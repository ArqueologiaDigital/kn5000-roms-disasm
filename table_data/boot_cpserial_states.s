; =============================================================================
; BOOT-TIME CONTROL-PANEL SERIAL-LINK DRIVER (state handlers + packet codecs)
; =============================================================================
; ROM range 0x9ff2f2-0x9ffb2e (formerly includes/bootcode_serial_state.bin;
; the trailing Boot_sbrk of that blob now opens boot_clib.s).  Boot-time
; alias: executes at 0xfff2f2-0xfffb2e.
;
; Contents, in ROM order:
;   - the ten state handlers dispatched from BootSerial_StateDispatchTable
;     (boot_cpserial_isr.s); TX states end at BootSerial_TxIsrEpilogue and
;     RX states at BootSerial_RxIsrEpilogue
;   - BootSerial_UnusedIsrEpilogue - orphaned ISR tail, no reference found
;   - BootSerial_PollTX - poll-mode transmit pump (used by the thunk in
;     boot_cpserial.s)
;   - the RX packet parser and the TX packet encoder with their .long
;     dispatch tables (split out of the code as data)
;   - the ring-index helpers (with two byte-identical duplicates)
;   - the AudioMix/memory shared library (see its banner below)
;
; Ring state shared with boot_cpserial.s and boot_cpserial_isr.s:
;   (0x0f62) state byte = raw dispatch-table offset (0x00..0x28 step 4)
;   (0x0f63) per-frame byte countdown (2 for plain frames, (b & 0x0f) + 3
;            for variable-length runs, derived from the first frame byte)
;   (0x0f64) link flags: bit0 RX active, bit1 TX pending, bit2 RX busy,
;            bit4 decode-collapse sentinel   (0x0f6a) status/abort bits
;   (0x0f79) RX serial ring (0x5c bytes): (0x0f75) tail / (0x0f77) head
;   (0x0fd9) TX serial ring (0x3c bytes): (0x0fd5) send index / (0x0fd7)
;            pending count
;   0x988a / 0x9914  RX / TX transfer-control blocks: 0x80-byte packet ring
;       at the base address, tail word at base-8, head word at base-4, and a
;       FREE-SLOT COUNT word at base-2 (initialised to the 0x0080 ring size
;       by boot_cpserial.s; the packet parser/encoder step it as they fill
;       and drain the ring)
;   0x1022+ decoded-packet buffer (XOR-scramble state; read back by
;       Boot_ClassifyDeviceID in boot_cpserial.s)
; =============================================================================

; -----------------------------------------------------------------------------
; BootSerial_State04_TxLineRequest - state 0x04: request the line for TX
; Drops PFCR bit 6, arms BR1CR=0x24 / INTEAB=0x07 / INTES1=0xd0, primes
; SC1BUF with a dummy write and advances to state 0x08.  After two MUL
; timing fillers it samples PF bit 6: line high means the request was
; granted and the pending INTTX1 will continue the frame; line low means
; arbitration failed - reset to idle with status bit 1 set in (0x0f6a).
; Callers: BootSerial_StateDispatchTable[0x04]; armed by
;          BootSerial_SendFrame / BootSerial_PollTX / State18
; -----------------------------------------------------------------------------
BootSerial_State04_TxLineRequest:
	and	(0x0f66:16), 0xbf		; PFCR shadow bit 6 low
	ld	a, (0x0f66:16)
	ld	(0x3e:8), a			; PFCR
	ld	(0xd7:8), 0x24:io		; BR1CR
	ld	(0xe3:8), 0x07:io		; INTEAB
	ld	(0xeb:8), 0xd0:io		; INTES1: TX enabled
	and	(0xd5:8), 0xfe		; SC1CR bit 0 low
	ld	(0xd4:8), a			; dummy SC1BUF write (A = PFCR shadow)
	inc	4, (0x0f62:16)		; state -> 0x08
	mul	a, 1			; timing filler
	mul	a, 1			; timing filler
	bit	6, (0x3c:8)			; PF bit 6: line granted?
	jr	nz, BootSerial_TxIsrEpilogue
	ld	(0x0f63:16), 0		; not granted: back to idle
	ld	(0x0f62:16), 0
	or	(0x0f6a:16), 0x02		; status: TX arbitration failed
	ld	(0xe3:8), 0x05:io		; INTEAB
	ld	(0xeb:8), 0xff:io		; INTES1
	ld	(0xd7:8), 0x24:io		; BR1CR
	and	(0x0f64:16), 0xfd		; clear TX-pending flag
	jrl	t, BootSerial_TxIsrEpilogue

; -----------------------------------------------------------------------------
; BootSerial_State0C_TxByteGap - state 0x0c: inter-byte turnaround
; 10-iteration spin, PFCR/PFFC mode bits back low, BR1CR=0x24, dummy SC1BUF
; write, advance to state 0x10 (send next byte).
; Callers: BootSerial_StateDispatchTable[0x0c] (loops with state 0x10)
; -----------------------------------------------------------------------------
BootSerial_State0C_TxByteGap:
	calr	BootSerial_SpinWait10
	and	(0x0f66:16), 0xaf
	ld	a, (0x0f66:16)
	ld	(0x3e:8), a			; PFCR
	and	(0x0f67:16), 0xaf
	ld	a, (0x0f67:16)
	ld	(0x3f:8), a			; PFFC
	ld	(0xd7:8), 0x24:io		; BR1CR
	ld	(0xeb:8), 0xd0:io		; INTES1
	and	(0xd5:8), 0xfe		; SC1CR bit 0 low
	ld	(0xd4:8), a			; dummy SC1BUF write
	inc	4, (0x0f62:16)		; state -> 0x10
	jrl	t, BootSerial_TxIsrEpilogue

; -----------------------------------------------------------------------------
; BootSerial_State14_TxTail - state 0x14: frame sent, closing turnaround
; Same pin restore as state 0x0c but with TWO dummy SC1BUF writes and
; INTEAB re-armed; advances to state 0x18 (frame done).
; Callers: BootSerial_StateDispatchTable[0x14]
; -----------------------------------------------------------------------------
BootSerial_State14_TxTail:
	calr	BootSerial_SpinWait10
	and	(0x0f66:16), 0xaf
	ld	a, (0x0f66:16)
	ld	(0x3e:8), a			; PFCR
	and	(0x0f67:16), 0xaf
	ld	a, (0x0f67:16)
	ld	(0x3f:8), a			; PFFC
	ld	(0xd7:8), 0x24:io		; BR1CR
	ld	(0xd4:8), a			; dummy SC1BUF write
	ld	(0xe3:8), 0x05:io		; INTEAB
	ld	(0xeb:8), 0xd0:io		; INTES1
	and	(0xd5:8), 0xfe		; SC1CR bit 0 low
	ld	(0xd4:8), a			; dummy SC1BUF write
	inc	4, (0x0f62:16)		; state -> 0x18
	jrl	t, BootSerial_TxIsrEpilogue

