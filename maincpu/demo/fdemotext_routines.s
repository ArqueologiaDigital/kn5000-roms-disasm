; =============================================================================
; Feature Demo Text Processing
; =============================================================================
;
; Text data processing for Feature Demo mode: voice probing,
; flag processing, and formatted output for demo displays.
; =============================================================================

FDemoText:
	cp xbc, 0x1E0009F
	jr nz, FDemoText_ReturnNull
	lda_24 xhl, 0xe9f9c8
	ret

FDemoText_ReturnNull:
	lds32 xhl, 0
	ret

FDemoText_LookupTableEntry:
	extz wa
	sla wa, 2
	ldda32 xbc, 37106
	exts xwa
	add xwa, xbc
	ld xhl, (xwa)
	ret

FDemoText_ByteData_VoiceProbeA:
	ldda8	c, 49277
	ldda8	a, 49280
	extz	wa
	cps	c, 5
	jr	z, 24
	cps	c, 1
	jr	z, 4
	cps	c, 0
	ret	nz
	lda_24	xbc, 15334596
	.byte 0xc3, 0x07, 0xe4, 0xe0, 0x21
	ordm8_24	149486, a
	ret
	calr	-57
	inc	5, xhl
	.byte 0x83, 0x3f, 0x00
	ret	nz
	ldda8	a, 49280
	extz	wa
	lda_24	xbc, 15334596
	.byte 0xc3, 0x07, 0xe4, 0xe0, 0x21
	ordm8_24	149490, a
	ret
FDemoText_ByteData_VoiceProbeB:
	cpdi8	49277, 1
	ret	nz
	ldda8	a, 49279
	res	7, a
	cps	a, 0
	ret	z
	.byte 0xf2, 0xee, 0x47, 0x02, 0xbe
	ret
FDemoText_ByteData_VoiceProbeC:
	ldda8	e, 49280
	sub	e, 68
	ldda8	a, 49277
	extz	wa
	dec	1, wa
	cps	wa, 0
	ret	lt
	cps	wa, 6
	ret	gt
	add	wa, wa
	lda_24	xix, 15334612
	.byte 0xd3, 0x07, 0xf0, 0xe0, 0x20
	lda_24	xix, 16271259
	.byte 0xf3, 0x07, 0xf0, 0xe0, 0xd8, 0xf2, 0xec, 0x47, 0x02, 0xbe
	ret
	ld	xwa, 15334604
	jr	42
	ldda8	a, 49279
	and	a, 15
	jr	z, 19
	ld	a, e
	extz	wa
	lda_24	xbc, 15334604
	.byte 0xc3, 0x07, 0xe4, 0xe0, 0x21
	ordm8_24	149484, a
	ldda8	a, 49279
	and	a, 48
	ret	z
	ld	xwa, 15334608
	extz	de
	.byte 0xc3, 0x07, 0xe0, 0xe8, 0x21
	ordm8_24	149484, a
	ret

FDemoText_ProcessVoiceFlags:
	push_werp 0xFA
	ldda8 a, 36166
	bit 6, a
	jr z, FDemoText_ProcessVoiceFlags_ReadState
	setda_24 6, 149486
	ldda8 a, 36166
	res 6, a
	stda8 36166, a

FDemoText_ProcessVoiceFlags_ReadState:
	call Boot_CheckConfigFlag7
	cps hl, 0
	jrl z, FDemoText_ProcessOutput_ClearAll
	ld8_24 a, 0x0247ee
	bit 6, a
	jr z, FDemoText_ProcessVoiceFlags_CheckBits
	set 7, a
	res 6, a
	st8_24 0x0247ee, a
	pushw 0x0
	ldw wa, 0x44
	ldw bc, 0x8
	lds de, 0
	call AddswbWr
	jrl FDemoText_ProcessVoiceFlags_Return

FDemoText_ProcessVoiceFlags_CheckBits:
	and a, 0x7
	call_24 nz, 0xF84FC3
	bitda_24 7, 149486
	jr z, FDemoText_ProcessChannels
	sti8_24 0x0247f2, 0x00
	ldi_berp 0xFB, 0

FDemoText_ProbeVoice_Loop:
	ldto_berp A, 0xFB
	extz wa
	lda_24 xbc, 0xe9fcc8
	ld_srib3 C, 0x07, 0xE4, 0xE0
	ldfr_berp C, 0xFA
	calr FDemoText_CheckVoiceState
	cps l, 1
	jr z, FDemoText_ProbeVoice_SetActive
	ldto_berp A, 0xFA
	cpl a
	anddm8_24 149486, a
	jr FDemoText_ProbeVoice_ClearActive

FDemoText_ProbeVoice_SetActive:
	ldto_berp A, 0xFA
	ordm8_24 149486, a

FDemoText_ProbeVoice_ClearActive:
	inc1_berp 0xFB
	cpi_berp 0xFB, 2
	jr ule, FDemoText_ProbeVoice_Loop

FDemoText_ProcessChannels:
	ldi_berp 0xFB, 0

FDemoText_ProcessChannels_Loop:
	ldto_berp A, 0xFB
	extz wa
	lda_24 xbc, 0xe9fcc4
	ld_srib3 C, 0x07, 0xE4, 0xE0
	ld8_24 e, 0x0247ee
	and c, e
	jr z, FDemoText_ProcessChannel_CheckMask
	lda_24 xbc, 0xe9fcc8
	ld_srib3 C, 0x07, 0xE4, 0xE0
	and c, e
	jr z, FDemoText_ProcessChannel_CheckNoFlag
	calr FDemoText_CheckVoiceState
	cps l, 1
	jr nz, FDemoText_ProcessChannel_Activate
	ldto_berp A, 0xFB
	extz wa
	calr FDemoText_ActivateVoice
	jr FDemoText_ProcessChannel_CheckMask

FDemoText_ProcessChannel_Activate:
	ldto_berp A, 0xFB
	extz wa
	calr FDemoText_DeactivateVoice
	jr FDemoText_ProcessChannel_CheckMask

FDemoText_ProcessChannel_CheckNoFlag:
	calr FDemoText_CheckVoiceState
	ldto_berp A, 0xFB
	extz wa
	cps l, 1
	jr nz, FDemoText_ProcessChannel_Deactivate
	calr FDemoText_ActivateVoiceAlt
	jr FDemoText_ProcessChannel_CheckMask

FDemoText_ProcessChannel_Deactivate:
	calr FDemoText_DeactivateVoice_RetOnly

FDemoText_ProcessChannel_CheckMask:
	ldto_berp A, 0xFB
	extz wa
	lda_24 xbc, 0xe9fcc4
	ld_srib3 C, 0x07, 0xE4, 0xE0
	andda8_24 c, 149490
	call_24 nz, 0xF84B2C
	inc1_berp 0xFB
	cpi_berp 0xFB, 2
	jr ule, FDemoText_ProcessChannels_Loop
	ldi_berp 0xFB, 0

FDemoText_ProcessOutputChannels:
	lda_24 xhl, 0xe9fcd0
	ld8_24 c, 0x0247ec
	bit 6, c
	jr z, FDemoText_ProcessOutput_CheckFlags
	ldto_berp E, 0xFB
	extz de
	lda_24 xwa, 0xe9fcc8
	ld_srib3 A, 0x07, 0xE0, 0xE8
	andda8_24 a, 149486
	jr z, FDemoText_ProcessOutput_CheckFlags
	or_srib_rm C, 0x07, 0xEC, 0xE8
	st8_24 0x0247ec, c

FDemoText_ProcessOutput_CheckFlags:
	ldto_berp A, 0xFB
	extz wa
	lda_24 xbc, 0xe9fcc8
	ld_srib3 C, 0x07, 0xE4, 0xE0
	andda8_24 c, 149486
	jr z, FDemoText_ProcessOutput_NextCh
	lda_24 xbc, 0xe9fccc
	ld_srib3 C, 0x07, 0xE4, 0xE0
	ld8_24 e, 0x0247ec
	and c, e
	jr z, FDemoText_ProcessOutput_AltUpdate
	calr FDemoText_SendVoiceParams
	jr FDemoText_ProcessOutput_NextCh

FDemoText_ProcessOutput_AltUpdate:
	ld_srib3 C, 0x07, 0xEC, 0xE0
	and c, e
	call_24 nz, 0xF84E3A

FDemoText_ProcessOutput_NextCh:
	inc1_berp 0xFB
	cpi_berp 0xFB, 2
	jr ule, FDemoText_ProcessOutputChannels

FDemoText_ProcessOutput_ClearAll:
	sti8_24 0x0247ec, 0x00
	sti8_24 0x0247f2, 0x00
	anddi8_24 149486, 120

FDemoText_ProcessVoiceFlags_Return:
	pop_werp 0xFA
	ret

FDemoText_ActivateVoice:
	dec 2, xsp
	ld (xsp), a
	ld a, (xsp)
	extz wa
	calr FDemoText_SendVoiceParams
	bitda_24 7, 149486
	jr nz, FDemoText_ActivateVoice_Done
	ld a, (xsp)
	extz wa
	calr FDemoText_SyncVoicePreset

FDemoText_ActivateVoice_Done:
	inc 2, xsp
	ret

FDemoText_DeactivateVoice:
	extz wa
	lda_24 xbc, 0xe9fcc8
	ld_srib3 C, 0x07, 0xE4, 0xE0
	cpl c
	anddm8_24 149486, c
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
	lda_24 xbc, 0xe9fcc8
	ld_srib3 A, 0x07, 0xE4, 0xE0
	ordm8_24 149486, a
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
	pushw 0x7F
	lds bc, 5
	lds de, 0
	call AddswbWr
	lda xwa, (xiz + 2)
	cp (xwa), 0x0
	jr nz, FDemoText_UpdateVoiceDisplay_CheckSend
	ld (xwa), 0x5A
	ld a, (xsp + 4)
	extz wa
	pushw 0x7F
	lds bc, 7
	ldw de, 0x5A
	call AddswbWr

