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
	cp xbc, EVT_ACTIVATE_STATE
	jr nz, DemoModeFunc_Exit
	cp xde, 0x1
	jr z, DemoModeFunc_Initialize
	or xde, xde
	jr nz, DemoModeFunc_Exit
	push xde
	push xhl
	push xix
	push xiz
	call DemoMode_Main_Operation
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
	call DemoMode_Initialize
	pop xiz
	pop xix
	pop xhl
	pop xde

DemoModeFunc_Exit:
	ld xhl, 0:i3
	ret

DemoMenuTtlFunc:
	ld xhl, 0:i3
	ret

DemoStyleTtlFunc:
	cp xbc, EVT_SW_IN
	jr z, DemoStyle_InputHandler
	cp xbc, EVT_ACTIVATE_STATE
	jrl nz, DemoStyleTtlFunc_Exit
	dec 2, xde
	cp xde, 0x0
	jrl c, DemoStyleTtlFunc_Exit
	cp xde, 0x5
	jrl ugt, DemoStyleTtlFunc_Exit
	add xde, xde
	add xde, DemoStyleTtlFunc_Data
	ld de, (xde)
	lda xix, (DemoStyle_DispatchTable:24)
	jp	t, (xix+de)
DemoStyle_DispatchTable:
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	FDemo_IndicatorSetup
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	jrl	DemoStyleTtlFunc_Exit

DemoStyle_InputHandler:
	cp xde, 0xf
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
	cpw (0x28b4:16), 0
	jr nz, DemoStyleTtlFunc_Exit
	cp (3375:16), 0
	jr nz, DemoStyleTtlFunc_Exit
	ldw wa, 0xe2
	jr DemoStyle_PostEventCommon

DemoStyle_DirectionHandler:
	cpw (0x28b4:16), 0
	jr nz, DemoStyleTtlFunc_Exit
	cp (3375:16), 0
	jr nz, DemoStyleTtlFunc_Exit
	ldw wa, 0xe3

DemoStyle_PostEventCommon:
	call UI_PostModeChangeEvent
	jr DemoStyleTtlFunc_Exit

DemoStyle_EnterHandler:
	push xde
	push xhl
	push xix
	push xiz
	call Demo_SelectionEntryHandler
	pop xiz
	pop xix
	pop xhl
	pop xde

DemoStyleTtlFunc_Exit:
	ld xhl, 0:i3
	ret

DemoSoundTtlFunc:
	cp xbc, EVT_SW_IN
	jr z, DemoSound_InputHandler
	cp xbc, EVT_ACTIVATE_STATE
	jrl nz, DemoSoundTtlFunc_Exit
	dec 2, xde
	cp xde, 0x0
	jrl c, DemoSoundTtlFunc_Exit
	cp xde, 0x5
	jrl ugt, DemoSoundTtlFunc_Exit
	add xde, xde
	add xde, DemoSoundTtlFunc_Data
	ld de, (xde)
	lda xix, (DemoSound_DispatchTable:24)
	jp	t, (xix+de)
DemoSound_DispatchTable:
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	FDemo_IndicatorSetup
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	jr	DemoSoundTtlFunc_Exit

DemoSound_InputHandler:
	cp xde, 0xf
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
	cpw (0x28b4:16), 0
	jr nz, DemoSoundTtlFunc_Exit
	cp (3375:16), 0
	jr nz, DemoSoundTtlFunc_Exit
	ldw wa, 0xe1
	jr DemoSound_PostEventCommon

DemoSound_DirectionHandler:
	cpw (0x28b4:16), 0
	jr nz, DemoSoundTtlFunc_Exit
	cp (3375:16), 0
	jr nz, DemoSoundTtlFunc_Exit
	ldw wa, 0xe3

DemoSound_PostEventCommon:
	call UI_PostModeChangeEvent
	jr DemoSoundTtlFunc_Exit

DemoSound_EnterHandler:
	push xde
	push xhl
	push xix
	push xiz
	call Demo_SelectionEntryHandler
	pop xiz
	pop xix
	pop xhl
	pop xde

DemoSoundTtlFunc_Exit:
	ld xhl, 0:i3
	ret

DemoRhyTtlFunc:
	cp xbc, EVT_SW_IN
	jr z, DemoRhythm_InputHandler
	cp xbc, EVT_ACTIVATE_STATE
	jrl nz, DemoRhyTtlFunc_Exit
	dec 2, xde
	cp xde, 0x0
	jrl c, DemoRhyTtlFunc_Exit
	cp xde, 0x5
	jrl ugt, DemoRhyTtlFunc_Exit
	add xde, xde
	add xde, DemoRhyTtlFunc_Data
	ld de, (xde)
	lda xix, (DemoRhythm_DispatchTable:24)
	jp	t, (xix+de)
DemoRhythm_DispatchTable:
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	FDemo_IndicatorSetup
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	jr	DemoRhyTtlFunc_Exit

DemoRhythm_InputHandler:
	cp xde, 0xf
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
	cpw (0x28b4:16), 0
	jr nz, DemoRhyTtlFunc_Exit
	cp (3375:16), 0
	jr nz, DemoRhyTtlFunc_Exit
	ldw wa, 0xe1
	jr DemoRhythm_PostEventCommon

DemoRhythm_DirectionHandler:
	cpw (0x28b4:16), 0
	jr nz, DemoRhyTtlFunc_Exit
	cp (3375:16), 0
	jr nz, DemoRhyTtlFunc_Exit
	ldw wa, 0xe2

DemoRhythm_PostEventCommon:
	call UI_PostModeChangeEvent
	jr DemoRhyTtlFunc_Exit

DemoRhythm_EnterHandler:
	push xde
	push xhl
	push xix
	push xiz
	call Demo_SelectionEntryHandler
	pop xiz
	pop xix
	pop xhl
	pop xde

DemoRhyTtlFunc_Exit:
	ld xhl, 0:i3
	ret

; End of Feature Demo routines
