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
	CP XBC, 01c00013h
	JR NZ, DemoModeFunc_Exit
	CP XDE, 00000001h
	JR Z, DemoModeFunc_Initialize
	OR XDE, XDE
	JR NZ, DemoModeFunc_Exit
	PUSH XDE
	PUSH XHL
	PUSH XIX
	PUSH XIZ
	CALL DemoMode_Main_Operation
	POP XIZ
	POP XIX
	POP XHL
	POP XDE
	JR T, DemoModeFunc_Exit

DemoModeFunc_Initialize:
	PUSH XDE
	PUSH XHL
	PUSH XIX
	PUSH XIZ
	CALL DemoMode_Initialize
	POP XIZ
	POP XIX
	POP XHL
	POP XDE

DemoModeFunc_Exit:
	LD XHL, 0
	RET

DemoMenuTtlFunc:
	LD XHL, 0
	RET

DemoStyleTtlFunc:
	CP XBC, 01c00007h
	JR Z, DemoStyle_InputHandler
	CP XBC, 01c00013h
	JRL NZ, DemoStyleTtlFunc_Exit
	DEC 2, XDE
	CP XDE, 00000000h
	JRL C, DemoStyleTtlFunc_Exit
	CP XDE, 00000005h
	JRL UGT, DemoStyleTtlFunc_Exit
	ADD XDE, XDE
	ADD XDE, 00e201c4h
	LD DE, (XDE)
	LDA XIX, 0F22339h
	JP T, XIX + DE
DemoStyle_DispatchTable:
	db 03Ah, 03Bh, 03Ch, 03Eh, 01Dh, 0D2h, 069h, 0F8h
	db 05Eh, 05Ch, 05Bh, 05Ah, 078h, 080h, 000h

DemoStyle_InputHandler:
	CP XDE, 0000000fh
	JR Z, DemoStyle_EnterHandler
	CP XDE, 00000087h
	JR Z, DemoStyle_DirectionHandler
	CP XDE, 00000007h
	JR Z, DemoStyle_DirectionHandler
	CP XDE, 00000086h
	JR Z, DemoStyle_DirectionHandler
	CP XDE, 00000006h
	JR Z, DemoStyle_DirectionHandler
	CP XDE, 00000084h
	JR Z, DemoStyle_EncoderHandler
	CP XDE, 00000004h
	JR Z, DemoStyle_EncoderHandler
	CP XDE, 00000083h
	JR Z, DemoStyle_EncoderHandler
	CP XDE, 00000003h
	JR NZ, DemoStyleTtlFunc_Exit

DemoStyle_EncoderHandler:
	CPW (28B4h), 0000h
	JR NZ, DemoStyleTtlFunc_Exit
	CP (0D2Fh), 000h
	JR NZ, DemoStyleTtlFunc_Exit
	LD WA, 00e2h
	JR T, DemoStyle_PostEventCommon

DemoStyle_DirectionHandler:
	CPW (28B4h), 0000h
	JR NZ, DemoStyleTtlFunc_Exit
	CP (0D2Fh), 000h
	JR NZ, DemoStyleTtlFunc_Exit
	LD WA, 00e3h

DemoStyle_PostEventCommon:
	CALL UI_PostModeChangeEvent
	JR T, DemoStyleTtlFunc_Exit

DemoStyle_EnterHandler:
	PUSH XDE
	PUSH XHL
	PUSH XIX
	PUSH XIZ
	CALL Demo_SelectionEntryHandler
	POP XIZ
	POP XIX
	POP XHL
	POP XDE

DemoStyleTtlFunc_Exit:
	LD XHL, 0
	RET

DemoSoundTtlFunc:
	CP XBC, 01c00007h
	JR Z, DemoSound_InputHandler
	CP XBC, 01c00013h
	JRL NZ, DemoSoundTtlFunc_Exit
	DEC 2, XDE
	CP XDE, 00000000h
	JRL C, DemoSoundTtlFunc_Exit
	CP XDE, 00000005h
	JRL UGT, DemoSoundTtlFunc_Exit
	ADD XDE, XDE
	ADD XDE, 00e201d0h
	LD DE, (XDE)
	LDA XIX, 0F22404h
	JP T, XIX + DE
DemoSound_DispatchTable:
	db 03Ah, 03Bh, 03Ch, 03Eh, 01Dh, 0D2h, 069h, 0F8h
	db "^", 05Ch, "[Zh|"

DemoSound_InputHandler:
	CP XDE, 0000000fh
	JR Z, DemoSound_EnterHandler
	CP XDE, 00000087h
	JR Z, DemoSound_DirectionHandler
	CP XDE, 00000007h
	JR Z, DemoSound_DirectionHandler
	CP XDE, 00000086h
	JR Z, DemoSound_DirectionHandler
	CP XDE, 00000006h
	JR Z, DemoSound_DirectionHandler
	CP XDE, 00000081h
	JR Z, DemoSound_EncoderHandler
	CP XDE, 00000001h
	JR Z, DemoSound_EncoderHandler
	CP XDE, 00000080h
	JR Z, DemoSound_EncoderHandler
	OR XDE, XDE
	JR NZ, DemoSoundTtlFunc_Exit

DemoSound_EncoderHandler:
	CPW (28B4h), 0000h
	JR NZ, DemoSoundTtlFunc_Exit
	CP (0D2Fh), 000h
	JR NZ, DemoSoundTtlFunc_Exit
	LD WA, 00e1h
	JR T, DemoSound_PostEventCommon

DemoSound_DirectionHandler:
	CPW (28B4h), 0000h
	JR NZ, DemoSoundTtlFunc_Exit
	CP (0D2Fh), 000h
	JR NZ, DemoSoundTtlFunc_Exit
	LD WA, 00e3h

DemoSound_PostEventCommon:
	CALL UI_PostModeChangeEvent
	JR T, DemoSoundTtlFunc_Exit

DemoSound_EnterHandler:
	PUSH XDE
	PUSH XHL
	PUSH XIX
	PUSH XIZ
	CALL Demo_SelectionEntryHandler
	POP XIZ
	POP XIX
	POP XHL
	POP XDE

DemoSoundTtlFunc_Exit:
	LD XHL, 0
	RET

DemoRhyTtlFunc:
	CP XBC, 01c00007h
	JR Z, DemoRhythm_InputHandler
	CP XBC, 01c00013h
	JRL NZ, DemoRhyTtlFunc_Exit
	DEC 2, XDE
	CP XDE, 00000000h
	JRL C, DemoRhyTtlFunc_Exit
	CP XDE, 00000005h
	JRL UGT, DemoRhyTtlFunc_Exit
	ADD XDE, XDE
	ADD XDE, 00e201dch
	LD DE, (XDE)
	LDA XIX, 0F224CAh
	JP T, XIX + DE
DemoRhythm_DispatchTable:
	db 03Ah, 03Bh, 03Ch, 03Eh, 01Dh, 0D2h, 069h, 0F8h
	db "^", 05Ch, "[Zh|"

DemoRhythm_InputHandler:
	CP XDE, 0000000fh
	JR Z, DemoRhythm_EnterHandler
	CP XDE, 00000084h
	JR Z, DemoRhythm_DirectionHandler
	CP XDE, 00000004h
	JR Z, DemoRhythm_DirectionHandler
	CP XDE, 00000083h
	JR Z, DemoRhythm_DirectionHandler
	CP XDE, 00000003h
	JR Z, DemoRhythm_DirectionHandler
	CP XDE, 00000081h
	JR Z, DemoRhythm_EncoderHandler
	CP XDE, 00000001h
	JR Z, DemoRhythm_EncoderHandler
	CP XDE, 00000080h
	JR Z, DemoRhythm_EncoderHandler
	OR XDE, XDE
	JR NZ, DemoRhyTtlFunc_Exit

DemoRhythm_EncoderHandler:
	CPW (28B4h), 0000h
	JR NZ, DemoRhyTtlFunc_Exit
	CP (0D2Fh), 000h
	JR NZ, DemoRhyTtlFunc_Exit
	LD WA, 00e1h
	JR T, DemoRhythm_PostEventCommon

DemoRhythm_DirectionHandler:
	CPW (28B4h), 0000h
	JR NZ, DemoRhyTtlFunc_Exit
	CP (0D2Fh), 000h
	JR NZ, DemoRhyTtlFunc_Exit
	LD WA, 00e2h

DemoRhythm_PostEventCommon:
	CALL UI_PostModeChangeEvent
	JR T, DemoRhyTtlFunc_Exit

DemoRhythm_EnterHandler:
	PUSH XDE
	PUSH XHL
	PUSH XIX
	PUSH XIZ
	CALL Demo_SelectionEntryHandler
	POP XIZ
	POP XIX
	POP XHL
	POP XDE

DemoRhyTtlFunc_Exit:
	LD XHL, 0
	RET

; End of Feature Demo routines