FDemoText_UpdateVoiceDisplay_CheckSend:
	ld8_24 a, 0x0247ee
	and a, 0x38
	jr nz, FDemoText_UpdateVoiceDisplay_Done
	ldda8 c, 64550
	cpdm8 64628, c
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
	push_werp 0xFA
	ld (xsp + 6), a
	ldada xwa, 64628
	ld (xsp + 2), xwa
	ld8_24 a, 0x0247ee
	and a, 0x38
	jr z, FDemoText_SyncPreset_DirectCopy
	ldi_berp 0xFB, 0

FDemoText_SyncPreset_ActiveLoop:
	ldto_berp A, 0xFB
	extz wa
	calr FDemoText_CheckVoiceState
	ldto_berp A, 0xFB
	extz wa
	cps l, 1
	jr nz, FDemoText_SyncPreset_CallUpdate
	ld bc, wa
	lda_24 xde, 0xe9fcc4
	ld_srib3 A, 0x07, 0xE8, 0xE0
	andda8_24 a, 149486
	jr z, FDemoText_SyncPreset_NextActive
	ld wa, bc

FDemoText_SyncPreset_CallUpdate:
	calr FDemoText_UpdateChannelVoice

FDemoText_SyncPreset_NextActive:
	inc1_berp 0xFB
	cpi_berp 0xFB, 2
	jr ule, FDemoText_SyncPreset_ActiveLoop
	jr FDemoText_SyncPreset_Compare

FDemoText_SyncPreset_DirectCopy:
	ld xwa, (xsp + 2)
	ld a, (xwa)
	stda8 64550, a
	ldi_berp 0xFB, 0

FDemoText_SyncPreset_DirectLoop:
	ldto_berp A, 0xFB
	extz wa
	calr FDemoText_UpdateChannelVoice
	inc1_berp 0xFB
	cpi_berp 0xFB, 2
	jr ule, FDemoText_SyncPreset_DirectLoop

FDemoText_SyncPreset_Compare:
	ld a, (xsp + 6)
	extz wa
	lda_24 xbc, 0x0247f4
	ld_srib3 C, 0x07, 0xE4, 0xE0
	ld xwa, (xsp + 2)
	cp c, (xwa)
	jr z, FDemoText_SyncPreset_Return
	extz bc
	ldw wa, 0x61
	calr FDemoText_NotifyUIChange

FDemoText_SyncPreset_Return:
	pop_werp 0xFA
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
	cps l, 1
	jr z, FDemoText_UpdateChannel_Active
	ld (xiz), 0x0
	pushw 0x7F
	lds bc, 5
	lds de, 0
	jr FDemoText_UpdateChannel_SendCmd

FDemoText_UpdateChannel_Active:
	cp (xiz), 0x0
	jr nz, FDemoText_UpdateChannel_Done
	ld (xiz), 0x50
	pushw 0x7F
	lds bc, 5
	ldw de, 0x50
	call AddswbWr
	lda xwa, (xiz + 2)
	cp (xwa), 0x0
	jr z, FDemoText_UpdateChannel_Done
	ld (xwa), 0x0
	ld a, (xsp + 4)
	extz wa
	pushw 0x7F
	lds bc, 7
	lds de, 0

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
	cps l, 1
	jr nz, FDemoText_CheckTimer_Done
	cp (xiz), 0x0
	jr nz, FDemoText_CheckTimer_Done
	lda xwa, (xiz + 2)
	cp (xwa), 0x0
	jr nz, FDemoText_CheckTimer_Done
	ld (xwa), 0x5A
	ld a, (xsp + 4)
	extz wa
	pushw 0x7F
	lds bc, 7
	ldw de, 0x5A
	call AddswbWr

FDemoText_CheckTimer_Done:
	pop xiz
	inc 2, xsp
	ret

FDemoText_ParseControlMessage:
	lda_24 xbc, 0x020c33
	ld a, (xbc + 1)
	cpda8 a, 36154
	ret nz
	cpdi8 36152, 234
	ret nz
	ld a, (xbc)
	cp a, 0x83
	jr z, FDemoText_ParseCtrl_SecondHalf
	cp a, 0x82
	ret nz
	ld e, (xbc + 2)
	ld c, (xbc + 7)
	and c, 0xF
	extz bc
	cp e, 0x82
	jr z, FDemoText_ParseCtrl_Type82
	cps e, 2
	jr nz, FDemoText_ParseCtrl_SecondHalf
	lds wa, 6
	call DemoMenu_BuildItemWorkspace
	ld8_24 a, 0x020c39
	srl a, 4
	and a, 0xF
	ld c, a
	extz bc
	lds wa, 2
	call DemoMenu_BuildItemWorkspace
	ld8_24 c, 0x020c39
	and c, 0xF
	extz bc
	lds wa, 0
	jr FDemoText_ParseCtrl_BuildWorkspace

FDemoText_ParseCtrl_Type82:
	ldw wa, 0x8
	call DemoMenu_BuildItemWorkspace
	ld8_24 a, 0x020c39
	srl a, 4
	and a, 0xF
	ld c, a
	extz bc
	lds wa, 5
	call DemoMenu_BuildItemWorkspace
	ld8_24 c, 0x020c39
	and c, 0xF
	extz bc
	lds wa, 3

FDemoText_ParseCtrl_BuildWorkspace:
	call DemoMenu_BuildItemWorkspace

FDemoText_ParseCtrl_SecondHalf:
	lda_24 xwa, 0x020c33
	ld c, (xwa + 2)
	cp c, 0x82
	jr z, FDemoText_ParseCtrl_FormatC3
	cps c, 2
	ret nz
	ld c, (xwa + 7)
	and c, 0xF
	extz bc
	lds wa, 7
	call DemoMenu_BuildItemWorkspace
	ld8_24 a, 0x020c39
	srl a, 4
	and a, 0xF
	ld c, a
	extz bc
	lds wa, 4
	call DemoMenu_BuildItemWorkspace
	ld8_24 c, 0x020c39
	and c, 0xF
	extz bc
	lds wa, 1
	jr FDemoText_ParseCtrl_Finalize

FDemoText_ParseCtrl_FormatC3:
	ld c, (xwa + 6)
	and c, 0x1
	extz bc
	ldw wa, 0xA
	call DemoMenu_BuildItemWorkspace
	ld8_24 a, 0x020c39
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
	ld (xde + 5), 0xEA
	lds wa, 0
	lds bc, 6
	call sendCOMM
	lda xde, (xsp)
	ld (xde + 2), 0x82
	ld (xde + 3), 0x2
	lds wa, 0
	lds bc, 6
	call sendCOMM
	lda xde, (xsp)
	ld (xde), 0x83
	ld (xde + 2), 0x2
	ld (xde + 3), 0x2
	lds wa, 0
	lds bc, 6
	call sendCOMM
	lda xde, (xsp)
	ld (xde + 2), 0x82
	ld (xde + 3), 0x2
	lds wa, 0
	lds bc, 6
	call sendCOMM
	inc 6, xsp
	ret

FDemoText_SendVoiceParams:
	lda xsp, (xsp - 12)
	push_werp 0xFA
	ld (xsp + 12), a
	ld a, (xsp + 12)
	extz wa
	calr FDemoText_ProbeVoiceType
	cp l, 0xC
	jrl nz, FDemoText_SendVoiceParams_Return
	lda xde, (xsp + 6)
	ld (xde), 0xB0
	ld a, (xsp + 12)
	ld (xde + 1), a
	ld (xde + 2), 0x78
	ld (xde + 3), 0x0
	lds wa, 0
	lds bc, 4
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
	lds32 xwa, 1
	add (xsp + 2), xwa
	ldi_erpb 0xFB, 0x0B

FDemoText_SendParams_NoteLoop:
	lda xde, (xsp + 6)
	ldto_berp A, 0xFB
	ld (xde + 2), a
	ld xwa, (xsp + 2)
	ld a, (xwa)
	ld (xde + 4), a
	lds wa, 0
	lds bc, 6
	call sendCOMM
	lds32 xwa, 1
	add (xsp + 2), xwa
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x0C
	jr ule, FDemoText_SendParams_NoteLoop
	ld a, (xsp + 12)
	add a, 0x44
	extz wa
	calr FDemoText_LookupTableEntry
	ld (xsp + 2), xhl
	lds32 xwa, 3
	add (xsp + 2), xwa
	ldi_berp 0xFB, 4

FDemoText_SendParams_LevelLoop:
	lda xde, (xsp + 6)
	ldto_berp A, 0xFB
	ld (xde + 2), a
	ld xwa, (xsp + 2)
	ld a, (xwa)
	ld (xde + 4), a
	lds wa, 0
	lds bc, 6
	call sendCOMM
	lds32 xwa, 1
	add (xsp + 2), xwa
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x08
	jr ule, FDemoText_SendParams_LevelLoop
	ld c, (xsp + 12)
	extz bc
	ldw wa, 0xFF
	call VoiceEvent_FlushAndReturn

FDemoText_SendVoiceParams_Return:
	pop_werp 0xFA
	lda xsp, (xsp + 12)
	ret