; -----------------------------------------------------------------------------
; BootSerial_State08_TxFirstByte - state 0x08: send the first frame byte
; BR1CR=0x14, PFFC/PFCR mode bits 0x50 high, then pushes TX ring byte
; [(0x0fd9) + (0x0fd5)] into SC1BUF and advances the send index (mod 0x3c).
; Derives the frame byte countdown (0x0f63): 2 for a plain frame, or
; (byte & 0x0f) + 3 when (byte & 0x3f) >= 0x30 (variable-length run).
; Advances to state 0x0c.
; Callers: BootSerial_StateDispatchTable[0x08]
; -----------------------------------------------------------------------------
BootSerial_State08_TxFirstByte:
	ld	(0xd7:8), 0x14:io		; BR1CR
	or	(0x0f67:16), 0x50
	ld	a, (0x0f67:16)
	ld	(0x3f:8), a			; PFFC mode bits high
	or	(0x0f66:16), 0x50
	ld	a, (0x0f66:16)
	ld	(0x3e:8), a			; PFCR mode bits high
	and	(0xd5:8), 0xfe		; SC1CR bit 0 low
	ld	(0xe3:8), 0x05:io		; INTEAB
	ld	(0xeb:8), 0xd0:io		; INTES1
	ld	xiy, 0x0fd9		; TX serial ring
	add	iy, (0x0fd5:16)		; + send index
	ld	a, (xiy)
	ld	(0xd4:8), a			; frame byte -> SC1BUF
	incw	1, (0x0fd5:16)
	cpw	(0x0fd5:16), 0x003c
	jr	c, BootSerial_State08_TxFirstByte__no_wrap
	ldw	(0x0fd5:16), 0
BootSerial_State08_TxFirstByte__no_wrap:
	ld	(0x0f63:16), 0x02		; default: 2-byte frame
	ld	a, (xiy)
	and	a, 0x3f
	cp	a, 0x30
	jr	c, BootSerial_State08_TxFirstByte__count_set
	and	a, 0x0f			; variable-length run:
	add	a, 3			; count = (byte & 0x0f) + 3
	ld	(0x0f63:16), a
BootSerial_State08_TxFirstByte__count_set:
	inc	4, (0x0f62:16)		; state -> 0x0c
	jrl	t, BootSerial_TxIsrEpilogue

; -----------------------------------------------------------------------------
; BootSerial_State10_TxNextByte - state 0x10: send a further frame byte
; Same pin/baud setup and ring push as state 0x08, then steps the frame
; countdown (0x0f63): 0 or 1 remaining advances to state 0x14 (tail),
; otherwise retreats to state 0x0c for another byte-gap/byte pair.
; Callers: BootSerial_StateDispatchTable[0x10]
; -----------------------------------------------------------------------------
BootSerial_State10_TxNextByte:
	ld	(0xd7:8), 0x14:io		; BR1CR
	or	(0x0f67:16), 0x50
	ld	a, (0x0f67:16)
	ld	(0x3f:8), a			; PFFC
	or	(0x0f66:16), 0x50
	ld	a, (0x0f66:16)
	ld	(0x3e:8), a			; PFCR
	and	(0xd5:8), 0xfe		; SC1CR bit 0 low
	ld	(0xe3:8), 0x05:io		; INTEAB
	ld	(0xeb:8), 0xd0:io		; INTES1
	ld	xiy, 0x0fd9		; TX serial ring
	add	iy, (0x0fd5:16)
	ld	a, (xiy)
	ld	(0xd4:8), a			; frame byte -> SC1BUF
	incw	1, (0x0fd5:16)
	cpw	(0x0fd5:16), 0x003c
	jr	c, BootSerial_State10_TxNextByte__no_wrap
	ldw	(0x0fd5:16), 0
BootSerial_State10_TxNextByte__no_wrap:
	dec	1, (0x0f63:16)
	cp	(0x0f63:16), 0x01
	jr	z, BootSerial_State10_TxNextByte__last
	cp	(0x0f63:16), 0x00
	jr	z, BootSerial_State10_TxNextByte__last
	dec	4, (0x0f62:16)		; more bytes: state -> 0x0c
	jrl	t, BootSerial_TxIsrEpilogue
BootSerial_State10_TxNextByte__last:
	inc	4, (0x0f62:16)		; countdown done: state -> 0x14
	jrl	t, BootSerial_TxIsrEpilogue

; -----------------------------------------------------------------------------
; BootSerial_State18_TxFrameDone - state 0x18: frame complete
; Clears the countdown and state; if the TX serial ring still holds 2 or
; more pending bytes, immediately re-arms the next frame (state 0x04 setup
; with BR1CR=0x28 and a dummy SC1BUF write), otherwise restores the pins to
; idle/receive and clears the TX-pending flag.
; Callers: BootSerial_StateDispatchTable[0x18]
; -----------------------------------------------------------------------------
BootSerial_State18_TxFrameDone:
	ld	(0x0f63:16), 0
	ld	(0x0f62:16), 0
	ld	wa, (0x0fd7:16)		; pending count
	sub	wa, (0x0fd5:16)		; - send index
	cp	wa, 2:i3
	jr	c, BootSerial_State18_TxFrameDone__go_idle
	ld	(0x0f62:16), 0x04		; next frame: state 0x04
	and	(0x0f67:16), 0xbf
	ld	a, (0x0f67:16)
	ld	(0x3f:8), a			; PFFC bit 6 low
	and	(0x3c:8), 0xbf		; PF bit 6 low
	or	(0x0f66:16), 0x40
	ld	a, (0x0f66:16)
	ld	(0x3e:8), a			; PFCR bit 6 high (request line)
	ld	(0xd7:8), 0x28:io		; BR1CR
	ld	(0xe3:8), 0x07:io		; INTEAB
	and	(0xd5:8), 0xfe		; SC1CR bit 0 low
	ld	(0xeb:8), 0xd0:io		; INTES1
	ld	(0xd4:8), a			; dummy SC1BUF write
	or	(0x0f64:16), 0x02		; TX-pending flag
	jrl	t, BootSerial_TxIsrEpilogue
BootSerial_State18_TxFrameDone__go_idle:
	and	(0x0f66:16), 0xbf
	ld	a, (0x0f66:16)
	ld	(0x3e:8), a			; PFCR bit 6 low
	and	(0x0f67:16), 0xbf
	ld	a, (0x0f67:16)
	ld	(0x3f:8), a			; PFFC bit 6 low
	ld	(0xe3:8), 0x05:io		; INTEAB
	ld	(0xeb:8), 0xff:io		; INTES1
	ld	(0xd7:8), 0x24:io		; BR1CR
	and	(0x0f64:16), 0xfd		; clear TX-pending flag
	jrl	t, BootSerial_TxIsrEpilogue

; -----------------------------------------------------------------------------
; BootSerial_State20_RxFirstByte - state 0x20: receive the first frame byte
; Reads SC1BUF into the RX serial ring at [(0x0f79) + (0x0f77)].  Computes
; the ring distance head-tail (mod 0x5c); fewer than 3 free slots sets the
; overflow bit 0 in (0x0f6a) and leaves the head unmoved, otherwise clears
; it and advances the head (mod 0x5c).  Derives the frame countdown
; (0x0f63) exactly like State08 (2, or (byte & 0x0f) + 3 for runs), then
; advances to state 0x24.
; Callers: BootSerial_StateDispatchTable[0x20]; armed by Handler_INTA
; -----------------------------------------------------------------------------
BootSerial_State20_RxFirstByte:
	and	(0x0f66:16), 0x9f
	ld	a, (0x0f66:16)
	ld	(0x3e:8), a			; PFCR: RX pin mode
	or	(0xd5:8), 0x01		; SC1CR bit 0 high
	and	(0xd5:8), 0xfd		; SC1CR bit 1 low
	ld	(0xe3:8), 0x05:io		; INTEAB
	ld	(0xeb:8), 0x0d:io		; INTES1: RX enabled
	ld	a, (0xd4:8)			; A = SC1BUF (received byte)
	ld	xiy, 0x0f79		; RX serial ring
	add	iy, (0x0f77:16)		; + head index
	ld	(xiy), a
	ld	hl, (0x0f77:16)
	sub	hl, (0x0f75:16)		; head - tail
	jr	nc, BootSerial_State20_RxFirstByte__fwd
	neg	hl
	ld	iy, hl			; wrapped: free = -(head - tail)
	jr	t, BootSerial_State20_RxFirstByte__have_free
