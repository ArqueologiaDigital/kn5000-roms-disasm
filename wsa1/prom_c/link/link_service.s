; ==============================================================================
; Technics SX-WSA1R -- prom_c (CPU 2, IC28) -- 0xF99E5F-0xF9A04F  Link_ServiceTask, the link wait, uDMA and the block move
; ==============================================================================
;
; 548 lines moved out of prom_c/wsa1_prom_c.s by notes/prom_c_split.py.  The master
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
; Two adjacent banners: the DEFERRED half of the link (the task that runs the
; three flash jobs INT0 queues) and the transfer primitives under it.  The
; last eight are byte-identical to prom_a's, which is where their names come
; from.
;
; >>> END OF EXTRACTION HEADER -- everything below is verbatim from the master

; ==============================================================================
; 0xF99E5F-0xF99FC0 -- Link_ServiceTask: the deferred half of the link, and the
;                      micro-DMA stall watchdog.  One routine, 354 bytes
; ==============================================================================
;
; `notes/FINDINGS-prom_c-link-receive.md` names this address seven times without
; being able to say what it does -- "the routine at 0xF99E5F" tests and clears
; every flag INT0_HANDLER and INTTC3_HANDLER post, and its own header list ends
; "**0xF99E5F-0xF99FC0 is the consumer** of every flag in §3 and is still
; `.incbin`.  Converting it should name the flags."  This is that conversion.
;
; ★★ IT ANSWERS THE 0xE2 REQUEST WITH AN 0xE1 REPLY, AND THAT PINS THE PACKET
; LAYOUT FROM CPU 2'S OWN CODE.  `INT0_HANDLER__cmd_E2` (converted above) points
; micro-DMA channel 3 at 0x008520 for ten bytes, and `INTTC3_HANDLER__state3_packet`
; sets bit 7 of 0x00852A when they have landed.  The first thing this routine does
; is take that bit down and call
;
;     Link_SendCmdE1( (0x008520) u32, (0x008528) u16, (0x008524) u32 )
;
; -- and Link_SendCmdE1 DEREFERENCES its first argument as the source of the
; payload transfer and puts its third into the 6-byte header packet.  So, entirely
; from prom_c:
;
;     0xE2 packet +0x00  u32  the address to read ON THIS PROCESSOR
;                 +0x04  u32  the destination ON THE OTHER ONE
;                 +0x08  u16  the length
;
; ★ Command 0xE2 is a REMOTE READ REQUEST and command 0xE1 is the WRITE that
; answers it.  `notes/FINDINGS-memory-map.md` §3 states the same three fields from
; CPU 1's two callers of its own 0xE2 sender; this is the independent confirmation
; from the answering side, and it removes the "carried from prom_a" caveat that
; Link_SendCmdE2_MemRead's header still has to carry for the sending direction.
;
; ★ THE THREE REQUEST BITS OF 0x00852C, NOW MATCHED TO THEIR CONSUMERS.
; INTTC3_HANDLER's states 5, 7 and 9 set bits 7, 6 and 5 (0xF99DE3, 0xF99E17,
; 0xF99E49) and this routine is where each is tested and cleared -- the existing
; INTTC3 header already says so, and now says what happens next:
;
;     bit 7  ->  clear 0x008537, 0x008535 and 0x008536, then
;                0xFC89AF((0x00852D)), 0xFC856C(), 0xFC8646((0x00852D))
;     bit 6  ->  0xFC856C(), then poll 0xFC898F((0x008531)) until it stops
;                returning 0xFFFF, then 0xFC88F9((0x008531)), then
;                Link_SendCmdByte(6) -- i.e. the bare command 0xE6 goes back
;     bit 5  ->  walk the index at 0x008536 up to the count at 0x008535, calling
;                0xFC893B(index) for each
;
; ⚠ None of 0xFC856C / 0xFC8646 / 0xFC88F9 / 0xFC893B / 0xFC898F / 0xFC89AF is
; converted, so what the three jobs DO is still unknown.  What is established is
; the handshake: which ISR raises which bit, and which call sequence answers it.
;
; ★ 0x008535/0x008536 ARE A PRODUCER/CONSUMER PAIR.  0x008535 is incremented by
; INTTC3 state 9 and by nothing else; 0x008536 is the index this routine walks and
; is loaded into XIX at entry (`lda XIX,0x008536` -- the only such instruction in
; the image).  The two loops at 0xF99F2D and 0xF99F59 both run `while (XIX) <
; (0x008535)`, so 0x008535 counts what arrived and 0x008536 counts what has been
; handed on.
;
; ★★ THE MICRO-DMA STALL WATCHDOG.  The last third of the routine, 0xF99F6E
; onward, is not part of any flag:
;
;     if PA bit 1 is clear:                      ; a transfer is outstanding
;         n = uDMA3_GetCount()                   ; DMAC3, bytes still to move
;         if n == (0x00F331):  (0x00F32F) += 1   ; no progress this pass
;         else:                (0x00F32F) = 0
;         (0x00F331) = uDMA3_GetCount()          ; remember it
;     else:
;         (0x00F32F) = 0
;     if (0x00F32F) > 10:
;         (0x00F32F) = 0;  DMA3V := 0;  (0x00F32D) := 0;  set PA bit 1;
;         (0x00F32E) += 1
;
; So ten consecutive service passes with the INBOUND byte count unchanged abort the
; transfer: the channel is unhooked from INT0, the transfer state goes idle, the
; handshake line is raised, and a counter is bumped.  This is the receive-side twin
; of Link_WaitBlockDone's 500-tick timeout on the transmit side, and it uses the
; same three actions.
; ⚠ `(0x00F32E)` is incremented here and referenced NOWHERE else in the image
; (`notes/prom_c_xrefs.py 0x00F32E --no-window --classify`: one site).  Written,
; never read by anything that names it.
; ⚠ The threshold is a comparison against 0x000A with `jr ULE`, so the abort needs
; ELEVEN unchanged passes, not ten.  Stated as the instruction reads.
;
; ⚠ EVERY FLAG TEST IS BRACKETED BY `ei 6` AND `di`, AND THAT IS NOT WHAT IT
; LOOKS LIKE.  llvm-mc's `di` assembles to the byte pair `06 00`, which is `EI 0`:
; op_EI writes the immediate into SR bits 6..4
; (mame/src/devices/cpu/tlcs900/900tbl.hxx:2073-2078) and tlcs900_check_irqs scans
; interrupt priorities from `max(1, (SR>>4)&7)` up to 6 (tmp95c061.cpp:536-545), so
; a level of 0 accepts EVERY maskable interrupt and a level of 7 accepts none;
; reset leaves the field at 7 (`m_sr.d = 0xf800`, "iff set to 111",
; tlcs900.cpp:213-220).  So each flag is read with the level RAISED to 6 -- almost
; everything blocked -- and the job that follows runs with the level back at 0.
; The flags are written by ISRs, which is why the read is guarded.
; ★ This is a correction to two headers earlier in this file, which read `di` as a
; disable; both now carry the citation.  The bytes were never in doubt -- only the
; reading -- which is precisely the kind of error the byte gate cannot see.

