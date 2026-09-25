; v10 name for this address: AudioInit_ConfigStereoVoice -- not a label here: v7 defines that name outside this span (= 0xFDE5F7)
; ============================================================================
; AudioInit_ConfigStereoVoice - Configure stereo voice routing and panning
; ============================================================================
; Input:  Voice index (from voice type table at 0xee8e62)
; Output: Updates audio config flags at address 50588
; Default handler in voice-source dispatch table. Routes voices by type:
; simple stereo (type < 3) or extended routing with panning configuration.
; ============================================================================
AudioInit_VoiceNotConfigured_Code_Helper:
	ld	a, (0x8c9e:16)
	extz	wa
	lda	xbc, (AudioInit_VoiceDispatch_Table_0x16A:24)
	extz	xwa
	add	xwa, xbc
	cp	(xwa), 0x3
	.byte 0x67, 0x78
	ld	a, (0x8c9e:16)
	extz	wa
	lda	xbc, (AudioInit_VoiceDispatch_Table_0x16A:24)
	extz	xwa
	add	xwa, xbc
	ld	a, (xwa)
	ld	(0xc163:16), a
	cp	a, 0xff
	jr	z, AudioInit_VoiceNotConfigured
	orw	(0xc500:16), 2
	.byte 0xd1, 0xfc, 0xc4, 0x20
	and	wa, 0x60
	jr	nz, AudioInit_SetDefaultLevels
AudioInit_CheckVoiceMixFlags:
	ld	wa, (0xc4fa:16)
	and	wa, 0x7
	jr	z, AudioInit_SetDefaultLevels
	ld	wa, (0xc4f8:16)
	bit	4, wa
	jr	nz, AudioInit_ClearModeRegister
	set	3, (0xc162:16)
	jr	AudioInit_AfterModeSet
AudioInit_ClearModeRegister:
	ld	(0xc162:16), 0
AudioInit_AfterModeSet:
	orw	(0xc500:16), 1
AudioInit_SetDefaultLevels:
	ld	(0xc21e:16), 255
	ld	(0xc21f:16), 255
	bit	5, (0xf9f7:16)
	jr	nz, AudioInit_CheckBit5_FD07
	ld	(0xc168:16), 2
AudioInit_CheckBit5_FD07:
	bit	5, (0xfbb1:16)
	jr	nz, AudioInit_CheckBit5_FBF1
	ld	(0xc17c:16), 22
AudioInit_CheckBit5_FBF1:
	orw	(0xc500:16), 260
	jp	AudioInit_ConfigurePanning
AudioInit_VoiceNotConfigured:
	.byte 0xf1, 0x63, 0xc1, 0x00, 0xff
	orw	(0xc500:16), 3
	.byte 0xd1, 0xfc, 0xc4, 0x20
	and	wa, 0x60
	jr	nz, AudioInit_RouteAndPan
AudioInit_CheckMixFlagsAlt:
	ld	wa, (0xc4fa:16)
	and	wa, 0x7
	jr	nz, AudioInit_CheckBit2Mode
	bit	2, (0xc162:16)
	jr	z, AudioInit_RouteAndPan
AudioInit_CheckBit2Mode:
	ld	wa, (0xc4f8:16)
	bit	4, wa
	jr	nz, AudioInit_ClearModeAlt
	set	3, (0xc162:16)
	jr	AudioInit_AfterModeSetAlt
AudioInit_ClearModeAlt:
	ld	(0xc162:16), 0
AudioInit_AfterModeSetAlt:
	orw	(0xc500:16), 1
AudioInit_RouteAndPan:
	call	AudioInit_ConfigureVoiceRouting
	call	AudioInit_ConfigurePanning
	jp	AudioInit_CheckStereoMode
; v10 name for this address: AudioInit_ConfigureVoiceFromFlags -- not a label here: v7 defines that name outside this span (= 0xFDE6CE)
	ld	bc, (0xc4fc:16)
	bit	0, bc
	jr	z, AudioInit_FallbackToStereo
	ldmm8	0xc163, 0xc502
	orw	(0xc500:16), 2
	ld	wa, (0xc4fc:16)
	and	wa, 0x6e
	jr	z, AudioInit_VoiceRouteJump
	ld	wa, (0xc4fc:16)
	and	wa, 0xe
	jr	z, AudioInit_VoiceRouteJump
	ld	wa, (0xc4f8:16)
	bit	4, wa
	jr	nz, AudioInit_ClearModeFromFlags
	set	3, (0xc162:16)
	jr	AudioInit_VoiceRouteJump
AudioInit_ClearModeFromFlags:
	ld	(0xc162:16), 0
AudioInit_VoiceRouteJump:
	call	AudioInit_ConfigureVoiceRouting
	jp	AudioInit_ConfigurePanning
AudioInit_FallbackToStereo:
	extz	wa
	jrl	AudioInit_VoiceNotConfigured_Code_Helper
; v10 name for this address: AudioInit_SelectVoiceByType -- not a label here: v7 defines that name outside this span (= 0xFDE718)
	ld	a, (0x36ff:16)
	cp	a, 0x60
	jr	z, AudioInit_StereoVoiceCfg
	cp	a, 0x10
	jr	z, AudioInit_StereoVoiceCfg
	cp	a, 0x8
	jr	z, AudioInit_SetVoice19
	cp	a, 4:i3
	jr	z, AudioInit_SetVoice18
	cp	a, 2:i3
	jr	z, AudioInit_SetVoice17
	cp	a, 1:i3
	jr	nz, AudioInit_StereoVoiceCfg
	ld	(0xc163:16), 16
	orw	(0xc500:16), 2
	ret
AudioInit_SetVoice17:
	ld	(0xc163:16), 17
	orw	(0xc500:16), 2
	ret
AudioInit_SetVoice18:
	ld	(0xc163:16), 18
	orw	(0xc500:16), 2
	ret
AudioInit_SetVoice19:
	ld	(0xc163:16), 19
	orw	(0xc500:16), 2
	ret
AudioInit_StereoVoiceCfg:
	ld	(0xc163:16), 20
	orw	(0xc500:16), 2
	ret
; v10 name for this address: AudioInit_PushAndConfigVoice -- not a label here: v7 defines that name outside this span (= 0xFDE773)
	dec	2, xsp
	ld	(xsp), a
	cp	(xsp), 0x1
	call	z, (AudioInit_RefreshToneBank:24)
	orw	(0xc4f8:16), 2
	ld	a, (xsp)
	extz	wa
	calr	AudioInit_VoiceNotConfigured_Code_Helper
	inc	2, xsp
	ret
; v10 name for this address: AudioInit_PushAndConfigVoiceAlt -- not a label here: v7 defines that name outside this span (= 0xFDE773)
	dec	2, xsp
	ld	(xsp), a
	cp	(xsp), 0x1
	call	z, (AudioInit_RefreshToneBank:24)
	ld	a, (0x8c9a:16)
	cp	a, 0xc9
	jr	nz, AudioInit_LoadStackAndConfig
	ld	(0xc163:16), 23
	orw	(0xc500:16), 2
	jr	AudioInit_RestoreStack
AudioInit_LoadStackAndConfig:
	ld	a, (xsp)
	extz	wa
	calr	AudioInit_VoiceNotConfigured_Code_Helper
AudioInit_RestoreStack:
	inc	2, xsp
	ret
; v10 name for this address: AudioInit_CheckSoundGroup -- not a label here: v7 defines that name outside this span (= 0xFDE7BB)
	cp	(0x8c9a:16), 3
	jr	z, AudioInit_LoadGroupVoice
	cp	(0x8c9a:16), 8
	jr	nz, AudioInit_GroupFallbackDefault
AudioInit_LoadGroupVoice:
	ld	c, (0x8c9e:16)
	extz	bc
	lda	xde, (AudioInit_VoiceDispatch_Table_0x16A:24)
	ldb_sri	C, 0x07, 0xe8, 0xe4
	ld	(0xc163:16), c
	cp	c, 0xff
	jr	z, AudioInit_GroupFallbackStereo
	orw	(0xc500:16), 2
	ld	wa, (0xc4fc:16)
	and	wa, 0x60
	jr	nz, AudioInit_SetGroupLevels
	ld	wa, (0xc4fa:16)
	and	wa, 0x7
	jr	z, AudioInit_SetGroupLevels
	ld	wa, (0xc4f8:16)
	bit	4, wa
	jr	nz, AudioInit_ClearGroupMode
	set	3, (0xc162:16)
	jr	AudioInit_AfterGroupModeSet
AudioInit_ClearGroupMode:
	ld	(0xc162:16), 0
AudioInit_AfterGroupModeSet:
	orw	(0xc500:16), 1
AudioInit_SetGroupLevels:
	ld	(0xc21e:16), 255
	ld	(0xc21f:16), 255
	bit	5, (0xf9f7:16)
	jr	nz, AudioInit_CheckGroupBit5_FD07
	ld	(0xc168:16), 2
AudioInit_CheckGroupBit5_FD07:
	bit	5, (0xfbb1:16)
	jr	nz, AudioInit_CheckGroupBit5_FBF1
	ld	(0xc17c:16), 22
AudioInit_CheckGroupBit5_FBF1:
	orw	(0xc500:16), 260
	jp	AudioInit_ConfigurePanning
AudioInit_GroupFallbackStereo:
	extz	wa
	jrl	AudioInit_VoiceNotConfigured_Code_Helper
AudioInit_GroupFallbackDefault:
	extz	wa
	jrl	AudioInit_VoiceNotConfigured_Code_Helper
; v10 name for this address: AudioInit_CheckSoundGroup51 -- not a label here: v7 defines that name outside this span (= 0xFDE84A)
	cp	(0x8c9a:16), 81
	jr	nz, AudioInit_G51FallbackDefault
	ld	c, (0x8c9e:16)
	extz	bc
	lda	xde, (AudioInit_VoiceDispatch_Table_0x18A:24)
	ldb_sri	C, 0x07, 0xe8, 0xe4
	ld	(0xc163:16), c
	cp	c, 0xff
	jr	z, AudioInit_G51FallbackStereo
	orw	(0xc500:16), 2
	ld	wa, (0xc4fc:16)
	and	wa, 0x60
	jr	nz, AudioInit_SetGroup51Levels
	ld	wa, (0xc4fa:16)
	and	wa, 0x7
	jr	z, AudioInit_SetGroup51Levels
	ld	wa, (0xc4f8:16)
	bit	4, wa
	jr	nz, AudioInit_ClearGroup51Mode
	set	3, (0xc162:16)
	jr	AudioInit_AfterGroup51ModeSet
AudioInit_ClearGroup51Mode:
	ld	(0xc162:16), 0
AudioInit_AfterGroup51ModeSet:
	orw	(0xc500:16), 1
AudioInit_SetGroup51Levels:
	ld	(0xc21e:16), 255
	ld	(0xc21f:16), 255
	bit	5, (0xf9f7:16)
	jr	nz, AudioInit_CheckG51Bit5_FD07
	ld	(0xc168:16), 2
AudioInit_CheckG51Bit5_FD07:
	bit	5, (0xfbb1:16)
	jr	nz, AudioInit_CheckG51Bit5_FBF1
	ld	(0xc17c:16), 22
