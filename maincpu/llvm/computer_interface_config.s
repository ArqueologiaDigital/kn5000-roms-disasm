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
	cp XBC, 0x1c0000c
	jr Z, ComputerConnectionTitleExit
	cp XBC, 0x1c0000b
	jr Z, ComputerConnectionTitleExit
	cp XBC, 0x1c00002
	jr Z, ComputerConnectionTitleExit
	cp XBC, 0x1c00001
	jr NZ, ComputerConnectionTitleExit
	or XDE, XDE
	jr NZ, ComputerConnectionTitleExit
	call GET_COMPUTER_INTERFACE_SELECTION
	cp L, 0	;  MIDI
	jr NZ, ComputerConnectionTitleExit
	ld (0x7F42), 0x46
	ld XWA, 0xffffffff
	ld XBC, 0x1c00016
	ld XDE, 0x1a000ee
	call PostEvent

ComputerConnectionTitleExit:
	ld XHL, 0
	ret

MdCmptCnctFunc:
	dec 4, XSP
	push XIZ
	ld XHL, XDE
	ld XDE, XBC
	ld XIZ, XWA
	ld XIY, 0xe7f844
	lda XIX, XSP + 0x4
	LDIW
	LDIW
	cp XDE, 0x1e0003f
	jrl Z, CmptCnctBlockingReturn
	cp XDE, 0x1e0003e
	jrl Z, CmptCnctBlockingReturn
	cp XDE, 0x1e00041
	jrl Z, CmptCnctBlockingReturn
	cp XDE, 0x1e00040
	jrl Z, CmptCnctInvalidInputReturn
	cp XDE, 0x1e00042
	jr Z, CmptCnctDrawConnectionDiagram
	ld XHL, 0
	jrl LABEL_F74C1B

CmptCnctDrawConnectionDiagram:
	ld BC, (XHL + 0x4)
	ld XWA, (XHL + 0x8)
	cp BC, 2
	jr Z, LABEL_F74BD2
	cp BC, 1
	jr Z, LABEL_F74BB5
	cp BC, 0
	jr NZ, LABEL_F74BEF
	pushw 0xe7
	pushw 0xf848
	push XWA
	call LABEL_FF0F4D
	inc 8, XSP
	lda XWA, XSP + 0x4
	pushw 0x6c
	ld XBC, Bitmap_MIDIConnections_1
	ld DE, 0x128
	jr CmptCnctBitmapDrawComplete

LABEL_F74BB5:
	pushw 0xe7
	pushw 0xf862
	push XWA
	call LABEL_FF0F4D
	inc 8, XSP
	lda XWA, XSP + 0x4
	pushw 0x6c
	ld XBC, Bitmap_MIDIConnections_2
	ld DE, 0x128
	jr CmptCnctBitmapDrawComplete

LABEL_F74BD2:
	pushw 0xe7
	pushw 0xf87c
	push XWA
	call LABEL_FF0F4D
	inc 8, XSP
	lda XWA, XSP + 0x4
	pushw 0x6c
	ld XBC, Bitmap_MIDIConnections_3
	ld DE, 0x128
	jr CmptCnctBitmapDrawComplete

LABEL_F74BEF:
	pushw 0xe7
	pushw 0xf896
	push XWA
	call LABEL_FF0F4D
	inc 8, XSP
	lda XWA, XSP + 0x4
	pushw 0x6c
	ld XBC, Bitmap_MIDIConnections_1
	ld DE, 0x128

CmptCnctBitmapDrawComplete:
	call DrawBitmapSPFast
	ld XHL, XIZ
	jr LABEL_F74C1B

CmptCnctInvalidInputReturn:
	ld XHL, 0x2c00
	jr LABEL_F74C1B

CmptCnctBlockingReturn:
	ld XHL, 1

LABEL_F74C1B:
	pop XIZ
	inc 4, XSP
	ret

MdPcgModeFunc:
	push XIZ
	ld XIZ, XWA
	cp XBC, 0x1e0003f
	jr Z, LABEL_F74C94
	cp XBC, 0x1e0003e
	jr Z, LABEL_F74C94
	cp XBC, 0x1e00041
	jr Z, LABEL_F74C94
	cp XBC, 0x1e00040
	jr Z, LABEL_F74C8D
	cp XBC, 0x1e00042
	jr Z, PcgModeGridEventStart
	ld XHL, 0
	jr LABEL_F74C96

