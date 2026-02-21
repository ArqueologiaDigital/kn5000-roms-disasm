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
	CALR LABEL_FCEEA6
	CALR LABEL_FCEEC4
	CALR LABEL_FCEF89
	CALR LABEL_FCEFB9
	lda XBC, 0x9798
	ld XWA, XBC
	lda XBC, XBC + 0x40

LABEL_FCF130:
	ldw (XWA+), 0x0
	cp XWA, XBC
	jr C, LABEL_FCF130
	ret

LABEL_FCF13A:
	ret

LABEL_FCF13B:
	ret

LABEL_FCF13C:
	ret

INTRX0_CLEAR_ERROR_STATE:
	push WA
	ld A, (SC0BUF)
	ld (0x423), 0x0
	and (0x427), 0xbd
	set 3, (0x427)
	ld (0x432), 0x0
	inc 1, (0xB7DE)
	pop WA
	reti

INTTX0_HANDLER:	; FCF15B
	push WA
	push HL
	ld A, (0x429)
	bit 0x0, A
	jr NZ, LABEL_FCF18B
	bit 0x4, A
	jr NZ, LABEL_FCF19C
	bit 0x1, A
	jr NZ, LABEL_FCF1A7
	bit 0x2, A
	jr NZ, LABEL_FCF1B8
	bit 0x3, A
	jr Z, LABEL_FCF1C9
	res 3, (0x429)
	bit 4, (0xFD50)
	jr NZ, LABEL_FCF1A0
	ld (SC0BUF), 0xfc
	jr LABEL_FCF1D7

LABEL_FCF18B:
	res 0, (0x429)
	bit 4, (0xFD50)
	jr NZ, LABEL_FCF1A0
	ld (SC0BUF), 0xf8
	jr LABEL_FCF1D7

LABEL_FCF19C:
	res 4, (0x429)

LABEL_FCF1A0:
	ld (SC0BUF), 0xfe
	jr LABEL_FCF1D7

LABEL_FCF1A7:
	res 1, (0x429)
	bit 4, (0xFD50)
	jr NZ, LABEL_FCF1A0
	ld (SC0BUF), 0xfa
	jr LABEL_FCF1D7

LABEL_FCF1B8:
	res 2, (0x429)
	bit 4, (0xFD50)
	jr NZ, LABEL_FCF1A0
	ld (SC0BUF), 0xfb
	jr LABEL_FCF1D7

LABEL_FCF1C9:
	call SeqAlt1_ReadByte
	cp HL, 0xffff
	jr Z, LABEL_FCF1D7
	ld (SC0BUF), L

LABEL_FCF1D7:
	ld A, (0x429)
	and A, 0x1f
	jr NZ, LABEL_FCF1ED
	call LABEL_EF2853
	and HL, HL
	jr NZ, LABEL_FCF1ED
	ld (INTES0), 0xfd

LABEL_FCF1ED:
	pop HL
	pop WA
	reti

INTRX0_HANDLER:	; FCF1F0
	push WA
	ld A, (SC0CR)
	and A, 0x1c
	pop WA
	jrl NZ, INTRX0_CLEAR_ERROR_STATE
	push XWA
	push XBC
	push XDE
	push XHL
	push XIX
	push XIY
	push XIZ
	ld A, (SC0BUF)
	ld (0x425), 0x0
	dec 2, XSP
	ld (XSP), A
	lda XWA, XSP
	push XWA
	ld WA, 1
	push WA
	call LABEL_FDB7DC
	inc 8, XSP
	pop XIZ
	pop XIY
	pop XIX
	pop XHL
	pop XDE
	pop XBC
	pop XWA
	reti

