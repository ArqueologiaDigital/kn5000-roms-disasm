; =============================================================================
; Feature Demo Text Processing
; =============================================================================
;
; Text data processing for Feature Demo mode: voice probing,
; flag processing, and formatted output for demo displays.
; =============================================================================

FDemoText:
	cp xbc, EVT_GET_LANGUAGE_PTR
	jr nz, FDemoText_ReturnNull
	lda xhl, (DemoDisk_LangPromptTable:24)
	ret

FDemoText_ReturnNull:
	ld xhl, 0:i3
	ret

FDemoText_LookupTableEntry:
	extz wa
	sla wa, 2
	ld xbc, (0x90f2:16)
	exts xwa
	add xwa, xbc
	ld xhl, (xwa)
	ret

FDemoText_ByteData_VoiceProbeA:
	ld	c, (SWBTWR_PAYLOAD_1:16)
	ld	a, (SWBTWR_EVENT_TYPE:16)
	extz	wa
	cp	c, 5:i3
	jr	z, FDemoText_ByteData_VoiceProbeA_Skip2
	cp	c, 1:i3
	jr	z, FDemoText_ByteData_VoiceProbeA_Skip
	cp	c, 0:i3
	ret	nz
FDemoText_ByteData_VoiceProbeA_Skip:
	lda	xbc, (FDemoText_PartFlagBit:24)
	ld	a, (xbc+wa)
	or (149486:24), a
	ret
FDemoText_ByteData_VoiceProbeA_Skip2:
	calr FDemoText_LookupTableEntry
	inc	5, xhl
	cp	(xhl), 0
	ret	nz
	ld	a, (SWBTWR_EVENT_TYPE:16)
	extz	wa
	lda	xbc, (FDemoText_PartFlagBit:24)
	ld	a, (xbc+wa)
	or (149490:24), a
	ret
FDemoText_ByteData_VoiceProbeB:
	cp	(SWBTWR_PAYLOAD_1:16), 1
	ret	nz
	ld	a, (SWBTWR_PAYLOAD_3:16)
	res	7, a
	cp	a, 0:i3
	ret	z
	set	6, (0x247ee:24)
	ret
FDemoText_ByteData_VoiceProbeC:
	ld	e, (SWBTWR_EVENT_TYPE:16)
	sub	e, 68
	ld	a, (SWBTWR_PAYLOAD_1:16)
	extz	wa
	dec	1, wa
	cp	wa, 0:i3
	ret	lt
	cp	wa, 6:i3
	ret	gt
	add	wa, wa
	lda	xix, (FDemoText_ByteData_VoiceProbeC_CaseTable:24)
	ld	wa, (xix+wa)
	lda	xix, (FDemoText_ByteData_VoiceProbeC_Code:24)
	jp	t, (xix+wa)
FDemoText_ByteData_VoiceProbeC_Code:
	set	6, (0x247ec:24)
	ret
FDemoText_ByteData_VoiceProbeC_Case3:	; cases 3, 4, 5, 6
	ld	xwa, FDemoText_FullSendBitByPart
	jr	FDemoText_ByteData_VoiceProbeC_Join
FDemoText_ByteData_VoiceProbeC_Case7:
	ld	a, (SWBTWR_PAYLOAD_3:16)
	and	a, 15
	jr	z, FDemoText_ByteData_VoiceProbeC_Skip
	ld	a, e
	extz	wa
	lda	xbc, (FDemoText_FullSendBitByPart:24)
	ld	a, (xbc+wa)
	or (149484:24), a
FDemoText_ByteData_VoiceProbeC_Skip:
	ld a, (SWBTWR_PAYLOAD_3:16)
	and a, 48
	ret z
	ld	xwa, FDemoText_PartialResendBit
FDemoText_ByteData_VoiceProbeC_Join:
	extz	de
	ld	a, (xwa+de)
	or (149484:24), a
	ret

FDemoText_ProcessVoiceFlags:
	pushw_erp 0xfa
	ld a, (0x8d46:16)
	bit 6, a
	jr z, FDemoText_ProcessVoiceFlags_ReadState
	set 6, (0x0247ee:24)
	ld a, (0x8d46:16)
	res 6, a
	ld (0x8d46:16), a

FDemoText_ProcessVoiceFlags_ReadState:
	call Boot_CheckConfigFlag7
	cp hl, 0:i3
	jrl z, FDemoText_ProcessOutput_ClearAll
	ld a, (0x0247ee:24)
	bit 6, a
	jr z, FDemoText_ProcessVoiceFlags_CheckBits
	set 7, a
	res 6, a
	ld (0x0247ee:24), a
	pushw 0x0
	ldw wa, 0x44
	ldw bc, 0x8
	ld de, 0:i3
	call AddswbWr
	jrl FDemoText_ProcessVoiceFlags_Return

FDemoText_ProcessVoiceFlags_CheckBits:
	and a, 0x7
	call nz, (FDemoText_ScanMIDIChannels:24)
	bit 7, (0x0247ee:24)
	jr z, FDemoText_ProcessChannels
	ld (0x0247f2:24), 0x00
	ldib_erp 0xfb, 0

FDemoText_ProbeVoice_Loop:
	ldto_berp A, 0xfb
	extz wa
	lda xbc, (FDemoText_VoiceActiveBit:24)
	ld	c, (xbc+wa)
	ldfr_berp C, 0xfa
	calr FDemoText_CheckVoiceState
	cp l, 1:i3
	jr z, FDemoText_ProbeVoice_SetActive
	ldto_berp A, 0xfa
	cpl a
	and (0x0247ee:24), a
	jr FDemoText_ProbeVoice_ClearActive

FDemoText_ProbeVoice_SetActive:
	ldto_berp A, 0xfa
	or (0x0247ee:24), a

FDemoText_ProbeVoice_ClearActive:
	inc1b_erp 0xfb
	cpib_erp 0xfb, 2
	jr ule, FDemoText_ProbeVoice_Loop

FDemoText_ProcessChannels:
	ldib_erp 0xfb, 0

FDemoText_ProcessChannels_Loop:
	ldto_berp A, 0xfb
	extz wa
	lda xbc, (FDemoText_PartFlagBit:24)
	ld	c, (xbc+wa)
	ld e, (0x0247ee:24)
	and c, e
	jr z, FDemoText_ProcessChannel_CheckMask
	lda xbc, (FDemoText_VoiceActiveBit:24)
	ld	c, (xbc+wa)
	and c, e
	jr z, FDemoText_ProcessChannel_CheckNoFlag
	calr FDemoText_CheckVoiceState
	cp l, 1:i3
	jr nz, FDemoText_ProcessChannel_Activate
	ldto_berp A, 0xfb
	extz wa
	calr FDemoText_ActivateVoice
	jr FDemoText_ProcessChannel_CheckMask

FDemoText_ProcessChannel_Activate:
	ldto_berp A, 0xfb
	extz wa
	calr FDemoText_DeactivateVoice
	jr FDemoText_ProcessChannel_CheckMask

FDemoText_ProcessChannel_CheckNoFlag:
	calr FDemoText_CheckVoiceState
	ldto_berp A, 0xfb
	extz wa
	cp l, 1:i3
	jr nz, FDemoText_ProcessChannel_Deactivate
	calr FDemoText_ActivateVoiceAlt
	jr FDemoText_ProcessChannel_CheckMask

FDemoText_ProcessChannel_Deactivate:
	calr FDemoText_DeactivateVoice_RetOnly

FDemoText_ProcessChannel_CheckMask:
	ldto_berp A, 0xfb
	extz wa
	lda xbc, (FDemoText_PartFlagBit:24)
	ld	c, (xbc+wa)
	and c, (0x0247f2:24)
	call nz, (FDemoText_CheckAndSetTimer:24)
	inc1b_erp 0xfb
	cpib_erp 0xfb, 2
	jr ule, FDemoText_ProcessChannels_Loop
	ldib_erp 0xfb, 0

FDemoText_ProcessOutputChannels:
	lda xhl, (FDemoText_PartialResendBit:24)
	ld c, (0x0247ec:24)
	bit 6, c
	jr z, FDemoText_ProcessOutput_CheckFlags
	ldto_berp E, 0xfb
	extz de
	lda xwa, (FDemoText_VoiceActiveBit:24)
	ld	a, (xwa+de)
	and a, (0x0247ee:24)
	jr z, FDemoText_ProcessOutput_CheckFlags
	or	c, (xhl+de)
	ld (0x0247ec:24), c

FDemoText_ProcessOutput_CheckFlags:
	ldto_berp A, 0xfb
	extz wa
	lda xbc, (FDemoText_VoiceActiveBit:24)
	ld	c, (xbc+wa)
	and c, (0x0247ee:24)
	jr z, FDemoText_ProcessOutput_NextCh
	lda xbc, (FDemoText_FullSendBitByPart:24)
	ld	c, (xbc+wa)
	ld e, (0x0247ec:24)
	and c, e
	jr z, FDemoText_ProcessOutput_AltUpdate
	calr FDemoText_SendVoiceParams
	jr FDemoText_ProcessOutput_NextCh

FDemoText_ProcessOutput_AltUpdate:
	ld	c, (xhl+wa)
	and c, e
	call nz, (FDemoText_UpdatePartialVoice:24)

FDemoText_ProcessOutput_NextCh:
	inc1b_erp 0xfb
	cpib_erp 0xfb, 2
	jr ule, FDemoText_ProcessOutputChannels

FDemoText_ProcessOutput_ClearAll:
	ld (0x0247ec:24), 0x00
	ld (0x0247f2:24), 0x00
	and (0x0247ee:24), 120

FDemoText_ProcessVoiceFlags_Return:
	popw_erp 0xfa
	ret

FDemoText_ActivateVoice:
	dec 2, xsp
	ld (xsp), a
	ld a, (xsp)
	extz wa
	calr FDemoText_SendVoiceParams
	bit 7, (0x0247ee:24)
	jr nz, FDemoText_ActivateVoice_Done
	ld a, (xsp)
	extz wa
	calr FDemoText_SyncVoicePreset

FDemoText_ActivateVoice_Done:
	inc 2, xsp
	ret

FDemoText_DeactivateVoice:
	extz wa
	lda xbc, (FDemoText_VoiceActiveBit:24)
	ld	c, (xbc+wa)
	cpl c
	and (0x0247ee:24), c
	jr FDemoText_UpdateVoiceDisplay

FDemoText_ActivateVoiceAlt:
	dec 2, xsp
	ld (xsp), a
	ld a, (xsp)
	extz wa
	calr FDemoText_SendVoiceParams
	ld a, (xsp)
	extz wa
	calr FDemoText_SyncVoicePreset
	ld a, (xsp)
	extz wa
	lda xbc, (FDemoText_VoiceActiveBit:24)
	ld	a, (xbc+wa)
	or (0x0247ee:24), a
	inc 2, xsp
	ret

FDemoText_DeactivateVoice_RetOnly:
	ret

FDemoText_UpdateVoiceDisplay:
	dec 2, xsp
	push xiz
	ld (xsp + 4), a
	ld a, (xsp + 4)
	extz wa
	calr FDemoText_LookupTableEntry
	ld xiz, xhl
	inc 5, xiz
	cp (xiz), 0x0
	jr z, FDemoText_UpdateVoiceDisplay_CheckSend
	ld (xiz), 0x0
	ld a, (xsp + 4)
	extz wa
	pushw 0x7f
	ld bc, 5:i3
	ld de, 0:i3
	call AddswbWr
	lda xwa, (xiz + 2)
	cp (xwa), 0x0
	jr nz, FDemoText_UpdateVoiceDisplay_CheckSend
	ld (xwa), 0x5a
	ld a, (xsp + 4)
	extz wa
	pushw 0x7f
	ld bc, 7:i3
	ldw de, 0x5a
	call AddswbWr

FDemoText_UpdateVoiceDisplay_CheckSend:
	ld a, (0x0247ee:24)
	and a, 0x38
	jr nz, FDemoText_UpdateVoiceDisplay_Done
	ld c, (0xfc26:16)
	cp (0xfc74:16), c
	jr z, FDemoText_UpdateVoiceDisplay_Done
	extz bc
	ldw wa, 0x61
	calr FDemoText_NotifyUIChange

FDemoText_UpdateVoiceDisplay_Done:
	pop xiz
	inc 2, xsp
	ret

FDemoText_SyncVoicePreset:
	dec 6, xsp
	pushw_erp 0xfa
	ld (xsp + 6), a
	lda xwa, (0xfc74:16)
	ld (xsp + 2), xwa
	ld a, (0x0247ee:24)
	and a, 0x38
	jr z, FDemoText_SyncPreset_DirectCopy
	ldib_erp 0xfb, 0

FDemoText_SyncPreset_ActiveLoop:
	ldto_berp A, 0xfb
	extz wa
	calr FDemoText_CheckVoiceState
	ldto_berp A, 0xfb
	extz wa
	cp l, 1:i3
	jr nz, FDemoText_SyncPreset_CallUpdate
	ld bc, wa
	lda xde, (FDemoText_PartFlagBit:24)
	ld	a, (xde+wa)
	and a, (0x0247ee:24)
	jr z, FDemoText_SyncPreset_NextActive
	ld wa, bc

FDemoText_SyncPreset_CallUpdate:
	calr FDemoText_UpdateChannelVoice

