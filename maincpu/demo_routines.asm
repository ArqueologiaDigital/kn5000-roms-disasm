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
	JR NZ, LABEL_F222FA
	CP XDE, 00000001h
	JR Z, LABEL_F222EE
	OR XDE, XDE
	JR NZ, LABEL_F222FA
	PUSH XDE
	PUSH XHL
	PUSH XIX
	PUSH XIZ
	CALL LABEL_F8696F
	POP XIZ
	POP XIX
	POP XHL
	POP XDE
	JR T, LABEL_F222FA

LABEL_F222EE:
	PUSH XDE
	PUSH XHL
	PUSH XIX
	PUSH XIZ
	CALL LABEL_F869E3
	POP XIZ
	POP XIX
	POP XHL
	POP XDE

LABEL_F222FA:
	LD XHL, 0
	RET

DemoMenuTtlFunc:
	LD XHL, 0
	RET

DemoStyleTtlFunc:
	CP XBC, 01c00007h
	JR Z, LABEL_F22348
	CP XBC, 01c00013h
	JRL NZ, LABEL_F223C8
	DEC 2, XDE
	CP XDE, 00000000h
	JRL C, LABEL_F223C8
	CP XDE, 00000005h
	JRL UGT, LABEL_F223C8
	ADD XDE, XDE
	ADD XDE, 00e201c4h
	LD DE, (XDE)
	LDA XIX, 0F22339h
	JP T, XIX + DE
LABEL_F22339:
	db 03Ah, 03Bh, 03Ch, 03Eh, 01Dh, 0D2h, 069h, 0F8h
	db 05Eh, 05Ch, 05Bh, 05Ah, 078h, 080h, 000h

LABEL_F22348:
	CP XDE, 0000000fh
	JR Z, LABEL_F223BC
	CP XDE, 00000087h
	JR Z, LABEL_F223A4
	CP XDE, 00000007h
	JR Z, LABEL_F223A4
	CP XDE, 00000086h
	JR Z, LABEL_F223A4
	CP XDE, 00000006h
	JR Z, LABEL_F223A4
	CP XDE, 00000084h
	JR Z, LABEL_F22390
	CP XDE, 00000004h
	JR Z, LABEL_F22390
	CP XDE, 00000083h
	JR Z, LABEL_F22390
	CP XDE, 00000003h
	JR NZ, LABEL_F223C8

LABEL_F22390:
	CPW (28B4h), 0000h
	JR NZ, LABEL_F223C8
	CP (0D2Fh), 000h
	JR NZ, LABEL_F223C8
	LD WA, 00e2h
	JR T, LABEL_F223B6

LABEL_F223A4:
	CPW (28B4h), 0000h
	JR NZ, LABEL_F223C8
	CP (0D2Fh), 000h
	JR NZ, LABEL_F223C8
	LD WA, 00e3h

LABEL_F223B6:
	CALL LABEL_F99490
	JR T, LABEL_F223C8

LABEL_F223BC:
	PUSH XDE
	PUSH XHL
	PUSH XIX
	PUSH XIZ
	CALL LABEL_F86A47
	POP XIZ
	POP XIX
	POP XHL
	POP XDE

LABEL_F223C8:
	LD XHL, 0
	RET

DemoSoundTtlFunc:
	CP XBC, 01c00007h
	JR Z, LABEL_F22412
	CP XBC, 01c00013h
	JRL NZ, LABEL_F2248E
	DEC 2, XDE
	CP XDE, 00000000h
	JRL C, LABEL_F2248E
	CP XDE, 00000005h
	JRL UGT, LABEL_F2248E
	ADD XDE, XDE
	ADD XDE, 00e201d0h
	LD DE, (XDE)
	LDA XIX, 0F22404h
	JP T, XIX + DE
LABEL_F22404:
	db 03Ah, 03Bh, 03Ch, 03Eh, 01Dh, 0D2h, 069h, 0F8h
	db "^", 05Ch, "[Zh|"

LABEL_F22412:
	CP XDE, 0000000fh
	JR Z, LABEL_F22482
	CP XDE, 00000087h
	JR Z, LABEL_F2246A
	CP XDE, 00000007h
	JR Z, LABEL_F2246A
	CP XDE, 00000086h
	JR Z, LABEL_F2246A
	CP XDE, 00000006h
	JR Z, LABEL_F2246A
	CP XDE, 00000081h
	JR Z, LABEL_F22456
	CP XDE, 00000001h
	JR Z, LABEL_F22456
	CP XDE, 00000080h
	JR Z, LABEL_F22456
	OR XDE, XDE
	JR NZ, LABEL_F2248E

LABEL_F22456:
	CPW (28B4h), 0000h
	JR NZ, LABEL_F2248E
	CP (0D2Fh), 000h
	JR NZ, LABEL_F2248E
	LD WA, 00e1h
	JR T, LABEL_F2247C

LABEL_F2246A:
	CPW (28B4h), 0000h
	JR NZ, LABEL_F2248E
	CP (0D2Fh), 000h
	JR NZ, LABEL_F2248E
	LD WA, 00e3h

LABEL_F2247C:
	CALL LABEL_F99490
	JR T, LABEL_F2248E

LABEL_F22482:
	PUSH XDE
	PUSH XHL
	PUSH XIX
	PUSH XIZ
	CALL LABEL_F86A47
	POP XIZ
	POP XIX
	POP XHL
	POP XDE

LABEL_F2248E:
	LD XHL, 0
	RET

DemoRhyTtlFunc:
	CP XBC, 01c00007h
	JR Z, LABEL_F224D8
	CP XBC, 01c00013h
	JRL NZ, LABEL_F22554
	DEC 2, XDE
	CP XDE, 00000000h
	JRL C, LABEL_F22554
	CP XDE, 00000005h
	JRL UGT, LABEL_F22554
	ADD XDE, XDE
	ADD XDE, 00e201dch
	LD DE, (XDE)
	LDA XIX, 0F224CAh
	JP T, XIX + DE
LABEL_F224CA:
	db 03Ah, 03Bh, 03Ch, 03Eh, 01Dh, 0D2h, 069h, 0F8h
	db "^", 05Ch, "[Zh|"

LABEL_F224D8:
	CP XDE, 0000000fh
	JR Z, LABEL_F22548
	CP XDE, 00000084h
	JR Z, LABEL_F22530
	CP XDE, 00000004h
	JR Z, LABEL_F22530
	CP XDE, 00000083h
	JR Z, LABEL_F22530
	CP XDE, 00000003h
	JR Z, LABEL_F22530
	CP XDE, 00000081h
	JR Z, LABEL_F2251C
	CP XDE, 00000001h
	JR Z, LABEL_F2251C
	CP XDE, 00000080h
	JR Z, LABEL_F2251C
	OR XDE, XDE
	JR NZ, LABEL_F22554

LABEL_F2251C:
	CPW (28B4h), 0000h
	JR NZ, LABEL_F22554
	CP (0D2Fh), 000h
	JR NZ, LABEL_F22554
	LD WA, 00e1h
	JR T, LABEL_F22542

LABEL_F22530:
	CPW (28B4h), 0000h
	JR NZ, LABEL_F22554
	CP (0D2Fh), 000h
	JR NZ, LABEL_F22554
	LD WA, 00e2h

LABEL_F22542:
	CALL LABEL_F99490
	JR T, LABEL_F22554

LABEL_F22548:
	PUSH XDE
	PUSH XHL
	PUSH XIX
	PUSH XIZ
	CALL LABEL_F86A47
	POP XIZ
	POP XIX
	POP XHL
	POP XDE

LABEL_F22554:
	LD XHL, 0
	RET

; End of Feature Demo routines
