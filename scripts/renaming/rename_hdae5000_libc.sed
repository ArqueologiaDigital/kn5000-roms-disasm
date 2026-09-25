# rename_hdae5000_libc.sed -- HD-AE5000 C runtime library (0x299AE7-0x29BAFB)
#
# The HD-AE5000 ROM links the Toshiba C runtime.  Its routines were named after
# whichever caller a pass happened to be reading (PPI_Block_Copy, Cell_Copy_Buffer,
# Directory_Handler_Helper ...) or after a wrong guess (Divide_Signed is the
# UNSIGNED core; StrCopy is strcat; MemCopy_Block is strcpy).  Each new name
# below is justified by the routine's own code in its header; the one-line
# reason is repeated here so this file doubles as the rename map.
#
# Apply:  LC_ALL=C sed -i -f scripts/renaming/rename_hdae5000_libc.sed hdae5000/*.s
#
# --- printf family ---
s/\bHDAE5000_PPI_Block_Copy_Helper\b/HDAE5000_DoPrintf/g
s/\bHDAE5000_PPI_Block_Copy\b/HDAE5000_SPrintf/g
s/\.Lppi_callback\b/HDAE5000_SPrintf_PutChar/g
s/\bHDAE5000_String_Format_Helper\b/HDAE5000_FltDec_Convert/g
s/\bHDAE5000_String_Format_Core\b/HDAE5000_FormatFloat_Fixed/g
s/\bHDAE5000_String_Format_Output\b/HDAE5000_FormatFloat_Exp/g
s/\bHDAE5000_String_Format\b/HDAE5000_FormatFloat/g
# --- integer <-> string ---
s/\bHDAE5000_HD_Partition_Setup_Helper\b/HDAE5000_IToA/g
s/\.Lccb_sign_handler\b/HDAE5000_LToA/g
s/\.Lccb_converter\b/HDAE5000_ULToA/g
s/\bHDAE5000_Cell_Copy_Buffer\b/HDAE5000_LDiv/g
# --- string.h ---
s/\bHDAE5000_String_Copy_N\b/HDAE5000_MemCCpy/g
s/\bHDAE5000_String_Length\b/HDAE5000_MemChr/g
s/\bHDAE5000_File_Read\b/HDAE5000_MemCmp/g
s/\bHDAE5000_StrCopy\b/HDAE5000_StrCat/g
s/\bHDAE5000_StrCopy__/HDAE5000_StrCat__/g
s/\bHDAE5000_Code_Remainder\b/HDAE5000_StrPrefixCmp/g
s/\bHDAE5000_MemCopy_Block\b/HDAE5000_StrCpy/g
s/\bHDAE5000_Display_Buffer_Validate\b/HDAE5000_StrLen/g
s/\bHDAE5000_HD_Read_Write_Helper\b/HDAE5000_StrNCat/g
s/\bHDAE5000_MemCompare_Block\b/HDAE5000_StrNCmp/g
s/\bHDAE5000_Directory_Handler_Helper2\b/HDAE5000_StrUpr/g
s/\bHDAE5000_Directory_Handler_Helper\b/HDAE5000_StrRev/g
# --- float -> decimal digit conversion (multi-precision, RAM 0x23948A..) ---
s/\bHDAE5000_MemCopy_Reverse_Helper10\b/HDAE5000_FltDec_DecimalExponent/g
s/\bHDAE5000_MemCopy_Reverse_Helper9\b/HDAE5000_FltDec_NormalizeRight/g
s/\bHDAE5000_MemCopy_Reverse_Helper8\b/HDAE5000_FltDec_NormalizeLeft/g
s/\bHDAE5000_MemCopy_Reverse_Helper7\b/HDAE5000_FltDec_FracMulBy10/g
s/\bHDAE5000_MemCopy_Reverse_Helper6\b/HDAE5000_FltDec_MulBy10/g
s/\bHDAE5000_MemCopy_Reverse_Helper5\b/HDAE5000_FltDec_DivBy10/g
s/\bHDAE5000_MemCopy_Reverse_Helper4\b/HDAE5000_FltDec_AddDigit/g
s/\bHDAE5000_MemCopy_Reverse_Helper3\b/HDAE5000_FltDec_FractionDigits/g
s/\bHDAE5000_MemCopy_Reverse_Helper2\b/HDAE5000_FltDec_ShiftLeftBits/g
s/\bHDAE5000_MemCopy_Reverse_Helper\b/HDAE5000_FltDec_ShiftRightBits/g
s/\bHDAE5000_MemCopy_Reverse\b/HDAE5000_StrNCpy/g
# --- soft-float and 32-bit integer arithmetic ---
s/\bHDAE5000_Multiply_Sub3\b/HDAE5000_Copy10/g
s/\bHDAE5000_Multiply_Sub2\b/HDAE5000_Float_Pack/g
s/\bHDAE5000_Multiply_Sub\b/HDAE5000_Float_Unpack/g
s/\bHDAE5000_Multiply_Helper\b/HDAE5000_ULong_To_Unpacked/g
s/\bHDAE5000_Display_String_Render_Helper25\b/HDAE5000_Copy8/g
s/\bHDAE5000_PPI_Write_Sector_Helper4\b/HDAE5000_ULongToFloat/g
s/\bHDAE5000_PPI_Write_Sector_Helper5\b/HDAE5000_FloatDiv/g
s/\.LMUL_b870\b/HDAE5000_SDivMod32_Common/g
s/\bHDAE5000_Cell_Copy_Buffer_Helper2\b/HDAE5000_SDiv32/g
s/\bHDAE5000_Cell_Copy_Buffer_Helper\b/HDAE5000_SMod32/g
s/\bHDAE5000_Divide_Unsigned\b/HDAE5000_UMod32/g
s/\bHDAE5000_Divide_Signed_Helper\b/HDAE5000_Double_Pack/g
s/\bHDAE5000_Divide_Signed_Sub3\b/HDAE5000_Unpacked_Div/g
s/\bHDAE5000_Divide_Signed_Sub2\b/HDAE5000_FloatToDouble/g
s/\bHDAE5000_Divide_Signed_Sub\b/HDAE5000_Long_To_Unpacked/g
s/\bHDAE5000_Divide_Signed\b/HDAE5000_UDivMod32/g
# --- HDAE5000_DoPrintf switch targets (HDAE5000_DoPrintf_ConvTable) ---
s/\.LDSR_9cd6\b/HDAE5000_DoPrintf_Case_Char/g
s/\.LDSR_a360\b/HDAE5000_DoPrintf_Case_Float/g
s/\.LDSR_a3b7\b/HDAE5000_DoPrintf_NextChar/g
s/\.LDSR_a088\b/HDAE5000_DoPrintf_Case_Hex/g