FDemoText_SyncPreset_NextActive:
	inc1b_erp 0xfb
	cpib_erp 0xfb, 2
	jr ule, FDemoText_SyncPreset_ActiveLoop
	jr FDemoText_SyncPreset_Compare

FDemoText_SyncPreset_DirectCopy:
	ld xwa, (xsp + 2)
	ld a, (xwa)
	ld (0xfc26:16), a
	ldib_erp 0xfb, 0

FDemoText_SyncPreset_DirectLoop:
	ldto_berp A, 0xfb
	extz wa
	calr FDemoText_UpdateChannelVoice
	inc1b_erp 0xfb
	cpib_erp 0xfb, 2
	jr ule, FDemoText_SyncPreset_DirectLoop

FDemoText_SyncPreset_Compare:
	ld a, (xsp + 6)
	extz wa
	lda xbc, (0x0247f4:24)
	ld	c, (xbc+wa)
	ld xwa, (xsp + 2)
	cp c, (xwa)
	jr z, FDemoText_SyncPreset_Return
	extz bc
	ldw wa, 0x61
	calr FDemoText_NotifyUIChange

FDemoText_SyncPreset_Return:
	popw_erp 0xfa
	inc 6, xsp
	ret

FDemoText_UpdateChannelVoice:
	dec 2, xsp
	push xiz
	ld (xsp + 4), a
	ld a, (xsp + 4)
	extz wa
	calr FDemoText_LookupTableEntry
	ld xiz, xhl
	inc 5, xiz
	ld a, (xsp + 4)
	extz wa
	calr FDemoText_CheckVoiceState
	ld a, (xsp + 4)
	extz wa
	cp l, 1:i3
	jr z, FDemoText_UpdateChannel_Active
	ld (xiz), 0x0
	pushw 0x7f
	ld bc, 5:i3
	ld de, 0:i3
	jr FDemoText_UpdateChannel_SendCmd

FDemoText_UpdateChannel_Active:
	cp (xiz), 0x0
	jr nz, FDemoText_UpdateChannel_Done
	ld (xiz), 0x50
	pushw 0x7f
	ld bc, 5:i3
	ldw de, 0x50
	call AddswbWr
	lda xwa, (xiz + 2)
	cp (xwa), 0x0
	jr z, FDemoText_UpdateChannel_Done
	ld (xwa), 0x0
	ld a, (xsp + 4)
	extz wa
	pushw 0x7f
	ld bc, 7:i3
	ld de, 0:i3

FDemoText_UpdateChannel_SendCmd:
	call AddswbWr

FDemoText_UpdateChannel_Done:
	pop xiz
	inc 2, xsp
	ret

FDemoText_CheckAndSetTimer:
	dec 2, xsp
	push xiz
	ld (xsp + 4), a
	ld a, (xsp + 4)
	extz wa
	calr FDemoText_LookupTableEntry
	ld xiz, xhl
	inc 5, xiz
	ld a, (xsp + 4)
	extz wa
	calr FDemoText_CheckVoiceState
	cp l, 1:i3
	jr nz, FDemoText_CheckTimer_Done
	cp (xiz), 0x0
	jr nz, FDemoText_CheckTimer_Done
	lda xwa, (xiz + 2)
	cp (xwa), 0x0
	jr nz, FDemoText_CheckTimer_Done
	ld (xwa), 0x5a
	ld a, (xsp + 4)
	extz wa
	pushw 0x7f
	ld bc, 7:i3
	ldw de, 0x5a
	call AddswbWr

FDemoText_CheckTimer_Done:
	pop xiz
	inc 2, xsp
	ret

FDemoText_ParseControlMessage:
	lda xbc, (0x020c33:24)
	ld a, (xbc + 1)
	cp a, (PART_SELECT:16)
	ret nz
	cp (ACTIVE_TITLE:16), 234
	ret nz
	ld a, (xbc)
	cp a, 0x83
	jr z, FDemoText_ParseCtrl_SecondHalf
	cp a, 0x82
	ret nz
	ld e, (xbc + 2)
	ld c, (xbc + 7)
	and c, 0xf
	extz bc
	cp e, 0x82
	jr z, FDemoText_ParseCtrl_Type82
	cp e, 2:i3
	jr nz, FDemoText_ParseCtrl_SecondHalf
	ld wa, 6:i3
	call DemoMenu_BuildItemWorkspace
	ld a, (0x020c39:24)
	srl a, 4
	and a, 0xf
	ld c, a
	extz bc
	ld wa, 2:i3
	call DemoMenu_BuildItemWorkspace
	ld c, (0x020c39:24)
	and c, 0xf
	extz bc
	ld wa, 0:i3
	jr FDemoText_ParseCtrl_BuildWorkspace

FDemoText_ParseCtrl_Type82:
	ldw wa, 0x8
	call DemoMenu_BuildItemWorkspace
	ld a, (0x020c39:24)
	srl a, 4
	and a, 0xf
	ld c, a
	extz bc
	ld wa, 5:i3
	call DemoMenu_BuildItemWorkspace
	ld c, (0x020c39:24)
	and c, 0xf
	extz bc
	ld wa, 3:i3

FDemoText_ParseCtrl_BuildWorkspace:
	call DemoMenu_BuildItemWorkspace

FDemoText_ParseCtrl_SecondHalf:
	lda xwa, (0x020c33:24)
	ld c, (xwa + 2)
	cp c, 0x82
	jr z, FDemoText_ParseCtrl_FormatC3
	cp c, 2:i3
	ret nz
	ld c, (xwa + 7)
	and c, 0xf
	extz bc
	ld wa, 7:i3
	call DemoMenu_BuildItemWorkspace
	ld a, (0x020c39:24)
	srl a, 4
	and a, 0xf
	ld c, a
	extz bc
	ld wa, 4:i3
	call DemoMenu_BuildItemWorkspace
	ld c, (0x020c39:24)
	and c, 0xf
	extz bc
	ld wa, 1:i3
	jr FDemoText_ParseCtrl_Finalize

FDemoText_ParseCtrl_FormatC3:
	ld c, (xwa + 6)
	and c, 0x1
	extz bc
	ldw wa, 0xa
	call DemoMenu_BuildItemWorkspace
	ld a, (0x020c39:24)
	srl a, 1
	and a, 0x1
	ld c, a
	extz bc
	ldw wa, 0x9

FDemoText_ParseCtrl_Finalize:
	call DemoMenu_BuildItemWorkspace
	ret

FDemoText_SendResetMessage:
	dec 6, xsp
	lda xde, (xsp)
	ld (xde), 0x82
	ld (xde + 1), a
	ld (xde + 2), 0x2
	ld (xde + 3), 0x2
	ld (xde + 4), 0x1
	ld (xde + 5), 0xea
	ld wa, 0:i3
	ld bc, 6:i3
	call sendCOMM
	lda xde, (xsp)
	ld (xde + 2), 0x82
	ld (xde + 3), 0x2
	ld wa, 0:i3
	ld bc, 6:i3
	call sendCOMM
	lda xde, (xsp)
	ld (xde), 0x83
	ld (xde + 2), 0x2
	ld (xde + 3), 0x2
	ld wa, 0:i3
	ld bc, 6:i3
	call sendCOMM
	lda xde, (xsp)
	ld (xde + 2), 0x82
	ld (xde + 3), 0x2
	ld wa, 0:i3
	ld bc, 6:i3
	call sendCOMM
	inc 6, xsp
	ret

FDemoText_SendVoiceParams:
	lda xsp, (xsp - 12)
	pushw_erp 0xfa
	ld (xsp + 12), a
	ld a, (xsp + 12)
	extz wa
	calr FDemoText_ProbeVoiceType
	cp l, 0xc
	jrl nz, FDemoText_SendVoiceParams_Return
	lda xde, (xsp + 6)
	ld (xde), 0xb0
	ld a, (xsp + 12)
	ld (xde + 1), a
	ld (xde + 2), 0x78
	ld (xde + 3), 0x0
	ld wa, 0:i3
	ld bc, 4:i3
	call sendCOMM
	lda xbc, (xsp + 6)
	ld (xbc), 0x88
	ld a, (xsp + 12)
	ld (xbc + 1), a
	ld (xbc + 3), 0x0
	ld (xbc + 5), 0x0
	ldw wa, 0x44
	calr FDemoText_LookupTableEntry
	ld (xsp + 2), xhl
	ld xwa, 1:i3
	add (xsp + 2), xwa
	ldi_erpb 0xfb, 0x0b

FDemoText_SendParams_NoteLoop:
	lda xde, (xsp + 6)
	ldto_berp A, 0xfb
	ld (xde + 2), a
	ld xwa, (xsp + 2)
	ld a, (xwa)
	ld (xde + 4), a
	ld wa, 0:i3
	ld bc, 6:i3
	call sendCOMM
	ld xwa, 1:i3
	add (xsp + 2), xwa
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x0c
	jr ule, FDemoText_SendParams_NoteLoop
	ld a, (xsp + 12)
	add a, 0x44
	extz wa
	calr FDemoText_LookupTableEntry
	ld (xsp + 2), xhl
	ld xwa, 3:i3
	add (xsp + 2), xwa
	ldib_erp 0xfb, 4

FDemoText_SendParams_LevelLoop:
	lda xde, (xsp + 6)
	ldto_berp A, 0xfb
	ld (xde + 2), a
	ld xwa, (xsp + 2)
	ld a, (xwa)
	ld (xde + 4), a
	ld wa, 0:i3
	ld bc, 6:i3
	call sendCOMM
	ld xwa, 1:i3
	add (xsp + 2), xwa
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x08
	jr ule, FDemoText_SendParams_LevelLoop
	ld c, (xsp + 12)
	extz bc
	ldw wa, 0xff
	call VoiceEvent_FlushAndReturn

FDemoText_SendVoiceParams_Return:
	popw_erp 0xfa
	lda xsp, (xsp + 12)
	ret

FDemoText_SendExtVoiceParams:
	lda xsp, (xsp - 22)
	pushw_erp 0xfa
	ld (xsp + 22), a
	lda xwa, (xsp + 6)
	ld (xsp + 2), xwa
	call DemoDesc_BuildCompactParams
	lda xde, (xsp + 16)
	ld (xde), 0xb0
	ld a, (xsp + 22)
	ld (xde + 1), a
	ld (xde + 2), 0x78
	ld (xde + 3), 0x0
	ld wa, 0:i3
	ld bc, 4:i3
	call sendCOMM
	lda xbc, (xsp + 16)
	ld (xbc), 0x88
	ld a, (xsp + 22)
	ld (xbc + 1), a
	ld (xbc + 3), 0x0
	ld (xbc + 5), 0x0
	ldi_erpb 0xfb, 0x0b

FDemoText_SendExtParams_NoteLoop:
	lda xde, (xsp + 16)
	ldto_berp A, 0xfb
	ld (xde + 2), a
	ld xwa, (xsp + 2)
	ld a, (xwa)
	ld (xde + 4), a
	ld wa, 0:i3
	ld bc, 6:i3
	call sendCOMM
	ld xwa, 1:i3
	add (xsp + 2), xwa
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x0c
	jr ule, FDemoText_SendExtParams_NoteLoop
	ldib_erp 0xfb, 4

FDemoText_SendExtParams_LevelLoop:
	lda xde, (xsp + 16)
	ldto_berp A, 0xfb
	ld (xde + 2), a
	ld xwa, (xsp + 2)
	ld a, (xwa)
	ld (xde + 4), a
	ld wa, 0:i3
	ld bc, 6:i3
	call sendCOMM
	ld xwa, 1:i3
	add (xsp + 2), xwa
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x08
	jr ule, FDemoText_SendExtParams_LevelLoop
	ld c, (xsp + 22)
	extz bc
	ldw wa, 0xff
	call VoiceEvent_FlushAndReturn
	popw_erp 0xfa
	lda xsp, (xsp + 22)
	ret

FDemoText_UpdatePartialVoice:
	lda xsp, (xsp - 10)
	push xiz
	ld (xsp + 12), a
	ld a, (xsp + 12)
	extz wa
	calr FDemoText_ProbeVoiceType
	cp l, 0xc
	jr nz, FDemoText_UpdatePartial_Done
	lda xbc, (xsp + 6)
	ld (xbc), 0x88
	ld a, (xsp + 12)
	ld (xbc + 1), a
	ld (xbc + 3), 0x0
	ld (xbc + 5), 0x0
	ldw wa, 0x44
	calr FDemoText_LookupTableEntry
	ld xiz, xhl
	inc 1, xiz
	ld (xsp + 4), 0xb

FDemoText_UpdatePartial_NoteLoop:
	lda xde, (xsp + 6)
	ld a, (xsp + 4)
	ld (xde + 2), a
	ld a, (xiz)
	ld (xde + 4), a
	ld wa, 0:i3
	ld bc, 6:i3
	call sendCOMM
	inc 1, xiz
	incm8 1, (xsp + 4)
	cp (xsp + 4), 0xc
	jr ule, FDemoText_UpdatePartial_NoteLoop
	ld a, (xsp + 12)
	add a, 0x44
	extz wa
	calr FDemoText_LookupTableEntry
	ld xiz, xhl
	inc 7, xiz
	lda xde, (xsp + 6)
	ld (xde + 2), 0x8
	ld a, (xiz)
	ld (xde + 4), a
	ld wa, 0:i3
	ld bc, 6:i3
	call sendCOMM