MIDI_RX_BYTE_DISPATCHER:
	ld (0xB7DF), A
	push XWA
	push XBC
	push XDE
	push XHL
	push XIX
	push XIY
	push XIZ
	CALR MIDI_RX_CONTEXT_RESTORE
	ld A, (0xB7DF)
	bit 0x7, A
	jr Z, LABEL_FCF289
	cp A, 0xf7
	jr ULE, LABEL_FCF245
	CALR MIDI_SYSTEM_MESSAGE_HANDLER
	jr LABEL_FCF28C

LABEL_FCF245:
	ld (0x423), A
	and (0x427), 0xbd
	bit 0, (0x432)
	jr Z, LABEL_FCF28C
	bit 1, (0x432)
	jr Z, LABEL_FCF271
	cp A, 0xf7
	jr NZ, LABEL_FCF27D
	bit 5, (0x432)
	jr NZ, LABEL_FCF271
	push WA
	call LABEL_EF28C9
	inc 2, XSP
	ld (0x432), 0x4

LABEL_FCF271:
	ld (0x423), 0x0
	and (0x432), 0xcc
	jr LABEL_FCF28C

LABEL_FCF27D:
	ld (0x432), 0x10
	ld (0x423), 0x0
	jr LABEL_FCF28C

LABEL_FCF289:
	CALR MIDI_CHANNEL_MESSAGE_DISPATCHER

LABEL_FCF28C:
	CALR MIDI_RX_CONTEXT_SAVE
	pop XIZ
	pop XIY
	pop XIX
	pop XHL
	pop XDE
	pop XBC
	pop XWA
	ret

MIDI_SYSTEM_MESSAGE_HANDLER:
	cp A, 0xfe
	jr NZ, LABEL_FCF2A1
	set 7, (0x427)

LABEL_FCF2A0:
	ret

LABEL_FCF2A1:
	bit 4, (0xFD50)
	jr NZ, LABEL_FCF2A0
	cp A, 0xfd
	jr NC, LABEL_FCF2A0
	bit 6, (0xB7E2)
	jr NZ, LABEL_FCF2A0
	cp (0x7F0B), 0x0
	jr Z, LABEL_FCF2CC
	cp A, 0xfa
	jr NZ, LABEL_FCF2C3
	call LABEL_F71E36
	ret

LABEL_FCF2C3:
	cp A, 0xfc
	jr NZ, LABEL_FCF2CC
	set 0, (0x7F35)

LABEL_FCF2CC:
	ld D, A
	bit 2, (0xFD50)
	jrl Z, LABEL_FCF5F9
	cp D, 0xf8
	jr NZ, LABEL_FCF342
	bit 5, (0x28AC)
	jr Z, LABEL_FCF2E4
	inc 1, (0x454)

LABEL_FCF2E4:
	ld A, (0x42A)
	cp A, 0x70
	jr UGT, LABEL_FCF301
	cp A, 4
	jr UGT, LABEL_FCF2F7
	ld WA, (0xB7D8)
	jr LABEL_FCF305

LABEL_FCF2F7:
	extz XWA
	xor W, W
	muls XWA, (0xB7DA)
	jr LABEL_FCF305

LABEL_FCF301:
	ld WA, (0xB7D6)

LABEL_FCF305:
	.byte 0xF1, 0x92, 0x0, 0x50	; LD (TREG5L), WA
	ld (0x42A), 0x0
	bit 0, (0x41F)
	jr Z, LABEL_FCF319
	ld (0x41F), 0x6

LABEL_FCF319:
	bit 2, (0x41F)
	jr Z, LABEL_FCF342
	and (0x46A), 0xfc
	inc 4, (0x46A)
	cp (0x46A), 0x60
	jr NZ, LABEL_FCF342
	ld (0x46A), 0x0
	INCW 1, (0x468)
	cp (0x7F0B), 0x0
	jr Z, LABEL_FCF342
	CALR MIDI_QUEUE_TRACK_EVENT

