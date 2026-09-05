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
	ld xwa, 0x1a00000
	ld xbc, 0x1e0009e
	ld xde, 1:i3
	call PostEvent
	ld xwa, 0:i3
	ld xbc, 0x1c00001
	ld xde, 0:i3
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
	ld	(32422:16), 35
	ret
MainTitle_TeardownAndLoop:
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	ld xde, 0:i3
	call PostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c0000a
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
	ld xbc, 0x1c00000
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
	ld XWA,0x01400001
	ld XBC,0x01e000bb
	.byte 0xea, 0xa8, 0x78, 0xf4, 0x11, 0x3e, 0xc1, 0xe4
	.byte 0xbf, 0x21, 0xc1, 0xe1, 0xbf, 0x25, 0xc9, 0xcf
	.byte 0xaa, 0x76, 0xb1, 0x02, 0xc9, 0xcf, 0xa8, 0x76
	.byte 0x75, 0x02, 0xc9, 0xcf, 0xa9, 0x7e, 0x79, 0x05
	.byte 0xcd, 0xcf, 0x10, 0x7b, 0xf2, 0x01, 0xee, 0xa8
	.byte 0xc7, 0xf8, 0x9d, 0xcd, 0xcf, 0x0e, 0x6e, 0x43
	.byte 0xc1, 0xe3, 0xbf, 0x25, 0xcd, 0x89, 0xc9, 0xcc
	.byte 0x03, 0x66, 0x38, 0xc1, 0xe2, 0xbf, 0x23, 0xcb
	.byte 0x89, 0xc9, 0xcc, 0x03, 0xc9, 0xdb, 0x6e, 0x0c
	.byte 0xe8, 0xab, 0xd9, 0xad, 0xda, 0xac, 0x1d, 0x30
	.byte 0xca, 0xfc, 0x68, 0x1f
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
	call	16567134
SndParam_SendDiskMenuEvents:
	.byte 0xc1, 0xe3, 0xbf, 0x23, 0xc1, 0xe2, 0xbf, 0x21
	.byte 0xcb, 0xc1, 0xee, 0x8a, 0xc9, 0x33, 0x01, 0x66
	.byte 0x5c, 0x40, 0xff, 0xff, 0xff, 0xff, 0x41, 0x08
	.byte 0x00, 0xc0, 0x01, 0x1d, 0x4b, 0x99, 0xfa, 0xee
	.byte 0x8a, 0x40, 0xff, 0xff, 0xff, 0xff, 0x41, 0x07
	.byte 0x00, 0xc0, 0x01, 0x1d, 0xc4, 0x94, 0xfa, 0xee
	.byte 0x8a, 0x40, 0xff, 0xff, 0xff, 0xff, 0x41, 0x07
	.byte 0x00, 0xc0, 0x01, 0x1d, 0x4b, 0x99, 0xfa, 0xee
	.byte 0x8a, 0xea, 0x88, 0xe8, 0xee, 0x02, 0x41, 0x66
	.byte 0x99, 0xea, 0x00, 0xe8, 0x81, 0xa1, 0x20, 0xe2
	.byte 0x9a, 0x74, 0x02, 0xe8, 0xa1, 0x20, 0xe2, 0x9e
	.byte 0x74, 0x02, 0xc0, 0x66, 0x3b, 0x40, 0xff, 0xff
	.byte 0xff, 0xff, 0x41, 0x30, 0x00, 0xc0, 0x01, 0x1d
	.byte 0x4b, 0x99, 0xfa, 0x68, 0x2b
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
	and (0x02749a:24), xwa

CtrlPanel_ProcessButtonPress:
	.byte 0xc1, 0xe3, 0xbf, 0x23, 0xc1, 0xe2, 0xbf, 0x21
	.byte 0xcb, 0xc1, 0xee, 0x8a, 0xda, 0x31, 0x07, 0xc9
	.byte 0x33, 0x00, 0x66, 0x62, 0x40, 0xff, 0xff, 0xff
	.byte 0xff, 0x41, 0x08, 0x00, 0xc0, 0x01, 0x1d, 0x4b
	.byte 0x99, 0xfa, 0xee, 0x8a, 0xda, 0x31, 0x07, 0x40
	.byte 0xff, 0xff, 0xff, 0xff, 0x41, 0x07, 0x00, 0xc0
	.byte 0x01, 0x1d, 0xc4, 0x94, 0xfa, 0xee, 0x8a, 0xda
	.byte 0x31, 0x07, 0x40, 0xff, 0xff, 0xff, 0xff, 0x41
	.byte 0x07, 0x00, 0xc0, 0x01, 0x1d, 0x4b, 0x99, 0xfa
	.byte 0xee, 0x8a, 0xea, 0x88, 0xe8, 0xee, 0x02, 0x41
	.byte 0x66, 0x99, 0xea, 0x00, 0xe8, 0x81, 0xa1, 0x20
	.byte 0xe2, 0x9e, 0x74, 0x02, 0xe8, 0xa1, 0x20, 0xe2
	.byte 0x9a, 0x74, 0x02, 0xc0, 0x66, 0x3b, 0x40, 0xff
	.byte 0xff, 0xff, 0xff, 0x41, 0x30, 0x00, 0xc0, 0x01
	.byte 0x1d, 0x4b, 0x99, 0xfa, 0x68, 0x2b
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
	and (0x02749e:24), xwa

CtrlPanel_DispatchCombinedState:
	ld xwa, (0x02749e:24)
	and xwa, (0x02749a:24)
	ld (0x0274a2:24), xwa
	cp xwa, 0x1100
	jr z, CtrlPanel_HandleFirmwareCheck
	cp xwa, 0xa1
	jr z, CtrlPanel_PostScrollEvent
	cp xwa, 0x91
	jr z, CtrlPanel_PostDisplayEvent
	cp xwa, 0x89
	jr nz, CtrlPanel_HandlePortCommands
	ld xwa, 7:i3
	ld xbc, 0x1c00001
	ld xde, 0:i3
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
	call z, (CaptureLcd:24)
CtrlPanel_HandlePortCommands:
	cp	(49121:16), 32
	jr	nz, 47
	cp	(49122:16), 0
	jr	z, 40
	ld	xwa, 4294967295
	ld	xbc, 29360187
	call	16421979
	ld	xde, 0:i3
	ld	e, (49122:16)
	add	xde, 25165824
	ld	xwa, 4294967295
	ld	xbc, 29360187
	call	16423243
CtrlPanel_HandleSerialPort:
	cp	(49121:16), 33
	jrl	nz, 835
	cp	(49122:16), 0
	jrl	z, 827
	ld	xwa, 4294967295
	ld	xbc, 29360159
	call	16421979
	ld	a, (49122:16)
	add	a, 16
	exts	wa
	sla	wa, 2
	lda	xbc, (15374562:24)
	ld_rrl	xde, xbc, wa
	ld	xwa, 4294967295
	ld	xbc, 29360159
	jrl	774
CtrlPanel_EventType_A8:
	cp	e, 3:i3
	jrl	nz, 155
	ld	c, (49123:16)
	ld	a, c
	and	a, (49122:16)
	bit	0, a
	jr	z, 26
	ld	xwa, 4294967295
	ld	xbc, 31457435
	ld	xde, 0:i3
	call	16423243
	ld	xwa, 1:i3
	.byte 0xe2, 0x90, 0x74, 0x02, 0xe8
	jrl	732
CtrlPanel_A8_CheckRelease:
	bit 0, c
	jr nz, CtrlPanel_ClearStateVar
	jrl UIEvent_Epilogue
CtrlPanel_EventType_AA:
	cp	e, 17
	jrl	z, 666
	ld	c, (49123:16)
	ld	a, c
	and	a, (49122:16)
	cp	e, 1:i3
	jrl	z, 501
	cp	e, 21
	jrl	z, 402
	cp	e, 4:i3
	jrl	z, 306
	cp	e, 14
	jrl	z, 153
	cp	e, 18
	jr	z, 107
	cp	e, 15
	jr	z, 61
	cp	e, 5:i3
	jrl	nz, 671
	ld	a, (49123:16)
	and	a, (49122:16)
	bit	0, a
	jrl	z, 657
	bit	1, a
	jrl	z, 651
	ld	xwa, (160912:24)
	cp	xwa, 1
	jrl	nz, 637
	call	16776933
	cp	l, 255
	.byte 0xf2, 0x23, 0xec, 0xfa, 0xe6
CtrlPanel_ClearStateVar:
	ld xwa, 0:i3
	ld (0x027490:24), xwa

CtrlPanel_AA_Epilogue:
	jrl UIEvent_Epilogue

CtrlPanel_AA_PanelEvent_0F:
	bit 7, a
	jr z, CtrlPanel_AA_0F_Release
	ld xwa, 0xffffffff
	ld xbc, 0x1e000a5
	ld xde, 0:i3
	jrl UIEvent_DispatchAndReturn

CtrlPanel_AA_0F_Release:
	bit 7, c
	jrl z, UIEvent_Epilogue
	ld xwa, 0xffffffff
	ld xbc, 0x1e000a6
	ld xde, 0:i3
	jrl UIEvent_DispatchAndReturn

CtrlPanel_AA_PanelEvent_12:
	bit 0, a
	jr z, CtrlPanel_AA_12_Release
	ld xwa, 0xffffffff
	ld xbc, 0x1e000a5
	ld xde, 1:i3
	jrl UIEvent_DispatchAndReturn

CtrlPanel_AA_12_Release:
	bit 0, c
	jrl z, UIEvent_Epilogue
	ld xwa, 0xffffffff
	ld xbc, 0x1e000a6
	ld xde, 1:i3
	jrl UIEvent_DispatchAndReturn

CtrlPanel_AA_PanelEvent_0E_Bit3:
	bit 3, a
	jr z, CtrlPanel_AA_0E_Bit3Release
	ld xwa, 0xffffffff
	ld xbc, 0x1e000a5
	ld xde, 2:i3
	jr CtrlPanel_AA_0E_PostAndContinue

CtrlPanel_AA_0E_Bit3Release:
	bit 3, c
	jr z, CtrlPanel_AA_PanelEvent_0E_Bit2
	ld xwa, 0xffffffff
	ld xbc, 0x1e000a6
	ld xde, 2:i3

CtrlPanel_AA_0E_PostAndContinue:
	call ApPostEvent

CtrlPanel_AA_PanelEvent_0E_Bit2:
	ld	c, (49123:16)
	ld	a, c
	and	a, (49122:16)
	bit	2, a
	jr	z, 14
	ld	xwa, 4294967295
	ld	xbc, 31457445
	ld	xde, 3:i3
	jr	17
CtrlPanel_AA_0E_Bit2Release:
	bit 2, c
	jr z, CtrlPanel_AA_PanelEvent_0E_Bit4
	ld xwa, 0xffffffff
	ld xbc, 0x1e000a6
	ld xde, 3:i3

CtrlPanel_AA_0E_Bit2Post:
	call ApPostEvent

CtrlPanel_AA_PanelEvent_0E_Bit4:
	ld	c, (49123:16)
	ld	a, c
	and	a, (49122:16)
	bit	4, a
	jr	z, 18
	ld	xwa, 4294967295
	ld	xbc, 31457445
	ld	xde, 9
	jrl	406
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
	ld xde, 4:i3
	jr CtrlPanel_AA_04_PostAndContinue

CtrlPanel_AA_04_Bit4Release:
	bit 4, c
	jr z, CtrlPanel_AA_PanelEvent_04_Bit5
	ld xwa, 0xffffffff
	ld xbc, 0x1e000a6
	ld xde, 4:i3

CtrlPanel_AA_04_PostAndContinue:
	call ApPostEvent

CtrlPanel_AA_PanelEvent_04_Bit5:
	ld	c, (49123:16)
	ld	a, c
	and	a, (49122:16)
	bit	5, a
	jr	z, 15
	ld	xwa, 4294967295
	ld	xbc, 31457445
	ld	xde, 5:i3
	jrl	312
