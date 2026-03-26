; =============================================================================
; Audio Control Engine
; =============================================================================
;
; MIDI stream processing, control panel LED management, voice/tone
; parameter control, and sound preset dispatch. This is the main
; bridge between the UI layer and the SubCPU audio engine.
; =============================================================================

	ld a, e
	and a, 0xf
	jr z, FileIO_ShiftD
	srla d

FileIO_ShiftD:
	ld a, e
	and a, 0xf
	jr z, FileIO_CallbackHandler
	srla l

; File I/O callback handler
FileIO_CallbackHandler:
	cps l, 0
	jr z, FileIO_AdvancePointer
	ld a, (xiz + 1)
	ld (xbc + 1), a
	ld (xbc + 2), d
	ld (xbc + 3), l
	ld xhl, (xiz + 4)
	ld xwa, xbc
	call (xhl)

FileIO_AdvancePointer:
	inc 8, xiz

FileIO_MainLoop:
	.incbin "includes/generated/v7_transplant_FileIO_MainLoop.bin"
FileIO_BytecodeData:
	.incbin "includes/generated/v7_transplant_FileIO_BytecodeData.bin"
ExtDev_SndParam_Block48_Var40:
	.incbin "includes/generated/v7_transplant_ExtDev_SndParam_Block48_Var40.bin"
ExtDev_SndParam_Block48_Var80:
	.incbin "includes/generated/v7_transplant_ExtDev_SndParam_Block48_Var80.bin"
ExtDev_SndParam_Block48_Var04:
	.incbin "includes/generated/v7_transplant_ExtDev_SndParam_Block48_Var04.bin"
ExtDev_SndParam_Block48_Var04_B:
	.incbin "includes/generated/v7_transplant_ExtDev_SndParam_Block48_Var04_B.bin"
ExtDev_SndParam_Write98_Block:
	.incbin "includes/generated/v7_transplant_ExtDev_SndParam_Write98_Block.bin"
ExtDev_SndParam_Block98_Var40:
	.incbin "includes/generated/v7_transplant_ExtDev_SndParam_Block98_Var40.bin"
ExtDev_SndParam_BlockA9_Var02:
	.incbin "includes/generated/v7_transplant_ExtDev_SndParam_BlockA9_Var02.bin"
ExtDev_SndParam_Block98_Var80:
	.incbin "includes/generated/v7_transplant_ExtDev_SndParam_Block98_Var80.bin"
ExtDev_SndParam_Block98_Var40_B:
	.incbin "includes/generated/v7_transplant_ExtDev_SndParam_Block98_Var40_B.bin"
ExtDev_SndParam_ConfigAndWrite:
	.incbin "includes/generated/v7_transplant_ExtDev_SndParam_ConfigAndWrite.bin"
ExtDev_SndParam_Block14_Dual:
	.incbin "includes/generated/v7_transplant_ExtDev_SndParam_Block14_Dual.bin"
ExtDev_SndParam_Write48_Block:
	.incbin "includes/generated/v7_transplant_ExtDev_SndParam_Write48_Block.bin"
ExtDev_SndParam_Block48_Var02:
	.incbin "includes/generated/v7_transplant_ExtDev_SndParam_Block48_Var02.bin"
ExtDev_SndParam_Block70_Var04:
	.incbin "includes/generated/v7_transplant_ExtDev_SndParam_Block70_Var04.bin"
ExtDev_SndParam_DispatchAndWriteA8:
	.incbin "includes/generated/v7_transplant_ExtDev_SndParam_DispatchAndWriteA8.bin"
ExtDev_SndParam_DispatchAndWriteA8_Alt:
	.incbin "includes/generated/v7_transplant_ExtDev_SndParam_DispatchAndWriteA8_Alt.bin"
ExtDev_SndParam_MultiReg_Iterate:
	.incbin "includes/generated/v7_transplant_ExtDev_SndParam_MultiReg_Iterate.bin"
ExtDev_SndParam_DispatchComplex:
	.incbin "includes/generated/v7_transplant_ExtDev_SndParam_DispatchComplex.bin"
VoiceEntry_FindMasterVolume:
	.incbin "includes/generated/v7_transplant_VoiceEntry_FindMasterVolume.bin"
VoiceEntry_CheckMatch:
	cp (xde), 0x98
	jr nz, VoiceEntryLoop_Continue
	cp (xde + 1), 0x1
	jr nz, VoiceEntryLoop_Continue
	cp (xde + 3), 0x7f
	jr nz, VoiceEntryLoop_Continue
	or xbc, xbc
	jr z, VoiceEntry_SaveMatch
	ld (xbc + 3), 0x0

VoiceEntry_SaveMatch:
	ld xbc, xde

VoiceEntryLoop_Continue:
	inc 1, wa
	inc 4, xde
	cp wa, 0xf
	ret nc

VoiceEntry_CheckTerminator:
	cp (xde), 0xff
	jr nz, VoiceEntry_CheckMatch
	ret

Audio_CopyStateFromROM:
	.incbin "includes/generated/v7_transplant_Audio_CopyStateFromROM.bin"
AudioCopy_TransferLoop:
	ld xiy, xwa
	ld xix, xde
	ldiw
	ldiw
	inc 4, xwa
	inc 4, xde
	cp xwa, xhl
	jr c, AudioCopy_TransferLoop
	ret

Audio_NullHandler_A:
	ret

Audio_NullHandler_B:
	ret

Audio_NullHandler_C:
	ret

Encoder_TimingAndOutput:
	.incbin "includes/generated/v7_transplant_Encoder_TimingAndOutput.bin"
Encoder_CheckTimerDelta:
	.incbin "includes/generated/v7_transplant_Encoder_CheckTimerDelta.bin"
Encoder_CheckBitAndProcess:
	.incbin "includes/generated/v7_transplant_Encoder_CheckBitAndProcess.bin"
Encoder_ProcessUpdate:
	calr Audio_PeriodicUpdate

Encoder_IncrementAndDispatch:
	.incbin "includes/generated/v7_transplant_Encoder_IncrementAndDispatch.bin"
Audio_PeriodicUpdate:
	.incbin "includes/generated/v7_transplant_Audio_PeriodicUpdate.bin"
Audio_ProcessVoiceQueue:
	.incbin "includes/generated/v7_transplant_Audio_ProcessVoiceQueue.bin"
VoiceQueue_ParseNextEntry:
	.incbin "includes/generated/v7_transplant_VoiceQueue_ParseNextEntry.bin"
VoiceQueue_Done:
	pop xiz
	ret

MIDI_ParseThreeByteParams:
	dec 2, xsp
	push xiz
	ld xiz, xwa
	ld (xsp + 4), 0xff
	call Seq_DataHandler
	cp hl, 0xffff
	jr z, MidiParseThreeByte_Done
	extz hl
	ld wa, hl
	calr MidiCC_LookupHandler
	ld (xiz), l
	call Seq_DataHandler
	cp hl, 0xffff
	jr z, MidiParseThreeByte_Done
	ld (xiz + 1), l
	call Seq_DataHandler
	cp hl, 0xffff
	jr z, MidiParseThreeByte_Done
	ld (xiz + 2), l
	ld (xsp + 4), 0x0

MidiParseThreeByte_Done:
	ld l, (xsp + 4)
	pop xiz
	inc 2, xsp
	ret

MIDI_ProcessVoiceAssignment:
	.incbin "includes/generated/v7_transplant_MIDI_ProcessVoiceAssignment.bin"
MIDI_ValidateParam:
	.incbin "includes/generated/v7_transplant_MIDI_ValidateParam.bin"
MIDI_WriteSecondByte:
	.incbin "includes/generated/v7_transplant_MIDI_WriteSecondByte.bin"
MIDI_WriteParamByte:
	lda xsp, (xsp - 10)
	push xiz
	lda xhl, (xwa + 1)
	cp (xwa), 0x1d
	jr nz, MIDI_ChannelSetup_Skip
	ld e, c
	and e, 0xf
	cp e, 0xf
	jr nz, MIDI_ChannelSetup_Skip
	xor c, 0xf
	ld (xhl), c
	jr MIDI_ChannelSetup_Store

MIDI_ChannelSetup_Skip:
	ld (xhl), c

MIDI_ChannelSetup_Store:
	.incbin "includes/generated/v7_transplant_MIDI_ChannelSetup_Store.bin"
MIDI_ChannelSetup_Init:
	.incbin "includes/generated/v7_transplant_MIDI_ChannelSetup_Init.bin"
VoiceData_Setup_Ret:
	pop xiz
	lda xsp, (xsp + 10)
	ret

MIDI_ProcessControlChange:
	.incbin "includes/generated/v7_transplant_MIDI_ProcessControlChange.bin"
MidiCC_ProcessParam:
	.incbin "includes/generated/v7_transplant_MidiCC_ProcessParam.bin"
MidiCC_SkipEntry:
	pop xiz
	ret

MidiCC_LookupHandler:
	ld c, a
	and c, 0x1f
	and a, 0xc0
	srl a, 1
	or a, c
	extz wa
	lda_24 xbc, (EffectMode_DispatchTable_0x10)
	ldb_sri L, 0x07, 0xe4, 0xe0
	ret

Voice_SetupFromData:
	.incbin "includes/generated/v7_transplant_Voice_SetupFromData.bin"
MidiCC_ValidateRange:
	.incbin "includes/generated/v7_transplant_MidiCC_ValidateRange.bin"
MidiCC_StoreAndDispatch:
	.incbin "includes/generated/v7_transplant_MidiCC_StoreAndDispatch.bin"
MidiCC_CheckOverflow:
	ld xwa, xiz
	call EffectMode_MidiSetLEDs
	jr MIDI_PopIzRet

MidiCC_Finalize:
	.incbin "includes/generated/v7_transplant_MidiCC_Finalize.bin"
MidiCC_Return:
	jr MIDI_PopIzRet

MidiCC_ReturnClean:
	.incbin "includes/generated/v7_transplant_MidiCC_ReturnClean.bin"
MIDI_PopIzRet:
	pop xiz
	ret

MidiCC_SyncForceResync:
	.incbin "includes/generated/v7_transplant_MidiCC_SyncForceResync.bin"
MidiCC_ResetState:
	.incbin "includes/generated/v7_fix_midicc_resetstate.bin"
	.include "midi/midi_encoder_routines.s"

MidiParam_ForceResync:
	.incbin "includes/generated/v7_transplant_MidiParam_ForceResync.bin"
MidiChannel_GetParamByIndex:
	cps a, 3
	jr z, MidiChannel_GetParam3
	cps a, 2
	jr z, MidiChannel_GetParam2
	cps a, 1
	jr z, MidiChannel_GetParam1
	cps a, 0
	jr nz, MidiChannel_GetParamReturn
	lda_d16 xbc, (288)
	jr MidiChannel_GetParamReturn

MidiChannel_GetParam1:
	lda_d16 xbc, (290)
	jr MidiChannel_GetParamReturn

MidiChannel_GetParam2:
	lda_d16 xbc, (292)
	jr MidiChannel_GetParamReturn

MidiChannel_GetParam3:
	lda_d16 xbc, (294)

MidiChannel_GetParamReturn:
	ld l, (xbc + 1)
	ret

MidiParam_ProcessDeltas:
	.incbin "includes/generated/v7_transplant_MidiParam_ProcessDeltas.bin"
MidiParam_ProcessChannel0:
	.incbin "includes/generated/v7_transplant_MidiParam_ProcessChannel0.bin"
MidiParam_Ch0_Done:
	popw_erp 0xfa
	inc 4, xsp
	ret

MidiParam_ProcessChannel1:
	.incbin "includes/generated/v7_transplant_MidiParam_ProcessChannel1.bin"
MidiParam_Ch1_Done:
	popw_erp 0xfa
	inc 4, xsp
	ret

MIDI_ComputeParamDelta:
	.incbin "includes/generated/v7_transplant_MIDI_ComputeParamDelta.bin"
MidiParam_DeltaMedium:
	ld xwa, (xsp)
	bitm 2, (xwa)
	jr z, MidiParam_DeltaStartDebounce

MidiParam_DeltaConfirmed:
	ld xwa, (xsp)
	andmi8 (xwa), 0xfc
	resm 2, (xwa)
	setm 3, (xwa)
	jr MidiParam_DeltaDone

MidiParam_DeltaStartDebounce:
	ld xwa, (xsp)
	setm 2, (xwa)
	jr MidiParam_DeltaDone

MidiParam_DeltaTooSmall:
	ld xwa, (xsp)
	andmi8 (xwa), 0xfc

MidiParam_DeltaClearActive:
	ld xwa, (xsp)
	resm 2, (xwa)

MidiParam_DeltaDone:
	inc 8, xsp
	ret

Audio_UpdateLEDsAndChannels:
	.incbin "includes/generated/v7_transplant_Audio_UpdateLEDsAndChannels.bin"
MIDI_ProcessChangedChannels:
	.incbin "includes/generated/v7_transplant_MIDI_ProcessChangedChannels.bin"
MidiChanged_ProcessGroup2:
	.incbin "includes/generated/v7_transplant_MidiChanged_ProcessGroup2.bin"
MidiChanged_ProcessGroup3:
	.incbin "includes/generated/v7_transplant_MidiChanged_ProcessGroup3.bin"
MidiChanged_ProcessGroup4:
	.incbin "includes/generated/v7_transplant_MidiChanged_ProcessGroup4.bin"
MidiChannel_DispatchChanged:
	.incbin "includes/generated/v7_transplant_MidiChannel_DispatchChanged.bin"
