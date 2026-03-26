; NOTE: Renamed from audio_cmd_encoder.s. Original Matsushita labels were
; Audio_CommandEncoder / AudioCmd_*. These are actually sprintf() implementation
; routines, not audio command encoders.
; =============================================================================
; Sprintf_Core -- Printf-like audio command byte formatter
; =============================================================================
; Parses format string with % specifiers to build multi-byte command packets.
; Stack frame: 74 bytes. Called exclusively by Sprintf_Locked.
Sprintf_Core:
	.incbin "includes/generated/v7_transplant_Sprintf_Core.bin"
Sprintf_OutputLiteral:
	.incbin "includes/generated/v7_transplant_Sprintf_OutputLiteral.bin"
Sprintf_ParseFormatSpec:
	.incbin "includes/generated/v7_transplant_Sprintf_ParseFormatSpec.bin"
Sprintf_ReadFormatChar:
	.incbin "includes/generated/v7_transplant_Sprintf_ReadFormatChar.bin"
Sprintf_StarWidth_Positive:
	.incbin "includes/generated/v7_transplant_Sprintf_StarWidth_Positive.bin"
Sprintf_Flag_Space:
	.incbin "includes/generated/v7_transplant_Sprintf_Flag_Space.bin"
Sprintf_Flag_Hash:
	.incbin "includes/generated/v7_transplant_Sprintf_Flag_Hash.bin"
Sprintf_Flag_Plus:
	.incbin "includes/generated/v7_transplant_Sprintf_Flag_Plus.bin"
Sprintf_Flag_Minus:
	.incbin "includes/generated/v7_transplant_Sprintf_Flag_Minus.bin"
Sprintf_Flag_Zero:
	.incbin "includes/generated/v7_transplant_Sprintf_Flag_Zero.bin"
Sprintf_ParseWidthDigit:
	.incbin "includes/generated/v7_transplant_Sprintf_ParseWidthDigit.bin"
Sprintf_CheckIfDigit:
	.incbin "includes/generated/v7_transplant_Sprintf_CheckIfDigit.bin"
Sprintf_CheckPrecisionDot:
	.incbin "includes/generated/v7_transplant_Sprintf_CheckPrecisionDot.bin"
Sprintf_StarPrecision_Applied:
	.incbin "includes/generated/v7_transplant_Sprintf_StarPrecision_Applied.bin"
Sprintf_ParsePrecisionDigit:
	.incbin "includes/generated/v7_transplant_Sprintf_ParsePrecisionDigit.bin"
Sprintf_CheckPrecisionDigit:
	.incbin "includes/generated/v7_transplant_Sprintf_CheckPrecisionDigit.bin"
Sprintf_CheckLengthH:
	.incbin "includes/generated/v7_transplant_Sprintf_CheckLengthH.bin"
Sprintf_CheckLengthL:
	.incbin "includes/generated/v7_transplant_Sprintf_CheckLengthL.bin"
Sprintf_CheckLengthLL:
	.incbin "includes/generated/v7_transplant_Sprintf_CheckLengthLL.bin"
Sprintf_DispatchType:
	.incbin "includes/generated/v7_transplant_Sprintf_DispatchType.bin"
Sprintf_Format_Percent:
	.incbin "includes/generated/v7_transplant_Sprintf_Format_Percent.bin"
Sprintf_Percent_PadLeft:
	.incbin "includes/generated/v7_transplant_Sprintf_Percent_PadLeft.bin"
Sprintf_Percent_PadLeftLoop:
	.incbin "includes/generated/v7_transplant_Sprintf_Percent_PadLeftLoop.bin"
Sprintf_Format_CharOrPercent:
	.incbin "includes/generated/v7_transplant_Sprintf_Format_CharOrPercent.bin"
Sprintf_Percent_LiteralPush:
	.incbin "includes/generated/v7_transplant_Sprintf_Percent_LiteralPush.bin"
Sprintf_Percent_OutputChar:
	.incbin "includes/generated/v7_transplant_Sprintf_Percent_OutputChar.bin"
Sprintf_Percent_PadRight:
	.incbin "includes/generated/v7_transplant_Sprintf_Percent_PadRight.bin"
Sprintf_Percent_PadRightLoop:
	.incbin "includes/generated/v7_transplant_Sprintf_Percent_PadRightLoop.bin"
Sprintf_String_UseStrLen:
	.incbin "includes/generated/v7_transplant_Sprintf_String_UseStrLen.bin"
Sprintf_String_UsePrecision:
	.incbin "includes/generated/v7_transplant_Sprintf_String_UsePrecision.bin"
Sprintf_String_ComputePadding:
	.incbin "includes/generated/v7_transplant_Sprintf_String_ComputePadding.bin"
Sprintf_String_WidthAvailable:
	.incbin "includes/generated/v7_transplant_Sprintf_String_WidthAvailable.bin"
Sprintf_String_CheckLeftAlign:
	.incbin "includes/generated/v7_transplant_Sprintf_String_CheckLeftAlign.bin"
Sprintf_String_PadLeftSpace:
	.incbin "includes/generated/v7_transplant_Sprintf_String_PadLeftSpace.bin"
Sprintf_String_PadLeftLoop:
	.incbin "includes/generated/v7_transplant_Sprintf_String_PadLeftLoop.bin"
Sprintf_String_OutputChars:
	.incbin "includes/generated/v7_transplant_Sprintf_String_OutputChars.bin"
Sprintf_String_OutputLoop:
	.incbin "includes/generated/v7_transplant_Sprintf_String_OutputLoop.bin"
Sprintf_String_PadRightSpace:
	.incbin "includes/generated/v7_transplant_Sprintf_String_PadRightSpace.bin"
Sprintf_String_PadRightLoop:
	.incbin "includes/generated/v7_transplant_Sprintf_String_PadRightLoop.bin"
Sprintf_Decimal_GetShortArg:
	.incbin "includes/generated/v7_transplant_Sprintf_Decimal_GetShortArg.bin"
Sprintf_Decimal_Setup:
	.incbin "includes/generated/v7_transplant_Sprintf_Decimal_Setup.bin"
Sprintf_Decimal_ConvertToString:
	.incbin "includes/generated/v7_transplant_Sprintf_Decimal_ConvertToString.bin"
Sprintf_Decimal_CheckPrecision:
	.incbin "includes/generated/v7_transplant_Sprintf_Decimal_CheckPrecision.bin"
Sprintf_Decimal_NoPrecision:
	.incbin "includes/generated/v7_transplant_Sprintf_Decimal_NoPrecision.bin"
Sprintf_Decimal_SubtractLength:
	.incbin "includes/generated/v7_transplant_Sprintf_Decimal_SubtractLength.bin"
Sprintf_Decimal_CheckSign:
	.incbin "includes/generated/v7_transplant_Sprintf_Decimal_CheckSign.bin"
Sprintf_Decimal_ComputeWidth:
	.incbin "includes/generated/v7_transplant_Sprintf_Decimal_ComputeWidth.bin"
