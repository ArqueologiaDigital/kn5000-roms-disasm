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
	cp xbc, 0x1C0000C
	jr z, ComputerConnectionTitleExit
	cp xbc, 0x1C0000B
	jr z, ComputerConnectionTitleExit
	cp xbc, 0x1C00002
	jr z, ComputerConnectionTitleExit
	cp xbc, 0x1C00001
	jr nz, ComputerConnectionTitleExit
	or xde, xde
	jr nz, ComputerConnectionTitleExit
	call GET_COMPUTER_INTERFACE_SELECTION
	cps l, 0	;  MIDI
	jr nz, ComputerConnectionTitleExit
	stdi8 32578, 70
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00016
	ld xde, 0x1A000EE
	call LABEL_FA9752

ComputerConnectionTitleExit:
	lds32 xhl, 0
	ret

MdCmptCnctFunc:
	dec 4, xsp
	push xiz
	ld xhl, xde
	ld xde, xbc
	ld xiz, xwa
	ld xiy, 0xE7F844
	lda xix, (xsp + 4)
	ldiw
	ldiw
	cp xde, 0x1E0003F
	jrl z, CmptCnctBlockingReturn
	cp xde, 0x1E0003E
	jrl z, CmptCnctBlockingReturn
	cp xde, 0x1E00041
	jrl z, CmptCnctBlockingReturn
	cp xde, 0x1E00040
	jrl z, CmptCnctInvalidInputReturn
	cp xde, 0x1E00042
	jr z, CmptCnctDrawConnectionDiagram
	lds32 xhl, 0
	jrl MdCmptCnct_Epilogue

CmptCnctDrawConnectionDiagram:
	ld bc, (xhl + 4)
	ld xwa, (xhl + 8)
	cps bc, 2
	jr z, CmptCnct_DrawDiagram2
	cps bc, 1
	jr z, CmptCnct_DrawDiagram1
	cps bc, 0
	jr nz, CmptCnct_DrawDiagramDefault
	pushw 0xE7
	pushw 0xF848
	push xwa
	call Strcpy
	inc 8, xsp
	lda xwa, (xsp + 4)
	pushw 0x6C
	ld xbc, 0xE64772
	ldw de, 0x128
	jr CmptCnctBitmapDrawComplete

CmptCnct_DrawDiagram1:
	pushw 0xE7
	pushw 0xF862
	push xwa
	call Strcpy
	inc 8, xsp
	lda xwa, (xsp + 4)
	pushw 0x6C
	ld xbc, 0xE6C452
	ldw de, 0x128
	jr CmptCnctBitmapDrawComplete

CmptCnct_DrawDiagram2:
	pushw 0xE7
	pushw 0xF87C
	push xwa
	call Strcpy
	inc 8, xsp
	lda xwa, (xsp + 4)
	pushw 0x6C
	ld xbc, 0xE74132
	ldw de, 0x128
	jr CmptCnctBitmapDrawComplete

CmptCnct_DrawDiagramDefault:
	pushw 0xE7
	pushw 0xF896
	push xwa
	call Strcpy
	inc 8, xsp
	lda xwa, (xsp + 4)
	pushw 0x6C
	ld xbc, 0xE64772
	ldw de, 0x128

CmptCnctBitmapDrawComplete:
	call 0xFAC3DB
	ld xhl, xiz
	jr MdCmptCnct_Epilogue

CmptCnctInvalidInputReturn:
	ld xhl, 0x2C00
	jr MdCmptCnct_Epilogue

CmptCnctBlockingReturn:
	lds32 xhl, 1

MdCmptCnct_Epilogue:
	pop xiz
	inc 4, xsp
	ret

MdPcgModeFunc:
	push xiz
	ld xiz, xwa
	cp xbc, 0x1E0003F
	jr z, PcgMode_BlockingReturn
	cp xbc, 0x1E0003E
	jr z, PcgMode_BlockingReturn
	cp xbc, 0x1E00041
	jr z, PcgMode_BlockingReturn
	cp xbc, 0x1E00040
	jr z, PcgMode_InvalidReturn
	cp xbc, 0x1E00042
	jr z, PcgModeGridEventStart
	lds32 xhl, 0
	jr MdPcgMode_Epilogue

PcgModeGridEventStart:
	ld xwa, xde
	ld de, (xwa + 4)
	inc 8, xwa
	cps de, 3
	jr z, PcgMode_CopyStrCustom
	ld xbc, (xwa)
	cps de, 1
	jr z, PcgModeDisplayString_Bank1
	cps de, 0
	jr nz, PcgModeDefaultCase
	ld xwa, 0xE7F8B0
	jr PcgMode_CopyStrEntry

