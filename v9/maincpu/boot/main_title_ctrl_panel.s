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

MainTitle_InitGraphicsAndEvents:
	call InitializeGraphics
	call InitializeEventQueue
	call InitializeTimer
	call InitializeObjectTable
	call LcdOn
	ld xwa, 0x1a00000
	ld xbc, 0x1e0009e
	lds32 xde, 1
	call PostEvent
	lds32 xwa, 0
	ld xbc, 0x1c00001
	lds32 xde, 0
	call PostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c00014
	ld xde, 0x1800001
	call PostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c00016
	ld xde, 0x1a000ef
	jp PostEvent

MainTitle_SetBootFlag:
	stdi8 0x7f42, 35
	ret

MainTitle_TeardownAndLoop:
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 0
	call PostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c0000a
	lds32 xde, 0
	call PostEvent
	lds wa, 0
	call SetNeedUpdate
	call DispatchEvent
	lds wa, 1

MainTitle_UpdateAndRefresh:
	call SetNeedUpdate
	call UpdateScreen

MainTitle_EventLoop:
	lds32 xwa, 1
	addl_da 0x027496, xwa
	lds wa, 2
	call TaskSched_WaitForEvent
	lds wa, 0
	call SetNeedUpdate
	call INTTR4_BytecodeSnippet
	cps l, 0
	jr z, MainTitle_EventLoop

	call RootContext_InitEventQueue
	call DispatchEvent
	call PostTitle_Function
	cps hl, 0
	jr z, MainTitle_EventLoopSkipInit

	calr SleepMainTask
	lds32 xwa, 0
	ld xbc, 0x1c00000
	lds32 xde, 0
	call DirmdEmulator_Entry
	lds wa, 1
	call SetNeedUpdate
	call UpdateScreen
	calr WakeUpMainTask
	jr MainTitle_EventLoop

MainTitle_EventLoopSkipInit:
	lds wa, 1
	jr MainTitle_UpdateAndRefresh

MainTitle_PrepareAndDispatch:
	call MainDispatchEvent
	ld xwa, 0x1400001
	ld xbc, 0x1e000bb
	lds32 xde, 0
	jrl MainTitleControl
	push xiz
	ldb_d8 a, 0xc080
	ldb_d8 e, 0xc07d
	cp a, 0xaa
	jrl z, CtrlPanel_EventType_AA
	cp a, 0xa8
	jrl z, CtrlPanel_EventType_A8
	cp a, 0xa9
	jrl nz, UIEvent_Epilogue
	cp e, 0x10
	jrl ugt, CtrlPanel_HandlePortCommands
	lds32 xiz, 0
	ldb_erp E, 0xf8
	cp e, 0xe
	jr nz, SndParam_SendDiskMenuEvents
	ldb_d8 e, 0xc07f
	ld a, e
	and a, 0x3
	jr z, SndParam_SendDiskMenuEvents
	ldb_d8 c, 0xc07e
	ld a, c
	and a, 0x3
	cps a, 3
	jr nz, CtrlPanel_HandleSingleBit
	lds32 xwa, 3
	lds bc, 5
	lds de, 4
	call SoundParam_NotifyChange
	jr SndParam_SendDiskMenuEvents

CtrlPanel_HandleSingleBit:
	and e, c
	bit 1, e
	jr z, CtrlPanel_HandleBit1SndParam
	lds32 xwa, 3
	lds bc, 1
	lds de, 4
	jr CtrlPanel_DispatchSndParamLookup

CtrlPanel_HandleBit1SndParam:
	bit 0, e
	jr z, SndParam_SendDiskMenuEvents
	lds32 xwa, 3
	ldw bc, 0xffff
	lds de, 4

CtrlPanel_DispatchSndParamLookup:
	call SndParam_LookupByKey

