; ==============================================================================
; Technics SX-WSA1R -- prom_c (CPU 2, IC28) -- 0xF99BBE-0xF99E5D  INT0 and INTTC2/INTTC3: the link's whole receive half
; ==============================================================================
;
; 538 lines moved out of prom_c/wsa1_prom_c.s by notes/prom_c_split.py.  The master
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
; Four adjacent banners: INT0's command dispatcher, its jump table and seven
; arms; the micro-DMA completion handlers; INTTC3's nine state arms.  The
; banners themselves say these are one machine.
;
; >>> END OF EXTRACTION HEADER -- everything below is verbatim from the master

; ==============================================================================
; 0xF99BBE-0xF99C11 -- INT0, the inter-processor command dispatcher
; ==============================================================================
; --------------------------------------------------------------------------
; INT0_HANDLER -- INT0 handler: read a command byte from the CPU-1 link port and
;             dispatch it.
;
; Called from: vector table offset 0x28 (INT0) -> 0x00FFF0B4 (INT0_HANDLER trampoline)
;              -> `jp 0xF99BBE`.
; Inputs:  the byte at 0x00100000, the CS0 inter-processor link port (see
;          notes/FINDINGS-memory-map.md); PA bit 2.
; Outputs: saves the command byte at 0x008518, then jumps through the table
;          below.  If PA bit 2 is set it leaves at once via
;          INT0_HANDLER__return (0xF99CF8).
; Notes:   ★ THE COMMAND RANGE IS READ OFF THE CODE, not assumed:
;              sub bc,0x00E1 / cps bc,6 / jrl ugt -> out of range
;          so the seven dispatched commands are 0xE1..0xE7 and anything else
;          goes to INT0_HANDLER__cmd_E6_or_other (0xF99CCF) -- which is also
;          table entry 5, i.e. command 0xE6's own arm.  0x00100000 is the address
;          RESET programmes CS0 to select, and prom_a's side of the same link is
;          at 0x7C0000.  ★ Round 2 converted all seven arms; their header, just
;          below the table, carries the command -> {state, count, buffer} map and
;          the script that derives it.
;          ⚠ The KN5000 sub-CPU's INT0 handler (../kn5000-roms-disasm/v142/subcpu/
;          kn5000_subprogram_v142.s:2429) reads its link port the same way and
;          also special-cases 0xE1/0xE2/0xE3 -- but it is NOT byte-identical to
;          this one and its dispatch is a chain of compares, not a table.  The
;          command NUMBERS agreeing across the two machines is suggestive; it is
;          not proof that they mean the same thing.
; --------------------------------------------------------------------------
INT0_HANDLER:
	push xbc
	pushw wa
	push xiy
	pushw hl
	push xix
	lda xix, (0x00F9A01F:24)
	bit_dd8 2, PA
	jrl nz, (0x00F99CF8 - 0x00F99BCE)
	ld xbc, 0x00100000
	ld h, (xbc)
	ld (0x008518:24), h
	ld c, h
	extz bc
	extz xbc
	sub bc, 0x00e1
	cps bc, 6
	jrl ugt, (0x00F99CCF - 0x00F99BE9)
	sll bc, 2
	add xbc, 0x00F99BF6
	ld xbc, (xbc)
	jp (xbc)
INT0_HANDLER__jumptable:
	; 7 x u32, indexed by (command - 0xE1).  Every target is inside prom_c, and
	; every one of them is a label defined immediately below.  Note entry 5:
	; command 0xE6 shares INT0_HANDLER__cmd_E6_or_other with the out-of-range path.
	;         0xE1         0xE2         0xE3         0xE4
	.long 0x00F99C12, 0x00F99C32, 0x00F99C52, 0x00F99C72
	;         0xE5         0xE6         0xE7
	.long 0x00F99C91, 0x00F99CCF, 0x00F99CB0