LABEL_FCF342:
	ld A, (0x420)
	push WA
	and A, 0x5
	pop WA
	jrl Z, LABEL_FCF4DF
	cp D, 0xf8
	jrl NZ, LABEL_FCF48F
	bit 0x0, A
	jr Z, LABEL_FCF377
	ld (0x420), 0x6
	bit 0, (0x41E)
	jr Z, LABEL_FCF369
	ld (0x41E), 0x6

LABEL_FCF369:
	bit 0, (0x421)
	jr Z, LABEL_FCF374
	ld (0x421), 0x6

LABEL_FCF374:
	jrl LABEL_FCF48F

LABEL_FCF377:
	bit 0x2, A
	jr Z, LABEL_FCF395
	and (0x417), 0xfc
	inc 4, (0x417)
	cp (0x417), 0x60
	jr NZ, LABEL_FCF395
	ld (0x417), 0x0
	INCW 1, (0x418)

LABEL_FCF395:
	bit 2, (0x41E)
	jr Z, LABEL_FCF3EC
	and (0x415), 0xfc
	inc 4, (0x415)
	cp (0x415), 0x60
	jr NZ, LABEL_FCF3EC
	ld (0x415), 0x0
	inc 1, (0x416)
	ld A, (0x379B)
	and A, 0x1f
	jr Z, LABEL_FCF3C0
	CALR MIDI_QUEUE_TRACK_EVENT

LABEL_FCF3C0:
	ld A, (0x416)
	ld W, (0x433)
	ex (0x458), W
	cp A, W
	jr C, LABEL_FCF3EC
	ld (0x416), 0x0
	inc 1, (0x434)
	inc 1, (0x435)
	ld A, (0x435)
	cp A, (0x34D7)
	jr ULE, LABEL_FCF3EC
	ld (0x435), 0x0

LABEL_FCF3EC:
	ld A, (0x415)
	ld W, A
	sub A, (0x457)
	jr Z, LABEL_FCF41D
	jr UGT, LABEL_FCF3FD
	add A, 0x60

LABEL_FCF3FD:
	ld (0x457), W
	add (0x464), A
	add (0x462), A
	xor W, W
	add WA, (0x460)
	cp A, 0x60
	jr C, LABEL_FCF419
	sub A, 0x60
	inc 1, W

LABEL_FCF419:
	ld (0x460), WA

LABEL_FCF41D:
	bit 2, (0x421)
	jr Z, LABEL_FCF48F
	and (0x41B), 0xfc
	inc 4, (0x41B)
	ld A, (0x41B)
	bit 0, (0x431)
	jr Z, LABEL_FCF452
	cp A, (0x42F)
	jr NZ, LABEL_FCF452
	res 0, (0x431)
	ld (0x41E), 0x1
	cpw (0x28AA), 0x0
	jr Z, LABEL_FCF452
	LD_A 0x85
	CALR MIDI_QUEUE_EVENT_PAIR

LABEL_FCF452:
	bit 3, (0x431)
	jr Z, LABEL_FCF474
	cp A, (0x430)
	jr NZ, LABEL_FCF474
	res 3, (0x431)
	ld (0x41E), 0x8
	cpw (0x28AA), 0x0
	jr Z, LABEL_FCF474
	LD_A 0x86
	CALR MIDI_QUEUE_EVENT_PAIR

LABEL_FCF474:
	cp (0x41B), 0x60
	jr NZ, LABEL_FCF4DE
	ld (0x41B), 0x0
	INCW 1, (0x41C)
	cpw (0x28AA), 0x0
	jr Z, LABEL_FCF48F
	CALR MIDI_QUEUE_TRACK_EVENT

LABEL_FCF48F:
	bit 2, (0xFD52)
	jr Z, LABEL_FCF4DE
	cp D, 0xfc
	jr NZ, LABEL_FCF4DE
	ld (0x420), 0x10
	bit 2, (0x41E)
	jr Z, LABEL_FCF4C1
	bit 2, (0x421)
	jr Z, LABEL_FCF4AF
	set 2, (0x347A)

