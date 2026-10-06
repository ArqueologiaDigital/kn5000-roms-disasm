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
	ld xhl, 0:i3
	ret

MainTitle_InitGraphicsAndEvents:
	call InitializeGraphics
	call InitializeEventQueue
	call InitializeTimer
	call InitializeObjectTable
	call LcdOn
	ld xwa, TITLE_PS
	ld xbc, EVT_SET_NOT_DRAW_FLAG
	ld xde, 1:i3
	call PostEvent
	ld xwa, 0:i3
	ld xbc, EVT_SHOW
	ld xde, 0:i3
	call PostEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_CHANGE_MODE
	ld xde, NAKA_MODE_MD_NORMAL
	call PostEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_INTERRUPT_TITLE
	ld xde, TITLE_WELCOM
	jp PostEvent

MainTitle_SetBootFlag:
	ld	(GLOBAL_ERROR_CODE:16), 35
	ret
MainTitle_TeardownAndLoop:
	ld xwa, 0xffffffff
	ld xbc, EVT_SET_NOT_DRAW_FLAG
	ld xde, 0:i3
	call PostEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_ALL_PAINT
	ld xde, 0:i3
	call PostEvent
	ld wa, 0:i3
	call SetNeedUpdate
	call DispatchEvent
	ld wa, 1:i3

MainTitle_UpdateAndRefresh:
	call SetNeedUpdate
	call UpdateScreen

MainTitle_EventLoop:
	ld xwa, 1:i3
	add (0x027496:24), xwa
	ld wa, 2:i3
	call TaskSched_WaitForEvent
	ld wa, 0:i3
	call SetNeedUpdate
	call INTTR4_BytecodeSnippet
	cp l, 0:i3
	jr z, MainTitle_EventLoop

	call RootContext_InitEventQueue
	call DispatchEvent
	call PostTitle_Function
	cp hl, 0:i3
	jr z, MainTitle_EventLoopSkipInit

	calr SleepMainTask
	ld xwa, 0:i3
	ld xbc, EVT_NONE
	ld xde, 0:i3
	call DirmdEmulator_Entry
	ld wa, 1:i3
	call SetNeedUpdate
	call UpdateScreen
	calr WakeUpMainTask
	jr MainTitle_EventLoop

MainTitle_EventLoopSkipInit:
	ld wa, 1:i3
	jr MainTitle_UpdateAndRefresh

MainTitle_PrepareAndDispatch:
	call MainDispatchEvent
	ld XWA,NAKA_MAINFUNC_MainTitleControl
	ld XBC,EVT_MAIN_LOOP_COUNT
	ld	xde, 0:i3
	jrl	MainTitleControl
SwbtB3_OnPanelEvent:
	push	xiz
	ld	a, (SWBTWR_EVENT_TYPE:16)
	ld	e, (SWBTWR_PAYLOAD_1:16)
	cp	a, 0xaa
	jrl	z, CtrlPanel_EventType_AA
	cp	a, 0xa8
	jrl	z, CtrlPanel_EventType_A8
	cp	a, 0xa9
	jrl	nz, UIEvent_Epilogue
	cp	e, 0x10
	jrl	ugt, CtrlPanel_HandlePortCommands
	ld	xiz, 0:i3
	ldfr_berp	E, 0xf8
	cp	e, 0xe
	jr	nz, SndParam_SendDiskMenuEvents
	ld	e, (SWBTWR_PAYLOAD_3:16)
	ld	a, e
	and	a, 0x3
	jr	z, SndParam_SendDiskMenuEvents
	ld	c, (SWBTWR_PAYLOAD_2:16)
	ld	a, c
	and	a, 0x3
	cp	a, 3:i3
	jr	nz, CtrlPanel_HandleSingleBit
	ld	xwa, 3:i3
	ld	bc, 5:i3
	ld	de, 4:i3
	call	SoundParam_NotifyChange
	jr	SndParam_SendDiskMenuEvents
CtrlPanel_HandleSingleBit:
	and e, c
	bit 1, e
	jr z, CtrlPanel_HandleBit1SndParam
	ld xwa, 3:i3
	ld bc, 1:i3
	ld de, 4:i3
	jr CtrlPanel_DispatchSndParamLookup

CtrlPanel_HandleBit1SndParam:
	bit 0, e
	jr z, SndParam_SendDiskMenuEvents
	ld xwa, 3:i3
	ldw bc, 0xffff
	ld de, 4:i3

CtrlPanel_DispatchSndParamLookup:
	call	SndParam_LookupByKey