Sprintf_Decimal_FinalWidth:
	.incbin "includes/generated/v7_transplant_Sprintf_Decimal_FinalWidth.bin"
Sprintf_Decimal_PadLeftSpace:
	.incbin "includes/generated/v7_transplant_Sprintf_Decimal_PadLeftSpace.bin"
Sprintf_Decimal_PadLeftLoop:
	.incbin "includes/generated/v7_transplant_Sprintf_Decimal_PadLeftLoop.bin"
Sprintf_Decimal_OutputSign:
	.incbin "includes/generated/v7_transplant_Sprintf_Decimal_OutputSign.bin"
Sprintf_Decimal_PlusSign:
	.incbin "includes/generated/v7_transplant_Sprintf_Decimal_PlusSign.bin"
Sprintf_Decimal_SpaceSign:
	.incbin "includes/generated/v7_transplant_Sprintf_Decimal_SpaceSign.bin"
Sprintf_Decimal_EmitSign:
	.incbin "includes/generated/v7_transplant_Sprintf_Decimal_EmitSign.bin"
Sprintf_Decimal_ZeroFill:
	.incbin "includes/generated/v7_transplant_Sprintf_Decimal_ZeroFill.bin"
Sprintf_Decimal_ZeroFillBody:
	.incbin "includes/generated/v7_transplant_Sprintf_Decimal_ZeroFillBody.bin"
Sprintf_Decimal_ZeroFillLoop:
	.incbin "includes/generated/v7_transplant_Sprintf_Decimal_ZeroFillLoop.bin"
Sprintf_Decimal_PrecZeroBody:
	.incbin "includes/generated/v7_transplant_Sprintf_Decimal_PrecZeroBody.bin"
Sprintf_Decimal_PrecZeroLoop:
	.incbin "includes/generated/v7_transplant_Sprintf_Decimal_PrecZeroLoop.bin"
Sprintf_Decimal_OutputDigits:
	.incbin "includes/generated/v7_transplant_Sprintf_Decimal_OutputDigits.bin"
Sprintf_Decimal_DigitLoop:
	.incbin "includes/generated/v7_transplant_Sprintf_Decimal_DigitLoop.bin"
Sprintf_Decimal_PadRightSpace:
	.incbin "includes/generated/v7_transplant_Sprintf_Decimal_PadRightSpace.bin"
Sprintf_Decimal_PadRightLoop:
	.incbin "includes/generated/v7_transplant_Sprintf_Decimal_PadRightLoop.bin"
Sprintf_Unsigned_GetShortArg:
	.incbin "includes/generated/v7_transplant_Sprintf_Unsigned_GetShortArg.bin"
Sprintf_Unsigned_Setup:
	.incbin "includes/generated/v7_transplant_Sprintf_Unsigned_Setup.bin"
Sprintf_Unsigned_ConvertToString:
	.incbin "includes/generated/v7_transplant_Sprintf_Unsigned_ConvertToString.bin"
Sprintf_Unsigned_CheckPrecision:
	.incbin "includes/generated/v7_transplant_Sprintf_Unsigned_CheckPrecision.bin"
Sprintf_Unsigned_NoPrecision:
	.incbin "includes/generated/v7_transplant_Sprintf_Unsigned_NoPrecision.bin"
Sprintf_Unsigned_SubtractLength:
	.incbin "includes/generated/v7_transplant_Sprintf_Unsigned_SubtractLength.bin"
Sprintf_Unsigned_ComputeWidth:
	.incbin "includes/generated/v7_transplant_Sprintf_Unsigned_ComputeWidth.bin"
Sprintf_Unsigned_FinalWidth:
	.incbin "includes/generated/v7_transplant_Sprintf_Unsigned_FinalWidth.bin"
Sprintf_Unsigned_PadLeftSpace:
	.incbin "includes/generated/v7_transplant_Sprintf_Unsigned_PadLeftSpace.bin"
Sprintf_Unsigned_PadLeftLoop:
	.incbin "includes/generated/v7_transplant_Sprintf_Unsigned_PadLeftLoop.bin"
Sprintf_Unsigned_PrecZeroBody:
	.incbin "includes/generated/v7_transplant_Sprintf_Unsigned_PrecZeroBody.bin"
Sprintf_Unsigned_PrecZeroLoop:
	.incbin "includes/generated/v7_transplant_Sprintf_Unsigned_PrecZeroLoop.bin"
Sprintf_Unsigned_OutputDigits:
	.incbin "includes/generated/v7_transplant_Sprintf_Unsigned_OutputDigits.bin"
Sprintf_Unsigned_DigitLoop:
	.incbin "includes/generated/v7_transplant_Sprintf_Unsigned_DigitLoop.bin"
Sprintf_Unsigned_PadRightSpace:
	.incbin "includes/generated/v7_transplant_Sprintf_Unsigned_PadRightSpace.bin"
Sprintf_Unsigned_PadRightLoop:
	.incbin "includes/generated/v7_transplant_Sprintf_Unsigned_PadRightLoop.bin"
Sprintf_Hex_GetArg:
	.incbin "includes/generated/v7_transplant_Sprintf_Hex_GetArg.bin"
Sprintf_Hex_GetShortArg:
	.incbin "includes/generated/v7_transplant_Sprintf_Hex_GetShortArg.bin"
Sprintf_Hex_Setup:
	.incbin "includes/generated/v7_transplant_Sprintf_Hex_Setup.bin"
Sprintf_Hex_ConvertToString:
	.incbin "includes/generated/v7_transplant_Sprintf_Hex_ConvertToString.bin"
Sprintf_Hex_CheckPrecision:
	.incbin "includes/generated/v7_transplant_Sprintf_Hex_CheckPrecision.bin"
Sprintf_Hex_NoPrecision:
	.incbin "includes/generated/v7_transplant_Sprintf_Hex_NoPrecision.bin"
Sprintf_Hex_SubtractLength:
	.incbin "includes/generated/v7_transplant_Sprintf_Hex_SubtractLength.bin"
Sprintf_Hex_CheckAltForm:
	.incbin "includes/generated/v7_transplant_Sprintf_Hex_CheckAltForm.bin"
Sprintf_Hex_AltFormPrefix:
	.incbin "includes/generated/v7_transplant_Sprintf_Hex_AltFormPrefix.bin"
Sprintf_Hex_ComputeWidth:
	.incbin "includes/generated/v7_transplant_Sprintf_Hex_ComputeWidth.bin"
Sprintf_Hex_PadLeftSpace:
	.incbin "includes/generated/v7_transplant_Sprintf_Hex_PadLeftSpace.bin"
Sprintf_Hex_PadLeftLoop:
	.incbin "includes/generated/v7_transplant_Sprintf_Hex_PadLeftLoop.bin"
Sprintf_Hex_EmitPrefix:
	.incbin "includes/generated/v7_transplant_Sprintf_Hex_EmitPrefix.bin"