FDemoText_UpdatePartial_Done:
	pop xiz
	lda xsp, (xsp + 10)
	ret

FDemoText_SendExtParamsAlt:
	lda xsp, (xsp - 22)
	pushw_erp 0xfa
	ld (xsp + 22), a
	lda xwa, (xsp + 6)
	ld (xsp + 2), xwa
	call DemoDesc_BuildCompactParams
	lda xbc, (xsp + 16)
	ld (xbc), 0x88
	ld a, (xsp + 22)
	ld (xbc + 1), a
	ld (xbc + 3), 0x0
	ld (xbc + 5), 0x0
	ldi_erpb 0xfb, 0x0b

FDemoText_SendExtAlt_NoteLoop:
	lda xde, (xsp + 16)
	ldto_berp A, 0xfb
	ld (xde + 2), a
	ld xwa, (xsp + 2)
	ld a, (xwa)
	ld (xde + 4), a
	ld wa, 0:i3
	ld bc, 6:i3
	call sendCOMM
	ld xwa, 1:i3
	add (xsp + 2), xwa
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x0c
	jr ule, FDemoText_SendExtAlt_NoteLoop
	lda xde, (xsp + 16)
	ld (xde + 2), 0x8
	ld xwa, (xsp + 2)
	ld a, (xwa + 4)
	ld (xde + 4), a
	ld wa, 0:i3
	ld bc, 6:i3
	call sendCOMM
	popw_erp 0xfa
	lda xsp, (xsp + 22)
	ret

FDemoText_ProbeVoiceType:
	dec 8, xsp
	ld (xsp + 6), a
	ld a, (xsp + 6)
	extz wa
	calr FDemoText_LookupTableEntry
	lda xbc, (xsp)
	ld A, (xhl+)
	ld (xbc + 3), a
	ld a, (xhl)
	ld (xbc + 4), a
	ld a, (xsp + 6)
	ld (xbc + 2), a
	ld xwa, xbc
	call SndParam_FetchOscTableEntry
	ld l, (xsp + 0:8)
	inc 8, xsp
	ret

FDemoText_ByteData_ProbeHelper:
	dec	8, xsp
	ld	(xsp+6), a
	ld	a, (xsp+6)
	extz	wa
	calr	FDemoText_LookupTableEntry
	lda	xbc, (xsp)
	ld	a, (xhl+)
	ld	(xbc+0x3), a
	ld	a, (xhl)
	ld	(xbc+0x4), a
	ld	a, (xsp+0x6)
	ld	(xbc+0x2), a
	ld	xwa, xbc
	call	SndParam_FetchOscTableEntry
	ld	l, (xsp+1)
	inc	8, xsp
	ret

FDemoText_CheckVoiceState:
	dec 2, xsp
	ld (xsp), a
	ld a, (xsp)
	extz wa
	calr FDemoText_ProbeVoiceType
	cp l, 0x11
	jr z, FDemoText_CheckVoice_MaskedActive
	cp l, 0x10
	jr z, FDemoText_CheckVoice_MaskedActive
	cp l, 0xf
	jr z, FDemoText_CheckVoice_TypeF
	cp l, 0xc
	jr z, FDemoText_CheckVoice_Active

FDemoText_CheckVoice_Inactive:
	ld l, 0x0:opc

FDemoText_CheckVoice_Return:
	inc 2, xsp
	ret

FDemoText_CheckVoice_TypeF:
	ld l, 0x2:opc
	jr FDemoText_CheckVoice_Return

FDemoText_CheckVoice_MaskedActive:
	ld a, (xsp)
	extz wa
	lda xbc, (FDemoText_VoiceActiveBit:24)
	ld	a, (xbc+wa)
	and a, (0x0247f0:24)
	jr z, FDemoText_CheckVoice_Inactive

FDemoText_CheckVoice_Active:
	ld l, 0x1:opc
	jr FDemoText_CheckVoice_Return

FDemoText_ScanMIDIChannels:
	lda xsp, (xsp - 26)
	push xiz
	lda xde, (xsp + 24)
	ld (xde), 0x80
	ld (xde + 1), 0x0
	ld (xde + 2), 0x17
	ld (xde + 3), 0x2
	ld (xde + 4), 0x1
	ld (xde + 5), 0xea
	ld wa, 0:i3
	ld bc, 6:i3
	call sendCOMM
	lda xde, (xsp + 24)
	ld (xde + 1), 0x1
	ld wa, 0:i3
	ld bc, 6:i3
	call sendCOMM
	lda xde, (xsp + 24)
	ld (xde + 1), 0x2
	ld wa, 0:i3
	ld bc, 6:i3
	call sendCOMM
	ldw (xsp + 6), 0x0
	call SeqBuf_NoteEvent_CheckSongEnd
	cp hl, 0:i3
	jr nz, FDemoText_ScanMIDI_ReadResponse

FDemoText_ScanMIDI_WaitLoop:
	incw 1, (xsp + 6)
	cpw (xsp + 6), 0x2710
	jr ugt, FDemoText_ScanMIDI_ReadResponse
	call SeqBuf_NoteEvent_CheckSongEnd
	cp hl, 0:i3
	jr z, FDemoText_ScanMIDI_WaitLoop

FDemoText_ScanMIDI_ReadResponse:
	call SeqBuf_NoteEvent_CopyPointers
	ld (xsp + 4), 0x0

FDemoText_ScanMIDI_ProcessChannel:
	ldi_erpb 0xfb, 0xff
	cpw (xsp + 6), 0x2710
	jrl nc, FDemoText_ScanMIDI_UpdateFlags

FDemoText_ScanMIDI_AdvanceTimeout:
	incw 1, (xsp + 6)
	jrl FDemoText_ScanMIDI_ReadNextFrame

FDemoText_ScanMIDI_ReadBytes:
	ld iz, 1:i3
	ld (xsp + 8), l
	jr FDemoText_ScanMIDI_ByteLoop

FDemoText_ScanMIDI_StoreResponseByte:
	ld bc, iz
	extz xbc
	lda xwa, (xsp + 8)
	add xwa, xbc
	ld (xwa), l
	inc 1, iz

FDemoText_ScanMIDI_ByteLoop:
	cp iz, 6:i3
	jr nc, FDemoText_ScanMIDI_CheckStatus
	call Seq_RingBuf_ReadSmall
	cp hl, 0:i3
	jr ge, FDemoText_ScanMIDI_StoreResponseByte

FDemoText_ScanMIDI_CheckStatus:
	lda xwa, (xsp + 8)
	cp (xwa), 0x80
	jr nz, FDemoText_ScanMIDI_ExtendLoop
	ld (xwa + 3), 0x2
	jr FDemoText_ScanMIDI_ExtendLoop

FDemoText_ScanMIDI_ExtendResponse:
	ld bc, iz
	extz xbc
	lda xwa, (xsp + 8)
	add xwa, xbc
	ld (xwa), l
	cp iz, 0x10
	jr nc, FDemoText_ScanMIDI_ValidateResponse
	inc 1, iz

FDemoText_ScanMIDI_ExtendLoop:
	ld a, (xsp + 11)
	inc 6, a
	extz wa
	cp iz, wa
	jr nc, FDemoText_ScanMIDI_ValidateResponse
	call Seq_RingBuf_ReadSmall
	cp hl, 0:i3
	jr ge, FDemoText_ScanMIDI_ExtendResponse

FDemoText_ScanMIDI_ValidateResponse:
	lda xbc, (xsp + 8)
	ld a, (xbc + 3)
	inc 6, a
	extz wa
	cp wa, iz
	jr nz, FDemoText_ScanMIDI_NoMatch
	cp (xbc + 5), 0xea
	jr nz, FDemoText_ScanMIDI_NoMatch
	ld c, (xbc + 7)
	cp c, 0xf
	jr z, FDemoText_ScanMIDI_SetActive
	cp c, 0x35
	jr z, FDemoText_ScanMIDI_SetActive
	ldib_erp 0xfb, 0

FDemoText_ScanMIDI_LookupActive:
	ld a, (xsp + 4)
	extz wa
	lda xde, (0x0247f4:24)
	ld	(xde+wa), c

FDemoText_ScanMIDI_NoMatch:
	cp_erpb 0xfb, 0xff
	jr nz, FDemoText_ScanMIDI_CheckTimeout

FDemoText_ScanMIDI_ReadNextFrame:
	call Seq_RingBuf_ReadSmall
	cp hl, 0:i3
	jrl ge, FDemoText_ScanMIDI_ReadBytes

FDemoText_ScanMIDI_CheckTimeout:
	cp_erpb 0xfb, 0xff
	jr nz, FDemoText_ScanMIDI_UpdateFlags
	cpw (xsp + 6), 0x2710
	jrl c, FDemoText_ScanMIDI_AdvanceTimeout

FDemoText_ScanMIDI_UpdateFlags:
	ld a, (xsp + 4)
	extz wa
	lda xbc, (FDemoText_VoiceActiveBit:24)
	exts xwa
	add xwa, xbc
	cpib_erp 0xfb, 1
	jr nz, FDemoText_ScanMIDI_ClearActive
	ld a, (xwa)
	or (0x0247f0:24), a
	jr FDemoText_ScanMIDI_NextChannel

FDemoText_ScanMIDI_SetActive:
	ldib_erp 0xfb, 1
	jr FDemoText_ScanMIDI_LookupActive

FDemoText_ScanMIDI_ClearActive:
	ld a, (xwa)
	cpl a
	and (0x0247f0:24), a

FDemoText_ScanMIDI_NextChannel:
	incm8 1, (xsp + 4)
	cp (xsp + 4), 0x2
	jrl ule, FDemoText_ScanMIDI_ProcessChannel
	pop xiz
	lda xsp, (xsp + 26)
	ret

FDemoText_StubReturn_A:
	ret

FDemoText_StubReturn_B:
	ret

FDemoText_StubReturn_C:
	ret

FDemoText_RescanAllVoices:
	pushw_erp 0xfa
	calr FDemoText_ScanMIDIChannels
	ldib_erp 0xfb, 0

FDemoText_Rescan_Loop:
	ldto_berp A, 0xfb
	extz wa
	lda xbc, (FDemoText_VoiceActiveBit:24)
	ld	c, (xbc+wa)
	ldfr_berp C, 0xfa
	calr FDemoText_CheckVoiceState
	cp l, 1:i3
	jr z, FDemoText_Rescan_SetFlag
	ldto_berp A, 0xfa
	cpl a
	and (0x0247ee:24), a
	jr FDemoText_Rescan_NextVoice

FDemoText_Rescan_SetFlag:
	ldto_berp A, 0xfa
	or (0x0247ee:24), a

FDemoText_Rescan_NextVoice:
	inc1b_erp 0xfb
	cpib_erp 0xfb, 2
	jr ule, FDemoText_Rescan_Loop
	ldib_erp 0xfb, 0

FDemoText_Rescan_SendUpdates:
	ldto_berp A, 0xfb
	extz wa
	lda xbc, (FDemoText_VoiceActiveBit:24)
	ld	c, (xbc+wa)
	and c, (0x0247ee:24)
	call nz, (FDemoText_SendVoiceParams:24)
	inc1b_erp 0xfb
	cpib_erp 0xfb, 2
	jr ule, FDemoText_Rescan_SendUpdates
	popw_erp 0xfa
	ret

FDemoText_NotifyUIChange:
	push xiz
	extz bc
	ld xwa, 0x4900
	call DSPCfg_WriteParamFull
	ld e, (0xfc74:16)
	extz de
	pushw 0xff
	ldw wa, 0x61
	ld bc, 0:i3
	call AddswbWr
	ld xwa, 0x4904
	call DSPCfg_ReadParam_Map0
	ldfr_werp HL, 0xfa
	ld iz, 0:i3
	cpiw_erp 0xfa, 0
	jr ule, FDemoText_NotifyUI_Done

FDemoText_NotifyUI_Loop:
	ld wa, iz
	extz xwa
	add xwa, 0x4910
	call DSPCfg_ReadParam_Map1
	ld bc, hl
	ld wa, iz
	extz xwa
	add xwa, 0x4910
	call DSPCfg_WriteParamFull
	inc 1, iz
	cpw_erp IZ, 0xfa
	jr c, FDemoText_NotifyUI_Loop

FDemoText_NotifyUI_Done:
	pop xiz
	ret

FDemoText_RefreshFullDisplay:
	or (0x0247ee:24), 7
	calr FDemoText_ProcessVoiceFlags
	push xde
	push xhl
	push xix
	push xiz
	call SwbtWr_ReinitOutputBank
	call SwbtWr_CallProcessAll
	call SwbtWr_ReinitOutputBank
	pop xiz
	pop xix
	pop xhl
	pop xde
	ret

FDemoText_ByteData_DisplayRefresh:
	push	xiz
	ld	xiz, xwa
	cp	xiz, 0xffffffff
	jr	nz, FDemoText_ByteData_DisplayRefresh_Skip
	lda	xhl, (FDemoText_ByteData_DisplayRefresh_Str_NONE:24)
	jr	FDemoText_ByteData_DisplayRefresh_Epilogue
