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
	; (no addr) CP XBC, 01c00013h
	; (no addr) JR NZ, DemoModeFunc_Exit
	; (no addr) CP XDE, 00000001h
	; (no addr) JR Z, DemoModeFunc_Initialize
	; (no addr) OR XDE, XDE
	; (no addr) JR NZ, DemoModeFunc_Exit
	; (no addr) PUSH XDE
	; (no addr) PUSH XHL
	; (no addr) PUSH XIX
	; (no addr) PUSH XIZ
	; (no addr) CALL DemoMode_Main_Operation
	; (no addr) POP XIZ
	; (no addr) POP XIX
	; (no addr) POP XHL
	; (no addr) POP XDE
	; (no addr) JR T, DemoModeFunc_Exit

DemoModeFunc_Initialize:
	; (no addr) PUSH XDE
	; (no addr) PUSH XHL
	; (no addr) PUSH XIX
	; (no addr) PUSH XIZ
	; (no addr) CALL DemoMode_Initialize
	; (no addr) POP XIZ
	; (no addr) POP XIX
	; (no addr) POP XHL
	; (no addr) POP XDE

DemoModeFunc_Exit:
	; (no addr) LD XHL, 0
	; (no addr) RET

DemoMenuTtlFunc:
	; (no addr) LD XHL, 0
	; (no addr) RET

DemoStyleTtlFunc:
	; (no addr) CP XBC, 01c00007h
	; (no addr) JR Z, DemoStyle_InputHandler
	; (no addr) CP XBC, 01c00013h
	; (no addr) JRL NZ, DemoStyleTtlFunc_Exit
	; (no addr) DEC 2, XDE
	; (no addr) CP XDE, 00000000h
	; (no addr) JRL C, DemoStyleTtlFunc_Exit
	; (no addr) CP XDE, 00000005h
	; (no addr) JRL UGT, DemoStyleTtlFunc_Exit
	; (no addr) ADD XDE, XDE
	; (no addr) ADD XDE, 00e201c4h
	; (no addr) LD DE, (XDE)
	; (no addr) LDA XIX, 0F22339h
	; (no addr) JP T, XIX + DE
DemoStyle_DispatchTable:
	.byte 0x3A, 0x3B, 0x3C, 0x3E, 0x1D, 0xD2, 0x69, 0xF8
	.byte 0x5E, 0x5C, 0x5B, 0x5A, 0x78, 0x80, 0x0

DemoStyle_InputHandler:
	; (no addr) CP XDE, 0000000fh
	; (no addr) JR Z, DemoStyle_EnterHandler
	; (no addr) CP XDE, 00000087h
	; (no addr) JR Z, DemoStyle_DirectionHandler
	; (no addr) CP XDE, 00000007h
	; (no addr) JR Z, DemoStyle_DirectionHandler
	; (no addr) CP XDE, 00000086h
	; (no addr) JR Z, DemoStyle_DirectionHandler
	; (no addr) CP XDE, 00000006h
	; (no addr) JR Z, DemoStyle_DirectionHandler
	; (no addr) CP XDE, 00000084h
	; (no addr) JR Z, DemoStyle_EncoderHandler
	; (no addr) CP XDE, 00000004h
	; (no addr) JR Z, DemoStyle_EncoderHandler
	; (no addr) CP XDE, 00000083h
	; (no addr) JR Z, DemoStyle_EncoderHandler
	; (no addr) CP XDE, 00000003h
	; (no addr) JR NZ, DemoStyleTtlFunc_Exit

DemoStyle_EncoderHandler:
	; (no addr) CPW (28B4h), 0000h
	; (no addr) JR NZ, DemoStyleTtlFunc_Exit
	; (no addr) CP (0D2Fh), 000h
	; (no addr) JR NZ, DemoStyleTtlFunc_Exit
	; (no addr) LD WA, 00e2h
	; (no addr) JR T, DemoStyle_PostEventCommon

DemoStyle_DirectionHandler:
	; (no addr) CPW (28B4h), 0000h
	; (no addr) JR NZ, DemoStyleTtlFunc_Exit
	; (no addr) CP (0D2Fh), 000h
	; (no addr) JR NZ, DemoStyleTtlFunc_Exit
	; (no addr) LD WA, 00e3h

DemoStyle_PostEventCommon:
	; (no addr) CALL UI_PostModeChangeEvent
	; (no addr) JR T, DemoStyleTtlFunc_Exit

DemoStyle_EnterHandler:
	; (no addr) PUSH XDE
	; (no addr) PUSH XHL
	; (no addr) PUSH XIX
	; (no addr) PUSH XIZ
	; (no addr) CALL Demo_SelectionEntryHandler
	; (no addr) POP XIZ
	; (no addr) POP XIX
	; (no addr) POP XHL
	; (no addr) POP XDE

DemoStyleTtlFunc_Exit:
	; (no addr) LD XHL, 0
	; (no addr) RET

DemoSoundTtlFunc:
	; (no addr) CP XBC, 01c00007h
	; (no addr) JR Z, DemoSound_InputHandler
	; (no addr) CP XBC, 01c00013h
	; (no addr) JRL NZ, DemoSoundTtlFunc_Exit
	; (no addr) DEC 2, XDE
	; (no addr) CP XDE, 00000000h
	; (no addr) JRL C, DemoSoundTtlFunc_Exit
	; (no addr) CP XDE, 00000005h
	; (no addr) JRL UGT, DemoSoundTtlFunc_Exit
	; (no addr) ADD XDE, XDE
	; (no addr) ADD XDE, 00e201d0h
	; (no addr) LD DE, (XDE)
	; (no addr) LDA XIX, 0F22404h
	; (no addr) JP T, XIX + DE
DemoSound_DispatchTable:
	.byte 0x3A, 0x3B, 0x3C, 0x3E, 0x1D, 0xD2, 0x69, 0xF8
	.ascii "^"
	.byte 0x5C
	.ascii "[Zh|"

DemoSound_InputHandler:
	; (no addr) CP XDE, 0000000fh
	; (no addr) JR Z, DemoSound_EnterHandler
	; (no addr) CP XDE, 00000087h
	; (no addr) JR Z, DemoSound_DirectionHandler
	; (no addr) CP XDE, 00000007h
	; (no addr) JR Z, DemoSound_DirectionHandler
	; (no addr) CP XDE, 00000086h
	; (no addr) JR Z, DemoSound_DirectionHandler
	; (no addr) CP XDE, 00000006h
	; (no addr) JR Z, DemoSound_DirectionHandler
	; (no addr) CP XDE, 00000081h
	; (no addr) JR Z, DemoSound_EncoderHandler
	; (no addr) CP XDE, 00000001h
	; (no addr) JR Z, DemoSound_EncoderHandler
	; (no addr) CP XDE, 00000080h
	; (no addr) JR Z, DemoSound_EncoderHandler
	; (no addr) OR XDE, XDE
	; (no addr) JR NZ, DemoSoundTtlFunc_Exit

DemoSound_EncoderHandler:
	; (no addr) CPW (28B4h), 0000h
	; (no addr) JR NZ, DemoSoundTtlFunc_Exit
	; (no addr) CP (0D2Fh), 000h
	; (no addr) JR NZ, DemoSoundTtlFunc_Exit
	; (no addr) LD WA, 00e1h
	; (no addr) JR T, DemoSound_PostEventCommon

DemoSound_DirectionHandler:
	; (no addr) CPW (28B4h), 0000h
	; (no addr) JR NZ, DemoSoundTtlFunc_Exit
	; (no addr) CP (0D2Fh), 000h
	; (no addr) JR NZ, DemoSoundTtlFunc_Exit
	; (no addr) LD WA, 00e3h

DemoSound_PostEventCommon:
	; (no addr) CALL UI_PostModeChangeEvent
	; (no addr) JR T, DemoSoundTtlFunc_Exit

DemoSound_EnterHandler:
	; (no addr) PUSH XDE
	; (no addr) PUSH XHL
	; (no addr) PUSH XIX
	; (no addr) PUSH XIZ
	; (no addr) CALL Demo_SelectionEntryHandler
	; (no addr) POP XIZ
	; (no addr) POP XIX
	; (no addr) POP XHL
	; (no addr) POP XDE

DemoSoundTtlFunc_Exit:
	; (no addr) LD XHL, 0
	; (no addr) RET

DemoRhyTtlFunc:
	; (no addr) CP XBC, 01c00007h
	; (no addr) JR Z, DemoRhythm_InputHandler
	; (no addr) CP XBC, 01c00013h
	; (no addr) JRL NZ, DemoRhyTtlFunc_Exit
	; (no addr) DEC 2, XDE
	; (no addr) CP XDE, 00000000h
	; (no addr) JRL C, DemoRhyTtlFunc_Exit
	; (no addr) CP XDE, 00000005h
	; (no addr) JRL UGT, DemoRhyTtlFunc_Exit
	; (no addr) ADD XDE, XDE
	; (no addr) ADD XDE, 00e201dch
	; (no addr) LD DE, (XDE)
	; (no addr) LDA XIX, 0F224CAh
	; (no addr) JP T, XIX + DE
DemoRhythm_DispatchTable:
	.byte 0x3A, 0x3B, 0x3C, 0x3E, 0x1D, 0xD2, 0x69, 0xF8
	.ascii "^"
	.byte 0x5C
	.ascii "[Zh|"

DemoRhythm_InputHandler:
	; (no addr) CP XDE, 0000000fh
	; (no addr) JR Z, DemoRhythm_EnterHandler
	; (no addr) CP XDE, 00000084h
	; (no addr) JR Z, DemoRhythm_DirectionHandler
	; (no addr) CP XDE, 00000004h
	; (no addr) JR Z, DemoRhythm_DirectionHandler
	; (no addr) CP XDE, 00000083h
	; (no addr) JR Z, DemoRhythm_DirectionHandler
	; (no addr) CP XDE, 00000003h
	; (no addr) JR Z, DemoRhythm_DirectionHandler
	; (no addr) CP XDE, 00000081h
	; (no addr) JR Z, DemoRhythm_EncoderHandler
	; (no addr) CP XDE, 00000001h
	; (no addr) JR Z, DemoRhythm_EncoderHandler
	; (no addr) CP XDE, 00000080h
	; (no addr) JR Z, DemoRhythm_EncoderHandler
	; (no addr) OR XDE, XDE
	; (no addr) JR NZ, DemoRhyTtlFunc_Exit

DemoRhythm_EncoderHandler:
	; (no addr) CPW (28B4h), 0000h
	; (no addr) JR NZ, DemoRhyTtlFunc_Exit
	; (no addr) CP (0D2Fh), 000h
	; (no addr) JR NZ, DemoRhyTtlFunc_Exit
	; (no addr) LD WA, 00e1h
	; (no addr) JR T, DemoRhythm_PostEventCommon

DemoRhythm_DirectionHandler:
	; (no addr) CPW (28B4h), 0000h
	; (no addr) JR NZ, DemoRhyTtlFunc_Exit
	; (no addr) CP (0D2Fh), 000h
	; (no addr) JR NZ, DemoRhyTtlFunc_Exit
	; (no addr) LD WA, 00e2h

DemoRhythm_PostEventCommon:
	; (no addr) CALL UI_PostModeChangeEvent
	; (no addr) JR T, DemoRhyTtlFunc_Exit

DemoRhythm_EnterHandler:
	; (no addr) PUSH XDE
	; (no addr) PUSH XHL
	; (no addr) PUSH XIX
	; (no addr) PUSH XIZ
	; (no addr) CALL Demo_SelectionEntryHandler
	; (no addr) POP XIZ
	; (no addr) POP XIX
	; (no addr) POP XHL
	; (no addr) POP XDE

DemoRhyTtlFunc_Exit:
	; (no addr) LD XHL, 0
	; (no addr) RET

; End of Feature Demo routines
