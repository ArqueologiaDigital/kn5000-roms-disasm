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
	CP XBC, 01c00013h
	RET NZ
	CP XDE, 00000001h
	JR Z, SeMenuModeFunc_Handler
	OR XDE, XDE
	RET NZ
	JP InitializeSeMenuDefaults

SeMenuModeFunc_Handler:
	CALL UpdateSeMenuSelection
	RET

SeMenuTitleFunc:
	LDA XSP, XSP - 010h
	LD XHL, XBC
	LD XIY, 00e0dab6h
	LD XIX, XSP
	LD BC, 0008h
	LDIRW_95
	LDA XWA, XSP
	LD XBC, XHL
	CALL DirmdEmulator
	LDA XSP, XSP + 010h
	RET

SeMenuTitleFunc_DisplayData:
	db 01Bh, 062h, 0A1h, 0F0h, 01Bh, 0D6h, 0BBh, 0F0h
	db 09Fh, 004h, 020h, 09Fh, 006h, 021h, 01Bh, 046h
	db 0BFh, 0F0h, 01Bh, 0E0h, 0BBh, 0F0h

SeEasyTitleFunc:
	LDA XSP, XSP - 010h
	LD XHL, XBC
	LD XIY, 00e0dac6h
	LD XIX, XSP
	LD BC, 0008h
	LDIRW_95
	LDA XWA, XSP
	LD XBC, XHL
	CALL DirmdEmulator
	LDA XSP, XSP + 010h
	RET

SeEasyTitleFunc_DisplayData:
	db 01Bh, 0A5h, 0A6h, 0F0h, 01Bh, 00Eh, 0BDh, 0F0h
	db 09Fh, 004h, 020h, 09Fh, 006h, 021h, 01Bh, 010h
	db 0D7h, 0F0h, 01Bh, 018h, 0BDh, 0F0h

SeTonTon1TitleFunc:
	LDA XSP, XSP - 010h
	LD XHL, XBC
	LD XIY, 00e0dad6h
	LD XIX, XSP
	LD BC, 0008h
	LDIRW_95
	LDA XWA, XSP
	LD XBC, XHL
	CALL DirmdEmulator
	LDA XSP, XSP + 010h
	RET

SeTonTon1TitleFunc_DisplayData:
	db 01Bh, 0DDh, 0B3h, 0F0h, 01Bh, 065h, 0BCh, 0F0h
	db 09Fh, 004h, 020h, 09Fh, 006h, 021h, 01Bh, 0D9h
	db 0C6h, 0F0h, 01Bh, 06Fh, 0BCh, 0F0h

SeTonTon2TitleFunc:
	LDA XSP, XSP - 010h
	LD XHL, XBC
	LD XIY, 00e0dae6h
	LD XIX, XSP
	LD BC, 0008h
	LDIRW_95
	LDA XWA, XSP
	LD XBC, XHL
	CALL DirmdEmulator
	LDA XSP, XSP + 010h
	RET

SeTonTon2TitleFunc_DisplayData:
	db 01Bh, 054h, 0B5h, 0F0h, 01Bh, 070h, 0BCh, 0F0h
	db 09Fh, 004h, 020h, 09Fh, 006h, 021h, 01Bh, 007h
	db 0C7h, 0F0h, 01Bh, 07Ah, 0BCh, 0F0h

SeTonRan1TitleFunc:
	LDA XSP, XSP - 010h
	LD XHL, XBC
	LD XIY, 00e0daf6h
	LD XIX, XSP
	LD BC, 0008h
	LDIRW_95
	LDA XWA, XSP
	LD XBC, XHL
	CALL DirmdEmulator
	LDA XSP, XSP + 010h
	RET

SeTonRan1TitleFunc_DisplayData:
	db 01Bh, 030h, 0B6h, 0F0h, 01Bh, 07Bh, 0BCh, 0F0h
	db 09Fh, 004h, 020h, 09Fh, 006h, 021h, 01Bh, 035h
	db 0C7h, 0F0h, 01Bh, 085h, 0BCh, 0F0h

