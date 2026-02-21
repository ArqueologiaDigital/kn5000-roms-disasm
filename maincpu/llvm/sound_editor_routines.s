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
	; (no addr) CP XBC, 01c00013h
	; (no addr) RET NZ
	; (no addr) CP XDE, 00000001h
	; (no addr) JR Z, SeMenuModeFunc_Handler
	; (no addr) OR XDE, XDE
	; (no addr) RET NZ
	; (no addr) JP InitializeSeMenuDefaults

SeMenuModeFunc_Handler:
	; (no addr) CALL UpdateSeMenuSelection
	; (no addr) RET

SeMenuTitleFunc:
	; (no addr) LDA XSP, XSP - 010h
	; (no addr) LD XHL, XBC
	; (no addr) LD XIY, 00e0dab6h
	; (no addr) LD XIX, XSP
	; (no addr) LD BC, 0008h
	LDIRW_95
	; (no addr) LDA XWA, XSP
	; (no addr) LD XBC, XHL
	; (no addr) CALL DirmdEmulator
	; (no addr) LDA XSP, XSP + 010h
	; (no addr) RET

SeMenuTitleFunc_DisplayData:
	.byte 0x1B, 0x62, 0xA1, 0xF0, 0x1B, 0xD6, 0xBB, 0xF0
	.byte 0x9F, 0x4, 0x20, 0x9F, 0x6, 0x21, 0x1B, 0x46
	.byte 0xBF, 0xF0, 0x1B, 0xE0, 0xBB, 0xF0

SeEasyTitleFunc:
	; (no addr) LDA XSP, XSP - 010h
	; (no addr) LD XHL, XBC
	; (no addr) LD XIY, 00e0dac6h
	; (no addr) LD XIX, XSP
	; (no addr) LD BC, 0008h
	LDIRW_95
	; (no addr) LDA XWA, XSP
	; (no addr) LD XBC, XHL
	; (no addr) CALL DirmdEmulator
	; (no addr) LDA XSP, XSP + 010h
	; (no addr) RET

SeEasyTitleFunc_DisplayData:
	.byte 0x1B, 0xA5, 0xA6, 0xF0, 0x1B, 0xE, 0xBD, 0xF0
	.byte 0x9F, 0x4, 0x20, 0x9F, 0x6, 0x21, 0x1B, 0x10
	.byte 0xD7, 0xF0, 0x1B, 0x18, 0xBD, 0xF0

SeTonTon1TitleFunc:
	; (no addr) LDA XSP, XSP - 010h
	; (no addr) LD XHL, XBC
	; (no addr) LD XIY, 00e0dad6h
	; (no addr) LD XIX, XSP
	; (no addr) LD BC, 0008h
	LDIRW_95
	; (no addr) LDA XWA, XSP
	; (no addr) LD XBC, XHL
	; (no addr) CALL DirmdEmulator
	; (no addr) LDA XSP, XSP + 010h
	; (no addr) RET

SeTonTon1TitleFunc_DisplayData:
	.byte 0x1B, 0xDD, 0xB3, 0xF0, 0x1B, 0x65, 0xBC, 0xF0
	.byte 0x9F, 0x4, 0x20, 0x9F, 0x6, 0x21, 0x1B, 0xD9
	.byte 0xC6, 0xF0, 0x1B, 0x6F, 0xBC, 0xF0

SeTonTon2TitleFunc:
	; (no addr) LDA XSP, XSP - 010h
	; (no addr) LD XHL, XBC
	; (no addr) LD XIY, 00e0dae6h
	; (no addr) LD XIX, XSP
	; (no addr) LD BC, 0008h
	LDIRW_95
	; (no addr) LDA XWA, XSP
	; (no addr) LD XBC, XHL
	; (no addr) CALL DirmdEmulator
	; (no addr) LDA XSP, XSP + 010h
	; (no addr) RET

SeTonTon2TitleFunc_DisplayData:
	.byte 0x1B, 0x54, 0xB5, 0xF0, 0x1B, 0x70, 0xBC, 0xF0
	.byte 0x9F, 0x4, 0x20, 0x9F, 0x6, 0x21, 0x1B, 0x7
	.byte 0xC7, 0xF0, 0x1B, 0x7A, 0xBC, 0xF0

