; =============================================================================
; Wallpaper & Wall Display
; =============================================================================
;
; Wallpaper image loading and wall display update routines.
; Manages the panel slot selection/matching system for the
; background display.
; =============================================================================

SetWall_X:
	ld (0x030452:24), xwa
	ret

SetWall_JumpStubData:
	anddi8 (3296), 254
	ld	(3295:16), 0
	call	CDlikeSwTtl_SendStartEvt
	call	SetWall_UpdateSlotIndex
	ret

SetWall_UpdateSlotIndex:
	ld xhl, 0xf1a0
	xor wa, wa
	ld a, (3295:16)
	ld iy, wa
	ldb_sri A, 0x07, 0xec, 0xf4
	ld (0x2873:16), a
	ret

SetWall_InlineCodeBlock:
	call	SetWall_InlineCodeBlock2
	ret
MiddleFuncCall_DispatchData_Code_Helper:
	call	SetWall_InlineCodeBlock2
	cpdi8 (3295), 7
	jr	z, MiddleFuncCall_DispatchData_Code_Helper_Skip
	call	CDlikeSwTtl_DispatchData_0x6
MiddleFuncCall_DispatchData_Code_Helper_Skip:
	call	CDlikeSwTtl_SendStartEvt
	ld	a, (3295:16)
	cp	a, 15
	jr	z, MiddleFuncCall_DispatchData_Code_Helper_Skip2
	inc	1, a
MiddleFuncCall_DispatchData_Code_Helper_Skip2:
	ld	(3295:16), a
	call	SetWall_UpdateSlotIndex
	ret
MiddleFuncCall_DispatchData_Code_Helper2:
	call	SetWall_InlineCodeBlock2
	cpdi8 (3295), 8
	jr	z, MiddleFuncCall_DispatchData_Code_Helper2_Skip
	call	CDlikeSwTtl_DispatchData_0x6
MiddleFuncCall_DispatchData_Code_Helper2_Skip:
	call	CDlikeSwTtl_SendStartEvt
	ld	a, (3295:16)
	cp	a, 0:i3
	jr	z, MiddleFuncCall_DispatchData_Code_Helper2_Skip2
	dec	1, a
MiddleFuncCall_DispatchData_Code_Helper2_Skip2:
	ld	(3295:16), a
	call	SetWall_UpdateSlotIndex
	ret
; Two 20-byte permutations of 0..0x13 (the SetWall slot numbers).  No reader:
; no instruction operand and no 32-bit data pointer in the v10 ROM names
; 0xF1EE8D..0xF1EEB4; purpose not established.  Was decoded as `nop / push sr
; / ldw (3:8),1284:io / halt / ei 7 ...` after the `ret` above.
NoRef_SetWall_SlotPerm20x2:
	.byte 0x00, 0x02, 0x00, 0x0a, 0x03, 0x04, 0x05, 0x06, 0x0b, 0x08, 0x09, 0x01, 0x13, 0x0c, 0x0d, 0x0e, 0x0f, 0x07, 0x11, 0x12
	.byte 0x02, 0x0b, 0x01, 0x04, 0x05, 0x06, 0x07, 0x11, 0x09, 0x0a, 0x03, 0x08, 0x0d, 0x0e, 0x0f, 0x10, 0x10, 0x12, 0x13, 0x0c
SetWall_InlineCodeBlock_Sub:
	call	SetWall_InlineCodeBlock_0x7F
	ret
	ld	a, (0x2873:16)
	cp	a, 13
	jr	z, SetWall_InlineCodeBlock_Sub_Skip
	cp	a, 16
	jr	z, SetWall_InlineCodeBlock_Sub_Skip
	cp	a, 15
	jr	z, SetWall_InlineCodeBlock_Sub_Skip
	cp	a, 14
	jr	z, SetWall_InlineCodeBlock_Sub_Skip
	call	CDlikeSwTtl_SendStartEvt
	ld	xhl, 0xf1a0
	xor	w, w
	ld	a, (3295:16)
	ld	iy, wa
	ld_rrb a, xhl, iy
	cp a, 13
	jr	z, SetWall_InlineCodeBlock_Sub_Skip
	cp	a, 16
	jr	z, SetWall_InlineCodeBlock_Sub_Skip
	cp	a, 15
	jr	z, SetWall_InlineCodeBlock_Sub_Skip
	cp	a, 14
	jr	z, SetWall_InlineCodeBlock_Sub_Skip
	jr	SetWall_InlineCodeBlock_Sub_Return
SetWall_InlineCodeBlock_Sub_Skip:
	call	CDlikeSwTtl_DispatchData_0x4A
SetWall_InlineCodeBlock_Sub_Return:
	ret
	call	SetWall_InlineCodeBlock_0x7F
	ret
; 20 x u8 mask per SetWall slot number 0..0x13 (0xFF, or 0 for slots 13-16):
; SetWall_CompareAndSwap (0xF1EFF7) and SetWall_InlineCodeBlock2_Skip read it with
; `ld xde,<this>; ld_rrb c,xde,iy`, iy = a slot number from the RAM slot table
; at 0xF1A0 -- two such masks are then ANDed (`and a,c`) to test a pair of slots.
SetWall_SlotMaskTable:
	.byte 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x00, 0x00, 0x00, 0x00, 0xff, 0xff, 0xff

SetWall_EventHandler:
	bit 2, (1056:16)
	jr z, SetWall_EventHandler_Active
	jp SetWall_Return

SetWall_EventHandler_Active:
	xor wa, wa
	ld a, (3295:16)
	ld iy, wa
	push xde
	ld xde, 0xf1a0
	ldb_sri A, 0x07, 0xe8, 0xf4
	pop xde
	cp a, (0x2873:16)
	jr nz, SetWall_EventHandler_Dispatch
	call CDlikeSwTtl_SendStartEvt
	jrl SetWall_ToReturn

SetWall_EventHandler_Dispatch:
	ld a, (0x2873:16)
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
	cp a, (0x2873:16)
	jr z, SetWall_NewSlotSelected
	inc 1, iy
	cp iy, 0x10
	jr c, SetWall_SearchSelf_Loop
	jr SetWall_CompareAndSwap

SetWall_MatchedSameSlot:
	ld a, (3295:16)
	xor w, w
	cp wa, iy
	jr nz, SetWall_NewSlotSelected
	jrl SetWall_CopySlotData

SetWall_NewSlotSelected:
	ld (0x7f42:16), 26
	ld (3298:16), 0
	ld a, (0x2873:16)
	cp a, 0x10
	jr z, SetWall_DispatchSlotEvent
	ld (3298:16), 2
	cp a, 0xf
	jr z, SetWall_DispatchSlotEvent
	ld (3298:16), 3
	cp a, 0xe
	jr z, SetWall_DispatchSlotEvent
	ld (3298:16), 1

SetWall_DispatchSlotEvent:
	xor wa, wa
	ld a, 0xee:opc
	call SoundCtrl_SendCommand

SetWall_ToReturn:
	jp SetWall_Return