SeTonRan2TitleFunc:
	LDA XSP, XSP - 010h
	LD XHL, XBC
	LD XIY, 00e0db06h
	LD XIX, XSP
	LD BC, 0008h
	LDIRW_95
	LDA XWA, XSP
	LD XBC, XHL
	CALL DirmdEmulator
	LDA XSP, XSP + 010h
	RET

SeTonRan2TitleFunc_DisplayData:
	db 01Bh, 00Fh, 0B7h, 0F0h, 01Bh, 086h, 0BCh, 0F0h
	db 09Fh, 004h, 020h, 09Fh, 006h, 021h, 01Bh, 063h
	db 0C7h, 0F0h, 01Bh, 090h, 0BCh, 0F0h

SeTonHyb1TitleFunc:
	LDA XSP, XSP - 010h
	LD XHL, XBC
	LD XIY, 00e0db16h
	LD XIX, XSP
	LD BC, 0008h
	LDIRW_95
	LDA XWA, XSP
	LD XBC, XHL
	CALL DirmdEmulator
	LDA XSP, XSP + 010h
	RET

SeTonHyb1TitleFunc_DisplayData:
	db 01Bh, 0EEh, 0B7h, 0F0h, 01Bh, 091h, 0BCh, 0F0h
	db 09Fh, 004h, 020h, 09Fh, 006h, 021h, 01Bh, 091h
	db 0C7h, 0F0h, 01Bh, 09Bh, 0BCh, 0F0h

SePitPit1TitleFunc:
	LDA XSP, XSP - 010h
	LD XHL, XBC
	LD XIY, 00e0db26h
	LD XIX, XSP
	LD BC, 0008h
	LDIRW_95
	LDA XWA, XSP
	LD XBC, XHL
	CALL DirmdEmulator
	LDA XSP, XSP + 010h
	RET

SePitPit1TitleFunc_DisplayData:
	db 01Bh, 086h, 0A7h, 0F0h, 01Bh, 0E1h, 0BBh, 0F0h
	db 09Fh, 004h, 020h, 09Fh, 006h, 021h, 01Bh, 0D0h
	db 09Ah, 0F0h, 01Bh, 0EBh, 0BBh, 0F0h

SePitEnv1TitleFunc:
	LDA XSP, XSP - 010h
	LD XHL, XBC
	LD XIY, 00e0db36h
	LD XIX, XSP
	LD BC, 0008h
	LDIRW_95
	LDA XWA, XSP
	LD XBC, XHL
	CALL DirmdEmulator
	LDA XSP, XSP + 010h
	RET

SePitEnv1TitleFunc_DisplayData:
	db 01Bh, 09Bh, 0A8h, 0F0h, 01Bh, 0ECh, 0BBh, 0F0h
	db 09Fh, 004h, 020h, 09Fh, 006h, 021h, 01Bh, 0FEh
	db 09Ah, 0F0h, 01Bh, 0F6h, 0BBh, 0F0h

SePitEnv2TitleFunc:
	LDA XSP, XSP - 010h
	LD XHL, XBC
	LD XIY, 00e0db46h
	LD XIX, XSP
	LD BC, 0008h
	LDIRW_95
	LDA XWA, XSP
	LD XBC, XHL
	CALL DirmdEmulator
	LDA XSP, XSP + 010h
	RET

SePitEnv2TitleFunc_DisplayData:
	db 01Bh, 031h, 0A9h, 0F0h, 01Bh, 0F7h, 0BBh, 0F0h
	db 09Fh, 004h, 020h, 09Fh, 006h, 021h, 01Bh, 02Ch
	db 09Bh, 0F0h, 01Bh, 001h, 0BCh, 0F0h

