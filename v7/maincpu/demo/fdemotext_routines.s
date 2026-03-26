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
	lda_24 xhl, (DemoDisk_LangPromptTable)
	ret

FDemoText_ReturnNull:
	lds32 xhl, 0
	ret

FDemoText_LookupTableEntry:
	.incbin "includes/generated/v7_transplant_FDemoText_LookupTableEntry.bin"
FDemoText_ByteData_VoiceProbeA:
	.incbin "includes/generated/v7_transplant_FDemoText_ByteData_VoiceProbeA.bin"
FDemoText_ByteData_VoiceProbeB:
	.incbin "includes/generated/v7_transplant_FDemoText_ByteData_VoiceProbeB.bin"
FDemoText_ByteData_VoiceProbeC:
	.incbin "includes/generated/v7_transplant_FDemoText_ByteData_VoiceProbeC.bin"
FDemoText_ProcessVoiceFlags:
	.incbin "includes/generated/v7_transplant_FDemoText_ProcessVoiceFlags.bin"
FDemoText_ProcessVoiceFlags_ReadState:
	.incbin "includes/generated/v7_transplant_FDemoText_ProcessVoiceFlags_ReadState.bin"
FDemoText_ProcessVoiceFlags_CheckBits:
	and a, 0x7
	call_24 nz, FDemoText_ScanMIDIChannels
	bitda_24 7, (0x0247ee)
	jr z, FDemoText_ProcessChannels
	stib_da (0x0247f2), 0x00
	ldib_erp 0xfb, 0

FDemoText_ProbeVoice_Loop:
	stb_erp A, 0xfb
	extz wa
	lda_24 xbc, (DemoDiskPrompt_English1_0x8A)
	ldb_sri C, 0x07, 0xe4, 0xe0
	ldb_erp C, 0xfa
	calr FDemoText_CheckVoiceState
	cps l, 1
	jr z, FDemoText_ProbeVoice_SetActive
	stb_erp A, 0xfa
	cpl a
	anddm8_24 (0x0247ee), a
	jr FDemoText_ProbeVoice_ClearActive

FDemoText_ProbeVoice_SetActive:
	stb_erp A, 0xfa
	ordm8_24 (0x0247ee), a

FDemoText_ProbeVoice_ClearActive:
	inc1b_erp 0xfb
	cpib_erp 0xfb, 2
	jr ule, FDemoText_ProbeVoice_Loop

FDemoText_ProcessChannels:
	ldib_erp 0xfb, 0

FDemoText_ProcessChannels_Loop:
	stb_erp A, 0xfb
	extz wa
	lda_24 xbc, (DemoDiskPrompt_English1_0x86)
	ldb_sri C, 0x07, 0xe4, 0xe0
	ldb_da e, (0x0247ee)
	and c, e
	jr z, FDemoText_ProcessChannel_CheckMask
	lda_24 xbc, (DemoDiskPrompt_English1_0x8A)
	ldb_sri C, 0x07, 0xe4, 0xe0
	and c, e
	jr z, FDemoText_ProcessChannel_CheckNoFlag
	calr FDemoText_CheckVoiceState
	cps l, 1
	jr nz, FDemoText_ProcessChannel_Activate
	stb_erp A, 0xfb
	extz wa
	calr FDemoText_ActivateVoice
	jr FDemoText_ProcessChannel_CheckMask

FDemoText_ProcessChannel_Activate:
	stb_erp A, 0xfb
	extz wa
	calr FDemoText_DeactivateVoice
	jr FDemoText_ProcessChannel_CheckMask

FDemoText_ProcessChannel_CheckNoFlag:
	calr FDemoText_CheckVoiceState
	stb_erp A, 0xfb
	extz wa
	cps l, 1
	jr nz, FDemoText_ProcessChannel_Deactivate
	calr FDemoText_ActivateVoiceAlt
	jr FDemoText_ProcessChannel_CheckMask