; ==============================================================================
; 0xF99C12-0xF99CFD -- INT0's seven command arms and their shared epilogue
; ==============================================================================
; --------------------------------------------------------------------------
; INT0_HANDLER__cmd_E1 ... __cmd_E7 / __cmd_E6_or_other -- arm micro-DMA channel
;             3 to receive this command's payload, then hand INT0 to the DMA
;             engine so the payload bytes never reach the CPU.
;
; Called from: nothing calls these; they are jumped to.  All seven entries of
;          INT0_HANDLER__jumptable (0xF99BF6, converted above) land here, the
;          table being indexed by (command - 0xE1).  Six entries point at an arm
;          of their own; entry index 5 -- command 0xE6 -- points at
;          INT0_HANDLER__cmd_E6_or_other (0xF99CCF), which is ALSO the target of
;          the out-of-range `jrl ugt` at 0xF99BE9, so that one arm takes 0xE6 and
;          every byte outside 0xE1..0xE7.  (BC is zero-extended from the byte
;          before `sub bc,0x00E1`, so bytes below 0xE1 wrap to a large unsigned
;          value and take the same unsigned-greater-than exit as bytes above
;          0xE7.)
; Inputs:  XIX = 0xF9A01F, loaded by INT0_HANDLER at 0xF99BC3 -- that address is
;          uDMA3_SetDest, converted in this file at 0xF9A01F.  The command byte
;          INT0_HANDLER saved at 0x008518.
; Outputs: DMAD3 = this arm's buffer, DMAC3 = its transfer count, DMA3V = 0x0A,
;          (0x00F32D) = a transfer state, PA bit 1 cleared.  Every arm leaves
;          through INT0_HANDLER__drop_args, which drops the 6 argument bytes and
;          pops the five registers INT0_HANDLER pushed.
; Evidence: each arm is a FIXED seven-instruction shape, so the table below is
;          decoded from the bytes rather than read off:
;              python3 notes/prom_c_link_state_machine.py --selftest
;          prints it and re-proves every field, including the LAST row (0xE7 ->
;          0xF99CB0, state 8) and that the word after the 7-entry jump table
;          (0x00F32DF2) is not a pointer.  It reports "arms matching the fixed
;          shape: 6 of 7" -- the seventh is different BY DESIGN, see below.
;
;          command   arm       state   count   buffer     resume
;            0xE1   0xF99C12     2       6     0x008568   0xF99C29
;            0xE2   0xF99C32     3      10     0x008520   0xF99C49
;            0xE3   0xF99C52     5       4     0x00852D   0xF99C69
;            0xE4   0xF99C72     6       6     0x008568   0xF99C89
;            0xE5   0xF99C91     7       4     0x008531   0xF99CA8
;            0xE7   0xF99CB0     8       6     0x008568   0xF99CC7
;            0xE6 / any other byte:
;                   0xF99CCF     1   (cmd & 0x1F) + 1   0x008548   0xF99CF0
;
;          ★ THE SEVENTH ARM IS THE INTERESTING ONE.  Its transfer count is not a
;          constant: it is the low five bits of the command byte plus one.  So the
;          link protocol is not "seven commands" -- it is six special commands
;          plus a general length-prefixed message whose header byte carries the
;          length in its low 5 bits.  The top 3 bits are then used as a class
;          index by INTTC3_HANDLER__state1_generic (0xF99D6F, below).  That is
;          exactly the header byte notes/FINDINGS-memory-map.md section 3 reports
;          from CPU 1's side, `(channel << 5) | (len - 1)`.
;
;          `ldio DMA3V, 0x0A`: DMA3V is SFR 0x7F (include/tmp95c061_sfr.inc) and
;          the TMP95C061 triggers micro-DMA on `(DMAnV & 0x1f) << 2`
;          (mame/src/devices/cpu/tlcs900/tmp95c061.cpp:353); 0x0A << 2 = 0x28,
;          which the same file's vector map (:322-347) gives as INT0.  So after
;          this write the SAME interrupt that ran this handler is consumed by the
;          DMA engine, one byte per interrupt, and does not reach the CPU again
;          until INTTC3 (the transfer-complete interrupt) re-points it.
;          The other half of that channel is programmed ONCE, at 0xF99966-0xF99977:
;          DMAS3 := 0x00100000 (the inter-processor link port,
;          notes/FINDINGS-memory-map.md) and DMAM3 := 0x00, and mode 0x00 is
;          "byte transfer, DESTINATION incremented" (tmp95c061.cpp:366-371) --
;          i.e. read the fixed port, write successive buffer bytes.  "Once" is
;          measured, not assumed:
;              python3 notes/prom_c_link_state_machine.py --dma
;          censuses every `ldc CRn,r` / `ldc r,CRn` in prom_c naming a micro-DMA
;          control register and finds DMAS3 written at exactly one instruction
;          (0xF9A015) and DMAM3 at exactly one (0xF9A01B), both inside
;          uDMA3_SetSource -- which itself has exactly one call site, 0xF99974.
;          The same census shows EVERY non-spurious micro-DMA register access in
;          the image is inside the helper block 0xF99FF8-0xF9A037.  (⚠ its
;          CR-0x00 rows are byte-pattern noise and are printed as such.)
;          PA is SFR 0x1E.  prom_a's side of the same link does all of this with
;          P7 instead of PA: the notes block above INT0_LinkByte (0xF8E47F) in
;          prom_a/wsa1_prom_a.s records bit 2 tested on entry and bit 1 cleared
;          once the DMA is armed, which is exactly the
;          `bit_dd8 2, PA` at 0xF99BC8 and the `res_dd8 1, PA` in every arm here.
; Unknown:  ⚠ what the commands MEAN.  Only their payload sizes, their landing
;          buffers and their follow-up states are established.  prom_a's header
;          for the same protocol says the same thing and adds "do not name them";
;          that discipline is kept here.
;          ⚠ why 0xE6 shares the generic arm.  It is a table entry like the rest,
;          and it points at the general path; nothing here says whether that is
;          deliberate or the compiler folding an identical body.
; --------------------------------------------------------------------------
; ------------------------- command 0xE1 -------------------------------
INT0_HANDLER__cmd_E1:
	ld (0x00F32D:24), 0x02                     ; F99C12  f2 2d f3 00 00 02   transfer state := 2
	pushw 0x0006                               ; F99C18  0b 06 00   arg2: DMAC3 := 6 transfers
	lda xbc, (0x008568:24)                       ; F99C1B  f2 68 85 00 31
	push xbc                                   ; F99C20  39   arg1: DMAD3 := 0x008568
	lda xiy, (0x00F99C29:24)                     ; F99C21  f2 29 9c f9 35
	push xiy                                   ; F99C26  3d   return address for the tail-jump call
	jp (xix)                                   ; F99C27  b4 d8   XIX = uDMA3_SetDest (0xF9A01F)
