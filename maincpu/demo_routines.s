; =============================================================================
; demo_routines.asm - Feature Demo Mode Routines
; =============================================================================
; This file contains the main Feature Demo mode handler routines for the
; KN5000 Main CPU.
;
; The Feature Demo is an automated presentation that showcases the KN5000's
; capabilities. It displays bitmap images (FTBMP01-06) and plays demo songs
; highlighting different aspects of the keyboard:
;   - Technics globe logo
;   - Subwoofer/speaker system
;   - Floppy disk functionality
;   - Surround sound arrows
;   - KN5000 name with rainbow effect
;
; Routines included:
;   DemoModeFunc      - Main demo mode handler
;   DemoMenuTtlFunc   - Demo menu title handler
;   DemoStyleTtlFunc  - Demo style selection title handler
;   DemoSoundTtlFunc  - Demo sound selection title handler
;   DemoRhyTtlFunc    - Demo rhythm selection title handler
;
; Note: Additional Demo-related functions exist elsewhere in the ROM:
;   - AcDemoSongBoxProc        (line ~194533)
;   - DemoSongSelFunc          (line ~194728)
;   - AcDemoMedleyDispBoxProc  (line ~195115)
;   - IvDemofeature1Proc       (line ~310702)
;   - IvDemofeature2Proc       (line ~310736)
;
; Feature Demo bitmap/filename data is in the data section (lines 36956-42245).
;
; =============================================================================

DemoModeFunc:
	cp xbc, 0x1C00013
	jr nz, DemoModeFunc_Exit
	cp xde, 0x1
	jr z, DemoModeFunc_Initialize
	or xde, xde
	jr nz, DemoModeFunc_Exit
	push xde
	push xhl
	push xix
	push xiz
	call 0xF8696F
	pop xiz
	pop xix
	pop xhl
	pop xde
	jr DemoModeFunc_Exit

DemoModeFunc_Initialize:
	push xde
	push xhl
	push xix
	push xiz
	call 0xF869E3
	pop xiz
	pop xix
	pop xhl
	pop xde

DemoModeFunc_Exit:
	lds32 xhl, 0
	ret

DemoMenuTtlFunc:
	lds32 xhl, 0
	ret

DemoStyleTtlFunc:
	cp xbc, 0x1C00007
	jr z, DemoStyle_InputHandler
	cp xbc, 0x1C00013
	jrl nz, DemoStyleTtlFunc_Exit
	dec 2, xde
	cp xde, 0x0
	jrl c, DemoStyleTtlFunc_Exit
	cp xde, 0x5
	jrl ugt, DemoStyleTtlFunc_Exit
	add xde, xde
	add xde, 0xE201C4
	ld de, (xde)
	lda_24 xix, 0xf22339
	jp_dri 8, 0x07, 0xF0, 0xE8
DemoStyle_DispatchTable:
	.ascii ":;<>"
	.byte 0x1d, 0xd2, 0x69, 0xf8
	.ascii "^\\[Zx"
	.byte 0x80, 0x00

DemoStyle_InputHandler:
	cp xde, 0xF
	jr z, DemoStyle_EnterHandler
	cp xde, 0x87
	jr z, DemoStyle_DirectionHandler
	cp xde, 0x7
	jr z, DemoStyle_DirectionHandler
	cp xde, 0x86
	jr z, DemoStyle_DirectionHandler
	cp xde, 0x6
	jr z, DemoStyle_DirectionHandler
	cp xde, 0x84
	jr z, DemoStyle_EncoderHandler
	cp xde, 0x4
	jr z, DemoStyle_EncoderHandler
	cp xde, 0x83
	jr z, DemoStyle_EncoderHandler
	cp xde, 0x3
	jr nz, DemoStyleTtlFunc_Exit

DemoStyle_EncoderHandler:
	cpdi16 10420, 0
	jr nz, DemoStyleTtlFunc_Exit
	cpdi8 3375, 0
	jr nz, DemoStyleTtlFunc_Exit
	ldw wa, 0xE2
	jr DemoStyle_PostEventCommon

DemoStyle_DirectionHandler:
	cpdi16 10420, 0
	jr nz, DemoStyleTtlFunc_Exit
	cpdi8 3375, 0
	jr nz, DemoStyleTtlFunc_Exit
	ldw wa, 0xE3

DemoStyle_PostEventCommon:
	call 0xF99490
	jr DemoStyleTtlFunc_Exit

DemoStyle_EnterHandler:
	push xde
	push xhl
	push xix
	push xiz
	call 0xF86A47
	pop xiz
	pop xix
	pop xhl
	pop xde

DemoStyleTtlFunc_Exit:
	lds32 xhl, 0
	ret