FDemoText_ByteData_DisplayRefresh_Skip:
	ld	xwa, xiz
	ld	xbc, EVT_GET_NAME
	ld	xde, 0:i3
	call	SendEvent
	cp	(xhl), 0
	jr	nz, FDemoText_ByteData_DisplayRefresh_Skip2
	ld	xwa, xiz
	srl	xwa, 16
	and	xwa, 4095
	extz	xwa
	add	xwa, TITLE_PS
	ld	xbc, EVT_GET_NAME
	ld	xde, 0:i3
	call	SendEvent
	ld	xwa, xiz
	ld	qwa, 0
	pushw	wa
	push	xhl
	pushw	FDemoText_ByteData_DisplayRefresh_Str_Fmts_Fmtd@hi16
	pushw	FDemoText_ByteData_DisplayRefresh_Str_Fmts_Fmtd@lo16
	pushw	2
	pushw	0x47f6
	call	Sprintf_Locked
	lda	xsp, (xsp+14)
	jr	FDemoText_ByteData_DisplayRefresh_Join
FDemoText_ByteData_DisplayRefresh_Skip2:
	push	xhl
	pushw	2
	pushw	0x47f6
	call	Strcpy
	inc	8, xsp
FDemoText_ByteData_DisplayRefresh_Join:
	lda	xhl, (0x0247f6:24)
FDemoText_ByteData_DisplayRefresh_Epilogue:
	pop	xiz
	ret
FDemoText_TextDispatch_Helper:
	lda xsp, (xsp-136)
	push	xiz
	push	xwa
	lda	xwa, (xsp+16)
	push	xwa
	call	Strcpy
	inc	8, xsp
	ld	xwa, 255
	ld	(xsp+4), xwa
FDemoText_ByteData_DisplayRefresh_Loop:
	ld	xbc, (xsp+4)
	ld	wa, bc
	call	CountObject
	extz	xhl
	ld	(xsp+8), xhl
	or	xhl, xhl
	jr	z, FDemoText_ByteData_DisplayRefresh_Skip4
	ld	xiz, 0:i3
	ld	xwa, (xsp+8)
	cp	xwa, 0
	jr	ule, FDemoText_ByteData_DisplayRefresh_Skip4
FDemoText_TextDispatch_Helper_Loop:
	ld	xbc, xiz
	ld	xwa, (xsp+4)
	sll	xwa, 16
	add	xwa, xbc
	call	CheckViewObject
	cp	hl, 0:i3
	jr	z, FDemoText_ByteData_DisplayRefresh_Skip3
	ld	xbc, xiz
	ld	xwa, (xsp+4)
	sll	xwa, 16
	add	xwa, xbc
	calr	FDemoText_ByteData_DisplayRefresh
	push	xhl
	lda	xwa, (xsp+16)
	push	xwa
	call	Strcmp
	inc	8, xsp
	cp	hl, 0:i3
	jr	nz, FDemoText_ByteData_DisplayRefresh_Skip3
	ld	xbc, xiz
	ld	xwa, (xsp+4)
	sll	xwa, 16
	add	xwa, xbc
	ld	xhl, xwa
	jr	FDemoText_ByteData_DisplayRefresh_Epilogue2
FDemoText_ByteData_DisplayRefresh_Skip3:
	inc	1, xiz
	ld	xwa, xiz
	cp	xwa, (xsp+0x8)
	jr	c, FDemoText_TextDispatch_Helper_Loop
FDemoText_ByteData_DisplayRefresh_Skip4:
	ld	xwa, 1:i3
	sub	(xsp+4), xwa
	ld	xwa, (xsp+4)
	cp	xwa, 0
	jr	ge, FDemoText_ByteData_DisplayRefresh_Loop
	.byte 0x40
	.long ErrStr_GetInstanceID
	call	FDemoText_ByteData_DisplayRefresh_Helper
	ld	xhl, 0xffffffff
FDemoText_ByteData_DisplayRefresh_Epilogue2:
	pop	xiz
	lda xsp, (xsp+136)
	ret
Seq_LoadDisplayResource_Helper:
	lda	xsp, (xsp-22)
	pushw	iz
	ld	(xsp+12), xde
	ld	(xsp+16), xbc
	ld	(xsp+20), xwa
	ldw	(xsp+2), 1
	jr	FDemoText_ByteData_DisplayRefresh_Join2
Seq_LoadDisplayResource_Helper_Loop:
	cp	hl, 60
	jr	nz, FDemoText_ByteData_DisplayRefresh_Join2
	ld	iz, 1:i3
Seq_LoadDisplayResource_Helper_Loop2:
	call	FileIO_ReadByte
	cp	hl, 0:i3
	jr	ge, FDemoText_ByteData_DisplayRefresh_Skip6
Seq_LoadDisplayResource_Helper_Loop3:
	cpw	(xsp+2), 0
	jr	z, FDemoText_ByteData_DisplayRefresh_Skip5
FDemoText_ByteData_DisplayRefresh_Join2:
	call	FileIO_ReadByte
	cp	hl, 0:i3
	jr	ge, Seq_LoadDisplayResource_Helper_Loop
FDemoText_ByteData_DisplayRefresh_Skip5:
	cpw	(xsp+2), 0
	jr	z, Seq_LoadDisplayResource_Helper_Skip
	ldw	hl, 0xfffd
	jrl	FDemoText_ByteData_DisplayRefresh_Epilogue3
FDemoText_ByteData_DisplayRefresh_Skip6:
	ld	xbc, (xsp+12)
	ld	a, (xbc+iz)
	extz wa
	cp	wa, hl
	jr	nz, Seq_LoadDisplayResource_Helper_Loop3
	inc	1, iz
	cp	(xbc+iz), 0x00
	jr	nz, Seq_LoadDisplayResource_Helper_Loop2
	ldw	(xsp+2), 0
Seq_LoadDisplayResource_Helper_Skip:
	ld	xwa, 0:i3
	ld	(xsp+4), xwa
FDemoText_ByteData_DisplayRefresh_Loop2:
	call	FileIO_ReadByte
	cp	hl, 0:i3
	jr	ge, Seq_LoadDisplayResource_Helper_Skip2
FDemoText_ByteData_DisplayRefresh_Loop3:
	cpw	(xsp+2), 1
	jrl	z, Seq_LoadDisplayResource_Helper_Skip4
	ldw	hl, 0xfffc
	jrl	FDemoText_ByteData_DisplayRefresh_Epilogue3
Seq_LoadDisplayResource_Helper_Skip2:
	cp	hl, 13
	jr	z, FDemoText_ByteData_DisplayRefresh_Skip7
	cp	hl, 10
	jr	z, FDemoText_ByteData_DisplayRefresh_Skip7
	cp	hl, 9
	jr	z, FDemoText_ByteData_DisplayRefresh_Skip7
	ld	xwa, (xsp+4)
	ld	(xsp+8), xwa
	ld	xbc, (xsp+20)
	add	xbc, (xsp+0x4)
	ld	a, l
	ld	(xbc), a
	ld	xwa, 1:i3
	add	(xsp+4), xwa
	ld	xwa, (xsp+4)
	cp	xwa, (xsp+16)
	jr	nc, FDemoText_ByteData_DisplayRefresh_Skip9
FDemoText_ByteData_DisplayRefresh_Skip7:
	cp	hl, 60
	jr	nz, FDemoText_ByteData_DisplayRefresh_Loop2
	ld	iz, 1:i3
Seq_LoadDisplayResource_Helper_Loop4:
	call	FileIO_ReadByte
	cp	hl, 0:i3
	jr	ge, FDemoText_ByteData_DisplayRefresh_Skip8
Seq_LoadDisplayResource_Helper_Loop5:
	cpw	(xsp+2), 1
	jr	z, FDemoText_ByteData_DisplayRefresh_Loop3
	jr	FDemoText_ByteData_DisplayRefresh_Loop2
FDemoText_ByteData_DisplayRefresh_Skip8:
	ld	xbc, (xsp+20)
	add	xbc, (xsp+0x4)
	ld	a, l
	ld	(xbc), a
	ld	xwa, 1:i3
	add	(xsp+4), xwa
	ld	xwa, (xsp+4)
	cp	xwa, (xsp+16)
	jr	c, Seq_LoadDisplayResource_Helper_Skip3
FDemoText_ByteData_DisplayRefresh_Skip9:
	ldw	hl, 0xfffb
	jr	FDemoText_ByteData_DisplayRefresh_Epilogue3
Seq_LoadDisplayResource_Helper_Skip3:
	ld	xbc, (xsp+28)
	ld	a, (xbc+iz)
	extz wa
	cp	wa, hl
	jr	nz, Seq_LoadDisplayResource_Helper_Loop5
	inc	1, iz
	cp	(xbc+iz), 0x00
	jr	nz, Seq_LoadDisplayResource_Helper_Loop4
	ldw	(xsp+2), 1
	ld	xwa, (xsp+20)
	add	xwa, (xsp+0x8)
	ld	(xwa), 0
	jr	Seq_LoadDisplayResource_Helper_Loop5
Seq_LoadDisplayResource_Helper_Skip4:
	ld	hl, 0:i3
FDemoText_ByteData_DisplayRefresh_Epilogue3:
	popw	iz
	lda	xsp, (xsp+22)
	retd	4

FDemoText_ProcessTextMarkup:
	lda xsp, (xsp - 86)
	push xiz
	ld (xsp + 84), bc
	ld (xsp + 86), xwa
	ldw (xsp + 18), 0x0
	ld xwa, (xsp + 86)
	cp (xwa), 0x0
	jr nz, FDemoText_ProcessMarkup_CheckTagOpen
	ld xhl, (xsp + 86)
	jrl FDemoText_ProcessMarkup_Return

FDemoText_ProcessMarkup_CheckTagOpen:
	ld xwa, (xsp + 86)
	cp (xwa), 0x3c
	jrl nz, FDemoText_ProcessMarkup_PlainText
	ldw (xsp + 16), 0x0
	jrl FDemoText_ProcessMarkup_TagTableLoop

FDemoText_ProcessMarkup_LookupTag:
	ld xwa, (xbc)
	push xwa
	call Strlen
	ld (xsp + 18), hl
	pushm (xsp + 18)
	ld xwa, (xsp + 92)
	inc 1, xwa
	push xwa
	ld bc, (xsp + 26)
	sla bc, 3
	lda xwa, (FDemoText_MarkupTagTable:24)
	ld	xwa, (xwa+bc)
	push xwa
	call String_Compare
	add xsp, 0xe
	cp hl, 0:i3
	jrl nz, FDemoText_ProcessMarkup_NextTag
	ld bc, (xsp + 16)
	sla bc, 3
	lda xwa, (FDemoText_MarkupTag_HandlerColumn:24)
	ld	xwa, (xwa+bc)
	ld (xsp + 4), xwa
	or xwa, xwa
	jrl z, FDemoText_ProcessMarkup_SkipToEnd
	ld xiz, 0:i3
	ld xbc, (xsp + 86)
	jr FDemoText_ProcessMarkup_ScanLoop

FDemoText_ProcessMarkup_ScanTagEnd:
	inc 1, xiz
	inc 1, xbc

FDemoText_ProcessMarkup_ScanLoop:
	ld a, (xbc)
	cp a, 0:i3
	jr z, FDemoText_ProcessMarkup_AllocCopy
	cp a, 0x3e
	jr nz, FDemoText_ProcessMarkup_ScanTagEnd

FDemoText_ProcessMarkup_AllocCopy:
	ld xwa, xiz
	inc 1, xwa
	pushw wa
	call Malloc
	ld (xsp + 14), xhl
	ld xbc, (xsp + 14)
	ld (xsp + 10), xbc
	ld wa, iz
	pushw wa
	ld xwa, (xsp + 90)
	inc 1, xwa
	push xwa
	push xbc
	call Strncpy
	lda xsp, (xsp + 12)
	ld xwa, (xsp + 12)
	add xwa, xiz
	ld (xwa), 0x0
	ld wa, 0:i3
	lda xbc, (xsp + 20)
	ld (xsp + 16), xbc
	ld xde, (xsp + 12)
	ld xbc, (xsp + 16)
	ld (xbc), xde
	ld xix, 0:i3
	ld hl, 0:i3
	cp xiz, 0x0
	jr ule, FDemoText_ProcessMarkup_CallHandler

FDemoText_ProcessMarkup_ParseAttrs:
	ld xbc, (xsp + 8)
	lda	xbc, (xbc+hl)
	ld e, (xbc)
	cp e, 0x22
	jr z, FDemoText_ProcessMarkup_ToggleQuote
	cp e, 0x3e
	jr z, FDemoText_ProcessMarkup_NullTermAttr
	cp e, 0x20
	jr nz, FDemoText_ProcessMarkup_NextChar
	or xix, xix
	jr nz, FDemoText_ProcessMarkup_NextChar
	ld (xbc), 0x0
	inc 1, wa
	cp wa, 0x10
	jr ge, FDemoText_ProcessMarkup_NextChar
	ld iy, wa
	sla iy, 2
	ld de, hl
	inc 1, de
	ld xbc, (xsp + 8)
	exts xde
	add xde, xbc
	ld xbc, (xsp + 16)
	ld	(xbc+iy), xde
	jr FDemoText_ProcessMarkup_NextChar

FDemoText_ProcessMarkup_NullTermAttr:
	ld (xbc), 0x0

