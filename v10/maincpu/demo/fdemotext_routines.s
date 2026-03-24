; =============================================================================
; Feature Demo Text Processing
; =============================================================================
;
; Text data processing for Feature Demo mode: voice probing,
; flag processing, and formatted output for demo displays.
; =============================================================================

FDemoText:
	cp xbc, 0x1e0009f
	jr nz, FDemoText_ReturnNull
	lda_24 xhl, DemoDisk_LangPromptTable
	ret

FDemoText_ReturnNull:
	lds32 xhl, 0
	ret

FDemoText_LookupTableEntry:
	extz wa
	sla wa, 2
	ldda32 xbc, 0x90f2
	exts xwa
	add xwa, xbc
	ld xhl, (xwa)
	ret

FDemoText_ByteData_VoiceProbeA:
	ldda8	c, 0xc07d
	ldda8	a, 0xc080
	extz	wa
	cps	c, 5
	jr	z, 24
	cps	c, 1
	jr	z, 4
	cps	c, 0
	ret	nz
	lda_24	xbc, DemoDiskPrompt_English1_0x86
	.byte 0xc3
	reti
	.byte 0xe4, 0xe0
	ldb	a, 194
	.byte 0xee
	ld	xsp, 0x1e0ee902
	.byte 0xc7
	swi	7
	inc	5, xhl
	cp	(xhl), 0
	ret	nz
	ldda8	a, 0xc080
	extz	wa
	lda_24	xbc, DemoDiskPrompt_English1_0x86
	.byte 0xc3
	reti
	.byte 0xe4, 0xe0
	ldb	a, 194
	.byte 0xf2, 0x47
	push_sr
	.byte 0xe9
	ret
FDemoText_ByteData_VoiceProbeB:
	.byte 0xc1
	jrl	pl, 16320
	.byte 0x01
	ret	nz
	ldda8	a, 0xc07f
	res	7, a
	cps	a, 0
	ret	z
	.byte 0xf2, 0xee, 0x47
	push_sr
	.byte 0xbe
	ret
FDemoText_ByteData_VoiceProbeC:
	ldda8	e, 0xc080
	sub	e, 68
	ldda8	a, 0xc07d
	extz	wa
	dec	1, wa
	cps	wa, 0
	ret	lt
	cps	wa, 6
	ret	gt
	add	wa, wa
	lda_24	xix, DemoDiskPrompt_English1_0x96
	.byte 0xd3
	reti
	.byte 0xf0, 0xe0
	ldb	w, 242
	cp	(xhl+71), wa
	ldw	ix, 2035
	.byte 0xf0, 0xe0
	cp	de, wa
	.byte 0xec
	ld	xsp, 0x400ebe02
	.byte 0xcc
	swi	4
	.byte 0xe9
	nop
	jr	42
	ldda8	a, 0xc07f
	and	a, 15
	jr	z, 19
	ld	a, e
	extz	wa
	lda_24	xbc, DemoDiskPrompt_English1_0x8E
	.byte 0xc3
	reti
	.byte 0xe4, 0xe0
	ldb	a, 194
	.byte 0xec
	ld	xsp, 0x7fc1e902
	.byte 0xc0
	ldb	a, 201
	.byte 0xcc
	ldw	wa, 0xf6b0
	ld	xwa, DemoDiskPrompt_English1_0x92
	extz	de
	.byte 0xc3
	reti
	.byte 0xe0, 0xe8
	ldb	a, 194
	.byte 0xec, 0x47
	push_sr
	.byte 0xe9
	ret

FDemoText_ProcessVoiceFlags:
	push_werp 0xfa
	ldda8 a, 0x8d46
	bit 6, a
	jr z, FDemoText_ProcessVoiceFlags_ReadState
	setda_24 6, 0x0247ee
	ldda8 a, 0x8d46
	res 6, a
	stda8 0x8d46, a

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
	call_24 nz, FDemoText_ScanMIDIChannels
	bitda_24 7, 0x0247ee
	jr z, FDemoText_ProcessChannels
	sti8_24 0x0247f2, 0x00
	ldi_berp 0xfb, 0

FDemoText_ProbeVoice_Loop:
	ldto_berp A, 0xfb
	extz wa
	lda_24 xbc, DemoDiskPrompt_English1_0x8A
	ld_srib3 C, 0x07, 0xe4, 0xe0
	ldfr_berp C, 0xfa
	calr FDemoText_CheckVoiceState
	cps l, 1
	jr z, FDemoText_ProbeVoice_SetActive
	ldto_berp A, 0xfa
	cpl a
	anddm8_24 0x0247ee, a
	jr FDemoText_ProbeVoice_ClearActive

FDemoText_ProbeVoice_SetActive:
	ldto_berp A, 0xfa
	ordm8_24 0x0247ee, a

FDemoText_ProbeVoice_ClearActive:
	inc1_berp 0xfb
	cpi_berp 0xfb, 2
	jr ule, FDemoText_ProbeVoice_Loop

FDemoText_ProcessChannels:
	ldi_berp 0xfb, 0

FDemoText_ProcessChannels_Loop:
	ldto_berp A, 0xfb
	extz wa
	lda_24 xbc, DemoDiskPrompt_English1_0x86
	ld_srib3 C, 0x07, 0xe4, 0xe0
	ld8_24 e, 0x0247ee
	and c, e
	jr z, FDemoText_ProcessChannel_CheckMask
	lda_24 xbc, DemoDiskPrompt_English1_0x8A
	ld_srib3 C, 0x07, 0xe4, 0xe0
	and c, e
	jr z, FDemoText_ProcessChannel_CheckNoFlag
	calr FDemoText_CheckVoiceState
	cps l, 1
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
	cps l, 1
	jr nz, FDemoText_ProcessChannel_Deactivate
	calr FDemoText_ActivateVoiceAlt
	jr FDemoText_ProcessChannel_CheckMask

FDemoText_ProcessChannel_Deactivate:
	calr FDemoText_DeactivateVoice_RetOnly

FDemoText_ProcessChannel_CheckMask:
	ldto_berp A, 0xfb
	extz wa
	lda_24 xbc, DemoDiskPrompt_English1_0x86
	ld_srib3 C, 0x07, 0xe4, 0xe0
	andda8_24 c, 0x0247f2
	call_24 nz, FDemoText_CheckAndSetTimer
	inc1_berp 0xfb
	cpi_berp 0xfb, 2
	jr ule, FDemoText_ProcessChannels_Loop
	ldi_berp 0xfb, 0

FDemoText_ProcessOutputChannels:
	lda_24 xhl, DemoDiskPrompt_English1_0x92
	ld8_24 c, 0x0247ec
	bit 6, c
	jr z, FDemoText_ProcessOutput_CheckFlags
	ldto_berp E, 0xfb
	extz de
	lda_24 xwa, DemoDiskPrompt_English1_0x8A
	ld_srib3 A, 0x07, 0xe0, 0xe8
	andda8_24 a, 0x0247ee
	jr z, FDemoText_ProcessOutput_CheckFlags
	or_srib_rm C, 0x07, 0xec, 0xe8
	st8_24 0x0247ec, c

