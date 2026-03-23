; =============================================================================
; Audio_CommandEncoder -- Printf-like audio command byte formatter
; =============================================================================
; Parses format string with % specifiers to build multi-byte command packets.
; Stack frame: 74 bytes. Called exclusively by Audio_SendCommand.
Audio_CommandEncoder:
	lda xsp, (xsp - 74)
	push xiz
	ldw (xsp + 4), 0x0
	jrl AudioCmd_MainLoop_ReadNext

AudioCmd_OutputLiteral:
	cp iz, 0x25
	jr z, AudioCmd_ParseFormatSpec
	pushw iz
	ld xwa, (xsp + 92)
	call (xwa)
	inc 2, xsp
	incm 1, (xsp + 4)
	jrl AudioCmd_MainLoop_ReadNext

AudioCmd_ParseFormatSpec:
	ldw (xsp + 8), 0x0
	ldw (xsp + 10), 0x0
	ldw (xsp + 6), 0x0
	sti16_24 0x03c220, 0x0020

AudioCmd_ReadFormatChar:
	ld xwa, (xsp + 82)
	ld_spib C, 0xE0
	ld (xsp + 82), xwa
	ldfr_berp C, 0xF8
	exts iz
	ld wa, iz
	cp iz, 0x30
	jr z, AudioCmd_Flag_Zero
	cp wa, 0x2D
	jr z, AudioCmd_Flag_Minus
	cp wa, 0x2B
	jr z, AudioCmd_Flag_Plus
	cp wa, 0x23
	jr z, AudioCmd_Flag_Hash
	cp wa, 0x20
	jr z, AudioCmd_Flag_Space
	cp iz, 0x2A
	jr nz, AudioCmd_CheckIfDigit
	ld xbc, (xsp + 86)
	lds32 xwa, 2
	add (xbc), xwa
	ld xwa, (xbc)
	ld wa, (xwa - 2)
	ld (xsp + 8), wa
	cpw (xsp + 8), 0x0
	jr ge, AudioCmd_StarWidth_Positive
	ld wa, (xsp + 8)
	neg wa
	ld (xsp + 8), wa
	setm 1, (xsp + 6)

AudioCmd_StarWidth_Positive:
	ld xwa, (xsp + 82)
	ld_spib C, 0xE0
	ld (xsp + 82), xwa
	ldfr_berp C, 0xF8
	exts iz
	jr AudioCmd_CheckPrecisionDot

AudioCmd_Flag_Space:
	setm 2, (xsp + 6)
	jr AudioCmd_ReadFormatChar

AudioCmd_Flag_Hash:
	setm 3, (xsp + 6)
	jr AudioCmd_ReadFormatChar

AudioCmd_Flag_Plus:
	setm 0, (xsp + 6)
	jr AudioCmd_ReadFormatChar

AudioCmd_Flag_Minus:
	setm 1, (xsp + 6)
	jr AudioCmd_ReadFormatChar

AudioCmd_Flag_Zero:
	sti16_24 0x03c220, 0x0030
	jrl AudioCmd_ReadFormatChar

AudioCmd_ParseWidthDigit:
	ld bc, iz
	sub bc, 0x30
	ld wa, (xsp + 8)
	muls wa, 0xA
	ld (xsp + 8), wa
	add (xsp + 8), bc
	ld xwa, (xsp + 82)
	ld_spib C, 0xE0
	ld (xsp + 82), xwa
	ldfr_berp C, 0xF8
	exts iz

AudioCmd_CheckIfDigit:
	ldto_berp A, 0xF8
	extz wa
	lda_24 xbc, 0xeed778
	bit_dri 2, 0x07, 0xE4, 0xE0
	jr nz, AudioCmd_ParseWidthDigit

AudioCmd_CheckPrecisionDot:
	cp iz, 0x2E
	jr nz, AudioCmd_CheckLengthH
	setm 4, (xsp + 6)
	ld xwa, (xsp + 82)
	ld_spib C, 0xE0
	ld (xsp + 82), xwa
	ldfr_berp C, 0xF8
	exts iz
	cp iz, 0x2A
	jr nz, AudioCmd_CheckPrecisionDigit
	ld xbc, (xsp + 86)
	lds32 xwa, 2
	add (xbc), xwa
	ld xwa, (xbc)
	ld wa, (xwa - 2)
	ld (xsp + 10), wa
	cpw (xsp + 10), 0x0
	jr ge, AudioCmd_StarPrecision_Applied
	resm 4, (xsp + 6)

AudioCmd_StarPrecision_Applied:
	ld xwa, (xsp + 82)
	ld_spib C, 0xE0
	ld (xsp + 82), xwa
	ldfr_berp C, 0xF8
	exts iz
	jr AudioCmd_CheckLengthH

AudioCmd_ParsePrecisionDigit:
	ld bc, iz
	sub bc, 0x30
	ld wa, (xsp + 10)
	muls wa, 0xA
	ld (xsp + 10), wa
	add (xsp + 10), bc
	ld xwa, (xsp + 82)
	ld_spib C, 0xE0
	ld (xsp + 82), xwa
	ldfr_berp C, 0xF8
	exts iz

AudioCmd_CheckPrecisionDigit:
	ldto_berp A, 0xF8
	extz wa
	lda_24 xbc, 0xeed778
	bit_dri 2, 0x07, 0xE4, 0xE0
	jr nz, AudioCmd_ParsePrecisionDigit

AudioCmd_CheckLengthH:
	cp iz, 0x68
	jr nz, AudioCmd_CheckLengthL
	setm 5, (xsp + 6)
	ld xwa, (xsp + 82)
	ld_spib C, 0xE0
	ld (xsp + 82), xwa
	ldfr_berp C, 0xF8
	exts iz
	jr AudioCmd_DispatchType

AudioCmd_CheckLengthL:
	cp iz, 0x6C
	jr nz, AudioCmd_CheckLengthLL
	setm 6, (xsp + 6)
	ld xwa, (xsp + 82)
	ld_spib C, 0xE0
	ld (xsp + 82), xwa
	ldfr_berp C, 0xF8
	exts iz
	jr AudioCmd_DispatchType

AudioCmd_CheckLengthLL:
	cp iz, 0x4C
	jr nz, AudioCmd_DispatchType
	setm 7, (xsp + 6)
	ld xwa, (xsp + 82)
	ld_spib C, 0xE0
	ld (xsp + 82), xwa
	ldfr_berp C, 0xF8
	exts iz

AudioCmd_DispatchType:
	ld wa, iz
	cp iz, 0x47
	jrl z, AudioCmd_FormatFloat_Entry
	cp wa, 0x45
	jrl z, AudioCmd_FormatFloat_Entry
	cp wa, 0x58
	jrl z, AudioCmd_Hex_GetArg
	cp wa, 0x25
	jr z, AudioCmd_Format_Percent
	sub wa, 0x63
	cps wa, 0
	jrl lt, AudioCmd_MainLoop_ReadNext
	cp wa, 0x15
	jrl gt, AudioCmd_MainLoop_ReadNext
	add wa, wa
	lda_24 xix, 0xeed878
	ld_sriw3 WA, 0x07, 0xF0, 0xE0
	lda_24 xix, 0xff1229
	jp_dri 8, 0x07, 0xF0, 0xE0

AudioCmd_Format_Percent:
	ld wa, (xsp + 6)
	bit 1, wa
	jr z, AudioCmd_Percent_PadLeftLoop
	jr AudioCmd_Format_CharOrPercent

AudioCmd_Percent_PadLeft:
	incm 1, (xsp + 4)
	push_sd24w 0x20, 0xC2, 0x03
	ld xwa, (xsp + 92)
	call (xwa)
	inc 2, xsp

AudioCmd_Percent_PadLeftLoop:
	decm 1, (xsp + 8)
	cpw (xsp + 8), 0x0
	jr gt, AudioCmd_Percent_PadLeft

AudioCmd_Format_CharOrPercent:
	incm 1, (xsp + 4)
	cp iz, 0x63
	jr nz, AudioCmd_Percent_LiteralPush
	ld xbc, (xsp + 86)
	lds32 xwa, 2
	add (xbc), xwa
	ld xwa, (xbc)
	pushm (xwa - 2)
	jr AudioCmd_Percent_OutputChar

AudioCmd_Percent_LiteralPush:
	pushw 0x25

AudioCmd_Percent_OutputChar:
	ld xwa, (xsp + 92)
	call (xwa)
	inc 2, xsp
	ld wa, (xsp + 6)
	bit 1, wa
	jr nz, AudioCmd_Percent_PadRightLoop
	jrl AudioCmd_MainLoop_ReadNext

AudioCmd_Percent_PadRight:
	incm 1, (xsp + 4)
	pushw 0x20
	ld xwa, (xsp + 92)
	call (xwa)
	inc 2, xsp

AudioCmd_Percent_PadRightLoop:
	decm 1, (xsp + 8)
	cpw (xsp + 8), 0x0
	jr gt, AudioCmd_Percent_PadRight
	jrl AudioCmd_MainLoop_ReadNext
	ld xbc, (xsp + 86)
	lds32 xwa, 4
	add (xbc), xwa
	ld xwa, (xbc)
	ld xwa, (xwa - 4)
	ld (xsp + 16), xwa
	push xwa
	call Strlen
	inc 4, xsp
	ld wa, (xsp + 6)
	bit 4, wa
	jr z, AudioCmd_String_UseStrLen
	cp (xsp + 10), hl
	jr lt, AudioCmd_String_UsePrecision

AudioCmd_String_UseStrLen:
	ld (xsp + 10), hl
	jr AudioCmd_String_ComputePadding

AudioCmd_String_UsePrecision:
	ld hl, (xsp + 10)

AudioCmd_String_ComputePadding:
	cp hl, (xsp + 8)
	jr le, AudioCmd_String_WidthAvailable
	ldw (xsp + 8), 0x0
	add (xsp + 4), hl
	jr AudioCmd_String_CheckLeftAlign

AudioCmd_String_WidthAvailable:
	ld wa, (xsp + 8)
	add (xsp + 4), wa
	sub (xsp + 8), hl

AudioCmd_String_CheckLeftAlign:
	ld wa, (xsp + 6)
	bit 1, wa
	jr z, AudioCmd_String_PadLeftLoop
	jr AudioCmd_String_OutputLoop

AudioCmd_String_PadLeftSpace:
	push_sd24w 0x20, 0xC2, 0x03
	ld xwa, (xsp + 92)
	call (xwa)
	inc 2, xsp

AudioCmd_String_PadLeftLoop:
	ld wa, (xsp + 8)
	decm 1, (xsp + 8)
	cps wa, 0
	jr nz, AudioCmd_String_PadLeftSpace
	jr AudioCmd_String_OutputLoop

AudioCmd_String_OutputChars:
	ld xwa, (xsp + 16)
	ld_spib C, 0xE0
	ld (xsp + 16), xwa
	exts bc
	pushw bc
	ld xwa, (xsp + 92)
	call (xwa)
	inc 2, xsp

AudioCmd_String_OutputLoop:
	ld wa, (xsp + 10)
	decm 1, (xsp + 10)
	cps wa, 0
	jr nz, AudioCmd_String_OutputChars
	ld wa, (xsp + 6)
	bit 1, wa
	jr nz, AudioCmd_String_PadRightLoop
	jrl AudioCmd_MainLoop_ReadNext

AudioCmd_String_PadRightSpace:
	pushw 0x20
	ld xwa, (xsp + 92)
	call (xwa)
	inc 2, xsp

AudioCmd_String_PadRightLoop:
	ld wa, (xsp + 8)
	decm 1, (xsp + 8)
	cps wa, 0
	jr nz, AudioCmd_String_PadRightSpace
	jrl AudioCmd_MainLoop_ReadNext
	ld wa, (xsp + 6)
	bit 6, wa
	jr z, AudioCmd_Decimal_GetShortArg
	ld xbc, (xsp + 86)
	lds32 xwa, 4
	add (xbc), xwa
	ld xwa, (xbc)
	ld xwa, (xwa - 4)
	ld (xsp + 16), xwa
	jr AudioCmd_Decimal_Setup

AudioCmd_Decimal_GetShortArg:
	ld xbc, (xsp + 86)
	lds32 xwa, 2
	add (xbc), xwa
	ld xwa, (xbc)
	ld wa, (xwa - 2)
	exts xwa
	ld (xsp + 16), xwa

AudioCmd_Decimal_Setup:
	ldw (xsp + 14), 0x0
	lda xbc, (xsp + 56)
	ld wa, (xsp + 6)
	bit 4, wa
	jr z, AudioCmd_Decimal_ConvertToString
	cpw (xsp + 10), 0x0
	jr nz, AudioCmd_Decimal_ConvertToString
	ld xwa, (xsp + 16)
	or xwa, xwa
	jr nz, AudioCmd_Decimal_ConvertToString
	ld (xbc), 0x0
	ldw (xsp + 12), 0x0
	jr AudioCmd_Decimal_CheckPrecision

