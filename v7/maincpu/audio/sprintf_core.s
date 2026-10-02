; NOTE: Renamed from audio_cmd_encoder.s. Original Matsushita labels were
; Audio_CommandEncoder / AudioCmd_*. These are actually sprintf() implementation
; routines, not audio command encoders.
; =============================================================================
; Sprintf_Core -- Printf-like audio command byte formatter
; =============================================================================
; Parses format string with % specifiers to build multi-byte command packets.
; Stack frame: 74 bytes. Called exclusively by Sprintf_Locked.

Sprintf_Core:
	lda	xsp, (xsp - 74)
	push	xiz
	ldw	(xsp + 4), 0x0
	jrl	Sprintf_MainLoop_ReadNext
Sprintf_OutputLiteral:
	cp	iz, 0x25
	jr	z, Sprintf_ParseFormatSpec
	pushw	iz
	ld	xwa, (xsp + 92)
	call	(xwa)
	inc	2, xsp
	incw	1, (xsp + 4)
	jrl	Sprintf_MainLoop_ReadNext
Sprintf_ParseFormatSpec:
	ldw	(xsp + 8), 0x0
	ldw	(xsp + 10), 0x0
	ldw	(xsp + 6), 0x0
	ldw	(0x03c220:24), 0x0020
Sprintf_ReadFormatChar:
	ld	xwa, (xsp + 82)
	ld	C, (xwa+)
	ld	(xsp + 82), xwa
	ldfr_berp	C, 0xf8
	exts	iz
	ld	wa, iz
	cp	iz, 0x30
	jr	z, Sprintf_Flag_Zero
	cp	wa, 0x2d
	jr	z, Sprintf_Flag_Minus
	cp	wa, 0x2b
	jr	z, Sprintf_Flag_Plus
	cp	wa, 0x23
	jr	z, Sprintf_Flag_Hash
	cp	wa, 0x20
	jr	z, Sprintf_Flag_Space
	cp	iz, 0x2a
	jr	nz, Sprintf_CheckIfDigit
	ld	xbc, (xsp + 86)
	ld	xwa, 2:i3
	add	(xbc), xwa
	ld	xwa, (xbc)
	ld	wa, (xwa - 2)
	ld	(xsp + 8), wa
	cpw	(xsp + 8), 0x0
	jr	ge, Sprintf_StarWidth_Positive
	ld	wa, (xsp + 8)
	neg	wa
	ld	(xsp + 8), wa
	setm	1, (xsp + 6)
Sprintf_StarWidth_Positive:
	ld	xwa, (xsp + 82)
	ld	C, (xwa+)
	ld	(xsp + 82), xwa
	ldfr_berp	C, 0xf8
	exts	iz
	jr	Sprintf_CheckPrecisionDot
Sprintf_Flag_Space:
	setm	2, (xsp + 6)
	jr	Sprintf_ReadFormatChar
Sprintf_Flag_Hash:
	setm	3, (xsp + 6)
	jr	Sprintf_ReadFormatChar
Sprintf_Flag_Plus:
	setm	0, (xsp + 6)
	jr	Sprintf_ReadFormatChar
Sprintf_Flag_Minus:
	setm	1, (xsp + 6)
	jr	Sprintf_ReadFormatChar
Sprintf_Flag_Zero:
	ldw	(0x03c220:24), 0x0030
	jrl	Sprintf_ReadFormatChar
Sprintf_ParseWidthDigit:
	ld	bc, iz
	sub	bc, 0x30
	ld	wa, (xsp + 8)
	.set	Strncpy, . + 3	; no instruction starts here: the name points 3 byte(s) into the one below
	muls	wa, 10
	; Strncpy is kept at this address only for ui_widgets/naka_widget_descriptors.c; v10's Strncpy is the code at 0xFF0516
	ld	(xsp + 8), wa
	add	(xsp + 8), bc
	ld	xwa, (xsp + 82)
	ld	C, (xwa+)
	ld	(xsp + 82), xwa
	ldfr_berp	C, 0xf8
	exts	iz
Sprintf_CheckIfDigit:
	ldto_berp	A, 0xf8
	extz	wa
	lda	xbc, (CType_ClassTable:24)
	bit	2, (xbc+wa)
	jr	nz, Sprintf_ParseWidthDigit
Sprintf_CheckPrecisionDot:
	cp	iz, 0x2e
	jr	nz, Sprintf_CheckLengthH
	setm	4, (xsp + 6)
	ld	xwa, (xsp + 82)
	ld	C, (xwa+)
	ld	(xsp + 82), xwa
	ldfr_berp	C, 0xf8
	exts	iz
	cp	iz, 0x2a
	jr	nz, Sprintf_CheckPrecisionDigit
	ld	xbc, (xsp + 86)
	ld	xwa, 2:i3
	add	(xbc), xwa
	ld	xwa, (xbc)
	ld	wa, (xwa - 2)
	ld	(xsp + 10), wa
	cpw	(xsp + 10), 0x0
	jr	ge, Sprintf_StarPrecision_Applied
	resm	4, (xsp + 6)
Sprintf_StarPrecision_Applied:
	ld	xwa, (xsp + 82)
	ld	C, (xwa+)
	ld	(xsp + 82), xwa
	ldfr_berp	C, 0xf8
	exts	iz
	jr	Sprintf_CheckLengthH
Sprintf_ParsePrecisionDigit:
	ld	bc, iz
	sub	bc, 0x30
	ld	wa, (xsp + 10)
	muls	wa, 0xa
	ld	(xsp + 10), wa
	add	(xsp + 10), bc
	ld	xwa, (xsp + 82)
	ld	C, (xwa+)
	ld	(xsp + 82), xwa
	ldfr_berp	C, 0xf8
	exts	iz
Sprintf_CheckPrecisionDigit:
	ldto_berp	A, 0xf8
	extz	wa
	lda	xbc, (CType_ClassTable:24)
	bit	2, (xbc+wa)
	jr	nz, Sprintf_ParsePrecisionDigit
Sprintf_CheckLengthH:
	cp	iz, 0x68
	jr	nz, Sprintf_CheckLengthL
	setm	5, (xsp + 6)
	ld	xwa, (xsp + 82)
	ld	C, (xwa+)
	ld	(xsp + 82), xwa
	ldfr_berp	C, 0xf8
	exts	iz
	jr	Sprintf_DispatchType
Sprintf_CheckLengthL:
	cp	iz, 0x6c
	jr	nz, Sprintf_CheckLengthLL
	setm	6, (xsp + 6)
	ld	xwa, (xsp + 82)
	ld	C, (xwa+)
	ld	(xsp + 82), xwa
	ldfr_berp	C, 0xf8
	exts	iz
	jr	Sprintf_DispatchType
Sprintf_CheckLengthLL:
	cp	iz, 0x4c
	jr	nz, Sprintf_DispatchType
	setm	7, (xsp + 6)
	ld	xwa, (xsp + 82)
	ld	C, (xwa+)
	ld	(xsp + 82), xwa
	ldfr_berp	C, 0xf8
	exts	iz
Sprintf_DispatchType:
	ld	wa, iz
	cp	iz, 0x47
	jrl	z, Sprintf_FormatFloat_Entry
	cp	wa, 0x45
	jrl	z, Sprintf_FormatFloat_Entry
	cp	wa, 0x58
	jrl	z, Sprintf_Hex_GetArg
	cp	wa, 0x25
	jr	z, Sprintf_Format_Percent
	sub	wa, 0x63
	cp	wa, 0:i3
	jrl	lt, Sprintf_MainLoop_ReadNext
	cp	wa, 0x15
	jrl	gt, Sprintf_MainLoop_ReadNext
	add	wa, wa
	lda	xix, (Sprintf_TypeSwitch:24)
	ld	wa, (xix+wa)
	lda	xix, (Sprintf_Format_Percent:24)
	jp	t, (xix+wa)
Sprintf_Format_Percent:
	ld	wa, (xsp + 6)
	bit	1, wa
	jr	z, Sprintf_Percent_PadLeftLoop
	jr	Sprintf_Format_CharOrPercent
Sprintf_Percent_PadLeft:
	incw	1, (xsp + 4)
	pushw_da	0x20, 0xc2, 0x03
	ld	xwa, (xsp + 92)
	call	(xwa)
	inc	2, xsp
Sprintf_Percent_PadLeftLoop:
	decm	1, (xsp + 8)
	cpw	(xsp + 8), 0x0
	jr	gt, Sprintf_Percent_PadLeft
Sprintf_Format_CharOrPercent:
	incw	1, (xsp + 4)
	cp	iz, 0x63
	jr	nz, Sprintf_Percent_LiteralPush
	ld	xbc, (xsp + 86)
	ld	xwa, 2:i3
	add	(xbc), xwa
	ld	xwa, (xbc)
	pushm	(xwa - 2)
	jr	Sprintf_Percent_OutputChar
Sprintf_Percent_LiteralPush:
	pushw	0x25
Sprintf_Percent_OutputChar:
	ld	xwa, (xsp + 92)
	call	(xwa)
	inc	2, xsp
	ld	wa, (xsp + 6)
	bit	1, wa
	jr	nz, Sprintf_Percent_PadRightLoop
	jrl	Sprintf_MainLoop_ReadNext
Sprintf_Percent_PadRight:
	incw	1, (xsp + 4)
	pushw	0x20
	ld	xwa, (xsp + 92)
	call	(xwa)
	inc	2, xsp
Sprintf_Percent_PadRightLoop:
	decm	1, (xsp + 8)
	cpw	(xsp + 8), 0x0
	jr	gt, Sprintf_Percent_PadRight
	jrl	Sprintf_MainLoop_ReadNext
	ld	xbc, (xsp + 86)
	ld	xwa, 4:i3
	add	(xbc), xwa
	ld	xwa, (xbc)
	ld	xwa, (xwa - 4)
	ld	(xsp + 16), xwa
	push	xwa
	call	Strlen
	inc	4, xsp
	ld	wa, (xsp + 6)
	bit	4, wa
	jr	z, Sprintf_String_UseStrLen
	cp	(xsp + 10), hl
	jr	lt, Sprintf_String_UsePrecision
Sprintf_String_UseStrLen:
	ld	(xsp + 10), hl
	jr	Sprintf_String_ComputePadding
Sprintf_String_UsePrecision:
	ld	hl, (xsp + 10)
Sprintf_String_ComputePadding:
	cp	hl, (xsp + 8)
	jr	le, Sprintf_String_WidthAvailable
	ldw	(xsp + 8), 0x0
	add	(xsp + 4), hl
	jr	Sprintf_String_CheckLeftAlign
Sprintf_String_WidthAvailable:
	ld	wa, (xsp + 8)
	add	(xsp + 4), wa
	sub	(xsp + 8), hl
Sprintf_String_CheckLeftAlign:
	ld	wa, (xsp + 6)
	bit	1, wa
	jr	z, Sprintf_String_PadLeftLoop
	jr	Sprintf_String_OutputLoop
Sprintf_String_PadLeftSpace:
	pushw_da	0x20, 0xc2, 0x03
	ld	xwa, (xsp + 92)
	call	(xwa)
	inc	2, xsp
Sprintf_String_PadLeftLoop:
	ld	wa, (xsp + 8)
	decm	1, (xsp + 8)
	cp	wa, 0:i3
	jr	nz, Sprintf_String_PadLeftSpace
	jr	Sprintf_String_OutputLoop
Sprintf_String_OutputChars:
	ld	xwa, (xsp + 16)
	ld	C, (xwa+)
	ld	(xsp + 16), xwa
	exts	bc
	pushw	bc
	ld	xwa, (xsp + 92)
	call	(xwa)
	inc	2, xsp
Sprintf_String_OutputLoop:
	ld	wa, (xsp + 10)
	decm	1, (xsp + 10)
	cp	wa, 0:i3
	jr	nz, Sprintf_String_OutputChars
	ld	wa, (xsp + 6)
	bit	1, wa
	jr	nz, Sprintf_String_PadRightLoop
	jrl	Sprintf_MainLoop_ReadNext
Sprintf_String_PadRightSpace:
	pushw	0x20
	ld	xwa, (xsp + 92)
	call	(xwa)
	inc	2, xsp
Sprintf_String_PadRightLoop:
	ld	wa, (xsp + 8)
	decm	1, (xsp + 8)
	cp	wa, 0:i3
	jr	nz, Sprintf_String_PadRightSpace
	jrl	Sprintf_MainLoop_ReadNext
	ld	wa, (xsp + 6)
	bit	6, wa
	jr	z, Sprintf_Decimal_GetShortArg
	ld	xbc, (xsp + 86)
	ld	xwa, 4:i3
	add	(xbc), xwa
	ld	xwa, (xbc)
	ld	xwa, (xwa - 4)
	ld	(xsp + 16), xwa
	jr	Sprintf_Decimal_Setup
Sprintf_Decimal_GetShortArg:
	ld	xbc, (xsp + 86)
	ld	xwa, 2:i3
	add	(xbc), xwa
	ld	xwa, (xbc)
	.set	Strcpy, . + 1	; no instruction starts here: the name points 1 byte(s) into the one below
	ld	wa, (xwa-2)
	; Strcpy is kept at this address only for ui_widgets/naka_widget_descriptors.c; v10's Strcpy is the code at 0xFF0770
	exts	xwa
	ld	(xsp + 16), xwa
Sprintf_Decimal_Setup:
	ldw	(xsp + 14), 0x0
	lda	xbc, (xsp + 56)
	ld	wa, (xsp + 6)
	bit	4, wa
	jr	z, Sprintf_Decimal_ConvertToString
	cpw	(xsp + 10), 0x0
	jr	nz, Sprintf_Decimal_ConvertToString
	ld	xwa, (xsp + 16)
	or	xwa, xwa
	jr	nz, Sprintf_Decimal_ConvertToString
	ld	(xbc), 0x0
	ldw	(xsp + 12), 0x0
	jr	Sprintf_Decimal_CheckPrecision
