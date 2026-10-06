; =============================================================================
; v7: audio-dispatch / UI-state event code (NOT the screen group dispatcher)
; =============================================================================
; Until 2026-09-25 this file said it held the boot screen group dispatcher,
; the error dialogs and the system reinitialisation routine, under the names
; ScreenGroup_ReInit ... ScreenGroup_InitFinalize.  In v7 that is false: its
; 703 bytes, 0xFDD777-0xFDDA35, are the bytes v10 carries at 0xFDDF48-0xFDE206
; in audio/dsp_config_sysex.s (v10 = v7 + 0x7D1): the end of
; AudioDispatch_CheckStereoMode, AudioVoice_Callback, AudioMode_* ,
; AudioVoiceReset_Handler, UIState_ProcessMidiEvent and UIStateEvt_*.  v7's
; screen group code (v10 0xFDDB2E-, boot/screen_group_dispatch.s) is at
; 0xFDD35D-, inside the bytes of audio/dsp_config_sysex.s: this file is
; included there, 0x41A below where its content belongs (the same drift as
; scripts/analysis/v7_label_drift.py reports for that whole zone).
; Ported from v10 by scripts/lanes/sys/port_islands.py --whole --delta 0x7d1:
; every instruction re-assembled to the v7 bytes; what v10 itself still spells
; as `.byte` stays `.byte`.  The v10 names above are not placed here because v7
; still defines them (drifted) in audio/dsp_config_sysex.s.  Kept, because
; other v7 code reaches them: AudioMode_ResetVoiceState (0xFDD7D6, 8 calls)
; and ScreenGroup_InitVoiceLoop (ui_widgets/widget_dispatch.s uses +79).  The
; other old labels had no reference in code or ROM and are dropped (notes).
; =============================================================================

; (v7 label ScreenGroup_ReInit stood here; dropped, see the file header)
	.byte	0x67, 0xfc, 0xc9
	jr	z, AudioVoice_Callback
	ld	wa, (0xc4f8:16)
	bit	4, wa
	jr	nz, AudioDispatch_ClearVoiceFlags
	set	2, (0xc162:16)
	jr	AudioDispatch_SetBusyFlag
; (v7 label ScreenGroup_Dispatch stood here; dropped, see the file header)
; (v7 label ScreenGroup_DispatchAlt stood here; dropped, see the file header)
AudioDispatch_ClearVoiceFlags:
	ld	(0xc162:16), 0
AudioDispatch_SetBusyFlag:
	.byte	0xd1, 0x00, 0xc5, 0x3e, 0x01, 0x00
AudioVoice_Callback:
	ld	a, (CURRENT_MODE:16)
	extz	wa
; (v7 label ScreenGroup_SetupWidgetPtr stood here; dropped, see the file header)
	sla	wa, 2
; (v7 label VoiceInit_Dispatch stood here; dropped, see the file header)
	lda	xbc, (AudioVoiceHandler_Table:24)
	ld	xhl, (xbc+wa)
	ld	xbc, xhl
	lda	xwa, (AudioInit_MixFallbackDefault_Code:24)
	cp	xwa, xbc
	jr	z, AudioVoice_SkipToDispatch
	ld	wa, 0:i3
	call	(xhl)
	call	AudioInit_ClearPartFlags_ByMode
AudioVoice_SkipToDispatch:
	jp	AudioInit_DispatchChanges
AudioMode_SetStereoFlags:
	bit	0, (0xfc69:16)
	ret	z
; (v7 label ScreenGroup_WidgetLoop stood here; dropped, see the file header)
	orw	(0xc4fa:16), 128
	orw	(0xc4f8:16), 4
	calr	AudioInit_ProcessModeChange
	ret
AudioMode_ResetVoiceState:
	bit	1, (0xfc67:16)
	jr	z, AudioVoiceReset_Handler
	ld	wa, (0xc4f8:16)
	bit	4, wa
; (v7 label ScreenGroup_InitState stood here; dropped, see the file header)
	jr	nz, AudioVoiceReset_ClearFlags
	set	2, (0xc162:16)
	jr	AudioVoiceReset_Handler
AudioVoiceReset_ClearFlags:
	ld	(0xc162:16), 0