SndParam_SendDiskMenuEvents:
	ldb_d8 c, 0xc07f
	ldb_d8 a, 0xc07e
	and a, c
	ld xde, xiz
	bit 1, a
	jr z, CtrlPanel_CheckDiskMenuRelease
	ld xwa, 0xffffffff
	ld xbc, 0x1c00008
	call ApPostEvent
	ld xde, xiz
	ld xwa, 0xffffffff
	ld xbc, 0x1c00007
	call DeleteSpecificEvent
	ld xde, xiz
	ld xwa, 0xffffffff
	ld xbc, 0x1c00007
	call ApPostEvent
	ld xde, xiz
	ld xwa, xde
	sll xwa, 2
	ld xbc, DiskWarning_ConfirmStrings_0xCBA
	add xbc, xwa
	ld xwa, (xbc)
	ordm32_24 0x02749a, xwa
	ld xwa, (xbc)
	andda32_24 xwa, 0x02749e
	jr z, CtrlPanel_ProcessButtonPress
	ld xwa, 0xffffffff
	ld xbc, 0x1c00030
	call ApPostEvent
	jr CtrlPanel_ProcessButtonPress

CtrlPanel_CheckDiskMenuRelease:
	bit 1, c
	jr z, CtrlPanel_ProcessButtonPress
	ld xwa, 0xffffffff
	ld xbc, 0x1c00009
	call ApPostEvent
	ld xwa, xiz
	sll xwa, 2
	ld xbc, DiskWarning_ConfirmStrings_0xCBA
	add xbc, xwa
	ld xwa, (xbc)
	cpl wa
	cplw_erp 0xe2
	anddm32_24 0x02749a, xwa

CtrlPanel_ProcessButtonPress:
	ldb_d8 c, 0xc07f
	ldb_d8 a, 0xc07e
	and a, c
	ld xde, xiz
	set 7, de
	bit 0, a
	jr z, CtrlPanel_CheckButtonRelease
	ld xwa, 0xffffffff
	ld xbc, 0x1c00008
	call ApPostEvent
	ld xde, xiz
	set 7, de
	ld xwa, 0xffffffff
	ld xbc, 0x1c00007
	call DeleteSpecificEvent
	ld xde, xiz
	set 7, de
	ld xwa, 0xffffffff
	ld xbc, 0x1c00007
	call ApPostEvent
	ld xde, xiz
	ld xwa, xde
	sll xwa, 2
	ld xbc, DiskWarning_ConfirmStrings_0xCBA
	add xbc, xwa
	ld xwa, (xbc)
	ordm32_24 0x02749e, xwa
	ld xwa, (xbc)
	andda32_24 xwa, 0x02749a
	jr z, CtrlPanel_DispatchCombinedState
	ld xwa, 0xffffffff
	ld xbc, 0x1c00030
	call ApPostEvent
	jr CtrlPanel_DispatchCombinedState

CtrlPanel_CheckButtonRelease:
	bit 0, c
	jr z, CtrlPanel_DispatchCombinedState
	ld xwa, 0xffffffff
	ld xbc, 0x1c00009
	call ApPostEvent
	ld xwa, xiz
	sll xwa, 2
	ld xbc, DiskWarning_ConfirmStrings_0xCBA
	add xbc, xwa
	ld xwa, (xbc)
	cpl wa
	cplw_erp 0xe2
	anddm32_24 0x02749e, xwa

CtrlPanel_DispatchCombinedState:
	ldl_da xwa, 0x02749e
	andda32_24 xwa, 0x02749a
	stl_da 0x0274a2, xwa
	cp xwa, 0x1100
	jr z, CtrlPanel_HandleFirmwareCheck
	cp xwa, 0xa1
	jr z, CtrlPanel_PostScrollEvent
	cp xwa, 0x91
	jr z, CtrlPanel_PostDisplayEvent
	cp xwa, 0x89
	jr nz, CtrlPanel_HandlePortCommands
	lds32 xwa, 7
	ld xbc, 0x1c00001
	lds32 xde, 0
	jr CtrlPanel_PostCombinedEvent

CtrlPanel_PostDisplayEvent:
	ld xwa, 0xffffffff
	ld xbc, 0x1c00015
	ld xde, 0x1a00000
	jr CtrlPanel_PostCombinedEvent

CtrlPanel_PostScrollEvent:
	ld xwa, 0xffffffff
	ld xbc, 0x1c00016
	ld xde, 0x1a000f0