LABEL_FCF4AF:
	ld (0x41E), 0x10
	cpw (0x28AA), 0x0
	jr Z, LABEL_FCF4C1
	LD_A 0x86
	CALR MIDI_QUEUE_EVENT_PAIR

LABEL_FCF4C1:
	bit 2, (0x421)
	jr Z, LABEL_FCF4DE
	ld (0x421), 0x10
	push WA
	ld A, (0x415)
	ld (0x436), A
	ld A, (0x416)
	ld (0x437), A
	pop WA

LABEL_FCF4DE:
	ret

LABEL_FCF4DF:
	bit 2, (0xFD52)
	jr Z, LABEL_FCF4C1
	bit 2, (0x28A7)
	jr NZ, LABEL_FCF4F6
	cp D, 0xfa
	jr Z, LABEL_FCF50A
	cp D, 0xfb
	jrl Z, LABEL_FCF5BE

LABEL_FCF4F6:
	ret

MIDI_START_PLAYBACK_REQUEST:
	cpw (0xF19E), 0x0
	jr Z, LABEL_FCF509
	push SR
	ei 0x6
	CALR MIDI_RESET_PLAYBACK_STATE
	CALR MIDI_APPLY_STARTUP_TIMING
	pop SR

LABEL_FCF509:
	ret

LABEL_FCF50A:
	set 5, (0x28AC)
	ld (0x454), 0x0
	cpw (0xF19E), 0x0
	jr NZ, LABEL_FCF56B

MIDI_RESET_PLAYBACK_STATE:
	xor WA, WA
	ld (0x417), A
	ld (0x418), WA
	ld (0x420), 0x1
	bit 1, (0x28A7)
	jr Z, LABEL_FCF556
	ld (0x415), A
	ld (0x416), A
	ld (0x434), A
	ld (0x435), A
	ld (0x41E), 0x1
	res 0, (0x28A6)
	cpw (0x28AA), 0x0
	jr Z, LABEL_FCF556
	LD_A 0x85
	CALR MIDI_QUEUE_EVENT_PAIR

LABEL_FCF556:
	bit 0, (0x28A7)
	jr Z, LABEL_FCF56B
	xor WA, WA
	ld (0x41B), A
	ld (0x41C), WA
	ld (0x421), 0x1

LABEL_FCF56B:
	ret

MIDI_APPLY_STARTUP_TIMING:
	cp (0x454), 0x0
	jr Z, LABEL_FCF5B8
	bit 0, (0x420)
	jr Z, LABEL_FCF5B8
	ld (0x420), 0x6
	ld A, (0x454)
	dec 1, A
	sll A, 2
	add (0x417), A
	bit 0, (0x41F)
	jr Z, LABEL_FCF59A
	ld (0x41F), 0x6
	add (0x46A), A

LABEL_FCF59A:
	bit 0, (0x41E)
	jr Z, LABEL_FCF5A9
	ld (0x41E), 0x6
	add (0x415), A

LABEL_FCF5A9:
	bit 0, (0x421)
	jr Z, LABEL_FCF5B8
	ld (0x421), 0x6
	add (0x41B), A

LABEL_FCF5B8:
	ld (0x454), 0x0
	ret

LABEL_FCF5BE:
	ld (0x420), 0x6
	bit 0, (0x28A7)
	jr Z, LABEL_FCF5F8
	ld (0x421), 0x6
	bit 1, (0x28A7)
	jr Z, LABEL_FCF5F8
	bit 0, (0x28A6)
	jr NZ, LABEL_FCF5E4
	ld (0x415), 0x0
	ld (0x416), 0x0

LABEL_FCF5E4:
	ld (0x434), 0x0
	ld (0x435), 0x0
	and (0x28A6), 0xfe
	ld (0x41E), 0x6

LABEL_FCF5F8:
	ret