INT0_HANDLER__cmd_E1_armed:
	ldio DMA3V, 0x0A                           ; F99C29  08 7f 0a   0x0A << 2 = 0x28 = INT0: the DMA now takes it
	res_dd8 1, PA                              ; F99C2C  f0 1e b1   drop the handshake line
	jrl t, (0x00F99CF6 - 0x00F99C32)           ; F99C2F  78 c4 00   -> INT0_HANDLER__drop_args
; ------------------------- command 0xE2 -------------------------------
INT0_HANDLER__cmd_E2:
	ld (0x00F32D:24), 0x03                     ; F99C32  f2 2d f3 00 00 03   transfer state := 3
	pushw 0x000A                               ; F99C38  0b 0a 00   arg2: DMAC3 := 10 transfers
	lda xbc, (0x008520:24)                       ; F99C3B  f2 20 85 00 31
	push xbc                                   ; F99C40  39   arg1: DMAD3 := 0x008520
	lda xiy, (0x00F99C49:24)                     ; F99C41  f2 49 9c f9 35
	push xiy                                   ; F99C46  3d   return address for the tail-jump call
	jp (xix)                                   ; F99C47  b4 d8   XIX = uDMA3_SetDest (0xF9A01F)
INT0_HANDLER__cmd_E2_armed:
	ldio DMA3V, 0x0A                           ; F99C49  08 7f 0a   0x0A << 2 = 0x28 = INT0: the DMA now takes it
	res_dd8 1, PA                              ; F99C4C  f0 1e b1   drop the handshake line
	jrl t, (0x00F99CF6 - 0x00F99C52)           ; F99C4F  78 a4 00   -> INT0_HANDLER__drop_args
; ------------------------- command 0xE3 -------------------------------
INT0_HANDLER__cmd_E3:
	ld (0x00F32D:24), 0x05                     ; F99C52  f2 2d f3 00 00 05   transfer state := 5
	pushw 0x0004                               ; F99C58  0b 04 00   arg2: DMAC3 := 4 transfers
	lda xbc, (0x00852D:24)                       ; F99C5B  f2 2d 85 00 31
	push xbc                                   ; F99C60  39   arg1: DMAD3 := 0x00852D
	lda xiy, (0x00F99C69:24)                     ; F99C61  f2 69 9c f9 35
	push xiy                                   ; F99C66  3d   return address for the tail-jump call
	jp (xix)                                   ; F99C67  b4 d8   XIX = uDMA3_SetDest (0xF9A01F)
INT0_HANDLER__cmd_E3_armed:
	ldio DMA3V, 0x0A                           ; F99C69  08 7f 0a   0x0A << 2 = 0x28 = INT0: the DMA now takes it
	res_dd8 1, PA                              ; F99C6C  f0 1e b1   drop the handshake line
	jrl t, (0x00F99CF6 - 0x00F99C72)           ; F99C6F  78 84 00   -> INT0_HANDLER__drop_args
; ------------------------- command 0xE4 -------------------------------
INT0_HANDLER__cmd_E4:
	ld (0x00F32D:24), 0x06                     ; F99C72  f2 2d f3 00 00 06   transfer state := 6
	pushw 0x0006                               ; F99C78  0b 06 00   arg2: DMAC3 := 6 transfers
	lda xbc, (0x008568:24)                       ; F99C7B  f2 68 85 00 31
	push xbc                                   ; F99C80  39   arg1: DMAD3 := 0x008568
	lda xiy, (0x00F99C89:24)                     ; F99C81  f2 89 9c f9 35
	push xiy                                   ; F99C86  3d   return address for the tail-jump call
	jp (xix)                                   ; F99C87  b4 d8   XIX = uDMA3_SetDest (0xF9A01F)
