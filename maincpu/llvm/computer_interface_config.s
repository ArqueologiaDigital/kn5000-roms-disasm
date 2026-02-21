; =============================================================================
; computer_interface_config.asm - Computer Interface Connection Config
; =============================================================================
; This file contains Computer Interface configuration routines:
;   TtComputerConnection  - Connection title handler
;   MdCmptCnctFunc        - MIDI Computer Connection mode function
;   MdPcgModeFunc         - MIDI Program Change mode function
;   MdDrumTypeFunc        - MIDI Drum Type selection function
;   MdSetupLoadFunc       - MIDI Setup Load function
;
; Related functions elsewhere in the ROM:
;   TtMdRealMsg                    (line ~292452) - Real-time message title
;   GET_COMPUTER_INTERFACE_SELECTION (line ~422620) - Gets current interface
;
; Data references:
;   COM_SELECT (0B7E0h)            - Current computer interface selection
;   Bitmap_MIDIConnections_1/2/3   - Connection diagram bitmaps
;
; =============================================================================

TtComputerConnection:
	; (no addr) CP XBC, 01c0000ch
	; (no addr) JR Z, ComputerConnectionTitleExit
	; (no addr) CP XBC, 01c0000bh
	; (no addr) JR Z, ComputerConnectionTitleExit
	; (no addr) CP XBC, 01c00002h
	; (no addr) JR Z, ComputerConnectionTitleExit
	; (no addr) CP XBC, 01c00001h
	; (no addr) JR NZ, ComputerConnectionTitleExit
	; (no addr) OR XDE, XDE
	; (no addr) JR NZ, ComputerConnectionTitleExit
	; (no addr) CALL GET_COMPUTER_INTERFACE_SELECTION
	; (no addr) CP L, 0	;  MIDI
	; (no addr) JR NZ, ComputerConnectionTitleExit
	; (no addr) LD (7F42h), 046h
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01c00016h
	; (no addr) LD XDE, 01a000eeh
	; (no addr) CALL PostEvent

ComputerConnectionTitleExit:
	; (no addr) LD XHL, 0
	; (no addr) RET

MdCmptCnctFunc:
	; (no addr) DEC 4, XSP
	; (no addr) PUSH XIZ
	; (no addr) LD XHL, XDE
	; (no addr) LD XDE, XBC
	; (no addr) LD XIZ, XWA
	; (no addr) LD XIY, 00e7f844h
	; (no addr) LDA XIX, XSP + 004h
	LDIW
	LDIW
	; (no addr) CP XDE, 01e0003fh
	; (no addr) JRL Z, CmptCnctBlockingReturn
	; (no addr) CP XDE, 01e0003eh
	; (no addr) JRL Z, CmptCnctBlockingReturn
	; (no addr) CP XDE, 01e00041h
	; (no addr) JRL Z, CmptCnctBlockingReturn
	; (no addr) CP XDE, 01e00040h
	; (no addr) JRL Z, CmptCnctInvalidInputReturn
	; (no addr) CP XDE, 01e00042h
	; (no addr) JR Z, CmptCnctDrawConnectionDiagram
	; (no addr) LD XHL, 0
	; (no addr) JRL T, LABEL_F74C1B

CmptCnctDrawConnectionDiagram:
	; (no addr) LD BC, (XHL + 004h)
	; (no addr) LD XWA, (XHL + 008h)
	; (no addr) CP BC, 2
	; (no addr) JR Z, LABEL_F74BD2
	; (no addr) CP BC, 1
	; (no addr) JR Z, LABEL_F74BB5
	; (no addr) CP BC, 0
	; (no addr) JR NZ, LABEL_F74BEF
	; (no addr) PUSHW 00e7h
	; (no addr) PUSHW 0f848h
	; (no addr) PUSH XWA
	; (no addr) CALL LABEL_FF0F4D
	; (no addr) INC 8, XSP
	; (no addr) LDA XWA, XSP + 004h
	; (no addr) PUSHW 006ch
	; (no addr) LD XBC, Bitmap_MIDIConnections_1
	; (no addr) LD DE, 0128h
	; (no addr) JR T, CmptCnctBitmapDrawComplete

LABEL_F74BB5:
	; (no addr) PUSHW 00e7h
	; (no addr) PUSHW 0f862h
	; (no addr) PUSH XWA
	; (no addr) CALL LABEL_FF0F4D
	; (no addr) INC 8, XSP
	; (no addr) LDA XWA, XSP + 004h
	; (no addr) PUSHW 006ch
	; (no addr) LD XBC, Bitmap_MIDIConnections_2
	; (no addr) LD DE, 0128h
	; (no addr) JR T, CmptCnctBitmapDrawComplete