Sprintf_Decimal_ConvertToString:
	ld	xwa, (xsp + 16)
	push	xwa
	push	xbc
	calr	Sprintf_IntToStr
	lda	xwa, (xsp + 64)
	push	xwa
	call	Strlen
	lda	xsp, (xsp + 12)
	ld	(xsp + 12), hl
	ld	xwa, (xsp + 16)
	cp	xwa, 0x0
	jr	ge, Sprintf_Decimal_CheckPrecision
	ldw	(xsp + 14), 0x1
Sprintf_Decimal_CheckPrecision:
	ld	wa, (xsp + 6)
	bit	4, wa
	jr	z, Sprintf_Decimal_NoPrecision
	ld	wa, (xsp + 10)
	cp	wa, (xsp + 12)
	jr	ge, Sprintf_Decimal_SubtractLength
Sprintf_Decimal_NoPrecision:
	ldw	(xsp + 10), 0x0
	jr	Sprintf_Decimal_CheckSign
Sprintf_Decimal_SubtractLength:
	ld	wa, (xsp + 12)
	sub	(xsp + 10), wa
Sprintf_Decimal_CheckSign:
	ld	wa, (xsp + 6)
	and	wa, 0x5
	jr	z, Sprintf_Decimal_ComputeWidth
	ldw	(xsp + 14), 0x1
Sprintf_Decimal_ComputeWidth:
	ld	wa, (xsp + 12)
	add	wa, (xsp + 10)
	add	wa, (xsp + 14)
	sub	(xsp + 8), wa
	jr	ge, Sprintf_Decimal_FinalWidth
	ldw	(xsp + 8), 0x0
Sprintf_Decimal_FinalWidth:
	ld	wa, (xsp + 8)
	add	wa, (xsp + 12)
	add	wa, (xsp + 10)
	add	wa, (xsp + 14)
	add	(xsp + 4), wa
	cpw	(xsp + 8), 0x0
	jr	z, Sprintf_Decimal_OutputSign
	ld	wa, (xsp + 6)
	bit	1, wa
	jr	nz, Sprintf_Decimal_OutputSign
	cpw	(0x3c220:24), 32
	jr	z, Sprintf_Decimal_PadLeftLoop
	bit	4, wa
	jr	nz, Sprintf_Decimal_PadLeftLoop
	jr	Sprintf_Decimal_OutputSign
Sprintf_Decimal_PadLeftSpace:
	pushw	0x20
	ld	xwa, (xsp + 92)
	call	(xwa)
	inc	2, xsp
Sprintf_Decimal_PadLeftLoop:
	ld	wa, (xsp + 8)
	decm	1, (xsp + 8)
	cp	wa, 0:i3
	jr	nz, Sprintf_Decimal_PadLeftSpace
	ldw	(xsp + 8), 0x0
Sprintf_Decimal_OutputSign:
	ld	xwa, (xsp + 16)
	cp	xwa, 0x0
	jr	ge, Sprintf_Decimal_PlusSign
	pushw	0x2d
	jr	Sprintf_Decimal_EmitSign
Sprintf_Decimal_PlusSign:
	ld	wa, (xsp + 6)
	bit	0, wa
	jr	z, Sprintf_Decimal_SpaceSign
	pushw	0x2b
	jr	Sprintf_Decimal_EmitSign
Sprintf_Decimal_SpaceSign:
	ld	wa, (xsp + 6)
	bit	2, wa
	jr	z, Sprintf_Decimal_ZeroFill
	pushw	0x20
Sprintf_Decimal_EmitSign:
	ld	xwa, (xsp + 92)
	call	(xwa)
	inc	2, xsp
Sprintf_Decimal_ZeroFill:
	ld	wa, (xsp + 6)
	bit	1, wa
	jr	nz, Sprintf_Decimal_PrecZeroLoop
	cpw	(0x3c220:24), 48
	jr	z, Sprintf_Decimal_ZeroFillLoop
	jr	Sprintf_Decimal_PrecZeroLoop
Sprintf_Decimal_ZeroFillBody:
	pushw	0x30
	ld	xwa, (xsp + 92)
	call	(xwa)
	inc	2, xsp
Sprintf_Decimal_ZeroFillLoop:
	ld	wa, (xsp + 8)
	decm	1, (xsp + 8)
	cp	wa, 0:i3
	jr	nz, Sprintf_Decimal_ZeroFillBody
	jr	Sprintf_Decimal_PrecZeroLoop
Sprintf_Decimal_PrecZeroBody:
	pushw	0x30
	ld	xwa, (xsp + 92)
	call	(xwa)
	inc	2, xsp
Sprintf_Decimal_PrecZeroLoop:
	ld	wa, (xsp + 10)
	decm	1, (xsp + 10)
	cp	wa, 0:i3
	jr	nz, Sprintf_Decimal_PrecZeroBody
	jr	Sprintf_Decimal_DigitLoop
Sprintf_Decimal_OutputDigits:
	decm	1, (xsp + 12)
	lda	xbc, (xsp + 56)
	ld	wa, (xsp + 12)
	ld	a, (xbc+wa)
	exts	wa
	pushw	wa
	ld	xwa, (xsp + 92)
	call	(xwa)
	inc	2, xsp
Sprintf_Decimal_DigitLoop:
	cpw	(xsp + 12), 0x0
	jr	nz, Sprintf_Decimal_OutputDigits
	ld	wa, (xsp + 6)
	bit	1, wa
	jr	nz, Sprintf_Decimal_PadRightLoop
	jrl	Sprintf_MainLoop_ReadNext
Sprintf_Decimal_PadRightSpace:
	pushw	0x20
	ld	xwa, (xsp + 92)
	call	(xwa)
	inc	2, xsp
Sprintf_Decimal_PadRightLoop:
	ld	wa, (xsp + 8)
	decm	1, (xsp + 8)
	cp	wa, 0:i3
	jr	nz, Sprintf_Decimal_PadRightSpace
	jrl	Sprintf_MainLoop_ReadNext
	ld	wa, (xsp + 6)
	bit	6, wa
	jr	z, Sprintf_Unsigned_GetShortArg
	ld	xbc, (xsp + 86)
	ld	xwa, 4:i3
	add	(xbc), xwa
	ld	xwa, (xbc)
	ld	xde, (xwa - 4)
	jr	Sprintf_Unsigned_Setup
Sprintf_Unsigned_GetShortArg:
	ld	xbc, (xsp + 86)
	ld	xwa, 2:i3
	add	(xbc), xwa
	ld	xwa, (xbc)
	ld	de, (xwa - 2)
	extz	xde
Sprintf_Unsigned_Setup:
	lda	xbc, (xsp + 44)
	ld	wa, (xsp + 6)
	bit	4, wa
	jr	z, Sprintf_Unsigned_ConvertToString
	cpw	(xsp + 10), 0x0
	jr	nz, Sprintf_Unsigned_ConvertToString
	or	xde, xde
	jr	nz, Sprintf_Unsigned_ConvertToString
	ld	(xbc), 0x0
	ld	iz, 0:i3
	jr	Sprintf_Unsigned_CheckPrecision
Sprintf_Unsigned_ConvertToString:
	push	xde
	push	xbc
	calr	Sprintf_UIntToStr
	lda	xwa, (xsp + 52)
	push	xwa
	call	Strlen
	lda	xsp, (xsp + 12)
	ld	iz, hl
Sprintf_Unsigned_CheckPrecision:
	ld	wa, (xsp + 6)
	bit	4, wa
	jr	z, Sprintf_Unsigned_NoPrecision
	cp	(xsp + 10), iz
	jr	ge, Sprintf_Unsigned_SubtractLength
Sprintf_Unsigned_NoPrecision:
	ldw	(xsp + 10), 0x0
	jr	Sprintf_Unsigned_ComputeWidth
Sprintf_Unsigned_SubtractLength:
	sub	(xsp + 10), iz
Sprintf_Unsigned_ComputeWidth:
	ld	wa, iz
	add	wa, (xsp + 10)
	sub	(xsp + 8), wa
	jr	ge, Sprintf_Unsigned_FinalWidth
	ldw	(xsp + 8), 0x0
Sprintf_Unsigned_FinalWidth:
	ld	wa, (xsp + 8)
	add	wa, iz
	add	wa, (xsp + 10)
	add	(xsp + 4), wa
	ld	wa, (xsp + 6)
	bit	1, wa
	jr	z, Sprintf_Unsigned_PadLeftLoop
	jr	Sprintf_Unsigned_PrecZeroLoop
Sprintf_Unsigned_PadLeftSpace:
	pushw_da	0x20, 0xc2, 0x03
	ld	xwa, (xsp + 92)
	call	(xwa)
	inc	2, xsp
Sprintf_Unsigned_PadLeftLoop:
	ld	wa, (xsp + 8)
	decm	1, (xsp + 8)
	cp	wa, 0:i3
	jr	nz, Sprintf_Unsigned_PadLeftSpace
	jr	Sprintf_Unsigned_PrecZeroLoop
Sprintf_Unsigned_PrecZeroBody:
	pushw	0x30
	ld	xwa, (xsp + 92)
	call	(xwa)
	inc	2, xsp
Sprintf_Unsigned_PrecZeroLoop:
	ld	wa, (xsp + 10)
	decm	1, (xsp + 10)
	cp	wa, 0:i3
	jr	nz, Sprintf_Unsigned_PrecZeroBody
	jr	Sprintf_Unsigned_DigitLoop
Sprintf_Unsigned_OutputDigits:
	dec	1, iz
	lda	xwa, (xsp + 44)
	ld	a, (xwa+iz)
	exts	wa
	pushw	wa
	ld	xwa, (xsp + 92)
	call	(xwa)
	inc	2, xsp
Sprintf_Unsigned_DigitLoop:
	cp	iz, 0:i3
	jr	nz, Sprintf_Unsigned_OutputDigits
	ld	wa, (xsp + 6)
	bit	1, wa
	jr	nz, Sprintf_Unsigned_PadRightLoop
	jrl	Sprintf_MainLoop_ReadNext
Sprintf_Unsigned_PadRightSpace:
	pushw	0x20
	ld	xwa, (xsp + 92)
	call	(xwa)
	inc	2, xsp
Sprintf_Unsigned_PadRightLoop:
	ld	wa, (xsp + 8)
	decm	1, (xsp + 8)
	cp	wa, 0:i3
	jr	nz, Sprintf_Unsigned_PadRightSpace
	jrl	Sprintf_MainLoop_ReadNext
	setm	6, (xsp + 6)
Sprintf_Hex_GetArg:
	ld	wa, (xsp + 6)
	bit	6, wa
	jr	z, Sprintf_Hex_GetShortArg
	ld	xbc, (xsp + 86)
	ld	xwa, 4:i3
	add	(xbc), xwa
	ld	xwa, (xbc)
	ld	xde, (xwa - 4)
	jr	Sprintf_Hex_Setup
Sprintf_Hex_GetShortArg:
	ld	xbc, (xsp + 86)
	ld	xwa, 2:i3
	add	(xbc), xwa
	ld	xwa, (xbc)
	ld	de, (xwa - 2)
	extz	xde
Sprintf_Hex_Setup:
	lda	xbc, (xsp + 32)
	ld	wa, (xsp + 6)
	bit	4, wa
	jr	z, Sprintf_Hex_ConvertToString
	cpw	(xsp + 10), 0x0
	jr	nz, Sprintf_Hex_ConvertToString
	or	xde, xde
	jr	nz, Sprintf_Hex_ConvertToString
	ld	(xbc), 0x0
	ldw	(xsp + 18), 0x0
	jr	Sprintf_Hex_CheckPrecision
Sprintf_Hex_ConvertToString:
	pushw	iz
	push	xde
	push	xbc
	calr	Sprintf_HexToStr
	lda	xwa, (xsp + 42)
	push	xwa
	call	Strlen
	lda	xsp, (xsp + 14)
	ld	(xsp + 18), hl
Sprintf_Hex_CheckPrecision:
	ld	wa, (xsp + 6)
	bit	4, wa
	jr	z, Sprintf_Hex_NoPrecision
	ld	wa, (xsp + 10)
	cp	wa, (xsp + 18)
	jr	ge, Sprintf_Hex_SubtractLength
Sprintf_Hex_NoPrecision:
	ldw	(xsp + 10), 0x0
	jr	Sprintf_Hex_CheckAltForm
Sprintf_Hex_SubtractLength:
	ld	wa, (xsp + 18)
	sub	(xsp + 10), wa
Sprintf_Hex_CheckAltForm:
	ldiw_erp	0xfa, 0
	ld	wa, (xsp + 6)
	bit	3, wa
	jr	z, Sprintf_Hex_AltFormPrefix
	ldiw_erp	0xfa, 2
Sprintf_Hex_AltFormPrefix:
	ld	wa, (xsp + 18)
	add	wa, (xsp + 10)
	addw_erp	WA, 0xfa
	sub	(xsp + 8), wa
	jr	ge, Sprintf_Hex_ComputeWidth
	ldw	(xsp + 8), 0x0
Sprintf_Hex_ComputeWidth:
	ld	wa, (xsp + 8)
	add	wa, (xsp + 18)
	add	wa, (xsp + 10)
	addw_erp	WA, 0xfa
	add	(xsp + 4), wa
	ld	wa, (xsp + 6)
	bit	1, wa
	jr	nz, Sprintf_Hex_EmitPrefix
	cpw	(0x3c220:24), 32
	jr	z, Sprintf_Hex_PadLeftLoop
	jr	Sprintf_Hex_EmitPrefix