SndParam_SendDiskMenuEvents:
	ld	c, (SWBTWR_PAYLOAD_3:16)
	ld	a, (SWBTWR_PAYLOAD_2:16)
	and	a, c
	ld	xde, xiz
	bit	1, a
	jr	z, CtrlPanel_CheckDiskMenuRelease
	ld	xwa, 0xffffffff
	ld	xbc, EVT_SW_ON
	call	ApPostEvent
	ld	xde, xiz
	ld	xwa, 0xffffffff
	ld	xbc, EVT_SW_IN
	call	DeleteSpecificEvent
	ld	xde, xiz
	ld	xwa, 0xffffffff
	ld	xbc, EVT_SW_IN
	call	ApPostEvent
	ld	xde, xiz
	ld	xwa, xde
	sll	xwa, 2
	ld	xbc, SndParam_SendDiskMenuEvents_Data
	add	xbc, xwa
	ld	xwa, (xbc)
	or	(TRANSITION_PROGRESS:24), xwa
	ld	xwa, (xbc)
	and	xwa, (TRANSITION_TIMER:24)
	jr	z, CtrlPanel_ProcessButtonPress
	ld	xwa, 0xffffffff
	ld	xbc, EVT_SW_BOTH
	call	ApPostEvent
	jr	CtrlPanel_ProcessButtonPress
CtrlPanel_CheckDiskMenuRelease:
	bit 1, c
	jr z, CtrlPanel_ProcessButtonPress
	ld xwa, 0xffffffff
	ld xbc, EVT_SW_OFF
	call ApPostEvent
	ld xwa, xiz
	sll xwa, 2
	ld xbc, SndParam_SendDiskMenuEvents_Data
	add xbc, xwa
	ld xwa, (xbc)
	cpl wa
	cplw_erp 0xe2
	and (TRANSITION_PROGRESS:24), xwa

CtrlPanel_ProcessButtonPress:
	ld	c, (SWBTWR_PAYLOAD_3:16)
	ld	a, (SWBTWR_PAYLOAD_2:16)
	and	a, c
	ld	xde, xiz
	set	7, de
	bit	0, a
	jr	z, CtrlPanel_CheckButtonRelease
	ld	xwa, 0xffffffff
	ld	xbc, EVT_SW_ON
	call	ApPostEvent
	ld	xde, xiz
	set	7, de
	ld	xwa, 0xffffffff
	ld	xbc, EVT_SW_IN
	call	DeleteSpecificEvent
	ld	xde, xiz
	set	7, de
	ld	xwa, 0xffffffff
	ld	xbc, EVT_SW_IN
	call	ApPostEvent
	ld	xde, xiz
	ld	xwa, xde
	sll	xwa, 2
	ld	xbc, SndParam_SendDiskMenuEvents_Data
	add	xbc, xwa
	ld	xwa, (xbc)
	or	(TRANSITION_TIMER:24), xwa
	ld	xwa, (xbc)
	and	xwa, (TRANSITION_PROGRESS:24)
	jr	z, CtrlPanel_DispatchCombinedState
	ld	xwa, 0xffffffff
	ld	xbc, EVT_SW_BOTH
	call	ApPostEvent
	jr	CtrlPanel_DispatchCombinedState
CtrlPanel_CheckButtonRelease:
	bit 0, c
	jr z, CtrlPanel_DispatchCombinedState
	ld xwa, 0xffffffff
	ld xbc, EVT_SW_OFF
	call ApPostEvent
	ld xwa, xiz
	sll xwa, 2
	ld xbc, SndParam_SendDiskMenuEvents_Data
	add xbc, xwa
	ld xwa, (xbc)
	cpl wa
	cplw_erp 0xe2
	and (TRANSITION_TIMER:24), xwa

CtrlPanel_DispatchCombinedState:
	ld xwa, (TRANSITION_TIMER:24)
	and xwa, (TRANSITION_PROGRESS:24)
	ld (TRANSITION_FLAGS:24), xwa
	cp xwa, 0x1100
	jr z, CtrlPanel_HandleFirmwareCheck
	cp xwa, 0xa1
	jr z, CtrlPanel_PostScrollEvent
	cp xwa, 0x91
	jr z, CtrlPanel_PostDisplayEvent
	cp xwa, 0x89
	jr nz, CtrlPanel_HandlePortCommands
	ld xwa, 7:i3
	ld xbc, EVT_SHOW
	ld xde, 0:i3
	jr CtrlPanel_PostCombinedEvent

CtrlPanel_PostDisplayEvent:
	ld xwa, 0xffffffff
	ld xbc, EVT_CHANGE_TITLE
	ld xde, TITLE_PS
	jr CtrlPanel_PostCombinedEvent

