; =============================================================================
; BOOT-TIME CONTROL-PANEL SERIAL-LINK DRIVER (interrupt entry half)
; =============================================================================
; ROM range 0x9ff229-0x9ff2f1 (formerly includes/bootcode_serial_handlers.bin).
; Boot-time alias: executes at 0xfff229-0xfff2f1; the interrupt vector table
; (BOOT_INTA_HANDLER / BOOT_INTTX1_HANDLER / BOOT_INTRX1_HANDLER .equs) holds
; the 0xffxxxx aliases of the three handlers below.
;
; This is the interrupt half of the first-stage bootloader's CP-serial driver.
; The polling/setup half is boot_cpserial.s (0x9fec6e-0x9ff228); the per-state
; handlers, packet codecs and ring helpers dispatched from here live in
; boot_cpserial_states.s (0x9ff2f2+).  Like the rest of this driver it is
; INDEPENDENT of the runtime CPanel_* protocol stack in the program ROM.
;
; Interrupt roles:
;   Handler_INTA    external interrupt A - the panel pulls the INTA line both
;                   to open a receive transfer and to pace one during RX
;   Handler_INTTX1  serial channel 1 TX-buffer-empty - drives the transmit
;                   states of the link state machine
;   Handler_INTRX1  serial channel 1 RX-buffer-full - drives the receive
;                   states of the link state machine
;
; Both SC1 handlers dispatch through BootSerial_StateDispatchTable, indexed by
; the state byte (0x0f62).  The state variable is a RAW TABLE OFFSET stepped
; in units of 4 (values 0x00, 0x04, ... 0x28), advanced/retreated with
; inc/dec 4, so no scaling is needed before the table lookup.
;
; NOTE FOR EMULATOR AUTHORS: all THREE epilogues below (Handler_INTA__exit,
; BootSerial_TxIsrEpilogue, BootSerial_RxIsrEpilogue) write the same three
; values to INTCLR -- 0x12 = INTA, 0x22 = INTRX1, 0x23 = INTTX1.  Those are
; interrupt VECTOR NUMBERS, not vector addresses, in the numbering reconstructed
; from the ROMs in v142/subcpu/subcpu_vectors.s: vector 34 = INTRX1, 35 =
; INTTX1, and vectors 10..19 are the external interrupts INT0, INT3..INTB,
; which puts INTA at 18 = 0x12 -- consistent with this handler arming INTEAB.
; The same numbering gives INT0 = 10, which is what the sub CPU writes into
; DMA0V.  So whichever of the three handlers runs, it discards the pending
; requests of the other two as well.
; INFERENCE: that is deliberate re-synchronisation of the link, but it means a
; request of the other two kinds raised while a handler is executing is LOST,
; not deferred -- worth knowing before blaming a driver for a dropped byte.
;
; This is the CONTROL-PANEL serial link (SC1 + INTA).  It is unrelated to the
; main-CPU/sub-CPU inter-CPU LATCH link, which also runs on /INT0 but on the
; IC22/IC23 latches; that protocol and its re-entrancy hazard are documented at
; INT0_HANDLER in v10/maincpu/boot/system_handlers.s.
; =============================================================================

; -----------------------------------------------------------------------------
; Handler_INTA - external interrupt A from the panel
; (0x0f63) == 0 (idle): the panel is requesting to send - program the SC1
; pins/control for receive (PFCR mode bits low, SC1CR bit0 set/bit1 clear,
; INTEAB = 0x05, INTES1 = 0x0d, SC1MOD bit5 set), arm state 0x20 (RX first
; byte) and set the RX-active flag (0x0f64) bit 0.
; (0x0f63) != 0 (a receive transfer is in flight): reload the RX progress
; counter (0x0f77) with the 0x005c ring size when it is zero, step it down,
; set status bit 6 in (0x0f6a) and clear the TX-pending flag (0x0f64) bit 1.
; Common exit clears INTA/INTRX1/INTTX1 in INTCLR.
; Callers: INTA vector (boot 0xfff229); armed by BootSerial_FullInit /
;          BootSerial_SendFrame (INTEAB writes in boot_cpserial.s)
; -----------------------------------------------------------------------------
Handler_INTA:
	push	xwa
	cpdi8	(0x0f63), 0
	jr	nz, Handler_INTA__rx_pacing
	anddi8	(0x0f66), 0x9f		; PFCR shadow: SC1 pins to RX mode
	ld	a, (0x0f66:16)
	st_dd8b	a, 0x3e			; PFCR
	or_sd8b_im 0xd5, 0x01		; SC1CR bit 0 high
	and_sd8b_im 0xd5, 0xfd		; SC1CR bit 1 low
	ldio	0xe3, 0x05		; INTEAB
	ldio	0xeb, 0x0d		; INTES1: RX enabled
	or_sd8b_im 0xd6, 0x20		; SC1MOD bit 5
	stdi8	(0x0f62), 0x20		; state 0x20: RX first byte
	ordi8	(0x0f64), 0x01		; RX-active flag
	jr	t, Handler_INTA__exit