SetWall_CompareAndSwap:
	ld a, (0x2873:16)
	xor w, w
	ld iy, wa
	push xde
	ld xde, SetWall_InlineCodeBlock_0xCD
	ldb_sri C, 0x07, 0xe8, 0xf4
	ld a, (3295:16)
	ld iy, wa
	ld xde, 0xf1a0
	ldb_sri A, 0x07, 0xe8, 0xf4
	ld (3297:16), a
	ld iy, wa
	ld xde, SetWall_InlineCodeBlock_0xCD
	ldb_sri A, 0x07, 0xe8, 0xf4
	pop xde
	and a, c
	cp a, 0:i3
	jr z, SetWall_CopySlotData
	jr SetWall_IncompatibleSlot

SetWall_CopySlotData:
	ld a, (3295:16)
	ld iy, wa
	push xde
	ld xde, 0xf1a0
	ldb_sri A, 0x07, 0xe8, 0xf4
	pop xde
	ld (3297:16), a
	ld (4438:16), a
	cp (0x0340ea:24), 0x00
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
	ld	(3295:16), 8
	call	SetWall_UpdateSlotIndex
	ret
MiddleFuncCall_DispatchData_Code_Helper3:
	call	SetWall_InlineCodeBlock2
	call	CDlikeSwTtl_SendStartEvt
	ld	(3295:16), 0
	call	SetWall_UpdateSlotIndex
	ret
	ret
	ret
	ret
	ret

SetWall_SlotSetup:
	bit 2, (1056:16)
	jr z, SetWall_SlotSetup_Active
	jp SetWall_SlotSetup_Return

SetWall_SlotSetup_Active:
	call CDlikeSwTtl_SendStartEvt
	ld wa, (0x00ffec:24)
	ld (0x2875:16), wa
	ld a, (3295:16)
	inc 1, a
	ld (0x2877:16), a
	call Scoop_SpecialMode_ParamCheckBound
	call SetWall_SlotBitUpdate
	ld wa, (0x2875:16)
	ld (0x00ffec:24), wa
	xor wa, wa
	ld a, (3295:16)
	ld iy, wa
	ld a, (0x2873:16)
	push xde
	ld xde, 0xf1a0
	stb_dri A, 0x07, 0xe8, 0xf4
	pop xde
	call CDlikeSwTtl_SendResetEvent
	call SetWall_UpdateSlotIndex

SetWall_SlotSetup_Return:
	ret

SetWall_SlotUpdate:
	bit 2, (1056:16)
	jr z, SetWall_SlotUpdate_Active
	jp SetWall_SlotUpdate_Return

SetWall_SlotUpdate_Active:
	call CDlikeSwTtl_SendStartEvt
	call CDlikeSwTtl_SendResetEvent
	call SetWall_UpdateSlotIndex

SetWall_SlotUpdate_Return:
	ret

SetWall_DataBlock1:
	ld	(0x7f42:16), 0
	ld	a, (0xffe3:24)
	ld	(3391:16), a
	ret
	ret
	ret
	ret

SetWall_ACSlotChange:
	cp (3391:16), 10
	jr z, SetWall_ACSlot_CheckPanel
	ld a, (3391:16)
	cp a, (0xffe3:24)
	jr nz, SetWall_ACSlot_IndexChange

SetWall_ACSlot_CheckPanel:
	bit 2, (0xfdad:16)
	jr z, SetWall_ACSlot_NoPanel
	cp (3390:16), 3
	jr nz, SetWall_ACSlot_PanelChange
	cp (3391:16), 10
	jr z, SetWall_ACSlot_AllChange
	jp SetWall_ACSlot_NormalChange

SetWall_ACSlot_NoPanel:
	cp (3390:16), 3
	jr z, SetWall_ACSlot_Direct
	cp (3391:16), 10
	jr z, SetWall_ACSlot_AllChange
	jp SetWall_ACSlot_NormalChange

SetWall_ACSlot_Direct:
	cp (0x0340ea:24), 0x00
	jr z, SetWall_ACSlot_DirectLocal
	call CDlikeSwTtl_SendEvent8C_A
	jp SetWall_ACSlot_Return

SetWall_ACSlot_DirectLocal:
	call SetWall_LocalSlotChange
	jp SetWall_ACSlot_Return

SetWall_ACSlot_PanelChange:
	cp (0x0340ea:24), 0x00
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
	ld l, (0x2878:16)
	pushw hl
	ld a, (3391:16)
	ld (0x2878:16), a
	call SeqVoice_InitEntry
	popw hl
	ld (0x2878:16), l
	xor hl, hl
	ld l, (3390:16)
	dec 1, l
	sla l, 4
	ld xde, SetWall_SlotOrderTable
	lda_dri XIY, 0x07, 0xe8, 0xec
	ld xix, 0xab000
	xor xwa, xwa
	ld a, (3391:16)
	sla xwa, 11
	lda_dri XIX, 0x07, 0xf0, 0xe0
	ld xwa, 0x20
	add xix, xwa
	ldw bc, 0x10
	ldir85
	push xhl
	push xde
	ld a, 0x0:opc
	cp (3390:16), 3
	jr nz, SetWall_WriteSingle_SetMode
	ld a, 0xff:opc

SetWall_WriteSingle_SetMode:
	ld xix, 0xab000
	xor xhl, xhl
	ld l, (3391:16)
	sla xhl, 11
	lda_dri XIX, 0x07, 0xf0, 0xec
	ld xde, xix
	ld xhl, 0xbd
	add xde, xhl
	ld (xde), a
	pop xde
	pop xhl
	ld xix, 0xab000
	xor xwa, xwa
	ld a, (3391:16)
	sla xwa, 11
	lda_dri XIX, 0x07, 0xf0, 0xe0
	ld xwa, 0x110
	add xix, xwa
	ldw (xix), 0xffff
	xor xwa, xwa
	ld a, (3391:16)
	xor xbc, xbc
	ld c, (3390:16)
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
	ld l, (3390:16)
	dec 1, l
	sla l, 4
	ld xde, SetWall_SlotOrderTable
	lda_dri XIY, 0x07, 0xe8, 0xec
	ldib_erp 0x34, 0

SetWall_WriteAll_Loop:
	ld xix, 0xab000
	xor xwa, xwa
	stb_erp A, 0x34
	sla xwa, 11
	add xix, xwa
	ld xwa, 0x20
	add xix, xwa
	lda_dri XIY, 0x07, 0xe8, 0xec
	ldw bc, 0x10
	ldir85
	ld xix, 0xab000
	xor xwa, xwa
	stb_erp A, 0x34
	sla xwa, 11
	add xix, xwa
	ld xwa, 0xbd
	add xix, xwa
	ld a, 0x0:opc
	cp (3390:16), 3
	jr nz, SetWall_WriteAll_ModeSet
	ld a, 0xff:opc

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
	ld a, (3391:16)
	xor xbc, xbc
	ld c, (3390:16)
	call SndParam_UpdateChannels
	call SetWall_SyncToneGenToDRAM
	call VoiceChannels_InitPanFromPreset
	ret

SetWall_NopPadding:
	.fill 6, 1, 0x0e

SetWall_LocalSlotChange:
	cp (3391:16), 10
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
	ld l, (3390:16)
	dec 1, l
	sla l, 4
	ld xde, SetWall_SlotOrderTable
	lda_dri XIY, 0x07, 0xe8, 0xec
	ldib_erp 0x34, 0