AudioCmd_Decimal_ConvertToString:
	ld xwa, (xsp + 16)
	push xwa
	push xbc
	calr AudioCmd_IntToStr
	lda xwa, (xsp + 64)
	push xwa
	call Strlen
	lda xsp, (xsp + 12)
	ld (xsp + 12), hl
	ld xwa, (xsp + 16)
	cp xwa, 0x0
	jr ge, AudioCmd_Decimal_CheckPrecision
	ldw (xsp + 14), 0x1

AudioCmd_Decimal_CheckPrecision:
	ld wa, (xsp + 6)
	bit 4, wa
	jr z, AudioCmd_Decimal_NoPrecision
	ld wa, (xsp + 10)
	cp wa, (xsp + 12)
	jr ge, AudioCmd_Decimal_SubtractLength

AudioCmd_Decimal_NoPrecision:
	ldw (xsp + 10), 0x0
	jr AudioCmd_Decimal_CheckSign

AudioCmd_Decimal_SubtractLength:
	ld wa, (xsp + 12)
	sub (xsp + 10), wa

AudioCmd_Decimal_CheckSign:
	ld wa, (xsp + 6)
	and wa, 0x5
	jr z, AudioCmd_Decimal_ComputeWidth
	ldw (xsp + 14), 0x1

AudioCmd_Decimal_ComputeWidth:
	ld wa, (xsp + 12)
	add wa, (xsp + 10)
	add wa, (xsp + 14)
	sub (xsp + 8), wa
	jr ge, AudioCmd_Decimal_FinalWidth
	ldw (xsp + 8), 0x0

AudioCmd_Decimal_FinalWidth:
	ld wa, (xsp + 8)
	add wa, (xsp + 12)
	add wa, (xsp + 10)
	add wa, (xsp + 14)
	add (xsp + 4), wa
	cpw (xsp + 8), 0x0
	jr z, AudioCmd_Decimal_OutputSign
	ld wa, (xsp + 6)
	bit 1, wa
	jr nz, AudioCmd_Decimal_OutputSign
	cpdi16_24 246304, 32
	jr z, AudioCmd_Decimal_PadLeftLoop
	bit 4, wa
	jr nz, AudioCmd_Decimal_PadLeftLoop
	jr AudioCmd_Decimal_OutputSign

AudioCmd_Decimal_PadLeftSpace:
	pushw 0x20
	ld xwa, (xsp + 92)
	call (xwa)
	inc 2, xsp

AudioCmd_Decimal_PadLeftLoop:
	ld wa, (xsp + 8)
	decm 1, (xsp + 8)
	cps wa, 0
	jr nz, AudioCmd_Decimal_PadLeftSpace
	ldw (xsp + 8), 0x0

AudioCmd_Decimal_OutputSign:
	ld xwa, (xsp + 16)
	cp xwa, 0x0
	jr ge, AudioCmd_Decimal_PlusSign
	pushw 0x2D
	jr AudioCmd_Decimal_EmitSign

AudioCmd_Decimal_PlusSign:
	ld wa, (xsp + 6)
	bit 0, wa
	jr z, AudioCmd_Decimal_SpaceSign
	pushw 0x2B
	jr AudioCmd_Decimal_EmitSign

AudioCmd_Decimal_SpaceSign:
	ld wa, (xsp + 6)
	bit 2, wa
	jr z, AudioCmd_Decimal_ZeroFill
	pushw 0x20

AudioCmd_Decimal_EmitSign:
	ld xwa, (xsp + 92)
	call (xwa)
	inc 2, xsp

AudioCmd_Decimal_ZeroFill:
	ld wa, (xsp + 6)
	bit 1, wa
	jr nz, AudioCmd_Decimal_PrecZeroLoop
	cpdi16_24 246304, 48
	jr z, AudioCmd_Decimal_ZeroFillLoop
	jr AudioCmd_Decimal_PrecZeroLoop

AudioCmd_Decimal_ZeroFillBody:
	pushw 0x30
	ld xwa, (xsp + 92)
	call (xwa)
	inc 2, xsp

AudioCmd_Decimal_ZeroFillLoop:
	ld wa, (xsp + 8)
	decm 1, (xsp + 8)
	cps wa, 0
	jr nz, AudioCmd_Decimal_ZeroFillBody
	jr AudioCmd_Decimal_PrecZeroLoop

AudioCmd_Decimal_PrecZeroBody:
	pushw 0x30
	ld xwa, (xsp + 92)
	call (xwa)
	inc 2, xsp

AudioCmd_Decimal_PrecZeroLoop:
	ld wa, (xsp + 10)
	decm 1, (xsp + 10)
	cps wa, 0
	jr nz, AudioCmd_Decimal_PrecZeroBody
	jr AudioCmd_Decimal_DigitLoop

AudioCmd_Decimal_OutputDigits:
	decm 1, (xsp + 12)
	lda xbc, (xsp + 56)
	ld wa, (xsp + 12)
	ld_srib3 A, 0x07, 0xE4, 0xE0
	exts wa
	pushw wa
	ld xwa, (xsp + 92)
	call (xwa)
	inc 2, xsp

AudioCmd_Decimal_DigitLoop:
	cpw (xsp + 12), 0x0
	jr nz, AudioCmd_Decimal_OutputDigits
	ld wa, (xsp + 6)
	bit 1, wa
	jr nz, AudioCmd_Decimal_PadRightLoop
	jrl AudioCmd_MainLoop_ReadNext

AudioCmd_Decimal_PadRightSpace:
	pushw 0x20
	ld xwa, (xsp + 92)
	call (xwa)
	inc 2, xsp

AudioCmd_Decimal_PadRightLoop:
	ld wa, (xsp + 8)
	decm 1, (xsp + 8)
	cps wa, 0
	jr nz, AudioCmd_Decimal_PadRightSpace
	jrl AudioCmd_MainLoop_ReadNext
	ld wa, (xsp + 6)
	bit 6, wa
	jr z, AudioCmd_Unsigned_GetShortArg
	ld xbc, (xsp + 86)
	lds32 xwa, 4
	add (xbc), xwa
	ld xwa, (xbc)
	ld xde, (xwa - 4)
	jr AudioCmd_Unsigned_Setup

AudioCmd_Unsigned_GetShortArg:
	ld xbc, (xsp + 86)
	lds32 xwa, 2
	add (xbc), xwa
	ld xwa, (xbc)
	ld de, (xwa - 2)
	extz xde

AudioCmd_Unsigned_Setup:
	lda xbc, (xsp + 44)
	ld wa, (xsp + 6)
	bit 4, wa
	jr z, AudioCmd_Unsigned_ConvertToString
	cpw (xsp + 10), 0x0
	jr nz, AudioCmd_Unsigned_ConvertToString
	or xde, xde
	jr nz, AudioCmd_Unsigned_ConvertToString
	ld (xbc), 0x0
	lds iz, 0
	jr AudioCmd_Unsigned_CheckPrecision

AudioCmd_Unsigned_ConvertToString:
	push xde
	push xbc
	calr AudioCmd_UIntToStr
	lda xwa, (xsp + 52)
	push xwa
	call Strlen
	lda xsp, (xsp + 12)
	ld iz, hl

AudioCmd_Unsigned_CheckPrecision:
	ld wa, (xsp + 6)
	bit 4, wa
	jr z, AudioCmd_Unsigned_NoPrecision
	cp (xsp + 10), iz
	jr ge, AudioCmd_Unsigned_SubtractLength

AudioCmd_Unsigned_NoPrecision:
	ldw (xsp + 10), 0x0
	jr AudioCmd_Unsigned_ComputeWidth

AudioCmd_Unsigned_SubtractLength:
	sub (xsp + 10), iz

AudioCmd_Unsigned_ComputeWidth:
	ld wa, iz
	add wa, (xsp + 10)
	sub (xsp + 8), wa
	jr ge, AudioCmd_Unsigned_FinalWidth
	ldw (xsp + 8), 0x0

AudioCmd_Unsigned_FinalWidth:
	ld wa, (xsp + 8)
	add wa, iz
	add wa, (xsp + 10)
	add (xsp + 4), wa
	ld wa, (xsp + 6)
	bit 1, wa
	jr z, AudioCmd_Unsigned_PadLeftLoop
	jr AudioCmd_Unsigned_PrecZeroLoop

AudioCmd_Unsigned_PadLeftSpace:
	push_sd24w 0x20, 0xC2, 0x03
	ld xwa, (xsp + 92)
	call (xwa)
	inc 2, xsp

AudioCmd_Unsigned_PadLeftLoop:
	ld wa, (xsp + 8)
	decm 1, (xsp + 8)
	cps wa, 0
	jr nz, AudioCmd_Unsigned_PadLeftSpace
	jr AudioCmd_Unsigned_PrecZeroLoop

AudioCmd_Unsigned_PrecZeroBody:
	pushw 0x30
	ld xwa, (xsp + 92)
	call (xwa)
	inc 2, xsp

AudioCmd_Unsigned_PrecZeroLoop:
	ld wa, (xsp + 10)
	decm 1, (xsp + 10)
	cps wa, 0
	jr nz, AudioCmd_Unsigned_PrecZeroBody
	jr AudioCmd_Unsigned_DigitLoop

AudioCmd_Unsigned_OutputDigits:
	dec 1, iz
	lda xwa, (xsp + 44)
	ld_srib3 A, 0x07, 0xE0, 0xF8
	exts wa
	pushw wa
	ld xwa, (xsp + 92)
	call (xwa)
	inc 2, xsp

AudioCmd_Unsigned_DigitLoop:
	cps iz, 0
	jr nz, AudioCmd_Unsigned_OutputDigits
	ld wa, (xsp + 6)
	bit 1, wa
	jr nz, AudioCmd_Unsigned_PadRightLoop
	jrl AudioCmd_MainLoop_ReadNext

AudioCmd_Unsigned_PadRightSpace:
	pushw 0x20
	ld xwa, (xsp + 92)
	call (xwa)
	inc 2, xsp

AudioCmd_Unsigned_PadRightLoop:
	ld wa, (xsp + 8)
	decm 1, (xsp + 8)
	cps wa, 0
	jr nz, AudioCmd_Unsigned_PadRightSpace
	jrl AudioCmd_MainLoop_ReadNext
	setm 6, (xsp + 6)

AudioCmd_Hex_GetArg:
	ld wa, (xsp + 6)
	bit 6, wa
	jr z, AudioCmd_Hex_GetShortArg
	ld xbc, (xsp + 86)
	lds32 xwa, 4
	add (xbc), xwa
	ld xwa, (xbc)
	ld xde, (xwa - 4)
	jr AudioCmd_Hex_Setup

AudioCmd_Hex_GetShortArg:
	ld xbc, (xsp + 86)
	lds32 xwa, 2
	add (xbc), xwa
	ld xwa, (xbc)
	ld de, (xwa - 2)
	extz xde

AudioCmd_Hex_Setup:
	lda xbc, (xsp + 32)
	ld wa, (xsp + 6)
	bit 4, wa
	jr z, AudioCmd_Hex_ConvertToString
	cpw (xsp + 10), 0x0
	jr nz, AudioCmd_Hex_ConvertToString
	or xde, xde
	jr nz, AudioCmd_Hex_ConvertToString
	ld (xbc), 0x0
	ldw (xsp + 18), 0x0
	jr AudioCmd_Hex_CheckPrecision

AudioCmd_Hex_ConvertToString:
	pushw iz
	push xde
	push xbc
	calr AudioCmd_HexToStr
	lda xwa, (xsp + 42)
	push xwa
	call Strlen
	lda xsp, (xsp + 14)
	ld (xsp + 18), hl

AudioCmd_Hex_CheckPrecision:
	ld wa, (xsp + 6)
	bit 4, wa
	jr z, AudioCmd_Hex_NoPrecision
	ld wa, (xsp + 10)
	cp wa, (xsp + 18)
	jr ge, AudioCmd_Hex_SubtractLength

AudioCmd_Hex_NoPrecision:
	ldw (xsp + 10), 0x0
	jr AudioCmd_Hex_CheckAltForm

AudioCmd_Hex_SubtractLength:
	ld wa, (xsp + 18)
	sub (xsp + 10), wa

AudioCmd_Hex_CheckAltForm:
	ldi_werp 0xFA, 0
	ld wa, (xsp + 6)
	bit 3, wa
	jr z, AudioCmd_Hex_AltFormPrefix
	ldi_werp 0xFA, 2

AudioCmd_Hex_AltFormPrefix:
	ld wa, (xsp + 18)
	add wa, (xsp + 10)
	add_werp WA, 0xFA
	sub (xsp + 8), wa
	jr ge, AudioCmd_Hex_ComputeWidth
	ldw (xsp + 8), 0x0

