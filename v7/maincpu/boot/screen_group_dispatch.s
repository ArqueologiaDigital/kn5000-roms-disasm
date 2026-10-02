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
; other v7 code reaches them: DkMdlyPly_CheckState_Helper2 (0xFDD7D6, 8 calls)
; and ScreenGroup_InitVoiceLoop (ui_widgets/widget_dispatch.s uses +79).  The
; other old labels had no reference in code or ROM and are dropped (notes).
; =============================================================================

; (v7 label ScreenGroup_ReInit stood here; dropped, see the file header)
	.byte	0x67, 0xfc, 0xc9
	jr	z, screen_group_dispatch_Skip2
	ld	wa, (0xc4f8:16)
	bit	4, wa
	jr	nz, screen_group_dispatch_Skip
	set	2, (0xc162:16)
	jr	screen_group_dispatch_Entry
; (v7 label ScreenGroup_Dispatch stood here; dropped, see the file header)
; (v7 label ScreenGroup_DispatchAlt stood here; dropped, see the file header)
screen_group_dispatch_Skip:
	ld	(0xc162:16), 0
screen_group_dispatch_Entry:
	.byte	0xd1, 0x00, 0xc5, 0x3e, 0x01, 0x00
screen_group_dispatch_Skip2:
	ld	a, (0x8c98:16)
	extz	wa
; (v7 label ScreenGroup_SetupWidgetPtr stood here; dropped, see the file header)
	sla	wa, 2
; (v7 label VoiceInit_Dispatch stood here; dropped, see the file header)
	lda	xbc, (SystemConfig_PointerTable_0x76:24)
	ld	xhl, (xbc+wa)
	ld	xbc, xhl
	lda	xwa, (0xfde509:24)
	cp	xwa, xbc
	jr	z, screen_group_dispatch_Skip3
	ld	wa, 0:i3
	call	(xhl)
	call	DSPCfg_EventType50_Code_Helper4
screen_group_dispatch_Skip3:
	jp	AudioInit_DispatchChanges
AudioMode_CheckAndUpdateStereo_Helper:
	bit	0, (0xfc69:16)
	ret	z
; (v7 label ScreenGroup_WidgetLoop stood here; dropped, see the file header)
	orw	(0xc4fa:16), 128
	orw	(0xc4f8:16), 4
	calr	AudioInit_ProcessModeChange
	ret
DkMdlyPly_CheckState_Helper2:
	bit	1, (0xfc67:16)
	jr	z, DkMdlyPly_CheckState_Helper2_Join
	ld	wa, (0xc4f8:16)
	bit	4, wa
; (v7 label ScreenGroup_InitState stood here; dropped, see the file header)
	jr	nz, DkMdlyPly_CheckState_Helper2_Skip
	set	2, (0xc162:16)
	jr	DkMdlyPly_CheckState_Helper2_Join
DkMdlyPly_CheckState_Helper2_Skip:
	ld	(0xc162:16), 0
; (v7 label .Lc_fdd7f0 stood here; dropped, see the file header)
; [v10] Audio subsystem callback
DkMdlyPly_CheckState_Helper2_Join:
	res	3, (0xc162:16)
	ld	(0xc218:16), 255
	ld	(0xc220:16), 255
	ld	(0xc164:16), 255
	ld	(0xc165:16), 255
	orw	(0xc500:16), 257
	.byte	0xd1, 0xf8, 0xc4, 0x3c, 0xfd, 0xff
	ld	a, (0x8c98:16)
	extz	wa
	sla	wa, 2
	lda	xbc, (SystemConfig_PointerTable_0x76:24)
	ld	xhl, (xbc+wa)
	ld	xbc, xhl
	.byte	0xf2, 0x09, 0xe5, 0xfd, 0x30
	cp	xwa, xbc
	ret	z
	ld	wa, 1:i3
	call	(xhl)
	call	DSPCfg_EventType50_Code_Helper3
	call	DSPCfg_EventType50_Code_Helper
	call	DSPCfg_EventType50_Code_Helper2
	call	DSPCfg_EventType50_Code_Helper4
	call	AudioInit_DispatchChanges
	ret
MimeSyori_Helper:
	ld	(0xc162:16), 0
	cp	a, 0:i3
	jr	z, DkMdlyPly_CheckState_Helper2_Skip2
	orw	(0xc4f8:16), 16
	jr	ScreenGroup_InitVoiceLoop_Code_Join2
DkMdlyPly_CheckState_Helper2_Skip2:
	andw	(0xc4f8:16), 0xffef
	.byte	0xf1, 0x66
ScreenGroup_InitVoiceLoop:
	.byte	0xfc, 0xc8
	jr	z, ScreenGroup_InitVoiceLoop_Code_Skip
	set	0, (0xc162:16)
ScreenGroup_InitVoiceLoop_Code_Skip:
	bit	1, (0xfc66:16)
	jr	z, ScreenGroup_InitVoiceLoop_Code_Skip2
	set	1, (0xc162:16)
ScreenGroup_InitVoiceLoop_Code_Skip2:
	bit	1, (0xfc67:16)
	jr	z, ScreenGroup_InitVoiceLoop_Code_Skip3
	orw	(0xc4fa:16), 32
	jr	ScreenGroup_InitVoiceLoop_Code_Join
ScreenGroup_InitVoiceLoop_Code_Skip3:
	andw	(0xc4fa:16), 0xffdf
	ld	wa, (0xc4fa:16)
	and	wa, 0x7
	call	z, (Interrupt_FlagSetBytecode_Helper:24)
ScreenGroup_InitVoiceLoop_Code_Join:
	res	2, (0xc162:16)
	ld	a, (0xfc67:16)
	and	a, 0x2
	ld	c, a
	add	a, c
	or	(0xc162:16), a
ScreenGroup_InitVoiceLoop_Code_Join2:
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
	cp	(0xbfe4:16), 24
	ret	ugt
	ld	l, (0xbfe4:16)
	ld	h, (0xbfe1:16)
	ld	e, (0xbfe3:16)
	ld	d, (0xbfe2:16)
	ld	a, l
	extz	wa
	sla	wa, 2
	lda	xbc, (AudioInit_VoiceDispatch_Table_0x7C:24)
	ld	xwa, (xbc+wa)
	ld	a, h
	cp	a, 0x16
	jrl	z, AudioDispatch_CheckStereoMode_Code_Skip26
	cp	a, 0xd
	jr	z, ScreenGroup_InitVoiceLoop_Code_Skip5
	cp	a, 0xc
	jr	z, ScreenGroup_InitVoiceLoop_Code_Skip4
	cp	a, 0:i3
	ret	nz
	ld	a, e
	and	a, 0xff
	ret	z
	orw	(0xc4f8:16), 4
	ret
ScreenGroup_InitVoiceLoop_Code_Skip4:
	ld	a, e
	and	a, 0x7
	ret	z
	ld	a, l
	extz	wa
	lda	xbc, (AudioInit_VoiceDispatch_Table_0xFC:24)
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
	lda	xbc, (AudioInit_VoiceDispatch_Table_0x11C:24)
	ld	a, (xbc+wa)
	and	a, 0x7
	sla	a, 1
	and	(xix+hl), 0xf1
	or	(xix+hl), a
; (v7 label ScreenGroup_InitParams8 stood here; dropped, see the file header)
	orw	(0xc4f8:16), 4
	ret
ScreenGroup_InitVoiceLoop_Code_Skip5:
	ld	a, e
	and	a, 0xf
; (v7 label ScreenGroup_InitParam8Loop stood here; dropped, see the file header)
	jr	z, ScreenGroup_InitVoiceLoop_Code_Skip7
	bit	6, d
	jr	nz, ScreenGroup_InitVoiceLoop_Code_Skip6
	ld	a, l
	extz	wa
	lda	xbc, (AudioInit_VoiceDispatch_Table_0xFC:24)
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
	jr	ScreenGroup_InitVoiceLoop_Code_Join3
ScreenGroup_InitVoiceLoop_Code_Skip6:
	ld	a, l
	extz	wa
	lda	xbc, (AudioInit_VoiceDispatch_Table_0xFC:24)
	ld	a, (xbc+wa)
	extz	wa
	lda	xbc, (0xc186:16)
	extz	xwa
	add	xwa, xbc
	ld	(xwa), 0xff
ScreenGroup_InitVoiceLoop_Code_Join3:
	orw	(0xc500:16), 2048
	orw	(0xc4f8:16), 4
ScreenGroup_InitVoiceLoop_Code_Skip7:
	bit	5, e
	jr	z, ScreenGroup_InitVoiceLoop_Code_Skip9
	bit	5, d
	jr	z, ScreenGroup_InitVoiceLoop_Code_Skip8
	ld	a, l
	extz	wa
	lda	xbc, (AudioInit_VoiceDispatch_Table_0xFC:24)
	ld	a, (xbc+wa)
	extz	wa
	lda	xbc, (0xc166:16)
	extz	xwa
	add	xwa, xbc
	ld	(xwa), 0xff
	cp	l, 0x13
	jr	nz, ScreenGroup_InitVoiceLoop_Code_Join4
	ld	(0xc17c:16), 255
; (v7 label ScreenGroup_FinalInit stood here; dropped, see the file header)
	jr	ScreenGroup_InitVoiceLoop_Code_Join4
ScreenGroup_InitVoiceLoop_Code_Skip8:
	ld	a, l
	extz	wa
	lda	xbc, (AudioInit_VoiceDispatch_Table_0xFC:24)
	ld	a, (xbc+wa)
	extz	wa
	lda	xbc, (0xc166:16)
	ld	ix, wa
	extz	xix
	add	xix, xbc
	ld	a, l
; (v7 label ScreenGroup_InitWordPairsLoop stood here; dropped, see the file header)
	extz	wa
	lda	xbc, (AudioInit_VoiceDispatch_Table_0xFC:24)
	ld	a, (xbc+wa)
	ld	(xix), a
	cp	l, 0x13
	jr	nz, ScreenGroup_InitVoiceLoop_Code_Join4
	ld	(0xc17c:16), 22
ScreenGroup_InitVoiceLoop_Code_Join4:
	orw	(0xc500:16), 4
	orw	(0xc4f8:16), 4
; (v7 label ScreenGroup_InitFinalize stood here; dropped, see the file header)
; (was .incbin "includes/romslices/v7_block_screengroup_initfinalize.bin")
ScreenGroup_InitVoiceLoop_Code_Skip9:
	bit	6, e
	ret	z
	bit	6, d
	jr	z, UIStateEvt_DrumAssign_Set
	ld	a, l
	extz	wa
	lda	xbc, (AudioInit_VoiceDispatch_Table_0xFC:24)
	ld	a, (xbc+wa)
	extz	wa
	lda	xbc, (0xc186:16)
	extz	xwa
	add	xwa, xbc
	.byte	0xb0, 0x00