; (v7 label .Lc_fdd7f0 stood here; dropped, see the file header)
; [v10] Audio subsystem callback
AudioVoiceReset_Handler:
	res	3, (0xc162:16)
	ld	(0xc218:16), 255
	ld	(0xc220:16), 255
	ld	(0xc164:16), 255
	ld	(0xc165:16), 255
	orw	(0xc500:16), 257
	.byte	0xd1, 0xf8, 0xc4, 0x3c, 0xfd, 0xff
	ld	a, (CURRENT_MODE:16)
	extz	wa
	sla	wa, 2
	lda	xbc, (AudioVoiceHandler_Table:24)
	ld	xhl, (xbc+wa)
	ld	xbc, xhl
	.byte	0xf2, 0x09, 0xe5, 0xfd, 0x30
	cp	xwa, xbc
	ret	z
	ld	wa, 1:i3
	call	(xhl)
	call	AudioInit_DrumRoutingCheck
	call	AudioInit_DrumSaveReturn
	call	AudioInit_VoiceParamCtrl
	call	AudioInit_ClearPartFlags_ByMode
	call	AudioInit_DispatchChanges
	ret
AudioMode_ConfigureExternal:
	ld	(0xc162:16), 0
	cp	a, 0:i3
	jr	z, AudioMode_ConfigExternal_Off
	orw	(0xc4f8:16), 16
	jr	AudioMode_ConfigExternal_Apply
AudioMode_ConfigExternal_Off:
	andw	(0xc4f8:16), 0xffef
	bit	0, (64614:16)
	jr	z, AudioMode_ConfigExternal_CheckBit1
	set	0, (0xc162:16)
AudioMode_ConfigExternal_CheckBit1:
	bit	1, (0xfc66:16)
	jr	z, AudioMode_ConfigExternal_CheckStereo
	set	1, (0xc162:16)
AudioMode_ConfigExternal_CheckStereo:
	bit	1, (0xfc67:16)
	jr	z, AudioMode_ConfigExternal_NoStereo
	orw	(0xc4fa:16), 32
	jr	AudioMode_ConfigExternal_MergeFlags
AudioMode_ConfigExternal_NoStereo:
	andw	(0xc4fa:16), 0xffdf
	ld	wa, (0xc4fa:16)
	and	wa, 0x7
	call	z, (AudioInit_RefreshToneBank:24)
AudioMode_ConfigExternal_MergeFlags:
	res	2, (0xc162:16)
	ld	a, (0xfc67:16)
	and	a, 0x2
	ld	c, a
	add	a, c
	or	(0xc162:16), a
AudioMode_ConfigExternal_Apply:
	orw	(0xc4f8:16), 4
	jrl	AudioInit_ProcessModeChange
; [v10] ============================================================================
; [v10] UIState_ProcessMidiEvent - Process an incoming MIDI event in UI state
; [v10] ============================================================================
; [v10] Input:  MIDI event data
; [v10] Output: None
; [v10] Handles MIDI events (note on/off, control change, etc.) within the UI
; [v10] state machine, updating relevant display elements.
; [v10] ============================================================================
UIState_ProcessMidiEvent:
	cp	(SWBTWR_EVENT_TYPE:16), 24
	ret	ugt
	ld	l, (SWBTWR_EVENT_TYPE:16)
	ld	h, (SWBTWR_PAYLOAD_1:16)
	ld	e, (SWBTWR_PAYLOAD_3:16)
	ld	d, (SWBTWR_PAYLOAD_2:16)
	ld	a, l
	extz	wa
	sla	wa, 2
	lda	xbc, (PartRecord_RamPtrTable:24)
	ld	xwa, (xbc+wa)
	ld	a, h
	cp	a, 0x16
	jrl	z, UIStateEvt_TransposeUpdate
	cp	a, 0xd
	jr	z, UIStateEvt_VoiceAssign
	cp	a, 0xc
	jr	z, UIStateEvt_PartRouting
	cp	a, 0:i3
	ret	nz
	ld	a, e
	and	a, 0xff
	ret	z
	orw	(0xc4f8:16), 4
	ret
UIStateEvt_PartRouting:
	ld	a, e
	and	a, 0x7
	ret	z
	ld	a, l
	extz	wa
	lda	xbc, (PartIndex_ByteMap:24)
	ld	a, (xbc+wa)