SePitLfo1TitleFunc:
	LDA XSP, XSP - 010h
	LD XHL, XBC
	LD XIY, 00e0db56h
	LD XIX, XSP
	LD BC, 0008h
	LDIRW_95
	LDA XWA, XSP
	LD XBC, XHL
	CALL DirmdEmulator
	LDA XSP, XSP + 010h
	RET

SePitLfo1TitleFunc_DisplayData:
	db 01Bh, 0DBh, 0A9h, 0F0h, 01Bh, 002h, 0BCh, 0F0h
	db 09Fh, 004h, 020h, 09Fh, 006h, 021h, 01Bh, 05Ah
	db 09Bh, 0F0h, 01Bh, 00Ch, 0BCh, 0F0h

SeAmpAmp1TitleFunc:
	LDA XSP, XSP - 010h
	LD XHL, XBC
	LD XIY, 00e0db66h
	LD XIX, XSP
	LD BC, 0008h
	LDIRW_95
	LDA XWA, XSP
	LD XBC, XHL
	CALL DirmdEmulator
	LDA XSP, XSP + 010h
	RET

SeAmpAmp1TitleFunc_DisplayData:
	db 01Bh, 0E3h, 0AAh, 0F0h, 01Bh, 00Dh, 0BCh, 0F0h
	db 09Fh, 004h, 020h, 09Fh, 006h, 021h, 01Bh, 0B3h
	db 03Dh, 0F0h, 01Bh, 017h, 0BCh, 0F0h

SeAmpAmp2TitleFunc:
	LDA XSP, XSP - 010h
	LD XHL, XBC
	LD XIY, 00e0db76h
	LD XIX, XSP
	LD BC, 0008h
	LDIRW_95
	LDA XWA, XSP
	LD XBC, XHL
	CALL DirmdEmulator
	LDA XSP, XSP + 010h
	RET

LABEL_F039B7:
	db 01Bh, 033h, 0ACh, 0F0h, 01Bh, 018h, 0BCh, 0F0h
	db 09Fh, 004h, 020h, 09Fh, 006h, 021h, 01Bh, 0E1h
	db 03Dh, 0F0h, 01Bh, 022h, 0BCh, 0F0h

SeAmpEnv1TitleFunc:
	LDA XSP, XSP - 010h
	LD XHL, XBC
	LD XIY, 00e0db86h
	LD XIX, XSP
	LD BC, 0008h
	LDIRW_95
	LDA XWA, XSP
	LD XBC, XHL
	CALL DirmdEmulator
	LDA XSP, XSP + 010h
	RET

LABEL_F039EA:
	db 01Bh, 0D4h, 0ACh, 0F0h, 01Bh, 023h, 0BCh, 0F0h
	db 09Fh, 004h, 020h, 09Fh, 006h, 021h, 01Bh, 00Fh
	db 03Eh, 0F0h, 01Bh, 02Dh, 0BCh, 0F0h

SeAmpEnv2TitleFunc:
	LDA XSP, XSP - 010h
	LD XHL, XBC
	LD XIY, 00e0db96h
	LD XIX, XSP
	LD BC, 0008h
	LDIRW_95
	LDA XWA, XSP
	LD XBC, XHL
	CALL DirmdEmulator
	LDA XSP, XSP + 010h
	RET

LABEL_F03A1D:
	db 01Bh, 0D0h, 0ADh, 0F0h, 01Bh, 02Eh, 0BCh, 0F0h
	db 09Fh, 004h, 020h, 09Fh, 006h, 021h, 01Bh, 03Dh
	db 03Eh, 0F0h, 01Bh, 038h, 0BCh, 0F0h

SeAmpLfo1TitleFunc:
	LDA XSP, XSP - 010h
	LD XHL, XBC
	LD XIY, 00e0dba6h
	LD XIX, XSP
	LD BC, 0008h
	LDIRW_95
	LDA XWA, XSP
	LD XBC, XHL
	CALL DirmdEmulator
	LDA XSP, XSP + 010h
	RET