Handler_INTA__rx_pacing:
	cpdi16	(0x0f77), 0
	jr	nz, Handler_INTA__count_ok
	stdi16	(0x0f77), 0x005c	; reload with the RX ring size
Handler_INTA__count_ok:
	decdi16	1, (0x0f77)
	ordi8	(0x0f6a), 0x40		; status: INTA seen mid-transfer
	anddi8	(0x0f64), 0xfd		; clear TX-pending flag
Handler_INTA__exit:
	pop	xwa
	ldio	0xf8, 0x12		; INTCLR: INTA
	ldio	0xf8, 0x22		; INTCLR: INTRX1
	ldio	0xf8, 0x23		; INTCLR: INTTX1
	reti

; -----------------------------------------------------------------------------
; BootSerial_StateDispatchTable - 11 x .long, indexed by the raw state byte
; (0x0f62) (offsets 0x00..0x28 in steps of 4).  Entries hold BOOT-TIME
; (0xffxxxx) addresses = ROM label + 0x600000; every target lives in
; boot_cpserial_states.s and returns through one of the two ISR epilogues
; below.  States 0x00/0x1c/0x28 share the abort handler.
; -----------------------------------------------------------------------------
BootSerial_StateDispatchTable:
	.long	BootSerial_State_Abort + 0x600000		; 0x00 idle/abort
	.long	BootSerial_State04_TxLineRequest + 0x600000	; 0x04
	.long	BootSerial_State08_TxFirstByte + 0x600000	; 0x08
	.long	BootSerial_State0C_TxByteGap + 0x600000		; 0x0c
	.long	BootSerial_State10_TxNextByte + 0x600000	; 0x10
	.long	BootSerial_State14_TxTail + 0x600000		; 0x14
	.long	BootSerial_State18_TxFrameDone + 0x600000	; 0x18
	.long	BootSerial_State_Abort + 0x600000		; 0x1c abort
	.long	BootSerial_State20_RxFirstByte + 0x600000	; 0x20
	.long	BootSerial_State24_RxNextByte + 0x600000	; 0x24
	.long	BootSerial_State_Abort + 0x600000		; 0x28 abort

; -----------------------------------------------------------------------------
; Handler_INTTX1 - serial channel 1 transmit interrupt
; Dispatches to the state handler selected by (0x0f62); the TX-side state
; handlers jump back to BootSerial_TxIsrEpilogue.
; Callers: INTTX1 vector (boot 0xfff2ae)
; -----------------------------------------------------------------------------
Handler_INTTX1:
	push	xwa
	push	xhl
	push	xiy
	ld	l, (0x0f62:16)
	xor	h, h
	extz	xhl
	add	xhl, BootSerial_StateDispatchTable + 0x600000	; boot-time alias
	ld	xhl, (xhl)
	jp	(xhl)
BootSerial_TxIsrEpilogue:
	pop	xiy
	pop	xhl
	pop	xwa
	ldio	0xf8, 0x12		; INTCLR: INTA
	ldio	0xf8, 0x22		; INTCLR: INTRX1
	ldio	0xf8, 0x23		; INTCLR: INTTX1
	reti

; -----------------------------------------------------------------------------
; Handler_INTRX1 - serial channel 1 receive interrupt
; Identical dispatch; the RX-side state handlers jump back to
; BootSerial_RxIsrEpilogue.
; Callers: INTRX1 vector (boot 0xfff2d0)
; -----------------------------------------------------------------------------
Handler_INTRX1:
	push	xwa
	push	xhl
	push	xiy
	ld	l, (0x0f62:16)
	xor	h, h
	extz	xhl
	add	xhl, BootSerial_StateDispatchTable + 0x600000	; boot-time alias
	ld	xhl, (xhl)
	jp	(xhl)
BootSerial_RxIsrEpilogue:
	pop	xiy
	pop	xhl
	pop	xwa
	ldio	0xf8, 0x12		; INTCLR: INTA
	ldio	0xf8, 0x22		; INTCLR: INTRX1
	ldio	0xf8, 0x23		; INTCLR: INTTX1
	reti