LABEL_F74BD2:
	; (no addr) PUSHW 00e7h
	; (no addr) PUSHW 0f87ch
	; (no addr) PUSH XWA
	; (no addr) CALL LABEL_FF0F4D
	; (no addr) INC 8, XSP
	; (no addr) LDA XWA, XSP + 004h
	; (no addr) PUSHW 006ch
	; (no addr) LD XBC, Bitmap_MIDIConnections_3
	; (no addr) LD DE, 0128h
	; (no addr) JR T, CmptCnctBitmapDrawComplete

LABEL_F74BEF:
	; (no addr) PUSHW 00e7h
	; (no addr) PUSHW 0f896h
	; (no addr) PUSH XWA
	; (no addr) CALL LABEL_FF0F4D
	; (no addr) INC 8, XSP
	; (no addr) LDA XWA, XSP + 004h
	; (no addr) PUSHW 006ch
	; (no addr) LD XBC, Bitmap_MIDIConnections_1
	; (no addr) LD DE, 0128h

CmptCnctBitmapDrawComplete:
	; (no addr) CALL DrawBitmapSPFast
	; (no addr) LD XHL, XIZ
	; (no addr) JR T, LABEL_F74C1B

CmptCnctInvalidInputReturn:
	; (no addr) LD XHL, 00002c00h
	; (no addr) JR T, LABEL_F74C1B

CmptCnctBlockingReturn:
	; (no addr) LD XHL, 1

LABEL_F74C1B:
	; (no addr) POP XIZ
	; (no addr) INC 4, XSP
	; (no addr) RET

MdPcgModeFunc:
	; (no addr) PUSH XIZ
	; (no addr) LD XIZ, XWA
	; (no addr) CP XBC, 01e0003fh
	; (no addr) JR Z, LABEL_F74C94
	; (no addr) CP XBC, 01e0003eh
	; (no addr) JR Z, LABEL_F74C94
	; (no addr) CP XBC, 01e00041h
	; (no addr) JR Z, LABEL_F74C94
	; (no addr) CP XBC, 01e00040h
	; (no addr) JR Z, LABEL_F74C8D
	; (no addr) CP XBC, 01e00042h
	; (no addr) JR Z, PcgModeGridEventStart
	; (no addr) LD XHL, 0
	; (no addr) JR T, LABEL_F74C96

PcgModeGridEventStart:
	; (no addr) LD XWA, XDE
	; (no addr) LD DE, (XWA + 004h)
	; (no addr) INC 8, XWA
	; (no addr) CP DE, 3
	; (no addr) JR Z, LABEL_F74C71
	; (no addr) LD XBC, (XWA)
	; (no addr) CP DE, 1
	; (no addr) JR Z, PcgModeDisplayString_Bank1
	; (no addr) CP DE, 0
	; (no addr) JR NZ, PcgModeDefaultCase
	; (no addr) LD XWA, 00e7f8b0h
	; (no addr) JR T, LABEL_F74C81

PcgModeDisplayString_Bank1:
	; (no addr) LD XWA, 00e7f8bah
	; (no addr) JR T, LABEL_F74C81

LABEL_F74C71:
	; (no addr) PUSHW 00e7h
	; (no addr) PUSHW 0f8c4h
	; (no addr) LD XWA, (XWA)
	; (no addr) PUSH XWA
	; (no addr) JR T, LABEL_F74C83

PcgModeDefaultCase:
	; (no addr) LD XWA, 00e7f8ceh

LABEL_F74C81:
	; (no addr) PUSH XWA
	; (no addr) PUSH XBC

LABEL_F74C83:
	; (no addr) CALL LABEL_FF0F4D
	; (no addr) INC 8, XSP
	; (no addr) LD XHL, XIZ
	; (no addr) JR T, LABEL_F74C96

LABEL_F74C8D:
	; (no addr) LD XHL, 00002201h
	; (no addr) JR T, LABEL_F74C96

LABEL_F74C94:
	; (no addr) LD XHL, 1

LABEL_F74C96:
	; (no addr) POP XIZ
	; (no addr) RET