AudioCmd_Hex_ComputeWidth:
	ld wa, (xsp + 8)
	add wa, (xsp + 18)
	add wa, (xsp + 10)
	add_werp WA, 0xFA
	add (xsp + 4), wa
	ld wa, (xsp + 6)
	bit 1, wa
	jr nz, AudioCmd_Hex_EmitPrefix
	cpdi16_24 246304, 32
	jr z, AudioCmd_Hex_PadLeftLoop
	jr AudioCmd_Hex_EmitPrefix

AudioCmd_Hex_PadLeftSpace:
	pushw 0x20
	ld xwa, (xsp + 92)
	call (xwa)
	inc 2, xsp

AudioCmd_Hex_PadLeftLoop:
	ld wa, (xsp + 8)
	decm 1, (xsp + 8)
	cps wa, 0
	jr nz, AudioCmd_Hex_PadLeftSpace

AudioCmd_Hex_EmitPrefix:
	cpi_werp 0xFA, 0
	jr z, AudioCmd_Hex_ZeroFill
	cpw (xsp + 18), 0x0
	jr z, AudioCmd_Hex_ZeroFill
	pushw 0x30
	ld xwa, (xsp + 92)
	call (xwa)
	pushw iz
	ld xwa, (xsp + 94)
	call (xwa)
	inc 4, xsp

AudioCmd_Hex_ZeroFill:
	ld wa, (xsp + 6)
	bit 1, wa
	jr nz, AudioCmd_Hex_PrecZeroLoop
	cpdi16_24 246304, 48
	jr z, AudioCmd_Hex_ZeroFillLoop
	jr AudioCmd_Hex_PrecZeroLoop

AudioCmd_Hex_ZeroFillBody:
	pushw 0x30
	ld xwa, (xsp + 92)
	call (xwa)
	inc 2, xsp

AudioCmd_Hex_ZeroFillLoop:
	ld wa, (xsp + 8)
	decm 1, (xsp + 8)
	cps wa, 0
	jr nz, AudioCmd_Hex_ZeroFillBody
	jr AudioCmd_Hex_PrecZeroLoop

AudioCmd_Hex_PrecZeroBody:
	pushw 0x30
	ld xwa, (xsp + 92)
	call (xwa)
	inc 2, xsp

AudioCmd_Hex_PrecZeroLoop:
	ld wa, (xsp + 10)
	decm 1, (xsp + 10)
	cps wa, 0
	jr nz, AudioCmd_Hex_PrecZeroBody
	jr AudioCmd_Hex_DigitLoop

AudioCmd_Hex_OutputDigits:
	decm 1, (xsp + 18)
	lda xbc, (xsp + 32)
	ld wa, (xsp + 18)
	ld_srib3 A, 0x07, 0xE4, 0xE0
	exts wa
	pushw wa
	ld xwa, (xsp + 92)
	call (xwa)
	inc 2, xsp

AudioCmd_Hex_DigitLoop:
	cpw (xsp + 18), 0x0
	jr nz, AudioCmd_Hex_OutputDigits
	ld wa, (xsp + 6)
	bit 1, wa
	jr nz, AudioCmd_Hex_PadRightLoop
	jrl AudioCmd_MainLoop_ReadNext

AudioCmd_Hex_PadRightSpace:
	pushw 0x20
	ld xwa, (xsp + 92)
	call (xwa)
	inc 2, xsp

AudioCmd_Hex_PadRightLoop:
	ld wa, (xsp + 8)
	decm 1, (xsp + 8)
	cps wa, 0
	jr nz, AudioCmd_Hex_PadRightSpace
	jrl AudioCmd_MainLoop_ReadNext
	ld wa, (xsp + 6)
	bit 6, wa
	jr z, AudioCmd_Octal_GetShortArg
	ld xbc, (xsp + 86)
	lds32 xwa, 4
	add (xbc), xwa
	ld xwa, (xbc)
	ld xde, (xwa - 4)
	jr AudioCmd_Octal_Setup

AudioCmd_Octal_GetShortArg:
	ld xbc, (xsp + 86)
	lds32 xwa, 2
	add (xbc), xwa
	ld xwa, (xbc)
	ld de, (xwa - 2)
	extz xde

AudioCmd_Octal_Setup:
	lda xbc, (xsp + 20)
	ld wa, (xsp + 6)
	bit 4, wa
	jr z, AudioCmd_Octal_ConvertToString
	cpw (xsp + 10), 0x0
	jr nz, AudioCmd_Octal_ConvertToString
	or xde, xde
	jr nz, AudioCmd_Octal_ConvertToString
	ld (xbc), 0x0
	lds iz, 0
	jr AudioCmd_Octal_CheckPrecision

AudioCmd_Octal_ConvertToString:
	push xde
	push xbc
	calr AudioCmd_OctalToStr
	lda xwa, (xsp + 28)
	push xwa
	call Strlen
	lda xsp, (xsp + 12)
	ld iz, hl

AudioCmd_Octal_CheckPrecision:
	ld wa, (xsp + 6)
	bit 4, wa
	jr z, AudioCmd_Octal_NoPrecision
	cp (xsp + 10), iz
	jr ge, AudioCmd_Octal_SubtractLength

AudioCmd_Octal_NoPrecision:
	ldw (xsp + 10), 0x0
	jr AudioCmd_Octal_CheckAltForm

AudioCmd_Octal_SubtractLength:
	sub (xsp + 10), iz

AudioCmd_Octal_CheckAltForm:
	ld wa, (xsp + 6)
	and wa, 0x8
	cps wa, 0
	scc16 nz, wa
	ld (xsp + 18), wa
	ld wa, iz
	add wa, (xsp + 10)
	add wa, (xsp + 18)
	sub (xsp + 8), wa
	jr ge, AudioCmd_Octal_ComputeWidth
	ldw (xsp + 8), 0x0

AudioCmd_Octal_ComputeWidth:
	ld wa, (xsp + 8)
	add wa, iz
	add wa, (xsp + 10)
	add wa, (xsp + 18)
	add (xsp + 4), wa
	ld wa, (xsp + 6)
	bit 1, wa
	jr nz, AudioCmd_Octal_EmitPrefix
	cpdi16_24 246304, 32
	jr z, AudioCmd_Octal_PadLeftLoop
	jr AudioCmd_Octal_EmitPrefix

AudioCmd_Octal_PadLeftSpace:
	pushw 0x20
	ld xwa, (xsp + 92)
	call (xwa)
	inc 2, xsp

AudioCmd_Octal_PadLeftLoop:
	ld wa, (xsp + 8)
	decm 1, (xsp + 8)
	cps wa, 0
	jr nz, AudioCmd_Octal_PadLeftSpace

AudioCmd_Octal_EmitPrefix:
	cpw (xsp + 18), 0x0
	jr z, AudioCmd_Octal_ZeroFill
	cps iz, 0
	jr z, AudioCmd_Octal_ZeroFill
	pushw 0x30
	ld xwa, (xsp + 92)
	call (xwa)
	inc 2, xsp

AudioCmd_Octal_ZeroFill:
	ld wa, (xsp + 6)
	bit 1, wa
	jr nz, AudioCmd_Octal_PrecZeroLoop
	cpdi16_24 246304, 48
	jr z, AudioCmd_Octal_ZeroFillLoop
	jr AudioCmd_Octal_PrecZeroLoop

AudioCmd_Octal_ZeroFillBody:
	pushw 0x30
	ld xwa, (xsp + 92)
	call (xwa)
	inc 2, xsp

AudioCmd_Octal_ZeroFillLoop:
	ld wa, (xsp + 8)
	decm 1, (xsp + 8)
	cps wa, 0
	jr nz, AudioCmd_Octal_ZeroFillBody
	jr AudioCmd_Octal_PrecZeroLoop

AudioCmd_Octal_PrecZeroBody:
	pushw 0x30
	ld xwa, (xsp + 92)
	call (xwa)
	inc 2, xsp

AudioCmd_Octal_PrecZeroLoop:
	ld wa, (xsp + 10)
	decm 1, (xsp + 10)
	cps wa, 0
	jr nz, AudioCmd_Octal_PrecZeroBody
	jr AudioCmd_Octal_DigitLoop

AudioCmd_Octal_OutputDigits:
	dec 1, iz
	lda xwa, (xsp + 20)
	ld_srib3 A, 0x07, 0xE0, 0xF8
	exts wa
	pushw wa
	ld xwa, (xsp + 92)
	call (xwa)
	inc 2, xsp

AudioCmd_Octal_DigitLoop:
	cps iz, 0
	jr nz, AudioCmd_Octal_OutputDigits
	ld wa, (xsp + 6)
	bit 1, wa
	jr nz, AudioCmd_Octal_PadRightLoop
	jrl AudioCmd_MainLoop_ReadNext

AudioCmd_Octal_PadRightSpace:
	pushw 0x20
	ld xwa, (xsp + 92)
	call (xwa)
	inc 2, xsp

AudioCmd_Octal_PadRightLoop:
	ld wa, (xsp + 8)
	decm 1, (xsp + 8)
	cps wa, 0
	jr nz, AudioCmd_Octal_PadRightSpace
	jr AudioCmd_MainLoop_ReadNext
	ld xbc, (xsp + 86)
	lds32 xwa, 4
	add (xbc), xwa
	ld xwa, (xbc)
	ld xbc, (xwa - 4)
	ld wa, (xsp + 6)
	bit 6, wa
	jr z, AudioCmd_StoreCount_Short
	ld wa, (xsp + 4)
	exts xwa
	ld (xbc), xwa
	jr AudioCmd_MainLoop_ReadNext

AudioCmd_StoreCount_Short:
	ld wa, (xsp + 4)
	ld (xbc), wa
	jr AudioCmd_MainLoop_ReadNext

AudioCmd_FormatFloat_Entry:
	lda xbc, (xsp + 68)
	ld wa, (xsp + 6)
	bit 7, wa
	jr z, AudioCmd_FormatFloat_ShortArg
	ld xwa, xbc
	ld xde, (xsp + 86)
	lda_dd8l XBC, 0x0A
	add (xde), xbc
	ld xbc, (xde)
	lda xbc, (xbc - 10)
	call AudioCmd_CopyBytes10
	jr AudioCmd_FormatFloat_Dispatch

AudioCmd_FormatFloat_ShortArg:
	ld xwa, xbc
	ld xde, (xsp + 86)
	lda_dd8l XBC, 0x08
	add (xde), xbc
	ld xbc, (xde)
	dec 8, xbc
	call AudioCmd_CopyBytes8

AudioCmd_FormatFloat_Dispatch:
	pushm (xsp + 10)
	pushm (xsp + 10)
	pushm (xsp + 10)
	lda xwa, (xsp + 74)
	push xwa
	ld xwa, (xsp + 100)
	push xwa
	ldto_berp A, 0xF8
	exts wa
	pushw wa
	calr AudioCmd_FormatFloat
	lda xsp, (xsp + 16)
	ld16_24 xwa, 0x03c222
	add (xsp + 4), wa

AudioCmd_MainLoop_ReadNext:
	ld xwa, (xsp + 82)
	ld_spib C, 0xE0
	ld (xsp + 82), xwa
	ldfr_berp C, 0xF8
	exts iz
	cps iz, 0
	jrl nz, AudioCmd_OutputLiteral
	ld hl, (xsp + 4)
	pop xiz
	lda xsp, (xsp + 74)
	ret

AudioCmd_IntToStr:
	dec 4, xsp
	push xiz
	ld xwa, (xsp + 16)
	cp xwa, 0x0
	jr ge, AudioCmd_IntToStr_Positive
	cpl wa
	cpl_werp 0xE2
	inc 1, xwa

AudioCmd_IntToStr_Positive:
	ld xiz, xwa

AudioCmd_IntToStr_DivLoop:
	ld xwa, (xsp + 12)
	st_dpib A, 0xE0
	ld (xsp + 4), xbc
	ld (xsp + 12), xwa
	ld xwa, xiz
	lda_dd8l XBC, 0x0A
	call DivMod32
	add xhl, 0x30
	ld xwa, (xsp + 4)
	ld (xwa), l
	ld xwa, xiz
	lda_dd8l XBC, 0x0A
	call Math_DivideU32
	ld xiz, xhl
	or xiz, xiz
	jr nz, AudioCmd_IntToStr_DivLoop
	ld xwa, (xsp + 12)
	ld (xwa), 0x0
	pop xiz
	inc 4, xsp
	ret

AudioCmd_UIntToStr:
	dec 4, xsp
	push xiz
	ld xiz, (xsp + 16)

AudioCmd_UIntToStr_DivLoop:
	ld xwa, (xsp + 12)
	st_dpib A, 0xE0
	ld (xsp + 4), xbc
	ld (xsp + 12), xwa
	ld xwa, xiz
	lda_dd8l XBC, 0x0A
	call DivMod32
	add xhl, 0x30
	ld xwa, (xsp + 4)
	ld (xwa), l
	ld xwa, xiz
	lda_dd8l XBC, 0x0A
	call Math_DivideU32
	ld xiz, xhl
	or xiz, xiz
	jr nz, AudioCmd_UIntToStr_DivLoop
	ld xwa, (xsp + 12)
	ld (xwa), 0x0
	pop xiz
	inc 4, xsp
	ret