AudioInit_CheckG51Bit5_FBF1:
	orw	(0xc500:16), 260
	jp	AudioInit_ConfigurePanning
AudioInit_G51FallbackStereo:
	extz	wa
	jrl	AudioInit_VoiceNotConfigured_Code_Helper
AudioInit_G51FallbackDefault:
	extz	wa
	jrl	AudioInit_VoiceNotConfigured_Code_Helper
; v10 name for this address: AudioInit_CheckMixMode -- not a label here: v7 defines that name outside this span (= 0xFDE8D2)
	ld	c, (0x8c9a:16)
	cp	c, 0x76
	jr	z, AudioInit_LoadAndConfigure
	cp	c, 0x73
	jr	z, AudioInit_LoadAndConfigure
	cp	c, 0x72
	jr	z, AudioInit_LoadAndConfigure
	cp	c, 0x6f
	jr	nz, AudioInit_VoiceNotConfigured_Code_Skip
AudioInit_LoadAndConfigure:
	ld	c, (0x8c9e:16)	; LD C, (238D3Ah) - 24-bit addressing mode
	extz	bc
	lda	xde, (AudioInit_VoiceDispatch_Table_0x18A:24)
	ldb_sri	C, 0x07, 0xe8, 0xe4
	ld	(0xc163:16), c
	cp	c, 0xff
	jr	z, AudioInit_MixFallbackConfig
	orw	(0xc500:16), 2
	ld	wa, (0xc4f8:16)
	bit	4, wa
	ret	z
	.byte 0xf1, 0x63, 0xc1, 0x00, 0xff
	ret
AudioInit_MixFallbackConfig:
	extz	wa
	calr	AudioInit_VoiceNotConfigured_Code_Helper
	ret
; v10 name for this address: AudioInit_MixFallbackDefault -- not a label here: v7 defines that name outside this span (= 0xFDE8C8)
AudioInit_VoiceNotConfigured_Code_Skip:
	extz	wa
	jrl	AudioInit_VoiceNotConfigured_Code_Helper
	extz	wa
	jrl	AudioInit_VoiceNotConfigured_Code_Helper
; v10 name for this address: AudioInit_DrumSaveReturn -- not a label here: v7 defines that name outside this span (= 0xFDE928)
DSPCfg_EventType50_Code_Helper:
	ldw	(0xc508:16), 0
	ldw	(0xc50a:16), 0
	push	xde
	push	xhl
	push	xix
	push	xiz
	lda	xwa, (0xc162:16)
	call	CtrlPanel_RefreshIndicatorState
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ret
; v10 name for this address: AudioInit_VoiceParamCtrl -- not a label here: v7 defines that name outside this span (= 0xFDE945)
DSPCfg_EventType50_Code_Helper2:
	dec	6, xsp
	ld	c, 0x0:opc
	bit	0, (0xfd53:16)
	jr	z, AudioInit_CheckVoiceParamState
	set	1, c
AudioInit_CheckVoiceParamState:
	.byte 0xc1, 0x63, 0xc1, 0x3f, 0xff
	jr	nz, AudioInit_CompareAndSendMIDI
	cp	(0xc52c:16), 255
	jr	z, AudioInit_CheckBit2VoiceParam
	set	0, c
	ld	wa, (0xc4fa:16)
	and	wa, 0x80
	cp	wa, 0x80
	jr	nz, AudioInit_CompareAndSendMIDI
	ld	wa, (0xc4fa:16)
	and	wa, 0x3
	jr	z, AudioInit_CompareAndSendMIDI
	set	4, c
	jr	AudioInit_CompareAndSendMIDI
AudioInit_CheckBit2VoiceParam:
	ld	wa, (0xc4fa:16)
	bit	2, wa
	jr	z, AudioInit_CompareAndSendMIDI
	or	c, 0x18
AudioInit_CompareAndSendMIDI:
	cp	(0xc50c:16), c
	jr	z, AudioInit_VoiceParamDone
	ld	(0xc50c:16), c
	ld	(xsp + 256), 0x4	; LD (XSP + 000h), 004h - explicit displacement encoding
	ld	(xsp + 1), 0xf0
	ld	(xsp + 2), 0x50
	ld	(xsp + 3), 0x91
	ldmi16	(xsp + 4), 0xc50c
	lda	xwa, (xsp)
	call	MIDI_SendCmdPacket
	call	MIDI_PostSendStub
	cp	(0x8c98:16), 13
	jr	z, AudioInit_VoiceParamDone
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	Audio_ProcessPartExpressions
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
AudioInit_VoiceParamDone:
	inc	6, xsp
	ret
; v10 name for this address: AudioInit_DrumRoutingCheck -- not a label here: v7 defines that name outside this span (= 0xFDE9CB)
DSPCfg_EventType50_Code_Helper3:
	ld	de, 0:i3
	bit	2, (0xc162:16)
	.byte 0x6e, 0x16
AudioInit_CheckOutputFlags:
	ld	wa, (0xc4fc:16)
	and	wa, 0x60
	jrl	nz, AudioInit_NoRoutingActive
	ld	wa, (0xc4fa:16)
	and	wa, 0x3
	jrl	z, AudioInit_NoRoutingActive
AudioInit_ProcessVoiceAssign:
	.byte 0xc1, 0x63, 0xc1, 0x3f, 0xff
	jr	nz, AudioInit_CheckStoredVoice
	set	3, de
	ldmm8	0xc52c, 0xc506
	jr	AudioInit_UpdateVoiceBank0
AudioInit_CheckStoredVoice:
	cp	(0xc52c:16), 255
	jr	z, AudioInit_ClearStoredVoice
	set	3, de
AudioInit_ClearStoredVoice:
	ld	(0xc52c:16), 255
AudioInit_UpdateVoiceBank0:
	ld	a, (0xc227:16)
	srl	a, 1
	cp	a, (0xc506:16)
	jr	z, AudioInit_UpdateVoiceBank1
	set	7, (0xc226:16)
	ld	a, (0xc506:16)
	res	7, a
	sla	a, 1
	and	(0xc227:16), 1
	or	(0xc227:16), a
	orw	(0xc4fe:16), 512
AudioInit_UpdateVoiceBank1:
	ld	a, (0xc22b:16)
	srl	a, 1
	cp	a, (0xc506:16)
	jr	z, AudioInit_UpdateVoiceBank2
	set	7, (0xc22a:16)
	ld	a, (0xc506:16)
	res	7, a
	sla	a, 1
	and	(0xc22b:16), 1
	or	(0xc22b:16), a
	orw	(0xc4fe:16), 512
AudioInit_UpdateVoiceBank2:
	ld	a, (0xc506:16)
	dec	1, a
	ld	c, (0xc22e:16)
	res	7, c
	cp	c, a
	jr	z, AudioInit_CheckStereoRouting
	set	7, (0xc22e:16)
	ld	a, (0xc506:16)
	dec	1, a
	res	7, a
	and	(0xc22e:16), 128
	or	(0xc22e:16), a
	orw	(0xc4fe:16), 512
AudioInit_CheckStereoRouting:
	bit	3, (0xc162:16)
	jr	z, AudioInit_ClearStereoRouting
	ld	a, (0xc506:16)
	dec	1, a
	ld	c, (0xc232:16)
	res	7, c
	cp	c, a
	jr	z, AudioInit_VoiceStereoCheck
	set	7, (0xc232:16)
	ld	a, (0xc506:16)
	dec	1, a
	res	7, a
	and	(0xc232:16), 128
	or	(0xc232:16), a
	orw	(0xc4fe:16), 512
	jr	AudioInit_VoiceStereoCheck
AudioInit_ClearStereoRouting:
	ld	a, (0xc232:16)
	res	7, a
	cp	a, 0:i3
	jr	z, AudioInit_VoiceStereoCheck
	set	7, (0xc232:16)
	and	(0xc232:16), 128
	orw	(0xc4fe:16), 512
AudioInit_VoiceStereoCheck:
	ld	a, (0xc237:16)
	srl	a, 1
	cp	a, (0xc506:16)
	jrl	z, AudioInit_UpdateIndicators
	set	7, (0xc236:16)
	ld	a, (0xc506:16)
	res	7, a
	sla	a, 1
	and	(0xc237:16), 1
	or	(0xc237:16), a
	orw	(0xc4fe:16), 512
	jrl	AudioInit_UpdateIndicators
AudioInit_NoRoutingActive:
	cp	(0xc52c:16), 255
	jr	z, AudioInit_ClearAllVoiceBanks
	set	3, de
AudioInit_ClearAllVoiceBanks:
	ld	(0xc52c:16), 255
	ld	a, (0xc227:16)
	res	0, a
	cp	a, 0:i3
	jr	z, AudioInit_ClearBank1Routing
	set	7, (0xc226:16)
	and	(0xc227:16), 1
	orw	(0xc4fe:16), 512
AudioInit_ClearBank1Routing:
	ld	a, (0xc22b:16)
	res	0, a
	cp	a, 0:i3
	jr	z, AudioInit_ClearBank2Routing
	set	7, (0xc22a:16)
	and	(0xc22b:16), 1
	orw	(0xc4fe:16), 512
AudioInit_ClearBank2Routing:
	ld	a, (0xc22e:16)
	res	7, a
	cp	a, 0:i3
	jr	z, AudioInit_CheckBit2Routing
	set	7, (0xc22e:16)
	and	(0xc22e:16), 128
	orw	(0xc4fe:16), 512
AudioInit_CheckBit2Routing:
	ld	wa, (0xc4fa:16)
	bit	2, wa
	jr	z, AudioInit_ClearBank3Routing
	ld	a, (0xc232:16)
	res	7, a
	cp	a, 0x7f
	jr	z, AudioInit_UpdateIndicators
	set	7, (0xc232:16)
	or	(0xc232:16), 127
	orw	(0xc4fe:16), 512
	jr	AudioInit_UpdateIndicators
AudioInit_ClearBank3Routing:
	ld	a, (0xc232:16)
	res	7, a
	cp	a, 0:i3
	jr	z, AudioInit_UpdateIndicators
	set	7, (0xc232:16)
	and	(0xc232:16), 128
	orw	(0xc4fe:16), 512
AudioInit_UpdateIndicators:
	bit	3, de
	ret	z
	ldw	wa, 0x45
	call	CtrlPanel_SetIndicatorBit
	cp	(0xc52c:16), 255
	jr	z, AudioInit_ClearDrumModeAlt
	ld	a, (0xfd02:16)
	and	a, 0x3
	jr	z, AudioInit_ClearDrumMode
	ld	a, (0xc506:16)
	cp	a, 0x43
	jr	z, AudioInit_SetDrumMode4
	cp	a, 0x3c
	jr	z, AudioInit_SetDrumMode2
	cp	a, 0x37
	ret	nz
	ld	(0x8ebc:16), 1
	ret
AudioInit_SetDrumMode2:
	ld	(0x8ebc:16), 2
	ret
AudioInit_SetDrumMode4:
	ld	(0x8ebc:16), 4
	ret
AudioInit_ClearDrumMode:
	and	(0x8ebc:16), 248
	ret
AudioInit_ClearDrumModeAlt:
	and	(0x8ebc:16), 248
	ret
; v10 name for this address: AudioInit_ClearPartFlags_ByMode -- not a label here: v7 defines that name outside this span (= 0xFDEC26)
DSPCfg_EventType50_Code_Helper4:
	ld	wa, (0xc4f8:16)
	and	wa, 0x3
	jr	z, AudioInit_SetPartMasks
	ld	de, 0:i3
	cp	de, 0x1a
	ret	nc
AudioInit_ClearPartFlags_Loop:
	ld	wa, de
	add	wa, wa
	lda	xbc, (0xc286:16)
	extz	xwa
	add	xwa, xbc
	resm	5, (xwa)
	orw	(0xc500:16), 8
	inc	1, de
	cp	de, 0x1a
	jr	c, AudioInit_ClearPartFlags_Loop
	ret
AudioInit_SetPartMasks:
	ld	de, 0:i3
	cp	de, 0x10
	jr	nc, AudioInit_CheckGlobalFlag6
AudioInit_SetPartMasks_Loop:
	ld	wa, de
	add	wa, wa
	lda	xbc, (0xc286:16)
	extz	xwa
	add	xwa, xbc
	setm	5, (xwa)
	inc	1, de
	cp	de, 0x10
	jr	c, AudioInit_SetPartMasks_Loop
AudioInit_CheckGlobalFlag6:
	bit	6, (0xfd53:16)
	jr	z, AudioInit_ClearVoiceGroupFlags
	set	5, (0xc2a6:16)
	set	5, (0xc2a8:16)
	set	5, (0xc2aa:16)
	set	5, (0xc2ac:16)
	set	5, (0xc2b0:16)
	jr	AudioInit_CheckVoiceFlag6
AudioInit_ClearVoiceGroupFlags:
	res	5, (0xc2a6:16)
	res	5, (0xc2a8:16)
	res	5, (0xc2aa:16)
	res	5, (0xc2ac:16)
	res	5, (0xc2b0:16)
	orw	(0xc500:16), 8
AudioInit_CheckVoiceFlag6:
	bit	6, (0xfd50:16)
	jr	z, AudioInit_ClearAuxVoiceFlag
	set	5, (0xc2ae:16)
	jr	AudioInit_CheckReverbFlag
AudioInit_ClearAuxVoiceFlag:
	res	5, (0xc2ae:16)
	orw	(0xc500:16), 8
AudioInit_CheckReverbFlag:
	bit	7, (0xfd53:16)
	jr	z, AudioInit_ClearReverbFlag
	set	5, (0xc2b8:16)
	ret
AudioInit_ClearReverbFlag:
	res	5, (0xc2b8:16)
	orw	(0xc500:16), 8
	ret
; v10 name for this address: Audio_CheckInitStatus -- not a label here: v7 defines that name outside this span (= 0xFDECA1)
DSPCfg_EventType50_Code_Helper5:
	dec	2, xsp
	ldw	(xsp), 0x0
	ldw	(0xc4fc:16), 0
	ld	(0xc502:16), 255
	ld	hl, (0xf19e:16)
	or	hl, (3409:16)
	ld	wa, hl
	cp	wa, 0:i3
	jr	z, AudioInit_ClearStatusBit8
	orw	(0xc4fc:16), 256
	jr	AudioInit_CheckGroupB_Presence
AudioInit_ClearStatusBit8:
	andw	(0xc4fc:16), 0xfeff
AudioInit_CheckGroupB_Presence:
	ld	bc, (0x28a8:16)
	or	bc, (3407:16)
	ld	wa, bc
	cp	wa, 0:i3
	jr	z, AudioInit_ClearStatusBit9
	orw	(0xc4fc:16), 512
	jr	AudioInit_ChannelLoop_Init
AudioInit_ClearStatusBit9:
	andw	(0xc4fc:16), 0xfdff
AudioInit_ChannelLoop_Init:
	ld	e, 0x0:opc
	cp	e, 0x10
	jrl	nc, AudioInit_ChannelLoop_Done
; v10 name for this address: AudioInit_ChannelLoop_Body -- not a label here: v7 defines that name outside this span (= 0xFDECF2)
AudioInit_ProcessVoiceAssign_Code_Loop:
	ld	a, e
	extz	wa
	lda	xix, (0xf1a0:16)
	extz	xwa
	add	xwa, xix
	ld	a, (xwa)
	ld	d, a
	.byte 0xf1, 0x3e, 0xf2, 0xc9, 0x66, 0x2e, 0xc7, 0xe6
	.byte 0x03, 0xff, 0xcd, 0x89, 0xd8, 0x12, 0xf1, 0xb0
	.byte 0xf1, 0x34, 0xe8, 0x12, 0xec, 0x80, 0x80, 0x3f
	.byte 0x10, 0x66, 0x11, 0xcd, 0x89, 0xd8, 0x12, 0xf1
	.byte 0xb0, 0xf1, 0x34, 0xe8, 0x12, 0xec, 0x80, 0x80
	.byte 0x21, 0xc7, 0xe6, 0x99, 0xc7, 0xe6, 0x89, 0xc7
	.byte 0xe2, 0x99, 0x68, 0x45
	ld	a, e
	extz	wa
	add	wa, wa
	lda	xix, (SystemConfig_PointerTable_0x56:24)
	ldw_sri	WA, 0x07, 0xf0, 0xe0
	and	wa, (0xf290:16)
	jr	z, AudioInit_VoiceNotAssigned
	ld	a, e
	extz	wa
	lda	xix, (0xf1a0:16)
	extz	xwa
	add	xwa, xix
	ld	a, (xwa)
	extz	wa
	lda	xix, (AudioInit_VoiceDispatch_Table_0x1AA:24)
	ldb_sri	A, 0x07, 0xf0, 0xe0
	extz	wa
	lda	xix, (0xc186:16)
	extz	xwa
	add	xwa, xix
	ld	a, (xwa)
	ldb_erp	A, 0xe2
	jr	AudioInit_CheckVoiceChanged
AudioInit_VoiceNotAssigned:
	ldi_erpb	0xe2, 0xff
AudioInit_CheckVoiceChanged:
	ld	a, d
	extz	wa
	lda	xix, (AudioInit_VoiceDispatch_Table_0x1AA:24)
	cpib_sri	0x07, 0xf0, 0xe0, 0xff
	jr	z, AudioInit_VoiceUnchanged
	ld	a, e
	extz	wa
	add	wa, wa
	lda	xix, (SystemConfig_PointerTable_0x56:24)
	ldw_sri	WA, 0x07, 0xf0, 0xe0
	ld	ix, hl
	or	ix, bc
	and	ix, wa
	jr	nz, AudioInit_CheckGroupA
AudioInit_VoiceUnchanged:
	ld	a, e
	extz	wa
	lda	xix, (0xc1e6:16)
	extz	xwa
	add	xwa, xix
	ld	(xwa), 0xff
	ld	a, e
	extz	wa
	lda	xix, (0xc206:16)
	extz	xwa
	add	xwa, xix
	ld	(xwa), 0xff
	jrl	AudioInit_ChannelLoop_Next
AudioInit_CheckGroupA:
	ld	wa, (0xc4fc:16)
	bit	8, wa
	jrl	z, AudioInit_CheckGroupB_Channel
	ld	a, e
	extz	wa
	add	wa, wa
	lda	xix, (SystemConfig_PointerTable_0x56:24)
	ldw_sri	WA, 0x07, 0xf0, 0xe0
	and	wa, hl
	jrl	z, AudioInit_CheckGroupB_Channel
	ld	a, d
	cp	a, 0xe
	jr	z, AudioInit_GroupA_TypeE
	cp	a, 0xd
	jrl	nz, AudioInit_GroupA_OtherType
	orw	(0xc4fc:16), 32
	ld	a, e
	extz	wa
	lda	xix, (0xc1e6:16)
	ld	iy, wa
	extz	xiy
	add	xiy, xix
	ld	a, d
	extz	wa
	lda	xix, (AudioInit_VoiceDispatch_Table_0x1AA:24)
	ldb_sri	A, 0x07, 0xf0, 0xe0
	ld	(xiy), a
	ld	a, e
	extz	wa
	lda	xix, (0xc1f6:16)
	ld	iy, wa
	extz	xiy
	add	xiy, xix
	ld	a, d
	extz	wa
	lda	xix, (AudioInit_VoiceDispatch_Table_0x1AA:24)
	ldb_sri	A, 0x07, 0xf0, 0xe0
	ld	(xiy), a
	jrl	AudioInit_CheckGroupB_Channel
AudioInit_GroupA_TypeE:
	orw	(0xc4fc:16), 64
	ld	a, e
	extz	wa
	lda	xix, (0xc1e6:16)
	ld	iy, wa
	extz	xiy
	add	xiy, xix
	ld	a, d
	extz	wa
	lda	xix, (AudioInit_VoiceDispatch_Table_0x1AA:24)
	ldb_sri	A, 0x07, 0xf0, 0xe0
	ld	(xiy), a
	ld	a, e
	extz	wa
	lda	xix, (0xc1f6:16)
	ld	iy, wa
	extz	xiy
	add	xiy, xix
	ld	a, d
	extz	wa
	lda	xix, (AudioInit_VoiceDispatch_Table_0x1AA:24)
	ldb_sri	A, 0x07, 0xf0, 0xe0
	ld	(xiy), a
	jrl	AudioInit_CheckGroupB_Channel
AudioInit_GroupA_OtherType:
	cp	(0x8c9a:16), 138
	jr	nz, AudioInit_GroupA_DefaultMapping
	ld	a, e
	extz	wa
	lda	xix, (0xc1e6:16)
	ld	iy, wa
	extz	xiy
	add	xiy, xix
	ld	a, d
	extz	wa
	lda	xix, (AudioInit_VoiceDispatch_Table_0x1AA:24)
	ldb_sri	A, 0x07, 0xf0, 0xe0
	ld	(xiy), a
	ld	a, e
	extz	wa
	add	wa, wa
	lda	xix, (SystemConfig_PointerTable_0x56:24)
	ldw_sri	WA, 0x07, 0xf0, 0xe0
	and	wa, (3928:16)
	jr	z, AudioInit_GroupA_NoAuxMapping
	ld	a, e
	extz	wa
	lda	xix, (0xc1f6:16)
	ld	iy, wa
	extz	xiy
	add	xiy, xix
	ld	a, d
	extz	wa
	lda	xix, (AudioInit_VoiceDispatch_Table_0x1AA:24)
	ldb_sri	A, 0x07, 0xf0, 0xe0
	ld	(xiy), a
	jr	AudioInit_StoreChannelMapping
AudioInit_GroupA_NoAuxMapping:
	ld	a, e
	extz	wa
	lda	xix, (0xc1f6:16)
	ld	iy, wa
	extz	xiy
	add	xiy, xix
	ld	(xiy), 0xff
	jr	AudioInit_StoreChannelMapping