FDemoText_ProcessMarkup_ToggleQuote:
	or xix, xix
	scc16 z, bc
	ld ix, bc
	exts xix

FDemoText_ProcessMarkup_NextChar:
	inc 1, hl
	ld bc, hl
	exts xbc
	cp xbc, xiz
	jr c, FDemoText_ProcessMarkup_ParseAttrs

FDemoText_ProcessMarkup_CallHandler:
	ld xhl, (xsp + 4)
	ld xbc, (xsp + 16)
	ld de, (xsp + 84)
	call (xhl)
	ld (xsp + 18), hl
	ld xwa, (xsp + 8)
	push xwa
	call Free
	inc 4, xsp

FDemoText_ProcessMarkup_SkipToEnd:
	ld xwa, (xsp + 86)
	inc 1, xwa
	ld xiz, xwa
	cpw (xsp + 18), 0x0
	jr nz, FDemoText_ProcessMarkup_AfterHandler
	cp (xwa), 0x0
	jrl z, FDemoText_ProcessMarkup_Done

FDemoText_ProcessMarkup_ScanClose:
	cp (xiz+), 0x3e
	jrl z, FDemoText_ProcessMarkup_Done
	cp (xiz), 0x0
	jr nz, FDemoText_ProcessMarkup_ScanClose
	jrl FDemoText_ProcessMarkup_Done

FDemoText_ProcessMarkup_AfterHandler:
	cp (xwa), 0x0
	jrl z, FDemoText_ProcessMarkup_Done

FDemoText_ProcessMarkup_FindNull:
	inc 1, xiz
	cp (xiz), 0x0
	jr nz, FDemoText_ProcessMarkup_FindNull
	jrl FDemoText_ProcessMarkup_Done

FDemoText_ProcessMarkup_NextTag:
	incw 1, (xsp + 16)

FDemoText_ProcessMarkup_TagTableLoop:
	ld bc, (xsp + 16)
	sla bc, 3
	lda xwa, (FDemoText_MarkupTagTable:24)
	exts xbc
	add xbc, xwa
	ld xwa, (xbc)
	or xwa, xwa
	jrl nz, FDemoText_ProcessMarkup_LookupTag
	ld xwa, (xsp + 86)
	inc 1, xwa
	ld xiz, xwa
	cp (xwa), 0x0
	jr z, FDemoText_ProcessMarkup_Done

FDemoText_ProcessMarkup_NoHandler:
	cp (xiz+), 0x3e
	jr z, FDemoText_ProcessMarkup_Done
	cp (xiz), 0x0
	jr nz, FDemoText_ProcessMarkup_NoHandler
	jr FDemoText_ProcessMarkup_Done

FDemoText_ProcessMarkup_PlainText:
	ld xwa, (xsp + 86)
	inc 1, xwa
	ld xiz, xwa
	cp (xwa), 0x0
	jr z, FDemoText_ProcessMarkup_CopyAndRender

FDemoText_ProcessMarkup_ScanPlainEnd:
	cp (xiz), 0x3e
	jr nz, FDemoText_ProcessMarkup_CheckOpenTag
	inc 1, xiz
	jr FDemoText_ProcessMarkup_CopyAndRender

FDemoText_ProcessMarkup_CheckOpenTag:
	cp (xiz), 0x3c
	jr z, FDemoText_ProcessMarkup_CopyAndRender
	inc 1, xiz
	cp (xiz), 0x0
	jr nz, FDemoText_ProcessMarkup_ScanPlainEnd

FDemoText_ProcessMarkup_CopyAndRender:
	ld xwa, xiz
	sub xwa, (xsp + 86)
	ld (xsp + 14), wa
	ld wa, (xsp + 14)
	inc 1, wa
	pushw wa
	call Malloc
	ld (xsp + 18), xhl
	pushm (xsp + 16)
	ld xwa, (xsp + 90)
	push xwa
	ld xwa, (xsp + 24)
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 12)
	ld wa, (xsp + 14)
	extz xwa
	add xwa, (xsp + 16)
	ld (xwa), 0x0
	ld xwa, (xsp + 16)
	ld bc, (xsp + 84)
	calr FDemoText_TextDispatch
	ld xwa, (xsp + 16)
	push xwa
	call Free
	inc 4, xsp

FDemoText_ProcessMarkup_Done:
	ld xhl, xiz

FDemoText_ProcessMarkup_Return:
	pop xiz
	lda xsp, (xsp + 86)
	ret

FDemoText_ByteData_TextRenderer:
	lda	xsp, (xsp-12)
	pushw	iz
	ld	(xsp+6), xde
	ld	(xsp+10), xbc
	ld	iz, wa
	ld	wa, iz
	exts	xwa
	sll	xwa, 2
	add	xwa, (xsp+0xa)
	ld	xwa, (xwa)
	push	xwa
	call	Strlen
	inc	1, hl
	pushw	hl
	call	Malloc
	ld	(xsp+8), xhl
	ld	wa, iz
	exts	xwa
	sll	xwa, 2
	add	xwa, (xsp+16)
	ld	xwa, (xwa)
	push	xwa
	ld	xwa, (xsp+12)
	push	xwa
	call	Strcpy
	ld	iz, 0:i3
	pushw	64
	ld	xwa, (xsp+18)
	push	xwa
	ld	xwa, (xsp+26)
	push	xwa
	call	Strncpy
	lda	xsp, (xsp+24)
	ld	xwa, (xsp+6)
	ld	(xwa+64), 0
	ld	xwa, (xsp+18)
	ld	(xwa), 0
	ld	xwa, (xsp+2)
	cp	(xwa), 0
	jr	z, FDemoText_ByteData_TextRenderer_Skip2
FDemoText_ByteData_TextRenderer_Loop:
	ld	xde, (xsp+2)
	lda	xwa, (xde+iz)
	ld xbc, xwa
	cp	(xwa), 61
	jr	nz, FDemoText_ByteData_TextRenderer_Skip3
	ld	(xbc), 0
	push	xde
	ld	xwa, (xsp+10)
	push	xwa
	call	Strcpy
	inc	8, xsp
	inc	1, iz
	ld	xde, (xsp+2)
	lda	xwa, (xde+iz)
	ld xbc, xwa
	ld	a, (xwa)
	cp	a, 34
	jr	nz, FDemoText_ByteData_TextRenderer_Skip
	inc	1, iz
	lda	xwa, (xde+iz)
	push xwa
	ld xwa, (xsp+22)
	push xwa
	call	Strcpy
	ld	xwa, (xsp+26)
	push	xwa
	call	Strlen
	lda	xsp, (xsp+12)
	dec	1, hl
	extz	xhl
	add	xhl, (xsp+18)
	ld	(xhl), 0
	jr	FDemoText_ByteData_TextRenderer_Skip2
FDemoText_ByteData_TextRenderer_Skip:
	push	xbc
	ld	xwa, (xsp+22)
	push	xwa
	call	Strcpy
	inc	8, xsp
	jr	FDemoText_ByteData_TextRenderer_Skip2
FDemoText_ByteData_TextRenderer_Skip3:
	inc	1, iz
	ld	xwa, (xsp+2)
	cp	(xwa+iz), 0x00
	jr	nz, FDemoText_ByteData_TextRenderer_Loop
FDemoText_ByteData_TextRenderer_Skip2:
	ld	xwa, (xsp+2)
	push	xwa
	call	Free
	inc	4, xsp
	popw	iz
	lda	xsp, (xsp+12)
	retd	4

FDemoText_TextDispatch:
	cp bc, 1:i3
	jr z, FDemoText_TextDispatch_Return
	cp bc, 0:i3
	call z, (FDemoText_RenderTextLine:24)

FDemoText_TextDispatch_Return:
	ld hl, 0:i3
	ret

FDemoText_ByteData_LayoutEngine:
	lda xsp, (xsp-222)
	push	xiz
	ld (xsp+218), de
	ld	(xsp+220), xbc
	ld	(xsp+224), wa
	ld	xiy, FDemoText_NameValueInit
	lda	xix, (xsp+20)
	ldw	bc, 32
	ldirw
	ldi85
	ld	xiy, FDemoText_SongSrcInit
	lda	xix, (xsp+6)
	ld	bc, 6:i3
	ldirw
	ldi85
	ld	iz, 0:i3
	cpw	(xsp+224), 0
	jr	lt, FDemoText_TextDispatch_Skip3
FDemoText_TextDispatch_Loop4:
	lda xde, (xsp+152)
	lda xwa, (xsp+86)
	push xwa
	ld wa, iz
	ld	xbc, (xsp+224)
	calr	FDemoText_ByteData_TextRenderer
	ld qiz, 0
	jr	FDemoText_TextDispatch_Join2
FDemoText_TextDispatch_Loop5:
	lda xwa, (xsp+152)
	push xwa
	push xbc
	call	Strcmp
	inc	8, xsp
	cp	hl, 0:i3
	jr	nz, FDemoText_TextDispatch_Join
	ld wa, qiz
	lda	xbc, (xsp+86)
	cp qiz, 2
	jr z, FDemoText_TextDispatch_Skip2
	cp wa, 1:i3
	jr z, FDemoText_TextDispatch_Skip
	cp	wa, 0:i3
	jr	nz, FDemoText_TextDispatch_Join
	push	xbc
	call	ParseInt16
	inc	4, xsp
	ld	(xsp+4), hl
	jr	FDemoText_TextDispatch_Join
FDemoText_TextDispatch_Skip:
	push	xbc
	lda	xwa, (xsp+10)
	push	xwa
	jr	FDemoText_TextDispatch_Join6
FDemoText_TextDispatch_Skip2:
	push	xbc
	lda	xwa, (xsp+24)
	push	xwa
FDemoText_TextDispatch_Join6:
	call	Strcpy
	inc	8, xsp
FDemoText_TextDispatch_Join:
	inc 1, qiz
FDemoText_TextDispatch_Join2:
	ld bc, qiz
	sla bc, 2
	lda	xwa, (FDemoText_ExecTagAttrNames:24)
	ld	xbc, (xwa+bc)
	cp	(xbc), 0
	jr	nz, FDemoText_TextDispatch_Loop5
	inc	1, iz
	cp	iz, (xsp+224)
	jr	le, FDemoText_TextDispatch_Loop4
FDemoText_TextDispatch_Skip3:
	cpw	(xsp+218), 1
	jrl	z, FDemoText_TextDispatch_Skip4
	cpw	(xsp+218), 0
	jrl	nz, FDemoText_TextDispatch_Skip4
	lda	xbc, (xsp+6)
	cp	(xbc), 0
	jrl	z, FDemoText_TextDispatch_Skip4
	ld	wa, (xsp+4)
	dec	1, wa
	ld	(0x024876:24), wa
	push	xbc
	pushw	FDemoText_ByteData_LayoutEngine_Str_Fmt8s@hi16
	pushw	FDemoText_ByteData_LayoutEngine_Str_Fmt8s@lo16
	pushw	2
	pushw	0x4878
	call	Sprintf_Locked
	lda	xwa, (xsp+18)
	push	xwa
	pushw	2
	pushw	0x4878
	call	Strcpy
	lda	xwa, (xsp+40)
	push	xwa
	pushw	2
	pushw	0x4882
	call	Strcpy
	lda	xsp, (xsp+28)
	ld	xwa, NAKA_VIEW_Demofeature1
	ld	xbc, EVT_HIDE
	ld	xde, 5:i3
	call	SendEvent
	ld	xwa, NAKA_VIEW_Demofeature2
	ld	xbc, EVT_HIDE
	ld	xde, 5:i3
	call	SendEvent
	ld	xwa, NAKA_VIEW_Demofeature2
	ld	xbc, EVT_SHOW
	ld	xde, 5:i3
	call	SendEvent
	ld	xwa, NAKA_VIEW_Demofeature2
	ld	xbc, EVT_START_SONG
	ld	xde, 19
	call	SendEvent
	ld	xwa, NAKA_VIEW_PleaseWait
	ld	xbc, EVT_SHOW
	ld	xde, 0:i3
	call	SendEvent
	pushw	2
	pushw	0x4878
	call	Strlen
	inc	1, hl
	pushw	hl
	call	Malloc
	ld	xiz, xhl
	pushw	2
	pushw	0x4878
	push	xiz
	call	Strcpy
	lda	xsp, (xsp+14)
	ld	xwa, NAKA_MAINFUNC_MainPreControl
	ld	xbc, EVT_READ_SONG_REQ
	ld	xde, xiz
	call	MainFuncCall
	ld	xwa, NAKA_MAINFUNC_MainAutoFree
	ld	xbc, EVT_AUTO_FREE
	ld	xde, xiz
	call	MainFuncCall
FDemoText_TextDispatch_Skip4:
	ld	hl, 0:i3
	pop	xiz
	lda xsp, (xsp+222)
	ret
	lda xsp, (xsp-142)
	push	xiz
	ld	(xsp+138), de
	ld	(xsp+0x8c), xbc
	ld	(xsp+0x90), wa
	ldw	(xsp+0x4), 0
	cpw	(xsp+144), 0
	jrl	lt, FDemoText_TextDispatch_Skip13
FDemoText_TextDispatch_Loop6:
	lda	xde, (xsp+72)
	lda	xwa, (xsp+6)
	push	xwa
	ld	wa, (xsp+8)
	ld	xbc, (xsp+144)
	calr	FDemoText_ByteData_TextRenderer
	ld qiz, 0
	jr	FDemoText_TextDispatch_Join7
