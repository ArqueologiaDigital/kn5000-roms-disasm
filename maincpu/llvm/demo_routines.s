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
	cp XBC, 0x1c00013
	jr NZ, DemoModeFunc_Exit
	cp XDE, 0x1
	jr Z, DemoModeFunc_Initialize
	or XDE, XDE
	jr NZ, DemoModeFunc_Exit
	push XDE
	push XHL
	push XIX
	push XIZ
	call DemoMode_Main_Operation
	pop XIZ
	pop XIX
	pop XHL
	pop XDE
	jr DemoModeFunc_Exit

DemoModeFunc_Initialize:
	push XDE
	push XHL
	push XIX
	push XIZ
	call DemoMode_Initialize
	pop XIZ
	pop XIX
	pop XHL
	pop XDE

DemoModeFunc_Exit:
	ld XHL, 0
	ret

DemoMenuTtlFunc:
	ld XHL, 0
	ret

DemoStyleTtlFunc:
	cp XBC, 0x1c00007
	jr Z, DemoStyle_InputHandler
	cp XBC, 0x1c00013
	jrl NZ, DemoStyleTtlFunc_Exit
	dec 2, XDE
	cp XDE, 0x0
	jrl C, DemoStyleTtlFunc_Exit
	cp XDE, 0x5
	jrl UGT, DemoStyleTtlFunc_Exit
	add XDE, XDE
	add XDE, 0xe201c4
	ld DE, (XDE)
	lda XIX, 0xF22339
	jp XIX + DE
DemoStyle_DispatchTable:
	.byte 0x3A, 0x3B, 0x3C, 0x3E, 0x1D, 0xD2, 0x69, 0xF8
	.byte 0x5E, 0x5C, 0x5B, 0x5A, 0x78, 0x80, 0x0

DemoStyle_InputHandler:
	cp XDE, 0xf
	jr Z, DemoStyle_EnterHandler
	cp XDE, 0x87
	jr Z, DemoStyle_DirectionHandler
	cp XDE, 0x7
	jr Z, DemoStyle_DirectionHandler
	cp XDE, 0x86
	jr Z, DemoStyle_DirectionHandler
	cp XDE, 0x6
	jr Z, DemoStyle_DirectionHandler
	cp XDE, 0x84
	jr Z, DemoStyle_EncoderHandler
	cp XDE, 0x4
	jr Z, DemoStyle_EncoderHandler
	cp XDE, 0x83
	jr Z, DemoStyle_EncoderHandler
	cp XDE, 0x3
	jr NZ, DemoStyleTtlFunc_Exit

DemoStyle_EncoderHandler:
	cpw (0x28B4), 0x0
	jr NZ, DemoStyleTtlFunc_Exit
	cp (0xD2F), 0x0
	jr NZ, DemoStyleTtlFunc_Exit
	ld WA, 0xe2
	jr DemoStyle_PostEventCommon

DemoStyle_DirectionHandler:
	cpw (0x28B4), 0x0
	jr NZ, DemoStyleTtlFunc_Exit
	cp (0xD2F), 0x0
	jr NZ, DemoStyleTtlFunc_Exit
	ld WA, 0xe3

DemoStyle_PostEventCommon:
	call UI_PostModeChangeEvent
	jr DemoStyleTtlFunc_Exit

DemoStyle_EnterHandler:
	push XDE
	push XHL
	push XIX
	push XIZ
	call Demo_SelectionEntryHandler
	pop XIZ
	pop XIX
	pop XHL
	pop XDE

DemoStyleTtlFunc_Exit:
	ld XHL, 0
	ret

DemoSoundTtlFunc:
	cp XBC, 0x1c00007
	jr Z, DemoSound_InputHandler
	cp XBC, 0x1c00013
	jrl NZ, DemoSoundTtlFunc_Exit
	dec 2, XDE
	cp XDE, 0x0
	jrl C, DemoSoundTtlFunc_Exit
	cp XDE, 0x5
	jrl UGT, DemoSoundTtlFunc_Exit
	add XDE, XDE
	add XDE, 0xe201d0
	ld DE, (XDE)
	lda XIX, 0xF22404
	jp XIX + DE
DemoSound_DispatchTable:
	.byte 0x3A, 0x3B, 0x3C, 0x3E, 0x1D, 0xD2, 0x69, 0xF8
	.ascii "^"
	.byte 0x5C
	.ascii "[Zh|"