LABEL_F03A50:
	db 01Bh, 07Bh, 0AEh, 0F0h, 01Bh, 039h, 0BCh, 0F0h
	db 09Fh, 004h, 020h, 09Fh, 006h, 021h, 01Bh, 06Bh
	db 03Eh, 0F0h, 01Bh, 043h, 0BCh, 0F0h

SeFilLpq1TitleFunc:
	LDA XSP, XSP - 010h
	LD XHL, XBC
	LD XIY, 00e0dbb6h
	LD XIX, XSP
	LD BC, 0008h
	LDIRW_95
	LDA XWA, XSP
	LD XBC, XHL
	CALL DirmdEmulator
	LDA XSP, XSP + 010h
	RET

LABEL_F03A83:
	db 01Bh, 04Fh, 0B0h, 0F0h, 01Bh, 09Ch, 0BCh, 0F0h
	db 09Fh, 004h, 020h, 09Fh, 006h, 021h, 01Bh, 05Eh
	db 04Eh, 0F0h, 01Bh, 0A6h, 0BCh, 0F0h

SeFilHpq1TitleFunc:
	LDA XSP, XSP - 010h
	LD XHL, XBC
	LD XIY, 00e0dbc6h
	LD XIX, XSP
	LD BC, 0008h
	LDIRW_95
	LDA XWA, XSP
	LD XBC, XHL
	CALL DirmdEmulator
	LDA XSP, XSP + 010h
	RET

LABEL_F03AB6:
	db 01Bh, 08Bh, 0B1h, 0F0h, 01Bh, 0A7h, 0BCh, 0F0h
	db 09Fh, 004h, 020h, 09Fh, 006h, 021h, 01Bh, 08Ch
	db 04Eh, 0F0h, 01Bh, 0B1h, 0BCh, 0F0h

SeFilL241TitleFunc:
	LDA XSP, XSP - 010h
	LD XHL, XBC
	LD XIY, 00e0dbd6h
	LD XIX, XSP
	LD BC, 0008h
	LDIRW_95
	LDA XWA, XSP
	LD XBC, XHL
	CALL DirmdEmulator
	LDA XSP, XSP + 010h
	RET

LABEL_F03AE9:
	db 01Bh, 0A6h, 0B1h, 0F0h, 01Bh, 0B2h, 0BCh, 0F0h
	db 09Fh, 004h, 020h, 09Fh, 006h, 021h, 01Bh, 0BAh
	db 04Eh, 0F0h, 01Bh, 0BCh, 0BCh, 0F0h

SeFilH241TitleFunc:
	LDA XSP, XSP - 010h
	LD XHL, XBC
	LD XIY, 00e0dbe6h
	LD XIX, XSP
	LD BC, 0008h
	LDIRW_95
	LDA XWA, XSP
	LD XBC, XHL
	CALL DirmdEmulator
	LDA XSP, XSP + 010h
	RET

LABEL_F03B1C:
	db 01Bh, 0BDh, 0B1h, 0F0h, 01Bh, 0BDh, 0BCh, 0F0h
	db 09Fh, 004h, 020h, 09Fh, 006h, 021h, 01Bh, 0E8h
	db 04Eh, 0F0h, 01Bh, 0C7h, 0BCh, 0F0h

SeFilBpf1TitleFunc:
	LDA XSP, XSP - 010h
	LD XHL, XBC
	LD XIY, 00e0dbf6h
	LD XIX, XSP
	LD BC, 0008h
	LDIRW_95
	LDA XWA, XSP
	LD XBC, XHL
	CALL DirmdEmulator
	LDA XSP, XSP + 010h
	RET