Sprintf_Hex_PadLeftSpace:
	pushw	0x20
	ld	xwa, (xsp + 92)
	call	(xwa)
	inc	2, xsp
Sprintf_Hex_PadLeftLoop:
	ld	wa, (xsp + 8)
	decm	1, (xsp + 8)
	cp	wa, 0:i3
	jr	nz, Sprintf_Hex_PadLeftSpace
Sprintf_Hex_EmitPrefix:
	cpiw_erp	0xfa, 0
	jr	z, Sprintf_Hex_ZeroFill
	cpw	(xsp + 18), 0x0
	jr	z, Sprintf_Hex_ZeroFill
	pushw	0x30
	ld	xwa, (xsp + 92)
	call	(xwa)
	pushw	iz
	ld	xwa, (xsp + 94)
	call	(xwa)
	inc	4, xsp
Sprintf_Hex_ZeroFill:
	ld	wa, (xsp + 6)
	bit	1, wa
	jr	nz, Sprintf_Hex_PrecZeroLoop
	cpw	(0x3c220:24), 48
	jr	z, Sprintf_Hex_ZeroFillLoop
	jr	Sprintf_Hex_PrecZeroLoop
Sprintf_Hex_ZeroFillBody:
	pushw	0x30
	ld	xwa, (xsp + 92)
	call	(xwa)
	inc	2, xsp
Sprintf_Hex_ZeroFillLoop:
	ld	wa, (xsp + 8)
	decm	1, (xsp + 8)
	cp	wa, 0:i3
	jr	nz, Sprintf_Hex_ZeroFillBody
	jr	Sprintf_Hex_PrecZeroLoop
Sprintf_Hex_PrecZeroBody:
	pushw	0x30
	ld	xwa, (xsp + 92)
	call	(xwa)
	inc	2, xsp
Sprintf_Hex_PrecZeroLoop:
	ld	wa, (xsp + 10)
	decm	1, (xsp + 10)
	cp	wa, 0:i3
	jr	nz, Sprintf_Hex_PrecZeroBody
	jr	Sprintf_Hex_DigitLoop
Sprintf_Hex_OutputDigits:
	decm	1, (xsp + 18)
	lda	xbc, (xsp + 32)
	ld	wa, (xsp + 18)
	ld	a, (xbc+wa)
	exts	wa
	pushw	wa
	ld	xwa, (xsp + 92)
	call	(xwa)
	inc	2, xsp
Sprintf_Hex_DigitLoop:
	cpw	(xsp + 18), 0x0
	jr	nz, Sprintf_Hex_OutputDigits
	ld	wa, (xsp + 6)
	bit	1, wa
	jr	nz, Sprintf_Hex_PadRightLoop
	jrl	Sprintf_MainLoop_ReadNext
Sprintf_Hex_PadRightSpace:
	pushw	0x20
	ld	xwa, (xsp + 92)
	call	(xwa)
	inc	2, xsp
Sprintf_Hex_PadRightLoop:
	ld	wa, (xsp + 8)
	decm	1, (xsp + 8)
	cp	wa, 0:i3
	jr	nz, Sprintf_Hex_PadRightSpace
	jrl	Sprintf_MainLoop_ReadNext
	ld	wa, (xsp + 6)
	bit	6, wa
	jr	z, Sprintf_Octal_GetShortArg
	ld	xbc, (xsp + 86)
	ld	xwa, 4:i3
	add	(xbc), xwa
	ld	xwa, (xbc)
	ld	xde, (xwa - 4)
	jr	Sprintf_Octal_Setup
Sprintf_Octal_GetShortArg:
	ld	xbc, (xsp + 86)
	ld	xwa, 2:i3
	add	(xbc), xwa
	ld	xwa, (xbc)
	ld	de, (xwa - 2)
	extz	xde
Sprintf_Octal_Setup:
	lda	xbc, (xsp + 20)
	ld	wa, (xsp + 6)
	bit	4, wa
	jr	z, Sprintf_Octal_ConvertToString
	cpw	(xsp + 10), 0x0
	jr	nz, Sprintf_Octal_ConvertToString
	or	xde, xde
	jr	nz, Sprintf_Octal_ConvertToString
	ld	(xbc), 0x0
	ld	iz, 0:i3
	jr	Sprintf_Octal_CheckPrecision
Sprintf_Octal_ConvertToString:
	push	xde
	push	xbc
	calr	Sprintf_OctalToStr
	lda	xwa, (xsp + 28)
	push	xwa
	call	Strlen
	lda	xsp, (xsp + 12)
	ld	iz, hl
Sprintf_Octal_CheckPrecision:
	ld	wa, (xsp + 6)
	bit	4, wa
	jr	z, Sprintf_Octal_NoPrecision
	cp	(xsp + 10), iz
	jr	ge, Sprintf_Octal_SubtractLength
Sprintf_Octal_NoPrecision:
	ldw	(xsp + 10), 0x0
	jr	Sprintf_Octal_CheckAltForm
Sprintf_Octal_SubtractLength:
	sub	(xsp + 10), iz
Sprintf_Octal_CheckAltForm:
	ld	wa, (xsp + 6)
	and	wa, 0x8
	cp	wa, 0:i3
	scc16	nz, wa
	ld	(xsp + 18), wa
	ld	wa, iz
	add	wa, (xsp + 10)
	add	wa, (xsp + 18)
	sub	(xsp + 8), wa
	jr	ge, Sprintf_Octal_ComputeWidth
	ldw	(xsp + 8), 0x0
Sprintf_Octal_ComputeWidth:
	ld	wa, (xsp + 8)
	add	wa, iz
	add	wa, (xsp + 10)
	add	wa, (xsp + 18)
	add	(xsp + 4), wa
	ld	wa, (xsp + 6)
	bit	1, wa
	jr	nz, Sprintf_Octal_EmitPrefix
	cpw	(0x3c220:24), 32
	jr	z, Sprintf_Octal_PadLeftLoop
	jr	Sprintf_Octal_EmitPrefix
Sprintf_Octal_PadLeftSpace:
	pushw	0x20
	ld	xwa, (xsp + 92)
	call	(xwa)
	inc	2, xsp
Sprintf_Octal_PadLeftLoop:
	ld	wa, (xsp + 8)
	decm	1, (xsp + 8)
	cp	wa, 0:i3
	jr	nz, Sprintf_Octal_PadLeftSpace
Sprintf_Octal_EmitPrefix:
	cpw	(xsp + 18), 0x0
	jr	z, Strcpy_Code_Skip
	cp	iz, 0:i3
	jr	z, Strcpy_Code_Skip
	pushw	0x30
	ld	xwa, (xsp + 92)
	call	(xwa)
	inc	2, xsp
; v10 name for this address: Sprintf_Octal_ZeroFill -- not a label here: v7 keeps that name at 0xFF1462 for shared/positional_labels.s
Strcpy_Code_Skip:
	ld	wa, (xsp + 6)
	bit	1, wa
	jr	nz, Sprintf_Octal_PrecZeroLoop
	cpw	(0x3c220:24), 48
	jr	z, Sprintf_Octal_ZeroFillLoop
	jr	Sprintf_Octal_PrecZeroLoop
Sprintf_Octal_ZeroFillBody:
	pushw	0x30
	ld	xwa, (xsp + 92)
	call	(xwa)
	inc	2, xsp
Sprintf_Octal_ZeroFillLoop:
	ld	wa, (xsp + 8)
	decm	1, (xsp + 8)
	cp	wa, 0:i3
	jr	nz, Sprintf_Octal_ZeroFillBody
	jr	Sprintf_Octal_PrecZeroLoop
Sprintf_Octal_PrecZeroBody:
	pushw	0x30
	ld	xwa, (xsp + 92)
	call	(xwa)
	inc	2, xsp
Sprintf_Octal_PrecZeroLoop:
	ld	wa, (xsp + 10)
	decm	1, (xsp + 10)
	cp	wa, 0:i3
	jr	nz, Sprintf_Octal_PrecZeroBody
	jr	Sprintf_Octal_DigitLoop
Sprintf_Octal_OutputDigits:
	dec	1, iz
	lda	xwa, (xsp + 20)
	ld	a, (xwa+iz)
	exts	wa
	pushw	wa
	ld	xwa, (xsp + 92)
	call	(xwa)
	inc	2, xsp
Sprintf_Octal_DigitLoop:
	cp	iz, 0:i3
	jr	nz, Sprintf_Octal_OutputDigits
	ld	wa, (xsp + 6)
	bit	1, wa
	jr	nz, Sprintf_Octal_PadRightLoop
	jrl	Sprintf_MainLoop_ReadNext
Sprintf_Octal_PadRightSpace:
	pushw	0x20
	ld	xwa, (xsp + 92)
	call	(xwa)
	inc	2, xsp
Sprintf_Octal_PadRightLoop:
	ld	wa, (xsp + 8)
	decm	1, (xsp + 8)
	cp	wa, 0:i3
	jr	nz, Sprintf_Octal_PadRightSpace
	jr	Sprintf_MainLoop_ReadNext
	ld	xbc, (xsp + 86)
	ld	xwa, 4:i3
	add	(xbc), xwa
	ld	xwa, (xbc)
	ld	xbc, (xwa - 4)
	ld	wa, (xsp + 6)
	bit	6, wa
	jr	z, Sprintf_StoreCount_Short
	ld	wa, (xsp + 4)
	exts	xwa
	ld	(xbc), xwa
	jr	Sprintf_MainLoop_ReadNext
Sprintf_StoreCount_Short:
	ld	wa, (xsp + 4)
	ld	(xbc), wa
	jr	Sprintf_MainLoop_ReadNext
Sprintf_FormatFloat_Entry:
	lda	xbc, (xsp + 68)
	ld	wa, (xsp + 6)
	bit	7, wa
	jr	z, Sprintf_FormatFloat_ShortArg
	ld	xwa, xbc
	ld	xde, (xsp + 86)
	lda_dd8l	XBC, (0x0a)
	add	(xde), xbc
	ld	xbc, (xde)
	lda	xbc, (xbc - 10)
	call	Sprintf_CopyBytes10
	jr	Sprintf_FormatFloat_Dispatch
Sprintf_FormatFloat_ShortArg:
	ld	xwa, xbc
	ld	xde, (xsp + 86)
	lda_dd8l	XBC, (0x08)
	add	(xde), xbc
	ld	xbc, (xde)
	dec	8, xbc
	call	Sprintf_CopyBytes8
Sprintf_FormatFloat_Dispatch:
	pushm	(xsp + 10)
	pushm	(xsp + 10)
	pushm	(xsp + 10)
	lda	xwa, (xsp + 74)
	push	xwa
	ld	xwa, (xsp + 100)
	push	xwa
	ldto_berp	A, 0xf8
	exts	wa
	pushw	wa
	calr	Sprintf_FormatFloat
	lda	xsp, (xsp + 16)
	ld	wa, (0x03c222:24)
	add	(xsp + 4), wa
Sprintf_MainLoop_ReadNext:
	ld	xwa, (xsp + 82)
	ld	C, (xwa+)
	ld	(xsp + 82), xwa
	ldfr_berp	C, 0xf8
	exts	iz
	cp	iz, 0:i3
	jrl	nz, Sprintf_OutputLiteral
	ld	hl, (xsp + 4)
	pop	xiz
	lda	xsp, (xsp + 74)
	ret
Sprintf_IntToStr:
	dec	4, xsp
	push	xiz
	ld	xwa, (xsp + 16)
	cp	xwa, 0x0
	jr	ge, Sprintf_IntToStr_Positive
	cpl	wa
	cplw_erp	0xe2
	inc	1, xwa
Sprintf_IntToStr_Positive:
	ld	xiz, xwa
Sprintf_IntToStr_DivLoop:
	ld	xwa, (xsp + 12)
	lda	xbc, (xwa+:1)
	ld	(xsp + 4), xbc
	ld	(xsp + 12), xwa
	ld	xwa, xiz
	lda_dd8l	XBC, (0x0a)
	call	DivMod32
	add	xhl, 0x30
	ld	xwa, (xsp + 4)
	ld	(xwa), l
	ld	xwa, xiz
	lda_dd8l	XBC, (0x0a)
	call	Math_DivideU32
	ld	xiz, xhl
	or	xiz, xiz
	jr	nz, Sprintf_IntToStr_DivLoop
	ld	xwa, (xsp + 12)
	ld	(xwa), 0x0
	pop	xiz
	inc	4, xsp
	ret
Sprintf_UIntToStr:
	dec	4, xsp
	push	xiz
	ld	xiz, (xsp + 16)
Sprintf_UIntToStr_DivLoop:
	ld	xwa, (xsp + 12)
	lda	xbc, (xwa+:1)
	ld	(xsp + 4), xbc
	ld	(xsp + 12), xwa
	ld	xwa, xiz
	lda_dd8l	XBC, (0x0a)
	call	DivMod32
	add	xhl, 0x30
	ld	xwa, (xsp + 4)
	ld	(xwa), l
	ld	xwa, xiz
	lda_dd8l	XBC, (0x0a)
	call	Math_DivideU32
	ld	xiz, xhl
	or	xiz, xiz
	jr	nz, Sprintf_UIntToStr_DivLoop
	ld	xwa, (xsp + 12)
	ld	(xwa), 0x0
	pop	xiz
	inc	4, xsp
	ret
Sprintf_HexToStr:
	ld	xwa, Sprintf_HexDigitsUpper
	cpw	(xsp + 12), 0x78
	jr	nz, Sprintf_HexToStr_TableSelected
	ld	xwa, Sprintf_HexDigitsLower
Sprintf_HexToStr_TableSelected:
	ld	xix, xwa
	ld	xhl, (xsp + 4)
	ld	xde, (xsp + 8)