FDemoText_ProcessOutput_CheckFlags:
	ldto_berp A, 0xfb
	extz wa
	lda_24 xbc, DemoDiskPrompt_English1_0x8A
	ld_srib3 C, 0x07, 0xe4, 0xe0
	andda8_24 c, 0x0247ee
	jr z, FDemoText_ProcessOutput_NextCh
	lda_24 xbc, DemoDiskPrompt_English1_0x8E
	ld_srib3 C, 0x07, 0xe4, 0xe0
	ld8_24 e, 0x0247ec
	and c, e
	jr z, FDemoText_ProcessOutput_AltUpdate
	calr FDemoText_SendVoiceParams
	jr FDemoText_ProcessOutput_NextCh

FDemoText_ProcessOutput_AltUpdate:
	ld_srib3 C, 0x07, 0xec, 0xe0
	and c, e
	call_24 nz, FDemoText_UpdatePartialVoice

FDemoText_ProcessOutput_NextCh:
	inc1_berp 0xfb
	cpi_berp 0xfb, 2
	jr ule, FDemoText_ProcessOutputChannels

FDemoText_ProcessOutput_ClearAll:
	sti8_24 0x0247ec, 0x00
	sti8_24 0x0247f2, 0x00
	anddi8_24 0x0247ee, 120

FDemoText_ProcessVoiceFlags_Return:
	pop_werp 0xfa
	ret

FDemoText_ActivateVoice:
	dec 2, xsp
	ld (xsp), a
	ld a, (xsp)
	extz wa
	calr FDemoText_SendVoiceParams
	bitda_24 7, 0x0247ee
	jr nz, FDemoText_ActivateVoice_Done
	ld a, (xsp)
	extz wa
	calr FDemoText_SyncVoicePreset

FDemoText_ActivateVoice_Done:
	inc 2, xsp
	ret

FDemoText_DeactivateVoice:
	extz wa
	lda_24 xbc, DemoDiskPrompt_English1_0x8A
	ld_srib3 C, 0x07, 0xe4, 0xe0
	cpl c
	anddm8_24 0x0247ee, c
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
	lda_24 xbc, DemoDiskPrompt_English1_0x8A
	ld_srib3 A, 0x07, 0xe4, 0xe0
	ordm8_24 0x0247ee, a
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
	lds bc, 5
	lds de, 0
	call AddswbWr
	lda xwa, (xiz + 2)
	cp (xwa), 0x0
	jr nz, FDemoText_UpdateVoiceDisplay_CheckSend
	ld (xwa), 0x5a
	ld a, (xsp + 4)
	extz wa
	pushw 0x7f
	lds bc, 7
	ldw de, 0x5a
	call AddswbWr

FDemoText_UpdateVoiceDisplay_CheckSend:
	ld8_24 a, 0x0247ee
	and a, 0x38
	jr nz, FDemoText_UpdateVoiceDisplay_Done
	ldda8 c, 0xfc26
	cpdm8 0xfc74, c
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
	push_werp 0xfa
	ld (xsp + 6), a
	ldada xwa, 0xfc74
	ld (xsp + 2), xwa
	ld8_24 a, 0x0247ee
	and a, 0x38
	jr z, FDemoText_SyncPreset_DirectCopy
	ldi_berp 0xfb, 0

FDemoText_SyncPreset_ActiveLoop:
	ldto_berp A, 0xfb
	extz wa
	calr FDemoText_CheckVoiceState
	ldto_berp A, 0xfb
	extz wa
	cps l, 1
	jr nz, FDemoText_SyncPreset_CallUpdate
	ld bc, wa
	lda_24 xde, DemoDiskPrompt_English1_0x86
	ld_srib3 A, 0x07, 0xe8, 0xe0
	andda8_24 a, 0x0247ee
	jr z, FDemoText_SyncPreset_NextActive
	ld wa, bc

FDemoText_SyncPreset_CallUpdate:
	calr FDemoText_UpdateChannelVoice

FDemoText_SyncPreset_NextActive:
	inc1_berp 0xfb
	cpi_berp 0xfb, 2
	jr ule, FDemoText_SyncPreset_ActiveLoop
	jr FDemoText_SyncPreset_Compare

FDemoText_SyncPreset_DirectCopy:
	ld xwa, (xsp + 2)
	ld a, (xwa)
	stda8 0xfc26, a
	ldi_berp 0xfb, 0

FDemoText_SyncPreset_DirectLoop:
	ldto_berp A, 0xfb
	extz wa
	calr FDemoText_UpdateChannelVoice
	inc1_berp 0xfb
	cpi_berp 0xfb, 2
	jr ule, FDemoText_SyncPreset_DirectLoop

FDemoText_SyncPreset_Compare:
	ld a, (xsp + 6)
	extz wa
	lda_24 xbc, 0x0247f4
	ld_srib3 C, 0x07, 0xe4, 0xe0
	ld xwa, (xsp + 2)
	cp c, (xwa)
	jr z, FDemoText_SyncPreset_Return
	extz bc
	ldw wa, 0x61
	calr FDemoText_NotifyUIChange

FDemoText_SyncPreset_Return:
	pop_werp 0xfa
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
	pushw 0x7f
	lds bc, 5
	lds de, 0
	jr FDemoText_UpdateChannel_SendCmd

FDemoText_UpdateChannel_Active:
	cp (xiz), 0x0
	jr nz, FDemoText_UpdateChannel_Done
	ld (xiz), 0x50
	pushw 0x7f
	lds bc, 5
	ldw de, 0x50
	call AddswbWr
	lda xwa, (xiz + 2)
	cp (xwa), 0x0
	jr z, FDemoText_UpdateChannel_Done
	ld (xwa), 0x0
	ld a, (xsp + 4)
	extz wa
	pushw 0x7f
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
	ld (xwa), 0x5a
	ld a, (xsp + 4)
	extz wa
	pushw 0x7f
	lds bc, 7
	ldw de, 0x5a
	call AddswbWr

FDemoText_CheckTimer_Done:
	pop xiz
	inc 2, xsp
	ret

FDemoText_ParseControlMessage:
	lda_24 xbc, 0x020c33
	ld a, (xbc + 1)
	cpda8 a, 0x8d3a
	ret nz
	cpdi8 0x8d38, 234
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
	cps e, 2
	jr nz, FDemoText_ParseCtrl_SecondHalf
	lds wa, 6
	call DemoMenu_BuildItemWorkspace
	ld8_24 a, 0x020c39
	srl a, 4
	and a, 0xf
	ld c, a
	extz bc
	lds wa, 2
	call DemoMenu_BuildItemWorkspace
	ld8_24 c, 0x020c39
	and c, 0xf
	extz bc
	lds wa, 0
	jr FDemoText_ParseCtrl_BuildWorkspace

FDemoText_ParseCtrl_Type82:
	ldw wa, 0x8
	call DemoMenu_BuildItemWorkspace
	ld8_24 a, 0x020c39
	srl a, 4
	and a, 0xf
	ld c, a
	extz bc
	lds wa, 5
	call DemoMenu_BuildItemWorkspace
	ld8_24 c, 0x020c39
	and c, 0xf
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
	and c, 0xf
	extz bc
	lds wa, 7
	call DemoMenu_BuildItemWorkspace
	ld8_24 a, 0x020c39
	srl a, 4
	and a, 0xf
	ld c, a
	extz bc
	lds wa, 4
	call DemoMenu_BuildItemWorkspace
	ld8_24 c, 0x020c39
	and c, 0xf
	extz bc
	lds wa, 1
	jr FDemoText_ParseCtrl_Finalize

