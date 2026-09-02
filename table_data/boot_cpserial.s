; =============================================================================
; BOOT-TIME CONTROL-PANEL SERIAL-LINK DRIVER (polling/setup half)
; =============================================================================
; ROM range 0x9fec6e-0x9ff228.  Boot-time alias: executes at 0xffec6e-0xfff228
; (labels below are at ROM addresses; absolute boot-time addresses appear in
; comments, and the three CALL-absolute sites in this module must stay numeric
; 0xffxxxx because the CPU runs this code only through the boot mapping).
;
; *** THIS IS THE FIRST-STAGE BOOTLOADER'S OWN CP-SERIAL DRIVER. ***
; *** IT IS INDEPENDENT OF THE RUNTIME CP-SERIAL IMPLEMENTATION. ***
; The runtime control-panel protocol stack (CPanel_* in the maincpu program
; ROM, documented in kn5000-docs/control-panel-protocol.md) is a separate
; implementation that takes over only after the bootloader hands control to
; the main program.  When investigating CP-serial behaviour, keep findings
; from the two drivers apart: nothing proven here transfers to the runtime
; driver, and vice versa.
;
; Hardware used (TMP94C241 SFRs, names from shared/sfr_tmp94c241.s):
;   SC1BUF/SC1CR/SC1MOD/BR1CR (0xd4-0xd7)  serial channel 1
;   PFCR/PFFC (0x3e/0x3f), PF (0x3c)       port F pin setup (SC1 pins),
;                                          shadowed at (0x0f66)/(0x0f67)
;   PECR/PEFC (0x3a/0x3b), PE (0x38)       port E pin setup / PE5 status line
;   INTEAB (0xe3), INTES1 (0xeb)           INTA + serial-1 interrupt enables
;   INTCLR (0xf8)                          int clear (0x12 INTA?, 0x22/0x23
;                                          INTRX1/INTTX1)
;   TAMOD (0xc8)                           timer A mode (baud source select)
;
; The interrupt half lives in the two neighbouring blobs: the INTA/INTRX1/
; INTTX1 handlers + state dispatch table (bootcode_serial_handlers.bin,
; 0x9ff229+) and the per-state handlers, ring helpers and packet codecs
; (bootcode_serial_state.bin, 0x9ff2f2+).  Shared state driven from here:
;   (0x0f62) state-machine byte offset (steps of 4, dispatch via 0xfff282)
;   (0x0f63) INTA mode flag       (0x0f64) link flags (bit0 RX, bit1 TX,...)
;   (0x0f6a) status/abort flags   (0x0f6b) loopback result bits
;   (0x0f6f) WaitTxIdle countdown (0x0f73) tick-delay scratch
;   (0x0f75)/(0x0f77) RX progress counters
;   (0x0fd5)/(0x0fd7) TX ring send index / pending count
;   (0x0fd9) TX ring (0x3c bytes); (0x0f79) RX ring (0x5c bytes)
;   0x988a / 0x9914  RX / TX transfer-control blocks: ring base at the
;       address itself, tail word at base-8, head word at base-4, wrap size
;       0x0080 at base-2 (the (xhl-8/-4/-2) displacements are SIGNED)
;   0x1022+ decoded-packet buffer filled by the INTRX1 packet handlers
;       (device-ident bytes read back by Boot_ClassifyDeviceID)
; =============================================================================

; -----------------------------------------------------------------------------
; BootSerial_InitVectorTable - 4-entry .long table of boot-time entry points
; Read by Boot_Init (boot 0xffb669): ldl_da xhl, (0xffec6e); call (xhl) --
; i.e. only entry[0] (BootSerial_Init) is ever fetched in this build; the
; other three entries point at bare-ret stubs (no-op init variants).
; Entries hold BOOT-TIME (0xffxxxx) addresses = ROM label + 0x600000.
; -----------------------------------------------------------------------------
BootSerial_InitVectorTable:
	.long	BootSerial_Init + 0x600000	; [0] full init (the one used)
	.long	BootSerial_Init_Nop2 + 0x600000	; [1] no-op variant
	.long	BootSerial_Init_Nop2 + 0x600000	; [2] no-op variant
	.long	BootSerial_Init_Nop1 + 0x600000	; [3] no-op variant

; -----------------------------------------------------------------------------
; BootSerial_Init - top-level boot CP-serial bring-up
; ei 0; three 51-tick delays; full SC1/ring/state init (BootSerial_FullInit,
; which also runs the opening handshake); four 6-tick delays; then blocks in
; BootSerial_WaitDeviceIdent until the device-ident answer is stable.
; Inputs:  none    Outputs: none
; Callers: entry [0] of BootSerial_InitVectorTable, fetched and called by
;          Boot_Init at boot 0xffb669
; -----------------------------------------------------------------------------
BootSerial_Init:
	ei	0
	calr	BootSerial_TickWait51
	calr	BootSerial_TickWait51
	calr	BootSerial_TickWait51
	calr	BootSerial_FullInit
	calr	BootSerial_TickWait6
	calr	BootSerial_TickWait6
	calr	BootSerial_TickWait6
	calr	BootSerial_TickWait6
	calr	BootSerial_WaitDeviceIdent
	ret