FDemoText_ProcessChannel_Deactivate:
	calr FDemoText_DeactivateVoice_RetOnly

FDemoText_ProcessChannel_CheckMask:
	stb_erp A, 0xfb
	extz wa
	lda_24 xbc, (DemoDiskPrompt_English1_0x86)
	ldb_sri C, 0x07, 0xe4, 0xe0
	andda8_24 c, (0x0247f2)
	call_24 nz, FDemoText_CheckAndSetTimer
	inc1b_erp 0xfb
	cpib_erp 0xfb, 2
	jr ule, FDemoText_ProcessChannels_Loop
	ldib_erp 0xfb, 0

FDemoText_ProcessOutputChannels:
	lda_24 xhl, (DemoDiskPrompt_English1_0x92)
	ldb_da c, (0x0247ec)
	bit 6, c
	jr z, FDemoText_ProcessOutput_CheckFlags
	stb_erp E, 0xfb
	extz de
	lda_24 xwa, (DemoDiskPrompt_English1_0x8A)
	ldb_sri A, 0x07, 0xe0, 0xe8
	andda8_24 a, (0x0247ee)
	jr z, FDemoText_ProcessOutput_CheckFlags
	or_srib_rm C, 0x07, 0xec, 0xe8
	stb_da (0x0247ec), c

FDemoText_ProcessOutput_CheckFlags:
	stb_erp A, 0xfb
	extz wa
	lda_24 xbc, (DemoDiskPrompt_English1_0x8A)
	ldb_sri C, 0x07, 0xe4, 0xe0
	andda8_24 c, (0x0247ee)
	jr z, FDemoText_ProcessOutput_NextCh
	lda_24 xbc, (DemoDiskPrompt_English1_0x8E)
	ldb_sri C, 0x07, 0xe4, 0xe0
	ldb_da e, (0x0247ec)
	and c, e
	jr z, FDemoText_ProcessOutput_AltUpdate
	calr FDemoText_SendVoiceParams
	jr FDemoText_ProcessOutput_NextCh

FDemoText_ProcessOutput_AltUpdate:
	ldb_sri C, 0x07, 0xec, 0xe0
	and c, e
	call_24 nz, FDemoText_UpdatePartialVoice

FDemoText_ProcessOutput_NextCh:
	inc1b_erp 0xfb
	cpib_erp 0xfb, 2
	jr ule, FDemoText_ProcessOutputChannels

FDemoText_ProcessOutput_ClearAll:
	stib_da (0x0247ec), 0x00
	stib_da (0x0247f2), 0x00
	anddi8_24 (0x0247ee), 120

FDemoText_ProcessVoiceFlags_Return:
	popw_erp 0xfa
	ret

FDemoText_ActivateVoice:
	dec 2, xsp
	ld (xsp), a
	ld a, (xsp)
	extz wa
	calr FDemoText_SendVoiceParams
	bitda_24 7, (0x0247ee)
	jr nz, FDemoText_ActivateVoice_Done
	ld a, (xsp)
	extz wa
	calr FDemoText_SyncVoicePreset

FDemoText_ActivateVoice_Done:
	inc 2, xsp
	ret

FDemoText_DeactivateVoice:
	extz wa
	lda_24 xbc, (DemoDiskPrompt_English1_0x8A)
	ldb_sri C, 0x07, 0xe4, 0xe0
	cpl c
	anddm8_24 (0x0247ee), c
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
	lda_24 xbc, (DemoDiskPrompt_English1_0x8A)
	ldb_sri A, 0x07, 0xe4, 0xe0
	ordm8_24 (0x0247ee), a
	inc 2, xsp
	ret

FDemoText_DeactivateVoice_RetOnly:
	ret

FDemoText_UpdateVoiceDisplay:
	.incbin "includes/generated/v7_transplant_FDemoText_UpdateVoiceDisplay.bin"