BootSerial_State20_RxFirstByte__fwd:
	ldw	iy, 0x005c
	sub	iy, hl			; free = ring size - used
BootSerial_State20_RxFirstByte__have_free:
	cp	iy, 3:i3
	jr	nc, BootSerial_State20_RxFirstByte__room
	or	(0x0f6a:16), 0x01		; RX ring overflow
	jr	t, BootSerial_State20_RxFirstByte__counted
BootSerial_State20_RxFirstByte__room:
	and	(0x0f6a:16), 0xfe
	incw	1, (0x0f77:16)
	cpw	(0x0f77:16), 0x005c
	jr	c, BootSerial_State20_RxFirstByte__counted
	ldw	(0x0f77:16), 0
BootSerial_State20_RxFirstByte__counted:
	ld	(0x0f63:16), 0x02		; default: 2-byte frame
	and	a, 0x3f
	cp	a, 0x30
	jr	c, BootSerial_State20_RxFirstByte__count_set
	and	a, 0x0f			; variable-length run:
	add	a, 3			; count = (byte & 0x0f) + 3
	ld	(0x0f63:16), a
BootSerial_State20_RxFirstByte__count_set:
	inc	4, (0x0f62:16)		; state -> 0x24
	jrl	t, BootSerial_RxIsrEpilogue

; -----------------------------------------------------------------------------
; BootSerial_State24_RxNextByte - state 0x24: receive further frame bytes
; Stores SC1BUF into the RX ring head; the head only advances while the
; overflow bit (0x0f6a).0 is clear.  Steps the frame countdown (0x0f63):
; when it hits 1 the frame is complete - clear RX-active, return to state 0
; and drop SC1MOD bit 5; otherwise re-arm SC1 for the next byte and stay in
; state 0x24.
; Callers: BootSerial_StateDispatchTable[0x24]
; -----------------------------------------------------------------------------
BootSerial_State24_RxNextByte:
	ld	a, (0xd4:8)			; A = SC1BUF
	ld	xiy, 0x0f79		; RX serial ring
	add	iy, (0x0f77:16)
	ld	(xiy), a
	bit	0, (0x0f6a:16)		; overflow latched?
	jr	nz, BootSerial_State24_RxNextByte__no_advance
	incw	1, (0x0f77:16)
	cpw	(0x0f77:16), 0x005c
	jr	c, BootSerial_State24_RxNextByte__no_advance
	ldw	(0x0f77:16), 0
BootSerial_State24_RxNextByte__no_advance:
	dec	1, (0x0f63:16)
	cp	(0x0f63:16), 0x01
	jr	nz, BootSerial_State24_RxNextByte__rearm
	ld	(0x0f63:16), 0		; frame complete
	and	(0x0f64:16), 0xfe		; clear RX-active flag
	ld	(0x0f62:16), 0		; state -> idle
	and	(0x0f66:16), 0x9f
	ld	a, (0x0f66:16)
	ld	(0x3e:8), a			; PFCR
	and	(0x0f67:16), 0xbf
	ld	a, (0x0f67:16)
	ld	(0x3f:8), a			; PFFC
	ld	(0xe3:8), 0x05:io		; INTEAB
	ld	(0xeb:8), 0x0d:io		; INTES1
	and	(0xd6:8), 0xdf		; SC1MOD bit 5 low
	jrl	t, BootSerial_RxIsrEpilogue
BootSerial_State24_RxNextByte__rearm:
	and	(0x0f66:16), 0x9f
	ld	a, (0x0f66:16)
	ld	(0x3e:8), a			; PFCR
	or	(0xd5:8), 0x01		; SC1CR bit 0 high
	and	(0xd5:8), 0xfd		; SC1CR bit 1 low
	ld	(0xe3:8), 0x05:io		; INTEAB
	ld	(0xeb:8), 0x0d:io		; INTES1
	jrl	t, BootSerial_RxIsrEpilogue

; -----------------------------------------------------------------------------
; BootSerial_State_Abort - states 0x00 / 0x1c / 0x28: bad state
; Sets the done/abort bit 7 in (0x0f6a) and returns via the RX epilogue.
; Callers: BootSerial_StateDispatchTable[0x00/0x1c/0x28]
; -----------------------------------------------------------------------------
BootSerial_State_Abort:
	or	(0x0f6a:16), 0x80
	jrl	t, BootSerial_RxIsrEpilogue

; -----------------------------------------------------------------------------
; BootSerial_UnusedIsrEpilogue - orphaned ISR tail
; Clears the RX/TX flags, sets status bit 2, re-arms INTES1=0x0f/INTEAB=0x07
; and returns from interrupt.  NO REFERENCE FOUND (no vector, jump or
; fall-through reaches it) - likely the epilogue of a removed fourth
; interrupt handler; retained dead code.
; -----------------------------------------------------------------------------
BootSerial_UnusedIsrEpilogue:
	and	(0x0f64:16), 0xfc
	or	(0x0f6a:16), 0x04
	ld	(0xf8:8), 0x23:io		; INTCLR: INTTX1
	and	(0xd6:8), 0xdf		; SC1MOD bit 5 low
	ld	(0xeb:8), 0x0f:io		; INTES1
	ld	(0xf8:8), 0x22:io		; INTCLR: INTRX1
	ld	(0xe3:8), 0x07:io		; INTEAB
	ld	(0xf8:8), 0x12:io		; INTCLR: INTA
	reti

; -----------------------------------------------------------------------------
; BootSerial_PollTX - poll-mode transmit pump
; Encodes any pending control-ring packets into the TX serial ring
; (BootSerial_TX_EncodePackets), then - with serial interrupts masked - when
; the line is idle (PF bit 6 high, PE bit 5 low, RX/TX flags clear) and the
; ring holds 2 or more bytes, kicks the interrupt state machine exactly like
; BootSerial_SendFrame (state 0x04, BR1CR=0x28, dummy SC1BUF write).  While
; the line stays busy a retry counter (0x0f70) runs to 20 before giving up
; with the done/abort bit 7 in (0x0f6a).
; The entry jump skips an UNREFERENCED sync-injection block (see below).
; Callers: BootSerial_Call_PollTX thunk (itself unreferenced, boot 0xffecf5)
; -----------------------------------------------------------------------------
BootSerial_PollTX:
	jr	t, BootSerial_PollTX__encode
; Dead block: alternate entry at boot 0xfff60a, NO REFERENCE FOUND.  Would
; run a 0x2a-tick timeout in (0x0f72) and then inject a (0x20, 0x10) sync
; frame into the TX serial ring when at least 3 slots are free.
BootSerial_PollTX__inject_sync:
	inc	1, (0x0f72:16)
	cp	(0x0f72:16), 42
	jr	ule, BootSerial_PollTX__inject_done
	ei	6
	ld	wa, (0x0fd7:16)
	sub	wa, (0x0fd5:16)
	jr	nc, BootSerial_PollTX__inject_fwd
	neg	wa
	ld	hl, wa
	jr	t, BootSerial_PollTX__inject_free