LABEL_F03B4F:
	db 01Bh, 0D4h, 0B1h, 0F0h, 01Bh, 0C8h, 0BCh, 0F0h
	db 09Fh, 004h, 020h, 09Fh, 006h, 021h, 01Bh, 016h
	db 04Fh, 0F0h, 01Bh, 0D2h, 0BCh, 0F0h

SeFilBcf1TitleFunc:
	LDA XSP, XSP - 010h
	LD XHL, XBC
	LD XIY, 00e0dc06h
	LD XIX, XSP
	LD BC, 0008h
	LDIRW_95
	LDA XWA, XSP
	LD XBC, XHL
	CALL DirmdEmulator
	LDA XSP, XSP + 010h
	RET

LABEL_F03B82:
	db 01Bh, 0E7h, 0B1h, 0F0h, 01Bh, 0D3h, 0BCh, 0F0h
	db 09Fh, 004h, 020h, 09Fh, 006h, 021h, 01Bh, 044h
	db 04Fh, 0F0h, 01Bh, 0DDh, 0BCh, 0F0h

SeFilFil2TitleFunc:
	LDA XSP, XSP - 010h
	LD XHL, XBC
	LD XIY, 00e0dc16h
	LD XIX, XSP
	LD BC, 0008h
	LDIRW_95
	LDA XWA, XSP
	LD XBC, XHL
	CALL DirmdEmulator
	LDA XSP, XSP + 010h
	RET

LABEL_F03BB5:
	db 01Bh, 0F6h, 0B1h, 0F0h, 01Bh, 0DEh, 0BCh, 0F0h
	db 09Fh, 004h, 020h, 09Fh, 006h, 021h, 01Bh, 072h
	db 04Fh, 0F0h, 01Bh, 0E8h, 0BCh, 0F0h

SeFilEnv1TitleFunc:
	LDA XSP, XSP - 010h
	LD XHL, XBC
	LD XIY, 00e0dc26h
	LD XIX, XSP
	LD BC, 0008h
	LDIRW_95
	LDA XWA, XSP
	LD XBC, XHL
	CALL DirmdEmulator
	LDA XSP, XSP + 010h
	RET

LABEL_F03BE8:
	db 01Bh, 097h, 0B2h, 0F0h, 01Bh, 0E9h, 0BCh, 0F0h
	db 09Fh, 004h, 020h, 09Fh, 006h, 021h, 01Bh, 0A0h
	db 04Fh, 0F0h, 01Bh, 0F3h, 0BCh, 0F0h

SeFilEnv2TitleFunc:
	LDA XSP, XSP - 010h
	LD XHL, XBC
	LD XIY, 00e0dc36h
	LD XIX, XSP
	LD BC, 0008h
	LDIRW_95
	LDA XWA, XSP
	LD XBC, XHL
	CALL DirmdEmulator
	LDA XSP, XSP + 010h
	RET

LABEL_F03C1B:
	db 01Bh, 02Dh, 0B3h, 0F0h, 01Bh, 0F4h, 0BCh, 0F0h
	db 09Fh, 004h, 020h, 09Fh, 006h, 021h, 01Bh, 0CEh
	db 04Fh, 0F0h, 01Bh, 0FEh, 0BCh, 0F0h

SeFilLfo1TitleFunc:
	LDA XSP, XSP - 010h
	LD XHL, XBC
	LD XIY, 00e0dc46h
	LD XIX, XSP
	LD BC, 0008h
	LDIRW_95
	LDA XWA, XSP
	LD XBC, XHL
	CALL DirmdEmulator
	LDA XSP, XSP + 010h
	RET

LABEL_F03C4E:
	db 01Bh, 0D7h, 0B3h, 0F0h, 01Bh, 0FFh, 0BCh, 0F0h
	db 09Fh, 004h, 020h, 09Fh, 006h, 021h, 01Bh, 0FCh
	db 04Fh, 0F0h, 01Bh, 009h, 0BDh, 0F0h