; -----------------------------------------------------------------------------
; BootSerial_Init_Nop1 - no-op init variant (vector entry [3])
; -----------------------------------------------------------------------------
BootSerial_Init_Nop1:
	ret

; -----------------------------------------------------------------------------
; BootSerial_ModeSwitch - advance the link-mode field in (0x0f64) bits 7:6
; Reads the mode field (0x00 -> 0x40 is a plain re-arm, 0x40 -> 0x80,
; 0x80 -> 0xc0; 0xc0 -> full BootSerial_ResetAndIdent), stores the new mode,
; resets the RX transfer-control block (0x988a) and the RX progress counters,
; then parses any pending RX packets.
; Inputs:  (0x0f64) bits 7:6 = current mode    Outputs: (0x0f64) updated
; Callers: NONE FOUND (no static reference in table_data or maincpu ROMs,
;          boot- or run-time address) -- retained factory/diagnostic code
; -----------------------------------------------------------------------------
BootSerial_ModeSwitch:
	ld	a, (0x0f64:16)
	and	a, 0xc0			; isolate mode field
	anddi8	(0x0f64), 0x3f		; strip it from the flags byte
	cps	a, 0
	jr	z, BootSerial_ModeSwitch__parse	; mode 0: just re-arm + parse
	cp	a, 0x40
	jr	nz, BootSerial_ModeSwitch__not40
	ldb	a, 0x80			; 0x40 -> 0x80
	jr	BootSerial_ModeSwitch__apply
BootSerial_ModeSwitch__not40:
	cp	a, 0x80
	jr	nz, BootSerial_ModeSwitch__not80
	ldb	a, 0xc0			; 0x80 -> 0xc0
	jr	BootSerial_ModeSwitch__apply
BootSerial_ModeSwitch__not80:
	cp	a, 0xc0
	jr	nz, BootSerial_ModeSwitch__apply	; unknown: store as-is
	calr	BootSerial_ResetAndIdent	; 0xc0: full reset + re-ident
	jr	BootSerial_ModeSwitch__ret
BootSerial_ModeSwitch__apply:
	orddm8	0x0f64, a		; merge new mode into flags
	ld	xhl, 0x988a		; RX transfer-control block
	ldw	(xhl - 4), 0		; head (0x9886) = 0
	ldw	(xhl - 8), 0		; tail (0x9882) = 0
	ldw	(xhl - 2), 0x80		; wrap size (0x9888) = 0x80
	ei	6			; mask serial interrupts
	ldw	(0x0f75:16), 0
	ldw	(0x0f77:16), 0
	ei	0
BootSerial_ModeSwitch__parse:
	calr	BootSerial_RX_ParsePackets
BootSerial_ModeSwitch__ret:
	ret

; -----------------------------------------------------------------------------
; BootSerial_Call_PollTX - plain thunk to BootSerial_PollTX
; Callers: NONE FOUND -- retained factory/diagnostic entry
; -----------------------------------------------------------------------------
BootSerial_Call_PollTX:
	calr	BootSerial_PollTX
	ret

; -----------------------------------------------------------------------------
; BootSerial_Call_ResetAndIdent - register-saving wrapper (XIX/XIZ/XHL/XDE)
; around BootSerial_ResetAndIdent
; Callers: NONE FOUND -- retained factory/diagnostic entry
; -----------------------------------------------------------------------------
BootSerial_Call_ResetAndIdent:
	push	xix
	push	xiz
	push	xhl
	push	xde
	calr	BootSerial_ResetAndIdent
	pop	xde
	pop	xhl
	pop	xiz
	pop	xix
	ret

; -----------------------------------------------------------------------------
; BootSerial_Call_TestLoopback - plain thunk to BootSerial_TestLoopback
; Callers: NONE FOUND -- retained factory/diagnostic entry
; -----------------------------------------------------------------------------
BootSerial_Call_TestLoopback:
	calr	BootSerial_TestLoopback
	ret

; -----------------------------------------------------------------------------
; BootSerial_Call_RetStub - thunk to the stubbed-out routine at 0x9ffa2b
; (BootSerial_RetStub, a bare ret in bootcode_serial_state.bin)
; Callers: NONE FOUND -- retained factory/diagnostic entry
; -----------------------------------------------------------------------------
BootSerial_Call_RetStub:
	calr	BootSerial_RetStub
	ret

; -----------------------------------------------------------------------------
; BootSerial_Init_Nop2 - no-op init variant (vector entries [1] and [2])
; -----------------------------------------------------------------------------
BootSerial_Init_Nop2:
	ret

; -----------------------------------------------------------------------------
; Boot_ProbeExternalDevice - probe + classify the device on the boot CP link
; Runs the four-frame probe exchange (BootSerial_ProbeSequence) with
; XIX/XIZ/XHL/XDE preserved, then classifies the decoded answer.
; Inputs:  none
; Outputs: HL = device class from Boot_ClassifyDeviceID: 0 none/unknown,
;          1/2/3 identified panel devices, 4 = flash-update service device
;          (Boot_Init compares against 4 to decide whether to run the
;          firmware-update UI)
; Callers: Boot_Init (boot 0xffb670)
; -----------------------------------------------------------------------------
Boot_ProbeExternalDevice:
	push	xix
	push	xiz
	push	xhl
	push	xde
	call	0xfff00e		; BootSerial_ProbeSequence (boot-time
					; absolute; ROM label 0x9ff00e)
	pop	xde
	pop	xhl
	pop	xiz
	pop	xix
	calr	Boot_ClassifyDeviceID
	ret