PcgModeGridEventStart:
	ld XWA, XDE
	ld DE, (XWA + 0x4)
	inc 8, XWA
	cp DE, 3
	jr Z, LABEL_F74C71
	ld XBC, (XWA)
	cp DE, 1
	jr Z, PcgModeDisplayString_Bank1
	cp DE, 0
	jr NZ, PcgModeDefaultCase
	ld XWA, 0xe7f8b0
	jr LABEL_F74C81

PcgModeDisplayString_Bank1:
	ld XWA, 0xe7f8ba
	jr LABEL_F74C81

LABEL_F74C71:
	pushw 0xe7
	pushw 0xf8c4
	ld XWA, (XWA)
	push XWA
	jr LABEL_F74C83

PcgModeDefaultCase:
	ld XWA, 0xe7f8ce

LABEL_F74C81:
	push XWA
	push XBC

LABEL_F74C83:
	call LABEL_FF0F4D
	inc 8, XSP
	ld XHL, XIZ
	jr LABEL_F74C96

LABEL_F74C8D:
	ld XHL, 0x2201
	jr LABEL_F74C96

LABEL_F74C94:
	ld XHL, 1

LABEL_F74C96:
	pop XIZ
	ret

MdDrumTypeFunc:
	push XIZ
	ld XIZ, XWA
	cp XBC, 0x1e0003f
	jr Z, LABEL_F74D0D
	cp XBC, 0x1e0003e
	jr Z, LABEL_F74D0D
	cp XBC, 0x1e00041
	jr Z, LABEL_F74D0D
	cp XBC, 0x1e00040
	jr Z, LABEL_F74D06
	cp XBC, 0x1e00042
	jr Z, LABEL_F74CC7
	ld XHL, 0
	jr LABEL_F74D0F

LABEL_F74CC7:
	ld XWA, XDE
	ld DE, (XWA + 0x4)
	inc 8, XWA
	cp DE, 3
	jr Z, LABEL_F74CEA
	ld XBC, (XWA)
	cp DE, 1
	jr Z, LABEL_F74CE3
	cp DE, 0
	jr NZ, LABEL_F74CF5
	ld XWA, 0xe7f8d8
	jr LABEL_F74CFA

LABEL_F74CE3:
	ld XWA, 0xe7f8e2
	jr LABEL_F74CFA

LABEL_F74CEA:
	pushw 0xe7
	pushw 0xf8ec
	ld XWA, (XWA)
	push XWA
	jr LABEL_F74CFC

LABEL_F74CF5:
	ld XWA, 0xe7f8f6

LABEL_F74CFA:
	push XWA
	push XBC

LABEL_F74CFC:
	call LABEL_FF0F4D
	inc 8, XSP
	ld XHL, XIZ
	jr LABEL_F74D0F

LABEL_F74D06:
	ld XHL, 0x2205
	jr LABEL_F74D0F

LABEL_F74D0D:
	ld XHL, 1

LABEL_F74D0F:
	pop XIZ
	ret

MdSetupLoadFunc:
	lda XSP, XSP - 0x10
	push XIZ
	ld XHL, XBC
	ld XIZ, XWA
	ld XIY, 0xe7f900
	lda XIX, XSP + 0x4
	ld BC, 0x8
	LDIRW_95
	sub XHL, 0x1e0003e
	cp XHL, 0x0
	jr LT, SetupLoadInvalidIndex
	cp XHL, 0x9
	jr GT, SetupLoadInvalidIndex
	add XHL, XHL
	add XHL, 0xe7f928
	ld HL, (XHL)
	lda XIX, 0xF74D50
	jp XIX + HL
SetupLoadOptionJumpTable:
	.byte 0xAA, 0xE, 0x20, 0xE8, 0xCC, 0x2, 0x0, 0x0
	.byte 0x0, 0xE8, 0xEE, 0x2, 0xBF, 0x4, 0x31, 0xE8
	.byte 0x81, 0xA1, 0x20, 0x38, 0xAA, 0x12, 0x20, 0x38
	.byte 0x1D, 0x4D, 0xF, 0xFF, 0xEF, 0x60, 0xEE, 0x8B
	.byte 0x68, 0x15, 0xEB, 0xAA, 0x68, 0x11, 0xEB, 0xAB
	.byte 0x68, 0xD

SetupLoadInvalidIndex:
	ld XHL, 0
	jr LABEL_F74D87
	lda XHL, 0xFFC0
	jr LABEL_F74D87
	ld XHL, 1

LABEL_F74D87:
	pop XIZ
	lda XSP, XSP + 0x10
	ret

; End of Computer Interface Config routines