AudioCmd_HexToStr:
	ld xwa, 0xEED8B6
	cpw (xsp + 12), 0x78
	jr nz, AudioCmd_HexToStr_TableSelected
	ld xwa, 0xEED8A4

AudioCmd_HexToStr_TableSelected:
	ld xix, xwa
	ld xhl, (xsp + 4)
	ld xde, (xsp + 8)

AudioCmd_HexToStr_Loop:
	st_dpib A, 0xEC
	ld xwa, xde
	and xwa, 0xF
	add xwa, xix
	ld a, (xwa)
	ld (xbc), a
	srl xde, 4
	jr nz, AudioCmd_HexToStr_Loop
	ld (xhl), 0x0
	ret

AudioCmd_OctalToStr:
	ld xde, (xsp + 8)
	ld xhl, (xsp + 4)

AudioCmd_OctalToStr_Loop:
	st_dpib A, 0xEC
	ld xwa, xde
	and xwa, 0x7
	add xwa, 0x30
	ld (xbc), a
	srl xde, 3
	jr nz, AudioCmd_OctalToStr_Loop
	ld (xhl), 0x0
	ret

AudioCmd_FormatFloat:
	lda xsp, (xsp - 26)
	push xiz
	ldw (xsp + 4), 0x0
	lda xwa, (xsp + 6)
	push xwa
	lda xwa, (xsp + 8)
	push xwa
	pushm (xsp + 52)
	lda xwa, (xsp + 18)
	push xwa
	ld xwa, (xsp + 54)
	push xwa
	call AudioCmd_FormatGGeneral
	lda xsp, (xsp + 18)
	sti16_24 0x03c222, 0x0000
	lda xde, (xsp + 8)
	ld xiy, xde
	ld c, (xsp + 34)
	ld xiz, (xsp + 36)
	ld ix, (xsp + 46)
	ld hl, (xsp + 48)
	ld a, c
	exts wa
	cp c, 0x65
	jr z, AudioCmd_FormatFloat_eE
	cp c, 0x45
	jr nz, AudioCmd_FormatFloat_fF_Check

AudioCmd_FormatFloat_eE:
	pushm (xsp + 6)
	pushm (xsp + 6)
	push xiy
	pushw hl
	pushw ix
	pushm (xsp + 56)
	push xiz
	pushw wa
	jr AudioCmd_FormatFloat_gG_UseSci

AudioCmd_FormatFloat_fF_Check:
	cp c, 0x66
	jr z, AudioCmd_FormatFloat_fF
	cp c, 0x46
	jr nz, AudioCmd_FormatFloat_gG

AudioCmd_FormatFloat_fF:
	pushm (xsp + 6)
	pushm (xsp + 6)
	push xiy
	pushw hl
	pushw ix
	pushm (xsp + 56)
	push xiz
	pushw wa

AudioCmd_FormatFloat_fF_Call:
	calr AudioCmd_FormatFFixed
	lda xsp, (xsp + 20)
	jr AudioCmd_FormatFloat_Return

AudioCmd_FormatFloat_gG:
	ld wa, (xsp + 44)
	bit 4, wa
	jr nz, AudioCmd_FormatFloat_gG_Setup
	lds hl, 6
	setm 4, (xsp + 44)

AudioCmd_FormatFloat_gG_Setup:
	exts bc
	pushm (xsp + 6)
	pushm (xsp + 6)
	push xde
	pushw hl
	pushw ix
	pushm (xsp + 56)
	push xiz
	pushw bc
	cpw (xsp + 24), 0xFFFC
	jr le, AudioCmd_FormatFloat_gG_UseSci
	cp (xsp + 24), hl
	jr le, AudioCmd_FormatFloat_fF_Call

AudioCmd_FormatFloat_gG_UseSci:
	calr AudioCmd_FormatEScientific
	lda xsp, (xsp + 20)

AudioCmd_FormatFloat_Return:
	pop xiz
	lda xsp, (xsp + 26)
	ret

AudioCmd_FormatFFixed:
	dec 4, xsp
	pushw iz
	ldw (xsp + 4), 0xF
	cpw (xsp + 26), 0x1
	jr ge, AudioCmd_FFixed_SetPrecision
	ldw (xsp + 2), 0x0
	jr AudioCmd_FFixed_CheckDefaults

AudioCmd_FFixed_SetPrecision:
	ld wa, (xsp + 26)
	ld (xsp + 2), wa

AudioCmd_FFixed_CheckDefaults:
	ld wa, (xsp + 16)
	bit 4, wa
	jr nz, AudioCmd_FFixed_CheckLongDouble
	ldw (xsp + 20), 0x6

AudioCmd_FFixed_CheckLongDouble:
	ld wa, (xsp + 16)
	bit 7, wa
	jr z, AudioCmd_FFixed_CheckLongDoubleLimit
	ldw (xsp + 4), 0x12

AudioCmd_FFixed_CheckLongDoubleLimit:
	ld c, (xsp + 10)
	ld a, c
	extz wa
	lda_24 xde, 0xeed778
	st_dri3b B, 0x07, 0xE8, 0xE0
	bitm 1, (xde)
	jr z, AudioCmd_FFixed_SpecNoUpperCase
	ld a, c
	sub a, 0x20
	jr AudioCmd_FFixed_CheckSpecG

AudioCmd_FFixed_SpecNoUpperCase:
	ld a, c

AudioCmd_FFixed_CheckSpecG:
	cp a, 0x47
	jr nz, AudioCmd_FFixed_NotG
	ld iz, (xsp + 20)
	jr AudioCmd_FFixed_RoundCheck

AudioCmd_FFixed_NotG:
	ld iz, (xsp + 20)
	add iz, (xsp + 26)

AudioCmd_FFixed_RoundCheck:
	ld wa, (xsp + 4)
	inc 1, wa
	cp iz, wa
	jr ge, AudioCmd_FFixed_AfterRound
	ld xwa, (xsp + 22)
	cp_srib_im 0x07, 0xE0, 0xF8, 0x34
	jr le, AudioCmd_FFixed_AfterRound
	cps iz, 0
	jr ge, AudioCmd_FFixed_RoundLoop
	jr AudioCmd_FFixed_AfterRound

AudioCmd_FFixed_RoundCarry:
	ld xwa, (xsp + 22)
	stib_dri 0x07, 0xE0, 0xF8, 0x30

AudioCmd_FFixed_RoundLoop:
	dec 1, iz
	ld xwa, (xsp + 22)
	inc_srib 1, 0x07, 0xE0, 0xF8
	cps iz, 0
	jr le, AudioCmd_FFixed_AfterRound
	cp_srib_im 0x07, 0xE0, 0xF8, 0x39
	jr gt, AudioCmd_FFixed_RoundCarry

AudioCmd_FFixed_AfterRound:
	ld e, (xde)
	bit 1, e
	jr z, AudioCmd_FFixed_AfterRound_NoCase
	ld a, c
	sub a, 0x20
	jr AudioCmd_FFixed_CheckG_StripZeros

AudioCmd_FFixed_AfterRound_NoCase:
	ld a, c

AudioCmd_FFixed_CheckG_StripZeros:
	cp a, 0x47
	jr nz, AudioCmd_FFixed_CheckG_AltForm
	ld iz, (xsp + 20)
	dec 1, iz
	ld wa, (xsp + 26)
	neg wa
	add (xsp + 20), wa

AudioCmd_FFixed_CheckG_AltForm:
	bit 1, e
	jr z, AudioCmd_FFixed_CaseApplied
	sub c, 0x20

AudioCmd_FFixed_CaseApplied:
	cp c, 0x47
	jr nz, AudioCmd_FFixed_ComputeOutputLen
	ld wa, (xsp + 16)
	bit 3, wa
	jr z, AudioCmd_FFixed_StripZeroCheck
	jr AudioCmd_FFixed_ComputeOutputLen

AudioCmd_FFixed_StripZeroLoop:
	dec 1, iz
	decm 1, (xsp + 20)

AudioCmd_FFixed_StripZeroCheck:
	ld xwa, (xsp + 22)
	cp_srib_im 0x07, 0xE0, 0xF8, 0x30
	jr z, AudioCmd_FFixed_StripZeroLoop

AudioCmd_FFixed_ComputeOutputLen:
	ld wa, (xsp + 16)
	bit 4, wa
	jr z, AudioCmd_FFixed_CheckPrecZero
	cpw (xsp + 20), 0x0
	jr z, AudioCmd_FFixed_AdjustForSign

AudioCmd_FFixed_CheckPrecZero:
	decm 1, (xsp + 18)

AudioCmd_FFixed_AdjustForSign:
	ld iz, (xsp + 28)
	cps iz, 0
	jr nz, AudioCmd_FFixed_AdjustForSign2
	ld wa, (xsp + 16)
	and wa, 0x5
	jr z, AudioCmd_FFixed_ComputePadding

AudioCmd_FFixed_AdjustForSign2:
	decm 1, (xsp + 18)

AudioCmd_FFixed_ComputePadding:
	ld wa, (xsp + 2)
	add wa, (xsp + 20)
	sub (xsp + 18), wa
	ld xwa, (xsp + 22)
	cp (xwa), 0x39
	jr le, AudioCmd_FFixed_CheckOverflow
	decm 1, (xsp + 18)

AudioCmd_FFixed_CheckOverflow:
	cpw (xsp + 18), 0x0
	jr ge, AudioCmd_FFixed_PadLeftCheck
	ldw (xsp + 18), 0x0

AudioCmd_FFixed_PadLeftCheck:
	ld wa, (xsp + 16)
	bit 1, wa
	jr nz, AudioCmd_FFixed_EmitSign
	cpdi16_24 246304, 32
	jr z, AudioCmd_FFixed_PadLeftLoop
	jr AudioCmd_FFixed_EmitSign

AudioCmd_FFixed_PadLeftSpace:
	pushw 0x20
	ld xwa, (xsp + 14)
	call (xwa)
	inc 2, xsp
	incdi16_24 1, 246306

AudioCmd_FFixed_PadLeftLoop:
	ld wa, (xsp + 18)
	decm 1, (xsp + 18)
	cps wa, 0
	jr gt, AudioCmd_FFixed_PadLeftSpace

AudioCmd_FFixed_EmitSign:
	cps iz, 0
	jr z, AudioCmd_FFixed_SignPlus
	pushw 0x2D
	jr AudioCmd_FFixed_SignEmit

AudioCmd_FFixed_SignPlus:
	ld wa, (xsp + 16)
	bit 0, wa
	jr z, AudioCmd_FFixed_SignSpace
	pushw 0x2B
	jr AudioCmd_FFixed_SignEmit

AudioCmd_FFixed_SignSpace:
	ld wa, (xsp + 16)
	bit 2, wa
	jr z, AudioCmd_FFixed_ZeroFill
	pushw 0x20

AudioCmd_FFixed_SignEmit:
	ld xwa, (xsp + 14)
	call (xwa)
	inc 2, xsp
	incdi16_24 1, 246306

AudioCmd_FFixed_ZeroFill:
	ld wa, (xsp + 16)
	bit 1, wa
	jr nz, AudioCmd_FFixed_LeadDigit
	cpdi16_24 246304, 48
	jr z, AudioCmd_FFixed_ZeroFillLoop
	jr AudioCmd_FFixed_LeadDigit

AudioCmd_FFixed_ZeroFillBody:
	pushw 0x30
	ld xwa, (xsp + 14)
	call (xwa)
	inc 2, xsp
	incdi16_24 1, 246306

AudioCmd_FFixed_ZeroFillLoop:
	ld wa, (xsp + 18)
	decm 1, (xsp + 18)
	cps wa, 0
	jr gt, AudioCmd_FFixed_ZeroFillBody

AudioCmd_FFixed_LeadDigit:
	ld xwa, (xsp + 22)
	cp (xwa), 0x39
	jr le, AudioCmd_FFixed_LeadDigitZero
	cpw (xsp + 26), 0x0
	jr lt, AudioCmd_FFixed_LeadDigitZero
	pushw 0x31
	ld xwa, (xsp + 14)
	call (xwa)
	inc 2, xsp
	ld xwa, (xsp + 22)
	ld (xwa), 0x30
	jr AudioCmd_FFixed_LeadDigitDone

AudioCmd_FFixed_LeadDigitZero:
	cpw (xsp + 26), 0x0
	jr gt, AudioCmd_FFixed_IntegerDigits
	pushw 0x30
	ld xwa, (xsp + 14)
	call (xwa)
	inc 2, xsp

AudioCmd_FFixed_LeadDigitDone:
	incdi16_24 1, 246306

AudioCmd_FFixed_IntegerDigits:
	lds iz, 0
	jr AudioCmd_FFixed_IntDigitLoop