MidiDispatch_CheckGroup2:
	.incbin "includes/generated/v7_transplant_MidiDispatch_CheckGroup2.bin"
MidiDispatch_CheckGroup3:
	.incbin "includes/generated/v7_transplant_MidiDispatch_CheckGroup3.bin"
MidiDispatch_CheckGroup4:
	.incbin "includes/generated/v7_transplant_MidiDispatch_CheckGroup4.bin"
MidiDispatch_UpdateLEDs:
	jrl CtrlPanel_UpdateLEDState

Audio_InitChannelTimers:
	.incbin "includes/generated/v7_transplant_Audio_InitChannelTimers.bin"
Audio_IncrementUpdateCounter:
	.incbin "includes/generated/v7_transplant_Audio_IncrementUpdateCounter.bin"
Audio_CheckAndFlagChanges:
	.incbin "includes/generated/v7_transplant_Audio_CheckAndFlagChanges.bin"
AudioChange_CheckSelectionState:
	.incbin "includes/generated/v7_transplant_AudioChange_CheckSelectionState.bin"
AudioChange_UpdatePreviousSelect:
	.incbin "includes/generated/v7_transplant_AudioChange_UpdatePreviousSelect.bin"
AudioChange_SetChannelFlag:
	.incbin "includes/generated/v7_transplant_AudioChange_SetChannelFlag.bin"
DispatchBitmaskHandlers:
	dec 2, xsp
	push xiz
	ld xiz, xbc
	ld (xsp + 4), wa
	cpw (xiz), 0xffff
	jr z, BitmaskDispatch_Return

; Bitmask dispatch loop handler
BitmaskDispatch_LoopHandler:
	ld wa, (xsp + 4)
	and wa, (xiz)
	jr z, BitmaskDispatch_NextEntry
	ld xhl, (xiz + 2)
	call (xhl)

BitmaskDispatch_NextEntry:
	inc 6, xiz
	cpw (xiz), 0xffff
	jr nz, BitmaskDispatch_LoopHandler

BitmaskDispatch_Return:
	pop xiz
	inc 2, xsp
	ret


; This routine seems to set the LEDs of the control panel
; I'm not sure yet if this is initialization, or if it
; also serves to update the LEDs later on.
CtrlPanel_UpdateLEDState:
	.incbin "includes/generated/v7_transplant_CtrlPanel_UpdateLEDState.bin"
LEDUpdate_ProcessChannel:
	stb_erp A, 0xfb
	extz wa
	ld xbc, (xsp + 2)
	ldb_sri C, 0x07, 0xe4, 0xe0
	ldb_erp C, 0xfa
	ld xbc, (xsp + 6)
	ldb_sri C, 0x07, 0xe4, 0xe0
	cpb_erp C, 0xfa
	jr z, LEDUpdate_NextChannel
	stb_erp C, 0xfa
	extz bc
	calr Set_LEDs
	stb_erp E, 0xfb
	extz de
	ld xwa, (xsp + 6)
	stb_erp C, 0xfa
	lda_dri XHL, 0x07, 0xe0, 0xe8

LEDUpdate_NextChannel:
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x0f
	jr c, LEDUpdate_ProcessChannel

LEDUpdate_Cleanup:
	popw_erp 0xfa
	inc 8, xsp
	ret


Set_LEDs:
	.incbin "includes/generated/v7_transplant_Set_LEDs.bin"
LED_WriteToPanel:
	push xiz
	ld xiz, xwa
	ld a, (xiz)
	extz wa
	pushw wa
	call Seq_TimerEventLoop
	inc 2, xsp
	cp hl, 0xffff
	jr nz, LED_WriteSecondByte
	push xde
	push xhl
	push xix
	push xiz
	call CPanel_Poll
	pop xiz
	pop xix
	pop xhl
	pop xde
	ld xwa, xiz
	jr LED_WriteThirdByte

LED_WriteSecondByte:
	ld a, (xiz + 1)
	extz wa
	pushw wa
	call Seq_TimerEventLoop
	inc 2, xsp
	cp hl, 0xffff
	jr nz, LED_WriteDone
	push xde
	push xhl
	push xix
	push xiz
	call CPanel_Poll
	pop xiz
	pop xix
	pop xhl
	pop xde
	lda xwa, (xiz + 1)

LED_WriteThirdByte:
	ld a, (xwa)
	extz wa
	pushw wa
	call Seq_TimerEventLoop
	inc 2, xsp

LED_WriteDone:
	pop xiz
	ret


SndParam_SetResBit0_Via028100:
	.incbin "includes/generated/v7_transplant_SndParam_SetResBit0_Via028100.bin"
SndParam028100_ResBit0:
	.byte 0xb0, 0xb0				; res 0, (xwa)  [not in LLVM]
SndParam028100_Done:
	pop xiz
	ret
SndParam_SetResBit1_ViaRegs0100_0101:
	.incbin "includes/generated/v7_transplant_SndParam_SetResBit1_ViaRegs0100_0101.bin"
SndParam028101_SetBit1:
	setm	1, (xiz+4)
	jr t, SndParam028101_Done
SndParam028101_ResBit1:
	.byte 0xbe, 0x04, 0xb1				; res 1, (xiz+4)  [not in LLVM]
SndParam028101_Done:
	pop xiz
	ret
SndParam_SetResBit2_ViaRegs0101_0102:
	.incbin "includes/generated/v7_transplant_SndParam_SetResBit2_ViaRegs0101_0102.bin"
SndParam028102_SetBit2:
	setm	2, (xiz+4)
	jr t, SndParam028102_Done
SndParam028102_ResBit2:
	.byte 0xbe, 0x04, 0xb2				; res 2, (xiz+4)  [not in LLVM]
SndParam028102_Done:
	pop xiz
	ret


SndParam_SetResBit3_ViaRegs0101_0102:
	.incbin "includes/generated/v7_transplant_SndParam_SetResBit3_ViaRegs0101_0102.bin"
SndParam028102_SetBit3:
	setm	3, (xiz+4)
	jr t, SndParam028102_Done2
SndParam028102_ResBit3:
	.byte 0xbe, 0x04, 0xb3				; res 3, (xiz+4)  [not in LLVM]
SndParam028102_Done2:
	pop xiz
	ret
SndParam_SetResBit3_Via4002:
	.incbin "includes/generated/v7_transplant_SndParam_SetResBit3_Via4002.bin"
SndParam4002_ResBit3:
	.byte 0xb0, 0xb3				; res 3, (xwa)  [not in LLVM]
SndParam4002_Done:
	pop xiz
	ret
SndParam_SetResBit4_Via4004:
	.incbin "includes/generated/v7_transplant_SndParam_SetResBit4_Via4004.bin"
SndParam4004_ResBit4:
	.byte 0xb0, 0xb4				; res 4, (xwa)  [not in LLVM]
SndParam4004_Done:
	pop xiz
	ret


SndParam_TableLookup_Via4100:
	.incbin "includes/generated/v7_transplant_SndParam_TableLookup_Via4100.bin"
SndParam_SetResBit1_ViaPartCC5E:
	.incbin "includes/generated/v7_transplant_SndParam_SetResBit1_ViaPartCC5E.bin"
SndParamCC5E_ResBit1:
	.byte 0xb0, 0xb1				; res 1, (xwa)  [not in LLVM]
SndParamCC5E_Done:
	pop xiz
	ret


SndParam_SetResBit2_ViaPartCC5D:
	.incbin "includes/generated/v7_transplant_SndParam_SetResBit2_ViaPartCC5D.bin"
SndParamCC5D_ResBit2:
	resm	2, (xiz+6)
	jr t, SndParamCC5D_Done
SndParamCC5D_SetBit2:
	.byte 0xbe, 0x06, 0xba				; set 2, (xiz+6)  [not in LLVM]
SndParamCC5D_Done:
	pop xiz
	ret
SndParam_SetResBit0_ViaPartCC40:
	.incbin "includes/generated/v7_transplant_SndParam_SetResBit0_ViaPartCC40.bin"
SndParamCC40_ResBit0:
	.byte 0xb0, 0xb0				; res 0, (xwa)  [not in LLVM]
SndParamCC40_Done:
	pop xiz
	ret
SndParam_GuardedNibbleSet_ViaReg0103:
	.incbin "includes/generated/v7_transplant_SndParam_GuardedNibbleSet_ViaReg0103.bin"
MidiCtrl_PopIzRet:
	pop xiz
	ret
SndParam_SetResBit0_Via028103:
	.incbin "includes/generated/v7_transplant_SndParam_SetResBit0_Via028103.bin"
SndParam028103_ResBit0:
	.byte 0xb0, 0xb0				; res 0, (xwa)  [not in LLVM]
SndParam028103_Done:
	pop xiz
	ret
SndParam_SetResBit5_Via028080:
	.incbin "includes/generated/v7_transplant_SndParam_SetResBit5_Via028080.bin"
SndParam028080_SetBit5:
	.byte 0xb0, 0xbd				; set 5, (xwa)  [not in LLVM]
SndParam028080_Done:
	pop xiz
	ret


SndParam_VoiceEntryLookup_ViaReg8000:
	.incbin "includes/generated/v7_transplant_SndParam_VoiceEntryLookup_ViaReg8000.bin"
SndParam028000_GetBankBit:
	ld a, (xwa+1)
	and a, 0x03
	extz wa
SndParam028000_LookupAndMerge:
	call CtrlPanel_LookupIndicatorEntry
	and l, 0x0f
	andmi8	(xiz+3), 240
	or (xiz+3), l
	pop xiz
	inc 6, xsp
	ret
SndParam_SetResBit7_Via4200:
	.incbin "includes/generated/v7_transplant_SndParam_SetResBit7_Via4200.bin"
SndParam4200_ResBit7:
	.byte 0xb0, 0xb7				; res 7, (xwa)  [not in LLVM]
SndParam4200_Done:
	pop xiz
	ret
SndParam_MaskShiftMerge_8F58:
	.incbin "includes/generated/v7_transplant_SndParam_MaskShiftMerge_8F58.bin"
SndParam_DecrLookup_Via0300:
	.incbin "includes/generated/v7_transplant_SndParam_DecrLookup_Via0300.bin"
SndParam0300_DecrAndMask:
	dec 1, l
	and l, 0x07
	extz	hl
	ld	wa, hl
	call CtrlPanel_LookupIndicatorEntry
SndParam0300_StoreLookup:
	ld (xiz+9), l
	pop xiz
	ret


SndParam_SetResBit4_Via0400:
	.incbin "includes/generated/v7_transplant_SndParam_SetResBit4_Via0400.bin"
SndParam0400_ResBit4:
	.byte 0xb0, 0xb4				; res 4, (xwa)  [not in LLVM]
SndParam0400_Done:
	pop xiz
	ret
SndParam_SetResBit7_ViaSelection:
	.incbin "includes/generated/v7_transplant_SndParam_SetResBit7_ViaSelection.bin"
SndParamSelect_SetBit7:
	.byte 0xb6, 0xbf				; set 7, (xiz)  [not in LLVM]
CtrlPanel_SetResBit7_Ret:
	pop xiz
	ret
SndParam_SetResBit7_ViaF9A541:
	.incbin "includes/generated/v7_transplant_SndParam_SetResBit7_ViaF9A541.bin"
SndParamF9A541_ResBit7:
	.byte 0xb0, 0xb7				; res 7, (xwa)  [not in LLVM]
SndParamF9A541_Done:
	pop xiz
	ret


ExtData_VoiceParam_DispatchBytecode:
	.incbin "includes/generated/v7_transplant_ExtData_VoiceParam_DispatchBytecode.bin"
CtrlPanel_SetResBit6_ViaLookup:
	.incbin "includes/generated/v7_transplant_CtrlPanel_SetResBit6_ViaLookup.bin"
CtrlPanel_ResBit6:
	.byte 0xb6, 0xb6				; res 6, (xiz)  [not in LLVM]
CtrlPanel_Bit6Done:
	pop xiz
	ret
CtrlPanel_MultiWayBitManip_ViaE0:
	.incbin "includes/generated/v7_transplant_CtrlPanel_MultiWayBitManip_ViaE0.bin"
CtrlPanel_SetBit1:
	and a, 0xf9
	set 1, a
	ld (xbc), a
	jr t, CtrlPanel_BitManip_Ret
CtrlPanel_ClearBits1_2:
	andmi8	(xbc), 249
	jr t, CtrlPanel_BitManip_Ret
CtrlPanel_SetBit2:
	and a, 0xf9
	set 2, a
	ld (xbc), a
CtrlPanel_BitManip_Ret:
	pop xiz
	ret
CtrlPanel_SyncBit0_From8F5C:
	.incbin "includes/generated/v7_transplant_CtrlPanel_SyncBit0_From8F5C.bin"
CtrlPanel_ResBit0_8F5C:
	resm	0, (xwa)
	ret
CtrlPanel_SetBit3_OnStyleD0D3:
	.incbin "includes/generated/v7_transplant_CtrlPanel_SetBit3_OnStyleD0D3.bin"
CtrlPanel_SetBit3:
	setm	3, (xwa)
	ret
CtrlPanel_SetResBit0_ViaLookup4:
	.incbin "includes/generated/v7_transplant_CtrlPanel_SetResBit0_ViaLookup4.bin"
CtrlPanelLookup4_ResBit0:
	.byte 0xb0, 0xb0				; res 0, (xwa)  [not in LLVM]
CtrlPanelLookup4_Done:
	pop xiz
	ret
