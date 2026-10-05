; =============================================================================
; sound_editor_routines.asm - Sound Editor Mode Routines
; =============================================================================
; This file contains the Sound Editor title and mode functions for the KN5000.
;
; The Sound Editor provides deep control over synthesizer parameters:
;   - Tone: Waveform selection, hybrid/random tones
;   - Pitch: Pitch control, envelopes, LFO
;   - Amplitude: Volume, envelopes, LFO
;   - Filter: LPF, HPF, BPF, BCF, 24dB modes, envelopes, LFO
;   - Digital Effects: Effect parameters
;   - Controllers: MIDI controller mappings
;   - Copy/Write: Patch management
;
; Routines included:
;   SeMenuModeFunc, SeMenuTitleFunc   - Main menu
;   SeEasyTitleFunc                   - Easy edit mode
;   SeTonTon1/2TitleFunc              - Tone selection
;   SeTonRan1/2TitleFunc              - Random tone
;   SeTonHyb1TitleFunc                - Hybrid tone
;   SePitPit1TitleFunc                - Pitch control
;   SePitEnv1/2TitleFunc              - Pitch envelopes
;   SePitLfo1TitleFunc                - Pitch LFO
;   SeAmpAmp1/2TitleFunc              - Amplitude control
;   SeAmpEnv1/2TitleFunc              - Amplitude envelopes
;   SeAmpLfo1TitleFunc                - Amplitude LFO
;   SeFilLpq1TitleFunc                - Low-pass filter
;   SeFilHpq1TitleFunc                - High-pass filter
;   SeFilL241TitleFunc                - 24dB low-pass
;   SeFilH241TitleFunc                - 24dB high-pass
;   SeFilBpf1TitleFunc                - Band-pass filter
;   SeFilBcf1TitleFunc                - Band-cut filter
;   SeFilFil2TitleFunc                - Filter 2
;   SeFilEnv1/2TitleFunc              - Filter envelopes
;   SeFilLfo1TitleFunc                - Filter LFO
;   SeDigEffTitleFunc                 - Digital effects
;   SeCtr2/3TitleFunc                 - Controllers
;   SeCopyTitleFunc                   - Copy function
;   SeWrtMemTitleFunc                 - Write to memory
;   SeWrtSndTitleFunc                 - Write sound
;
; =============================================================================

SeMenuModeFunc:
	cp xbc, EVT_ACTIVATE_STATE
	ret nz
	cp xde, 0x1
	jr z, SeMenuModeFunc_Handler
	or xde, xde
	ret nz
	jp InitializeSeMenuDefaults

SeMenuModeFunc_Handler:
	call UpdateSeMenuSelection
	ret

SeMenuTitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, SeMenuTitleFunc_Methods
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeMenuTitleFunc_OnDraw:
	jp	UpdSeSel_ProcessStep
SeMenuTitleFunc_OnHide:
	jp	SeMenu_CopyWriteUpdate_Step3_Join3
SeMenuTitleFunc_OnSwitchIn:
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeMenuTitleFunc_DispatchSwitch
SeMenuTitleFunc_Nop:
	jp	SeMenu_CopyWriteUpdate_Step3_Return

SeEasyTitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, SeEasyTitleFunc_Methods
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeEasyTitleFunc_OnDraw:
	jp	UpdSeSel_ExtendedOps_Data
SeEasyTitleFunc_OnHide:
	jp	SeMenu_CopyWriteUpdate_Step3_Join30
SeEasyTitleFunc_OnSwitchIn:
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeEasyTitleFunc_DispatchSwitch
SeEasyTitleFunc_Nop:
	jp	SeMenu_CopyWriteUpdate_Step3_Return30

SeTonTon1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, SeTonTon1TitleFunc_Methods
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeTonTon1TitleFunc_OnDraw:
	jp	SeMenu_AltUpdate
SeTonTon1TitleFunc_OnHide:
	jp	SeMenu_CopyWriteUpdate_Step3_Join15
