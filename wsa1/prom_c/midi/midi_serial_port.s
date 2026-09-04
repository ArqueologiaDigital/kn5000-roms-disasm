; ==============================================================================
; Technics SX-WSA1R -- prom_c (CPU 2, IC28) -- 0xF990FA-0xF99597  the SC0 serial port that is MIDI: init, ISRs, queues, TX
; ==============================================================================
;
; 989 lines moved out of prom_c/wsa1_prom_c.s by notes/prom_c_split.py.  The master
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
; Three adjacent banners, one subject: timer 1 and the 0x108000 preload and
; the UART init that configures SC0; INTRX0/INTTX0, SC0's two interrupt
; handlers; and the ring-queue runtime plus the MIDI transmit path they
; feed.  ⚠ The first banner also covers Timer1_Init and
; Dev108000_Preload_80toBF, which are not MIDI; they are here because they
; are inside the banner that documents the UART init and moving a banner's
; body away from its banner would be worse.
;
; >>> END OF EXTRACTION HEADER -- everything below is verbatim from the master

; ==============================================================================
; 0xF990FA-0xF991FE -- timer 1, the 0x108000 preload, the UART init, MIDI dequeue
; ==============================================================================
; --------------------------------------------------------------------------
; Timer1_SetPeriodAndStart -- load TREG1 from the caller and (re)start timer 1.
;
; Called from: 0xF98BA8 (`calr 0xF990FA`), and from nowhere else that
;              notes/prom_c_xrefs.py can see.  The three instructions in front of
;              that call are
;                  ld BC,(0xFFFFEF) / extz BC / push BC
;              so ★ THE ARGUMENT IS THE fc CONFIGURATION BYTE, 0x1C = 28.
;              TREG1 is therefore loaded with fc IN MHz -- the same trick
;              notes/FINDINGS-system-clock.md documents for the UART, where
;              BR0CR is also computed from that byte so that the bit rate comes
;              out fc-independent.  Two unrelated peripherals scaled off the same
;              byte is what makes "0xFFFFEF is fc" more than an interpretation.
; Inputs:  (XIZ+8), a 16-bit stack argument; only its low byte reaches TREG1.
; Outputs: TRUN bit 1 cleared then set (timer 1 stopped and restarted), TREG1 =
;          the argument, INTET10 = 0x33.
; Evidence: TRUN is 0x20, TREG1 is 0x23 and INTET10 is 0x73 in
;          include/tmp95c061_sfr.inc, whose names come from MAME's symbol table
;          for this exact part.  `and (XBC),0xFD` on TRUN clears bit 1 and
;          `or (XBC),0x02` sets it, which is timer 1's run bit.
; Unknown:  ⚠ the timer-1 CLOCK SOURCE.  This routine does not write T01MOD, and
;          no write to it has been located, so TREG1 = 28 cannot be turned into a
;          tick period here.  The INTT1 rate -- which paces the whole six-phase
;          scheduler at 0xF99063 -- is therefore NOT ESTABLISHED.
;          The 0x33 in INTET10 is recorded as a value, not decoded: no TMP95C061
;          databook is available in these trees and MAME does not decode the
;          interrupt-level registers (see the header of the SFR include).
; --------------------------------------------------------------------------
Timer1_SetPeriodAndStart:
	link32	0xEE, 0x0C, 0x00, 0x00
	push	xix
	ld	xbc, TRUN
	extpfx3	0x81, 0x3C, 0xFD
	ld	xix, TREG1
	ld	c, (xiz+8)
	ld	(xix), c
	ld	xbc, TRUN
	extpfx3	0x81, 0x3E, 0x02
	ld	xbc, INTET10
	ld	(xbc), 0x33
	pop	xix
	unlk32	xiz
	ret


; --------------------------------------------------------------------------
; Dev108000_Preload_80toBF -- write 64 values into the device port at 0x108000.
;
; Called from: RESET at 0xFFF081, and from IRQ_NMI at 0xFFF0AE -- the two places
;              `call 0xF99125` appears (notes/prom_c_xrefs.py 0xF99125).
; Inputs:  none.
; Outputs: 64 write pairs to the 0x108000 port: the 16-bit value 0x0080 + i goes
;          to +2 and the constant 0x8000 goes to +0, for i = 0x00..0x3F.
; Evidence: ★ THIS CORRECTS A COMMENT ALREADY IN THIS FILE.  The RESET listing
;          below described 0xF99125 as "a counted delay (loops to 0x40)".  It
;          does loop to 0x40, and it is not a delay: the loop body loads
;          XBC = 0x00108002 and stores HL, then loads XBC = 0x00108000 and stores
;          0x8000.  0x108000 is one of CPU 2's three address/data device ports
;          (notes/FINDINGS-memory-map.md, which already lists this very site).
; Unknown:  ⚠ which register 0x8000 is, and what the 64 ascending values are.
;          Note also that the ORDER here is value-to-+2 first and 0x8000-to-+0
;          second, the opposite of the address-then-data order the 0xE00000 and
;          0x10C000 drivers use.  So either +0 is a commit/trigger on this device
;          or the port convention differs; NOT ESTABLISHED which.
;          ⚠ And a behavioural oddity worth flagging: NMI runs this and then
;          spins forever (IRQ_NMI__hang).  Whatever the sweep does, on NMI it is
;          the last thing this processor ever does.
; --------------------------------------------------------------------------
Dev108000_Preload_80toBF:
	link32	0xEE, 0x0C, 0xFF, 0xFF
	pushw	hl
	ld	(xiz-1), 0
Dev108000_Preload_80toBF__test:
	cp	(xiz-1), 0x40
	jr	nc, Dev108000_Preload_80toBF__done
	jr	Dev108000_Preload_80toBF__body
Dev108000_Preload_80toBF__next:
	incm8	1, (xiz-1)
	jr	Dev108000_Preload_80toBF__test
Dev108000_Preload_80toBF__body:
	ld	bc, (xiz-1)
	extz	bc
	ld	hl, bc
	add	hl, 0x0080
	ld	xbc, 0x00108002
	ld	(xbc), hl
	ld	xbc, 0x00108000
	extpfx4	0xB1, 0x02, 0x00, 0x80
	jr	Dev108000_Preload_80toBF__next
Dev108000_Preload_80toBF__done:
	popw	hl
	unlk32	xiz
	ret


; --------------------------------------------------------------------------
; sub_F9915C -- the job the scheduler's phase-3 bit posts.  NOT NAMED: what it
;             decides is not established, only how it decides it.
;
; Called from: 0xF98C9E (`calr 0xF9915C`), reached only when bit 3 of the work
;              byte 0x007ED1 is set -- and INTT1_HANDLER sets bit 3 on phase 3,
;              once every six ticks.  So this is a scheduled poll, not a
;              one-shot.
; Inputs:  the tick counter 0x00F2F3; a countdown byte at 0x00E2E4; bit 0 of the
;          byte at 0x0000FFF8 (work DRAM).
; Outputs: 0x00F35F = 1 if that bit is set, 2 if it is clear; bit 7 of 0x007ECC
;          set either way; 0x00E2E4 decremented.
; Evidence: two guards, both early-outs: `cp XBC,0x000000FA` on the tick counter
;          means nothing happens until 250 INTT1 ticks have elapsed since reset,
;          and `cp (0x00E2E4),0x00` means it only runs while that counter is
;          non-zero.  0x00E2E4's boot value is 1 (see
;          notes/FINDINGS-prom_c-ram-image.md), so ★ THIS BODY RUNS EXACTLY ONCE
;          PER POWER-UP, on the first phase-3 tick after tick 250.  That is a
;          power-on sample of one input, latched into a two-valued result.
;          Bit 7 of 0x007ECC is what the main loop tests at 0xF98C52 before
;          calling 0xF98510 -- so the latch is consumed.
; Unknown:  ⚠ what the byte at 0x0000FFF8 is, and hence what is being sampled.
;          It is work DRAM, so something else must write it; that writer has not
;          been found.  Naming this routine before that is known would be a
;          guess, so it keeps its address.
; --------------------------------------------------------------------------
sub_F9915C:
	ld	xbc, (0x00F2F3:24)
	cp	xbc, 0x000000FA
	jr	nc, sub_F9915C__armed
	jr	sub_F9915C__exit