CtrlPanel_SetResBit1_ViaLookup56:
	.incbin "includes/generated/v7_transplant_CtrlPanel_SetResBit1_ViaLookup56.bin"
CtrlPanelLookup56_ResBit1:
	.byte 0xb0, 0xb1				; res 1, (xwa)  [not in LLVM]
CtrlPanelLookup56_Done:
	pop xiz
	ret
CtrlPanel_SetResBit2_ViaLookup50:
	.incbin "includes/generated/v7_transplant_CtrlPanel_SetResBit2_ViaLookup50.bin"
CtrlPanelLookup50_ResBit2:
	.byte 0xb0, 0xb2				; res 2, (xwa)  [not in LLVM]
CtrlPanelLookup50_Done:
	pop xiz
	ret
CtrlPanel_SetResBit3_ViaLookup52:
	.incbin "includes/generated/v7_transplant_CtrlPanel_SetResBit3_ViaLookup52.bin"
CtrlPanelLookup52_ResBit3:
	.byte 0xb0, 0xb3				; res 3, (xwa)  [not in LLVM]
CtrlPanelLookup52_Done:
	pop xiz
	ret
CtrlPanel_GuardedNibbleSet_8F4E:
	.incbin "includes/generated/v7_transplant_CtrlPanel_GuardedNibbleSet_8F4E.bin"
CtrlPanelGuard_PassedCheck:
	.incbin "includes/generated/v7_transplant_CtrlPanelGuard_PassedCheck.bin"
CtrlPanelGuard_ClearNibble:
	.byte 0x80
	push	xix
	.byte 0xf0
CtrlPanel_BitOp_Cleanup:
	pop xiz
	ret
CtrlPanel_SetResBit0_ViaLookup4C:
	.incbin "includes/generated/v7_transplant_CtrlPanel_SetResBit0_ViaLookup4C.bin"
CtrlPanelLookup4C_ResBit0:
	.byte 0xb0, 0xb0				; res 0, (xwa)  [not in LLVM]
CtrlPanelLookup4C_Done:
	pop xiz
	ret
CtrlPanel_SetResBit7_ViaLookup4C:
	.incbin "includes/generated/v7_transplant_CtrlPanel_SetResBit7_ViaLookup4C.bin"
CtrlPanelBit7_Res:
	.byte 0xb6, 0xb7				; res 7, (xiz)  [not in LLVM]
CtrlPanelBit7_Done:
	pop xiz
	ret
CtrlPanel_SetResBit5_ViaLookup4C:
	.incbin "includes/generated/v7_transplant_CtrlPanel_SetResBit5_ViaLookup4C.bin"
CtrlPanelBit5_Res:
	.byte 0xb6, 0xb5				; res 5, (xiz)  [not in LLVM]
CtrlPanelBit5_Done:
	pop xiz
	ret
CtrlPanel_SetResBit6_ViaLookup4C:
	.incbin "includes/generated/v7_transplant_CtrlPanel_SetResBit6_ViaLookup4C.bin"
CtrlPanelBit6_Res:
	.byte 0xb6, 0xb6				; res 6, (xiz)  [not in LLVM]
CtrlPanelBit6_Done:
	pop xiz
	ret


; ============================================================================
; CtrlPanel_SetIndicatorBit - Set a control panel LED indicator bit
; ============================================================================
; Input:  A = key code (upper nibble=group, lower nibble=bit index)
; Output: ORs bitmask into panel LED register (36666/36670/36674/36678)
; Looks up bitmask from table at 0xeda66c.
; ============================================================================
CtrlPanel_SetIndicatorBit:
	.incbin "includes/generated/v7_transplant_CtrlPanel_SetIndicatorBit.bin"
CtrlPanel_SetIndicator_Group2:
	.incbin "includes/generated/v7_transplant_CtrlPanel_SetIndicator_Group2.bin"
CtrlPanel_SetIndicator_Group3:
	.incbin "includes/generated/v7_transplant_CtrlPanel_SetIndicator_Group3.bin"
CtrlPanel_SetIndicator_Group4:
	.incbin "includes/generated/v7_transplant_CtrlPanel_SetIndicator_Group4.bin"
CtrlPanel_PopRetFA:
	popw_erp 0xfa
	ret

CtrlPanel_IndicatorDispatch:
	.incbin "includes/generated/v7_transplant_CtrlPanel_IndicatorDispatch.bin"
CtrlPanel_DispIndicator_Group2:
	.incbin "includes/generated/v7_transplant_CtrlPanel_DispIndicator_Group2.bin"
CtrlPanel_DispIndicator_Group3:
	.incbin "includes/generated/v7_transplant_CtrlPanel_DispIndicator_Group3.bin"
CtrlPanel_DispIndicator_Group4:
	.incbin "includes/generated/v7_transplant_CtrlPanel_DispIndicator_Group4.bin"
CtrlPanel_PopRetFA2:
	popw_erp 0xfa
	ret

CtrlPanel_SetIndicatorLED:
	.incbin "includes/generated/v7_transplant_CtrlPanel_SetIndicatorLED.bin"
CtrlPanel_SetLED_Group2:
	.incbin "includes/generated/v7_transplant_CtrlPanel_SetLED_Group2.bin"
CtrlPanel_SetLED_Group3:
	.incbin "includes/generated/v7_transplant_CtrlPanel_SetLED_Group3.bin"
MidiChOutState_Return:
	popw_erp 0xfa
	ret

MidiChannel_ProcessOutputState:
	.incbin "includes/generated/v7_transplant_MidiChannel_ProcessOutputState.bin"
MidiChOut_CheckHWState:
	.incbin "includes/generated/v7_transplant_MidiChOut_CheckHWState.bin"
MidiChOut_Mode6or3_Mask7:
	and l, 0x7
	ld xwa, Protocol_values_for_LED_rows_0x38
	jr MidiChOut_TableLookup

MidiChOut_OtherMode_Mask3:
	and l, 0x3
	ld xwa, Protocol_values_for_LED_rows_0x3E

MidiChOut_TableLookup:
	extz hl
	ldb_sri A, 0x07, 0xe0, 0xec
	and a, 0xf
	andmi8 (xde), 0xf0
	or (xde), a
	jr MidiChannel_CleanupRet

MidiChOut_CheckBit1Clear:
	.incbin "includes/generated/v7_transplant_MidiChOut_CheckBit1Clear.bin"
MidiChOut_ClearLowNibble:
	andmi8 (xde), 0xf0

MidiChannel_CleanupRet:
	pop xiz
	ret

MidiChOut_DetectChanges:
	.incbin "includes/generated/v7_transplant_MidiChOut_DetectChanges.bin"
MidiChannel_ScanPending:
	.incbin "includes/generated/v7_transplant_MidiChannel_ScanPending.bin"
MidiScan_CheckBit2InAddr1057:
	bitda 2, (1057)
	jr nz, MidiScan_PopIzRet

MidiScan_ClearAndReturn:
	andmi8 (xbc), 0xf0
	jr MidiScan_PopIzRet

MidiScan_AltPathCheck:
	bitda 2, (1057)
	jr nz, MidiScan_PopIzRet
	andmi8 (xiz + 14), 0xf0

MidiScan_PopIzRet:
	pop xiz
	ret

; ============================================================================
; UIState_UpdateControlBits - Update UI state control bit flags
; ============================================================================
; Input:  Control parameters from caller
; Output: Updated control bit state
; Modifies the UI state control flags that govern which UI elements are
; active and which input modes are enabled.
; ============================================================================
UIState_UpdateControlBits:
	.incbin "includes/generated/v7_transplant_UIState_UpdateControlBits.bin"
UIState_SwitchOnDisplayMode:
	.incbin "includes/generated/v7_transplant_UIState_SwitchOnDisplayMode.bin"
UIState_Mode0or1:
	.incbin "includes/generated/v7_transplant_UIState_Mode0or1.bin"
UIState_Mode3:
	.incbin "includes/generated/v7_transplant_UIState_Mode3.bin"
UIState_Mode4:
	.incbin "includes/generated/v7_transplant_UIState_Mode4.bin"
UIState_ProcessExtendedMode:
	.incbin "includes/generated/v7_transplant_UIState_ProcessExtendedMode.bin"
UIStateEvt_NullHandler:
	ret
UIState_SwitchForMidiFlags:
	.incbin "includes/generated/v7_transplant_UIState_SwitchForMidiFlags.bin"
UIState_MidiMode6:
	.incbin "includes/generated/v7_transplant_UIState_MidiMode6.bin"
UIState_MidiMode3F:
	.incbin "includes/generated/v7_transplant_UIState_MidiMode3F.bin"
UIState_MidiMode4:
	.incbin "includes/generated/v7_transplant_UIState_MidiMode4.bin"
UIState_MidiMode14:
	.incbin "includes/generated/v7_transplant_UIState_MidiMode14.bin"
UIState_NullReturn:
	ret


UIState_ProcessAltMode:
	.incbin "includes/generated/v7_transplant_UIState_ProcessAltMode.bin"
UIState_ProcessSimpleMode:
	.incbin "includes/generated/v7_transplant_UIState_ProcessSimpleMode.bin"
CtrlPanel_LookupIndicatorEntry:
	extz wa
	sla wa, 2
	lda_24 xbc, (Protocol_values_for_LED_rows_0x56)
	ld_sril3 XHL, 0x07, 0xe4, 0xe0
	ret

Util_FindLowestSetBit:
	lds hl, 0
	or xwa, xwa
	ret z
	bit 0, wa
	ret nz

FindBit_ShiftLoop:
	srl xwa, 1
	inc 1, hl
	bit 0, wa
	jr z, FindBit_ShiftLoop
	ret

Audio_InitAllDefaults:
	.incbin "includes/generated/v7_transplant_Audio_InitAllDefaults.bin"
AudioInit_FillLoop:
	stib_dsp 0xe0, 0x50
	cp xwa, xbc
	jr ule, AudioInit_FillLoop
	call ToneGen_FlashVerify
	jp DSPCfg_Param_CaseB

Audio_ResetAfterPayloadError:
	.incbin "includes/generated/v7_transplant_Audio_ResetAfterPayloadError.bin"
Audio_ReinitDisplay:
	calr Display_SetupAndPrepareRender
	calr Display_CopyAndRenderBitmaps
	call MainTitle_SetBootFlag

Audio_ReinitToneGen:
	.incbin "includes/generated/v7_transplant_Audio_ReinitToneGen.bin"
Audio_FillParamBuffer:
	.incbin "includes/generated/v7_transplant_Audio_FillParamBuffer.bin"
AudioFill_Loop:
	stib_dsp 0xe0, 0x50
	cp xwa, xbc
	jr ule, AudioFill_Loop
	ret

Audio_JumpTrampoline:
	jr	t, 0x82

Audio_ReinitToneGenAndOutput:
	push xde
	push xhl
	push xix
	push xiz
	call ToneGen_ApplyMaskTable
	call ToneGen_Config_InitAndChannels
	call ToneGen_InitAllChannelEntries_Skip
	call ToneGen_DSPCfg_Initialize
	pop xiz
	pop xix
	pop xhl
	pop xde
	calr MidiMsg_ParseChannelStream
	cpdi8 (0xfd32), 182
	jr z, Audio_UpdateTempoAndReturn
	pushw 0x7f
	ldw wa, 0xb0
	lds bc, 1
	ldw de, 0x7f
	calr MIDI_WriteCommandToBuffer
	push xde
	push xhl
	push xix
	push xiz
	call SwbtWr_ReinitOutputBank
	pop xiz
	pop xix
	pop xhl
	pop xde

Audio_UpdateTempoAndReturn:
	.incbin "includes/generated/v7_transplant_Audio_UpdateTempoAndReturn.bin"
Audio_FullReinitWithPreset:
	.incbin "includes/generated/v7_transplant_Audio_FullReinitWithPreset.bin"
Audio_CheckAndReinitReverb:
	.incbin "includes/generated/v7_transplant_Audio_CheckAndReinitReverb.bin"
VoiceData_InitAndCopyParams:
	.incbin "includes/generated/v7_transplant_VoiceData_InitAndCopyParams.bin"
VoiceData_InitDone:
	pop xiz
	inc 2, xsp
	ret

VoiceData_ExtendedParamSetup:
	.incbin "includes/generated/v7_transplant_VoiceData_ExtendedParamSetup.bin"
MidiMsg_ParseChannelStream:
	push xiz
	lda_d16 xiz, (0xf9a0)
	jr MidiMsg_LoopAndFlush

MidiMsg_CheckTerminator:
	cp (xiz), 0xff
	jr nz, MidiMsg_CheckMsgType
	inc 2, xiz
	jr MidiMsg_LoopAndFlush

MidiMsg_CheckMsgType:
	cp (xiz), 0x1f
	jr ule, MidiMsg_WriteMultiByte
	cp (xiz), 0x48
	jr nz, MidiMsg_CheckControlChange

MidiMsg_WriteMultiByte:
	ld xwa, xiz
	calr MIDI_WriteMultiByteWithHeader
	jr MidiChannelMsg_WriteOutput

MidiMsg_CheckControlChange:
	cp (xiz), 0xc0
	jr c, MidiMsg_WriteDefaultMsg
	cp (xiz), 0xdf
	jr ule, MidiChannelMsg_WriteOutput

MidiMsg_WriteDefaultMsg:
	cp (xiz), 0x49
	jr z, MidiChannelMsg_WriteOutput
	ld xwa, xiz
	calr MIDI_WriteMultiByteNoHeader

