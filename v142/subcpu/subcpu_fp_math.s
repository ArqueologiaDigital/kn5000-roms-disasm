; *(double*)XWA = -*(double*)XBC. Copies the 8 bytes low half first, then flips bit 7 of
; the top byte (the IEEE-754 double sign bit) via the xor_erpb pseudo-op before storing
; the high half. If XWA == XBC it tail-jumps to FP_DP_NegateInPlace8 instead of copying.
; Touches no hardware. Used everywhere a negated constant or a sign flip is needed:
; pow() 0x03D66B/0x03D6B7/0x03D7ED, sin kernel 0x03DAB8/0x03DBFD, ldexp 0x03EAE9/0x03EB5F,
; and the DSP curve code.
FP_DP_CopyOrNegate8:
	cp xwa, xbc
	jr z, FP_DP_NegateInPlace8
	ld xhl, (xbc)
	ld (xwa), xhl
	ld xhl, (xbc + 4)
	xor_erpb 0xEF, 0x80
	ld (xwa + 4), xhl
	ret

; In-place double negate: xor (XWA+7),0x80; ret. Also a standalone entry point.
FP_DP_NegateInPlace8:
	xormi8 (xwa + 7), 0x80
	ret

; *(float*)XWA = -*(float*)XBC. Single-precision twin of FP_DP_CopyOrNegate8; flips bit 7
; of the top byte of the 4-byte word. Falls through to FP_SP_NegateInPlace4 when
; XWA == XBC.
FP_SP_CopyOrNegate4:
	cp xwa, xbc
	jr z, FP_SP_NegateInPlace4
	ld xhl, (xbc)
	xor_erpb 0xEF, 0x80
	ld (xwa), xhl
	ret

; In-place float negate: xor (XWA+3),0x80; ret.
FP_SP_NegateInPlace4:
	xormi8 (xwa + 3), 0x80
	ret

; fabs(double). C signature f(double *result, double x): result pointer at (XSP+4),
; the 8-byte argument at (XSP+8). Calls FP_DP_CmpZero64 with BC = 1 (the "< 0" relation,
; see [DATA] 0x03D978) and, if x < 0, negate-copies via FP_DP_CopyOrNegate8, otherwise
; raw-copies via FP_DP_Raw8Copy. Caller pops 12 bytes. Callers: the sin kernel
; 0x03DA2F / 0x03DA6C / 0x03DAE9 and cos 0x03D361.
; NOTE: the name is a mechanical description of the body; the routine is fabs().
; RENAMED 2026-09-25: was FP_DP_CmpAndCopy (scripts/renaming/rename_v142_fp_libm.sed); the name now says
; what the header above established.
FP_fabs:
	lda xwa, (xsp + 8)
	ld bc, 1:i3
	call FP_DP_CmpZero64
	lda xbc, (xsp + 8)
	ld xwa, (xsp + 4)
	cp hl, 0:i3
	jr nz, FP_fabs_Negate
	call FP_DP_Raw8Copy
	ret

; x < 0 arm of fabs(): result = -x.
FP_fabs_Negate:
	call FP_DP_CopyOrNegate8
	ret

; --- 0x03D44B-0x03D44B  FP_fabs_Pad (0xFF alignment byte)
; One 0xFF pad byte inserted by the linker between routines. There are ~14 of these in
; the region; each is already named *_Pad and none is reachable code.
; One 0xFF fill byte, never executed (it follows `ret`), at an odd address so that
; FP_ftoi starts on the next even address.  All 20 *_Pad bytes in this file are 0xFF at odd
; addresses (measured 2026-09-25); the library aligns some routines to 2 bytes, not all.
FP_fabs_Pad:
	.byte 0xff

; (int32)(float) conversion. XWA = pointer to the int32 result, XBC = pointer to the
; float. Allocates an 8-byte unpacked record on the stack, calls FP_SP_Decode to unpack
; the float, then FP_DP_ShiftDecode to shift the mantissa to integer position, and
; stores XHL to *XIZ. Sets ERANGE (via FP_DP_ShiftDecode) on out-of-range.
; NOTE: the name describes the first instruction, not the function; this is __ftoi.
; RENAMED 2026-09-25: was FP_SP_Decode_ReadSign (scripts/renaming/rename_v142_fp_libm.sed); the name now says
; what the header above established.
FP_ftoi:
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

; One 0xFF fill byte, never executed (it follows `ret`), at an odd address so that
; FP_DP_CmpZero64 starts on the next even address.  All 20 *_Pad bytes in this file are 0xFF at odd
; addresses (measured 2026-09-25); the library aligns some routines to 2 bytes, not all.
FP_ftoi_Pad:
	.byte 0xff

; Relational compare of a double against 0.0, returning a C boolean in HL.
; XWA = pointer to the double, BC = relation selector 0..5 (see [DATA] 0x03D978).
; Compares the high 4 bytes against 0 first, then the low 4; picks one of the three
; 6-byte result rows (equal / less / greater) and returns row[BC]. Called ~15 times
; inside this region (pow, exp, ldexp, frexp, sin, modf) and never from outside.
FP_DP_CmpZero64:
	ld hl, 0:i3
	ld xde, 0:i3
	ld xiy, (xwa + 4)
	cp xiy, xde
	jr lt, FP_DP_CmpZero64_Less
	jr gt, FP_DP_CmpZero64_Greater
	ld xiy, (xwa)
	cp xiy, xde
	jr nz, FP_DP_CmpZero64_Greater
	lda xde, (FP_CmpResult_Equal:24)
	ldb_sri L, 0x07, 0xE8, 0xE4
	ret

; x < 0: return LessRow[BC].
FP_DP_CmpZero64_Less:
	lda xde, (FP_CmpResult_Less:24)
	ldb_sri L, 0x07, 0xE8, 0xE4
	ret

; x > 0 (and the "high words differ" shortcut): return GreaterRow[BC].
FP_DP_CmpZero64_Greater:
	lda xde, (FP_CmpResult_Greater:24)
	ldb_sri L, 0x07, 0xE8, 0xE4
	ret

; Single-precision twin of FP_DP_CmpZero64: relational compare of *(float*)XWA against
; 0.0 with relation BC, result in HL. Uses the same three 6-byte rows at 0x03D978.
; No caller inside this region; reached only from the DSP curve code.
FP_SP_CmpZero32:
	ld hl, 0:i3
	ld xde, (xwa)
	cp xde, 0x0
	jr lt, FP_SP_CmpZero32_Less
	jr gt, FP_SP_CmpZero32_Greater
	lda xde, (FP_CmpResult_Equal:24)
	ldb_sri L, 0x07, 0xE8, 0xE4
	ret

; x < 0 arm.
FP_SP_CmpZero32_Less:
	lda xde, (FP_CmpResult_Less:24)
	ldb_sri L, 0x07, 0xE8, 0xE4
	ret

; x > 0 arm.
FP_SP_CmpZero32_Greater:
	lda xde, (FP_CmpResult_Greater:24)
	ldb_sri L, 0x07, 0xE8, 0xE4
	ret

; tan(double). C signature f(double *result, double x). Loads the exponent word of x
; ((XSP+0x3A), i.e. bytes 6..7 of the argument), masks 0x7FF0 and compares against
; 0x41E0: if |x| >= 2^31 the argument cannot be reduced, so errno=ERANGE and the result
; is the constant 0.0 at 0x01F63E. Otherwise it calls FP_cos
; (= cos, 0x03D34D) and FP_sin (= sin, 0x03D84F) on the same x and
; divides with FP_ddiv (= double divide, 0x03D3A4): result = sin(x)/cos(x).
; 3 callers, all in the DSP curve block: 0x03A9A9, 0x03AE9B, 0x03B0B3.
; NOTE: nothing in this routine multiplies, adds or dispatches; the name is wrong.
; RENAMED 2026-09-25: was VoiceFloat_MulAddDispatch (scripts/renaming/rename_v142_fp_libm.sed); the name now says
; what the header above established.
FP_tan:
	lda xsp, (xsp - 40)
	push xiz
	ld xiz, (xsp + 48)
	ld wa, (xsp + 58)
	and wa, 0x7FF0
	cp wa, 0x41E0
	jr c, FP_tan_InRange
	ldw (0x040c22:24), 0x0022
	ld xwa, xiz
	lda xbc, (FPConst_tan_Zero:24)
	call FP_DP_Raw8Copy
	jr FP_tan_Epilog

; |x| < 2^31 arm of tan(): compute cos into the local at entrySP-0x10, sin into
; entrySP-0x18, then divide sin by cos.
FP_tan_InRange:
	lda xiy, (xsp + 52)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda xwa, (xsp + 36)
	push xwa
	call FP_cos
	lda xiy, (xsp + 64)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda xwa, (xsp + 40)
	push xwa
	call FP_sin
	lda xsp, (xsp + 24)
	lda xbc, (xsp + 20)
	lda xde, (xsp + 28)
	lda xwa, (xsp + 36)
	call FP_ddiv
	ld xwa, xiz
	lda xbc, (xsp + 36)
	call FP_DP_Raw8Copy

; tan() epilogue: pop XIZ, release the 0x28-byte frame.
FP_tan_Epilog:
	pop xiz
	lda xsp, (xsp + 40)
	ret

; pow(double x, double y). C signature f(double *result, double x, double y); result
; pointer at entrySP+4, x at entrySP+8, y at entrySP+0x10. Structure, all arms verified:
;   (1) if y is outside [-2147483647, +2147483647] (constants 0x01F646 / 0x01F64E) the
;       integer form n is set to 0xFFFFFFFF, otherwise n = (int)y via FP_DP_DecodeToInt.
;   (2) if x < 0 and (double)n != y  -> errno = EDOM (0x21), result = 1.0 (0x01F656).
;       This is the textbook "negative base with non-integer exponent" domain error and
;       is what identifies the routine.
;   (3) if y <= 0 and x == 0         -> errno = EDOM, result = 1.0 (0x01F65E).
;   (4) if (double)n == y (integer exponent) -> binary exponentiation, see
;       FP_pow_IntPower.
;   (5) otherwise -> exp(y * log(x)) via FP_pow_ExpLog.
; 21 callers, all in the DSP curve block (0x03937D ... 0x03BA14) - this is the single
; most-used libm function in the firmware.
; NOTE: the name is wrong; it is pow().
; RENAMED 2026-09-25: was VoiceFloat_CompareAndConvert (scripts/renaming/rename_v142_fp_libm.sed); the name now says
; what the header above established.
FP_pow:
	lda xsp, (xsp - 56)
	pushw iz
	lda xwa, (xsp + 74)
	lda xbc, (FPConst_Int32_Min_As_Double:24)
	ld de, 1:i3
	call FP_dcmp
	cp hl, 0:i3
	jr nz, FP_pow_Invalid
	lda xwa, (xsp + 74)
	lda xbc, (FPConst_Int32_Max_As_Double:24)
	ld de, 3:i3
	call FP_dcmp
	cp hl, 0:i3
	jr nz, FP_pow_Invalid
	lda xbc, (xsp + 74)
	lda xwa, (xsp + 54)
	call FP_DP_DecodeToInt
	jr FP_pow_AfterRange

; y not representable as int32: store n = 0xFFFFFFFF so the integer test below fails.
FP_pow_Invalid:
	ld xwa, 0xFFFFFFFF
	ld (xsp + 54), xwa

; pow(): x < 0 branch - reject a non-integer exponent with EDOM.
FP_pow_AfterRange:
	lda xwa, (xsp + 66)
	ld bc, 2:i3
	call FP_DP_CmpZero64
	cp hl, 0:i3
	jr nz, FP_pow_AltPath
	lda xbc, (xsp + 54)
	lda xwa, (xsp + 18)
	call FP_ScalarToDP
	lda xwa, (xsp + 18)
	lda xbc, (xsp + 74)
	ld de, 4:i3
	call FP_dcmp
	cp hl, 0:i3
	jr nz, FP_pow_AltPath
	ldw (0x040c22:24), 0x0021
	ld xwa, (xsp + 62)
	lda xbc, (FPConst_pow_AfterRange_One:24)
	call FP_DP_Raw8Copy
	jrl FP_pow_Epilog

; pow(): x >= 0 branch - reject pow(0, y<=0) with EDOM.
FP_pow_AltPath:
	lda xwa, (xsp + 74)
	ld bc, 3:i3
	call FP_DP_CmpZero64
	cp hl, 0:i3
	jr nz, FP_pow_AltPath2
	lda xwa, (xsp + 66)
	ld bc, 5:i3
	call FP_DP_CmpZero64
	cp hl, 0:i3
	jr nz, FP_pow_AltPath2
	ldw (0x040c22:24), 0x0021
	ld xwa, (xsp + 62)
	lda xbc, (FPConst_pow_AltPath_One:24)
	call FP_DP_Raw8Copy
	jrl FP_pow_Epilog

; pow(): choose between the integer-exponent path and the exp/log path by testing
; (double)n == y; then take |n| and seed the accumulator with 1.0 (0x01F666).
FP_pow_AltPath2:
	lda xbc, (xsp + 54)
	lda xwa, (xsp + 18)
	call FP_ScalarToDP
	lda xwa, (xsp + 18)
	lda xbc, (xsp + 74)
	ld de, 5:i3
	call FP_dcmp
	cp hl, 0:i3
	jrl nz, FP_pow_ExpLog
	ld xwa, (xsp + 54)
	cp xwa, 0x0
	jr ge, FP_pow_IntPower_Seed
	ld xwa, (xsp + 54)
	cpl wa
	cplw_erp 0xE2
	inc 1, xwa
	ld (xsp + 54), xwa

; pow(): n was already >= 0; seed the accumulator with 1.0 and enter the loop test.
FP_pow_IntPower_Seed:
	lda xbc, (FPConst_pow_IntPower_Seed_One:24)
	lda xwa, (xsp + 46)
	call FP_DP_Raw8Copy
	jrl FP_pow_IntPower_CheckContinue

; pow() integer-exponent kernel: classic square-and-multiply over |n|.
; Each pass calls FP_frexp (= frexp) on the running base to get its exponent,
; doubles that exponent and compares against -1021 (0xFC03) and +1024 (0x0400) to detect
; the next squaring overflowing or underflowing BEFORE it happens; on overflow it sets
; errno=ERANGE and returns +/-DBL_MAX (0x00F420), on underflow +/-0.0. If bit 0 of the
; remaining exponent is set the accumulator is multiplied by the base
; (FP_dmul, which is the double MULTIPLY), then the base is squared and the
; exponent is shifted right by one (sra 1). Terminates in at most 32 passes.
; RENAMED 2026-09-25: was VoiceFloat_IterationLoop (scripts/renaming/rename_v142_fp_libm.sed); the name now says
; what the header above established.
FP_pow_IntPower:
	lda xwa, (xsp + 36)
	push xwa
	lda xiy, (xsp + 70)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda xwa, (xsp + 38)
	push xwa
	call FP_frexp
	lda xsp, (xsp + 16)
	ld wa, (xsp + 36)
	add wa, wa
	cp wa, 0xFC03
	jr ge, FP_pow_IntPower_LargeStep
	lda xwa, (xsp + 74)
	ld bc, 2:i3
	call FP_DP_CmpZero64
	cp hl, 0:i3
	jr nz, FP_pow_IntPower_LessPath
	ldw (0x040c22:24), 0x0022
	lda xwa, (xsp + 66)
	ld bc, 2:i3
	call FP_DP_CmpZero64
	lda xbc, (FPConst_MaxNorm:24)
	cp hl, 0:i3
	jr nz, FP_pow_IntPower_GreaterPath
	lda xwa, (xsp + 46)
	call FP_DP_CopyOrNegate8
	jr FP_pow_IntPower_CopyResult

; Overflow with a positive base: result = +DBL_MAX.
FP_pow_IntPower_GreaterPath:
	lda xwa, (xsp + 46)
	call FP_DP_Raw8Copy
	jr FP_pow_IntPower_CopyResult

; Underflow: result = 0.0 (0x01F66E).
FP_pow_IntPower_LessPath:
	lda xbc, (FPConst_pow_IntPower_LessPath_Zero:24)
	lda xwa, (xsp + 46)
	call FP_DP_Raw8Copy

; Store the saturated result to *result and return.
FP_pow_IntPower_CopyResult:
	ld xwa, (xsp + 62)
	lda xbc, (xsp + 46)
	call FP_DP_Raw8Copy
	jrl FP_pow_Epilog