FDemoText_UpdateVoiceDisplay_CheckSend:
	ldb_da a, (0x0247ee)
	and a, 0x38
	jr nz, FDemoText_UpdateVoiceDisplay_Done
	ldb_d8 c, (0xfc26)
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
	pushw_erp 0xfa
	ld (xsp + 6), a
	lda_d16 xwa, (0xfc74)
	ld (xsp + 2), xwa
	ldb_da a, (0x0247ee)
	and a, 0x38
	jr z, FDemoText_SyncPreset_DirectCopy
	ldib_erp 0xfb, 0

FDemoText_SyncPreset_ActiveLoop:
	stb_erp A, 0xfb
	extz wa
	calr FDemoText_CheckVoiceState
	stb_erp A, 0xfb
	extz wa
	cps l, 1
	jr nz, FDemoText_SyncPreset_CallUpdate
	ld bc, wa
	lda_24 xde, (DemoDiskPrompt_English1_0x86)
	ldb_sri A, 0x07, 0xe8, 0xe0
	andda8_24 a, (0x0247ee)
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
	stb_d8 (0xfc26), a
	ldib_erp 0xfb, 0

FDemoText_SyncPreset_DirectLoop:
	stb_erp A, 0xfb
	extz wa
	calr FDemoText_UpdateChannelVoice
	inc1b_erp 0xfb
	cpib_erp 0xfb, 2
	jr ule, FDemoText_SyncPreset_DirectLoop

FDemoText_SyncPreset_Compare:
	ld a, (xsp + 6)
	extz wa
	lda_24 xbc, (0x0247f4)
	ldb_sri C, 0x07, 0xe4, 0xe0
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
	cps l, 1
	jr z, FDemoText_UpdateChannel_Active
	ld (xiz), 0x0
	pushw 0x7f
	lds bc, 5
	lds de, 0
	jr FDemoText_UpdateChannel_SendCmd

FDemoText_UpdateChannel_Active:
	.incbin "includes/generated/v7_transplant_FDemoText_UpdateChannel_Active.bin"
FDemoText_UpdateChannel_SendCmd:
	.incbin "includes/generated/v7_transplant_FDemoText_UpdateChannel_SendCmd.bin"
FDemoText_UpdateChannel_Done:
	pop xiz
	inc 2, xsp
	ret

FDemoText_CheckAndSetTimer:
	.incbin "includes/generated/v7_transplant_FDemoText_CheckAndSetTimer.bin"
FDemoText_CheckTimer_Done:
	pop xiz
	inc 2, xsp
	ret

FDemoText_ParseControlMessage:
	.incbin "includes/generated/v7_transplant_FDemoText_ParseControlMessage.bin"
FDemoText_ParseCtrl_Type82:
	ldw wa, 0x8
	call DemoMenu_BuildItemWorkspace
	ldb_da a, (0x020c39)
	srl a, 4
	and a, 0xf
	ld c, a
	extz bc
	lds wa, 5
	call DemoMenu_BuildItemWorkspace
	ldb_da c, (0x020c39)
	and c, 0xf
	extz bc
	lds wa, 3

FDemoText_ParseCtrl_BuildWorkspace:
	call DemoMenu_BuildItemWorkspace

FDemoText_ParseCtrl_SecondHalf:
	lda_24 xwa, (0x020c33)
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
	ldb_da a, (0x020c39)
	srl a, 4
	and a, 0xf
	ld c, a
	extz bc
	lds wa, 4
	call DemoMenu_BuildItemWorkspace
	ldb_da c, (0x020c39)
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
	ldb_da a, (0x020c39)
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
	stb_erp A, 0xfb
	ld (xde + 2), a
	ld xwa, (xsp + 2)
	ld a, (xwa)
	ld (xde + 4), a
	lds wa, 0
	lds bc, 6
	call sendCOMM
	lds32 xwa, 1
	add (xsp + 2), xwa
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x0c
	jr ule, FDemoText_SendParams_NoteLoop
	ld a, (xsp + 12)
	add a, 0x44
	extz wa
	calr FDemoText_LookupTableEntry
	ld (xsp + 2), xhl
	lds32 xwa, 3
	add (xsp + 2), xwa
	ldib_erp 0xfb, 4