CtrlPanel_PostCombinedEvent:
	call ApPostEvent
	jr CtrlPanel_HandlePortCommands

CtrlPanel_HandleFirmwareCheck:
	call Get_Firmware_Version
	cp l, 0xff
	call_24 z, CaptureLcd

CtrlPanel_HandlePortCommands:
	cpdi8 0xc07d, 32
	jr nz, CtrlPanel_HandleSerialPort
	cpdi8 0xc07e, 0
	jr z, CtrlPanel_HandleSerialPort
	ld xwa, 0xffffffff
	ld xbc, 0x1c0003b
	call DeleteEvent
	lds32 xde, 0
	ldb_d8 e, 0xc07e
	add xde, 0x1800000
	ld xwa, 0xffffffff
	ld xbc, 0x1c0003b
	call ApPostEvent

CtrlPanel_HandleSerialPort:
	cpdi8 0xc07d, 33
	jrl nz, UIEvent_Epilogue
	cpdi8 0xc07e, 0
	jrl z, UIEvent_Epilogue
	ld xwa, 0xffffffff
	ld xbc, 0x1c0001f
	call DeleteEvent
	ldb_d8 a, 0xc07e
	add a, 0x10
	exts wa
	sla wa, 2
	lda_24 xbc, DiskWarning_ConfirmStrings_0xC36
	ld_sril3 XDE, 0x07, 0xe4, 0xe0
	ld xwa, 0xffffffff
	ld xbc, 0x1c0001f
	jrl UIEvent_DispatchAndReturn

CtrlPanel_EventType_A8:
	cps e, 3
	jrl nz, CtrlPanel_AA_Epilogue
	ldb_d8 c, 0xc07f
	ld a, c
	andda8 a, 0xc07e
	bit 0, a
	jr z, CtrlPanel_A8_CheckRelease
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009b
	lds32 xde, 0
	call ApPostEvent
	lds32 xwa, 1
	ordm32_24 0x027490, xwa
	jrl UIEvent_Epilogue

CtrlPanel_A8_CheckRelease:
	bit 0, c
	jr nz, CtrlPanel_ClearStateVar
	jrl UIEvent_Epilogue

CtrlPanel_EventType_AA:
	cp e, 0x11
	jrl z, CtrlPanel_AA_PanelEvent_11
	ldb_d8 c, 0xc07f
	ld a, c
	andda8 a, 0xc07e
	cps e, 1
	jrl z, CtrlPanel_AA_PanelEvent_01_Bit1
	cp e, 0x15
	jrl z, CtrlPanel_AA_PanelEvent_15
	cps e, 4
	jrl z, CtrlPanel_AA_PanelEvent_04_Bit4
	cp e, 0xe
	jrl z, CtrlPanel_AA_PanelEvent_0E_Bit3
	cp e, 0x12
	jr z, CtrlPanel_AA_PanelEvent_12
	cp e, 0xf
	jr z, CtrlPanel_AA_PanelEvent_0F
	cps e, 5
	jrl nz, UIEvent_Epilogue
	ldb_d8 a, 0xc07f
	andda8 a, 0xc07e
	bit 0, a
	jrl z, UIEvent_Epilogue
	bit 1, a
	jrl z, UIEvent_Epilogue
	ldl_da xwa, 0x027490
	cp xwa, 0x1
	jrl nz, UIEvent_Epilogue
	call Get_Firmware_Version
	cp l, 0xff
	call_24 z, CaptureLcd

CtrlPanel_ClearStateVar:
	lds32 xwa, 0
	stl_da 0x027490, xwa

CtrlPanel_AA_Epilogue:
	jrl UIEvent_Epilogue

CtrlPanel_AA_PanelEvent_0F:
	bit 7, a
	jr z, CtrlPanel_AA_0F_Release
	ld xwa, 0xffffffff
	ld xbc, 0x1e000a5
	lds32 xde, 0
	jrl UIEvent_DispatchAndReturn