DemoSound_InputHandler:
	cp XDE, 0xf
	jr Z, DemoSound_EnterHandler
	cp XDE, 0x87
	jr Z, DemoSound_DirectionHandler
	cp XDE, 0x7
	jr Z, DemoSound_DirectionHandler
	cp XDE, 0x86
	jr Z, DemoSound_DirectionHandler
	cp XDE, 0x6
	jr Z, DemoSound_DirectionHandler
	cp XDE, 0x81
	jr Z, DemoSound_EncoderHandler
	cp XDE, 0x1
	jr Z, DemoSound_EncoderHandler
	cp XDE, 0x80
	jr Z, DemoSound_EncoderHandler
	or XDE, XDE
	jr NZ, DemoSoundTtlFunc_Exit

DemoSound_EncoderHandler:
	cpw (0x28B4), 0x0
	jr NZ, DemoSoundTtlFunc_Exit
	cp (0xD2F), 0x0
	jr NZ, DemoSoundTtlFunc_Exit
	ld WA, 0xe1
	jr DemoSound_PostEventCommon

DemoSound_DirectionHandler:
	cpw (0x28B4), 0x0
	jr NZ, DemoSoundTtlFunc_Exit
	cp (0xD2F), 0x0
	jr NZ, DemoSoundTtlFunc_Exit
	ld WA, 0xe3

DemoSound_PostEventCommon:
	call UI_PostModeChangeEvent
	jr DemoSoundTtlFunc_Exit

DemoSound_EnterHandler:
	push XDE
	push XHL
	push XIX
	push XIZ
	call Demo_SelectionEntryHandler
	pop XIZ
	pop XIX
	pop XHL
	pop XDE

DemoSoundTtlFunc_Exit:
	ld XHL, 0
	ret

DemoRhyTtlFunc:
	cp XBC, 0x1c00007
	jr Z, DemoRhythm_InputHandler
	cp XBC, 0x1c00013
	jrl NZ, DemoRhyTtlFunc_Exit
	dec 2, XDE
	cp XDE, 0x0
	jrl C, DemoRhyTtlFunc_Exit
	cp XDE, 0x5
	jrl UGT, DemoRhyTtlFunc_Exit
	add XDE, XDE
	add XDE, 0xe201dc
	ld DE, (XDE)
	lda XIX, 0xF224CA
	jp XIX + DE
DemoRhythm_DispatchTable:
	.byte 0x3A, 0x3B, 0x3C, 0x3E, 0x1D, 0xD2, 0x69, 0xF8
	.ascii "^"
	.byte 0x5C
	.ascii "[Zh|"

DemoRhythm_InputHandler:
	cp XDE, 0xf
	jr Z, DemoRhythm_EnterHandler
	cp XDE, 0x84
	jr Z, DemoRhythm_DirectionHandler
	cp XDE, 0x4
	jr Z, DemoRhythm_DirectionHandler
	cp XDE, 0x83
	jr Z, DemoRhythm_DirectionHandler
	cp XDE, 0x3
	jr Z, DemoRhythm_DirectionHandler
	cp XDE, 0x81
	jr Z, DemoRhythm_EncoderHandler
	cp XDE, 0x1
	jr Z, DemoRhythm_EncoderHandler
	cp XDE, 0x80
	jr Z, DemoRhythm_EncoderHandler
	or XDE, XDE
	jr NZ, DemoRhyTtlFunc_Exit

DemoRhythm_EncoderHandler:
	cpw (0x28B4), 0x0
	jr NZ, DemoRhyTtlFunc_Exit
	cp (0xD2F), 0x0
	jr NZ, DemoRhyTtlFunc_Exit
	ld WA, 0xe1
	jr DemoRhythm_PostEventCommon

DemoRhythm_DirectionHandler:
	cpw (0x28B4), 0x0
	jr NZ, DemoRhyTtlFunc_Exit
	cp (0xD2F), 0x0
	jr NZ, DemoRhyTtlFunc_Exit
	ld WA, 0xe2

DemoRhythm_PostEventCommon:
	call UI_PostModeChangeEvent
	jr DemoRhyTtlFunc_Exit

DemoRhythm_EnterHandler:
	push XDE
	push XHL
	push XIX
	push XIZ
	call Demo_SelectionEntryHandler
	pop XIZ
	pop XIX
	pop XHL
	pop XDE

DemoRhyTtlFunc_Exit:
	ld XHL, 0
	ret

; End of Feature Demo routines
