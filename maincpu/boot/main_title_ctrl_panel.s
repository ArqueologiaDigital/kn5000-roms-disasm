; =============================================================================
; Main Title & System Initialization
; =============================================================================
;
; System initialization sequence (graphics, event queue, timers,
; object table, LCD power-on) and the main title screen UI event
; loop. Entry point after boot completes.
; =============================================================================

;==================== (guessed) end of floppy routines =========================


CheckTitleFunc:
	lds32 xhl, 0
	ret

LABEL_F9800F:
	call InitializeGraphics
	call InitializeEventQueue
	call InitializeTimer
	call InitializeObjectTable
	call LcdOn
	ld xwa, 0x1A00000
	ld xbc, 0x1E0009E
	lds32 xde, 1
	call PostEvent
	lds32 xwa, 0
	ld xbc, 0x1C00001
	lds32 xde, 0
	call PostEvent
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00014
	ld xde, 0x1800001
	call PostEvent
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00016
	ld xde, 0x1A000EF
	jp PostEvent

LABEL_F98066:
	stdi8 32578, 35
	ret

LABEL_F9806C:
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 0
	call PostEvent
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0000A
	lds32 xde, 0
	call PostEvent
	lds wa, 0
	call SetNeedUpdate
	call DispatchEvent
	lds wa, 1

LABEL_F98098:
	call SetNeedUpdate
	call UpdateScreen

LABEL_F980A0:
	lds32 xwa, 1
	addm32_24 0x027496, xwa
	lds wa, 2
	call TaskSched_WaitForEvent
	lds wa, 0
	call SetNeedUpdate
	call INTTR4_BytecodeSnippet
	cps l, 0
	jr z, LABEL_F980A0

	call LABEL_FA9F45
	call DispatchEvent
	call PostTitle_Function
	cps hl, 0
	jr z, LABEL_F980EA

	calr SleepMainTask
	lds32 xwa, 0
	ld xbc, 0x1C00000
	lds32 xde, 0
	call DirmdEmulator_Entry
	lds wa, 1
	call SetNeedUpdate
	call UpdateScreen
	calr WakeUpMainTask
	jr LABEL_F980A0

LABEL_F980EA:
	lds wa, 1
	jr LABEL_F98098

MainTitle_PrepareAndDispatch:
	call MainDispatchEvent
	ld xwa, 0x1400001
	ld xbc, 0x1E000BB
	lds32 xde, 0
	jrl MainTitleControl
	push xiz
	ldda8 a, 49280
	ldda8 e, 49277
	cp a, 0xAA
	jrl z, LABEL_F983C1
	cp a, 0xA8
	jrl z, LABEL_F9838B
	cp a, 0xA9
	jrl nz, UIEvent_Epilogue
	cp e, 0x10
	jrl ugt, CtrlPanel_HandlePortCommands
	lds32 xiz, 0
	ldfr_berp E, 0xF8
	cp e, 0xE
	jr nz, SndParam_SendDiskMenuEvents
	ldda8 e, 49279
	ld a, e
	and a, 0x3
	jr z, SndParam_SendDiskMenuEvents
	ldda8 c, 49278
	ld a, c
	and a, 0x3
	cps a, 3
	jr nz, LABEL_F98150
	lds32 xwa, 3
	lds bc, 5
	lds de, 4
	call SoundParam_NotifyChange
	jr SndParam_SendDiskMenuEvents

LABEL_F98150:
	and e, c
	bit 1, e
	jr z, LABEL_F9815F
	lds32 xwa, 3
	lds bc, 1
	lds de, 4
	jr LABEL_F9816B

LABEL_F9815F:
	bit 0, e
	jr z, SndParam_SendDiskMenuEvents
	lds32 xwa, 3
	ldw bc, 0xFFFF
	lds de, 4

LABEL_F9816B:
	call SndParam_LookupByKey

SndParam_SendDiskMenuEvents:
	ldda8 c, 49279
	ldda8 a, 49278
	and a, c
	ld xde, xiz
	bit 1, a
	jr z, LABEL_F981DC
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00008
	call ApPostEvent
	ld xde, xiz
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00007
	call DeleteSpecificEvent
	ld xde, xiz
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00007
	call ApPostEvent
	ld xde, xiz
	ld xwa, xde
	sll xwa, 2
	ld xbc, 0xEA9966
	add xbc, xwa
	ld xwa, (xbc)
	ordm32_24 160922, xwa
	ld xwa, (xbc)
	andda32_24 xwa, 160926
	jr z, CtrlPanel_ProcessButtonPress
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00030
	call ApPostEvent
	jr CtrlPanel_ProcessButtonPress

LABEL_F981DC:
	bit 1, c
	jr z, CtrlPanel_ProcessButtonPress
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00009
	call ApPostEvent
	ld xwa, xiz
	sll xwa, 2
	ld xbc, 0xEA9966
	add xbc, xwa
	ld xwa, (xbc)
	cpl wa
	cpl_werp 0xE2
	anddm32_24 160922, xwa