sub_F9915C__armed:
	cpib_da	0x00E2E4, 0x00
	jr	nz, sub_F9915C__counting
	jr	sub_F9915C__exit
sub_F9915C__counting:
	decdi8_24 1, 0x00E2E4
	ldw	bc, 0xFFF8
	extz	xbc
	ld	a, (xbc)
	and	a, 1
	jr	z, sub_F9915C__bit0_clear
	ld	(0x00F35F:24), 1
	set 7, (0x007ECC:24)
	jr	sub_F9915C__exit
sub_F9915C__bit0_clear:
	ld	(0x00F35F:24), 2
	set 7, (0x007ECC:24)
sub_F9915C__exit:
	ret


; --------------------------------------------------------------------------
; Serial0_Init -- configure serial channel 0 (the MIDI port) and its interrupts.
;
; Called from: 0xF98B91 (`call 0xF9919F`), in the power-on init chain.
; Inputs:  the fc byte at 0xFFFFEF; the INTES0 shadow byte at 0x00F2F7.
; Outputs: TRUN = 0x80, BR0CR = (fc >> 1) & 0x0F, SC0CR = 0, SC0MOD = 0x29,
;          0x00F2F9 = 2, and INTES0 = (old shadow & 0x88) | 0x55.
; Evidence: ★ THIS IS THE ROUTINE notes/FINDINGS-system-clock.md ARGUES FROM, now
;          in source.  `ld C,(0xFFFFEF) / srl 0x01,C / and C,0x0F / ld (BR0CR),C`
;          is exactly the rule that note states: BR0CR = (M >> 1) & 0x0F.  With
;          the baud generator's fc/4 tap and the UART's own divide-by-16 the bit
;          rate is fc / (32*M), which is 31250 -- the MIDI rate -- for any fc as
;          long as fc = 1,000,000 * M.  M = 0x1C, so fc = 28 MHz.
;          The INTES0 value is built in two steps on the shadow byte and only
;          then written to the register at 0x77: `and 0x8F / or 0x50` sets the
;          upper field to 5 and `and 0xF8 / or 0x05` sets the lower field to 5,
;          so both of channel 0's interrupts get the same setting.  That the two
;          fields are INTTX0 and INTRX0 follows from the register's name in
;          include/tmp95c061_sfr.inc; the numeric meaning of 5 is NOT decoded
;          here for the same reason as in Timer1_SetPeriodAndStart.
;          It brackets the register writes with `ei 6` before and `di` after.
;          ⚠ THAT PAIR IS THE OPPOSITE WAY ROUND FROM WHAT THE MNEMONICS SUGGEST:
;          `ei 6` raises the minimum accepted interrupt priority to 6 (blocking
;          everything below it) and llvm-mc's `di` is the byte pair `06 00` =
;          `EI 0`, which lowers it to 0 and accepts everything.  See the long note
;          in DSP_ChannelRefresh_Loop's header for the citations.  So the guarded
;          region is between them, and the routine ends with interrupts ON.
; Unknown:  what 0x00F2F9 = 2 means.  INTTX0_HANDLER writes the same value when
;          its queue runs dry, so "transmitter idle" is the reading offered in
;          notes/FINDINGS-prom_c-serial-midi.md; it is still not established.
;          Why SC0MOD is 0x29 here and 0x09 in the boot block is also open.
; --------------------------------------------------------------------------
Serial0_Init:
	ldio	TRUN, 0x80
	ld	c, (0x00FFFFEF:24)
	srl	c, 1
	and	c, 0x0F
	st_dd8b	c, BR0CR
	ldio	SC0CR, 0x00
	ldio	SC0MOD, 0x29
	ei	6
	ldw	(0x00F2F9:24), 0x0002
	ld	c, (0x00F2F7:24)
	and	c, 0x8F
	or	c, 0x50
	ld	(0x00F2F7:24), c
	and	c, 0xF8
	or	c, 0x05
	ld	(0x00F2F7:24), c
	ldw	bc, INTES0
	exts	xbc
	ld	a, (0x00F2F7:24)
	ld	(xbc), a
	ei	0
	ret


; --------------------------------------------------------------------------
; MIDI_Rx_FreeSlots -- a queue operation on the MIDI RECEIVE descriptor.  Which one is
;             not established.
;
; Called from: not found -- no literal reference and no calr displacement in
;              prom_c reaches 0xF991E9.
; Inputs:  none; it supplies the descriptor address 0x00F2FB itself.
; Outputs: whatever 0xF994D7 returns.
; Evidence: byte for byte the same three-instruction wrapper as MIDI_Rx_Dequeue
;          below, on the SAME descriptor, differing only in the routine called
;          (0xF994D7 instead of 0xF993D4).  0x00F2FB is the descriptor
;          INTRX0_HANDLER pushes when it enqueues a received byte.
; Unknown:  what 0xF994D7 does.  A pair of wrappers over one descriptor is what
;          "peek" and "pop" look like, but neither callee has been converted, so
;          that is a shape and not a finding.
; ★ NAMED (round 7 finish pass).  THE FREE-SLOT COUNT OF THE MIDI RECEIVE QUEUE.
;          11 bytes, 2 of which differ from MIDI_Rx_Dequeue at 0xF991F4 (byte diff
;          run by notes/prom_c_finish_round7.py --twins): the two differing bytes are
;          the calr displacement at 0xF991F0-0xF991F1, E5 02 here against D7 01 there.
;          Both wrappers push the SAME descriptor -- `lda XBC,0x00F2FB` at 0xF991E9,
;          which is the descriptor INTRX0_HANDLER enqueues into -- and the only thing
;          that differs is the callee: 0xF994D7 = Queue_FreeSlots here, 0xF993D4 =
;          Queue_Get_IrqGuarded there.
;          ⚠ THIS RETIRES A STALE 'Unknown'.  The previous header said "what 0xF994D7
;          does" was unknown and refused the name for that reason; 0xF994D7 has since
;          been named Queue_FreeSlots, so the reason is gone.
; Called from: still NOT FOUND -- no literal reference and no calr displacement in
;          prom_c reaches 0xF991E9.  Naming it does not make it reached.
; --------------------------------------------------------------------------
MIDI_Rx_FreeSlots:
	lda	xbc, (0x00F2FB:24)
	push	xbc
	calr	(0xF994D7 - 0xF991F2)
	pop	xiy
	ret


; --------------------------------------------------------------------------
; MIDI_Rx_Dequeue -- take the next byte from the MIDI receive queue.
;
; Called from: 0xF98BC6 and 0xF98D52, both `call 0xF991F4`.
; Inputs:  none; the descriptor address 0x00F2FB is supplied here.
; Outputs: WA = the byte, or 0xFFFF when the queue is empty.
; Evidence: the caller at 0xF98BC6 is the main loop's MIDI drain: it calls this,
;          copies WA to HL, and `cp HL,0xFFFF / jr Z` leaves the loop -- so
;          0xFFFF is the empty sentinel, and every other value is a byte it
;          stores into a 32-entry buffer before going round again (it also stops
;          at 0x20 entries).  The descriptor is the same 0x00F2FB the receive ISR
;          enqueues into, which is what makes this the RECEIVE side.
; Unknown:  the layout of the descriptor at 0x00F2FB and the body of 0xF993D4.
; --------------------------------------------------------------------------
MIDI_Rx_Dequeue:
	lda	xbc, (0x00F2FB:24)
	push	xbc
	calr	(0xF993D4 - 0xF991FD)
	pop	xiy
	ret

; ==============================================================================
; 0xF991FF-0xF992A6 -- the serial-channel-0 interrupt handlers (MIDI)
; ==============================================================================
;
; Both handlers are converted from unidasm's decode; the llvm-mc spelling for each
; instruction was recovered with notes/prom_c_enc_oracle.py, which inverts the
; 40,101 already-byte-verified instructions of the KN5000 sub-CPU source.  The
; byte gate is what certifies them.
;
; --------------------------------------------------------------------------
; INTRX0_HANDLER -- serial channel 0 receive ISR.  This is the MIDI IN port.
;
; Called from: vector table offset 0x60 (INTRX0), which holds 0x00F991FF -- see
;              VECTORS at the bottom of this file.
; Inputs:  SC0CR (0x51) receive status, SC0BUF (0x50) received byte.
; Outputs: on a receive error, the status byte is stored at 0x00F327 and the byte
;          is dropped.  Otherwise the 32-bit value at 0x00F2F3 is copied to
;          0x007ED6, a byte of 0xFE additionally sets 0x00F2F8 = 1, and the byte
;          is pushed to the routine at 0xF9932E together with the descriptor
;          address 0x00F2FB.
; Notes:   ★ THE MIDI IDENTIFICATION RESTS ON THREE THINGS, ALL VISIBLE HERE.
;          1. `and c,0x1c` on SC0CR tests exactly bits 4..2 -- the three receive
;             error flags of a TLCS-900 serial channel.
;          2. The range filter is MIDI's, exactly.  The two SIGNED compares
;                cp (xiz-1),0x00 / jr ge   -> 0x00..0x7F enqueued
;                cp (xiz-1),0xf8 / jr lt   -> 0x80..0xF7 enqueued
;                                             0xF8..0xFF DROPPED
;             0xF8-0xFF is the MIDI System Real-Time range, which by the standard
;             may appear between the bytes of another message and must not be
;             queued with it.
;          3. The one byte singled out for a flag, 0xFE, is MIDI Active Sensing.
;          Corroborated independently by notes/FINDINGS-system-clock.md, where the
;          firmware's own baud rule makes SC0 run at 31250 bit/s for any fc.
;          ⚠ NOT ESTABLISHED: which physical connector SC0 reaches.  The MIDI
;          reading is from the protocol this code implements, not from a trace.
;          0x00F2FB is presumably a ring-buffer descriptor (the transmit handler
;          below uses 0x00F311 the same way) but that is NOT traced.
; --------------------------------------------------------------------------
INTRX0_HANDLER:
	push xbc
	pushw wa
	link32 0xEE, 0x0C, 0xFE, 0xFF
	push xwa
	push xiy
	ldmi16 (xiz-2), SC0CR
	ldw bc, SC0BUF
	exts xbc
	ld a, (xbc)
	ld (xiz-1), a
	ld c, (xiz-2)
	and c, 0x1c
	cps c, 0
	jr z, INTRX0_HANDLER__no_error
	ld c, (xiz-2)
	ld (0x00F327:24), c
	jr INTRX0_HANDLER__exit
INTRX0_HANDLER__no_error:
	ld xbc, (0x00F2F3:24)
	stl_da 0x007ED6, xbc
	cp (xiz-1), 0xfe
	jr nz, INTRX0_HANDLER__range_check
	ld (0x00F2F8:24), 0x01
INTRX0_HANDLER__range_check:
	cp (xiz-1), 0x00
	jr ge, INTRX0_HANDLER__enqueue
	cp (xiz-1), 0xf8
	jr lt, INTRX0_HANDLER__enqueue
	jr INTRX0_HANDLER__exit
INTRX0_HANDLER__enqueue:
	push 0x00
	extpfx3 0x8e, 0xff, 0x04
	lda xbc, (0x00F2FB:24)
	push xbc
	calr (0xF9932E - 0xF9925C)
	inc 6, xsp
INTRX0_HANDLER__exit:
	pop xiy
	pop xwa
	unlk32 xiz
	popw wa
	pop xbc
	reti

; --------------------------------------------------------------------------
; INTTX0_HANDLER -- serial channel 0 transmit-done ISR.  The MIDI OUT drain.
;
; Called from: vector table offset 0x64 (INTTX0), which holds 0x00F99265.
; Inputs:  none from hardware; it calls 0xF9942F with the descriptor address
;          0x00F311 to fetch the next byte to send.
; Outputs: if 0xF9942F returns 0xFFFF the queue is empty and 0x00F2F9 is set to
;          2 (transmitter idle, presumably).  Otherwise the byte is written to
;          SC0BUF (0x50) and the 32-bit value at 0x00F2F3 is copied to 0x007ED2.
; Notes:   The mirror of INTRX0_HANDLER: same 0x00F2F3 source copied to an adjacent
;          destination (0x007ED2 here, 0x007ED6 there), same descriptor-pointer
;          calling convention.  What 0x00F2F3 counts is NOT ESTABLISHED -- it is
;          read as a 32-bit value on every serial interrupt, which is what a
;          free-running timestamp would look like.
; --------------------------------------------------------------------------
INTTX0_HANDLER:

	push xbc
	pushw wa
	push xiy
	link32 0xEE, 0x0C, 0xFE, 0xFF
	pushw hl
	push xwa
	lda xbc, (0x00F311:24)
	push xbc
	calr (0xF9942F - 0xF99277)
	ld hl, wa
	ld (xiz-2), wa
	pop xiy
	cp hl, 0xffff
	jr z, INTTX0_HANDLER__empty
	ld h, a
	ldw bc, SC0BUF
	exts xbc
	ld (xbc), a
	ld xbc, (0x00F2F3:24)
	stl_da 0x007ED2, xbc
	jr INTTX0_HANDLER__exit
INTTX0_HANDLER__empty:
	ldw (0x00F2F9:24), 0x0002
INTTX0_HANDLER__exit:
	pop xwa
	popw hl
	unlk32 xiz
	pop xiy
	popw wa
	pop xbc
	reti

; ==============================================================================
; 0xF992A7-0xF99597 -- the RING-QUEUE runtime, the MIDI transmit path, and the
;                      ACTIVE-SENSING / TRANSPORT-SWITCH watchdogs
;                      9 routines, 753 bytes
; ==============================================================================
;
; ★★ THE QUEUE DESCRIPTOR, AND ITS SIZE CONFIRMED THREE WAYS.  Six of the nine
; routines below take one pointer argument and do nothing but walk a ring buffer
; through it.  The fields are read off their instructions:
;
;     +0x00  u32  first slot
;     +0x04  u32  LAST slot        (the wrap test is `cursor == +0x04 -> +0x00`)
;     +0x08  u32  read cursor
;     +0x0C  u32  write cursor
;     +0x10  u32  a SECOND read cursor, used only by Queue_Peek_Cursor2
;     +0x14  u16  FREE-slot count  (`== 0` means full; put decrements, get
;                                   increments)
;                                                  = 22 = 0x16 bytes
;
; The size is not counted off a listing.  Three independent facts give it:
;   1. `notes/FINDINGS-prom_c-serial-midi.md` already names 0x00F2FB as the
;      receive descriptor, and MIDI_Tx_PutByte below passes **0x00F311** for the
;      transmit one.  0x00F311 - 0x00F2FB = **0x16**.
;   2. Both descriptors are inside the boot RAM image, so their power-on contents
;      are readable and the last field is where the struct stops:
;          python3 notes/prom_c_ram_image.py 0x00F2FB:22 0x00F311:22
;      RX: first 0x00007EDA, last 0x000082D9, all three cursors 0x00007EDA,
;          free 0x03FF = 1023 -- a 0x400 = 1024-byte buffer with one slot held back.
;      TX: first 0x000082DA, last 0x000084D9, all three cursors 0x000082DA,
;          free 0x01FF =  511 -- a 0x200 =  512-byte buffer, likewise.
;   3. The two buffers are ADJACENT and each free count is its buffer's size minus
;      one: 0x82D9 + 1 = 0x82DA and 0x84D9 + 1 = **0x0084DA**, which is the
;      per-note velocity trim table
;      (notes/FINDINGS-prom_c-keyboard-and-touch.md).  Three RAM objects meeting
;      end to end with no gap.
;
; ★ THE MIDI TRANSMIT PATH.  MIDI_Tx_PutByte writes STRAIGHT to SC0BUF when the
; transmitter is idle -- `(0x00F2F9) == 2`, which is the value INTTX0_HANDLER
; writes when its queue runs dry (see notes/FINDINGS-prom_c-serial-midi.md) --
; and otherwise queues the byte on 0x00F311, retrying while the queue is full.
; Every direct write also stamps 0x007ED2 with the current INTT1 tick count, which
; is what the active-sensing timer below measures against.
;
; ★★ ACTIVE SENSING, IN BOTH DIRECTIONS.  MIDI_Watchdogs_And_TransportSwitch is
; called from MAIN every pass and does three unrelated jobs:
;
;   1. If more than 0x87 = 135 INTT1 ticks have passed since the last byte was
;      given to the UART (0x007ED2), it re-stamps and sends the byte **0xFE**.
;   2. If a 0xFE has been RECEIVED -- INTRX0_HANDLER sets 0x00F2F8 on exactly that
;      byte, which that handler's own header already records -- and more than
;      0xA5 = 165 ticks have passed since the last receive timestamp (0x007ED6),
;      it clears the flag and sends the byte at **0xFCC5C2** up link channel 6.
;   3. It reads bit 2 of port P8 and, on a change, sends the byte at **0xFCC5C3**
;      or **0xFCC5C4** up link channel 6, tracking the state in 0x00F328.
;
; ★★★ AND THAT DECODES THE LAST THREE BYTES OF `unexplained_FCC5BE`.  The zone-2
; header in this file lists `ff fa fb 4d 00 80 00` as unidentified and a later pass
; explained only the `4d 00` and `80 00`.  The other three are these:
;
;     0xFCC5C2 = 0xFF     sent on the receive-side active-sensing TIMEOUT
;     0xFCC5C3 = 0xFA     sent when P8 bit 2 goes HIGH
;     0xFCC5C4 = 0xFB     sent when P8 bit 2 goes LOW
;
; They are single bytes with addresses because Link_SendBuffer takes a POINTER and
; a length, and each is sent with length 1.
;
; ⚠ In MIDI, 0xFE is Active Sensing, 0xFF is System Reset, 0xFA is Start and 0xFB
; is Continue.  The 0xFE side is not just a name-match: the transmitter emits it on
; a timer and the receiver flags it and times it out, which IS the active-sensing
; protocol.  What P8 bit 2 physically is -- a footswitch, a transport button -- is
; NOT ESTABLISHED; only that its two states send two different single-byte messages
; and that 0xF992A7's byte-string terminator is 0xFF.
;
; ⚠ AND A TIMING INFERENCE, LABELLED AS ONE.  notes/FINDINGS-prom_c-scheduler.md
; records "the tick RATE is not established".  It still is not.  But IF the 0xFE is
; MIDI Active Sensing, the standard requires it at intervals of at most 300 ms, and
; 135 ticks would then be at most 300 ms -- a tick of about 2.2 ms or less, and a
; receive timeout (165 ticks) about 22% longer than the send interval, which is the
; margin an active-sensing receiver needs.  That is an argument from the MIDI
; specification, NOT from this ROM, and it is written here so that a later
; measurement can contradict it.
;
; Transcribed with notes/llvm_roundtrip_autoforce.py c 0xF992A7 0x2F1, restyled by
; notes/prom_c_listing_prep.py, re-proved with notes/prom_c_verify_fragment.py.

