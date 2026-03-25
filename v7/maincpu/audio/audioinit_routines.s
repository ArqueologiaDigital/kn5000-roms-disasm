; v7: First part replaced by .incbin in dsp_config_sysex.s
AudioInit_VoiceNotAssigned:
	ldi_erpb 0xe2, 0xff

AudioInit_CheckVoiceChanged:
	ld a, d
	extz wa
	lda_24 xix, (AudioInit_VoiceDispatch_Table_0x1AA)
	cpib_sri 0x07, 0xf0, 0xe0, 0xff
	jr z, AudioInit_VoiceUnchanged
	ld a, e
	extz wa
	add wa, wa
	lda_24 xix, (SystemConfig_PointerTable_0x56)
	ldw_sri WA, 0x07, 0xf0, 0xe0
	ld ix, hl
	or ix, bc
	and ix, wa
	jr nz, AudioInit_CheckGroupA

AudioInit_VoiceUnchanged:
	ld a, e
	extz wa
	lda_d16 xix, (0xc282)
	extz xwa
	add xwa, xix
	ld (xwa), 0xff
	ld a, e
	extz wa
	lda_d16 xix, (0xc2a2)
	extz xwa
	add xwa, xix
	ld (xwa), 0xff
	jrl AudioInit_ChannelLoop_Next

AudioInit_CheckGroupA:
	ldw_d16 xwa, (0xc598)
	bit 8, wa
	jrl z, AudioInit_CheckGroupB_Channel
	ld a, e
	extz wa
	add wa, wa
	lda_24 xix, (SystemConfig_PointerTable_0x56)
	ldw_sri WA, 0x07, 0xf0, 0xe0
	and wa, hl
	jrl z, AudioInit_CheckGroupB_Channel
	ld a, d
	cp a, 0xe
	jr z, AudioInit_GroupA_TypeE
	cp a, 0xd
	jrl nz, AudioInit_GroupA_OtherType
	ordi16 0xc598, 32
	ld a, e
	extz wa
	lda_d16 xix, (0xc282)
	ld iy, wa
	extz xiy
	add xiy, xix
	ld a, d
	extz wa
	lda_24 xix, (AudioInit_VoiceDispatch_Table_0x1AA)
	ldb_sri A, 0x07, 0xf0, 0xe0
	ld (xiy), a
	ld a, e
	extz wa
	lda_d16 xix, (0xc292)
	ld iy, wa
	extz xiy
	add xiy, xix
	ld a, d
	extz wa
	lda_24 xix, (AudioInit_VoiceDispatch_Table_0x1AA)
	ldb_sri A, 0x07, 0xf0, 0xe0
	ld (xiy), a
	jrl AudioInit_CheckGroupB_Channel

AudioInit_GroupA_TypeE:
	ordi16 0xc598, 64
	ld a, e
	extz wa
	lda_d16 xix, (0xc282)
	ld iy, wa
	extz xiy
	add xiy, xix
	ld a, d
	extz wa
	lda_24 xix, (AudioInit_VoiceDispatch_Table_0x1AA)
	ldb_sri A, 0x07, 0xf0, 0xe0
	ld (xiy), a
	ld a, e
	extz wa
	lda_d16 xix, (0xc292)
	ld iy, wa
	extz xiy
	add xiy, xix
	ld a, d
	extz wa
	lda_24 xix, (AudioInit_VoiceDispatch_Table_0x1AA)
	ldb_sri A, 0x07, 0xf0, 0xe0
	ld (xiy), a
	jrl AudioInit_CheckGroupB_Channel

AudioInit_GroupA_OtherType:
	cpdi8 (0x8d36), 138
	jr nz, AudioInit_GroupA_DefaultMapping
	ld a, e
	extz wa
	lda_d16 xix, (0xc282)
	ld iy, wa
	extz xiy
	add xiy, xix
	ld a, d
	extz wa
	lda_24 xix, (AudioInit_VoiceDispatch_Table_0x1AA)
	ldb_sri A, 0x07, 0xf0, 0xe0
	ld (xiy), a
	ld a, e
	extz wa
	add wa, wa
	lda_24 xix, (SystemConfig_PointerTable_0x56)
	ldw_sri WA, 0x07, 0xf0, 0xe0
	andda16 xwa, 3928
	jr z, AudioInit_GroupA_NoAuxMapping
	ld a, e
	extz wa
	lda_d16 xix, (0xc292)
	ld iy, wa
	extz xiy
	add xiy, xix
	ld a, d
	extz wa
	lda_24 xix, (AudioInit_VoiceDispatch_Table_0x1AA)
	ldb_sri A, 0x07, 0xf0, 0xe0
	ld (xiy), a
	jr AudioInit_StoreChannelMapping

AudioInit_GroupA_NoAuxMapping:
	ld a, e
	extz wa
	lda_d16 xix, (0xc292)
	ld iy, wa
	extz xiy
	add xiy, xix
	ld (xiy), 0xff
	jr AudioInit_StoreChannelMapping

AudioInit_GroupA_DefaultMapping:
	ld a, e
	extz wa
	lda_d16 xix, (0xc282)
	ld iy, wa
	extz xiy
	add xiy, xix
	ld a, d
	extz wa
	lda_24 xix, (AudioInit_VoiceDispatch_Table_0x1AA)
	ldb_sri A, 0x07, 0xf0, 0xe0
	ld (xiy), a
	ld a, e
	extz wa
	add wa, wa
	lda_24 xix, (SystemConfig_PointerTable_0x56)
	ldw_sri WA, 0x07, 0xf0, 0xe0
	andda16 xwa, 0xf1d0
	jr z, AudioInit_GroupA_NoSecondary
	ld a, e
	extz wa
	lda_d16 xix, (0xc292)
	ld iy, wa
	extz xiy
	add xiy, xix
	ld a, d
	extz wa
	lda_24 xix, (AudioInit_VoiceDispatch_Table_0x1AA)
	ldb_sri A, 0x07, 0xf0, 0xe0
	ld (xiy), a
	jr AudioInit_StoreChannelMapping

AudioInit_GroupA_NoSecondary:
	ld a, e
	extz wa
	lda_d16 xix, (0xc292)
	ld iy, wa
	extz xiy
	add xiy, xix
	ld (xiy), 0xff

AudioInit_StoreChannelMapping:
	ld a, e
	extz wa
	lda_d16 xix, (0xc2a2)
	ld iy, wa
	extz xiy
	add xiy, xix
	stb_erp A, 0xe2
	ld (xiy), a