SetWall_LocalWriteAll_Loop:
	ld xix, 0xab000
	xor xwa, xwa
	stb_erp A, 0x34
	sla xwa, 11
	add xix, xwa
	ld xwa, 0x20
	add xix, xwa
	lda_dri XIY, 0x07, 0xe8, 0xec
	ldw bc, 0x10
	ldir85
	ld xix, 0xab000
	xor xwa, xwa
	stb_erp A, 0x34
	sla xwa, 11
	add xix, xwa
	ld xwa, 0xbd
	add xix, xwa
	ld a, 0x0:opc
	cp (3390:16), 3
	jr nz, SetWall_LocalWriteAll_Mode
	ld a, 0xff:opc

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
	ld a, (3391:16)
	xor xbc, xbc
	ld c, (3390:16)
	call SndParam_UpdateChannels
	call SetWall_SyncToneGenToDRAM
	call VoiceChannels_InitPanFromPreset
	ret

SetWall_ExternalSync:
	call CDlikeSwTtl_SendEvent8C_0
	ret

SetWall_InlineCodeBlock2:
	xor	wa, wa
	ld	a, (3295:16)
	ld	iy, wa
	push	xde
	ld	xde, 0xf1a0
	ld_rrb a, xde, iy
	pop xde
	cp a, (10355:16)
	jr	nz, SetWall_InlineCodeBlock2_Skip
	jp	SetWall_InlineCodeBlock2_0x5E
SetWall_InlineCodeBlock2_Skip:
	ld	a, (0x2873:16)
	xor	w, w
	ld	iy, wa
	push	xde
	ld	xde, SetWall_InlineCodeBlock_0xCD
	ld_rrb c, xde, iy
	ld a, (3295:16)
	ld iy, wa
	ld	xde, 0xf1a0
	ld_rrb a, xde, iy
	ld iy, wa
	ld	xde, SetWall_InlineCodeBlock_0xCD
	ld_rrb a, xde, iy
	pop xde
	and	a, c
	cp	a, 0:i3
	jr	z, SetWall_InlineCodeBlock2_Skip2
	jr	SetWall_InlineCodeBlock2_Join
SetWall_InlineCodeBlock2_Skip2:
	jp	SetWall_InlineCodeBlock2_0x5E
SetWall_InlineCodeBlock2_Join:
	call	SetWall_CrossTypeChange
	ret

SetWall_CrossTypeChange:
	ld xhl, 0xf1a0
	xor wa, wa
	ld a, (3295:16)
	ld iy, wa
	ld a, (0x2873:16)
	ldb_sri C, 0x07, 0xec, 0xf4
	ld (0x2873:16), c
	stb_dri A, 0x07, 0xec, 0xf4
	ld (3386:16), a
	ld a, (3295:16)
	ld (3301:16), a
	call SetWall_CrossType_Validate
	call Audio_CheckSubsystemReady
	ret

; 20 x u8 slot -> type map, 0xFF = no type.  SetWall_CrossType_MapLookup reads it with
; `ld xde,<this>; ld l,(xde+hl)` (hl = slot) and branches to SetWall_CrossType_Reset on
; 0xFF; SetWall_ParseB0ControlChange does the same lookup and compares the entry with a.
; (Formerly decoded as instructions.)
SetWall_SlotTypeMap:
	.byte 0x00, 0x02, 0x01, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x04, 0x05
	.byte 0x06, 0x03, 0x0f, 0xff, 0xff, 0xff, 0xff, 0x0c, 0x0d, 0x0e

SetWall_CrossType_Validate:
	and (0x2879:16), 252
	call SetWall_ParserInit
	ld a, (3301:16)
	cp a, 0xf
	jrl ugt, SetWall_CrossType_Reset
	ld a, (0x2873:16)
	cp a, 0x13
	jrl ugt, SetWall_CrossType_Reset
	ld (0x287a:16), 0
	and (0x287b:16), 191
	xor hl, hl
	ld l, (3301:16)
	push xde
	ld xde, 0xf1a0
	ldb_sri A, 0x07, 0xe8, 0xec
	pop xde
	cp a, (0x2873:16)
	jr z, SetWall_CrossType_Reset
	ld l, (3301:16)
	xor h, h
	push xde
	ld xde, 0xf1a0
	ldb_sri L, 0x07, 0xe8, 0xec
	pop xde
	cp l, 0xc
	jr nz, SetWall_CrossType_ClearBit0
	or (0x2879:16), 1
	jr SetWall_CrossType_CheckDest

SetWall_CrossType_ClearBit0:
	and (0x2879:16), 254

SetWall_CrossType_CheckDest:
	cp (0x2873:16), 12
	jr nz, SetWall_CrossType_ClearBit1
	or (0x2879:16), 2
	jr SetWall_CrossType_MapLookup

SetWall_CrossType_ClearBit1:
	and (0x2879:16), 253

SetWall_CrossType_MapLookup:
	xor h, h
	push xde
	ld xde, SetWall_SlotTypeMap
	ldb_sri L, 0x07, 0xe8, 0xec
	pop xde
	cp l, 0xff
	jr z, SetWall_CrossType_Reset
	ld (0x287c:16), l
	ld a, (3301:16)
	inc 1, a
	pushw wa
	ld (4596:16), 0
	call SeqPlay_CheckStartConditions
	popw wa
	call SetWall_ParsePatternStream

SetWall_CrossType_Reset:
	pushw wa
	xor a, a
	call Part_InitVoiceDefaults
	popw wa
	and (0x2879:16), 252
	ret

; 3 rows x 16 slot numbers.  SetWall_WriteSingleSlot, SetWall_WriteAllSlots and SetWall_LocalWriteAll
; run `ld l,(0x0D3E); dec 1,l; sla l,4; ld xde,<this>; lda xiy,(xde+hl)`:
; row = (byte at RAM 0x0D3E) - 1, 16 bytes per row.
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
	ld de, (0x00ffec:24)
	ld a, (3295:16)
	rcf
	stcf_a_16 de
	stb_erp A, 0x3c
	ld (0x00ffec:24), de
	stw_erp DE, 0x3e
	ret

SetWall_ParsePatternStream:
	and (0x287b:16), 251
	xor w, w
	ld (0x287a:16), 0
	ld (0x287d:16), wa
	ldw (0x287f:16), 1
	call SetWall_SlotResolve
	cp (0x287a:16), 0
	jr z, SetWall_ParseStream_Init
	jrl SetWall_ParseStream_Return

SetWall_ParseStream_Init:
	push xhl
	ld xhl, (4349:16)
	ld (0x2881:16), xhl
	pop xhl
	ld (0x2885:16), iy
	ld wa, (0x28af:16)
	ld (0x2887:16), wa
	ld (0x2889:16), iy
	ld (0x288b:16), wa
	ld ix, iy
	ld hl, (3376:16)

SetWall_ParseStream_MainLoop:
	push xde
	ld xde, (4349:16)
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
	ld w, 0xf0:opc
	and w, a
	cp w, 0x90
	jr z, SetWall_ParseStream_ReadEvent
	cp w, 0xc0
	jr z, SetWall_ParseStream_TypeC0
	cp w, 0xb0
	jrl z, SetWall_ParseStream_TypeB0

SetWall_ParseStream_Advance:
	call SetWall_AdvanceStreamPos
	cp (0x287a:16), 0
	jr z, SetWall_ParseStream_MainLoop
	jrl SetWall_ParseStream_Return

