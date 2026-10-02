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
	ld xiy, GUI_DisplayStructData_0xAD8
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeMenuTitleFunc_DisplayData:
	jp	UpdSeSel_ProcessStep
	jp	SeMenu_CopyWriteUpdate_Step3_Join3
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeMenu_CopyWriteUpdate_Step3_Join35
	jp	SeMenu_CopyWriteUpdate_Step3_Return

SeEasyTitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xAE8
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeEasyTitleFunc_DisplayData:
	jp	UpdSeSel_ExtendedOps_Data
	jp	SeMenu_CopyWriteUpdate_Step3_Join30
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeMenu_CopyWriteUpdate_Step3_Join41
	jp	SeMenu_CopyWriteUpdate_Step3_Return30

SeTonTon1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xAF8
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeTonTon1TitleFunc_DisplayData:
	jp	SeMenu_AltUpdate
	jp	SeMenu_CopyWriteUpdate_Step3_Join15
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeMenu_CopyWriteUpdate_Step3_Join36
	jp	SeMenu_CopyWriteUpdate_Step3_Return13

SeTonTon2TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xB08
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeTonTon2TitleFunc_DisplayData:
	jp	SeMenu_AltUpdate_Data
	jp	SeMenu_CopyWriteUpdate_Step3_Join16
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeMenu_CopyWriteUpdate_Step3_Join37
	jp	SeMenu_CopyWriteUpdate_Step3_Return14

SeTonRan1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xB18
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeTonRan1TitleFunc_DisplayData:
	jp	SeMenu_AltUpdate_Step3Plus_Join
	jp	SeMenu_CopyWriteUpdate_Step3_Join17
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeMenu_CopyWriteUpdate_Step3_Join38
	jp	SeMenu_CopyWriteUpdate_Step3_Return15

SeTonRan2TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xB28
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeTonRan2TitleFunc_DisplayData:
	jp	SeMenu_AltUpdate_Step3Plus_Join2
	jp	SeMenu_CopyWriteUpdate_Step3_Join18
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeMenu_CopyWriteUpdate_Step3_Join39
	jp	SeMenu_CopyWriteUpdate_Step3_Return16

SeTonHyb1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xB38
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeTonHyb1TitleFunc_DisplayData:
	jp	SeMenu_ControllerUpdate
	jp	SeMenu_CopyWriteUpdate_Step3_Join19
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeMenu_CopyWriteUpdate_Step3_Join40
	jp	SeMenu_CopyWriteUpdate_Step3_Return17

SePitPit1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xB48
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SePitPit1TitleFunc_DisplayData:
	jp	UpdSeSel_DetailedUpdate_SetDisplayState_Join
	jp	SeMenu_CopyWriteUpdate_Step3_Join4
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeMenu_RefreshPartDisplay_Join5
	jp	SeMenu_CopyWriteUpdate_Step3_Return2

SePitEnv1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xB58
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SePitEnv1TitleFunc_DisplayData:
	jp	UpdSeSel_DetailedUpdate_SetDisplayState_Join2
	jp	SeMenu_CopyWriteUpdate_Step3_Join5
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeMenu_RefreshPartDisplay_Join6
	jp	SeMenu_CopyWriteUpdate_Step3_Return3

SePitEnv2TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xB68
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SePitEnv2TitleFunc_DisplayData:
	jp	UpdSeSel_DetailedUpdate_SetDisplayState_Join3
	jp	SeMenu_CopyWriteUpdate_Step3_Join6
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeMenu_RefreshPartDisplay_Join7
	jp	SeMenu_CopyWriteUpdate_Step3_Return4

SePitLfo1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xB78
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SePitLfo1TitleFunc_DisplayData:
	jp	UpdSeSel_DetailedUpdate_SetDisplayState_Join4
	jp	SeMenu_CopyWriteUpdate_Step3_Join7
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeMenu_RefreshPartDisplay_Join8
	jp	SeMenu_CopyWriteUpdate_Step3_Return5

SeAmpAmp1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xB88
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeAmpAmp1TitleFunc_DisplayData:
	jp	UpdSeSel_DetailedUpdate_SetDisplayState_Join5
	jp	SeMenu_CopyWriteUpdate_Step3_Join8
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	Scoop_SoundEditorData_Join56
	jp	SeMenu_CopyWriteUpdate_Step3_Return6

SeAmpAmp2TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xB98
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeAmpAmp2TitleFunc_DisplayData:
	jp	UpdSeSel_DetailedUpdate_SetDisplayState_Join6
	jp	SeMenu_CopyWriteUpdate_Step3_Join9
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	Scoop_SoundEditorData_Join57
	jp	SeMenu_CopyWriteUpdate_Step3_Return7

SeAmpEnv1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xBA8
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeAmpEnv1TitleFunc_DisplayData:
	jp	UpdSeSel_DetailedUpdate_SetDisplayState_Join7
	jp	SeMenu_CopyWriteUpdate_Step3_Join10
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	Scoop_SoundEditorData_Join58
	jp	SeMenu_CopyWriteUpdate_Step3_Return8

SeAmpEnv2TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xBB8
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeAmpEnv2TitleFunc_DisplayData:
	jp	UpdSeSel_DetailedUpdate_SetDisplayState_Join8
	jp	SeMenu_CopyWriteUpdate_Step3_Join11
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	Scoop_SoundEditorData_Join59
	jp	SeMenu_CopyWriteUpdate_Step3_Return9

SeAmpLfo1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xBC8
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeAmpLfo1TitleFunc_DisplayData:
	jp	UpdSeSel_DetailedUpdate_SetDisplayState_Join9
	jp	SeMenu_CopyWriteUpdate_Step3_Join12
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	Scoop_SoundEditorData_0xEB
	jp	SeMenu_CopyWriteUpdate_Step3_Return10