Sprintf_HexToStr_Loop:
	lda	xbc, (xhl+:1)
	ld	xwa, xde
	and	xwa, 0xf
	add	xwa, xix
	ld	a, (xwa)
	ld	(xbc), a
	srl	xde, 4
	jr	nz, Sprintf_HexToStr_Loop
	ld	(xhl), 0x0
	ret
Sprintf_OctalToStr:
	ld	xde, (xsp + 8)
	ld	xhl, (xsp + 4)
Sprintf_OctalToStr_Loop:
	lda	xbc, (xhl+:1)
	ld	xwa, xde
	and	xwa, 0x7
	add	xwa, 0x30
	ld	(xbc), a
	srl	xde, 3
	jr	nz, Sprintf_OctalToStr_Loop
	ld	(xhl), 0x0
	ret
Sprintf_FormatFloat:
	lda	xsp, (xsp - 26)
	push	xiz
	ldw	(xsp + 4), 0x0
	lda	xwa, (xsp + 6)
	push	xwa
	lda	xwa, (xsp + 8)
	push	xwa
	pushm	(xsp + 52)
	lda	xwa, (xsp + 18)
	push	xwa
	ld	xwa, (xsp + 54)
	push	xwa
	call	Sprintf_FormatGGeneral
	lda	xsp, (xsp + 18)
	ldw	(0x03c222:24), 0x0000
	lda	xde, (xsp + 8)
	ld	xiy, xde
	ld	c, (xsp + 34)
	ld	xiz, (xsp + 36)
	ld	ix, (xsp + 46)
	ld	hl, (xsp + 48)
	ld	a, c
	exts	wa
	cp	c, 0x65
	jr	z, Sprintf_FormatFloat_eE
	cp	c, 0x45
	jr	nz, Sprintf_FormatFloat_fF_Check
Sprintf_FormatFloat_eE:
	pushm	(xsp + 6)
	pushm	(xsp + 6)
	push	xiy
	pushw	hl
	pushw	ix
	pushm	(xsp + 56)
	push	xiz
	pushw	wa
	jr	Sprintf_FormatFloat_gG_UseSci
Sprintf_FormatFloat_fF_Check:
	cp	c, 0x66
	jr	z, Sprintf_FormatFloat_fF
	cp	c, 0x46
	jr	nz, Sprintf_FormatFloat_gG
Sprintf_FormatFloat_fF:
	pushm	(xsp + 6)
	pushm	(xsp + 6)
	push	xiy
	pushw	hl
	pushw	ix
	pushm	(xsp + 56)
	push	xiz
	pushw	wa
Sprintf_FormatFloat_fF_Call:
	calr	Sprintf_FormatFFixed
	lda	xsp, (xsp + 20)
	jr	Sprintf_FormatFloat_Return
Sprintf_FormatFloat_gG:
	ld	wa, (xsp + 44)
	bit	4, wa
	jr	nz, Sprintf_FormatFloat_gG_Setup
	ld	hl, 6:i3
	setm	4, (xsp + 44)
Sprintf_FormatFloat_gG_Setup:
	exts	bc
	pushm	(xsp + 6)
	pushm	(xsp + 6)
	push	xde
	pushw	hl
	pushw	ix
	pushm	(xsp + 56)
	push	xiz
	pushw	bc
	cpw	(xsp + 24), 0xfffc
	jr	le, Sprintf_FormatFloat_gG_UseSci
	cp	(xsp + 24), hl
	jr	le, Sprintf_FormatFloat_fF_Call
Sprintf_FormatFloat_gG_UseSci:
	calr	Sprintf_FormatEScientific
	lda	xsp, (xsp + 20)
Sprintf_FormatFloat_Return:
	pop	xiz
	lda	xsp, (xsp + 26)
	ret
Sprintf_FormatFFixed:
	dec	4, xsp
	pushw	iz
	ldw	(xsp + 4), 0xf
	cpw	(xsp + 26), 0x1
	jr	ge, Sprintf_FFixed_SetPrecision
	ldw	(xsp + 2), 0x0
	jr	Sprintf_FFixed_CheckDefaults
Sprintf_FFixed_SetPrecision:
	ld	wa, (xsp + 26)
	ld	(xsp + 2), wa
Sprintf_FFixed_CheckDefaults:
	ld	wa, (xsp + 16)
	bit	4, wa
	jr	nz, Sprintf_FFixed_CheckLongDouble
	ldw	(xsp + 20), 0x6
Sprintf_FFixed_CheckLongDouble:
	ld	wa, (xsp + 16)
	bit	7, wa
	jr	z, Sprintf_FFixed_CheckLongDoubleLimit
	ldw	(xsp + 4), 0x12
Sprintf_FFixed_CheckLongDoubleLimit:
	ld	c, (xsp + 10)
	ld	a, c
	extz	wa
	lda	xde, (CType_ClassTable:24)
	lda	xde, (xde+wa)
	bitm	1, (xde)
	jr	z, Sprintf_FFixed_SpecNoUpperCase
	ld	a, c
	sub	a, 0x20
	jr	Sprintf_FFixed_CheckSpecG
Sprintf_FFixed_SpecNoUpperCase:
	ld	a, c
Sprintf_FFixed_CheckSpecG:
	cp	a, 0x47
	jr	nz, Sprintf_FFixed_NotG
	ld	iz, (xsp + 20)
	jr	Sprintf_FFixed_RoundCheck
Sprintf_FFixed_NotG:
	ld	iz, (xsp + 20)
	add	iz, (xsp + 26)
Sprintf_FFixed_RoundCheck:
	ld	wa, (xsp + 4)
	inc	1, wa
	cp	iz, wa
	jr	ge, Sprintf_FFixed_AfterRound
	ld	xwa, (xsp + 22)
	cp	(xwa+iz), 0x34
	jr	le, Sprintf_FFixed_AfterRound
	cp	iz, 0:i3
	jr	ge, Sprintf_FFixed_RoundLoop
	jr	Sprintf_FFixed_AfterRound
Sprintf_FFixed_RoundCarry:
	ld	xwa, (xsp + 22)
	ld	(xwa+iz), 0x30
Sprintf_FFixed_RoundLoop:
	dec	1, iz
	ld	xwa, (xsp + 22)
	inc	1, (xwa+iz)
	cp	iz, 0:i3
	jr	le, Sprintf_FFixed_AfterRound
	cp	(xwa+iz), 0x39
	jr	gt, Sprintf_FFixed_RoundCarry
Sprintf_FFixed_AfterRound:
	ld	e, (xde)
	bit	1, e
	jr	z, Sprintf_FFixed_AfterRound_NoCase
	ld	a, c
	sub	a, 0x20
	jr	Sprintf_FFixed_CheckG_StripZeros
Sprintf_FFixed_AfterRound_NoCase:
	ld	a, c
Sprintf_FFixed_CheckG_StripZeros:
	cp	a, 0x47
	jr	nz, Sprintf_FFixed_CheckG_AltForm
	ld	iz, (xsp + 20)
	dec	1, iz
	ld	wa, (xsp + 26)
	neg	wa
	add	(xsp + 20), wa
Sprintf_FFixed_CheckG_AltForm:
	bit	1, e
	jr	z, Sprintf_FFixed_CaseApplied
	sub	c, 0x20
Sprintf_FFixed_CaseApplied:
	cp	c, 0x47
	jr	nz, Sprintf_FFixed_ComputeOutputLen
	ld	wa, (xsp + 16)
	bit	3, wa
	jr	z, Sprintf_FFixed_StripZeroCheck
	jr	Sprintf_FFixed_ComputeOutputLen
Sprintf_FFixed_StripZeroLoop:
	dec	1, iz
	decm	1, (xsp + 20)
Sprintf_FFixed_StripZeroCheck:
	ld	xwa, (xsp + 22)
	cp	(xwa+iz), 0x30
	jr	z, Sprintf_FFixed_StripZeroLoop
Sprintf_FFixed_ComputeOutputLen:
	ld	wa, (xsp + 16)
	bit	4, wa
	jr	z, Sprintf_FFixed_CheckPrecZero
	cpw	(xsp + 20), 0x0
	jr	z, Sprintf_FFixed_AdjustForSign
Sprintf_FFixed_CheckPrecZero:
	decm	1, (xsp + 18)
Sprintf_FFixed_AdjustForSign:
	ld	iz, (xsp + 28)
	cp	iz, 0:i3
	jr	nz, Sprintf_FFixed_AdjustForSign2
	ld	wa, (xsp + 16)
	and	wa, 0x5
	jr	z, Sprintf_FFixed_ComputePadding
Sprintf_FFixed_AdjustForSign2:
	decm	1, (xsp + 18)
Sprintf_FFixed_ComputePadding:
	ld	wa, (xsp + 2)
	add	wa, (xsp + 20)
	sub	(xsp + 18), wa
	ld	xwa, (xsp + 22)
	cp	(xwa), 0x39
	jr	le, Sprintf_FFixed_CheckOverflow
	decm	1, (xsp + 18)
Sprintf_FFixed_CheckOverflow:
	cpw	(xsp + 18), 0x0
	jr	ge, Sprintf_FFixed_PadLeftCheck
	ldw	(xsp + 18), 0x0
Sprintf_FFixed_PadLeftCheck:
	ld	wa, (xsp + 16)
	bit	1, wa
	jr	nz, Sprintf_FFixed_EmitSign
	cpw	(0x3c220:24), 32
	jr	z, Sprintf_FFixed_PadLeftLoop
	jr	Sprintf_FFixed_EmitSign
Sprintf_FFixed_PadLeftSpace:
	pushw	0x20
	ld	xwa, (xsp + 14)
	call	(xwa)
	inc	2, xsp
	incw	1, (0x3c222:24)
Sprintf_FFixed_PadLeftLoop:
	ld	wa, (xsp + 18)
	decm	1, (xsp + 18)
	cp	wa, 0:i3
	jr	gt, Sprintf_FFixed_PadLeftSpace
Sprintf_FFixed_EmitSign:
	cp	iz, 0:i3
	jr	z, Sprintf_FFixed_SignPlus
	pushw	0x2d
	jr	Sprintf_FFixed_SignEmit
Sprintf_FFixed_SignPlus:
	ld	wa, (xsp + 16)
	bit	0, wa
	jr	z, Sprintf_FFixed_SignSpace
	pushw	0x2b
	jr	Sprintf_FFixed_SignEmit
Sprintf_FFixed_SignSpace:
	ld	wa, (xsp + 16)
	bit	2, wa
	jr	z, Sprintf_FFixed_ZeroFill
	pushw	0x20
Sprintf_FFixed_SignEmit:
	ld	xwa, (xsp + 14)
; Sprintf_Octal_ZeroFill is kept at this address only for shared/positional_labels.s; v10's Sprintf_Octal_ZeroFill is the code at 0xFF1048
Sprintf_Octal_ZeroFill:
	call	(xwa)
	inc	2, xsp
	incw	1, (0x3c222:24)
Sprintf_FFixed_ZeroFill:
	ld	wa, (xsp + 16)
	bit	1, wa
	jr	nz, Sprintf_FFixed_LeadDigit
	cpw	(0x3c220:24), 48
	jr	z, Sprintf_FFixed_ZeroFillLoop
	jr	Sprintf_FFixed_LeadDigit
Sprintf_FFixed_ZeroFillBody:
	pushw	0x30
	ld	xwa, (xsp + 14)
	call	(xwa)
	inc	2, xsp
	incw	1, (0x3c222:24)
Sprintf_FFixed_ZeroFillLoop:
	ld	wa, (xsp + 18)
	decm	1, (xsp + 18)
	cp	wa, 0:i3
	jr	gt, Sprintf_FFixed_ZeroFillBody
Sprintf_FFixed_LeadDigit:
	ld	xwa, (xsp + 22)
	cp	(xwa), 0x39
	jr	le, Sprintf_FFixed_LeadDigitZero
	cpw	(xsp + 26), 0x0
	jr	lt, Sprintf_FFixed_LeadDigitZero
	pushw	0x31
	ld	xwa, (xsp + 14)
	call	(xwa)
	inc	2, xsp
	ld	xwa, (xsp + 22)
	ld	(xwa), 0x30
	jr	Sprintf_FFixed_LeadDigitDone
Sprintf_FFixed_LeadDigitZero:
	cpw	(xsp + 26), 0x0
	jr	gt, Sprintf_FFixed_IntegerDigits
	pushw	0x30
	ld	xwa, (xsp + 14)
	call	(xwa)
	inc	2, xsp
Sprintf_FFixed_LeadDigitDone:
	incw	1, (0x3c222:24)
Sprintf_FFixed_IntegerDigits:
	ld	iz, 0:i3
	jr	Sprintf_FFixed_IntDigitLoop
Sprintf_FFixed_IntDigitOutput:
	ld	xwa, (xsp + 22)
	ld	a, (xwa+iz)
	exts	wa
	pushw	wa
	ld	xwa, (xsp + 14)
	call	(xwa)
	inc	2, xsp
	incw	1, (0x3c222:24)
	inc	1, iz
Sprintf_FFixed_IntDigitLoop:
	ld	wa, (xsp + 4)
	inc	1, wa
	cp	iz, wa
	jr	ge, Sprintf_FFixed_IntZeroLoop
	ld	wa, (xsp + 2)
	decm	1, (xsp + 2)
	cp	wa, 0:i3
	jr	gt, Sprintf_FFixed_IntDigitOutput
	jr	Sprintf_FFixed_IntZeroLoop
Sprintf_FFixed_IntZeroFill:
	pushw	0x30
	ld	xwa, (xsp + 14)
	call	(xwa)
	inc	2, xsp
	incw	1, (0x3c222:24)