AudioCmd_FFixed_IntDigitOutput:
	ld xwa, (xsp + 22)
	ld_srib3 A, 0x07, 0xE0, 0xF8
	exts wa
	pushw wa
	ld xwa, (xsp + 14)
	call (xwa)
	inc 2, xsp
	incdi16_24 1, 246306
	inc 1, iz

AudioCmd_FFixed_IntDigitLoop:
	ld wa, (xsp + 4)
	inc 1, wa
	cp iz, wa
	jr ge, AudioCmd_FFixed_IntZeroLoop
	ld wa, (xsp + 2)
	decm 1, (xsp + 2)
	cps wa, 0
	jr gt, AudioCmd_FFixed_IntDigitOutput
	jr AudioCmd_FFixed_IntZeroLoop

AudioCmd_FFixed_IntZeroFill:
	pushw 0x30
	ld xwa, (xsp + 14)
	call (xwa)
	inc 2, xsp
	incdi16_24 1, 246306

AudioCmd_FFixed_IntZeroLoop:
	ld wa, (xsp + 2)
	decm 1, (xsp + 2)
	cps wa, 0
	jr gt, AudioCmd_FFixed_IntZeroFill
	ld wa, (xsp + 16)
	bit 3, wa
	jr nz, AudioCmd_FFixed_DecimalPoint
	cpw (xsp + 20), 0x0
	jr z, AudioCmd_FFixed_FracLeadZeroLoop

AudioCmd_FFixed_DecimalPoint:
	pushw 0x2E
	ld xwa, (xsp + 14)
	call (xwa)
	inc 2, xsp
	incdi16_24 1, 246306
	jr AudioCmd_FFixed_FracLeadZeroLoop

AudioCmd_FFixed_FracLeadZeros:
	ld wa, (xsp + 26)
	add wa, 0x1
	jr nz, AudioCmd_FFixed_FracLeadZeroBody
	ld xwa, (xsp + 22)
	cp (xwa), 0x39
	jr le, AudioCmd_FFixed_FracLeadZeroBody
	pushw 0x31
	ld xwa, (xsp + 14)
	call (xwa)
	inc 2, xsp
	ld xwa, (xsp + 22)
	ld (xwa), 0x30
	jr AudioCmd_FFixed_FracLeadZeroDone

AudioCmd_FFixed_FracLeadZeroBody:
	pushw 0x30
	ld xwa, (xsp + 14)
	call (xwa)
	inc 2, xsp

AudioCmd_FFixed_FracLeadZeroDone:
	incdi16_24 1, 246306
	incm 1, (xsp + 26)

AudioCmd_FFixed_FracLeadZeroLoop:
	cpw (xsp + 26), 0x0
	jr ge, AudioCmd_FFixed_FracDigits
	ld wa, (xsp + 20)
	decm 1, (xsp + 20)
	cps wa, 0
	jr nz, AudioCmd_FFixed_FracLeadZeros

AudioCmd_FFixed_FracDigits:
	ld wa, (xsp + 4)
	inc 1, wa
	cp iz, wa
	jr lt, AudioCmd_FFixed_FracDigitLoop
	jr AudioCmd_FFixed_FracTrailLoop

AudioCmd_FFixed_FracDigitOutput:
	ld xwa, (xsp + 22)
	ld_srib3 A, 0x07, 0xE0, 0xF8
	exts wa
	pushw wa
	ld xwa, (xsp + 14)
	call (xwa)
	inc 2, xsp
	incdi16_24 1, 246306
	inc 1, iz

AudioCmd_FFixed_FracDigitLoop:
	ld wa, (xsp + 4)
	inc 1, wa
	cp iz, wa
	jr ge, AudioCmd_FFixed_FracTrailLoop
	ld wa, (xsp + 20)
	decm 1, (xsp + 20)
	cps wa, 0
	jr gt, AudioCmd_FFixed_FracDigitOutput
	jr AudioCmd_FFixed_FracTrailLoop

AudioCmd_FFixed_FracTrailZeros:
	pushw 0x30
	ld xwa, (xsp + 14)
	call (xwa)
	inc 2, xsp
	incdi16_24 1, 246306

AudioCmd_FFixed_FracTrailLoop:
	ld wa, (xsp + 20)
	decm 1, (xsp + 20)
	cps wa, 0
	jr gt, AudioCmd_FFixed_FracTrailZeros
	ld wa, (xsp + 16)
	bit 1, wa
	jr nz, AudioCmd_FFixed_PadRightLoop
	jr AudioCmd_FFixed_Return

AudioCmd_FFixed_PadRightSpace:
	pushw 0x20
	ld xwa, (xsp + 14)
	call (xwa)
	inc 2, xsp
	incdi16_24 1, 246306

AudioCmd_FFixed_PadRightLoop:
	ld wa, (xsp + 18)
	decm 1, (xsp + 18)
	cps wa, 0
	jr gt, AudioCmd_FFixed_PadRightSpace

AudioCmd_FFixed_Return:
	popw iz
	inc 4, xsp
	ret

AudioCmd_FFixed_DataTable:
	.byte 0xaf, 0x04, 0x20, 0x80, 0x3f, 0x00, 0x6e, 0x03
	.byte 0xdb, 0xa9, 0x0e, 0xc5, 0xe0, 0x3f, 0x30, 0x66
	.byte 0xf2, 0xdb, 0xa8, 0x0e

AudioCmd_FormatEScientific:
	dec 2, xsp
	push xiz
	ldw (xsp + 4), 0xF
	ld wa, (xsp + 16)
	bit 4, wa
	jr nz, AudioCmd_ESci_ApplyDefaults
	ldw (xsp + 20), 0x6

AudioCmd_ESci_ApplyDefaults:
	ld a, (xsp + 10)
	extz wa
	lda_24 xbc, 0xeed778
	st_dri3b A, 0x07, 0xE4, 0xE0
	bitm 1, (xbc)
	jr z, AudioCmd_ESci_SpecNoUpperCase
	ld a, (xsp + 10)
	sub a, 0x20
	jr AudioCmd_ESci_CheckSpecG

AudioCmd_ESci_SpecNoUpperCase:
	ld a, (xsp + 10)

AudioCmd_ESci_CheckSpecG:
	cp a, 0x47
	jr nz, AudioCmd_ESci_SetDigitCount
	cpw (xsp + 20), 0x0
	jr z, AudioCmd_ESci_SetDigitCount
	decm 1, (xsp + 20)

AudioCmd_ESci_SetDigitCount:
	ld wa, (xsp + 20)
	inc 1, wa
	ldfr_werp WA, 0xFA
	ld wa, (xsp + 16)
	bit 7, wa
	jr z, AudioCmd_ESci_RoundCheck
	ldw (xsp + 4), 0x12

AudioCmd_ESci_RoundCheck:
	ld de, (xsp + 4)
	inc 1, de
	ldto_werp WA, 0xFA
	cp wa, de
	jr ge, AudioCmd_ESci_AfterRound
	ldto_werp DE, 0xFA
	dec1_werp 0xFA
	ld xwa, (xsp + 22)
	cp_srib_im 0x07, 0xE0, 0xE8, 0x34
	jr gt, AudioCmd_ESci_RoundLoop
	jr AudioCmd_ESci_AfterRound

AudioCmd_ESci_RoundCarry:
	ld xwa, (xsp + 22)
	stib_dri 0x07, 0xE0, 0xFA, 0x30
	dec1_werp 0xFA

AudioCmd_ESci_RoundLoop:
	ld xwa, (xsp + 22)
	inc_srib 1, 0x07, 0xE0, 0xFA
	cpi_werp 0xFA, 0
	jr le, AudioCmd_ESci_AfterRound
	cp_srib_im 0x07, 0xE0, 0xFA, 0x39
	jr gt, AudioCmd_ESci_RoundCarry

AudioCmd_ESci_AfterRound:
	bitm 1, (xbc)
	jr z, AudioCmd_ESci_AfterRound_NoCase
	ld a, (xsp + 10)
	sub a, 0x20
	jr AudioCmd_ESci_StripTrailZeros

AudioCmd_ESci_AfterRound_NoCase:
	ld a, (xsp + 10)

AudioCmd_ESci_StripTrailZeros:
	cp a, 0x47
	jr nz, AudioCmd_ESci_ComputeOutputLen
	ld wa, (xsp + 16)
	bit 3, wa
	jr nz, AudioCmd_ESci_ComputeOutputLen
	ld wa, (xsp + 20)
	ldfr_werp WA, 0xFA
	jr AudioCmd_ESci_StripCheck

AudioCmd_ESci_StripLoop:
	dec1_werp 0xFA
	decm 1, (xsp + 20)

AudioCmd_ESci_StripCheck:
	cpi_werp 0xFA, 0
	jr le, AudioCmd_ESci_ComputeOutputLen
	ld xwa, (xsp + 22)
	cp_srib_im 0x07, 0xE0, 0xFA, 0x30
	jr z, AudioCmd_ESci_StripLoop

AudioCmd_ESci_ComputeOutputLen:
	decm 5, (xsp + 18)
	ld wa, (xsp + 16)
	bit 4, wa
	jr z, AudioCmd_ESci_CheckPrecZero
	cpw (xsp + 20), 0x0
	jr z, AudioCmd_ESci_AdjustForSign

AudioCmd_ESci_CheckPrecZero:
	decm 1, (xsp + 18)

AudioCmd_ESci_AdjustForSign:
	ld iz, (xsp + 28)
	cps iz, 0
	jr nz, AudioCmd_ESci_AdjustForSign2
	ld wa, (xsp + 16)
	and wa, 0x5
	jr z, AudioCmd_ESci_ComputePadding

AudioCmd_ESci_AdjustForSign2:
	decm 1, (xsp + 18)

AudioCmd_ESci_ComputePadding:
	ld wa, (xsp + 20)
	sub (xsp + 18), wa
	jr ge, AudioCmd_ESci_PadLeftCheck
	ldw (xsp + 18), 0x0

AudioCmd_ESci_PadLeftCheck:
	ld wa, (xsp + 16)
	bit 1, wa
	jr nz, AudioCmd_ESci_EmitSign
	cpdi16_24 246304, 32
	jr z, AudioCmd_ESci_PadLeftLoop
	jr AudioCmd_ESci_EmitSign

AudioCmd_ESci_PadLeftSpace:
	pushw 0x20
	ld xwa, (xsp + 14)
	call (xwa)
	inc 2, xsp
	incdi16_24 1, 246306

AudioCmd_ESci_PadLeftLoop:
	decm 1, (xsp + 18)
	cpw (xsp + 18), 0x0
	jr gt, AudioCmd_ESci_PadLeftSpace

AudioCmd_ESci_EmitSign:
	cps iz, 0
	jr z, AudioCmd_ESci_SignPlus
	pushw 0x2D
	jr AudioCmd_ESci_SignEmit

AudioCmd_ESci_SignPlus:
	ld wa, (xsp + 16)
	bit 0, wa
	jr z, AudioCmd_ESci_SignSpace
	pushw 0x2B
	jr AudioCmd_ESci_SignEmit

AudioCmd_ESci_SignSpace:
	ld wa, (xsp + 16)
	bit 2, wa
	jr z, AudioCmd_ESci_ZeroFill
	pushw 0x20

AudioCmd_ESci_SignEmit:
	ld xwa, (xsp + 14)
	call (xwa)
	inc 2, xsp
	incdi16_24 1, 246306

AudioCmd_ESci_ZeroFill:
	ld wa, (xsp + 16)
	bit 1, wa
	jr nz, AudioCmd_ESci_LeadDigit
	cpdi16_24 246304, 48
	jr z, AudioCmd_ESci_ZeroFillLoop
	jr AudioCmd_ESci_LeadDigit

AudioCmd_ESci_ZeroFillBody:
	pushw 0x30
	ld xwa, (xsp + 14)
	call (xwa)
	inc 2, xsp
	incdi16_24 1, 246306

AudioCmd_ESci_ZeroFillLoop:
	decm 1, (xsp + 18)
	cpw (xsp + 18), 0x0
	jr gt, AudioCmd_ESci_ZeroFillBody

AudioCmd_ESci_LeadDigit:
	ld xwa, (xsp + 22)
	cp (xwa), 0x39
	jr le, AudioCmd_ESci_LeadDigitNormal
	pushw 0x31
	ld xwa, (xsp + 14)
	call (xwa)
	inc 2, xsp
	ld xwa, (xsp + 22)
	ld (xwa), 0x30
	ldi_werp 0xFA, 0
	incdi16_24 1, 246306
	cpw (xsp + 26), 0x0
	jr ge, AudioCmd_ESci_Overflow_DecExp
	incm 1, (xsp + 26)
	jr AudioCmd_ESci_DecimalPoint

AudioCmd_ESci_Overflow_DecExp:
	decm 1, (xsp + 26)
	jr AudioCmd_ESci_DecimalPoint