FDemoText_TextDispatch_Loop7:
	lda	xbc, (xsp+72)
	push	xbc
	push	xwa
	call	Strcmp
	inc	8, xsp
	cp	hl, 0:i3
	jr	nz, FDemoText_TextDispatch_Join3
	ld	bc, qiz
	lda	xwa, (xsp+6)
	cp qiz, 1
	jr z, FDemoText_TextDispatch_Skip5
	cp bc, 0:i3
	jr	nz, FDemoText_TextDispatch_Join3
	push	xwa
	call	ParseInt16
	inc	4, xsp
	ld	iz, hl
	jr	FDemoText_TextDispatch_Join3
FDemoText_TextDispatch_Skip5:
	ld c, (xwa+)
	cp c, 82
	jr	z, FDemoText_TextDispatch_Skip7
	cp	c, 67
	jr	z, FDemoText_TextDispatch_Skip6
	cp	c, 76
	jr	nz, FDemoText_TextDispatch_Join3
	push	xwa
	call	ParseInt16
	inc	4, xsp
	ldw	iz, 64
	sub	iz, hl
	jr	FDemoText_TextDispatch_Join3
FDemoText_TextDispatch_Skip6:
	ldw	iz, 64
	jr	FDemoText_TextDispatch_Join3
FDemoText_TextDispatch_Skip7:
	push	xwa
	call	ParseInt16
	inc	4, xsp
	ld	iz, hl
	add	iz, 64
FDemoText_TextDispatch_Join3:
	inc 1, qiz
FDemoText_TextDispatch_Join7:
	ld bc, qiz
	sla bc, 2
	lda	xwa, (FDemoText_ActTag_AttrNames:24)
	ld	xwa, (xwa+bc)
	cp	(xwa), 0
	jr	nz, FDemoText_TextDispatch_Loop7
	incw	1, (xsp+4)
	ld	wa, (xsp+4)
	cp	wa, (xsp+144)
	jrl	le, FDemoText_TextDispatch_Loop6
FDemoText_TextDispatch_Skip13:
	cpw	(xsp+138), 2
	jr	z, FDemoText_TextDispatch_Skip14
	cpw	(xsp+138), 1
	jr	z, FDemoText_TextDispatch_Skip14
	cpw	(xsp+138), 0
	jr	nz, FDemoText_TextDispatch_Join4
	calr	FDemoText_TextDispatch_Helper2
	ld	xwa, 0xffffffff
	ld	xbc, EVT_SET_NOT_DRAW_FLAG
	ld	xde, 1:i3
	call	SendEvent
	ld	xwa, NAKA_VIEW_PlainScreen
	ld	xbc, EVT_SHOW
	ld	xde, 0:i3
	call	SendEvent
	ld	xwa, NAKA_VIEW_PresentationControl
	ld	xbc, EVT_SHOW
	ld	xde, 5:i3
	call	SendEvent
	ld	xwa, 0xffffffff
	ld	xbc, EVT_SET_NOT_DRAW_FLAG
	ld	xde, 0:i3
	call	SendEvent
	call	DrawWall
	jr	FDemoText_TextDispatch_Join4
FDemoText_TextDispatch_Skip14:
	cp	iz, 0:i3
	jr	lt, FDemoText_TextDispatch_Join4
	cp	iz, 127
	jr	gt, FDemoText_TextDispatch_Join4
	ld	bc, iz
	sla	bc, 2
	lda	xde, (0x024fd8:24)
	ld	xwa, (0x0249d4:24)
	ld	(xde+bc), xwa
FDemoText_TextDispatch_Join4:
	ld hl, 0:i3
	pop xiz
	lda xsp, (xsp+142)
	ret
	cp	de, 1:i3
	jr	z, FDemoText_TextDispatch_Skip15
	cp	de, 0:i3
	scc16	z, hl
	ret
FDemoText_TextDispatch_Skip15:
	ld	hl, 0:i3
	ret
	cp	de, 1:i3
	jr	z, FDemoText_TextDispatch_Skip16
	cp	de, 0:i3
	call	z, (0xf85eca:24)
FDemoText_TextDispatch_Skip16:
	ld	hl, 0:i3
	ret
	cp	de, 1:i3
	jr	z, FDemoText_TextDispatch_Skip17
	cp	de, 0:i3
	jr	nz, FDemoText_TextDispatch_Skip17
	calr	FDemoText_UpdateCursorPosition
	ld	wa, (0x025b72:24)
	inc	1, wa
	ld	(0x025b72:24), wa
	cp	wa, 8
	jr	ge, FDemoText_TextDispatch_Skip17
	lda	xbc, (0x025b74:24)
	.byte 0xf3
	.long ToneGen_ParamTable
	nop
FDemoText_TextDispatch_Skip17:
	ld	hl, 0:i3
	ret
	cp	de, 1:i3
	jr	z, FDemoText_TextDispatch_Skip19
	cp	de, 0:i3
	jr	nz, FDemoText_TextDispatch_Skip19
	calr	FDemoText_UpdateCursorPosition
	ld	wa, (0x025b72:24)
	dec	1, wa
	ld	(0x025b72:24), wa
	cp	wa, 0:i3
	jr	ge, FDemoText_TextDispatch_Skip18
	ldw	(0x025b72:24), 0
FDemoText_TextDispatch_Skip18:
	lda	xbc, (0x025b74:24)
	ld	wa, (0x025b72:24)
	ld	(xbc+wa), 0x01
FDemoText_TextDispatch_Skip19:
	ld	hl, 0:i3
	ret
	lda xsp, (xsp-146)
	push	xiz
	ld	(xsp+142), de
	ld	(xsp+144), xbc
	ld (xsp+148), wa
	ld	wa, (0x025b3e:24)
	sla	wa, 2
	lda	xbc, (0x025b40:24)
	ld	xwa, (xbc+wa)
	ld	(xsp+0x4), xwa
	ld	wa, (0x25b60:24)
	sla	wa, 1
	lda	xbc, (0x25b62:24)
	ld	wa, (xbc+wa)
	ld	(xsp+0x8), wa
	ld	iz, 0:i3
	cpw	(xsp+0x94), 0
	jrl	lt, FDemoText_TextDispatch_Skip21
FDemoText_TextDispatch_Loop8:
	lda	xde, (xsp+76)
	lda	xwa, (xsp+10)
	push	xwa
	ld	wa, iz
	ld	xbc, (xsp+148)
	calr	FDemoText_ByteData_TextRenderer
	ld qiz, 0
	jr	FDemoText_TextDispatch_Join8
FDemoText_TextDispatch_Loop9:
	lda	xbc, (xsp+76)
	push	xbc
	push	xwa
	call	Strcmp
	inc	8, xsp
	cp	hl, 0:i3
	jr	nz, FDemoText_TextDispatch_Skip8
	ld	bc, qiz
	lda	xwa, (xsp+10)
	cp qiz, 1
	jr z, FDemoText_TextDispatch_Skip20
	cp bc, 0:i3
	jr nz, FDemoText_TextDispatch_Skip8
	push	xwa
	call	ParseInt16
	inc	4, xsp
	cp	hl, 0:i3
	jr	lt, FDemoText_TextDispatch_Skip8
	cp	hl, 9
	jr	gt, FDemoText_TextDispatch_Skip8
	sla	hl, 2
	lda	xwa, (FDemoText_FontSizeToFont:24)
	ld	xwa, (xwa+hl)
	ld	(xsp+0x4), xwa
	jr	FDemoText_TextDispatch_Skip8
FDemoText_TextDispatch_Skip20:
	push	xwa
	call	ParseInt16
	inc	4, xsp
	cp	hl, 0:i3
	jr	lt, FDemoText_TextDispatch_Skip8
	cp	hl, 255
	jr	gt, FDemoText_TextDispatch_Skip8
	ld	(xsp+8), hl
FDemoText_TextDispatch_Skip8:
	inc 1, qiz
FDemoText_TextDispatch_Join8:
	ld bc, qiz
	sla bc, 2
	lda	xwa, (FDemoText_FontTagAttrNames:24)
	ld	xwa, (xwa+bc)
	cp	(xwa), 0
	jr	nz, FDemoText_TextDispatch_Loop9
	inc	1, iz
	cp	iz, (xsp+0x94)
	jrl	le, FDemoText_TextDispatch_Loop8
FDemoText_TextDispatch_Skip21:
	cpw	(xsp+142), 1
	jr	z, FDemoText_TextDispatch_Skip22
	cpw	(xsp+142), 0
	jr	nz, FDemoText_TextDispatch_Skip22
	ld	bc, (0x025b3e:24)
	inc	1, bc
	ld	(0x025b3e:24), bc
	ld	wa, (0x025b60:24)
	inc	1, wa
	ld	(0x025b60:24), wa
	cp	bc, 8
	jr	ge, FDemoText_TextDispatch_Skip22
	sla	bc, 2
	lda	xde, (0x025b40:24)
	ld	xwa, (xsp+4)
	ld	(xde+bc), xwa
	ld	bc, (0x25b60:24)
	sla	bc, 1
	lda	xde, (0x025b62:24)
	ld	wa, (xsp+8)
	ld	(xde+bc), wa
FDemoText_TextDispatch_Skip22:
	ld	hl, 0:i3
	pop	xiz
	lda xsp, (xsp+146)
	ret
	cp	de, 1:i3
	jr	z, FDemoText_TextDispatch_Skip9
	cp	de, 0:i3
	jr	nz, FDemoText_TextDispatch_Skip9
	ld	wa, (0x025b3e:24)
	dec	1, wa
	ld	(0x025b3e:24), wa
	decw	1, (0x025b60:24)
	cp	wa, 0:i3
	jr	ge, FDemoText_TextDispatch_Skip23
	ldw	(0x025b3e:24), 0
	ldw	(0x025b60:24), 0
FDemoText_TextDispatch_Skip23:
	ld	bc, (0x025b3e:24)
	sla	bc, 2
	lda	xde, (0x025b40:24)
	ld	xwa, 5:i3
	ld	(xde+bc), xwa
	ld	wa, (0x25b60:24)
	sla	wa, 1
	lda	xbc, (0x25b62:24)
	ldw	(xbc+wa), 0x00ff
FDemoText_TextDispatch_Skip9:
	ld	hl, 0:i3
	ret
	lda xsp, (xsp-272)
	push	xiz
	ld	(xsp+0x10c), de
	ld	(xsp+0x10e), xbc
	ld	(xsp+0x112), wa
	ld	xiy, FDemoText_ImgSrcBufInit
	lda	xix, (xsp+0x46)
	ldw	bc, 32
	ldirw
	ldi85
	ld	xiy, FDemoText_ImgAltInit
	lda	xix, (xsp+4)
	ldw	bc, 32
	ldirw
	ldi85
	ld	iz, 0:i3
	cpw	(xsp+274), 0
	jr	lt, FDemoText_TextDispatch_Skip25
FDemoText_TextDispatch_Loop12:
	lda	xde, (xsp+0xca)
	lda	xwa, (xsp+0x88)
	push	xwa
	ld	wa, iz
	ld	xbc, (xsp+0x112)
	calr	FDemoText_ByteData_TextRenderer
	ld qiz, 0
	jr	FDemoText_TextDispatch_Join9
FDemoText_TextDispatch_Loop13:
	lda	xwa, (xsp+202)
	push	xwa
	push	xbc
	call	Strcmp
	inc	8, xsp
	cp	hl, 0:i3
	jr	nz, FDemoText_TextDispatch_Skip24
	ld wa, qiz
	cpw qiz, 8
	jr	gt, FDemoText_TextDispatch_Skip24
	cp	wa, 2:i3
	jr	ge, FDemoText_TextDispatch_Skip24
	lda	xbc, (xsp+136)
	cp	wa, 0:i3
	jr	z, FDemoText_TextDispatch_Skip26
	cp	wa, 1:i3
	jr	z, FDemoText_TextDispatch_Skip27
	jr	FDemoText_TextDispatch_Skip24
FDemoText_TextDispatch_Skip26:
	push	xbc
	lda	xwa, (xsp+0x4a)
	push	xwa
	jr	FDemoText_TextDispatch_Join11
FDemoText_TextDispatch_Skip27:
	push	xbc
	lda	xwa, (xsp+8)
	push	xwa
FDemoText_TextDispatch_Join11:
	call	Strcpy
	inc	8, xsp
FDemoText_TextDispatch_Skip24:
	inc 1, qiz
FDemoText_TextDispatch_Join9:
	ld bc, qiz
	sla bc, 2
	lda	xwa, (ImgAttr_NameTable:24)
	ld	xbc, (xwa+bc)
	cp	(xbc), 0
	jr	nz, FDemoText_TextDispatch_Loop13
	inc	1, iz
	cp	iz, (xsp+274)
	jr	le, FDemoText_TextDispatch_Loop12
FDemoText_TextDispatch_Skip25:
	lda	xbc, (xsp+70)
	cpw	(xsp+268), 1
	jr	z, FDemoText_TextDispatch_Skip28
	cpw	(xsp+268), 0
	jr	nz, FDemoText_TextDispatch_Join10
	ld	xwa, xbc
	cp	(xbc), 0
	jr	z, FDemoText_TextDispatch_Join10
	calr	FDemoText_ByteData_LayoutB
	jr	FDemoText_TextDispatch_Join10