FDemoText_SendExtVoiceParams:
	lda xsp, (xsp - 22)
	push_werp 0xFA
	ld (xsp + 22), a
	lda xwa, (xsp + 6)
	ld (xsp + 2), xwa
	call DemoDesc_BuildCompactParams
	lda xde, (xsp + 16)
	ld (xde), 0xB0
	ld a, (xsp + 22)
	ld (xde + 1), a
	ld (xde + 2), 0x78
	ld (xde + 3), 0x0
	lds wa, 0
	lds bc, 4
	call sendCOMM
	lda xbc, (xsp + 16)
	ld (xbc), 0x88
	ld a, (xsp + 22)
	ld (xbc + 1), a
	ld (xbc + 3), 0x0
	ld (xbc + 5), 0x0
	ldi_erpb 0xFB, 0x0B

FDemoText_SendExtParams_NoteLoop:
	lda xde, (xsp + 16)
	ldto_berp A, 0xFB
	ld (xde + 2), a
	ld xwa, (xsp + 2)
	ld a, (xwa)
	ld (xde + 4), a
	lds wa, 0
	lds bc, 6
	call sendCOMM
	lds32 xwa, 1
	add (xsp + 2), xwa
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x0C
	jr ule, FDemoText_SendExtParams_NoteLoop
	ldi_berp 0xFB, 4

FDemoText_SendExtParams_LevelLoop:
	lda xde, (xsp + 16)
	ldto_berp A, 0xFB
	ld (xde + 2), a
	ld xwa, (xsp + 2)
	ld a, (xwa)
	ld (xde + 4), a
	lds wa, 0
	lds bc, 6
	call sendCOMM
	lds32 xwa, 1
	add (xsp + 2), xwa
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x08
	jr ule, FDemoText_SendExtParams_LevelLoop
	ld c, (xsp + 22)
	extz bc
	ldw wa, 0xFF
	call VoiceEvent_FlushAndReturn
	pop_werp 0xFA
	lda xsp, (xsp + 22)
	ret

FDemoText_UpdatePartialVoice:
	lda xsp, (xsp - 10)
	push xiz
	ld (xsp + 12), a
	ld a, (xsp + 12)
	extz wa
	calr FDemoText_ProbeVoiceType
	cp l, 0xC
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
	ld (xsp + 4), 0xB

FDemoText_UpdatePartial_NoteLoop:
	lda xde, (xsp + 6)
	ld a, (xsp + 4)
	ld (xde + 2), a
	ld a, (xiz)
	ld (xde + 4), a
	lds wa, 0
	lds bc, 6
	call sendCOMM
	inc 1, xiz
	incm8 1, (xsp + 4)
	cp (xsp + 4), 0xC
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
	lds wa, 0
	lds bc, 6
	call sendCOMM

FDemoText_UpdatePartial_Done:
	pop xiz
	lda xsp, (xsp + 10)
	ret

FDemoText_SendExtParamsAlt:
	lda xsp, (xsp - 22)
	push_werp 0xFA
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
	ldi_erpb 0xFB, 0x0B

FDemoText_SendExtAlt_NoteLoop:
	lda xde, (xsp + 16)
	ldto_berp A, 0xFB
	ld (xde + 2), a
	ld xwa, (xsp + 2)
	ld a, (xwa)
	ld (xde + 4), a
	lds wa, 0
	lds bc, 6
	call sendCOMM
	lds32 xwa, 1
	add (xsp + 2), xwa
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x0C
	jr ule, FDemoText_SendExtAlt_NoteLoop
	lda xde, (xsp + 16)
	ld (xde + 2), 0x8
	ld xwa, (xsp + 2)
	ld a, (xwa + 4)
	ld (xde + 4), a
	lds wa, 0
	lds bc, 6
	call sendCOMM
	pop_werp 0xFA
	lda xsp, (xsp + 22)
	ret

FDemoText_ProbeVoiceType:
	dec 8, xsp
	ld (xsp + 6), a
	ld a, (xsp + 6)
	extz wa
	calr FDemoText_LookupTableEntry
	lda xbc, (xsp)
	ld_spib A, 0xEC
	ld (xbc + 3), a
	ld a, (xhl)
	ld (xbc + 4), a
	ld a, (xsp + 6)
	ld (xbc + 2), a
	ld xwa, xbc
	call SndParam_FetchOscTableEntry
	ld l, (xsp + 256)
	inc 8, xsp
	ret

FDemoText_ByteData_ProbeHelper:
	dec	8, xsp
	ld	(xsp+6), a
	ld	a, (xsp+6)
	extz	wa
	calr	-2147
	lda	xbc, (xsp)
	.byte 0xc5, 0xec, 0x21
	ld	(xbc+3), a
	ld	a, (xhl)
	ld	(xbc+4), a
	ld	a, (xsp+6)
	ld	(xbc+2), a
	ld	xwa, xbc
	call	16705514
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
	cp l, 0xF
	jr z, FDemoText_CheckVoice_TypeF
	cp l, 0xC
	jr z, FDemoText_CheckVoice_Active

FDemoText_CheckVoice_Inactive:
	ldb l, 0x0

FDemoText_CheckVoice_Return:
	inc 2, xsp
	ret

FDemoText_CheckVoice_TypeF:
	ldb l, 0x2
	jr FDemoText_CheckVoice_Return

FDemoText_CheckVoice_MaskedActive:
	ld a, (xsp)
	extz wa
	lda_24 xbc, 0xe9fcc8
	ld_srib3 A, 0x07, 0xE4, 0xE0
	andda8_24 a, 149488
	jr z, FDemoText_CheckVoice_Inactive

FDemoText_CheckVoice_Active:
	ldb l, 0x1
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
	ld (xde + 5), 0xEA
	lds wa, 0
	lds bc, 6
	call sendCOMM
	lda xde, (xsp + 24)
	ld (xde + 1), 0x1
	lds wa, 0
	lds bc, 6
	call sendCOMM
	lda xde, (xsp + 24)
	ld (xde + 1), 0x2
	lds wa, 0
	lds bc, 6
	call sendCOMM
	ldw (xsp + 6), 0x0
	call SeqBuf_NoteEvent_CheckSongEnd
	cps hl, 0
	jr nz, FDemoText_ScanMIDI_ReadResponse

FDemoText_ScanMIDI_WaitLoop:
	incm 1, (xsp + 6)
	cpw (xsp + 6), 0x2710
	jr ugt, FDemoText_ScanMIDI_ReadResponse
	call SeqBuf_NoteEvent_CheckSongEnd
	cps hl, 0
	jr z, FDemoText_ScanMIDI_WaitLoop

FDemoText_ScanMIDI_ReadResponse:
	call SeqBuf_NoteEvent_CopyPointers
	ld (xsp + 4), 0x0

FDemoText_ScanMIDI_ProcessChannel:
	ldi_erpb 0xFB, 0xFF
	cpw (xsp + 6), 0x2710
	jrl nc, FDemoText_ScanMIDI_UpdateFlags

FDemoText_ScanMIDI_AdvanceTimeout:
	incm 1, (xsp + 6)
	jrl FDemoText_ScanMIDI_ReadNextFrame

FDemoText_ScanMIDI_ReadBytes:
	lds iz, 1
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
	cps iz, 6
	jr nc, FDemoText_ScanMIDI_CheckStatus
	call Seq_RingBuf_ReadSmall
	cps hl, 0
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
	cps hl, 0
	jr ge, FDemoText_ScanMIDI_ExtendResponse

FDemoText_ScanMIDI_ValidateResponse:
	lda xbc, (xsp + 8)
	ld a, (xbc + 3)
	inc 6, a
	extz wa
	cp wa, iz
	jr nz, FDemoText_ScanMIDI_NoMatch
	cp (xbc + 5), 0xEA
	jr nz, FDemoText_ScanMIDI_NoMatch
	ld c, (xbc + 7)
	cp c, 0xF
	jr z, FDemoText_ScanMIDI_SetActive
	cp c, 0x35
	jr z, FDemoText_ScanMIDI_SetActive
	ldi_berp 0xFB, 0

FDemoText_ScanMIDI_LookupActive:
	ld a, (xsp + 4)
	extz wa
	lda_24 xde, 0x0247f4
	lda_dri3 XHL, 0x07, 0xE8, 0xE0

FDemoText_ScanMIDI_NoMatch:
	cp_erpb 0xFB, 0xFF
	jr nz, FDemoText_ScanMIDI_CheckTimeout

FDemoText_ScanMIDI_ReadNextFrame:
	call Seq_RingBuf_ReadSmall
	cps hl, 0
	jrl ge, FDemoText_ScanMIDI_ReadBytes

FDemoText_ScanMIDI_CheckTimeout:
	cp_erpb 0xFB, 0xFF
	jr nz, FDemoText_ScanMIDI_UpdateFlags
	cpw (xsp + 6), 0x2710
	jrl c, FDemoText_ScanMIDI_AdvanceTimeout

FDemoText_ScanMIDI_UpdateFlags:
	ld a, (xsp + 4)
	extz wa
	lda_24 xbc, 0xe9fcc8
	exts xwa
	add xwa, xbc
	cpi_berp 0xFB, 1
	jr nz, FDemoText_ScanMIDI_ClearActive
	ld a, (xwa)
	ordm8_24 149488, a
	jr FDemoText_ScanMIDI_NextChannel

FDemoText_ScanMIDI_SetActive:
	ldi_berp 0xFB, 1
	jr FDemoText_ScanMIDI_LookupActive

FDemoText_ScanMIDI_ClearActive:
	ld a, (xwa)
	cpl a
	anddm8_24 149488, a

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
	push_werp 0xFA
	calr FDemoText_ScanMIDIChannels
	ldi_berp 0xFB, 0