LABEL_FCF5F9:
	ld (0x42A), 0x0
	push WA
	ld A, (0x420)
	and A, 0x5
	pop WA
	jr Z, LABEL_FCF659
	bit 2, (0xFD52)
	jr Z, LABEL_FCF658
	cp D, 0xfc
	jr NZ, LABEL_FCF658
	ld (0x420), 0xc
	bit 2, (0x41E)
	jr Z, LABEL_FCF63B
	bit 2, (0x421)
	jr Z, LABEL_FCF629
	set 2, (0x347A)

LABEL_FCF629:
	ld (0x41E), 0xc
	cpw (0x28AA), 0x0
	jr Z, LABEL_FCF63B
	LD_A 0x86
	CALR MIDI_QUEUE_EVENT_PAIR

LABEL_FCF63B:
	bit 2, (0x421)
	jr Z, LABEL_FCF658
	ld (0x421), 0xc
	push WA
	ld A, (0x415)
	ld (0x436), A
	ld A, (0x416)
	ld (0x437), A
	pop WA

LABEL_FCF658:
	ret

LABEL_FCF659:
	bit 2, (0xFD52)
	jr Z, LABEL_FCF66F
	bit 2, (0x28A7)
	jr NZ, LABEL_FCF66F
	cp D, 0xfa
	jr Z, LABEL_FCF670
	cp D, 0xfb
	jr Z, LABEL_FCF67C

LABEL_FCF66F:
	ret

LABEL_FCF670:
	set 1, (0x429)
	ld (INTES0), 0xdd
	jrl LABEL_FCF50A

LABEL_FCF67C:
	bit 0, (0x28A7)
	jr Z, LABEL_FCF68E
	set 2, (0x429)
	ld (INTES0), 0xdd
	jrl LABEL_FCF5BE

LABEL_FCF68E:
	ret

MIDI_QUEUE_TRACK_EVENT:
	bit 0, (0x459)
	jr NZ, LABEL_FCF6BF
	push WA
	ld XIX, 0x1e753
	ld WA, (XIX - 2)
	and WA, WA
	jr Z, LABEL_FCF6B7
	ld HL, (XIX - 4)
	ld (XIX + HL), 0x81
	minc1 0x800, HL
	dec 1, WA
	ld (XIX - 4), HL
	ld (XIX - 2), WA

LABEL_FCF6B7:
	pop WA
	ldw (0x475), 0x0
	ret

LABEL_FCF6BF:
	ld XIX, 0x477
	ld HL, (0x475)
	ld (XIX + HL), 0x81
	inc 1, HL
	ld (0x475), HL
	ret

MIDI_QUEUE_EVENT_PAIR:
	bit 0, (0x459)
	jr NZ, LABEL_FCF713
	cpw (0x1E751), 0x2
	jr C, LABEL_FCF70C
	push SR
	ei 0x6
	ld XIX, 0x1e753
	ld HL, (XIX - 4)
	ld (XIX + HL), A
	minc1 0x800, HL
	ld A, (0x41B)
	ld (XIX + HL), A
	minc1 0x800, HL
	ld (XIX - 4), HL
	DECW 2, (XIX - 2)
	pop SR

LABEL_FCF70C:
	ldw (0x475), 0x0
	ret

LABEL_FCF713:
	ld XIX, 0x477
	ld HL, (0x475)
	ld (XIX + HL), A
	inc 1, HL
	ld A, (0x41B)
	ld (XIX + HL), A
	inc 1, HL
	ld (0x475), HL
	ret

MIDI_CHANNEL_MESSAGE_DISPATCHER:
	ld E, A
	ld A, (0x423)
	ld D, A
	bit 0, (0x432)
	jrl NZ, LABEL_FCF849
	bit 6, (0x427)
	jr NZ, LABEL_FCF7AF
	cp A, 0
	jr Z, LABEL_FCF781
	and A, 0x70
	srl A, 2
	xor W, W
	ld XIX, 0xfcf761
	ld XIX, (XIX + WA)
	jp XIX
MIDI_CHANNEL_HANDLER_JUMP_TABLE:
	.byte 0xFF, 0xA8, 0xF7, 0xFC, 0x0, 0xA8, 0xF7, 0xFC
	.byte 0x0, 0x81, 0xF7, 0xFC, 0x0, 0xA8, 0xF7, 0xFC
	.byte 0x0, 0x82, 0xF7, 0xFC, 0x0, 0x82, 0xF7, 0xFC
	.byte 0x0, 0xA8, 0xF7, 0xFC, 0x0, 0x0, 0xF8, 0xFC
	.byte 0x0

LABEL_FCF781:
	ret

MIDI_QUEUE_EVENT_TO_SEQUENCER:
	ld XIX, 0x1f37b
	cpw (XIX - 2), 0x3
	jr C, LABEL_FCF79F
	ld A, D
	push WA
	call SeqMain_WriteByte
	inc 2, XSP
	push DE
	call SeqMain_WriteByte
	inc 2, XSP
	ret

LABEL_FCF79F:
	set 2, (0x427)
	inc 1, (0xB7DD)
	ret

LABEL_FCF7A8:
	set 6, (0x427)
	ld C, E
	ret

LABEL_FCF7AF:
	bit 1, (0x427)
	jr Z, LABEL_FCF7B7
	LD_D 0xf2

LABEL_FCF7B7:
	ld XIX, 0x1f37b
	cpw (XIX - 2), 0x40
	jr UGT, LABEL_FCF7D1
	push DE
	and D, 0xf0
	cp D, 0x90
	pop DE
	jr NZ, LABEL_FCF7D1
	cp E, 0
	jr NZ, LABEL_FCF7F6

LABEL_FCF7D1:
	cpw (XIX - 2), 0x4
	jr C, LABEL_FCF7F7
	ld A, D
	push WA
	call SeqMain_WriteByte
	inc 2, XSP
	ld A, C
	push WA
	call SeqMain_WriteByte
	inc 2, XSP
	push DE
	call SeqMain_WriteByte
	inc 2, XSP
	and (0x427), 0xbd

LABEL_FCF7F6:
	ret

LABEL_FCF7F7:
	set 2, (0x427)
	inc 1, (0xB7DD)
	ret

MIDI_SYSTEM_EXCLUSIVE_HANDLER:
	ld (0x423), 0x0
	cp D, 0xf0
	jr Z, LABEL_FCF820
	cp D, 0xf2
	jr Z, LABEL_FCF815
	cp D, 0xf3
	jr Z, LABEL_FCF81D
	ret

LABEL_FCF815:
	or (0x427), 0x42
	ld C, E
	ret

LABEL_FCF81D:
	jrl MIDI_QUEUE_EVENT_TO_SEQUENCER

LABEL_FCF820:
	ld (0x432), 0x1
	cp E, 0x50
	jr Z, LABEL_FCF834
	cp E, 0x41
	jr Z, LABEL_FCF834
	cp E, 0x7e
	jr NZ, LABEL_FCF848

LABEL_FCF834:
	set 1, (0x432)
	ld A, D
	push WA
	call LABEL_EF28C9
	inc 2, XSP
	push DE
	call LABEL_EF28C9
	inc 2, XSP

LABEL_FCF848:
	ret

LABEL_FCF849:
	bit 1, (0x432)
	jr Z, LABEL_FCF85C
	bit 5, (0x432)
	jr NZ, LABEL_FCF85C
	push DE
	call LABEL_EF28C9
	inc 2, XSP

LABEL_FCF85C:
	ret

MIDI_RX_CONTEXT_RESTORE:
	ld XWA, (0x438)
	ld XBC, (0x43C)
	ld XDE, (0x440)
	ld XHL, (0x444)
	ld XIX, (0x448)
	ld XIY, (0x44C)
	ld XIZ, (0x450)
	ret