; -----------------------------------------------------------------------------
; BootSerial_FullInit - reset rings, program SC1 + pins, open the handshake
; Resets BOTH transfer-control blocks (RX 0x988a, TX 0x9914), programs the
; port F/E pin functions (keeping shadows of PFCR/PFFC in (0x0f66)/(0x0f67)),
; sets SC1MOD=0x00 / BR1CR=0x14 / SC1CR=0x01, enables INTA + serial-1
; interrupts (clearing 0x12/0x22/0x23 in INTCLR), selects the timer-A baud
; source (TAMOD |= 0x10, &= ~0x08), clears all link state bytes, sends the
; opening frame (0x1f, 0xda), then falls into the four-frame
; BootSerial_HandshakeSequence.
; Inputs:  none    Outputs: link initialised, handshake sent
; Callers: BootSerial_Init (boot 0xffec89)
; -----------------------------------------------------------------------------
BootSerial_FullInit:
	ld	xhl, 0x988a		; RX transfer-control block
	ldw	(xhl - 4), 0
	ldw	(xhl - 8), 0
	ldw	(xhl - 2), 0x80
	ld	xhl, 0x9914		; TX transfer-control block
	ldw	(xhl - 4), 0
	ldw	(xhl - 8), 0
	ldw	(xhl - 2), 0x80
	ldb	a, 0x03
	and	a, 0xaf			; = 0x03
	ld	(0x0f67:16), a		; PFFC shadow
	st_dd8b	a, 0x3f			; PFFC = 0x03
	ldb	a, 0x15
	and	a, 0x8f			; = 0x05
	ld	(0x0f66:16), a		; PFCR shadow
	st_dd8b	a, 0x3e			; PFCR = 0x05
	and_sd8b_im 0x3c, 0xbf		; PF bit 6 low
	ldb	a, 0
	st_dd8b	a, 0x3b			; PEFC = 0x00
	ldb	a, 0x46
	st_dd8b	a, 0x3a			; PECR = 0x46
	ldio	0xd6, 0x00		; SC1MOD
	ldio	0xd7, 0x14		; BR1CR
	ldio	0xd5, 0x01		; SC1CR
	ldio	0xe3, 0x07		; INTEAB: enable INTA
	ldio	0xf8, 0x12		; INTCLR
	ldio	0xeb, 0xff		; INTES1: RX+TX enabled, max priority
	ldio	0xf8, 0x22		; INTCLR: clear INTRX1
	ldio	0xf8, 0x23		; INTCLR: clear INTTX1
	or_sd8b_im 0xc8, 0x10		; TAMOD |= 0x10
	and_sd8b_im 0xc8, 0xf7		; TAMOD &= ~0x08
	ld	(0x0f69:16), 0x7d
	ordi8	(0x0f64), 0x40		; link flag bit 6
	ld	(0x0f63:16), 0		; INTA mode: next INTA enters RX mode
	anddi8	(0x0f64), 0xfc		; clear RX/TX active flags
	ldw	(0x0fd5:16), 0		; TX send index
	ldw	(0x0fd7:16), 0		; TX pending count
	ldw	(0x0f75:16), 0
	ldw	(0x0f77:16), 0
	calr	BootSerial_TickWait6
	ldb	a, 0x1f			; opening frame (0x1f, 0xda)
	ldb	w, 0xda
	calr	BootSerial_SendFrame
	calr	BootSerial_SpinWait3000
	ldw	(0x0fd5:16), 0
	calr	BootSerial_SpinWait3000
	calr	BootSerial_HandshakeSequence
	ret

; -----------------------------------------------------------------------------
; BootSerial_HandshakeSequence - send the four opening handshake frames
; Frames (0x1f,0x1a), (0x1d,0x00), (0xdd,0x03), (0x1e,0x80), each padded with
; 3000-iteration spin delays and a TX-index rewind between attempts; then
; re-arms the interrupt setup (INTES1=0xff, INTCLR 0x22/0x23/0x12,
; SC1MOD &= ~0x20, INTEAB=0x05) and clears the RX progress counters.
; Inputs:  none    Outputs: handshake frames queued/sent
; Callers: fall-in from BootSerial_FullInit (calr at boot 0xffedce)
; -----------------------------------------------------------------------------
BootSerial_HandshakeSequence:
	ldb	a, 0x1f			; frame (0x1f, 0x1a)
	ldb	w, 0x1a
	calr	BootSerial_SendFrame
	calr	BootSerial_SpinWait3000
	ldw	(0x0fd5:16), 0
	calr	BootSerial_SpinWait3000
	ldb	a, 0x1d			; frame (0x1d, 0x00)
	ldb	w, 0x00
	calr	BootSerial_SendFrame
	calr	BootSerial_SpinWait3000
	ldw	(0x0fd5:16), 0
	calr	BootSerial_SpinWait3000
	calr	BootSerial_SpinWait3000
	ldb	a, 0xdd			; frame (0xdd, 0x03)
	ldb	w, 0x03
	calr	BootSerial_SendFrame
	calr	BootSerial_SpinWait3000
	ldw	(0x0fd5:16), 0
	calr	BootSerial_SpinWait3000
	calr	BootSerial_SpinWait3000
	ldb	a, 0x1e			; frame (0x1e, 0x80)
	ldb	w, 0x80
	calr	BootSerial_SendFrame
	calr	BootSerial_SpinWait3000
	calr	BootSerial_SpinWait3000
	calr	BootSerial_SpinWait3000
	ei	6			; mask serial ints while re-arming
	ldio	0xeb, 0xff		; INTES1
	ldio	0xf8, 0x22		; INTCLR: INTRX1
	ldio	0xf8, 0x23		; INTCLR: INTTX1
	and_sd8b_im 0xd6, 0xdf		; SC1MOD &= ~0x20
	ldio	0xf8, 0x12		; INTCLR
	ldio	0xe3, 0x05		; INTEAB
	ldw	(0x0f75:16), 0
	ldw	(0x0f77:16), 0
	ei	0
	ret