FDemoText_ParseCtrl_FormatC3:
	ld c, (xwa + 6)
	and c, 0x1
	extz bc
	ldw wa, 0xa
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
	ld (xde + 5), 0xea
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
	push_werp 0xfa
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
	ldi_erpb 0xfb, 0x0b

FDemoText_SendParams_NoteLoop:
	lda xde, (xsp + 6)
	ldto_berp A, 0xfb
	ld (xde + 2), a
	ld xwa, (xsp + 2)
	ld a, (xwa)
	ld (xde + 4), a
	lds wa, 0
	lds bc, 6
	call sendCOMM
	lds32 xwa, 1
	add (xsp + 2), xwa
	inc1_berp 0xfb
	cp_erpb 0xfb, 0x0c
	jr ule, FDemoText_SendParams_NoteLoop
	ld a, (xsp + 12)
	add a, 0x44
	extz wa
	calr FDemoText_LookupTableEntry
	ld (xsp + 2), xhl
	lds32 xwa, 3
	add (xsp + 2), xwa
	ldi_berp 0xfb, 4

FDemoText_SendParams_LevelLoop:
	lda xde, (xsp + 6)
	ldto_berp A, 0xfb
	ld (xde + 2), a
	ld xwa, (xsp + 2)
	ld a, (xwa)
	ld (xde + 4), a
	lds wa, 0
	lds bc, 6
	call sendCOMM
	lds32 xwa, 1
	add (xsp + 2), xwa
	inc1_berp 0xfb
	cp_erpb 0xfb, 0x08
	jr ule, FDemoText_SendParams_LevelLoop
	ld c, (xsp + 12)
	extz bc
	ldw wa, 0xff
	call VoiceEvent_FlushAndReturn

FDemoText_SendVoiceParams_Return:
	pop_werp 0xfa
	lda xsp, (xsp + 12)
	ret

FDemoText_SendExtVoiceParams:
	lda xsp, (xsp - 22)
	push_werp 0xfa
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
	lds wa, 0
	lds bc, 4
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
	lds wa, 0
	lds bc, 6
	call sendCOMM
	lds32 xwa, 1
	add (xsp + 2), xwa
	inc1_berp 0xfb
	cp_erpb 0xfb, 0x0c
	jr ule, FDemoText_SendExtParams_NoteLoop
	ldi_berp 0xfb, 4

FDemoText_SendExtParams_LevelLoop:
	lda xde, (xsp + 16)
	ldto_berp A, 0xfb
	ld (xde + 2), a
	ld xwa, (xsp + 2)
	ld a, (xwa)
	ld (xde + 4), a
	lds wa, 0
	lds bc, 6
	call sendCOMM
	lds32 xwa, 1
	add (xsp + 2), xwa
	inc1_berp 0xfb
	cp_erpb 0xfb, 0x08
	jr ule, FDemoText_SendExtParams_LevelLoop
	ld c, (xsp + 22)
	extz bc
	ldw wa, 0xff
	call VoiceEvent_FlushAndReturn
	pop_werp 0xfa
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
	lds wa, 0
	lds bc, 6
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
	lds wa, 0
	lds bc, 6
	call sendCOMM

FDemoText_UpdatePartial_Done:
	pop xiz
	lda xsp, (xsp + 10)
	ret

FDemoText_SendExtParamsAlt:
	lda xsp, (xsp - 22)
	push_werp 0xfa
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
	lds wa, 0
	lds bc, 6
	call sendCOMM
	lds32 xwa, 1
	add (xsp + 2), xwa
	inc1_berp 0xfb
	cp_erpb 0xfb, 0x0c
	jr ule, FDemoText_SendExtAlt_NoteLoop
	lda xde, (xsp + 16)
	ld (xde + 2), 0x8
	ld xwa, (xsp + 2)
	ld a, (xwa + 4)
	ld (xde + 4), a
	lds wa, 0
	lds bc, 6
	call sendCOMM
	pop_werp 0xfa
	lda xsp, (xsp + 22)
	ret

FDemoText_ProbeVoiceType:
	dec 8, xsp
	ld (xsp + 6), a
	ld a, (xsp + 6)
	extz wa
	calr FDemoText_LookupTableEntry
	lda xbc, (xsp)
	ld_spib A, 0xec
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
	calr	63389
	lda	xbc, (xsp)
	.byte 0xc5, 0xec
	ldb	a, 185
	pop_sr
	ld	xbc, 0x04b92183
	ld	xbc, 0xb921068f
	push_sr
	ld	xbc, 0xea1d88e9
	.byte 0xe7
	swi	6
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
	lda_24 xbc, DemoDiskPrompt_English1_0x8A
	ld_srib3 A, 0x07, 0xe4, 0xe0
	andda8_24 a, 0x0247f0
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
	ld (xde + 5), 0xea
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
	ldi_erpb 0xfb, 0xff
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
	cp (xbc + 5), 0xea
	jr nz, FDemoText_ScanMIDI_NoMatch
	ld c, (xbc + 7)
	cp c, 0xf
	jr z, FDemoText_ScanMIDI_SetActive
	cp c, 0x35
	jr z, FDemoText_ScanMIDI_SetActive
	ldi_berp 0xfb, 0

FDemoText_ScanMIDI_LookupActive:
	ld a, (xsp + 4)
	extz wa
	lda_24 xde, 0x0247f4
	lda_dri3 XHL, 0x07, 0xe8, 0xe0

FDemoText_ScanMIDI_NoMatch:
	cp_erpb 0xfb, 0xff
	jr nz, FDemoText_ScanMIDI_CheckTimeout

FDemoText_ScanMIDI_ReadNextFrame:
	call Seq_RingBuf_ReadSmall
	cps hl, 0
	jrl ge, FDemoText_ScanMIDI_ReadBytes

FDemoText_ScanMIDI_CheckTimeout:
	cp_erpb 0xfb, 0xff
	jr nz, FDemoText_ScanMIDI_UpdateFlags
	cpw (xsp + 6), 0x2710
	jrl c, FDemoText_ScanMIDI_AdvanceTimeout

FDemoText_ScanMIDI_UpdateFlags:
	ld a, (xsp + 4)
	extz wa
	lda_24 xbc, DemoDiskPrompt_English1_0x8A
	exts xwa
	add xwa, xbc
	cpi_berp 0xfb, 1
	jr nz, FDemoText_ScanMIDI_ClearActive
	ld a, (xwa)
	ordm8_24 0x0247f0, a
	jr FDemoText_ScanMIDI_NextChannel

FDemoText_ScanMIDI_SetActive:
	ldi_berp 0xfb, 1
	jr FDemoText_ScanMIDI_LookupActive

FDemoText_ScanMIDI_ClearActive:
	ld a, (xwa)
	cpl a
	anddm8_24 0x0247f0, a

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
	push_werp 0xfa
	calr FDemoText_ScanMIDIChannels
	ldi_berp 0xfb, 0