FDemoText_SendParams_LevelLoop:
	.incbin "includes/generated/v7_transplant_FDemoText_SendParams_LevelLoop.bin"
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
	stb_erp A, 0xfb
	ld (xde + 2), a
	ld xwa, (xsp + 2)
	ld a, (xwa)
	ld (xde + 4), a
	lds wa, 0
	lds bc, 6
	call sendCOMM
	lds32 xwa, 1
	add (xsp + 2), xwa
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x0c
	jr ule, FDemoText_SendExtParams_NoteLoop
	ldib_erp 0xfb, 4

FDemoText_SendExtParams_LevelLoop:
	.incbin "includes/generated/v7_transplant_FDemoText_SendExtParams_LevelLoop.bin"
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
	stb_erp A, 0xfb
	ld (xde + 2), a
	ld xwa, (xsp + 2)
	ld a, (xwa)
	ld (xde + 4), a
	lds wa, 0
	lds bc, 6
	call sendCOMM
	lds32 xwa, 1
	add (xsp + 2), xwa
	inc1b_erp 0xfb
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
	popw_erp 0xfa
	lda xsp, (xsp + 22)
	ret

FDemoText_ProbeVoiceType:
	.incbin "includes/generated/v7_transplant_FDemoText_ProbeVoiceType.bin"
FDemoText_ByteData_ProbeHelper:
	.incbin "includes/generated/v7_transplant_FDemoText_ByteData_ProbeHelper.bin"
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
	lda_24 xbc, (DemoDiskPrompt_English1_0x8A)
	ldb_sri A, 0x07, 0xe4, 0xe0
	andda8_24 a, (0x0247f0)
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
	ldib_erp 0xfb, 0

FDemoText_ScanMIDI_LookupActive:
	ld a, (xsp + 4)
	extz wa
	lda_24 xde, (0x0247f4)
	lda_dri XHL, 0x07, 0xe8, 0xe0

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
	lda_24 xbc, (DemoDiskPrompt_English1_0x8A)
	exts xwa
	add xwa, xbc
	cpib_erp 0xfb, 1
	jr nz, FDemoText_ScanMIDI_ClearActive
	ld a, (xwa)
	ordm8_24 (0x0247f0), a
	jr FDemoText_ScanMIDI_NextChannel

FDemoText_ScanMIDI_SetActive:
	ldib_erp 0xfb, 1
	jr FDemoText_ScanMIDI_LookupActive

FDemoText_ScanMIDI_ClearActive:
	ld a, (xwa)
	cpl a
	anddm8_24 (0x0247f0), a

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
	stb_erp A, 0xfb
	extz wa
	lda_24 xbc, (DemoDiskPrompt_English1_0x8A)
	ldb_sri C, 0x07, 0xe4, 0xe0
	ldb_erp C, 0xfa
	calr FDemoText_CheckVoiceState
	cps l, 1
	jr z, FDemoText_Rescan_SetFlag
	stb_erp A, 0xfa
	cpl a
	anddm8_24 (0x0247ee), a
	jr FDemoText_Rescan_NextVoice

FDemoText_Rescan_SetFlag:
	stb_erp A, 0xfa
	ordm8_24 (0x0247ee), a

FDemoText_Rescan_NextVoice:
	inc1b_erp 0xfb
	cpib_erp 0xfb, 2
	jr ule, FDemoText_Rescan_Loop
	ldib_erp 0xfb, 0

FDemoText_Rescan_SendUpdates:
	stb_erp A, 0xfb
	extz wa
	lda_24 xbc, (DemoDiskPrompt_English1_0x8A)
	ldb_sri C, 0x07, 0xe4, 0xe0
	andda8_24 c, (0x0247ee)
	call_24 nz, FDemoText_SendVoiceParams
	inc1b_erp 0xfb
	cpib_erp 0xfb, 2
	jr ule, FDemoText_Rescan_SendUpdates
	popw_erp 0xfa
	ret