; 2*exponent >= -1021: check the upper limit (+1024) before squaring.
FP_pow_IntPower_LargeStep:
	lda xde, (xsp + 66)
	cp wa, 0x400
	jr le, FP_pow_IntPower_SmallStep
	ldw (0x040c22:24), 0x0022
	ld xwa, xde
	ld bc, 2:i3
	call FP_DP_CmpZero64
	cp hl, 0:i3
	jr nz, FP_pow_IntPower_LargeStep_NegPath
	lda xbc, (FPConst_MaxNorm:24)
	lda xwa, (xsp + 46)
	call FP_DP_CopyOrNegate8
	jr FP_pow_IntPower_LargeStep_Copy

; Overflow with a negative base: result = -DBL_MAX.
FP_pow_IntPower_LargeStep_NegPath:
	lda xbc, (FPConst_MaxNorm:24)
	lda xwa, (xsp + 46)
	call FP_DP_Raw8Copy

; Store the ERANGE-saturated result and return.
FP_pow_IntPower_LargeStep_Copy:
	ld xwa, (xsp + 62)
	lda xbc, (xsp + 46)
	call FP_DP_Raw8Copy
	jrl FP_pow_Epilog

; Exponent in range: test bit 0 of the remaining integer exponent.
FP_pow_IntPower_SmallStep:
	ld xwa, (xsp + 54)
	bit 0, wa
	jr z, FP_pow_IntPower_SmallStep_Add
	lda xwa, (xsp + 46)
	ld xbc, xwa
	call FP_dmul

; Square the base (base = base * base) and shift the exponent right one bit.
FP_pow_IntPower_SmallStep_Add:
	lda xwa, (xsp + 66)
	ld xbc, xwa
	ld xde, xwa
	call FP_dmul
	ld xwa, (xsp + 54)
	sra xwa, 1
	ld (xsp + 54), xwa

; Loop while the remaining exponent is non-zero; then, if the ORIGINAL exponent was
; negative, take the reciprocal (1.0 / acc) via FP_ddiv.
FP_pow_IntPower_CheckContinue:
	ld xwa, (xsp + 54)
	or xwa, xwa
	jrl nz, FP_pow_IntPower
	lda xwa, (xsp + 74)
	ld bc, 1:i3
	call FP_DP_CmpZero64
	cp hl, 0:i3
	jr nz, FP_pow_IntPower_DifferentPath
	ld xwa, (xsp + 62)
	lda xbc, (xsp + 46)
	call FP_DP_Raw8Copy
	jrl FP_pow_Epilog

; Negative integer exponent: result = 1.0 (0x01F676) / accumulator.
FP_pow_IntPower_DifferentPath:
	ld xwa, (xsp + 62)
	lda xbc, (FPConst_pow_IntPower_DifferentPath_One:24)
	lda xde, (xsp + 46)
	call FP_ddiv
	jrl FP_pow_Epilog

; pow() general path: result = exp(y * log(x)). Saves errno (0x040C22) in IZ, clears it,
; calls FP_log (= log, 0x03E731) on x, and if log() set EDOM returns
; 0.0 (0x01F67E). Otherwise it restores errno and does the over/underflow pre-check in
; exponent space: frexp(log(x)) and frexp(y) via FP_frexp, adds the two
; exponents, and if the sum exceeds +1024 -> ERANGE and +/-DBL_MAX, if below -1021 ->
; ERANGE and 0.0 (0x01F686). Only when the product is representable does it multiply
; y*log(x) (FP_dmul) and call FP_exp (= exp, 0x03E64B).
; This exponent pre-check is why pow() never actually feeds a huge argument to exp().
; RENAMED 2026-09-25: was VoiceFloat_ConvergenceLoop (scripts/renaming/rename_v142_fp_libm.sed); the name now says
; what the header above established.
FP_pow_ExpLog:
	ld iz, (0x040c22:24)
	ldw (0x040c22:24), 0x0000
	lda xiy, (xsp + 66)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda xwa, (xsp + 46)
	push xwa
	call FP_log
	lda xsp, (xsp + 12)
	cpw (265250:24), 33
	jr nz, FP_pow_ExpLog_Body
	ld xwa, (xsp + 62)
	lda xbc, (FPConst_pow_ExpLog_Zero:24)
	call FP_DP_Raw8Copy
	jrl FP_pow_Epilog

; Restore errno and frexp both operands into (XSP+0x24) and (XSP+0x22).
FP_pow_ExpLog_Body:
	ld (0x040c22:24), iz
	lda xwa, (xsp + 36)
	push xwa
	lda xiy, (xsp + 70)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda xwa, (xsp + 22)
	push xwa
	call FP_frexp
	lda xwa, (xsp + 50)
	push xwa
	lda xiy, (xsp + 94)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda xwa, (xsp + 30)
	push xwa
	call FP_frexp
	lda xsp, (xsp + 32)
	cpw (xsp + 36), 0x0
	jr ge, FP_pow_ExpLog_SumCheck
	cpw (xsp + 34), 0x0
	jr ge, FP_pow_ExpLog_SumCheck
	ld wa, (xsp + 34)
	neg wa
	ld (xsp + 34), wa

; IZ = exponent(log x) + exponent(y), negated when y < 0.
FP_pow_ExpLog_SumCheck:
	ld iz, (xsp + 36)
	add iz, (xsp + 34)
	lda xwa, (xsp + 74)
	ld bc, 2:i3
	call FP_DP_CmpZero64
	cp hl, 0:i3
	jr nz, FP_pow_ExpLog_RangeCheck
	ld wa, iz
	neg wa
	ld iz, wa

; IZ > 1024 -> ERANGE, result = +/-DBL_MAX.
FP_pow_ExpLog_RangeCheck:
	cp iz, 0x400
	jr le, FP_pow_ExpLog_Clamp
	ldw (0x040c22:24), 0x0022
	lda xwa, (xsp + 66)
	ld bc, 2:i3
	call FP_DP_CmpZero64
	lda xwa, (xsp + 46)
	lda xbc, (FPConst_MaxNorm:24)
	cp hl, 0:i3
	jr nz, FP_pow_ExpLog_NegResult
	call FP_DP_CopyOrNegate8
	jr FP_pow_ExpLog_StoreResult

; Overflow with a negative sign: copy DBL_MAX unnegated.
FP_pow_ExpLog_NegResult:
	call FP_DP_Raw8Copy

; Store the saturated result and return.
FP_pow_ExpLog_StoreResult:
	ld xwa, (xsp + 62)
	lda xbc, (xsp + 46)
	call FP_DP_Raw8Copy
	jr FP_pow_Epilog

; IZ < -1021 -> ERANGE, result = 0.0 (0x01F686).
FP_pow_ExpLog_Clamp:
	cp iz, 0xFC03
	jr ge, FP_pow_ExpLog_CrossZero
	ldw (0x040c22:24), 0x0022
	ld xwa, (xsp + 62)
	lda xbc, (FPConst_pow_ExpLog_Clamp_Zero:24)
	call FP_DP_Raw8Copy
	jr FP_pow_Epilog

; In range: t = y * log(x) (FP_dmul = multiply), result = exp(t).
FP_pow_ExpLog_CrossZero:
	lda xbc, (xsp + 38)
	lda xde, (xsp + 74)
	lda xwa, (xsp + 18)
	call FP_dmul
	lda xiy, (xsp + 18)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda xwa, (xsp + 54)
	push xwa
	call FP_exp
	lda xsp, (xsp + 12)
	ld xwa, (xsp + 62)
	lda xbc, (xsp + 46)
	call FP_DP_Raw8Copy

; pow() epilogue: pop IZ, release the 0x38-byte frame.
FP_pow_Epilog:
	popw iz
	lda xsp, (xsp + 56)
	ret

; sin(double). C signature f(double *result, double x). Computes the sign flag
; (x < 0) with FP_DP_CmpZero64 relation 2 (">= 0") and calls the shared kernel
; FP_SinCos_Kernel(result, x, |x|, x<0). The |x| is produced by
; FP_DP_CopyOrNegate8 on the negative arm. 7 call sites, 6 of them in the DSP curve
; block (0x03B73E, 0x03B84E, 0x03BA8D, 0x03BB95, 0x03BDC6, 0x03BECE) plus tan().
; NOTE: the name is wrong; it is sin().
; RENAMED 2026-09-25: was VoiceFloat_MulAddVariant2 (scripts/renaming/rename_v142_fp_libm.sed); the name now says
; what the header above established.
FP_sin:
	lda xsp, (xsp - 48)
	push xiz
	ld xiz, (xsp + 56)
	lda xwa, (xsp + 60)
	ld bc, 2:i3
	call FP_DP_CmpZero64
	cp hl, 0:i3
	jr nz, FP_sin_AltPath
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
	call FP_SinCos_Kernel
	lda xsp, (xsp + 22)
	ld xwa, xiz
	lda xbc, (xsp + 36)
	call FP_DP_Raw8Copy
	jr FP_sin_Epilog

; x >= 0 arm: kernel(result, x, x, flag=0).
FP_sin_AltPath:
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
	call FP_SinCos_Kernel
	lda xsp, (xsp + 22)
	ld xwa, xiz
	lda xbc, (xsp + 28)
	call FP_DP_Raw8Copy

; sin() epilogue.
FP_sin_Epilog:
	pop xiz
	lda xsp, (xsp + 48)
	ret

; 64x64 -> 64 unsigned integer multiply used by the C runtime for `long long`.
; Inputs XWA:QWA and XBC:QBC (each a 32-bit value plus its high extension register),
; result in XHL. Three `mul` instructions plus the cross-term adds; no rounding, no
; exponent handling - this is an integer helper, not floating point.
FP_MulAccum64:
	ldto_werp HL, 0xE2
	mul xhl, bc
	ldto_werp DE, 0xE6
	mul xde, wa
	add xhl, xde
	ldfr_werp HL, 0xEE
	ld hl, 0:i3
	mul xwa, bc
	add xhl, xwa
	ret

; Double SUBTRACTION: *(double*)XWA = *(double*)XBC - *(double*)XDE.
; Unpacks both operands with FP_DP_Decode into two 12-byte stack records, aligns their
; exponents with FP_DP_AlignMantissa, and then - because it is a subtract - adds the
; mantissas when the operand signs DIFFER (FP_DP_AddMantissa) and subtracts them when
; they are EQUAL (FP_DP_SubMantissa). Repacks with FP_DP_Encode. The zero flag at +2 of
; the first record short-circuits the sign test. 21 call sites (11 external).
; This is the reference for the whole arithmetic quartet: compare it against
; FP_dadd 0x03E10E, which is byte-for-byte identical apart from the inverted sign
; test and is therefore the ADDITION.
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

; Equal signs (or a zero operand): magnitudes subtract.
FP_DP_Sub_SameSign:
	call FP_DP_SubMantissa

; Repack the unpacked result into *XWA with FP_DP_Encode.
FP_DP_Sub_Done:
	ld xwa, (xsp + 24)
	ld xbc, xsp
	call FP_DP_Encode
	lda xsp, (xsp + 28)
	pop xiz
	ret

; One 0xFF fill byte, never executed (it follows `ret`), at an odd address so that
; FP_SP_Sub starts on the next even address.  All 20 *_Pad bytes in this file are 0xFF at odd
; addresses (measured 2026-09-25); the library aligns some routines to 2 bytes, not all.
FP_SP_Sub_Pad:
	.byte 0xff

; Single-precision SUBTRACTION: *(float*)XWA = *(float*)XBC - *(float*)XDE.
; Same shape as FP_DP_Sub using FP_SP_Decode / FP_SP_AlignMantissa /
; FP_SP_AddMantissa / FP_SP_SubMantissa / FP_SP_Encode and 8-byte unpacked records.
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

; Equal signs: magnitudes subtract.
FP_SP_Sub_SameSign:
	call FP_SP_SubMantissa

; Repack with FP_SP_Encode.
FP_SP_Sub_Done:
	ld xwa, (xsp + 16)
	ld xbc, xsp
	call FP_SP_Encode
	lda xsp, (xsp + 20)
	pop xiz
	ret

; ----------------------------------------------------------------------------
; FP_CmpResult_Pad - Lookup tables for voice comparison results
; 0x03D978: Equal result table (6 bytes)
; 0x03D97E: Less-than result table (6 bytes)
; 0x03D984: Greater-than result table (6 bytes)
; ----------------------------------------------------------------------------
; ★ Renamed 2026-09-25 from ToneGen_Compare_Tables (FP library compare; see the headers).
FP_CmpResult_Pad:	; 03D977h
	.byte 0xff	; Padding
; The three rows are indexed by the comparison-kind code 0..5 (DE in FP_dcmp / FP_fcmp,
; BC in FP_DP_CmpZero64 / FP_SP_CmpZero32), `ldb_sri` / `xor_srib_rm` = row[kind].
	; Equal table (0x03D978)
FP_CmpResult_Equal:
	.byte 0x01, 0x00, 0x01, 0x00, 0x01, 0x00
	; Less-than table (0x03D97E)
FP_CmpResult_Less:
	.byte 0x01, 0x01, 0x00, 0x00, 0x00, 0x01
	; Greater-than table (0x03D984)
FP_CmpResult_Greater:
	.byte 0x00, 0x00, 0x01, 0x01, 0x00, 0x01

; The shared sin/cos kernel. C signature f(double *result, double x, double a, int neg),
; where a = |x| for sin() and |x| + pi/2 for cos() - which is exactly why one kernel
; serves both (sin(|x| + pi/2) = cos(x), cos being even). Body:
;   (1) if |x| >= 2^31 (exponent word test against 0x41E0) -> errno = ERANGE,
;       result = 0.0 (0x01F68E). Argument reduction is impossible past that point.
;   (2) n = round(a * (1/pi)): multiplies by the constant 0.3183098861837907 at
;       0x00F396 (= 1/pi), splits with FP_modf (= modf), and rounds up when the
;       fraction is >= 0.5 (constants 0.5 at 0x01F696 and 1.0 at 0x01F69E).
;   (3) if n is odd, the sign flag at (XSP+0x9C) is toggled - i.e. sin(x + n*pi) =
;       (-1)^n sin(x).
;   (4) Cody-Waite two-step reduction: z = (a - n*pi_hi) - n*pi_lo, using
;       pi_hi = 3.1416015625 at 0x00F39E and pi_lo = pi_hi - pi = 8.908910e-06 at
;       0x00F38E (negated through FP_DP_CopyOrNegate8).
;   (5) if |z| <= 2.3283e-10 (0x00F3A6) the polynomial is skipped and z is returned.
;   (6) otherwise Horner on z^2 with the eight coefficients 1/3! .. 1/17! at
;       0x00F34E, F356, F35E, F366, F36E, F376, F37E, F386, then result = z + z*poly.
;   (7) finally, if the sign flag is set, negate.
; The coefficient values read out of the ROM (0.16666666666666666, 0.008333333333333165,
; 1.984126984120184e-04, 2.7557319210152756e-06, 2.5052106798274583e-08,
; 1.605893649037159e-10, 7.642917806891047e-13, 2.7204790957888847e-15) are the odd
; reciprocal factorials to double precision and are what identifies this as sin.
; Callers: only sin() 0x03D888/0x03D8B5 and cos() 0x03D38F.
; NOTE: the name is wrong; nothing here blends or merges anything.
; RENAMED 2026-09-25: was VoiceFloat_BlendAndMerge (scripts/renaming/rename_v142_fp_libm.sed); the name now says
; what the header above established.
FP_SinCos_Kernel:
	lda xsp, (xsp - 128)
	push xiz
	ldw_sri0 WA, (xsp + 0x0092)
	and wa, 0x7FF0
	cp wa, 0x41E0
	jr c, FP_SinCos_Kernel_InRange
	ldw (0x040c22:24), 0x0022
	ld_sril XWA, (xsp + 0x0088)
	lda xbc, (FPConst_SinCos_Kernel_Zero:24)
	call FP_DP_Raw8Copy
	jrl FP_SinCos_Kernel_Epilog

; |x| < 2^31: begin argument reduction, a * (1/pi) then modf.
FP_SinCos_Kernel_InRange:
	lda xwa, (xsp + 116)
	push xwa
	lda xde, (FPConst_InvPi:24)
	lda xbc, (xsp+152:16)
	lda xwa, (xsp + 72)
	call FP_dmul
	lda xiy, (xsp + 72)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda xwa, (xsp + 112)
	push xwa
	call FP_modf
	lda xsp, (xsp + 16)
	lda xwa, (xsp + 100)
	lda xbc, (FPConst_SinCos_Kernel_InRange_Half:24)
	ld de, 1:i3
	call FP_dcmp
	cp hl, 0:i3
	jr nz, FP_SinCos_Kernel_Phase2
	lda xwa, (xsp + 116)
	ld xbc, xwa
	lda xde, (FPConst_SinCos_Kernel_InRange_One:24)
	call FP_dadd

; Convert the (rounded) quadrant count to int32 and test its parity.
FP_SinCos_Kernel_Phase2:
	lda xbc, (xsp + 116)
	lda xwa, (xsp + 64)
	call FP_DP_DecodeToInt
	ld xwa, (xsp + 64)
	bit 0, wa
	jr z, FP_SinCos_Kernel_Phase3
	cpiw_sri 0xFD, 0x9C, 0x00, 0x00, 0x00
	scc16 z, wa
	stw_dri WA, 0xFD, 0x9C, 0x00

; Take |n| and, on the half-quadrant case, subtract 0.5 (0x01F6A6).
FP_SinCos_Kernel_Phase3:
	lda xiy, (xsp+140:16)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda xwa, (xsp + 100)
	push xwa
	call FP_fabs
	lda xsp, (xsp + 12)
	lda xwa, (xsp + 92)
	lda xbc, (xsp+148:16)
	ld de, 4:i3
	call FP_dcmp
	cp hl, 0:i3
	jr nz, FP_SinCos_Kernel_Phase4
	lda xwa, (xsp + 116)
	ld xbc, xwa
	lda xde, (FPConst_SinCos_Kernel_Phase3_Half:24)
	call FP_DP_Sub

; Cody-Waite reduction proper: subtract n*pi_hi then n*pi_lo, leaving z in the local at
; (XSP+0x7C); then the |z| <= 2.3283e-10 shortcut test.
FP_SinCos_Kernel_Phase4:
	lda xwa, (xsp+140:16)
	push xwa
	lda xiy, (xsp+144:16)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda xwa, (xsp + 96)
	push xwa
	call FP_fabs
	lda xsp, (xsp + 12)
	lda xiy, (xsp + 88)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda xwa, (xsp + 120)
	push xwa
	call FP_modf
	lda xde, (FPConst_PiHi_CodyWaite:24)
	lda xbc, (xsp+132:16)
	lda xwa, (xsp + 84)
	call FP_dmul
	lda xbc, (xsp+156:16)
	lda xwa, (xsp + 84)
	ld xde, xwa
	call FP_DP_Sub
	lda xwa, (xsp + 84)
	ld xbc, xwa
	lda xde, (xsp + 124)
	call FP_dadd
	lda xbc, (FPConst_PiLo_CodyWaite:24)
	lda xwa, (xsp + 72)
	call FP_DP_CopyOrNegate8
	lda xwa, (xsp + 72)
	ld xbc, xwa
	lda xde, (xsp+132:16)
	call FP_dmul
	lda xbc, (xsp + 84)
	lda xde, (xsp + 72)
	lda xwa, (xsp+140:16)
	call FP_DP_Sub
	lda xiy, (xsp+140:16)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda xwa, (xsp + 100)
	push xwa
	call FP_fabs
	lda xsp, (xsp + 28)
	lda xbc, (FPConst_SinCos_Epsilon:24)
	lda xwa, (xsp + 76)
	ld de, 0:i3
	call FP_dcmp
	cp hl, 0:i3
	jrl nz, FP_SinCos_Kernel_FinalCheck
	lda xde, (xsp + 124)
	ld xbc, xde
	lda xwa, (xsp + 108)
	call FP_dmul
	lda xwa, (FPConst_InvFact3:24)
	lda xiz, (xwa + 48)
	lda xbc, (xwa + 56)
	lda xde, (xsp + 108)
	lda xwa, (xsp + 56)
	call FP_dmul
	lda xwa, (xsp + 56)
	ld xbc, xwa
	ld xde, xiz
	call FP_DP_Sub
	lda xwa, (xsp + 56)
	ld xbc, xwa
	lda xde, (xsp + 108)
	call FP_dmul
	lda xbc, (FPConst_InvFact13:24)
	lda xwa, (xsp + 56)
	ld xde, xwa
	call FP_dadd
	lda xwa, (xsp + 56)
	ld xbc, xwa
	lda xde, (xsp + 108)
	call FP_dmul
	lda xde, (FPConst_InvFact11:24)
	lda xwa, (xsp + 56)
	ld xbc, xwa
	call FP_DP_Sub
	lda xwa, (xsp + 56)
	ld xbc, xwa
	lda xde, (xsp + 108)
	call FP_dmul
	lda xbc, (FPConst_InvFact9:24)
	lda xwa, (xsp + 56)
	ld xde, xwa
	call FP_dadd
	lda xwa, (xsp + 56)
	ld xbc, xwa
	lda xde, (xsp + 108)
	call FP_dmul
	lda xde, (FPConst_InvFact7:24)
	lda xwa, (xsp + 56)
	ld xbc, xwa
	call FP_DP_Sub
	lda xwa, (xsp + 56)
	ld xbc, xwa
	lda xde, (xsp + 108)
	call FP_dmul
	lda xbc, (FPConst_InvFact5:24)
	lda xwa, (xsp + 56)
	ld xde, xwa
	call FP_dadd
	lda xwa, (xsp + 56)
	ld xbc, xwa
	lda xde, (xsp + 108)
	call FP_dmul
	lda xde, (FPConst_InvFact3:24)
	lda xwa, (xsp + 56)
	ld xbc, xwa
	call FP_DP_Sub
	lda xwa, (xsp + 56)
	ld xbc, xwa
	lda xde, (xsp + 108)
	call FP_dmul
	lda xwa, (xsp + 56)
	ld xbc, xwa
	lda xde, (xsp + 124)
	call FP_dmul
	lda xbc, (xsp + 56)
	lda xwa, (xsp + 124)
	ld xde, xwa
	call FP_dadd

; Apply the accumulated sign flag: if non-zero, negate the polynomial result.
FP_SinCos_Kernel_FinalCheck:
	cpiw_sri 0xFD, 0x9C, 0x00, 0x00, 0x00
	jr z, FP_SinCos_Kernel_FinalCopy
	lda xwa, (xsp + 124)
	ld xbc, xwa
	call FP_DP_CopyOrNegate8

; Copy the kernel result to the caller's result pointer.
FP_SinCos_Kernel_FinalCopy:
	ld_sril XWA, (xsp + 0x0088)
	lda xbc, (xsp + 124)
	call FP_DP_Raw8Copy

; Kernel epilogue: pop XIZ, release the 0x80-byte frame.
FP_SinCos_Kernel_Epilog:
	pop xiz
	lda xsp, (xsp+128:16)
	ret

; Signed 64-bit divide/modulo helper for the C runtime. Inputs XWA:QWA (dividend) and
; XBC:QBC (divisor); D selects quotient (0) or remainder (1) and is set by the two
; alternate entry points below. Records the operand signs in E, takes absolute values,
; calls FP_UnsignedDiv, and re-applies the sign to the quotient (sign(a) xor sign(b))
; or to the remainder (sign(a)). Result in XHL. Not floating point despite the
; neighbours.
Int_SignedDiv:
	ld e, 0x0:opc
	bit_erpw 0xE2, 0x0F
	jr z, Int_SignedDiv_AfterSignA
	ld e, 0x1:opc
	cplw_erp 0xE2
	cpl wa
	inc 1, xwa

; Dividend sign captured; now normalise the divisor.
Int_SignedDiv_AfterSignA:
	bit_erpw 0xE6, 0x0F
	jr z, Int_SignedDiv_CallUnsigned
	or e, 0x2
	cplw_erp 0xE6
	cpl bc
	inc 1, xbc

; Push the sign bits, call FP_UnsignedDiv, pop them back.
Int_SignedDiv_CallUnsigned:
	pushw de
	calr FP_UnsignedDiv
	popw wa
	cp w, 1:i3
	jr z, Int_SignedDiv_ResultCorr
	ld xhl, xde
	bit 0, a
	scc8 nz, a
	jr Int_SignedDiv_NegResult

; Remainder selected: sign follows the dividend only.
Int_SignedDiv_ResultCorr:
	cp a, 3:i3
	ret z

; Negate the 64-bit result when the computed sign says so (and it is non-zero).
Int_SignedDiv_NegResult:
	or xhl, xhl
	ret z
	cp a, 0:i3
	ret z
	cplw_erp 0xEE
	cpl hl
	inc 1, xhl
	ret

; Entry point "signed quotient": D = 0, jump to Int_SignedDiv. Despite the name this is
; executable code, not data. Converted from `.byte` to mnemonics 2026-09-01 (lane SUB);
; `jr -75` takes the raw signed 8-bit displacement, verified byte-identical by an
; llvm-mc round trip.
Int_SignedDiv_ConstData:
	ld	d, 0:opc
	jr	Int_SignedDiv

; Entry point "signed remainder": D = 1, jump to Int_SignedDiv. The three bytes at
; 0x03DC63 are a fourth entry point ("unsigned remainder"): call FP_UnsignedDiv and
; return XDE in XHL.
Int_SignedDiv_AltEntry:
	ld d, 0x1:opc
	jr Int_SignedDiv
; The fourth entry point the header above describes ("unsigned remainder": call FP_UnsignedDiv
; and return XDE in XHL); unlabelled until 2026-09-25, no caller found.
Int_UnsignedRemainder:
	calr FP_UnsignedDiv
	ld xhl, xde
	ret

; Unsigned 64-bit divide. Dividend in XWA:QWA, divisor in XBC:QBC; returns quotient in
; XHL and remainder in XDE. Special cases first: divisor == 1 (copy), divisor == 0
; (quotient = 0xFFFFFFFF, remainder 0), dividend <= divisor. When the divisor fits in
; 32 bits it uses the hardware `div` instruction, with a two-step fallback on overflow;
; otherwise it falls back to the shift-and-subtract restoring loop below.
FP_UnsignedDiv:
	cp xbc, 0x1
	jr z, FP_UnsignedDiv_ByOne
	jr c, FP_UnsignedDiv_Zero
	cp xwa, xbc
	jr ule, FP_UnsignedDiv_SmallDividend
	cpiw_erp 0xE6, 0
	jr nz, FP_UnsignedDiv_General
	ld xde, xwa
	div xwa, bc
	jr ov, FP_UnsignedDiv_Overflow
	ld xhl, 0:i3
	ld xde, xhl
	ld hl, wa
	ldto_werp DE, 0xE2
	ret

; Hardware `div` overflowed: redo it as two 16-bit-at-a-time divisions.
FP_UnsignedDiv_Overflow:
	ldto_werp WA, 0xEA
	extz xwa
	div xwa, bc
	ldfr_werp WA, 0xEE
	ld wa, de
	div xwa, bc
	ld hl, wa
	ldto_werp DE, 0xE2
	extz xde
	ret

; Divisor == 1: quotient = dividend, remainder = 0.
FP_UnsignedDiv_ByOne:
	ld xhl, xwa
	ld xde, 0:i3
	ret

; Divisor == 0: quotient = 0xFFFFFFFF, remainder = 0. No trap, no errno.
FP_UnsignedDiv_Zero:
	ld xhl, 0:i3
	ld xde, xhl
	dec 1, xhl
	ret

; dividend <= divisor: quotient is 0 or 1, remainder is the dividend.
FP_UnsignedDiv_SmallDividend:
	ld xhl, 1:i3
	ld xde, 0:i3
	ret z
	dec 1, xhl
	ld xde, xwa
	ret

; General case: normalise the divisor by left-shifting, counting the shift in D.
FP_UnsignedDiv_General:
	ld d, 0x0:opc

; Shift the divisor left until it exceeds the dividend; bounded by the carry out of XBC.
FP_UnsignedDiv_ShiftLoop:
	cp xwa, xbc
	jr c, FP_UnsignedDiv_ShiftLoopDone
	inc 1, d
	add xbc, xbc
	jr nc, FP_UnsignedDiv_ShiftLoop
	extpfx3 0xD9, 0x24, 0x00
	rrc xbc
	jr FP_UnsignedDiv_Subtract

; Back off one shift.
FP_UnsignedDiv_ShiftLoopDone:
	srl xbc, 1

; Clear the quotient accumulator.
FP_UnsignedDiv_Subtract:
	ld xhl, 0:i3

; Restoring-division inner loop, `djnz D` bounded by the shift count.
FP_UnsignedDiv_SubtractLoop:
	add xhl, xhl
	cp xwa, xbc
	jr c, FP_UnsignedDiv_Done
	set 0, l
	sub xwa, xbc

; Shift the divisor back down and loop; remainder ends up in XDE.
FP_UnsignedDiv_Done:
	srl xbc, 1
	djnz8 d, FP_UnsignedDiv_SubtractLoop
	ld xde, xwa
	ret

; memcpy of 8 bytes: *(double*)XWA = *(double*)XBC, via two 32-bit loads/stores. No sign
; or exponent handling. 51 call sites, all inside this region - it is how every libm
; entry point returns its result and how every constant is loaded.
FP_DP_Raw8Copy:
	ld xix, (xbc)
	ld xiy, (xbc + 4)
	ld (xwa), xix
	ld (xwa + 4), xiy
	ret

; One 0xFF fill byte, never executed (it follows `ret`), at an odd address so that
; FP_ftod starts on the next even address.  All 20 *_Pad bytes in this file are 0xFF at odd
; addresses (measured 2026-09-25); the library aligns some routines to 2 bytes, not all.
FP_DP_Raw8Copy_Pad:
	.byte 0xff

; float -> double conversion. XWA = pointer to the double result, XBC = pointer to the
; float. Unpacks with FP_SP_Decode; if the value is not zero it shifts the 24-bit
; mantissa right by 3 into the 53-bit double layout (three srl/rrc pairs building the
; low word in XDE and the high word in XHL) and repacks with FP_DP_Encode.
; NOTE: nothing is negated here; the name is wrong.
; RENAMED 2026-09-25: was FP_DP_NegMantissaLS (scripts/renaming/rename_v142_fp_libm.sed); the name now says
; what the header above established.
FP_ftod:
	push xiz
	lda xsp, (xsp - 12)
	ld xiz, xwa
	ld xwa, xsp
	call FP_SP_Decode
	cp l, 0:i3
	jr nz, FP_ftod_Store
	ld xhl, (xsp + 4)
	ld xde, 0:i3
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

; Repack the widened value with FP_DP_Encode and return.
FP_ftod_Store:
	ld xwa, xiz
	ld xbc, xsp
	call FP_DP_Encode
	lda xsp, (xsp + 12)
	pop xiz
	ret

; One 0xFF fill byte, never executed (it follows `ret`), at an odd address so that
; FP_ScalarToDP starts on the next even address.  All 20 *_Pad bytes in this file are 0xFF at odd
; addresses (measured 2026-09-25); the library aligns some routines to 2 bytes, not all.
FP_ScalarToDP_Pad:
	.byte 0xff

; (double)(int32) conversion. XWA = pointer to the double result, XBC = pointer to the
; int32 source. Loads the int, normalises it into a 12-byte unpacked record with
; FP_SP_Normalize (which, despite its name, is the DOUBLE normaliser - it uses the
; 20-bit split and writes the mantissa to +4/+8), then FP_DP_Encode. 14 call sites; used
; by pow() to test whether the exponent is an integer, and by exp() and log() to build
; the term denominators.
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
; (double)(uint32) conversion. Identical to FP_ScalarToDP except that it calls
; FP_SP_NormCore directly, skipping the sign-extraction step, so the source is treated
; as unsigned.
FP_DP_CallWithBuf12:
	push	xiz
	lda	xsp, (xsp-12)
	ld	xiz, xwa
	ld	xwa, xsp
	ld	xbc, (xbc)
	call	FP_SP_NormCore
	ld	xwa, xiz
	ld	xbc, xsp
	call	FP_DP_Encode
	lda	xsp, (xsp+12)
	pop	xiz
	ret

; double -> float conversion. XWA = pointer to the float result, XBC = pointer to the
; double. Unpacks with FP_DP_Decode; if non-zero, shifts the 53-bit mantissa LEFT by 3
; (three sll/rlc pairs) to reach the 24-bit float layout, rounds to nearest using the
; discarded byte (compare against 0x80) and re-normalises if the round carried out of
; bit 23; repacks with FP_SP_Encode.
; NOTE: the name describes an internal step; this is __dtof.
; RENAMED 2026-09-25: was FP_DP_NormalizeMantissa (scripts/renaming/rename_v142_fp_libm.sed); the name now says
; what the header above established.
FP_dtof:
	push xiz
	lda xsp, (xsp - 12)
	ld xiz, xwa
	ld xwa, xsp
	call FP_DP_Decode
	cp l, 0:i3
	jr nz, FP_dtof_Encode
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
	jr c, FP_dtof_StoreHL
	inc 1, xhl
	bit_erpw 0xEE, 0x07
	jr nz, FP_dtof_StoreHL
	incw 1, (xsp + 0:8)
	srl xhl, 1

; Store the rounded 24-bit mantissa back into the unpacked record.
FP_dtof_StoreHL:
	ld (xsp + 4), xhl

; Repack with FP_SP_Encode and return.
FP_dtof_Encode:
	ld xwa, xiz
	ld xbc, xsp
	call FP_SP_Encode
	lda xsp, (xsp + 12)
	pop xiz
	ret

; One 0xFF fill byte, never executed (it follows `ret`), at an odd address so that
; FP_SP_Raw4Copy starts on the next even address.  All 20 *_Pad bytes in this file are 0xFF at odd
; addresses (measured 2026-09-25); the library aligns some routines to 2 bytes, not all.
FP_SP_Raw4Copy_Pad:
	.byte 0xff

; memcpy of 4 bytes: *(float*)XWA = *(float*)XBC. Single-precision twin of
; FP_DP_Raw8Copy.
FP_SP_Raw4Copy:
	ld xix, (xbc)
	ld (xwa), xix
	ret

; One 0xFF fill byte, never executed (it follows `ret`), at an odd address so that
; FP_SP_CallWithBuf8 starts on the next even address.  All 20 *_Pad bytes in this file are 0xFF at odd
; addresses (measured 2026-09-25); the library aligns some routines to 2 bytes, not all.
FP_SP_CallWithBuf8_Pad:
	.byte 0xff

; (float)(int32) conversion: FP_DP_Normalize (the SINGLE-precision normaliser, 23-bit
; split) followed by FP_SP_Encode, using an 8-byte unpacked record.
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
; (float)(uint32) conversion: FP_DP_NormCore (no sign extraction) followed by
; FP_SP_Encode.
FP_SP_CallWithBuf8b:
	push	xiz
	lda	xsp, (xsp-8)
	ld	xiz, xwa
	ld	xwa, xsp
	ld	xbc, (xbc)
	call	FP_DP_NormCore
	ld	xwa, xiz
	ld	xbc, xsp
	call	FP_SP_Encode
	lda	xsp, (xsp+8)
	pop	xiz
	ret

; (int32)(double) conversion. XWA = pointer to the int32 result, XBC = pointer to the
; double. FP_DP_Decode into a 12-byte record, then FP_SP_DecodeToInt (which is the
; DOUBLE record-to-integer shifter) and store XHL. Sets ERANGE on out-of-range.
; Used by pow() (integer-exponent test) and by the sin kernel (quadrant count).
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

; --- 0x03DE19-0x03DE19  FP_DP_Normalize_Pad (0xFF alignment byte)
; Linker pad.
; One 0xFF fill byte, never executed (it follows `ret`), at an odd address so that
; FP_DP_Normalize starts on the next even address.  All 20 *_Pad bytes in this file are 0xFF at odd
; addresses (measured 2026-09-25); the library aligns some routines to 2 bytes, not all.
FP_DP_Normalize_Pad:
	.byte 0xff

; Signed int32 -> unpacked SINGLE-precision record. XWA = pointer to the 8-byte record,
; XBC = the integer value. Extracts the sign into E, takes the absolute value, calls
; FP_DP_NormCore, and stores the sign at record+3.
; NOTE: SP/DP are swapped here - the core it calls uses the 23-bit (single) split.
FP_DP_Normalize:
	ld e, 0x0:opc
	ldcf_erpw 0xE6, 0x0F
	extpfx3 0xCD, 0x24, 0x07
	jr nc, FP_DP_Normalize_StoreSign
	cplw_erp 0xE6
	cpl bc
	inc 1, xbc

; Call the core, then write the saved sign byte to (XIY+3).
FP_DP_Normalize_StoreSign:
	calr FP_DP_NormCore
	ld (xiy + 3), e
	ret

; Unsigned int32 -> unpacked SINGLE-precision record. Uses `bs1b` (bit-search-1
; backwards) to find the highest set bit, writes that as the exponent, and shifts the
; value so the mantissa lands at bit 23 (0x17), rounding up and re-normalising when the
; shifted-out bit was set. A zero input sets the +2 "zero" flag and returns.
FP_DP_NormCore:
	ld xiy, xwa
	or xbc, xbc
	jr z, FP_DP_NormCore_Zero
	bs1b_erpw 0xE6
	jr ov, FP_DP_NormCore_Overflow
	add a, 0x10
	jr FP_DP_NormCore_Shift

; Value fits in the low 16 bits: repeat the bit search on BC alone.
FP_DP_NormCore_Overflow:
	extpfx2 0xD9, 0x0F

; Store the exponent, then choose left shift, right shift or no shift against 23.
FP_DP_NormCore_Shift:
	ld hl, 0:i3
	ld (xiy + 2), hl
	ld l, a
	ld (xiy + 0:8), hl
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
	incm8 1, (xiy + 0:8)
	jr FP_DP_NormCore_StoreResult

; Shift left, 16 bits at a time then the remainder.
FP_DP_NormCore_ShiftLeft:
	ld a, 0x17:opc
	sub a, l
	cp a, 0x10
	jr lt, FP_DP_NormCore_ShiftLeftLoop
	ldfr_werp BC, 0xE6
	ld bc, 0:i3
	sub a, 0x10
	jr z, FP_DP_NormCore_StoreResult

; Final variable left shift.
FP_DP_NormCore_ShiftLeftLoop:
	slla xbc

; Store the mantissa at record+4.
FP_DP_NormCore_StoreResult:
	ld (xiy + 4), xbc
	ret

; Input was zero: set the record's zero flag (+2 = 1).
FP_DP_NormCore_Zero:
	ld (xiy + 2), 0x1
	ret

; One 0xFF fill byte, never executed (it follows `ret`), at an odd address so that
; FP_DP_ShiftDecode starts on the next even address.  All 20 *_Pad bytes in this file are 0xFF at odd
; addresses (measured 2026-09-25); the library aligns some routines to 2 bytes, not all.
FP_DP_ShiftDecode_Pad:
	.byte 0xff

; Unpacked SINGLE-precision record -> int32, returned in XHL. XWA = pointer to the
; record. Rejects the NaN/overflow marker, returns 0 for a negative exponent
; (magnitude < 1), and sets ERANGE with 0xFFFFFFFF for an exponent above 31. Otherwise
; it shifts the 24-bit mantissa to align bit 23 with the requested exponent and applies
; the sign by two's complement. Called only from FP_ftoi.
FP_DP_ShiftDecode:
	ld xde, (xwa)
	cpib_erp 0xEA, 0
	jr nz, FP_DP_ShiftDecode_Zero
	cp de, 0:i3
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

; Exponent below 23: shift right by (23 - exponent).
FP_DP_ShiftDecode_ShiftRight:
	ld a, 0x17:opc
	sub a, e
	cp a, 0x10
	jr lt, FP_DP_ShiftDecode_ShiftRightLoop
	ldto_werp IX, 0xF2
	extz xix
	sub a, 0x10
	jr z, FP_DP_ShiftDecode_SignCorrect

; Final variable right shift.
FP_DP_ShiftDecode_ShiftRightLoop:
	srla xix

; Apply the sign byte by negating XIX.
FP_DP_ShiftDecode_SignCorrect:
	cpib_erp 0xEB, 0
	jr z, FP_DP_ShiftDecode_Return
	cplw_erp 0xF2
	cpl ix
	inc 1, xix

; Move the result to XHL and return.
FP_DP_ShiftDecode_Return:
	ld xhl, xix
	ret

; |x| < 1: result 0, then set ERANGE.
FP_DP_ShiftDecode_Underflow:
	ld xhl, 0:i3
	jr FP_DP_ShiftDecode_SetError

; |x| >= 2^32: result 0xFFFFFFFF, then set ERANGE.
FP_DP_ShiftDecode_Overflow:
	ld xhl, 0:i3
	dec 1, xhl

; errno (0x040C22) = 0x22 (ERANGE).
FP_DP_ShiftDecode_SetError:
	ldw (0x040c22:24), 0x0022
	ret

; NaN/overflow marker in the record: return 0 without touching errno.
FP_DP_ShiftDecode_Zero:
	ld xhl, 0:i3
	ret

; Adds the 53-bit mantissa of the unpacked record at XBC into the one at XWA (the
; exponents must already be equal - the caller has run FP_DP_AlignMantissa). If the sum
; carries out of bit 53 it shifts right one and increments the exponent, propagating the
; rounding bit. If either record carries a special flag it jumps to FP_DP_CopyWithSign.
; Called by FP_DP_Sub (different signs) and FP_dadd (equal signs).
FP_DP_AddMantissa:
	ld e, (xwa + 2)
	or e, (xbc + 2)
	jp nz, (FP_DP_CopyWithSign:24)
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
	incw 1, (xwa + 0:8)
	jr nc, FP_DP_AddMantissa_Store
	add xde, 0x1
	adc xhl, 0x0

; Store the 64-bit mantissa back into the record.
FP_DP_AddMantissa_Store:
	ld (xwa + 4), xde
	ld (xwa + 8), xhl
	ret

; Single-precision twin of FP_DP_AddMantissa, on 8-byte records with a 24-bit mantissa.
; Special-flag path jumps to FP_DP_CopyNoSign.
FP_SP_AddMantissa:
	ld e, (xwa + 2)
	or e, (xbc + 2)
	jp nz, (FP_DP_CopyNoSign:24)
	ld xix, (xwa + 4)
	add xix, (xbc + 4)
	bit_erpw 0xF2, 0x08
	jr z, FP_SP_AddMantissa_Store
	incw 1, (xwa + 0:8)
	srl xix, 1
	adc xix, 0x0

; Store the 32-bit mantissa back into the record.
FP_SP_AddMantissa_Store:
	ld (xwa + 4), xix
	ret

; One 0xFF fill byte, never executed (it follows `ret`), at an odd address so that
; FP_DP_Decode starts on the next even address.  All 20 *_Pad bytes in this file are 0xFF at odd
; addresses (measured 2026-09-25); the library aligns some routines to 2 bytes, not all.
FP_DP_Decode_Pad:
	.byte 0xff

; Unpack an IEEE-754 double into the 12-byte working record. XWA = record, XBC = the
; double. Extracts the 11-bit biased exponent, subtracts the bias 0x03FF, restores the
; hidden mantissa bit (set bit 4 of the high word, i.e. bit 52), and stores the sign
; nibble at record+3. A zero exponent takes the zero path.
; The bias 0x03FF and the 4-bit high-word exponent split confirm this operates on
; doubles.
FP_DP_Decode:
	ld xhl, 0:i3
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

; Zero input: set record+2 = 1 (zero flag), record+3 = 0.
FP_DP_Decode_Zero:
	ld l, 0x1:opc
	ld (xwa + 2), l
	ld (xwa + 3), 0x0
	ret

; Unpack an IEEE-754 float into the 8-byte working record. Bias 0x007F, hidden bit at
; bit 7 of the high byte. Twin of FP_DP_Decode.
FP_SP_Decode:
	ld xhl, 0:i3
	ld xix, (xbc)
	ldto_werp DE, 0xF2
	extpfx3 0xDA, 0x23, 0x0F
	stcf_erpw 0xEE, 0x0F
	ld hl, de
	sll hl, 1
	ld l, 0x0:opc
	ex8 h, l
	cp hl, 0:i3
	jr z, FP_SP_Decode_Zero
	and de, 0x7F
	set 7, de
	ldfr_werp DE, 0xF2
	sub hl, 0x7F

; Store exponent and mantissa into the record; return the special flag in L.
FP_SP_Decode_Store:
	ld (xwa), xhl
	ld (xwa + 4), xix
	ldto_berp L, 0xEE
	ret

; Zero input: mantissa 0, zero flag 1.
FP_SP_Decode_Zero:
	ld xix, 0:i3
	ldib_erp 0xEE, 1
	jr FP_SP_Decode_Store
	.byte 0xff	; fill byte after the unconditional jr -- never executed (it was written as `swi 7`,
			; the way 0xFF decodes; the other 0xFF fill bytes in this file are FP_*_Pad data)

; Signed int32 -> unpacked DOUBLE-precision record. Sign extraction plus
; FP_SP_NormCore, then the sign byte at record+3.
; NOTE: SP/DP are swapped - the core uses the 20-bit (double) split and writes a 64-bit
; mantissa to +4/+8. Called by FP_ScalarToDP, i.e. by int-to-double conversion.
FP_SP_Normalize:
	ld e, 0x0:opc
	ldcf_erpw 0xE6, 0x0F
	extpfx3 0xCD, 0x24, 0x07
	jr nc, FP_SP_Normalize_StoreSign
	cplw_erp 0xE6
	cpl bc
	inc 1, xbc

; Call the core, then write the saved sign byte.
FP_SP_Normalize_StoreSign:
	calr FP_SP_NormCore
	ld (xiy + 3), e
	ret

; Unsigned int32 -> unpacked DOUBLE-precision record. `bs1b` to find the top set bit,
; store it as the exponent, then shift so the mantissa lands at bit 20 (0x14) of the
; high word, spilling the low bits into XIX (record+4). Zero input sets the zero flag.
FP_SP_NormCore:
	ld xiy, xwa
	or xbc, xbc
	jr z, FP_SP_NormCore_Zero
	bs1b_erpw 0xE6
	jr ov, FP_SP_NormCore_Overflow
	add a, 0x10
	jr FP_SP_NormCore_Shift

; Value fits in 16 bits: repeat the bit search on BC alone.
FP_SP_NormCore_Overflow:
	extpfx2 0xD9, 0x0F

; Store the exponent and select the shift direction against 20.
FP_SP_NormCore_Shift:
	ld hl, 0:i3
	ld (xiy + 2), hl
	ld l, a
	ld (xiy + 0:8), hl
	ld xix, 0:i3
	cp l, 0x14
	jr z, FP_SP_NormCore_StoreResult
	jr lt, FP_SP_NormCore_ShiftLeft
	sub l, 0x14

; Bit-at-a-time right shift, spilling into the low mantissa word.
FP_SP_NormCore_ShiftRight:
	srl xbc, 1
	extpfx3 0xDC, 0x24, 0x00
	rrc xix
	djnz8 l, FP_SP_NormCore_ShiftRight
	jr FP_SP_NormCore_StoreResult

; Left shift, 16 bits at a time then the remainder.
FP_SP_NormCore_ShiftLeft:
	ld a, 0x14:opc
	sub a, l
	cp a, 0x10
	jr lt, FP_SP_NormCore_ShiftLeftLoop
	ldfr_werp BC, 0xE6
	ld bc, 0:i3
	sub a, 0x10
	jr z, FP_SP_NormCore_StoreResult

; Final variable left shift.
FP_SP_NormCore_ShiftLeftLoop:
	slla xbc

; Store the 64-bit mantissa to record+4 / record+8.
FP_SP_NormCore_StoreResult:
	ld (xiy + 8), xbc
	ld (xiy + 4), xix
	ret

; Input was zero: set the record's zero flag.
FP_SP_NormCore_Zero:
	ld (xiy + 2), 0x1
	ret

; Repack a 12-byte working record into an IEEE-754 double at *XWA. Re-applies the bias
; 0x03FF, clears the hidden bit, shifts the exponent into position and ORs in the sign.
; Exponent above +1023 -> FP_DP_Encode_Overflow (errno = ERANGE, result = +/-DBL_MAX);
; below -1022 -> flush to zero; special flag set -> zero or overflow depending on bit 0.
FP_DP_Encode:
	ld xhl, (xbc)
	cpib_erp 0xEE, 0
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

; Write the packed 8 bytes to *XWA.
FP_DP_Encode_Store:
	ld (xwa), xiy
	ld (xwa + 4), xix
	ret

; Flush to +0.0.
FP_DP_Encode_Zero:
	ld xix, 0:i3
	ld xiy, xix
	jr FP_DP_Encode_Store

; Special flag set: bit 0 means "zero", anything else falls into the overflow path.
FP_DP_Encode_NaN:
	bit_erpb 0xEE, 0x00
	jr nz, FP_DP_Encode_Zero

; Double overflow: errno = ERANGE (0x22) and the result is set to 0x7FEFFFFFFFFFFFFF
; (DBL_MAX) with the operand's sign ORed back in.
FP_DP_Encode_Overflow:
	ldw (0x040c22:24), 0x0022
	ld xde, 0:i3
	dec 1, xde
	ld (xwa), xde
	ld xde, 0x7FEFFFFF
	ldto_berp C, 0xEF
	orb_erp C, 0xEB
	ldfr_berp C, 0xEB
	ld (xwa + 4), xde
	jr __jrt_nop_03E0A5
__jrt_nop_03E0A5:

; The FP exception hook. Loads the 32-bit word at 0x00F428 and, if it is non-zero,
; performs an INDIRECT CALL through it (`call NZ,XBC`). In the shipped image that word
; is 0x00000000, so the hook is disabled. See [UNCERTAIN] - the existing symbol
; FPConst_Zero at 0x00F428 is a function pointer, not a constant, and it lives in the
; program's writable DRAM image. The identical hook appears at 0x03E0FB for singles.
; (The alias symbol __jrt_nop_03E0A5 refers to the same address.)
FP_DP_Encode_NormCheck:
	ld xbc, (FPConst_Zero:24)
	or xbc, xbc
	mri_d2 0xB1, 0xEE
	ret

; One 0xFF fill byte, never executed (it follows `ret`), at an odd address so that
; FP_SP_Encode starts on the next even address.  All 20 *_Pad bytes in this file are 0xFF at odd
; addresses (measured 2026-09-25); the library aligns some routines to 2 bytes, not all.
FP_SP_Encode_Pad:
	.byte 0xff

; Repack an 8-byte working record into an IEEE-754 float at *XWA. Bias 0x007F, limits
; +127 / -126, overflow result 0x7F7FFFFF (FLT_MAX) with errno = ERANGE.
FP_SP_Encode:
	ld xhl, (xbc)
	cpib_erp 0xEE, 0
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

; Special flag 8 (NaN/overflow marker) -> the overflow store; anything else -> zero.
FP_SP_Encode_NaN:
	ldto_berp E, 0xEE
	cp e, 0x8
	jr nz, FP_SP_Encode_Zero
	ld xde, 0:i3
	jr FP_SP_Encode_Overflow_Store

; Flush to +0.0f.
FP_SP_Encode_Zero:
	ld xde, 0:i3
	ld (xwa), xde
	ret

; Build FLT_MAX with the operand's sign.
FP_SP_Encode_Overflow:
	ldw de, 0xFFFF
	ldw bc, 0x7F7F
	or_erpb_rr B, 0xEF
	ldfr_werp BC, 0xEA

; errno = ERANGE, store the saturated value, then the same indirect hook call through
; the pointer at 0x00F428.
FP_SP_Encode_Overflow_Store:
	ldw (0x040c22:24), 0x0022
	ld (xwa), xde
	ld xbc, (FPConst_Zero:24)
	or xbc, xbc
	mri_d2 0xB1, 0xEE
	ret

; Double ADDITION: *(double*)XWA = *(double*)XBC + *(double*)XDE.
; The body is identical to FP_DP_Sub (0x03D8E0) except for the polarity of the sign
; test: here EQUAL signs take FP_DP_AddMantissa and DIFFERENT signs take
; FP_DP_SubMantissa, which is addition, not multiplication. It calls
; FP_DP_AlignMantissa, which only exists to line up exponents for add/subtract; a
; multiply would never need it. The real double multiply is FP_dmul 0x03E290.
; 29 call sites (17 external). NOTE: the name is wrong; this is __dadd.
; RENAMED 2026-09-25: was FP_DP_Mul (scripts/renaming/rename_v142_fp_libm.sed); the name now says
; what the header above established.
FP_dadd:
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
	jr nz, FP_dadd_DiffSign

; Equal signs: magnitudes add.
FP_dadd_SameSign:
	call FP_DP_AddMantissa
	jr FP_dadd_Encode

; Different signs (and neither operand zero): magnitudes subtract.
FP_dadd_DiffSign:
	bitm 0, (xsp + 2)
	jr nz, FP_dadd_SameSign
	call FP_DP_SubMantissa

; Repack with FP_DP_Encode.
FP_dadd_Encode:
	ld xwa, (xsp + 24)
	ld xbc, xsp
	call FP_DP_Encode
	lda xsp, (xsp + 28)
	pop xiz
	ret

; One 0xFF fill byte, never executed (it follows `ret`), at an odd address so that
; FP_fadd starts on the next even address.  All 20 *_Pad bytes in this file are 0xFF at odd
; addresses (measured 2026-09-25); the library aligns some routines to 2 bytes, not all.
FP_fadd_Pad:
	.byte 0xff

; Single-precision ADDITION: *(float*)XWA = *(float*)XBC + *(float*)XDE. Same argument
; as FP_dadd. 32 call sites, all external (the DSP curve code does most of its work in
; single precision). NOTE: the name is wrong; this is __fadd.
; RENAMED 2026-09-25: was FP_SP_Mul (scripts/renaming/rename_v142_fp_libm.sed); the name now says
; what the header above established.
FP_fadd:
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
	jr nz, FP_fadd_DiffSign

; Equal signs: magnitudes add.
FP_fadd_SameSign:
	call FP_SP_AddMantissa
	jr FP_fadd_Encode

; Different signs: magnitudes subtract.
FP_fadd_DiffSign:
	bitm 0, (xsp + 2)
	jr nz, FP_fadd_SameSign
	call FP_SP_SubMantissa

; Repack with FP_SP_Encode.
FP_fadd_Encode:
	ld xwa, (xsp + 16)
	ld xbc, xsp
	call FP_SP_Encode
	lda xsp, (xsp + 20)
	pop xiz
	ret

; modf(double x, double *iptr). C signature f(double *result, double x, double *iptr).
; Calls FP_trunc (the integer-part extractor, 0x03E894) to produce the
; integral part, stores it through the caller's *iptr, and returns x minus that part -
; i.e. the fractional part - through *result. The 0.0 constant at 0x01F6AE is copied
; into the scratch buffer first as the default. Only callers: the sin kernel
; (0x03D9D8, 0x03DA81) for its quadrant reduction.
; NOTE: nothing here touches the DSP or a voice; the name is wrong.
; RENAMED 2026-09-25: was DSP_VoiceBlend (scripts/renaming/rename_v142_fp_libm.sed); the name now says
; what the header above established.
FP_modf:
	lda xsp, (xsp - 24)
	push xiz
	lda xbc, (FPConst_modf_Zero:24)
	lda xwa, (xsp + 20)
	call FP_DP_Raw8Copy
	lda xiy, (xsp + 36)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda xwa, (xsp + 20)
	push xwa
	call FP_trunc
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

; frexp(double x, int *exp). C signature f(double *result, double x, int *exp).
; Copies x to a scratch buffer, sets *exp = 0, and returns x unchanged when x == 0
; (FP_DP_CmpZero64 relation 5 = NE). Otherwise it reads the 11-bit biased exponent out
; of bytes 6..7 of the copy, computes *exp = biased - 0x03FE, and then forces the
; stored exponent field to 0x03FE by the loop at 0x03E256/0x03E263 (a compiler-generated
; count-down/count-up rather than a subtract). The result therefore has magnitude in
; [0.5, 1.0), which is exactly frexp's contract. Sign bit is preserved (0x03E27A).
; Callers: pow()'s overflow pre-checks (0x03D630, 0x03D77F, 0x03D795) and log()
; (0x03E779). The loops are bounded by the exponent value, at most 2047 iterations.
; NOTE: nothing here adjusts a frequency; the name is wrong.
; RENAMED 2026-09-25: was FP_DP_FreqAdjust (scripts/renaming/rename_v142_fp_libm.sed); the name now says
; what the header above established.
FP_frexp:
	dec 8, xsp
	pushw iz
	lda xwa, (xsp + 2)
	lda xbc, (xsp + 18)
	call FP_DP_Raw8Copy
	ld xwa, (xsp + 26)
	ldw (xwa), 0x0
	lda xwa, (xsp + 18)
	ld bc, 5:i3
	call FP_DP_CmpZero64
	ld xix, (xsp + 14)
	cp hl, 0:i3
	jr nz, FP_frexp_NonZeroExp
	ld xwa, xix
	lda xbc, (xsp + 18)
	call FP_DP_Raw8Copy
	jr FP_frexp_Return

; Extract the biased exponent from bytes 6..7 and compute *exp = biased - 0x3FE.
FP_frexp_NonZeroExp:
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
	ld iz, 0:i3
	cpw (xwa), 0x0
	jr gt, FP_frexp_DecCheck
	jr FP_frexp_IncCheck

; Count the stored exponent down toward 0x3FE (positive *exp case).
FP_frexp_DecLoop:
	dec 1, hl
	inc 1, iz

; Loop test for the count-down.
FP_frexp_DecCheck:
	ld xwa, (xsp + 26)
	cp iz, (xwa)
	jr lt, FP_frexp_DecLoop
	jr FP_frexp_Combine

; Count the stored exponent up toward 0x3FE (negative *exp case).
FP_frexp_IncLoop:
	inc 1, hl
	dec 1, iz

; Loop test for the count-up.
FP_frexp_IncCheck:
	ld xwa, (xsp + 26)
	cp iz, (xwa)
	jr gt, FP_frexp_IncLoop

; Merge the new exponent back with the top mantissa nibble and restore the sign bit.
FP_frexp_Combine:
	sll hl, 4
	ld a, (xbc)
	and a, 0xF
	extz wa
	or hl, wa
	bitm 7, (xiy)
	jr z, FP_frexp_StoreResult
	set 15, hl

; Write the patched exponent word and copy the mantissa to *result.
FP_frexp_StoreResult:
	ld (xbc), hl
	ld xwa, xix
	ld xbc, xde
	call FP_DP_Raw8Copy

; frexp epilogue.
FP_frexp_Return:
	popw iz
	inc 8, xsp
	ret

; One 0xFF fill byte, never executed (it follows `ret`), at an odd address so that
; FP_dmul starts on the next even address.  All 20 *_Pad bytes in this file are 0xFF at odd
; addresses (measured 2026-09-25); the library aligns some routines to 2 bytes, not all.
FP_dmul_Pad:
	.byte 0xff

; Double MULTIPLICATION: *(double*)XWA = *(double*)XBC * *(double*)XDE.
; Unpacks both operands with FP_DP_Decode and calls FP_DP_MulAdd (0x03EBCE), which adds
; the exponents, XORs the signs and does a 64x64 mantissa multiply - there is no
; FP_DP_AlignMantissa call, because multiplication needs no exponent alignment. Three
; independent confirmations: (a) the callee's structure, (b) pow()'s square-and-multiply
; at 0x03D6E7 uses it as `base = base * base`, (c) the sin kernel uses it to form z^2
; at 0x03DB0B. 69 call sites (48 external) - the most-used arithmetic routine in the
; firmware. NOTE: the name is wrong; this is __dmul.
; RENAMED 2026-09-25: was FP_DP_Add_Outer (scripts/renaming/rename_v142_fp_libm.sed); the name now says
; what the header above established.
FP_dmul:
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

; Single-precision MULTIPLICATION via FP_SP_MulAdd (0x03EC9E). 58 call sites, all
; external. NOTE: the name is wrong; this is __fmul.
; RENAMED 2026-09-25: was FP_SP_Add_Outer (scripts/renaming/rename_v142_fp_libm.sed); the name now says
; what the header above established.
FP_fmul:
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

; Pre-alignment step for double add/subtract. Compares the two records' exponents,
; raises the smaller one to match the larger, and shifts that record's 53-bit mantissa
; right by the difference (32/16/8/1 bits at a time), keeping a guard byte and rounding
; to nearest at the end. A shift beyond 53 (0x35) bits zeroes the operand entirely and
; marks it as zero. Called only by FP_DP_Sub and FP_dadd (= double add).
FP_DP_AlignMantissa:
	ld h, (xwa + 2)
	or h, (xbc + 2)
	ret nz
	ld ix, (xwa + 0:8)
	ld iy, (xbc + 0:8)
	cp ix, iy
	ret z
	jr lt, FP_DP_AlignMantissa_ShiftA
	ld (xbc + 0:8), ix
	ld xwa, xbc
	sub ix, iy
	jr FP_DP_AlignMantissa_Shift

; The first operand has the smaller exponent: shift it instead.
FP_DP_AlignMantissa_ShiftA:
	ld (xwa + 0:8), iy
	sub ix, iy
	neg ix

; Load the mantissa with a guard byte and start the shift ladder.
FP_DP_AlignMantissa_Shift:
	ld xde, (xwa + 3)
	ld xhl, (xwa + 7)
	ld e, 0x0:opc
	cp ix, 0x35
	jr gt, FP_DP_AlignMantissa_MaxShift
	cp ix, 0x20
	jr lt, FP_DP_AlignMantissa_Shift16
	ld xde, xhl
	ld xhl, 0:i3
	sub ix, 0x20
	jr z, FP_DP_AlignMantissa_Round

; Shift by 16 bits.
FP_DP_AlignMantissa_Shift16:
	cp ix, 0x10
	jr lt, FP_DP_AlignMantissa_Shift8
	ldto_werp DE, 0xEA
	ldfr_werp HL, 0xEA
	ldto_werp HL, 0xEE
	ldiw_erp 0xEE, 0
	sub ix, 0x10
	jr z, FP_DP_AlignMantissa_Round

; Shift by 8 bits.
FP_DP_AlignMantissa_Shift8:
	cp ix, 0x8
	jr lt, FP_DP_AlignMantissa_ShiftBit
	srl xde, 8
	ldfr_berp L, 0xEB
	srl xhl, 8
	sub ix, 0x8
	jr z, FP_DP_AlignMantissa_Round

; Bit-at-a-time remainder, `djnz IX` bounded by the exponent difference.
FP_DP_AlignMantissa_ShiftBit:
	srl xhl, 1
	extpfx3 0xDA, 0x24, 0x00
	rrc xde
	djnz16 ix, FP_DP_AlignMantissa_ShiftBit

; Drop the guard byte, rounding to nearest when it is >= 0x80.
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

; Store the aligned mantissa.
FP_DP_AlignMantissa_Store:
	ld (xwa + 4), xde
	ld (xwa + 8), xhl
	ret

; Exponent difference > 53: the smaller operand vanishes; zero it and set its zero flag.
FP_DP_AlignMantissa_MaxShift:
	ld xde, 0:i3
	ld (xwa), xde
	ld (xwa + 4), xde
	ld (xwa + 8), xde
	ld (xwa + 2), 0x1
	ret

; One 0xFF fill byte, never executed (it follows `ret`), at an odd address so that
; FP_SP_AlignMantissa starts on the next even address.  All 20 *_Pad bytes in this file are 0xFF at odd
; addresses (measured 2026-09-25); the library aligns some routines to 2 bytes, not all.
FP_SP_AlignMantissa_Pad:
	.byte 0xff

; Single-precision twin of FP_DP_AlignMantissa; the vanishing threshold is 24 (0x18).
FP_SP_AlignMantissa:
	ld e, (xwa + 2)
	or e, (xbc + 2)
	ret nz
	ld ix, (xwa + 0:8)
	ld hl, (xbc + 0:8)
	cp ix, hl
	ret z
	jr lt, FP_SP_AlignMantissa_ShiftA
	ex16 hl, ix
	jr FP_SP_AlignMantissa_Shift

; Swap so that the operand to be shifted is the one with the smaller exponent.
FP_SP_AlignMantissa_ShiftA:
	ld xbc, xwa

; Compute the difference and shift.
FP_SP_AlignMantissa_Shift:
	ld xde, (xbc + 3)
	ld e, 0x0:opc
	ld (xbc + 0:8), hl
	sub hl, ix
	cp hl, 0x18
	jr gt, FP_SP_AlignMantissa_MaxShift
	bit 4, l
	jr z, FP_SP_AlignMantissa_Shift_Odd
	srl xde, 16
	and l, 0xF
	jr z, FP_SP_AlignMantissa_Round

; Variable-count shift path.
FP_SP_AlignMantissa_Shift_Odd:
	ld a, l
	srla xde

; Drop the guard byte with round-to-nearest.
FP_SP_AlignMantissa_Round:
	ld l, e
	srl xde, 8
	cp l, 0x80
	jr c, FP_SP_AlignMantissa_Store
	inc 1, xde

; Store the aligned mantissa.
FP_SP_AlignMantissa_Store:
	ld (xbc + 4), xde
	ret

; Exponent difference > 24: zero the operand and set its zero flag.
FP_SP_AlignMantissa_MaxShift:
	ld xix, 0:i3
	ld (xbc + 4), xix
	ldib_erp 0xF2, 1
	ld (xbc), xix
	ret

; Double DIVISION mantissa core, operating on two unpacked 12-byte records: XWA is the
; dividend record (updated in place), XBC the divisor. SUBTRACTS the exponents
; (0x03E40A) and XORs the signs, short-circuits when the divisor mantissa is exactly
; 1.0, and otherwise runs a restoring long division through FP_Div_Step_Bit3 /
; FP_Div_Step4Bits, 4 quotient bits per call, 8 rounds (C = 8). This is the callee of
; FP_ddiv 0x03D3A4, which is the public double divide.
; NOTE: exponent SUBTRACTION is the giveaway - a multiply adds them (compare
; FP_DP_MulAdd 0x03EBCE). The name is wrong; this is the divide core.
; RENAMED 2026-09-25: was FP_DP_Mul_Outer (scripts/renaming/rename_v142_fp_libm.sed); the name now says
; what the header above established.
FP_DP_DivCore:
	ld e, (xwa + 2)
	or e, (xbc + 2)
	jp nz, (FP_NaN_Handler:24)
	ld l, (xbc + 3)
	xor (xwa + 3), l
	ld hl, (xbc + 0:8)
	sub (xwa + 0:8), hl
	ld xhl, (xbc + 8)
	ld xde, (xbc + 4)
	cp xhl, 0x100000
	jr nz, FP_DP_MulMantissaCore
	or xde, xde
	ret z

; The long-division body proper: two 4-bit-per-round passes producing the 53-bit
; quotient, then normalise-by-one if the leading bit did not land.
FP_DP_MulMantissaCore:
	push xiz
	lda xsp, (xsp - 12)
	ld xiy, (xwa + 8)
	ld xix, (xwa + 4)
	ld c, 0x8:opc
	ldto_berp B, 0xEF
	ld xiz, 0:i3
	call FP_Div_Step_Bit3
	ld (xsp), xiz
	ld c, 0x8:opc
	ld xiz, 0:i3
	call FP_Div_Step4Bits
	ld (xsp + 4), xiz
	ld xiy, (xsp)
	ld xix, (xsp + 4)
	bit_erpw 0xF6, 0x0F
	jr nz, FP_DP_MulMantissaCore_Round
	sll xix, 1
	stcf_erpw 0xF6, 0x0F
	rlc xiy
	decm 1, (xwa + 0:8)

; Re-pack the quotient into the record's 53-bit layout and round to nearest on the
; discarded byte, re-normalising if the round carries.
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
	incw 1, (xwa + 0:8)

; Store the quotient mantissa back into the record.
FP_DP_MulMantissaCore_Store:
	ld (xwa + 8), xiy
	ld (xwa + 4), xix
	lda xsp, (xsp + 12)
	pop xiz
	ret

; One 0xFF fill byte, never executed (it follows `ret`), at an odd address so that
; FP_SP_DivCore starts on the next even address.  All 20 *_Pad bytes in this file are 0xFF at odd
; addresses (measured 2026-09-25); the library aligns some routines to 2 bytes, not all.
FP_SP_DivCore_Pad:
	.byte 0xff

; Single-precision DIVISION mantissa core. Subtracts exponents, XORs signs, then runs a
; classic restoring division that resolves four quotient bits per iteration by keeping
; the divisor pre-shifted by 1, 2 and 3 (XIX, XIY, XIZ) and comparing against each.
; Eight iterations give 32 bits. Callee of FP_fdiv 0x03D3D4.
; NOTE: the name is wrong; this is the single-precision divide core.
; RENAMED 2026-09-25: was FP_SP_Mul_Outer (scripts/renaming/rename_v142_fp_libm.sed); the name now says
; what the header above established.
FP_SP_DivCore:
	ld e, (xwa + 2)
	or e, (xwa + 2)
	jp nz, (FP_NaN_Handler:24)
	push xiz
	push xwa
	ld hl, (xbc + 0:8)
	sub (xwa + 0:8), hl
	ld l, (xbc + 3)
	xor (xwa + 3), l
	ld xwa, (xwa + 4)
	ld xbc, (xbc + 4)
	cp xbc, 0x800000
	jr z, FP_SP_MulMantissaCore_Divisor1
	ld xhl, 0:i3
	ld xix, xbc
	add xix, xix
	ld xiy, xix
	add xiy, xiy
	ld xiz, xiy
	add xiz, xiz
	ldw de, 0x8
	sll xwa, 3

; Quotient bit 3: compare against divisor<<3.
FP_SP_MulMantissaCore_Loop:
	cp xwa, xiz
	jr c, FP_SP_MulMantissaCore_Bit2
	sub xwa, xiz
	set 3, l

; Quotient bit 2: compare against divisor<<2.
FP_SP_MulMantissaCore_Bit2:
	cp xwa, xiy
	jr c, FP_SP_MulMantissaCore_Bit1
	sub xwa, xiy
	set 2, l

; Quotient bit 1: compare against divisor<<1.
FP_SP_MulMantissaCore_Bit1:
	cp xwa, xix
	jr c, FP_SP_MulMantissaCore_Bit0
	sub xwa, xix
	set 1, l

; Quotient bit 0: compare against the divisor.
FP_SP_MulMantissaCore_Bit0:
	cp xwa, xbc
	jr c, FP_SP_MulMantissaCore_IterDone
	sub xwa, xbc
	set 0, l

; Eight-round loop counter in E; shift both accumulators left by 4 and repeat.
FP_SP_MulMantissaCore_IterDone:
	dec 1, e
	jr z, FP_SP_MulMantissaCore_Round
	sll xhl, 4
	sll xwa, 4
	jr FP_SP_MulMantissaCore_Loop

; Normalise by one bit if the leading quotient bit did not land, then round to nearest.
FP_SP_MulMantissaCore_Round:
	pop xwa
	bit_erpw 0xEE, 0x0F
	jr nz, FP_SP_MulMantissaCore_RoundUp
	sll xhl, 1
	decm 1, (xwa + 0:8)

; Round-to-nearest on the guard byte, with carry re-normalisation.
FP_SP_MulMantissaCore_RoundUp:
	cp l, 0x80
	jr c, FP_SP_MulMantissaCore_Shift8
	add xhl, 0x100
	jr nc, FP_SP_MulMantissaCore_Shift8
	extpfx3 0xDB, 0x24, 0x00
	rrc xhl

; Drop the guard byte.
FP_SP_MulMantissaCore_Shift8:
	srl xhl, 8

; Store the quotient mantissa.
FP_SP_MulMantissaCore_Store:
	ld (xwa + 4), xhl
	pop xiz
	ret

; Divisor mantissa is exactly 1.0: the quotient is the dividend unchanged.
FP_SP_MulMantissaCore_Divisor1:
	ld xhl, xwa
	pop xwa
	jr FP_SP_MulMantissaCore_Store

; Subtracts the 53-bit mantissa of the record at XBC from the one at XWA (exponents
; already aligned), records a borrow as a sign flip in B, takes the magnitude, and then
; RE-NORMALISES the difference: `bs1b` finds the new leading bit and the mantissa is
; shifted left (or right) with the exponent adjusted. A result of exactly zero sets the
; record's zero flag. Special flags divert to FP_DP_NegWithSign. Called by FP_DP_Sub
; (equal signs) and FP_dadd (different signs).
FP_DP_SubMantissa:
	ld e, (xwa + 2)
	or e, (xbc + 2)
	jp nz, (FP_DP_NegWithSign:24)
	ld xhl, (xwa + 8)
	ld xde, (xwa + 4)
	sub xde, (xbc + 4)
	sbc xhl, (xbc + 8)
	ld b, 0x0:opc
	jr nc, FP_DP_SubMantissa_NoBorrow
	ld b, 0x80:opc
	ld xiy, 0:i3
	dec 1, xiy
	xor xde, xiy
	xor xhl, xiy
	add xde, 0x1
	adc xhl, 0x0
	jr FP_DP_SubMantissa_Normalize

; No borrow: test for an exactly-zero result.
FP_DP_SubMantissa_NoBorrow:
	ld xiy, xhl
	or xiy, xde
	jr z, FP_DP_SubMantissa_Zero

; If bit 52 is already set, skip renormalisation.
FP_DP_SubMantissa_Normalize:
	bit_erpw 0xEE, 0x04
	jr nz, FP_DP_SubMantissa_Store
	ld iy, wa
	ld ix, (xwa + 0:8)

; Bit-search the high word; when it is empty, shift 16 bits at a time and retry.
; Terminates because the zero case was excluded above.
FP_DP_SubMantissa_NormLoop:
	bs1b_erpw 0xEE
	jr nov, FP_DP_SubMantissa_Shift
	ldfr_werp HL, 0xEE
	ldto_werp HL, 0xEA
	ldfr_werp DE, 0xEA
	ld de, 0:i3
	sub ix, 0x10
	jr FP_DP_SubMantissa_NormLoop

; Shift right by (bitpos - 4) with exponent correction.
FP_DP_SubMantissa_Shift:
	cp a, 4:i3
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

; Bit-at-a-time right shift, `djnz A` bounded.
FP_DP_SubMantissa_ShiftBit:
	srl xhl, 1
	extpfx3 0xDA, 0x24, 0x00
	rrc xde
	djnz8 a, FP_DP_SubMantissa_ShiftBit
	jr FP_DP_SubMantissa_StoreExp

; Shift left until bit 52 is set, decrementing the exponent each pass.
FP_DP_SubMantissa_ShiftLeft:
	sll xde, 1
	stcf_erpw 0xEE, 0x0F
	rlc xhl
	dec 1, ix
	bit_erpw 0xEE, 0x04
	jr z, FP_DP_SubMantissa_ShiftLeft

; Write the corrected exponent back.
FP_DP_SubMantissa_StoreExp:
	ld wa, iy
	ld (xwa + 0:8), ix

; Store the mantissa and XOR the borrow flag into the sign byte.
FP_DP_SubMantissa_Store:
	ld (xwa + 4), xde
	ld (xwa + 8), xhl
	xor (xwa + 3), b
	ret

; Exact cancellation: set the record's zero flag.
FP_DP_SubMantissa_Zero:
	ld (xwa + 2), 0x1
	ret

; Single-precision twin of FP_DP_SubMantissa on 8-byte records, with the same borrow /
; renormalise / zero-flag structure. Special flags divert to FP_DP_NegNoSign.
FP_SP_SubMantissa:
	ld e, (xwa + 2)
	or e, (xbc + 2)
	jp nz, (FP_DP_NegNoSign:24)
	ld xiy, xwa
	ld de, (xwa + 0:8)
	ld xix, (xwa + 4)
	sub xix, (xbc + 4)
	ld b, 0x0:opc
	jr z, FP_SP_SubMantissa_Zero
	jr nc, FP_SP_SubMantissa_Normalize
	cplw_erp 0xF2
	cpl ix
	inc 1, xix
	ld b, 0x80:opc

; Byte-wise renormalisation: shift left 8 bits while the top byte is empty.
FP_SP_SubMantissa_Normalize:
	cpiw_erp 0xF2, 0
	jr nz, FP_SP_SubMantissa_AlignBits
	sll xix, 8
	dec 8, de
	jr FP_SP_SubMantissa_Normalize

; Bit-search the top byte and do the final left shift, adjusting the exponent.
FP_SP_SubMantissa_AlignBits:
	ld w, 0x7:opc
	bs1b_erpw 0xF2
	sub w, a
	ld a, w
	jr z, FP_SP_SubMantissa_Store
	extz wa
	slla xix
	sub de, wa

; Store mantissa, exponent and the borrow-derived sign.
FP_SP_SubMantissa_Store:
	ld (xiy + 4), xix
	ld (xiy + 0:8), de
	xor (xiy + 3), b
	ret

; Exact cancellation: zero flag.
FP_SP_SubMantissa_Zero:
	ld (xiy + 4), xix
	ldib_erp 0xF2, 1
	ld (xiy), xix
	ret

; exp(double). C signature f(double *result, double x). Seeds the accumulator and the
; term with 1.0 (0x01F6B6 / 0x01F6BE). Guards, in order:
;   x == 0                 -> return 1.0
;   x > 709.778 (0x01F6C6) -> errno = ERANGE, return DBL_MAX (0x00F420)
;   x < -708.396 (0x01F6CE)-> return 0.0 (0x01F6D6)
; The two thresholds are log(DBL_MAX) and log(DBL_MIN) to full double precision, which
; is what identifies the function. The kernel is the plain Taylor series: on pass n it
; forms t = x/n (FP_ddiv = divide), term *= t (FP_dmul = multiply),
; acc += term (FP_dadd = add), and stops as soon as acc stops changing.
; IMPORTANT: the loop is HARD-BOUNDED at 300 passes (`cp IZ,0x012C; jr LE`) - contrast
; with log() below, which has no such bound. Only caller: pow() at 0x03D839.
; NOTE: the name is wrong; nothing here slides a pitch.
; RENAMED 2026-09-25: was VoicePitch_SlideEngine (scripts/renaming/rename_v142_fp_libm.sed); the name now says
; what the header above established.
FP_exp:
	lda xsp, (xsp - 48)
	pushw iz
	lda xbc, (FPConst_exp_One:24)
	lda xwa, (xsp + 34)
	call FP_DP_Raw8Copy
	lda xwa, (xsp + 58)
	ld bc, 5:i3
	call FP_DP_CmpZero64
	cp hl, 0:i3
	jr nz, FP_exp_NonZero
	ld xwa, (xsp + 54)
	lda xbc, (xsp + 34)
	call FP_DP_Raw8Copy
	jrl FP_exp_Epilog

; x != 0: load the term seed and test the overflow threshold.
FP_exp_NonZero:
	lda xbc, (FPConst_exp_NonZero_One:24)
	lda xwa, (xsp + 42)
	call FP_DP_Raw8Copy
	lda xwa, (xsp + 58)
	lda xbc, (FPConst_Exp_Overflow_Limit:24)
	ld de, 0:i3
	call FP_dcmp
	cp hl, 0:i3
	jr nz, FP_exp_LessPath
	ldw (0x040c22:24), 0x0022
	ld xwa, (xsp + 54)
	lda xbc, (FPConst_MaxNorm:24)
	call FP_DP_Raw8Copy
	jrl FP_exp_Epilog

; x <= log(DBL_MAX): test the underflow threshold.
FP_exp_LessPath:
	lda xwa, (xsp + 58)
	lda xbc, (FPConst_Exp_Underflow_Limit:24)
	ld de, 2:i3
	call FP_dcmp
	cp hl, 0:i3
	jr nz, FP_exp_StartIter
	ld xwa, (xsp + 54)
	lda xbc, (FPConst_exp_LessPath_Zero:24)
	call FP_DP_Raw8Copy
	jr FP_exp_Epilog

; Seed the term index IZ = 1.
FP_exp_StartIter:
	ld iz, 1:i3

; Taylor pass: save the previous sum, term *= x/n, sum += term, stop when the sum stops
; changing or n exceeds 300.
FP_exp_IterLoop:
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
	call FP_ddiv
	lda xwa, (xsp + 42)
	ld xbc, xwa
	lda xde, (xsp + 14)
	call FP_dmul
	lda xwa, (xsp + 34)
	ld xbc, xwa
	lda xde, (xsp + 42)
	call FP_dadd
	lda xwa, (xsp + 26)
	lda xbc, (xsp + 34)
	ld de, 5:i3
	call FP_dcmp
	cp hl, 0:i3
	jr z, FP_exp_Done
	inc 1, iz
	cp iz, 0x12C
	jr le, FP_exp_IterLoop

; Copy the converged sum to *result.
FP_exp_Done:
	ld xwa, (xsp + 54)
	lda xbc, (xsp + 34)
	call FP_DP_Raw8Copy

; exp() epilogue.
FP_exp_Epilog:
	popw iz
	lda xsp, (xsp + 48)
	ret

