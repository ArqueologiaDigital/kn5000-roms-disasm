; =============================================================================
; midi_serial_routines.asm - MIDI Serial Communication (SC0)
; =============================================================================
; This file contains the MIDI serial communication routines for the KN5000
; Main CPU. Serial Channel 0 (SC0) is used for MIDI communication.
;
; Key routines:
;   INTTX0_HANDLER        - MIDI TX interrupt handler
;   INTRX0_HANDLER        - MIDI RX interrupt handler
;   READ_COM_SELECT_SWITCH - Reads COM port selection switch (MIDI/MAC/PC1/PC2)
;   LABEL_FCF940          - SC0 serial port initialization
;
; Hardware:
;   Serial Channel 0 (SC0) registers:
;     SC0BUF (0xD0) - Serial buffer
;     SC0CR  (0xD1) - Control register
;     SC0MOD (0xD2) - Mode register
;     BR0CR  (0xD3) - Baud rate control
;
; COM_SELECT switch values:
;   0x00 = MIDI
;   0x01 = MAC
;   0x02 = PC1
;   0x03 = PC2
;
; =============================================================================

MIDI_INIT_SEQUENCES:
	calr LABEL_FCEEA6
	calr LABEL_FCEEC4
	calr LABEL_FCEF89
	calr LABEL_FCEFB9
	ldada xbc, 38808
	ld xwa, xbc
	lda xbc, (xbc + 64)

LABEL_FCF130:
	x_dpi4_o02_t2 0xE1, 0x00, 0x00
	cp xwa, xbc
	jr c, LABEL_FCF130
	ret

LABEL_FCF13A:
	ret

LABEL_FCF13B:
	ret

LABEL_FCF13C:
	ret

INTRX0_CLEAR_ERROR_STATE:
	pushw wa
	ldda8 a, 208
	stdi8 1059, 0
	anddi8 1063, 189
	setda 3, 1063
	stdi8 1074, 0
	incdi8 1, 47070
	popw wa
	reti

INTTX0_HANDLER:	; FCF15B
	pushw wa
	pushw hl
	ldda8 a, 1065
	bit 0, a
	jr nz, LABEL_FCF18B
	bit 4, a
	jr nz, LABEL_FCF19C
	bit 1, a
	jr nz, LABEL_FCF1A7
	bit 2, a
	jr nz, LABEL_FCF1B8
	bit 3, a
	jr z, LABEL_FCF1C9
	resda 3, 1065
	bitda 4, 64848
	jr nz, LABEL_FCF1A0
	stdi8 208, 252
	jr LABEL_FCF1D7

LABEL_FCF18B:
	resda 0, 1065
	bitda 4, 64848
	jr nz, LABEL_FCF1A0
	stdi8 208, 248
	jr LABEL_FCF1D7

LABEL_FCF19C:
	resda 4, 1065

LABEL_FCF1A0:
	stdi8 208, 254
	jr LABEL_FCF1D7

LABEL_FCF1A7:
	resda 1, 1065
	bitda 4, 64848
	jr nz, LABEL_FCF1A0
	stdi8 208, 250
	jr LABEL_FCF1D7

LABEL_FCF1B8:
	resda 2, 1065
	bitda 4, 64848
	jr nz, LABEL_FCF1A0
	stdi8 208, 251
	jr LABEL_FCF1D7

LABEL_FCF1C9:
	call 0xEF280E
	cp hl, 0xFFFF
	jr z, LABEL_FCF1D7
	stda8 208, l

LABEL_FCF1D7:
	ldda8 a, 1065
	and a, 0x1F
	jr nz, LABEL_FCF1ED
	call LABEL_EF2853
	and hl, hl
	jr nz, LABEL_FCF1ED
	stdi8 234, 253

LABEL_FCF1ED:
	popw hl
	popw wa
	reti