; --------------------------------------------------------------------------
; ★★ Link_ServiceTask -- the deferred half of the inter-processor link.
;
; Called from: 0xF98C1A (`call 0xF99E5F`), inside MAIN's phase-4 job.  One site.
; Inputs:  that arm is guarded by bit 4 of the scheduler work byte 0x007ED1, which
;          INTT1_HANDLER sets once every six ticks.  ⚠ The address above is a VARIABLE, not a call site.  It is stated here rather than in `Called from:` because notes/prom_c_audit_callsites.py harvests every 0xXXXXXX in that paragraph and cannot tell prose from a citation.
;          Then: the flag bits 0x00852A.7 and 0x00852C.7/6/5, the parameter blocks at
;          0x008520 (10 bytes), 0x00852D (u32) and 0x008531 (u32), the counter
;          pair 0x008535/0x008536, and micro-DMA channel 3's remaining count.
; Outputs: one 0xE1 reply, three job sequences, and the stall abort -- all four
;          described in the block comment above.  XIX is saved and restored; the
;          routine has NO stack frame (`push XIX` and not `link`).
; Evidence: every claim above is one of
;          * an instruction in this routine, cited by address;
;          * a census over all twelve direct-address spellings
;            (`notes/prom_c_xrefs.py <addr> --no-window --classify`) for
;            0x00852A (3 sites), 0x00852C (10), 0x008535 (5), 0x008536 (2),
;            0x008537 (4), 0x00F32F (5), 0x00F331 (2) and 0x00F32E (1);
;          * a converted routine elsewhere in this file -- INT0_HANDLER__cmd_E2
;            for where the 10-byte packet comes from, INTTC3_HANDLER states 3/5/7/9
;            for who raises each bit, uDMA3_GetCount for what 0xF9A030 returns.
; ★★ WHAT THE THREE JOBS ARE -- SOLVED IN ROUND 4.  The header used to read
;          "Unknown: the six 0xFC8xxx routines the three jobs call".  All six are
;          the FLASH DRIVER, converted below at 0xFC856C-0xFC89C4:
;            0xFC89AF Flash_ReadSectorToBuffer    0xFC8646 Flash_SectorErase
;            0xFC856C Flash_ReadResetMode         0xFC898F Flash_SectorBlankCheck
;            0xFC88F9 Flash_ProgramSectorFromBuffer
;            0xFC893B Flash_ProgramSlice1K
;          so the three jobs read:
;            bit 7 -> copy sector (0x00852D) into the 64 KiB RAM buffer at
;                     0x00010000, then erase that sector
;            bit 6 -> wait for the erase, burn the whole buffer back into sector
;                     (0x008531), then Link_SendCmdByte(6) = command 0xE6 to CPU 1
;            bit 5 -> burn the 1 KiB slices that have arrived, one per index
;          ★ THE INTER-PROCESSOR LINK IS A FLASH DOWNLOAD PATH.  Command 0xE2 is
;          CPU 2 asking CPU 1 to read, 0xE1 is the write that answers, micro-DMA
;          channel 3 lands the payload, and 0xE6 acknowledges a committed sector.
;          ⚠ WHAT THE DOWNLOADED BYTES ARE is still not established.
; Unknown:  what 0x008537 gates (it is set to 1 by the bit-5 job's first loop and
;          tested by its second); and what reads 0x00F32E.
; --------------------------------------------------------------------------
Link_ServiceTask:
	push	xix                               ; F99E5F  push XIX
	lda	xix, (0x8536:24)                   ; F99E60  lda XIX,0x008536
	ei	6                                   ; F99E65  ei 0x06
	extpfx5 0xF2, 0x2A, 0x85, 0x00, 0xCF   ; F99E67  bit 7,(0x00852a)   [llvm-mc cannot encode this]
	jr z, Link_ServiceTask__F99E8E                        ; F99E6C  jr Z,0xf99e8e
	extpfx5 0xF2, 0x2A, 0x85, 0x00, 0xB7   ; F99E6E  res 7,(0x00852a)   [llvm-mc cannot encode this]
	ei	0                                     ; F99E73  ei 0x00
	ld	xbc, (0x8524:24)                   ; F99E75  ld XBC,(0x008524)
	push	xbc                               ; F99E7A  push XBC
	ld	bc, (0x8528:24)                    ; F99E7B  ld BC,(0x008528)
	pushw	bc                               ; F99E80  push BC
	ld	xbc, (0x8520:24)                   ; F99E81  ld XBC,(0x008520)
	push	xbc                               ; F99E86  push XBC
	calr (0xF99B0D - 0xF99E8A)             ; F99E87  calr 0xf99b0d
	inc	8, xsp                             ; F99E8A  inc 0,XSP
	inc	2, xsp                             ; F99E8C  inc 2,XSP