MidiChannelMsg_WriteOutput:
	ld a, (xiz + 1)
	inc 2, a
	extz wa
	stb_dri H, 0x07, 0xf8, 0xe0

MidiMsg_LoopAndFlush:
	cp xiz, 0xffbe
	jr c, MidiMsg_CheckTerminator
	push xde
	push xhl
	push xix
	push xiz
	call SwbtWr_ReinitOutputBank
	pop xiz
	pop xix
	pop xhl
	pop xde
	pop xiz
	ret

Display_SetupAndPrepareRender:
	.incbin "includes/generated/v7_transplant_Display_SetupAndPrepareRender.bin"
Display_SetRegionNon2:
	stib_da (0x00ffc8), 0x02

Display_RegionDone:
	lds wa, 0
	call BitMapOut_PrepareRender_CheckBit2
	jrl Audio_FillParamBuffer

Display_CopyAndRenderBitmaps:
	.incbin "includes/generated/v7_transplant_Display_CopyAndRenderBitmaps.bin"
DisplayRender_Loop:
	ld wa, iz
	calr VoiceData_InitAndCopyParams
	inc 1, iz
	cp iz, 0x50
	jr c, DisplayRender_Loop
	calr Display_ProcessBitmapTable
	popw iz
	ret

Display_ProcessBitmapTable:
	dec 2, xsp
	push xiz
	ldw (xsp + 4), 0x0

BitmapTable_ProcessEntry:
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	add xbc, xbc
	lda_24 xwa, (SoundProgram_DispatchTable_0x892)
	add xwa, xbc
	ld a, (xwa)
	calr VoiceData_LookupPtrByIndex
	ld xiz, xhl
	sub xiz, 0xf9a0
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	add xbc, xbc
	ld xwa, SoundProgram_DispatchTable_0x890
	add xwa, xbc
	lda_24 xbc, (0x1ed400)
	lda xde, (xwa + 3)
	lda xhl, (xwa + 4)
	lda xix, (xwa + 5)
	cpw (xwa), 0x50
	jr nz, BitmapTable_CheckOffset
	lds iy, 0
	ld e, (xde)
	ld d, (xix)
	ld l, (xhl)
	add xbc, xiz
	ld xix, xbc

BitmapTable_RenderLine:
	ld a, e
	extz wa
	stb_dri A, 0x07, 0xf0, 0xe0
	ld a, d
	cpl a
	and (xbc), a
	or (xbc), l
	inc 1, iy
	add xix, 0x3c0
	cp iy, 0x50
	jr c, BitmapTable_RenderLine
	jr BitmapTable_NextEntry

BitmapTable_CheckOffset:
	cpw (xwa), 0x50
	jr ge, BitmapTable_NextEntry
	ld wa, (xwa)
	exts xwa
	ld xiy, xwa
	sll xiy, 4
	sub xiy, xwa
	sll xiy, 6
	add xbc, xiy
	ld xiy, xbc
	add xiy, xiz
	ld c, (xde)
	extz bc
	ld a, (xix)
	cpl a
	and_srib_mr A, 0x07, 0xf4, 0xe4
	ld c, (xde)
	extz bc
	ld a, (xhl)
	or_srib_mr A, 0x07, 0xf4, 0xe4

BitmapTable_NextEntry:
	incm 1, (xsp + 4)
	cpw (xsp + 4), 0x1
	jrl c, BitmapTable_ProcessEntry
	pop xiz
	inc 2, xsp
	ret

MIDI_WriteMultiByteWithHeader:
	dec 6, xsp
	push xiz
	ld xiz, xwa
	ldb_spi A, 0xf8
	ld (xsp + 4), a
	ldb_spi A, 0xf8
	ld (xsp + 6), a
	ld a, (xsp + 4)
	extz wa
	ld e, (xiz + 1)
	extz de
	pushw 0xff
	lds bc, 1
	calr MIDI_WriteCommandToBuffer
	ld a, (xsp + 4)
	extz wa
	ld e, (xiz)
	extz de
	pushw 0xff
	lds bc, 0
	calr MIDI_WriteCommandToBuffer
	decm8 2, (xsp + 6)
	ld (xsp + 8), 0x2
	inc 2, xiz
	cp (xsp + 6), 0x0
	jr z, MidiMultiByte_Done

MidiMultiByte_WriteLoop:
	ld a, (xsp + 4)
	extz wa
	ld c, (xsp + 8)
	extz bc
	ld e, (xiz)
	extz de
	pushw 0xff
	calr MIDI_WriteCommandToBuffer
	decm8 1, (xsp + 6)
	incm8 1, (xsp + 8)
	inc 1, xiz
	cp (xsp + 6), 0x0
	jr nz, MidiMultiByte_WriteLoop

MidiMultiByte_Done:
	pop xiz
	inc 6, xsp
	ret

MIDI_WriteMultiByteNoHeader:
	dec 6, xsp
	push xiz
	ld xiz, xwa
	ldb_spi A, 0xf8
	ld (xsp + 4), a
	ldb_spi A, 0xf8
	ld (xsp + 6), a
	ld (xsp + 8), 0x0
	cp (xsp + 6), 0x0
	jr z, MidiNoHeader_Done

MidiNoHeader_WriteLoop:
	ld a, (xsp + 4)
	extz wa
	ld c, (xsp + 8)
	extz bc
	ld e, (xiz)
	extz de
	pushw 0xff
	calr MIDI_WriteCommandToBuffer
	decm8 1, (xsp + 6)
	incm8 1, (xsp + 8)
	inc 1, xiz
	cp (xsp + 6), 0x0
	jr nz, MidiNoHeader_WriteLoop

MidiNoHeader_Done:
	pop xiz
	inc 6, xsp
	ret

MIDI_WriteCommandToBuffer:
	.incbin "includes/generated/v7_transplant_MIDI_WriteCommandToBuffer.bin"
MidiWrite_ReturnDiscard:
	retd 0x2

Audio_InitAllChannelParams:
	pushw_erp 0xfa
	ldib_erp 0xfb, 0

AudioParamInit_Loop:
	stb_erp A, 0xfb
	extz wa
	calr Audio_InitSingleChannelParams
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x0f
	jr ule, AudioParamInit_Loop
	popw_erp 0xfa
	ret

Audio_InitSingleChannelParams:
	.incbin "includes/generated/v7_transplant_Audio_InitSingleChannelParams.bin"
Audio_MainPeriodicUpdate:
	.incbin "includes/generated/v7_transplant_Audio_MainPeriodicUpdate.bin"
Audio_SyncBufferPositions:
	.incbin "includes/generated/v7_transplant_Audio_SyncBufferPositions.bin"
FileIO_OperationDispatch:
	.incbin "includes/generated/v7_transplant_FileIO_OperationDispatch.bin"
FileIO_ProcessRemainingOps:
	.incbin "includes/generated/v7_transplant_FileIO_ProcessRemainingOps.bin"
ExtData_ToneParam_DispatchHandler:
	.incbin "includes/generated/v7_transplant_ExtData_ToneParam_DispatchHandler.bin"
FileIO_AllocBuffer:
	ret
ExtData_ToneParam_CheckMode:
	.incbin "includes/generated/v7_transplant_ExtData_ToneParam_CheckMode.bin"
ExtData_ToneParam_AltDispatch:
	.incbin "includes/generated/v7_transplant_ExtData_ToneParam_AltDispatch.bin"
ExtData_ToneParam_AltEntry:
	ret
ExtData_ToneParam_AltBody:
	.incbin "includes/generated/v7_transplant_ExtData_ToneParam_AltBody.bin"
ExtData_ToneParam_MultiChannel:
	.incbin "includes/generated/v7_transplant_ExtData_ToneParam_MultiChannel.bin"
MIDI_WriteResetSequence:
	.incbin "includes/generated/v7_transplant_MIDI_WriteResetSequence.bin"
ExtData_Voice_UpdateFlags:
	.incbin "includes/generated/v7_transplant_ExtData_Voice_UpdateFlags.bin"
ExtData_Voice_CheckMode:
	.incbin "includes/generated/v7_transplant_ExtData_Voice_CheckMode.bin"
ExtData_Voice_RetEntry:
	ret
ExtData_Voice_MixedHandler:
	.incbin "includes/generated/v7_transplant_ExtData_Voice_MixedHandler.bin"
ExtData_Voice_CheckMode3:
	.incbin "includes/generated/v7_transplant_ExtData_Voice_CheckMode3.bin"
ExtData_Voice_RetEntry2:
	ret
ExtData_Voice_FullHandler:
	.incbin "includes/generated/v7_transplant_ExtData_Voice_FullHandler.bin"
ExtData_Voice_CopyAndJump:
	.incbin "includes/generated/v7_transplant_ExtData_Voice_CopyAndJump.bin"
ExtData_Voice_CompareAndDispatch:
	.incbin "includes/generated/v7_transplant_ExtData_Voice_CompareAndDispatch.bin"
MidiChannel_ResetAndConfigure:
	.incbin "includes/generated/v7_transplant_MidiChannel_ResetAndConfigure.bin"
MidiCh_ConfigVoiceAndParts:
	.incbin "includes/generated/v7_transplant_MidiCh_ConfigVoiceAndParts.bin"
MidiCh_IterateVolume_Forward:
	.incbin "includes/generated/v7_transplant_MidiCh_IterateVolume_Forward.bin"
MidiCh_IterateVolume_Reverse:
	.incbin "includes/generated/v7_transplant_MidiCh_IterateVolume_Reverse.bin"
MidiCh_IteratePan_Forward:
	.incbin "includes/generated/v7_transplant_MidiCh_IteratePan_Forward.bin"
MidiCh_IterateExpression:
	.incbin "includes/generated/v7_transplant_MidiCh_IterateExpression.bin"
CtrlPanel_RefreshIndicatorState:
	.incbin "includes/generated/v7_transplant_CtrlPanel_RefreshIndicatorState.bin"
CtrlPanel_CompareAndUpdateIndicators:
	stb_dri L, 0xfd, 0x8e, 0xfe
	push xiz
	stl_dri XBC, 0xfd, 0x6e, 0x01
	stl_dri XWA, 0xfd, 0x72, 0x01
	ld_sril XWA, (xsp + 0x0172)
	calr CtrlPanel_BuildIndicatorBitmask
	ld (xsp + 4), xhl
	ld_sril XWA, (xsp + 0x016e)
	calr CtrlPanel_BuildIndicatorBitmask
	ld xiz, xhl
	ld xwa, (xsp + 4)
	xor xwa, xiz
	and xwa, xiz
	calr Part_BitmaskToIndexList
	ld_sril XWA, (xsp + 0x016e)
	ld c, (xwa + 1)
	extz bc
	ldw wa, 0x80
	calr Audio_IteratePartsWithExpression
	ld_sril XWA, (xsp + 0x016e)
	ld c, (xwa + 1)
	extz bc
	lds wa, 0
	calr Audio_IteratePartsWithVolume
	ld_sril XWA, (xsp + 0x016e)
	ld c, (xwa + 1)
	extz bc
	lds wa, 0
	calr Audio_IteratePartsWithPan
	ld_sril XWA, (xsp + 0x016e)
	ld c, (xwa + 1)
	cp c, 0xff
	jr z, CtrlPanelRefresh_ProcessRemoved
	extz bc
	ldw wa, 0x7f
	calr MIDI_DispatchVoiceParamCC

CtrlPanelRefresh_ProcessRemoved:
	.incbin "includes/generated/v7_transplant_CtrlPanelRefresh_ProcessRemoved.bin"
CtrlPanelRefresh_DispatchVoiceCC:
	.incbin "includes/generated/v7_transplant_CtrlPanelRefresh_DispatchVoiceCC.bin"
CtrlPanelRefresh_CheckMigration:
	.incbin "includes/generated/v7_transplant_CtrlPanelRefresh_CheckMigration.bin"
CtrlPanelRefresh_Done:
	pop xiz
	stb_dri L, 0xfd, 0x72, 0x01
	ret

CtrlPanel_BuildIndicatorBitmask:
	push xiz
	lds32 xiz, 0
	lda_24 xde, (SoundProgram_DispatchTable_0x8DA)
	ld c, (xwa + 1)
	cp c, 0xff
	jr nz, IndBitmask_LookupByChannel
	ld c, (xwa)
	lds32 xiz, 0
	ldb_erp C, 0xf8
	and xiz, 0x7
	ldb_sri0 A, (xwa + 0x00be)
	cp a, 0xff
	jr z, IndBitmask_ReturnResult
	extz wa
	ldb_sri A, 0x07, 0xe8, 0xe0
	jr IndBitmask_ApplyResult

IndBitmask_LookupByChannel:
	extz bc
	ldb_sri A, 0x07, 0xe8, 0xe4

IndBitmask_ApplyResult:
	call CtrlPanel_LookupIndicatorEntry
	or xiz, xhl

IndBitmask_ReturnResult:
	ld xhl, xiz
	pop xiz
	ret

Part_BitmaskToIndexList:
	.incbin "includes/generated/v7_transplant_Part_BitmaskToIndexList.bin"
BitmaskToIndex_ScanLoop:
	or xwa, xwa
	jr z, BitmaskToIndex_Terminate
	bit 0, wa
	jr z, BitmaskToIndex_ShiftAndAdvance
	ld bc, iy
	inc 1, iy
	ld ix, bc
	extz xix
	add xix, xde
	ld c, l
	ld (xix), c

BitmaskToIndex_ShiftAndAdvance:
	srl xwa, 1
	inc 1, hl
	cp hl, 0x20
	jr c, BitmaskToIndex_ScanLoop