SeTonTon1TitleFunc_OnSwitchIn:
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeTonTon1TitleFunc_DispatchSwitch
SeTonTon1TitleFunc_Nop:
	jp	SeMenu_CopyWriteUpdate_Step3_Return13

SeTonTon2TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, SeTonTon2TitleFunc_Methods
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeTonTon2TitleFunc_OnDraw:
	jp	SeMenu_AltUpdate_Data
SeTonTon2TitleFunc_OnHide:
	jp	SeMenu_CopyWriteUpdate_Step3_Join16
SeTonTon2TitleFunc_OnSwitchIn:
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeTonTon2TitleFunc_DispatchSwitch
SeTonTon2TitleFunc_Nop:
	jp	SeMenu_CopyWriteUpdate_Step3_Return14

SeTonRan1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, SeTonRan1TitleFunc_Methods
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeTonRan1TitleFunc_OnDraw:
	jp	SeMenu_AltUpdate_Step3Plus_Join
SeTonRan1TitleFunc_OnHide:
	jp	SeMenu_CopyWriteUpdate_Step3_Join17
SeTonRan1TitleFunc_OnSwitchIn:
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeTonRan1TitleFunc_DispatchSwitch
SeTonRan1TitleFunc_Nop:
	jp	SeMenu_CopyWriteUpdate_Step3_Return15

SeTonRan2TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, SeTonRan2TitleFunc_Methods
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeTonRan2TitleFunc_OnDraw:
	jp	SeMenu_AltUpdate_Step3Plus_Join2
SeTonRan2TitleFunc_OnHide:
	jp	SeMenu_CopyWriteUpdate_Step3_Join18
SeTonRan2TitleFunc_OnSwitchIn:
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeTonRan2TitleFunc_DispatchSwitch
SeTonRan2TitleFunc_Nop:
	jp	SeMenu_CopyWriteUpdate_Step3_Return16

SeTonHyb1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, SeTonHyb1TitleFunc_Methods
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeTonHyb1TitleFunc_OnDraw:
	jp	SeMenu_ControllerUpdate
SeTonHyb1TitleFunc_OnHide:
	jp	SeMenu_CopyWriteUpdate_Step3_Join19
SeTonHyb1TitleFunc_OnSwitchIn:
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeTonHyb1TitleFunc_DispatchSwitch
SeTonHyb1TitleFunc_Nop:
	jp	SeMenu_CopyWriteUpdate_Step3_Return17

SePitPit1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, SePitPit1TitleFunc_Methods
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SePitPit1TitleFunc_OnDraw:
	jp	UpdSeSel_DetailedUpdate_SetDisplayState_Join
SePitPit1TitleFunc_OnHide:
	jp	SeMenu_CopyWriteUpdate_Step3_Join4
SePitPit1TitleFunc_OnSwitchIn:
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SePitPit1TitleFunc_DispatchSwitch
SePitPit1TitleFunc_Nop:
	jp	SeMenu_CopyWriteUpdate_Step3_Return2

SePitEnv1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, SePitEnv1TitleFunc_Methods
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SePitEnv1TitleFunc_OnDraw:
	jp	UpdSeSel_DetailedUpdate_SetDisplayState_Join2
SePitEnv1TitleFunc_OnHide:
	jp	SeMenu_CopyWriteUpdate_Step3_Join5
SePitEnv1TitleFunc_OnSwitchIn:
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SePitEnv1TitleFunc_DispatchSwitch
SePitEnv1TitleFunc_Nop:
	jp	SeMenu_CopyWriteUpdate_Step3_Return3

SePitEnv2TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, SePitEnv2TitleFunc_Methods
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SePitEnv2TitleFunc_OnDraw:
	jp	UpdSeSel_DetailedUpdate_SetDisplayState_Join3
SePitEnv2TitleFunc_OnHide:
	jp	SeMenu_CopyWriteUpdate_Step3_Join6
SePitEnv2TitleFunc_OnSwitchIn:
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SePitEnv2TitleFunc_DispatchSwitch
SePitEnv2TitleFunc_Nop:
	jp	SeMenu_CopyWriteUpdate_Step3_Return4