FDemoText_Rescan_Loop:
	ldto_berp A, 0xFB
	extz wa
	lda_24 xbc, 0xe9fcc8
	ld_srib3 C, 0x07, 0xE4, 0xE0
	ldfr_berp C, 0xFA
	calr FDemoText_CheckVoiceState
	cps l, 1
	jr z, FDemoText_Rescan_SetFlag
	ldto_berp A, 0xFA
	cpl a
	anddm8_24 149486, a
	jr FDemoText_Rescan_NextVoice

FDemoText_Rescan_SetFlag:
	ldto_berp A, 0xFA
	ordm8_24 149486, a

FDemoText_Rescan_NextVoice:
	inc1_berp 0xFB
	cpi_berp 0xFB, 2
	jr ule, FDemoText_Rescan_Loop
	ldi_berp 0xFB, 0

FDemoText_Rescan_SendUpdates:
	ldto_berp A, 0xFB
	extz wa
	lda_24 xbc, 0xe9fcc8
	ld_srib3 C, 0x07, 0xE4, 0xE0
	andda8_24 c, 149486
	call_24 nz, 0xF84CBF
	inc1_berp 0xFB
	cpi_berp 0xFB, 2
	jr ule, FDemoText_Rescan_SendUpdates
	pop_werp 0xFA
	ret

FDemoText_NotifyUIChange:
	push xiz
	extz bc
	ld xwa, 0x4900
	call DSPCfg_WriteParamFull
	ldda8 e, 64628
	extz de
	pushw 0xFF
	ldw wa, 0x61
	lds bc, 0
	call AddswbWr
	ld xwa, 0x4904
	call DSPCfg_ReadParam_Map0
	ldfr_werp HL, 0xFA
	lds iz, 0
	cpi_werp 0xFA, 0
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
	cp_werp IZ, 0xFA
	jr c, FDemoText_NotifyUI_Loop

FDemoText_NotifyUI_Done:
	pop xiz
	ret

FDemoText_RefreshFullDisplay:
	ordi8_24 149486, 7
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
	cp	xiz, 4294967295
	jr	nz, 7
	lda_24	xhl, 15334864
	jr	94
	ld	xwa, xiz
	ld	xbc, 31457301
	lds32	xde, 0
	call	16422496
	.byte 0x83, 0x3f, 0x00
	jr	nz, 58
	ld	xwa, xiz
	.byte 0xe8, 0xef, 0x00
	and	xwa, 4095
	extz	xwa
	add	xwa, 27262976
	ld	xbc, 31457301
	lds32	xde, 0
	call	16422496
	ld	xwa, xiz
	ld	qwa, 0
	pushw	wa
	.long LABEL_E90B3B
	.byte 0x0b, 0xd6, 0xfd, 0x0b, 0x02, 0x00, 0x0b, 0xf6, 0x47
	call	16714354
	lda	xsp, (xsp+14)
	jr	13
	push	xhl
	.byte 0x0b, 0x02, 0x00, 0x0b, 0xf6, 0x47
	call	16715597
	inc	8, xsp
	lda_24	xhl, 149494
	pop	xiz
	ret
	.byte 0xf3, 0xfd, 0x78, 0xff, 0x37
	push	xiz
	push	xwa
	lda	xwa, (xsp+16)
	push	xwa
	call	16715597
	inc	8, xsp
	ld	xwa, 255
	ld	(xsp+4), xwa
	ld	xbc, (xsp+4)
	ld	wa, bc
	call	16401023
	extz	xhl
	ld	(xsp+8), xhl
	or	xhl, xhl
	jr	z, 82
	lds32	xiz, 0
	ld	xwa, (xsp+8)
	cp	xwa, 0
	jr	ule, 69
	ld	xbc, xiz
	ld	xwa, (xsp+4)
	.byte 0xe8, 0xee, 0x00
	add	xwa, xbc
	call	16401092
	cps	hl, 0
	jr	z, 42
	ld	xbc, xiz
	.byte 0xaf, 0x04
	.long SeqCh_FeatureDemoCallbackData
	add	xwa, xbc
	calr	-201
	push	xhl
	lda	xwa, (xsp+16)
	push	xwa
	call	16715573
	inc	8, xsp
	cps	hl, 0
	jr	nz, 14
	ld	xbc, xiz
	ld	xwa, (xsp+4)
	.byte 0xe8, 0xee, 0x00
	add	xwa, xbc
	ld	xhl, xwa
	jr	39
	inc	1, xiz
	ld	xwa, xiz
	.byte 0xaf, 0x08, 0xf0
	jr	c, -69
	lds32	xwa, 1
	sub	(xsp+4), xwa
	ld	xwa, (xsp+4)
	cp	xwa, 0
	jr	ge, -116
	.byte 0x40
	.long ErrStr_GetInstanceID
	call	16395937
	ld	xhl, 4294967295
	pop	xiz
	.byte 0xf3, 0xfd, 0x88, 0x00, 0x37
	ret
	lda	xsp, (xsp-22)
	pushw	iz
	ld	(xsp+12), xde
	ld	(xsp+16), xbc
	ld	(xsp+20), xwa
	.byte 0xbf, 0x02, 0x02, 0x01, 0x00
	jr	23
	cp	hl, 60
	jr	nz, 17
	lds	iz, 1
	call	16289020
	cps	hl, 0
	jr	ge, 28
	.byte 0x9f, 0x02, 0x3f, 0x00, 0x00
	jr	z, 8
	call	16289020
	cps	hl, 0
	jr	ge, -31
	.byte 0x9f, 0x02, 0x3f, 0x00, 0x00
	jr	z, 35
	ldw	hl, 65533
	jrl	198
	ld	xbc, (xsp+12)
	.byte 0xc3, 0x07, 0xe4, 0xf8, 0x21
	extz	wa
	cp	wa, hl
	jr	nz, -42
	inc	1, iz
	.byte 0xc3, 0x07, 0xe4, 0xf8, 0x3f, 0x00
	jr	nz, -60
	.byte 0xbf, 0x02, 0x02, 0x00, 0x00
	lds32	xwa, 0
	ld	(xsp+4), xwa
	call	16289020
	cps	hl, 0
	jr	ge, 14
	.byte 0x9f, 0x02, 0x3f, 0x01, 0x00
	jrl	z, 146
	ldw	hl, 65532
	jrl	142
	cp	hl, 13
	jr	z, 41
	cp	hl, 10
	jr	z, 35
	cp	hl, 9
	jr	z, 29
	ld	xwa, (xsp+4)
	ld	(xsp+8), xwa
	ld	xbc, (xsp+20)
	.byte 0xaf, 0x04, 0x81
	ld	a, l
	ld	(xbc), a
	lds32	xwa, 1
	add	(xsp+4), xwa
	ld	xwa, (xsp+4)
	.byte 0xaf, 0x10, 0xf0
	jr	nc, 48
	cp	hl, 60
	jr	nz, -75
	lds	iz, 1
	call	16289020
	cps	hl, 0
	jr	ge, 9
	.byte 0x9f, 0x02, 0x3f, 0x01, 0x00
	jr	z, -84
	jr	-94
	ld	xbc, (xsp+20)
	.byte 0xaf, 0x04, 0x81
	ld	a, l
	ld	(xbc), a
	lds32	xwa, 1
	add	(xsp+4), xwa
	ld	xwa, (xsp+4)
	.byte 0xaf, 0x10, 0xf0
	jr	c, 5
	ldw	hl, 65531
	jr	42
	ld	xbc, (xsp+28)
	.byte 0xc3, 0x07, 0xe4, 0xf8, 0x21
	extz	wa
	cp	wa, hl
	jr	nz, -51
	inc	1, iz
	.byte 0xc3, 0x07, 0xe4, 0xf8, 0x3f, 0x00
	jr	nz, -69
	.byte 0xbf, 0x02, 0x02, 0x01, 0x00
	ld	xwa, (xsp+20)
	.byte 0xaf, 0x08, 0x80
	ld	(xwa), 0
	jr	-77
	lds	hl, 0
	popw	iz
	lda	xsp, (xsp+22)
	retd	0x0004

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
	cp (xwa), 0x3C
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
	lda_24 xwa, 0xe9fcf2
	ld_sril3 XWA, 0x07, 0xE0, 0xE4
	push xwa
	call String_Compare
	add xsp, 0xE
	cps hl, 0
	jrl nz, FDemoText_ProcessMarkup_NextTag
	ld bc, (xsp + 16)
	sla bc, 3
	lda_24 xwa, 0xe9fcf6
	ld_sril3 XWA, 0x07, 0xE0, 0xE4
	ld (xsp + 4), xwa
	or xwa, xwa
	jrl z, FDemoText_ProcessMarkup_SkipToEnd
	lds32 xiz, 0
	ld xbc, (xsp + 86)
	jr FDemoText_ProcessMarkup_ScanLoop

FDemoText_ProcessMarkup_ScanTagEnd:
	inc 1, xiz
	inc 1, xbc

FDemoText_ProcessMarkup_ScanLoop:
	ld a, (xbc)
	cps a, 0
	jr z, FDemoText_ProcessMarkup_AllocCopy
	cp a, 0x3E
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
	lds wa, 0
	lda xbc, (xsp + 20)
	ld (xsp + 16), xbc
	ld xde, (xsp + 12)
	ld xbc, (xsp + 16)
	ld (xbc), xde
	lds32 xix, 0
	lds hl, 0
	cp xiz, 0x0
	jr ule, FDemoText_ProcessMarkup_CallHandler

FDemoText_ProcessMarkup_ParseAttrs:
	ld xbc, (xsp + 8)
	st_dri3b A, 0x07, 0xE4, 0xEC
	ld e, (xbc)
	cp e, 0x22
	jr z, FDemoText_ProcessMarkup_ToggleQuote
	cp e, 0x3E
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
	st_dri3l XDE, 0x07, 0xE4, 0xF4
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
	cp_spib_im 0xF8, 0x3E
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
	incm 1, (xsp + 16)