Sprintf_Hex_ZeroFill:
	.incbin "includes/generated/v7_transplant_Sprintf_Hex_ZeroFill.bin"
Sprintf_Hex_ZeroFillBody:
	.incbin "includes/generated/v7_transplant_Sprintf_Hex_ZeroFillBody.bin"
Sprintf_Hex_ZeroFillLoop:
	.incbin "includes/generated/v7_transplant_Sprintf_Hex_ZeroFillLoop.bin"
Sprintf_Hex_PrecZeroBody:
	.incbin "includes/generated/v7_transplant_Sprintf_Hex_PrecZeroBody.bin"
Sprintf_Hex_PrecZeroLoop:
	.incbin "includes/generated/v7_transplant_Sprintf_Hex_PrecZeroLoop.bin"
Sprintf_Hex_OutputDigits:
	.incbin "includes/generated/v7_transplant_Sprintf_Hex_OutputDigits.bin"
Sprintf_Hex_DigitLoop:
	.incbin "includes/generated/v7_transplant_Sprintf_Hex_DigitLoop.bin"
Sprintf_Hex_PadRightSpace:
	.incbin "includes/generated/v7_transplant_Sprintf_Hex_PadRightSpace.bin"
Sprintf_Hex_PadRightLoop:
	.incbin "includes/generated/v7_transplant_Sprintf_Hex_PadRightLoop.bin"
Sprintf_Octal_GetShortArg:
	.incbin "includes/generated/v7_transplant_Sprintf_Octal_GetShortArg.bin"
Sprintf_Octal_Setup:
	.incbin "includes/generated/v7_transplant_Sprintf_Octal_Setup.bin"
Sprintf_Octal_ConvertToString:
	.incbin "includes/generated/v7_transplant_Sprintf_Octal_ConvertToString.bin"
Sprintf_Octal_CheckPrecision:
	.incbin "includes/generated/v7_transplant_Sprintf_Octal_CheckPrecision.bin"
Sprintf_Octal_NoPrecision:
	.incbin "includes/generated/v7_transplant_Sprintf_Octal_NoPrecision.bin"
Sprintf_Octal_SubtractLength:
	.incbin "includes/generated/v7_transplant_Sprintf_Octal_SubtractLength.bin"
Sprintf_Octal_CheckAltForm:
	.incbin "includes/generated/v7_transplant_Sprintf_Octal_CheckAltForm.bin"
Sprintf_Octal_ComputeWidth:
	.incbin "includes/generated/v7_transplant_Sprintf_Octal_ComputeWidth.bin"
Sprintf_Octal_PadLeftSpace:
	.incbin "includes/generated/v7_transplant_Sprintf_Octal_PadLeftSpace.bin"
Sprintf_Octal_PadLeftLoop:
	.incbin "includes/generated/v7_transplant_Sprintf_Octal_PadLeftLoop.bin"
Sprintf_Octal_EmitPrefix:
	.incbin "includes/generated/v7_transplant_Sprintf_Octal_EmitPrefix.bin"
Sprintf_Octal_ZeroFill:
	.incbin "includes/generated/v7_transplant_Sprintf_Octal_ZeroFill.bin"
Sprintf_Octal_ZeroFillBody:
	.incbin "includes/generated/v7_transplant_Sprintf_Octal_ZeroFillBody.bin"
Sprintf_Octal_ZeroFillLoop:
	.incbin "includes/generated/v7_transplant_Sprintf_Octal_ZeroFillLoop.bin"
Sprintf_Octal_PrecZeroBody:
	.incbin "includes/generated/v7_transplant_Sprintf_Octal_PrecZeroBody.bin"
Sprintf_Octal_PrecZeroLoop:
	.incbin "includes/generated/v7_transplant_Sprintf_Octal_PrecZeroLoop.bin"
Sprintf_Octal_OutputDigits:
	.incbin "includes/generated/v7_transplant_Sprintf_Octal_OutputDigits.bin"
Sprintf_Octal_DigitLoop:
	.incbin "includes/generated/v7_transplant_Sprintf_Octal_DigitLoop.bin"
Sprintf_Octal_PadRightSpace:
	.incbin "includes/generated/v7_transplant_Sprintf_Octal_PadRightSpace.bin"
Sprintf_Octal_PadRightLoop:
	.incbin "includes/generated/v7_transplant_Sprintf_Octal_PadRightLoop.bin"
Sprintf_StoreCount_Short:
	.incbin "includes/generated/v7_transplant_Sprintf_StoreCount_Short.bin"
Sprintf_FormatFloat_Entry:
	.incbin "includes/generated/v7_transplant_Sprintf_FormatFloat_Entry.bin"
Sprintf_FormatFloat_ShortArg:
	.incbin "includes/generated/v7_transplant_Sprintf_FormatFloat_ShortArg.bin"
Sprintf_FormatFloat_Dispatch:
	.incbin "includes/generated/v7_transplant_Sprintf_FormatFloat_Dispatch.bin"
Sprintf_MainLoop_ReadNext:
	.incbin "includes/generated/v7_transplant_Sprintf_MainLoop_ReadNext.bin"
Sprintf_IntToStr:
	.incbin "includes/generated/v7_transplant_Sprintf_IntToStr.bin"
Sprintf_IntToStr_Positive:
	.incbin "includes/generated/v7_transplant_Sprintf_IntToStr_Positive.bin"
Sprintf_IntToStr_DivLoop:
	.incbin "includes/generated/v7_transplant_Sprintf_IntToStr_DivLoop.bin"
Sprintf_UIntToStr:
	.incbin "includes/generated/v7_transplant_Sprintf_UIntToStr.bin"
Sprintf_UIntToStr_DivLoop:
	.incbin "includes/generated/v7_transplant_Sprintf_UIntToStr_DivLoop.bin"
Sprintf_HexToStr:
	.incbin "includes/generated/v7_transplant_Sprintf_HexToStr.bin"
Sprintf_HexToStr_TableSelected:
	.incbin "includes/generated/v7_transplant_Sprintf_HexToStr_TableSelected.bin"
Sprintf_HexToStr_Loop:
	.incbin "includes/generated/v7_transplant_Sprintf_HexToStr_Loop.bin"
Sprintf_OctalToStr:
	.incbin "includes/generated/v7_transplant_Sprintf_OctalToStr.bin"
Sprintf_OctalToStr_Loop:
	.incbin "includes/generated/v7_transplant_Sprintf_OctalToStr_Loop.bin"
Sprintf_FormatFloat:
	.incbin "includes/generated/v7_transplant_Sprintf_FormatFloat.bin"
Sprintf_FormatFloat_eE:
	.incbin "includes/generated/v7_transplant_Sprintf_FormatFloat_eE.bin"
Sprintf_FormatFloat_fF_Check:
	.incbin "includes/generated/v7_transplant_Sprintf_FormatFloat_fF_Check.bin"
Sprintf_FormatFloat_fF:
	.incbin "includes/generated/v7_transplant_Sprintf_FormatFloat_fF.bin"