BitmaskToIndex_Terminate:
	ld wa, iy
	extz xwa
	add xwa, xde
	ld (xwa), 0xff
	ret

Audio_IteratePartsWithVolume:
	dec 4, xsp
	pushw iz
	ld (xsp + 2), c
	ld (xsp + 4), a
	lds iz, 0

VolumeIter_NextPart:
	.incbin "includes/generated/v7_transplant_VolumeIter_NextPart.bin"
VolumeIter_ApplyParam:
	.incbin "includes/generated/v7_transplant_VolumeIter_ApplyParam.bin"
VolumeIter_AdvancePart:
	inc 1, iz
	cp iz, 0x20
	jr c, VolumeIter_NextPart

VolumeIter_Done:
	popw iz
	inc 4, xsp
	ret

Audio_IteratePartsWithExpression:
	dec 2, xsp
	push xiz
	ld (xsp + 4), c
	ld c, a
	sll c, 6
	and c, 0x40
	ldb_erp C, 0xfa
	srl a, 1
	ldb_erp A, 0xfb
	res_erpb 0xfb, 0x07
	stb_erp C, 0xfb
	extz bc
	sll bc, 8
	stb_erp A, 0xfa
	extz wa
	add wa, bc
	cp wa, 0x7f40
	jr c, ExprIter_Start
	ldi_erpb 0xfb, 0x7f
	ldi_erpb 0xfa, 0x7f

ExprIter_Start:
	lds iz, 0

ExprIter_NextPart:
	.incbin "includes/generated/v7_transplant_ExprIter_NextPart.bin"
ExprIter_ApplyParam:
	.incbin "includes/generated/v7_transplant_ExprIter_ApplyParam.bin"
ExprIter_AdvancePart:
	inc 1, iz
	cp iz, 0x20
	jr c, ExprIter_NextPart

ExprIter_Done:
	pop xiz
	inc 2, xsp
	ret

Audio_IteratePartsWithPan:
	dec 4, xsp
	pushw iz
	ld (xsp + 2), c
	ld (xsp + 4), a
	lds iz, 0

PanIter_NextPart:
	.incbin "includes/generated/v7_transplant_PanIter_NextPart.bin"
PanIter_ApplyParam:
	.incbin "includes/generated/v7_transplant_PanIter_ApplyParam.bin"
MidiLoadParams_ContinueLoop:
	inc 1, iz
	cp iz, 0x20
	jrl c, PanIter_NextPart

PanIter_Done:
	popw iz
	inc 4, xsp
	ret

MIDI_DispatchVoiceParamCC:
	dec 2, xsp
	pushw iz
	ld (xsp + 2), a
	cpdi8 (0xfd32), 183
	jr nz, VoiceParamCC_Done
	lds iz, 0

VoiceParamCC_NextPart:
	.incbin "includes/generated/v7_transplant_VoiceParamCC_NextPart.bin"
VoiceParamCC_AdvancePart:
	inc 1, iz
	cp iz, 0x20
	jr c, VoiceParamCC_NextPart

VoiceParamCC_Done:
	popw iz
	inc 2, xsp
	ret

UIState_CheckAndRenderBitmap:
	.incbin "includes/generated/v7_transplant_UIState_CheckAndRenderBitmap.bin"
UIState_RenderBitmapData:
	.incbin "includes/generated/v7_transplant_UIState_RenderBitmapData.bin"
ToshiCmd_DefaultHandler_Ret:
	ret

SndParam_FetchSequencerParams:
	.incbin "includes/generated/v7_transplant_SndParam_FetchSequencerParams.bin"
SndParam_WriteLookupAndStore:
	.incbin "includes/generated/v7_transplant_SndParam_WriteLookupAndStore.bin"
SwbtWr_FlushAndAppendParams:
	.incbin "includes/generated/v7_transplant_SwbtWr_FlushAndAppendParams.bin"
SwbtWr_FlushDone:
	calr SwbtWr_AppendFixedParamBlock
	ret

SwbtWr_CheckBufferOverflow:
	.incbin "includes/generated/v7_transplant_SwbtWr_CheckBufferOverflow.bin"
SwbtWr_WriteParamBlock:
	.incbin "includes/generated/v7_transplant_SwbtWr_WriteParamBlock.bin"
SwbtWr_WriteParamBlock_Body:
	.incbin "includes/generated/v7_transplant_SwbtWr_WriteParamBlock_Body.bin"
Voice_Update_Return:
	inc 2, xsp
	ret

VoiceParam_CompareAndUpdate:
	.incbin "includes/generated/v7_transplant_VoiceParam_CompareAndUpdate.bin"
ToneGen_ApplyVoiceParams:
	.incbin "includes/generated/v7_transplant_ToneGen_ApplyVoiceParams.bin"
ToneGen_DispatchStartVoice:
	.incbin "includes/generated/v7_transplant_ToneGen_DispatchStartVoice.bin"
ToneGen_Dispatch_Return:
	popw_erp 0xfa
	inc 6, xsp
	ret

SwbtWr_NullRet:
	ret

Audio_FlushPendingBankSelects:
	.incbin "includes/generated/v7_transplant_Audio_FlushPendingBankSelects.bin"
BankFlush_CheckChannel1:
	.incbin "includes/generated/v7_transplant_BankFlush_CheckChannel1.bin"
UIWidget_MidiStreamControl:
	.incbin "includes/generated/v7_transplant_UIWidget_MidiStreamControl.bin"
SndParam_ApplyAndFetch:
	.incbin "includes/generated/v7_transplant_SndParam_ApplyAndFetch.bin"
SndParam_CheckRhythm:
	cp c, 0x48
	call_24 z, Rhythm_LookupTempoVelocity_Wrap

SndParam_ApplyDone:
	inc 6, xsp
	ret

SndParam_ApplyFromPointer:
	.incbin "includes/generated/v7_transplant_SndParam_ApplyFromPointer.bin"
SndParam_FetchAndStore:
	.incbin "includes/generated/v7_transplant_SndParam_FetchAndStore.bin"
SndParam_FetchCheckRhythm:
	cp c, 0x48
	call_24 z, Rhythm_DispatchNote_Finalize

SndParam_FetchDone:
	inc 6, xsp
	ret

SndParam_ResolveVoiceEntry:
	.incbin "includes/generated/v7_transplant_SndParam_ResolveVoiceEntry.bin"
SndParamResolve_CheckRhythm:
	.incbin "includes/generated/v7_transplant_SndParamResolve_CheckRhythm.bin"
SndParamResolve_Done:
	pop xiz
	ret

SndBuf_WriteParamEntries:
	.incbin "includes/generated/v7_transplant_SndBuf_WriteParamEntries.bin"
SndParam_UpdateVoiceEntry:
	.incbin "includes/generated/v7_transplant_SndParam_UpdateVoiceEntry.bin"
SndParamUpdate_SetResBit6:
	ld (xsp + 2), 0x40
	ld c, (xsp + 4)
	extz bc
	sll bc, 8
	ld a, (xsp + 6)
	extz wa
	add wa, bc
	call MIDI_ParamValidate_CheckBit2
	cps hl, 0
	jr z, SndParamUpdate_DispatchWrite
	ldib_erp 0xfb, 0
	setm 3, (xsp + 2)

SndParamUpdate_DispatchWrite:
	.incbin "includes/generated/v7_transplant_SndParamUpdate_DispatchWrite.bin"
SndParamUpdate_Done:
	popw_erp 0xfa
	inc 8, xsp
	ret

MIDI_DistributeParamToChannels:
	.incbin "includes/generated/v7_transplant_MIDI_DistributeParamToChannels.bin"
MidiDistribute_LookupAndWrite:
	ld a, (xsp + 6)
	extz wa
	calr VoiceData_LookupPtrByChannel
	cp xhl, 0xffffffff
	jr z, MidiDistribute_Fallthrough
	ld c, (xsp + 4)
	cp c, (xsp)
	jr ugt, MidiDistribute_Fallthrough
	extz bc
	ld a, (xsp + 2)
	lda_dri XBC, 0x07, 0xec, 0xe4

MidiDistribute_Fallthrough:
	jr MidiDistribute_Done

MidiDistribute_CheckRhythm:
	cp (xsp + 6), 0x48
	jr nz, MidiDistribute_Done
	ld (xsp), 0xf
	jr MidiDistribute_LookupAndWrite

MidiDistribute_Done:
	inc 8, xsp
	ret

VoiceData_DistributeToChannels:
	.incbin "includes/generated/v7_transplant_VoiceData_DistributeToChannels.bin"
SwbtWr_AppendFixedParamBlock:
	.incbin "includes/generated/v7_transplant_SwbtWr_AppendFixedParamBlock.bin"
VoiceData_LookupPtrByIndex:
	extz wa
	sla wa, 2
	lda_24 xbc, (SoundProgram_DispatchTable_0x400)
	ld_sril3 XHL, 0x07, 0xe4, 0xe0
	ret

VoiceData_LookupPtrByChannel:
	cp a, 0x1f
	jr ugt, VoiceLookup_CheckRhythm
	extz wa
	sla wa, 2
	lda_24 xbc, (SoundProgram_DispatchTable_0x800)
	ld_sril3 XHL, 0x07, 0xe4, 0xe0
	ret

VoiceLookup_CheckRhythm:
	cp a, 0x48
	jr nz, VoiceLookup_ReturnInvalid
	lda_d16 xhl, (0xff92)
	ret

VoiceLookup_ReturnInvalid:
	ld xhl, 0xffffffff
	ret

VoiceChannels_InitPanFromPreset:
	push xiz
	ldw_d16 xiz, (0xf290)
	ldiw_erp 0xfa, 0

VoicePanInit_Loop:
	.incbin "includes/generated/v7_transplant_VoicePanInit_Loop.bin"
ToneGen_IncrementAndExit:
	srl iz, 1
	inc1w_erp 0xfa
	cp_erpw 0xfa, 0x10, 0x00
	jr c, VoicePanInit_Loop
	pop xiz
	ret

; =============================================================================
; SoundPreset_FindMatch -- Find matching preset in ROM tables
; =============================================================================
; Compares current params against all presets to find active one.
; Args: a = type (0/1/2), bc = search params
; Returns: hl = matched index, or 0xffff if no match
SoundPreset_FindMatch:
	cps a, 2
	jrl z, SoundPreset_FindMatch_Combined
	cps a, 1
	jr z, EQPreset_FindMatch
	cps a, 0
	jr z, SoundPreset_FindMatch_Reverb
	ldw hl, 0xffff
	ret

SoundPreset_FindMatch_Reverb:
	pushw iz
	lds iz, 0

ReverbPreset_SearchLoop:
	.incbin "includes/generated/v7_transplant_ReverbPreset_SearchLoop.bin"
ReverbPreset_NextEntry:
	inc 1, iz
	cp iz, 0xa
	jr c, ReverbPreset_SearchLoop
	ldw hl, 0xffff

ReverbPreset_SearchDone:
	popw iz
	ret

EQPreset_FindMatch:
	pushw iz
	lds iz, 0

EQPreset_SearchLoop:
	.incbin "includes/generated/v7_transplant_EQPreset_SearchLoop.bin"
EQPreset_NextEntry:
	inc 1, iz
	cp iz, 0x9
	jr c, EQPreset_SearchLoop
	ldw hl, 0xffff

EQPreset_SearchDone:
	popw iz
	ret

SoundPreset_FindMatch_Combined:
	pushw iz
	lds iz, 0

CombinedPreset_SearchLoop:
	.incbin "includes/generated/v7_transplant_CombinedPreset_SearchLoop.bin"
CombinedPreset_NextEntry:
	inc 1, iz
	cp iz, 0x9
	jr c, CombinedPreset_SearchLoop
	ldw hl, 0xffff

SoundPreset_ReturnResult:
	popw iz
	ret

; =============================================================================
; SoundPreset_Dispatch -- Route preset load by type (reverb/EQ/combined)
; =============================================================================
; Dispatches to the appropriate preset loader based on the type parameter:
;   type 0 -> ReverbPreset_Load (reverb-only, 24 bytes via cmd 0x63)
;   type 1 -> EQPreset_Load (EQ-only, 24 bytes via cmd 0x64)
;   type 2 -> CombinedPreset_Load (reverb+EQ, 48 bytes)
; Args: a = preset type (0/1/2), bc = preset index
; Called from: MainRevEqPresetLoad
SoundPreset_Dispatch:
	ld e, a
	extz bc
	cps e, 2
	jr z, SoundPreset_Dispatch_Combined
	cps e, 1
	jr z, SoundPreset_Dispatch_EQ
	cps e, 0
	ret nz
	ld wa, bc
	jr ReverbPreset_Load

SoundPreset_Dispatch_EQ:
	ld wa, bc
	jr EQPreset_Load

SoundPreset_Dispatch_Combined:
	ld wa, bc
	calr CombinedPreset_Load
	ret

; =============================================================================
; ReverbPreset_Load -- Load and send a reverb preset to the Sub CPU
; =============================================================================
; Reads 24-byte reverb preset from ROM table at 0xedb36c, copies to 0xfc8e,
; then sends all 24 bytes via cmd 0x63 to the Sub CPU DSP ring buffer.
; Preset: B0=algo_id, B1=REV_TIME, B3=PRE_DLY, B4=HI_DAMP, B5=ER_LVL, B22=99
; Args: wa = preset index (0-9)
ReverbPreset_Load:
	.incbin "includes/generated/v7_transplant_ReverbPreset_Load.bin"
ReverbPreset_SendLoop:
	.incbin "includes/generated/v7_transplant_ReverbPreset_SendLoop.bin"
EQPreset_Load:
	.incbin "includes/generated/v7_transplant_EQPreset_Load.bin"
EQPreset_SendLoop:
	.incbin "includes/generated/v7_transplant_EQPreset_SendLoop.bin"
CombinedPreset_Load:
	.incbin "includes/generated/v7_transplant_CombinedPreset_Load.bin"
CombinedPreset_SendReverbLoop:
	.incbin "includes/generated/v7_transplant_CombinedPreset_SendReverbLoop.bin"
CombinedPreset_SendEQLoop:
	.incbin "includes/generated/v7_transplant_CombinedPreset_SendEQLoop.bin"
MIDI_MapCCToIndex:
	cp	a, 102
	jr	z, 36
	cp	a, 101
	jr	z, 28
	cp	a, 100
	jr	z, 20
	cp	a, 99
	jr	z, 12
	cp	a, 97
	jr	z, 4
	ldw	hl, 0xffff
	ret
	lds	hl, 0
	ret
	lds	hl, 1
	ret
	lds	hl, 4
	ret
	lds	hl, 2
	ret
	lds	hl, 3
	ret
	cps	a, 4
	jr	z, 36
	cps	a, 3
	jr	z, 28
	cps	a, 2
	jr	z, 20
	cps	a, 1
	jr	z, 12
	cps	a, 0
	jr	z, 4
	ldw	hl, 0xffff
	ret
	ldw	hl, 97
	ret
	ldw	hl, 99
	ret
	ldw	hl, 101
	ret
	ldw	hl, 102
	ret
	ldw	hl, 100
	ret

SwbtWr_WriteVoiceParam_PreserveRegs:
	push xwa
	push xbc
	push xde
	push xhl
	push xix
	push xiy
	push xiz
	call SwbtWr_FlushAndAppendParams
	pop xiz
	pop xiy
	pop xix
	pop xhl
	pop xde
	pop xbc
	pop xwa
	ret

AudioCtrl_PreserveRegs_PopEpilogue:
	.incbin "includes/generated/v7_transplant_AudioCtrl_PreserveRegs_PopEpilogue.bin"
SwbtWr_WriteParamBlockSafe:
	push xwa
	push xbc
	push xde
	push xhl
	push xix
	push xiy
	push xiz
	call SwbtWr_WriteParamBlock
	pop xiz
	pop xiy
	pop xix
	pop xhl
	pop xde
	pop xbc
	pop xwa
	ret

SndParam_ApplyProgramChange_Safe:
	.incbin "includes/generated/v7_transplant_SndParam_ApplyProgramChange_Safe.bin"
PartCtrl_WriteProgramChange:
	.incbin "includes/generated/v7_transplant_PartCtrl_WriteProgramChange.bin"
SndParam_UpdateVoiceEntry_Safe:
	push xwa
	push xbc
	push xde
	push xhl
	push xix
	push xiy
	push xiz
	ld a, c
	extz wa
	ld c, e
	extz bc
	ld e, d
	extz de
	call SndParam_UpdateVoiceEntry
	pop xiz
	pop xiy
	pop xix
	pop xhl
	pop xde
	pop xbc
	pop xwa
	ret

MIDI_LoadParamsAndDispatchCC:
	.incbin "includes/generated/v7_transplant_MIDI_LoadParamsAndDispatchCC.bin"
MIDI_ClearGuardAndDispatchCC:
	.incbin "includes/generated/v7_transplant_MIDI_ClearGuardAndDispatchCC.bin"
MIDI_DispatchCC_Guarded:
	.incbin "includes/generated/v7_transplant_MIDI_DispatchCC_Guarded.bin"
MidiGuarded_Return:
	ret

MIDI_WriteVoiceParamCC:
	.incbin "includes/generated/v7_transplant_MIDI_WriteVoiceParamCC.bin"
MidiWriteVoice_Done:
	pop xhl
	popw wa
	pop xix
	ret

MIDI_WriteVoiceParamFromBuffer:
	.incbin "includes/generated/v7_transplant_MIDI_WriteVoiceParamFromBuffer.bin"
MIDI_WriteVoiceParamDirect:
	.incbin "includes/generated/v7_transplant_MIDI_WriteVoiceParamDirect.bin"
MidiWriteDirect_Done:
	popw hl
	popw wa
	pop xix
	ret

MIDI_SetupChannelParams:
	push xwa
	push xbc
	push xde
	push xhl
	push xix
	push xiy
	push xiz
	ld a, c
	extz wa
	ld c, l
	extz bc
	ld e, h
	extz de
	call MIDI_DistributeParamToChannels
	pop xiz
	pop xiy
	pop xix
	pop xhl
	pop xde
	pop xbc
	pop xwa
	ret

Audio_WriteBankSelectParams:
	.incbin "includes/generated/v7_transplant_Audio_WriteBankSelectParams.bin"
BankSelect_CheckChannel1:
	.incbin "includes/generated/v7_transplant_BankSelect_CheckChannel1.bin"
BankSelect_Done:
	popw de
	ret

SeqTimer_UpdateTempoReg:
	bitda 2, (0xfd50)
	jr nz, SeqTimer_Return
	push xiz
	push xwa
	push xbc
	push xde
	push xhl
	ld xde, 0xfc5a
	ld wa, (xde + 8)
	and wa, 0x1ff
	cp wa, 0x28
	jr c, SeqTimer_ClampToDefault
	cp wa, 0x12c
	jr ule, SeqTimer_ComputeRegValue

SeqTimer_ClampToDefault:
	andmi16 (xde + 8), 0xfe00
	ldw wa, 0x78
	ld (xde + 8), a

SeqTimer_ComputeRegValue:
	.incbin "includes/generated/v7_transplant_SeqTimer_ComputeRegValue.bin"
SeqTimer_AdjustForMode4:
	div xde, xwa
	ld xbc, xde
	srl xbc, 0
	srl wa, 1
	cp bc, wa
	jr c, SeqTimer_RoundUp
	inc 1, de

SeqTimer_RoundUp:
	.incbin "includes/generated/v7_transplant_SeqTimer_RoundUp.bin"
SeqTimer_ClearFlag:
	.incbin "includes/generated/v7_transplant_SeqTimer_ClearFlag.bin"
SeqTimer_Return:
	ret

ToneGen_DispatchByMode:
	pushw wa
	pushw hl
	push xix
	ldw_d16 xwa, (0xfc66)
	and wa, 0x203
	cps a, 0
	jr nz, RegBitManip_Dispatch
	ldb a, 0x1

; Register bit manipulation dispatch
; Index: DRAM[64605] & 0x7 (0-7), entries: 8
; 32-bit function pointers, call (xhl)
RegBitManip_Dispatch:
	extz xhl
	xor h, h
	ldb_d8 l, (0xfc5d)
	and l, 0x7
	sla hl, 2
	ld xix, RegisterBit_Manipulate_Table
	ld_sril3 XIX, 0x07, 0xf0, 0xec
	jp (xix)
RegisterBit_Manipulate_Table:
	.long RegBitManip_Handler_0
	.long RegBitManip_Handler_1
	.long RegBitManip_Handler_0
	.long RegBitManip_Handler_3
	.long RegBitManip_Handler_4
	.long RegBitManip_Handler_4
	.long RegBitManip_Handler_4
	.long RegBitManip_Handler_4
RegBitManip_Handler_1:
	bitda	0, (0xfc69)
	jr	nz, 3
RegBitManip_Handler_3:
	and	w, 0xfd
RegBitManip_Handler_0:
	pushw	wa
	and	wa, 515
	popw	wa
	jr	nz, 2
	lds	wa, 1
RegBitManip_Handler_4:
	.incbin "includes/generated/v7_transplant_RegBitManip_Handler_4.bin"
MIDI_ParamValidate_CheckBit2:
	xor hl, hl
	bitda 2, (0xfdad)
	jr nz, MidiParamValid_CheckW78
	cp a, 0xf0
	jr nc, MidiParamValid_SetInvalid
	jr MidiParamValid_Return

MidiParamValid_CheckW78:
	cp w, 0x78
	jr nz, MidiParamValid_Return

MidiParamValid_SetInvalid:
	inc 1, hl

MidiParamValid_Return:
	ret

MidiStream_ProcessEventBuffer:
	.incbin "includes/generated/v7_transplant_MidiStream_ProcessEventBuffer.bin"
MidiStream_NextEvent:
	.incbin "includes/generated/v7_transplant_MidiStream_NextEvent.bin"
MidiStream_ScanForMatch:
	ld_spiw WA, 0xf1
	cp a, 0xff
	jr z, MidiStream_NextEvent
	cp wa, bc
	jr z, MidiStream_FoundMatch
	inc 2, xix
	jr MidiStream_ScanForMatch

MidiStream_FoundMatch:
	ld_spiw WA, 0xf1
	cp c, 0xb1
	jr z, MidiStream_ProcessorDispatch
	and d, a
	jr z, MidiStream_ScanForMatch

; MIDI stream processor dispatch A
; Index: w & 0x7 (0-7), entries: 8
; 32-bit function pointers, call (xhl)
MidiStream_ProcessorDispatch:
	and w, 0x7
	sll w, 2
	ld xix, MidiStream_Processor_Table
	ld_sril3 XIX, 0x03, 0xf0, 0xe1
	call (xix)
	jr MidiStream_NextEvent

MidiStream_BufferDone:
	call TempoRingBuf_Consume
	resda 0, 1113

MidiStream_Return:
	pop xiz
	ret


MidiStream_Processor_Table:
	.long MidiStream_ProcessHandler_0
	.long MidiStream_ProcessHandler_1
	.long MidiStream_ProcessHandler_2
	.long MidiStream_ProcessHandler_3
	.long MidiStream_ProcessHandler_4
	.long MidiStream_ProcessHandler_5
	.long MidiStream_ProcessHandler_5
	.long MidiStream_ProcessHandler_5
MidiStream_ProcessHandler_5:
	ret

MidiStream_InitFromLookup:
	.incbin "includes/generated/v7_transplant_MidiStream_InitFromLookup.bin"
MidiStreamInit_CopyLoop:
	ld_spiw WA, 0xf5
	stw_dpi WA, 0xf1
	ld_spiw WA, 0xf5
	stw_dpi WA, 0xf1
	cp a, 0xff
	jr nz, MidiStreamInit_CopyLoop

MidiStreamInit_Done:
	ret

MidiStream_ProcessHandler_0:
	.incbin "includes/generated/v7_transplant_MidiStream_ProcessHandler_0.bin"
MidiStream_ProcessHandler_1:
	.incbin "includes/generated/v7_transplant_MidiStream_ProcessHandler_1.bin"
MidiStream_ProcessHandler_2:
	.incbin "includes/generated/v7_transplant_MidiStream_ProcessHandler_2.bin"
MidiStream_ProcessHandler_3:
	.incbin "includes/generated/v7_transplant_MidiStream_ProcessHandler_3.bin"
MidiStream_ProcessHandler_4:
	.incbin "includes/generated/v7_transplant_MidiStream_ProcessHandler_4.bin"
MidiStream_ProcessSeqBuffer:
	.incbin "includes/generated/v7_transplant_MidiStream_ProcessSeqBuffer.bin"
MidiSeqBuf_NextEvent:
	.incbin "includes/generated/v7_transplant_MidiSeqBuf_NextEvent.bin"
MidiSeqBuf_ScanForMatch:
	ld_spiw WA, 0xf1
	cp a, 0xff
	jr z, MidiSeqBuf_NextEvent
	cp wa, bc
	jr z, MidiSeqBuf_FoundMatch
	inc 2, xix
	jr MidiSeqBuf_ScanForMatch

MidiSeqBuf_FoundMatch:
	ld_spiw WA, 0xf1
	cp c, 0xb1
	jr z, MidiStream_ProcessorDispatchB
	and d, a
	jr z, MidiSeqBuf_ScanForMatch

; MIDI stream processor dispatch B
; Index: w & 0x7 (0-7), entries: 8
; 32-bit function pointers, call (xhl)
MidiStream_ProcessorDispatchB:
	.incbin "includes/generated/v7_transplant_MidiStream_ProcessorDispatchB.bin"
MidiSeqBuf_Done:
	call TempoRingBuf_Consume
	resda 0, 1113

MidiSeqBuf_Return:
	pop xiz
	ret

MidiSeqBuf_ProcessorTable:
	.incbin "includes/generated/v7_transplant_MidiSeqBuf_ProcessorTable.bin"
MidiSeqBuf_InitFromTable:
	.incbin "includes/generated/v7_transplant_MidiSeqBuf_InitFromTable.bin"
MidiSeqBufInit_CopyLoop:
	ld_spiw WA, 0xf5
	stw_dpi WA, 0xf1
	cp a, 0xff
	jr z, MidiSeqBufInit_Done
	ld_spiw WA, 0xf5
	stw_dpi WA, 0xf1
	jr MidiSeqBufInit_CopyLoop

MidiSeqBufInit_Done:
	ret

Tempo_ProcessExpressionChange:
	.incbin "includes/generated/v7_transplant_Tempo_ProcessExpressionChange.bin"
TempoExpr_FindActivePart:
	cpib_sri 0x03, 0xf0, 0xec, 0x0f
	jr z, TempoExpr_StorePartIndex
	inc 1, l
	cp l, 0x10
	jr c, TempoExpr_FindActivePart

TempoExpr_StorePartIndex:
	.incbin "includes/generated/v7_transplant_TempoExpr_StorePartIndex.bin"