Sprintf_FFixed_IntZeroLoop:
	ld	wa, (xsp + 2)
	decm	1, (xsp + 2)
	cp	wa, 0:i3
	jr	gt, Sprintf_FFixed_IntZeroFill
	ld	wa, (xsp + 16)
	bit	3, wa
	jr	nz, Sprintf_FFixed_DecimalPoint
	cpw	(xsp + 20), 0x0
	jr	z, Sprintf_FFixed_FracLeadZeroLoop
Sprintf_FFixed_DecimalPoint:
	pushw	0x2e
	ld	xwa, (xsp + 14)
	call	(xwa)
	inc	2, xsp
	incw	1, (0x3c222:24)
	jr	Sprintf_FFixed_FracLeadZeroLoop
Sprintf_FFixed_FracLeadZeros:
	ld	wa, (xsp + 26)
	add	wa, 0x1
	jr	nz, Sprintf_FFixed_FracLeadZeroBody
	ld	xwa, (xsp + 22)
	cp	(xwa), 0x39
	jr	le, Sprintf_FFixed_FracLeadZeroBody
	pushw	0x31
	ld	xwa, (xsp + 14)
	call	(xwa)
	inc	2, xsp
	ld	xwa, (xsp + 22)
	ld	(xwa), 0x30
	jr	Sprintf_FFixed_FracLeadZeroDone
Sprintf_FFixed_FracLeadZeroBody:
	pushw	0x30
	ld	xwa, (xsp + 14)
	call	(xwa)
	inc	2, xsp
Sprintf_FFixed_FracLeadZeroDone:
	incw	1, (0x3c222:24)
	incw	1, (xsp + 26)
Sprintf_FFixed_FracLeadZeroLoop:
	cpw	(xsp + 26), 0x0
	jr	ge, Sprintf_FFixed_FracDigits
	ld	wa, (xsp + 20)
	decm	1, (xsp + 20)
	cp	wa, 0:i3
	jr	nz, Sprintf_FFixed_FracLeadZeros
Sprintf_FFixed_FracDigits:
	ld	wa, (xsp + 4)
	inc	1, wa
	cp	iz, wa
	jr	lt, Sprintf_FFixed_FracDigitLoop
	jr	Sprintf_FFixed_FracTrailLoop
Sprintf_FFixed_FracDigitOutput:
	ld	xwa, (xsp + 22)
	ld	a, (xwa+iz)
	exts	wa
	pushw	wa
	ld	xwa, (xsp + 14)
	call	(xwa)
	inc	2, xsp
	incw	1, (0x3c222:24)
	inc	1, iz
Sprintf_FFixed_FracDigitLoop:
	ld	wa, (xsp + 4)
	inc	1, wa
	cp	iz, wa
	jr	ge, Sprintf_FFixed_FracTrailLoop
	ld	wa, (xsp + 20)
	decm	1, (xsp + 20)
	cp	wa, 0:i3
	jr	gt, Sprintf_FFixed_FracDigitOutput
	jr	Sprintf_FFixed_FracTrailLoop
Sprintf_FFixed_FracTrailZeros:
	pushw	0x30
	ld	xwa, (xsp + 14)
	call	(xwa)
	inc	2, xsp
	incw	1, (0x3c222:24)
Sprintf_FFixed_FracTrailLoop:
	ld	wa, (xsp + 20)
	decm	1, (xsp + 20)
	cp	wa, 0:i3
	jr	gt, Sprintf_FFixed_FracTrailZeros
	ld	wa, (xsp + 16)
	bit	1, wa
	jr	nz, Sprintf_FFixed_PadRightLoop
	jr	Sprintf_FFixed_Return
Sprintf_FFixed_PadRightSpace:
	pushw	0x20
	ld	xwa, (xsp + 14)
	call	(xwa)
	inc	2, xsp
	incw	1, (0x3c222:24)
Sprintf_FFixed_PadRightLoop:
	ld	wa, (xsp + 18)
	decm	1, (xsp + 18)
	cp	wa, 0:i3
	jr	gt, Sprintf_FFixed_PadRightSpace
Sprintf_FFixed_Return:
	popw	iz
	inc	4, xsp
	ret
Sprintf_FFixed_DataTable:
	ld	xwa, (xsp+4)
Sprintf_FormatFFixed_Entry:
	.byte	0x80, 0x3f, 0x00
	jr	nz, Sprintf_FormatFFixed_Skip
	ld	hl, 1:i3
	ret
Sprintf_FormatFFixed_Skip:
	cp	(xwa+), 48
	jr	z, Sprintf_FormatFFixed_Entry
	ld	hl, 0:i3
	ret
Sprintf_FormatEScientific:
	dec	2, xsp
	push	xiz
	ldw	(xsp + 4), 0xf
	ld	wa, (xsp + 16)
	bit	4, wa
	jr	nz, Sprintf_ESci_ApplyDefaults
	ldw	(xsp + 20), 0x6
Sprintf_ESci_ApplyDefaults:
	ld	a, (xsp + 10)
	extz	wa
	lda	xbc, (CType_ClassTable:24)
	lda	xbc, (xbc+wa)
	bitm	1, (xbc)
	jr	z, Sprintf_ESci_SpecNoUpperCase
	ld	a, (xsp + 10)
	sub	a, 0x20
	jr	Sprintf_ESci_CheckSpecG
Sprintf_ESci_SpecNoUpperCase:
	ld	a, (xsp + 10)
Sprintf_ESci_CheckSpecG:
	cp	a, 0x47
	jr	nz, Sprintf_ESci_SetDigitCount
	cpw	(xsp + 20), 0x0
	jr	z, Sprintf_ESci_SetDigitCount
	decm	1, (xsp + 20)
Sprintf_ESci_SetDigitCount:
	ld	wa, (xsp + 20)
	inc	1, wa
	ldfr_werp	WA, 0xfa
	ld	wa, (xsp + 16)
	bit	7, wa
	jr	z, Sprintf_ESci_RoundCheck
	ldw	(xsp + 4), 0x12
Sprintf_ESci_RoundCheck:
	ld	de, (xsp + 4)
	inc	1, de
	ldto_werp	WA, 0xfa
	cp	wa, de
	jr	ge, Sprintf_ESci_AfterRound
	ldto_werp	DE, 0xfa
	dec1w_erp	0xfa
	ld	xwa, (xsp + 22)
	cp	(xwa+de), 0x34
	jr	gt, Sprintf_ESci_RoundLoop
	jr	Sprintf_ESci_AfterRound
Sprintf_ESci_RoundCarry:
	ld	xwa, (xsp + 22)
	stib_ind	0x07, 0xe0, 0xfa, 0x30
	dec1w_erp	0xfa
Sprintf_ESci_RoundLoop:
	ld	xwa, (xsp + 22)
	inc_srib	1, 0x07, 0xe0, 0xfa
	cpiw_erp	0xfa, 0
	jr	le, Sprintf_ESci_AfterRound
	cpib_sri	0x07, 0xe0, 0xfa, 0x39
	jr	gt, Sprintf_ESci_RoundCarry
Sprintf_ESci_AfterRound:
	bitm	1, (xbc)
	jr	z, Sprintf_ESci_AfterRound_NoCase
	ld	a, (xsp + 10)
	sub	a, 0x20
	jr	Sprintf_ESci_StripTrailZeros
Sprintf_ESci_AfterRound_NoCase:
	ld	a, (xsp + 10)
Sprintf_ESci_StripTrailZeros:
	cp	a, 0x47
	jr	nz, Sprintf_ESci_ComputeOutputLen
	ld	wa, (xsp + 16)
	bit	3, wa
	jr	nz, Sprintf_ESci_ComputeOutputLen
	ld	wa, (xsp + 20)
	ldfr_werp	WA, 0xfa
	jr	Sprintf_ESci_StripCheck
Sprintf_ESci_StripLoop:
	dec1w_erp	0xfa
	decm	1, (xsp + 20)
Sprintf_ESci_StripCheck:
	cpiw_erp	0xfa, 0
	jr	le, Sprintf_ESci_ComputeOutputLen
	ld	xwa, (xsp + 22)
	cpib_sri	0x07, 0xe0, 0xfa, 0x30
	jr	z, Sprintf_ESci_StripLoop
Sprintf_ESci_ComputeOutputLen:
	decm	5, (xsp + 18)
	ld	wa, (xsp + 16)
	bit	4, wa
	jr	z, Sprintf_ESci_CheckPrecZero
	cpw	(xsp + 20), 0x0
	jr	z, Sprintf_ESci_AdjustForSign
Sprintf_ESci_CheckPrecZero:
	decm	1, (xsp + 18)
Sprintf_ESci_AdjustForSign:
	ld	iz, (xsp + 28)
	cp	iz, 0:i3
	jr	nz, Sprintf_ESci_AdjustForSign2
	ld	wa, (xsp + 16)
	and	wa, 0x5
	jr	z, Sprintf_ESci_ComputePadding
Sprintf_ESci_AdjustForSign2:
	decm	1, (xsp + 18)
Sprintf_ESci_ComputePadding:
	ld	wa, (xsp + 20)
	sub	(xsp + 18), wa
	jr	ge, Sprintf_ESci_PadLeftCheck
	ldw	(xsp + 18), 0x0
Sprintf_ESci_PadLeftCheck:
	ld	wa, (xsp + 16)
	bit	1, wa
	jr	nz, Sprintf_ESci_EmitSign
	cpw	(0x3c220:24), 32
	jr	z, Sprintf_ESci_PadLeftLoop
	jr	Sprintf_ESci_EmitSign
Sprintf_ESci_PadLeftSpace:
	pushw	0x20
	ld	xwa, (xsp + 14)
	call	(xwa)
	inc	2, xsp
	incw	1, (0x3c222:24)
Sprintf_ESci_PadLeftLoop:
	decm	1, (xsp + 18)
	cpw	(xsp + 18), 0x0
	jr	gt, Sprintf_ESci_PadLeftSpace
Sprintf_ESci_EmitSign:
	cp	iz, 0:i3
	jr	z, Sprintf_ESci_SignPlus
	pushw	0x2d
	jr	Sprintf_ESci_SignEmit
Sprintf_ESci_SignPlus:
	ld	wa, (xsp + 16)
	bit	0, wa
	jr	z, Sprintf_ESci_SignSpace
	pushw	0x2b
	jr	Sprintf_ESci_SignEmit
Sprintf_ESci_SignSpace:
	ld	wa, (xsp + 16)
	bit	2, wa
	jr	z, Sprintf_ESci_ZeroFill
	pushw	0x20
Sprintf_ESci_SignEmit:
	ld	xwa, (xsp + 14)
	call	(xwa)
	inc	2, xsp
	incw	1, (0x3c222:24)
Sprintf_ESci_ZeroFill:
	ld	wa, (xsp + 16)
	bit	1, wa
	jr	nz, Sprintf_ESci_LeadDigit
	cpw	(0x3c220:24), 48
	jr	z, Sprintf_ESci_ZeroFillLoop
	jr	Sprintf_ESci_LeadDigit
Sprintf_ESci_ZeroFillBody:
	pushw	0x30
	ld	xwa, (xsp + 14)
	call	(xwa)
	inc	2, xsp
	incw	1, (0x3c222:24)
Sprintf_ESci_ZeroFillLoop:
	decm	1, (xsp + 18)
	cpw	(xsp + 18), 0x0
	jr	gt, Sprintf_ESci_ZeroFillBody
Sprintf_ESci_LeadDigit:
	ld	xwa, (xsp + 22)
	cp	(xwa), 0x39
	jr	le, Sprintf_ESci_LeadDigitNormal
	pushw	0x31
	ld	xwa, (xsp + 14)
	call	(xwa)
	inc	2, xsp
	ld	xwa, (xsp + 22)
	ld	(xwa), 0x30
	ldiw_erp	0xfa, 0
	incw	1, (0x3c222:24)
	cpw	(xsp + 26), 0x0
	jr	ge, Sprintf_ESci_Overflow_DecExp
	incw	1, (xsp + 26)
	jr	Sprintf_ESci_DecimalPoint
Sprintf_ESci_Overflow_DecExp:
	decm	1, (xsp + 26)
	jr	Sprintf_ESci_DecimalPoint
Sprintf_ESci_LeadDigitNormal:
	ld	xwa, (xsp + 22)
	ld	a, (xwa)
	exts	wa
	pushw	wa
	ld	xwa, (xsp + 14)
	call	(xwa)
	inc	2, xsp
	incw	1, (0x3c222:24)
	ldiw_erp	0xfa, 1
Sprintf_ESci_DecimalPoint:
	cpw	(xsp + 20), 0x0
	jr	nz, Sprintf_ESci_DecimalPointEmit
	ld	wa, (xsp + 16)
	bit	3, wa
	jr	z, Sprintf_ESci_MantissaDigits
Sprintf_ESci_DecimalPointEmit:
	pushw	0x2e
	ld	xwa, (xsp + 14)
	call	(xwa)
	inc	2, xsp
	incw	1, (0x3c222:24)
Sprintf_ESci_MantissaDigits:
	ld	c, (xsp + 10)
	extz	bc
	lda	xwa, (CType_ClassTable:24)
	bit	1, (xwa+bc)
	jr	z, Sprintf_ESci_MantissaNoCase
	ld	a, (xsp + 10)
	sub	a, 0x20
	jr	Sprintf_ESci_CheckGTrim
Sprintf_ESci_MantissaNoCase:
	ld	a, (xsp + 10)
Sprintf_ESci_CheckGTrim:
	cp	a, 0x47
	jr	nz, Sprintf_ESci_OutputMantissa
	cpw	(xsp + 20), 0x0
	jr	nz, Sprintf_ESci_OutputMantissa
	cpw	(xsp + 26), 0x1
	jrl	z, Sprintf_ESci_Return
