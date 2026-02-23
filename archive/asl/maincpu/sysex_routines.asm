; =============================================================================
; sysex_routines.asm - MIDI System Exclusive (SysEx) Routines
; =============================================================================
; This file contains all MIDI System Exclusive message handling routines
; for the KN5000 Main CPU.
;
; System Exclusive messages are used for:
;   - Bulk data dumps (panel memory, sound memory, composer, sequences, MSP)
;   - Parameter transfers between devices
;   - Manufacturer-specific commands
;
; Routines included:
;   ExcSendFunc    - Main SysEx send handler
;   MainExcSend    - SysEx send dispatch
;   ExcDotFunc     - DOT (Data Object Transfer) handler
;   ExcPmemFunc    - Panel Memory SysEx handler
;   ExcSmemFunc    - Sound Memory SysEx handler
;   ExcCompFunc    - Composer SysEx handler
;   ExcSeqFunc     - Sequence SysEx handler
;   ExcMspFunc     - MSP (Music Style Programmer) SysEx handler
;
; Each Exc*Func handles SysEx messages for a specific data type:
;   - PMEM: Panel Memory settings (PM1-PM8)
;   - SMEM: Sound Memory banks
;   - COMP: Composer/arranger data
;   - SEQ:  Sequencer song data
;   - MSP:  Music Style Programmer data
;
; =============================================================================

ExcSendFunc:
	LD XHL, XDE
	CP XBC, 01c00007h
	JR NZ, ExcSendFunc_InvalidParam_Exit
	LD XWA, 00570003h
	LD XBC, 01e00090h
	LD XDE, 0
	CALL SendEvent
	EXTS XHL
	LD XWA, 01430001h
	LD XBC, 01e30001h
	LD XDE, XHL
	CALL MainFuncCall

ExcSendFunc_InvalidParam_Exit:
	LD XHL, 0
	RET

MainExcSend:
	CP XBC, 01e30001h
	JR NZ, MainExcSend_UnexpectedMessageType_Exit
	CP XDE, 00000006h
	JR C, MainExcSend_ClampIndexToRange
	LD XDE, 0

MainExcSend_ClampIndexToRange:
	LD XWA, 00e7fd84h
	ADD XWA, XDE
	LD A, (XWA)
	CALL LABEL_FD8CAE

MainExcSend_UnexpectedMessageType_Exit:
	LD XHL, 0
	RET

ExcDotFunc:
	SUB XBC, 01e0003eh
	CP XBC, 00000000h
	JR LT, ExcDotFunc_InvalidIndex_Exit
	CP XBC, 00000009h
	JR GT, ExcDotFunc_InvalidIndex_Exit
	ADD XBC, XBC
	ADD XBC, 00e7fd8ah
	LD BC, (XBC)
	LDA XIX, 0F76696h
	JP T, XIX + BC
ExcDotFunc_HandlerJumpTable:
	db 0AAh, 012h, 024h, 0AAh, 00Eh, 021h, 0CBh, 08Fh
	db 0DAh, 0A8h, 0C2h, 05Ch, 047h, 002h, 023h, 0D9h
	db 012h, 0D9h, 0D8h, 063h, 016h, 0CFh, 0D8h, 066h
	db 008h, 0F5h, 0F0h, 000h, 09Dh, 0CFh, 069h, 068h
	db 004h, 0F5h, 0F0h, 000h, 02Eh, 0DAh, 061h, 0D9h
	db 0F2h, 067h, 0EAh, 0B4h, 000h, 000h, 0E8h, 08Bh
	db 00Eh, 0EBh, 0A9h, 00Eh, 043h, 020h, 000h, 000h
	db 000h, 00Eh

ExcDotFunc_InvalidIndex_Exit:
	LD XHL, 0
	RET

LABEL_F766D3:
	db 0F2h, 05Eh, 047h, 002h, 033h, 00Eh

ExcPmemFunc:
	PUSH XIZ
	LD XIZ, XWA
	SUB XBC, 01e0003eh
	CP XBC, 00000000h
	JR LT, ExcPmemFunc_InvalidIndex_Exit
	CP XBC, 00000009h
	JR GT, ExcPmemFunc_InvalidIndex_Exit
	ADD XBC, XBC
	ADD XBC, 00e7fdd6h
	LD BC, (XBC)
	LDA XIX, 0F76706h
	JP T, XIX + BC
LABEL_F76706:
	db 0AAh, 00Eh, 020h, 0E8h, 0EEh, 002h, 041h, 09Eh
	db 0FDh, 0E7h, 000h, 0E8h, 081h, 0A1h, 020h, 038h
	db 0AAh, 012h, 020h, 038h, 01Dh, 04Dh, 00Fh, 0FFh
	db 0EFh, 060h, 0EEh, 08Bh, 068h, 011h, 0EBh, 0A9h
	db 068h, 00Dh, 0EBh, 0ABh, 068h, 009h

ExcPmemFunc_InvalidIndex_Exit:
	LD XHL, 0
	JR T, ExcPmemFunc_Return
	LDA XHL, 024760h

ExcPmemFunc_Return:
	POP XIZ
	RET

ExcSmemFunc:
	PUSH XIZ
	LD XIZ, XWA
	SUB XBC, 01e0003eh
	CP XBC, 00000000h
	JR LT, ExcSmemFunc_InvalidIndex_Exit
	CP XBC, 00000009h
	JR GT, ExcSmemFunc_InvalidIndex_Exit
	ADD XBC, XBC
	ADD XBC, 00e7fdeah
	LD BC, (XBC)
	LDA XIX, 0F76764h
	JP T, XIX + BC
LABEL_F76764:
	db 0AAh, 00Eh, 020h, 0E8h, 0EEh, 002h, 041h, 09Eh
	db 0FDh, 0E7h, 000h, 0E8h, 081h, 0A1h, 020h, 038h
	db 0AAh, 012h, 020h, 038h, 01Dh, 04Dh, 00Fh, 0FFh
	db 0EFh, 060h, 0EEh, 08Bh, 068h, 011h, 0EBh, 0A9h
	db 068h, 00Dh, 0EBh, 0ABh, 068h, 009h

ExcSmemFunc_InvalidIndex_Exit:
	LD XHL, 0
	JR T, ExcSmemFunc_Return
	LDA XHL, 024762h

ExcSmemFunc_Return:
	POP XIZ
	RET

ExcCompFunc:
	PUSH XIZ
	LD XIZ, XWA
	SUB XBC, 01e0003eh
	CP XBC, 00000000h
	JR LT, ExcCompFunc_InvalidIndex_Exit
	CP XBC, 00000009h
	JR GT, ExcCompFunc_InvalidIndex_Exit
	ADD XBC, XBC
	ADD XBC, 00e7fdfeh
	LD BC, (XBC)
	LDA XIX, 0F767C2h
	JP T, XIX + BC
LABEL_F767C2:
	db 0AAh, 00Eh, 020h, 0E8h, 0EEh, 002h, 041h, 09Eh
	db 0FDh, 0E7h, 000h, 0E8h, 081h, 0A1h, 020h, 038h
	db 0AAh, 012h, 020h, 038h, 01Dh, 04Dh, 00Fh, 0FFh
	db 0EFh, 060h, 0EEh, 08Bh, 068h, 011h, 0EBh, 0A9h
	db 068h, 00Dh, 0EBh, 0ABh, 068h, 009h

ExcCompFunc_InvalidIndex_Exit:
	LD XHL, 0
	JR T, ExcCompFunc_Return
	LDA XHL, 024764h

ExcCompFunc_Return:
	POP XIZ
	RET

ExcSeqFunc:
	PUSH XIZ
	LD XIZ, XWA
	SUB XBC, 01e0003eh
	CP XBC, 00000000h
	JR LT, ExcSeqFunc_InvalidIndex_Exit
	CP XBC, 00000009h
	JR GT, ExcSeqFunc_InvalidIndex_Exit
	ADD XBC, XBC
	ADD XBC, 00e7fe12h
	LD BC, (XBC)
	LDA XIX, 0F76820h
	JP T, XIX + BC
LABEL_F76820:
	db 0AAh, 00Eh, 020h, 0E8h, 0EEh, 002h, 041h, 09Eh
	db 0FDh, 0E7h, 000h, 0E8h, 081h, 0A1h, 020h, 038h
	db 0AAh, 012h, 020h, 038h, 01Dh, 04Dh, 00Fh, 0FFh
	db 0EFh, 060h, 0EEh, 08Bh, 068h, 011h, 0EBh, 0A9h
	db 068h, 00Dh, 0EBh, 0ABh, 068h, 009h

ExcSeqFunc_InvalidIndex_Exit:
	LD XHL, 0
	JR T, ExcSeqFunc_Return
	LDA XHL, 024766h

ExcSeqFunc_Return:
	POP XIZ
	RET

ExcMspFunc:
	PUSH XIZ
	LD XIZ, XWA
	SUB XBC, 01e0003eh
	CP XBC, 00000000h
	JR LT, ExcMspFunc_InvalidIndex_Exit
	CP XBC, 00000009h
	JR GT, ExcMspFunc_InvalidIndex_Exit
	ADD XBC, XBC
	ADD XBC, 00e7fe26h
	LD BC, (XBC)
	LDA XIX, 0F7687Eh
	JP T, XIX + BC
LABEL_F7687E:
	db 0AAh, 00Eh, 020h, 0E8h, 0EEh, 002h, 041h, 09Eh
	db 0FDh, 0E7h, 000h, 0E8h, 081h, 0A1h, 020h, 038h
	db 0AAh, 012h, 020h, 038h, 01Dh, 04Dh, 00Fh, 0FFh
	db 0EFh, 060h, 0EEh, 08Bh, 068h, 011h, 0EBh, 0A9h
	db 068h, 00Dh, 0EBh, 0ABh, 068h, 009h

ExcMspFunc_InvalidIndex_Exit:
	LD XHL, 0
	JR T, ExcMspFunc_Return
	LDA XHL, 024768h

ExcMspFunc_Return:
	POP XIZ
	RET

; End of SysEx routines