AudioInit_GroupA_DefaultMapping:
	ld	a, e
	extz	wa
	lda	xix, (0xc1e6:16)
	ld	iy, wa
	extz	xiy
	add	xiy, xix
	ld	a, d
	extz	wa
	lda	xix, (AudioInit_VoiceDispatch_Table_0x1AA:24)
	ldb_sri	A, 0x07, 0xf0, 0xe0
	ld	(xiy), a
	ld	a, e
	extz	wa
	add	wa, wa
	lda	xix, (SystemConfig_PointerTable_0x56:24)
	ldw_sri	WA, 0x07, 0xf0, 0xe0
	and	wa, (0xf1d0:16)
	jr	z, AudioInit_GroupA_NoSecondary
	ld	a, e
	extz	wa
	lda	xix, (0xc1f6:16)
	ld	iy, wa
	extz	xiy
	add	xiy, xix
	ld	a, d
	extz	wa
	lda	xix, (AudioInit_VoiceDispatch_Table_0x1AA:24)
	ldb_sri	A, 0x07, 0xf0, 0xe0
	ld	(xiy), a
	jr	AudioInit_StoreChannelMapping
AudioInit_GroupA_NoSecondary:
	ld	a, e
	extz	wa
	lda	xix, (0xc1f6:16)
	ld	iy, wa
	extz	xiy
	add	xiy, xix
	ld	(xiy), 0xff
AudioInit_StoreChannelMapping:
	ld	a, e
	extz	wa
	lda	xix, (0xc206:16)
	ld	iy, wa
	extz	xiy
	add	xiy, xix
	stb_erp	A, 0xe2
	ld	(xiy), a
AudioInit_CheckGroupB_Channel:
	ld	wa, (0xc4fc:16)
	bit	9, wa
	jrl	z, AudioInit_ChannelLoop_Next
	ld	a, e
	extz	wa
	add	wa, wa
	lda	xix, (SystemConfig_PointerTable_0x56:24)
	ldw_sri	WA, 0x07, 0xf0, 0xe0
	and	wa, bc
	jrl	z, AudioInit_ChannelLoop_Next
	incw	1, (xsp)
	cp	(0xc502:16), 255
	jr	nz, AudioInit_GroupB_CheckType
	ld	a, d
	extz	wa
	lda	xix, (AudioInit_VoiceDispatch_Table_0x1AA:24)
	ldmm_srib	0x07, 0xf0, 0xe0, 0x2, 0xc5
AudioInit_GroupB_CheckType:
	ld	a, d
	cp	a, 0x10
	jrl	z, AudioInit_GroupB_Type10
	cp	a, 0xe
	jr	z, AudioInit_GroupB_TypeE
	cp	a, 0xd
	jrl	nz, AudioInit_GroupB_DefaultMapping
	orw	(0xc4fc:16), 2
	ld	a, e
	extz	wa
	lda	xix, (0xc1e6:16)
	ld	iy, wa
	extz	xiy
	add	xiy, xix
	ld	a, d
	extz	wa
	lda	xix, (AudioInit_VoiceDispatch_Table_0x1AA:24)
	ldb_sri	A, 0x07, 0xf0, 0xe0
	ld	(xiy), a
	ld	a, e
	extz	wa
	lda	xix, (0xc1f6:16)
	ld	iy, wa
	extz	xiy
	add	xiy, xix
	ld	a, d
	extz	wa
	lda	xix, (AudioInit_VoiceDispatch_Table_0x1AA:24)
	ldb_sri	A, 0x07, 0xf0, 0xe0
	ld	(xiy), a
	jrl	AudioInit_ChannelLoop_Next
AudioInit_GroupB_TypeE:
	orw	(0xc4fc:16), 4
	ld	a, e
	extz	wa
	lda	xix, (0xc1e6:16)
	ld	iy, wa
	extz	xiy
	add	xiy, xix
	ld	a, d
	extz	wa
	lda	xix, (AudioInit_VoiceDispatch_Table_0x1AA:24)
	ldb_sri	A, 0x07, 0xf0, 0xe0
	ld	(xiy), a
	ld	a, e
	extz	wa
	lda	xix, (0xc1f6:16)
	ld	iy, wa
	extz	xiy
	add	xiy, xix
	ld	a, d
	extz	wa
	lda	xix, (AudioInit_VoiceDispatch_Table_0x1AA:24)
	ldb_sri	A, 0x07, 0xf0, 0xe0
	ld	(xiy), a
	jr	AudioInit_ChannelLoop_Next
AudioInit_GroupB_Type10:
	orw	(0xc4fc:16), 8
	ld	a, e
	extz	wa
	lda	xix, (0xc1e6:16)
	extz	xwa
	add	xwa, xix
	ld	(xwa), 0xff
	ld	a, e
	extz	wa
	lda	xix, (0xc1f6:16)
	extz	xwa
	add	xwa, xix
	ld	(xwa), 0xff
	jr	AudioInit_ChannelLoop_Next
AudioInit_GroupB_DefaultMapping:
	ld	a, e
	extz	wa
	lda	xix, (0xc1e6:16)
	ld	iy, wa
	extz	xiy
	add	xiy, xix
	ld	a, d
	extz	wa
	lda	xix, (AudioInit_VoiceDispatch_Table_0x1AA:24)
	ldb_sri	A, 0x07, 0xf0, 0xe0
	ld	(xiy), a
	ld	a, e
	extz	wa
	lda	xix, (0xc1f6:16)
	ld	iy, wa
	extz	xiy
	add	xiy, xix
	ld	a, d
	extz	wa
	lda	xix, (AudioInit_VoiceDispatch_Table_0x1AA:24)
	ldb_sri	A, 0x07, 0xf0, 0xe0
	ld	(xiy), a
AudioInit_ChannelLoop_Next:
	orw	(0xc500:16), 192
	inc	1, e
	cp	e, 0x10
	jrl	c, AudioInit_ProcessVoiceAssign_Code_Loop
AudioInit_ChannelLoop_Done:
	cpw	(xsp), 0x1
	jr	nz, AudioInit_SetChangedFlag
	orw	(0xc4fc:16), 1
AudioInit_SetChangedFlag:
	bit	3, (0x28b3:16)
	jr	z, AudioInit_CheckExternalBit3
	andw	(0xc4fc:16), 0xfdff
AudioInit_CheckExternalBit3:
	ld	wa, (0xc4fc:16)
	bit	6, wa
	jr	z, AudioInit_NoTypeE_CheckD
	ld	a, (0xfc5e:16)
	and	a, 0x7
	extz	wa
	add	wa, wa
	lda	xbc, (AudioInit_VoiceDispatch_Table_0x130:24)
	ldw_sri	DE, 0x07, 0xe4, 0xe0
	ld	a, (0xfc5d:16)
	and	a, 0x8
	extz	wa
	add	wa, wa
	lda	xbc, (AudioInit_VoiceDispatch_Table_0x130:24)
	or_sriw_rm	DE, 0x07, 0xe4, 0xe0
	jr	AudioInit_ApplyOutputRouting
AudioInit_NoTypeE_CheckD:
	ld	wa, (0xc4fc:16)
	and	wa, 0x22
	cp	wa, 0x20
	jr	nz, AudioInit_DefaultOutputRouting
	ld	de, 2:i3
	ld	a, (0xfc5d:16)
	and	a, 0x8
	extz	wa
	add	wa, wa
	lda	xbc, (AudioInit_VoiceDispatch_Table_0x130:24)
	or_sriw_rm	DE, 0x07, 0xe4, 0xe0
	jr	AudioInit_ApplyOutputRouting
AudioInit_DefaultOutputRouting:
	ld	a, (0xfc5d:16)
	and	a, 0xf
	extz	wa
	add	wa, wa
	lda	xbc, (AudioInit_VoiceDispatch_Table_0x130:24)
	ldw_sri	DE, 0x07, 0xe4, 0xe0
AudioInit_ApplyOutputRouting:
	andw	(0xc4fa:16), 0xffe8
	or	(0xc4fa:16), de
	inc	2, xsp
	ret
AudioInit_SelectPriority:
	ld	a, (0x36ff:16)
	cp	a, 0x10
	jrl	z, AudioInit_Priority_Mode10
	cp	a, 0x8
	jr	z, AudioInit_Priority_Mode8
	cp	a, 4:i3
	jr	z, AudioInit_Priority_Mode4
	cp	a, 2:i3
	jr	z, AudioInit_Priority_Mode2
	cp	a, 1:i3
	jrl	nz, AudioInit_Priority_Default
	ld	(0xc1b6:16), 0
	ld	(0xc1b7:16), 255
	ld	(0xc1b8:16), 255
	ld	(0xc1b9:16), 255
	ld	(0xc1ba:16), 255
	orw	(0xc500:16), 16
	ret
AudioInit_Priority_Mode2:
	ld	(0xc1b6:16), 255
	ld	(0xc1b7:16), 1
	ld	(0xc1b8:16), 255
	ld	(0xc1b9:16), 255
	ld	(0xc1ba:16), 255
	orw	(0xc500:16), 16
	ret
AudioInit_Priority_Mode4:
	ld	(0xc1b6:16), 255
	ld	(0xc1b7:16), 255
	ld	(0xc1b8:16), 2
	ld	(0xc1b9:16), 255
	ld	(0xc1ba:16), 255
	orw	(0xc500:16), 16
	ret
AudioInit_Priority_Mode8:
	ld	(0xc1b6:16), 255
	ld	(0xc1b7:16), 255
	ld	(0xc1b8:16), 255
	ld	(0xc1b9:16), 3
	ld	(0xc1ba:16), 255
	orw	(0xc500:16), 16
	ret
AudioInit_Priority_Mode10:
	ld	(0xc1b6:16), 255
	ld	(0xc1b7:16), 255
	ld	(0xc1b8:16), 255
	ld	(0xc1b9:16), 255
	ld	(0xc1ba:16), 4
	orw	(0xc500:16), 16
	ret
AudioInit_Priority_Default:
	ld	(0xc1b6:16), 255
	ld	(0xc1b7:16), 255
	ld	(0xc1b8:16), 255
	ld	(0xc1b9:16), 255
	ld	(0xc1ba:16), 255
	orw	(0xc500:16), 16
	ret
AudioInit_CheckMIDIStatus:
	cp	(0x7e6f:16), 0
	jr	z, AudioInit_MIDIDisabled
	ld	(0xc1dd:16), 0
	ld	(0xc1de:16), 255
	orw	(0xc500:16), 32
	ret
AudioInit_MIDIDisabled:
	ld	(0xc1dd:16), 255
	ld	(0xc1de:16), 255
	orw	(0xc500:16), 32
	ret
AudioInit_RefreshToneBank:
Interrupt_FlagSetBytecode_Helper:
	pushw	iz
	ld	iz, (0xc4fa:16)
	andw	(0xc4fa:16), 0xffef
	call	Voice_UpdatePlayModeState
	cp	l, 0xff
	call	nz, (VoiceEvent_AllocAllLayers:24)
	call	NoteMap_FindBestMatch
	cp	l, 0xff
	call	nz, (VoiceEvent_DispatchTable:24)
	ld	(0xc4fa:16), iz
	popw	iz
	ret
; NOTE: THE NAME IS A MISNOMER. These 248 bytes are a ROUTINE, not a table, and
; nothing in the tree references this label. It clears bit 7 and sets bits 5/6
; across the two 0x20-entry arrays at 0xc2e2 and 0xc322, after a run of
; `or (0xc2c2),0x7f` / `and (0xc2c3),0x01` pairs whose address operand steps by
; one from 0xc2c2 to 0xc2d5, and it ends on `ret` at its last byte. The name is
; left alone (semantic labeling is deferred, and renaming an unreferenced label
; buys nothing); this comment is the record. The 119 bytes still spelled
; `.byte` below are `or (nnnn),n`, `and (nnnn),n`, `res n,(XWA)` and
; `set n,(XWA)`, which tlcs900_backend cannot yet encode -- they are not data.
AudioInit_VoiceRoutingTable:
	ret
	ret
	ret
	ret
	ret
	ret
	ret
	ld	(0xc162:16), 0
	.byte 0xc1, 0x26, 0xc2, 0x3e, 0x7f, 0xc1, 0x27, 0xc2
	.byte 0x3c, 0x01, 0xc1, 0x28, 0xc2, 0x3e, 0xfe, 0xc1
	.byte 0x29, 0xc2, 0x3c, 0x01, 0xc1, 0x2a, 0xc2, 0x3e
	.byte 0x7f, 0xc1, 0x2b, 0xc2, 0x3c, 0x01, 0xc1, 0x2c
	.byte 0xc2, 0x3e, 0xfe, 0xc1, 0x2d, 0xc2, 0x3c, 0x01
	.byte 0xc1, 0x2e, 0xc2, 0x3e, 0x7f, 0xc1, 0x2f, 0xc2
	.byte 0x3c, 0x01, 0xc1, 0x30, 0xc2, 0x3e, 0xfe, 0xc1
	.byte 0x31, 0xc2, 0x3c, 0x01, 0xc1, 0x32, 0xc2, 0x3e
	.byte 0x7f, 0xc1, 0x33, 0xc2, 0x3c, 0x01, 0xc1, 0x34
	.byte 0xc2, 0x3e, 0xfe, 0xc1, 0x35, 0xc2, 0x3c, 0x01
	.byte 0xc1, 0x36, 0xc2, 0x3e, 0x7f, 0xc1, 0x37, 0xc2
	.byte 0x3c, 0x01, 0xc1, 0x38, 0xc2, 0x3e, 0xfe, 0xc1
	.byte 0x39, 0xc2, 0x3c, 0x01
	ld	de, 0:i3
	cp	de, 32
	ret	nc
AudioInit_RefreshToneBank_Loop:
	ld	wa, de
	add	wa, wa
	lda	xbc, (0xc246:16)
	extz	xwa
	add	xwa, xbc
	.byte	0xb0, 0xb7
	ld	wa, de
	add	wa, wa
	lda	xbc, (0xc246:16)
	extz	xwa
	add	xwa, xbc
	.byte	0x80, 0x3c, 0x8f
	ld	wa, de
	add	wa, wa
	lda	xbc, (0xc286:16)
	extz	xwa
	add	xwa, xbc
	.byte	0xb0, 0xb7
	ld	wa, de
	add	wa, wa
	lda	xbc, (0xc286:16)
	extz	xwa
	add	xwa, xbc
	.byte	0xb0, 0xbe
	ld	wa, de
	add	wa, wa
	lda	xbc, (0xc286:16)
	extz	xwa
	add	xwa, xbc
	.byte	0xb0, 0xbd
	ld	wa, de
	add	wa, wa
	lda	xbc, (0xc286:16)
	extz	xwa
	add	xwa, xbc
	.byte	0xb0, 0xb4
	ld	wa, de
	add	wa, wa
	lda	xbc, (0xc286:16)
	extz	xwa
	add	xwa, xbc
	.byte	0x80, 0x3c, 0xf1
	ld	wa, de
	add	wa, wa
	add	wa, 292
	lda	xbc, (0xc163:16)
	extz	xwa
	add	xwa, xbc
	.byte	0x80, 0x3c, 0x0f
	inc	1, de
	cp	de, 32
	jr	c, AudioInit_RefreshToneBank_Loop
	ret
AudioInit_ConfigureVoiceRouting:
	andw	(0xc4fa:16), 0xfeff
	ld	wa, (0xc4fa:16)
	and	wa, 0x3
	jrl	z, AudioInit_Routing_NoActiveVoices
	ld	wa, (0xc4fa:16)
	and	wa, 0xa0
	cp	wa, 0xa0
	jrl	nz, AudioInit_Routing_NoGroupAB
	res	2, (0xc162:16)
	orw	(0xc500:16), 1
	ld	(0xc21e:16), 2
	ld	(0xc21f:16), 22
	ld	(0xc168:16), 255
	ld	(0xc17c:16), 255
	ld	wa, (0xc4fa:16)
	bit	9, wa
	jr	z, AudioInit_Routing_CheckSplitMode
	ld	a, (0xfc5f:16)
	and	a, 0xfc
	jr	nz, AudioInit_Routing_SetOverrideFlag
	ld	a, (0xfc60:16)
	and	a, 0xfc
	jr	nz, AudioInit_Routing_SetOverrideFlag
	bit	5, (0xf9f7:16)
	jrl	nz, AudioInit_Routing_SkipToEnd
	ld	(0xc168:16), 2
	jrl	AudioInit_Routing_Done
AudioInit_Routing_SetOverrideFlag:
	orw	(0xc4fa:16), 256
	jrl	AudioInit_Routing_Done
AudioInit_Routing_CheckSplitMode:
	bit	1, (0xfc5f:16)
	jr	z, AudioInit_Routing_NoSplit
	ld	a, (0xfc5f:16)
	and	a, 0xfc
	jr	nz, AudioInit_Routing_SplitOverride
	ld	a, (0xfc60:16)
	and	a, 0xfc
	jr	nz, AudioInit_Routing_SplitOverride
	bit	5, (0xf9f7:16)
	jr	nz, AudioInit_Routing_SplitCheckAux
	ld	(0xc168:16), 2
AudioInit_Routing_SplitCheckAux:
	bit	5, (0xfbb1:16)
	jrl	nz, AudioInit_Routing_SkipToEnd
	ld	(0xc17c:16), 22
	jrl	AudioInit_Routing_Done
AudioInit_Routing_SplitOverride:
	orw	(0xc4fa:16), 256
	jrl	AudioInit_Routing_Done
AudioInit_Routing_NoSplit:
	ld	a, (0xfc5f:16)
	and	a, 0xfc
	jr	nz, AudioInit_Routing_CheckTypeEDFlags
	ld	a, (0xfc60:16)
	and	a, 0xfc
	jr	nz, AudioInit_Routing_CheckTypeEDFlags
	bit	5, (0xf9f7:16)
	jr	nz, AudioInit_Routing_NoSplitCheckAux
	ld	(0xc168:16), 2
AudioInit_Routing_NoSplitCheckAux:
	bit	5, (0xfbb1:16)
	jrl	nz, AudioInit_Routing_Done
	ld	(0xc17c:16), 22
	jrl	AudioInit_Routing_Done
AudioInit_Routing_CheckTypeEDFlags:
	ld	wa, (0xc4fc:16)
	and	wa, 0x60
	jr	nz, AudioInit_Routing_TypeED_Override
	bit	5, (0xf9f7:16)
	jr	nz, AudioInit_Routing_TypeED_CheckAux
	ld	(0xc168:16), 2
AudioInit_Routing_TypeED_CheckAux:
	bit	5, (0xfbb1:16)
	jrl	nz, AudioInit_Routing_Done
	ld	(0xc17c:16), 22
	jrl	AudioInit_Routing_Done
AudioInit_Routing_TypeED_Override:
	orw	(0xc4fa:16), 256
	jrl	AudioInit_Routing_Done
AudioInit_Routing_NoGroupAB:
	bit	5, (0xf9f7:16)
	jr	nz, AudioInit_Routing_SimpleAssign
	ld	(0xc168:16), 2
AudioInit_Routing_SimpleAssign:
	ld	(0xc21e:16), 21
	ld	(0xc21f:16), 22
	ld	(0xc17b:16), 255
	ld	(0xc17c:16), 255
	cp	(3431:16), 4
	jr	z, AudioInit_Routing_AllDisabled
	ld	wa, (0xc4fc:16)
	and	wa, 0x22
	cp	wa, 0x20
	jr	nz, AudioInit_Routing_CheckMixMode
AudioInit_Routing_AllDisabled:
	ld	(0xc21e:16), 255
	ld	(0xc21f:16), 255
	jrl	AudioInit_Routing_Done
AudioInit_Routing_CheckMixMode:
	ld	wa, (0xc4fa:16)
	bit	9, wa
	jrl	nz, AudioInit_Routing_Done
	bit	1, (0xfc5f:16)
	jr	nz, AudioInit_Routing_Done
	ld	a, (0xfc5f:16)
	and	a, 0xfc
	jr	nz, AudioInit_Routing_MixFCBits
	ld	a, (0xfc60:16)
	and	a, 0xfc
	jr	nz, AudioInit_Routing_MixFCBits
	bit	5, (0xfbe5:16)
	jr	nz, AudioInit_Routing_MixCheckAux
	ld	(0xc17b:16), 21
AudioInit_Routing_MixCheckAux:
	bit	5, (0xfbb1:16)
	jr	nz, AudioInit_Routing_Done
	ld	(0xc17c:16), 22
	jr	AudioInit_Routing_Done
AudioInit_Routing_MixFCBits:
	ld	wa, (0xc4fc:16)
	and	wa, 0x60
	jr	nz, AudioInit_Routing_Done
	bit	5, (0xfbe5:16)
	jr	nz, AudioInit_Routing_MixFCCheckAux
	ld	(0xc17b:16), 21
AudioInit_Routing_MixFCCheckAux:
	bit	5, (0xfbb1:16)
	jr	nz, AudioInit_Routing_Done
	ld	(0xc17c:16), 22
AudioInit_Routing_SkipToEnd:
	jr	AudioInit_Routing_Done
AudioInit_Routing_NoActiveVoices:
	ld	wa, (0xc4fa:16)
	bit	2, wa
	jr	z, AudioInit_Routing_FullDisable
	ld	(0xc21e:16), 21
	ld	(0xc21f:16), 22
	ld	(0xc17b:16), 255
	ld	(0xc17c:16), 255
	jr	AudioInit_Routing_Done
AudioInit_Routing_FullDisable:
	ld	(0xc21e:16), 255
	ld	(0xc21f:16), 255
	ld	(0xc17b:16), 255
	ld	(0xc17c:16), 255
AudioInit_Routing_Done:
	orw	(0xc500:16), 260
	ret
AudioInit_ConfigurePanning:
	ld	wa, (0xc4fa:16)
	and	wa, 0x400
	cp	wa, 0x400
	ret	nz
	ld	wa, (0xc4fa:16)
	bit	2, wa
	ret	nz
	.byte 0xc1, 0x63, 0xc1, 0x3f, 0xff
	jr	nz, AudioInit_Pan_CheckMode0
	bit	0, (0xc162:16)
	jr	nz, AudioInit_Pan_SetStereoLeft
AudioInit_Pan_CheckMode0:
	cp	(0xc163:16), 0
	jr	nz, AudioInit_Pan_CheckMode1
AudioInit_Pan_SetStereoLeft:
	ld	(0xc218:16), 0
	jr	AudioInit_Pan_CheckReverbChannel
AudioInit_Pan_CheckMode1:
	.byte 0xc1, 0x63, 0xc1, 0x3f, 0xff
	jr	nz, AudioInit_Pan_CheckMode1b
	bit	1, (0xc162:16)
	jr	nz, AudioInit_Pan_SetStereoRight
AudioInit_Pan_CheckMode1b:
	cp	(0xc163:16), 1
	jr	nz, AudioInit_Pan_CheckTypeED
AudioInit_Pan_SetStereoRight:
	ld	(0xc218:16), 1
	jr	AudioInit_Pan_CheckReverbChannel
AudioInit_Pan_CheckTypeED:
	ld	wa, (0xc4fc:16)
	and	wa, 0x60
	jr	z, AudioInit_Pan_DefaultCenter
	ld	a, (0xfc66:16)
	and	a, 0x3
	cp	a, 2:i3
	jr	nz, AudioInit_Pan_TypeED_Left
	ld	(0xc218:16), 1
	jr	AudioInit_Pan_CheckReverbChannel
AudioInit_Pan_TypeED_Left:
	ld	(0xc218:16), 0
	jr	AudioInit_Pan_CheckReverbChannel
AudioInit_Pan_DefaultCenter:
	ld	(0xc218:16), 255
AudioInit_Pan_CheckReverbChannel:
	cp	(0xe8fa:16), 14
	jr	ule, AudioInit_Pan_Reverb_CopyFromMain
	.byte 0xc1, 0x63, 0xc1, 0x3f, 0xff
	jr	nz, AudioInit_Pan_Reverb_CheckMode0
	bit	0, (0xc162:16)
	jr	nz, AudioInit_Pan_Reverb_Left
AudioInit_Pan_Reverb_CheckMode0:
	cp	(0xc163:16), 0
	jr	nz, AudioInit_Pan_Reverb_CheckMode1
AudioInit_Pan_Reverb_Left:
	ld	(0xc220:16), 0
	jr	AudioInit_Pan_Done
AudioInit_Pan_Reverb_CheckMode1:
	.byte 0xc1, 0x63, 0xc1, 0x3f, 0xff
	jr	nz, AudioInit_Pan_Reverb_CheckMode1b
	bit	1, (0xc162:16)
	jr	nz, AudioInit_Pan_Reverb_Right
AudioInit_Pan_Reverb_CheckMode1b:
	cp	(0xc163:16), 1
	jr	nz, AudioInit_Pan_Reverb_CheckTypeED
AudioInit_Pan_Reverb_Right:
	ld	(0xc220:16), 1
	jr	AudioInit_Pan_Done
AudioInit_Pan_Reverb_CheckTypeED:
	ld	wa, (0xc4fc:16)
	and	wa, 0x60
	jr	z, AudioInit_Pan_Reverb_Center
	ld	a, (0xfc66:16)
	and	a, 0x3
	cp	a, 2:i3
	jr	nz, AudioInit_Pan_Reverb_TypeED_Left
	ld	(0xc220:16), 1
	jr	AudioInit_Pan_Done
AudioInit_Pan_Reverb_TypeED_Left:
	ld	(0xc220:16), 0
	jr	AudioInit_Pan_Done
AudioInit_Pan_Reverb_Center:
	ld	(0xc220:16), 255
	jr	AudioInit_Pan_Done
AudioInit_Pan_Reverb_CopyFromMain:
	ldmm8	0xc220, 0xe8fa
AudioInit_Pan_Done:
	orw	(0xc500:16), 256
	ret
AudioInit_CheckStereoMode:
	ld	wa, (0xc4fa:16)
	bit	11, wa
	ret	z
	bit	0, (0xc162:16)
	jr	z, AudioInit_Stereo_CheckBit1
	.byte 0xf1, 0x64, 0xc1, 0x00, 0x00
	jr	AudioInit_Stereo_CheckBit3
AudioInit_Stereo_CheckBit1:
	bit	1, (0xc162:16)
	jr	z, AudioInit_Stereo_Default
	ld	(0xc164:16), 1
	jr	AudioInit_Stereo_CheckBit3
AudioInit_Stereo_Default:
	ld	(0xc164:16), 255
AudioInit_Stereo_CheckBit3:
	bit	3, (0xc162:16)
	ret	z
	ld	(0xc165:16), 0
	ret
AudioInit_DispatchChanges:
	ldw	(0xc42e:16), 0
	ld	wa, (0xc500:16)
	and	wa, 0x188
	call	nz, (AudioInit_ComparePartStates:24)
	ld	wa, (0xc500:16)
	and	wa, 0x1c0
	call	nz, (AudioInit_CompareChannelMappings:24)
	ld	wa, (0xc500:16)
	and	wa, 0x102
	jr	z, AudioInit_Dispatch_CheckVoiceChange
	calr	AudioInit_CompareVoiceConfig
	jr	AudioInit_Dispatch_CheckPartChange
AudioInit_Dispatch_CheckVoiceChange:
	ld	wa, (0xc500:16)
	bit	0, wa
	jr	nz, AudioInit_Dispatch_SendVoiceChange
	ld	wa, (0xc4fe:16)
	bit	9, wa
	jr	z, AudioInit_Dispatch_CheckPartChange
AudioInit_Dispatch_SendVoiceChange:
	calr	AudioInit_CompareVoiceConfig
AudioInit_Dispatch_CheckPartChange:
	ld	wa, (0xc500:16)
	bit	8, wa
	jr	nz, AudioInit_Dispatch_SendPartChange
	ld	wa, (0xc4fe:16)
	and	wa, 0x7000
	jr	z, AudioInit_Dispatch_CheckMisc
AudioInit_Dispatch_SendPartChange:
	calr	AudioInit_ComparePriorityTable
AudioInit_Dispatch_CheckMisc:
	ld	wa, (0xc500:16)
	bit	2, wa
	call	nz, (AudioInit_ComparePartAssignment:24)
	ld	wa, (0xc500:16)
	bit	3, wa
	call	nz, (AudioInit_ComparePartConfig:24)
	ld	wa, (0xc500:16)
	bit	6, wa
	call	nz, (AudioInit_CompareChannelConfig:24)
	ld	wa, (0xc500:16)
	bit	4, wa
	call	nz, (AudioInit_CompareVolumeTable:24)
	ld	wa, (0xc4fe:16)
	bit	13, wa
	jr	z, AudioInit_Dispatch_CheckToneRefresh
	ld	wa, (0xc4fa:16)
	bit	4, wa
	jr	z, AudioInit_Dispatch_RefreshTone
AudioInit_Dispatch_CheckToneRefresh:
	ld	wa, (0xc4fe:16)
	bit	12, wa
	jr	z, AudioInit_Dispatch_CheckVoiceAssign
AudioInit_Dispatch_RefreshTone:
	call	Voice_UpdatePlayModeState
	cp	l, 0xff
	call	nz, (VoiceEvent_AllocAllLayers:24)
AudioInit_Dispatch_CheckVoiceAssign:
	ld	wa, (0xc4fe:16)
	bit	14, wa
	jr	z, AudioInit_Dispatch_Finalize
	call	NoteMap_FindBestMatch
	cp	l, 0xff
	call	nz, (VoiceEvent_DispatchTable:24)
AudioInit_Dispatch_Finalize:
	call	VoiceEvent_HandlerTable
	ld	xiy, 0xc162
	ld	xix, 0xc2c8
	ldw	bc, 0xb3
	ldirw
	ldw	(0xc500:16), 0
	ldw	(0xc4fe:16), 0
	ret
AudioInit_QueueCommand:
	dec	6, xsp
	ld	(xsp), e
	ld	(xsp + 2), c
	ld	(xsp + 4), a
	cpw	(0xc42e:16), 49
	jr	c, AudioInit_QueueCommand_Write
	call	VoiceEvent_HandlerTable
	ldw	(0xc42e:16), 0
AudioInit_QueueCommand_Write:
	ld	wa, (0xc42e:16)
	sll	wa, 2
	lda	xbc, (0xc430:16)
	ld	de, wa
	extz	xde
	add	xde, xbc
	ld	a, (xsp + 4)
	ld	(xde), a
	ld	wa, (0xc42e:16)
	sll	wa, 2
	lda	xbc, (0xc431:16)
	ld	de, wa
	extz	xde
	add	xde, xbc
	ld	a, (xsp + 2)
	ld	(xde), a
	ld	wa, (0xc42e:16)
	sll	wa, 2
	lda	xbc, (0xc432:16)
	ld	de, wa
	extz	xde
	add	xde, xbc
	ld	a, (xsp)
	ld	(xde), a
	ld	wa, (0xc42e:16)
	sll	wa, 2
	lda	xbc, (0xc433:16)
	ld	de, wa
	extz	xde
	add	xde, xbc
	ld	a, (xsp + 10)
	ld	(xde), a
	incw	1, (0xc42e:16)
	inc	6, xsp
	retd	0x2
AudioInit_ComparePartStates:
	pushw	iz
	ld	wa, (0xc500:16)
	bit	3, wa
	jrl	z, AudioInit_ComparePanState
	ld	iz, 0:i3
	cp	iz, 0x1a
	jrl	nc, AudioInit_PartCompare_CheckGlobalBits
AudioInit_PartCompare_Loop:
	ld	wa, iz
	lda	xbc, (0xc186:16)
	ld	de, wa
	extz	xde
	add	xde, xbc
	ld	wa, iz
	lda	xbc, (0xc2ec:16)
	extz	xwa
	add	xwa, xbc
	ld	a, (xwa)
	cp	a, (xde)
	jr	z, AudioInit_PartCompare_SameVoice
	stb_erp	A, 0xf8
	ld	l, a
	extz	hl
	ld	wa, iz
	lda	xbc, (0xc186:16)
	extz	xwa
	add	xwa, xbc
	ld	a, (xwa)
	ld	e, a
	extz	de
	ld	wa, iz
	lda	xbc, (0xc2ec:16)
	extz	xwa
	add	xwa, xbc
	ld	a, (xwa)
	extz	wa
	pushw	wa
	ld	bc, hl
	ld	wa, 0:i3
	calr	AudioInit_QueueCommand
	jr	AudioInit_PartCompare_Next
AudioInit_PartCompare_SameVoice:
	ld	wa, iz
	lda	xbc, (0xc186:16)
	extz	xwa
	add	xwa, xbc
	cp	(xwa), 0xff
	jr	z, AudioInit_PartCompare_Next
	ld	wa, iz
	add	wa, wa
	lda	xbc, (0xc3ec:16)
	extz	xwa
	add	xwa, xbc
	ldcfm	6, (xwa)
	scc8	c, e
	ld	wa, iz
	add	wa, wa
	lda	xbc, (0xc286:16)
	extz	xwa
	add	xwa, xbc
	ldcfm	6, (xwa)
	scc8	c, a
	cp	a, e
	jr	z, AudioInit_PartCompare_Next
	stb_erp	A, 0xf8
	ld	e, a
	extz	de
	ld	wa, iz
	lda	xbc, (0xc186:16)
	extz	xwa
	add	xwa, xbc
	ld	a, (xwa)
	extz	wa
	pushw	wa
	ld	bc, de
	ld	wa, 0:i3
	ldw	de, 0xff
	calr	AudioInit_QueueCommand
AudioInit_PartCompare_Next:
	inc	1, iz
	cp	iz, 0x1a
	jrl	c, AudioInit_PartCompare_Loop
AudioInit_PartCompare_CheckGlobalBits:
	ldcf_dd16	4, 0xec, 0xc3
	scc8	c, a
	ldcf_dd16	4, 0x86, 0xc2
	scc8	c, c
	cp	c, a
	jr	z, AudioInit_ComparePanState
	ld	a, (0xc186:16)
	extz	wa
	pushw	wa
	ld	wa, 0:i3
	ld	bc, 0:i3
	ldw	de, 0xff
	calr	AudioInit_QueueCommand
AudioInit_ComparePanState:
	ld	wa, (0xc500:16)
	bit	8, wa
	jr	z, AudioInit_PartCompare_Return
	ld	a, (0xc37e:16)
	cp	a, (0xc218:16)
	jr	z, AudioInit_PartCompare_Return
	ld	a, (0xc218:16)
	ld	c, a
	extz	bc
	ld	a, (0xc37e:16)
	extz	wa
	pushw	wa
	ld	de, bc
	ld	wa, 1:i3
	ld	bc, 0:i3
	calr	AudioInit_QueueCommand
AudioInit_PartCompare_Return:
	popw	iz
	ret
AudioInit_CompareVoiceConfig:
	ld	e, 0x0:opc
	ld	l, 0x0:opc
	ld	d, 0x1:opc
	ld	wa, (0xc500:16)
	bit	1, wa
	jr	z, AudioInit_VoiceCompare_BothFF
	ld	a, (0xc2c9:16)
	cp	a, (0xc163:16)
	jr	z, AudioInit_VoiceCompare_BothFF
	ld	a, (0xc163:16)
	ld	c, a
	extz	bc
	ld	a, (0xc2c9:16)
	extz	wa
	pushw	wa
	ld	de, bc
	ld	wa, 2:i3
	ld	bc, 1:i3
	calr	AudioInit_QueueCommand
	bit	3, (0xc2c8:16)
	ret	z
	bit	3, (0xc162:16)
	ret	nz
	pushw	0x8
	ld	wa, 2:i3
	ld	bc, 0:i3
	ld	de, 0:i3
	calr	AudioInit_QueueCommand
	ret
AudioInit_VoiceCompare_BothFF:
	.byte 0xc1, 0x63, 0xc1, 0x3f, 0xff
	jrl	nz, AudioInit_VoiceCompare_NotBothFF
	cp	(0xc2c9:16), 255
	jrl	nz, AudioInit_VoiceCompare_NotBothFF
	ld	a, (0xc2c8:16)
	xor	a, (0xc162:16)
	ld	c, a
	ld	a, (0xc162:16)
	and	a, c
	ld	e, a
	ld	a, (0xc2c8:16)
	xor	a, (0xc162:16)
	ld	c, a
	ld	a, (0xc2c8:16)
	and	a, c
	ld	l, a
	ld	ix, 0:i3
	cp	ix, 6:i3
	jrl	nc, AudioInit_VoiceCompare_BuildCmd
AudioInit_VoiceCompare_LayerLoop:
	ld	wa, ix
	sll	wa, 2
	lda	xbc, (0xc226:16)
	extz	xwa
	add	xwa, xbc
	bitm	7, (xwa)
	jr	z, AudioInit_VoiceCompare_LayerNext
	ld	wa, ix
	sll	wa, 2
	lda	xbc, (0xc38c:16)
	extz	xwa
	add	xwa, xbc
	ld	h, (xwa)
	res	7, h
	ld	wa, ix
	sll	wa, 2
	lda	xbc, (0xc226:16)
	extz	xwa
	add	xwa, xbc
	ld	a, (xwa)
	res	7, a
	cp	a, h
	jr	nz, AudioInit_VoiceCompare_LayerChanged
	ld	wa, ix
	sll	wa, 2
	add	wa, 0xc4
	lda	xbc, (0xc2c9:16)
	extz	xwa
	add	xwa, xbc
	ld	h, (xwa)
	srl	h, 1
	ld	wa, ix
	sll	wa, 2
	add	wa, 0xc4
	lda	xbc, (0xc163:16)
	extz	xwa
	add	xwa, xbc
	ld	a, (xwa)
	srl	a, 1
	cp	a, h
	jr	z, AudioInit_VoiceCompare_LayerNext
AudioInit_VoiceCompare_LayerChanged:
	ld	a, (0xc162:16)
	and	a, (0xc2c8:16)
	and	a, d
	jr	z, AudioInit_VoiceCompare_LayerNext
	or	e, d
	or	l, d
AudioInit_VoiceCompare_LayerNext:
	add	d, d
	inc	1, ix
	cp	ix, 6:i3
	jrl	c, AudioInit_VoiceCompare_LayerLoop
	jr	AudioInit_VoiceCompare_BuildCmd
AudioInit_VoiceCompare_NotBothFF:
	.byte 0xc1, 0x63, 0xc1, 0x3f, 0xff
	jr	z, AudioInit_VoiceCompare_BuildCmd
	cp	(0xc2c9:16), 255
	jr	z, AudioInit_VoiceCompare_BuildCmd
	ld	a, (0xc2c8:16)
	xor	a, (0xc162:16)
	ld	c, a
	ld	a, (0xc162:16)
	and	a, c
	and	a, 0xf8
	ld	e, a
	ld	a, (0xc2c8:16)
	xor	a, (0xc162:16)
	ld	c, a
	ld	a, (0xc2c8:16)
	and	a, c
	and	a, 0xf8
	ld	l, a
	bit	7, (0xc232:16)
	jr	z, AudioInit_VoiceCompare_BuildCmd
	ld	a, (0xc398:16)
	res	7, a
	ld	c, (0xc232:16)
	res	7, c
	cp	c, a
	jr	nz, AudioInit_VoiceCompare_SetBit3
	ld	a, (0xc399:16)
	srl	a, 1
	ld	c, (0xc233:16)
	srl	c, 1
	cp	c, a
	jr	z, AudioInit_VoiceCompare_BuildCmd
AudioInit_VoiceCompare_SetBit3:
	set	3, e
	set	3, l
AudioInit_VoiceCompare_BuildCmd:
	cp	e, 0:i3
	jr	nz, AudioInit_VoiceCompare_QueueCmd
	cp	l, 0:i3
	jr	z, AudioInit_VoiceCompare_PanCheck
AudioInit_VoiceCompare_QueueCmd:
	ld	c, e
	extz	bc
	ld	a, l
	extz	wa
	pushw	wa
	ld	de, bc
	ld	wa, 2:i3
	ld	bc, 0:i3
	calr	AudioInit_QueueCommand
AudioInit_VoiceCompare_PanCheck:
	ld	a, (0xc37e:16)
	cp	a, (0xc218:16)
	ret	z
	ld	a, (0xc218:16)
	ld	c, a
	extz	bc
	ld	a, (0xc37e:16)
	extz	wa
	pushw	wa
	ld	de, bc
	ld	wa, 2:i3
	ld	bc, 2:i3
	calr	AudioInit_QueueCommand
	ret
AudioInit_CompareChannelMappings:
	pushw	iz
	ld	wa, (0xc500:16)
	and	wa, 0xc0
	jrl	z, AudioInit_ChannelMap_CheckPan
	ld	iz, 0:i3
	cp	iz, 0x10
	jrl	nc, AudioInit_ChannelMap_CheckPan
AudioInit_ChannelMap_Loop:
	ld	wa, iz
	lda	xbc, (0xc206:16)
	ld	de, wa
	extz	xde
	add	xde, xbc
	ld	wa, iz
	.byte 0xf1, 0x6c, 0xc3, 0x31
	extz	xwa
	add	xwa, xbc
	ld	a, (xwa)
	cp	a, (xde)
	jr	z, 45
	stb_erp	A, 0xf8
	ld	l, a
	extz	hl
	ld	wa, iz
	lda	xbc, (0xc206:16)
	extz	xwa
	add	xwa, xbc
	ld	a, (xwa)
	ld	e, a
	extz	de
	ld	wa, iz
	.byte 0xf1, 0x6c, 0xc3, 0x31, 0xe8, 0x12, 0xe9, 0x80
	.byte 0x80, 0x21, 0xd8, 0x12, 0x28, 0xdb, 0x89, 0xd8
	.byte 0xab, 0x1e, 0x6f, 0xfc, 0xde, 0x88, 0xf1, 0xe6
	.byte 0xc1, 0x31, 0xd8, 0x8a, 0xea, 0x12, 0xe9, 0x82
	.byte 0xde, 0x88, 0xf1, 0x4c, 0xc3, 0x31, 0xe8, 0x12
	.byte 0xe9, 0x80, 0x80, 0x21, 0x82, 0xf1, 0x66, 0x2d
	.byte 0xc7, 0xf8, 0x89, 0xc9, 0x8f, 0xdb, 0x12, 0xde
	.byte 0x88, 0xf1, 0xe6, 0xc1, 0x31, 0xe8, 0x12, 0xe9
	.byte 0x80, 0x80, 0x21, 0xc9, 0x8d, 0xda, 0x12, 0xde
	.byte 0x88, 0xf1, 0x4c, 0xc3, 0x31
	extz	xwa
	add	xwa, xbc
	ld	a, (xwa)
	extz	wa
	pushw	wa
	ld	bc, hl
	ld	wa, 4:i3
	calr	AudioInit_QueueCommand
AudioInit_ChannelMap_Next:
	inc	1, iz
	cp	iz, 0x10
	jrl	c, AudioInit_ChannelMap_Loop
AudioInit_ChannelMap_CheckPan:
	ld	wa, (0xc500:16)
	bit	8, wa
	jr	z, AudioInit_ChannelMap_Return
	ld	a, (0xc37e:16)
	cp	a, (0xc218:16)
	jr	z, AudioInit_ChannelMap_Return
	ld	a, (0xc218:16)
	ld	c, a
	extz	bc
	ld	a, (0xc37e:16)
	extz	wa
	pushw	wa
	ld	de, bc
	ld	wa, 5:i3
	ld	bc, 0:i3
	calr	AudioInit_QueueCommand
AudioInit_ChannelMap_Return:
	popw	iz
	ret
AudioInit_ComparePriorityTable:
	pushw	iz
	ld	iz, 0:i3
	cp	iz, 3:i3
	jr	nc, AudioInit_Priority_Return