SeFilLpq1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xBD8
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeFilLpq1TitleFunc_DisplayData:
	jp	UpdSeSel_DetailedUpdate_SetDisplayState_Join12
	jp	SeMenu_CopyWriteUpdate_Step3_Join20
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	Scoop_SoundEditorData_Join60
	jp	SeMenu_CopyWriteUpdate_Step3_Return18

SeFilHpq1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xBE8
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeFilHpq1TitleFunc_DisplayData:
	jp	UpdSeSel_DetailedUpdate_SetDisplayState_Join13
	jp	SeMenu_CopyWriteUpdate_Step3_Join21
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	Scoop_SoundEditorData_Join61
	jp	SeMenu_CopyWriteUpdate_Step3_Return19

SeFilL241TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xBF8
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeFilL241TitleFunc_DisplayData:
	jp	UpdSeSel_DetailedUpdate_SetDisplayState_Join14
	jp	SeMenu_CopyWriteUpdate_Step3_Join22
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	Scoop_SoundEditorData_Join62
	jp	SeMenu_CopyWriteUpdate_Step3_Return20

SeFilH241TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xC08
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeFilH241TitleFunc_DisplayData:
	jp	UpdSeSel_DetailedUpdate_SetDisplayState_Join15
	jp	SeMenu_CopyWriteUpdate_Step3_Join23
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	Scoop_SoundEditorData_Join63
	jp	SeMenu_CopyWriteUpdate_Step3_Return21

SeFilBpf1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xC18
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeFilBpf1TitleFunc_DisplayData:
	jp	UpdSeSel_DetailedUpdate_SetDisplayState_Join16
	jp	SeMenu_CopyWriteUpdate_Step3_Join24
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	Scoop_SoundEditorData_Join64
	jp	SeMenu_CopyWriteUpdate_Step3_Return22

SeFilBcf1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xC28
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeFilBcf1TitleFunc_DisplayData:
	jp	UpdSeSel_DetailedUpdate_SetDisplayState_Join17
	jp	SeMenu_CopyWriteUpdate_Step3_Join25
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	Scoop_SoundEditorData_Join65
	jp	SeMenu_CopyWriteUpdate_Step3_Return23

SeFilFil2TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xC38
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeFilFil2TitleFunc_DisplayData:
	jp	UpdSeSel_DetailedUpdate_SetDisplayState_Join18
	jp	SeMenu_CopyWriteUpdate_Step3_Join26
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	Scoop_SoundEditorData_Join66
	jp	SeMenu_CopyWriteUpdate_Step3_Return24

SeFilEnv1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xC48
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeFilEnv1TitleFunc_DisplayData:
	jp	UpdSeSel_DetailedUpdate_SetDisplayState_Join19
	jp	SeMenu_CopyWriteUpdate_Step3_Join27
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	Scoop_SoundEditorData_Join67
	jp	SeMenu_CopyWriteUpdate_Step3_Return25

SeFilEnv2TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xC58
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeFilEnv2TitleFunc_DisplayData:
	jp	UpdSeSel_DetailedUpdate_SetDisplayState_Join20
	jp	SeMenu_CopyWriteUpdate_Step3_Join28
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	Scoop_SoundEditorData_Join68
	jp	SeMenu_CopyWriteUpdate_Step3_Return26

SeFilLfo1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xC68
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeFilLfo1TitleFunc_DisplayData:
	jp	UpdSeSel_DetailedUpdate_SetDisplayState_Join21
	jp	SeMenu_CopyWriteUpdate_Step3_Join29
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	Scoop_SoundEditorData_0x127C
	jp	SeMenu_CopyWriteUpdate_Step3_Return27

SeDigEffTitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xC78
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeDigEffTitleFunc_DisplayData:
	jp	SeMenu_CopyWriteUpdate_Step3_Join
	jp	SeMenu_CopyWriteUpdate_Step3_Join31
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeMenu_CopyWriteUpdate_Step3_Join44
	jp	SeMenu_CopyWriteUpdate_Step3_Return31

SeCtr2TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xC88
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeCtr2TitleFunc_DisplayData:
	jp	UpdSeSel_DetailedUpdate_SetDisplayState_Join10
	jp	SeMenu_CopyWriteUpdate_Step3_Join13
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeMenu_CopyWriteUpdate_Step3_Join33
	jp	SeMenu_CopyWriteUpdate_Step3_Return11

SeCtr3TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xC98
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeCtr3TitleFunc_DisplayData:
	jp	UpdSeSel_DetailedUpdate_SetDisplayState_Join11
	jp	SeMenu_CopyWriteUpdate_Step3_Join14
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeMenu_CopyWriteUpdate_Step3_Join34
	jp	SeMenu_CopyWriteUpdate_Step3_Return12

SeCopyTitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xCA8
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeCopyTitleFunc_DisplayData:
	jp	SeMenu_CopyWriteUpdate_Step3_Join2
	jp	SeMenu_CopyWriteUpdate_Step3_Join32
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeMenu_CopyWriteUpdate_Step3_Join42
	jp	SeMenu_CopyWriteUpdate_Step3_Return32

SeWrtMemTitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xCB8
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeWrtMemTitleFunc_DisplayData:
	jp	SeMenu_CopyWriteUpdate_Data
	jp	SeMenu_CopyWriteUpdate_Step3_Return28
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeMenu_CopyWriteUpdate_Step3_Join43
	jp	SeMenu_CopyWriteUpdate_Step3_Return29

SeWrtSndTitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xCC8
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

; End of Sound Editor routines