AudioCmd_ESci_LeadDigitNormal:
	ld xwa, (xsp + 22)
	ld a, (xwa)
	exts wa
	pushw wa
	ld xwa, (xsp + 14)
	call (xwa)
	inc 2, xsp
	incdi16_24 1, 246306
	ldi_werp 0xFA, 1

AudioCmd_ESci_DecimalPoint:
	cpw (xsp + 20), 0x0
	jr nz, AudioCmd_ESci_DecimalPointEmit
	ld wa, (xsp + 16)
	bit 3, wa
	jr z, AudioCmd_ESci_MantissaDigits

AudioCmd_ESci_DecimalPointEmit:
	pushw 0x2E
	ld xwa, (xsp + 14)
	call (xwa)
	inc 2, xsp
	incdi16_24 1, 246306

AudioCmd_ESci_MantissaDigits:
	ld c, (xsp + 10)
	extz bc
	lda_24 xwa, 0xeed778
	bit_dri 1, 0x07, 0xE0, 0xE4
	jr z, AudioCmd_ESci_MantissaNoCase
	ld a, (xsp + 10)
	sub a, 0x20
	jr AudioCmd_ESci_CheckGTrim

AudioCmd_ESci_MantissaNoCase:
	ld a, (xsp + 10)

AudioCmd_ESci_CheckGTrim:
	cp a, 0x47
	jr nz, AudioCmd_ESci_OutputMantissa
	cpw (xsp + 20), 0x0
	jr nz, AudioCmd_ESci_OutputMantissa
	cpw (xsp + 26), 0x1
	jrl z, AudioCmd_ESci_Return

AudioCmd_ESci_OutputMantissa:
	ld bc, (xsp + 4)
	inc 1, bc
	ldto_werp WA, 0xFA
	cp wa, bc
	jr lt, AudioCmd_ESci_MantDigitLoop
	jr AudioCmd_ESci_MantTrailLoop

AudioCmd_ESci_MantDigitOutput:
	ld xwa, (xsp + 22)
	ld_srib3 A, 0x07, 0xE0, 0xFA
	exts wa
	pushw wa
	ld xwa, (xsp + 14)
	call (xwa)
	inc 2, xsp
	incdi16_24 1, 246306
	inc1_werp 0xFA

AudioCmd_ESci_MantDigitLoop:
	ld bc, (xsp + 4)
	inc 1, bc
	ldto_werp WA, 0xFA
	cp wa, bc
	jr ge, AudioCmd_ESci_MantTrailLoop
	ld wa, (xsp + 20)
	decm 1, (xsp + 20)
	cps wa, 0
	jr gt, AudioCmd_ESci_MantDigitOutput
	jr AudioCmd_ESci_MantTrailLoop

AudioCmd_ESci_MantTrailZeros:
	pushw 0x30
	ld xwa, (xsp + 14)
	call (xwa)
	inc 2, xsp
	incdi16_24 1, 246306

AudioCmd_ESci_MantTrailLoop:
	ld wa, (xsp + 20)
	decm 1, (xsp + 20)
	cps wa, 0
	jr gt, AudioCmd_ESci_MantTrailZeros
	decm 1, (xsp + 26)
	ld wa, (xsp + 26)
	exts xwa
	push xwa
	ld xwa, (xsp + 26)
	push xwa
	calr AudioCmd_IntToStr
	ld xwa, (xsp + 30)
	push xwa
	call Strlen
	lda xsp, (xsp + 12)
	ld iz, hl
	ld c, (xsp + 10)
	extz bc
	lda_24 xwa, 0xeed778
	bit_dri 1, 0x07, 0xE0, 0xE4
	jr z, AudioCmd_ESci_ExpNoCase
	ld a, (xsp + 10)
	sub a, 0x20
	jr AudioCmd_ESci_CheckExpG

AudioCmd_ESci_ExpNoCase:
	ld a, (xsp + 10)

AudioCmd_ESci_CheckExpG:
	cp a, 0x47
	jr nz, AudioCmd_ESci_ExpLetterNormal
	ld a, (xsp + 10)
	dec 2, a
	jr AudioCmd_ESci_EmitExpLetter

AudioCmd_ESci_ExpLetterNormal:
	ld a, (xsp + 10)

AudioCmd_ESci_EmitExpLetter:
	exts wa
	pushw wa
	ld xwa, (xsp + 14)
	call (xwa)
	inc 2, xsp
	incdi16_24 1, 246306
	cpw (xsp + 26), 0x0
	jr ge, AudioCmd_ESci_ExpSignPositive
	pushw 0x2D
	jr AudioCmd_ESci_EmitExpSign

AudioCmd_ESci_ExpSignPositive:
	pushw 0x2B

AudioCmd_ESci_EmitExpSign:
	ld xwa, (xsp + 14)
	call (xwa)
	inc 2, xsp
	incdi16_24 1, 246306
	ldfr_werp IZ, 0xFA
	jr AudioCmd_ESci_ExpLeadZeroLoop

AudioCmd_ESci_ExpLeadZeros:
	pushw 0x30
	ld xwa, (xsp + 14)
	call (xwa)
	inc 2, xsp
	incdi16_24 1, 246306

AudioCmd_ESci_ExpLeadZeroLoop:
	ldto_werp WA, 0xFA
	inc1_werp 0xFA
	cps wa, 3
	jr lt, AudioCmd_ESci_ExpLeadZeros
	jr AudioCmd_ESci_ExpDigitLoop

AudioCmd_ESci_ExpDigitOutput:
	dec 1, iz
	ld xwa, (xsp + 22)
	ld_srib3 A, 0x07, 0xE0, 0xF8
	exts wa
	pushw wa
	ld xwa, (xsp + 14)
	call (xwa)
	inc 2, xsp
	incdi16_24 1, 246306

AudioCmd_ESci_ExpDigitLoop:
	cps iz, 0
	jr nz, AudioCmd_ESci_ExpDigitOutput
	ld wa, (xsp + 16)
	bit 1, wa
	jr nz, AudioCmd_ESci_PadRightLoop
	jr AudioCmd_ESci_Return

AudioCmd_ESci_PadRightSpace:
	pushw 0x20
	ld xwa, (xsp + 14)
	call (xwa)
	inc 2, xsp
	incdi16_24 1, 246306

AudioCmd_ESci_PadRightLoop:
	decm 1, (xsp + 18)
	cpw (xsp + 18), 0x0
	jr gt, AudioCmd_ESci_PadRightSpace

AudioCmd_ESci_Return:
	pop xiz
	inc 2, xsp
	ret

AudioCmd_FormatGGeneral:
	lda xsp, (xsp - 16)
	push xiz
	lds iz, 0
	ldw (xsp + 6), 0xF
	ldw (xsp + 8), 0x8
	pushw 0x20
	pushw 0x0
	pushw 0x3
	pushw 0xC224
	call Memset
	inc 8, xsp
	ldi_werp 0xFA, 0

AudioCmd_GGen_ClearArrays:
	ldto_werp BC, 0xFA
	add bc, bc
	lda_24 xde, 0x03c284
	lda_24 xwa, 0x03c244
	stiw_dri 0x07, 0xE0, 0xE4, 0x00, 0x00
	stiw_dri 0x07, 0xE8, 0xE4, 0x00, 0x00
	inc1_werp 0xFA
	cp_erpw 0xFA, 0x20, 0x00
	jr lt, AudioCmd_GGen_ClearArrays
	ld wa, (xsp + 32)
	bit 7, wa
	jr z, AudioCmd_GGen_CheckLongDouble
	ldw (xsp + 6), 0x12
	ldw (xsp + 8), 0xA

AudioCmd_GGen_CheckLongDouble:
	ldi_werp 0xFA, 0
	cpw (xsp + 8), 0x0
	jr le, AudioCmd_GGen_CheckSign

AudioCmd_GGen_LoadDigits:
	lda xwa, (xsp + 10)
	ld bc, (xsp + 8)
	dec 1, bc
	sub_werp BC, 0xFA
	extz xbc
	add xbc, (xsp + 24)
	ld c, (xbc)
	lda_dri3 XHL, 0x07, 0xE0, 0xFA
	inc1_werp 0xFA
	ldto_werp WA, 0xFA
	cp wa, (xsp + 8)
	jr lt, AudioCmd_GGen_LoadDigits

AudioCmd_GGen_CheckSign:
	lda xde, (xsp + 10)
	bitm 7, (xde)
	jr z, AudioCmd_GGen_Negative
	lds wa, 1
	jr AudioCmd_GGen_ExtractExponent

AudioCmd_GGen_Negative:
	lds wa, 0

AudioCmd_GGen_ExtractExponent:
	ld xbc, (xsp + 38)
	ld (xbc), wa
	lda xbc, (xde + 1)
	ld wa, (xsp + 32)
	bit 7, wa
	jr z, AudioCmd_GGen_NormalExp
	cp (xde), 0x0
	jr nz, AudioCmd_GGen_LongDoubleExp
	cp (xbc), 0x0
	jr z, AudioCmd_GGen_NormalExp

AudioCmd_GGen_LongDoubleExp:
	ld l, (xbc)
	extz hl
	ldw wa, 0x8
	ldw bc, 0x4000
	jr AudioCmd_GGen_ComputeDecExp

AudioCmd_GGen_NormalExp:
	cp (xde), 0x0
	jr nz, AudioCmd_GGen_NonZero
	cp (xbc), 0x0
	jr z, AudioCmd_GGen_DecimalExponent

AudioCmd_GGen_NonZero:
	ld l, (xbc)
	and l, 0xF0
	extz hl
	sra hl, 4
	lds wa, 4
	ldw bc, 0x400

AudioCmd_GGen_ComputeDecExp:
	ld e, (xde)
	res 7, e
	extz de
	and a, 0xF
	jr z, AudioCmd_GGen_ShiftMantissa
	slaa de

AudioCmd_GGen_ShiftMantissa:
	ld iz, de
	add iz, hl
	sub iz, bc

AudioCmd_GGen_DecimalExponent:
	pushw iz
	calr AudioCmd_DecimalExponent
	inc 2, xsp
	ld (xsp + 4), hl
	cps iz, 0
	jr ge, AudioCmd_GGen_AdjustNegExp
	decm 1, (xsp + 4)

AudioCmd_GGen_AdjustNegExp:
	ld wa, (xsp + 32)
	bit 7, wa
	jr z, AudioCmd_GGen_NormalDigits
	ldi_werp 0xFA, 2

AudioCmd_GGen_LongDoubleDigits:
	lda xwa, (xsp + 10)
	ld_srib3 A, 0x07, 0xE0, 0xFA
	and a, 0xFF
	ldto_werp DE, 0xFA
	add de, de
	lda_24 xbc, 0x03c240
	extz wa
	st_dri3w WA, 0x07, 0xE4, 0xE8
	inc1_werp 0xFA
	cp_erpw 0xFA, 0x0A, 0x00
	jr lt, AudioCmd_GGen_LongDoubleDigits
	jr AudioCmd_GGen_NormalizeArray

AudioCmd_GGen_NormalDigits:
	lds ix, 0
	ldi_werp 0xFA, 0

AudioCmd_GGen_FindLeadDigit:
	lda xbc, (xsp + 10)
	cp_srib_im 0x07, 0xE4, 0xFA, 0x00
	jr z, AudioCmd_GGen_FindLeadDone
	lds ix, 1
	jr AudioCmd_GGen_LoadDigitPairs

AudioCmd_GGen_FindLeadDone:
	inc1_werp 0xFA
	cp_erpw 0xFA, 0x08, 0x00
	jr lt, AudioCmd_GGen_FindLeadDigit

AudioCmd_GGen_LoadDigitPairs:
	andmi8 (xbc + 1), 0xF
	ldi_werp 0xFA, 1

AudioCmd_GGen_DigitPairLoop:
	ld_srib3 A, 0x07, 0xE4, 0xFA
	and a, 0xFF
	ldto_werp HL, 0xFA
	add hl, hl
	dec 2, hl
	lda_24 xde, 0x03c244
	extz wa
	st_dri3w WA, 0x07, 0xE8, 0xEC
	inc1_werp 0xFA
	cp_erpw 0xFA, 0x08, 0x00
	jr lt, AudioCmd_GGen_DigitPairLoop
	cps ix, 0
	jr z, AudioCmd_GGen_NormalizeArray
	ormi16 (xde), 0x10

AudioCmd_GGen_NormalizeArray:
	pushm (xsp + 8)
	pushw 0x3
	pushw 0xC244
	calr AudioCmd_CountLeadingZeros
	inc 6, xsp
	ldi_werp 0xFA, 0
	cps iz, 0
	jr le, AudioCmd_GGen_NegativeExpCheck
	cpw (xsp + 4), 0x0
	jr le, AudioCmd_GGen_PositiveExpDone