MIDI_RX_CONTEXT_SAVE:
	ld (0x438), XWA
	ld (0x43C), XBC
	ld (0x440), XDE
	ld (0x444), XHL
	ld (0x448), XIX
	ld (0x44C), XIY
	ld (0x450), XIZ
	ret

LABEL_FCF897:
	res 0, (0xB7E7)
	ld (0xB7E1), 0x0
	CALR LABEL_FCF91C
	CALR LABEL_FCF8B1
	CALR READ_COM_SELECT_SWITCH
	call LABEL_FDBA02
	CALR LABEL_FCF940
	ret

LABEL_FCF8B1:
	call Get_Region_Code
	cp L, 4
	jr Z, LABEL_FCF8D8
	ldw (0xB7D4), 0x7a12
	ldw (0xB7D6), 0x28b0
	ldw (0xB7D8), 0x1046
	ldw (0xB7DA), 0x3e8
	ld (0xB7DC), 0x8	; BR0CR: clk=fc/4/8 = 500kHz (baudrate for MIDI ?!)
	jr LABEL_FCF8F5

LABEL_FCF8D8:
	ldw (0xB7D4), 0x5b8d
	ldw (0xB7D6), 0x1e84
	ldw (0xB7D8), 0xc35
	ldw (0xB7DA), 0x2ee
	ld (0xB7DC), 0x6	; BR0CR: clk=fc/4/6 = 666.6kHz (baudrate for MIDI ?!)

LABEL_FCF8F5:
	ret

READ_COM_SELECT_SWITCH:	; FCF8F6
	ld A, (PZ)
	srl A, 4
	ld XIX, OFFSETS_FCF90C
	ld A, (XIX + A)
	ld (COM_SELECT), A
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
	.byte 0x0
	.byte 0x0
	.byte 0x0
	.byte 0x0
	.byte 0x0
	.byte 0x0
	.byte 0x0
	.byte 0x0	; MIDI
	.byte 0x0
	.byte 0x0
	.byte 0x0
	.byte 0x1	; MAC
	.byte 0x0
	.byte 0x2	; PC1
	.byte 0x3	; PC2
	.byte 0x0

LABEL_FCF91C:
	ld (0x438), 0x0
	ld (0x43C), 0x0
	ld (0x440), 0x0
	ld (0x444), 0x0
	ld (0x448), 0x0
	ld (0x44C), 0x0
	ld (0x450), 0x0
	ret

LABEL_FCF940:
	ei 0x6
	ld (SC0MOD), 0x29
	ld (SC0CR), 0x0
	ld A, (0xB7DC)
	ld (BR0CR), A
	ld (INTES0), 0x5d
	ld (SC0BUF), 0xfe
	ei 0x0
	ret

LABEL_FCF961:
	ret

LABEL_FCF962:
	.byte 0x97, 0xF8, 0xFC, 0x0, 0x61, 0xF9, 0xFC, 0x0
	.byte 0x61, 0xF9, 0xFC, 0x0, 0x61, 0xF9, 0xFC, 0x0

LABEL_FCF972:
	push XWA
	push XBC
	push XDE
	push XHL
	push XIX
	push XIY
	push XIZ
	cp (COM_SELECT), 0x0	; 000h means MIDI
	jr NZ, LABEL_FCF985
	CALR LABEL_FCF991
	jr LABEL_FCF989

LABEL_FCF985:
	call LABEL_FDB903

LABEL_FCF989:
	pop XIZ
	pop XIY
	pop XIX
	pop XHL
	pop XDE
	pop XBC
	pop XWA
	ret

LABEL_FCF991:
	push SR
	ei 0x6
	cp (0x474), 0x55
	jr Z, LABEL_FCF9A2
	ld (INTES0), 0xdd
	jr LABEL_FCF9AB

LABEL_FCF9A2:
	call LABEL_EF286B
	ld (0x429), 0x0

LABEL_FCF9AB:
	pop SR
	ret

; End of MIDI Serial routines