CtrlPanel_AA_04_Bit5Release:
	bit 5, c
	jrl z, UIEvent_Epilogue
	ld xwa, 0xffffffff
	ld xbc, 0x1e000a6
	ld xde, 5:i3
	jrl UIEvent_DispatchAndReturn

CtrlPanel_AA_PanelEvent_15:
	bit 5, a
	jr z, CtrlPanel_AA_15_Release
	call GetAprStatus_Entry
	cp l, 0:i3
	jr z, CtrlPanel_AA_15_AprInactive
	ld xwa, 0xffffffff
	ld xbc, 0x1e000a5
	ld xde, 0xb
	jrl UIEvent_DispatchAndReturn

CtrlPanel_AA_15_AprInactive:
	ld xwa, 0xffffffff
	ld xbc, 0x1e000a5
	ld xde, 6:i3
	jrl UIEvent_DispatchAndReturn

CtrlPanel_AA_15_Release:
	bit 5, c
	jrl z, UIEvent_Epilogue
	call GetAprStatus_Entry
	cp l, 0:i3
	jr z, CtrlPanel_AA_15_ReleaseAprInactive
	ld xwa, 0xffffffff
	ld xbc, 0x1e000a6
	ld xde, 0xb
	jrl UIEvent_DispatchAndReturn

CtrlPanel_AA_15_ReleaseAprInactive:
	ld xwa, 0xffffffff
	ld xbc, 0x1e000a6
	ld xde, 6:i3
	jrl UIEvent_DispatchAndReturn

CtrlPanel_AA_PanelEvent_01_Bit1:
	bit 1, a
	jr z, CtrlPanel_AA_01_Bit1Release
	ld xwa, 0xffffffff
	ld xbc, 0x1e000a5
	ld xde, 7:i3
	jr CtrlPanel_AA_01_PostAndContinue

CtrlPanel_AA_01_Bit1Release:
	bit 1, c
	jr z, CtrlPanel_AA_PanelEvent_01_Bit5
	ld xwa, 0xffffffff
	ld xbc, 0x1e000a6
	ld xde, 7:i3

CtrlPanel_AA_01_PostAndContinue:
	call ApPostEvent

CtrlPanel_AA_PanelEvent_01_Bit5:
	ld	c, (49123:16)
	ld	a, c
	and	a, (49122:16)
	bit	5, a
	jr	z, 17
	ld	xwa, 4294967295
	ld	xbc, 31457445
	ld	xde, 8
	jr	20
CtrlPanel_AA_01_Bit5Release:
	bit 5, c
	jr z, CtrlPanel_AA_PanelEvent_01_Bit6
	ld xwa, 0xffffffff
	ld xbc, 0x1e000a6
	ld xde, 0x8

CtrlPanel_AA_01_Bit5Post:
	call ApPostEvent

CtrlPanel_AA_PanelEvent_01_Bit6:
	ld	c, (49123:16)
	ld	a, c
	and	a, (49122:16)
	bit	6, a
	jr	z, 17
	ld	xwa, 4294967295
	ld	xbc, 31457445
	ld	xde, 8
	jr	70
CtrlPanel_AA_01_Bit6Release:
	bit 6, c
	jr z, UIEvent_Epilogue
	ld xwa, 0xffffffff
	ld xbc, 0x1e000a6
	ld xde, 0x8
	jr UIEvent_DispatchAndReturn

CtrlPanel_AA_PanelEvent_11:
	ld	c, (49123:16)
	ld	a, c
	and	a, (49122:16)
	jr	z, 17
	ld	xwa, 4294967295
	ld	xbc, 31457445
	ld	xde, 10
	jr	19
CtrlPanel_AA_11_Release:
	cp c, 0:i3
	jr z, UIEvent_Epilogue
	ld xwa, 0xffffffff
	ld xbc, 0x1e000a6
	ld xde, 0xa

UIEvent_DispatchAndReturn:
	call ApPostEvent

UIEvent_Epilogue:
	pop xiz
	ret
