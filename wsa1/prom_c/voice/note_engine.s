; ==============================================================================
; Technics SX-WSA1R -- prom_c (CPU 2, IC28) -- 0xFB0504-0xFB6E09  the MIDI message path and the 64-VOICE NOTE ENGINE
; ==============================================================================
;
; 12,473 lines moved out of prom_c/wsa1_prom_c.s by notes/prom_c_split.py.  The master
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
; Two banners the tree itself joins: the second opens `Continues the same
; module ... what is left here is the rest of the note engine`.  MidiIn_*,
; MidiNote_*, VoiceParams_Compute_A..D, VoiceList_*, Voice_Retire_* and the
; 68-byte voice record.
;
; >>> END OF EXTRACTION HEADER -- everything below is verbatim from the master

; ==============================================================================
; 0xFB0504-0xFB405E -- ★★ THE MIDI MESSAGE PATH AND THE 64-VOICE ENGINE
;                       32 routines, 15,195 bytes, one contiguous module
; ==============================================================================
;
; This is what CPU 2 does with a MIDI message.  The chain closes end to end and
; every link in it is a byte in the ROM:
;
;   Link_Ch0_AppendToRing (0xF98D9A, converted above)  writes bytes into the ring
;        |                                            at 0x00E2F1
;        v
;   MAIN  `lda XBC,0x00E2EB / push / call 0xFB060A`    (0xF98CA4-0xF98CAA)
;        v
;   MidiIn_ParseRingAndDispatch  takes 4-byte packets off the ring and switches on
;        |                       the status nibble: 80 90 B0 C0 D0 E0 F0
;        v
;   MidiNote_Dispatch (0xFB3F36)          for 0x90 -- and for 0x90 ONLY
;        |
;        +-- velocity != 0 -> MidiNote_OnByPartMode + MidiNote_OnTail
;        +-- velocity == 0 -> VoiceQuery_Tag80_PartNote + VoiceList_RetireByMode
;                             + MidiNote_OffTail
;        v
;   VoiceParams_Compute_*  fill a staging struct, VoiceRegs_Stage_*  hand it to
;   Dev10C_WriteAllChanRegs (0xFB713A) and Dev104_WriteAllChanRegs (0xFB77EF),
;   both converted BELOW this block -- 0xFB713A and 0xFB77EF are higher addresses
;   than 0xFB405E, so they appear later in the file.
;
; ★ THE TWO DATA STRUCTURES THE WHOLE MODULE IS BUILT ON
;
;   THE VOICE RECORD -- 64 records of 0x44 = 68 bytes at RAM 0x00003BCF.
;     The index is BOTH the record index AND the hardware channel number: the
;     smallest routine in the block, Dev10C_ChanReset (0xFB0A8B), takes one
;     argument n, writes device 0x0010C000 register n and register n+0xC0, and
;     then clears the word at `0x3BCF + n*0x44 + 1`.  One argument, two uses --
;     which is why "voice" and "channel" are the same number here.
;     The bound is `cp H,0x40` (0xFB3EA2 and 0xFB3FDE) -- 64 -- and 64 is exactly
;     the channel count notes/FINDINGS-prom_c-tone-generator.md establishes for
;     both devices from their register numbering (block*0x40 + channel).
;     64 * 0x44 = 4352 bytes, 0x00003BCF-0x00004CCE.  Record 63 -- the LAST --
;     occupies 0x00004C8B-0x00004CCE (0x3BCF + 63*0x44 .. +0x43).
;     ⚠ CORRECTED 2026-08-25.  This line used to end "0x0000456E", which is 2,464
;     bytes from the base -- 36.2 records, not 64 -- and contradicted the "4352
;     bytes" in the same sentence by 1,888 bytes.  The end address is now computed
;     from base, stride and count READ OUT OF THE ROM and asserted on the last
;     record by prom_c_voice_module_check.py section 5, which used to `print` this
;     line without checking it.
;
;   THE PART RECORD -- 300 bytes (0x012C) each, reached through the pointer array
;     at RAM 0x00001523: `mul BC,0x012c` then `ld XWA,(XBC+0x1523)` (0xFB386C,
;     0xFB3872).  MidiNote_Dispatch refuses a part index >= 0x21 (`cp C,0x21` at
;     0xFB3F41), so there are 33 of them.
;     ⚠ 0x21 is a BOUND read off one guard, not a table length read off a
;     terminator; nothing here walks the array to its end.
;
; ★ THE PACKET IS FOUR BYTES FOR MOST STATUSES -- NOT THREE, AND NOT FOUR FOR ALL.
;   Each arm carries its own `cp DE,n` guard and its own `decw n,(count)`, and the
;   two always agree.  Read out of those bytes by
;   `python3 notes/prom_c_voice_module_check.py` section 1b:
;
;       status  bytes  handler
;       0x80      6    0xFC2600
;       0x90      4    MidiNote_Dispatch (0xFB3F36), or 0xFC3E02 when byte[1]>=0xF0
;       0xB0      4    0xFAFDA5
;       0xC0      5    0xFB6BA8
;       0xD0      4    0xFB0013
;       0xE0      4    0xFB0132
;       0xF0      4    0xFB0338
;       default   --   drains the ring ONE BYTE AT A TIME until it is empty
;
;   ⚠ AN EARLIER DRAFT OF THIS PARAGRAPH SAID "every arm consumes four bytes, the
;   0xC0 arm alone five".  THE 0x80 ARM CONSUMES SIX and does not go anywhere near
;   the note handler.  So 0x80 is NOT "note off" in this protocol -- the format is
;   MIDI-DERIVED, not MIDI: the high nibble is a message type that coincides with
;   a MIDI status for 0x90/0xB0/0xC0, and the lengths are its own.  Section 1b of
;   the checker exists because of that error and asserts every row of the table.
;
;   For the four-byte statuses the layout is
;
;       [0] status byte, low nibble carried through to the handler
;       [1] a PART index (0..0x20), or >= 0xF0 for the second note handler
;       [2] data 1  (note number for 0x90, controller number for 0xB0)
;       [3] data 2  (velocity, controller value)
;
;   and it is proven by MidiMsg_SendBootSequence, which builds four packets from
;   literals: `B0 00 07 00` is MIDI controller 7 = CHANNEL VOLUME with value 0,
;   and `B0 00 78 7F` is controller 120 = ALL SOUND OFF with value 127.  Two
;   standard controller numbers landing in byte [2] is not a coincidence a wrong
;   layout survives.  Its `C0 00 00 00 00` is five bytes long, which is the 0xC0
;   arm's length -- the boot sequence and the parser agree on the lengths too.
;
; ★ 0xA0 IS MISSING.  The seven arms are 80, 90, B0, C0, D0, E0, F0; 0xA0 -- the
;   MIDI status for polyphonic key pressure -- has none, and falls to the default,
;   which drains the ring.  Read out of the `cp BC,imm16` immediates by
;   `python3 notes/prom_c_voice_module_check.py`, not by eye.
;   ⚠ "so this instrument has no per-key aftertouch" is the tempting next
;   sentence and it is NOT written here: this is one internal message path, the
;   format is MIDI-derived rather than MIDI (the 0x80 arm's packet is six bytes),
;   and what arrives on the physical MIDI IN is a different question.
;
; ★ FOUR ROUTINES IN THIS BLOCK HAVE NO CALLER AT ALL: 0xFB0B95, 0xFB1FB1,
;   0xFB289A and 0xFB2F74.  No `call`, no `calr`, no `jrl`, no `jp`, and no 24-bit
;   literal anywhere in the 512 KiB image names any of them.  Each sits
;   immediately in front of a much larger routine with almost the same call set,
;   so "an earlier version the linker kept" is the obvious reading -- and it is
;   NOT asserted here.  They are named sub_FB0B95 and friends, and the census is a
;   SEARCHED NEGATIVE: a target computed at run time is invisible to it.
;
; EVIDENCE FOR EVERYTHING QUANTIFIED ABOVE
;   python3 notes/prom_c_voice_module_check.py --selftest
;   -- 8 sections, all byte-matched against original_ROMs/wsa1_prom_c.ic28, never
;   against unidasm's text and never against this file.  Its --selftest asserts
;   the LAST element of every table (the 0xF0 arm, the 0x1FFF query, the All Sound
;   Off message, the last routine's single call site) and one negative control.
;   The conversion itself is proven by scripts/analysis/assert_byte_identical.py;
;   the fragment was cleared by `notes/prom_c_verify_fragment.py c 0xFB0504` first.
;
; WHAT THIS BLOCK DOES NOT ESTABLISH
;   ⚠ What any tone-generator register MEANS.  This module computes values and
;   hands them to two already-converted writers; the writers' own headers say the
;   register semantics are unknown, and nothing here changes that.
;   ⚠ CORRECTED 2026-08-25: the helpers each VoiceRegs_Stage_* calls -- 18, 20, 23
;   and 26 distinct call targets respectively (checker section 10) -- are NOT still
;   `.incbin`.  Every one of them is converted, and
;   `python3 notes/prom_c_dev10c_field_sources.py` now names, for each of the 22
;   staged words, the routines that write it.  What each staged word MEANS is still
;   open; what CODE produces it is not.  They are the obvious next module: most of
;   them lie between 0xFA819A and 0xFAB7E0, and every one of them now has a named
;   caller.
; ==============================================================================

; ------------------------------------------------------------------------------
; ExtBoard_ProbeAndInstallBases -- 0xFB0504..0xFB05EB (232 bytes)
;
; The first thing MAIN does.  Installs eight 32-bit base addresses in a table at
; RAM 0x00D7ED, then looks for the expansion board and records where it is.
;
; Called from: one site, `call 0xFB0504` at 0xF98B81 -- the FIRST call in MAIN's
;          init chain (notes/prom_c_voice_module_check.py --refs).
; Inputs:  P9 bit 0, and whatever is at 0x00C00000.
; Outputs: 0x00D7ED..0x00D80C = EIGHT 32-bit slots, filled from SEVEN distinct
;          literals (0x00F00000 goes into the first two and 0x00010000 into the
;          last two); 0x00D80D and 0x00D811 = the
;          expansion board's base and a second address derived from its header;
;          bit 2 of the word at (0x14FF) set or cleared; (0x14FE) = 0.
; Evidence: ★ THE SIGNATURE IS IN THE ROM AND THE COMPARE IS TEN BYTES LONG.
;          The loop at 0xFB056C reads `(0x00FE129E + i)` and `(0x00C00000 + i)`
;          and stops at `cp HL,0x000a` (0xFB0588 and again at 0xFB058E).  0xFE129E
;          holds the eleven bytes `57 53 41 31 20 45 58 54 42 44 00` = "WSA1 EXTBD"
;          with its NUL, and len("WSA1 EXTBD") is exactly 10.
;          notes/FINDINGS-memory-map.md already had 0x00C00000 as the expansion
;          board from `0xFB6B6E ld XIX,0x00C00000`; this is the routine that
;          decides whether one is fitted.
;          On a match it stores 0x00C00000 to (0x00D80D), reads a 32-bit link at
;          `board + 0x10`, and if that is not 0xFFFFFFFF stores `link + 0x00C00000`
;          to (0x00D811); on a mismatch it zeroes both.
;          The seven 32-bit literals it installs are, in order, 0x00F00000,
;          0x00E80000, 0x00E90000, 0x00EA0000, 0x00EB0000, 0x00010000 and
;          0x00C00000 -- read out of the `ld XBC,imm32` bytes by
;          prom_c_voice_module_check.py section 7.  0x00E80000 is the flash and
;          0x00010000 is its 64 KiB staging buffer, both established in
;          notes/FINDINGS-prom_c-flash.md, so this table is a MAP OF WHERE SAMPLE
;          DATA CAN LIVE.  ⚠ that last sentence is an inference from the addresses;
;          no consumer of 0x00D7ED is traced here.
;          It ends by calling Dev10C_ResetAllChannels (0xFB80E1, converted below),
;          then 0xFA664B, 0xFC7CF9 and 0xFB6CEE.  ⚠ CORRECTED 2026-08-25: those
;          three were described here as "all still .incbin"; all three are
;          converted.
; Unknown:  ⚠ what P9 bit 0 is wired to, and what bit 2 of (0x14FF) selects.  What
;          the eight base slots are indexed BY.  What is at expansion-board +0x10
;          beyond "a link, 0xFFFFFFFF means none".
ExtBoard_ProbeAndInstallBases:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FB0504  link XIZ,0xfffc
	pushw	hl                                   ; FB0508  push HL
	pushw	de                                   ; FB0509  push DE
	push	xix                                   ; FB050A  push XIX
	bit_dd8	0, P9                              ; FB050B  bit 0,(0x19)
	jr z, ExtBoard_ProbeAndInstallBases__FB0518 ; FB050E  jr Z,0xfb0518
	extpfx6 0xD1, 0xFF, 0x14, 0x3C, 0xFB, 0xFF ; FB0510  and (0x14ff),0xfffb
	jr ExtBoard_ProbeAndInstallBases__FB051E   ; FB0516  jr T,0xfb051e
ExtBoard_ProbeAndInstallBases__FB0518:
	extpfx6 0xD1, 0xFF, 0x14, 0x3E, 0x04, 0x00 ; FB0518  or (0x14ff),0x0004
ExtBoard_ProbeAndInstallBases__FB051E:
	ld	xbc, 0xF00000                           ; FB051E  ld XBC,0x00f00000
	stl_da	(0xD7ED), xbc                       ; FB0523  ld (0x00d7ed),XBC
	stl_da	(0xD7F1), xbc                       ; FB0528  ld (0x00d7f1),XBC
	ld	xwa, 0xE80000                           ; FB052D  ld XWA,0x00e80000
	stl_da	(0xD7F5), xwa                       ; FB0532  ld (0x00d7f5),XWA
	ld	xbc, 0xE90000                           ; FB0537  ld XBC,0x00e90000
	stl_da	(0xD7F9), xbc                       ; FB053C  ld (0x00d7f9),XBC
	ld	xbc, 0xEA0000                           ; FB0541  ld XBC,0x00ea0000
	stl_da	(0xD7FD), xbc                       ; FB0546  ld (0x00d7fd),XBC
	ld	xbc, 0xEB0000                           ; FB054B  ld XBC,0x00eb0000
	stl_da	(0xD801), xbc                       ; FB0550  ld (0x00d801),XBC
	ld	xbc, 0x10000                            ; FB0555  ld XBC,0x00010000
	stl_da	(0xD805), xbc                       ; FB055A  ld (0x00d805),XBC
	stl_da	(0xD809), xbc                       ; FB055F  ld (0x00d809),XBC
	ld	xix, 0xC00000                           ; FB0564  ld XIX,0x00c00000
	ldw	hl, 0                                  ; FB0569  ld HL,0x0000
ExtBoard_ProbeAndInstallBases__FB056C:
	ld	bc, hl                                  ; FB056C  ld BC,HL
	extz	xbc                                   ; FB056E  extz XBC
	ld	(xiz-4), xbc                            ; FB0570  ld (XIZ+0xfc),XBC
	add	xbc, 0xFE129E                          ; FB0573  add XBC,0x00fe129e
	ld	d, (xbc)                                ; FB0579  ld D,(XBC)
	ld	xbc, xix                                ; FB057B  ld XBC,XIX
	extpfx3 0xAE, 0xFC, 0x81                   ; FB057D  add XBC,(XIZ+0xfc)
	ld	a, (xbc)                                ; FB0580  ld A,(XBC)
	cp	a, d                                    ; FB0582  cp A,D
	jr nz, ExtBoard_ProbeAndInstallBases__FB058E ; FB0584  jr NZ,0xfb058e
	inc	1, hl                                  ; FB0586  inc 1,HL
	cp	hl, 10                                  ; FB0588  cp HL,0x000a
	jr c, ExtBoard_ProbeAndInstallBases__FB056C ; FB058C  jr C,0xfb056c
ExtBoard_ProbeAndInstallBases__FB058E:
	cp	hl, 10                                  ; FB058E  cp HL,0x000a
	jr c, ExtBoard_ProbeAndInstallBases__FB05B0 ; FB0592  jr C,0xfb05b0
	ld	xbc, 0xC00000                           ; FB0594  ld XBC,0x00c00000
	stl_da	(0xD80D), xbc                       ; FB0599  ld (0x00d80d),XBC
	add	xix, 16                                ; FB059E  add XIX,0x00000010
	ld	xwa, (xix)                              ; FB05A4  ld XWA,(XIX)
	ld	xix, xwa                                ; FB05A6  ld XIX,XWA
	cp	xwa, 0xFFFFFFFF                         ; FB05A8  cp XWA,0xffffffff
	jr nz, ExtBoard_ProbeAndInstallBases__FB05C0 ; FB05AE  jr NZ,0xfb05c0
ExtBoard_ProbeAndInstallBases__FB05B0:
	sub	xbc, xbc                               ; FB05B0  sub XBC,XBC
	stl_da	(0xD80D), xbc                       ; FB05B2  ld (0x00d80d),XBC
	sub	xwa, xwa                               ; FB05B7  sub XWA,XWA
	stl_da	(0xD811), xwa                       ; FB05B9  ld (0x00d811),XWA
	jr ExtBoard_ProbeAndInstallBases__FB05CD   ; FB05BE  jr T,0xfb05cd
ExtBoard_ProbeAndInstallBases__FB05C0:
	ld	xbc, xix                                ; FB05C0  ld XBC,XIX
	add	xbc, 0xC00000                          ; FB05C2  add XBC,0x00c00000
	stl_da	(0xD811), xbc                       ; FB05C8  ld (0x00d811),XBC
ExtBoard_ProbeAndInstallBases__FB05CD:
	call	0xFB80E1                              ; FB05CD  call 0xfb80e1
	pushw	0                                    ; FB05D1  push 0x0000
	call	0xFA664B                              ; FB05D4  call 0xfa664b
	call	0xFC7CF9                              ; FB05D8  call 0xfc7cf9
	call	0xFB6CEE                              ; FB05DC  call 0xfb6cee
	stdi8	(0x14FE), 0                          ; FB05E0  ld (0x14fe),0x00
	popw	bc                                    ; FB05E5  pop BC
	pop	xix                                    ; FB05E6  pop XIX
	popw	de                                    ; FB05E7  pop DE
	popw	hl                                    ; FB05E8  pop HL
	unlk32 xiz                                 ; FB05E9  unlk XIZ
	ret                                        ; FB05EB  ret
; ------------------------------------------------------------------------------
; Toggle14FE_AndDispatch -- 0xFB05EC..0xFB0609 (30 bytes)
;
; Called from: one site, `call 0xFB05EC` at 0xF98C1E.
; Inputs:  the byte at (0x14FE).
; Outputs: that byte, complemented; plus whatever the two callees do.
; Evidence: its one call site is inside MAIN's bit-4 arm, the arm that runs
;          after `res 4,(0x007ED1)`.
;          `lda XIX,0x14fe` / `ld C,(XIX)` / `cp C,0` chooses between
;          `call 0xFACA40` and `call 0xFA68DC` + `call 0xFACAB7`, and the routine
;          then ends with `xor (XIX),0xff` -- so successive calls alternate
;          between the two paths for ever, and 0x00 and 0xFF are the only two
;          values the byte can hold once this routine has run.  (0x14FE) is also
;          zeroed by ExtBoard_ProbeAndInstallBases at 0xFB05E0, so the FIRST pass
;          takes the `call 0xFACA40` path.
; Unknown:  ⚠ everything the two paths DO -- 0xFACA40, 0xFA68DC and 0xFACAB7 are
;          converted but unexplained (⚠ CORRECTED 2026-08-25: this line said "all
;          still .incbin"; all three are converted).  The name records the
;          mechanism, not a purpose.
Toggle14FE_AndDispatch:
	push	xix                                   ; FB05EC  push XIX
	lda	xix, (0x14FE:16)                      ; FB05ED  lda XIX,0x14fe
	ld	c, (xix)                                ; FB05F1  ld C,(XIX)
	cps	c, 0                                   ; FB05F3  cp C,0
	jr nz, Toggle14FE_AndDispatch__FB05FD      ; FB05F5  jr NZ,0xfb05fd
	call	0xFACA40                              ; FB05F7  call 0xfaca40
	jr Toggle14FE_AndDispatch__FB0605          ; FB05FB  jr T,0xfb0605
Toggle14FE_AndDispatch__FB05FD:
	call	0xFA68DC                              ; FB05FD  call 0xfa68dc
	call	0xFACAB7                              ; FB0601  call 0xfacab7
Toggle14FE_AndDispatch__FB0605:
	extpfx3 0x84, 0x3D, 0xFF                   ; FB0605  xor (XIX),0xff
	pop	xix                                    ; FB0608  pop XIX
	ret                                        ; FB0609  ret
; ------------------------------------------------------------------------------
; ★★ MidiIn_ParseRingAndDispatch -- 0xFB060A..0xFB0A0C (1027 bytes)
;
; Drains 4-byte MIDI packets from a ring and calls one handler per status nibble.
;
; Called from: one site, `call 0xFB060A` at 0xF98CAA, at the bottom of MAIN's
;          loop.
; Inputs:  (XIZ+0x08) = the ring DESCRIPTOR address.  MAIN pushes it with
;          `lda XBC,0x00E2EB` two instructions before that call.
;          The descriptor is
;              +0  u16  WRITE index   -- written by Link_Ch0_AppendToRing
;              +2  u16  READ index    -- this routine's cursor
;              +4  u16  byte count    -- available bytes
;              +6  ..   the ring itself, 4096 bytes
; Outputs: L = 1 when it gives up for lack of bytes; the read index and the count
;          advanced by THAT ARM'S OWN PACKET LENGTH per packet consumed -- 4 for
;          0x90/0xB0/0xD0/0xE0/0xF0, 5 for 0xC0, SIX for 0x80 (`cp DE,6` at
;          0xFB068A, `da de`, the operand being in the opcode) -- and the default
;          arm advances by 1 at a time; one of the message buffers at
;          0x00D7C8-0x00D7E5 filled; one handler called.
;          ⚠ CORRECTED 2026-08-25.  This line still read "advanced by 4 (5 for the
;          0xC0 arm)" -- the retracted sentence the block comment above and the
;          `Unknown:` section below had already replaced.  Section 1b of
;          prom_c_voice_module_check.py asserts every row of the per-arm table.
; Evidence: ★ THE RING GEOMETRY IS SELF-PROVING.  The cursor is masked with
;          `and IY,0x0fff` (0xFB063A) and the data starts at descriptor+6, so with
;          MAIN's argument the ring is 0x00E2F1-0x00F2F0.  0x00F2F1 -- the very
;          next byte -- is the main loop's countdown, a variable
;          notes/FINDINGS-prom_c-ram-image.md already documented with its boot
;          value 100.  And the ring's own boot image is 4096 CONSECUTIVE ZERO
;          BYTES in the ROM (0xFCB4FC-0xFCC4FB, the RAM-image source for
;          0x00E2F1-0x00F2F0), while the two bytes after it are `64 00`.  A wrong
;          base or a wrong size does not land on both edges of a 4096-byte zero
;          run.  Checked by prom_c_voice_module_check.py section 2.
;          ★ THE PRODUCER IS Link_Ch0_AppendToRing (0xF98D9A, converted above),
;          which forms `((0x00E2EB) & 0x0FFF) + 6 + 0x0000E2EB` and increments
;          (0x00E2EB) and (0x00E2EF).  That routine's header called (0x00E2EF)
;          "Unknown: what it counts" -- THIS ROUTINE ANSWERS IT.  It is the byte
;          COUNT: the entry guard is `cp DE,4` on (descriptor+4) and every arm
;          does `decw 4,(descriptor+4)`.
;          ★ THE DISPATCH.  `and C,0xf0` (0xFB0649) then seven compares, in this
;          order: 0x80 0x90 0xB0 0xC0 0xD0 0xE0 0xF0, each to its own arm, with a
;          default at 0xFB09FA.  These are seven of the eight MIDI channel/system
;          status nibbles; 0xA0, polyphonic key pressure, has NO arm.  The list is
;          read out of the `cp BC,imm16` immediates by
;          prom_c_voice_module_check.py section 1, which also asserts 0xA0's
;          absence; section 1b derives each arm's LENGTH and HANDLER from that
;          arm's own guard, decrement and `call`.  The per-arm table is in the
;          block comment above.  Of the seven handlers only MidiNote_Dispatch
;          (0xFB3F36) is converted.
;          ★ THE DEFAULT ARM IS A RESYNC.  It does not skip one packet: it drops
;          bytes ONE AT A TIME (`dec 1,DE` / `decw 1,(count)` / `incw 1,(cursor)`
;          at 0xFB09F1) until the count reaches zero.  An unrecognised status byte
;          therefore costs the whole buffer.
;          ★ IT LOOPS.  L is 1 on entry and only 0xFB09ED -- the "fewer bytes than
;          this arm needs" exit -- sets it to 0; the tail at 0xFB0A02 tests L and
;          jumps back to 0xFB0619 while it is non-zero.  So one call drains as
;          many packets as the ring holds.
;          ★ AND 0xF98CB9 IS NOT AN ARM.  `call 0xF98CB9` at 0xFB09FE is on the
;          LOOP TAIL, executed once per iteration whatever the status byte was.
;          0xF98CB9 is KeyEvents_ToLink, converted above.
; Unknown:  ⚠ which arm is which beyond the status byte, because six of the seven
;          handlers are unexplained (⚠ CORRECTED 2026-08-25: "still .incbin" --
;          they are converted) -- and the 0x80 arm in particular is NOT the
;          MIDI note-off it looks like, since it takes a six-byte packet and calls
;          0xFC2600.
;          ✔ CLOSED 2026-08-30 (round 9): what packet byte [1] >= 0xF0 means.  It
;          is a real branch -- `cp H,0xf0` at 0xFB07FD and `jr NC,0xfb0808` at
;          0xFB0800 -- and its handler is NotePool8_NoteOnOff (0xFC3E02), a
;          note-on/note-off engine over a PRIVATE EIGHT-SLOT VOICE POOL with
;          nothing in common with the 33 part records MidiNote_Dispatch drives:
;          its own round-robin allocator at RAM 0x00E005, its own eight-byte
;          sounding-note table at 0x00E006, and its own 68-byte device image
;          Dev10C_StagingStruct_NotePool8Image.  Byte [1] is 0xF0 + a VARIANT the
;          handler masks to 0..6.  ⚠ STILL OPEN: what the seven variants are, and
;          what sends the packets -- they arrive over link channel 0 from CPU 1,
;          so any name for them lives in prom_a.
;          ✔ CLOSED 2026-08-25: the call to 0xFA5949 at 0xFB061F, made with the
;          byte count pushed before any parsing happens, is sub_FA5949, converted
;          above.  Its whole body is `ld BC,(XIZ+0x08) / ld (0x008678),BC / ret` --
;          fifteen bytes that store the pushed count at 0x008678 and return.  What
;          0x008678 is FOR is still not established; what the call does is.
;          ⚠ the 0x80 arm has TWO sub-paths, chosen on bit 3 of the status byte's
;          low nibble and on `cp DE,6`; both consume six bytes and both end at the
;          same `call 0xFC2600`, and what distinguishes them is not traced.
MidiIn_ParseRingAndDispatch:
	link32 0xEE, 0x0C, 0xF0, 0xFF              ; FB060A  link XIZ,0xfff0
	pushw	hl                                   ; FB060E  push HL
	pushw	de                                   ; FB060F  push DE
	push	xix                                   ; FB0610  push XIX
	ld	xbc, (xiz+8)                            ; FB0611  ld XBC,(XIZ+0x08)
	ld	de, (xbc+4)                             ; FB0614  ld DE,(XBC+0x04)
	ldb	l, 1                                   ; FB0617  ld L,0x01
MidiIn_ParseRingAndDispatch__FB0619:
	cps	de, 4                                  ; FB0619  cp DE,4
	jrl c, MidiIn_ParseRingAndDispatch__FB0A07 ; FB061B  jrl C,0xfb0a07
	pushw	de                                   ; FB061E  push DE
	call	0xFA5949                              ; FB061F  call 0xfa5949
	ld	xbc, (xiz+8)                            ; FB0623  ld XBC,(XIZ+0x08)
	inc	4, xbc                                 ; FB0626  inc 4,XBC
	ld	(xiz-12), xbc                           ; FB0628  ld (XIZ+0xf4),XBC
	ld	xix, (xiz+8)                            ; FB062B  ld XIX,(XIZ+0x08)
	inc	2, xix                                 ; FB062E  inc 2,XIX
	ld	xwa, (xiz+8)                            ; FB0630  ld XWA,(XIZ+0x08)
	inc	6, xwa                                 ; FB0633  inc 6,XWA
	ld	(xiz-8), xwa                            ; FB0635  ld (XIZ+0xf8),XWA
	ld	iy, (xix)                               ; FB0638  ld IY,(XIX)
	and	iy, 0xFFF                              ; FB063A  and IY,0x0fff
	exts	xiy                                   ; FB063E  exts XIY
	add	xwa, xiy                               ; FB0640  add XWA,XIY
	ld	(xiz-4), xwa                            ; FB0642  ld (XIZ+0xfc),XWA
	ld	h, (xwa)                                ; FB0645  ld H,(XWA)
	ld	c, h                                    ; FB0647  ld C,H
	and	c, 0xF0                                ; FB0649  and C,0xf0
	extz	bc                                    ; FB064C  extz BC
	popw	iy                                    ; FB064E  pop IY
	cp	bc, 0x80                                ; FB064F  cp BC,0x0080
	jr z, MidiIn_ParseRingAndDispatch__FB0682  ; FB0653  jr Z,0xfb0682
	cp	bc, 0x90                                ; FB0655  cp BC,0x0090
	jrl z, MidiIn_ParseRingAndDispatch__FB07A3 ; FB0659  jrl Z,0xfb07a3
	cp	bc, 0xB0                                ; FB065C  cp BC,0x00b0
	jrl z, MidiIn_ParseRingAndDispatch__FB080E ; FB0660  jrl Z,0xfb080e
	cp	bc, 0xC0                                ; FB0663  cp BC,0x00c0
	jrl z, MidiIn_ParseRingAndDispatch__FB086A ; FB0667  jrl Z,0xfb086a
	cp	bc, 0xD0                                ; FB066A  cp BC,0x00d0
	jrl z, MidiIn_ParseRingAndDispatch__FB08DA ; FB066E  jrl Z,0xfb08da
	cp	bc, 0xE0                                ; FB0671  cp BC,0x00e0
	jrl z, MidiIn_ParseRingAndDispatch__FB0936 ; FB0675  jrl Z,0xfb0936
	cp	bc, 0xF0                                ; FB0678  cp BC,0x00f0
	jrl z, MidiIn_ParseRingAndDispatch__FB0992 ; FB067C  jrl Z,0xfb0992
	jrl MidiIn_ParseRingAndDispatch__FB09FA    ; FB067F  jrl T,0xfb09fa
MidiIn_ParseRingAndDispatch__FB0682:
	ld	c, h                                    ; FB0682  ld C,H
	and	c, 8                                   ; FB0684  and C,0x08
	jrl nz, MidiIn_ParseRingAndDispatch__FB070F ; FB0687  jrl NZ,0xfb070f
	cps	de, 6                                  ; FB068A  cp DE,6
	jrl c, MidiIn_ParseRingAndDispatch__FB070F ; FB068C  jrl C,0xfb070f
	ldw (xiz-14), 0x0FFF                       ; FB068F  ld (XIZ+0xf2),0x0fff
	ld	xbc, (xiz-4)                            ; FB0694  ld XBC,(XIZ+0xfc)
	ld	a, (xbc)                                ; FB0697  ld A,(XBC)
	stb_da	(0xD7C8), a                         ; FB0699  ld (0x00d7c8),A
	incw	1, (xix)                              ; FB069E  incw 1,(XIX)
	ld	bc, (xix)                               ; FB06A0  ld BC,(XIX)
	extpfx3 0x9E, 0xF2, 0xC1                   ; FB06A2  and BC,(XIZ+0xf2)
	exts	xbc                                   ; FB06A5  exts XBC
	extpfx3 0xAE, 0xF8, 0x81                   ; FB06A7  add XBC,(XIZ+0xf8)
	ld	a, (xbc)                                ; FB06AA  ld A,(XBC)
	stb_da	(0xD7C9), a                         ; FB06AC  ld (0x00d7c9),A
	incw	1, (xix)                              ; FB06B1  incw 1,(XIX)
	ld	bc, (xix)                               ; FB06B3  ld BC,(XIX)
	extpfx3 0x9E, 0xF2, 0xC1                   ; FB06B5  and BC,(XIZ+0xf2)
	exts	xbc                                   ; FB06B8  exts XBC
	extpfx3 0xAE, 0xF8, 0x81                   ; FB06BA  add XBC,(XIZ+0xf8)
	ld	a, (xbc)                                ; FB06BD  ld A,(XBC)
	stb_da	(0xD7CA), a                         ; FB06BF  ld (0x00d7ca),A
	incw	1, (xix)                              ; FB06C4  incw 1,(XIX)
	ld	bc, (xix)                               ; FB06C6  ld BC,(XIX)
	extpfx3 0x9E, 0xF2, 0xC1                   ; FB06C8  and BC,(XIZ+0xf2)
	exts	xbc                                   ; FB06CB  exts XBC
	extpfx3 0xAE, 0xF8, 0x81                   ; FB06CD  add XBC,(XIZ+0xf8)
	ld	a, (xbc)                                ; FB06D0  ld A,(XBC)
	stb_da	(0xD7CB), a                         ; FB06D2  ld (0x00d7cb),A
	incw	1, (xix)                              ; FB06D7  incw 1,(XIX)
	ld	bc, (xix)                               ; FB06D9  ld BC,(XIX)
	extpfx3 0x9E, 0xF2, 0xC1                   ; FB06DB  and BC,(XIZ+0xf2)
	exts	xbc                                   ; FB06DE  exts XBC
	extpfx3 0xAE, 0xF8, 0x81                   ; FB06E0  add XBC,(XIZ+0xf8)
	ld	a, (xbc)                                ; FB06E3  ld A,(XBC)
	stb_da	(0xD7CC), a                         ; FB06E5  ld (0x00d7cc),A
	incw	1, (xix)                              ; FB06EA  incw 1,(XIX)
	ld	bc, (xix)                               ; FB06EC  ld BC,(XIX)
	extpfx3 0x9E, 0xF2, 0xC1                   ; FB06EE  and BC,(XIZ+0xf2)
	exts	xbc                                   ; FB06F1  exts XBC
	extpfx3 0xAE, 0xF8, 0x81                   ; FB06F3  add XBC,(XIZ+0xf8)
	ld	a, (xbc)                                ; FB06F6  ld A,(XBC)
	stb_da	(0xD7CD), a                         ; FB06F8  ld (0x00d7cd),A
	incw	1, (xix)                              ; FB06FD  incw 1,(XIX)
	ld	xbc, (xiz-12)                           ; FB06FF  ld XBC,(XIZ+0xf4)
	decm	6, (xbc)                              ; FB0702  decw 6,(XBC)
	dec	6, de                                  ; FB0704  dec 6,DE
	lda	xbc, (0xD7C8:24)                       ; FB0706  lda XBC,0x00d7c8
	push	xbc                                   ; FB070B  push XBC
	jrl MidiIn_ParseRingAndDispatch__FB079B    ; FB070C  jrl T,0xfb079b
MidiIn_ParseRingAndDispatch__FB070F:
	cps	de, 6                                  ; FB070F  cp DE,6
	jrl c, MidiIn_ParseRingAndDispatch__FB09ED ; FB0711  jrl C,0xfb09ed
	ld	bc, (xix)                               ; FB0714  ld BC,(XIX)
	ld	(xiz-14), bc                            ; FB0716  ld (XIZ+0xf2),BC
	ldw (xiz-16), 0x0FFF                       ; FB0719  ld (XIZ+0xf0),0x0fff
	extpfx3 0x9E, 0xF0, 0xC1                   ; FB071E  and BC,(XIZ+0xf0)
	exts	xbc                                   ; FB0721  exts XBC
	extpfx3 0xAE, 0xF8, 0x81                   ; FB0723  add XBC,(XIZ+0xf8)
	ld	a, (xbc)                                ; FB0726  ld A,(XBC)
	stb_da	(0xD7CE), a                         ; FB0728  ld (0x00d7ce),A
	incw	1, (xix)                              ; FB072D  incw 1,(XIX)
	ld	bc, (xix)                               ; FB072F  ld BC,(XIX)
	extpfx3 0x9E, 0xF0, 0xC1                   ; FB0731  and BC,(XIZ+0xf0)
	exts	xbc                                   ; FB0734  exts XBC
	extpfx3 0xAE, 0xF8, 0x81                   ; FB0736  add XBC,(XIZ+0xf8)
	ld	a, (xbc)                                ; FB0739  ld A,(XBC)
	stb_da	(0xD7CF), a                         ; FB073B  ld (0x00d7cf),A
	incw	1, (xix)                              ; FB0740  incw 1,(XIX)
	ld	bc, (xix)                               ; FB0742  ld BC,(XIX)
	extpfx3 0x9E, 0xF0, 0xC1                   ; FB0744  and BC,(XIZ+0xf0)
	exts	xbc                                   ; FB0747  exts XBC
	extpfx3 0xAE, 0xF8, 0x81                   ; FB0749  add XBC,(XIZ+0xf8)
	ld	a, (xbc)                                ; FB074C  ld A,(XBC)
	stb_da	(0xD7D0), a                         ; FB074E  ld (0x00d7d0),A
	incw	1, (xix)                              ; FB0753  incw 1,(XIX)
	ld	bc, (xix)                               ; FB0755  ld BC,(XIX)
	extpfx3 0x9E, 0xF0, 0xC1                   ; FB0757  and BC,(XIZ+0xf0)
	exts	xbc                                   ; FB075A  exts XBC
	extpfx3 0xAE, 0xF8, 0x81                   ; FB075C  add XBC,(XIZ+0xf8)
	ld	a, (xbc)                                ; FB075F  ld A,(XBC)
	stb_da	(0xD7D1), a                         ; FB0761  ld (0x00d7d1),A
	incw	1, (xix)                              ; FB0766  incw 1,(XIX)
	ld	bc, (xix)                               ; FB0768  ld BC,(XIX)
	extpfx3 0x9E, 0xF0, 0xC1                   ; FB076A  and BC,(XIZ+0xf0)
	exts	xbc                                   ; FB076D  exts XBC
	extpfx3 0xAE, 0xF8, 0x81                   ; FB076F  add XBC,(XIZ+0xf8)
	ld	a, (xbc)                                ; FB0772  ld A,(XBC)
	stb_da	(0xD7D2), a                         ; FB0774  ld (0x00d7d2),A
	incw	1, (xix)                              ; FB0779  incw 1,(XIX)
	ld	bc, (xix)                               ; FB077B  ld BC,(XIX)
	extpfx3 0x9E, 0xF0, 0xC1                   ; FB077D  and BC,(XIZ+0xf0)
	exts	xbc                                   ; FB0780  exts XBC
	extpfx3 0xAE, 0xF8, 0x81                   ; FB0782  add XBC,(XIZ+0xf8)
	ld	a, (xbc)                                ; FB0785  ld A,(XBC)
	stb_da	(0xD7D3), a                         ; FB0787  ld (0x00d7d3),A
	incw	1, (xix)                              ; FB078C  incw 1,(XIX)
	ld	xbc, (xiz-12)                           ; FB078E  ld XBC,(XIZ+0xf4)
	decm	6, (xbc)                              ; FB0791  decw 6,(XBC)
	dec	6, de                                  ; FB0793  dec 6,DE
	lda	xbc, (0xD7CE:24)                       ; FB0795  lda XBC,0x00d7ce
	push	xbc                                   ; FB079A  push XBC
MidiIn_ParseRingAndDispatch__FB079B:
	call	0xFC2600                              ; FB079B  call 0xfc2600
MidiIn_ParseRingAndDispatch__FB079F:
	pop	xiy                                    ; FB079F  pop XIY
	jrl MidiIn_ParseRingAndDispatch__FB09FE    ; FB07A0  jrl T,0xfb09fe
MidiIn_ParseRingAndDispatch__FB07A3:
	cps	de, 4                                  ; FB07A3  cp DE,4
	jrl c, MidiIn_ParseRingAndDispatch__FB09ED ; FB07A5  jrl C,0xfb09ed
	stb_da	(0xD7D4), h                         ; FB07A8  ld (0x00d7d4),H
	incw	1, (xix)                              ; FB07AD  incw 1,(XIX)
	ld	bc, (xix)                               ; FB07AF  ld BC,(XIX)
	and	bc, 0xFFF                              ; FB07B1  and BC,0x0fff
	exts	xbc                                   ; FB07B5  exts XBC
	extpfx3 0xAE, 0xF8, 0x81                   ; FB07B7  add XBC,(XIZ+0xf8)
	ld	a, (xbc)                                ; FB07BA  ld A,(XBC)
	stb_da	(0xD7D5), a                         ; FB07BC  ld (0x00d7d5),A
	incw	1, (xix)                              ; FB07C1  incw 1,(XIX)
	ld	bc, (xix)                               ; FB07C3  ld BC,(XIX)
	and	bc, 0xFFF                              ; FB07C5  and BC,0x0fff
	exts	xbc                                   ; FB07C9  exts XBC
	extpfx3 0xAE, 0xF8, 0x81                   ; FB07CB  add XBC,(XIZ+0xf8)
	ld	a, (xbc)                                ; FB07CE  ld A,(XBC)
	stb_da	(0xD7D6), a                         ; FB07D0  ld (0x00d7d6),A
	incw	1, (xix)                              ; FB07D5  incw 1,(XIX)
	ld	bc, (xix)                               ; FB07D7  ld BC,(XIX)
	and	bc, 0xFFF                              ; FB07D9  and BC,0x0fff
	exts	xbc                                   ; FB07DD  exts XBC
	extpfx3 0xAE, 0xF8, 0x81                   ; FB07DF  add XBC,(XIZ+0xf8)
	ld	a, (xbc)                                ; FB07E2  ld A,(XBC)
	stb_da	(0xD7D7), a                         ; FB07E4  ld (0x00d7d7),A
	incw	1, (xix)                              ; FB07E9  incw 1,(XIX)
	ld	xbc, (xiz-12)                           ; FB07EB  ld XBC,(XIZ+0xf4)
	decm	4, (xbc)                              ; FB07EE  decw 4,(XBC)
	dec	4, de                                  ; FB07F0  dec 4,DE
	ldb_da	h, (0xD7D5)                         ; FB07F2  ld H,(0x00d7d5)
	lda	xbc, (0xD7D4:24)                       ; FB07F7  lda XBC,0x00d7d4
	push	xbc                                   ; FB07FC  push XBC
	cp	h, 0xF0                                 ; FB07FD  cp H,0xf0
	jr nc, MidiIn_ParseRingAndDispatch__FB0808 ; FB0800  jr NC,0xfb0808
	call	0xFB3F36                              ; FB0802  call 0xfb3f36
	jr MidiIn_ParseRingAndDispatch__FB079F     ; FB0806  jr T,0xfb079f
MidiIn_ParseRingAndDispatch__FB0808:
	call	0xFC3E02                              ; FB0808  call 0xfc3e02
	jr MidiIn_ParseRingAndDispatch__FB079F     ; FB080C  jr T,0xfb079f
MidiIn_ParseRingAndDispatch__FB080E:
	cps	de, 4                                  ; FB080E  cp DE,4
	jrl c, MidiIn_ParseRingAndDispatch__FB09ED ; FB0810  jrl C,0xfb09ed
	stb_da	(0xD7D8), h                         ; FB0813  ld (0x00d7d8),H
	incw	1, (xix)                              ; FB0818  incw 1,(XIX)
	ld	bc, (xix)                               ; FB081A  ld BC,(XIX)
	and	bc, 0xFFF                              ; FB081C  and BC,0x0fff
	exts	xbc                                   ; FB0820  exts XBC
	extpfx3 0xAE, 0xF8, 0x81                   ; FB0822  add XBC,(XIZ+0xf8)
	ld	a, (xbc)                                ; FB0825  ld A,(XBC)
	stb_da	(0xD7D9), a                         ; FB0827  ld (0x00d7d9),A
	incw	1, (xix)                              ; FB082C  incw 1,(XIX)
	ld	bc, (xix)                               ; FB082E  ld BC,(XIX)
	and	bc, 0xFFF                              ; FB0830  and BC,0x0fff
	exts	xbc                                   ; FB0834  exts XBC
	extpfx3 0xAE, 0xF8, 0x81                   ; FB0836  add XBC,(XIZ+0xf8)
	ld	a, (xbc)                                ; FB0839  ld A,(XBC)
	stb_da	(0xD7DA), a                         ; FB083B  ld (0x00d7da),A
	incw	1, (xix)                              ; FB0840  incw 1,(XIX)
	ld	bc, (xix)                               ; FB0842  ld BC,(XIX)
	and	bc, 0xFFF                              ; FB0844  and BC,0x0fff
	exts	xbc                                   ; FB0848  exts XBC
	extpfx3 0xAE, 0xF8, 0x81                   ; FB084A  add XBC,(XIZ+0xf8)
	ld	a, (xbc)                                ; FB084D  ld A,(XBC)
	stb_da	(0xD7DB), a                         ; FB084F  ld (0x00d7db),A
	incw	1, (xix)                              ; FB0854  incw 1,(XIX)
	ld	xbc, (xiz-12)                           ; FB0856  ld XBC,(XIZ+0xf4)
	decm	4, (xbc)                              ; FB0859  decw 4,(XBC)
	dec	4, de                                  ; FB085B  dec 4,DE
	lda	xbc, (0xD7D8:24)                       ; FB085D  lda XBC,0x00d7d8
	push	xbc                                   ; FB0862  push XBC
	call	0xFAFDA5                              ; FB0863  call 0xfafda5
	jrl MidiIn_ParseRingAndDispatch__FB079F    ; FB0867  jrl T,0xfb079f
MidiIn_ParseRingAndDispatch__FB086A:
	cps	de, 5                                  ; FB086A  cp DE,5
	jrl c, MidiIn_ParseRingAndDispatch__FB09ED ; FB086C  jrl C,0xfb09ed
	stb_da	(0xD7DC), h                         ; FB086F  ld (0x00d7dc),H
	incw	1, (xix)                              ; FB0874  incw 1,(XIX)
	ld	bc, (xix)                               ; FB0876  ld BC,(XIX)
	and	bc, 0xFFF                              ; FB0878  and BC,0x0fff
	exts	xbc                                   ; FB087C  exts XBC
	extpfx3 0xAE, 0xF8, 0x81                   ; FB087E  add XBC,(XIZ+0xf8)
	ld	a, (xbc)                                ; FB0881  ld A,(XBC)
	stb_da	(0xD7DD), a                         ; FB0883  ld (0x00d7dd),A
	incw	1, (xix)                              ; FB0888  incw 1,(XIX)
	ld	bc, (xix)                               ; FB088A  ld BC,(XIX)
	and	bc, 0xFFF                              ; FB088C  and BC,0x0fff
	exts	xbc                                   ; FB0890  exts XBC
	extpfx3 0xAE, 0xF8, 0x81                   ; FB0892  add XBC,(XIZ+0xf8)
	ld	a, (xbc)                                ; FB0895  ld A,(XBC)
	stb_da	(0xD7DE), a                         ; FB0897  ld (0x00d7de),A
	incw	1, (xix)                              ; FB089C  incw 1,(XIX)
	ld	bc, (xix)                               ; FB089E  ld BC,(XIX)
	and	bc, 0xFFF                              ; FB08A0  and BC,0x0fff
	exts	xbc                                   ; FB08A4  exts XBC
	extpfx3 0xAE, 0xF8, 0x81                   ; FB08A6  add XBC,(XIZ+0xf8)
	ld	a, (xbc)                                ; FB08A9  ld A,(XBC)
	stb_da	(0xD7DF), a                         ; FB08AB  ld (0x00d7df),A
	incw	1, (xix)                              ; FB08B0  incw 1,(XIX)
	ld	bc, (xix)                               ; FB08B2  ld BC,(XIX)
	and	bc, 0xFFF                              ; FB08B4  and BC,0x0fff
	exts	xbc                                   ; FB08B8  exts XBC
	extpfx3 0xAE, 0xF8, 0x81                   ; FB08BA  add XBC,(XIZ+0xf8)
	ld	a, (xbc)                                ; FB08BD  ld A,(XBC)
	stb_da	(0xD7E0), a                         ; FB08BF  ld (0x00d7e0),A
	incw	1, (xix)                              ; FB08C4  incw 1,(XIX)
	ld	xbc, (xiz-12)                           ; FB08C6  ld XBC,(XIZ+0xf4)
	decm	5, (xbc)                              ; FB08C9  decw 5,(XBC)
	dec	5, de                                  ; FB08CB  dec 5,DE
	lda	xbc, (0xD7DC:24)                       ; FB08CD  lda XBC,0x00d7dc
	push	xbc                                   ; FB08D2  push XBC
	call	0xFB6BA8                              ; FB08D3  call 0xfb6ba8
	jrl MidiIn_ParseRingAndDispatch__FB079F    ; FB08D7  jrl T,0xfb079f
MidiIn_ParseRingAndDispatch__FB08DA:
	cps	de, 4                                  ; FB08DA  cp DE,4
	jrl c, MidiIn_ParseRingAndDispatch__FB09ED ; FB08DC  jrl C,0xfb09ed
	stb_da	(0xD7E1), h                         ; FB08DF  ld (0x00d7e1),H
	incw	1, (xix)                              ; FB08E4  incw 1,(XIX)
	ld	bc, (xix)                               ; FB08E6  ld BC,(XIX)
	and	bc, 0xFFF                              ; FB08E8  and BC,0x0fff
	exts	xbc                                   ; FB08EC  exts XBC
	extpfx3 0xAE, 0xF8, 0x81                   ; FB08EE  add XBC,(XIZ+0xf8)
	ld	a, (xbc)                                ; FB08F1  ld A,(XBC)
	stb_da	(0xD7E2), a                         ; FB08F3  ld (0x00d7e2),A
	incw	1, (xix)                              ; FB08F8  incw 1,(XIX)
	ld	bc, (xix)                               ; FB08FA  ld BC,(XIX)
	and	bc, 0xFFF                              ; FB08FC  and BC,0x0fff
	exts	xbc                                   ; FB0900  exts XBC
	extpfx3 0xAE, 0xF8, 0x81                   ; FB0902  add XBC,(XIZ+0xf8)
	ld	a, (xbc)                                ; FB0905  ld A,(XBC)
	stb_da	(0xD7E3), a                         ; FB0907  ld (0x00d7e3),A
	incw	1, (xix)                              ; FB090C  incw 1,(XIX)
	ld	bc, (xix)                               ; FB090E  ld BC,(XIX)
	and	bc, 0xFFF                              ; FB0910  and BC,0x0fff
	exts	xbc                                   ; FB0914  exts XBC
	extpfx3 0xAE, 0xF8, 0x81                   ; FB0916  add XBC,(XIZ+0xf8)
	ld	a, (xbc)                                ; FB0919  ld A,(XBC)
	stb_da	(0xD7E4), a                         ; FB091B  ld (0x00d7e4),A
	incw	1, (xix)                              ; FB0920  incw 1,(XIX)
	ld	xbc, (xiz-12)                           ; FB0922  ld XBC,(XIZ+0xf4)
	decm	4, (xbc)                              ; FB0925  decw 4,(XBC)
	dec	4, de                                  ; FB0927  dec 4,DE
	lda	xbc, (0xD7E1:24)                       ; FB0929  lda XBC,0x00d7e1
	push	xbc                                   ; FB092E  push XBC
	call	0xFB0013                              ; FB092F  call 0xfb0013
	jrl MidiIn_ParseRingAndDispatch__FB079F    ; FB0933  jrl T,0xfb079f
MidiIn_ParseRingAndDispatch__FB0936:
	cps	de, 4                                  ; FB0936  cp DE,4
	jrl c, MidiIn_ParseRingAndDispatch__FB09ED ; FB0938  jrl C,0xfb09ed
	stb_da	(0xD7E5), h                         ; FB093B  ld (0x00d7e5),H
	incw	1, (xix)                              ; FB0940  incw 1,(XIX)
	ld	bc, (xix)                               ; FB0942  ld BC,(XIX)
	and	bc, 0xFFF                              ; FB0944  and BC,0x0fff
	exts	xbc                                   ; FB0948  exts XBC
	extpfx3 0xAE, 0xF8, 0x81                   ; FB094A  add XBC,(XIZ+0xf8)
	ld	a, (xbc)                                ; FB094D  ld A,(XBC)
	stb_da	(0xD7E6), a                         ; FB094F  ld (0x00d7e6),A
	incw	1, (xix)                              ; FB0954  incw 1,(XIX)
	ld	bc, (xix)                               ; FB0956  ld BC,(XIX)
	and	bc, 0xFFF                              ; FB0958  and BC,0x0fff
	exts	xbc                                   ; FB095C  exts XBC
	extpfx3 0xAE, 0xF8, 0x81                   ; FB095E  add XBC,(XIZ+0xf8)
	ld	a, (xbc)                                ; FB0961  ld A,(XBC)
	stb_da	(0xD7E7), a                         ; FB0963  ld (0x00d7e7),A
	incw	1, (xix)                              ; FB0968  incw 1,(XIX)
	ld	bc, (xix)                               ; FB096A  ld BC,(XIX)
	and	bc, 0xFFF                              ; FB096C  and BC,0x0fff
	exts	xbc                                   ; FB0970  exts XBC
	extpfx3 0xAE, 0xF8, 0x81                   ; FB0972  add XBC,(XIZ+0xf8)
	ld	a, (xbc)                                ; FB0975  ld A,(XBC)
	stb_da	(0xD7E8), a                         ; FB0977  ld (0x00d7e8),A
	incw	1, (xix)                              ; FB097C  incw 1,(XIX)
	ld	xbc, (xiz-12)                           ; FB097E  ld XBC,(XIZ+0xf4)
	decm	4, (xbc)                              ; FB0981  decw 4,(XBC)
	dec	4, de                                  ; FB0983  dec 4,DE
	lda	xbc, (0xD7E5:24)                       ; FB0985  lda XBC,0x00d7e5
	push	xbc                                   ; FB098A  push XBC
	call	0xFB0132                              ; FB098B  call 0xfb0132
	jrl MidiIn_ParseRingAndDispatch__FB079F    ; FB098F  jrl T,0xfb079f
MidiIn_ParseRingAndDispatch__FB0992:
	cps	de, 4                                  ; FB0992  cp DE,4
	jr c, MidiIn_ParseRingAndDispatch__FB09ED  ; FB0994  jr C,0xfb09ed
	stb_da	(0xD7E9), h                         ; FB0996  ld (0x00d7e9),H
	incw	1, (xix)                              ; FB099B  incw 1,(XIX)
	ld	bc, (xix)                               ; FB099D  ld BC,(XIX)
	and	bc, 0xFFF                              ; FB099F  and BC,0x0fff
	exts	xbc                                   ; FB09A3  exts XBC
	extpfx3 0xAE, 0xF8, 0x81                   ; FB09A5  add XBC,(XIZ+0xf8)
	ld	a, (xbc)                                ; FB09A8  ld A,(XBC)
	stb_da	(0xD7EA), a                         ; FB09AA  ld (0x00d7ea),A
	incw	1, (xix)                              ; FB09AF  incw 1,(XIX)
	ld	bc, (xix)                               ; FB09B1  ld BC,(XIX)
	and	bc, 0xFFF                              ; FB09B3  and BC,0x0fff
	exts	xbc                                   ; FB09B7  exts XBC
	extpfx3 0xAE, 0xF8, 0x81                   ; FB09B9  add XBC,(XIZ+0xf8)
	ld	a, (xbc)                                ; FB09BC  ld A,(XBC)
	stb_da	(0xD7EB), a                         ; FB09BE  ld (0x00d7eb),A
	incw	1, (xix)                              ; FB09C3  incw 1,(XIX)
	ld	bc, (xix)                               ; FB09C5  ld BC,(XIX)
	and	bc, 0xFFF                              ; FB09C7  and BC,0x0fff
	exts	xbc                                   ; FB09CB  exts XBC
	extpfx3 0xAE, 0xF8, 0x81                   ; FB09CD  add XBC,(XIZ+0xf8)
	ld	a, (xbc)                                ; FB09D0  ld A,(XBC)
	stb_da	(0xD7EC), a                         ; FB09D2  ld (0x00d7ec),A
	incw	1, (xix)                              ; FB09D7  incw 1,(XIX)
	ld	xbc, (xiz-12)                           ; FB09D9  ld XBC,(XIZ+0xf4)
	decm	4, (xbc)                              ; FB09DC  decw 4,(XBC)
	dec	4, de                                  ; FB09DE  dec 4,DE
	lda	xbc, (0xD7E9:24)                       ; FB09E0  lda XBC,0x00d7e9
	push	xbc                                   ; FB09E5  push XBC
	call	0xFB0338                              ; FB09E6  call 0xfb0338
	jrl MidiIn_ParseRingAndDispatch__FB079F    ; FB09EA  jrl T,0xfb079f
MidiIn_ParseRingAndDispatch__FB09ED:
	ldb	l, 0                                   ; FB09ED  ld L,0x00
	jr MidiIn_ParseRingAndDispatch__FB09FE     ; FB09EF  jr T,0xfb09fe
MidiIn_ParseRingAndDispatch__FB09F1:
	dec	1, de                                  ; FB09F1  dec 1,DE
	ld	xbc, (xiz-12)                           ; FB09F3  ld XBC,(XIZ+0xf4)
	decm	1, (xbc)                              ; FB09F6  decw 1,(XBC)
	incw	1, (xix)                              ; FB09F8  incw 1,(XIX)
MidiIn_ParseRingAndDispatch__FB09FA:
	cps	de, 0                                  ; FB09FA  cp DE,0
	jr nz, MidiIn_ParseRingAndDispatch__FB09F1 ; FB09FC  jr NZ,0xfb09f1
MidiIn_ParseRingAndDispatch__FB09FE:
	call	0xF98CB9                              ; FB09FE  call 0xf98cb9
	cps	l, 0                                   ; FB0A02  cp L,0
	jrl nz, MidiIn_ParseRingAndDispatch__FB0619 ; FB0A04  jrl NZ,0xfb0619
MidiIn_ParseRingAndDispatch__FB0A07:
	pop	xix                                    ; FB0A07  pop XIX
	popw	de                                    ; FB0A08  pop DE
	popw	hl                                    ; FB0A09  pop HL
	unlk32 xiz                                 ; FB0A0A  unlk XIZ
	ret                                        ; FB0A0C  ret
; ------------------------------------------------------------------------------
; ★ MidiMsg_SendBootSequence -- 0xFB0A0D..0xFB0A8A (126 bytes)
;
; Four MIDI messages built from literals and handed to the same handlers the ring
; parser uses.  This routine is what PROVES the 4-byte packet layout.
;
; Called from: one site, `call 0xFB0A0D` at 0xF98BB2 -- the LAST call in MAIN's
;          init chain, immediately before the loop starts.
; Inputs:  none.
; Outputs: the message buffers at 0x00D7D4, 0x00D7D8 and 0x00D7DC, and four
;          handler calls.
; Evidence: the four messages, byte for byte out of the `ld (0x00D7xx),imm8`
;          immediates (prom_c_voice_module_check.py section 3):
;              C0 00 00 00 00   -> call 0xFB6BA8   (five bytes: the 0xC0 arm of
;                                                   the parser also needs five)
;              B0 00 07 00      -> call 0xFAFDA5
;              90 00 30 01      -> calr MidiNote_Dispatch
;              B0 00 78 7F      -> call 0xFAFDA5
;          ★ 0x07 IS MIDI CONTROLLER 7, CHANNEL VOLUME, and 0x78 IS CONTROLLER
;          120, ALL SOUND OFF -- two standard controller numbers, both landing in
;          byte [2] of the packet, with their values in byte [3].  That is the
;          layout the parser's arms fill from the ring, arrived at from the other
;          end.  The note message is note 0x30 = 48 at velocity 1, the quietest
;          audible velocity.
;          The three destinations are exactly the three the parser's 0xC0, 0xB0
;          and 0x90 arms call, which is what makes them the program-change, the
;          control-change and the note handler rather than an unlabelled trio.
; Unknown:  ⚠ WHY a note-on at velocity 1 is part of a boot sequence that ends
;          with All Sound Off.  Priming the engine is the obvious reading and it
;          is not established here.
MidiMsg_SendBootSequence:
	push	xix                                   ; FB0A0D  push XIX
	lda	xix, (0xD7D8:24)                       ; FB0A0E  lda XIX,0x00d7d8
	stib_da	(0xD7DC), 0xC0                     ; FB0A13  ld (0x00d7dc),0xc0
	stib_da	(0xD7DD), 0                        ; FB0A19  ld (0x00d7dd),0x00
	stib_da	(0xD7DE), 0                        ; FB0A1F  ld (0x00d7de),0x00
	stib_da	(0xD7DF), 0                        ; FB0A25  ld (0x00d7df),0x00
	stib_da	(0xD7E0), 0                        ; FB0A2B  ld (0x00d7e0),0x00
	lda	xbc, (0xD7DC:24)                       ; FB0A31  lda XBC,0x00d7dc
	push	xbc                                   ; FB0A36  push XBC
	call	0xFB6BA8                              ; FB0A37  call 0xfb6ba8
	ld	(xix), 0xB0                             ; FB0A3B  ld (XIX),0xb0
	ld	(xix+1), 0                              ; FB0A3E  ld (XIX+0x01),0x00
	ld	(xix+2), 7                              ; FB0A42  ld (XIX+0x02),0x07
	ld	(xix+3), 0                              ; FB0A46  ld (XIX+0x03),0x00
	push	xix                                   ; FB0A4A  push XIX
	call	0xFAFDA5                              ; FB0A4B  call 0xfafda5
	stib_da	(0xD7D4), 0x90                     ; FB0A4F  ld (0x00d7d4),0x90
	stib_da	(0xD7D5), 0                        ; FB0A55  ld (0x00d7d5),0x00
	stib_da	(0xD7D6), 48                       ; FB0A5B  ld (0x00d7d6),0x30
	stib_da	(0xD7D7), 1                        ; FB0A61  ld (0x00d7d7),0x01
	lda	xbc, (0xD7D4:24)                       ; FB0A67  lda XBC,0x00d7d4
	push	xbc                                   ; FB0A6C  push XBC
	call	0xFB3F36                              ; FB0A6D  call 0xfb3f36
	ld	(xix), 0xB0                             ; FB0A71  ld (XIX),0xb0
	ld	(xix+1), 0                              ; FB0A74  ld (XIX+0x01),0x00
	ld	(xix+2), 0x78                           ; FB0A78  ld (XIX+0x02),0x78
	ld	(xix+3), 0x7F                           ; FB0A7C  ld (XIX+0x03),0x7f
	push	xix                                   ; FB0A80  push XIX
	call	0xFAFDA5                              ; FB0A81  call 0xfafda5
	inc	8, xsp                                 ; FB0A85  inc 0,XSP
	inc	8, xsp                                 ; FB0A87  inc 0,XSP
	pop	xix                                    ; FB0A89  pop XIX
	ret                                        ; FB0A8A  ret
; ------------------------------------------------------------------------------
; ★ Dev10C_ChanReset -- 0xFB0A8B..0xFB0ACF (69 bytes)
;
; The routine that ties the voice-record index to the hardware channel number.
;
; Called from: one site, `call 0xFB0A8B` at 0xFA6990 (⚠ CORRECTED 2026-08-25: this
;          said "still .incbin"; 0xFA6990 is converted).
; Inputs:  (XIZ+0x08) = n.
; Outputs: device 0x0010C000 register `n + 0xC0` := 0x0000, register `n` := 0x7E00,
;          and the word at `0x00003BCF + n*0x44 + 1` := 0.
; Evidence: ★ ONE ARGUMENT, TWO USES.  `add DE,0x00c0` then `ld (XIX),DE` /
;          `ld (XIX+0x02),0x0000` with XIX = 0x0010C000 is the select/data pair
;          notes/FINDINGS-memory-map.md documents for that device; then the same n
;          goes in unmodified for the second pair; then `ld C,0x44 / mul BC,n /
;          inc 1,BC / ld (XBC+0x3bcf),0x0000`.  So n indexes the device's channels
;          AND the 68-byte records at 0x00003BCF.  Everything else in this module
;          that touches 0x3BCF uses the same stride and the same bound.
;          The five `nop`s between the two select/data pairs are the bus-timing
;          padding every other 0x10C000 accessor in this file carries.
; Unknown:  ⚠ what registers `n` and `n+0xC0` are, and what 0x7E00 means.
;          "Reset" is the shape -- two registers driven to fixed values and a
;          record word cleared -- not a decoded meaning.
Dev10C_ChanReset:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB0A8B  link XIZ,0x0000
	pushw	hl                                   ; FB0A8F  push HL
	pushw	de                                   ; FB0A90  push DE
	push	xix                                   ; FB0A91  push XIX
	ld	hl, (xiz+8)                             ; FB0A92  ld HL,(XIZ+0x08)
	extz	hl                                    ; FB0A95  extz HL
	ld	de, hl                                  ; FB0A97  ld DE,HL
	add	de, 0xC0                               ; FB0A99  add DE,0x00c0
	ld	xix, 0x10C000                           ; FB0A9D  ld XIX,0x0010c000
	ld	(xix), de                               ; FB0AA2  ld (XIX),DE
	extpfx5 0xBC, 0x02, 0x02, 0x00, 0x00       ; FB0AA4  ld (XIX+0x02),0x0000
	nop                                        ; FB0AA9  nop
	nop                                        ; FB0AAA  nop
	nop                                        ; FB0AAB  nop
	nop                                        ; FB0AAC  nop
	nop                                        ; FB0AAD  nop
	ld	xix, 0x10C000                           ; FB0AAE  ld XIX,0x0010c000
	ld	(xix), hl                               ; FB0AB3  ld (XIX),HL
	extpfx5 0xBC, 0x02, 0x02, 0x00, 0x7E       ; FB0AB5  ld (XIX+0x02),0x7e00
	ldb	c, 68                                  ; FB0ABA  ld C,0x44
	extpfx3 0x8E, 0x08, 0x43                   ; FB0ABC  mul BC,(XIZ+0x08)
	inc	1, bc                                  ; FB0ABF  inc 1,BC
	extz	xbc                                   ; FB0AC1  extz XBC
	extpfx7 0xF3, 0xE5, 0xCF, 0x3B, 0x02, 0x00, 0x00 ; FB0AC3  ld (XBC+0x3bcf),0x0000
	pop	xix                                    ; FB0ACA  pop XIX
	popw	de                                    ; FB0ACB  pop DE
	popw	hl                                    ; FB0ACC  pop HL
	unlk32 xiz                                 ; FB0ACD  unlk XIZ
	ret                                        ; FB0ACF  ret
; ------------------------------------------------------------------------------
; VoiceRegs_Stage_A -- 0xFB0AD0..0xFB0B94 (197 bytes)
;
; Builds the two staging structs for one voice out of seventeen helper calls and
; hands them to both tone-generator writers.
;
; Called from: one site, `calr 0xFB0AD0` at 0xFB394D, inside
;          MidiNote_OnByPartMode's part-mode 0x00 arm.
; Inputs:  (XIZ+0x08) = the voice/channel number.
; Outputs: 66 bytes of stack temporaries (`add XSP,0x00000042` at 0xFB0B8A) and
;          two device writes.
; Voice record: touches voice_record[+0x03(r), +0x06(r), +0x08(r), +0x0A(r), +0x0C(r), +0x1F(r)] -- pointer built in place.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: `ld C,0x44 / mul BC,(XIZ+0x08) / ld WA,0x3bcf / add DE,BC` -- the
;          voice record again -- then a run of `call` / `push DE` pairs (23
;          DISTINCT call targets in the routine, counted by
;          `python3 notes/prom_c_voice_module_check.py` section 10, not by eye),
;          then `push &0x00D7A2` + `call 0xFC4DBD`, then
;          `push &0x00D7A2 / push voice / call Dev104_WriteAllChanRegs` (0xFB77EF,
;          converted BELOW, whose header already lists 0xFB0B71 among its call
;          sites) and `push &0x00D75E / push voice / call Dev10C_WriteAllChanRegs`
;          (0xFB713A, also below, whose header lists 0xFB0B86).  So 0x00D7A2 is the 0x104000 staging
;          struct and 0x00D75E the 0x10C000 one, for this path.
; Unknown:  ⚠ CORRECTED 2026-08-25.  This said all 21 helpers (0xFA819A, 0xFA8323,
;          0xFA8347, 0xFA842D, 0xFA8BDD, 0xFA919B, 0xFA93AF, 0xFA95D4, 0xFA9915,
;          0xFA9C60, 0xFA9F19, 0xFAA0BC, 0xFAA2B6, 0xFAA4C3, 0xFAA87E, 0xFAB5A5,
;          0xFAB79D, 0xFC4D63, 0xFC4DA1, 0xFC4DBD and 0xFC7F03) were "still
;          .incbin".  ALL TWENTY-ONE ARE CONVERTED.  What each staged word MEANS is
;          still not established, but the producers are now enumerated:
;          `python3 notes/prom_c_dev10c_field_sources.py` lists, per staged word and
;          therefore per 0x0010C000 register, every routine that writes it (70 write
;          sites over 21 of the 22 words; word 0 has none, and Dev10C_WriteAllChanRegs
;          reads none -- two independent readings agreeing).
;          ★ AND 0xFC4DBD IS THE 0x00104000 PACKER, not a helper of the same kind:
;          it takes the struct POINTER as its only argument and writes 19 offsets
;          0x00..0x24 through it -- exactly the span Dev104_WriteAllChanRegs reads.
;          Its inputs are the pointer block at RAM 0x00E082-0x00E08D, which
;          Pack104_SetInputs_PartRecord / Pack104_SetInputs_SubRecordPair / Pack104_SetInputs_E088_E089_E08A / Pack104_SetInputs_Rec0E_E08D set from the part and
;          voice records.  See notes/FINDINGS-prom_c-dev10c-producers.md.
;          ⚠ "_A" is a label for "the variant part mode 0x00 uses", nothing more.
VoiceRegs_Stage_A:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB0AD0  link XIZ,0x0000
	pushw	hl                                   ; FB0AD4  push HL
	push	xde                                   ; FB0AD5  push XDE
	ldb	c, 68                                  ; FB0AD6  ld C,0x44
	extpfx3 0x8E, 0x08, 0x43                   ; FB0AD8  mul BC,(XIZ+0x08)
	ld	hl, bc                                  ; FB0ADB  ld HL,BC
	ldw	wa, 0x3BCF                             ; FB0ADD  ld WA,0x3bcf
	ld	de, wa                                  ; FB0AE0  ld DE,WA
	add	de, bc                                 ; FB0AE2  add DE,BC
	extz	xde                                   ; FB0AE4  extz XDE
	ld	xbc, (xde+31)                           ; FB0AE6  ld XBC,(XDE+0x1f)
	ld	a, (xbc)                                ; FB0AE9  ld A,(XBC)
	pushw	wa                                   ; FB0AEB  push WA
	ld	c, (xde+12)                             ; FB0AEC  ld C,(XDE+0x0c)
	pushw	bc                                   ; FB0AEF  push BC
	ld	bc, (xde+8)                             ; FB0AF0  ld BC,(XDE+0x08)
	pushw	bc                                   ; FB0AF3  push BC
	ld	c, (xde+3)                              ; FB0AF4  ld C,(XDE+0x03)
	pushw	bc                                   ; FB0AF7  push BC
	call	0xFC4D63                              ; FB0AF8  call 0xfc4d63
	pushw	de                                   ; FB0AFC  push DE
	call	0xFC7F03                              ; FB0AFD  call 0xfc7f03
	pushw	de                                   ; FB0B01  push DE
	call	0xFA819A                              ; FB0B02  call 0xfa819a
	pushw	de                                   ; FB0B06  push DE
	call	0xFA8323                              ; FB0B07  call 0xfa8323
	pushw	de                                   ; FB0B0B  push DE
	call	0xFA8347                              ; FB0B0C  call 0xfa8347
	pushw	de                                   ; FB0B10  push DE
	call	0xFA842D                              ; FB0B11  call 0xfa842d
	pushw	de                                   ; FB0B15  push DE
	call	0xFA8BDD                              ; FB0B16  call 0xfa8bdd
	pushw	de                                   ; FB0B1A  push DE
	call	0xFA919B                              ; FB0B1B  call 0xfa919b
	pushw	de                                   ; FB0B1F  push DE
	call	0xFA93AF                              ; FB0B20  call 0xfa93af
	pushw	de                                   ; FB0B24  push DE
	call	0xFA95D4                              ; FB0B25  call 0xfa95d4
	pushw	de                                   ; FB0B29  push DE
	call	0xFA9915                              ; FB0B2A  call 0xfa9915
	pushw	de                                   ; FB0B2E  push DE
	call	0xFA9C60                              ; FB0B2F  call 0xfa9c60
	pushw	de                                   ; FB0B33  push DE
	call	0xFA9F19                              ; FB0B34  call 0xfa9f19
	pushw	de                                   ; FB0B38  push DE
	call	0xFAA0BC                              ; FB0B39  call 0xfaa0bc
	pushw	de                                   ; FB0B3D  push DE
	call	0xFAA2B6                              ; FB0B3E  call 0xfaa2b6
	pushw	de                                   ; FB0B42  push DE
	call	0xFAA4C3                              ; FB0B43  call 0xfaa4c3
	pushw	0                                    ; FB0B47  push 0x0000
	pushw	de                                   ; FB0B4A  push DE
	call	0xFAA87E                              ; FB0B4B  call 0xfaa87e
	ld	bc, (xde+10)                            ; FB0B4F  ld BC,(XDE+0x0a)
	pushw	bc                                   ; FB0B52  push BC
	ld	bc, (xde+6)                             ; FB0B53  ld BC,(XDE+0x06)
	pushw	bc                                   ; FB0B56  push BC
	call	0xFC4DA1                              ; FB0B57  call 0xfc4da1
	lda	xbc, (0xD7A2:24)                       ; FB0B5B  lda XBC,0x00d7a2
	push	xbc                                   ; FB0B60  push XBC
	call	0xFC4DBD                              ; FB0B61  call 0xfc4dbd
	lda	xbc, (0xD7A2:24)                       ; FB0B65  lda XBC,0x00d7a2
	push	xbc                                   ; FB0B6A  push XBC
	ld	hl, (xiz+8)                             ; FB0B6B  ld HL,(XIZ+0x08)
	extz	hl                                    ; FB0B6E  extz HL
	pushw	hl                                   ; FB0B70  push HL
	call	0xFB77EF                              ; FB0B71  call 0xfb77ef
	pushw	de                                   ; FB0B75  push DE
	call	0xFAB5A5                              ; FB0B76  call 0xfab5a5
	pushw	de                                   ; FB0B7A  push DE
	call	0xFAB79D                              ; FB0B7B  call 0xfab79d
	lda	xbc, (0xD75E:24)                       ; FB0B7F  lda XBC,0x00d75e
	push	xbc                                   ; FB0B84  push XBC
	pushw	hl                                   ; FB0B85  push HL
	call	0xFB713A                              ; FB0B86  call 0xfb713a
	add	xsp, 66                                ; FB0B8A  add XSP,0x00000042
	pop	xde                                    ; FB0B90  pop XDE
	popw	hl                                    ; FB0B91  pop HL
	unlk32 xiz                                 ; FB0B92  unlk XIZ
	ret                                        ; FB0B94  ret
; ------------------------------------------------------------------------------
; sub_FB0B95 -- 0xFB0B95..0xFB0E4E (698 bytes)
;
; ⚠ NOTHING IN THE IMAGE REFERENCES THIS ADDRESS.  No `call`, no `calr`, no
; `jrl`, no `jp`, and no 24-bit literal anywhere in the 512 KiB
; (notes/prom_c_voice_module_check.py --refs).  It is left as sub_ for that
; reason: a name would have to say what it is FOR, and nothing calls it.
;
; Called from: nothing found.  ★ SEARCHED NEGATIVE -- the census cannot see a
;          target computed at run time.
; Inputs:  (XIZ+0x0c) = a part index (`mul BC,0x012c` + `(XBC+0x1523)`),
;          (XIZ+0x0e) = an index into the mask/shift tables at 0xFE12AD/0xFE12B1.
; Outputs: not traced.
; Evidence: its first eleven instructions are the same shape as
;          VoiceParams_Compute_A's (0xFB0E4F, the routine immediately after it):
;          same 0x012C part stride, same 0x1523 pointer array, same `+0x12` byte,
;          same 0xFE12AD mask / 0xFE12B1 shift pair fed to Shift8_LogicalRight
;          (0xFCB23C, converted above).  Its call set is a SUBSET of that
;          routine's: both call 0xFA727D, 0xFA7F28, 0xFB5D05, 0xFB6272, 0xFC4B2E
;          and Shift8_LogicalRight, and 0xFB0E4F additionally calls MemCopyWords
;          (0xF9A038), 0xFA6BB5 and 0xFC376C.
;          "An earlier version of 0xFB0E4F that the linker kept" is the obvious
;          reading of a 698-byte unreferenced routine sitting directly in front of
;          a 4206-byte one with the same prologue.  ⚠ IT IS NOT ASSERTED.  The
;          same pattern repeats three more times in this block (sub_FB1FB1 before
;          VoiceParams_Compute_B, sub_FB289A before _C, sub_FB2F74 before _D),
;          which is what makes it worth recording at all.
;          ★ ALL FOUR SUBSET RELATIONS ARE MEASURED, and so is the shape of the
;          difference: `python3 notes/prom_c_voice_module_check.py` section 11
;          shows every orphan's `call` targets are a subset of its big routine's,
;          with ZERO exceptions in all four pairs, and that all four big routines
;          add THE SAME THREE callees the orphans lack -- MemCopyWords (0xF9A038),
;          0xFA6BB5 and 0xFC376C.  One shared difference across four independent
;          pairs is a fact; what it MEANS is still not asserted.
sub_FB0B95:
	link32 0xEE, 0x0C, 0xD4, 0xFF              ; FB0B95  link XIZ,0xffd4
	push	xhl                                   ; FB0B99  push XHL
	push	xde                                   ; FB0B9A  push XDE
	push	xix                                   ; FB0B9B  push XIX
	ld	bc, (xiz+12)                            ; FB0B9C  ld BC,(XIZ+0x0c)
	extz	bc                                    ; FB0B9F  extz BC
	mul	bc, 0x12C                              ; FB0BA1  mul BC,0x012c
	ld	ix, bc                                  ; FB0BA5  ld IX,BC
	extz	xbc                                   ; FB0BA7  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB0BA9  ld XWA,(XBC+0x1523)
	ld	l, (xwa+18)                             ; FB0BAE  ld L,(XWA+0x12)
	ld	wa, (xiz+14)                            ; FB0BB1  ld WA,(XIZ+0x0e)
	extz	wa                                    ; FB0BB4  extz WA
	extz	xwa                                   ; FB0BB6  extz XWA
	ld	(xiz-4), xwa                            ; FB0BB8  ld (XIZ+0xfc),XWA
	add	xwa, 0xFE12AD                          ; FB0BBB  add XWA,0x00fe12ad
	ld	w, (xwa)                                ; FB0BC1  ld W,(XWA)
	and	w, l                                   ; FB0BC3  and W,L
	ld	(xiz-6), w                              ; FB0BC5  ld (XIZ+0xfa),W
	lda	xiy, (0xFE12B1:24)                     ; FB0BC8  lda XIY,0xfe12b1
	extpfx3 0xAE, 0xFC, 0x85                   ; FB0BCD  add XIY,(XIZ+0xfc)
	ld	a, (xiy)                                ; FB0BD0  ld A,(XIY)
	pushw	wa                                   ; FB0BD2  push WA
	push	0                                     ; FB0BD3  push 0x00
	push	w                                     ; FB0BD5  push W
	call	0xFCB23C                              ; FB0BD7  call 0xfcb23c
	ld	h, a                                    ; FB0BDB  ld H,A
	ld	bc, ix                                  ; FB0BDD  ld BC,IX
	inc	6, bc                                  ; FB0BDF  inc 6,BC
	extz	xbc                                   ; FB0BE1  extz XBC
	ld	de, (xbc+0x1523)                        ; FB0BE3  ld DE,(XBC+0x1523)
	ldb	c, 2                                   ; FB0BE8  ld C,0x02
	extpfx3 0x8E, 0x0E, 0x43                   ; FB0BEA  mul BC,(XIZ+0x0e)
	extz	xbc                                   ; FB0BED  extz XBC
	add	xbc, 0xFDE695                          ; FB0BEF  add XBC,0x00fde695
	ld	bc, (xbc)                               ; FB0BF5  ld BC,(XBC)
	and	bc, de                                 ; FB0BF7  and BC,DE
	jrl z, sub_FB0B95__FB0E2E                  ; FB0BF9  jrl Z,0xfb0e2e
	cps	a, 2                                   ; FB0BFC  cp A,2
	jr nz, sub_FB0B95__FB0C08                  ; FB0BFE  jr NZ,0xfb0c08
	ld	bc, de                                  ; FB0C00  ld BC,DE
	and	bc, 0x2000                             ; FB0C02  and BC,0x2000
	jr z, sub_FB0B95__FB0C19                   ; FB0C06  jr Z,0xfb0c19
sub_FB0B95__FB0C08:
	cps	h, 3                                   ; FB0C08  cp H,3
	jr nz, sub_FB0B95__FB0C14                  ; FB0C0A  jr NZ,0xfb0c14
	ld	bc, de                                  ; FB0C0C  ld BC,DE
	and	bc, 0x2000                             ; FB0C0E  and BC,0x2000
	jr nz, sub_FB0B95__FB0C19                  ; FB0C12  jr NZ,0xfb0c19
sub_FB0B95__FB0C14:
	cps	h, 1                                   ; FB0C14  cp H,1
	jrl ugt, sub_FB0B95__FB0E2E                ; FB0C16  jrl UGT,0xfb0e2e
sub_FB0B95__FB0C19:
	ldb	c, 41                                  ; FB0C19  ld C,0x29
	extpfx3 0x8E, 0x10, 0x43                   ; FB0C1B  mul BC,(XIZ+0x10)
	ld	(xiz-2), bc                             ; FB0C1E  ld (XIZ+0xfe),BC
	ld	a, (xiz+12)                             ; FB0C21  ld A,(XIZ+0x0c)
	ld	(xiz-4), a                              ; FB0C24  ld (XIZ+0xfc),A
	extz	wa                                    ; FB0C27  extz WA
	mul	wa, 0x12C                              ; FB0C29  mul WA,0x012c
	ld	(xiz-6), wa                             ; FB0C2D  ld (XIZ+0xfa),WA
	add	wa, bc                                 ; FB0C30  add WA,BC
	ld	(xiz-8), wa                             ; FB0C32  ld (XIZ+0xf8),WA
	add	wa, 0x8C                               ; FB0C35  add WA,0x008c
	extz	xwa                                   ; FB0C39  extz XWA
	ld	xbc, (xwa+0x1523)                       ; FB0C3B  ld XBC,(XWA+0x1523)
	ld	(xiz-12), xbc                           ; FB0C40  ld (XIZ+0xf4),XBC
	push	xbc                                   ; FB0C43  push XBC
	push	0                                     ; FB0C44  push 0x00
	extpfx3 0x8E, 0x14, 0x04                   ; FB0C46  push (XIZ+0x14)
	call	0xFA727D                              ; FB0C49  call 0xfa727d
	ld	(xiz-14), a                             ; FB0C4D  ld (XIZ+0xf2),A
	ld	bc, (xiz-8)                             ; FB0C50  ld BC,(XIZ+0xf8)
	add	bc, 0x88                               ; FB0C53  add BC,0x0088
	extz	xbc                                   ; FB0C57  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB0C59  ld XWA,(XBC+0x1523)
	ld	(xiz-18), xwa                           ; FB0C5E  ld (XIZ+0xee),XWA
	ldb	c, 4                                   ; FB0C61  ld C,0x04
	extpfx3 0x8E, 0xF2, 0x43                   ; FB0C63  mul BC,(XIZ+0xf2)
	extpfx3 0x9E, 0xF8, 0x81                   ; FB0C66  add BC,(XIZ+0xf8)
	add	bc, 0x90                               ; FB0C69  add BC,0x0090
	extz	xbc                                   ; FB0C6D  extz XBC
	ld	xiy, (xbc+0x1523)                       ; FB0C6F  ld XIY,(XBC+0x1523)
	ld	(xiz-22), xiy                           ; FB0C74  ld (XIZ+0xea),XIY
	ld	c, (xiz+14)                             ; FB0C77  ld C,(XIZ+0x0e)
	ld	(xiz-24), c                             ; FB0C7A  ld (XIZ+0xe8),C
	mul	c, 41                                  ; FB0C7D  mul C,0x29
	extpfx3 0x9E, 0xFA, 0x81                   ; FB0C80  add BC,(XIZ+0xfa)
	add	bc, 0x88                               ; FB0C83  add BC,0x0088
	ld	(xiz-26), bc                            ; FB0C87  ld (XIZ+0xe6),BC
	ldw	bc, 0x1523                             ; FB0C8A  ld BC,0x1523
	ld	(xiz-28), bc                            ; FB0C8D  ld (XIZ+0xe4),BC
	ld	de, bc                                  ; FB0C90  ld DE,BC
	extpfx3 0x9E, 0xE6, 0x82                   ; FB0C92  add DE,(XIZ+0xe6)
	ldb	c, 68                                  ; FB0C95  ld C,0x44
	extpfx3 0x8E, 0xE8, 0x43                   ; FB0C97  mul BC,(XIZ+0xe8)
	ld	(xiz-30), bc                            ; FB0C9A  ld (XIZ+0xe2),BC
	ldw	hl, 0x5A53                             ; FB0C9D  ld HL,0x5a53
	add	hl, bc                                 ; FB0CA0  add HL,BC
	ld	c, (xiz-14)                             ; FB0CA2  ld C,(XIZ+0xf2)
	sll	c, 6                                   ; FB0CA5  sll 0x06,C
	set	2, c                                   ; FB0CA8  set 0x02,C
	extz	bc                                    ; FB0CAB  extz BC
	extz	xhl                                   ; FB0CAD  extz XHL
	ld	(xhl+1), bc                             ; FB0CAF  ld (XHL+0x01),BC
	ld	c, (xiz-24)                             ; FB0CB2  ld C,(XIZ+0xe8)
	ld	(xhl+3), c                              ; FB0CB5  ld (XHL+0x03),C
	ld	c, (xiz-4)                              ; FB0CB8  ld C,(XIZ+0xfc)
	ld	(xhl+4), c                              ; FB0CBB  ld (XHL+0x04),C
	ld	c, (xiz+18)                             ; FB0CBE  ld C,(XIZ+0x12)
	set	7, c                                   ; FB0CC1  set 0x07,C
	ld	(xhl+5), c                              ; FB0CC4  ld (XHL+0x05),C
	ld	c, (xiz+20)                             ; FB0CC7  ld C,(XIZ+0x14)
	res	7, c                                   ; FB0CCA  res 0x07,C
	ld	(xhl+12), c                             ; FB0CCD  ld (XHL+0x0c),C
	ld	bc, (xiz-28)                            ; FB0CD0  ld BC,(XIZ+0xe4)
	extpfx3 0x9E, 0xFA, 0x81                   ; FB0CD3  add BC,(XIZ+0xfa)
	ld	(xhl+35), bc                            ; FB0CD6  ld (XHL+0x23),BC
	ld	bc, (xiz-6)                             ; FB0CD9  ld BC,(XIZ+0xfa)
	extz	xbc                                   ; FB0CDC  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB0CDE  ld XWA,(XBC+0x1523)
	ld	(xiz-34), xwa                           ; FB0CE3  ld (XIZ+0xde),XWA
	ldw (xiz-36), 0x0013                       ; FB0CE6  ld (XIZ+0xdc),0x0013
	ld	bc, hl                                  ; FB0CEB  ld BC,HL
	extz	xbc                                   ; FB0CED  extz XBC
	extpfx3 0x9E, 0xDC, 0x81                   ; FB0CEF  add BC,(XIZ+0xdc)
	ld	(xbc), xwa                              ; FB0CF2  ld (XBC),XWA
	ld	xbc, (xiz-18)                           ; FB0CF4  ld XBC,(XIZ+0xee)
	ld	(xhl+23), xbc                           ; FB0CF7  ld (XHL+0x17),XBC
	ld	(xhl+37), de                            ; FB0CFA  ld (XHL+0x25),DE
	ld	xbc, (xiz-12)                           ; FB0CFD  ld XBC,(XIZ+0xf4)
	ld	(xhl+27), xbc                           ; FB0D00  ld (XHL+0x1b),XBC
	ld	xbc, (xiz-22)                           ; FB0D03  ld XBC,(XIZ+0xea)
	ld	(xhl+31), xbc                           ; FB0D06  ld (XHL+0x1f),XBC
	pushw	hl                                   ; FB0D09  push HL
	call	0xFA7F28                              ; FB0D0A  call 0xfa7f28
	push	0                                     ; FB0D0E  push 0x00
	extpfx3 0x8E, 0xE8, 0x04                   ; FB0D10  push (XIZ+0xe8)
	push	0                                     ; FB0D13  push 0x00
	extpfx3 0x8E, 0xFC, 0x04                   ; FB0D15  push (XIZ+0xfc)
	call	0xFB6272                              ; FB0D18  call 0xfb6272
	extz	wa                                    ; FB0D1C  extz WA
	ld	(xhl+43), wa                            ; FB0D1E  ld (XHL+0x2b),WA
	push	0                                     ; FB0D21  push 0x00
	extpfx3 0x8E, 0xFC, 0x04                   ; FB0D23  push (XIZ+0xfc)
	call	0xFB5D05                              ; FB0D26  call 0xfb5d05
	extz	wa                                    ; FB0D2A  extz WA
	ld	(xhl+45), wa                            ; FB0D2C  ld (XHL+0x2d),WA
	ld	bc, (xiz-36)                            ; FB0D2F  ld BC,(XIZ+0xdc)
	extpfx5 0xE3, 0x07, 0xEC, 0xE4, 0x20       ; FB0D32  ld XWA,(XHL+BC)
	ld	c, (xwa+0xD1)                           ; FB0D37  ld C,(XWA+0x00d1)
	extz	bc                                    ; FB0D3C  extz BC
	extz	xbc                                   ; FB0D3E  extz XBC
	add	xbc, 0xFDF6C5                          ; FB0D40  add XBC,0x00fdf6c5
	ld	a, (xbc)                                ; FB0D46  ld A,(XBC)
	ld	(xhl+49), a                             ; FB0D48  ld (XHL+0x31),A
	ld	bc, (xiz-36)                            ; FB0D4B  ld BC,(XIZ+0xdc)
	extpfx5 0xE3, 0x07, 0xEC, 0xE4, 0x20       ; FB0D4E  ld XWA,(XHL+BC)
	ld	c, (xwa+0xD2)                           ; FB0D53  ld C,(XWA+0x00d2)
	mul	c, 2                                   ; FB0D58  mul C,0x02
	extz	xbc                                   ; FB0D5B  extz XBC
	add	xbc, 0xFDF6E4                          ; FB0D5D  add XBC,0x00fdf6e4
	ld	bc, (xbc)                               ; FB0D63  ld BC,(XBC)
	ld	(xhl+50), bc                            ; FB0D65  ld (XHL+0x32),BC
	ld	bc, (xiz-36)                            ; FB0D68  ld BC,(XIZ+0xdc)
	extpfx5 0xE3, 0x07, 0xEC, 0xE4, 0x20       ; FB0D6B  ld XWA,(XHL+BC)
	ld	c, (xwa+0xD3)                           ; FB0D70  ld C,(XWA+0x00d3)
	mul	c, 2                                   ; FB0D75  mul C,0x02
	extz	xbc                                   ; FB0D78  extz XBC
	add	xbc, 0xFDF722                          ; FB0D7A  add XBC,0x00fdf722
	ld	bc, (xbc)                               ; FB0D80  ld BC,(XBC)
	ld	(xhl+54), bc                            ; FB0D82  ld (XHL+0x36),BC
	ld	bc, (xiz-36)                            ; FB0D85  ld BC,(XIZ+0xdc)
	extpfx5 0xE3, 0x07, 0xEC, 0xE4, 0x20       ; FB0D88  ld XWA,(XHL+BC)
	ld	c, (xwa+0xD4)                           ; FB0D8D  ld C,(XWA+0x00d4)
	mul	c, 2                                   ; FB0D92  mul C,0x02
	extz	xbc                                   ; FB0D95  extz XBC
	add	xbc, 0xFDF6E4                          ; FB0D97  add XBC,0x00fdf6e4
	ld	bc, (xbc)                               ; FB0D9D  ld BC,(XBC)
	ld	(xhl+52), bc                            ; FB0D9F  ld (XHL+0x34),BC
	ld	bc, (xiz-24)                            ; FB0DA2  ld BC,(XIZ+0xe8)
	extz	bc                                    ; FB0DA5  extz BC
	extz	xbc                                   ; FB0DA7  extz XBC
	ld	(xiz-40), xbc                           ; FB0DA9  ld (XIZ+0xd8),XBC
	add	xbc, 0xFE12A9                          ; FB0DAC  add XBC,0x00fe12a9
	ld	a, (xbc)                                ; FB0DB2  ld A,(XBC)
	set	7, a                                   ; FB0DB4  set 0x07,A
	ld	(xiz-42), a                             ; FB0DB7  ld (XIZ+0xd6),A
	ld	xbc, (xiz-40)                           ; FB0DBA  ld XBC,(XIZ+0xd8)
	inc	2, xbc                                 ; FB0DBD  inc 2,XBC
	extpfx3 0xAE, 0x08, 0x81                   ; FB0DBF  add XBC,(XIZ+0x08)
	ld	(xbc), a                                ; FB0DC2  ld (XBC),A
	ld	bc, (xhl+6)                             ; FB0DC4  ld BC,(XHL+0x06)
	pushw	bc                                   ; FB0DC7  push BC
	ld	bc, (xhl+8)                             ; FB0DC8  ld BC,(XHL+0x08)
	pushw	bc                                   ; FB0DCB  push BC
	push	0                                     ; FB0DCC  push 0x00
	extpfx3 0x8E, 0xE8, 0x04                   ; FB0DCE  push (XIZ+0xe8)
	push	0                                     ; FB0DD1  push 0x00
	extpfx3 0x8E, 0xFC, 0x04                   ; FB0DD3  push (XIZ+0xfc)
	call	0xFC4B2E                              ; FB0DD6  call 0xfc4b2e
	ld	(xiz-44), a                             ; FB0DDA  ld (XIZ+0xd4),A
	ld	xix, (xiz-40)                           ; FB0DDD  ld XIX,(XIZ+0xd8)
	inc	6, xix                                 ; FB0DE0  inc 6,XIX
	add	xsp, 22                                ; FB0DE2  add XSP,0x00000016
	cps	a, 0                                   ; FB0DE8  cp A,0
	jr z, sub_FB0B95__FB0DF6                   ; FB0DEA  jr Z,0xfb0df6
	ld	xbc, (xiz+8)                            ; FB0DEC  ld XBC,(XIZ+0x08)
	add	xbc, xix                               ; FB0DEF  add XBC,XIX
	ld	(xbc), 32                               ; FB0DF1  ld (XBC),0x20
	jr sub_FB0B95__FB0DFE                      ; FB0DF4  jr T,0xfb0dfe
sub_FB0B95__FB0DF6:
	ld	xbc, (xiz+8)                            ; FB0DF6  ld XBC,(XIZ+0x08)
	add	xbc, xix                               ; FB0DF9  add XBC,XIX
	ld	(xbc), 0                                ; FB0DFB  ld (XBC),0x00
sub_FB0B95__FB0DFE:
	extz	xhl                                   ; FB0DFE  extz XHL
	ld	bc, (xhl+43)                            ; FB0E00  ld BC,(XHL+0x2b)
	cps	bc, 0                                  ; FB0E03  cp BC,0
	jr nz, sub_FB0B95__FB0E1D                  ; FB0E05  jr NZ,0xfb0e1d
	extz	xhl                                   ; FB0E07  extz XHL
	ld	bc, (xhl+45)                            ; FB0E09  ld BC,(XHL+0x2d)
	cp	bc, 0xFF                                ; FB0E0C  cp BC,0x00ff
	jr nz, sub_FB0B95__FB0E1D                  ; FB0E10  jr NZ,0xfb0e1d
	extz	xde                                   ; FB0E12  extz XDE
	ld	bc, (xde+24)                            ; FB0E14  ld BC,(XDE+0x18)
	and	bc, 0x8000                             ; FB0E17  and BC,0x8000
	jr z, sub_FB0B95__FB0E49                   ; FB0E1B  jr Z,0xfb0e49
sub_FB0B95__FB0E1D:
	ld	bc, (xiz+14)                            ; FB0E1D  ld BC,(XIZ+0x0e)
	extz	bc                                    ; FB0E20  extz BC
	extz	xbc                                   ; FB0E22  extz XBC
	inc	6, xbc                                 ; FB0E24  inc 6,XBC
	extpfx3 0xAE, 0x08, 0x81                   ; FB0E26  add XBC,(XIZ+0x08)
	extpfx3 0x81, 0x3E, 0x80                   ; FB0E29  or (XBC),0x80
	jr sub_FB0B95__FB0E49                      ; FB0E2C  jr T,0xfb0e49
sub_FB0B95__FB0E2E:
	ld	ix, (xiz+14)                            ; FB0E2E  ld IX,(XIZ+0x0e)
	extz	ix                                    ; FB0E31  extz IX
	extz	xix                                   ; FB0E33  extz XIX
	ld	xbc, xix                                ; FB0E35  ld XBC,XIX
	inc	2, xbc                                 ; FB0E37  inc 2,XBC
	extpfx3 0xAE, 0x08, 0x81                   ; FB0E39  add XBC,(XIZ+0x08)
	ld	(xbc), 0                                ; FB0E3C  ld (XBC),0x00
	ld	xbc, xix                                ; FB0E3F  ld XBC,XIX
	inc	6, xbc                                 ; FB0E41  inc 6,XBC
	extpfx3 0xAE, 0x08, 0x81                   ; FB0E43  add XBC,(XIZ+0x08)
	ld	(xbc), 0                                ; FB0E46  ld (XBC),0x00
sub_FB0B95__FB0E49:
	pop	xix                                    ; FB0E49  pop XIX
	pop	xde                                    ; FB0E4A  pop XDE
	pop	xhl                                    ; FB0E4B  pop XHL
	unlk32 xiz                                 ; FB0E4C  unlk XIZ
	ret                                        ; FB0E4E  ret
; ------------------------------------------------------------------------------
; VoiceParams_Compute_A -- 0xFB0E4F..0xFB1EBC (4206 bytes)
;
; The largest routine in the block.  Turns a part record plus a note into the
; numbers VoiceRegs_Stage_A writes.
;
; Called from: one site, `calr 0xFB0E4F` at 0xFB38B7, in MidiNote_OnByPartMode's
;          part-mode 0x00 arm, five instructions before that arm's other calls.
; Inputs:  (XIZ+0x08) = a destination buffer, (XIZ+0x0a) and (XIZ+0x0c) = two
;          16-bit arguments, (XIZ+0x0e) = a third.  Its caller pushes
;          `&(XIZ-24)`, the voice list it is about to fill.
; Outputs: writes a 16-bit word through (XIZ+0x08); zeroes two words at +2 and +6
;          of a computed record on the way out.
; Evidence: the prologue reads the part record exactly as the rest of the block
;          does -- `mul BC,0x012c`, `ld IX,(XBC+0x1523)`, `ld C,(0xfe12ad)` /
;          `ld A,(0xfe12b1)` pushed into Shift8_LogicalRight (0xFCB23C) -- so
;          0xFE12AD.. and 0xFE12B1.. are a four-entry MASK table and a four-entry
;          SHIFT table for 2-bit fields: the ROM holds `03 0C 30 C0` at 0xFE12AD
;          and `00 02 04 06` at 0xFE12B1, and `(field & mask) >> shift` is exactly
;          what the two loads plus that call compute.
;          It reads the 32-bit words at 0xFDE695-0xFDE69B and the whole
;          0xFE12A9-0xFE12B4 tail (⚠ CORRECTED 2026-08-25: "still .incbin" -- that
;          tail is converted; this is still the routine that gives those bytes a
;          consumer).
; Unknown:  ⚠ every individual parameter.  1416 instructions of arithmetic whose
;          operands are all still-unconverted tables is not something this pass
;          decodes; what is established is the ROUTINE'S PLACE in the chain, not
;          its formulae.
VoiceParams_Compute_A:
	link32 0xEE, 0x0C, 0xD8, 0xFF              ; FB0E4F  link XIZ,0xffd8
	push	xhl                                   ; FB0E53  push XHL
	push	xde                                   ; FB0E54  push XDE
	push	xix                                   ; FB0E55  push XIX
	ld	de, (xiz+12)                            ; FB0E56  ld DE,(XIZ+0x0c)
	extz	de                                    ; FB0E59  extz DE
	ld	bc, de                                  ; FB0E5B  ld BC,DE
	sll	bc, 8                                  ; FB0E5D  sll 0x08,BC
	ld	(xiz-8), bc                             ; FB0E60  ld (XIZ+0xf8),BC
	ld	wa, (xiz+14)                            ; FB0E63  ld WA,(XIZ+0x0e)
	extz	wa                                    ; FB0E66  extz WA
	or	bc, wa                                  ; FB0E68  or BC,WA
	set	7, bc                                  ; FB0E6A  set 0x07,BC
	ld	xwa, (xiz+8)                            ; FB0E6D  ld XWA,(XIZ+0x08)
	ld	(xwa), bc                               ; FB0E70  ld (XWA),BC
	ldw	bc, 0x12C                              ; FB0E72  ld BC,0x012c
	mul	xbc, xde                               ; FB0E75  mul XBC,DE
	ld	hl, bc                                  ; FB0E77  ld HL,BC
	inc	6, bc                                  ; FB0E79  inc 6,BC
	extz	xbc                                   ; FB0E7B  extz XBC
	ld	ix, (xbc+0x1523)                        ; FB0E7D  ld IX,(XBC+0x1523)
	ld	bc, ix                                  ; FB0E82  ld BC,IX
	and	bc, 0x4000                             ; FB0E84  and BC,0x4000
	jrl z, VoiceParams_Compute_A__FB10AA       ; FB0E88  jrl Z,0xfb10aa
	extz	xhl                                   ; FB0E8B  extz XHL
	ld	xbc, (xhl+0x1523)                       ; FB0E8D  ld XBC,(XHL+0x1523)
	ld	e, (xbc+18)                             ; FB0E92  ld E,(XBC+0x12)
	ldb_da	c, (0xFE12AD)                       ; FB0E95  ld C,(0xfe12ad)
	and	c, e                                   ; FB0E9A  and C,E
	ld	(xiz-8), c                              ; FB0E9C  ld (XIZ+0xf8),C
	ldb_da	a, (0xFE12B1)                       ; FB0E9F  ld A,(0xfe12b1)
	pushw	wa                                   ; FB0EA4  push WA
	pushw	bc                                   ; FB0EA5  push BC
	call	0xFCB23C                              ; FB0EA6  call 0xfcb23c
	ld	d, a                                    ; FB0EAA  ld D,A
	ld	hl, ix                                  ; FB0EAC  ld HL,IX
	ldw_da	bc, (0xFDE695)                      ; FB0EAE  ld BC,(0xfde695)
	and	bc, hl                                 ; FB0EB3  and BC,HL
	jrl z, VoiceParams_Compute_A__FB1099       ; FB0EB5  jrl Z,0xfb1099
	cps	a, 2                                   ; FB0EB8  cp A,2
	jr nz, VoiceParams_Compute_A__FB0EC4       ; FB0EBA  jr NZ,0xfb0ec4
	ld	bc, hl                                  ; FB0EBC  ld BC,HL
	and	bc, 0x2000                             ; FB0EBE  and BC,0x2000
	jr z, VoiceParams_Compute_A__FB0ED5        ; FB0EC2  jr Z,0xfb0ed5
VoiceParams_Compute_A__FB0EC4:
	cps	d, 3                                   ; FB0EC4  cp D,3
	jr nz, VoiceParams_Compute_A__FB0ED0       ; FB0EC6  jr NZ,0xfb0ed0
	ld	bc, hl                                  ; FB0EC8  ld BC,HL
	and	bc, 0x2000                             ; FB0ECA  and BC,0x2000
	jr nz, VoiceParams_Compute_A__FB0ED5       ; FB0ECE  jr NZ,0xfb0ed5
VoiceParams_Compute_A__FB0ED0:
	cps	d, 1                                   ; FB0ED0  cp D,1
	jrl ugt, VoiceParams_Compute_A__FB1099     ; FB0ED2  jrl UGT,0xfb1099
VoiceParams_Compute_A__FB0ED5:
	ld	c, (xiz+12)                             ; FB0ED5  ld C,(XIZ+0x0c)
	ld	(xiz-8), c                              ; FB0ED8  ld (XIZ+0xf8),C
	extz	bc                                    ; FB0EDB  extz BC
	mul	bc, 0x12C                              ; FB0EDD  mul BC,0x012c
	ld	ix, bc                                  ; FB0EE1  ld IX,BC
	add	bc, 41                                 ; FB0EE3  add BC,0x0029
	ld	(xiz-10), bc                            ; FB0EE7  ld (XIZ+0xf6),BC
	ld	wa, ix                                  ; FB0EEA  ld WA,IX
	add	wa, 0xB5                               ; FB0EEC  add WA,0x00b5
	extz	xwa                                   ; FB0EF0  extz XWA
	ld	xiy, (xwa+0x1523)                       ; FB0EF2  ld XIY,(XWA+0x1523)
	ld	(xiz-14), xiy                           ; FB0EF7  ld (XIZ+0xf2),XIY
	push	xiy                                   ; FB0EFA  push XIY
	push	0                                     ; FB0EFB  push 0x00
	extpfx3 0x8E, 0x10, 0x04                   ; FB0EFD  push (XIZ+0x10)
	call	0xFA727D                              ; FB0F00  call 0xfa727d
	ld	(xiz-16), a                             ; FB0F04  ld (XIZ+0xf0),A
	ld	bc, ix                                  ; FB0F07  ld BC,IX
	add	bc, 0xB1                               ; FB0F09  add BC,0x00b1
	extz	xbc                                   ; FB0F0D  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB0F0F  ld XWA,(XBC+0x1523)
	ld	(xiz-20), xwa                           ; FB0F14  ld (XIZ+0xec),XWA
	ldb	c, 4                                   ; FB0F17  ld C,0x04
	extpfx3 0x8E, 0xF0, 0x43                   ; FB0F19  mul BC,(XIZ+0xf0)
	extpfx3 0x9E, 0xF6, 0x81                   ; FB0F1C  add BC,(XIZ+0xf6)
	add	bc, 0x90                               ; FB0F1F  add BC,0x0090
	extz	xbc                                   ; FB0F23  extz XBC
	ld	xiy, (xbc+0x1523)                       ; FB0F25  ld XIY,(XBC+0x1523)
	ld	(xiz-24), xiy                           ; FB0F2A  ld (XIZ+0xe8),XIY
	ld	bc, ix                                  ; FB0F2D  ld BC,IX
	add	bc, 0x88                               ; FB0F2F  add BC,0x0088
	ld	(xiz-26), bc                            ; FB0F33  ld (XIZ+0xe6),BC
	ldw	bc, 0x1523                             ; FB0F36  ld BC,0x1523
	ld	(xiz-28), bc                            ; FB0F39  ld (XIZ+0xe4),BC
	ld	de, bc                                  ; FB0F3C  ld DE,BC
	extpfx3 0x9E, 0xE6, 0x82                   ; FB0F3E  add DE,(XIZ+0xe6)
	ldw	hl, 0x5A53                             ; FB0F41  ld HL,0x5a53
	ld	w, (xiz-16)                             ; FB0F44  ld W,(XIZ+0xf0)
	sll	w, 6                                   ; FB0F47  sll 0x06,W
	set	2, w                                   ; FB0F4A  set 0x02,W
	ld	a, w                                    ; FB0F4D  ld A,W
	extz	wa                                    ; FB0F4F  extz WA
	extz	xhl                                   ; FB0F51  extz XHL
	ld	(xhl+1), wa                             ; FB0F53  ld (XHL+0x01),WA
	ld	(xhl+3), 0                              ; FB0F56  ld (XHL+0x03),0x00
	ld	c, (xiz-8)                              ; FB0F5A  ld C,(XIZ+0xf8)
	ld	(xhl+4), c                              ; FB0F5D  ld (XHL+0x04),C
	ld	c, (xiz+14)                             ; FB0F60  ld C,(XIZ+0x0e)
	set	7, c                                   ; FB0F63  set 0x07,C
	ld	(xhl+5), c                              ; FB0F66  ld (XHL+0x05),C
	ld	c, (xiz+16)                             ; FB0F69  ld C,(XIZ+0x10)
	res	7, c                                   ; FB0F6C  res 0x07,C
	ld	(xhl+12), c                             ; FB0F6F  ld (XHL+0x0c),C
	ld	bc, (xiz-28)                            ; FB0F72  ld BC,(XIZ+0xe4)
	add	bc, ix                                 ; FB0F75  add BC,IX
	ld	(xhl+35), bc                            ; FB0F77  ld (XHL+0x23),BC
	extz	xix                                   ; FB0F7A  extz XIX
	ld	xbc, (xix+0x1523)                       ; FB0F7C  ld XBC,(XIX+0x1523)
	ld	(xiz-32), xbc                           ; FB0F81  ld (XIZ+0xe0),XBC
	ldw	ix, 19                                 ; FB0F84  ld IX,0x0013
	ld	wa, hl                                  ; FB0F87  ld WA,HL
	extz	xwa                                   ; FB0F89  extz XWA
	add	wa, ix                                 ; FB0F8B  add WA,IX
	ld	(xwa), xbc                              ; FB0F8D  ld (XWA),XBC
	ld	xbc, (xiz-20)                           ; FB0F8F  ld XBC,(XIZ+0xec)
	ld	(xhl+23), xbc                           ; FB0F92  ld (XHL+0x17),XBC
	ld	(xhl+37), de                            ; FB0F95  ld (XHL+0x25),DE
	ld	xbc, (xiz-14)                           ; FB0F98  ld XBC,(XIZ+0xf2)
	ld	(xhl+27), xbc                           ; FB0F9B  ld (XHL+0x1b),XBC
	ld	xbc, (xiz-24)                           ; FB0F9E  ld XBC,(XIZ+0xe8)
	ld	(xhl+31), xbc                           ; FB0FA1  ld (XHL+0x1f),XBC
	pushw	hl                                   ; FB0FA4  push HL
	call	0xFA7F28                              ; FB0FA5  call 0xfa7f28
	pushw	0                                    ; FB0FA9  push 0x0000
	push	0                                     ; FB0FAC  push 0x00
	extpfx3 0x8E, 0xF8, 0x04                   ; FB0FAE  push (XIZ+0xf8)
	call	0xFB6272                              ; FB0FB1  call 0xfb6272
	extz	wa                                    ; FB0FB5  extz WA
	ld	(xhl+43), wa                            ; FB0FB7  ld (XHL+0x2b),WA
	push	0                                     ; FB0FBA  push 0x00
	extpfx3 0x8E, 0xF8, 0x04                   ; FB0FBC  push (XIZ+0xf8)
	call	0xFB5D05                              ; FB0FBF  call 0xfb5d05
	extz	wa                                    ; FB0FC3  extz WA
	ld	(xhl+45), wa                            ; FB0FC5  ld (XHL+0x2d),WA
	extpfx5 0xE3, 0x07, 0xEC, 0xF0, 0x21       ; FB0FC8  ld XBC,(XHL+IX)
	ld	a, (xbc+0xD1)                           ; FB0FCD  ld A,(XBC+0x00d1)
	extz	wa                                    ; FB0FD2  extz WA
	extz	xwa                                   ; FB0FD4  extz XWA
	add	xwa, 0xFDF6C5                          ; FB0FD6  add XWA,0x00fdf6c5
	ld	c, (xwa)                                ; FB0FDC  ld C,(XWA)
	ld	(xhl+49), c                             ; FB0FDE  ld (XHL+0x31),C
	extpfx5 0xE3, 0x07, 0xEC, 0xF0, 0x21       ; FB0FE1  ld XBC,(XHL+IX)
	ld	a, (xbc+0xD2)                           ; FB0FE6  ld A,(XBC+0x00d2)
	mul	a, 2                                   ; FB0FEB  mul A,0x02
	extz	xwa                                   ; FB0FEE  extz XWA
	add	xwa, 0xFDF6E4                          ; FB0FF0  add XWA,0x00fdf6e4
	ld	bc, (xwa)                               ; FB0FF6  ld BC,(XWA)
	ld	(xhl+50), bc                            ; FB0FF8  ld (XHL+0x32),BC
	extpfx5 0xE3, 0x07, 0xEC, 0xF0, 0x21       ; FB0FFB  ld XBC,(XHL+IX)
	ld	a, (xbc+0xD3)                           ; FB1000  ld A,(XBC+0x00d3)
	mul	a, 2                                   ; FB1005  mul A,0x02
	extz	xwa                                   ; FB1008  extz XWA
	add	xwa, 0xFDF722                          ; FB100A  add XWA,0x00fdf722
	ld	bc, (xwa)                               ; FB1010  ld BC,(XWA)
	ld	(xhl+54), bc                            ; FB1012  ld (XHL+0x36),BC
	extpfx5 0xE3, 0x07, 0xEC, 0xF0, 0x21       ; FB1015  ld XBC,(XHL+IX)
	ld	a, (xbc+0xD4)                           ; FB101A  ld A,(XBC+0x00d4)
	mul	a, 2                                   ; FB101F  mul A,0x02
	extz	xwa                                   ; FB1022  extz XWA
	add	xwa, 0xFDF6E4                          ; FB1024  add XWA,0x00fdf6e4
	ld	bc, (xwa)                               ; FB102A  ld BC,(XWA)
	ld	(xhl+52), bc                            ; FB102C  ld (XHL+0x34),BC
	ldb_da	c, (0xFE12A9)                       ; FB102F  ld C,(0xfe12a9)
	set	7, c                                   ; FB1034  set 0x07,C
	ld	(xiz-34), c                             ; FB1037  ld (XIZ+0xde),C
	ld	xbc, (xiz+8)                            ; FB103A  ld XBC,(XIZ+0x08)
	ld	a, (xiz-34)                             ; FB103D  ld A,(XIZ+0xde)
	ld	(xbc+2), a                              ; FB1040  ld (XBC+0x02),A
	ld	bc, (xhl+6)                             ; FB1043  ld BC,(XHL+0x06)
	pushw	bc                                   ; FB1046  push BC
	ld	bc, (xhl+8)                             ; FB1047  ld BC,(XHL+0x08)
	pushw	bc                                   ; FB104A  push BC
	pushw	0                                    ; FB104B  push 0x0000
	push	0                                     ; FB104E  push 0x00
	extpfx3 0x8E, 0xF8, 0x04                   ; FB1050  push (XIZ+0xf8)
	call	0xFC4B2E                              ; FB1053  call 0xfc4b2e
	add	xsp, 22                                ; FB1057  add XSP,0x00000016
	cps	a, 0                                   ; FB105D  cp A,0
	jr z, VoiceParams_Compute_A__FB106A        ; FB105F  jr Z,0xfb106a
	ld	xbc, (xiz+8)                            ; FB1061  ld XBC,(XIZ+0x08)
	ld	(xbc+6), 32                             ; FB1064  ld (XBC+0x06),0x20
	jr VoiceParams_Compute_A__FB1071           ; FB1068  jr T,0xfb1071
VoiceParams_Compute_A__FB106A:
	ld	xbc, (xiz+8)                            ; FB106A  ld XBC,(XIZ+0x08)
	ld	(xbc+6), 0                              ; FB106D  ld (XBC+0x06),0x00
VoiceParams_Compute_A__FB1071:
	extz	xhl                                   ; FB1071  extz XHL
	ld	bc, (xhl+43)                            ; FB1073  ld BC,(XHL+0x2b)
	cps	bc, 0                                  ; FB1076  cp BC,0
	jr nz, VoiceParams_Compute_A__FB1090       ; FB1078  jr NZ,0xfb1090
	extz	xhl                                   ; FB107A  extz XHL
	ld	bc, (xhl+45)                            ; FB107C  ld BC,(XHL+0x2d)
	cp	bc, 0xFF                                ; FB107F  cp BC,0x00ff
	jr nz, VoiceParams_Compute_A__FB1090       ; FB1083  jr NZ,0xfb1090
	extz	xde                                   ; FB1085  extz XDE
	ld	bc, (xde+24)                            ; FB1087  ld BC,(XDE+0x18)
	and	bc, 0x8000                             ; FB108A  and BC,0x8000
	jr z, VoiceParams_Compute_A__FB10A7        ; FB108E  jr Z,0xfb10a7
VoiceParams_Compute_A__FB1090:
	ld	xbc, (xiz+8)                            ; FB1090  ld XBC,(XIZ+0x08)
	extpfx4 0x89, 0x06, 0x3E, 0x80             ; FB1093  or (XBC+0x06),0x80
	jr VoiceParams_Compute_A__FB10A7           ; FB1097  jr T,0xfb10a7
VoiceParams_Compute_A__FB1099:
	ld	xbc, (xiz+8)                            ; FB1099  ld XBC,(XIZ+0x08)
	ld	(xbc+2), 0                              ; FB109C  ld (XBC+0x02),0x00
	ld	xbc, (xiz+8)                            ; FB10A0  ld XBC,(XIZ+0x08)
	ld	(xbc+6), 0                              ; FB10A3  ld (XBC+0x06),0x00
VoiceParams_Compute_A__FB10A7:
	jrl VoiceParams_Compute_A__FB12B6          ; FB10A7  jrl T,0xfb12b6
VoiceParams_Compute_A__FB10AA:
	extz	xhl                                   ; FB10AA  extz XHL
	ld	xbc, (xhl+0x1523)                       ; FB10AC  ld XBC,(XHL+0x1523)
	ld	e, (xbc+18)                             ; FB10B1  ld E,(XBC+0x12)
	ldb_da	c, (0xFE12AD)                       ; FB10B4  ld C,(0xfe12ad)
	and	c, e                                   ; FB10B9  and C,E
	ld	(xiz-8), c                              ; FB10BB  ld (XIZ+0xf8),C
	ldb_da	a, (0xFE12B1)                       ; FB10BE  ld A,(0xfe12b1)
	pushw	wa                                   ; FB10C3  push WA
	pushw	bc                                   ; FB10C4  push BC
	call	0xFCB23C                              ; FB10C5  call 0xfcb23c
	ld	d, a                                    ; FB10C9  ld D,A
	ld	hl, ix                                  ; FB10CB  ld HL,IX
	ldw_da	bc, (0xFDE695)                      ; FB10CD  ld BC,(0xfde695)
	and	bc, hl                                 ; FB10D2  and BC,HL
	jrl z, VoiceParams_Compute_A__FB12A8       ; FB10D4  jrl Z,0xfb12a8
	cps	a, 2                                   ; FB10D7  cp A,2
	jr nz, VoiceParams_Compute_A__FB10E3       ; FB10D9  jr NZ,0xfb10e3
	ld	bc, hl                                  ; FB10DB  ld BC,HL
	and	bc, 0x2000                             ; FB10DD  and BC,0x2000
	jr z, VoiceParams_Compute_A__FB10F4        ; FB10E1  jr Z,0xfb10f4
VoiceParams_Compute_A__FB10E3:
	cps	d, 3                                   ; FB10E3  cp D,3
	jr nz, VoiceParams_Compute_A__FB10EF       ; FB10E5  jr NZ,0xfb10ef
	ld	bc, hl                                  ; FB10E7  ld BC,HL
	and	bc, 0x2000                             ; FB10E9  and BC,0x2000
	jr nz, VoiceParams_Compute_A__FB10F4       ; FB10ED  jr NZ,0xfb10f4
VoiceParams_Compute_A__FB10EF:
	cps	d, 1                                   ; FB10EF  cp D,1
	jrl ugt, VoiceParams_Compute_A__FB12A8     ; FB10F1  jrl UGT,0xfb12a8
VoiceParams_Compute_A__FB10F4:
	ld	c, (xiz+12)                             ; FB10F4  ld C,(XIZ+0x0c)
	ld	(xiz-8), c                              ; FB10F7  ld (XIZ+0xf8),C
	extz	bc                                    ; FB10FA  extz BC
	mul	bc, 0x12C                              ; FB10FC  mul BC,0x012c
	ld	ix, bc                                  ; FB1100  ld IX,BC
	add	bc, 0x8C                               ; FB1102  add BC,0x008c
	extz	xbc                                   ; FB1106  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB1108  ld XWA,(XBC+0x1523)
	ld	(xiz-12), xwa                           ; FB110D  ld (XIZ+0xf4),XWA
	push	xwa                                   ; FB1110  push XWA
	push	0                                     ; FB1111  push 0x00
	extpfx3 0x8E, 0x10, 0x04                   ; FB1113  push (XIZ+0x10)
	call	0xFA727D                              ; FB1116  call 0xfa727d
	ld	(xiz-14), a                             ; FB111A  ld (XIZ+0xf2),A
	ld	bc, ix                                  ; FB111D  ld BC,IX
	add	bc, 0x88                               ; FB111F  add BC,0x0088
	ld	(xiz-16), bc                            ; FB1123  ld (XIZ+0xf0),BC
	extz	xbc                                   ; FB1126  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB1128  ld XWA,(XBC+0x1523)
	ld	(xiz-20), xwa                           ; FB112D  ld (XIZ+0xec),XWA
	ldb	c, 4                                   ; FB1130  ld C,0x04
	extpfx3 0x8E, 0xF2, 0x43                   ; FB1132  mul BC,(XIZ+0xf2)
	add	bc, ix                                 ; FB1135  add BC,IX
	add	bc, 0x90                               ; FB1137  add BC,0x0090
	extz	xbc                                   ; FB113B  extz XBC
	ld	xiy, (xbc+0x1523)                       ; FB113D  ld XIY,(XBC+0x1523)
	ld	(xiz-24), xiy                           ; FB1142  ld (XIZ+0xe8),XIY
	ldw	bc, 0x1523                             ; FB1145  ld BC,0x1523
	ld	(xiz-26), bc                            ; FB1148  ld (XIZ+0xe6),BC
	ld	de, bc                                  ; FB114B  ld DE,BC
	extpfx3 0x9E, 0xF0, 0x82                   ; FB114D  add DE,(XIZ+0xf0)
	ldw	hl, 0x5A53                             ; FB1150  ld HL,0x5a53
	ld	w, (xiz-14)                             ; FB1153  ld W,(XIZ+0xf2)
	sll	w, 6                                   ; FB1156  sll 0x06,W
	set	2, w                                   ; FB1159  set 0x02,W
	ld	a, w                                    ; FB115C  ld A,W
	extz	wa                                    ; FB115E  extz WA
	extz	xhl                                   ; FB1160  extz XHL
	ld	(xhl+1), wa                             ; FB1162  ld (XHL+0x01),WA
	ld	(xhl+3), 0                              ; FB1165  ld (XHL+0x03),0x00
	ld	c, (xiz-8)                              ; FB1169  ld C,(XIZ+0xf8)
	ld	(xhl+4), c                              ; FB116C  ld (XHL+0x04),C
	ld	c, (xiz+14)                             ; FB116F  ld C,(XIZ+0x0e)
	set	7, c                                   ; FB1172  set 0x07,C
	ld	(xhl+5), c                              ; FB1175  ld (XHL+0x05),C
	ld	c, (xiz+16)                             ; FB1178  ld C,(XIZ+0x10)
	res	7, c                                   ; FB117B  res 0x07,C
	ld	(xhl+12), c                             ; FB117E  ld (XHL+0x0c),C
	ld	bc, (xiz-26)                            ; FB1181  ld BC,(XIZ+0xe6)
	add	bc, ix                                 ; FB1184  add BC,IX
	ld	(xhl+35), bc                            ; FB1186  ld (XHL+0x23),BC
	extz	xix                                   ; FB1189  extz XIX
	ld	xbc, (xix+0x1523)                       ; FB118B  ld XBC,(XIX+0x1523)
	ld	(xiz-30), xbc                           ; FB1190  ld (XIZ+0xe2),XBC
	ldw	ix, 19                                 ; FB1193  ld IX,0x0013
	ld	wa, hl                                  ; FB1196  ld WA,HL
	extz	xwa                                   ; FB1198  extz XWA
	add	wa, ix                                 ; FB119A  add WA,IX
	ld	(xwa), xbc                              ; FB119C  ld (XWA),XBC
	ld	xbc, (xiz-20)                           ; FB119E  ld XBC,(XIZ+0xec)
	ld	(xhl+23), xbc                           ; FB11A1  ld (XHL+0x17),XBC
	ld	(xhl+37), de                            ; FB11A4  ld (XHL+0x25),DE
	ld	xbc, (xiz-12)                           ; FB11A7  ld XBC,(XIZ+0xf4)
	ld	(xhl+27), xbc                           ; FB11AA  ld (XHL+0x1b),XBC
	ld	xbc, (xiz-24)                           ; FB11AD  ld XBC,(XIZ+0xe8)
	ld	(xhl+31), xbc                           ; FB11B0  ld (XHL+0x1f),XBC
	pushw	hl                                   ; FB11B3  push HL
	call	0xFA7F28                              ; FB11B4  call 0xfa7f28
	pushw	0                                    ; FB11B8  push 0x0000
	push	0                                     ; FB11BB  push 0x00
	extpfx3 0x8E, 0xF8, 0x04                   ; FB11BD  push (XIZ+0xf8)
	call	0xFB6272                              ; FB11C0  call 0xfb6272
	extz	wa                                    ; FB11C4  extz WA
	ld	(xhl+43), wa                            ; FB11C6  ld (XHL+0x2b),WA
	push	0                                     ; FB11C9  push 0x00
	extpfx3 0x8E, 0xF8, 0x04                   ; FB11CB  push (XIZ+0xf8)
	call	0xFB5D05                              ; FB11CE  call 0xfb5d05
	extz	wa                                    ; FB11D2  extz WA
	ld	(xhl+45), wa                            ; FB11D4  ld (XHL+0x2d),WA
	extpfx5 0xE3, 0x07, 0xEC, 0xF0, 0x21       ; FB11D7  ld XBC,(XHL+IX)
	ld	a, (xbc+0xD1)                           ; FB11DC  ld A,(XBC+0x00d1)
	extz	wa                                    ; FB11E1  extz WA
	extz	xwa                                   ; FB11E3  extz XWA
	add	xwa, 0xFDF6C5                          ; FB11E5  add XWA,0x00fdf6c5
	ld	c, (xwa)                                ; FB11EB  ld C,(XWA)
	ld	(xhl+49), c                             ; FB11ED  ld (XHL+0x31),C
	extpfx5 0xE3, 0x07, 0xEC, 0xF0, 0x21       ; FB11F0  ld XBC,(XHL+IX)
	ld	a, (xbc+0xD2)                           ; FB11F5  ld A,(XBC+0x00d2)
	mul	a, 2                                   ; FB11FA  mul A,0x02
	extz	xwa                                   ; FB11FD  extz XWA
	add	xwa, 0xFDF6E4                          ; FB11FF  add XWA,0x00fdf6e4
	ld	bc, (xwa)                               ; FB1205  ld BC,(XWA)
	ld	(xhl+50), bc                            ; FB1207  ld (XHL+0x32),BC
	extpfx5 0xE3, 0x07, 0xEC, 0xF0, 0x21       ; FB120A  ld XBC,(XHL+IX)
	ld	a, (xbc+0xD3)                           ; FB120F  ld A,(XBC+0x00d3)
	mul	a, 2                                   ; FB1214  mul A,0x02
	extz	xwa                                   ; FB1217  extz XWA
	add	xwa, 0xFDF722                          ; FB1219  add XWA,0x00fdf722
	ld	bc, (xwa)                               ; FB121F  ld BC,(XWA)
	ld	(xhl+54), bc                            ; FB1221  ld (XHL+0x36),BC
	extpfx5 0xE3, 0x07, 0xEC, 0xF0, 0x21       ; FB1224  ld XBC,(XHL+IX)
	ld	a, (xbc+0xD4)                           ; FB1229  ld A,(XBC+0x00d4)
	mul	a, 2                                   ; FB122E  mul A,0x02
	extz	xwa                                   ; FB1231  extz XWA
	add	xwa, 0xFDF6E4                          ; FB1233  add XWA,0x00fdf6e4
	ld	bc, (xwa)                               ; FB1239  ld BC,(XWA)
	ld	(xhl+52), bc                            ; FB123B  ld (XHL+0x34),BC
	ldb_da	c, (0xFE12A9)                       ; FB123E  ld C,(0xfe12a9)
	set	7, c                                   ; FB1243  set 0x07,C
	ld	(xiz-32), c                             ; FB1246  ld (XIZ+0xe0),C
	ld	xbc, (xiz+8)                            ; FB1249  ld XBC,(XIZ+0x08)
	ld	a, (xiz-32)                             ; FB124C  ld A,(XIZ+0xe0)
	ld	(xbc+2), a                              ; FB124F  ld (XBC+0x02),A
	ld	bc, (xhl+6)                             ; FB1252  ld BC,(XHL+0x06)
	pushw	bc                                   ; FB1255  push BC
	ld	bc, (xhl+8)                             ; FB1256  ld BC,(XHL+0x08)
	pushw	bc                                   ; FB1259  push BC
	pushw	0                                    ; FB125A  push 0x0000
	push	0                                     ; FB125D  push 0x00
	extpfx3 0x8E, 0xF8, 0x04                   ; FB125F  push (XIZ+0xf8)
	call	0xFC4B2E                              ; FB1262  call 0xfc4b2e
	add	xsp, 22                                ; FB1266  add XSP,0x00000016
	cps	a, 0                                   ; FB126C  cp A,0
	jr z, VoiceParams_Compute_A__FB1279        ; FB126E  jr Z,0xfb1279
	ld	xbc, (xiz+8)                            ; FB1270  ld XBC,(XIZ+0x08)
	ld	(xbc+6), 32                             ; FB1273  ld (XBC+0x06),0x20
	jr VoiceParams_Compute_A__FB1280           ; FB1277  jr T,0xfb1280
VoiceParams_Compute_A__FB1279:
	ld	xbc, (xiz+8)                            ; FB1279  ld XBC,(XIZ+0x08)
	ld	(xbc+6), 0                              ; FB127C  ld (XBC+0x06),0x00
VoiceParams_Compute_A__FB1280:
	extz	xhl                                   ; FB1280  extz XHL
	ld	bc, (xhl+43)                            ; FB1282  ld BC,(XHL+0x2b)
	cps	bc, 0                                  ; FB1285  cp BC,0
	jr nz, VoiceParams_Compute_A__FB129F       ; FB1287  jr NZ,0xfb129f
	extz	xhl                                   ; FB1289  extz XHL
	ld	bc, (xhl+45)                            ; FB128B  ld BC,(XHL+0x2d)
	cp	bc, 0xFF                                ; FB128E  cp BC,0x00ff
	jr nz, VoiceParams_Compute_A__FB129F       ; FB1292  jr NZ,0xfb129f
	extz	xde                                   ; FB1294  extz XDE
	ld	bc, (xde+24)                            ; FB1296  ld BC,(XDE+0x18)
	and	bc, 0x8000                             ; FB1299  and BC,0x8000
	jr z, VoiceParams_Compute_A__FB12B6        ; FB129D  jr Z,0xfb12b6
VoiceParams_Compute_A__FB129F:
	ld	xbc, (xiz+8)                            ; FB129F  ld XBC,(XIZ+0x08)
	extpfx4 0x89, 0x06, 0x3E, 0x80             ; FB12A2  or (XBC+0x06),0x80
	jr VoiceParams_Compute_A__FB12B6           ; FB12A6  jr T,0xfb12b6
VoiceParams_Compute_A__FB12A8:
	ld	xbc, (xiz+8)                            ; FB12A8  ld XBC,(XIZ+0x08)
	ld	(xbc+2), 0                              ; FB12AB  ld (XBC+0x02),0x00
	ld	xbc, (xiz+8)                            ; FB12AF  ld XBC,(XIZ+0x08)
	ld	(xbc+6), 0                              ; FB12B2  ld (XBC+0x06),0x00
VoiceParams_Compute_A__FB12B6:
	ld	bc, (xiz+12)                            ; FB12B6  ld BC,(XIZ+0x0c)
	extz	bc                                    ; FB12B9  extz BC
	mul	bc, 0x12C                              ; FB12BB  mul BC,0x012c
	ld	hl, bc                                  ; FB12BF  ld HL,BC
	inc	6, bc                                  ; FB12C1  inc 6,BC
	extz	xbc                                   ; FB12C3  extz XBC
	ld	ix, (xbc+0x1523)                        ; FB12C5  ld IX,(XBC+0x1523)
	ld	bc, ix                                  ; FB12CA  ld BC,IX
	and	bc, 0x8000                             ; FB12CC  and BC,0x8000
	jrl z, VoiceParams_Compute_A__FB1566       ; FB12D0  jrl Z,0xfb1566
	extz	xhl                                   ; FB12D3  extz XHL
	ld	xbc, (xhl+0x1523)                       ; FB12D5  ld XBC,(XHL+0x1523)
	ld	e, (xbc+18)                             ; FB12DA  ld E,(XBC+0x12)
	ldb_da	c, (0xFE12AE)                       ; FB12DD  ld C,(0xfe12ae)
	and	c, e                                   ; FB12E2  and C,E
	ld	(xiz-8), c                              ; FB12E4  ld (XIZ+0xf8),C
	ldb_da	a, (0xFE12B2)                       ; FB12E7  ld A,(0xfe12b2)
	pushw	wa                                   ; FB12EC  push WA
	pushw	bc                                   ; FB12ED  push BC
	call	0xFCB23C                              ; FB12EE  call 0xfcb23c
	ld	d, a                                    ; FB12F2  ld D,A
	ld	hl, ix                                  ; FB12F4  ld HL,IX
	ldw_da	bc, (0xFDE697)                      ; FB12F6  ld BC,(0xfde697)
	and	bc, hl                                 ; FB12FB  and BC,HL
	jrl z, VoiceParams_Compute_A__FB1555       ; FB12FD  jrl Z,0xfb1555
	cps	a, 2                                   ; FB1300  cp A,2
	jr nz, VoiceParams_Compute_A__FB130C       ; FB1302  jr NZ,0xfb130c
	ld	bc, hl                                  ; FB1304  ld BC,HL
	and	bc, 0x2000                             ; FB1306  and BC,0x2000
	jr z, VoiceParams_Compute_A__FB131D        ; FB130A  jr Z,0xfb131d
VoiceParams_Compute_A__FB130C:
	cps	d, 3                                   ; FB130C  cp D,3
	jr nz, VoiceParams_Compute_A__FB1318       ; FB130E  jr NZ,0xfb1318
	ld	bc, hl                                  ; FB1310  ld BC,HL
	and	bc, 0x2000                             ; FB1312  and BC,0x2000
	jr nz, VoiceParams_Compute_A__FB131D       ; FB1316  jr NZ,0xfb131d
VoiceParams_Compute_A__FB1318:
	cps	d, 1                                   ; FB1318  cp D,1
	jrl ugt, VoiceParams_Compute_A__FB1555     ; FB131A  jrl UGT,0xfb1555
VoiceParams_Compute_A__FB131D:
	ld	c, (xiz+12)                             ; FB131D  ld C,(XIZ+0x0c)
	ld	(xiz-8), c                              ; FB1320  ld (XIZ+0xf8),C
	extz	bc                                    ; FB1323  extz BC
	mul	bc, 0x12C                              ; FB1325  mul BC,0x012c
	ld	ix, bc                                  ; FB1329  ld IX,BC
	add	bc, 0x8C                               ; FB132B  add BC,0x008c
	extz	xbc                                   ; FB132F  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB1331  ld XWA,(XBC+0x1523)
	ld	(xiz-12), xwa                           ; FB1336  ld (XIZ+0xf4),XWA
	push	xwa                                   ; FB1339  push XWA
	push	0                                     ; FB133A  push 0x00
	extpfx3 0x8E, 0x10, 0x04                   ; FB133C  push (XIZ+0x10)
	call	0xFA727D                              ; FB133F  call 0xfa727d
	ld	(xiz-14), a                             ; FB1343  ld (XIZ+0xf2),A
	ld	bc, ix                                  ; FB1346  ld BC,IX
	add	bc, 0x88                               ; FB1348  add BC,0x0088
	extz	xbc                                   ; FB134C  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB134E  ld XWA,(XBC+0x1523)
	ld	(xiz-18), xwa                           ; FB1353  ld (XIZ+0xee),XWA
	ldb	c, 4                                   ; FB1356  ld C,0x04
	extpfx3 0x8E, 0xF2, 0x43                   ; FB1358  mul BC,(XIZ+0xf2)
	add	bc, ix                                 ; FB135B  add BC,IX
	add	bc, 0x90                               ; FB135D  add BC,0x0090
	extz	xbc                                   ; FB1361  extz XBC
	ld	xiy, (xbc+0x1523)                       ; FB1363  ld XIY,(XBC+0x1523)
	ld	(xiz-22), xiy                           ; FB1368  ld (XIZ+0xea),XIY
	ld	bc, ix                                  ; FB136B  ld BC,IX
	add	bc, 41                                 ; FB136D  add BC,0x0029
	add	bc, 0x88                               ; FB1371  add BC,0x0088
	ld	(xiz-24), bc                            ; FB1375  ld (XIZ+0xe8),BC
	ldw	bc, 0x1523                             ; FB1378  ld BC,0x1523
	ld	(xiz-26), bc                            ; FB137B  ld (XIZ+0xe6),BC
	ld	de, bc                                  ; FB137E  ld DE,BC
	extpfx3 0x9E, 0xE8, 0x82                   ; FB1380  add DE,(XIZ+0xe8)
	ldw	bc, 0x5A53                             ; FB1383  ld BC,0x5a53
	ld	(xiz-28), bc                            ; FB1386  ld (XIZ+0xe4),BC
	ld	hl, bc                                  ; FB1389  ld HL,BC
	add	hl, 68                                 ; FB138B  add HL,0x0044
	ld	w, (xiz-14)                             ; FB138F  ld W,(XIZ+0xf2)
	sll	w, 6                                   ; FB1392  sll 0x06,W
	set	2, w                                   ; FB1395  set 0x02,W
	ld	a, w                                    ; FB1398  ld A,W
	extz	wa                                    ; FB139A  extz WA
	extz	xbc                                   ; FB139C  extz XBC
	ld	(xbc+69), wa                            ; FB139E  ld (XBC+0x45),WA
	ld	bc, (xiz-28)                            ; FB13A1  ld BC,(XIZ+0xe4)
	extz	xbc                                   ; FB13A4  extz XBC
	ld	(xbc+71), 1                             ; FB13A6  ld (XBC+0x47),0x01
	ld	bc, (xiz-28)                            ; FB13AA  ld BC,(XIZ+0xe4)
	extz	xbc                                   ; FB13AD  extz XBC
	ld	a, (xiz-8)                              ; FB13AF  ld A,(XIZ+0xf8)
	ld	(xbc+72), a                             ; FB13B2  ld (XBC+0x48),A
	ld	c, (xiz+14)                             ; FB13B5  ld C,(XIZ+0x0e)
	set	7, c                                   ; FB13B8  set 0x07,C
	ld	(xiz-30), c                             ; FB13BB  ld (XIZ+0xe2),C
	ld	bc, (xiz-28)                            ; FB13BE  ld BC,(XIZ+0xe4)
	extz	xbc                                   ; FB13C1  extz XBC
	ld	a, (xiz-30)                             ; FB13C3  ld A,(XIZ+0xe2)
	ld	(xbc+73), a                             ; FB13C6  ld (XBC+0x49),A
	ld	c, (xiz+16)                             ; FB13C9  ld C,(XIZ+0x10)
	res	7, c                                   ; FB13CC  res 0x07,C
	ld	(xiz-32), c                             ; FB13CF  ld (XIZ+0xe0),C
	ld	bc, (xiz-28)                            ; FB13D2  ld BC,(XIZ+0xe4)
	extz	xbc                                   ; FB13D5  extz XBC
	ld	a, (xiz-32)                             ; FB13D7  ld A,(XIZ+0xe0)
	ld	(xbc+80), a                             ; FB13DA  ld (XBC+0x50),A
	ld	bc, (xiz-26)                            ; FB13DD  ld BC,(XIZ+0xe6)
	add	bc, ix                                 ; FB13E0  add BC,IX
	ld	wa, (xiz-28)                            ; FB13E2  ld WA,(XIZ+0xe4)
	extz	xwa                                   ; FB13E5  extz XWA
	ld	(xwa+0x67), bc                          ; FB13E7  ld (XWA+0x67),BC
	extz	xix                                   ; FB13EA  extz XIX
	ld	xbc, (xix+0x1523)                       ; FB13EC  ld XBC,(XIX+0x1523)
	ld	(xiz-36), xbc                           ; FB13F1  ld (XIZ+0xdc),XBC
	ldw	ix, 87                                 ; FB13F4  ld IX,0x0057
	ld	wa, (xiz-28)                            ; FB13F7  ld WA,(XIZ+0xe4)
	extz	xwa                                   ; FB13FA  extz XWA
	add	wa, ix                                 ; FB13FC  add WA,IX
	ld	(xwa), xbc                              ; FB13FE  ld (XWA),XBC
	ld	bc, (xiz-28)                            ; FB1400  ld BC,(XIZ+0xe4)
	extz	xbc                                   ; FB1403  extz XBC
	ld	xwa, (xiz-18)                           ; FB1405  ld XWA,(XIZ+0xee)
	ld	(xbc+91), xwa                           ; FB1408  ld (XBC+0x5b),XWA
	ld	bc, (xiz-28)                            ; FB140B  ld BC,(XIZ+0xe4)
	extz	xbc                                   ; FB140E  extz XBC
	ld	(xbc+0x69), de                          ; FB1410  ld (XBC+0x69),DE
	ld	bc, (xiz-28)                            ; FB1413  ld BC,(XIZ+0xe4)
	extz	xbc                                   ; FB1416  extz XBC
	ld	xwa, (xiz-12)                           ; FB1418  ld XWA,(XIZ+0xf4)
	ld	(xbc+95), xwa                           ; FB141B  ld (XBC+0x5f),XWA
	ld	bc, (xiz-28)                            ; FB141E  ld BC,(XIZ+0xe4)
	extz	xbc                                   ; FB1421  extz XBC
	ld	xwa, (xiz-22)                           ; FB1423  ld XWA,(XIZ+0xea)
	ld	(xbc+99), xwa                           ; FB1426  ld (XBC+0x63),XWA
	pushw	hl                                   ; FB1429  push HL
	call	0xFA7F28                              ; FB142A  call 0xfa7f28
	pushw	1                                    ; FB142E  push 0x0001
	push	0                                     ; FB1431  push 0x00
	extpfx3 0x8E, 0xF8, 0x04                   ; FB1433  push (XIZ+0xf8)
	call	0xFB6272                              ; FB1436  call 0xfb6272
	extz	wa                                    ; FB143A  extz WA
	ld	bc, (xiz-28)                            ; FB143C  ld BC,(XIZ+0xe4)
	extz	xbc                                   ; FB143F  extz XBC
	ld	(xbc+0x6F), wa                          ; FB1441  ld (XBC+0x6f),WA
	push	0                                     ; FB1444  push 0x00
	extpfx3 0x8E, 0xF8, 0x04                   ; FB1446  push (XIZ+0xf8)
	call	0xFB5D05                              ; FB1449  call 0xfb5d05
	extz	wa                                    ; FB144D  extz WA
	ld	bc, (xiz-28)                            ; FB144F  ld BC,(XIZ+0xe4)
	extz	xbc                                   ; FB1452  extz XBC
	ld	(xbc+0x71), wa                          ; FB1454  ld (XBC+0x71),WA
	ld	bc, (xiz-28)                            ; FB1457  ld BC,(XIZ+0xe4)
	extz	xbc                                   ; FB145A  extz XBC
	extpfx5 0xE3, 0x07, 0xE4, 0xF0, 0x20       ; FB145C  ld XWA,(XBC+IX)
	ld	c, (xwa+0xD1)                           ; FB1461  ld C,(XWA+0x00d1)
	extz	bc                                    ; FB1466  extz BC
	extz	xbc                                   ; FB1468  extz XBC
	add	xbc, 0xFDF6C5                          ; FB146A  add XBC,0x00fdf6c5
	ld	a, (xbc)                                ; FB1470  ld A,(XBC)
	ld	bc, (xiz-28)                            ; FB1472  ld BC,(XIZ+0xe4)
	extz	xbc                                   ; FB1475  extz XBC
	ld	(xbc+0x75), a                           ; FB1477  ld (XBC+0x75),A
	ld	bc, (xiz-28)                            ; FB147A  ld BC,(XIZ+0xe4)
	extz	xbc                                   ; FB147D  extz XBC
	extpfx5 0xE3, 0x07, 0xE4, 0xF0, 0x20       ; FB147F  ld XWA,(XBC+IX)
	ld	c, (xwa+0xD2)                           ; FB1484  ld C,(XWA+0x00d2)
	mul	c, 2                                   ; FB1489  mul C,0x02
	extz	xbc                                   ; FB148C  extz XBC
	add	xbc, 0xFDF6E4                          ; FB148E  add XBC,0x00fdf6e4
	ld	bc, (xbc)                               ; FB1494  ld BC,(XBC)
	ld	wa, (xiz-28)                            ; FB1496  ld WA,(XIZ+0xe4)
	extz	xwa                                   ; FB1499  extz XWA
	ld	(xwa+0x76), bc                          ; FB149B  ld (XWA+0x76),BC
	ld	bc, (xiz-28)                            ; FB149E  ld BC,(XIZ+0xe4)
	extz	xbc                                   ; FB14A1  extz XBC
	extpfx5 0xE3, 0x07, 0xE4, 0xF0, 0x20       ; FB14A3  ld XWA,(XBC+IX)
	ld	c, (xwa+0xD3)                           ; FB14A8  ld C,(XWA+0x00d3)
	mul	c, 2                                   ; FB14AD  mul C,0x02
	extz	xbc                                   ; FB14B0  extz XBC
	add	xbc, 0xFDF722                          ; FB14B2  add XBC,0x00fdf722
	ld	bc, (xbc)                               ; FB14B8  ld BC,(XBC)
	ld	wa, (xiz-28)                            ; FB14BA  ld WA,(XIZ+0xe4)
	extz	xwa                                   ; FB14BD  extz XWA
	ld	(xwa+0x7A), bc                          ; FB14BF  ld (XWA+0x7a),BC
	ld	bc, (xiz-28)                            ; FB14C2  ld BC,(XIZ+0xe4)
	extz	xbc                                   ; FB14C5  extz XBC
	extpfx5 0xE3, 0x07, 0xE4, 0xF0, 0x20       ; FB14C7  ld XWA,(XBC+IX)
	ld	c, (xwa+0xD4)                           ; FB14CC  ld C,(XWA+0x00d4)
	mul	c, 2                                   ; FB14D1  mul C,0x02
	extz	xbc                                   ; FB14D4  extz XBC
	add	xbc, 0xFDF6E4                          ; FB14D6  add XBC,0x00fdf6e4
	ld	bc, (xbc)                               ; FB14DC  ld BC,(XBC)
	ld	wa, (xiz-28)                            ; FB14DE  ld WA,(XIZ+0xe4)
	extz	xwa                                   ; FB14E1  extz XWA
	ld	(xwa+0x78), bc                          ; FB14E3  ld (XWA+0x78),BC
	ldb_da	c, (0xFE12AA)                       ; FB14E6  ld C,(0xfe12aa)
	set	7, c                                   ; FB14EB  set 0x07,C
	ld	(xiz-38), c                             ; FB14EE  ld (XIZ+0xda),C
	ld	xbc, (xiz+8)                            ; FB14F1  ld XBC,(XIZ+0x08)
	ld	a, (xiz-38)                             ; FB14F4  ld A,(XIZ+0xda)
	ld	(xbc+3), a                              ; FB14F7  ld (XBC+0x03),A
	ld	bc, (xiz-28)                            ; FB14FA  ld BC,(XIZ+0xe4)
	extz	xbc                                   ; FB14FD  extz XBC
	ld	wa, (xbc+74)                            ; FB14FF  ld WA,(XBC+0x4a)
	pushw	wa                                   ; FB1502  push WA
	ld	wa, (xbc+76)                            ; FB1503  ld WA,(XBC+0x4c)
	pushw	wa                                   ; FB1506  push WA
	pushw	1                                    ; FB1507  push 0x0001
	push	0                                     ; FB150A  push 0x00
	extpfx3 0x8E, 0xF8, 0x04                   ; FB150C  push (XIZ+0xf8)
	call	0xFC4B2E                              ; FB150F  call 0xfc4b2e
	add	xsp, 22                                ; FB1513  add XSP,0x00000016
	cps	a, 0                                   ; FB1519  cp A,0
	jr z, VoiceParams_Compute_A__FB1526        ; FB151B  jr Z,0xfb1526
	ld	xbc, (xiz+8)                            ; FB151D  ld XBC,(XIZ+0x08)
	ld	(xbc+7), 32                             ; FB1520  ld (XBC+0x07),0x20
	jr VoiceParams_Compute_A__FB152D           ; FB1524  jr T,0xfb152d
VoiceParams_Compute_A__FB1526:
	ld	xbc, (xiz+8)                            ; FB1526  ld XBC,(XIZ+0x08)
	ld	(xbc+7), 0                              ; FB1529  ld (XBC+0x07),0x00
VoiceParams_Compute_A__FB152D:
	extz	xhl                                   ; FB152D  extz XHL
	ld	bc, (xhl+43)                            ; FB152F  ld BC,(XHL+0x2b)
	cps	bc, 0                                  ; FB1532  cp BC,0
	jr nz, VoiceParams_Compute_A__FB154C       ; FB1534  jr NZ,0xfb154c
	extz	xhl                                   ; FB1536  extz XHL
	ld	bc, (xhl+45)                            ; FB1538  ld BC,(XHL+0x2d)
	cp	bc, 0xFF                                ; FB153B  cp BC,0x00ff
	jr nz, VoiceParams_Compute_A__FB154C       ; FB153F  jr NZ,0xfb154c
	extz	xde                                   ; FB1541  extz XDE
	ld	bc, (xde+24)                            ; FB1543  ld BC,(XDE+0x18)
	and	bc, 0x8000                             ; FB1546  and BC,0x8000
	jr z, VoiceParams_Compute_A__FB1563        ; FB154A  jr Z,0xfb1563
VoiceParams_Compute_A__FB154C:
	ld	xbc, (xiz+8)                            ; FB154C  ld XBC,(XIZ+0x08)
	extpfx4 0x89, 0x07, 0x3E, 0x80             ; FB154F  or (XBC+0x07),0x80
	jr VoiceParams_Compute_A__FB1563           ; FB1553  jr T,0xfb1563
VoiceParams_Compute_A__FB1555:
	ld	xbc, (xiz+8)                            ; FB1555  ld XBC,(XIZ+0x08)
	ld	(xbc+3), 0                              ; FB1558  ld (XBC+0x03),0x00
	ld	xbc, (xiz+8)                            ; FB155C  ld XBC,(XIZ+0x08)
	ld	(xbc+7), 0                              ; FB155F  ld (XBC+0x07),0x00
VoiceParams_Compute_A__FB1563:
	jrl VoiceParams_Compute_A__FB17FD          ; FB1563  jrl T,0xfb17fd
VoiceParams_Compute_A__FB1566:
	extz	xhl                                   ; FB1566  extz XHL
	ld	xbc, (xhl+0x1523)                       ; FB1568  ld XBC,(XHL+0x1523)
	ld	e, (xbc+18)                             ; FB156D  ld E,(XBC+0x12)
	ldb_da	c, (0xFE12AE)                       ; FB1570  ld C,(0xfe12ae)
	and	c, e                                   ; FB1575  and C,E
	ld	(xiz-8), c                              ; FB1577  ld (XIZ+0xf8),C
	ldb_da	a, (0xFE12B2)                       ; FB157A  ld A,(0xfe12b2)
	pushw	wa                                   ; FB157F  push WA
	pushw	bc                                   ; FB1580  push BC
	call	0xFCB23C                              ; FB1581  call 0xfcb23c
	ld	d, a                                    ; FB1585  ld D,A
	ld	hl, ix                                  ; FB1587  ld HL,IX
	ldw_da	bc, (0xFDE697)                      ; FB1589  ld BC,(0xfde697)
	and	bc, hl                                 ; FB158E  and BC,HL
	jrl z, VoiceParams_Compute_A__FB17EF       ; FB1590  jrl Z,0xfb17ef
	cps	a, 2                                   ; FB1593  cp A,2
	jr nz, VoiceParams_Compute_A__FB159F       ; FB1595  jr NZ,0xfb159f
	ld	bc, hl                                  ; FB1597  ld BC,HL
	and	bc, 0x2000                             ; FB1599  and BC,0x2000
	jr z, VoiceParams_Compute_A__FB15B0        ; FB159D  jr Z,0xfb15b0
VoiceParams_Compute_A__FB159F:
	cps	d, 3                                   ; FB159F  cp D,3
	jr nz, VoiceParams_Compute_A__FB15AB       ; FB15A1  jr NZ,0xfb15ab
	ld	bc, hl                                  ; FB15A3  ld BC,HL
	and	bc, 0x2000                             ; FB15A5  and BC,0x2000
	jr nz, VoiceParams_Compute_A__FB15B0       ; FB15A9  jr NZ,0xfb15b0
VoiceParams_Compute_A__FB15AB:
	cps	d, 1                                   ; FB15AB  cp D,1
	jrl ugt, VoiceParams_Compute_A__FB17EF     ; FB15AD  jrl UGT,0xfb17ef
VoiceParams_Compute_A__FB15B0:
	ld	c, (xiz+12)                             ; FB15B0  ld C,(XIZ+0x0c)
	ld	(xiz-8), c                              ; FB15B3  ld (XIZ+0xf8),C
	extz	bc                                    ; FB15B6  extz BC
	mul	bc, 0x12C                              ; FB15B8  mul BC,0x012c
	ld	ix, bc                                  ; FB15BC  ld IX,BC
	add	bc, 41                                 ; FB15BE  add BC,0x0029
	ld	(xiz-10), bc                            ; FB15C2  ld (XIZ+0xf6),BC
	ld	wa, ix                                  ; FB15C5  ld WA,IX
	add	wa, 0xB5                               ; FB15C7  add WA,0x00b5
	extz	xwa                                   ; FB15CB  extz XWA
	ld	xiy, (xwa+0x1523)                       ; FB15CD  ld XIY,(XWA+0x1523)
	ld	(xiz-14), xiy                           ; FB15D2  ld (XIZ+0xf2),XIY
	push	xiy                                   ; FB15D5  push XIY
	push	0                                     ; FB15D6  push 0x00
	extpfx3 0x8E, 0x10, 0x04                   ; FB15D8  push (XIZ+0x10)
	call	0xFA727D                              ; FB15DB  call 0xfa727d
	ld	(xiz-16), a                             ; FB15DF  ld (XIZ+0xf0),A
	ld	bc, ix                                  ; FB15E2  ld BC,IX
	add	bc, 0xB1                               ; FB15E4  add BC,0x00b1
	extz	xbc                                   ; FB15E8  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB15EA  ld XWA,(XBC+0x1523)
	ld	(xiz-20), xwa                           ; FB15EF  ld (XIZ+0xec),XWA
	ldb	c, 4                                   ; FB15F2  ld C,0x04
	extpfx3 0x8E, 0xF0, 0x43                   ; FB15F4  mul BC,(XIZ+0xf0)
	extpfx3 0x9E, 0xF6, 0x81                   ; FB15F7  add BC,(XIZ+0xf6)
	add	bc, 0x90                               ; FB15FA  add BC,0x0090
	extz	xbc                                   ; FB15FE  extz XBC
	ld	xiy, (xbc+0x1523)                       ; FB1600  ld XIY,(XBC+0x1523)
	ld	(xiz-24), xiy                           ; FB1605  ld (XIZ+0xe8),XIY
	ld	bc, (xiz-10)                            ; FB1608  ld BC,(XIZ+0xf6)
	add	bc, 0x88                               ; FB160B  add BC,0x0088
	ld	(xiz-26), bc                            ; FB160F  ld (XIZ+0xe6),BC
	ldw	bc, 0x1523                             ; FB1612  ld BC,0x1523
	ld	(xiz-28), bc                            ; FB1615  ld (XIZ+0xe4),BC
	ld	de, bc                                  ; FB1618  ld DE,BC
	extpfx3 0x9E, 0xE6, 0x82                   ; FB161A  add DE,(XIZ+0xe6)
	ldw	bc, 0x5A53                             ; FB161D  ld BC,0x5a53
	ld	(xiz-30), bc                            ; FB1620  ld (XIZ+0xe2),BC
	ld	hl, bc                                  ; FB1623  ld HL,BC
	add	hl, 68                                 ; FB1625  add HL,0x0044
	ld	w, (xiz-16)                             ; FB1629  ld W,(XIZ+0xf0)
	sll	w, 6                                   ; FB162C  sll 0x06,W
	set	2, w                                   ; FB162F  set 0x02,W
	ld	a, w                                    ; FB1632  ld A,W
	extz	wa                                    ; FB1634  extz WA
	extz	xbc                                   ; FB1636  extz XBC
	ld	(xbc+69), wa                            ; FB1638  ld (XBC+0x45),WA
	ld	bc, (xiz-30)                            ; FB163B  ld BC,(XIZ+0xe2)
	extz	xbc                                   ; FB163E  extz XBC
	ld	(xbc+71), 1                             ; FB1640  ld (XBC+0x47),0x01
	ld	bc, (xiz-30)                            ; FB1644  ld BC,(XIZ+0xe2)
	extz	xbc                                   ; FB1647  extz XBC
	ld	a, (xiz-8)                              ; FB1649  ld A,(XIZ+0xf8)
	ld	(xbc+72), a                             ; FB164C  ld (XBC+0x48),A
	ld	c, (xiz+14)                             ; FB164F  ld C,(XIZ+0x0e)
	set	7, c                                   ; FB1652  set 0x07,C
	ld	(xiz-32), c                             ; FB1655  ld (XIZ+0xe0),C
	ld	bc, (xiz-30)                            ; FB1658  ld BC,(XIZ+0xe2)
	extz	xbc                                   ; FB165B  extz XBC
	ld	a, (xiz-32)                             ; FB165D  ld A,(XIZ+0xe0)
	ld	(xbc+73), a                             ; FB1660  ld (XBC+0x49),A
	ld	c, (xiz+16)                             ; FB1663  ld C,(XIZ+0x10)
	res	7, c                                   ; FB1666  res 0x07,C
	ld	(xiz-34), c                             ; FB1669  ld (XIZ+0xde),C
	ld	bc, (xiz-30)                            ; FB166C  ld BC,(XIZ+0xe2)
	extz	xbc                                   ; FB166F  extz XBC
	ld	a, (xiz-34)                             ; FB1671  ld A,(XIZ+0xde)
	ld	(xbc+80), a                             ; FB1674  ld (XBC+0x50),A
	ld	bc, (xiz-28)                            ; FB1677  ld BC,(XIZ+0xe4)
	add	bc, ix                                 ; FB167A  add BC,IX
	ld	wa, (xiz-30)                            ; FB167C  ld WA,(XIZ+0xe2)
	extz	xwa                                   ; FB167F  extz XWA
	ld	(xwa+0x67), bc                          ; FB1681  ld (XWA+0x67),BC
	extz	xix                                   ; FB1684  extz XIX
	ld	xbc, (xix+0x1523)                       ; FB1686  ld XBC,(XIX+0x1523)
	ld	(xiz-38), xbc                           ; FB168B  ld (XIZ+0xda),XBC
	ldw	ix, 87                                 ; FB168E  ld IX,0x0057
	ld	wa, (xiz-30)                            ; FB1691  ld WA,(XIZ+0xe2)
	extz	xwa                                   ; FB1694  extz XWA
	add	wa, ix                                 ; FB1696  add WA,IX
	ld	(xwa), xbc                              ; FB1698  ld (XWA),XBC
	ld	bc, (xiz-30)                            ; FB169A  ld BC,(XIZ+0xe2)
	extz	xbc                                   ; FB169D  extz XBC
	ld	xwa, (xiz-20)                           ; FB169F  ld XWA,(XIZ+0xec)
	ld	(xbc+91), xwa                           ; FB16A2  ld (XBC+0x5b),XWA
	ld	bc, (xiz-30)                            ; FB16A5  ld BC,(XIZ+0xe2)
	extz	xbc                                   ; FB16A8  extz XBC
	ld	(xbc+0x69), de                          ; FB16AA  ld (XBC+0x69),DE
	ld	bc, (xiz-30)                            ; FB16AD  ld BC,(XIZ+0xe2)
	extz	xbc                                   ; FB16B0  extz XBC
	ld	xwa, (xiz-14)                           ; FB16B2  ld XWA,(XIZ+0xf2)
	ld	(xbc+95), xwa                           ; FB16B5  ld (XBC+0x5f),XWA
	ld	bc, (xiz-30)                            ; FB16B8  ld BC,(XIZ+0xe2)
	extz	xbc                                   ; FB16BB  extz XBC
	ld	xwa, (xiz-24)                           ; FB16BD  ld XWA,(XIZ+0xe8)
	ld	(xbc+99), xwa                           ; FB16C0  ld (XBC+0x63),XWA
	pushw	hl                                   ; FB16C3  push HL
	call	0xFA7F28                              ; FB16C4  call 0xfa7f28
	pushw	1                                    ; FB16C8  push 0x0001
	push	0                                     ; FB16CB  push 0x00
	extpfx3 0x8E, 0xF8, 0x04                   ; FB16CD  push (XIZ+0xf8)
	call	0xFB6272                              ; FB16D0  call 0xfb6272
	extz	wa                                    ; FB16D4  extz WA
	ld	bc, (xiz-30)                            ; FB16D6  ld BC,(XIZ+0xe2)
	extz	xbc                                   ; FB16D9  extz XBC
	ld	(xbc+0x6F), wa                          ; FB16DB  ld (XBC+0x6f),WA
	push	0                                     ; FB16DE  push 0x00
	extpfx3 0x8E, 0xF8, 0x04                   ; FB16E0  push (XIZ+0xf8)
	call	0xFB5D05                              ; FB16E3  call 0xfb5d05
	extz	wa                                    ; FB16E7  extz WA
	ld	bc, (xiz-30)                            ; FB16E9  ld BC,(XIZ+0xe2)
	extz	xbc                                   ; FB16EC  extz XBC
	ld	(xbc+0x71), wa                          ; FB16EE  ld (XBC+0x71),WA
	ld	bc, (xiz-30)                            ; FB16F1  ld BC,(XIZ+0xe2)
	extz	xbc                                   ; FB16F4  extz XBC
	extpfx5 0xE3, 0x07, 0xE4, 0xF0, 0x20       ; FB16F6  ld XWA,(XBC+IX)
	ld	c, (xwa+0xD1)                           ; FB16FB  ld C,(XWA+0x00d1)
	extz	bc                                    ; FB1700  extz BC
	extz	xbc                                   ; FB1702  extz XBC
	add	xbc, 0xFDF6C5                          ; FB1704  add XBC,0x00fdf6c5
	ld	a, (xbc)                                ; FB170A  ld A,(XBC)
	ld	bc, (xiz-30)                            ; FB170C  ld BC,(XIZ+0xe2)
	extz	xbc                                   ; FB170F  extz XBC
	ld	(xbc+0x75), a                           ; FB1711  ld (XBC+0x75),A
	ld	bc, (xiz-30)                            ; FB1714  ld BC,(XIZ+0xe2)
	extz	xbc                                   ; FB1717  extz XBC
	extpfx5 0xE3, 0x07, 0xE4, 0xF0, 0x20       ; FB1719  ld XWA,(XBC+IX)
	ld	c, (xwa+0xD2)                           ; FB171E  ld C,(XWA+0x00d2)
	mul	c, 2                                   ; FB1723  mul C,0x02
	extz	xbc                                   ; FB1726  extz XBC
	add	xbc, 0xFDF6E4                          ; FB1728  add XBC,0x00fdf6e4
	ld	bc, (xbc)                               ; FB172E  ld BC,(XBC)
	ld	wa, (xiz-30)                            ; FB1730  ld WA,(XIZ+0xe2)
	extz	xwa                                   ; FB1733  extz XWA
	ld	(xwa+0x76), bc                          ; FB1735  ld (XWA+0x76),BC
	ld	bc, (xiz-30)                            ; FB1738  ld BC,(XIZ+0xe2)
	extz	xbc                                   ; FB173B  extz XBC
	extpfx5 0xE3, 0x07, 0xE4, 0xF0, 0x20       ; FB173D  ld XWA,(XBC+IX)
	ld	c, (xwa+0xD3)                           ; FB1742  ld C,(XWA+0x00d3)
	mul	c, 2                                   ; FB1747  mul C,0x02
	extz	xbc                                   ; FB174A  extz XBC
	add	xbc, 0xFDF722                          ; FB174C  add XBC,0x00fdf722
	ld	bc, (xbc)                               ; FB1752  ld BC,(XBC)
	ld	wa, (xiz-30)                            ; FB1754  ld WA,(XIZ+0xe2)
	extz	xwa                                   ; FB1757  extz XWA
	ld	(xwa+0x7A), bc                          ; FB1759  ld (XWA+0x7a),BC
	ld	bc, (xiz-30)                            ; FB175C  ld BC,(XIZ+0xe2)
	extz	xbc                                   ; FB175F  extz XBC
	extpfx5 0xE3, 0x07, 0xE4, 0xF0, 0x20       ; FB1761  ld XWA,(XBC+IX)
	ld	c, (xwa+0xD4)                           ; FB1766  ld C,(XWA+0x00d4)
	mul	c, 2                                   ; FB176B  mul C,0x02
	extz	xbc                                   ; FB176E  extz XBC
	add	xbc, 0xFDF6E4                          ; FB1770  add XBC,0x00fdf6e4
	ld	bc, (xbc)                               ; FB1776  ld BC,(XBC)
	ld	wa, (xiz-30)                            ; FB1778  ld WA,(XIZ+0xe2)
	extz	xwa                                   ; FB177B  extz XWA
	ld	(xwa+0x78), bc                          ; FB177D  ld (XWA+0x78),BC
	ldb_da	c, (0xFE12AA)                       ; FB1780  ld C,(0xfe12aa)
	set	7, c                                   ; FB1785  set 0x07,C
	ld	(xiz-40), c                             ; FB1788  ld (XIZ+0xd8),C
	ld	xbc, (xiz+8)                            ; FB178B  ld XBC,(XIZ+0x08)
	ld	a, (xiz-40)                             ; FB178E  ld A,(XIZ+0xd8)
	ld	(xbc+3), a                              ; FB1791  ld (XBC+0x03),A
	ld	bc, (xiz-30)                            ; FB1794  ld BC,(XIZ+0xe2)
	extz	xbc                                   ; FB1797  extz XBC
	ld	wa, (xbc+74)                            ; FB1799  ld WA,(XBC+0x4a)
	pushw	wa                                   ; FB179C  push WA
	ld	wa, (xbc+76)                            ; FB179D  ld WA,(XBC+0x4c)
	pushw	wa                                   ; FB17A0  push WA
	pushw	1                                    ; FB17A1  push 0x0001
	push	0                                     ; FB17A4  push 0x00
	extpfx3 0x8E, 0xF8, 0x04                   ; FB17A6  push (XIZ+0xf8)
	call	0xFC4B2E                              ; FB17A9  call 0xfc4b2e
	add	xsp, 22                                ; FB17AD  add XSP,0x00000016
	cps	a, 0                                   ; FB17B3  cp A,0
	jr z, VoiceParams_Compute_A__FB17C0        ; FB17B5  jr Z,0xfb17c0
	ld	xbc, (xiz+8)                            ; FB17B7  ld XBC,(XIZ+0x08)
	ld	(xbc+7), 32                             ; FB17BA  ld (XBC+0x07),0x20
	jr VoiceParams_Compute_A__FB17C7           ; FB17BE  jr T,0xfb17c7
VoiceParams_Compute_A__FB17C0:
	ld	xbc, (xiz+8)                            ; FB17C0  ld XBC,(XIZ+0x08)
	ld	(xbc+7), 0                              ; FB17C3  ld (XBC+0x07),0x00
VoiceParams_Compute_A__FB17C7:
	extz	xhl                                   ; FB17C7  extz XHL
	ld	bc, (xhl+43)                            ; FB17C9  ld BC,(XHL+0x2b)
	cps	bc, 0                                  ; FB17CC  cp BC,0
	jr nz, VoiceParams_Compute_A__FB17E6       ; FB17CE  jr NZ,0xfb17e6
	extz	xhl                                   ; FB17D0  extz XHL
	ld	bc, (xhl+45)                            ; FB17D2  ld BC,(XHL+0x2d)
	cp	bc, 0xFF                                ; FB17D5  cp BC,0x00ff
	jr nz, VoiceParams_Compute_A__FB17E6       ; FB17D9  jr NZ,0xfb17e6
	extz	xde                                   ; FB17DB  extz XDE
	ld	bc, (xde+24)                            ; FB17DD  ld BC,(XDE+0x18)
	and	bc, 0x8000                             ; FB17E0  and BC,0x8000
	jr z, VoiceParams_Compute_A__FB17FD        ; FB17E4  jr Z,0xfb17fd
VoiceParams_Compute_A__FB17E6:
	ld	xbc, (xiz+8)                            ; FB17E6  ld XBC,(XIZ+0x08)
	extpfx4 0x89, 0x07, 0x3E, 0x80             ; FB17E9  or (XBC+0x07),0x80
	jr VoiceParams_Compute_A__FB17FD           ; FB17ED  jr T,0xfb17fd
VoiceParams_Compute_A__FB17EF:
	ld	xbc, (xiz+8)                            ; FB17EF  ld XBC,(XIZ+0x08)
	ld	(xbc+3), 0                              ; FB17F2  ld (XBC+0x03),0x00
	ld	xbc, (xiz+8)                            ; FB17F6  ld XBC,(XIZ+0x08)
	ld	(xbc+7), 0                              ; FB17F9  ld (XBC+0x07),0x00
VoiceParams_Compute_A__FB17FD:
	ld	bc, (xiz+12)                            ; FB17FD  ld BC,(XIZ+0x0c)
	extz	bc                                    ; FB1800  extz BC
	mul	bc, 0x12C                              ; FB1802  mul BC,0x012c
	ld	ix, bc                                  ; FB1806  ld IX,BC
	extz	xbc                                   ; FB1808  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB180A  ld XWA,(XBC+0x1523)
	ld	e, (xwa+18)                             ; FB180F  ld E,(XWA+0x12)
	ldb_da	a, (0xFE12AF)                       ; FB1812  ld A,(0xfe12af)
	and	a, e                                   ; FB1817  and A,E
	ld	(xiz-8), a                              ; FB1819  ld (XIZ+0xf8),A
	ldb_da	w, (0xFE12B3)                       ; FB181C  ld W,(0xfe12b3)
	push	0                                     ; FB1821  push 0x00
	push	w                                     ; FB1823  push W
	pushw	wa                                   ; FB1825  push WA
	call	0xFCB23C                              ; FB1826  call 0xfcb23c
	ld	d, a                                    ; FB182A  ld D,A
	ld	bc, ix                                  ; FB182C  ld BC,IX
	inc	6, bc                                  ; FB182E  inc 6,BC
	extz	xbc                                   ; FB1830  extz XBC
	ld	hl, (xbc+0x1523)                        ; FB1832  ld HL,(XBC+0x1523)
	ldw_da	bc, (0xFDE699)                      ; FB1837  ld BC,(0xfde699)
	and	bc, hl                                 ; FB183C  and BC,HL
	jrl z, VoiceParams_Compute_A__FB1AC1       ; FB183E  jrl Z,0xfb1ac1
	cps	a, 2                                   ; FB1841  cp A,2
	jr nz, VoiceParams_Compute_A__FB184D       ; FB1843  jr NZ,0xfb184d
	ld	bc, hl                                  ; FB1845  ld BC,HL
	and	bc, 0x2000                             ; FB1847  and BC,0x2000
	jr z, VoiceParams_Compute_A__FB185E        ; FB184B  jr Z,0xfb185e
VoiceParams_Compute_A__FB184D:
	cps	d, 3                                   ; FB184D  cp D,3
	jr nz, VoiceParams_Compute_A__FB1859       ; FB184F  jr NZ,0xfb1859
	ld	bc, hl                                  ; FB1851  ld BC,HL
	and	bc, 0x2000                             ; FB1853  and BC,0x2000
	jr nz, VoiceParams_Compute_A__FB185E       ; FB1857  jr NZ,0xfb185e
VoiceParams_Compute_A__FB1859:
	cps	d, 1                                   ; FB1859  cp D,1
	jrl ugt, VoiceParams_Compute_A__FB1AC1     ; FB185B  jrl UGT,0xfb1ac1
VoiceParams_Compute_A__FB185E:
	ld	c, (xiz+12)                             ; FB185E  ld C,(XIZ+0x0c)
	ld	(xiz-8), c                              ; FB1861  ld (XIZ+0xf8),C
	extz	bc                                    ; FB1864  extz BC
	mul	bc, 0x12C                              ; FB1866  mul BC,0x012c
	ld	ix, bc                                  ; FB186A  ld IX,BC
	add	bc, 82                                 ; FB186C  add BC,0x0052
	ld	(xiz-10), bc                            ; FB1870  ld (XIZ+0xf6),BC
	ld	wa, ix                                  ; FB1873  ld WA,IX
	add	wa, 0xDE                               ; FB1875  add WA,0x00de
	extz	xwa                                   ; FB1879  extz XWA
	ld	xiy, (xwa+0x1523)                       ; FB187B  ld XIY,(XWA+0x1523)
	ld	(xiz-14), xiy                           ; FB1880  ld (XIZ+0xf2),XIY
	push	xiy                                   ; FB1883  push XIY
	push	0                                     ; FB1884  push 0x00
	extpfx3 0x8E, 0x10, 0x04                   ; FB1886  push (XIZ+0x10)
	call	0xFA727D                              ; FB1889  call 0xfa727d
	ld	(xiz-16), a                             ; FB188D  ld (XIZ+0xf0),A
	ld	bc, ix                                  ; FB1890  ld BC,IX
	add	bc, 0xDA                               ; FB1892  add BC,0x00da
	extz	xbc                                   ; FB1896  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB1898  ld XWA,(XBC+0x1523)
	ld	(xiz-20), xwa                           ; FB189D  ld (XIZ+0xec),XWA
	ldb	c, 4                                   ; FB18A0  ld C,0x04
	extpfx3 0x8E, 0xF0, 0x43                   ; FB18A2  mul BC,(XIZ+0xf0)
	extpfx3 0x9E, 0xF6, 0x81                   ; FB18A5  add BC,(XIZ+0xf6)
	add	bc, 0x90                               ; FB18A8  add BC,0x0090
	extz	xbc                                   ; FB18AC  extz XBC
	ld	xiy, (xbc+0x1523)                       ; FB18AE  ld XIY,(XBC+0x1523)
	ld	(xiz-24), xiy                           ; FB18B3  ld (XIZ+0xe8),XIY
	ld	bc, (xiz-10)                            ; FB18B6  ld BC,(XIZ+0xf6)
	add	bc, 0x88                               ; FB18B9  add BC,0x0088
	ld	(xiz-26), bc                            ; FB18BD  ld (XIZ+0xe6),BC
	ldw	bc, 0x1523                             ; FB18C0  ld BC,0x1523
	ld	(xiz-28), bc                            ; FB18C3  ld (XIZ+0xe4),BC
	ld	de, bc                                  ; FB18C6  ld DE,BC
	extpfx3 0x9E, 0xE6, 0x82                   ; FB18C8  add DE,(XIZ+0xe6)
	ldw	bc, 0x5A53                             ; FB18CB  ld BC,0x5a53
	ld	(xiz-30), bc                            ; FB18CE  ld (XIZ+0xe2),BC
	ld	hl, bc                                  ; FB18D1  ld HL,BC
	add	hl, 0x88                               ; FB18D3  add HL,0x0088
	ld	w, (xiz-16)                             ; FB18D7  ld W,(XIZ+0xf0)
	sll	w, 6                                   ; FB18DA  sll 0x06,W
	set	2, w                                   ; FB18DD  set 0x02,W
	ld	a, w                                    ; FB18E0  ld A,W
	extz	wa                                    ; FB18E2  extz WA
	extz	xbc                                   ; FB18E4  extz XBC
	ld	(xbc+0x89), wa                          ; FB18E6  ld (XBC+0x0089),WA
	ld	bc, (xiz-30)                            ; FB18EB  ld BC,(XIZ+0xe2)
	extz	xbc                                   ; FB18EE  extz XBC
	ld	(xbc+0x8B), 2                           ; FB18F0  ld (XBC+0x008b),0x02
	ld	bc, (xiz-30)                            ; FB18F6  ld BC,(XIZ+0xe2)
	extz	xbc                                   ; FB18F9  extz XBC
	ld	a, (xiz-8)                              ; FB18FB  ld A,(XIZ+0xf8)
	ld	(xbc+0x8C), a                           ; FB18FE  ld (XBC+0x008c),A
	ld	c, (xiz+14)                             ; FB1903  ld C,(XIZ+0x0e)
	set	7, c                                   ; FB1906  set 0x07,C
	ld	(xiz-32), c                             ; FB1909  ld (XIZ+0xe0),C
	ld	bc, (xiz-30)                            ; FB190C  ld BC,(XIZ+0xe2)
	extz	xbc                                   ; FB190F  extz XBC
	ld	a, (xiz-32)                             ; FB1911  ld A,(XIZ+0xe0)
	ld	(xbc+0x8D), a                           ; FB1914  ld (XBC+0x008d),A
	ld	c, (xiz+16)                             ; FB1919  ld C,(XIZ+0x10)
	res	7, c                                   ; FB191C  res 0x07,C
	ld	(xiz-34), c                             ; FB191F  ld (XIZ+0xde),C
	ld	bc, (xiz-30)                            ; FB1922  ld BC,(XIZ+0xe2)
	extz	xbc                                   ; FB1925  extz XBC
	ld	a, (xiz-34)                             ; FB1927  ld A,(XIZ+0xde)
	ld	(xbc+0x94), a                           ; FB192A  ld (XBC+0x0094),A
	ld	bc, (xiz-28)                            ; FB192F  ld BC,(XIZ+0xe4)
	add	bc, ix                                 ; FB1932  add BC,IX
	ld	wa, (xiz-30)                            ; FB1934  ld WA,(XIZ+0xe2)
	extz	xwa                                   ; FB1937  extz XWA
	ld	(xwa+0xAB), bc                          ; FB1939  ld (XWA+0x00ab),BC
	extz	xix                                   ; FB193E  extz XIX
	ld	xbc, (xix+0x1523)                       ; FB1940  ld XBC,(XIX+0x1523)
	ld	(xiz-38), xbc                           ; FB1945  ld (XIZ+0xda),XBC
	ldw	ix, 0x9B                               ; FB1948  ld IX,0x009b
	ld	wa, (xiz-30)                            ; FB194B  ld WA,(XIZ+0xe2)
	extz	xwa                                   ; FB194E  extz XWA
	add	wa, ix                                 ; FB1950  add WA,IX
	ld	(xwa), xbc                              ; FB1952  ld (XWA),XBC
	ld	bc, (xiz-30)                            ; FB1954  ld BC,(XIZ+0xe2)
	extz	xbc                                   ; FB1957  extz XBC
	ld	xwa, (xiz-20)                           ; FB1959  ld XWA,(XIZ+0xec)
	ld	(xbc+0x9F), xwa                         ; FB195C  ld (XBC+0x009f),XWA
	ld	bc, (xiz-30)                            ; FB1961  ld BC,(XIZ+0xe2)
	extz	xbc                                   ; FB1964  extz XBC
	ld	(xbc+0xAD), de                          ; FB1966  ld (XBC+0x00ad),DE
	ld	bc, (xiz-30)                            ; FB196B  ld BC,(XIZ+0xe2)
	extz	xbc                                   ; FB196E  extz XBC
	ld	xwa, (xiz-14)                           ; FB1970  ld XWA,(XIZ+0xf2)
	ld	(xbc+0xA3), xwa                         ; FB1973  ld (XBC+0x00a3),XWA
	ld	bc, (xiz-30)                            ; FB1978  ld BC,(XIZ+0xe2)
	extz	xbc                                   ; FB197B  extz XBC
	ld	xwa, (xiz-24)                           ; FB197D  ld XWA,(XIZ+0xe8)
	ld	(xbc+0xA7), xwa                         ; FB1980  ld (XBC+0x00a7),XWA
	pushw	hl                                   ; FB1985  push HL
	call	0xFA7F28                              ; FB1986  call 0xfa7f28
	pushw	2                                    ; FB198A  push 0x0002
	push	0                                     ; FB198D  push 0x00
	extpfx3 0x8E, 0xF8, 0x04                   ; FB198F  push (XIZ+0xf8)
	call	0xFB6272                              ; FB1992  call 0xfb6272
	extz	wa                                    ; FB1996  extz WA
	ld	bc, (xiz-30)                            ; FB1998  ld BC,(XIZ+0xe2)
	extz	xbc                                   ; FB199B  extz XBC
	ld	(xbc+0xB3), wa                          ; FB199D  ld (XBC+0x00b3),WA
	push	0                                     ; FB19A2  push 0x00
	extpfx3 0x8E, 0xF8, 0x04                   ; FB19A4  push (XIZ+0xf8)
	call	0xFB5D05                              ; FB19A7  call 0xfb5d05
	extz	wa                                    ; FB19AB  extz WA
	ld	bc, (xiz-30)                            ; FB19AD  ld BC,(XIZ+0xe2)
	extz	xbc                                   ; FB19B0  extz XBC
	ld	(xbc+0xB5), wa                          ; FB19B2  ld (XBC+0x00b5),WA
	ld	bc, (xiz-30)                            ; FB19B7  ld BC,(XIZ+0xe2)
	extz	xbc                                   ; FB19BA  extz XBC
	extpfx5 0xE3, 0x07, 0xE4, 0xF0, 0x20       ; FB19BC  ld XWA,(XBC+IX)
	ld	c, (xwa+0xD1)                           ; FB19C1  ld C,(XWA+0x00d1)
	extz	bc                                    ; FB19C6  extz BC
	extz	xbc                                   ; FB19C8  extz XBC
	add	xbc, 0xFDF6C5                          ; FB19CA  add XBC,0x00fdf6c5
	ld	a, (xbc)                                ; FB19D0  ld A,(XBC)
	ld	bc, (xiz-30)                            ; FB19D2  ld BC,(XIZ+0xe2)
	extz	xbc                                   ; FB19D5  extz XBC
	ld	(xbc+0xB9), a                           ; FB19D7  ld (XBC+0x00b9),A
	ld	bc, (xiz-30)                            ; FB19DC  ld BC,(XIZ+0xe2)
	extz	xbc                                   ; FB19DF  extz XBC
	extpfx5 0xE3, 0x07, 0xE4, 0xF0, 0x20       ; FB19E1  ld XWA,(XBC+IX)
	ld	c, (xwa+0xD2)                           ; FB19E6  ld C,(XWA+0x00d2)
	mul	c, 2                                   ; FB19EB  mul C,0x02
	extz	xbc                                   ; FB19EE  extz XBC
	add	xbc, 0xFDF6E4                          ; FB19F0  add XBC,0x00fdf6e4
	ld	bc, (xbc)                               ; FB19F6  ld BC,(XBC)
	ld	wa, (xiz-30)                            ; FB19F8  ld WA,(XIZ+0xe2)
	extz	xwa                                   ; FB19FB  extz XWA
	ld	(xwa+0xBA), bc                          ; FB19FD  ld (XWA+0x00ba),BC
	ld	bc, (xiz-30)                            ; FB1A02  ld BC,(XIZ+0xe2)
	extz	xbc                                   ; FB1A05  extz XBC
	extpfx5 0xE3, 0x07, 0xE4, 0xF0, 0x20       ; FB1A07  ld XWA,(XBC+IX)
	ld	c, (xwa+0xD3)                           ; FB1A0C  ld C,(XWA+0x00d3)
	mul	c, 2                                   ; FB1A11  mul C,0x02
	extz	xbc                                   ; FB1A14  extz XBC
	add	xbc, 0xFDF722                          ; FB1A16  add XBC,0x00fdf722
	ld	bc, (xbc)                               ; FB1A1C  ld BC,(XBC)
	ld	wa, (xiz-30)                            ; FB1A1E  ld WA,(XIZ+0xe2)
	extz	xwa                                   ; FB1A21  extz XWA
	ld	(xwa+0xBE), bc                          ; FB1A23  ld (XWA+0x00be),BC
	ld	bc, (xiz-30)                            ; FB1A28  ld BC,(XIZ+0xe2)
	extz	xbc                                   ; FB1A2B  extz XBC
	extpfx5 0xE3, 0x07, 0xE4, 0xF0, 0x20       ; FB1A2D  ld XWA,(XBC+IX)
	ld	c, (xwa+0xD4)                           ; FB1A32  ld C,(XWA+0x00d4)
	mul	c, 2                                   ; FB1A37  mul C,0x02
	extz	xbc                                   ; FB1A3A  extz XBC
	add	xbc, 0xFDF6E4                          ; FB1A3C  add XBC,0x00fdf6e4
	ld	bc, (xbc)                               ; FB1A42  ld BC,(XBC)
	ld	wa, (xiz-30)                            ; FB1A44  ld WA,(XIZ+0xe2)
	extz	xwa                                   ; FB1A47  extz XWA
	ld	(xwa+0xBC), bc                          ; FB1A49  ld (XWA+0x00bc),BC
	ldb_da	c, (0xFE12AB)                       ; FB1A4E  ld C,(0xfe12ab)
	set	7, c                                   ; FB1A53  set 0x07,C
	ld	(xiz-40), c                             ; FB1A56  ld (XIZ+0xd8),C
	ld	xbc, (xiz+8)                            ; FB1A59  ld XBC,(XIZ+0x08)
	ld	a, (xiz-40)                             ; FB1A5C  ld A,(XIZ+0xd8)
	ld	(xbc+4), a                              ; FB1A5F  ld (XBC+0x04),A
	ld	bc, (xiz-30)                            ; FB1A62  ld BC,(XIZ+0xe2)
	extz	xbc                                   ; FB1A65  extz XBC
	ld	wa, (xbc+0x8E)                          ; FB1A67  ld WA,(XBC+0x008e)
	pushw	wa                                   ; FB1A6C  push WA
	ld	wa, (xbc+0x90)                          ; FB1A6D  ld WA,(XBC+0x0090)
	pushw	wa                                   ; FB1A72  push WA
	pushw	2                                    ; FB1A73  push 0x0002
	push	0                                     ; FB1A76  push 0x00
	extpfx3 0x8E, 0xF8, 0x04                   ; FB1A78  push (XIZ+0xf8)
	call	0xFC4B2E                              ; FB1A7B  call 0xfc4b2e
	add	xsp, 22                                ; FB1A7F  add XSP,0x00000016
	cps	a, 0                                   ; FB1A85  cp A,0
	jr z, VoiceParams_Compute_A__FB1A92        ; FB1A87  jr Z,0xfb1a92
	ld	xbc, (xiz+8)                            ; FB1A89  ld XBC,(XIZ+0x08)
	ld	(xbc+8), 32                             ; FB1A8C  ld (XBC+0x08),0x20
	jr VoiceParams_Compute_A__FB1A99           ; FB1A90  jr T,0xfb1a99
VoiceParams_Compute_A__FB1A92:
	ld	xbc, (xiz+8)                            ; FB1A92  ld XBC,(XIZ+0x08)
	ld	(xbc+8), 0                              ; FB1A95  ld (XBC+0x08),0x00
VoiceParams_Compute_A__FB1A99:
	extz	xhl                                   ; FB1A99  extz XHL
	ld	bc, (xhl+43)                            ; FB1A9B  ld BC,(XHL+0x2b)
	cps	bc, 0                                  ; FB1A9E  cp BC,0
	jr nz, VoiceParams_Compute_A__FB1AB8       ; FB1AA0  jr NZ,0xfb1ab8
	extz	xhl                                   ; FB1AA2  extz XHL
	ld	bc, (xhl+45)                            ; FB1AA4  ld BC,(XHL+0x2d)
	cp	bc, 0xFF                                ; FB1AA7  cp BC,0x00ff
	jr nz, VoiceParams_Compute_A__FB1AB8       ; FB1AAB  jr NZ,0xfb1ab8
	extz	xde                                   ; FB1AAD  extz XDE
	ld	bc, (xde+24)                            ; FB1AAF  ld BC,(XDE+0x18)
	and	bc, 0x8000                             ; FB1AB2  and BC,0x8000
	jr z, VoiceParams_Compute_A__FB1ACF        ; FB1AB6  jr Z,0xfb1acf
VoiceParams_Compute_A__FB1AB8:
	ld	xbc, (xiz+8)                            ; FB1AB8  ld XBC,(XIZ+0x08)
	extpfx4 0x89, 0x08, 0x3E, 0x80             ; FB1ABB  or (XBC+0x08),0x80
	jr VoiceParams_Compute_A__FB1ACF           ; FB1ABF  jr T,0xfb1acf
VoiceParams_Compute_A__FB1AC1:
	ld	xbc, (xiz+8)                            ; FB1AC1  ld XBC,(XIZ+0x08)
	ld	(xbc+4), 0                              ; FB1AC4  ld (XBC+0x04),0x00
	ld	xbc, (xiz+8)                            ; FB1AC8  ld XBC,(XIZ+0x08)
	ld	(xbc+8), 0                              ; FB1ACB  ld (XBC+0x08),0x00
VoiceParams_Compute_A__FB1ACF:
	ld	bc, (xiz+12)                            ; FB1ACF  ld BC,(XIZ+0x0c)
	extz	bc                                    ; FB1AD2  extz BC
	mul	bc, 0x12C                              ; FB1AD4  mul BC,0x012c
	ld	ix, bc                                  ; FB1AD8  ld IX,BC
	extz	xbc                                   ; FB1ADA  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB1ADC  ld XWA,(XBC+0x1523)
	ld	e, (xwa+18)                             ; FB1AE1  ld E,(XWA+0x12)
	ldb_da	a, (0xFE12B0)                       ; FB1AE4  ld A,(0xfe12b0)
	and	a, e                                   ; FB1AE9  and A,E
	ld	(xiz-8), a                              ; FB1AEB  ld (XIZ+0xf8),A
	ldb_da	w, (0xFE12B4)                       ; FB1AEE  ld W,(0xfe12b4)
	push	0                                     ; FB1AF3  push 0x00
	push	w                                     ; FB1AF5  push W
	pushw	wa                                   ; FB1AF7  push WA
	call	0xFCB23C                              ; FB1AF8  call 0xfcb23c
	ld	d, a                                    ; FB1AFC  ld D,A
	ld	bc, ix                                  ; FB1AFE  ld BC,IX
	inc	6, bc                                  ; FB1B00  inc 6,BC
	extz	xbc                                   ; FB1B02  extz XBC
	ld	hl, (xbc+0x1523)                        ; FB1B04  ld HL,(XBC+0x1523)
	ldw_da	bc, (0xFDE69B)                      ; FB1B09  ld BC,(0xfde69b)
	and	bc, hl                                 ; FB1B0E  and BC,HL
	jrl z, VoiceParams_Compute_A__FB1D93       ; FB1B10  jrl Z,0xfb1d93
	cps	a, 2                                   ; FB1B13  cp A,2
	jr nz, VoiceParams_Compute_A__FB1B1F       ; FB1B15  jr NZ,0xfb1b1f
	ld	bc, hl                                  ; FB1B17  ld BC,HL
	and	bc, 0x2000                             ; FB1B19  and BC,0x2000
	jr z, VoiceParams_Compute_A__FB1B30        ; FB1B1D  jr Z,0xfb1b30
VoiceParams_Compute_A__FB1B1F:
	cps	d, 3                                   ; FB1B1F  cp D,3
	jr nz, VoiceParams_Compute_A__FB1B2B       ; FB1B21  jr NZ,0xfb1b2b
	ld	bc, hl                                  ; FB1B23  ld BC,HL
	and	bc, 0x2000                             ; FB1B25  and BC,0x2000
	jr nz, VoiceParams_Compute_A__FB1B30       ; FB1B29  jr NZ,0xfb1b30
VoiceParams_Compute_A__FB1B2B:
	cps	d, 1                                   ; FB1B2B  cp D,1
	jrl ugt, VoiceParams_Compute_A__FB1D93     ; FB1B2D  jrl UGT,0xfb1d93
VoiceParams_Compute_A__FB1B30:
	ld	c, (xiz+12)                             ; FB1B30  ld C,(XIZ+0x0c)
	ld	(xiz-8), c                              ; FB1B33  ld (XIZ+0xf8),C
	extz	bc                                    ; FB1B36  extz BC
	mul	bc, 0x12C                              ; FB1B38  mul BC,0x012c
	ld	ix, bc                                  ; FB1B3C  ld IX,BC
	add	bc, 0x7B                               ; FB1B3E  add BC,0x007b
	ld	(xiz-10), bc                            ; FB1B42  ld (XIZ+0xf6),BC
	ld	wa, ix                                  ; FB1B45  ld WA,IX
	add	wa, 0x107                              ; FB1B47  add WA,0x0107
	extz	xwa                                   ; FB1B4B  extz XWA
	ld	xiy, (xwa+0x1523)                       ; FB1B4D  ld XIY,(XWA+0x1523)
	ld	(xiz-14), xiy                           ; FB1B52  ld (XIZ+0xf2),XIY
	push	xiy                                   ; FB1B55  push XIY
	push	0                                     ; FB1B56  push 0x00
	extpfx3 0x8E, 0x10, 0x04                   ; FB1B58  push (XIZ+0x10)
	call	0xFA727D                              ; FB1B5B  call 0xfa727d
	ld	(xiz-16), a                             ; FB1B5F  ld (XIZ+0xf0),A
	ld	bc, ix                                  ; FB1B62  ld BC,IX
	add	bc, 0x103                              ; FB1B64  add BC,0x0103
	extz	xbc                                   ; FB1B68  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB1B6A  ld XWA,(XBC+0x1523)
	ld	(xiz-20), xwa                           ; FB1B6F  ld (XIZ+0xec),XWA
	ldb	c, 4                                   ; FB1B72  ld C,0x04
	extpfx3 0x8E, 0xF0, 0x43                   ; FB1B74  mul BC,(XIZ+0xf0)
	extpfx3 0x9E, 0xF6, 0x81                   ; FB1B77  add BC,(XIZ+0xf6)
	add	bc, 0x90                               ; FB1B7A  add BC,0x0090
	extz	xbc                                   ; FB1B7E  extz XBC
	ld	xiy, (xbc+0x1523)                       ; FB1B80  ld XIY,(XBC+0x1523)
	ld	(xiz-24), xiy                           ; FB1B85  ld (XIZ+0xe8),XIY
	ld	bc, (xiz-10)                            ; FB1B88  ld BC,(XIZ+0xf6)
	add	bc, 0x88                               ; FB1B8B  add BC,0x0088
	ld	(xiz-26), bc                            ; FB1B8F  ld (XIZ+0xe6),BC
	ldw	bc, 0x1523                             ; FB1B92  ld BC,0x1523
	ld	(xiz-28), bc                            ; FB1B95  ld (XIZ+0xe4),BC
	ld	de, bc                                  ; FB1B98  ld DE,BC
	extpfx3 0x9E, 0xE6, 0x82                   ; FB1B9A  add DE,(XIZ+0xe6)
	ldw	bc, 0x5A53                             ; FB1B9D  ld BC,0x5a53
	ld	(xiz-30), bc                            ; FB1BA0  ld (XIZ+0xe2),BC
	ld	hl, bc                                  ; FB1BA3  ld HL,BC
	add	hl, 0xCC                               ; FB1BA5  add HL,0x00cc
	ld	w, (xiz-16)                             ; FB1BA9  ld W,(XIZ+0xf0)
	sll	w, 6                                   ; FB1BAC  sll 0x06,W
	set	2, w                                   ; FB1BAF  set 0x02,W
	ld	a, w                                    ; FB1BB2  ld A,W
	extz	wa                                    ; FB1BB4  extz WA
	extz	xbc                                   ; FB1BB6  extz XBC
	ld	(xbc+0xCD), wa                          ; FB1BB8  ld (XBC+0x00cd),WA
	ld	bc, (xiz-30)                            ; FB1BBD  ld BC,(XIZ+0xe2)
	extz	xbc                                   ; FB1BC0  extz XBC
	ld	(xbc+0xCF), 3                           ; FB1BC2  ld (XBC+0x00cf),0x03
	ld	bc, (xiz-30)                            ; FB1BC8  ld BC,(XIZ+0xe2)
	extz	xbc                                   ; FB1BCB  extz XBC
	ld	a, (xiz-8)                              ; FB1BCD  ld A,(XIZ+0xf8)
	ld	(xbc+0xD0), a                           ; FB1BD0  ld (XBC+0x00d0),A
	ld	c, (xiz+14)                             ; FB1BD5  ld C,(XIZ+0x0e)
	set	7, c                                   ; FB1BD8  set 0x07,C
	ld	(xiz-32), c                             ; FB1BDB  ld (XIZ+0xe0),C
	ld	bc, (xiz-30)                            ; FB1BDE  ld BC,(XIZ+0xe2)
	extz	xbc                                   ; FB1BE1  extz XBC
	ld	a, (xiz-32)                             ; FB1BE3  ld A,(XIZ+0xe0)
	ld	(xbc+0xD1), a                           ; FB1BE6  ld (XBC+0x00d1),A
	ld	c, (xiz+16)                             ; FB1BEB  ld C,(XIZ+0x10)
	res	7, c                                   ; FB1BEE  res 0x07,C
	ld	(xiz-34), c                             ; FB1BF1  ld (XIZ+0xde),C
	ld	bc, (xiz-30)                            ; FB1BF4  ld BC,(XIZ+0xe2)
	extz	xbc                                   ; FB1BF7  extz XBC
	ld	a, (xiz-34)                             ; FB1BF9  ld A,(XIZ+0xde)
	ld	(xbc+0xD8), a                           ; FB1BFC  ld (XBC+0x00d8),A
	ld	bc, (xiz-28)                            ; FB1C01  ld BC,(XIZ+0xe4)
	add	bc, ix                                 ; FB1C04  add BC,IX
	ld	wa, (xiz-30)                            ; FB1C06  ld WA,(XIZ+0xe2)
	extz	xwa                                   ; FB1C09  extz XWA
	ld	(xwa+0xEF), bc                          ; FB1C0B  ld (XWA+0x00ef),BC
	extz	xix                                   ; FB1C10  extz XIX
	ld	xbc, (xix+0x1523)                       ; FB1C12  ld XBC,(XIX+0x1523)
	ld	(xiz-38), xbc                           ; FB1C17  ld (XIZ+0xda),XBC
	ldw	ix, 0xDF                               ; FB1C1A  ld IX,0x00df
	ld	wa, (xiz-30)                            ; FB1C1D  ld WA,(XIZ+0xe2)
	extz	xwa                                   ; FB1C20  extz XWA
	add	wa, ix                                 ; FB1C22  add WA,IX
	ld	(xwa), xbc                              ; FB1C24  ld (XWA),XBC
	ld	bc, (xiz-30)                            ; FB1C26  ld BC,(XIZ+0xe2)
	extz	xbc                                   ; FB1C29  extz XBC
	ld	xwa, (xiz-20)                           ; FB1C2B  ld XWA,(XIZ+0xec)
	ld	(xbc+0xE3), xwa                         ; FB1C2E  ld (XBC+0x00e3),XWA
	ld	bc, (xiz-30)                            ; FB1C33  ld BC,(XIZ+0xe2)
	extz	xbc                                   ; FB1C36  extz XBC
	ld	(xbc+0xF1), de                          ; FB1C38  ld (XBC+0x00f1),DE
	ld	bc, (xiz-30)                            ; FB1C3D  ld BC,(XIZ+0xe2)
	extz	xbc                                   ; FB1C40  extz XBC
	ld	xwa, (xiz-14)                           ; FB1C42  ld XWA,(XIZ+0xf2)
	ld	(xbc+0xE7), xwa                         ; FB1C45  ld (XBC+0x00e7),XWA
	ld	bc, (xiz-30)                            ; FB1C4A  ld BC,(XIZ+0xe2)
	extz	xbc                                   ; FB1C4D  extz XBC
	ld	xwa, (xiz-24)                           ; FB1C4F  ld XWA,(XIZ+0xe8)
	ld	(xbc+0xEB), xwa                         ; FB1C52  ld (XBC+0x00eb),XWA
	pushw	hl                                   ; FB1C57  push HL
	call	0xFA7F28                              ; FB1C58  call 0xfa7f28
	pushw	3                                    ; FB1C5C  push 0x0003
	push	0                                     ; FB1C5F  push 0x00
	extpfx3 0x8E, 0xF8, 0x04                   ; FB1C61  push (XIZ+0xf8)
	call	0xFB6272                              ; FB1C64  call 0xfb6272
	extz	wa                                    ; FB1C68  extz WA
	ld	bc, (xiz-30)                            ; FB1C6A  ld BC,(XIZ+0xe2)
	extz	xbc                                   ; FB1C6D  extz XBC
	ld	(xbc+0xF7), wa                          ; FB1C6F  ld (XBC+0x00f7),WA
	push	0                                     ; FB1C74  push 0x00
	extpfx3 0x8E, 0xF8, 0x04                   ; FB1C76  push (XIZ+0xf8)
	call	0xFB5D05                              ; FB1C79  call 0xfb5d05
	extz	wa                                    ; FB1C7D  extz WA
	ld	bc, (xiz-30)                            ; FB1C7F  ld BC,(XIZ+0xe2)
	extz	xbc                                   ; FB1C82  extz XBC
	ld	(xbc+0xF9), wa                          ; FB1C84  ld (XBC+0x00f9),WA
	ld	bc, (xiz-30)                            ; FB1C89  ld BC,(XIZ+0xe2)
	extz	xbc                                   ; FB1C8C  extz XBC
	extpfx5 0xE3, 0x07, 0xE4, 0xF0, 0x20       ; FB1C8E  ld XWA,(XBC+IX)
	ld	c, (xwa+0xD1)                           ; FB1C93  ld C,(XWA+0x00d1)
	extz	bc                                    ; FB1C98  extz BC
	extz	xbc                                   ; FB1C9A  extz XBC
	add	xbc, 0xFDF6C5                          ; FB1C9C  add XBC,0x00fdf6c5
	ld	a, (xbc)                                ; FB1CA2  ld A,(XBC)
	ld	bc, (xiz-30)                            ; FB1CA4  ld BC,(XIZ+0xe2)
	extz	xbc                                   ; FB1CA7  extz XBC
	ld	(xbc+0xFD), a                           ; FB1CA9  ld (XBC+0x00fd),A
	ld	bc, (xiz-30)                            ; FB1CAE  ld BC,(XIZ+0xe2)
	extz	xbc                                   ; FB1CB1  extz XBC
	extpfx5 0xE3, 0x07, 0xE4, 0xF0, 0x20       ; FB1CB3  ld XWA,(XBC+IX)
	ld	c, (xwa+0xD2)                           ; FB1CB8  ld C,(XWA+0x00d2)
	mul	c, 2                                   ; FB1CBD  mul C,0x02
	extz	xbc                                   ; FB1CC0  extz XBC
	add	xbc, 0xFDF6E4                          ; FB1CC2  add XBC,0x00fdf6e4
	ld	bc, (xbc)                               ; FB1CC8  ld BC,(XBC)
	ld	wa, (xiz-30)                            ; FB1CCA  ld WA,(XIZ+0xe2)
	extz	xwa                                   ; FB1CCD  extz XWA
	ld	(xwa+0xFE), bc                          ; FB1CCF  ld (XWA+0x00fe),BC
	ld	bc, (xiz-30)                            ; FB1CD4  ld BC,(XIZ+0xe2)
	extz	xbc                                   ; FB1CD7  extz XBC
	extpfx5 0xE3, 0x07, 0xE4, 0xF0, 0x20       ; FB1CD9  ld XWA,(XBC+IX)
	ld	c, (xwa+0xD3)                           ; FB1CDE  ld C,(XWA+0x00d3)
	mul	c, 2                                   ; FB1CE3  mul C,0x02
	extz	xbc                                   ; FB1CE6  extz XBC
	add	xbc, 0xFDF722                          ; FB1CE8  add XBC,0x00fdf722
	ld	bc, (xbc)                               ; FB1CEE  ld BC,(XBC)
	ld	wa, (xiz-30)                            ; FB1CF0  ld WA,(XIZ+0xe2)
	extz	xwa                                   ; FB1CF3  extz XWA
	ld	(xwa+0x102), bc                         ; FB1CF5  ld (XWA+0x0102),BC
	ld	bc, (xiz-30)                            ; FB1CFA  ld BC,(XIZ+0xe2)
	extz	xbc                                   ; FB1CFD  extz XBC
	extpfx5 0xE3, 0x07, 0xE4, 0xF0, 0x20       ; FB1CFF  ld XWA,(XBC+IX)
	ld	c, (xwa+0xD4)                           ; FB1D04  ld C,(XWA+0x00d4)
	mul	c, 2                                   ; FB1D09  mul C,0x02
	extz	xbc                                   ; FB1D0C  extz XBC
	add	xbc, 0xFDF6E4                          ; FB1D0E  add XBC,0x00fdf6e4
	ld	bc, (xbc)                               ; FB1D14  ld BC,(XBC)
	ld	wa, (xiz-30)                            ; FB1D16  ld WA,(XIZ+0xe2)
	extz	xwa                                   ; FB1D19  extz XWA
	extpfx5 0xF3, 0xE1, 0x00, 0x01, 0x51       ; FB1D1B  ld (XWA+0x0100),BC
	ldb_da	c, (0xFE12AC)                       ; FB1D20  ld C,(0xfe12ac)
	set	7, c                                   ; FB1D25  set 0x07,C
	ld	(xiz-40), c                             ; FB1D28  ld (XIZ+0xd8),C
	ld	xbc, (xiz+8)                            ; FB1D2B  ld XBC,(XIZ+0x08)
	ld	a, (xiz-40)                             ; FB1D2E  ld A,(XIZ+0xd8)
	ld	(xbc+5), a                              ; FB1D31  ld (XBC+0x05),A
	ld	bc, (xiz-30)                            ; FB1D34  ld BC,(XIZ+0xe2)
	extz	xbc                                   ; FB1D37  extz XBC
	ld	wa, (xbc+0xD2)                          ; FB1D39  ld WA,(XBC+0x00d2)
	pushw	wa                                   ; FB1D3E  push WA
	ld	wa, (xbc+0xD4)                          ; FB1D3F  ld WA,(XBC+0x00d4)
	pushw	wa                                   ; FB1D44  push WA
	pushw	3                                    ; FB1D45  push 0x0003
	push	0                                     ; FB1D48  push 0x00
	extpfx3 0x8E, 0xF8, 0x04                   ; FB1D4A  push (XIZ+0xf8)
	call	0xFC4B2E                              ; FB1D4D  call 0xfc4b2e
	add	xsp, 22                                ; FB1D51  add XSP,0x00000016
	cps	a, 0                                   ; FB1D57  cp A,0
	jr z, VoiceParams_Compute_A__FB1D64        ; FB1D59  jr Z,0xfb1d64
	ld	xbc, (xiz+8)                            ; FB1D5B  ld XBC,(XIZ+0x08)
	ld	(xbc+9), 32                             ; FB1D5E  ld (XBC+0x09),0x20
	jr VoiceParams_Compute_A__FB1D6B           ; FB1D62  jr T,0xfb1d6b
VoiceParams_Compute_A__FB1D64:
	ld	xbc, (xiz+8)                            ; FB1D64  ld XBC,(XIZ+0x08)
	ld	(xbc+9), 0                              ; FB1D67  ld (XBC+0x09),0x00
VoiceParams_Compute_A__FB1D6B:
	extz	xhl                                   ; FB1D6B  extz XHL
	ld	bc, (xhl+43)                            ; FB1D6D  ld BC,(XHL+0x2b)
	cps	bc, 0                                  ; FB1D70  cp BC,0
	jr nz, VoiceParams_Compute_A__FB1D8A       ; FB1D72  jr NZ,0xfb1d8a
	extz	xhl                                   ; FB1D74  extz XHL
	ld	bc, (xhl+45)                            ; FB1D76  ld BC,(XHL+0x2d)
	cp	bc, 0xFF                                ; FB1D79  cp BC,0x00ff
	jr nz, VoiceParams_Compute_A__FB1D8A       ; FB1D7D  jr NZ,0xfb1d8a
	extz	xde                                   ; FB1D7F  extz XDE
	ld	bc, (xde+24)                            ; FB1D81  ld BC,(XDE+0x18)
	and	bc, 0x8000                             ; FB1D84  and BC,0x8000
	jr z, VoiceParams_Compute_A__FB1DA1        ; FB1D88  jr Z,0xfb1da1
VoiceParams_Compute_A__FB1D8A:
	ld	xbc, (xiz+8)                            ; FB1D8A  ld XBC,(XIZ+0x08)
	extpfx4 0x89, 0x09, 0x3E, 0x80             ; FB1D8D  or (XBC+0x09),0x80
	jr VoiceParams_Compute_A__FB1DA1           ; FB1D91  jr T,0xfb1da1
VoiceParams_Compute_A__FB1D93:
	ld	xbc, (xiz+8)                            ; FB1D93  ld XBC,(XIZ+0x08)
	ld	(xbc+5), 0                              ; FB1D96  ld (XBC+0x05),0x00
	ld	xbc, (xiz+8)                            ; FB1D9A  ld XBC,(XIZ+0x08)
	ld	(xbc+9), 0                              ; FB1D9D  ld (XBC+0x09),0x00
VoiceParams_Compute_A__FB1DA1:
	ld	xbc, (xiz+8)                            ; FB1DA1  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FB1DA4  push XBC
	call	0xFA6BB5                              ; FB1DA5  call 0xfa6bb5
	ld	xbc, 10                                 ; FB1DA9  ld XBC,0x0000000a
	ld	(xiz-6), xbc                            ; FB1DAE  ld (XIZ+0xfa),XBC
	ldw	ix, 0                                  ; FB1DB1  ld IX,0x0000
	ld	(xiz-1), 4                              ; FB1DB4  ld (XIZ+0xff),0x04
	pop	xiy                                    ; FB1DB8  pop XIY
VoiceParams_Compute_A__FB1DB9:
	ld	xbc, (xiz+8)                            ; FB1DB9  ld XBC,(XIZ+0x08)
	extpfx3 0xAE, 0xFA, 0x81                   ; FB1DBC  add XBC,(XIZ+0xfa)
	ld	h, (xbc)                                ; FB1DBF  ld H,(XBC)
	cp	h, 64                                   ; FB1DC1  cp H,0x40
	jrl nc, VoiceParams_Compute_A__FB1EA6      ; FB1DC4  jrl NC,0xfb1ea6
	ld	d, h                                    ; FB1DC7  ld D,H
	pushw	68                                   ; FB1DC9  push 0x0044
	ldb	c, 68                                  ; FB1DCC  ld C,0x44
	mul8rr	c, d                                ; FB1DCE  mul BC,D
	ld	(xiz-8), bc                             ; FB1DD0  ld (XIZ+0xf8),BC
	ldw	wa, 0x3BCF                             ; FB1DD3  ld WA,0x3bcf
	add	wa, bc                                 ; FB1DD6  add WA,BC
	extz	xwa                                   ; FB1DD8  extz XWA
	push	xwa                                   ; FB1DDA  push XWA
	ld	(xiz-10), ix                            ; FB1DDB  ld (XIZ+0xf6),IX
	ldw	wa, 0x5A53                             ; FB1DDE  ld WA,0x5a53
	extpfx3 0x9E, 0xF6, 0x80                   ; FB1DE1  add WA,(XIZ+0xf6)
	extz	xwa                                   ; FB1DE4  extz XWA
	push	xwa                                   ; FB1DE6  push XWA
	call	0xF9A038                              ; FB1DE7  call 0xf9a038
	ld	bc, (xiz-8)                             ; FB1DEB  ld BC,(XIZ+0xf8)
	extz	xbc                                   ; FB1DEE  extz XBC
	ld	(xbc+0x3BCF), d                         ; FB1DF0  ld (XBC+0x3bcf),D
	push	0                                     ; FB1DF5  push 0x00
	push	d                                     ; FB1DF7  push D
	push	0                                     ; FB1DF9  push 0x00
	extpfx3 0x8E, 0x0C, 0x04                   ; FB1DFB  push (XIZ+0x0c)
	call	0xFC376C                              ; FB1DFE  call 0xfc376c
	ld	bc, (xiz-10)                            ; FB1E02  ld BC,(XIZ+0xf6)
	add	bc, 43                                 ; FB1E05  add BC,0x002b
	extz	xbc                                   ; FB1E09  extz XBC
	ld	hl, (xbc+0x5A53)                        ; FB1E0B  ld HL,(XBC+0x5a53)
	inc	8, xsp                                 ; FB1E10  inc 0,XSP
	inc	6, xsp                                 ; FB1E12  inc 6,XSP
	cps	hl, 0                                  ; FB1E14  cp HL,0
	jr z, VoiceParams_Compute_A__FB1E24        ; FB1E16  jr Z,0xfb1e24
	ld	bc, hl                                  ; FB1E18  ld BC,HL
	sll	bc, 8                                  ; FB1E1A  sll 0x08,BC
	or	hl, bc                                  ; FB1E1D  or HL,BC
	set	15, hl                                 ; FB1E1F  set 0x0f,HL
	jr VoiceParams_Compute_A__FB1E27           ; FB1E22  jr T,0xfb1e27
VoiceParams_Compute_A__FB1E24:
	ldw	hl, 0                                  ; FB1E24  ld HL,0x0000
VoiceParams_Compute_A__FB1E27:
	ldb	c, 68                                  ; FB1E27  ld C,0x44
	mul8rr	c, d                                ; FB1E29  mul BC,D
	add	bc, 43                                 ; FB1E2B  add BC,0x002b
	extz	xbc                                   ; FB1E2F  extz XBC
	ld	(xbc+0x3BCF), hl                        ; FB1E31  ld (XBC+0x3bcf),HL
	ld	bc, ix                                  ; FB1E36  ld BC,IX
	add	bc, 45                                 ; FB1E38  add BC,0x002d
	extz	xbc                                   ; FB1E3C  extz XBC
	ld	hl, (xbc+0x5A53)                        ; FB1E3E  ld HL,(XBC+0x5a53)
	cp	hl, 0xFF                                ; FB1E43  cp HL,0x00ff
	jr z, VoiceParams_Compute_A__FB1E4F        ; FB1E47  jr Z,0xfb1e4f
	or	hl, 0xC000                              ; FB1E49  or HL,0xc000
	jr VoiceParams_Compute_A__FB1E52           ; FB1E4D  jr T,0xfb1e52
VoiceParams_Compute_A__FB1E4F:
	ldw	hl, 0xFF                               ; FB1E4F  ld HL,0x00ff
VoiceParams_Compute_A__FB1E52:
	ldb	c, 68                                  ; FB1E52  ld C,0x44
	mul8rr	c, d                                ; FB1E54  mul BC,D
	ld	(xiz-8), bc                             ; FB1E56  ld (XIZ+0xf8),BC
	add	bc, 45                                 ; FB1E59  add BC,0x002d
	extz	xbc                                   ; FB1E5D  extz XBC
	ld	(xbc+0x3BCF), hl                        ; FB1E5F  ld (XBC+0x3bcf),HL
	ld	bc, (xiz-8)                             ; FB1E64  ld BC,(XIZ+0xf8)
	add	bc, 37                                 ; FB1E67  add BC,0x0025
	extz	xbc                                   ; FB1E6B  extz XBC
	ld	wa, (xbc+0x3BCF)                        ; FB1E6D  ld WA,(XBC+0x3bcf)
	extz	xwa                                   ; FB1E72  extz XWA
	ld	bc, (xwa+24)                            ; FB1E74  ld BC,(XWA+0x18)
	and	bc, 0x8000                             ; FB1E77  and BC,0x8000
	ld	(xiz-10), bc                            ; FB1E7B  ld (XIZ+0xf6),BC
	ld	hl, (xiz-8)                             ; FB1E7E  ld HL,(XIZ+0xf8)
	inc	1, hl                                  ; FB1E81  inc 1,HL
	extz	xhl                                   ; FB1E83  extz XHL
	ld	de, (xhl+0x3BCF)                        ; FB1E85  ld DE,(XHL+0x3bcf)
	jr z, VoiceParams_Compute_A__FB1E9A        ; FB1E8A  jr Z,0xfb1e9a
	ld	bc, de                                  ; FB1E8C  ld BC,DE
	set	8, bc                                  ; FB1E8E  set 0x08,BC
	extz	xhl                                   ; FB1E91  extz XHL
	ld	(xhl+0x3BCF), bc                        ; FB1E93  ld (XHL+0x3bcf),BC
	jr VoiceParams_Compute_A__FB1EA6           ; FB1E98  jr T,0xfb1ea6
VoiceParams_Compute_A__FB1E9A:
	ld	bc, de                                  ; FB1E9A  ld BC,DE
	res	8, bc                                  ; FB1E9C  res 0x08,BC
	extz	xhl                                   ; FB1E9F  extz XHL
	ld	(xhl+0x3BCF), bc                        ; FB1EA1  ld (XHL+0x3bcf),BC
VoiceParams_Compute_A__FB1EA6:
	sub	xbc, xbc                               ; FB1EA6  sub XBC,XBC
	inc	1, xbc                                 ; FB1EA8  inc 1,XBC
	add	(xiz-6), xbc                           ; FB1EAA  add (XIZ+0xfa),XBC
	add	ix, 68                                 ; FB1EAD  add IX,0x0044
	sub	(xiz-1), c                             ; FB1EB1  sub (XIZ+0xff),C
	jrl nz, VoiceParams_Compute_A__FB1DB9      ; FB1EB4  jrl NZ,0xfb1db9
	pop	xix                                    ; FB1EB7  pop XIX
	pop	xde                                    ; FB1EB8  pop XDE
	pop	xhl                                    ; FB1EB9  pop XHL
	unlk32 xiz                                 ; FB1EBA  unlk XIZ
	ret                                        ; FB1EBC  ret
; ------------------------------------------------------------------------------
; VoiceRegs_Stage_B -- 0xFB1EBD..0xFB1FB0 (244 bytes)
;
; Called from: one site, `calr 0xFB1EBD` at 0xFB3A7A, in MidiNote_OnByPartMode's
;          part-mode 0x40 arm.
; Inputs:  (XIZ+0x08) = the voice/channel number.
; Outputs: as VoiceRegs_Stage_A -- the two staging structs and both device writes
;          (Dev104_WriteAllChanRegs at 0xFB1F51, Dev10C_WriteAllChanRegs at
;          0xFB1FA5; both writers' headers list those exact sites).
; Voice record: touches voice_record[+0x03(r), +0x06(r), +0x08(r), +0x0A(r), +0x0C(r), +0x1F(r)] -- pointer built in place.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: same shape as VoiceRegs_Stage_A: 26 distinct call targets against that
;          routine's 23, of which 20 ARE SHARED.  Its own six are 0xFA826C,
;          0xFAACEE, 0xFAB0BD, 0xFC3595, 0xFC35DB and 0xFC571A; the three
;          VoiceRegs_Stage_A has that this one does not are 0xFA819A, 0xFAA4C3 and
;          0xFC4DBD.  Every one of those figures is printed by
;          `python3 notes/prom_c_voice_module_check.py` section 10, which computes
;          the four call sets from the `1D` bytes and intersects them -- the kind
;          of arithmetic this tree has shipped wrong by hand before.
; Unknown:  ⚠ what the six extra calls add.  ⚠ "_B" is a label for "the variant
;          part mode 0x40 uses".
VoiceRegs_Stage_B:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB1EBD  link XIZ,0x0000
	pushw	hl                                   ; FB1EC1  push HL
	push	xde                                   ; FB1EC2  push XDE
	pushw	ix                                   ; FB1EC3  push IX
	ld	h, (xiz+8)                              ; FB1EC4  ld H,(XIZ+0x08)
	ldb	c, 68                                  ; FB1EC7  ld C,0x44
	mul8rr	c, h                                ; FB1EC9  mul BC,H
	ld	ix, bc                                  ; FB1ECB  ld IX,BC
	ldw	de, 0x3BCF                             ; FB1ECD  ld DE,0x3bcf
	add	de, bc                                 ; FB1ED0  add DE,BC
	extz	xde                                   ; FB1ED2  extz XDE
	ld	xbc, (xde+31)                           ; FB1ED4  ld XBC,(XDE+0x1f)
	ld	a, (xbc)                                ; FB1ED7  ld A,(XBC)
	pushw	wa                                   ; FB1ED9  push WA
	ld	c, (xde+12)                             ; FB1EDA  ld C,(XDE+0x0c)
	pushw	bc                                   ; FB1EDD  push BC
	ld	bc, (xde+8)                             ; FB1EDE  ld BC,(XDE+0x08)
	pushw	bc                                   ; FB1EE1  push BC
	ld	c, (xde+3)                              ; FB1EE2  ld C,(XDE+0x03)
	pushw	bc                                   ; FB1EE5  push BC
	call	0xFC4D63                              ; FB1EE6  call 0xfc4d63
	pushw	de                                   ; FB1EEA  push DE
	call	0xFC7F03                              ; FB1EEB  call 0xfc7f03
	pushw	de                                   ; FB1EEF  push DE
	call	0xFA826C                              ; FB1EF0  call 0xfa826c
	pushw	de                                   ; FB1EF4  push DE
	call	0xFA8323                              ; FB1EF5  call 0xfa8323
	pushw	de                                   ; FB1EF9  push DE
	call	0xFA8347                              ; FB1EFA  call 0xfa8347
	pushw	de                                   ; FB1EFE  push DE
	call	0xFA842D                              ; FB1EFF  call 0xfa842d
	pushw	de                                   ; FB1F03  push DE
	call	0xFA8BDD                              ; FB1F04  call 0xfa8bdd
	pushw	de                                   ; FB1F08  push DE
	call	0xFA919B                              ; FB1F09  call 0xfa919b
	pushw	de                                   ; FB1F0D  push DE
	call	0xFA93AF                              ; FB1F0E  call 0xfa93af
	pushw	de                                   ; FB1F12  push DE
	call	0xFA95D4                              ; FB1F13  call 0xfa95d4
	pushw	de                                   ; FB1F17  push DE
	call	0xFA9915                              ; FB1F18  call 0xfa9915
	pushw	de                                   ; FB1F1C  push DE
	call	0xFA9C60                              ; FB1F1D  call 0xfa9c60
	pushw	de                                   ; FB1F21  push DE
	call	0xFA9F19                              ; FB1F22  call 0xfa9f19
	pushw	de                                   ; FB1F26  push DE
	call	0xFAA0BC                              ; FB1F27  call 0xfaa0bc
	pushw	de                                   ; FB1F2B  push DE
	call	0xFAA2B6                              ; FB1F2C  call 0xfaa2b6
	ld	bc, (xde+10)                            ; FB1F30  ld BC,(XDE+0x0a)
	pushw	bc                                   ; FB1F33  push BC
	ld	bc, (xde+6)                             ; FB1F34  ld BC,(XDE+0x06)
	pushw	bc                                   ; FB1F37  push BC
	call	0xFC4DA1                              ; FB1F38  call 0xfc4da1
	lda	xbc, (0xD7A2:24)                       ; FB1F3C  lda XBC,0x00d7a2
	push	xbc                                   ; FB1F41  push XBC
	call	0xFC571A                              ; FB1F42  call 0xfc571a
	lda	xbc, (0xD7A2:24)                       ; FB1F46  lda XBC,0x00d7a2
	push	xbc                                   ; FB1F4B  push XBC
	ld	a, h                                    ; FB1F4C  ld A,H
	extz	wa                                    ; FB1F4E  extz WA
	pushw	wa                                   ; FB1F50  push WA
	call	0xFB77EF                              ; FB1F51  call 0xfb77ef
	ld	l, (xde+3)                              ; FB1F55  ld L,(XDE+0x03)
	add	xsp, 50                                ; FB1F58  add XSP,0x00000032
	pushw	de                                   ; FB1F5E  push DE
	cps	l, 3                                   ; FB1F5F  cp L,3
	jr nc, VoiceRegs_Stage_B__FB1F7B           ; FB1F61  jr NC,0xfb1f7b
	call	0xFAACEE                              ; FB1F63  call 0xfaacee
	pushw	0                                    ; FB1F67  push 0x0000
	pushw	de                                   ; FB1F6A  push DE
	call	0xFAA87E                              ; FB1F6B  call 0xfaa87e
	pushw	de                                   ; FB1F6F  push DE
	call	0xFAB5A5                              ; FB1F70  call 0xfab5a5
	pushw	de                                   ; FB1F74  push DE
	call	0xFC3595                              ; FB1F75  call 0xfc3595
	jr VoiceRegs_Stage_B__FB1F91               ; FB1F79  jr T,0xfb1f91
VoiceRegs_Stage_B__FB1F7B:
	call	0xFAB0BD                              ; FB1F7B  call 0xfab0bd
	pushw	0                                    ; FB1F7F  push 0x0000
	pushw	de                                   ; FB1F82  push DE
	call	0xFAA87E                              ; FB1F83  call 0xfaa87e
	pushw	de                                   ; FB1F87  push DE
	call	0xFAB5A5                              ; FB1F88  call 0xfab5a5
	pushw	de                                   ; FB1F8C  push DE
	call	0xFC35DB                              ; FB1F8D  call 0xfc35db
VoiceRegs_Stage_B__FB1F91:
	inc	8, xsp                                 ; FB1F91  inc 0,XSP
	inc	2, xsp                                 ; FB1F93  inc 2,XSP
	pushw	de                                   ; FB1F95  push DE
	call	0xFAB79D                              ; FB1F96  call 0xfab79d
	lda	xbc, (0xD75E:24)                       ; FB1F9A  lda XBC,0x00d75e
	push	xbc                                   ; FB1F9F  push XBC
	ld	a, h                                    ; FB1FA0  ld A,H
	extz	wa                                    ; FB1FA2  extz WA
	pushw	wa                                   ; FB1FA4  push WA
	call	0xFB713A                              ; FB1FA5  call 0xfb713a
	inc	8, xsp                                 ; FB1FA9  inc 0,XSP
	popw	ix                                    ; FB1FAB  pop IX
	pop	xde                                    ; FB1FAC  pop XDE
	popw	hl                                    ; FB1FAD  pop HL
	unlk32 xiz                                 ; FB1FAE  unlk XIZ
	ret                                        ; FB1FB0  ret
; ------------------------------------------------------------------------------
; sub_FB1FB1 -- 0xFB1FB1..0xFB2171 (449 bytes)
;
; ⚠ UNREFERENCED, exactly as sub_FB0B95 is -- see that routine's header for the
; census and for why the pattern is recorded rather than named.
; Called from: nothing found (searched negative).
; Evidence: same prologue as VoiceParams_Compute_B (0xFB2172, immediately after
;          it): `mul BC,0x012c`, `(XBC+0x1523)`, `+0x12`.  Its call set
;          {0xFA7F28, Shift8_LogicalRight} is a strict subset of that routine's
;          six (checker section 11).
sub_FB1FB1:
	link32 0xEE, 0x0C, 0xEC, 0xFF              ; FB1FB1  link XIZ,0xffec
	push	xhl                                   ; FB1FB5  push XHL
	pushw	de                                   ; FB1FB6  push DE
	push	xix                                   ; FB1FB7  push XIX
	ld	bc, (xiz+12)                            ; FB1FB8  ld BC,(XIZ+0x0c)
	extz	bc                                    ; FB1FBB  extz BC
	mul	bc, 0x12C                              ; FB1FBD  mul BC,0x012c
	ld	ix, bc                                  ; FB1FC1  ld IX,BC
	extz	xbc                                   ; FB1FC3  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB1FC5  ld XWA,(XBC+0x1523)
	ld	e, (xwa+18)                             ; FB1FCA  ld E,(XWA+0x12)
	ld	wa, (xiz+16)                            ; FB1FCD  ld WA,(XIZ+0x10)
	extz	wa                                    ; FB1FD0  extz WA
	extz	xwa                                   ; FB1FD2  extz XWA
	ld	(xiz-12), xwa                           ; FB1FD4  ld (XIZ+0xf4),XWA
	add	xwa, 0xFE12AD                          ; FB1FD7  add XWA,0x00fe12ad
	ld	w, (xwa)                                ; FB1FDD  ld W,(XWA)
	and	w, e                                   ; FB1FDF  and W,E
	ld	(xiz-14), w                             ; FB1FE1  ld (XIZ+0xf2),W
	lda	xiy, (0xFE12B1:24)                     ; FB1FE4  lda XIY,0xfe12b1
	extpfx3 0xAE, 0xF4, 0x85                   ; FB1FE9  add XIY,(XIZ+0xf4)
	ld	a, (xiy)                                ; FB1FEC  ld A,(XIY)
	pushw	wa                                   ; FB1FEE  push WA
	push	0                                     ; FB1FEF  push 0x00
	push	w                                     ; FB1FF1  push W
	call	0xFCB23C                              ; FB1FF3  call 0xfcb23c
	ld	d, a                                    ; FB1FF7  ld D,A
	ld	bc, ix                                  ; FB1FF9  ld BC,IX
	inc	6, bc                                  ; FB1FFB  inc 6,BC
	extz	xbc                                   ; FB1FFD  extz XBC
	ld	hl, (xbc+0x1523)                        ; FB1FFF  ld HL,(XBC+0x1523)
	ld	bc, (xiz+14)                            ; FB2004  ld BC,(XIZ+0x0e)
	extz	bc                                    ; FB2007  extz BC
	and	bc, hl                                 ; FB2009  and BC,HL
	jrl z, sub_FB1FB1__FB214E                  ; FB200B  jrl Z,0xfb214e
	cps	a, 2                                   ; FB200E  cp A,2
	jr nz, sub_FB1FB1__FB201A                  ; FB2010  jr NZ,0xfb201a
	ld	bc, hl                                  ; FB2012  ld BC,HL
	and	bc, 0x2000                             ; FB2014  and BC,0x2000
	jr z, sub_FB1FB1__FB202B                   ; FB2018  jr Z,0xfb202b
sub_FB1FB1__FB201A:
	cps	d, 3                                   ; FB201A  cp D,3
	jr nz, sub_FB1FB1__FB2026                  ; FB201C  jr NZ,0xfb2026
	ld	bc, hl                                  ; FB201E  ld BC,HL
	and	bc, 0x2000                             ; FB2020  and BC,0x2000
	jr nz, sub_FB1FB1__FB202B                  ; FB2024  jr NZ,0xfb202b
sub_FB1FB1__FB2026:
	cps	d, 1                                   ; FB2026  cp D,1
	jrl ugt, sub_FB1FB1__FB214E                ; FB2028  jrl UGT,0xfb214e
sub_FB1FB1__FB202B:
	ldb	c, 41                                  ; FB202B  ld C,0x29
	extpfx3 0x8E, 0x10, 0x43                   ; FB202D  mul BC,(XIZ+0x10)
	ld	(xiz-10), bc                            ; FB2030  ld (XIZ+0xf6),BC
	ld	wa, (xiz+12)                            ; FB2033  ld WA,(XIZ+0x0c)
	extz	wa                                    ; FB2036  extz WA
	mul	wa, 0x12C                              ; FB2038  mul WA,0x012c
	add	wa, bc                                 ; FB203C  add WA,BC
	ld	(xiz-12), wa                            ; FB203E  ld (XIZ+0xf4),WA
	add	wa, 0x8C                               ; FB2041  add WA,0x008c
	extz	xwa                                   ; FB2045  extz XWA
	ld	xbc, (xwa+0x1523)                       ; FB2047  ld XBC,(XWA+0x1523)
	ld	(xiz-4), xbc                            ; FB204C  ld (XIZ+0xfc),XBC
	ld	wa, (xiz-12)                            ; FB204F  ld WA,(XIZ+0xf4)
	add	wa, 0x88                               ; FB2052  add WA,0x0088
	ld	(xiz-14), wa                            ; FB2056  ld (XIZ+0xf2),WA
	extz	xwa                                   ; FB2059  extz XWA
	ld	xiy, (xwa+0x1523)                       ; FB205B  ld XIY,(XWA+0x1523)
	ld	(xiz-8), xiy                            ; FB2060  ld (XIZ+0xf8),XIY
	ld	bc, (xiz-12)                            ; FB2063  ld BC,(XIZ+0xf4)
	add	bc, 0x90                               ; FB2066  add BC,0x0090
	ld	(xiz-16), bc                            ; FB206A  ld (XIZ+0xf0),BC
	ldw	bc, 0x1523                             ; FB206D  ld BC,0x1523
	ld	(xiz-18), bc                            ; FB2070  ld (XIZ+0xee),BC
	ld	wa, (xiz-16)                            ; FB2073  ld WA,(XIZ+0xf0)
	extz	xbc                                   ; FB2076  extz XBC
	extpfx5 0xE3, 0x07, 0xE4, 0xE0, 0x20       ; FB2078  ld XWA,(XBC+WA)
	ld	xix, xwa                                ; FB207D  ld XIX,XWA
	ld	de, bc                                  ; FB207F  ld DE,BC
	extpfx3 0x9E, 0xF2, 0x82                   ; FB2081  add DE,(XIZ+0xf2)
	ldb	c, 68                                  ; FB2084  ld C,0x44
	extpfx3 0x8E, 0x10, 0x43                   ; FB2086  mul BC,(XIZ+0x10)
	ld	(xiz-20), bc                            ; FB2089  ld (XIZ+0xec),BC
	ldw	hl, 0x5A53                             ; FB208C  ld HL,0x5a53
	add	hl, bc                                 ; FB208F  add HL,BC
	extz	xhl                                   ; FB2091  extz XHL
	extpfx5 0xBB, 0x01, 0x02, 0x08, 0x00       ; FB2093  ld (XHL+0x01),0x0008
	ld	c, (xiz+20)                             ; FB2098  ld C,(XIZ+0x14)
	and	c, 0x80                                ; FB209B  and C,0x80
	jr z, sub_FB1FB1__FB20A7                   ; FB209E  jr Z,0xfb20a7
	extz	xhl                                   ; FB20A0  extz XHL
	extpfx5 0x9B, 0x01, 0x3E, 0x00, 0x08       ; FB20A2  or (XHL+0x01),0x0800
sub_FB1FB1__FB20A7:
	extz	xhl                                   ; FB20A7  extz XHL
	ld	c, (xiz+16)                             ; FB20A9  ld C,(XIZ+0x10)
	ld	(xhl+3), c                              ; FB20AC  ld (XHL+0x03),C
	ld	c, (xiz+12)                             ; FB20AF  ld C,(XIZ+0x0c)
	ld	(xhl+4), c                              ; FB20B2  ld (XHL+0x04),C
	ld	c, (xiz+18)                             ; FB20B5  ld C,(XIZ+0x12)
	set	7, c                                   ; FB20B8  set 0x07,C
	ld	(xhl+5), c                              ; FB20BB  ld (XHL+0x05),C
	ld	c, (xiz+20)                             ; FB20BE  ld C,(XIZ+0x14)
	res	7, c                                   ; FB20C1  res 0x07,C
	ld	(xhl+12), c                             ; FB20C4  ld (XHL+0x0c),C
	ld	bc, (xiz+12)                            ; FB20C7  ld BC,(XIZ+0x0c)
	extz	bc                                    ; FB20CA  extz BC
	mul	bc, 0x12C                              ; FB20CC  mul BC,0x012c
	ld	(xiz-10), bc                            ; FB20D0  ld (XIZ+0xf6),BC
	ldw	wa, 0x1523                             ; FB20D3  ld WA,0x1523
	add	wa, bc                                 ; FB20D6  add WA,BC
	ld	(xhl+35), wa                            ; FB20D8  ld (XHL+0x23),WA
	ld	bc, (xiz-10)                            ; FB20DB  ld BC,(XIZ+0xf6)
	extz	xbc                                   ; FB20DE  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB20E0  ld XWA,(XBC+0x1523)
	ld	(xhl+19), xwa                           ; FB20E5  ld (XHL+0x13),XWA
	ld	xbc, (xiz-8)                            ; FB20E8  ld XBC,(XIZ+0xf8)
	ld	(xhl+23), xbc                           ; FB20EB  ld (XHL+0x17),XBC
	ld	xbc, (xiz-4)                            ; FB20EE  ld XBC,(XIZ+0xfc)
	ld	(xhl+27), xbc                           ; FB20F1  ld (XHL+0x1b),XBC
	ld	(xhl+31), xix                           ; FB20F4  ld (XHL+0x1f),XIX
	ld	(xhl+37), de                            ; FB20F7  ld (XHL+0x25),DE
	pushw	hl                                   ; FB20FA  push HL
	call	0xFA7F28                              ; FB20FB  call 0xfa7f28
	extpfx5 0xBB, 0x2B, 0x02, 0x00, 0x00       ; FB20FF  ld (XHL+0x2b),0x0000
	extpfx5 0xBB, 0x2D, 0x02, 0xFF, 0x00       ; FB2104  ld (XHL+0x2d),0x00ff
	ld	(xhl+49), 0                             ; FB2109  ld (XHL+0x31),0x00
	extpfx5 0xBB, 0x32, 0x02, 0x00, 0x00       ; FB210D  ld (XHL+0x32),0x0000
	extpfx5 0xBB, 0x36, 0x02, 0x00, 0x00       ; FB2112  ld (XHL+0x36),0x0000
	extpfx5 0xBB, 0x34, 0x02, 0x00, 0x00       ; FB2117  ld (XHL+0x34),0x0000
	ld	c, (xiz+22)                             ; FB211C  ld C,(XIZ+0x16)
	set	7, c                                   ; FB211F  set 0x07,C
	ld	(xiz-12), c                             ; FB2122  ld (XIZ+0xf4),C
	ld	ix, (xiz+16)                            ; FB2125  ld IX,(XIZ+0x10)
	extz	ix                                    ; FB2128  extz IX
	extz	xix                                   ; FB212A  extz XIX
	ld	xbc, xix                                ; FB212C  ld XBC,XIX
	inc	2, xbc                                 ; FB212E  inc 2,XBC
	extpfx3 0xAE, 0x08, 0x81                   ; FB2130  add XBC,(XIZ+0x08)
	ld	a, (xiz-12)                             ; FB2133  ld A,(XIZ+0xf4)
	ld	(xbc), a                                ; FB2136  ld (XBC),A
	ld	bc, (xhl+6)                             ; FB2138  ld BC,(XHL+0x06)
	popw	wa                                    ; FB213B  pop WA
	cp	bc, 0x2980                              ; FB213C  cp BC,0x2980
	jr ugt, sub_FB1FB1__FB215D                 ; FB2140  jr UGT,0xfb215d
	ld	xbc, xix                                ; FB2142  ld XBC,XIX
	inc	6, xbc                                 ; FB2144  inc 6,XBC
	extpfx3 0xAE, 0x08, 0x81                   ; FB2146  add XBC,(XIZ+0x08)
	ld	(xbc), 32                               ; FB2149  ld (XBC),0x20
	jr sub_FB1FB1__FB216C                      ; FB214C  jr T,0xfb216c
sub_FB1FB1__FB214E:
	ld	bc, (xiz+16)                            ; FB214E  ld BC,(XIZ+0x10)
	extz	bc                                    ; FB2151  extz BC
	extz	xbc                                   ; FB2153  extz XBC
	inc	2, xbc                                 ; FB2155  inc 2,XBC
	extpfx3 0xAE, 0x08, 0x81                   ; FB2157  add XBC,(XIZ+0x08)
	ld	(xbc), 0                                ; FB215A  ld (XBC),0x00
sub_FB1FB1__FB215D:
	ld	bc, (xiz+16)                            ; FB215D  ld BC,(XIZ+0x10)
	extz	bc                                    ; FB2160  extz BC
	extz	xbc                                   ; FB2162  extz XBC
	inc	6, xbc                                 ; FB2164  inc 6,XBC
	extpfx3 0xAE, 0x08, 0x81                   ; FB2166  add XBC,(XIZ+0x08)
	ld	(xbc), 0                                ; FB2169  ld (XBC),0x00
sub_FB1FB1__FB216C:
	pop	xix                                    ; FB216C  pop XIX
	popw	de                                    ; FB216D  pop DE
	pop	xhl                                    ; FB216E  pop XHL
	unlk32 xiz                                 ; FB216F  unlk XIZ
	ret                                        ; FB2171  ret
; ------------------------------------------------------------------------------
; VoiceParams_Compute_B -- 0xFB2172..0xFB27ED (1660 bytes)
;
; Called from: one site, `calr 0xFB2172` at 0xFB3A02, in MidiNote_OnByPartMode's
;          part-mode 0x40 arm.
; Inputs/Outputs: as VoiceParams_Compute_A.
; Evidence: reads the same 0xFE12AD mask / 0xFE12B1 shift pair -- and this routine
;          reads ALL EIGHT bytes 0xFE12AD-0xFE12B4, which is what shows the two
;          tables are four entries each and not one constant apiece.
;          Calls MemCopyWords (0xF9A038), 0xFA6BB5, 0xFA7F28, 0xFC376C, 0xFC382A
;          and Shift8_LogicalRight.
; Unknown:  ⚠ the formulae, as for _A.
VoiceParams_Compute_B:
	link32 0xEE, 0x0C, 0xEE, 0xFF              ; FB2172  link XIZ,0xffee
	push	xhl                                   ; FB2176  push XHL
	pushw	de                                   ; FB2177  push DE
	push	xix                                   ; FB2178  push XIX
	push	0                                     ; FB2179  push 0x00
	extpfx3 0x8E, 0x0C, 0x04                   ; FB217B  push (XIZ+0x0c)
	call	0xFC382A                              ; FB217E  call 0xfc382a
	ld	ix, (xiz+12)                            ; FB2182  ld IX,(XIZ+0x0c)
	extz	ix                                    ; FB2185  extz IX
	ld	bc, ix                                  ; FB2187  ld BC,IX
	sll	bc, 8                                  ; FB2189  sll 0x08,BC
	ld	(xiz-10), bc                            ; FB218C  ld (XIZ+0xf6),BC
	ld	wa, (xiz+14)                            ; FB218F  ld WA,(XIZ+0x0e)
	extz	wa                                    ; FB2192  extz WA
	or	bc, wa                                  ; FB2194  or BC,WA
	set	7, bc                                  ; FB2196  set 0x07,BC
	ld	xwa, (xiz+8)                            ; FB2199  ld XWA,(XIZ+0x08)
	ld	(xwa), bc                               ; FB219C  ld (XWA),BC
	ldw	bc, 0x12C                              ; FB219E  ld BC,0x012c
	mul	xbc, xix                               ; FB21A1  mul XBC,IX
	ld	ix, bc                                  ; FB21A3  ld IX,BC
	extz	xbc                                   ; FB21A5  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB21A7  ld XWA,(XBC+0x1523)
	ld	e, (xwa+18)                             ; FB21AC  ld E,(XWA+0x12)
	ldb_da	a, (0xFE12AD)                       ; FB21AF  ld A,(0xfe12ad)
	and	a, e                                   ; FB21B4  and A,E
	ld	(xiz-12), a                             ; FB21B6  ld (XIZ+0xf4),A
	ldb_da	w, (0xFE12B1)                       ; FB21B9  ld W,(0xfe12b1)
	push	0                                     ; FB21BE  push 0x00
	push	w                                     ; FB21C0  push W
	pushw	wa                                   ; FB21C2  push WA
	call	0xFCB23C                              ; FB21C3  call 0xfcb23c
	ld	d, a                                    ; FB21C7  ld D,A
	ld	bc, ix                                  ; FB21C9  ld BC,IX
	inc	6, bc                                  ; FB21CB  inc 6,BC
	extz	xbc                                   ; FB21CD  extz XBC
	ld	hl, (xbc+0x1523)                        ; FB21CF  ld HL,(XBC+0x1523)
	ld	bc, hl                                  ; FB21D4  ld BC,HL
	and	bc, 1                                  ; FB21D6  and BC,0x0001
	popw	iy                                    ; FB21DA  pop IY
	jrl z, VoiceParams_Compute_B__FB22F0       ; FB21DB  jrl Z,0xfb22f0
	cps	a, 2                                   ; FB21DE  cp A,2
	jr nz, VoiceParams_Compute_B__FB21EA       ; FB21E0  jr NZ,0xfb21ea
	ld	bc, hl                                  ; FB21E2  ld BC,HL
	and	bc, 0x2000                             ; FB21E4  and BC,0x2000
	jr z, VoiceParams_Compute_B__FB21FB        ; FB21E8  jr Z,0xfb21fb
VoiceParams_Compute_B__FB21EA:
	cps	d, 3                                   ; FB21EA  cp D,3
	jr nz, VoiceParams_Compute_B__FB21F6       ; FB21EC  jr NZ,0xfb21f6
	ld	bc, hl                                  ; FB21EE  ld BC,HL
	and	bc, 0x2000                             ; FB21F0  and BC,0x2000
	jr nz, VoiceParams_Compute_B__FB21FB       ; FB21F4  jr NZ,0xfb21fb
VoiceParams_Compute_B__FB21F6:
	cps	d, 1                                   ; FB21F6  cp D,1
	jrl ugt, VoiceParams_Compute_B__FB22F0     ; FB21F8  jrl UGT,0xfb22f0
VoiceParams_Compute_B__FB21FB:
	ld	bc, (xiz+12)                            ; FB21FB  ld BC,(XIZ+0x0c)
	extz	bc                                    ; FB21FE  extz BC
	mul	bc, 0x12C                              ; FB2200  mul BC,0x012c
	ld	(xiz-10), bc                            ; FB2204  ld (XIZ+0xf6),BC
	add	bc, 0x8C                               ; FB2207  add BC,0x008c
	extz	xbc                                   ; FB220B  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB220D  ld XWA,(XBC+0x1523)
	ld	(xiz-4), xwa                            ; FB2212  ld (XIZ+0xfc),XWA
	ld	bc, (xiz-10)                            ; FB2215  ld BC,(XIZ+0xf6)
	add	bc, 0x88                               ; FB2218  add BC,0x0088
	ld	(xiz-12), bc                            ; FB221C  ld (XIZ+0xf4),BC
	extz	xbc                                   ; FB221F  extz XBC
	ld	xiy, (xbc+0x1523)                       ; FB2221  ld XIY,(XBC+0x1523)
	ld	(xiz-8), xiy                            ; FB2226  ld (XIZ+0xf8),XIY
	ld	bc, (xiz-10)                            ; FB2229  ld BC,(XIZ+0xf6)
	add	bc, 0x90                               ; FB222C  add BC,0x0090
	ld	(xiz-14), bc                            ; FB2230  ld (XIZ+0xf2),BC
	ldw	bc, 0x1523                             ; FB2233  ld BC,0x1523
	ld	(xiz-16), bc                            ; FB2236  ld (XIZ+0xf0),BC
	ld	wa, (xiz-14)                            ; FB2239  ld WA,(XIZ+0xf2)
	extz	xbc                                   ; FB223C  extz XBC
	extpfx5 0xE3, 0x07, 0xE4, 0xE0, 0x20       ; FB223E  ld XWA,(XBC+WA)
	ld	xix, xwa                                ; FB2243  ld XIX,XWA
	ld	de, bc                                  ; FB2245  ld DE,BC
	extpfx3 0x9E, 0xF4, 0x82                   ; FB2247  add DE,(XIZ+0xf4)
	ldw	hl, 0x5A53                             ; FB224A  ld HL,0x5a53
	extz	xhl                                   ; FB224D  extz XHL
	extpfx5 0xBB, 0x01, 0x02, 0x08, 0x00       ; FB224F  ld (XHL+0x01),0x0008
	ld	c, (xiz+16)                             ; FB2254  ld C,(XIZ+0x10)
	and	c, 0x80                                ; FB2257  and C,0x80
	jr z, VoiceParams_Compute_B__FB2263        ; FB225A  jr Z,0xfb2263
	extz	xhl                                   ; FB225C  extz XHL
	extpfx5 0x9B, 0x01, 0x3E, 0x00, 0x08       ; FB225E  or (XHL+0x01),0x0800
VoiceParams_Compute_B__FB2263:
	extz	xhl                                   ; FB2263  extz XHL
	ld	(xhl+3), 0                              ; FB2265  ld (XHL+0x03),0x00
	ld	c, (xiz+12)                             ; FB2269  ld C,(XIZ+0x0c)
	ld	(xhl+4), c                              ; FB226C  ld (XHL+0x04),C
	ld	c, (xiz+14)                             ; FB226F  ld C,(XIZ+0x0e)
	set	7, c                                   ; FB2272  set 0x07,C
	ld	(xhl+5), c                              ; FB2275  ld (XHL+0x05),C
	ld	c, (xiz+16)                             ; FB2278  ld C,(XIZ+0x10)
	res	7, c                                   ; FB227B  res 0x07,C
	ld	(xhl+12), c                             ; FB227E  ld (XHL+0x0c),C
	ld	bc, (xiz+12)                            ; FB2281  ld BC,(XIZ+0x0c)
	extz	bc                                    ; FB2284  extz BC
	mul	bc, 0x12C                              ; FB2286  mul BC,0x012c
	ld	(xiz-10), bc                            ; FB228A  ld (XIZ+0xf6),BC
	ldw	wa, 0x1523                             ; FB228D  ld WA,0x1523
	add	wa, bc                                 ; FB2290  add WA,BC
	ld	(xhl+35), wa                            ; FB2292  ld (XHL+0x23),WA
	ld	bc, (xiz-10)                            ; FB2295  ld BC,(XIZ+0xf6)
	extz	xbc                                   ; FB2298  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB229A  ld XWA,(XBC+0x1523)
	ld	(xhl+19), xwa                           ; FB229F  ld (XHL+0x13),XWA
	ld	xbc, (xiz-8)                            ; FB22A2  ld XBC,(XIZ+0xf8)
	ld	(xhl+23), xbc                           ; FB22A5  ld (XHL+0x17),XBC
	ld	xbc, (xiz-4)                            ; FB22A8  ld XBC,(XIZ+0xfc)
	ld	(xhl+27), xbc                           ; FB22AB  ld (XHL+0x1b),XBC
	ld	(xhl+31), xix                           ; FB22AE  ld (XHL+0x1f),XIX
	ld	(xhl+37), de                            ; FB22B1  ld (XHL+0x25),DE
	pushw	hl                                   ; FB22B4  push HL
	call	0xFA7F28                              ; FB22B5  call 0xfa7f28
	extpfx5 0xBB, 0x2B, 0x02, 0x00, 0x00       ; FB22B9  ld (XHL+0x2b),0x0000
	extpfx5 0xBB, 0x2D, 0x02, 0xFF, 0x00       ; FB22BE  ld (XHL+0x2d),0x00ff
	ld	(xhl+49), 0                             ; FB22C3  ld (XHL+0x31),0x00
	extpfx5 0xBB, 0x32, 0x02, 0x00, 0x00       ; FB22C7  ld (XHL+0x32),0x0000
	extpfx5 0xBB, 0x36, 0x02, 0x00, 0x00       ; FB22CC  ld (XHL+0x36),0x0000
	extpfx5 0xBB, 0x34, 0x02, 0x00, 0x00       ; FB22D1  ld (XHL+0x34),0x0000
	ld	xbc, (xiz+8)                            ; FB22D6  ld XBC,(XIZ+0x08)
	ld	(xbc+2), 0x80                           ; FB22D9  ld (XBC+0x02),0x80
	ld	bc, (xhl+6)                             ; FB22DD  ld BC,(XHL+0x06)
	popw	wa                                    ; FB22E0  pop WA
	cp	bc, 0x2980                              ; FB22E1  cp BC,0x2980
	jr ugt, VoiceParams_Compute_B__FB22F7      ; FB22E5  jr UGT,0xfb22f7
	ld	xbc, (xiz+8)                            ; FB22E7  ld XBC,(XIZ+0x08)
	ld	(xbc+6), 32                             ; FB22EA  ld (XBC+0x06),0x20
	jr VoiceParams_Compute_B__FB22FE           ; FB22EE  jr T,0xfb22fe
VoiceParams_Compute_B__FB22F0:
	ld	xbc, (xiz+8)                            ; FB22F0  ld XBC,(XIZ+0x08)
	ld	(xbc+2), 0                              ; FB22F3  ld (XBC+0x02),0x00
VoiceParams_Compute_B__FB22F7:
	ld	xbc, (xiz+8)                            ; FB22F7  ld XBC,(XIZ+0x08)
	ld	(xbc+6), 0                              ; FB22FA  ld (XBC+0x06),0x00
VoiceParams_Compute_B__FB22FE:
	ld	bc, (xiz+12)                            ; FB22FE  ld BC,(XIZ+0x0c)
	extz	bc                                    ; FB2301  extz BC
	mul	bc, 0x12C                              ; FB2303  mul BC,0x012c
	ld	ix, bc                                  ; FB2307  ld IX,BC
	extz	xbc                                   ; FB2309  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB230B  ld XWA,(XBC+0x1523)
	ld	e, (xwa+18)                             ; FB2310  ld E,(XWA+0x12)
	ldb_da	a, (0xFE12AE)                       ; FB2313  ld A,(0xfe12ae)
	and	a, e                                   ; FB2318  and A,E
	ld	(xiz-10), a                             ; FB231A  ld (XIZ+0xf6),A
	ldb_da	w, (0xFE12B2)                       ; FB231D  ld W,(0xfe12b2)
	push	0                                     ; FB2322  push 0x00
	push	w                                     ; FB2324  push W
	pushw	wa                                   ; FB2326  push WA
	call	0xFCB23C                              ; FB2327  call 0xfcb23c
	ld	d, a                                    ; FB232B  ld D,A
	ld	bc, ix                                  ; FB232D  ld BC,IX
	inc	6, bc                                  ; FB232F  inc 6,BC
	extz	xbc                                   ; FB2331  extz XBC
	ld	hl, (xbc+0x1523)                        ; FB2333  ld HL,(XBC+0x1523)
	ld	bc, hl                                  ; FB2338  ld BC,HL
	and	bc, 2                                  ; FB233A  and BC,0x0002
	jrl z, VoiceParams_Compute_B__FB2467       ; FB233E  jrl Z,0xfb2467
	cps	a, 2                                   ; FB2341  cp A,2
	jr nz, VoiceParams_Compute_B__FB234D       ; FB2343  jr NZ,0xfb234d
	ld	bc, hl                                  ; FB2345  ld BC,HL
	and	bc, 0x2000                             ; FB2347  and BC,0x2000
	jr z, VoiceParams_Compute_B__FB235E        ; FB234B  jr Z,0xfb235e
VoiceParams_Compute_B__FB234D:
	cps	d, 3                                   ; FB234D  cp D,3
	jr nz, VoiceParams_Compute_B__FB2359       ; FB234F  jr NZ,0xfb2359
	ld	bc, hl                                  ; FB2351  ld BC,HL
	and	bc, 0x2000                             ; FB2353  and BC,0x2000
	jr nz, VoiceParams_Compute_B__FB235E       ; FB2357  jr NZ,0xfb235e
VoiceParams_Compute_B__FB2359:
	cps	d, 1                                   ; FB2359  cp D,1
	jrl ugt, VoiceParams_Compute_B__FB2467     ; FB235B  jrl UGT,0xfb2467
VoiceParams_Compute_B__FB235E:
	ld	bc, (xiz+12)                            ; FB235E  ld BC,(XIZ+0x0c)
	extz	bc                                    ; FB2361  extz BC
	mul	bc, 0x12C                              ; FB2363  mul BC,0x012c
	ld	(xiz-10), bc                            ; FB2367  ld (XIZ+0xf6),BC
	add	bc, 41                                 ; FB236A  add BC,0x0029
	ld	(xiz-12), bc                            ; FB236E  ld (XIZ+0xf4),BC
	ld	wa, (xiz-10)                            ; FB2371  ld WA,(XIZ+0xf6)
	add	wa, 0xB5                               ; FB2374  add WA,0x00b5
	extz	xwa                                   ; FB2378  extz XWA
	ld	xiy, (xwa+0x1523)                       ; FB237A  ld XIY,(XWA+0x1523)
	ld	(xiz-4), xiy                            ; FB237F  ld (XIZ+0xfc),XIY
	ld	wa, (xiz-10)                            ; FB2382  ld WA,(XIZ+0xf6)
	add	wa, 0xB1                               ; FB2385  add WA,0x00b1
	extz	xwa                                   ; FB2389  extz XWA
	ld	xbc, (xwa+0x1523)                       ; FB238B  ld XBC,(XWA+0x1523)
	ld	(xiz-8), xbc                            ; FB2390  ld (XIZ+0xf8),XBC
	ld	wa, (xiz-12)                            ; FB2393  ld WA,(XIZ+0xf4)
	add	wa, 0x90                               ; FB2396  add WA,0x0090
	ld	(xiz-14), wa                            ; FB239A  ld (XIZ+0xf2),WA
	ldw	bc, 0x1523                             ; FB239D  ld BC,0x1523
	ld	(xiz-16), bc                            ; FB23A0  ld (XIZ+0xf0),BC
	extz	xbc                                   ; FB23A3  extz XBC
	extpfx5 0xE3, 0x07, 0xE4, 0xE0, 0x20       ; FB23A5  ld XWA,(XBC+WA)
	ld	xix, xwa                                ; FB23AA  ld XIX,XWA
	ld	bc, (xiz-12)                            ; FB23AC  ld BC,(XIZ+0xf4)
	add	bc, 0x88                               ; FB23AF  add BC,0x0088
	ld	de, bc                                  ; FB23B3  ld DE,BC
	extpfx3 0x9E, 0xF0, 0x82                   ; FB23B5  add DE,(XIZ+0xf0)
	ldw	bc, 0x5A53                             ; FB23B8  ld BC,0x5a53
	ld	(xiz-18), bc                            ; FB23BB  ld (XIZ+0xee),BC
	ld	hl, bc                                  ; FB23BE  ld HL,BC
	add	hl, 68                                 ; FB23C0  add HL,0x0044
	extz	xbc                                   ; FB23C4  extz XBC
	extpfx5 0xB9, 0x45, 0x02, 0x08, 0x00       ; FB23C6  ld (XBC+0x45),0x0008
	ld	c, (xiz+16)                             ; FB23CB  ld C,(XIZ+0x10)
	and	c, 0x80                                ; FB23CE  and C,0x80
	jr z, VoiceParams_Compute_B__FB23DA        ; FB23D1  jr Z,0xfb23da
	extz	xhl                                   ; FB23D3  extz XHL
	extpfx5 0x9B, 0x01, 0x3E, 0x00, 0x08       ; FB23D5  or (XHL+0x01),0x0800
VoiceParams_Compute_B__FB23DA:
	extz	xhl                                   ; FB23DA  extz XHL
	ld	(xhl+3), 1                              ; FB23DC  ld (XHL+0x03),0x01
	ld	c, (xiz+12)                             ; FB23E0  ld C,(XIZ+0x0c)
	ld	(xhl+4), c                              ; FB23E3  ld (XHL+0x04),C
	ld	c, (xiz+14)                             ; FB23E6  ld C,(XIZ+0x0e)
	set	7, c                                   ; FB23E9  set 0x07,C
	ld	(xhl+5), c                              ; FB23EC  ld (XHL+0x05),C
	ld	c, (xiz+16)                             ; FB23EF  ld C,(XIZ+0x10)
	res	7, c                                   ; FB23F2  res 0x07,C
	ld	(xhl+12), c                             ; FB23F5  ld (XHL+0x0c),C
	ld	bc, (xiz+12)                            ; FB23F8  ld BC,(XIZ+0x0c)
	extz	bc                                    ; FB23FB  extz BC
	mul	bc, 0x12C                              ; FB23FD  mul BC,0x012c
	ld	(xiz-10), bc                            ; FB2401  ld (XIZ+0xf6),BC
	ldw	wa, 0x1523                             ; FB2404  ld WA,0x1523
	add	wa, bc                                 ; FB2407  add WA,BC
	ld	(xhl+35), wa                            ; FB2409  ld (XHL+0x23),WA
	ld	bc, (xiz-10)                            ; FB240C  ld BC,(XIZ+0xf6)
	extz	xbc                                   ; FB240F  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB2411  ld XWA,(XBC+0x1523)
	ld	(xhl+19), xwa                           ; FB2416  ld (XHL+0x13),XWA
	ld	xbc, (xiz-8)                            ; FB2419  ld XBC,(XIZ+0xf8)
	ld	(xhl+23), xbc                           ; FB241C  ld (XHL+0x17),XBC
	ld	xbc, (xiz-4)                            ; FB241F  ld XBC,(XIZ+0xfc)
	ld	(xhl+27), xbc                           ; FB2422  ld (XHL+0x1b),XBC
	ld	(xhl+31), xix                           ; FB2425  ld (XHL+0x1f),XIX
	ld	(xhl+37), de                            ; FB2428  ld (XHL+0x25),DE
	pushw	hl                                   ; FB242B  push HL
	call	0xFA7F28                              ; FB242C  call 0xfa7f28
	extpfx5 0xBB, 0x2B, 0x02, 0x00, 0x00       ; FB2430  ld (XHL+0x2b),0x0000
	extpfx5 0xBB, 0x2D, 0x02, 0xFF, 0x00       ; FB2435  ld (XHL+0x2d),0x00ff
	ld	(xhl+49), 0                             ; FB243A  ld (XHL+0x31),0x00
	extpfx5 0xBB, 0x32, 0x02, 0x00, 0x00       ; FB243E  ld (XHL+0x32),0x0000
	extpfx5 0xBB, 0x36, 0x02, 0x00, 0x00       ; FB2443  ld (XHL+0x36),0x0000
	extpfx5 0xBB, 0x34, 0x02, 0x00, 0x00       ; FB2448  ld (XHL+0x34),0x0000
	ld	xbc, (xiz+8)                            ; FB244D  ld XBC,(XIZ+0x08)
	ld	(xbc+3), 0x81                           ; FB2450  ld (XBC+0x03),0x81
	ld	bc, (xhl+6)                             ; FB2454  ld BC,(XHL+0x06)
	popw	wa                                    ; FB2457  pop WA
	cp	bc, 0x2980                              ; FB2458  cp BC,0x2980
	jr ugt, VoiceParams_Compute_B__FB246E      ; FB245C  jr UGT,0xfb246e
	ld	xbc, (xiz+8)                            ; FB245E  ld XBC,(XIZ+0x08)
	ld	(xbc+7), 32                             ; FB2461  ld (XBC+0x07),0x20
	jr VoiceParams_Compute_B__FB2475           ; FB2465  jr T,0xfb2475
VoiceParams_Compute_B__FB2467:
	ld	xbc, (xiz+8)                            ; FB2467  ld XBC,(XIZ+0x08)
	ld	(xbc+3), 0                              ; FB246A  ld (XBC+0x03),0x00
VoiceParams_Compute_B__FB246E:
	ld	xbc, (xiz+8)                            ; FB246E  ld XBC,(XIZ+0x08)
	ld	(xbc+7), 0                              ; FB2471  ld (XBC+0x07),0x00
VoiceParams_Compute_B__FB2475:
	ld	bc, (xiz+12)                            ; FB2475  ld BC,(XIZ+0x0c)
	extz	bc                                    ; FB2478  extz BC
	mul	bc, 0x12C                              ; FB247A  mul BC,0x012c
	ld	ix, bc                                  ; FB247E  ld IX,BC
	extz	xbc                                   ; FB2480  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB2482  ld XWA,(XBC+0x1523)
	ld	e, (xwa+18)                             ; FB2487  ld E,(XWA+0x12)
	ldb_da	a, (0xFE12AF)                       ; FB248A  ld A,(0xfe12af)
	and	a, e                                   ; FB248F  and A,E
	ld	(xiz-10), a                             ; FB2491  ld (XIZ+0xf6),A
	ldb_da	w, (0xFE12B3)                       ; FB2494  ld W,(0xfe12b3)
	push	0                                     ; FB2499  push 0x00
	push	w                                     ; FB249B  push W
	pushw	wa                                   ; FB249D  push WA
	call	0xFCB23C                              ; FB249E  call 0xfcb23c
	ld	d, a                                    ; FB24A2  ld D,A
	ld	bc, ix                                  ; FB24A4  ld BC,IX
	inc	6, bc                                  ; FB24A6  inc 6,BC
	extz	xbc                                   ; FB24A8  extz XBC
	ld	hl, (xbc+0x1523)                        ; FB24AA  ld HL,(XBC+0x1523)
	ld	bc, hl                                  ; FB24AF  ld BC,HL
	and	bc, 4                                  ; FB24B1  and BC,0x0004
	jrl z, VoiceParams_Compute_B__FB25E0       ; FB24B5  jrl Z,0xfb25e0
	cps	a, 2                                   ; FB24B8  cp A,2
	jr nz, VoiceParams_Compute_B__FB24C4       ; FB24BA  jr NZ,0xfb24c4
	ld	bc, hl                                  ; FB24BC  ld BC,HL
	and	bc, 0x2000                             ; FB24BE  and BC,0x2000
	jr z, VoiceParams_Compute_B__FB24D5        ; FB24C2  jr Z,0xfb24d5
VoiceParams_Compute_B__FB24C4:
	cps	d, 3                                   ; FB24C4  cp D,3
	jr nz, VoiceParams_Compute_B__FB24D0       ; FB24C6  jr NZ,0xfb24d0
	ld	bc, hl                                  ; FB24C8  ld BC,HL
	and	bc, 0x2000                             ; FB24CA  and BC,0x2000
	jr nz, VoiceParams_Compute_B__FB24D5       ; FB24CE  jr NZ,0xfb24d5
VoiceParams_Compute_B__FB24D0:
	cps	d, 1                                   ; FB24D0  cp D,1
	jrl ugt, VoiceParams_Compute_B__FB25E0     ; FB24D2  jrl UGT,0xfb25e0
VoiceParams_Compute_B__FB24D5:
	ld	bc, (xiz+12)                            ; FB24D5  ld BC,(XIZ+0x0c)
	extz	bc                                    ; FB24D8  extz BC
	mul	bc, 0x12C                              ; FB24DA  mul BC,0x012c
	ld	(xiz-10), bc                            ; FB24DE  ld (XIZ+0xf6),BC
	add	bc, 82                                 ; FB24E1  add BC,0x0052
	ld	(xiz-12), bc                            ; FB24E5  ld (XIZ+0xf4),BC
	ld	wa, (xiz-10)                            ; FB24E8  ld WA,(XIZ+0xf6)
	add	wa, 0xDE                               ; FB24EB  add WA,0x00de
	extz	xwa                                   ; FB24EF  extz XWA
	ld	xiy, (xwa+0x1523)                       ; FB24F1  ld XIY,(XWA+0x1523)
	ld	(xiz-4), xiy                            ; FB24F6  ld (XIZ+0xfc),XIY
	ld	wa, (xiz-10)                            ; FB24F9  ld WA,(XIZ+0xf6)
	add	wa, 0xDA                               ; FB24FC  add WA,0x00da
	extz	xwa                                   ; FB2500  extz XWA
	ld	xbc, (xwa+0x1523)                       ; FB2502  ld XBC,(XWA+0x1523)
	ld	(xiz-8), xbc                            ; FB2507  ld (XIZ+0xf8),XBC
	ld	wa, (xiz-12)                            ; FB250A  ld WA,(XIZ+0xf4)
	add	wa, 0x90                               ; FB250D  add WA,0x0090
	ld	(xiz-14), wa                            ; FB2511  ld (XIZ+0xf2),WA
	ldw	bc, 0x1523                             ; FB2514  ld BC,0x1523
	ld	(xiz-16), bc                            ; FB2517  ld (XIZ+0xf0),BC
	extz	xbc                                   ; FB251A  extz XBC
	extpfx5 0xE3, 0x07, 0xE4, 0xE0, 0x20       ; FB251C  ld XWA,(XBC+WA)
	ld	xix, xwa                                ; FB2521  ld XIX,XWA
	ld	bc, (xiz-12)                            ; FB2523  ld BC,(XIZ+0xf4)
	add	bc, 0x88                               ; FB2526  add BC,0x0088
	ld	de, bc                                  ; FB252A  ld DE,BC
	extpfx3 0x9E, 0xF0, 0x82                   ; FB252C  add DE,(XIZ+0xf0)
	ldw	bc, 0x5A53                             ; FB252F  ld BC,0x5a53
	ld	(xiz-18), bc                            ; FB2532  ld (XIZ+0xee),BC
	ld	hl, bc                                  ; FB2535  ld HL,BC
	add	hl, 0x88                               ; FB2537  add HL,0x0088
	extz	xbc                                   ; FB253B  extz XBC
	extpfx7 0xF3, 0xE5, 0x89, 0x00, 0x02, 0x08, 0x00 ; FB253D  ld (XBC+0x0089),0x0008
	ld	c, (xiz+16)                             ; FB2544  ld C,(XIZ+0x10)
	and	c, 0x80                                ; FB2547  and C,0x80
	jr z, VoiceParams_Compute_B__FB2553        ; FB254A  jr Z,0xfb2553
	extz	xhl                                   ; FB254C  extz XHL
	extpfx5 0x9B, 0x01, 0x3E, 0x00, 0x08       ; FB254E  or (XHL+0x01),0x0800
VoiceParams_Compute_B__FB2553:
	extz	xhl                                   ; FB2553  extz XHL
	ld	(xhl+3), 2                              ; FB2555  ld (XHL+0x03),0x02
	ld	c, (xiz+12)                             ; FB2559  ld C,(XIZ+0x0c)
	ld	(xhl+4), c                              ; FB255C  ld (XHL+0x04),C
	ld	c, (xiz+14)                             ; FB255F  ld C,(XIZ+0x0e)
	set	7, c                                   ; FB2562  set 0x07,C
	ld	(xhl+5), c                              ; FB2565  ld (XHL+0x05),C
	ld	c, (xiz+16)                             ; FB2568  ld C,(XIZ+0x10)
	res	7, c                                   ; FB256B  res 0x07,C
	ld	(xhl+12), c                             ; FB256E  ld (XHL+0x0c),C
	ld	bc, (xiz+12)                            ; FB2571  ld BC,(XIZ+0x0c)
	extz	bc                                    ; FB2574  extz BC
	mul	bc, 0x12C                              ; FB2576  mul BC,0x012c
	ld	(xiz-10), bc                            ; FB257A  ld (XIZ+0xf6),BC
	ldw	wa, 0x1523                             ; FB257D  ld WA,0x1523
	add	wa, bc                                 ; FB2580  add WA,BC
	ld	(xhl+35), wa                            ; FB2582  ld (XHL+0x23),WA
	ld	bc, (xiz-10)                            ; FB2585  ld BC,(XIZ+0xf6)
	extz	xbc                                   ; FB2588  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB258A  ld XWA,(XBC+0x1523)
	ld	(xhl+19), xwa                           ; FB258F  ld (XHL+0x13),XWA
	ld	xbc, (xiz-8)                            ; FB2592  ld XBC,(XIZ+0xf8)
	ld	(xhl+23), xbc                           ; FB2595  ld (XHL+0x17),XBC
	ld	xbc, (xiz-4)                            ; FB2598  ld XBC,(XIZ+0xfc)
	ld	(xhl+27), xbc                           ; FB259B  ld (XHL+0x1b),XBC
	ld	(xhl+31), xix                           ; FB259E  ld (XHL+0x1f),XIX
	ld	(xhl+37), de                            ; FB25A1  ld (XHL+0x25),DE
	pushw	hl                                   ; FB25A4  push HL
	call	0xFA7F28                              ; FB25A5  call 0xfa7f28
	extpfx5 0xBB, 0x2B, 0x02, 0x00, 0x00       ; FB25A9  ld (XHL+0x2b),0x0000
	extpfx5 0xBB, 0x2D, 0x02, 0xFF, 0x00       ; FB25AE  ld (XHL+0x2d),0x00ff
	ld	(xhl+49), 0                             ; FB25B3  ld (XHL+0x31),0x00
	extpfx5 0xBB, 0x32, 0x02, 0x00, 0x00       ; FB25B7  ld (XHL+0x32),0x0000
	extpfx5 0xBB, 0x36, 0x02, 0x00, 0x00       ; FB25BC  ld (XHL+0x36),0x0000
	extpfx5 0xBB, 0x34, 0x02, 0x00, 0x00       ; FB25C1  ld (XHL+0x34),0x0000
	ld	xbc, (xiz+8)                            ; FB25C6  ld XBC,(XIZ+0x08)
	ld	(xbc+4), 0x81                           ; FB25C9  ld (XBC+0x04),0x81
	ld	bc, (xhl+6)                             ; FB25CD  ld BC,(XHL+0x06)
	popw	wa                                    ; FB25D0  pop WA
	cp	bc, 0x2980                              ; FB25D1  cp BC,0x2980
	jr ugt, VoiceParams_Compute_B__FB25E7      ; FB25D5  jr UGT,0xfb25e7
	ld	xbc, (xiz+8)                            ; FB25D7  ld XBC,(XIZ+0x08)
	ld	(xbc+8), 32                             ; FB25DA  ld (XBC+0x08),0x20
	jr VoiceParams_Compute_B__FB25EE           ; FB25DE  jr T,0xfb25ee
VoiceParams_Compute_B__FB25E0:
	ld	xbc, (xiz+8)                            ; FB25E0  ld XBC,(XIZ+0x08)
	ld	(xbc+4), 0                              ; FB25E3  ld (XBC+0x04),0x00
VoiceParams_Compute_B__FB25E7:
	ld	xbc, (xiz+8)                            ; FB25E7  ld XBC,(XIZ+0x08)
	ld	(xbc+8), 0                              ; FB25EA  ld (XBC+0x08),0x00
VoiceParams_Compute_B__FB25EE:
	ld	c, (xiz+16)                             ; FB25EE  ld C,(XIZ+0x10)
	and	c, 0x80                                ; FB25F1  and C,0x80
	jr z, VoiceParams_Compute_B__FB2607        ; FB25F4  jr Z,0xfb2607
	ld	xbc, (xiz+8)                            ; FB25F6  ld XBC,(XIZ+0x08)
	ld	(xbc+5), 0                              ; FB25F9  ld (XBC+0x05),0x00
	ld	xbc, (xiz+8)                            ; FB25FD  ld XBC,(XIZ+0x08)
	ld	(xbc+9), 0                              ; FB2600  ld (XBC+0x09),0x00
	jrl VoiceParams_Compute_B__FB2780          ; FB2604  jrl T,0xfb2780
VoiceParams_Compute_B__FB2607:
	ld	bc, (xiz+12)                            ; FB2607  ld BC,(XIZ+0x0c)
	extz	bc                                    ; FB260A  extz BC
	mul	bc, 0x12C                              ; FB260C  mul BC,0x012c
	ld	ix, bc                                  ; FB2610  ld IX,BC
	extz	xbc                                   ; FB2612  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB2614  ld XWA,(XBC+0x1523)
	ld	e, (xwa+18)                             ; FB2619  ld E,(XWA+0x12)
	ldb_da	a, (0xFE12B0)                       ; FB261C  ld A,(0xfe12b0)
	and	a, e                                   ; FB2621  and A,E
	ld	(xiz-10), a                             ; FB2623  ld (XIZ+0xf6),A
	ldb_da	w, (0xFE12B4)                       ; FB2626  ld W,(0xfe12b4)
	push	0                                     ; FB262B  push 0x00
	push	w                                     ; FB262D  push W
	pushw	wa                                   ; FB262F  push WA
	call	0xFCB23C                              ; FB2630  call 0xfcb23c
	ld	d, a                                    ; FB2634  ld D,A
	ld	bc, ix                                  ; FB2636  ld BC,IX
	inc	6, bc                                  ; FB2638  inc 6,BC
	extz	xbc                                   ; FB263A  extz XBC
	ld	hl, (xbc+0x1523)                        ; FB263C  ld HL,(XBC+0x1523)
	ld	bc, hl                                  ; FB2641  ld BC,HL
	and	bc, 8                                  ; FB2643  and BC,0x0008
	jrl z, VoiceParams_Compute_B__FB2772       ; FB2647  jrl Z,0xfb2772
	cps	a, 2                                   ; FB264A  cp A,2
	jr nz, VoiceParams_Compute_B__FB2656       ; FB264C  jr NZ,0xfb2656
	ld	bc, hl                                  ; FB264E  ld BC,HL
	and	bc, 0x2000                             ; FB2650  and BC,0x2000
	jr z, VoiceParams_Compute_B__FB2667        ; FB2654  jr Z,0xfb2667
VoiceParams_Compute_B__FB2656:
	cps	d, 3                                   ; FB2656  cp D,3
	jr nz, VoiceParams_Compute_B__FB2662       ; FB2658  jr NZ,0xfb2662
	ld	bc, hl                                  ; FB265A  ld BC,HL
	and	bc, 0x2000                             ; FB265C  and BC,0x2000
	jr nz, VoiceParams_Compute_B__FB2667       ; FB2660  jr NZ,0xfb2667
VoiceParams_Compute_B__FB2662:
	cps	d, 1                                   ; FB2662  cp D,1
	jrl ugt, VoiceParams_Compute_B__FB2772     ; FB2664  jrl UGT,0xfb2772
VoiceParams_Compute_B__FB2667:
	ld	bc, (xiz+12)                            ; FB2667  ld BC,(XIZ+0x0c)
	extz	bc                                    ; FB266A  extz BC
	mul	bc, 0x12C                              ; FB266C  mul BC,0x012c
	ld	(xiz-10), bc                            ; FB2670  ld (XIZ+0xf6),BC
	add	bc, 0x7B                               ; FB2673  add BC,0x007b
	ld	(xiz-12), bc                            ; FB2677  ld (XIZ+0xf4),BC
	ld	wa, (xiz-10)                            ; FB267A  ld WA,(XIZ+0xf6)
	add	wa, 0x107                              ; FB267D  add WA,0x0107
	extz	xwa                                   ; FB2681  extz XWA
	ld	xiy, (xwa+0x1523)                       ; FB2683  ld XIY,(XWA+0x1523)
	ld	(xiz-4), xiy                            ; FB2688  ld (XIZ+0xfc),XIY
	ld	wa, (xiz-10)                            ; FB268B  ld WA,(XIZ+0xf6)
	add	wa, 0x103                              ; FB268E  add WA,0x0103
	extz	xwa                                   ; FB2692  extz XWA
	ld	xbc, (xwa+0x1523)                       ; FB2694  ld XBC,(XWA+0x1523)
	ld	(xiz-8), xbc                            ; FB2699  ld (XIZ+0xf8),XBC
	ld	wa, (xiz-12)                            ; FB269C  ld WA,(XIZ+0xf4)
	add	wa, 0x90                               ; FB269F  add WA,0x0090
	ld	(xiz-14), wa                            ; FB26A3  ld (XIZ+0xf2),WA
	ldw	bc, 0x1523                             ; FB26A6  ld BC,0x1523
	ld	(xiz-16), bc                            ; FB26A9  ld (XIZ+0xf0),BC
	extz	xbc                                   ; FB26AC  extz XBC
	extpfx5 0xE3, 0x07, 0xE4, 0xE0, 0x20       ; FB26AE  ld XWA,(XBC+WA)
	ld	xix, xwa                                ; FB26B3  ld XIX,XWA
	ld	bc, (xiz-12)                            ; FB26B5  ld BC,(XIZ+0xf4)
	add	bc, 0x88                               ; FB26B8  add BC,0x0088
	ld	de, bc                                  ; FB26BC  ld DE,BC
	extpfx3 0x9E, 0xF0, 0x82                   ; FB26BE  add DE,(XIZ+0xf0)
	ldw	bc, 0x5A53                             ; FB26C1  ld BC,0x5a53
	ld	(xiz-18), bc                            ; FB26C4  ld (XIZ+0xee),BC
	ld	hl, bc                                  ; FB26C7  ld HL,BC
	add	hl, 0xCC                               ; FB26C9  add HL,0x00cc
	extz	xbc                                   ; FB26CD  extz XBC
	extpfx7 0xF3, 0xE5, 0xCD, 0x00, 0x02, 0x08, 0x00 ; FB26CF  ld (XBC+0x00cd),0x0008
	ld	c, (xiz+16)                             ; FB26D6  ld C,(XIZ+0x10)
	and	c, 0x80                                ; FB26D9  and C,0x80
	jr z, VoiceParams_Compute_B__FB26E5        ; FB26DC  jr Z,0xfb26e5
	extz	xhl                                   ; FB26DE  extz XHL
	extpfx5 0x9B, 0x01, 0x3E, 0x00, 0x08       ; FB26E0  or (XHL+0x01),0x0800
VoiceParams_Compute_B__FB26E5:
	extz	xhl                                   ; FB26E5  extz XHL
	ld	(xhl+3), 3                              ; FB26E7  ld (XHL+0x03),0x03
	ld	c, (xiz+12)                             ; FB26EB  ld C,(XIZ+0x0c)
	ld	(xhl+4), c                              ; FB26EE  ld (XHL+0x04),C
	ld	c, (xiz+14)                             ; FB26F1  ld C,(XIZ+0x0e)
	set	7, c                                   ; FB26F4  set 0x07,C
	ld	(xhl+5), c                              ; FB26F7  ld (XHL+0x05),C
	ld	c, (xiz+16)                             ; FB26FA  ld C,(XIZ+0x10)
	res	7, c                                   ; FB26FD  res 0x07,C
	ld	(xhl+12), c                             ; FB2700  ld (XHL+0x0c),C
	ld	bc, (xiz+12)                            ; FB2703  ld BC,(XIZ+0x0c)
	extz	bc                                    ; FB2706  extz BC
	mul	bc, 0x12C                              ; FB2708  mul BC,0x012c
	ld	(xiz-10), bc                            ; FB270C  ld (XIZ+0xf6),BC
	ldw	wa, 0x1523                             ; FB270F  ld WA,0x1523
	add	wa, bc                                 ; FB2712  add WA,BC
	ld	(xhl+35), wa                            ; FB2714  ld (XHL+0x23),WA
	ld	bc, (xiz-10)                            ; FB2717  ld BC,(XIZ+0xf6)
	extz	xbc                                   ; FB271A  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB271C  ld XWA,(XBC+0x1523)
	ld	(xhl+19), xwa                           ; FB2721  ld (XHL+0x13),XWA
	ld	xbc, (xiz-8)                            ; FB2724  ld XBC,(XIZ+0xf8)
	ld	(xhl+23), xbc                           ; FB2727  ld (XHL+0x17),XBC
	ld	xbc, (xiz-4)                            ; FB272A  ld XBC,(XIZ+0xfc)
	ld	(xhl+27), xbc                           ; FB272D  ld (XHL+0x1b),XBC
	ld	(xhl+31), xix                           ; FB2730  ld (XHL+0x1f),XIX
	ld	(xhl+37), de                            ; FB2733  ld (XHL+0x25),DE
	pushw	hl                                   ; FB2736  push HL
	call	0xFA7F28                              ; FB2737  call 0xfa7f28
	extpfx5 0xBB, 0x2B, 0x02, 0x00, 0x00       ; FB273B  ld (XHL+0x2b),0x0000
	extpfx5 0xBB, 0x2D, 0x02, 0xFF, 0x00       ; FB2740  ld (XHL+0x2d),0x00ff
	ld	(xhl+49), 0                             ; FB2745  ld (XHL+0x31),0x00
	extpfx5 0xBB, 0x32, 0x02, 0x00, 0x00       ; FB2749  ld (XHL+0x32),0x0000
	extpfx5 0xBB, 0x36, 0x02, 0x00, 0x00       ; FB274E  ld (XHL+0x36),0x0000
	extpfx5 0xBB, 0x34, 0x02, 0x00, 0x00       ; FB2753  ld (XHL+0x34),0x0000
	ld	xbc, (xiz+8)                            ; FB2758  ld XBC,(XIZ+0x08)
	ld	(xbc+5), 0x83                           ; FB275B  ld (XBC+0x05),0x83
	ld	bc, (xhl+6)                             ; FB275F  ld BC,(XHL+0x06)
	popw	wa                                    ; FB2762  pop WA
	cp	bc, 0x2980                              ; FB2763  cp BC,0x2980
	jr ugt, VoiceParams_Compute_B__FB2779      ; FB2767  jr UGT,0xfb2779
	ld	xbc, (xiz+8)                            ; FB2769  ld XBC,(XIZ+0x08)
	ld	(xbc+9), 32                             ; FB276C  ld (XBC+0x09),0x20
	jr VoiceParams_Compute_B__FB2780           ; FB2770  jr T,0xfb2780
VoiceParams_Compute_B__FB2772:
	ld	xbc, (xiz+8)                            ; FB2772  ld XBC,(XIZ+0x08)
	ld	(xbc+5), 0                              ; FB2775  ld (XBC+0x05),0x00
VoiceParams_Compute_B__FB2779:
	ld	xbc, (xiz+8)                            ; FB2779  ld XBC,(XIZ+0x08)
	ld	(xbc+9), 0                              ; FB277C  ld (XBC+0x09),0x00
VoiceParams_Compute_B__FB2780:
	ld	xbc, (xiz+8)                            ; FB2780  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FB2783  push XBC
	call	0xFA6BB5                              ; FB2784  call 0xfa6bb5
	ld	xix, 10                                 ; FB2788  ld XIX,0x0000000a
	ldw	de, 0                                  ; FB278D  ld DE,0x0000
	ldb	l, 4                                   ; FB2790  ld L,0x04
	pop	xiy                                    ; FB2792  pop XIY
VoiceParams_Compute_B__FB2793:
	ld	xbc, (xiz+8)                            ; FB2793  ld XBC,(XIZ+0x08)
	add	xbc, xix                               ; FB2796  add XBC,XIX
	ld	h, (xbc)                                ; FB2798  ld H,(XBC)
	cp	h, 64                                   ; FB279A  cp H,0x40
	jr nc, VoiceParams_Compute_B__FB27DC       ; FB279D  jr NC,0xfb27dc
	pushw	68                                   ; FB279F  push 0x0044
	ldb	c, 68                                  ; FB27A2  ld C,0x44
	mul8rr	c, h                                ; FB27A4  mul BC,H
	ld	(xiz-10), bc                            ; FB27A6  ld (XIZ+0xf6),BC
	ldw	wa, 0x3BCF                             ; FB27A9  ld WA,0x3bcf
	add	wa, bc                                 ; FB27AC  add WA,BC
	extz	xwa                                   ; FB27AE  extz XWA
	push	xwa                                   ; FB27B0  push XWA
	ld	(xiz-12), de                            ; FB27B1  ld (XIZ+0xf4),DE
	ldw	wa, 0x5A53                             ; FB27B4  ld WA,0x5a53
	extpfx3 0x9E, 0xF4, 0x80                   ; FB27B7  add WA,(XIZ+0xf4)
	extz	xwa                                   ; FB27BA  extz XWA
	push	xwa                                   ; FB27BC  push XWA
	call	0xF9A038                              ; FB27BD  call 0xf9a038
	ld	bc, (xiz-10)                            ; FB27C1  ld BC,(XIZ+0xf6)
	extz	xbc                                   ; FB27C4  extz XBC
	ld	(xbc+0x3BCF), h                         ; FB27C6  ld (XBC+0x3bcf),H
	push	0                                     ; FB27CB  push 0x00
	push	h                                     ; FB27CD  push H
	push	0                                     ; FB27CF  push 0x00
	extpfx3 0x8E, 0x0C, 0x04                   ; FB27D1  push (XIZ+0x0c)
	call	0xFC376C                              ; FB27D4  call 0xfc376c
	inc	8, xsp                                 ; FB27D8  inc 0,XSP
	inc	6, xsp                                 ; FB27DA  inc 6,XSP
VoiceParams_Compute_B__FB27DC:
	inc	1, xix                                 ; FB27DC  inc 1,XIX
	add	de, 68                                 ; FB27DE  add DE,0x0044
	dec	1, l                                   ; FB27E2  dec 1,L
	cps	l, 0                                   ; FB27E4  cp L,0
	jr nz, VoiceParams_Compute_B__FB2793       ; FB27E6  jr NZ,0xfb2793
	pop	xix                                    ; FB27E8  pop XIX
	popw	de                                    ; FB27E9  pop DE
	pop	xhl                                    ; FB27EA  pop XHL
	unlk32 xiz                                 ; FB27EB  unlk XIZ
	ret                                        ; FB27ED  ret
; ------------------------------------------------------------------------------
; VoiceRegs_Stage_C -- 0xFB27EE..0xFB2899 (172 bytes)
;
; Called from: TWO sites, `calr 0xFB27EE` at 0xFB3948 (part-mode 0x00 arm) and at
;          0xFB3B98 (part-mode 0x80 arm) -- the only staging routine two modes
;          share.
; Inputs:  (XIZ+0x08) = the voice/channel number.
; Outputs: Dev104_WriteAllChanRegs at 0xFB2876, Dev10C_WriteAllChanRegs at
;          0xFB288B.
; Voice record: touches voice_record[+0x03(r), +0x06(r), +0x08(r), +0x0A(r), +0x0C(r), +0x1F(r)] -- pointer built in place.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: ★ 18 distinct call targets, and ALL EIGHTEEN are also called by
;          VoiceRegs_Stage_D -- this routine's call set is a strict SUBSET of that
;          one's, which has exactly two more (0xFC35B8 and 0xFC369F).  Against
;          VoiceRegs_Stage_A it shares only 6 of 18, and against _B only 4.
;          ★ THAT IS WHAT MAKES THE FOUR TWO FAMILIES OF TWO: A n B = 20 shared,
;          C n D = 18 shared, and every cross-family intersection is 4 or 6.  All
;          six intersections are computed by
;          `python3 notes/prom_c_voice_module_check.py` section 10.
; Unknown:  ⚠ the helpers.
VoiceRegs_Stage_C:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB27EE  link XIZ,0x0000
	pushw	hl                                   ; FB27F2  push HL
	push	xde                                   ; FB27F3  push XDE
	ldb	c, 68                                  ; FB27F4  ld C,0x44
	extpfx3 0x8E, 0x08, 0x43                   ; FB27F6  mul BC,(XIZ+0x08)
	ld	hl, bc                                  ; FB27F9  ld HL,BC
	ldw	wa, 0x3BCF                             ; FB27FB  ld WA,0x3bcf
	ld	de, wa                                  ; FB27FE  ld DE,WA
	add	de, bc                                 ; FB2800  add DE,BC
	extz	xde                                   ; FB2802  extz XDE
	ld	xbc, (xde+31)                           ; FB2804  ld XBC,(XDE+0x1f)
	ld	a, (xbc)                                ; FB2807  ld A,(XBC)
	pushw	wa                                   ; FB2809  push WA
	ld	c, (xde+12)                             ; FB280A  ld C,(XDE+0x0c)
	pushw	bc                                   ; FB280D  push BC
	ld	bc, (xde+8)                             ; FB280E  ld BC,(XDE+0x08)
	pushw	bc                                   ; FB2811  push BC
	ld	c, (xde+3)                              ; FB2812  ld C,(XDE+0x03)
	pushw	bc                                   ; FB2815  push BC
	call	0xFC4D63                              ; FB2816  call 0xfc4d63
	pushw	de                                   ; FB281A  push DE
	call	0xFC7F7A                              ; FB281B  call 0xfc7f7a
	pushw	de                                   ; FB281F  push DE
	call	0xFA819A                              ; FB2820  call 0xfa819a
	pushw	de                                   ; FB2824  push DE
	call	0xFA83A8                              ; FB2825  call 0xfa83a8
	pushw	de                                   ; FB2829  push DE
	call	0xFA83CC                              ; FB282A  call 0xfa83cc
	pushw	de                                   ; FB282E  push DE
	call	0xFA900A                              ; FB282F  call 0xfa900a
	pushw	de                                   ; FB2833  push DE
	call	0xFA92A5                              ; FB2834  call 0xfa92a5
	pushw	de                                   ; FB2838  push DE
	call	0xFAA1A5                              ; FB2839  call 0xfaa1a5
	pushw	de                                   ; FB283D  push DE
	call	0xFAA3EB                              ; FB283E  call 0xfaa3eb
	pushw	de                                   ; FB2842  push DE
	call	0xFAA96C                              ; FB2843  call 0xfaa96c
	pushw	0                                    ; FB2847  push 0x0000
	pushw	de                                   ; FB284A  push DE
	call	0xFAAC00                              ; FB284B  call 0xfaac00
	pushw	de                                   ; FB284F  push DE
	call	0xFA96F7                              ; FB2850  call 0xfa96f7
	ld	bc, (xde+10)                            ; FB2854  ld BC,(XDE+0x0a)
	pushw	bc                                   ; FB2857  push BC
	ld	bc, (xde+6)                             ; FB2858  ld BC,(XDE+0x06)
	pushw	bc                                   ; FB285B  push BC
	call	0xFC4DA1                              ; FB285C  call 0xfc4da1
	lda	xbc, (0xD7A2:24)                       ; FB2860  lda XBC,0x00d7a2
	push	xbc                                   ; FB2865  push XBC
	call	0xFC4DBD                              ; FB2866  call 0xfc4dbd
	lda	xbc, (0xD7A2:24)                       ; FB286A  lda XBC,0x00d7a2
	push	xbc                                   ; FB286F  push XBC
	ld	hl, (xiz+8)                             ; FB2870  ld HL,(XIZ+0x08)
	extz	hl                                    ; FB2873  extz HL
	pushw	hl                                   ; FB2875  push HL
	call	0xFB77EF                              ; FB2876  call 0xfb77ef
	pushw	de                                   ; FB287A  push DE
	call	0xFAB6D5                              ; FB287B  call 0xfab6d5
	pushw	de                                   ; FB287F  push DE
	call	0xFAB7E0                              ; FB2880  call 0xfab7e0
	lda	xbc, (0xD75E:24)                       ; FB2884  lda XBC,0x00d75e
	push	xbc                                   ; FB2889  push XBC
	pushw	hl                                   ; FB288A  push HL
	call	0xFB713A                              ; FB288B  call 0xfb713a
	add	xsp, 56                                ; FB288F  add XSP,0x00000038
	pop	xde                                    ; FB2895  pop XDE
	popw	hl                                    ; FB2896  pop HL
	unlk32 xiz                                 ; FB2897  unlk XIZ
	ret                                        ; FB2899  ret
; ------------------------------------------------------------------------------
; sub_FB289A -- 0xFB289A..0xFB2A97 (510 bytes)
; ⚠ UNREFERENCED -- see sub_FB0B95's header.
; Called from: nothing found (searched negative).
; Evidence: call set {0xFA72B3, 0xFA814C, 0xFB456F, 0xFB474E, 0xFB49EB, 0xFC4B2E,
;          0xFC6803} is a strict subset of VoiceParams_Compute_C's ten, which
;          follows it immediately (checker section 11).
sub_FB289A:
	link32 0xEE, 0x0C, 0xE4, 0xFF              ; FB289A  link XIZ,0xffe4
	pushw	hl                                   ; FB289E  push HL
	pushw	de                                   ; FB289F  push DE
	push	xix                                   ; FB28A0  push XIX
	ld	e, (xiz+16)                             ; FB28A1  ld E,(XIZ+0x10)
	ld	d, (xiz+12)                             ; FB28A4  ld D,(XIZ+0x0c)
	ld	c, d                                    ; FB28A7  ld C,D
	extz	bc                                    ; FB28A9  extz BC
	mul	bc, 0x12C                              ; FB28AB  mul BC,0x012c
	ld	hl, bc                                  ; FB28AF  ld HL,BC
	extz	xbc                                   ; FB28B1  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB28B3  ld XWA,(XBC+0x1523)
	ld	(xiz-12), xwa                           ; FB28B8  ld (XIZ+0xf4),XWA
	push	0                                     ; FB28BB  push 0x00
	extpfx3 0x8E, 0x12, 0x04                   ; FB28BD  push (XIZ+0x12)
	push	xwa                                   ; FB28C0  push XWA
	push	0                                     ; FB28C1  push 0x00
	push	d                                     ; FB28C3  push D
	call	0xFB49EB                              ; FB28C5  call 0xfb49eb
	ld	(xiz-8), xiy                            ; FB28C9  ld (XIZ+0xf8),XIY
	ldb	c, 23                                  ; FB28CC  ld C,0x17
	mul8rr	c, e                                ; FB28CE  mul BC,E
	extz	xbc                                   ; FB28D0  extz XBC
	add	xbc, 18                                ; FB28D2  add XBC,0x00000012
	add	xiy, xbc                               ; FB28D8  add XIY,XBC
	ld	(xiz-4), xiy                            ; FB28DA  ld (XIZ+0xfc),XIY
	push	0                                     ; FB28DD  push 0x00
	extpfx3 0x8E, 0x12, 0x04                   ; FB28DF  push (XIZ+0x12)
	ld	xbc, (xiz-8)                            ; FB28E2  ld XBC,(XIZ+0xf8)
	push	xbc                                   ; FB28E5  push XBC
	pushw	de                                   ; FB28E6  push DE
	push	0                                     ; FB28E7  push 0x00
	push	d                                     ; FB28E9  push D
	call	0xFB456F                              ; FB28EB  call 0xfb456f
	ld	xix, xiy                                ; FB28EF  ld XIX,XIY
	ld	xbc, (xiz-8)                            ; FB28F1  ld XBC,(XIZ+0xf8)
	ld	a, (xbc+13)                             ; FB28F4  ld A,(XBC+0x0d)
	extz	wa                                    ; FB28F7  extz WA
	extpfx3 0x9E, 0x0E, 0xC0                   ; FB28F9  and WA,(XIZ+0x0e)
	add	xsp, 18                                ; FB28FC  add XSP,0x00000012
	cps	wa, 0                                  ; FB2902  cp WA,0
	jrl z, sub_FB289A__FB2A65                  ; FB2904  jrl Z,0xfb2a65
	push	xiy                                   ; FB2907  push XIY
	push	0                                     ; FB2908  push 0x00
	extpfx3 0x8E, 0x14, 0x04                   ; FB290A  push (XIZ+0x14)
	call	0xFA72B3                              ; FB290D  call 0xfa72b3
	ld	(xiz-10), a                             ; FB2911  ld (XIZ+0xf6),A
	push	xix                                   ; FB2914  push XIX
	pushw	wa                                   ; FB2915  push WA
	call	0xFB474E                              ; FB2916  call 0xfb474e
	ld	(xiz-14), xiy                           ; FB291A  ld (XIZ+0xf2),XIY
	ldb	c, 68                                  ; FB291D  ld C,0x44
	mul8rr	c, e                                ; FB291F  mul BC,E
	ld	(xiz-16), bc                            ; FB2921  ld (XIZ+0xf0),BC
	ldw	wa, 0x5A53                             ; FB2924  ld WA,0x5a53
	add	wa, bc                                 ; FB2927  add WA,BC
	ld	(xiz-18), wa                            ; FB2929  ld (XIZ+0xee),WA
	ld	c, (xiz-10)                             ; FB292C  ld C,(XIZ+0xf6)
	sll	c, 6                                   ; FB292F  sll 0x06,C
	set	4, c                                   ; FB2932  set 0x04,C
	extz	bc                                    ; FB2935  extz BC
	ld	wa, (xiz-18)                            ; FB2937  ld WA,(XIZ+0xee)
	extz	xwa                                   ; FB293A  extz XWA
	ld	(xwa+1), bc                             ; FB293C  ld (XWA+0x01),BC
	ld	bc, (xiz-18)                            ; FB293F  ld BC,(XIZ+0xee)
	extz	xbc                                   ; FB2942  extz XBC
	ld	(xbc+3), e                              ; FB2944  ld (XBC+0x03),E
	ld	bc, (xiz-18)                            ; FB2947  ld BC,(XIZ+0xee)
	extz	xbc                                   ; FB294A  extz XBC
	ld	(xbc+4), d                              ; FB294C  ld (XBC+0x04),D
	ld	c, (xiz+18)                             ; FB294F  ld C,(XIZ+0x12)
	set	7, c                                   ; FB2952  set 0x07,C
	ld	(xiz-20), c                             ; FB2955  ld (XIZ+0xec),C
	ld	bc, (xiz-18)                            ; FB2958  ld BC,(XIZ+0xee)
	extz	xbc                                   ; FB295B  extz XBC
	ld	a, (xiz-20)                             ; FB295D  ld A,(XIZ+0xec)
	ld	(xbc+5), a                              ; FB2960  ld (XBC+0x05),A
	ld	c, (xiz+20)                             ; FB2963  ld C,(XIZ+0x14)
	res	7, c                                   ; FB2966  res 0x07,C
	ld	(xiz-22), c                             ; FB2969  ld (XIZ+0xea),C
	ld	bc, (xiz-18)                            ; FB296C  ld BC,(XIZ+0xee)
	extz	xbc                                   ; FB296F  extz XBC
	ld	a, (xiz-22)                             ; FB2971  ld A,(XIZ+0xea)
	ld	(xbc+12), a                             ; FB2974  ld (XBC+0x0c),A
	ldw	bc, 0x1523                             ; FB2977  ld BC,0x1523
	ld	(xiz-24), bc                            ; FB297A  ld (XIZ+0xe8),BC
	add	bc, hl                                 ; FB297D  add BC,HL
	ld	wa, (xiz-18)                            ; FB297F  ld WA,(XIZ+0xee)
	extz	xwa                                   ; FB2982  extz XWA
	ld	(xwa+35), bc                            ; FB2984  ld (XWA+0x23),BC
	ldb	c, 41                                  ; FB2987  ld C,0x29
	mul8rr	c, e                                ; FB2989  mul BC,E
	add	bc, hl                                 ; FB298B  add BC,HL
	add	bc, 0x88                               ; FB298D  add BC,0x0088
	extpfx3 0x9E, 0xE8, 0x81                   ; FB2991  add BC,(XIZ+0xe8)
	ld	wa, (xiz-18)                            ; FB2994  ld WA,(XIZ+0xee)
	extz	xwa                                   ; FB2997  extz XWA
	ld	(xwa+37), bc                            ; FB2999  ld (XWA+0x25),BC
	ld	bc, (xiz-18)                            ; FB299C  ld BC,(XIZ+0xee)
	extz	xbc                                   ; FB299F  extz XBC
	ld	xwa, (xiz-8)                            ; FB29A1  ld XWA,(XIZ+0xf8)
	ld	(xbc+19), xwa                           ; FB29A4  ld (XBC+0x13),XWA
	ld	bc, (xiz-18)                            ; FB29A7  ld BC,(XIZ+0xee)
	extz	xbc                                   ; FB29AA  extz XBC
	ld	xwa, (xiz-4)                            ; FB29AC  ld XWA,(XIZ+0xfc)
	ld	(xbc+23), xwa                           ; FB29AF  ld (XBC+0x17),XWA
	ld	bc, (xiz-18)                            ; FB29B2  ld BC,(XIZ+0xee)
	extz	xbc                                   ; FB29B5  extz XBC
	ld	(xbc+27), xix                           ; FB29B7  ld (XBC+0x1b),XIX
	ld	bc, (xiz-18)                            ; FB29BA  ld BC,(XIZ+0xee)
	extz	xbc                                   ; FB29BD  extz XBC
	ld	xwa, (xiz-14)                           ; FB29BF  ld XWA,(XIZ+0xf2)
	ld	(xbc+31), xwa                           ; FB29C2  ld (XBC+0x1f),XWA
	extpfx3 0x9E, 0xEE, 0x04                   ; FB29C5  pushw (XIZ+0xee)
	call	0xFA814C                              ; FB29C8  call 0xfa814c
	ld	bc, (xiz-18)                            ; FB29CC  ld BC,(XIZ+0xee)
	extz	xbc                                   ; FB29CF  extz XBC
	extpfx5 0xB9, 0x2B, 0x02, 0x00, 0x00       ; FB29D1  ld (XBC+0x2b),0x0000
	ld	bc, (xiz-18)                            ; FB29D6  ld BC,(XIZ+0xee)
	extz	xbc                                   ; FB29D9  extz XBC
	extpfx5 0xB9, 0x2D, 0x02, 0xFF, 0x00       ; FB29DB  ld (XBC+0x2d),0x00ff
	ld	bc, (xiz-18)                            ; FB29E0  ld BC,(XIZ+0xee)
	extz	xbc                                   ; FB29E3  extz XBC
	ld	(xbc+49), 0                             ; FB29E5  ld (XBC+0x31),0x00
	ld	bc, (xiz-18)                            ; FB29E9  ld BC,(XIZ+0xee)
	extz	xbc                                   ; FB29EC  extz XBC
	extpfx5 0xB9, 0x32, 0x02, 0x00, 0x00       ; FB29EE  ld (XBC+0x32),0x0000
	ld	bc, (xiz-18)                            ; FB29F3  ld BC,(XIZ+0xee)
	extz	xbc                                   ; FB29F6  extz XBC
	extpfx5 0xB9, 0x36, 0x02, 0x00, 0x00       ; FB29F8  ld (XBC+0x36),0x0000
	ld	bc, (xiz-18)                            ; FB29FD  ld BC,(XIZ+0xee)
	extz	xbc                                   ; FB2A00  extz XBC
	extpfx5 0xB9, 0x34, 0x02, 0x00, 0x00       ; FB2A02  ld (XBC+0x34),0x0000
	pushw	1                                    ; FB2A07  push 0x0001
	push	xix                                   ; FB2A0A  push XIX
	pushw	de                                   ; FB2A0B  push DE
	push	0                                     ; FB2A0C  push 0x00
	push	d                                     ; FB2A0E  push D
	call	0xFC6803                              ; FB2A10  call 0xfc6803
	ld	h, (xiz+22)                             ; FB2A14  ld H,(XIZ+0x16)
	set	7, h                                   ; FB2A17  set 0x07,H
	ld	c, e                                    ; FB2A1A  ld C,E
	extz	bc                                    ; FB2A1C  extz BC
	extz	xbc                                   ; FB2A1E  extz XBC
	ld	(xiz-28), xbc                           ; FB2A20  ld (XIZ+0xe4),XBC
	inc	2, xbc                                 ; FB2A23  inc 2,XBC
	extpfx3 0xAE, 0x08, 0x81                   ; FB2A25  add XBC,(XIZ+0x08)
	ld	(xbc), h                                ; FB2A28  ld (XBC),H
	ld	bc, (xiz-18)                            ; FB2A2A  ld BC,(XIZ+0xee)
	extz	xbc                                   ; FB2A2D  extz XBC
	ld	wa, (xbc+6)                             ; FB2A2F  ld WA,(XBC+0x06)
	pushw	wa                                   ; FB2A32  push WA
	ld	wa, (xbc+8)                             ; FB2A33  ld WA,(XBC+0x08)
	pushw	wa                                   ; FB2A36  push WA
	pushw	de                                   ; FB2A37  push DE
	push	0                                     ; FB2A38  push 0x00
	push	d                                     ; FB2A3A  push D
	call	0xFC4B2E                              ; FB2A3C  call 0xfc4b2e
	ld	h, a                                    ; FB2A40  ld H,A
	ld	xix, (xiz-28)                           ; FB2A42  ld XIX,(XIZ+0xe4)
	inc	6, xix                                 ; FB2A45  inc 6,XIX
	add	xsp, 32                                ; FB2A47  add XSP,0x00000020
	cps	a, 0                                   ; FB2A4D  cp A,0
	jr z, sub_FB289A__FB2A5B                   ; FB2A4F  jr Z,0xfb2a5b
	ld	xbc, (xiz+8)                            ; FB2A51  ld XBC,(XIZ+0x08)
	add	xbc, xix                               ; FB2A54  add XBC,XIX
	ld	(xbc), 32                               ; FB2A56  ld (XBC),0x20
	jr sub_FB289A__FB2A92                      ; FB2A59  jr T,0xfb2a92
sub_FB289A__FB2A5B:
	ld	xbc, (xiz+8)                            ; FB2A5B  ld XBC,(XIZ+0x08)
	add	xbc, xix                               ; FB2A5E  add XBC,XIX
	ld	(xbc), 0                                ; FB2A60  ld (XBC),0x00
	jr sub_FB289A__FB2A92                      ; FB2A63  jr T,0xfb2a92
sub_FB289A__FB2A65:
	ld	c, e                                    ; FB2A65  ld C,E
	extz	bc                                    ; FB2A67  extz BC
	extz	xbc                                   ; FB2A69  extz XBC
	ld	(xiz-12), xbc                           ; FB2A6B  ld (XIZ+0xf4),XBC
	inc	2, xbc                                 ; FB2A6E  inc 2,XBC
	extpfx3 0xAE, 0x08, 0x81                   ; FB2A70  add XBC,(XIZ+0x08)
	ld	(xbc), 0                                ; FB2A73  ld (XBC),0x00
	ld	xbc, (xiz-12)                           ; FB2A76  ld XBC,(XIZ+0xf4)
	inc	6, xbc                                 ; FB2A79  inc 6,XBC
	extpfx3 0xAE, 0x08, 0x81                   ; FB2A7B  add XBC,(XIZ+0x08)
	ld	(xbc), 0                                ; FB2A7E  ld (XBC),0x00
	pushw	0                                    ; FB2A81  push 0x0000
	push	xix                                   ; FB2A84  push XIX
	pushw	de                                   ; FB2A85  push DE
	push	0                                     ; FB2A86  push 0x00
	push	d                                     ; FB2A88  push D
	call	0xFC6803                              ; FB2A8A  call 0xfc6803
	inc	8, xsp                                 ; FB2A8E  inc 0,XSP
	inc	2, xsp                                 ; FB2A90  inc 2,XSP
sub_FB289A__FB2A92:
	pop	xix                                    ; FB2A92  pop XIX
	popw	de                                    ; FB2A93  pop DE
	popw	hl                                    ; FB2A94  pop HL
	unlk32 xiz                                 ; FB2A95  unlk XIZ
	ret                                        ; FB2A97  ret
; ------------------------------------------------------------------------------
; VoiceParams_Compute_C -- 0xFB2A98..0xFB2EB6 (1055 bytes)
;
; Called from: one site, `calr 0xFB2A98` at 0xFB3B01, in MidiNote_OnByPartMode's
;          part-mode 0x80 arm.
; Evidence: the subset relation with sub_FB289A above, plus the same three extra
;          callees the other _Compute_ routines have and their short twins do not:
;          MemCopyWords (0xF9A038), 0xFA6BB5 and 0xFC376C.
; Unknown:  ⚠ the formulae.
VoiceParams_Compute_C:
	link32 0xEE, 0x0C, 0xF0, 0xFF              ; FB2A98  link XIZ,0xfff0
	pushw	hl                                   ; FB2A9C  push HL
	pushw	de                                   ; FB2A9D  push DE
	push	xix                                   ; FB2A9E  push XIX
	ld	de, (xiz+12)                            ; FB2A9F  ld DE,(XIZ+0x0c)
	extz	de                                    ; FB2AA2  extz DE
	ld	bc, de                                  ; FB2AA4  ld BC,DE
	sll	bc, 8                                  ; FB2AA6  sll 0x08,BC
	ld	(xiz-10), bc                            ; FB2AA9  ld (XIZ+0xf6),BC
	ld	wa, (xiz+14)                            ; FB2AAC  ld WA,(XIZ+0x0e)
	extz	wa                                    ; FB2AAF  extz WA
	or	bc, wa                                  ; FB2AB1  or BC,WA
	set	7, bc                                  ; FB2AB3  set 0x07,BC
	ld	xwa, (xiz+8)                            ; FB2AB6  ld XWA,(XIZ+0x08)
	ld	(xwa), bc                               ; FB2AB9  ld (XWA),BC
	ldw	bc, 0x12C                              ; FB2ABB  ld BC,0x012c
	mul	xbc, xde                               ; FB2ABE  mul XBC,DE
	ld	hl, bc                                  ; FB2AC0  ld HL,BC
	extz	xbc                                   ; FB2AC2  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB2AC4  ld XWA,(XBC+0x1523)
	ld	(xiz-14), xwa                           ; FB2AC9  ld (XIZ+0xf2),XWA
	push	0                                     ; FB2ACC  push 0x00
	extpfx3 0x8E, 0x0E, 0x04                   ; FB2ACE  push (XIZ+0x0e)
	push	xwa                                   ; FB2AD1  push XWA
	push	0                                     ; FB2AD2  push 0x00
	extpfx3 0x8E, 0x0C, 0x04                   ; FB2AD4  push (XIZ+0x0c)
	call	0xFB49EB                              ; FB2AD7  call 0xfb49eb
	ld	(xiz-8), xiy                            ; FB2ADB  ld (XIZ+0xf8),XIY
	add	xiy, 18                                ; FB2ADE  add XIY,0x00000012
	ld	(xiz-4), xiy                            ; FB2AE4  ld (XIZ+0xfc),XIY
	push	0                                     ; FB2AE7  push 0x00
	extpfx3 0x8E, 0x0E, 0x04                   ; FB2AE9  push (XIZ+0x0e)
	ld	xbc, (xiz-8)                            ; FB2AEC  ld XBC,(XIZ+0xf8)
	push	xbc                                   ; FB2AEF  push XBC
	pushw	0                                    ; FB2AF0  push 0x0000
	push	0                                     ; FB2AF3  push 0x00
	extpfx3 0x8E, 0x0C, 0x04                   ; FB2AF5  push (XIZ+0x0c)
	call	0xFB456F                              ; FB2AF8  call 0xfb456f
	ld	xix, xiy                                ; FB2AFC  ld XIX,XIY
	ld	xbc, (xiz-8)                            ; FB2AFE  ld XBC,(XIZ+0xf8)
	ld	a, (xbc+13)                             ; FB2B01  ld A,(XBC+0x0d)
	extz	wa                                    ; FB2B04  extz WA
	and	wa, 1                                  ; FB2B06  and WA,0x0001
	add	xsp, 18                                ; FB2B0A  add XSP,0x00000012
	cps	wa, 0                                  ; FB2B10  cp WA,0
	jrl z, VoiceParams_Compute_C__FB2C4B       ; FB2B12  jrl Z,0xfb2c4b
	push	xiy                                   ; FB2B15  push XIY
	push	0                                     ; FB2B16  push 0x00
	extpfx3 0x8E, 0x10, 0x04                   ; FB2B18  push (XIZ+0x10)
	call	0xFA72B3                              ; FB2B1B  call 0xfa72b3
	ld	d, a                                    ; FB2B1F  ld D,A
	push	xix                                   ; FB2B21  push XIX
	pushw	wa                                   ; FB2B22  push WA
	call	0xFB474E                              ; FB2B23  call 0xfb474e
	ld	(xiz-12), xiy                           ; FB2B27  ld (XIZ+0xf4),XIY
	ldw	bc, 0x5A53                             ; FB2B2A  ld BC,0x5a53
	ld	(xiz-14), bc                            ; FB2B2D  ld (XIZ+0xf2),BC
	ld	w, d                                    ; FB2B30  ld W,D
	sll	w, 6                                   ; FB2B32  sll 0x06,W
	set	4, w                                   ; FB2B35  set 0x04,W
	ld	a, w                                    ; FB2B38  ld A,W
	extz	wa                                    ; FB2B3A  extz WA
	extz	xbc                                   ; FB2B3C  extz XBC
	ld	(xbc+1), wa                             ; FB2B3E  ld (XBC+0x01),WA
	ld	bc, (xiz-14)                            ; FB2B41  ld BC,(XIZ+0xf2)
	extz	xbc                                   ; FB2B44  extz XBC
	ld	(xbc+3), 0                              ; FB2B46  ld (XBC+0x03),0x00
	ld	bc, (xiz-14)                            ; FB2B4A  ld BC,(XIZ+0xf2)
	extz	xbc                                   ; FB2B4D  extz XBC
	ld	a, (xiz+12)                             ; FB2B4F  ld A,(XIZ+0x0c)
	ld	(xbc+4), a                              ; FB2B52  ld (XBC+0x04),A
	ld	c, (xiz+14)                             ; FB2B55  ld C,(XIZ+0x0e)
	set	7, c                                   ; FB2B58  set 0x07,C
	ld	d, c                                    ; FB2B5B  ld D,C
	ld	bc, (xiz-14)                            ; FB2B5D  ld BC,(XIZ+0xf2)
	extz	xbc                                   ; FB2B60  extz XBC
	ld	(xbc+5), d                              ; FB2B62  ld (XBC+0x05),D
	ld	c, (xiz+16)                             ; FB2B65  ld C,(XIZ+0x10)
	res	7, c                                   ; FB2B68  res 0x07,C
	ld	d, c                                    ; FB2B6B  ld D,C
	ld	bc, (xiz-14)                            ; FB2B6D  ld BC,(XIZ+0xf2)
	extz	xbc                                   ; FB2B70  extz XBC
	ld	(xbc+12), d                             ; FB2B72  ld (XBC+0x0c),D
	ldw	de, 0x1523                             ; FB2B75  ld DE,0x1523
	ld	bc, de                                  ; FB2B78  ld BC,DE
	add	bc, hl                                 ; FB2B7A  add BC,HL
	ld	wa, (xiz-14)                            ; FB2B7C  ld WA,(XIZ+0xf2)
	extz	xwa                                   ; FB2B7F  extz XWA
	ld	(xwa+35), bc                            ; FB2B81  ld (XWA+0x23),BC
	ld	bc, hl                                  ; FB2B84  ld BC,HL
	add	bc, 0x88                               ; FB2B86  add BC,0x0088
	add	bc, de                                 ; FB2B8A  add BC,DE
	ld	wa, (xiz-14)                            ; FB2B8C  ld WA,(XIZ+0xf2)
	extz	xwa                                   ; FB2B8F  extz XWA
	ld	(xwa+37), bc                            ; FB2B91  ld (XWA+0x25),BC
	ld	bc, (xiz-14)                            ; FB2B94  ld BC,(XIZ+0xf2)
	extz	xbc                                   ; FB2B97  extz XBC
	ld	xwa, (xiz-8)                            ; FB2B99  ld XWA,(XIZ+0xf8)
	ld	(xbc+19), xwa                           ; FB2B9C  ld (XBC+0x13),XWA
	ld	bc, (xiz-14)                            ; FB2B9F  ld BC,(XIZ+0xf2)
	extz	xbc                                   ; FB2BA2  extz XBC
	ld	xwa, (xiz-4)                            ; FB2BA4  ld XWA,(XIZ+0xfc)
	ld	(xbc+23), xwa                           ; FB2BA7  ld (XBC+0x17),XWA
	ld	bc, (xiz-14)                            ; FB2BAA  ld BC,(XIZ+0xf2)
	extz	xbc                                   ; FB2BAD  extz XBC
	ld	(xbc+27), xix                           ; FB2BAF  ld (XBC+0x1b),XIX
	ld	bc, (xiz-14)                            ; FB2BB2  ld BC,(XIZ+0xf2)
	extz	xbc                                   ; FB2BB5  extz XBC
	ld	xwa, (xiz-12)                           ; FB2BB7  ld XWA,(XIZ+0xf4)
	ld	(xbc+31), xwa                           ; FB2BBA  ld (XBC+0x1f),XWA
	extpfx3 0x9E, 0xF2, 0x04                   ; FB2BBD  pushw (XIZ+0xf2)
	call	0xFA814C                              ; FB2BC0  call 0xfa814c
	ld	bc, (xiz-14)                            ; FB2BC4  ld BC,(XIZ+0xf2)
	extz	xbc                                   ; FB2BC7  extz XBC
	extpfx5 0xB9, 0x2B, 0x02, 0x00, 0x00       ; FB2BC9  ld (XBC+0x2b),0x0000
	ld	bc, (xiz-14)                            ; FB2BCE  ld BC,(XIZ+0xf2)
	extz	xbc                                   ; FB2BD1  extz XBC
	extpfx5 0xB9, 0x2D, 0x02, 0xFF, 0x00       ; FB2BD3  ld (XBC+0x2d),0x00ff
	ld	bc, (xiz-14)                            ; FB2BD8  ld BC,(XIZ+0xf2)
	extz	xbc                                   ; FB2BDB  extz XBC
	ld	(xbc+49), 0                             ; FB2BDD  ld (XBC+0x31),0x00
	ld	bc, (xiz-14)                            ; FB2BE1  ld BC,(XIZ+0xf2)
	extz	xbc                                   ; FB2BE4  extz XBC
	extpfx5 0xB9, 0x32, 0x02, 0x00, 0x00       ; FB2BE6  ld (XBC+0x32),0x0000
	ld	bc, (xiz-14)                            ; FB2BEB  ld BC,(XIZ+0xf2)
	extz	xbc                                   ; FB2BEE  extz XBC
	extpfx5 0xB9, 0x36, 0x02, 0x00, 0x00       ; FB2BF0  ld (XBC+0x36),0x0000
	ld	bc, (xiz-14)                            ; FB2BF5  ld BC,(XIZ+0xf2)
	extz	xbc                                   ; FB2BF8  extz XBC
	extpfx5 0xB9, 0x34, 0x02, 0x00, 0x00       ; FB2BFA  ld (XBC+0x34),0x0000
	pushw	1                                    ; FB2BFF  push 0x0001
	push	xix                                   ; FB2C02  push XIX
	pushw	0                                    ; FB2C03  push 0x0000
	push	0                                     ; FB2C06  push 0x00
	extpfx3 0x8E, 0x0C, 0x04                   ; FB2C08  push (XIZ+0x0c)
	call	0xFC6803                              ; FB2C0B  call 0xfc6803
	ld	xbc, (xiz+8)                            ; FB2C0F  ld XBC,(XIZ+0x08)
	ld	(xbc+2), 0x80                           ; FB2C12  ld (XBC+0x02),0x80
	ld	bc, (xiz-14)                            ; FB2C16  ld BC,(XIZ+0xf2)
	extz	xbc                                   ; FB2C19  extz XBC
	ld	wa, (xbc+6)                             ; FB2C1B  ld WA,(XBC+0x06)
	pushw	wa                                   ; FB2C1E  push WA
	ld	wa, (xbc+8)                             ; FB2C1F  ld WA,(XBC+0x08)
	pushw	wa                                   ; FB2C22  push WA
	pushw	0                                    ; FB2C23  push 0x0000
	push	0                                     ; FB2C26  push 0x00
	extpfx3 0x8E, 0x0C, 0x04                   ; FB2C28  push (XIZ+0x0c)
	call	0xFC4B2E                              ; FB2C2B  call 0xfc4b2e
	add	xsp, 32                                ; FB2C2F  add XSP,0x00000020
	cps	a, 0                                   ; FB2C35  cp A,0
	jr z, VoiceParams_Compute_C__FB2C42        ; FB2C37  jr Z,0xfb2c42
	ld	xbc, (xiz+8)                            ; FB2C39  ld XBC,(XIZ+0x08)
	ld	(xbc+6), 32                             ; FB2C3C  ld (XBC+0x06),0x20
	jr VoiceParams_Compute_C__FB2C6D           ; FB2C40  jr T,0xfb2c6d
VoiceParams_Compute_C__FB2C42:
	ld	xbc, (xiz+8)                            ; FB2C42  ld XBC,(XIZ+0x08)
	ld	(xbc+6), 0                              ; FB2C45  ld (XBC+0x06),0x00
	jr VoiceParams_Compute_C__FB2C6D           ; FB2C49  jr T,0xfb2c6d
VoiceParams_Compute_C__FB2C4B:
	ld	xbc, (xiz+8)                            ; FB2C4B  ld XBC,(XIZ+0x08)
	ld	(xbc+2), 0                              ; FB2C4E  ld (XBC+0x02),0x00
	ld	xbc, (xiz+8)                            ; FB2C52  ld XBC,(XIZ+0x08)
	ld	(xbc+6), 0                              ; FB2C55  ld (XBC+0x06),0x00
	pushw	0                                    ; FB2C59  push 0x0000
	push	xix                                   ; FB2C5C  push XIX
	pushw	0                                    ; FB2C5D  push 0x0000
	push	0                                     ; FB2C60  push 0x00
	extpfx3 0x8E, 0x0C, 0x04                   ; FB2C62  push (XIZ+0x0c)
	call	0xFC6803                              ; FB2C65  call 0xfc6803
	inc	8, xsp                                 ; FB2C69  inc 0,XSP
	inc	2, xsp                                 ; FB2C6B  inc 2,XSP
VoiceParams_Compute_C__FB2C6D:
	ld	bc, (xiz+12)                            ; FB2C6D  ld BC,(XIZ+0x0c)
	extz	bc                                    ; FB2C70  extz BC
	mul	bc, 0x12C                              ; FB2C72  mul BC,0x012c
	ld	hl, bc                                  ; FB2C76  ld HL,BC
	extz	xbc                                   ; FB2C78  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB2C7A  ld XWA,(XBC+0x1523)
	ld	(xiz-12), xwa                           ; FB2C7F  ld (XIZ+0xf4),XWA
	push	0                                     ; FB2C82  push 0x00
	extpfx3 0x8E, 0x0E, 0x04                   ; FB2C84  push (XIZ+0x0e)
	push	xwa                                   ; FB2C87  push XWA
	push	0                                     ; FB2C88  push 0x00
	extpfx3 0x8E, 0x0C, 0x04                   ; FB2C8A  push (XIZ+0x0c)
	call	0xFB49EB                              ; FB2C8D  call 0xfb49eb
	ld	(xiz-8), xiy                            ; FB2C91  ld (XIZ+0xf8),XIY
	add	xiy, 41                                ; FB2C94  add XIY,0x00000029
	ld	(xiz-4), xiy                            ; FB2C9A  ld (XIZ+0xfc),XIY
	push	0                                     ; FB2C9D  push 0x00
	extpfx3 0x8E, 0x0E, 0x04                   ; FB2C9F  push (XIZ+0x0e)
	ld	xbc, (xiz-8)                            ; FB2CA2  ld XBC,(XIZ+0xf8)
	push	xbc                                   ; FB2CA5  push XBC
	pushw	1                                    ; FB2CA6  push 0x0001
	push	0                                     ; FB2CA9  push 0x00
	extpfx3 0x8E, 0x0C, 0x04                   ; FB2CAB  push (XIZ+0x0c)
	call	0xFB456F                              ; FB2CAE  call 0xfb456f
	ld	xix, xiy                                ; FB2CB2  ld XIX,XIY
	ld	xbc, (xiz-8)                            ; FB2CB4  ld XBC,(XIZ+0xf8)
	ld	a, (xbc+13)                             ; FB2CB7  ld A,(XBC+0x0d)
	extz	wa                                    ; FB2CBA  extz WA
	and	wa, 4                                  ; FB2CBC  and WA,0x0004
	add	xsp, 18                                ; FB2CC0  add XSP,0x00000012
	cps	wa, 0                                  ; FB2CC6  cp WA,0
	jrl z, VoiceParams_Compute_C__FB2E0B       ; FB2CC8  jrl Z,0xfb2e0b
	push	xiy                                   ; FB2CCB  push XIY
	push	0                                     ; FB2CCC  push 0x00
	extpfx3 0x8E, 0x10, 0x04                   ; FB2CCE  push (XIZ+0x10)
	call	0xFA72B3                              ; FB2CD1  call 0xfa72b3
	ld	d, a                                    ; FB2CD5  ld D,A
	push	xix                                   ; FB2CD7  push XIX
	pushw	wa                                   ; FB2CD8  push WA
	call	0xFB474E                              ; FB2CD9  call 0xfb474e
	ld	(xiz-12), xiy                           ; FB2CDD  ld (XIZ+0xf4),XIY
	ldw	bc, 0x5A53                             ; FB2CE0  ld BC,0x5a53
	ld	(xiz-14), bc                            ; FB2CE3  ld (XIZ+0xf2),BC
	add	bc, 68                                 ; FB2CE6  add BC,0x0044
	ld	(xiz-16), bc                            ; FB2CEA  ld (XIZ+0xf0),BC
	ld	w, d                                    ; FB2CED  ld W,D
	sll	w, 6                                   ; FB2CEF  sll 0x06,W
	set	4, w                                   ; FB2CF2  set 0x04,W
	ld	a, w                                    ; FB2CF5  ld A,W
	extz	wa                                    ; FB2CF7  extz WA
	ld	bc, (xiz-14)                            ; FB2CF9  ld BC,(XIZ+0xf2)
	extz	xbc                                   ; FB2CFC  extz XBC
	ld	(xbc+69), wa                            ; FB2CFE  ld (XBC+0x45),WA
	ld	bc, (xiz-14)                            ; FB2D01  ld BC,(XIZ+0xf2)
	extz	xbc                                   ; FB2D04  extz XBC
	ld	(xbc+71), 1                             ; FB2D06  ld (XBC+0x47),0x01
	ld	bc, (xiz-14)                            ; FB2D0A  ld BC,(XIZ+0xf2)
	extz	xbc                                   ; FB2D0D  extz XBC
	ld	a, (xiz+12)                             ; FB2D0F  ld A,(XIZ+0x0c)
	ld	(xbc+72), a                             ; FB2D12  ld (XBC+0x48),A
	ld	c, (xiz+14)                             ; FB2D15  ld C,(XIZ+0x0e)
	set	7, c                                   ; FB2D18  set 0x07,C
	ld	d, c                                    ; FB2D1B  ld D,C
	ld	bc, (xiz-14)                            ; FB2D1D  ld BC,(XIZ+0xf2)
	extz	xbc                                   ; FB2D20  extz XBC
	ld	(xbc+73), d                             ; FB2D22  ld (XBC+0x49),D
	ld	c, (xiz+16)                             ; FB2D25  ld C,(XIZ+0x10)
	res	7, c                                   ; FB2D28  res 0x07,C
	ld	d, c                                    ; FB2D2B  ld D,C
	ld	bc, (xiz-14)                            ; FB2D2D  ld BC,(XIZ+0xf2)
	extz	xbc                                   ; FB2D30  extz XBC
	ld	(xbc+80), d                             ; FB2D32  ld (XBC+0x50),D
	ldw	de, 0x1523                             ; FB2D35  ld DE,0x1523
	ld	bc, de                                  ; FB2D38  ld BC,DE
	add	bc, hl                                 ; FB2D3A  add BC,HL
	ld	wa, (xiz-14)                            ; FB2D3C  ld WA,(XIZ+0xf2)
	extz	xwa                                   ; FB2D3F  extz XWA
	ld	(xwa+0x67), bc                          ; FB2D41  ld (XWA+0x67),BC
	ld	bc, hl                                  ; FB2D44  ld BC,HL
	add	bc, 0xB1                               ; FB2D46  add BC,0x00b1
	add	bc, de                                 ; FB2D4A  add BC,DE
	ld	wa, (xiz-14)                            ; FB2D4C  ld WA,(XIZ+0xf2)
	extz	xwa                                   ; FB2D4F  extz XWA
	ld	(xwa+0x69), bc                          ; FB2D51  ld (XWA+0x69),BC
	ld	bc, (xiz-14)                            ; FB2D54  ld BC,(XIZ+0xf2)
	extz	xbc                                   ; FB2D57  extz XBC
	ld	xwa, (xiz-8)                            ; FB2D59  ld XWA,(XIZ+0xf8)
	ld	(xbc+87), xwa                           ; FB2D5C  ld (XBC+0x57),XWA
	ld	bc, (xiz-14)                            ; FB2D5F  ld BC,(XIZ+0xf2)
	extz	xbc                                   ; FB2D62  extz XBC
	ld	xwa, (xiz-4)                            ; FB2D64  ld XWA,(XIZ+0xfc)
	ld	(xbc+91), xwa                           ; FB2D67  ld (XBC+0x5b),XWA
	ld	bc, (xiz-14)                            ; FB2D6A  ld BC,(XIZ+0xf2)
	extz	xbc                                   ; FB2D6D  extz XBC
	ld	(xbc+95), xix                           ; FB2D6F  ld (XBC+0x5f),XIX
	ld	bc, (xiz-14)                            ; FB2D72  ld BC,(XIZ+0xf2)
	extz	xbc                                   ; FB2D75  extz XBC
	ld	xwa, (xiz-12)                           ; FB2D77  ld XWA,(XIZ+0xf4)
	ld	(xbc+99), xwa                           ; FB2D7A  ld (XBC+0x63),XWA
	extpfx3 0x9E, 0xF0, 0x04                   ; FB2D7D  pushw (XIZ+0xf0)
	call	0xFA814C                              ; FB2D80  call 0xfa814c
	ld	bc, (xiz-14)                            ; FB2D84  ld BC,(XIZ+0xf2)
	extz	xbc                                   ; FB2D87  extz XBC
	extpfx5 0xB9, 0x6F, 0x02, 0x00, 0x00       ; FB2D89  ld (XBC+0x6f),0x0000
	ld	bc, (xiz-14)                            ; FB2D8E  ld BC,(XIZ+0xf2)
	extz	xbc                                   ; FB2D91  extz XBC
	extpfx5 0xB9, 0x71, 0x02, 0xFF, 0x00       ; FB2D93  ld (XBC+0x71),0x00ff
	ld	bc, (xiz-14)                            ; FB2D98  ld BC,(XIZ+0xf2)
	extz	xbc                                   ; FB2D9B  extz XBC
	ld	(xbc+0x75), 0                           ; FB2D9D  ld (XBC+0x75),0x00
	ld	bc, (xiz-14)                            ; FB2DA1  ld BC,(XIZ+0xf2)
	extz	xbc                                   ; FB2DA4  extz XBC
	extpfx5 0xB9, 0x76, 0x02, 0x00, 0x00       ; FB2DA6  ld (XBC+0x76),0x0000
	ld	bc, (xiz-14)                            ; FB2DAB  ld BC,(XIZ+0xf2)
	extz	xbc                                   ; FB2DAE  extz XBC
	extpfx5 0xB9, 0x7A, 0x02, 0x00, 0x00       ; FB2DB0  ld (XBC+0x7a),0x0000
	ld	bc, (xiz-14)                            ; FB2DB5  ld BC,(XIZ+0xf2)
	extz	xbc                                   ; FB2DB8  extz XBC
	extpfx5 0xB9, 0x78, 0x02, 0x00, 0x00       ; FB2DBA  ld (XBC+0x78),0x0000
	pushw	1                                    ; FB2DBF  push 0x0001
	push	xix                                   ; FB2DC2  push XIX
	pushw	1                                    ; FB2DC3  push 0x0001
	push	0                                     ; FB2DC6  push 0x00
	extpfx3 0x8E, 0x0C, 0x04                   ; FB2DC8  push (XIZ+0x0c)
	call	0xFC6803                              ; FB2DCB  call 0xfc6803
	ld	xbc, (xiz+8)                            ; FB2DCF  ld XBC,(XIZ+0x08)
	ld	(xbc+3), 0x81                           ; FB2DD2  ld (XBC+0x03),0x81
	ld	bc, (xiz-14)                            ; FB2DD6  ld BC,(XIZ+0xf2)
	extz	xbc                                   ; FB2DD9  extz XBC
	ld	wa, (xbc+74)                            ; FB2DDB  ld WA,(XBC+0x4a)
	pushw	wa                                   ; FB2DDE  push WA
	ld	wa, (xbc+76)                            ; FB2DDF  ld WA,(XBC+0x4c)
	pushw	wa                                   ; FB2DE2  push WA
	pushw	1                                    ; FB2DE3  push 0x0001
	push	0                                     ; FB2DE6  push 0x00
	extpfx3 0x8E, 0x0C, 0x04                   ; FB2DE8  push (XIZ+0x0c)
	call	0xFC4B2E                              ; FB2DEB  call 0xfc4b2e
	add	xsp, 32                                ; FB2DEF  add XSP,0x00000020
	cps	a, 0                                   ; FB2DF5  cp A,0
	jr z, VoiceParams_Compute_C__FB2E02        ; FB2DF7  jr Z,0xfb2e02
	ld	xbc, (xiz+8)                            ; FB2DF9  ld XBC,(XIZ+0x08)
	ld	(xbc+7), 32                             ; FB2DFC  ld (XBC+0x07),0x20
	jr VoiceParams_Compute_C__FB2E2D           ; FB2E00  jr T,0xfb2e2d
VoiceParams_Compute_C__FB2E02:
	ld	xbc, (xiz+8)                            ; FB2E02  ld XBC,(XIZ+0x08)
	ld	(xbc+7), 0                              ; FB2E05  ld (XBC+0x07),0x00
	jr VoiceParams_Compute_C__FB2E2D           ; FB2E09  jr T,0xfb2e2d
VoiceParams_Compute_C__FB2E0B:
	ld	xbc, (xiz+8)                            ; FB2E0B  ld XBC,(XIZ+0x08)
	ld	(xbc+3), 0                              ; FB2E0E  ld (XBC+0x03),0x00
	ld	xbc, (xiz+8)                            ; FB2E12  ld XBC,(XIZ+0x08)
	ld	(xbc+7), 0                              ; FB2E15  ld (XBC+0x07),0x00
	pushw	0                                    ; FB2E19  push 0x0000
	push	xix                                   ; FB2E1C  push XIX
	pushw	1                                    ; FB2E1D  push 0x0001
	push	0                                     ; FB2E20  push 0x00
	extpfx3 0x8E, 0x0C, 0x04                   ; FB2E22  push (XIZ+0x0c)
	call	0xFC6803                              ; FB2E25  call 0xfc6803
	inc	8, xsp                                 ; FB2E29  inc 0,XSP
	inc	2, xsp                                 ; FB2E2B  inc 2,XSP
VoiceParams_Compute_C__FB2E2D:
	ld	xbc, (xiz+8)                            ; FB2E2D  ld XBC,(XIZ+0x08)
	ld	(xbc+4), 0                              ; FB2E30  ld (XBC+0x04),0x00
	ld	xbc, (xiz+8)                            ; FB2E34  ld XBC,(XIZ+0x08)
	ld	(xbc+8), 0                              ; FB2E37  ld (XBC+0x08),0x00
	ld	xbc, (xiz+8)                            ; FB2E3B  ld XBC,(XIZ+0x08)
	ld	(xbc+5), 0                              ; FB2E3E  ld (XBC+0x05),0x00
	ld	xbc, (xiz+8)                            ; FB2E42  ld XBC,(XIZ+0x08)
	ld	(xbc+9), 0                              ; FB2E45  ld (XBC+0x09),0x00
	ld	xbc, (xiz+8)                            ; FB2E49  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FB2E4C  push XBC
	call	0xFA6BB5                              ; FB2E4D  call 0xfa6bb5
	ld	xix, 10                                 ; FB2E51  ld XIX,0x0000000a
	ldw	de, 0                                  ; FB2E56  ld DE,0x0000
	ldb	l, 2                                   ; FB2E59  ld L,0x02
	pop	xiy                                    ; FB2E5B  pop XIY
VoiceParams_Compute_C__FB2E5C:
	ld	xbc, (xiz+8)                            ; FB2E5C  ld XBC,(XIZ+0x08)
	add	xbc, xix                               ; FB2E5F  add XBC,XIX
	ld	h, (xbc)                                ; FB2E61  ld H,(XBC)
	cp	h, 64                                   ; FB2E63  cp H,0x40
	jr nc, VoiceParams_Compute_C__FB2EA5       ; FB2E66  jr NC,0xfb2ea5
	pushw	68                                   ; FB2E68  push 0x0044
	ldb	c, 68                                  ; FB2E6B  ld C,0x44
	mul8rr	c, h                                ; FB2E6D  mul BC,H
	ld	(xiz-10), bc                            ; FB2E6F  ld (XIZ+0xf6),BC
	ldw	wa, 0x3BCF                             ; FB2E72  ld WA,0x3bcf
	add	wa, bc                                 ; FB2E75  add WA,BC
	extz	xwa                                   ; FB2E77  extz XWA
	push	xwa                                   ; FB2E79  push XWA
	ld	(xiz-12), de                            ; FB2E7A  ld (XIZ+0xf4),DE
	ldw	wa, 0x5A53                             ; FB2E7D  ld WA,0x5a53
	extpfx3 0x9E, 0xF4, 0x80                   ; FB2E80  add WA,(XIZ+0xf4)
	extz	xwa                                   ; FB2E83  extz XWA
	push	xwa                                   ; FB2E85  push XWA
	call	0xF9A038                              ; FB2E86  call 0xf9a038
	ld	bc, (xiz-10)                            ; FB2E8A  ld BC,(XIZ+0xf6)
	extz	xbc                                   ; FB2E8D  extz XBC
	ld	(xbc+0x3BCF), h                         ; FB2E8F  ld (XBC+0x3bcf),H
	push	0                                     ; FB2E94  push 0x00
	push	h                                     ; FB2E96  push H
	push	0                                     ; FB2E98  push 0x00
	extpfx3 0x8E, 0x0C, 0x04                   ; FB2E9A  push (XIZ+0x0c)
	call	0xFC376C                              ; FB2E9D  call 0xfc376c
	inc	8, xsp                                 ; FB2EA1  inc 0,XSP
	inc	6, xsp                                 ; FB2EA3  inc 6,XSP
VoiceParams_Compute_C__FB2EA5:
	inc	1, xix                                 ; FB2EA5  inc 1,XIX
	add	de, 68                                 ; FB2EA7  add DE,0x0044
	dec	1, l                                   ; FB2EAB  dec 1,L
	cps	l, 0                                   ; FB2EAD  cp L,0
	jr nz, VoiceParams_Compute_C__FB2E5C       ; FB2EAF  jr NZ,0xfb2e5c
	pop	xix                                    ; FB2EB1  pop XIX
	popw	de                                    ; FB2EB2  pop DE
	popw	hl                                    ; FB2EB3  pop HL
	unlk32 xiz                                 ; FB2EB4  unlk XIZ
	ret                                        ; FB2EB6  ret
; ------------------------------------------------------------------------------
; VoiceRegs_Stage_D -- 0xFB2EB7..0xFB2F73 (189 bytes)
;
; Called from: TWO sites, `calr 0xFB2EB7` at 0xFB3703 (inside MidiNote_OnTail) and
;          at 0xFB3810 (inside MidiNote_OffTail).
; Outputs: Dev104_WriteAllChanRegs at 0xFB2F4B, Dev10C_WriteAllChanRegs at
;          0xFB2F65.
; Voice record: touches voice_record[+0x03(r), +0x06(r), +0x08(r), +0x0A(r), +0x0C(r), +0x1F(r)] -- pointer built in place.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: 20 distinct call targets = VoiceRegs_Stage_C's eighteen plus exactly
;          0xFC35B8 and 0xFC369F (section 10 of the checker prints the difference
;          both ways, and the C-only direction is EMPTY).
; Unknown:  ⚠ the helpers.
VoiceRegs_Stage_D:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB2EB7  link XIZ,0x0000
	pushw	hl                                   ; FB2EBB  push HL
	push	xde                                   ; FB2EBC  push XDE
	ldb	c, 68                                  ; FB2EBD  ld C,0x44
	extpfx3 0x8E, 0x08, 0x43                   ; FB2EBF  mul BC,(XIZ+0x08)
	ld	hl, bc                                  ; FB2EC2  ld HL,BC
	ldw	wa, 0x3BCF                             ; FB2EC4  ld WA,0x3bcf
	ld	de, wa                                  ; FB2EC7  ld DE,WA
	add	de, bc                                 ; FB2EC9  add DE,BC
	extz	xde                                   ; FB2ECB  extz XDE
	ld	xbc, (xde+31)                           ; FB2ECD  ld XBC,(XDE+0x1f)
	ld	a, (xbc)                                ; FB2ED0  ld A,(XBC)
	pushw	wa                                   ; FB2ED2  push WA
	ld	c, (xde+12)                             ; FB2ED3  ld C,(XDE+0x0c)
	pushw	bc                                   ; FB2ED6  push BC
	ld	bc, (xde+8)                             ; FB2ED7  ld BC,(XDE+0x08)
	pushw	bc                                   ; FB2EDA  push BC
	ld	c, (xde+3)                              ; FB2EDB  ld C,(XDE+0x03)
	pushw	bc                                   ; FB2EDE  push BC
	call	0xFC4D63                              ; FB2EDF  call 0xfc4d63
	pushw	de                                   ; FB2EE3  push DE
	call	0xFC7F7A                              ; FB2EE4  call 0xfc7f7a
	pushw	de                                   ; FB2EE8  push DE
	call	0xFA819A                              ; FB2EE9  call 0xfa819a
	lda	xbc, (0xD75E:24)                       ; FB2EED  lda XBC,0x00d75e
	inc	2, xbc                                 ; FB2EF2  inc 2,XBC
	push	xbc                                   ; FB2EF4  push XBC
	call	0xFC369F                              ; FB2EF5  call 0xfc369f
	pushw	de                                   ; FB2EF9  push DE
	call	0xFA83A8                              ; FB2EFA  call 0xfa83a8
	pushw	de                                   ; FB2EFE  push DE
	call	0xFA83CC                              ; FB2EFF  call 0xfa83cc
	pushw	de                                   ; FB2F03  push DE
	call	0xFA900A                              ; FB2F04  call 0xfa900a
	pushw	de                                   ; FB2F08  push DE
	call	0xFA92A5                              ; FB2F09  call 0xfa92a5
	pushw	de                                   ; FB2F0D  push DE
	call	0xFAA1A5                              ; FB2F0E  call 0xfaa1a5
	pushw	de                                   ; FB2F12  push DE
	call	0xFAA3EB                              ; FB2F13  call 0xfaa3eb
	pushw	de                                   ; FB2F17  push DE
	call	0xFAA96C                              ; FB2F18  call 0xfaa96c
	pushw	0                                    ; FB2F1C  push 0x0000
	pushw	de                                   ; FB2F1F  push DE
	call	0xFAAC00                              ; FB2F20  call 0xfaac00
	pushw	de                                   ; FB2F24  push DE
	call	0xFA96F7                              ; FB2F25  call 0xfa96f7
	ld	bc, (xde+10)                            ; FB2F29  ld BC,(XDE+0x0a)
	pushw	bc                                   ; FB2F2C  push BC
	ld	bc, (xde+6)                             ; FB2F2D  ld BC,(XDE+0x06)
	pushw	bc                                   ; FB2F30  push BC
	call	0xFC4DA1                              ; FB2F31  call 0xfc4da1
	lda	xbc, (0xD7A2:24)                       ; FB2F35  lda XBC,0x00d7a2
	push	xbc                                   ; FB2F3A  push XBC
	call	0xFC4DBD                              ; FB2F3B  call 0xfc4dbd
	lda	xbc, (0xD7A2:24)                       ; FB2F3F  lda XBC,0x00d7a2
	push	xbc                                   ; FB2F44  push XBC
	ld	hl, (xiz+8)                             ; FB2F45  ld HL,(XIZ+0x08)
	extz	hl                                    ; FB2F48  extz HL
	pushw	hl                                   ; FB2F4A  push HL
	call	0xFB77EF                              ; FB2F4B  call 0xfb77ef
	pushw	de                                   ; FB2F4F  push DE
	call	0xFAB6D5                              ; FB2F50  call 0xfab6d5
	pushw	de                                   ; FB2F54  push DE
	call	0xFC35B8                              ; FB2F55  call 0xfc35b8
	pushw	de                                   ; FB2F59  push DE
	call	0xFAB7E0                              ; FB2F5A  call 0xfab7e0
	lda	xbc, (0xD75E:24)                       ; FB2F5E  lda XBC,0x00d75e
	push	xbc                                   ; FB2F63  push XBC
	pushw	hl                                   ; FB2F64  push HL
	call	0xFB713A                              ; FB2F65  call 0xfb713a
	add	xsp, 62                                ; FB2F69  add XSP,0x0000003e
	pop	xde                                    ; FB2F6F  pop XDE
	popw	hl                                    ; FB2F70  pop HL
	unlk32 xiz                                 ; FB2F71  unlk XIZ
	ret                                        ; FB2F73  ret
; ------------------------------------------------------------------------------
; sub_FB2F74 -- 0xFB2F74..0xFB31AA (567 bytes)
; ⚠ UNREFERENCED -- see sub_FB0B95's header.
; Called from: nothing found (searched negative).
; Evidence: call set {0xFA72B3, 0xFB4124, 0xFB454C, 0xFB474E, 0xFB48F7, 0xFC36BE,
;          0xFC6803} is a strict subset of VoiceParams_Compute_D's ten (checker
;          section 11).
sub_FB2F74:
	link32 0xEE, 0x0C, 0xE0, 0xFF              ; FB2F74  link XIZ,0xffe0
	pushw	hl                                   ; FB2F78  push HL
	pushw	de                                   ; FB2F79  push DE
	push	xix                                   ; FB2F7A  push XIX
	ld	e, (xiz+12)                             ; FB2F7B  ld E,(XIZ+0x0c)
	ld	d, (xiz+16)                             ; FB2F7E  ld D,(XIZ+0x10)
	ldb	c, 41                                  ; FB2F81  ld C,0x29
	mul8rr	c, d                                ; FB2F83  mul BC,D
	ld	(xiz-10), bc                            ; FB2F85  ld (XIZ+0xf6),BC
	ld	a, e                                    ; FB2F88  ld A,E
	extz	wa                                    ; FB2F8A  extz WA
	mul	wa, 0x12C                              ; FB2F8C  mul WA,0x012c
	ld	hl, wa                                  ; FB2F90  ld HL,WA
	add	wa, bc                                 ; FB2F92  add WA,BC
	add	wa, 0x90                               ; FB2F94  add WA,0x0090
	extz	xwa                                   ; FB2F98  extz XWA
	ld	xbc, (xwa+0x1523)                       ; FB2F9A  ld XBC,(XWA+0x1523)
	ld	(xiz-14), xbc                           ; FB2F9F  ld (XIZ+0xf2),XBC
	ld	wa, (xbc+12)                            ; FB2FA2  ld WA,(XBC+0x0c)
	ld	(xiz-16), wa                            ; FB2FA5  ld (XIZ+0xf0),WA
	srl	wa, 8                                  ; FB2FA8  srl 0x08,WA
	pushw	wa                                   ; FB2FAB  push WA
	ld	wa, (xiz-16)                            ; FB2FAC  ld WA,(XIZ+0xf0)
	and	wa, 0xFF                               ; FB2FAF  and WA,0x00ff
	ld	(xiz-18), wa                            ; FB2FB3  ld (XIZ+0xee),WA
	pushw	wa                                   ; FB2FB6  push WA
	call	0xFB4124                              ; FB2FB7  call 0xfb4124
	ld	(xiz-22), xiy                           ; FB2FBB  ld (XIZ+0xea),XIY
	ld	xbc, (xiz-14)                           ; FB2FBE  ld XBC,(XIZ+0xf2)
	ld	a, (xbc+11)                             ; FB2FC1  ld A,(XBC+0x0b)
	ld	(xiz-24), a                             ; FB2FC4  ld (XIZ+0xe8),A
	mul	a, 2                                   ; FB2FC7  mul A,0x02
	extz	xwa                                   ; FB2FCA  extz XWA
	ld	(xiz-28), xwa                           ; FB2FCC  ld (XIZ+0xe4),XWA
	add	xwa, 0x98                              ; FB2FCF  add XWA,0x00000098
	add	xiy, xwa                               ; FB2FD5  add XIY,XWA
	ld	c, (xiy)                                ; FB2FD7  ld C,(XIY)
	extz	bc                                    ; FB2FD9  extz BC
	ld	(xiz-30), bc                            ; FB2FDB  ld (XIZ+0xe2),BC
	ld	xwa, (xiz-28)                           ; FB2FDE  ld XWA,(XIZ+0xe4)
	add	xwa, 0x99                              ; FB2FE1  add XWA,0x00000099
	extpfx3 0xAE, 0xEA, 0x80                   ; FB2FE7  add XWA,(XIZ+0xea)
	ld	c, (xwa)                                ; FB2FEA  ld C,(XWA)
	extz	bc                                    ; FB2FEC  extz BC
	ld	(xiz-32), bc                            ; FB2FEE  ld (XIZ+0xe0),BC
	push	0                                     ; FB2FF1  push 0x00
	extpfx3 0x8E, 0xE8, 0x04                   ; FB2FF3  push (XIZ+0xe8)
	ld	w, (xiz-18)                             ; FB2FF6  ld W,(XIZ+0xee)
	push	0                                     ; FB2FF9  push 0x00
	push	w                                     ; FB2FFB  push W
	pushw	bc                                   ; FB2FFD  push BC
	extpfx3 0x9E, 0xE2, 0x04                   ; FB2FFE  pushw (XIZ+0xe2)
	call	0xFB48F7                              ; FB3001  call 0xfb48f7
	ld	xix, xiy                                ; FB3005  ld XIX,XIY
	ldb	c, 23                                  ; FB3007  ld C,0x17
	mul8rr	c, d                                ; FB3009  mul BC,D
	extz	xbc                                   ; FB300B  extz XBC
	add	xbc, 18                                ; FB300D  add XBC,0x00000012
	add	xiy, xbc                               ; FB3013  add XIY,XBC
	ld	(xiz-8), xiy                            ; FB3015  ld (XIZ+0xf8),XIY
	push	xix                                   ; FB3018  push XIX
	push	0                                     ; FB3019  push 0x00
	push	d                                     ; FB301B  push D
	call	0xFB454C                              ; FB301D  call 0xfb454c
	ld	(xiz-4), xiy                            ; FB3021  ld (XIZ+0xfc),XIY
	ld	xbc, (xiz-14)                           ; FB3024  ld XBC,(XIZ+0xf2)
	ld	a, (xbc)                                ; FB3027  ld A,(XBC)
	and	a, 2                                   ; FB3029  and A,0x02
	add	xsp, 18                                ; FB302C  add XSP,0x00000012
	cps	a, 0                                   ; FB3032  cp A,0
	jrl z, sub_FB2F74__FB3177                  ; FB3034  jrl Z,0xfb3177
	ld	c, (xix+13)                             ; FB3037  ld C,(XIX+0x0d)
	extz	bc                                    ; FB303A  extz BC
	extpfx3 0x9E, 0x0E, 0xC1                   ; FB303C  and BC,(XIZ+0x0e)
	jrl z, sub_FB2F74__FB3177                  ; FB303F  jrl Z,0xfb3177
	push	xiy                                   ; FB3042  push XIY
	push	0                                     ; FB3043  push 0x00
	extpfx3 0x8E, 0x14, 0x04                   ; FB3045  push (XIZ+0x14)
	call	0xFA72B3                              ; FB3048  call 0xfa72b3
	ld	(xiz-10), a                             ; FB304C  ld (XIZ+0xf6),A
	ld	xbc, (xiz-4)                            ; FB304F  ld XBC,(XIZ+0xfc)
	push	xbc                                   ; FB3052  push XBC
	pushw	wa                                   ; FB3053  push WA
	call	0xFB474E                              ; FB3054  call 0xfb474e
	ld	(xiz-14), xiy                           ; FB3058  ld (XIZ+0xf2),XIY
	ldb	c, 68                                  ; FB305B  ld C,0x44
	mul8rr	c, d                                ; FB305D  mul BC,D
	ld	(xiz-16), bc                            ; FB305F  ld (XIZ+0xf0),BC
	ldw	wa, 0x5A53                             ; FB3062  ld WA,0x5a53
	add	wa, bc                                 ; FB3065  add WA,BC
	ld	(xiz-18), wa                            ; FB3067  ld (XIZ+0xee),WA
	ld	c, (xiz-10)                             ; FB306A  ld C,(XIZ+0xf6)
	sll	c, 6                                   ; FB306D  sll 0x06,C
	or	c, 18                                   ; FB3070  or C,0x12
	extz	bc                                    ; FB3073  extz BC
	ld	wa, (xiz-18)                            ; FB3075  ld WA,(XIZ+0xee)
	extz	xwa                                   ; FB3078  extz XWA
	ld	(xwa+1), bc                             ; FB307A  ld (XWA+0x01),BC
	ld	bc, (xiz-18)                            ; FB307D  ld BC,(XIZ+0xee)
	extz	xbc                                   ; FB3080  extz XBC
	ld	(xbc+3), d                              ; FB3082  ld (XBC+0x03),D
	ld	bc, (xiz-18)                            ; FB3085  ld BC,(XIZ+0xee)
	extz	xbc                                   ; FB3088  extz XBC
	ld	(xbc+4), e                              ; FB308A  ld (XBC+0x04),E
	ld	c, (xiz+18)                             ; FB308D  ld C,(XIZ+0x12)
	set	7, c                                   ; FB3090  set 0x07,C
	ld	(xiz-20), c                             ; FB3093  ld (XIZ+0xec),C
	ld	bc, (xiz-18)                            ; FB3096  ld BC,(XIZ+0xee)
	extz	xbc                                   ; FB3099  extz XBC
	ld	a, (xiz-20)                             ; FB309B  ld A,(XIZ+0xec)
	ld	(xbc+5), a                              ; FB309E  ld (XBC+0x05),A
	ld	c, (xiz+20)                             ; FB30A1  ld C,(XIZ+0x14)
	res	7, c                                   ; FB30A4  res 0x07,C
	ld	(xiz-22), c                             ; FB30A7  ld (XIZ+0xea),C
	ld	bc, (xiz-18)                            ; FB30AA  ld BC,(XIZ+0xee)
	extz	xbc                                   ; FB30AD  extz XBC
	ld	a, (xiz-22)                             ; FB30AF  ld A,(XIZ+0xea)
	ld	(xbc+12), a                             ; FB30B2  ld (XBC+0x0c),A
	ldw	bc, 0x1523                             ; FB30B5  ld BC,0x1523
	add	bc, hl                                 ; FB30B8  add BC,HL
	ld	wa, (xiz-18)                            ; FB30BA  ld WA,(XIZ+0xee)
	extz	xwa                                   ; FB30BD  extz XWA
	ld	(xwa+35), bc                            ; FB30BF  ld (XWA+0x23),BC
	ld	bc, (xiz-18)                            ; FB30C2  ld BC,(XIZ+0xee)
	extz	xbc                                   ; FB30C5  extz XBC
	ld	(xbc+19), xix                           ; FB30C7  ld (XBC+0x13),XIX
	ld	bc, (xiz-18)                            ; FB30CA  ld BC,(XIZ+0xee)
	extz	xbc                                   ; FB30CD  extz XBC
	ld	xwa, (xiz-8)                            ; FB30CF  ld XWA,(XIZ+0xf8)
	ld	(xbc+23), xwa                           ; FB30D2  ld (XBC+0x17),XWA
	ld	bc, (xiz-18)                            ; FB30D5  ld BC,(XIZ+0xee)
	extz	xbc                                   ; FB30D8  extz XBC
	ld	xwa, (xiz-4)                            ; FB30DA  ld XWA,(XIZ+0xfc)
	ld	(xbc+27), xwa                           ; FB30DD  ld (XBC+0x1b),XWA
	ld	bc, (xiz-18)                            ; FB30E0  ld BC,(XIZ+0xee)
	extz	xbc                                   ; FB30E3  extz XBC
	ld	xwa, (xiz-14)                           ; FB30E5  ld XWA,(XIZ+0xf2)
	ld	(xbc+31), xwa                           ; FB30E8  ld (XBC+0x1f),XWA
	extpfx3 0x9E, 0xEE, 0x04                   ; FB30EB  pushw (XIZ+0xee)
	call	0xFC36BE                              ; FB30EE  call 0xfc36be
	ld	bc, (xiz-18)                            ; FB30F2  ld BC,(XIZ+0xee)
	extz	xbc                                   ; FB30F5  extz XBC
	extpfx5 0xB9, 0x2B, 0x02, 0x00, 0x00       ; FB30F7  ld (XBC+0x2b),0x0000
	ld	bc, (xiz-18)                            ; FB30FC  ld BC,(XIZ+0xee)
	extz	xbc                                   ; FB30FF  extz XBC
	extpfx5 0xB9, 0x2D, 0x02, 0xFF, 0x00       ; FB3101  ld (XBC+0x2d),0x00ff
	ld	bc, (xiz-18)                            ; FB3106  ld BC,(XIZ+0xee)
	extz	xbc                                   ; FB3109  extz XBC
	ld	(xbc+49), 0                             ; FB310B  ld (XBC+0x31),0x00
	ld	bc, (xiz-18)                            ; FB310F  ld BC,(XIZ+0xee)
	extz	xbc                                   ; FB3112  extz XBC
	extpfx5 0xB9, 0x32, 0x02, 0x00, 0x00       ; FB3114  ld (XBC+0x32),0x0000
	ld	bc, (xiz-18)                            ; FB3119  ld BC,(XIZ+0xee)
	extz	xbc                                   ; FB311C  extz XBC
	extpfx5 0xB9, 0x36, 0x02, 0x00, 0x00       ; FB311E  ld (XBC+0x36),0x0000
	ld	bc, (xiz-18)                            ; FB3123  ld BC,(XIZ+0xee)
	extz	xbc                                   ; FB3126  extz XBC
	extpfx5 0xB9, 0x34, 0x02, 0x00, 0x00       ; FB3128  ld (XBC+0x34),0x0000
	ld	c, (xiz+22)                             ; FB312D  ld C,(XIZ+0x16)
	set	7, c                                   ; FB3130  set 0x07,C
	ld	(xiz-24), c                             ; FB3133  ld (XIZ+0xe8),C
	ld	c, d                                    ; FB3136  ld C,D
	extz	bc                                    ; FB3138  extz BC
	extz	xbc                                   ; FB313A  extz XBC
	ld	(xiz-28), xbc                           ; FB313C  ld (XIZ+0xe4),XBC
	inc	2, xbc                                 ; FB313F  inc 2,XBC
	extpfx3 0xAE, 0x08, 0x81                   ; FB3141  add XBC,(XIZ+0x08)
	ld	a, (xiz-24)                             ; FB3144  ld A,(XIZ+0xe8)
	ld	(xbc), a                                ; FB3147  ld (XBC),A
	ld	bc, (xiz-18)                            ; FB3149  ld BC,(XIZ+0xee)
	extz	xbc                                   ; FB314C  extz XBC
	ld	hl, (xbc+6)                             ; FB314E  ld HL,(XBC+0x06)
	ld	xix, (xiz-28)                           ; FB3151  ld XIX,(XIZ+0xe4)
	inc	6, xix                                 ; FB3154  inc 6,XIX
	inc	8, xsp                                 ; FB3156  inc 0,XSP
	inc	6, xsp                                 ; FB3158  inc 6,XSP
	cp	hl, 0x2980                              ; FB315A  cp HL,0x2980
	jr ugt, sub_FB2F74__FB316A                 ; FB315E  jr UGT,0xfb316a
	ld	xbc, (xiz+8)                            ; FB3160  ld XBC,(XIZ+0x08)
	add	xbc, xix                               ; FB3163  add XBC,XIX
	ld	(xbc), 32                               ; FB3165  ld (XBC),0x20
	jr sub_FB2F74__FB3172                      ; FB3168  jr T,0xfb3172
sub_FB2F74__FB316A:
	ld	xbc, (xiz+8)                            ; FB316A  ld XBC,(XIZ+0x08)
	add	xbc, xix                               ; FB316D  add XBC,XIX
	ld	(xbc), 0                                ; FB316F  ld (XBC),0x00
sub_FB2F74__FB3172:
	pushw	1                                    ; FB3172  push 0x0001
	jr sub_FB2F74__FB3194                      ; FB3175  jr T,0xfb3194
sub_FB2F74__FB3177:
	ld	c, d                                    ; FB3177  ld C,D
	extz	bc                                    ; FB3179  extz BC
	extz	xbc                                   ; FB317B  extz XBC
	ld	xix, xbc                                ; FB317D  ld XIX,XBC
	inc	2, xbc                                 ; FB317F  inc 2,XBC
	extpfx3 0xAE, 0x08, 0x81                   ; FB3181  add XBC,(XIZ+0x08)
	ld	(xbc), 0                                ; FB3184  ld (XBC),0x00
	ld	xbc, xix                                ; FB3187  ld XBC,XIX
	inc	6, xbc                                 ; FB3189  inc 6,XBC
	extpfx3 0xAE, 0x08, 0x81                   ; FB318B  add XBC,(XIZ+0x08)
	ld	(xbc), 0                                ; FB318E  ld (XBC),0x00
	pushw	0                                    ; FB3191  push 0x0000
sub_FB2F74__FB3194:
	ld	xbc, (xiz-4)                            ; FB3194  ld XBC,(XIZ+0xfc)
	push	xbc                                   ; FB3197  push XBC
	push	0                                     ; FB3198  push 0x00
	push	d                                     ; FB319A  push D
	pushw	de                                   ; FB319C  push DE
	call	0xFC6803                              ; FB319D  call 0xfc6803
	inc	8, xsp                                 ; FB31A1  inc 0,XSP
	inc	2, xsp                                 ; FB31A3  inc 2,XSP
	pop	xix                                    ; FB31A5  pop XIX
	popw	de                                    ; FB31A6  pop DE
	popw	hl                                    ; FB31A7  pop HL
	unlk32 xiz                                 ; FB31A8  unlk XIZ
	ret                                        ; FB31AA  ret
; ------------------------------------------------------------------------------
; VoiceParams_Compute_D -- 0xFB31AB..0xFB3633 (1161 bytes)
;
; Called from: TWO sites, `calr 0xFB31AB` at 0xFB3695 (MidiNote_OnTail) and at
;          0xFB37A2 (MidiNote_OffTail) -- the same pair of callers as
;          VoiceRegs_Stage_D, which each of them calls a few instructions later.
; Evidence: the subset relation with sub_FB2F74, plus MemCopyWords / 0xFA6BB5 /
;          0xFC376C.
; Unknown:  ⚠ the formulae.
VoiceParams_Compute_D:
	link32 0xEE, 0x0C, 0xE2, 0xFF              ; FB31AB  link XIZ,0xffe2
	pushw	hl                                   ; FB31AF  push HL
	pushw	de                                   ; FB31B0  push DE
	push	xix                                   ; FB31B1  push XIX
	ld	hl, (xiz+12)                            ; FB31B2  ld HL,(XIZ+0x0c)
	extz	hl                                    ; FB31B5  extz HL
	ld	de, hl                                  ; FB31B7  ld DE,HL
	sll	de, 8                                  ; FB31B9  sll 0x08,DE
	ld	bc, (xiz+14)                            ; FB31BC  ld BC,(XIZ+0x0e)
	extz	bc                                    ; FB31BF  extz BC
	or	bc, de                                  ; FB31C1  or BC,DE
	set	7, bc                                  ; FB31C3  set 0x07,BC
	ld	xwa, (xiz+8)                            ; FB31C6  ld XWA,(XIZ+0x08)
	ld	(xwa), bc                               ; FB31C9  ld (XWA),BC
	cp (xiz+16), 0x00                          ; FB31CB  cp (XIZ+0x10),0x00
	jrl z, VoiceParams_Compute_D__FB33CE       ; FB31CF  jrl Z,0xfb33ce
	ldb	e, 0                                   ; FB31D2  ld E,0x00
	ld	d, (xiz+16)                             ; FB31D4  ld D,(XIZ+0x10)
	ldw	bc, 0x12C                              ; FB31D7  ld BC,0x012c
	mul	xbc, xhl                               ; FB31DA  mul XBC,HL
	ld	hl, bc                                  ; FB31DC  ld HL,BC
	add	bc, 0x90                               ; FB31DE  add BC,0x0090
	extz	xbc                                   ; FB31E2  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB31E4  ld XWA,(XBC+0x1523)
	ld	(xiz-12), xwa                           ; FB31E9  ld (XIZ+0xf4),XWA
	ld	bc, (xwa+12)                            ; FB31EC  ld BC,(XWA+0x0c)
	ld	(xiz-14), bc                            ; FB31EF  ld (XIZ+0xf2),BC
	srl	bc, 8                                  ; FB31F2  srl 0x08,BC
	pushw	bc                                   ; FB31F5  push BC
	ld	bc, (xiz-14)                            ; FB31F6  ld BC,(XIZ+0xf2)
	and	bc, 0xFF                               ; FB31F9  and BC,0x00ff
	ld	(xiz-16), bc                            ; FB31FD  ld (XIZ+0xf0),BC
	pushw	bc                                   ; FB3200  push BC
	call	0xFB4124                              ; FB3201  call 0xfb4124
	ld	(xiz-20), xiy                           ; FB3205  ld (XIZ+0xec),XIY
	ld	xbc, (xiz-12)                           ; FB3208  ld XBC,(XIZ+0xf4)
	ld	a, (xbc+11)                             ; FB320B  ld A,(XBC+0x0b)
	ld	(xiz-22), a                             ; FB320E  ld (XIZ+0xea),A
	mul	a, 2                                   ; FB3211  mul A,0x02
	extz	xwa                                   ; FB3214  extz XWA
	ld	(xiz-26), xwa                           ; FB3216  ld (XIZ+0xe6),XWA
	add	xwa, 0x98                              ; FB3219  add XWA,0x00000098
	add	xiy, xwa                               ; FB321F  add XIY,XWA
	ld	c, (xiy)                                ; FB3221  ld C,(XIY)
	extz	bc                                    ; FB3223  extz BC
	ld	(xiz-28), bc                            ; FB3225  ld (XIZ+0xe4),BC
	ld	xwa, (xiz-26)                           ; FB3228  ld XWA,(XIZ+0xe6)
	add	xwa, 0x99                              ; FB322B  add XWA,0x00000099
	extpfx3 0xAE, 0xEC, 0x80                   ; FB3231  add XWA,(XIZ+0xec)
	ld	c, (xwa)                                ; FB3234  ld C,(XWA)
	extz	bc                                    ; FB3236  extz BC
	ld	(xiz-30), bc                            ; FB3238  ld (XIZ+0xe2),BC
	push	0                                     ; FB323B  push 0x00
	extpfx3 0x8E, 0xEA, 0x04                   ; FB323D  push (XIZ+0xea)
	ld	w, (xiz-16)                             ; FB3240  ld W,(XIZ+0xf0)
	push	0                                     ; FB3243  push 0x00
	push	w                                     ; FB3245  push W
	pushw	bc                                   ; FB3247  push BC
	extpfx3 0x9E, 0xE4, 0x04                   ; FB3248  pushw (XIZ+0xe4)
	call	0xFB48F7                              ; FB324B  call 0xfb48f7
	ld	(xiz-8), xiy                            ; FB324F  ld (XIZ+0xf8),XIY
	add	xiy, 18                                ; FB3252  add XIY,0x00000012
	ld	(xiz-4), xiy                            ; FB3258  ld (XIZ+0xfc),XIY
	ld	xbc, (xiz-8)                            ; FB325B  ld XBC,(XIZ+0xf8)
	push	xbc                                   ; FB325E  push XBC
	pushw	0                                    ; FB325F  push 0x0000
	call	0xFB454C                              ; FB3262  call 0xfb454c
	ld	xix, xiy                                ; FB3266  ld XIX,XIY
	ld	xbc, (xiz-12)                           ; FB3268  ld XBC,(XIZ+0xf4)
	ld	a, (xbc)                                ; FB326B  ld A,(XBC)
	and	a, 2                                   ; FB326D  and A,0x02
	add	xsp, 18                                ; FB3270  add XSP,0x00000012
	cps	a, 0                                   ; FB3276  cp A,0
	jrl z, VoiceParams_Compute_D__FB3394       ; FB3278  jrl Z,0xfb3394
	ld	xbc, (xiz-8)                            ; FB327B  ld XBC,(XIZ+0xf8)
	ld	a, (xbc+13)                             ; FB327E  ld A,(XBC+0x0d)
	extz	wa                                    ; FB3281  extz WA
	and	wa, 1                                  ; FB3283  and WA,0x0001
	jrl z, VoiceParams_Compute_D__FB3394       ; FB3287  jrl Z,0xfb3394
	push	xiy                                   ; FB328A  push XIY
	push	0                                     ; FB328B  push 0x00
	push	d                                     ; FB328D  push D
	call	0xFA72B3                              ; FB328F  call 0xfa72b3
	ld	(xiz-10), a                             ; FB3293  ld (XIZ+0xf6),A
	push	xix                                   ; FB3296  push XIX
	pushw	wa                                   ; FB3297  push WA
	call	0xFB474E                              ; FB3298  call 0xfb474e
	ld	(xiz-14), xiy                           ; FB329C  ld (XIZ+0xf2),XIY
	ldw	bc, 0x5A53                             ; FB329F  ld BC,0x5a53
	ld	(xiz-16), bc                            ; FB32A2  ld (XIZ+0xf0),BC
	ld	w, (xiz-10)                             ; FB32A5  ld W,(XIZ+0xf6)
	sll	w, 6                                   ; FB32A8  sll 0x06,W
	or	w, 18                                   ; FB32AB  or W,0x12
	ld	a, w                                    ; FB32AE  ld A,W
	extz	wa                                    ; FB32B0  extz WA
	extz	xbc                                   ; FB32B2  extz XBC
	ld	(xbc+1), wa                             ; FB32B4  ld (XBC+0x01),WA
	ld	bc, (xiz-16)                            ; FB32B7  ld BC,(XIZ+0xf0)
	extz	xbc                                   ; FB32BA  extz XBC
	ld	(xbc+3), 0                              ; FB32BC  ld (XBC+0x03),0x00
	ld	bc, (xiz-16)                            ; FB32C0  ld BC,(XIZ+0xf0)
	extz	xbc                                   ; FB32C3  extz XBC
	ld	a, (xiz+12)                             ; FB32C5  ld A,(XIZ+0x0c)
	ld	(xbc+4), a                              ; FB32C8  ld (XBC+0x04),A
	ld	c, (xiz+14)                             ; FB32CB  ld C,(XIZ+0x0e)
	set	7, c                                   ; FB32CE  set 0x07,C
	ld	(xiz-18), c                             ; FB32D1  ld (XIZ+0xee),C
	ld	bc, (xiz-16)                            ; FB32D4  ld BC,(XIZ+0xf0)
	extz	xbc                                   ; FB32D7  extz XBC
	ld	a, (xiz-18)                             ; FB32D9  ld A,(XIZ+0xee)
	ld	(xbc+5), a                              ; FB32DC  ld (XBC+0x05),A
	ld	c, d                                    ; FB32DF  ld C,D
	res	7, c                                   ; FB32E1  res 0x07,C
	ld	d, c                                    ; FB32E4  ld D,C
	ld	bc, (xiz-16)                            ; FB32E6  ld BC,(XIZ+0xf0)
	extz	xbc                                   ; FB32E9  extz XBC
	ld	(xbc+12), d                             ; FB32EB  ld (XBC+0x0c),D
	ldw	bc, 0x1523                             ; FB32EE  ld BC,0x1523
	add	bc, hl                                 ; FB32F1  add BC,HL
	ld	wa, (xiz-16)                            ; FB32F3  ld WA,(XIZ+0xf0)
	extz	xwa                                   ; FB32F6  extz XWA
	ld	(xwa+35), bc                            ; FB32F8  ld (XWA+0x23),BC
	ld	bc, (xiz-16)                            ; FB32FB  ld BC,(XIZ+0xf0)
	extz	xbc                                   ; FB32FE  extz XBC
	ld	xwa, (xiz-8)                            ; FB3300  ld XWA,(XIZ+0xf8)
	ld	(xbc+19), xwa                           ; FB3303  ld (XBC+0x13),XWA
	ld	bc, (xiz-16)                            ; FB3306  ld BC,(XIZ+0xf0)
	extz	xbc                                   ; FB3309  extz XBC
	ld	xwa, (xiz-4)                            ; FB330B  ld XWA,(XIZ+0xfc)
	ld	(xbc+23), xwa                           ; FB330E  ld (XBC+0x17),XWA
	ld	bc, (xiz-16)                            ; FB3311  ld BC,(XIZ+0xf0)
	extz	xbc                                   ; FB3314  extz XBC
	ld	(xbc+27), xix                           ; FB3316  ld (XBC+0x1b),XIX
	ld	bc, (xiz-16)                            ; FB3319  ld BC,(XIZ+0xf0)
	extz	xbc                                   ; FB331C  extz XBC
	ld	xwa, (xiz-14)                           ; FB331E  ld XWA,(XIZ+0xf2)
	ld	(xbc+31), xwa                           ; FB3321  ld (XBC+0x1f),XWA
	extpfx3 0x9E, 0xF0, 0x04                   ; FB3324  pushw (XIZ+0xf0)
	call	0xFC36BE                              ; FB3327  call 0xfc36be
	ld	bc, (xiz-16)                            ; FB332B  ld BC,(XIZ+0xf0)
	extz	xbc                                   ; FB332E  extz XBC
	extpfx5 0xB9, 0x2B, 0x02, 0x00, 0x00       ; FB3330  ld (XBC+0x2b),0x0000
	ld	bc, (xiz-16)                            ; FB3335  ld BC,(XIZ+0xf0)
	extz	xbc                                   ; FB3338  extz XBC
	extpfx5 0xB9, 0x2D, 0x02, 0xFF, 0x00       ; FB333A  ld (XBC+0x2d),0x00ff
	ld	bc, (xiz-16)                            ; FB333F  ld BC,(XIZ+0xf0)
	extz	xbc                                   ; FB3342  extz XBC
	ld	(xbc+49), 0                             ; FB3344  ld (XBC+0x31),0x00
	ld	bc, (xiz-16)                            ; FB3348  ld BC,(XIZ+0xf0)
	extz	xbc                                   ; FB334B  extz XBC
	extpfx5 0xB9, 0x32, 0x02, 0x00, 0x00       ; FB334D  ld (XBC+0x32),0x0000
	ld	bc, (xiz-16)                            ; FB3352  ld BC,(XIZ+0xf0)
	extz	xbc                                   ; FB3355  extz XBC
	extpfx5 0xB9, 0x36, 0x02, 0x00, 0x00       ; FB3357  ld (XBC+0x36),0x0000
	ld	bc, (xiz-16)                            ; FB335C  ld BC,(XIZ+0xf0)
	extz	xbc                                   ; FB335F  extz XBC
	extpfx5 0xB9, 0x34, 0x02, 0x00, 0x00       ; FB3361  ld (XBC+0x34),0x0000
	ld	xbc, (xiz+8)                            ; FB3366  ld XBC,(XIZ+0x08)
	ld	(xbc+2), 0x83                           ; FB3369  ld (XBC+0x02),0x83
	ld	bc, (xiz-16)                            ; FB336D  ld BC,(XIZ+0xf0)
	extz	xbc                                   ; FB3370  extz XBC
	ld	wa, (xbc+6)                             ; FB3372  ld WA,(XBC+0x06)
	inc	8, xsp                                 ; FB3375  inc 0,XSP
	inc	6, xsp                                 ; FB3377  inc 6,XSP
	cp	wa, 0x2980                              ; FB3379  cp WA,0x2980
	jr ugt, VoiceParams_Compute_D__FB3388      ; FB337D  jr UGT,0xfb3388
	ld	xbc, (xiz+8)                            ; FB337F  ld XBC,(XIZ+0x08)
	ld	(xbc+6), 32                             ; FB3382  ld (XBC+0x06),0x20
	jr VoiceParams_Compute_D__FB338F           ; FB3386  jr T,0xfb338f
VoiceParams_Compute_D__FB3388:
	ld	xbc, (xiz+8)                            ; FB3388  ld XBC,(XIZ+0x08)
	ld	(xbc+6), 0                              ; FB338B  ld (XBC+0x06),0x00
VoiceParams_Compute_D__FB338F:
	pushw	1                                    ; FB338F  push 0x0001
	jr VoiceParams_Compute_D__FB33A5           ; FB3392  jr T,0xfb33a5
VoiceParams_Compute_D__FB3394:
	ld	xbc, (xiz+8)                            ; FB3394  ld XBC,(XIZ+0x08)
	ld	(xbc+2), 0                              ; FB3397  ld (XBC+0x02),0x00
	ld	xbc, (xiz+8)                            ; FB339B  ld XBC,(XIZ+0x08)
	ld	(xbc+6), 0                              ; FB339E  ld (XBC+0x06),0x00
	pushw	0                                    ; FB33A2  push 0x0000
VoiceParams_Compute_D__FB33A5:
	push	xix                                   ; FB33A5  push XIX
	pushw	0                                    ; FB33A6  push 0x0000
	push	0                                     ; FB33A9  push 0x00
	extpfx3 0x8E, 0x0C, 0x04                   ; FB33AB  push (XIZ+0x0c)
	call	0xFC6803                              ; FB33AE  call 0xfc6803
	ld	xbc, (xiz+8)                            ; FB33B2  ld XBC,(XIZ+0x08)
	extpfx4 0x89, 0x06, 0x3E, 0x40             ; FB33B5  or (XBC+0x06),0x40
	ld	xbc, (xiz+8)                            ; FB33B9  ld XBC,(XIZ+0x08)
	ld	(xbc+3), 0                              ; FB33BC  ld (XBC+0x03),0x00
	ld	xbc, (xiz+8)                            ; FB33C0  ld XBC,(XIZ+0x08)
	ld	(xbc+7), 0                              ; FB33C3  ld (XBC+0x07),0x00
	inc	8, xsp                                 ; FB33C7  inc 0,XSP
	inc	2, xsp                                 ; FB33C9  inc 2,XSP
	jrl VoiceParams_Compute_D__FB35B7          ; FB33CB  jrl T,0xfb35b7
VoiceParams_Compute_D__FB33CE:
	ldb	e, 1                                   ; FB33CE  ld E,0x01
	ld	xbc, (xiz+8)                            ; FB33D0  ld XBC,(XIZ+0x08)
	ld	(xbc+2), 0                              ; FB33D3  ld (XBC+0x02),0x00
	ld	xbc, (xiz+8)                            ; FB33D7  ld XBC,(XIZ+0x08)
	ld	(xbc+6), 0                              ; FB33DA  ld (XBC+0x06),0x00
	ldw	bc, 0x12C                              ; FB33DE  ld BC,0x012c
	mul	xbc, xhl                               ; FB33E1  mul XBC,HL
	ld	hl, bc                                  ; FB33E3  ld HL,BC
	add	bc, 0xB9                               ; FB33E5  add BC,0x00b9
	extz	xbc                                   ; FB33E9  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB33EB  ld XWA,(XBC+0x1523)
	ld	(xiz-12), xwa                           ; FB33F0  ld (XIZ+0xf4),XWA
	ld	bc, (xwa+12)                            ; FB33F3  ld BC,(XWA+0x0c)
	ld	(xiz-14), bc                            ; FB33F6  ld (XIZ+0xf2),BC
	srl	bc, 8                                  ; FB33F9  srl 0x08,BC
	pushw	bc                                   ; FB33FC  push BC
	ld	bc, (xiz-14)                            ; FB33FD  ld BC,(XIZ+0xf2)
	and	bc, 0xFF                               ; FB3400  and BC,0x00ff
	ld	(xiz-16), bc                            ; FB3404  ld (XIZ+0xf0),BC
	pushw	bc                                   ; FB3407  push BC
	call	0xFB4124                              ; FB3408  call 0xfb4124
	ld	(xiz-20), xiy                           ; FB340C  ld (XIZ+0xec),XIY
	ld	xbc, (xiz-12)                           ; FB340F  ld XBC,(XIZ+0xf4)
	ld	d, (xbc+11)                             ; FB3412  ld D,(XBC+0x0b)
	ldb	a, 2                                   ; FB3415  ld A,0x02
	mul8rr	a, d                                ; FB3417  mul WA,D
	extz	xwa                                   ; FB3419  extz XWA
	ld	(xiz-24), xwa                           ; FB341B  ld (XIZ+0xe8),XWA
	add	xwa, 0x98                              ; FB341E  add XWA,0x00000098
	add	xiy, xwa                               ; FB3424  add XIY,XWA
	ld	c, (xiy)                                ; FB3426  ld C,(XIY)
	extz	bc                                    ; FB3428  extz BC
	ld	(xiz-26), bc                            ; FB342A  ld (XIZ+0xe6),BC
	ld	xwa, (xiz-24)                           ; FB342D  ld XWA,(XIZ+0xe8)
	add	xwa, 0x99                              ; FB3430  add XWA,0x00000099
	extpfx3 0xAE, 0xEC, 0x80                   ; FB3436  add XWA,(XIZ+0xec)
	ld	c, (xwa)                                ; FB3439  ld C,(XWA)
	extz	bc                                    ; FB343B  extz BC
	ld	(xiz-28), bc                            ; FB343D  ld (XIZ+0xe4),BC
	push	0                                     ; FB3440  push 0x00
	push	d                                     ; FB3442  push D
	ld	w, (xiz-16)                             ; FB3444  ld W,(XIZ+0xf0)
	push	0                                     ; FB3447  push 0x00
	push	w                                     ; FB3449  push W
	pushw	bc                                   ; FB344B  push BC
	extpfx3 0x9E, 0xE6, 0x04                   ; FB344C  pushw (XIZ+0xe6)
	call	0xFB48F7                              ; FB344F  call 0xfb48f7
	ld	(xiz-8), xiy                            ; FB3453  ld (XIZ+0xf8),XIY
	add	xiy, 41                                ; FB3456  add XIY,0x00000029
	ld	(xiz-4), xiy                            ; FB345C  ld (XIZ+0xfc),XIY
	ld	xbc, (xiz-8)                            ; FB345F  ld XBC,(XIZ+0xf8)
	push	xbc                                   ; FB3462  push XBC
	pushw	1                                    ; FB3463  push 0x0001
	call	0xFB454C                              ; FB3466  call 0xfb454c
	ld	xix, xiy                                ; FB346A  ld XIX,XIY
	ld	xbc, (xiz-12)                           ; FB346C  ld XBC,(XIZ+0xf4)
	ld	a, (xbc)                                ; FB346F  ld A,(XBC)
	and	a, 2                                   ; FB3471  and A,0x02
	add	xsp, 18                                ; FB3474  add XSP,0x00000012
	cps	a, 0                                   ; FB347A  cp A,0
	jrl z, VoiceParams_Compute_D__FB3595       ; FB347C  jrl Z,0xfb3595
	ld	xbc, (xiz-8)                            ; FB347F  ld XBC,(XIZ+0xf8)
	ld	a, (xbc+13)                             ; FB3482  ld A,(XBC+0x0d)
	extz	wa                                    ; FB3485  extz WA
	and	wa, 4                                  ; FB3487  and WA,0x0004
	jrl z, VoiceParams_Compute_D__FB3595       ; FB348B  jrl Z,0xfb3595
	push	xiy                                   ; FB348E  push XIY
	pushw	80                                   ; FB348F  push 0x0050
	call	0xFA72B3                              ; FB3492  call 0xfa72b3
	ld	d, a                                    ; FB3496  ld D,A
	push	xix                                   ; FB3498  push XIX
	pushw	wa                                   ; FB3499  push WA
	call	0xFB474E                              ; FB349A  call 0xfb474e
	ld	(xiz-12), xiy                           ; FB349E  ld (XIZ+0xf4),XIY
	ldw	bc, 0x5A53                             ; FB34A1  ld BC,0x5a53
	ld	(xiz-14), bc                            ; FB34A4  ld (XIZ+0xf2),BC
	add	bc, 68                                 ; FB34A7  add BC,0x0044
	ld	(xiz-16), bc                            ; FB34AB  ld (XIZ+0xf0),BC
	ld	w, d                                    ; FB34AE  ld W,D
	sll	w, 6                                   ; FB34B0  sll 0x06,W
	or	w, 18                                   ; FB34B3  or W,0x12
	ld	a, w                                    ; FB34B6  ld A,W
	extz	wa                                    ; FB34B8  extz WA
	ld	bc, (xiz-14)                            ; FB34BA  ld BC,(XIZ+0xf2)
	extz	xbc                                   ; FB34BD  extz XBC
	ld	(xbc+69), wa                            ; FB34BF  ld (XBC+0x45),WA
	ld	bc, (xiz-14)                            ; FB34C2  ld BC,(XIZ+0xf2)
	extz	xbc                                   ; FB34C5  extz XBC
	ld	(xbc+71), 1                             ; FB34C7  ld (XBC+0x47),0x01
	ld	bc, (xiz-14)                            ; FB34CB  ld BC,(XIZ+0xf2)
	extz	xbc                                   ; FB34CE  extz XBC
	ld	a, (xiz+12)                             ; FB34D0  ld A,(XIZ+0x0c)
	ld	(xbc+72), a                             ; FB34D3  ld (XBC+0x48),A
	ld	c, (xiz+14)                             ; FB34D6  ld C,(XIZ+0x0e)
	set	7, c                                   ; FB34D9  set 0x07,C
	ld	d, c                                    ; FB34DC  ld D,C
	ld	bc, (xiz-14)                            ; FB34DE  ld BC,(XIZ+0xf2)
	extz	xbc                                   ; FB34E1  extz XBC
	ld	(xbc+73), d                             ; FB34E3  ld (XBC+0x49),D
	ld	bc, (xiz-14)                            ; FB34E6  ld BC,(XIZ+0xf2)
	extz	xbc                                   ; FB34E9  extz XBC
	ld	(xbc+80), 80                            ; FB34EB  ld (XBC+0x50),0x50
	ldw	bc, 0x1523                             ; FB34EF  ld BC,0x1523
	add	bc, hl                                 ; FB34F2  add BC,HL
	ld	wa, (xiz-14)                            ; FB34F4  ld WA,(XIZ+0xf2)
	extz	xwa                                   ; FB34F7  extz XWA
	ld	(xwa+0x67), bc                          ; FB34F9  ld (XWA+0x67),BC
	ld	bc, (xiz-14)                            ; FB34FC  ld BC,(XIZ+0xf2)
	extz	xbc                                   ; FB34FF  extz XBC
	ld	xwa, (xiz-8)                            ; FB3501  ld XWA,(XIZ+0xf8)
	ld	(xbc+87), xwa                           ; FB3504  ld (XBC+0x57),XWA
	ld	bc, (xiz-14)                            ; FB3507  ld BC,(XIZ+0xf2)
	extz	xbc                                   ; FB350A  extz XBC
	ld	xwa, (xiz-4)                            ; FB350C  ld XWA,(XIZ+0xfc)
	ld	(xbc+91), xwa                           ; FB350F  ld (XBC+0x5b),XWA
	ld	bc, (xiz-14)                            ; FB3512  ld BC,(XIZ+0xf2)
	extz	xbc                                   ; FB3515  extz XBC
	ld	(xbc+95), xix                           ; FB3517  ld (XBC+0x5f),XIX
	ld	bc, (xiz-14)                            ; FB351A  ld BC,(XIZ+0xf2)
	extz	xbc                                   ; FB351D  extz XBC
	ld	xwa, (xiz-12)                           ; FB351F  ld XWA,(XIZ+0xf4)
	ld	(xbc+99), xwa                           ; FB3522  ld (XBC+0x63),XWA
	extpfx3 0x9E, 0xF0, 0x04                   ; FB3525  pushw (XIZ+0xf0)
	call	0xFC36BE                              ; FB3528  call 0xfc36be
	ld	bc, (xiz-14)                            ; FB352C  ld BC,(XIZ+0xf2)
	extz	xbc                                   ; FB352F  extz XBC
	extpfx5 0xB9, 0x6F, 0x02, 0x00, 0x00       ; FB3531  ld (XBC+0x6f),0x0000
	ld	bc, (xiz-14)                            ; FB3536  ld BC,(XIZ+0xf2)
	extz	xbc                                   ; FB3539  extz XBC
	extpfx5 0xB9, 0x71, 0x02, 0xFF, 0x00       ; FB353B  ld (XBC+0x71),0x00ff
	ld	bc, (xiz-14)                            ; FB3540  ld BC,(XIZ+0xf2)
	extz	xbc                                   ; FB3543  extz XBC
	ld	(xbc+0x75), 0                           ; FB3545  ld (XBC+0x75),0x00
	ld	bc, (xiz-14)                            ; FB3549  ld BC,(XIZ+0xf2)
	extz	xbc                                   ; FB354C  extz XBC
	extpfx5 0xB9, 0x76, 0x02, 0x00, 0x00       ; FB354E  ld (XBC+0x76),0x0000
	ld	bc, (xiz-14)                            ; FB3553  ld BC,(XIZ+0xf2)
	extz	xbc                                   ; FB3556  extz XBC
	extpfx5 0xB9, 0x7A, 0x02, 0x00, 0x00       ; FB3558  ld (XBC+0x7a),0x0000
	ld	bc, (xiz-14)                            ; FB355D  ld BC,(XIZ+0xf2)
	extz	xbc                                   ; FB3560  extz XBC
	extpfx5 0xB9, 0x78, 0x02, 0x00, 0x00       ; FB3562  ld (XBC+0x78),0x0000
	ld	xbc, (xiz+8)                            ; FB3567  ld XBC,(XIZ+0x08)
	ld	(xbc+3), 0x83                           ; FB356A  ld (XBC+0x03),0x83
	ld	bc, (xiz-14)                            ; FB356E  ld BC,(XIZ+0xf2)
	extz	xbc                                   ; FB3571  extz XBC
	ld	wa, (xbc+74)                            ; FB3573  ld WA,(XBC+0x4a)
	inc	8, xsp                                 ; FB3576  inc 0,XSP
	inc	6, xsp                                 ; FB3578  inc 6,XSP
	cp	wa, 0x2980                              ; FB357A  cp WA,0x2980
	jr ugt, VoiceParams_Compute_D__FB3589      ; FB357E  jr UGT,0xfb3589
	ld	xbc, (xiz+8)                            ; FB3580  ld XBC,(XIZ+0x08)
	ld	(xbc+7), 32                             ; FB3583  ld (XBC+0x07),0x20
	jr VoiceParams_Compute_D__FB3590           ; FB3587  jr T,0xfb3590
VoiceParams_Compute_D__FB3589:
	ld	xbc, (xiz+8)                            ; FB3589  ld XBC,(XIZ+0x08)
	ld	(xbc+7), 0                              ; FB358C  ld (XBC+0x07),0x00
VoiceParams_Compute_D__FB3590:
	pushw	1                                    ; FB3590  push 0x0001
	jr VoiceParams_Compute_D__FB35A6           ; FB3593  jr T,0xfb35a6
VoiceParams_Compute_D__FB3595:
	ld	xbc, (xiz+8)                            ; FB3595  ld XBC,(XIZ+0x08)
	ld	(xbc+3), 0                              ; FB3598  ld (XBC+0x03),0x00
	ld	xbc, (xiz+8)                            ; FB359C  ld XBC,(XIZ+0x08)
	ld	(xbc+7), 0                              ; FB359F  ld (XBC+0x07),0x00
	pushw	0                                    ; FB35A3  push 0x0000
VoiceParams_Compute_D__FB35A6:
	push	xix                                   ; FB35A6  push XIX
	pushw	1                                    ; FB35A7  push 0x0001
	push	0                                     ; FB35AA  push 0x00
	extpfx3 0x8E, 0x0C, 0x04                   ; FB35AC  push (XIZ+0x0c)
	call	0xFC6803                              ; FB35AF  call 0xfc6803
	inc	8, xsp                                 ; FB35B3  inc 0,XSP
	inc	2, xsp                                 ; FB35B5  inc 2,XSP
VoiceParams_Compute_D__FB35B7:
	ld	xbc, (xiz+8)                            ; FB35B7  ld XBC,(XIZ+0x08)
	ld	(xbc+4), 0                              ; FB35BA  ld (XBC+0x04),0x00
	ld	xbc, (xiz+8)                            ; FB35BE  ld XBC,(XIZ+0x08)
	ld	(xbc+8), 0                              ; FB35C1  ld (XBC+0x08),0x00
	ld	xbc, (xiz+8)                            ; FB35C5  ld XBC,(XIZ+0x08)
	ld	(xbc+5), 0                              ; FB35C8  ld (XBC+0x05),0x00
	ld	xbc, (xiz+8)                            ; FB35CC  ld XBC,(XIZ+0x08)
	ld	(xbc+9), 0                              ; FB35CF  ld (XBC+0x09),0x00
	ld	xbc, (xiz+8)                            ; FB35D3  ld XBC,(XIZ+0x08)
	push	xbc                                   ; FB35D6  push XBC
	call	0xFA6BB5                              ; FB35D7  call 0xfa6bb5
	ld	c, e                                    ; FB35DB  ld C,E
	extz	bc                                    ; FB35DD  extz BC
	extz	xbc                                   ; FB35DF  extz XBC
	add	xbc, 10                                ; FB35E1  add XBC,0x0000000a
	extpfx3 0xAE, 0x08, 0x81                   ; FB35E7  add XBC,(XIZ+0x08)
	ld	h, (xbc)                                ; FB35EA  ld H,(XBC)
	pop	xiy                                    ; FB35EC  pop XIY
	cp	h, 64                                   ; FB35ED  cp H,0x40
	jr nc, VoiceParams_Compute_D__FB362E       ; FB35F0  jr NC,0xfb362e
	pushw	68                                   ; FB35F2  push 0x0044
	ldb	c, 68                                  ; FB35F5  ld C,0x44
	mul8rr	c, h                                ; FB35F7  mul BC,H
	ld	ix, bc                                  ; FB35F9  ld IX,BC
	ldw	wa, 0x3BCF                             ; FB35FB  ld WA,0x3bcf
	add	wa, bc                                 ; FB35FE  add WA,BC
	extz	xwa                                   ; FB3600  extz XWA
	push	xwa                                   ; FB3602  push XWA
	ldb	a, 68                                  ; FB3603  ld A,0x44
	mul8rr	a, e                                ; FB3605  mul WA,E
	ld	(xiz-10), wa                            ; FB3607  ld (XIZ+0xf6),WA
	ldw	bc, 0x5A53                             ; FB360A  ld BC,0x5a53
	add	bc, wa                                 ; FB360D  add BC,WA
	extz	xbc                                   ; FB360F  extz XBC
	push	xbc                                   ; FB3611  push XBC
	call	0xF9A038                              ; FB3612  call 0xf9a038
	extz	xix                                   ; FB3616  extz XIX
	ld	(xix+0x3BCF), h                         ; FB3618  ld (XIX+0x3bcf),H
	push	0                                     ; FB361D  push 0x00
	push	h                                     ; FB361F  push H
	push	0                                     ; FB3621  push 0x00
	extpfx3 0x8E, 0x0C, 0x04                   ; FB3623  push (XIZ+0x0c)
	call	0xFC376C                              ; FB3626  call 0xfc376c
	inc	8, xsp                                 ; FB362A  inc 0,XSP
	inc	6, xsp                                 ; FB362C  inc 6,XSP
VoiceParams_Compute_D__FB362E:
	pop	xix                                    ; FB362E  pop XIX
	popw	de                                    ; FB362F  pop DE
	popw	hl                                    ; FB3630  pop HL
	unlk32 xiz                                 ; FB3631  unlk XIZ
	ret                                        ; FB3633  ret
; ------------------------------------------------------------------------------
; MidiNote_OnTail -- 0xFB3634..0xFB3749 (278 bytes)
;
; Called from: one site, `calr 0xFB3634` at 0xFB3F75 -- MidiNote_Dispatch's
;          VELOCITY-NON-ZERO arm, immediately after MidiNote_OnByPartMode.
; Inputs:  three pushed bytes: part, note, velocity (its caller pushes
;          (XIX+0x01), (XIX+0x02), (XIX+0x03) of the packet, in that order).
; Outputs: calls VoiceParams_Compute_D (0xFB3695) then VoiceRegs_Stage_D
;          (0xFB3703) then Dev104_WriteAllChanRegs (0xFB3708), plus 0xF98CB9
;          (KeyEvents_ToLink's block, converted above), Dev10C_WriteReg (0xFB732C),
;          0xFB7A58, 0xFB7B05, 0xFA7E2C, 0xFC4BB6, 0xFC4C85 and 0xFC56C4.
; Evidence: the single caller and the arm it sits in are the whole basis for the
;          name "OnTail": MidiNote_Dispatch reaches it only when
;          `(packet[3] & 0x7F) != 0`, i.e. a non-zero MIDI velocity.  Its twin
;          MidiNote_OffTail (0xFB374A) has the same call set plus 0xFA6EFA and is
;          reached only from the other arm.
; Unknown:  ⚠ what distinguishes it from MidiNote_OffTail beyond that one extra
;          call.  Both are 278 bytes and 205 of those bytes DIFFER -- measured by
;          checker section 12, because "twin" in this block means same length and
;          same call shape and never same code.
MidiNote_OnTail:
	link32 0xEE, 0x0C, 0xEC, 0xFF              ; FB3634  link XIZ,0xffec
	pushw	hl                                   ; FB3638  push HL
	pushw	de                                   ; FB3639  push DE
	push	xix                                   ; FB363A  push XIX
	lda	xix, (0xD7A2:24)                       ; FB363B  lda XIX,0x00d7a2
	ld	bc, (xiz+8)                             ; FB3640  ld BC,(XIZ+0x08)
	extz	bc                                    ; FB3643  extz BC
	mul	bc, 0x12C                              ; FB3645  mul BC,0x012c
	ld	hl, bc                                  ; FB3649  ld HL,BC
	extz	xbc                                   ; FB364B  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB364D  ld XWA,(XBC+0x1523)
	ld	c, (xwa+16)                             ; FB3652  ld C,(XWA+0x10)
	and	c, 0xC0                                ; FB3655  and C,0xc0
	cp	c, 64                                   ; FB3658  cp C,0x40
	jrl nz, MidiNote_OnTail__FB3744            ; FB365B  jrl NZ,0xfb3744
	ld	bc, hl                                  ; FB365E  ld BC,HL
	inc	6, bc                                  ; FB3660  inc 6,BC
	extz	xbc                                   ; FB3662  extz XBC
	ld	wa, (xbc+0x1523)                        ; FB3664  ld WA,(XBC+0x1523)
	and	wa, 7                                  ; FB3669  and WA,0x0007
	jrl z, MidiNote_OnTail__FB3744             ; FB366D  jrl Z,0xfb3744
	ld	c, (xiz+12)                             ; FB3670  ld C,(XIZ+0x0c)
	and	c, 0x80                                ; FB3673  and C,0x80
	jrl nz, MidiNote_OnTail__FB3744            ; FB3676  jrl NZ,0xfb3744
	push	0                                     ; FB3679  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FB367B  push (XIZ+0x08)
	call	0xFA7E2C                              ; FB367E  call 0xfa7e2c
	push	0                                     ; FB3682  push 0x00
	extpfx3 0x8E, 0x0C, 0x04                   ; FB3684  push (XIZ+0x0c)
	push	0                                     ; FB3687  push 0x00
	extpfx3 0x8E, 0x0A, 0x04                   ; FB3689  push (XIZ+0x0a)
	push	0                                     ; FB368C  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FB368E  push (XIZ+0x08)
	lda	xbc, (xiz-14)                          ; FB3691  lda XBC,XIZ+0xf2
	push	xbc                                   ; FB3694  push XBC
	calr (0xFB31AB - 0xFB3698)                 ; FB3695  calr 0xfb31ab
	push	0                                     ; FB3698  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FB369A  push (XIZ+0x08)
	call	0xFC4BB6                              ; FB369D  call 0xfc4bb6
	ld	h, (xiz-4)                              ; FB36A1  ld H,(XIZ+0xfc)
	inc	8, xsp                                 ; FB36A4  inc 0,XSP
	inc	6, xsp                                 ; FB36A6  inc 6,XSP
	cp	h, 64                                   ; FB36A8  cp H,0x40
	jrl nc, MidiNote_OnTail__FB3744            ; FB36AB  jrl NC,0xfb3744
	ld	c, h                                    ; FB36AE  ld C,H
	extz	bc                                    ; FB36B0  extz BC
	ld	de, bc                                  ; FB36B2  ld DE,BC
	add	bc, 0x840                              ; FB36B4  add BC,0x0840
	ld	(xiz-16), bc                            ; FB36B8  ld (XIZ+0xf0),BC
	ld	xwa, 0x10C000                           ; FB36BB  ld XWA,0x0010c000
	ld	(xiz-20), xwa                           ; FB36C0  ld (XIZ+0xec),XWA
	ld	(xwa), bc                               ; FB36C3  ld (XWA),BC
	ld	xbc, (xiz-20)                           ; FB36C5  ld XBC,(XIZ+0xec)
	extpfx5 0xB9, 0x02, 0x02, 0x00, 0xFF       ; FB36C8  ld (XBC+0x02),0xff00
	nop                                        ; FB36CD  nop
	nop                                        ; FB36CE  nop
	nop                                        ; FB36CF  nop
	nop                                        ; FB36D0  nop
	nop                                        ; FB36D1  nop
	ld	bc, de                                  ; FB36D2  ld BC,DE
	add	bc, 0x800                              ; FB36D4  add BC,0x0800
	ld	(xiz-16), bc                            ; FB36D8  ld (XIZ+0xf0),BC
	ld	xwa, 0x10C000                           ; FB36DB  ld XWA,0x0010c000
	ld	(xiz-20), xwa                           ; FB36E0  ld (XIZ+0xec),XWA
	ld	(xwa), bc                               ; FB36E3  ld (XWA),BC
	ld	xbc, (xiz-20)                           ; FB36E5  ld XBC,(XIZ+0xec)
	extpfx5 0xB9, 0x02, 0x02, 0x80, 0xFF       ; FB36E8  ld (XBC+0x02),0xff80
	push	xix                                   ; FB36ED  push XIX
	push	0                                     ; FB36EE  push 0x00
	push	h                                     ; FB36F0  push H
	pushw	0                                    ; FB36F2  push 0x0000
	call	0xFC4C85                              ; FB36F5  call 0xfc4c85
	push	xix                                   ; FB36F9  push XIX
	pushw	de                                   ; FB36FA  push DE
	call	0xFB7A58                              ; FB36FB  call 0xfb7a58
	push	0                                     ; FB36FF  push 0x00
	push	h                                     ; FB3701  push H
	calr (0xFB2EB7 - 0xFB3706)                 ; FB3703  calr 0xfb2eb7
	push	xix                                   ; FB3706  push XIX
	pushw	de                                   ; FB3707  push DE
	call	0xFB77EF                              ; FB3708  call 0xfb77ef
	ldb	c, 68                                  ; FB370C  ld C,0x44
	mul8rr	c, h                                ; FB370E  mul BC,H
	add	bc, 41                                 ; FB3710  add BC,0x0029
	extz	xbc                                   ; FB3714  extz XBC
	ld	wa, (xbc+0x3BCF)                        ; FB3716  ld WA,(XBC+0x3bcf)
	pushw	wa                                   ; FB371B  push WA
	pushw	de                                   ; FB371C  push DE
	call	0xFB732C                              ; FB371D  call 0xfb732c
	push	xix                                   ; FB3721  push XIX
	push	0                                     ; FB3722  push 0x00
	push	h                                     ; FB3724  push H
	call	0xFC56C4                              ; FB3726  call 0xfc56c4
	add	xsp, 32                                ; FB372A  add XSP,0x00000020
	cps	a, 0                                   ; FB3730  cp A,0
	jr z, MidiNote_OnTail__FB3740              ; FB3732  jr Z,0xfb3740
	push	xix                                   ; FB3734  push XIX
	ld	c, h                                    ; FB3735  ld C,H
	extz	bc                                    ; FB3737  extz BC
	pushw	bc                                   ; FB3739  push BC
	call	0xFB7B05                              ; FB373A  call 0xfb7b05
	inc	6, xsp                                 ; FB373E  inc 6,XSP
MidiNote_OnTail__FB3740:
	call	0xF98CB9                              ; FB3740  call 0xf98cb9
MidiNote_OnTail__FB3744:
	pop	xix                                    ; FB3744  pop XIX
	popw	de                                    ; FB3745  pop DE
	popw	hl                                    ; FB3746  pop HL
	unlk32 xiz                                 ; FB3747  unlk XIZ
	ret                                        ; FB3749  ret
; ------------------------------------------------------------------------------
; MidiNote_OffTail -- 0xFB374A..0xFB385F (278 bytes)
;
; Called from: one site, `calr 0xFB374A` at 0xFB3F95 -- MidiNote_Dispatch's
;          VELOCITY-ZERO arm, after the query and the retire walk.
; Inputs:  part, note, velocity, as MidiNote_OnTail.
; Evidence: the twin of MidiNote_OnTail: same length, same callees plus 0xFA6EFA,
;          same VoiceParams_Compute_D (0xFB37A2) then VoiceRegs_Stage_D (0xFB3810)
;          then Dev104_WriteAllChanRegs (0xFB3815) sequence.  The name comes from
;          its one caller and the arm it is in, nothing else.
; Unknown:  ⚠ as above.
MidiNote_OffTail:
	link32 0xEE, 0x0C, 0xEC, 0xFF              ; FB374A  link XIZ,0xffec
	pushw	hl                                   ; FB374E  push HL
	pushw	de                                   ; FB374F  push DE
	push	xix                                   ; FB3750  push XIX
	lda	xix, (0xD7A2:24)                       ; FB3751  lda XIX,0x00d7a2
	ld	bc, (xiz+8)                             ; FB3756  ld BC,(XIZ+0x08)
	extz	bc                                    ; FB3759  extz BC
	mul	bc, 0x12C                              ; FB375B  mul BC,0x012c
	ld	hl, bc                                  ; FB375F  ld HL,BC
	extz	xbc                                   ; FB3761  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB3763  ld XWA,(XBC+0x1523)
	ld	c, (xwa+16)                             ; FB3768  ld C,(XWA+0x10)
	and	c, 0xC0                                ; FB376B  and C,0xc0
	cp	c, 64                                   ; FB376E  cp C,0x40
	jrl nz, MidiNote_OffTail__FB385A           ; FB3771  jrl NZ,0xfb385a
	ld	bc, hl                                  ; FB3774  ld BC,HL
	inc	6, bc                                  ; FB3776  inc 6,BC
	extz	xbc                                   ; FB3778  extz XBC
	ld	wa, (xbc+0x1523)                        ; FB377A  ld WA,(XBC+0x1523)
	and	wa, 7                                  ; FB377F  and WA,0x0007
	jrl z, MidiNote_OffTail__FB385A            ; FB3783  jrl Z,0xfb385a
	push	0                                     ; FB3786  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FB3788  push (XIZ+0x08)
	call	0xFA7E2C                              ; FB378B  call 0xfa7e2c
	push	0                                     ; FB378F  push 0x00
	extpfx3 0x8E, 0x0C, 0x04                   ; FB3791  push (XIZ+0x0c)
	push	0                                     ; FB3794  push 0x00
	extpfx3 0x8E, 0x0A, 0x04                   ; FB3796  push (XIZ+0x0a)
	push	0                                     ; FB3799  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FB379B  push (XIZ+0x08)
	lda	xbc, (xiz-14)                          ; FB379E  lda XBC,XIZ+0xf2
	push	xbc                                   ; FB37A1  push XBC
	calr (0xFB31AB - 0xFB37A5)                 ; FB37A2  calr 0xfb31ab
	push	0                                     ; FB37A5  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FB37A7  push (XIZ+0x08)
	call	0xFC4BB6                              ; FB37AA  call 0xfc4bb6
	ld	h, (xiz-3)                              ; FB37AE  ld H,(XIZ+0xfd)
	inc	8, xsp                                 ; FB37B1  inc 0,XSP
	inc	6, xsp                                 ; FB37B3  inc 6,XSP
	cp	h, 64                                   ; FB37B5  cp H,0x40
	jrl nc, MidiNote_OffTail__FB385A           ; FB37B8  jrl NC,0xfb385a
	ld	c, h                                    ; FB37BB  ld C,H
	extz	bc                                    ; FB37BD  extz BC
	ld	de, bc                                  ; FB37BF  ld DE,BC
	add	bc, 0x840                              ; FB37C1  add BC,0x0840
	ld	(xiz-16), bc                            ; FB37C5  ld (XIZ+0xf0),BC
	ld	xwa, 0x10C000                           ; FB37C8  ld XWA,0x0010c000
	ld	(xiz-20), xwa                           ; FB37CD  ld (XIZ+0xec),XWA
	ld	(xwa), bc                               ; FB37D0  ld (XWA),BC
	ld	xbc, (xiz-20)                           ; FB37D2  ld XBC,(XIZ+0xec)
	extpfx5 0xB9, 0x02, 0x02, 0x00, 0xFF       ; FB37D5  ld (XBC+0x02),0xff00
	nop                                        ; FB37DA  nop
	nop                                        ; FB37DB  nop
	nop                                        ; FB37DC  nop
	nop                                        ; FB37DD  nop
	nop                                        ; FB37DE  nop
	ld	bc, de                                  ; FB37DF  ld BC,DE
	add	bc, 0x800                              ; FB37E1  add BC,0x0800
	ld	(xiz-16), bc                            ; FB37E5  ld (XIZ+0xf0),BC
	ld	xwa, 0x10C000                           ; FB37E8  ld XWA,0x0010c000
	ld	(xiz-20), xwa                           ; FB37ED  ld (XIZ+0xec),XWA
	ld	(xwa), bc                               ; FB37F0  ld (XWA),BC
	ld	xbc, (xiz-20)                           ; FB37F2  ld XBC,(XIZ+0xec)
	extpfx5 0xB9, 0x02, 0x02, 0x80, 0xFF       ; FB37F5  ld (XBC+0x02),0xff80
	push	xix                                   ; FB37FA  push XIX
	push	0                                     ; FB37FB  push 0x00
	push	h                                     ; FB37FD  push H
	pushw	0                                    ; FB37FF  push 0x0000
	call	0xFC4C85                              ; FB3802  call 0xfc4c85
	push	xix                                   ; FB3806  push XIX
	pushw	de                                   ; FB3807  push DE
	call	0xFB7A58                              ; FB3808  call 0xfb7a58
	push	0                                     ; FB380C  push 0x00
	push	h                                     ; FB380E  push H
	calr (0xFB2EB7 - 0xFB3813)                 ; FB3810  calr 0xfb2eb7
	push	xix                                   ; FB3813  push XIX
	pushw	de                                   ; FB3814  push DE
	call	0xFB77EF                              ; FB3815  call 0xfb77ef
	ldb	c, 68                                  ; FB3819  ld C,0x44
	mul8rr	c, h                                ; FB381B  mul BC,H
	add	bc, 41                                 ; FB381D  add BC,0x0029
	extz	xbc                                   ; FB3821  extz XBC
	ld	wa, (xbc+0x3BCF)                        ; FB3823  ld WA,(XBC+0x3bcf)
	pushw	wa                                   ; FB3828  push WA
	pushw	de                                   ; FB3829  push DE
	call	0xFB732C                              ; FB382A  call 0xfb732c
	push	xix                                   ; FB382E  push XIX
	push	0                                     ; FB382F  push 0x00
	push	h                                     ; FB3831  push H
	call	0xFC56C4                              ; FB3833  call 0xfc56c4
	add	xsp, 32                                ; FB3837  add XSP,0x00000020
	cps	a, 0                                   ; FB383D  cp A,0
	jr z, MidiNote_OffTail__FB384D             ; FB383F  jr Z,0xfb384d
	push	xix                                   ; FB3841  push XIX
	ld	c, h                                    ; FB3842  ld C,H
	extz	bc                                    ; FB3844  extz BC
	pushw	bc                                   ; FB3846  push BC
	call	0xFB7B05                              ; FB3847  call 0xfb7b05
	inc	6, xsp                                 ; FB384B  inc 6,XSP
MidiNote_OffTail__FB384D:
	call	0xF98CB9                              ; FB384D  call 0xf98cb9
	push	0                                     ; FB3851  push 0x00
	push	h                                     ; FB3853  push H
	call	0xFA6EFA                              ; FB3855  call 0xfa6efa
	popw	bc                                    ; FB3859  pop BC
MidiNote_OffTail__FB385A:
	pop	xix                                    ; FB385A  pop XIX
	popw	de                                    ; FB385B  pop DE
	popw	hl                                    ; FB385C  pop HL
	unlk32 xiz                                 ; FB385D  unlk XIZ
	ret                                        ; FB385F  ret
; ------------------------------------------------------------------------------
; ★ MidiNote_OnByPartMode -- 0xFB3860..0xFB3C27 (968 bytes)
;
; Four-way switch on two bits of the part record, and the routine that pairs each
; VoiceParams_Compute_* with its VoiceRegs_Stage_*.
;
; Called from: one site, `calr 0xFB3860` at 0xFB3F66 -- MidiNote_Dispatch's
;          velocity-non-zero arm.
; Inputs:  (XIZ+0x08) part, (XIZ+0x0a) note, (XIZ+0x0c) velocity.
; Outputs: one of four arms.
; Evidence: `mul BC,0x012c` / `ld XWA,(XBC+0x1523)` / `ld C,(XWA+0x10)` /
;          `and C,0xc0` and then compares against 0x00, 0x40, 0x80 and 0xC0, with
;          the default falling into the same arm as 0xC0 (`jrl T,0xFB3C0E`).  So
;          the mode is BITS 6-7 of byte +0x10 of the part record, and there are
;          four values because two bits have four values -- not because four
;          compares were counted.
;          The arms, from the calr census (prom_c_voice_module_check.py --refs):
;              0x00  VoiceParams_Compute_A (0xFB38B7), VoiceRegs_Stage_C (0xFB3948),
;                    VoiceRegs_Stage_A (0xFB394D)
;              0x40  VoiceParams_Compute_B (0xFB3A02), VoiceRegs_Stage_B (0xFB3A7A)
;              0x80  VoiceParams_Compute_C (0xFB3B01), VoiceRegs_Stage_C (0xFB3B98)
;              0xC0  and the default: 0xFB3C0E
;          ★ ARM 0x00 IS A LOOP OVER AT MOST FOUR VOICES, which is why it names
;          two staging routines rather than one.  Its body reads the next voice
;          number from the list at (XIZ-0x18), gives up at `cp H,0x40`, drives
;          0x0010C000 directly -- register `v + 0x0840` := 0xFF00 then
;          `v + 0x0800` := 0xFF80, with the same five `nop`s of bus padding every
;          other accessor in this file carries -- and then calls
;          VoiceRegs_Stage_A or VoiceRegs_Stage_C on a Z test (0xFB3946).  The
;          loop closes with `add L,C` / `cp L,4` / `jrl C,0xFB38DD` at
;          0xFB3958-0xFB395C, so FOUR is the bound.
; Unknown:  ⚠ what part-record byte +0x10 IS.  ⚠ what arm 0xC0 does -- 0xFB3C0E is
;          inside this routine and was not traced.  ⚠ what the Z test at 0xFB3946
;          tests, i.e. what makes a voice take Stage_A rather than Stage_C.
MidiNote_OnByPartMode:
	link32 0xEE, 0x0C, 0xE8, 0xFF              ; FB3860  link XIZ,0xffe8
	pushw	hl                                   ; FB3864  push HL
	pushw	de                                   ; FB3865  push DE
	push	xix                                   ; FB3866  push XIX
	ld	bc, (xiz+8)                             ; FB3867  ld BC,(XIZ+0x08)
	extz	bc                                    ; FB386A  extz BC
	mul	bc, 0x12C                              ; FB386C  mul BC,0x012c
	extz	xbc                                   ; FB3870  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB3872  ld XWA,(XBC+0x1523)
	ld	c, (xwa+16)                             ; FB3877  ld C,(XWA+0x10)
	and	c, 0xC0                                ; FB387A  and C,0xc0
	extz	bc                                    ; FB387D  extz BC
	cps	bc, 0                                  ; FB387F  cp BC,0
	jr z, MidiNote_OnByPartMode__FB389B        ; FB3881  jr Z,0xfb389b
	cp	bc, 64                                  ; FB3883  cp BC,0x0040
	jrl z, MidiNote_OnByPartMode__FB39E6       ; FB3887  jrl Z,0xfb39e6
	cp	bc, 0x80                                ; FB388A  cp BC,0x0080
	jrl z, MidiNote_OnByPartMode__FB3AEE       ; FB388E  jrl Z,0xfb3aee
	cp	bc, 0xC0                                ; FB3891  cp BC,0x00c0
	jrl z, MidiNote_OnByPartMode__FB3C0E       ; FB3895  jrl Z,0xfb3c0e
	jrl MidiNote_OnByPartMode__FB3C0E          ; FB3898  jrl T,0xfb3c0e
MidiNote_OnByPartMode__FB389B:
	push	0                                     ; FB389B  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FB389D  push (XIZ+0x08)
	call	0xFA7E2C                              ; FB38A0  call 0xfa7e2c
	push	0                                     ; FB38A4  push 0x00
	extpfx3 0x8E, 0x0C, 0x04                   ; FB38A6  push (XIZ+0x0c)
	push	0                                     ; FB38A9  push 0x00
	extpfx3 0x8E, 0x0A, 0x04                   ; FB38AB  push (XIZ+0x0a)
	push	0                                     ; FB38AE  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FB38B0  push (XIZ+0x08)
	lda	xbc, (xiz-24)                          ; FB38B3  lda XBC,XIZ+0xe8
	push	xbc                                   ; FB38B6  push XBC
	calr (0xFB0E4F - 0xFB38BA)                 ; FB38B7  calr 0xfb0e4f
	push	0                                     ; FB38BA  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FB38BC  push (XIZ+0x08)
	call	0xFC4BB6                              ; FB38BF  call 0xfc4bb6
	ldb	l, 0                                   ; FB38C3  ld L,0x00
	ld	xix, 0x10C000                           ; FB38C5  ld XIX,0x0010c000
	ld	xbc, xix                                ; FB38CA  ld XBC,XIX
	inc	2, xbc                                 ; FB38CC  inc 2,XBC
	ld	(xiz-8), xbc                            ; FB38CE  ld (XIZ+0xf8),XBC
	ld	xwa, 10                                 ; FB38D1  ld XWA,0x0000000a
	ld	(xiz-4), xwa                            ; FB38D6  ld (XIZ+0xfc),XWA
	inc	8, xsp                                 ; FB38D9  inc 0,XSP
	inc	6, xsp                                 ; FB38DB  inc 6,XSP
MidiNote_OnByPartMode__FB38DD:
	ld	xbc, (xiz-4)                            ; FB38DD  ld XBC,(XIZ+0xfc)
	add	xbc, xiz                               ; FB38E0  add XBC,XIZ
	ld	h, (xbc-24)                             ; FB38E2  ld H,(XBC+0xe8)
	cp	h, 64                                   ; FB38E5  cp H,0x40
	jr nc, MidiNote_OnByPartMode__FB3951       ; FB38E8  jr NC,0xfb3951
	ld	c, h                                    ; FB38EA  ld C,H
	extz	bc                                    ; FB38EC  extz BC
	ld	de, bc                                  ; FB38EE  ld DE,BC
	add	bc, 0x840                              ; FB38F0  add BC,0x0840
	ld	(xix), bc                               ; FB38F4  ld (XIX),BC
	ld	xbc, (xiz-8)                            ; FB38F6  ld XBC,(XIZ+0xf8)
	extpfx4 0xB1, 0x02, 0x00, 0xFF             ; FB38F9  ld (XBC),0xff00
	nop                                        ; FB38FD  nop
	nop                                        ; FB38FE  nop
	nop                                        ; FB38FF  nop
	nop                                        ; FB3900  nop
	nop                                        ; FB3901  nop
	ld	bc, de                                  ; FB3902  ld BC,DE
	add	bc, 0x800                              ; FB3904  add BC,0x0800
	ld	(xix), bc                               ; FB3908  ld (XIX),BC
	ld	xbc, (xiz-8)                            ; FB390A  ld XBC,(XIZ+0xf8)
	extpfx4 0xB1, 0x02, 0x80, 0xFF             ; FB390D  ld (XBC),0xff80
	lda	xbc, (0xD7A2:24)                       ; FB3911  lda XBC,0x00d7a2
	push	xbc                                   ; FB3916  push XBC
	push	0                                     ; FB3917  push 0x00
	push	h                                     ; FB3919  push H
	pushw	hl                                   ; FB391B  push HL
	call	0xFC4C85                              ; FB391C  call 0xfc4c85
	lda	xbc, (0xD7A2:24)                       ; FB3920  lda XBC,0x00d7a2
	push	xbc                                   ; FB3925  push XBC
	pushw	de                                   ; FB3926  push DE
	call	0xFB7A58                              ; FB3927  call 0xfb7a58
	ldb	c, 68                                  ; FB392B  ld C,0x44
	mul8rr	c, h                                ; FB392D  mul BC,H
	inc	1, bc                                  ; FB392F  inc 1,BC
	extz	xbc                                   ; FB3931  extz XBC
	ld	wa, (xbc+0x3BCF)                        ; FB3933  ld WA,(XBC+0x3bcf)
	ld	de, wa                                  ; FB3938  ld DE,WA
	and	de, 2                                  ; FB393A  and DE,0x0002
	inc	8, xsp                                 ; FB393E  inc 0,XSP
	inc	6, xsp                                 ; FB3940  inc 6,XSP
	push	0                                     ; FB3942  push 0x00
	push	h                                     ; FB3944  push H
	jr z, MidiNote_OnByPartMode__FB394D        ; FB3946  jr Z,0xfb394d
	calr (0xFB27EE - 0xFB394B)                 ; FB3948  calr 0xfb27ee
	jr MidiNote_OnByPartMode__FB3950           ; FB394B  jr T,0xfb3950
MidiNote_OnByPartMode__FB394D:
	calr (0xFB0AD0 - 0xFB3950)                 ; FB394D  calr 0xfb0ad0
MidiNote_OnByPartMode__FB3950:
	popw	bc                                    ; FB3950  pop BC
MidiNote_OnByPartMode__FB3951:
	sub	xbc, xbc                               ; FB3951  sub XBC,XBC
	inc	1, xbc                                 ; FB3953  inc 1,XBC
	add	(xiz-4), xbc                           ; FB3955  add (XIZ+0xfc),XBC
	add	l, c                                   ; FB3958  add L,C
	cps	l, 4                                   ; FB395A  cp L,4
	jrl c, MidiNote_OnByPartMode__FB38DD       ; FB395C  jrl C,0xfb38dd
	ld	xix, 10                                 ; FB395F  ld XIX,0x0000000a
	ldb	l, 4                                   ; FB3964  ld L,0x04
MidiNote_OnByPartMode__FB3966:
	ld	xbc, xix                                ; FB3966  ld XBC,XIX
	add	xbc, xiz                               ; FB3968  add XBC,XIZ
	ld	d, (xbc-24)                             ; FB396A  ld D,(XBC+0xe8)
	cp	d, 64                                   ; FB396D  cp D,0x40
	jr nc, MidiNote_OnByPartMode__FB39DB       ; FB3970  jr NC,0xfb39db
	ld	h, d                                    ; FB3972  ld H,D
	ldb	c, 68                                  ; FB3974  ld C,0x44
	mul8rr	c, d                                ; FB3976  mul BC,D
	ld	de, bc                                  ; FB3978  ld DE,BC
	add	bc, 43                                 ; FB397A  add BC,0x002b
	extz	xbc                                   ; FB397E  extz XBC
	ld	wa, (xbc+0x3BCF)                        ; FB3980  ld WA,(XBC+0x3bcf)
	cps	wa, 0                                  ; FB3985  cp WA,0
	jr nz, MidiNote_OnByPartMode__FB39B2       ; FB3987  jr NZ,0xfb39b2
	ld	bc, de                                  ; FB3989  ld BC,DE
	inc	1, bc                                  ; FB398B  inc 1,BC
	extz	xbc                                   ; FB398D  extz XBC
	ld	wa, (xbc+0x3BCF)                        ; FB398F  ld WA,(XBC+0x3bcf)
	and	wa, 0x100                              ; FB3994  and WA,0x0100
	jr nz, MidiNote_OnByPartMode__FB39B2       ; FB3998  jr NZ,0xfb39b2
	ld	bc, de                                  ; FB399A  ld BC,DE
	add	bc, 41                                 ; FB399C  add BC,0x0029
	extz	xbc                                   ; FB39A0  extz XBC
	ld	wa, (xbc+0x3BCF)                        ; FB39A2  ld WA,(XBC+0x3bcf)
	pushw	wa                                   ; FB39A7  push WA
	ld	c, h                                    ; FB39A8  ld C,H
	extz	bc                                    ; FB39AA  extz BC
	pushw	bc                                   ; FB39AC  push BC
	call	0xFB732C                              ; FB39AD  call 0xfb732c
	pop	xiy                                    ; FB39B1  pop XIY
MidiNote_OnByPartMode__FB39B2:
	lda	xbc, (0xD7A2:24)                       ; FB39B2  lda XBC,0x00d7a2
	push	xbc                                   ; FB39B7  push XBC
	push	0                                     ; FB39B8  push 0x00
	push	h                                     ; FB39BA  push H
	call	0xFC56C4                              ; FB39BC  call 0xfc56c4
	inc	6, xsp                                 ; FB39C0  inc 6,XSP
	cps	a, 0                                   ; FB39C2  cp A,0
	jr z, MidiNote_OnByPartMode__FB39D7        ; FB39C4  jr Z,0xfb39d7
	lda	xbc, (0xD7A2:24)                       ; FB39C6  lda XBC,0x00d7a2
	push	xbc                                   ; FB39CB  push XBC
	ld	a, h                                    ; FB39CC  ld A,H
	extz	wa                                    ; FB39CE  extz WA
	pushw	wa                                   ; FB39D0  push WA
	call	0xFB7B05                              ; FB39D1  call 0xfb7b05
	inc	6, xsp                                 ; FB39D5  inc 6,XSP
MidiNote_OnByPartMode__FB39D7:
	call	0xF98CB9                              ; FB39D7  call 0xf98cb9
MidiNote_OnByPartMode__FB39DB:
	inc	1, xix                                 ; FB39DB  inc 1,XIX
	dec	1, l                                   ; FB39DD  dec 1,L
	cps	l, 0                                   ; FB39DF  cp L,0
	jr nz, MidiNote_OnByPartMode__FB3966       ; FB39E1  jr NZ,0xfb3966
	jrl MidiNote_OnByPartMode__FB3C04          ; FB39E3  jrl T,0xfb3c04
MidiNote_OnByPartMode__FB39E6:
	push	0                                     ; FB39E6  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FB39E8  push (XIZ+0x08)
	call	0xFA7E2C                              ; FB39EB  call 0xfa7e2c
	push	0                                     ; FB39EF  push 0x00
	extpfx3 0x8E, 0x0C, 0x04                   ; FB39F1  push (XIZ+0x0c)
	push	0                                     ; FB39F4  push 0x00
	extpfx3 0x8E, 0x0A, 0x04                   ; FB39F6  push (XIZ+0x0a)
	push	0                                     ; FB39F9  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FB39FB  push (XIZ+0x08)
	lda	xbc, (xiz-24)                          ; FB39FE  lda XBC,XIZ+0xe8
	push	xbc                                   ; FB3A01  push XBC
	calr (0xFB2172 - 0xFB3A05)                 ; FB3A02  calr 0xfb2172
	push	0                                     ; FB3A05  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FB3A07  push (XIZ+0x08)
	call	0xFC4BB6                              ; FB3A0A  call 0xfc4bb6
	ldb	l, 0                                   ; FB3A0E  ld L,0x00
	ld	xix, 0x10C000                           ; FB3A10  ld XIX,0x0010c000
	ld	xbc, xix                                ; FB3A15  ld XBC,XIX
	inc	2, xbc                                 ; FB3A17  inc 2,XBC
	ld	(xiz-8), xbc                            ; FB3A19  ld (XIZ+0xf8),XBC
	ld	xwa, 10                                 ; FB3A1C  ld XWA,0x0000000a
	ld	(xiz-4), xwa                            ; FB3A21  ld (XIZ+0xfc),XWA
	inc	8, xsp                                 ; FB3A24  inc 0,XSP
	inc	6, xsp                                 ; FB3A26  inc 6,XSP
MidiNote_OnByPartMode__FB3A28:
	ld	xbc, (xiz-4)                            ; FB3A28  ld XBC,(XIZ+0xfc)
	add	xbc, xiz                               ; FB3A2B  add XBC,XIZ
	ld	h, (xbc-24)                             ; FB3A2D  ld H,(XBC+0xe8)
	cp	h, 64                                   ; FB3A30  cp H,0x40
	jr nc, MidiNote_OnByPartMode__FB3A81       ; FB3A33  jr NC,0xfb3a81
	ld	c, h                                    ; FB3A35  ld C,H
	extz	bc                                    ; FB3A37  extz BC
	ld	de, bc                                  ; FB3A39  ld DE,BC
	add	bc, 0x840                              ; FB3A3B  add BC,0x0840
	ld	(xix), bc                               ; FB3A3F  ld (XIX),BC
	ld	xbc, (xiz-8)                            ; FB3A41  ld XBC,(XIZ+0xf8)
	extpfx4 0xB1, 0x02, 0x00, 0xFF             ; FB3A44  ld (XBC),0xff00
	nop                                        ; FB3A48  nop
	nop                                        ; FB3A49  nop
	nop                                        ; FB3A4A  nop
	nop                                        ; FB3A4B  nop
	nop                                        ; FB3A4C  nop
	ld	bc, de                                  ; FB3A4D  ld BC,DE
	add	bc, 0x800                              ; FB3A4F  add BC,0x0800
	ld	(xix), bc                               ; FB3A53  ld (XIX),BC
	ld	xbc, (xiz-8)                            ; FB3A55  ld XBC,(XIZ+0xf8)
	extpfx4 0xB1, 0x02, 0x80, 0xFF             ; FB3A58  ld (XBC),0xff80
	lda	xbc, (0xD7A2:24)                       ; FB3A5C  lda XBC,0x00d7a2
	push	xbc                                   ; FB3A61  push XBC
	push	0                                     ; FB3A62  push 0x00
	push	h                                     ; FB3A64  push H
	pushw	hl                                   ; FB3A66  push HL
	call	0xFC4C85                              ; FB3A67  call 0xfc4c85
	lda	xbc, (0xD7A2:24)                       ; FB3A6B  lda XBC,0x00d7a2
	push	xbc                                   ; FB3A70  push XBC
	pushw	de                                   ; FB3A71  push DE
	call	0xFB7A58                              ; FB3A72  call 0xfb7a58
	push	0                                     ; FB3A76  push 0x00
	push	h                                     ; FB3A78  push H
	calr (0xFB1EBD - 0xFB3A7D)                 ; FB3A7A  calr 0xfb1ebd
	inc	8, xsp                                 ; FB3A7D  inc 0,XSP
	inc	8, xsp                                 ; FB3A7F  inc 0,XSP
MidiNote_OnByPartMode__FB3A81:
	sub	xbc, xbc                               ; FB3A81  sub XBC,XBC
	inc	1, xbc                                 ; FB3A83  inc 1,XBC
	add	(xiz-4), xbc                           ; FB3A85  add (XIZ+0xfc),XBC
	add	l, c                                   ; FB3A88  add L,C
	cps	l, 4                                   ; FB3A8A  cp L,4
	jr c, MidiNote_OnByPartMode__FB3A28        ; FB3A8C  jr C,0xfb3a28
	ld	xix, 10                                 ; FB3A8E  ld XIX,0x0000000a
	ldb	l, 4                                   ; FB3A93  ld L,0x04
MidiNote_OnByPartMode__FB3A95:
	ld	xbc, xix                                ; FB3A95  ld XBC,XIX
	add	xbc, xiz                               ; FB3A97  add XBC,XIZ
	ld	h, (xbc-24)                             ; FB3A99  ld H,(XBC+0xe8)
	cp	h, 64                                   ; FB3A9C  cp H,0x40
	jr nc, MidiNote_OnByPartMode__FB3AE3       ; FB3A9F  jr NC,0xfb3ae3
	ldb	c, 68                                  ; FB3AA1  ld C,0x44
	mul8rr	c, h                                ; FB3AA3  mul BC,H
	add	bc, 41                                 ; FB3AA5  add BC,0x0029
	extz	xbc                                   ; FB3AA9  extz XBC
	ld	wa, (xbc+0x3BCF)                        ; FB3AAB  ld WA,(XBC+0x3bcf)
	pushw	wa                                   ; FB3AB0  push WA
	ld	c, h                                    ; FB3AB1  ld C,H
	extz	bc                                    ; FB3AB3  extz BC
	ld	de, bc                                  ; FB3AB5  ld DE,BC
	pushw	bc                                   ; FB3AB7  push BC
	call	0xFB732C                              ; FB3AB8  call 0xfb732c
	lda	xbc, (0xD7A2:24)                       ; FB3ABC  lda XBC,0x00d7a2
	push	xbc                                   ; FB3AC1  push XBC
	push	0                                     ; FB3AC2  push 0x00
	push	h                                     ; FB3AC4  push H
	call	0xFC56C4                              ; FB3AC6  call 0xfc56c4
	inc	8, xsp                                 ; FB3ACA  inc 0,XSP
	inc	2, xsp                                 ; FB3ACC  inc 2,XSP
	cps	a, 0                                   ; FB3ACE  cp A,0
	jr z, MidiNote_OnByPartMode__FB3ADF        ; FB3AD0  jr Z,0xfb3adf
	lda	xbc, (0xD7A2:24)                       ; FB3AD2  lda XBC,0x00d7a2
	push	xbc                                   ; FB3AD7  push XBC
	pushw	de                                   ; FB3AD8  push DE
	call	0xFB7B05                              ; FB3AD9  call 0xfb7b05
	inc	6, xsp                                 ; FB3ADD  inc 6,XSP
MidiNote_OnByPartMode__FB3ADF:
	call	0xF98CB9                              ; FB3ADF  call 0xf98cb9
MidiNote_OnByPartMode__FB3AE3:
	inc	1, xix                                 ; FB3AE3  inc 1,XIX
	dec	1, l                                   ; FB3AE5  dec 1,L
	cps	l, 0                                   ; FB3AE7  cp L,0
	jr nz, MidiNote_OnByPartMode__FB3A95       ; FB3AE9  jr NZ,0xfb3a95
	jrl MidiNote_OnByPartMode__FB3C04          ; FB3AEB  jrl T,0xfb3c04
MidiNote_OnByPartMode__FB3AEE:
	push	0                                     ; FB3AEE  push 0x00
	extpfx3 0x8E, 0x0C, 0x04                   ; FB3AF0  push (XIZ+0x0c)
	push	0                                     ; FB3AF3  push 0x00
	extpfx3 0x8E, 0x0A, 0x04                   ; FB3AF5  push (XIZ+0x0a)
	push	0                                     ; FB3AF8  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FB3AFA  push (XIZ+0x08)
	lda	xbc, (xiz-24)                          ; FB3AFD  lda XBC,XIZ+0xe8
	push	xbc                                   ; FB3B00  push XBC
	calr (0xFB2A98 - 0xFB3B04)                 ; FB3B01  calr 0xfb2a98
	push	0                                     ; FB3B04  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FB3B06  push (XIZ+0x08)
	call	0xFC4BB6                              ; FB3B09  call 0xfc4bb6
	ld	(xiz-9), 0                              ; FB3B0D  ld (XIZ+0xf7),0x00
	ldb	l, 0                                   ; FB3B11  ld L,0x00
	ld	xbc, 0x10C000                           ; FB3B13  ld XBC,0x0010c000
	ld	(xiz-8), xbc                            ; FB3B18  ld (XIZ+0xf8),XBC
	inc	2, xbc                                 ; FB3B1B  inc 2,XBC
	ld	(xiz-4), xbc                            ; FB3B1D  ld (XIZ+0xfc),XBC
	ld	xix, 10                                 ; FB3B20  ld XIX,0x0000000a
	inc	8, xsp                                 ; FB3B25  inc 0,XSP
	inc	4, xsp                                 ; FB3B27  inc 4,XSP
MidiNote_OnByPartMode__FB3B29:
	ld	xbc, xix                                ; FB3B29  ld XBC,XIX
	add	xbc, xiz                               ; FB3B2B  add XBC,XIZ
	ld	h, (xbc-24)                             ; FB3B2D  ld H,(XBC+0xe8)
	cp	h, 64                                   ; FB3B30  cp H,0x40
	jr nc, MidiNote_OnByPartMode__FB3B9F       ; FB3B33  jr NC,0xfb3b9f
	cp (xiz-9), 0x00                           ; FB3B35  cp (XIZ+0xf7),0x00
	jr nz, MidiNote_OnByPartMode__FB3B4D       ; FB3B39  jr NZ,0xfb3b4d
	push	0                                     ; FB3B3B  push 0x00
	push	h                                     ; FB3B3D  push H
	push	0                                     ; FB3B3F  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FB3B41  push (XIZ+0x08)
	call	0xFAB818                              ; FB3B44  call 0xfab818
	ld	(xiz-9), 1                              ; FB3B48  ld (XIZ+0xf7),0x01
	pop	xiy                                    ; FB3B4C  pop XIY
MidiNote_OnByPartMode__FB3B4D:
	ld	c, h                                    ; FB3B4D  ld C,H
	extz	bc                                    ; FB3B4F  extz BC
	ld	de, bc                                  ; FB3B51  ld DE,BC
	add	bc, 0x840                              ; FB3B53  add BC,0x0840
	ld	xwa, (xiz-8)                            ; FB3B57  ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB3B5A  ld (XWA),BC
	ld	xbc, (xiz-4)                            ; FB3B5C  ld XBC,(XIZ+0xfc)
	extpfx4 0xB1, 0x02, 0x00, 0xFF             ; FB3B5F  ld (XBC),0xff00
	nop                                        ; FB3B63  nop
	nop                                        ; FB3B64  nop
	nop                                        ; FB3B65  nop
	nop                                        ; FB3B66  nop
	nop                                        ; FB3B67  nop
	ld	bc, de                                  ; FB3B68  ld BC,DE
	add	bc, 0x800                              ; FB3B6A  add BC,0x0800
	ld	xwa, (xiz-8)                            ; FB3B6E  ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB3B71  ld (XWA),BC
	ld	xbc, (xiz-4)                            ; FB3B73  ld XBC,(XIZ+0xfc)
	extpfx4 0xB1, 0x02, 0x80, 0xFF             ; FB3B76  ld (XBC),0xff80
	lda	xbc, (0xD7A2:24)                       ; FB3B7A  lda XBC,0x00d7a2
	push	xbc                                   ; FB3B7F  push XBC
	push	0                                     ; FB3B80  push 0x00
	push	h                                     ; FB3B82  push H
	pushw	hl                                   ; FB3B84  push HL
	call	0xFC4C85                              ; FB3B85  call 0xfc4c85
	lda	xbc, (0xD7A2:24)                       ; FB3B89  lda XBC,0x00d7a2
	push	xbc                                   ; FB3B8E  push XBC
	pushw	de                                   ; FB3B8F  push DE
	call	0xFB7A58                              ; FB3B90  call 0xfb7a58
	push	0                                     ; FB3B94  push 0x00
	push	h                                     ; FB3B96  push H
	calr (0xFB27EE - 0xFB3B9B)                 ; FB3B98  calr 0xfb27ee
	inc	8, xsp                                 ; FB3B9B  inc 0,XSP
	inc	8, xsp                                 ; FB3B9D  inc 0,XSP
MidiNote_OnByPartMode__FB3B9F:
	inc	1, xix                                 ; FB3B9F  inc 1,XIX
	inc	1, l                                   ; FB3BA1  inc 1,L
	cps	l, 2                                   ; FB3BA3  cp L,2
	jr c, MidiNote_OnByPartMode__FB3B29        ; FB3BA5  jr C,0xfb3b29
	ld	xix, 10                                 ; FB3BA7  ld XIX,0x0000000a
	ldb	l, 2                                   ; FB3BAC  ld L,0x02
MidiNote_OnByPartMode__FB3BAE:
	ld	xbc, xix                                ; FB3BAE  ld XBC,XIX
	add	xbc, xiz                               ; FB3BB0  add XBC,XIZ
	ld	h, (xbc-24)                             ; FB3BB2  ld H,(XBC+0xe8)
	cp	h, 64                                   ; FB3BB5  cp H,0x40
	jr nc, MidiNote_OnByPartMode__FB3BFC       ; FB3BB8  jr NC,0xfb3bfc
	ldb	c, 68                                  ; FB3BBA  ld C,0x44
	mul8rr	c, h                                ; FB3BBC  mul BC,H
	add	bc, 41                                 ; FB3BBE  add BC,0x0029
	extz	xbc                                   ; FB3BC2  extz XBC
	ld	wa, (xbc+0x3BCF)                        ; FB3BC4  ld WA,(XBC+0x3bcf)
	pushw	wa                                   ; FB3BC9  push WA
	ld	c, h                                    ; FB3BCA  ld C,H
	extz	bc                                    ; FB3BCC  extz BC
	ld	de, bc                                  ; FB3BCE  ld DE,BC
	pushw	bc                                   ; FB3BD0  push BC
	call	0xFB732C                              ; FB3BD1  call 0xfb732c
	lda	xbc, (0xD7A2:24)                       ; FB3BD5  lda XBC,0x00d7a2
	push	xbc                                   ; FB3BDA  push XBC
	push	0                                     ; FB3BDB  push 0x00
	push	h                                     ; FB3BDD  push H
	call	0xFC56C4                              ; FB3BDF  call 0xfc56c4
	inc	8, xsp                                 ; FB3BE3  inc 0,XSP
	inc	2, xsp                                 ; FB3BE5  inc 2,XSP
	cps	a, 0                                   ; FB3BE7  cp A,0
	jr z, MidiNote_OnByPartMode__FB3BF8        ; FB3BE9  jr Z,0xfb3bf8
	lda	xbc, (0xD7A2:24)                       ; FB3BEB  lda XBC,0x00d7a2
	push	xbc                                   ; FB3BF0  push XBC
	pushw	de                                   ; FB3BF1  push DE
	call	0xFB7B05                              ; FB3BF2  call 0xfb7b05
	inc	6, xsp                                 ; FB3BF6  inc 6,XSP
MidiNote_OnByPartMode__FB3BF8:
	call	0xF98CB9                              ; FB3BF8  call 0xf98cb9
MidiNote_OnByPartMode__FB3BFC:
	inc	1, xix                                 ; FB3BFC  inc 1,XIX
	dec	1, l                                   ; FB3BFE  dec 1,L
	cps	l, 0                                   ; FB3C00  cp L,0
	jr nz, MidiNote_OnByPartMode__FB3BAE       ; FB3C02  jr NZ,0xfb3bae
MidiNote_OnByPartMode__FB3C04:
	push	0                                     ; FB3C04  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FB3C06  push (XIZ+0x08)
	call	0xFACC5A                              ; FB3C09  call 0xfacc5a
	popw	bc                                    ; FB3C0D  pop BC
MidiNote_OnByPartMode__FB3C0E:
	ld	bc, (xiz+8)                             ; FB3C0E  ld BC,(XIZ+0x08)
	extz	bc                                    ; FB3C11  extz BC
	mul	bc, 0x12C                              ; FB3C13  mul BC,0x012c
	inc	4, bc                                  ; FB3C17  inc 4,BC
	extz	xbc                                   ; FB3C19  extz XBC
	extpfx7 0xD3, 0xE5, 0x23, 0x15, 0x3C, 0xF3, 0xFF ; FB3C1B  and (XBC+0x1523),0xfff3
	pop	xix                                    ; FB3C22  pop XIX
	popw	de                                    ; FB3C23  pop DE
	popw	hl                                    ; FB3C24  pop HL
	unlk32 xiz                                 ; FB3C25  unlk XIZ
	ret                                        ; FB3C27  ret
; ------------------------------------------------------------------------------
; ★ THE SIX VoiceQuery_* ROUTINES -- 0xFB3C28..0xFB3D25
;
; One family.  Each fills the same five-byte record at RAM 0x00D815 with three
; constants and its arguments, calls 0xFA6FE0, and returns XIY = 0x00D815.  The
; record is
;       +0  u8   TAG      0x80, 0x40 or 0x00
;       +1  u16  KEY      (part << 8) | note, sometimes with bit 7 forced
;       +3  u16  MASK     0x0000, 0x007F, 0x00FF or 0x1FFF
; and 0xFA6FE0 (⚠ CORRECTED 2026-08-25: "still .incbin"; it is converted) appends
; the matching VOICE NUMBERS from +5 onward,
; terminated by a byte >= 0x40 -- which is exactly how VoiceList_RetireByMode and
; VoiceRecords_InitFromAlloc walk the result.
;
; The six differ ONLY in the three constants.  Read out of the ROM bytes by
; `python3 notes/prom_c_voice_module_check.py` section 4, which also asserts that
; these six are the only routines in the block that build the record:
;
;       routine                       tag   key                    mask
;       VoiceQuery_Tag80_PartNote     0x80  (a0<<8)|a1|0x80        0x0000
;       VoiceQuery_Tag80_Part         0x80  (a0<<8)|0x80           0x007F
;       VoiceQuery_Tag40_Part         0x40  (a0<<8)                0x007F
;       VoiceQuery_Tag00_PartBit7     0x00  (a0<<8)|0x80           0x007F
;       VoiceQuery_Tag00_Part         0x00  (a0<<8)                0x00FF
;       VoiceQuery_Tag00_All          0x00  0x0000                 0x1FFF
;
; ⚠ THE NAMES ENCODE THE CONSTANTS AND NOTHING ELSE.  What the tag selects and
; what the mask masks are properties of 0xFA6FE0, which is not converted.  What IS
; visible there: it does `and BC,0x1f00` on the mask and, when that is non-zero,
; sweeps 64 fixed-stride entries instead of indexing one part -- so bits 8-12 of
; the mask are a "any part" wildcard and 0x1FFF is the widest query of the six.
;
; VoiceQuery_Tag80_PartNote -- 0xFB3C28..0xFB3C5E (55 bytes)
; Called from: one site, `calr 0xFB3C28` at 0xFB3F82 -- MidiNote_Dispatch's
;          velocity-ZERO arm, whose result it hands straight to
;          VoiceList_RetireByMode.  That is the note-off lookup: find the voices
;          playing THIS note of THIS part.
; Inputs:  (XIZ+0x08) part, (XIZ+0x0a) note.   Outputs: XIY = 0x00D815.
VoiceQuery_Tag80_PartNote:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB3C28  link XIZ,0x0000
	pushw	hl                                   ; FB3C2C  push HL
	push	xix                                   ; FB3C2D  push XIX
	lda	xix, (0xD815:24)                       ; FB3C2E  lda XIX,0x00d815
	ld	(xix), 0x80                             ; FB3C33  ld (XIX),0x80
	ld	bc, (xiz+8)                             ; FB3C36  ld BC,(XIZ+0x08)
	extz	bc                                    ; FB3C39  extz BC
	ld	hl, bc                                  ; FB3C3B  ld HL,BC
	sll	hl, 8                                  ; FB3C3D  sll 0x08,HL
	ld	bc, (xiz+10)                            ; FB3C40  ld BC,(XIZ+0x0a)
	extz	bc                                    ; FB3C43  extz BC
	or	bc, hl                                  ; FB3C45  or BC,HL
	set	7, bc                                  ; FB3C47  set 0x07,BC
	ld	(xix+1), bc                             ; FB3C4A  ld (XIX+0x01),BC
	extpfx5 0xBC, 0x03, 0x02, 0x00, 0x00       ; FB3C4D  ld (XIX+0x03),0x0000
	push	xix                                   ; FB3C52  push XIX
	call	0xFA6FE0                              ; FB3C53  call 0xfa6fe0
	pop	xiy                                    ; FB3C57  pop XIY
	ld	xiy, xix                                ; FB3C58  ld XIY,XIX
	pop	xix                                    ; FB3C5A  pop XIX
	popw	hl                                    ; FB3C5B  pop HL
	unlk32 xiz                                 ; FB3C5C  unlk XIZ
	ret                                        ; FB3C5E  ret
; ------------------------------------------------------------------------------
; VoiceQuery_Tag80_Part -- 0xFB3C5F..0xFB3C8A (44 bytes)
; Called from: TWO sites, `call 0xFB3C5F` at 0xFAFCEB and 0xFAFF7B (both .incbin).
; Inputs:  (XIZ+0x08) part.   Outputs: XIY = 0x00D815.
; Evidence: see the family header above; tag 0x80, key (part<<8)|0x80, mask 0x007F.
VoiceQuery_Tag80_Part:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB3C5F  link XIZ,0x0000
	push	xix                                   ; FB3C63  push XIX
	lda	xix, (0xD815:24)                       ; FB3C64  lda XIX,0x00d815
	ld	(xix), 0x80                             ; FB3C69  ld (XIX),0x80
	ld	bc, (xiz+8)                             ; FB3C6C  ld BC,(XIZ+0x08)
	extz	bc                                    ; FB3C6F  extz BC
	sll	bc, 8                                  ; FB3C71  sll 0x08,BC
	set	7, bc                                  ; FB3C74  set 0x07,BC
	ld	(xix+1), bc                             ; FB3C77  ld (XIX+0x01),BC
	extpfx5 0xBC, 0x03, 0x02, 0x7F, 0x00       ; FB3C7A  ld (XIX+0x03),0x007f
	push	xix                                   ; FB3C7F  push XIX
	call	0xFA6FE0                              ; FB3C80  call 0xfa6fe0
	pop	xiy                                    ; FB3C84  pop XIY
	ld	xiy, xix                                ; FB3C85  ld XIY,XIX
	pop	xix                                    ; FB3C87  pop XIX
	unlk32 xiz                                 ; FB3C88  unlk XIZ
	ret                                        ; FB3C8A  ret
; ------------------------------------------------------------------------------
; VoiceQuery_Tag40_Part -- 0xFB3C8B..0xFB3CB3 (41 bytes)
; Called from: FIVE sites, `call 0xFB3C8B` at 0xFAEF11, 0xFAEF66, 0xFAFF1C,
;          0xFBC51C and 0xFBD5FA.
; Inputs:  (XIZ+0x08) part.   Outputs: XIY = 0x00D815.
; Evidence: the only one of the six with tag 0x40, and the only one that does NOT
;          force bit 7 of the key.
VoiceQuery_Tag40_Part:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB3C8B  link XIZ,0x0000
	push	xix                                   ; FB3C8F  push XIX
	lda	xix, (0xD815:24)                       ; FB3C90  lda XIX,0x00d815
	ld	(xix), 64                               ; FB3C95  ld (XIX),0x40
	ld	bc, (xiz+8)                             ; FB3C98  ld BC,(XIZ+0x08)
	extz	bc                                    ; FB3C9B  extz BC
	sll	bc, 8                                  ; FB3C9D  sll 0x08,BC
	ld	(xix+1), bc                             ; FB3CA0  ld (XIX+0x01),BC
	extpfx5 0xBC, 0x03, 0x02, 0x7F, 0x00       ; FB3CA3  ld (XIX+0x03),0x007f
	push	xix                                   ; FB3CA8  push XIX
	call	0xFA6FE0                              ; FB3CA9  call 0xfa6fe0
	pop	xiy                                    ; FB3CAD  pop XIY
	ld	xiy, xix                                ; FB3CAE  ld XIY,XIX
	pop	xix                                    ; FB3CB0  pop XIX
	unlk32 xiz                                 ; FB3CB1  unlk XIZ
	ret                                        ; FB3CB3  ret
; ------------------------------------------------------------------------------
; VoiceQuery_Tag00_PartBit7 -- 0xFB3CB4..0xFB3CDF (44 bytes)
; Called from: one site, `call 0xFB3CB4` at 0xFAE224.
; Inputs:  (XIZ+0x08) part.   Outputs: XIY = 0x00D815.
; Evidence: tag 0x00, key (part<<8)|0x80 -- the bit-7 that gives it its name is
;          `set 0x07,BC` at 0xFB3CC9 -- mask 0x007F.
VoiceQuery_Tag00_PartBit7:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB3CB4  link XIZ,0x0000
	push	xix                                   ; FB3CB8  push XIX
	lda	xix, (0xD815:24)                       ; FB3CB9  lda XIX,0x00d815
	ld	(xix), 0                                ; FB3CBE  ld (XIX),0x00
	ld	bc, (xiz+8)                             ; FB3CC1  ld BC,(XIZ+0x08)
	extz	bc                                    ; FB3CC4  extz BC
	sll	bc, 8                                  ; FB3CC6  sll 0x08,BC
	set	7, bc                                  ; FB3CC9  set 0x07,BC
	ld	(xix+1), bc                             ; FB3CCC  ld (XIX+0x01),BC
	extpfx5 0xBC, 0x03, 0x02, 0x7F, 0x00       ; FB3CCF  ld (XIX+0x03),0x007f
	push	xix                                   ; FB3CD4  push XIX
	call	0xFA6FE0                              ; FB3CD5  call 0xfa6fe0
	pop	xiy                                    ; FB3CD9  pop XIY
	ld	xiy, xix                                ; FB3CDA  ld XIY,XIX
	pop	xix                                    ; FB3CDC  pop XIX
	unlk32 xiz                                 ; FB3CDD  unlk XIZ
	ret                                        ; FB3CDF  ret
; ------------------------------------------------------------------------------
; VoiceQuery_Tag00_Part -- 0xFB3CE0..0xFB3D08 (41 bytes)
; Called from: TWENTY-ONE sites -- the busiest routine in the block.  0xFAB873,
;          0xFAE14C, 0xFAE19F, 0xFAE230, 0xFAE399, 0xFAE4D3, 0xFAE616, 0xFAE752,
;          0xFAE897, 0xFAE9D5 and eleven more; the full list is printed by
;          `python3 notes/prom_c_voice_module_check.py --refs`.
; Inputs:  (XIZ+0x08) part.   Outputs: XIY = 0x00D815.
; Evidence: tag 0x00, key (part<<8) with no bit forced, mask 0x00FF -- the only
;          0x00FF of the six.
VoiceQuery_Tag00_Part:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB3CE0  link XIZ,0x0000
	push	xix                                   ; FB3CE4  push XIX
	lda	xix, (0xD815:24)                       ; FB3CE5  lda XIX,0x00d815
	ld	(xix), 0                                ; FB3CEA  ld (XIX),0x00
	ld	bc, (xiz+8)                             ; FB3CED  ld BC,(XIZ+0x08)
	extz	bc                                    ; FB3CF0  extz BC
	sll	bc, 8                                  ; FB3CF2  sll 0x08,BC
	ld	(xix+1), bc                             ; FB3CF5  ld (XIX+0x01),BC
	extpfx5 0xBC, 0x03, 0x02, 0xFF, 0x00       ; FB3CF8  ld (XIX+0x03),0x00ff
	push	xix                                   ; FB3CFD  push XIX
	call	0xFA6FE0                              ; FB3CFE  call 0xfa6fe0
	pop	xiy                                    ; FB3D02  pop XIY
	ld	xiy, xix                                ; FB3D03  ld XIY,XIX
	pop	xix                                    ; FB3D05  pop XIX
	unlk32 xiz                                 ; FB3D06  unlk XIZ
	ret                                        ; FB3D08  ret
; ------------------------------------------------------------------------------
; VoiceQuery_Tag00_All -- 0xFB3D09..0xFB3D25 (29 bytes)
; Called from: FIVE sites, `call 0xFB3D09` at 0xFACA46, 0xFACAC1, 0xFB0218,
;          0xFB0278 and 0xFB0291.
; Inputs:  none -- it takes no argument at all, which is why it is 29 bytes and
;          has no stack frame.
; Outputs: XIY = 0x00D815.
; Evidence: key 0x0000 and mask 0x1FFF, the widest of the six; every bit 0xFA6FE0
;          tests with `and BC,0x1f00` is set, so this is the "every voice" query.
VoiceQuery_Tag00_All:
	push	xix                                   ; FB3D09  push XIX
	lda	xix, (0xD815:24)                       ; FB3D0A  lda XIX,0x00d815
	ld	(xix), 0                                ; FB3D0F  ld (XIX),0x00
	extpfx5 0xBC, 0x01, 0x02, 0x00, 0x00       ; FB3D12  ld (XIX+0x01),0x0000
	extpfx5 0xBC, 0x03, 0x02, 0xFF, 0x1F       ; FB3D17  ld (XIX+0x03),0x1fff
	push	xix                                   ; FB3D1C  push XIX
	call	0xFA6FE0                              ; FB3D1D  call 0xfa6fe0
	pop	xiy                                    ; FB3D21  pop XIY
	ld	xiy, xix                                ; FB3D22  ld XIY,XIX
	pop	xix                                    ; FB3D24  pop XIX
	ret                                        ; FB3D25  ret
; ------------------------------------------------------------------------------
; Voice_Retire_Mode20 -- 0xFB3D26..0xFB3DC0 (155 bytes)
;
; One of three routines that take a VOICE NUMBER, clear bit 7 of its record's +5
; byte, and hand the voice to 0xFB7345.  VoiceList_RetireByMode picks between them
; on the record's mode field.
;
; Called from: SIX sites -- `call 0xFB3D26` at 0xFAC07B, 0xFAC1E4, 0xFACA9B,
;          0xFACB33 and 0xFACB55, plus `calr` at 0xFB3F22 inside
;          VoiceList_RetireByMode's mode-0x20 (and 0x00FF) path.
; Inputs:  (XIZ+0x08) = the voice number.
; Outputs: `and (record+5),0x7f`; then either 0xFAB8CC + Dev10C_WriteReg (0xFB732C)
;          + 0xFA6EA5 and `and (record+1),0xfeff`, or 0xFABAE3 + 0xFABBFB + 0xFB7345.
; Voice record: touches voice_record[+0x01(rw), +0x05(rw), +0x23(r), +0x29(r)] -- pointer built in place.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: `ld C,0x44 / mul BC,H / ld DE,0x3bcf / add DE,BC` is the voice record;
;          the branch is on bit 8 of (record+1), and on (record+0x23) being a
;          pointer whose +9 bit 0 is set.
;          ★ "Retire" names the ONE observable all three share -- bit 7 of the
;          record's +5 byte goes to 0, and (voice, &0x00D75E) is passed to
;          0xFB7345 -- and claims nothing about the device registers, because
;          0xFB7345 is unexplained.  ⚠ CORRECTED TWICE: 2026-08-25 struck "still
;          .incbin" (it is converted), and wave 7 round 2 NAMED it
;          Dev10C_WriteSixChanRegs_FromD78A -- it commits registers 0x0800, 0x0840,
;          0x0900, 0x0940, 0x09C0 and 0x0A00 of one channel from the staging
;          struct's tail words +0x2C..+0x36, reproduced by
;          `notes/prom_c_tg_chanmap.py 0xFB7345 0xAB --pairs`.  So "claims nothing
;          about the device registers" is now too weak: retiring a voice DOES reach
;          six named registers.  What those six MEAN is still open.
;          "_Mode20" is the value of
;          `(record+1) & 0x3C` for which VoiceList_RetireByMode selects it.
; Unknown:  ⚠ what 0xFB7345, 0xFAB8CC, 0xFABAE3, 0xFABBFB, 0xFA6EA5 and 0xFB74C6
;          do.  ⚠ five of the six callers are outside this module, so the mode
;          suffix describes the selector, not a precondition they all satisfy.
Voice_Retire_Mode20:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB3D26  link XIZ,0x0000
	pushw	hl                                   ; FB3D2A  push HL
	push	xde                                   ; FB3D2B  push XDE
	pushw	ix                                   ; FB3D2C  push IX
	ld	h, (xiz+8)                              ; FB3D2D  ld H,(XIZ+0x08)
	ldb	c, 68                                  ; FB3D30  ld C,0x44
	mul8rr	c, h                                ; FB3D32  mul BC,H
	ld	ix, bc                                  ; FB3D34  ld IX,BC
	ldw	de, 0x3BCF                             ; FB3D36  ld DE,0x3bcf
	add	de, bc                                 ; FB3D39  add DE,BC
	extz	xde                                   ; FB3D3B  extz XDE
	extpfx4 0x8A, 0x05, 0x3C, 0x7F             ; FB3D3D  and (XDE+0x05),0x7f
	ld	bc, (xde+1)                             ; FB3D41  ld BC,(XDE+0x01)
	and	bc, 0x8000                             ; FB3D44  and BC,0x8000
	jr nz, Voice_Retire_Mode20__FB3D5A         ; FB3D48  jr NZ,0xfb3d5a
	extz	xde                                   ; FB3D4A  extz XDE
	ld	bc, (xde+35)                            ; FB3D4C  ld BC,(XDE+0x23)
	extz	xbc                                   ; FB3D4F  extz XBC
	ld	wa, (xbc+9)                             ; FB3D51  ld WA,(XBC+0x09)
	and	wa, 1                                  ; FB3D54  and WA,0x0001
	jr nz, Voice_Retire_Mode20__FB3DBB         ; FB3D58  jr NZ,0xfb3dbb
Voice_Retire_Mode20__FB3D5A:
	extz	xde                                   ; FB3D5A  extz XDE
	ld	bc, (xde+1)                             ; FB3D5C  ld BC,(XDE+0x01)
	ld	ix, bc                                  ; FB3D5F  ld IX,BC
	and	ix, 0x100                              ; FB3D61  and IX,0x0100
	pushw	de                                   ; FB3D65  push DE
	call	0xFAB8CC                              ; FB3D66  call 0xfab8cc
	popw	bc                                    ; FB3D6A  pop BC
	cps	ix, 0                                  ; FB3D6B  cp IX,0
	jr z, Voice_Retire_Mode20__FB3D9E          ; FB3D6D  jr Z,0xfb3d9e
	lda	xbc, (0xD75E:24)                       ; FB3D6F  lda XBC,0x00d75e
	push	xbc                                   ; FB3D74  push XBC
	ld	a, h                                    ; FB3D75  ld A,H
	extz	wa                                    ; FB3D77  extz WA
	ld	ix, wa                                  ; FB3D79  ld IX,WA
	pushw	wa                                   ; FB3D7B  push WA
	call	0xFB74C6                              ; FB3D7C  call 0xfb74c6
	extz	xde                                   ; FB3D80  extz XDE
	ld	bc, (xde+41)                            ; FB3D82  ld BC,(XDE+0x29)
	pushw	bc                                   ; FB3D85  push BC
	pushw	ix                                   ; FB3D86  push IX
	call	0xFB732C                              ; FB3D87  call 0xfb732c
	push	0                                     ; FB3D8B  push 0x00
	push	h                                     ; FB3D8D  push H
	call	0xFA6EA5                              ; FB3D8F  call 0xfa6ea5
	extpfx5 0x9A, 0x01, 0x3C, 0xFF, 0xFE       ; FB3D93  and (XDE+0x01),0xfeff
	inc	8, xsp                                 ; FB3D98  inc 0,XSP
	inc	4, xsp                                 ; FB3D9A  inc 4,XSP
	jr Voice_Retire_Mode20__FB3DBB             ; FB3D9C  jr T,0xfb3dbb
Voice_Retire_Mode20__FB3D9E:
	pushw	de                                   ; FB3D9E  push DE
	call	0xFABAE3                              ; FB3D9F  call 0xfabae3
	pushw	de                                   ; FB3DA3  push DE
	call	0xFABBFB                              ; FB3DA4  call 0xfabbfb
	lda	xbc, (0xD75E:24)                       ; FB3DA8  lda XBC,0x00d75e
	push	xbc                                   ; FB3DAD  push XBC
	ld	a, h                                    ; FB3DAE  ld A,H
	extz	wa                                    ; FB3DB0  extz WA
	pushw	wa                                   ; FB3DB2  push WA
	call	0xFB7345                              ; FB3DB3  call 0xfb7345
	inc	8, xsp                                 ; FB3DB7  inc 0,XSP
	inc	2, xsp                                 ; FB3DB9  inc 2,XSP
Voice_Retire_Mode20__FB3DBB:
	popw	ix                                    ; FB3DBB  pop IX
	pop	xde                                    ; FB3DBC  pop XDE
	popw	hl                                    ; FB3DBD  pop HL
	unlk32 xiz                                 ; FB3DBE  unlk XIZ
	ret                                        ; FB3DC0  ret
; ------------------------------------------------------------------------------
; Voice_Retire_Mode08 -- 0xFB3DC1..0xFB3E4F (143 bytes)
; Called from: TWO sites -- `call 0xFB3DC1` at 0xFADF9D, and `calr` at 0xFB3F0E
;          inside VoiceList_RetireByMode's mode-0x08 path.
; Inputs:  (XIZ+0x08) = the voice number.
; Voice record: touches voice_record[+0x01(r), +0x03(r), +0x05(rw), +0x23(r)] -- pointer built in place.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: same `and (record+5),0x7f` and the same closing
;          `push &0x00D75E / push voice / call 0xFB7345`.  Its own middle: it
;          preserves (record+0x23)->+9 across the call, clears bit 0 of it when
;          (record+3) == 3, and chooses 0xFAB9D8 or 0xFAB8CC on `cp C,3`.
; Unknown:  ⚠ as Voice_Retire_Mode20.
Voice_Retire_Mode08:
	link32 0xEE, 0x0C, 0xFE, 0xFF              ; FB3DC1  link XIZ,0xfffe
	push	xhl                                   ; FB3DC5  push XHL
	push	xde                                   ; FB3DC6  push XDE
	pushw	ix                                   ; FB3DC7  push IX
	ldb	c, 68                                  ; FB3DC8  ld C,0x44
	extpfx3 0x8E, 0x08, 0x43                   ; FB3DCA  mul BC,(XIZ+0x08)
	ld	(xiz-2), bc                             ; FB3DCD  ld (XIZ+0xfe),BC
	ldw	hl, 0x3BCF                             ; FB3DD0  ld HL,0x3bcf
	add	hl, bc                                 ; FB3DD3  add HL,BC
	extz	xhl                                   ; FB3DD5  extz XHL
	ld	de, (xhl+35)                            ; FB3DD7  ld DE,(XHL+0x23)
	extpfx4 0x8B, 0x05, 0x3C, 0x7F             ; FB3DDA  and (XHL+0x05),0x7f
	extz	xde                                   ; FB3DDE  extz XDE
	ld	ix, (xde+9)                             ; FB3DE0  ld IX,(XDE+0x09)
	ld	c, (xhl+3)                              ; FB3DE3  ld C,(XHL+0x03)
	cps	c, 3                                   ; FB3DE6  cp C,3
	jr nz, Voice_Retire_Mode08__FB3DF4         ; FB3DE8  jr NZ,0xfb3df4
	ld	bc, ix                                  ; FB3DEA  ld BC,IX
	res	0, bc                                  ; FB3DEC  res 0x00,BC
	extz	xde                                   ; FB3DEF  extz XDE
	ld	(xde+9), bc                             ; FB3DF1  ld (XDE+0x09),BC
Voice_Retire_Mode08__FB3DF4:
	extz	xhl                                   ; FB3DF4  extz XHL
	ld	bc, (xhl+1)                             ; FB3DF6  ld BC,(XHL+0x01)
	and	bc, 0x8000                             ; FB3DF9  and BC,0x8000
	jr nz, Voice_Retire_Mode08__FB3E0F         ; FB3DFD  jr NZ,0xfb3e0f
	extz	xhl                                   ; FB3DFF  extz XHL
	ld	bc, (xhl+35)                            ; FB3E01  ld BC,(XHL+0x23)
	extz	xbc                                   ; FB3E04  extz XBC
	ld	wa, (xbc+9)                             ; FB3E06  ld WA,(XBC+0x09)
	and	wa, 1                                  ; FB3E09  and WA,0x0001
	jr nz, Voice_Retire_Mode08__FB3E45         ; FB3E0D  jr NZ,0xfb3e45
Voice_Retire_Mode08__FB3E0F:
	extz	xhl                                   ; FB3E0F  extz XHL
	ld	c, (xhl+3)                              ; FB3E11  ld C,(XHL+0x03)
	ld	(xiz-2), c                              ; FB3E14  ld (XIZ+0xfe),C
	pushw	hl                                   ; FB3E17  push HL
	cps	c, 3                                   ; FB3E18  cp C,3
	jr nc, Voice_Retire_Mode08__FB3E22         ; FB3E1A  jr NC,0xfb3e22
	call	0xFAB9D8                              ; FB3E1C  call 0xfab9d8
	jr Voice_Retire_Mode08__FB3E26             ; FB3E20  jr T,0xfb3e26
Voice_Retire_Mode08__FB3E22:
	call	0xFAB8CC                              ; FB3E22  call 0xfab8cc
Voice_Retire_Mode08__FB3E26:
	popw	bc                                    ; FB3E26  pop BC
	pushw	hl                                   ; FB3E27  push HL
	call	0xFABAE3                              ; FB3E28  call 0xfabae3
	pushw	hl                                   ; FB3E2C  push HL
	call	0xFABBFB                              ; FB3E2D  call 0xfabbfb
	lda	xbc, (0xD75E:24)                       ; FB3E31  lda XBC,0x00d75e
	push	xbc                                   ; FB3E36  push XBC
	ld	wa, (xiz+8)                             ; FB3E37  ld WA,(XIZ+0x08)
	extz	wa                                    ; FB3E3A  extz WA
	pushw	wa                                   ; FB3E3C  push WA
	call	0xFB7345                              ; FB3E3D  call 0xfb7345
	inc	8, xsp                                 ; FB3E41  inc 0,XSP
	inc	2, xsp                                 ; FB3E43  inc 2,XSP
Voice_Retire_Mode08__FB3E45:
	extz	xde                                   ; FB3E45  extz XDE
	ld	(xde+9), ix                             ; FB3E47  ld (XDE+0x09),IX
	popw	ix                                    ; FB3E4A  pop IX
	pop	xde                                    ; FB3E4B  pop XDE
	pop	xhl                                    ; FB3E4C  pop XHL
	unlk32 xiz                                 ; FB3E4D  unlk XIZ
	ret                                        ; FB3E4F  ret
; ------------------------------------------------------------------------------
; Voice_Retire_Mode10 -- 0xFB3E50..0xFB3E8A (59 bytes)
; Called from: one site, `calr 0xFB3E50` at 0xFB3F17, inside
;          VoiceList_RetireByMode's mode-0x10 path.  Nothing outside the module.
; Inputs:  (XIZ+0x08) = the voice number.
; Voice record: touches voice_record[+0x05(rw), +0x43(r)] -- pointer built in place.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: the shortest of the three: `and (record+5),0x7f`, then if
;          (record+0x43) != 0 call 0xFABCF9 and 0xFB7345, else nothing.
;          0x43 is the LAST byte of the 0x44-byte record.
; Unknown:  ⚠ as above.
Voice_Retire_Mode10:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB3E50  link XIZ,0x0000
	push	xhl                                   ; FB3E54  push XHL
	pushw	de                                   ; FB3E55  push DE
	ldb	c, 68                                  ; FB3E56  ld C,0x44
	extpfx3 0x8E, 0x08, 0x43                   ; FB3E58  mul BC,(XIZ+0x08)
	ld	de, bc                                  ; FB3E5B  ld DE,BC
	ldw	hl, 0x3BCF                             ; FB3E5D  ld HL,0x3bcf
	add	hl, bc                                 ; FB3E60  add HL,BC
	extz	xhl                                   ; FB3E62  extz XHL
	extpfx4 0x8B, 0x05, 0x3C, 0x7F             ; FB3E64  and (XHL+0x05),0x7f
	ld	c, (xhl+67)                             ; FB3E68  ld C,(XHL+0x43)
	cps	c, 0                                   ; FB3E6B  cp C,0
	jr z, Voice_Retire_Mode10__FB3E86          ; FB3E6D  jr Z,0xfb3e86
	pushw	hl                                   ; FB3E6F  push HL
	call	0xFABCF9                              ; FB3E70  call 0xfabcf9
	lda	xbc, (0xD75E:24)                       ; FB3E74  lda XBC,0x00d75e
	push	xbc                                   ; FB3E79  push XBC
	ld	wa, (xiz+8)                             ; FB3E7A  ld WA,(XIZ+0x08)
	extz	wa                                    ; FB3E7D  extz WA
	pushw	wa                                   ; FB3E7F  push WA
	call	0xFB7345                              ; FB3E80  call 0xfb7345
	inc	8, xsp                                 ; FB3E84  inc 0,XSP
Voice_Retire_Mode10__FB3E86:
	popw	de                                    ; FB3E86  pop DE
	pop	xhl                                    ; FB3E87  pop XHL
	unlk32 xiz                                 ; FB3E88  unlk XIZ
	ret                                        ; FB3E8A  ret
; ------------------------------------------------------------------------------
; ★ VoiceList_RetireByMode -- 0xFB3E8B..0xFB3F35 (171 bytes)
;
; Walks the voice-number list a VoiceQuery_* left at record+5 and applies one of
; the three Voice_Retire_* routines per voice, chosen by that voice's mode field.
;
; Called from: TWO sites -- `call 0xFB3E8B` at 0xFAFF80, and `calr` at 0xFB3F86
;          inside MidiNote_Dispatch's velocity-ZERO arm, with the XIY that
;          VoiceQuery_Tag80_PartNote returned pushed as its argument.
; Inputs:  (XIZ+0x08) = the 0x00D815 record; the list starts at +5.
; Outputs: one Voice_Retire_* call per listed voice.
; Evidence: ★ THE LIST TERMINATOR IS THE VOICE BOUND.  `ld H,(XBC)` then
;          `cp H,0x40` / `jrl NC,<exit>` -- so any byte >= 0x40 ends the list, and
;          0x40 is the same 64-voice bound Dev10C_ChanReset and the record stride
;          give.  The cursor then advances by exactly 1 (`sub XBC,XBC / inc 1,XBC
;          / add (XIZ+0xfc),XBC`), so the list is one BYTE per voice.
;          The mode is `(record+1) & 0x3C` and the four cases are 0x04, 0x08,
;          0x10 and 0x20 -- four adjacent bits of a nibble-wide field, which is
;          why 0x3C and not a wider mask.  Case 0x04 is handled inline: if
;          (record+0x2B) is non-zero it sets bit 7 there; otherwise it reads
;          (record+0x2D), treats the sentinel 0x00FF as case 0x20, and otherwise
;          rewrites it as `(x & 0x9FFF) | 0x1000`.
; Unknown:  ⚠ what the mode field means, and what +0x2B/+0x2D hold.  The four
;          values are read off the compares; nothing here says a fifth is
;          impossible, only that the code has no arm for one.
VoiceList_RetireByMode:
	link32 0xEE, 0x0C, 0xFA, 0xFF              ; FB3E8B  link XIZ,0xfffa
	pushw	hl                                   ; FB3E8F  push HL
	push	xde                                   ; FB3E90  push XDE
	pushw	ix                                   ; FB3E91  push IX
	ld	xbc, (xiz+8)                            ; FB3E92  ld XBC,(XIZ+0x08)
	inc	5, xbc                                 ; FB3E95  inc 5,XBC
	ld	(xiz-4), xbc                            ; FB3E97  ld (XIZ+0xfc),XBC
	ldw	ix, 0x3BCF                             ; FB3E9A  ld IX,0x3bcf
VoiceList_RetireByMode__FB3E9D:
	ld	xbc, (xiz-4)                            ; FB3E9D  ld XBC,(XIZ+0xfc)
	ld	h, (xbc)                                ; FB3EA0  ld H,(XBC)
	cp	h, 64                                   ; FB3EA2  cp H,0x40
	jrl nc, VoiceList_RetireByMode__FB3F30     ; FB3EA5  jrl NC,0xfb3f30
	ldb	a, 68                                  ; FB3EA8  ld A,0x44
	mul8rr	a, h                                ; FB3EAA  mul WA,H
	ld	de, wa                                  ; FB3EAC  ld DE,WA
	add	de, ix                                 ; FB3EAE  add DE,IX
	extz	xde                                   ; FB3EB0  extz XDE
	ld	wa, (xde+1)                             ; FB3EB2  ld WA,(XDE+0x01)
	and	wa, 60                                 ; FB3EB5  and WA,0x003c
	cps	wa, 4                                  ; FB3EB9  cp WA,4
	jr z, VoiceList_RetireByMode__FB3ED1       ; FB3EBB  jr Z,0xfb3ed1
	cp	wa, 8                                   ; FB3EBD  cp WA,0x0008
	jr z, VoiceList_RetireByMode__FB3F0A       ; FB3EC1  jr Z,0xfb3f0a
	cp	wa, 16                                  ; FB3EC3  cp WA,0x0010
	jr z, VoiceList_RetireByMode__FB3F13       ; FB3EC7  jr Z,0xfb3f13
	cp	wa, 32                                  ; FB3EC9  cp WA,0x0020
	jr z, VoiceList_RetireByMode__FB3F1C       ; FB3ECD  jr Z,0xfb3f1c
	jr VoiceList_RetireByMode__FB3F26          ; FB3ECF  jr T,0xfb3f26
VoiceList_RetireByMode__FB3ED1:
	extz	xde                                   ; FB3ED1  extz XDE
	ld	hl, (xde+43)                            ; FB3ED3  ld HL,(XDE+0x2b)
	cps	hl, 0                                  ; FB3ED6  cp HL,0
	jr z, VoiceList_RetireByMode__FB3EE6       ; FB3ED8  jr Z,0xfb3ee6
	ld	bc, hl                                  ; FB3EDA  ld BC,HL
	set	7, bc                                  ; FB3EDC  set 0x07,BC
	extz	xde                                   ; FB3EDF  extz XDE
	ld	(xde+43), bc                            ; FB3EE1  ld (XDE+0x2b),BC
	jr VoiceList_RetireByMode__FB3F26          ; FB3EE4  jr T,0xfb3f26
VoiceList_RetireByMode__FB3EE6:
	extz	xde                                   ; FB3EE6  extz XDE
	ld	hl, (xde+45)                            ; FB3EE8  ld HL,(XDE+0x2d)
	cp	hl, 0xFF                                ; FB3EEB  cp HL,0x00ff
	jr z, VoiceList_RetireByMode__FB3F1C       ; FB3EEF  jr Z,0xfb3f1c
	ld	bc, hl                                  ; FB3EF1  ld BC,HL
	and	bc, 0x9FFF                             ; FB3EF3  and BC,0x9fff
	ld	(xiz-6), bc                             ; FB3EF7  ld (XIZ+0xfa),BC
	extz	xde                                   ; FB3EFA  extz XDE
	ld	(xde+45), bc                            ; FB3EFC  ld (XDE+0x2d),BC
	ld	bc, (xiz-6)                             ; FB3EFF  ld BC,(XIZ+0xfa)
	set	12, bc                                 ; FB3F02  set 0x0c,BC
	ld	(xde+45), bc                            ; FB3F05  ld (XDE+0x2d),BC
	jr VoiceList_RetireByMode__FB3F26          ; FB3F08  jr T,0xfb3f26
VoiceList_RetireByMode__FB3F0A:
	push	0                                     ; FB3F0A  push 0x00
	push	h                                     ; FB3F0C  push H
	calr (0xFB3DC1 - 0xFB3F11)                 ; FB3F0E  calr 0xfb3dc1
	jr VoiceList_RetireByMode__FB3F25          ; FB3F11  jr T,0xfb3f25
VoiceList_RetireByMode__FB3F13:
	push	0                                     ; FB3F13  push 0x00
	push	h                                     ; FB3F15  push H
	calr (0xFB3E50 - 0xFB3F1A)                 ; FB3F17  calr 0xfb3e50
	jr VoiceList_RetireByMode__FB3F25          ; FB3F1A  jr T,0xfb3f25
VoiceList_RetireByMode__FB3F1C:
	ld	xbc, (xiz-4)                            ; FB3F1C  ld XBC,(XIZ+0xfc)
	ld	a, (xbc)                                ; FB3F1F  ld A,(XBC)
	pushw	wa                                   ; FB3F21  push WA
	calr (0xFB3D26 - 0xFB3F25)                 ; FB3F22  calr 0xfb3d26
VoiceList_RetireByMode__FB3F25:
	popw	bc                                    ; FB3F25  pop BC
VoiceList_RetireByMode__FB3F26:
	sub	xbc, xbc                               ; FB3F26  sub XBC,XBC
	inc	1, xbc                                 ; FB3F28  inc 1,XBC
	add	(xiz-4), xbc                           ; FB3F2A  add (XIZ+0xfc),XBC
	jrl VoiceList_RetireByMode__FB3E9D         ; FB3F2D  jrl T,0xfb3e9d
VoiceList_RetireByMode__FB3F30:
	popw	ix                                    ; FB3F30  pop IX
	pop	xde                                    ; FB3F31  pop XDE
	popw	hl                                    ; FB3F32  pop HL
	unlk32 xiz                                 ; FB3F33  unlk XIZ
	ret                                        ; FB3F35  ret
; ------------------------------------------------------------------------------
; ★★ MidiNote_Dispatch -- 0xFB3F36..0xFB3F9F (106 bytes)
;
; The note handler: the routine the MIDI parser's 0x90 arm calls -- the 0x90 arm
; and no other -- and the one
; that splits note-on from note-off.
;
; Called from: TWO sites, both `call 0xFB3F36`: 0xFB0802, inside
;          MidiIn_ParseRingAndDispatch's 0x90 arm, and 0xFB0A6D, inside
;          MidiMsg_SendBootSequence.  Both push a 4-byte packet's address.
; Inputs:  (XIZ+0x08) = the packet.  packet[1] part, packet[2] note,
;          packet[3] velocity.
; Outputs: nothing directly -- it calls the on- or the off-chain.
; Evidence: ★ TWO GUARDS AND ONE SPLIT, all in the first eight instructions.
;          `ld C,(XIX+0x01)` / `cp C,0x21` / `jr NC,<return>`: packet byte [1] is
;          bounded by 0x21, which is the part count.
;          `ld C,(XIX+0x03)` / `res 0x07,C` / `cp C,0` / `jr Z,<off>`: byte [3]
;          with bit 7 masked off is the split.  A MIDI velocity is seven bits and
;          a note-on of velocity zero IS a note-off; that is what this branch is.
;          The two chains, from the calr sites:
;              velocity != 0 : `push (packet+0)&0x08` + call 0xFA5958, then
;                              MidiNote_OnByPartMode (0xFB3F66) then
;                              MidiNote_OnTail (0xFB3F75), each with
;                              (part, note, velocity) pushed
;              velocity == 0 : VoiceQuery_Tag80_PartNote (0xFB3F82) with
;                              (part, note), then VoiceList_RetireByMode
;                              (0xFB3F86) with the XIY it returned, then
;                              MidiNote_OffTail (0xFB3F95)
;          The note-off chain -- look the voices up BY PART AND NOTE, then retire
;          them -- is the reading the query's own constants already forced
;          (tag 0x80, key (part<<8)|note, mask 0x0000: the only one of the six
;          that matches on the note as well as the part).
; Unknown:  ⚠ what bit 3 of the status byte, pushed into 0xFA5958, selects.
;          ⚠ what happens for parts 0x21..0xEF: nothing.  The parser routes
;          byte [1] >= 0xF0 to a different handler and this routine drops
;          0x21-0xEF silently.
MidiNote_Dispatch:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB3F36  link XIZ,0x0000
	push	xix                                   ; FB3F3A  push XIX
	ld	xix, (xiz+8)                            ; FB3F3B  ld XIX,(XIZ+0x08)
	ld	c, (xix+1)                              ; FB3F3E  ld C,(XIX+0x01)
	cp	c, 33                                   ; FB3F41  cp C,0x21
	jr nc, MidiNote_Dispatch__FB3F9C           ; FB3F44  jr NC,0xfb3f9c
	ld	c, (xix+3)                              ; FB3F46  ld C,(XIX+0x03)
	res	7, c                                   ; FB3F49  res 0x07,C
	cps	c, 0                                   ; FB3F4C  cp C,0
	jr z, MidiNote_Dispatch__FB3F7A            ; FB3F4E  jr Z,0xfb3f7a
	ld	c, (xix)                                ; FB3F50  ld C,(XIX)
	and	c, 8                                   ; FB3F52  and C,0x08
	pushw	bc                                   ; FB3F55  push BC
	call	0xFA5958                              ; FB3F56  call 0xfa5958
	ld	c, (xix+3)                              ; FB3F5A  ld C,(XIX+0x03)
	pushw	bc                                   ; FB3F5D  push BC
	ld	c, (xix+2)                              ; FB3F5E  ld C,(XIX+0x02)
	pushw	bc                                   ; FB3F61  push BC
	ld	c, (xix+1)                              ; FB3F62  ld C,(XIX+0x01)
	pushw	bc                                   ; FB3F65  push BC
	calr (0xFB3860 - 0xFB3F69)                 ; FB3F66  calr 0xfb3860
	ld	c, (xix+3)                              ; FB3F69  ld C,(XIX+0x03)
	pushw	bc                                   ; FB3F6C  push BC
	ld	c, (xix+2)                              ; FB3F6D  ld C,(XIX+0x02)
	pushw	bc                                   ; FB3F70  push BC
	ld	c, (xix+1)                              ; FB3F71  ld C,(XIX+0x01)
	pushw	bc                                   ; FB3F74  push BC
	calr (0xFB3634 - 0xFB3F78)                 ; FB3F75  calr 0xfb3634
	jr MidiNote_Dispatch__FB3F98               ; FB3F78  jr T,0xfb3f98
MidiNote_Dispatch__FB3F7A:
	ld	c, (xix+2)                              ; FB3F7A  ld C,(XIX+0x02)
	pushw	bc                                   ; FB3F7D  push BC
	ld	c, (xix+1)                              ; FB3F7E  ld C,(XIX+0x01)
	pushw	bc                                   ; FB3F81  push BC
	calr (0xFB3C28 - 0xFB3F85)                 ; FB3F82  calr 0xfb3c28
	push	xiy                                   ; FB3F85  push XIY
	calr (0xFB3E8B - 0xFB3F89)                 ; FB3F86  calr 0xfb3e8b
	ld	c, (xix+3)                              ; FB3F89  ld C,(XIX+0x03)
	pushw	bc                                   ; FB3F8C  push BC
	ld	c, (xix+2)                              ; FB3F8D  ld C,(XIX+0x02)
	pushw	bc                                   ; FB3F90  push BC
	ld	c, (xix+1)                              ; FB3F91  ld C,(XIX+0x01)
	pushw	bc                                   ; FB3F94  push BC
	calr (0xFB374A - 0xFB3F98)                 ; FB3F95  calr 0xfb374a
MidiNote_Dispatch__FB3F98:
	inc	8, xsp                                 ; FB3F98  inc 0,XSP
	inc	6, xsp                                 ; FB3F9A  inc 6,XSP
MidiNote_Dispatch__FB3F9C:
	pop	xix                                    ; FB3F9C  pop XIX
	unlk32 xiz                                 ; FB3F9D  unlk XIZ
	ret                                        ; FB3F9F  ret
; ------------------------------------------------------------------------------
; ==============================================================================
; ★ ROUND 10 -- THE 68-BYTE VOICE RECORD AT RAM 0x003BCF, FIELD BY FIELD
; ==============================================================================
; GENERATED by `python3 notes/prom_c_record68_round10.py --emit68`, which
; re-derives every row below from this source on every run; --selftest asserts
; the text is present verbatim, so the comment cannot drift from the tracker.
;
; THE ARRAY (wave 5, FINDINGS-prom_c-voice-module.md sec 4; re-derived here):
;     base   0x3BCF  `ld DE,0x3bcf`             0xFADCCA
;     stride   0x44  `ld C,0x44` / `mul BC,H`   0xFADCD9 / 0xFADCDB
;     count    0x40  `cp H,0x40`                0xFADCD4, also the list terminator
;     0x3BCF + 64 * 0x44 = 0x4CCF -- EXACTLY the base of the 27-byte envelope
;     record array (notes/prom_c_understanding_round6.py sec 6).  They abut.
;
; THE FIELDS.  72 routines hold a pointer this round's rule proves is base +
; 0x44*index; every displacement seen on one, below the stride, is a field.
; `w` is the width, read off the other operand's register -- the only place the
; size is stated.  `dir` is what the tracker SAW.  `ctor` marks the fields
; VoiceRecords_InitFromAlloc writes.
;
;     field   w   dir     sites  rtns  ctor
;     +0x00   1   r/w       42    16  yes
;     +0x01   2   r/rw/w    29    21  yes
;     +0x03   1   r         13    11  
;     +0x04   1   r/w        9     7  yes
;     +0x05   1   r/rw/w     6     5  yes
;     +0x06   2   r/w        9     9  yes
;     +0x08   2   r/w       16    12  yes
;     +0x0A   2   r/w        6     6  
;     +0x0C   1   r/w       26    17  yes
;     +0x0D   2   r/rw/w     9     7  
;     +0x0F   4   r/w        4     4  
;     +0x13   4   r/w       10    10  yes
;     +0x17   4   r/w       32    31  yes
;     +0x1B   4   w          1     1  yes
;     +0x1F   4   r/w        9     9  yes
;     +0x23   2   r         67    34  
;     +0x25   2   r/w       39    31  yes
;     +0x27   2   r/w       11     5  
;     +0x29   2   r/w        4     4  
;     +0x2B   2   r/w       10     4  
;     +0x2D   2   r/w        7     3  
;     +0x2F   2   r/w        7     4  
;     +0x31   1   r          1     1  
;     +0x32   2   r          1     1  
;     +0x34   2   r          1     1  
;     +0x36   2   r          1     1  
;     +0x38   1   r/w        2     2  
;     +0x39   2   w          3     3  
;     +0x3B   2   r/w        9     5  
;     +0x3D   2   r/w       14     5  
;     +0x3F   2   r/w       26    16  
;     +0x41   2   r/w       24    16  
;     +0x43   1   r/w        6     4  
;
; ★ THE 33 FIELDS TILE ALL 68 BYTES -- no gap, no overlap, widths summing to the
; stride, and no offset carrying two different determinate widths.  That is the
; map's own check: a tracker inventing offsets produces overlaps and one
; mis-reading widths produces gaps.  VoiceRecords_InitFromAlloc writes the 12 fields marked
; `ctor` at those same widths, without ever walking the array -- an independent
; second reading of the same boundaries.
;
; MEANING: exactly ONE field has one.  +0x23 holds 0x1523 + 0x012C*part, the
; address of this voice's part record (`ld BC,0x1523` 0xFB0C8A,
; `ld (XHL+0x23),BC` 0xFB0CD6), which round 9's selftest already asserts.  The
; other 32 fields have an offset, a width, a direction and a site list and NO
; name, deliberately: reading a musical role out of a displacement is how this
; tree acquired five labels built on a morpheme that occurs zero times in all
; four ROM images.
;
; ⚠ THE TRACKER UNDER-REPORTS AND CANNOT SAY BY HOW MUCH.  It is blind to a
; record pointer that arrives in a register it cannot prove, is stashed in a
; stack slot, or is built by arithmetic it does not model -- `ld (XHL+0x23),BC`
; at 0xFB0CD6 really does write +0x23 and this tracker does not see it.  So a
; field's `dir` column is what the tracker SAW, never what the image does, and
; `no writer found` is a searched negative of THIS rule and of nothing else.
; ==============================================================================
; VoiceRecords_InitFromAlloc -- 0xFB3FA0..0xFB405E (191 bytes)
;
; Asks the allocator for voices and initialises each returned voice's record.
;
; Called from: one site, `call 0xFB3FA0` at 0xFAC373 (⚠ CORRECTED 2026-08-25:
;          "still .incbin"; 0xFAC373 is converted).
; Inputs:  (XIZ+0x08) = a request buffer the routine fills in itself.
; Outputs: for every voice number the allocator returns, that voice's 68-byte
;          record at 0x00003BCF gets +6 and +8 = (0x151d), +1 = 1, and +0x13 and
;          +0x17 cleared.
; Voice record: touches voice_record[+0x00(w), +0x01(w), +0x04(w), +0x05(w), +0x06(w), +0x08(w), +0x0C(w), +0x13(w), +0x17(w), +0x1B(w), +0x1F(w), +0x25(w)] -- pointer built in place.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: it writes the request as `((0x151d) >> 8) | 0x2080` at +0, 0x80 at +2
;          and zeroes at +3..+6, calls 0xFA6BB5, and then walks the result list
;          from request+0x0A with the SAME terminator test the retire walk uses:
;          `ld H,(XBC)` / `cp H,0x40` / `jrl NC,<exit>`, and `ld A,0x44` /
;          `mul WA,H` / `ld BC,0x3bcf` for the record.  0xFA6BB5 is the routine
;          the four VoiceParams_Compute_* also call, and its own prologue bounds
;          a part index with `cp A,0x21` -- the same 33 as MidiNote_Dispatch.
; Unknown:  ⚠ what (0x151d) is -- it is read three times here and is the value
;          stored into both +6 and +8 of every record.  ⚠ what 0x2080 tags.
VoiceRecords_InitFromAlloc:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FB3FA0  link XIZ,0xfffc
	pushw	hl                                   ; FB3FA4  push HL
	pushw	de                                   ; FB3FA5  push DE
	push	xix                                   ; FB3FA6  push XIX
	ld	xix, (xiz+8)                            ; FB3FA7  ld XIX,(XIZ+0x08)
	ld	bc, (0x151D:16)                       ; FB3FAA  ld BC,(0x151d)
	srl	bc, 8                                  ; FB3FAE  srl 0x08,BC
	or	bc, 0x2080                              ; FB3FB1  or BC,0x2080
	ld	(xix), bc                               ; FB3FB5  ld (XIX),BC
	ld	(xix+2), 0x80                           ; FB3FB7  ld (XIX+0x02),0x80
	ld	(xix+6), 0                              ; FB3FBB  ld (XIX+0x06),0x00
	ld	(xix+3), 0                              ; FB3FBF  ld (XIX+0x03),0x00
	ld	(xix+4), 0                              ; FB3FC3  ld (XIX+0x04),0x00
	ld	(xix+5), 0                              ; FB3FC7  ld (XIX+0x05),0x00
	push	xix                                   ; FB3FCB  push XIX
	call	0xFA6BB5                              ; FB3FCC  call 0xfa6bb5
	ld	xbc, xix                                ; FB3FD0  ld XBC,XIX
	add	xbc, 10                                ; FB3FD2  add XBC,0x0000000a
	ld	(xiz-4), xbc                            ; FB3FD8  ld (XIZ+0xfc),XBC
	ld	h, (xbc)                                ; FB3FDB  ld H,(XBC)
	pop	xiy                                    ; FB3FDD  pop XIY
	cp	h, 64                                   ; FB3FDE  cp H,0x40
	jrl nc, VoiceRecords_InitFromAlloc__FB4059 ; FB3FE1  jrl NC,0xfb4059
	ldb	a, 68                                  ; FB3FE4  ld A,0x44
	mul8rr	a, h                                ; FB3FE6  mul WA,H
	ld	de, wa                                  ; FB3FE8  ld DE,WA
	ldw	bc, 0x3BCF                             ; FB3FEA  ld BC,0x3bcf
	ld	ix, bc                                  ; FB3FED  ld IX,BC
	add	ix, wa                                 ; FB3FEF  add IX,WA
	ld	bc, (0x151D:16)                       ; FB3FF1  ld BC,(0x151d)
	extz	xix                                   ; FB3FF5  extz XIX
	ld	(xix+8), bc                             ; FB3FF7  ld (XIX+0x08),BC
	ld	bc, (0x151D:16)                       ; FB3FFA  ld BC,(0x151d)
	ld	(xix+6), bc                             ; FB3FFE  ld (XIX+0x06),BC
	extpfx5 0xBC, 0x01, 0x02, 0x01, 0x00       ; FB4001  ld (XIX+0x01),0x0001
	sub	xbc, xbc                               ; FB4006  sub XBC,XBC
	ld	(xix+19), xbc                           ; FB4008  ld (XIX+0x13),XBC
	sub	xbc, xbc                               ; FB400B  sub XBC,XBC
	ld	(xix+23), xbc                           ; FB400D  ld (XIX+0x17),XBC
	sub	xbc, xbc                               ; FB4010  sub XBC,XBC
	ld	(xix+27), xbc                           ; FB4012  ld (XIX+0x1b),XBC
	sub	xbc, xbc                               ; FB4015  sub XBC,XBC
	ld	(xix+31), xbc                           ; FB4017  ld (XIX+0x1f),XBC
	sub	bc, bc                                 ; FB401A  sub BC,BC
	ld	(xix+37), bc                            ; FB401C  ld (XIX+0x25),BC
	ld	(xix+12), 0                             ; FB401F  ld (XIX+0x0c),0x00
	ld	(xix+4), 32                             ; FB4023  ld (XIX+0x04),0x20
	ld	bc, (0x151D:16)                       ; FB4027  ld BC,(0x151d)
	srl	bc, 8                                  ; FB402B  srl 0x08,BC
	ld	(xix+5), c                              ; FB402E  ld (XIX+0x05),C
	ld	xbc, (xiz-4)                            ; FB4031  ld XBC,(XIZ+0xfc)
	ld	a, (xbc)                                ; FB4034  ld A,(XBC)
	ld	(xix), a                                ; FB4036  ld (XIX),A
	ld	(xix+3), 0                              ; FB4038  ld (XIX+0x03),0x00
	extpfx5 0xBC, 0x2B, 0x02, 0x00, 0x00       ; FB403C  ld (XIX+0x2b),0x0000
	extpfx5 0xBC, 0x2D, 0x02, 0xFF, 0x00       ; FB4041  ld (XIX+0x2d),0x00ff
	ld	(xix+49), 0                             ; FB4046  ld (XIX+0x31),0x00
	extpfx5 0xBC, 0x32, 0x02, 0x00, 0x00       ; FB404A  ld (XIX+0x32),0x0000
	extpfx5 0xBC, 0x36, 0x02, 0x00, 0x00       ; FB404F  ld (XIX+0x36),0x0000
	extpfx5 0xBC, 0x34, 0x02, 0x00, 0x00       ; FB4054  ld (XIX+0x34),0x0000
VoiceRecords_InitFromAlloc__FB4059:
	pop	xix                                    ; FB4059  pop XIX
	popw	de                                    ; FB405A  pop DE
	popw	hl                                    ; FB405B  pop HL
	unlk32 xiz                                 ; FB405C  unlk XIZ
	ret                                        ; FB405E  ret

; ==============================================================================
; 0xFB405F-0xFB6E09 -- not yet converted
; ==============================================================================
; Continues the same module: 0xFB405F is a routine start (the byte before it is
; the `ret` at 0xFB405E) and 0xFB6E09 is the byte before Dev10C_WriteAllChanRegs'
; block.  What is left here is the rest of the note engine -- 0xFB4124, 0xFB454C,
; 0xFB456F, 0xFB474E, 0xFB48F7, 0xFB49EB, 0xFB5D05 and 0xFB6272 are all called
; from the converted routines above and are all still bytes.

; ==============================================================================
; 0xFB405F-0xFB6E09 -- 55 routines, 25 computed-goto arm(s), 8 table(s), 11,691 bytes
; ==============================================================================
;
; Boundaries, read off the bytes rather than asserted:
;   0xFB405E = 0x0E (`ret`)   0xFB405F = EE 0C (`link XIZ`)
;   0xFB6E09 = 0x0E (`ret`)   0xFB6E0A = EE 0C (`link XIZ`)
;   ⚠ A `ret`/`link` pair at a cut is evidence the cut falls between
;   routines; anything else on those lines is a cut that needs reading.
;
; Call census (`python3 notes/prom_c_module_map.py 0xFB405F 0xFB6E0A`):
;   170 literal call site(s) from outside this block, 56 from inside it.
;         18  sub_FBB793
;         12  VoiceParams_Compute_A
;         12  sub_FB9B69
;         10  sub_FBC39D
;          8  VoiceParams_Compute_D
;          6  sub_FAFBEC
;          6  VoiceParams_Compute_C
;          5  sub_FB86BB
;          4  sub_FB029E
;          4  sub_FB2F74
;       ... and 52 further caller(s)
;   ⚠ Sites in code that is still `.incbin` are counted under
;   "(caller not yet converted)"; that row shrinks as conversion proceeds,
;   so every named row is a FLOOR.
;
; Computed-goto tables (`python3 notes/prom_c_jumptables.py 0xFB405F 0xFB6E0A`):
;   0xFB4B20  9 entries -- the `cp rr,8` guard and the contents walk
;             both give 9, and the word after the last entry is not a
;             plausible one.  Emitted as `.long`, not decoded.
;   0xFB4BEA  9 entries -- the `cp rr,8` guard and the contents walk
;             both give 9, and the word after the last entry is not a
;             plausible one.  Emitted as `.long`, not decoded.
;   0xFB586B  12 entries -- the `cp rr,11` guard and the contents walk
;             both give 12, and the word after the last entry is not a
;             plausible one.  Emitted as `.long`, not decoded.
;   0xFB5A13  12 entries -- the `cp rr,11` guard and the contents walk
;             both give 12, and the word after the last entry is not a
;             plausible one.  Emitted as `.long`, not decoded.
;   0xFB5E7A  12 entries -- the `cp rr,11` guard and the contents walk
;             both give 12, and the word after the last entry is not a
;             plausible one.  Emitted as `.long`, not decoded.
;   0xFB60E1  9 entries -- the `cp rr,8` guard and the contents walk
;             both give 9, and the word after the last entry is not a
;             plausible one.  Emitted as `.long`, not decoded.
;   0xFB61F3  9 entries -- the `cp rr,8` guard and the contents walk
;             both give 9, and the word after the last entry is not a
;             plausible one.  Emitted as `.long`, not decoded.
;   0xFB62EF  9 entries -- the `cp rr,8` guard and the contents walk
;             both give 9, and the word after the last entry is not a
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
;     python3 notes/gen_prom_c_block.py --start 0xFB405F --end 0xFB6E0A > /tmp/b.s
;     python3 notes/gen_prom_c_block_headers.py --start 0xFB405F --end 0xFB6E0A \
;         --labels > /tmp/b.labels
;     python3 notes/gen_prom_c_block_headers.py --start 0xFB405F --end 0xFB6E0A \
;         --headers > /tmp/b.headers
;     python3 notes/prom_c_apply_headers.py /tmp/b.s /tmp/b.labels \
;         /tmp/b.headers > /tmp/b.final.s
;     python3 notes/prom_c_verify_fragment.py c 0xFB405F /tmp/b.final.s
; ==============================================================================
; --------------------------------------------------------------------------
; sub_FB405F -- 0xFB405F..0xFB40C6 (104 bytes)
;
; Called from: no site outside this module.
;          2 site(s) inside this module:
;          0xFB434A 0xFB43E2
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFB405F-0xFB40C6
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FB405F:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB405F  link XIZ,0x0000
	pushw	hl                                   ; FB4063  push HL
	pushw	de                                   ; FB4064  push DE
	cp (xiz+8), 0x08                           ; FB4065  cp (XIZ+0x08),0x08
	jr c, sub_FB405F__FB4077                   ; FB4069  jr C,0xfb4077
	cp (xiz+8), 0x10                           ; FB406B  cp (XIZ+0x08),0x10
	jr nc, sub_FB405F__FB4077                  ; FB406F  jr NC,0xfb4077
	cp (xiz+10), 0x00                          ; FB4071  cp (XIZ+0x0a),0x00
	jr nz, sub_FB405F__FB40BF                  ; FB4075  jr NZ,0xfb40bf
sub_FB405F__FB4077:
	ld	bc, (xiz+10)                            ; FB4077  ld BC,(XIZ+0x0a)
	extz	bc                                    ; FB407A  extz BC
	extz	xbc                                   ; FB407C  extz XBC
	add	xbc, 0xFDE69D                          ; FB407E  add XBC,0x00fde69d
	ld	a, (xbc)                                ; FB4084  ld A,(XBC)
	extpfx3 0x8E, 0x0C, 0xC1                   ; FB4086  and A,(XIZ+0x0c)
	jr z, sub_FB405F__FB40BB                   ; FB4089  jr Z,0xfb40bb
	ldb	l, 0                                   ; FB408B  ld L,0x00
	ldb	h, 1                                   ; FB408D  ld H,0x01
	ld	de, (xiz+10)                            ; FB408F  ld DE,(XIZ+0x0a)
	extz	de                                    ; FB4092  extz DE
	inc	1, de                                  ; FB4094  inc 1,DE
sub_FB405F__FB4096:
	ld	c, h                                    ; FB4096  ld C,H
	extz	bc                                    ; FB4098  extz BC
	cp	bc, de                                  ; FB409A  cp BC,DE
	jr nc, sub_FB405F__FB40B7                  ; FB409C  jr NC,0xfb40b7
	ld	c, h                                    ; FB409E  ld C,H
	extz	bc                                    ; FB40A0  extz BC
	extz	xbc                                   ; FB40A2  extz XBC
	add	xbc, 0xFDE69D                          ; FB40A4  add XBC,0x00fde69d
	ld	a, (xbc)                                ; FB40AA  ld A,(XBC)
	extpfx3 0x8E, 0x0C, 0xC1                   ; FB40AC  and A,(XIZ+0x0c)
	jr z, sub_FB405F__FB40B3                   ; FB40AF  jr Z,0xfb40b3
	inc	1, l                                   ; FB40B1  inc 1,L
sub_FB405F__FB40B3:
	inc	1, h                                   ; FB40B3  inc 1,H
	jr sub_FB405F__FB4096                      ; FB40B5  jr T,0xfb4096
sub_FB405F__FB40B7:
	ld	a, l                                    ; FB40B7  ld A,L
	jr sub_FB405F__FB40C2                      ; FB40B9  jr T,0xfb40c2
sub_FB405F__FB40BB:
	ldb	a, 0xFF                                ; FB40BB  ld A,0xff
	jr sub_FB405F__FB40C2                      ; FB40BD  jr T,0xfb40c2
sub_FB405F__FB40BF:
	ld	a, (xiz+10)                             ; FB40BF  ld A,(XIZ+0x0a)
sub_FB405F__FB40C2:
	popw	de                                    ; FB40C2  pop DE
	popw	hl                                    ; FB40C3  pop HL
	unlk32 xiz                                 ; FB40C4  unlk XIZ
	ret                                        ; FB40C6  ret
; --------------------------------------------------------------------------
; sub_FB40C7 -- 0xFB40C7..0xFB4102 (60 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFB4415
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFB40C7-0xFB4102
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FB40C7:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB40C7  link XIZ,0x0000
	pushw	hl                                   ; FB40CB  push HL
	ldb	l, 0                                   ; FB40CC  ld L,0x00
	cp (xiz+8), 0x08                           ; FB40CE  cp (XIZ+0x08),0x08
	jr c, sub_FB40C7__FB40DA                   ; FB40D2  jr C,0xfb40da
	cp (xiz+8), 0x10                           ; FB40D4  cp (XIZ+0x08),0x10
	jr c, sub_FB40C7__FB40F9                   ; FB40D8  jr C,0xfb40f9
sub_FB40C7__FB40DA:
	ldb	h, 0                                   ; FB40DA  ld H,0x00
sub_FB40C7__FB40DC:
	ld	c, h                                    ; FB40DC  ld C,H
	extz	bc                                    ; FB40DE  extz BC
	extz	xbc                                   ; FB40E0  extz XBC
	add	xbc, 0xFDE69D                          ; FB40E2  add XBC,0x00fde69d
	ld	a, (xbc)                                ; FB40E8  ld A,(XBC)
	extpfx3 0x8E, 0x0A, 0xC1                   ; FB40EA  and A,(XIZ+0x0a)
	jr z, sub_FB40C7__FB40F1                   ; FB40ED  jr Z,0xfb40f1
	inc	1, l                                   ; FB40EF  inc 1,L
sub_FB40C7__FB40F1:
	inc	1, h                                   ; FB40F1  inc 1,H
	cps	h, 4                                   ; FB40F3  cp H,4
	jr c, sub_FB40C7__FB40DC                   ; FB40F5  jr C,0xfb40dc
	jr sub_FB40C7__FB40FD                      ; FB40F7  jr T,0xfb40fd
sub_FB40C7__FB40F9:
	ldb	a, 4                                   ; FB40F9  ld A,0x04
	jr sub_FB40C7__FB40FF                      ; FB40FB  jr T,0xfb40ff
sub_FB40C7__FB40FD:
	ld	a, l                                    ; FB40FD  ld A,L
sub_FB40C7__FB40FF:
	popw	hl                                    ; FB40FF  pop HL
	unlk32 xiz                                 ; FB4100  unlk XIZ
	ret                                        ; FB4102  ret
; --------------------------------------------------------------------------
; sub_FB4103 -- 0xFB4103..0xFB4123 (33 bytes)
;
; Called from: 1 site(s) outside this module:
;          0xFB9BD1 in sub_FB9B69
;          1 site(s) inside this module:
;          0xFB42D0
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFB4103-0xFB4123
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FB4103:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB4103  link XIZ,0x0000
	push	xix                                   ; FB4107  push XIX
	cp (xiz+8), 0x20                           ; FB4108  cp (XIZ+0x08),0x20
	jr c, sub_FB4103__FB4117                   ; FB410C  jr C,0xfb4117
	lda	xbc, (0x8A9B:24)                       ; FB410E  lda XBC,0x008a9b
	ld	xix, xbc                                ; FB4113  ld XIX,XBC
	jr sub_FB4103__FB411C                      ; FB4115  jr T,0xfb411c
sub_FB4103__FB4117:
	lda	xix, (0x87D2:24)                       ; FB4117  lda XIX,0x0087d2
sub_FB4103__FB411C:
	ld	xbc, xix                                ; FB411C  ld XBC,XIX
	ld	xiy, xbc                                ; FB411E  ld XIY,XBC
	pop	xix                                    ; FB4120  pop XIX
	unlk32 xiz                                 ; FB4121  unlk XIZ
	ret                                        ; FB4123  ret
; --------------------------------------------------------------------------
; ToneDB_ResolveToneRecord -- 0xFB4124..0xFB42AF (396 bytes)
;
; Called from: 13 site(s) outside this module:
;          0xFB2FB7 in sub_FB2F74, 0xFB3201 in VoiceParams_Compute_D
;          0xFB3408 in VoiceParams_Compute_D__FB33CE, 0xFB9BE5 in sub_FB9B69__FB9BDF
;          0xFBA3CC in sub_FB9B69__FBA3C6, 0xFBC779 in sub_FBC725
;          0xFBC87B in sub_FBC80E, 0xFC031B in ToneQuery_ReplyToneName
;          0xFC10C8 in sub_FC10BE, 0xFC1AC5 in ToneQuery_ReplyWholeToneRecord
;          0xFC1E92 in ToneQuery_Dispatch__FC1E72, 0xFC3881 in SoundRam_ClearFourBanks
;          0xFC395C in SoundRam_ClearFourBanks__FC3917
;          1 site(s) inside this module:
;          0xFB42DC
; Inputs:  frame `link XIZ,-12`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
;          reads 0x00D7ED, 0x00D7F1, 0x00D80D, 0x00D811
; Evidence: the listing below is the byte-identical round-trip of 0xFB4124-0xFB42AF
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Name:     resolves (bank selector, program) to a TONE RECORD pointer, from
;           prom_d or from the expansion board
; Evidence: prom_d's Q4a decodes the internal arm of this body from the ROM
;           bytes, 15 instructions at 0xFB4266-0xFB429F: directory slot
;           +0x04 (ToneDB_ToneNumBanks) indexed by row*128 + program as
;           LE16, that value scaled by 4 into slot +0x08
;           (ToneDB_ToneOffsetTable), and the LE32 it finds there added to
;           the base a SECOND time (0xFB429F) -- which is also the whole
;           argument for prom_d's offsets being file-relative. The
;           0x0010-0x001F and 0x0030+ arms run the same two-level walk
;           through 0x00D811/0x00D80D, the EXPANSION BOARD's copy of the
;           same directory (0xFB418D-0xFB41E7), selected by `ld
;           XBC,(0x00D80D) / or XBC,XBC` at 0xFB4137 and 0xFB4184 -- so the
;           board's image has prom_d's layout. Slot +0xB0
;           (ToneRec_Template_Clear) is the no-board fallback at 0xFB41F1
; Unknown:  what the caller's second argument SELECTS. The body compares it
;           against 0x08, 0x10, 0x20, 0x28 and 0x30 and takes five different
;           paths; the ranges are instruction operands and their meaning is
;           not established here
; Named:   ROUND 11, by notes/prom_c_inventory_round8.py -- it was `sub_FB4124`.
; --------------------------------------------------------------------------
ToneDB_ResolveToneRecord:
	link32 0xEE, 0x0C, 0xF4, 0xFF              ; FB4124  link XIZ,0xfff4
	pushw	hl                                   ; FB4128  push HL
	pushw	de                                   ; FB4129  push DE
	push	xix                                   ; FB412A  push XIX
	ld	de, (xiz+8)                             ; FB412B  ld DE,(XIZ+0x08)
	ld	hl, (xiz+10)                            ; FB412E  ld HL,(XIZ+0x0a)
	cp	hl, 48                                  ; FB4131  cp HL,0x0030
	jr c, ToneDB_ResolveToneRecord__FB4143                   ; FB4135  jr C,0xfb4143
	ldl_da	xbc, (0xD80D)                       ; FB4137  ld XBC,(0x00d80d)
	or	xbc, xbc                                ; FB413C  or XBC,XBC
	jrl z, ToneDB_ResolveToneRecord__FB41EC                  ; FB413E  jrl Z,0xfb41ec
	jr ToneDB_ResolveToneRecord__FB418D                      ; FB4141  jr T,0xfb418d
ToneDB_ResolveToneRecord__FB4143:
	cp	hl, 40                                  ; FB4143  cp HL,0x0028
	jr c, ToneDB_ResolveToneRecord__FB4176                   ; FB4147  jr C,0xfb4176
	ld	bc, hl                                  ; FB4149  ld BC,HL
	sub	bc, 40                                 ; FB414B  sub BC,0x0028
	add	bc, bc                                 ; FB414F  add BC,BC
	ld	hl, bc                                  ; FB4151  ld HL,BC
	and	hl, 2                                  ; FB4153  and HL,0x0002
	ld	bc, de                                  ; FB4157  ld BC,DE
	and	bc, 1                                  ; FB4159  and BC,0x0001
	or	bc, hl                                  ; FB415D  or BC,HL
	mul	bc, 4                                  ; FB415F  mul BC,0x0004
	add	xbc, 0xD7F5                            ; FB4163  add XBC,0x0000d7f5
	ld	xbc, (xbc)                              ; FB4169  ld XBC,(XBC)
	add	xbc, 0xB2D0                            ; FB416B  add XBC,0x0000b2d0
	ld	xix, xbc                                ; FB4171  ld XIX,XBC
	jrl ToneDB_ResolveToneRecord__FB42A6                     ; FB4173  jrl T,0xfb42a6
ToneDB_ResolveToneRecord__FB4176:
	cp	hl, 32                                  ; FB4176  cp HL,0x0020
	jrl nc, ToneDB_ResolveToneRecord__FB424A                 ; FB417A  jrl NC,0xfb424a
	cp	hl, 16                                  ; FB417D  cp HL,0x0010
	jrl c, ToneDB_ResolveToneRecord__FB4205                  ; FB4181  jrl C,0xfb4205
	ldl_da	xbc, (0xD80D)                       ; FB4184  ld XBC,(0x00d80d)
	or	xbc, xbc                                ; FB4189  or XBC,XBC
	jr z, ToneDB_ResolveToneRecord__FB41EC                   ; FB418B  jr Z,0xfb41ec
ToneDB_ResolveToneRecord__FB418D:
	ldl_da	xbc, (0xD811)                       ; FB418D  ld XBC,(0x00d811)
	ld	xwa, (xbc+0x6C)                         ; FB4192  ld XWA,(XBC+0x6c)
	ld	(xiz-4), xwa                            ; FB4195  ld (XIZ+0xfc),XWA
	ld	iy, hl                                  ; FB4198  ld IY,HL
	extz	xiy                                   ; FB419A  extz XIY
	add	xwa, xiy                               ; FB419C  add XWA,XIY
	addda32_24	xwa, (0xD80D)                   ; FB419E  add XWA,(0x00d80d)
	ld	c, (xwa)                                ; FB41A3  ld C,(XWA)
	extz	bc                                    ; FB41A5  extz BC
	ld	hl, bc                                  ; FB41A7  ld HL,BC
	ldl_da	xwa, (0xD811)                       ; FB41A9  ld XWA,(0x00d811)
	ld	xiy, (xwa+4)                            ; FB41AE  ld XIY,(XWA+0x04)
	ld	(xiz-8), xiy                            ; FB41B1  ld (XIZ+0xf8),XIY
	sll	bc, 7                                  ; FB41B4  sll 0x07,BC
	add	bc, de                                 ; FB41B7  add BC,DE
	add	bc, bc                                 ; FB41B9  add BC,BC
	extz	xbc                                   ; FB41BB  extz XBC
	add	xiy, xbc                               ; FB41BD  add XIY,XBC
	addda32_24	xiy, (0xD80D)                   ; FB41BF  add XIY,(0x00d80d)
	ld	hl, (xiy)                               ; FB41C4  ld HL,(XIY)
	ldl_da	xbc, (0xD811)                       ; FB41C6  ld XBC,(0x00d811)
	ld	xwa, (xbc+8)                            ; FB41CB  ld XWA,(XBC+0x08)
	ld	(xiz-12), xwa                           ; FB41CE  ld (XIZ+0xf4),XWA
	ld	iy, hl                                  ; FB41D1  ld IY,HL
	sll	iy, 2                                  ; FB41D3  sll 0x02,IY
	extz	xiy                                   ; FB41D6  extz XIY
	extpfx3 0xAE, 0xF4, 0x85                   ; FB41D8  add XIY,(XIZ+0xf4)
	addda32_24	xiy, (0xD80D)                   ; FB41DB  add XIY,(0x00d80d)
	ld	xwa, (xiy)                              ; FB41E0  ld XWA,(XIY)
	addda32_24	xwa, (0xD80D)                   ; FB41E2  add XWA,(0x00d80d)
	ld	xix, xwa                                ; FB41E7  ld XIX,XWA
	jrl ToneDB_ResolveToneRecord__FB42A6                     ; FB41E9  jrl T,0xfb42a6
ToneDB_ResolveToneRecord__FB41EC:
	ldl_da	xbc, (0xD7F1)                       ; FB41EC  ld XBC,(0x00d7f1)
	ld	xwa, (xbc+0xB0)                         ; FB41F1  ld XWA,(XBC+0x00b0)
	ld	(xiz-4), xwa                            ; FB41F6  ld (XIZ+0xfc),XWA
	ldl_da	xiy, (0xD7ED)                       ; FB41F9  ld XIY,(0x00d7ed)
	ld	xix, xwa                                ; FB41FE  ld XIX,XWA
	add	xix, xiy                               ; FB4200  add XIX,XIY
	jrl ToneDB_ResolveToneRecord__FB42A6                     ; FB4202  jrl T,0xfb42a6
ToneDB_ResolveToneRecord__FB4205:
	cp	hl, 8                                   ; FB4205  cp HL,0x0008
	jr c, ToneDB_ResolveToneRecord__FB424A                   ; FB4209  jr C,0xfb424a
	ld	bc, hl                                  ; FB420B  ld BC,HL
	dec	8, bc                                  ; FB420D  dec 0,BC
	add	bc, bc                                 ; FB420F  add BC,BC
	ld	hl, bc                                  ; FB4211  ld HL,BC
	and	hl, 2                                  ; FB4213  and HL,0x0002
	ld	bc, de                                  ; FB4217  ld BC,DE
	srl	bc, 6                                  ; FB4219  srl 0x06,BC
	and	bc, 1                                  ; FB421C  and BC,0x0001
	or	bc, hl                                  ; FB4220  or BC,HL
	ld	(xiz-2), bc                             ; FB4222  ld (XIZ+0xfe),BC
	ld	wa, de                                  ; FB4225  ld WA,DE
	and	wa, 63                                 ; FB4227  and WA,0x003f
	mul	wa, 0x2C9                              ; FB422B  mul WA,0x02c9
	add	xwa, 0x90                              ; FB422F  add XWA,0x00000090
	ld	(xiz-6), xwa                            ; FB4235  ld (XIZ+0xfa),XWA
	mul	bc, 4                                  ; FB4238  mul BC,0x0004
	add	xbc, 0xD7F5                            ; FB423C  add XBC,0x0000d7f5
	ld	xbc, (xbc)                              ; FB4242  ld XBC,(XBC)
	add	xbc, xwa                               ; FB4244  add XBC,XWA
	ld	xix, xbc                                ; FB4246  ld XIX,XBC
	jr ToneDB_ResolveToneRecord__FB42A6                      ; FB4248  jr T,0xfb42a6
ToneDB_ResolveToneRecord__FB424A:
	ldl_da	xbc, (0xD7F1)                       ; FB424A  ld XBC,(0x00d7f1)
	ld	xwa, (xbc+0x6C)                         ; FB424F  ld XWA,(XBC+0x6c)
	ld	(xiz-4), xwa                            ; FB4252  ld (XIZ+0xfc),XWA
	ld	iy, hl                                  ; FB4255  ld IY,HL
	extz	xiy                                   ; FB4257  extz XIY
	add	xwa, xiy                               ; FB4259  add XWA,XIY
	addda32_24	xwa, (0xD7ED)                   ; FB425B  add XWA,(0x00d7ed)
	ld	c, (xwa)                                ; FB4260  ld C,(XWA)
	extz	bc                                    ; FB4262  extz BC
	ld	hl, bc                                  ; FB4264  ld HL,BC
	ldl_da	xwa, (0xD7F1)                       ; FB4266  ld XWA,(0x00d7f1)
	ld	xiy, (xwa+4)                            ; FB426B  ld XIY,(XWA+0x04)
	ld	(xiz-8), xiy                            ; FB426E  ld (XIZ+0xf8),XIY
	sll	bc, 7                                  ; FB4271  sll 0x07,BC
	add	bc, de                                 ; FB4274  add BC,DE
	add	bc, bc                                 ; FB4276  add BC,BC
	extz	xbc                                   ; FB4278  extz XBC
	add	xiy, xbc                               ; FB427A  add XIY,XBC
	addda32_24	xiy, (0xD7ED)                   ; FB427C  add XIY,(0x00d7ed)
	ld	hl, (xiy)                               ; FB4281  ld HL,(XIY)
	ldl_da	xbc, (0xD7F1)                       ; FB4283  ld XBC,(0x00d7f1)
	ld	xwa, (xbc+8)                            ; FB4288  ld XWA,(XBC+0x08)
	ld	(xiz-12), xwa                           ; FB428B  ld (XIZ+0xf4),XWA
	ld	iy, hl                                  ; FB428E  ld IY,HL
	sll	iy, 2                                  ; FB4290  sll 0x02,IY
	extz	xiy                                   ; FB4293  extz XIY
	extpfx3 0xAE, 0xF4, 0x85                   ; FB4295  add XIY,(XIZ+0xf4)
	addda32_24	xiy, (0xD7ED)                   ; FB4298  add XIY,(0x00d7ed)
	ld	xwa, (xiy)                              ; FB429D  ld XWA,(XIY)
	addda32_24	xwa, (0xD7ED)                   ; FB429F  add XWA,(0x00d7ed)
	ld	xix, xwa                                ; FB42A4  ld XIX,XWA
ToneDB_ResolveToneRecord__FB42A6:
	ld	xbc, xix                                ; FB42A6  ld XBC,XIX
	ld	xiy, xbc                                ; FB42A8  ld XIY,XBC
	pop	xix                                    ; FB42AA  pop XIX
	popw	de                                    ; FB42AB  pop DE
	popw	hl                                    ; FB42AC  pop HL
	unlk32 xiz                                 ; FB42AD  unlk XIZ
	ret                                        ; FB42AF  ret
; --------------------------------------------------------------------------
; sub_FB42B0 -- 0xFB42B0..0xFB42E2 (51 bytes)
;
; Called from: 1 site(s) outside this module:
;          0xFC1BA1 in sub_FC1B6E
;          1 site(s) inside this module:
;          0xFB47DC
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C)
; Outputs: no absolute-addressed write.
; Calls:   0xFB4103 = sub_FB4103, 0xFB4124 = ToneDB_ResolveToneRecord
; Evidence: the listing below is the byte-identical round-trip of 0xFB42B0-0xFB42E2
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FB42B0:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB42B0  link XIZ,0x0000
	ld	bc, (xiz+8)                             ; FB42B4  ld BC,(XIZ+0x08)
	extz	bc                                    ; FB42B7  extz BC
	mul	bc, 0x12C                              ; FB42B9  mul BC,0x012c
	inc	4, bc                                  ; FB42BD  inc 4,BC
	extz	xbc                                   ; FB42BF  extz XBC
	ld	wa, (xbc+0x1523)                        ; FB42C1  ld WA,(XBC+0x1523)
	and	wa, 1                                  ; FB42C6  and WA,0x0001
	jr z, sub_FB42B0__FB42D6                   ; FB42CA  jr Z,0xfb42d6
	ld	c, (xiz+12)                             ; FB42CC  ld C,(XIZ+0x0c)
	pushw	bc                                   ; FB42CF  push BC
	calr (0xFB4103 - 0xFB42D3)                 ; FB42D0  calr 0xfb4103
	popw	bc                                    ; FB42D3  pop BC
	jr sub_FB42B0__FB42E0                      ; FB42D4  jr T,0xfb42e0
sub_FB42B0__FB42D6:
	extpfx3 0x9E, 0x0C, 0x04                   ; FB42D6  pushw (XIZ+0x0c)
	extpfx3 0x9E, 0x0A, 0x04                   ; FB42D9  pushw (XIZ+0x0a)
	calr (0xFB4124 - 0xFB42DF)                 ; FB42DC  calr 0xfb4124
	pop	xbc                                    ; FB42DF  pop XBC
sub_FB42B0__FB42E0:
	unlk32 xiz                                 ; FB42E0  unlk XIZ
	ret                                        ; FB42E2  ret
; --------------------------------------------------------------------------
; sub_FB42E3 -- 0xFB42E3..0xFB4323 (65 bytes)
;
; Called from: 2 site(s) outside this module:
;          0xFB9C70 in sub_FB9B69__FB9C2D, 0xFB9E8D in sub_FB9B69__FB9E4A
;          1 site(s) inside this module:
;          0xFB43B2
; Inputs:  frame `link XIZ,-4`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFB42E3-0xFB4323
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FB42E3:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FB42E3  link XIZ,0xfffc
	push	xix                                   ; FB42E7  push XIX
	cpw (xiz+12), 0x0020                       ; FB42E8  cp (XIZ+0x0c),0x0020
	jr c, sub_FB42E3__FB42F8                   ; FB42ED  jr C,0xfb42f8
	lda	xbc, (0x8C33:24)                       ; FB42EF  lda XBC,0x008c33
	ld	xix, xbc                                ; FB42F4  ld XIX,XBC
	jr sub_FB42E3__FB431C                      ; FB42F6  jr T,0xfb431c
sub_FB42E3__FB42F8:
	ldb	c, 81                                  ; FB42F8  ld C,0x51
	extpfx3 0x8E, 0x0A, 0x43                   ; FB42FA  mul BC,(XIZ+0x0a)
	extz	xbc                                   ; FB42FD  extz XBC
	add	xbc, 0xD9                              ; FB42FF  add XBC,0x000000d9
	ld	(xiz-4), xbc                            ; FB4305  ld (XIZ+0xfc),XBC
	ld	wa, (xiz+8)                             ; FB4308  ld WA,(XIZ+0x08)
	extz	wa                                    ; FB430B  extz WA
	mul	wa, 0x12C                              ; FB430D  mul WA,0x012c
	extz	xwa                                   ; FB4311  extz XWA
	ld	xiy, (xwa+0x1523)                       ; FB4313  ld XIY,(XWA+0x1523)
	add	xiy, xbc                               ; FB4318  add XIY,XBC
	ld	xix, xiy                                ; FB431A  ld XIX,XIY
sub_FB42E3__FB431C:
	ld	xbc, xix                                ; FB431C  ld XBC,XIX
	ld	xiy, xbc                                ; FB431E  ld XIY,XBC
	pop	xix                                    ; FB4320  pop XIX
	unlk32 xiz                                 ; FB4321  unlk XIZ
	ret                                        ; FB4323  ret
; --------------------------------------------------------------------------
; ToneRec_GetElementBlock -- 0xFB4324..0xFB4382 (95 bytes)
;
; Called from: 3 site(s) outside this module:
;          0xFB9C9D in sub_FB9B69__FB9C91, 0xFB9EBE in sub_FB9B69__FB9EB2
;          0xFC1B0F in ToneQuery_ReplyWholeToneRecord__FC1AEF
;          1 site(s) inside this module:
;          0xFB43C1
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0C), (XIZ+0x0E)
; Outputs: no absolute-addressed write.
;          reads 0x00D7ED, 0x00D7F1
; Calls:   0xFB405F = sub_FB405F
; Evidence: the listing below is the byte-identical round-trip of 0xFB4324-0xFB4382
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Name:     returns the 81-byte ELEMENT BLOCK of a tone record, or the
;           default block at directory slot +0xAC when the element index is
;           0xFF
; Evidence: prom_d's Q4b decodes 8 instructions at 0xFB4356-0xFB4379: `ld
;           C,0x51` (81, the element-block stride) multiplied by the element
;           index, plus 0x000000D9 (217, the record head) added to the
;           record pointer at (XIZ+0x08). The other arm, reached by `cp
;           A,0xFF / jr NZ` at 0xFB4351, takes directory slot +0xAC
;           (ToneDB_DefaultLayerParams) instead, which is what makes that
;           slot a FALLBACK. 217 + 81*N + 43*N is exactly prom_d's melodic
;           record size for N = 1..4
; Unknown:  nothing here says what any field of the element block IS
; Named:   ROUND 11, by notes/prom_c_inventory_round8.py -- it was `sub_FB4324`.
; --------------------------------------------------------------------------
ToneRec_GetElementBlock:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB4324  link XIZ,0x0000
	pushw	hl                                   ; FB4328  push HL
	push	xix                                   ; FB4329  push XIX
	cpw (xiz+14), 0x0020                       ; FB432A  cp (XIZ+0x0e),0x0020
	jr c, ToneRec_GetElementBlock__FB433A                   ; FB432F  jr C,0xfb433a
	lda	xbc, (0x8C33:24)                       ; FB4331  lda XBC,0x008c33
	ld	xiy, xbc                                ; FB4336  ld XIY,XBC
	jr ToneRec_GetElementBlock__FB437E                      ; FB4338  jr T,0xfb437e
ToneRec_GetElementBlock__FB433A:
	ld	xbc, (xiz+8)                            ; FB433A  ld XBC,(XIZ+0x08)
	ld	a, (xbc+17)                             ; FB433D  ld A,(XBC+0x11)
	pushw	wa                                   ; FB4340  push WA
	push	0                                     ; FB4341  push 0x00
	extpfx3 0x8E, 0x0C, 0x04                   ; FB4343  push (XIZ+0x0c)
	ld	a, (xiz+14)                             ; FB4346  ld A,(XIZ+0x0e)
	pushw	wa                                   ; FB4349  push WA
	calr (0xFB405F - 0xFB434D)                 ; FB434A  calr 0xfb405f
	ld	h, a                                    ; FB434D  ld H,A
	inc	6, xsp                                 ; FB434F  inc 6,XSP
	cp	a, 0xFF                                 ; FB4351  cp A,0xff
	jr nz, ToneRec_GetElementBlock__FB436D                  ; FB4354  jr NZ,0xfb436d
	ldl_da	xbc, (0xD7F1)                       ; FB4356  ld XBC,(0x00d7f1)
	ld	xwa, (xbc+0xAC)                         ; FB435B  ld XWA,(XBC+0x00ac)
	ld	xix, xwa                                ; FB4360  ld XIX,XWA
	ldl_da	xiy, (0xD7ED)                       ; FB4362  ld XIY,(0x00d7ed)
	add	xwa, xiy                               ; FB4367  add XWA,XIY
	ld	xiy, xwa                                ; FB4369  ld XIY,XWA
	jr ToneRec_GetElementBlock__FB437E                      ; FB436B  jr T,0xfb437e
ToneRec_GetElementBlock__FB436D:
	ldb	c, 81                                  ; FB436D  ld C,0x51
	mul8rr	c, h                                ; FB436F  mul BC,H
	extz	xbc                                   ; FB4371  extz XBC
	add	xbc, 0xD9                              ; FB4373  add XBC,0x000000d9
	extpfx3 0xAE, 0x08, 0x81                   ; FB4379  add XBC,(XIZ+0x08)
	ld	xiy, xbc                                ; FB437C  ld XIY,XBC
ToneRec_GetElementBlock__FB437E:
	pop	xix                                    ; FB437E  pop XIX
	popw	hl                                    ; FB437F  pop HL
	unlk32 xiz                                 ; FB4380  unlk XIZ
	ret                                        ; FB4382  ret
; --------------------------------------------------------------------------
; sub_FB4383 -- 0xFB4383..0xFB43CA (72 bytes)
;
; Called from: no site outside this module.
;          2 site(s) inside this module:
;          0xFB4837 0xFB48AD
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C)
; Outputs: no absolute-addressed write.
; Calls:   0xFB42E3 = sub_FB42E3, 0xFB4324 = ToneRec_GetElementBlock
; Evidence: the listing below is the byte-identical round-trip of 0xFB4383-0xFB43CA
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FB4383:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB4383  link XIZ,0x0000
	push	xhl                                   ; FB4387  push XHL
	pushw	de                                   ; FB4388  push DE
	ld	bc, (xiz+8)                             ; FB4389  ld BC,(XIZ+0x08)
	extz	bc                                    ; FB438C  extz BC
	mul	bc, 0x12C                              ; FB438E  mul BC,0x012c
	ld	hl, bc                                  ; FB4392  ld HL,BC
	inc	4, bc                                  ; FB4394  inc 4,BC
	extz	xbc                                   ; FB4396  extz XBC
	ld	wa, (xbc+0x1523)                        ; FB4398  ld WA,(XBC+0x1523)
	ld	de, wa                                  ; FB439D  ld DE,WA
	and	de, 1                                  ; FB439F  and DE,0x0001
	extpfx3 0x9E, 0x0C, 0x04                   ; FB43A3  pushw (XIZ+0x0c)
	push	0                                     ; FB43A6  push 0x00
	extpfx3 0x8E, 0x0A, 0x04                   ; FB43A8  push (XIZ+0x0a)
	jr z, sub_FB4383__FB43B9                   ; FB43AB  jr Z,0xfb43b9
	push	0                                     ; FB43AD  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FB43AF  push (XIZ+0x08)
	calr (0xFB42E3 - 0xFB43B5)                 ; FB43B2  calr 0xfb42e3
	inc	6, xsp                                 ; FB43B5  inc 6,XSP
	jr sub_FB4383__FB43C6                      ; FB43B7  jr T,0xfb43c6
sub_FB4383__FB43B9:
	extz	xhl                                   ; FB43B9  extz XHL
	ld	xbc, (xhl+0x1523)                       ; FB43BB  ld XBC,(XHL+0x1523)
	push	xbc                                   ; FB43C0  push XBC
	calr (0xFB4324 - 0xFB43C4)                 ; FB43C1  calr 0xfb4324
	inc	8, xsp                                 ; FB43C4  inc 0,XSP
sub_FB4383__FB43C6:
	popw	de                                    ; FB43C6  pop DE
	pop	xhl                                    ; FB43C7  pop XHL
	unlk32 xiz                                 ; FB43C8  unlk XIZ
	ret                                        ; FB43CA  ret
; --------------------------------------------------------------------------
; sub_FB43CB -- 0xFB43CB..0xFB44A4 (218 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFB44E2
; Inputs:  frame `link XIZ,-4`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C)
; Outputs: no absolute-addressed write.
;          reads 0x00D7ED, 0x00D7F1
; Calls:   0xFB405F = sub_FB405F, 0xFB40C7 = sub_FB40C7
; Evidence: the listing below is the byte-identical round-trip of 0xFB43CB-0xFB44A4
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; Refused:  REFUSED round 11.  reads slot +0xAC like ToneRec_GetElementBlock but is 82
;           instructions to its 37 and shares none of the arithmetic; a name
;           borrowed from the slot would claim a twin the diff denies.
; --------------------------------------------------------------------------
sub_FB43CB:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FB43CB  link XIZ,0xfffc
	pushw	hl                                   ; FB43CF  push HL
	push	xix                                   ; FB43D0  push XIX
	ld	xix, (xiz+12)                           ; FB43D1  ld XIX,(XIZ+0x0c)
	ld	c, (xix+17)                             ; FB43D4  ld C,(XIX+0x11)
	pushw	bc                                   ; FB43D7  push BC
	push	0                                     ; FB43D8  push 0x00
	extpfx3 0x8E, 0x0A, 0x04                   ; FB43DA  push (XIZ+0x0a)
	push	0                                     ; FB43DD  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FB43DF  push (XIZ+0x08)
	calr (0xFB405F - 0xFB43E5)                 ; FB43E2  calr 0xfb405f
	ld	h, a                                    ; FB43E5  ld H,A
	inc	6, xsp                                 ; FB43E7  inc 6,XSP
	cp	a, 0xFF                                 ; FB43E9  cp A,0xff
	jr nz, sub_FB43CB__FB440C                  ; FB43EC  jr NZ,0xfb440c
	ldl_da	xbc, (0xD7F1)                       ; FB43EE  ld XBC,(0x00d7f1)
	ld	xwa, (xbc+0xAC)                         ; FB43F3  ld XWA,(XBC+0x00ac)
	ld	xix, xwa                                ; FB43F8  ld XIX,XWA
	ldl_da	xiy, (0xD7ED)                       ; FB43FA  ld XIY,(0x00d7ed)
	add	xwa, xiy                               ; FB43FF  add XWA,XIY
	add	xwa, 81                                ; FB4401  add XWA,0x00000051
	ld	xiy, xwa                                ; FB4407  ld XIY,XWA
	jrl sub_FB43CB__FB44A0                     ; FB4409  jrl T,0xfb44a0
sub_FB43CB__FB440C:
	ld	c, (xix+17)                             ; FB440C  ld C,(XIX+0x11)
	pushw	bc                                   ; FB440F  push BC
	push	0                                     ; FB4410  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FB4412  push (XIZ+0x08)
	calr (0xFB40C7 - 0xFB4418)                 ; FB4415  calr 0xfb40c7
	extz	wa                                    ; FB4418  extz WA
	pop	xiy                                    ; FB441A  pop XIY
	cps	wa, 1                                  ; FB441B  cp WA,1
	jr z, sub_FB43CB__FB442E                   ; FB441D  jr Z,0xfb442e
	cps	wa, 2                                  ; FB441F  cp WA,2
	jr z, sub_FB43CB__FB444B                   ; FB4421  jr Z,0xfb444b
	cps	wa, 3                                  ; FB4423  cp WA,3
	jr z, sub_FB43CB__FB4468                   ; FB4425  jr Z,0xfb4468
	cps	wa, 4                                  ; FB4427  cp WA,4
	jr z, sub_FB43CB__FB4485                   ; FB4429  jr Z,0xfb4485
	jrl sub_FB43CB__FB44A0                     ; FB442B  jrl T,0xfb44a0
sub_FB43CB__FB442E:
	ld	xbc, xix                                ; FB442E  ld XBC,XIX
	add	xbc, 0xD9                              ; FB4430  add XBC,0x000000d9
	ld	(xiz-4), xbc                            ; FB4436  ld (XIZ+0xfc),XBC
	ldb	a, 43                                  ; FB4439  ld A,0x2b
	mul8rr	a, h                                ; FB443B  mul WA,H
	extz	xwa                                   ; FB443D  extz XWA
	add	xwa, 81                                ; FB443F  add XWA,0x00000051
	add	xbc, xwa                               ; FB4445  add XBC,XWA
	ld	xiy, xbc                                ; FB4447  ld XIY,XBC
	jr sub_FB43CB__FB44A0                      ; FB4449  jr T,0xfb44a0
sub_FB43CB__FB444B:
	ld	xbc, xix                                ; FB444B  ld XBC,XIX
	add	xbc, 0xD9                              ; FB444D  add XBC,0x000000d9
	ld	(xiz-4), xbc                            ; FB4453  ld (XIZ+0xfc),XBC
	ldb	a, 43                                  ; FB4456  ld A,0x2b
	mul8rr	a, h                                ; FB4458  mul WA,H
	extz	xwa                                   ; FB445A  extz XWA
	add	xwa, 0xA2                              ; FB445C  add XWA,0x000000a2
	add	xbc, xwa                               ; FB4462  add XBC,XWA
	ld	xiy, xbc                                ; FB4464  ld XIY,XBC
	jr sub_FB43CB__FB44A0                      ; FB4466  jr T,0xfb44a0
sub_FB43CB__FB4468:
	ld	xbc, xix                                ; FB4468  ld XBC,XIX
	add	xbc, 0xD9                              ; FB446A  add XBC,0x000000d9
	ld	(xiz-4), xbc                            ; FB4470  ld (XIZ+0xfc),XBC
	ldb	a, 43                                  ; FB4473  ld A,0x2b
	mul8rr	a, h                                ; FB4475  mul WA,H
	extz	xwa                                   ; FB4477  extz XWA
	add	xwa, 0xF3                              ; FB4479  add XWA,0x000000f3
	add	xbc, xwa                               ; FB447F  add XBC,XWA
	ld	xiy, xbc                                ; FB4481  ld XIY,XBC
	jr sub_FB43CB__FB44A0                      ; FB4483  jr T,0xfb44a0
sub_FB43CB__FB4485:
	ld	xbc, xix                                ; FB4485  ld XBC,XIX
	add	xbc, 0xD9                              ; FB4487  add XBC,0x000000d9
	ld	(xiz-4), xbc                            ; FB448D  ld (XIZ+0xfc),XBC
	ldb	a, 43                                  ; FB4490  ld A,0x2b
	mul8rr	a, h                                ; FB4492  mul WA,H
	extz	xwa                                   ; FB4494  extz XWA
	add	xwa, 0x144                             ; FB4496  add XWA,0x00000144
	add	xbc, xwa                               ; FB449C  add XBC,XWA
	ld	xiy, xbc                                ; FB449E  ld XIY,XBC
sub_FB43CB__FB44A0:
	pop	xix                                    ; FB44A0  pop XIX
	popw	hl                                    ; FB44A1  pop HL
	unlk32 xiz                                 ; FB44A2  unlk XIZ
	ret                                        ; FB44A4  ret
; --------------------------------------------------------------------------
; sub_FB44A5 -- 0xFB44A5..0xFB44EB (71 bytes)
;
; Called from: 5 site(s) outside this module:
;          0xFB862E in sub_FB8603, 0xFB9CB2 in sub_FB9B69__FB9C91
;          0xFB9ED3 in sub_FB9B69__FB9EB2, 0xFBC79E in sub_FBC725
;          0xFC1B46 in ToneQuery_ReplyWholeToneRecord__FC1AEF
;          1 site(s) inside this module:
;          0xFB4542
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C)
; Outputs: no absolute-addressed write.
; Calls:   0xFB43CB = sub_FB43CB
; Evidence: the listing below is the byte-identical round-trip of 0xFB44A5-0xFB44EB
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FB44A5:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB44A5  link XIZ,0x0000
	pushw	hl                                   ; FB44A9  push HL
	push	xix                                   ; FB44AA  push XIX
	ld	hl, (xiz+8)                             ; FB44AB  ld HL,(XIZ+0x08)
	cp	hl, 8                                   ; FB44AE  cp HL,0x0008
	jr c, sub_FB44A5__FB44D6                   ; FB44B2  jr C,0xfb44d6
	cp	hl, 16                                  ; FB44B4  cp HL,0x0010
	jr nc, sub_FB44A5__FB44D6                  ; FB44B8  jr NC,0xfb44d6
	ld	xix, (xiz+12)                           ; FB44BA  ld XIX,(XIZ+0x0c)
	add	xix, 0xD9                              ; FB44BD  add XIX,0x000000d9
	ldb	c, 43                                  ; FB44C3  ld C,0x2b
	extpfx3 0x8E, 0x0A, 0x43                   ; FB44C5  mul BC,(XIZ+0x0a)
	extz	xbc                                   ; FB44C8  extz XBC
	add	xbc, 0x144                             ; FB44CA  add XBC,0x00000144
	add	xbc, xix                               ; FB44D0  add XBC,XIX
	ld	xiy, xbc                                ; FB44D2  ld XIY,XBC
	jr sub_FB44A5__FB44E7                      ; FB44D4  jr T,0xfb44e7
sub_FB44A5__FB44D6:
	ld	xbc, (xiz+12)                           ; FB44D6  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FB44D9  push XBC
	push	0                                     ; FB44DA  push 0x00
	extpfx3 0x8E, 0x0A, 0x04                   ; FB44DC  push (XIZ+0x0a)
	ld	c, l                                    ; FB44DF  ld C,L
	pushw	bc                                   ; FB44E1  push BC
	calr (0xFB43CB - 0xFB44E5)                 ; FB44E2  calr 0xfb43cb
	inc	8, xsp                                 ; FB44E5  inc 0,XSP
sub_FB44A5__FB44E7:
	pop	xix                                    ; FB44E7  pop XIX
	popw	hl                                    ; FB44E8  pop HL
	unlk32 xiz                                 ; FB44E9  unlk XIZ
	ret                                        ; FB44EB  ret
; --------------------------------------------------------------------------
; sub_FB44EC -- 0xFB44EC..0xFB454B (96 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFB485C
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Calls:   0xFB44A5 = sub_FB44A5
; Evidence: the listing below is the byte-identical round-trip of 0xFB44EC-0xFB454B
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FB44EC:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB44EC  link XIZ,0x0000
	pushw	hl                                   ; FB44F0  push HL
	push	xix                                   ; FB44F1  push XIX
	lda	xix, (0x1523:16)                      ; FB44F2  lda XIX,0x1523
	ld	bc, (xiz+8)                             ; FB44F6  ld BC,(XIZ+0x08)
	extz	bc                                    ; FB44F9  extz BC
	mul	bc, 0x12C                              ; FB44FB  mul BC,0x012c
	ld	hl, bc                                  ; FB44FF  ld HL,BC
	inc	4, bc                                  ; FB4501  inc 4,BC
	extz	xix                                   ; FB4503  extz XIX
	extpfx5 0xD3, 0x07, 0xF0, 0xE4, 0x20       ; FB4505  ld WA,(XIX+BC)
	and	wa, 1                                  ; FB450A  and WA,0x0001
	jr z, sub_FB44EC__FB4527                   ; FB450E  jr Z,0xfb4527
	ldb	c, 43                                  ; FB4510  ld C,0x2b
	extpfx3 0x8E, 0x0A, 0x43                   ; FB4512  mul BC,(XIZ+0x0a)
	extz	xbc                                   ; FB4515  extz XBC
	add	xbc, 0x21D                             ; FB4517  add XBC,0x0000021d
	add	xbc, 0x87D2                            ; FB451D  add XBC,0x000087d2
	ld	xiy, xbc                                ; FB4523  ld XIY,XBC
	jr sub_FB44EC__FB4547                      ; FB4525  jr T,0xfb4547
sub_FB44EC__FB4527:
	extz	xix                                   ; FB4527  extz XIX
	extpfx5 0xE3, 0x07, 0xF0, 0xEC, 0x21       ; FB4529  ld XBC,(XIX+HL)
	push	xbc                                   ; FB452E  push XBC
	push	0                                     ; FB452F  push 0x00
	extpfx3 0x8E, 0x0A, 0x04                   ; FB4531  push (XIZ+0x0a)
	ld	bc, hl                                  ; FB4534  ld BC,HL
	add	bc, 28                                 ; FB4536  add BC,0x001c
	extpfx5 0xC3, 0x07, 0xF0, 0xE4, 0x21       ; FB453A  ld A,(XIX+BC)
	extz	wa                                    ; FB453F  extz WA
	pushw	wa                                   ; FB4541  push WA
	calr (0xFB44A5 - 0xFB4545)                 ; FB4542  calr 0xfb44a5
	inc	8, xsp                                 ; FB4545  inc 0,XSP
sub_FB44EC__FB4547:
	pop	xix                                    ; FB4547  pop XIX
	popw	hl                                    ; FB4548  pop HL
	unlk32 xiz                                 ; FB4549  unlk XIZ
	ret                                        ; FB454B  ret
; --------------------------------------------------------------------------
; sub_FB454C -- 0xFB454C..0xFB456E (35 bytes)
;
; Called from: 8 site(s) outside this module:
;          0xFB301D in sub_FB2F74, 0xFB3262 in VoiceParams_Compute_D
;          0xFB3466 in VoiceParams_Compute_D__FB33CE, 0xFB8676 in sub_FB8668
;          0xFBA526 in sub_FB9B69__FBA51D, 0xFBA71C in sub_FB9B69__FBA713
;          0xFBC8DA in sub_FBC80E, 0xFBD75E in sub_FBD6FC
;          1 site(s) inside this module:
;          0xFB45B7
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFB454C-0xFB456E
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FB454C:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB454C  link XIZ,0x0000
	push	xix                                   ; FB4550  push XIX
	ld	xix, (xiz+10)                           ; FB4551  ld XIX,(XIZ+0x0a)
	add	xix, 18                                ; FB4554  add XIX,0x00000012
	ldb	c, 43                                  ; FB455A  ld C,0x2b
	extpfx3 0x8E, 0x08, 0x43                   ; FB455C  mul BC,(XIZ+0x08)
	extz	xbc                                   ; FB455F  extz XBC
	add	xbc, 46                                ; FB4561  add XBC,0x0000002e
	add	xbc, xix                               ; FB4567  add XBC,XIX
	ld	xiy, xbc                                ; FB4569  ld XIY,XBC
	pop	xix                                    ; FB456B  pop XIX
	unlk32 xiz                                 ; FB456C  unlk XIZ
	ret                                        ; FB456E  ret
; --------------------------------------------------------------------------
; sub_FB456F -- 0xFB456F..0xFB45BF (81 bytes)
;
; Called from: 5 site(s) outside this module:
;          0xFB28EB in sub_FB289A, 0xFB2AF8 in VoiceParams_Compute_C
;          0xFB2CAE in VoiceParams_Compute_C__FB2C6D, 0xFC18AD in ToneQuery_ReplyPercSourceName2AndIndex
;          0xFC258D in sub_FC24F6__FC252F
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C), (XIZ+0x10)
; Outputs: no absolute-addressed write.
; Calls:   0xFB454C = sub_FB454C
; Evidence: the listing below is the byte-identical round-trip of 0xFB456F-0xFB45BF
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FB456F:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB456F  link XIZ,0x0000
	push	xix                                   ; FB4573  push XIX
	ld	bc, (xiz+8)                             ; FB4574  ld BC,(XIZ+0x08)
	extz	bc                                    ; FB4577  extz BC
	mul	bc, 0x12C                              ; FB4579  mul BC,0x012c
	inc	4, bc                                  ; FB457D  inc 4,BC
	extz	xbc                                   ; FB457F  extz XBC
	ld	wa, (xbc+0x1523)                        ; FB4581  ld WA,(XBC+0x1523)
	and	wa, 1                                  ; FB4586  and WA,0x0001
	jr z, sub_FB456F__FB45AE                   ; FB458A  jr Z,0xfb45ae
	ldb	c, 43                                  ; FB458C  ld C,0x2b
	extpfx3 0x8E, 0x0A, 0x43                   ; FB458E  mul BC,(XIZ+0x0a)
	extz	xbc                                   ; FB4591  extz XBC
	ld	xix, xbc                                ; FB4593  ld XIX,XBC
	ldb	a, 0x96                                ; FB4595  ld A,0x96
	extpfx3 0x8E, 0x10, 0x41                   ; FB4597  mul WA,(XIZ+0x10)
	extz	xwa                                   ; FB459A  extz XWA
	add	xwa, xbc                               ; FB459C  add XWA,XBC
	add	xwa, 0x4A1                             ; FB459E  add XWA,0x000004a1
	add	xwa, 0x87D2                            ; FB45A4  add XWA,0x000087d2
	ld	xiy, xwa                                ; FB45AA  ld XIY,XWA
	jr sub_FB456F__FB45BC                      ; FB45AC  jr T,0xfb45bc
sub_FB456F__FB45AE:
	ld	xbc, (xiz+12)                           ; FB45AE  ld XBC,(XIZ+0x0c)
	push	xbc                                   ; FB45B1  push XBC
	push	0                                     ; FB45B2  push 0x00
	extpfx3 0x8E, 0x0A, 0x04                   ; FB45B4  push (XIZ+0x0a)
	calr (0xFB454C - 0xFB45BA)                 ; FB45B7  calr 0xfb454c
	inc	6, xsp                                 ; FB45BA  inc 6,XSP
sub_FB456F__FB45BC:
	pop	xix                                    ; FB45BC  pop XIX
	unlk32 xiz                                 ; FB45BD  unlk XIZ
	ret                                        ; FB45BF  ret
; --------------------------------------------------------------------------
; sub_FB45C0 -- 0xFB45C0..0xFB46FB (316 bytes)
;
; Called from: no site outside this module.
;          2 site(s) inside this module:
;          0xFB4745 0xFB4772
; Inputs:  frame `link XIZ,-20`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
;          reads 0x00D7ED, 0x00D7F1, 0x00D80D, 0x00D811
; Evidence: the listing below is the byte-identical round-trip of 0xFB45C0-0xFB46FB
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FB45C0:
	link32 0xEE, 0x0C, 0xEC, 0xFF              ; FB45C0  link XIZ,0xffec
	pushw	hl                                   ; FB45C4  push HL
	pushw	de                                   ; FB45C5  push DE
	pushw	ix                                   ; FB45C6  push IX
	ld	(xiz-1), 0                              ; FB45C7  ld (XIZ+0xff),0x00
	ld	c, (xiz+8)                              ; FB45CB  ld C,(XIZ+0x08)
	res	7, c                                   ; FB45CE  res 0x07,C
	extz	bc                                    ; FB45D1  extz BC
	ld	hl, bc                                  ; FB45D3  ld HL,BC
	ld	a, (xiz+10)                             ; FB45D5  ld A,(XIZ+0x0a)
	and	a, 15                                  ; FB45D8  and A,0x0f
	extz	wa                                    ; FB45DB  extz WA
	ld	de, wa                                  ; FB45DD  ld DE,WA
	ld	c, (xiz+10)                             ; FB45DF  ld C,(XIZ+0x0a)
	and	c, 0xC0                                ; FB45E2  and C,0xc0
	extz	bc                                    ; FB45E5  extz BC
	ld	ix, bc                                  ; FB45E7  ld IX,BC
	ld	c, (xiz+10)                             ; FB45E9  ld C,(XIZ+0x0a)
	and	c, 48                                  ; FB45EC  and C,0x30
	extz	bc                                    ; FB45EF  extz BC
	cps	bc, 0                                  ; FB45F1  cp BC,0
	jr z, sub_FB45C0__FB4609                   ; FB45F3  jr Z,0xfb4609
	cp	bc, 16                                  ; FB45F5  cp BC,0x0010
	jr z, sub_FB45C0__FB4609                   ; FB45F9  jr Z,0xfb4609
	cp	bc, 32                                  ; FB45FB  cp BC,0x0020
	jr z, sub_FB45C0__FB461B                   ; FB45FF  jr Z,0xfb461b
	cp	bc, 48                                  ; FB4601  cp BC,0x0030
	jr z, sub_FB45C0__FB461B                   ; FB4605  jr Z,0xfb461b
	jr sub_FB45C0__FB464A                      ; FB4607  jr T,0xfb464a
sub_FB45C0__FB4609:
	ldl_da	xbc, (0xD7ED)                       ; FB4609  ld XBC,(0x00d7ed)
	ld	(xiz-6), xbc                            ; FB460E  ld (XIZ+0xfa),XBC
	ldl_da	xwa, (0xD7F1)                       ; FB4611  ld XWA,(0x00d7f1)
	ld	(xiz-10), xwa                           ; FB4616  ld (XIZ+0xf6),XWA
	jr sub_FB45C0__FB464A                      ; FB4619  jr T,0xfb464a
sub_FB45C0__FB461B:
	ldl_da	xbc, (0xD80D)                       ; FB461B  ld XBC,(0x00d80d)
	or	xbc, xbc                                ; FB4620  or XBC,XBC
	jr z, sub_FB45C0__FB4636                   ; FB4622  jr Z,0xfb4636
	ldl_da	xbc, (0xD80D)                       ; FB4624  ld XBC,(0x00d80d)
	ld	(xiz-6), xbc                            ; FB4629  ld (XIZ+0xfa),XBC
	ldl_da	xwa, (0xD811)                       ; FB462C  ld XWA,(0x00d811)
	ld	(xiz-10), xwa                           ; FB4631  ld (XIZ+0xf6),XWA
	jr sub_FB45C0__FB464A                      ; FB4634  jr T,0xfb464a
sub_FB45C0__FB4636:
	ldl_da	xbc, (0xD7ED)                       ; FB4636  ld XBC,(0x00d7ed)
	ld	(xiz-6), xbc                            ; FB463B  ld (XIZ+0xfa),XBC
	ldl_da	xwa, (0xD7F1)                       ; FB463E  ld XWA,(0x00d7f1)
	ld	(xiz-10), xwa                           ; FB4643  ld (XIZ+0xf6),XWA
	ld	(xiz-1), 1                              ; FB4646  ld (XIZ+0xff),0x01
sub_FB45C0__FB464A:
	ld	bc, ix                                  ; FB464A  ld BC,IX
	cps	bc, 0                                  ; FB464C  cp BC,0
	jr z, sub_FB45C0__FB4665                   ; FB464E  jr Z,0xfb4665
	cp	bc, 64                                  ; FB4650  cp BC,0x0040
	jr z, sub_FB45C0__FB4689                   ; FB4654  jr Z,0xfb4689
	cp	bc, 0x80                                ; FB4656  cp BC,0x0080
	jr z, sub_FB45C0__FB46B0                   ; FB465A  jr Z,0xfb46b0
	cp	bc, 0xC0                                ; FB465C  cp BC,0x00c0
	jr z, sub_FB45C0__FB4665                   ; FB4660  jr Z,0xfb4665
	jrl sub_FB45C0__FB46D8                     ; FB4662  jrl T,0xfb46d8
sub_FB45C0__FB4665:
	ld	xbc, (xiz-10)                           ; FB4665  ld XBC,(XIZ+0xf6)
	ld	xwa, (xbc+36)                           ; FB4668  ld XWA,(XBC+0x24)
	ld	(xiz-14), xwa                           ; FB466B  ld (XIZ+0xf2),XWA
	ld	xiy, (xbc+48)                           ; FB466E  ld XIY,(XBC+0x30)
	ld	(xiz-18), xiy                           ; FB4671  ld (XIZ+0xee),XIY
	ldl_da	xbc, (0xD7F1)                       ; FB4674  ld XBC,(0x00d7f1)
	ld	wa, (xbc+0xEC)                          ; FB4679  ld WA,(XBC+0x00ec)
	ld	(xiz-20), wa                            ; FB467E  ld (XIZ+0xec),WA
	cp (xiz-1), 0x00                           ; FB4681  cp (XIZ+0xff),0x00
	jr z, sub_FB45C0__FB46D8                   ; FB4685  jr Z,0xfb46d8
	jr sub_FB45C0__FB46D2                      ; FB4687  jr T,0xfb46d2
sub_FB45C0__FB4689:
	ld	xbc, (xiz-10)                           ; FB4689  ld XBC,(XIZ+0xf6)
	ld	xwa, (xbc+44)                           ; FB468C  ld XWA,(XBC+0x2c)
	ld	(xiz-14), xwa                           ; FB468F  ld (XIZ+0xf2),XWA
	ld	xiy, (xbc+56)                           ; FB4692  ld XIY,(XBC+0x38)
	ld	(xiz-18), xiy                           ; FB4695  ld (XIZ+0xee),XIY
	ldl_da	xbc, (0xD7F1)                       ; FB4698  ld XBC,(0x00d7f1)
	ld	wa, (xbc+0xF2)                          ; FB469D  ld WA,(XBC+0x00f2)
	ld	(xiz-20), wa                            ; FB46A2  ld (XIZ+0xec),WA
	cp (xiz-1), 0x00                           ; FB46A5  cp (XIZ+0xff),0x00
	jr z, sub_FB45C0__FB46D8                   ; FB46A9  jr Z,0xfb46d8
	ldw	hl, 0                                  ; FB46AB  ld HL,0x0000
	jr sub_FB45C0__FB46D5                      ; FB46AE  jr T,0xfb46d5
sub_FB45C0__FB46B0:
	ld	xbc, (xiz-10)                           ; FB46B0  ld XBC,(XIZ+0xf6)
	ld	xwa, (xbc+40)                           ; FB46B3  ld XWA,(XBC+0x28)
	ld	(xiz-14), xwa                           ; FB46B6  ld (XIZ+0xf2),XWA
	ld	xiy, (xbc+52)                           ; FB46B9  ld XIY,(XBC+0x34)
	ld	(xiz-18), xiy                           ; FB46BC  ld (XIZ+0xee),XIY
	ldl_da	xbc, (0xD7F1)                       ; FB46BF  ld XBC,(0x00d7f1)
	ld	wa, (xbc+0xEC)                          ; FB46C4  ld WA,(XBC+0x00ec)
	ld	(xiz-20), wa                            ; FB46C9  ld (XIZ+0xec),WA
	cp (xiz-1), 0x00                           ; FB46CC  cp (XIZ+0xff),0x00
	jr z, sub_FB45C0__FB46D8                   ; FB46D0  jr Z,0xfb46d8
sub_FB45C0__FB46D2:
	ldw	hl, 0x7F                               ; FB46D2  ld HL,0x007f
sub_FB45C0__FB46D5:
	ldw	de, 0                                  ; FB46D5  ld DE,0x0000
sub_FB45C0__FB46D8:
	ld	bc, de                                  ; FB46D8  ld BC,DE
	sll	bc, 7                                  ; FB46DA  sll 0x07,BC
	add	bc, hl                                 ; FB46DD  add BC,HL
	mul	bc, 2                                  ; FB46DF  mul BC,0x0002
	extpfx3 0xAE, 0xF2, 0x81                   ; FB46E3  add XBC,(XIZ+0xf2)
	extpfx3 0xAE, 0xFA, 0x81                   ; FB46E6  add XBC,(XIZ+0xfa)
	ld	wa, (xbc)                               ; FB46E9  ld WA,(XBC)
	extpfx3 0x9E, 0xEC, 0x40                   ; FB46EB  mul XWA,(XIZ+0xec)
	extpfx3 0xAE, 0xEE, 0x80                   ; FB46EE  add XWA,(XIZ+0xee)
	extpfx3 0xAE, 0xFA, 0x80                   ; FB46F1  add XWA,(XIZ+0xfa)
	ld	xiy, xwa                                ; FB46F4  ld XIY,XWA
	popw	ix                                    ; FB46F6  pop IX
	popw	de                                    ; FB46F7  pop DE
	popw	hl                                    ; FB46F8  pop HL
	unlk32 xiz                                 ; FB46F9  unlk XIZ
	ret                                        ; FB46FB  ret
; --------------------------------------------------------------------------
; sub_FB46FC -- 0xFB46FC..0xFB474D (82 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFB4791
; Inputs:  frame `link XIZ,-8`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C)
; Outputs: no absolute-addressed write.
; Calls:   0xFB45C0 = sub_FB45C0
; Evidence: the listing below is the byte-identical round-trip of 0xFB46FC-0xFB474D
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FB46FC:
	link32 0xEE, 0x0C, 0xF8, 0xFF              ; FB46FC  link XIZ,0xfff8
	pushw	hl                                   ; FB4700  push HL
	push	xix                                   ; FB4701  push XIX
	ldb	c, 2                                   ; FB4702  ld C,0x02
	extpfx3 0x8E, 0x0C, 0x43                   ; FB4704  mul BC,(XIZ+0x0c)
	extz	xbc                                   ; FB4707  extz XBC
	ld	xix, xbc                                ; FB4709  ld XIX,XBC
	inc	3, xbc                                 ; FB470B  inc 3,XBC
	ld	(xiz-4), xbc                            ; FB470D  ld (XIZ+0xfc),XBC
	ldb	a, 41                                  ; FB4710  ld A,0x29
	extpfx3 0x8E, 0x0A, 0x41                   ; FB4712  mul WA,(XIZ+0x0a)
	ld	hl, wa                                  ; FB4715  ld HL,WA
	ld	iy, (xiz+8)                             ; FB4717  ld IY,(XIZ+0x08)
	extz	iy                                    ; FB471A  extz IY
	mul	iy, 0x12C                              ; FB471C  mul IY,0x012c
	add	iy, wa                                 ; FB4720  add IY,WA
	add	iy, 0x8C                               ; FB4722  add IY,0x008c
	extz	xiy                                   ; FB4726  extz XIY
	ld	xwa, (xiy+0x1523)                       ; FB4728  ld XWA,(XIY+0x1523)
	ld	(xiz-8), xwa                            ; FB472D  ld (XIZ+0xf8),XWA
	add	xwa, xbc                               ; FB4730  add XWA,XBC
	ld	h, (xwa)                                ; FB4732  ld H,(XWA)
	ld	xbc, xix                                ; FB4734  ld XBC,XIX
	inc	4, xbc                                 ; FB4736  inc 4,XBC
	extpfx3 0xAE, 0xF8, 0x81                   ; FB4738  add XBC,(XIZ+0xf8)
	ld	w, (xbc)                                ; FB473B  ld W,(XBC)
	push	0                                     ; FB473D  push 0x00
	push	w                                     ; FB473F  push W
	push	0                                     ; FB4741  push 0x00
	push	h                                     ; FB4743  push H
	calr (0xFB45C0 - 0xFB4748)                 ; FB4745  calr 0xfb45c0
	pop	xbc                                    ; FB4748  pop XBC
	pop	xix                                    ; FB4749  pop XIX
	popw	hl                                    ; FB474A  pop HL
	unlk32 xiz                                 ; FB474B  unlk XIZ
	ret                                        ; FB474D  ret
; --------------------------------------------------------------------------
; sub_FB474E -- 0xFB474E..0xFB477A (45 bytes)
;
; Called from: 6 site(s) outside this module:
;          0xFB2916 in sub_FB289A, 0xFB2B23 in VoiceParams_Compute_C
;          0xFB2CD9 in VoiceParams_Compute_C__FB2C6D, 0xFB3054 in sub_FB2F74
;          0xFB3298 in VoiceParams_Compute_D, 0xFB349A in VoiceParams_Compute_D__FB33CE
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Calls:   0xFB45C0 = sub_FB45C0
; Evidence: the listing below is the byte-identical round-trip of 0xFB474E-0xFB477A
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FB474E:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB474E  link XIZ,0x0000
	pushw	hl                                   ; FB4752  push HL
	push	xix                                   ; FB4753  push XIX
	ldb	c, 2                                   ; FB4754  ld C,0x02
	extpfx3 0x8E, 0x08, 0x43                   ; FB4756  mul BC,(XIZ+0x08)
	extz	xbc                                   ; FB4759  extz XBC
	ld	xix, xbc                                ; FB475B  ld XIX,XBC
	inc	3, xbc                                 ; FB475D  inc 3,XBC
	extpfx3 0xAE, 0x0A, 0x81                   ; FB475F  add XBC,(XIZ+0x0a)
	ld	h, (xbc)                                ; FB4762  ld H,(XBC)
	ld	xbc, xix                                ; FB4764  ld XBC,XIX
	inc	4, xbc                                 ; FB4766  inc 4,XBC
	extpfx3 0xAE, 0x0A, 0x81                   ; FB4768  add XBC,(XIZ+0x0a)
	ld	a, (xbc)                                ; FB476B  ld A,(XBC)
	pushw	wa                                   ; FB476D  push WA
	push	0                                     ; FB476E  push 0x00
	push	h                                     ; FB4770  push H
	calr (0xFB45C0 - 0xFB4775)                 ; FB4772  calr 0xfb45c0
	pop	xbc                                    ; FB4775  pop XBC
	pop	xix                                    ; FB4776  pop XIX
	popw	hl                                    ; FB4777  pop HL
	unlk32 xiz                                 ; FB4778  unlk XIZ
	ret                                        ; FB477A  ret
; --------------------------------------------------------------------------
; sub_FB477B -- 0xFB477B..0xFB47C3 (73 bytes)
;
; Called from: 7 site(s) outside this module:
;          0xFB91DB in ToneDB_SourceNameList1_SelectEntry__FB91CD, 0xFB936E in ToneDB_SourceNameList2_SelectEntry__FB92D2
;          0xFBC064 in sub_FBBFFB__FBC055, 0xFBC9CC in sub_FBC958__FBC9BF
;          0xFBC9E2 in sub_FBC958__FBC9D5, 0xFBC9F8 in sub_FBC958__FBC9EB
;          0xFBCA0E in sub_FBC958__FBCA01
;          1 site(s) inside this module:
;          0xFB4880
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C)
; Outputs: no absolute-addressed write.
; Calls:   0xFB46FC = sub_FB46FC
; Evidence: the listing below is the byte-identical round-trip of 0xFB477B-0xFB47C3
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FB477B:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB477B  link XIZ,0x0000
	pushw	hl                                   ; FB477F  push HL
	pushw	de                                   ; FB4780  push DE
	push	xix                                   ; FB4781  push XIX
	push	0                                     ; FB4782  push 0x00
	extpfx3 0x8E, 0x0C, 0x04                   ; FB4784  push (XIZ+0x0c)
	push	0                                     ; FB4787  push 0x00
	extpfx3 0x8E, 0x0A, 0x04                   ; FB4789  push (XIZ+0x0a)
	push	0                                     ; FB478C  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FB478E  push (XIZ+0x08)
	calr (0xFB46FC - 0xFB4794)                 ; FB4791  calr 0xfb46fc
	ld	xix, xiy                                ; FB4794  ld XIX,XIY
	ldb	c, 41                                  ; FB4796  ld C,0x29
	extpfx3 0x8E, 0x0A, 0x43                   ; FB4798  mul BC,(XIZ+0x0a)
	ld	hl, bc                                  ; FB479B  ld HL,BC
	ld	wa, (xiz+8)                             ; FB479D  ld WA,(XIZ+0x08)
	extz	wa                                    ; FB47A0  extz WA
	mul	wa, 0x12C                              ; FB47A2  mul WA,0x012c
	ld	de, wa                                  ; FB47A6  ld DE,WA
	add	de, bc                                 ; FB47A8  add DE,BC
	ldb	c, 4                                   ; FB47AA  ld C,0x04
	extpfx3 0x8E, 0x0C, 0x43                   ; FB47AC  mul BC,(XIZ+0x0c)
	add	bc, de                                 ; FB47AF  add BC,DE
	add	bc, 0x90                               ; FB47B1  add BC,0x0090
	extz	xbc                                   ; FB47B5  extz XBC
	ld	(xbc+0x1523), xiy                       ; FB47B7  ld (XBC+0x1523),XIY
	inc	6, xsp                                 ; FB47BC  inc 6,XSP
	pop	xix                                    ; FB47BE  pop XIX
	popw	de                                    ; FB47BF  pop DE
	popw	hl                                    ; FB47C0  pop HL
	unlk32 xiz                                 ; FB47C1  unlk XIZ
	ret                                        ; FB47C3  ret
; --------------------------------------------------------------------------
; sub_FB47C4 -- 0xFB47C4..0xFB48F6 (307 bytes)
;
; Called from: 5 site(s) outside this module:
;          0xFB02D9 in sub_FB029E__FB02B2, 0xFB8705 in sub_FB86BB
;          0xFB8EB2 in sub_FB8CEC__FB8E88, 0xFB9AFE in sub_FB9AC2
;          0xFBAB55 in sub_FBAAA2__FBAB0E
;          1 site(s) inside this module:
;          0xFB6C28
; Inputs:  frame `link XIZ,-12`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C)
; Outputs: no absolute-addressed write.
; Calls:   0xFB42B0 = sub_FB42B0, 0xFB4383 = sub_FB4383
;          0xFB44EC = sub_FB44EC, 0xFB477B = sub_FB477B
;          0xFC2930 = sub_FC2930, 0xFC295B = DrawbarPreset_GetDescriptor
; Evidence: the listing below is the byte-identical round-trip of 0xFB47C4-0xFB48F6
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FB47C4:
	link32 0xEE, 0x0C, 0xF4, 0xFF              ; FB47C4  link XIZ,0xfff4
	pushw	hl                                   ; FB47C8  push HL
	pushw	de                                   ; FB47C9  push DE
	push	xix                                   ; FB47CA  push XIX
	ld	bc, (xiz+12)                            ; FB47CB  ld BC,(XIZ+0x0c)
	extz	bc                                    ; FB47CE  extz BC
	pushw	bc                                   ; FB47D0  push BC
	ld	bc, (xiz+10)                            ; FB47D1  ld BC,(XIZ+0x0a)
	extz	bc                                    ; FB47D4  extz BC
	pushw	bc                                   ; FB47D6  push BC
	push	0                                     ; FB47D7  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FB47D9  push (XIZ+0x08)
	calr (0xFB42B0 - 0xFB47DF)                 ; FB47DC  calr 0xfb42b0
	ld	xix, xiy                                ; FB47DF  ld XIX,XIY
	ld	bc, (xiz+8)                             ; FB47E1  ld BC,(XIZ+0x08)
	extz	bc                                    ; FB47E4  extz BC
	mul	bc, 0x12C                              ; FB47E6  mul BC,0x012c
	ld	de, bc                                  ; FB47EA  ld DE,BC
	extz	xbc                                   ; FB47EC  extz XBC
	ld	(xbc+0x1523), xiy                       ; FB47EE  ld (XBC+0x1523),XIY
	ld	a, (xiy+16)                             ; FB47F3  ld A,(XIY+0x10)
	and	a, 0xC0                                ; FB47F6  and A,0xc0
	extz	wa                                    ; FB47F9  extz WA
	inc	6, xsp                                 ; FB47FB  inc 6,XSP
	cps	wa, 0                                  ; FB47FD  cp WA,0
	jr z, sub_FB47C4__FB4818                   ; FB47FF  jr Z,0xfb4818
	cp	wa, 64                                  ; FB4801  cp WA,0x0040
	jrl z, sub_FB47C4__FB4897                  ; FB4805  jrl Z,0xfb4897
	cp	wa, 0x80                                ; FB4808  cp WA,0x0080
	jrl z, sub_FB47C4__FB48F1                  ; FB480C  jrl Z,0xfb48f1
	cp	wa, 0xC0                                ; FB480F  cp WA,0x00c0
	jr z, sub_FB47C4__FB4818                   ; FB4813  jr Z,0xfb4818
	jrl sub_FB47C4__FB48F1                     ; FB4815  jrl T,0xfb48f1
sub_FB47C4__FB4818:
	ldb	h, 0                                   ; FB4818  ld H,0x00
	ld	bc, (xiz+8)                             ; FB481A  ld BC,(XIZ+0x08)
	extz	bc                                    ; FB481D  extz BC
	mul	bc, 0x12C                              ; FB481F  mul BC,0x012c
	ld	xix, xbc                                ; FB4823  ld XIX,XBC
	ldw	de, 0                                  ; FB4825  ld DE,0x0000
sub_FB47C4__FB4828:
	ld	bc, (xiz+12)                            ; FB4828  ld BC,(XIZ+0x0c)
	extz	bc                                    ; FB482B  extz BC
	pushw	bc                                   ; FB482D  push BC
	push	0                                     ; FB482E  push 0x00
	push	h                                     ; FB4830  push H
	push	0                                     ; FB4832  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FB4834  push (XIZ+0x08)
	calr (0xFB4383 - 0xFB483A)                 ; FB4837  calr 0xfb4383
	ld	(xiz-4), xiy                            ; FB483A  ld (XIZ+0xfc),XIY
	ld	(xiz-6), de                             ; FB483D  ld (XIZ+0xfa),DE
	ld	bc, ix                                  ; FB4840  ld BC,IX
	extpfx3 0x9E, 0xFA, 0x81                   ; FB4842  add BC,(XIZ+0xfa)
	ld	(xiz-8), bc                             ; FB4845  ld (XIZ+0xf8),BC
	add	bc, 0x88                               ; FB4848  add BC,0x0088
	extz	xbc                                   ; FB484C  extz XBC
	ld	(xbc+0x1523), xiy                       ; FB484E  ld (XBC+0x1523),XIY
	push	0                                     ; FB4853  push 0x00
	push	h                                     ; FB4855  push H
	push	0                                     ; FB4857  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FB4859  push (XIZ+0x08)
	calr (0xFB44EC - 0xFB485F)                 ; FB485C  calr 0xfb44ec
	ld	(xiz-12), xiy                           ; FB485F  ld (XIZ+0xf4),XIY
	ld	bc, (xiz-8)                             ; FB4862  ld BC,(XIZ+0xf8)
	add	bc, 0x8C                               ; FB4865  add BC,0x008c
	extz	xbc                                   ; FB4869  extz XBC
	ld	(xbc+0x1523), xiy                       ; FB486B  ld (XBC+0x1523),XIY
	ldb	l, 0                                   ; FB4870  ld L,0x00
	inc	8, xsp                                 ; FB4872  inc 0,XSP
	inc	2, xsp                                 ; FB4874  inc 2,XSP
sub_FB47C4__FB4876:
	pushw	hl                                   ; FB4876  push HL
	push	0                                     ; FB4877  push 0x00
	push	h                                     ; FB4879  push H
	push	0                                     ; FB487B  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FB487D  push (XIZ+0x08)
	calr (0xFB477B - 0xFB4883)                 ; FB4880  calr 0xfb477b
	inc	1, l                                   ; FB4883  inc 1,L
	inc	6, xsp                                 ; FB4885  inc 6,XSP
	cps	l, 4                                   ; FB4887  cp L,4
	jr c, sub_FB47C4__FB4876                   ; FB4889  jr C,0xfb4876
	add	de, 41                                 ; FB488B  add DE,0x0029
	inc	1, h                                   ; FB488F  inc 1,H
	cps	h, 4                                   ; FB4891  cp H,4
	jr c, sub_FB47C4__FB4828                   ; FB4893  jr C,0xfb4828
	jr sub_FB47C4__FB48F1                      ; FB4895  jr T,0xfb48f1
sub_FB47C4__FB4897:
	ldb	h, 0                                   ; FB4897  ld H,0x00
	ld	ix, de                                  ; FB4899  ld IX,DE
	ldw	de, 0                                  ; FB489B  ld DE,0x0000
sub_FB47C4__FB489E:
	ld	bc, (xiz+12)                            ; FB489E  ld BC,(XIZ+0x0c)
	extz	bc                                    ; FB48A1  extz BC
	pushw	bc                                   ; FB48A3  push BC
	push	0                                     ; FB48A4  push 0x00
	push	h                                     ; FB48A6  push H
	push	0                                     ; FB48A8  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FB48AA  push (XIZ+0x08)
	calr (0xFB4383 - 0xFB48B0)                 ; FB48AD  calr 0xfb4383
	ld	(xiz-4), xiy                            ; FB48B0  ld (XIZ+0xfc),XIY
	ld	(xiz-6), de                             ; FB48B3  ld (XIZ+0xfa),DE
	ld	bc, ix                                  ; FB48B6  ld BC,IX
	extpfx3 0x9E, 0xFA, 0x81                   ; FB48B8  add BC,(XIZ+0xfa)
	add	bc, 0x88                               ; FB48BB  add BC,0x0088
	extz	xbc                                   ; FB48BF  extz XBC
	ld	(xbc+0x1523), xiy                       ; FB48C1  ld (XBC+0x1523),XIY
	push	0                                     ; FB48C6  push 0x00
	push	h                                     ; FB48C8  push H
	push	0                                     ; FB48CA  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FB48CC  push (XIZ+0x08)
	call	0xFC2930                              ; FB48CF  call 0xfc2930
	push	0                                     ; FB48D3  push 0x00
	push	h                                     ; FB48D5  push H
	push	0                                     ; FB48D7  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FB48D9  push (XIZ+0x08)
	call	0xFC295B                              ; FB48DC  call 0xfc295b
	ld	de, (xiz-6)                             ; FB48E0  ld DE,(XIZ+0xfa)
	add	de, 41                                 ; FB48E3  add DE,0x0029
	inc	1, h                                   ; FB48E7  inc 1,H
	inc	8, xsp                                 ; FB48E9  inc 0,XSP
	inc	6, xsp                                 ; FB48EB  inc 6,XSP
	cps	h, 4                                   ; FB48ED  cp H,4
	jr c, sub_FB47C4__FB489E                   ; FB48EF  jr C,0xfb489e
sub_FB47C4__FB48F1:
	pop	xix                                    ; FB48F1  pop XIX
	popw	de                                    ; FB48F2  pop DE
	popw	hl                                    ; FB48F3  pop HL
	unlk32 xiz                                 ; FB48F4  unlk XIZ
	ret                                        ; FB48F6  ret
; --------------------------------------------------------------------------
; DrumKit_ResolveInstrumentRecord -- 0xFB48F7..0xFB49EA (244 bytes)
;
; Called from: 9 site(s) outside this module:
;          0xFB3001 in sub_FB2F74, 0xFB324B in VoiceParams_Compute_D
;          0xFB344F in VoiceParams_Compute_D__FB33CE, 0xFB85D5 in sub_FB857E
;          0xFB8970 in sub_FB86BB__FB890E, 0xFB9651 in ToneDB_DrumSourceNameList_SelectEntry__FB95B3
;          0xFBA41C in sub_FB9B69__FBA3C6, 0xFBC8CB in sub_FBC80E
;          0xFBCC19 in sub_FBCBA7
;          1 site(s) inside this module:
;          0xFB4A94
; Inputs:  frame `link XIZ,-14`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C), (XIZ+0x0E)
; Outputs: no absolute-addressed write.
;          reads 0x00D7ED, 0x00D7F1, 0x00D80D, 0x00D811
; Evidence: the listing below is the byte-identical round-trip of 0xFB48F7-0xFB49EA
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Name:     resolves (kit, note) to a 150-byte DRUM-INSTRUMENT RECORD
; Evidence: prom_d's Q4d decodes 9 instructions at 0xFB48FE-0xFB495A:
;           directory slot +0x74 (DrumKit_NoteMapA) indexed by kit*128 +
;           note as LE16, and the index it yields multiplied by the tail
;           scalar at +0xEE (150) into slot +0x78 (PercInst_000_Silent, the
;           record array). prom_d's own geometry confirms the stride
;           independently: 0x2EF5C + 504*150 = 0x416AC, which is exactly the
;           next slot, +0x20
; Unknown:  what a drum-instrument record's 150 bytes contain
; Named:   ROUND 11, by notes/prom_c_inventory_round8.py -- it was `sub_FB48F7`.
; --------------------------------------------------------------------------
DrumKit_ResolveInstrumentRecord:
	link32 0xEE, 0x0C, 0xF2, 0xFF              ; FB48F7  link XIZ,0xfff2
	pushw	hl                                   ; FB48FB  push HL
	pushw	de                                   ; FB48FC  push DE
	push	xix                                   ; FB48FD  push XIX
	ldl_da	xix, (0xD7F1)                       ; FB48FE  ld XIX,(0x00d7f1)
	ld	de, (xiz+8)                             ; FB4903  ld DE,(XIZ+0x08)
	and	de, 0x7F                               ; FB4906  and DE,0x007f
	ld	hl, (xiz+10)                            ; FB490A  ld HL,(XIZ+0x0a)
	and	hl, 15                                 ; FB490D  and HL,0x000f
	ld	bc, (xiz+10)                            ; FB4911  ld BC,(XIZ+0x0a)
	and	bc, 48                                 ; FB4914  and BC,0x0030
	cps	bc, 0                                  ; FB4918  cp BC,0
	jr z, DrumKit_ResolveInstrumentRecord__FB4931                   ; FB491A  jr Z,0xfb4931
	cp	bc, 16                                  ; FB491C  cp BC,0x0010
	jr z, DrumKit_ResolveInstrumentRecord__FB4967                   ; FB4920  jr Z,0xfb4967
	cp	bc, 32                                  ; FB4922  cp BC,0x0020
	jr z, DrumKit_ResolveInstrumentRecord__FB498C                   ; FB4926  jr Z,0xfb498c
	cp	bc, 48                                  ; FB4928  cp BC,0x0030
	jr z, DrumKit_ResolveInstrumentRecord__FB498C                   ; FB492C  jr Z,0xfb498c
	jrl DrumKit_ResolveInstrumentRecord__FB49E2                     ; FB492E  jrl T,0xfb49e2
DrumKit_ResolveInstrumentRecord__FB4931:
	ld	xbc, (xix+0x74)                         ; FB4931  ld XBC,(XIX+0x74)
	ld	(xiz-8), xbc                            ; FB4934  ld (XIZ+0xf8),XBC
	ld	xwa, (xix+0x78)                         ; FB4937  ld XWA,(XIX+0x78)
	ld	(xiz-12), xwa                           ; FB493A  ld (XIZ+0xf4),XWA
	ld	iy, (xix+0xEE)                          ; FB493D  ld IY,(XIX+0x00ee)
	ld	(xiz-14), iy                            ; FB4942  ld (XIZ+0xf2),IY
	ld	bc, hl                                  ; FB4945  ld BC,HL
	sll	bc, 7                                  ; FB4947  sll 0x07,BC
	add	bc, de                                 ; FB494A  add BC,DE
	mul	bc, 2                                  ; FB494C  mul BC,0x0002
	extpfx3 0xAE, 0xF8, 0x81                   ; FB4950  add XBC,(XIZ+0xf8)
	addda32_24	xbc, (0xD7ED)                   ; FB4953  add XBC,(0x00d7ed)
	ld	wa, (xbc)                               ; FB4958  ld WA,(XBC)
	mul	xiy, xwa                               ; FB495A  mul XIY,WA
	extpfx3 0xAE, 0xF4, 0x85                   ; FB495C  add XIY,(XIZ+0xf4)
	addda32_24	xiy, (0xD7ED)                   ; FB495F  add XIY,(0x00d7ed)
	jrl DrumKit_ResolveInstrumentRecord__FB49E5                     ; FB4964  jrl T,0xfb49e5
DrumKit_ResolveInstrumentRecord__FB4967:
	ldb	c, 0x96                                ; FB4967  ld C,0x96
	extpfx3 0x8E, 0x0E, 0x43                   ; FB4969  mul BC,(XIZ+0x0e)
	extz	xbc                                   ; FB496C  extz XBC
	add	xbc, 0xB468                            ; FB496E  add XBC,0x0000b468
	ld	(xiz-8), xbc                            ; FB4974  ld (XIZ+0xf8),XBC
	ldb	a, 4                                   ; FB4977  ld A,0x04
	extpfx3 0x8E, 0x0C, 0x41                   ; FB4979  mul WA,(XIZ+0x0c)
	extz	xwa                                   ; FB497C  extz XWA
	add	xwa, 0xD7F5                            ; FB497E  add XWA,0x0000d7f5
	ld	xwa, (xwa)                              ; FB4984  ld XWA,(XWA)
	add	xwa, xbc                               ; FB4986  add XWA,XBC
	ld	xiy, xwa                                ; FB4988  ld XIY,XWA
	jr DrumKit_ResolveInstrumentRecord__FB49E5                      ; FB498A  jr T,0xfb49e5
DrumKit_ResolveInstrumentRecord__FB498C:
	ldl_da	xbc, (0xD80D)                       ; FB498C  ld XBC,(0x00d80d)
	or	xbc, xbc                                ; FB4991  or XBC,XBC
	jr z, DrumKit_ResolveInstrumentRecord__FB49CF                   ; FB4993  jr Z,0xfb49cf
	ldl_da	xbc, (0xD811)                       ; FB4995  ld XBC,(0x00d811)
	ld	xwa, (xbc+0x74)                         ; FB499A  ld XWA,(XBC+0x74)
	ld	(xiz-8), xwa                            ; FB499D  ld (XIZ+0xf8),XWA
	ld	xiy, (xbc+0x78)                         ; FB49A0  ld XIY,(XBC+0x78)
	ld	(xiz-12), xiy                           ; FB49A3  ld (XIZ+0xf4),XIY
	ld	bc, (xix+0xEE)                          ; FB49A6  ld BC,(XIX+0x00ee)
	ld	(xiz-14), bc                            ; FB49AB  ld (XIZ+0xf2),BC
	ld	bc, hl                                  ; FB49AE  ld BC,HL
	sll	bc, 7                                  ; FB49B0  sll 0x07,BC
	add	bc, de                                 ; FB49B3  add BC,DE
	mul	bc, 2                                  ; FB49B5  mul BC,0x0002
	extpfx3 0xAE, 0xF8, 0x81                   ; FB49B9  add XBC,(XIZ+0xf8)
	addda32_24	xbc, (0xD80D)                   ; FB49BC  add XBC,(0x00d80d)
	ld	wa, (xbc)                               ; FB49C1  ld WA,(XBC)
	extpfx3 0x9E, 0xF2, 0x40                   ; FB49C3  mul XWA,(XIZ+0xf2)
	add	xiy, xwa                               ; FB49C6  add XIY,XWA
	addda32_24	xiy, (0xD80D)                   ; FB49C8  add XIY,(0x00d80d)
	jr DrumKit_ResolveInstrumentRecord__FB49E5                      ; FB49CD  jr T,0xfb49e5
DrumKit_ResolveInstrumentRecord__FB49CF:
	ld	xbc, (xix+0x78)                         ; FB49CF  ld XBC,(XIX+0x78)
	ld	(xiz-8), xbc                            ; FB49D2  ld (XIZ+0xf8),XBC
	sub	xwa, xwa                               ; FB49D5  sub XWA,XWA
	add	xbc, xwa                               ; FB49D7  add XBC,XWA
	addda32_24	xbc, (0xD7ED)                   ; FB49D9  add XBC,(0x00d7ed)
	ld	xiy, xbc                                ; FB49DE  ld XIY,XBC
	jr DrumKit_ResolveInstrumentRecord__FB49E5                      ; FB49E0  jr T,0xfb49e5
DrumKit_ResolveInstrumentRecord__FB49E2:
	ld	xiy, (xiz-4)                            ; FB49E2  ld XIY,(XIZ+0xfc)
DrumKit_ResolveInstrumentRecord__FB49E5:
	pop	xix                                    ; FB49E5  pop XIX
	popw	de                                    ; FB49E6  pop DE
	popw	hl                                    ; FB49E7  pop HL
	unlk32 xiz                                 ; FB49E8  unlk XIZ
	ret                                        ; FB49EA  ret
; --------------------------------------------------------------------------
; sub_FB49EB -- 0xFB49EB..0xFB4A9E (180 bytes)
;
; Called from: 9 site(s) outside this module:
;          0xFB28C5 in sub_FB289A, 0xFB2AD7 in VoiceParams_Compute_C
;          0xFB2C8D in VoiceParams_Compute_C__FB2C6D, 0xFBD49E in sub_FBD46B
;          0xFBD727 in sub_FBD6FC, 0xFC1743 in ToneQuery_ReplyPercSourceName1AndIndex
;          0xFC187E in ToneQuery_ReplyPercSourceName2AndIndex, 0xFC2488 in sub_FC2430__FC2469
;          0xFC254E in sub_FC24F6__FC252F
; Inputs:  frame `link XIZ,-10`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0E)
; Outputs: no absolute-addressed write.
; Calls:   0xFB48F7 = DrumKit_ResolveInstrumentRecord
; Evidence: the listing below is the byte-identical round-trip of 0xFB49EB-0xFB4A9E
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FB49EB:
	link32 0xEE, 0x0C, 0xF6, 0xFF              ; FB49EB  link XIZ,0xfff6
	pushw	hl                                   ; FB49EF  push HL
	pushw	de                                   ; FB49F0  push DE
	push	xix                                   ; FB49F1  push XIX
	lda	xix, (0x1523:16)                      ; FB49F2  lda XIX,0x1523
	ld	d, (xiz+14)                             ; FB49F6  ld D,(XIZ+0x0e)
	ld	bc, (xiz+8)                             ; FB49F9  ld BC,(XIZ+0x08)
	extz	bc                                    ; FB49FC  extz BC
	mul	bc, 0x12C                              ; FB49FE  mul BC,0x012c
	ld	hl, bc                                  ; FB4A02  ld HL,BC
	inc	4, bc                                  ; FB4A04  inc 4,BC
	extz	xix                                   ; FB4A06  extz XIX
	extpfx5 0xD3, 0x07, 0xF0, 0xE4, 0x20       ; FB4A08  ld WA,(XIX+BC)
	and	wa, 1                                  ; FB4A0D  and WA,0x0001
	jr z, sub_FB49EB__FB4A2A                   ; FB4A11  jr Z,0xfb4a2a
	ldb	c, 0x96                                ; FB4A13  ld C,0x96
	mul8rr	c, d                                ; FB4A15  mul BC,D
	extz	xbc                                   ; FB4A17  extz XBC
	add	xbc, 0x461                             ; FB4A19  add XBC,0x00000461
	add	xbc, 0x87D2                            ; FB4A1F  add XBC,0x000087d2
	ld	xiy, xbc                                ; FB4A25  ld XIY,XBC
	jrl sub_FB49EB__FB4A99                     ; FB4A27  jrl T,0xfb4a99
sub_FB49EB__FB4A2A:
	ldb	c, 2                                   ; FB4A2A  ld C,0x02
	mul8rr	c, d                                ; FB4A2C  mul BC,D
	extz	xbc                                   ; FB4A2E  extz XBC
	ld	(xiz-4), xbc                            ; FB4A30  ld (XIZ+0xfc),XBC
	add	xbc, 0x98                              ; FB4A33  add XBC,0x00000098
	extpfx3 0xAE, 0x0A, 0x81                   ; FB4A39  add XBC,(XIZ+0x0a)
	ld	a, (xbc)                                ; FB4A3C  ld A,(XBC)
	extz	wa                                    ; FB4A3E  extz WA
	ld	(xiz-6), wa                             ; FB4A40  ld (XIZ+0xfa),WA
	ld	xbc, (xiz-4)                            ; FB4A43  ld XBC,(XIZ+0xfc)
	add	xbc, 0x99                              ; FB4A46  add XBC,0x00000099
	extpfx3 0xAE, 0x0A, 0x81                   ; FB4A4C  add XBC,(XIZ+0x0a)
	ld	a, (xbc)                                ; FB4A4F  ld A,(XBC)
	extz	wa                                    ; FB4A51  extz WA
	ld	(xiz-8), wa                             ; FB4A53  ld (XIZ+0xf8),WA
	ld	bc, hl                                  ; FB4A56  ld BC,HL
	add	bc, 27                                 ; FB4A58  add BC,0x001b
	extz	xix                                   ; FB4A5C  extz XIX
	extpfx5 0xC3, 0x07, 0xF0, 0xE4, 0x23       ; FB4A5E  ld C,(XIX+BC)
	and	c, 1                                   ; FB4A63  and C,0x01
	extz	bc                                    ; FB4A66  extz BC
	ld	(xiz-10), bc                            ; FB4A68  ld (XIZ+0xf6),BC
	ld	iy, hl                                  ; FB4A6B  ld IY,HL
	add	iy, 28                                 ; FB4A6D  add IY,0x001c
	extpfx5 0xC3, 0x07, 0xF0, 0xF4, 0x23       ; FB4A71  ld C,(XIX+IY)
	extz	bc                                    ; FB4A76  extz BC
	sub	bc, 40                                 ; FB4A78  sub BC,0x0028
	add	bc, bc                                 ; FB4A7C  add BC,BC
	and	bc, 2                                  ; FB4A7E  and BC,0x0002
	ld	hl, bc                                  ; FB4A82  ld HL,BC
	extpfx3 0x9E, 0xF6, 0xE3                   ; FB4A84  or HL,(XIZ+0xf6)
	push	0                                     ; FB4A87  push 0x00
	push	d                                     ; FB4A89  push D
	ld	c, l                                    ; FB4A8B  ld C,L
	pushw	bc                                   ; FB4A8D  push BC
	extpfx3 0x9E, 0xF8, 0x04                   ; FB4A8E  pushw (XIZ+0xf8)
	extpfx3 0x9E, 0xFA, 0x04                   ; FB4A91  pushw (XIZ+0xfa)
	calr (0xFB48F7 - 0xFB4A97)                 ; FB4A94  calr 0xfb48f7
	inc	8, xsp                                 ; FB4A97  inc 0,XSP
sub_FB49EB__FB4A99:
	pop	xix                                    ; FB4A99  pop XIX
	popw	de                                    ; FB4A9A  pop DE
	popw	hl                                    ; FB4A9B  pop HL
	unlk32 xiz                                 ; FB4A9C  unlk XIZ
	ret                                        ; FB4A9E  ret
; --------------------------------------------------------------------------
; sub_FB4A9F -- 0xFB4A9F..0xFB4D20 (642 bytes)
;
; Called from: 5 site(s) outside this module:
;          0xFAFC44 in sub_FAFBEC__FAFC28, 0xFBBAC3 in sub_FBB793__FBBABE
;          0xFBBB89 in sub_FBB793__FBBB84, 0xFBBC79 in sub_FBB793__FBBC74
;          0xFBBCA6 in sub_FBB793__FBBC8B
;          1 site(s) inside this module:
;          0xFB66A0
; Inputs:  frame `link XIZ,-5`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Arms:    2 computed-goto arm(s) inside this routine: 0xFB4B44 0xFB4C0E
; Evidence: the listing below is the byte-identical round-trip of 0xFB4A9F-0xFB4D20
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FB4A9F:
	link32 0xEE, 0x0C, 0xFB, 0xFF              ; FB4A9F  link XIZ,0xfffb
	push	xhl                                   ; FB4AA3  push XHL
	pushw	de                                   ; FB4AA4  push DE
	push	xix                                   ; FB4AA5  push XIX
	ld	bc, (xiz+8)                             ; FB4AA6  ld BC,(XIZ+0x08)
	extz	bc                                    ; FB4AA9  extz BC
	mul	bc, 0x12C                              ; FB4AAB  mul BC,0x012c
	ld	hl, bc                                  ; FB4AAF  ld HL,BC
	inc	6, bc                                  ; FB4AB1  inc 6,BC
	extz	xbc                                   ; FB4AB3  extz XBC
	ld	wa, (xbc+0x1523)                        ; FB4AB5  ld WA,(XBC+0x1523)
	and	wa, 0x3FF0                             ; FB4ABA  and WA,0x3ff0
	ld	(xiz-2), wa                             ; FB4ABE  ld (XIZ+0xfe),WA
	extz	xhl                                   ; FB4AC1  extz XHL
	ld	xbc, (xhl+0x1523)                       ; FB4AC3  ld XBC,(XHL+0x1523)
	ld	xix, xbc                                ; FB4AC8  ld XIX,XBC
	ld	a, (xbc+18)                             ; FB4ACA  ld A,(XBC+0x12)
	ld	(xiz-3), a                              ; FB4ACD  ld (XIZ+0xfd),A
	ld	w, (xbc+17)                             ; FB4AD0  ld W,(XBC+0x11)
	and	w, 1                                   ; FB4AD3  and W,0x01
	jr z, sub_FB4A9F__FB4ADD                   ; FB4AD6  jr Z,0xfb4add
	extpfx3 0xBE, 0xFE, 0xB8                   ; FB4AD8  set 0,(XIZ+0xfe)
	jr sub_FB4A9F__FB4B49                      ; FB4ADB  jr T,0xfb4b49
sub_FB4A9F__FB4ADD:
	ld	bc, hl                                  ; FB4ADD  ld BC,HL
	add	bc, 9                                  ; FB4ADF  add BC,0x0009
	extz	xbc                                   ; FB4AE3  extz XBC
	ld	wa, (xbc+0x1523)                        ; FB4AE5  ld WA,(XBC+0x1523)
	and	wa, 0x8000                             ; FB4AEA  and WA,0x8000
	jr z, sub_FB4A9F__FB4B49                   ; FB4AEE  jr Z,0xfb4b49
	extz	xhl                                   ; FB4AF0  extz XHL
	ld	xbc, (xhl+0x1523)                       ; FB4AF2  ld XBC,(XHL+0x1523)
	ld	xix, xbc                                ; FB4AF7  ld XIX,XBC
	ld	a, (xbc+17)                             ; FB4AF9  ld A,(XBC+0x11)
	and	a, 4                                   ; FB4AFC  and A,0x04
	jr z, sub_FB4A9F__FB4B49                   ; FB4AFF  jr Z,0xfb4b49
	ld	a, (xbc+0xD0)                           ; FB4B01  ld A,(XBC+0x00d0)
	and	a, 15                                  ; FB4B06  and A,0x0f
	extz	wa                                    ; FB4B09  extz WA
	extz	xwa                                   ; FB4B0B  extz XWA
	cp	wa, 8                                   ; FB4B0D  cp WA,0x0008
	jr ugt, sub_FB4A9F__FB4B49                 ; FB4B11  jr UGT,0xfb4b49
	sll	wa, 2                                  ; FB4B13  sll 0x02,WA
	add	xwa, 0xFB4B20                          ; FB4B16  add XWA,0x00fb4b20
	ld	xwa, (xwa)                              ; FB4B1C  ld XWA,(XWA)
	jp	(xwa)                                   ; FB4B1E  jp T,XWA
; 9 x u32 computed-goto table, 0xFB4B20-0xFB4B43, 36 bytes.
; THE ENTRY COUNT IS ESTABLISHED TWICE AND THE TWO AGREE: the `cp rr,8`
; guard before the `jr UGT` gives 9, and reading consecutive words while
; each is a plausible code address also gives 9.  The word after the last
; entry is not a plausible entry, so the table ends here rather than being
; assumed to.  (python3 notes/prom_c_jumptables.py 0xFB405F 0xFB6E0A;
; asserted per table by notes/prom_c_voiceparam_checks.py section 2.)
; Entry 0 is the SAME address the out-of-range guard branches to.
	.long 0x00FB4B44	; 0xFB4B20  entry 0 -> 0xFB4B44   (also the out-of-range arm)
	.long 0x00FB4B44	; 0xFB4B24  entry 1 -> 0xFB4B44
	.long 0x00FB4B44	; 0xFB4B28  entry 2 -> 0xFB4B44
	.long 0x00FB4B44	; 0xFB4B2C  entry 3 -> 0xFB4B44
	.long 0x00FB4B44	; 0xFB4B30  entry 4 -> 0xFB4B44
	.long 0x00FB4B44	; 0xFB4B34  entry 5 -> 0xFB4B44
	.long 0x00FB4B44	; 0xFB4B38  entry 6 -> 0xFB4B44
	.long 0x00FB4B44	; 0xFB4B3C  entry 7 -> 0xFB4B44
	.long 0x00FB4B44	; 0xFB4B40  entry 8 -> 0xFB4B44
sub_FB4A9F__FB4B44:
	extpfx5 0x9E, 0xFE, 0x3E, 0x01, 0x40       ; FB4B44  or (XIZ+0xfe),0x4001
sub_FB4A9F__FB4B49:
	ld	c, (xiz-3)                              ; FB4B49  ld C,(XIZ+0xfd)
	and	c, 3                                   ; FB4B4C  and C,0x03
	ld	(xiz-5), c                              ; FB4B4F  ld (XIZ+0xfb),C
	ld	bc, (xiz+8)                             ; FB4B52  ld BC,(XIZ+0x08)
	extz	bc                                    ; FB4B55  extz BC
	mul	bc, 0x12C                              ; FB4B57  mul BC,0x012c
	ld	hl, bc                                  ; FB4B5B  ld HL,BC
	add	bc, 0xA0                               ; FB4B5D  add BC,0x00a0
	ld	hl, bc                                  ; FB4B61  ld HL,BC
	extz	xbc                                   ; FB4B63  extz XBC
	ld	de, (xbc+0x1523)                        ; FB4B65  ld DE,(XBC+0x1523)
	cp (xiz-5), 0x01                           ; FB4B6A  cp (XIZ+0xfb),0x01
	jr nz, sub_FB4A9F__FB4B7C                  ; FB4B6E  jr NZ,0xfb4b7c
	ld	wa, de                                  ; FB4B70  ld WA,DE
	set	15, wa                                 ; FB4B72  set 0x0f,WA
	ld	(xbc+0x1523), wa                        ; FB4B75  ld (XBC+0x1523),WA
	jr sub_FB4A9F__FB4B88                      ; FB4B7A  jr T,0xfb4b88
sub_FB4A9F__FB4B7C:
	ld	bc, de                                  ; FB4B7C  ld BC,DE
	res	15, bc                                 ; FB4B7E  res 0x0f,BC
	extz	xhl                                   ; FB4B81  extz XHL
	ld	(xhl+0x1523), bc                        ; FB4B83  ld (XHL+0x1523),BC
sub_FB4A9F__FB4B88:
	ld	bc, (xiz+8)                             ; FB4B88  ld BC,(XIZ+0x08)
	extz	bc                                    ; FB4B8B  extz BC
	mul	bc, 0x12C                              ; FB4B8D  mul BC,0x012c
	ld	hl, bc                                  ; FB4B91  ld HL,BC
	extz	xbc                                   ; FB4B93  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB4B95  ld XWA,(XBC+0x1523)
	ld	c, (xwa+17)                             ; FB4B9A  ld C,(XWA+0x11)
	and	c, 4                                   ; FB4B9D  and C,0x04
	jr z, sub_FB4A9F__FB4BA7                   ; FB4BA0  jr Z,0xfb4ba7
	extpfx3 0xBE, 0xFE, 0xB9                   ; FB4BA2  set 1,(XIZ+0xfe)
	jr sub_FB4A9F__FB4C13                      ; FB4BA5  jr T,0xfb4c13
sub_FB4A9F__FB4BA7:
	ld	bc, hl                                  ; FB4BA7  ld BC,HL
	add	bc, 9                                  ; FB4BA9  add BC,0x0009
	extz	xbc                                   ; FB4BAD  extz XBC
	ld	wa, (xbc+0x1523)                        ; FB4BAF  ld WA,(XBC+0x1523)
	and	wa, 0x8000                             ; FB4BB4  and WA,0x8000
	jr z, sub_FB4A9F__FB4C13                   ; FB4BB8  jr Z,0xfb4c13
	extz	xhl                                   ; FB4BBA  extz XHL
	ld	xbc, (xhl+0x1523)                       ; FB4BBC  ld XBC,(XHL+0x1523)
	ld	xix, xbc                                ; FB4BC1  ld XIX,XBC
	ld	a, (xbc+17)                             ; FB4BC3  ld A,(XBC+0x11)
	and	a, 1                                   ; FB4BC6  and A,0x01
	jr z, sub_FB4A9F__FB4C13                   ; FB4BC9  jr Z,0xfb4c13
	ld	a, (xbc+0xD0)                           ; FB4BCB  ld A,(XBC+0x00d0)
	and	a, 15                                  ; FB4BD0  and A,0x0f
	extz	wa                                    ; FB4BD3  extz WA
	extz	xwa                                   ; FB4BD5  extz XWA
	cp	wa, 8                                   ; FB4BD7  cp WA,0x0008
	jr ugt, sub_FB4A9F__FB4C13                 ; FB4BDB  jr UGT,0xfb4c13
	sll	wa, 2                                  ; FB4BDD  sll 0x02,WA
	add	xwa, 0xFB4BEA                          ; FB4BE0  add XWA,0x00fb4bea
	ld	xwa, (xwa)                              ; FB4BE6  ld XWA,(XWA)
	jp	(xwa)                                   ; FB4BE8  jp T,XWA
; 9 x u32 computed-goto table, 0xFB4BEA-0xFB4C0D, 36 bytes.
; THE ENTRY COUNT IS ESTABLISHED TWICE AND THE TWO AGREE: the `cp rr,8`
; guard before the `jr UGT` gives 9, and reading consecutive words while
; each is a plausible code address also gives 9.  The word after the last
; entry is not a plausible entry, so the table ends here rather than being
; assumed to.  (python3 notes/prom_c_jumptables.py 0xFB405F 0xFB6E0A;
; asserted per table by notes/prom_c_voiceparam_checks.py section 2.)
; Entry 0 is the SAME address the out-of-range guard branches to.
	.long 0x00FB4C0E	; 0xFB4BEA  entry 0 -> 0xFB4C0E   (also the out-of-range arm)
	.long 0x00FB4C0E	; 0xFB4BEE  entry 1 -> 0xFB4C0E
	.long 0x00FB4C0E	; 0xFB4BF2  entry 2 -> 0xFB4C0E
	.long 0x00FB4C0E	; 0xFB4BF6  entry 3 -> 0xFB4C0E
	.long 0x00FB4C0E	; 0xFB4BFA  entry 4 -> 0xFB4C0E
	.long 0x00FB4C0E	; 0xFB4BFE  entry 5 -> 0xFB4C0E
	.long 0x00FB4C0E	; 0xFB4C02  entry 6 -> 0xFB4C0E
	.long 0x00FB4C0E	; 0xFB4C06  entry 7 -> 0xFB4C0E
	.long 0x00FB4C0E	; 0xFB4C0A  entry 8 -> 0xFB4C0E
sub_FB4A9F__FB4C0E:
	extpfx5 0x9E, 0xFE, 0x3E, 0x02, 0x80       ; FB4C0E  or (XIZ+0xfe),0x8002
sub_FB4A9F__FB4C13:
	ld	c, (xiz-3)                              ; FB4C13  ld C,(XIZ+0xfd)
	and	c, 12                                  ; FB4C16  and C,0x0c
	ld	(xiz-5), c                              ; FB4C19  ld (XIZ+0xfb),C
	ld	bc, (xiz+8)                             ; FB4C1C  ld BC,(XIZ+0x08)
	extz	bc                                    ; FB4C1F  extz BC
	mul	bc, 0x12C                              ; FB4C21  mul BC,0x012c
	ld	hl, bc                                  ; FB4C25  ld HL,BC
	add	bc, 0xC9                               ; FB4C27  add BC,0x00c9
	ld	hl, bc                                  ; FB4C2B  ld HL,BC
	extz	xbc                                   ; FB4C2D  extz XBC
	ld	de, (xbc+0x1523)                        ; FB4C2F  ld DE,(XBC+0x1523)
	cp (xiz-5), 0x04                           ; FB4C34  cp (XIZ+0xfb),0x04
	jr nz, sub_FB4A9F__FB4C46                  ; FB4C38  jr NZ,0xfb4c46
	ld	wa, de                                  ; FB4C3A  ld WA,DE
	set	15, wa                                 ; FB4C3C  set 0x0f,WA
	ld	(xbc+0x1523), wa                        ; FB4C3F  ld (XBC+0x1523),WA
	jr sub_FB4A9F__FB4C52                      ; FB4C44  jr T,0xfb4c52
sub_FB4A9F__FB4C46:
	ld	bc, de                                  ; FB4C46  ld BC,DE
	res	15, bc                                 ; FB4C48  res 0x0f,BC
	extz	xhl                                   ; FB4C4B  extz XHL
	ld	(xhl+0x1523), bc                        ; FB4C4D  ld (XHL+0x1523),BC
sub_FB4A9F__FB4C52:
	ld	bc, (xiz+8)                             ; FB4C52  ld BC,(XIZ+0x08)
	extz	bc                                    ; FB4C55  extz BC
	mul	bc, 0x12C                              ; FB4C57  mul BC,0x012c
	extz	xbc                                   ; FB4C5B  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB4C5D  ld XWA,(XBC+0x1523)
	ld	c, (xwa+17)                             ; FB4C62  ld C,(XWA+0x11)
	and	c, 16                                  ; FB4C65  and C,0x10
	jr z, sub_FB4A9F__FB4C6D                   ; FB4C68  jr Z,0xfb4c6d
	extpfx3 0xBE, 0xFE, 0xBA                   ; FB4C6A  set 2,(XIZ+0xfe)
sub_FB4A9F__FB4C6D:
	ld	c, (xiz-3)                              ; FB4C6D  ld C,(XIZ+0xfd)
	and	c, 48                                  ; FB4C70  and C,0x30
	ld	(xiz-5), c                              ; FB4C73  ld (XIZ+0xfb),C
	ld	bc, (xiz+8)                             ; FB4C76  ld BC,(XIZ+0x08)
	extz	bc                                    ; FB4C79  extz BC
	mul	bc, 0x12C                              ; FB4C7B  mul BC,0x012c
	ld	hl, bc                                  ; FB4C7F  ld HL,BC
	add	bc, 0xF2                               ; FB4C81  add BC,0x00f2
	ld	hl, bc                                  ; FB4C85  ld HL,BC
	extz	xbc                                   ; FB4C87  extz XBC
	ld	de, (xbc+0x1523)                        ; FB4C89  ld DE,(XBC+0x1523)
	cp (xiz-5), 0x10                           ; FB4C8E  cp (XIZ+0xfb),0x10
	jr nz, sub_FB4A9F__FB4CA0                  ; FB4C92  jr NZ,0xfb4ca0
	ld	wa, de                                  ; FB4C94  ld WA,DE
	set	15, wa                                 ; FB4C96  set 0x0f,WA
	ld	(xbc+0x1523), wa                        ; FB4C99  ld (XBC+0x1523),WA
	jr sub_FB4A9F__FB4CAC                      ; FB4C9E  jr T,0xfb4cac
sub_FB4A9F__FB4CA0:
	ld	bc, de                                  ; FB4CA0  ld BC,DE
	res	15, bc                                 ; FB4CA2  res 0x0f,BC
	extz	xhl                                   ; FB4CA5  extz XHL
	ld	(xhl+0x1523), bc                        ; FB4CA7  ld (XHL+0x1523),BC
sub_FB4A9F__FB4CAC:
	ld	bc, (xiz+8)                             ; FB4CAC  ld BC,(XIZ+0x08)
	extz	bc                                    ; FB4CAF  extz BC
	mul	bc, 0x12C                              ; FB4CB1  mul BC,0x012c
	extz	xbc                                   ; FB4CB5  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB4CB7  ld XWA,(XBC+0x1523)
	ld	c, (xwa+17)                             ; FB4CBC  ld C,(XWA+0x11)
	and	c, 64                                  ; FB4CBF  and C,0x40
	jr z, sub_FB4A9F__FB4CC7                   ; FB4CC2  jr Z,0xfb4cc7
	extpfx3 0xBE, 0xFE, 0xBB                   ; FB4CC4  set 3,(XIZ+0xfe)
sub_FB4A9F__FB4CC7:
	ld	c, (xiz-3)                              ; FB4CC7  ld C,(XIZ+0xfd)
	and	c, 0xC0                                ; FB4CCA  and C,0xc0
	ld	(xiz-5), c                              ; FB4CCD  ld (XIZ+0xfb),C
	ld	bc, (xiz+8)                             ; FB4CD0  ld BC,(XIZ+0x08)
	extz	bc                                    ; FB4CD3  extz BC
	mul	bc, 0x12C                              ; FB4CD5  mul BC,0x012c
	ld	hl, bc                                  ; FB4CD9  ld HL,BC
	add	bc, 0x11B                              ; FB4CDB  add BC,0x011b
	ld	hl, bc                                  ; FB4CDF  ld HL,BC
	extz	xbc                                   ; FB4CE1  extz XBC
	ld	de, (xbc+0x1523)                        ; FB4CE3  ld DE,(XBC+0x1523)
	cp (xiz-5), 0x40                           ; FB4CE8  cp (XIZ+0xfb),0x40
	jr nz, sub_FB4A9F__FB4CFA                  ; FB4CEC  jr NZ,0xfb4cfa
	ld	wa, de                                  ; FB4CEE  ld WA,DE
	set	15, wa                                 ; FB4CF0  set 0x0f,WA
	ld	(xbc+0x1523), wa                        ; FB4CF3  ld (XBC+0x1523),WA
	jr sub_FB4A9F__FB4D06                      ; FB4CF8  jr T,0xfb4d06
sub_FB4A9F__FB4CFA:
	ld	bc, de                                  ; FB4CFA  ld BC,DE
	res	15, bc                                 ; FB4CFC  res 0x0f,BC
	extz	xhl                                   ; FB4CFF  extz XHL
	ld	(xhl+0x1523), bc                        ; FB4D01  ld (XHL+0x1523),BC
sub_FB4A9F__FB4D06:
	ld	bc, (xiz+8)                             ; FB4D06  ld BC,(XIZ+0x08)
	extz	bc                                    ; FB4D09  extz BC
	mul	bc, 0x12C                              ; FB4D0B  mul BC,0x012c
	inc	6, bc                                  ; FB4D0F  inc 6,BC
	extz	xbc                                   ; FB4D11  extz XBC
	ld	wa, (xiz-2)                             ; FB4D13  ld WA,(XIZ+0xfe)
	ld	(xbc+0x1523), wa                        ; FB4D16  ld (XBC+0x1523),WA
	pop	xix                                    ; FB4D1B  pop XIX
	popw	de                                    ; FB4D1C  pop DE
	pop	xhl                                    ; FB4D1D  pop XHL
	unlk32 xiz                                 ; FB4D1E  unlk XIZ
	ret                                        ; FB4D20  ret
; --------------------------------------------------------------------------
; sub_FB4D21 -- 0xFB4D21..0xFB4D44 (36 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFB4E55
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFB4D21-0xFB4D44
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FB4D21:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB4D21  link XIZ,0x0000
	pushw	hl                                   ; FB4D25  push HL
	ld	hl, (xiz+8)                             ; FB4D26  ld HL,(XIZ+0x08)
	cp	hl, 0x7F                                ; FB4D29  cp HL,0x007f
	jr le, sub_FB4D21__FB4D34                  ; FB4D2D  jr LE,0xfb4d34
	ldw	hl, 0x7F                               ; FB4D2F  ld HL,0x007f
	jr sub_FB4D21__FB4D3B                      ; FB4D32  jr T,0xfb4d3b
sub_FB4D21__FB4D34:
	cps	hl, 0                                  ; FB4D34  cp HL,0
	jr ge, sub_FB4D21__FB4D3B                  ; FB4D36  jr GE,0xfb4d3b
	ldw	hl, 0                                  ; FB4D38  ld HL,0x0000
sub_FB4D21__FB4D3B:
	ld	c, l                                    ; FB4D3B  ld C,L
	exts	bc                                    ; FB4D3D  exts BC
	ld	wa, bc                                  ; FB4D3F  ld WA,BC
	popw	hl                                    ; FB4D41  pop HL
	unlk32 xiz                                 ; FB4D42  unlk XIZ
	ret                                        ; FB4D44  ret
; --------------------------------------------------------------------------
; sub_FB4D45 -- 0xFB4D45..0xFB501E (730 bytes)
;
; Called from: 7 site(s) outside this module:
;          0xFAEDB7 in PartRec_ApplyParam_0025, 0xFAFC49 in sub_FAFBEC__FAFC28
;          0xFAFEB2 in MidiCtrl_Dispatch__FAFEA3, 0xFBBACD in sub_FBB793__FBBABE
;          0xFBBC83 in sub_FBB793__FBBC74, 0xFBBCB0 in sub_FBB793__FBBC8B
;          0xFBC3F4 in sub_FBC39D__FBC3EF
;          2 site(s) inside this module:
;          0xFB66A8 0xFB6905
; Inputs:  frame `link XIZ,-34`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Calls:   0xFB4D21 = sub_FB4D21
; Evidence: the listing below is the byte-identical round-trip of 0xFB4D45-0xFB501E
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FB4D45:
	link32 0xEE, 0x0C, 0xDE, 0xFF              ; FB4D45  link XIZ,0xffde
	pushw	hl                                   ; FB4D49  push HL
	pushw	de                                   ; FB4D4A  push DE
	push	xix                                   ; FB4D4B  push XIX
	ld	bc, (xiz+8)                             ; FB4D4C  ld BC,(XIZ+0x08)
	extz	bc                                    ; FB4D4F  extz BC
	mul	bc, 0x12C                              ; FB4D51  mul BC,0x012c
	ld	de, bc                                  ; FB4D55  ld DE,BC
	extz	xbc                                   ; FB4D57  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB4D59  ld XWA,(XBC+0x1523)
	ld	(xiz-10), xwa                           ; FB4D5E  ld (XIZ+0xf6),XWA
	ldw	bc, 0x1523                             ; FB4D61  ld BC,0x1523
	add	bc, de                                 ; FB4D64  add BC,DE
	ld	(xiz-12), bc                            ; FB4D66  ld (XIZ+0xf4),BC
	ld	iy, de                                  ; FB4D69  ld IY,DE
	inc	6, iy                                  ; FB4D6B  inc 6,IY
	extz	xiy                                   ; FB4D6D  extz XIY
	ld	hl, (xiy+0x1523)                        ; FB4D6F  ld HL,(XIY+0x1523)
	ld	iy, hl                                  ; FB4D74  ld IY,HL
	and	iy, 0x4000                             ; FB4D76  and IY,0x4000
	jr z, sub_FB4D45__FB4D8D                   ; FB4D7A  jr Z,0xfb4d8d
	extz	xbc                                   ; FB4D7C  extz XBC
	ld	xiy, (xbc+0xB1)                         ; FB4D7E  ld XIY,(XBC+0x00b1)
	ld	c, (xiy+1)                              ; FB4D83  ld C,(XIY+0x01)
	extz	bc                                    ; FB4D86  extz BC
	ld	(xiz-20), bc                            ; FB4D88  ld (XIZ+0xec),BC
	jr sub_FB4D45__FB4DA7                      ; FB4D8B  jr T,0xfb4da7
sub_FB4D45__FB4D8D:
	ld	bc, (xiz-12)                            ; FB4D8D  ld BC,(XIZ+0xf4)
	extz	xbc                                   ; FB4D90  extz XBC
	ld	xwa, (xbc+0x88)                         ; FB4D92  ld XWA,(XBC+0x0088)
	ld	c, (xwa+1)                              ; FB4D97  ld C,(XWA+0x01)
	extz	bc                                    ; FB4D9A  extz BC
	ld	(xiz-20), bc                            ; FB4D9C  ld (XIZ+0xec),BC
	ld	bc, hl                                  ; FB4D9F  ld BC,HL
	and	bc, 0x8000                             ; FB4DA1  and BC,0x8000
	jr z, sub_FB4D45__FB4DAF                   ; FB4DA5  jr Z,0xfb4daf
sub_FB4D45__FB4DA7:
	ld	bc, (xiz-20)                            ; FB4DA7  ld BC,(XIZ+0xec)
	ld	(xiz-18), bc                            ; FB4DAA  ld (XIZ+0xee),BC
	jr sub_FB4D45__FB4DC1                      ; FB4DAD  jr T,0xfb4dc1
sub_FB4D45__FB4DAF:
	ld	bc, (xiz-12)                            ; FB4DAF  ld BC,(XIZ+0xf4)
	extz	xbc                                   ; FB4DB2  extz XBC
	ld	xwa, (xbc+0xB1)                         ; FB4DB4  ld XWA,(XBC+0x00b1)
	ld	c, (xwa+1)                              ; FB4DB9  ld C,(XWA+0x01)
	extz	bc                                    ; FB4DBC  extz BC
	ld	(xiz-18), bc                            ; FB4DBE  ld (XIZ+0xee),BC
sub_FB4D45__FB4DC1:
	ld	bc, (xiz-12)                            ; FB4DC1  ld BC,(XIZ+0xf4)
	extz	xbc                                   ; FB4DC4  extz XBC
	ld	xwa, (xbc+0xDA)                         ; FB4DC6  ld XWA,(XBC+0x00da)
	ld	c, (xwa+1)                              ; FB4DCB  ld C,(XWA+0x01)
	extz	bc                                    ; FB4DCE  extz BC
	ld	(xiz-16), bc                            ; FB4DD0  ld (XIZ+0xf0),BC
	ld	bc, (xiz-12)                            ; FB4DD3  ld BC,(XIZ+0xf4)
	extz	xbc                                   ; FB4DD6  extz XBC
	ld	xwa, (xbc+0x103)                        ; FB4DD8  ld XWA,(XBC+0x0103)
	ld	c, (xwa+1)                              ; FB4DDD  ld C,(XWA+0x01)
	extz	bc                                    ; FB4DE0  extz BC
	ld	(xiz-14), bc                            ; FB4DE2  ld (XIZ+0xf2),BC
	ld	bc, (xiz+8)                             ; FB4DE5  ld BC,(XIZ+0x08)
	extz	bc                                    ; FB4DE8  extz BC
	mul	bc, 0x12C                              ; FB4DEA  mul BC,0x012c
	ld	(xiz-6), bc                             ; FB4DEE  ld (XIZ+0xfa),BC
	add	bc, 37                                 ; FB4DF1  add BC,0x0025
	ld	(xiz-4), bc                             ; FB4DF5  ld (XIZ+0xfc),BC
	ldw	hl, 0                                  ; FB4DF8  ld HL,0x0000
	ld	xix, 0                                  ; FB4DFB  ld XIX,0x00000000
sub_FB4D45__FB4E00:
	ld	(xiz-24), hl                            ; FB4E00  ld (XIZ+0xe8),HL
	ld	de, (xiz-6)                             ; FB4E03  ld DE,(XIZ+0xfa)
	ld	bc, (xiz-24)                            ; FB4E06  ld BC,(XIZ+0xe8)
	add	de, bc                                 ; FB4E09  add DE,BC
	ld	bc, de                                  ; FB4E0B  ld BC,DE
	add	bc, 0xA2                               ; FB4E0D  add BC,0x00a2
	extz	xbc                                   ; FB4E11  extz XBC
	ld	wa, (xbc+0x1523)                        ; FB4E13  ld WA,(XBC+0x1523)
	and	wa, 64                                 ; FB4E18  and WA,0x0040
	jr z, sub_FB4D45__FB4E60                   ; FB4E1C  jr Z,0xfb4e60
	ld	bc, de                                  ; FB4E1E  ld BC,DE
	add	bc, 0xA4                               ; FB4E20  add BC,0x00a4
	extz	xbc                                   ; FB4E24  extz XBC
	ld	wa, (xbc+0x1523)                        ; FB4E26  ld WA,(XBC+0x1523)
	and	wa, 64                                 ; FB4E2B  and WA,0x0040
	ld	(xiz-24), wa                            ; FB4E2F  ld (XIZ+0xe8),WA
	ld	bc, (xiz-4)                             ; FB4E32  ld BC,(XIZ+0xfc)
	extz	xbc                                   ; FB4E35  extz XBC
	ld	de, (xbc+0x1523)                        ; FB4E37  ld DE,(XBC+0x1523)
	ld	xiy, xix                                ; FB4E3C  ld XIY,XIX
	add	xiy, xiz                               ; FB4E3E  add XIY,XIZ
	ld	iy, (xiy-20)                            ; FB4E40  ld IY,(XIY+0xec)
	ld	(xiz-2), iy                             ; FB4E43  ld (XIZ+0xfe),IY
	cps	wa, 0                                  ; FB4E46  cp WA,0
	jr z, sub_FB4D45__FB4E4F                   ; FB4E48  jr Z,0xfb4e4f
	sub	iy, de                                 ; FB4E4A  sub IY,DE
	pushw	iy                                   ; FB4E4C  push IY
	jr sub_FB4D45__FB4E55                      ; FB4E4D  jr T,0xfb4e55
sub_FB4D45__FB4E4F:
	ld	bc, (xiz-2)                             ; FB4E4F  ld BC,(XIZ+0xfe)
	add	bc, de                                 ; FB4E52  add BC,DE
	pushw	bc                                   ; FB4E54  push BC
sub_FB4D45__FB4E55:
	calr (0xFB4D21 - 0xFB4E58)                 ; FB4E55  calr 0xfb4d21
	ld	xbc, xix                                ; FB4E58  ld XBC,XIX
	add	xbc, xiz                               ; FB4E5A  add XBC,XIZ
	ld	(xbc-20), wa                            ; FB4E5C  ld (XBC+0xec),WA
	popw	bc                                    ; FB4E5F  pop BC
sub_FB4D45__FB4E60:
	add	hl, 41                                 ; FB4E60  add HL,0x0029
	inc	2, xix                                 ; FB4E64  inc 2,XIX
	cp	hl, 0xA4                                ; FB4E66  cp HL,0x00a4
	jr c, sub_FB4D45__FB4E00                   ; FB4E6A  jr C,0xfb4e00
	ld	bc, (xiz+8)                             ; FB4E6C  ld BC,(XIZ+0x08)
	extz	bc                                    ; FB4E6F  extz BC
	mul	bc, 0x12C                              ; FB4E71  mul BC,0x012c
	add	bc, 13                                 ; FB4E75  add BC,0x000d
	extz	xbc                                   ; FB4E79  extz XBC
	ld	a, (xbc+0x1523)                         ; FB4E7B  ld A,(XBC+0x1523)
	extz	wa                                    ; FB4E80  extz WA
	sub	wa, 64                                 ; FB4E82  sub WA,0x0040
	ld	(xiz-22), wa                            ; FB4E86  ld (XIZ+0xea),WA
	sub	xbc, xbc                               ; FB4E89  sub XBC,XBC
	ld	(xiz-6), xbc                            ; FB4E8B  ld (XIZ+0xfa),XBC
	ldw	hl, 0                                  ; FB4E8E  ld HL,0x0000
	ldw (xiz-2), 0x00AF                        ; FB4E91  ld (XIZ+0xfe),0x00af
	ldw	de, 0xB0                               ; FB4E96  ld DE,0x00b0
sub_FB4D45__FB4E99:
	ld	xix, (xiz-6)                            ; FB4E99  ld XIX,(XIZ+0xfa)
	ld	xbc, xix                                ; FB4E9C  ld XBC,XIX
	add	xbc, xiz                               ; FB4E9E  add XBC,XIZ
	ld	wa, (xiz-22)                            ; FB4EA0  ld WA,(XIZ+0xea)
	add	(xbc-20), wa                           ; FB4EA3  add (XBC+0xec),WA
	ld	xbc, xix                                ; FB4EA6  ld XBC,XIX
	add	xbc, xiz                               ; FB4EA8  add XBC,XIZ
	ld	bc, (xbc-20)                            ; FB4EAA  ld BC,(XBC+0xec)
	cp	bc, 0x7F                                ; FB4EAD  cp BC,0x007f
	jr le, sub_FB4D45__FB4EBE                  ; FB4EB1  jr LE,0xfb4ebe
	ld	xbc, xix                                ; FB4EB3  ld XBC,XIX
	add	xbc, xiz                               ; FB4EB5  add XBC,XIZ
	extpfx5 0xB9, 0xEC, 0x02, 0x7F, 0x00       ; FB4EB7  ld (XBC+0xec),0x007f
	jr sub_FB4D45__FB4ED2                      ; FB4EBC  jr T,0xfb4ed2
sub_FB4D45__FB4EBE:
	ld	xbc, xix                                ; FB4EBE  ld XBC,XIX
	add	xbc, xiz                               ; FB4EC0  add XBC,XIZ
	ld	bc, (xbc-20)                            ; FB4EC2  ld BC,(XBC+0xec)
	cps	bc, 0                                  ; FB4EC5  cp BC,0
	jr ge, sub_FB4D45__FB4ED2                  ; FB4EC7  jr GE,0xfb4ed2
	ld	xbc, xix                                ; FB4EC9  ld XBC,XIX
	add	xbc, xiz                               ; FB4ECB  add XBC,XIZ
	extpfx5 0xB9, 0xEC, 0x02, 0x00, 0x00       ; FB4ECD  ld (XBC+0xec),0x0000
sub_FB4D45__FB4ED2:
	ld	xix, (xiz-6)                            ; FB4ED2  ld XIX,(XIZ+0xfa)
	ld	(xiz-26), xix                           ; FB4ED5  ld (XIZ+0xe6),XIX
	ld	xbc, (xiz-26)                           ; FB4ED8  ld XBC,(XIZ+0xe6)
	add	xbc, xiz                               ; FB4EDB  add XBC,XIZ
	ld	a, (xbc-20)                             ; FB4EDD  ld A,(XBC+0xec)
	ld	(xiz-28), a                             ; FB4EE0  ld (XIZ+0xe4),A
	ld	bc, (xiz-2)                             ; FB4EE3  ld BC,(XIZ+0xfe)
	ld	(xiz-30), bc                            ; FB4EE6  ld (XIZ+0xe2),BC
	extz	xbc                                   ; FB4EE9  extz XBC
	extpfx3 0x9E, 0xF4, 0x81                   ; FB4EEB  add BC,(XIZ+0xf4)
	ld	(xbc), a                                ; FB4EEE  ld (XBC),A
	ld	xbc, (xiz-26)                           ; FB4EF0  ld XBC,(XIZ+0xe6)
	add	xbc, xiz                               ; FB4EF3  add XBC,XIZ
	ld	a, (xbc-20)                             ; FB4EF5  ld A,(XBC+0xec)
	ld	(xiz-32), a                             ; FB4EF8  ld (XIZ+0xe0),A
	ld	(xiz-34), de                            ; FB4EFB  ld (XIZ+0xde),DE
	ld	bc, (xiz-12)                            ; FB4EFE  ld BC,(XIZ+0xf4)
	extz	xbc                                   ; FB4F01  extz XBC
	extpfx3 0x9E, 0xDE, 0x81                   ; FB4F03  add BC,(XIZ+0xde)
	ld	(xbc), a                                ; FB4F06  ld (XBC),A
	ld	xbc, xix                                ; FB4F08  ld XBC,XIX
	inc	2, xbc                                 ; FB4F0A  inc 2,XBC
	ld	(xiz-6), xbc                            ; FB4F0C  ld (XIZ+0xfa),XBC
	add	hl, 41                                 ; FB4F0F  add HL,0x0029
	ld	de, (xiz-34)                            ; FB4F13  ld DE,(XIZ+0xde)
	add	de, 41                                 ; FB4F16  add DE,0x0029
	ld	wa, (xiz-30)                            ; FB4F1A  ld WA,(XIZ+0xe2)
	add	wa, 41                                 ; FB4F1D  add WA,0x0029
	ld	(xiz-2), wa                             ; FB4F21  ld (XIZ+0xfe),WA
	cp	hl, 0xA4                                ; FB4F24  cp HL,0x00a4
	jrl c, sub_FB4D45__FB4E99                  ; FB4F28  jrl C,0xfb4e99
	ld	xiy, (xiz-10)                           ; FB4F2B  ld XIY,(XIZ+0xf6)
	ld	l, (xiy+0xD0)                           ; FB4F2E  ld L,(XIY+0x00d0)
	ld	bc, (xiz-12)                            ; FB4F33  ld BC,(XIZ+0xf4)
	extz	xbc                                   ; FB4F36  extz XBC
	ld	wa, (xbc+9)                             ; FB4F38  ld WA,(XBC+0x09)
	and	wa, 0x8000                             ; FB4F3B  and WA,0x8000
	jrl z, sub_FB4D45__FB5019                  ; FB4F3F  jrl Z,0xfb5019
	ld	a, l                                    ; FB4F42  ld A,L
	and	a, 64                                  ; FB4F44  and A,0x40
	jrl z, sub_FB4D45__FB5019                  ; FB4F47  jrl Z,0xfb5019
	ld	de, (xiz-18)                            ; FB4F4A  ld DE,(XIZ+0xee)
	ld	wa, (xiz-20)                            ; FB4F4D  ld WA,(XIZ+0xec)
	cp	wa, de                                  ; FB4F50  cp WA,DE
	jrl nz, sub_FB4D45__FB5019                 ; FB4F52  jrl NZ,0xfb5019
	ld	h, l                                    ; FB4F55  ld H,L
	and	h, 15                                  ; FB4F57  and H,0x0f
	cp	h, 9                                    ; FB4F5A  cp H,0x09
	jr nz, sub_FB4D45__FB4F9A                  ; FB4F5D  jr NZ,0xfb4f9a
	ld	h, (xiz-20)                             ; FB4F5F  ld H,(XIZ+0xec)
	cp	h, 64                                   ; FB4F62  cp H,0x40
	jr ge, sub_FB4D45__FB4F7E                  ; FB4F65  jr GE,0xfb4f7e
	ld	l, h                                    ; FB4F67  ld L,H
	add	l, 40                                  ; FB4F69  add L,0x28
	ld	(xbc+0xB0), l                           ; FB4F6C  ld (XBC+0x00b0),L
	ld	bc, (xiz-12)                            ; FB4F71  ld BC,(XIZ+0xf4)
	extz	xbc                                   ; FB4F74  extz XBC
	ld	(xbc+0xD9), l                           ; FB4F76  ld (XBC+0x00d9),L
	jrl sub_FB4D45__FB5019                     ; FB4F7B  jrl T,0xfb5019
sub_FB4D45__FB4F7E:
	ld	l, h                                    ; FB4F7E  ld L,H
	sub	l, 40                                  ; FB4F80  sub L,0x28
	ld	bc, (xiz-12)                            ; FB4F83  ld BC,(XIZ+0xf4)
	extz	xbc                                   ; FB4F86  extz XBC
	ld	(xbc+0xB0), l                           ; FB4F88  ld (XBC+0x00b0),L
	ld	bc, (xiz-12)                            ; FB4F8D  ld BC,(XIZ+0xf4)
	extz	xbc                                   ; FB4F90  extz XBC
	ld	(xbc+0xD9), l                           ; FB4F92  ld (XBC+0x00d9),L
	jrl sub_FB4D45__FB5019                     ; FB4F97  jrl T,0xfb5019
sub_FB4D45__FB4F9A:
	cp	h, 10                                   ; FB4F9A  cp H,0x0a
	jrl nc, sub_FB4D45__FB5019                 ; FB4F9D  jrl NC,0xfb5019
	ld	h, (xiz-20)                             ; FB4FA0  ld H,(XIZ+0xec)
	cp	h, 64                                   ; FB4FA3  cp H,0x40
	jr ge, sub_FB4D45__FB4FE5                  ; FB4FA6  jr GE,0xfb4fe5
	ld	c, h                                    ; FB4FA8  ld C,H
	exts	bc                                    ; FB4FAA  exts BC
	sub	bc, 16                                 ; FB4FAC  sub BC,0x0010
	cps	bc, 0                                  ; FB4FB0  cp BC,0
	jr ge, sub_FB4D45__FB4FC1                  ; FB4FB2  jr GE,0xfb4fc1
	ld	bc, (xiz-12)                            ; FB4FB4  ld BC,(XIZ+0xf4)
	extz	xbc                                   ; FB4FB7  extz XBC
	ld	(xbc+0xAF), 0                           ; FB4FB9  ld (XBC+0x00af),0x00
	jr sub_FB4D45__FB4FD2                      ; FB4FBF  jr T,0xfb4fd2
sub_FB4D45__FB4FC1:
	ld	c, h                                    ; FB4FC1  ld C,H
	sub	c, 16                                  ; FB4FC3  sub C,0x10
	ld	l, c                                    ; FB4FC6  ld L,C
	ld	bc, (xiz-12)                            ; FB4FC8  ld BC,(XIZ+0xf4)
	extz	xbc                                   ; FB4FCB  extz XBC
	ld	(xbc+0xAF), l                           ; FB4FCD  ld (XBC+0x00af),L
sub_FB4D45__FB4FD2:
	ld	c, h                                    ; FB4FD2  ld C,H
	add	c, 40                                  ; FB4FD4  add C,0x28
	ld	h, c                                    ; FB4FD7  ld H,C
	ld	bc, (xiz-12)                            ; FB4FD9  ld BC,(XIZ+0xf4)
	extz	xbc                                   ; FB4FDC  extz XBC
	ld	(xbc+0xD8), h                           ; FB4FDE  ld (XBC+0x00d8),H
	jr sub_FB4D45__FB5019                      ; FB4FE3  jr T,0xfb5019
sub_FB4D45__FB4FE5:
	cp	h, 0x6F                                 ; FB4FE5  cp H,0x6f
	jr le, sub_FB4D45__FB4FF7                  ; FB4FE8  jr LE,0xfb4ff7
	ld	bc, (xiz-12)                            ; FB4FEA  ld BC,(XIZ+0xf4)
	extz	xbc                                   ; FB4FED  extz XBC
	ld	(xbc+0xAF), 0x7F                        ; FB4FEF  ld (XBC+0x00af),0x7f
	jr sub_FB4D45__FB5008                      ; FB4FF5  jr T,0xfb5008
sub_FB4D45__FB4FF7:
	ld	c, h                                    ; FB4FF7  ld C,H
	add	c, 16                                  ; FB4FF9  add C,0x10
	ld	l, c                                    ; FB4FFC  ld L,C
	ld	bc, (xiz-12)                            ; FB4FFE  ld BC,(XIZ+0xf4)
	extz	xbc                                   ; FB5001  extz XBC
	ld	(xbc+0xAF), l                           ; FB5003  ld (XBC+0x00af),L
sub_FB4D45__FB5008:
	ld	c, h                                    ; FB5008  ld C,H
	sub	c, 40                                  ; FB500A  sub C,0x28
	ld	h, c                                    ; FB500D  ld H,C
	ld	bc, (xiz-12)                            ; FB500F  ld BC,(XIZ+0xf4)
	extz	xbc                                   ; FB5012  extz XBC
	ld	(xbc+0xD8), h                           ; FB5014  ld (XBC+0x00d8),H
sub_FB4D45__FB5019:
	pop	xix                                    ; FB5019  pop XIX
	popw	de                                    ; FB501A  pop DE
	popw	hl                                    ; FB501B  pop HL
	unlk32 xiz                                 ; FB501C  unlk XIZ
	ret                                        ; FB501E  ret
; --------------------------------------------------------------------------
; sub_FB501F -- 0xFB501F..0xFB5102 (228 bytes)
;
; Called from: 7 site(s) outside this module:
;          0xFAE296 in Voice_RestageArm_BaseCurve_Shared, 0xFB8A0A in Voice_RecomputeEnv_AndWriteSlot2
;          0xFB8B08 in Voice_RecomputeEnv_AndWriteSlot1, 0xFB8C08 in Voice_RecomputeEnv_AndWriteSlot1or3
;          0xFBC481 in sub_FBC39D__FBC463, 0xFBC4F6 in sub_FBC39D__FBC4D8
;          0xFBC58B in sub_FBC39D__FBC56D
; Inputs:  frame `link XIZ,-4`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFB501F-0xFB5102
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FB501F:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FB501F  link XIZ,0xfffc
	pushw	hl                                   ; FB5023  push HL
	pushw	de                                   ; FB5024  push DE
	push	xix                                   ; FB5025  push XIX
	ldb	c, 16                                  ; FB5026  ld C,0x10
	extpfx3 0x8E, 0x0A, 0x43                   ; FB5028  mul BC,(XIZ+0x0a)
	ld	hl, bc                                  ; FB502B  ld HL,BC
	ld	wa, (xiz+8)                             ; FB502D  ld WA,(XIZ+0x08)
	extz	wa                                    ; FB5030  extz WA
	mul	wa, 0x12C                              ; FB5032  mul WA,0x012c
	ld	ix, wa                                  ; FB5036  ld IX,WA
	add	ix, bc                                 ; FB5038  add IX,BC
	ldb	c, 4                                   ; FB503A  ld C,0x04
	extpfx3 0x8E, 0x0C, 0x43                   ; FB503C  mul BC,(XIZ+0x0c)
	add	bc, ix                                 ; FB503F  add BC,IX
	ld	hl, bc                                  ; FB5041  ld HL,BC
	add	hl, 53                                 ; FB5043  add HL,0x0035
	ldw	bc, 0x1523                             ; FB5047  ld BC,0x1523
	add	bc, hl                                 ; FB504A  add BC,HL
	ld	(xiz-2), bc                             ; FB504C  ld (XIZ+0xfe),BC
	extz	xbc                                   ; FB504F  extz XBC
	extpfx3 0x81, 0x3C, 0xFC                   ; FB5051  and (XBC),0xfc
	ld	bc, (xiz-2)                             ; FB5054  ld BC,(XIZ+0xfe)
	extz	xbc                                   ; FB5057  extz XBC
	ld	a, (xbc+3)                              ; FB5059  ld A,(XBC+0x03)
	cps	a, 0                                   ; FB505C  cp A,0
	jr z, sub_FB501F__FB506E                   ; FB505E  jr Z,0xfb506e
	ld	a, (xbc+1)                              ; FB5060  ld A,(XBC+0x01)
	and	a, 85                                  ; FB5063  and A,0x55
	jr z, sub_FB501F__FB506E                   ; FB5066  jr Z,0xfb506e
	extpfx3 0x81, 0x3E, 0x02                   ; FB5068  or (XBC),0x02
	jrl sub_FB501F__FB50FD                     ; FB506B  jrl T,0xfb50fd
sub_FB501F__FB506E:
	ld	bc, (xiz+8)                             ; FB506E  ld BC,(XIZ+0x08)
	extz	bc                                    ; FB5071  extz BC
	mul	bc, 0x12C                              ; FB5073  mul BC,0x012c
	ld	xix, xbc                                ; FB5077  ld XIX,XBC
	ldw	hl, 0                                  ; FB5079  ld HL,0x0000
	ldb	d, 4                                   ; FB507C  ld D,0x04
sub_FB501F__FB507E:
	ld	bc, (xiz+10)                            ; FB507E  ld BC,(XIZ+0x0a)
	extz	bc                                    ; FB5081  extz BC
	cps	bc, 0                                  ; FB5083  cp BC,0
	jr z, sub_FB501F__FB5091                   ; FB5085  jr Z,0xfb5091
	cps	bc, 1                                  ; FB5087  cp BC,1
	jr z, sub_FB501F__FB50A9                   ; FB5089  jr Z,0xfb50a9
	cps	bc, 2                                  ; FB508B  cp BC,2
	jr z, sub_FB501F__FB50C1                   ; FB508D  jr Z,0xfb50c1
	jr sub_FB501F__FB50D7                      ; FB508F  jr T,0xfb50d7
sub_FB501F__FB5091:
	ld	(xiz-4), hl                             ; FB5091  ld (XIZ+0xfc),HL
	ld	bc, ix                                  ; FB5094  ld BC,IX
	extpfx3 0x9E, 0xFC, 0x81                   ; FB5096  add BC,(XIZ+0xfc)
	add	bc, 0x88                               ; FB5099  add BC,0x0088
	extz	xbc                                   ; FB509D  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB509F  ld XWA,(XBC+0x1523)
	ld	e, (xwa+6)                              ; FB50A4  ld E,(XWA+0x06)
	jr sub_FB501F__FB50D7                      ; FB50A7  jr T,0xfb50d7
sub_FB501F__FB50A9:
	ld	(xiz-4), hl                             ; FB50A9  ld (XIZ+0xfc),HL
	ld	bc, ix                                  ; FB50AC  ld BC,IX
	extpfx3 0x9E, 0xFC, 0x81                   ; FB50AE  add BC,(XIZ+0xfc)
	add	bc, 0x88                               ; FB50B1  add BC,0x0088
	extz	xbc                                   ; FB50B5  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB50B7  ld XWA,(XBC+0x1523)
	ld	e, (xwa+38)                             ; FB50BC  ld E,(XWA+0x26)
	jr sub_FB501F__FB50D7                      ; FB50BF  jr T,0xfb50d7
sub_FB501F__FB50C1:
	ld	(xiz-4), hl                             ; FB50C1  ld (XIZ+0xfc),HL
	ld	bc, ix                                  ; FB50C4  ld BC,IX
	extpfx3 0x9E, 0xFC, 0x81                   ; FB50C6  add BC,(XIZ+0xfc)
	add	bc, 0x88                               ; FB50C9  add BC,0x0088
	extz	xbc                                   ; FB50CD  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB50CF  ld XWA,(XBC+0x1523)
	ld	e, (xwa+56)                             ; FB50D4  ld E,(XWA+0x38)
sub_FB501F__FB50D7:
	ld	c, e                                    ; FB50D7  ld C,E
	and	c, 32                                  ; FB50D9  and C,0x20
	jr z, sub_FB501F__FB50F3                   ; FB50DC  jr Z,0xfb50f3
	ld	c, e                                    ; FB50DE  ld C,E
	and	c, 0xC0                                ; FB50E0  and C,0xc0
	srl	c, 6                                   ; FB50E3  srl 0x06,C
	extpfx3 0x8E, 0x0C, 0xF3                   ; FB50E6  cp C,(XIZ+0x0c)
	jr nz, sub_FB501F__FB50F3                  ; FB50E9  jr NZ,0xfb50f3
	ld	bc, (xiz-2)                             ; FB50EB  ld BC,(XIZ+0xfe)
	extz	xbc                                   ; FB50EE  extz XBC
	extpfx3 0x81, 0x3E, 0x01                   ; FB50F0  or (XBC),0x01
sub_FB501F__FB50F3:
	add	hl, 41                                 ; FB50F3  add HL,0x0029
	dec	1, d                                   ; FB50F7  dec 1,D
	cps	d, 0                                   ; FB50F9  cp D,0
	jr nz, sub_FB501F__FB507E                  ; FB50FB  jr NZ,0xfb507e
sub_FB501F__FB50FD:
	pop	xix                                    ; FB50FD  pop XIX
	popw	de                                    ; FB50FE  pop DE
	popw	hl                                    ; FB50FF  pop HL
	unlk32 xiz                                 ; FB5100  unlk XIZ
	ret                                        ; FB5102  ret
; --------------------------------------------------------------------------
; sub_FB5103 -- 0xFB5103..0xFB519B (153 bytes)
;
; Called from: 7 site(s) outside this module:
;          0xFAE31A in Voice_RestageArm_ValueCurve_Shared, 0xFB8A1D in Voice_RecomputeEnv_AndWriteSlot2
;          0xFB8B1B in Voice_RecomputeEnv_AndWriteSlot1, 0xFB8C1B in Voice_RecomputeEnv_AndWriteSlot1or3
;          0xFBC46F in sub_FBC39D__FBC463, 0xFBC4E4 in sub_FBC39D__FBC4D8
;          0xFBC579 in sub_FBC39D__FBC56D
; Inputs:  frame `link XIZ,-2`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFB5103-0xFB519B
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FB5103:
	link32 0xEE, 0x0C, 0xFE, 0xFF              ; FB5103  link XIZ,0xfffe
	push	xhl                                   ; FB5107  push XHL
	pushw	de                                   ; FB5108  push DE
	pushw	ix                                   ; FB5109  push IX
	ldb	c, 16                                  ; FB510A  ld C,0x10
	extpfx3 0x8E, 0x0A, 0x43                   ; FB510C  mul BC,(XIZ+0x0a)
	ld	de, bc                                  ; FB510F  ld DE,BC
	ld	wa, (xiz+8)                             ; FB5111  ld WA,(XIZ+0x08)
	extz	wa                                    ; FB5114  extz WA
	mul	wa, 0x12C                              ; FB5116  mul WA,0x012c
	ld	ix, wa                                  ; FB511A  ld IX,WA
	add	ix, bc                                 ; FB511C  add IX,BC
	ldb	c, 4                                   ; FB511E  ld C,0x04
	extpfx3 0x8E, 0x0C, 0x43                   ; FB5120  mul BC,(XIZ+0x0c)
	add	bc, ix                                 ; FB5123  add BC,IX
	ld	de, bc                                  ; FB5125  ld DE,BC
	add	de, 53                                 ; FB5127  add DE,0x0035
	ldw	hl, 0x1523                             ; FB512B  ld HL,0x1523
	ld	bc, de                                  ; FB512E  ld BC,DE
	add	hl, bc                                 ; FB5130  add HL,BC
	extz	xhl                                   ; FB5132  extz XHL
	extpfx3 0x83, 0x3C, 0xF3                   ; FB5134  and (XHL),0xf3
	ld	c, (xhl+2)                              ; FB5137  ld C,(XHL+0x02)
	cps	c, 0                                   ; FB513A  cp C,0
	jr z, sub_FB5103__FB514F                   ; FB513C  jr Z,0xfb514f
	extz	xhl                                   ; FB513E  extz XHL
	ld	c, (xhl+1)                              ; FB5140  ld C,(XHL+0x01)
	and	c, 85                                  ; FB5143  and C,0x55
	jr z, sub_FB5103__FB514F                   ; FB5146  jr Z,0xfb514f
	extz	xhl                                   ; FB5148  extz XHL
	extpfx3 0x83, 0x3E, 0x08                   ; FB514A  or (XHL),0x08
	jr sub_FB5103__FB5196                      ; FB514D  jr T,0xfb5196
sub_FB5103__FB514F:
	ld	bc, (xiz+8)                             ; FB514F  ld BC,(XIZ+0x08)
	extz	bc                                    ; FB5152  extz BC
	mul	bc, 0x12C                              ; FB5154  mul BC,0x012c
	ld	(xiz-2), bc                             ; FB5158  ld (XIZ+0xfe),BC
	ldw	ix, 0                                  ; FB515B  ld IX,0x0000
	ldb	d, 4                                   ; FB515E  ld D,0x04
sub_FB5103__FB5160:
	ld	bc, (xiz-2)                             ; FB5160  ld BC,(XIZ+0xfe)
	add	bc, ix                                 ; FB5163  add BC,IX
	add	bc, 0x88                               ; FB5165  add BC,0x0088
	extz	xbc                                   ; FB5169  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB516B  ld XWA,(XBC+0x1523)
	ld	e, (xwa+6)                              ; FB5170  ld E,(XWA+0x06)
	ld	c, e                                    ; FB5173  ld C,E
	and	c, 32                                  ; FB5175  and C,0x20
	jr z, sub_FB5103__FB518C                   ; FB5178  jr Z,0xfb518c
	ld	c, e                                    ; FB517A  ld C,E
	and	c, 0xC0                                ; FB517C  and C,0xc0
	srl	c, 6                                   ; FB517F  srl 0x06,C
	extpfx3 0x8E, 0x0C, 0xF3                   ; FB5182  cp C,(XIZ+0x0c)
	jr nz, sub_FB5103__FB518C                  ; FB5185  jr NZ,0xfb518c
	extz	xhl                                   ; FB5187  extz XHL
	extpfx3 0x83, 0x3E, 0x04                   ; FB5189  or (XHL),0x04
sub_FB5103__FB518C:
	add	ix, 41                                 ; FB518C  add IX,0x0029
	dec	1, d                                   ; FB5190  dec 1,D
	cps	d, 0                                   ; FB5192  cp D,0
	jr nz, sub_FB5103__FB5160                  ; FB5194  jr NZ,0xfb5160
sub_FB5103__FB5196:
	popw	ix                                    ; FB5196  pop IX
	popw	de                                    ; FB5197  pop DE
	pop	xhl                                    ; FB5198  pop XHL
	unlk32 xiz                                 ; FB5199  unlk XIZ
	ret                                        ; FB519B  ret
; --------------------------------------------------------------------------
; sub_FB519C -- 0xFB519C..0xFB52A4 (265 bytes)
;
; Called from: no site outside this module.
;          ⚠ NOT FOUND -- no literal call/calr/jp reaches this address anywhere
;          in the image.  A register-indirect call would be invisible to that
;          scan, so this is "not found", not "dead".
; Inputs:  frame `link XIZ,-6`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C), (XIZ+0x0E), (XIZ+0x10)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFB519C-0xFB52A4
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FB519C:
	link32 0xEE, 0x0C, 0xFA, 0xFF              ; FB519C  link XIZ,0xfffa
	pushw	hl                                   ; FB51A0  push HL
	pushw	de                                   ; FB51A1  push DE
	pushw	ix                                   ; FB51A2  push IX
	ld	ix, (xiz+8)                             ; FB51A3  ld IX,(XIZ+0x08)
	ld	d, (xiz+16)                             ; FB51A6  ld D,(XIZ+0x10)
	ld	l, (xiz+14)                             ; FB51A9  ld L,(XIZ+0x0e)
	ld	bc, (xiz+12)                            ; FB51AC  ld BC,(XIZ+0x0c)
	extz	bc                                    ; FB51AF  extz BC
	extz	xbc                                   ; FB51B1  extz XBC
	ld	(xiz-4), xbc                            ; FB51B3  ld (XIZ+0xfc),XBC
	add	xbc, 0xFDE6A1                          ; FB51B6  add XBC,0x00fde6a1
	ld	e, (xbc)                                ; FB51BC  ld E,(XBC)
	ld	bc, (xiz+10)                            ; FB51BE  ld BC,(XIZ+0x0a)
	extz	xbc                                   ; FB51C1  extz XBC
	ld	h, (xbc+1)                              ; FB51C3  ld H,(XBC+0x01)
	ld	a, e                                    ; FB51C6  ld A,E
	and	a, h                                   ; FB51C8  and A,H
	jrl z, sub_FB519C__FB529F                  ; FB51CA  jrl Z,0xfb529f
	lda	xwa, (0xFDE6A5:24)                     ; FB51CD  lda XWA,0xfde6a5
	extpfx3 0xAE, 0xFC, 0x80                   ; FB51D2  add XWA,(XIZ+0xfc)
	ld	c, (xwa)                                ; FB51D5  ld C,(XWA)
	and	c, h                                   ; FB51D7  and C,H
	jr z, sub_FB519C__FB5240                   ; FB51D9  jr Z,0xfb5240
	ld	c, l                                    ; FB51DB  ld C,L
	extz	bc                                    ; FB51DD  extz BC
	cps	bc, 0                                  ; FB51DF  cp BC,0
	jr z, sub_FB519C__FB51EE                   ; FB51E1  jr Z,0xfb51ee
	cps	bc, 1                                  ; FB51E3  cp BC,1
	jr z, sub_FB519C__FB5209                   ; FB51E5  jr Z,0xfb5209
	cps	bc, 2                                  ; FB51E7  cp BC,2
	jr z, sub_FB519C__FB5225                   ; FB51E9  jr Z,0xfb5225
	jrl sub_FB519C__FB529F                     ; FB51EB  jrl T,0xfb529f
sub_FB519C__FB51EE:
	ld	c, d                                    ; FB51EE  ld C,D
	or	c, 0xC0                                 ; FB51F0  or C,0xc0
	extz	bc                                    ; FB51F3  extz BC
	ld	(xiz-6), bc                             ; FB51F5  ld (XIZ+0xfa),BC
	ldb	a, 2                                   ; FB51F8  ld A,0x02
	mul8rr	a, l                                ; FB51FA  mul WA,L
	add	wa, 30                                 ; FB51FC  add WA,0x001e
	extz	xwa                                   ; FB5200  extz XWA
	add	wa, ix                                 ; FB5202  add WA,IX
	ld	(xwa), bc                               ; FB5204  ld (XWA),BC
	jrl sub_FB519C__FB529F                     ; FB5206  jrl T,0xfb529f
sub_FB519C__FB5209:
	ld	c, d                                    ; FB5209  ld C,D
	extz	bc                                    ; FB520B  extz BC
	or	bc, 0xC000                              ; FB520D  or BC,0xc000
	ld	(xiz-6), bc                             ; FB5211  ld (XIZ+0xfa),BC
	ldb	a, 2                                   ; FB5214  ld A,0x02
	mul8rr	a, l                                ; FB5216  mul WA,L
	add	wa, 30                                 ; FB5218  add WA,0x001e
	extz	xwa                                   ; FB521C  extz XWA
	add	wa, ix                                 ; FB521E  add WA,IX
	ld	(xwa), bc                               ; FB5220  ld (XWA),BC
	jrl sub_FB519C__FB529F                     ; FB5222  jrl T,0xfb529f
sub_FB519C__FB5225:
	ld	c, d                                    ; FB5225  ld C,D
	extz	bc                                    ; FB5227  extz BC
	or	bc, 0x3300                              ; FB5229  or BC,0x3300
	ld	(xiz-6), bc                             ; FB522D  ld (XIZ+0xfa),BC
	ldb	a, 2                                   ; FB5230  ld A,0x02
	mul8rr	a, l                                ; FB5232  mul WA,L
	add	wa, 30                                 ; FB5234  add WA,0x001e
	extz	xwa                                   ; FB5238  extz XWA
	add	wa, ix                                 ; FB523A  add WA,IX
	ld	(xwa), bc                               ; FB523C  ld (XWA),BC
	jr sub_FB519C__FB529F                      ; FB523E  jr T,0xfb529f
sub_FB519C__FB5240:
	ld	c, l                                    ; FB5240  ld C,L
	extz	bc                                    ; FB5242  extz BC
	cps	bc, 0                                  ; FB5244  cp BC,0
	jr z, sub_FB519C__FB5252                   ; FB5246  jr Z,0xfb5252
	cps	bc, 1                                  ; FB5248  cp BC,1
	jr z, sub_FB519C__FB526C                   ; FB524A  jr Z,0xfb526c
	cps	bc, 2                                  ; FB524C  cp BC,2
	jr z, sub_FB519C__FB5286                   ; FB524E  jr Z,0xfb5286
	jr sub_FB519C__FB529F                      ; FB5250  jr T,0xfb529f
sub_FB519C__FB5252:
	ld	c, d                                    ; FB5252  ld C,D
	set	6, c                                   ; FB5254  set 0x06,C
	extz	bc                                    ; FB5257  extz BC
	ld	(xiz-6), bc                             ; FB5259  ld (XIZ+0xfa),BC
	ldb	a, 2                                   ; FB525C  ld A,0x02
	mul8rr	a, l                                ; FB525E  mul WA,L
	add	wa, 30                                 ; FB5260  add WA,0x001e
	extz	xwa                                   ; FB5264  extz XWA
	add	wa, ix                                 ; FB5266  add WA,IX
	ld	(xwa), bc                               ; FB5268  ld (XWA),BC
	jr sub_FB519C__FB529F                      ; FB526A  jr T,0xfb529f
sub_FB519C__FB526C:
	ld	c, d                                    ; FB526C  ld C,D
	extz	bc                                    ; FB526E  extz BC
	set	14, bc                                 ; FB5270  set 0x0e,BC
	ld	(xiz-6), bc                             ; FB5273  ld (XIZ+0xfa),BC
	ldb	a, 2                                   ; FB5276  ld A,0x02
	mul8rr	a, l                                ; FB5278  mul WA,L
	add	wa, 30                                 ; FB527A  add WA,0x001e
	extz	xwa                                   ; FB527E  extz XWA
	add	wa, ix                                 ; FB5280  add WA,IX
	ld	(xwa), bc                               ; FB5282  ld (XWA),BC
	jr sub_FB519C__FB529F                      ; FB5284  jr T,0xfb529f
sub_FB519C__FB5286:
	ld	c, d                                    ; FB5286  ld C,D
	extz	bc                                    ; FB5288  extz BC
	or	bc, 0x1100                              ; FB528A  or BC,0x1100
	ld	(xiz-6), bc                             ; FB528E  ld (XIZ+0xfa),BC
	ldb	a, 2                                   ; FB5291  ld A,0x02
	mul8rr	a, l                                ; FB5293  mul WA,L
	add	wa, 30                                 ; FB5295  add WA,0x001e
	extz	xwa                                   ; FB5299  extz XWA
	add	wa, ix                                 ; FB529B  add WA,IX
	ld	(xwa), bc                               ; FB529D  ld (XWA),BC
sub_FB519C__FB529F:
	popw	ix                                    ; FB529F  pop IX
	popw	de                                    ; FB52A0  pop DE
	popw	hl                                    ; FB52A1  pop HL
	unlk32 xiz                                 ; FB52A2  unlk XIZ
	ret                                        ; FB52A4  ret
; --------------------------------------------------------------------------
; sub_FB52A5 -- 0xFB52A5..0xFB5303 (95 bytes)
;
; Called from: no site outside this module.
;          ⚠ NOT FOUND -- no literal call/calr/jp reaches this address anywhere
;          in the image.  A register-indirect call would be invisible to that
;          scan, so this is "not found", not "dead".
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C), (XIZ+0x0E)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFB52A5-0xFB5303
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FB52A5:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB52A5  link XIZ,0x0000
	pushw	hl                                   ; FB52A9  push HL
	pushw	de                                   ; FB52AA  push DE
	ld	l, (xiz+14)                             ; FB52AB  ld L,(XIZ+0x0e)
	ld	h, (xiz+12)                             ; FB52AE  ld H,(XIZ+0x0c)
	ld	c, l                                    ; FB52B1  ld C,L
	and	c, 32                                  ; FB52B3  and C,0x20
	jr z, sub_FB52A5__FB52FF                   ; FB52B6  jr Z,0xfb52ff
	ld	c, l                                    ; FB52B8  ld C,L
	and	c, 0xC0                                ; FB52BA  and C,0xc0
	srl	c, 6                                   ; FB52BD  srl 0x06,C
	cp	c, h                                    ; FB52C0  cp C,H
	jr nz, sub_FB52A5__FB52FF                  ; FB52C2  jr NZ,0xfb52ff
	ld	c, l                                    ; FB52C4  ld C,L
	and	c, 16                                  ; FB52C6  and C,0x10
	jr z, sub_FB52A5__FB52E6                   ; FB52C9  jr Z,0xfb52e6
	ld	c, h                                    ; FB52CB  ld C,H
	or	c, 0xC0                                 ; FB52CD  or C,0xc0
	extz	bc                                    ; FB52D0  extz BC
	ld	de, bc                                  ; FB52D2  ld DE,BC
	ldb	a, 2                                   ; FB52D4  ld A,0x02
	extpfx3 0x8E, 0x0A, 0x41                   ; FB52D6  mul WA,(XIZ+0x0a)
	add	wa, 30                                 ; FB52D9  add WA,0x001e
	extz	xwa                                   ; FB52DD  extz XWA
	extpfx3 0x9E, 0x08, 0x80                   ; FB52DF  add WA,(XIZ+0x08)
	ld	(xwa), bc                               ; FB52E2  ld (XWA),BC
	jr sub_FB52A5__FB52FF                      ; FB52E4  jr T,0xfb52ff
sub_FB52A5__FB52E6:
	ld	c, h                                    ; FB52E6  ld C,H
	set	6, c                                   ; FB52E8  set 0x06,C
	extz	bc                                    ; FB52EB  extz BC
	ld	de, bc                                  ; FB52ED  ld DE,BC
	ldb	a, 2                                   ; FB52EF  ld A,0x02
	extpfx3 0x8E, 0x0A, 0x41                   ; FB52F1  mul WA,(XIZ+0x0a)
	add	wa, 30                                 ; FB52F4  add WA,0x001e
	extz	xwa                                   ; FB52F8  extz XWA
	extpfx3 0x9E, 0x08, 0x80                   ; FB52FA  add WA,(XIZ+0x08)
	ld	(xwa), bc                               ; FB52FD  ld (XWA),BC
sub_FB52A5__FB52FF:
	popw	de                                    ; FB52FF  pop DE
	popw	hl                                    ; FB5300  pop HL
	unlk32 xiz                                 ; FB5301  unlk XIZ
	ret                                        ; FB5303  ret
; --------------------------------------------------------------------------
; sub_FB5304 -- 0xFB5304..0xFB5363 (96 bytes)
;
; Called from: no site outside this module.
;          ⚠ NOT FOUND -- no literal call/calr/jp reaches this address anywhere
;          in the image.  A register-indirect call would be invisible to that
;          scan, so this is "not found", not "dead".
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C), (XIZ+0x0E)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFB5304-0xFB5363
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FB5304:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB5304  link XIZ,0x0000
	pushw	hl                                   ; FB5308  push HL
	pushw	de                                   ; FB5309  push DE
	ld	l, (xiz+14)                             ; FB530A  ld L,(XIZ+0x0e)
	ld	h, (xiz+12)                             ; FB530D  ld H,(XIZ+0x0c)
	ld	c, l                                    ; FB5310  ld C,L
	and	c, 32                                  ; FB5312  and C,0x20
	jr z, sub_FB5304__FB535F                   ; FB5315  jr Z,0xfb535f
	ld	c, l                                    ; FB5317  ld C,L
	and	c, 0xC0                                ; FB5319  and C,0xc0
	srl	c, 6                                   ; FB531C  srl 0x06,C
	cp	c, h                                    ; FB531F  cp C,H
	jr nz, sub_FB5304__FB535F                  ; FB5321  jr NZ,0xfb535f
	ld	c, l                                    ; FB5323  ld C,L
	and	c, 16                                  ; FB5325  and C,0x10
	jr z, sub_FB5304__FB5346                   ; FB5328  jr Z,0xfb5346
	ld	c, h                                    ; FB532A  ld C,H
	extz	bc                                    ; FB532C  extz BC
	ld	de, bc                                  ; FB532E  ld DE,BC
	or	de, 0xC000                              ; FB5330  or DE,0xc000
	ldb	c, 2                                   ; FB5334  ld C,0x02
	extpfx3 0x8E, 0x0A, 0x43                   ; FB5336  mul BC,(XIZ+0x0a)
	add	bc, 30                                 ; FB5339  add BC,0x001e
	extz	xbc                                   ; FB533D  extz XBC
	extpfx3 0x9E, 0x08, 0x81                   ; FB533F  add BC,(XIZ+0x08)
	ld	(xbc), de                               ; FB5342  ld (XBC),DE
	jr sub_FB5304__FB535F                      ; FB5344  jr T,0xfb535f
sub_FB5304__FB5346:
	ld	c, h                                    ; FB5346  ld C,H
	extz	bc                                    ; FB5348  extz BC
	ld	de, bc                                  ; FB534A  ld DE,BC
	set	14, de                                 ; FB534C  set 0x0e,DE
	ldb	c, 2                                   ; FB534F  ld C,0x02
	extpfx3 0x8E, 0x0A, 0x43                   ; FB5351  mul BC,(XIZ+0x0a)
	add	bc, 30                                 ; FB5354  add BC,0x001e
	extz	xbc                                   ; FB5358  extz XBC
	extpfx3 0x9E, 0x08, 0x81                   ; FB535A  add BC,(XIZ+0x08)
	ld	(xbc), de                               ; FB535D  ld (XBC),DE
sub_FB5304__FB535F:
	popw	de                                    ; FB535F  pop DE
	popw	hl                                    ; FB5360  pop HL
	unlk32 xiz                                 ; FB5361  unlk XIZ
	ret                                        ; FB5363  ret
; --------------------------------------------------------------------------
; sub_FB5364 -- 0xFB5364..0xFB53C4 (97 bytes)
;
; Called from: no site outside this module.
;          ⚠ NOT FOUND -- no literal call/calr/jp reaches this address anywhere
;          in the image.  A register-indirect call would be invisible to that
;          scan, so this is "not found", not "dead".
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C), (XIZ+0x0E)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFB5364-0xFB53C4
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FB5364:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB5364  link XIZ,0x0000
	pushw	hl                                   ; FB5368  push HL
	pushw	de                                   ; FB5369  push DE
	ld	l, (xiz+14)                             ; FB536A  ld L,(XIZ+0x0e)
	ld	h, (xiz+12)                             ; FB536D  ld H,(XIZ+0x0c)
	ld	c, l                                    ; FB5370  ld C,L
	and	c, 32                                  ; FB5372  and C,0x20
	jr z, sub_FB5364__FB53C0                   ; FB5375  jr Z,0xfb53c0
	ld	c, l                                    ; FB5377  ld C,L
	and	c, 0xC0                                ; FB5379  and C,0xc0
	srl	c, 6                                   ; FB537C  srl 0x06,C
	cp	c, h                                    ; FB537F  cp C,H
	jr nz, sub_FB5364__FB53C0                  ; FB5381  jr NZ,0xfb53c0
	ld	c, l                                    ; FB5383  ld C,L
	and	c, 16                                  ; FB5385  and C,0x10
	jr z, sub_FB5364__FB53A6                   ; FB5388  jr Z,0xfb53a6
	ld	c, h                                    ; FB538A  ld C,H
	extz	bc                                    ; FB538C  extz BC
	ld	de, bc                                  ; FB538E  ld DE,BC
	or	de, 0x3300                              ; FB5390  or DE,0x3300
	ldb	c, 2                                   ; FB5394  ld C,0x02
	extpfx3 0x8E, 0x0A, 0x43                   ; FB5396  mul BC,(XIZ+0x0a)
	add	bc, 30                                 ; FB5399  add BC,0x001e
	extz	xbc                                   ; FB539D  extz XBC
	extpfx3 0x9E, 0x08, 0x81                   ; FB539F  add BC,(XIZ+0x08)
	ld	(xbc), de                               ; FB53A2  ld (XBC),DE
	jr sub_FB5364__FB53C0                      ; FB53A4  jr T,0xfb53c0
sub_FB5364__FB53A6:
	ld	c, h                                    ; FB53A6  ld C,H
	extz	bc                                    ; FB53A8  extz BC
	ld	de, bc                                  ; FB53AA  ld DE,BC
	or	de, 0x1100                              ; FB53AC  or DE,0x1100
	ldb	c, 2                                   ; FB53B0  ld C,0x02
	extpfx3 0x8E, 0x0A, 0x43                   ; FB53B2  mul BC,(XIZ+0x0a)
	add	bc, 30                                 ; FB53B5  add BC,0x001e
	extz	xbc                                   ; FB53B9  extz XBC
	extpfx3 0x9E, 0x08, 0x81                   ; FB53BB  add BC,(XIZ+0x08)
	ld	(xbc), de                               ; FB53BE  ld (XBC),DE
sub_FB5364__FB53C0:
	popw	de                                    ; FB53C0  pop DE
	popw	hl                                    ; FB53C1  pop HL
	unlk32 xiz                                 ; FB53C2  unlk XIZ
	ret                                        ; FB53C4  ret
; --------------------------------------------------------------------------
; sub_FB53C5 -- 0xFB53C5..0xFB5635 (625 bytes)
;
; Called from: 8 site(s) outside this module:
;          0xFAE2AF in Voice_RestageArm_BaseCurve_Shared__FAE2A2, 0xFAE333 in Voice_RestageArm_ValueCurve_Shared__FAE326
;          0xFB8A41 in Voice_RecomputeEnv_AndWriteSlot2__FB8A34, 0xFB8B3F in Voice_RecomputeEnv_AndWriteSlot1__FB8B32
;          0xFB8C3F in Voice_RecomputeEnv_AndWriteSlot1or3__FB8C32, 0xFBC496 in sub_FBC39D__FBC489
;          0xFBC50B in sub_FBC39D__FBC4FE, 0xFBC5A0 in sub_FBC39D__FBC593
;          2 site(s) inside this module:
;          0xFB6833 0xFB6AAE
; Inputs:  frame `link XIZ,-19`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFB53C5-0xFB5635
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FB53C5:
	link32 0xEE, 0x0C, 0xED, 0xFF              ; FB53C5  link XIZ,0xffed
	pushw	hl                                   ; FB53C9  push HL
	pushw	de                                   ; FB53CA  push DE
	push	xix                                   ; FB53CB  push XIX
	ldb	c, 41                                  ; FB53CC  ld C,0x29
	extpfx3 0x8E, 0x0A, 0x43                   ; FB53CE  mul BC,(XIZ+0x0a)
	ld	(xiz-19), bc                            ; FB53D1  ld (XIZ+0xed),BC
	ld	wa, (xiz+8)                             ; FB53D4  ld WA,(XIZ+0x08)
	extz	wa                                    ; FB53D7  extz WA
	mul	wa, 0x12C                              ; FB53D9  mul WA,0x012c
	ld	de, wa                                  ; FB53DD  ld DE,WA
	ld	ix, wa                                  ; FB53DF  ld IX,WA
	add	ix, bc                                 ; FB53E1  add IX,BC
	add	ix, 0x88                               ; FB53E3  add IX,0x0088
	ldw	bc, 0x1523                             ; FB53E7  ld BC,0x1523
	add	bc, ix                                 ; FB53EA  add BC,IX
	ld	(xiz-16), bc                            ; FB53EC  ld (XIZ+0xf0),BC
	ldb	c, 2                                   ; FB53EF  ld C,0x02
	extpfx3 0x8E, 0x0C, 0x43                   ; FB53F1  mul BC,(XIZ+0x0c)
	ld	hl, bc                                  ; FB53F4  ld HL,BC
	add	bc, 30                                 ; FB53F6  add BC,0x001e
	ld	hl, bc                                  ; FB53FA  ld HL,BC
	extz	xbc                                   ; FB53FC  extz XBC
	extpfx3 0x9E, 0xF0, 0x81                   ; FB53FE  add BC,(XIZ+0xf0)
	extpfx4 0xB1, 0x02, 0x00, 0x00             ; FB5401  ld (XBC),0x0000
	ld	(xiz-17), 0                             ; FB5405  ld (XIZ+0xef),0x00
	ldb	c, 16                                  ; FB5409  ld C,0x10
	extpfx3 0x8E, 0x0C, 0x43                   ; FB540B  mul BC,(XIZ+0x0c)
	ld	(xiz-19), bc                            ; FB540E  ld (XIZ+0xed),BC
	ld	(xiz-8), hl                             ; FB5411  ld (XIZ+0xf8),HL
	add	bc, de                                 ; FB5414  add BC,DE
	ld	(xiz-12), bc                            ; FB5416  ld (XIZ+0xf4),BC
	ld	(xiz-14), ix                            ; FB5419  ld (XIZ+0xf2),IX
	ldw (xiz-10), 0x0000                       ; FB541C  ld (XIZ+0xf6),0x0000
sub_FB53C5__FB5421:
	ld	bc, (xiz-12)                            ; FB5421  ld BC,(XIZ+0xf4)
	extpfx3 0x9E, 0xF6, 0x81                   ; FB5424  add BC,(XIZ+0xf6)
	ld	de, bc                                  ; FB5427  ld DE,BC
	add	de, 53                                 ; FB5429  add DE,0x0035
	ldw	ix, 0x1523                             ; FB542D  ld IX,0x1523
	ld	bc, de                                  ; FB5430  ld BC,DE
	add	ix, bc                                 ; FB5432  add IX,BC
	extz	xix                                   ; FB5434  extz XIX
	ld	h, (xix)                                ; FB5436  ld H,(XIX)
	ld	c, h                                    ; FB5438  ld C,H
	and	c, 10                                  ; FB543A  and C,0x0a
	jrl z, sub_FB53C5__FB5511                  ; FB543D  jrl Z,0xfb5511
	ld	h, (xiz-17)                             ; FB5440  ld H,(XIZ+0xef)
	ld	(xiz-2), ix                             ; FB5443  ld (XIZ+0xfe),IX
	ld	de, (xiz-16)                            ; FB5446  ld DE,(XIZ+0xf0)
	ld	bc, (xiz+10)                            ; FB5449  ld BC,(XIZ+0x0a)
	extz	bc                                    ; FB544C  extz BC
	extz	xbc                                   ; FB544E  extz XBC
	ld	(xiz-6), xbc                            ; FB5450  ld (XIZ+0xfa),XBC
	add	xbc, 0xFDE6A1                          ; FB5453  add XBC,0x00fde6a1
	ld	l, (xbc)                                ; FB5459  ld L,(XBC)
	ld	a, (xix+1)                              ; FB545B  ld A,(XIX+0x01)
	and	a, l                                   ; FB545E  and A,L
	jrl z, sub_FB53C5__FB550E                  ; FB5460  jrl Z,0xfb550e
	lda	xbc, (0xFDE6A5:24)                     ; FB5463  lda XBC,0xfde6a5
	extpfx3 0xAE, 0xFA, 0x81                   ; FB5468  add XBC,(XIZ+0xfa)
	ld	l, (xbc)                                ; FB546B  ld L,(XBC)
	ld	bc, (xiz-2)                             ; FB546D  ld BC,(XIZ+0xfe)
	extz	xbc                                   ; FB5470  extz XBC
	ld	a, (xbc+1)                              ; FB5472  ld A,(XBC+0x01)
	and	a, l                                   ; FB5475  and A,L
	jr z, sub_FB53C5__FB54C6                   ; FB5477  jr Z,0xfb54c6
	ld	wa, (xiz+12)                            ; FB5479  ld WA,(XIZ+0x0c)
	extz	wa                                    ; FB547C  extz WA
	cps	wa, 0                                  ; FB547E  cp WA,0
	jr z, sub_FB53C5__FB548D                   ; FB5480  jr Z,0xfb548d
	cps	wa, 1                                  ; FB5482  cp WA,1
	jr z, sub_FB53C5__FB54A0                   ; FB5484  jr Z,0xfb54a0
	cps	wa, 2                                  ; FB5486  cp WA,2
	jr z, sub_FB53C5__FB54B3                   ; FB5488  jr Z,0xfb54b3
	jrl sub_FB53C5__FB550E                     ; FB548A  jrl T,0xfb550e
sub_FB53C5__FB548D:
	ld	c, h                                    ; FB548D  ld C,H
	or	c, 0xC0                                 ; FB548F  or C,0xc0
	extz	bc                                    ; FB5492  extz BC
	ld	wa, de                                  ; FB5494  ld WA,DE
	extz	xwa                                   ; FB5496  extz XWA
	extpfx3 0x9E, 0xF8, 0x80                   ; FB5498  add WA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB549B  ld (XWA),BC
	jrl sub_FB53C5__FB550E                     ; FB549D  jrl T,0xfb550e
sub_FB53C5__FB54A0:
	ld	c, h                                    ; FB54A0  ld C,H
	extz	bc                                    ; FB54A2  extz BC
	or	bc, 0xC000                              ; FB54A4  or BC,0xc000
	ld	wa, de                                  ; FB54A8  ld WA,DE
	extz	xwa                                   ; FB54AA  extz XWA
	extpfx3 0x9E, 0xF8, 0x80                   ; FB54AC  add WA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB54AF  ld (XWA),BC
	jr sub_FB53C5__FB550E                      ; FB54B1  jr T,0xfb550e
sub_FB53C5__FB54B3:
	ld	c, h                                    ; FB54B3  ld C,H
	extz	bc                                    ; FB54B5  extz BC
	or	bc, 0x3300                              ; FB54B7  or BC,0x3300
	ld	wa, de                                  ; FB54BB  ld WA,DE
	extz	xwa                                   ; FB54BD  extz XWA
	extpfx3 0x9E, 0xF8, 0x80                   ; FB54BF  add WA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB54C2  ld (XWA),BC
	jr sub_FB53C5__FB550E                      ; FB54C4  jr T,0xfb550e
sub_FB53C5__FB54C6:
	ld	bc, (xiz+12)                            ; FB54C6  ld BC,(XIZ+0x0c)
	extz	bc                                    ; FB54C9  extz BC
	cps	bc, 0                                  ; FB54CB  cp BC,0
	jr z, sub_FB53C5__FB54D9                   ; FB54CD  jr Z,0xfb54d9
	cps	bc, 1                                  ; FB54CF  cp BC,1
	jr z, sub_FB53C5__FB54EB                   ; FB54D1  jr Z,0xfb54eb
	cps	bc, 2                                  ; FB54D3  cp BC,2
	jr z, sub_FB53C5__FB54FD                   ; FB54D5  jr Z,0xfb54fd
	jr sub_FB53C5__FB550E                      ; FB54D7  jr T,0xfb550e
sub_FB53C5__FB54D9:
	ld	c, h                                    ; FB54D9  ld C,H
	set	6, c                                   ; FB54DB  set 0x06,C
	extz	bc                                    ; FB54DE  extz BC
	ld	wa, de                                  ; FB54E0  ld WA,DE
	extz	xwa                                   ; FB54E2  extz XWA
	extpfx3 0x9E, 0xF8, 0x80                   ; FB54E4  add WA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB54E7  ld (XWA),BC
	jr sub_FB53C5__FB550E                      ; FB54E9  jr T,0xfb550e
sub_FB53C5__FB54EB:
	ld	c, h                                    ; FB54EB  ld C,H
	extz	bc                                    ; FB54ED  extz BC
	set	14, bc                                 ; FB54EF  set 0x0e,BC
	ld	wa, de                                  ; FB54F2  ld WA,DE
	extz	xwa                                   ; FB54F4  extz XWA
	extpfx3 0x9E, 0xF8, 0x80                   ; FB54F6  add WA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB54F9  ld (XWA),BC
	jr sub_FB53C5__FB550E                      ; FB54FB  jr T,0xfb550e
sub_FB53C5__FB54FD:
	ld	c, h                                    ; FB54FD  ld C,H
	extz	bc                                    ; FB54FF  extz BC
	or	bc, 0x1100                              ; FB5501  or BC,0x1100
	ld	wa, de                                  ; FB5505  ld WA,DE
	extz	xwa                                   ; FB5507  extz XWA
	extpfx3 0x9E, 0xF8, 0x80                   ; FB5509  add WA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB550C  ld (XWA),BC
sub_FB53C5__FB550E:
	jrl sub_FB53C5__FB5623                     ; FB550E  jrl T,0xfb5623
sub_FB53C5__FB5511:
	ld	c, h                                    ; FB5511  ld C,H
	and	c, 5                                   ; FB5513  and C,0x05
	jrl z, sub_FB53C5__FB5623                  ; FB5516  jrl Z,0xfb5623
	ld	bc, (xiz+12)                            ; FB5519  ld BC,(XIZ+0x0c)
	extz	bc                                    ; FB551C  extz BC
	cps	bc, 0                                  ; FB551E  cp BC,0
	jr z, sub_FB53C5__FB552E                   ; FB5520  jr Z,0xfb552e
	cps	bc, 1                                  ; FB5522  cp BC,1
	jr z, sub_FB53C5__FB5580                   ; FB5524  jr Z,0xfb5580
	cps	bc, 2                                  ; FB5526  cp BC,2
	jrl z, sub_FB53C5__FB55D2                  ; FB5528  jrl Z,0xfb55d2
	jrl sub_FB53C5__FB5623                     ; FB552B  jrl T,0xfb5623
sub_FB53C5__FB552E:
	ld	bc, (xiz-14)                            ; FB552E  ld BC,(XIZ+0xf2)
	extz	xbc                                   ; FB5531  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB5533  ld XWA,(XBC+0x1523)
	ld	h, (xwa+6)                              ; FB5538  ld H,(XWA+0x06)
	ld	l, (xiz-17)                             ; FB553B  ld L,(XIZ+0xef)
	ld	de, (xiz-16)                            ; FB553E  ld DE,(XIZ+0xf0)
	ld	a, h                                    ; FB5541  ld A,H
	and	a, 32                                  ; FB5543  and A,0x20
	jr z, sub_FB53C5__FB557D                   ; FB5546  jr Z,0xfb557d
	ld	a, h                                    ; FB5548  ld A,H
	and	a, 0xC0                                ; FB554A  and A,0xc0
	srl	a, 6                                   ; FB554D  srl 0x06,A
	cp	a, l                                    ; FB5550  cp A,L
	jr nz, sub_FB53C5__FB557D                  ; FB5552  jr NZ,0xfb557d
	ld	a, h                                    ; FB5554  ld A,H
	and	a, 16                                  ; FB5556  and A,0x10
	jr z, sub_FB53C5__FB556D                   ; FB5559  jr Z,0xfb556d
	ld	a, l                                    ; FB555B  ld A,L
	or	a, 0xC0                                 ; FB555D  or A,0xc0
	extz	wa                                    ; FB5560  extz WA
	ld	bc, de                                  ; FB5562  ld BC,DE
	extz	xbc                                   ; FB5564  extz XBC
	extpfx3 0x9E, 0xF8, 0x81                   ; FB5566  add BC,(XIZ+0xf8)
	ld	(xbc), wa                               ; FB5569  ld (XBC),WA
	jr sub_FB53C5__FB557D                      ; FB556B  jr T,0xfb557d
sub_FB53C5__FB556D:
	ld	c, l                                    ; FB556D  ld C,L
	set	6, c                                   ; FB556F  set 0x06,C
	extz	bc                                    ; FB5572  extz BC
	ld	wa, de                                  ; FB5574  ld WA,DE
	extz	xwa                                   ; FB5576  extz XWA
	extpfx3 0x9E, 0xF8, 0x80                   ; FB5578  add WA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB557B  ld (XWA),BC
sub_FB53C5__FB557D:
	jrl sub_FB53C5__FB5623                     ; FB557D  jrl T,0xfb5623
sub_FB53C5__FB5580:
	ld	bc, (xiz-14)                            ; FB5580  ld BC,(XIZ+0xf2)
	extz	xbc                                   ; FB5583  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB5585  ld XWA,(XBC+0x1523)
	ld	l, (xwa+38)                             ; FB558A  ld L,(XWA+0x26)
	ld	h, (xiz-17)                             ; FB558D  ld H,(XIZ+0xef)
	ld	de, (xiz-16)                            ; FB5590  ld DE,(XIZ+0xf0)
	ld	a, l                                    ; FB5593  ld A,L
	and	a, 32                                  ; FB5595  and A,0x20
	jr z, sub_FB53C5__FB55D0                   ; FB5598  jr Z,0xfb55d0
	ld	a, l                                    ; FB559A  ld A,L
	and	a, 0xC0                                ; FB559C  and A,0xc0
	srl	a, 6                                   ; FB559F  srl 0x06,A
	cp	a, h                                    ; FB55A2  cp A,H
	jr nz, sub_FB53C5__FB55D0                  ; FB55A4  jr NZ,0xfb55d0
	ld	a, l                                    ; FB55A6  ld A,L
	and	a, 16                                  ; FB55A8  and A,0x10
	jr z, sub_FB53C5__FB55C0                   ; FB55AB  jr Z,0xfb55c0
	ld	a, h                                    ; FB55AD  ld A,H
	extz	wa                                    ; FB55AF  extz WA
	or	wa, 0xC000                              ; FB55B1  or WA,0xc000
	ld	bc, de                                  ; FB55B5  ld BC,DE
	extz	xbc                                   ; FB55B7  extz XBC
	extpfx3 0x9E, 0xF8, 0x81                   ; FB55B9  add BC,(XIZ+0xf8)
	ld	(xbc), wa                               ; FB55BC  ld (XBC),WA
	jr sub_FB53C5__FB55D0                      ; FB55BE  jr T,0xfb55d0
sub_FB53C5__FB55C0:
	ld	c, h                                    ; FB55C0  ld C,H
	extz	bc                                    ; FB55C2  extz BC
	set	14, bc                                 ; FB55C4  set 0x0e,BC
	ld	wa, de                                  ; FB55C7  ld WA,DE
	extz	xwa                                   ; FB55C9  extz XWA
	extpfx3 0x9E, 0xF8, 0x80                   ; FB55CB  add WA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB55CE  ld (XWA),BC
sub_FB53C5__FB55D0:
	jr sub_FB53C5__FB5623                      ; FB55D0  jr T,0xfb5623
sub_FB53C5__FB55D2:
	ld	bc, (xiz-14)                            ; FB55D2  ld BC,(XIZ+0xf2)
	extz	xbc                                   ; FB55D5  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB55D7  ld XWA,(XBC+0x1523)
	ld	l, (xwa+56)                             ; FB55DC  ld L,(XWA+0x38)
	ld	h, (xiz-17)                             ; FB55DF  ld H,(XIZ+0xef)
	ld	de, (xiz-16)                            ; FB55E2  ld DE,(XIZ+0xf0)
	ld	a, l                                    ; FB55E5  ld A,L
	and	a, 32                                  ; FB55E7  and A,0x20
	jr z, sub_FB53C5__FB5623                   ; FB55EA  jr Z,0xfb5623
	ld	a, l                                    ; FB55EC  ld A,L
	and	a, 0xC0                                ; FB55EE  and A,0xc0
	srl	a, 6                                   ; FB55F1  srl 0x06,A
	cp	a, h                                    ; FB55F4  cp A,H
	jr nz, sub_FB53C5__FB5623                  ; FB55F6  jr NZ,0xfb5623
	ld	a, l                                    ; FB55F8  ld A,L
	and	a, 16                                  ; FB55FA  and A,0x10
	jr z, sub_FB53C5__FB5612                   ; FB55FD  jr Z,0xfb5612
	ld	a, h                                    ; FB55FF  ld A,H
	extz	wa                                    ; FB5601  extz WA
	or	wa, 0x3300                              ; FB5603  or WA,0x3300
	ld	bc, de                                  ; FB5607  ld BC,DE
	extz	xbc                                   ; FB5609  extz XBC
	extpfx3 0x9E, 0xF8, 0x81                   ; FB560B  add BC,(XIZ+0xf8)
	ld	(xbc), wa                               ; FB560E  ld (XBC),WA
	jr sub_FB53C5__FB5623                      ; FB5610  jr T,0xfb5623
sub_FB53C5__FB5612:
	ld	c, h                                    ; FB5612  ld C,H
	extz	bc                                    ; FB5614  extz BC
	or	bc, 0x1100                              ; FB5616  or BC,0x1100
	ld	wa, de                                  ; FB561A  ld WA,DE
	extz	xwa                                   ; FB561C  extz XWA
	extpfx3 0x9E, 0xF8, 0x80                   ; FB561E  add WA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB5621  ld (XWA),BC
sub_FB53C5__FB5623:
	incw	4, (xiz-10)                           ; FB5623  incw 4,(XIZ+0xf6)
	incm8	1, (xiz-17)                          ; FB5626  inc 1,(XIZ+0xef)
	cp (xiz-17), 0x04                          ; FB5629  cp (XIZ+0xef),0x04
	jrl c, sub_FB53C5__FB5421                  ; FB562D  jrl C,0xfb5421
	pop	xix                                    ; FB5630  pop XIX
	popw	de                                    ; FB5631  pop DE
	popw	hl                                    ; FB5632  pop HL
	unlk32 xiz                                 ; FB5633  unlk XIZ
	ret                                        ; FB5635  ret
; --------------------------------------------------------------------------
; sub_FB5636 -- 0xFB5636..0xFB5829 (500 bytes)
;
; Called from: 2 site(s) outside this module:
;          0xFAFC35 in sub_FAFBEC__FAFC28, 0xFBBC9C in sub_FBB793__FBBC8B
;          2 site(s) inside this module:
;          0xFB6690 0xFB68EC
; Inputs:  frame `link XIZ,-1`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Calls:   0xFB582A = sub_FB582A, 0xFB59D2 = sub_FB59D2
;          0xFB5BAA = sub_FB5BAA, 0xFB5C77 = sub_FB5C77
; Evidence: the listing below is the byte-identical round-trip of 0xFB5636-0xFB5829
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FB5636:
	link32 0xEE, 0x0C, 0xFF, 0xFF              ; FB5636  link XIZ,0xffff
	push	xhl                                   ; FB563A  push XHL
	pushw	de                                   ; FB563B  push DE
	push	xix                                   ; FB563C  push XIX
	ld	bc, (xiz+8)                             ; FB563D  ld BC,(XIZ+0x08)
	extz	bc                                    ; FB5640  extz BC
	mul	bc, 0x12C                              ; FB5642  mul BC,0x012c
	ld	de, bc                                  ; FB5646  ld DE,BC
	extz	xbc                                   ; FB5648  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB564A  ld XWA,(XBC+0x1523)
	ld	c, (xwa+0xD0)                           ; FB564F  ld C,(XWA+0x00d0)
	and	c, 15                                  ; FB5654  and C,0x0f
	ld	(xiz-1), c                              ; FB5657  ld (XIZ+0xff),C
	cps	c, 7                                   ; FB565A  cp C,7
	jrl nz, sub_FB5636__FB5755                 ; FB565C  jrl NZ,0xfb5755
	ld	hl, de                                  ; FB565F  ld HL,DE
	add	hl, 9                                  ; FB5661  add HL,0x0009
	extz	xhl                                   ; FB5665  extz XHL
	extpfx7 0xD3, 0xED, 0x23, 0x15, 0x3E, 0x00, 0x80 ; FB5667  or (XHL+0x1523),0x8000
	cp (xiz+10), 0x00                          ; FB566E  cp (XIZ+0x0a),0x00
	jrl nz, sub_FB5636__FB5717                 ; FB5672  jrl NZ,0xfb5717
	extz	xhl                                   ; FB5675  extz XHL
	ld	bc, (xhl+0x1523)                        ; FB5677  ld BC,(XHL+0x1523)
	ld	ix, bc                                  ; FB567C  ld IX,BC
	and	ix, 0x4000                             ; FB567E  and IX,0x4000
	ld	hl, de                                  ; FB5682  ld HL,DE
	add	hl, 0x71                               ; FB5684  add HL,0x0071
	cps	ix, 0                                  ; FB5688  cp IX,0
	jr z, sub_FB5636__FB56B2                   ; FB568A  jr Z,0xfb56b2
	extz	xhl                                   ; FB568C  extz XHL
	ld	(xhl+0x1523), 15                        ; FB568E  ld (XHL+0x1523),0x0f
	ld	bc, de                                  ; FB5694  ld BC,DE
	add	bc, 0x72                               ; FB5696  add BC,0x0072
	extz	xbc                                   ; FB569A  extz XBC
	ld	(xbc+0x1523), 79                        ; FB569C  ld (XBC+0x1523),0x4f
	ld	bc, de                                  ; FB56A2  ld BC,DE
	add	bc, 0x73                               ; FB56A4  add BC,0x0073
	extz	xbc                                   ; FB56A8  extz XBC
	ld	(xbc+0x1523), 0x96                      ; FB56AA  ld (XBC+0x1523),0x96
	jr sub_FB5636__FB56D6                      ; FB56B0  jr T,0xfb56d6
sub_FB5636__FB56B2:
	extz	xhl                                   ; FB56B2  extz XHL
	ld	(xhl+0x1523), 1                         ; FB56B4  ld (XHL+0x1523),0x01
	ld	bc, de                                  ; FB56BA  ld BC,DE
	add	bc, 0x72                               ; FB56BC  add BC,0x0072
	extz	xbc                                   ; FB56C0  extz XBC
	ld	(xbc+0x1523), 1                         ; FB56C2  ld (XBC+0x1523),0x01
	ld	bc, de                                  ; FB56C8  ld BC,DE
	add	bc, 0x73                               ; FB56CA  add BC,0x0073
	extz	xbc                                   ; FB56CE  extz XBC
	ld	(xbc+0x1523), 1                         ; FB56D0  ld (XBC+0x1523),0x01
sub_FB5636__FB56D6:
	pushw	0                                    ; FB56D6  push 0x0000
	ld	h, (xiz+8)                              ; FB56D9  ld H,(XIZ+0x08)
	push	0                                     ; FB56DC  push 0x00
	push	h                                     ; FB56DE  push H
	calr (0xFB582A - 0xFB56E3)                 ; FB56E0  calr 0xfb582a
	pushw	0                                    ; FB56E3  push 0x0000
	push	0                                     ; FB56E6  push 0x00
	push	h                                     ; FB56E8  push H
	calr (0xFB59D2 - 0xFB56ED)                 ; FB56EA  calr 0xfb59d2
	pushw	1                                    ; FB56ED  push 0x0001
	push	0                                     ; FB56F0  push 0x00
	push	h                                     ; FB56F2  push H
	calr (0xFB582A - 0xFB56F7)                 ; FB56F4  calr 0xfb582a
	pushw	1                                    ; FB56F7  push 0x0001
	push	0                                     ; FB56FA  push 0x00
	push	h                                     ; FB56FC  push H
	calr (0xFB59D2 - 0xFB5701)                 ; FB56FE  calr 0xfb59d2
	push	0                                     ; FB5701  push 0x00
	push	h                                     ; FB5703  push H
	calr (0xFB5BAA - 0xFB5708)                 ; FB5705  calr 0xfb5baa
	push	0                                     ; FB5708  push 0x00
	push	h                                     ; FB570A  push H
	calr (0xFB5C77 - 0xFB570F)                 ; FB570C  calr 0xfb5c77
	add	xsp, 20                                ; FB570F  add XSP,0x00000014
	jr sub_FB5636__FB573E                      ; FB5715  jr T,0xfb573e
sub_FB5636__FB5717:
	extz	xhl                                   ; FB5717  extz XHL
	ld	bc, (xhl+0x1523)                        ; FB5719  ld BC,(XHL+0x1523)
	ld	ix, bc                                  ; FB571E  ld IX,BC
	and	ix, 0x4000                             ; FB5720  and IX,0x4000
	ld	hl, de                                  ; FB5724  ld HL,DE
	add	hl, 0x71                               ; FB5726  add HL,0x0071
	extz	xhl                                   ; FB572A  extz XHL
	extpfx6 0xC3, 0xED, 0x23, 0x15, 0x3C, 0x05 ; FB572C  and (XHL+0x1523),0x05
	cps	ix, 0                                  ; FB5732  cp IX,0
	jr z, sub_FB5636__FB573E                   ; FB5734  jr Z,0xfb573e
	extz	xhl                                   ; FB5736  extz XHL
	extpfx6 0xC3, 0xED, 0x23, 0x15, 0x3E, 0x02 ; FB5738  or (XHL+0x1523),0x02
sub_FB5636__FB573E:
	ld	bc, (xiz+8)                             ; FB573E  ld BC,(XIZ+0x08)
	extz	bc                                    ; FB5741  extz BC
	mul	bc, 0x12C                              ; FB5743  mul BC,0x012c
	inc	6, bc                                  ; FB5747  inc 6,BC
	extz	xbc                                   ; FB5749  extz XBC
	extpfx7 0xD3, 0xE5, 0x23, 0x15, 0x3C, 0xFF, 0xFD ; FB574B  and (XBC+0x1523),0xfdff
	jrl sub_FB5636__FB5824                     ; FB5752  jrl T,0xfb5824
sub_FB5636__FB5755:
	ld	ix, de                                  ; FB5755  ld IX,DE
	add	ix, 9                                  ; FB5757  add IX,0x0009
	extz	xix                                   ; FB575B  extz XIX
	ld	hl, (xix+0x1523)                        ; FB575D  ld HL,(XIX+0x1523)
	ld	bc, hl                                  ; FB5762  ld BC,HL
	and	bc, 0x4000                             ; FB5764  and BC,0x4000
	jr z, sub_FB5636__FB57D1                   ; FB5768  jr Z,0xfb57d1
	ld	d, (xiz+8)                              ; FB576A  ld D,(XIZ+0x08)
	ld	bc, hl                                  ; FB576D  ld BC,HL
	set	15, bc                                 ; FB576F  set 0x0f,BC
	extz	xix                                   ; FB5772  extz XIX
	ld	(xix+0x1523), bc                        ; FB5774  ld (XIX+0x1523),BC
	pushw	0                                    ; FB5779  push 0x0000
	push	0                                     ; FB577C  push 0x00
	push	d                                     ; FB577E  push D
	calr (0xFB582A - 0xFB5783)                 ; FB5780  calr 0xfb582a
	pushw	0                                    ; FB5783  push 0x0000
	push	0                                     ; FB5786  push 0x00
	push	d                                     ; FB5788  push D
	calr (0xFB59D2 - 0xFB578D)                 ; FB578A  calr 0xfb59d2
	pushw	1                                    ; FB578D  push 0x0001
	push	0                                     ; FB5790  push 0x00
	push	d                                     ; FB5792  push D
	calr (0xFB582A - 0xFB5797)                 ; FB5794  calr 0xfb582a
	pushw	1                                    ; FB5797  push 0x0001
	push	0                                     ; FB579A  push 0x00
	push	d                                     ; FB579C  push D
	calr (0xFB59D2 - 0xFB57A1)                 ; FB579E  calr 0xfb59d2
	push	0                                     ; FB57A1  push 0x00
	push	d                                     ; FB57A3  push D
	calr (0xFB5BAA - 0xFB57A8)                 ; FB57A5  calr 0xfb5baa
	push	0                                     ; FB57A8  push 0x00
	push	d                                     ; FB57AA  push D
	calr (0xFB5C77 - 0xFB57AF)                 ; FB57AC  calr 0xfb5c77
	add	xsp, 20                                ; FB57AF  add XSP,0x00000014
	cp (xiz-1), 0x0A                           ; FB57B5  cp (XIZ+0xff),0x0a
	jr nz, sub_FB5636__FB57DD                  ; FB57B9  jr NZ,0xfb57dd
	ld	bc, (xiz+8)                             ; FB57BB  ld BC,(XIZ+0x08)
	extz	bc                                    ; FB57BE  extz BC
	mul	bc, 0x12C                              ; FB57C0  mul BC,0x012c
	inc	6, bc                                  ; FB57C4  inc 6,BC
	extz	xbc                                   ; FB57C6  extz XBC
	extpfx7 0xD3, 0xE5, 0x23, 0x15, 0x3E, 0x00, 0x02 ; FB57C8  or (XBC+0x1523),0x0200
	jr sub_FB5636__FB57F1                      ; FB57CF  jr T,0xfb57f1
sub_FB5636__FB57D1:
	ld	bc, hl                                  ; FB57D1  ld BC,HL
	res	15, bc                                 ; FB57D3  res 0x0f,BC
	extz	xix                                   ; FB57D6  extz XIX
	ld	(xix+0x1523), bc                        ; FB57D8  ld (XIX+0x1523),BC
sub_FB5636__FB57DD:
	ld	bc, (xiz+8)                             ; FB57DD  ld BC,(XIZ+0x08)
	extz	bc                                    ; FB57E0  extz BC
	mul	bc, 0x12C                              ; FB57E2  mul BC,0x012c
	inc	6, bc                                  ; FB57E6  inc 6,BC
	extz	xbc                                   ; FB57E8  extz XBC
	extpfx7 0xD3, 0xE5, 0x23, 0x15, 0x3C, 0xFF, 0xFD ; FB57EA  and (XBC+0x1523),0xfdff
sub_FB5636__FB57F1:
	ld	bc, (xiz+8)                             ; FB57F1  ld BC,(XIZ+0x08)
	extz	bc                                    ; FB57F4  extz BC
	mul	bc, 0x12C                              ; FB57F6  mul BC,0x012c
	ld	hl, bc                                  ; FB57FA  ld HL,BC
	add	bc, 0x71                               ; FB57FC  add BC,0x0071
	extz	xbc                                   ; FB5800  extz XBC
	ld	(xbc+0x1523), 0                         ; FB5802  ld (XBC+0x1523),0x00
	ld	bc, hl                                  ; FB5808  ld BC,HL
	add	bc, 0x72                               ; FB580A  add BC,0x0072
	extz	xbc                                   ; FB580E  extz XBC
	ld	(xbc+0x1523), 0                         ; FB5810  ld (XBC+0x1523),0x00
	ld	bc, hl                                  ; FB5816  ld BC,HL
	add	bc, 0x73                               ; FB5818  add BC,0x0073
	extz	xbc                                   ; FB581C  extz XBC
	ld	(xbc+0x1523), 0                         ; FB581E  ld (XBC+0x1523),0x00
sub_FB5636__FB5824:
	pop	xix                                    ; FB5824  pop XIX
	popw	de                                    ; FB5825  pop DE
	pop	xhl                                    ; FB5826  pop XHL
	unlk32 xiz                                 ; FB5827  unlk XIZ
	ret                                        ; FB5829  ret
; --------------------------------------------------------------------------
; sub_FB582A -- 0xFB582A..0xFB59D1 (424 bytes)
;
; Called from: 5 site(s) outside this module:
;          0xFAC4A3 in sub_FAC42C__FAC49B, 0xFAC546 in sub_FAC526
;          0xFAC606 in sub_FAC58F__FAC5FE, 0xFAC6A9 in sub_FAC689
;          0xFACC86 in sub_FACC75
;          4 site(s) inside this module:
;          0xFB56E0 0xFB56F4 0xFB5780 0xFB5794
; Inputs:  frame `link XIZ,-4`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Arms:    4 computed-goto arm(s) inside this routine: 0xFB589B 0xFB58B5 0xFB5935 0xFB59AF
; Evidence: the listing below is the byte-identical round-trip of 0xFB582A-0xFB59D1
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FB582A:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FB582A  link XIZ,0xfffc
	pushw	hl                                   ; FB582E  push HL
	pushw	de                                   ; FB582F  push DE
	push	xix                                   ; FB5830  push XIX
	ld	e, (xiz+8)                              ; FB5831  ld E,(XIZ+0x08)
	ld	d, (xiz+10)                             ; FB5834  ld D,(XIZ+0x0a)
	ldw	ix, 0                                  ; FB5837  ld IX,0x0000
	ld	c, e                                    ; FB583A  ld C,E
	extz	bc                                    ; FB583C  extz BC
	mul	bc, 0x12C                              ; FB583E  mul BC,0x012c
	extz	xbc                                   ; FB5842  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB5844  ld XWA,(XBC+0x1523)
	ld	l, (xwa+0xD0)                           ; FB5849  ld L,(XWA+0x00d0)
	and	l, 15                                  ; FB584E  and L,0x0f
	ld	c, l                                    ; FB5851  ld C,L
	extz	bc                                    ; FB5853  extz BC
	extz	xbc                                   ; FB5855  extz XBC
	cp	bc, 11                                  ; FB5857  cp BC,0x000b
	jrl ugt, sub_FB582A__FB59AF                ; FB585B  jrl UGT,0xfb59af
	sll	bc, 2                                  ; FB585E  sll 0x02,BC
	add	xbc, 0xFB586B                          ; FB5861  add XBC,0x00fb586b
	ld	xbc, (xbc)                              ; FB5867  ld XBC,(XBC)
	jp	(xbc)                                   ; FB5869  jp T,XBC
; 12 x u32 computed-goto table, 0xFB586B-0xFB589A, 48 bytes.
; THE ENTRY COUNT IS ESTABLISHED TWICE AND THE TWO AGREE: the `cp rr,11`
; guard before the `jr UGT` gives 12, and reading consecutive words while
; each is a plausible code address also gives 12.  The word after the last
; entry is not a plausible entry, so the table ends here rather than being
; assumed to.  (python3 notes/prom_c_jumptables.py 0xFB405F 0xFB6E0A;
; asserted per table by notes/prom_c_voiceparam_checks.py section 2.)
; Entry 0 is the SAME address the out-of-range guard branches to.
	.long 0x00FB589B	; 0xFB586B  entry 0 -> 0xFB589B   (also the out-of-range arm)
	.long 0x00FB589B	; 0xFB586F  entry 1 -> 0xFB589B
	.long 0x00FB589B	; 0xFB5873  entry 2 -> 0xFB589B
	.long 0x00FB589B	; 0xFB5877  entry 3 -> 0xFB589B
	.long 0x00FB58B5	; 0xFB587B  entry 4 -> 0xFB58B5
	.long 0x00FB58B5	; 0xFB587F  entry 5 -> 0xFB58B5
	.long 0x00FB59AF	; 0xFB5883  entry 6 -> 0xFB59AF
	.long 0x00FB58B5	; 0xFB5887  entry 7 -> 0xFB58B5
	.long 0x00FB59AF	; 0xFB588B  entry 8 -> 0xFB59AF
	.long 0x00FB59AF	; 0xFB588F  entry 9 -> 0xFB59AF
	.long 0x00FB5935	; 0xFB5893  entry 10 -> 0xFB5935
	.long 0x00FB5935	; 0xFB5897  entry 11 -> 0xFB5935
sub_FB582A__FB589B:
	ldb	c, 2                                   ; FB589B  ld C,0x02
	mul8rr	c, d                                ; FB589D  mul BC,D
	extz	xbc                                   ; FB589F  extz XBC
	ld	xix, xbc                                ; FB58A1  ld XIX,XBC
	ldb	a, 6                                   ; FB58A3  ld A,0x06
	mul8rr	a, l                                ; FB58A5  mul WA,L
	extz	xwa                                   ; FB58A7  extz XWA
	add	xwa, xbc                               ; FB58A9  add XWA,XBC
	add	xwa, 0xFDE6A9                          ; FB58AB  add XWA,0x00fde6a9
	ld	h, (xwa)                                ; FB58B1  ld H,(XWA)
	jr sub_FB582A__FB58D2                      ; FB58B3  jr T,0xfb58d2
sub_FB582A__FB58B5:
	ldb	c, 2                                   ; FB58B5  ld C,0x02
	mul8rr	c, d                                ; FB58B7  mul BC,D
	extz	xbc                                   ; FB58B9  extz XBC
	ld	(xiz-4), xbc                            ; FB58BB  ld (XIZ+0xfc),XBC
	ldb	a, 6                                   ; FB58BE  ld A,0x06
	mul8rr	a, l                                ; FB58C0  mul WA,L
	extz	xwa                                   ; FB58C2  extz XWA
	add	xwa, xbc                               ; FB58C4  add XWA,XBC
	add	xwa, 0xFDE6A9                          ; FB58C6  add XWA,0x00fde6a9
	ld	h, (xwa)                                ; FB58CC  ld H,(XWA)
	cps	d, 0                                   ; FB58CE  cp D,0
	jr nz, sub_FB582A__FB5901                  ; FB58D0  jr NZ,0xfb5901
sub_FB582A__FB58D2:
	ld	c, e                                    ; FB58D2  ld C,E
	extz	bc                                    ; FB58D4  extz BC
	mul	bc, 0x12C                              ; FB58D6  mul BC,0x012c
	extz	xbc                                   ; FB58DA  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB58DC  ld XWA,(XBC+0x1523)
	ld	c, (xwa+0xD1)                           ; FB58E1  ld C,(XWA+0x00d1)
	mul	c, 2                                   ; FB58E6  mul C,0x02
	extz	xbc                                   ; FB58E9  extz XBC
	ld	(xiz-4), xbc                            ; FB58EB  ld (XIZ+0xfc),XBC
	ldb	a, 0x66                                ; FB58EE  ld A,0x66
	mul8rr	a, h                                ; FB58F0  mul WA,H
	extz	xwa                                   ; FB58F2  extz XWA
	add	xwa, xbc                               ; FB58F4  add XWA,XBC
	add	xwa, 0xFDEA21                          ; FB58F6  add XWA,0x00fdea21
	ld	ix, (xwa)                               ; FB58FC  ld IX,(XWA)
	jrl sub_FB582A__FB59AF                     ; FB58FE  jrl T,0xfb59af
sub_FB582A__FB5901:
	cps	d, 1                                   ; FB5901  cp D,1
	jrl nz, sub_FB582A__FB59AF                 ; FB5903  jrl NZ,0xfb59af
	ld	c, e                                    ; FB5906  ld C,E
	extz	bc                                    ; FB5908  extz BC
	mul	bc, 0x12C                              ; FB590A  mul BC,0x012c
	extz	xbc                                   ; FB590E  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB5910  ld XWA,(XBC+0x1523)
	ld	c, (xwa+0xD3)                           ; FB5915  ld C,(XWA+0x00d3)
	mul	c, 2                                   ; FB591A  mul C,0x02
	extz	xbc                                   ; FB591D  extz XBC
	ld	(xiz-4), xbc                            ; FB591F  ld (XIZ+0xfc),XBC
	ldb	a, 0x66                                ; FB5922  ld A,0x66
	mul8rr	a, h                                ; FB5924  mul WA,H
	extz	xwa                                   ; FB5926  extz XWA
	add	xwa, xbc                               ; FB5928  add XWA,XBC
	add	xwa, 0xFDEA21                          ; FB592A  add XWA,0x00fdea21
	ld	ix, (xwa)                               ; FB5930  ld IX,(XWA)
	jrl sub_FB582A__FB59AF                     ; FB5932  jrl T,0xfb59af
sub_FB582A__FB5935:
	ldb	c, 2                                   ; FB5935  ld C,0x02
	mul8rr	c, d                                ; FB5937  mul BC,D
	extz	xbc                                   ; FB5939  extz XBC
	ld	(xiz-4), xbc                            ; FB593B  ld (XIZ+0xfc),XBC
	ldb	a, 6                                   ; FB593E  ld A,0x06
	mul8rr	a, l                                ; FB5940  mul WA,L
	extz	xwa                                   ; FB5942  extz XWA
	add	xwa, xbc                               ; FB5944  add XWA,XBC
	add	xwa, 0xFDE6A9                          ; FB5946  add XWA,0x00fde6a9
	ld	h, (xwa)                                ; FB594C  ld H,(XWA)
	cp	h, 0xFF                                 ; FB594E  cp H,0xff
	jr z, sub_FB582A__FB597F                   ; FB5951  jr Z,0xfb597f
	ld	c, e                                    ; FB5953  ld C,E
	extz	bc                                    ; FB5955  extz BC
	mul	bc, 0x12C                              ; FB5957  mul BC,0x012c
	extz	xbc                                   ; FB595B  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB595D  ld XWA,(XBC+0x1523)
	ld	c, (xwa+0xD3)                           ; FB5962  ld C,(XWA+0x00d3)
	mul	c, 2                                   ; FB5967  mul C,0x02
	extz	xbc                                   ; FB596A  extz XBC
	ld	(xiz-4), xbc                            ; FB596C  ld (XIZ+0xfc),XBC
	ldb	a, 0x66                                ; FB596F  ld A,0x66
	mul8rr	a, h                                ; FB5971  mul WA,H
	extz	xwa                                   ; FB5973  extz XWA
	add	xwa, xbc                               ; FB5975  add XWA,XBC
	add	xwa, 0xFDEA21                          ; FB5977  add XWA,0x00fdea21
	ld	ix, (xwa)                               ; FB597D  ld IX,(XWA)
sub_FB582A__FB597F:
	ldb	c, 3                                   ; FB597F  ld C,0x03
	mul8rr	c, d                                ; FB5981  mul BC,D
	extz	xbc                                   ; FB5983  extz XBC
	ld	(xiz-4), xbc                            ; FB5985  ld (XIZ+0xfc),XBC
	ldb	a, 39                                  ; FB5988  ld A,0x27
	mul8rr	a, l                                ; FB598A  mul WA,L
	extz	xwa                                   ; FB598C  extz XWA
	add	xwa, xbc                               ; FB598E  add XWA,XBC
	inc	2, xwa                                 ; FB5990  inc 2,XWA
	add	xwa, 0xFDF4F1                          ; FB5992  add XWA,0x00fdf4f1
	ld	c, (xwa)                                ; FB5998  ld C,(XWA)
	and	c, 0xC0                                ; FB599A  and C,0xc0
	srl	c, 6                                   ; FB599D  srl 0x06,C
	mul	c, 2                                   ; FB59A0  mul C,0x02
	extz	xbc                                   ; FB59A3  extz XBC
	add	xbc, 0xFDEBEC                          ; FB59A5  add XBC,0x00fdebec
	ld	bc, (xbc)                               ; FB59AB  ld BC,(XBC)
	or	ix, bc                                  ; FB59AD  or IX,BC
sub_FB582A__FB59AF:
	ldb	c, 4                                   ; FB59AF  ld C,0x04
	mul8rr	c, d                                ; FB59B1  mul BC,D
	ld	hl, bc                                  ; FB59B3  ld HL,BC
	ld	a, e                                    ; FB59B5  ld A,E
	extz	wa                                    ; FB59B7  extz WA
	mul	wa, 0x12C                              ; FB59B9  mul WA,0x012c
	add	wa, bc                                 ; FB59BD  add WA,BC
	add	wa, 0x65                               ; FB59BF  add WA,0x0065
	extz	xwa                                   ; FB59C3  extz XWA
	ld	(xwa+0x1523), ix                        ; FB59C5  ld (XWA+0x1523),IX
	ld	wa, ix                                  ; FB59CA  ld WA,IX
	pop	xix                                    ; FB59CC  pop XIX
	popw	de                                    ; FB59CD  pop DE
	popw	hl                                    ; FB59CE  pop HL
	unlk32 xiz                                 ; FB59CF  unlk XIZ
	ret                                        ; FB59D1  ret
; --------------------------------------------------------------------------
; sub_FB59D2 -- 0xFB59D2..0xFB5B55 (388 bytes)
;
; Called from: 5 site(s) outside this module:
;          0xFAC43B in sub_FAC42C, 0xFAC535 in sub_FAC526
;          0xFAC59E in sub_FAC58F, 0xFAC698 in sub_FAC689
;          0xFACD2C in sub_FACD1B
;          4 site(s) inside this module:
;          0xFB56EA 0xFB56FE 0xFB578A 0xFB579E
; Inputs:  frame `link XIZ,-8`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Arms:    4 computed-goto arm(s) inside this routine: 0xFB5A43 0xFB5A5F 0xFB5AE0 0xFB5B33
; Evidence: the listing below is the byte-identical round-trip of 0xFB59D2-0xFB5B55
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FB59D2:
	link32 0xEE, 0x0C, 0xF8, 0xFF              ; FB59D2  link XIZ,0xfff8
	pushw	hl                                   ; FB59D6  push HL
	pushw	de                                   ; FB59D7  push DE
	push	xix                                   ; FB59D8  push XIX
	ld	e, (xiz+8)                              ; FB59D9  ld E,(XIZ+0x08)
	ld	d, (xiz+10)                             ; FB59DC  ld D,(XIZ+0x0a)
	ldw	ix, 0                                  ; FB59DF  ld IX,0x0000
	ld	c, e                                    ; FB59E2  ld C,E
	extz	bc                                    ; FB59E4  extz BC
	mul	bc, 0x12C                              ; FB59E6  mul BC,0x012c
	extz	xbc                                   ; FB59EA  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB59EC  ld XWA,(XBC+0x1523)
	ld	l, (xwa+0xD0)                           ; FB59F1  ld L,(XWA+0x00d0)
	and	l, 15                                  ; FB59F6  and L,0x0f
	ld	c, l                                    ; FB59F9  ld C,L
	extz	bc                                    ; FB59FB  extz BC
	extz	xbc                                   ; FB59FD  extz XBC
	cp	bc, 11                                  ; FB59FF  cp BC,0x000b
	jrl ugt, sub_FB59D2__FB5B33                ; FB5A03  jrl UGT,0xfb5b33
	sll	bc, 2                                  ; FB5A06  sll 0x02,BC
	add	xbc, 0xFB5A13                          ; FB5A09  add XBC,0x00fb5a13
	ld	xbc, (xbc)                              ; FB5A0F  ld XBC,(XBC)
	jp	(xbc)                                   ; FB5A11  jp T,XBC
; 12 x u32 computed-goto table, 0xFB5A13-0xFB5A42, 48 bytes.
; THE ENTRY COUNT IS ESTABLISHED TWICE AND THE TWO AGREE: the `cp rr,11`
; guard before the `jr UGT` gives 12, and reading consecutive words while
; each is a plausible code address also gives 12.  The word after the last
; entry is not a plausible entry, so the table ends here rather than being
; assumed to.  (python3 notes/prom_c_jumptables.py 0xFB405F 0xFB6E0A;
; asserted per table by notes/prom_c_voiceparam_checks.py section 2.)
; Entry 0 is the SAME address the out-of-range guard branches to.
	.long 0x00FB5A43	; 0xFB5A13  entry 0 -> 0xFB5A43   (also the out-of-range arm)
	.long 0x00FB5A43	; 0xFB5A17  entry 1 -> 0xFB5A43
	.long 0x00FB5A43	; 0xFB5A1B  entry 2 -> 0xFB5A43
	.long 0x00FB5A43	; 0xFB5A1F  entry 3 -> 0xFB5A43
	.long 0x00FB5A5F	; 0xFB5A23  entry 4 -> 0xFB5A5F
	.long 0x00FB5A5F	; 0xFB5A27  entry 5 -> 0xFB5A5F
	.long 0x00FB5B33	; 0xFB5A2B  entry 6 -> 0xFB5B33
	.long 0x00FB5A5F	; 0xFB5A2F  entry 7 -> 0xFB5A5F
	.long 0x00FB5B33	; 0xFB5A33  entry 8 -> 0xFB5B33
	.long 0x00FB5B33	; 0xFB5A37  entry 9 -> 0xFB5B33
	.long 0x00FB5AE0	; 0xFB5A3B  entry 10 -> 0xFB5AE0
	.long 0x00FB5AE0	; 0xFB5A3F  entry 11 -> 0xFB5AE0
sub_FB59D2__FB5A43:
	ldb	c, 2                                   ; FB5A43  ld C,0x02
	mul8rr	c, d                                ; FB5A45  mul BC,D
	extz	xbc                                   ; FB5A47  extz XBC
	ld	xix, xbc                                ; FB5A49  ld XIX,XBC
	ldb	a, 6                                   ; FB5A4B  ld A,0x06
	mul8rr	a, l                                ; FB5A4D  mul WA,L
	extz	xwa                                   ; FB5A4F  extz XWA
	add	xwa, xbc                               ; FB5A51  add XWA,XBC
	inc	1, xwa                                 ; FB5A53  inc 1,XWA
	add	xwa, 0xFDE6A9                          ; FB5A55  add XWA,0x00fde6a9
	ld	h, (xwa)                                ; FB5A5B  ld H,(XWA)
	jr sub_FB59D2__FB5A7E                      ; FB5A5D  jr T,0xfb5a7e
sub_FB59D2__FB5A5F:
	ldb	c, 2                                   ; FB5A5F  ld C,0x02
	mul8rr	c, d                                ; FB5A61  mul BC,D
	extz	xbc                                   ; FB5A63  extz XBC
	ld	(xiz-4), xbc                            ; FB5A65  ld (XIZ+0xfc),XBC
	ldb	a, 6                                   ; FB5A68  ld A,0x06
	mul8rr	a, l                                ; FB5A6A  mul WA,L
	extz	xwa                                   ; FB5A6C  extz XWA
	add	xwa, xbc                               ; FB5A6E  add XWA,XBC
	inc	1, xwa                                 ; FB5A70  inc 1,XWA
	add	xwa, 0xFDE6A9                          ; FB5A72  add XWA,0x00fde6a9
	ld	h, (xwa)                                ; FB5A78  ld H,(XWA)
	cps	d, 0                                   ; FB5A7A  cp D,0
	jr nz, sub_FB59D2__FB5AAD                  ; FB5A7C  jr NZ,0xfb5aad
sub_FB59D2__FB5A7E:
	ld	c, e                                    ; FB5A7E  ld C,E
	extz	bc                                    ; FB5A80  extz BC
	mul	bc, 0x12C                              ; FB5A82  mul BC,0x012c
	extz	xbc                                   ; FB5A86  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB5A88  ld XWA,(XBC+0x1523)
	ld	c, (xwa+0xD2)                           ; FB5A8D  ld C,(XWA+0x00d2)
	mul	c, 2                                   ; FB5A92  mul C,0x02
	extz	xbc                                   ; FB5A95  extz XBC
	ld	(xiz-4), xbc                            ; FB5A97  ld (XIZ+0xfc),XBC
	ldb	a, 0x66                                ; FB5A9A  ld A,0x66
	mul8rr	a, h                                ; FB5A9C  mul WA,H
	extz	xwa                                   ; FB5A9E  extz XWA
	add	xwa, xbc                               ; FB5AA0  add XWA,XBC
	add	xwa, 0xFDE6F1                          ; FB5AA2  add XWA,0x00fde6f1
	ld	ix, (xwa)                               ; FB5AA8  ld IX,(XWA)
	jrl sub_FB59D2__FB5B33                     ; FB5AAA  jrl T,0xfb5b33
sub_FB59D2__FB5AAD:
	cps	d, 1                                   ; FB5AAD  cp D,1
	jrl nz, sub_FB59D2__FB5B33                 ; FB5AAF  jrl NZ,0xfb5b33
	ld	c, e                                    ; FB5AB2  ld C,E
	extz	bc                                    ; FB5AB4  extz BC
	mul	bc, 0x12C                              ; FB5AB6  mul BC,0x012c
	extz	xbc                                   ; FB5ABA  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB5ABC  ld XWA,(XBC+0x1523)
	ld	c, (xwa+0xD4)                           ; FB5AC1  ld C,(XWA+0x00d4)
	mul	c, 2                                   ; FB5AC6  mul C,0x02
	extz	xbc                                   ; FB5AC9  extz XBC
	ld	(xiz-4), xbc                            ; FB5ACB  ld (XIZ+0xfc),XBC
	ldb	a, 0x66                                ; FB5ACE  ld A,0x66
	mul8rr	a, h                                ; FB5AD0  mul WA,H
	extz	xwa                                   ; FB5AD2  extz XWA
	add	xwa, xbc                               ; FB5AD4  add XWA,XBC
	add	xwa, 0xFDE6F1                          ; FB5AD6  add XWA,0x00fde6f1
	ld	ix, (xwa)                               ; FB5ADC  ld IX,(XWA)
	jr sub_FB59D2__FB5B33                      ; FB5ADE  jr T,0xfb5b33
sub_FB59D2__FB5AE0:
	ldb	c, 2                                   ; FB5AE0  ld C,0x02
	mul8rr	c, d                                ; FB5AE2  mul BC,D
	extz	xbc                                   ; FB5AE4  extz XBC
	ld	(xiz-4), xbc                            ; FB5AE6  ld (XIZ+0xfc),XBC
	ldb	a, 6                                   ; FB5AE9  ld A,0x06
	mul8rr	a, l                                ; FB5AEB  mul WA,L
	extz	xwa                                   ; FB5AED  extz XWA
	add	xwa, xbc                               ; FB5AEF  add XWA,XBC
	inc	1, xwa                                 ; FB5AF1  inc 1,XWA
	add	xwa, 0xFDE6A9                          ; FB5AF3  add XWA,0x00fde6a9
	ld	h, (xwa)                                ; FB5AF9  ld H,(XWA)
	cp	h, 0xFF                                 ; FB5AFB  cp H,0xff
	jr z, sub_FB59D2__FB5B33                   ; FB5AFE  jr Z,0xfb5b33
	ldb	c, 3                                   ; FB5B00  ld C,0x03
	mul8rr	c, d                                ; FB5B02  mul BC,D
	extz	xbc                                   ; FB5B04  extz XBC
	ld	(xiz-4), xbc                            ; FB5B06  ld (XIZ+0xfc),XBC
	ldb	a, 39                                  ; FB5B09  ld A,0x27
	mul8rr	a, l                                ; FB5B0B  mul WA,L
	extz	xwa                                   ; FB5B0D  extz XWA
	add	xwa, xbc                               ; FB5B0F  add XWA,XBC
	inc	1, xwa                                 ; FB5B11  inc 1,XWA
	add	xwa, 0xFDF4F1                          ; FB5B13  add XWA,0x00fdf4f1
	ld	c, (xwa)                                ; FB5B19  ld C,(XWA)
	mul	c, 2                                   ; FB5B1B  mul C,0x02
	extz	xbc                                   ; FB5B1E  extz XBC
	ld	(xiz-8), xbc                            ; FB5B20  ld (XIZ+0xf8),XBC
	ldb	a, 0x66                                ; FB5B23  ld A,0x66
	mul8rr	a, h                                ; FB5B25  mul WA,H
	extz	xwa                                   ; FB5B27  extz XWA
	add	xwa, xbc                               ; FB5B29  add XWA,XBC
	add	xwa, 0xFDE6F1                          ; FB5B2B  add XWA,0x00fde6f1
	ld	ix, (xwa)                               ; FB5B31  ld IX,(XWA)
sub_FB59D2__FB5B33:
	ldb	c, 4                                   ; FB5B33  ld C,0x04
	mul8rr	c, d                                ; FB5B35  mul BC,D
	ld	hl, bc                                  ; FB5B37  ld HL,BC
	ld	a, e                                    ; FB5B39  ld A,E
	extz	wa                                    ; FB5B3B  extz WA
	mul	wa, 0x12C                              ; FB5B3D  mul WA,0x012c
	add	wa, bc                                 ; FB5B41  add WA,BC
	add	wa, 0x67                               ; FB5B43  add WA,0x0067
	extz	xwa                                   ; FB5B47  extz XWA
	ld	(xwa+0x1523), ix                        ; FB5B49  ld (XWA+0x1523),IX
	ld	wa, ix                                  ; FB5B4E  ld WA,IX
	pop	xix                                    ; FB5B50  pop XIX
	popw	de                                    ; FB5B51  pop DE
	popw	hl                                    ; FB5B52  pop HL
	unlk32 xiz                                 ; FB5B53  unlk XIZ
	ret                                        ; FB5B55  ret
; --------------------------------------------------------------------------
; sub_FB5B56 -- 0xFB5B56..0xFB5BA9 (84 bytes)
;
; Called from: 1 site(s) outside this module:
;          0xFA9BD2 in Voice_StageChanSel_Reg0440_Reg0480__FA9B74
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFB5B56-0xFB5BA9
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FB5B56:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB5B56  link XIZ,0x0000
	pushw	hl                                   ; FB5B5A  push HL
	ldw	hl, 0                                  ; FB5B5B  ld HL,0x0000
	ld	bc, (xiz+8)                             ; FB5B5E  ld BC,(XIZ+0x08)
	extz	bc                                    ; FB5B61  extz BC
	mul	bc, 0x12C                              ; FB5B63  mul BC,0x012c
	extz	xbc                                   ; FB5B67  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB5B69  ld XWA,(XBC+0x1523)
	ld	c, (xwa+0xD0)                           ; FB5B6E  ld C,(XWA+0x00d0)
	and	c, 15                                  ; FB5B73  and C,0x0f
	extz	bc                                    ; FB5B76  extz BC
	cp	bc, 10                                  ; FB5B78  cp BC,0x000a
	jr z, sub_FB5B56__FB5B86                   ; FB5B7C  jr Z,0xfb5b86
	cp	bc, 11                                  ; FB5B7E  cp BC,0x000b
	jr z, sub_FB5B56__FB5B86                   ; FB5B82  jr Z,0xfb5b86
	jr sub_FB5B56__FB5BA2                      ; FB5B84  jr T,0xfb5ba2
sub_FB5B56__FB5B86:
	ld	bc, (xiz+8)                             ; FB5B86  ld BC,(XIZ+0x08)
	extz	bc                                    ; FB5B89  extz BC
	mul	bc, 0x12C                              ; FB5B8B  mul BC,0x012c
	extz	xbc                                   ; FB5B8F  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB5B91  ld XWA,(XBC+0x1523)
	ld	c, (xwa+0xD2)                           ; FB5B96  ld C,(XWA+0x00d2)
	and	c, 63                                  ; FB5B9B  and C,0x3f
	extz	bc                                    ; FB5B9E  extz BC
	ld	hl, bc                                  ; FB5BA0  ld HL,BC
sub_FB5B56__FB5BA2:
	ld	c, l                                    ; FB5BA2  ld C,L
	ld	a, c                                    ; FB5BA4  ld A,C
	popw	hl                                    ; FB5BA6  pop HL
	unlk32 xiz                                 ; FB5BA7  unlk XIZ
	ret                                        ; FB5BA9  ret
; --------------------------------------------------------------------------
; sub_FB5BAA -- 0xFB5BAA..0xFB5C76 (205 bytes)
;
; Called from: 1 site(s) outside this module:
;          0xFACDCD in sub_FACDC1
;          2 site(s) inside this module:
;          0xFB5705 0xFB57A5
; Inputs:  frame `link XIZ,-4`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFB5BAA-0xFB5C76
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FB5BAA:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FB5BAA  link XIZ,0xfffc
	pushw	hl                                   ; FB5BAE  push HL
	pushw	de                                   ; FB5BAF  push DE
	push	xix                                   ; FB5BB0  push XIX
	ld	bc, (xiz+8)                             ; FB5BB1  ld BC,(XIZ+0x08)
	extz	bc                                    ; FB5BB4  extz BC
	mul	bc, 0x12C                              ; FB5BB6  mul BC,0x012c
	extz	xbc                                   ; FB5BBA  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB5BBC  ld XWA,(XBC+0x1523)
	ld	xix, xwa                                ; FB5BC1  ld XIX,XWA
	ld	h, (xwa+0xD0)                           ; FB5BC3  ld H,(XWA+0x00d0)
	and	h, 15                                  ; FB5BC8  and H,0x0f
	ld	c, h                                    ; FB5BCB  ld C,H
	extz	bc                                    ; FB5BCD  extz BC
	cps	bc, 6                                  ; FB5BCF  cp BC,6
	jr z, sub_FB5BAA__FB5BDA                   ; FB5BD1  jr Z,0xfb5bda
	cps	bc, 7                                  ; FB5BD3  cp BC,7
	jr z, sub_FB5BAA__FB5C1F                   ; FB5BD5  jr Z,0xfb5c1f
	jrl sub_FB5BAA__FB5C58                     ; FB5BD7  jrl T,0xfb5c58
sub_FB5BAA__FB5BDA:
	ldb	c, 6                                   ; FB5BDA  ld C,0x06
	mul8rr	c, h                                ; FB5BDC  mul BC,H
	extz	xbc                                   ; FB5BDE  extz XBC
	inc	4, xbc                                 ; FB5BE0  inc 4,XBC
	add	xbc, 0xFDE6A9                          ; FB5BE2  add XBC,0x00fde6a9
	ld	d, (xbc)                                ; FB5BE8  ld D,(XBC)
	ld	a, (xix+0xD1)                           ; FB5BEA  ld A,(XIX+0x00d1)
	mul	a, 2                                   ; FB5BEF  mul A,0x02
	extz	xwa                                   ; FB5BF2  extz XWA
	ld	(xiz-4), xwa                            ; FB5BF4  ld (XIZ+0xfc),XWA
	ldb	c, 0x66                                ; FB5BF7  ld C,0x66
	mul8rr	c, d                                ; FB5BF9  mul BC,D
	extz	xbc                                   ; FB5BFB  extz XBC
	add	xbc, xwa                               ; FB5BFD  add XBC,XWA
	add	xbc, 0xFDEB53                          ; FB5BFF  add XBC,0x00fdeb53
	ld	de, (xbc)                               ; FB5C05  ld DE,(XBC)
	ld	a, (xix+0xD3)                           ; FB5C07  ld A,(XIX+0x00d3)
	mul	a, 2                                   ; FB5C0C  mul A,0x02
	extz	xwa                                   ; FB5C0F  extz XWA
	add	xwa, 0xFDEBEC                          ; FB5C11  add XWA,0x00fdebec
	ld	bc, (xwa)                               ; FB5C17  ld BC,(XWA)
	ld	hl, bc                                  ; FB5C19  ld HL,BC
	or	hl, de                                  ; FB5C1B  or HL,DE
	jr sub_FB5BAA__FB5C5B                      ; FB5C1D  jr T,0xfb5c5b
sub_FB5BAA__FB5C1F:
	ldb	c, 6                                   ; FB5C1F  ld C,0x06
	mul8rr	c, h                                ; FB5C21  mul BC,H
	extz	xbc                                   ; FB5C23  extz XBC
	inc	4, xbc                                 ; FB5C25  inc 4,XBC
	add	xbc, 0xFDE6A9                          ; FB5C27  add XBC,0x00fde6a9
	ld	d, (xbc)                                ; FB5C2D  ld D,(XBC)
	ldb	c, 39                                  ; FB5C2F  ld C,0x27
	mul8rr	c, h                                ; FB5C31  mul BC,H
	extz	xbc                                   ; FB5C33  extz XBC
	inc	6, xbc                                 ; FB5C35  inc 6,XBC
	add	xbc, 0xFDF4F1                          ; FB5C37  add XBC,0x00fdf4f1
	ld	a, (xbc)                                ; FB5C3D  ld A,(XBC)
	mul	a, 2                                   ; FB5C3F  mul A,0x02
	extz	xwa                                   ; FB5C42  extz XWA
	ld	xix, xwa                                ; FB5C44  ld XIX,XWA
	ldb	c, 0x66                                ; FB5C46  ld C,0x66
	mul8rr	c, d                                ; FB5C48  mul BC,D
	extz	xbc                                   ; FB5C4A  extz XBC
	add	xbc, xwa                               ; FB5C4C  add XBC,XWA
	add	xbc, 0xFDEB53                          ; FB5C4E  add XBC,0x00fdeb53
	ld	hl, (xbc)                               ; FB5C54  ld HL,(XBC)
	jr sub_FB5BAA__FB5C5B                      ; FB5C56  jr T,0xfb5c5b
sub_FB5BAA__FB5C58:
	ldw	hl, 0                                  ; FB5C58  ld HL,0x0000
sub_FB5BAA__FB5C5B:
	ld	bc, (xiz+8)                             ; FB5C5B  ld BC,(XIZ+0x08)
	extz	bc                                    ; FB5C5E  extz BC
	mul	bc, 0x12C                              ; FB5C60  mul BC,0x012c
	add	bc, 0x6D                               ; FB5C64  add BC,0x006d
	extz	xbc                                   ; FB5C68  extz XBC
	ld	(xbc+0x1523), hl                        ; FB5C6A  ld (XBC+0x1523),HL
	ld	wa, hl                                  ; FB5C6F  ld WA,HL
	pop	xix                                    ; FB5C71  pop XIX
	popw	de                                    ; FB5C72  pop DE
	popw	hl                                    ; FB5C73  pop HL
	unlk32 xiz                                 ; FB5C74  unlk XIZ
	ret                                        ; FB5C76  ret
; --------------------------------------------------------------------------
; sub_FB5C77 -- 0xFB5C77..0xFB5D04 (142 bytes)
;
; Called from: 3 site(s) outside this module:
;          0xFAC6FE in sub_FAC6F2, 0xFAC7A8 in sub_FAC79C
;          0xFACE20 in sub_FACE14
;          2 site(s) inside this module:
;          0xFB570C 0xFB57AC
; Inputs:  frame `link XIZ,-4`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFB5C77-0xFB5D04
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FB5C77:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FB5C77  link XIZ,0xfffc
	pushw	hl                                   ; FB5C7B  push HL
	pushw	de                                   ; FB5C7C  push DE
	push	xix                                   ; FB5C7D  push XIX
	lda	xix, (0x1523:16)                      ; FB5C7E  lda XIX,0x1523
	ld	d, (xiz+8)                              ; FB5C82  ld D,(XIZ+0x08)
	ld	c, d                                    ; FB5C85  ld C,D
	extz	bc                                    ; FB5C87  extz BC
	mul	bc, 0x12C                              ; FB5C89  mul BC,0x012c
	extz	xix                                   ; FB5C8D  extz XIX
	extpfx5 0xE3, 0x07, 0xF0, 0xE4, 0x20       ; FB5C8F  ld XWA,(XIX+BC)
	ld	h, (xwa+0xD0)                           ; FB5C94  ld H,(XWA+0x00d0)
	and	h, 15                                  ; FB5C99  and H,0x0f
	ld	c, h                                    ; FB5C9C  ld C,H
	extz	bc                                    ; FB5C9E  extz BC
	cps	bc, 6                                  ; FB5CA0  cp BC,6
	jr z, sub_FB5C77__FB5CAA                   ; FB5CA2  jr Z,0xfb5caa
	cps	bc, 7                                  ; FB5CA4  cp BC,7
	jr z, sub_FB5C77__FB5CAA                   ; FB5CA6  jr Z,0xfb5caa
	jr sub_FB5C77__FB5CE8                      ; FB5CA8  jr T,0xfb5ce8
sub_FB5C77__FB5CAA:
	ldb	c, 6                                   ; FB5CAA  ld C,0x06
	mul8rr	c, h                                ; FB5CAC  mul BC,H
	extz	xbc                                   ; FB5CAE  extz XBC
	inc	5, xbc                                 ; FB5CB0  inc 5,XBC
	add	xbc, 0xFDE6A9                          ; FB5CB2  add XBC,0x00fde6a9
	ld	e, (xbc)                                ; FB5CB8  ld E,(XBC)
	ld	c, d                                    ; FB5CBA  ld C,D
	extz	bc                                    ; FB5CBC  extz BC
	mul	bc, 0x12C                              ; FB5CBE  mul BC,0x012c
	extz	xix                                   ; FB5CC2  extz XIX
	extpfx5 0xE3, 0x07, 0xF0, 0xE4, 0x20       ; FB5CC4  ld XWA,(XIX+BC)
	ld	c, (xwa+0xD2)                           ; FB5CC9  ld C,(XWA+0x00d2)
	mul	c, 2                                   ; FB5CCE  mul C,0x02
	extz	xbc                                   ; FB5CD1  extz XBC
	ld	(xiz-4), xbc                            ; FB5CD3  ld (XIZ+0xfc),XBC
	ldb	a, 0x66                                ; FB5CD6  ld A,0x66
	mul8rr	a, e                                ; FB5CD8  mul WA,E
	extz	xwa                                   ; FB5CDA  extz XWA
	add	xwa, xbc                               ; FB5CDC  add XWA,XBC
	add	xwa, 0xFDE6F1                          ; FB5CDE  add XWA,0x00fde6f1
	ld	hl, (xwa)                               ; FB5CE4  ld HL,(XWA)
	jr sub_FB5C77__FB5CEB                      ; FB5CE6  jr T,0xfb5ceb
sub_FB5C77__FB5CE8:
	ldw	hl, 0                                  ; FB5CE8  ld HL,0x0000
sub_FB5C77__FB5CEB:
	ld	c, d                                    ; FB5CEB  ld C,D
	extz	bc                                    ; FB5CED  extz BC
	mul	bc, 0x12C                              ; FB5CEF  mul BC,0x012c
	add	bc, 0x6F                               ; FB5CF3  add BC,0x006f
	extz	xbc                                   ; FB5CF7  extz XBC
	add	bc, ix                                 ; FB5CF9  add BC,IX
	ld	(xbc), hl                               ; FB5CFB  ld (XBC),HL
	ld	wa, hl                                  ; FB5CFD  ld WA,HL
	pop	xix                                    ; FB5CFF  pop XIX
	popw	de                                    ; FB5D00  pop DE
	popw	hl                                    ; FB5D01  pop HL
	unlk32 xiz                                 ; FB5D02  unlk XIZ
	ret                                        ; FB5D04  ret
; --------------------------------------------------------------------------
; sub_FB5D05 -- 0xFB5D05..0xFB5D6B (103 bytes)
;
; Called from: 7 site(s) outside this module:
;          0xFB0D26 in sub_FB0B95__FB0C19, 0xFB0FBF in VoiceParams_Compute_A__FB0ED5
;          0xFB11CE in VoiceParams_Compute_A__FB10F4, 0xFB1449 in VoiceParams_Compute_A__FB131D
;          0xFB16E3 in VoiceParams_Compute_A__FB15B0, 0xFB19A7 in VoiceParams_Compute_A__FB185E
;          0xFB1C79 in VoiceParams_Compute_A__FB1B30
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFB5D05-0xFB5D6B
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FB5D05:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB5D05  link XIZ,0x0000
	push	xhl                                   ; FB5D09  push XHL
	pushw	de                                   ; FB5D0A  push DE
	push	xix                                   ; FB5D0B  push XIX
	ld	bc, (xiz+8)                             ; FB5D0C  ld BC,(XIZ+0x08)
	extz	bc                                    ; FB5D0F  extz BC
	mul	bc, 0x12C                              ; FB5D11  mul BC,0x012c
	ld	hl, bc                                  ; FB5D15  ld HL,BC
	add	bc, 9                                  ; FB5D17  add BC,0x0009
	extz	xbc                                   ; FB5D1B  extz XBC
	ld	wa, (xbc+0x1523)                        ; FB5D1D  ld WA,(XBC+0x1523)
	and	wa, 0x8000                             ; FB5D22  and WA,0x8000
	jr z, sub_FB5D05__FB5D60                   ; FB5D26  jr Z,0xfb5d60
	extz	xhl                                   ; FB5D28  extz XHL
	ld	xbc, (xhl+0x1523)                       ; FB5D2A  ld XBC,(XHL+0x1523)
	ld	xix, xbc                                ; FB5D2F  ld XIX,XBC
	ld	a, (xbc+0xD0)                           ; FB5D31  ld A,(XBC+0x00d0)
	and	a, 15                                  ; FB5D36  and A,0x0f
	cp	a, 9                                    ; FB5D39  cp A,0x09
	jr nz, sub_FB5D05__FB5D60                  ; FB5D3C  jr NZ,0xfb5d60
	ld	a, (xbc+0xD1)                           ; FB5D3E  ld A,(XBC+0x00d1)
	extz	wa                                    ; FB5D43  extz WA
	extz	xwa                                   ; FB5D45  extz XWA
	add	xwa, 0xFDF6C5                          ; FB5D47  add XWA,0x00fdf6c5
	ld	d, (xwa)                                ; FB5D4D  ld D,(XWA)
	ld	bc, hl                                  ; FB5D4F  ld BC,HL
	add	bc, 9                                  ; FB5D51  add BC,0x0009
	extz	xbc                                   ; FB5D55  extz XBC
	extpfx7 0xD3, 0xE5, 0x23, 0x15, 0x3C, 0xFF, 0xDF ; FB5D57  and (XBC+0x1523),0xdfff
	jr sub_FB5D05__FB5D64                      ; FB5D5E  jr T,0xfb5d64
sub_FB5D05__FB5D60:
	ldb	a, 0xFF                                ; FB5D60  ld A,0xff
	jr sub_FB5D05__FB5D66                      ; FB5D62  jr T,0xfb5d66
sub_FB5D05__FB5D64:
	ld	a, d                                    ; FB5D64  ld A,D
sub_FB5D05__FB5D66:
	pop	xix                                    ; FB5D66  pop XIX
	popw	de                                    ; FB5D67  pop DE
	pop	xhl                                    ; FB5D68  pop XHL
	unlk32 xiz                                 ; FB5D69  unlk XIZ
	ret                                        ; FB5D6B  ret
; --------------------------------------------------------------------------
; sub_FB5D6C -- 0xFB5D6C..0xFB5DFF (148 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFB64AB
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFB5D6C-0xFB5DFF
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FB5D6C:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB5D6C  link XIZ,0x0000
	push	xhl                                   ; FB5D70  push XHL
	pushw	de                                   ; FB5D71  push DE
	push	xix                                   ; FB5D72  push XIX
	ldb	d, 0                                   ; FB5D73  ld D,0x00
	ld	bc, (xiz+8)                             ; FB5D75  ld BC,(XIZ+0x08)
	extz	bc                                    ; FB5D78  extz BC
	mul	bc, 0x12C                              ; FB5D7A  mul BC,0x012c
	ld	hl, bc                                  ; FB5D7E  ld HL,BC
	add	bc, 9                                  ; FB5D80  add BC,0x0009
	extz	xbc                                   ; FB5D84  extz XBC
	ld	wa, (xbc+0x1523)                        ; FB5D86  ld WA,(XBC+0x1523)
	and	wa, 0x8000                             ; FB5D8B  and WA,0x8000
	jr z, sub_FB5D6C__FB5DF8                   ; FB5D8F  jr Z,0xfb5df8
	extz	xhl                                   ; FB5D91  extz XHL
	ld	xbc, (xhl+0x1523)                       ; FB5D93  ld XBC,(XHL+0x1523)
	ld	h, (xbc+0xD0)                           ; FB5D98  ld H,(XBC+0x00d0)
	and	h, 15                                  ; FB5D9D  and H,0x0f
	ld	c, h                                    ; FB5DA0  ld C,H
	extz	bc                                    ; FB5DA2  extz BC
	cp	bc, 10                                  ; FB5DA4  cp BC,0x000a
	jr z, sub_FB5D6C__FB5DB2                   ; FB5DA8  jr Z,0xfb5db2
	cp	bc, 11                                  ; FB5DAA  cp BC,0x000b
	jr z, sub_FB5D6C__FB5DB2                   ; FB5DAE  jr Z,0xfb5db2
	jr sub_FB5D6C__FB5DDF                      ; FB5DB0  jr T,0xfb5ddf
sub_FB5D6C__FB5DB2:
	ldb	c, 39                                  ; FB5DB2  ld C,0x27
	mul8rr	c, h                                ; FB5DB4  mul BC,H
	extz	xbc                                   ; FB5DB6  extz XBC
	ld	xix, xbc                                ; FB5DB8  ld XIX,XBC
	add	xbc, 13                                ; FB5DBA  add XBC,0x0000000d
	add	xbc, 0xFDF4F1                          ; FB5DC0  add XBC,0x00fdf4f1
	ld	a, (xbc)                                ; FB5DC6  ld A,(XBC)
	and	a, 0x80                                ; FB5DC8  and A,0x80
	jr z, sub_FB5D6C__FB5DDF                   ; FB5DCB  jr Z,0xfb5ddf
	ld	xbc, xix                                ; FB5DCD  ld XBC,XIX
	add	xbc, 14                                ; FB5DCF  add XBC,0x0000000e
	add	xbc, 0xFDF4F1                          ; FB5DD5  add XBC,0x00fdf4f1
	ld	a, (xbc)                                ; FB5DDB  ld A,(XBC)
	jr sub_FB5D6C__FB5DFA                      ; FB5DDD  jr T,0xfb5dfa
sub_FB5D6C__FB5DDF:
	ld	bc, (xiz+8)                             ; FB5DDF  ld BC,(XIZ+0x08)
	extz	bc                                    ; FB5DE2  extz BC
	mul	bc, 0x12C                              ; FB5DE4  mul BC,0x012c
	extz	xbc                                   ; FB5DE8  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB5DEA  ld XWA,(XBC+0x1523)
	ld	c, (xwa+0xD7)                           ; FB5DEF  ld C,(XWA+0x00d7)
	ld	a, c                                    ; FB5DF4  ld A,C
	jr sub_FB5D6C__FB5DFA                      ; FB5DF6  jr T,0xfb5dfa
sub_FB5D6C__FB5DF8:
	ld	a, d                                    ; FB5DF8  ld A,D
sub_FB5D6C__FB5DFA:
	pop	xix                                    ; FB5DFA  pop XIX
	popw	de                                    ; FB5DFB  pop DE
	pop	xhl                                    ; FB5DFC  pop XHL
	unlk32 xiz                                 ; FB5DFD  unlk XIZ
	ret                                        ; FB5DFF  ret
; --------------------------------------------------------------------------
; sub_FB5E00 -- 0xFB5E00..0xFB5E38 (57 bytes)
;
; Called from: 3 site(s) outside this module:
;          0xFAFC58 in sub_FAFBEC__FAFC28, 0xFBBCF2 in sub_FBB793__FBBC8B
;          0xFBBE39 in sub_FBB793__FBBE34
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFB5E00-0xFB5E38
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FB5E00:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB5E00  link XIZ,0x0000
	push	xhl                                   ; FB5E04  push XHL
	pushw	de                                   ; FB5E05  push DE
	ldb	d, 0                                   ; FB5E06  ld D,0x00
	ld	bc, (xiz+8)                             ; FB5E08  ld BC,(XIZ+0x08)
	extz	bc                                    ; FB5E0B  extz BC
	mul	bc, 0x12C                              ; FB5E0D  mul BC,0x012c
	ld	hl, bc                                  ; FB5E11  ld HL,BC
	add	bc, 9                                  ; FB5E13  add BC,0x0009
	extz	xbc                                   ; FB5E17  extz XBC
	ld	wa, (xbc+0x1523)                        ; FB5E19  ld WA,(XBC+0x1523)
	and	wa, 0x8000                             ; FB5E1E  and WA,0x8000
	jr z, sub_FB5E00__FB5E32                   ; FB5E22  jr Z,0xfb5e32
	extz	xhl                                   ; FB5E24  extz XHL
	ld	xbc, (xhl+0x1523)                       ; FB5E26  ld XBC,(XHL+0x1523)
	ld	a, (xbc+0xD8)                           ; FB5E2B  ld A,(XBC+0x00d8)
	jr sub_FB5E00__FB5E34                      ; FB5E30  jr T,0xfb5e34
sub_FB5E00__FB5E32:
	ld	a, d                                    ; FB5E32  ld A,D
sub_FB5E00__FB5E34:
	popw	de                                    ; FB5E34  pop DE
	pop	xhl                                    ; FB5E35  pop XHL
	unlk32 xiz                                 ; FB5E36  unlk XIZ
	ret                                        ; FB5E38  ret
; --------------------------------------------------------------------------
; Dev10C_ChanSelHighBits -- 0xFB5E39..0xFB5F90 (344 bytes)
;
; Called from: 2 site(s) outside this module:
;          0xFA9AE7 in Voice_StageChanSel_Reg0440_Reg0480__FA9ACB, 0xFA9B90 in Voice_StageChanSel_Reg0440_Reg0480__FA9B74
; Inputs:  frame `link XIZ,-4`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C)
; Outputs: no absolute-addressed write.
; Arms:    3 computed-goto arm(s) inside this routine: 0xFB5EAA 0xFB5F44 0xFB5F89
; Evidence: the listing below is the byte-identical round-trip of 0xFB5E39-0xFB5F90
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
;
; ★ IT RETURNS EXACTLY THREE VALUES: 0x0000, 0x0040 and 0x00C0 -- and that is a
;   SWEEP of the routine, not a sample.  Outside the 48-byte jump table at
;   0xFB5E7A only three instructions load WA: 0xFB5F7F `ld WA,0x00c0`, 0xFB5F84
;   `ld WA,0x0040` and 0xFB5F89 `ld WA,IX`.  IX is written twice, 0xFB5E46
;   `ld IX,0x0000` and 0xFB5F62 `ld XIX,XBC`.  0xFB5F89 is reached FIVE ways, not
;   four, and every one of them is BELOW 0xFB5F62, so IX is still 0 at every
;   arrival: the four conditional branches 0xFB5E6A, 0xFB5ED4, 0xFB5F20, 0xFB5F5A,
;   AND the computed goto `jp T,XBC` at 0xFB5E78, whose table entries 6, 8 and 9
;   hold 0xFB5F89.  The decode covers 0xFB5E39..0xFB5F90 with one gap, and that gap
;   is the jump table.
; ★ NAME: at BOTH of its two call sites the value becomes the high bits of a
;   0x0010C000 channel-selector word -- 0xFA9AE7 for word 8 (register 0x0440) and
;   0xFA9B90 for word 9 (register 0x0480), each OR'd with a 6- or 7-bit channel
;   index at 0xFA9B28 and 0xFA9BC6.  Both callers REJECT the value 0
;   (0xFA9AEF/0xFA9AF1 and 0xFA9B98/0xFA9B9A), so only 0x0040 and 0x00C0 ever
;   reach a register, and bit 6 of the word is therefore always set.
; ★ The index into the jump table is bounded to 0..11 by 0xFB5E66 `cp BC,0x000b`
;   and out-of-range returns 0 (0xFB5E6A).  The twelve entries hold only THREE
;   distinct targets: 0xFB5EAA (entries 0-5, 7), 0xFB5F89 (6, 8, 9) and 0xFB5F44
;   (10, 11).  Read from the ROM, not inferred.
; ⚠ NOT ESTABLISHED: what 0x0040 and 0x00C0 MEAN.  Their width (2 bits), their
;   position (bits 7..6) and their source are measured; their meaning is not, and
;   naming them "modes" here would be an invention.
; Evidence: `python3 notes/prom_c_understanding_round4.py --modes`, which sweeps
;          the address extent and enumerates the jump table rather than reasoning
;          about it; every cited address is re-decoded by an independent
;          disassembler.
; --------------------------------------------------------------------------
Dev10C_ChanSelHighBits:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FB5E39  link XIZ,0xfffc
	pushw	hl                                   ; FB5E3D  push HL
	pushw	de                                   ; FB5E3E  push DE
	push	xix                                   ; FB5E3F  push XIX
	ld	d, (xiz+10)                             ; FB5E40  ld D,(XIZ+0x0a)
	ld	l, (xiz+8)                              ; FB5E43  ld L,(XIZ+0x08)
	ldw	ix, 0                                  ; FB5E46  ld IX,0x0000
	ld	c, l                                    ; FB5E49  ld C,L
	extz	bc                                    ; FB5E4B  extz BC
	mul	bc, 0x12C                              ; FB5E4D  mul BC,0x012c
	extz	xbc                                   ; FB5E51  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB5E53  ld XWA,(XBC+0x1523)
	ld	h, (xwa+0xD0)                           ; FB5E58  ld H,(XWA+0x00d0)
	and	h, 15                                  ; FB5E5D  and H,0x0f
	ld	c, h                                    ; FB5E60  ld C,H
	extz	bc                                    ; FB5E62  extz BC
	extz	xbc                                   ; FB5E64  extz XBC
	cp	bc, 11                                  ; FB5E66  cp BC,0x000b
	jrl ugt, Dev10C_ChanSelHighBits__FB5F89                ; FB5E6A  jrl UGT,0xfb5f89
	sll	bc, 2                                  ; FB5E6D  sll 0x02,BC
	add	xbc, 0xFB5E7A                          ; FB5E70  add XBC,0x00fb5e7a
	ld	xbc, (xbc)                              ; FB5E76  ld XBC,(XBC)
	jp	(xbc)                                   ; FB5E78  jp T,XBC
; 12 x u32 computed-goto table, 0xFB5E7A-0xFB5EA9, 48 bytes.
; THE ENTRY COUNT IS ESTABLISHED TWICE AND THE TWO AGREE: the `cp rr,11`
; guard before the `jr UGT` gives 12, and reading consecutive words while
; each is a plausible code address also gives 12.  The word after the last
; entry is not a plausible entry, so the table ends here rather than being
; assumed to.  (python3 notes/prom_c_jumptables.py 0xFB405F 0xFB6E0A;
; asserted per table by notes/prom_c_voiceparam_checks.py section 2.)
; Entry 0 is the SAME address the out-of-range guard branches to.
	.long 0x00FB5EAA	; 0xFB5E7A  entry 0 -> 0xFB5EAA   (also the out-of-range arm)
	.long 0x00FB5EAA	; 0xFB5E7E  entry 1 -> 0xFB5EAA
	.long 0x00FB5EAA	; 0xFB5E82  entry 2 -> 0xFB5EAA
	.long 0x00FB5EAA	; 0xFB5E86  entry 3 -> 0xFB5EAA
	.long 0x00FB5EAA	; 0xFB5E8A  entry 4 -> 0xFB5EAA
	.long 0x00FB5EAA	; 0xFB5E8E  entry 5 -> 0xFB5EAA
	.long 0x00FB5F89	; 0xFB5E92  entry 6 -> 0xFB5F89
	.long 0x00FB5EAA	; 0xFB5E96  entry 7 -> 0xFB5EAA
	.long 0x00FB5F89	; 0xFB5E9A  entry 8 -> 0xFB5F89
	.long 0x00FB5F89	; 0xFB5E9E  entry 9 -> 0xFB5F89
	.long 0x00FB5F44	; 0xFB5EA2  entry 10 -> 0xFB5F44
	.long 0x00FB5F44	; 0xFB5EA6  entry 11 -> 0xFB5F44
Dev10C_ChanSelHighBits__FB5EAA:
	cp (xiz+12), 0x00                          ; FB5EAA  cp (XIZ+0x0c),0x00
	jr nz, Dev10C_ChanSelHighBits__FB5EFC                  ; FB5EAE  jr NZ,0xfb5efc
	ldb	c, 5                                   ; FB5EB0  ld C,0x05
	mul8rr	c, d                                ; FB5EB2  mul BC,D
	extz	xbc                                   ; FB5EB4  extz XBC
	ld	(xiz-4), xbc                            ; FB5EB6  ld (XIZ+0xfc),XBC
	ldb	a, 39                                  ; FB5EB9  ld A,0x27
	mul8rr	a, h                                ; FB5EBB  mul WA,H
	extz	xwa                                   ; FB5EBD  extz XWA
	add	xwa, xbc                               ; FB5EBF  add XWA,XBC
	add	xwa, 19                                ; FB5EC1  add XWA,0x00000013
	add	xwa, 0xFDF4F1                          ; FB5EC7  add XWA,0x00fdf4f1
	ld	h, (xwa)                                ; FB5ECD  ld H,(XWA)
	ld	c, h                                    ; FB5ECF  ld C,H
	and	c, 0x80                                ; FB5ED1  and C,0x80
	jrl z, Dev10C_ChanSelHighBits__FB5F89                  ; FB5ED4  jrl Z,0xfb5f89
	ld	c, l                                    ; FB5ED7  ld C,L
	extz	bc                                    ; FB5ED9  extz BC
	mul	bc, 0x12C                              ; FB5EDB  mul BC,0x012c
	extz	xbc                                   ; FB5EDF  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB5EE1  ld XWA,(XBC+0x1523)
	ld	c, (xwa+0xD0)                           ; FB5EE6  ld C,(XWA+0x00d0)
	and	c, 64                                  ; FB5EEB  and C,0x40
	jrl z, Dev10C_ChanSelHighBits__FB5F84                  ; FB5EEE  jrl Z,0xfb5f84
	ld	c, h                                    ; FB5EF1  ld C,H
	and	c, 8                                   ; FB5EF3  and C,0x08
	jrl z, Dev10C_ChanSelHighBits__FB5F84                  ; FB5EF6  jrl Z,0xfb5f84
	jrl Dev10C_ChanSelHighBits__FB5F7F                     ; FB5EF9  jrl T,0xfb5f7f
Dev10C_ChanSelHighBits__FB5EFC:
	ldb	c, 5                                   ; FB5EFC  ld C,0x05
	mul8rr	c, d                                ; FB5EFE  mul BC,D
	extz	xbc                                   ; FB5F00  extz XBC
	ld	(xiz-4), xbc                            ; FB5F02  ld (XIZ+0xfc),XBC
	ldb	a, 39                                  ; FB5F05  ld A,0x27
	mul8rr	a, h                                ; FB5F07  mul WA,H
	extz	xwa                                   ; FB5F09  extz XWA
	add	xwa, xbc                               ; FB5F0B  add XWA,XBC
	add	xwa, 19                                ; FB5F0D  add XWA,0x00000013
	add	xwa, 0xFDF4F1                          ; FB5F13  add XWA,0x00fdf4f1
	ld	h, (xwa)                                ; FB5F19  ld H,(XWA)
	ld	c, h                                    ; FB5F1B  ld C,H
	and	c, 64                                  ; FB5F1D  and C,0x40
	jr z, Dev10C_ChanSelHighBits__FB5F89                   ; FB5F20  jr Z,0xfb5f89
	ld	c, l                                    ; FB5F22  ld C,L
	extz	bc                                    ; FB5F24  extz BC
	mul	bc, 0x12C                              ; FB5F26  mul BC,0x012c
	extz	xbc                                   ; FB5F2A  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB5F2C  ld XWA,(XBC+0x1523)
	ld	c, (xwa+0xD0)                           ; FB5F31  ld C,(XWA+0x00d0)
	and	c, 64                                  ; FB5F36  and C,0x40
	jr z, Dev10C_ChanSelHighBits__FB5F84                   ; FB5F39  jr Z,0xfb5f84
	ld	c, h                                    ; FB5F3B  ld C,H
	and	c, 4                                   ; FB5F3D  and C,0x04
	jr z, Dev10C_ChanSelHighBits__FB5F84                   ; FB5F40  jr Z,0xfb5f84
	jr Dev10C_ChanSelHighBits__FB5F7F                      ; FB5F42  jr T,0xfb5f7f
Dev10C_ChanSelHighBits__FB5F44:
	ld	c, l                                    ; FB5F44  ld C,L
	extz	bc                                    ; FB5F46  extz BC
	mul	bc, 0x12C                              ; FB5F48  mul BC,0x012c
	extz	xbc                                   ; FB5F4C  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB5F4E  ld XWA,(XBC+0x1523)
	ld	c, (xwa+0xD1)                           ; FB5F53  ld C,(XWA+0x00d1)
	cps	c, 0                                   ; FB5F58  cp C,0
	jr z, Dev10C_ChanSelHighBits__FB5F89                   ; FB5F5A  jr Z,0xfb5f89
	ldb	c, 5                                   ; FB5F5C  ld C,0x05
	mul8rr	c, d                                ; FB5F5E  mul BC,D
	extz	xbc                                   ; FB5F60  extz XBC
	ld	xix, xbc                                ; FB5F62  ld XIX,XBC
	ldb	a, 39                                  ; FB5F64  ld A,0x27
	mul8rr	a, h                                ; FB5F66  mul WA,H
	extz	xwa                                   ; FB5F68  extz XWA
	add	xwa, xbc                               ; FB5F6A  add XWA,XBC
	add	xwa, 19                                ; FB5F6C  add XWA,0x00000013
	add	xwa, 0xFDF4F1                          ; FB5F72  add XWA,0x00fdf4f1
	ld	c, (xwa)                                ; FB5F78  ld C,(XWA)
	and	c, 8                                   ; FB5F7A  and C,0x08
	jr z, Dev10C_ChanSelHighBits__FB5F84                   ; FB5F7D  jr Z,0xfb5f84
Dev10C_ChanSelHighBits__FB5F7F:
	ldw	wa, 0xC0                               ; FB5F7F  ld WA,0x00c0
	jr Dev10C_ChanSelHighBits__FB5F8B                      ; FB5F82  jr T,0xfb5f8b
Dev10C_ChanSelHighBits__FB5F84:
	ldw	wa, 64                                 ; FB5F84  ld WA,0x0040
	jr Dev10C_ChanSelHighBits__FB5F8B                      ; FB5F87  jr T,0xfb5f8b
Dev10C_ChanSelHighBits__FB5F89:
	ld	wa, ix                                  ; FB5F89  ld WA,IX
Dev10C_ChanSelHighBits__FB5F8B:
	pop	xix                                    ; FB5F8B  pop XIX
	popw	de                                    ; FB5F8C  pop DE
	popw	hl                                    ; FB5F8D  pop HL
	unlk32 xiz                                 ; FB5F8E  unlk XIZ
	ret                                        ; FB5F90  ret
; --------------------------------------------------------------------------
; sub_FB5F91 -- 0xFB5F91..0xFB6019 (137 bytes)
;
; Called from: 1 site(s) outside this module:
;          0xFA9E2A in Voice_StageRegs_0180_AB__FA9E12
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFB5F91-0xFB6019
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FB5F91:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB5F91  link XIZ,0x0000
	pushw	hl                                   ; FB5F95  push HL
	pushw	de                                   ; FB5F96  push DE
	push	xix                                   ; FB5F97  push XIX
	ldw	de, 0                                  ; FB5F98  ld DE,0x0000
	ld	bc, (xiz+8)                             ; FB5F9B  ld BC,(XIZ+0x08)
	extz	bc                                    ; FB5F9E  extz BC
	mul	bc, 0x12C                              ; FB5FA0  mul BC,0x012c
	extz	xbc                                   ; FB5FA4  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB5FA6  ld XWA,(XBC+0x1523)
	ld	h, (xwa+0xD0)                           ; FB5FAB  ld H,(XWA+0x00d0)
	and	h, 15                                  ; FB5FB0  and H,0x0f
	ld	c, h                                    ; FB5FB3  ld C,H
	extz	bc                                    ; FB5FB5  extz BC
	cps	bc, 6                                  ; FB5FB7  cp BC,6
	jr z, sub_FB5F91__FB5FC1                   ; FB5FB9  jr Z,0xfb5fc1
	cps	bc, 7                                  ; FB5FBB  cp BC,7
	jr z, sub_FB5F91__FB5FC1                   ; FB5FBD  jr Z,0xfb5fc1
	jr sub_FB5F91__FB6012                      ; FB5FBF  jr T,0xfb6012
sub_FB5F91__FB5FC1:
	ldb	c, 5                                   ; FB5FC1  ld C,0x05
	extpfx3 0x8E, 0x0A, 0x43                   ; FB5FC3  mul BC,(XIZ+0x0a)
	extz	xbc                                   ; FB5FC6  extz XBC
	ld	xix, xbc                                ; FB5FC8  ld XIX,XBC
	ldb	a, 39                                  ; FB5FCA  ld A,0x27
	mul8rr	a, h                                ; FB5FCC  mul WA,H
	extz	xwa                                   ; FB5FCE  extz XWA
	add	xwa, xbc                               ; FB5FD0  add XWA,XBC
	add	xwa, 19                                ; FB5FD2  add XWA,0x00000013
	add	xwa, 0xFDF4F1                          ; FB5FD8  add XWA,0x00fdf4f1
	ld	h, (xwa)                                ; FB5FDE  ld H,(XWA)
	ld	c, h                                    ; FB5FE0  ld C,H
	and	c, 32                                  ; FB5FE2  and C,0x20
	jr z, sub_FB5F91__FB6012                   ; FB5FE5  jr Z,0xfb6012
	ld	bc, (xiz+8)                             ; FB5FE7  ld BC,(XIZ+0x08)
	extz	bc                                    ; FB5FEA  extz BC
	mul	bc, 0x12C                              ; FB5FEC  mul BC,0x012c
	extz	xbc                                   ; FB5FF0  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB5FF2  ld XWA,(XBC+0x1523)
	ld	c, (xwa+0xD0)                           ; FB5FF7  ld C,(XWA+0x00d0)
	and	c, 64                                  ; FB5FFC  and C,0x40
	jr z, sub_FB5F91__FB600D                   ; FB5FFF  jr Z,0xfb600d
	ld	c, h                                    ; FB6001  ld C,H
	and	c, 2                                   ; FB6003  and C,0x02
	jr z, sub_FB5F91__FB600D                   ; FB6006  jr Z,0xfb600d
	ldw	wa, 0xC000                             ; FB6008  ld WA,0xc000
	jr sub_FB5F91__FB6014                      ; FB600B  jr T,0xfb6014
sub_FB5F91__FB600D:
	ldw	wa, 0x4000                             ; FB600D  ld WA,0x4000
	jr sub_FB5F91__FB6014                      ; FB6010  jr T,0xfb6014
sub_FB5F91__FB6012:
	ld	wa, de                                  ; FB6012  ld WA,DE
sub_FB5F91__FB6014:
	pop	xix                                    ; FB6014  pop XIX
	popw	de                                    ; FB6015  pop DE
	popw	hl                                    ; FB6016  pop HL
	unlk32 xiz                                 ; FB6017  unlk XIZ
	ret                                        ; FB6019  ret
; --------------------------------------------------------------------------
; sub_FB601A -- 0xFB601A..0xFB607E (101 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFB63CC
; Inputs:  frame `link XIZ,-4`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFB601A-0xFB607E
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FB601A:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FB601A  link XIZ,0xfffc
	pushw	hl                                   ; FB601E  push HL
	push	xix                                   ; FB601F  push XIX
	ld	bc, (xiz+8)                             ; FB6020  ld BC,(XIZ+0x08)
	extz	bc                                    ; FB6023  extz BC
	mul	bc, 0x12C                              ; FB6025  mul BC,0x012c
	extz	xbc                                   ; FB6029  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB602B  ld XWA,(XBC+0x1523)
	ld	xix, xwa                                ; FB6030  ld XIX,XWA
	ld	c, (xwa+0xD0)                           ; FB6032  ld C,(XWA+0x00d0)
	ld	l, c                                    ; FB6037  ld L,C
	and	l, 15                                  ; FB6039  and L,0x0f
	ldb	c, 5                                   ; FB603C  ld C,0x05
	extpfx3 0x8E, 0x0A, 0x43                   ; FB603E  mul BC,(XIZ+0x0a)
	extz	xbc                                   ; FB6041  extz XBC
	ld	(xiz-4), xbc                            ; FB6043  ld (XIZ+0xfc),XBC
	ldb	c, 39                                  ; FB6046  ld C,0x27
	mul8rr	c, l                                ; FB6048  mul BC,L
	extz	xbc                                   ; FB604A  extz XBC
	extpfx3 0xAE, 0xFC, 0x81                   ; FB604C  add XBC,(XIZ+0xfc)
	add	xbc, 20                                ; FB604F  add XBC,0x00000014
	add	xbc, 0xFDF4F1                          ; FB6055  add XBC,0x00fdf4f1
	ld	h, (xbc)                                ; FB605B  ld H,(XBC)
	ld	c, l                                    ; FB605D  ld C,L
	extz	bc                                    ; FB605F  extz BC
	cp	bc, 8                                   ; FB6061  cp BC,0x0008
	jr z, sub_FB601A__FB6069                   ; FB6065  jr Z,0xfb6069
	jr sub_FB601A__FB6078                      ; FB6067  jr T,0xfb6078
sub_FB601A__FB6069:
	cp (xiz+10), 0x01                          ; FB6069  cp (XIZ+0x0a),0x01
	jr nz, sub_FB601A__FB6078                  ; FB606D  jr NZ,0xfb6078
	ld	c, (xix+0xD3)                           ; FB606F  ld C,(XIX+0x00d3)
	ld	a, c                                    ; FB6074  ld A,C
	jr sub_FB601A__FB607A                      ; FB6076  jr T,0xfb607a
sub_FB601A__FB6078:
	ld	a, h                                    ; FB6078  ld A,H
sub_FB601A__FB607A:
	pop	xix                                    ; FB607A  pop XIX
	popw	hl                                    ; FB607B  pop HL
	unlk32 xiz                                 ; FB607C  unlk XIZ
	ret                                        ; FB607E  ret
; --------------------------------------------------------------------------
; sub_FB607F -- 0xFB607F..0xFB6157 (217 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFB63F5
; Inputs:  frame `link XIZ,-4`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Arms:    4 computed-goto arm(s) inside this routine: 0xFB6105 0xFB6123 0xFB6141 0xFB6150
; Evidence: the listing below is the byte-identical round-trip of 0xFB607F-0xFB6157
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FB607F:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FB607F  link XIZ,0xfffc
	pushw	hl                                   ; FB6083  push HL
	pushw	de                                   ; FB6084  push DE
	push	xix                                   ; FB6085  push XIX
	ld	d, (xiz+8)                              ; FB6086  ld D,(XIZ+0x08)
	ld	l, (xiz+10)                             ; FB6089  ld L,(XIZ+0x0a)
	ld	c, d                                    ; FB608C  ld C,D
	extz	bc                                    ; FB608E  extz BC
	mul	bc, 0x12C                              ; FB6090  mul BC,0x012c
	extz	xbc                                   ; FB6094  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB6096  ld XWA,(XBC+0x1523)
	ld	xix, xwa                                ; FB609B  ld XIX,XWA
	ld	c, (xwa+0xD0)                           ; FB609D  ld C,(XWA+0x00d0)
	ld	e, c                                    ; FB60A2  ld E,C
	and	e, 15                                  ; FB60A4  and E,0x0f
	ldb	c, 5                                   ; FB60A7  ld C,0x05
	mul8rr	c, l                                ; FB60A9  mul BC,L
	extz	xbc                                   ; FB60AB  extz XBC
	ld	(xiz-4), xbc                            ; FB60AD  ld (XIZ+0xfc),XBC
	ldb	c, 39                                  ; FB60B0  ld C,0x27
	mul8rr	c, e                                ; FB60B2  mul BC,E
	extz	xbc                                   ; FB60B4  extz XBC
	extpfx3 0xAE, 0xFC, 0x81                   ; FB60B6  add XBC,(XIZ+0xfc)
	add	xbc, 21                                ; FB60B9  add XBC,0x00000015
	add	xbc, 0xFDF4F1                          ; FB60BF  add XBC,0x00fdf4f1
	ld	h, (xbc)                                ; FB60C5  ld H,(XBC)
	ld	c, e                                    ; FB60C7  ld C,E
	extz	bc                                    ; FB60C9  extz BC
	extz	xbc                                   ; FB60CB  extz XBC
	cp	bc, 8                                   ; FB60CD  cp BC,0x0008
	jrl ugt, sub_FB607F__FB6150                ; FB60D1  jrl UGT,0xfb6150
	sll	bc, 2                                  ; FB60D4  sll 0x02,BC
	add	xbc, 0xFB60E1                          ; FB60D7  add XBC,0x00fb60e1
	ld	xbc, (xbc)                              ; FB60DD  ld XBC,(XBC)
	jp	(xbc)                                   ; FB60DF  jp T,XBC
; 9 x u32 computed-goto table, 0xFB60E1-0xFB6104, 36 bytes.
; THE ENTRY COUNT IS ESTABLISHED TWICE AND THE TWO AGREE: the `cp rr,8`
; guard before the `jr UGT` gives 9, and reading consecutive words while
; each is a plausible code address also gives 9.  The word after the last
; entry is not a plausible entry, so the table ends here rather than being
; assumed to.  (python3 notes/prom_c_jumptables.py 0xFB405F 0xFB6E0A;
; asserted per table by notes/prom_c_voiceparam_checks.py section 2.)
; Entry 0 is the SAME address the out-of-range guard branches to.
	.long 0x00FB6105	; 0xFB60E1  entry 0 -> 0xFB6105   (also the out-of-range arm)
	.long 0x00FB6105	; 0xFB60E5  entry 1 -> 0xFB6105
	.long 0x00FB6105	; 0xFB60E9  entry 2 -> 0xFB6105
	.long 0x00FB6105	; 0xFB60ED  entry 3 -> 0xFB6105
	.long 0x00FB6123	; 0xFB60F1  entry 4 -> 0xFB6123
	.long 0x00FB6123	; 0xFB60F5  entry 5 -> 0xFB6123
	.long 0x00FB6150	; 0xFB60F9  entry 6 -> 0xFB6150
	.long 0x00FB6150	; 0xFB60FD  entry 7 -> 0xFB6150
	.long 0x00FB6141	; 0xFB6101  entry 8 -> 0xFB6141
sub_FB607F__FB6105:
	cps	l, 1                                   ; FB6105  cp L,1
	jr nz, sub_FB607F__FB6150                  ; FB6107  jr NZ,0xfb6150
	ld	c, d                                    ; FB6109  ld C,D
	extz	bc                                    ; FB610B  extz BC
	mul	bc, 0x12C                              ; FB610D  mul BC,0x012c
	extz	xbc                                   ; FB6111  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB6113  ld XWA,(XBC+0x1523)
	ld	c, (xwa+0xD3)                           ; FB6118  ld C,(XWA+0x00d3)
	add	c, c                                   ; FB611D  add C,C
	ld	a, c                                    ; FB611F  ld A,C
	jr sub_FB607F__FB6152                      ; FB6121  jr T,0xfb6152
sub_FB607F__FB6123:
	cps	l, 1                                   ; FB6123  cp L,1
	jr nz, sub_FB607F__FB6150                  ; FB6125  jr NZ,0xfb6150
	ld	c, d                                    ; FB6127  ld C,D
	extz	bc                                    ; FB6129  extz BC
	mul	bc, 0x12C                              ; FB612B  mul BC,0x012c
	extz	xbc                                   ; FB612F  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB6131  ld XWA,(XBC+0x1523)
	ld	c, (xwa+0xD5)                           ; FB6136  ld C,(XWA+0x00d5)
	add	c, c                                   ; FB613B  add C,C
	ld	a, c                                    ; FB613D  ld A,C
	jr sub_FB607F__FB6152                      ; FB613F  jr T,0xfb6152
sub_FB607F__FB6141:
	cps	l, 1                                   ; FB6141  cp L,1
	jr nz, sub_FB607F__FB6150                  ; FB6143  jr NZ,0xfb6150
	ld	c, (xix+0xD2)                           ; FB6145  ld C,(XIX+0x00d2)
	add	c, c                                   ; FB614A  add C,C
	ld	a, c                                    ; FB614C  ld A,C
	jr sub_FB607F__FB6152                      ; FB614E  jr T,0xfb6152
sub_FB607F__FB6150:
	ld	a, h                                    ; FB6150  ld A,H
sub_FB607F__FB6152:
	pop	xix                                    ; FB6152  pop XIX
	popw	de                                    ; FB6153  pop DE
	popw	hl                                    ; FB6154  pop HL
	unlk32 xiz                                 ; FB6155  unlk XIZ
	ret                                        ; FB6157  ret
; --------------------------------------------------------------------------
; sub_FB6158 -- 0xFB6158..0xFB618F (56 bytes)
;
; Called from: no site outside this module.
;          2 site(s) inside this module:
;          0xFB6238 0xFB6245
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFB6158-0xFB618F
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FB6158:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB6158  link XIZ,0x0000
	ld	bc, (xiz+8)                             ; FB615C  ld BC,(XIZ+0x08)
	extz	bc                                    ; FB615F  extz BC
	mul	bc, 0x12C                              ; FB6161  mul BC,0x012c
	inc	6, bc                                  ; FB6165  inc 6,BC
	extz	xbc                                   ; FB6167  extz XBC
	ld	wa, (xbc+0x1523)                        ; FB6169  ld WA,(XBC+0x1523)
	and	wa, 0xC000                             ; FB616E  and WA,0xc000
	jr z, sub_FB6158__FB618B                   ; FB6172  jr Z,0xfb618b
	ld	bc, (xiz+10)                            ; FB6174  ld BC,(XIZ+0x0a)
	extz	bc                                    ; FB6177  extz BC
	cps	bc, 0                                  ; FB6179  cp BC,0
	jr z, sub_FB6158__FB6183                   ; FB617B  jr Z,0xfb6183
	cps	bc, 1                                  ; FB617D  cp BC,1
	jr z, sub_FB6158__FB6187                   ; FB617F  jr Z,0xfb6187
	jr sub_FB6158__FB618B                      ; FB6181  jr T,0xfb618b
sub_FB6158__FB6183:
	ldb	a, 0xFC                                ; FB6183  ld A,0xfc
	jr sub_FB6158__FB618D                      ; FB6185  jr T,0xfb618d
sub_FB6158__FB6187:
	ldb	a, 0xF0                                ; FB6187  ld A,0xf0
	jr sub_FB6158__FB618D                      ; FB6189  jr T,0xfb618d
sub_FB6158__FB618B:
	sub	a, a                                   ; FB618B  sub A,A
sub_FB6158__FB618D:
	unlk32 xiz                                 ; FB618D  unlk XIZ
	ret                                        ; FB618F  ret
; --------------------------------------------------------------------------
; sub_FB6190 -- 0xFB6190..0xFB6271 (226 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFB640E
; Inputs:  frame `link XIZ,-4`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Calls:   0xFB6158 = sub_FB6158
; Arms:    4 computed-goto arm(s) inside this routine: 0xFB6217 0xFB6240 0xFB624B 0xFB626A
; Evidence: the listing below is the byte-identical round-trip of 0xFB6190-0xFB6271
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FB6190:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FB6190  link XIZ,0xfffc
	pushw	hl                                   ; FB6194  push HL
	pushw	de                                   ; FB6195  push DE
	push	xix                                   ; FB6196  push XIX
	lda	xix, (0x1523:16)                      ; FB6197  lda XIX,0x1523
	ld	d, (xiz+8)                              ; FB619B  ld D,(XIZ+0x08)
	ld	l, (xiz+10)                             ; FB619E  ld L,(XIZ+0x0a)
	ld	c, d                                    ; FB61A1  ld C,D
	extz	bc                                    ; FB61A3  extz BC
	mul	bc, 0x12C                              ; FB61A5  mul BC,0x012c
	extz	xix                                   ; FB61A9  extz XIX
	extpfx5 0xE3, 0x07, 0xF0, 0xE4, 0x20       ; FB61AB  ld XWA,(XIX+BC)
	ld	c, (xwa+0xD0)                           ; FB61B0  ld C,(XWA+0x00d0)
	ld	e, c                                    ; FB61B5  ld E,C
	and	e, 15                                  ; FB61B7  and E,0x0f
	ldb	c, 5                                   ; FB61BA  ld C,0x05
	mul8rr	c, l                                ; FB61BC  mul BC,L
	extz	xbc                                   ; FB61BE  extz XBC
	ld	(xiz-4), xbc                            ; FB61C0  ld (XIZ+0xfc),XBC
	ldb	a, 39                                  ; FB61C3  ld A,0x27
	mul8rr	a, e                                ; FB61C5  mul WA,E
	extz	xwa                                   ; FB61C7  extz XWA
	add	xwa, xbc                               ; FB61C9  add XWA,XBC
	add	xwa, 22                                ; FB61CB  add XWA,0x00000016
	add	xwa, 0xFDF4F1                          ; FB61D1  add XWA,0x00fdf4f1
	ld	h, (xwa)                                ; FB61D7  ld H,(XWA)
	ld	c, e                                    ; FB61D9  ld C,E
	extz	bc                                    ; FB61DB  extz BC
	extz	xbc                                   ; FB61DD  extz XBC
	cp	bc, 8                                   ; FB61DF  cp BC,0x0008
	jrl ugt, sub_FB6190__FB626A                ; FB61E3  jrl UGT,0xfb626a
	sll	bc, 2                                  ; FB61E6  sll 0x02,BC
	add	xbc, 0xFB61F3                          ; FB61E9  add XBC,0x00fb61f3
	ld	xbc, (xbc)                              ; FB61EF  ld XBC,(XBC)
	jp	(xbc)                                   ; FB61F1  jp T,XBC
; 9 x u32 computed-goto table, 0xFB61F3-0xFB6216, 36 bytes.
; THE ENTRY COUNT IS ESTABLISHED TWICE AND THE TWO AGREE: the `cp rr,8`
; guard before the `jr UGT` gives 9, and reading consecutive words while
; each is a plausible code address also gives 9.  The word after the last
; entry is not a plausible entry, so the table ends here rather than being
; assumed to.  (python3 notes/prom_c_jumptables.py 0xFB405F 0xFB6E0A;
; asserted per table by notes/prom_c_voiceparam_checks.py section 2.)
; Entry 0 is the SAME address the out-of-range guard branches to.
	.long 0x00FB6217	; 0xFB61F3  entry 0 -> 0xFB6217   (also the out-of-range arm)
	.long 0x00FB6217	; 0xFB61F7  entry 1 -> 0xFB6217
	.long 0x00FB6217	; 0xFB61FB  entry 2 -> 0xFB6217
	.long 0x00FB6217	; 0xFB61FF  entry 3 -> 0xFB6217
	.long 0x00FB6240	; 0xFB6203  entry 4 -> 0xFB6240
	.long 0x00FB6240	; 0xFB6207  entry 5 -> 0xFB6240
	.long 0x00FB624B	; 0xFB620B  entry 6 -> 0xFB624B
	.long 0x00FB626A	; 0xFB620F  entry 7 -> 0xFB626A
	.long 0x00FB624B	; 0xFB6213  entry 8 -> 0xFB624B
sub_FB6190__FB6217:
	cps	l, 1                                   ; FB6217  cp L,1
	jr nz, sub_FB6190__FB6233                  ; FB6219  jr NZ,0xfb6233
	ld	c, d                                    ; FB621B  ld C,D
	extz	bc                                    ; FB621D  extz BC
	mul	bc, 0x12C                              ; FB621F  mul BC,0x012c
	extz	xix                                   ; FB6223  extz XIX
	extpfx5 0xE3, 0x07, 0xF0, 0xE4, 0x20       ; FB6225  ld XWA,(XIX+BC)
	ld	h, (xwa+0xD5)                           ; FB622A  ld H,(XWA+0x00d5)
	ldb	c, 0x64                                ; FB622F  ld C,0x64
	sub	h, c                                   ; FB6231  sub H,C
sub_FB6190__FB6233:
	pushw	hl                                   ; FB6233  push HL
	push	0                                     ; FB6234  push 0x00
	push	d                                     ; FB6236  push D
	calr (0xFB6158 - 0xFB623B)                 ; FB6238  calr 0xfb6158
	add	a, h                                   ; FB623B  add A,H
	pop	xiy                                    ; FB623D  pop XIY
	jr sub_FB6190__FB626C                      ; FB623E  jr T,0xfb626c
sub_FB6190__FB6240:
	pushw	hl                                   ; FB6240  push HL
	push	0                                     ; FB6241  push 0x00
	push	d                                     ; FB6243  push D
	calr (0xFB6158 - 0xFB6248)                 ; FB6245  calr 0xfb6158
	pop	xiy                                    ; FB6248  pop XIY
	jr sub_FB6190__FB626C                      ; FB6249  jr T,0xfb626c
sub_FB6190__FB624B:
	cps	l, 1                                   ; FB624B  cp L,1
	jr nz, sub_FB6190__FB626A                  ; FB624D  jr NZ,0xfb626a
	ld	c, d                                    ; FB624F  ld C,D
	extz	bc                                    ; FB6251  extz BC
	mul	bc, 0x12C                              ; FB6253  mul BC,0x012c
	extz	xix                                   ; FB6257  extz XIX
	extpfx5 0xE3, 0x07, 0xF0, 0xE4, 0x20       ; FB6259  ld XWA,(XIX+BC)
	ld	c, (xwa+0xD4)                           ; FB625E  ld C,(XWA+0x00d4)
	sub	c, 0x64                                ; FB6263  sub C,0x64
	ld	a, c                                    ; FB6266  ld A,C
	jr sub_FB6190__FB626C                      ; FB6268  jr T,0xfb626c
sub_FB6190__FB626A:
	ld	a, h                                    ; FB626A  ld A,H
sub_FB6190__FB626C:
	pop	xix                                    ; FB626C  pop XIX
	popw	de                                    ; FB626D  pop DE
	popw	hl                                    ; FB626E  pop HL
	unlk32 xiz                                 ; FB626F  unlk XIZ
	ret                                        ; FB6271  ret
; --------------------------------------------------------------------------
; sub_FB6272 -- 0xFB6272..0xFB6399 (296 bytes)
;
; Called from: 7 site(s) outside this module:
;          0xFB0D18 in sub_FB0B95__FB0C19, 0xFB0FB1 in VoiceParams_Compute_A__FB0ED5
;          0xFB11C0 in VoiceParams_Compute_A__FB10F4, 0xFB1436 in VoiceParams_Compute_A__FB131D
;          0xFB16D0 in VoiceParams_Compute_A__FB15B0, 0xFB1992 in VoiceParams_Compute_A__FB185E
;          0xFB1C64 in VoiceParams_Compute_A__FB1B30
; Inputs:  frame `link XIZ,-10`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Arms:    4 computed-goto arm(s) inside this routine: 0xFB6313 0xFB633A 0xFB6360 0xFB6392
; Evidence: the listing below is the byte-identical round-trip of 0xFB6272-0xFB6399
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FB6272:
	link32 0xEE, 0x0C, 0xF6, 0xFF              ; FB6272  link XIZ,0xfff6
	pushw	hl                                   ; FB6276  push HL
	pushw	de                                   ; FB6277  push DE
	push	xix                                   ; FB6278  push XIX
	lda	xix, (0x1523:16)                      ; FB6279  lda XIX,0x1523
	ld	e, (xiz+8)                              ; FB627D  ld E,(XIZ+0x08)
	ld	d, (xiz+10)                             ; FB6280  ld D,(XIZ+0x0a)
	ld	c, e                                    ; FB6283  ld C,E
	extz	bc                                    ; FB6285  extz BC
	mul	bc, 0x12C                              ; FB6287  mul BC,0x012c
	ld	hl, bc                                  ; FB628B  ld HL,BC
	add	bc, 9                                  ; FB628D  add BC,0x0009
	extz	xix                                   ; FB6291  extz XIX
	extpfx5 0xD3, 0x07, 0xF0, 0xE4, 0x20       ; FB6293  ld WA,(XIX+BC)
	and	wa, 0x8000                             ; FB6298  and WA,0x8000
	jrl z, sub_FB6272__FB638E                  ; FB629C  jrl Z,0xfb638e
	extz	xix                                   ; FB629F  extz XIX
	extpfx5 0xE3, 0x07, 0xF0, 0xEC, 0x21       ; FB62A1  ld XBC,(XIX+HL)
	ld	(xiz-4), xbc                            ; FB62A6  ld (XIZ+0xfc),XBC
	ld	a, (xbc+0xD0)                           ; FB62A9  ld A,(XBC+0x00d0)
	and	a, 15                                  ; FB62AE  and A,0x0f
	ld	(xiz-6), a                              ; FB62B1  ld (XIZ+0xfa),A
	ldb	a, 5                                   ; FB62B4  ld A,0x05
	mul8rr	a, d                                ; FB62B6  mul WA,D
	extz	xwa                                   ; FB62B8  extz XWA
	ld	(xiz-10), xwa                           ; FB62BA  ld (XIZ+0xf6),XWA
	ldb	c, 39                                  ; FB62BD  ld C,0x27
	extpfx3 0x8E, 0xFA, 0x43                   ; FB62BF  mul BC,(XIZ+0xfa)
	extz	xbc                                   ; FB62C2  extz XBC
	add	xbc, xwa                               ; FB62C4  add XBC,XWA
	add	xbc, 23                                ; FB62C6  add XBC,0x00000017
	add	xbc, 0xFDF4F1                          ; FB62CC  add XBC,0x00fdf4f1
	ld	h, (xbc)                                ; FB62D2  ld H,(XBC)
	ld	bc, (xiz-6)                             ; FB62D4  ld BC,(XIZ+0xfa)
	extz	bc                                    ; FB62D7  extz BC
	extz	xbc                                   ; FB62D9  extz XBC
	cp	bc, 8                                   ; FB62DB  cp BC,0x0008
	jrl ugt, sub_FB6272__FB6392                ; FB62DF  jrl UGT,0xfb6392
	sll	bc, 2                                  ; FB62E2  sll 0x02,BC
	add	xbc, 0xFB62EF                          ; FB62E5  add XBC,0x00fb62ef
	ld	xbc, (xbc)                              ; FB62EB  ld XBC,(XBC)
	jp	(xbc)                                   ; FB62ED  jp T,XBC
; 9 x u32 computed-goto table, 0xFB62EF-0xFB6312, 36 bytes.
; THE ENTRY COUNT IS ESTABLISHED TWICE AND THE TWO AGREE: the `cp rr,8`
; guard before the `jr UGT` gives 9, and reading consecutive words while
; each is a plausible code address also gives 9.  The word after the last
; entry is not a plausible entry, so the table ends here rather than being
; assumed to.  (python3 notes/prom_c_jumptables.py 0xFB405F 0xFB6E0A;
; asserted per table by notes/prom_c_voiceparam_checks.py section 2.)
; Entry 0 is the SAME address the out-of-range guard branches to.
	.long 0x00FB6313	; 0xFB62EF  entry 0 -> 0xFB6313   (also the out-of-range arm)
	.long 0x00FB6313	; 0xFB62F3  entry 1 -> 0xFB6313
	.long 0x00FB6313	; 0xFB62F7  entry 2 -> 0xFB6313
	.long 0x00FB6313	; 0xFB62FB  entry 3 -> 0xFB6313
	.long 0x00FB633A	; 0xFB62FF  entry 4 -> 0xFB633A
	.long 0x00FB633A	; 0xFB6303  entry 5 -> 0xFB633A
	.long 0x00FB6392	; 0xFB6307  entry 6 -> 0xFB6392
	.long 0x00FB6392	; 0xFB630B  entry 7 -> 0xFB6392
	.long 0x00FB6360	; 0xFB630F  entry 8 -> 0xFB6360
sub_FB6272__FB6313:
	cps	d, 1                                   ; FB6313  cp D,1
	jrl nz, sub_FB6272__FB6392                 ; FB6315  jrl NZ,0xfb6392
	ld	c, e                                    ; FB6318  ld C,E
	extz	bc                                    ; FB631A  extz BC
	mul	bc, 0x12C                              ; FB631C  mul BC,0x012c
	extz	xix                                   ; FB6320  extz XIX
	extpfx5 0xE3, 0x07, 0xF0, 0xE4, 0x20       ; FB6322  ld XWA,(XIX+BC)
	ld	c, (xwa+0xD4)                           ; FB6327  ld C,(XWA+0x00d4)
	extz	bc                                    ; FB632C  extz BC
	extz	xbc                                   ; FB632E  extz XBC
	add	xbc, 0xFDEBB9                          ; FB6330  add XBC,0x00fdebb9
	ld	h, (xbc)                                ; FB6336  ld H,(XBC)
	jr sub_FB6272__FB6378                      ; FB6338  jr T,0xfb6378
sub_FB6272__FB633A:
	cps	d, 1                                   ; FB633A  cp D,1
	jr nz, sub_FB6272__FB6392                  ; FB633C  jr NZ,0xfb6392
	ld	c, e                                    ; FB633E  ld C,E
	extz	bc                                    ; FB6340  extz BC
	mul	bc, 0x12C                              ; FB6342  mul BC,0x012c
	extz	xix                                   ; FB6346  extz XIX
	extpfx5 0xE3, 0x07, 0xF0, 0xE4, 0x20       ; FB6348  ld XWA,(XIX+BC)
	ld	c, (xwa+0xD6)                           ; FB634D  ld C,(XWA+0x00d6)
	extz	bc                                    ; FB6352  extz BC
	extz	xbc                                   ; FB6354  extz XBC
	add	xbc, 0xFDEBB9                          ; FB6356  add XBC,0x00fdebb9
	ld	h, (xbc)                                ; FB635C  ld H,(XBC)
	jr sub_FB6272__FB6378                      ; FB635E  jr T,0xfb6378
sub_FB6272__FB6360:
	cps	d, 1                                   ; FB6360  cp D,1
	jr nz, sub_FB6272__FB6392                  ; FB6362  jr NZ,0xfb6392
	ld	xbc, (xiz-4)                            ; FB6364  ld XBC,(XIZ+0xfc)
	ld	a, (xbc+0xD1)                           ; FB6367  ld A,(XBC+0x00d1)
	extz	wa                                    ; FB636C  extz WA
	extz	xwa                                   ; FB636E  extz XWA
	add	xwa, 0xFDEBB9                          ; FB6370  add XWA,0x00fdebb9
	ld	h, (xwa)                                ; FB6376  ld H,(XWA)
sub_FB6272__FB6378:
	ld	c, e                                    ; FB6378  ld C,E
	extz	bc                                    ; FB637A  extz BC
	mul	bc, 0x12C                              ; FB637C  mul BC,0x012c
	add	bc, 9                                  ; FB6380  add BC,0x0009
	extz	xbc                                   ; FB6384  extz XBC
	add	bc, ix                                 ; FB6386  add BC,IX
	extpfx4 0x91, 0x3C, 0xFF, 0xDF             ; FB6388  and (XBC),0xdfff
	jr sub_FB6272__FB6392                      ; FB638C  jr T,0xfb6392
sub_FB6272__FB638E:
	sub	a, a                                   ; FB638E  sub A,A
	jr sub_FB6272__FB6394                      ; FB6390  jr T,0xfb6394
sub_FB6272__FB6392:
	ld	a, h                                    ; FB6392  ld A,H
sub_FB6272__FB6394:
	pop	xix                                    ; FB6394  pop XIX
	popw	de                                    ; FB6395  pop DE
	popw	hl                                    ; FB6396  pop HL
	unlk32 xiz                                 ; FB6397  unlk XIZ
	ret                                        ; FB6399  ret
; --------------------------------------------------------------------------
; sub_FB639A -- 0xFB639A..0xFB6486 (237 bytes)
;
; Called from: 7 site(s) outside this module:
;          0xFAFC4E in sub_FAFBEC__FAFC28, 0xFBBCBA in sub_FBB793__FBBC8B
;          0xFBBDD9 in sub_FBB793__FBBDCB, 0xFBBDEF in sub_FBB793__FBBDE1
;          0xFBBE05 in sub_FBB793__FBBDF7, 0xFBBE12 in sub_FBB793__FBBE0D
;          0xFBBE1F in sub_FBB793__FBBE1A
;          2 site(s) inside this module:
;          0xFB684F 0xFB6ACD
; Inputs:  frame `link XIZ,-12`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Calls:   0xFB601A = sub_FB601A, 0xFB607F = sub_FB607F
;          0xFB6190 = sub_FB6190
; Evidence: the listing below is the byte-identical round-trip of 0xFB639A-0xFB6486
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FB639A:
	link32 0xEE, 0x0C, 0xF4, 0xFF              ; FB639A  link XIZ,0xfff4
	pushw	hl                                   ; FB639E  push HL
	pushw	de                                   ; FB639F  push DE
	push	xix                                   ; FB63A0  push XIX
	ld	e, (xiz+8)                              ; FB63A1  ld E,(XIZ+0x08)
	ld	c, e                                    ; FB63A4  ld C,E
	extz	bc                                    ; FB63A6  extz BC
	mul	bc, 0x12C                              ; FB63A8  mul BC,0x012c
	ld	xix, xbc                                ; FB63AC  ld XIX,XBC
	add	bc, 9                                  ; FB63AE  add BC,0x0009
	extz	xbc                                   ; FB63B2  extz XBC
	ld	wa, (xbc+0x1523)                        ; FB63B4  ld WA,(XBC+0x1523)
	ld	hl, wa                                  ; FB63B9  ld HL,WA
	and	hl, 0x8000                             ; FB63BB  and HL,0x8000
	ldb	d, 0                                   ; FB63BF  ld D,0x00
	jrl z, sub_FB639A__FB6435                  ; FB63C1  jrl Z,0xfb6435
	ldw	hl, 0                                  ; FB63C4  ld HL,0x0000
sub_FB639A__FB63C7:
	push	0                                     ; FB63C7  push 0x00
	push	d                                     ; FB63C9  push D
	pushw	de                                   ; FB63CB  push DE
	calr (0xFB601A - 0xFB63CF)                 ; FB63CC  calr 0xfb601a
	ld	(xiz-2), a                              ; FB63CF  ld (XIZ+0xfe),A
	ld	(xiz-4), hl                             ; FB63D2  ld (XIZ+0xfc),HL
	ld	bc, (xiz-4)                             ; FB63D5  ld BC,(XIZ+0xfc)
	ld	(xiz-6), bc                             ; FB63D8  ld (XIZ+0xfa),BC
	ld	wa, ix                                  ; FB63DB  ld WA,IX
	add	wa, bc                                 ; FB63DD  add WA,BC
	ld	(xiz-8), wa                             ; FB63DF  ld (XIZ+0xf8),WA
	add	wa, 0xAC                               ; FB63E2  add WA,0x00ac
	extz	xwa                                   ; FB63E6  extz XWA
	ld	c, (xiz-2)                              ; FB63E8  ld C,(XIZ+0xfe)
	ld	(xwa+0x1523), c                         ; FB63EB  ld (XWA+0x1523),C
	push	0                                     ; FB63F0  push 0x00
	push	d                                     ; FB63F2  push D
	pushw	de                                   ; FB63F4  push DE
	calr (0xFB607F - 0xFB63F8)                 ; FB63F5  calr 0xfb607f
	ld	(xiz-10), a                             ; FB63F8  ld (XIZ+0xf6),A
	ld	bc, (xiz-8)                             ; FB63FB  ld BC,(XIZ+0xf8)
	add	bc, 0xAD                               ; FB63FE  add BC,0x00ad
	extz	xbc                                   ; FB6402  extz XBC
	ld	(xbc+0x1523), a                         ; FB6404  ld (XBC+0x1523),A
	push	0                                     ; FB6409  push 0x00
	push	d                                     ; FB640B  push D
	pushw	de                                   ; FB640D  push DE
	calr (0xFB6190 - 0xFB6411)                 ; FB640E  calr 0xfb6190
	ld	(xiz-12), a                             ; FB6411  ld (XIZ+0xf4),A
	ld	bc, (xiz-8)                             ; FB6414  ld BC,(XIZ+0xf8)
	add	bc, 0xAE                               ; FB6417  add BC,0x00ae
	extz	xbc                                   ; FB641B  extz XBC
	ld	(xbc+0x1523), a                         ; FB641D  ld (XBC+0x1523),A
	ld	hl, (xiz-4)                             ; FB6422  ld HL,(XIZ+0xfc)
	add	hl, 41                                 ; FB6425  add HL,0x0029
	inc	1, d                                   ; FB6429  inc 1,D
	inc	8, xsp                                 ; FB642B  inc 0,XSP
	inc	4, xsp                                 ; FB642D  inc 4,XSP
	cps	d, 4                                   ; FB642F  cp D,4
	jr c, sub_FB639A__FB63C7                   ; FB6431  jr C,0xfb63c7
	jr sub_FB639A__FB6481                      ; FB6433  jr T,0xfb6481
sub_FB639A__FB6435:
	ldw	hl, 0                                  ; FB6435  ld HL,0x0000
	ldb	d, 4                                   ; FB6438  ld D,0x04
sub_FB639A__FB643A:
	ld	(xiz-2), hl                             ; FB643A  ld (XIZ+0xfe),HL
	ld	bc, (xiz-2)                             ; FB643D  ld BC,(XIZ+0xfe)
	ld	(xiz-4), bc                             ; FB6440  ld (XIZ+0xfc),BC
	ld	wa, ix                                  ; FB6443  ld WA,IX
	add	wa, bc                                 ; FB6445  add WA,BC
	ld	(xiz-6), wa                             ; FB6447  ld (XIZ+0xfa),WA
	add	wa, 0xAC                               ; FB644A  add WA,0x00ac
	extz	xwa                                   ; FB644E  extz XWA
	ld	(xwa+0x1523), 0                         ; FB6450  ld (XWA+0x1523),0x00
	ld	bc, (xiz-6)                             ; FB6456  ld BC,(XIZ+0xfa)
	add	bc, 0xAD                               ; FB6459  add BC,0x00ad
	extz	xbc                                   ; FB645D  extz XBC
	ld	(xbc+0x1523), 0                         ; FB645F  ld (XBC+0x1523),0x00
	ld	bc, (xiz-6)                             ; FB6465  ld BC,(XIZ+0xfa)
	add	bc, 0xAE                               ; FB6468  add BC,0x00ae
	extz	xbc                                   ; FB646C  extz XBC
	ld	(xbc+0x1523), 0                         ; FB646E  ld (XBC+0x1523),0x00
	ld	hl, (xiz-2)                             ; FB6474  ld HL,(XIZ+0xfe)
	add	hl, 41                                 ; FB6477  add HL,0x0029
	dec	1, d                                   ; FB647B  dec 1,D
	cps	d, 0                                   ; FB647D  cp D,0
	jr nz, sub_FB639A__FB643A                  ; FB647F  jr NZ,0xfb643a
sub_FB639A__FB6481:
	pop	xix                                    ; FB6481  pop XIX
	popw	de                                    ; FB6482  pop DE
	popw	hl                                    ; FB6483  pop HL
	unlk32 xiz                                 ; FB6484  unlk XIZ
	ret                                        ; FB6486  ret
; --------------------------------------------------------------------------
; sub_FB6487 -- 0xFB6487..0xFB64C7 (65 bytes)
;
; Called from: 3 site(s) outside this module:
;          0xFAFC53 in sub_FAFBEC__FAFC28, 0xFBBCE8 in sub_FBB793__FBBC8B
;          0xFBBE2C in sub_FBB793__FBBE27
;          2 site(s) inside this module:
;          0xFB6698 0xFB68F4
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Calls:   0xFB5D6C = sub_FB5D6C
; Evidence: the listing below is the byte-identical round-trip of 0xFB6487-0xFB64C7
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FB6487:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB6487  link XIZ,0x0000
	pushw	hl                                   ; FB648B  push HL
	ld	l, (xiz+8)                              ; FB648C  ld L,(XIZ+0x08)
	ldb	h, 0                                   ; FB648F  ld H,0x00
	ld	c, l                                    ; FB6491  ld C,L
	extz	bc                                    ; FB6493  extz BC
	mul	bc, 0x12C                              ; FB6495  mul BC,0x012c
	add	bc, 9                                  ; FB6499  add BC,0x0009
	extz	xbc                                   ; FB649D  extz XBC
	ld	wa, (xbc+0x1523)                        ; FB649F  ld WA,(XBC+0x1523)
	and	wa, 0x8000                             ; FB64A4  and WA,0x8000
	jr z, sub_FB6487__FB64B1                   ; FB64A8  jr Z,0xfb64b1
	pushw	hl                                   ; FB64AA  push HL
	calr (0xFB5D6C - 0xFB64AE)                 ; FB64AB  calr 0xfb5d6c
	ld	h, a                                    ; FB64AE  ld H,A
	popw	bc                                    ; FB64B0  pop BC
sub_FB6487__FB64B1:
	ld	c, l                                    ; FB64B1  ld C,L
	extz	bc                                    ; FB64B3  extz BC
	mul	bc, 0x12C                              ; FB64B5  mul BC,0x012c
	add	bc, 0x75                               ; FB64B9  add BC,0x0075
	extz	xbc                                   ; FB64BD  extz XBC
	ld	(xbc+0x1523), h                         ; FB64BF  ld (XBC+0x1523),H
	popw	hl                                    ; FB64C4  pop HL
	unlk32 xiz                                 ; FB64C5  unlk XIZ
	ret                                        ; FB64C7  ret
; --------------------------------------------------------------------------
; sub_FB64C8 -- 0xFB64C8..0xFB64FF (56 bytes)
;
; Called from: 1 site(s) outside this module:
;          0xFB86D6 in sub_FB86BB
;          1 site(s) inside this module:
;          0xFB6C04
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFB64C8-0xFB64FF
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FB64C8:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB64C8  link XIZ,0x0000
	pushw	hl                                   ; FB64CC  push HL
	push	xix                                   ; FB64CD  push XIX
	lda	xix, (0x1523:16)                      ; FB64CE  lda XIX,0x1523
	ld	bc, (xiz+8)                             ; FB64D2  ld BC,(XIZ+0x08)
	extz	bc                                    ; FB64D5  extz BC
	mul	bc, 0x12C                              ; FB64D7  mul BC,0x012c
	ld	hl, bc                                  ; FB64DB  ld HL,BC
	inc	4, hl                                  ; FB64DD  inc 4,HL
	ld	bc, ix                                  ; FB64DF  ld BC,IX
	extz	xbc                                   ; FB64E1  extz XBC
	add	bc, hl                                 ; FB64E3  add BC,HL
	extpfx4 0x91, 0x3C, 0xFC, 0xFF             ; FB64E5  and (XBC),0xfffc
	extz	xix                                   ; FB64E9  extz XIX
	extpfx5 0xD3, 0x07, 0xF0, 0xEC, 0x21       ; FB64EB  ld BC,(XIX+HL)
	set	2, bc                                  ; FB64F0  set 0x02,BC
	ld	wa, ix                                  ; FB64F3  ld WA,IX
	extz	xwa                                   ; FB64F5  extz XWA
	add	wa, hl                                 ; FB64F7  add WA,HL
	ld	(xwa), bc                               ; FB64F9  ld (XWA),BC
	pop	xix                                    ; FB64FB  pop XIX
	popw	hl                                    ; FB64FC  pop HL
	unlk32 xiz                                 ; FB64FD  unlk XIZ
	ret                                        ; FB64FF  ret
; --------------------------------------------------------------------------
; sub_FB6500 -- 0xFB6500..0xFB6680 (385 bytes)
;
; Called from: 3 site(s) outside this module:
;          0xFAFF67 in MidiCtrl_Dispatch__FAFF63, 0xFB020C in Dev10C_QuiesceListedChans_0800_0840__FB0208
;          0xFB02B7 in sub_FB029E__FB02B2
;          2 site(s) inside this module:
;          0xFB6C0C 0xFB6D71
; Inputs:  frame `link XIZ,-4`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Calls:   0xFA267A = Rec8644_Store3Bytes_AndFlagChanged, 0xFC589E = sub_FC589E
;          0xFC59EF = sub_FC59EF, 0xFC5EFB = sub_FC5EFB
;          0xFC6175 = sub_FC6175, 0xFC63EC = sub_FC63EC
;          0xFC654F = sub_FC654F, 0xFC65EC = sub_FC65EC
;          0xFC7E10 = sub_FC7E10
; Evidence: the listing below is the byte-identical round-trip of 0xFB6500-0xFB6680
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FB6500:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FB6500  link XIZ,0xfffc
	push	xhl                                   ; FB6504  push XHL
	pushw	de                                   ; FB6505  push DE
	push	xix                                   ; FB6506  push XIX
	ld	d, (xiz+8)                              ; FB6507  ld D,(XIZ+0x08)
	ld	c, d                                    ; FB650A  ld C,D
	extz	bc                                    ; FB650C  extz BC
	mul	bc, 0x12C                              ; FB650E  mul BC,0x012c
	ld	ix, bc                                  ; FB6512  ld IX,BC
	ldw	hl, 0x1523                             ; FB6514  ld HL,0x1523
	add	hl, bc                                 ; FB6517  add HL,BC
	extz	xhl                                   ; FB6519  extz XHL
	extpfx5 0xBB, 0x1D, 0x02, 0x00, 0x00       ; FB651B  ld (XHL+0x1d),0x0000
	pushw	0                                    ; FB6520  push 0x0000
	pushw	0                                    ; FB6523  push 0x0000
	push	0                                     ; FB6526  push 0x00
	push	d                                     ; FB6528  push D
	call	0xFC7E10                              ; FB652A  call 0xfc7e10
	extpfx5 0xBB, 0x1F, 0x02, 0x00, 0x00       ; FB652E  ld (XHL+0x1f),0x0000
	extpfx5 0xBB, 0x21, 0x02, 0x00, 0x00       ; FB6533  ld (XHL+0x21),0x0000
	extpfx5 0xBB, 0x23, 0x02, 0x00, 0x00       ; FB6538  ld (XHL+0x23),0x0000
	extpfx5 0xBB, 0x25, 0x02, 0x00, 0x00       ; FB653D  ld (XHL+0x25),0x0000
	extpfx5 0xBB, 0x27, 0x02, 0x00, 0x00       ; FB6542  ld (XHL+0x27),0x0000
	extpfx5 0xBB, 0x29, 0x02, 0x00, 0x00       ; FB6547  ld (XHL+0x29),0x0000
	extpfx5 0xBB, 0x2B, 0x02, 0x00, 0x00       ; FB654C  ld (XHL+0x2b),0x0000
	extpfx5 0xBB, 0x2D, 0x02, 0x00, 0x00       ; FB6551  ld (XHL+0x2d),0x0000
	extpfx5 0xBB, 0x2F, 0x02, 0x00, 0x00       ; FB6556  ld (XHL+0x2f),0x0000
	extpfx5 0xBB, 0x31, 0x02, 0x00, 0x00       ; FB655B  ld (XHL+0x31),0x0000
	extpfx5 0xBB, 0x33, 0x02, 0x00, 0x00       ; FB6560  ld (XHL+0x33),0x0000
	pushw	0                                    ; FB6565  push 0x0000
	pushw	0                                    ; FB6568  push 0x0000
	pushw	0                                    ; FB656B  push 0x0000
	pushw	0                                    ; FB656E  push 0x0000
	call	0xFA267A                              ; FB6571  call 0xfa267a
	pushw	0                                    ; FB6575  push 0x0000
	pushw	0                                    ; FB6578  push 0x0000
	pushw	0                                    ; FB657B  push 0x0000
	pushw	1                                    ; FB657E  push 0x0001
	call	0xFA267A                              ; FB6581  call 0xfa267a
	pushw	0                                    ; FB6585  push 0x0000
	pushw	0                                    ; FB6588  push 0x0000
	pushw	0                                    ; FB658B  push 0x0000
	pushw	2                                    ; FB658E  push 0x0002
	call	0xFA267A                              ; FB6591  call 0xfa267a
	pushw	0                                    ; FB6595  push 0x0000
	pushw	0                                    ; FB6598  push 0x0000
	push	0                                     ; FB659B  push 0x00
	push	d                                     ; FB659D  push D
	call	0xFC589E                              ; FB659F  call 0xfc589e
	pushw	0                                    ; FB65A3  push 0x0000
	pushw	0                                    ; FB65A6  push 0x0000
	push	0                                     ; FB65A9  push 0x00
	push	d                                     ; FB65AB  push D
	call	0xFC59EF                              ; FB65AD  call 0xfc59ef
	pushw	0                                    ; FB65B1  push 0x0000
	pushw	0                                    ; FB65B4  push 0x0000
	push	0                                     ; FB65B7  push 0x00
	push	d                                     ; FB65B9  push D
	call	0xFC5EFB                              ; FB65BB  call 0xfc5efb
	pushw	0                                    ; FB65BF  push 0x0000
	pushw	0                                    ; FB65C2  push 0x0000
	push	0                                     ; FB65C5  push 0x00
	push	d                                     ; FB65C7  push D
	call	0xFC6175                              ; FB65C9  call 0xfc6175
	pushw	0                                    ; FB65CD  push 0x0000
	pushw	0                                    ; FB65D0  push 0x0000
	push	0                                     ; FB65D3  push 0x00
	push	d                                     ; FB65D5  push D
	call	0xFC63EC                              ; FB65D7  call 0xfc63ec
	pushw	0                                    ; FB65DB  push 0x0000
	pushw	0                                    ; FB65DE  push 0x0000
	push	0                                     ; FB65E1  push 0x00
	push	d                                     ; FB65E3  push D
	call	0xFC654F                              ; FB65E5  call 0xfc654f
	pushw	0                                    ; FB65E9  push 0x0000
	pushw	0                                    ; FB65EC  push 0x0000
	push	0                                     ; FB65EF  push 0x00
	push	d                                     ; FB65F1  push D
	call	0xFC65EC                              ; FB65F3  call 0xfc65ec
	ld	xix, 0                                  ; FB65F7  ld XIX,0x00000000
	ld	(xiz-1), 4                              ; FB65FC  ld (XIZ+0xff),0x04
	add	xsp, 72                                ; FB6600  add XSP,0x00000048
sub_FB6500__FB6606:
	ldw	de, 0                                  ; FB6606  ld DE,0x0000
sub_FB6500__FB6609:
	ld	bc, ix                                  ; FB6609  ld BC,IX
	add	bc, de                                 ; FB660B  add BC,DE
	ld	(xiz-4), bc                             ; FB660D  ld (XIZ+0xfc),BC
	add	bc, 55                                 ; FB6610  add BC,0x0037
	extz	xbc                                   ; FB6614  extz XBC
	add	bc, hl                                 ; FB6616  add BC,HL
	ld	(xbc), 0                                ; FB6618  ld (XBC),0x00
	ld	bc, (xiz-4)                             ; FB661B  ld BC,(XIZ+0xfc)
	add	bc, 56                                 ; FB661E  add BC,0x0038
	extz	xbc                                   ; FB6622  extz XBC
	add	bc, hl                                 ; FB6624  add BC,HL
	ld	(xbc), 0                                ; FB6626  ld (XBC),0x00
	add	de, 16                                 ; FB6629  add DE,0x0010
	cp	de, 48                                  ; FB662D  cp DE,0x0030
	jr c, sub_FB6500__FB6609                   ; FB6631  jr C,0xfb6609
	inc	4, xix                                 ; FB6633  inc 4,XIX
	decm8	1, (xiz-1)                           ; FB6635  dec 1,(XIZ+0xff)
	cp (xiz-1), 0x00                           ; FB6638  cp (XIZ+0xff),0x00
	jr nz, sub_FB6500__FB6606                  ; FB663C  jr NZ,0xfb6606
	ld	bc, (xiz+8)                             ; FB663E  ld BC,(XIZ+0x08)
	extz	bc                                    ; FB6641  extz BC
	mul	bc, 0x12C                              ; FB6643  mul BC,0x012c
	ld	de, bc                                  ; FB6647  ld DE,BC
	ldw (xiz-2), 0x0000                        ; FB6649  ld (XIZ+0xfe),0x0000
sub_FB6500__FB664E:
	ldw	hl, 0                                  ; FB664E  ld HL,0x0000
	ld	ix, de                                  ; FB6651  ld IX,DE
	add	ix, 0x76                               ; FB6653  add IX,0x0076
sub_FB6500__FB6657:
	ld	(xiz-4), ix                             ; FB6657  ld (XIZ+0xfc),IX
	ld	bc, (xiz-4)                             ; FB665A  ld BC,(XIZ+0xfc)
	extz	xbc                                   ; FB665D  extz XBC
	ld	(xbc+0x1523), 64                        ; FB665F  ld (XBC+0x1523),0x40
	ld	ix, bc                                  ; FB6665  ld IX,BC
	inc	1, ix                                  ; FB6667  inc 1,IX
	inc	1, hl                                  ; FB6669  inc 1,HL
	cps	hl, 2                                  ; FB666B  cp HL,2
	jr c, sub_FB6500__FB6657                   ; FB666D  jr C,0xfb6657
	incw	2, (xiz-2)                            ; FB666F  incw 2,(XIZ+0xfe)
	inc	2, de                                  ; FB6672  inc 2,DE
	cpw (xiz-2), 0x000C                        ; FB6674  cp (XIZ+0xfe),0x000c
	jr c, sub_FB6500__FB664E                   ; FB6679  jr C,0xfb664e
	pop	xix                                    ; FB667B  pop XIX
	popw	de                                    ; FB667C  pop DE
	pop	xhl                                    ; FB667D  pop XHL
	unlk32 xiz                                 ; FB667E  unlk XIZ
	ret                                        ; FB6680  ret
; --------------------------------------------------------------------------
; sub_FB6681 -- 0xFB6681..0xFB68DC (604 bytes)
;
; Called from: 4 site(s) outside this module:
;          0xFB030D in sub_FB029E__FB0308, 0xFB872D in sub_FB86BB__FB8728
;          0xFB8F23 in sub_FB8CEC__FB8F1E, 0xFB9B09 in sub_FB9AC2
;          1 site(s) inside this module:
;          0xFB6CB7
; Inputs:  frame `link XIZ,-16`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Calls:   0xFB4A9F = sub_FB4A9F, 0xFB4D45 = sub_FB4D45
;          0xFB53C5 = sub_FB53C5, 0xFB5636 = sub_FB5636
;          0xFB639A = sub_FB639A, 0xFB6487 = sub_FB6487
;          0xFC6803 = sub_FC6803, 0xFC7481 = sub_FC7481
;          0xFC81F8 = sub_FC81F8
; Evidence: the listing below is the byte-identical round-trip of 0xFB6681-0xFB68DC
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FB6681:
	link32 0xEE, 0x0C, 0xF0, 0xFF              ; FB6681  link XIZ,0xfff0
	push	xhl                                   ; FB6685  push XHL
	pushw	de                                   ; FB6686  push DE
	push	xix                                   ; FB6687  push XIX
	pushw	0                                    ; FB6688  push 0x0000
	push	0                                     ; FB668B  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FB668D  push (XIZ+0x08)
	calr (0xFB5636 - 0xFB6693)                 ; FB6690  calr 0xfb5636
	push	0                                     ; FB6693  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FB6695  push (XIZ+0x08)
	calr (0xFB6487 - 0xFB669B)                 ; FB6698  calr 0xfb6487
	push	0                                     ; FB669B  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FB669D  push (XIZ+0x08)
	calr (0xFB4A9F - 0xFB66A3)                 ; FB66A0  calr 0xfb4a9f
	push	0                                     ; FB66A3  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FB66A5  push (XIZ+0x08)
	calr (0xFB4D45 - 0xFB66AB)                 ; FB66A8  calr 0xfb4d45
	ld	bc, (xiz+8)                             ; FB66AB  ld BC,(XIZ+0x08)
	extz	bc                                    ; FB66AE  extz BC
	mul	bc, 0x12C                              ; FB66B0  mul BC,0x012c
	ld	xix, xbc                                ; FB66B4  ld XIX,XBC
	ld	(xiz-12), bc                            ; FB66B6  ld (XIZ+0xf4),BC
	ld	(xiz-14), bc                            ; FB66B9  ld (XIZ+0xf2),BC
	ld	(xiz-9), 0                              ; FB66BC  ld (XIZ+0xf7),0x00
	inc	8, xsp                                 ; FB66C0  inc 0,XSP
	inc	2, xsp                                 ; FB66C2  inc 2,XSP
sub_FB6681__FB66C4:
	ld	c, (xiz-9)                              ; FB66C4  ld C,(XIZ+0xf7)
	ld	(xiz-4), c                              ; FB66C7  ld (XIZ+0xfc),C
	ldb	c, 16                                  ; FB66CA  ld C,0x10
	extpfx3 0x8E, 0xF7, 0x43                   ; FB66CC  mul BC,(XIZ+0xf7)
	extpfx3 0x9E, 0xF4, 0x81                   ; FB66CF  add BC,(XIZ+0xf4)
	ld	(xiz-8), bc                             ; FB66D2  ld (XIZ+0xf8),BC
	ld	(xiz-5), 0                              ; FB66D5  ld (XIZ+0xfb),0x00
sub_FB6681__FB66D9:
	ld	c, (xiz-5)                              ; FB66D9  ld C,(XIZ+0xfb)
	ld	(xiz-6), c                              ; FB66DC  ld (XIZ+0xfa),C
	mul	c, 4                                   ; FB66DF  mul C,0x04
	extpfx3 0x9E, 0xF8, 0x81                   ; FB66E2  add BC,(XIZ+0xf8)
	ld	de, bc                                  ; FB66E5  ld DE,BC
	add	de, 53                                 ; FB66E7  add DE,0x0035
	ldw	hl, 0x1523                             ; FB66EB  ld HL,0x1523
	ld	bc, de                                  ; FB66EE  ld BC,DE
	add	hl, bc                                 ; FB66F0  add HL,BC
	extz	xhl                                   ; FB66F2  extz XHL
	extpfx3 0x83, 0x3C, 0xF3                   ; FB66F4  and (XHL),0xf3
	ld	c, (xhl+2)                              ; FB66F7  ld C,(XHL+0x02)
	cps	c, 0                                   ; FB66FA  cp C,0
	jr z, sub_FB6681__FB670F                   ; FB66FC  jr Z,0xfb670f
	extz	xhl                                   ; FB66FE  extz XHL
	ld	c, (xhl+1)                              ; FB6700  ld C,(XHL+0x01)
	and	c, 85                                  ; FB6703  and C,0x55
	jr z, sub_FB6681__FB670F                   ; FB6706  jr Z,0xfb670f
	extz	xhl                                   ; FB6708  extz XHL
	extpfx3 0x83, 0x3E, 0x08                   ; FB670A  or (XHL),0x08
	jr sub_FB6681__FB6751                      ; FB670D  jr T,0xfb6751
sub_FB6681__FB670F:
	ldw	de, 0                                  ; FB670F  ld DE,0x0000
	ld	(xiz-2), 4                              ; FB6712  ld (XIZ+0xfe),0x04
sub_FB6681__FB6716:
	ld	bc, (xiz-14)                            ; FB6716  ld BC,(XIZ+0xf2)
	add	bc, de                                 ; FB6719  add BC,DE
	add	bc, 0x88                               ; FB671B  add BC,0x0088
	extz	xbc                                   ; FB671F  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB6721  ld XWA,(XBC+0x1523)
	ld	c, (xwa+6)                              ; FB6726  ld C,(XWA+0x06)
	ld	(xiz-1), c                              ; FB6729  ld (XIZ+0xff),C
	and	c, 32                                  ; FB672C  and C,0x20
	jr z, sub_FB6681__FB6744                   ; FB672F  jr Z,0xfb6744
	ld	c, (xiz-1)                              ; FB6731  ld C,(XIZ+0xff)
	and	c, 0xC0                                ; FB6734  and C,0xc0
	srl	c, 6                                   ; FB6737  srl 0x06,C
	extpfx3 0x8E, 0xFA, 0xF3                   ; FB673A  cp C,(XIZ+0xfa)
	jr nz, sub_FB6681__FB6744                  ; FB673D  jr NZ,0xfb6744
	extz	xhl                                   ; FB673F  extz XHL
	extpfx3 0x83, 0x3E, 0x04                   ; FB6741  or (XHL),0x04
sub_FB6681__FB6744:
	add	de, 41                                 ; FB6744  add DE,0x0029
	decm8	1, (xiz-2)                           ; FB6748  dec 1,(XIZ+0xfe)
	cp (xiz-2), 0x00                           ; FB674B  cp (XIZ+0xfe),0x00
	jr nz, sub_FB6681__FB6716                  ; FB674F  jr NZ,0xfb6716
sub_FB6681__FB6751:
	ld	c, (xiz-5)                              ; FB6751  ld C,(XIZ+0xfb)
	ld	(xiz-3), c                              ; FB6754  ld (XIZ+0xfd),C
	mul	c, 4                                   ; FB6757  mul C,0x04
	extpfx3 0x9E, 0xF8, 0x81                   ; FB675A  add BC,(XIZ+0xf8)
	ld	de, bc                                  ; FB675D  ld DE,BC
	add	de, 53                                 ; FB675F  add DE,0x0035
	ldw	hl, 0x1523                             ; FB6763  ld HL,0x1523
	ld	bc, de                                  ; FB6766  ld BC,DE
	add	hl, bc                                 ; FB6768  add HL,BC
	extz	xhl                                   ; FB676A  extz XHL
	extpfx3 0x83, 0x3C, 0xFC                   ; FB676C  and (XHL),0xfc
	ld	c, (xhl+3)                              ; FB676F  ld C,(XHL+0x03)
	cps	c, 0                                   ; FB6772  cp C,0
	jr z, sub_FB6681__FB6788                   ; FB6774  jr Z,0xfb6788
	extz	xhl                                   ; FB6776  extz XHL
	ld	c, (xhl+1)                              ; FB6778  ld C,(XHL+0x01)
	and	c, 85                                  ; FB677B  and C,0x55
	jr z, sub_FB6681__FB6788                   ; FB677E  jr Z,0xfb6788
	extz	xhl                                   ; FB6780  extz XHL
	extpfx3 0x83, 0x3E, 0x02                   ; FB6782  or (XHL),0x02
	jrl sub_FB6681__FB681A                     ; FB6785  jrl T,0xfb681a
sub_FB6681__FB6788:
	ldw	de, 0                                  ; FB6788  ld DE,0x0000
	ld	(xiz-1), 4                              ; FB678B  ld (XIZ+0xff),0x04
sub_FB6681__FB678F:
	ld	bc, (xiz-4)                             ; FB678F  ld BC,(XIZ+0xfc)
	extz	bc                                    ; FB6792  extz BC
	cps	bc, 0                                  ; FB6794  cp BC,0
	jr z, sub_FB6681__FB67A2                   ; FB6796  jr Z,0xfb67a2
	cps	bc, 1                                  ; FB6798  cp BC,1
	jr z, sub_FB6681__FB67BD                   ; FB679A  jr Z,0xfb67bd
	cps	bc, 2                                  ; FB679C  cp BC,2
	jr z, sub_FB6681__FB67D8                   ; FB679E  jr Z,0xfb67d8
	jr sub_FB6681__FB67F1                      ; FB67A0  jr T,0xfb67f1
sub_FB6681__FB67A2:
	ld	(xiz-16), de                            ; FB67A2  ld (XIZ+0xf0),DE
	ld	bc, ix                                  ; FB67A5  ld BC,IX
	extpfx3 0x9E, 0xF0, 0x81                   ; FB67A7  add BC,(XIZ+0xf0)
	add	bc, 0x88                               ; FB67AA  add BC,0x0088
	extz	xbc                                   ; FB67AE  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB67B0  ld XWA,(XBC+0x1523)
	ld	c, (xwa+6)                              ; FB67B5  ld C,(XWA+0x06)
	ld	(xiz-10), c                             ; FB67B8  ld (XIZ+0xf6),C
	jr sub_FB6681__FB67F1                      ; FB67BB  jr T,0xfb67f1
sub_FB6681__FB67BD:
	ld	(xiz-16), de                            ; FB67BD  ld (XIZ+0xf0),DE
	ld	bc, ix                                  ; FB67C0  ld BC,IX
	extpfx3 0x9E, 0xF0, 0x81                   ; FB67C2  add BC,(XIZ+0xf0)
	add	bc, 0x88                               ; FB67C5  add BC,0x0088
	extz	xbc                                   ; FB67C9  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB67CB  ld XWA,(XBC+0x1523)
	ld	c, (xwa+38)                             ; FB67D0  ld C,(XWA+0x26)
	ld	(xiz-10), c                             ; FB67D3  ld (XIZ+0xf6),C
	jr sub_FB6681__FB67F1                      ; FB67D6  jr T,0xfb67f1
sub_FB6681__FB67D8:
	ld	(xiz-16), de                            ; FB67D8  ld (XIZ+0xf0),DE
	ld	bc, ix                                  ; FB67DB  ld BC,IX
	extpfx3 0x9E, 0xF0, 0x81                   ; FB67DD  add BC,(XIZ+0xf0)
	add	bc, 0x88                               ; FB67E0  add BC,0x0088
	extz	xbc                                   ; FB67E4  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB67E6  ld XWA,(XBC+0x1523)
	ld	c, (xwa+56)                             ; FB67EB  ld C,(XWA+0x38)
	ld	(xiz-10), c                             ; FB67EE  ld (XIZ+0xf6),C
sub_FB6681__FB67F1:
	ld	c, (xiz-10)                             ; FB67F1  ld C,(XIZ+0xf6)
	and	c, 32                                  ; FB67F4  and C,0x20
	jr z, sub_FB6681__FB680C                   ; FB67F7  jr Z,0xfb680c
	ld	c, (xiz-10)                             ; FB67F9  ld C,(XIZ+0xf6)
	and	c, 0xC0                                ; FB67FC  and C,0xc0
	srl	c, 6                                   ; FB67FF  srl 0x06,C
	extpfx3 0x8E, 0xFD, 0xF3                   ; FB6802  cp C,(XIZ+0xfd)
	jr nz, sub_FB6681__FB680C                  ; FB6805  jr NZ,0xfb680c
	extz	xhl                                   ; FB6807  extz XHL
	extpfx3 0x83, 0x3E, 0x01                   ; FB6809  or (XHL),0x01
sub_FB6681__FB680C:
	add	de, 41                                 ; FB680C  add DE,0x0029
	decm8	1, (xiz-1)                           ; FB6810  dec 1,(XIZ+0xff)
	cp (xiz-1), 0x00                           ; FB6813  cp (XIZ+0xff),0x00
	jrl nz, sub_FB6681__FB678F                 ; FB6817  jrl NZ,0xfb678f
sub_FB6681__FB681A:
	incm8	1, (xiz-5)                           ; FB681A  inc 1,(XIZ+0xfb)
	cp (xiz-5), 0x04                           ; FB681D  cp (XIZ+0xfb),0x04
	jrl c, sub_FB6681__FB66D9                  ; FB6821  jrl C,0xfb66d9
	ldb	h, 0                                   ; FB6824  ld H,0x00
sub_FB6681__FB6826:
	push	0                                     ; FB6826  push 0x00
	extpfx3 0x8E, 0xF7, 0x04                   ; FB6828  push (XIZ+0xf7)
	ld	l, h                                    ; FB682B  ld L,H
	pushw	hl                                   ; FB682D  push HL
	push	0                                     ; FB682E  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FB6830  push (XIZ+0x08)
	calr (0xFB53C5 - 0xFB6836)                 ; FB6833  calr 0xfb53c5
	ld	h, l                                    ; FB6836  ld H,L
	inc	1, h                                   ; FB6838  inc 1,H
	inc	6, xsp                                 ; FB683A  inc 6,XSP
	cps	h, 4                                   ; FB683C  cp H,4
	jr c, sub_FB6681__FB6826                   ; FB683E  jr C,0xfb6826
	incm8	1, (xiz-9)                           ; FB6840  inc 1,(XIZ+0xf7)
	cp (xiz-9), 0x03                           ; FB6843  cp (XIZ+0xf7),0x03
	jrl c, sub_FB6681__FB66C4                  ; FB6847  jrl C,0xfb66c4
	push	0                                     ; FB684A  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FB684C  push (XIZ+0x08)
	calr (0xFB639A - 0xFB6852)                 ; FB684F  calr 0xfb639a
	ldw	de, 0                                  ; FB6852  ld DE,0x0000
	ld	bc, (xiz+8)                             ; FB6855  ld BC,(XIZ+0x08)
	extz	bc                                    ; FB6858  extz BC
	mul	bc, 0x12C                              ; FB685A  mul BC,0x012c
	ld	(xiz-4), bc                             ; FB685E  ld (XIZ+0xfc),BC
	inc	6, bc                                  ; FB6861  inc 6,BC
	ld	(xiz-2), bc                             ; FB6863  ld (XIZ+0xfe),BC
	ld	xix, 0                                  ; FB6866  ld XIX,0x00000000
	ldw	hl, 0                                  ; FB686B  ld HL,0x0000
	popw	bc                                    ; FB686E  pop BC
sub_FB6681__FB686F:
	ld	bc, (xiz-2)                             ; FB686F  ld BC,(XIZ+0xfe)
	extz	xbc                                   ; FB6872  extz XBC
	ld	wa, (xbc+0x1523)                        ; FB6874  ld WA,(XBC+0x1523)
	ld	(xiz-16), wa                            ; FB6879  ld (XIZ+0xf0),WA
	lda	xiy, (0xFDE695:24)                     ; FB687C  lda XIY,0xfde695
	add	xiy, xix                               ; FB6881  add XIY,XIX
	ld	bc, (xiy)                               ; FB6883  ld BC,(XIY)
	and	wa, bc                                 ; FB6885  and WA,BC
	jr z, sub_FB6681__FB688E                   ; FB6887  jr Z,0xfb688e
	pushw	1                                    ; FB6889  push 0x0001
	jr sub_FB6681__FB6891                      ; FB688C  jr T,0xfb6891
sub_FB6681__FB688E:
	pushw	0                                    ; FB688E  push 0x0000
sub_FB6681__FB6891:
	ld	bc, (xiz-4)                             ; FB6891  ld BC,(XIZ+0xfc)
	add	bc, hl                                 ; FB6894  add BC,HL
	add	bc, 0x8C                               ; FB6896  add BC,0x008c
	extz	xbc                                   ; FB689A  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB689C  ld XWA,(XBC+0x1523)
	push	xwa                                   ; FB68A1  push XWA
	ld	c, e                                    ; FB68A2  ld C,E
	pushw	bc                                   ; FB68A4  push BC
	push	0                                     ; FB68A5  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FB68A7  push (XIZ+0x08)
	call	0xFC6803                              ; FB68AA  call 0xfc6803
	inc	2, xix                                 ; FB68AE  inc 2,XIX
	add	hl, 41                                 ; FB68B0  add HL,0x0029
	inc	1, de                                  ; FB68B4  inc 1,DE
	inc	8, xsp                                 ; FB68B6  inc 0,XSP
	inc	2, xsp                                 ; FB68B8  inc 2,XSP
	cp	hl, 0xA4                                ; FB68BA  cp HL,0x00a4
	jr c, sub_FB6681__FB686F                   ; FB68BE  jr C,0xfb686f
	pushw	1                                    ; FB68C0  push 0x0001
	push	0                                     ; FB68C3  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FB68C5  push (XIZ+0x08)
	call	0xFC7481                              ; FB68C8  call 0xfc7481
	push	0                                     ; FB68CC  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FB68CE  push (XIZ+0x08)
	call	0xFC81F8                              ; FB68D1  call 0xfc81f8
	inc	6, xsp                                 ; FB68D5  inc 6,XSP
	pop	xix                                    ; FB68D7  pop XIX
	popw	de                                    ; FB68D8  pop DE
	pop	xhl                                    ; FB68D9  pop XHL
	unlk32 xiz                                 ; FB68DA  unlk XIZ
	ret                                        ; FB68DC  ret
; --------------------------------------------------------------------------
; sub_FB68DD -- 0xFB68DD..0xFB6B59 (637 bytes)
;
; Called from: 3 site(s) outside this module:
;          0xFB0318 in sub_FB029E__FB0313, 0xFB8739 in sub_FB86BB__FB8734
;          0xFB8FDC in sub_FB8CEC__FB8FD7
;          1 site(s) inside this module:
;          0xFB6CCB
; Inputs:  frame `link XIZ,-23`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Calls:   0xFB4D45 = sub_FB4D45, 0xFB53C5 = sub_FB53C5
;          0xFB5636 = sub_FB5636, 0xFB639A = sub_FB639A
;          0xFB6487 = sub_FB6487, 0xFC2CD5 = sub_FC2CD5
;          0xFC6803 = sub_FC6803, 0xFC7481 = sub_FC7481
;          0xFC81F8 = sub_FC81F8
; Evidence: the listing below is the byte-identical round-trip of 0xFB68DD-0xFB6B59
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FB68DD:
	link32 0xEE, 0x0C, 0xE9, 0xFF              ; FB68DD  link XIZ,0xffe9
	push	xhl                                   ; FB68E1  push XHL
	pushw	de                                   ; FB68E2  push DE
	push	xix                                   ; FB68E3  push XIX
	pushw	0                                    ; FB68E4  push 0x0000
	push	0                                     ; FB68E7  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FB68E9  push (XIZ+0x08)
	calr (0xFB5636 - 0xFB68EF)                 ; FB68EC  calr 0xfb5636
	push	0                                     ; FB68EF  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FB68F1  push (XIZ+0x08)
	calr (0xFB6487 - 0xFB68F7)                 ; FB68F4  calr 0xfb6487
	push	0                                     ; FB68F7  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FB68F9  push (XIZ+0x08)
	call	0xFC2CD5                              ; FB68FC  call 0xfc2cd5
	push	0                                     ; FB6900  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FB6902  push (XIZ+0x08)
	calr (0xFB4D45 - 0xFB6908)                 ; FB6905  calr 0xfb4d45
	ld	(xiz-21), 0                             ; FB6908  ld (XIZ+0xeb),0x00
	ld	bc, (xiz+8)                             ; FB690C  ld BC,(XIZ+0x08)
	extz	bc                                    ; FB690F  extz BC
	mul	bc, 0x12C                              ; FB6911  mul BC,0x012c
	ld	xix, xbc                                ; FB6915  ld XIX,XBC
	ld	(xiz-18), bc                            ; FB6917  ld (XIZ+0xee),BC
	ld	(xiz-20), bc                            ; FB691A  ld (XIZ+0xec),BC
	ldw (xiz-16), 0x0000                       ; FB691D  ld (XIZ+0xf0),0x0000
	inc	8, xsp                                 ; FB6922  inc 0,XSP
	inc	2, xsp                                 ; FB6924  inc 2,XSP
sub_FB68DD__FB6926:
	ld	(xiz-13), 0                             ; FB6926  ld (XIZ+0xf3),0x00
	ld	c, (xiz-21)                             ; FB692A  ld C,(XIZ+0xeb)
	ld	(xiz-5), c                              ; FB692D  ld (XIZ+0xfb),C
	ldb	c, 16                                  ; FB6930  ld C,0x10
	extpfx3 0x8E, 0xEB, 0x43                   ; FB6932  mul BC,(XIZ+0xeb)
	ld	hl, bc                                  ; FB6935  ld HL,BC
	ld	de, (xiz-16)                            ; FB6937  ld DE,(XIZ+0xf0)
	ld	(xiz-23), bc                            ; FB693A  ld (XIZ+0xe9),BC
	ld	wa, (xiz-18)                            ; FB693D  ld WA,(XIZ+0xee)
	add	wa, de                                 ; FB6940  add WA,DE
	ld	(xiz-12), wa                            ; FB6942  ld (XIZ+0xf4),WA
	extpfx3 0x9E, 0xEE, 0x81                   ; FB6945  add BC,(XIZ+0xee)
	ld	(xiz-10), bc                            ; FB6948  ld (XIZ+0xf6),BC
	ldw (xiz-8), 0x0000                        ; FB694B  ld (XIZ+0xf8),0x0000
sub_FB68DD__FB6950:
	ld	c, (xiz-13)                             ; FB6950  ld C,(XIZ+0xf3)
	ld	(xiz-3), c                              ; FB6953  ld (XIZ+0xfd),C
	ld	bc, (xiz-12)                            ; FB6956  ld BC,(XIZ+0xf4)
	extpfx3 0x9E, 0xF8, 0x81                   ; FB6959  add BC,(XIZ+0xf8)
	ld	de, bc                                  ; FB695C  ld DE,BC
	add	de, 53                                 ; FB695E  add DE,0x0035
	ldw	hl, 0x1523                             ; FB6962  ld HL,0x1523
	ld	bc, de                                  ; FB6965  ld BC,DE
	add	hl, bc                                 ; FB6967  add HL,BC
	extz	xhl                                   ; FB6969  extz XHL
	extpfx3 0x83, 0x3C, 0xF3                   ; FB696B  and (XHL),0xf3
	ld	c, (xhl+2)                              ; FB696E  ld C,(XHL+0x02)
	cps	c, 0                                   ; FB6971  cp C,0
	jr z, sub_FB68DD__FB6986                   ; FB6973  jr Z,0xfb6986
	extz	xhl                                   ; FB6975  extz XHL
	ld	c, (xhl+1)                              ; FB6977  ld C,(XHL+0x01)
	and	c, 85                                  ; FB697A  and C,0x55
	jr z, sub_FB68DD__FB6986                   ; FB697D  jr Z,0xfb6986
	extz	xhl                                   ; FB697F  extz XHL
	extpfx3 0x83, 0x3E, 0x08                   ; FB6981  or (XHL),0x08
	jr sub_FB68DD__FB69C8                      ; FB6984  jr T,0xfb69c8
sub_FB68DD__FB6986:
	ldw	de, 0                                  ; FB6986  ld DE,0x0000
	ld	(xiz-1), 4                              ; FB6989  ld (XIZ+0xff),0x04
sub_FB68DD__FB698D:
	ld	bc, (xiz-20)                            ; FB698D  ld BC,(XIZ+0xec)
	add	bc, de                                 ; FB6990  add BC,DE
	add	bc, 0x88                               ; FB6992  add BC,0x0088
	extz	xbc                                   ; FB6996  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB6998  ld XWA,(XBC+0x1523)
	ld	c, (xwa+6)                              ; FB699D  ld C,(XWA+0x06)
	ld	(xiz-2), c                              ; FB69A0  ld (XIZ+0xfe),C
	and	c, 32                                  ; FB69A3  and C,0x20
	jr z, sub_FB68DD__FB69BB                   ; FB69A6  jr Z,0xfb69bb
	ld	c, (xiz-2)                              ; FB69A8  ld C,(XIZ+0xfe)
	and	c, 0xC0                                ; FB69AB  and C,0xc0
	srl	c, 6                                   ; FB69AE  srl 0x06,C
	extpfx3 0x8E, 0xFD, 0xF3                   ; FB69B1  cp C,(XIZ+0xfd)
	jr nz, sub_FB68DD__FB69BB                  ; FB69B4  jr NZ,0xfb69bb
	extz	xhl                                   ; FB69B6  extz XHL
	extpfx3 0x83, 0x3E, 0x04                   ; FB69B8  or (XHL),0x04
sub_FB68DD__FB69BB:
	add	de, 41                                 ; FB69BB  add DE,0x0029
	decm8	1, (xiz-1)                           ; FB69BF  dec 1,(XIZ+0xff)
	cp (xiz-1), 0x00                           ; FB69C2  cp (XIZ+0xff),0x00
	jr nz, sub_FB68DD__FB698D                  ; FB69C6  jr NZ,0xfb698d
sub_FB68DD__FB69C8:
	ld	c, (xiz-13)                             ; FB69C8  ld C,(XIZ+0xf3)
	ld	(xiz-4), c                              ; FB69CB  ld (XIZ+0xfc),C
	mul	c, 4                                   ; FB69CE  mul C,0x04
	extpfx3 0x9E, 0xF6, 0x81                   ; FB69D1  add BC,(XIZ+0xf6)
	ld	de, bc                                  ; FB69D4  ld DE,BC
	add	de, 53                                 ; FB69D6  add DE,0x0035
	ldw	hl, 0x1523                             ; FB69DA  ld HL,0x1523
	ld	bc, de                                  ; FB69DD  ld BC,DE
	add	hl, bc                                 ; FB69DF  add HL,BC
	extz	xhl                                   ; FB69E1  extz XHL
	extpfx3 0x83, 0x3C, 0xFC                   ; FB69E3  and (XHL),0xfc
	ld	c, (xhl+3)                              ; FB69E6  ld C,(XHL+0x03)
	cps	c, 0                                   ; FB69E9  cp C,0
	jr z, sub_FB68DD__FB69FF                   ; FB69EB  jr Z,0xfb69ff
	extz	xhl                                   ; FB69ED  extz XHL
	ld	c, (xhl+1)                              ; FB69EF  ld C,(XHL+0x01)
	and	c, 85                                  ; FB69F2  and C,0x55
	jr z, sub_FB68DD__FB69FF                   ; FB69F5  jr Z,0xfb69ff
	extz	xhl                                   ; FB69F7  extz XHL
	extpfx3 0x83, 0x3E, 0x02                   ; FB69F9  or (XHL),0x02
	jrl sub_FB68DD__FB6A91                     ; FB69FC  jrl T,0xfb6a91
sub_FB68DD__FB69FF:
	ldw	de, 0                                  ; FB69FF  ld DE,0x0000
	ld	(xiz-1), 4                              ; FB6A02  ld (XIZ+0xff),0x04
sub_FB68DD__FB6A06:
	ld	bc, (xiz-5)                             ; FB6A06  ld BC,(XIZ+0xfb)
	extz	bc                                    ; FB6A09  extz BC
	cps	bc, 0                                  ; FB6A0B  cp BC,0
	jr z, sub_FB68DD__FB6A19                   ; FB6A0D  jr Z,0xfb6a19
	cps	bc, 1                                  ; FB6A0F  cp BC,1
	jr z, sub_FB68DD__FB6A34                   ; FB6A11  jr Z,0xfb6a34
	cps	bc, 2                                  ; FB6A13  cp BC,2
	jr z, sub_FB68DD__FB6A4F                   ; FB6A15  jr Z,0xfb6a4f
	jr sub_FB68DD__FB6A68                      ; FB6A17  jr T,0xfb6a68
sub_FB68DD__FB6A19:
	ld	(xiz-23), de                            ; FB6A19  ld (XIZ+0xe9),DE
	ld	bc, ix                                  ; FB6A1C  ld BC,IX
	extpfx3 0x9E, 0xE9, 0x81                   ; FB6A1E  add BC,(XIZ+0xe9)
	add	bc, 0x88                               ; FB6A21  add BC,0x0088
	extz	xbc                                   ; FB6A25  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB6A27  ld XWA,(XBC+0x1523)
	ld	c, (xwa+6)                              ; FB6A2C  ld C,(XWA+0x06)
	ld	(xiz-14), c                             ; FB6A2F  ld (XIZ+0xf2),C
	jr sub_FB68DD__FB6A68                      ; FB6A32  jr T,0xfb6a68
sub_FB68DD__FB6A34:
	ld	(xiz-23), de                            ; FB6A34  ld (XIZ+0xe9),DE
	ld	bc, ix                                  ; FB6A37  ld BC,IX
	extpfx3 0x9E, 0xE9, 0x81                   ; FB6A39  add BC,(XIZ+0xe9)
	add	bc, 0x88                               ; FB6A3C  add BC,0x0088
	extz	xbc                                   ; FB6A40  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB6A42  ld XWA,(XBC+0x1523)
	ld	c, (xwa+38)                             ; FB6A47  ld C,(XWA+0x26)
	ld	(xiz-14), c                             ; FB6A4A  ld (XIZ+0xf2),C
	jr sub_FB68DD__FB6A68                      ; FB6A4D  jr T,0xfb6a68
sub_FB68DD__FB6A4F:
	ld	(xiz-23), de                            ; FB6A4F  ld (XIZ+0xe9),DE
	ld	bc, ix                                  ; FB6A52  ld BC,IX
	extpfx3 0x9E, 0xE9, 0x81                   ; FB6A54  add BC,(XIZ+0xe9)
	add	bc, 0x88                               ; FB6A57  add BC,0x0088
	extz	xbc                                   ; FB6A5B  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB6A5D  ld XWA,(XBC+0x1523)
	ld	c, (xwa+56)                             ; FB6A62  ld C,(XWA+0x38)
	ld	(xiz-14), c                             ; FB6A65  ld (XIZ+0xf2),C
sub_FB68DD__FB6A68:
	ld	c, (xiz-14)                             ; FB6A68  ld C,(XIZ+0xf2)
	and	c, 32                                  ; FB6A6B  and C,0x20
	jr z, sub_FB68DD__FB6A83                   ; FB6A6E  jr Z,0xfb6a83
	ld	c, (xiz-14)                             ; FB6A70  ld C,(XIZ+0xf2)
	and	c, 0xC0                                ; FB6A73  and C,0xc0
	srl	c, 6                                   ; FB6A76  srl 0x06,C
	extpfx3 0x8E, 0xFC, 0xF3                   ; FB6A79  cp C,(XIZ+0xfc)
	jr nz, sub_FB68DD__FB6A83                  ; FB6A7C  jr NZ,0xfb6a83
	extz	xhl                                   ; FB6A7E  extz XHL
	extpfx3 0x83, 0x3E, 0x01                   ; FB6A80  or (XHL),0x01
sub_FB68DD__FB6A83:
	add	de, 41                                 ; FB6A83  add DE,0x0029
	decm8	1, (xiz-1)                           ; FB6A87  dec 1,(XIZ+0xff)
	cp (xiz-1), 0x00                           ; FB6A8A  cp (XIZ+0xff),0x00
	jrl nz, sub_FB68DD__FB6A06                 ; FB6A8E  jrl NZ,0xfb6a06
sub_FB68DD__FB6A91:
	incw	4, (xiz-8)                            ; FB6A91  incw 4,(XIZ+0xf8)
	incm8	1, (xiz-13)                          ; FB6A94  inc 1,(XIZ+0xf3)
	cp (xiz-13), 0x04                          ; FB6A97  cp (XIZ+0xf3),0x04
	jrl c, sub_FB68DD__FB6950                  ; FB6A9B  jrl C,0xfb6950
	ldb	h, 0                                   ; FB6A9E  ld H,0x00
sub_FB68DD__FB6AA0:
	push	0                                     ; FB6AA0  push 0x00
	extpfx3 0x8E, 0xEB, 0x04                   ; FB6AA2  push (XIZ+0xeb)
	push	0                                     ; FB6AA5  push 0x00
	push	h                                     ; FB6AA7  push H
	push	0                                     ; FB6AA9  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FB6AAB  push (XIZ+0x08)
	calr (0xFB53C5 - 0xFB6AB1)                 ; FB6AAE  calr 0xfb53c5
	inc	1, h                                   ; FB6AB1  inc 1,H
	inc	6, xsp                                 ; FB6AB3  inc 6,XSP
	cps	h, 4                                   ; FB6AB5  cp H,4
	jr c, sub_FB68DD__FB6AA0                   ; FB6AB7  jr C,0xfb6aa0
	extpfx5 0x9E, 0xF0, 0x38, 0x10, 0x00       ; FB6AB9  add (XIZ+0xf0),0x0010
	incm8	1, (xiz-21)                          ; FB6ABE  inc 1,(XIZ+0xeb)
	cp (xiz-21), 0x03                          ; FB6AC1  cp (XIZ+0xeb),0x03
	jrl c, sub_FB68DD__FB6926                  ; FB6AC5  jrl C,0xfb6926
	push	0                                     ; FB6AC8  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FB6ACA  push (XIZ+0x08)
	calr (0xFB639A - 0xFB6AD0)                 ; FB6ACD  calr 0xfb639a
	ldb	h, 0                                   ; FB6AD0  ld H,0x00
	ld	bc, (xiz+8)                             ; FB6AD2  ld BC,(XIZ+0x08)
	extz	bc                                    ; FB6AD5  extz BC
	mul	bc, 0x12C                              ; FB6AD7  mul BC,0x012c
	ld	(xiz-4), bc                             ; FB6ADB  ld (XIZ+0xfc),BC
	inc	6, bc                                  ; FB6ADE  inc 6,BC
	ld	(xiz-2), bc                             ; FB6AE0  ld (XIZ+0xfe),BC
	ldw	de, 0                                  ; FB6AE3  ld DE,0x0000
	ldw	ix, 0                                  ; FB6AE6  ld IX,0x0000
	popw	bc                                    ; FB6AE9  pop BC
sub_FB68DD__FB6AEA:
	ld	bc, (xiz-2)                             ; FB6AEA  ld BC,(XIZ+0xfe)
	extz	xbc                                   ; FB6AED  extz XBC
	ld	wa, (xbc+0x1523)                        ; FB6AEF  ld WA,(XBC+0x1523)
	ld	(xiz-23), wa                            ; FB6AF4  ld (XIZ+0xe9),WA
	ld	iy, de                                  ; FB6AF7  ld IY,DE
	extz	xiy                                   ; FB6AF9  extz XIY
	add	xiy, 0xFDE695                          ; FB6AFB  add XIY,0x00fde695
	ld	iy, (xiy)                               ; FB6B01  ld IY,(XIY)
	and	wa, iy                                 ; FB6B03  and WA,IY
	jr z, sub_FB68DD__FB6B0C                   ; FB6B05  jr Z,0xfb6b0c
	pushw	1                                    ; FB6B07  push 0x0001
	jr sub_FB68DD__FB6B0F                      ; FB6B0A  jr T,0xfb6b0f
sub_FB68DD__FB6B0C:
	pushw	0                                    ; FB6B0C  push 0x0000
sub_FB68DD__FB6B0F:
	ld	bc, (xiz-4)                             ; FB6B0F  ld BC,(XIZ+0xfc)
	add	bc, ix                                 ; FB6B12  add BC,IX
	add	bc, 0x8C                               ; FB6B14  add BC,0x008c
	extz	xbc                                   ; FB6B18  extz XBC
	ld	xwa, (xbc+0x1523)                       ; FB6B1A  ld XWA,(XBC+0x1523)
	push	xwa                                   ; FB6B1F  push XWA
	push	0                                     ; FB6B20  push 0x00
	push	h                                     ; FB6B22  push H
	push	0                                     ; FB6B24  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FB6B26  push (XIZ+0x08)
	call	0xFC6803                              ; FB6B29  call 0xfc6803
	inc	2, de                                  ; FB6B2D  inc 2,DE
	add	ix, 41                                 ; FB6B2F  add IX,0x0029
	inc	1, h                                   ; FB6B33  inc 1,H
	inc	8, xsp                                 ; FB6B35  inc 0,XSP
	inc	2, xsp                                 ; FB6B37  inc 2,XSP
	cps	h, 4                                   ; FB6B39  cp H,4
	jr c, sub_FB68DD__FB6AEA                   ; FB6B3B  jr C,0xfb6aea
	pushw	1                                    ; FB6B3D  push 0x0001
	push	0                                     ; FB6B40  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FB6B42  push (XIZ+0x08)
	call	0xFC7481                              ; FB6B45  call 0xfc7481
	push	0                                     ; FB6B49  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FB6B4B  push (XIZ+0x08)
	call	0xFC81F8                              ; FB6B4E  call 0xfc81f8
	inc	6, xsp                                 ; FB6B52  inc 6,XSP
	pop	xix                                    ; FB6B54  pop XIX
	popw	de                                    ; FB6B55  pop DE
	pop	xhl                                    ; FB6B56  pop XHL
	unlk32 xiz                                 ; FB6B57  unlk XIZ
	ret                                        ; FB6B59  ret
; --------------------------------------------------------------------------
; sub_FB6B5A -- 0xFB6B5A..0xFB6BA7 (78 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFB6BEC
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
;          reads 0x00D80D
; Evidence: the listing below is the byte-identical round-trip of 0xFB6B5A-0xFB6BA7
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FB6B5A:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB6B5A  link XIZ,0x0000
	push	xix                                   ; FB6B5E  push XIX
	cp (xiz+10), 0x10                          ; FB6B5F  cp (XIZ+0x0a),0x10
	jr nz, sub_FB6B5A__FB6BA1                  ; FB6B63  jr NZ,0xfb6ba1
	ldl_da	xbc, (0xD80D)                       ; FB6B65  ld XBC,(0x00d80d)
	or	xbc, xbc                                ; FB6B6A  or XBC,XBC
	jr z, sub_FB6B5A__FB6B9D                   ; FB6B6C  jr Z,0xfb6b9d
	ld	xix, 0xC00000                           ; FB6B6E  ld XIX,0x00c00000
	ld	c, (xix+49)                             ; FB6B73  ld C,(XIX+0x31)
	cp	(xiz+8), c                              ; FB6B76  cp (XIZ+0x08),C
	jr nc, sub_FB6B5A__FB6B9D                  ; FB6B79  jr NC,0xfb6b9d
	ld	c, (xix+24)                             ; FB6B7B  ld C,(XIX+0x18)
	extz	bc                                    ; FB6B7E  extz BC
	extz	xbc                                   ; FB6B80  extz XBC
	add	xbc, 0xC00000                          ; FB6B82  add XBC,0x00c00000
	ld	xix, xbc                                ; FB6B88  ld XIX,XBC
	ld	wa, (xiz+8)                             ; FB6B8A  ld WA,(XIZ+0x08)
	extz	wa                                    ; FB6B8D  extz WA
	extz	xwa                                   ; FB6B8F  extz XWA
	add	xbc, xwa                               ; FB6B91  add XBC,XWA
	ld	a, (xbc)                                ; FB6B93  ld A,(XBC)
	cps	a, 1                                   ; FB6B95  cp A,1
	jr nz, sub_FB6B5A__FB6BA1                  ; FB6B97  jr NZ,0xfb6ba1
	ldb	a, 48                                  ; FB6B99  ld A,0x30
	jr sub_FB6B5A__FB6BA4                      ; FB6B9B  jr T,0xfb6ba4
sub_FB6B5A__FB6B9D:
	sub	a, a                                   ; FB6B9D  sub A,A
	jr sub_FB6B5A__FB6BA4                      ; FB6B9F  jr T,0xfb6ba4
sub_FB6B5A__FB6BA1:
	ld	a, (xiz+10)                             ; FB6BA1  ld A,(XIZ+0x0a)
sub_FB6B5A__FB6BA4:
	pop	xix                                    ; FB6BA4  pop XIX
	unlk32 xiz                                 ; FB6BA5  unlk XIZ
	ret                                        ; FB6BA7  ret
; --------------------------------------------------------------------------
; sub_FB6BA8 -- 0xFB6BA8..0xFB6CED (326 bytes)
;
; Called from: 2 site(s) outside this module:
;          0xFB08D3 in MidiIn_ParseRingAndDispatch__FB086A, 0xFB0A37 in MidiMsg_SendBootSequence
; Inputs:  frame `link XIZ,-9`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Calls:   0xFACC3F = PartRec_Word0006_SetBit13, 0xFB47C4 = sub_FB47C4
;          0xFB64C8 = sub_FB64C8, 0xFB6500 = sub_FB6500
;          0xFB6681 = sub_FB6681, 0xFB68DD = sub_FB68DD
;          0xFB6B5A = sub_FB6B5A, 0xFC28B5 = sub_FC28B5
;          0xFC7A1F = sub_FC7A1F, 0xFC81F8 = sub_FC81F8
; Evidence: the listing below is the byte-identical round-trip of 0xFB6BA8-0xFB6CED
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FB6BA8:
	link32 0xEE, 0x0C, 0xF7, 0xFF              ; FB6BA8  link XIZ,0xfff7
	pushw	hl                                   ; FB6BAC  push HL
	pushw	de                                   ; FB6BAD  push DE
	push	xix                                   ; FB6BAE  push XIX
	lda	xix, (0x1523:16)                      ; FB6BAF  lda XIX,0x1523
	ld	xbc, (xiz+8)                            ; FB6BB3  ld XBC,(XIZ+0x08)
	ld	h, (xbc+1)                              ; FB6BB6  ld H,(XBC+0x01)
	cp	h, 33                                   ; FB6BB9  cp H,0x21
	jrl nc, sub_FB6BA8__FB6CE8                 ; FB6BBC  jrl NC,0xfb6ce8
	ld	(xiz-1), h                              ; FB6BBF  ld (XIZ+0xff),H
	ld	a, (xbc+2)                              ; FB6BC2  ld A,(XBC+0x02)
	ld	(xiz-3), a                              ; FB6BC5  ld (XIZ+0xfd),A
	ld	wa, (xiz-1)                             ; FB6BC8  ld WA,(XIZ+0xff)
	extz	wa                                    ; FB6BCB  extz WA
	mul	wa, 0x12C                              ; FB6BCD  mul WA,0x012c
	ld	(xiz-5), wa                             ; FB6BD1  ld (XIZ+0xfb),WA
	add	wa, 27                                 ; FB6BD4  add WA,0x001b
	extz	xwa                                   ; FB6BD8  extz XWA
	add	wa, ix                                 ; FB6BDA  add WA,IX
	ld	c, (xiz-3)                              ; FB6BDC  ld C,(XIZ+0xfd)
	ld	(xwa), c                                ; FB6BDF  ld (XWA),C
	ld	xbc, (xiz+8)                            ; FB6BE1  ld XBC,(XIZ+0x08)
	ld	a, (xbc+3)                              ; FB6BE4  ld A,(XBC+0x03)
	pushw	wa                                   ; FB6BE7  push WA
	ld	a, (xbc+2)                              ; FB6BE8  ld A,(XBC+0x02)
	pushw	wa                                   ; FB6BEB  push WA
	calr (0xFB6B5A - 0xFB6BEF)                 ; FB6BEC  calr 0xfb6b5a
	ld	(xiz-7), a                              ; FB6BEF  ld (XIZ+0xf9),A
	ld	bc, (xiz-5)                             ; FB6BF2  ld BC,(XIZ+0xfb)
	add	bc, 28                                 ; FB6BF5  add BC,0x001c
	extz	xbc                                   ; FB6BF9  extz XBC
	add	bc, ix                                 ; FB6BFB  add BC,IX
	ld	(xbc), a                                ; FB6BFD  ld (XBC),A
	push	0                                     ; FB6BFF  push 0x00
	extpfx3 0x8E, 0xFF, 0x04                   ; FB6C01  push (XIZ+0xff)
	calr (0xFB64C8 - 0xFB6C07)                 ; FB6C04  calr 0xfb64c8
	push	0                                     ; FB6C07  push 0x00
	extpfx3 0x8E, 0xFF, 0x04                   ; FB6C09  push (XIZ+0xff)
	calr (0xFB6500 - 0xFB6C0F)                 ; FB6C0C  calr 0xfb6500
	push	0                                     ; FB6C0F  push 0x00
	extpfx3 0x8E, 0xFF, 0x04                   ; FB6C11  push (XIZ+0xff)
	call	0xFACC3F                              ; FB6C14  call 0xfacc3f
	ld	xbc, (xiz+8)                            ; FB6C18  ld XBC,(XIZ+0x08)
	ld	a, (xbc+3)                              ; FB6C1B  ld A,(XBC+0x03)
	pushw	wa                                   ; FB6C1E  push WA
	ld	a, (xbc+2)                              ; FB6C1F  ld A,(XBC+0x02)
	pushw	wa                                   ; FB6C22  push WA
	push	0                                     ; FB6C23  push 0x00
	extpfx3 0x8E, 0xFF, 0x04                   ; FB6C25  push (XIZ+0xff)
	calr (0xFB47C4 - 0xFB6C2B)                 ; FB6C28  calr 0xfb47c4
	ld	bc, (xiz-5)                             ; FB6C2B  ld BC,(XIZ+0xfb)
	extz	xix                                   ; FB6C2E  extz XIX
	extpfx5 0xE3, 0x07, 0xF0, 0xE4, 0x20       ; FB6C30  ld XWA,(XIX+BC)
	ld	c, (xwa+0xD0)                           ; FB6C35  ld C,(XWA+0x00d0)
	and	c, 0x80                                ; FB6C3A  and C,0x80
	ld	(xiz-9), c                              ; FB6C3D  ld (XIZ+0xf7),C
	ld	hl, (xiz-5)                             ; FB6C40  ld HL,(XIZ+0xfb)
	add	hl, 9                                  ; FB6C43  add HL,0x0009
	extpfx5 0xD3, 0x07, 0xF0, 0xEC, 0x22       ; FB6C47  ld DE,(XIX+HL)
	inc	8, xsp                                 ; FB6C4C  inc 0,XSP
	inc	8, xsp                                 ; FB6C4E  inc 0,XSP
	cps	c, 0                                   ; FB6C50  cp C,0
	jr z, sub_FB6BA8__FB6C64                   ; FB6C52  jr Z,0xfb6c64
	ld	bc, de                                  ; FB6C54  ld BC,DE
	or	bc, 0x6000                              ; FB6C56  or BC,0x6000
	ld	wa, ix                                  ; FB6C5A  ld WA,IX
	extz	xwa                                   ; FB6C5C  extz XWA
	add	wa, hl                                 ; FB6C5E  add WA,HL
	ld	(xwa), bc                               ; FB6C60  ld (XWA),BC
	jr sub_FB6BA8__FB6C82                      ; FB6C62  jr T,0xfb6c82
sub_FB6BA8__FB6C64:
	ld	bc, de                                  ; FB6C64  ld BC,DE
	res	14, bc                                 ; FB6C66  res 0x0e,BC
	ld	(xiz-3), bc                             ; FB6C69  ld (XIZ+0xfd),BC
	ld	wa, ix                                  ; FB6C6C  ld WA,IX
	extz	xwa                                   ; FB6C6E  extz XWA
	add	wa, hl                                 ; FB6C70  add WA,HL
	ld	(xwa), bc                               ; FB6C72  ld (XWA),BC
	ld	bc, (xiz-3)                             ; FB6C74  ld BC,(XIZ+0xfd)
	set	13, bc                                 ; FB6C77  set 0x0d,BC
	ld	wa, ix                                  ; FB6C7A  ld WA,IX
	extz	xwa                                   ; FB6C7C  extz XWA
	add	wa, hl                                 ; FB6C7E  add WA,HL
	ld	(xwa), bc                               ; FB6C80  ld (XWA),BC
sub_FB6BA8__FB6C82:
	ld	bc, (xiz-1)                             ; FB6C82  ld BC,(XIZ+0xff)
	extz	bc                                    ; FB6C85  extz BC
	mul	bc, 0x12C                              ; FB6C87  mul BC,0x012c
	extz	xix                                   ; FB6C8B  extz XIX
	extpfx5 0xE3, 0x07, 0xF0, 0xE4, 0x20       ; FB6C8D  ld XWA,(XIX+BC)
	ld	c, (xwa+16)                             ; FB6C92  ld C,(XWA+0x10)
	and	c, 0xC0                                ; FB6C95  and C,0xc0
	extz	bc                                    ; FB6C98  extz BC
	cps	bc, 0                                  ; FB6C9A  cp BC,0
	jr z, sub_FB6BA8__FB6CB2                   ; FB6C9C  jr Z,0xfb6cb2
	cp	bc, 64                                  ; FB6C9E  cp BC,0x0040
	jr z, sub_FB6BA8__FB6CBD                   ; FB6CA2  jr Z,0xfb6cbd
	cp	bc, 0x80                                ; FB6CA4  cp BC,0x0080
	jr z, sub_FB6BA8__FB6CD1                   ; FB6CA8  jr Z,0xfb6cd1
	cp	bc, 0xC0                                ; FB6CAA  cp BC,0x00c0
	jr z, sub_FB6BA8__FB6CB2                   ; FB6CAE  jr Z,0xfb6cb2
	jr sub_FB6BA8__FB6CE8                      ; FB6CB0  jr T,0xfb6ce8
sub_FB6BA8__FB6CB2:
	push	0                                     ; FB6CB2  push 0x00
	extpfx3 0x8E, 0xFF, 0x04                   ; FB6CB4  push (XIZ+0xff)
	calr (0xFB6681 - 0xFB6CBA)                 ; FB6CB7  calr 0xfb6681
	popw	bc                                    ; FB6CBA  pop BC
	jr sub_FB6BA8__FB6CE8                      ; FB6CBB  jr T,0xfb6ce8
sub_FB6BA8__FB6CBD:
	push	0                                     ; FB6CBD  push 0x00
	extpfx3 0x8E, 0xFF, 0x04                   ; FB6CBF  push (XIZ+0xff)
	call	0xFC28B5                              ; FB6CC2  call 0xfc28b5
	push	0                                     ; FB6CC6  push 0x00
	extpfx3 0x8E, 0xFF, 0x04                   ; FB6CC8  push (XIZ+0xff)
	calr (0xFB68DD - 0xFB6CCE)                 ; FB6CCB  calr 0xfb68dd
	pop	xiy                                    ; FB6CCE  pop XIY
	jr sub_FB6BA8__FB6CE8                      ; FB6CCF  jr T,0xfb6ce8
sub_FB6BA8__FB6CD1:
	pushw	1                                    ; FB6CD1  push 0x0001
	push	0                                     ; FB6CD4  push 0x00
	extpfx3 0x8E, 0xFF, 0x04                   ; FB6CD6  push (XIZ+0xff)
	call	0xFC7A1F                              ; FB6CD9  call 0xfc7a1f
	push	0                                     ; FB6CDD  push 0x00
	extpfx3 0x8E, 0xFF, 0x04                   ; FB6CDF  push (XIZ+0xff)
	call	0xFC81F8                              ; FB6CE2  call 0xfc81f8
	inc	6, xsp                                 ; FB6CE6  inc 6,XSP
sub_FB6BA8__FB6CE8:
	pop	xix                                    ; FB6CE8  pop XIX
	popw	de                                    ; FB6CE9  pop DE
	popw	hl                                    ; FB6CEA  pop HL
	unlk32 xiz                                 ; FB6CEB  unlk XIZ
	ret                                        ; FB6CED  ret
; --------------------------------------------------------------------------
; sub_FB6CEE -- 0xFB6CEE..0xFB6E09 (284 bytes)
;
; Called from: 2 site(s) outside this module:
;          0xFADAA5 in sub_FADA7C__FADAA1, 0xFB05DC in ExtBoard_ProbeAndInstallBases__FB05CD
; Inputs:  frame `link XIZ,-17`; no positive frame slot is read
; Outputs: writes 0x001509, 0x00D733
; Calls:   0xFA78E8 = sub_FA78E8, 0xFB6500 = sub_FB6500
; Evidence: the listing below is the byte-identical round-trip of 0xFB6CEE-0xFB6E09
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FB6CEE:
	link32 0xEE, 0x0C, 0xEF, 0xFF              ; FB6CEE  link XIZ,0xffef
	pushw	hl                                   ; FB6CF2  push HL
	pushw	de                                   ; FB6CF3  push DE
	push	xix                                   ; FB6CF4  push XIX
	ld	(xiz-11), 0                             ; FB6CF5  ld (XIZ+0xf5),0x00
sub_FB6CEE__FB6CF9:
	ld	bc, (xiz-11)                            ; FB6CF9  ld BC,(XIZ+0xf5)
	extz	bc                                    ; FB6CFC  extz BC
	mul	bc, 0x12C                              ; FB6CFE  mul BC,0x012c
	ld	(xiz-6), bc                             ; FB6D02  ld (XIZ+0xfa),BC
	ld	xix, 0                                  ; FB6D05  ld XIX,0x00000000
	sub	xwa, xwa                               ; FB6D0A  sub XWA,XWA
	ld	(xiz-10), xwa                           ; FB6D0C  ld (XIZ+0xf6),XWA
	ld	(xiz-3), 4                              ; FB6D0F  ld (XIZ+0xfd),0x04
sub_FB6CEE__FB6D13:
	ld	(xiz-2), ix                             ; FB6D13  ld (XIZ+0xfe),IX
	ld	bc, (xiz-10)                            ; FB6D16  ld BC,(XIZ+0xf6)
	extpfx3 0x9E, 0xFA, 0x81                   ; FB6D19  add BC,(XIZ+0xfa)
	ld	(xiz-13), bc                            ; FB6D1C  ld (XIZ+0xf3),BC
	ldw	hl, 0                                  ; FB6D1F  ld HL,0x0000
	ld	de, bc                                  ; FB6D22  ld DE,BC
	add	de, 0xA6                               ; FB6D24  add DE,0x00a6
sub_FB6CEE__FB6D28:
	ld	bc, (xiz-6)                             ; FB6D28  ld BC,(XIZ+0xfa)
	add	bc, hl                                 ; FB6D2B  add BC,HL
	extpfx3 0x9E, 0xFE, 0x81                   ; FB6D2D  add BC,(XIZ+0xfe)
	add	bc, 53                                 ; FB6D30  add BC,0x0035
	extz	xbc                                   ; FB6D34  extz XBC
	ld	(xbc+0x1523), 0                         ; FB6D36  ld (XBC+0x1523),0x00
	ld	(xiz-13), de                            ; FB6D3C  ld (XIZ+0xf3),DE
	ld	bc, (xiz-13)                            ; FB6D3F  ld BC,(XIZ+0xf3)
	extz	xbc                                   ; FB6D42  extz XBC
	extpfx7 0xF3, 0xE5, 0x23, 0x15, 0x02, 0x00, 0x00 ; FB6D44  ld (XBC+0x1523),0x0000
	add	hl, 16                                 ; FB6D4B  add HL,0x0010
	ld	de, bc                                  ; FB6D4F  ld DE,BC
	inc	2, de                                  ; FB6D51  inc 2,DE
	cp	hl, 48                                  ; FB6D53  cp HL,0x0030
	jr c, sub_FB6CEE__FB6D28                   ; FB6D57  jr C,0xfb6d28
	inc	4, xix                                 ; FB6D59  inc 4,XIX
	ld	xbc, 41                                 ; FB6D5B  ld XBC,0x00000029
	add	(xiz-10), xbc                          ; FB6D60  add (XIZ+0xf6),XBC
	decm8	1, (xiz-3)                           ; FB6D63  dec 1,(XIZ+0xfd)
	cp (xiz-3), 0x00                           ; FB6D66  cp (XIZ+0xfd),0x00
	jr nz, sub_FB6CEE__FB6D13                  ; FB6D6A  jr NZ,0xfb6d13
	push	0                                     ; FB6D6C  push 0x00
	extpfx3 0x8E, 0xF5, 0x04                   ; FB6D6E  push (XIZ+0xf5)
	calr (0xFB6500 - 0xFB6D74)                 ; FB6D71  calr 0xfb6500
	incm8	1, (xiz-11)                          ; FB6D74  inc 1,(XIZ+0xf5)
	popw	bc                                    ; FB6D77  pop BC
	cp (xiz-11), 0x21                          ; FB6D78  cp (XIZ+0xf5),0x21
	jrl c, sub_FB6CEE__FB6CF9                  ; FB6D7C  jrl C,0xfb6cf9
	ldb	h, 0                                   ; FB6D7F  ld H,0x00
sub_FB6CEE__FB6D81:
	ldb	l, 0                                   ; FB6D81  ld L,0x00
sub_FB6CEE__FB6D83:
	ld	d, l                                    ; FB6D83  ld D,L
	push	0                                     ; FB6D85  push 0x00
	push	d                                     ; FB6D87  push D
	push	0                                     ; FB6D89  push 0x00
	push	h                                     ; FB6D8B  push H
	call	0xFA78E8                              ; FB6D8D  call 0xfa78e8
	ld	l, d                                    ; FB6D91  ld L,D
	inc	1, l                                   ; FB6D93  inc 1,L
	pop	xiy                                    ; FB6D95  pop XIY
	cps	l, 3                                   ; FB6D96  cp L,3
	jr c, sub_FB6CEE__FB6D83                   ; FB6D98  jr C,0xfb6d83
	inc	1, h                                   ; FB6D9A  inc 1,H
	cp	h, 64                                   ; FB6D9C  cp H,0x40
	jr c, sub_FB6CEE__FB6D81                   ; FB6D9F  jr C,0xfb6d81
	stib_da	(0xD733), 0xFF                     ; FB6DA1  ld (0x00d733),0xff
	stdi8	(0x1509), 17                         ; FB6DA7  ld (0x1509),0x11
	ldw	hl, 0                                  ; FB6DAC  ld HL,0x0000
	ldw (xiz-2), 0x0019                        ; FB6DAF  ld (XIZ+0xfe),0x0019
	ldw	de, 23                                 ; FB6DB4  ld DE,0x0017
	ldw	ix, 24                                 ; FB6DB7  ld IX,0x0018
sub_FB6CEE__FB6DBA:
	ld	bc, (xiz-2)                             ; FB6DBA  ld BC,(XIZ+0xfe)
	ld	(xiz-13), bc                            ; FB6DBD  ld (XIZ+0xf3),BC
	extz	xbc                                   ; FB6DC0  extz XBC
	ld	(xbc+0x1523), 1                         ; FB6DC2  ld (XBC+0x1523),0x01
	ld	(xiz-15), de                            ; FB6DC8  ld (XIZ+0xf1),DE
	ld	wa, (xiz-15)                            ; FB6DCB  ld WA,(XIZ+0xf1)
	extz	xwa                                   ; FB6DCE  extz XWA
	ld	(xwa+0x1523), 1                         ; FB6DD0  ld (XWA+0x1523),0x01
	ld	(xiz-17), ix                            ; FB6DD6  ld (XIZ+0xef),IX
	ld	bc, (xiz-17)                            ; FB6DD9  ld BC,(XIZ+0xef)
	extz	xbc                                   ; FB6DDC  extz XBC
	ld	(xbc+0x1523), 1                         ; FB6DDE  ld (XBC+0x1523),0x01
	add	hl, 0x12C                              ; FB6DE4  add HL,0x012c
	ld	ix, bc                                  ; FB6DE8  ld IX,BC
	add	ix, 0x12C                              ; FB6DEA  add IX,0x012c
	ld	de, wa                                  ; FB6DEE  ld DE,WA
	add	de, 0x12C                              ; FB6DF0  add DE,0x012c
	ld	bc, (xiz-13)                            ; FB6DF4  ld BC,(XIZ+0xf3)
	add	bc, 0x12C                              ; FB6DF7  add BC,0x012c
	ld	(xiz-2), bc                             ; FB6DFB  ld (XIZ+0xfe),BC
	cp	hl, 0x26AC                              ; FB6DFE  cp HL,0x26ac
	jr c, sub_FB6CEE__FB6DBA                   ; FB6E02  jr C,0xfb6dba
	pop	xix                                    ; FB6E04  pop XIX
	popw	de                                    ; FB6E05  pop DE
	popw	hl                                    ; FB6E06  pop HL
	unlk32 xiz                                 ; FB6E07  unlk XIZ
	ret                                        ; FB6E09  ret