BootSerial_PollTX__inject_fwd:
	ldw	hl, 0x003c
	sub	hl, wa
BootSerial_PollTX__inject_free:
	cp	hl, 3:i3
	jr	c, BootSerial_PollTX__inject_done
	ld	(0x0f72:16), 0
	ld	w, 0x20:opc			; sync frame (0x20, 0x10)
	ld	a, 0x10:opc
	ld	iy, (0x0fd7:16)
	ld	xde, 0x0fd9		; TX serial ring
	ld	(xde+iy), w
	calr	BootSerial_TxRingAdvanceIY
	ld	(xde+iy), a
	calr	BootSerial_TxRingAdvanceIY
	ld	(0x0fd7:16), iy
BootSerial_PollTX__inject_done:
	ei	0
BootSerial_PollTX__encode:
	calr	BootSerial_TX_EncodePackets
	ei	6
	bit	6, (0x3c:8)			; PF bit 6 must be high
	jr	z, BootSerial_PollTX__line_busy
	bit	5, (0x38:8)			; PE bit 5 must be low
	jr	nz, BootSerial_PollTX__line_busy
	bit	1, (0x0f64:16)		; TX-pending flag clear?
	jr	nz, BootSerial_PollTX__line_busy
	bit	0, (0x0f64:16)		; RX-active flag clear?
	jr	nz, BootSerial_PollTX__line_busy
	ld	wa, (0x0fd7:16)
	sub	wa, (0x0fd5:16)		; pending - sent
	jr	nc, BootSerial_PollTX__have_count
	neg	wa
	ex8	a, w
	ld	a, 0x3c:opc
	sub	a, w			; wrapped: pending = ring size - diff
BootSerial_PollTX__have_count:
	cp	a, 2:i3
	jr	c, BootSerial_PollTX__exit
	or	(0x0f64:16), 0x02		; TX-pending flag
	ld	(0x0f62:16), 0x04		; state 0x04: TX line request
	and	(0x0f67:16), 0xbf
	ld	a, (0x0f67:16)
	ld	(0x3f:8), a			; PFFC bit 6 low
	and	(0x3c:8), 0xbf		; PF bit 6 low
	or	(0x0f66:16), 0x40
	ld	a, (0x0f66:16)
	ld	(0x3e:8), a			; PFCR bit 6 high (request line)
	ld	(0xd7:8), 0x28:io		; BR1CR
	and	(0xd6:8), 0xdf		; SC1MOD bit 5 low
	and	(0xd5:8), 0xfe		; SC1CR bit 0 low
	ld	(0xe3:8), 0x07:io		; INTEAB
	ld	(0xf8:8), 0x12:io		; INTCLR: INTA
	ld	(0xf8:8), 0x23:io		; INTCLR: INTTX1
	ld	(0xeb:8), 0xd0:io		; INTES1
	ld	(0xd4:8), a			; dummy SC1BUF write - kick INTTX1
BootSerial_PollTX__exit:
	ei	0
	ret
BootSerial_PollTX__line_busy:
	inc	1, (0x0f70:16)
	cp	(0x0f70:16), 20
	jr	ule, BootSerial_PollTX__exit
	ei	6			; 20 retries exhausted: give up
	ld	(0xf8:8), 0x22:io		; INTCLR: INTRX1
	ld	(0xf8:8), 0x23:io		; INTCLR: INTTX1
	ld	(0xeb:8), 0xdd:io		; INTES1
	ld	(0xf8:8), 0x12:io		; INTCLR: INTA
	ld	(0xe3:8), 0x05:io		; INTEAB
	or	(0x0f6a:16), 0x80		; done/abort status bit
	jr	t, BootSerial_PollTX__exit

; -----------------------------------------------------------------------------
; BootSerial_RX_SetBusy - flag RX busy, then parse
; Sets the RX-busy flag (0x0f64) bit 2 and falls into the packet parser
; (skipping only the flag-clear below).
; Callers: BootSerial_ResetAndIdent (4 sites in boot_cpserial.s)
; -----------------------------------------------------------------------------
BootSerial_RX_SetBusy:
	or	(0x0f64:16), 0x04
	jr	t, BootSerial_RX_ParsePackets__scan

; -----------------------------------------------------------------------------
; BootSerial_RX_ParsePackets - drain the RX serial ring into packets
; Clears the RX-busy flag, then walks the RX serial ring from the tail
; (0x0f75) toward the head (0x0f77), classifying each frame by
; (first byte & 0x38) >> 1 through BootSerial_RxPacketDispatchTable and
; appending the decoded result to the RX transfer-control ring at 0x988a
; (head word at 0x9886, free-count word at 0x9888).  Stops when fewer than
; 4 free slots remain in the control ring or fewer than 2 bytes are
; available in the serial ring.
; Inputs:  XDE/XIY/XIZ/XIX set up below; rings as documented in the banner
; Outputs: (0x0f75) advanced; control ring filled; (0x0f6c)-(0x0f6e) hold
;          the last packet's raw/decoded bytes
; Callers: BootSerial_ModeSwitch, BootSerial_ProbeSequence,
;          BootSerial_WaitDeviceIdent (boot_cpserial.s); fall-in from
;          BootSerial_RX_SetBusy
; -----------------------------------------------------------------------------
BootSerial_RX_ParsePackets:
	and	(0x0f64:16), 0xfb		; clear RX-busy flag
BootSerial_RX_ParsePackets__scan:
	ld	xde, 0x0f79		; RX serial ring
	ld	iy, (0x0f75:16)		; IY = serial ring tail
	ld	xiz, 0x988a		; RX transfer-control block
	ld	ix, (xiz - 4)		; IX = control ring head
BootSerial_RX_ParsePackets__next:
	cpw	(xiz - 2), 4		; >= 4 free control-ring slots?
	jrl	c, BootSerial_RxParseDone
	ld	wa, (0x0f77:16)
	sub	wa, (0x0f75:16)		; head - tail
	jr	nc, BootSerial_RX_ParsePackets__have_avail
	neg	wa
	ex8	a, w
	ld	a, 0x5c:opc
	sub	a, w			; wrapped: avail = ring size - diff
BootSerial_RX_ParsePackets__have_avail:
	cp	a, 2:i3			; a whole frame available?
	jrl	c, BootSerial_RxParseDone
	ld	l, (xde+iy)	; first frame byte
	and	l, 0x38
	srl	l, 1			; class * 4 = table offset
	xor	h, h
	extz	xhl
	add	xhl, BootSerial_RxPacketDispatchTable + 0x600000 ; boot alias
	ld	xhl, (xhl)
	jp	(xhl)

	.byte	0x6d, 0x0f		; 2 bytes non-code filler