SeDigEffTitleFunc:
	LDA XSP, XSP - 010h
	LD XHL, XBC
	LD XIY, 00e0dc56h
	LD XIX, XSP
	LD BC, 0008h
	LDIRW_95
	LDA XWA, XSP
	LD XBC, XHL
	CALL DirmdEmulator
	LDA XSP, XSP + 010h
	RET

LABEL_F03C81:
	db 01Bh, 0D8h, 0BAh, 0F0h, 01Bh, 019h, 0BDh, 0F0h
	db 09Fh, 004h, 020h, 09Fh, 006h, 021h, 01Bh, 0C8h
	db 0D7h, 0F0h, 01Bh, 023h, 0BDh, 0F0h

SeCtr2TitleFunc:
	LDA XSP, XSP - 010h
	LD XHL, XBC
	LD XIY, 00e0dc66h
	LD XIX, XSP
	LD BC, 0008h
	LDIRW_95
	LDA XWA, XSP
	LD XBC, XHL
	CALL DirmdEmulator
	LDA XSP, XSP + 010h
	RET

LABEL_F03CB4:
	db 01Bh, 081h, 0AEh, 0F0h, 01Bh, 04Fh, 0BCh, 0F0h
	db 09Fh, 004h, 020h, 09Fh, 006h, 021h, 01Bh, 02Fh
	db 0BDh, 0F0h, 01Bh, 059h, 0BCh, 0F0h

SeCtr3TitleFunc:
	LDA XSP, XSP - 010h
	LD XHL, XBC
	LD XIY, 00e0dc76h
	LD XIX, XSP
	LD BC, 0008h
	LDIRW_95
	LDA XWA, XSP
	LD XBC, XHL
	CALL DirmdEmulator
	LDA XSP, XSP + 010h
	RET

LABEL_F03CE7:
	db 01Bh, 00Bh, 0B0h, 0F0h, 01Bh, 05Ah, 0BCh, 0F0h
	db 09Fh, 004h, 020h, 09Fh, 006h, 021h, 01Bh, 05Dh
	db 0BDh, 0F0h, 01Bh, 064h, 0BCh, 0F0h

SeCopyTitleFunc:
	LDA XSP, XSP - 010h
	LD XHL, XBC
	LD XIY, 00e0dc86h
	LD XIX, XSP
	LD BC, 0008h
	LDIRW_95
	LDA XWA, XSP
	LD XBC, XHL
	CALL DirmdEmulator
	LDA XSP, XSP + 010h
	RET

LABEL_F03D1A:
	db 01Bh, 07Dh, 0BBh, 0F0h, 01Bh, 024h, 0BDh, 0F0h
	db 09Fh, 004h, 020h, 09Fh, 006h, 021h, 01Bh, 03Eh
	db 0D7h, 0F0h, 01Bh, 02Eh, 0BDh, 0F0h

SeWrtMemTitleFunc:
	LDA XSP, XSP - 010h
	LD XHL, XBC
	LD XIY, 00e0dc96h
	LD XIX, XSP
	LD BC, 0008h
	LDIRW_95
	LDA XWA, XSP
	LD XBC, XHL
	CALL DirmdEmulator
	LDA XSP, XSP + 010h
	RET

LABEL_F03D4D:
	db 01Bh, 0C4h, 0B9h, 0F0h, 01Bh, 00Ah, 0BDh, 0F0h
	db 09Fh, 004h, 020h, 09Fh, 006h, 021h, 01Bh, 06Ch
	db 0D7h, 0F0h, 01Bh, 00Bh, 0BDh, 0F0h

SeWrtSndTitleFunc:
	LDA XSP, XSP - 010h
	LD XHL, XBC
	LD XIY, 00e0dca6h
	LD XIX, XSP
	LD BC, 0008h
	LDIRW_95
	LDA XWA, XSP
	LD XBC, XHL
	CALL DirmdEmulator
	LDA XSP, XSP + 010h
	RET

; End of Sound Editor routines