SetWall_ParseStream_CheckD1D2:
	bit 0, (0x2879:16)
	jr nz, SetWall_ParseStream_Advance

SetWall_ParseStream_ReadEvent:
	push xhl
	ld xhl, (0x2881:16)
	stb_dri A, 0x07, 0xec, 0xf0
	pop xhl
	call SetWall_AdvanceWritePos
	cp (0x287a:16), 0
	jrl nz, SetWall_ParseStream_Return
	call SetWall_AdvanceStreamPos
	cp (0x287a:16), 0
	jrl nz, SetWall_ParseStream_Return
	push xde
	ld xde, (4349:16)
	bit_dri 7, 0x07, 0xe8, 0xf4
	pop xde
	jrl nz, SetWall_ParseStream_MainLoop
	push xde
	ld xde, (4349:16)
	ldb_sri A, 0x07, 0xe8, 0xf4
	pop xde
	jr SetWall_ParseStream_ReadEvent

SetWall_ParseStream_TypeC0:
	ldb_erp A, 0x3c
	ld a, (0x2879:16)
	and a, 0x3
	stb_erp A, 0x3c
	jr nz, SetWall_ParseStream_Advance
	bit 1, (4393:16)
	jr nz, SetWall_ParseStream_TypeC0_Loop
	push xiz
	ld xiz, (4349:16)
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
	ld (4349:16), xiz
	pop xiz
	cp l, 0:i3
	jrl nz, SetWall_ParseStream_Advance

SetWall_ParseStream_TypeC0_Loop:
	xor c, c

SetWall_ParseStream_C0_Iter:
	cp c, 2:i3
	jr nz, SetWall_ParseStream_C0_Read
	ld a, (0x287c:16)

SetWall_ParseStream_C0_Read:
	push xhl
	ld xhl, (0x2881:16)
	stb_dri A, 0x07, 0xec, 0xf0
	pop xhl
	pushw bc
	call SetWall_AdvanceWritePos
	popw bc
	cp (0x287a:16), 0
	jrl nz, SetWall_ParseStream_Return
	pushw bc
	call SetWall_AdvanceStreamPos
	popw bc
	cp (0x287a:16), 0
	jrl nz, SetWall_ParseStream_Return
	inc 1, c
	push xde
	ld xde, (4349:16)
	bit_dri 7, 0x07, 0xe8, 0xf4
	pop xde
	jrl nz, SetWall_ParseStream_MainLoop
	push xde
	ld xde, (4349:16)
	ldb_sri A, 0x07, 0xe8, 0xf4
	pop xde
	jr SetWall_ParseStream_C0_Iter

SetWall_ParseStream_TypeB0:
	ld c, a
	and c, 0x4
	sll c, 5
	ld (4340:16), c
	ld (3310:16), a
	and (3310:16), 2
	pushw bc
	ld c, 0x6:opc

SetWall_ParseStream_B0_ShiftLoop:
	sla_sd16b 0xee, 0x0c
	djnz8 c, SetWall_ParseStream_B0_ShiftLoop
	popw bc
	bit 1, (4393:16)
	jr nz, SetWall_ParseStream_B0_Iter
	push xiz
	ld xiz, (4349:16)
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
	ld (4349:16), xiz
	pop xiz
	cp (0x287a:16), 0
	jrl nz, SetWall_ParseStream_Return
	bit 0, (0x289d:16)
	jr nz, SetWall_ParseStream_B0_Iter
	bit 2, (0x289d:16)
	jrl nz, SetWall_ParseStream_ReadEvent
	jrl SetWall_ParseStream_Advance

SetWall_ParseStream_B0_Iter:
	xor c, c

SetWall_ParseStream_B0_ByteLoop:
	cp c, 0:i3
	jr nz, SetWall_ParseStream_B0_Byte1
	bit 0, (3389:16)
	jr z, SetWall_ParseStream_B0_Write
	and a, 0xfc
	jr SetWall_ParseStream_B0_Write

SetWall_ParseStream_B0_Byte1:
	cp c, 2:i3
	jr nz, SetWall_ParseStream_B0_Byte3
	cp (4340:16), 181
	jr z, SetWall_ParseStream_B0_Write
	cp (4340:16), 182
	jr z, SetWall_ParseStream_B0_Write
	cp (4340:16), 183
	jr z, SetWall_ParseStream_B0_Write
	ld a, (0x287c:16)

SetWall_ParseStream_B0_Byte3:
	cp c, 3:i3
	jr nz, SetWall_ParseStream_B0_Byte4
	bit 1, (4393:16)
	jr nz, SetWall_ParseStream_B0_Write
	ld a, (3388:16)
	jr SetWall_ParseStream_B0_Write

SetWall_ParseStream_B0_Byte4:
	cp c, 4:i3
	jr nz, SetWall_ParseStream_B0_Write
	cp (3387:16), 255
	jr z, SetWall_ParseStream_B0_Write
	bit 1, (4393:16)
	jr nz, SetWall_ParseStream_B0_Write
	ld a, (3387:16)

SetWall_ParseStream_B0_Write:
	push xhl
	ld xhl, (0x2881:16)
	stb_dri A, 0x07, 0xec, 0xf0
	pop xhl
	pushw bc
	call SetWall_AdvanceWritePos
	popw bc
	cp (0x287a:16), 0
	jr nz, SetWall_ParseStream_Return
	pushw bc
	call SetWall_AdvanceStreamPos
	popw bc
	cp (0x287a:16), 0
	jr nz, SetWall_ParseStream_Return
	inc 1, c
	push xde
	ld xde, (4349:16)
	bit_dri 7, 0x07, 0xe8, 0xf4
	pop xde
	jrl nz, SetWall_ParseStream_MainLoop
	push xde
	ld xde, (4349:16)
	ldb_sri A, 0x07, 0xe8, 0xf4
	pop xde
	jrl SetWall_ParseStream_B0_ByteLoop

SetWall_ParseStream_End:
	push xhl
	ld xhl, (0x2881:16)
	stb_dri A, 0x07, 0xec, 0xf0
	pop xhl
	ld wa, (0x2887:16)
	ld (0x289f:16), wa
	call SetWall_EventOutput
	call SetWall_EventAdvanceCheck

SetWall_ParseStream_Return:
	ret

SetWall_ParserInit:
	push xiy
	ld (0x28a1:16), 16
	ld iy, (0x286d:16)
	ld (0x28a2:16), iy
	ld xiy, (7514:16)
	ld (3304:16), xiy
	ldw (3376:16), 0
	ld (0x289e:16), 15
	pop xiy
	ret

SetWall_AdvanceStreamPos:
	inc 1, iy
	cp iy, 0xff
	jr ule, SetWall_AdvanceStream_Return
	ld hl, (0x288b:16)
	call SetWall_StreamIndexResolve
	ld xhl, (4349:16)
	ld wa, (xhl + 3)
	ld (0x288b:16), wa
	ld hl, wa
	call SetWall_StreamIndexResolve
	ld xhl, (4349:16)
	bitm 7, (xhl)
	jr nz, SetWall_AdvanceStream_Reset
	ld (0x287a:16), 2
	jr SetWall_AdvanceStream_Return

SetWall_AdvanceStream_Reset:
	ld iy, 5:i3