SeTonRan1TitleFunc:
	; (no addr) LDA XSP, XSP - 010h
	; (no addr) LD XHL, XBC
	; (no addr) LD XIY, 00e0daf6h
	; (no addr) LD XIX, XSP
	; (no addr) LD BC, 0008h
	LDIRW_95
	; (no addr) LDA XWA, XSP
	; (no addr) LD XBC, XHL
	; (no addr) CALL DirmdEmulator
	; (no addr) LDA XSP, XSP + 010h
	; (no addr) RET

SeTonRan1TitleFunc_DisplayData:
	.byte 0x1B, 0x30, 0xB6, 0xF0, 0x1B, 0x7B, 0xBC, 0xF0
	.byte 0x9F, 0x4, 0x20, 0x9F, 0x6, 0x21, 0x1B, 0x35
	.byte 0xC7, 0xF0, 0x1B, 0x85, 0xBC, 0xF0

SeTonRan2TitleFunc:
	; (no addr) LDA XSP, XSP - 010h
	; (no addr) LD XHL, XBC
	; (no addr) LD XIY, 00e0db06h
	; (no addr) LD XIX, XSP
	; (no addr) LD BC, 0008h
	LDIRW_95
	; (no addr) LDA XWA, XSP
	; (no addr) LD XBC, XHL
	; (no addr) CALL DirmdEmulator
	; (no addr) LDA XSP, XSP + 010h
	; (no addr) RET

SeTonRan2TitleFunc_DisplayData:
	.byte 0x1B, 0xF, 0xB7, 0xF0, 0x1B, 0x86, 0xBC, 0xF0
	.byte 0x9F, 0x4, 0x20, 0x9F, 0x6, 0x21, 0x1B, 0x63
	.byte 0xC7, 0xF0, 0x1B, 0x90, 0xBC, 0xF0

SeTonHyb1TitleFunc:
	; (no addr) LDA XSP, XSP - 010h
	; (no addr) LD XHL, XBC
	; (no addr) LD XIY, 00e0db16h
	; (no addr) LD XIX, XSP
	; (no addr) LD BC, 0008h
	LDIRW_95
	; (no addr) LDA XWA, XSP
	; (no addr) LD XBC, XHL
	; (no addr) CALL DirmdEmulator
	; (no addr) LDA XSP, XSP + 010h
	; (no addr) RET

SeTonHyb1TitleFunc_DisplayData:
	.byte 0x1B, 0xEE, 0xB7, 0xF0, 0x1B, 0x91, 0xBC, 0xF0
	.byte 0x9F, 0x4, 0x20, 0x9F, 0x6, 0x21, 0x1B, 0x91
	.byte 0xC7, 0xF0, 0x1B, 0x9B, 0xBC, 0xF0

SePitPit1TitleFunc:
	; (no addr) LDA XSP, XSP - 010h
	; (no addr) LD XHL, XBC
	; (no addr) LD XIY, 00e0db26h
	; (no addr) LD XIX, XSP
	; (no addr) LD BC, 0008h
	LDIRW_95
	; (no addr) LDA XWA, XSP
	; (no addr) LD XBC, XHL
	; (no addr) CALL DirmdEmulator
	; (no addr) LDA XSP, XSP + 010h
	; (no addr) RET

SePitPit1TitleFunc_DisplayData:
	.byte 0x1B, 0x86, 0xA7, 0xF0, 0x1B, 0xE1, 0xBB, 0xF0
	.byte 0x9F, 0x4, 0x20, 0x9F, 0x6, 0x21, 0x1B, 0xD0
	.byte 0x9A, 0xF0, 0x1B, 0xEB, 0xBB, 0xF0

SePitEnv1TitleFunc:
	; (no addr) LDA XSP, XSP - 010h
	; (no addr) LD XHL, XBC
	; (no addr) LD XIY, 00e0db36h
	; (no addr) LD XIX, XSP
	; (no addr) LD BC, 0008h
	LDIRW_95
	; (no addr) LDA XWA, XSP
	; (no addr) LD XBC, XHL
	; (no addr) CALL DirmdEmulator
	; (no addr) LDA XSP, XSP + 010h
	; (no addr) RET