; -----------------------------------------------------------------------------
; BootSerial_RxPacketDispatchTable - 8 x .long, indexed by
; (first frame byte & 0x38) >> 3 (the parser shifts right by 1 only, so the
; entries are 4 bytes apart).  Boot-time (0xffxxxx) addresses.
; Every handler loops back to BootSerial_RX_ParsePackets__next.
; -----------------------------------------------------------------------------
BootSerial_RxPacketDispatchTable:
	.long	BootSerial_RxPkt_TwoByteScrambled + 0x600000	; class 0
	.long	BootSerial_RxPkt_TwoByteScrambled + 0x600000	; class 1
	.long	BootSerial_RxPkt_TwoByteDecode + 0x600000	; class 2
	.long	BootSerial_RxPkt_Discard + 0x600000		; class 3
	.long	BootSerial_RxPkt_Discard + 0x600000		; class 4
	.long	BootSerial_RxPkt_Discard + 0x600000		; class 5
	.long	BootSerial_RxPkt_VarLengthRun + 0x600000	; class 6
	.long	BootSerial_RxPkt_VarLengthRun + 0x600000	; class 7

; -----------------------------------------------------------------------------
; BootSerial_RxPkt_TwoByteScrambled - RX classes 0/1: 2-byte frame, XOR-mixed
; Copies both frame bytes from the serial ring into the control ring, then
; produces a third byte by exchanging A with the scramble buffer at
; 0x1022 + f(W) and XORing with the OLD buffer contents (f adds the first
; byte, minus 0x30 when its bit 6 is set, keeping only bits 0-3/6).  The
; three bytes cost 3 control-ring slots; head and serial tail are committed
; only after a complete packet.  Shadows the last bytes in (0x0f6c)-(0x0f6e).
; Callers: BootSerial_RxPacketDispatchTable[0/1]
; -----------------------------------------------------------------------------
BootSerial_RxPkt_TwoByteScrambled:
	ld	w, (xde+iy)	; first byte
	calr	BootSerial_RxRingAdvanceIY
	ld	(xiz+ix), w
	calr	BootSerial_CtrlRingAdvanceIX
	ld	(0x0f6c:16), w
	ld	a, (xde+iy)	; second byte
	calr	BootSerial_RxRingAdvanceIY
	ld	(xiz+ix), a
	calr	BootSerial_CtrlRingAdvanceIX
	ld	(0x0f6d:16), a
	and	w, 0x4f			; index bits of the first byte
	ld	xhl, 0x1022		; scramble buffer
	bit	6, w
	jr	z, BootSerial_RxPkt_TwoByteScrambled__no_bias
	sub	w, 0x30
BootSerial_RxPkt_TwoByteScrambled__no_bias:
	add	l, w
	jr	nc, BootSerial_RxPkt_TwoByteScrambled__no_carry
	inc	1, h
BootSerial_RxPkt_TwoByteScrambled__no_carry:
	ex8_ri	xhl, a			; swap A into the buffer slot,
	xor	a, (xhl)		; A = old ^ new
	ld	(xiz+ix), a
	calr	BootSerial_CtrlRingAdvanceIX
	ld	(0x0f6e:16), a
	ld	(xiz - 4), ix		; commit control-ring head
	decm	3, (xiz - 2)		; 3 slots consumed
	ld	(0x0f75:16), iy		; commit serial-ring tail
	jrl	t, BootSerial_RX_ParsePackets__next

; -----------------------------------------------------------------------------
; BootSerial_RxPkt_TwoByteDecode - RX class 2: 2-byte frame, external decode
; Stores the first byte raw, then hands (C = first byte, A = second byte)
; to the external decoder (BootSerial_CallExternalDecode).  HL = 0xffff
; means decode failure: the control-ring head byte is taken back and the
; packet dropped.  Otherwise the decoded byte L plus a 0xff terminator are
; appended (3 slots total, like class 0/1).
; Callers: BootSerial_RxPacketDispatchTable[2]
; -----------------------------------------------------------------------------
BootSerial_RxPkt_TwoByteDecode:
	ld	w, (xde+iy)	; first byte
	calr	BootSerial_RxRingAdvanceIY
	ld	(xiz+ix), w
	calr	BootSerial_CtrlRingAdvanceIX
	ld	(0x0f6c:16), w
	ld	a, (xde+iy)	; second byte
	calr	BootSerial_RxRingAdvanceIY
	ld	(0x0f6d:16), a
	ld	c, w
	calr	BootSerial_CallExternalDecode
	cp	hl, 0xffff		; decode failed?
	jr	nz, BootSerial_RxPkt_TwoByteDecode__store
	calr	BootSerial_CtrlRingRetreatIX	; drop the stored first byte
	ld	(0x0f75:16), iy
	jr	t, BootSerial_RxPkt_TwoByteDecode__exit
BootSerial_RxPkt_TwoByteDecode__store:
	ld	(xiz+ix), l	; decoded byte
	calr	BootSerial_CtrlRingAdvanceIX
	ld	(0x0f6e:16), l
	ld	(xiz+ix), 0xff	; terminator
	calr	BootSerial_CtrlRingAdvanceIX
	ld	(xiz - 4), ix		; commit control-ring head
	decm	3, (xiz - 2)
	ld	(0x0f75:16), iy		; commit serial-ring tail
BootSerial_RxPkt_TwoByteDecode__exit:
	jrl	t, BootSerial_RX_ParsePackets__next