Sprintf_FormatFloat_fF_Call:
	.incbin "includes/generated/v7_transplant_Sprintf_FormatFloat_fF_Call.bin"
Sprintf_FormatFloat_gG:
	.incbin "includes/generated/v7_transplant_Sprintf_FormatFloat_gG.bin"
Sprintf_FormatFloat_gG_Setup:
	.incbin "includes/generated/v7_transplant_Sprintf_FormatFloat_gG_Setup.bin"
Sprintf_FormatFloat_gG_UseSci:
	.incbin "includes/generated/v7_transplant_Sprintf_FormatFloat_gG_UseSci.bin"
Sprintf_FormatFloat_Return:
	.incbin "includes/generated/v7_transplant_Sprintf_FormatFloat_Return.bin"
Sprintf_FormatFFixed:
	.incbin "includes/generated/v7_transplant_Sprintf_FormatFFixed.bin"
Sprintf_FFixed_SetPrecision:
	.incbin "includes/generated/v7_transplant_Sprintf_FFixed_SetPrecision.bin"
Sprintf_FFixed_CheckDefaults:
	.incbin "includes/generated/v7_transplant_Sprintf_FFixed_CheckDefaults.bin"
Sprintf_FFixed_CheckLongDouble:
	.incbin "includes/generated/v7_transplant_Sprintf_FFixed_CheckLongDouble.bin"
Sprintf_FFixed_CheckLongDoubleLimit:
	.incbin "includes/generated/v7_transplant_Sprintf_FFixed_CheckLongDoubleLimit.bin"
Sprintf_FFixed_SpecNoUpperCase:
	.incbin "includes/generated/v7_transplant_Sprintf_FFixed_SpecNoUpperCase.bin"
Sprintf_FFixed_CheckSpecG:
	.incbin "includes/generated/v7_transplant_Sprintf_FFixed_CheckSpecG.bin"
Sprintf_FFixed_NotG:
	.incbin "includes/generated/v7_transplant_Sprintf_FFixed_NotG.bin"
Sprintf_FFixed_RoundCheck:
	.incbin "includes/generated/v7_transplant_Sprintf_FFixed_RoundCheck.bin"
Sprintf_FFixed_RoundCarry:
	.incbin "includes/generated/v7_transplant_Sprintf_FFixed_RoundCarry.bin"
Sprintf_FFixed_RoundLoop:
	.incbin "includes/generated/v7_transplant_Sprintf_FFixed_RoundLoop.bin"
Sprintf_FFixed_AfterRound:
	.incbin "includes/generated/v7_transplant_Sprintf_FFixed_AfterRound.bin"
Sprintf_FFixed_AfterRound_NoCase:
	.incbin "includes/generated/v7_transplant_Sprintf_FFixed_AfterRound_NoCase.bin"
Sprintf_FFixed_CheckG_StripZeros:
	.incbin "includes/generated/v7_transplant_Sprintf_FFixed_CheckG_StripZeros.bin"
Sprintf_FFixed_CheckG_AltForm:
	.incbin "includes/generated/v7_transplant_Sprintf_FFixed_CheckG_AltForm.bin"
Sprintf_FFixed_CaseApplied:
	.incbin "includes/generated/v7_transplant_Sprintf_FFixed_CaseApplied.bin"
Sprintf_FFixed_StripZeroLoop:
	.incbin "includes/generated/v7_transplant_Sprintf_FFixed_StripZeroLoop.bin"
Sprintf_FFixed_StripZeroCheck:
	.incbin "includes/generated/v7_transplant_Sprintf_FFixed_StripZeroCheck.bin"
Sprintf_FFixed_ComputeOutputLen:
	.incbin "includes/generated/v7_transplant_Sprintf_FFixed_ComputeOutputLen.bin"
Sprintf_FFixed_CheckPrecZero:
	.incbin "includes/generated/v7_transplant_Sprintf_FFixed_CheckPrecZero.bin"
Sprintf_FFixed_AdjustForSign:
	.incbin "includes/generated/v7_transplant_Sprintf_FFixed_AdjustForSign.bin"
Sprintf_FFixed_AdjustForSign2:
	.incbin "includes/generated/v7_transplant_Sprintf_FFixed_AdjustForSign2.bin"
Sprintf_FFixed_ComputePadding:
	.incbin "includes/generated/v7_transplant_Sprintf_FFixed_ComputePadding.bin"
Sprintf_FFixed_CheckOverflow:
	.incbin "includes/generated/v7_transplant_Sprintf_FFixed_CheckOverflow.bin"
Sprintf_FFixed_PadLeftCheck:
	.incbin "includes/generated/v7_transplant_Sprintf_FFixed_PadLeftCheck.bin"
Sprintf_FFixed_PadLeftSpace:
	.incbin "includes/generated/v7_transplant_Sprintf_FFixed_PadLeftSpace.bin"
Sprintf_FFixed_PadLeftLoop:
	.incbin "includes/generated/v7_transplant_Sprintf_FFixed_PadLeftLoop.bin"
Sprintf_FFixed_EmitSign:
	.incbin "includes/generated/v7_transplant_Sprintf_FFixed_EmitSign.bin"
Sprintf_FFixed_SignPlus:
	.incbin "includes/generated/v7_transplant_Sprintf_FFixed_SignPlus.bin"
Sprintf_FFixed_SignSpace:
	.incbin "includes/generated/v7_transplant_Sprintf_FFixed_SignSpace.bin"
Sprintf_FFixed_SignEmit:
	.incbin "includes/generated/v7_transplant_Sprintf_FFixed_SignEmit.bin"
Sprintf_FFixed_ZeroFill:
	.incbin "includes/generated/v7_transplant_Sprintf_FFixed_ZeroFill.bin"
Sprintf_FFixed_ZeroFillBody:
	.incbin "includes/generated/v7_transplant_Sprintf_FFixed_ZeroFillBody.bin"
Sprintf_FFixed_ZeroFillLoop:
	.incbin "includes/generated/v7_transplant_Sprintf_FFixed_ZeroFillLoop.bin"
Sprintf_FFixed_LeadDigit:
	.incbin "includes/generated/v7_transplant_Sprintf_FFixed_LeadDigit.bin"
Sprintf_FFixed_LeadDigitZero:
	.incbin "includes/generated/v7_transplant_Sprintf_FFixed_LeadDigitZero.bin"
Sprintf_FFixed_LeadDigitDone:
	.incbin "includes/generated/v7_transplant_Sprintf_FFixed_LeadDigitDone.bin"
Sprintf_FFixed_IntegerDigits:
	.incbin "includes/generated/v7_transplant_Sprintf_FFixed_IntegerDigits.bin"
Sprintf_FFixed_IntDigitOutput:
	.incbin "includes/generated/v7_transplant_Sprintf_FFixed_IntDigitOutput.bin"
Sprintf_FFixed_IntDigitLoop:
	.incbin "includes/generated/v7_transplant_Sprintf_FFixed_IntDigitLoop.bin"
