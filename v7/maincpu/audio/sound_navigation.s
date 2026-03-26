; =============================================================================
; Sound Navigation
; =============================================================================
;
; Sound bank browsing functions: MainGetSoundName,
; Sound_Navigate_Next/Prev, MainGetRhythmName, MainGetPmemName,
; and MainTrSwControl for sound selection UI.
; =============================================================================

MainGetSoundName:
	.incbin "includes/generated/v7_transplant_MainGetSoundName.bin"
GetSoundName_BuildString:
	.incbin "includes/generated/v7_transplant_GetSoundName_BuildString.bin"
GetSoundName_DefaultString:
	.incbin "includes/generated/v7_transplant_GetSoundName_DefaultString.bin"
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
	.incbin "includes/generated/v7_transplant_SoundLookup_ByCategory.bin"
SoundLookup_DispatchAndReturn:
	call ApPostEvent
	jrl Sound_Navigate_Return

Sound_SetSelection:
	.incbin "includes/generated/v7_transplant_Sound_SetSelection.bin"
Sound_Navigate_Entry:
	ld (xsp + 4), wa
	cpw (xsp + 4), 0xf
	jr le, Sound_Navigate_Init
	cpw (xsp + 4), 0x15
	jrl lt, Sound_Navigate_Return
	cpw (xsp + 4), 0x16
	jrl gt, Sound_Navigate_Return

Sound_Navigate_Init:
	.incbin "includes/generated/v7_transplant_Sound_Navigate_Init.bin"
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
	.incbin "includes/generated/v7_transplant_Sound_Navigate_ApplyChange.bin"
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
	.incbin "includes/generated/v7_transplant_GetSoundBankCount_DoLookup.bin"
MainGetRhythmName:
	.incbin "includes/generated/v7_transplant_MainGetRhythmName.bin"
MainGetRhythmName_Return:
	lds32 xhl, 0
	popw_erp 0xfa
	inc 4, xsp
	ret

MainGetPmemName:
	.incbin "includes/generated/v7_transplant_MainGetPmemName.bin"
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