Sprintf_ESci_OutputMantissa:
	ld	bc, (xsp + 4)
	inc	1, bc
	ldto_werp	WA, 0xfa
	cp	wa, bc
	jr	lt, Sprintf_ESci_MantDigitLoop
	jr	Sprintf_ESci_MantTrailLoop
Sprintf_ESci_MantDigitOutput:
	ld	xwa, (xsp + 22)
	ld	a, (xwa+qiz)
	exts	wa
	pushw	wa
	ld	xwa, (xsp + 14)
	call	(xwa)
	inc	2, xsp
	incw	1, (0x3c222:24)
	inc1w_erp	0xfa
Sprintf_ESci_MantDigitLoop:
	ld	bc, (xsp + 4)
	inc	1, bc
	ldto_werp	WA, 0xfa
	cp	wa, bc
	jr	ge, Sprintf_ESci_MantTrailLoop
	ld	wa, (xsp + 20)
	decm	1, (xsp + 20)
	cp	wa, 0:i3
	jr	gt, Sprintf_ESci_MantDigitOutput
	jr	Sprintf_ESci_MantTrailLoop
Sprintf_ESci_MantTrailZeros:
	pushw	0x30
	ld	xwa, (xsp + 14)
	call	(xwa)
	inc	2, xsp
	incw	1, (0x3c222:24)
Sprintf_ESci_MantTrailLoop:
	ld	wa, (xsp + 20)
	decm	1, (xsp + 20)
	cp	wa, 0:i3
	jr	gt, Sprintf_ESci_MantTrailZeros
	decm	1, (xsp + 26)
	ld	wa, (xsp + 26)
	exts	xwa
	push	xwa
	ld	xwa, (xsp + 26)
	push	xwa
	calr	Sprintf_IntToStr
	ld	xwa, (xsp + 30)
	push	xwa
	call	Strlen
	lda	xsp, (xsp + 12)
	ld	iz, hl
	ld	c, (xsp + 10)
	extz	bc
	lda	xwa, (CType_ClassTable:24)
	bit	1, (xwa+bc)
	jr	z, Sprintf_ESci_ExpNoCase
	ld	a, (xsp + 10)
	sub	a, 0x20
	jr	Sprintf_ESci_CheckExpG
Sprintf_ESci_ExpNoCase:
	ld	a, (xsp + 10)
Sprintf_ESci_CheckExpG:
	cp	a, 0x47
	jr	nz, Sprintf_ESci_ExpLetterNormal
	ld	a, (xsp + 10)
	dec	2, a
	jr	Sprintf_ESci_EmitExpLetter
Sprintf_ESci_ExpLetterNormal:
	ld	a, (xsp + 10)
Sprintf_ESci_EmitExpLetter:
	exts	wa
	pushw	wa
	ld	xwa, (xsp + 14)
	call	(xwa)
	inc	2, xsp
	incw	1, (0x3c222:24)
	cpw	(xsp + 26), 0x0
	jr	ge, Sprintf_ESci_ExpSignPositive
	pushw	0x2d
	jr	Sprintf_ESci_EmitExpSign
Sprintf_ESci_ExpSignPositive:
	pushw	0x2b
Sprintf_ESci_EmitExpSign:
	ld	xwa, (xsp + 14)
	call	(xwa)
	inc	2, xsp
	incw	1, (0x3c222:24)
	ldfr_werp	IZ, 0xfa
	jr	Sprintf_ESci_ExpLeadZeroLoop
Sprintf_ESci_ExpLeadZeros:
	pushw	0x30
	ld	xwa, (xsp + 14)
	call	(xwa)
	inc	2, xsp
	incw	1, (0x3c222:24)
Sprintf_ESci_ExpLeadZeroLoop:
	ldto_werp	WA, 0xfa
	inc1w_erp	0xfa
	cp	wa, 3:i3
	jr	lt, Sprintf_ESci_ExpLeadZeros
	jr	Sprintf_ESci_ExpDigitLoop
Sprintf_ESci_ExpDigitOutput:
	dec	1, iz
	ld	xwa, (xsp + 22)
	ld	a, (xwa+iz)
	exts	wa
	pushw	wa
	ld	xwa, (xsp + 14)
	call	(xwa)
	inc	2, xsp
	incw	1, (0x3c222:24)
Sprintf_ESci_ExpDigitLoop:
	cp	iz, 0:i3
	jr	nz, Sprintf_ESci_ExpDigitOutput
	ld	wa, (xsp + 16)
	bit	1, wa
	jr	nz, Sprintf_ESci_PadRightLoop
	jr	Sprintf_ESci_Return
Sprintf_ESci_PadRightSpace:
	pushw	0x20
	ld	xwa, (xsp + 14)
	call	(xwa)
	inc	2, xsp
	incw	1, (0x3c222:24)
Sprintf_ESci_PadRightLoop:
	decm	1, (xsp + 18)
	cpw	(xsp + 18), 0x0
	jr	gt, Sprintf_ESci_PadRightSpace
Sprintf_ESci_Return:
	pop	xiz
	inc	2, xsp
	ret
Sprintf_FormatGGeneral:
	lda	xsp, (xsp - 16)
	push	xiz
	ld	iz, 0:i3
	ldw	(xsp + 6), 0xf
	ldw	(xsp + 8), 0x8
	pushw	0x20
	pushw	0x0
	pushw	0x3
	pushw	0xc224
	call	Memset
	inc	8, xsp
	ldiw_erp	0xfa, 0
Sprintf_GGen_ClearArrays:
	ldto_werp	BC, 0xfa
	add	bc, bc
	lda	xde, (0x03c284:24)
	lda	xwa, (0x03c244:24)
	ldw	(xwa+bc), 0x0000
	ldw	(xde+bc), 0x0000
	inc1w_erp	0xfa
	cp_erpw	0xfa, 0x20, 0x00
	jr	lt, Sprintf_GGen_ClearArrays
	ld	wa, (xsp + 32)
	bit	7, wa
	jr	z, Sprintf_GGen_CheckLongDouble
	ldw	(xsp + 6), 0x12
	ldw	(xsp + 8), 0xa
Sprintf_GGen_CheckLongDouble:
	ldiw_erp	0xfa, 0
	cpw	(xsp + 8), 0x0
	jr	le, Sprintf_GGen_CheckSign
Sprintf_GGen_LoadDigits:
	lda	xwa, (xsp + 10)
	ld	bc, (xsp + 8)
	dec	1, bc
	subw_erp	BC, 0xfa
	extz	xbc
	add	xbc, (xsp + 24)
	ld	c, (xbc)
	ld	(xwa+qiz), c
	inc1w_erp	0xfa
	ldto_werp	WA, 0xfa
	cp	wa, (xsp + 8)
	jr	lt, Sprintf_GGen_LoadDigits
Sprintf_GGen_CheckSign:
	lda	xde, (xsp + 10)
	bitm	7, (xde)
	jr	z, Sprintf_GGen_Negative
	ld	wa, 1:i3
	jr	Sprintf_GGen_ExtractExponent
Sprintf_GGen_Negative:
	ld	wa, 0:i3
Sprintf_GGen_ExtractExponent:
	ld	xbc, (xsp + 38)
	ld	(xbc), wa
	lda	xbc, (xde + 1)
	ld	wa, (xsp + 32)
	bit	7, wa
	jr	z, Sprintf_GGen_NormalExp
	cp	(xde), 0x0
	jr	nz, Sprintf_GGen_LongDoubleExp
	cp	(xbc), 0x0
	jr	z, Sprintf_GGen_NormalExp
Sprintf_GGen_LongDoubleExp:
	ld	l, (xbc)
	extz	hl
	ldw	wa, 0x8
	ldw	bc, 0x4000
	jr	Sprintf_GGen_ComputeDecExp
Sprintf_GGen_NormalExp:
	cp	(xde), 0x0
	jr	nz, Sprintf_GGen_NonZero
	cp	(xbc), 0x0
	jr	z, Sprintf_GGen_DecimalExponent
Sprintf_GGen_NonZero:
	ld	l, (xbc)
	and	l, 0xf0
	extz	hl
	sra	hl, 4
	ld	wa, 4:i3
	ldw	bc, 0x400
Sprintf_GGen_ComputeDecExp:
	ld	e, (xde)
	res	7, e
	extz	de
	and	a, 0xf
	jr	z, Sprintf_GGen_ShiftMantissa
	slaa	de
Sprintf_GGen_ShiftMantissa:
	ld	iz, de
	add	iz, hl
	sub	iz, bc
Sprintf_GGen_DecimalExponent:
	pushw	iz
	calr	Sprintf_DecimalExponent
	inc	2, xsp
	ld	(xsp + 4), hl
	cp	iz, 0:i3
	jr	ge, Sprintf_GGen_AdjustNegExp
	decm	1, (xsp + 4)
Sprintf_GGen_AdjustNegExp:
	ld	wa, (xsp + 32)
	bit	7, wa
	jr	z, Sprintf_GGen_NormalDigits
	ldiw_erp	0xfa, 2
Sprintf_GGen_LongDoubleDigits:
	lda	xwa, (xsp + 10)
	ld	a, (xwa+qiz)
	and	a, 0xff
	ldto_werp	DE, 0xfa
	add	de, de
	lda	xbc, (0x03c240:24)
	extz	wa
	ld	(xbc+de), wa
	inc1w_erp	0xfa
	cp_erpw	0xfa, 0x0a, 0x00
	jr	lt, Sprintf_GGen_LongDoubleDigits
	jr	Sprintf_GGen_NormalizeArray
Sprintf_GGen_NormalDigits:
	ld	ix, 0:i3
	ldiw_erp	0xfa, 0
Sprintf_GGen_FindLeadDigit:
	lda	xbc, (xsp + 10)
	cpib_sri	0x07, 0xe4, 0xfa, 0x00
	jr	z, Sprintf_GGen_FindLeadDone
	ld	ix, 1:i3
	jr	Sprintf_GGen_LoadDigitPairs
Sprintf_GGen_FindLeadDone:
	inc1w_erp	0xfa
	cp_erpw	0xfa, 0x08, 0x00
	jr	lt, Sprintf_GGen_FindLeadDigit
Sprintf_GGen_LoadDigitPairs:
	andmi8	(xbc + 1), 0xf
	ldiw_erp	0xfa, 1
Sprintf_GGen_DigitPairLoop:
	ld	a, (xbc+qiz)
	and	a, 0xff
	ldto_werp	HL, 0xfa
	add	hl, hl
	dec	2, hl
	lda	xde, (0x03c244:24)
	extz	wa
	ld	(xde+hl), wa
; (pre-port v7 note about the bytes at 0xFF1AC9:)
; Disassembled from the committed romslice (no source of any kind existed):
; llvm-mc round-trips these 3 B byte-exact as one instruction. v9/v10 open
; this label with "ld a,(xsp+10)" instead, so this fragment is NOT the
; routine's first instruction in this revision -- the label here just marks
; the nearest preceding symbol, not a verified entry point. Kept as a single
; verified instruction rather than an opaque blob.
	inc1w_erp	0xfa
	cp_erpw	0xfa, 0x08, 0x00
	jr	lt, Sprintf_GGen_DigitPairLoop
	cp	ix, 0:i3
	jr	z, Sprintf_GGen_NormalizeArray
	ormi16	(xde), 0x10
Sprintf_GGen_NormalizeArray:
	pushm	(xsp + 8)
	pushw	0x3
	pushw	0xc244
	calr	Sprintf_CountLeadingZeros
	inc	6, xsp
	ldiw_erp	0xfa, 0
	cp	iz, 0:i3
	jr	le, Sprintf_GGen_NegativeExpCheck
	cpw	(xsp + 4), 0x0
	jr	le, Sprintf_GGen_PositiveExpDone
Sprintf_GGen_MultiplyLoop:
	pushw	0x3
	pushw	0xc244
	calr	Sprintf_DivideDigitsByTen
	pushm	(xsp + 12)
	pushw	0x3
	pushw	0xc244
	calr	Sprintf_CountLeadingZeros
	lda	xsp, (xsp + 10)
	sub	iz, hl
	inc1w_erp	0xfa
	ldto_werp	WA, 0xfa
	cp	wa, (xsp + 4)
	jr	lt, Sprintf_GGen_MultiplyLoop
Sprintf_GGen_PositiveExpDone:
	pushm	(xsp + 6)
	ld	wa, 6:i3
	sub	wa, iz
	pushw	wa
	pushw	0x3
	pushw	0xc244
	jr	Sprintf_GGen_FinalShift
Sprintf_GGen_DivideLoop:
	push	xbc
	calr	Sprintf_MultiplyDigitsByTen
	pushm	(xsp + 12)
	pushw	0x3
	pushw	0xc244
	calr	Sprintf_CountTrailingZeros
	lda	xsp, (xsp + 10)
	add	iz, hl
	inc1w_erp	0xfa
Sprintf_GGen_NegativeExpCheck:
	ld	de, (xsp + 4)
	neg	de
	lda	xbc, (0x03c244:24)
	ldto_werp	WA, 0xfa
	cp	wa, de
	jr	lt, Sprintf_GGen_DivideLoop
	pushm	(xsp + 6)
	ld	wa, 6:i3
	sub	wa, iz
	pushw	wa
	push	xbc
Sprintf_GGen_FinalShift:
	calr	Sprintf_ShiftDigitArray
	inc	8, xsp
	ldiw_erp	0xfa, 1