CtrlPanel_PostScrollEvent:
	ld xwa, 0xffffffff
	ld xbc, EVT_INTERRUPT_TITLE
	ld xde, TITLE_SOFTVER

CtrlPanel_PostCombinedEvent:
	call ApPostEvent
	jr CtrlPanel_HandlePortCommands

CtrlPanel_HandleFirmwareCheck:
	call Get_Firmware_Version
	cp l, 0xff
	call z, (CaptureLcd:24)
CtrlPanel_HandlePortCommands:
	cp	(SWBTWR_PAYLOAD_1:16), 32
	jr	nz, CtrlPanel_HandleSerialPort
	cp	(SWBTWR_PAYLOAD_2:16), 0
	jr	z, CtrlPanel_HandleSerialPort
	ld	xwa, 4294967295
	ld	xbc, EVT_SW_IN_MODE
	call	DeleteEvent
	ld	xde, 0:i3
	ld	e, (SWBTWR_PAYLOAD_2:16)
	add	xde, NAKA_MODE_MD_PS
	ld	xwa, 4294967295
	ld	xbc, EVT_SW_IN_MODE
	call	ApPostEvent
CtrlPanel_HandleSerialPort:
	cp	(SWBTWR_PAYLOAD_1:16), 33
	jrl	nz, UIEvent_Epilogue
	cp	(SWBTWR_PAYLOAD_2:16), 0
	jrl	z, UIEvent_Epilogue
	ld	xwa, 4294967295
	ld	xbc, EVT_DIAL
	call	DeleteEvent
	ld	a, (SWBTWR_PAYLOAD_2:16)
	add	a, 16
	exts	wa
	sla	wa, 2
	lda	xbc, (CtrlPanel_HandleSerialPort_Data:24)
	ld	xde, (xbc+wa)
	ld	xwa, 4294967295
	ld	xbc, EVT_DIAL
	jrl	UIEvent_DispatchAndReturn
CtrlPanel_EventType_A8:
	cp	e, 3:i3
	jrl	nz, CtrlPanel_AA_Epilogue
	ld	c, (SWBTWR_PAYLOAD_3:16)
	ld	a, c
	and	a, (SWBTWR_PAYLOAD_2:16)
	bit	0, a
	jr	z, CtrlPanel_A8_CheckRelease
	ld	xwa, 4294967295
	ld	xbc, EVT_TOGGLE_HOLD
	ld	xde, 0:i3
	call	ApPostEvent
	ld	xwa, 1:i3
	or	(0x027490:24), xwa
	jrl	UIEvent_Epilogue
CtrlPanel_A8_CheckRelease:
	bit 0, c
	jr nz, CtrlPanel_ClearStateVar
	jrl UIEvent_Epilogue
CtrlPanel_EventType_AA:
	cp	e, 17
	jrl	z, CtrlPanel_AA_PanelEvent_11
	ld	c, (SWBTWR_PAYLOAD_3:16)
	ld	a, c
	and	a, (SWBTWR_PAYLOAD_2:16)
	cp	e, 1:i3
	jrl	z, CtrlPanel_AA_PanelEvent_01_Bit1
	cp	e, 21
	jrl	z, CtrlPanel_AA_PanelEvent_15
	cp	e, 4:i3
	jrl	z, CtrlPanel_AA_PanelEvent_04_Bit4
	cp	e, 14
	jrl	z, CtrlPanel_AA_PanelEvent_0E_Bit3
	cp	e, 18
	jr	z, CtrlPanel_AA_PanelEvent_12
	cp	e, 15
	jr	z, CtrlPanel_AA_PanelEvent_0F
	cp	e, 5:i3
	jrl	nz, UIEvent_Epilogue
	ld	a, (SWBTWR_PAYLOAD_3:16)
	and	a, (SWBTWR_PAYLOAD_2:16)
	bit	0, a
	jrl	z, UIEvent_Epilogue
	bit	1, a
	jrl	z, UIEvent_Epilogue
	ld	xwa, (160912:24)
	cp	xwa, 1
	jrl	nz, UIEvent_Epilogue
	call	Get_Firmware_Version
	cp	l, 255
	call	z, (CaptureLcd:24)
CtrlPanel_ClearStateVar:
	ld xwa, 0:i3
	ld (0x027490:24), xwa

CtrlPanel_AA_Epilogue:
	jrl UIEvent_Epilogue