CtrlPanel_ProcessButtonPress:
	ldda8 c, 49279
	ldda8 a, 49278
	and a, c
	ld xde, xiz
	set 7, de
	bit 0, a
	jr z, LABEL_F9827D
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00008
	call ApPostEvent
	ld xde, xiz
	set 7, de
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00007
	call DeleteSpecificEvent
	ld xde, xiz
	set 7, de
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00007
	call ApPostEvent
	ld xde, xiz
	ld xwa, xde
	sll xwa, 2
	ld xbc, 0xEA9966
	add xbc, xwa
	ld xwa, (xbc)
	ordm32_24 160926, xwa
	ld xwa, (xbc)
	andda32_24 xwa, 160922
	jr z, CtrlPanel_DispatchCombinedState
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00030
	call ApPostEvent
	jr CtrlPanel_DispatchCombinedState

LABEL_F9827D:
	bit 0, c
	jr z, CtrlPanel_DispatchCombinedState
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00009
	call ApPostEvent
	ld xwa, xiz
	sll xwa, 2
	ld xbc, 0xEA9966
	add xbc, xwa
	ld xwa, (xbc)
	cpl wa
	cpl_werp 0xE2
	anddm32_24 160926, xwa

CtrlPanel_DispatchCombinedState:
	ld32_24 xwa, 0x02749e
	andda32_24 xwa, 160922
	st32_24 0x0274a2, xwa
	cp xwa, 0x1100
	jr z, LABEL_F98308
	cp xwa, 0xA1
	jr z, LABEL_F982F3
	cp xwa, 0x91
	jr z, LABEL_F982E2
	cp xwa, 0x89
	jr nz, CtrlPanel_HandlePortCommands
	lds32 xwa, 7
	ld xbc, 0x1C00001
	lds32 xde, 0
	jr LABEL_F98302

LABEL_F982E2:
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00015
	ld xde, 0x1A00000
	jr LABEL_F98302

LABEL_F982F3:
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00016
	ld xde, 0x1A000F0

LABEL_F98302:
	call ApPostEvent
	jr CtrlPanel_HandlePortCommands

LABEL_F98308:
	call Get_Firmware_Version
	cp l, 0xFF
	call_24 z, 0xFAF030

CtrlPanel_HandlePortCommands:
	cpdi8 49277, 32
	jr nz, LABEL_F9834A
	cpdi8 49278, 0
	jr z, LABEL_F9834A
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0003B
	call DeleteEvent
	lds32 xde, 0
	ldda8 e, 49278
	add xde, 0x1800000
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0003B
	call ApPostEvent

LABEL_F9834A:
	cpdi8 49277, 33
	jrl nz, UIEvent_Epilogue
	cpdi8 49278, 0
	jrl z, UIEvent_Epilogue
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0001F
	call DeleteEvent
	ldda8 a, 49278
	add a, 0x10
	exts wa
	sla wa, 2
	lda_24 xbc, 0xea98e2
	ld_sril3 XDE, 0x07, 0xE4, 0xE0
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0001F
	jrl UIEvent_DispatchAndReturn

LABEL_F9838B:
	cps e, 3
	jrl nz, LABEL_F9842B
	ldda8 c, 49279
	ld a, c
	andda8 a, 49278
	bit 0, a
	jr z, LABEL_F983B9
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009B
	lds32 xde, 0
	call ApPostEvent
	lds32 xwa, 1
	ordm32_24 160912, xwa
	jrl UIEvent_Epilogue

LABEL_F983B9:
	bit 0, c
	jr nz, LABEL_F98424
	jrl UIEvent_Epilogue

LABEL_F983C1:
	cp e, 0x11
	jrl z, LABEL_F98661
	ldda8 c, 49279
	ld a, c
	andda8 a, 49278
	cps e, 1
	jrl z, LABEL_F985CB
	cp e, 0x15
	jrl z, LABEL_F9856E
	cps e, 4
	jrl z, LABEL_F98513
	cp e, 0xE
	jrl z, LABEL_F98480
	cp e, 0x12
	jr z, LABEL_F98457
	cp e, 0xF
	jr z, LABEL_F9842E
	cps e, 5
	jrl nz, UIEvent_Epilogue
	ldda8 a, 49279
	andda8 a, 49278
	bit 0, a
	jrl z, UIEvent_Epilogue
	bit 1, a
	jrl z, UIEvent_Epilogue
	ld32_24 xwa, 0x027490
	cp xwa, 0x1
	jrl nz, UIEvent_Epilogue
	call Get_Firmware_Version
	cp l, 0xFF
	call_24 z, 0xFAF030

LABEL_F98424:
	lds32 xwa, 0
	st32_24 0x027490, xwa

LABEL_F9842B:
	jrl UIEvent_Epilogue

LABEL_F9842E:
	bit 7, a
	jr z, LABEL_F98442
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E000A5
	lds32 xde, 0
	jrl UIEvent_DispatchAndReturn