FDemoText_NotifyUIChange:
	.incbin "includes/generated/v7_transplant_FDemoText_NotifyUIChange.bin"
FDemoText_NotifyUI_Loop:
	.incbin "includes/generated/v7_transplant_FDemoText_NotifyUI_Loop.bin"
FDemoText_NotifyUI_Done:
	pop xiz
	ret

FDemoText_RefreshFullDisplay:
	.incbin "includes/generated/v7_transplant_FDemoText_RefreshFullDisplay.bin"
FDemoText_ByteData_DisplayRefresh:
	.incbin "includes/generated/v7_transplant_FDemoText_ByteData_DisplayRefresh.bin"
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
	.incbin "includes/generated/v7_transplant_FDemoText_ProcessMarkup_LookupTag.bin"
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
	.incbin "includes/generated/v7_transplant_FDemoText_ProcessMarkup_AllocCopy.bin"
FDemoText_ProcessMarkup_ParseAttrs:
	ld xbc, (xsp + 8)
	stb_dri A, 0x07, 0xe4, 0xec
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
	stl_dri XDE, 0x07, 0xe4, 0xf4
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
	.incbin "includes/generated/v7_transplant_FDemoText_ProcessMarkup_CallHandler.bin"
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
	lda_24 xwa, (DemoDiskPrompt_English1_0xB4)
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
	.incbin "includes/generated/v7_transplant_FDemoText_ProcessMarkup_CopyAndRender.bin"
FDemoText_ProcessMarkup_Done:
	ld xhl, xiz

FDemoText_ProcessMarkup_Return:
	pop xiz
	lda xsp, (xsp + 86)
	ret

FDemoText_ByteData_TextRenderer:
	.incbin "includes/generated/v7_transplant_FDemoText_ByteData_TextRenderer.bin"
FDemoText_TextDispatch:
	cps bc, 1
	jr z, FDemoText_TextDispatch_Return
	cps bc, 0
	call_24 z, FDemoText_RenderTextLine

FDemoText_TextDispatch_Return:
	lds hl, 0
	ret

FDemoText_ByteData_LayoutEngine:
	.incbin "includes/generated/v7_transplant_FDemoText_ByteData_LayoutEngine.bin"
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
	lda_24 xde, (0x0251da)

FDemoText_CalcExtent_ScanLoop:
	ld bc, wa
	add bc, ix
	cpib_sri 0x07, 0xe8, 0xe4, 0x54
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
	ldw_da xwa, (0x025b3e)
	sla wa, 2
	lda_24 xbc, (0x025b40)
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	call GetCenteredDelta
	ld iz, hl
	ldw_da xwa, (0x025b3e)
	sla wa, 2
	lda_24 xbc, (0x025b40)
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
	lda_24 xix, (0x0251da)
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
	cpib_sri 0x07, 0xf0, 0xe8, 0x54
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
	cpib_sri 0x07, 0xf0, 0xe4, 0x54
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
	ldw_da xwa, (0x025b3e)
	sla wa, 2
	lda_24 xbc, (0x025b40)
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	call GetCharHeight
	ld iz, hl
	ldw_da xwa, (0x025b3e)
	sla wa, 2
	lda_24 xbc, (0x025b40)
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	call GetCharDescent
	sub iz, hl
	lda_24 xde, (0x025b3c)
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
	.incbin "includes/generated/v7_transplant_FDemoText_Layout_Setup.bin"
FDemoText_Layout_NoWrap:
	ldw (xsp + 14), 0x0