CtrlPanel_AA_PanelEvent_0F:
	bit 7, a
	jr z, CtrlPanel_AA_0F_Release
	ld xwa, 0xffffffff
	ld xbc, EVT_EASY_SET_ON
	ld xde, 0:i3
	jrl UIEvent_DispatchAndReturn

CtrlPanel_AA_0F_Release:
	bit 7, c
	jrl z, UIEvent_Epilogue
	ld xwa, 0xffffffff
	ld xbc, EVT_EASY_SET_OFF
	ld xde, 0:i3
	jrl UIEvent_DispatchAndReturn

CtrlPanel_AA_PanelEvent_12:
	bit 0, a
	jr z, CtrlPanel_AA_12_Release
	ld xwa, 0xffffffff
	ld xbc, EVT_EASY_SET_ON
	ld xde, 1:i3
	jrl UIEvent_DispatchAndReturn

CtrlPanel_AA_12_Release:
	bit 0, c
	jrl z, UIEvent_Epilogue
	ld xwa, 0xffffffff
	ld xbc, EVT_EASY_SET_OFF
	ld xde, 1:i3
	jrl UIEvent_DispatchAndReturn

CtrlPanel_AA_PanelEvent_0E_Bit3:
	bit 3, a
	jr z, CtrlPanel_AA_0E_Bit3Release
	ld xwa, 0xffffffff
	ld xbc, EVT_EASY_SET_ON
	ld xde, 2:i3
	jr CtrlPanel_AA_0E_PostAndContinue

CtrlPanel_AA_0E_Bit3Release:
	bit 3, c
	jr z, CtrlPanel_AA_PanelEvent_0E_Bit2
	ld xwa, 0xffffffff
	ld xbc, EVT_EASY_SET_OFF
	ld xde, 2:i3

CtrlPanel_AA_0E_PostAndContinue:
	call ApPostEvent

CtrlPanel_AA_PanelEvent_0E_Bit2:
	ld	c, (SWBTWR_PAYLOAD_3:16)
	ld	a, c
	and	a, (SWBTWR_PAYLOAD_2:16)
	bit	2, a
	jr	z, CtrlPanel_AA_0E_Bit2Release
	ld	xwa, 4294967295
	ld	xbc, EVT_EASY_SET_ON
	ld	xde, 3:i3
	jr	CtrlPanel_AA_0E_Bit2Post
CtrlPanel_AA_0E_Bit2Release:
	bit 2, c
	jr z, CtrlPanel_AA_PanelEvent_0E_Bit4
	ld xwa, 0xffffffff
	ld xbc, EVT_EASY_SET_OFF
	ld xde, 3:i3

CtrlPanel_AA_0E_Bit2Post:
	call ApPostEvent

CtrlPanel_AA_PanelEvent_0E_Bit4:
	ld	c, (SWBTWR_PAYLOAD_3:16)
	ld	a, c
	and	a, (SWBTWR_PAYLOAD_2:16)
	bit	4, a
	jr	z, CtrlPanel_AA_0E_Bit4Release
	ld	xwa, 4294967295
	ld	xbc, EVT_EASY_SET_ON
	ld	xde, 9
	jrl	UIEvent_DispatchAndReturn
CtrlPanel_AA_0E_Bit4Release:
	bit 4, c
	jrl z, UIEvent_Epilogue
	ld xwa, 0xffffffff
	ld xbc, EVT_EASY_SET_OFF
	ld xde, 0x9
	jrl UIEvent_DispatchAndReturn

CtrlPanel_AA_PanelEvent_04_Bit4:
	bit 4, a
	jr z, CtrlPanel_AA_04_Bit4Release
	ld xwa, 0xffffffff
	ld xbc, EVT_EASY_SET_ON
	ld xde, 4:i3
	jr CtrlPanel_AA_04_PostAndContinue

CtrlPanel_AA_04_Bit4Release:
	bit 4, c
	jr z, CtrlPanel_AA_PanelEvent_04_Bit5
	ld xwa, 0xffffffff
	ld xbc, EVT_EASY_SET_OFF
	ld xde, 4:i3

CtrlPanel_AA_04_PostAndContinue:
	call ApPostEvent

CtrlPanel_AA_PanelEvent_04_Bit5:
	ld	c, (SWBTWR_PAYLOAD_3:16)
	ld	a, c
	and	a, (SWBTWR_PAYLOAD_2:16)
	bit	5, a
	jr	z, CtrlPanel_AA_04_Bit5Release
	ld	xwa, 4294967295
	ld	xbc, EVT_EASY_SET_ON
	ld	xde, 5:i3
	jrl	UIEvent_DispatchAndReturn