LABEL_F98442:
	bit 7, c
	jrl z, UIEvent_Epilogue
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E000A6
	lds32 xde, 0
	jrl UIEvent_DispatchAndReturn

LABEL_F98457:
	bit 0, a
	jr z, LABEL_F9846B
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E000A5
	lds32 xde, 1
	jrl UIEvent_DispatchAndReturn

LABEL_F9846B:
	bit 0, c
	jrl z, UIEvent_Epilogue
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E000A6
	lds32 xde, 1
	jrl UIEvent_DispatchAndReturn

LABEL_F98480:
	bit 3, a
	jr z, LABEL_F98493
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E000A5
	lds32 xde, 2
	jr LABEL_F984A4

LABEL_F98493:
	bit 3, c
	jr z, LABEL_F984A8
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E000A6
	lds32 xde, 2

LABEL_F984A4:
	call ApPostEvent

LABEL_F984A8:
	ldda8 c, 49279
	ld a, c
	andda8 a, 49278
	bit 2, a
	jr z, LABEL_F984C5
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E000A5
	lds32 xde, 3
	jr LABEL_F984D6

LABEL_F984C5:
	bit 2, c
	jr z, LABEL_F984DA
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E000A6
	lds32 xde, 3

LABEL_F984D6:
	call ApPostEvent

LABEL_F984DA:
	ldda8 c, 49279
	ld a, c
	andda8 a, 49278
	bit 4, a
	jr z, LABEL_F984FB
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E000A5
	ld xde, 0x9
	jrl UIEvent_DispatchAndReturn

LABEL_F984FB:
	bit 4, c
	jrl z, UIEvent_Epilogue
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E000A6
	ld xde, 0x9
	jrl UIEvent_DispatchAndReturn

LABEL_F98513:
	bit 4, a
	jr z, LABEL_F98526
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E000A5
	lds32 xde, 4
	jr LABEL_F98537

LABEL_F98526:
	bit 4, c
	jr z, LABEL_F9853B
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E000A6
	lds32 xde, 4

LABEL_F98537:
	call ApPostEvent

LABEL_F9853B:
	ldda8 c, 49279
	ld a, c
	andda8 a, 49278
	bit 5, a
	jr z, LABEL_F98559
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E000A5
	lds32 xde, 5
	jrl UIEvent_DispatchAndReturn

LABEL_F98559:
	bit 5, c
	jrl z, UIEvent_Epilogue
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E000A6
	lds32 xde, 5
	jrl UIEvent_DispatchAndReturn

LABEL_F9856E:
	bit 5, a
	jr z, LABEL_F9859C
	call GetAprStatus_Entry
	cps l, 0
	jr z, LABEL_F9858D
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E000A5
	ld xde, 0xB
	jrl UIEvent_DispatchAndReturn

LABEL_F9858D:
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E000A5
	lds32 xde, 6
	jrl UIEvent_DispatchAndReturn

LABEL_F9859C:
	bit 5, c
	jrl z, UIEvent_Epilogue
	call GetAprStatus_Entry
	cps l, 0
	jr z, LABEL_F985BC
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E000A6
	ld xde, 0xB
	jrl UIEvent_DispatchAndReturn

LABEL_F985BC:
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E000A6
	lds32 xde, 6
	jrl UIEvent_DispatchAndReturn

LABEL_F985CB:
	bit 1, a
	jr z, LABEL_F985DE
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E000A5
	lds32 xde, 7
	jr LABEL_F985EF

LABEL_F985DE:
	bit 1, c
	jr z, LABEL_F985F3
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E000A6
	lds32 xde, 7

LABEL_F985EF:
	call ApPostEvent

LABEL_F985F3:
	ldda8 c, 49279
	ld a, c
	andda8 a, 49278
	bit 5, a
	jr z, LABEL_F98613
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E000A5
	ld xde, 0x8
	jr LABEL_F98627

LABEL_F98613:
	bit 5, c
	jr z, LABEL_F9862B
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E000A6
	ld xde, 0x8

LABEL_F98627:
	call ApPostEvent

LABEL_F9862B:
	ldda8 c, 49279
	ld a, c
	andda8 a, 49278
	bit 6, a
	jr z, LABEL_F9864B
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E000A5
	ld xde, 0x8
	jr UIEvent_DispatchAndReturn

LABEL_F9864B:
	bit 6, c
	jr z, UIEvent_Epilogue
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E000A6
	ld xde, 0x8
	jr UIEvent_DispatchAndReturn

LABEL_F98661:
	ldda8 c, 49279
	ld a, c
	andda8 a, 49278
	jr z, LABEL_F9867E
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E000A5
	ld xde, 0xA
	jr UIEvent_DispatchAndReturn

LABEL_F9867E:
	cps c, 0
	jr z, UIEvent_Epilogue
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E000A6
	ld xde, 0xA

UIEvent_DispatchAndReturn:
	call ApPostEvent

UIEvent_Epilogue:
	pop xiz
	ret