INT0_HANDLER__cmd_E4_armed:
	ldio DMA3V, 0x0A                           ; F99C89  08 7f 0a   0x0A << 2 = 0x28 = INT0: the DMA now takes it
	res_dd8 1, PA                              ; F99C8C  f0 1e b1   drop the handshake line
	jr INT0_HANDLER__drop_args                 ; F99C8F  68 65
; ------------------------- command 0xE5 -------------------------------
INT0_HANDLER__cmd_E5:
	ld (0x00F32D:24), 0x07                     ; F99C91  f2 2d f3 00 00 07   transfer state := 7
	pushw 0x0004                               ; F99C97  0b 04 00   arg2: DMAC3 := 4 transfers
	lda xbc, (0x008531:24)                       ; F99C9A  f2 31 85 00 31
	push xbc                                   ; F99C9F  39   arg1: DMAD3 := 0x008531
	lda xiy, (0x00F99CA8:24)                     ; F99CA0  f2 a8 9c f9 35
	push xiy                                   ; F99CA5  3d   return address for the tail-jump call
	jp (xix)                                   ; F99CA6  b4 d8   XIX = uDMA3_SetDest (0xF9A01F)
INT0_HANDLER__cmd_E5_armed:
	ldio DMA3V, 0x0A                           ; F99CA8  08 7f 0a   0x0A << 2 = 0x28 = INT0: the DMA now takes it
	res_dd8 1, PA                              ; F99CAB  f0 1e b1   drop the handshake line
	jr INT0_HANDLER__drop_args                 ; F99CAE  68 46
; ------------------------- command 0xE7 -------------------------------
INT0_HANDLER__cmd_E7:
	ld (0x00F32D:24), 0x08                     ; F99CB0  f2 2d f3 00 00 08   transfer state := 8
	pushw 0x0006                               ; F99CB6  0b 06 00   arg2: DMAC3 := 6 transfers
	lda xbc, (0x008568:24)                       ; F99CB9  f2 68 85 00 31
	push xbc                                   ; F99CBE  39   arg1: DMAD3 := 0x008568
	lda xiy, (0x00F99CC7:24)                     ; F99CBF  f2 c7 9c f9 35
	push xiy                                   ; F99CC4  3d   return address for the tail-jump call
	jp (xix)                                   ; F99CC5  b4 d8   XIX = uDMA3_SetDest (0xF9A01F)
INT0_HANDLER__cmd_E7_armed:
	ldio DMA3V, 0x0A                           ; F99CC7  08 7f 0a   0x0A << 2 = 0x28 = INT0: the DMA now takes it
	res_dd8 1, PA                              ; F99CCA  f0 1e b1   drop the handshake line
	jr INT0_HANDLER__drop_args                 ; F99CCD  68 27
; --------------- command 0xE6 AND every unlisted byte -----------------
INT0_HANDLER__cmd_E6_or_other:
	ld (0x00F32D:24), 0x01                     ; F99CCF  f2 2d f3 00 00 01   transfer state := 1
	ld c, (0x008518:24)                         ; F99CD5  c2 18 85 00 23   the command byte INT0_HANDLER saved
	and c, 0x1f                                ; F99CDA  cb cc 1f   low 5 bits ...
	extz bc                                    ; F99CDD  d9 12
	inc 1, bc                                  ; F99CDF  d9 61   ... + 1 = the payload length
	pushw bc                                   ; F99CE1  29   arg2: DMAC3 := that many transfers
	lda xbc, (0x008548:24)                       ; F99CE2  f2 48 85 00 31
	push xbc                                   ; F99CE7  39   arg1: DMAD3 := 0x008548
	lda xiy, (0x00F99CF0:24)                     ; F99CE8  f2 f0 9c f9 35
	push xiy                                   ; F99CED  3d
	jp (xix)                                   ; F99CEE  b4 d8   XIX = uDMA3_SetDest (0xF9A01F)
INT0_HANDLER__cmd_E6_armed:
	ldio DMA3V, 0x0A                           ; F99CF0  08 7f 0a
	res_dd8 1, PA                              ; F99CF3  f0 1e b1

INT0_HANDLER__drop_args:
	inc 6, xsp                                 ; F99CF6  ef 66   drop the 6 bytes of arguments -- caller-cleaned
INT0_HANDLER__return:
	pop xix                                    ; F99CF8  5c
	popw hl                                    ; F99CF9  4b
	pop xiy                                    ; F99CFA  5d
	popw wa                                    ; F99CFB  48
	pop xbc                                    ; F99CFC  59
	reti                                       ; F99CFD  07