Sprintf_GGen_RoundLoop:
	pushw_erp	0xfa
	ldto_werp	BC, 0xfa
	add	bc, bc
	lda	xwa, (0x03c244:24)
	pushw	(xwa+bc)
	calr	Sprintf_NormalizeDigits
	inc	4, xsp
	inc1w_erp	0xfa
	cp_erpw	0xfa, 0x09, 0x00
	jr	lt, Sprintf_GGen_RoundLoop
	ld	de, 0:i3
	lda	xbc, (0x03c244:24)
	ld	xhl, (xsp + 28)
	ld	wa, (xbc)
	cp	wa, 0x9
	jr	ule, Sprintf_GGen_ExtractResult
	ld	de, 1:i3
	extz	xwa
	div	wa, 0xa
	ld	(xhl), a
	incw	1, (xsp + 4)
Sprintf_GGen_ExtractResult:
	ld	ix, de
	inc	1, de
	ld	wa, (xbc)
	extz	xwa
	div	wa, 0xa
	ldto_werp	WA, 0xe2
	ld	(xhl+ix), a
	incw	1, (xsp + 4)
	ldiw_erp	0xfa, 1
	jr	Sprintf_GGen_CopyLoop
Sprintf_GGen_CopyDigits:
	ld	bc, de
	inc	1, de
	lda	xwa, (0x03c224:24)
	ld	a, (xwa+qiz)
	ld	(xhl+bc), a
	inc1w_erp	0xfa
Sprintf_GGen_CopyLoop:
	ld	bc, (xsp + 6)
	inc	2, bc
	ldto_werp	WA, 0xfa
	cp	wa, bc
	jr	lt, Sprintf_GGen_CopyDigits
	ld	de, (xsp + 6)
	inc	1, de
	lda	xbc, (xhl+de)
	cp	(xbc), 0x5
	jr	c, Sprintf_GGen_HandleCarry
	ld	wa, (xsp + 6)
	inc	1, (xhl+wa)
Sprintf_GGen_HandleCarry:
	ld	(xbc), 0x0
	ld	wa, (xsp + 6)
	ldfr_werp	WA, 0xfa
	jr	Sprintf_GGen_CarryCheck
Sprintf_GGen_CarryLoop:
	ldto_werp	BC, 0xfa
	dec	1, bc
	inc	1, (xhl+bc)
	ld	(xwa), 0x0
	dec1w_erp	0xfa
Sprintf_GGen_CarryCheck:
	cpiw_erp	0xfa, 0
	jr	z, Sprintf_GGen_ConvertToAscii
	lda	xwa, (xhl+qiz)
	cp	(xwa), 0x9
	jr	ugt, Sprintf_GGen_CarryLoop
Sprintf_GGen_ConvertToAscii:
	ldiw_erp	0xfa, 0
	jr	Sprintf_GGen_AsciiDone
Sprintf_GGen_AsciiLoop:
	or_srib_im	0x07, 0xec, 0xfa, 0x30
	inc1w_erp	0xfa
Sprintf_GGen_AsciiDone:
	ldto_werp	WA, 0xfa
	cp	wa, de
	jr	lt, Sprintf_GGen_AsciiLoop
	ld	xbc, (xsp + 34)
	ld	wa, (xsp + 4)
	ld	(xbc), wa
	pop	xiz
	lda	xsp, (xsp + 16)
	ret
Sprintf_ShiftDigitArray:
	dec	8, xsp
	pushw	iz
	ld	iz, 0:i3
	ld	wa, 0:i3
	ld	hl, (xsp + 18)
	cp	hl, 0:i3
	jr	le, Sprintf_Shift_SetupLoop
Sprintf_Shift_BuildMask:
	add	wa, wa
	set	0, wa
	inc	1, iz
	cp	iz, hl
	jr	lt, Sprintf_Shift_BuildMask
Sprintf_Shift_SetupLoop:
	ld	iz, (xsp + 20)
	dec	1, iz
	ld	xiy, (xsp + 14)
	cp	iz, 0:i3
	jr	le, Sprintf_Shift_LastEntry
	ld	(xsp + 4), wa
	ldw	(xsp + 2), 0x8
	sub	(xsp + 2), hl
	ld	wa, iz
	exts	xwa
	add	xwa, xwa
	ld	xix, xwa
Sprintf_Shift_Loop:
	ld	(xsp + 6), xix
	add	(xsp + 6), xiy
	ld	xbc, (xsp + 6)
	ld	de, (xbc)
	ld	wa, hl
	and	a, 0xf
	jr	z, Sprintf_Shift_ApplyShift
	srla	de
Sprintf_Shift_ApplyShift:
	ld	(xbc), de
	ld	xbc, xix
	ld	xwa, 2:i3
	sub	xbc, xwa
	add	xbc, xiy
	ld	wa, (xsp + 4)
	and	wa, (xbc)
	ld	bc, wa
	ld	wa, (xsp + 2)
	and	a, 0xf
	jr	z, Sprintf_Shift_ApplyCarry
	slla	bc
Sprintf_Shift_ApplyCarry:
	ld	xwa, (xsp + 6)
	or	(xwa), bc
	dec	1, iz
	dec	2, xix
	cp	iz, 0:i3
	jr	gt, Sprintf_Shift_Loop
Sprintf_Shift_LastEntry:
	ld	bc, (xiy)
	ld	wa, hl
	and	a, 0xf
	jr	z, Sprintf_Shift_LastShift
	srla	bc
Sprintf_Shift_LastShift:
	ld	(xiy), bc
	popw	iz
	inc	8, xsp
	ret
Sprintf_PropagateCarry:
	ld	xiy, (xsp + 4)
	andmi16	(xiy), 0xff
	ld	ix, 1:i3
	ld	hl, (xsp + 8)
	add	hl, hl
	jr	Sprintf_PropCarry_Check
Sprintf_PropCarry_Loop:
	ld	de, ix
	exts	xde
	add	xde, xde
	add	xde, xiy
	ld	wa, (xsp + 10)
	ld	bc, (xde)
	and	a, 0xf
	jr	z, Sprintf_PropCarry_Store
	slla	bc
Sprintf_PropCarry_Store:
	ld	(xde), bc
	ld	wa, ix
	dec	1, wa
	exts	xwa
	add	xwa, xwa
	ld	xbc, xwa
	add	xbc, xiy
	ld	wa, (xde)
	srl	wa, 8
	add	(xbc), wa
	andmi16	(xde), 0xff
	inc	1, ix
Sprintf_PropCarry_Check:
	cp	ix, hl
	jr	lt, Sprintf_PropCarry_Loop
	ret
Sprintf_NormalizeDigits:
	pushw	iz
	lda	xde, (0x03c284:24)
	ld	xwa, xde
	lda	xbc, (xde + 18)
Sprintf_Normalize_ClearLoop:
	ldw	(xwa+), 0x0000
	cp	xwa, xbc
	jr	c, Sprintf_Normalize_ClearLoop
	ld	wa, (xsp + 6)
	ld	(xde + 16), wa
	ld	iz, 0:i3
Sprintf_Normalize_MainLoop:
	lda	xwa, (0x03c284:24)
	cpw	(xwa), 0x0
	jr	nz, Sprintf_Normalize_ExtractDigit
	cpw	(xwa + 2), 0x0
	jr	nz, Sprintf_Normalize_ExtractDigit
	cpw	(xwa + 4), 0x0
	jr	nz, Sprintf_Normalize_ExtractDigit
	cpw	(xwa + 6), 0x0
	jr	nz, Sprintf_Normalize_ExtractDigit
	cpw	(xwa + 8), 0x0
	jr	nz, Sprintf_Normalize_ExtractDigit
	cpw	(xwa + 10), 0x0
	jr	nz, Sprintf_Normalize_ExtractDigit
	cpw	(xwa + 12), 0x0
	jr	nz, Sprintf_Normalize_ExtractDigit
	cpw	(xwa + 14), 0x0
	jr	nz, Sprintf_Normalize_ExtractDigit
	cpw	(xwa + 16), 0x0
	jr	nz, Sprintf_Normalize_ExtractDigit
	jr	Sprintf_Normalize_Done
Sprintf_Normalize_MultiplyTen:
	inc	1, iz
	calr	Sprintf_MultiplyBCDByTen
Sprintf_Normalize_ExtractDigit:
	ldw	wa, 0x8
	sub	wa, (xsp + 8)
	add	wa, wa
	lda	xbc, (0x03c284:24)
	ld	wa, (xbc+wa)
	cp	wa, 0:i3
	jr	z, Sprintf_Normalize_MultiplyTen
	pushw	iz
	pushw	wa
	calr	Sprintf_InsertCarry
	inc	4, xsp
	ldw	bc, 0x8
	sub	bc, (xsp + 8)
	add	bc, bc
	lda	xwa, (0x03c284:24)
	ldw	(xwa+bc), 0x0000
	cp	iz, 0x20
	jrl	le, Sprintf_Normalize_MainLoop
Sprintf_Normalize_Done:
	popw	iz
	ret
Sprintf_InsertCarry:
	ld	de, (xsp + 6)
	cp	de, 0x20
	jr	ge, Sprintf_InsertCarry_Clamp
	lda	xbc, (0x03c224:24)
	ld	wa, (xsp + 4)
	add	(xbc+de), a
Sprintf_InsertCarry_Clamp:
	jr	Sprintf_InsertCarry_Check
Sprintf_InsertCarry_ClampLoop:
	dec	1, de
Sprintf_InsertCarry_Check:
	cp	de, 0x20
	jr	ge, Sprintf_InsertCarry_ClampLoop
	lda	xwa, (0x03c224:24)
	jr	Sprintf_InsertCarry_PropCheck
Sprintf_InsertCarry_Propagate:
	ld	bc, de
	dec	1, bc
	inc	1, (xwa+bc)
	ld	bc, de
	dec	1, de
	sub	(xwa+bc), 0x0a
Sprintf_InsertCarry_PropCheck:
	cp	(xwa+de), 0x0a
	ret	lt
	cp	de, 0:i3
	jr	gt, Sprintf_InsertCarry_Propagate
	ret
Sprintf_DivideDigitsByTen:
	ld	xwa, (xsp + 4)
	ld	xbc, xwa
	lda	xde, (xwa + 18)
Sprintf_DivByTen_Loop:
	ld	wa, (xbc)
	extz	xwa
	div	wa, 0xa
	ldto_werp	WA, 0xe2
	sll	wa, 8
	add	(xbc + 2), wa
	ld	wa, (xbc)
	extz	xwa
	div	wa, 0xa
	ld	(xbc+), WA
	cp	xbc, xde
	jr	c, Sprintf_DivByTen_Loop
	ret
Sprintf_MultiplyDigitsByTen:
	pushw	iz
	ld	ix, 0:i3
	ld	xbc, 0:i3
Sprintf_MulByTen_Loop:
	ld	xhl, (xsp + 6)
	ld	xde, xbc
	add	xde, xhl
	ld	wa, (xde)
	mul	wa, 0xa
	ld	(xde), wa
	cp	ix, 0:i3
	jr	z, Sprintf_MulByTen_Next
	ld	iz, ix
	jr	Sprintf_MulByTen_CarryCheck
Sprintf_MulByTen_CarryLoop:
	ld	iy, iz
	dec	1, iy
	exts	xiy
	add	xiy, xiy
	add	xiy, xhl
	srl	wa, 8
	add	(xiy), wa
	andmi16	(xde), 0xff
	dec	1, iz
Sprintf_MulByTen_CarryCheck:
	cp	iz, 0:i3
	jr	le, Sprintf_MulByTen_Next
	ld	de, iz
	exts	xde
	add	xde, xde
	add	xde, xhl
	ld	wa, (xde)
	cp	wa, 0xff
	jr	ugt, Sprintf_MulByTen_CarryLoop
Sprintf_MulByTen_Next:
	inc	1, ix
	inc	2, xbc
	cp	ix, 0x10
	jr	lt, Sprintf_MulByTen_Loop
	lda	xbc, (xhl + 30)
	ld	wa, (xbc)
	bit	7, wa
	jr	z, Sprintf_MulByTen_HandleOverflow
	incw	1, (xhl + 28)
Sprintf_MulByTen_HandleOverflow:
	ldw	(xbc), 0x0
	popw	iz
	ret
Sprintf_MultiplyBCDByTen:
	lda	xhl, (0x03c284:24)
	ld	xbc, xhl
	lda	xde, (xhl + 20)
Sprintf_BCDMul_Loop:
	cpw	(xbc), 0x0
	jr	z, Sprintf_BCDMul_Skip
	ld	wa, (xbc)
	mul	wa, 0xa
	ld	(xbc), wa
Sprintf_BCDMul_Skip:
	inc	2, xbc
	cp	xbc, xde
	jr	c, Sprintf_BCDMul_Loop
	lda	xbc, (xhl + 18)
	ldw	de, 0x12
Sprintf_BCDMul_CarryLoop:
	ld	wa, (xbc)
	cp	wa, 0x100
	jr	c, Sprintf_BCDMul_Next
	ld	ix, de
	dec	2, ix
	srl	wa, 8
	add	(xhl+ix), wa
	andmi16	(xbc), 0xff
Sprintf_BCDMul_Next:
	dec	2, de
	dec	2, xbc
	cp	de, 0:i3
	jr	gt, Sprintf_BCDMul_CarryLoop
	ret
Sprintf_CountLeadingZeros:
	dec	2, xsp
	pushw	iz
	ld	iz, 0:i3
	cpw	(xsp + 12), 0x0
	jr	le, Sprintf_LeadZero_CheckAllZero
Sprintf_LeadZero_Loop:
	ld	wa, iz
	exts	xwa
	add	xwa, xwa
	add	xwa, (xsp + 8)
	cpw	(xwa), 0x0
	jr	nz, Sprintf_LeadZero_CheckAllZero
	inc	1, iz
	cp	iz, (xsp + 12)
	jr	lt, Sprintf_LeadZero_Loop
Sprintf_LeadZero_CheckAllZero:
	cp	iz, (xsp + 12)
	jr	nz, Sprintf_LeadZero_CountBits
	ld	hl, 0:i3
	jr	Sprintf_LeadZero_Return
Sprintf_LeadZero_CountBits:
	ldw	(xsp + 2), 0x0
	jr	Sprintf_LeadZero_OuterLoop
Sprintf_LeadZero_ShiftLoop:
	ld	iz, 0:i3
	ld	xbc, (xsp + 8)
	jr	Sprintf_LeadZero_CheckBit7
Sprintf_LeadZero_ShiftBody:
	ld	xwa, (xsp + 8)
	mriw2	0x90, 0x7e
	inc	1, iz
Sprintf_LeadZero_CheckBit7:
	ld	wa, (xbc)
	bit	7, wa
	jr	nz, Sprintf_LeadZero_ApplyShift
	cp	iz, 0x8
	jr	lt, Sprintf_LeadZero_ShiftBody
Sprintf_LeadZero_ApplyShift:
	cp	iz, 0:i3
	jr	z, Sprintf_LeadZero_AccumShift
	pushw	iz
	pushm	(xsp + 14)
	ld	xwa, (xsp + 12)
	push	xwa
	calr	Sprintf_PropagateCarry
	inc	8, xsp
Sprintf_LeadZero_AccumShift:
	add	(xsp + 2), iz
Sprintf_LeadZero_OuterLoop:
	ld	xwa, (xsp + 8)
	ld	wa, (xwa)
	bit	7, wa
	jr	z, Sprintf_LeadZero_ShiftLoop
	ld	hl, (xsp + 2)
Sprintf_LeadZero_Return:
	popw	iz
	inc	2, xsp
	ret
Sprintf_CountTrailingZeros:
	pushw	iz
	ld	xde, (xsp + 6)
	ld	iz, 0:i3
	ld	bc, (xsp + 10)
	cp	bc, 0:i3
	jr	le, Sprintf_TrailZero_CheckAllZero
Sprintf_TrailZero_Loop:
	ld	wa, iz
	exts	xwa
	add	xwa, xwa
	add	xwa, xde
	cpw	(xwa), 0x0
	jr	nz, Sprintf_TrailZero_CheckAllZero
	inc	1, iz
	cp	iz, bc
	jr	lt, Sprintf_TrailZero_Loop
Sprintf_TrailZero_CheckAllZero:
	cp	iz, bc
	jr	nz, Sprintf_TrailZero_CountBits
	ld	hl, 0:i3
	jr	Sprintf_TrailZero_Return
Sprintf_TrailZero_CountBits:
	ld	hl, (xde)
	ld	iz, 0:i3
	jr	Sprintf_TrailZero_CheckHigh
Sprintf_TrailZero_ShiftLoop:
	srl	hl, 1
	inc	1, iz
Sprintf_TrailZero_CheckHigh:
	ld	wa, hl
	and	wa, 0xff00
	jr	z, Sprintf_TrailZero_ApplyShift
	cp	iz, 0x8
	jr	lt, Sprintf_TrailZero_ShiftLoop
Sprintf_TrailZero_ApplyShift:
	cp	iz, 0:i3
	jr	z, Sprintf_TrailZero_Done
	pushw	bc
	pushw	iz
	push	xde
	calr	Sprintf_ShiftDigitArray
	inc	8, xsp
Sprintf_TrailZero_Done:
	ld	hl, iz
Sprintf_TrailZero_Return:
	popw	iz
	ret
Sprintf_DecimalExponent:
	dec	8, xsp
	push	xiz
	ld	wa, (xsp + 16)
	exts	xwa
	lda	xbc, (301:16)
	call	Math_MultiplyAccumulate
	ld	xiz, xhl
	cp	xiz, 0x0
	jr	ge, Sprintf_DecExp_Positive
	ld	xwa, xiz
	cpl	wa
	cplw_erp	0xe2
	inc	1, xwa
	ld	(xsp + 4), xwa
	jr	Sprintf_DecExp_ComputeQuotient
Sprintf_DecExp_Positive:
	ld	(xsp + 4), xiz
Sprintf_DecExp_ComputeQuotient:
	ld	xiz, (xsp + 4)
	ld	xwa, xiz
	lda	xbc, (1000:16)
	call	Free_ClearByte2
	ld	(xsp + 8), xhl
	ld	xwa, xiz
	lda	xbc, (1000:16)
	call	Math_DivideSigned32
	ld	xiz, xhl
	ld	xwa, (xsp + 8)
	cp	xwa, 0x3d4
	jr	le, Sprintf_DecExp_CheckRemainder
	inc	1, xiz
	jr	Sprintf_DecExp_ApplySign
Sprintf_DecExp_CheckRemainder:
	ld	xwa, (xsp + 4)
	or	xwa, xwa
	jr	z, Sprintf_DecExp_ApplySign
	ld	xwa, (xsp + 8)
	cp	xwa, 0x14
	jr	ge, Sprintf_DecExp_ApplySign
	dec	1, xiz
Sprintf_DecExp_ApplySign:
	cpw	(xsp + 16), 0x0
	jr	ge, Sprintf_DecExp_Positive_Return
	ld	xwa, xiz
	cpl	wa
	cplw_erp	0xe2
	inc	1, xwa
	ld	xhl, xwa
	jr	Sprintf_DecExp_Return
Sprintf_DecExp_Positive_Return:
	ld	xhl, xiz
Sprintf_DecExp_Return:
	pop	xiz
	inc	8, xsp
	ret
	.byte 0xff
Sprintf_CopyBytes8:
	ld	xix, (xbc)
	ld	xiy, (xbc + 4)
	ld	(xwa), xix
	ld	(xwa + 4), xiy
	ret
Sprintf_ItoaBaseN:
	lda	xsp, (xsp - 46)
	push	xiz
	cpw	(xsp + 62), 0x2
	jr	lt, Sprintf_ItoaBaseN_Invalid
	cpw	(xsp + 62), 0x24
	jr	le, Sprintf_ItoaBaseN_Setup
Sprintf_ItoaBaseN_Invalid:
	ld	xwa, (xsp + 58)
	ld	(xwa), 0x0
	jr	Sprintf_ItoaBaseN_Return
Sprintf_ItoaBaseN_Setup:
	lda	xwa, (xsp + 16)
	ld	(xsp + 8), xwa
	ld	(xwa + 32), 0x0
	ld	xwa, (xsp + 8)
	lda	xwa, (xwa + 31)
	ld	(xsp + 4), xwa
	ld	xiz, (xsp + 54)
Sprintf_ItoaBaseN_DivLoop:
	ld	wa, (xsp + 62)
	exts	xwa
	ld	(xsp + 12), xwa
	ld	xwa, xiz
	ld	xbc, (xsp + 12)
	call	DivMod32
	add	l, 0x30
	ld	xwa, (xsp + 4)
	ld	(xwa), l
	cp	(xwa), 0x39
	jr	le, Sprintf_ItoaBaseN_StoreDigit
	addmi8	(xwa), 0x27
Sprintf_ItoaBaseN_StoreDigit:
	ld	xwa, xiz
	ld	xbc, (xsp + 12)
	call	Math_DivideU32
	ld	xiz, xhl
	or	xiz, xiz
	jr	z, Sprintf_ItoaBaseN_Reverse
	ld	xwa, 1:i3
	sub	(xsp + 4), xwa
	jr	Sprintf_ItoaBaseN_DivLoop
Sprintf_ItoaBaseN_Reverse:
	ld	xwa, (xsp + 8)
	lda	xwa, (xwa + 33)
	sub	xwa, (xsp + 4)
	push	xwa
	ld	xwa, (xsp + 8)
	push	xwa
	ld	xwa, (xsp + 66)
	push	xwa
	call	Mem_Copy
	lda	xsp, (xsp + 12)
Sprintf_ItoaBaseN_Return:
	ld	xhl, (xsp + 58)
	pop	xiz
	lda	xsp, (xsp + 46)
	ret
Sprintf_ItoaBaseN_Pad:
	swi	7
Sprintf_CopyBytes10:
	ld	xix, (xbc)
	ld	xiy, (xbc + 4)
	ld	hl, (xbc + 8)
	ld	(xwa), xix
	ld	(xwa + 4), xiy
	ld	(xwa + 8), hl
	ret
Sprintf_StringNSearch:
	dec	4, xsp
	pushw	iz
	ld	iz, (xsp + 20)
	pushw	iz
	pushm	(xsp + 20)
	ld	xwa, (xsp + 18)
	push	xwa
	call	Sprintf_MemChr
	inc	8, xsp
	ld	(xsp + 2), xhl
	ld	xwa, (xsp + 2)
	or	xwa, xwa
	jr	nz, Sprintf_StringNSearch_Found
	pushw	iz
	jr	Sprintf_StringNSearch_Copy
Sprintf_StringNSearch_Found:
	ld	xwa, (xsp + 2)
	sub	xwa, (xsp + 14)
	inc	1, xwa
	pushw	wa
Sprintf_StringNSearch_Copy:
	ld	xwa, (xsp + 16)
	push	xwa
	ld	xwa, (xsp + 16)
	push	xwa
	call	Mem_Copy
	lda	xsp, (xsp + 10)
	ld	xhl, (xsp + 2)
	popw	iz
	inc	4, xsp
	ret
Sprintf_MemChr:
	ld	xhl, 0:i3
	ld	bc, (xsp + 10)
	cp	bc, 0:i3
	ret	z
	ld	xhl, (xsp + 4)
	ld	wa, (xsp + 8)
	cpir83	; <-- aqui é o endereço FF28E2
	dec	1, xhl
	ret	z
	ld	xhl, 0:i3
	ret
Sprintf_StrNSet:
	ld	de, (xsp+10)
	ld	xix, (xsp+4)
	ld	xhl, xix
	jr	Sprintf_StrNSet_Join
Sprintf_StrNSet_Loop:
	lda	xbc, (xix+:1)
	ld	wa, (xsp+8)
	ld	(xbc), a
Sprintf_StrNSet_Join:
	ld	wa, de
	dec	1, de
	cp	wa, 0:i3
	ret	z
	cp	(xix), 0
	jr	nz, Sprintf_StrNSet_Loop
	ret
Sprintf_StringLength:
	push	xiz
	ld	xiz, (xsp + 8)
	push	xiz
	call	Strlen
	inc	4, xsp
	inc	1, hl
	ld	bc, hl
	lda	xhl, (xiz+bc)
	cp	bc, 0:i3
	jr	z, Sprintf_StrLen_NotFound
	ld	wa, (xsp + 12)
Sprintf_StrLen_ScanLoop:
	cp	A, (-xhl)
	jr	z, Sprintf_StrLen_Return
	djnz16	bc, Sprintf_StrLen_ScanLoop
Sprintf_StrLen_NotFound:
	ld	xhl, 0:i3
Sprintf_StrLen_Return:
	pop	xiz
	ret
; ---------------------------------------------------------------------------
; ERASED FLASH, 0xFF2154-0xFFFE7F (56,620 bytes, every one 0xFF).
;
; Measured on original_ROMs/kn5000_v7_program.rom: the byte after the `ret`
; above is the first of an unbroken 0xFF run that ends exactly at
; Debug_PrintHexByte (0xFFFE80).  The `.org` below emits all of it.
;
; Until 2026-09-25 the head of this run was written as ~990 lines of
; `swi 7` (0xFF decodes as SWI 7), four `.byte 0xff` rows and a 27-byte
; `.fill`, carrying 68 labels transplanted from v9/v10 (Sprintf_Normalize_*,
; Sprintf_InsertCarry*, Sprintf_DivideDigitsByTen, Sprintf_MulByTen_*,
; Sprintf_CountLeadingZeros, Sprintf_DecimalExponent, Sprintf_DecExp_*,
; Sprintf_CopyBytes8/10, Sprintf_ItoaBaseN*, Sprintf_StringNSearch*,
; Sprintf_MemChr, Sprintf_StrNSet, Sprintf_StringLength,
; Sprintf_StrLen_*, Sprintf_FillToEnd).  No v7 source file referenced any
; of them (checked over every v7/maincpu .s/.c/.ld), and no byte here is
; anything but 0xFF, so they were names on erased flash, not routines.
; The routines themselves DO exist in v7, lower down: a byte alignment
; (difflib over the two ROMs) matches v7 0xFF086B-0xFF2153 to v10
; 0xFF1048-0xFF292F -- v10's whole Sprintf_Core..Sprintf_FillToEnd span --
; with only 2-byte operand differences and one inserted byte.  The v7 labels
; of this file sit 0x41A bytes above their code, which is what pushed the
; last ~70 of them onto the fill.  The note below was written about one of
; them, Sprintf_DecExp_ApplySign (then at 0xFF240F); its point, that a clean
; `swi 7` decode of 0xFF is not code, is the reason for this block.
; ---------------------------------------------------------------------------
	; NOT code, despite the label: all 27 bytes are 0xff. v9/v10 has a real,
	; ~10-instruction routine at this same label ("cpw (xsp+16),0x0 / jr ge,... /
	; ld xwa,xiz / cpl wa / ..."), so this is not shared structure -- this v7
	; revision's flash is unprogrammed/erased here, not merely undecoded. A
	; disassembler happily decodes 0xff as 27x `swi 7` and round-trips it
	; byte-exact, which is exactly the trap noted in the HD-AE5000 version-string
	; case: a clean decode is not proof of code. Typed as the fill it plainly is.
; === end v7 block ===
; v7: Use .org to auto-compute padding to reach Debug_PrintHexByte at 0xFFFE80
	.org 0xfffe80 - 0xe00000, 0xff
Sprintf_FillToVectors:
