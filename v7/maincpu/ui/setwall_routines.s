; =============================================================================
; Wallpaper & Wall Display
; =============================================================================
;
; Wallpaper image loading and wall display update routines.
; Manages the panel slot selection/matching system for the
; background display.
; =============================================================================

SetWall_X:
	stl_da (0x030452), xwa
	ret

SetWall_JumpStubData:
	.byte 0xc1, 0xe0
	incf
	push	xix
	swi	6
	stdi8	(3295), 0
	call	CDlikeSwTtl_SendStartEvt
	call	SetWall_UpdateSlotIndex
	ret

SetWall_UpdateSlotIndex:
	ld xhl, 0xf1a0
	xor wa, wa
	ldb_d8 a, (3295)
	ld iy, wa
	ldb_sri A, 0x07, 0xec, 0xf4
	stb_d8 (0x2873), a
	ret

SetWall_InlineCodeBlock:
	call	SetWall_InlineCodeBlock2
	ret
	call	SetWall_InlineCodeBlock2
	.byte 0xc1, 0xdf
	incf
	push	xsp
	reti
	jr	z, 4
	call	CDlikeSwTtl_DispatchData_0x6
	call	CDlikeSwTtl_SendStartEvt
	ldb_d8	a, (3295)
	cp	a, 15
	jr	z, 2
	inc	1, a
	stb_d8	(3295), a
	call	SetWall_UpdateSlotIndex
	ret
	call	SetWall_InlineCodeBlock2
	.byte 0xc1, 0xdf
	incf
	push	xsp
	ldio	102, 4
	call	CDlikeSwTtl_DispatchData_0x6
	call	CDlikeSwTtl_SendStartEvt
	ldb_d8	a, (3295)
	cps	a, 0
	jr	z, 2
	dec	1, a
	stb_d8	(3295), a
	call	SetWall_UpdateSlotIndex
	ret
	nop
	push	sr
	nop
	ldwio	3, 1284
	.byte 0x06
	pushw	2312
	.byte 0x01
	zcf
	incf
	decf
	ret
	retd	4359
	ccf
	push	sr
	pushw	1025
	halt
	ei	7
	scf
	push	10
	pop	sr
	ldio	13, 14
	retd	4112
	ccf
	zcf
	incf
	call	SetWall_InlineCodeBlock_0x7F
	ret
	ldb_d8	a, (0x2873)
	cp	a, 13
	jr	z, 59
	cp	a, 16
	jr	z, 54
	cp	a, 15
	jr	z, 49
	cp	a, 14
	jr	z, 44
	call	CDlikeSwTtl_SendStartEvt
	ld	xhl, 0xf1a0
	xor	w, w
	ldb_d8	a, (3295)
	ld	iy, wa
	.byte 0xc3
	reti
	cp	xix, xix
	ldb	a, 201
	.byte 0xcf
	decf
	jr	z, 17
	cp	a, 16
	jr	z, 12
	cp	a, 15
	jr	z, 7
	cp	a, 14
	jr	z, 2
	jr	4
	call	CDlikeSwTtl_DispatchData_0x4A
	ret
	call	SetWall_InlineCodeBlock_0x7F
	ret
	swi	7
	swi	7
	swi	7
	.fill 8, 1, 0xff
	swi	7
	swi	7
	nop
	nop
	nop
	nop
	swi	7
	swi	7
	swi	7

SetWall_EventHandler:
	bitda 2, (1056)
	jr z, SetWall_EventHandler_Active
	jp SetWall_Return

SetWall_EventHandler_Active:
	xor wa, wa
	ldb_d8 a, (3295)
	ld iy, wa
	push xde
	ld xde, 0xf1a0
	ldb_sri A, 0x07, 0xe8, 0xf4
	pop xde
	cpda8 a, 0x2873
	jr nz, SetWall_EventHandler_Dispatch
	call CDlikeSwTtl_SendStartEvt
	jrl SetWall_ToReturn

SetWall_EventHandler_Dispatch:
	ldb_d8 a, (0x2873)
	cp a, 0xd
	jr z, SetWall_SearchForSearch
	cp a, 0x10
	jr z, SetWall_SearchSelf
	cp a, 0xf
	jr z, SetWall_SearchSelf
	cp a, 0xe
	jr z, SetWall_SearchForPanel
	jrl SetWall_CompareAndSwap

SetWall_SearchForPanel:
	xor iy, iy
	ld xhl, 0xf1a0

SetWall_SearchForPanel_Loop:
	ldb_sri A, 0x07, 0xec, 0xf4
	cp a, 0xd
	jr z, SetWall_MatchedSameSlot
	inc 1, iy
	cp iy, 0x10
	jr c, SetWall_SearchForPanel_Loop
	jr SetWall_SearchSelf

SetWall_SearchForSearch:
	xor iy, iy
	ld xhl, 0xf1a0

SetWall_SearchForSearch_Loop:
	ldb_sri A, 0x07, 0xec, 0xf4
	cp a, 0xe
	jr z, SetWall_MatchedSameSlot
	inc 1, iy
	cp iy, 0x10
	jr c, SetWall_SearchForSearch_Loop

SetWall_SearchSelf:
	xor iy, iy
	ld xhl, 0xf1a0

SetWall_SearchSelf_Loop:
	ldb_sri A, 0x07, 0xec, 0xf4
	cpda8 a, 0x2873
	jr z, SetWall_NewSlotSelected
	inc 1, iy
	cp iy, 0x10
	jr c, SetWall_SearchSelf_Loop
	jr SetWall_CompareAndSwap

SetWall_MatchedSameSlot:
	ldb_d8 a, (3295)
	xor w, w
	cp wa, iy
	jr nz, SetWall_NewSlotSelected
	jrl SetWall_CopySlotData

SetWall_NewSlotSelected:
	stdi8 (0x7f42), 26
	stdi8 (3298), 0
	ldb_d8 a, (0x2873)
	cp a, 0x10
	jr z, SetWall_DispatchSlotEvent
	stdi8 (3298), 2
	cp a, 0xf
	jr z, SetWall_DispatchSlotEvent
	stdi8 (3298), 3
	cp a, 0xe
	jr z, SetWall_DispatchSlotEvent
	stdi8 (3298), 1

SetWall_DispatchSlotEvent:
	xor wa, wa
	ldb a, 0xee
	call SoundCtrl_SendCommand

SetWall_ToReturn:
	jp SetWall_Return

SetWall_CompareAndSwap:
	ldb_d8 a, (0x2873)
	xor w, w
	ld iy, wa
	push xde
	ld xde, SetWall_InlineCodeBlock_0xCD
	ldb_sri C, 0x07, 0xe8, 0xf4
	ldb_d8 a, (3295)
	ld iy, wa
	ld xde, 0xf1a0
	ldb_sri A, 0x07, 0xe8, 0xf4
	stb_d8 (3297), a
	ld iy, wa
	ld xde, SetWall_InlineCodeBlock_0xCD
	ldb_sri A, 0x07, 0xe8, 0xf4
	pop xde
	and a, c
	cps a, 0
	jr z, SetWall_CopySlotData
	jr SetWall_IncompatibleSlot

SetWall_CopySlotData:
	ldb_d8 a, (3295)
	ld iy, wa
	push xde
	ld xde, 0xf1a0
	ldb_sri A, 0x07, 0xe8, 0xf4
	pop xde
	stb_d8 (3297), a
	stb_d8 (4438), a
	cpib_da (0x0340ea), 0x00
	jr z, SetWall_DirectHandler
	call CDlikeSwTtl_SendStopEvtD
	jp SetWall_Return

SetWall_DirectHandler:
	call SetWall_SlotSetup
	jp SetWall_Return

SetWall_IncompatibleSlot:
	call SetWall_CrossTypeChange

SetWall_Return:
	ret

SetWall_InitCallSequences:
	call	SetWall_InlineCodeBlock2
	call	CDlikeSwTtl_SendStartEvt
	stdi8	(3295), 8
	call	SetWall_UpdateSlotIndex
	ret
	call	SetWall_InlineCodeBlock2
	call	CDlikeSwTtl_SendStartEvt
	stdi8	(3295), 0
	call	SetWall_UpdateSlotIndex
	ret
	ret
	ret
	ret
	ret

SetWall_SlotSetup:
	bitda 2, (1056)
	jr z, SetWall_SlotSetup_Active
	jp SetWall_SlotSetup_Return

SetWall_SlotSetup_Active:
	call CDlikeSwTtl_SendStartEvt
	ldw_da xwa, (0x00ffec)
	stda16 (0x2875), xwa
	ldb_d8 a, (3295)
	inc 1, a
	stb_d8 (0x2877), a
	call Scoop_SpecialMode_ParamCheckBound
	call SetWall_SlotBitUpdate
	ldw_d16 xwa, (0x2875)
	stw_da (0x00ffec), xwa
	xor wa, wa
	ldb_d8 a, (3295)
	ld iy, wa
	ldb_d8 a, (0x2873)
	push xde
	ld xde, 0xf1a0
	lda_dri XBC, 0x07, 0xe8, 0xf4
	pop xde
	call CDlikeSwTtl_SendResetEvent
	call SetWall_UpdateSlotIndex

SetWall_SlotSetup_Return:
	ret

SetWall_SlotUpdate:
	bitda 2, (1056)
	jr z, SetWall_SlotUpdate_Active
	jp SetWall_SlotUpdate_Return

SetWall_SlotUpdate_Active:
	call CDlikeSwTtl_SendStartEvt
	call CDlikeSwTtl_SendResetEvent
	call SetWall_UpdateSlotIndex

SetWall_SlotUpdate_Return:
	ret

SetWall_DataBlock1:
	stdi8	(0x7f42), 0
	ldb_da	a, (0xffe3)
	stb_d8	(3391), a
	ret
	ret
	ret
	ret

SetWall_ACSlotChange:
	cpdi8 (3391), 10
	jr z, SetWall_ACSlot_CheckPanel
	ldb_d8 a, (3391)
	cpda8_24 a, (0xffe3)
	jr nz, SetWall_ACSlot_IndexChange

SetWall_ACSlot_CheckPanel:
	bitda 2, (0xfdad)
	jr z, SetWall_ACSlot_NoPanel
	cpdi8 (3390), 3
	jr nz, SetWall_ACSlot_PanelChange
	cpdi8 (3391), 10
	jr z, SetWall_ACSlot_AllChange
	jp SetWall_ACSlot_NormalChange

SetWall_ACSlot_NoPanel:
	cpdi8 (3390), 3
	jr z, SetWall_ACSlot_Direct
	cpdi8 (3391), 10
	jr z, SetWall_ACSlot_AllChange
	jp SetWall_ACSlot_NormalChange

SetWall_ACSlot_Direct:
	cpib_da (0x0340ea), 0x00
	jr z, SetWall_ACSlot_DirectLocal
	call CDlikeSwTtl_SendEvent8C_A
	jp SetWall_ACSlot_Return

SetWall_ACSlot_DirectLocal:
	call SetWall_LocalSlotChange
	jp SetWall_ACSlot_Return

SetWall_ACSlot_PanelChange:
	cpib_da (0x0340ea), 0x00
	jr z, SetWall_ACSlot_PanelLocal
	call CDlikeSwTtl_SendEvent8C_13
	jp SetWall_ACSlot_Return

SetWall_ACSlot_PanelLocal:
	call SetWall_LocalSlotChange
	jp SetWall_ACSlot_Return

SetWall_ACSlot_IndexChange:
	call SetWall_WriteSingleSlot
	jp SetWall_ACSlot_PostFinalize

SetWall_ACSlot_NormalChange:
	call SetWall_WriteSlotAndSync
	jp SetWall_ACSlot_PostFinalize

SetWall_ACSlot_AllChange:
	call SetWall_WriteAllSlots

SetWall_ACSlot_PostFinalize:
	call PlayMode_SwitchToModeAndNotify

SetWall_ACSlot_Return:
	ret

SetWall_WriteSingleSlot:
	ldb_d8 l, (0x2878)
	pushw hl
	ldb_d8 a, (3391)
	stb_d8 (0x2878), a
	call SeqVoice_InitEntry
	popw hl
	stb_d8 (0x2878), l
	xor hl, hl
	ldb_d8 l, (3390)
	dec 1, l
	sla l, 4
	ld xde, SetWall_SlotOrderTable
	stb_dri E, 0x07, 0xe8, 0xec
	ld xix, 0xab000
	xor xwa, xwa
	ldb_d8 a, (3391)
	sla xwa, 11
	stb_dri D, 0x07, 0xf0, 0xe0
	ld xwa, 0x20
	add xix, xwa
	ldw bc, 0x10
	ldir85
	push xhl
	push xde
	ldb a, 0x0
	cpdi8 (3390), 3
	jr nz, SetWall_WriteSingle_SetMode
	ldb a, 0xff

SetWall_WriteSingle_SetMode:
	ld xix, 0xab000
	xor xhl, xhl
	ldb_d8 l, (3391)
	sla xhl, 11
	stb_dri D, 0x07, 0xf0, 0xec
	ld xde, xix
	ld xhl, 0xbd
	add xde, xhl
	ld (xde), a
	pop xde
	pop xhl
	ld xix, 0xab000
	xor xwa, xwa
	ldb_d8 a, (3391)
	sla xwa, 11
	stb_dri D, 0x07, 0xf0, 0xe0
	ld xwa, 0x110
	add xix, xwa
	ldw (xix), 0xffff
	xor xwa, xwa
	ldb_d8 a, (3391)
	xor xbc, xbc
	ldb_d8 c, (3390)
	call SndParam_UpdateChannels
	ret

SetWall_WriteSlotAndSync:
	call SetWall_WriteSingleSlot
	call SetWall_SyncToneGenToDRAM
	call VoiceChannels_InitPanFromPreset
	ret

SetWall_WriteAllSlots:
	call SetWall_BankInit
	call SetWall_FullReset
	xor hl, hl
	ldb_d8 l, (3390)
	dec 1, l
	sla l, 4
	ld xde, SetWall_SlotOrderTable
	stb_dri E, 0x07, 0xe8, 0xec
	ldib_erp 0x34, 0

SetWall_WriteAll_Loop:
	ld xix, 0xab000
	xor xwa, xwa
	stb_erp A, 0x34
	sla xwa, 11
	add xix, xwa
	ld xwa, 0x20
	add xix, xwa
	stb_dri E, 0x07, 0xe8, 0xec
	ldw bc, 0x10
	ldir85
	ld xix, 0xab000
	xor xwa, xwa
	stb_erp A, 0x34
	sla xwa, 11
	add xix, xwa
	ld xwa, 0xbd
	add xix, xwa
	ldb a, 0x0
	cpdi8 (3390), 3
	jr nz, SetWall_WriteAll_ModeSet
	ldb a, 0xff

SetWall_WriteAll_ModeSet:
	ld (xix), a
	ld xix, 0xab000
	xor xwa, xwa
	stb_erp A, 0x34
	sla xwa, 11
	add xix, xwa
	ld xwa, 0x110
	add xix, xwa
	ldw (xix), 0xffff
	inc1b_erp 0x34
	cp_erpb 0x34, 0x0a
	jr c, SetWall_WriteAll_Loop
	xor xwa, xwa
	ldb_d8 a, (3391)
	xor xbc, xbc
	ldb_d8 c, (3390)
	call SndParam_UpdateChannels
	call SetWall_SyncToneGenToDRAM
	call VoiceChannels_InitPanFromPreset
	ret

SetWall_NopPadding:
	.fill 6, 1, 0x0e

SetWall_LocalSlotChange:
	cpdi8 (3391), 10
	jr nz, SetWall_LocalSingle
	call SetWall_LocalWriteAll
	jp SetWall_LocalFinalize

SetWall_LocalSingle:
	call SetWall_LocalSingle_Exec

SetWall_LocalFinalize:
	call PlayMode_SwitchToModeAndNotify
	ret

SetWall_LocalSingle_Exec:
	call SetWall_WriteSingleSlot
	call SetWall_SyncToneGenToDRAM
	call VoiceChannels_InitPanFromPreset
	ret

SetWall_LocalWriteAll:
	call SetWall_BankInit
	call SetWall_FullReset
	xor hl, hl
	ldb_d8 l, (3390)
	dec 1, l
	sla l, 4
	ld xde, SetWall_SlotOrderTable
	stb_dri E, 0x07, 0xe8, 0xec
	ldib_erp 0x34, 0

SetWall_LocalWriteAll_Loop:
	ld xix, 0xab000
	xor xwa, xwa
	stb_erp A, 0x34
	sla xwa, 11
	add xix, xwa
	ld xwa, 0x20
	add xix, xwa
	stb_dri E, 0x07, 0xe8, 0xec
	ldw bc, 0x10
	ldir85
	ld xix, 0xab000
	xor xwa, xwa
	stb_erp A, 0x34
	sla xwa, 11
	add xix, xwa
	ld xwa, 0xbd
	add xix, xwa
	ldb a, 0x0
	cpdi8 (3390), 3
	jr nz, SetWall_LocalWriteAll_Mode
	ldb a, 0xff

SetWall_LocalWriteAll_Mode:
	ld (xix), a
	ld xix, 0xab000
	xor xwa, xwa
	stb_erp A, 0x34
	sla xwa, 11
	add xix, xwa
	ld xwa, 0x110
	add xix, xwa
	ldw (xix), 0xffff
	inc1b_erp 0x34
	cp_erpb 0x34, 0x0a
	jr c, SetWall_LocalWriteAll_Loop
	xor xwa, xwa
	ldb_d8 a, (3391)
	xor xbc, xbc
	ldb_d8 c, (3390)
	call SndParam_UpdateChannels
	call SetWall_SyncToneGenToDRAM
	call VoiceChannels_InitPanFromPreset
	ret

SetWall_ExternalSync:
	call CDlikeSwTtl_SendEvent8C_0
	ret

SetWall_InlineCodeBlock2:
	xor	wa, wa
	ldb_d8	a, (3295)
	ld	iy, wa
	push	xde
	ld	xde, 0xf1a0
	.byte 0xc3
	reti
	cp	xix, xwa
	ldb	a, 90
	.byte 0xc1
	jrl	ule, -3800
	jr	nz, 4
	jp	SetWall_InlineCodeBlock2_0x5E
	ldb_d8	a, (0x2873)
	xor	w, w
	ld	iy, wa
	push	xde
	ld	xde, SetWall_InlineCodeBlock_0xCD
	.byte 0xc3
	reti
	cp	xix, xwa
	ldb	c, 193
	.byte 0xdf
	incf
	ldb	a, 216
	.byte 0x8d
	ld	xde, 0xf1a0
	.byte 0xc3
	reti
	cp	xix, xwa
	ldb	a, 216
	.byte 0x8d
	ld	xde, SetWall_InlineCodeBlock_0xCD
	.byte 0xc3
	reti
	cp	xix, xwa
	ldb	a, 90
	and	a, c
	cps	a, 0
	jr	z, 2
	jr	4
	jp	SetWall_InlineCodeBlock2_0x5E
	call	SetWall_CrossTypeChange
	ret

SetWall_CrossTypeChange:
	ld xhl, 0xf1a0
	xor wa, wa
	ldb_d8 a, (3295)
	ld iy, wa
	ldb_d8 a, (0x2873)
	ldb_sri C, 0x07, 0xec, 0xf4
	stb_d8 (0x2873), c
	lda_dri XBC, 0x07, 0xec, 0xf4
	stb_d8 (3386), a
	ldb_d8 a, (3295)
	stb_d8 (3301), a
	call SetWall_CrossType_Validate
	call Audio_CheckSubsystemReady
	ret

SetWall_SlotTypeMap:
	nop
	push	sr
	.byte 0x01
	reti
	ldio	9, 10
	pushw	1284
	ei	3
	retd	0xffff
	swi	7
	swi	7
	incf
	decf
	ret

SetWall_CrossType_Validate:
	anddi8 (0x2879), 252
	call SetWall_ParserInit
	ldb_d8 a, (3301)
	cp a, 0xf
	jrl ugt, SetWall_CrossType_Reset
	ldb_d8 a, (0x2873)
	cp a, 0x13
	jrl ugt, SetWall_CrossType_Reset
	stdi8 (0x287a), 0
	anddi8 (0x287b), 191
	xor hl, hl
	ldb_d8 l, (3301)
	push xde
	ld xde, 0xf1a0
	ldb_sri A, 0x07, 0xe8, 0xec
	pop xde
	cpda8 a, 0x2873
	jr z, SetWall_CrossType_Reset
	ldb_d8 l, (3301)
	xor h, h
	push xde
	ld xde, 0xf1a0
	ldb_sri L, 0x07, 0xe8, 0xec
	pop xde
	cp l, 0xc
	jr nz, SetWall_CrossType_ClearBit0
	ordi8 0x2879, 1
	jr SetWall_CrossType_CheckDest

SetWall_CrossType_ClearBit0:
	anddi8 (0x2879), 254

SetWall_CrossType_CheckDest:
	cpdi8 (0x2873), 12
	jr nz, SetWall_CrossType_ClearBit1
	ordi8 0x2879, 2
	jr SetWall_CrossType_MapLookup

SetWall_CrossType_ClearBit1:
	anddi8 (0x2879), 253

SetWall_CrossType_MapLookup:
	xor h, h
	push xde
	ld xde, SetWall_SlotTypeMap
	ldb_sri L, 0x07, 0xe8, 0xec
	pop xde
	cp l, 0xff
	jr z, SetWall_CrossType_Reset
	stb_d8 (0x287c), l
	ldb_d8 a, (3301)
	inc 1, a
	pushw wa
	stdi8 (4596), 0
	call SeqPlay_CheckStartConditions
	popw wa
	call SetWall_ParsePatternStream

SetWall_CrossType_Reset:
	pushw wa
	xor a, a
	call Part_InitVoiceDefaults
	popw wa
	anddi8 (0x2879), 252
	ret

SetWall_SlotOrderTable:
	.byte 0x00, 0x02, 0x01, 0x0d, 0x0f, 0x10, 0x0c, 0x0b
	.byte 0x08, 0x09, 0x0a, 0x03, 0x04, 0x05, 0x06, 0x07
	.byte 0x00, 0x02, 0x01, 0x0b, 0x08, 0x09, 0x0a, 0x03
	.byte 0x04, 0x05, 0x06, 0x07, 0x11, 0x12, 0x13, 0x0c
	.byte 0x00, 0x02, 0x01, 0x0b, 0x08, 0x09, 0x0a, 0x03
	.byte 0x04, 0x0c, 0x06, 0x07, 0x11, 0x12, 0x13, 0x05

SetWall_SlotBitUpdate:
	ldb_erp A, 0x3c
	ldw_erp DE, 0x3e
	ldw_da xde, (0x00ffec)
	ldb_d8 a, (3295)
	rcf
	stcf_a_16 de
	stb_erp A, 0x3c
	stw_da (0x00ffec), xde
	stw_erp DE, 0x3e
	ret

SetWall_ParsePatternStream:
	anddi8 (0x287b), 251
	xor w, w
	stdi8 (0x287a), 0
	stda16 (0x287d), xwa
	stdi16 (0x287f), 1
	call SetWall_SlotResolve
	cpdi8 (0x287a), 0
	jr z, SetWall_ParseStream_Init
	jrl SetWall_ParseStream_Return

SetWall_ParseStream_Init:
	push xhl
	ldda32 xhl, (4349)
	stda32 0x2881, xhl
	pop xhl
	stda16 (0x2885), xiy
	ldw_d16 xwa, (0x28af)
	stda16 (0x2887), xwa
	stda16 (0x2889), xiy
	stda16 (0x288b), xwa
	ld ix, iy
	ldw_d16 xhl, (3376)

SetWall_ParseStream_MainLoop:
	push xde
	ldda32 xde, (4349)
	ldb_sri A, 0x07, 0xe8, 0xf4
	pop xde
	cp a, 0x82
	jrl z, SetWall_ParseStream_End
	cp a, 0x81
	jr z, SetWall_ParseStream_ReadEvent
	cp a, 0x80
	jr z, SetWall_ParseStream_ReadEvent
	cp a, 0xd2
	jr z, SetWall_ParseStream_CheckD1D2
	cp a, 0xd1
	jr z, SetWall_ParseStream_CheckD1D2
	cp a, 0x85
	jr z, SetWall_ParseStream_ReadEvent
	cp a, 0x86
	jr z, SetWall_ParseStream_ReadEvent
	cp a, 0xd3
	jr z, SetWall_ParseStream_ReadEvent
	ldb w, 0xf0
	and w, a
	cp w, 0x90
	jr z, SetWall_ParseStream_ReadEvent
	cp w, 0xc0
	jr z, SetWall_ParseStream_TypeC0
	cp w, 0xb0
	jrl z, SetWall_ParseStream_TypeB0

SetWall_ParseStream_Advance:
	call SetWall_AdvanceStreamPos
	cpdi8 (0x287a), 0
	jr z, SetWall_ParseStream_MainLoop
	jrl SetWall_ParseStream_Return

SetWall_ParseStream_CheckD1D2:
	bitda 0, (0x2879)
	jr nz, SetWall_ParseStream_Advance

SetWall_ParseStream_ReadEvent:
	push xhl
	ldda32 xhl, (0x2881)
	lda_dri XBC, 0x07, 0xec, 0xf0
	pop xhl
	call SetWall_AdvanceWritePos
	cpdi8 (0x287a), 0
	jrl nz, SetWall_ParseStream_Return
	call SetWall_AdvanceStreamPos
	cpdi8 (0x287a), 0
	jrl nz, SetWall_ParseStream_Return
	push xde
	ldda32 xde, (4349)
	bit_dri 7, 0x07, 0xe8, 0xf4
	pop xde
	jrl nz, SetWall_ParseStream_MainLoop
	push xde
	ldda32 xde, (4349)
	ldb_sri A, 0x07, 0xe8, 0xf4
	pop xde
	jr SetWall_ParseStream_ReadEvent

SetWall_ParseStream_TypeC0:
	ldb_erp A, 0x3c
	ldb_d8 a, (0x2879)
	and a, 0x3
	stb_erp A, 0x3c
	jr nz, SetWall_ParseStream_Advance
	bitda 1, (4393)
	jr nz, SetWall_ParseStream_TypeC0_Loop
	push xiz
	ldda32 xiz, (4349)
	ldfr_lerp XIZ, 0x38
	pop xiz
	push_lerp 0x38
	pushw wa
	push xiy
	push_sd16w 0x8b, 0x28
	call SetWall_SkipC0Scanner
	popw_dd16 0x8b, 0x28
	pop xiy
	popw wa
	pop_lerp 0x38
	push xiz
	ldto_lerp XIZ, 0x38
	stda32 4349, xiz
	pop xiz
	cps l, 0
	jrl nz, SetWall_ParseStream_Advance

SetWall_ParseStream_TypeC0_Loop:
	xor c, c

SetWall_ParseStream_C0_Iter:
	cps c, 2
	jr nz, SetWall_ParseStream_C0_Read
	ldb_d8 a, (0x287c)

SetWall_ParseStream_C0_Read:
	push xhl
	ldda32 xhl, (0x2881)
	lda_dri XBC, 0x07, 0xec, 0xf0
	pop xhl
	pushw bc
	call SetWall_AdvanceWritePos
	popw bc
	cpdi8 (0x287a), 0
	jrl nz, SetWall_ParseStream_Return
	pushw bc
	call SetWall_AdvanceStreamPos
	popw bc
	cpdi8 (0x287a), 0
	jrl nz, SetWall_ParseStream_Return
	inc 1, c
	push xde
	ldda32 xde, (4349)
	bit_dri 7, 0x07, 0xe8, 0xf4
	pop xde
	jrl nz, SetWall_ParseStream_MainLoop
	push xde
	ldda32 xde, (4349)
	ldb_sri A, 0x07, 0xe8, 0xf4
	pop xde
	jr SetWall_ParseStream_C0_Iter

SetWall_ParseStream_TypeB0:
	ld c, a
	and c, 0x4
	sll c, 5
	stb_d8 (4340), c
	stb_d8 (3310), a
	anddi8 (3310), 2
	pushw bc
	ldb c, 0x6

SetWall_ParseStream_B0_ShiftLoop:
	sla_sd16b 0xee, 0x0c
	djnz8 c, SetWall_ParseStream_B0_ShiftLoop
	popw bc
	bitda 1, (4393)
	jr nz, SetWall_ParseStream_B0_Iter
	push xiz
	ldda32 xiz, (4349)
	ldfr_lerp XIZ, 0x38
	pop xiz
	push_lerp 0x38
	pushw wa
	push xiy
	push_sd16w 0x8b, 0x28
	call SetWall_ParseB0ControlChange
	popw_dd16 0x8b, 0x28
	pop xiy
	popw wa
	pop_lerp 0x38
	push xiz
	ldto_lerp XIZ, 0x38
	stda32 4349, xiz
	pop xiz
	cpdi8 (0x287a), 0
	jrl nz, SetWall_ParseStream_Return
	bitda 0, (0x289d)
	jr nz, SetWall_ParseStream_B0_Iter
	bitda 2, (0x289d)
	jrl nz, SetWall_ParseStream_ReadEvent
	jrl SetWall_ParseStream_Advance

SetWall_ParseStream_B0_Iter:
	xor c, c

SetWall_ParseStream_B0_ByteLoop:
	cps c, 0
	jr nz, SetWall_ParseStream_B0_Byte1
	bitda 0, (3389)
	jr z, SetWall_ParseStream_B0_Write
	and a, 0xfc
	jr SetWall_ParseStream_B0_Write

SetWall_ParseStream_B0_Byte1:
	cps c, 2
	jr nz, SetWall_ParseStream_B0_Byte3
	cpdi8 (4340), 181
	jr z, SetWall_ParseStream_B0_Write
	cpdi8 (4340), 182
	jr z, SetWall_ParseStream_B0_Write
	cpdi8 (4340), 183
	jr z, SetWall_ParseStream_B0_Write
	ldb_d8 a, (0x287c)

SetWall_ParseStream_B0_Byte3:
	cps c, 3
	jr nz, SetWall_ParseStream_B0_Byte4
	bitda 1, (4393)
	jr nz, SetWall_ParseStream_B0_Write
	ldb_d8 a, (3388)
	jr SetWall_ParseStream_B0_Write

SetWall_ParseStream_B0_Byte4:
	cps c, 4
	jr nz, SetWall_ParseStream_B0_Write
	cpdi8 (3387), 255
	jr z, SetWall_ParseStream_B0_Write
	bitda 1, (4393)
	jr nz, SetWall_ParseStream_B0_Write
	ldb_d8 a, (3387)

SetWall_ParseStream_B0_Write:
	push xhl
	ldda32 xhl, (0x2881)
	lda_dri XBC, 0x07, 0xec, 0xf0
	pop xhl
	pushw bc
	call SetWall_AdvanceWritePos
	popw bc
	cpdi8 (0x287a), 0
	jr nz, SetWall_ParseStream_Return
	pushw bc
	call SetWall_AdvanceStreamPos
	popw bc
	cpdi8 (0x287a), 0
	jr nz, SetWall_ParseStream_Return
	inc 1, c
	push xde
	ldda32 xde, (4349)
	bit_dri 7, 0x07, 0xe8, 0xf4
	pop xde
	jrl nz, SetWall_ParseStream_MainLoop
	push xde
	ldda32 xde, (4349)
	ldb_sri A, 0x07, 0xe8, 0xf4
	pop xde
	jrl SetWall_ParseStream_B0_ByteLoop

SetWall_ParseStream_End:
	push xhl
	ldda32 xhl, (0x2881)
	lda_dri XBC, 0x07, 0xec, 0xf0
	pop xhl
	ldw_d16 xwa, (0x2887)
	stda16 (0x289f), xwa
	call SetWall_EventOutput
	call SetWall_EventAdvanceCheck

SetWall_ParseStream_Return:
	ret

SetWall_ParserInit:
	push xiy
	stdi8 (0x28a1), 16
	ldw_d16 xiy, (0x286d)
	stda16 (0x28a2), xiy
	ldda32 xiy, (7514)
	stda32 3304, xiy
	stdi16 (3376), 0
	stdi8 (0x289e), 15
	pop xiy
	ret

SetWall_AdvanceStreamPos:
	inc 1, iy
	cp iy, 0xff
	jr ule, SetWall_AdvanceStream_Return
	ldw_d16 xhl, (0x288b)
	call SetWall_StreamIndexResolve
	ldda32 xhl, (4349)
	ld wa, (xhl + 3)
	stda16 (0x288b), xwa
	ld hl, wa
	call SetWall_StreamIndexResolve
	ldda32 xhl, (4349)
	bitm 7, (xhl)
	jr nz, SetWall_AdvanceStream_Reset
	stdi8 (0x287a), 2
	jr SetWall_AdvanceStream_Return

SetWall_AdvanceStream_Reset:
	lds iy, 5

SetWall_AdvanceStream_Return:
	ret

SetWall_AdvanceWritePos:
	ldda32 xwa, (4349)
	push xwa
	inc 1, ix
	cp ix, 0xff
	jr ule, SetWall_AdvanceWrite_Return
	ldda32 xhl, (0x2881)
	ld wa, (xhl + 3)
	stda16 (0x2887), xwa
	ld hl, wa
	call SetWall_StreamIndexResolve
	ldda32 xhl, (4349)
	bitm 7, (xhl)
	jr nz, SetWall_AdvanceWrite_Reset
	stdi8 (0x287a), 2
	jr SetWall_AdvanceWrite_Return

SetWall_AdvanceWrite_Reset:
	stda32 0x2881, xhl
	lds ix, 5

SetWall_AdvanceWrite_Return:
	pop xwa
	stda32 4349, xwa
	ret

SetWall_SkipC0Scanner:
	xor hl, hl
	call SetWall_AdvanceStreamPos
	cpdi8 (0x287a), 0
	jr nz, SetWall_SkipC0_Return
	call SetWall_AdvanceStreamPos
	cpdi8 (0x287a), 0
	jr nz, SetWall_SkipC0_Return
	push xde
	ldda32 xde, (4349)
	ldb_sri A, 0x07, 0xe8, 0xf4
	pop xde
	call SetWall_AdvanceStreamPos
	cpdi8 (0x287a), 0
	jr nz, SetWall_SkipC0_Return
	push xde
	ldda32 xde, (4349)
	ldb_sri A, 0x07, 0xe8, 0xf4
	pop xde
	xor l, l
	cps a, 0
	jr ule, SetWall_SkipC0_Return
	ldb l, 0x1

SetWall_SkipC0_Return:
	ret

SetWall_ParseB0ControlChange:
	ldb_d8 a, (0x2873)
	stb_d8 (3378), a
	call SetWall_AdvanceStreamPos
	cpdi8 (0x287a), 0
	jrl nz, SetWall_B0CC_Return
	call SetWall_AdvanceStreamPos
	cpdi8 (0x287a), 0
	jrl nz, SetWall_B0CC_Return
	stdi8 (3387), 255
	push xde
	ldda32 xde, (4349)
	ldb_sri A, 0x07, 0xe8, 0xf4
	pop xde
	and a, 0x7f
	orddm8 4340, a
	ldb_d8 a, (4340)
	cp a, 0x48
	jr z, SetWall_B0CC_Type48
	anddi8 (0x289d), 251
	ldb_d8 l, (0x2873)
	xor h, h
	push xde
	ld xde, SetWall_SlotTypeMap
	ldb_sri L, 0x07, 0xe8, 0xec
	pop xde
	cp a, l
	jr nz, SetWall_B0CC_ClearFlags
	call SetWall_AdvanceStreamPos
	cpdi8 (0x287a), 0
	jrl nz, SetWall_B0CC_Return
	push xde
	ldda32 xde, (4349)
	ldb_sri A, 0x07, 0xe8, 0xf4
	pop xde
	cps a, 3
	jr c, SetWall_B0CC_ClearFlags
	cp a, 0xb
	jr ugt, SetWall_B0CC_ClearFlags
	cps a, 6
	jr z, SetWall_B0CC_ClearFlags
	ldb_erp A, 0x3c
	ldb_d8 a, (0x2879)
	and a, 0x3
	stb_erp A, 0x3c
	jr z, SetWall_B0CC_BankSelect
	ldb c, 0x3
	cp a, c
	jr nz, SetWall_B0CC_ClearFlags

SetWall_B0CC_BankSelect:
	ordi8 0x289d, 1
	anddi8 (3389), 254
	stb_d8 (3388), a
	jrl SetWall_B0CC_Return

SetWall_B0CC_ClearFlags:
	anddi8 (0x289d), 250
	jrl SetWall_B0CC_Return
	jrl SetWall_B0CC_Return

SetWall_B0CC_Type48:
	call SetWall_AdvanceStreamPos
	cpdi8 (0x287a), 0
	jrl nz, SetWall_B0CC_Return
	push xde
	ldda32 xde, (4349)
	ldb_sri A, 0x07, 0xe8, 0xf4
	pop xde
	cps a, 5
	jr nz, SetWall_B0CC_Type48_Check12
	anddi8 (0x289d), 254
	call SetWall_AdvanceStreamPos
	cpdi8 (0x287a), 0
	jr nz, SetWall_B0CC_Return
	call SetWall_AdvanceStreamPos
	cpdi8 (0x287a), 0
	jr nz, SetWall_B0CC_Return
	push xde
	ldda32 xde, (4349)
	ldb_sri A, 0x07, 0xe8, 0xf4
	pop xde
	and a, 0x7f
	orda8 a, 3310
	ldb_erp A, 0x3c
	and a, 0xfc
	stb_erp A, 0x3c
	jr nz, SetWall_B0CC_Type48_SetFlag
	anddi8 (0x289d), 251
	jr SetWall_B0CC_Return

SetWall_B0CC_Type48_SetFlag:
	ordi8 0x289d, 4
	jr SetWall_B0CC_Return

SetWall_B0CC_Type48_Check12:
	anddi8 (0x289d), 251
	cpdi8 (0x2873), 12
	jr nz, SetWall_B0CC_ClearFlags
	push xde
	ldda32 xde, (4349)
	ldb_sri A, 0x07, 0xe8, 0xf4
	pop xde
	cps a, 3
	jrl nz, SetWall_B0CC_ClearFlags
	jrl SetWall_B0CC_BankSelect

SetWall_B0CC_Return:
	ret

SetWall_EventOutput:
	push xde
	push xiz
	ldw_d16 xhl, (0x287d)
	dec 1, hl
	ld wa, ix
	ld xde, 0xf218
	lda_dri XBC, 0x07, 0xe8, 0xec
	sla hl, 1
	ldw_d16 xwa, (0x289f)
	ld xde, 0xf1f8
	stw_dri WA, 0x07, 0xe8, 0xec
	xor xwa, xwa
	ld xiz, 0xab000
	ldb_da a, (0x00ffe3)
	sla xwa, 11
	add xiz, xwa
	ld xde, 0x98
	add xde, xiz
	ld wa, ix
	lda_dri XBC, 0x07, 0xe8, 0xec
	sla hl, 1
	ld xde, 0x78
	add xde, xiz
	ldw_d16 xwa, (0x289f)
	stw_dri WA, 0x07, 0xe8, 0xec
	pop xiz
	pop xde
	ret

SetWall_EventAdvanceCheck:
	ld hl, wa
	call SetWall_StreamIndexResolve
	ldda32 xhl, (4349)
	ld wa, (xhl + 3)
	stda16 (0x28af), xwa
	cp wa, 0xffff
	jr z, SetWall_EventAdvance_Return
	cpda16 xwa, 0x28a2
	jr ule, SetWall_EventAdvance_Sync
	stdi8 (0x287a), 10
	jr SetWall_EventAdvance_Return

SetWall_EventAdvance_Sync:
	ld iy, wa
	ldw_d16 xwa, (0x28a2)
	call DispatchHandler_JumpSub

SetWall_EventAdvance_Return:
	ret

SetWall_SlotResolve:
	stdi8 (0x287a), 0
	stb_d8 (0x288d), w
	call SetWall_SingleSlotResolve
	cpdi8 (0x287a), 0
	jr z, SetWall_SlotResolve_Init
	jr SetWall_SlotResolve_Return

SetWall_SlotResolve_Init:
	lds iy, 5
	push xiz
	ldda32 xiz, (4349)
	ldfr_lerp XIZ, 0x38
	pop xiz
	push_lerp 0x38
	push xhl
	push xiy
	call SetWall_DualPassScanner
	pop xiy
	pop xhl
	pop_lerp 0x38
	push xiz
	ldto_lerp XIZ, 0x38
	stda32 4349, xiz
	pop xiz
	xor de, de
	inc 1, de
	xor xix, xix

SetWall_SlotResolve_CheckDone:
	cpda16 xde, 0x287f
	jr nz, SetWall_SlotResolve_ScanNext
	ldb_d8 a, (0x288e)
	jr SetWall_SlotResolve_Return

SetWall_SlotResolve_ScanNext:
	ldb_d8 b, (0x288e)
	call SetWall_SkipEvents
	cpdi8 (0x287a), 0
	jr z, SetWall_SlotResolve_FoundMatch
	jr SetWall_SlotResolve_Return

SetWall_SlotResolve_FoundMatch:
	stda16 (3383), xix
	inc 1, de
	push xiz
	ldda32 xiz, (4349)
	ldfr_lerp XIZ, 0x38
	pop xiz
	push_lerp 0x38
	push xhl
	pushw de
	push xiy
	push xix
	call SetWall_ReplayScanner
	pop xix
	pop xiy
	popw de
	pop xhl
	pop_lerp 0x38
	push xiz
	ldto_lerp XIZ, 0x38
	stda32 4349, xiz
	pop xiz
	cpdi8 (0x287a), 0
	jr nz, SetWall_SlotResolve_Return
	jr SetWall_SlotResolve_CheckDone

SetWall_SlotResolve_Return:
	ret

SetWall_StreamIndexResolve:
	dec 1, hl
	extz xhl
	sla xhl, 8
	addda32 xhl, 7514
	stda32 4349, xhl
	xor xhl, xhl
	ret

SetWall_BankInit:
	ld xhl, 0x110a
	push xde
	ldda32 xde, (7514)
	ld (xhl), xde
	pop xde
	lds iy, 1
	call SetWall_ResolveStreamPtr
	stdi16 (0xf22f), 1
	ldda32 xiy, (4349)
	xor xhl, xhl
	lds de, 2
	ldw_d16 xbc, (0x286d)
	stda16 (0xf231), xbc
	dec 1, bc

SetWall_BankInit_SlotLoop:
	andmi8 (xiy), 0x7f
	ld (xiy + 1), hl
	ld (xiy + 3), de
	ld (xiy + 5), 0x82
	inc 1, hl
	inc 1, de
	add xiy, 0x100
	djnz xbc, SetWall_BankInit_SlotLoop
	andmi8 (xiy), 0x7f
	ld (xiy + 1), hl
	ld (xiy + 5), 0x82
	ldw (xiy + 3), 0xffff
	ld xhl, 0xf250
	ldw bc, 0x10

SetWall_BankInit_ClearF250:
	ld (xhl), 0x0
	ldw (xhl + 1), 0xffff
	add xhl, 0x3
	djnz xbc, SetWall_BankInit_ClearF250
	ld xhl, 0xc9e
	ldw bc, 0x10

SetWall_BankInit_ClearC9E:
	ldw (xhl), 0xffff
	inc 2, xhl
	djnz xbc, SetWall_BankInit_ClearC9E
	ld xhl, 0xcae
	ldw bc, 0x10

SetWall_BankInit_FillCAE:
	ld (xhl), 0x5
	inc 1, xhl
	djnz xbc, SetWall_BankInit_FillCAE
	ld xhl, 0xf1f8
	ldw bc, 0x10

SetWall_BankInit_ClearF1F8:
	ldw (xhl), 0xffff
	inc 2, xhl
	djnz xbc, SetWall_BankInit_ClearF1F8
	ld xhl, 0xf218
	ldw bc, 0x10

SetWall_BankInit_FillF218:
	ld (xhl), 0x5
	inc 1, xhl
	djnz xbc, SetWall_BankInit_FillF218
	ret

SetWall_FullReset:
	xor bc, bc

SetWall_FullReset_SlotLoop:
	pushw bc
	ld xde, 0xab000
	xor xwa, xwa
	ld wa, bc
	sla xwa, 11
	add xde, xwa
	ld xwa, 0x1c
	add xwa, xde
	ldw (xwa), 0x0
	ld xwa, 0xd0
	add xwa, xde
	xor iy, iy

SetWall_FullReset_VoiceLoop:
	stib_ind 0x07, 0xe0, 0xf4, 0x00
	inc 1, iy
	stiw_ind 0x07, 0xe0, 0xf4, 0xff, 0xff
	inc 2, iy
	cp iy, 0x30
	jr c, SetWall_FullReset_VoiceLoop
	ld xwa, 0x78
	add xwa, xde
	ldw iy, 0xffff
	ldb c, 0x10

SetWall_FullReset_ClearNotes:
	stw_dpi IY, 0xe1
	djnz8 c, SetWall_FullReset_ClearNotes
	ld xwa, 0x98
	add xwa, xde
	ldb b, 0x5
	ldb c, 0x10

SetWall_FullReset_ClearCtrl:
	lda_dpi XDE, 0xe0
	djnz8 c, SetWall_FullReset_ClearCtrl
	ld xwa, 0x1e
	add xwa, xde
	ldw (xwa), 0x0
	ld xwa, 0xcb
	add xwa, xde
	ld (xwa), 0x0
	popw bc
	inc 1, bc
	cp bc, 0xa
	jrl c, SetWall_FullReset_SlotLoop
	stdi16 (0xf19e), 0
	stiw_da (0x00ffec), 0x0000
	stdi8 (0xf24b), 0
	ld xix, 0xcef
	xor wa, wa
	ldb c, 0x10

SetWall_FullReset_ClearGlobal1:
	stw_dpi WA, 0xf1
	djnz8 c, SetWall_FullReset_ClearGlobal1
	ld xix, 0xd0f
	ldb c, 0x10

SetWall_FullReset_ClearGlobal2:
	ld (xix), a
	djnz8 b, SetWall_FullReset_ClearGlobal2
	stdi8 (0xf24b), 0
	call SetWall_SendPanelCtrl
	stdi16 (0x2875), 0
	stiw_da (0x00ffec), 0x0000
	ret

SetWall_SingleSlotResolve:
	xor w, w
	dec 1, a
	muls wa, 0x3
	ld iy, wa
	push xde
	ld xde, 0xf250
	bit_dri 7, 0x07, 0xe8, 0xf4
	pop xde
	jr nz, SetWall_SingleSlot_LoadPos
	stdi8 (0x287a), 1
	jr SetWall_SingleSlot_Return

SetWall_SingleSlot_LoadPos:
	inc 1, iy
	push xde
	ld xde, 0xf250
	ldw_sri WA, 0x07, 0xe8, 0xf4
	pop xde
	cp wa, 0xffff
	jr nz, SetWall_SingleSlot_InvalidPos
	stdi8 (0x287a), 2
	jr SetWall_SingleSlot_Return

SetWall_SingleSlot_InvalidPos:
	cpda16 xwa, 0x28a2
	jr ule, SetWall_SingleSlot_CheckBounds
	stdi8 (0x287a), 10
	jr SetWall_SingleSlot_Return

SetWall_SingleSlot_CheckBounds:
	stda16 (0x28af), xwa
	ld hl, wa
	call SetWall_StreamIndexResolve
	ldda32 xhl, (4349)
	bitm 7, (xhl)
	jr nz, SetWall_SingleSlot_Return
	stdi8 (0x287a), 11

SetWall_SingleSlot_Return:
	ret

SetWall_DualPassScanner:
	push_sd16w 0xaf, 0x28
	anddi8 (0x287b), 223
	ldb_d8 a, (1075)
	stb_d8 (0x288e), a
	bitda 2, (0x287b)
	jrl z, SetWall_DualPass_Done
	ldb_d8 a, (0x288d)
	call SetWall_SingleSlotResolve
	cpdi8 (0x287a), 0
	jr z, SetWall_DualPass_InitLoop
	anddi8 (0x287b), 251
	stdi8 (0x287a), 0
	jrl SetWall_DualPass_Done

SetWall_DualPass_InitLoop:
	xor hl, hl
	push xwa
	ldda32 xwa, (4349)
	stda32 0x288f, xwa
	pop xwa
	lds iy, 5

SetWall_DualPass_MainLoop:
	ldda32 xhl, (4349)
	ldb_sri A, 0x07, 0xec, 0xf4
	ld w, a
	and a, 0xf0
	cp a, 0xc0
	jr z, SetWall_DualPass_TypeC0
	cp w, 0x82
	jrl z, SetWall_DualPass_Error
	cp w, 0x84
	jrl z, SetWall_DualPass_Error
	cp w, 0x81
	jrl z, SetWall_DualPass_Type81
	call SetWall_StreamAdvanceBounded
	cpdi8 (0x287a), 0
	jr z, SetWall_DualPass_MainLoop
	jrl SetWall_DualPass_Error

SetWall_DualPass_TypeC0:
	ld a, w
	ld hl, wa
	rrc a
	and wa, 0x80
	stda16 (0x2893), xwa
	and hl, 0x2
	rrc_i_8 l, 2
	stda16 (0x2895), xhl
	call SetWall_StreamAdvanceBounded
	cpdi8 (0x287a), 0
	jrl nz, SetWall_DualPass_Error
	call SetWall_StreamAdvanceBounded
	cpdi8 (0x287a), 0
	jrl nz, SetWall_DualPass_Error
	call SetWall_StreamAdvanceBounded
	cpdi8 (0x287a), 0
	jr nz, SetWall_DualPass_Error
	call SetWall_StreamAdvanceBounded
	cpdi8 (0x287a), 0
	jrl nz, SetWall_DualPass_Error
	ldw_d16 xwa, (0x2893)
	ldda32 xhl, (4349)
	ldb_sri W, 0x07, 0xec, 0xf4
	or a, w
	pushw wa
	call SetWall_StreamAdvanceBounded
	popw wa
	cpdi8 (0x287a), 0
	jr nz, SetWall_DualPass_Error
	ldda32 xhl, (4349)
	ldb_sri D, 0x07, 0xec, 0xf4
	ldw_d16 xhl, (0x2895)
	or d, l
	push xiz
	ldda32 xiz, (4349)
	ldfr_lerp XIZ, 0x30
	pop xiz
	push_lerp 0x30
	push xiy
	push xhl
	call Rhythm_DispatchNote_Tramp
	pop xhl
	pop xiy
	pop_lerp 0x30
	push xiz
	ldto_lerp XIZ, 0x30
	stda32 4349, xiz
	pop xiz
	stb_d8 (0x288e), a
	call SetWall_StreamAdvanceBounded
	cpdi8 (0x287a), 0
	jr nz, SetWall_DualPass_Error
	jrl SetWall_DualPass_MainLoop

SetWall_DualPass_Type81:
	call SetWall_ForwardSkip
	jr SetWall_DualPass_Done

SetWall_DualPass_Error:
	stdi8 (0x287a), 0
	ldb_d8 a, (1075)
	stb_d8 (0x288e), a
	ordi8 0x287b, 32

SetWall_DualPass_Done:
	popw_dd16 0xaf, 0x28
	ret

SetWall_SkipEvents:
	xor c, c

SetWall_SkipEvents_CheckCount:
	cp c, b
	jr z, SetWall_SkipEvents_Return

SetWall_SkipEvents_ReadLoop:
	ldda32 xhl, (4349)
	ldb_sri A, 0x07, 0xec, 0xf4
	cp a, 0x84
	jr z, SetWall_SkipEvents_EndMarker
	cp a, 0x82
	jr nz, SetWall_SkipEvents_CheckEnd

SetWall_SkipEvents_EndMarker:
	stdi8 (0x287a), 8
	jr SetWall_SkipEvents_Return

SetWall_SkipEvents_CheckEnd:
	cp a, 0x81
	jr z, SetWall_SkipEvents_IncCount
	call SetWall_StreamAdvanceBounded
	cpdi8 (0x287a), 0
	jr z, SetWall_SkipEvents_ReadLoop
	jr SetWall_SkipEvents_Return

SetWall_SkipEvents_IncCount:
	inc 1, c
	call SetWall_StreamAdvanceBounded
	cpdi8 (0x287a), 0
	jr z, SetWall_SkipEvents_CheckCount
	jr SetWall_SkipEvents_Return

SetWall_SkipEvents_Return:
	xor b, b
	add ix, bc
	ret

SetWall_ReplayScanner:
	push_sd16w 0xaf, 0x28
	bitda 2, (0x287b)
	jrl z, SetWall_Replay_Done
	bitda 5, (0x287b)
	jrl nz, SetWall_Replay_Done
	xor hl, hl
	ldda32 xhl, (0x2897)
	stda32 4349, xhl
	ldw_d16 xiy, (0x289b)

SetWall_Replay_MainLoop:
	ldb_sri A, 0x07, 0xec, 0xf4
	ld w, a
	and a, 0xf0
	cp a, 0xc0
	jr z, SetWall_Replay_TypeC0
	cp w, 0x82
	jr nz, SetWall_Replay_Type84
	ordi8 0x287b, 32
	jrl SetWall_Replay_Done

SetWall_Replay_Type84:
	cp w, 0x84
	jr nz, SetWall_Replay_CheckType81
	lds iy, 5
	ldda32 xhl, (0x288f)
	jr SetWall_Replay_MainLoop

SetWall_Replay_CheckType81:
	cp w, 0x81
	jrl z, SetWall_Replay_Type81
	call SetWall_StreamAdvanceBounded
	cpdi8 (0x287a), 0
	jr z, SetWall_Replay_MainLoop
	stdi8 (0x287a), 0
	jrl SetWall_Replay_Done

SetWall_Replay_TypeC0:
	ld l, w
	xor l, l
	ld a, w
	rrc a
	and wa, 0x80
	stda16 (0x2893), xwa
	call SetWall_StreamAdvanceBounded
	cpdi8 (0x287a), 0
	jr z, SetWall_Replay_C0_Byte2
	stdi8 (0x287a), 0
	jrl SetWall_Replay_Done

SetWall_Replay_C0_Byte2:
	call SetWall_StreamAdvanceBounded
	cpdi8 (0x287a), 0
	jr z, SetWall_Replay_C0_Byte3
	stdi8 (0x287a), 0
	jrl SetWall_Replay_Done

SetWall_Replay_C0_Byte3:
	call SetWall_StreamAdvanceBounded
	cpdi8 (0x287a), 0
	jr z, SetWall_Replay_C0_Byte4
	stdi8 (0x287a), 0
	jrl SetWall_Replay_Done

SetWall_Replay_C0_Byte4:
	call SetWall_StreamAdvanceBounded
	cpdi8 (0x287a), 0
	jr z, SetWall_Replay_C0_ReadBank
	stdi8 (0x287a), 0
	jr SetWall_Replay_Done

SetWall_Replay_C0_ReadBank:
	ldw_d16 xwa, (0x2893)
	ldda32 xhl, (4349)
	ldb_sri W, 0x07, 0xec, 0xf4
	or a, w
	pushw wa
	call SetWall_StreamAdvanceBounded
	popw wa
	cpdi8 (0x287a), 0
	jr z, SetWall_Replay_C0_ReadCC
	stdi8 (0x287a), 0
	jr SetWall_Replay_Done

SetWall_Replay_C0_ReadCC:
	ldda32 xhl, (4349)
	ldb_sri D, 0x07, 0xec, 0xf4
	push xiz
	ldda32 xiz, (4349)
	ldfr_lerp XIZ, 0x3c
	pop xiz
	push_lerp 0x3c
	push xiy
	push xhl
	call Rhythm_DispatchNote_Tramp
	pop xhl
	pop xiy
	pop_lerp 0x3c
	push xiz
	ldto_lerp XIZ, 0x3c
	stda32 4349, xiz
	pop xiz
	stb_d8 (0x288e), a
	call SetWall_StreamAdvanceBounded
	cpdi8 (0x287a), 0
	jrl z, SetWall_Replay_MainLoop
	stdi8 (0x287a), 0
	jr SetWall_Replay_Done

SetWall_Replay_Type81:
	call SetWall_ForwardSkip

SetWall_Replay_Done:
	popw_dd16 0xaf, 0x28
	stdi8 (0x287a), 0
	ret

SetWall_SendPanelCtrl:
	anddi8 (0xfdad), 254
	xor a, a
	ldb w, 0x1
	ldb e, 0x91
	ldb d, 0x3
	call SwbtWr_QueuePostEvent
	ret

SetWall_ResolveStreamPtr:
	ld hl, iy
	extz xhl
	dec 1, hl
	sla xhl, 8
	addda32 xhl, 4362
	stda32 4349, xhl
	xor xhl, xhl
	ret

SetWall_StreamAdvanceBounded:
	inc 1, iy
	cp iy, 0xff
	jr le, SetWall_StreamAdv_Return
	ldda32 xhl, (4349)
	ld wa, (xhl + 3)
	cp wa, 0xffff
	jr ule, SetWall_StreamAdv_CheckBounds
	stdi8 (0x287a), 8
	jr SetWall_StreamAdv_Return

SetWall_StreamAdv_CheckBounds:
	cpda16 xwa, 0x28a2
	jr ule, SetWall_StreamAdv_LoadNext
	stdi8 (0x287a), 10
	jr SetWall_StreamAdv_Return

SetWall_StreamAdv_LoadNext:
	stda16 (0x28af), xwa
	ld hl, wa
	call SetWall_StreamIndexResolve
	ldda32 xhl, (4349)
	bitm 7, (xhl)
	jr nz, SetWall_StreamAdv_Reset
	stdi8 (0x287a), 11
	jr SetWall_StreamAdv_Return

SetWall_StreamAdv_Reset:
	lds iy, 5

SetWall_StreamAdv_Return:
	ret

SetWall_ForwardSkip:
	xor bc, bc

SetWall_ForwardSkip_Loop:
	cpdm8 0x288e, c
	jr z, SetWall_ForwardSkip_TargetFound
	ldda32 xhl, (4349)
	cpib_sri 0x07, 0xec, 0xf4, 0x82
	jr nz, SetWall_ForwardSkip_CheckType
	ordi8 0x287b, 32
	jr SetWall_ForwardSkip_Return

SetWall_ForwardSkip_CheckType:
	cpib_sri 0x07, 0xec, 0xf4, 0x81
	jr z, SetWall_ForwardSkip_Type81
	cpib_sri 0x07, 0xec, 0xf4, 0x84
	jr z, SetWall_ForwardSkip_Type84
	call SetWall_StreamAdvanceBounded
	cpdi8 (0x287a), 0
	jr nz, SetWall_ForwardSkip_Error
	jr SetWall_ForwardSkip_Loop