AudioCmd_GGen_MultiplyLoop:
	pushw 0x3
	pushw 0xC244
	calr AudioCmd_DivideDigitsByTen
	pushm (xsp + 12)
	pushw 0x3
	pushw 0xC244
	calr AudioCmd_CountLeadingZeros
	lda xsp, (xsp + 10)
	sub iz, hl
	inc1_werp 0xFA
	ldto_werp WA, 0xFA
	cp wa, (xsp + 4)
	jr lt, AudioCmd_GGen_MultiplyLoop

AudioCmd_GGen_PositiveExpDone:
	pushm (xsp + 6)
	lds wa, 6
	sub wa, iz
	pushw wa
	pushw 0x3
	pushw 0xC244
	jr AudioCmd_GGen_FinalShift

AudioCmd_GGen_DivideLoop:
	push xbc
	calr AudioCmd_MultiplyDigitsByTen
	pushm (xsp + 12)
	pushw 0x3
	pushw 0xC244
	calr AudioCmd_CountTrailingZeros
	lda xsp, (xsp + 10)
	add iz, hl
	inc1_werp 0xFA

AudioCmd_GGen_NegativeExpCheck:
	ld de, (xsp + 4)
	neg de
	lda_24 xbc, 0x03c244
	ldto_werp WA, 0xFA
	cp wa, de
	jr lt, AudioCmd_GGen_DivideLoop
	pushm (xsp + 6)
	lds wa, 6
	sub wa, iz
	pushw wa
	push xbc

AudioCmd_GGen_FinalShift:
	calr AudioCmd_ShiftDigitArray
	inc 8, xsp
	ldi_werp 0xFA, 1

AudioCmd_GGen_RoundLoop:
	push_werp 0xFA
	ldto_werp BC, 0xFA
	add bc, bc
	lda_24 xwa, 0x03c244
	push_sriw 0x07, 0xE0, 0xE4
	calr AudioCmd_NormalizeDigits
	inc 4, xsp
	inc1_werp 0xFA
	cp_erpw 0xFA, 0x09, 0x00
	jr lt, AudioCmd_GGen_RoundLoop
	lds de, 0
	lda_24 xbc, 0x03c244
	ld xhl, (xsp + 28)
	ld wa, (xbc)
	cp wa, 0x9
	jr ule, AudioCmd_GGen_ExtractResult
	lds de, 1
	extz xwa
	div wa, 0xA
	ld (xhl), a
	incm 1, (xsp + 4)

AudioCmd_GGen_ExtractResult:
	ld ix, de
	inc 1, de
	ld wa, (xbc)
	extz xwa
	div wa, 0xA
	ldto_werp WA, 0xE2
	lda_dri3 XBC, 0x07, 0xEC, 0xF0
	incm 1, (xsp + 4)
	ldi_werp 0xFA, 1
	jr AudioCmd_GGen_CopyLoop

AudioCmd_GGen_CopyDigits:
	ld bc, de
	inc 1, de
	lda_24 xwa, 0x03c224
	ld_srib3 A, 0x07, 0xE0, 0xFA
	lda_dri3 XBC, 0x07, 0xEC, 0xE4
	inc1_werp 0xFA

AudioCmd_GGen_CopyLoop:
	ld bc, (xsp + 6)
	inc 2, bc
	ldto_werp WA, 0xFA
	cp wa, bc
	jr lt, AudioCmd_GGen_CopyDigits
	ld de, (xsp + 6)
	inc 1, de
	st_dri3b A, 0x07, 0xEC, 0xE8
	cp (xbc), 0x5
	jr c, AudioCmd_GGen_HandleCarry
	ld wa, (xsp + 6)
	inc_srib 1, 0x07, 0xEC, 0xE0

AudioCmd_GGen_HandleCarry:
	ld (xbc), 0x0
	ld wa, (xsp + 6)
	ldfr_werp WA, 0xFA
	jr AudioCmd_GGen_CarryCheck

AudioCmd_GGen_CarryLoop:
	ldto_werp BC, 0xFA
	dec 1, bc
	inc_srib 1, 0x07, 0xEC, 0xE4
	ld (xwa), 0x0
	dec1_werp 0xFA

AudioCmd_GGen_CarryCheck:
	cpi_werp 0xFA, 0
	jr z, AudioCmd_GGen_ConvertToAscii
	st_dri3b W, 0x07, 0xEC, 0xFA
	cp (xwa), 0x9
	jr ugt, AudioCmd_GGen_CarryLoop

AudioCmd_GGen_ConvertToAscii:
	ldi_werp 0xFA, 0
	jr AudioCmd_GGen_AsciiDone

AudioCmd_GGen_AsciiLoop:
	or_srib_im 0x07, 0xEC, 0xFA, 0x30
	inc1_werp 0xFA

AudioCmd_GGen_AsciiDone:
	ldto_werp WA, 0xFA
	cp wa, de
	jr lt, AudioCmd_GGen_AsciiLoop
	ld xbc, (xsp + 34)
	ld wa, (xsp + 4)
	ld (xbc), wa
	pop xiz
	lda xsp, (xsp + 16)
	ret

AudioCmd_ShiftDigitArray:
	dec 8, xsp
	pushw iz
	lds iz, 0
	lds wa, 0
	ld hl, (xsp + 18)
	cps hl, 0
	jr le, AudioCmd_Shift_SetupLoop

AudioCmd_Shift_BuildMask:
	add wa, wa
	set 0, wa
	inc 1, iz
	cp iz, hl
	jr lt, AudioCmd_Shift_BuildMask

AudioCmd_Shift_SetupLoop:
	ld iz, (xsp + 20)
	dec 1, iz
	ld xiy, (xsp + 14)
	cps iz, 0
	jr le, AudioCmd_Shift_LastEntry
	ld (xsp + 4), wa
	ldw (xsp + 2), 0x8
	sub (xsp + 2), hl
	ld wa, iz
	exts xwa
	add xwa, xwa
	ld xix, xwa

AudioCmd_Shift_Loop:
	ld (xsp + 6), xix
	add (xsp + 6), xiy
	ld xbc, (xsp + 6)
	ld de, (xbc)
	ld wa, hl
	and a, 0xF
	jr z, AudioCmd_Shift_ApplyShift
	srla de

AudioCmd_Shift_ApplyShift:
	ld (xbc), de
	ld xbc, xix
	lds32 xwa, 2
	sub xbc, xwa
	add xbc, xiy
	ld wa, (xsp + 4)
	and wa, (xbc)
	ld bc, wa
	ld wa, (xsp + 2)
	and a, 0xF
	jr z, AudioCmd_Shift_ApplyCarry
	slla bc

AudioCmd_Shift_ApplyCarry:
	ld xwa, (xsp + 6)
	or (xwa), bc
	dec 1, iz
	dec 2, xix
	cps iz, 0
	jr gt, AudioCmd_Shift_Loop

AudioCmd_Shift_LastEntry:
	ld bc, (xiy)
	ld wa, hl
	and a, 0xF
	jr z, AudioCmd_Shift_LastShift
	srla bc

AudioCmd_Shift_LastShift:
	ld (xiy), bc
	popw iz
	inc 8, xsp
	ret

AudioCmd_PropagateCarry:
	ld xiy, (xsp + 4)
	andmi16 (xiy), 0xFF
	lds ix, 1
	ld hl, (xsp + 8)
	add hl, hl
	jr AudioCmd_PropCarry_Check

AudioCmd_PropCarry_Loop:
	ld de, ix
	exts xde
	add xde, xde
	add xde, xiy
	ld wa, (xsp + 10)
	ld bc, (xde)
	and a, 0xF
	jr z, AudioCmd_PropCarry_Store
	slla bc

AudioCmd_PropCarry_Store:
	ld (xde), bc
	ld wa, ix
	dec 1, wa
	exts xwa
	add xwa, xwa
	ld xbc, xwa
	add xbc, xiy
	ld wa, (xde)
	srl wa, 8
	add (xbc), wa
	andmi16 (xde), 0xFF
	inc 1, ix

AudioCmd_PropCarry_Check:
	cp ix, hl
	jr lt, AudioCmd_PropCarry_Loop
	ret

AudioCmd_NormalizeDigits:
	pushw iz
	lda_24 xde, 0x03c284
	ld xwa, xde
	lda xbc, (xde + 18)

AudioCmd_Normalize_ClearLoop:
	stiw_dpi 0xE1, 0x00, 0x00
	cp xwa, xbc
	jr c, AudioCmd_Normalize_ClearLoop
	ld wa, (xsp + 6)
	ld (xde + 16), wa
	lds iz, 0

AudioCmd_Normalize_MainLoop:
	lda_24 xwa, 0x03c284
	cpw (xwa), 0x0
	jr nz, AudioCmd_Normalize_ExtractDigit
	cpw (xwa + 2), 0x0
	jr nz, AudioCmd_Normalize_ExtractDigit
	cpw (xwa + 4), 0x0
	jr nz, AudioCmd_Normalize_ExtractDigit
	cpw (xwa + 6), 0x0
	jr nz, AudioCmd_Normalize_ExtractDigit
	cpw (xwa + 8), 0x0
	jr nz, AudioCmd_Normalize_ExtractDigit
	cpw (xwa + 10), 0x0
	jr nz, AudioCmd_Normalize_ExtractDigit
	cpw (xwa + 12), 0x0
	jr nz, AudioCmd_Normalize_ExtractDigit
	cpw (xwa + 14), 0x0
	jr nz, AudioCmd_Normalize_ExtractDigit
	cpw (xwa + 16), 0x0
	jr nz, AudioCmd_Normalize_ExtractDigit
	jr AudioCmd_Normalize_Done

AudioCmd_Normalize_MultiplyTen:
	inc 1, iz
	calr AudioCmd_MultiplyBCDByTen

AudioCmd_Normalize_ExtractDigit:
	ldw wa, 0x8
	sub wa, (xsp + 8)
	add wa, wa
	lda_24 xbc, 0x03c284
	ld_sriw3 WA, 0x07, 0xE4, 0xE0
	cps wa, 0
	jr z, AudioCmd_Normalize_MultiplyTen
	pushw iz
	pushw wa
	calr AudioCmd_InsertCarry
	inc 4, xsp
	ldw bc, 0x8
	sub bc, (xsp + 8)
	add bc, bc
	lda_24 xwa, 0x03c284
	stiw_dri 0x07, 0xE0, 0xE4, 0x00, 0x00
	cp iz, 0x20
	jrl le, AudioCmd_Normalize_MainLoop

AudioCmd_Normalize_Done:
	popw iz
	ret

AudioCmd_InsertCarry:
	ld de, (xsp + 6)
	cp de, 0x20
	jr ge, AudioCmd_InsertCarry_Clamp
	lda_24 xbc, 0x03c224
	ld wa, (xsp + 4)
	add_srib_mr A, 0x07, 0xE4, 0xE8

AudioCmd_InsertCarry_Clamp:
	jr AudioCmd_InsertCarry_Check

AudioCmd_InsertCarry_ClampLoop:
	dec 1, de

AudioCmd_InsertCarry_Check:
	cp de, 0x20
	jr ge, AudioCmd_InsertCarry_ClampLoop
	lda_24 xwa, 0x03c224
	jr AudioCmd_InsertCarry_PropCheck

AudioCmd_InsertCarry_Propagate:
	ld bc, de
	dec 1, bc
	inc_srib 1, 0x07, 0xE0, 0xE4
	ld bc, de
	dec 1, de
	sub_srib_im 0x07, 0xE0, 0xE4, 0x0A

AudioCmd_InsertCarry_PropCheck:
	cp_srib_im 0x07, 0xE0, 0xE8, 0x0A
	ret lt
	cps de, 0
	jr gt, AudioCmd_InsertCarry_Propagate
	ret

AudioCmd_DivideDigitsByTen:
	ld xwa, (xsp + 4)
	ld xbc, xwa
	lda xde, (xwa + 18)

AudioCmd_DivByTen_Loop:
	ld wa, (xbc)
	extz xwa
	div wa, 0xA
	ldto_werp WA, 0xE2
	sll wa, 8
	add (xbc + 2), wa
	ld wa, (xbc)
	extz xwa
	div wa, 0xA
	st_dpiw WA, 0xE5
	cp xbc, xde
	jr c, AudioCmd_DivByTen_Loop
	ret

AudioCmd_MultiplyDigitsByTen:
	pushw iz
	lds ix, 0
	lds32 xbc, 0

AudioCmd_MulByTen_Loop:
	ld xhl, (xsp + 6)
	ld xde, xbc
	add xde, xhl
	ld wa, (xde)
	mul wa, 0xA
	ld (xde), wa
	cps ix, 0
	jr z, AudioCmd_MulByTen_Next
	ld iz, ix
	jr AudioCmd_MulByTen_CarryCheck

AudioCmd_MulByTen_CarryLoop:
	ld iy, iz
	dec 1, iy
	exts xiy
	add xiy, xiy
	add xiy, xhl
	srl wa, 8
	add (xiy), wa
	andmi16 (xde), 0xFF
	dec 1, iz

