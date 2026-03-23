FP_DP_CopyOrNegate8:
	cp xwa, xbc
	jr z, FP_DP_NegateInPlace8
	ld xhl, (xbc)
	ld (xwa), xhl
	ld xhl, (xbc + 4)
	xor_erpb 0xEF, 0x80
	ld (xwa + 4), xhl
	ret

FP_DP_NegateInPlace8:
	xormi8 (xwa + 7), 0x80
	ret

FP_SP_CopyOrNegate4:
	cp xwa, xbc
	jr z, FP_SP_NegateInPlace4
	ld xhl, (xbc)
	xor_erpb 0xEF, 0x80
	ld (xwa), xhl
	ret

FP_SP_NegateInPlace4:
	xormi8 (xwa + 3), 0x80
	ret

FP_DP_CmpAndCopy:
	lda xwa, (xsp + 8)
	lds bc, 1
	call FP_DP_CmpZero64
	lda xbc, (xsp + 8)
	ld xwa, (xsp + 4)
	cps hl, 0
	jr nz, FP_DP_CmpAndCopy_Negate
	call FP_DP_Raw8Copy
	ret

FP_DP_CmpAndCopy_Negate:
	call FP_DP_CopyOrNegate8
	ret

FP_DP_CmpAndCopy_Pad:
	.byte 0xff

FP_SP_Decode_ReadSign:
	push xiz
	lda xsp, (xsp - 8)
	ld xiz, xwa
	ld xwa, xsp
	call FP_SP_Decode
	ld xwa, xsp
	call FP_DP_ShiftDecode
	ld (xiz), xhl
	lda xsp, (xsp + 8)
	pop xiz
	ret

FP_SP_Decode_ReadSign_Pad:
	.byte 0xff

FP_DP_CmpZero64:
	lds hl, 0
	lds32 xde, 0
	ld xiy, (xwa + 4)
	cp xiy, xde
	jr lt, FP_DP_CmpZero64_Less
	jr gt, FP_DP_CmpZero64_Greater
	ld xiy, (xwa)
	cp xiy, xde
	jr nz, FP_DP_CmpZero64_Greater
	lda_24 xde, 0x03d978
	ld_srib3 L, 0x07, 0xE8, 0xE4
	ret

FP_DP_CmpZero64_Less:
	lda_24 xde, 0x03d97e
	ld_srib3 L, 0x07, 0xE8, 0xE4
	ret

FP_DP_CmpZero64_Greater:
	lda_24 xde, 0x03d984
	ld_srib3 L, 0x07, 0xE8, 0xE4
	ret

FP_SP_CmpZero32:
	lds hl, 0
	ld xde, (xwa)
	cp xde, 0x0
	jr lt, FP_SP_CmpZero32_Less
	jr gt, FP_SP_CmpZero32_Greater
	lda_24 xde, 0x03d978
	ld_srib3 L, 0x07, 0xE8, 0xE4
	ret

FP_SP_CmpZero32_Less:
	lda_24 xde, 0x03d97e
	ld_srib3 L, 0x07, 0xE8, 0xE4
	ret

FP_SP_CmpZero32_Greater:
	lda_24 xde, 0x03d984
	ld_srib3 L, 0x07, 0xE8, 0xE4
	ret

VoiceFloat_MulAddDispatch:
	lda xsp, (xsp - 40)
	push xiz
	ld xiz, (xsp + 48)
	ld wa, (xsp + 58)
	and wa, 0x7FF0
	cp wa, 0x41E0
	jr c, VoiceFloat_MulAddDispatch_InRange
	sti16_24 0x040c22, 0x0022
	ld xwa, xiz
	lda_24 xbc, 0x01f63e
	call FP_DP_Raw8Copy
	jr VoiceFloat_MulAddDispatch_Epilog

VoiceFloat_MulAddDispatch_InRange:
	lda xiy, (xsp + 52)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda xwa, (xsp + 36)
	push xwa
	call VoiceFloat_DispatchMulAdd
	lda xiy, (xsp + 64)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda xwa, (xsp + 40)
	push xwa
	call VoiceFloat_MulAddVariant2
	lda xsp, (xsp + 24)
	lda xbc, (xsp + 20)
	lda xde, (xsp + 28)
	lda xwa, (xsp + 36)
	call VoiceFloat_SubDP
	ld xwa, xiz
	lda xbc, (xsp + 36)
	call FP_DP_Raw8Copy

VoiceFloat_MulAddDispatch_Epilog:
	pop xiz
	lda xsp, (xsp + 40)
	ret

VoiceFloat_CompareAndConvert:
	lda xsp, (xsp - 56)
	pushw iz
	lda xwa, (xsp + 74)
	lda_24 xbc, 0x01f646
	lds de, 1
	call ToneGen_Compare_Voice
	cps hl, 0
	jr nz, VoiceFloat_CompareAndConvert_Invalid
	lda xwa, (xsp + 74)
	lda_24 xbc, 0x01f64e
	lds de, 3
	call ToneGen_Compare_Voice
	cps hl, 0
	jr nz, VoiceFloat_CompareAndConvert_Invalid
	lda xbc, (xsp + 74)
	lda xwa, (xsp + 54)
	call FP_DP_DecodeToInt
	jr VoiceFloat_CompareAndConvert_AfterRange

VoiceFloat_CompareAndConvert_Invalid:
	ld xwa, 0xFFFFFFFF
	ld (xsp + 54), xwa

VoiceFloat_CompareAndConvert_AfterRange:
	lda xwa, (xsp + 66)
	lds bc, 2
	call FP_DP_CmpZero64
	cps hl, 0
	jr nz, VoiceFloat_CompareAndConvert_AltPath
	lda xbc, (xsp + 54)
	lda xwa, (xsp + 18)
	call FP_ScalarToDP
	lda xwa, (xsp + 18)
	lda xbc, (xsp + 74)
	lds de, 4
	call ToneGen_Compare_Voice
	cps hl, 0
	jr nz, VoiceFloat_CompareAndConvert_AltPath
	sti16_24 0x040c22, 0x0021
	ld xwa, (xsp + 62)
	lda_24 xbc, 0x01f656
	call FP_DP_Raw8Copy
	jrl VoiceFloat_CompareAndConvert_Epilog

VoiceFloat_CompareAndConvert_AltPath:
	lda xwa, (xsp + 74)
	lds bc, 3
	call FP_DP_CmpZero64
	cps hl, 0
	jr nz, VoiceFloat_CompareAndConvert_AltPath2
	lda xwa, (xsp + 66)
	lds bc, 5
	call FP_DP_CmpZero64
	cps hl, 0
	jr nz, VoiceFloat_CompareAndConvert_AltPath2
	sti16_24 0x040c22, 0x0021
	ld xwa, (xsp + 62)
	lda_24 xbc, 0x01f65e
	call FP_DP_Raw8Copy
	jrl VoiceFloat_CompareAndConvert_Epilog

VoiceFloat_CompareAndConvert_AltPath2:
	lda xbc, (xsp + 54)
	lda xwa, (xsp + 18)
	call FP_ScalarToDP
	lda xwa, (xsp + 18)
	lda xbc, (xsp + 74)
	lds de, 5
	call ToneGen_Compare_Voice
	cps hl, 0
	jrl nz, VoiceFloat_ConvergenceLoop
	ld xwa, (xsp + 54)
	cp xwa, 0x0
	jr ge, VoiceFloat_SignedDelta_Positive
	ld xwa, (xsp + 54)
	cpl wa
	cpl_werp 0xE2
	inc 1, xwa
	ld (xsp + 54), xwa

VoiceFloat_SignedDelta_Positive:
	lda_24 xbc, 0x01f666
	lda xwa, (xsp + 46)
	call FP_DP_Raw8Copy
	jrl VoiceFloat_IterationLoop_CheckContinue

VoiceFloat_IterationLoop:
	lda xwa, (xsp + 36)
	push xwa
	lda xiy, (xsp + 70)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda xwa, (xsp + 38)
	push xwa
	call FP_DP_FreqAdjust
	lda xsp, (xsp + 16)
	ld wa, (xsp + 36)
	add wa, wa
	cp wa, 0xFC03
	jr ge, VoiceFloat_IterationLoop_LargeStep
	lda xwa, (xsp + 74)
	lds bc, 2
	call FP_DP_CmpZero64
	cps hl, 0
	jr nz, VoiceFloat_IterationLoop_LessPath
	sti16_24 0x040c22, 0x0022
	lda xwa, (xsp + 66)
	lds bc, 2
	call FP_DP_CmpZero64
	lda_24 xbc, 0x00f420
	cps hl, 0
	jr nz, VoiceFloat_IterationLoop_GreaterPath
	lda xwa, (xsp + 46)
	call FP_DP_CopyOrNegate8
	jr VoiceFloat_IterationLoop_CopyResult

VoiceFloat_IterationLoop_GreaterPath:
	lda xwa, (xsp + 46)
	call FP_DP_Raw8Copy
	jr VoiceFloat_IterationLoop_CopyResult

VoiceFloat_IterationLoop_LessPath:
	lda_24 xbc, 0x01f66e
	lda xwa, (xsp + 46)
	call FP_DP_Raw8Copy

VoiceFloat_IterationLoop_CopyResult:
	ld xwa, (xsp + 62)
	lda xbc, (xsp + 46)
	call FP_DP_Raw8Copy
	jrl VoiceFloat_CompareAndConvert_Epilog

VoiceFloat_IterationLoop_LargeStep:
	lda xde, (xsp + 66)
	cp wa, 0x400
	jr le, VoiceFloat_IterationLoop_SmallStep
	sti16_24 0x040c22, 0x0022
	ld xwa, xde
	lds bc, 2
	call FP_DP_CmpZero64
	cps hl, 0
	jr nz, VoiceFloat_IterationLoop_LargeStep_NegPath
	lda_24 xbc, 0x00f420
	lda xwa, (xsp + 46)
	call FP_DP_CopyOrNegate8
	jr VoiceFloat_IterationLoop_LargeStep_Copy

VoiceFloat_IterationLoop_LargeStep_NegPath:
	lda_24 xbc, 0x00f420
	lda xwa, (xsp + 46)
	call FP_DP_Raw8Copy

VoiceFloat_IterationLoop_LargeStep_Copy:
	ld xwa, (xsp + 62)
	lda xbc, (xsp + 46)
	call FP_DP_Raw8Copy
	jrl VoiceFloat_CompareAndConvert_Epilog

VoiceFloat_IterationLoop_SmallStep:
	ld xwa, (xsp + 54)
	bit 0, wa
	jr z, VoiceFloat_IterationLoop_SmallStep_Add
	lda xwa, (xsp + 46)
	ld xbc, xwa
	call FP_DP_Add_Outer

VoiceFloat_IterationLoop_SmallStep_Add:
	lda xwa, (xsp + 66)
	ld xbc, xwa
	ld xde, xwa
	call FP_DP_Add_Outer
	ld xwa, (xsp + 54)
	sra xwa, 1
	ld (xsp + 54), xwa

VoiceFloat_IterationLoop_CheckContinue:
	ld xwa, (xsp + 54)
	or xwa, xwa
	jrl nz, VoiceFloat_IterationLoop
	lda xwa, (xsp + 74)
	lds bc, 1
	call FP_DP_CmpZero64
	cps hl, 0
	jr nz, VoiceFloat_IterationLoop_DifferentPath
	ld xwa, (xsp + 62)
	lda xbc, (xsp + 46)
	call FP_DP_Raw8Copy
	jrl VoiceFloat_CompareAndConvert_Epilog

VoiceFloat_IterationLoop_DifferentPath:
	ld xwa, (xsp + 62)
	lda_24 xbc, 0x01f676
	lda xde, (xsp + 46)
	call VoiceFloat_SubDP
	jrl VoiceFloat_CompareAndConvert_Epilog

VoiceFloat_ConvergenceLoop:
	ld16_24 xiz, 0x040c22
	sti16_24 0x040c22, 0x0000
	lda xiy, (xsp + 66)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda xwa, (xsp + 46)
	push xwa
	call VoiceAmp_ConvergeEngine
	lda xsp, (xsp + 12)
	cpdi16_24 265250, 33
	jr nz, VoiceFloat_ConvergenceLoop_Body
	ld xwa, (xsp + 62)
	lda_24 xbc, 0x01f67e
	call FP_DP_Raw8Copy
	jrl VoiceFloat_CompareAndConvert_Epilog

VoiceFloat_ConvergenceLoop_Body:
	st16_24 0x040c22, xiz
	lda xwa, (xsp + 36)
	push xwa
	lda xiy, (xsp + 70)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda xwa, (xsp + 22)
	push xwa
	call FP_DP_FreqAdjust
	lda xwa, (xsp + 50)
	push xwa
	lda xiy, (xsp + 94)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda xwa, (xsp + 30)
	push xwa
	call FP_DP_FreqAdjust
	lda xsp, (xsp + 32)
	cpw (xsp + 36), 0x0
	jr ge, VoiceFloat_ConvergenceLoop_SumCheck
	cpw (xsp + 34), 0x0
	jr ge, VoiceFloat_ConvergenceLoop_SumCheck
	ld wa, (xsp + 34)
	neg wa
	ld (xsp + 34), wa

VoiceFloat_ConvergenceLoop_SumCheck:
	ld iz, (xsp + 36)
	add iz, (xsp + 34)
	lda xwa, (xsp + 74)
	lds bc, 2
	call FP_DP_CmpZero64
	cps hl, 0
	jr nz, VoiceFloat_ConvergenceLoop_RangeCheck
	ld wa, iz
	neg wa
	ld iz, wa

VoiceFloat_ConvergenceLoop_RangeCheck:
	cp iz, 0x400
	jr le, VoiceFloat_ConvergenceLoop_Clamp
	sti16_24 0x040c22, 0x0022
	lda xwa, (xsp + 66)
	lds bc, 2
	call FP_DP_CmpZero64
	lda xwa, (xsp + 46)
	lda_24 xbc, 0x00f420
	cps hl, 0
	jr nz, VoiceFloat_ConvergenceLoop_NegResult
	call FP_DP_CopyOrNegate8
	jr VoiceFloat_ConvergenceLoop_StoreResult

VoiceFloat_ConvergenceLoop_NegResult:
	call FP_DP_Raw8Copy

VoiceFloat_ConvergenceLoop_StoreResult:
	ld xwa, (xsp + 62)
	lda xbc, (xsp + 46)
	call FP_DP_Raw8Copy
	jr VoiceFloat_CompareAndConvert_Epilog

VoiceFloat_ConvergenceLoop_Clamp:
	cp iz, 0xFC03
	jr ge, VoiceFloat_ConvergenceLoop_CrossZero
	sti16_24 0x040c22, 0x0022
	ld xwa, (xsp + 62)
	lda_24 xbc, 0x01f686
	call FP_DP_Raw8Copy
	jr VoiceFloat_CompareAndConvert_Epilog

VoiceFloat_ConvergenceLoop_CrossZero:
	lda xbc, (xsp + 38)
	lda xde, (xsp + 74)
	lda xwa, (xsp + 18)
	call FP_DP_Add_Outer
	lda xiy, (xsp + 18)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda xwa, (xsp + 54)
	push xwa
	call VoicePitch_SlideEngine
	lda xsp, (xsp + 12)
	ld xwa, (xsp + 62)
	lda xbc, (xsp + 46)
	call FP_DP_Raw8Copy

VoiceFloat_CompareAndConvert_Epilog:
	popw iz
	lda xsp, (xsp + 56)
	ret

VoiceFloat_MulAddVariant2:
	lda xsp, (xsp - 48)
	push xiz
	ld xiz, (xsp + 56)
	lda xwa, (xsp + 60)
	lds bc, 2
	call FP_DP_CmpZero64
	cps hl, 0
	jr nz, VoiceFloat_MulAddVariant2_AltPath
	pushw 0x1
	lda xbc, (xsp + 62)
	lda xwa, (xsp + 46)
	call FP_DP_CopyOrNegate8
	lda xiy, (xsp + 46)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda xiy, (xsp + 70)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda xwa, (xsp + 54)
	push xwa
	call VoiceFloat_BlendAndMerge
	lda xsp, (xsp + 22)
	ld xwa, xiz
	lda xbc, (xsp + 36)
	call FP_DP_Raw8Copy
	jr VoiceFloat_MulAddVariant2_Epilog

VoiceFloat_MulAddVariant2_AltPath:
	pushw 0x0
	lda xiy, (xsp + 62)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda xiy, (xsp + 70)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda xwa, (xsp + 46)
	push xwa
	call VoiceFloat_BlendAndMerge
	lda xsp, (xsp + 22)
	ld xwa, xiz
	lda xbc, (xsp + 28)
	call FP_DP_Raw8Copy

VoiceFloat_MulAddVariant2_Epilog:
	pop xiz
	lda xsp, (xsp + 48)
	ret

FP_MulAccum64:
	ldto_werp HL, 0xE2
	mul xhl, xbc
	ldto_werp DE, 0xE6
	mul xde, xwa
	add xhl, xde
	ldfr_werp HL, 0xEE
	lds hl, 0
	mul xwa, xbc
	add xhl, xwa
	ret

FP_DP_Sub:
	push xiz
	lda xsp, (xsp - 28)
	ld xiz, xde
	ld (xsp + 24), xwa
	ld xwa, xsp
	call FP_DP_Decode
	ld xbc, xiz
	lda xiz, (xsp + 12)
	lda xwa, (xiz)
	call FP_DP_Decode
	ld xwa, xsp
	lda xbc, (xiz)
	call FP_DP_AlignMantissa
	ld xwa, xsp
	lda xbc, (xiz)
	ld e, (xsp + 3)
	xor e, (xiz + 3)
	jr z, FP_DP_Sub_SameSign
	bitm 0, (xsp + 2)
	jr nz, FP_DP_Sub_SameSign
	call FP_DP_AddMantissa
	jr FP_DP_Sub_Done

FP_DP_Sub_SameSign:
	call FP_DP_SubMantissa

FP_DP_Sub_Done:
	ld xwa, (xsp + 24)
	ld xbc, xsp
	call FP_DP_Encode
	lda xsp, (xsp + 28)
	pop xiz
	ret

FP_SP_Sub_Pad:
	.byte 0xff

FP_SP_Sub:
	push xiz
	lda xsp, (xsp - 20)
	ld xiz, xde
	ld (xsp + 16), xwa
	ld xwa, xsp
	call FP_SP_Decode
	ld xbc, xiz
	lda xiz, (xsp + 8)
	lda xwa, (xiz)
	call FP_SP_Decode
	ld xwa, xsp
	lda xbc, (xiz)
	call FP_SP_AlignMantissa
	ld xwa, xsp
	lda xbc, (xiz)
	ld e, (xsp + 3)
	xor e, (xiz + 3)
	jr z, FP_SP_Sub_SameSign
	bitm 0, (xsp + 2)
	jr nz, FP_SP_Sub_SameSign
	call FP_SP_AddMantissa
	jr FP_SP_Sub_Done

FP_SP_Sub_SameSign:
	call FP_SP_SubMantissa

FP_SP_Sub_Done:
	ld xwa, (xsp + 16)
	ld xbc, xsp
	call FP_SP_Encode
	lda xsp, (xsp + 20)
	pop xiz
	ret

; ----------------------------------------------------------------------------
; ToneGen_Compare_Tables - Lookup tables for voice comparison results
; 0x03D978: Equal result table (6 bytes)
; 0x03D97E: Less-than result table (6 bytes)
; 0x03D984: Greater-than result table (6 bytes)
; ----------------------------------------------------------------------------
ToneGen_Compare_Tables:	; 03D977h
	.byte 0xff	; Padding
	; Equal table (0x03D978)
	.byte 0x01, 0x00, 0x01, 0x00, 0x01, 0x00
	; Less-than table (0x03D97E)
	.byte 0x01, 0x01, 0x00, 0x00, 0x00, 0x01
	; Greater-than table (0x03D984)
	.byte 0x00, 0x00, 0x01, 0x01, 0x00, 0x01

VoiceFloat_BlendAndMerge:
	lda xsp, (xsp - 128)
	push xiz
	ld_sriw WA, (xsp + 0x0092)
	and wa, 0x7FF0
	cp wa, 0x41E0
	jr c, VoiceFloat_BlendAndMerge_InRange
	sti16_24 0x040c22, 0x0022
	ld_sril XWA, (xsp + 0x0088)
	lda_24 xbc, 0x01f68e
	call FP_DP_Raw8Copy
	jrl VoiceFloat_BlendAndMerge_Epilog

VoiceFloat_BlendAndMerge_InRange:
	lda xwa, (xsp + 116)
	push xwa
	lda_24 xde, 0x00f396
	st_dri3b A, 0xFD, 0x98, 0x00
	lda xwa, (xsp + 72)
	call FP_DP_Add_Outer
	lda xiy, (xsp + 72)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda xwa, (xsp + 112)
	push xwa
	call DSP_VoiceBlend
	lda xsp, (xsp + 16)
	lda xwa, (xsp + 100)
	lda_24 xbc, 0x01f696
	lds de, 1
	call ToneGen_Compare_Voice
	cps hl, 0
	jr nz, VoiceFloat_BlendAndMerge_Phase2
	lda xwa, (xsp + 116)
	ld xbc, xwa
	lda_24 xde, 0x01f69e
	call FP_DP_Mul

VoiceFloat_BlendAndMerge_Phase2:
	lda xbc, (xsp + 116)
	lda xwa, (xsp + 64)
	call FP_DP_DecodeToInt
	ld xwa, (xsp + 64)
	bit 0, wa
	jr z, VoiceFloat_BlendAndMerge_Phase3
	cp_sriw_im 0xFD, 0x9C, 0x00, 0x00, 0x00
	scc16 z, wa
	st_dri3w WA, 0xFD, 0x9C, 0x00

VoiceFloat_BlendAndMerge_Phase3:
	st_dri3b E, 0xFD, 0x8C, 0x00
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda xwa, (xsp + 100)
	push xwa
	call FP_DP_CmpAndCopy
	lda xsp, (xsp + 12)
	lda xwa, (xsp + 92)
	st_dri3b A, 0xFD, 0x94, 0x00
	lds de, 4
	call ToneGen_Compare_Voice
	cps hl, 0
	jr nz, VoiceFloat_BlendAndMerge_Phase4
	lda xwa, (xsp + 116)
	ld xbc, xwa
	lda_24 xde, 0x01f6a6
	call FP_DP_Sub

VoiceFloat_BlendAndMerge_Phase4:
	st_dri3b W, 0xFD, 0x8C, 0x00
	push xwa
	st_dri3b E, 0xFD, 0x90, 0x00
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda xwa, (xsp + 96)
	push xwa
	call FP_DP_CmpAndCopy
	lda xsp, (xsp + 12)
	lda xiy, (xsp + 88)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda xwa, (xsp + 120)
	push xwa
	call DSP_VoiceBlend
	lda_24 xde, 0x00f39e
	st_dri3b A, 0xFD, 0x84, 0x00
	lda xwa, (xsp + 84)
	call FP_DP_Add_Outer
	st_dri3b A, 0xFD, 0x9C, 0x00
	lda xwa, (xsp + 84)
	ld xde, xwa
	call FP_DP_Sub
	lda xwa, (xsp + 84)
	ld xbc, xwa
	lda xde, (xsp + 124)
	call FP_DP_Mul
	lda_24 xbc, 0x00f38e
	lda xwa, (xsp + 72)
	call FP_DP_CopyOrNegate8
	lda xwa, (xsp + 72)
	ld xbc, xwa
	st_dri3b B, 0xFD, 0x84, 0x00
	call FP_DP_Add_Outer
	lda xbc, (xsp + 84)
	lda xde, (xsp + 72)
	st_dri3b W, 0xFD, 0x8C, 0x00
	call FP_DP_Sub
	st_dri3b E, 0xFD, 0x8C, 0x00
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda xwa, (xsp + 100)
	push xwa
	call FP_DP_CmpAndCopy
	lda xsp, (xsp + 28)
	lda_24 xbc, 0x00f3a6
	lda xwa, (xsp + 76)
	lds de, 0
	call ToneGen_Compare_Voice
	cps hl, 0
	jrl nz, VoiceFloat_BlendAndMerge_FinalCheck
	lda xde, (xsp + 124)
	ld xbc, xde
	lda xwa, (xsp + 108)
	call FP_DP_Add_Outer
	lda_24 xwa, 0x00f34e
	lda xiz, (xwa + 48)
	lda xbc, (xwa + 56)
	lda xde, (xsp + 108)
	lda xwa, (xsp + 56)
	call FP_DP_Add_Outer
	lda xwa, (xsp + 56)
	ld xbc, xwa
	ld xde, xiz
	call FP_DP_Sub
	lda xwa, (xsp + 56)
	ld xbc, xwa
	lda xde, (xsp + 108)
	call FP_DP_Add_Outer
	lda_24 xbc, 0x00f376
	lda xwa, (xsp + 56)
	ld xde, xwa
	call FP_DP_Mul
	lda xwa, (xsp + 56)
	ld xbc, xwa
	lda xde, (xsp + 108)
	call FP_DP_Add_Outer
	lda_24 xde, 0x00f36e
	lda xwa, (xsp + 56)
	ld xbc, xwa
	call FP_DP_Sub
	lda xwa, (xsp + 56)
	ld xbc, xwa
	lda xde, (xsp + 108)
	call FP_DP_Add_Outer
	lda_24 xbc, 0x00f366
	lda xwa, (xsp + 56)
	ld xde, xwa
	call FP_DP_Mul
	lda xwa, (xsp + 56)
	ld xbc, xwa
	lda xde, (xsp + 108)
	call FP_DP_Add_Outer
	lda_24 xde, 0x00f35e
	lda xwa, (xsp + 56)
	ld xbc, xwa
	call FP_DP_Sub
	lda xwa, (xsp + 56)
	ld xbc, xwa
	lda xde, (xsp + 108)
	call FP_DP_Add_Outer
	lda_24 xbc, 0x00f356
	lda xwa, (xsp + 56)
	ld xde, xwa
	call FP_DP_Mul
	lda xwa, (xsp + 56)
	ld xbc, xwa
	lda xde, (xsp + 108)
	call FP_DP_Add_Outer
	lda_24 xde, 0x00f34e
	lda xwa, (xsp + 56)
	ld xbc, xwa
	call FP_DP_Sub
	lda xwa, (xsp + 56)
	ld xbc, xwa
	lda xde, (xsp + 108)
	call FP_DP_Add_Outer
	lda xwa, (xsp + 56)
	ld xbc, xwa
	lda xde, (xsp + 124)
	call FP_DP_Add_Outer
	lda xbc, (xsp + 56)
	lda xwa, (xsp + 124)
	ld xde, xwa
	call FP_DP_Mul

VoiceFloat_BlendAndMerge_FinalCheck:
	cp_sriw_im 0xFD, 0x9C, 0x00, 0x00, 0x00
	jr z, VoiceFloat_BlendAndMerge_FinalCopy
	lda xwa, (xsp + 124)
	ld xbc, xwa
	call FP_DP_CopyOrNegate8

VoiceFloat_BlendAndMerge_FinalCopy:
	ld_sril XWA, (xsp + 0x0088)
	lda xbc, (xsp + 124)
	call FP_DP_Raw8Copy

VoiceFloat_BlendAndMerge_Epilog:
	pop xiz
	st_dri3b L, 0xFD, 0x80, 0x00
	ret

Int_SignedDiv:
	ldb e, 0x0
	bit_erpw 0xE2, 0x0F
	jr z, Int_SignedDiv_AfterSignA
	ldb e, 0x1
	cpl_werp 0xE2
	cpl wa
	inc 1, xwa

Int_SignedDiv_AfterSignA:
	bit_erpw 0xE6, 0x0F
	jr z, Int_SignedDiv_CallUnsigned
	or e, 0x2
	cpl_werp 0xE6
	cpl bc
	inc 1, xbc

Int_SignedDiv_CallUnsigned:
	pushw de
	calr FP_UnsignedDiv
	popw wa
	cps w, 1
	jr z, Int_SignedDiv_ResultCorr
	ld xhl, xde
	bit 0, a
	scc8 nz, a
	jr Int_SignedDiv_NegResult

Int_SignedDiv_ResultCorr:
	cps a, 3
	ret z

Int_SignedDiv_NegResult:
	or xhl, xhl
	ret z
	cps a, 0
	ret z
	cpl_werp 0xEE
	cpl hl
	inc 1, xhl
	ret

Int_SignedDiv_ConstData:
	.byte 0x24, 0x00, 0x68, 0xb5

Int_SignedDiv_AltEntry:
	ldb d, 0x1
	jr Int_SignedDiv
	calr FP_UnsignedDiv
	ld xhl, xde
	ret

FP_UnsignedDiv:
	cp xbc, 0x1
	jr z, FP_UnsignedDiv_ByOne
	jr c, FP_UnsignedDiv_Zero
	cp xwa, xbc
	jr ule, FP_UnsignedDiv_SmallDividend
	cpi_werp 0xE6, 0
	jr nz, FP_UnsignedDiv_General
	ld xde, xwa
	div xwa, xbc
	jr ov, FP_UnsignedDiv_Overflow
	lds32 xhl, 0
	ld xde, xhl
	ld hl, wa
	ldto_werp DE, 0xE2
	ret

FP_UnsignedDiv_Overflow:
	ldto_werp WA, 0xEA
	extz xwa
	div xwa, xbc
	ldfr_werp WA, 0xEE
	ld wa, de
	div xwa, xbc
	ld hl, wa
	ldto_werp DE, 0xE2
	extz xde
	ret

FP_UnsignedDiv_ByOne:
	ld xhl, xwa
	lds32 xde, 0
	ret

FP_UnsignedDiv_Zero:
	lds32 xhl, 0
	ld xde, xhl
	dec 1, xhl
	ret

FP_UnsignedDiv_SmallDividend:
	lds32 xhl, 1
	lds32 xde, 0
	ret z
	dec 1, xhl
	ld xde, xwa
	ret

FP_UnsignedDiv_General:
	ldb d, 0x0

FP_UnsignedDiv_ShiftLoop:
	cp xwa, xbc
	jr c, FP_UnsignedDiv_ShiftLoopDone
	inc 1, d
	add xbc, xbc
	jr nc, FP_UnsignedDiv_ShiftLoop
	extpfx3 0xD9, 0x24, 0x00
	rrc xbc
	jr FP_UnsignedDiv_Subtract

FP_UnsignedDiv_ShiftLoopDone:
	srl xbc, 1

FP_UnsignedDiv_Subtract:
	lds32 xhl, 0

FP_UnsignedDiv_SubtractLoop:
	add xhl, xhl
	cp xwa, xbc
	jr c, FP_UnsignedDiv_Done
	set 0, l
	sub xwa, xbc

FP_UnsignedDiv_Done:
	srl xbc, 1
	djnz8 d, FP_UnsignedDiv_SubtractLoop
	ld xde, xwa
	ret

FP_DP_Raw8Copy:
	ld xix, (xbc)
	ld xiy, (xbc + 4)
	ld (xwa), xix
	ld (xwa + 4), xiy
	ret

FP_DP_Raw8Copy_Pad:
	.byte 0xff

FP_DP_NegMantissaLS:
	push xiz
	lda xsp, (xsp - 12)
	ld xiz, xwa
	ld xwa, xsp
	call FP_SP_Decode
	cps l, 0
	jr nz, FP_DP_NegMantissaLS_Store
	ld xhl, (xsp + 4)
	lds32 xde, 0
	srl xhl, 1
	extpfx3 0xDA, 0x24, 0x00
	rrc xde
	srl xhl, 1
	extpfx3 0xDA, 0x24, 0x00
	rrc xde
	srl xhl, 1
	extpfx3 0xDA, 0x24, 0x00
	rrc xde
	ld (xsp + 8), xhl
	ld (xsp + 4), xde

FP_DP_NegMantissaLS_Store:
	ld xwa, xiz
	ld xbc, xsp
	call FP_DP_Encode
	lda xsp, (xsp + 12)
	pop xiz
	ret

FP_ScalarToDP_Pad:
	.byte 0xff

FP_ScalarToDP:
	push xiz
	lda xsp, (xsp - 12)
	ld xiz, xwa
	ld xwa, xsp
	ld xbc, (xbc)
	call FP_SP_Normalize
	ld xwa, xiz
	ld xbc, xsp
	call FP_DP_Encode
	lda xsp, (xsp + 12)
	pop xiz
	ret

; --- CallWithBuffer12: Allocate 12-byte stack buffer and call ---
; Entry: XWA = source data, XBC = ptr to function table
; Allocates 12 bytes on stack, calls function from table, then
; calls cleanup function. Stack buffer passed in XWA/XBC.
FP_DP_CallWithBuf12:
	push	xiz
	lda	xsp, (xsp-12)
	ld	xiz, xwa
	ld	xwa, xsp
	ld	xbc, (xbc)
	call	253935
	ld	xwa, xiz
	ld	xbc, xsp
	call	254022
	lda	xsp, (xsp+12)
	pop	xiz
	ret

FP_DP_NormalizeMantissa:
	push xiz
	lda xsp, (xsp - 12)
	ld xiz, xwa
	ld xwa, xsp
	call FP_DP_Decode
	cps l, 0
	jr nz, FP_DP_NormalizeMantissa_Encode
	ld xhl, (xsp + 8)
	ld de, (xsp + 6)
	sll de, 1
	stcf_erpw 0xEE, 0x0F
	rlc xhl
	sll de, 1
	stcf_erpw 0xEE, 0x0F
	rlc xhl
	sll de, 1
	stcf_erpw 0xEE, 0x0F
	rlc xhl
	cp d, 0x80
	jr c, FP_DP_NormalizeMantissa_StoreHL
	inc 1, xhl
	bit_erpw 0xEE, 0x07
	jr nz, FP_DP_NormalizeMantissa_StoreHL
	incm 1, (xsp + 256)
	srl xhl, 1

FP_DP_NormalizeMantissa_StoreHL:
	ld (xsp + 4), xhl

FP_DP_NormalizeMantissa_Encode:
	ld xwa, xiz
	ld xbc, xsp
	call FP_SP_Encode
	lda xsp, (xsp + 12)
	pop xiz
	ret

FP_SP_Raw4Copy_Pad:
	.byte 0xff

FP_SP_Raw4Copy:
	ld xix, (xbc)
	ld (xwa), xix
	ret

FP_SP_CallWithBuf8_Pad:
	.byte 0xff

FP_SP_CallWithBuf8:
	push xiz
	lda xsp, (xsp - 8)
	ld xiz, xwa
	ld xwa, xsp
	ld xbc, (xbc)
	call FP_DP_Normalize
	ld xwa, xiz
	ld xbc, xsp
	call FP_SP_Encode
	lda xsp, (xsp + 8)
	pop xiz
	ret

; --- CallWithBuffer8: Allocate 8-byte stack buffer and call ---
; Entry: XWA = source data, XBC = ptr to function table
; Same pattern as CallWithBuffer12 but with 8-byte buffer.
FP_SP_CallWithBuf8b:
	push	xiz
	lda	xsp, (xsp-8)
	ld	xiz, xwa
	ld	xwa, xsp
	ld	xbc, (xbc)
	call	253491
	ld	xwa, xiz
	ld	xbc, xsp
	call	254128
	lda	xsp, (xsp+8)
	pop	xiz
	ret

FP_DP_DecodeToInt:
	push xiz
	lda xsp, (xsp - 12)
	ld xiz, xwa
	ld xwa, xsp
	call FP_DP_Decode
	ld xwa, xsp
	call FP_SP_DecodeToInt
	ld (xiz), xhl
	lda xsp, (xsp + 12)
	pop xiz
	ret

FP_DP_Normalize_Pad:
	.byte 0xff

FP_DP_Normalize:
	ldb e, 0x0
	ldcf_erpw 0xE6, 0x0F
	extpfx3 0xCD, 0x24, 0x07
	jr nc, FP_DP_Normalize_StoreSign
	cpl_werp 0xE6
	cpl bc
	inc 1, xbc

FP_DP_Normalize_StoreSign:
	calr FP_DP_NormCore
	ld (xiy + 3), e
	ret

FP_DP_NormCore:
	ld xiy, xwa
	or xbc, xbc
	jr z, FP_DP_NormCore_Zero
	bs1b_erpw 0xE6
	jr ov, FP_DP_NormCore_Overflow
	add a, 0x10
	jr FP_DP_NormCore_Shift

FP_DP_NormCore_Overflow:
	extpfx2 0xD9, 0x0F

FP_DP_NormCore_Shift:
	lds hl, 0
	ld (xiy + 2), hl
	ld l, a
	ld (xiy + 256), hl
	cp l, 0x17
	jr z, FP_DP_NormCore_StoreResult
	jr lt, FP_DP_NormCore_ShiftLeft
	sub l, 0x17
	ld a, l
	srla xbc
	jr nc, FP_DP_NormCore_StoreResult
	inc 1, xbc
	bit_erpb 0xE7, 0x00
	jr z, FP_DP_NormCore_StoreResult
	srl xbc, 1
	incm8 1, (xiy + 256)
	jr FP_DP_NormCore_StoreResult

FP_DP_NormCore_ShiftLeft:
	ldb a, 0x17
	sub a, l
	cp a, 0x10
	jr lt, FP_DP_NormCore_ShiftLeftLoop
	ldfr_werp BC, 0xE6
	lds bc, 0
	sub a, 0x10
	jr z, FP_DP_NormCore_StoreResult

FP_DP_NormCore_ShiftLeftLoop:
	slla xbc

FP_DP_NormCore_StoreResult:
	ld (xiy + 4), xbc
	ret

FP_DP_NormCore_Zero:
	ld (xiy + 2), 0x1
	ret

FP_DP_ShiftDecode_Pad:
	.byte 0xff

FP_DP_ShiftDecode:
	ld xde, (xwa)
	cpi_berp 0xEA, 0
	jr nz, FP_DP_ShiftDecode_Zero
	cps de, 0
	jr lt, FP_DP_ShiftDecode_Underflow
	cp de, 0x1F
	jr gt, FP_DP_ShiftDecode_Overflow
	ld xix, (xwa + 4)
	cp de, 0x17
	jr z, FP_DP_ShiftDecode_SignCorrect
	jr lt, FP_DP_ShiftDecode_ShiftRight
	ld a, e
	sub a, 0x17
	slla xix
	jr FP_DP_ShiftDecode_SignCorrect

FP_DP_ShiftDecode_ShiftRight:
	ldb a, 0x17
	sub a, e
	cp a, 0x10
	jr lt, FP_DP_ShiftDecode_ShiftRightLoop
	ldto_werp IX, 0xF2
	extz xix
	sub a, 0x10
	jr z, FP_DP_ShiftDecode_SignCorrect

FP_DP_ShiftDecode_ShiftRightLoop:
	srla xix

FP_DP_ShiftDecode_SignCorrect:
	cpi_berp 0xEB, 0
	jr z, FP_DP_ShiftDecode_Return
	cpl_werp 0xF2
	cpl ix
	inc 1, xix

FP_DP_ShiftDecode_Return:
	ld xhl, xix
	ret

FP_DP_ShiftDecode_Underflow:
	lds32 xhl, 0
	jr FP_DP_ShiftDecode_SetError

FP_DP_ShiftDecode_Overflow:
	lds32 xhl, 0
	dec 1, xhl

FP_DP_ShiftDecode_SetError:
	sti16_24 0x040c22, 0x0022
	ret

FP_DP_ShiftDecode_Zero:
	lds32 xhl, 0
	ret

FP_DP_AddMantissa:
	ld e, (xwa + 2)
	or e, (xbc + 2)
	jp_24 nz, 0x3EA06
	ld xhl, (xwa + 8)
	ld xde, (xwa + 4)
	add xde, (xbc + 4)
	adc xhl, (xbc + 8)
	bit_erpw 0xEE, 0x05
	jr z, FP_DP_AddMantissa_Store
	srl xhl, 1
	extpfx3 0xD9, 0x24, 0x01
	extpfx3 0xDA, 0x23, 0x00
	extpfx3 0xD9, 0x24, 0x00
	rrc xde
	extpfx3 0xD9, 0x23, 0x01
	stcf_erpw 0xEA, 0x0F
	extpfx3 0xD9, 0x23, 0x00
	incm 1, (xwa + 256)
	jr nc, FP_DP_AddMantissa_Store
	add xde, 0x1
	adc xhl, 0x0

FP_DP_AddMantissa_Store:
	ld (xwa + 4), xde
	ld (xwa + 8), xhl
	ret

FP_SP_AddMantissa:
	ld e, (xwa + 2)
	or e, (xbc + 2)
	jp_24 nz, 0x3EA02
	ld xix, (xwa + 4)
	add xix, (xbc + 4)
	bit_erpw 0xF2, 0x08
	jr z, FP_SP_AddMantissa_Store
	incm 1, (xwa + 256)
	srl xix, 1
	adc xix, 0x0

FP_SP_AddMantissa_Store:
	ld (xwa + 4), xix
	ret

FP_DP_Decode_Pad:
	.byte 0xff

FP_DP_Decode:
	lds32 xhl, 0
	ld xde, (xbc)
	ld xbc, (xbc + 4)
	ldto_werp HL, 0xE6
	and_erpw 0xE6, 0x0F, 0x00
	extpfx3 0xDB, 0x23, 0x0F
	stcf_erpw 0xEE, 0x0F
	res 15, hl
	srl hl, 4
	jr z, FP_DP_Decode_Zero
	sub hl, 0x3FF
	set_erpw 0xE6, 0x04
	ld (xwa), xhl
	ldto_berp L, 0xEE
	ld (xwa + 4), xde
	ld (xwa + 8), xbc
	ret

FP_DP_Decode_Zero:
	ldb l, 0x1
	ld (xwa + 2), l
	ld (xwa + 3), 0x0
	ret

FP_SP_Decode:
	lds32 xhl, 0
	ld xix, (xbc)
	ldto_werp DE, 0xF2
	extpfx3 0xDA, 0x23, 0x0F
	stcf_erpw 0xEE, 0x0F
	ld hl, de
	sll hl, 1
	ldb l, 0x0
	ex8 h, l
	cps hl, 0
	jr z, FP_SP_Decode_Zero
	and de, 0x7F
	set 7, de
	ldfr_werp DE, 0xF2
	sub hl, 0x7F

FP_SP_Decode_Store:
	ld (xwa), xhl
	ld (xwa + 4), xix
	ldto_berp L, 0xEE
	ret

FP_SP_Decode_Zero:
	lds32 xix, 0
	ldi_berp 0xEE, 1
	jr FP_SP_Decode_Store
	swi 7

FP_SP_Normalize:
	ldb e, 0x0
	ldcf_erpw 0xE6, 0x0F
	extpfx3 0xCD, 0x24, 0x07
	jr nc, FP_SP_Normalize_StoreSign
	cpl_werp 0xE6
	cpl bc
	inc 1, xbc

FP_SP_Normalize_StoreSign:
	calr FP_SP_NormCore
	ld (xiy + 3), e
	ret

FP_SP_NormCore:
	ld xiy, xwa
	or xbc, xbc
	jr z, FP_SP_NormCore_Zero
	bs1b_erpw 0xE6
	jr ov, FP_SP_NormCore_Overflow
	add a, 0x10
	jr FP_SP_NormCore_Shift

FP_SP_NormCore_Overflow:
	extpfx2 0xD9, 0x0F

FP_SP_NormCore_Shift:
	lds hl, 0
	ld (xiy + 2), hl
	ld l, a
	ld (xiy + 256), hl
	lds32 xix, 0
	cp l, 0x14
	jr z, FP_SP_NormCore_StoreResult
	jr lt, FP_SP_NormCore_ShiftLeft
	sub l, 0x14

FP_SP_NormCore_ShiftRight:
	srl xbc, 1
	extpfx3 0xDC, 0x24, 0x00
	rrc xix
	djnz8 l, FP_SP_NormCore_ShiftRight
	jr FP_SP_NormCore_StoreResult

FP_SP_NormCore_ShiftLeft:
	ldb a, 0x14
	sub a, l
	cp a, 0x10
	jr lt, FP_SP_NormCore_ShiftLeftLoop
	ldfr_werp BC, 0xE6
	lds bc, 0
	sub a, 0x10
	jr z, FP_SP_NormCore_StoreResult

FP_SP_NormCore_ShiftLeftLoop:
	slla xbc

FP_SP_NormCore_StoreResult:
	ld (xiy + 8), xbc
	ld (xiy + 4), xix
	ret

FP_SP_NormCore_Zero:
	ld (xiy + 2), 0x1
	ret

FP_DP_Encode:
	ld xhl, (xbc)
	cpi_berp 0xEE, 0
	jr nz, FP_DP_Encode_NaN
	ld xix, (xbc + 8)
	ld xiy, (xbc + 4)
	cp hl, 0x3FF
	jr gt, FP_DP_Encode_Overflow
	cp hl, 0xFC02
	jr lt, FP_DP_Encode_Zero
	add hl, 0x3FF
	res_erpw 0xF2, 0x04
	sll hl, 4
	or_erpb_rr H, 0xEF
	or_erpw_rr HL, 0xF2
	ldfr_werp HL, 0xF2

FP_DP_Encode_Store:
	ld (xwa), xiy
	ld (xwa + 4), xix
	ret

FP_DP_Encode_Zero:
	lds32 xix, 0
	ld xiy, xix
	jr FP_DP_Encode_Store

FP_DP_Encode_NaN:
	bit_erpb 0xEE, 0x00
	jr nz, FP_DP_Encode_Zero

FP_DP_Encode_Overflow:
	sti16_24 0x040c22, 0x0022
	lds32 xde, 0
	dec 1, xde
	ld (xwa), xde
	ld xde, 0x7FEFFFFF
	ldto_berp C, 0xEF
	or_berp C, 0xEB
	ldfr_berp C, 0xEB
	ld (xwa + 4), xde
	jr __jrt_nop_03E0A5
__jrt_nop_03E0A5:

FP_DP_Encode_NormCheck:
	ld32_24 xbc, 0x00f428
	or xbc, xbc
	mrid2 0xB1, 0xEE
	ret

FP_SP_Encode_Pad:
	.byte 0xff

FP_SP_Encode:
	ld xhl, (xbc)
	cpi_berp 0xEE, 0
	jr nz, FP_SP_Encode_NaN
	ld xde, (xbc + 4)
	cp hl, 0x7F
	jr gt, FP_SP_Encode_Overflow
	cp hl, 0xFF82
	jr lt, FP_SP_Encode_Zero
	add hl, 0x7F
	ldto_werp BC, 0xEA
	res 7, bc
	sll hl, 7
	or_erpb_rr H, 0xEF
	or hl, bc
	ldfr_werp HL, 0xEA
	ld (xwa), xde
	ret

FP_SP_Encode_NaN:
	ldto_berp E, 0xEE
	cp e, 0x8
	jr nz, FP_SP_Encode_Zero
	lds32 xde, 0
	jr FP_SP_Encode_Overflow_Store

FP_SP_Encode_Zero:
	lds32 xde, 0
	ld (xwa), xde
	ret

FP_SP_Encode_Overflow:
	ldw de, 0xFFFF
	ldw bc, 0x7F7F
	or_erpb_rr B, 0xEF
	ldfr_werp BC, 0xEA

FP_SP_Encode_Overflow_Store:
	sti16_24 0x040c22, 0x0022
	ld (xwa), xde
	ld32_24 xbc, 0x00f428
	or xbc, xbc
	mrid2 0xB1, 0xEE
	ret

FP_DP_Mul:
	push xiz
	lda xsp, (xsp - 28)
	ld xiz, xde
	ld (xsp + 24), xwa
	ld xwa, xsp
	call FP_DP_Decode
	ld xbc, xiz
	lda xiz, (xsp + 12)
	lda xwa, (xiz)
	call FP_DP_Decode
	ld xwa, xsp
	lda xbc, (xiz)
	call FP_DP_AlignMantissa
	ld xwa, xsp
	lda xbc, (xiz)
	ld e, (xsp + 3)
	xor e, (xiz + 3)
	jr nz, FP_DP_Mul_DiffSign

FP_DP_Mul_SameSign:
	call FP_DP_AddMantissa
	jr FP_DP_Mul_Encode

FP_DP_Mul_DiffSign:
	bitm 0, (xsp + 2)
	jr nz, FP_DP_Mul_SameSign
	call FP_DP_SubMantissa

FP_DP_Mul_Encode:
	ld xwa, (xsp + 24)
	ld xbc, xsp
	call FP_DP_Encode
	lda xsp, (xsp + 28)
	pop xiz
	ret

FP_SP_Mul_Pad:
	.byte 0xff

FP_SP_Mul:
	push xiz
	lda xsp, (xsp - 20)
	ld xiz, xde
	ld (xsp + 16), xwa
	ld xwa, xsp
	call FP_SP_Decode
	ld xbc, xiz
	lda xiz, (xsp + 8)
	lda xwa, (xiz)
	call FP_SP_Decode
	ld xwa, xsp
	lda xbc, (xiz)
	call FP_SP_AlignMantissa
	ld xwa, xsp
	lda xbc, (xiz)
	ld e, (xsp + 3)
	xor e, (xiz + 3)
	jr nz, FP_SP_Mul_DiffSign

FP_SP_Mul_SameSign:
	call FP_SP_AddMantissa
	jr FP_SP_Mul_Encode

FP_SP_Mul_DiffSign:
	bitm 0, (xsp + 2)
	jr nz, FP_SP_Mul_SameSign
	call FP_SP_SubMantissa

FP_SP_Mul_Encode:
	ld xwa, (xsp + 16)
	ld xbc, xsp
	call FP_SP_Encode
	lda xsp, (xsp + 20)
	pop xiz
	ret

DSP_VoiceBlend:
	lda xsp, (xsp - 24)
	push xiz
	lda_24 xbc, 0x01f6ae
	lda xwa, (xsp + 20)
	call FP_DP_Raw8Copy
	lda xiy, (xsp + 36)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda xwa, (xsp + 20)
	push xwa
	call DSP_VoiceRegUpdate
	lda xsp, (xsp + 12)
	ld xiz, (xsp + 44)
	ld xwa, xiz
	lda xbc, (xsp + 12)
	call FP_DP_Raw8Copy
	ld xde, xiz
	lda xbc, (xsp + 36)
	lda xwa, (xsp + 20)
	call FP_DP_Sub
	ld xwa, (xsp + 32)
	lda xbc, (xsp + 20)
	call FP_DP_Raw8Copy
	pop xiz
	lda xsp, (xsp + 24)
	ret

FP_DP_FreqAdjust:
	dec 8, xsp
	pushw iz
	lda xwa, (xsp + 2)
	lda xbc, (xsp + 18)
	call FP_DP_Raw8Copy
	ld xwa, (xsp + 26)
	ldw (xwa), 0x0
	lda xwa, (xsp + 18)
	lds bc, 5
	call FP_DP_CmpZero64
	ld xix, (xsp + 14)
	cps hl, 0
	jr nz, FP_DP_FreqAdjust_NonZeroExp
	ld xwa, xix
	lda xbc, (xsp + 18)
	call FP_DP_Raw8Copy
	jr FP_DP_FreqAdjust_Return

FP_DP_FreqAdjust_NonZeroExp:
	lda xde, (xsp + 2)
	lda xbc, (xde + 6)
	ld a, (xbc)
	and a, 0xF0
	extz wa
	ld iz, wa
	srl iz, 4
	lda xiy, (xde + 7)
	ld l, (xiy)
	res 7, l
	extz hl
	sll hl, 4
	add hl, iz
	ld iz, hl
	sub iz, 0x3FE
	ld xwa, (xsp + 26)
	ld (xwa), iz
	lds iz, 0
	cpw (xwa), 0x0
	jr gt, FP_DP_FreqAdjust_DecCheck
	jr FP_DP_FreqAdjust_IncCheck

FP_DP_FreqAdjust_DecLoop:
	dec 1, hl
	inc 1, iz

FP_DP_FreqAdjust_DecCheck:
	ld xwa, (xsp + 26)
	cp iz, (xwa)
	jr lt, FP_DP_FreqAdjust_DecLoop
	jr FP_DP_FreqAdjust_Combine

FP_DP_FreqAdjust_IncLoop:
	inc 1, hl
	dec 1, iz

FP_DP_FreqAdjust_IncCheck:
	ld xwa, (xsp + 26)
	cp iz, (xwa)
	jr gt, FP_DP_FreqAdjust_IncLoop

FP_DP_FreqAdjust_Combine:
	sll hl, 4
	ld a, (xbc)
	and a, 0xF
	extz wa
	or hl, wa
	bitm 7, (xiy)
	jr z, FP_DP_FreqAdjust_StoreResult
	set 15, hl

FP_DP_FreqAdjust_StoreResult:
	ld (xbc), hl
	ld xwa, xix
	ld xbc, xde
	call FP_DP_Raw8Copy

FP_DP_FreqAdjust_Return:
	popw iz
	inc 8, xsp
	ret

FP_DP_Add_Outer_Pad:
	.byte 0xff

FP_DP_Add_Outer:
	push xiz
	lda xsp, (xsp - 28)
	ld xiz, xde
	ld (xsp + 24), xwa
	ld xwa, xsp
	call FP_DP_Decode
	ld xbc, xiz
	lda xiz, (xsp + 12)
	lda xwa, (xiz)
	call FP_DP_Decode
	ld xwa, xsp
	lda xbc, (xiz)
	call FP_DP_MulAdd
	ld xwa, (xsp + 24)
	ld xbc, xsp
	call FP_DP_Encode
	lda xsp, (xsp + 28)
	pop xiz
	ret

FP_SP_Add_Outer:
	push xiz
	lda xsp, (xsp - 20)
	ld xiz, xde
	ld (xsp + 16), xwa
	ld xwa, xsp
	call FP_SP_Decode
	ld xbc, xiz
	lda xiz, (xsp + 8)
	lda xwa, (xiz)
	call FP_SP_Decode
	ld xwa, xsp
	lda xbc, (xiz)
	call FP_SP_MulAdd
	ld xwa, (xsp + 16)
	ld xbc, xsp
	call FP_SP_Encode
	lda xsp, (xsp + 20)
	pop xiz
	ret

FP_DP_AlignMantissa:
	ld h, (xwa + 2)
	or h, (xbc + 2)
	ret nz
	ld ix, (xwa + 256)
	ld iy, (xbc + 256)
	cp ix, iy
	ret z
	jr lt, FP_DP_AlignMantissa_ShiftA
	ld (xbc + 256), ix
	ld xwa, xbc
	sub ix, iy
	jr FP_DP_AlignMantissa_Shift

FP_DP_AlignMantissa_ShiftA:
	ld (xwa + 256), iy
	sub ix, iy
	neg ix

FP_DP_AlignMantissa_Shift:
	ld xde, (xwa + 3)
	ld xhl, (xwa + 7)
	ldb e, 0x0
	cp ix, 0x35
	jr gt, FP_DP_AlignMantissa_MaxShift
	cp ix, 0x20
	jr lt, FP_DP_AlignMantissa_Shift16
	ld xde, xhl
	lds32 xhl, 0
	sub ix, 0x20
	jr z, FP_DP_AlignMantissa_Round

FP_DP_AlignMantissa_Shift16:
	cp ix, 0x10
	jr lt, FP_DP_AlignMantissa_Shift8
	ldto_werp DE, 0xEA
	ldfr_werp HL, 0xEA
	ldto_werp HL, 0xEE
	ldi_werp 0xEE, 0
	sub ix, 0x10
	jr z, FP_DP_AlignMantissa_Round

FP_DP_AlignMantissa_Shift8:
	cp ix, 0x8
	jr lt, FP_DP_AlignMantissa_ShiftBit
	srl xde, 8
	ldfr_berp L, 0xEB
	srl xhl, 8
	sub ix, 0x8
	jr z, FP_DP_AlignMantissa_Round

FP_DP_AlignMantissa_ShiftBit:
	srl xhl, 1
	extpfx3 0xDA, 0x24, 0x00
	rrc xde
	djnz xix, FP_DP_AlignMantissa_ShiftBit

FP_DP_AlignMantissa_Round:
	ld c, e
	srl xde, 8
	ldfr_berp L, 0xEB
	srl xhl, 8
	cp c, 0x80
	jr c, FP_DP_AlignMantissa_Store
	add xde, 0x1
	jr nc, FP_DP_AlignMantissa_Store
	adc xhl, 0x0

FP_DP_AlignMantissa_Store:
	ld (xwa + 4), xde
	ld (xwa + 8), xhl
	ret

FP_DP_AlignMantissa_MaxShift:
	lds32 xde, 0
	ld (xwa), xde
	ld (xwa + 4), xde
	ld (xwa + 8), xde
	ld (xwa + 2), 0x1
	ret

FP_SP_AlignMantissa_Pad:
	.byte 0xff

FP_SP_AlignMantissa:
	ld e, (xwa + 2)
	or e, (xbc + 2)
	ret nz
	ld ix, (xwa + 256)
	ld hl, (xbc + 256)
	cp ix, hl
	ret z
	jr lt, FP_SP_AlignMantissa_ShiftA
	ex16 hl, ix
	jr FP_SP_AlignMantissa_Shift

FP_SP_AlignMantissa_ShiftA:
	ld xbc, xwa

FP_SP_AlignMantissa_Shift:
	ld xde, (xbc + 3)
	ldb e, 0x0
	ld (xbc + 256), hl
	sub hl, ix
	cp hl, 0x18
	jr gt, FP_SP_AlignMantissa_MaxShift
	bit 4, l
	jr z, FP_SP_AlignMantissa_Shift_Odd
	srl xde, 0
	and l, 0xF
	jr z, FP_SP_AlignMantissa_Round

FP_SP_AlignMantissa_Shift_Odd:
	ld a, l
	srla xde

FP_SP_AlignMantissa_Round:
	ld l, e
	srl xde, 8
	cp l, 0x80
	jr c, FP_SP_AlignMantissa_Store
	inc 1, xde

FP_SP_AlignMantissa_Store:
	ld (xbc + 4), xde
	ret

FP_SP_AlignMantissa_MaxShift:
	lds32 xix, 0
	ld (xbc + 4), xix
	ldi_berp 0xF2, 1
	ld (xbc), xix
	ret

FP_DP_Mul_Outer:
	ld e, (xwa + 2)
	or e, (xbc + 2)
	jp_24 nz, 0x3E884
	ld l, (xbc + 3)
	xor (xwa + 3), l
	ld hl, (xbc + 256)
	sub (xwa + 256), hl
	ld xhl, (xbc + 8)
	ld xde, (xbc + 4)
	cp xhl, 0x100000
	jr nz, FP_DP_MulMantissaCore
	or xde, xde
	ret z

FP_DP_MulMantissaCore:
	push xiz
	lda xsp, (xsp - 12)
	ld xiy, (xwa + 8)
	ld xix, (xwa + 4)
	ldb c, 0x8
	ldto_berp B, 0xEF
	lds32 xiz, 0
	call FP_Div_Step_Bit3
	ld (xsp), xiz
	ldb c, 0x8
	lds32 xiz, 0
	call FP_Div_Step4Bits
	ld (xsp + 4), xiz
	ld xiy, (xsp)
	ld xix, (xsp + 4)
	bit_erpw 0xF6, 0x0F
	jr nz, FP_DP_MulMantissaCore_Round
	sll xix, 1
	stcf_erpw 0xF6, 0x0F
	rlc xiy
	decm 1, (xwa + 256)

FP_DP_MulMantissaCore_Round:
	ld bc, ix
	srl bc, 3
	srl xix, 8
	ldto_berp E, 0xF4
	ldfr_berp E, 0xF3
	srl xiy, 8
	srl xiy, 1
	extpfx3 0xDC, 0x24, 0x00
	rrc xix
	srl xiy, 1
	extpfx3 0xDC, 0x24, 0x00
	rrc xix
	srl xiy, 1
	extpfx3 0xDC, 0x24, 0x00
	rrc xix
	cp c, 0x80
	jr c, FP_DP_MulMantissaCore_Store
	add xix, 0x1
	adc xiy, 0x0
	bit_erpw 0xF6, 0x04
	jr nz, FP_DP_MulMantissaCore_Store
	srl xiy, 1
	extpfx3 0xDC, 0x24, 0x00
	rrc xix
	incm 1, (xwa + 256)

FP_DP_MulMantissaCore_Store:
	ld (xwa + 8), xiy
	ld (xwa + 4), xix
	lda xsp, (xsp + 12)
	pop xiz
	ret

FP_SP_Mul_Outer_Pad:
	.byte 0xff

FP_SP_Mul_Outer:
	ld e, (xwa + 2)
	or e, (xwa + 2)
	jp_24 nz, 0x3E884
	push xiz
	push xwa
	ld hl, (xbc + 256)
	sub (xwa + 256), hl
	ld l, (xbc + 3)
	xor (xwa + 3), l
	ld xwa, (xwa + 4)
	ld xbc, (xbc + 4)
	cp xbc, 0x800000
	jr z, FP_SP_MulMantissaCore_Divisor1
	lds32 xhl, 0
	ld xix, xbc
	add xix, xix
	ld xiy, xix
	add xiy, xiy
	ld xiz, xiy
	add xiz, xiz
	ldw de, 0x8
	sll xwa, 3

FP_SP_MulMantissaCore_Loop:
	cp xwa, xiz
	jr c, FP_SP_MulMantissaCore_Bit2
	sub xwa, xiz
	set 3, l

FP_SP_MulMantissaCore_Bit2:
	cp xwa, xiy
	jr c, FP_SP_MulMantissaCore_Bit1
	sub xwa, xiy
	set 2, l

FP_SP_MulMantissaCore_Bit1:
	cp xwa, xix
	jr c, FP_SP_MulMantissaCore_Bit0
	sub xwa, xix
	set 1, l

FP_SP_MulMantissaCore_Bit0:
	cp xwa, xbc
	jr c, FP_SP_MulMantissaCore_IterDone
	sub xwa, xbc
	set 0, l

FP_SP_MulMantissaCore_IterDone:
	dec 1, e
	jr z, FP_SP_MulMantissaCore_Round
	sll xhl, 4
	sll xwa, 4
	jr FP_SP_MulMantissaCore_Loop

FP_SP_MulMantissaCore_Round:
	pop xwa
	bit_erpw 0xEE, 0x0F
	jr nz, FP_SP_MulMantissaCore_RoundUp
	sll xhl, 1
	decm 1, (xwa + 256)

FP_SP_MulMantissaCore_RoundUp:
	cp l, 0x80
	jr c, FP_SP_MulMantissaCore_Shift8
	add xhl, 0x100
	jr nc, FP_SP_MulMantissaCore_Shift8
	extpfx3 0xDB, 0x24, 0x00
	rrc xhl

FP_SP_MulMantissaCore_Shift8:
	srl xhl, 8

FP_SP_MulMantissaCore_Store:
	ld (xwa + 4), xhl
	pop xiz
	ret

FP_SP_MulMantissaCore_Divisor1:
	ld xhl, xwa
	pop xwa
	jr FP_SP_MulMantissaCore_Store

FP_DP_SubMantissa:
	ld e, (xwa + 2)
	or e, (xbc + 2)
	jp_24 nz, 0x3EE3A
	ld xhl, (xwa + 8)
	ld xde, (xwa + 4)
	sub xde, (xbc + 4)
	sbc xhl, (xbc + 8)
	ldb b, 0x0
	jr nc, FP_DP_SubMantissa_NoBorrow
	ldb b, 0x80
	lds32 xiy, 0
	dec 1, xiy
	xor xde, xiy
	xor xhl, xiy
	add xde, 0x1
	adc xhl, 0x0
	jr FP_DP_SubMantissa_Normalize

FP_DP_SubMantissa_NoBorrow:
	ld xiy, xhl
	or xiy, xde
	jr z, FP_DP_SubMantissa_Zero

FP_DP_SubMantissa_Normalize:
	bit_erpw 0xEE, 0x04
	jr nz, FP_DP_SubMantissa_Store
	ld iy, wa
	ld ix, (xwa + 256)

FP_DP_SubMantissa_NormLoop:
	bs1b_erpw 0xEE
	jr nov, FP_DP_SubMantissa_Shift
	ldfr_werp HL, 0xEE
	ldto_werp HL, 0xEA
	ldfr_werp DE, 0xEA
	lds de, 0
	sub ix, 0x10
	jr FP_DP_SubMantissa_NormLoop

FP_DP_SubMantissa_Shift:
	cps a, 4
	jr lt, FP_DP_SubMantissa_ShiftLeft
	dec 4, a
	extz wa
	add ix, wa
	cp a, 0x8
	jr lt, FP_DP_SubMantissa_ShiftBit
	srl xde, 8
	ldfr_berp L, 0xEB
	srl xhl, 8
	dec 8, a
	jr z, FP_DP_SubMantissa_StoreExp

FP_DP_SubMantissa_ShiftBit:
	srl xhl, 1
	extpfx3 0xDA, 0x24, 0x00
	rrc xde
	djnz8 a, FP_DP_SubMantissa_ShiftBit
	jr FP_DP_SubMantissa_StoreExp

FP_DP_SubMantissa_ShiftLeft:
	sll xde, 1
	stcf_erpw 0xEE, 0x0F
	rlc xhl
	dec 1, ix
	bit_erpw 0xEE, 0x04
	jr z, FP_DP_SubMantissa_ShiftLeft

FP_DP_SubMantissa_StoreExp:
	ld wa, iy
	ld (xwa + 256), ix

FP_DP_SubMantissa_Store:
	ld (xwa + 4), xde
	ld (xwa + 8), xhl
	xor (xwa + 3), b
	ret

FP_DP_SubMantissa_Zero:
	ld (xwa + 2), 0x1
	ret

FP_SP_SubMantissa:
	ld e, (xwa + 2)
	or e, (xbc + 2)
	jp_24 nz, 0x3EE36
	ld xiy, xwa
	ld de, (xwa + 256)
	ld xix, (xwa + 4)
	sub xix, (xbc + 4)
	ldb b, 0x0
	jr z, FP_SP_SubMantissa_Zero
	jr nc, FP_SP_SubMantissa_Normalize
	cpl_werp 0xF2
	cpl ix
	inc 1, xix
	ldb b, 0x80

FP_SP_SubMantissa_Normalize:
	cpi_werp 0xF2, 0
	jr nz, FP_SP_SubMantissa_AlignBits
	sll xix, 8
	dec 8, de
	jr FP_SP_SubMantissa_Normalize

FP_SP_SubMantissa_AlignBits:
	ldb w, 0x7
	bs1b_erpw 0xF2
	sub w, a
	ld a, w
	jr z, FP_SP_SubMantissa_Store
	extz wa
	slla xix
	sub de, wa

FP_SP_SubMantissa_Store:
	ld (xiy + 4), xix
	ld (xiy + 256), de
	xor (xiy + 3), b
	ret

FP_SP_SubMantissa_Zero:
	ld (xiy + 4), xix
	ldi_berp 0xF2, 1
	ld (xiy), xix
	ret

VoicePitch_SlideEngine:
	lda xsp, (xsp - 48)
	pushw iz
	lda_24 xbc, 0x01f6b6
	lda xwa, (xsp + 34)
	call FP_DP_Raw8Copy
	lda xwa, (xsp + 58)
	lds bc, 5
	call FP_DP_CmpZero64
	cps hl, 0
	jr nz, VoicePitch_SlideEngine_NonZero
	ld xwa, (xsp + 54)
	lda xbc, (xsp + 34)
	call FP_DP_Raw8Copy
	jrl VoicePitch_SlideEngine_Epilog

VoicePitch_SlideEngine_NonZero:
	lda_24 xbc, 0x01f6be
	lda xwa, (xsp + 42)
	call FP_DP_Raw8Copy
	lda xwa, (xsp + 58)
	lda_24 xbc, 0x01f6c6
	lds de, 0
	call ToneGen_Compare_Voice
	cps hl, 0
	jr nz, VoicePitch_SlideEngine_LessPath
	sti16_24 0x040c22, 0x0022
	ld xwa, (xsp + 54)
	lda_24 xbc, 0x00f420
	call FP_DP_Raw8Copy
	jrl VoicePitch_SlideEngine_Epilog

VoicePitch_SlideEngine_LessPath:
	lda xwa, (xsp + 58)
	lda_24 xbc, 0x01f6ce
	lds de, 2
	call ToneGen_Compare_Voice
	cps hl, 0
	jr nz, VoicePitch_SlideEngine_StartIter
	ld xwa, (xsp + 54)
	lda_24 xbc, 0x01f6d6
	call FP_DP_Raw8Copy
	jr VoicePitch_SlideEngine_Epilog

VoicePitch_SlideEngine_StartIter:
	lds iz, 1

VoicePitch_SlideEngine_IterLoop:
	lda xbc, (xsp + 34)
	lda xwa, (xsp + 26)
	call FP_DP_Raw8Copy
	ld wa, iz
	exts xwa
	ld (xsp + 22), xwa
	lda xbc, (xsp + 22)
	lda xwa, (xsp + 14)
	call FP_ScalarToDP
	lda xbc, (xsp + 58)
	lda xwa, (xsp + 14)
	ld xde, xwa
	call VoiceFloat_SubDP
	lda xwa, (xsp + 42)
	ld xbc, xwa
	lda xde, (xsp + 14)
	call FP_DP_Add_Outer
	lda xwa, (xsp + 34)
	ld xbc, xwa
	lda xde, (xsp + 42)
	call FP_DP_Mul
	lda xwa, (xsp + 26)
	lda xbc, (xsp + 34)
	lds de, 5
	call ToneGen_Compare_Voice
	cps hl, 0
	jr z, VoicePitch_SlideEngine_Done
	inc 1, iz
	cp iz, 0x12C
	jr le, VoicePitch_SlideEngine_IterLoop

VoicePitch_SlideEngine_Done:
	ld xwa, (xsp + 54)
	lda xbc, (xsp + 34)
	call FP_DP_Raw8Copy

VoicePitch_SlideEngine_Epilog:
	popw iz
	lda xsp, (xsp + 48)
	ret

VoiceAmp_ConvergeEngine:
	lda xsp, (xsp - 102)
	push xiz
	lda xwa, (xsp + 114)
	lds bc, 3
	call FP_DP_CmpZero64
	cps hl, 0
	jr nz, VoiceAmp_ConvergeEngine_InRange
	sti16_24 0x040c22, 0x0021
	ld xwa, (xsp + 110)
	lda_24 xbc, 0x01f6de
	call FP_DP_Raw8Copy
	jrl VoiceAmp_ConvergeEngine_Epilog

VoiceAmp_ConvergeEngine_InRange:
	lda xwa, (xsp + 104)
	push xwa
	lda_24 xde, 0x00f42c
	lda xbc, (xsp + 118)
	lda xwa, (xsp + 52)
	call VoiceFloat_SubDP
	lda xiy, (xsp + 52)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda xwa, (xsp + 76)
	push xwa
	call FP_DP_FreqAdjust
	pushm (xsp + 120)
	lda_24 xiy, 0x01f6e6
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda xwa, (xsp + 82)
	push xwa
	call VoiceFreq_EnvelopeStep
	lda xsp, (xsp + 30)
	lda xwa, (xsp + 114)
	ld xbc, xwa
	lda xde, (xsp + 56)
	call VoiceFloat_SubDP
	lda xbc, (xsp + 114)
	lda_24 xde, 0x01f6ee
	lda xwa, (xsp + 48)
	call FP_DP_Mul
	lda xbc, (xsp + 114)
	lda_24 xde, 0x01f6f6
	lda xwa, (xsp + 72)
	call FP_DP_Sub
	lda xbc, (xsp + 72)
	lda xde, (xsp + 48)
	lda xwa, (xsp + 114)
	call VoiceFloat_SubDP
	lda xde, (xsp + 114)
	ld xbc, xde
	lda xwa, (xsp + 96)
	call FP_DP_Add_Outer
	lds iz, 1
	lda xbc, (xsp + 114)
	lda xwa, (xsp + 88)
	call FP_DP_Raw8Copy

VoiceAmp_ConvergeEngine_IterLoop:
	lda xwa, (xsp + 114)
	ld xbc, xwa
	lda xde, (xsp + 96)
	call FP_DP_Add_Outer
	inc 2, iz
	lda xbc, (xsp + 88)
	lda xwa, (xsp + 80)
	call FP_DP_Raw8Copy
	ld wa, iz
	exts xwa
	ld (xsp + 40), xwa
	lda xbc, (xsp + 40)
	lda xwa, (xsp + 72)
	call FP_ScalarToDP
	lda xbc, (xsp + 114)
	lda xwa, (xsp + 72)
	ld xde, xwa
	call VoiceFloat_SubDP
	lda xwa, (xsp + 88)
	ld xbc, xwa
	lda xde, (xsp + 72)
	call FP_DP_Mul
	lda xwa, (xsp + 80)
	lda xbc, (xsp + 88)
	lds de, 5
	call ToneGen_Compare_Voice
	cps hl, 0
	jr nz, VoiceAmp_ConvergeEngine_IterLoop
	lda_24 xiz, 0x00f3d2
	ld wa, (xsp + 104)
	exts xwa
	ld (xsp + 44), xwa
	lda xbc, (xsp + 44)
	lda xwa, (xsp + 72)
	call FP_ScalarToDP
	lda xwa, (xsp + 72)
	ld xbc, xwa
	ld xde, xiz
	call FP_DP_Add_Outer
	lda xbc, (xsp + 88)
	lda_24 xde, 0x01f6fe
	lda xwa, (xsp + 48)
	call FP_DP_Add_Outer
	lda xbc, (xsp + 48)
	lda xwa, (xsp + 72)
	ld xde, xwa
	call FP_DP_Mul
	ld xwa, (xsp + 110)
	lda xbc, (xsp + 72)
	call FP_DP_Raw8Copy

VoiceAmp_ConvergeEngine_Epilog:
	pop xiz
	lda xsp, (xsp + 102)
	ret

FP_NaN_Handler_Pad:
	.byte 0xff

FP_NaN_Handler:
	ld h, (xwa + 2)
	ld l, (xbc + 2)
	bit 0, l
	ret z
	ld (xwa + 2), 0x8
	ret

DSP_VoiceRegUpdate:
	lda xsp, (xsp - 28)
	push xiz
	ld xiy, 0x1F706
	lda xix, (xsp + 24)
	lds bc, 4
	ldirw
	lda xwa, (xsp + 16)
	lda xbc, (xsp + 40)
	call FP_DP_Raw8Copy
	lda xhl, (xsp + 16)
	lda xbc, (xhl + 6)
	ld wa, (xbc)
	and wa, 0x7FF0
	srl wa, 4
	cps wa, 0
	jr z, DSP_VoiceRegUpdate_ZeroOrMax
	cp wa, 0x7FF
	jr nz, DSP_VoiceRegUpdate_InRange

DSP_VoiceRegUpdate_ZeroOrMax:
	ld xwa, (xsp + 36)
	lda_24 xbc, 0x01f70e
	call FP_DP_Raw8Copy
	jrl DSP_VoiceRegUpdate_Return

DSP_VoiceRegUpdate_InRange:
	ld (xsp + 4), wa
	sub wa, 0x3FF
	cp wa, 0x28
	jr ge, DSP_VoiceRegUpdate_NegOffset
	lda xde, (xsp + 24)
	ldw (xde), 0xF
	ld wa, (xbc)
	and wa, 0xFFF0
	ld (xde + 6), wa
	ld xiz, xhl
	ld xbc, xiz
	ld xwa, xiz
	call FP_DP_Mul
	lda xde, (xsp + 24)
	ldw (xde), 0x0
	lda xiz, (xsp + 16)
	ld xbc, xiz
	ld xwa, xiz
	call FP_DP_Sub
	ld wa, (xsp + 22)
	and wa, 0x7FF0
	srl wa, 4
	ld (xsp + 4), wa
	sub wa, 0x3FF

DSP_VoiceRegUpdate_NegOffset:
	cps wa, 0
	jr ge, DSP_VoiceRegUpdate_LargeOffset
	ld xwa, (xsp + 36)
	lda_24 xbc, 0x01f716
	call FP_DP_Raw8Copy
	jrl DSP_VoiceRegUpdate_Return

DSP_VoiceRegUpdate_LargeOffset:
	cp wa, 0x34
	jr lt, DSP_VoiceRegUpdate_BlendLoop
	ld xwa, (xsp + 36)
	lda xbc, (xsp + 40)
	call FP_DP_Raw8Copy
	jrl DSP_VoiceRegUpdate_Return

DSP_VoiceRegUpdate_BlendLoop:
	ld iy, wa
	exts xiy
	divs iy, 0x8
	exts xwa
	divs wa, 0x8
	ldto_werp WA, 0xE2
	ld (xsp + 6), wa
	lda xhl, (xsp + 16)
	lda xix, (xsp + 8)
	ld xbc, xix
	lda xwa, (xhl + 6)
	ld xde, xwa
	lda xiz, (xwa - 6)

DSP_VoiceRegUpdate_ForwardScan:
	ld w, (xde - 1)
	srl w, 4
	ld a, (xde)
	sll a, 4
	or a, w
	lda_dpi XBC, 0xE4
	dec 1, xde
	cp xde, xiz
	jr ugt, DSP_VoiceRegUpdate_ForwardScan
	ld a, (xhl)
	sll a, 4
	ld (xix + 6), a
	lds wa, 6
	cps iy, 6
	jr ge, DSP_VoiceRegUpdate_BackScan

DSP_VoiceRegUpdate_FillPad:
	stib_dri 0x07, 0xF0, 0xE0, 0x00
	dec 1, wa
	cp wa, iy
	jr gt, DSP_VoiceRegUpdate_FillPad

DSP_VoiceRegUpdate_BackScan:
	st_dri3b B, 0x07, 0xF0, 0xF4
	cpw (xsp + 6), 0x0
	jr z, DSP_VoiceRegUpdate_ZeroLow
	ldw wa, 0x8
	sub wa, (xsp + 6)
	ldw bc, 0xFF
	and a, 0xF
	jr z, DSP_VoiceRegUpdate_MaskLow
	slaa bc

DSP_VoiceRegUpdate_MaskLow:
	and (xde), c
	jr DSP_VoiceRegUpdate_BackScan2

DSP_VoiceRegUpdate_ZeroLow:
	ld (xde), 0x0

DSP_VoiceRegUpdate_BackScan2:
	ld xbc, xhl
	lda xwa, (xix + 6)
	ld xde, xwa
	lda xiy, (xwa - 6)

DSP_VoiceRegUpdate_BackScanLoop:
	ld w, (xde - 1)
	sll w, 4
	ld a, (xde)
	srl a, 4
	or a, w
	lda_dpi XBC, 0xE4
	dec 1, xde
	cp xde, xiy
	jr ugt, DSP_VoiceRegUpdate_BackScanLoop
	lda xbc, (xhl + 6)
	ld a, (xix)
	srl a, 4
	ld (xbc), a
	andmi16 (xbc), 0x800F
	ld wa, (xsp + 4)
	sll wa, 4
	or (xbc), wa
	ld xwa, (xsp + 36)
	ld xbc, xhl
	call FP_DP_Raw8Copy

DSP_VoiceRegUpdate_Return:
	pop xiz
	lda xsp, (xsp + 28)
	ret

FP_CopyVariant_Pad:
	.byte 0xff

FP_DP_CopyNoSign:
	ldb d, 0x0
	jr FP_DP_CopyDispatch

FP_DP_CopyWithSign:
	ldb d, 0x1
	jr FP_DP_CopyDispatch
	ldb d, 0x2
	jr __jrt_nop_03EA0E
__jrt_nop_03EA0E:

FP_DP_CopyDispatch:
	bitm 0, (xbc + 2)
	ret nz
	cps d, 0
	jr nz, FP_DP_Copy3Words
	ld xhl, (xbc)
	ld xde, (xbc + 4)
	ld (xwa), xhl
	ld (xwa + 4), xde
	ret

FP_DP_Copy3Words:
	ld xhl, (xbc)
	ld (xwa), xhl
	ld xhl, (xbc + 4)
	ld (xwa + 4), xhl
	ld xhl, (xbc + 8)
	ld (xwa + 8), xhl
	ret

FP_SP_DecodeToInt_Pad:
	.byte 0xff

FP_SP_DecodeToInt:
	ld xde, (xwa)
	cpi_berp 0xEA, 0
	jr nz, FP_SP_DecodeToInt_NaN
	cps de, 0
	jr lt, FP_SP_DecodeToInt_Underflow
	cp de, 0x1F
	jr gt, FP_SP_DecodeToInt_Overflow
	ld xiy, (xwa + 8)
	ld ix, (xwa + 6)
	cp de, 0x14
	jr z, FP_SP_DecodeToInt_SignCorrect
	jr lt, FP_SP_DecodeToInt_ShiftRight
	sub e, 0x14

FP_SP_DecodeToInt_ShiftLeft:
	sll ix, 1
	stcf_erpw 0xF6, 0x0F
	rlc xiy
	djnz8 e, FP_SP_DecodeToInt_ShiftLeft
	jr FP_SP_DecodeToInt_SignCorrect

FP_SP_DecodeToInt_ShiftRight:
	ldb a, 0x14
	sub a, e
	cp a, 0x10
	jr lt, FP_SP_DecodeToInt_ShiftRightLoop
	ldto_werp IY, 0xF6
	extz xiy
	sub a, 0x10
	jr z, FP_SP_DecodeToInt_SignCorrect

FP_SP_DecodeToInt_ShiftRightLoop:
	srla xiy

FP_SP_DecodeToInt_SignCorrect:
	cpi_berp 0xEB, 0
	jr z, FP_SP_DecodeToInt_Return
	cpl_werp 0xF6
	cpl iy
	inc 1, xiy

FP_SP_DecodeToInt_Return:
	ld xhl, xiy
	ret

FP_SP_DecodeToInt_Underflow:
	lds32 xhl, 0
	jr FP_SP_DecodeToInt_SetError

FP_SP_DecodeToInt_Overflow:
	lds32 xhl, 0
	dec 1, xhl

FP_SP_DecodeToInt_SetError:
	sti16_24 0x040c22, 0x0022
	ret

FP_SP_DecodeToInt_NaN:
	lds32 xhl, 0
	ret

VoiceFreq_EnvelopeStep:
	lda xsp, (xsp - 16)
	pushw iz
	lda xwa, (xsp + 10)
	lda xbc, (xsp + 26)
	call FP_DP_Raw8Copy
	lda xwa, (xsp + 26)
	lds bc, 5
	call FP_DP_CmpZero64
	ld xde, (xsp + 22)
	cps hl, 0
	jr nz, VoiceFreq_EnvelopeStep_InRange
	lda_24 xbc, 0x01f71e
	ld xwa, xde
	call FP_DP_Raw8Copy
	jrl VoiceFreq_EnvelopeStep_Epilog

VoiceFreq_EnvelopeStep_InRange:
	ld bc, (xsp + 34)
	lda xwa, (xsp + 10)
	lda xhl, (xwa + 7)
	cp bc, 0x7FF
	jr le, VoiceFreq_EnvelopeStep_ClampLow
	sti16_24 0x040c22, 0x0022
	lda_24 xbc, 0x00f420
	bitm 7, (xhl)
	jr z, VoiceFreq_EnvelopeStep_ClampHigh
	ld xwa, xde
	call FP_DP_CopyOrNegate8
	jrl VoiceFreq_EnvelopeStep_Epilog

VoiceFreq_EnvelopeStep_ClampHigh:
	ld xwa, xde
	call FP_DP_Raw8Copy
	jrl VoiceFreq_EnvelopeStep_Epilog

VoiceFreq_EnvelopeStep_ClampLow:
	cp bc, 0xF801
	jr ge, VoiceFreq_EnvelopeStep_NibbleAdjust
	lda_24 xbc, 0x01f726
	ld xwa, xde
	call FP_DP_Raw8Copy
	jrl VoiceFreq_EnvelopeStep_Epilog

VoiceFreq_EnvelopeStep_NibbleAdjust:
	ld (xsp + 2), xwa
	inc 6, xwa
	ld (xsp + 6), xwa
	ld a, (xwa)
	ldfr_berp A, 0xE2
	and a, 0xF0
	extz wa
	ld iy, wa
	sra iy, 4
	ld xix, xhl
	ld l, (xhl)
	ld a, l
	res 7, a
	extz wa
	sla wa, 4
	add wa, iy
	ld iy, wa
	lds iz, 0
	cps bc, 0
	jr le, VoiceFreq_EnvelopeStep_DecCheck
	cps bc, 0
	jr le, VoiceFreq_EnvelopeStep_StoreResult

VoiceFreq_EnvelopeStep_IncLoop:
	ld wa, iy
	inc 1, wa
	cp wa, 0x7FF
	jr c, VoiceFreq_EnvelopeStep_IncStep
	sti16_24 0x040c22, 0x0022
	lda_24 xbc, 0x00f420
	ld a, (xix)
	bit 7, a
	jr z, VoiceFreq_EnvelopeStep_IncClamp_Copy
	ld xwa, xde
	call FP_DP_CopyOrNegate8
	jr VoiceFreq_EnvelopeStep_Epilog

