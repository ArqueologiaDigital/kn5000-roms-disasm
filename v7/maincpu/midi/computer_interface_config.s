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
	.incbin "includes/generated/v7_transplant_TtComputerConnection.bin"
ComputerConnectionTitleExit:
	lds32 xhl, 0
	ret

MdCmptCnctFunc:
	dec 4, xsp
	push xiz
	ld xhl, xde
	ld xde, xbc
	ld xiz, xwa
	ld xiy, SplitPoint_NoteEntry_C_Code_0x66
	lda xix, (xsp + 4)
	ldiw
	ldiw
	cp xde, 0x1e0003f
	jrl z, CmptCnctBlockingReturn
	cp xde, 0x1e0003e
	jrl z, CmptCnctBlockingReturn
	cp xde, 0x1e00041
	jrl z, CmptCnctBlockingReturn
	cp xde, 0x1e00040
	jrl z, CmptCnctInvalidInputReturn
	cp xde, 0x1e00042
	jr z, CmptCnctDrawConnectionDiagram
	lds32 xhl, 0
	jrl MdCmptCnct_Epilogue

CmptCnctDrawConnectionDiagram:
	.incbin "includes/generated/v7_transplant_CmptCnctDrawConnectionDiagram.bin"
CmptCnct_DrawDiagram1:
	.incbin "includes/generated/v7_transplant_CmptCnct_DrawDiagram1.bin"
CmptCnct_DrawDiagram2:
	.incbin "includes/generated/v7_transplant_CmptCnct_DrawDiagram2.bin"
CmptCnct_DrawDiagramDefault:
	.incbin "includes/generated/v7_transplant_CmptCnct_DrawDiagramDefault.bin"
CmptCnctBitmapDrawComplete:
	call DrawBitmapSPFast
	ld xhl, xiz
	jr MdCmptCnct_Epilogue

CmptCnctInvalidInputReturn:
	ld xhl, 0x2c00
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
	cp xbc, 0x1e0003f
	jr z, PcgMode_BlockingReturn
	cp xbc, 0x1e0003e
	jr z, PcgMode_BlockingReturn
	cp xbc, 0x1e00041
	jr z, PcgMode_BlockingReturn
	cp xbc, 0x1e00040
	jr z, PcgMode_InvalidReturn
	cp xbc, 0x1e00042
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
	ld xwa, SplitPoint_NoteEntry_C_Code_0xD2
	jr PcgMode_CopyStrEntry

PcgModeDisplayString_Bank1:
	ld xwa, SplitPoint_NoteEntry_C_Code_0xDC
	jr PcgMode_CopyStrEntry

PcgMode_CopyStrCustom:
	pushw 0xe7
	pushw 0xf8c4
	ld xwa, (xwa)
	push xwa
	jr PcgMode_CallStrcpy

PcgModeDefaultCase:
	ld xwa, SplitPoint_NoteEntry_C_Code_0xF0

PcgMode_CopyStrEntry:
	push xwa
	push xbc

PcgMode_CallStrcpy:
	.incbin "includes/generated/v7_transplant_PcgMode_CallStrcpy.bin"
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
	cp xbc, 0x1e0003f
	jr z, DrumType_BlockingReturn
	cp xbc, 0x1e0003e
	jr z, DrumType_BlockingReturn
	cp xbc, 0x1e00041
	jr z, DrumType_BlockingReturn
	cp xbc, 0x1e00040
	jr z, DrumType_InvalidReturn
	cp xbc, 0x1e00042
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
	ld xwa, SplitPoint_NoteEntry_C_Code_0xFA
	jr DrumType_CopyStrEntry

DrumType_CopyStrBank1:
	ld xwa, SplitPoint_NoteEntry_C_Code_0x104
	jr DrumType_CopyStrEntry

DrumType_CopyStrCustom:
	pushw 0xe7
	pushw 0xf8ec
	ld xwa, (xwa)
	push xwa
	jr DrumType_CallStrcpy

DrumType_CopyStrDefault:
	ld xwa, SplitPoint_NoteEntry_C_Code_0x118

DrumType_CopyStrEntry:
	push xwa
	push xbc

DrumType_CallStrcpy:
	.incbin "includes/generated/v7_transplant_DrumType_CallStrcpy.bin"
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
	ld xiy, DisplayMode_OnOff_Table
	lda xix, (xsp + 4)
	ldw bc, 0x8
	ldirw
	sub xhl, 0x1e0003e
	cp xhl, 0x0
	jr lt, SetupLoadInvalidIndex
	cp xhl, 0x9
	jr gt, SetupLoadInvalidIndex
	add xhl, xhl
	add xhl, NakaInst_OFF_WidgetTbl2_0x12
	ld hl, (xhl)
	lda_24 xix, (SetupLoadOptionJumpTable)
	jp_ind 8, 0x07, 0xf0, 0xec
SetupLoadOptionJumpTable:
	.incbin "includes/generated/v7_transplant_SetupLoadOptionJumpTable.bin"
SetupLoadInvalidIndex:
	lds32 xhl, 0
	jr MdSetupLoad_Epilogue
	lda_24 xhl, (0x00ffc0)
	jr MdSetupLoad_Epilogue
	lds32 xhl, 1

MdSetupLoad_Epilogue:
	pop xiz
	lda xsp, (xsp + 16)
	ret

; End of Computer Interface Config routines