; -----------------------------------------------------------------------------
; BootSerial_SendTwoBytes_Bitbang - send a 2-byte frame by bit-banging
; Manual fallback transmitter: stores WA into the TX ring head (0x0fd9),
; toggles the SC1 pins through PFCR/PFFC (shadows 0x0f66/0x0f67) with
; 300-iteration spin delays to clock the line, pushes both bytes through
; SC1BUF, pulses SC1CR bit 0, then restores the pin setup.
; Inputs:  WA = the two frame bytes (A first, W second)
; Outputs: (0x0fd5) advanced by 2
; Callers: NONE FOUND (no static reference, boot- or run-time address) --
;          retained factory/diagnostic code, and the only user of
;          BootSerial_SpinWait300
; -----------------------------------------------------------------------------
BootSerial_SendTwoBytes_Bitbang:
	ld	(0x0fd9:16), wa		; frame bytes into TX ring head
	anddi8	(0x0f67), 0xbf
	ld	a, (0x0f67:16)
	st_dd8b	a, 0x3f			; PFFC with bit 6 low
	ldio	0xeb, 0xff		; INTES1
	ldio	0xf8, 0x22		; INTCLR: INTRX1
	ldio	0xf8, 0x23		; INTCLR: INTTX1
	ldio	0xe3, 0x07		; INTEAB
	ldio	0xf8, 0x12		; INTCLR
	and_sd8b_im 0x3c, 0xbf		; PF bit 6 low
	ordi8	(0x0f66), 0x40
	ld	a, (0x0f66:16)
	st_dd8b	a, 0x3e			; PFCR with bit 6 high
	calr	BootSerial_SpinWait300
	calr	BootSerial_SpinWait300
	anddi8	(0x0f66), 0xbf
	ld	a, (0x0f66:16)
	st_dd8b	a, 0x3e			; PFCR bit 6 back low  (clock pulse)
	calr	BootSerial_SpinWait300
	calr	BootSerial_SpinWait300
	ordi8	(0x0f67), 0x50
	ld	a, (0x0f67:16)
	st_dd8b	a, 0x3f			; PFFC bits 6:4 pattern 0x50
	ordi8	(0x0f66), 0x50
	ld	a, (0x0f66:16)
	st_dd8b	a, 0x3e			; PFCR likewise
	and_sd8b_im 0xd5, 0xfe		; SC1CR bit 0 low
	ldio	0xeb, 0xff		; INTES1
	ldio	0xf8, 0x22
	ldio	0xf8, 0x23
	ld	xiy, 0x0fd9		; TX ring
	addda16	xiy, 0x0fd5		; + send index
	ld	a, (xiy)
	incdi16	1, (0x0fd5)
	st_dd8b	a, 0xd4			; first byte -> SC1BUF
	calr	BootSerial_SpinWait300
	calr	BootSerial_SpinWait300
	ld	xiy, 0x0fd9
	addda16	xiy, 0x0fd5
	ld	a, (xiy)
	incdi16	1, (0x0fd5)
	st_dd8b	a, 0xd4			; second byte -> SC1BUF
	calr	BootSerial_SpinWait300
	calr	BootSerial_SpinWait300
	or_sd8b_im 0xd5, 0x01		; pulse SC1CR bit 0
	and_sd8b_im 0xd5, 0xfd		; SC1CR bit 1 low
	anddi8	(0x0f66), 0xaf
	ld	a, (0x0f66:16)
	st_dd8b	a, 0x3e			; restore PFCR
	anddi8	(0x0f67), 0xaf
	ld	a, (0x0f67:16)
	st_dd8b	a, 0x3f			; restore PFFC
	ret

; -----------------------------------------------------------------------------
; BootSerial_SpinWait2/6/10/300/1500/3000 - busy delays, N dec-loop iterations
; Six copies of the same WA countdown loop differing only in the constant.
; Clobbers WA.
; Callers: SpinWait2, SpinWait6: NONE FOUND (factory/diagnostic);
;          SpinWait10: serial state handlers 0x0c and 0x14 (boot 0xfff33d,
;          0xfff36c in bootcode_serial_state.bin);
;          SpinWait300: only BootSerial_SendTwoBytes_Bitbang (8 sites, itself
;          unreferenced);
;          SpinWait1500: BootSerial_WaitTxIdle retry path (boot 0xfff19f);
;          SpinWait3000: 13 sites in BootSerial_FullInit /
;          BootSerial_HandshakeSequence
; -----------------------------------------------------------------------------
BootSerial_SpinWait2:
	lds	wa, 2