Sprintf_FFixed_IntZeroFill:
	.incbin "includes/generated/v7_transplant_Sprintf_FFixed_IntZeroFill.bin"
Sprintf_FFixed_IntZeroLoop:
	.incbin "includes/generated/v7_transplant_Sprintf_FFixed_IntZeroLoop.bin"
Sprintf_FFixed_DecimalPoint:
	.incbin "includes/generated/v7_transplant_Sprintf_FFixed_DecimalPoint.bin"
Sprintf_FFixed_FracLeadZeros:
	.incbin "includes/generated/v7_transplant_Sprintf_FFixed_FracLeadZeros.bin"
Sprintf_FFixed_FracLeadZeroBody:
	.incbin "includes/generated/v7_transplant_Sprintf_FFixed_FracLeadZeroBody.bin"
Sprintf_FFixed_FracLeadZeroDone:
	.incbin "includes/generated/v7_transplant_Sprintf_FFixed_FracLeadZeroDone.bin"
Sprintf_FFixed_FracLeadZeroLoop:
	.incbin "includes/generated/v7_transplant_Sprintf_FFixed_FracLeadZeroLoop.bin"
Sprintf_FFixed_FracDigits:
	.incbin "includes/generated/v7_transplant_Sprintf_FFixed_FracDigits.bin"
Sprintf_FFixed_FracDigitOutput:
	.incbin "includes/generated/v7_transplant_Sprintf_FFixed_FracDigitOutput.bin"
Sprintf_FFixed_FracDigitLoop:
	.incbin "includes/generated/v7_transplant_Sprintf_FFixed_FracDigitLoop.bin"
Sprintf_FFixed_FracTrailZeros:
	.incbin "includes/generated/v7_transplant_Sprintf_FFixed_FracTrailZeros.bin"
Sprintf_FFixed_FracTrailLoop:
	.incbin "includes/generated/v7_transplant_Sprintf_FFixed_FracTrailLoop.bin"
Sprintf_FFixed_PadRightSpace:
	.incbin "includes/generated/v7_transplant_Sprintf_FFixed_PadRightSpace.bin"
Sprintf_FFixed_PadRightLoop:
	.incbin "includes/generated/v7_transplant_Sprintf_FFixed_PadRightLoop.bin"
Sprintf_FFixed_Return:
	.incbin "includes/generated/v7_transplant_Sprintf_FFixed_Return.bin"
Sprintf_FFixed_DataTable:
	.incbin "includes/generated/v7_transplant_Sprintf_FFixed_DataTable.bin"
Sprintf_FormatEScientific:
	.incbin "includes/generated/v7_transplant_Sprintf_FormatEScientific.bin"
Sprintf_ESci_ApplyDefaults:
	.incbin "includes/generated/v7_transplant_Sprintf_ESci_ApplyDefaults.bin"
Sprintf_ESci_SpecNoUpperCase:
	.incbin "includes/generated/v7_transplant_Sprintf_ESci_SpecNoUpperCase.bin"
Sprintf_ESci_CheckSpecG:
	.incbin "includes/generated/v7_transplant_Sprintf_ESci_CheckSpecG.bin"
Sprintf_ESci_SetDigitCount:
	.incbin "includes/generated/v7_transplant_Sprintf_ESci_SetDigitCount.bin"
Sprintf_ESci_RoundCheck:
	.incbin "includes/generated/v7_transplant_Sprintf_ESci_RoundCheck.bin"
Sprintf_ESci_RoundCarry:
	.incbin "includes/generated/v7_transplant_Sprintf_ESci_RoundCarry.bin"
Sprintf_ESci_RoundLoop:
	.incbin "includes/generated/v7_transplant_Sprintf_ESci_RoundLoop.bin"
Sprintf_ESci_AfterRound:
	.incbin "includes/generated/v7_transplant_Sprintf_ESci_AfterRound.bin"
Sprintf_ESci_AfterRound_NoCase:
	ld a, (xsp + 10)

Sprintf_ESci_StripTrailZeros:
	.incbin "includes/generated/v7_transplant_Sprintf_ESci_StripTrailZeros.bin"
Sprintf_ESci_StripLoop:
	.incbin "includes/generated/v7_transplant_Sprintf_ESci_StripLoop.bin"
Sprintf_ESci_StripCheck:
	.incbin "includes/generated/v7_transplant_Sprintf_ESci_StripCheck.bin"
Sprintf_ESci_ComputeOutputLen:
	.incbin "includes/generated/v7_transplant_Sprintf_ESci_ComputeOutputLen.bin"
Sprintf_ESci_CheckPrecZero:
	.incbin "includes/generated/v7_transplant_Sprintf_ESci_CheckPrecZero.bin"
Sprintf_ESci_AdjustForSign:
	.incbin "includes/generated/v7_transplant_Sprintf_ESci_AdjustForSign.bin"
Sprintf_ESci_AdjustForSign2:
	.incbin "includes/generated/v7_transplant_Sprintf_ESci_AdjustForSign2.bin"
Sprintf_ESci_ComputePadding:
	.incbin "includes/generated/v7_transplant_Sprintf_ESci_ComputePadding.bin"
Sprintf_ESci_PadLeftCheck:
	.incbin "includes/generated/v7_transplant_Sprintf_ESci_PadLeftCheck.bin"
Sprintf_ESci_PadLeftSpace:
	.incbin "includes/generated/v7_transplant_Sprintf_ESci_PadLeftSpace.bin"
Sprintf_ESci_PadLeftLoop:
	.incbin "includes/generated/v7_transplant_Sprintf_ESci_PadLeftLoop.bin"
Sprintf_ESci_EmitSign:
	.incbin "includes/generated/v7_transplant_Sprintf_ESci_EmitSign.bin"
Sprintf_ESci_SignPlus:
	.incbin "includes/generated/v7_transplant_Sprintf_ESci_SignPlus.bin"
Sprintf_ESci_SignSpace:
	.incbin "includes/generated/v7_transplant_Sprintf_ESci_SignSpace.bin"
Sprintf_ESci_SignEmit:
	.incbin "includes/generated/v7_transplant_Sprintf_ESci_SignEmit.bin"
Sprintf_ESci_ZeroFill:
	.incbin "includes/generated/v7_transplant_Sprintf_ESci_ZeroFill.bin"
Sprintf_ESci_ZeroFillBody:
	.incbin "includes/generated/v7_transplant_Sprintf_ESci_ZeroFillBody.bin"
Sprintf_ESci_ZeroFillLoop:
	.incbin "includes/generated/v7_transplant_Sprintf_ESci_ZeroFillLoop.bin"
Sprintf_ESci_LeadDigit:
	.incbin "includes/generated/v7_transplant_Sprintf_ESci_LeadDigit.bin"
Sprintf_ESci_Overflow_DecExp:
	.incbin "includes/generated/v7_transplant_Sprintf_ESci_Overflow_DecExp.bin"