; -----------------------------------------------------------------------------
; BootSerial_CallExternalDecode - register-saving decoder wrapper
; Preserves XDE/XIZ/XIX (the parser's ring pointers) around the call into
; the bootloader stub area.  BootStub_ReturnError is the shipped stub (it
; just returns HL = 0xffff), so in this firmware every class-2 decode
; fails and the packets are dropped - the hook exists for a patched-in
; decoder.
; Inputs:  C = first frame byte, A = second frame byte
; Outputs: HL = decoded value, or 0xffff on failure
; Callers: BootSerial_RxPkt_TwoByteDecode, BootSerial_RxPkt_VarLengthRun
; -----------------------------------------------------------------------------
BootSerial_CallExternalDecode:
	push	xde
	push	xiz
	push	xix
	calr	BootStub_ReturnError
	pop	xix
	pop	xiz
	pop	xde
	ret

; -----------------------------------------------------------------------------
; BootSerial_RxPkt_VarLengthRun - RX classes 6/7: variable-length run
; A arrives holding the parser's available-byte count.  The run header's
; low nibble gives the payload length ((header & 0x0f) + 1); the frame is
; only consumed once length + 2 bytes are available.  Each payload byte is
; stored raw, then either decoded externally (run tag bit 4 set - the
; decoded byte replaces it and failures drop the byte pair) or XOR-mixed
; through the 0x1022 scramble buffer like class 0/1.  With the collapse
; sentinel (0x0f64) bit 4 set, scrambled bytes that XOR to zero are elided
; (both control-ring slots taken back).  Each stored pair costs 3 slots
; less the elisions.
; Callers: BootSerial_RxPacketDispatchTable[6/7]
; -----------------------------------------------------------------------------
BootSerial_RxPkt_VarLengthRun:
	ld	w, a			; W = available-byte count
	ld	a, (xde+iy)	; A = run header
	ld	c, a
	and	a, 0x0f
	inc	1, a
	ld	b, a			; B = payload length
	add	a, 2
	cp	w, a			; whole run available?
	jrl	c, BootSerial_RxParseDone
	calr	BootSerial_RxRingAdvanceIY
	ld	a, (xde+iy)	; A = second header byte
	calr	BootSerial_RxRingAdvanceIY
	and	a, 0x1f
	and	c, 0xc0
	or	c, a
	ld	w, c			; W = run tag
	bit	4, w
	jr	nz, BootSerial_RxPkt_VarLengthRun__store	; decode mode:
								; no scramble ptr
	and	c, 0x40
	bit	6, c
	jr	z, BootSerial_RxPkt_VarLengthRun__no_bias
	sub	c, 0x30
BootSerial_RxPkt_VarLengthRun__no_bias:
	or	a, c
	ld	l, a
	extz	hl
	extz	xhl
	add	xhl, 0x00001022		; XHL = scramble buffer slot
BootSerial_RxPkt_VarLengthRun__store:
	ld	(xiz+ix), w	; run tag
	calr	BootSerial_CtrlRingAdvanceIX
	ld	a, (xde+iy)	; A = payload byte
	calr	BootSerial_RxRingAdvanceIY
	bit	4, w
	jr	z, BootSerial_RxPkt_VarLengthRun__scramble
	pushw	bc			; decode mode
	ld	c, w
	pushw	hl
	pushw	wa
	calr	BootSerial_CallExternalDecode
	popw	wa
	cp	hl, 0xffff
	ld	(0x0f6e:16), l
	popw	hl
	popw	bc
	jr	nz, BootSerial_RxPkt_VarLengthRun__decoded
	jr	t, BootSerial_RxPkt_VarLengthRun__drop_pair
BootSerial_RxPkt_VarLengthRun__drop_pair:
	calr	BootSerial_CtrlRingRetreatIX	; decode failed: take back tag
	ld	(0x0f75:16), iy
	jrl	t, BootSerial_RxPkt_VarLengthRun__step
BootSerial_RxPkt_VarLengthRun__decoded:
	ld	a, (0x0f6e:16)		; A = decoded byte
BootSerial_RxPkt_VarLengthRun__scramble:
	ld	(xiz+ix), a
	calr	BootSerial_CtrlRingAdvanceIX
	bit	4, w
	jr	nz, BootSerial_RxPkt_VarLengthRun__raw_done
	ex8_ri	xhl, a			; scramble mode: swap into buffer,
	xor	a, (xhl)		; A = old ^ new
	inc	1, hl
	bit	4, (0x0f64:16)		; collapse sentinel armed?
	jr	z, BootSerial_RxPkt_VarLengthRun__store_mixed
	cp	a, 0:i3
	jr	nz, BootSerial_RxPkt_VarLengthRun__store_mixed
	calr	BootSerial_CtrlRingRetreatIX	; unchanged byte: elide the
	calr	BootSerial_CtrlRingRetreatIX	; whole pair
	jr	t, BootSerial_RxPkt_VarLengthRun__commit_tail
BootSerial_RxPkt_VarLengthRun__raw_done:
	ld	a, 0xff:opc			; decode mode: 0xff terminator
BootSerial_RxPkt_VarLengthRun__store_mixed:
	ld	(xiz+ix), a
	calr	BootSerial_CtrlRingAdvanceIX
	ld	(xiz - 4), ix		; commit control-ring head
	decm	1, (xiz - 2)
	decm	1, (xiz - 2)
	decm	1, (xiz - 2)
BootSerial_RxPkt_VarLengthRun__commit_tail:
	ld	(0x0f75:16), iy		; commit serial-ring tail
BootSerial_RxPkt_VarLengthRun__step:
	inc	1, w			; next run tag
	dec	1, b
	cp	b, 0:i3
	jrl	nz, BootSerial_RxPkt_VarLengthRun__store
	jrl	t, BootSerial_RX_ParsePackets__next

; -----------------------------------------------------------------------------
; BootSerial_RxPkt_Discard - RX classes 3/4/5: consume and drop the frame
; Skips both frame bytes, commits the serial-ring tail and sets status
; bit 3 in (0x0f6a).
; Callers: BootSerial_RxPacketDispatchTable[3/4/5]
; -----------------------------------------------------------------------------
BootSerial_RxPkt_Discard:
	ld	a, (xde+iy)
	calr	BootSerial_RxRingAdvanceIY
	ld	a, (xde+iy)
	calr	BootSerial_RxRingAdvanceIY
	ld	(0x0f75:16), iy
	or	(0x0f6a:16), 0x08		; status: frame discarded
	jrl	t, BootSerial_RX_ParsePackets__next
BootSerial_RxParseDone:
	ret

; -----------------------------------------------------------------------------
; BootSerial_TX_EncodePackets - drain the TX control ring into the TX
; serial ring
; Mirror of the RX parser: reads packets from the TX transfer-control ring
; at 0x9914 (tail word at 0x990c, head at 0x9910, free-count at 0x9912),
; classifies each by (byte & 0x30) >> 4 through
; BootSerial_TxPacketDispatchTable (entries 4 bytes apart - the encoder
; shifts right by 2 only) and emits the frame bytes into the TX serial
; ring at 0x0fd9.  Stops when the control ring is empty (head == tail with
; a nonzero free count) or fewer than 3 serial-ring slots are free.
; Callers: BootSerial_PollTX
; -----------------------------------------------------------------------------
BootSerial_TX_EncodePackets:
	ld	iy, (0x0fd7:16)		; IY = serial-ring pending count
	ld	xde, 0x0fd9		; TX serial ring
	ld	xiz, 0x9914		; TX transfer-control block
	ld	ix, (xiz - 8)		; IX = control ring tail
BootSerial_TX_EncodePackets__next:
	ld	wa, (xiz - 4)		; head
	cp	wa, (xiz - 8)		; == tail?
	jr	nz, BootSerial_TX_EncodePackets__have_data
	cpw	(xiz - 2), 0		; empty (free count nonzero)?
	jrl	nz, BootSerial_TxEncodeDone
BootSerial_TX_EncodePackets__have_data:
	ld	wa, (0x0fd7:16)
	sub	wa, (0x0fd5:16)
	jr	nc, BootSerial_TX_EncodePackets__fwd
	neg	wa
	ld	hl, wa
	jr	t, BootSerial_TX_EncodePackets__have_free
BootSerial_TX_EncodePackets__fwd:
	ldw	hl, 0x003c
	sub	hl, wa			; free = ring size - used
BootSerial_TX_EncodePackets__have_free:
	cp	hl, 3:i3
	jrl	c, BootSerial_TxEncodeDone
	ld	a, (xiz+ix)	; packet tag
	and	a, 0x30
	srl	a, 2			; class * 4 = table offset
	ld	l, a
	xor	h, h
	extz	xhl
	add	xhl, BootSerial_TxPacketDispatchTable + 0x600000 ; boot alias
	ld	xhl, (xhl)
	jp	(xhl)

	.byte	0x20, 0x9e		; 2 bytes non-code filler

; -----------------------------------------------------------------------------
; BootSerial_TxPacketDispatchTable - 4 x .long, indexed by
; (packet tag & 0x30) >> 4.  Boot-time (0xffxxxx) addresses.
; -----------------------------------------------------------------------------
BootSerial_TxPacketDispatchTable:
	.long	BootSerial_TxPkt_TwoByte + 0x600000		; class 0
	.long	BootSerial_TxPkt_TwoByte + 0x600000		; class 1
	.long	BootSerial_TxPkt_TwoByte + 0x600000		; class 2
	.long	BootSerial_TxPkt_VarLengthRun + 0x600000	; class 3

; -----------------------------------------------------------------------------
; BootSerial_TxPkt_TwoByte - TX classes 0/1/2: emit a plain 2-byte frame
; Copies two control-ring bytes (A then W) into the TX serial ring,
; returns 2 free-count slots and commits tail and pending count.
; Callers: BootSerial_TxPacketDispatchTable[0/1/2]
; -----------------------------------------------------------------------------
BootSerial_TxPkt_TwoByte:
	ld	a, (xiz+ix)
	calr	BootSerial_CtrlRingAdvanceIX_Dup
	ld	(xde+iy), a
	calr	BootSerial_TxRingAdvanceIY
	ld	w, (xiz+ix)
	calr	BootSerial_CtrlRingAdvanceIX_Dup
	ld	(xde+iy), w
	calr	BootSerial_TxRingAdvanceIY
	ld	(xiz - 8), ix		; commit control-ring tail
	incw	1, (xiz - 2)		; 2 slots freed
	incw	1, (xiz - 2)
	ld	(0x0fd7:16), iy		; commit pending count
	jrl	t, BootSerial_TX_EncodePackets__next

; -----------------------------------------------------------------------------
; BootSerial_TxPkt_VarLengthRun - TX class 3: emit a variable-length run
; The run header's low nibble gives (header & 0x0f) + 2 payload bytes to
; copy after the header itself; each byte returns one free-count slot and
; the commit happens per byte.
; Callers: BootSerial_TxPacketDispatchTable[3]
; -----------------------------------------------------------------------------
BootSerial_TxPkt_VarLengthRun:
	ld	a, (xiz+ix)	; run header
	calr	BootSerial_CtrlRingAdvanceIX_Dup
	ld	c, a
	and	a, 0x0f
	add	a, 2
	ld	b, a			; B = payload count
	ld	a, c
	ld	(xde+iy), a	; emit header
	calr	BootSerial_TxRingAdvanceIY
	incw	1, (xiz - 2)
BootSerial_TxPkt_VarLengthRun__loop:
	ld	a, (xiz+ix)
	calr	BootSerial_CtrlRingAdvanceIX_Dup
	ld	(xde+iy), a
	calr	BootSerial_TxRingAdvanceIY
	ld	(xiz - 8), ix		; commit control-ring tail
	incw	1, (xiz - 2)
	ld	(0x0fd7:16), iy		; commit pending count
	dec	1, b
	cp	b, 0:i3
	jr	nz, BootSerial_TxPkt_VarLengthRun__loop
	jrl	t, BootSerial_TX_EncodePackets__next
BootSerial_TxEncodeDone:
	ret

; -----------------------------------------------------------------------------
; Ring-index helpers - post-increment/decrement IY/IX modulo the ring size
; Six 11-byte routines; the last two are BYTE-IDENTICAL DUPLICATES of the
; control-ring pair (the RX parser calls the first pair, the TX encoder the
; duplicates - most likely separate compiler instantiations).
; -----------------------------------------------------------------------------
BootSerial_RxRingAdvanceIY:
	inc	1, iy
	cp	iy, 0x005c		; RX serial ring size
	jr	c, BootSerial_RxRingAdvanceIY__done
	ld	iy, 0:i3
BootSerial_RxRingAdvanceIY__done:
	ret

BootSerial_TxRingAdvanceIY:
	inc	1, iy
	cp	iy, 0x003c		; TX serial ring size
	jr	c, BootSerial_TxRingAdvanceIY__done
	ld	iy, 0:i3
BootSerial_TxRingAdvanceIY__done:
	ret

BootSerial_CtrlRingAdvanceIX:
	inc	1, ix
	cp	ix, 0x0080		; control ring size
	jr	c, BootSerial_CtrlRingAdvanceIX__done
	ld	ix, 0:i3
BootSerial_CtrlRingAdvanceIX__done:
	ret

BootSerial_CtrlRingRetreatIX:
	cp	ix, 0:i3
	jr	nz, BootSerial_CtrlRingRetreatIX__dec
	ldw	ix, 0x007f
	ret
BootSerial_CtrlRingRetreatIX__dec:
	dec	1, ix
	ret

BootSerial_CtrlRingAdvanceIX_Dup:
	inc	1, ix
	cp	ix, 0x0080
	jr	c, BootSerial_CtrlRingAdvanceIX_Dup__done
	ld	ix, 0:i3
BootSerial_CtrlRingAdvanceIX_Dup__done:
	ret

BootSerial_CtrlRingRetreatIX_Dup:	; NO REFERENCE FOUND - dead duplicate
	cp	ix, 0:i3
	jr	nz, BootSerial_CtrlRingRetreatIX_Dup__dec
	ldw	ix, 0x007f
	ret
BootSerial_CtrlRingRetreatIX_Dup__dec:
	dec	1, ix
	ret

; -----------------------------------------------------------------------------
; BootSerial_RetStub - stubbed-out routine (bare ret)
; Callers: BootSerial_Call_RetStub thunk (boot 0xffed09, itself unreferenced)
; -----------------------------------------------------------------------------
BootSerial_RetStub:
	ret

; =============================================================================
; SHARED HARDWARE-CHANNEL + MEMORY LIBRARY (0x9ffa2c-0x9ffb2e, 259 bytes)
; =============================================================================
; This block is shared THREE WAYS across the KN5000 firmware:
;   - here (table_data bootloader), peripheral base 0x150000
;   - maincpu program ROM 0xef17f4-0xef18f6: AudioMix_Init /
;     AudioMix_WriteChannelGroup / LABEL_EF185A / COPY_DE_WORDS_FROM_XBC_TO_XWA
;     / FILL_MEMORY_AT_XWA_WITH_DE_WORDS_OF_BC_VALUE, base 0x150000
;   - subcpu boot ROM 0xff84a8-0xff85aa: INIT_TONE_GEN / TONE_GEN_WRITE /
;     WRITE_TONE_REG_MULTI_CHANNEL / WRITE_TONE_REG_SINGLE_CHANNEL /
;     COPY_WORDS / FILL_WORDS / CHECKSUM_CALC, base 0x130000 (the sub CPU's
;     tone generator)
; The table_data and subcpu copies are BYTE-IDENTICAL except for the three
; base-address immediates (0x150000 vs 0x130000) - verified by direct
; comparison (259 bytes, exactly 3 differing bytes).
;
; Register protocol (all three copies): A = (channel << 5) | 0x10 is written
; to base+0 as a register-address latch, then each data byte goes to base+2
; with A incremented between bytes.
;
; The labels here mirror the maincpu AudioMix_* names.  Note for a future
; pass: shared/boot_call_init_handlers.s documents its `call 0xfffa75` as an
; "indirect call helper" - it actually calls AudioMix_WriteChannelGroup with
; XBC pointing at an 8-byte register block from the 0xfffef0 table (compare
; TONE_GEN_CHANNEL_INIT in the subcpu boot ROM, which is the same routine
; built around the 0x130000 base).
; =============================================================================

; -----------------------------------------------------------------------------
; AudioMix_Init - reset all four hardware channels
; Writes the 8-byte scratch pattern 0x5a5a5a5a,0x5a5a5a5a to channels 0-3,
; then programs the four per-channel mode registers at offsets
; 0x1f/0x3f/0x5f/0x7f with 0x01 each (XWA = 0x0101001f walks address in A,
; data in W).
; Callers: NONE FOUND in table_data (no pointer, CALL or CALR site, boot- or
;          ROM-address) - retained library code; the subcpu twin
;          INIT_TONE_GEN is live (called from subcpu BOOT_INIT)
; -----------------------------------------------------------------------------
AudioMix_Init:
	link	xiz, 0xfff8	; LINK XIZ, -8
	xor	xwa, xwa
	ld	xwa, 0x5a5a5a5a		; scratch pattern
	ld	(xiz - 8), xwa
	ld	(xiz - 4), xwa
	lda	xwa, (xiz - 8)
	push	xwa
	ld	bc, 0:i3
	calr	AudioMix_WriteChannelGroup
	pop	xwa
	push	xwa
	ld	bc, 1:i3
	calr	AudioMix_WriteChannelGroup
	pop	xwa
	push	xwa
	ld	bc, 2:i3
	calr	AudioMix_WriteChannelGroup
	pop	xwa
	push	xwa
	ld	bc, 3:i3
	calr	AudioMix_WriteChannelGroup
	pop	xwa
	ld	xbc, 0x150000		; peripheral base (subcpu twin: 0x130000)
	ld	xwa, 0x101001f		; A = first reg 0x1f, W = data 0x01
	ld	d, 4:opc
AudioMix_Init__mode_loop:
	ld	w, a
	ld	(xbc), xwa
	add	a, 0x20			; next channel's mode register
	djnz8	d, AudioMix_Init__mode_loop
	unlk	xiz
	ret

; -----------------------------------------------------------------------------
; AudioMix_WriteChannelGroup - write 8 stacked bytes to one channel
; A register-address latch write (channel << 5 | 0x10) followed by 8 data
; bytes popped from the caller's stack frame via (XSP+), incrementing the
; register address each byte.
; Inputs:  BC = channel number, 8 data bytes on the stack (cdecl)
; Callers: AudioMix_Init (x4); Boot_CallInitHandlers (call 0xfffa75 in
;          shared/boot_call_init_handlers.s) with table-supplied blocks
; -----------------------------------------------------------------------------
AudioMix_WriteChannelGroup:
	pushw	de
	sll	a, 5
	set	4, a			; A = (channel << 5) | 0x10
	ld	xhl, 0x150000		; peripheral base (subcpu twin: 0x130000)
	ld	d, 8:opc
AudioMix_WriteChannelGroup__loop:
	ld	(xhl), a		; register-address latch
	ld	e, (xbc+)			; LD E, (XSP+)
	ld	(xhl + 2), e		; data byte
	inc	1, a
	djnz8	d, AudioMix_WriteChannelGroup__loop
	popw	de
	ret

; -----------------------------------------------------------------------------
; AudioMix_WriteAllChannelPairs - write four register pairs to channels 1,0,2,3
; Distributes the caller's register set across the four channels via
; AudioMix_WriteChannelPair: channel 1 gets the stacked XBC/XDE image (via
; XSP+0x0a and XIZ), channel 0 gets XWA/XHL, channel 2 XIX/XIY, channel 3
; the originals again.
; Callers: NONE FOUND in table_data (subcpu twin WRITE_TONE_REG_MULTI_CHANNEL
;          is live there; maincpu twin is LABEL_EF185A)
; [2026-09-25: v10 now labels 0xEF185A AudioMix_BytecodeData.]
; -----------------------------------------------------------------------------
AudioMix_WriteAllChannelPairs:
	push	xbc
	push	xde
	pushw	1
	calr	AudioMix_WriteChannelPair
	mrdl3	0xaf, 0x0a, 0x21	; LD XBC, (XSP+0x0a)
	ld	xde, xiz
	pushw	0
	calr	AudioMix_WriteChannelPair
	ld	xbc, xwa
	ld	xde, xhl
	pushw	2
	calr	AudioMix_WriteChannelPair
	ld	xbc, xix
	ld	xde, xiy
	pushw	3
	calr	AudioMix_WriteChannelPair
	inc	8, xsp			; drop the pushed channel number
	pop	xde
	pop	xbc
	ret

; -----------------------------------------------------------------------------
; AudioMix_WriteChannelPair - write an 8-byte register pair to one channel
; Streams C,B, QBC low/high, E,D, QDE low/high to consecutive registers of
; the channel taken from the stack, through the base+0 latch / base+2 data
; protocol.
; Inputs:  XBC/XDE = 8 data bytes, channel number word on the stack
; Callers: AudioMix_WriteAllChannelPairs (x4)
; -----------------------------------------------------------------------------
AudioMix_WriteChannelPair:
	push	xiy
	pushw	wa
	pushw	bc
	mrdb3	0x8f, 0x0c, 0x21	; LD A, (XSP+0x0c) - channel number
	sll	a, 5
	set	4, a			; A = (channel << 5) | 0x10
	ld	xiy, 0x150000		; peripheral base (subcpu twin: 0x130000)
	ld	(xiy), a
	ld	(xiy + 2), c
	inc	1, a
	ld	(xiy), a
	ld	(xiy + 2), b
	inc	1, a
	ld	(xiy), a
	ldto_werp	bc, 0xe6		; LD BC, QBC (high word of XBC)
	ld	(xiy + 2), c
	inc	1, a
	ld	(xiy), a
	ld	(xiy + 2), b
	inc	1, a
	ld	(xiy), a
	ld	(xiy + 2), e
	inc	1, a
	ld	(xiy), a
	ld	(xiy + 2), d
	inc	1, a
	ld	(xiy), a
	ldto_werp	bc, 0xea		; LD BC, QDE (high word of XDE)
	ld	(xiy + 2), c
	inc	1, a
	ld	(xiy), a
	ld	(xiy + 2), b
	popw	bc
	popw	wa
	pop	xiy
	ret

; -----------------------------------------------------------------------------
; Boot_CopyWords - copy DE words from XWA to XBC
; The .equ BootRAM_MemoryCopy (kn5000_table_data.s) is this routine's
; boot-time alias, used by the flash-update RAM-relocation code.
; Inputs:  XWA = source, XBC = destination, DE = word count
; Callers: INITPROGRESSDISPLAY_FILLREGION (boot 0xffcd90),
;          VGA_FINALIZEINITIALIZATION (boot 0xffd7ce)
; -----------------------------------------------------------------------------
Boot_CopyWords:
	ld	xix, xwa
	ld	xiy, xbc
	ld	bc, de
	ldirw
	ret

; -----------------------------------------------------------------------------
; Boot_FillWords - fill DE words at XWA with the pattern in BC
; The .equ BootRAM_MemoryFill (kn5000_table_data.s) is this routine's
; boot-time alias.
; Inputs:  XWA = destination, BC = fill word, DE = word count
; Callers: VGA_FINALIZEINITIALIZATION (boot 0xffd7bd)
; -----------------------------------------------------------------------------
Boot_FillWords:
	ld	(xwa+), bc
	djnz16	de, Boot_FillWords
	ret

; -----------------------------------------------------------------------------
; Boot_ChecksumWords - complemented 32-bit sum over a word range
; Inputs:  XWA = start address, BC = byte count (extended, added to XWA)
; Outputs: HL = one's complement of the 32-bit sum of the words
; Callers: NONE FOUND in table_data (subcpu twin CHECKSUM_CALC verifies the
;          payload there)
; -----------------------------------------------------------------------------
Boot_ChecksumWords:
	xor	xhl, xhl
	extz	xbc
	add	xbc, xwa		; XBC = end address
Boot_ChecksumWords__loop:
	add xhl, (xwa+)
	cp	xwa, xbc
	jr	lt, Boot_ChecksumWords__loop
	cpl	hl
	ret