INTRX0_HANDLER:	; FCF1F0
	pushw wa
	ldda8 a, 209
	and a, 0x1C
	popw wa
	jrl nz, INTRX0_CLEAR_ERROR_STATE
	push xwa
	push xbc
	push xde
	push xhl
	push xix
	push xiy
	push xiz
	ldda8 a, 208
	stdi8 1061, 0
	dec 2, xsp
	ld (xsp), a
	lda xwa, (xsp)
	push xwa
	lds wa, 1
	pushw wa
	call LABEL_FDB7DC
	inc 8, xsp
	pop xiz
	pop xiy
	pop xix
	pop xhl
	pop xde
	pop xbc
	pop xwa
	reti

MIDI_RX_BYTE_DISPATCHER:
	stda8 47071, a
	push xwa
	push xbc
	push xde
	push xhl
	push xix
	push xiy
	push xiz
	calr MIDI_RX_CONTEXT_RESTORE
	ldda8 a, 47071
	bit 7, a
	jr z, LABEL_FCF289
	cp a, 0xF7
	jr ule, LABEL_FCF245
	calr MIDI_SYSTEM_MESSAGE_HANDLER
	jr LABEL_FCF28C

LABEL_FCF245:
	stda8 1059, a
	anddi8 1063, 189
	bitda 0, 1074
	jr z, LABEL_FCF28C
	bitda 1, 1074
	jr z, LABEL_FCF271
	cp a, 0xF7
	jr nz, LABEL_FCF27D
	bitda 5, 1074
	jr nz, LABEL_FCF271
	pushw wa
	call LABEL_EF28C9
	inc 2, xsp
	stdi8 1074, 4

LABEL_FCF271:
	stdi8 1059, 0
	anddi8 1074, 204
	jr LABEL_FCF28C

LABEL_FCF27D:
	stdi8 1074, 16
	stdi8 1059, 0
	jr LABEL_FCF28C

LABEL_FCF289:
	calr MIDI_CHANNEL_MESSAGE_DISPATCHER

LABEL_FCF28C:
	calr MIDI_RX_CONTEXT_SAVE
	pop xiz
	pop xiy
	pop xix
	pop xhl
	pop xde
	pop xbc
	pop xwa
	ret

MIDI_SYSTEM_MESSAGE_HANDLER:
	cp a, 0xFE
	jr nz, LABEL_FCF2A1
	setda 7, 1063

LABEL_FCF2A0:
	ret

LABEL_FCF2A1:
	bitda 4, 64848
	jr nz, LABEL_FCF2A0
	cp a, 0xFD
	jr nc, LABEL_FCF2A0
	bitda 6, 47074
	jr nz, LABEL_FCF2A0
	cpdi8 32523, 0
	jr z, LABEL_FCF2CC
	cp a, 0xFA
	jr nz, LABEL_FCF2C3
	call LABEL_F71E36
	ret

LABEL_FCF2C3:
	cp a, 0xFC
	jr nz, LABEL_FCF2CC
	setda 0, 32565

LABEL_FCF2CC:
	ld d, a
	bitda 2, 64848
	jrl z, LABEL_FCF5F9
	cp d, 0xF8
	jr nz, LABEL_FCF342
	bitda 5, 10412
	jr z, LABEL_FCF2E4
	incdi8 1, 1108

LABEL_FCF2E4:
	ldda8 a, 1066
	cp a, 0x70
	jr ugt, LABEL_FCF301
	cps a, 4
	jr ugt, LABEL_FCF2F7
	ldda16 xwa, 47064
	jr LABEL_FCF305

LABEL_FCF2F7:
	extz xwa
	xor w, w
	x_sd16w3_s48 0xDA, 0xB7
	jr LABEL_FCF305

LABEL_FCF301:
	ldda16 xwa, 47062

LABEL_FCF305:
	stda16 146, xwa	; LD (TREG5L), WA
	stdi8 1066, 0
	bitda 0, 1055
	jr z, LABEL_FCF319
	stdi8 1055, 6

