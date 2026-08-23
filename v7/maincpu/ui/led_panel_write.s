; =============================================================================
; Control-panel LED write sequence
; =============================================================================
; Moved out of audio/audio_control_engine.s, where it sat between the audio
; control code and the SndParam_* register helpers with no relation to either.
; It drives the control panel, not the tone generator.
;
; LED_WriteToPanel(xwa -> 3-byte LED frame) writes the frame one byte at a time
; through Seq_TimerEventLoop, and calls CPanel_Poll between bytes whenever the
; timer loop reports 0xFFFF -- i.e. it services the panel link while waiting.
;
; The entry and its three internal branch targets are ONE routine and are kept
; together: LED_WriteSecondByte, LED_WriteThirdByte and LED_WriteDone are jump
; targets inside it, not separate callables.
;
; !! Position matters. This file is `.include`d at exactly the point the block
; occupied, so the link order -- and therefore every byte -- is unchanged.
; =============================================================================
LED_WriteToPanel:
	push xiz
	ld xiz, xwa
	ld a, (xiz)
	extz wa
	pushw wa
	call Seq_TimerEventLoop
	inc 2, xsp
	cp hl, 0xffff
	jr nz, LED_WriteSecondByte
	push xde
	push xhl
	push xix
	push xiz
	call CPanel_Poll
	pop xiz
	pop xix
	pop xhl
	pop xde
	ld xwa, xiz
	jr LED_WriteThirdByte

LED_WriteSecondByte:
	ld a, (xiz + 1)
	extz wa
	pushw wa
	call Seq_TimerEventLoop
	inc 2, xsp
	cp hl, 0xffff
	jr nz, LED_WriteDone
	push xde
	push xhl
	push xix
	push xiz
	call CPanel_Poll
	pop xiz
	pop xix
	pop xhl
	pop xde
	lda xwa, (xiz + 1)

LED_WriteThirdByte:
	ld a, (xwa)
	extz wa
	pushw wa
	call Seq_TimerEventLoop
	inc 2, xsp

LED_WriteDone:
	pop xiz
	ret