SePitEnv1TitleFunc_DisplayData:
	.byte 0x1B, 0x9B, 0xA8, 0xF0, 0x1B, 0xEC, 0xBB, 0xF0
	.byte 0x9F, 0x4, 0x20, 0x9F, 0x6, 0x21, 0x1B, 0xFE
	.byte 0x9A, 0xF0, 0x1B, 0xF6, 0xBB, 0xF0

SePitEnv2TitleFunc:
	; (no addr) LDA XSP, XSP - 010h
	; (no addr) LD XHL, XBC
	; (no addr) LD XIY, 00e0db46h
	; (no addr) LD XIX, XSP
	; (no addr) LD BC, 0008h
	LDIRW_95
	; (no addr) LDA XWA, XSP
	; (no addr) LD XBC, XHL
	; (no addr) CALL DirmdEmulator
	; (no addr) LDA XSP, XSP + 010h
	; (no addr) RET

SePitEnv2TitleFunc_DisplayData:
	.byte 0x1B, 0x31, 0xA9, 0xF0, 0x1B, 0xF7, 0xBB, 0xF0
	.byte 0x9F, 0x4, 0x20, 0x9F, 0x6, 0x21, 0x1B, 0x2C
	.byte 0x9B, 0xF0, 0x1B, 0x1, 0xBC, 0xF0

SePitLfo1TitleFunc:
	; (no addr) LDA XSP, XSP - 010h
	; (no addr) LD XHL, XBC
	; (no addr) LD XIY, 00e0db56h
	; (no addr) LD XIX, XSP
	; (no addr) LD BC, 0008h
	LDIRW_95
	; (no addr) LDA XWA, XSP
	; (no addr) LD XBC, XHL
	; (no addr) CALL DirmdEmulator
	; (no addr) LDA XSP, XSP + 010h
	; (no addr) RET

SePitLfo1TitleFunc_DisplayData:
	.byte 0x1B, 0xDB, 0xA9, 0xF0, 0x1B, 0x2, 0xBC, 0xF0
	.byte 0x9F, 0x4, 0x20, 0x9F, 0x6, 0x21, 0x1B, 0x5A
	.byte 0x9B, 0xF0, 0x1B, 0xC, 0xBC, 0xF0

SeAmpAmp1TitleFunc:
	; (no addr) LDA XSP, XSP - 010h
	; (no addr) LD XHL, XBC
	; (no addr) LD XIY, 00e0db66h
	; (no addr) LD XIX, XSP
	; (no addr) LD BC, 0008h
	LDIRW_95
	; (no addr) LDA XWA, XSP
	; (no addr) LD XBC, XHL
	; (no addr) CALL DirmdEmulator
	; (no addr) LDA XSP, XSP + 010h
	; (no addr) RET

SeAmpAmp1TitleFunc_DisplayData:
	.byte 0x1B, 0xE3, 0xAA, 0xF0, 0x1B, 0xD, 0xBC, 0xF0
	.byte 0x9F, 0x4, 0x20, 0x9F, 0x6, 0x21, 0x1B, 0xB3
	.byte 0x3D, 0xF0, 0x1B, 0x17, 0xBC, 0xF0

SeAmpAmp2TitleFunc:
	; (no addr) LDA XSP, XSP - 010h
	; (no addr) LD XHL, XBC
	; (no addr) LD XIY, 00e0db76h
	; (no addr) LD XIX, XSP
	; (no addr) LD BC, 0008h
	LDIRW_95
	; (no addr) LDA XWA, XSP
	; (no addr) LD XBC, XHL
	; (no addr) CALL DirmdEmulator
	; (no addr) LDA XSP, XSP + 010h
	; (no addr) RET

LABEL_F039B7:
	.byte 0x1B, 0x33, 0xAC, 0xF0, 0x1B, 0x18, 0xBC, 0xF0
	.byte 0x9F, 0x4, 0x20, 0x9F, 0x6, 0x21, 0x1B, 0xE1
	.byte 0x3D, 0xF0, 0x1B, 0x22, 0xBC, 0xF0

