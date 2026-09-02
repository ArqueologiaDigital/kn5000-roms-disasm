; ==============================================================================
; Technics SX-WSA1R -- prom_c (CPU 2, IC28) -- 0xF98CB9-0xF99062  key events become MIDI, and the four link-channel handlers
; ==============================================================================
;
; 643 lines moved out of prom_c/wsa1_prom_c.s by notes/prom_c_split.py.  The master
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
; Banner-declared.  The keyboard leaves this CPU as MIDI note-on messages
; over the inter-processor link, and the four Link_ChN_* ring handlers are
; the other direction.
;
; >>> END OF EXTRACTION HEADER -- everything below is verbatim from the master

; ==============================================================================
; 0xF98CB9-0xF99062 -- not yet converted
; ==============================================================================
; ==============================================================================
; 0xF98CB9-0xF99062 -- KEY EVENTS BECOME MIDI, and the FOUR link-channel handlers
;                      5 routines and one 16-entry jump table, 938 bytes
; ==============================================================================
;
; ★★ THE KEYBOARD IS SENT TO CPU 1 AS MIDI NOTE-ON MESSAGES.
; KeyEvents_ToLink builds a buffer of 3-byte groups
;
;       0x90 , note , velocity
;
; -- the byte 0x90 is a literal in the code (`ld (XBC+0xde),0x90` at 0xF98D24) --
; and hands the whole buffer to Link_SendBlock on channel 5.  0x90 is MIDI's
; Note-On status for channel 1, and the two bytes after it are exactly what
; ToneGen_VelocityFromTouch was made to produce.
;
; ★ THAT CLOSES THREE THINGS THIS FILE ALREADY WONDERED ABOUT, and each one is a
; separate check that lands on the same reading:
;   1. ToneGen_VelocityFromTouch's header notes that its output curve "spans 1..127
;      over all 256 entries and never reaches 0 or 128", i.e. a velocity that can
;      never be a note-off by accident.  In MIDI, note-on with velocity 0 IS a
;      note-off -- and KeyScan_ReadEvent forces the velocity byte to 0 on exactly
;      the note-OFF path (0xF997CE).  The curve's floor of 1 is what keeps that
;      encoding unambiguous.
;   2. The same header asks why the note is transposed by +36.  36 = MIDI note C2,
;      so keys 0..60 become MIDI notes 36..96 = C2..C7 -- the range of a 61-key
;      instrument, and 61 is the key count NoteTrim_BuildFromCalibration walks.
;   3. It also asks what the two pointer arguments are for.  They point into this
;      routine's frame buffer, one 3-byte group apart.
;
; ⚠ "MIDI" here is the ENCODING of the message, not a claim about where it goes:
; the buffer is handed to the inter-processor link, not to the UART.  The UART
; path is the separate drain in MAIN that uses channel 6.
;
; ★ THE FOUR LINK-CHANNEL HANDLERS ARE THESE FOUR ROUTINES.
; Link_ClassHandlerTable (further down this file) is 8 x u32 and its header ends
; "⚠ Still not established: what the four real class handlers DO".  Its first four
; entries are 0xF98D9A, 0xF98DE6, 0xF98FD6 and 0xF9901B -- the four routines below
; -- and its last four are all 0xF9993D, the `ret` now labelled
; Link_ChannelHandler_Ignore.  INTTC3_HANDLER__state1_generic indexes the table's
; RAM copy at 0x00F334 with (command byte >> 5), so:
;
;     link channel 0 -> Link_Ch0_AppendToRing       bytes into a 4096-byte ring
;     link channel 1 -> Link_Ch1_WriteParamBlock    16 sub-commands, 4 param blocks
;     link channel 2 -> Link_Ch2_ForwardBytes       byte stream, 0xFA intercepted
;     link channel 3 -> Link_Ch3_SetTouchControl    the two touch controls
;     link channels 4-7 -> discarded
;
; and the two channels CPU 2 SENDS on -- 5 and 6 -- are among the four it ignores
; when receiving, which is what a one-way channel assignment looks like.
;
; ⚠ WHAT IS NOT ESTABLISHED HERE: what CPU 1 does with the note-on stream; what
; the four parameter blocks at 0x00007E7E, 0x00007E98, 0x00007EB2 and 0x00007ECD
; control; and what 0xF992C6 (the per-byte sink of channel 2) does with a byte.
;
; Transcribed with notes/llvm_roundtrip_autoforce.py c 0xF98CB9 0x3AA, restyled by
; notes/prom_c_listing_prep.py, the jump table replaced by `.long` entries by hand,
; and re-proved before insertion with
; `python3 notes/prom_c_verify_fragment.py c 0xF98CB9 <file>`.

; --------------------------------------------------------------------------
; ★★ KeyEvents_ToLink -- drain the key scanner and the MIDI receive queue, and
;             send each as a link packet.
;
; Called from: 0xF98CA1 (`calr 0xF98CB9`, inside MAIN's per-pass tail) and six
;          `call 0xF98CB9` sites at 0xFB09FE, 0xFB3740, 0xFB384D, 0xFB39D7,
;          0xFB3ADF and 0xFB3BF8.  notes/prom_c_xrefs.py 0xF98CB9.
; Inputs:  none.  Globals: the flush counter at 0x00E2E1.
; Outputs: up to ten 3-byte MIDI note-on groups on link channel 5, and up to 32
;          raw MIDI bytes on link channel 6.
; Evidence, step by step off the instructions:
;   * FLUSH MODE.  If the 16-bit value at 0x00E2E1 is > 0, the routine drains the
;     scanner into the SAME two frame bytes over and over until KeyScan_ReadEvent
;     returns 0xFFFF, decrements 0x00E2E1, and returns without sending anything.
;     So a positive 0x00E2E1 means "throw the keyboard away this pass".
;   * NORMAL MODE.  `i = 0`; each pass calls KeyScan_ReadEvent with pointers
;     `frame+i+1` and `frame+i+2`, and on success writes `frame+i = 0x90` and
;     `i += 3`.  The loop stops on 0xFFFF or when `i` reaches 0x1E = 30, so the
;     buffer holds at most TEN groups.  30 / 3 = 10, and the bound is a literal.
;   * `Link_SendBlock(channel 5, i, frame)` if i != 0.
;   * Then the identical shape for MIDI_Rx_Dequeue: up to 0x20 = 32 bytes into the
;     same frame buffer, then `Link_SendBlock(channel 6, i, frame)`.
; ⚠ The two drains SHARE the frame buffer and the counter at (XIZ-0x23); the
;   second sets it back to 0 first (0xF98D4E).  Nothing is left over between them.
; ⚠ MAIN has its OWN channel-6 drain (the loop at 0xF98BC1, whose MIDI_Rx_Dequeue
;   call is at 0xF98BC6, converted above) that does the same thing with the same
;   32-byte bound.  Two drains of one queue, in one
;   loop body, is what the code says; why is not established.
; Unknown:  what writes 0x00E2E1 (it is inside the boot RAM image, so its power-on
;          value is readable with notes/prom_c_ram_image.py, but no writer has been
;          found in converted code); what CPU 1 does with channel 5.
; --------------------------------------------------------------------------
KeyEvents_ToLink:
	link32 0xEE, 0x0C, 0xDD, 0xFF          ; F98CB9  link XIZ,0xffdd   [llvm-mc cannot encode this]
	pushw	hl                               ; F98CBD  push HL
	push	xix                               ; F98CBE  push XIX
	extpfx7 0xD2, 0xE1, 0xE2, 0x00, 0x3F, 0x00, 0x00 ; F98CBF  cp (0x00e2e1),0x0000   [llvm-mc cannot encode this]
	jr le, KeyEvents_ToLink__F98CEA                       ; F98CC6  jr LE,0xf98cea
KeyEvents_ToLink__F98CC8:
	lda	xbc, (xiz-34)                      ; F98CC8  lda XBC,XIZ+0xde
	inc	2, xbc                             ; F98CCB  inc 2,XBC
	push	xbc                               ; F98CCD  push XBC
	lda	xbc, (xiz-34)                      ; F98CCE  lda XBC,XIZ+0xde
	inc	1, xbc                             ; F98CD1  inc 1,XBC
	push	xbc                               ; F98CD3  push XBC
	call	0xF9973D                          ; F98CD4  call 0xf9973d
	inc	8, xsp                             ; F98CD8  inc 0,XSP
	cp	wa, 0xFFFF                          ; F98CDA  cp WA,0xffff
	jr z, KeyEvents_ToLink__F98CE2                        ; F98CDE  jr Z,0xf98ce2
	jr KeyEvents_ToLink__F98CC8                           ; F98CE0  jr T,0xf98cc8
KeyEvents_ToLink__F98CE2:
	decdi16_24	1, (0xE2E1)                 ; F98CE2  decw 1,(0x00e2e1)
	jrl KeyEvents_ToLink__F98D4E                          ; F98CE7  jrl T,0xf98d4e
KeyEvents_ToLink__F98CEA:
	ld	(xiz-35), 0                         ; F98CEA  ld (XIZ+0xdd),0x00
KeyEvents_ToLink__F98CEE:
	ld	ix, (xiz-35)                        ; F98CEE  ld IX,(XIZ+0xdd)
	extz	ix                                ; F98CF1  extz IX
	extz	xix                               ; F98CF3  extz XIX
	ld	xbc, xix                            ; F98CF5  ld XBC,XIX
	inc	2, xbc                             ; F98CF7  inc 2,XBC
	add	xbc, xiz                           ; F98CF9  add XBC,XIZ
	add	xbc, 0xFFFFFFDE                    ; F98CFB  add XBC,0xffffffde
	push	xbc                               ; F98D01  push XBC
	ld	xbc, xix                            ; F98D02  ld XBC,XIX
	inc	1, xbc                             ; F98D04  inc 1,XBC
	add	xbc, xiz                           ; F98D06  add XBC,XIZ
	add	xbc, 0xFFFFFFDE                    ; F98D08  add XBC,0xffffffde
	push	xbc                               ; F98D0E  push XBC
	call	0xF9973D                          ; F98D0F  call 0xf9973d
	inc	8, xsp                             ; F98D13  inc 0,XSP
	cp	wa, 0xFFFF                          ; F98D15  cp WA,0xffff
	jr z, KeyEvents_ToLink__F98D35                        ; F98D19  jr Z,0xf98d35
	ld	bc, (xiz-35)                        ; F98D1B  ld BC,(XIZ+0xdd)
	extz	bc                                ; F98D1E  extz BC
	extz	xbc                               ; F98D20  extz XBC
	add	xbc, xiz                           ; F98D22  add XBC,XIZ
	ld	(xbc-34), 0x90                      ; F98D24  ld (XBC+0xde),0x90
	incm8	3, (xiz-35)                      ; F98D28  inc 3,(XIZ+0xdd)
	cp (xiz-35), 0x1E                      ; F98D2B  cp (XIZ+0xdd),0x1e   [llvm-mc cannot encode this]
	jr nz, KeyEvents_ToLink__F98D33                       ; F98D2F  jr NZ,0xf98d33
	jr KeyEvents_ToLink__F98D35                           ; F98D31  jr T,0xf98d35
KeyEvents_ToLink__F98D33:
	jr KeyEvents_ToLink__F98CEE                           ; F98D33  jr T,0xf98cee
KeyEvents_ToLink__F98D35:
	cp (xiz-35), 0x00                      ; F98D35  cp (XIZ+0xdd),0x00   [llvm-mc cannot encode this]
	jr z, KeyEvents_ToLink__F98D4E                        ; F98D39  jr Z,0xf98d4e
	lda	xbc, (xiz-34)                      ; F98D3B  lda XBC,XIZ+0xde
	push	xbc                               ; F98D3E  push XBC
	ld	wa, (xiz-35)                        ; F98D3F  ld WA,(XIZ+0xdd)
	extz	wa                                ; F98D42  extz WA
	pushw	wa                               ; F98D44  push WA
	pushw	5                                ; F98D45  push 0x0005
	call	0xF9997E                          ; F98D48  call 0xf9997e
	inc	8, xsp                             ; F98D4C  inc 0,XSP
KeyEvents_ToLink__F98D4E:
	ld	(xiz-35), 0                         ; F98D4E  ld (XIZ+0xdd),0x00
KeyEvents_ToLink__F98D52:
	call	0xF991F4                          ; F98D52  call 0xf991f4
	ld	hl, wa                              ; F98D56  ld HL,WA
	ld	(xiz-2), wa                         ; F98D58  ld (XIZ+0xfe),WA
	cp	hl, 0xFFFF                          ; F98D5B  cp HL,0xffff
	jr z, KeyEvents_ToLink__F98D7C                        ; F98D5F  jr Z,0xf98d7c
	ld	ix, (xiz-35)                        ; F98D61  ld IX,(XIZ+0xdd)
	extz	ix                                ; F98D64  extz IX
	extz	xix                               ; F98D66  extz XIX
	ld	xbc, xix                            ; F98D68  ld XBC,XIX
	add	xbc, xiz                           ; F98D6A  add XBC,XIZ
	ld	(xbc-34), a                         ; F98D6C  ld (XBC+0xde),A
	incm8	1, (xiz-35)                      ; F98D6F  inc 1,(XIZ+0xdd)
	cp (xiz-35), 0x20                      ; F98D72  cp (XIZ+0xdd),0x20   [llvm-mc cannot encode this]
	jr nz, KeyEvents_ToLink__F98D7A                       ; F98D76  jr NZ,0xf98d7a
	jr KeyEvents_ToLink__F98D7C                           ; F98D78  jr T,0xf98d7c
KeyEvents_ToLink__F98D7A:
	jr KeyEvents_ToLink__F98D52                           ; F98D7A  jr T,0xf98d52
KeyEvents_ToLink__F98D7C:
	cp (xiz-35), 0x00                      ; F98D7C  cp (XIZ+0xdd),0x00   [llvm-mc cannot encode this]
	jr z, KeyEvents_ToLink__F98D95                        ; F98D80  jr Z,0xf98d95
	lda	xbc, (xiz-34)                      ; F98D82  lda XBC,XIZ+0xde
	push	xbc                               ; F98D85  push XBC
	ld	wa, (xiz-35)                        ; F98D86  ld WA,(XIZ+0xdd)
	extz	wa                                ; F98D89  extz WA
	pushw	wa                               ; F98D8B  push WA
	pushw	6                                ; F98D8C  push 0x0006
	call	0xF9997E                          ; F98D8F  call 0xf9997e
	inc	8, xsp                             ; F98D93  inc 0,XSP
KeyEvents_ToLink__F98D95:
	pop	xix                                ; F98D95  pop XIX
	popw	hl                                ; F98D96  pop HL
	unlk32 xiz                             ; F98D97  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; F98D99  ret

; --------------------------------------------------------------------------
; Link_Ch0_AppendToRing -- append a packet's bytes to the 4096-byte ring at
;             0x00E2F1.
;
; Called from: entry 0 of Link_ClassHandlerTable -- the ROM table entry at
;          0xFCC53F, which notes/prom_c_xrefs.py 0xF98D9A finds, and nothing else.
; Inputs:  (XIZ+0x08) u16 byte count, (XIZ+0x0a) pointer to the bytes.
;          The dispatch indexes the table's RAM COPY at 0x00F334, not the ROM
;          original.  ⚠ The address above is a VARIABLE, not a call site.  It is stated here rather than in `Called from:` because notes/prom_c_audit_callsites.py harvests every 0xXXXXXX in that paragraph and cannot tell prose from a citation.
; Outputs: `count` bytes into the ring; the 16-bit write index at 0x00E2EB and the
;          16-bit counter at 0x00E2EF each advanced by `count`.
; Evidence: the store address is
;          `((0x00E2EB) & 0x0FFF) + 6 + 0x0000E2EB`, so the descriptor is
;          {u16 write index at +0, u16 at +4, data from +6} and the ring is
;          0x00E2F1-0x00F2F0.
;          ★ THE MASK AND THE NEXT KNOWN VARIABLE AGREE EXACTLY.  0x0FFF makes the
;          ring 4096 bytes, and 0x00F2F1 -- the first address past it -- is
;          `0x00E2F1 + 0x1000` and is the main loop's countdown, whose boot value
;          notes/FINDINGS-prom_c-ram-image.md already records.  The ring ends
;          precisely where the next documented variable begins.
;          The whole descriptor lies inside the boot RAM image (0x00E2DF-0x00F3B6),
;          so its power-on contents are readable:
;              python3 notes/prom_c_ram_image.py 0x00E2EB:8
; ★ ITS CONSUMER IS TRACED.  MAIN pushes `0x00E2EB` and calls 0xFB060A
;   immediately after KeyEvents_ToLink (0xF98CA4-0xF98CAA), and 0xF98CA4 is the
;   only `lda XBC,0x00E2EB` in the image -- the other two literal-addressed sites
;   are the `ld WA,(0x00E2EB)` and `incw 1,(0x00E2EB)` inside this routine
;   (notes/prom_c_xrefs.py 0x00E2EB --no-window --classify).
; ★ RESOLVED 2026-08-25 (round 6) -- 0x00E2EF IS THE BYTE COUNT, and the
;          descriptor has four fields, not three.  Converting
;          MidiIn_ParseRingAndDispatch (0xFB060A) supplied the consumer this
;          header could not find:
;              +0  0x00E2EB  u16  WRITE index  -- incremented here
;              +2  0x00E2ED  u16  READ index   -- the parser's cursor
;              +4  0x00E2EF  u16  BYTE COUNT   -- incremented here, and the
;                                                 parser's entry guard is
;                                                 `cp DE,(desc+4) < 4` with every
;                                                 arm doing `decw 4,(desc+4)`
;              +6  0x00E2F1  ..   the 4096-byte ring
;          The old "written here and read by nothing that names it" was right about
;          the LITERAL census and wrong about the fact: the parser reaches +4
;          through the descriptor pointer MAIN pushes, so no instruction spells
;          0x00E2EF and prom_c_xrefs.py could not see it.  ★ That is the general
;          lesson: a literal census cannot see a field reached through a base
;          pointer, and "no reference found" for a STRUCTURE MEMBER is worth much
;          less than for a routine.
; Unknown:  nothing further about the descriptor.
; --------------------------------------------------------------------------
Link_Ch0_AppendToRing:
	link32 0xEE, 0x0C, 0xFE, 0xFF          ; F98D9A  link XIZ,0xfffe   [llvm-mc cannot encode this]
	pushw	hl                               ; F98D9E  push HL
	ldw (xiz-2), 0x0000                    ; F98D9F  ld (XIZ+0xfe),0x0000   [llvm-mc cannot encode this]
Link_Ch0_AppendToRing__F98DA4:
	ld	bc, (xiz+8)                         ; F98DA4  ld BC,(XIZ+0x08)
	extz	bc                                ; F98DA7  extz BC
	cp	(xiz-2), bc                         ; F98DA9  cp (XIZ+0xfe),BC
	jr nc, Link_Ch0_AppendToRing__F98DE2                       ; F98DAC  jr NC,0xf98de2
	jr Link_Ch0_AppendToRing__F98DB5                           ; F98DAE  jr T,0xf98db5
Link_Ch0_AppendToRing__F98DB0:
	incw	1, (xiz-2)                        ; F98DB0  incw 1,(XIZ+0xfe)
	jr Link_Ch0_AppendToRing__F98DA4                           ; F98DB3  jr T,0xf98da4
Link_Ch0_AppendToRing__F98DB5:
	ld	xbc, (xiz+10)                       ; F98DB5  ld XBC,(XIZ+0x0a)
	ld	h, (xbc)                            ; F98DB8  ld H,(XBC)
	ld	wa, (0xE2EB:24)                    ; F98DBA  ld WA,(0x00e2eb)
	and	wa, 0xFFF                          ; F98DBF  and WA,0x0fff
	exts	xwa                               ; F98DC3  exts XWA
	inc	6, xwa                             ; F98DC5  inc 6,XWA
	add	xwa, 0xE2EB                        ; F98DC7  add XWA,0x0000e2eb
	ld	(xwa), h                            ; F98DCD  ld (XWA),H
	incdi16_24	1, (0xE2EB)                 ; F98DCF  incw 1,(0x00e2eb)
	incdi16_24	1, (0xE2EF)                 ; F98DD4  incw 1,(0x00e2ef)
	sub	xbc, xbc                           ; F98DD9  sub XBC,XBC
	inc	1, xbc                             ; F98DDB  inc 1,XBC
	add	(xiz+10), xbc                      ; F98DDD  add (XIZ+0x0a),XBC
	jr Link_Ch0_AppendToRing__F98DB0                           ; F98DE0  jr T,0xf98db0
Link_Ch0_AppendToRing__F98DE2:
	popw	hl                                ; F98DE2  pop HL
	unlk32 xiz                             ; F98DE3  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; F98DE5  ret

; --------------------------------------------------------------------------
; ★ Link_Ch1_WriteParamBlock -- CPU 1 writes a byte range into one of four
;             parameter blocks, and flags it.
;
; Called from: entry 1 of Link_ClassHandlerTable (ROM 0xFCC543).
; Inputs:  (XIZ+0x08) u16 total packet length, (XIZ+0x0a) pointer to the packet.
; Packet:  `{u8 command, u8 offset, u8 length, payload...}` -- read off the three
;          byte fetches at 0xF98DEC-0xF98E0A and the two checks that follow:
;              `HL = length + 3;  if HL != total, return`     (0xF98E11-0xF98E1C)
;              `if offset + length > 0x1A, return`            (0xF98E1F-0xF98E2A)
;          so every block is at most **26 bytes** and the packet is exactly
;          3 + length bytes.  Both bounds are literals.
; Dispatch: `command - 0x80`, rejected unless <= 0x0F, then
;          `Link_Ch1_CommandTable[index]`.  Sixteen 4-byte entries running from
;          0xF98F91 to 0xF98FD0 inclusive, which ends EXACTLY on 0xF98FD1 -- the
;          routine's own epilogue, and also the target every unused entry holds.
;          The table's end is therefore fixed by the code that follows it.
;
;     command  destination block   flag         extra
;     0x80/88  -- (one byte)       0x007ECC.0   (0x00F361) = payload[0]
;     0x81     0x00007E7E          0x007ECC.1   (0x007E97) = 1, then as 0x89
;     0x89     0x00007E7E          0x007ECC.1
;     0x82     0x00007E98          0x007ECC.2   (0x007EB1) = 1, then as 0x8A
;     0x8A     0x00007E98          0x007ECC.2
;     0x83     0x00007EB2          0x007ECC.3   (0x007ECB) = 1, then as 0x8B
;     0x8B     0x00007EB2          0x007ECC.3
;     0x87/8F  0x00007ECD          0x007ECC.4
;     0x84-86, 0x8C-8E             -- ignored, straight to the epilogue
;
; ★ THE THREE BLOCK BASES ARE 26 BYTES APART, WHICH IS THE BOUND THE ROUTINE
;   ENFORCES: 0x7E98 - 0x7E7E = 0x1A and 0x7EB2 - 0x7E98 = 0x1A.  And the three
;   "extra" bytes 0x7E97, 0x7EB1 and 0x7ECB are each the LAST byte of the block
;   before them, so the 0x8x form of each pair sets its own block's last byte to 1
;   and the 0x8(x+8) form does not.  That is read off five addresses agreeing, not
;   from any one instruction.
; ⚠ 0x00007ECD + 0x19 = 0x00007EE6, so the fourth block COVERS 0x007ED1 -- the
;   six-phase scheduler's job-request byte (notes/FINDINGS-prom_c-scheduler.md) --
;   at offset 4.  Whether any packet actually reaches that far depends on the
;   offset and length CPU 1 sends, which is not established.  Recorded because a
;   MAME device or a firmware change that assumed 0x007ED1 was CPU-2-private would
;   be assuming something this routine does not guarantee.
; ★ 0x007ECC IS THE "SOMETHING CHANGED" BYTE.  Ten literal-addressed sites in the
;   image (`notes/prom_c_xrefs.py 0x007ECC --no-window --classify`): MAIN tests it
;   at 0xF98C52 and clears it at 0xF98C5C, five of the sets are the arms here, two
;   more set bit 7 inside the 0xF9918C/0xF99199 pair, and 0xFA26C1 sets bit 5.
; Unknown:  what any of the four blocks controls.
; --------------------------------------------------------------------------
Link_Ch1_WriteParamBlock:
	link32 0xEE, 0x0C, 0xF4, 0xFF          ; F98DE6  link XIZ,0xfff4   [llvm-mc cannot encode this]
	pushw	hl                               ; F98DEA  push HL
	push	xix                               ; F98DEB  push XIX
	ld	xbc, (xiz+10)                       ; F98DEC  ld XBC,(XIZ+0x0a)
	ld	a, (xbc)                            ; F98DEF  ld A,(XBC)
	ld	(xiz-1), a                          ; F98DF1  ld (XIZ+0xff),A
	inc	1, xbc                             ; F98DF4  inc 1,XBC
	ld	(xiz+10), xbc                       ; F98DF6  ld (XIZ+0x0a),XBC
	ld	w, (xbc)                            ; F98DF9  ld W,(XBC)
	ld	(xiz-2), w                          ; F98DFB  ld (XIZ+0xfe),W
	inc	1, xbc                             ; F98DFE  inc 1,XBC
	ld	(xiz+10), xbc                       ; F98E00  ld (XIZ+0x0a),XBC
	ld	a, (xbc)                            ; F98E03  ld A,(XBC)
	ld	(xiz-3), a                          ; F98E05  ld (XIZ+0xfd),A
	inc	1, xbc                             ; F98E08  inc 1,XBC
	ld	(xiz+10), xbc                       ; F98E0A  ld (XIZ+0x0a),XBC
	extz	wa                                ; F98E0D  extz WA
	ld	hl, wa                              ; F98E0F  ld HL,WA
	inc	3, hl                              ; F98E11  inc 3,HL
	ld	wa, (xiz+8)                         ; F98E13  ld WA,(XIZ+0x08)
	extz	wa                                ; F98E16  extz WA
	cp	hl, wa                              ; F98E18  cp HL,WA
	jr z, Link_Ch1_WriteParamBlock__F98E1F                        ; F98E1A  jr Z,0xf98e1f
	jrl Link_Ch1_WriteParamBlock__F98FD1                          ; F98E1C  jrl T,0xf98fd1
Link_Ch1_WriteParamBlock__F98E1F:
	ld	c, (xiz-3)                          ; F98E1F  ld C,(XIZ+0xfd)
	extpfx3 0x8E, 0xFE, 0x83               ; F98E22  add C,(XIZ+0xfe)   [llvm-mc cannot encode this]
	cp	c, 26                               ; F98E25  cp C,0x1a
	jr ule, Link_Ch1_WriteParamBlock__F98E2D                      ; F98E28  jr ULE,0xf98e2d
	jrl Link_Ch1_WriteParamBlock__F98FD1                          ; F98E2A  jrl T,0xf98fd1
Link_Ch1_WriteParamBlock__F98E2D:
	ld	bc, (xiz-1)                         ; F98E2D  ld BC,(XIZ+0xff)
	extz	bc                                ; F98E30  extz BC
	ld	(xiz-12), bc                        ; F98E32  ld (XIZ+0xf4),BC
	jrl Link_Ch1_WriteParamBlock__F98F75                          ; F98E35  jrl T,0xf98f75
	setda_24 0, 0x007ECC                   ; F98E38  set 0,(0x007ecc)   [llvm-mc cannot encode this]
	ld	xbc, (xiz+10)                       ; F98E3D  ld XBC,(XIZ+0x0a)
	ld	a, (xbc)                            ; F98E40  ld A,(XBC)
	stb_da	(0xF361), a                     ; F98E42  ld (0x00f361),A
	jrl Link_Ch1_WriteParamBlock__F98FD1                          ; F98E47  jrl T,0xf98fd1
	stib_da	(0x7E97), 1                    ; F98E4A  ld (0x007e97),0x01
	setda_24 1, 0x007ECC                   ; F98E50  set 1,(0x007ecc)   [llvm-mc cannot encode this]
	ld	bc, (xiz-2)                         ; F98E55  ld BC,(XIZ+0xfe)
	extz	bc                                ; F98E58  extz BC
	extz	xbc                               ; F98E5A  extz XBC
	add	xbc, 0x7E7E                        ; F98E5C  add XBC,0x00007e7e
	ld	(xiz-8), xbc                        ; F98E62  ld (XIZ+0xf8),XBC
	ldw (xiz-10), 0x0000                   ; F98E65  ld (XIZ+0xf6),0x0000   [llvm-mc cannot encode this]
Link_Ch1_WriteParamBlock__F98E6A:
	ld	bc, (xiz-3)                         ; F98E6A  ld BC,(XIZ+0xfd)
	extz	bc                                ; F98E6D  extz BC
	cp	(xiz-10), bc                        ; F98E6F  cp (XIZ+0xf6),BC
	jr nc, Link_Ch1_WriteParamBlock__F98E93                       ; F98E72  jr NC,0xf98e93
	jr Link_Ch1_WriteParamBlock__F98E7B                           ; F98E74  jr T,0xf98e7b
Link_Ch1_WriteParamBlock__F98E76:
	incw	1, (xiz-10)                       ; F98E76  incw 1,(XIZ+0xf6)
	jr Link_Ch1_WriteParamBlock__F98E6A                           ; F98E79  jr T,0xf98e6a
Link_Ch1_WriteParamBlock__F98E7B:
	ld	xbc, (xiz+10)                       ; F98E7B  ld XBC,(XIZ+0x0a)
	ld	a, (xbc)                            ; F98E7E  ld A,(XBC)
	ld	h, a                                ; F98E80  ld H,A
	ld	xwa, (xiz-8)                        ; F98E82  ld XWA,(XIZ+0xf8)
	ld	(xwa), h                            ; F98E85  ld (XWA),H
	sub	xbc, xbc                           ; F98E87  sub XBC,XBC
	inc	1, xbc                             ; F98E89  inc 1,XBC
	add	(xiz+10), xbc                      ; F98E8B  add (XIZ+0x0a),XBC
	add	(xiz-8), xbc                       ; F98E8E  add (XIZ+0xf8),XBC
	jr Link_Ch1_WriteParamBlock__F98E76                           ; F98E91  jr T,0xf98e76
Link_Ch1_WriteParamBlock__F98E93:
	jrl Link_Ch1_WriteParamBlock__F98FD1                          ; F98E93  jrl T,0xf98fd1
	stib_da	(0x7EB1), 1                    ; F98E96  ld (0x007eb1),0x01
	setda_24 2, 0x007ECC                   ; F98E9C  set 2,(0x007ecc)   [llvm-mc cannot encode this]
	lda	xix, (0x7E98:24)                   ; F98EA1  lda XIX,0x007e98
	ld	bc, (xiz-2)                         ; F98EA6  ld BC,(XIZ+0xfe)
	extz	bc                                ; F98EA9  extz BC
	extz	xbc                               ; F98EAB  extz XBC
	add	xbc, xix                           ; F98EAD  add XBC,XIX
	ld	(xiz-8), xbc                        ; F98EAF  ld (XIZ+0xf8),XBC
	ldw (xiz-10), 0x0000                   ; F98EB2  ld (XIZ+0xf6),0x0000   [llvm-mc cannot encode this]
Link_Ch1_WriteParamBlock__F98EB7:
	ld	bc, (xiz-3)                         ; F98EB7  ld BC,(XIZ+0xfd)
	extz	bc                                ; F98EBA  extz BC
	cp	(xiz-10), bc                        ; F98EBC  cp (XIZ+0xf6),BC
	jr nc, Link_Ch1_WriteParamBlock__F98EE0                       ; F98EBF  jr NC,0xf98ee0
	jr Link_Ch1_WriteParamBlock__F98EC8                           ; F98EC1  jr T,0xf98ec8
Link_Ch1_WriteParamBlock__F98EC3:
	incw	1, (xiz-10)                       ; F98EC3  incw 1,(XIZ+0xf6)
	jr Link_Ch1_WriteParamBlock__F98EB7                           ; F98EC6  jr T,0xf98eb7
Link_Ch1_WriteParamBlock__F98EC8:
	ld	xbc, (xiz+10)                       ; F98EC8  ld XBC,(XIZ+0x0a)
	ld	a, (xbc)                            ; F98ECB  ld A,(XBC)
	ld	h, a                                ; F98ECD  ld H,A
	ld	xwa, (xiz-8)                        ; F98ECF  ld XWA,(XIZ+0xf8)
	ld	(xwa), h                            ; F98ED2  ld (XWA),H
	sub	xbc, xbc                           ; F98ED4  sub XBC,XBC
	inc	1, xbc                             ; F98ED6  inc 1,XBC
	add	(xiz+10), xbc                      ; F98ED8  add (XIZ+0x0a),XBC
	add	(xiz-8), xbc                       ; F98EDB  add (XIZ+0xf8),XBC
	jr Link_Ch1_WriteParamBlock__F98EC3                           ; F98EDE  jr T,0xf98ec3
Link_Ch1_WriteParamBlock__F98EE0:
	jrl Link_Ch1_WriteParamBlock__F98FD1                          ; F98EE0  jrl T,0xf98fd1
	stib_da	(0x7ECB), 1                    ; F98EE3  ld (0x007ecb),0x01
	setda_24 3, 0x007ECC                   ; F98EE9  set 3,(0x007ecc)   [llvm-mc cannot encode this]
	lda	xix, (0x7EB2:24)                   ; F98EEE  lda XIX,0x007eb2
	ld	bc, (xiz-2)                         ; F98EF3  ld BC,(XIZ+0xfe)
	extz	bc                                ; F98EF6  extz BC
	extz	xbc                               ; F98EF8  extz XBC
	add	xbc, xix                           ; F98EFA  add XBC,XIX
	ld	(xiz-8), xbc                        ; F98EFC  ld (XIZ+0xf8),XBC
	ldw (xiz-10), 0x0000                   ; F98EFF  ld (XIZ+0xf6),0x0000   [llvm-mc cannot encode this]
Link_Ch1_WriteParamBlock__F98F04:
	ld	bc, (xiz-3)                         ; F98F04  ld BC,(XIZ+0xfd)
	extz	bc                                ; F98F07  extz BC
	cp	(xiz-10), bc                        ; F98F09  cp (XIZ+0xf6),BC
	jr nc, Link_Ch1_WriteParamBlock__F98F2D                       ; F98F0C  jr NC,0xf98f2d
	jr Link_Ch1_WriteParamBlock__F98F15                           ; F98F0E  jr T,0xf98f15
Link_Ch1_WriteParamBlock__F98F10:
	incw	1, (xiz-10)                       ; F98F10  incw 1,(XIZ+0xf6)
	jr Link_Ch1_WriteParamBlock__F98F04                           ; F98F13  jr T,0xf98f04
Link_Ch1_WriteParamBlock__F98F15:
	ld	xbc, (xiz+10)                       ; F98F15  ld XBC,(XIZ+0x0a)
	ld	a, (xbc)                            ; F98F18  ld A,(XBC)
	ld	h, a                                ; F98F1A  ld H,A
	ld	xwa, (xiz-8)                        ; F98F1C  ld XWA,(XIZ+0xf8)
	ld	(xwa), h                            ; F98F1F  ld (XWA),H
	sub	xbc, xbc                           ; F98F21  sub XBC,XBC
	inc	1, xbc                             ; F98F23  inc 1,XBC
	add	(xiz+10), xbc                      ; F98F25  add (XIZ+0x0a),XBC
	add	(xiz-8), xbc                       ; F98F28  add (XIZ+0xf8),XBC
	jr Link_Ch1_WriteParamBlock__F98F10                           ; F98F2B  jr T,0xf98f10
Link_Ch1_WriteParamBlock__F98F2D:
	jrl Link_Ch1_WriteParamBlock__F98FD1                          ; F98F2D  jrl T,0xf98fd1
	setda_24 4, 0x007ECC                   ; F98F30  set 4,(0x007ecc)   [llvm-mc cannot encode this]
	ld	bc, (xiz-2)                         ; F98F35  ld BC,(XIZ+0xfe)
	extz	bc                                ; F98F38  extz BC
	extz	xbc                               ; F98F3A  extz XBC
	add	xbc, 0x7ECD                        ; F98F3C  add XBC,0x00007ecd
	ld	(xiz-8), xbc                        ; F98F42  ld (XIZ+0xf8),XBC
	ldw (xiz-10), 0x0000                   ; F98F45  ld (XIZ+0xf6),0x0000   [llvm-mc cannot encode this]
Link_Ch1_WriteParamBlock__F98F4A:
	ld	bc, (xiz-3)                         ; F98F4A  ld BC,(XIZ+0xfd)
	extz	bc                                ; F98F4D  extz BC
	cp	(xiz-10), bc                        ; F98F4F  cp (XIZ+0xf6),BC
	jr nc, Link_Ch1_WriteParamBlock__F98F73                       ; F98F52  jr NC,0xf98f73
	jr Link_Ch1_WriteParamBlock__F98F5B                           ; F98F54  jr T,0xf98f5b
Link_Ch1_WriteParamBlock__F98F56:
	incw	1, (xiz-10)                       ; F98F56  incw 1,(XIZ+0xf6)
	jr Link_Ch1_WriteParamBlock__F98F4A                           ; F98F59  jr T,0xf98f4a
Link_Ch1_WriteParamBlock__F98F5B:
	ld	xbc, (xiz+10)                       ; F98F5B  ld XBC,(XIZ+0x0a)
	ld	a, (xbc)                            ; F98F5E  ld A,(XBC)
	ld	h, a                                ; F98F60  ld H,A
	ld	xwa, (xiz-8)                        ; F98F62  ld XWA,(XIZ+0xf8)
	ld	(xwa), h                            ; F98F65  ld (XWA),H
	sub	xbc, xbc                           ; F98F67  sub XBC,XBC
	inc	1, xbc                             ; F98F69  inc 1,XBC
	add	(xiz+10), xbc                      ; F98F6B  add (XIZ+0x0a),XBC
	add	(xiz-8), xbc                       ; F98F6E  add (XIZ+0xf8),XBC
	jr Link_Ch1_WriteParamBlock__F98F56                           ; F98F71  jr T,0xf98f56
Link_Ch1_WriteParamBlock__F98F73:
	jr Link_Ch1_WriteParamBlock__F98FD1                           ; F98F73  jr T,0xf98fd1
Link_Ch1_WriteParamBlock__F98F75:
	sub	xbc, xbc                           ; F98F75  sub XBC,XBC
	ld	bc, (xiz-12)                        ; F98F77  ld BC,(XIZ+0xf4)
	sub	bc, 0x80                           ; F98F7A  sub BC,0x0080
	cp	bc, 15                              ; F98F7E  cp BC,0x000f
	jr ugt, Link_Ch1_WriteParamBlock__F98FD1                      ; F98F82  jr UGT,0xf98fd1
	sll	bc, 2                              ; F98F84  sll 0x02,BC
	add	xbc, 0xF98F91                      ; F98F87  add XBC,0x00f98f91
	ld	xbc, (xbc)                          ; F98F8D  ld XBC,(XBC)
	jp	(xbc)                               ; F98F8F  jp T,XBC

; ----------------------------------------------------------------------------
; Link_Ch1_CommandTable -- 0xF98F91-0xF98FD0, SIXTEEN 32-bit targets for
; sub-commands 0x80..0x8F.  Bounded twice: `cp BC,0x000F / jr UGT` rejects
; anything above 15, and sixteen 4-byte entries from 0xF98F91 end exactly on
; 0xF98FD1, which is the routine's epilogue AND the target of every unused entry.
; The LAST entry (0xF98FCD) was checked as well as the first: it holds 0xF98F30,
; the 0x87 arm, which is what command 0x8F has to be for the 0x8x/0x8(x+8) pairing
; to hold all the way across.
; ----------------------------------------------------------------------------
Link_Ch1_CommandTable:
	.long	0x00F98E38			; 0xF98F91  command 0x80
	.long	0x00F98E4A			; 0xF98F95  command 0x81
	.long	0x00F98E96			; 0xF98F99  command 0x82
	.long	0x00F98EE3			; 0xF98F9D  command 0x83
	.long	0x00F98FD1			; 0xF98FA1  command 0x84
	.long	0x00F98FD1			; 0xF98FA5  command 0x85
	.long	0x00F98FD1			; 0xF98FA9  command 0x86
	.long	0x00F98F30			; 0xF98FAD  command 0x87
	.long	0x00F98E38			; 0xF98FB1  command 0x88
	.long	0x00F98E50			; 0xF98FB5  command 0x89
	.long	0x00F98E9C			; 0xF98FB9  command 0x8A
	.long	0x00F98EE9			; 0xF98FBD  command 0x8B
	.long	0x00F98FD1			; 0xF98FC1  command 0x8C
	.long	0x00F98FD1			; 0xF98FC5  command 0x8D
	.long	0x00F98FD1			; 0xF98FC9  command 0x8E
	.long	0x00F98F30			; 0xF98FCD  command 0x8F
Link_Ch1_WriteParamBlock__F98FD1:
	pop	xix                                ; F98FD1  pop XIX
	popw	hl                                ; F98FD2  pop HL
	unlk32 xiz                             ; F98FD3  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; F98FD5  ret

; --------------------------------------------------------------------------
; Link_Ch2_ForwardBytes -- push a packet's bytes one at a time into 0xF992C6,
;             intercepting the byte 0xFA.
;
; Called from: entry 2 of Link_ClassHandlerTable (ROM 0xFCC547).
; Inputs:  (XIZ+0x08) u16 count, (XIZ+0x0a) pointer.
; Outputs: for each byte: if it is **0xFA**, `(0x00F328) = 0xFF` and the byte is
;          NOT forwarded; otherwise `0xF992C6(byte)`.
; Evidence: `cp A,0xFA / jr NZ` is the only comparison in the routine; the count
;          is decremented in place at (XIZ+0x08) and the loop ends when it reaches
;          zero.
; ⚠ 0xFA is MIDI's System-Real-Time "Start" and 0xF992C6 is reached from the
;   serial transmit side as well (`calr 0xF992C6` at 0xF992BD and 0xF9950A), so
;   "this is the MIDI OUT path with a transport-start intercept" FITS.  It is NOT
;   ESTABLISHED: 0xF992C6 is not converted and nothing here shows the byte
;   reaching SC0BUF.
; ★ 0x00F328 has five literal-addressed sites and the other four are all in the
;   converted routine at 0xF99553-0xF9958D, which compares it against 0 and 1 and
;   writes 0 and 1 -- so 0xFF here is a third, distinct value written by this one
;   instruction.  Stated as read.
; Unknown:  what 0xF992C6 does; what 0x00F328 selects.
; --------------------------------------------------------------------------
Link_Ch2_ForwardBytes:
	link32 0xEE, 0x0C, 0xFF, 0xFF          ; F98FD6  link XIZ,0xffff   [llvm-mc cannot encode this]
	pushw	hl                               ; F98FDA  push HL
Link_Ch2_ForwardBytes__F98FDB:
	ld	h, (xiz+8)                          ; F98FDB  ld H,(XIZ+0x08)
	ld	c, h                                ; F98FDE  ld C,H
	dec	1, c                               ; F98FE0  dec 1,C
	ld	(xiz-1), c                          ; F98FE2  ld (XIZ+0xff),C
	ld	(xiz+8), c                          ; F98FE5  ld (XIZ+0x08),C
	cps	h, 0                               ; F98FE8  cp H,0
	jr z, Link_Ch2_ForwardBytes__F99017                        ; F98FEA  jr Z,0xf99017
	ld	xbc, (xiz+10)                       ; F98FEC  ld XBC,(XIZ+0x0a)
	ld	a, (xbc)                            ; F98FEF  ld A,(XBC)
	cp	a, 0xFA                             ; F98FF1  cp A,0xfa
	jr nz, Link_Ch2_ForwardBytes__F99003                       ; F98FF4  jr NZ,0xf99003
	stib_da	(0xF328), 0xFF                 ; F98FF6  ld (0x00f328),0xff
	inc	1, xbc                             ; F98FFC  inc 1,XBC
	ld	(xiz+10), xbc                       ; F98FFE  ld (XIZ+0x0a),XBC
	jr Link_Ch2_ForwardBytes__F99015                           ; F99001  jr T,0xf99015
Link_Ch2_ForwardBytes__F99003:
	ld	xbc, (xiz+10)                       ; F99003  ld XBC,(XIZ+0x0a)
	ld	a, (xbc)                            ; F99006  ld A,(XBC)
	extz	wa                                ; F99008  extz WA
	pushw	wa                               ; F9900A  push WA
	inc	1, xbc                             ; F9900B  inc 1,XBC
	ld	(xiz+10), xbc                       ; F9900D  ld (XIZ+0x0a),XBC
	call	0xF992C6                          ; F99010  call 0xf992c6
	popw	bc                                ; F99014  pop BC
Link_Ch2_ForwardBytes__F99015:
	jr Link_Ch2_ForwardBytes__F98FDB                           ; F99015  jr T,0xf98fdb
Link_Ch2_ForwardBytes__F99017:
	popw	hl                                ; F99017  pop HL
	unlk32 xiz                             ; F99018  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; F9901A  ret

; --------------------------------------------------------------------------
; ★★ Link_Ch3_SetTouchControl -- CPU 1 sets the two TOUCH controls.
;
; Called from: entry 3 of Link_ClassHandlerTable (ROM 0xFCC54B).
; Inputs:  (XIZ+0x08) u16 packet length, (XIZ+0x0a) pointer to `{u8 sel, u8 val}`.
; Outputs: nothing unless the length is EXACTLY 2 (`cp (XIZ+0x08),0x02 / jr NZ`);
;          then
;              sel == 0x80  ->  ToneGen_SetVelCurveMode(val)   (0xF99598)
;              sel == 0x90  ->  ToneGen_SetVelOffset(val)      (0xF995AD)
;              anything else -> nothing.
; Evidence: two `cp BC,0x0080` / `cp BC,0x0090` against the first byte, each
;          jumping to a two-instruction arm that pushes the second byte and calls
;          one of the two setters.  0xF995AD is ToneGen_SetVelOffset, checked by
;          disassembling rather than by counting a listing: ToneGen_SetVelCurveMode
;          occupies 0xF99598-0xF995AC (21 bytes, ending in the 0x0E `ret` at
;          0xF995AC), so 0xF995AD is the next routine's `link XIZ,0x0000`.
; ★ THIS ANSWERS BOTH SETTERS' OPEN QUESTION.  ToneGen_SetVelCurveMode's header
;   says "Called from: not traced" and "Unknown: which UI control feeds it", and
;   ToneGen_SetVelOffset's says the same.  Neither is fed by a control on this
;   processor at all: **CPU 1 sends them over the link**, on channel 3, as a
;   two-byte packet.  The UI is on the other CPU, which is why nothing on this one
;   could be found.
; Unknown:  whether sub-selectors other than 0x80 and 0x90 are ever sent.
; --------------------------------------------------------------------------
Link_Ch3_SetTouchControl:
	link32 0xEE, 0x0C, 0xFE, 0xFF          ; F9901B  link XIZ,0xfffe   [llvm-mc cannot encode this]
	cp (xiz+8), 0x02                       ; F9901F  cp (XIZ+0x08),0x02   [llvm-mc cannot encode this]
	jr nz, Link_Ch3_SetTouchControl__F99060                       ; F99023  jr NZ,0xf99060
	ld	xbc, (xiz+10)                       ; F99025  ld XBC,(XIZ+0x0a)
	ld	a, (xbc)                            ; F99028  ld A,(XBC)
	extz	wa                                ; F9902A  extz WA
	ld	(xiz-2), wa                         ; F9902C  ld (XIZ+0xfe),WA
	jr Link_Ch3_SetTouchControl__F99051                           ; F9902F  jr T,0xf99051
Link_Ch3_SetTouchControl__F99031:
	ld	xbc, (xiz+10)                       ; F99031  ld XBC,(XIZ+0x0a)
	ld	a, (xbc+1)                          ; F99034  ld A,(XBC+0x01)
	extz	wa                                ; F99037  extz WA
	pushw	wa                               ; F99039  push WA
	call	0xF99598                          ; F9903A  call 0xf99598
	popw	bc                                ; F9903E  pop BC
	jr Link_Ch3_SetTouchControl__F99060                           ; F9903F  jr T,0xf99060
Link_Ch3_SetTouchControl__F99041:
	ld	xbc, (xiz+10)                       ; F99041  ld XBC,(XIZ+0x0a)
	ld	a, (xbc+1)                          ; F99044  ld A,(XBC+0x01)
	extz	wa                                ; F99047  extz WA
	pushw	wa                               ; F99049  push WA
	call	0xF995AD                          ; F9904A  call 0xf995ad
	popw	bc                                ; F9904E  pop BC
	jr Link_Ch3_SetTouchControl__F99060                           ; F9904F  jr T,0xf99060
Link_Ch3_SetTouchControl__F99051:
	ld	bc, (xiz-2)                         ; F99051  ld BC,(XIZ+0xfe)
	cp	bc, 0x80                            ; F99054  cp BC,0x0080
	jr z, Link_Ch3_SetTouchControl__F99031                        ; F99058  jr Z,0xf99031
	cp	bc, 0x90                            ; F9905A  cp BC,0x0090
	jr z, Link_Ch3_SetTouchControl__F99041                        ; F9905E  jr Z,0xf99041
Link_Ch3_SetTouchControl__F99060:
	unlk32 xiz                             ; F99060  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; F99062  ret
