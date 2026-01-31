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
	CP XBC, 01c0000ch
	JR Z, ComputerConnectionTitleExit
	CP XBC, 01c0000bh
	JR Z, ComputerConnectionTitleExit
	CP XBC, 01c00002h
	JR Z, ComputerConnectionTitleExit
	CP XBC, 01c00001h
	JR NZ, ComputerConnectionTitleExit
	OR XDE, XDE
	JR NZ, ComputerConnectionTitleExit
	CALL GET_COMPUTER_INTERFACE_SELECTION
	CP L, 0  ;  MIDI
	JR NZ, ComputerConnectionTitleExit
	LD (7F42h), 046h
	LD XWA, 0ffffffffh
	LD XBC, 01c00016h
	LD XDE, 01a000eeh
	CALL PostEvent

ComputerConnectionTitleExit:
	LD XHL, 0
	RET

MdCmptCnctFunc:
	DEC 4, XSP
	PUSH XIZ
	LD XHL, XDE
	LD XDE, XBC
	LD XIZ, XWA
	LD XIY, 00e7f844h
	LDA XIX, XSP + 004h
	LDIW
	LDIW
	CP XDE, 01e0003fh
	JRL Z, CmptCnctBlockingReturn
	CP XDE, 01e0003eh
	JRL Z, CmptCnctBlockingReturn
	CP XDE, 01e00041h
	JRL Z, CmptCnctBlockingReturn
	CP XDE, 01e00040h
	JRL Z, CmptCnctInvalidInputReturn
	CP XDE, 01e00042h
	JR Z, CmptCnctDrawConnectionDiagram
	LD XHL, 0
	JRL T, LABEL_F74C1B

CmptCnctDrawConnectionDiagram:
	LD BC, (XHL + 004h)
	LD XWA, (XHL + 008h)
	CP BC, 2
	JR Z, LABEL_F74BD2
	CP BC, 1
	JR Z, LABEL_F74BB5
	CP BC, 0
	JR NZ, LABEL_F74BEF
	PUSHW 00e7h
	PUSHW 0f848h
	PUSH XWA
	CALL LABEL_FF0F4D
	INC 8, XSP
	LDA XWA, XSP + 004h
	PUSHW 006ch
	LD XBC, Bitmap_MIDIConnections_1
	LD DE, 0128h
	JR T, CmptCnctBitmapDrawComplete

LABEL_F74BB5:
	PUSHW 00e7h
	PUSHW 0f862h
	PUSH XWA
	CALL LABEL_FF0F4D
	INC 8, XSP
	LDA XWA, XSP + 004h
	PUSHW 006ch
	LD XBC, Bitmap_MIDIConnections_2
	LD DE, 0128h
	JR T, CmptCnctBitmapDrawComplete

LABEL_F74BD2:
	PUSHW 00e7h
	PUSHW 0f87ch
	PUSH XWA
	CALL LABEL_FF0F4D
	INC 8, XSP
	LDA XWA, XSP + 004h
	PUSHW 006ch
	LD XBC, Bitmap_MIDIConnections_3
	LD DE, 0128h
	JR T, CmptCnctBitmapDrawComplete

LABEL_F74BEF:
	PUSHW 00e7h
	PUSHW 0f896h
	PUSH XWA
	CALL LABEL_FF0F4D
	INC 8, XSP
	LDA XWA, XSP + 004h
	PUSHW 006ch
	LD XBC, Bitmap_MIDIConnections_1
	LD DE, 0128h

CmptCnctBitmapDrawComplete:
	CALL DrawBitmapSPFast
	LD XHL, XIZ
	JR T, LABEL_F74C1B

CmptCnctInvalidInputReturn:
	LD XHL, 00002c00h
	JR T, LABEL_F74C1B

CmptCnctBlockingReturn:
	LD XHL, 1

LABEL_F74C1B:
	POP XIZ
	INC 4, XSP
	RET

MdPcgModeFunc:
	PUSH XIZ
	LD XIZ, XWA
	CP XBC, 01e0003fh
	JR Z, LABEL_F74C94
	CP XBC, 01e0003eh
	JR Z, LABEL_F74C94
	CP XBC, 01e00041h
	JR Z, LABEL_F74C94
	CP XBC, 01e00040h
	JR Z, LABEL_F74C8D
	CP XBC, 01e00042h
	JR Z, PcgModeGridEventStart
	LD XHL, 0
	JR T, LABEL_F74C96