FDemoText_Rescan_Loop:
	ldto_berp A, 0xfb
	extz wa
	lda_24 xbc, DemoDiskPrompt_English1_0x8A
	ld_srib3 C, 0x07, 0xe4, 0xe0
	ldfr_berp C, 0xfa
	calr FDemoText_CheckVoiceState
	cps l, 1
	jr z, FDemoText_Rescan_SetFlag
	ldto_berp A, 0xfa
	cpl a
	anddm8_24 0x0247ee, a
	jr FDemoText_Rescan_NextVoice

FDemoText_Rescan_SetFlag:
	ldto_berp A, 0xfa
	ordm8_24 0x0247ee, a

FDemoText_Rescan_NextVoice:
	inc1_berp 0xfb
	cpi_berp 0xfb, 2
	jr ule, FDemoText_Rescan_Loop
	ldi_berp 0xfb, 0

FDemoText_Rescan_SendUpdates:
	ldto_berp A, 0xfb
	extz wa
	lda_24 xbc, DemoDiskPrompt_English1_0x8A
	ld_srib3 C, 0x07, 0xe4, 0xe0
	andda8_24 c, 0x0247ee
	call_24 nz, FDemoText_SendVoiceParams
	inc1_berp 0xfb
	cpi_berp 0xfb, 2
	jr ule, FDemoText_Rescan_SendUpdates
	pop_werp 0xfa
	ret

FDemoText_NotifyUIChange:
	push xiz
	extz bc
	ld xwa, 0x4900
	call DSPCfg_WriteParamFull
	ldda8 e, 0xfc74
	extz de
	pushw 0xff
	ldw wa, 0x61
	lds bc, 0
	call AddswbWr
	ld xwa, 0x4904
	call DSPCfg_ReadParam_Map0
	ldfr_werp HL, 0xfa
	lds iz, 0
	cpi_werp 0xfa, 0
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
	cp_werp IZ, 0xfa
	jr c, FDemoText_NotifyUI_Loop

FDemoText_NotifyUI_Done:
	pop xiz
	ret

FDemoText_RefreshFullDisplay:
	ordi8_24 0x0247ee, 7
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
	jr	nz, 7
	lda_24	xhl, DemoDiskPrompt_English1_0x192
	jr	94
	ld	xwa, xiz
	ld	xbc, 0x01e00015
	lds32	xde, 0
	call	SendEvent
	cp	(xhl), 0
	jr	nz, 58
	ld	xwa, xiz
	srl	xwa, 0
	and	xwa, 4095
	extz	xwa
	add	xwa, 0x01a00000
	ld	xbc, 0x01e00015
	lds32	xde, 0
	call	SendEvent
	ld	xwa, xiz
	.byte 0xd7, 0xe2, 0xa8
	pushw	wa
	.long Bitmap_TechnichordBackground_2
	pushw	0xfdd6
	pushw	2
	pushw	0x47f6
	call	Sprintf_Locked
	lda	xsp, (xsp+14)
	jr	13
	push	xhl
	pushw	2
	pushw	0x47f6
	call	Strcpy
	inc	8, xsp
	lda_24	xhl, 0x0247f6
	pop	xiz
	ret
	.byte 0xf3
	swi	5
	jrl	14335
	push	xiz
	push	xwa
	lda	xwa, (xsp+16)
	push	xwa
	call	Strcpy
	inc	8, xsp
	ld	xwa, 255
	ld	(xsp+4), xwa
	ld	xbc, (xsp+4)
	ld	wa, bc
	call	CountObject
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
	sll	xwa, 0
	add	xwa, xbc
	call	CheckViewObject
	cps	hl, 0
	jr	z, 42
	ld	xbc, xiz
	.byte 0xaf, 0x04
	.long SeqCh_FeatureDemoCallbackData
	add	xwa, xbc
	calr	65335
	push	xhl
	lda	xwa, (xsp+16)
	push	xwa
	call	Strcmp
	inc	8, xsp
	cps	hl, 0
	jr	nz, 14
	ld	xbc, xiz
	ld	xwa, (xsp+4)
	sll	xwa, 0
	add	xwa, xbc
	ld	xhl, xwa
	jr	39
	inc	1, xiz
	ld	xwa, xiz
	.byte 0xaf
	ldio	240, 103
	.byte 0xbb
	lds32	xwa, 1
	sub	(xsp+4), xwa
	ld	xwa, (xsp+4)
	cp	xwa, 0
	jr	ge, -116
	.byte 0x40
	.long ErrStr_GetInstanceID
	call	DbMemo_DrawContent_Loop_0x61
	ld	xhl, 0xffffffff
	pop	xiz
	.byte 0xf3
	swi	5
	.byte 0x88
	nop
	.byte 0x37
	ret
	lda	xsp, (xsp-22)
	pushw	iz
	ld	(xsp+12), xde
	ld	(xsp+16), xbc
	ld	(xsp+20), xwa
	ldw	(xsp+2), 1
	jr	23
	cp	hl, 60
	jr	nz, 17
	lds	iz, 1
	call	FileIO_ReadByte
	cps	hl, 0
	jr	ge, 28
	cpw	(xsp+2), 0
	jr	z, 8
	call	FileIO_ReadByte
	cps	hl, 0
	jr	ge, -31
	cpw	(xsp+2), 0
	jr	z, 35
	ldw	hl, 0xfffd
	jrl	198
	ld	xbc, (xsp+12)
	.byte 0xc3
	reti
	.byte 0xe4
	swi	0
	ldb	a, 216
	ccf
	cp	wa, hl
	jr	nz, -42
	inc	1, iz
	.byte 0xc3
	reti
	.byte 0xe4
	swi	0
	push	xsp
	nop
	jr	nz, -60
	ldw	(xsp+2), 0
	lds32	xwa, 0
	ld	(xsp+4), xwa
	call	FileIO_ReadByte
	cps	hl, 0
	jr	ge, 14
	cpw	(xsp+2), 1
	jrl	z, 146
	ldw	hl, 0xfffc
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
	.byte 0xaf, 0x04
	and	(xbc), l
	.byte 0x89
	ld	(xbc), a
	lds32	xwa, 1
	add	(xsp+4), xwa
	ld	xwa, (xsp+4)
	cp	xwa, (xsp+16)
	jr	nc, 48
	cp	hl, 60
	jr	nz, -75
	lds	iz, 1
	call	FileIO_ReadByte
	cps	hl, 0
	jr	ge, 9
	cpw	(xsp+2), 1
	jr	z, -84
	jr	-94
	ld	xbc, (xsp+20)
	.byte 0xaf, 0x04
	and	(xbc), l
	.byte 0x89
	ld	(xbc), a
	lds32	xwa, 1
	add	(xsp+4), xwa
	ld	xwa, (xsp+4)
	cp	xwa, (xsp+16)
	jr	c, 5
	ldw	hl, 0xfffb
	jr	42
	ld	xbc, (xsp+28)
	.byte 0xc3
	reti
	.byte 0xe4
	swi	0
	ldb	a, 216
	ccf
	cp	wa, hl
	jr	nz, -51
	inc	1, iz
	.byte 0xc3
	reti
	.byte 0xe4
	swi	0
	push	xsp
	nop
	jr	nz, -69
	ldw	(xsp+2), 1
	ld	xwa, (xsp+20)
	.byte 0xaf
	ldio	128, 176
	nop
	nop
	jr	-77
	lds	hl, 0
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
	lda_24 xwa, DemoDiskPrompt_English1_0xB4
	ld_sril3 XWA, 0x07, 0xe0, 0xe4
	push xwa
	call String_Compare
	add xsp, 0xe
	cps hl, 0
	jrl nz, FDemoText_ProcessMarkup_NextTag
	ld bc, (xsp + 16)
	sla bc, 3
	lda_24 xwa, DemoDiskPrompt_English1_0xB8
	ld_sril3 XWA, 0x07, 0xe0, 0xe4
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
	st_dri3b A, 0x07, 0xe4, 0xec
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
	st_dri3l XDE, 0x07, 0xe4, 0xf4
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
	cp_spib_im 0xf8, 0x3e
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
	lda_24 xwa, DemoDiskPrompt_English1_0xB4
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
	cp_spib_im 0xf8, 0x3e
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
	.byte 0xaf
	ldwio	128, 8352
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
	lds	iz, 0
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
	.byte 0x80
	push	xsp
	nop
	jr	z, 113
	ld	xde, (xsp+2)
	.byte 0xf3
	reti
	.byte 0xe8
	swi	0
	ldw	wa, 0x89e8
	.byte 0x80
	.ascii "?=nU"
	ld	(xbc), 0
	push	xde
	ld	xwa, (xsp+10)
	push	xwa
	call	Strcpy
	inc	8, xsp
	inc	1, iz
	ld	xde, (xsp+2)
	.byte 0xf3
	reti
	.byte 0xe8
	swi	0
	ldw	wa, 0x89e8
	ld	a, (xwa)
	cp	a, 34
	jr	nz, 39
	inc	1, iz
	.byte 0xf3
	reti
	.byte 0xe8
	swi	0
	ldw	wa, 0xaf38
	ex_ff
	ldb	w, 56
	call	Strcpy
	ld	xwa, (xsp+26)
	push	xwa
	call	Strlen
	lda	xsp, (xsp+12)
	dec	1, hl
	extz	xhl
	add	xhl, (xsp+18)
	ld	(xhl), 0
	jr	26
	push	xbc
	ld	xwa, (xsp+22)
	push	xwa
	call	Strcpy
	inc	8, xsp
	jr	13
	inc	1, iz
	ld	xwa, (xsp+2)
	.byte 0xc3
	reti
	.byte 0xe0
	swi	0
	push	xsp
	nop
	jr	nz, -113
	ld	xwa, (xsp+2)
	push	xwa
	call	Free
	inc	4, xsp
	popw	iz
	lda	xsp, (xsp+12)
	retd	4

FDemoText_TextDispatch:
	cps bc, 1
	jr z, FDemoText_TextDispatch_Return
	cps bc, 0
	call_24 z, FDemoText_RenderTextLine

FDemoText_TextDispatch_Return:
	lds hl, 0
	ret

FDemoText_ByteData_LayoutEngine:
	.byte 0xf3
	swi	5
	ldb	b, 255
	.byte 0x37
	push	xiz
	.byte 0xf3
	swi	5
	.byte 0xda
	nop
	.byte 0x52
	ld	(xsp+220), xbc
	ld	(xsp+224), wa
	ld	xiy, FileTypeName_Song_0x6
	lda	xix, (xsp+20)
	ldw	bc, 32
	ldirw
	.byte 0x85
	rcf
	ld	xiy, FileTypeName_Song_0x48
	lda	xix, (xsp+6)
	lds	bc, 6
	ldirw
	.byte 0x85
	rcf
	lds	iz, 0
	cpw	(xsp+224), 0
	jr	lt, 123
	.byte 0xf3
	swi	5
	.byte 0x98
	nop
	ldw	de, 0x56bf
	ldw	wa, 0xde38
	.byte 0x88
	ld	xbc, (xsp+224)
	calr	65211
	.byte 0xd7
	swi	2
	.byte 0xa8
	jr	69
	.byte 0xf3
	swi	5
	.byte 0x98
	nop
	ldw	wa, 0x3938
	call	Strcmp
	inc	8, xsp
	cps	hl, 0
	jr	nz, 49
	.byte 0xd7
	swi	2
	.byte 0x88
	lda	xbc, (xsp+86)
	.byte 0xd7
	swi	2
	inc	6, de
	jp	0x66d9d8
	rcf
	cps	wa, 0
	jr	nz, 30
	push	xbc
	call	ParseInt16
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
	call	Strcpy
	inc	8, xsp
	.byte 0xd7
	swi	2
	jr	lt, -41
	swi	2
	or	(xbc-39), d
	push_sr
	lda_24	xwa, FileType_NameTable
	.byte 0xe3
	reti
	.byte 0xe0, 0xe4
	ldb	a, 129
	push	xsp
	nop
	jr	nz, -90
	inc	1, iz
	cp	iz, (xsp+224)
	jr	le, -123
	cpw	(xsp+218), 1
	jrl	z, 225
	cpw	(xsp+218), 0
	jrl	nz, 215
	lda	xbc, (xsp+6)
	cp	(xbc), 0
	jrl	z, 206
	ld	wa, (xsp+4)
	dec	1, wa
	st16_24	0x024876, wa
	push	xbc
	pushw	233
	pushw	0xfe66
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
	.byte 0x40
	.long Pad_AfterNakaData_ExternalBase
	ld	xbc, 0x01c00002
	lds32	xde, 5
	call	SendEvent
	.byte 0x40
	.long Pad_NakaExternal_Block1
	ld	xbc, 0x01c00002
	lds32	xde, 5
	call	SendEvent
	.byte 0x40
	.long Pad_NakaExternal_Block1
	ld	xbc, 0x01c00001
	lds32	xde, 5
	call	SendEvent
	.byte 0x40
	.long Pad_NakaExternal_Block1
	ld	xbc, 0x01c10005
	ld	xde, 19
	call	SendEvent
	ld	xwa, NakaInst_Param_Field02_0x4
	ld	xbc, 0x01c00001
	lds32	xde, 0
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
	ld	xwa, 0x01410000
	ld	xbc, 0x01e10005
	ld	xde, xiz
	call	MainFuncCall
	ld	xwa, 0x01400003
	ld	xbc, 0x01e00023
	ld	xde, xiz
	call	MainFuncCall
	lds	hl, 0
	pop	xiz
	.byte 0xf3
	swi	5
	.byte 0xde
	nop
	.byte 0x37
	ret
	.byte 0xf3
	swi	5
	jrl	le, 14335
	push	xiz
	ld	(xsp+138), de
	.byte 0xf3
	swi	5
	.byte 0x8c
	nop
	jr	lt, -13
	swi	5
	.byte 0x90
	nop
	.byte 0x50, 0xbf, 0x04
	push_sr
	nop
	nop
	cpw	(xsp+144), 0
	jrl	lt, 152
	lda	xde, (xsp+72)
	lda	xwa, (xsp+6)
	push	xwa
	ld	wa, (xsp+8)
	ld	xbc, (xsp+144)
	calr	64809
	.byte 0xd7
	swi	2
	.byte 0xa8
	jr	94
	lda	xbc, (xsp+72)
	push	xbc
	push	xwa
	call	Strcmp
	inc	8, xsp
	cps	hl, 0
	jr	nz, 76
	ld	bc, qiz
	lda	xwa, (xsp+6)
	.byte 0xd7
	swi	2
	inc	6, bc
	retd	0xd8d9
	jr	nz, 61
	push	xwa
	call	ParseInt16
	inc	4, xsp
	ld	iz, hl
	jr	50
	.byte 0xc5, 0xe0
	ldb	c, 203
	div8rr	b, l
	jr	z, 29
	cp	c, 67
	jr	z, 19
	cp	c, 76
	jr	nz, 32
	push	xwa
	call	ParseInt16
	inc	4, xsp
	ldw	iz, 64
	sub	iz, hl
	jr	18
	ldw	iz, 64
	jr	13
	push	xwa
	call	ParseInt16
	inc	4, xsp
	ld	iz, hl
	add	iz, 64
	.byte 0xd7
	swi	2
	jr	lt, -41
	swi	2
	or	(xbc-39), d
	push_sr
	lda_24	xwa, FileTypeName_Song_0x5A
	.byte 0xe3
	reti
	.byte 0xe0, 0xe4
	ldb	w, 128
	push	xsp
	nop
	jr	nz, -115
	incm	1, (xsp+4)
	ld	wa, (xsp+4)
	cp	wa, (xsp+144)
	jrl	le, -152
	cpw	(xsp+138), 2
	jr	z, 91
	cpw	(xsp+138), 1
	jr	z, 82
	cpw	(xsp+138), 0
	jr	nz, 103
	calr	1079
	ld	xwa, 0xffffffff
	ld	xbc, 0x01e0009e
	lds32	xde, 1
	call	SendEvent
	ld	xwa, Bitmap_Dredt0d_0x9A9
	ld	xbc, 0x01c00001
	lds32	xde, 0
	call	SendEvent
	ld	xwa, Bitmap_Dredt0d_0x9AA
	ld	xbc, 0x01c00001
	lds32	xde, 5
	call	SendEvent
	ld	xwa, 0xffffffff
	ld	xbc, 0x01e0009e
	lds32	xde, 0
	call	SendEvent
	call	DrawWall
	jr	30
	cps	iz, 0
	jr	lt, 26
	cp	iz, 127
	jr	gt, 20
	ld	bc, iz
	sla	bc, 2
	lda_24	xde, 0x024fd8
	ld32_24	xwa, 0x0249d4
	.byte 0xf3
	reti
	or	xix, xwa
	jr	f, -37
	cp	xhl, (xwa+94)
	swi	5
	.byte 0x8e
	nop
	.byte 0x37
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
	.byte 0xf2
	divs8rr	h, b
	swi	0
	.byte 0xe6
	lds	hl, 0
	ret
	cps	de, 1
	jr	z, 36
	cps	de, 0
	jr	nz, 32
	calr	1161
	ld16_24	wa, 0x025b72
	inc	1, wa
	st16_24	0x025b72, wa
	cp	wa, 8
	jr	ge, 11
	lda_24	xbc, 0x025b74
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
	ld16_24	wa, 0x025b72
	dec	1, wa
	st16_24	0x025b72, wa
	cps	wa, 0
	jr	ge, 7
	sti16_24	0x025b72, 0
	lda_24	xbc, 0x025b74
	ld16_24	wa, 0x025b72
	.byte 0xf3
	reti
	.byte 0xe4, 0xe0
	nop
	.byte 0x01
	lds	hl, 0
	ret
	.byte 0xf3
	swi	5
	jr	nz, -1
	.byte 0x37
	push	xiz
	ld	(xsp+142), de
	ld	(xsp+144), xbc
	.byte 0xf3
	swi	5
	.byte 0x94
	nop
	.byte 0x50
	ld16_24	wa, 0x025b3e
	sla	wa, 2
	lda_24	xbc, 0x025b40
	.byte 0xe3
	reti
	.byte 0xe4, 0xe0
	ldb	w, 191
	.byte 0x04
	jr	f, -46
	jr	f, 91
	push_sr
	ldb	w, 216
	.byte 0xec, 0x01
	lda_24	xbc, 0x025b62
	.byte 0xd3
	reti
	.byte 0xe4, 0xe0
	ldb	w, 191
	ldio	80, 222
	cp	(xwa-45), xiy
	.byte 0x94
	nop
	push	xsp
	nop
	nop
	jrl	lt, 141
	lda	xde, (xsp+76)
	lda	xwa, (xsp+10)
	push	xwa
	ld	wa, iz
	ld	xbc, (xsp+148)
	calr	64322
	.byte 0xd7
	swi	2
	.byte 0xa8
	jr	88
	lda	xbc, (xsp+76)
	push	xbc
	push	xwa
	call	Strcmp
	inc	8, xsp
	cps	hl, 0
	jr	nz, 70
	ld	bc, qiz
	lda	xwa, (xsp+10)
	.byte 0xd7
	swi	2
	inc	6, bc
	ldb	l, 217
	dec	6, wa
	.byte 0x37
	push	xwa
	call	ParseInt16
	inc	4, xsp
	cps	hl, 0
	jr	lt, 44
	cp	hl, 9
	jr	gt, 38
	sla	hl, 2
	lda_24	xwa, ImgAttr_Size_0x6
	.byte 0xe3
	reti
	.byte 0xe0, 0xec
	ldb	w, 191
	.byte 0x04
	jr	f, 104
	push_a
	push	xwa
	call	ParseInt16
	inc	4, xsp
	cps	hl, 0
	jr	lt, 9
	cp	hl, 255
	jr	gt, 3
	ld	(xsp+8), hl
	.byte 0xd7
	swi	2
	jr	lt, -41
	swi	2
	or	(xbc-39), d
	push_sr
	lda_24	xwa, UIStr_No_0x4
	.byte 0xe3
	reti
	.byte 0xe0, 0xe4
	ldb	w, 128
	push	xsp
	nop
	jr	nz, -109
	inc	1, iz
	.byte 0xd3
	swi	5
	.byte 0x94
	nop
	.byte 0xf6
	jrl	le, -141
	cpw	(xsp+142), 1
	jr	z, 76
	cpw	(xsp+142), 0
	jr	nz, 67
	ld16_24	bc, 0x025b3e
	inc	1, bc
	st16_24	0x025b3e, bc
	ld16_24	wa, 0x025b60
	inc	1, wa
	st16_24	0x025b60, wa
	cp	bc, 8
	jr	ge, 37
	sla	bc, 2
	lda_24	xde, 0x025b40
	ld	xwa, (xsp+4)
	.byte 0xf3
	reti
	or	xix, xwa
	jr	f, -46
	jr	f, 91
	push_sr
	ldb	a, 217
	.byte 0xec, 0x01
	lda_24	xde, 0x025b62
	ld	wa, (xsp+8)
	.byte 0xf3
	reti
	or	xix, xwa
	.byte 0x50
	lds	hl, 0
	pop	xiz
	.byte 0xf3
	swi	5
	.byte 0x92
	nop
	.byte 0x37
	ret
	cps	de, 1
	jr	z, 79
	cps	de, 0
	jr	nz, 75
	ld16_24	wa, 0x025b3e
	dec	1, wa
	st16_24	0x025b3e, wa
	decdi16_24	1, 0x025b60
	cps	wa, 0
	jr	ge, 14
	sti16_24	0x025b3e, 0
	sti16_24	0x025b60, 0
	ld16_24	bc, 0x025b3e
	sla	bc, 2
	lda_24	xde, 0x025b40
	lds32	xwa, 5
	.byte 0xf3
	reti
	or	xix, xwa
	jr	f, -46
	jr	f, 91
	push_sr
	ldb	w, 216
	.byte 0xec, 0x01
	lda_24	xbc, 0x025b62
	.byte 0xf3
	reti
	.byte 0xe4, 0xe0
	push_sr
	swi	7
	nop
	lds	hl, 0
	ret
	.byte 0xf3
	swi	5
	.byte 0xf0
	swi	6
	.byte 0x37
	push	xiz
	.byte 0xf3
	swi	5
	incf
	.byte 0x01, 0x52, 0xf3
	swi	5
	ret
	.byte 0x01, 0x61
	ld	(xsp+274), wa
	ld	xiy, ImgAttrName_Src_0x4
	.byte 0xbf
	.asciz "F41 "
	ldirw
	.byte 0x85
	rcf
	ld	xiy, ImgAttrName_Src_0x46
	lda	xix, (xsp+4)
	ldw	bc, 32
	ldirw
	.byte 0x85
	rcf
	lds	iz, 0
	cpw	(xsp+274), 0
	jr	lt, 123
	.byte 0xf3
	swi	5
	.byte 0xca
	nop
	ldw	de, 0xfdf3
	.byte 0x88
	nop
	ldw	wa, 0xde38
	cp	(xwa-29), e
	ccf
	.byte 0x01
	ldb	a, 30
	.byte 0xbf
	swi	1
	.byte 0xd7
	swi	2
	.byte 0xa8
	jr	67
	lda	xwa, (xsp+202)
	push	xwa
	push	xbc
	call	Strcmp
	inc	8, xsp
	cps	hl, 0
	jr	nz, 47
	.byte 0xd7
	swi	2
	cp	(xwa-41), b
	mul	l, 0
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
	halt
	push	xbc
	lda	xwa, (xsp+8)
	push	xwa
	call	Strcpy
	inc	8, xsp
	.byte 0xd7
	swi	2
	jr	lt, -41
	swi	2
	or	(xbc-39), d
	push_sr
	lda_24	xwa, ImgAttr_NameTable
	.byte 0xe3
	reti
	.byte 0xe0, 0xe4
	ldb	a, 129
	push	xsp
	nop
	jr	nz, -88
	inc	1, iz
	cp	iz, (xsp+274)
	jr	le, -123
	lda	xbc, (xsp+70)
	cpw	(xsp+268), 1
	jr	z, 21
	cpw	(xsp+268), 0
	jr	nz, 22
	ld	xwa, xbc
	cp	(xbc), 0
	jr	z, 15
	calr	1096
	jr	10
	ld	xwa, xbc
	cp	(xbc), 0
	.byte 0xf2
	swi	5
	jr	-8
	cps	xiz, 3
	cp	xhl, (xwa+94)
	swi	5
	rcf
	.byte 0x01, 0x37
	ret
	.byte 0xf3
	swi	5
	ldw	de, 0x37ff
	push	xiz
	.byte 0xf3
	swi	5
	.byte 0xca
	nop
	.byte 0x52
	ld	(xsp+204), xbc
	.byte 0xf3
	swi	5
	.byte 0xd0
	nop
	.byte 0x50
	ld	xiy, ObjAttr_Obj_0x4
	lda	xix, (xsp+4)
	ldw	bc, 32
	ldirw
	.byte 0x85
	rcf
	lds	iz, 0
	cpw	(xsp+208), 0
	jr	lt, 93
	.byte 0xf3
	swi	5
	.byte 0x88
	nop
	ldw	de, 0x46bf
	ldw	wa, 0xde38
	.byte 0x88
	ld	xbc, (xsp+208)
	calr	63715
	.byte 0xd7
	swi	2
	ld	xsp, (xwa+104)
	.byte 0xf3
	swi	5
	.byte 0x88
	nop
	ldw	wa, 0x3938
	call	Strcmp
	inc	8, xsp
	cps	hl, 0
	jr	nz, 19
	.byte 0xd7
	swi	2
	dec	6, wa
	ret
	lda	xwa, (xsp+70)
	push	xwa
	lda	xwa, (xsp+8)
	push	xwa
	call	Strcpy
	inc	8, xsp
	.byte 0xd7
	swi	2
	jr	lt, -41
	swi	2
	or	(xbc-39), d
	push_sr
	lda_24	xwa, ImgAttrName_Src_0x88
	.byte 0xe3
	reti
	.byte 0xe0, 0xe4
	ldb	a, 129
	push	xsp
	nop
	jr	nz, -60
	inc	1, iz
	cp	iz, (xsp+208)
	jr	le, -93
	cpw	(xsp+202), 1
	jr	z, 57
	cpw	(xsp+202), 0
	jr	nz, 48
	lda	xwa, (xsp+4)
	.byte 0x80
	push	xsp
	nop
	jr	z, 40
	calr	62646
	ld	xwa, xhl
	cp	xwa, 0xffffffff
	jr	z, 27
	ld	xbc, 0x01c00001
	lds32	xde, 0
	call	SendEvent
	ld	xwa, Bitmap_Dredt0d_0x9AA
	ld	xbc, 0x01c00001
	lds32	xde, 5
	call	SendEvent
	lds	hl, 0
	pop	xiz
	.byte 0xf3
	swi	5
	.byte 0xce
	nop
	.byte 0x37
	ret
	lda_24	xbc, 0x0251da
	ld	xwa, xbc
	.byte 0xf3, 0xe5
	jr	f, 9
	ldw	bc, 0x8ae8
	lda	xhl, (xwa+40)
	.byte 0xf5, 0xe8
	nop
	.byte 0x54
	cp	xde, xhl
	jr	c, -8
	lda	xwa, (xwa+40)
	cp	xwa, xbc
	jr	c, -20
	lda_24	xwa, 0x025b3a
	ldw	(xwa), 0
	ldw	(xwa+2), 0
	sti16_24	0x025b3e, 0
	sti16_24	0x025b60, 0
	sti16_24	0x025b72, 0
	lda_24	xhl, 0x025b40
	lda_24	xde, 0x025b62
	lda_24	xwa, 0x025b74
	ld	xbc, xwa
	lda	xix, (xwa+8)
	lds32	xwa, 5
	.byte 0xf5
	inc	8, xiz
	.byte 0xf5, 0xe9
	push_sr
	swi	7
	nop
	.byte 0xf5, 0xe4
	nop
	.byte 0x01
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
	cp_srib_im 0x07, 0xe8, 0xe4, 0x54
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
	ld16_24 xwa, 0x025b3e
	sla wa, 2
	lda_24 xbc, 0x025b40
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	call GetCenteredDelta
	ld iz, hl
	ld16_24 xwa, 0x025b3e
	sla wa, 2
	lda_24 xbc, 0x025b40
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
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
	cp_srib_im 0x07, 0xf0, 0xe8, 0x54
	jr nz, FDemoText_FindCursor_LeftDone
	ld iy, iz
	cps iz, 0
	jr gt, FDemoText_FindCursor_SearchLeft

FDemoText_FindCursor_LeftDone:
	cp iy, 0xffff
	jr nz, FDemoText_FindCursor_StoreResult
	cp iz, 0x28
	jr ge, FDemoText_FindCursor_StoreResult

FDemoText_FindCursor_SearchRight:
	ld bc, hl
	add bc, iz
	cp_srib_im 0x07, 0xf0, 0xe4, 0x54
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
	ld xiy, ObjAttr_Obj_0x46
	lda xix, (xsp + 24)
	lds bc, 4
	ldirw
	ld16_24 xwa, 0x025b3e
	sla wa, 2
	lda_24 xbc, 0x025b40
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	call GetCharHeight
	ld iz, hl
	ld16_24 xwa, 0x025b3e
	sla wa, 2
	lda_24 xbc, 0x025b40
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
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
	ld16_24 xwa, 0x025b3e
	sla wa, 2
	lda_24 xbc, 0x025b40
	ld_sril3 XBC, 0x07, 0xe4, 0xe0
	ld xwa, (xsp + 16)
	ld de, (xsp + 4)
	call WordwrapStrings
	ld iz, hl
	cp_werp IZ, 0xfa
	jr z, FDemoText_Layout_NoWrap
	ldw (xsp + 14), 0x1
	ld xwa, (xsp + 16)
	st_dri3b W, 0x07, 0xe0, 0xf8
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
	ld_sril3 XBC, 0x07, 0xe4, 0xe0
	ld xwa, (xsp + 6)
	call CalcTotalWidth
	ld (xsp + 8), hl
	cps iz, 0
	jr z, FDemoText_Layout_UpdatePosition
	lda_24 xbc, 0x025b74
	ld16_24 xwa, 0x025b72
	ld_srib3 A, 0x07, 0xe4, 0xe0
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
	ld_sril3 XDE, 0x07, 0xec, 0xe8
	push xde
	ld16_24 xde, 0x025b60
	sla de, 1
	lda_24 xhl, 0x025b62
	push_sriw 0x07, 0xec, 0xe8
	pushw 0xf7
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
	ld16_24	wa, 0x025b3e
	sla	wa, 2
	lda_24	xbc, 0x025b40
	.byte 0xe3
	reti
	.byte 0xe4, 0xe0
	ldb	w, 29
	ldwio	38, 0xdbfb
	.byte 0x8e
	ld16_24	wa, 0x025b3e
	sla	wa, 2
	lda_24	xbc, 0x025b40
	.byte 0xe3
	reti
	.byte 0xe4, 0xe0
	ldb	w, 29
	.byte 0x17
	ldb	h, 251
	sub	iz, hl
	lda_24	xde, 0x025b3c
	ld	bc, (xde)
	ld	wa, bc
	sub	wa, iz
	jr	ge, 17
	neg	wa
	inc	3, wa
	exts	xwa
	divs	wa, 4
	sla	wa, 2
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
	ldw	(xsp+2), 24
	ld	xiy, 0x025b3a
	lda	xix, (xsp+8)
	ldiw
	ldiw
	lda	xwa, (xsp+8)
	sub	(xwa+2), iz
	calr	64683
	lda_24	xbc, 0x025b74
	ld16_24	wa, 0x025b72
	.byte 0xc3
	reti
	.byte 0xe4, 0xe0
	ldb	a, 191
	ldio	49, 201
	inc	6, de
	.byte 0x1f
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
	.byte 0x9f
	push_sr
	.byte 0xa0
	ld	(xbc), wa
	ld	xbc, (xsp+4)
	or	xbc, xbc
	jr	z, 12
	lda	xwa, (xsp+8)
	ld	xbc, (xbc+16)
	call	DrawBitmapFile
	jr	9
	lda	xwa, (xsp+8)
	lds32	xbc, 0
	call	DrawBitmap
	ld	wa, (xsp+8)
	add	wa, (xsp+2)
	st16_24	0x025b3a, wa
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
	ldi_werp 0xfa, 0

Seq_InitVoiceLoop:
	pushw 0xea
	pushw 0x4
	ldto_werp BC, 0xfa
	muls bc, 0x18
	lda_24 xwa, 0x0249d8
	st_dri3b W, 0x07, 0xe0, 0xe4
	push xwa
	call Strcpy
	inc 8, xsp
	ldto_werp WA, 0xfa
	muls wa, 0x18
	lda_24 xbc, 0x0249d8
	st_dri3b B, 0x07, 0xe4, 0xe0
	lds32 xwa, 0
	ld (xde + 16), xwa
	ldto_werp WA, 0xfa
	muls wa, 0x18
	st_dri3b A, 0x07, 0xe4, 0xe0
	lds32 xwa, 0
	ld (xbc + 20), xwa
	inc1_werp 0xfa
	cp_erpw 0xfa, 0x40, 0x00
	jr lt, Seq_InitVoiceLoop
	st16_24 0x025b82, xiz
	pop xiz
	ret

Seq_PostProcessDisplay:
	ld16_24	wa, 0x025b82
	jr	0

Seq_CopyResourcePtrs:
	lda_24 xde, 0x024fd8
	lda_24 xhl, Presentation_RootEntry_0x6
	ld xbc, xde
	st_dri3b B, 0xe9, 0xfc, 0x01

Seq_CopyPtrLoop:
	st_dpil XHL, 0xe6
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
	ld xbc, 0x1e10003
	ld xde, xiz
	call MainFuncCall
	ld xwa, 0x1400003
	ld xbc, 0x1e00023
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
	ld xiy, 0x00ea0028			; resource descriptor ptr
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
	pushw 0x00ea				; resource ID high
	pushw 0x0048				; resource ID low
	lda xwa, (xsp + 16)			; buffer
	push xwa
	call Strcat			; format/prepare
	lda xsp, (xsp + 16)			; clean stack (16 bytes)
	lda xwa, (xsp + 4)			; reload buffer
	ld xbc, 0x00ea004e			; resource descriptor
	call FileIO_OpenWithMode				; open display resource
	cps hl, 0
	jr lt, Seq_Epilogue32			; failed
	pushw 0x00ea
	pushw 0x0018
	ld xwa, 0x000248c8			; data source
	ld xbc, 0x00000100			; size 256
	ld xde, Presentation_TagStrTable			; destination descriptor
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
	stib_dpi	224, 32
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
	pushw 0x00ea
	pushw 0x0066				; resource ID
	push xwa
	call Strcat			; format/prepare
	lda xsp, (xsp + 22)			; clean stack
	lda xwa, (xsp + 4)
	ld xbc, 0x00ea006c			; resource descriptor
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
	st32_24 0x0249d0, xwa			; store result
	pushw 0x00ea
	pushw 0x005c
	ld xbc, xiz				; info ptr
	ld xde, 0x00ea0052			; destination descriptor
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