BootSerial_SpinWait2__loop:
	dec	1, wa
	cps	wa, 0
	jr	z, BootSerial_SpinWait2__done
	jr	BootSerial_SpinWait2__loop
BootSerial_SpinWait2__done:
	ret

BootSerial_SpinWait6:
	lds	wa, 6
BootSerial_SpinWait6__loop:
	dec	1, wa
	cps	wa, 0
	jr	z, BootSerial_SpinWait6__done
	jr	BootSerial_SpinWait6__loop
BootSerial_SpinWait6__done:
	ret

BootSerial_SpinWait10:
	ldw	wa, 10
BootSerial_SpinWait10__loop:
	dec	1, wa
	cps	wa, 0
	jr	z, BootSerial_SpinWait10__done
	jr	BootSerial_SpinWait10__loop
BootSerial_SpinWait10__done:
	ret

BootSerial_SpinWait300:
	ldw	wa, 300
BootSerial_SpinWait300__loop:
	dec	1, wa
	cps	wa, 0
	jr	z, BootSerial_SpinWait300__done
	jr	BootSerial_SpinWait300__loop
BootSerial_SpinWait300__done:
	ret

BootSerial_SpinWait1500:
	ldw	wa, 1500
BootSerial_SpinWait1500__loop:
	dec	1, wa
	cps	wa, 0
	jr	z, BootSerial_SpinWait1500__done
	jr	BootSerial_SpinWait1500__loop
BootSerial_SpinWait1500__done:
	ret

BootSerial_SpinWait3000:
	ldw	wa, 3000
BootSerial_SpinWait3000__loop:
	dec	1, wa
	cps	wa, 0
	jr	z, BootSerial_SpinWait3000__done
	jr	BootSerial_SpinWait3000__loop
BootSerial_SpinWait3000__done:
	ret

; -----------------------------------------------------------------------------
; BootSerial_TickWait2/6/51 - timer-based delays on the (0x0c00) tick counter
; Latch the current tick count into (0x0f73), then spin until the counter
; (incremented by BootTimer_InterruptHandler -> Boot_TimerTick) has advanced
; by 2 / 6 / 51 ticks.  Clobbers WA.
; Callers: TickWait2: NONE FOUND (factory/diagnostic);
;          TickWait6: 27 sites across BootSerial_Init, BootSerial_FullInit,
;          BootSerial_TestLoopback, BootSerial_ProbeSequence,
;          BootSerial_WaitDeviceIdent, BootSerial_ResetAndIdent;
;          TickWait51: BootSerial_Init (3 sites)
; -----------------------------------------------------------------------------
BootSerial_TickWait2:
	ld	wa, (0x0c00:16)
	ld	(0x0f73:16), wa
BootSerial_TickWait2__loop:
	ld	wa, (0x0c00:16)
	subda16	xwa, 0x0f73
	cps	wa, 2
	jr	lt, BootSerial_TickWait2__loop
	ret

BootSerial_TickWait6:
	ld	wa, (0x0c00:16)
	ld	(0x0f73:16), wa
BootSerial_TickWait6__loop:
	ld	wa, (0x0c00:16)
	subda16	xwa, 0x0f73
	cps	wa, 6
	jr	lt, BootSerial_TickWait6__loop
	ret

BootSerial_TickWait51:
	ld	wa, (0x0c00:16)
	ld	(0x0f73:16), wa
BootSerial_TickWait51__loop:
	ld	wa, (0x0c00:16)
	subda16	xwa, 0x0f73
	cp	wa, 51
	jr	lt, BootSerial_TickWait51__loop
	ret

; -----------------------------------------------------------------------------
; Boot_ClassifyDeviceID - classify the probed device from its decoded answer
; Tests the decoded-packet buffer (filled by the INTRX1 packet handlers in
; bootcode_serial_state.bin) against four known signatures.
; Inputs:  decoded bytes at (0x1036), (0x1023), (0x1038), (0x1028)
; Outputs: HL = 3 if (0x1036) == 0x6c
;               2 if (0x1023) == 0x70
;               1 if (0x1038) == 0x38
;               4 if (0x1028) == 0x0f  (flash-update service device --
;                 Boot_Init runs the firmware-update UI on this answer)
;               0 otherwise (no / unknown device)
; Callers: Boot_ProbeExternalDevice (boot 0xffed1a)
; -----------------------------------------------------------------------------
Boot_ClassifyDeviceID:
	cp	(0x1036:16), 0x6c
	jr	nz, Boot_ClassifyDeviceID__not3
	lds	hl, 3
	jr	Boot_ClassifyDeviceID__ret
Boot_ClassifyDeviceID__not3:
	cp	(0x1023:16), 0x70
	jr	nz, Boot_ClassifyDeviceID__not2
	lds	hl, 2
	jr	Boot_ClassifyDeviceID__ret
