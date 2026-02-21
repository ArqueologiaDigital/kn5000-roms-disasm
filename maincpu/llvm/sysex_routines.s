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
	; (no addr) LD XHL, XDE
	; (no addr) CP XBC, 01c00007h
	; (no addr) JR NZ, ExcSendFunc_InvalidParam_Exit
	; (no addr) LD XWA, 00570003h
	; (no addr) LD XBC, 01e00090h
	; (no addr) LD XDE, 0
	; (no addr) CALL SendEvent
	; (no addr) EXTS XHL
	; (no addr) LD XWA, 01430001h
	; (no addr) LD XBC, 01e30001h
	; (no addr) LD XDE, XHL
	; (no addr) CALL MainFuncCall

ExcSendFunc_InvalidParam_Exit:
	; (no addr) LD XHL, 0
	; (no addr) RET

MainExcSend:
	; (no addr) CP XBC, 01e30001h
	; (no addr) JR NZ, MainExcSend_UnexpectedMessageType_Exit
	; (no addr) CP XDE, 00000006h
	; (no addr) JR C, MainExcSend_ClampIndexToRange
	; (no addr) LD XDE, 0

MainExcSend_ClampIndexToRange:
	; (no addr) LD XWA, 00e7fd84h
	; (no addr) ADD XWA, XDE
	; (no addr) LD A, (XWA)
	; (no addr) CALL LABEL_FD8CAE

MainExcSend_UnexpectedMessageType_Exit:
	; (no addr) LD XHL, 0
	; (no addr) RET

ExcDotFunc:
	; (no addr) SUB XBC, 01e0003eh
	; (no addr) CP XBC, 00000000h
	; (no addr) JR LT, ExcDotFunc_InvalidIndex_Exit
	; (no addr) CP XBC, 00000009h
	; (no addr) JR GT, ExcDotFunc_InvalidIndex_Exit
	; (no addr) ADD XBC, XBC
	; (no addr) ADD XBC, 00e7fd8ah
	; (no addr) LD BC, (XBC)
	; (no addr) LDA XIX, 0F76696h
	; (no addr) JP T, XIX + BC
ExcDotFunc_HandlerJumpTable:
	.byte 0xAA, 0x12, 0x24, 0xAA, 0xE, 0x21, 0xCB, 0x8F
	.byte 0xDA, 0xA8, 0xC2, 0x5C, 0x47, 0x2, 0x23, 0xD9
	.byte 0x12, 0xD9, 0xD8, 0x63, 0x16, 0xCF, 0xD8, 0x66
	.byte 0x8, 0xF5, 0xF0, 0x0, 0x9D, 0xCF, 0x69, 0x68
	.byte 0x4, 0xF5, 0xF0, 0x0, 0x2E, 0xDA, 0x61, 0xD9
	.byte 0xF2, 0x67, 0xEA, 0xB4, 0x0, 0x0, 0xE8, 0x8B
	.byte 0xE, 0xEB, 0xA9, 0xE, 0x43, 0x20, 0x0, 0x0
	.byte 0x0, 0xE

ExcDotFunc_InvalidIndex_Exit:
	; (no addr) LD XHL, 0
	; (no addr) RET

LABEL_F766D3:
	.byte 0xF2, 0x5E, 0x47, 0x2, 0x33, 0xE

ExcPmemFunc:
	; (no addr) PUSH XIZ
	; (no addr) LD XIZ, XWA
	; (no addr) SUB XBC, 01e0003eh
	; (no addr) CP XBC, 00000000h
	; (no addr) JR LT, ExcPmemFunc_InvalidIndex_Exit
	; (no addr) CP XBC, 00000009h
	; (no addr) JR GT, ExcPmemFunc_InvalidIndex_Exit
	; (no addr) ADD XBC, XBC
	; (no addr) ADD XBC, 00e7fdd6h
	; (no addr) LD BC, (XBC)
	; (no addr) LDA XIX, 0F76706h
	; (no addr) JP T, XIX + BC
LABEL_F76706:
	.byte 0xAA, 0xE, 0x20, 0xE8, 0xEE, 0x2, 0x41, 0x9E
	.byte 0xFD, 0xE7, 0x0, 0xE8, 0x81, 0xA1, 0x20, 0x38
	.byte 0xAA, 0x12, 0x20, 0x38, 0x1D, 0x4D, 0xF, 0xFF
	.byte 0xEF, 0x60, 0xEE, 0x8B, 0x68, 0x11, 0xEB, 0xA9
	.byte 0x68, 0xD, 0xEB, 0xAB, 0x68, 0x9

ExcPmemFunc_InvalidIndex_Exit:
	; (no addr) LD XHL, 0
	; (no addr) JR T, ExcPmemFunc_Return
	; (no addr) LDA XHL, 024760h

ExcPmemFunc_Return:
	; (no addr) POP XIZ
	; (no addr) RET

ExcSmemFunc:
	; (no addr) PUSH XIZ
	; (no addr) LD XIZ, XWA
	; (no addr) SUB XBC, 01e0003eh
	; (no addr) CP XBC, 00000000h
	; (no addr) JR LT, ExcSmemFunc_InvalidIndex_Exit
	; (no addr) CP XBC, 00000009h
	; (no addr) JR GT, ExcSmemFunc_InvalidIndex_Exit
	; (no addr) ADD XBC, XBC
	; (no addr) ADD XBC, 00e7fdeah
	; (no addr) LD BC, (XBC)
	; (no addr) LDA XIX, 0F76764h
	; (no addr) JP T, XIX + BC
LABEL_F76764:
	.byte 0xAA, 0xE, 0x20, 0xE8, 0xEE, 0x2, 0x41, 0x9E
	.byte 0xFD, 0xE7, 0x0, 0xE8, 0x81, 0xA1, 0x20, 0x38
	.byte 0xAA, 0x12, 0x20, 0x38, 0x1D, 0x4D, 0xF, 0xFF
	.byte 0xEF, 0x60, 0xEE, 0x8B, 0x68, 0x11, 0xEB, 0xA9
	.byte 0x68, 0xD, 0xEB, 0xAB, 0x68, 0x9

ExcSmemFunc_InvalidIndex_Exit:
	; (no addr) LD XHL, 0
	; (no addr) JR T, ExcSmemFunc_Return
	; (no addr) LDA XHL, 024762h

ExcSmemFunc_Return:
	; (no addr) POP XIZ
	; (no addr) RET

ExcCompFunc:
	; (no addr) PUSH XIZ
	; (no addr) LD XIZ, XWA
	; (no addr) SUB XBC, 01e0003eh
	; (no addr) CP XBC, 00000000h
	; (no addr) JR LT, ExcCompFunc_InvalidIndex_Exit
	; (no addr) CP XBC, 00000009h
	; (no addr) JR GT, ExcCompFunc_InvalidIndex_Exit
	; (no addr) ADD XBC, XBC
	; (no addr) ADD XBC, 00e7fdfeh
	; (no addr) LD BC, (XBC)
	; (no addr) LDA XIX, 0F767C2h
	; (no addr) JP T, XIX + BC
LABEL_F767C2:
	.byte 0xAA, 0xE, 0x20, 0xE8, 0xEE, 0x2, 0x41, 0x9E
	.byte 0xFD, 0xE7, 0x0, 0xE8, 0x81, 0xA1, 0x20, 0x38
	.byte 0xAA, 0x12, 0x20, 0x38, 0x1D, 0x4D, 0xF, 0xFF
	.byte 0xEF, 0x60, 0xEE, 0x8B, 0x68, 0x11, 0xEB, 0xA9
	.byte 0x68, 0xD, 0xEB, 0xAB, 0x68, 0x9

ExcCompFunc_InvalidIndex_Exit:
	; (no addr) LD XHL, 0
	; (no addr) JR T, ExcCompFunc_Return
	; (no addr) LDA XHL, 024764h

ExcCompFunc_Return:
	; (no addr) POP XIZ
	; (no addr) RET

ExcSeqFunc:
	; (no addr) PUSH XIZ
	; (no addr) LD XIZ, XWA
	; (no addr) SUB XBC, 01e0003eh
	; (no addr) CP XBC, 00000000h
	; (no addr) JR LT, ExcSeqFunc_InvalidIndex_Exit
	; (no addr) CP XBC, 00000009h
	; (no addr) JR GT, ExcSeqFunc_InvalidIndex_Exit
	; (no addr) ADD XBC, XBC
	; (no addr) ADD XBC, 00e7fe12h
	; (no addr) LD BC, (XBC)
	; (no addr) LDA XIX, 0F76820h
	; (no addr) JP T, XIX + BC
LABEL_F76820:
	.byte 0xAA, 0xE, 0x20, 0xE8, 0xEE, 0x2, 0x41, 0x9E
	.byte 0xFD, 0xE7, 0x0, 0xE8, 0x81, 0xA1, 0x20, 0x38
	.byte 0xAA, 0x12, 0x20, 0x38, 0x1D, 0x4D, 0xF, 0xFF
	.byte 0xEF, 0x60, 0xEE, 0x8B, 0x68, 0x11, 0xEB, 0xA9
	.byte 0x68, 0xD, 0xEB, 0xAB, 0x68, 0x9

ExcSeqFunc_InvalidIndex_Exit:
	; (no addr) LD XHL, 0
	; (no addr) JR T, ExcSeqFunc_Return
	; (no addr) LDA XHL, 024766h

ExcSeqFunc_Return:
	; (no addr) POP XIZ
	; (no addr) RET

ExcMspFunc:
	; (no addr) PUSH XIZ
	; (no addr) LD XIZ, XWA
	; (no addr) SUB XBC, 01e0003eh
	; (no addr) CP XBC, 00000000h
	; (no addr) JR LT, ExcMspFunc_InvalidIndex_Exit
	; (no addr) CP XBC, 00000009h
	; (no addr) JR GT, ExcMspFunc_InvalidIndex_Exit
	; (no addr) ADD XBC, XBC
	; (no addr) ADD XBC, 00e7fe26h
	; (no addr) LD BC, (XBC)
	; (no addr) LDA XIX, 0F7687Eh
	; (no addr) JP T, XIX + BC
LABEL_F7687E:
	.byte 0xAA, 0xE, 0x20, 0xE8, 0xEE, 0x2, 0x41, 0x9E
	.byte 0xFD, 0xE7, 0x0, 0xE8, 0x81, 0xA1, 0x20, 0x38
	.byte 0xAA, 0x12, 0x20, 0x38, 0x1D, 0x4D, 0xF, 0xFF
	.byte 0xEF, 0x60, 0xEE, 0x8B, 0x68, 0x11, 0xEB, 0xA9
	.byte 0x68, 0xD, 0xEB, 0xAB, 0x68, 0x9

ExcMspFunc_InvalidIndex_Exit:
	; (no addr) LD XHL, 0
	; (no addr) JR T, ExcMspFunc_Return
	; (no addr) LDA XHL, 024768h

ExcMspFunc_Return:
	; (no addr) POP XIZ
	; (no addr) RET

; End of SysEx routines