; --------------------------------------------------------------------------
; MIDI_Tx_SendUntilFF -- hand bytes to MIDI_Tx_PutByte until one of them is 0xFF.
;
; Called from: 0xF9A0ED, 0xF9A11B and 0xF9A153, three `call 0xF992A7` sites in the
;          still-unconverted stretch above Link_WaitBlockDone.
; Inputs:  (XIZ+0x08) a pointer, updated in place as it walks.
; Outputs: none.  The terminating 0xFF is NOT sent.
; Evidence: `ld A,(XBC) / cp A,0xFF / jr Z,exit`, then the same byte is pushed and
;          `calr 0xF992C6` called, the pointer incremented and written back to the
;          stack slot, and the loop repeats.
; Unknown:  what the three callers send.  ⚠ 0xFF is MIDI System Reset, so a
;          message list terminated by 0xFF cannot itself contain one; whether that
;          is deliberate is not established.
; --------------------------------------------------------------------------
MIDI_Tx_SendUntilFF:
	link32 0xEE, 0x0C, 0x00, 0x00          ; F992A7  link XIZ,0x0000   [llvm-mc cannot encode this]
MIDI_Tx_SendUntilFF__F992AB:
	ld	xbc, (xiz+8)                        ; F992AB  ld XBC,(XIZ+0x08)
	ld	a, (xbc)                            ; F992AE  ld A,(XBC)
	cp	a, 0xFF                             ; F992B0  cp A,0xff
	jr z, MIDI_Tx_SendUntilFF__F992C3                        ; F992B3  jr Z,0xf992c3
	ld	a, (xbc)                            ; F992B5  ld A,(XBC)
	pushw	wa                               ; F992B7  push WA
	inc	1, xbc                             ; F992B8  inc 1,XBC
	ld	(xiz+8), xbc                        ; F992BA  ld (XIZ+0x08),XBC
	calr (0xF992C6 - 0xF992C0)             ; F992BD  calr 0xf992c6
	popw	bc                                ; F992C0  pop BC
	jr MIDI_Tx_SendUntilFF__F992AB                           ; F992C1  jr T,0xf992ab
MIDI_Tx_SendUntilFF__F992C3:
	unlk32 xiz                             ; F992C3  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; F992C5  ret