DemoSoundTtlFunc:
	cp xbc, 0x1C00007
	jr z, DemoSound_InputHandler
	cp xbc, 0x1C00013
	jrl nz, DemoSoundTtlFunc_Exit
	dec 2, xde
	cp xde, 0x0
	jrl c, DemoSoundTtlFunc_Exit
	cp xde, 0x5
	jrl ugt, DemoSoundTtlFunc_Exit
	add xde, xde
	add xde, 0xE201D0
	ld de, (xde)
	lda_24 xix, 0xf22404
	jp_dri 8, 0x07, 0xF0, 0xE8
DemoSound_DispatchTable:
	.ascii ":;<>"
	.byte 0x1d, 0xd2, 0x69, 0xf8
	.ascii "^\\[Zh|"

DemoSound_InputHandler:
	cp xde, 0xF
	jr z, DemoSound_EnterHandler
	cp xde, 0x87
	jr z, DemoSound_DirectionHandler
	cp xde, 0x7
	jr z, DemoSound_DirectionHandler
	cp xde, 0x86
	jr z, DemoSound_DirectionHandler
	cp xde, 0x6
	jr z, DemoSound_DirectionHandler
	cp xde, 0x81
	jr z, DemoSound_EncoderHandler
	cp xde, 0x1
	jr z, DemoSound_EncoderHandler
	cp xde, 0x80
	jr z, DemoSound_EncoderHandler
	or xde, xde
	jr nz, DemoSoundTtlFunc_Exit

DemoSound_EncoderHandler:
	cpdi16 10420, 0
	jr nz, DemoSoundTtlFunc_Exit
	cpdi8 3375, 0
	jr nz, DemoSoundTtlFunc_Exit
	ldw wa, 0xE1
	jr DemoSound_PostEventCommon

DemoSound_DirectionHandler:
	cpdi16 10420, 0
	jr nz, DemoSoundTtlFunc_Exit
	cpdi8 3375, 0
	jr nz, DemoSoundTtlFunc_Exit
	ldw wa, 0xE3

DemoSound_PostEventCommon:
	call 0xF99490
	jr DemoSoundTtlFunc_Exit

DemoSound_EnterHandler:
	push xde
	push xhl
	push xix
	push xiz
	call 0xF86A47
	pop xiz
	pop xix
	pop xhl
	pop xde

DemoSoundTtlFunc_Exit:
	lds32 xhl, 0
	ret

DemoRhyTtlFunc:
	cp xbc, 0x1C00007
	jr z, DemoRhythm_InputHandler
	cp xbc, 0x1C00013
	jrl nz, DemoRhyTtlFunc_Exit
	dec 2, xde
	cp xde, 0x0
	jrl c, DemoRhyTtlFunc_Exit
	cp xde, 0x5
	jrl ugt, DemoRhyTtlFunc_Exit
	add xde, xde
	add xde, 0xE201DC
	ld de, (xde)
	lda_24 xix, 0xf224ca
	jp_dri 8, 0x07, 0xF0, 0xE8
DemoRhythm_DispatchTable:
	.ascii ":;<>"
	.byte 0x1d, 0xd2, 0x69, 0xf8
	.ascii "^\\[Zh|"

DemoRhythm_InputHandler:
	cp xde, 0xF
	jr z, DemoRhythm_EnterHandler
	cp xde, 0x84
	jr z, DemoRhythm_DirectionHandler
	cp xde, 0x4
	jr z, DemoRhythm_DirectionHandler
	cp xde, 0x83
	jr z, DemoRhythm_DirectionHandler
	cp xde, 0x3
	jr z, DemoRhythm_DirectionHandler
	cp xde, 0x81
	jr z, DemoRhythm_EncoderHandler
	cp xde, 0x1
	jr z, DemoRhythm_EncoderHandler
	cp xde, 0x80
	jr z, DemoRhythm_EncoderHandler
	or xde, xde
	jr nz, DemoRhyTtlFunc_Exit

DemoRhythm_EncoderHandler:
	cpdi16 10420, 0
	jr nz, DemoRhyTtlFunc_Exit
	cpdi8 3375, 0
	jr nz, DemoRhyTtlFunc_Exit
	ldw wa, 0xE1
	jr DemoRhythm_PostEventCommon

DemoRhythm_DirectionHandler:
	cpdi16 10420, 0
	jr nz, DemoRhyTtlFunc_Exit
	cpdi8 3375, 0
	jr nz, DemoRhyTtlFunc_Exit
	ldw wa, 0xE2

DemoRhythm_PostEventCommon:
	call 0xF99490
	jr DemoRhyTtlFunc_Exit

DemoRhythm_EnterHandler:
	push xde
	push xhl
	push xix
	push xiz
	call 0xF86A47
	pop xiz
	pop xix
	pop xhl
	pop xde

DemoRhyTtlFunc_Exit:
	lds32 xhl, 0
	ret

; End of Feature Demo routines