SetWall_AdvanceStream_Return:
	ret

SetWall_AdvanceWritePos:
	ld xwa, (4349:16)
	push xwa
	inc 1, ix
	cp ix, 0xff
	jr ule, SetWall_AdvanceWrite_Return
	ld xhl, (0x2881:16)
	ld wa, (xhl + 3)
	ld (0x2887:16), wa
	ld hl, wa
	call SetWall_StreamIndexResolve
	ld xhl, (4349:16)
	bitm 7, (xhl)
	jr nz, SetWall_AdvanceWrite_Reset
	ld (0x287a:16), 2
	jr SetWall_AdvanceWrite_Return

SetWall_AdvanceWrite_Reset:
	ld (0x2881:16), xhl
	ld ix, 5:i3

SetWall_AdvanceWrite_Return:
	pop xwa
	ld (4349:16), xwa
	ret

SetWall_SkipC0Scanner:
	xor hl, hl
	call SetWall_AdvanceStreamPos
	cp (0x287a:16), 0
	jr nz, SetWall_SkipC0_Return
	call SetWall_AdvanceStreamPos
	cp (0x287a:16), 0
	jr nz, SetWall_SkipC0_Return
	push xde
	ld xde, (4349:16)
	ldb_sri A, 0x07, 0xe8, 0xf4
	pop xde
	call SetWall_AdvanceStreamPos
	cp (0x287a:16), 0
	jr nz, SetWall_SkipC0_Return
	push xde
	ld xde, (4349:16)
	ldb_sri A, 0x07, 0xe8, 0xf4
	pop xde
	xor l, l
	cp a, 0:i3
	jr ule, SetWall_SkipC0_Return
	ld l, 0x1:opc

SetWall_SkipC0_Return:
	ret

SetWall_ParseB0ControlChange:
	ld a, (0x2873:16)
	ld (3378:16), a
	call SetWall_AdvanceStreamPos
	cp (0x287a:16), 0
	jrl nz, SetWall_B0CC_Return
	call SetWall_AdvanceStreamPos
	cp (0x287a:16), 0
	jrl nz, SetWall_B0CC_Return
	ld (3387:16), 255
	push xde
	ld xde, (4349:16)
	ldb_sri A, 0x07, 0xe8, 0xf4
	pop xde
	and a, 0x7f
	or (4340:16), a
	ld a, (4340:16)
	cp a, 0x48
	jr z, SetWall_B0CC_Type48
	and (0x289d:16), 251
	ld l, (0x2873:16)
	xor h, h
	push xde
	ld xde, SetWall_SlotTypeMap
	ldb_sri L, 0x07, 0xe8, 0xec
	pop xde
	cp a, l
	jr nz, SetWall_B0CC_ClearFlags
	call SetWall_AdvanceStreamPos
	cp (0x287a:16), 0
	jrl nz, SetWall_B0CC_Return
	push xde
	ld xde, (4349:16)
	ldb_sri A, 0x07, 0xe8, 0xf4
	pop xde
	cp a, 3:i3
	jr c, SetWall_B0CC_ClearFlags
	cp a, 0xb
	jr ugt, SetWall_B0CC_ClearFlags
	cp a, 6:i3
	jr z, SetWall_B0CC_ClearFlags
	ldb_erp A, 0x3c
	ld a, (0x2879:16)
	and a, 0x3
	stb_erp A, 0x3c
	jr z, SetWall_B0CC_BankSelect
	ld c, 0x3:opc
	cp a, c
	jr nz, SetWall_B0CC_ClearFlags

SetWall_B0CC_BankSelect:
	or (0x289d:16), 1
	and (3389:16), 254
	ld (3388:16), a
	jrl SetWall_B0CC_Return

SetWall_B0CC_ClearFlags:
	and (0x289d:16), 250
	jrl SetWall_B0CC_Return
	jrl SetWall_B0CC_Return

SetWall_B0CC_Type48:
	call SetWall_AdvanceStreamPos
	cp (0x287a:16), 0
	jrl nz, SetWall_B0CC_Return
	push xde
	ld xde, (4349:16)
	ldb_sri A, 0x07, 0xe8, 0xf4
	pop xde
	cp a, 5:i3
	jr nz, SetWall_B0CC_Type48_Check12
	and (0x289d:16), 254
	call SetWall_AdvanceStreamPos
	cp (0x287a:16), 0
	jr nz, SetWall_B0CC_Return
	call SetWall_AdvanceStreamPos
	cp (0x287a:16), 0
	jr nz, SetWall_B0CC_Return
	push xde
	ld xde, (4349:16)
	ldb_sri A, 0x07, 0xe8, 0xf4
	pop xde
	and a, 0x7f
	or a, (3310:16)
	ldb_erp A, 0x3c
	and a, 0xfc
	stb_erp A, 0x3c
	jr nz, SetWall_B0CC_Type48_SetFlag
	and (0x289d:16), 251
	jr SetWall_B0CC_Return

SetWall_B0CC_Type48_SetFlag:
	or (0x289d:16), 4
	jr SetWall_B0CC_Return

SetWall_B0CC_Type48_Check12:
	and (0x289d:16), 251
	cp (0x2873:16), 12
	jr nz, SetWall_B0CC_ClearFlags
	push xde
	ld xde, (4349:16)
	ldb_sri A, 0x07, 0xe8, 0xf4
	pop xde
	cp a, 3:i3
	jrl nz, SetWall_B0CC_ClearFlags
	jrl SetWall_B0CC_BankSelect

SetWall_B0CC_Return:
	ret

SetWall_EventOutput:
	push xde
	push xiz
	ld hl, (0x287d:16)
	dec 1, hl
	ld wa, ix
	ld xde, 0xf218
	stb_dri A, 0x07, 0xe8, 0xec
	sla hl, 1
	ld wa, (0x289f:16)
	ld xde, 0xf1f8
	stw_dri WA, 0x07, 0xe8, 0xec
	xor xwa, xwa
	ld xiz, 0xab000
	ld a, (0x00ffe3:24)
	sla xwa, 11
	add xiz, xwa
	ld xde, 0x98
	add xde, xiz
	ld wa, ix
	stb_dri A, 0x07, 0xe8, 0xec
	sla hl, 1
	ld xde, 0x78
	add xde, xiz
	ld wa, (0x289f:16)
	stw_dri WA, 0x07, 0xe8, 0xec
	pop xiz
	pop xde
	ret

SetWall_EventAdvanceCheck:
	ld hl, wa
	call SetWall_StreamIndexResolve
	ld xhl, (4349:16)
	ld wa, (xhl + 3)
	ld (0x28af:16), wa
	cp wa, 0xffff
	jr z, SetWall_EventAdvance_Return
	cp wa, (0x28a2:16)
	jr ule, SetWall_EventAdvance_Sync
	ld (0x287a:16), 10
	jr SetWall_EventAdvance_Return

SetWall_EventAdvance_Sync:
	ld iy, wa
	ld wa, (0x28a2:16)
	call DispatchHandler_JumpSub

SetWall_EventAdvance_Return:
	ret

SetWall_SlotResolve:
	ld (0x287a:16), 0
	ld (0x288d:16), w
	call SetWall_SingleSlotResolve
	cp (0x287a:16), 0
	jr z, SetWall_SlotResolve_Init
	jr SetWall_SlotResolve_Return