; ==============================================================================
; 0xF99CFE-0xF99D6E -- the micro-DMA completion handlers
; ==============================================================================
; --------------------------------------------------------------------------
; INTTC2_HANDLER -- micro-DMA channel 2 completion.
;
; Called from: vector table offset 0x7C (INTTC2) -> 0x00FFF0C0 -> `jp 0xF99CFE`.
; Inputs:  the state byte at 0x00F32C.
; Outputs: stops the prescaler/timer bit (res 2,(TRUN)) and counts the state byte
;          down: 1 -> 0, 2 -> 1, anything else left alone.
; Notes:   A two-phase transfer state machine, the same shape as the KN5000
;          sub-CPU's MICRODMA_CH2_HANDLER (kn5000_subprogram_v142.s:2499), which
;          also clears a TRUN bit and steps a state byte 2 -> 1 -> 0.  Not
;          byte-identical (different state address, different register), so the
;          resemblance is structural only.
; --------------------------------------------------------------------------
INTTC2_HANDLER:
	res_dd8 2, TRUN
	cpib_da 0x00F32C, 0x01
	jr nz, INTTC2_HANDLER__try2
	ld (0x00F32C:24), 0x00
	jr INTTC2_HANDLER__done
INTTC2_HANDLER__try2:
	cpib_da 0x00F32C, 0x02
	jr nz, INTTC2_HANDLER__done
	ld (0x00F32C:24), 0x01
INTTC2_HANDLER__done:
	reti

; --------------------------------------------------------------------------
; INTTC3_HANDLER -- micro-DMA channel 3 completion; dispatches on a 9-state machine.
;
; Called from: vector table offset 0x80 (INTTC3) -> 0x00FFF0C4 -> `jp 0xF99D20`.
; Inputs:  the 16-bit state at 0x00F32D.
; Outputs: jumps through the table below; state 0 or > 9 falls out to
;          INTTC3_HANDLER__return (0xF99E56).  ★ Round 2 converted all nine
;          arms; their header, just below the table, says which link command
;          reaches which arm and what each one posts.
; Notes:   ★ The state range is read off the code: `dec 1,bc` then `cp bc,0x0008`
;          with an UNSIGNED greater-than exit, so the accepted states are 1..9 and
;          the table has exactly 9 entries -- which is also exactly the space
;          before the first target, 0xF99D6F.
;          `pushw_erp 0xE2` is unidasm's `push QWA`; the llvm-mc backend spells
;          extended-register operands as the raw operand byte.
; --------------------------------------------------------------------------
INTTC3_HANDLER:

	push xbc
	pushw wa
	push xiy
	push xix
	lda xix, (0x008568:24)
	pushw_erp 0xE2
	ld bc, (0x00F32D:24)
	extz bc
	extz xbc
	dec 1, bc
	cp bc, 0x0008
	jrl ugt, (0x00F99E56 - 0x00F99D3E)
	sll bc, 2
	add xbc, 0x00F99D4B
	ld xbc, (xbc)
	jp (xbc)
INTTC3_HANDLER__jumptable:
	; 9 x u32, indexed by (state - 1).  Every target is inside prom_c, is a label
	; defined immediately below, and the first of them, 0xF99D6F, is the byte
	; immediately after this table.
	.long 0x00F99D6F, 0x00F99DAC, 0x00F99DB5, 0x00F99DCC
	.long 0x00F99DDD, 0x00F99DED, 0x00F99E11, 0x00F99E21
	.long 0x00F99E43