AudioInit_Priority_Loop:
	ld	wa, iz
	lda	xbc, (0xc21e:16)
	ld	de, wa
	extz	xde
	add	xde, xbc
	ld	wa, iz
	lda	xbc, (0xc384:16)
	extz	xwa
	add	xwa, xbc
	ld	a, (xwa)
	cp	a, (xde)
	jr	z, AudioInit_Priority_Next
	stb_erp	A, 0xf8
	ld	l, a
	extz	hl
	ld	wa, iz
	lda	xbc, (0xc21e:16)
	extz	xwa
	add	xwa, xbc
	ld	a, (xwa)
	ld	e, a
	extz	de
	ld	wa, iz
	lda	xbc, (0xc384:16)
	extz	xwa
	add	xwa, xbc
	ld	a, (xwa)
	extz	wa
	pushw	wa
	ld	bc, hl
	ld	wa, 6:i3
	calr	AudioInit_QueueCommand
AudioInit_Priority_Next:
	inc	1, iz
	cp	iz, 3:i3
	jr	c, AudioInit_Priority_Loop
AudioInit_Priority_Return:
	popw	iz
	ret
AudioInit_ComparePartAssignment:
	pushw	iz
	ld	iz, 0:i3
	cp	iz, 0x1a
	jrl	nc, AudioInit_PartAssign_Return
AudioInit_PartAssign_Loop:
	ld	wa, iz
	lda	xbc, (0xc166:16)
	ld	de, wa
	extz	xde
	add	xde, xbc
	ld	wa, iz
	lda	xbc, (0xc2cc:16)
	extz	xwa
	add	xwa, xbc
	ld	a, (xwa)
	cp	a, (xde)
	jrl	z, AudioInit_PartAssign_Next
	cp	iz, 2:i3
	jr	nz, AudioInit_PartAssign_CheckIdx15
	ld	wa, iz
	lda	xbc, (0xc166:16)
	extz	xwa
	add	xwa, xbc
	cp	(xwa), 0xff
	jr	z, AudioInit_PartAssign_CheckIdx15
	cp	(0xc21e:16), 2
	jr	nz, AudioInit_PartAssign_CheckIdx15
	cp	(0xc384:16), 2
	jr	nz, AudioInit_PartAssign_Next
AudioInit_PartAssign_CheckIdx15:
	cp	iz, 0x15
	jr	nz, AudioInit_PartAssign_CheckIdx16
	ld	wa, iz
	lda	xbc, (0xc166:16)
	extz	xwa
	add	xwa, xbc
	cp	(xwa), 0xff
	jr	z, AudioInit_PartAssign_CheckIdx16
	cp	(0xc21e:16), 21
	jr	nz, AudioInit_PartAssign_CheckIdx16
	cp	(0xc384:16), 21
	jr	nz, AudioInit_PartAssign_Next
AudioInit_PartAssign_CheckIdx16:
	cp	iz, 0x16
	jr	nz, AudioInit_PartAssign_QueueChange
	ld	wa, iz
	lda	xbc, (0xc166:16)
	extz	xwa
	add	xwa, xbc
	cp	(xwa), 0xff
	jr	z, AudioInit_PartAssign_QueueChange
	cp	(0xc21f:16), 22
	jr	nz, AudioInit_PartAssign_QueueChange
	cp	(0xc385:16), 22
	jr	nz, AudioInit_PartAssign_Next
AudioInit_PartAssign_QueueChange:
	stb_erp	A, 0xf8
	ld	l, a
	extz	hl
	ld	wa, iz
	lda	xbc, (0xc166:16)
	extz	xwa
	add	xwa, xbc
	ld	a, (xwa)
	ld	e, a
	extz	de
	ld	wa, iz
	lda	xbc, (0xc2cc:16)
	extz	xwa
	add	xwa, xbc
	ld	a, (xwa)
	extz	wa
	pushw	wa
	ld	bc, hl
	ld	wa, 7:i3
	calr	AudioInit_QueueCommand
AudioInit_PartAssign_Next:
	inc	1, iz
	cp	iz, 0x1a
	jrl	c, AudioInit_PartAssign_Loop
AudioInit_PartAssign_Return:
	popw	iz
	ret
AudioInit_ComparePartConfig:
	pushw	iz
	ld	iz, 0:i3
	cp	iz, 0x1a
	jrl	nc, AudioInit_PartConfig_Return
AudioInit_PartConfig_Loop:
	ld	wa, iz
	lda	xbc, (0xc186:16)
	ld	de, wa
	extz	xde
	add	xde, xbc
	ld	wa, iz
	lda	xbc, (0xc2ec:16)
	extz	xwa
	add	xwa, xbc
	ld	a, (xwa)
	cp	a, (xde)
	jr	z, AudioInit_PartConfig_SameVoice
	stb_erp	A, 0xf8
	ld	l, a
	extz	hl
	ld	wa, iz
	lda	xbc, (0xc186:16)
	extz	xwa
	add	xwa, xbc
	ld	a, (xwa)
	ld	e, a
	extz	de
	ld	wa, iz
	lda	xbc, (0xc2ec:16)
	extz	xwa
	add	xwa, xbc
	ld	a, (xwa)
	extz	wa
	pushw	wa
	ld	bc, hl
	ldw	wa, 0x8
	calr	AudioInit_QueueCommand
	jrl	AudioInit_PartConfig_Next
AudioInit_PartConfig_SameVoice:
	cp	iz, 0x19
	jr	nz, AudioInit_PartConfig_NotReverb
	ld	a, (0xc220:16)
	extz	wa
	lda	xbc, (0xc186:16)
	extz	xwa
	add	xwa, xbc
	cp	(xwa), 0xff
	jrl	z, AudioInit_PartConfig_Next
	ld	wa, iz
	add	wa, wa
	lda	xbc, (0xc3ec:16)
	extz	xwa
	add	xwa, xbc
	ldcfm	5, (xwa)
	scc8	c, e
	ld	wa, iz
	add	wa, wa
	lda	xbc, (0xc286:16)
	extz	xwa
	add	xwa, xbc
	ldcfm	5, (xwa)
	scc8	c, a
	cp	a, e
	jr	z, AudioInit_PartConfig_Next
	stb_erp	A, 0xf8
	ld	e, a
	extz	de
	ld	a, (0xc220:16)
	extz	wa
	lda	xbc, (0xc186:16)
	extz	xwa
	add	xwa, xbc
	ld	a, (xwa)
	extz	wa
	pushw	wa
	ld	bc, de
	ldw	wa, 0x8
	ldw	de, 0xff
	calr	AudioInit_QueueCommand
	jr	AudioInit_PartConfig_Next
AudioInit_PartConfig_NotReverb:
	ld	wa, iz
	lda	xbc, (0xc186:16)
	extz	xwa
	add	xwa, xbc
	cp	(xwa), 0xff
	jr	z, AudioInit_PartConfig_Next
AudioInit_PartConfig_CheckCarry:
	ld	wa, iz
	add	wa, wa
	lda	xbc, (0xc3ec:16)
	extz	xwa
	add	xwa, xbc
	ldcfm	5, (xwa)
	scc8	c, e
	ld	wa, iz
	add	wa, wa
	lda	xbc, (0xc286:16)
	extz	xwa
	add	xwa, xbc
	ldcfm	5, (xwa)
	scc8	c, a
	cp	a, e
	jr	z, AudioInit_PartConfig_Next
	stb_erp	A, 0xf8
	ld	e, a
	extz	de
	ld	wa, iz
	lda	xbc, (0xc186:16)
	extz	xwa
	add	xwa, xbc
	ld	a, (xwa)
	extz	wa
	pushw	wa
	ld	bc, de
	ldw	wa, 0x8
	ldw	de, 0xff
	calr	AudioInit_QueueCommand
AudioInit_PartConfig_Next:
	inc	1, iz
	cp	iz, 0x1a
	jrl	c, AudioInit_PartConfig_Loop
AudioInit_PartConfig_Return:
	popw	iz
	ret
AudioInit_CompareChannelConfig:
	pushw	iz
	ld	iz, 0:i3
	cp	iz, 0x10
	jr	nc, AudioInit_ChannelConfig_Return
AudioInit_ChannelConfig_Loop:
	ld	wa, iz
	lda	xbc, (0xc1e6:16)
	ld	de, wa
	extz	xde
	add	xde, xbc
	ld	wa, iz
	lda	xbc, (0xc34c:16)
	extz	xwa
	add	xwa, xbc
	ld	a, (xwa)
	cp	a, (xde)
	jr	z, AudioInit_ChannelConfig_Next
	stb_erp	A, 0xf8
	ld	l, a
	extz	hl
	ld	wa, iz
	lda	xbc, (0xc1e6:16)
	extz	xwa
	add	xwa, xbc
	ld	a, (xwa)
	ld	e, a
	extz	de
	ld	wa, iz
	lda	xbc, (0xc34c:16)
	extz	xwa
	add	xwa, xbc
	ld	a, (xwa)
	extz	wa
	pushw	wa
	ld	bc, hl
	ldw	wa, 0x9
	calr	AudioInit_QueueCommand
AudioInit_ChannelConfig_Next:
	inc	1, iz
	cp	iz, 0x10
	jr	c, AudioInit_ChannelConfig_Loop
AudioInit_ChannelConfig_Return:
	popw	iz
	ret
AudioInit_CompareVolumeTable:
	pushw	iz
	ld	iz, 0:i3
	cp	iz, 0x1a
	jr	nc, AudioInit_Volume_Return
AudioInit_Volume_Loop:
	ld	wa, iz
	lda	xbc, (0xc1a6:16)
	ld	de, wa
	extz	xde
	add	xde, xbc
	ld	wa, iz
	lda	xbc, (0xc30c:16)
	extz	xwa
	add	xwa, xbc
	ld	a, (xwa)
	cp	a, (xde)
	jr	z, AudioInit_Volume_Next
	stb_erp	A, 0xf8
	ld	l, a
	extz	hl
	ld	wa, iz
	lda	xbc, (0xc1a6:16)
	extz	xwa
	add	xwa, xbc
	ld	a, (xwa)
	ld	e, a
	extz	de
	ld	wa, iz
	lda	xbc, (0xc30c:16)
	extz	xwa
	add	xwa, xbc
	ld	a, (xwa)
	extz	wa
	pushw	wa
	ld	bc, hl
	ldw	wa, 0xa
	calr	AudioInit_QueueCommand
AudioInit_Volume_Next:
	inc	1, iz
	cp	iz, 0x1a
	jr	c, AudioInit_Volume_Loop
AudioInit_Volume_Return:
	popw	iz
	ret
AudioInit_InitPartSendLevels:
	ld	de, 0:i3
	cp	de, 161
	jr	nc, AudioInit_PartConfig_CheckCarry_Skip
AudioInit_PartConfig_CheckCarry_Loop:
	ld	wa, de
	add	wa, wa
	lda	xbc, (0xc58e:16)
	extz	xwa
	add	xwa, xbc
	ld	(xwa), 16
	ld	wa, de
	add	wa, wa
	lda	xbc, (0xc58f:16)
	extz	xwa
	add	xwa, xbc
	ld	(xwa), 0
	inc	1, de
	cp	de, 161
	jr	c, AudioInit_PartConfig_CheckCarry_Loop
AudioInit_PartConfig_CheckCarry_Skip:
	ld	(0xc9ce:16), 8
	ld	(0xc9cf:16), 0
	ld	(0xc9d0:16), 8
	ld	(0xc9d1:16), 0
	ld	(0xc9d2:16), 16
	ld	(0xc9d3:16), 0
	ret