FDemoText_Layout_ProcessLine:
	ldw_da xwa, (0x025b3e)
	sla wa, 2
	lda_24 xbc, (0x025b40)
	ld_sril3 XBC, 0x07, 0xe4, 0xe0
	ld xwa, (xsp + 6)
	call CalcTotalWidth
	ld (xsp + 8), hl
	cps iz, 0
	jr z, FDemoText_Layout_UpdatePosition
	lda_24 xbc, (0x025b74)
	ldw_da xwa, (0x025b72)
	ldb_sri A, 0x07, 0xe4, 0xe0
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
	ldw_da xde, (0x025b3e)
	sla de, 2
	lda_24 xhl, (0x025b40)
	ld_sril3 XDE, 0x07, 0xec, 0xe8
	push xde
	ldw_da xde, (0x025b60)
	sla de, 1
	lda_24 xhl, (0x025b62)
	push_sriw 0x07, 0xec, 0xe8
	pushw 0xf7
	ld xde, (xsp + 24)
	call DrawString

FDemoText_Layout_UpdatePosition:
	ld wa, (xsp + 20)
	add wa, (xsp + 8)
	stw_da (0x025b3a), xwa
	cpw (xsp + 14), 0x0
	jr z, FDemoText_Layout_FreeBuffer
	calr FDemoText_UpdateCursorPosition
	cps hl, 0
	jr z, FDemoText_Layout_FreeBuffer
	ld xwa, (xsp + 10)
	inc 1, xwa
	calr FDemoText_RenderTextLine

FDemoText_Layout_FreeBuffer:
	.incbin "includes/generated/v7_transplant_FDemoText_Layout_FreeBuffer.bin"
FDemoText_ByteData_LayoutB:
	.incbin "includes/generated/v7_transplant_FDemoText_ByteData_LayoutB.bin"
Seq_InitVoiceStructures:
	push xiz
	ld iz, wa
	stiw_da (0x025b7c), 0x0000
	lda_24 xwa, (0x0248c8)
	ld (xwa), 0x0
	stl_da (0x0248c4), xwa
	stl_da (0x0249c8), xwa
	ldiw_erp 0xfa, 0

Seq_InitVoiceLoop:
	.incbin "includes/generated/v7_transplant_Seq_InitVoiceLoop.bin"
Seq_PostProcessDisplay:
	ldw_da	wa, (0x025b82)
	jr	0

Seq_CopyResourcePtrs:
	lda_24 xde, (0x024fd8)
	lda_24 xhl, (Presentation_RootEntry_0x6)
	ld xbc, xde
	stb_dri B, 0xe9, 0xfc, 0x01

Seq_CopyPtrLoop:
	stl_dpi XHL, 0xe6
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
	stl_da (0x0249cc), xwa
	jr Seq_StoreResultAddr

Seq_UseFallbackAddr:
	ldl_da xwa, (0x0249d0)
	stl_da (0x0249cc), xwa

Seq_StoreResultAddr:
	ldl_da xwa, (0x0249cc)
	stl_da (0x0249d4), xwa
	ret

Seq_InitializeAndStart:
	.incbin "includes/generated/v7_transplant_Seq_InitializeAndStart.bin"
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
	.incbin "includes/generated/v7_transplant_Seq_LoadResource_Proceed.bin"
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
	.incbin "includes/generated/v7_transplant_Seq_FillBufferLoop.bin"
Seq_NamedResource_Epilogue:
	pop xiz
	lda xsp, (xsp + 32)
	ret


FDemoText_ProcessMarkupLoop:
	pushw iz
	ld iz, wa
	ldl_da xwa, (0x0249cc)
	stl_da (0x0249d4), xwa
	cp (xwa), 0x0
	jr z, FDemoText_MarkupDone

FDemoText_MarkupLoop:
	ldl_da xwa, (0x0249d4)
	ld bc, iz
	calr FDemoText_ProcessTextMarkup
	stl_da (0x0249d4), xhl
	ldl_da xwa, (0x0249d4)
	cp (xwa), 0x0
	jr nz, FDemoText_MarkupLoop

FDemoText_MarkupDone:
	lds hl, 0
	popw iz
	ret