; ==============================================================================
; 0xF99D6F-0xF99E5D -- INTTC3's nine state arms and their shared epilogue
; ==============================================================================
; --------------------------------------------------------------------------
; INTTC3_HANDLER__state1_generic ... __state9 -- one arm per transfer state:
;             finish the transfer that just completed, and either post a flag for
;             the service task or arm the NEXT transfer.
;
; Called from: nothing calls these; INTTC3_HANDLER (0xF99D20, converted above)
;          jumps through INTTC3_HANDLER__jumptable (0xF99D4B) indexed by
;          (state - 1).
; Inputs:  the index comes from the 16-bit state variable at 0x00F32D that the
;          INT0 arms wrote.  ⚠ The address above is a VARIABLE, not a call site.  It is stated here rather than in `Called from:` because notes/prom_c_audit_callsites.py harvests every 0xXXXXXX in that paragraph and cannot tell prose from a citation.
;          XIX = 0x008568, loaded by INTTC3_HANDLER at 0xF99D24 -- that is the
;          buffer commands 0xE1/0xE4/0xE7 transfer their six descriptor bytes
;          into, and states 2/6/8 read it back as {u32 destination, u16 count}.
;          The command byte at 0x008518 (state 1 only).
; Outputs: (0x00F32D) := 0 on every terminating arm; PA bit 1 raised again; and
;          one of: a flag bit in 0x00852A/0x00852B/0x00852C, a further micro-DMA
;          transfer armed, or the counter at 0x008535 incremented.
; Evidence: the 9-entry table and which command reaches which arm are decoded
;          from the ROM by
;              python3 notes/prom_c_link_state_machine.py --selftest
;          which prints the state -> handler mapping, checks the LAST entry
;          (state 9 -> 0xF99E43) as well as the first, and shows the word after
;          the table (0x008548F2) is not a pointer.  The same run censuses the
;          state variable completely: over all twelve direct-address spellings
;          0x00F32D has EIGHTEEN literal-addressed references in prom_c --
;          SEVENTEEN immediate byte writes, covering exactly the values 0..9 and
;          all inside 0xF99C12-0xF99FDC, and ONE read, the `ldw_da bc, 0x00F32D`
;          at 0xF99D2C in INTTC3_HANDLER itself.  That is what makes "states 4
;          and 9 are entered from INTTC3, not from an INT0 command" a measurement
;          rather than an impression: 0xF99E07 writes 4 and 0xF99E3B writes 9,
;          and no INT0 arm writes either.  (A write through a pointer register
;          would still be invisible -- see the INTT1_HANDLER header.)
;
;          ★ THIS CLOSES THE Link_ClassHandlerTable QUESTION.  That table's
;          header (below, at 0xFCC53F) said "nothing in prom_c references
;          0xFCC53F as a literal ... what dispatches through it is not traced".
;          Both halves are now answered, and the reason the literal search failed
;          is that the dispatcher does not use the ROM address at all: RESET
;          copies ROM 0xFCB4EA.. to RAM 0x00E2DF (notes/prom_c_ram_image.py), and
;          0xFCC53F - 0xFCB4EA = 0x1055, so the table's RAM copy is at
;          0x00E2DF + 0x1055 = 0x00F334.  `add xbc, 0x0000F334` at 0xF99D91 is
;          that address.  The index is (command byte >> 5) * 4, i.e. the message
;          class in the top three bits, 0..7 -- which is exactly why the table has
;          eight entries.  Reproduce the RAM address and the boot contents with
;              python3 notes/prom_c_ram_image.py 0x00F334:32
;          which prints the eight pointers 0xF98D9A, 0xF98DE6, 0xF98FD6, 0xF9901B
;          and then 0xF9993D four times.
;
;          ★ AND IT CONFIRMS THE 0xE2 PACKET LAYOUT FROM THE RECEIVING SIDE.
;          notes/FINDINGS-memory-map.md section 3 derives, from prom_a alone, that
;          command 0xE2 carries a 10-byte packet laid out {+0 remote address u32,
;          +4 local destination u32, +8 length u16}.  Here the 0xE2 arm transfers
;          exactly 10 bytes to 0x008520, and the routine at 0xF99E5F that state 3
;          wakes reads 0x008524 (u32), 0x008528 (u16) and 0x008520 (u32) in that
;          order and passes them as three arguments.  Two independent images, one
;          layout.
;
;          The three flag bytes these arms post to are each fully censused by
;              python3 notes/prom_c_link_state_machine.py --flags
;          (all twelve direct spellings).  0x00852A/B/C have SEVENTEEN sites
;          between them, spanning 0xF99AAE-0xF99FE5 -- note that the top of that
;          span is inside Link_WaitBlockDone, NOT inside this block:
;            0x00852A -- 3 sites.  set 7 HERE (state 3, 0xF99DC4); bit 7 tested at
;                        0xF99E67 and cleared at 0xF99E6E, both in the routine at
;                        0xF99E5F.  A one-bit "0xE2 packet ready" handshake.
;            0x00852B -- 4 sites.  set 7 at 0xF99AAE, immediately after micro-DMA
;                        channel 2 is armed and TRUN bit 2 set (an OUTGOING
;                        transfer starting); cleared HERE by state 4 (0xF99DD2)
;                        and by Link_WaitBlockDone's timeout path (0xF99FE5),
;                        which is also its only reader (0xF99FC6).
;            0x00852C -- 10 sites.  bits 7/6/5 set HERE by states 5/7/9
;                        (0xF99DE3, 0xF99E17, 0xF99E49) and each tested and
;                        cleared by the routine at 0xF99E5F (0xF99E92/0xF99E99,
;                        0xF99ECD/0xF99ED4, 0xF99F06/0xF99F0D); bit 5 is also set
;                        at 0xF99F48.  A three-bit work-request byte.
;          0x008535, incremented by state 9 (0xF99E4E), has 5 sites: cleared at
;          0xF99951 and 0xF99EA6, compared against C at 0xF99F3F and 0xF99F65.
;          It IS read.  Adding it and 0x008519 to the census gives 23 sites over
;          0xF99951-0xF99FE5, which is the whole link subsystem.
; Unknown:  ⚠ WHAT the three flags MEAN -- which link exchange each one belongs to
;          is not established, only which code sets and clears it.
;          ⚠ why states 6 and 8 force the destination into 0x010000-0x01FFFF with
;          `and 0xFFFF` + `add 0x00010000` while state 2 uses the descriptor's
;          full 32-bit address.  Per notes/FINDINGS-memory-map.md that range is
;          CS3, the same chip select as the work DRAM, but its upper half is
;          listed there as NOT ESTABLISHED.
;          ⚠ 0x008519 := 0xFF (state 3) is the ONLY literal-addressed reference
;          to 0x008519 in the whole image -- written once, never read.  Either a
;          pointer-based reader exists (invisible to any literal census) or it is
;          dead.  Stated as measured; not called dead.
; --------------------------------------------------------------------------
; ---- state 1: a generic length-prefixed message; dispatch on the top 3 bits ----
INTTC3_HANDLER__state1_generic:
	lda xbc, (0x008548:24)                       ; F99D6F  f2 48 85 00 31
	push xbc                                   ; F99D74  39   arg2 (XSP+6): the buffer the payload landed in
	ld a, (0x008518:24)                         ; F99D75  c2 18 85 00 21   the command byte INT0_HANDLER saved
	and a, 0x1f                                ; F99D7A  c9 cc 1f
	extz wa                                    ; F99D7D  d8 12
	inc 1, wa                                  ; F99D7F  d8 61
	pushw wa                                   ; F99D81  28   arg1 (XSP+4): (cmd & 0x1F) + 1 = payload length
	ld w, (0x008518:24)                         ; F99D82  c2 18 85 00 20
	srl w, 5                                   ; F99D87  c8 ef 05   the top 3 bits = the message class, 0..7
	ld c, w                                    ; F99D8A  c8 8b
	mul c, 4                                   ; F99D8C  cb 08 04   x 4: these are 32-bit pointers
	extz xbc                                   ; F99D8F  e9 12
	add xbc, 0x0000F334                        ; F99D91  e9 c8 34 f3 00 00   the RAM copy of Link_ClassHandlerTable
	ld xbc, (xbc)                              ; F99D97  a1 21
	lda xiy, (0x00F99DA1:24)                     ; F99D99  f2 a1 9d f9 35
	push xiy                                   ; F99D9E  3d   return address for the tail-jump call
	jp (xbc)                                   ; F99D9F  b1 d8   call the class handler