TempoExpr_CheckHighBitW:
	.incbin "includes/generated/v7_transplant_TempoExpr_CheckHighBitW.bin"
TempoExpr_WriteAndProcess:
	.incbin "includes/generated/v7_transplant_TempoExpr_WriteAndProcess.bin"
TempoExpr_Done:
	inc 2, xsp
	ret

Audio_ProcessAllMidiStreams:
	.incbin "includes/generated/v7_transplant_Audio_ProcessAllMidiStreams.bin"
MIDI_SelectTempoExpressionSource:
	.incbin "includes/generated/v7_transplant_MIDI_SelectTempoExpressionSource.bin"
TempoSrc_CheckAutoPlay:
	.incbin "includes/generated/v7_transplant_TempoSrc_CheckAutoPlay.bin"
Tempo_Expression_Bypass:
	bitda 0, (0x28c5)
	jr z, Tempo_ExpressionStore
	ldw_d16 xwa, (0x28aa)
	jr Tempo_ExpressionStore

TempoSrc_DirectTempoMode:
	.incbin "includes/generated/v7_transplant_TempoSrc_DirectTempoMode.bin"
Tempo_ExpressionStore:
	.incbin "includes/generated/v7_transplant_Tempo_ExpressionStore.bin"
Mod_SelectExpressionSource:
	.incbin "includes/generated/v7_transplant_Mod_SelectExpressionSource.bin"
ModExpr_CheckAutoPlay:
	.incbin "includes/generated/v7_transplant_ModExpr_CheckAutoPlay.bin"
ModExpr_DirectMode:
	.incbin "includes/generated/v7_transplant_ModExpr_DirectMode.bin"
Mod_ExpressionStore:
	.incbin "includes/generated/v7_transplant_Mod_ExpressionStore.bin"
MidiStream_ProcessTempoRingBuf:
	.incbin "includes/generated/v7_transplant_MidiStream_ProcessTempoRingBuf.bin"
TempoRing_NextEvent:
	.incbin "includes/generated/v7_transplant_TempoRing_NextEvent.bin"
TempoRing_InitAndScan:
	.incbin "includes/generated/v7_transplant_TempoRing_InitAndScan.bin"
TempoRing_ScanForMatch:
	ld_spiw WA, 0xf1
	cp a, 0xff
	jr z, TempoRing_UpdateAndContinue
	cp wa, bc
	jr z, TempoRing_FoundMatch
	inc 2, xix
	jr TempoRing_ScanForMatch

TempoRing_FoundMatch:
	ld_spiw WA, 0xf1
	cp c, 0xb1
	jr z, MidiStream_ProcessorDispatchC
	and d, a
	jr z, TempoRing_ScanForMatch

; MIDI stream processor dispatch C
; Index: w & 0xf (0-15), entries: 16
; 32-bit function pointers, call (xhl)
MidiStream_ProcessorDispatchC:
	and w, 0xf
	sll w, 2
	ld xix, TempoRing_ProcessorTable_0x1
	ld_sril3 XIX, 0x03, 0xf0, 0xe1
	call (xix)

TempoRing_UpdateAndContinue:
	.incbin "includes/generated/v7_transplant_TempoRing_UpdateAndContinue.bin"
TempoRing_Done:
	call TempoRingBuf_Consume
	resda 0, 1113

TempoRing_Return:
	pop xiz
	ret

TempoRing_ProcessorTable:
	.incbin "includes/generated/v7_transplant_TempoRing_ProcessorTable.bin"
TempoRing_ValidateState:
	.incbin "includes/generated/v7_transplant_TempoRing_ValidateState.bin"
MIDI_ParamValidation_ReturnNoOp:
	ret

TempoCC_TransmitBytecodeBlock:
	.incbin "includes/generated/v7_transplant_TempoCC_TransmitBytecodeBlock.bin"
MIDI_TransmitTempoCC:
	.incbin "includes/generated/v7_transplant_MIDI_TransmitTempoCC.bin"
TempoCC_CheckHighBitW:
	.incbin "includes/generated/v7_transplant_TempoCC_CheckHighBitW.bin"
TempoCC_WriteAndProcess:
	.incbin "includes/generated/v7_transplant_TempoCC_WriteAndProcess.bin"
TempoCC_Return:
	ret

TempoRing_InitPartStream:
	.incbin "includes/generated/v7_transplant_TempoRing_InitPartStream.bin"
TempoPartStream_CopyLoop:
	ld_spiw WA, 0xf5
	stw_dpi WA, 0xf1
	cp a, 0xff
	jr z, TempoPartStream_Done
	ld_spiw WA, 0xf5
	stw_dpi WA, 0xf1
	jr TempoPartStream_CopyLoop

TempoPartStream_Done:
	ret

TempoRingBuf_ProcessEntry:
	.incbin "includes/generated/v7_transplant_TempoRingBuf_ProcessEntry.bin"
TempoRingBuf_ClearEntryType:
	.incbin "includes/generated/v7_transplant_TempoRingBuf_ClearEntryType.bin"
TempoRingBuf_EntryDone:
	ret

Audio_ProcessPartExpressions:
	.incbin "includes/generated/v7_transplant_Audio_ProcessPartExpressions.bin"
PartExpr_ProcessNextBit:
	.incbin "includes/generated/v7_transplant_PartExpr_ProcessNextBit.bin"
PartExpr_WriteToBuffer:
	.incbin "includes/generated/v7_transplant_PartExpr_WriteToBuffer.bin"
PartExpr_AddPartIndex:
	.incbin "includes/generated/v7_transplant_PartExpr_AddPartIndex.bin"
PartExpr_ReadCurrentValue:
	.incbin "includes/generated/v7_transplant_PartExpr_ReadCurrentValue.bin"
PartExpr_AdvanceBit:
	inc 1, c
	cp c, 0x10
	jr c, PartExpr_ProcessNextBit
	call TempoRingBuf_Consume
	resda 0, 1113

PartExpr_Done:
	pop xiz
	ret

Part_ReinitAllActive:
	.incbin "includes/generated/v7_transplant_Part_ReinitAllActive.bin"
PartReinit_ProcessNextPart:
	.incbin "includes/generated/v7_transplant_PartReinit_ProcessNextPart.bin"
PartReinit_AdvancePart:
	.incbin "includes/generated/v7_transplant_PartReinit_AdvancePart.bin"
PartReinit_SendD2Command:
	.incbin "includes/generated/v7_transplant_PartReinit_SendD2Command.bin"
PartReinit_SendD1Command:
	.incbin "includes/generated/v7_transplant_PartReinit_SendD1Command.bin"
PartReinit_SendD0Command:
	.incbin "includes/generated/v7_transplant_PartReinit_SendD0Command.bin"
PartReinit_SendB0Command:
	.incbin "includes/generated/v7_transplant_PartReinit_SendB0Command.bin"
PartReinit_CheckSpecialPart15:
	.incbin "includes/generated/v7_transplant_PartReinit_CheckSpecialPart15.bin"
PartReinit_SpecialDone:
	ret

Audio_ReinitAndProcessEvents:
	.incbin "includes/generated/v7_transplant_Audio_ReinitAndProcessEvents.bin"
Audio_SyncAndProcessSequencer:
	.incbin "includes/generated/v7_transplant_Audio_SyncAndProcessSequencer.bin"
AudioSeq_CheckEventPending:
	.incbin "includes/generated/v7_transplant_AudioSeq_CheckEventPending.bin"
AudioSeq_ReadNextEvent:
	pushw hl
	call SeqBuf_ReadAlternate
	lda_dpi XSP, 0xf4
	popw hl
	ld hl, (xix - 10)
	cp hl, (xix - 6)
	jr z, VoiceMode_ParamDispatch
	ldb_sri A, 0x07, 0xf0, 0xec
	bit 7, a
	jr z, AudioSeq_ReadNextEvent

; Voice mode parameter dispatch
; Index: DRAM[37301] bits [6:4] (0-7), entries: 8
; 32-bit function pointers, call (xhl)
VoiceMode_ParamDispatch:
	.incbin "includes/generated/v7_transplant_VoiceMode_ParamDispatch.bin"
VoiceMode_ParamDispatch_Sentinel:
	swi	7


VoiceMode_ParamDispatch_Table:
	.long VoiceMode_ParamHandler_0
	.long VoiceMode_ParamHandler_1
	.long VoiceMode_ParamHandler_1
	.long VoiceMode_ParamHandler_3
	.long VoiceMode_ParamHandler_4
	.long VoiceParam_DispatchByMode
	.long VoiceMode_ParamHandler_1
	.long VoiceMode_ParamHandler_1

VoiceMode_ParamHandler_1:
	ret

AudioSeq_FlushAndTerminate:
	.incbin "includes/generated/v7_transplant_AudioSeq_FlushAndTerminate.bin"
VoiceMode_ParamHandler_4:
	.incbin "includes/generated/v7_transplant_VoiceMode_ParamHandler_4.bin"
VoiceMode4_SetupChannelAndWrite:
	.incbin "includes/generated/v7_transplant_VoiceMode4_SetupChannelAndWrite.bin"
VoiceMode4_CheckPart0:
	.incbin "includes/generated/v7_transplant_VoiceMode4_CheckPart0.bin"
MidiCtrl_DispatchHandler:
	.incbin "includes/generated/v7_transplant_MidiCtrl_DispatchHandler.bin"
MidiCtrl_ModeDispatch_Table:
	.incbin "includes/generated/v7_transplant_MidiCtrl_ModeDispatch_Table.bin"
MidiCtrl_NullRet:
	ret

VoiceMode_CheckPendingFlags:
	.incbin "includes/generated/v7_transplant_VoiceMode_CheckPendingFlags.bin"
VoiceMode_CheckFlag1:
	bitm 1, (xix)
	jr z, VoiceMode_CheckPart15Validate
	setm 7, (xix + 5)

VoiceMode_CheckPart15Validate:
	cp (xix + 2), 0xf
	jr nz, VoiceMode_FlagCheckDone
	pushw wa
	pushw hl
	ld a, (xix + 4)
	ld w, (xix + 5)
	call MIDI_ParamValidate_CheckBit2
	or hl, hl
	popw hl
	popw wa
	jr nz, VoiceMode_FlagCheckDone
	ld (xix), 0xff

VoiceMode_FlagCheckDone:
	ret

VoiceMode_ParamHandler_3:
	.incbin "includes/generated/v7_transplant_VoiceMode_ParamHandler_3.bin"
VoiceMode3_Done:
	ret

VoiceMode3_DispatchTable:
	.incbin "includes/generated/v7_transplant_VoiceMode3_DispatchTable.bin"
MidiPartCC_WriteAndDispatch:
	.incbin "includes/generated/v7_transplant_MidiPartCC_WriteAndDispatch.bin"
MidiPartCC_CheckAndGuard:
	.incbin "includes/generated/v7_transplant_MidiPartCC_CheckAndGuard.bin"
MIDI_PartCC_DispatchExit:
	ret

MidiVoice_DataBlockHandler:
	.incbin "includes/generated/v7_transplant_MidiVoice_DataBlockHandler.bin"
VoiceMode3_InitChannelMatch:
	.incbin "includes/generated/v7_transplant_VoiceMode3_InitChannelMatch.bin"
VoiceMode3_CheckBit0:
	bit 0, a
	jr z, VoiceMode3_CheckBit1
	set 7, e

VoiceMode3_CheckBit1:
	bit 1, a
	jr z, VoiceMode3_StoreAndScan
	set 7, d

VoiceMode3_StoreAndScan:
	.incbin "includes/generated/v7_transplant_VoiceMode3_StoreAndScan.bin"
VoiceMode3_ScanLoop:
	ld_spiw WA, 0xf5
	cp a, 0xff
	jr z, VoiceMode3_NoMatch
	cp wa, bc
	jr z, VoiceMode3_FoundMatch
	inc 2, xiy
	jr VoiceMode3_ScanLoop

VoiceMode3_FoundMatch:
	ld_spiw WA, 0xf5
	and d, a
	ld (xix + 2), de
	jr nz, VoiceMode3_StoreSubMode

VoiceMode3_NoMatch:
	.incbin "includes/generated/v7_transplant_VoiceMode3_NoMatch.bin"
VoiceMode3_StoreSubMode:
	.incbin "includes/generated/v7_transplant_VoiceMode3_StoreSubMode.bin"
VoiceMode3_ScanDone:
	ret

VoiceMode3_BuildChannelTable:
	.incbin "includes/generated/v7_transplant_VoiceMode3_BuildChannelTable.bin"
VoiceMode3_CopyTableEntry:
	ld_spiw WA, 0xf5
	stw_dpi WA, 0xf1
	cp a, 0xff
	jr z, VoiceMode3_TableCopyDone
	ld_spiw WA, 0xf5
	stw_dpi WA, 0xf1
	jr VoiceMode3_CopyTableEntry

VoiceMode3_TableCopyDone:
	ret

VoiceMode_ParamHandler_0:
	.incbin "includes/generated/v7_transplant_VoiceMode_ParamHandler_0.bin"
VoiceMode0_UpdateTempoAndWrite:
	.incbin "includes/generated/v7_transplant_VoiceMode0_UpdateTempoAndWrite.bin"
VoiceMode0_Done:
	ret

VoiceParam_DispatchByMode:
	.incbin "includes/generated/v7_transplant_VoiceParam_DispatchByMode.bin"
VoiceParam_DispatchDone:
	ret

