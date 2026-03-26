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
	.incbin "includes/generated/v7_transplant_MainTitle_SetBootFlag.bin"
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
	.incbin "includes/generated/v7_transplant_MainTitle_PrepareAndDispatch.bin"
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
	.incbin "includes/generated/v7_transplant_CtrlPanel_DispatchSndParamLookup.bin"
SndParam_SendDiskMenuEvents:
	.incbin "includes/generated/v7_transplant_SndParam_SendDiskMenuEvents.bin"
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
	anddm32_24 (0x02749a), xwa

CtrlPanel_ProcessButtonPress:
	.incbin "includes/generated/v7_transplant_CtrlPanel_ProcessButtonPress.bin"
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
	anddm32_24 (0x02749e), xwa

CtrlPanel_DispatchCombinedState:
	ldl_da xwa, (0x02749e)
	andda32_24 xwa, (0x02749a)
	stl_da (0x0274a2), xwa
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
	.incbin "includes/generated/v7_transplant_CtrlPanel_HandlePortCommands.bin"
CtrlPanel_HandleSerialPort:
	.incbin "includes/generated/v7_transplant_CtrlPanel_HandleSerialPort.bin"
CtrlPanel_EventType_A8:
	.incbin "includes/generated/v7_transplant_CtrlPanel_EventType_A8.bin"
CtrlPanel_A8_CheckRelease:
	bit 0, c
	jr nz, CtrlPanel_ClearStateVar
	jrl UIEvent_Epilogue

CtrlPanel_EventType_AA:
	.incbin "includes/generated/v7_transplant_CtrlPanel_EventType_AA.bin"
CtrlPanel_ClearStateVar:
	lds32 xwa, 0
	stl_da (0x027490), xwa

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
	.incbin "includes/generated/v7_transplant_CtrlPanel_AA_PanelEvent_0E_Bit2.bin"
CtrlPanel_AA_0E_Bit2Release:
	bit 2, c
	jr z, CtrlPanel_AA_PanelEvent_0E_Bit4
	ld xwa, 0xffffffff
	ld xbc, 0x1e000a6
	lds32 xde, 3

CtrlPanel_AA_0E_Bit2Post:
	call ApPostEvent

CtrlPanel_AA_PanelEvent_0E_Bit4:
	.incbin "includes/generated/v7_transplant_CtrlPanel_AA_PanelEvent_0E_Bit4.bin"
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
	.incbin "includes/generated/v7_transplant_CtrlPanel_AA_PanelEvent_04_Bit5.bin"
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
	.incbin "includes/generated/v7_transplant_CtrlPanel_AA_PanelEvent_01_Bit5.bin"
CtrlPanel_AA_01_Bit5Release:
	bit 5, c
	jr z, CtrlPanel_AA_PanelEvent_01_Bit6
	ld xwa, 0xffffffff
	ld xbc, 0x1e000a6
	ld xde, 0x8

CtrlPanel_AA_01_Bit5Post:
	call ApPostEvent

CtrlPanel_AA_PanelEvent_01_Bit6:
	.incbin "includes/generated/v7_transplant_CtrlPanel_AA_PanelEvent_01_Bit6.bin"
CtrlPanel_AA_01_Bit6Release:
	bit 6, c
	jr z, UIEvent_Epilogue
	ld xwa, 0xffffffff
	ld xbc, 0x1e000a6
	ld xde, 0x8
	jr UIEvent_DispatchAndReturn

CtrlPanel_AA_PanelEvent_11:
	.incbin "includes/generated/v7_transplant_CtrlPanel_AA_PanelEvent_11.bin"
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
