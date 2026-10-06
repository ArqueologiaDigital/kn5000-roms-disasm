# HDAE5000_TableData_Write's flash steps, named by what they do (helper-naming batch g finding; v10/v9/v7)
s/\bHDAE5000_ROM_Transfer\b/HDAE5000_VerifyFlashAgainstWindow/g
s/\bHDAE5000_FlashVerify_BytecodeBlock\b/HDAE5000_ProgramTableDataFlash/g