SetWall_ForwardSkip_Type84:
	lds iy, 5
	ldda32 xhl, (0x288f)
	stda32 4349, xhl
	jr SetWall_ForwardSkip_Loop

SetWall_ForwardSkip_Type81:
	inc 1, c
	call SetWall_StreamAdvanceBounded
	cpdi8 (0x287a), 0
	jr nz, SetWall_ForwardSkip_Error
	jr SetWall_ForwardSkip_Loop

SetWall_ForwardSkip_TargetFound:
	ldda32 xhl, (4349)
	cpib_sri 0x07, 0xec, 0xf4, 0x82
	jr nz, SetWall_ForwardSkip_Check84
	ordi8 0x287b, 32
	jr SetWall_ForwardSkip_Return

SetWall_ForwardSkip_Check84:
	cpib_sri 0x07, 0xec, 0xf4, 0x84
	jr nz, SetWall_ForwardSkip_SaveState
	lds iy, 5
	ldda32 xhl, (0x288f)

SetWall_ForwardSkip_SaveState:
	stda16 (0x289b), xiy
	push xwa
	ldda32 xwa, (4349)
	stda32 0x2897, xwa
	pop xwa
	jr SetWall_ForwardSkip_Return

SetWall_ForwardSkip_Error:
	ordi8 0x287b, 32
	stdi8 (0x287a), 0

SetWall_ForwardSkip_Return:
	ret

SetWall_InlineCodeBlock3:
	ret
	call	AccWrap_PlayModeDispatch
	.byte 0xc1, 0xa7
	pushw	wa
	push	xiz
	.byte 0x04
	ldw_da	wa, (0xffec)
	stda16	(0xf19e), wa
	push	xix
	pushw	bc
	ld	xix, 4421
	lds	bc, 0
	stb_d8	(0x286b), c
	push	xix
	call	SetWall_MiscDataAndCode_0x52
	pop	xix
	xor	bc, bc
	ldb_d8	c, (0x286b)
	ldb_d8	a, (0x286c)
	.byte 0xf3
	reti
	.byte 0xf0, 0xe4
	ld	xbc, 0xcfd961d9
	ldwio	0, 0xdf61
	popw	bc
	pop	xix
	ret
	.byte 0xc1, 0xa7
	pushw	wa
	push	xix
	swi	3
	xor	wa, wa
	ldb	a, 76
	call	CtrlPanel_SetIndicatorBit
	ret
	ret

SetWall_LoadToneGenData:
	ldb_d8 a, (7500)
	pushw wa
	call SetWall_LoadBankToToneGen
	popw wa
	ldb_d8 a, (7502)
	stb_da (0x00ffe3), a
	call SetWall_SyncToneGenToDRAM
	ret

SetWall_RetStub1:
	ret
SetWall_RetStub2:
	ret
SetWall_MiscDataAndCode:
	ret
	ret
	ld	xix, 0xf280
	ld	xiy, 4441
	ldw	bc, 16
	.byte 0x85
	scf
	xor	xwa, xwa
	ldb_da	a, (0xffe3)
	sla	xwa, 11
	ld	xix, 0x0ab000
	add	xix, xwa
	ld	xwa, 256
	add	xix, xwa
	ld	xiy, 4441
	ldw	bc, 16
	.byte 0x85
	scf
	.byte 0xc1
	ldw	iz, 0x3f8d
	.byte 0x8f
	jr	z, 7
	.byte 0xc1
	ldw	iz, 0x3f8d
	.byte 0xa7
	jr	z, 10
	ldb	a, 142
	call	UI_PostModeChangeEvent
	jp	SetWall_MiscDataAndCode_0x51
	ldb	a, 131
	call	UI_PostModeChangeEvent
	ret
	ldda32	xwa, (4349)
	push	xwa
	xor	xwa, xwa
	ldb_d8	a, (0x286b)
	.byte 0xc2, 0xe3
	swi	7
	nop
	stb_d8	(1902), d
	.byte 0x50, 0xf2
	nop
	nop
	jr	16
	ld	xix, 0x0ab000
	sla	xwa, 11
	add	xix, xwa
	add	xix, 208
	xor	xbc, xbc
	xor	de, de
	.byte 0xc3
	reti
	.byte 0xf0, 0xe8
	ldb	a, 201
	ldw	hl, 0x6607
	decf
	push	xbc
	push	xde
	push	xix
	call	SetWall_MiscDataAndCode_0xCB
	pop	xix
	pop	xde
	pop	xbc
	.byte 0xe7
	ldw	ix, 0xda81
	ld	w, 0
	cp	de, 48
	jr	c, -33
	ld	xde, xbc
	cp	xbc, 0
	jr	z, 23
	ld	xde, xbc
	mul	bc, 100
	ldw_d16	hl, (0x286d)
	div	xbc, xhl
	inc	1, bc
	cp	bc, 100
	jr	c, 3
	ldw	bc, 99
	.byte 0xf1
	.ascii "l(CX"
	stda32	4349, xwa
	ret
	.byte 0xe7
	ldw	ix, 0xdaa8
	incm8	1, (xwa-40)
	.byte 0xd3
	reti
	.byte 0xf0, 0xe0
	ldb	c, 219
	.byte 0xcf
	swi	7
	swi	7
	jr	z, 55
	push	xhl
	.byte 0xe7
	ldw	ix, 7428
	.byte 0x04
	push	sr
	.byte 0xf2, 0xe7
	ldw	ix, 0xe105
	swi	5
	rcf
	ldb	c, 179
	divs8rr	c, l
	jr	z, 35
	.byte 0xe7
	ldw	ix, 0xe761
	ldw	ix, 7428
	.byte 0x04
	push	sr
	.byte 0xf2, 0xe7
	ldw	ix, 0xe105
	swi	5
	rcf
	ldb	c, 179
	inc	6, l
	ret
	ld	hl, (xhl+3)
	cp	hl, 0xffff
	jr	z, 5
	.byte 0xe7
	ldw	ix, 0x6861
	.byte 0xe0
	ret
	push	xiy
	ldda32	xiy, (7514)
	extz	xhl
	dec	1, xhl
	sla	xhl, 8
	add	xiy, xhl
	stda32	4349, xiy
	xor	xhl, xhl
	pop	xiy
	ret

SetWall_SyncToneGenToDRAM:
	ldw_d16 xwa, (0xf22f)
	stda16 (0x286f), xwa
	ldw_d16 xwa, (0xf231)
	stda16 (0x2871), xwa
	xor xwa, xwa
	ldb_da a, (0x00ffe3)
	sla xwa, 11
	ld xiy, 0xab000
	add xiy, xwa
	ld xix, 0xf180
	ldw bc, 0x800
	ldir85
	ldw_d16 xwa, (0x286f)
	stda16 (0xf22f), xwa
	ldw_d16 xwa, (0x2871)
	stda16 (0xf231), xwa
	ldw_d16 xwa, (0xf19e)
	stw_da (0x00ffec), xwa
	anddi8 (0x28a5), 254
	cps wa, 0
	jr z, SetWall_Sync_CheckPanelBit
	ordi8 0x28a5, 1

SetWall_Sync_CheckPanelBit:
	call SeqTimer_PostTempoUpdate
	cpdi8 (0xf23d), 255
	jr z, SetWall_Sync_PanelOff
	bitda 2, (0xfdad)
	jr z, SetWall_Sync_FinalUpdate
	anddi8 (0xfdad), 251
	xor a, a
	jr SetWall_Sync_PostEvent

SetWall_Sync_PanelOff:
	bitda 2, (0xfdad)
	jr nz, SetWall_Sync_FinalUpdate
	ordi8 0xfdad, 4
	ldb a, 0x4

SetWall_Sync_PostEvent:
	stdi8 (4330), 1
	ldb e, 0x91
	ldb d, 0x3
	ldb w, 0x4
	call SwbtWr_QueueMainEvent
	call SwbtWr_ReinitBothBanks

SetWall_Sync_FinalUpdate:
	stdi8 (4596), 1
	call BitMapOut_RenderDisplay
	stdi8 (4596), 1
	anddi8 (0x28a7), 247
	call SeqPlay_CheckStartConditions
	anddi8 (0x28b1), 254
	call Audio_CheckSubsystemReady
	ret

SetWall_LoadBankToToneGen:
	ldw_da xwa, (0x00ffec)
	stda16 (0xf19e), xwa
	ld xix, 0xab000
	xor xhl, xhl
	ldb_da l, (0x00ffe3)
	sla xhl, 11
	add xix, xhl
	ld xiy, 0xf180
	ldw bc, 0x800
	ldir85
	ret