SeAmpEnv1TitleFunc:
	; (no addr) LDA XSP, XSP - 010h
	; (no addr) LD XHL, XBC
	; (no addr) LD XIY, 00e0db86h
	; (no addr) LD XIX, XSP
	; (no addr) LD BC, 0008h
	LDIRW_95
	; (no addr) LDA XWA, XSP
	; (no addr) LD XBC, XHL
	; (no addr) CALL DirmdEmulator
	; (no addr) LDA XSP, XSP + 010h
	; (no addr) RET

LABEL_F039EA:
	.byte 0x1B, 0xD4, 0xAC, 0xF0, 0x1B, 0x23, 0xBC, 0xF0
	.byte 0x9F, 0x4, 0x20, 0x9F, 0x6, 0x21, 0x1B, 0xF
	.byte 0x3E, 0xF0, 0x1B, 0x2D, 0xBC, 0xF0

SeAmpEnv2TitleFunc:
	; (no addr) LDA XSP, XSP - 010h
	; (no addr) LD XHL, XBC
	; (no addr) LD XIY, 00e0db96h
	; (no addr) LD XIX, XSP
	; (no addr) LD BC, 0008h
	LDIRW_95
	; (no addr) LDA XWA, XSP
	; (no addr) LD XBC, XHL
	; (no addr) CALL DirmdEmulator
	; (no addr) LDA XSP, XSP + 010h
	; (no addr) RET

LABEL_F03A1D:
	.byte 0x1B, 0xD0, 0xAD, 0xF0, 0x1B, 0x2E, 0xBC, 0xF0
	.byte 0x9F, 0x4, 0x20, 0x9F, 0x6, 0x21, 0x1B, 0x3D
	.byte 0x3E, 0xF0, 0x1B, 0x38, 0xBC, 0xF0

SeAmpLfo1TitleFunc:
	; (no addr) LDA XSP, XSP - 010h
	; (no addr) LD XHL, XBC
	; (no addr) LD XIY, 00e0dba6h
	; (no addr) LD XIX, XSP
	; (no addr) LD BC, 0008h
	LDIRW_95
	; (no addr) LDA XWA, XSP
	; (no addr) LD XBC, XHL
	; (no addr) CALL DirmdEmulator
	; (no addr) LDA XSP, XSP + 010h
	; (no addr) RET

LABEL_F03A50:
	.byte 0x1B, 0x7B, 0xAE, 0xF0, 0x1B, 0x39, 0xBC, 0xF0
	.byte 0x9F, 0x4, 0x20, 0x9F, 0x6, 0x21, 0x1B, 0x6B
	.byte 0x3E, 0xF0, 0x1B, 0x43, 0xBC, 0xF0

SeFilLpq1TitleFunc:
	; (no addr) LDA XSP, XSP - 010h
	; (no addr) LD XHL, XBC
	; (no addr) LD XIY, 00e0dbb6h
	; (no addr) LD XIX, XSP
	; (no addr) LD BC, 0008h
	LDIRW_95
	; (no addr) LDA XWA, XSP
	; (no addr) LD XBC, XHL
	; (no addr) CALL DirmdEmulator
	; (no addr) LDA XSP, XSP + 010h
	; (no addr) RET

LABEL_F03A83:
	.byte 0x1B, 0x4F, 0xB0, 0xF0, 0x1B, 0x9C, 0xBC, 0xF0
	.byte 0x9F, 0x4, 0x20, 0x9F, 0x6, 0x21, 0x1B, 0x5E
	.byte 0x4E, 0xF0, 0x1B, 0xA6, 0xBC, 0xF0

SeFilHpq1TitleFunc:
	; (no addr) LDA XSP, XSP - 010h
	; (no addr) LD XHL, XBC
	; (no addr) LD XIY, 00e0dbc6h
	; (no addr) LD XIX, XSP
	; (no addr) LD BC, 0008h
	LDIRW_95
	; (no addr) LDA XWA, XSP
	; (no addr) LD XBC, XHL
	; (no addr) CALL DirmdEmulator
	; (no addr) LDA XSP, XSP + 010h
	; (no addr) RET