CtrlPanel_AA_0F_Release:
	bit 7, c
	jrl z, UIEvent_Epilogue
	ld xwa, 0xffffffff
	ld xbc, 0x1e000a6
	lds32 xde, 0
	jrl UIEvent_DispatchAndReturn

CtrlPanel_AA_PanelEvent_12:
	bit 0, a
	jr z, CtrlPanel_AA_12_Release
	ld xwa, 0xffffffff
	ld xbc, 0x1e000a5
	lds32 xde, 1
	jrl UIEvent_DispatchAndReturn

CtrlPanel_AA_12_Release:
	bit 0, c
	jrl z, UIEvent_Epilogue
	ld xwa, 0xffffffff
	ld xbc, 0x1e000a6
	lds32 xde, 1
	jrl UIEvent_DispatchAndReturn

CtrlPanel_AA_PanelEvent_0E_Bit3:
	bit 3, a
	jr z, CtrlPanel_AA_0E_Bit3Release
	ld xwa, 0xffffffff
	ld xbc, 0x1e000a5
	lds32 xde, 2
	jr CtrlPanel_AA_0E_PostAndContinue

CtrlPanel_AA_0E_Bit3Release:
	bit 3, c
	jr z, CtrlPanel_AA_PanelEvent_0E_Bit2
	ld xwa, 0xffffffff
	ld xbc, 0x1e000a6
	lds32 xde, 2

CtrlPanel_AA_0E_PostAndContinue:
	call ApPostEvent

CtrlPanel_AA_PanelEvent_0E_Bit2:
	ldb_d8 c, 0xc07f
	ld a, c
	andda8 a, 0xc07e
	bit 2, a
	jr z, CtrlPanel_AA_0E_Bit2Release
	ld xwa, 0xffffffff
	ld xbc, 0x1e000a5
	lds32 xde, 3
	jr CtrlPanel_AA_0E_Bit2Post

CtrlPanel_AA_0E_Bit2Release:
	bit 2, c
	jr z, CtrlPanel_AA_PanelEvent_0E_Bit4
	ld xwa, 0xffffffff
	ld xbc, 0x1e000a6
	lds32 xde, 3

CtrlPanel_AA_0E_Bit2Post:
	call ApPostEvent

CtrlPanel_AA_PanelEvent_0E_Bit4:
	ldb_d8 c, 0xc07f
	ld a, c
	andda8 a, 0xc07e
	bit 4, a
	jr z, CtrlPanel_AA_0E_Bit4Release
	ld xwa, 0xffffffff
	ld xbc, 0x1e000a5
	ld xde, 0x9
	jrl UIEvent_DispatchAndReturn

CtrlPanel_AA_0E_Bit4Release:
	bit 4, c
	jrl z, UIEvent_Epilogue
	ld xwa, 0xffffffff
	ld xbc, 0x1e000a6
	ld xde, 0x9
	jrl UIEvent_DispatchAndReturn

CtrlPanel_AA_PanelEvent_04_Bit4:
	bit 4, a
	jr z, CtrlPanel_AA_04_Bit4Release
	ld xwa, 0xffffffff
	ld xbc, 0x1e000a5
	lds32 xde, 4
	jr CtrlPanel_AA_04_PostAndContinue

CtrlPanel_AA_04_Bit4Release:
	bit 4, c
	jr z, CtrlPanel_AA_PanelEvent_04_Bit5
	ld xwa, 0xffffffff
	ld xbc, 0x1e000a6
	lds32 xde, 4

CtrlPanel_AA_04_PostAndContinue:
	call ApPostEvent

CtrlPanel_AA_PanelEvent_04_Bit5:
	ldb_d8 c, 0xc07f
	ld a, c
	andda8 a, 0xc07e
	bit 5, a
	jr z, CtrlPanel_AA_04_Bit5Release
	ld xwa, 0xffffffff
	ld xbc, 0x1e000a5
	lds32 xde, 5
	jrl UIEvent_DispatchAndReturn

CtrlPanel_AA_04_Bit5Release:
	bit 5, c
	jrl z, UIEvent_Epilogue
	ld xwa, 0xffffffff
	ld xbc, 0x1e000a6
	lds32 xde, 5
	jrl UIEvent_DispatchAndReturn