Boot_ClassifyDeviceID__not2:
	cp	(0x1038:16), 0x38
	jr	nz, Boot_ClassifyDeviceID__not1
	lds	hl, 1
	jr	Boot_ClassifyDeviceID__ret
Boot_ClassifyDeviceID__not1:
	cp	(0x1028:16), 0x0f
	jr	nz, Boot_ClassifyDeviceID__none
	lds	hl, 4
	jr	Boot_ClassifyDeviceID__ret
Boot_ClassifyDeviceID__none:
	lds	hl, 0
Boot_ClassifyDeviceID__ret:
	ret

; -----------------------------------------------------------------------------
; BootSerial_TestLoopback - send two test frames, accumulate response bits
; Sends (0x20, 0x00) and (0xe0, 0x00); after each, a 6-tick wait, then checks
; whether the RX progress counter (0x0f77) advanced: bit 0 (first frame) and
; bit 3 (second frame) are set in the result accordingly.
; Inputs:  none
; Outputs: A = (0x0f6b) result bits (bit 0 / bit 3 = response seen)
; Callers: BootSerial_Call_TestLoopback thunk only (itself unreferenced) --
;          factory/diagnostic code
; -----------------------------------------------------------------------------
BootSerial_TestLoopback:
	ld	(0x0f6b:16), 0
	calr	BootSerial_WaitTxIdle
	ldw	(0x0f75:16), 0
	ldw	(0x0f77:16), 0
	ldb	a, 0x20			; test frame (0x20, 0x00)
	ldb	w, 0x00
	calr	BootSerial_SendFrame
	calr	BootSerial_TickWait6
	cpdi16	(0x0f77), 0
	jr	z, BootSerial_TestLoopback__no_resp1
	ordi8	(0x0f6b), 1
BootSerial_TestLoopback__no_resp1:
	calr	BootSerial_WaitTxIdle
	ldw	(0x0f75:16), 0
	ldw	(0x0f77:16), 0
	ldb	a, 0xe0			; test frame (0xe0, 0x00)
	ldb	w, 0x00
	calr	BootSerial_SendFrame
	calr	BootSerial_TickWait6
	cpdi16	(0x0f77), 0
	jr	z, BootSerial_TestLoopback__no_resp2
	ordi8	(0x0f6b), 8
BootSerial_TestLoopback__no_resp2:
	ld	a, (0x0f6b:16)
	ret

; -----------------------------------------------------------------------------
; BootSerial_ProbeSequence - the four-frame device-ident probe exchange
; Resets the RX transfer-control block, snapshots (0x0f75) into (0x0f77),
; then sends frames (0x25,0x01), (0xe2,0x04), (0x20,0x10), (0xe2,0x11), each
; preceded by a TX-idle wait and followed by 6-tick waits; finally parses the
; collected RX packets (BootSerial_RX_ParsePackets) so the decoded answer
; lands in the 0x1022+ buffer for Boot_ClassifyDeviceID.
; Inputs:  none    Outputs: decoded response in the 0x1022+ buffer
; Callers: Boot_ProbeExternalDevice (call 0xfff00e at boot 0xffed12)
; -----------------------------------------------------------------------------
BootSerial_ProbeSequence:
	ld	xhl, 0x988a		; RX transfer-control block
	ldw	(xhl - 4), 0
	ldw	(xhl - 8), 0
	ldw	(xhl - 2), 0x80
	ei	6
	ld	wa, (0x0f75:16)
	ld	(0x0f77:16), wa		; (0x0f77) = (0x0f75) snapshot
	ei	0
	call	0xfff173		; BootSerial_WaitTxIdle (boot-time
					; absolute; ROM label 0x9ff173)
	ldb	a, 0x25			; frame (0x25, 0x01)
	ldb	w, 0x01
	call	0xfff1c5		; BootSerial_SendFrame (boot-time
					; absolute; ROM label 0x9ff1c5)
	calr	BootSerial_TickWait6
	calr	BootSerial_TickWait6
	calr	BootSerial_TickWait6
	calr	BootSerial_WaitTxIdle
	ldb	a, 0xe2			; frame (0xe2, 0x04)
	ldb	w, 0x04
	calr	BootSerial_SendFrame
	calr	BootSerial_TickWait6
	calr	BootSerial_TickWait6
	calr	BootSerial_WaitTxIdle
	ldb	a, 0x20			; frame (0x20, 0x10)
	ldb	w, 0x10
	calr	BootSerial_SendFrame
	calr	BootSerial_TickWait6
	calr	BootSerial_TickWait6
	calr	BootSerial_WaitTxIdle
	ldb	a, 0xe2			; frame (0xe2, 0x11)
	ldb	w, 0x11
	calr	BootSerial_SendFrame
	calr	BootSerial_TickWait6
	calr	BootSerial_TickWait6
	calr	BootSerial_RX_ParsePackets
	ret