Sprintf_ESci_LeadDigitNormal:
	.incbin "includes/generated/v7_transplant_Sprintf_ESci_LeadDigitNormal.bin"
Sprintf_ESci_DecimalPoint:
	.incbin "includes/generated/v7_transplant_Sprintf_ESci_DecimalPoint.bin"
Sprintf_ESci_DecimalPointEmit:
	.incbin "includes/generated/v7_transplant_Sprintf_ESci_DecimalPointEmit.bin"
Sprintf_ESci_MantissaDigits:
	.incbin "includes/generated/v7_transplant_Sprintf_ESci_MantissaDigits.bin"
Sprintf_ESci_MantissaNoCase:
	.incbin "includes/generated/v7_transplant_Sprintf_ESci_MantissaNoCase.bin"
Sprintf_ESci_CheckGTrim:
	.incbin "includes/generated/v7_transplant_Sprintf_ESci_CheckGTrim.bin"
Sprintf_ESci_OutputMantissa:
	.incbin "includes/generated/v7_transplant_Sprintf_ESci_OutputMantissa.bin"
Sprintf_ESci_MantDigitOutput:
	.incbin "includes/generated/v7_transplant_Sprintf_ESci_MantDigitOutput.bin"
Sprintf_ESci_MantDigitLoop:
	.incbin "includes/generated/v7_transplant_Sprintf_ESci_MantDigitLoop.bin"
Sprintf_ESci_MantTrailZeros:
	.incbin "includes/generated/v7_transplant_Sprintf_ESci_MantTrailZeros.bin"
Sprintf_ESci_MantTrailLoop:
	.incbin "includes/generated/v7_transplant_Sprintf_ESci_MantTrailLoop.bin"
Sprintf_ESci_ExpNoCase:
	.incbin "includes/generated/v7_transplant_Sprintf_ESci_ExpNoCase.bin"
Sprintf_ESci_CheckExpG:
	.incbin "includes/generated/v7_transplant_Sprintf_ESci_CheckExpG.bin"
Sprintf_ESci_ExpLetterNormal:
	.incbin "includes/generated/v7_transplant_Sprintf_ESci_ExpLetterNormal.bin"
Sprintf_ESci_EmitExpLetter:
	.incbin "includes/generated/v7_transplant_Sprintf_ESci_EmitExpLetter.bin"
Sprintf_ESci_ExpSignPositive:
	.incbin "includes/generated/v7_transplant_Sprintf_ESci_ExpSignPositive.bin"
Sprintf_ESci_EmitExpSign:
	.incbin "includes/generated/v7_transplant_Sprintf_ESci_EmitExpSign.bin"
Sprintf_ESci_ExpLeadZeros:
	.incbin "includes/generated/v7_transplant_Sprintf_ESci_ExpLeadZeros.bin"
Sprintf_ESci_ExpLeadZeroLoop:
	.incbin "includes/generated/v7_transplant_Sprintf_ESci_ExpLeadZeroLoop.bin"
Sprintf_ESci_ExpDigitOutput:
	.incbin "includes/generated/v7_transplant_Sprintf_ESci_ExpDigitOutput.bin"
Sprintf_ESci_ExpDigitLoop:
	.incbin "includes/generated/v7_transplant_Sprintf_ESci_ExpDigitLoop.bin"
Sprintf_ESci_PadRightSpace:
	.incbin "includes/generated/v7_transplant_Sprintf_ESci_PadRightSpace.bin"
Sprintf_ESci_PadRightLoop:
	.incbin "includes/generated/v7_transplant_Sprintf_ESci_PadRightLoop.bin"
Sprintf_ESci_Return:
	.incbin "includes/generated/v7_transplant_Sprintf_ESci_Return.bin"
Sprintf_FormatGGeneral:
	.incbin "includes/generated/v7_transplant_Sprintf_FormatGGeneral.bin"
Sprintf_GGen_ClearArrays:
	.incbin "includes/generated/v7_transplant_Sprintf_GGen_ClearArrays.bin"
Sprintf_GGen_CheckLongDouble:
	.incbin "includes/generated/v7_transplant_Sprintf_GGen_CheckLongDouble.bin"
Sprintf_GGen_LoadDigits:
	.incbin "includes/generated/v7_transplant_Sprintf_GGen_LoadDigits.bin"
Sprintf_GGen_CheckSign:
	.incbin "includes/generated/v7_transplant_Sprintf_GGen_CheckSign.bin"
Sprintf_GGen_Negative:
	.incbin "includes/generated/v7_transplant_Sprintf_GGen_Negative.bin"
Sprintf_GGen_ExtractExponent:
	.incbin "includes/generated/v7_transplant_Sprintf_GGen_ExtractExponent.bin"
Sprintf_GGen_LongDoubleExp:
	.incbin "includes/generated/v7_transplant_Sprintf_GGen_LongDoubleExp.bin"
Sprintf_GGen_NormalExp:
	.incbin "includes/generated/v7_transplant_Sprintf_GGen_NormalExp.bin"
Sprintf_GGen_NonZero:
	.incbin "includes/generated/v7_transplant_Sprintf_GGen_NonZero.bin"
Sprintf_GGen_ComputeDecExp:
	.incbin "includes/generated/v7_transplant_Sprintf_GGen_ComputeDecExp.bin"
Sprintf_GGen_ShiftMantissa:
	.incbin "includes/generated/v7_transplant_Sprintf_GGen_ShiftMantissa.bin"
Sprintf_GGen_DecimalExponent:
	.incbin "includes/generated/v7_transplant_Sprintf_GGen_DecimalExponent.bin"
Sprintf_GGen_AdjustNegExp:
	.incbin "includes/generated/v7_transplant_Sprintf_GGen_AdjustNegExp.bin"
Sprintf_GGen_LongDoubleDigits:
	.incbin "includes/generated/v7_transplant_Sprintf_GGen_LongDoubleDigits.bin"
Sprintf_GGen_NormalDigits:
	.incbin "includes/generated/v7_transplant_Sprintf_GGen_NormalDigits.bin"
Sprintf_GGen_FindLeadDigit:
	.incbin "includes/generated/v7_transplant_Sprintf_GGen_FindLeadDigit.bin"
Sprintf_GGen_FindLeadDone:
	.incbin "includes/generated/v7_transplant_Sprintf_GGen_FindLeadDone.bin"
Sprintf_GGen_LoadDigitPairs:
	.incbin "includes/generated/v7_transplant_Sprintf_GGen_LoadDigitPairs.bin"
Sprintf_GGen_DigitPairLoop:
	.incbin "includes/generated/v7_transplant_Sprintf_GGen_DigitPairLoop.bin"
Sprintf_GGen_NormalizeArray:
	.incbin "includes/generated/v7_transplant_Sprintf_GGen_NormalizeArray.bin"
Sprintf_GGen_MultiplyLoop:
	.incbin "includes/generated/v7_transplant_Sprintf_GGen_MultiplyLoop.bin"
Sprintf_GGen_PositiveExpDone:
	.incbin "includes/generated/v7_transplant_Sprintf_GGen_PositiveExpDone.bin"
Sprintf_GGen_DivideLoop:
	.incbin "includes/generated/v7_transplant_Sprintf_GGen_DivideLoop.bin"
Sprintf_GGen_NegativeExpCheck:
	.incbin "includes/generated/v7_transplant_Sprintf_GGen_NegativeExpCheck.bin"
Sprintf_GGen_FinalShift:
	.incbin "includes/generated/v7_transplant_Sprintf_GGen_FinalShift.bin"
Sprintf_GGen_RoundLoop:
	.incbin "includes/generated/v7_transplant_Sprintf_GGen_RoundLoop.bin"
Sprintf_GGen_ExtractResult:
	.incbin "includes/generated/v7_transplant_Sprintf_GGen_ExtractResult.bin"
Sprintf_GGen_CopyDigits:
	.incbin "includes/generated/v7_transplant_Sprintf_GGen_CopyDigits.bin"
Sprintf_GGen_CopyLoop:
	.incbin "includes/generated/v7_transplant_Sprintf_GGen_CopyLoop.bin"
Sprintf_GGen_HandleCarry:
	.incbin "includes/generated/v7_transplant_Sprintf_GGen_HandleCarry.bin"
Sprintf_GGen_CarryLoop:
	.incbin "includes/generated/v7_transplant_Sprintf_GGen_CarryLoop.bin"
Sprintf_GGen_CarryCheck:
	.incbin "includes/generated/v7_transplant_Sprintf_GGen_CarryCheck.bin"
Sprintf_GGen_ConvertToAscii:
	.incbin "includes/generated/v7_transplant_Sprintf_GGen_ConvertToAscii.bin"
Sprintf_GGen_AsciiLoop:
	.incbin "includes/generated/v7_transplant_Sprintf_GGen_AsciiLoop.bin"
Sprintf_GGen_AsciiDone:
	.incbin "includes/generated/v7_transplant_Sprintf_GGen_AsciiDone.bin"
Sprintf_ShiftDigitArray:
	.incbin "includes/generated/v7_transplant_Sprintf_ShiftDigitArray.bin"
Sprintf_Shift_BuildMask:
	.incbin "includes/generated/v7_transplant_Sprintf_Shift_BuildMask.bin"
Sprintf_Shift_SetupLoop:
	.incbin "includes/generated/v7_transplant_Sprintf_Shift_SetupLoop.bin"
Sprintf_Shift_Loop:
	.incbin "includes/generated/v7_transplant_Sprintf_Shift_Loop.bin"
Sprintf_Shift_ApplyShift:
	.incbin "includes/generated/v7_transplant_Sprintf_Shift_ApplyShift.bin"
Sprintf_Shift_ApplyCarry:
	.incbin "includes/generated/v7_transplant_Sprintf_Shift_ApplyCarry.bin"
Sprintf_Shift_LastEntry:
	.incbin "includes/generated/v7_transplant_Sprintf_Shift_LastEntry.bin"
Sprintf_Shift_LastShift:
	.incbin "includes/generated/v7_transplant_Sprintf_Shift_LastShift.bin"
Sprintf_PropagateCarry:
	.incbin "includes/generated/v7_transplant_Sprintf_PropagateCarry.bin"
Sprintf_PropCarry_Loop:
	.incbin "includes/generated/v7_transplant_Sprintf_PropCarry_Loop.bin"
Sprintf_PropCarry_Store:
	.incbin "includes/generated/v7_transplant_Sprintf_PropCarry_Store.bin"
Sprintf_PropCarry_Check:
	.incbin "includes/generated/v7_transplant_Sprintf_PropCarry_Check.bin"
Sprintf_NormalizeDigits:
	.incbin "includes/generated/v7_transplant_Sprintf_NormalizeDigits.bin"
Sprintf_Normalize_ClearLoop:
	.incbin "includes/generated/v7_transplant_Sprintf_Normalize_ClearLoop.bin"
Sprintf_Normalize_MainLoop:
	.incbin "includes/generated/v7_transplant_Sprintf_Normalize_MainLoop.bin"
Sprintf_Normalize_MultiplyTen:
	.incbin "includes/generated/v7_transplant_Sprintf_Normalize_MultiplyTen.bin"
Sprintf_Normalize_ExtractDigit:
	.incbin "includes/generated/v7_transplant_Sprintf_Normalize_ExtractDigit.bin"
Sprintf_Normalize_Done:
	.incbin "includes/generated/v7_transplant_Sprintf_Normalize_Done.bin"
Sprintf_InsertCarry:
	.incbin "includes/generated/v7_transplant_Sprintf_InsertCarry.bin"
Sprintf_InsertCarry_Clamp:
	.incbin "includes/generated/v7_transplant_Sprintf_InsertCarry_Clamp.bin"
Sprintf_InsertCarry_ClampLoop:
	.incbin "includes/generated/v7_transplant_Sprintf_InsertCarry_ClampLoop.bin"
Sprintf_InsertCarry_Check:
	.incbin "includes/generated/v7_transplant_Sprintf_InsertCarry_Check.bin"
Sprintf_InsertCarry_Propagate:
	.incbin "includes/generated/v7_transplant_Sprintf_InsertCarry_Propagate.bin"
Sprintf_InsertCarry_PropCheck:
	.incbin "includes/generated/v7_transplant_Sprintf_InsertCarry_PropCheck.bin"
Sprintf_DivideDigitsByTen:
	.incbin "includes/generated/v7_transplant_Sprintf_DivideDigitsByTen.bin"
Sprintf_DivByTen_Loop:
	.incbin "includes/generated/v7_transplant_Sprintf_DivByTen_Loop.bin"
Sprintf_MultiplyDigitsByTen:
	.incbin "includes/generated/v7_transplant_Sprintf_MultiplyDigitsByTen.bin"
Sprintf_MulByTen_Loop:
	.incbin "includes/generated/v7_transplant_Sprintf_MulByTen_Loop.bin"
Sprintf_MulByTen_CarryLoop:
	.incbin "includes/generated/v7_transplant_Sprintf_MulByTen_CarryLoop.bin"
Sprintf_MulByTen_CarryCheck:
	.incbin "includes/generated/v7_transplant_Sprintf_MulByTen_CarryCheck.bin"
Sprintf_MulByTen_Next:
	.incbin "includes/generated/v7_transplant_Sprintf_MulByTen_Next.bin"
Sprintf_MulByTen_HandleOverflow:
	.incbin "includes/generated/v7_transplant_Sprintf_MulByTen_HandleOverflow.bin"
Sprintf_MultiplyBCDByTen:
	.incbin "includes/generated/v7_transplant_Sprintf_MultiplyBCDByTen.bin"
Sprintf_BCDMul_Loop:
	.incbin "includes/generated/v7_transplant_Sprintf_BCDMul_Loop.bin"