FDemoText_TextDispatch_Skip28:
	ld	xwa, xbc
	cp	(xbc), 0
	call	nz, (0xf868fd:24)
FDemoText_TextDispatch_Join10:
	ld	hl, 0:i3
	pop	xiz
	lda	xsp, (xsp+0x110)
	ret
	lda xsp, (xsp-206)
	push	xiz
	ld (xsp+202), de
	ld	(xsp+204), xbc
	ld (xsp+208), wa
	ld	xiy, FDemoText_ObjValueInit
	lda	xix, (xsp+4)
	ldw	bc, 32
	ldirw
	ldi85
	ld	iz, 0:i3
	cpw	(xsp+208), 0
	jr	lt, FDemoText_TextDispatch_Skip11
FDemoText_TextDispatch_Loop10:
	lda xde, (xsp+136)
	lda xwa, (xsp+70)
	push xwa
	ld wa, iz
	ld	xbc, (xsp+208)
	calr	FDemoText_ByteData_TextRenderer
	ld qiz, 0
	jr FDemoText_TextDispatch_Join5
FDemoText_TextDispatch_Loop11:
	lda xwa, (xsp+136)
	push xwa
	push xbc
	call	Strcmp
	inc	8, xsp
	cp	hl, 0:i3
	jr	nz, FDemoText_TextDispatch_Skip10
	cp qiz, 0
	jr nz, FDemoText_TextDispatch_Skip10
	lda	xwa, (xsp+70)
	push	xwa
	lda	xwa, (xsp+8)
	push	xwa
	call	Strcpy
	inc	8, xsp
FDemoText_TextDispatch_Skip10:
	inc 1, qiz
FDemoText_TextDispatch_Join5:
	ld bc, qiz
	sla bc, 2
	lda	xwa, (ObjAttr_NameTable:24)
	ld	xbc, (xwa+bc)
	cp	(xbc), 0
	jr	nz, FDemoText_TextDispatch_Loop11
	inc	1, iz
	cp	iz, (xsp+208)
	jr	le, FDemoText_TextDispatch_Loop10
FDemoText_TextDispatch_Skip11:
	cpw	(xsp+202), 1
	jr	z, FDemoText_TextDispatch_Skip12
	cpw	(xsp+202), 0
	jr	nz, FDemoText_TextDispatch_Skip12
	lda	xwa, (xsp+4)
	cp	(xwa), 0
	jr	z, FDemoText_TextDispatch_Skip12
	calr	FDemoText_TextDispatch_Helper
	ld	xwa, xhl
	cp	xwa, 0xffffffff
	jr	z, FDemoText_TextDispatch_Skip12
	ld	xbc, EVT_SHOW
	ld	xde, 0:i3
	call	SendEvent
	ld	xwa, NAKA_VIEW_PresentationControl
	ld	xbc, EVT_SHOW
	ld	xde, 5:i3
	call	SendEvent
FDemoText_TextDispatch_Skip12:
	ld	hl, 0:i3
	pop	xiz
	lda xsp, (xsp+206)
	ret
FDemoText_TextDispatch_Helper2:
	lda	xbc, (0x0251da:24)
	ld	xwa, xbc
	lda xbc, (xbc+2400)
FDemoText_TextDispatch_Loop:
	ld xde, xwa
	lda	xhl, (xwa+40)
FDemoText_TextDispatch_Loop2:
	ld (xde+), 84
	cp	xde, xhl
	jr	c, FDemoText_TextDispatch_Loop2
	lda	xwa, (xwa+40)
	cp	xwa, xbc
	jr	c, FDemoText_TextDispatch_Loop
	lda	xwa, (0x025b3a:24)
	ldw	(xwa), 0
	ldw	(xwa+2), 0
	ldw	(0x025b3e:24), 0
	ldw	(0x025b60:24), 0
	ldw	(0x025b72:24), 0
	lda	xhl, (0x025b40:24)
	lda	xde, (0x025b62:24)
	lda	xwa, (0x025b74:24)
	ld	xbc, xwa
	lda	xix, (xwa+8)
FDemoText_TextDispatch_Loop3:
	ld	xwa, 5:i3
	ld (xhl+), xwa
	ldw (xde+), 0x00ff
	ld	(xbc+), 1
	cp	xbc, xix
	jr	c, FDemoText_TextDispatch_Loop3
	ret

FDemoText_ScaleDownCoords:
	ld de, (xwa)
	exts xde
	divs de, 0x8
	ld (xbc), de
	ld wa, (xwa + 2)
	exts xwa
	divs wa, 0x4
	ld (xbc + 2), wa
	ret

FDemoText_ScaleUpCoords:
	ld de, (xwa)
	sla de, 3
	ld (xbc), de
	ld wa, (xwa + 2)
	sla wa, 2
	inc 3, wa
	ld (xbc + 2), wa
	ret

FDemoText_CalcTextExtent:
	dec 8, xsp
	push xiz
	ld xiz, xwa
	lda xbc, (xsp + 8)
	ld xwa, xiz
	calr FDemoText_ScaleDownCoords
	lda xwa, (xsp + 8)
	lda xbc, (xsp + 4)
	calr FDemoText_ScaleUpCoords
	lda xwa, (xsp + 8)
	ld ix, (xwa)
	inc 1, ix
	ld hl, (xsp + 4)
	inc 8, hl
	sub hl, (xiz)
	cp ix, 0x28
	jr ge, FDemoText_CalcExtent_Done
	ld wa, (xwa + 2)
	muls wa, 0x28
	lda xde, (0x0251da:24)

FDemoText_CalcExtent_ScanLoop:
	ld bc, wa
	add bc, ix
	cp	(xde+bc), 0x54
	jr nz, FDemoText_CalcExtent_Done
	inc 8, hl
	inc 1, ix
	cp ix, 0x28
	jr lt, FDemoText_CalcExtent_ScanLoop

FDemoText_CalcExtent_Done:
	pop xiz
	inc 8, xsp
	ret

FDemoText_UpdateCursorPosition:
	dec 4, xsp
	pushw iz
	lda xbc, (xsp + 2)
	ld xwa, 0x25b3a
	calr FDemoText_ScaleDownCoords
	ld wa, (0x025b3e:24)
	sla wa, 2
	lda xbc, (0x025b40:24)
	ld	xwa, (xbc+wa)
	call GetCenteredDelta
	ld iz, hl
	ld wa, (0x025b3e:24)
	sla wa, 2
	lda xbc, (0x025b40:24)
	ld	xwa, (xbc+wa)
	call GetCharHeight
	add hl, iz
	exts xhl
	divs hl, 0x4
	inc 1, hl
	lda xwa, (xsp + 2)
	lda xde, (xwa + 2)
	ld bc, (xde)
	add bc, hl
	ld (xde), bc
	cp bc, 0x3c
	jr ge, FDemoText_FindCursor_NotFound
	ldw iy, 0xffff
	ld iz, (xwa)
	lda xix, (0x0251da:24)
	muls bc, 0x28
	ld hl, bc
	cp iz, 0:i3
	jr le, FDemoText_FindCursor_LeftDone
	ld bc, iz
	ld de, hl
	add de, bc

FDemoText_FindCursor_SearchLeft:
	dec 1, iz
	dec 1, de
	cp	(xix+de), 0x54
	jr nz, FDemoText_FindCursor_LeftDone
	ld iy, iz
	cp iz, 0:i3
	jr gt, FDemoText_FindCursor_SearchLeft

FDemoText_FindCursor_LeftDone:
	cp iy, 0xffff
	jr nz, FDemoText_FindCursor_StoreResult
	cp iz, 0x28
	jr ge, FDemoText_FindCursor_StoreResult

FDemoText_FindCursor_SearchRight:
	ld bc, hl
	add bc, iz
	cp	(xix+bc), 0x54
	jr nz, FDemoText_FindCursor_RightNext
	ld iy, iz
	jr FDemoText_FindCursor_StoreResult

FDemoText_FindCursor_RightNext:
	inc 1, iz
	cp iz, 0x28
	jr lt, FDemoText_FindCursor_SearchRight

FDemoText_FindCursor_StoreResult:
	cp iy, 0xffff
	jr z, FDemoText_FindCursor_NotFound
	ld (xwa), iy
	ld xbc, 0x25b3a
	calr FDemoText_ScaleUpCoords
	ld hl, 1:i3
	jr FDemoText_FindCursor_Return

FDemoText_FindCursor_NotFound:
	ld hl, 0:i3

FDemoText_FindCursor_Return:
	popw iz
	inc 4, xsp
	ret

FDemoText_RenderTextLine:
	lda xsp, (xsp - 32)
	push xiz
	ld (xsp + 32), xwa
	ld xiy, FDemoText_ScreenClipRect
	lda xix, (xsp + 24)
	ld bc, 4:i3
	ldirw
	ld wa, (0x025b3e:24)
	sla wa, 2
	lda xbc, (0x025b40:24)
	ld	xwa, (xbc+wa)
	call GetCharHeight
	ld iz, hl
	ld wa, (0x025b3e:24)
	sla wa, 2
	lda xbc, (0x025b40:24)
	ld	xwa, (xbc+wa)
	call GetCharDescent
	sub iz, hl
	lda xde, (0x025b3c:24)
	ld bc, (xde)
	ld wa, bc
	sub wa, iz
	jr ge, FDemoText_Layout_Setup
	neg wa
	inc 3, wa
	exts xwa
	divs wa, 0x4
	sla wa, 2
	add bc, wa
	ld (xde), bc

FDemoText_Layout_Setup:
	ld xiy, 0x25b3a
	lda xix, (xsp + 20)
	ldiw
	ldiw
	sub (xsp + 22), iz
	ld xwa, (xsp + 32)
	push xwa
	call Strlen
	ldfr_werp HL, 0xfa
	ldto_werp WA, 0xfa
	inc 1, wa
	pushw wa
	call Malloc
	ld (xsp + 22), xhl
	ld xwa, (xsp + 38)
	push xwa
	ld xwa, (xsp + 26)
	push xwa
	call Strcpy
	lda xsp, (xsp + 14)
	ld xwa, (xsp + 16)
	ld (xsp + 6), xwa
	lda xwa, (xsp + 20)
	calr FDemoText_CalcTextExtent
	ld (xsp + 4), hl
	ld wa, (0x025b3e:24)
	sla wa, 2
	lda xbc, (0x025b40:24)
	ld	xbc, (xbc+wa)
	ld xwa, (xsp + 16)
	ld de, (xsp + 4)
	call WordwrapStrings
	ld iz, hl
	cpw_erp IZ, 0xfa
	jr z, FDemoText_Layout_NoWrap
	ldw (xsp + 14), 0x1
	ld xwa, (xsp + 16)
	lda	xwa, (xwa+iz)
	ld (xsp + 10), xwa
	ld xwa, 1:i3
	sub (xsp + 10), xwa
	cp iz, 0:i3
	jr z, FDemoText_Layout_ProcessLine
	ld xwa, (xsp + 10)
	ld (xwa), 0x0
	jr FDemoText_Layout_ProcessLine

FDemoText_Layout_NoWrap:
	ldw (xsp + 14), 0x0

FDemoText_Layout_ProcessLine:
	ld wa, (0x025b3e:24)
	sla wa, 2
	lda xbc, (0x025b40:24)
	ld	xbc, (xbc+wa)
	ld xwa, (xsp + 6)
	call CalcTotalWidth
	ld (xsp + 8), hl
	cp iz, 0:i3
	jr z, FDemoText_Layout_UpdatePosition
	lda xbc, (0x025b74:24)
	ld wa, (0x025b72:24)
	ld	a, (xbc+wa)
	lda xbc, (xsp + 20)
	cp a, 2:i3
	jr z, FDemoText_Layout_AlignRight
	cp a, 1:i3
	jr z, FDemoText_Layout_DrawText
	cp a, 0:i3
	jr nz, FDemoText_Layout_DrawText
	ld de, (xsp + 4)
	exts xde
	divs de, 0x2
	add de, (xbc)
	ld wa, (xsp + 8)
	exts xwa
	divs wa, 0x2
	sub de, wa
	ld (xbc), de
	jr FDemoText_Layout_DrawText

FDemoText_Layout_AlignRight:
	ld wa, (xbc)
	add wa, (xsp + 4)
	sub wa, (xsp + 8)
	ld (xbc), wa

FDemoText_Layout_DrawText:
	lda xwa, (xsp + 24)
	lda xbc, (xsp + 20)
	ld de, (0x025b3e:24)
	sla de, 2
	lda xhl, (0x025b40:24)
	ld	xde, (xhl+de)
	push xde
	ld de, (0x025b60:24)
	sla de, 1
	lda xhl, (0x025b62:24)
	pushw	(xhl+de)
	pushw 0xf7
	ld xde, (xsp + 24)
	call DrawString

FDemoText_Layout_UpdatePosition:
	ld wa, (xsp + 20)
	add wa, (xsp + 8)
	ld (0x025b3a:24), wa
	cpw (xsp + 14), 0x0
	jr z, FDemoText_Layout_FreeBuffer
	calr FDemoText_UpdateCursorPosition
	cp hl, 0:i3
	jr z, FDemoText_Layout_FreeBuffer
	ld xwa, (xsp + 10)
	inc 1, xwa
	calr FDemoText_RenderTextLine