INTTC3_HANDLER__state1_done:
	ld (0x00F32D:24), 0x00                     ; F99DA1  f2 2d f3 00 00 00   transfer state := idle
	set_dd8 1, PA                              ; F99DA7  f0 1e b9   raise the handshake line again
	jr INTTC3_HANDLER__drop_args               ; F99DAA  68 61

; ---- state 2: the 0xE1 descriptor has landed -- arm the payload transfer ----
INTTC3_HANDLER__state2_block:
	ld bc, (xix+4)                             ; F99DAC  9c 04 21   descriptor +4: the 16-bit count
	pushw bc                                   ; F99DAF  29
	ld xbc, (xix)                              ; F99DB0  a4 21   descriptor +0: the 32-bit destination
	push xbc                                   ; F99DB2  39
	jr INTTC3_HANDLER__arm_payload             ; F99DB3  68 4b

; ---- state 3: the 0xE2 packet has landed -- hand it to the service task ----
INTTC3_HANDLER__state3_packet:
	ld (0x008519:24), 0xff                     ; F99DB5  f2 19 85 00 00 ff
	ld (0x00F32D:24), 0x00                     ; F99DBB  f2 2d f3 00 00 00   transfer state := idle
	set_dd8 1, PA                              ; F99DC1  f0 1e b9
	set 7, (0x00852A:24)                       ; F99DC4  f2 2a 85 00 bf   post 'packet ready' to the service task at 0xF99E5F
	jrl t, (0x00F99E56 - 0x00F99DCC)           ; F99DC9  78 8a 00   -> INTTC3_HANDLER__return

; ---- state 4: a payload transfer finished ----
INTTC3_HANDLER__state4_blockdone:
	ld (0x00F32D:24), 0x00                     ; F99DCC  f2 2d f3 00 00 00   transfer state := idle
	res 7, (0x00852B:24)                       ; F99DD2  f2 2b 85 00 b7   release Link_WaitBlockDone (0xF99FC1)
	set_dd8 1, PA                              ; F99DD7  f0 1e b9
	jrl t, (0x00F99E56 - 0x00F99DDD)           ; F99DDA  78 79 00   -> INTTC3_HANDLER__return