; (v7 label ScreenGroup_InitParams16 stood here; dropped, see the file header)
	extz	wa
	add	wa, wa
	ld	hl, wa
; (v7 label ScreenGroup_InitParam16Loop stood here; dropped, see the file header)
	add	hl, 0x124
	lda	xix, (0xc162:16)
	ld	a, d
	and	a, 0x7
	extz	wa
	lda	xbc, (PartRouting_ByteTable:24)
	ld	a, (xbc+wa)
	and	a, 0x7
	sla	a, 1
	and	(xix+hl), 0xf1
	or	(xix+hl), a
; (v7 label ScreenGroup_InitParams8 stood here; dropped, see the file header)
	orw	(0xc4f8:16), 4
	ret
UIStateEvt_VoiceAssign:
	ld	a, e
	and	a, 0xf
; (v7 label ScreenGroup_InitParam8Loop stood here; dropped, see the file header)
	jr	z, UIStateEvt_ToneChange
	bit	6, d
	jr	nz, UIStateEvt_VoiceAssign_Reset
	ld	a, l
	extz	wa
	lda	xbc, (PartIndex_ByteMap:24)
	ld	a, (xbc+wa)
	extz	wa
	lda	xbc, (0xc186:16)
	ld	ix, wa
	extz	xix
; (v7 label ScreenGroup_InitParams8Complex stood here; dropped, see the file header)
	add	xix, xbc
	ld	a, d
	and	a, 0xf
	ld	(xix), a
; (v7 label ScreenGroup_InitParam8ComplexLoop stood here; dropped, see the file header)
	jr	UIStateEvt_VoiceAssign_Notify
UIStateEvt_VoiceAssign_Reset:
	ld	a, l
	extz	wa
	lda	xbc, (PartIndex_ByteMap:24)
	ld	a, (xbc+wa)
	extz	wa
	lda	xbc, (0xc186:16)
	extz	xwa
	add	xwa, xbc
	ld	(xwa), 0xff
UIStateEvt_VoiceAssign_Notify:
	orw	(0xc500:16), 2048
	orw	(0xc4f8:16), 4
UIStateEvt_ToneChange:
	bit	5, e
	jr	z, UIStateEvt_DrumAssign
	bit	5, d
	jr	z, UIStateEvt_ToneChange_Set
	ld	a, l
	extz	wa
	lda	xbc, (PartIndex_ByteMap:24)
	ld	a, (xbc+wa)
	extz	wa
	lda	xbc, (0xc166:16)
	extz	xwa
	add	xwa, xbc
	ld	(xwa), 0xff
	cp	l, 0x13
	jr	nz, Tone_WriteEndMarker
	ld	(0xc17c:16), 255
; (v7 label ScreenGroup_FinalInit stood here; dropped, see the file header)
	jr	Tone_WriteEndMarker
UIStateEvt_ToneChange_Set:
	ld	a, l
	extz	wa
	lda	xbc, (PartIndex_ByteMap:24)
	ld	a, (xbc+wa)
	extz	wa
	lda	xbc, (0xc166:16)
	ld	ix, wa
	extz	xix
	add	xix, xbc
	ld	a, l
; (v7 label ScreenGroup_InitWordPairsLoop stood here; dropped, see the file header)
	extz	wa
	lda	xbc, (PartIndex_ByteMap:24)
	ld	a, (xbc+wa)
	ld	(xix), a
	cp	l, 0x13
	jr	nz, Tone_WriteEndMarker
	ld	(0xc17c:16), 22
Tone_WriteEndMarker:
	orw	(0xc500:16), 4
	orw	(0xc4f8:16), 4
; (v7 label ScreenGroup_InitFinalize stood here; dropped, see the file header)
; (was .incbin "includes/romslices/v7_block_screengroup_initfinalize.bin")
UIStateEvt_DrumAssign:
	bit	6, e
	ret	z
	bit	6, d
	jr	z, UIStateEvt_DrumAssign_Set
	ld	a, l
	extz	wa
	lda	xbc, (PartIndex_ByteMap:24)
	ld	a, (xbc+wa)
	extz	wa
	lda	xbc, (0xc186:16)
	extz	xwa
	add	xwa, xbc
	.byte	0xb0, 0x00