Sprintf_BCDMul_Skip:
	.incbin "includes/generated/v7_transplant_Sprintf_BCDMul_Skip.bin"
Sprintf_BCDMul_CarryLoop:
	.incbin "includes/generated/v7_transplant_Sprintf_BCDMul_CarryLoop.bin"
Sprintf_BCDMul_Next:
	.incbin "includes/generated/v7_transplant_Sprintf_BCDMul_Next.bin"
Sprintf_CountLeadingZeros:
	.incbin "includes/generated/v7_transplant_Sprintf_CountLeadingZeros.bin"
Sprintf_LeadZero_Loop:
	.incbin "includes/generated/v7_transplant_Sprintf_LeadZero_Loop.bin"
Sprintf_LeadZero_CheckAllZero:
	.incbin "includes/generated/v7_transplant_Sprintf_LeadZero_CheckAllZero.bin"
Sprintf_LeadZero_CountBits:
	.incbin "includes/generated/v7_transplant_Sprintf_LeadZero_CountBits.bin"
Sprintf_LeadZero_ShiftLoop:
	.incbin "includes/generated/v7_transplant_Sprintf_LeadZero_ShiftLoop.bin"
Sprintf_LeadZero_ShiftBody:
	.incbin "includes/generated/v7_transplant_Sprintf_LeadZero_ShiftBody.bin"
Sprintf_LeadZero_CheckBit7:
	.incbin "includes/generated/v7_transplant_Sprintf_LeadZero_CheckBit7.bin"
Sprintf_LeadZero_ApplyShift:
	.incbin "includes/generated/v7_transplant_Sprintf_LeadZero_ApplyShift.bin"
Sprintf_LeadZero_AccumShift:
	.incbin "includes/generated/v7_transplant_Sprintf_LeadZero_AccumShift.bin"
Sprintf_LeadZero_OuterLoop:
	.incbin "includes/generated/v7_transplant_Sprintf_LeadZero_OuterLoop.bin"
Sprintf_LeadZero_Return:
	.incbin "includes/generated/v7_transplant_Sprintf_LeadZero_Return.bin"
Sprintf_CountTrailingZeros:
	.incbin "includes/generated/v7_transplant_Sprintf_CountTrailingZeros.bin"
Sprintf_TrailZero_Loop:
	.incbin "includes/generated/v7_transplant_Sprintf_TrailZero_Loop.bin"
Sprintf_TrailZero_CheckAllZero:
	.incbin "includes/generated/v7_transplant_Sprintf_TrailZero_CheckAllZero.bin"
Sprintf_TrailZero_CountBits:
	.incbin "includes/generated/v7_transplant_Sprintf_TrailZero_CountBits.bin"
Sprintf_TrailZero_ShiftLoop:
	.incbin "includes/generated/v7_transplant_Sprintf_TrailZero_ShiftLoop.bin"
Sprintf_TrailZero_CheckHigh:
	.incbin "includes/generated/v7_transplant_Sprintf_TrailZero_CheckHigh.bin"
Sprintf_TrailZero_ApplyShift:
	.incbin "includes/generated/v7_transplant_Sprintf_TrailZero_ApplyShift.bin"
Sprintf_TrailZero_Done:
	.incbin "includes/generated/v7_transplant_Sprintf_TrailZero_Done.bin"
Sprintf_TrailZero_Return:
	.incbin "includes/generated/v7_transplant_Sprintf_TrailZero_Return.bin"
Sprintf_DecimalExponent:
	.incbin "includes/generated/v7_transplant_Sprintf_DecimalExponent.bin"
Sprintf_DecExp_Positive:
	.incbin "includes/generated/v7_transplant_Sprintf_DecExp_Positive.bin"
Sprintf_DecExp_ComputeQuotient:
	.incbin "includes/generated/v7_transplant_Sprintf_DecExp_ComputeQuotient.bin"
Sprintf_DecExp_CheckRemainder:
	.incbin "includes/generated/v7_transplant_Sprintf_DecExp_CheckRemainder.bin"
Sprintf_DecExp_ApplySign:
	.incbin "includes/generated/v7_block_sprintf_decexp_applysign.bin"
; === end v7 block ===
Sprintf_CopyBytes8:
	.incbin "includes/generated/v7_transplant_Sprintf_CopyBytes8.bin"
Sprintf_ItoaBaseN:
	.incbin "includes/generated/v7_transplant_Sprintf_ItoaBaseN.bin"
Sprintf_ItoaBaseN_Invalid:
	.incbin "includes/generated/v7_transplant_Sprintf_ItoaBaseN_Invalid.bin"
Sprintf_ItoaBaseN_Setup:
	.incbin "includes/generated/v7_transplant_Sprintf_ItoaBaseN_Setup.bin"
Sprintf_ItoaBaseN_DivLoop:
	.incbin "includes/generated/v7_transplant_Sprintf_ItoaBaseN_DivLoop.bin"
Sprintf_ItoaBaseN_StoreDigit:
	.incbin "includes/generated/v7_transplant_Sprintf_ItoaBaseN_StoreDigit.bin"
Sprintf_ItoaBaseN_Reverse:
	.incbin "includes/generated/v7_transplant_Sprintf_ItoaBaseN_Reverse.bin"
Sprintf_ItoaBaseN_Return:
	.incbin "includes/generated/v7_transplant_Sprintf_ItoaBaseN_Return.bin"
Sprintf_ItoaBaseN_Pad:
	swi	7

Sprintf_CopyBytes10:
	.incbin "includes/generated/v7_transplant_Sprintf_CopyBytes10.bin"
Sprintf_StringNSearch:
	.incbin "includes/generated/v7_transplant_Sprintf_StringNSearch.bin"
Sprintf_StringNSearch_Found:
	.incbin "includes/generated/v7_transplant_Sprintf_StringNSearch_Found.bin"
Sprintf_StringNSearch_Copy:
	.incbin "includes/generated/v7_transplant_Sprintf_StringNSearch_Copy.bin"
Sprintf_MemChr:
	.incbin "includes/generated/v7_transplant_Sprintf_MemChr.bin"
Sprintf_DataBlock_28E9:
	.incbin "includes/generated/v7_transplant_Sprintf_DataBlock_28E9.bin"
Sprintf_StringLength:
	.incbin "includes/generated/v7_transplant_Sprintf_StringLength.bin"
Sprintf_StrLen_ScanLoop:
	.incbin "includes/generated/v7_transplant_Sprintf_StrLen_ScanLoop.bin"
Sprintf_StrLen_NotFound:
	.incbin "includes/generated/v7_transplant_Sprintf_StrLen_NotFound.bin"
Sprintf_StrLen_Return:
	.incbin "includes/generated/v7_transplant_Sprintf_StrLen_Return.bin"
Sprintf_FillToEnd:
; v7: Use .org to auto-compute padding to reach Debug_PrintHexByte at 0xFFFE80
	.org 0xfffe80 - 0xe00000, 0xff
Sprintf_FillToVectors:
