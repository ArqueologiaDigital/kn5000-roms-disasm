; =============================================================================
; Sound Navigation
; =============================================================================
;
; Sound bank browsing functions: MainGetSoundName,
; Sound_Navigate_Next/Prev, MainGetRhythmName, MainGetPmemName,
; and MainTrSwControl for sound selection UI.
; =============================================================================

MainGetSoundName:
	lda xsp, (xsp - 20)
	push xiz
	ld (xsp + 20), xde
	ld xwa, (xsp + 20)
	cp xbc, 0x1e000a9
	jrl z, Sound_Navigate_Entry
	cp xbc, 0x1e000a8
	jrl z, Sound_SetSelection
	cp xbc, 0x1e00061
	jrl z, SoundLookup_ByCategory
	cp xbc, 0x1e0005e
	jrl nz, Sound_Navigate_Return
	pushw 0x6
	call Malloc
	ld (xsp + 8), xhl
	pushw 0x12
	call Malloc
	inc 4, xsp
	ld (xsp + 10), xhl
	ld xwa, (xsp + 20)
	ld xbc, (xsp + 6)
	ld (xbc), wa
	ld xde, (xsp + 10)
	ld (xbc + 2), xde
	cpw (xbc), 0xf
	jr ule, GetSoundName_BuildString
	cpw (xbc), 0x15
	jr c, GetSoundName_DefaultString
	cpw (xbc), 0x16
	jr ugt, GetSoundName_DefaultString

GetSoundName_BuildString:
	lds bc, 0
	call SndParam_LookupViaEncode
	ldb_erp L, 0xfb
	ld xwa, (xsp + 20)
	ldw bc, 0x20
	call SndParam_LookupViaEncode
	stb_erp A, 0xfb
	extz wa
	extz hl
	ld bc, hl
	ld xde, (xsp + 10)
	call SndParam_ApplyProgramChangeAsync
	ld xwa, (xsp + 10)
	ld (xwa + 16), 0x0
	jr GetSoundName_DispatchResult

GetSoundName_DefaultString:
	pushw 0xea
	pushw 0x99e6
	ld xwa, (xsp + 14)
	push xwa
	call Strcpy
	inc 8, xsp

GetSoundName_DispatchResult:
	ld xwa, 0xffffffff
	ld xbc, 0x1c00020
	ld xde, (xsp + 6)
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e00023
	ld xde, (xsp + 6)
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e00023
	ld xde, (xsp + 10)
	jr SoundLookup_DispatchAndReturn

SoundLookup_ByCategory:
	lds bc, 0
	call SndParam_LookupViaEncode
	ld (xsp + 17), l
	ld xwa, (xsp + 20)
	ldw bc, 0x20
	call SndParam_LookupViaEncode
	lda xwa, (xsp + 14)
	ld (xwa + 4), l
	ld xbc, (xsp + 20)
	ld (xwa + 2), c
	call SndParam_FetchOscTableEntry
	lda xbc, (xsp + 14)
	ld e, (xbc + 1)
	extz de
	ld a, (xbc)
	extz wa
	sll wa, 8
	add wa, de
	ld bc, wa
	extz xbc
	sll xbc, 0
	ld xwa, (xsp + 20)
	ld de, wa
	extz xde
	add xde, xbc
	ld xwa, 0xffffffff
	ld xbc, 0x1c00023

SoundLookup_DispatchAndReturn:
	call ApPostEvent
	jrl Sound_Navigate_Return

Sound_SetSelection:
	extz wa
	ld xbc, (xsp + 20)
	srl xbc, 0
	ldiw_erp 0xe6, 0
	ld de, bc
	srl bc, 8
	ldb b, 0x0
	extz bc
	extz de
	call MIDI_DistributeParamToChannels
	ld xwa, (xsp + 20)
	extz wa
	ld xbc, (xsp + 20)
	srl xbc, 0
	ldiw_erp 0xe6, 0
	ld de, bc
	srl de, 8
	ldb d, 0x0
	extz de
	extz bc
	pushw bc
	lds bc, 0
	call SwbtWr
	lds wa, 1
	jrl Sound_Navigate_Notify

Sound_Navigate_Entry:
	ld (xsp + 4), wa
	cpw (xsp + 4), 0xf
	jr le, Sound_Navigate_Init
	cpw (xsp + 4), 0x15
	jrl lt, Sound_Navigate_Return
	cpw (xsp + 4), 0x16
	jrl gt, Sound_Navigate_Return

Sound_Navigate_Init:
	ldw (xsp + 12), 0x0
	ld xwa, (xsp + 20)
	srl xwa, 0
	ldiw_erp 0xe2, 0
	ld (xsp + 10), wa
	ld wa, (xsp + 4)
	lds bc, 0
	call SndParam_LookupViaEncode
	ld (xsp + 17), l
	ld wa, (xsp + 4)
	ldw bc, 0x20
	call SndParam_LookupViaEncode
	lda xwa, (xsp + 14)
	ld (xwa + 4), l
	ld bc, (xsp + 4)
	ld (xwa + 2), c
	call SndParam_FetchOscTableEntry
	lda xbc, (xsp + 14)
	ld a, (xbc)
	extz wa
	ld (xsp + 8), wa
	ld a, (xbc + 1)
	ldb_erp A, 0xf8
	extz iz
	ld wa, (xsp + 4)
	ld bc, (xsp + 8)
	calr GetSoundBankCount
	ld (xsp + 6), hl
	add iz, (xsp + 10)

Sound_Navigate_SearchLoop:
	cps iz, 0
	jr ge, Sound_Navigate_ScanForward
	cpw (xsp + 8), 0x0
	jr le, Sound_Navigate_AtBottom
	ld wa, (xsp + 8)
	ldw_erp WA, 0xfa
	ld (xsp + 10), iz
	ld hl, (xsp + 6)
	cpiw_erp 0xfa, 0
	jrl le, Sound_Navigate_UpdateState

Sound_Navigate_ScanBackward:
	dec1w_erp 0xfa
	ld wa, (xsp + 4)
	stw_erp BC, 0xfa
	calr GetSoundBankCount
	ld wa, hl
	inc 1, wa
	add (xsp + 10), wa
	cp hl, 0xffff
	jr nz, Sound_Navigate_BackwardCheck
	cpiw_erp 0xfa, 0
	jr gt, Sound_Navigate_BackwardCheck
	ld wa, (xsp + 8)
	ldw_erp WA, 0xfa
	ldw (xsp + 10), 0x0
	ld hl, (xsp + 6)
	jr Sound_Navigate_UpdateState

Sound_Navigate_BackwardCheck:
	cp hl, 0xffff
	jr nz, Sound_Navigate_UpdateState
	cpiw_erp 0xfa, 0
	jr gt, Sound_Navigate_ScanBackward
	jr Sound_Navigate_UpdateState

Sound_Navigate_AtBottom:
	lds iz, 0
	jrl Sound_Navigate_SetDone

Sound_Navigate_ScanForward:
	cp iz, (xsp + 6)
	jrl le, Sound_Navigate_SetDone
	cpw (xsp + 8), 0x11
	jrl ge, Sound_Navigate_AtTop
	ld wa, (xsp + 8)
	ldw_erp WA, 0xfa
	ld (xsp + 10), iz
	ld hl, (xsp + 6)
	cp_erpw 0xfa, 0x11, 0x00
	jr ge, Sound_Navigate_UpdateState

Sound_Navigate_ForwardLoop:
	inc1w_erp 0xfa
	inc 1, hl
	sub (xsp + 10), hl
	ld wa, (xsp + 4)
	stw_erp BC, 0xfa
	calr GetSoundBankCount
	cp hl, 0xffff
	jr nz, Sound_Navigate_ForwardCheck
	cp_erpw 0xfa, 0x11, 0x00
	jr lt, Sound_Navigate_ForwardCheck
	ld wa, (xsp + 8)
	ldw_erp WA, 0xfa
	ld wa, (xsp + 6)
	ld (xsp + 10), wa
	ld hl, (xsp + 6)
	jr Sound_Navigate_UpdateState

Sound_Navigate_ForwardCheck:
	cp hl, 0xffff
	jr nz, Sound_Navigate_UpdateState
	cp_erpw 0xfa, 0x11, 0x00
	jr lt, Sound_Navigate_ForwardLoop

Sound_Navigate_UpdateState:
	stw_erp WA, 0xfa
	ld (xsp + 8), wa
	ld iz, (xsp + 10)
	ld (xsp + 6), hl
	cpw (xsp + 12), 0x0
	jrl z, Sound_Navigate_SearchLoop

Sound_Navigate_Commit:
	lda xbc, (xsp + 14)
	ld a, (xbc + 1)
	extz wa
	cp wa, iz
	jr nz, Sound_Navigate_ApplyChange
	ld a, (xbc)
	extz wa
	cp wa, (xsp + 8)
	jr z, Sound_Navigate_Return

Sound_Navigate_ApplyChange:
	ld wa, (xsp + 4)
	extz wa
	ld bc, (xsp + 8)
	extz bc
	stb_erp E, 0xf8
	extz de
	call MIDI_DistributeParamToChannels
	ld wa, (xsp + 4)
	extz wa
	ld bc, (xsp + 8)
	ld e, c
	extz de
	stb_erp C, 0xf8
	extz bc
	pushw bc
	lds bc, 0
	call SwbtWr
	lds wa, 1

Sound_Navigate_Notify:
	call BitMapOut_StorePresetValue

Sound_Navigate_Return:
	lds32 xhl, 0
	pop xiz
	lda xsp, (xsp + 20)
	ret

Sound_Navigate_AtTop:
	ld iz, (xsp + 6)

Sound_Navigate_SetDone:
	ldw (xsp + 12), 0x1
	jr Sound_Navigate_Commit

GetSoundBankCount:
	ld de, bc
	ld hl, wa
	ld a, l
	ld c, e
	extz bc
	extz wa
	cp hl, 0xf
	jr z, GetSoundBankCount_CheckDrum
	cps hl, 2
	jr z, GetSoundBankCount_StandardBank
	cps hl, 1
	jr z, GetSoundBankCount_StandardBank
	cps hl, 0
	jr nz, GetSoundBankCount_CheckSpecial

GetSoundBankCount_StandardBank:
	jr GetSoundBankCount_DoLookup

GetSoundBankCount_CheckDrum:
	cp de, 0xf
	jr z, GetSoundBankCount_DoLookup

GetSoundBankCount_Invalid:
	ldw hl, 0xffff

GetSoundBankCount_Return:
	ret

GetSoundBankCount_CheckSpecial:
	cp de, 0xc
	jr z, GetSoundBankCount_Invalid

GetSoundBankCount_DoLookup:
	call CharMap_ActivePreamb_Prologue
	exts hl
	jr GetSoundBankCount_Return

MainGetRhythmName:
	dec 4, xsp
	pushw_erp 0xfa
	cp xbc, 0x1e0005f
	jrl nz, MainGetRhythmName_Return
	ld xwa, 0x28000
	call SndParam_LookupReadOnly
	ldb_erp L, 0xfa
	ld xwa, 0x28001
	call SndParam_LookupReadOnly
	ldb_erp L, 0xfb
	pushw 0x11
	call Malloc
	inc 2, xsp
	ld (xsp + 2), xhl
	lda_d16 xbc, 0x90ea
	stb_erp A, 0xfa
	ld (xbc), a
	stb_erp A, 0xfb
	ld (xbc + 1), a
	ld (xbc + 2), 0x48
	push xde
	push xhl
	push xix
	push xiz
	call Rhythm_DispatchNote_Finalize
	pop xiz
	pop xix
	pop xhl
	pop xde
	lda_d16 xbc, 0x90ee
	ld a, (xbc)
	extz wa
	ld c, (xbc + 1)
	extz bc
	call AccVoice_DispatchWithChannel
	pushw 0xd
	push xhl
	ld xwa, (xsp + 8)
	push xwa
	call Strncpy
	lda xsp, (xsp + 10)
	ld xwa, (xsp + 2)
	ld (xwa + 13), 0x0
	ld xwa, 0xffffffff
	ld xbc, 0x1c00021
	ld xde, (xsp + 2)
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e00023
	ld xde, (xsp + 2)
	call ApPostEvent

MainGetRhythmName_Return:
	lds32 xhl, 0
	popw_erp 0xfa
	inc 4, xsp
	ret

MainGetPmemName:
	dec 8, xsp
	pushw_erp 0xfa
	pushw 0x8
	call Malloc
	ld (xsp + 4), xhl
	pushw 0x12
	call Malloc
	inc 4, xsp
	ld (xsp + 6), xhl
	call BitMapOut_PrepareRender_CheckBit1
	ldb_erp L, 0xfb
	ld xwa, 0x300
	call SndParam_LookupReadOnly
	ld xwa, (xsp + 2)
	ld (xwa + 2), hl
	pushw 0x11
	pushw 0x0
	pushw 0xf9a2
	ld xwa, (xsp + 12)
	push xwa
	call Strncpy
	lda xsp, (xsp + 10)
	ld xwa, (xsp + 2)
	lda xbc, (xwa + 2)
	ld de, (xbc)
	dec 1, de
	srl de, 3
	stb_erp A, 0xfb
	extz wa
	cp wa, de
	jr nz, MainGetPmemName_CalcOffset
	call BitMapOut_GetRenderMode
	bit 7, l
	jr z, MainGetPmemName_PageNotFirst
	lds bc, 0
	jr MainGetPmemName_StoreResult

MainGetPmemName_PageNotFirst:
	lds bc, 1
	jr MainGetPmemName_StoreResult

MainGetPmemName_CalcOffset:
	stb_erp A, 0xfb
	sll a, 3
	inc 1, a
	extz wa
	ld (xbc), wa
	lds bc, 0

MainGetPmemName_StoreResult:
	ld xwa, (xsp + 2)
	ld (xwa), bc
	ld xbc, (xsp + 6)
	ld (xwa + 4), xbc
	ld (xbc + 17), 0x0
	ld xwa, 0xffffffff
	ld xbc, 0x1c00022
	ld xde, (xsp + 2)
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e00023
	ld xde, (xsp + 2)
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e00023
	ld xde, (xsp + 6)
	call ApPostEvent
	lds32 xhl, 0
	popw_erp 0xfa
	inc 8, xsp
	ret

MainTrSwControl:
	dec 4, xsp
	ld (xsp), xde
	ld xwa, (xsp)
	extz wa
	cp xbc, 0x1e00093
	jr z, MainTrSwControl_HandleChannel
	cp xbc, 0x1e00092
	jr nz, MainTrSwControl_Return
	call SeqVoice_DispatchEventToHandler
	ld xwa, (xsp)
	extz wa
	call SeqVoice_ComputeStatusFlags
	jr MainTrSwControl_Return

MainTrSwControl_HandleChannel:
	call AppEvent_HandleChannelEvent

MainTrSwControl_Return:
	lds32 xhl, 0
	inc 4, xsp
	ret