; -----------------------------------------------------------------------------
; BootSerial_WaitDeviceIdent - poll (0x20, 0x0b) until the ident is stable
; Repeatedly sends frame (0x20, 0x0b) and derives an ident code W from the
; decoded response byte (0x102d): bit 7 -> 0x0d, else bit 6 -> 0x0e, else
; 0x0c.  Loops until two consecutive polls return the same code (compared
; against the previous value kept in (0x1042)), then resets the RX
; transfer-control block and all TX/RX progress state.
; Inputs:  none    Outputs: (0x1042) = stable ident code
; Callers: BootSerial_Init (boot 0xffec98)
; -----------------------------------------------------------------------------
BootSerial_WaitDeviceIdent:
	ld	xhl, 0x988a		; RX transfer-control block
	ldw	(xhl - 4), 0
	ldw	(xhl - 8), 0
	ldw	(xhl - 2), 0x80
	ei	6
	ldw	(0x0f75:16), 0
	ldw	(0x0f77:16), 0
	ei	0
BootSerial_WaitDeviceIdent__poll:
	calr	BootSerial_WaitTxIdle
	ldb	a, 0x20			; ident request frame (0x20, 0x0b)
	ldb	w, 0x0b
	calr	BootSerial_SendFrame
	calr	BootSerial_TickWait6
	calr	BootSerial_RX_ParsePackets
	ld	a, (0x102d:16)		; decoded response byte
	ldb	w, 0x0d
	bit	7, a
	jr	nz, BootSerial_WaitDeviceIdent__have
	ldb	w, 0x0e
	bit	6, a
	jr	nz, BootSerial_WaitDeviceIdent__have
	ldb	w, 0x0c
BootSerial_WaitDeviceIdent__have:
	cpdm8	0x1042, w		; same as previous poll?
	ld	(0x1042:16), w
	jr	nz, BootSerial_WaitDeviceIdent__poll
	ld	(0x1042:16), w		; stable: store (again) and clean up
	ld	xhl, 0x988a
	ldw	(xhl - 4), 0
	ldw	(xhl - 8), 0
	ldw	(xhl - 2), 0x80
	ei	6
	ldw	(0x0fd5:16), 0
	ldw	(0x0fd7:16), 0
	ldw	(0x0f75:16), 0
	ldw	(0x0f77:16), 0
	ei	0
	ret

; -----------------------------------------------------------------------------
; BootSerial_ResetAndIdent - reset the RX side and run the (0x2b/0xeb/0x20/
; 0xe3) re-ident exchange
; Resets the RX transfer-control block and progress counters (note: BYTE
; stores to (0x0f75)/(0x0f77) here, unlike the word stores everywhere else),
; then sends frames (0x2b,0x00), (0xeb,0x00), (0x20,0x10), (0xe3,0x10), each
; with a TX-idle wait before and 6-tick waits plus an RX-busy mark
; (BootSerial_RX_SetBusy) after.
; Inputs:  none    Outputs: link re-identified
; Callers: BootSerial_ModeSwitch (mode 0xc0 arm, boot 0xffecc4) and the
;          BootSerial_Call_ResetAndIdent thunk (boot 0xffecfd)
; -----------------------------------------------------------------------------
BootSerial_ResetAndIdent:
	ld	xhl, 0x988a		; RX transfer-control block
	ldw	(xhl - 4), 0
	ldw	(xhl - 8), 0
	ldw	(xhl - 2), 0x80
	ei	6
	ld	(0x0f75:16), 0		; byte store (word store elsewhere)
	ld	(0x0f77:16), 0		; byte store
	ei	0
	calr	BootSerial_WaitTxIdle
	ldb	a, 0x2b			; frame (0x2b, 0x00)
	ldb	w, 0x00
	calr	BootSerial_SendFrame
	calr	BootSerial_TickWait6
	calr	BootSerial_TickWait6
	calr	BootSerial_TickWait6
	calr	BootSerial_RX_SetBusy
	calr	BootSerial_WaitTxIdle
	ldb	a, 0xeb			; frame (0xeb, 0x00)
	ldb	w, 0x00
	calr	BootSerial_SendFrame
	calr	BootSerial_TickWait6
	calr	BootSerial_TickWait6
	calr	BootSerial_TickWait6
	calr	BootSerial_RX_SetBusy
	calr	BootSerial_WaitTxIdle
	ldb	a, 0x20			; frame (0x20, 0x10)
	ldb	w, 0x10
	calr	BootSerial_SendFrame
	calr	BootSerial_TickWait6
	calr	BootSerial_TickWait6
	calr	BootSerial_RX_SetBusy
	calr	BootSerial_WaitTxIdle
	ldb	a, 0xe3			; frame (0xe3, 0x10)
	ldb	w, 0x10
	calr	BootSerial_SendFrame
	calr	BootSerial_TickWait6
	calr	BootSerial_TickWait6
	calr	BootSerial_RX_SetBusy
	ret

; -----------------------------------------------------------------------------
; BootSerial_WaitTxIdle - wait (200 retries) for the link to go idle
; Idle test (with serial ints masked): PF bit 6 high, PE bit 5 low, link
; flags (0x0f64) bits 1 (TX pending) and 0 (RX active) clear; then the TX
; ring drained: pending count (0x0fd7) == send index (0x0fd5).  While busy,
; decrements the (0x0f6f) countdown (start 200) with a 1500-iteration spin
; between attempts.  The exit path (reached on idle AND on timeout) clears
; INTRX1/INTTX1, sets INTES1 = 0xdd, SC1MOD &= ~0x20, and sets bit 7 in the
; status byte (0x0f6a).
; Inputs:  none    Outputs: (0x0f6a) bit 7 set; serial ints re-armed
; Callers: BootSerial_TestLoopback (x2), BootSerial_ProbeSequence (x4, first
;          one via CALL absolute at boot 0xfff02e), BootSerial_WaitDeviceIdent,
;          BootSerial_ResetAndIdent (x4)
; -----------------------------------------------------------------------------
BootSerial_WaitTxIdle:
	ld	(0x0f6f:16), 0xc8		; 200 retries