LABEL_FCF319:
	bitda 2, 1055
	jr z, LABEL_FCF342
	anddi8 1130, 252
	incdi8 4, 1130
	cpdi8 1130, 96
	jr nz, LABEL_FCF342
	stdi8 1130, 0
	incdi16 1, 1128
	cpdi8 32523, 0
	jr z, LABEL_FCF342
	calr MIDI_QUEUE_TRACK_EVENT

LABEL_FCF342:
	ldda8 a, 1056
	pushw wa
	and a, 0x5
	popw wa
	jrl z, LABEL_FCF4DF
	cp d, 0xF8
	jrl nz, LABEL_FCF48F
	bit 0, a
	jr z, LABEL_FCF377
	stdi8 1056, 6
	bitda 0, 1054
	jr z, LABEL_FCF369
	stdi8 1054, 6

LABEL_FCF369:
	bitda 0, 1057
	jr z, LABEL_FCF374
	stdi8 1057, 6

LABEL_FCF374:
	jrl LABEL_FCF48F

LABEL_FCF377:
	bit 2, a
	jr z, LABEL_FCF395
	anddi8 1047, 252
	incdi8 4, 1047
	cpdi8 1047, 96
	jr nz, LABEL_FCF395
	stdi8 1047, 0
	incdi16 1, 1048

LABEL_FCF395:
	bitda 2, 1054
	jr z, LABEL_FCF3EC
	anddi8 1045, 252
	incdi8 4, 1045
	cpdi8 1045, 96
	jr nz, LABEL_FCF3EC
	stdi8 1045, 0
	incdi8 1, 1046
	ldda8 a, 14235
	and a, 0x1F
	jr z, LABEL_FCF3C0
	calr MIDI_QUEUE_TRACK_EVENT

LABEL_FCF3C0:
	ldda8 a, 1046
	ldda8 w, 1075
	x_sd16b3_s30 0x58, 0x04
	cp a, w
	jr c, LABEL_FCF3EC
	stdi8 1046, 0
	incdi8 1, 1076
	incdi8 1, 1077
	ldda8 a, 1077
	cpda8 a, 13527
	jr ule, LABEL_FCF3EC
	stdi8 1077, 0

LABEL_FCF3EC:
	ldda8 a, 1045
	ld w, a
	subda8 a, 1111
	jr z, LABEL_FCF41D
	jr ugt, LABEL_FCF3FD
	add a, 0x60

LABEL_FCF3FD:
	stda8 1111, w
	adddm8 1124, a
	adddm8 1122, a
	xor w, w
	addda16 xwa, 1120
	cp a, 0x60
	jr c, LABEL_FCF419
	sub a, 0x60
	inc 1, w

LABEL_FCF419:
	stda16 1120, xwa

LABEL_FCF41D:
	bitda 2, 1057
	jr z, LABEL_FCF48F
	anddi8 1051, 252
	incdi8 4, 1051
	ldda8 a, 1051
	bitda 0, 1073
	jr z, LABEL_FCF452
	cpda8 a, 1071
	jr nz, LABEL_FCF452
	resda 0, 1073
	stdi8 1054, 1
	cpdi16 10410, 0
	jr z, LABEL_FCF452
	ldb a, 0x85
	calr MIDI_QUEUE_EVENT_PAIR

LABEL_FCF452:
	bitda 3, 1073
	jr z, LABEL_FCF474
	cpda8 a, 1072
	jr nz, LABEL_FCF474
	resda 3, 1073
	stdi8 1054, 8
	cpdi16 10410, 0
	jr z, LABEL_FCF474
	ldb a, 0x86
	calr MIDI_QUEUE_EVENT_PAIR

LABEL_FCF474:
	cpdi8 1051, 96
	jr nz, LABEL_FCF4DE
	stdi8 1051, 0
	incdi16 1, 1052
	cpdi16 10410, 0
	jr z, LABEL_FCF48F
	calr MIDI_QUEUE_TRACK_EVENT

LABEL_FCF48F:
	bitda 2, 64850
	jr z, LABEL_FCF4DE
	cp d, 0xFC
	jr nz, LABEL_FCF4DE
	stdi8 1056, 16
	bitda 2, 1054
	jr z, LABEL_FCF4C1
	bitda 2, 1057
	jr z, LABEL_FCF4AF
	setda 2, 13434

LABEL_FCF4AF:
	stdi8 1054, 16
	cpdi16 10410, 0
	jr z, LABEL_FCF4C1
	ldb a, 0x86
	calr MIDI_QUEUE_EVENT_PAIR

LABEL_FCF4C1:
	bitda 2, 1057
	jr z, LABEL_FCF4DE
	stdi8 1057, 16
	pushw wa
	ldda8 a, 1045
	stda8 1078, a
	ldda8 a, 1046
	stda8 1079, a
	popw wa

LABEL_FCF4DE:
	ret

LABEL_FCF4DF:
	bitda 2, 64850
	jr z, LABEL_FCF4C1
	bitda 2, 10407
	jr nz, LABEL_FCF4F6
	cp d, 0xFA
	jr z, LABEL_FCF50A
	cp d, 0xFB
	jrl z, LABEL_FCF5BE

LABEL_FCF4F6:
	ret

MIDI_START_PLAYBACK_REQUEST:
	cpdi16 61854, 0
	jr z, LABEL_FCF509
	push_sr
	ei 6
	calr MIDI_RESET_PLAYBACK_STATE
	calr MIDI_APPLY_STARTUP_TIMING
	pop_sr

LABEL_FCF509:
	ret

LABEL_FCF50A:
	setda 5, 10412
	stdi8 1108, 0
	cpdi16 61854, 0
	jr nz, LABEL_FCF56B

MIDI_RESET_PLAYBACK_STATE:
	xor wa, wa
	stda8 1047, a
	stda16 1048, xwa
	stdi8 1056, 1
	bitda 1, 10407
	jr z, LABEL_FCF556
	stda8 1045, a
	stda8 1046, a
	stda8 1076, a
	stda8 1077, a
	stdi8 1054, 1
	resda 0, 10406
	cpdi16 10410, 0
	jr z, LABEL_FCF556
	ldb a, 0x85
	calr MIDI_QUEUE_EVENT_PAIR

LABEL_FCF556:
	bitda 0, 10407
	jr z, LABEL_FCF56B
	xor wa, wa
	stda8 1051, a
	stda16 1052, xwa
	stdi8 1057, 1

LABEL_FCF56B:
	ret

MIDI_APPLY_STARTUP_TIMING:
	cpdi8 1108, 0
	jr z, LABEL_FCF5B8
	bitda 0, 1056
	jr z, LABEL_FCF5B8
	stdi8 1056, 6
	ldda8 a, 1108
	dec 1, a
	sll a, 2
	adddm8 1047, a
	bitda 0, 1055
	jr z, LABEL_FCF59A
	stdi8 1055, 6
	adddm8 1130, a

LABEL_FCF59A:
	bitda 0, 1054
	jr z, LABEL_FCF5A9
	stdi8 1054, 6
	adddm8 1045, a

LABEL_FCF5A9:
	bitda 0, 1057
	jr z, LABEL_FCF5B8
	stdi8 1057, 6
	adddm8 1051, a

LABEL_FCF5B8:
	stdi8 1108, 0
	ret

LABEL_FCF5BE:
	stdi8 1056, 6
	bitda 0, 10407
	jr z, LABEL_FCF5F8
	stdi8 1057, 6
	bitda 1, 10407
	jr z, LABEL_FCF5F8
	bitda 0, 10406
	jr nz, LABEL_FCF5E4
	stdi8 1045, 0
	stdi8 1046, 0

LABEL_FCF5E4:
	stdi8 1076, 0
	stdi8 1077, 0
	anddi8 10406, 254
	stdi8 1054, 6

LABEL_FCF5F8:
	ret