MdDrumTypeFunc:
	; (no addr) PUSH XIZ
	; (no addr) LD XIZ, XWA
	; (no addr) CP XBC, 01e0003fh
	; (no addr) JR Z, LABEL_F74D0D
	; (no addr) CP XBC, 01e0003eh
	; (no addr) JR Z, LABEL_F74D0D
	; (no addr) CP XBC, 01e00041h
	; (no addr) JR Z, LABEL_F74D0D
	; (no addr) CP XBC, 01e00040h
	; (no addr) JR Z, LABEL_F74D06
	; (no addr) CP XBC, 01e00042h
	; (no addr) JR Z, LABEL_F74CC7
	; (no addr) LD XHL, 0
	; (no addr) JR T, LABEL_F74D0F

LABEL_F74CC7:
	; (no addr) LD XWA, XDE
	; (no addr) LD DE, (XWA + 004h)
	; (no addr) INC 8, XWA
	; (no addr) CP DE, 3
	; (no addr) JR Z, LABEL_F74CEA
	; (no addr) LD XBC, (XWA)
	; (no addr) CP DE, 1
	; (no addr) JR Z, LABEL_F74CE3
	; (no addr) CP DE, 0
	; (no addr) JR NZ, LABEL_F74CF5
	; (no addr) LD XWA, 00e7f8d8h
	; (no addr) JR T, LABEL_F74CFA

LABEL_F74CE3:
	; (no addr) LD XWA, 00e7f8e2h
	; (no addr) JR T, LABEL_F74CFA

LABEL_F74CEA:
	; (no addr) PUSHW 00e7h
	; (no addr) PUSHW 0f8ech
	; (no addr) LD XWA, (XWA)
	; (no addr) PUSH XWA
	; (no addr) JR T, LABEL_F74CFC

LABEL_F74CF5:
	; (no addr) LD XWA, 00e7f8f6h

LABEL_F74CFA:
	; (no addr) PUSH XWA
	; (no addr) PUSH XBC

LABEL_F74CFC:
	; (no addr) CALL LABEL_FF0F4D
	; (no addr) INC 8, XSP
	; (no addr) LD XHL, XIZ
	; (no addr) JR T, LABEL_F74D0F

LABEL_F74D06:
	; (no addr) LD XHL, 00002205h
	; (no addr) JR T, LABEL_F74D0F

LABEL_F74D0D:
	; (no addr) LD XHL, 1

LABEL_F74D0F:
	; (no addr) POP XIZ
	; (no addr) RET

MdSetupLoadFunc:
	; (no addr) LDA XSP, XSP - 010h
	; (no addr) PUSH XIZ
	; (no addr) LD XHL, XBC
	; (no addr) LD XIZ, XWA
	; (no addr) LD XIY, 00e7f900h
	; (no addr) LDA XIX, XSP + 004h
	; (no addr) LD BC, 0008h
	LDIRW_95
	; (no addr) SUB XHL, 01e0003eh
	; (no addr) CP XHL, 00000000h
	; (no addr) JR LT, SetupLoadInvalidIndex
	; (no addr) CP XHL, 00000009h
	; (no addr) JR GT, SetupLoadInvalidIndex
	; (no addr) ADD XHL, XHL
	; (no addr) ADD XHL, 00e7f928h
	; (no addr) LD HL, (XHL)
	; (no addr) LDA XIX, 0F74D50h
	; (no addr) JP T, XIX + HL
SetupLoadOptionJumpTable:
	.byte 0xAA, 0xE, 0x20, 0xE8, 0xCC, 0x2, 0x0, 0x0
	.byte 0x0, 0xE8, 0xEE, 0x2, 0xBF, 0x4, 0x31, 0xE8
	.byte 0x81, 0xA1, 0x20, 0x38, 0xAA, 0x12, 0x20, 0x38
	.byte 0x1D, 0x4D, 0xF, 0xFF, 0xEF, 0x60, 0xEE, 0x8B
	.byte 0x68, 0x15, 0xEB, 0xAA, 0x68, 0x11, 0xEB, 0xAB
	.byte 0x68, 0xD

SetupLoadInvalidIndex:
	; (no addr) LD XHL, 0
	; (no addr) JR T, LABEL_F74D87
	; (no addr) LDA XHL, 0FFC0h:24
	; (no addr) JR T, LABEL_F74D87
	; (no addr) LD XHL, 1

LABEL_F74D87:
	; (no addr) POP XIZ
	; (no addr) LDA XSP, XSP + 010h
	; (no addr) RET

; End of Computer Interface Config routines