LABEL_F03AB6:
	.byte 0x1B, 0x8B, 0xB1, 0xF0, 0x1B, 0xA7, 0xBC, 0xF0
	.byte 0x9F, 0x4, 0x20, 0x9F, 0x6, 0x21, 0x1B, 0x8C
	.byte 0x4E, 0xF0, 0x1B, 0xB1, 0xBC, 0xF0

SeFilL241TitleFunc:
	; (no addr) LDA XSP, XSP - 010h
	; (no addr) LD XHL, XBC
	; (no addr) LD XIY, 00e0dbd6h
	; (no addr) LD XIX, XSP
	; (no addr) LD BC, 0008h
	LDIRW_95
	; (no addr) LDA XWA, XSP
	; (no addr) LD XBC, XHL
	; (no addr) CALL DirmdEmulator
	; (no addr) LDA XSP, XSP + 010h
	; (no addr) RET

LABEL_F03AE9:
	.byte 0x1B, 0xA6, 0xB1, 0xF0, 0x1B, 0xB2, 0xBC, 0xF0
	.byte 0x9F, 0x4, 0x20, 0x9F, 0x6, 0x21, 0x1B, 0xBA
	.byte 0x4E, 0xF0, 0x1B, 0xBC, 0xBC, 0xF0

SeFilH241TitleFunc:
	; (no addr) LDA XSP, XSP - 010h
	; (no addr) LD XHL, XBC
	; (no addr) LD XIY, 00e0dbe6h
	; (no addr) LD XIX, XSP
	; (no addr) LD BC, 0008h
	LDIRW_95
	; (no addr) LDA XWA, XSP
	; (no addr) LD XBC, XHL
	; (no addr) CALL DirmdEmulator
	; (no addr) LDA XSP, XSP + 010h
	; (no addr) RET

LABEL_F03B1C:
	.byte 0x1B, 0xBD, 0xB1, 0xF0, 0x1B, 0xBD, 0xBC, 0xF0
	.byte 0x9F, 0x4, 0x20, 0x9F, 0x6, 0x21, 0x1B, 0xE8
	.byte 0x4E, 0xF0, 0x1B, 0xC7, 0xBC, 0xF0

SeFilBpf1TitleFunc:
	; (no addr) LDA XSP, XSP - 010h
	; (no addr) LD XHL, XBC
	; (no addr) LD XIY, 00e0dbf6h
	; (no addr) LD XIX, XSP
	; (no addr) LD BC, 0008h
	LDIRW_95
	; (no addr) LDA XWA, XSP
	; (no addr) LD XBC, XHL
	; (no addr) CALL DirmdEmulator
	; (no addr) LDA XSP, XSP + 010h
	; (no addr) RET

LABEL_F03B4F:
	.byte 0x1B, 0xD4, 0xB1, 0xF0, 0x1B, 0xC8, 0xBC, 0xF0
	.byte 0x9F, 0x4, 0x20, 0x9F, 0x6, 0x21, 0x1B, 0x16
	.byte 0x4F, 0xF0, 0x1B, 0xD2, 0xBC, 0xF0

SeFilBcf1TitleFunc:
	; (no addr) LDA XSP, XSP - 010h
	; (no addr) LD XHL, XBC
	; (no addr) LD XIY, 00e0dc06h
	; (no addr) LD XIX, XSP
	; (no addr) LD BC, 0008h
	LDIRW_95
	; (no addr) LDA XWA, XSP
	; (no addr) LD XBC, XHL
	; (no addr) CALL DirmdEmulator
	; (no addr) LDA XSP, XSP + 010h
	; (no addr) RET

LABEL_F03B82:
	.byte 0x1B, 0xE7, 0xB1, 0xF0, 0x1B, 0xD3, 0xBC, 0xF0
	.byte 0x9F, 0x4, 0x20, 0x9F, 0x6, 0x21, 0x1B, 0x44
	.byte 0x4F, 0xF0, 0x1B, 0xDD, 0xBC, 0xF0

SeFilFil2TitleFunc:
	; (no addr) LDA XSP, XSP - 010h
	; (no addr) LD XHL, XBC
	; (no addr) LD XIY, 00e0dc16h
	; (no addr) LD XIX, XSP
	; (no addr) LD BC, 0008h
	LDIRW_95
	; (no addr) LDA XWA, XSP
	; (no addr) LD XBC, XHL
	; (no addr) CALL DirmdEmulator
	; (no addr) LDA XSP, XSP + 010h
	; (no addr) RET

