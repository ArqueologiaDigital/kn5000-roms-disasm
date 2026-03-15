; =============================================================================
; Audio Initialization
; =============================================================================
;
; Audio subsystem initialization and stereo voice configuration.
; Called during system boot to set up voice slots, output routing,
; and default sound parameters.
; =============================================================================

AudioInit_ConfigStereoVoice:
	ldda8 a, 36154
	extz wa
	lda_24 xbc, 0xee8e62
	extz xwa
	add xwa, xbc
	cp (xwa), 0x3
	jrl c, AudioInit_VoiceNotConfigured
	ldda8 a, 36154
	extz wa
	lda_24 xbc, 0xee8e62
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	stda8 49663, a
	cp a, 0xFF
	jr z, AudioInit_VoiceNotConfigured
	ordi16 50588, 2
	ldda16 xwa, 50584
	and wa, 0x6
	jr nz, AudioInit_CheckVoiceMixFlags
	ldda16 xwa, 50584
	and wa, 0x60
	jr nz, AudioInit_SetDefaultLevels

AudioInit_CheckVoiceMixFlags:
	ldda16 xwa, 50582
	and wa, 0x7
	jr z, AudioInit_SetDefaultLevels
	ldda16 xwa, 50580
	bit 4, wa
	jr nz, AudioInit_ClearModeRegister
	setda 3, 49662
	jr AudioInit_AfterModeSet

AudioInit_ClearModeRegister:
	stdi8 49662, 0

AudioInit_AfterModeSet:
	ordi16 50588, 1

AudioInit_SetDefaultLevels:
	stdi8 49850, 255
	stdi8 49851, 255
	bitda 5, 63991
	jr nz, AudioInit_CheckBit5_FD07
	stdi8 49668, 2

AudioInit_CheckBit5_FD07:
	bitda 5, 64433
	jr nz, AudioInit_CheckBit5_FBF1
	stdi8 49688, 22

AudioInit_CheckBit5_FBF1:
	ordi16 50588, 260
	jp AudioInit_ConfigurePanning

AudioInit_VoiceNotConfigured:
	stdi8 49663, 255
	ordi16 50588, 3
	ldda16 xwa, 50584
	and wa, 0x6
	jr nz, AudioInit_CheckMixFlagsAlt
	ldda16 xwa, 50584
	and wa, 0x60
	jr nz, AudioInit_RouteAndPan

AudioInit_CheckMixFlagsAlt:
	ldda16 xwa, 50582
	and wa, 0x7
	jr nz, AudioInit_CheckBit2Mode
	bitda 2, 49662
	jr z, AudioInit_RouteAndPan

AudioInit_CheckBit2Mode:
	ldda16 xwa, 50580
	bit 4, wa
	jr nz, AudioInit_ClearModeAlt
	setda 3, 49662
	jr AudioInit_AfterModeSetAlt

AudioInit_ClearModeAlt:
	stdi8 49662, 0

AudioInit_AfterModeSetAlt:
	ordi16 50588, 1

AudioInit_RouteAndPan:
	call AudioInit_ConfigureVoiceRouting
	call AudioInit_ConfigurePanning
	jp AudioInit_CheckStereoMode

AudioInit_ConfigureVoiceFromFlags:
	ldda16 xbc, 50584
	bit 0, bc
	jr z, AudioInit_FallbackToStereo
	ldmm8 49663, 50590
	ordi16 50588, 2
	ldda16 xwa, 50584
	and wa, 0x6E
	jr z, AudioInit_VoiceRouteJump
	ldda16 xwa, 50584
	and wa, 0xE
	jr z, AudioInit_VoiceRouteJump
	ldda16 xwa, 50580
	bit 4, wa
	jr nz, AudioInit_ClearModeFromFlags
	setda 3, 49662
	jr AudioInit_VoiceRouteJump

AudioInit_ClearModeFromFlags:
	stdi8 49662, 0

AudioInit_VoiceRouteJump:
	call AudioInit_ConfigureVoiceRouting
	jp AudioInit_ConfigurePanning

AudioInit_FallbackToStereo:
	extz wa
	jrl AudioInit_ConfigStereoVoice

AudioInit_SelectVoiceByType:
	ldda8 a, 14235
	cp a, 0x60
	jr z, AudioInit_StereoVoiceCfg
	cp a, 0x10
	jr z, AudioInit_StereoVoiceCfg
	cp a, 0x8
	jr z, AudioInit_SetVoice19
	cps a, 4
	jr z, AudioInit_SetVoice18
	cps a, 2
	jr z, AudioInit_SetVoice17
	cps a, 1
	jr nz, AudioInit_StereoVoiceCfg
	stdi8 49663, 16
	ordi16 50588, 2
	ret

AudioInit_SetVoice17:
	stdi8 49663, 17
	ordi16 50588, 2
	ret

AudioInit_SetVoice18:
	stdi8 49663, 18
	ordi16 50588, 2
	ret

AudioInit_SetVoice19:
	stdi8 49663, 19
	ordi16 50588, 2
	ret

AudioInit_StereoVoiceCfg:
	stdi8 49663, 20
	ordi16 50588, 2
	ret

AudioInit_PushAndConfigVoice:
	dec 2, xsp
	ld (xsp), a
	cp (xsp), 0x1
	call_24 z, 0xFDF5F5
	ordi16 50580, 2
	ld a, (xsp)
	extz wa
	calr AudioInit_ConfigStereoVoice
	inc 2, xsp
	ret

AudioInit_PushAndConfigVoiceAlt:
	dec 2, xsp
	ld (xsp), a
	cp (xsp), 0x1
	call_24 z, 0xFDF5F5
	ldda8 a, 36150
	cp a, 0xC9
	jr nz, AudioInit_LoadStackAndConfig
	stdi8 49663, 23
	ordi16 50588, 2
	jr AudioInit_RestoreStack

AudioInit_LoadStackAndConfig:
	ld a, (xsp)
	extz wa
	calr AudioInit_ConfigStereoVoice

AudioInit_RestoreStack:
	inc 2, xsp
	ret

AudioInit_CheckSoundGroup:
	cpdi8 36150, 3
	jr z, AudioInit_LoadGroupVoice
	cpdi8 36150, 8
	jr nz, AudioInit_GroupFallbackDefault

AudioInit_LoadGroupVoice:
	ldda8 c, 36154
	extz bc
	lda_24 xde, 0xee8e62
	ld_srib3 C, 0x07, 0xE8, 0xE4
	stda8 49663, c
	cp c, 0xFF
	jr z, AudioInit_GroupFallbackStereo
	ordi16 50588, 2
	ldda16 xwa, 50584
	and wa, 0x60
	jr nz, AudioInit_SetGroupLevels
	ldda16 xwa, 50582
	and wa, 0x7
	jr z, AudioInit_SetGroupLevels
	ldda16 xwa, 50580
	bit 4, wa
	jr nz, AudioInit_ClearGroupMode
	setda 3, 49662
	jr AudioInit_AfterGroupModeSet

AudioInit_ClearGroupMode:
	stdi8 49662, 0

AudioInit_AfterGroupModeSet:
	ordi16 50588, 1

AudioInit_SetGroupLevels:
	stdi8 49850, 255
	stdi8 49851, 255
	bitda 5, 63991
	jr nz, AudioInit_CheckGroupBit5_FD07
	stdi8 49668, 2

AudioInit_CheckGroupBit5_FD07:
	bitda 5, 64433
	jr nz, AudioInit_CheckGroupBit5_FBF1
	stdi8 49688, 22

AudioInit_CheckGroupBit5_FBF1:
	ordi16 50588, 260
	jp AudioInit_ConfigurePanning

AudioInit_GroupFallbackStereo:
	extz wa
	jrl AudioInit_ConfigStereoVoice

AudioInit_GroupFallbackDefault:
	extz wa
	jrl AudioInit_ConfigStereoVoice

AudioInit_CheckSoundGroup51:
	cpdi8 36150, 81
	jr nz, AudioInit_G51FallbackDefault
	ldda8 c, 36154
	extz bc
	lda_24 xde, 0xee8e82
	ld_srib3 C, 0x07, 0xE8, 0xE4
	stda8 49663, c
	cp c, 0xFF
	jr z, AudioInit_G51FallbackStereo
	ordi16 50588, 2
	ldda16 xwa, 50584
	and wa, 0x60
	jr nz, AudioInit_SetGroup51Levels
	ldda16 xwa, 50582
	and wa, 0x7
	jr z, AudioInit_SetGroup51Levels
	ldda16 xwa, 50580
	bit 4, wa
	jr nz, AudioInit_ClearGroup51Mode
	setda 3, 49662
	jr AudioInit_AfterGroup51ModeSet

AudioInit_ClearGroup51Mode:
	stdi8 49662, 0

AudioInit_AfterGroup51ModeSet:
	ordi16 50588, 1

AudioInit_SetGroup51Levels:
	stdi8 49850, 255
	stdi8 49851, 255
	bitda 5, 63991
	jr nz, AudioInit_CheckG51Bit5_FD07
	stdi8 49668, 2

AudioInit_CheckG51Bit5_FD07:
	bitda 5, 64433
	jr nz, AudioInit_CheckG51Bit5_FBF1
	stdi8 49688, 22

AudioInit_CheckG51Bit5_FBF1:
	ordi16 50588, 260
	jp AudioInit_ConfigurePanning

AudioInit_G51FallbackStereo:
	extz wa
	jrl AudioInit_ConfigStereoVoice

AudioInit_G51FallbackDefault:
	extz wa
	jrl AudioInit_ConfigStereoVoice

AudioInit_CheckMixMode:
	ldda8 c, 36150
	cp c, 0x76
	jr z, AudioInit_LoadAndConfigure
	cp c, 0x73
	jr z, AudioInit_LoadAndConfigure
	cp c, 0x72
	jr z, AudioInit_LoadAndConfigure
	cp c, 0x6F
	jr nz, AudioInit_MixFallbackDefault

AudioInit_LoadAndConfigure:
	ldda8 c, 36154	; LD C, (238D3Ah) - 24-bit addressing mode
	extz bc
	lda_24 xde, 0xee8e82
	ld_srib3 C, 0x07, 0xE8, 0xE4
	stda8 49663, c
	cp c, 0xFF
	jr z, AudioInit_MixFallbackConfig
	ordi16 50588, 2
	ldda16 xwa, 50580
	bit 4, wa
	ret z
	stdi8 49663, 255
	ret

AudioInit_MixFallbackConfig:
	extz wa
	calr AudioInit_ConfigStereoVoice
	ret

AudioInit_MixFallbackDefault:
	extz wa
	jrl AudioInit_ConfigStereoVoice
	extz wa
	jrl AudioInit_ConfigStereoVoice

AudioInit_DrumSaveReturn:
	stdi16 50596, 0
	stdi16 50598, 0
	push xde
	push xhl
	push xix
	push xiz
	ldada xwa, 49662
	call CtrlPanel_RefreshIndicatorState
	pop xiz
	pop xix
	pop xhl
	pop xde
	ret

AudioInit_VoiceParamCtrl:
	dec 6, xsp
	ldb c, 0x0
	bitda 0, 64851
	jr z, AudioInit_CheckVoiceParamState
	set 1, c

AudioInit_CheckVoiceParamState:
	cpdi8 49663, 255
	jr nz, AudioInit_CompareAndSendMIDI
	cpdi8 50632, 255
	jr z, AudioInit_CheckBit2VoiceParam
	set 0, c
	ldda16 xwa, 50582
	and wa, 0x80
	cp wa, 0x80
	jr nz, AudioInit_CompareAndSendMIDI
	ldda16 xwa, 50582
	and wa, 0x3
	jr z, AudioInit_CompareAndSendMIDI
	set 4, c
	jr AudioInit_CompareAndSendMIDI

AudioInit_CheckBit2VoiceParam:
	ldda16 xwa, 50582
	bit 2, wa
	jr z, AudioInit_CompareAndSendMIDI
	or c, 0x18

AudioInit_CompareAndSendMIDI:
	cpdm8 50600, c
	jr z, AudioInit_VoiceParamDone
	stda8 50600, c
	ld (xsp + 256), 0x4	; LD (XSP + 000h), 004h - explicit displacement encoding
	ld (xsp + 1), 0xF0
	ld (xsp + 2), 0x50
	ld (xsp + 3), 0x91
	ldmi16 (xsp + 4), 0xC5A8
	lda xwa, (xsp)
	call MIDI_SendCmdPacket
	call MIDI_PostSendStub
	cpdi8 36148, 13
	jr z, AudioInit_VoiceParamDone
	push xde
	push xhl
	push xix
	push xiz
	call Audio_ProcessPartExpressions
	pop xiz
	pop xix
	pop xhl
	pop xde

AudioInit_VoiceParamDone:
	inc 6, xsp
	ret

AudioInit_DrumRoutingCheck:
	lds de, 0
	bitda 2, 49662
	jr nz, AudioInit_ProcessVoiceAssign
	ldda16 xwa, 50584
	and wa, 0x6
	jr z, AudioInit_CheckOutputFlags
	ldda16 xwa, 50584
	bit 0, wa
	jr nz, AudioInit_CheckOutputFlags
	ldda16 xwa, 50582
	and wa, 0x3
	jr nz, AudioInit_ProcessVoiceAssign

AudioInit_CheckOutputFlags:
	ldda16 xwa, 50584
	and wa, 0x60
	jrl nz, AudioInit_NoRoutingActive
	ldda16 xwa, 50582
	and wa, 0x3
	jrl z, AudioInit_NoRoutingActive

AudioInit_ProcessVoiceAssign:
	cpdi8 49663, 255
	jr nz, AudioInit_CheckStoredVoice
	set 3, de
	ldmm8 50632, 50594
	jr AudioInit_UpdateVoiceBank0

AudioInit_CheckStoredVoice:
	cpdi8 50632, 255
	jr z, AudioInit_ClearStoredVoice
	set 3, de

AudioInit_ClearStoredVoice:
	stdi8 50632, 255

AudioInit_UpdateVoiceBank0:
	ldda8 a, 49859
	srl a, 1
	cpda8 a, 50594
	jr z, AudioInit_UpdateVoiceBank1
	setda 7, 49858
	ldda8 a, 50594
	res 7, a
	sla a, 1
	anddi8 49859, 1
	orddm8 49859, a
	ordi16 50586, 512

AudioInit_UpdateVoiceBank1:
	ldda8 a, 49863
	srl a, 1
	cpda8 a, 50594
	jr z, AudioInit_UpdateVoiceBank2
	setda 7, 49862
	ldda8 a, 50594
	res 7, a
	sla a, 1
	anddi8 49863, 1
	orddm8 49863, a
	ordi16 50586, 512

AudioInit_UpdateVoiceBank2:
	ldda8 a, 50594
	dec 1, a
	ldda8 c, 49866
	res 7, c
	cp c, a
	jr z, AudioInit_CheckStereoRouting
	setda 7, 49866
	ldda8 a, 50594
	dec 1, a
	res 7, a
	anddi8 49866, 128
	orddm8 49866, a
	ordi16 50586, 512

AudioInit_CheckStereoRouting:
	bitda 3, 49662
	jr z, AudioInit_ClearStereoRouting
	ldda8 a, 50594
	dec 1, a
	ldda8 c, 49870
	res 7, c
	cp c, a
	jr z, AudioInit_VoiceStereoCheck
	setda 7, 49870
	ldda8 a, 50594
	dec 1, a
	res 7, a
	anddi8 49870, 128
	orddm8 49870, a
	ordi16 50586, 512
	jr AudioInit_VoiceStereoCheck

AudioInit_ClearStereoRouting:
	ldda8 a, 49870
	res 7, a
	cps a, 0
	jr z, AudioInit_VoiceStereoCheck
	setda 7, 49870
	anddi8 49870, 128
	ordi16 50586, 512

AudioInit_VoiceStereoCheck:
	ldda8 a, 49875
	srl a, 1
	cpda8 a, 50594
	jrl z, AudioInit_UpdateIndicators
	setda 7, 49874
	ldda8 a, 50594
	res 7, a
	sla a, 1
	anddi8 49875, 1
	orddm8 49875, a
	ordi16 50586, 512
	jrl AudioInit_UpdateIndicators

AudioInit_NoRoutingActive:
	cpdi8 50632, 255
	jr z, AudioInit_ClearAllVoiceBanks
	set 3, de

AudioInit_ClearAllVoiceBanks:
	stdi8 50632, 255
	ldda8 a, 49859
	res 0, a
	cps a, 0
	jr z, AudioInit_ClearBank1Routing
	setda 7, 49858
	anddi8 49859, 1
	ordi16 50586, 512

AudioInit_ClearBank1Routing:
	ldda8 a, 49863
	res 0, a
	cps a, 0
	jr z, AudioInit_ClearBank2Routing
	setda 7, 49862
	anddi8 49863, 1
	ordi16 50586, 512

AudioInit_ClearBank2Routing:
	ldda8 a, 49866
	res 7, a
	cps a, 0
	jr z, AudioInit_CheckBit2Routing
	setda 7, 49866
	anddi8 49866, 128
	ordi16 50586, 512

AudioInit_CheckBit2Routing:
	ldda16 xwa, 50582
	bit 2, wa
	jr z, AudioInit_ClearBank3Routing
	ldda8 a, 49870
	res 7, a
	cp a, 0x7F
	jr z, AudioInit_UpdateIndicators
	setda 7, 49870
	ordi8 49870, 127
	ordi16 50586, 512
	jr AudioInit_UpdateIndicators

AudioInit_ClearBank3Routing:
	ldda8 a, 49870
	res 7, a
	cps a, 0
	jr z, AudioInit_UpdateIndicators
	setda 7, 49870
	anddi8 49870, 128
	ordi16 50586, 512

AudioInit_UpdateIndicators:
	bit 3, de
	ret z
	ldw wa, 0x45
	call CtrlPanel_SetIndicatorBit
	cpdi8 50632, 255
	jr z, AudioInit_ClearDrumModeAlt
	ldda8 a, 64770
	and a, 0x3
	jr z, AudioInit_ClearDrumMode
	ldda8 a, 50594
	cp a, 0x43
	jr z, AudioInit_SetDrumMode4
	cp a, 0x3C
	jr z, AudioInit_SetDrumMode2
	cp a, 0x37
	ret nz
	stdi8 36696, 1
	ret

AudioInit_SetDrumMode2:
	stdi8 36696, 2
	ret

AudioInit_SetDrumMode4:
	stdi8 36696, 4
	ret

AudioInit_ClearDrumMode:
	anddi8 36696, 248
	ret

AudioInit_ClearDrumModeAlt:
	anddi8 36696, 248
	ret

AudioInit_ClearPartFlags_ByMode:
	ldda16 xwa, 50580
	and wa, 0x3
	jr z, AudioInit_SetPartMasks
	lds de, 0
	cp de, 0x1A
	ret nc

AudioInit_ClearPartFlags_Loop:
	ld wa, de
	add wa, wa
	ldada xbc, 49954
	extz xwa
	add xwa, xbc
	resm 5, (xwa)
	ordi16 50588, 8
	inc 1, de
	cp de, 0x1A
	jr c, AudioInit_ClearPartFlags_Loop
	ret

AudioInit_SetPartMasks:
	lds de, 0
	cp de, 0x10
	jr nc, AudioInit_CheckGlobalFlag6

AudioInit_SetPartMasks_Loop:
	ld wa, de
	add wa, wa
	ldada xbc, 49954
	extz xwa
	add xwa, xbc
	setm 5, (xwa)
	inc 1, de
	cp de, 0x10
	jr c, AudioInit_SetPartMasks_Loop

AudioInit_CheckGlobalFlag6:
	bitda 6, 64851
	jr z, AudioInit_ClearVoiceGroupFlags
	setda 5, 49986
	setda 5, 49988
	setda 5, 49990
	setda 5, 49992
	setda 5, 49996
	jr AudioInit_CheckVoiceFlag6

AudioInit_ClearVoiceGroupFlags:
	resda 5, 49986
	resda 5, 49988
	resda 5, 49990
	resda 5, 49992
	resda 5, 49996
	ordi16 50588, 8

AudioInit_CheckVoiceFlag6:
	bitda 6, 64848
	jr z, AudioInit_ClearAuxVoiceFlag
	setda 5, 49994
	jr AudioInit_CheckReverbFlag

AudioInit_ClearAuxVoiceFlag:
	resda 5, 49994
	ordi16 50588, 8

AudioInit_CheckReverbFlag:
	bitda 7, 64851
	jr z, AudioInit_ClearReverbFlag
	setda 5, 50004
	ret

AudioInit_ClearReverbFlag:
	resda 5, 50004
	ordi16 50588, 8
	ret

Audio_CheckInitStatus:
	dec 2, xsp
	ldw (xsp), 0x0
	stdi16 50584, 0
	stdi8 50590, 255
	ldda16 xhl, 61854
	orda16 xhl, 3409
	ld wa, hl
	cps wa, 0
	jr z, AudioInit_ClearStatusBit8
	ordi16 50584, 256
	jr AudioInit_CheckGroupB_Presence

AudioInit_ClearStatusBit8:
	anddi16 50584, 65279

AudioInit_CheckGroupB_Presence:
	ldda16 xbc, 10408
	orda16 xbc, 3407
	ld wa, bc
	cps wa, 0
	jr z, AudioInit_ClearStatusBit9
	ordi16 50584, 512
	jr AudioInit_ChannelLoop_Init

AudioInit_ClearStatusBit9:
	anddi16 50584, 65023

AudioInit_ChannelLoop_Init:
	ldb e, 0x0
	cp e, 0x10
	jrl nc, AudioInit_ChannelLoop_Done

AudioInit_ChannelLoop_Body:
	ld a, e
	extz wa
	ldada xix, 61856
	extz xwa
	add xwa, xix
	ld a, (xwa)
	ld d, a
	ld a, e
	extz wa
	add wa, wa
	lda_24 xix, 0xee8cd4
	ld_sriw3 WA, 0x07, 0xF0, 0xE0
	andda16 xwa, 62096
	jr z, AudioInit_VoiceNotAssigned
	ld a, e
	extz wa
	ldada xix, 61856
	extz xwa
	add xwa, xix
	ld a, (xwa)
	extz wa
	lda_24 xix, 0xee8ea2
	ld_srib3 A, 0x07, 0xF0, 0xE0
	extz wa
	ldada xix, 49698
	extz xwa
	add xwa, xix
	ld a, (xwa)
	ldfr_berp A, 0xE2
	jr AudioInit_CheckVoiceChanged

AudioInit_VoiceNotAssigned:
	ldi_erpb 0xE2, 0xFF

AudioInit_CheckVoiceChanged:
	ld a, d
	extz wa
	lda_24 xix, 0xee8ea2
	cp_srib_im 0x07, 0xF0, 0xE0, 0xFF
	jr z, AudioInit_VoiceUnchanged
	ld a, e
	extz wa
	add wa, wa
	lda_24 xix, 0xee8cd4
	ld_sriw3 WA, 0x07, 0xF0, 0xE0
	ld ix, hl
	or ix, bc
	and ix, wa
	jr nz, AudioInit_CheckGroupA

AudioInit_VoiceUnchanged:
	ld a, e
	extz wa
	ldada xix, 49794
	extz xwa
	add xwa, xix
	ld (xwa), 0xFF
	ld a, e
	extz wa
	ldada xix, 49826
	extz xwa
	add xwa, xix
	ld (xwa), 0xFF
	jrl AudioInit_ChannelLoop_Next

AudioInit_CheckGroupA:
	ldda16 xwa, 50584
	bit 8, wa
	jrl z, AudioInit_CheckGroupB_Channel
	ld a, e
	extz wa
	add wa, wa
	lda_24 xix, 0xee8cd4
	ld_sriw3 WA, 0x07, 0xF0, 0xE0
	and wa, hl
	jrl z, AudioInit_CheckGroupB_Channel
	ld a, d
	cp a, 0xE
	jr z, AudioInit_GroupA_TypeE
	cp a, 0xD
	jrl nz, AudioInit_GroupA_OtherType
	ordi16 50584, 32
	ld a, e
	extz wa
	ldada xix, 49794
	ld iy, wa
	extz xiy
	add xiy, xix
	ld a, d
	extz wa
	lda_24 xix, 0xee8ea2
	ld_srib3 A, 0x07, 0xF0, 0xE0
	ld (xiy), a
	ld a, e
	extz wa
	ldada xix, 49810
	ld iy, wa
	extz xiy
	add xiy, xix
	ld a, d
	extz wa
	lda_24 xix, 0xee8ea2
	ld_srib3 A, 0x07, 0xF0, 0xE0
	ld (xiy), a
	jrl AudioInit_CheckGroupB_Channel

AudioInit_GroupA_TypeE:
	ordi16 50584, 64
	ld a, e
	extz wa
	ldada xix, 49794
	ld iy, wa
	extz xiy
	add xiy, xix
	ld a, d
	extz wa
	lda_24 xix, 0xee8ea2
	ld_srib3 A, 0x07, 0xF0, 0xE0
	ld (xiy), a
	ld a, e
	extz wa
	ldada xix, 49810
	ld iy, wa
	extz xiy
	add xiy, xix
	ld a, d
	extz wa
	lda_24 xix, 0xee8ea2
	ld_srib3 A, 0x07, 0xF0, 0xE0
	ld (xiy), a
	jrl AudioInit_CheckGroupB_Channel

AudioInit_GroupA_OtherType:
	cpdi8 36150, 138
	jr nz, AudioInit_GroupA_DefaultMapping
	ld a, e
	extz wa
	ldada xix, 49794
	ld iy, wa
	extz xiy
	add xiy, xix
	ld a, d
	extz wa
	lda_24 xix, 0xee8ea2
	ld_srib3 A, 0x07, 0xF0, 0xE0
	ld (xiy), a
	ld a, e
	extz wa
	add wa, wa
	lda_24 xix, 0xee8cd4
	ld_sriw3 WA, 0x07, 0xF0, 0xE0
	andda16 xwa, 3928
	jr z, AudioInit_GroupA_NoAuxMapping
	ld a, e
	extz wa
	ldada xix, 49810
	ld iy, wa
	extz xiy
	add xiy, xix
	ld a, d
	extz wa
	lda_24 xix, 0xee8ea2
	ld_srib3 A, 0x07, 0xF0, 0xE0
	ld (xiy), a
	jr AudioInit_StoreChannelMapping

AudioInit_GroupA_NoAuxMapping:
	ld a, e
	extz wa
	ldada xix, 49810
	ld iy, wa
	extz xiy
	add xiy, xix
	ld (xiy), 0xFF
	jr AudioInit_StoreChannelMapping

AudioInit_GroupA_DefaultMapping:
	ld a, e
	extz wa
	ldada xix, 49794
	ld iy, wa
	extz xiy
	add xiy, xix
	ld a, d
	extz wa
	lda_24 xix, 0xee8ea2
	ld_srib3 A, 0x07, 0xF0, 0xE0
	ld (xiy), a
	ld a, e
	extz wa
	add wa, wa
	lda_24 xix, 0xee8cd4
	ld_sriw3 WA, 0x07, 0xF0, 0xE0
	andda16 xwa, 61904
	jr z, AudioInit_GroupA_NoSecondary
	ld a, e
	extz wa
	ldada xix, 49810
	ld iy, wa
	extz xiy
	add xiy, xix
	ld a, d
	extz wa
	lda_24 xix, 0xee8ea2
	ld_srib3 A, 0x07, 0xF0, 0xE0
	ld (xiy), a
	jr AudioInit_StoreChannelMapping

AudioInit_GroupA_NoSecondary:
	ld a, e
	extz wa
	ldada xix, 49810
	ld iy, wa
	extz xiy
	add xiy, xix
	ld (xiy), 0xFF

AudioInit_StoreChannelMapping:
	ld a, e
	extz wa
	ldada xix, 49826
	ld iy, wa
	extz xiy
	add xiy, xix
	ldto_berp A, 0xE2
	ld (xiy), a

AudioInit_CheckGroupB_Channel:
	ldda16 xwa, 50584
	bit 9, wa
	jrl z, AudioInit_ChannelLoop_Next
	ld a, e
	extz wa
	add wa, wa
	lda_24 xix, 0xee8cd4
	ld_sriw3 WA, 0x07, 0xF0, 0xE0
	and wa, bc
	jrl z, AudioInit_ChannelLoop_Next
	incm 1, (xsp)
	cpdi8 50590, 255
	jr nz, AudioInit_GroupB_CheckType
	ld a, d
	extz wa
	lda_24 xix, 0xee8ea2
	ldmm_srib 0x07, 0xF0, 0xE0, 0x9E, 0xC5

AudioInit_GroupB_CheckType:
	ld a, d
	cp a, 0x10
	jrl z, AudioInit_GroupB_Type10
	cp a, 0xE
	jr z, AudioInit_GroupB_TypeE
	cp a, 0xD
	jrl nz, AudioInit_GroupB_DefaultMapping
	ordi16 50584, 2
	ld a, e
	extz wa
	ldada xix, 49794
	ld iy, wa
	extz xiy
	add xiy, xix
	ld a, d
	extz wa
	lda_24 xix, 0xee8ea2
	ld_srib3 A, 0x07, 0xF0, 0xE0
	ld (xiy), a
	ld a, e
	extz wa
	ldada xix, 49810
	ld iy, wa
	extz xiy
	add xiy, xix
	ld a, d
	extz wa
	lda_24 xix, 0xee8ea2
	ld_srib3 A, 0x07, 0xF0, 0xE0
	ld (xiy), a
	jrl AudioInit_ChannelLoop_Next

AudioInit_GroupB_TypeE:
	ordi16 50584, 4
	ld a, e
	extz wa
	ldada xix, 49794
	ld iy, wa
	extz xiy
	add xiy, xix
	ld a, d
	extz wa
	lda_24 xix, 0xee8ea2
	ld_srib3 A, 0x07, 0xF0, 0xE0
	ld (xiy), a
	ld a, e
	extz wa
	ldada xix, 49810
	ld iy, wa
	extz xiy
	add xiy, xix
	ld a, d
	extz wa
	lda_24 xix, 0xee8ea2
	ld_srib3 A, 0x07, 0xF0, 0xE0
	ld (xiy), a
	jr AudioInit_ChannelLoop_Next

AudioInit_GroupB_Type10:
	ordi16 50584, 8
	ld a, e
	extz wa
	ldada xix, 49794
	extz xwa
	add xwa, xix
	ld (xwa), 0xFF
	ld a, e
	extz wa
	ldada xix, 49810
	extz xwa
	add xwa, xix
	ld (xwa), 0xFF
	jr AudioInit_ChannelLoop_Next

AudioInit_GroupB_DefaultMapping:
	ld a, e
	extz wa
	ldada xix, 49794
	ld iy, wa
	extz xiy
	add xiy, xix
	ld a, d
	extz wa
	lda_24 xix, 0xee8ea2
	ld_srib3 A, 0x07, 0xF0, 0xE0
	ld (xiy), a
	ld a, e
	extz wa
	ldada xix, 49810
	ld iy, wa
	extz xiy
	add xiy, xix
	ld a, d
	extz wa
	lda_24 xix, 0xee8ea2
	ld_srib3 A, 0x07, 0xF0, 0xE0
	ld (xiy), a

AudioInit_ChannelLoop_Next:
	ordi16 50588, 192
	inc 1, e
	cp e, 0x10
	jrl c, AudioInit_ChannelLoop_Body

AudioInit_ChannelLoop_Done:
	cpw (xsp), 0x1
	jr nz, AudioInit_SetChangedFlag
	ordi16 50584, 1

AudioInit_SetChangedFlag:
	bitda 3, 10419
	jr z, AudioInit_CheckExternalBit3
	anddi16 50584, 65023

AudioInit_CheckExternalBit3:
	ldda16 xwa, 50584
	bit 6, wa
	jr z, AudioInit_NoTypeE_CheckD
	ldda8 a, 64606
	and a, 0x7
	extz wa
	add wa, wa
	lda_24 xbc, 0xee8e28
	ld_sriw3 DE, 0x07, 0xE4, 0xE0
	ldda8 a, 64605
	and a, 0x8
	extz wa
	add wa, wa
	lda_24 xbc, 0xee8e28
	or_sriw_rm DE, 0x07, 0xE4, 0xE0
	jr AudioInit_ApplyOutputRouting

AudioInit_NoTypeE_CheckD:
	ldda16 xwa, 50584
	and wa, 0x22
	cp wa, 0x20
	jr nz, AudioInit_DefaultOutputRouting
	lds de, 2
	ldda8 a, 64605
	and a, 0x8
	extz wa
	add wa, wa
	lda_24 xbc, 0xee8e28
	or_sriw_rm DE, 0x07, 0xE4, 0xE0
	jr AudioInit_ApplyOutputRouting

AudioInit_DefaultOutputRouting:
	ldda8 a, 64605
	and a, 0xF
	extz wa
	add wa, wa
	lda_24 xbc, 0xee8e28
	ld_sriw3 DE, 0x07, 0xE4, 0xE0

AudioInit_ApplyOutputRouting:
	anddi16 50582, 65512
	orddm16 50582, xde
	inc 2, xsp
	ret

AudioInit_SelectPriority:
	ldda8 a, 14235
	cp a, 0x10
	jrl z, AudioInit_Priority_Mode10
	cp a, 0x8
	jr z, AudioInit_Priority_Mode8
	cps a, 4
	jr z, AudioInit_Priority_Mode4
	cps a, 2
	jr z, AudioInit_Priority_Mode2
	cps a, 1
	jrl nz, AudioInit_Priority_Default
	stdi8 49746, 0
	stdi8 49747, 255
	stdi8 49748, 255
	stdi8 49749, 255
	stdi8 49750, 255
	ordi16 50588, 16
	ret

AudioInit_Priority_Mode2:
	stdi8 49746, 255
	stdi8 49747, 1
	stdi8 49748, 255
	stdi8 49749, 255
	stdi8 49750, 255
	ordi16 50588, 16
	ret

AudioInit_Priority_Mode4:
	stdi8 49746, 255
	stdi8 49747, 255
	stdi8 49748, 2
	stdi8 49749, 255
	stdi8 49750, 255
	ordi16 50588, 16
	ret

AudioInit_Priority_Mode8:
	stdi8 49746, 255
	stdi8 49747, 255
	stdi8 49748, 255
	stdi8 49749, 3
	stdi8 49750, 255
	ordi16 50588, 16
	ret

AudioInit_Priority_Mode10:
	stdi8 49746, 255
	stdi8 49747, 255
	stdi8 49748, 255
	stdi8 49749, 255
	stdi8 49750, 4
	ordi16 50588, 16
	ret

AudioInit_Priority_Default:
	stdi8 49746, 255
	stdi8 49747, 255
	stdi8 49748, 255
	stdi8 49749, 255
	stdi8 49750, 255
	ordi16 50588, 16
	ret

AudioInit_CheckMIDIStatus:
	cpdi8 32523, 0
	jr z, AudioInit_MIDIDisabled
	stdi8 49785, 0
	stdi8 49786, 255
	ordi16 50588, 32
	ret

AudioInit_MIDIDisabled:
	stdi8 49785, 255
	stdi8 49786, 255
	ordi16 50588, 32
	ret

AudioInit_RefreshToneBank:
	pushw iz
	ldda16 xiz, 50582
	anddi16 50582, 65519
	call Voice_UpdatePlayModeState
	cp l, 0xFF
	call_24 nz, 0xFE12B8
	call NoteMap_FindBestMatch
	cp l, 0xFF
	call_24 nz, 0xFE12FC
	stda16 50582, xiz
	popw iz
	ret

AudioInit_VoiceRoutingTable:
	ret
	ret
	ret
	ret
	ret
	ret
	ret
	stdi8	49662, 0
	ordi8	49858, 127
	anddi8	49859, 1
	ordi8	49860, 254
	anddi8	49861, 1
	ordi8	49862, 127
	anddi8	49863, 1
	ordi8	49864, 254
	anddi8	49865, 1
	ordi8	49866, 127
	anddi8	49867, 1
	ordi8	49868, 254
	anddi8	49869, 1
	ordi8	49870, 127
	anddi8	49871, 1
	ordi8	49872, 254
	anddi8	49873, 1
	ordi8	49874, 127
	anddi8	49875, 1
	ordi8	49876, 254
	anddi8	49877, 1
	lds	de, 0
	cp	de, 32
	ret	nc
	ld	wa, de
	add	wa, wa
	ldada	xbc, 49890
	extz	xwa
	add	xwa, xbc
	resm	7, (xwa)
	ld	wa, de
	add	wa, wa
	ldada	xbc, 49890
	extz	xwa
	add	xwa, xbc
	andmi8	(xwa), 143
	ld	wa, de
	add	wa, wa
	ldada	xbc, 49954
	extz	xwa
	add	xwa, xbc
	resm	7, (xwa)
	ld	wa, de
	add	wa, wa
	ldada	xbc, 49954
	extz	xwa
	add	xwa, xbc
	setm	6, (xwa)
	ld	wa, de
	add	wa, wa
	ldada	xbc, 49954
	extz	xwa
	add	xwa, xbc
	setm	5, (xwa)
	ld	wa, de
	add	wa, wa
	ldada	xbc, 49954
	extz	xwa
	add	xwa, xbc
	resm	4, (xwa)
	ld	wa, de
	add	wa, wa
	ldada	xbc, 49954
	extz	xwa
	add	xwa, xbc
	andmi8	(xwa), 241
	ld	wa, de
	add	wa, wa
	add	wa, 292
	ldada	xbc, 49663
	extz	xwa
	add	xwa, xbc
	andmi8	(xwa), 15
	inc	1, de
	cp	de, 32
	jr	c, -127
	ret

AudioInit_ConfigureVoiceRouting:
	anddi16 50582, 65279
	ldda16 xwa, 50582
	and wa, 0x3
	jrl z, AudioInit_Routing_NoActiveVoices
	ldda16 xwa, 50582
	and wa, 0xA0
	cp wa, 0xA0
	jrl nz, AudioInit_Routing_NoGroupAB
	resda 2, 49662
	ordi16 50588, 1
	stdi8 49850, 2
	stdi8 49851, 22
	stdi8 49668, 255
	stdi8 49688, 255
	ldda16 xwa, 50582
	bit 9, wa
	jr z, AudioInit_Routing_CheckSplitMode
	ldda8 a, 64607
	and a, 0xFC
	jr nz, AudioInit_Routing_SetOverrideFlag
	ldda8 a, 64608
	and a, 0xFC
	jr nz, AudioInit_Routing_SetOverrideFlag
	bitda 5, 63991
	jrl nz, AudioInit_Routing_SkipToEnd
	stdi8 49668, 2
	jrl AudioInit_Routing_Done

AudioInit_Routing_SetOverrideFlag:
	ordi16 50582, 256
	jrl AudioInit_Routing_Done

AudioInit_Routing_CheckSplitMode:
	bitda 1, 64607
	jr z, AudioInit_Routing_NoSplit
	ldda8 a, 64607
	and a, 0xFC
	jr nz, AudioInit_Routing_SplitOverride
	ldda8 a, 64608
	and a, 0xFC
	jr nz, AudioInit_Routing_SplitOverride
	bitda 5, 63991
	jr nz, AudioInit_Routing_SplitCheckAux
	stdi8 49668, 2

AudioInit_Routing_SplitCheckAux:
	bitda 5, 64433
	jrl nz, AudioInit_Routing_SkipToEnd
	stdi8 49688, 22
	jrl AudioInit_Routing_Done

AudioInit_Routing_SplitOverride:
	ordi16 50582, 256
	jrl AudioInit_Routing_Done

AudioInit_Routing_NoSplit:
	ldda8 a, 64607
	and a, 0xFC
	jr nz, AudioInit_Routing_CheckTypeEDFlags
	ldda8 a, 64608
	and a, 0xFC
	jr nz, AudioInit_Routing_CheckTypeEDFlags
	bitda 5, 63991
	jr nz, AudioInit_Routing_NoSplitCheckAux
	stdi8 49668, 2

AudioInit_Routing_NoSplitCheckAux:
	bitda 5, 64433
	jrl nz, AudioInit_Routing_Done
	stdi8 49688, 22
	jrl AudioInit_Routing_Done

AudioInit_Routing_CheckTypeEDFlags:
	ldda16 xwa, 50584
	and wa, 0x60
	jr nz, AudioInit_Routing_TypeED_Override
	bitda 5, 63991
	jr nz, AudioInit_Routing_TypeED_CheckAux
	stdi8 49668, 2

AudioInit_Routing_TypeED_CheckAux:
	bitda 5, 64433
	jrl nz, AudioInit_Routing_Done
	stdi8 49688, 22
	jrl AudioInit_Routing_Done

AudioInit_Routing_TypeED_Override:
	ordi16 50582, 256
	jrl AudioInit_Routing_Done

AudioInit_Routing_NoGroupAB:
	bitda 5, 63991
	jr nz, AudioInit_Routing_SimpleAssign
	stdi8 49668, 2

AudioInit_Routing_SimpleAssign:
	stdi8 49850, 21
	stdi8 49851, 22
	stdi8 49687, 255
	stdi8 49688, 255
	cpdi8 3431, 4
	jr z, AudioInit_Routing_AllDisabled
	ldda16 xwa, 50584
	and wa, 0x22
	cp wa, 0x20
	jr nz, AudioInit_Routing_CheckMixMode

AudioInit_Routing_AllDisabled:
	stdi8 49850, 255
	stdi8 49851, 255
	jrl AudioInit_Routing_Done

AudioInit_Routing_CheckMixMode:
	ldda16 xwa, 50582
	bit 9, wa
	jrl nz, AudioInit_Routing_Done
	bitda 1, 64607
	jr nz, AudioInit_Routing_Done
	ldda8 a, 64607
	and a, 0xFC
	jr nz, AudioInit_Routing_MixFCBits
	ldda8 a, 64608
	and a, 0xFC
	jr nz, AudioInit_Routing_MixFCBits
	bitda 5, 64485
	jr nz, AudioInit_Routing_MixCheckAux
	stdi8 49687, 21

AudioInit_Routing_MixCheckAux:
	bitda 5, 64433
	jr nz, AudioInit_Routing_Done
	stdi8 49688, 22
	jr AudioInit_Routing_Done

AudioInit_Routing_MixFCBits:
	ldda16 xwa, 50584
	and wa, 0x60
	jr nz, AudioInit_Routing_Done
	bitda 5, 64485
	jr nz, AudioInit_Routing_MixFCCheckAux
	stdi8 49687, 21

AudioInit_Routing_MixFCCheckAux:
	bitda 5, 64433
	jr nz, AudioInit_Routing_Done
	stdi8 49688, 22

AudioInit_Routing_SkipToEnd:
	jr AudioInit_Routing_Done

AudioInit_Routing_NoActiveVoices:
	ldda16 xwa, 50582
	bit 2, wa
	jr z, AudioInit_Routing_FullDisable
	stdi8 49850, 21
	stdi8 49851, 22
	stdi8 49687, 255
	stdi8 49688, 255
	jr AudioInit_Routing_Done

AudioInit_Routing_FullDisable:
	stdi8 49850, 255
	stdi8 49851, 255
	stdi8 49687, 255
	stdi8 49688, 255

AudioInit_Routing_Done:
	ordi16 50588, 260
	ret

AudioInit_ConfigurePanning:
	ldda16 xwa, 50582
	and wa, 0x400
	cp wa, 0x400
	ret nz
	ldda16 xwa, 50582
	bit 2, wa
	ret nz
	cpdi8 49663, 255
	jr nz, AudioInit_Pan_CheckMode0
	bitda 0, 49662
	jr nz, AudioInit_Pan_SetStereoLeft

AudioInit_Pan_CheckMode0:
	cpdi8 49663, 0
	jr nz, AudioInit_Pan_CheckMode1

AudioInit_Pan_SetStereoLeft:
	stdi8 49844, 0
	jr AudioInit_Pan_CheckReverbChannel

AudioInit_Pan_CheckMode1:
	cpdi8 49663, 255
	jr nz, AudioInit_Pan_CheckMode1b
	bitda 1, 49662
	jr nz, AudioInit_Pan_SetStereoRight

AudioInit_Pan_CheckMode1b:
	cpdi8 49663, 1
	jr nz, AudioInit_Pan_CheckTypeED

AudioInit_Pan_SetStereoRight:
	stdi8 49844, 1
	jr AudioInit_Pan_CheckReverbChannel

AudioInit_Pan_CheckTypeED:
	ldda16 xwa, 50584
	and wa, 0x60
	jr z, AudioInit_Pan_DefaultCenter
	ldda8 a, 64614
	and a, 0x3
	cps a, 2
	jr nz, AudioInit_Pan_TypeED_Left
	stdi8 49844, 1
	jr AudioInit_Pan_CheckReverbChannel

AudioInit_Pan_TypeED_Left:
	stdi8 49844, 0
	jr AudioInit_Pan_CheckReverbChannel

AudioInit_Pan_DefaultCenter:
	stdi8 49844, 255

AudioInit_Pan_CheckReverbChannel:
	cpdi8 59840, 14
	jr ule, AudioInit_Pan_Reverb_CopyFromMain
	cpdi8 49663, 255
	jr nz, AudioInit_Pan_Reverb_CheckMode0
	bitda 0, 49662
	jr nz, AudioInit_Pan_Reverb_Left

AudioInit_Pan_Reverb_CheckMode0:
	cpdi8 49663, 0
	jr nz, AudioInit_Pan_Reverb_CheckMode1

AudioInit_Pan_Reverb_Left:
	stdi8 49852, 0
	jr AudioInit_Pan_Done

AudioInit_Pan_Reverb_CheckMode1:
	cpdi8 49663, 255
	jr nz, AudioInit_Pan_Reverb_CheckMode1b
	bitda 1, 49662
	jr nz, AudioInit_Pan_Reverb_Right

AudioInit_Pan_Reverb_CheckMode1b:
	cpdi8 49663, 1
	jr nz, AudioInit_Pan_Reverb_CheckTypeED

AudioInit_Pan_Reverb_Right:
	stdi8 49852, 1
	jr AudioInit_Pan_Done

AudioInit_Pan_Reverb_CheckTypeED:
	ldda16 xwa, 50584
	and wa, 0x60
	jr z, AudioInit_Pan_Reverb_Center
	ldda8 a, 64614
	and a, 0x3
	cps a, 2
	jr nz, AudioInit_Pan_Reverb_TypeED_Left
	stdi8 49852, 1
	jr AudioInit_Pan_Done

AudioInit_Pan_Reverb_TypeED_Left:
	stdi8 49852, 0
	jr AudioInit_Pan_Done

AudioInit_Pan_Reverb_Center:
	stdi8 49852, 255
	jr AudioInit_Pan_Done

AudioInit_Pan_Reverb_CopyFromMain:
	ldmm8 49852, 59840

AudioInit_Pan_Done:
	ordi16 50588, 256
	ret

AudioInit_CheckStereoMode:
	ldda16 xwa, 50582
	bit 11, wa
	ret z
	bitda 0, 49662
	jr z, AudioInit_Stereo_CheckBit1
	stdi8 49664, 0
	jr AudioInit_Stereo_CheckBit3

AudioInit_Stereo_CheckBit1:
	bitda 1, 49662
	jr z, AudioInit_Stereo_Default
	stdi8 49664, 1
	jr AudioInit_Stereo_CheckBit3

AudioInit_Stereo_Default:
	stdi8 49664, 255

AudioInit_Stereo_CheckBit3:
	bitda 3, 49662
	ret z
	stdi8 49665, 0
	ret

AudioInit_DispatchChanges:
	stdi16 50378, 0
	ldda16 xwa, 50588
	and wa, 0x188
	call_24 nz, 0xFDFB71
	ldda16 xwa, 50588
	and wa, 0x1C0
	call_24 nz, 0xFDFE28
	ldda16 xwa, 50588
	and wa, 0x102
	jr z, AudioInit_Dispatch_CheckVoiceChange
	calr AudioInit_CompareVoiceConfig
	jr AudioInit_Dispatch_CheckPartChange

AudioInit_Dispatch_CheckVoiceChange:
	ldda16 xwa, 50588
	bit 0, wa
	jr nz, AudioInit_Dispatch_SendVoiceChange
	ldda16 xwa, 50586
	bit 9, wa
	jr z, AudioInit_Dispatch_CheckPartChange

AudioInit_Dispatch_SendVoiceChange:
	calr AudioInit_CompareVoiceConfig

AudioInit_Dispatch_CheckPartChange:
	ldda16 xwa, 50588
	bit 8, wa
	jr nz, AudioInit_Dispatch_SendPartChange
	ldda16 xwa, 50586
	and wa, 0x7000
	jr z, AudioInit_Dispatch_CheckMisc

AudioInit_Dispatch_SendPartChange:
	calr AudioInit_ComparePriorityTable

AudioInit_Dispatch_CheckMisc:
	ldda16 xwa, 50588
	bit 2, wa
	call_24 nz, 0xFDFF5D
	ldda16 xwa, 50588
	bit 3, wa
	call_24 nz, 0xFE0023
	ldda16 xwa, 50588
	bit 6, wa
	call_24 nz, 0xFE013E
	ldda16 xwa, 50588
	bit 4, wa
	call_24 nz, 0xFE019B
	ldda16 xwa, 50586
	bit 13, wa
	jr z, AudioInit_Dispatch_CheckToneRefresh
	ldda16 xwa, 50582
	bit 4, wa
	jr z, AudioInit_Dispatch_RefreshTone

AudioInit_Dispatch_CheckToneRefresh:
	ldda16 xwa, 50586
	bit 12, wa
	jr z, AudioInit_Dispatch_CheckVoiceAssign

AudioInit_Dispatch_RefreshTone:
	call Voice_UpdatePlayModeState
	cp l, 0xFF
	call_24 nz, 0xFE12B8

AudioInit_Dispatch_CheckVoiceAssign:
	ldda16 xwa, 50586
	bit 14, wa
	jr z, AudioInit_Dispatch_Finalize
	call NoteMap_FindBestMatch
	cp l, 0xFF
	call_24 nz, 0xFE12FC

AudioInit_Dispatch_Finalize:
	call VoiceEvent_HandlerTable
	ld xiy, 0xC1FE
	ld xix, 0xC364
	ldw bc, 0xB3
	ldirw
	stdi16 50588, 0
	stdi16 50586, 0
	ret

AudioInit_QueueCommand:
	dec 6, xsp
	ld (xsp), e
	ld (xsp + 2), c
	ld (xsp + 4), a
	cpdi16 50378, 49
	jr c, AudioInit_QueueCommand_Write
	call VoiceEvent_HandlerTable
	stdi16 50378, 0

AudioInit_QueueCommand_Write:
	ldda16 xwa, 50378
	sll wa, 2
	ldada xbc, 50380
	ld de, wa
	extz xde
	add xde, xbc
	ld a, (xsp + 4)
	ld (xde), a
	ldda16 xwa, 50378
	sll wa, 2
	ldada xbc, 50381
	ld de, wa
	extz xde
	add xde, xbc
	ld a, (xsp + 2)
	ld (xde), a
	ldda16 xwa, 50378
	sll wa, 2
	ldada xbc, 50382
	ld de, wa
	extz xde
	add xde, xbc
	ld a, (xsp)
	ld (xde), a
	ldda16 xwa, 50378
	sll wa, 2
	ldada xbc, 50383
	ld de, wa
	extz xde
	add xde, xbc
	ld a, (xsp + 10)
	ld (xde), a
	incdi16 1, 50378
	inc 6, xsp
	retd 0x2

AudioInit_ComparePartStates:
	pushw iz
	ldda16 xwa, 50588
	bit 3, wa
	jrl z, AudioInit_ComparePanState
	lds iz, 0
	cp iz, 0x1A
	jrl nc, AudioInit_PartCompare_CheckGlobalBits

AudioInit_PartCompare_Loop:
	ld wa, iz
	ldada xbc, 49698
	ld de, wa
	extz xde
	add xde, xbc
	ld wa, iz
	ldada xbc, 50056
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	cp a, (xde)
	jr z, AudioInit_PartCompare_SameVoice
	ldto_berp A, 0xF8
	ld l, a
	extz hl
	ld wa, iz
	ldada xbc, 49698
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	ld e, a
	extz de
	ld wa, iz
	ldada xbc, 50056
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	extz wa
	pushw wa
	ld bc, hl
	lds wa, 0
	calr AudioInit_QueueCommand
	jr AudioInit_PartCompare_Next

AudioInit_PartCompare_SameVoice:
	ld wa, iz
	ldada xbc, 49698
	extz xwa
	add xwa, xbc
	cp (xwa), 0xFF
	jr z, AudioInit_PartCompare_Next
	ld wa, iz
	add wa, wa
	ldada xbc, 50312
	extz xwa
	add xwa, xbc
	ldcfm 6, (xwa)
	scc8 c, e
	ld wa, iz
	add wa, wa
	ldada xbc, 49954
	extz xwa
	add xwa, xbc
	ldcfm 6, (xwa)
	scc8 c, a
	cp a, e
	jr z, AudioInit_PartCompare_Next
	ldto_berp A, 0xF8
	ld e, a
	extz de
	ld wa, iz
	ldada xbc, 49698
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	extz wa
	pushw wa
	ld bc, de
	lds wa, 0
	ldw de, 0xFF
	calr AudioInit_QueueCommand

AudioInit_PartCompare_Next:
	inc 1, iz
	cp iz, 0x1A
	jrl c, AudioInit_PartCompare_Loop

AudioInit_PartCompare_CheckGlobalBits:
	ldcf_dd16 4, 0x88, 0xC4
	scc8 c, a
	ldcf_dd16 4, 0x22, 0xC3
	scc8 c, c
	cp c, a
	jr z, AudioInit_ComparePanState
	ldda8 a, 49698
	extz wa
	pushw wa
	lds wa, 0
	lds bc, 0
	ldw de, 0xFF
	calr AudioInit_QueueCommand

AudioInit_ComparePanState:
	ldda16 xwa, 50588
	bit 8, wa
	jr z, AudioInit_PartCompare_Return
	ldda8 a, 50202
	cpda8 a, 49844
	jr z, AudioInit_PartCompare_Return
	ldda8 a, 49844
	ld c, a
	extz bc
	ldda8 a, 50202
	extz wa
	pushw wa
	ld de, bc
	lds wa, 1
	lds bc, 0
	calr AudioInit_QueueCommand

AudioInit_PartCompare_Return:
	popw iz
	ret

AudioInit_CompareVoiceConfig:
	ldb e, 0x0
	ldb l, 0x0
	ldb d, 0x1
	ldda16 xwa, 50588
	bit 1, wa
	jr z, AudioInit_VoiceCompare_BothFF
	ldda8 a, 50021
	cpda8 a, 49663
	jr z, AudioInit_VoiceCompare_BothFF
	ldda8 a, 49663
	ld c, a
	extz bc
	ldda8 a, 50021
	extz wa
	pushw wa
	ld de, bc
	lds wa, 2
	lds bc, 1
	calr AudioInit_QueueCommand
	bitda 3, 50020
	ret z
	bitda 3, 49662
	ret nz
	pushw 0x8
	lds wa, 2
	lds bc, 0
	lds de, 0
	calr AudioInit_QueueCommand
	ret

AudioInit_VoiceCompare_BothFF:
	cpdi8 49663, 255
	jrl nz, AudioInit_VoiceCompare_NotBothFF
	cpdi8 50021, 255
	jrl nz, AudioInit_VoiceCompare_NotBothFF
	ldda8 a, 50020
	xorda8 a, 49662
	ld c, a
	ldda8 a, 49662
	and a, c
	ld e, a
	ldda8 a, 50020
	xorda8 a, 49662
	ld c, a
	ldda8 a, 50020
	and a, c
	ld l, a
	lds ix, 0
	cps ix, 6
	jrl nc, AudioInit_VoiceCompare_BuildCmd

AudioInit_VoiceCompare_LayerLoop:
	ld wa, ix
	sll wa, 2
	ldada xbc, 49858
	extz xwa
	add xwa, xbc
	bitm 7, (xwa)
	jr z, AudioInit_VoiceCompare_LayerNext
	ld wa, ix
	sll wa, 2
	ldada xbc, 50216
	extz xwa
	add xwa, xbc
	ld h, (xwa)
	res 7, h
	ld wa, ix
	sll wa, 2
	ldada xbc, 49858
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	res 7, a
	cp a, h
	jr nz, AudioInit_VoiceCompare_LayerChanged
	ld wa, ix
	sll wa, 2
	add wa, 0xC4
	ldada xbc, 50021
	extz xwa
	add xwa, xbc
	ld h, (xwa)
	srl h, 1
	ld wa, ix
	sll wa, 2
	add wa, 0xC4
	ldada xbc, 49663
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	srl a, 1
	cp a, h
	jr z, AudioInit_VoiceCompare_LayerNext

AudioInit_VoiceCompare_LayerChanged:
	ldda8 a, 49662
	andda8 a, 50020
	and a, d
	jr z, AudioInit_VoiceCompare_LayerNext
	or e, d
	or l, d

AudioInit_VoiceCompare_LayerNext:
	add d, d
	inc 1, ix
	cps ix, 6
	jrl c, AudioInit_VoiceCompare_LayerLoop
	jr AudioInit_VoiceCompare_BuildCmd

AudioInit_VoiceCompare_NotBothFF:
	cpdi8 49663, 255
	jr z, AudioInit_VoiceCompare_BuildCmd
	cpdi8 50021, 255
	jr z, AudioInit_VoiceCompare_BuildCmd
	ldda8 a, 50020
	xorda8 a, 49662
	ld c, a
	ldda8 a, 49662
	and a, c
	and a, 0xF8
	ld e, a
	ldda8 a, 50020
	xorda8 a, 49662
	ld c, a
	ldda8 a, 50020
	and a, c
	and a, 0xF8
	ld l, a
	bitda 7, 49870
	jr z, AudioInit_VoiceCompare_BuildCmd
	ldda8 a, 50228
	res 7, a
	ldda8 c, 49870
	res 7, c
	cp c, a
	jr nz, AudioInit_VoiceCompare_SetBit3
	ldda8 a, 50229
	srl a, 1
	ldda8 c, 49871
	srl c, 1
	cp c, a
	jr z, AudioInit_VoiceCompare_BuildCmd

AudioInit_VoiceCompare_SetBit3:
	set 3, e
	set 3, l

AudioInit_VoiceCompare_BuildCmd:
	cps e, 0
	jr nz, AudioInit_VoiceCompare_QueueCmd
	cps l, 0
	jr z, AudioInit_VoiceCompare_PanCheck

AudioInit_VoiceCompare_QueueCmd:
	ld c, e
	extz bc
	ld a, l
	extz wa
	pushw wa
	ld de, bc
	lds wa, 2
	lds bc, 0
	calr AudioInit_QueueCommand

AudioInit_VoiceCompare_PanCheck:
	ldda8 a, 50202
	cpda8 a, 49844
	ret z
	ldda8 a, 49844
	ld c, a
	extz bc
	ldda8 a, 50202
	extz wa
	pushw wa
	ld de, bc
	lds wa, 2
	lds bc, 2
	calr AudioInit_QueueCommand
	ret

AudioInit_CompareChannelMappings:
	pushw iz
	ldda16 xwa, 50588
	and wa, 0xC0
	jrl z, AudioInit_ChannelMap_CheckPan
	lds iz, 0
	cp iz, 0x10
	jrl nc, AudioInit_ChannelMap_CheckPan

AudioInit_ChannelMap_Loop:
	ld wa, iz
	ldada xbc, 49826
	ld de, wa
	extz xde
	add xde, xbc
	ld wa, iz
	ldada xbc, 50184
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	cp a, (xde)
	jr z, AudioInit_ChannelMap_CheckPrimary
	ldto_berp A, 0xF8
	ld l, a
	extz hl
	ld wa, iz
	ldada xbc, 49826
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	ld e, a
	extz de
	ld wa, iz
	ldada xbc, 50184
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	extz wa
	pushw wa
	ld bc, hl
	lds wa, 3
	calr AudioInit_QueueCommand

AudioInit_ChannelMap_CheckPrimary:
	ld wa, iz
	ldada xbc, 49794
	ld de, wa
	extz xde
	add xde, xbc
	ld wa, iz
	ldada xbc, 50152
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	cp a, (xde)
	jr z, AudioInit_ChannelMap_Next
	ldto_berp A, 0xF8
	ld l, a
	extz hl
	ld wa, iz
	ldada xbc, 49794
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	ld e, a
	extz de
	ld wa, iz
	ldada xbc, 50152
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	extz wa
	pushw wa
	ld bc, hl
	lds wa, 4
	calr AudioInit_QueueCommand

AudioInit_ChannelMap_Next:
	inc 1, iz
	cp iz, 0x10
	jrl c, AudioInit_ChannelMap_Loop

AudioInit_ChannelMap_CheckPan:
	ldda16 xwa, 50588
	bit 8, wa
	jr z, AudioInit_ChannelMap_Return
	ldda8 a, 50202
	cpda8 a, 49844
	jr z, AudioInit_ChannelMap_Return
	ldda8 a, 49844
	ld c, a
	extz bc
	ldda8 a, 50202
	extz wa
	pushw wa
	ld de, bc
	lds wa, 5
	lds bc, 0
	calr AudioInit_QueueCommand

AudioInit_ChannelMap_Return:
	popw iz
	ret

AudioInit_ComparePriorityTable:
	pushw iz
	lds iz, 0
	cps iz, 3
	jr nc, AudioInit_Priority_Return

AudioInit_Priority_Loop:
	ld wa, iz
	ldada xbc, 49850
	ld de, wa
	extz xde
	add xde, xbc
	ld wa, iz
	ldada xbc, 50208
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	cp a, (xde)
	jr z, AudioInit_Priority_Next
	ldto_berp A, 0xF8
	ld l, a
	extz hl
	ld wa, iz
	ldada xbc, 49850
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	ld e, a
	extz de
	ld wa, iz
	ldada xbc, 50208
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	extz wa
	pushw wa
	ld bc, hl
	lds wa, 6
	calr AudioInit_QueueCommand

AudioInit_Priority_Next:
	inc 1, iz
	cps iz, 3
	jr c, AudioInit_Priority_Loop

AudioInit_Priority_Return:
	popw iz
	ret

AudioInit_ComparePartAssignment:
	pushw iz
	lds iz, 0
	cp iz, 0x1A
	jrl nc, AudioInit_PartAssign_Return

AudioInit_PartAssign_Loop:
	ld wa, iz
	ldada xbc, 49666
	ld de, wa
	extz xde
	add xde, xbc
	ld wa, iz
	ldada xbc, 50024
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	cp a, (xde)
	jrl z, AudioInit_PartAssign_Next
	cps iz, 2
	jr nz, AudioInit_PartAssign_CheckIdx15
	ld wa, iz
	ldada xbc, 49666
	extz xwa
	add xwa, xbc
	cp (xwa), 0xFF
	jr z, AudioInit_PartAssign_CheckIdx15
	cpdi8 49850, 2
	jr nz, AudioInit_PartAssign_CheckIdx15
	cpdi8 50208, 2
	jr nz, AudioInit_PartAssign_Next

AudioInit_PartAssign_CheckIdx15:
	cp iz, 0x15
	jr nz, AudioInit_PartAssign_CheckIdx16
	ld wa, iz
	ldada xbc, 49666
	extz xwa
	add xwa, xbc
	cp (xwa), 0xFF
	jr z, AudioInit_PartAssign_CheckIdx16
	cpdi8 49850, 21
	jr nz, AudioInit_PartAssign_CheckIdx16
	cpdi8 50208, 21
	jr nz, AudioInit_PartAssign_Next

AudioInit_PartAssign_CheckIdx16:
	cp iz, 0x16
	jr nz, AudioInit_PartAssign_QueueChange
	ld wa, iz
	ldada xbc, 49666
	extz xwa
	add xwa, xbc
	cp (xwa), 0xFF
	jr z, AudioInit_PartAssign_QueueChange
	cpdi8 49851, 22
	jr nz, AudioInit_PartAssign_QueueChange
	cpdi8 50209, 22
	jr nz, AudioInit_PartAssign_Next

AudioInit_PartAssign_QueueChange:
	ldto_berp A, 0xF8
	ld l, a
	extz hl
	ld wa, iz
	ldada xbc, 49666
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	ld e, a
	extz de
	ld wa, iz
	ldada xbc, 50024
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	extz wa
	pushw wa
	ld bc, hl
	lds wa, 7
	calr AudioInit_QueueCommand

AudioInit_PartAssign_Next:
	inc 1, iz
	cp iz, 0x1A
	jrl c, AudioInit_PartAssign_Loop

AudioInit_PartAssign_Return:
	popw iz
	ret

AudioInit_ComparePartConfig:
	pushw iz
	lds iz, 0
	cp iz, 0x1A
	jrl nc, AudioInit_PartConfig_Return

AudioInit_PartConfig_Loop:
	ld wa, iz
	ldada xbc, 49698
	ld de, wa
	extz xde
	add xde, xbc
	ld wa, iz
	ldada xbc, 50056
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	cp a, (xde)
	jr z, AudioInit_PartConfig_SameVoice
	ldto_berp A, 0xF8
	ld l, a
	extz hl
	ld wa, iz
	ldada xbc, 49698
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	ld e, a
	extz de
	ld wa, iz
	ldada xbc, 50056
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	extz wa
	pushw wa
	ld bc, hl
	ldw wa, 0x8
	calr AudioInit_QueueCommand
	jrl AudioInit_PartConfig_Next

AudioInit_PartConfig_SameVoice:
	cp iz, 0x19
	jr nz, AudioInit_PartConfig_NotReverb
	ldda8 a, 49852
	extz wa
	ldada xbc, 49698
	extz xwa
	add xwa, xbc
	cp (xwa), 0xFF
	jrl z, AudioInit_PartConfig_Next
	ld wa, iz
	add wa, wa
	ldada xbc, 50312
	extz xwa
	add xwa, xbc
	ldcfm 5, (xwa)
	scc8 c, e
	ld wa, iz
	add wa, wa
	ldada xbc, 49954
	extz xwa
	add xwa, xbc
	ldcfm 5, (xwa)
	scc8 c, a
	cp a, e
	jr z, AudioInit_PartConfig_Next
	ldto_berp A, 0xF8
	ld e, a
	extz de
	ldda8 a, 49852
	extz wa
	ldada xbc, 49698
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	extz wa
	pushw wa
	ld bc, de
	ldw wa, 0x8
	ldw de, 0xFF
	calr AudioInit_QueueCommand
	jr AudioInit_PartConfig_Next

AudioInit_PartConfig_NotReverb:
	ld wa, iz
	ldada xbc, 49698
	extz xwa
	add xwa, xbc
	cp (xwa), 0xFF
	jr z, AudioInit_PartConfig_Next
AudioInit_PartConfig_CheckCarry:
	ld wa, iz
	add wa, wa
	ldada xbc, 50312
	extz xwa
	add xwa, xbc
	ldcfm 5, (xwa)
	scc8 c, e
	ld wa, iz
	add wa, wa
	ldada xbc, 49954
	extz xwa
	add xwa, xbc
	ldcfm 5, (xwa)
	scc8 c, a
	cp a, e
	jr z, AudioInit_PartConfig_Next
	ldto_berp A, 0xF8
	ld e, a
	extz de
	ld wa, iz
	ldada xbc, 49698
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	extz wa
	pushw wa
	ld bc, de
	ldw wa, 0x8
	ldw de, 0xFF
	calr AudioInit_QueueCommand

AudioInit_PartConfig_Next:
	inc 1, iz
	cp iz, 0x1A
	jrl c, AudioInit_PartConfig_Loop

AudioInit_PartConfig_Return:
	popw iz
	ret

AudioInit_CompareChannelConfig:
	pushw iz
	lds iz, 0
	cp iz, 0x10
	jr nc, AudioInit_ChannelConfig_Return

AudioInit_ChannelConfig_Loop:
	ld wa, iz
	ldada xbc, 49794
	ld de, wa
	extz xde
	add xde, xbc
	ld wa, iz
	ldada xbc, 50152
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	cp a, (xde)
	jr z, AudioInit_ChannelConfig_Next
	ldto_berp A, 0xF8
	ld l, a
	extz hl
	ld wa, iz
	ldada xbc, 49794
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	ld e, a
	extz de
	ld wa, iz
	ldada xbc, 50152
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	extz wa
	pushw wa
	ld bc, hl
	ldw wa, 0x9
	calr AudioInit_QueueCommand

AudioInit_ChannelConfig_Next:
	inc 1, iz
	cp iz, 0x10
	jr c, AudioInit_ChannelConfig_Loop

AudioInit_ChannelConfig_Return:
	popw iz
	ret

AudioInit_CompareVolumeTable:
	pushw iz
	lds iz, 0
	cp iz, 0x1A
	jr nc, AudioInit_Volume_Return

AudioInit_Volume_Loop:
	ld wa, iz
	ldada xbc, 49730
	ld de, wa
	extz xde
	add xde, xbc
	ld wa, iz
	ldada xbc, 50088
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	cp a, (xde)
	jr z, AudioInit_Volume_Next
	ldto_berp A, 0xF8
	ld l, a
	extz hl
	ld wa, iz
	ldada xbc, 49730
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	ld e, a
	extz de
	ld wa, iz
	ldada xbc, 50088
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	extz wa
	pushw wa
	ld bc, hl
	ldw wa, 0xA
	calr AudioInit_QueueCommand

AudioInit_Volume_Next:
	inc 1, iz
	cp iz, 0x1A
	jr c, AudioInit_Volume_Loop

AudioInit_Volume_Return:
	popw iz
	ret

AudioInit_InitPartSendLevels:
	lds	de, 0
	cp	de, 161
	jr	nc, 38
	ld	wa, de
	add	wa, wa
	ldada	xbc, 50730
	extz	xwa
	add	xwa, xbc
	ld	(xwa), 16
	ld	wa, de
	add	wa, wa
	ldada	xbc, 50731
	extz	xwa
	add	xwa, xbc
	ld	(xwa), 0
	inc	1, de
	cp	de, 161
	jr	c, -38
	stdi8	51818, 8
	stdi8	51819, 0
	stdi8	51820, 8
	stdi8	51821, 0
	stdi8	51822, 16
	stdi8	51823, 0
	ret