; --------------------------------------------------------------------------
; ★ MIDI_Tx_PutByte -- send one byte out of serial channel 0, directly if the
;             transmitter is idle and through the ring queue otherwise.
;
; Called from: 0xF992BD (MIDI_Tx_SendUntilFF), 0xF9950A
;          (MIDI_Watchdogs_And_TransportSwitch's active-sensing arm) and 0xF99010
;          (Link_Ch2_ForwardBytes -- so a byte CPU 1 sends on link channel 2 goes
;          out of the MIDI port).  notes/prom_c_xrefs.py 0xF992C6.
; Inputs:  (XIZ+0x08) the byte.
; Outputs: either SC0BUF directly, or one slot of the transmit queue at 0x00F311.
; Evidence: `push SR` / `ei 6` guards the test; `cp (0x00F2F9),0x0002` is the idle
;          test -- 2 is the value INTTX0_HANDLER writes when its queue runs dry,
;          per notes/FINDINGS-prom_c-serial-midi.md -- and the direct path is
;          `ld BC,0x0050 / exts XBC / ld (XBC),A`, i.e. a store to SC0BUF at
;          internal-I/O address 0x50.  It then stamps 0x007ED2 with the 32-bit
;          tick counter and sets the state to 1.
;          The queued path calls Queue_Put(0x00F311, byte) and RETRIES while the
;          result is 0xFFFF, so a full queue blocks here rather than dropping.
; ★ 0x007ED2 IS THE ACTIVE-SENSING TIMER'S REFERENCE.  Four literal-addressed
;          sites: written here and at 0xF99502, written by INTTX0_HANDLER at
;          0xF99291, and read at 0xF994ED.
; Unknown:  what the third value of 0x00F2F9 (0 -- its boot value) means.
; --------------------------------------------------------------------------
MIDI_Tx_PutByte:
	link32 0xEE, 0x0C, 0xFE, 0xFF          ; F992C6  link XIZ,0xfffe   [llvm-mc cannot encode this]
	push	sr                                ; F992CA  push SR
	ei	6                                   ; F992CB  ei 0x06
	extpfx7 0xD2, 0xF9, 0xF2, 0x00, 0x3F, 0x02, 0x00 ; F992CD  cp (0x00f2f9),0x0002   [llvm-mc cannot encode this]
	jr nz, MIDI_Tx_PutByte__F992F8                       ; F992D4  jr NZ,0xf992f8
	ldw	bc, 80                             ; F992D6  ld BC,0x0050
	exts	xbc                               ; F992D9  exts XBC
	ld	a, (xiz+8)                          ; F992DB  ld A,(XIZ+0x08)
	ld	(xbc), a                            ; F992DE  ld (XBC),A
	ld	xbc, (0xF2F3:24)                   ; F992E0  ld XBC,(0x00f2f3)
	stl_da	(0x7ED2), xbc                   ; F992E5  ld (0x007ed2),XBC
	ldw	(0xF2F9:24), 1                    ; F992EA  ld (0x00f2f9),0x0001
	ldw (xiz-2), 0x0000                    ; F992F1  ld (XIZ+0xfe),0x0000   [llvm-mc cannot encode this]
	jr MIDI_Tx_PutByte__F9930B                           ; F992F6  jr T,0xf9930b
MIDI_Tx_PutByte__F992F8:
	push	0                                 ; F992F8  push 0x00
	extpfx3 0x8E, 0x08, 0x04               ; F992FA  push (XIZ+0x08)   [llvm-mc cannot encode this]
	lda	xbc, (0xF311:24)                   ; F992FD  lda XBC,0x00f311
	push	xbc                               ; F99302  push XBC
	calr (0xF9932E - 0xF99306)             ; F99303  calr 0xf9932e
	ld	(xiz-2), wa                         ; F99306  ld (XIZ+0xfe),WA
	inc	6, xsp                             ; F99309  inc 6,XSP
MIDI_Tx_PutByte__F9930B:
	pop	sr                                 ; F9930B  pop SR
	cpw (xiz-2), 0xFFFF                    ; F9930C  cp (XIZ+0xfe),0xffff   [llvm-mc cannot encode this]
	jr nz, MIDI_Tx_PutByte__F9932B                       ; F99311  jr NZ,0xf9932b
MIDI_Tx_PutByte__F99313:
	push	0                                 ; F99313  push 0x00
	extpfx3 0x8E, 0x08, 0x04               ; F99315  push (XIZ+0x08)   [llvm-mc cannot encode this]
	lda	xbc, (0xF311:24)                   ; F99318  lda XBC,0x00f311
	push	xbc                               ; F9931D  push XBC
	calr (0xF9932E - 0xF99321)             ; F9931E  calr 0xf9932e
	inc	6, xsp                             ; F99321  inc 6,XSP
	cp	wa, 0xFFFF                          ; F99323  cp WA,0xffff
	jr nz, MIDI_Tx_PutByte__F9932B                       ; F99327  jr NZ,0xf9932b
	jr MIDI_Tx_PutByte__F99313                           ; F99329  jr T,0xf99313
MIDI_Tx_PutByte__F9932B:
	unlk32 xiz                             ; F9932B  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; F9932D  ret

; --------------------------------------------------------------------------
; Queue_Put -- store one byte at the write cursor of a ring queue.
;
; Called from: 0xF99303 and 0xF9931E, both inside MIDI_Tx_PutByte.
; Inputs:  (XIZ+0x08) descriptor pointer, (XIZ+0x0c) the byte.  Both sites pass
;          the TRANSMIT descriptor 0x00F311.  ⚠ The address above is a VARIABLE, not a call site.  It is stated here rather than in `Called from:` because notes/prom_c_audit_callsites.py harvests every 0xXXXXXX in that paragraph and cannot tell prose from a citation.
; Outputs: WA = the free count AFTER the store, or 0 if the queue was already
;          full -- and the caller's `cp (XIZ+0xfe),0xFFFF` test means a full queue
;          is signalled by the value it reads back, not by a flag.
; Evidence: the descriptor layout in the block comment above is read entirely from
;          this routine and its five siblings: `(XBC+0x14)` is tested against 0 and
;          decremented, `(XBC+0x0c)` is the store address, and the wrap is
;          `if (XBC+0x0c) == (XBC+0x04) then (XBC+0x0c) = (XBC) else += 1`.
; Unknown:  nothing about the routine.
; --------------------------------------------------------------------------
Queue_Put:
	link32 0xEE, 0x0C, 0x00, 0x00          ; F9932E  link XIZ,0x0000   [llvm-mc cannot encode this]
	push	xix                               ; F99332  push XIX
	ld	xbc, (xiz+8)                        ; F99333  ld XBC,(XIZ+0x08)
	ld	wa, (xbc+20)                        ; F99336  ld WA,(XBC+0x14)
	cps	wa, 0                              ; F99339  cp WA,0
	jr nz, Queue_Put__F99344                       ; F9933B  jr NZ,0xf99344
	ld	wa, (xbc+20)                        ; F9933D  ld WA,(XBC+0x14)
	jr Queue_Put__F9937B                           ; F99340  jr T,0xf9937b
	jr Queue_Put__F9937B                           ; F99342  jr T,0xf9937b
Queue_Put__F99344:
	ld	xbc, (xiz+8)                        ; F99344  ld XBC,(XIZ+0x08)
	ld	xwa, (xbc+12)                       ; F99347  ld XWA,(XBC+0x0c)
	ld	c, (xiz+12)                         ; F9934A  ld C,(XIZ+0x0c)
	ld	(xwa), c                            ; F9934D  ld (XWA),C
	ld	xbc, (xiz+8)                        ; F9934F  ld XBC,(XIZ+0x08)
	decm	1, (xbc+20)                       ; F99352  decw 1,(XBC+0x14)
	ld	xbc, (xiz+8)                        ; F99355  ld XBC,(XIZ+0x08)
	ld	xwa, (xbc+4)                        ; F99358  ld XWA,(XBC+0x04)
	ld	xix, xwa                            ; F9935B  ld XIX,XWA
	ld	xiy, (xbc+12)                       ; F9935D  ld XIY,(XBC+0x0c)
	cp	xiy, xwa                            ; F99360  cp XIY,XWA
	jr nz, Queue_Put__F9936B                       ; F99362  jr NZ,0xf9936b
	ld	xwa, (xbc)                          ; F99364  ld XWA,(XBC)
	ld	(xbc+12), xwa                       ; F99366  ld (XBC+0x0c),XWA
	jr Queue_Put__F99375                           ; F99369  jr T,0xf99375
Queue_Put__F9936B:
	ld	xbc, (xiz+8)                        ; F9936B  ld XBC,(XIZ+0x08)
	sub	xwa, xwa                           ; F9936E  sub XWA,XWA
	inc	1, xwa                             ; F99370  inc 1,XWA
	add	(xbc+12), xwa                      ; F99372  add (XBC+0x0c),XWA
Queue_Put__F99375:
	ld	xbc, (xiz+8)                        ; F99375  ld XBC,(XIZ+0x08)
	ld	wa, (xbc+20)                        ; F99378  ld WA,(XBC+0x14)
Queue_Put__F9937B:
	pop	xix                                ; F9937B  pop XIX
	unlk32 xiz                             ; F9937C  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; F9937E  ret

; --------------------------------------------------------------------------
; Queue_Put_IrqGuarded -- Queue_Put with the free-count decrement bracketed by
;             `ei 6` / `di`.
;
; Called from: NOT FOUND.  `python3 notes/prom_c_xrefs.py 0xF9937F --no-window`
;          reports no literal and no calr; short PC-relative forms are not
;          searched.
; Inputs / Outputs: as Queue_Put.
; Evidence: Queue_Put is 81 bytes and this one 85.  Aligned byte by byte with
;          difflib, the difference is exactly two INSERTED two-byte instructions --
;          `06 06` and `06 00` -- wrapped round the `decw 1,(XBC+0x14)`, plus the
;          two branch-displacement bytes at Queue_Put offsets +0x13 and +0x15 that
;          had to move because of them.  Nothing else differs, and the four
;          "changed" bytes are two displacements, not two instructions.
;          ⚠ Read `ei 6` … `di` the right way round: `di` is the byte pair
;          `06 00` = `EI 0`, which ENABLES interrupts -- see the long note in
;          DSP_ChannelRefresh_Loop's header.  So the guard RAISES the mask for the
;          decrement and drops it again, which is what protecting a counter shared
;          with an ISR looks like.
; Unknown:  why the guarded variant exists and is unused, while the unguarded one
;          is the one MIDI_Tx_PutByte calls -- from inside its own `ei 6` region.
; --------------------------------------------------------------------------
Queue_Put_IrqGuarded:
	link32 0xEE, 0x0C, 0x00, 0x00          ; F9937F  link XIZ,0x0000   [llvm-mc cannot encode this]
	push	xix                               ; F99383  push XIX
	ld	xbc, (xiz+8)                        ; F99384  ld XBC,(XIZ+0x08)
	ld	wa, (xbc+20)                        ; F99387  ld WA,(XBC+0x14)
	cps	wa, 0                              ; F9938A  cp WA,0
	jr nz, Queue_Put_IrqGuarded__F99395                       ; F9938C  jr NZ,0xf99395
	ld	wa, (xbc+20)                        ; F9938E  ld WA,(XBC+0x14)
	jr Queue_Put_IrqGuarded__F993D0                           ; F99391  jr T,0xf993d0
	jr Queue_Put_IrqGuarded__F993D0                           ; F99393  jr T,0xf993d0
Queue_Put_IrqGuarded__F99395:
	ld	xbc, (xiz+8)                        ; F99395  ld XBC,(XIZ+0x08)
	ld	xwa, (xbc+12)                       ; F99398  ld XWA,(XBC+0x0c)
	ld	c, (xiz+12)                         ; F9939B  ld C,(XIZ+0x0c)
	ld	(xwa), c                            ; F9939E  ld (XWA),C
	ei	6                                   ; F993A0  ei 0x06
	ld	xbc, (xiz+8)                        ; F993A2  ld XBC,(XIZ+0x08)
	decm	1, (xbc+20)                       ; F993A5  decw 1,(XBC+0x14)
	ei	0                                     ; F993A8  ei 0x00
	ld	xbc, (xiz+8)                        ; F993AA  ld XBC,(XIZ+0x08)
	ld	xwa, (xbc+4)                        ; F993AD  ld XWA,(XBC+0x04)
	ld	xix, xwa                            ; F993B0  ld XIX,XWA
	ld	xiy, (xbc+12)                       ; F993B2  ld XIY,(XBC+0x0c)
	cp	xiy, xwa                            ; F993B5  cp XIY,XWA
	jr nz, Queue_Put_IrqGuarded__F993C0                       ; F993B7  jr NZ,0xf993c0
	ld	xwa, (xbc)                          ; F993B9  ld XWA,(XBC)
	ld	(xbc+12), xwa                       ; F993BB  ld (XBC+0x0c),XWA
	jr Queue_Put_IrqGuarded__F993CA                           ; F993BE  jr T,0xf993ca
Queue_Put_IrqGuarded__F993C0:
	ld	xbc, (xiz+8)                        ; F993C0  ld XBC,(XIZ+0x08)
	sub	xwa, xwa                           ; F993C3  sub XWA,XWA
	inc	1, xwa                             ; F993C5  inc 1,XWA
	add	(xbc+12), xwa                      ; F993C7  add (XBC+0x0c),XWA
Queue_Put_IrqGuarded__F993CA:
	ld	xbc, (xiz+8)                        ; F993CA  ld XBC,(XIZ+0x08)
	ld	wa, (xbc+20)                        ; F993CD  ld WA,(XBC+0x14)
Queue_Put_IrqGuarded__F993D0:
	pop	xix                                ; F993D0  pop XIX
	unlk32 xiz                             ; F993D1  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; F993D3  ret

; --------------------------------------------------------------------------
; Queue_Get_IrqGuarded -- take one byte from the read cursor, with the free-count
;             increment bracketed by `ei 6` / `di`.
;
; Called from: 0xF991FA, the `calr 0xF993D4` inside MIDI_Rx_Dequeue.  One site.
; Inputs:  (XIZ+0x08) descriptor pointer -- that site passes the RECEIVE
;          descriptor 0x00F2FB.  ⚠ The address above is a VARIABLE, not a call site.  It is stated here rather than in `Called from:` because notes/prom_c_audit_callsites.py harvests every 0xXXXXXX in that paragraph and cannot tell prose from a citation.
; Outputs: WA = the byte, zero-extended; 0xFFFF when the queue is empty.
; Evidence: empty is `(XBC+0x0c) == (XBC+0x08)`, write cursor equal to read cursor;
;          the byte is fetched from `(XBC+0x08)`, the cursor wrapped the same way
;          as in Queue_Put, and `(XBC+0x14)` incremented.
; ★ THIS IS THE BODY notes/FINDINGS-prom_c-serial-midi.md CALLS UNKNOWN.  That note
;          and MIDI_Rx_Dequeue's header both end with "the layout of the descriptor
;          at 0x00F2FB and the body of 0xF993D4" as open.  Both are now read off
;          instructions, and the RX buffer's extent (0x00007EDA-0x000082D9, 1024
;          bytes) comes out of the boot RAM image.
; Unknown:  nothing about the routine.
; --------------------------------------------------------------------------
Queue_Get_IrqGuarded:
	link32 0xEE, 0x0C, 0xFF, 0xFF          ; F993D4  link XIZ,0xffff   [llvm-mc cannot encode this]
	push	xix                               ; F993D8  push XIX
	ld	xbc, (xiz+8)                        ; F993D9  ld XBC,(XIZ+0x08)
	ld	xwa, (xbc+12)                       ; F993DC  ld XWA,(XBC+0x0c)
	ld	xix, xwa                            ; F993DF  ld XIX,XWA
	ld	xiy, (xbc+8)                        ; F993E1  ld XIY,(XBC+0x08)
	cp	xiy, xwa                            ; F993E4  cp XIY,XWA
	jr nz, Queue_Get_IrqGuarded__F993EF                       ; F993E6  jr NZ,0xf993ef
	ldw	wa, 0xFFFF                         ; F993E8  ld WA,0xffff
	jr Queue_Get_IrqGuarded__F9942B                           ; F993EB  jr T,0xf9942b
	jr Queue_Get_IrqGuarded__F993FA                           ; F993ED  jr T,0xf993fa
