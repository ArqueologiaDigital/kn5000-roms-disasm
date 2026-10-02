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
	cp	xbc, EVT_REPAINT
	jr	z, ComputerConnectionTitleExit
	cp	xbc, EVT_PAINT
	jr	z, ComputerConnectionTitleExit
	cp	xbc, EVT_HIDE
	jr	z, ComputerConnectionTitleExit
	cp	xbc, EVT_SHOW
	jr	nz, ComputerConnectionTitleExit
	or	xde, xde
	jr	nz, ComputerConnectionTitleExit
	call	GET_COMPUTER_INTERFACE_SELECTION
	cp	l, 0:i3
	jr	nz, ComputerConnectionTitleExit
	ld	(32422:16), 70
	ld	xwa, 4294967295
	ld	xbc, EVT_INTERRUPT_TITLE
	ld	xde, TITLE_MESAGE
	call	PostEvent
ComputerConnectionTitleExit:
	ld xhl, 0:i3
	ret

MdCmptCnctFunc:
	dec 4, xsp
	push xiz
	ld xhl, xde
	ld xde, xbc
	ld xiz, xwa
	ld xiy, MdCmptCnctFunc_LocalInit
	lda xix, (xsp + 4)
	ldiw
	ldiw
	cp xde, EVT_GET_SMALL_STEP
	jrl z, CmptCnctBlockingReturn
	cp xde, EVT_GET_LARGE_STEP
	jrl z, CmptCnctBlockingReturn
	cp xde, EVT_GET_LSW_OUTPUT
	jrl z, CmptCnctBlockingReturn
	cp xde, EVT_GET_LSW_ADDRESS
	jrl z, CmptCnctInvalidInputReturn
	cp xde, EVT_GET_LSW_STRING
	jr z, CmptCnctDrawConnectionDiagram
	ld xhl, 0:i3
	jrl MdCmptCnct_Epilogue

CmptCnctDrawConnectionDiagram:
	ld	bc, (xhl+4)
	ld	xwa, (xhl+8)
	cp	bc, 2:i3
	jr	z, CmptCnct_DrawDiagram2
	cp	bc, 1:i3
	jr	z, CmptCnct_DrawDiagram1
	cp	bc, 0:i3
	jr	nz, CmptCnct_DrawDiagramDefault
	pushw	MdCmptCnctFunc_LocalInit_Strings@hi16
	pushw	MdCmptCnctFunc_LocalInit_Strings@lo16
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	lda	xwa, (xsp+4)
	pushw	108
	ld	xbc, Bitmap_MIDIConnections_1
	ldw	de, 296
	jr	CmptCnctBitmapDrawComplete
CmptCnct_DrawDiagram1:
	pushw	CmptCnct_DrawDiagram1_Str_KN_as_master@hi16
	pushw	CmptCnct_DrawDiagram1_Str_KN_as_master@lo16
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	lda	xwa, (xsp+4)
	pushw	108
	ld	xbc, Bitmap_MIDIConnections_2
	ldw	de, 296
	jr	CmptCnctBitmapDrawComplete
CmptCnct_DrawDiagram2:
	pushw	CmptCnct_DrawDiagram2_Str_KN_as_slave@hi16
	pushw	CmptCnct_DrawDiagram2_Str_KN_as_slave@lo16
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	lda	xwa, (xsp+4)
	pushw	108
	ld	xbc, Bitmap_MIDIConnections_3
	ldw	de, 296
	jr	CmptCnctBitmapDrawComplete
CmptCnct_DrawDiagramDefault:
	pushw	CmptCnct_DrawDiagramDefault_Str_Error@hi16
	pushw	CmptCnct_DrawDiagramDefault_Str_Error@lo16
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	lda	xwa, (xsp+4)
	pushw	108
	ld	xbc, Bitmap_MIDIConnections_1
	ldw	de, 296
CmptCnctBitmapDrawComplete:
	call DrawBitmapSPFast
	ld xhl, xiz
	jr MdCmptCnct_Epilogue

CmptCnctInvalidInputReturn:
	ld xhl, 0x2c00
	jr MdCmptCnct_Epilogue

CmptCnctBlockingReturn:
	ld xhl, 1:i3

MdCmptCnct_Epilogue:
	pop xiz
	inc 4, xsp
	ret

MdPcgModeFunc:
	push xiz
	ld xiz, xwa
	cp xbc, EVT_GET_SMALL_STEP
	jr z, PcgMode_BlockingReturn
	cp xbc, EVT_GET_LARGE_STEP
	jr z, PcgMode_BlockingReturn
	cp xbc, EVT_GET_LSW_OUTPUT
	jr z, PcgMode_BlockingReturn
	cp xbc, EVT_GET_LSW_ADDRESS
	jr z, PcgMode_InvalidReturn
	cp xbc, EVT_GET_LSW_STRING
	jr z, PcgModeGridEventStart
	ld xhl, 0:i3
	jr MdPcgMode_Epilogue