VoiceFreq_EnvelopeStep_IncClamp_Copy:
	ld xwa, xde
	call FP_DP_Raw8Copy
	jr VoiceFreq_EnvelopeStep_Epilog

VoiceFreq_EnvelopeStep_IncStep:
	inc 1, iy
	inc 1, iz
	cp iz, bc
	jr lt, VoiceFreq_EnvelopeStep_IncLoop
	jr VoiceFreq_EnvelopeStep_StoreResult

VoiceFreq_EnvelopeStep_DecCheck:
	cps bc, 0
	jr ge, VoiceFreq_EnvelopeStep_StoreResult

VoiceFreq_EnvelopeStep_DecLoop:
	ld wa, iy
	sub wa, 0x1
	jr nz, VoiceFreq_EnvelopeStep_DecStep
	sti16_24 0x040c22, 0x0022
	lda_24 xbc, 0x01f72e
	ld xwa, xde
	call FP_DP_Raw8Copy
	jr VoiceFreq_EnvelopeStep_Epilog

VoiceFreq_EnvelopeStep_DecStep:
	dec 1, iy
	dec 1, iz
	cp iz, bc
	jr gt, VoiceFreq_EnvelopeStep_DecLoop

VoiceFreq_EnvelopeStep_StoreResult:
	sll iy, 4
	ldto_berp C, 0xE2
	and c, 0xF
	extz bc
	ld wa, iy
	or wa, bc
	ld iy, wa
	bit 7, l
	jr z, VoiceFreq_EnvelopeStep_SetHighBit
	set 15, iy

VoiceFreq_EnvelopeStep_SetHighBit:
	ld bc, iy
	ld xwa, (xsp + 6)
	ld (xwa), bc
	ld xbc, (xsp + 2)
	ld xwa, xde
	call FP_DP_Raw8Copy

VoiceFreq_EnvelopeStep_Epilog:
	popw iz
	lda xsp, (xsp + 16)
	ret

FP_DP_MulAdd_Pad:
	.byte 0xff

FP_DP_MulAdd:
	ld e, (xwa + 2)
	or e, (xbc + 2)
	jp_24 nz, 0x3EE70
	push xiz
	lda xsp, (xsp - 16)
	ld xhl, (xbc)
	add (xwa + 256), hl
	ldto_berp L, 0xEF
	xor (xwa + 3), l
	ld xhl, (xwa + 4)
	ld xiy, (xbc + 4)
	call FP_MulMantissa64x64
	ld (xsp), xhl
	ld (xsp + 4), xde
	ld xhl, (xwa + 8)
	ld xiy, (xbc + 8)
	call FP_MulMantissa64x64
	ld (xsp + 8), xhl
	ld (xsp + 12), xde
	ld xhl, (xwa + 4)
	ld xiy, (xbc + 8)
	call FP_MulMantissa64x64
	add (xsp + 4), xhl
	adc (xsp + 8), xde
	jr nc, FP_DP_MulAdd_Sum1
	lds32 xhl, 0
	adc (xsp + 12), xhl

FP_DP_MulAdd_Sum1:
	ld xhl, (xwa + 8)
	ld xiy, (xbc + 4)
	call FP_MulMantissa64x64
	add (xsp + 4), xhl
	adc (xsp + 8), xde
	jr nc, FP_DP_MulAdd_Sum2
	lds32 xhl, 0
	adc (xsp + 12), xhl

FP_DP_MulAdd_Sum2:
	ld ix, (xsp + 5)
	ld xde, (xsp + 7)
	ld xhl, (xsp + 11)
	bit_erpw 0xEE, 0x01
	jr z, FP_DP_MulAdd_Round
	incm 1, (xwa + 256)
	srl xhl, 1
	extpfx3 0xDA, 0x24, 0x00
	rrc xde
	extpfx3 0xDC, 0x24, 0x00
	rrc ix

FP_DP_MulAdd_Round:
	ldto_berp C, 0xF1
	ldto_berp B, 0xEB
	srl c, 4
	srl b, 4
	sll xhl, 4
	sll xde, 4
	sll ix, 4
	or e, c
	or l, b
	cp_erpb 0xF1, 0x80
	jr c, FP_DP_MulAdd_Store
	add xde, 0x1
	adc xhl, 0x0
	bit_erpw 0xEE, 0x04
	jr nz, FP_DP_MulAdd_Store
	srl xhl, 1
	extpfx3 0xDA, 0x24, 0x00
	rrc xde
	incm 1, (xwa + 256)

FP_DP_MulAdd_Store:
	ld (xwa + 4), xde
	ld (xwa + 8), xhl
	lda xsp, (xsp + 16)
	pop xiz
	ret

FP_SP_MulAdd:
	ld e, (xwa + 2)
	or e, (xbc + 2)
	jp_24 nz, 0x3EE70
	push xiz
	ld xiz, xwa
	ld xhl, (xbc)
	add (xwa + 256), hl
	ldto_berp L, 0xEF
	xor (xwa + 3), l
	ld xwa, (xwa + 4)
	ld xbc, (xbc + 4)
	ldto_werp DE, 0xE2
	ld hl, de
	ldto_werp IX, 0xE6
	mul xde, xix
	mul xhl, xbc
	mul xix, xwa
	mul xwa, xbc
	add xhl, xix
	ex_erpw_rr DE, 0xEA
	add xde, xhl
	ldto_werp HL, 0xE2
	extz xhl
	add xde, xhl
	bit_erpw 0xEA, 0x0F
	jr z, FP_SP_MulAdd_NormCheck
	incm 1, (xiz + 256)
	jr FP_SP_MulAdd_Round

FP_SP_MulAdd_NormCheck:
	sll wa, 1
	stcf_erpw 0xEA, 0x0F
	rlc xde

FP_SP_MulAdd_Round:
	cp e, 0x80
	jr c, FP_SP_MulAdd_Store
	add xde, 0x100
	jr nc, FP_SP_MulAdd_Store
	extpfx3 0xDA, 0x24, 0x00
	rrc xde
	incm 1, (xiz + 256)

FP_SP_MulAdd_Store:
	srl xde, 8
	ld (xiz + 4), xde
	pop xiz
	ret

FP_MulMantissa64x64:
	ldto_werp DE, 0xEE
	ld ix, de
	ldto_werp IZ, 0xF6
	mul xde, xiz
	mul xix, xiy
	mul xiz, xhl
	mul xhl, xiy
	add xix, xiz
	adc_erpw 0xEA, 0x00, 0x00
	add_erpw_rr DE, 0xF2
	adc_erpw 0xEA, 0x00, 0x00
	add_erpw_rr IX, 0xEE
	ld2_erpw_rr IX, 0xEE
	ret nc
	adc xde, 0x0
	ret

FP_Div_Step4Bits:
	sll xix, 1
	stcf_erpw 0xE6, 0x01
	ldcf_erpw 0xF6, 0x0F
	stcf_erpw 0xE6, 0x00
	rlc xiy
	ldcf_erpw 0xE6, 0x01
	extpfx3 0xDD, 0x24, 0x00
	ldcf_erpw 0xE6, 0x00
	jr nc, FP_Div_Step_Bit3
	sub xix, xde
	sbc xiy, xhl
	set 3, iz
	jr FP_Div_Step_Bit2_Entry

FP_Div_Step_Bit3:
	cp_erpb_rr B, 0xF7
	jr gt, FP_Div_Step_Bit2_Entry
	sub xix, xde
	sbc xiy, xhl
	jr nc, FP_Div_Step_Bit3_Set
	add xix, xde
	adc xiy, xhl
	jr FP_Div_Step_Bit2_Entry

FP_Div_Step_Bit3_Set:
	set 3, iz

FP_Div_Step_Bit2_Entry:
	sll xix, 1
	stcf_erpw 0xE6, 0x01
	ldcf_erpw 0xF6, 0x0F
	stcf_erpw 0xE6, 0x00
	rlc xiy
	ldcf_erpw 0xE6, 0x01
	extpfx3 0xDD, 0x24, 0x00
	ldcf_erpw 0xE6, 0x00
	jr nc, FP_Div_Step_Bit2
	sub xix, xde
	sbc xiy, xhl
	set 2, iz
	jr FP_Div_Step_Bit1_Entry

FP_Div_Step_Bit2:
	cp_erpb_rr B, 0xF7
	jr gt, FP_Div_Step_Bit1_Entry
	sub xix, xde
	sbc xiy, xhl
	jr nc, FP_Div_Step_Bit2_Set
	add xix, xde
	adc xiy, xhl
	jr FP_Div_Step_Bit1_Entry

FP_Div_Step_Bit2_Set:
	set 2, iz

FP_Div_Step_Bit1_Entry:
	sll xix, 1
	stcf_erpw 0xE6, 0x01
	ldcf_erpw 0xF6, 0x0F
	stcf_erpw 0xE6, 0x00
	rlc xiy
	ldcf_erpw 0xE6, 0x01
	extpfx3 0xDD, 0x24, 0x00
	ldcf_erpw 0xE6, 0x00
	jr nc, FP_Div_Step_Bit1
	sub xix, xde
	sbc xiy, xhl
	set 1, iz
	jr FP_Div_Step_Bit0_Entry

FP_Div_Step_Bit1:
	cp_erpb_rr B, 0xF7
	jr gt, FP_Div_Step_Bit0_Entry
	sub xix, xde
	sbc xiy, xhl
	jr nc, FP_Div_Step_Bit1_Set
	add xix, xde
	adc xiy, xhl
	jr FP_Div_Step_Bit0_Entry

FP_Div_Step_Bit1_Set:
	set 1, iz

FP_Div_Step_Bit0_Entry:
	sll xix, 1
	stcf_erpw 0xE6, 0x01
	ldcf_erpw 0xF6, 0x0F
	stcf_erpw 0xE6, 0x00
	rlc xiy
	ldcf_erpw 0xE6, 0x01
	extpfx3 0xDD, 0x24, 0x00
	ldcf_erpw 0xE6, 0x00
	jr nc, FP_Div_Step_Bit0
	sub xix, xde
	sbc xiy, xhl
	set 0, iz
	jr FP_Div_Step_Continue

FP_Div_Step_Bit0:
	cp_erpb_rr B, 0xF7
	jr gt, FP_Div_Step_Continue
	sub xix, xde
	sbc xiy, xhl
	jr nc, FP_Div_Step_Bit0_Set
	add xix, xde
	adc xiy, xhl
	jr FP_Div_Step_Continue

FP_Div_Step_Bit0_Set:
	set 0, iz

FP_Div_Step_Continue:
	dec 1, c
	ret z
	sll xiz, 4
	jrl FP_Div_Step4Bits

FP_DP_NegNoSign:
	ldb d, 0x0
	jr FP_DP_NegDispatch

FP_DP_NegWithSign:
	ldb d, 0x1
	jr FP_DP_NegDispatch
	ldb d, 0x2
	jr __jrt_nop_03EE42
__jrt_nop_03EE42:

FP_DP_NegDispatch:
	bitm 0, (xbc + 2)
	ret nz
	cps d, 0
	jr nz, FP_DP_Neg3Words
	ld xhl, (xbc)
	ld xde, (xbc + 4)
	ld (xwa), xhl
	ld (xwa + 4), xde
	xormi8 (xwa + 3), 0x80
	ret

FP_DP_Neg3Words:
	ld xhl, (xbc)
	ld (xwa), xhl
	ld xhl, (xbc + 4)
	ld (xwa + 4), xhl
	ld xhl, (xbc + 8)
	ld (xwa + 8), xhl
	xormi8 (xwa + 3), 0x80
	ret

FP_Overflow_Handler_Pad:
	.byte 0xff

FP_Overflow_Handler:
	ld (xwa + 2), 0x1
	ret

FP_Library_End_Pad:
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.byte 0xff, 0xff, 0xff

; Labels emitted as .set (exact addresses from ORG/name)
	.set PAYLOAD_LOADED_FLAG, 0x0004FE
	.set SERIAL_1_VAR_1034, 0x001034
	.set SERIAL_1_VAR_1038, 0x001038
	.set DMA_XFER_STATE, 0x0010E8
	.set CMD_PROCESSING_STATE, 0x0010EA
	.set BYTE_FROM_MAINCPU_LATCH, 0x0010EC