SetWall_SlotResolve_Init:
	ld iy, 5:i3
	push xiz
	ld xiz, (4349:16)
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
	ld (4349:16), xiz
	pop xiz
	xor de, de
	inc 1, de
	xor xix, xix

SetWall_SlotResolve_CheckDone:
	cp de, (0x287f:16)
	jr nz, SetWall_SlotResolve_ScanNext
	ld a, (0x288e:16)
	jr SetWall_SlotResolve_Return

SetWall_SlotResolve_ScanNext:
	ld b, (0x288e:16)
	call SetWall_SkipEvents
	cp (0x287a:16), 0
	jr z, SetWall_SlotResolve_FoundMatch
	jr SetWall_SlotResolve_Return

SetWall_SlotResolve_FoundMatch:
	ld (3383:16), ix
	inc 1, de
	push xiz
	ld xiz, (4349:16)
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
	ld (4349:16), xiz
	pop xiz
	cp (0x287a:16), 0
	jr nz, SetWall_SlotResolve_Return
	jr SetWall_SlotResolve_CheckDone

SetWall_SlotResolve_Return:
	ret

SetWall_StreamIndexResolve:
	dec 1, hl
	extz xhl
	sla xhl, 8
	add xhl, (7514:16)
	ld (4349:16), xhl
	xor xhl, xhl
	ret

SetWall_BankInit:
	ld xhl, 0x110a
	push xde
	ld xde, (7514:16)
	ld (xhl), xde
	pop xde
	ld iy, 1:i3
	call SetWall_ResolveStreamPtr
	ldw (0xf22f:16), 1
	ld xiy, (4349:16)
	xor xhl, xhl
	ld de, 2:i3
	ld bc, (0x286d:16)
	ld (0xf231:16), bc
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
	ld c, 0x10:opc

SetWall_FullReset_ClearNotes:
	stw_dpi IY, 0xe1
	djnz8 c, SetWall_FullReset_ClearNotes
	ld xwa, 0x98
	add xwa, xde
	ld b, 0x5:opc
	ld c, 0x10:opc

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
	ldw (0xf19e:16), 0
	ldw (0x00ffec:24), 0x0000
	ld (0xf24b:16), 0
	ld xix, 0xcef
	xor wa, wa
	ld c, 0x10:opc

SetWall_FullReset_ClearGlobal1:
	stw_dpi WA, 0xf1
	djnz8 c, SetWall_FullReset_ClearGlobal1
	ld xix, 0xd0f
	ld c, 0x10:opc

SetWall_FullReset_ClearGlobal2:
	ld (xix), a
	djnz8 b, SetWall_FullReset_ClearGlobal2
	ld (0xf24b:16), 0
	call SetWall_SendPanelCtrl
	ldw (0x2875:16), 0
	ldw (0x00ffec:24), 0x0000
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
	ld (0x287a:16), 1
	jr SetWall_SingleSlot_Return

SetWall_SingleSlot_LoadPos:
	inc 1, iy
	push xde
	ld xde, 0xf250
	ldw_sri WA, 0x07, 0xe8, 0xf4
	pop xde
	cp wa, 0xffff
	jr nz, SetWall_SingleSlot_InvalidPos
	ld (0x287a:16), 2
	jr SetWall_SingleSlot_Return

SetWall_SingleSlot_InvalidPos:
	cp wa, (0x28a2:16)
	jr ule, SetWall_SingleSlot_CheckBounds
	ld (0x287a:16), 10
	jr SetWall_SingleSlot_Return

SetWall_SingleSlot_CheckBounds:
	ld (0x28af:16), wa
	ld hl, wa
	call SetWall_StreamIndexResolve
	ld xhl, (4349:16)
	bitm 7, (xhl)
	jr nz, SetWall_SingleSlot_Return
	ld (0x287a:16), 11

SetWall_SingleSlot_Return:
	ret

SetWall_DualPassScanner:
	push_sd16w 0xaf, 0x28
	and (0x287b:16), 223
	ld a, (1075:16)
	ld (0x288e:16), a
	bit 2, (0x287b:16)
	jrl z, SetWall_DualPass_Done
	ld a, (0x288d:16)
	call SetWall_SingleSlotResolve
	cp (0x287a:16), 0
	jr z, SetWall_DualPass_InitLoop
	and (0x287b:16), 251
	ld (0x287a:16), 0
	jrl SetWall_DualPass_Done

SetWall_DualPass_InitLoop:
	xor hl, hl
	push xwa
	ld xwa, (4349:16)
	ld (0x288f:16), xwa
	pop xwa
	ld iy, 5:i3

SetWall_DualPass_MainLoop:
	ld xhl, (4349:16)
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
	cp (0x287a:16), 0
	jr z, SetWall_DualPass_MainLoop
	jrl SetWall_DualPass_Error

SetWall_DualPass_TypeC0:
	ld a, w
	ld hl, wa
	rrc a
	and wa, 0x80
	ld (0x2893:16), wa
	and hl, 0x2
	rrc_i_8 l, 2
	ld (0x2895:16), hl
	call SetWall_StreamAdvanceBounded
	cp (0x287a:16), 0
	jrl nz, SetWall_DualPass_Error
	call SetWall_StreamAdvanceBounded
	cp (0x287a:16), 0
	jrl nz, SetWall_DualPass_Error
	call SetWall_StreamAdvanceBounded
	cp (0x287a:16), 0
	jr nz, SetWall_DualPass_Error
	call SetWall_StreamAdvanceBounded
	cp (0x287a:16), 0
	jrl nz, SetWall_DualPass_Error
	ld wa, (0x2893:16)
	ld xhl, (4349:16)
	ldb_sri W, 0x07, 0xec, 0xf4
	or a, w
	pushw wa
	call SetWall_StreamAdvanceBounded
	popw wa
	cp (0x287a:16), 0
	jr nz, SetWall_DualPass_Error
	ld xhl, (4349:16)
	ldb_sri D, 0x07, 0xec, 0xf4
	ld hl, (0x2895:16)
	or d, l
	push xiz
	ld xiz, (4349:16)
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
	ld (4349:16), xiz
	pop xiz
	ld (0x288e:16), a
	call SetWall_StreamAdvanceBounded
	cp (0x287a:16), 0
	jr nz, SetWall_DualPass_Error
	jrl SetWall_DualPass_MainLoop

SetWall_DualPass_Type81:
	call SetWall_ForwardSkip
	jr SetWall_DualPass_Done

SetWall_DualPass_Error:
	ld (0x287a:16), 0
	ld a, (1075:16)
	ld (0x288e:16), a
	or (0x287b:16), 32

SetWall_DualPass_Done:
	popw_dd16 0xaf, 0x28
	ret

SetWall_SkipEvents:
	xor c, c

SetWall_SkipEvents_CheckCount:
	cp c, b
	jr z, SetWall_SkipEvents_Return

SetWall_SkipEvents_ReadLoop:
	ld xhl, (4349:16)
	ldb_sri A, 0x07, 0xec, 0xf4
	cp a, 0x84
	jr z, SetWall_SkipEvents_EndMarker
	cp a, 0x82
	jr nz, SetWall_SkipEvents_CheckEnd