Link_ServiceTask__F99E8E:
	ei	0                                     ; F99E8E  ei 0x00
	ei	6                                   ; F99E90  ei 0x06
	extpfx5 0xF2, 0x2C, 0x85, 0x00, 0xCF   ; F99E92  bit 7,(0x00852c)   [llvm-mc cannot encode this]
	jr z, Link_ServiceTask__F99EC9                        ; F99E97  jr Z,0xf99ec9
	extpfx5 0xF2, 0x2C, 0x85, 0x00, 0xB7   ; F99E99  res 7,(0x00852c)   [llvm-mc cannot encode this]
	ei	0                                     ; F99E9E  ei 0x00
	ld	(0x8537:24), 0                    ; F99EA0  ld (0x008537),0x00
	ld	(0x8535:24), 0                    ; F99EA6  ld (0x008535),0x00
	ld	(xix), 0                            ; F99EAC  ld (XIX),0x00
	ld	xbc, (0x852D:24)                   ; F99EAF  ld XBC,(0x00852d)
	push	xbc                               ; F99EB4  push XBC
	call	0xFC89AF                          ; F99EB5  call 0xfc89af
	call	0xFC856C                          ; F99EB9  call 0xfc856c
	ld	xbc, (0x852D:24)                   ; F99EBD  ld XBC,(0x00852d)
	push	xbc                               ; F99EC2  push XBC
	call	0xFC8646                          ; F99EC3  call 0xfc8646
	inc	8, xsp                             ; F99EC7  inc 0,XSP
Link_ServiceTask__F99EC9:
	ei	0                                     ; F99EC9  ei 0x00
	ei	6                                   ; F99ECB  ei 0x06
	extpfx5 0xF2, 0x2C, 0x85, 0x00, 0xCE   ; F99ECD  bit 6,(0x00852c)   [llvm-mc cannot encode this]
	jr z, Link_ServiceTask__F99F02                        ; F99ED2  jr Z,0xf99f02
	extpfx5 0xF2, 0x2C, 0x85, 0x00, 0xB6   ; F99ED4  res 6,(0x00852c)   [llvm-mc cannot encode this]
	ei	0                                     ; F99ED9  ei 0x00
	call	0xFC856C                          ; F99EDB  call 0xfc856c
Link_ServiceTask__F99EDF:
	ld	xbc, (0x8531:24)                   ; F99EDF  ld XBC,(0x008531)
	push	xbc                               ; F99EE4  push XBC
	call	0xFC898F                          ; F99EE5  call 0xfc898f
	pop	xiy                                ; F99EE9  pop XIY
	cp	wa, 0xFFFF                          ; F99EEA  cp WA,0xffff
	jr z, Link_ServiceTask__F99EDF                        ; F99EEE  jr Z,0xf99edf
	ld	xbc, (0x8531:24)                   ; F99EF0  ld XBC,(0x008531)
	push	xbc                               ; F99EF5  push XBC
	call	0xFC88F9                          ; F99EF6  call 0xfc88f9
	pushw	6                                ; F99EFA  push 0x0006
	calr (0xF99AC3 - 0xF99F00)             ; F99EFD  calr 0xf99ac3
	inc	6, xsp                             ; F99F00  inc 6,XSP
Link_ServiceTask__F99F02:
	ei	0                                     ; F99F02  ei 0x00
	ei	6                                   ; F99F04  ei 0x06
	extpfx5 0xF2, 0x2C, 0x85, 0x00, 0xCD   ; F99F06  bit 5,(0x00852c)   [llvm-mc cannot encode this]
	jr z, Link_ServiceTask__F99F6C                        ; F99F0B  jr Z,0xf99f6c
	extpfx5 0xF2, 0x2C, 0x85, 0x00, 0xB5   ; F99F0D  res 5,(0x00852c)   [llvm-mc cannot encode this]
	ei	0                                     ; F99F12  ei 0x00
	ld	c, (xix)                            ; F99F14  ld C,(XIX)
	cps	c, 0                               ; F99F16  cp C,0
	jr nz, Link_ServiceTask__F99F4F                       ; F99F18  jr NZ,0xf99f4f
	ld	xbc, (0x8568:24)                   ; F99F1A  ld XBC,(0x008568)
	push	xbc                               ; F99F1F  push XBC
	call	0xFC898F                          ; F99F20  call 0xfc898f
	pop	xiy                                ; F99F24  pop XIY
	cp	wa, 0xFFFF                          ; F99F25  cp WA,0xffff
	jr z, Link_ServiceTask__F99F48                        ; F99F29  jr Z,0xf99f48
	jr Link_ServiceTask__F99F3D                           ; F99F2B  jr T,0xf99f3d
Link_ServiceTask__F99F2D:
	ld	c, (xix)                            ; F99F2D  ld C,(XIX)
	pushw	bc                               ; F99F2F  push BC
	incm8	1, (xix)                         ; F99F30  inc 1,(XIX)
	call	0xFC893B                          ; F99F32  call 0xfc893b
	ld	(0x8537:24), 1                    ; F99F36  ld (0x008537),0x01
	popw	bc                                ; F99F3C  pop BC
Link_ServiceTask__F99F3D:
	ld	c, (xix)                            ; F99F3D  ld C,(XIX)
	extpfx5 0xC2, 0x35, 0x85, 0x00, 0xF3   ; F99F3F  cp C,(0x008535)   [llvm-mc cannot encode this]
	jr c, Link_ServiceTask__F99F2D                        ; F99F44  jr C,0xf99f2d
	jr Link_ServiceTask__F99F6C                           ; F99F46  jr T,0xf99f6c
Link_ServiceTask__F99F48:
	set 5, (0x00852C:24)                   ; F99F48  set 5,(0x00852c)   [llvm-mc cannot encode this]
	jr Link_ServiceTask__F99F6C                           ; F99F4D  jr T,0xf99f6c
Link_ServiceTask__F99F4F:
	cpib_da 0x008537, 0x01                 ; F99F4F  cp (0x008537),0x01   [llvm-mc cannot encode this]
	jr nz, Link_ServiceTask__F99F6C                       ; F99F55  jr NZ,0xf99f6c
	jr Link_ServiceTask__F99F63                           ; F99F57  jr T,0xf99f63
Link_ServiceTask__F99F59:
	ld	c, (xix)                            ; F99F59  ld C,(XIX)
	pushw	bc                               ; F99F5B  push BC
	incm8	1, (xix)                         ; F99F5C  inc 1,(XIX)
	call	0xFC893B                          ; F99F5E  call 0xfc893b
	popw	bc                                ; F99F62  pop BC
Link_ServiceTask__F99F63:
	ld	c, (xix)                            ; F99F63  ld C,(XIX)
	extpfx5 0xC2, 0x35, 0x85, 0x00, 0xF3   ; F99F65  cp C,(0x008535)   [llvm-mc cannot encode this]
	jr c, Link_ServiceTask__F99F59                        ; F99F6A  jr C,0xf99f59
Link_ServiceTask__F99F6C:
	ei	0                                     ; F99F6C  ei 0x00
	bit_dd8	1, PA                          ; F99F6E  bit 1,(0x1e)
	jr nz, Link_ServiceTask__F99F97                       ; F99F71  jr NZ,0xf99f97
	call	0xF9A030                          ; F99F73  call 0xf9a030
	cpdm16_24	(0xF331), wa                 ; F99F77  cp (0x00f331),WA
	jr nz, Link_ServiceTask__F99F85                       ; F99F7C  jr NZ,0xf99f85
	incw	1, (0xF32F:24)                 ; F99F7E  incw 1,(0x00f32f)
	jr Link_ServiceTask__F99F8C                           ; F99F83  jr T,0xf99f8c
Link_ServiceTask__F99F85:
	ldw	(0xF32F:24), 0                    ; F99F85  ld (0x00f32f),0x0000
Link_ServiceTask__F99F8C:
	call	0xF9A030                          ; F99F8C  call 0xf9a030
	ld	(0xF331:24), wa                    ; F99F90  ld (0x00f331),WA
	jr Link_ServiceTask__F99F9E                           ; F99F95  jr T,0xf99f9e
Link_ServiceTask__F99F97:
	ldw	(0xF32F:24), 0                    ; F99F97  ld (0x00f32f),0x0000
Link_ServiceTask__F99F9E:
	extpfx7 0xD2, 0x2F, 0xF3, 0x00, 0x3F, 0x0A, 0x00 ; F99F9E  cp (0x00f32f),0x000a   [llvm-mc cannot encode this]
	jr ule, Link_ServiceTask__F99FBF                      ; F99FA5  jr ULE,0xf99fbf
	ldw	(0xF32F:24), 0                    ; F99FA7  ld (0x00f32f),0x0000
	ldio	DMA3V, 0                          ; F99FAE  ld (0x7f),0x00
	ld	(0xF32D:24), 0                    ; F99FB1  ld (0x00f32d),0x00
	set_dd8	1, PA                          ; F99FB7  set 1,(0x1e)
	inc	1, (0xF32E:24)                  ; F99FBA  inc 1,(0x00f32e)
Link_ServiceTask__F99FBF:
	pop	xix                                ; F99FBF  pop XIX
	ret                                    ; F99FC0  ret

; ==============================================================================
; 0xF99FC1-0xF9A04F -- the link wait, and the micro-DMA / block-move runtime
; ==============================================================================
; --------------------------------------------------------------------------
; Link_WaitBlockDone -- block until the outstanding link transfer finishes, or
;             500 ticks pass; abort it if they do.
;
; Called from: not yet traced.  notes/prom_c_xrefs.py 0xF99FC1 finds no absolute
;          literal and no calr displacement, and short PC-relative forms are not
;          searched, so this is "not found", not "nothing calls it".
; Inputs:  bit 7 of (0x00852B); the INTT1 tick counter at 0x00F2F3, read as 16
;          bits.
; Outputs: WA = 0 if the flag cleared in time, 0xFFFF if it did not.  On timeout
;          it also aborts: DMA3V := 0, (0x00F32D) := 0, PA bit 1 raised, bit 7 of
;          (0x00852B) cleared, and the counter at 0x00F333 incremented.  HL saved.
; Evidence: this is prom_a's Link_WaitBlockDone (0xF8E66D in
;          prom_a/wsa1_prom_a.s) rewritten for CPU 2's addresses.  The two
;          routines are the SAME FIFTEEN INSTRUCTIONS in the same order with the
;          same opcodes -- push HL / load tick / poll flag / re-load tick /
;          subtract / cp 0x01F4 / loop / DMAnV:=0 / state:=0 / set port bit 1 /
;          clear flag / bump a counter / WA:=0xFFFF / else WA:=0 / pop HL / ret --
;          and only the operand addresses differ:
;
;              role                     prom_a          prom_c
;              tick counter             (0x0080)        (0x00F2F3)
;              outstanding flag         (0x00008A) b7   (0x00852B) b7
;              transfer state           (0x6007DA)      (0x00F32D)
;              handshake port           P7 (0x13) b1    PA (0x1E) b1
;              timeout counter          (0x6007E1)      (0x00F333)
;              timeout                  0x01F4 = 500    0x01F4 = 500
;
;          They are NOT byte-identical -- the embedded addresses see to that.
;          The maximal identical run through this neighbourhood starts only at the
;          `ldw wa, 0xffff` and runs 98 bytes into the helper block below:
;              python3 notes/prom_c_prom_a_shared_runs.py --at 0xF9A01F 0xF8E6C9
;          The clearing side is pinned independently: INTTC3_HANDLER__state4_blockdone
;          (0xF99DCC, converted above) is the only `res 7,(0x00852B)` besides the
;          timeout path here, and it runs when a payload transfer completes.
;
;          ★ The two reads of the tick counter here are the two sites that the
;          round-1 census of 0x00F2F3 MISSED, because they use the 16-bit-direct
;          spelling (prefix 0xD1) instead of the 24-bit one (0xD2).  prom_a's
;          counterpart makes the point twice over: its tick counter lives at
;          0x0080, so the SAME instruction is spelled with the 8-bit-direct prefix
;          0xD0 there.  See the correction in the INTT1_HANDLER header above.
; Unknown:  ⚠ which of the flag's setters a given caller is waiting on, and what
;          reads the timeout counter at 0x00F333 -- prom_a's header records the
;          same two gaps for its own copy.
; --------------------------------------------------------------------------
; uDMA2_SetDest / uDMA2_SetSource / uDMA3_SetSource / uDMA3_SetDest /
; uDMA2_GetCount / uDMA3_GetCount / uDMA3_GetDest -- one micro-DMA control
;             register each, from the stack.
;
; Called from: uDMA2_SetDest 0xF9996C; uDMA2_SetSource 0xF99A26, 0xF99AA4,
;          0xF99B81, 0xF99BA4; uDMA3_SetSource 0xF99974; uDMA3_SetDest 0xF99E00
;          and 0xF99E34, plus the tail-jump from all seven INT0 arms (XIX is
;          loaded with 0xF9A01F at 0xF99BC3); uDMA3_GetCount 0xF99F73, 0xF99F8C.
;          uDMA2_GetCount and uDMA3_GetDest: no literal reference found.
;          (Byte census of the 24-bit literal with the `1D` call opcode in front.)
; Inputs:  (XSP+4) = a 32-bit address; (XSP+8) = the second argument, which is
;          NOT the same thing in all four setters -- read straight off the bodies:
;              uDMA2_SetDest     DMAD2 0x18      DMAM2 0x2A   mode byte
;              uDMA2_SetSource   DMAS2 0x08      DMAC2 0x28   transfer count
;              uDMA3_SetSource   DMAS3 0x0C      DMAM3 0x2E   mode byte
;              uDMA3_SetDest     DMAD3 0x1C      DMAC3 0x2C   transfer count
;          ⚠ the mode byte rides with the SOURCE setter on channel 3 and with the
;          DEST setter on channel 2.  prom_a's block header at 0xF8E6A2 records
;          the same crossing and the round-1 audit finding (F8) that an earlier
;          version of it got backwards.
; Outputs: the named control register.  BC/XBC clobbered.  Callers drop the
;          arguments themselves.
; Evidence: ★ NAMES CARRIED FROM prom_a BY BYTE IDENTITY, not by resemblance.
;          All eight routines here, 0xF99FF8-0xF9A04F, are byte-for-byte
;          prom_a 0xF8E6A2-0xF8E6F9 -- the same C runtime compiled into both
;          EPROMs -- and prom_a names all eight in its own 0xF8E6A2-0xF8E6F9
;          block header.  Measured, not assumed:
;              python3 notes/prom_c_prom_a_shared_runs.py --selftest
;          reports the maximal identical run through this block as 98 bytes,
;          prom_c 0xF99FEE <-> prom_a 0xF8E698, differing one byte before and one
;          byte after -- so the run COVERS all eight routines and stops outside
;          them.  The control-register numbers are MAME's table for this exact
;          part, mame/src/devices/cpu/tlcs900/tmp95c061.cpp:1394-1398:
;          DMAS2 0x08, DMAC2 0x28, DMAD2 0x18, DMAM2 0x2A, DMAS3 0x0C,
;          DMAC3 0x2C, DMAD3 0x1C, DMAM3 0x2E -- which is why the `.equ`s below
;          are equates and not guesses.
; Unknown:  nothing about these seven; each writes or reads one register and rets.
; --------------------------------------------------------------------------
; MemCopyWords -- copy (XSP+0x10) BYTES from (XSP+0x08) to (XSP+0x0C)
;
; Called from: 66 call sites in prom_c -- a byte census of `1D 38 A0 F9`
;          (call + the 24-bit literal), first 0xFB1DE7, last 0xFC575B.  Both ends
;          checked, not just the first.  This is the compiler's block move.
; Inputs:  (XSP+0x08) source, (XSP+0x0C) destination, (XSP+0x10) byte count.
; Outputs: the copy; BC, XIY, XIX clobbered (XIX saved and restored).
; Evidence: byte-identical to prom_a's MemCopyWords (0xF8E6E2 in
;          prom_a/wsa1_prom_a.s), inside the same 98-byte run measured above.
;          The odd-length handling is visible: `bit 0,bc` then one `LDI` before
;          `srl bc,1` + `LDIRW`, so an odd count moves one byte and then
;          (count-1)/2 words.
; Unknown:  nothing.
; --------------------------------------------------------------------------
	.equ CR_DMAS2, 0x08	; mame/src/devices/cpu/tlcs900/tmp95c061.cpp:1394-1398
	.equ CR_DMAC2, 0x28
	.equ CR_DMAD2, 0x18
	.equ CR_DMAM2, 0x2A
	.equ CR_DMAS3, 0x0C
	.equ CR_DMAC3, 0x2C
	.equ CR_DMAD3, 0x1C
	.equ CR_DMAM3, 0x2E
; Evidence: (the nine routines below are described by the block comments above the
;          `.equ` group; each carries a one-line citation of its own so a grep for
;          "Evidence" does not skip them.)
;          Link_WaitBlockDone: the 500-tick bound is `cp BC,0x01f4 / jr LE` at
;          0xF99FD3 against the INTT1 tick counter 0x00F2F3 sampled at entry, and
;          the three timeout actions are the instructions at 0xF99FD9-0xF99FE5.
Link_WaitBlockDone:
	pushw hl                                   ; F99FC1  2b
	ld hl, (0xF2F3:16)                         ; F99FC2  d1 f3 f2 23   HL := the INTT1 tick count at entry (low 16 bits)
Link_WaitBlockDone__poll:
	bit 7, (0x00852B:24)                       ; F99FC6  f2 2b 85 00 cf   still outstanding?
	jr z, Link_WaitBlockDone__ok               ; F99FCB  66 27
	ld bc, (0xF2F3:16)                         ; F99FCD  d1 f3 f2 21
	sub bc, hl                                 ; F99FD1  db a1
	cp bc, 0x01f4                              ; F99FD3  d9 cf f4 01   500 ticks
	jr le, Link_WaitBlockDone__poll            ; F99FD7  62 ed
	ldio DMA3V, 0x00                           ; F99FD9  08 7f 00   timed out: stop INT0 feeding the DMA engine
	ld (0x00F32D:24), 0x00                     ; F99FDC  f2 2d f3 00 00 00   transfer state := idle
	set_dd8 1, PA                              ; F99FE2  f0 1e b9   raise the handshake line
	res 7, (0x00852B:24)                       ; F99FE5  f2 2b 85 00 b7   clear the outstanding flag ourselves
	inc 1, (0x00F333:24)                      ; F99FEA  c2 33 f3 00 61   the timeout counter
	ldw wa, 0xffff                             ; F99FEF  30 ff ff   return -1
	jr Link_WaitBlockDone__ret                 ; F99FF2  68 02
Link_WaitBlockDone__ok:
	sub wa, wa                                 ; F99FF4  d8 a0   return 0
Link_WaitBlockDone__ret:
	popw hl                                    ; F99FF6  4b
	ret                                        ; F99FF7  0e

; Evidence: writes CR_DMAD2 (0x18) then CR_DMAM2 (0x2A); both `.equ`s above are
;          cited to mame/src/devices/cpu/tlcs900/tmp95c061.cpp:1394-1398.
; ★ ROUND 6 ------------------------------------------------------------
; uDMA2_SetDest -- micro-DMA channel 2 SETTER.  It has no `link`
;          frame, so its arguments sit on the stack above the return address: (XSP+4) is a
;          32-bit address and (XSP+8) the second argument, and the routine copies them into
;          the CPU control registers CR_DMAD2 and CR_DMAM2.
;          Evidence: the `ldc` operands at 0xF99FFB, 0xF9A001; the register numbers are the `.equ`s at the
;          head of this group, each cited to mame/src/devices/cpu/tlcs900/tmp95c061.cpp.
;          ⚠ CHANNELS 2 AND 3 PAIR THEIR REGISTERS THE OPPOSITE WAY ROUND, which is a
;          property of the ROM and not a typo here: on channel 2 the DESTINATION setter also
;          writes the MODE register and the SOURCE setter writes the COUNT; on channel 3 the
;          SOURCE setter writes the mode and the DESTINATION setter writes the count.
;          `python3 notes/prom_c_understanding_round6.py --udma` asserts that pairing from
;          the listing, so if either routine is ever re-read it fails rather than drifting.
;          Unknown: what either channel transfers.  Channel 3's count is read by
;          Link_ServiceTask; nothing here says what channel 2 is for.
uDMA2_SetDest:
	ld xbc, (xsp+4)                            ; F99FF8  af 04 21
	ldc_cr32 xbc, CR_DMAD2                     ; F99FFB  e9 2e 18
	ld c, (xsp+8)                              ; F99FFE  8f 08 23
	ldc_cr8 c, CR_DMAM2                        ; F9A001  cb 2e 2a
	ret                                        ; F9A004  0e
; Evidence: writes CR_DMAS2 (0x08) then CR_DMAC2 (0x28) -- source address and
;          transfer count of micro-DMA channel 2; `.equ`s cited above.
; ★ ROUND 6 ------------------------------------------------------------
; uDMA2_SetSource -- micro-DMA channel 2 SETTER.  It has no `link`
;          frame, so its arguments sit on the stack above the return address: (XSP+4) is a
;          32-bit address and (XSP+8) the second argument, and the routine copies them into
;          the CPU control registers CR_DMAS2 and CR_DMAC2.
;          Evidence: the `ldc` operands at 0xF9A008, 0xF9A00E; the register numbers are the `.equ`s at the
;          head of this group, each cited to mame/src/devices/cpu/tlcs900/tmp95c061.cpp.
;          ⚠ CHANNELS 2 AND 3 PAIR THEIR REGISTERS THE OPPOSITE WAY ROUND, which is a
;          property of the ROM and not a typo here: on channel 2 the DESTINATION setter also
;          writes the MODE register and the SOURCE setter writes the COUNT; on channel 3 the
;          SOURCE setter writes the mode and the DESTINATION setter writes the count.
;          `python3 notes/prom_c_understanding_round6.py --udma` asserts that pairing from
;          the listing, so if either routine is ever re-read it fails rather than drifting.
;          Unknown: what either channel transfers.  Channel 3's count is read by
;          Link_ServiceTask; nothing here says what channel 2 is for.
uDMA2_SetSource:
	ld xbc, (xsp+4)                            ; F9A005  af 04 21
	ldc_cr32 xbc, CR_DMAS2                     ; F9A008  e9 2e 08
	ld bc, (xsp+8)                             ; F9A00B  9f 08 21
	ldc_cr16 bc, CR_DMAC2                      ; F9A00E  d9 2e 28
	ret                                        ; F9A011  0e
; Evidence: writes CR_DMAS3 (0x0C) then CR_DMAM3 (0x2E); `.equ`s cited above.
; ★ ROUND 6 ------------------------------------------------------------
; uDMA3_SetSource -- micro-DMA channel 3 SETTER.  It has no `link`
;          frame, so its arguments sit on the stack above the return address: (XSP+4) is a
;          32-bit address and (XSP+8) the second argument, and the routine copies them into
;          the CPU control registers CR_DMAS3 and CR_DMAM3.
;          Evidence: the `ldc` operands at 0xF9A015, 0xF9A01B; the register numbers are the `.equ`s at the
;          head of this group, each cited to mame/src/devices/cpu/tlcs900/tmp95c061.cpp.
;          ⚠ CHANNELS 2 AND 3 PAIR THEIR REGISTERS THE OPPOSITE WAY ROUND, which is a
;          property of the ROM and not a typo here: on channel 2 the DESTINATION setter also
;          writes the MODE register and the SOURCE setter writes the COUNT; on channel 3 the
;          SOURCE setter writes the mode and the DESTINATION setter writes the count.
;          `python3 notes/prom_c_understanding_round6.py --udma` asserts that pairing from
;          the listing, so if either routine is ever re-read it fails rather than drifting.
;          Unknown: what either channel transfers.  Channel 3's count is read by
;          Link_ServiceTask; nothing here says what channel 2 is for.
uDMA3_SetSource:
	ld xbc, (xsp+4)                            ; F9A012  af 04 21
	ldc_cr32 xbc, CR_DMAS3                     ; F9A015  e9 2e 0c
	ld c, (xsp+8)                              ; F9A018  8f 08 23
	ldc_cr8 c, CR_DMAM3                        ; F9A01B  cb 2e 2e
	ret                                        ; F9A01E  0e
; Evidence: writes CR_DMAD3 (0x1C) then CR_DMAC3 (0x2C); `.equ`s cited above.
; ★ ROUND 6 ------------------------------------------------------------
; uDMA3_SetDest -- micro-DMA channel 3 SETTER.  It has no `link`
;          frame, so its arguments sit on the stack above the return address: (XSP+4) is a
;          32-bit address and (XSP+8) the second argument, and the routine copies them into
;          the CPU control registers CR_DMAD3 and CR_DMAC3.
;          Evidence: the `ldc` operands at 0xF9A022, 0xF9A028; the register numbers are the `.equ`s at the
;          head of this group, each cited to mame/src/devices/cpu/tlcs900/tmp95c061.cpp.
;          ⚠ CHANNELS 2 AND 3 PAIR THEIR REGISTERS THE OPPOSITE WAY ROUND, which is a
;          property of the ROM and not a typo here: on channel 2 the DESTINATION setter also
;          writes the MODE register and the SOURCE setter writes the COUNT; on channel 3 the
;          SOURCE setter writes the mode and the DESTINATION setter writes the count.
;          `python3 notes/prom_c_understanding_round6.py --udma` asserts that pairing from
;          the listing, so if either routine is ever re-read it fails rather than drifting.
;          Unknown: what either channel transfers.  Channel 3's count is read by
;          Link_ServiceTask; nothing here says what channel 2 is for.
uDMA3_SetDest:
	ld xbc, (xsp+4)                            ; F9A01F  af 04 21
	ldc_cr32 xbc, CR_DMAD3                     ; F9A022  e9 2e 1c
	ld bc, (xsp+8)                             ; F9A025  9f 08 21
	ldc_cr16 bc, CR_DMAC3                      ; F9A028  d9 2e 2c
	ret                                        ; F9A02B  0e
; Evidence: one `ldc WA,CR_DMAC2` and a `ret`; `.equ` cited above.
; ★ ROUND 6 ------------------------------------------------------------
; uDMA2_GetCount -- micro-DMA channel 2 GETTER.  It takes NO argument
;          and has no frame: one `ldc` from CR_DMAC2 and a `ret`, returning the value in the
;          register the instruction names.
;          Evidence: the `ldc` operand at 0xF9A02C; the register number is the `.equ` at the head
;          of this group, cited to mame/src/devices/cpu/tlcs900/tmp95c061.cpp.
;          Unknown: what the channel transfers.
uDMA2_GetCount:
	ldc_16_cr wa, CR_DMAC2                     ; F9A02C  d8 2f 28
	ret                                        ; F9A02F  0e
; Evidence: one `ldc WA,CR_DMAC3` and a `ret`; `.equ` cited above.  This is the
;          0xF9A030 that Link_ServiceTask calls to read the remaining count.
; ★ ROUND 6 ------------------------------------------------------------
; uDMA3_GetCount -- micro-DMA channel 3 GETTER.  It takes NO argument
;          and has no frame: one `ldc` from CR_DMAC3 and a `ret`, returning the value in the
;          register the instruction names.
;          Evidence: the `ldc` operand at 0xF9A030; the register number is the `.equ` at the head
;          of this group, cited to mame/src/devices/cpu/tlcs900/tmp95c061.cpp.
;          Unknown: what the channel transfers.
uDMA3_GetCount:
	ldc_16_cr wa, CR_DMAC3                     ; F9A030  d8 2f 2c
	ret                                        ; F9A033  0e
; Evidence: one `ldc XIY,CR_DMAD3` and a `ret`; `.equ` cited above.
; ★ ROUND 6 ------------------------------------------------------------
; uDMA3_GetDest -- micro-DMA channel 3 GETTER.  It takes NO argument
;          and has no frame: one `ldc` from CR_DMAD3 and a `ret`, returning the value in the
;          register the instruction names.
;          Evidence: the `ldc` operand at 0xF9A034; the register number is the `.equ` at the head
;          of this group, cited to mame/src/devices/cpu/tlcs900/tmp95c061.cpp.
;          Unknown: what the channel transfers.
uDMA3_GetDest:
	ldc_32_cr xiy, CR_DMAD3                    ; F9A034  ed 2f 1c
	ret                                        ; F9A037  0e
; Evidence: see this routine's own header above the `.equ` group -- 66 call sites
;          by byte census, byte-identical to prom_a's, odd-length handling read
;          off the `bit 0,bc / ldi / srl bc,1 / ldirw` sequence below.
MemCopyWords:
	push xix                                   ; F9A038  3c
	ld bc, (xsp+16)                            ; F9A039  9f 10 21   arg3: byte count
	ld xiy, (xsp+8)                            ; F9A03C  af 08 25   arg1: source   (LDI/LDIRW read (XIY+))
	ld xix, (xsp+12)                           ; F9A03F  af 0c 24   arg2: dest     (LDI/LDIRW write (XIX+))
	bit 0, bc                                  ; F9A042  d9 33 00
	jr z, MemCopyWords__words                  ; F9A045  66 02   odd count: move the leading byte first
	ldi85                                      ; F9A047  85 10
MemCopyWords__words:
	srl bc, 1                                  ; F9A049  d9 ef 01   the rest as 16-bit words
	ldirw                                      ; F9A04C  95 11
	pop xix                                    ; F9A04E  5c
	ret                                        ; F9A04F  0e