; ---- state 5: the 0xE3 payload has landed ----
INTTC3_HANDLER__state5:
	ld (0x00F32D:24), 0x00                     ; F99DDD  f2 2d f3 00 00 00
	set 7, (0x00852C:24)                       ; F99DE3  f2 2c 85 00 bf
	set_dd8 1, PA                              ; F99DE8  f0 1e b9
	jr INTTC3_HANDLER__return                  ; F99DEB  68 69

; ---- state 6: the 0xE4 descriptor has landed -- same, but banked ----
INTTC3_HANDLER__state6_block_banked:
	ld bc, (xix+4)                             ; F99DED  9c 04 21   descriptor +4: the 16-bit count
	pushw bc                                   ; F99DF0  29
	ld xbc, (xix)                              ; F99DF1  a4 21   descriptor +0: the destination
	and xbc, 0x0000FFFF                        ; F99DF3  e9 cc ff ff 00 00
	add xbc, 0x00010000                        ; F99DF9  e9 c8 00 00 01 00   forced into 0x010000-0x01FFFF
	push xbc                                   ; F99DFF  39
INTTC3_HANDLER__arm_payload:
	call 0x00F9A01F                            ; F99E00  1d 1f a0 f9   uDMA3_SetDest: DMAD3 := dest, DMAC3 := count
	ldio DMA3V, 0x0A                           ; F99E04  08 7f 0a   re-point INT0 at the DMA engine
	ld (0x00F32D:24), 0x04                     ; F99E07  f2 2d f3 00 00 04   transfer state := 4 (payload in flight)
INTTC3_HANDLER__drop_args:
	inc 6, xsp                                 ; F99E0D  ef 66   drop the 6 bytes of arguments -- caller-cleaned
	jr INTTC3_HANDLER__return                  ; F99E0F  68 45

; ---- state 7: the 0xE5 payload has landed ----
INTTC3_HANDLER__state7:
	ld (0x00F32D:24), 0x00                     ; F99E11  f2 2d f3 00 00 00
	set 6, (0x00852C:24)                       ; F99E17  f2 2c 85 00 be
	set_dd8 1, PA                              ; F99E1C  f0 1e b9
	jr INTTC3_HANDLER__return                  ; F99E1F  68 35

; ---- state 8: the 0xE7 descriptor has landed -- banked, then state 9 ----
INTTC3_HANDLER__state8_block_banked:
	ld bc, (xix+4)                             ; F99E21  9c 04 21
	pushw bc                                   ; F99E24  29
	ld xbc, (xix)                              ; F99E25  a4 21
	and xbc, 0x0000FFFF                        ; F99E27  e9 cc ff ff 00 00
	add xbc, 0x00010000                        ; F99E2D  e9 c8 00 00 01 00
	push xbc                                   ; F99E33  39
	call 0x00F9A01F                            ; F99E34  1d 1f a0 f9   uDMA3_SetDest
	ldio DMA3V, 0x0A                           ; F99E38  08 7f 0a
	ld (0x00F32D:24), 0x09                     ; F99E3B  f2 2d f3 00 00 09   transfer state := 9, NOT 4
	jr INTTC3_HANDLER__drop_args               ; F99E41  68 ca

; ---- state 9: the 0xE7 payload has landed ----
INTTC3_HANDLER__state9:
	ld (0x00F32D:24), 0x00                     ; F99E43  f2 2d f3 00 00 00
	set 5, (0x00852C:24)                       ; F99E49  f2 2c 85 00 bd
	inc 1, (0x008535:24)                      ; F99E4E  c2 35 85 00 61   a counter, incremented only here
	set_dd8 1, PA                              ; F99E53  f0 1e b9
INTTC3_HANDLER__return:
	popw_erp 0xE2                              ; F99E56  d7 e2 05   pop QWA -- matches the pushw_erp in the prologue
	pop xix                                    ; F99E59  5c
	pop xiy                                    ; F99E5A  5d
	popw wa                                    ; F99E5B  48
	pop xbc                                    ; F99E5C  59
	reti                                       ; F99E5D  07

; --------------------------------------------------------------------------
; INTT2_HANDLER -- timer 2 interrupt: acknowledge and return, nothing else.
;
; Called from: vector table offset 0x48 (INTT2) -> 0x00FFF0B8 -> `jp 0xF99E5E`.
; Inputs:  none.  Outputs: none.
; Notes:   A single 0x07 RETI byte.  It is not dead code: the vector table
;          comment at 0x48 records that this is the interrupt CPU 2's micro-DMA
;          channel 2 is armed on (DMA2V = 0x12 at 0xF99A2A), and a micro-DMA
;          channel needs its interrupt to fire and be dismissed for the transfer
;          to be paced.  The byte before it, 0xF99E5D, is the RETI of a different
;          routine, so this really is a one-instruction handler and not a tail.
; --------------------------------------------------------------------------
INTT2_HANDLER:
	reti