SePitLfo1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, SePitLfo1TitleFunc_Methods
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SePitLfo1TitleFunc_OnDraw:
	jp	UpdSeSel_DetailedUpdate_SetDisplayState_Join4
SePitLfo1TitleFunc_OnHide:
	jp	SeMenu_CopyWriteUpdate_Step3_Join7
SePitLfo1TitleFunc_OnSwitchIn:
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SePitLfo1TitleFunc_DispatchSwitch
SePitLfo1TitleFunc_Nop:
	jp	SeMenu_CopyWriteUpdate_Step3_Return5

SeAmpAmp1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, SeAmpAmp1TitleFunc_Methods
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeAmpAmp1TitleFunc_OnDraw:
	jp	UpdSeSel_DetailedUpdate_SetDisplayState_Join5
SeAmpAmp1TitleFunc_OnHide:
	jp	SeMenu_CopyWriteUpdate_Step3_Join8
SeAmpAmp1TitleFunc_OnSwitchIn:
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeAmpAmp1TitleFunc_DispatchSwitch
SeAmpAmp1TitleFunc_Nop:
	jp	SeMenu_CopyWriteUpdate_Step3_Return6

SeAmpAmp2TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, SeAmpAmp2TitleFunc_Methods
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeAmpAmp2TitleFunc_OnDraw:
	jp	UpdSeSel_DetailedUpdate_SetDisplayState_Join6
SeAmpAmp2TitleFunc_OnHide:
	jp	SeMenu_CopyWriteUpdate_Step3_Join9
SeAmpAmp2TitleFunc_OnSwitchIn:
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeAmpAmp2TitleFunc_DispatchSwitch
SeAmpAmp2TitleFunc_Nop:
	jp	SeMenu_CopyWriteUpdate_Step3_Return7

SeAmpEnv1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, SeAmpEnv1TitleFunc_Methods
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeAmpEnv1TitleFunc_OnDraw:
	jp	UpdSeSel_DetailedUpdate_SetDisplayState_Join7
SeAmpEnv1TitleFunc_OnHide:
	jp	SeMenu_CopyWriteUpdate_Step3_Join10
SeAmpEnv1TitleFunc_OnSwitchIn:
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeAmpEnv1TitleFunc_DispatchSwitch
SeAmpEnv1TitleFunc_Nop:
	jp	SeMenu_CopyWriteUpdate_Step3_Return8

SeAmpEnv2TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, SeAmpEnv2TitleFunc_Methods
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeAmpEnv2TitleFunc_OnDraw:
	jp	UpdSeSel_DetailedUpdate_SetDisplayState_Join8
SeAmpEnv2TitleFunc_OnHide:
	jp	SeMenu_CopyWriteUpdate_Step3_Join11
SeAmpEnv2TitleFunc_OnSwitchIn:
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeAmpEnv2TitleFunc_DispatchSwitch
SeAmpEnv2TitleFunc_Nop:
	jp	SeMenu_CopyWriteUpdate_Step3_Return9

SeAmpLfo1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, SeAmpLfo1TitleFunc_Methods
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeAmpLfo1TitleFunc_OnDraw:
	jp	UpdSeSel_DetailedUpdate_SetDisplayState_Join9
SeAmpLfo1TitleFunc_OnHide:
	jp	SeMenu_CopyWriteUpdate_Step3_Join12
SeAmpLfo1TitleFunc_OnSwitchIn:
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeAmpLfo1TitleFunc_DispatchSwitch
SeAmpLfo1TitleFunc_Nop:
	jp	SeMenu_CopyWriteUpdate_Step3_Return10

SeFilLpq1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, SeFilLpq1TitleFunc_Methods
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeFilLpq1TitleFunc_OnDraw:
	jp	UpdSeSel_DetailedUpdate_SetDisplayState_Join12
SeFilLpq1TitleFunc_OnHide:
	jp	SeMenu_CopyWriteUpdate_Step3_Join20
SeFilLpq1TitleFunc_OnSwitchIn:
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeFilLpq1TitleFunc_DispatchSwitch
SeFilLpq1TitleFunc_Nop:
	jp	SeMenu_CopyWriteUpdate_Step3_Return18

SeFilHpq1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, SeFilHpq1TitleFunc_Methods
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeFilHpq1TitleFunc_OnDraw:
	jp	UpdSeSel_DetailedUpdate_SetDisplayState_Join13
SeFilHpq1TitleFunc_OnHide:
	jp	SeMenu_CopyWriteUpdate_Step3_Join21
SeFilHpq1TitleFunc_OnSwitchIn:
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeFilHpq1TitleFunc_DispatchSwitch
SeFilHpq1TitleFunc_Nop:
	jp	SeMenu_CopyWriteUpdate_Step3_Return19

SeFilL241TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, SeFilL241TitleFunc_Methods
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeFilL241TitleFunc_OnDraw:
	jp	UpdSeSel_DetailedUpdate_SetDisplayState_Join14
SeFilL241TitleFunc_OnHide:
	jp	SeMenu_CopyWriteUpdate_Step3_Join22
SeFilL241TitleFunc_OnSwitchIn:
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeFilL241TitleFunc_DispatchSwitch
SeFilL241TitleFunc_Nop:
	jp	SeMenu_CopyWriteUpdate_Step3_Return20

SeFilH241TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, SeFilH241TitleFunc_Methods
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeFilH241TitleFunc_OnDraw:
	jp	UpdSeSel_DetailedUpdate_SetDisplayState_Join15
SeFilH241TitleFunc_OnHide:
	jp	SeMenu_CopyWriteUpdate_Step3_Join23
SeFilH241TitleFunc_OnSwitchIn:
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeFilH241TitleFunc_DispatchSwitch
SeFilH241TitleFunc_Nop:
	jp	SeMenu_CopyWriteUpdate_Step3_Return21

SeFilBpf1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, SeFilBpf1TitleFunc_Methods
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeFilBpf1TitleFunc_OnDraw:
	jp	UpdSeSel_DetailedUpdate_SetDisplayState_Join16
SeFilBpf1TitleFunc_OnHide:
	jp	SeMenu_CopyWriteUpdate_Step3_Join24
SeFilBpf1TitleFunc_OnSwitchIn:
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeFilBpf1TitleFunc_DispatchSwitch
SeFilBpf1TitleFunc_Nop:
	jp	SeMenu_CopyWriteUpdate_Step3_Return22

SeFilBcf1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, SeFilBcf1TitleFunc_Methods
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeFilBcf1TitleFunc_OnDraw:
	jp	UpdSeSel_DetailedUpdate_SetDisplayState_Join17
SeFilBcf1TitleFunc_OnHide:
	jp	SeMenu_CopyWriteUpdate_Step3_Join25
SeFilBcf1TitleFunc_OnSwitchIn:
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeFilBcf1TitleFunc_DispatchSwitch
SeFilBcf1TitleFunc_Nop:
	jp	SeMenu_CopyWriteUpdate_Step3_Return23

SeFilFil2TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, SeFilFil2TitleFunc_Methods
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeFilFil2TitleFunc_OnDraw:
	jp	UpdSeSel_DetailedUpdate_SetDisplayState_Join18
SeFilFil2TitleFunc_OnHide:
	jp	SeMenu_CopyWriteUpdate_Step3_Join26
SeFilFil2TitleFunc_OnSwitchIn:
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeFilFil2TitleFunc_DispatchSwitch
SeFilFil2TitleFunc_Nop:
	jp	SeMenu_CopyWriteUpdate_Step3_Return24

SeFilEnv1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, SeFilEnv1TitleFunc_Methods
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeFilEnv1TitleFunc_OnDraw:
	jp	UpdSeSel_DetailedUpdate_SetDisplayState_Join19
SeFilEnv1TitleFunc_OnHide:
	jp	SeMenu_CopyWriteUpdate_Step3_Join27
SeFilEnv1TitleFunc_OnSwitchIn:
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeFilEnv1TitleFunc_DispatchSwitch
SeFilEnv1TitleFunc_Nop:
	jp	SeMenu_CopyWriteUpdate_Step3_Return25

SeFilEnv2TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, SeFilEnv2TitleFunc_Methods
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeFilEnv2TitleFunc_OnDraw:
	jp	UpdSeSel_DetailedUpdate_SetDisplayState_Join20
SeFilEnv2TitleFunc_OnHide:
	jp	SeMenu_CopyWriteUpdate_Step3_Join28
SeFilEnv2TitleFunc_OnSwitchIn:
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeFilEnv2TitleFunc_DispatchSwitch
SeFilEnv2TitleFunc_Nop:
	jp	SeMenu_CopyWriteUpdate_Step3_Return26

SeFilLfo1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, SeFilLfo1TitleFunc_Methods
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeFilLfo1TitleFunc_OnDraw:
	jp	UpdSeSel_DetailedUpdate_SetDisplayState_Join21
SeFilLfo1TitleFunc_OnHide:
	jp	SeMenu_CopyWriteUpdate_Step3_Join29
SeFilLfo1TitleFunc_OnSwitchIn:
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeFilLfo1TitleFunc_DispatchSwitch
SeFilLfo1TitleFunc_Nop:
	jp	SeMenu_CopyWriteUpdate_Step3_Return27

SeDigEffTitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, SeDigEffTitleFunc_Methods
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeDigEffTitleFunc_OnDraw:
	jp	SeMenu_CopyWriteUpdate_Step3_Join
SeDigEffTitleFunc_OnHide:
	jp	SeMenu_CopyWriteUpdate_Step3_Join31
SeDigEffTitleFunc_OnSwitchIn:
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeDigEffTitleFunc_DispatchSwitch
SeDigEffTitleFunc_Nop:
	jp	SeMenu_CopyWriteUpdate_Step3_Return31

SeCtr2TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, SeCtr2TitleFunc_Methods
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeCtr2TitleFunc_OnDraw:
	jp	UpdSeSel_DetailedUpdate_SetDisplayState_Join10
SeCtr2TitleFunc_OnHide:
	jp	SeMenu_CopyWriteUpdate_Step3_Join13
SeCtr2TitleFunc_OnSwitchIn:
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeCtr2TitleFunc_DispatchSwitch
SeCtr2TitleFunc_Nop:
	jp	SeMenu_CopyWriteUpdate_Step3_Return11

SeCtr3TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, SeCtr3TitleFunc_Methods
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeCtr3TitleFunc_OnDraw:
	jp	UpdSeSel_DetailedUpdate_SetDisplayState_Join11
SeCtr3TitleFunc_OnHide:
	jp	SeMenu_CopyWriteUpdate_Step3_Join14
SeCtr3TitleFunc_OnSwitchIn:
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeCtr3TitleFunc_DispatchSwitch
SeCtr3TitleFunc_Nop:
	jp	SeMenu_CopyWriteUpdate_Step3_Return12

SeCopyTitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, SeCopyTitleFunc_Methods
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeCopyTitleFunc_OnDraw:
	jp	SeMenu_CopyWriteUpdate_Step3_Join2
SeCopyTitleFunc_OnHide:
	jp	SeMenu_CopyWriteUpdate_Step3_Join32
SeCopyTitleFunc_OnSwitchIn:
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeCopyTitleFunc_DispatchSwitch
SeCopyTitleFunc_Nop:
	jp	SeMenu_CopyWriteUpdate_Step3_Return32

SeWrtMemTitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, SeWrtMemTitleFunc_Methods
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeWrtMemTitleFunc_OnDraw:
	jp	SeMenu_CopyWriteUpdate_Data
SeWrtMemTitleFunc_OnHide:
	jp	SeMenu_CopyWriteUpdate_Step3_Return28
SeWrtMemTitleFunc_OnSwitchIn:
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeWrtMemTitleFunc_DispatchSwitch
SeWrtMemTitleFunc_Nop:
	jp	SeMenu_CopyWriteUpdate_Step3_Return29

SeWrtSndTitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, SeWrtSndTitleFunc_Methods
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

; End of Sound Editor routines