FDemoText_ProcessMarkup_TagTableLoop:
	ld bc, (xsp + 16)
	sla bc, 3
	lda_24 xwa, 0xe9fcf2
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
	cp_spib_im 0xF8, 0x3E
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
	cp (xiz), 0x3E
	jr nz, FDemoText_ProcessMarkup_CheckOpenTag
	inc 1, xiz
	jr FDemoText_ProcessMarkup_CopyAndRender

FDemoText_ProcessMarkup_CheckOpenTag:
	cp (xiz), 0x3C
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
	.byte 0xe8, 0xee, 0x02, 0xaf, 0x0a, 0x80
	ld	xwa, (xwa)
	push	xwa
	call	16715680
	inc	1, hl
	pushw	hl
	call	16715392
	ld	(xsp+8), xhl
	ld	wa, iz
	exts	xwa
	.byte 0xe8, 0xee, 0x02, 0xaf, 0x10, 0x80
	ld	xwa, (xwa)
	push	xwa
	ld	xwa, (xsp+12)
	push	xwa
	call	16715597
	lds	iz, 0
	.byte 0x0b, 0x40, 0x00
	ld	xwa, (xsp+18)
	push	xwa
	ld	xwa, (xsp+26)
	push	xwa
	call	16714995
	lda	xsp, (xsp+24)
	ld	xwa, (xsp+6)
	ld	(xwa+64), 0
	ld	xwa, (xsp+18)
	ld	(xwa), 0
	ld	xwa, (xsp+2)
	.byte 0x80, 0x3f, 0x00
	jr	z, 113
	ld	xde, (xsp+2)
	.byte 0xf3, 0x07, 0xe8, 0xf8, 0x30
	ld	xbc, xwa
	.byte 0x80
	.ascii "?=nU"
	.byte 0xb1, 0x00, 0x00, 0x3a
	.byte 0xaf, 0x0a, 0x20, 0x38, 0x1d, 0x4d, 0x0f, 0xff
	.byte 0xef, 0x60, 0xde, 0x61, 0xaf, 0x02, 0x22, 0xf3
	.byte 0x07, 0xe8, 0xf8, 0x30, 0xe8, 0x89, 0x80, 0x21
	.byte 0xc9, 0xcf, 0x22, 0x6e, 0x27, 0xde, 0x61, 0xf3
	.byte 0x07, 0xe8, 0xf8, 0x30, 0x38, 0xaf, 0x16, 0x20
	.byte 0x38, 0x1d, 0x4d, 0x0f, 0xff, 0xaf, 0x1a, 0x20
	.byte 0x38, 0x1d, 0xa0, 0x0f, 0xff, 0xbf, 0x0c, 0x37
	.byte 0xdb, 0x69, 0xeb, 0x12, 0xaf, 0x12, 0x83, 0xb3
	.byte 0x00, 0x00, 0x68, 0x1a, 0x39, 0xaf, 0x16, 0x20
	.byte 0x38, 0x1d, 0x4d, 0x0f, 0xff, 0xef, 0x60, 0x68
	.byte 0x0d, 0xde, 0x61, 0xaf, 0x02, 0x20, 0xc3, 0x07
	.byte 0xe0, 0xf8, 0x3f, 0x00, 0x6e, 0x8f, 0xaf, 0x02
	.byte 0x20, 0x38, 0x1d, 0xf2, 0x0a, 0xff, 0xef, 0x64
	.byte 0x4e, 0xbf, 0x0c, 0x37, 0x0f, 0x04, 0x00

FDemoText_TextDispatch:
	cps bc, 1
	jr z, FDemoText_TextDispatch_Return
	cps bc, 0
	call_24 z, 0xF85F8C

FDemoText_TextDispatch_Return:
	lds hl, 0
	ret