FDemoText_Layout_FreeBuffer:
	ld xwa, (xsp + 16)
	push xwa
	call Free
	inc 4, xsp
	pop xiz
	lda xsp, (xsp + 32)
	ret

FDemoText_ByteData_LayoutB:
	lda	xsp, (xsp-14)
	pushw	iz
	ld	(xsp+12), xwa
	ld	wa, (0x025b3e:24)
	sla	wa, 2
	lda	xbc, (0x025b40:24)
	ld	xwa, (xbc+wa)
	call	GetCharHeight
	ld	iz, hl
	ld	wa, (0x025b3e:24)
	sla	wa, 2
	lda	xbc, (0x025b40:24)
	ld	xwa, (xbc+wa)
	call	GetCharDescent
	sub	iz, hl
	lda	xde, (0x025b3c:24)
	ld	bc, (xde)
	ld	wa, bc
	sub	wa, iz
	jr	ge, FDemoText_ByteData_LayoutB_Skip
	neg	wa
	inc	3, wa
	exts	xwa
	divs	wa, 4
	sla	wa, 2
	add	bc, wa
	ld	(xde), bc
FDemoText_ByteData_LayoutB_Skip:
	ld	xwa, (xsp+12)
	calr	FDemo_LinkedListSearchInsert
	ld	(xsp+4), xhl
	ld	xwa, (xsp+4)
	or	xwa, xwa
	jr	z, FDemoText_RenderTextLine_Skip
	ld	xwa, (xwa+16)
	lda	xwa, (xwa+14)
	ld	xwa, (xwa+4)
	ld	(xsp+2), wa
	jr	FDemoText_RenderTextLine_Join
FDemoText_RenderTextLine_Skip:
	ldw	(xsp+2), 24
FDemoText_RenderTextLine_Join:
	ld	xiy, 0x025b3a
	lda	xix, (xsp+8)
	ldiw
	ldiw
	lda	xwa, (xsp+8)
	sub	(xwa+2), iz
	calr	FDemoText_CalcTextExtent
	lda	xbc, (0x025b74:24)
	ld	wa, (0x025b72:24)
	ld	a, (xbc+wa)
	lda xbc, (xsp+8)
	cp a, 2:i3
	jr z, FDemoText_RenderTextLine_Skip2
	cp	a, 1:i3
	jr	z, FDemoText_RenderTextLine_Join2
	cp	a, 0:i3
	jr	nz, FDemoText_RenderTextLine_Join2
	exts	xhl
	divs	hl, 2
	add	hl, (xbc)
	ld	wa, (xsp+2)
	exts	xwa
	divs	wa, 2
	sub	hl, wa
	ld	(xbc), hl
	jr	FDemoText_RenderTextLine_Join2
FDemoText_RenderTextLine_Skip2:
	ld	wa, (xbc)
	add	wa, hl
	sub	wa, (xsp+0x2)
	ld	(xbc), wa
FDemoText_RenderTextLine_Join2:
	ld	xbc, (xsp+4)
	or	xbc, xbc
	jr	z, FDemoText_RenderTextLine_Skip3
	lda	xwa, (xsp+8)
	ld	xbc, (xbc+16)
	call	DrawBitmapFile
	jr	FDemoText_RenderTextLine_Join3
FDemoText_RenderTextLine_Skip3:
	lda	xwa, (xsp+8)
	ld	xbc, 0:i3
	call	DrawBitmap
FDemoText_RenderTextLine_Join3:
	ld	wa, (xsp+8)
	add	wa, (xsp+2)
	ld	(0x025b3a:24), wa
	popw	iz
	lda	xsp, (xsp+14)
	ret

Seq_InitVoiceStructures:
	push xiz
	ld iz, wa
	ldw (0x025b7c:24), 0x0000
	lda xwa, (0x0248c8:24)
	ld (xwa), 0x0
	ld (0x0248c4:24), xwa
	ld (0x0249c8:24), xwa
	ldiw_erp 0xfa, 0

Seq_InitVoiceLoop:
	pushw Seq_InitVoiceStructures_Str_Empty@hi16
	pushw Seq_InitVoiceStructures_Str_Empty@lo16
	ldto_werp BC, 0xfa
	muls bc, 0x18
	lda xwa, (0x0249d8:24)
	lda	xwa, (xwa+bc)
	push xwa
	call Strcpy
	inc 8, xsp
	ldto_werp WA, 0xfa
	muls wa, 0x18
	lda xbc, (0x0249d8:24)
	lda	xde, (xbc+wa)
	ld xwa, 0:i3
	ld (xde + 16), xwa
	ldto_werp WA, 0xfa
	muls wa, 0x18
	lda	xbc, (xbc+wa)
	ld xwa, 0:i3
	ld (xbc + 20), xwa
	inc1w_erp 0xfa
	cp_erpw 0xfa, 0x40, 0x00
	jr lt, Seq_InitVoiceLoop
	ld (0x025b82:24), iz
	pop xiz
	ret

Seq_PostProcessDisplay:
	ld	wa, (0x025b82:24)
	jr	Seq_CopyResourcePtrs

Seq_CopyResourcePtrs:
	lda xde, (0x024fd8:24)
	lda xhl, (Seq_CopyResourcePtrs_Data:24)
	ld xbc, xde
	lda xde, (xde+508)

Seq_CopyPtrLoop:
	ld (xbc+), XHL
	cp xbc, xde
	jr ule, Seq_CopyPtrLoop
	cp wa, 0x12
	jr lt, Seq_UseFallbackAddr
	cp wa, 0x12
	jr gt, Seq_UseFallbackAddr
	sub wa, 0x12
	exts xwa
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	sll xbc, 2
	add xbc, 0x880000
	ld xwa, (xbc + 4)
	ld (0x0249cc:24), xwa
	jr Seq_StoreResultAddr

Seq_UseFallbackAddr:
	ld xwa, (0x0249d0:24)
	ld (0x0249cc:24), xwa

Seq_StoreResultAddr:
	ld xwa, (0x0249cc:24)
	ld (0x0249d4:24), xwa
	ret

Seq_InitializeAndStart:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xwa
	ldw (0x0251d8:24), 0x0001
	ld wa, 0:i3
	calr Seq_InitVoiceStructures
	ld xwa, (xsp + 4)
	push xwa
	call Strlen
	inc 1, hl
	pushw hl
	call Malloc
	ld xiz, xhl
	ld xwa, (xsp + 10)
	push xwa
	push xiz
	call Strcpy
	lda xsp, (xsp + 14)
	ld xwa, NAKA_MAINFUNC_MainPreControl
	ld xbc, EVT_READ_PRESENTATION_REQ
	ld xde, xiz
	call MainFuncCall
	ld xwa, NAKA_MAINFUNC_MainAutoFree
	ld xbc, EVT_AUTO_FREE
	ld xde, xiz
	call MainFuncCall
	pop xiz
	inc 4, xsp
	ret

; =============================================================================
; Display resource loader functions (F86360-F86470)
;
; Function 1 (F86360): Loads a display resource with format validation.
;   Checks state via F89520, validates result (0=error, 1=special, 5=error),
;   configures display resource via F88BC7/F88C48, calls F85310 to render.
;
; Function 2 (F863E4): Loads a named display resource with string parameter.
;   Fills buffer with spaces (0x20), calls FF0FA0 for name lookup,
;   FF0CF3 for format, configures via F88BC7, calls F88EE0/F88F39/F88F10.
; =============================================================================
Seq_LoadDisplayResource:
	lda xsp, (xsp - 32)
	push xiz				; 4 bytes, frame = 36
	ld xiz, xwa				; XIZ = caller arg
	ld xiy, Seq_LoadDisplayResource_NameBufInit			; resource descriptor ptr
	lda xix, (xsp + 4)			; XIX = local buffer
	ldw bc, 0x0010				; 16 bytes to copy
	ldirw					; block copy
	call GetDiskSizeInfo				; get display state
	extz hl					; zero-extend result
	cp hl, 1:i3				; state == 1?
	jr z, Seq_LoadResource_SpecialCase			; special case
	cp hl, 5:i3				; state == 5?
	jr z, Seq_LoadResource_Error			; error
	cp hl, 0:i3				; state == 0?
	jr z, Seq_LoadResource_Error			; error
	call GetEncodedFileSizeData				; validate resource
	cp hl, 0:i3
	jr ge, Seq_LoadResource_Proceed			; valid, proceed
	jr Seq_Epilogue32				; error, cleanup
Seq_LoadResource_Error:
	ldw hl, 0xfff9				; error code -7
	jr Seq_Epilogue32
Seq_LoadResource_SpecialCase:
	ldw hl, 0xfff8				; error code -8
	jr Seq_Epilogue32
Seq_LoadResource_Proceed:
	push xiz				; push resource arg
	lda xwa, (xsp + 8)			; buffer (adjusted for push)
	push xwa
	call Strcat			; format/prepare
	pushw Seq_LoadResource_Proceed_Str_PRE@hi16				; resource ID high
	pushw Seq_LoadResource_Proceed_Str_PRE@lo16				; resource ID low
	lda xwa, (xsp + 16)			; buffer
	push xwa
	call Strcat			; format/prepare
	lda xsp, (xsp + 16)			; clean stack (16 bytes)
	lda xwa, (xsp + 4)			; reload buffer
	ld xbc, Seq_LoadResource_Proceed_Str_rt			; resource descriptor
	call FileIO_OpenWithMode				; open display resource
	cp hl, 0:i3
	jr lt, Seq_Epilogue32			; failed
	pushw Seq_LoadResource_Proceed_Str_PRESENTATION@hi16
	pushw Seq_LoadResource_Proceed_Str_PRESENTATION@lo16
	ld xwa, 0x000248c8			; data source
	ld xbc, 0x00000100			; size 256
	ld xde, Presentation_TagStrTable			; destination descriptor
	calr	Seq_LoadDisplayResource_Helper
	call FileIO_CloseHandle			; finalize
Seq_Epilogue32:
	pop xiz
	lda xsp, (xsp + 32)
	ret

Seq_LoadNamedResource:
	; --- Load named display resource with string fill ---
	lda xsp, (xsp - 32)
	push xiz
	ld xiz, xwa
	lda xbc, (xsp + 4)			; XBC = local buffer
	ld xwa, xbc				; XWA = buffer pointer
	lda xbc, (xbc + 32)			; XBC = end of buffer
Seq_FillBufferLoop:
	ld	(xwa+), 32
	cp xwa, xbc				; reached end?
	jr c, Seq_FillBufferLoop			; no, continue filling
	push xiz				; push name arg
	call Strlen				; name lookup (strlen?)
	pushw hl				; push length
	push xiz				; push name
	lda xwa, (xsp + 14)			; buffer
	push xwa
	call Strncpy				; format string into buffer
	lda xwa, (xsp + 18)			; buffer (adjusted)
	ld (xwa + 8), 0x00			; null-terminate at offset 8
	pushw Seq_FillBufferLoop_Str_ACT@hi16
	pushw Seq_FillBufferLoop_Str_ACT@lo16				; resource ID
	push xwa
	call Strcat			; format/prepare
	lda xsp, (xsp + 22)			; clean stack
	lda xwa, (xsp + 4)
	ld xbc, Seq_FillBufferLoop_Str_rt			; resource descriptor
	call FileIO_OpenWithMode				; open display resource
	cp hl, 0:i3
	jr lt, Seq_NamedResource_Epilogue			; failed
	ld	xwa, 0:i3
	ld	bc, 2:i3
	call FileIO_SeekAndReadBlock				; set region param
	call FileIO_SeekWriteBlock_Impl				; get display info
	ld xiz, xhl				; XIZ = info ptr
	call FileIO_SeekRead_ExtReturn				; additional setup
	ld xwa, xiz
	calr	Seq_LoadNamedResource_Helper
	ld xwa, xhl
	ld (0x0249d0:24), xwa; store result
	pushw Seq_FillBufferLoop_Str_ACTION@hi16
	pushw Seq_FillBufferLoop_Str_ACTION@lo16
	ld xbc, xiz				; info ptr
	ld xde, Seq_FillBufferLoop_Str_ACTION_2			; destination descriptor
	calr	Seq_LoadDisplayResource_Helper
	call FileIO_CloseHandle			; finalize
	cp hl, 0:i3
	jr nz, Seq_NamedResource_Epilogue			; finalize failed
	calr Seq_PostProcessDisplay			; post-processing
	ld	wa, 1:i3
	calr FDemoText_ProcessMarkupLoop			; additional display update
Seq_NamedResource_Epilogue:
	pop xiz
	lda xsp, (xsp + 32)
	ret


FDemoText_ProcessMarkupLoop:
	pushw iz
	ld iz, wa
	ld xwa, (0x0249cc:24)
	ld (0x0249d4:24), xwa
	cp (xwa), 0x0
	jr z, FDemoText_MarkupDone

FDemoText_MarkupLoop:
	ld xwa, (0x0249d4:24)
	ld bc, iz
	calr FDemoText_ProcessTextMarkup
	ld (0x0249d4:24), xhl
	ld xwa, (0x0249d4:24)
	cp (xwa), 0x0
	jr nz, FDemoText_MarkupLoop

FDemoText_MarkupDone:
	ld hl, 0:i3
	popw iz
	ret