SetWall_SkipEvents_EndMarker:
	ld (0x287a:16), 8
	jr SetWall_SkipEvents_Return

SetWall_SkipEvents_CheckEnd:
	cp a, 0x81
	jr z, SetWall_SkipEvents_IncCount
	call SetWall_StreamAdvanceBounded
	cp (0x287a:16), 0
	jr z, SetWall_SkipEvents_ReadLoop
	jr SetWall_SkipEvents_Return

SetWall_SkipEvents_IncCount:
	inc 1, c
	call SetWall_StreamAdvanceBounded
	cp (0x287a:16), 0
	jr z, SetWall_SkipEvents_CheckCount
	jr SetWall_SkipEvents_Return

SetWall_SkipEvents_Return:
	xor b, b
	add ix, bc
	ret

SetWall_ReplayScanner:
	push_sd16w 0xaf, 0x28
	bit 2, (0x287b:16)
	jrl z, SetWall_Replay_Done
	bit 5, (0x287b:16)
	jrl nz, SetWall_Replay_Done
	xor hl, hl
	ld xhl, (0x2897:16)
	ld (4349:16), xhl
	ld iy, (0x289b:16)

SetWall_Replay_MainLoop:
	ldb_sri A, 0x07, 0xec, 0xf4
	ld w, a
	and a, 0xf0
	cp a, 0xc0
	jr z, SetWall_Replay_TypeC0
	cp w, 0x82
	jr nz, SetWall_Replay_Type84
	or (0x287b:16), 32
	jrl SetWall_Replay_Done

SetWall_Replay_Type84:
	cp w, 0x84
	jr nz, SetWall_Replay_CheckType81
	ld iy, 5:i3
	ld xhl, (0x288f:16)
	jr SetWall_Replay_MainLoop

SetWall_Replay_CheckType81:
	cp w, 0x81
	jrl z, SetWall_Replay_Type81
	call SetWall_StreamAdvanceBounded
	cp (0x287a:16), 0
	jr z, SetWall_Replay_MainLoop
	ld (0x287a:16), 0
	jrl SetWall_Replay_Done

SetWall_Replay_TypeC0:
	ld l, w
	xor l, l
	ld a, w
	rrc a
	and wa, 0x80
	ld (0x2893:16), wa
	call SetWall_StreamAdvanceBounded
	cp (0x287a:16), 0
	jr z, SetWall_Replay_C0_Byte2
	ld (0x287a:16), 0
	jrl SetWall_Replay_Done

SetWall_Replay_C0_Byte2:
	call SetWall_StreamAdvanceBounded
	cp (0x287a:16), 0
	jr z, SetWall_Replay_C0_Byte3
	ld (0x287a:16), 0
	jrl SetWall_Replay_Done

SetWall_Replay_C0_Byte3:
	call SetWall_StreamAdvanceBounded
	cp (0x287a:16), 0
	jr z, SetWall_Replay_C0_Byte4
	ld (0x287a:16), 0
	jrl SetWall_Replay_Done

SetWall_Replay_C0_Byte4:
	call SetWall_StreamAdvanceBounded
	cp (0x287a:16), 0
	jr z, SetWall_Replay_C0_ReadBank
	ld (0x287a:16), 0
	jr SetWall_Replay_Done

SetWall_Replay_C0_ReadBank:
	ld wa, (0x2893:16)
	ld xhl, (4349:16)
	ldb_sri W, 0x07, 0xec, 0xf4
	or a, w
	pushw wa
	call SetWall_StreamAdvanceBounded
	popw wa
	cp (0x287a:16), 0
	jr z, SetWall_Replay_C0_ReadCC
	ld (0x287a:16), 0
	jr SetWall_Replay_Done

SetWall_Replay_C0_ReadCC:
	ld xhl, (4349:16)
	ldb_sri D, 0x07, 0xec, 0xf4
	push xiz
	ld xiz, (4349:16)
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
	ld (4349:16), xiz
	pop xiz
	ld (0x288e:16), a
	call SetWall_StreamAdvanceBounded
	cp (0x287a:16), 0
	jrl z, SetWall_Replay_MainLoop
	ld (0x287a:16), 0
	jr SetWall_Replay_Done

SetWall_Replay_Type81:
	call SetWall_ForwardSkip

SetWall_Replay_Done:
	popw_dd16 0xaf, 0x28
	ld (0x287a:16), 0
	ret

SetWall_SendPanelCtrl:
	and (0xfdad:16), 254
	xor a, a
	ld w, 0x1:opc
	ld e, 0x91:opc
	ld d, 0x3:opc
	call SwbtWr_QueuePostEvent
	ret

SetWall_ResolveStreamPtr:
	ld hl, iy
	extz xhl
	dec 1, hl
	sla xhl, 8
	add xhl, (4362:16)
	ld (4349:16), xhl
	xor xhl, xhl
	ret

SetWall_StreamAdvanceBounded:
	inc 1, iy
	cp iy, 0xff
	jr le, SetWall_StreamAdv_Return
	ld xhl, (4349:16)
	ld wa, (xhl + 3)
	cp wa, 0xffff
	jr ule, SetWall_StreamAdv_CheckBounds
	ld (0x287a:16), 8
	jr SetWall_StreamAdv_Return

SetWall_StreamAdv_CheckBounds:
	cp wa, (0x28a2:16)
	jr ule, SetWall_StreamAdv_LoadNext
	ld (0x287a:16), 10
	jr SetWall_StreamAdv_Return

SetWall_StreamAdv_LoadNext:
	ld (0x28af:16), wa
	ld hl, wa
	call SetWall_StreamIndexResolve
	ld xhl, (4349:16)
	bitm 7, (xhl)
	jr nz, SetWall_StreamAdv_Reset
	ld (0x287a:16), 11
	jr SetWall_StreamAdv_Return

SetWall_StreamAdv_Reset:
	ld iy, 5:i3

SetWall_StreamAdv_Return:
	ret

SetWall_ForwardSkip:
	xor bc, bc

SetWall_ForwardSkip_Loop:
	cp (0x288e:16), c
	jr z, SetWall_ForwardSkip_TargetFound
	ld xhl, (4349:16)
	cpib_sri 0x07, 0xec, 0xf4, 0x82
	jr nz, SetWall_ForwardSkip_CheckType
	or (0x287b:16), 32
	jr SetWall_ForwardSkip_Return

SetWall_ForwardSkip_CheckType:
	cpib_sri 0x07, 0xec, 0xf4, 0x81
	jr z, SetWall_ForwardSkip_Type81
	cpib_sri 0x07, 0xec, 0xf4, 0x84
	jr z, SetWall_ForwardSkip_Type84
	call SetWall_StreamAdvanceBounded
	cp (0x287a:16), 0
	jr nz, SetWall_ForwardSkip_Error
	jr SetWall_ForwardSkip_Loop

SetWall_ForwardSkip_Type84:
	ld iy, 5:i3
	ld xhl, (0x288f:16)
	ld (4349:16), xhl
	jr SetWall_ForwardSkip_Loop

SetWall_ForwardSkip_Type81:
	inc 1, c
	call SetWall_StreamAdvanceBounded
	cp (0x287a:16), 0
	jr nz, SetWall_ForwardSkip_Error
	jr SetWall_ForwardSkip_Loop