AudioCmd_MulByTen_CarryCheck:
	cps iz, 0
	jr le, AudioCmd_MulByTen_Next
	ld de, iz
	exts xde
	add xde, xde
	add xde, xhl
	ld wa, (xde)
	cp wa, 0xFF
	jr ugt, AudioCmd_MulByTen_CarryLoop

AudioCmd_MulByTen_Next:
	inc 1, ix
	inc 2, xbc
	cp ix, 0x10
	jr lt, AudioCmd_MulByTen_Loop
	lda xbc, (xhl + 30)
	ld wa, (xbc)
	bit 7, wa
	jr z, AudioCmd_MulByTen_HandleOverflow
	incm 1, (xhl + 28)

AudioCmd_MulByTen_HandleOverflow:
	ldw (xbc), 0x0
	popw iz
	ret

AudioCmd_MultiplyBCDByTen:
	lda_24 xhl, 0x03c284
	ld xbc, xhl
	lda xde, (xhl + 20)

AudioCmd_BCDMul_Loop:
	cpw (xbc), 0x0
	jr z, AudioCmd_BCDMul_Skip
	ld wa, (xbc)
	mul wa, 0xA
	ld (xbc), wa

AudioCmd_BCDMul_Skip:
	inc 2, xbc
	cp xbc, xde
	jr c, AudioCmd_BCDMul_Loop
	lda xbc, (xhl + 18)
	ldw de, 0x12

AudioCmd_BCDMul_CarryLoop:
	ld wa, (xbc)
	cp wa, 0x100
	jr c, AudioCmd_BCDMul_Next
	ld ix, de
	dec 2, ix
	srl wa, 8
	add_sriw_mr WA, 0x07, 0xEC, 0xF0
	andmi16 (xbc), 0xFF

AudioCmd_BCDMul_Next:
	dec 2, de
	dec 2, xbc
	cps de, 0
	jr gt, AudioCmd_BCDMul_CarryLoop
	ret

AudioCmd_CountLeadingZeros:
	dec 2, xsp
	pushw iz
	lds iz, 0
	cpw (xsp + 12), 0x0
	jr le, AudioCmd_LeadZero_CheckAllZero

AudioCmd_LeadZero_Loop:
	ld wa, iz
	exts xwa
	add xwa, xwa
	add xwa, (xsp + 8)
	cpw (xwa), 0x0
	jr nz, AudioCmd_LeadZero_CheckAllZero
	inc 1, iz
	cp iz, (xsp + 12)
	jr lt, AudioCmd_LeadZero_Loop

AudioCmd_LeadZero_CheckAllZero:
	cp iz, (xsp + 12)
	jr nz, AudioCmd_LeadZero_CountBits
	lds hl, 0
	jr AudioCmd_LeadZero_Return

AudioCmd_LeadZero_CountBits:
	ldw (xsp + 2), 0x0
	jr AudioCmd_LeadZero_OuterLoop

AudioCmd_LeadZero_ShiftLoop:
	lds iz, 0
	ld xbc, (xsp + 8)
	jr AudioCmd_LeadZero_CheckBit7

AudioCmd_LeadZero_ShiftBody:
	ld xwa, (xsp + 8)
	mriw2 0x90, 0x7E
	inc 1, iz

AudioCmd_LeadZero_CheckBit7:
	ld wa, (xbc)
	bit 7, wa
	jr nz, AudioCmd_LeadZero_ApplyShift
	cp iz, 0x8
	jr lt, AudioCmd_LeadZero_ShiftBody

AudioCmd_LeadZero_ApplyShift:
	cps iz, 0
	jr z, AudioCmd_LeadZero_AccumShift
	pushw iz
	pushm (xsp + 14)
	ld xwa, (xsp + 12)
	push xwa
	calr AudioCmd_PropagateCarry
	inc 8, xsp

AudioCmd_LeadZero_AccumShift:
	add (xsp + 2), iz

AudioCmd_LeadZero_OuterLoop:
	ld xwa, (xsp + 8)
	ld wa, (xwa)
	bit 7, wa
	jr z, AudioCmd_LeadZero_ShiftLoop
	ld hl, (xsp + 2)

AudioCmd_LeadZero_Return:
	popw iz
	inc 2, xsp
	ret

AudioCmd_CountTrailingZeros:
	pushw iz
	ld xde, (xsp + 6)
	lds iz, 0
	ld bc, (xsp + 10)
	cps bc, 0
	jr le, AudioCmd_TrailZero_CheckAllZero

AudioCmd_TrailZero_Loop:
	ld wa, iz
	exts xwa
	add xwa, xwa
	add xwa, xde
	cpw (xwa), 0x0
	jr nz, AudioCmd_TrailZero_CheckAllZero
	inc 1, iz
	cp iz, bc
	jr lt, AudioCmd_TrailZero_Loop

AudioCmd_TrailZero_CheckAllZero:
	cp iz, bc
	jr nz, AudioCmd_TrailZero_CountBits
	lds hl, 0
	jr AudioCmd_TrailZero_Return

AudioCmd_TrailZero_CountBits:
	ld hl, (xde)
	lds iz, 0
	jr AudioCmd_TrailZero_CheckHigh

AudioCmd_TrailZero_ShiftLoop:
	srl hl, 1
	inc 1, iz

AudioCmd_TrailZero_CheckHigh:
	ld wa, hl
	and wa, 0xFF00
	jr z, AudioCmd_TrailZero_ApplyShift
	cp iz, 0x8
	jr lt, AudioCmd_TrailZero_ShiftLoop

AudioCmd_TrailZero_ApplyShift:
	cps iz, 0
	jr z, AudioCmd_TrailZero_Done
	pushw bc
	pushw iz
	push xde
	calr AudioCmd_ShiftDigitArray
	inc 8, xsp

AudioCmd_TrailZero_Done:
	ld hl, iz

AudioCmd_TrailZero_Return:
	popw iz
	ret

AudioCmd_DecimalExponent:
	dec 8, xsp
	push xiz
	ld wa, (xsp + 16)
	exts xwa
	ldada xbc, 301
	call Math_MultiplyAccumulate
	ld xiz, xhl
	cp xiz, 0x0
	jr ge, AudioCmd_DecExp_Positive
	ld xwa, xiz
	cpl wa
	cpl_werp 0xE2
	inc 1, xwa
	ld (xsp + 4), xwa
	jr AudioCmd_DecExp_ComputeQuotient

AudioCmd_DecExp_Positive:
	ld (xsp + 4), xiz

AudioCmd_DecExp_ComputeQuotient:
	ld xiz, (xsp + 4)
	ld xwa, xiz
	ldada xbc, 1000
	call Free_ClearByte2
	ld (xsp + 8), xhl
	ld xwa, xiz
	ldada xbc, 1000
	call Math_DivideSigned32
	ld xiz, xhl
	ld xwa, (xsp + 8)
	cp xwa, 0x3D4
	jr le, AudioCmd_DecExp_CheckRemainder
	inc 1, xiz
	jr AudioCmd_DecExp_ApplySign

AudioCmd_DecExp_CheckRemainder:
	ld xwa, (xsp + 4)
	or xwa, xwa
	jr z, AudioCmd_DecExp_ApplySign
	ld xwa, (xsp + 8)
	cp xwa, 0x14
	jr ge, AudioCmd_DecExp_ApplySign
	dec 1, xiz

AudioCmd_DecExp_ApplySign:
	cpw (xsp + 16), 0x0
	jr ge, AudioCmd_DecExp_Positive_Return
	ld xwa, xiz
	cpl wa
	cpl_werp 0xE2
	inc 1, xwa
	ld xhl, xwa
	jr AudioCmd_DecExp_Return

AudioCmd_DecExp_Positive_Return:
	ld xhl, xiz

AudioCmd_DecExp_Return:
	pop xiz
	inc 8, xsp
	ret

AudioCmd_CopyBytes8:
	ld xix, (xbc)
	ld xiy, (xbc + 4)
	ld (xwa), xix
	ld (xwa + 4), xiy
	ret

AudioCmd_ItoaBaseN:
	lda xsp, (xsp - 46)
	push xiz
	cpw (xsp + 62), 0x2
	jr lt, AudioCmd_ItoaBaseN_Invalid
	cpw (xsp + 62), 0x24
	jr le, AudioCmd_ItoaBaseN_Setup

AudioCmd_ItoaBaseN_Invalid:
	ld xwa, (xsp + 58)
	ld (xwa), 0x0
	jr AudioCmd_ItoaBaseN_Return

AudioCmd_ItoaBaseN_Setup:
	lda xwa, (xsp + 16)
	ld (xsp + 8), xwa
	ld (xwa + 32), 0x0
	ld xwa, (xsp + 8)
	lda xwa, (xwa + 31)
	ld (xsp + 4), xwa
	ld xiz, (xsp + 54)

AudioCmd_ItoaBaseN_DivLoop:
	ld wa, (xsp + 62)
	exts xwa
	ld (xsp + 12), xwa
	ld xwa, xiz
	ld xbc, (xsp + 12)
	call DivMod32
	add l, 0x30
	ld xwa, (xsp + 4)
	ld (xwa), l
	cp (xwa), 0x39
	jr le, AudioCmd_ItoaBaseN_StoreDigit
	addmi8 (xwa), 0x27

AudioCmd_ItoaBaseN_StoreDigit:
	ld xwa, xiz
	ld xbc, (xsp + 12)
	call Math_DivideU32
	ld xiz, xhl
	or xiz, xiz
	jr z, AudioCmd_ItoaBaseN_Reverse
	lds32 xwa, 1
	sub (xsp + 4), xwa
	jr AudioCmd_ItoaBaseN_DivLoop

AudioCmd_ItoaBaseN_Reverse:
	ld xwa, (xsp + 8)
	lda xwa, (xwa + 33)
	sub xwa, (xsp + 4)
	push xwa
	ld xwa, (xsp + 8)
	push xwa
	ld xwa, (xsp + 66)
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 12)

AudioCmd_ItoaBaseN_Return:
	ld xhl, (xsp + 58)
	pop xiz
	lda xsp, (xsp + 46)
	ret

AudioCmd_ItoaBaseN_Pad:
	swi	7

AudioCmd_CopyBytes10:
	ld xix, (xbc)
	ld xiy, (xbc + 4)
	ld hl, (xbc + 8)
	ld (xwa), xix
	ld (xwa + 4), xiy
	ld (xwa + 8), hl
	ret

AudioCmd_StringNSearch:
	dec 4, xsp
	pushw iz
	ld iz, (xsp + 20)
	pushw iz
	pushm (xsp + 20)
	ld xwa, (xsp + 18)
	push xwa
	call AudioCmd_MemChr
	inc 8, xsp
	ld (xsp + 2), xhl
	ld xwa, (xsp + 2)
	or xwa, xwa
	jr nz, AudioCmd_StringNSearch_Found
	pushw iz
	jr AudioCmd_StringNSearch_Copy

AudioCmd_StringNSearch_Found:
	ld xwa, (xsp + 2)
	sub xwa, (xsp + 14)
	inc 1, xwa
	pushw wa

AudioCmd_StringNSearch_Copy:
	ld xwa, (xsp + 16)
	push xwa
	ld xwa, (xsp + 16)
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 10)
	ld xhl, (xsp + 2)
	popw iz
	inc 4, xsp
	ret

AudioCmd_MemChr:
	lds32 xhl, 0
	ld bc, (xsp + 10)
	cps bc, 0
	ret z
	ld xhl, (xsp + 4)
	ld wa, (xsp + 8)
	cpir83	; <-- aqui é o endereço FF28E2
	dec 1, xhl
	ret z
	lds32 xhl, 0
	ret

AudioCmd_DataBlock_28E9:
	.byte 0x9f, 0x0a, 0x22, 0xaf, 0x04, 0x24, 0xec, 0x8b
	.byte 0x68, 0x08, 0xf5, 0xf0, 0x31, 0x9f, 0x08, 0x20
	.byte 0xb1, 0x41, 0xda, 0x88, 0xda, 0x69, 0xd8, 0xd8
	.byte 0xb0, 0xf6, 0x84, 0x3f, 0x00, 0x6e, 0xeb, 0x0e

AudioCmd_StringLength:
	push xiz
	ld xiz, (xsp + 8)
	push xiz
	call Strlen
	inc 4, xsp
	inc 1, hl
	ld bc, hl
	st_dri3b C, 0x07, 0xF8, 0xE4
	cps bc, 0
	jr z, AudioCmd_StrLen_NotFound
	ld wa, (xsp + 12)

AudioCmd_StrLen_ScanLoop:
	cp_spdb A, 0xEC
	jr z, AudioCmd_StrLen_Return
	djnz xbc, AudioCmd_StrLen_ScanLoop

AudioCmd_StrLen_NotFound:
	lds32 xhl, 0

AudioCmd_StrLen_Return:
	pop xiz
	ret

AudioCmd_FillToEnd:
	.fill 41912, 1, 0xff
AudioCmd_FillToVectors:
	.fill 12710, 1, 0xff