LABEL_F03BB5:
	.byte 0x1B, 0xF6, 0xB1, 0xF0, 0x1B, 0xDE, 0xBC, 0xF0
	.byte 0x9F, 0x4, 0x20, 0x9F, 0x6, 0x21, 0x1B, 0x72
	.byte 0x4F, 0xF0, 0x1B, 0xE8, 0xBC, 0xF0

SeFilEnv1TitleFunc:
	; (no addr) LDA XSP, XSP - 010h
	; (no addr) LD XHL, XBC
	; (no addr) LD XIY, 00e0dc26h
	; (no addr) LD XIX, XSP
	; (no addr) LD BC, 0008h
	LDIRW_95
	; (no addr) LDA XWA, XSP
	; (no addr) LD XBC, XHL
	; (no addr) CALL DirmdEmulator
	; (no addr) LDA XSP, XSP + 010h
	; (no addr) RET

LABEL_F03BE8:
	.byte 0x1B, 0x97, 0xB2, 0xF0, 0x1B, 0xE9, 0xBC, 0xF0
	.byte 0x9F, 0x4, 0x20, 0x9F, 0x6, 0x21, 0x1B, 0xA0
	.byte 0x4F, 0xF0, 0x1B, 0xF3, 0xBC, 0xF0

SeFilEnv2TitleFunc:
	; (no addr) LDA XSP, XSP - 010h
	; (no addr) LD XHL, XBC
	; (no addr) LD XIY, 00e0dc36h
	; (no addr) LD XIX, XSP
	; (no addr) LD BC, 0008h
	LDIRW_95
	; (no addr) LDA XWA, XSP
	; (no addr) LD XBC, XHL
	; (no addr) CALL DirmdEmulator
	; (no addr) LDA XSP, XSP + 010h
	; (no addr) RET

LABEL_F03C1B:
	.byte 0x1B, 0x2D, 0xB3, 0xF0, 0x1B, 0xF4, 0xBC, 0xF0
	.byte 0x9F, 0x4, 0x20, 0x9F, 0x6, 0x21, 0x1B, 0xCE
	.byte 0x4F, 0xF0, 0x1B, 0xFE, 0xBC, 0xF0

SeFilLfo1TitleFunc:
	; (no addr) LDA XSP, XSP - 010h
	; (no addr) LD XHL, XBC
	; (no addr) LD XIY, 00e0dc46h
	; (no addr) LD XIX, XSP
	; (no addr) LD BC, 0008h
	LDIRW_95
	; (no addr) LDA XWA, XSP
	; (no addr) LD XBC, XHL
	; (no addr) CALL DirmdEmulator
	; (no addr) LDA XSP, XSP + 010h
	; (no addr) RET

LABEL_F03C4E:
	.byte 0x1B, 0xD7, 0xB3, 0xF0, 0x1B, 0xFF, 0xBC, 0xF0
	.byte 0x9F, 0x4, 0x20, 0x9F, 0x6, 0x21, 0x1B, 0xFC
	.byte 0x4F, 0xF0, 0x1B, 0x9, 0xBD, 0xF0

SeDigEffTitleFunc:
	; (no addr) LDA XSP, XSP - 010h
	; (no addr) LD XHL, XBC
	; (no addr) LD XIY, 00e0dc56h
	; (no addr) LD XIX, XSP
	; (no addr) LD BC, 0008h
	LDIRW_95
	; (no addr) LDA XWA, XSP
	; (no addr) LD XBC, XHL
	; (no addr) CALL DirmdEmulator
	; (no addr) LDA XSP, XSP + 010h
	; (no addr) RET

LABEL_F03C81:
	.byte 0x1B, 0xD8, 0xBA, 0xF0, 0x1B, 0x19, 0xBD, 0xF0
	.byte 0x9F, 0x4, 0x20, 0x9F, 0x6, 0x21, 0x1B, 0xC8
	.byte 0xD7, 0xF0, 0x1B, 0x23, 0xBD, 0xF0