PcgModeGridEventStart:
	ld xwa, xde
	ld de, (xwa + 4)
	inc 8, xwa
	cp de, 3:i3
	jr z, PcgMode_CopyStrCustom
	ld xbc, (xwa)
	cp de, 1:i3
	jr z, PcgModeDisplayString_Bank1
	cp de, 0:i3
	jr nz, PcgModeDefaultCase
	ld xwa, PcgModeGridEventStart_Str
	jr PcgMode_CopyStrEntry

PcgModeDisplayString_Bank1:
	ld xwa, PcgModeDisplayString_Bank1_Str
	jr PcgMode_CopyStrEntry

PcgMode_CopyStrCustom:
	pushw PcgMode_CopyStrCustom_Str_GM@hi16
	pushw PcgMode_CopyStrCustom_Str_GM@lo16
	ld xwa, (xwa)
	push xwa
	jr PcgMode_CallStrcpy

PcgModeDefaultCase:
	ld xwa, PcgModeDefaultCase_Str

PcgMode_CopyStrEntry:
	push xwa
	push xbc

PcgMode_CallStrcpy:
	call	Free_Compare2
	inc	8, xsp
	ld	xhl, xiz
	jr	MdPcgMode_Epilogue
PcgMode_InvalidReturn:
	ld xhl, 0x2201
	jr MdPcgMode_Epilogue

PcgMode_BlockingReturn:
	ld xhl, 1:i3

MdPcgMode_Epilogue:
	pop xiz
	ret

MdDrumTypeFunc:
	push xiz
	ld xiz, xwa
	cp xbc, EVT_GET_SMALL_STEP
	jr z, DrumType_BlockingReturn
	cp xbc, EVT_GET_LARGE_STEP
	jr z, DrumType_BlockingReturn
	cp xbc, EVT_GET_LSW_OUTPUT
	jr z, DrumType_BlockingReturn
	cp xbc, EVT_GET_LSW_ADDRESS
	jr z, DrumType_InvalidReturn
	cp xbc, EVT_GET_LSW_STRING
	jr z, DrumType_GridEvent
	ld xhl, 0:i3
	jr MdDrumType_Epilogue

DrumType_GridEvent:
	ld xwa, xde
	ld de, (xwa + 4)
	inc 8, xwa
	cp de, 3:i3
	jr z, DrumType_CopyStrCustom
	ld xbc, (xwa)
	cp de, 1:i3
	jr z, DrumType_CopyStrBank1
	cp de, 0:i3
	jr nz, DrumType_CopyStrDefault
	ld xwa, DrumType_GridEvent_Str
	jr DrumType_CopyStrEntry

DrumType_CopyStrBank1:
	ld xwa, DrumType_CopyStrBank1_Str
	jr DrumType_CopyStrEntry

DrumType_CopyStrCustom:
	pushw DrumType_CopyStrCustom_Str_GM@hi16
	pushw DrumType_CopyStrCustom_Str_GM@lo16
	ld xwa, (xwa)
	push xwa
	jr DrumType_CallStrcpy

DrumType_CopyStrDefault:
	ld xwa, DrumType_CopyStrDefault_Str

DrumType_CopyStrEntry:
	push xwa
	push xbc

DrumType_CallStrcpy:
	call	Free_Compare2
	inc	8, xsp
	ld	xhl, xiz
	jr	MdDrumType_Epilogue
DrumType_InvalidReturn:
	ld xhl, 0x2205
	jr MdDrumType_Epilogue

DrumType_BlockingReturn:
	ld xhl, 1:i3

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
	sub xhl, EVT_GET_LARGE_STEP
	cp xhl, 0x0
	jr lt, SetupLoadInvalidIndex
	cp xhl, 0x9
	jr gt, SetupLoadInvalidIndex
	add xhl, xhl
	add xhl, MdSetupLoadFunc_CaseTable
	ld hl, (xhl)
	lda xix, (SetupLoadOptionJumpTable:24)
	jp_ind 8, 0x07, 0xf0, 0xec
SetupLoadOptionJumpTable:
	ld	xwa, (xde+14)
	and	xwa, 2
	sll	xwa, 2
	lda	xbc, (xsp+4)
	add	xbc, xwa
	ld	xwa, (xbc)
	push	xwa
	ld	xwa, (xde+18)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	ld	xhl, xiz
	jr	MdSetupLoad_Epilogue
	ld	xhl, 2:i3
	jr	MdSetupLoad_Epilogue
	ld	xhl, 3:i3
	jr	MdSetupLoad_Epilogue
SetupLoadInvalidIndex:
	ld xhl, 0:i3
	jr MdSetupLoad_Epilogue
	lda xhl, (0x00ffc0:24)
	jr MdSetupLoad_Epilogue
	ld xhl, 1:i3

MdSetupLoad_Epilogue:
	pop xiz
	lda xsp, (xsp + 16)
	ret

; End of Computer Interface Config routines