SetWall_ForwardSkip_TargetFound:
	ld xhl, (4349:16)
	cpib_sri 0x07, 0xec, 0xf4, 0x82
	jr nz, SetWall_ForwardSkip_Check84
	or (0x287b:16), 32
	jr SetWall_ForwardSkip_Return

SetWall_ForwardSkip_Check84:
	cpib_sri 0x07, 0xec, 0xf4, 0x84
	jr nz, SetWall_ForwardSkip_SaveState
	ld iy, 5:i3
	ld xhl, (0x288f:16)

SetWall_ForwardSkip_SaveState:
	ld (0x289b:16), iy
	push xwa
	ld xwa, (4349:16)
	ld (0x2897:16), xwa
	pop xwa
	jr SetWall_ForwardSkip_Return

SetWall_ForwardSkip_Error:
	or (0x287b:16), 32
	ld (0x287a:16), 0

SetWall_ForwardSkip_Return:
	ret

SetWall_InlineCodeBlock3:
	ret
	call	AccWrap_PlayModeDispatch
	ordi8 (10407), 4
	ld	wa, (0xffec:24)
	ld	(0xf19e:16), wa
	push	xix
	pushw	bc
	ld	xix, 4421
	ld	bc, 0:i3
SetWall_ForwardSkip_Loop2:
	ld	(0x286b:16), c
	push	xix
	call	SetWall_MiscDataAndCode_0x52
	pop	xix
	xor	bc, bc
	ld	c, (0x286b:16)
	ld	a, (0x286c:16)
	st_rrb a, xix, bc
	inc 1, bc
	cp bc, 10
	jr lt, SetWall_ForwardSkip_Loop2
	popw	bc
	pop	xix
	ret
	anddi8 (10407), 251
	xor	wa, wa
	ld	a, 76:opc
	call	CtrlPanel_SetIndicatorBit
	ret
	ret

SetWall_LoadToneGenData:
	ld a, (7500:16)
	pushw wa
	call SetWall_LoadBankToToneGen
	popw wa
	ld a, (7502:16)
	ld (0x00ffe3:24), a
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
	ldir85
	xor	xwa, xwa
	ld	a, (0xffe3:24)
	sla	xwa, 11
	ld	xix, 0x0ab000
	add	xix, xwa
	ld	xwa, 256
	add	xix, xwa
	ld	xiy, 4441
	ldw	bc, 16
	ldir85
	cpdi8 (36150), 143
	jr	z, SetWall_MiscDataAndCode_Skip
	cpdi8 (36150), 167
	jr	z, SetWall_MiscDataAndCode_Skip2
SetWall_MiscDataAndCode_Skip:
	ld	a, 142:opc
	call	UI_PostModeChangeEvent
	jp	SetWall_MiscDataAndCode_0x51
SetWall_MiscDataAndCode_Skip2:
	ld	a, 131:opc
	call	UI_PostModeChangeEvent
	ret
	ld	xwa, (4349:16)
	push	xwa
	xor	xwa, xwa
	ld	a, (0x286b:16)
	cp a, (65507:24)
	jr nz, SetWall_MiscDataAndCode_Skip3
	ld xix, 62032
	jr	SetWall_MiscDataAndCode_Join
SetWall_MiscDataAndCode_Skip3:
	ld	xix, 0x0ab000
	sla	xwa, 11
	add	xix, xwa
	add	xix, 208
SetWall_MiscDataAndCode_Join:
	xor	xbc, xbc
	xor	de, de
SetWall_MiscDataAndCode_Loop:
	ld_rrb a, xix, de
	bit 7, a
	jr z, 13
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
	jr	c, SetWall_MiscDataAndCode_Loop
	ld	xde, xbc
	cp	xbc, 0
	jr	z, SetWall_MiscDataAndCode_Entry
	ld	xde, xbc
	mul	bc, 100
	ld	hl, (0x286d:16)
	div	xbc, xhl
	inc	1, bc
	cp	bc, 100
	jr	c, SetWall_MiscDataAndCode_Entry
	ldw	bc, 99
SetWall_MiscDataAndCode_Entry:
	stb_d8 (10348), c
	pop xwa
	ld	(4349:16), xwa
	ret
	.byte 0xe7
	ldw	ix, 0xdaa8
	incm8	1, (xwa-40)
	ld_rrw hl, xix, wa
	cp hl, 65535
	jr	z, 55
	push	xhl
	push_lerp 52
	call 15860228
	pop_lerp 52
	ldda32 xhl, (4349)
	bitm 7, (xhl)
	pop xhl
	jr	z, 35
	.byte 0xe7
	ldw	ix, 0xe761
	ldw	ix, 7428
	max
	push	sr
	call_24 lt, (341223)
	swi	5
	rcf
	ld	c, 179:opc
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
	ld	xiy, (7514:16)
	extz	xhl
	dec	1, xhl
	sla	xhl, 8
	add	xiy, xhl
	ld	(4349:16), xiy
	xor	xhl, xhl
	pop	xiy
	ret

SetWall_SyncToneGenToDRAM:
	ld wa, (0xf22f:16)
	ld (0x286f:16), wa
	ld wa, (0xf231:16)
	ld (0x2871:16), wa
	xor xwa, xwa
	ld a, (0x00ffe3:24)
	sla xwa, 11
	ld xiy, 0xab000
	add xiy, xwa
	ld xix, 0xf180
	ldw bc, 0x800
	ldir85
	ld wa, (0x286f:16)
	ld (0xf22f:16), wa
	ld wa, (0x2871:16)
	ld (0xf231:16), wa
	ld wa, (0xf19e:16)
	ld (0x00ffec:24), wa
	and (0x28a5:16), 254
	cp wa, 0:i3
	jr z, SetWall_Sync_CheckPanelBit
	or (0x28a5:16), 1

SetWall_Sync_CheckPanelBit:
	call SeqTimer_PostTempoUpdate
	cp (0xf23d:16), 255
	jr z, SetWall_Sync_PanelOff
	bit 2, (0xfdad:16)
	jr z, SetWall_Sync_FinalUpdate
	and (0xfdad:16), 251
	xor a, a
	jr SetWall_Sync_PostEvent

SetWall_Sync_PanelOff:
	bit 2, (0xfdad:16)
	jr nz, SetWall_Sync_FinalUpdate
	or (0xfdad:16), 4
	ld a, 0x4:opc

SetWall_Sync_PostEvent:
	ld (4330:16), 1
	ld e, 0x91:opc
	ld d, 0x3:opc
	ld w, 0x4:opc
	call SwbtWr_QueueMainEvent
	call SwbtWr_ReinitBothBanks

SetWall_Sync_FinalUpdate:
	ld (4596:16), 1
	call BitMapOut_RenderDisplay
	ld (4596:16), 1
	and (0x28a7:16), 247
	call SeqPlay_CheckStartConditions
	and (0x28b1:16), 254
	call Audio_CheckSubsystemReady
	ret

SetWall_LoadBankToToneGen:
	ld wa, (0x00ffec:24)
	ld (0xf19e:16), wa
	ld xix, 0xab000
	xor xhl, xhl
	ld l, (0x00ffe3:24)
	sla xhl, 11
	add xix, xhl
	ld xiy, 0xf180
	ldw bc, 0x800
	ldir85
	ret