SeCtr2TitleFunc:
	; (no addr) LDA XSP, XSP - 010h
	; (no addr) LD XHL, XBC
	; (no addr) LD XIY, 00e0dc66h
	; (no addr) LD XIX, XSP
	; (no addr) LD BC, 0008h
	LDIRW_95
	; (no addr) LDA XWA, XSP
	; (no addr) LD XBC, XHL
	; (no addr) CALL DirmdEmulator
	; (no addr) LDA XSP, XSP + 010h
	; (no addr) RET

LABEL_F03CB4:
	.byte 0x1B, 0x81, 0xAE, 0xF0, 0x1B, 0x4F, 0xBC, 0xF0
	.byte 0x9F, 0x4, 0x20, 0x9F, 0x6, 0x21, 0x1B, 0x2F
	.byte 0xBD, 0xF0, 0x1B, 0x59, 0xBC, 0xF0

SeCtr3TitleFunc:
	; (no addr) LDA XSP, XSP - 010h
	; (no addr) LD XHL, XBC
	; (no addr) LD XIY, 00e0dc76h
	; (no addr) LD XIX, XSP
	; (no addr) LD BC, 0008h
	LDIRW_95
	; (no addr) LDA XWA, XSP
	; (no addr) LD XBC, XHL
	; (no addr) CALL DirmdEmulator
	; (no addr) LDA XSP, XSP + 010h
	; (no addr) RET

LABEL_F03CE7:
	.byte 0x1B, 0xB, 0xB0, 0xF0, 0x1B, 0x5A, 0xBC, 0xF0
	.byte 0x9F, 0x4, 0x20, 0x9F, 0x6, 0x21, 0x1B, 0x5D
	.byte 0xBD, 0xF0, 0x1B, 0x64, 0xBC, 0xF0

SeCopyTitleFunc:
	; (no addr) LDA XSP, XSP - 010h
	; (no addr) LD XHL, XBC
	; (no addr) LD XIY, 00e0dc86h
	; (no addr) LD XIX, XSP
	; (no addr) LD BC, 0008h
	LDIRW_95
	; (no addr) LDA XWA, XSP
	; (no addr) LD XBC, XHL
	; (no addr) CALL DirmdEmulator
	; (no addr) LDA XSP, XSP + 010h
	; (no addr) RET

LABEL_F03D1A:
	.byte 0x1B, 0x7D, 0xBB, 0xF0, 0x1B, 0x24, 0xBD, 0xF0
	.byte 0x9F, 0x4, 0x20, 0x9F, 0x6, 0x21, 0x1B, 0x3E
	.byte 0xD7, 0xF0, 0x1B, 0x2E, 0xBD, 0xF0

SeWrtMemTitleFunc:
	; (no addr) LDA XSP, XSP - 010h
	; (no addr) LD XHL, XBC
	; (no addr) LD XIY, 00e0dc96h
	; (no addr) LD XIX, XSP
	; (no addr) LD BC, 0008h
	LDIRW_95
	; (no addr) LDA XWA, XSP
	; (no addr) LD XBC, XHL
	; (no addr) CALL DirmdEmulator
	; (no addr) LDA XSP, XSP + 010h
	; (no addr) RET

LABEL_F03D4D:
	.byte 0x1B, 0xC4, 0xB9, 0xF0, 0x1B, 0xA, 0xBD, 0xF0
	.byte 0x9F, 0x4, 0x20, 0x9F, 0x6, 0x21, 0x1B, 0x6C
	.byte 0xD7, 0xF0, 0x1B, 0xB, 0xBD, 0xF0

SeWrtSndTitleFunc:
	; (no addr) LDA XSP, XSP - 010h
	; (no addr) LD XHL, XBC
	; (no addr) LD XIY, 00e0dca6h
	; (no addr) LD XIX, XSP
	; (no addr) LD BC, 0008h
	LDIRW_95
	; (no addr) LDA XWA, XSP
	; (no addr) LD XBC, XHL
	; (no addr) CALL DirmdEmulator
	; (no addr) LDA XSP, XSP + 010h
	; (no addr) RET

; End of Sound Editor routines