CtrlPanel_AA_04_Bit5Release:
	bit 5, c
	jrl z, UIEvent_Epilogue
	ld xwa, 0xffffffff
	ld xbc, EVT_EASY_SET_OFF
	ld xde, 5:i3
	jrl UIEvent_DispatchAndReturn

CtrlPanel_AA_PanelEvent_15:
	bit 5, a
	jr z, CtrlPanel_AA_15_Release
	call GetAprStatus_Entry
	cp l, 0:i3
	jr z, CtrlPanel_AA_15_AprInactive
	ld xwa, 0xffffffff
	ld xbc, EVT_EASY_SET_ON
	ld xde, 0xb
	jrl UIEvent_DispatchAndReturn

CtrlPanel_AA_15_AprInactive:
	ld xwa, 0xffffffff
	ld xbc, EVT_EASY_SET_ON
	ld xde, 6:i3
	jrl UIEvent_DispatchAndReturn

CtrlPanel_AA_15_Release:
	bit 5, c
	jrl z, UIEvent_Epilogue
	call GetAprStatus_Entry
	cp l, 0:i3
	jr z, CtrlPanel_AA_15_ReleaseAprInactive
	ld xwa, 0xffffffff
	ld xbc, EVT_EASY_SET_OFF
	ld xde, 0xb
	jrl UIEvent_DispatchAndReturn

CtrlPanel_AA_15_ReleaseAprInactive:
	ld xwa, 0xffffffff
	ld xbc, EVT_EASY_SET_OFF
	ld xde, 6:i3
	jrl UIEvent_DispatchAndReturn

CtrlPanel_AA_PanelEvent_01_Bit1:
	bit 1, a
	jr z, CtrlPanel_AA_01_Bit1Release
	ld xwa, 0xffffffff
	ld xbc, EVT_EASY_SET_ON
	ld xde, 7:i3
	jr CtrlPanel_AA_01_PostAndContinue

CtrlPanel_AA_01_Bit1Release:
	bit 1, c
	jr z, CtrlPanel_AA_PanelEvent_01_Bit5
	ld xwa, 0xffffffff
	ld xbc, EVT_EASY_SET_OFF
	ld xde, 7:i3

CtrlPanel_AA_01_PostAndContinue:
	call ApPostEvent

CtrlPanel_AA_PanelEvent_01_Bit5:
	ld	c, (SWBTWR_PAYLOAD_3:16)
	ld	a, c
	and	a, (SWBTWR_PAYLOAD_2:16)
	bit	5, a
	jr	z, CtrlPanel_AA_01_Bit5Release
	ld	xwa, 4294967295
	ld	xbc, EVT_EASY_SET_ON
	ld	xde, 8
	jr	CtrlPanel_AA_01_Bit5Post
CtrlPanel_AA_01_Bit5Release:
	bit 5, c
	jr z, CtrlPanel_AA_PanelEvent_01_Bit6
	ld xwa, 0xffffffff
	ld xbc, EVT_EASY_SET_OFF
	ld xde, 0x8

CtrlPanel_AA_01_Bit5Post:
	call ApPostEvent

CtrlPanel_AA_PanelEvent_01_Bit6:
	ld	c, (SWBTWR_PAYLOAD_3:16)
	ld	a, c
	and	a, (SWBTWR_PAYLOAD_2:16)
	bit	6, a
	jr	z, CtrlPanel_AA_01_Bit6Release
	ld	xwa, 4294967295
	ld	xbc, EVT_EASY_SET_ON
	ld	xde, 8
	jr	UIEvent_DispatchAndReturn
CtrlPanel_AA_01_Bit6Release:
	bit 6, c
	jr z, UIEvent_Epilogue
	ld xwa, 0xffffffff
	ld xbc, EVT_EASY_SET_OFF
	ld xde, 0x8
	jr UIEvent_DispatchAndReturn

CtrlPanel_AA_PanelEvent_11:
	ld	c, (SWBTWR_PAYLOAD_3:16)
	ld	a, c
	and	a, (SWBTWR_PAYLOAD_2:16)
	jr	z, CtrlPanel_AA_11_Release
	ld	xwa, 4294967295
	ld	xbc, EVT_EASY_SET_ON
	ld	xde, 10
	jr	UIEvent_DispatchAndReturn
CtrlPanel_AA_11_Release:
	cp c, 0:i3
	jr z, UIEvent_Epilogue
	ld xwa, 0xffffffff
	ld xbc, EVT_EASY_SET_OFF
	ld xde, 0xa

UIEvent_DispatchAndReturn:
	call ApPostEvent

UIEvent_Epilogue:
	pop xiz
	ret