FDemoText_ByteData_LayoutEngine:
	.byte 0xf3, 0xfd, 0x22, 0xff, 0x37
	push	xiz
	.byte 0xf3, 0xfd, 0xda, 0x00, 0x52
	ld	(xsp+220), xbc
	ld	(xsp+224), wa
	ld	xiy, 15334934
	lda	xix, (xsp+20)
	ldw	bc, 32
	.byte 0x95, 0x11, 0x85, 0x10
	ld	xiy, 15335000
	lda	xix, (xsp+6)
	lds	bc, 6
	.byte 0x95, 0x11, 0x85, 0x10
	lds	iz, 0
	.byte 0xd3, 0xfd, 0xe0, 0x00, 0x3f, 0x00, 0x00
	jr	lt, 123
	.byte 0xf3, 0xfd, 0x98, 0x00, 0x32
	lda	xwa, (xsp+86)
	push	xwa
	ld	wa, iz
	ld	xbc, (xsp+224)
	calr	-325
	ld	qiz, 0
	jr	69
	.byte 0xf3, 0xfd, 0x98, 0x00, 0x30
	push	xwa
	push	xbc
	call	16715573
	inc	8, xsp
	cps	hl, 0
	jr	nz, 49
	ld	wa, qiz
	lda	xbc, (xsp+86)
	.byte 0xd7, 0xfa, 0xda
	jr	z, 27
	cps	wa, 1
	jr	z, 16
	cps	wa, 0
	jr	nz, 30
	push	xbc
	call	16714144
	inc	4, xsp
	ld	(xsp+4), hl
	jr	18
	push	xbc
	lda	xwa, (xsp+10)
	push	xwa
	jr	5
	push	xbc
	lda	xwa, (xsp+24)
	push	xwa
	call	16715597
	inc	8, xsp
	.byte 0xd7, 0xfa, 0x61
	ld	bc, qiz
	.byte 0xd9, 0xec, 0x02
	lda_24	xwa, 15334900
	.byte 0xe3, 0x07, 0xe0, 0xe4, 0x21, 0x81, 0x3f, 0x00
	jr	nz, -90
	inc	1, iz
	cp	iz, (xsp+224)
	.byte 0x62, 0x85
	cpw	(xsp+218), 1
	jrl	z, 225
	.byte 0xd3, 0xfd, 0xda, 0x00, 0x3f, 0x00, 0x00
	jrl	nz, 215
	lda	xbc, (xsp+6)
	.byte 0x81, 0x3f, 0x00
	jrl	z, 206
	ld	wa, (xsp+4)
	dec	1, wa
	st16_24	149622, wa
	push	xbc
	.byte 0x0b, 0xe9, 0x00, 0x0b, 0x66, 0xfe, 0x0b, 0x02, 0x00, 0x0b, 0x78, 0x48
	call	16714354
	lda	xwa, (xsp+18)
	push	xwa
	.byte 0x0b, 0x02, 0x00, 0x0b, 0x78, 0x48
	call	16715597
	lda	xwa, (xsp+40)
	push	xwa
	.byte 0x0b, 0x02, 0x00, 0x0b, 0x82, 0x48
	call	16715597
	lda	xsp, (xsp+28)
	.byte 0x40
	.long LABEL_E40002
	ld	xbc, 29360130
	lds32	xde, 5
	call	16422496
	.byte 0x40
	.long LABEL_E40005
	ld	xbc, 29360130
	lds32	xde, 5
	call	16422496
	.byte 0x40
	.long LABEL_E40005
	ld	xbc, 29360129
	lds32	xde, 5
	call	16422496
	.byte 0x40
	.long LABEL_E40005
	ld	xbc, 29425669
	ld	xde, 19
	call	16422496
	ld	xwa, 15597590
	ld	xbc, 29360129
	lds32	xde, 0
	call	16422496
	.byte 0x0b, 0x02, 0x00, 0x0b, 0x78, 0x48
	call	16715680
	inc	1, hl
	pushw	hl
	call	16715392
	ld	xiz, xhl
	.byte 0x0b, 0x02, 0x00, 0x0b, 0x78, 0x48
	push	xiz
	call	16715597
	lda	xsp, (xsp+14)
	ld	xwa, 21037056
	ld	xbc, 31522821
	ld	xde, xiz
	call	16403043
	ld	xwa, 20971523
	ld	xbc, 31457315
	ld	xde, xiz
	call	16403043
	lds	hl, 0
	pop	xiz
	.byte 0xf3, 0xfd, 0xde, 0x00, 0x37
	ret
	.byte 0xf3, 0xfd, 0x72, 0xff, 0x37
	push	xiz
	ld	(xsp+138), de
	.byte 0xf3, 0xfd, 0x8c, 0x00, 0x61, 0xf3, 0xfd, 0x90, 0x00, 0x50, 0xbf, 0x04, 0x02, 0x00, 0x00, 0xd3, 0xfd, 0x90, 0x00, 0x3f, 0x00, 0x00
	jrl	lt, 152
	lda	xde, (xsp+72)
	lda	xwa, (xsp+6)
	push	xwa
	ld	wa, (xsp+8)
	ld	xbc, (xsp+144)
	calr	-727
	ld	qiz, 0
	jr	94
	lda	xbc, (xsp+72)
	push	xbc
	push	xwa
	call	16715573
	inc	8, xsp
	cps	hl, 0
	jr	nz, 76
	ld	bc, qiz
	lda	xwa, (xsp+6)
	.byte 0xd7, 0xfa, 0xd9
	jr	z, 15
	cps	bc, 0
	jr	nz, 61
	push	xwa
	call	16714144
	inc	4, xsp
	ld	iz, hl
	jr	50
	.byte 0xc5, 0xe0, 0x23
	cp	c, 82
	jr	z, 29
	cp	c, 67
	jr	z, 19
	cp	c, 76
	jr	nz, 32
	push	xwa
	call	16714144
	inc	4, xsp
	ldw	iz, 64
	sub	iz, hl
	jr	18
	ldw	iz, 64
	jr	13
	push	xwa
	call	16714144
	inc	4, xsp
	ld	iz, hl
	add	iz, 64
	.byte 0xd7, 0xfa, 0x61
	ld	bc, qiz
	.byte 0xd9, 0xec, 0x02
	lda_24	xwa, 15335018
	.byte 0xe3, 0x07, 0xe0, 0xe4, 0x20, 0x80, 0x3f, 0x00
	jr	nz, -115
	incm	1, (xsp+4)
	ld	wa, (xsp+4)
	cp	wa, (xsp+144)
	jrl	le, -152
	cpw	(xsp+138), 2
	.byte 0x66
	.byte 0x5b
	cpw	(xsp+138), 1
	jr	z, 82
	.byte 0xd3, 0xfd, 0x8a, 0x00, 0x3f, 0x00, 0x00
	jr	nz, 103
	calr	1079
	ld	xwa, 4294967295
	ld	xbc, 31457438
	lds32	xde, 1
	call	16422496
	ld	xwa, 14942217
	ld	xbc, 29360129
	lds32	xde, 0
	call	16422496
	ld	xwa, 14942218
	ld	xbc, 29360129
	lds32	xde, 5
	call	16422496
	ld	xwa, 4294967295
	ld	xbc, 31457438
	lds32	xde, 0
	call	16422496
	call	16431987
	jr	30
	cps	iz, 0
	jr	lt, 26
	cp	iz, 127
	jr	gt, 20
	ld	bc, iz
	.byte 0xd9, 0xec, 0x02
	lda_24	xde, 151512
	ld32_24	xwa, 149972
	.byte 0xf3, 0x07, 0xe8, 0xe4, 0x60
	lds	hl, 0
	pop	xiz
	.byte 0xf3, 0xfd, 0x8e, 0x00, 0x37
	ret
	cps	de, 1
	jr	z, 5
	cps	de, 0
	scc16	z, hl
	ret
	lds	hl, 0
	ret
	cps	de, 1
	jr	z, 7
	cps	de, 0
	.byte 0xf2, 0xca, 0x5e, 0xf8, 0xe6
	lds	hl, 0
	ret
	cps	de, 1
	jr	z, 36
	cps	de, 0
	jr	nz, 32
	calr	1161
	ld16_24	wa, 154482
	inc	1, wa
	st16_24	154482, wa
	cp	wa, 8
	jr	ge, 11
	lda_24	xbc, 154484
	.byte 0xf3
	.long ToneGen_ParamTable
	nop
	lds	hl, 0
	ret
	cps	de, 1
	jr	z, 46
	cps	de, 0
	jr	nz, 42
	calr	1118
	ld16_24	wa, 154482
	dec	1, wa
	st16_24	154482, wa
	cps	wa, 0
	jr	ge, 7
	sti16_24	154482, 0
	lda_24	xbc, 154484
	ld16_24	wa, 154482
	.byte 0xf3, 0x07, 0xe4, 0xe0, 0x00, 0x01
	lds	hl, 0
	ret
	.byte 0xf3, 0xfd, 0x6e, 0xff, 0x37
	push	xiz
	ld	(xsp+142), de
	ld	(xsp+144), xbc
	.byte 0xf3, 0xfd, 0x94, 0x00, 0x50
	ld16_24	wa, 154430
	.byte 0xd8, 0xec, 0x02
	lda_24	xbc, 154432
	.byte 0xe3, 0x07, 0xe4, 0xe0, 0x20
	ld	(xsp+4), xwa
	ld16_24	wa, 154464
	.byte 0xd8, 0xec, 0x01
	lda_24	xbc, 154466
	.byte 0xd3, 0x07, 0xe4, 0xe0, 0x20
	ld	(xsp+8), wa
	lds	iz, 0
	.byte 0xd3, 0xfd, 0x94, 0x00, 0x3f, 0x00, 0x00
	jrl	lt, 141
	lda	xde, (xsp+76)
	lda	xwa, (xsp+10)
	push	xwa
	ld	wa, iz
	ld	xbc, (xsp+148)
	calr	-1214
	ld	qiz, 0
	jr	88
	lda	xbc, (xsp+76)
	push	xbc
	push	xwa
	call	16715573
	inc	8, xsp
	cps	hl, 0
	jr	nz, 70
	ld	bc, qiz
	lda	xwa, (xsp+10)
	.byte 0xd7, 0xfa, 0xd9
	jr	z, 39
	cps	bc, 0
	jr	nz, 55
	push	xwa
	call	16714144
	inc	4, xsp
	cps	hl, 0
	jr	lt, 44
	cp	hl, 9
	jr	gt, 38
	.byte 0xdb, 0xec, 0x02
	lda_24	xwa, 15335066
	.byte 0xe3, 0x07, 0xe0, 0xec, 0x20
	ld	(xsp+4), xwa
	jr	20
	push	xwa
	call	16714144
	inc	4, xsp
	cps	hl, 0
	jr	lt, 9
	cp	hl, 255
	jr	gt, 3
	ld	(xsp+8), hl
	.byte 0xd7, 0xfa, 0x61
	ld	bc, qiz
	.byte 0xd9, 0xec, 0x02
	lda_24	xwa, 15335040
	.byte 0xe3, 0x07, 0xe0, 0xe4, 0x20, 0x80, 0x3f, 0x00
	jr	nz, -109
	inc	1, iz
	.byte 0xd3, 0xfd, 0x94, 0x00, 0xf6
	jrl	le, -141
	.byte 0xd3, 0xfd, 0x8e, 0x00, 0x3f, 0x01, 0x00
	jr	z, 76
	.byte 0xd3, 0xfd, 0x8e, 0x00, 0x3f, 0x00, 0x00
	jr	nz, 67
	ld16_24	bc, 154430
	inc	1, bc
	st16_24	154430, bc
	ld16_24	wa, 154464
	inc	1, wa
	st16_24	154464, wa
	cp	bc, 8
	jr	ge, 37
	.byte 0xd9, 0xec, 0x02
	lda_24	xde, 154432
	ld	xwa, (xsp+4)
	.byte 0xf3, 0x07, 0xe8, 0xe4, 0x60
	ld16_24	bc, 154464
	.byte 0xd9, 0xec, 0x01
	lda_24	xde, 154466
	ld	wa, (xsp+8)
	.byte 0xf3, 0x07, 0xe8, 0xe4, 0x50
	lds	hl, 0
	pop	xiz
	.byte 0xf3, 0xfd, 0x92, 0x00, 0x37
	ret
	cps	de, 1
	jr	z, 79
	cps	de, 0
	jr	nz, 75
	ld16_24	wa, 154430
	dec	1, wa
	st16_24	154430, wa
	decdi16_24	1, 154464
	cps	wa, 0
	jr	ge, 14
	sti16_24	154430, 0
	sti16_24	154464, 0
	ld16_24	bc, 154430
	.byte 0xd9, 0xec, 0x02
	lda_24	xde, 154432
	lds32	xwa, 5
	.byte 0xf3, 0x07, 0xe8, 0xe4, 0x60
	ld16_24	wa, 154464
	.byte 0xd8, 0xec, 0x01
	lda_24	xbc, 154466
	.byte 0xf3, 0x07, 0xe4, 0xe0, 0x02, 0xff, 0x00
	lds	hl, 0
	ret
	.byte 0xf3, 0xfd, 0xf0, 0xfe, 0x37
	push	xiz
	.byte 0xf3, 0xfd, 0x0c, 0x01, 0x52, 0xf3, 0xfd, 0x0e, 0x01, 0x61
	ld	(xsp+274), wa
	ld	xiy, 15335208
	.byte 0xbf
	.asciz "F41 "
	.byte 0x95, 0x11, 0x85, 0x10, 0x45, 0x6a, 0xff
	.byte 0xe9, 0x00, 0xbf, 0x04, 0x34, 0x31, 0x20, 0x00
	.byte 0x95, 0x11, 0x85, 0x10, 0xde, 0xa8, 0xd3, 0xfd
	.byte 0x12, 0x01, 0x3f, 0x00, 0x00, 0x61, 0x7b, 0xf3
	.byte 0xfd, 0xca, 0x00, 0x32, 0xf3, 0xfd, 0x88, 0x00
	.byte 0x30, 0x38, 0xde, 0x88, 0xe3, 0xfd, 0x12, 0x01
	.byte 0x21, 0x1e, 0xbf, 0xf9, 0xd7, 0xfa, 0xa8, 0x68
	.byte 0x43
	lda	xwa, (xsp+202)
	push	xwa
	push	xbc
	call	16715573
	inc	8, xsp
	cps	hl, 0
	jr	nz, 47
	ld	wa, qiz
	cpw	qiz, 8
	jr	gt, 37
	cps	wa, 2
	jr	ge, 33
	lda	xbc, (xsp+136)
	cps	wa, 0
	jr	z, 6
	cps	wa, 1
	jr	z, 9
	jr	18
	push	xbc
	.byte 0xbf
	.ascii "J08h"
	.byte 0x05, 0x39, 0xbf
	.byte 0x08, 0x30, 0x38, 0x1d, 0x4d, 0x0f, 0xff, 0xef
	.byte 0x60, 0xd7, 0xfa, 0x61, 0xd7, 0xfa, 0x89, 0xd9
	.byte 0xec, 0x02, 0xf2, 0xc2, 0xfe, 0xe9, 0x30, 0xe3
	.byte 0x07, 0xe0, 0xe4, 0x21, 0x81, 0x3f, 0x00, 0x6e
	.byte 0xa8, 0xde, 0x61
	cp	iz, (xsp+274)
	.byte 0x62, 0x85, 0xbf, 0x46, 0x31, 0xd3, 0xfd, 0x0c
	.byte 0x01, 0x3f, 0x01, 0x00, 0x66, 0x15, 0xd3, 0xfd
	.byte 0x0c, 0x01, 0x3f, 0x00, 0x00, 0x6e, 0x16, 0xe9
	.byte 0x88, 0x81, 0x3f, 0x00, 0x66, 0x0f, 0x1e, 0x48
	.byte 0x04, 0x68, 0x0a, 0xe9, 0x88, 0x81, 0x3f, 0x00
	.byte 0xf2, 0xfd, 0x68, 0xf8, 0xee, 0xdb, 0xa8, 0x5e
	.byte 0xf3, 0xfd, 0x10, 0x01, 0x37, 0x0e, 0xf3, 0xfd
	.byte 0x32, 0xff, 0x37, 0x3e, 0xf3, 0xfd, 0xca, 0x00
	.byte 0x52
	ld	(xsp+204), xbc
	.byte 0xf3, 0xfd, 0xd0, 0x00, 0x50
	ld	xiy, 15335354
	lda	xix, (xsp+4)
	ldw	bc, 32
	.byte 0x95, 0x11, 0x85, 0x10
	lds	iz, 0
	.byte 0xd3, 0xfd, 0xd0, 0x00, 0x3f, 0x00, 0x00
	jr	lt, 93
	.byte 0xf3, 0xfd, 0x88, 0x00, 0x32
	lda	xwa, (xsp+70)
	push	xwa
	ld	wa, iz
	ld	xbc, (xsp+208)
	calr	-1821
	ld	qiz, 0
	jr	39
	.byte 0xf3, 0xfd, 0x88, 0x00, 0x30
	push	xwa
	push	xbc
	call	16715573
	inc	8, xsp
	cps	hl, 0
	jr	nz, 19
	cp	qiz, 0
	jr	nz, 14
	lda	xwa, (xsp+70)
	push	xwa
	lda	xwa, (xsp+8)
	push	xwa
	call	16715597
	inc	8, xsp
	.byte 0xd7, 0xfa, 0x61
	ld	bc, qiz
	.byte 0xd9, 0xec, 0x02
	lda_24	xwa, 15335340
	.byte 0xe3, 0x07, 0xe0, 0xe4, 0x21, 0x81, 0x3f, 0x00
	jr	nz, -60
	inc	1, iz
	cp	iz, (xsp+208)
	jr	le, -93
	.byte 0xd3, 0xfd, 0xca, 0x00, 0x3f, 0x01, 0x00
	jr	z, 57
	.byte 0xd3, 0xfd, 0xca, 0x00, 0x3f, 0x00, 0x00
	jr	nz, 48
	lda	xwa, (xsp+4)
	.byte 0x80, 0x3f, 0x00
	jr	z, 40
	calr	-2890
	ld	xwa, xhl
	cp	xwa, 4294967295
	jr	z, 27
	ld	xbc, 29360129
	lds32	xde, 0
	call	16422496
	ld	xwa, 14942218
	ld	xbc, 29360129
	lds32	xde, 5
	call	16422496
	lds	hl, 0
	pop	xiz
	.byte 0xf3, 0xfd, 0xce, 0x00, 0x37
	ret
	lda_24	xbc, 152026
	ld	xwa, xbc
	.byte 0xf3, 0xe5, 0x60, 0x09, 0x31
	ld	xde, xwa
	lda	xhl, (xwa+40)
	.byte 0xf5, 0xe8, 0x00, 0x54
	cp	xde, xhl
	jr	c, -8
	lda	xwa, (xwa+40)
	cp	xwa, xbc
	jr	c, -20
	lda_24	xwa, 154426
	.byte 0xb0, 0x02, 0x00, 0x00, 0xb8, 0x02, 0x02, 0x00, 0x00
	sti16_24	154430, 0
	sti16_24	154464, 0
	sti16_24	154482, 0
	lda_24	xhl, 154432
	lda_24	xde, 154466
	lda_24	xwa, 154484
	ld	xbc, xwa
	lda	xix, (xwa+8)
	lds32	xwa, 5
	.byte 0xf5, 0xee, 0x60, 0xf5, 0xe9, 0x02, 0xff, 0x00, 0xf5, 0xe4, 0x00, 0x01
	cp	xbc, xix
	jr	c, -18
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
	lda_24 xde, 0x0251da

FDemoText_CalcExtent_ScanLoop:
	ld bc, wa
	add bc, ix
	cp_srib_im 0x07, 0xE8, 0xE4, 0x54
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
	ld xwa, 0x25B3A
	calr FDemoText_ScaleDownCoords
	ld16_24 xwa, 0x025b3e
	sla wa, 2
	lda_24 xbc, 0x025b40
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	call GetCenteredDelta
	ld iz, hl
	ld16_24 xwa, 0x025b3e
	sla wa, 2
	lda_24 xbc, 0x025b40
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
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
	cp bc, 0x3C
	jr ge, FDemoText_FindCursor_NotFound
	ldw iy, 0xFFFF
	ld iz, (xwa)
	lda_24 xix, 0x0251da
	muls bc, 0x28
	ld hl, bc
	cps iz, 0
	jr le, FDemoText_FindCursor_LeftDone
	ld bc, iz
	ld de, hl
	add de, bc

FDemoText_FindCursor_SearchLeft:
	dec 1, iz
	dec 1, de
	cp_srib_im 0x07, 0xF0, 0xE8, 0x54
	jr nz, FDemoText_FindCursor_LeftDone
	ld iy, iz
	cps iz, 0
	jr gt, FDemoText_FindCursor_SearchLeft

FDemoText_FindCursor_LeftDone:
	cp iy, 0xFFFF
	jr nz, FDemoText_FindCursor_StoreResult
	cp iz, 0x28
	jr ge, FDemoText_FindCursor_StoreResult

FDemoText_FindCursor_SearchRight:
	ld bc, hl
	add bc, iz
	cp_srib_im 0x07, 0xF0, 0xE4, 0x54
	jr nz, FDemoText_FindCursor_RightNext
	ld iy, iz
	jr FDemoText_FindCursor_StoreResult

FDemoText_FindCursor_RightNext:
	inc 1, iz
	cp iz, 0x28
	jr lt, FDemoText_FindCursor_SearchRight

FDemoText_FindCursor_StoreResult:
	cp iy, 0xFFFF
	jr z, FDemoText_FindCursor_NotFound
	ld (xwa), iy
	ld xbc, 0x25B3A
	calr FDemoText_ScaleUpCoords
	lds hl, 1
	jr FDemoText_FindCursor_Return

FDemoText_FindCursor_NotFound:
	lds hl, 0

FDemoText_FindCursor_Return:
	popw iz
	inc 4, xsp
	ret

FDemoText_RenderTextLine:
	lda xsp, (xsp - 32)
	push xiz
	ld (xsp + 32), xwa
	ld xiy, 0xE9FFFC
	lda xix, (xsp + 24)
	lds bc, 4
	ldirw
	ld16_24 xwa, 0x025b3e
	sla wa, 2
	lda_24 xbc, 0x025b40
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	call GetCharHeight
	ld iz, hl
	ld16_24 xwa, 0x025b3e
	sla wa, 2
	lda_24 xbc, 0x025b40
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	call GetCharDescent
	sub iz, hl
	lda_24 xde, 0x025b3c
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
	ld xiy, 0x25B3A
	lda xix, (xsp + 20)
	ldiw
	ldiw
	sub (xsp + 22), iz
	ld xwa, (xsp + 32)
	push xwa
	call Strlen
	ldfr_werp HL, 0xFA
	ldto_werp WA, 0xFA
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
	ld16_24 xwa, 0x025b3e
	sla wa, 2
	lda_24 xbc, 0x025b40
	ld_sril3 XBC, 0x07, 0xE4, 0xE0
	ld xwa, (xsp + 16)
	ld de, (xsp + 4)
	call WordwrapStrings
	ld iz, hl
	cp_werp IZ, 0xFA
	jr z, FDemoText_Layout_NoWrap
	ldw (xsp + 14), 0x1
	ld xwa, (xsp + 16)
	st_dri3b W, 0x07, 0xE0, 0xF8
	ld (xsp + 10), xwa
	lds32 xwa, 1
	sub (xsp + 10), xwa
	cps iz, 0
	jr z, FDemoText_Layout_ProcessLine
	ld xwa, (xsp + 10)
	ld (xwa), 0x0
	jr FDemoText_Layout_ProcessLine

FDemoText_Layout_NoWrap:
	ldw (xsp + 14), 0x0

FDemoText_Layout_ProcessLine:
	ld16_24 xwa, 0x025b3e
	sla wa, 2
	lda_24 xbc, 0x025b40
	ld_sril3 XBC, 0x07, 0xE4, 0xE0
	ld xwa, (xsp + 6)
	call CalcTotalWidth
	ld (xsp + 8), hl
	cps iz, 0
	jr z, FDemoText_Layout_UpdatePosition
	lda_24 xbc, 0x025b74
	ld16_24 xwa, 0x025b72
	ld_srib3 A, 0x07, 0xE4, 0xE0
	lda xbc, (xsp + 20)
	cps a, 2
	jr z, FDemoText_Layout_AlignRight
	cps a, 1
	jr z, FDemoText_Layout_DrawText
	cps a, 0
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
	ld16_24 xde, 0x025b3e
	sla de, 2
	lda_24 xhl, 0x025b40
	ld_sril3 XDE, 0x07, 0xEC, 0xE8
	push xde
	ld16_24 xde, 0x025b60
	sla de, 1
	lda_24 xhl, 0x025b62
	push_sriw 0x07, 0xEC, 0xE8
	pushw 0xF7
	ld xde, (xsp + 24)
	call DrawString

FDemoText_Layout_UpdatePosition:
	ld wa, (xsp + 20)
	add wa, (xsp + 8)
	st16_24 0x025b3a, xwa
	cpw (xsp + 14), 0x0
	jr z, FDemoText_Layout_FreeBuffer
	calr FDemoText_UpdateCursorPosition
	cps hl, 0
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
	ld16_24	wa, 154430
	.byte 0xd8, 0xec, 0x02
	lda_24	xbc, 154432
	.byte 0xe3, 0x07, 0xe4, 0xe0, 0x20
	call	16459274
	ld	iz, hl
	ld16_24	wa, 154430
	.byte 0xd8, 0xec, 0x02
	lda_24	xbc, 154432
	.byte 0xe3, 0x07, 0xe4, 0xe0, 0x20
	call	16459287
	sub	iz, hl
	lda_24	xde, 154428
	ld	bc, (xde)
	ld	wa, bc
	sub	wa, iz
	jr	ge, 17
	neg	wa
	inc	3, wa
	exts	xwa
	divs	wa, 4
	.byte 0xd8, 0xec, 0x02
	add	bc, wa
	ld	(xde), bc
	ld	xwa, (xsp+12)
	calr	1742
	ld	(xsp+4), xhl
	ld	xwa, (xsp+4)
	or	xwa, xwa
	jr	z, 14
	ld	xwa, (xwa+16)
	lda	xwa, (xwa+14)
	ld	xwa, (xwa+4)
	ld	(xsp+2), wa
	jr	5
	.byte 0xbf, 0x02, 0x02, 0x18, 0x00
	ld	xiy, 154426
	lda	xix, (xsp+8)
	.byte 0x95, 0x10, 0x95, 0x10
	lda	xwa, (xsp+8)
	sub	(xwa+2), iz
	calr	-853
	lda_24	xbc, 154484
	ld16_24	wa, 154482
	.byte 0xc3, 0x07, 0xe4, 0xe0, 0x21
	lda	xbc, (xsp+8)
	cps	a, 2
	jr	z, 31
	cps	a, 1
	jr	z, 36
	cps	a, 0
	jr	nz, 32
	exts	xhl
	divs	hl, 2
	.byte 0x91, 0x83
	ld	wa, (xsp+2)
	exts	xwa
	divs	wa, 2
	sub	hl, wa
	ld	(xbc), hl
	jr	9
	ld	wa, (xbc)
	add	wa, hl
	.byte 0x9f, 0x02, 0xa0
	ld	(xbc), wa
	ld	xbc, (xsp+4)
	or	xbc, xbc
	jr	z, 12
	lda	xwa, (xsp+8)
	ld	xbc, (xbc+16)
	call	16434839
	jr	9
	lda	xwa, (xsp+8)
	lds32	xbc, 0
	call	16432188
	ld	wa, (xsp+8)
	.byte 0x9f, 0x02, 0x80
	st16_24	154426, wa
	popw	iz
	lda	xsp, (xsp+14)
	ret

Seq_InitVoiceStructures:
	push xiz
	ld iz, wa
	sti16_24 0x025b7c, 0x0000
	lda_24 xwa, 0x0248c8
	ld (xwa), 0x0
	st32_24 0x0248c4, xwa
	st32_24 0x0249c8, xwa
	ldi_werp 0xFA, 0

Seq_InitVoiceLoop:
	pushw 0xEA
	pushw 0x4
	ldto_werp BC, 0xFA
	muls bc, 0x18
	lda_24 xwa, 0x0249d8
	st_dri3b W, 0x07, 0xE0, 0xE4
	push xwa
	call Strcpy
	inc 8, xsp
	ldto_werp WA, 0xFA
	muls wa, 0x18
	lda_24 xbc, 0x0249d8
	st_dri3b B, 0x07, 0xE4, 0xE0
	lds32 xwa, 0
	ld (xde + 16), xwa
	ldto_werp WA, 0xFA
	muls wa, 0x18
	st_dri3b A, 0x07, 0xE4, 0xE0
	lds32 xwa, 0
	ld (xbc + 20), xwa
	inc1_werp 0xFA
	cp_erpw 0xFA, 0x40, 0x00
	jr lt, Seq_InitVoiceLoop
	st16_24 0x025b82, xiz
	pop xiz
	ret

Seq_PostProcessDisplay:
	ld16_24	wa, 154498
	jr	0

Seq_CopyResourcePtrs:
	lda_24 xde, 0x024fd8
	lda_24 xhl, 0xea0006
	ld xbc, xde
	st_dri3b B, 0xE9, 0xFC, 0x01

Seq_CopyPtrLoop:
	st_dpil XHL, 0xE6
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
	st32_24 0x0249cc, xwa
	jr Seq_StoreResultAddr

Seq_UseFallbackAddr:
	ld32_24 xwa, 0x0249d0
	st32_24 0x0249cc, xwa

Seq_StoreResultAddr:
	ld32_24 xwa, 0x0249cc
	st32_24 0x0249d4, xwa
	ret

Seq_InitializeAndStart:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xwa
	sti16_24 0x0251d8, 0x0001
	lds wa, 0
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
	ld xwa, 0x1410000
	ld xbc, 0x1E10003
	ld xde, xiz
	call MainFuncCall
	ld xwa, 0x1400003
	ld xbc, 0x1E00023
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
	ld xiy, 0x00EA0028			; resource descriptor ptr
	lda xix, (xsp + 4)			; XIX = local buffer
	ldw bc, 0x0010				; 16 bytes to copy
	ldirw					; block copy
	call GetDiskSizeInfo				; get display state
	extz hl					; zero-extend result
	cps hl, 1				; state == 1?
	jr z, Seq_LoadResource_SpecialCase			; special case
	cps hl, 5				; state == 5?
	jr z, Seq_LoadResource_Error			; error
	cps hl, 0				; state == 0?
	jr z, Seq_LoadResource_Error			; error
	call GetEncodedFileSizeData				; validate resource
	cps hl, 0
	jr ge, Seq_LoadResource_Proceed			; valid, proceed
	jr Seq_Epilogue32				; error, cleanup
Seq_LoadResource_Error:
	ldw hl, 0xFFF9				; error code -7
	jr Seq_Epilogue32
Seq_LoadResource_SpecialCase:
	ldw hl, 0xFFF8				; error code -8
	jr Seq_Epilogue32
Seq_LoadResource_Proceed:
	push xiz				; push resource arg
	lda xwa, (xsp + 8)			; buffer (adjusted for push)
	push xwa
	call Strcat			; format/prepare
	pushw 0x00EA				; resource ID high
	pushw 0x0048				; resource ID low
	lda xwa, (xsp + 16)			; buffer
	push xwa
	call Strcat			; format/prepare
	lda xsp, (xsp + 16)			; clean stack (16 bytes)
	lda xwa, (xsp + 4)			; reload buffer
	ld xbc, 0x00EA004E			; resource descriptor
	call FileIO_OpenWithMode				; open display resource
	cps hl, 0
	jr lt, Seq_Epilogue32			; failed
	pushw 0x00EA
	pushw 0x0018
	ld xwa, 0x000248C8			; data source
	ld xbc, 0x00000100			; size 256
	ld xde, 0x00EA0008			; destination descriptor
	calr	61237
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
	.byte 0xf5, 0xe0, 0x00, 0x20		; ld (xwa+), 0x20  [auto-inc store, not in LLVM]
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
	pushw 0x00EA
	pushw 0x0066				; resource ID
	push xwa
	call Strcat			; format/prepare
	lda xsp, (xsp + 22)			; clean stack
	lda xwa, (xsp + 4)
	ld xbc, 0x00EA006C			; resource descriptor
	call FileIO_OpenWithMode				; open display resource
	cps hl, 0
	jr lt, Seq_NamedResource_Epilogue			; failed
	lds32	xwa, 0
	lds	bc, 2
	call FileIO_SeekAndReadBlock				; set region param
	call FileIO_SeekWriteBlock_Impl				; get display info
	ld xiz, xhl				; XIZ = info ptr
	call FileIO_SeekRead_ExtReturn				; additional setup
	ld xwa, xiz
	calr	395
	ld xwa, xhl
	st32_24 0x0249D0, xwa			; store result
	pushw 0x00EA
	pushw 0x005C
	ld xbc, xiz				; info ptr
	ld xde, 0x00EA0052			; destination descriptor
	calr	61108
	call FileIO_CloseHandle			; finalize
	cps hl, 0
	jr nz, Seq_NamedResource_Epilogue			; finalize failed
	calr Seq_PostProcessDisplay			; post-processing
	lds	wa, 1
	calr FDemoText_ProcessMarkupLoop			; additional display update
Seq_NamedResource_Epilogue:
	pop xiz
	lda xsp, (xsp + 32)
	ret


FDemoText_ProcessMarkupLoop:
	pushw iz
	ld iz, wa
	ld32_24 xwa, 0x0249cc
	st32_24 0x0249d4, xwa
	cp (xwa), 0x0
	jr z, FDemoText_MarkupDone

FDemoText_MarkupLoop:
	ld32_24 xwa, 0x0249d4
	ld bc, iz
	calr FDemoText_ProcessTextMarkup
	st32_24 0x0249d4, xhl
	ld32_24 xwa, 0x0249d4
	cp (xwa), 0x0
	jr nz, FDemoText_MarkupLoop

FDemoText_MarkupDone:
	lds hl, 0
	popw iz
	ret