CtrlPanel_AA_PanelEvent_15:
	bit 5, a
	jr z, CtrlPanel_AA_15_Release
	call GetAprStatus_Entry
	cps l, 0
	jr z, CtrlPanel_AA_15_AprInactive
	ld xwa, 0xffffffff
	ld xbc, 0x1e000a5
	ld xde, 0xb
	jrl UIEvent_DispatchAndReturn

CtrlPanel_AA_15_AprInactive:
	ld xwa, 0xffffffff
	ld xbc, 0x1e000a5
	lds32 xde, 6
	jrl UIEvent_DispatchAndReturn

CtrlPanel_AA_15_Release:
	bit 5, c
	jrl z, UIEvent_Epilogue
	call GetAprStatus_Entry
	cps l, 0
	jr z, CtrlPanel_AA_15_ReleaseAprInactive
	ld xwa, 0xffffffff
	ld xbc, 0x1e000a6
	ld xde, 0xb
	jrl UIEvent_DispatchAndReturn

CtrlPanel_AA_15_ReleaseAprInactive:
	ld xwa, 0xffffffff
	ld xbc, 0x1e000a6
	lds32 xde, 6
	jrl UIEvent_DispatchAndReturn

CtrlPanel_AA_PanelEvent_01_Bit1:
	bit 1, a
	jr z, CtrlPanel_AA_01_Bit1Release
	ld xwa, 0xffffffff
	ld xbc, 0x1e000a5
	lds32 xde, 7
	jr CtrlPanel_AA_01_PostAndContinue

CtrlPanel_AA_01_Bit1Release:
	bit 1, c
	jr z, CtrlPanel_AA_PanelEvent_01_Bit5
	ld xwa, 0xffffffff
	ld xbc, 0x1e000a6
	lds32 xde, 7

CtrlPanel_AA_01_PostAndContinue:
	call ApPostEvent

CtrlPanel_AA_PanelEvent_01_Bit5:
	ldb_d8 c, 0xc07f
	ld a, c
	andda8 a, 0xc07e
	bit 5, a
	jr z, CtrlPanel_AA_01_Bit5Release
	ld xwa, 0xffffffff
	ld xbc, 0x1e000a5
	ld xde, 0x8
	jr CtrlPanel_AA_01_Bit5Post

CtrlPanel_AA_01_Bit5Release:
	bit 5, c
	jr z, CtrlPanel_AA_PanelEvent_01_Bit6
	ld xwa, 0xffffffff
	ld xbc, 0x1e000a6
	ld xde, 0x8

CtrlPanel_AA_01_Bit5Post:
	call ApPostEvent

CtrlPanel_AA_PanelEvent_01_Bit6:
	ldb_d8 c, 0xc07f
	ld a, c
	andda8 a, 0xc07e
	bit 6, a
	jr z, CtrlPanel_AA_01_Bit6Release
	ld xwa, 0xffffffff
	ld xbc, 0x1e000a5
	ld xde, 0x8
	jr UIEvent_DispatchAndReturn

CtrlPanel_AA_01_Bit6Release:
	bit 6, c
	jr z, UIEvent_Epilogue
	ld xwa, 0xffffffff
	ld xbc, 0x1e000a6
	ld xde, 0x8
	jr UIEvent_DispatchAndReturn

CtrlPanel_AA_PanelEvent_11:
	ldb_d8 c, 0xc07f
	ld a, c
	andda8 a, 0xc07e
	jr z, CtrlPanel_AA_11_Release
	ld xwa, 0xffffffff
	ld xbc, 0x1e000a5
	ld xde, 0xa
	jr UIEvent_DispatchAndReturn

CtrlPanel_AA_11_Release:
	cps c, 0
	jr z, UIEvent_Epilogue
	ld xwa, 0xffffffff
	ld xbc, 0x1e000a6
	ld xde, 0xa

UIEvent_DispatchAndReturn:
	call ApPostEvent

UIEvent_Epilogue:
	pop xiz
	ret
