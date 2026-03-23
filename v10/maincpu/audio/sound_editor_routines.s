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
	cp xbc, 0x1C00013
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
	ld xiy, 0xE0DAB6
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
	jp	15776726
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	15777606
	jp	15776736

SeEasyTitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, 0xE0DAC6
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
	jp	15777038
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	15783696
	jp	15777048

SeTonTon1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, 0xE0DAD6
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
	jp	15776869
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	15779545
	jp	15776879

SeTonTon2TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, 0xE0DAE6
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
	jp	15776880
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	15779591
	jp	15776890

SeTonRan1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, 0xE0DAF6
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeTonRan1TitleFunc_DisplayData:
	jp	15775280
	jp	15776891
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	15779637
	jp	15776901

SeTonRan2TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, 0xE0DB06
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeTonRan2TitleFunc_DisplayData:
	jp	15775503
	jp	15776902
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	15779683
	jp	15776912

SeTonHyb1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, 0xE0DB16
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
	jp	15776913
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	15779729
	jp	15776923

SePitPit1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, 0xE0DB26
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SePitPit1TitleFunc_DisplayData:
	jp	15771526
	jp	15776737
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	15768272
	jp	15776747

SePitEnv1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, 0xE0DB36
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SePitEnv1TitleFunc_DisplayData:
	jp	15771803
	jp	15776748
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	15768318
	jp	15776758

SePitEnv2TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, 0xE0DB46
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SePitEnv2TitleFunc_DisplayData:
	jp	15771953
	jp	15776759
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	15768364
	jp	15776769

SePitLfo1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, 0xE0DB56
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SePitLfo1TitleFunc_DisplayData:
	jp	15772123
	jp	15776770
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	15768410
	jp	15776780

SeAmpAmp1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, 0xE0DB66
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeAmpAmp1TitleFunc_DisplayData:
	jp	15772387
	jp	15776781
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	15744435
	jp	15776791

SeAmpAmp2TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, 0xE0DB76
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeAmpAmp2TitleFunc_DisplayData:
	jp	15772723
	jp	15776792
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	15744481
	jp	15776802

SeAmpEnv1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, 0xE0DB86
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeAmpEnv1TitleFunc_DisplayData:
	jp	15772884
	jp	15776803
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	15744527
	jp	15776813

SeAmpEnv2TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, 0xE0DB96
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeAmpEnv2TitleFunc_DisplayData:
	jp	15773136
	jp	15776814
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	15744573
	jp	15776824

SeAmpLfo1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, 0xE0DBA6
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeAmpLfo1TitleFunc_DisplayData:
	jp	15773307
	jp	15776825
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	15744619
	jp	15776835

SeFilLpq1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, 0xE0DBB6
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeFilLpq1TitleFunc_DisplayData:
	jp	15773775
	jp	15776924
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	15748702
	jp	15776934

SeFilHpq1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, 0xE0DBC6
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeFilHpq1TitleFunc_DisplayData:
	jp	15774091
	jp	15776935
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	15748748
	jp	15776945

SeFilL241TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, 0xE0DBD6
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeFilL241TitleFunc_DisplayData:
	jp	15774118
	jp	15776946
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	15748794
	jp	15776956

SeFilH241TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, 0xE0DBE6
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeFilH241TitleFunc_DisplayData:
	jp	15774141
	jp	15776957
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	15748840
	jp	15776967

SeFilBpf1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, 0xE0DBF6
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeFilBpf1TitleFunc_DisplayData:
	jp	15774164
	jp	15776968
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	15748886
	jp	15776978

SeFilBcf1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, 0xE0DC06
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeFilBcf1TitleFunc_DisplayData:
	jp	15774183
	jp	15776979
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	15748932
	jp	15776989

SeFilFil2TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, 0xE0DC16
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeFilFil2TitleFunc_DisplayData:
	jp	15774198
	jp	15776990
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	15748978
	jp	15777000

SeFilEnv1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, 0xE0DC26
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeFilEnv1TitleFunc_DisplayData:
	jp	15774359
	jp	15777001
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	15749024
	jp	15777011

SeFilEnv2TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, 0xE0DC36
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeFilEnv2TitleFunc_DisplayData:
	jp	15774509
	jp	15777012
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	15749070
	jp	15777022

SeFilLfo1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, 0xE0DC46
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeFilLfo1TitleFunc_DisplayData:
	jp	15774679
	jp	15777023
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	15749116
	jp	15777033

SeDigEffTitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, 0xE0DC56
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeDigEffTitleFunc_DisplayData:
	jp	15776472
	jp	15777049
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	15783880
	jp	15777059

SeCtr2TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, 0xE0DC66
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeCtr2TitleFunc_DisplayData:
	jp	15773313
	jp	15776847
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	15777071
	jp	15776857

SeCtr3TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, 0xE0DC76
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeCtr3TitleFunc_DisplayData:
	jp	15773707
	jp	15776858
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	15777117
	jp	15776868

SeCopyTitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, 0xE0DC86
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeCopyTitleFunc_DisplayData:
	jp	15776637
	jp	15777060
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	15783742
	jp	15777070

SeWrtMemTitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, 0xE0DC96
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
	jp	15777034
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	15783788
	jp	15777035

SeWrtSndTitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, 0xE0DCA6
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

; End of Sound Editor routines