LABEL_FCF5F9:
	stdi8 1066, 0
	pushw wa
	ldda8 a, 1056
	and a, 0x5
	popw wa
	jr z, LABEL_FCF659
	bitda 2, 64850
	jr z, LABEL_FCF658
	cp d, 0xFC
	jr nz, LABEL_FCF658
	stdi8 1056, 12
	bitda 2, 1054
	jr z, LABEL_FCF63B
	bitda 2, 1057
	jr z, LABEL_FCF629
	setda 2, 13434

LABEL_FCF629:
	stdi8 1054, 12
	cpdi16 10410, 0
	jr z, LABEL_FCF63B
	ldb a, 0x86
	calr MIDI_QUEUE_EVENT_PAIR

LABEL_FCF63B:
	bitda 2, 1057
	jr z, LABEL_FCF658
	stdi8 1057, 12
	pushw wa
	ldda8 a, 1045
	stda8 1078, a
	ldda8 a, 1046
	stda8 1079, a
	popw wa

LABEL_FCF658:
	ret

LABEL_FCF659:
	bitda 2, 64850
	jr z, LABEL_FCF66F
	bitda 2, 10407
	jr nz, LABEL_FCF66F
	cp d, 0xFA
	jr z, LABEL_FCF670
	cp d, 0xFB
	jr z, LABEL_FCF67C

LABEL_FCF66F:
	ret

LABEL_FCF670:
	setda 1, 1065
	stdi8 234, 221
	jrl LABEL_FCF50A

LABEL_FCF67C:
	bitda 0, 10407
	jr z, LABEL_FCF68E
	setda 2, 1065
	stdi8 234, 221
	jrl LABEL_FCF5BE

LABEL_FCF68E:
	ret

MIDI_QUEUE_TRACK_EVENT:
	bitda 0, 1113
	jr nz, LABEL_FCF6BF
	pushw wa
	ld xix, 0x1E753
	ld wa, (xix - 2)
	and wa, wa
	jr z, LABEL_FCF6B7
	ld hl, (xix - 4)
	x_dri5_o00_t1 0x07, 0xF0, 0xEC, 0x81
	minc1_16 hl, 0x7FF
	dec 1, wa
	ld (xix - 4), hl
	ld (xix - 2), wa

LABEL_FCF6B7:
	popw wa
	stdi16 1141, 0
	ret

LABEL_FCF6BF:
	ld xix, 0x477
	ldda16 xhl, 1141
	x_dri5_o00_t1 0x07, 0xF0, 0xEC, 0x81
	inc 1, hl
	stda16 1141, xhl
	ret

MIDI_QUEUE_EVENT_PAIR:
	bitda 0, 1113
	jr nz, LABEL_FCF713
	cpdi16_24 124753, 2
	jr c, LABEL_FCF70C
	push_sr
	ei 6
	ld xix, 0x1E753
	ld hl, (xix - 4)
	lda_xbc_dri3 0x07, 0xF0, 0xEC
	minc1_16 hl, 0x7FF
	ldda8 a, 1051
	lda_xbc_dri3 0x07, 0xF0, 0xEC
	minc1_16 hl, 0x7FF
	ld (xix - 4), hl
	decm 2, (xix - 2)
	pop_sr

LABEL_FCF70C:
	stdi16 1141, 0
	ret

LABEL_FCF713:
	ld xix, 0x477
	ldda16 xhl, 1141
	lda_xbc_dri3 0x07, 0xF0, 0xEC
	inc 1, hl
	ldda8 a, 1051
	lda_xbc_dri3 0x07, 0xF0, 0xEC
	inc 1, hl
	stda16 1141, xhl
	ret

MIDI_CHANNEL_MESSAGE_DISPATCHER:
	ld e, a
	ldda8 a, 1059
	ld d, a
	bitda 0, 1074
	jrl nz, LABEL_FCF849
	bitda 6, 1063
	jr nz, LABEL_FCF7AF
	cps a, 0
	jr z, LABEL_FCF781
	and a, 0x70
	srl a, 2
	xor w, w
	ld xix, 0xFCF761
	ld_xix_sril3 0x07, 0xF0, 0xE0
	jp (xix)
MIDI_CHANNEL_HANDLER_JUMP_TABLE:
	.byte 0xff, 0xa8, 0xf7, 0xfc, 0x00, 0xa8, 0xf7, 0xfc
	.byte 0x00, 0x81, 0xf7, 0xfc, 0x00, 0xa8, 0xf7, 0xfc
	.byte 0x00, 0x82, 0xf7, 0xfc, 0x00, 0x82, 0xf7, 0xfc
	.byte 0x00, 0xa8, 0xf7, 0xfc, 0x00, 0x00, 0xf8, 0xfc
	.byte 0x00

LABEL_FCF781:
	ret

MIDI_QUEUE_EVENT_TO_SEQUENCER:
	ld xix, 0x1F37B
	cpmi16 (xix - 2), 0x3
	jr c, LABEL_FCF79F
	ld a, d
	pushw wa
	call 0xEF276D
	inc 2, xsp
	pushw de
	call 0xEF276D
	inc 2, xsp
	ret

LABEL_FCF79F:
	setda 2, 1063
	incdi8 1, 47069
	ret

LABEL_FCF7A8:
	setda 6, 1063
	ld c, e
	ret

LABEL_FCF7AF:
	bitda 1, 1063
	jr z, LABEL_FCF7B7
	ldb d, 0xF2

LABEL_FCF7B7:
	ld xix, 0x1F37B
	cpmi16 (xix - 2), 0x40
	jr ugt, LABEL_FCF7D1
	pushw de
	and d, 0xF0
	cp d, 0x90
	popw de
	jr nz, LABEL_FCF7D1
	cps e, 0
	jr nz, LABEL_FCF7F6

LABEL_FCF7D1:
	cpmi16 (xix - 2), 0x4
	jr c, LABEL_FCF7F7
	ld a, d
	pushw wa
	call 0xEF276D
	inc 2, xsp
	ld a, c
	pushw wa
	call 0xEF276D
	inc 2, xsp
	pushw de
	call 0xEF276D
	inc 2, xsp
	anddi8 1063, 189

LABEL_FCF7F6:
	ret

LABEL_FCF7F7:
	setda 2, 1063
	incdi8 1, 47069
	ret

MIDI_SYSTEM_EXCLUSIVE_HANDLER:
	stdi8 1059, 0
	cp d, 0xF0
	jr z, LABEL_FCF820
	cp d, 0xF2
	jr z, LABEL_FCF815
	cp d, 0xF3
	jr z, LABEL_FCF81D
	ret

LABEL_FCF815:
	ordi8 1063, 66
	ld c, e
	ret

LABEL_FCF81D:
	jrl MIDI_QUEUE_EVENT_TO_SEQUENCER

LABEL_FCF820:
	stdi8 1074, 1
	cp e, 0x50
	jr z, LABEL_FCF834
	cp e, 0x41
	jr z, LABEL_FCF834
	cp e, 0x7E
	jr nz, LABEL_FCF848

LABEL_FCF834:
	setda 1, 1074
	ld a, d
	pushw wa
	call LABEL_EF28C9
	inc 2, xsp
	pushw de
	call LABEL_EF28C9
	inc 2, xsp

LABEL_FCF848:
	ret

LABEL_FCF849:
	bitda 1, 1074
	jr z, LABEL_FCF85C
	bitda 5, 1074
	jr nz, LABEL_FCF85C
	pushw de
	call LABEL_EF28C9
	inc 2, xsp

LABEL_FCF85C:
	ret

MIDI_RX_CONTEXT_RESTORE:
	ldda32 xwa, 1080
	ldda32 xbc, 1084
	ldda32 xde, 1088
	ldda32 xhl, 1092
	ldda32 xix, 1096
	ldda32 xiy, 1100
	ldda32 xiz, 1104
	ret

MIDI_RX_CONTEXT_SAVE:
	stda32 1080, xwa
	stda32 1084, xbc
	stda32 1088, xde
	stda32 1092, xhl
	stda32 1096, xix
	stda32 1100, xiy
	stda32 1104, xiz
	ret

LABEL_FCF897:
	resda 0, 47079
	stdi8 47073, 0
	calr LABEL_FCF91C
	calr LABEL_FCF8B1
	calr READ_COM_SELECT_SWITCH
	call LABEL_FDBA02
	calr LABEL_FCF940
	ret

LABEL_FCF8B1:
	call 0xEF0865
	cps l, 4
	jr z, LABEL_FCF8D8
	stdi16 47060, 31250
	stdi16 47062, 10416
	stdi16 47064, 4166
	stdi16 47066, 1000
	stdi8 47068, 8	; BR0CR: clk=fc/4/8 = 500kHz (baudrate for MIDI ?!)
	jr LABEL_FCF8F5

LABEL_FCF8D8:
	stdi16 47060, 23437
	stdi16 47062, 7812
	stdi16 47064, 3125
	stdi16 47066, 750
	stdi8 47068, 6	; BR0CR: clk=fc/4/6 = 666.6kHz (baudrate for MIDI ?!)

LABEL_FCF8F5:
	ret

READ_COM_SELECT_SWITCH:	; FCF8F6
	ldda8 a, 104
	srl a, 4
	ld xix, 0xFCF90C
	ld_a_srib3 0x03, 0xF0, 0xE0
	stda8 47072, a
	ret

; Input: Active-low "COM_SELECT"
; bit 7: MIDI
; bit 6: MAC
; bit 5: PC1
; bit 4: PC2
;
; Output:
;   000h = MIDI
;   001h = MAC
;   002h = PC1
;   003h = PC2
;
; Note: Bad switch positioning data (more than a single low-bit)
;       is treated as MIDI selection.
;
OFFSETS_FCF90C:
	.byte 0x00
	.byte 0x00
	.byte 0x00
	.byte 0x00
	.byte 0x00
	.byte 0x00
	.byte 0x00
	.byte 0x00	; MIDI
	.byte 0x00
	.byte 0x00
	.byte 0x00
	.byte 0x01	; MAC
	.byte 0x00
	.byte 0x02	; PC1
	.byte 0x03	; PC2
	.byte 0x00

LABEL_FCF91C:
	stdi8 1080, 0
	stdi8 1084, 0
	stdi8 1088, 0
	stdi8 1092, 0
	stdi8 1096, 0
	stdi8 1100, 0
	stdi8 1104, 0
	ret

LABEL_FCF940:
	ei 6
	stdi8 210, 41
	stdi8 209, 0
	ldda8 a, 47068
	stda8 211, a
	stdi8 234, 93
	stdi8 208, 254
	ei 0
	ret

LABEL_FCF961:
	ret

LABEL_FCF962:
	.byte 0x97, 0xf8, 0xfc, 0x00, 0x61, 0xf9, 0xfc, 0x00
	.byte 0x61, 0xf9, 0xfc, 0x00, 0x61, 0xf9, 0xfc, 0x00

LABEL_FCF972:
	push xwa
	push xbc
	push xde
	push xhl
	push xix
	push xiy
	push xiz
	cpdi8 47072, 0	; 000h means MIDI
	jr nz, LABEL_FCF985
	calr LABEL_FCF991
	jr LABEL_FCF989

LABEL_FCF985:
	call LABEL_FDB903

LABEL_FCF989:
	pop xiz
	pop xiy
	pop xix
	pop xhl
	pop xde
	pop xbc
	pop xwa
	ret

LABEL_FCF991:
	push_sr
	ei 6
	cpdi8 1140, 85
	jr z, LABEL_FCF9A2
	stdi8 234, 221
	jr LABEL_FCF9AB

LABEL_FCF9A2:
	call LABEL_EF286B
	stdi8 1065, 0

LABEL_FCF9AB:
	pop_sr
	ret

; End of MIDI Serial routines