VoiceParam_ModeDispatch_Table:
	.incbin "includes/generated/v7_transplant_VoiceParam_ModeDispatch_Table.bin"
VoiceParam_StoreExpression:
	.incbin "includes/generated/v7_transplant_VoiceParam_StoreExpression.bin"
VoiceParam_WriteExpression:
	.incbin "includes/generated/v7_transplant_VoiceParam_WriteExpression.bin"
VoiceParam_ExprCheckGuard:
	.incbin "includes/generated/v7_transplant_VoiceParam_ExprCheckGuard.bin"
VoiceParam_ExprDone:
	ret

VoiceParam_StoreVolume:
	.incbin "includes/generated/v7_transplant_VoiceParam_StoreVolume.bin"
VoiceParam_WriteVolume:
	.incbin "includes/generated/v7_transplant_VoiceParam_WriteVolume.bin"
VoiceParam_VolCheckGuard:
	.incbin "includes/generated/v7_transplant_VoiceParam_VolCheckGuard.bin"
VoiceParam_VolDone:
	ret

VoiceParam_StorePan:
	.incbin "includes/generated/v7_transplant_VoiceParam_StorePan.bin"
VoiceParam_WritePan:
	.incbin "includes/generated/v7_transplant_VoiceParam_WritePan.bin"
VoiceParam_PanCheckGuard:
	.incbin "includes/generated/v7_transplant_VoiceParam_PanCheckGuard.bin"
VoiceParam_PanDone:
	ret

VoiceNote_StoreBankSelect:
	.incbin "includes/generated/v7_transplant_VoiceNote_StoreBankSelect.bin"
VoiceNote_WriteBankAndCC:
	.incbin "includes/generated/v7_transplant_VoiceNote_WriteBankAndCC.bin"
VoiceNote_SetupCCParams:
	.incbin "includes/generated/v7_transplant_VoiceNote_SetupCCParams.bin"
VoiceNote_CheckBankSelect:
	bitda 7, (0x28ad)
	jr nz, VoiceNote_ApplyBankSelect
	bitda 7, (0x28ae)
	jr z, VoiceNote_CtrlDone

VoiceNote_ApplyBankSelect:
	.incbin "includes/generated/v7_transplant_VoiceNote_ApplyBankSelect.bin"
MIDI_VoiceNote_CtrlExit:
	.incbin "includes/generated/v7_transplant_MIDI_VoiceNote_CtrlExit.bin"
VoiceNote_CtrlDone:
	ret

; MIDI voice note dispatch
MidiVoiceNote_Dispatch:
	.incbin "includes/generated/v7_transplant_MidiVoiceNote_Dispatch.bin"
MidiVoiceNote_Dispatch_Table:
	.incbin "includes/generated/v7_transplant_MidiVoiceNote_Dispatch_Table.bin"
MidiVoiceNote_LookupMode0:
	.incbin "includes/generated/v7_transplant_MidiVoiceNote_LookupMode0.bin"
MidiVoiceNote_LookupMode1:
	.incbin "includes/generated/v7_transplant_MidiVoiceNote_LookupMode1.bin"
MidiVoiceNote_LookupMode2:
	.incbin "includes/generated/v7_transplant_MidiVoiceNote_LookupMode2.bin"
MidiVoiceNote_LookupMode3:
	.incbin "includes/generated/v7_transplant_MidiVoiceNote_LookupMode3.bin"
MidiPart_FindChannelInTable:
	.incbin "includes/generated/v7_transplant_MidiPart_FindChannelInTable.bin"
MidiPart_ScanNextEntry:
	ldb_spi A, 0xf4
	cp a, w
	jr z, MidiPart_ScanDone
	djnz xbc, MidiPart_ScanNextEntry

MidiPart_NoChannelFound:
	.incbin "includes/generated/v7_transplant_MidiPart_NoChannelFound.bin"
MidiPart_ScanDone:
	ret

MidiNote_RhythmPartDispatch:
	.incbin "includes/generated/v7_transplant_MidiNote_RhythmPartDispatch.bin"
MidiPart_ChannelDispatch:
	.incbin "includes/generated/v7_transplant_MidiPart_ChannelDispatch.bin"
MidiNote_VelocityHandler_Table:
	.long MidiNoteVel_Handler_0
	.long MidiNoteVel_Handler_1
	.long MidiNoteVel_Handler_2
	.long MidiNoteVel_Handler_2

MidiNoteVel_Handler_0:
	.incbin "includes/generated/v7_transplant_MidiNoteVel_Handler_0.bin"
MidiNoteVel_Handler_1:
	.incbin "includes/generated/v7_transplant_MidiNoteVel_Handler_1.bin"
MidiNoteVel_Handler_2:
	ret

SeqVoice_UpdateTempoParam:
	.incbin "includes/generated/v7_transplant_SeqVoice_UpdateTempoParam.bin"
SeqVoice_TempoDone:
	ret

PendingParam_ScanAllTables:
	.incbin "includes/generated/v7_transplant_PendingParam_ScanAllTables.bin"
PendingExpr_ScanEntry:
	.incbin "includes/generated/v7_transplant_PendingExpr_ScanEntry.bin"
PendingExpr_NextEntry:
	.incbin "includes/generated/v7_transplant_PendingExpr_NextEntry.bin"
PendingVol_ScanEntry:
	.incbin "includes/generated/v7_transplant_PendingVol_ScanEntry.bin"
PendingVol_NextEntry:
	.incbin "includes/generated/v7_transplant_PendingVol_NextEntry.bin"
PendingPan_ScanEntry:
	.incbin "includes/generated/v7_transplant_PendingPan_ScanEntry.bin"
PendingPan_NextEntry:
	.incbin "includes/generated/v7_transplant_PendingPan_NextEntry.bin"
PendingBank_ScanEntry:
	.incbin "includes/generated/v7_transplant_PendingBank_ScanEntry.bin"
PendingBank_NextEntry:
	.incbin "includes/generated/v7_transplant_PendingBank_NextEntry.bin"
PendingPartCC_ScanEntry:
	.incbin "includes/generated/v7_transplant_PendingPartCC_ScanEntry.bin"
PendingPartCC_NextEntry:
	inc 1, xiy
	djnz xbc, PendingPartCC_ScanEntry
	ret

PartCtrl_CheckBitmaskBit:
	.incbin "includes/generated/v7_transplant_PartCtrl_CheckBitmaskBit.bin"
PartCtrl_ShiftBitmask:
	srl wa, 1
	djnz8 c, PartCtrl_ShiftBitmask
	popw bc
	popw wa
	ret

AudioCtrl_SaveAllRegs:
	.incbin "includes/generated/v7_transplant_AudioCtrl_SaveAllRegs.bin"
AudioCtrl_RestoreAllRegs:
	.incbin "includes/generated/v7_transplant_AudioCtrl_RestoreAllRegs.bin"
VoiceMode_ParamConfigTables:
	.incbin "includes/generated/v7_transplant_VoiceMode_ParamConfigTables.bin"
MidiStream_ApplyPendingParams:
	.incbin "includes/generated/v7_transplant_MidiStream_ApplyPendingParams.bin"
MidiStream_CallFilterAndAudio:
	call SwbtWr_WriteVoiceParam_PreserveRegs
	call MIDI_WriteResetSequence

MidiStream_ApplyDone:
	ret

MidiStream_DispatchData:
	.incbin "includes/generated/v7_transplant_MidiStream_DispatchData.bin"
MidiStream_LoadAllPresets:
	.incbin "includes/generated/v7_transplant_MidiStream_LoadAllPresets.bin"
MidiStream_LoadVoicePreset:
	xor hl, hl

MidiStream_LoadVoiceLoop:
	.incbin "includes/generated/v7_transplant_MidiStream_LoadVoiceLoop.bin"
MidiStream_LoadVoiceNext:
	inc 1, hl
	cp l, 0x1f
	jr ule, MidiStream_LoadVoiceLoop
	ret

MidiStream_LoadBankSelect:
	.incbin "includes/generated/v7_transplant_MidiStream_LoadBankSelect.bin"
MidiStream_LoadBankDone:
	ret

MidiStream_LoadMultiPartPreset:
	.incbin "includes/generated/v7_transplant_MidiStream_LoadMultiPartPreset.bin"
MidiStream_LoadMultiLoop:
	.incbin "includes/generated/v7_transplant_MidiStream_LoadMultiLoop.bin"
MidiStream_LoadMultiNext:
	inc 1, b
	inc 2, hl
	cp b, 0x1f
	jr ule, MidiStream_LoadMultiLoop
	ret

MidiStream_LoadPedalPreset:
	.incbin "includes/generated/v7_transplant_MidiStream_LoadPedalPreset.bin"
MidiStream_LoadPedalLoop:
	.incbin "includes/generated/v7_transplant_MidiStream_LoadPedalLoop.bin"
MidiStream_LoadPedalNext:
	inc 1, hl
	cp l, 0x1f
	jr ule, MidiStream_LoadPedalLoop
	ret

MidiStream_ProcessRxBuffer:
	.incbin "includes/generated/v7_transplant_MidiStream_ProcessRxBuffer.bin"
MidiStream_DispatchLoop:
	.incbin "includes/generated/v7_transplant_MidiStream_DispatchLoop.bin"
MidiStream_AdvanceRxPtr:
	.incbin "includes/generated/v7_transplant_MidiStream_AdvanceRxPtr.bin"
MidiStream_ProcessDone:
	ret

MidiStream_StatusPrecheck:
	extz	hl
	ld	l, b
	cp	l, 11
	jr	ugt, 63
	sll	hl, 2
	ld	xix, MidiStream_StatusJumpTable
	ld_rrl	xix, xix, hl
	jp	(xix)


MidiStream_StatusJumpTable:
	.long MidiStream_HandleRunningStatus
	.long MidiStream_HandleNoteCC
	.long MidiStream_HandleNoteCC
	.long MidiStream_HandlePgmChange
	.long MidiStream_HandleChanPressure
	.long MidiStream_HandleSysMsg
	.long MidiStream_HandleSysMsg
	.long MidiStream_HandleSysMsg
	.long MidiStream_HandleSysMsg
	.long MidiStream_HandleSysMsg
	.long MidiStream_HandleSysMsg
	.long MidiStream_HandleSysMsg
MidiStream_HandleNoteCC:
	.incbin "includes/generated/v7_transplant_MidiStream_HandleNoteCC.bin"
MidiStream_PostNoteCC:
	.incbin "includes/generated/v7_transplant_MidiStream_PostNoteCC.bin"
MidiStream_HandleNoteCC_Ret:
	ret


MidiStream_HandlePgmChange:
	.incbin "includes/generated/v7_transplant_MidiStream_HandlePgmChange.bin"
MidiStream_HandleChanPressure:
	.incbin "includes/generated/v7_transplant_MidiStream_HandleChanPressure.bin"
MidiStream_HandleSysMsg:
	.incbin "includes/generated/v7_transplant_MidiStream_HandleSysMsg.bin"
MidiStream_SysExJumpTable:
	.long MidiStream_HandleRunningStatus
	.long MidiStream_SysExNop
	.long MidiStream_SysExNop
	.long MidiStream_SysExData
MidiStream_SysExNop:
	ret
MidiStream_SysExData:
	.incbin "includes/generated/v7_transplant_MidiStream_SysExData.bin"
MidiStream_CtrlJumpTable:
	.long MidiStream_CtrlNop
	.long MidiStream_CtrlData
MidiStream_CtrlNop:
	ret
MidiStream_CtrlData:
	bit	7, d
	jr	z, 18
	bit	7, e
	jr	z, 13
	ldb_d8	e, (0xfc6f)
	and	e, 128
	ldb	d, 128
	call	MIDI_ClearGuardAndDispatchCC
	ret
	extz	hl
	ld	l, b
	cp	l, 11
	jr	ugt, 63
	sll	hl, 2
	ld	xix, MidiStream_CmdJumpTable
	.byte 0xe3
	reti
	.byte 0xf0, 0xec
	ldb	d, 180
	.byte 0xd8
MidiStream_CmdJumpTable:
	.long MidiStream_CmdNop
	.long MidiStream_CmdPedalNotify
	.long MidiStream_CmdNop
	.long MidiStream_CmdNop
	.long MidiStream_CmdNop
	.long MidiStream_CmdNop
	.long MidiStream_CmdNop
	.long MidiStream_CmdNop
	.long MidiStream_CmdNop
	.long MidiStream_CmdNop
	.long MidiStream_CmdNop
	.long MidiStream_CmdMaskedNotify
MidiStream_CmdNop:
	ret
MidiStream_CmdMaskedNotify:
	; --- Routine 1: D/E bit masking, call FCA1FE (23 bytes) ---
	and d, 0xc0
	jr z, MidiStream_CmdMaskedDone
	and e, d
	jr z, MidiStream_CmdMaskedDone
	ldb_d8	e, (0xfda1)
	and e, 0xc0
	ldb d, 0xc0
	call MIDI_ClearGuardAndDispatchCC
MidiStream_CmdMaskedDone:
	ret
MidiStream_CmdPedalNotify:
	.incbin "includes/generated/v7_transplant_MidiStream_CmdPedalNotify.bin"
MidiStream_CmdPedalDone:
	.incbin "includes/generated/v7_block_midistream_cmdpedaldone.bin"
; === end v7 block ===
; === v7-specific block: MidiStream_HandleRunningStatus (919 bytes) ===
MidiStream_HandleRunningStatus:
	.incbin "includes/generated/v7_block_midistream_handlerunningstatus.bin"
; === end v7 block ===