; log(double) (natural logarithm). C signature f(double *result, double x).
; If x <= 0 (FP_DP_CmpZero64 relation 3 = GT fails) -> errno = EDOM (0x21), result 0.0
; (0x01F6DE). Otherwise:
;   (1) t = x / sqrt(2) using the constant 1.4142135623730951 at 0x00F42C, then
;       frexp(t) -> exponent k in the local at (XSP+0x68), and ldexp(1.0, k) via
;       FP_ldexp; x is divided by that so the reduced argument sits
;       around 1.0.
;   (2) z = (x - 1.0) / (x + 1.0), using 1.0 at 0x01F6EE and 0x01F6F6.
;   (3) the atanh series: acc = z; on pass n (n stepping 1, 3, 5, ...) x *= z^2 and
;       acc += x/n, until acc stops changing.
;   (4) result = 2*acc (2.0 at 0x01F6FE) + k*ln2, using 0.6931471805599453 at 0x00F3D2.
; log(x) = 2*atanh((x-1)/(x+1)) + k*ln2 is the standard construction and the constants
; read out of the ROM (sqrt(2), ln 2) confirm it exactly.
; Only caller: pow() at 0x03D749.
; NOTE 1: the name is wrong; this is log().
; NOTE 2: the series loop at 0x03E7E6 has NO ITERATION CAP - see [UNCERTAIN] / findings.
; RENAMED 2026-09-25: was VoiceAmp_ConvergeEngine (scripts/renaming/rename_v142_fp_libm.sed); the name now says
; what the header above established.
FP_log:
	lda xsp, (xsp - 102)
	push xiz
	lda xwa, (xsp + 114)
	ld bc, 3:i3
	call FP_DP_CmpZero64
	cp hl, 0:i3
	jr nz, FP_log_InRange
	ldw (0x040c22:24), 0x0021
	ld xwa, (xsp + 110)
	lda xbc, (FPConst_log_Zero:24)
	call FP_DP_Raw8Copy
	jrl FP_log_Epilog

; x > 0: argument reduction by sqrt(2) + frexp + ldexp, then form z = (x-1)/(x+1) and
; z^2, and seed the accumulator with z.
FP_log_InRange:
	lda xwa, (xsp + 104)
	push xwa
	lda xde, (FPConst_Sqrt2:24)
	lda xbc, (xsp + 118)
	lda xwa, (xsp + 52)
	call FP_ddiv
	lda xiy, (xsp + 52)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda xwa, (xsp + 76)
	push xwa
	call FP_frexp
	pushm (xsp + 120)
	lda xiy, (FPConst_log_InRange_One_1:24)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda xwa, (xsp + 82)
	push xwa
	call FP_ldexp
	lda xsp, (xsp + 30)
	lda xwa, (xsp + 114)
	ld xbc, xwa
	lda xde, (xsp + 56)
	call FP_ddiv
	lda xbc, (xsp + 114)
	lda xde, (FPConst_log_InRange_One_2:24)
	lda xwa, (xsp + 48)
	call FP_dadd
	lda xbc, (xsp + 114)
	lda xde, (FPConst_log_InRange_One_3:24)
	lda xwa, (xsp + 72)
	call FP_DP_Sub
	lda xbc, (xsp + 72)
	lda xde, (xsp + 48)
	lda xwa, (xsp + 114)
	call FP_ddiv
	lda xde, (xsp + 114)
	ld xbc, xde
	lda xwa, (xsp + 96)
	call FP_dmul
	ld iz, 1:i3
	lda xbc, (xsp + 114)
	lda xwa, (xsp + 88)
	call FP_DP_Raw8Copy

; atanh series pass: x *= z^2, n += 2, acc += x/n; loops while the accumulator still
; changes. UNBOUNDED - there is no pass counter here, unlike exp()'s 300-pass cap.
FP_log_IterLoop:
	lda xwa, (xsp + 114)
	ld xbc, xwa
	lda xde, (xsp + 96)
	call FP_dmul
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
	call FP_ddiv
	lda xwa, (xsp + 88)
	ld xbc, xwa
	lda xde, (xsp + 72)
	call FP_dadd
	lda xwa, (xsp + 80)
	lda xbc, (xsp + 88)
	ld de, 5:i3
	call FP_dcmp
	cp hl, 0:i3
	jr nz, FP_log_IterLoop
	lda xiz, (FPConst_Ln2:24)
	ld wa, (xsp + 104)
	exts xwa
	ld (xsp + 44), xwa
	lda xbc, (xsp + 44)
	lda xwa, (xsp + 72)
	call FP_ScalarToDP
	lda xwa, (xsp + 72)
	ld xbc, xwa
	ld xde, xiz
	call FP_dmul
	lda xbc, (xsp + 88)
	lda xde, (FPConst_log_IterLoop_Two:24)
	lda xwa, (xsp + 48)
	call FP_dmul
	lda xbc, (xsp + 48)
	lda xwa, (xsp + 72)
	ld xde, xwa
	call FP_dadd
	ld xwa, (xsp + 110)
	lda xbc, (xsp + 72)
	call FP_DP_Raw8Copy

; log() epilogue: pop XIZ, release the 0x66-byte frame.
FP_log_Epilog:
	pop xiz
	lda xsp, (xsp + 102)
	ret

; One 0xFF fill byte, never executed (it follows `ret`), at an odd address so that
; FP_NaN_Handler starts on the next even address.  All 20 *_Pad bytes in this file are 0xFF at odd
; addresses (measured 2026-09-25); the library aligns some routines to 2 bytes, not all.
FP_NaN_Handler_Pad:
	.byte 0xff

; Special-value propagation for the divide cores. If the divisor record's flag bit 0 is
; set (divisor is zero) it stamps flag 8 - the "overflow/infinity" marker - into the
; dividend record so FP_DP_Encode/FP_SP_Encode will emit DBL_MAX/FLT_MAX with ERANGE.
; Otherwise it returns leaving the dividend's flag alone (0/0 propagates zero).
; This is the whole of the library's division-by-zero handling: no trap, no exception.
FP_NaN_Handler:
	ld h, (xwa + 2)
	ld l, (xbc + 2)
	bit 0, l
	ret z
	ld (xwa + 2), 0x8
	ret

; Integer part of a double, i.e. trunc(). C signature f(double *result, double x); it is
; the worker behind modf (FP_modf 0x03E1A5) and has no other caller.
; Copies a 4-word template from 0x01F706, then:
;   - biased exponent 0 or 0x7FF (zero/inf/NaN) -> result = 0.0 (0x01F70E)
;   - unbiased exponent >= 0x28 goes straight to the large-value test
;   - otherwise it builds a magic value with exponent field 0x000F, adds it and
;     subtracts it again (FP_dadd then FP_DP_Sub, i.e. add then subtract) to force
;     rounding, and re-reads the exponent
;   - unbiased exponent < 0 (|x| < 1) -> result = 0.0 (0x01F716)
;   - unbiased exponent >= 0x34 (52) -> x is already integral, copy it through
;   - otherwise it clears the fractional mantissa bits with the nibble-shift scan loops
;     at 0x03E96A / 0x03E9C7 (rotate the mantissa down by exponent/8 bytes, mask the
;     partial nibble, rotate back) and rebuilds the exponent field.
; NOTE: nothing here touches a DSP register or a voice; the name is wrong.
; RENAMED 2026-09-25: was DSP_VoiceRegUpdate (scripts/renaming/rename_v142_fp_libm.sed); the name now says
; what the header above established.
FP_trunc:
	lda xsp, (xsp - 28)
	push xiz
	ld xiy, FPConst_trunc_Zero
	lda xix, (xsp + 24)
	ld bc, 4:i3
	ldirw
	lda xwa, (xsp + 16)
	lda xbc, (xsp + 40)
	call FP_DP_Raw8Copy
	lda xhl, (xsp + 16)
	lda xbc, (xhl + 6)
	ld wa, (xbc)
	and wa, 0x7FF0
	srl wa, 4
	cp wa, 0:i3
	jr z, FP_trunc_ZeroOrMax
	cp wa, 0x7FF
	jr nz, FP_trunc_InRange

; Biased exponent 0 or 0x7FF: return 0.0.
FP_trunc_ZeroOrMax:
	ld xwa, (xsp + 36)
	lda xbc, (FPConst_trunc_ZeroOrMax_Zero:24)
	call FP_DP_Raw8Copy
	jrl FP_trunc_Return

; The add-magic/subtract-magic rounding trick, then re-read the exponent.
FP_trunc_InRange:
	ld (xsp + 4), wa
	sub wa, 0x3FF
	cp wa, 0x28
	jr ge, FP_trunc_NegOffset
	lda xde, (xsp + 24)
	ldw (xde), 0xF
	ld wa, (xbc)
	and wa, 0xFFF0
	ld (xde + 6), wa
	ld xiz, xhl
	ld xbc, xiz
	ld xwa, xiz
	call FP_dadd
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

; Unbiased exponent < 0 (|x| < 1): the integer part is 0.0.
FP_trunc_NegOffset:
	cp wa, 0:i3
	jr ge, FP_trunc_LargeOffset
	ld xwa, (xsp + 36)
	lda xbc, (FPConst_trunc_NegOffset_Zero:24)
	call FP_DP_Raw8Copy
	jrl FP_trunc_Return

; Unbiased exponent >= 52: x has no fractional bits, copy it unchanged.
FP_trunc_LargeOffset:
	cp wa, 0x34
	jr lt, FP_trunc_BlendLoop
	ld xwa, (xsp + 36)
	lda xbc, (xsp + 40)
	call FP_DP_Raw8Copy
	jrl FP_trunc_Return

; Split the exponent into a byte count and a bit remainder (divs by 8) for the
; nibble-shift masking below.
FP_trunc_BlendLoop:
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

; Rotate the mantissa down one nibble per byte into the scratch buffer.
FP_trunc_ForwardScan:
	ld w, (xde - 1)
	srl w, 4
	ld a, (xde)
	sll a, 4
	or a, w
	ld (xbc+), a
	dec 1, xde
	cp xde, xiz
	jr ugt, FP_trunc_ForwardScan
	ld a, (xhl)
	sll a, 4
	ld (xix + 6), a
	ld wa, 6:i3
	cp iy, 6:i3
	jr ge, FP_trunc_BackScan

; Zero the bytes above the retained integer bits.
FP_trunc_FillPad:
	stib_ind 0x07, 0xF0, 0xE0, 0x00
	dec 1, wa
	cp wa, iy
	jr gt, FP_trunc_FillPad

; Mask the partial byte at the integer/fraction boundary.
FP_trunc_BackScan:
	lda_dri XDE, 0x07, 0xF0, 0xF4
	cpw (xsp + 6), 0x0
	jr z, FP_trunc_ZeroLow
	ldw wa, 0x8
	sub wa, (xsp + 6)
	ldw bc, 0xFF
	and a, 0xF
	jr z, FP_trunc_MaskLow
	slaa bc

; Apply the computed byte mask.
FP_trunc_MaskLow:
	and (xde), c
	jr FP_trunc_BackScan2

; Boundary lands on a byte edge: just zero it.
FP_trunc_ZeroLow:
	ld (xde), 0x0

; Prepare the reverse nibble rotation.
FP_trunc_BackScan2:
	ld xbc, xhl
	lda xwa, (xix + 6)
	ld xde, xwa
	lda xiy, (xwa - 6)

; Rotate the masked mantissa back up one nibble per byte and restore the exponent field.
FP_trunc_BackScanLoop:
	ld w, (xde - 1)
	sll w, 4
	ld a, (xde)
	srl a, 4
	or a, w
	ld (xbc+), a
	dec 1, xde
	cp xde, xiy
	jr ugt, FP_trunc_BackScanLoop
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

; trunc() epilogue.
FP_trunc_Return:
	pop xiz
	lda xsp, (xsp + 28)
	ret

; One 0xFF fill byte, never executed (it follows `ret`), at an odd address so that
; FP_DP_CopyNoSign starts on the next even address.  All 20 *_Pad bytes in this file are 0xFF at odd
; addresses (measured 2026-09-25); the library aligns some routines to 2 bytes, not all.
FP_CopyVariant_Pad:
	.byte 0xff

; Special-value copy helper, single-precision entry (D = 0): if the source record at XBC
; is not flagged, copy 8 bytes from the XBC record to the XWA record. Reached from
; FP_SP_AddMantissa when either operand carries a special flag.
FP_DP_CopyNoSign:
	ld d, 0x0:opc
	jr FP_DP_CopyDispatch

; Same helper, double-precision entry (D = 1) -> copies 12 bytes. A third entry at
; 0x03EA0A sets D = 2 but is not referenced anywhere in the image.
FP_DP_CopyWithSign:
	ld d, 0x1:opc
	jr FP_DP_CopyDispatch
; The third entry (D = 2) the header above says is unreferenced; labelled 2026-09-25.
FP_CopyWithSign_D2:
	ld d, 0x2:opc
	jr __jrt_nop_03EA0E
__jrt_nop_03EA0E:

; Shared body: bail out if the source's zero flag is set, else copy 8 or 12 bytes
; according to D. (Alias symbol __jrt_nop_03EA0E is the same address.)
FP_DP_CopyDispatch:
	bitm 0, (xbc + 2)
	ret nz
	cp d, 0:i3
	jr nz, FP_DP_Copy3Words
	ld xhl, (xbc)
	ld xde, (xbc + 4)
	ld (xwa), xhl
	ld (xwa + 4), xde
	ret

; 12-byte record copy (exponent + both mantissa words).
FP_DP_Copy3Words:
	ld xhl, (xbc)
	ld (xwa), xhl
	ld xhl, (xbc + 4)
	ld (xwa + 4), xhl
	ld xhl, (xbc + 8)
	ld (xwa + 8), xhl
	ret

; One 0xFF fill byte, never executed (it follows `ret`), at an odd address so that
; FP_SP_DecodeToInt starts on the next even address.  All 20 *_Pad bytes in this file are 0xFF at odd
; addresses (measured 2026-09-25); the library aligns some routines to 2 bytes, not all.
FP_SP_DecodeToInt_Pad:
	.byte 0xff

; Unpacked DOUBLE-precision record -> int32, returned in XHL. Rejects the NaN marker,
; returns 0 for a negative exponent, sets ERANGE with 0xFFFFFFFF above exponent 31, and
; otherwise shifts the 53-bit mantissa (read from record+6 / record+8) to align bit 20
; with the requested exponent, then applies the sign. Called only from
; FP_DP_DecodeToInt.
; NOTE: SP/DP are swapped - the 0x14 (20-bit) split and the +6/+8 mantissa access are
; the double layout.
FP_SP_DecodeToInt:
	ld xde, (xwa)
	cpib_erp 0xEA, 0
	jr nz, FP_SP_DecodeToInt_NaN
	cp de, 0:i3
	jr lt, FP_SP_DecodeToInt_Underflow
	cp de, 0x1F
	jr gt, FP_SP_DecodeToInt_Overflow
	ld xiy, (xwa + 8)
	ld ix, (xwa + 6)
	cp de, 0x14
	jr z, FP_SP_DecodeToInt_SignCorrect
	jr lt, FP_SP_DecodeToInt_ShiftRight
	sub e, 0x14

; Exponent above 20: shift left, `djnz E` bounded.
FP_SP_DecodeToInt_ShiftLeft:
	sll ix, 1
	stcf_erpw 0xF6, 0x0F
	rlc xiy
	djnz8 e, FP_SP_DecodeToInt_ShiftLeft
	jr FP_SP_DecodeToInt_SignCorrect

; Exponent below 20: shift right by (20 - exponent).
FP_SP_DecodeToInt_ShiftRight:
	ld a, 0x14:opc
	sub a, e
	cp a, 0x10
	jr lt, FP_SP_DecodeToInt_ShiftRightLoop
	ldto_werp IY, 0xF6
	extz xiy
	sub a, 0x10
	jr z, FP_SP_DecodeToInt_SignCorrect

; Final variable right shift.
FP_SP_DecodeToInt_ShiftRightLoop:
	srla xiy

; Two's-complement negate when the record's sign byte is set.
FP_SP_DecodeToInt_SignCorrect:
	cpib_erp 0xEB, 0
	jr z, FP_SP_DecodeToInt_Return
	cplw_erp 0xF6
	cpl iy
	inc 1, xiy

; Move the result into XHL.
FP_SP_DecodeToInt_Return:
	ld xhl, xiy
	ret

; |x| < 1: result 0 with ERANGE.
FP_SP_DecodeToInt_Underflow:
	ld xhl, 0:i3
	jr FP_SP_DecodeToInt_SetError

; |x| >= 2^32: result 0xFFFFFFFF with ERANGE.
FP_SP_DecodeToInt_Overflow:
	ld xhl, 0:i3
	dec 1, xhl

; errno (0x040C22) = 0x22 (ERANGE).
FP_SP_DecodeToInt_SetError:
	ldw (0x040c22:24), 0x0022
	ret

; NaN marker: return 0, errno untouched.
FP_SP_DecodeToInt_NaN:
	ld xhl, 0:i3
	ret

; ldexp(double x, int n) - scale by a power of two. C signature
; f(double *result, double x, int n); result pointer at entrySP+4, x at entrySP+8,
; n at entrySP+0x10. Returns the constant at 0x01F71E when x == 0. Rejects n > 0x7FF
; (errno = ERANGE, +/-DBL_MAX) and n < -0x7FF (errno = ERANGE, 0.0 from 0x01F726).
; Otherwise it extracts the 11-bit biased exponent out of bytes 6..7 and steps it up or
; down one at a time (the compiler emitted loops rather than an add), setting ERANGE and
; saturating on the way if the biased exponent would leave (0, 0x7FF), then writes the
; exponent field back and copies the result out. Sign bit preserved at 0x03EBB0.
; Only caller: log() at 0x03E790 (ldexp(1.0, k)).
; NOTE: the name is wrong; this has nothing to do with envelopes or frequency.
; RENAMED 2026-09-25: was VoiceFreq_EnvelopeStep (scripts/renaming/rename_v142_fp_libm.sed); the name now says
; what the header above established.
FP_ldexp:
	lda xsp, (xsp - 16)
	pushw iz
	lda xwa, (xsp + 10)
	lda xbc, (xsp + 26)
	call FP_DP_Raw8Copy
	lda xwa, (xsp + 26)
	ld bc, 5:i3
	call FP_DP_CmpZero64
	ld xde, (xsp + 22)
	cp hl, 0:i3
	jr nz, FP_ldexp_InRange
	lda xbc, (FPConst_ldexp_Zero:24)
	ld xwa, xde
	call FP_DP_Raw8Copy
	jrl FP_ldexp_Epilog

; x != 0: test n against the +0x7FF upper limit.
FP_ldexp_InRange:
	ld bc, (xsp + 34)
	lda xwa, (xsp + 10)
	lda xhl, (xwa + 7)
	cp bc, 0x7FF
	jr le, FP_ldexp_ClampLow
	ldw (0x040c22:24), 0x0022
	lda xbc, (FPConst_MaxNorm:24)
	bitm 7, (xhl)
	jr z, FP_ldexp_ClampHigh
	ld xwa, xde
	call FP_DP_CopyOrNegate8
	jrl FP_ldexp_Epilog

; Positive-sign overflow: copy +DBL_MAX.
FP_ldexp_ClampHigh:
	ld xwa, xde
	call FP_DP_Raw8Copy
	jrl FP_ldexp_Epilog

; Test n against the -0x7FF lower limit; below it, return 0.0.
FP_ldexp_ClampLow:
	cp bc, 0xF801
	jr ge, FP_ldexp_NibbleAdjust
	lda xbc, (FPConst_ldexp_ClampLow_Zero:24)
	ld xwa, xde
	call FP_DP_Raw8Copy
	jrl FP_ldexp_Epilog

; Extract the biased exponent from the nibble-split bytes 6..7 into IY.
FP_ldexp_NibbleAdjust:
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
	ld iz, 0:i3
	cp bc, 0:i3
	jr le, FP_ldexp_DecCheck
	cp bc, 0:i3
	jr le, FP_ldexp_StoreResult

; n > 0: increment the biased exponent once per pass, saturating at 0x7FF with ERANGE.
; Bounded by n, which was already limited to 0x7FF.
FP_ldexp_IncLoop:
	ld wa, iy
	inc 1, wa
	cp wa, 0x7FF
	jr c, FP_ldexp_IncStep
	ldw (0x040c22:24), 0x0022
	lda xbc, (FPConst_MaxNorm:24)
	ld a, (xix)
	bit 7, a
	jr z, FP_ldexp_IncClamp_Copy
	ld xwa, xde
	call FP_DP_CopyOrNegate8
	jr FP_ldexp_Epilog

; Overflow with a positive value: copy +DBL_MAX.
FP_ldexp_IncClamp_Copy:
	ld xwa, xde
	call FP_DP_Raw8Copy
	jr FP_ldexp_Epilog

; One successful increment; loop while IZ < n.
FP_ldexp_IncStep:
	inc 1, iy
	inc 1, iz
	cp iz, bc
	jr lt, FP_ldexp_IncLoop
	jr FP_ldexp_StoreResult

; n == 0: nothing to do.
FP_ldexp_DecCheck:
	cp bc, 0:i3
	jr ge, FP_ldexp_StoreResult

; n < 0: decrement the biased exponent, flushing to 0.0 with ERANGE at 0 (0x01F72E).
FP_ldexp_DecLoop:
	ld wa, iy
	sub wa, 0x1
	jr nz, FP_ldexp_DecStep
	ldw (0x040c22:24), 0x0022
	lda xbc, (FPConst_ldexp_DecLoop_Zero:24)
	ld xwa, xde
	call FP_DP_Raw8Copy
	jr FP_ldexp_Epilog

; One successful decrement; loop while IZ > n.
FP_ldexp_DecStep:
	dec 1, iy
	dec 1, iz
	cp iz, bc
	jr gt, FP_ldexp_DecLoop

; Reassemble the exponent nibbles with the retained top mantissa nibble.
FP_ldexp_StoreResult:
	sll iy, 4
	ldto_berp C, 0xE2
	and c, 0xF
	extz bc
	ld wa, iy
	or wa, bc
	ld iy, wa
	bit 7, l
	jr z, FP_ldexp_SetHighBit
	set 15, iy

; Restore the sign bit and write the patched word back, then copy the result out.
FP_ldexp_SetHighBit:
	ld bc, iy
	ld xwa, (xsp + 6)
	ld (xwa), bc
	ld xbc, (xsp + 2)
	ld xwa, xde
	call FP_DP_Raw8Copy

; ldexp epilogue.
FP_ldexp_Epilog:
	popw iz
	lda xsp, (xsp + 16)
	ret

; One 0xFF fill byte, never executed (it follows `ret`), at an odd address so that
; FP_DP_MulAdd starts on the next even address.  All 20 *_Pad bytes in this file are 0xFF at odd
; addresses (measured 2026-09-25); the library aligns some routines to 2 bytes, not all.
FP_DP_MulAdd_Pad:
	.byte 0xff

; Double MULTIPLY mantissa core, on two unpacked 12-byte records: XWA is updated in
; place, XBC is the second operand. ADDS the exponents (0x03EBDF), XORs the signs, and
; forms the 106-bit product as four 32x32 partial products through FP_MulMantissa64x64,
; accumulating into a 16-byte stack buffer. Then it normalises by at most one bit,
; re-packs to 53 bits with a 4-bit shift, and rounds to nearest on the discarded byte.
; Special flags divert to FP_Overflow_Handler. Called only by FP_dmul, which is
; therefore the public double multiply.
FP_DP_MulAdd:
	ld e, (xwa + 2)
	or e, (xbc + 2)
	jp nz, (FP_Overflow_Handler:24)
	push xiz
	lda xsp, (xsp - 16)
	ld xhl, (xbc)
	add (xwa + 0:8), hl
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
	ld xhl, 0:i3
	adc (xsp + 12), xhl

; Accumulate the low x high cross product with carry into the third word.
FP_DP_MulAdd_Sum1:
	ld xhl, (xwa + 8)
	ld xiy, (xbc + 4)
	call FP_MulMantissa64x64
	add (xsp + 4), xhl
	adc (xsp + 8), xde
	jr nc, FP_DP_MulAdd_Sum2
	ld xhl, 0:i3
	adc (xsp + 12), xhl

; Read the 106-bit product back out, normalise by one bit if bit 105 is set.
FP_DP_MulAdd_Sum2:
	ld ix, (xsp + 5)
	ld xde, (xsp + 7)
	ld xhl, (xsp + 11)
	bit_erpw 0xEE, 0x01
	jr z, FP_DP_MulAdd_Round
	incw 1, (xwa + 0:8)
	srl xhl, 1
	extpfx3 0xDA, 0x24, 0x00
	rrc xde
	extpfx3 0xDC, 0x24, 0x00
	rrc ix

; Shift the product down to 53 bits and round to nearest, re-normalising on carry.
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
	incw 1, (xwa + 0:8)

; Store the product mantissa back into the record.
FP_DP_MulAdd_Store:
	ld (xwa + 4), xde
	ld (xwa + 8), xhl
	lda xsp, (xsp + 16)
	pop xiz
	ret

; Single-precision MULTIPLY mantissa core. Adds exponents, XORs signs, forms the 48-bit
; product with four hardware `mul` instructions, normalises by at most one bit and
; rounds to nearest. Called only by FP_fmul.
FP_SP_MulAdd:
	ld e, (xwa + 2)
	or e, (xbc + 2)
	jp nz, (FP_Overflow_Handler:24)
	push xiz
	ld xiz, xwa
	ld xhl, (xbc)
	add (xwa + 0:8), hl
	ldto_berp L, 0xEF
	xor (xwa + 3), l
	ld xwa, (xwa + 4)
	ld xbc, (xbc + 4)
	ldto_werp DE, 0xE2
	ld hl, de
	ldto_werp IX, 0xE6
	mul xde, ix
	mul xhl, bc
	mul xix, wa
	mul xwa, bc
	add xhl, xix
	ex_erpw_rr DE, 0xEA
	add xde, xhl
	ldto_werp HL, 0xE2
	extz xhl
	add xde, xhl
	bit_erpw 0xEA, 0x0F
	jr z, FP_SP_MulAdd_NormCheck
	incw 1, (xiz + 0:8)
	jr FP_SP_MulAdd_Round

; Leading bit did not land: shift left one instead of incrementing the exponent.
FP_SP_MulAdd_NormCheck:
	sll wa, 1
	stcf_erpw 0xEA, 0x0F
	rlc xde

; Round to nearest on the guard byte.
FP_SP_MulAdd_Round:
	cp e, 0x80
	jr c, FP_SP_MulAdd_Store
	add xde, 0x100
	jr nc, FP_SP_MulAdd_Store
	extpfx3 0xDA, 0x24, 0x00
	rrc xde
	incw 1, (xiz + 0:8)

; Drop the guard byte and store the product mantissa.
FP_SP_MulAdd_Store:
	srl xde, 8
	ld (xiz + 4), xde
	pop xiz
	ret

; 32x32 -> 64 unsigned multiply built from four 16x16 `mul` instructions with carry
; propagation. Inputs XHL and XIY, result in XHL (low) and XDE (high). Called four times
; per double multiply by FP_DP_MulAdd. Name is accurate about intent though the operand
; width is 32, not 64.
FP_MulMantissa64x64:
	ldto_werp DE, 0xEE
	ld ix, de
	ldto_werp IZ, 0xF6
	mul xde, iz
	mul xix, iy
	mul xiz, hl
	mul xhl, iy
	add xix, xiz
	adc_erpw 0xEA, 0x00, 0x00
	add_erpw_rr DE, 0xF2
	adc_erpw 0xEA, 0x00, 0x00
	add_erpw_rr IX, 0xEE
	ld qhl, ix
	ret nc
	adc xde, 0x0
	ret

; Restoring-division engine producing FOUR quotient bits per call, used by the double
; divide core FP_DP_DivCore. Registers: XIX/XIY = running remainder, XDE/XHL =
; divisor, XIZ = quotient accumulator, C = remaining rounds. Each of the four unrolled
; stages shifts the remainder left one bit, trial-subtracts the divisor, and either
; keeps the subtraction (setting the corresponding bit of IZ) or restores it. The entry
; at FP_Div_Step_Bit3 (0x03ED64) skips the initial shift for the first call.
; The loop back-edge at 0x03EE33 is bounded by `dec C` (8 rounds).
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

; Alternate entry / bit-3 trial subtraction without a preceding shift.
FP_Div_Step_Bit3:
	cp_erpb_rr B, 0xF7
	jr gt, FP_Div_Step_Bit2_Entry
	sub xix, xde
	sbc xiy, xhl
	jr nc, FP_Div_Step_Bit3_Set
	add xix, xde
	adc xiy, xhl
	jr FP_Div_Step_Bit2_Entry

; Bit 3 of the quotient nibble is 1.
FP_Div_Step_Bit3_Set:
	set 3, iz

; Shift the remainder and start the bit-2 stage.
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

; Bit-2 trial subtraction.
FP_Div_Step_Bit2:
	cp_erpb_rr B, 0xF7
	jr gt, FP_Div_Step_Bit1_Entry
	sub xix, xde
	sbc xiy, xhl
	jr nc, FP_Div_Step_Bit2_Set
	add xix, xde
	adc xiy, xhl
	jr FP_Div_Step_Bit1_Entry

; Bit 2 of the quotient nibble is 1.
FP_Div_Step_Bit2_Set:
	set 2, iz

; Shift the remainder and start the bit-1 stage.
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

; Bit-1 trial subtraction.
FP_Div_Step_Bit1:
	cp_erpb_rr B, 0xF7
	jr gt, FP_Div_Step_Bit0_Entry
	sub xix, xde
	sbc xiy, xhl
	jr nc, FP_Div_Step_Bit1_Set
	add xix, xde
	adc xiy, xhl
	jr FP_Div_Step_Bit0_Entry

; Bit 1 of the quotient nibble is 1.
FP_Div_Step_Bit1_Set:
	set 1, iz

; Shift the remainder and start the bit-0 stage.
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

; Bit-0 trial subtraction.
FP_Div_Step_Bit0:
	cp_erpb_rr B, 0xF7
	jr gt, FP_Div_Step_Continue
	sub xix, xde
	sbc xiy, xhl
	jr nc, FP_Div_Step_Bit0_Set
	add xix, xde
	adc xiy, xhl
	jr FP_Div_Step_Continue

; Bit 0 of the quotient nibble is 1.
FP_Div_Step_Bit0_Set:
	set 0, iz

; `dec C`; return when the round count is exhausted, otherwise shift the quotient
; accumulator left one nibble and loop.
FP_Div_Step_Continue:
	dec 1, c
	ret z
	sll xiz, 4
	jrl FP_Div_Step4Bits

; Special-value negate-copy helper, single-precision entry (D = 0): if the source record
; is not flagged zero, copy 8 bytes from XBC to XWA and flip the sign byte. Reached from
; FP_SP_SubMantissa when an operand carries a special flag.
FP_DP_NegNoSign:
	ld d, 0x0:opc
	jr FP_DP_NegDispatch

; Same helper, double-precision entry (D = 1) -> 12 bytes. Reached from
; FP_DP_SubMantissa. A third entry at 0x03EE3E sets D = 2 and is unreferenced.
FP_DP_NegWithSign:
	ld d, 0x1:opc
	jr FP_DP_NegDispatch
; The third entry (D = 2) the header above says is unreferenced; labelled 2026-09-25.
FP_NegWithSign_D2:
	ld d, 0x2:opc
	jr __jrt_nop_03EE42
__jrt_nop_03EE42:

; Shared body: bail out on the zero flag, else copy 8 or 12 bytes per D and XOR 0x80
; into the sign byte. (Alias symbol __jrt_nop_03EE42 is the same address.)
FP_DP_NegDispatch:
	bitm 0, (xbc + 2)
	ret nz
	cp d, 0:i3
	jr nz, FP_DP_Neg3Words
	ld xhl, (xbc)
	ld xde, (xbc + 4)
	ld (xwa), xhl
	ld (xwa + 4), xde
	xormi8 (xwa + 3), 0x80
	ret

; 12-byte negate-copy.
FP_DP_Neg3Words:
	ld xhl, (xbc)
	ld (xwa), xhl
	ld xhl, (xbc + 4)
	ld (xwa + 4), xhl
	ld xhl, (xbc + 8)
	ld (xwa + 8), xhl
	xormi8 (xwa + 3), 0x80
	ret

; One 0xFF fill byte, never executed (it follows `ret`), at an odd address so that
; FP_Overflow_Handler starts on the next even address.  All 20 *_Pad bytes in this file are 0xFF at odd
; addresses (measured 2026-09-25); the library aligns some routines to 2 bytes, not all.
FP_Overflow_Handler_Pad:
	.byte 0xff

; Special-value handler for the two multiply cores: stamps flag 1 ("zero") into the
; destination record and returns, so a multiply where either operand is flagged
; produces zero rather than propagating an infinity. Note the asymmetry with
; FP_NaN_Handler (0x03E884), which the divide cores use and which stamps flag 8.
FP_Overflow_Handler:
	ld (xwa + 2), 0x1
	ret

; --- 0x03EE75-0x03EEFF  FP_Library_End_Pad - end-of-library 0xFF fill
; 139 bytes of 0xFF. No code, no data; this is the tail padding of the sub-CPU program
; image and the end of the region.
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