AudioInit_CheckGroupB_Channel:
	ldw_d16 xwa, (0xc598)
	bit 9, wa
	jrl z, AudioInit_ChannelLoop_Next
	ld a, e
	extz wa
	add wa, wa
	lda_24 xix, (SystemConfig_PointerTable_0x56)
	ldw_sri WA, 0x07, 0xf0, 0xe0
	and wa, bc
	jrl z, AudioInit_ChannelLoop_Next
	incm 1, (xsp)
	cpdi8 (0xc59e), 255
	jr nz, AudioInit_GroupB_CheckType
	ld a, d
	extz wa
	lda_24 xix, (AudioInit_VoiceDispatch_Table_0x1AA)
	ldmm_srib 0x07, 0xf0, 0xe0, 0x9e, 0xc5

AudioInit_GroupB_CheckType:
	ld a, d
	cp a, 0x10
	jrl z, AudioInit_GroupB_Type10
	cp a, 0xe
	jr z, AudioInit_GroupB_TypeE
	cp a, 0xd
	jrl nz, AudioInit_GroupB_DefaultMapping
	ordi16 0xc598, 2
	ld a, e
	extz wa
	lda_d16 xix, (0xc282)
	ld iy, wa
	extz xiy
	add xiy, xix
	ld a, d
	extz wa
	lda_24 xix, (AudioInit_VoiceDispatch_Table_0x1AA)
	ldb_sri A, 0x07, 0xf0, 0xe0
	ld (xiy), a
	ld a, e
	extz wa
	lda_d16 xix, (0xc292)
	ld iy, wa
	extz xiy
	add xiy, xix
	ld a, d
	extz wa
	lda_24 xix, (AudioInit_VoiceDispatch_Table_0x1AA)
	ldb_sri A, 0x07, 0xf0, 0xe0
	ld (xiy), a
	jrl AudioInit_ChannelLoop_Next

AudioInit_GroupB_TypeE:
	ordi16 0xc598, 4
	ld a, e
	extz wa
	lda_d16 xix, (0xc282)
	ld iy, wa
	extz xiy
	add xiy, xix
	ld a, d
	extz wa
	lda_24 xix, (AudioInit_VoiceDispatch_Table_0x1AA)
	ldb_sri A, 0x07, 0xf0, 0xe0
	ld (xiy), a
	ld a, e
	extz wa
	lda_d16 xix, (0xc292)
	ld iy, wa
	extz xiy
	add xiy, xix
	ld a, d
	extz wa
	lda_24 xix, (AudioInit_VoiceDispatch_Table_0x1AA)
	ldb_sri A, 0x07, 0xf0, 0xe0
	ld (xiy), a
	jr AudioInit_ChannelLoop_Next

AudioInit_GroupB_Type10:
	ordi16 0xc598, 8
	ld a, e
	extz wa
	lda_d16 xix, (0xc282)
	extz xwa
	add xwa, xix
	ld (xwa), 0xff
	ld a, e
	extz wa
	lda_d16 xix, (0xc292)
	extz xwa
	add xwa, xix
	ld (xwa), 0xff
	jr AudioInit_ChannelLoop_Next

AudioInit_GroupB_DefaultMapping:
	ld a, e
	extz wa
	lda_d16 xix, (0xc282)
	ld iy, wa
	extz xiy
	add xiy, xix
	ld a, d
	extz wa
	lda_24 xix, (AudioInit_VoiceDispatch_Table_0x1AA)
	ldb_sri A, 0x07, 0xf0, 0xe0
	ld (xiy), a
	ld a, e
	extz wa
	lda_d16 xix, (0xc292)
	ld iy, wa
	extz xiy
	add xiy, xix
	ld a, d
	extz wa
	lda_24 xix, (AudioInit_VoiceDispatch_Table_0x1AA)
	ldb_sri A, 0x07, 0xf0, 0xe0
	ld (xiy), a

AudioInit_ChannelLoop_Next:
	ordi16 0xc59c, 192
	inc 1, e
	cp e, 0x10
	jrl c, AudioInit_ChannelLoop_Body

AudioInit_ChannelLoop_Done:
	cpw (xsp), 0x1
	jr nz, AudioInit_SetChangedFlag
	ordi16 0xc598, 1

AudioInit_SetChangedFlag:
	bitda 3, (0x28b3)
	jr z, AudioInit_CheckExternalBit3
	anddi16 0xc598, 0xfdff

AudioInit_CheckExternalBit3:
	ldw_d16 xwa, (0xc598)
	bit 6, wa
	jr z, AudioInit_NoTypeE_CheckD
	ldb_d8 a, (0xfc5e)
	and a, 0x7
	extz wa
	add wa, wa
	lda_24 xbc, (AudioInit_VoiceDispatch_Table_0x130)
	ldw_sri DE, 0x07, 0xe4, 0xe0
	ldb_d8 a, (0xfc5d)
	and a, 0x8
	extz wa
	add wa, wa
	lda_24 xbc, (AudioInit_VoiceDispatch_Table_0x130)
	or_sriw_rm DE, 0x07, 0xe4, 0xe0
	jr AudioInit_ApplyOutputRouting

AudioInit_NoTypeE_CheckD:
	ldw_d16 xwa, (0xc598)
	and wa, 0x22
	cp wa, 0x20
	jr nz, AudioInit_DefaultOutputRouting
	lds de, 2
	ldb_d8 a, (0xfc5d)
	and a, 0x8
	extz wa
	add wa, wa
	lda_24 xbc, (AudioInit_VoiceDispatch_Table_0x130)
	or_sriw_rm DE, 0x07, 0xe4, 0xe0
	jr AudioInit_ApplyOutputRouting

AudioInit_DefaultOutputRouting:
	ldb_d8 a, (0xfc5d)
	and a, 0xf
	extz wa
	add wa, wa
	lda_24 xbc, (AudioInit_VoiceDispatch_Table_0x130)
	ldw_sri DE, 0x07, 0xe4, 0xe0

AudioInit_ApplyOutputRouting:
	anddi16 0xc596, 0xffe8
	orddm16 0xc596, xde
	inc 2, xsp
	ret

AudioInit_SelectPriority:
	ldb_d8 a, (0x379b)
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
	stdi8 (0xc252), 0
	stdi8 (0xc253), 255
	stdi8 (0xc254), 255
	stdi8 (0xc255), 255
	stdi8 (0xc256), 255
	ordi16 0xc59c, 16
	ret

AudioInit_Priority_Mode2:
	stdi8 (0xc252), 255
	stdi8 (0xc253), 1
	stdi8 (0xc254), 255
	stdi8 (0xc255), 255
	stdi8 (0xc256), 255
	ordi16 0xc59c, 16
	ret

AudioInit_Priority_Mode4:
	stdi8 (0xc252), 255
	stdi8 (0xc253), 255
	stdi8 (0xc254), 2
	stdi8 (0xc255), 255
	stdi8 (0xc256), 255
	ordi16 0xc59c, 16
	ret

AudioInit_Priority_Mode8:
	stdi8 (0xc252), 255
	stdi8 (0xc253), 255
	stdi8 (0xc254), 255
	stdi8 (0xc255), 3
	stdi8 (0xc256), 255
	ordi16 0xc59c, 16
	ret

AudioInit_Priority_Mode10:
	stdi8 (0xc252), 255
	stdi8 (0xc253), 255
	stdi8 (0xc254), 255
	stdi8 (0xc255), 255
	stdi8 (0xc256), 4
	ordi16 0xc59c, 16
	ret

AudioInit_Priority_Default:
	stdi8 (0xc252), 255
	stdi8 (0xc253), 255
	stdi8 (0xc254), 255
	stdi8 (0xc255), 255
	stdi8 (0xc256), 255
	ordi16 0xc59c, 16
	ret

AudioInit_CheckMIDIStatus:
	cpdi8 (0x7f0b), 0
	jr z, AudioInit_MIDIDisabled
	stdi8 (0xc279), 0
	stdi8 (0xc27a), 255
	ordi16 0xc59c, 32
	ret

AudioInit_MIDIDisabled:
	stdi8 (0xc279), 255
	stdi8 (0xc27a), 255
	ordi16 0xc59c, 32
	ret

AudioInit_RefreshToneBank:
	pushw iz
	ldw_d16 xiz, (0xc596)
	anddi16 0xc596, 0xffef
	call Voice_UpdatePlayModeState
	cp l, 0xff
	call_24 nz, VoiceEvent_AllocAllLayers
	call NoteMap_FindBestMatch
	cp l, 0xff
	call_24 nz, VoiceEvent_DispatchTable
	stda16 (0xc596), xiz
	popw iz
	ret

AudioInit_VoiceRoutingTable:
	.byte 0x0e, 0x0e, 0x0e, 0x0e, 0x0e, 0x0e, 0x0e, 0xf1
	.byte 0xfe, 0xc1, 0x00, 0x00, 0xc1, 0xc2, 0xc2, 0x3e
	.byte 0x7f, 0xc1, 0xc3, 0xc2, 0x3c, 0x01, 0xc1, 0xc4
	.byte 0xc2, 0x3e, 0xfe, 0xc1, 0xc5, 0xc2, 0x3c, 0x01
	.byte 0xc1, 0xc6, 0xc2, 0x3e, 0x7f, 0xc1, 0xc7, 0xc2
	.byte 0x3c, 0x01, 0xc1, 0xc8, 0xc2, 0x3e, 0xfe, 0xc1
	.byte 0xc9, 0xc2, 0x3c, 0x01, 0xc1, 0xca, 0xc2, 0x3e
	.byte 0x7f, 0xc1, 0xcb, 0xc2, 0x3c, 0x01, 0xc1, 0xcc
	.byte 0xc2, 0x3e, 0xfe, 0xc1, 0xcd, 0xc2, 0x3c, 0x01
	.byte 0xc1, 0xce, 0xc2, 0x3e, 0x7f, 0xc1, 0xcf, 0xc2
	.byte 0x3c, 0x01, 0xc1, 0xd0, 0xc2, 0x3e, 0xfe, 0xc1
	.byte 0xd1, 0xc2, 0x3c, 0x01, 0xc1, 0xd2, 0xc2, 0x3e
	.byte 0x7f, 0xc1, 0xd3, 0xc2, 0x3c, 0x01, 0xc1, 0xd4
	.byte 0xc2, 0x3e, 0xfe, 0xc1, 0xd5, 0xc2, 0x3c, 0x01
	.byte 0xda, 0xa8, 0xda, 0xcf, 0x20, 0x00, 0xb0, 0xff
	.byte 0xda, 0x88, 0xd8, 0x80, 0xf1, 0xe2, 0xc2, 0x31
	.byte 0xe8, 0x12, 0xe9, 0x80, 0xb0, 0xb7, 0xda, 0x88
	.byte 0xd8, 0x80, 0xf1, 0xe2, 0xc2, 0x31, 0xe8, 0x12
	.byte 0xe9, 0x80, 0x80, 0x3c, 0x8f, 0xda, 0x88, 0xd8
	.byte 0x80, 0xf1, 0x22, 0xc3, 0x31, 0xe8, 0x12, 0xe9
	.byte 0x80, 0xb0, 0xb7, 0xda, 0x88, 0xd8, 0x80, 0xf1
	.byte 0x22, 0xc3, 0x31, 0xe8, 0x12, 0xe9, 0x80, 0xb0
	.byte 0xbe, 0xda, 0x88, 0xd8, 0x80, 0xf1, 0x22, 0xc3
	.byte 0x31, 0xe8, 0x12, 0xe9, 0x80, 0xb0, 0xbd, 0xda
	.byte 0x88, 0xd8, 0x80, 0xf1, 0x22, 0xc3, 0x31, 0xe8
	.byte 0x12, 0xe9, 0x80, 0xb0, 0xb4, 0xda, 0x88, 0xd8
	.byte 0x80, 0xf1, 0x22, 0xc3, 0x31, 0xe8, 0x12, 0xe9
	.byte 0x80, 0x80, 0x3c, 0xf1, 0xda, 0x88, 0xd8, 0x80
	.byte 0xd8, 0xc8, 0x24, 0x01, 0xf1, 0xff, 0xc1, 0x31
	.byte 0xe8, 0x12, 0xe9, 0x80, 0x80, 0x3c, 0x0f, 0xda
	.byte 0x61, 0xda, 0xcf, 0x20, 0x00, 0x67, 0x81, 0x0e

AudioInit_ConfigureVoiceRouting:
	anddi16 0xc596, 0xfeff
	ldw_d16 xwa, (0xc596)
	and wa, 0x3
	jrl z, AudioInit_Routing_NoActiveVoices
	ldw_d16 xwa, (0xc596)
	and wa, 0xa0
	cp wa, 0xa0
	jrl nz, AudioInit_Routing_NoGroupAB
	resda 2, 0xc1fe
	ordi16 0xc59c, 1
	stdi8 (0xc2ba), 2
	stdi8 (0xc2bb), 22
	stdi8 (0xc204), 255
	stdi8 (0xc218), 255
	ldw_d16 xwa, (0xc596)
	bit 9, wa
	jr z, AudioInit_Routing_CheckSplitMode
	ldb_d8 a, (0xfc5f)
	and a, 0xfc
	jr nz, AudioInit_Routing_SetOverrideFlag
	ldb_d8 a, (0xfc60)
	and a, 0xfc
	jr nz, AudioInit_Routing_SetOverrideFlag
	bitda 5, (0xf9f7)
	jrl nz, AudioInit_Routing_SkipToEnd
	stdi8 (0xc204), 2
	jrl AudioInit_Routing_Done

AudioInit_Routing_SetOverrideFlag:
	ordi16 0xc596, 256
	jrl AudioInit_Routing_Done

AudioInit_Routing_CheckSplitMode:
	bitda 1, (0xfc5f)
	jr z, AudioInit_Routing_NoSplit
	ldb_d8 a, (0xfc5f)
	and a, 0xfc
	jr nz, AudioInit_Routing_SplitOverride
	ldb_d8 a, (0xfc60)
	and a, 0xfc
	jr nz, AudioInit_Routing_SplitOverride
	bitda 5, (0xf9f7)
	jr nz, AudioInit_Routing_SplitCheckAux
	stdi8 (0xc204), 2

AudioInit_Routing_SplitCheckAux:
	bitda 5, (0xfbb1)
	jrl nz, AudioInit_Routing_SkipToEnd
	stdi8 (0xc218), 22
	jrl AudioInit_Routing_Done

AudioInit_Routing_SplitOverride:
	ordi16 0xc596, 256
	jrl AudioInit_Routing_Done

AudioInit_Routing_NoSplit:
	ldb_d8 a, (0xfc5f)
	and a, 0xfc
	jr nz, AudioInit_Routing_CheckTypeEDFlags
	ldb_d8 a, (0xfc60)
	and a, 0xfc
	jr nz, AudioInit_Routing_CheckTypeEDFlags
	bitda 5, (0xf9f7)
	jr nz, AudioInit_Routing_NoSplitCheckAux
	stdi8 (0xc204), 2

AudioInit_Routing_NoSplitCheckAux:
	bitda 5, (0xfbb1)
	jrl nz, AudioInit_Routing_Done
	stdi8 (0xc218), 22
	jrl AudioInit_Routing_Done

AudioInit_Routing_CheckTypeEDFlags:
	ldw_d16 xwa, (0xc598)
	and wa, 0x60
	jr nz, AudioInit_Routing_TypeED_Override
	bitda 5, (0xf9f7)
	jr nz, AudioInit_Routing_TypeED_CheckAux
	stdi8 (0xc204), 2

AudioInit_Routing_TypeED_CheckAux:
	bitda 5, (0xfbb1)
	jrl nz, AudioInit_Routing_Done
	stdi8 (0xc218), 22
	jrl AudioInit_Routing_Done

AudioInit_Routing_TypeED_Override:
	ordi16 0xc596, 256
	jrl AudioInit_Routing_Done

AudioInit_Routing_NoGroupAB:
	bitda 5, (0xf9f7)
	jr nz, AudioInit_Routing_SimpleAssign
	stdi8 (0xc204), 2

AudioInit_Routing_SimpleAssign:
	stdi8 (0xc2ba), 21
	stdi8 (0xc2bb), 22
	stdi8 (0xc217), 255
	stdi8 (0xc218), 255
	cpdi8 (3431), 4
	jr z, AudioInit_Routing_AllDisabled
	ldw_d16 xwa, (0xc598)
	and wa, 0x22
	cp wa, 0x20
	jr nz, AudioInit_Routing_CheckMixMode

AudioInit_Routing_AllDisabled:
	stdi8 (0xc2ba), 255
	stdi8 (0xc2bb), 255
	jrl AudioInit_Routing_Done

AudioInit_Routing_CheckMixMode:
	ldw_d16 xwa, (0xc596)
	bit 9, wa
	jrl nz, AudioInit_Routing_Done
	bitda 1, (0xfc5f)
	jr nz, AudioInit_Routing_Done
	ldb_d8 a, (0xfc5f)
	and a, 0xfc
	jr nz, AudioInit_Routing_MixFCBits
	ldb_d8 a, (0xfc60)
	and a, 0xfc
	jr nz, AudioInit_Routing_MixFCBits
	bitda 5, (0xfbe5)
	jr nz, AudioInit_Routing_MixCheckAux
	stdi8 (0xc217), 21

AudioInit_Routing_MixCheckAux:
	bitda 5, (0xfbb1)
	jr nz, AudioInit_Routing_Done
	stdi8 (0xc218), 22
	jr AudioInit_Routing_Done

AudioInit_Routing_MixFCBits:
	ldw_d16 xwa, (0xc598)
	and wa, 0x60
	jr nz, AudioInit_Routing_Done
	bitda 5, (0xfbe5)
	jr nz, AudioInit_Routing_MixFCCheckAux
	stdi8 (0xc217), 21

AudioInit_Routing_MixFCCheckAux:
	bitda 5, (0xfbb1)
	jr nz, AudioInit_Routing_Done
	stdi8 (0xc218), 22

AudioInit_Routing_SkipToEnd:
	jr AudioInit_Routing_Done

AudioInit_Routing_NoActiveVoices:
	ldw_d16 xwa, (0xc596)
	bit 2, wa
	jr z, AudioInit_Routing_FullDisable
	stdi8 (0xc2ba), 21
	stdi8 (0xc2bb), 22
	stdi8 (0xc217), 255
	stdi8 (0xc218), 255
	jr AudioInit_Routing_Done

AudioInit_Routing_FullDisable:
	stdi8 (0xc2ba), 255
	stdi8 (0xc2bb), 255
	stdi8 (0xc217), 255
	stdi8 (0xc218), 255

AudioInit_Routing_Done:
	ordi16 0xc59c, 260
	ret

AudioInit_ConfigurePanning:
	ldw_d16 xwa, (0xc596)
	and wa, 0x400
	cp wa, 0x400
	ret nz
	ldw_d16 xwa, (0xc596)
	bit 2, wa
	ret nz
	cpdi8 (0xc1ff), 255
	jr nz, AudioInit_Pan_CheckMode0
	bitda 0, (0xc1fe)
	jr nz, AudioInit_Pan_SetStereoLeft

AudioInit_Pan_CheckMode0:
	cpdi8 (0xc1ff), 0
	jr nz, AudioInit_Pan_CheckMode1

AudioInit_Pan_SetStereoLeft:
	stdi8 (0xc2b4), 0
	jr AudioInit_Pan_CheckReverbChannel

AudioInit_Pan_CheckMode1:
	cpdi8 (0xc1ff), 255
	jr nz, AudioInit_Pan_CheckMode1b
	bitda 1, (0xc1fe)
	jr nz, AudioInit_Pan_SetStereoRight

AudioInit_Pan_CheckMode1b:
	cpdi8 (0xc1ff), 1
	jr nz, AudioInit_Pan_CheckTypeED

AudioInit_Pan_SetStereoRight:
	stdi8 (0xc2b4), 1
	jr AudioInit_Pan_CheckReverbChannel

AudioInit_Pan_CheckTypeED:
	ldw_d16 xwa, (0xc598)
	and wa, 0x60
	jr z, AudioInit_Pan_DefaultCenter
	ldb_d8 a, (0xfc66)
	and a, 0x3
	cps a, 2
	jr nz, AudioInit_Pan_TypeED_Left
	stdi8 (0xc2b4), 1
	jr AudioInit_Pan_CheckReverbChannel

AudioInit_Pan_TypeED_Left:
	stdi8 (0xc2b4), 0
	jr AudioInit_Pan_CheckReverbChannel

AudioInit_Pan_DefaultCenter:
	stdi8 (0xc2b4), 255

AudioInit_Pan_CheckReverbChannel:
	cpdi8 (0xe9c0), 14
	jr ule, AudioInit_Pan_Reverb_CopyFromMain
	cpdi8 (0xc1ff), 255
	jr nz, AudioInit_Pan_Reverb_CheckMode0
	bitda 0, (0xc1fe)
	jr nz, AudioInit_Pan_Reverb_Left

AudioInit_Pan_Reverb_CheckMode0:
	cpdi8 (0xc1ff), 0
	jr nz, AudioInit_Pan_Reverb_CheckMode1

AudioInit_Pan_Reverb_Left:
	stdi8 (0xc2bc), 0
	jr AudioInit_Pan_Done

AudioInit_Pan_Reverb_CheckMode1:
	cpdi8 (0xc1ff), 255
	jr nz, AudioInit_Pan_Reverb_CheckMode1b
	bitda 1, (0xc1fe)
	jr nz, AudioInit_Pan_Reverb_Right

AudioInit_Pan_Reverb_CheckMode1b:
	cpdi8 (0xc1ff), 1
	jr nz, AudioInit_Pan_Reverb_CheckTypeED

AudioInit_Pan_Reverb_Right:
	stdi8 (0xc2bc), 1
	jr AudioInit_Pan_Done

AudioInit_Pan_Reverb_CheckTypeED:
	ldw_d16 xwa, (0xc598)
	and wa, 0x60
	jr z, AudioInit_Pan_Reverb_Center
	ldb_d8 a, (0xfc66)
	and a, 0x3
	cps a, 2
	jr nz, AudioInit_Pan_Reverb_TypeED_Left
	stdi8 (0xc2bc), 1
	jr AudioInit_Pan_Done

AudioInit_Pan_Reverb_TypeED_Left:
	stdi8 (0xc2bc), 0
	jr AudioInit_Pan_Done

AudioInit_Pan_Reverb_Center:
	stdi8 (0xc2bc), 255
	jr AudioInit_Pan_Done

AudioInit_Pan_Reverb_CopyFromMain:
	ldmm8 0xc2bc, 0xe9c0

AudioInit_Pan_Done:
	ordi16 0xc59c, 256
	ret

AudioInit_CheckStereoMode:
	ldw_d16 xwa, (0xc596)
	bit 11, wa
	ret z
	bitda 0, (0xc1fe)
	jr z, AudioInit_Stereo_CheckBit1
	stdi8 (0xc200), 0
	jr AudioInit_Stereo_CheckBit3

AudioInit_Stereo_CheckBit1:
	bitda 1, (0xc1fe)
	jr z, AudioInit_Stereo_Default
	stdi8 (0xc200), 1
	jr AudioInit_Stereo_CheckBit3

AudioInit_Stereo_Default:
	stdi8 (0xc200), 255

AudioInit_Stereo_CheckBit3:
	bitda 3, (0xc1fe)
	ret z
	stdi8 (0xc201), 0
	ret

AudioInit_DispatchChanges:
	stdi16 (0xc4ca), 0
	ldw_d16 xwa, (0xc59c)
	and wa, 0x188
	call_24 nz, AudioInit_ComparePartStates
	ldw_d16 xwa, (0xc59c)
	and wa, 0x1c0
	call_24 nz, AudioInit_CompareChannelMappings
	ldw_d16 xwa, (0xc59c)
	and wa, 0x102
	jr z, AudioInit_Dispatch_CheckVoiceChange
	calr AudioInit_CompareVoiceConfig
	jr AudioInit_Dispatch_CheckPartChange

AudioInit_Dispatch_CheckVoiceChange:
	ldw_d16 xwa, (0xc59c)
	bit 0, wa
	jr nz, AudioInit_Dispatch_SendVoiceChange
	ldw_d16 xwa, (0xc59a)
	bit 9, wa
	jr z, AudioInit_Dispatch_CheckPartChange

AudioInit_Dispatch_SendVoiceChange:
	calr AudioInit_CompareVoiceConfig

AudioInit_Dispatch_CheckPartChange:
	ldw_d16 xwa, (0xc59c)
	bit 8, wa
	jr nz, AudioInit_Dispatch_SendPartChange
	ldw_d16 xwa, (0xc59a)
	and wa, 0x7000
	jr z, AudioInit_Dispatch_CheckMisc

AudioInit_Dispatch_SendPartChange:
	calr AudioInit_ComparePriorityTable

AudioInit_Dispatch_CheckMisc:
	ldw_d16 xwa, (0xc59c)
	bit 2, wa
	call_24 nz, AudioInit_ComparePartAssignment
	ldw_d16 xwa, (0xc59c)
	bit 3, wa
	call_24 nz, AudioInit_ComparePartConfig
	ldw_d16 xwa, (0xc59c)
	bit 6, wa
	call_24 nz, AudioInit_CompareChannelConfig
	ldw_d16 xwa, (0xc59c)
	bit 4, wa
	call_24 nz, AudioInit_CompareVolumeTable
	ldw_d16 xwa, (0xc59a)
	bit 13, wa
	jr z, AudioInit_Dispatch_CheckToneRefresh
	ldw_d16 xwa, (0xc596)
	bit 4, wa
	jr z, AudioInit_Dispatch_RefreshTone

AudioInit_Dispatch_CheckToneRefresh:
	ldw_d16 xwa, (0xc59a)
	bit 12, wa
	jr z, AudioInit_Dispatch_CheckVoiceAssign

AudioInit_Dispatch_RefreshTone:
	call Voice_UpdatePlayModeState
	cp l, 0xff
	call_24 nz, VoiceEvent_AllocAllLayers

AudioInit_Dispatch_CheckVoiceAssign:
	ldw_d16 xwa, (0xc59a)
	bit 14, wa
	jr z, AudioInit_Dispatch_Finalize
	call NoteMap_FindBestMatch
	cp l, 0xff
	call_24 nz, VoiceEvent_DispatchTable

AudioInit_Dispatch_Finalize:
	call VoiceEvent_HandlerTable
	ld xiy, 0xc1fe
	ld xix, 0xc364
	ldw bc, 0xb3
	ldirw
	stdi16 (0xc59c), 0
	stdi16 (0xc59a), 0
	ret

AudioInit_QueueCommand:
	dec 6, xsp
	ld (xsp), e
	ld (xsp + 2), c
	ld (xsp + 4), a
	cpdi16 0xc4ca, 49
	jr c, AudioInit_QueueCommand_Write
	call VoiceEvent_HandlerTable
	stdi16 (0xc4ca), 0

AudioInit_QueueCommand_Write:
	ldw_d16 xwa, (0xc4ca)
	sll wa, 2
	lda_d16 xbc, (0xc4cc)
	ld de, wa
	extz xde
	add xde, xbc
	ld a, (xsp + 4)
	ld (xde), a
	ldw_d16 xwa, (0xc4ca)
	sll wa, 2
	lda_d16 xbc, (0xc4cd)
	ld de, wa
	extz xde
	add xde, xbc
	ld a, (xsp + 2)
	ld (xde), a
	ldw_d16 xwa, (0xc4ca)
	sll wa, 2
	lda_d16 xbc, (0xc4ce)
	ld de, wa
	extz xde
	add xde, xbc
	ld a, (xsp)
	ld (xde), a
	ldw_d16 xwa, (0xc4ca)
	sll wa, 2
	lda_d16 xbc, (0xc4cf)
	ld de, wa
	extz xde
	add xde, xbc
	ld a, (xsp + 10)
	ld (xde), a
	incdi16 1, (0xc4ca)
	inc 6, xsp
	retd 0x2

AudioInit_ComparePartStates:
	pushw iz
	ldw_d16 xwa, (0xc59c)
	bit 3, wa
	jrl z, AudioInit_ComparePanState
	lds iz, 0
	cp iz, 0x1a
	jrl nc, AudioInit_PartCompare_CheckGlobalBits

AudioInit_PartCompare_Loop:
	ld wa, iz
	lda_d16 xbc, (0xc222)
	ld de, wa
	extz xde
	add xde, xbc
	ld wa, iz
	lda_d16 xbc, (0xc388)
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	cp a, (xde)
	jr z, AudioInit_PartCompare_SameVoice
	stb_erp A, 0xf8
	ld l, a
	extz hl
	ld wa, iz
	lda_d16 xbc, (0xc222)
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	ld e, a
	extz de
	ld wa, iz
	lda_d16 xbc, (0xc388)
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
	lda_d16 xbc, (0xc222)
	extz xwa
	add xwa, xbc
	cp (xwa), 0xff
	jr z, AudioInit_PartCompare_Next
	ld wa, iz
	add wa, wa
	lda_d16 xbc, (0xc488)
	extz xwa
	add xwa, xbc
	ldcfm 6, (xwa)
	scc8 c, e
	ld wa, iz
	add wa, wa
	lda_d16 xbc, (0xc322)
	extz xwa
	add xwa, xbc
	ldcfm 6, (xwa)
	scc8 c, a
	cp a, e
	jr z, AudioInit_PartCompare_Next
	stb_erp A, 0xf8
	ld e, a
	extz de
	ld wa, iz
	lda_d16 xbc, (0xc222)
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	extz wa
	pushw wa
	ld bc, de
	lds wa, 0
	ldw de, 0xff
	calr AudioInit_QueueCommand

AudioInit_PartCompare_Next:
	inc 1, iz
	cp iz, 0x1a
	jrl c, AudioInit_PartCompare_Loop

AudioInit_PartCompare_CheckGlobalBits:
	ldcf_dd16 4, 0x88, 0xc4
	scc8 c, a
	ldcf_dd16 4, 0x22, 0xc3
	scc8 c, c
	cp c, a
	jr z, AudioInit_ComparePanState
	ldb_d8 a, (0xc222)
	extz wa
	pushw wa
	lds wa, 0
	lds bc, 0
	ldw de, 0xff
	calr AudioInit_QueueCommand

AudioInit_ComparePanState:
	ldw_d16 xwa, (0xc59c)
	bit 8, wa
	jr z, AudioInit_PartCompare_Return
	ldb_d8 a, (0xc41a)
	cpda8 a, 0xc2b4
	jr z, AudioInit_PartCompare_Return
	ldb_d8 a, (0xc2b4)
	ld c, a
	extz bc
	ldb_d8 a, (0xc41a)
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
	ldw_d16 xwa, (0xc59c)
	bit 1, wa
	jr z, AudioInit_VoiceCompare_BothFF
	ldb_d8 a, (0xc365)
	cpda8 a, 0xc1ff
	jr z, AudioInit_VoiceCompare_BothFF
	ldb_d8 a, (0xc1ff)
	ld c, a
	extz bc
	ldb_d8 a, (0xc365)
	extz wa
	pushw wa
	ld de, bc
	lds wa, 2
	lds bc, 1
	calr AudioInit_QueueCommand
	bitda 3, (0xc364)
	ret z
	bitda 3, (0xc1fe)
	ret nz
	pushw 0x8
	lds wa, 2
	lds bc, 0
	lds de, 0
	calr AudioInit_QueueCommand
	ret

AudioInit_VoiceCompare_BothFF:
	cpdi8 (0xc1ff), 255
	jrl nz, AudioInit_VoiceCompare_NotBothFF
	cpdi8 (0xc365), 255
	jrl nz, AudioInit_VoiceCompare_NotBothFF
	ldb_d8 a, (0xc364)
	xorda8 a, 0xc1fe
	ld c, a
	ldb_d8 a, (0xc1fe)
	and a, c
	ld e, a
	ldb_d8 a, (0xc364)
	xorda8 a, 0xc1fe
	ld c, a
	ldb_d8 a, (0xc364)
	and a, c
	ld l, a
	lds ix, 0
	cps ix, 6
	jrl nc, AudioInit_VoiceCompare_BuildCmd

AudioInit_VoiceCompare_LayerLoop:
	ld wa, ix
	sll wa, 2
	lda_d16 xbc, (0xc2c2)
	extz xwa
	add xwa, xbc
	bitm 7, (xwa)
	jr z, AudioInit_VoiceCompare_LayerNext
	ld wa, ix
	sll wa, 2
	lda_d16 xbc, (0xc428)
	extz xwa
	add xwa, xbc
	ld h, (xwa)
	res 7, h
	ld wa, ix
	sll wa, 2
	lda_d16 xbc, (0xc2c2)
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	res 7, a
	cp a, h
	jr nz, AudioInit_VoiceCompare_LayerChanged
	ld wa, ix
	sll wa, 2
	add wa, 0xc4
	lda_d16 xbc, (0xc365)
	extz xwa
	add xwa, xbc
	ld h, (xwa)
	srl h, 1
	ld wa, ix
	sll wa, 2
	add wa, 0xc4
	lda_d16 xbc, (0xc1ff)
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	srl a, 1
	cp a, h
	jr z, AudioInit_VoiceCompare_LayerNext

AudioInit_VoiceCompare_LayerChanged:
	ldb_d8 a, (0xc1fe)
	andda8 a, 0xc364
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
	cpdi8 (0xc1ff), 255
	jr z, AudioInit_VoiceCompare_BuildCmd
	cpdi8 (0xc365), 255
	jr z, AudioInit_VoiceCompare_BuildCmd
	ldb_d8 a, (0xc364)
	xorda8 a, 0xc1fe
	ld c, a
	ldb_d8 a, (0xc1fe)
	and a, c
	and a, 0xf8
	ld e, a
	ldb_d8 a, (0xc364)
	xorda8 a, 0xc1fe
	ld c, a
	ldb_d8 a, (0xc364)
	and a, c
	and a, 0xf8
	ld l, a
	bitda 7, (0xc2ce)
	jr z, AudioInit_VoiceCompare_BuildCmd
	ldb_d8 a, (0xc434)
	res 7, a
	ldb_d8 c, (0xc2ce)
	res 7, c
	cp c, a
	jr nz, AudioInit_VoiceCompare_SetBit3
	ldb_d8 a, (0xc435)
	srl a, 1
	ldb_d8 c, (0xc2cf)
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
	ldb_d8 a, (0xc41a)
	cpda8 a, 0xc2b4
	ret z
	ldb_d8 a, (0xc2b4)
	ld c, a
	extz bc
	ldb_d8 a, (0xc41a)
	extz wa
	pushw wa
	ld de, bc
	lds wa, 2
	lds bc, 2
	calr AudioInit_QueueCommand
	ret

AudioInit_CompareChannelMappings:
	pushw iz
	ldw_d16 xwa, (0xc59c)
	and wa, 0xc0
	jrl z, AudioInit_ChannelMap_CheckPan
	lds iz, 0
	cp iz, 0x10
	jrl nc, AudioInit_ChannelMap_CheckPan

AudioInit_ChannelMap_Loop:
	ld wa, iz
	lda_d16 xbc, (0xc2a2)
	ld de, wa
	extz xde
	add xde, xbc
	ld wa, iz
	lda_d16 xbc, (0xc408)
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	cp a, (xde)
	jr z, AudioInit_ChannelMap_CheckPrimary
	stb_erp A, 0xf8
	ld l, a
	extz hl
	ld wa, iz
	lda_d16 xbc, (0xc2a2)
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	ld e, a
	extz de
	ld wa, iz
	lda_d16 xbc, (0xc408)
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
	lda_d16 xbc, (0xc282)
	ld de, wa
	extz xde
	add xde, xbc
	ld wa, iz
	lda_d16 xbc, (0xc3e8)
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	cp a, (xde)
	jr z, AudioInit_ChannelMap_Next
	stb_erp A, 0xf8
	ld l, a
	extz hl
	ld wa, iz
	lda_d16 xbc, (0xc282)
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	ld e, a
	extz de
	ld wa, iz
	lda_d16 xbc, (0xc3e8)
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
	ldw_d16 xwa, (0xc59c)
	bit 8, wa
	jr z, AudioInit_ChannelMap_Return
	ldb_d8 a, (0xc41a)
	cpda8 a, 0xc2b4
	jr z, AudioInit_ChannelMap_Return
	ldb_d8 a, (0xc2b4)
	ld c, a
	extz bc
	ldb_d8 a, (0xc41a)
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
	lda_d16 xbc, (0xc2ba)
	ld de, wa
	extz xde
	add xde, xbc
	ld wa, iz
	lda_d16 xbc, (0xc420)
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	cp a, (xde)
	jr z, AudioInit_Priority_Next
	stb_erp A, 0xf8
	ld l, a
	extz hl
	ld wa, iz
	lda_d16 xbc, (0xc2ba)
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	ld e, a
	extz de
	ld wa, iz
	lda_d16 xbc, (0xc420)
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
	cp iz, 0x1a
	jrl nc, AudioInit_PartAssign_Return

AudioInit_PartAssign_Loop:
	ld wa, iz
	lda_d16 xbc, (0xc202)
	ld de, wa
	extz xde
	add xde, xbc
	ld wa, iz
	lda_d16 xbc, (0xc368)
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	cp a, (xde)
	jrl z, AudioInit_PartAssign_Next
	cps iz, 2
	jr nz, AudioInit_PartAssign_CheckIdx15
	ld wa, iz
	lda_d16 xbc, (0xc202)
	extz xwa
	add xwa, xbc
	cp (xwa), 0xff
	jr z, AudioInit_PartAssign_CheckIdx15
	cpdi8 (0xc2ba), 2
	jr nz, AudioInit_PartAssign_CheckIdx15
	cpdi8 (0xc420), 2
	jr nz, AudioInit_PartAssign_Next

AudioInit_PartAssign_CheckIdx15:
	cp iz, 0x15
	jr nz, AudioInit_PartAssign_CheckIdx16
	ld wa, iz
	lda_d16 xbc, (0xc202)
	extz xwa
	add xwa, xbc
	cp (xwa), 0xff
	jr z, AudioInit_PartAssign_CheckIdx16
	cpdi8 (0xc2ba), 21
	jr nz, AudioInit_PartAssign_CheckIdx16
	cpdi8 (0xc420), 21
	jr nz, AudioInit_PartAssign_Next

AudioInit_PartAssign_CheckIdx16:
	cp iz, 0x16
	jr nz, AudioInit_PartAssign_QueueChange
	ld wa, iz
	lda_d16 xbc, (0xc202)
	extz xwa
	add xwa, xbc
	cp (xwa), 0xff
	jr z, AudioInit_PartAssign_QueueChange
	cpdi8 (0xc2bb), 22
	jr nz, AudioInit_PartAssign_QueueChange
	cpdi8 (0xc421), 22
	jr nz, AudioInit_PartAssign_Next

AudioInit_PartAssign_QueueChange:
	stb_erp A, 0xf8
	ld l, a
	extz hl
	ld wa, iz
	lda_d16 xbc, (0xc202)
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	ld e, a
	extz de
	ld wa, iz
	lda_d16 xbc, (0xc368)
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
	cp iz, 0x1a
	jrl c, AudioInit_PartAssign_Loop

AudioInit_PartAssign_Return:
	popw iz
	ret

AudioInit_ComparePartConfig:
	pushw iz
	lds iz, 0
	cp iz, 0x1a
	jrl nc, AudioInit_PartConfig_Return

AudioInit_PartConfig_Loop:
	ld wa, iz
	lda_d16 xbc, (0xc222)
	ld de, wa
	extz xde
	add xde, xbc
	ld wa, iz
	lda_d16 xbc, (0xc388)
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	cp a, (xde)
	jr z, AudioInit_PartConfig_SameVoice
	stb_erp A, 0xf8
	ld l, a
	extz hl
	ld wa, iz
	lda_d16 xbc, (0xc222)
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	ld e, a
	extz de
	ld wa, iz
	lda_d16 xbc, (0xc388)
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
	ldb_d8 a, (0xc2bc)
	extz wa
	lda_d16 xbc, (0xc222)
	extz xwa
	add xwa, xbc
	cp (xwa), 0xff
	jrl z, AudioInit_PartConfig_Next
	ld wa, iz
	add wa, wa
	lda_d16 xbc, (0xc488)
	extz xwa
	add xwa, xbc
	ldcfm 5, (xwa)
	scc8 c, e
	ld wa, iz
	add wa, wa
	lda_d16 xbc, (0xc322)
	extz xwa
	add xwa, xbc
	ldcfm 5, (xwa)
	scc8 c, a
	cp a, e
	jr z, AudioInit_PartConfig_Next
	stb_erp A, 0xf8
	ld e, a
	extz de
	ldb_d8 a, (0xc2bc)
	extz wa
	lda_d16 xbc, (0xc222)
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	extz wa
	pushw wa
	ld bc, de
	ldw wa, 0x8
	ldw de, 0xff
	calr AudioInit_QueueCommand
	jr AudioInit_PartConfig_Next

AudioInit_PartConfig_NotReverb:
	ld wa, iz
	lda_d16 xbc, (0xc222)
	extz xwa
	add xwa, xbc
	cp (xwa), 0xff
	jr z, AudioInit_PartConfig_Next
AudioInit_PartConfig_CheckCarry:
	ld wa, iz
	add wa, wa
	lda_d16 xbc, (0xc488)
	extz xwa
	add xwa, xbc
	ldcfm 5, (xwa)
	scc8 c, e
	ld wa, iz
	add wa, wa
	lda_d16 xbc, (0xc322)
	extz xwa
	add xwa, xbc
	ldcfm 5, (xwa)
	scc8 c, a
	cp a, e
	jr z, AudioInit_PartConfig_Next
	stb_erp A, 0xf8
	ld e, a
	extz de
	ld wa, iz
	lda_d16 xbc, (0xc222)
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	extz wa
	pushw wa
	ld bc, de
	ldw wa, 0x8
	ldw de, 0xff
	calr AudioInit_QueueCommand

AudioInit_PartConfig_Next:
	inc 1, iz
	cp iz, 0x1a
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
	lda_d16 xbc, (0xc282)
	ld de, wa
	extz xde
	add xde, xbc
	ld wa, iz
	lda_d16 xbc, (0xc3e8)
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	cp a, (xde)
	jr z, AudioInit_ChannelConfig_Next
	stb_erp A, 0xf8
	ld l, a
	extz hl
	ld wa, iz
	lda_d16 xbc, (0xc282)
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	ld e, a
	extz de
	ld wa, iz
	lda_d16 xbc, (0xc3e8)
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
	cp iz, 0x1a
	jr nc, AudioInit_Volume_Return

AudioInit_Volume_Loop:
	ld wa, iz
	lda_d16 xbc, (0xc242)
	ld de, wa
	extz xde
	add xde, xbc
	ld wa, iz
	lda_d16 xbc, (0xc3a8)
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	cp a, (xde)
	jr z, AudioInit_Volume_Next
	stb_erp A, 0xf8
	ld l, a
	extz hl
	ld wa, iz
	lda_d16 xbc, (0xc242)
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	ld e, a
	extz de
	ld wa, iz
	lda_d16 xbc, (0xc3a8)
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	extz wa
	pushw wa
	ld bc, hl
	ldw wa, 0xa
	calr AudioInit_QueueCommand

AudioInit_Volume_Next:
	inc 1, iz
	cp iz, 0x1a
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
	lda_d16	xbc, (0xc62a)
	extz	xwa
	add	xwa, xbc
	ld	(xwa), 16
	ld	wa, de
	add	wa, wa
	lda_d16	xbc, (0xc62b)
	extz	xwa
	add	xwa, xbc
	ld	(xwa), 0
	inc	1, de
	cp	de, 161
	jr	c, -38
	stdi8	(0xca6a), 8
	stdi8	(0xca6b), 0
	stdi8	(0xca6c), 8
	stdi8	(0xca6d), 0
	stdi8	(0xca6e), 16
	stdi8	(0xca6f), 0
	ret