Queue_Get_IrqGuarded__F993EF:
	ld	xbc, (xiz+8)                        ; F993EF  ld XBC,(XIZ+0x08)
	ld	xwa, (xbc+8)                        ; F993F2  ld XWA,(XBC+0x08)
	ld	c, (xwa)                            ; F993F5  ld C,(XWA)
	ld	(xiz-1), c                          ; F993F7  ld (XIZ+0xff),C
Queue_Get_IrqGuarded__F993FA:
	ld	xbc, (xiz+8)                        ; F993FA  ld XBC,(XIZ+0x08)
	ld	xwa, (xbc+4)                        ; F993FD  ld XWA,(XBC+0x04)
	ld	xix, xwa                            ; F99400  ld XIX,XWA
	ld	xiy, (xbc+8)                        ; F99402  ld XIY,(XBC+0x08)
	cp	xiy, xwa                            ; F99405  cp XIY,XWA
	jr nz, Queue_Get_IrqGuarded__F99410                       ; F99407  jr NZ,0xf99410
	ld	xwa, (xbc)                          ; F99409  ld XWA,(XBC)
	ld	(xbc+8), xwa                        ; F9940B  ld (XBC+0x08),XWA
	jr Queue_Get_IrqGuarded__F9941A                           ; F9940E  jr T,0xf9941a
Queue_Get_IrqGuarded__F99410:
	ld	xbc, (xiz+8)                        ; F99410  ld XBC,(XIZ+0x08)
	sub	xwa, xwa                           ; F99413  sub XWA,XWA
	inc	1, xwa                             ; F99415  inc 1,XWA
	add	(xbc+8), xwa                       ; F99417  add (XBC+0x08),XWA
Queue_Get_IrqGuarded__F9941A:
	ei	6                                   ; F9941A  ei 0x06
	ld	xbc, (xiz+8)                        ; F9941C  ld XBC,(XIZ+0x08)
	incw	1, (xbc+20)                       ; F9941F  incw 1,(XBC+0x14)
	ei	0                                     ; F99422  ei 0x00
	ld	bc, (xiz-1)                         ; F99424  ld BC,(XIZ+0xff)
	extz	bc                                ; F99427  extz BC
	ld	wa, bc                              ; F99429  ld WA,BC
Queue_Get_IrqGuarded__F9942B:
	pop	xix                                ; F9942B  pop XIX
	unlk32 xiz                             ; F9942C  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; F9942E  ret

; --------------------------------------------------------------------------
; Queue_Get -- Queue_Get_IrqGuarded without the guard.
;
; Called from: 0xF99274, the `calr 0xF9942F` inside INTTX0_HANDLER -- which is
;          already inside an interrupt, so the guard would be pointless.  One site.
; Inputs / Outputs: as Queue_Get_IrqGuarded.
; Evidence: 87 bytes against the guarded version's 91; aligned byte by byte the
;          difference is the two inserted pairs `06 06` / `06 00` plus the two
;          branch-displacement bytes at this routine's offsets +0x18 and +0x1A that
;          moved with them.
; Unknown:  nothing.
; --------------------------------------------------------------------------
Queue_Get:
	link32 0xEE, 0x0C, 0xFF, 0xFF          ; F9942F  link XIZ,0xffff   [llvm-mc cannot encode this]
	push	xix                               ; F99433  push XIX
	ld	xbc, (xiz+8)                        ; F99434  ld XBC,(XIZ+0x08)
	ld	xwa, (xbc+12)                       ; F99437  ld XWA,(XBC+0x0c)
	ld	xix, xwa                            ; F9943A  ld XIX,XWA
	ld	xiy, (xbc+8)                        ; F9943C  ld XIY,(XBC+0x08)
	cp	xiy, xwa                            ; F9943F  cp XIY,XWA
	jr nz, Queue_Get__F9944A                       ; F99441  jr NZ,0xf9944a
	ldw	wa, 0xFFFF                         ; F99443  ld WA,0xffff
	jr Queue_Get__F99482                           ; F99446  jr T,0xf99482
	jr Queue_Get__F99482                           ; F99448  jr T,0xf99482
Queue_Get__F9944A:
	ld	xbc, (xiz+8)                        ; F9944A  ld XBC,(XIZ+0x08)
	ld	xwa, (xbc+8)                        ; F9944D  ld XWA,(XBC+0x08)
	ld	c, (xwa)                            ; F99450  ld C,(XWA)
	ld	(xiz-1), c                          ; F99452  ld (XIZ+0xff),C
	ld	xbc, (xiz+8)                        ; F99455  ld XBC,(XIZ+0x08)
	ld	xwa, (xbc+4)                        ; F99458  ld XWA,(XBC+0x04)
	ld	xix, xwa                            ; F9945B  ld XIX,XWA
	ld	xiy, (xbc+8)                        ; F9945D  ld XIY,(XBC+0x08)
	cp	xiy, xwa                            ; F99460  cp XIY,XWA
	jr nz, Queue_Get__F9946B                       ; F99462  jr NZ,0xf9946b
	ld	xwa, (xbc)                          ; F99464  ld XWA,(XBC)
	ld	(xbc+8), xwa                        ; F99466  ld (XBC+0x08),XWA
	jr Queue_Get__F99475                           ; F99469  jr T,0xf99475
Queue_Get__F9946B:
	ld	xbc, (xiz+8)                        ; F9946B  ld XBC,(XIZ+0x08)
	sub	xwa, xwa                           ; F9946E  sub XWA,XWA
	inc	1, xwa                             ; F99470  inc 1,XWA
	add	(xbc+8), xwa                       ; F99472  add (XBC+0x08),XWA
Queue_Get__F99475:
	ld	xbc, (xiz+8)                        ; F99475  ld XBC,(XIZ+0x08)
	incw	1, (xbc+20)                       ; F99478  incw 1,(XBC+0x14)
	ld	bc, (xiz-1)                         ; F9947B  ld BC,(XIZ+0xff)
	extz	bc                                ; F9947E  extz BC
	ld	wa, bc                              ; F99480  ld WA,BC
Queue_Get__F99482:
	pop	xix                                ; F99482  pop XIX
	unlk32 xiz                             ; F99483  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; F99485  ret

; --------------------------------------------------------------------------
; Queue_Peek_Cursor2 -- read a byte through the descriptor's SECOND cursor at
;             +0x10, without touching the free count.
;
; Called from: NOT FOUND (notes/prom_c_xrefs.py 0xF99486: no literal, no calr).
; Inputs:  (XIZ+0x08) descriptor pointer.
; Outputs: WA = the byte, or 0xFFFF when the second cursor has caught up with the
;          WRITE cursor.
; Evidence: every access is to `(XBC+0x10)` where Queue_Get uses `(XBC+0x08)`, and
;          the free count at +0x14 is never touched -- so this cursor consumes
;          nothing and a byte can be read twice, once by each.  That is what makes
;          +0x10 a second reader rather than a copy of the first.
;          Both descriptors' boot images set +0x08, +0x0C and +0x10 to the same
;          address (`python3 notes/prom_c_ram_image.py 0x00F2FB:22`).
; Unknown:  ⚠ what the second reader is FOR.  Nothing calls this routine, so the
;          field exists in the struct and in this code and nowhere else that has
;          been found.
; --------------------------------------------------------------------------
Queue_Peek_Cursor2:
	link32 0xEE, 0x0C, 0xFF, 0xFF          ; F99486  link XIZ,0xffff   [llvm-mc cannot encode this]
	push	xix                               ; F9948A  push XIX
	ld	xbc, (xiz+8)                        ; F9948B  ld XBC,(XIZ+0x08)
	ld	xwa, (xbc+12)                       ; F9948E  ld XWA,(XBC+0x0c)
	ld	xix, xwa                            ; F99491  ld XIX,XWA
	ld	xiy, (xbc+16)                       ; F99493  ld XIY,(XBC+0x10)
	cp	xiy, xwa                            ; F99496  cp XIY,XWA
	jr nz, Queue_Peek_Cursor2__F994A1                       ; F99498  jr NZ,0xf994a1
	ldw	wa, 0xFFFF                         ; F9949A  ld WA,0xffff
	jr Queue_Peek_Cursor2__F994D3                           ; F9949D  jr T,0xf994d3
	jr Queue_Peek_Cursor2__F994AC                           ; F9949F  jr T,0xf994ac
Queue_Peek_Cursor2__F994A1:
	ld	xbc, (xiz+8)                        ; F994A1  ld XBC,(XIZ+0x08)
	ld	xwa, (xbc+16)                       ; F994A4  ld XWA,(XBC+0x10)
	ld	c, (xwa)                            ; F994A7  ld C,(XWA)
	ld	(xiz-1), c                          ; F994A9  ld (XIZ+0xff),C
Queue_Peek_Cursor2__F994AC:
	ld	xbc, (xiz+8)                        ; F994AC  ld XBC,(XIZ+0x08)
	ld	xwa, (xbc+4)                        ; F994AF  ld XWA,(XBC+0x04)
	ld	xix, xwa                            ; F994B2  ld XIX,XWA
	ld	xiy, (xbc+16)                       ; F994B4  ld XIY,(XBC+0x10)
	cp	xiy, xwa                            ; F994B7  cp XIY,XWA
	jr nz, Queue_Peek_Cursor2__F994C2                       ; F994B9  jr NZ,0xf994c2
	ld	xwa, (xbc)                          ; F994BB  ld XWA,(XBC)
	ld	(xbc+16), xwa                       ; F994BD  ld (XBC+0x10),XWA
	jr Queue_Peek_Cursor2__F994CC                           ; F994C0  jr T,0xf994cc
Queue_Peek_Cursor2__F994C2:
	ld	xbc, (xiz+8)                        ; F994C2  ld XBC,(XIZ+0x08)
	sub	xwa, xwa                           ; F994C5  sub XWA,XWA
	inc	1, xwa                             ; F994C7  inc 1,XWA
	add	(xbc+16), xwa                      ; F994C9  add (XBC+0x10),XWA
Queue_Peek_Cursor2__F994CC:
	ld	bc, (xiz-1)                         ; F994CC  ld BC,(XIZ+0xff)
	extz	bc                                ; F994CF  extz BC
	ld	wa, bc                              ; F994D1  ld WA,BC
Queue_Peek_Cursor2__F994D3:
	pop	xix                                ; F994D3  pop XIX
	unlk32 xiz                             ; F994D4  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; F994D6  ret

; --------------------------------------------------------------------------
; Queue_FreeSlots -- return the descriptor's free-slot count.
;
; Called from: 0xF991EF, the `calr 0xF994D7` inside MIDI_Rx_FreeSlots.  One site.
; Inputs:  (XIZ+0x08) descriptor pointer -- that site passes the RECEIVE
;          descriptor 0x00F2FB.  ⚠ The address above is a VARIABLE, not a call site.  It is stated here rather than in `Called from:` because notes/prom_c_audit_callsites.py harvests every 0xXXXXXX in that paragraph and cannot tell prose from a citation.
;          Outputs: WA = the u16 at +0x14.
; Evidence: three instructions and a return.
; Unknown:  nothing.
; --------------------------------------------------------------------------
Queue_FreeSlots:
	link32 0xEE, 0x0C, 0x00, 0x00          ; F994D7  link XIZ,0x0000   [llvm-mc cannot encode this]
	ld	xbc, (xiz+8)                        ; F994DB  ld XBC,(XIZ+0x08)
	ld	wa, (xbc+20)                        ; F994DE  ld WA,(XBC+0x14)
	unlk32 xiz                             ; F994E1  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; F994E3  ret

; --------------------------------------------------------------------------
; ★★ MIDI_Watchdogs_And_TransportSwitch -- active sensing out, active sensing in,
;             and the P8 bit 2 transport input.  Three unrelated jobs in one
;             routine because MAIN calls it once per pass.
;
; Called from: 0xF98CAE (`call 0xF994E4`), the last call in MAIN's loop body.  One
;          site.
; Inputs:  the tick counter 0x00F2F3; the two timestamps 0x007ED2 (last transmit)
;          and 0x007ED6 (last receive, written by INTRX0_HANDLER); the received
;          active-sensing flag 0x00F2F8; port P8 bit 2; the transport state
;          0x00F328.
; Outputs: MIDI_Tx_PutByte(0xFE); Link_SendBuffer(channel 6, length 1, pointer)
;          for the three single-byte messages at 0xFCC5C2, 0xFCC5C3 and 0xFCC5C4.
; Evidence, arm by arm:
;   1. `(0x00F2F3) - (0x007ED2) > 0x87` -> re-stamp 0x007ED2 and `push 0x00FE /
;      calr 0xF992C6`.  0x00FE is an immediate in the instruction, not a table
;      lookup.
;   2. `(0x00F2F8) != 0` AND `(0x00F2F3) - (0x007ED6) > 0xA5` -> clear the flag and
;      send the byte at 0xFCC5C2 (= 0xFF).  0x00F2F8 is set by INTRX0_HANDLER on a
;      received 0xFE and by nothing else in this image, and 0x007ED6 is stamped by
;      the same handler on every good byte -- both are already in that handler's
;      converted header.
;      ⚠ `notes/prom_c_xrefs.py 0x00F2F8` reports FOUR literal-addressed hits, not
;      three.  The extra one, at 0xFBE149, is a byte coincidence: the bytes
;      `e1 f8 f2` there are the tail of `calr 0xFBDA2C` (`1e e1 f8`) followed by
;      the next instruction's prefix.  Checked by disassembling, not assumed.
;   3. `res 2,(P8)` then read P8 and test bit 2.  Clear and `(0x00F328) != 0` ->
;      send the byte at 0xFCC5C4 (= 0xFB) and set 0x00F328 = 0.  Set and
;      `(0x00F328) != 1` -> send the byte at 0xFCC5C3 (= 0xFA) and set
;      0x00F328 = 1.  So the messages go out only on a CHANGE.
; ★ 0x00F328's third value is written elsewhere: Link_Ch2_ForwardBytes sets it to
;   0xFF when CPU 1 sends the byte 0xFA on link channel 2.  0xFF is neither 0 nor
;   1, so the next P8 transition in either direction will send a message.  All five
;   literal-addressed sites of 0x00F328 are accounted for.
; ⚠ NOT ESTABLISHED: what P8 bit 2 is wired to.  `res 2,(P8)` before reading it is
;   the shape of driving a line low and sampling it, which is how an open-collector
;   input is read, but the port direction registers are set in RESET and P8CR's bit
;   layout is not decoded anywhere in this tree.
; ⚠ NOT ESTABLISHED: the tick rate.  See the timing paragraph in the block comment
;   above -- the 135/165-tick pair is consistent with MIDI's 300 ms active-sensing
;   rule, but that is an argument from the standard, not from this ROM.
; --------------------------------------------------------------------------
MIDI_Watchdogs_And_TransportSwitch:
	link32 0xEE, 0x0C, 0xFC, 0xFF          ; F994E4  link XIZ,0xfffc   [llvm-mc cannot encode this]
	ld	xbc, (0xF2F3:24)                   ; F994E8  ld XBC,(0x00f2f3)
	sub32_24	xbc, (0x7ED2)                 ; F994ED  sub XBC,(0x007ed2)
	ld	(xiz-4), xbc                        ; F994F2  ld (XIZ+0xfc),XBC
	cp	xbc, 0x87                           ; F994F5  cp XBC,0x00000087
	jr ule, MIDI_Watchdogs_And_TransportSwitch__F9950E                      ; F994FB  jr ULE,0xf9950e
	ld	xwa, (0xF2F3:24)                   ; F994FD  ld XWA,(0x00f2f3)
	stl_da	(0x7ED2), xwa                   ; F99502  ld (0x007ed2),XWA
	pushw	0xFE                             ; F99507  push 0x00fe
	calr (0xF992C6 - 0xF9950D)             ; F9950A  calr 0xf992c6
	popw	bc                                ; F9950D  pop BC
MIDI_Watchdogs_And_TransportSwitch__F9950E:
	cpib_da 0x00F2F8, 0x00                 ; F9950E  cp (0x00f2f8),0x00   [llvm-mc cannot encode this]
	jr z, MIDI_Watchdogs_And_TransportSwitch__F99543                        ; F99514  jr Z,0xf99543
	ld	xbc, (0xF2F3:24)                   ; F99516  ld XBC,(0x00f2f3)
	sub32_24	xbc, (0x7ED6)                 ; F9951B  sub XBC,(0x007ed6)
	ld	(xiz-4), xbc                        ; F99520  ld (XIZ+0xfc),XBC
	cp	xbc, 0xA5                           ; F99523  cp XBC,0x000000a5
	jr ule, MIDI_Watchdogs_And_TransportSwitch__F99543                      ; F99529  jr ULE,0xf99543
	ld	(0xF2F8:24), 0                    ; F9952B  ld (0x00f2f8),0x00
	lda	xwa, (0xFCC5C2:24)                 ; F99531  lda XWA,0xfcc5c2
	push	xwa                               ; F99536  push XWA
	pushw	1                                ; F99537  push 0x0001
	pushw	6                                ; F9953A  push 0x0006
	call	0xF98B20                          ; F9953D  call 0xf98b20
	inc	8, xsp                             ; F99541  inc 0,XSP
MIDI_Watchdogs_And_TransportSwitch__F99543:
	res_dd8	2, P8                          ; F99543  res 2,(0x18)
	ld_sd8b	c, 24                          ; F99546  ld C,(0x18)
	and	c, 4                               ; F99549  and C,0x04
	srl	c, 2                               ; F9954C  srl 0x02,C
	cps	c, 0                               ; F9954F  cp C,0
	jr nz, MIDI_Watchdogs_And_TransportSwitch__F99575                       ; F99551  jr NZ,0xf99575
	cpib_da 0x00F328, 0x00                 ; F99553  cp (0x00f328),0x00   [llvm-mc cannot encode this]
	jr z, MIDI_Watchdogs_And_TransportSwitch__F99573                        ; F99559  jr Z,0xf99573
	lda	xbc, (0xFCC5C4:24)                 ; F9955B  lda XBC,0xfcc5c4
	push	xbc                               ; F99560  push XBC
	pushw	1                                ; F99561  push 0x0001
	pushw	6                                ; F99564  push 0x0006
	call	0xF98B20                          ; F99567  call 0xf98b20
	ld	(0xF328:24), 0                    ; F9956B  ld (0x00f328),0x00
	inc	8, xsp                             ; F99571  inc 0,XSP
MIDI_Watchdogs_And_TransportSwitch__F99573:
	jr MIDI_Watchdogs_And_TransportSwitch__F99595                           ; F99573  jr T,0xf99595
MIDI_Watchdogs_And_TransportSwitch__F99575:
	cpib_da 0x00F328, 0x01                 ; F99575  cp (0x00f328),0x01   [llvm-mc cannot encode this]
	jr z, MIDI_Watchdogs_And_TransportSwitch__F99595                        ; F9957B  jr Z,0xf99595
	lda	xbc, (0xFCC5C3:24)                 ; F9957D  lda XBC,0xfcc5c3
	push	xbc                               ; F99582  push XBC
	pushw	1                                ; F99583  push 0x0001
	pushw	6                                ; F99586  push 0x0006
	call	0xF98B20                          ; F99589  call 0xf98b20
	ld	(0xF328:24), 1                    ; F9958D  ld (0x00f328),0x01
	inc	8, xsp                             ; F99593  inc 0,XSP
MIDI_Watchdogs_And_TransportSwitch__F99595:
	unlk32 xiz                             ; F99595  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; F99597  ret