PcgModeDisplayString_Bank1:
	ld xwa, 0xE7F8BA
	jr PcgMode_CopyStrEntry

PcgMode_CopyStrCustom:
	pushw 0xE7
	pushw 0xF8C4
	ld xwa, (xwa)
	push xwa
	jr PcgMode_CallStrcpy

PcgModeDefaultCase:
	ld xwa, 0xE7F8CE

PcgMode_CopyStrEntry:
	push xwa
	push xbc

PcgMode_CallStrcpy:
	call Strcpy
	inc 8, xsp
	ld xhl, xiz
	jr MdPcgMode_Epilogue

PcgMode_InvalidReturn:
	ld xhl, 0x2201
	jr MdPcgMode_Epilogue

PcgMode_BlockingReturn:
	lds32 xhl, 1

MdPcgMode_Epilogue:
	pop xiz
	ret

MdDrumTypeFunc:
	push xiz
	ld xiz, xwa
	cp xbc, 0x1E0003F
	jr z, DrumType_BlockingReturn
	cp xbc, 0x1E0003E
	jr z, DrumType_BlockingReturn
	cp xbc, 0x1E00041
	jr z, DrumType_BlockingReturn
	cp xbc, 0x1E00040
	jr z, DrumType_InvalidReturn
	cp xbc, 0x1E00042
	jr z, DrumType_GridEvent
	lds32 xhl, 0
	jr MdDrumType_Epilogue

DrumType_GridEvent:
	ld xwa, xde
	ld de, (xwa + 4)
	inc 8, xwa
	cps de, 3
	jr z, DrumType_CopyStrCustom
	ld xbc, (xwa)
	cps de, 1
	jr z, DrumType_CopyStrBank1
	cps de, 0
	jr nz, DrumType_CopyStrDefault
	ld xwa, 0xE7F8D8
	jr DrumType_CopyStrEntry

DrumType_CopyStrBank1:
	ld xwa, 0xE7F8E2
	jr DrumType_CopyStrEntry

DrumType_CopyStrCustom:
	pushw 0xE7
	pushw 0xF8EC
	ld xwa, (xwa)
	push xwa
	jr DrumType_CallStrcpy

DrumType_CopyStrDefault:
	ld xwa, 0xE7F8F6

DrumType_CopyStrEntry:
	push xwa
	push xbc

DrumType_CallStrcpy:
	call Strcpy
	inc 8, xsp
	ld xhl, xiz
	jr MdDrumType_Epilogue

DrumType_InvalidReturn:
	ld xhl, 0x2205
	jr MdDrumType_Epilogue

DrumType_BlockingReturn:
	lds32 xhl, 1

MdDrumType_Epilogue:
	pop xiz
	ret

MdSetupLoadFunc:
	lda xsp, (xsp - 16)
	push xiz
	ld xhl, xbc
	ld xiz, xwa
	ld xiy, 0xE7F900
	lda xix, (xsp + 4)
	ldw bc, 0x8
	ldirw
	sub xhl, 0x1E0003E
	cp xhl, 0x0
	jr lt, SetupLoadInvalidIndex
	cp xhl, 0x9
	jr gt, SetupLoadInvalidIndex
	add xhl, xhl
	add xhl, 0xE7F928
	ld hl, (xhl)
	lda_24 xix, 0xf74d50
	jp_dri 8, 0x07, 0xF0, 0xEC
SetupLoadOptionJumpTable:
	.byte 0xaa, 0x0e, 0x20, 0xe8, 0xcc, 0x02, 0x00, 0x00
	.byte 0x00, 0xe8, 0xee, 0x02, 0xbf, 0x04, 0x31, 0xe8
	.byte 0x81, 0xa1, 0x20, 0x38, 0xaa, 0x12, 0x20, 0x38
	.byte 0x1d, 0x4d, 0x0f, 0xff, 0xef, 0x60, 0xee, 0x8b
	.byte 0x68, 0x15, 0xeb, 0xaa, 0x68, 0x11, 0xeb, 0xab
	.byte 0x68, 0x0d

SetupLoadInvalidIndex:
	lds32 xhl, 0
	jr MdSetupLoad_Epilogue
	lda_24 xhl, 0x00ffc0
	jr MdSetupLoad_Epilogue
	lds32 xhl, 1

MdSetupLoad_Epilogue:
	pop xiz
	lda xsp, (xsp + 16)
	ret

; End of Computer Interface Config routines