BootSerial_WaitTxIdle__outer:
	ei	6			; sample state with serial ints masked
	bit_dd8	6, 0x3c			; PF bit 6 must be high
	jr	z, BootSerial_WaitTxIdle__busy
	bit_dd8	5, 0x38			; PE bit 5 must be low
	jr	nz, BootSerial_WaitTxIdle__busy
	bit	1, (0x0f64:16)		; TX-pending flag clear?
	jr	nz, BootSerial_WaitTxIdle__busy
	bit	0, (0x0f64:16)		; RX-active flag clear?
	jr	nz, BootSerial_WaitTxIdle__busy
	jr	BootSerial_WaitTxIdle__check_tx
BootSerial_WaitTxIdle__busy:
	decdi8	1, (0x0f6f)
	cp	(0x0f6f:16), 0
	jr	z, BootSerial_WaitTxIdle__exit	; timed out
	ei	0
	calr	BootSerial_SpinWait1500
	jr	BootSerial_WaitTxIdle__outer
BootSerial_WaitTxIdle__check_tx:
	ld	wa, (0x0fd7:16)		; TX pending count
	cpda16	xwa, 0x0fd5		; == send index -> drained
	jr	nz, BootSerial_WaitTxIdle__busy
BootSerial_WaitTxIdle__exit:
	ei	6
	ldio	0xf8, 0x22		; INTCLR: INTRX1
	ldio	0xf8, 0x23		; INTCLR: INTTX1
	ldio	0xeb, 0xdd		; INTES1
	and_sd8b_im 0xd6, 0xdf		; SC1MOD &= ~0x20
	ordi8	(0x0f6a), 0x80		; done/abort status bit
	ei	0
	ret

; -----------------------------------------------------------------------------
; BootSerial_SendFrame - queue a 2-byte frame and kick the TX interrupt chain
; With serial ints masked: rewinds the TX ring (send index (0x0fd5) = 0,
; pending count (0x0fd7) = 0), stores WA at the ring head (0x0fd9), sets
; pending count = 2, flags TX-pending (bit 1) / clears RX-active (bit 0) in
; (0x0f64), arms state (0x0f62) = 0x04 (state-machine dispatch offset), sets
; BR1CR = 0x28, re-programs the port F pins from the shadows, enables INTA +
; serial ints (INTES1 = 0xdf), drops SC1MOD bit 5 / SC1CR bit 0, and finally
; primes SC1BUF with a dummy write (A holds the PFCR shadow at that point) so
; the INTTX1 state machine (bootcode_serial_state.bin) takes over and sends
; the real bytes from the ring.
; Inputs:  WA = frame bytes (A first, W second)
; Outputs: frame queued; TX interrupt chain running
; Callers: BootSerial_FullInit, BootSerial_HandshakeSequence (x4),
;          BootSerial_TestLoopback (x2), BootSerial_ProbeSequence (x4, first
;          one via CALL absolute at boot 0xfff036),
;          BootSerial_WaitDeviceIdent, BootSerial_ResetAndIdent (x4)
; -----------------------------------------------------------------------------
BootSerial_SendFrame:
	ei	6
	ldw	(0x0fd5:16), 0		; TX send index = 0
	ldw	(0x0fd7:16), 0		; TX pending count = 0
	ld	(0x0fd9:16), wa		; both frame bytes -> ring head
	adddi16	(0x0fd7), 2		; two bytes pending
	ordi8	(0x0f64), 2		; TX-pending flag
	anddi8	(0x0f64), 0xfe		; clear RX-active flag
	ld	(0x0f62:16), 4		; state machine -> state 0x04
	ldio	0xd7, 0x28		; BR1CR
	anddi8	(0x0f67), 0xbf
	ld	a, (0x0f67:16)
	st_dd8b	a, 0x3f			; PFFC bit 6 low
	and_sd8b_im 0x3c, 0xbf		; PF bit 6 low
	ordi8	(0x0f66), 0x40
	ld	a, (0x0f66:16)
	st_dd8b	a, 0x3e			; PFCR bit 6 high
	ldio	0xe3, 0x07		; INTEAB
	ldio	0xf8, 0x12		; INTCLR
	and_sd8b_im 0xd6, 0xdf		; SC1MOD &= ~0x20
	and_sd8b_im 0xd5, 0xfe		; SC1CR bit 0 low
	ldio	0xf8, 0x23		; INTCLR: INTTX1
	ldio	0xeb, 0xdf		; INTES1
	ldio	0xf8, 0x22		; INTCLR: INTRX1
	st_dd8b	a, 0xd4			; dummy SC1BUF write (A = PFCR shadow)
					; primes the INTTX1 state machine
	ei	0
	nop
	ret