PcgModeGridEventStart:
	LD XWA, XDE
	LD DE, (XWA + 004h)
	INC 8, XWA
	CP DE, 3
	JR Z, LABEL_F74C71
	LD XBC, (XWA)
	CP DE, 1
	JR Z, PcgModeDisplayString_Bank1
	CP DE, 0
	JR NZ, PcgModeDefaultCase
	LD XWA, 00e7f8b0h
	JR T, LABEL_F74C81

PcgModeDisplayString_Bank1:
	LD XWA, 00e7f8bah
	JR T, LABEL_F74C81

LABEL_F74C71:
	PUSHW 00e7h
	PUSHW 0f8c4h
	LD XWA, (XWA)
	PUSH XWA
	JR T, LABEL_F74C83

PcgModeDefaultCase:
	LD XWA, 00e7f8ceh

LABEL_F74C81:
	PUSH XWA
	PUSH XBC

LABEL_F74C83:
	CALL LABEL_FF0F4D
	INC 8, XSP
	LD XHL, XIZ
	JR T, LABEL_F74C96

LABEL_F74C8D:
	LD XHL, 00002201h
	JR T, LABEL_F74C96

LABEL_F74C94:
	LD XHL, 1

LABEL_F74C96:
	POP XIZ
	RET

MdDrumTypeFunc:
	PUSH XIZ
	LD XIZ, XWA
	CP XBC, 01e0003fh
	JR Z, LABEL_F74D0D
	CP XBC, 01e0003eh
	JR Z, LABEL_F74D0D
	CP XBC, 01e00041h
	JR Z, LABEL_F74D0D
	CP XBC, 01e00040h
	JR Z, LABEL_F74D06
	CP XBC, 01e00042h
	JR Z, LABEL_F74CC7
	LD XHL, 0
	JR T, LABEL_F74D0F

LABEL_F74CC7:
	LD XWA, XDE
	LD DE, (XWA + 004h)
	INC 8, XWA
	CP DE, 3
	JR Z, LABEL_F74CEA
	LD XBC, (XWA)
	CP DE, 1
	JR Z, LABEL_F74CE3
	CP DE, 0
	JR NZ, LABEL_F74CF5
	LD XWA, 00e7f8d8h
	JR T, LABEL_F74CFA

LABEL_F74CE3:
	LD XWA, 00e7f8e2h
	JR T, LABEL_F74CFA

LABEL_F74CEA:
	PUSHW 00e7h
	PUSHW 0f8ech
	LD XWA, (XWA)
	PUSH XWA
	JR T, LABEL_F74CFC

LABEL_F74CF5:
	LD XWA, 00e7f8f6h

LABEL_F74CFA:
	PUSH XWA
	PUSH XBC

LABEL_F74CFC:
	CALL LABEL_FF0F4D
	INC 8, XSP
	LD XHL, XIZ
	JR T, LABEL_F74D0F

LABEL_F74D06:
	LD XHL, 00002205h
	JR T, LABEL_F74D0F

LABEL_F74D0D:
	LD XHL, 1

LABEL_F74D0F:
	POP XIZ
	RET

MdSetupLoadFunc:
	LDA XSP, XSP - 010h
	PUSH XIZ
	LD XHL, XBC
	LD XIZ, XWA
	LD XIY, 00e7f900h
	LDA XIX, XSP + 004h
	LD BC, 0008h
	LDIRW_95
	SUB XHL, 01e0003eh
	CP XHL, 00000000h
	JR LT, SetupLoadInvalidIndex
	CP XHL, 00000009h
	JR GT, SetupLoadInvalidIndex
	ADD XHL, XHL
	ADD XHL, 00e7f928h
	LD HL, (XHL)
	LDA XIX, 0F74D50h
	JP T, XIX + HL
SetupLoadOptionJumpTable:
	db 0AAh, 00Eh, 020h, 0E8h, 0CCh, 002h, 000h, 000h
	db 000h, 0E8h, 0EEh, 002h, 0BFh, 004h, 031h, 0E8h
	db 081h, 0A1h, 020h, 038h, 0AAh, 012h, 020h, 038h
	db 01Dh, 04Dh, 00Fh, 0FFh, 0EFh, 060h, 0EEh, 08Bh
	db 068h, 015h, 0EBh, 0AAh, 068h, 011h, 0EBh, 0ABh
	db 068h, 00Dh

SetupLoadInvalidIndex:
	LD XHL, 0
	JR T, LABEL_F74D87
	LDA XHL, 0FFC0h:24
	JR T, LABEL_F74D87
	LD XHL, 1

LABEL_F74D87:
	POP XIZ
	LDA XSP, XSP + 010h
	RET

; End of Computer Interface Config routines

