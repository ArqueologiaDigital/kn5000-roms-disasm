#!/usr/bin/env python3
"""Rename LABEL_* to semantic names in kn5000_v10_program.s (file load/SMF/variable screen).

Three function regions (~477 labels total):

1. LoadFileSMF (F88009 - F88B84)
   ~131 labels across 18+ sub-functions for floppy disk file I/O:
   - LoadFileSMF: Load SMF file from disk page
   - LoadFileVariant: Alternate SMF load with different parameters
   - LoadFileMultiPass: Multi-pass file loader with 10-pass retry loop
   - LoadFileMultiPassAlt: Similar multi-pass with different setup
   - ReadSingleFile: Single-pass file read (10 retries)
   - ReadDualFile: Dual-file read with cross-file verification
   - ReadDualFileEx: Extended dual-file read with two page bases
   - WriteFileWithVerify: Write file then verify by reading back
   - GetFirstRecordAndOpen: Shortcut: get first page record -> open default
   - SearchAndOpen: Search file table, open or create record
   - LoadFromSecondaryPage: Load file from secondary (user) page
   - FileIO_ReturnError: Return error status from global
   - FileIO_OpenWithMode: Open file with mode (r/w) and error handling
   - FileIO_CloseHandle: Close file handle if open
   - FileIO_OpenDefault: Open file with default parameters
   - FileIO_CopyAndOpen: Copy rename buffers, open two files for copy
   - FileIO_ReadByte: Read single byte from open file
   - FileIO_SeekAndRead: Seek to offset then read block
   - FileIO_WriteBlock: Write block to open file
   - FileIO_CopyString: Copy null-terminated string from src to dst
   - FileIO_BuildFilePath: Build full path string (dir + filename)
   - FileIO_SearchFile: Search for file in directory listing
   - FileIO_FormatFileIndex: Format file index as 2-digit decimal string
   - FileIO_ReadHeader: Read and parse file header structure
   - FileIO_GetRecordType: Get record type byte for file index

2. GetFileCountEncoded (F89C8C - F8A7CB)
   ~211 labels across 20+ sub-functions for encoded file count/page management:
   - GetFileCountEncoded: Initialize and count encoded files on second page
   - ReadVariableLengthInt: Parse MIDI-style variable-length integer from file
   - ReadFieldToBuffer: Read N bytes from file into buffer, with name trimming
   - ParseSMFTrackName: Parse SMF track name from meta-events (FF 03)
   - ProcessFileRecord: Process a single file record (seek, read header, parse data)
   - GetFileEntryByIndex: Get file entry pointer by page-relative index
   - GetFileEntryByIndexAlt: Alternate get-entry with different page base
   - GetFileCountEncodedAlt: Count encoded files (alt page variant)
   - TrimAndFormatFilename: Trim control chars, pad with spaces, remove separator
   - DetectFileType: Detect file type (6=standard, 7=extended) and open
   - ValidateFileRange: Validate file index in range for current page
   - ValidateFileRangeAlt: Validate range for alternate page layout
   - SetCurrentFileIndex: Set current file index, adjust page boundaries
   - SetCurrentFileIndexAlt: Set file index for alternate layout
   - GetFileRecordPtr: Get pointer to file record by index
   - GetFileRecordPtrAlt: Get record pointer for alternate layout
   - BuildPageRecordsAlt: Build second page records for alternate layout

3. RVariScreenProc (FBF537 - FC1A22)
   ~133 labels in a large event-dispatch screen procedure:
   - Main event dispatcher for variable-parameter screen
   - Handles events: 0x1C00001 (Init), 0x1C0000B (Show), 0x1C0000D (Paint),
     0x1C0000E (Select), 0x1C0000F (Confirm), 0x1E2000B (EnumNotify),
     0x1C00007 (OK)
   - Sub-handlers for numeric-type vs pattern-type display modes
   - Key/dial input handlers with boundary checks (0x88-0x8C, 0x8-0xC)
   - Audio preview via Sprintf_Locked
   - Page scroll (up=0x10, down=0x90) with wrap-around

Uses binary I/O with latin-1 encoding.
Never use the Edit tool on kn5000_v10_program.s -- it corrupts Latin-1.
"""

import os
import re

# ---------------------------------------------------------------------------
# Rename table: (old_label, new_label, brief_comment)
# ---------------------------------------------------------------------------

RENAMES = [
    # ======================================================================
    # LoadFileSMF region (F88009 - F88B84)
    # SMF and general file I/O functions
    # ======================================================================

    # --- LoadFileSMF (226418) ---
    # Loads an SMF file: get first page, get record ptr, open file, process
    ('LABEL_F8801B', 'LoadSMF_GetRecordPtr',
     'Page base >= 0: get record ptr for file'),
    ('LABEL_F8803A', 'LoadSMF_OpenAndProcess',
     'Record found: open file via BC=0xEA0240, then call process routines'),
    ('LABEL_F88057', 'LoadSMF_Return',
     'Common exit: popw iz, adjust stack, ret'),

    # --- LoadFileVariant (226458 LABEL_F8805B) ---
    # Variant load: different entry buffer (0xEA0244), different processor
    ('LABEL_F8805B', 'LoadFileVariant',
     'Alternate file load entry: uses F892D5 for record, opens via 0xEA0244'),
    ('LABEL_F88083', 'LoadVariant_OpenAndProcess',
     'File record valid: read file-type byte, open with mode params'),
    ('LABEL_F880A7', 'LoadVariant_CheckResult',
     'Check if process returned error (iz < 0)'),
    ('LABEL_F880A9', 'LoadVariant_Return',
     'Common exit: popw iz, adjust stack, ret'),

    # --- LoadFileMultiPass (226497 LABEL_F880AD) ---
    # Multi-pass file loader with 10-pass retry loop and error accumulation
    ('LABEL_F880AD', 'LoadFileMultiPass',
     'Multi-pass file load: allocates stack frame, gets first page base'),
    ('LABEL_F880C8', 'MultiPass_SetupEntry',
     'Page valid: read file-type byte, get entry ptr, init header buffer'),
    ('LABEL_F880E4', 'MultiPass_RetryLoop',
     'Inner loop (10 passes): read/verify record, process header, check result'),
    ('LABEL_F88119', 'MultiPass_LoopNext',
     'Increment pass counter iz, loop while < 10'),
    ('LABEL_F8815A', 'MultiPass_Finalize',
     'All passes done: call F47C70 finalization, close file handle'),
    ('LABEL_F88176', 'MultiPass_StoreResult',
     'Store accumulated result to ERP work area'),
    ('LABEL_F88179', 'MultiPass_Return',
     'Exit: pop xiz, restore stack, ret'),

    # --- LABEL_F8817E (226580) - .byte data block ---
    # Large block of encoded instructions (not decoded yet)
    ('LABEL_F8817E', 'FileIO_ByteBlock_F8817E',
     'Undecoded .byte block: file I/O helper (needs LLVM backend additions)'),

    # --- ReadSingleFile (226767 LABEL_F8872D) ---
    # Single file read with 10-pass retry loop
    ('LABEL_F8872D', 'ReadSingleFile',
     'Read single file: alloc stack, init ERP, get first page base'),
    ('LABEL_F88743', 'ReadSingle_SetupEntry',
     'Page valid: get file entry ptr, init header buffer with file type'),
    ('LABEL_F88759', 'ReadSingle_RetryLoop',
     'Inner loop (10 passes): read record, write header, close handle'),
    ('LABEL_F8878E', 'ReadSingle_LoopNext',
     'Increment pass counter, loop while < 10'),
    ('LABEL_F88796', 'ReadSingle_StoreResult',
     'Store result to ERP work area'),
    ('LABEL_F88799', 'ReadSingle_Return',
     'Exit: pop xiz, restore stack, ret'),

    # --- ReadDualFile (226818 LABEL_F8879E) ---
    # Dual-file read with cross-verification
    ('LABEL_F8879E', 'ReadDualFile',
     'Read two files: alloc 52-byte frame, init ERP, get page base'),
    ('LABEL_F887B7', 'ReadDual_SetupEntries',
     'Page valid: get entry ptr, init both header buffers'),
    ('LABEL_F887DC', 'ReadDual_RetryLoop',
     'Inner loop: read both records, cross-verify via F88C9C'),
    ('LABEL_F88828', 'ReadDual_LoopNext',
     'Increment pass, loop while < 10'),
    ('LABEL_F88830', 'ReadDual_StoreResult',
     'Store result to ERP work area'),
    ('LABEL_F88833', 'ReadDual_Return',
     'Exit: pop xiz, restore stack, ret'),

    # --- ReadDualFileEx (226881 LABEL_F88838) ---
    # Extended dual-file read with two separate page bases
    ('LABEL_F88838', 'ReadDualFileEx',
     'Extended dual-file read: 60-byte frame, separate page bases'),
    ('LABEL_F88856', 'ReadDualEx_SetupPages',
     'Get entry ptrs for both source and destination file pages'),
    ('LABEL_F8888A', 'ReadDualEx_FirstLoop',
     'First retry loop: read destination file records (10 passes)'),
    ('LABEL_F888DA', 'ReadDualEx_FirstLoopNext',
     'Increment pass counter for first loop'),
    ('LABEL_F88906', 'ReadDualEx_SecondLoop',
     'Second retry loop: read source file records (10 passes)'),
    ('LABEL_F88952', 'ReadDualEx_SecondLoopNext',
     'Increment pass counter for second loop, prepare third loop'),
    ('LABEL_F8897A', 'ReadDualEx_ThirdLoop',
     'Third retry loop: read from destination page for cross-verify'),
    ('LABEL_F889C9', 'ReadDualEx_ThirdLoopNext',
     'Increment pass counter for third loop'),
    ('LABEL_F889D1', 'ReadDualEx_StoreResult',
     'Store accumulated result to ERP'),
    ('LABEL_F889D4', 'ReadDualEx_Return',
     'Exit: pop xiz, restore 60-byte stack, ret'),

    # --- WriteFileWithVerify (227030 LABEL_F889D9) ---
    # Write file to disk then verify by reading back
    ('LABEL_F889D9', 'WriteFileWithVerify',
     'Write file then verify: 58-byte frame, get first page base'),
    ('LABEL_F889F9', 'WriteVerify_InitCounters',
     'Page valid: init total-written counter, begin write loop'),
    ('LABEL_F88A00', 'WriteVerify_WriteLoop',
     'Write loop: iterate 10 passes, call UpdateFileEntry per pass'),
    ('LABEL_F88A26', 'WriteVerify_WriteLoopNext',
     'Increment write pass counter, check free space after'),
    ('LABEL_F88A3D', 'WriteVerify_SetupReadback',
     'Write done: get dest entry ptr, prepare for read-back verification'),
    ('LABEL_F88A56', 'WriteVerify_ReadbackLoop',
     'Readback loop: read written records back, verify via open-default'),
    ('LABEL_F88A91', 'WriteVerify_ReadbackNext',
     'Increment readback pass, transition to cross-verify'),
    ('LABEL_F88AC4', 'WriteVerify_CrossVerifyLoop',
     'Cross-verify loop: compare written data with read-back via F88F75'),
    ('LABEL_F88B12', 'WriteVerify_CrossVerifyNext',
     'Increment cross-verify pass counter'),
    ('LABEL_F88B1A', 'WriteVerify_GetStatus',
     'Retrieve final status from stack variable'),
    ('LABEL_F88B1D', 'WriteVerify_Return',
     'Exit: pop xiz, restore 58-byte stack, ret'),

    # --- GetFirstRecordAndOpen (227155 LABEL_F88B22) ---
    ('LABEL_F88B22', 'GetFirstRecordAndOpen',
     'Shortcut: get first page base, get record ptr, jump to open-default'),
    ('LABEL_F88B2E', 'GetFirstRecord_GotPage',
     'Page valid: get record ptr then tail-call FileIO_OpenDefault'),

    # --- SearchAndOpen (227168 LABEL_F88B3A) ---
    ('LABEL_F88B3A', 'SearchAndOpen',
     'Search file table for match; if not found, create new record and open'),
    ('LABEL_F88B54', 'SearchOpen_DoSearch',
     'Perform search via F5298A; if found skip to create'),
    ('LABEL_F88B7D', 'SearchOpen_AlreadyExists',
     'File already exists: call F52AAA, return error 0xFFF6'),
    ('LABEL_F88B84', 'SearchOpen_Return',
     'Exit: popw iz, store result byte, ret'),

    # --- LoadFromSecondaryPage (227202 LABEL_F88B8B) ---
    ('LABEL_F88B8B', 'LoadFromSecondaryPage',
     'Load from secondary (user) page: get page base via F8B015'),
    ('LABEL_F88B99', 'LoadSecondary_OpenFile',
     'Page valid: get record ptr via F8B13D, open with mode 0xEA0264'),
    ('LABEL_F88BB4', 'LoadSecondary_Process',
     'File opened: call FAE86D processor, close handle'),
    ('LABEL_F88BC0', 'LoadSecondary_Return',
     'Exit: popw iz, ret'),

    # --- FileIO_ReturnError (227231 LABEL_F88BC2) ---
    ('LABEL_F88BC2', 'FileIO_ReturnError',
     'Load global error status (addr 32584) into xhl and return'),

    # --- FileIO_OpenWithMode (227235 LABEL_F88BC7) ---
    # Open file with specific mode ('r' or 'w') and error code handling
    ('LABEL_F88BC7', 'FileIO_OpenWithMode',
     'Open file: copy 128-byte path buffer, build path, call FileOpen'),
    ('LABEL_F88C08', 'FileIO_OpenMode_CheckWrite',
     'Mode not r: check if w (write mode)'),
    ('LABEL_F88C21', 'FileIO_OpenMode_WriteMaxFiles',
     'Write mode, max files reached (31): return error 0xFFF5'),
    ('LABEL_F88C2C', 'FileIO_OpenMode_UnknownMode',
     'Unknown mode: return error 0xFFFF'),
    ('LABEL_F88C37', 'FileIO_OpenMode_Success',
     'FileOpen succeeded: store 0 to global status'),
    ('LABEL_F88C41', 'FileIO_OpenMode_Return',
     'Exit: pop xiz, store result byte, ret'),

    # --- FileIO_CloseHandle (227289 LABEL_F88C48) ---
    ('LABEL_F88C48', 'FileIO_CloseHandle',
     'Close file handle if open (global 32580), reset to 0'),
    ('LABEL_F88C5D', 'FileIO_CloseHandle_Done',
     'Handle already null or closed: return hl=0'),

    # --- FileIO_OpenDefault (227303 LABEL_F88C60) ---
    ('LABEL_F88C60', 'FileIO_OpenDefault',
     'Open file with default params: copy 16-byte path, build path, call FileOpenDefault'),
    ('LABEL_F88C8A', 'FileIO_OpenDefault_CheckMaxFiles',
     'FileOpenDefault returned error: check if max-files error (0x1F)'),
    ('LABEL_F88C95', 'FileIO_OpenDefault_OtherError',
     'Other open error: return 0xFFFD'),
    ('LABEL_F88C98', 'FileIO_OpenDefault_Return',
     'Exit: restore 16-byte stack, ret'),

    # --- FileIO_CopyAndOpen (227335 LABEL_F88C9C) ---
    ('LABEL_F88C9C', 'FileIO_CopyAndOpen',
     'Copy-and-open: copies two 16-byte path buffers, calls F4F421 (file copy)'),
    ('LABEL_F88CE6', 'FileIO_CopyOpen_CheckMaxFiles',
     'Copy returned error: check if max-files (31)'),
    ('LABEL_F88CF4', 'FileIO_CopyOpen_OtherError',
     'Other copy error: return 0xFFFD'),
    ('LABEL_F88CF7', 'FileIO_CopyOpen_Return',
     'Exit: pop xiz, restore 32-byte stack, ret'),

    # --- FileIO_ReadByte (227379 LABEL_F88CFC) ---
    ('LABEL_F88CFC', 'FileIO_ReadByte',
     'Read single byte from open file handle (global 32580)'),
    ('LABEL_F88D14', 'FileIO_ReadByte_NoHandle',
     'No file handle open: return error 0xFF9C'),
    ('LABEL_F88D19', 'FileIO_ReadByte_CheckEOF',
     'Read ok but check for EOF condition'),
    ('LABEL_F88D1D', 'FileIO_ReadByte_Return',
     'Exit with byte in hl'),

    # --- FileIO_SeekAndRead (227405-227443) ---
    ('LABEL_F88D27', 'FileIO_ReadByte_Extended',
     'Extended read: handle read-ahead buffer management'),
    ('LABEL_F88D2C', 'FileIO_ReadByte_BufferHit',
     'Buffer contains data: return byte from buffer'),
    ('LABEL_F88D5A', 'FileIO_SeekAndRead_NoHandle',
     'Seek failed: no handle open'),
    ('LABEL_F88D5F', 'FileIO_SeekAndRead_Error',
     'Seek/read returned error'),
    ('LABEL_F88D62', 'FileIO_SeekAndRead_Return',
     'Exit from seek-and-read'),
    ('LABEL_F88D6C', 'FileIO_SeekToOffset',
     'Seek to specific offset in open file'),

    # --- FileIO_ReadBlock (227449 LABEL_F88D74) ---
    ('LABEL_F88D74', 'FileIO_ReadBlock',
     'Read block of bc bytes into buffer at xwa from open file'),
    ('LABEL_F88D98', 'FileIO_ReadBlock_Loop',
     'Read block loop: read bc bytes one at a time via FileIO_ReadByte'),
    ('LABEL_F88DAB', 'FileIO_ReadBlock_Done',
     'Block read complete or error encountered'),

    # --- FileIO byte-level helpers (227493-227613) ---
    ('LABEL_F88DE3', 'FileIO_WriteBlock_NoHandle',
     'Write block: no handle open, return error'),
    ('LABEL_F88DF4', 'FileIO_WriteBlock_CheckResult',
     'Check write result for errors'),
    ('LABEL_F88DFB', 'FileIO_WriteBlock_LoopNext',
     'Advance write loop: increment offset, check count'),
    ('LABEL_F88E02', 'FileIO_WriteBlock_Error',
     'Write block encountered error'),
    ('LABEL_F88E09', 'FileIO_WriteBlock_Return',
     'Exit from write block'),
    ('LABEL_F88E14', 'FileIO_WriteWord',
     'Write 16-bit word to file'),
    ('LABEL_F88E20', 'FileIO_WriteByte',
     'Write single byte to file'),
    ('LABEL_F88E28', 'FileIO_WriteByte_Impl',
     'Write byte implementation: check handle, call F4F30D'),
    ('LABEL_F88E4D', 'FileIO_WriteByte_NoHandle',
     'Write byte: no handle, return error 0xFF9C'),
    ('LABEL_F88E60', 'FileIO_WriteByte_Return',
     'Exit from write byte'),
    ('LABEL_F88E96', 'FileIO_FlushBuffer',
     'Flush write buffer to disk'),
    ('LABEL_F88E9D', 'FileIO_FlushBuffer_Return',
     'Exit from flush buffer'),
    ('LABEL_F88EB3', 'FileIO_FlushAndClose',
     'Flush buffer then close file handle'),
    ('LABEL_F88EBA', 'FileIO_FlushClose_Return',
     'Exit from flush-and-close'),
    ('LABEL_F88EC1', 'FileIO_GetPosition',
     'Get current file position/offset'),
    ('LABEL_F88ECC', 'FileIO_GetPosition_Return',
     'Exit from get position'),
    ('LABEL_F88ED8', 'FileIO_CheckHandle',
     'Verify file handle is valid (non-null)'),

    # --- FileIO_SeekAndRead (227613 LABEL_F88EE0) ---
    ('LABEL_F88EE0', 'FileIO_SeekAndReadBlock',
     'Seek to offset xwa then read bc bytes from open file'),
    ('LABEL_F88EFE', 'FileIO_SeekRead_NoHandle',
     'No handle: return error'),
    ('LABEL_F88F01', 'FileIO_SeekRead_Return',
     'Exit from seek-and-read-block'),
    ('LABEL_F88F0B', 'FileIO_SeekRead_Extended',
     'Extended seek-read with additional buffer management'),
    ('LABEL_F88F10', 'FileIO_SeekRead_ExtReturn',
     'Exit from extended seek-read'),

    # --- FileIO_CopyFile (227651-227696) ---
    ('LABEL_F88F24', 'FileIO_SeekWrite_NoHandle',
     'Seek-write: no handle, return error'),
    ('LABEL_F88F27', 'FileIO_SeekWrite_Return',
     'Exit from seek-write'),
    ('LABEL_F88F31', 'FileIO_SeekWriteBlock',
     'Seek to offset then write block'),
    ('LABEL_F88F39', 'FileIO_SeekWriteBlock_Impl',
     'Seek-write implementation: call seek then write'),
    ('LABEL_F88F57', 'FileIO_SeekWriteBlock_NoHandle',
     'Seek-write-block: no handle'),
    ('LABEL_F88F5E', 'FileIO_SeekWriteBlock_Error',
     'Seek-write-block error'),
    ('LABEL_F88F66', 'FileIO_SeekWriteBlock_Return',
     'Exit from seek-write-block'),
    ('LABEL_F88F70', 'FileIO_SeekWriteBlock_Done',
     'Seek-write-block completed successfully'),

    # --- FileIO_CopyAndVerify (227696 LABEL_F88F75) ---
    ('LABEL_F88F75', 'FileIO_CompareFiles',
     'Compare two file records byte-by-byte for verification'),
    ('LABEL_F88FCF', 'FileIO_Compare_Mismatch',
     'Byte mismatch detected during comparison'),
    ('LABEL_F88FD5', 'FileIO_Compare_Return',
     'Exit from file comparison'),

    # --- FileIO header/record parsing (227753-227845) ---
    ('LABEL_F89008', 'FileIO_ParseHeader_CheckType',
     'Parse header: check file type field'),
    ('LABEL_F89010', 'FileIO_ParseHeader_ReadFields',
     'Read header fields into structure'),
    ('LABEL_F89042', 'FileIO_ParseHeader_Done',
     'Header parsing complete'),
    ('LABEL_F89057', 'FileIO_ParseHeader_Error',
     'Header parse error: invalid format'),
    ('LABEL_F8905C', 'FileIO_ParseHeader_Return',
     'Exit from header parser'),
    ('LABEL_F8908A', 'FileIO_ValidateRecord',
     'Validate record structure integrity'),
    ('LABEL_F89091', 'FileIO_ValidateRecord_CheckSize',
     'Check record size against expected'),
    ('LABEL_F8909E', 'FileIO_ValidateRecord_Fail',
     'Record validation failed'),
    ('LABEL_F890AB', 'FileIO_ValidateRecord_Ok',
     'Record validation passed'),
    ('LABEL_F890AF', 'FileIO_ValidateRecord_Return',
     'Exit from record validation'),

    # --- FileIO_CopyString (227845 LABEL_F890DC) ---
    ('LABEL_F890DC', 'FileIO_CopyString',
     'Copy null-terminated string from xbc to xwa'),
    ('LABEL_F890E3', 'FileIO_CopyString_Loop',
     'Copy loop: transfer bytes until null terminator'),
    ('LABEL_F890EE', 'FileIO_CopyString_Done',
     'Source is empty/null: write terminator to dest'),
    ('LABEL_F890F2', 'FileIO_CopyString_WriteNull',
     'Write null terminator and return'),
    ('LABEL_F890F6', 'FileIO_CopyString_Advance',
     'Advance source and dest pointers'),
    ('LABEL_F890FE', 'FileIO_CopyString_CheckEnd',
     'Check if source byte is null (end of string)'),
    ('LABEL_F89107', 'FileIO_CopyString_StoreAndCont',
     'Store byte to dest, continue loop'),
    ('LABEL_F8910B', 'FileIO_CopyString_Return',
     'Exit from string copy'),

    # --- FileIO_BuildFilePath (227884 LABEL_F89113) ---
    ('LABEL_F89113', 'FileIO_BuildFilePath',
     'Build file path: concatenate directory path with filename'),
    ('LABEL_F8911A', 'FileIO_BuildPath_CopyDir',
     'Copy directory path bytes'),
    ('LABEL_F89121', 'FileIO_BuildPath_NullDir',
     'Directory is empty: start filename at beginning'),
    ('LABEL_F89126', 'FileIO_BuildPath_AddSep',
     'Add path separator between directory and filename'),
    ('LABEL_F89131', 'FileIO_BuildPath_Return',
     'Exit from path builder'),

    # --- FileIO_SearchFile (227908 LABEL_F89135) ---
    ('LABEL_F89135', 'FileIO_SearchFile',
     'Search for filename in directory listing'),
    ('LABEL_F89139', 'FileIO_Search_CompareChar',
     'Compare characters in search loop'),
    ('LABEL_F89140', 'FileIO_Search_Match',
     'Characters match: advance to next'),
    ('LABEL_F89146', 'FileIO_Search_CheckNext',
     'Check next entry in directory'),
    ('LABEL_F89153', 'FileIO_Search_SkipEntry',
     'Entry does not match: skip to next'),
    ('LABEL_F89157', 'FileIO_Search_EndOfList',
     'Reached end of directory listing'),
    ('LABEL_F8915F', 'FileIO_Search_Found',
     'File found in directory'),
    ('LABEL_F89165', 'FileIO_Search_NotFound',
     'File not found in directory'),
    ('LABEL_F8916F', 'FileIO_Search_Error',
     'Search encountered error'),
    ('LABEL_F89179', 'FileIO_Search_Return',
     'Exit from file search'),

    # --- FileIO_FormatFileIndex (227966 LABEL_F8917E) ---
    ('LABEL_F8917E', 'FileIO_FormatFileIndex',
     'Format file index as decimal string: tens digit + ones digit'),
    ('LABEL_F8918B', 'FileIO_FormatIndex_TwoDigit',
     'Index >= 10: compute tens and ones digits'),
    ('LABEL_F89199', 'FileIO_FormatIndex_AddOnes',
     'Add ones digit and null terminator'),
    ('LABEL_F891A0', 'FileIO_FormatIndex_AddChar',
     'Store character to output string'),

    # --- FileIO_ReadHeader (227990 LABEL_F891AB) ---
    ('LABEL_F891AB', 'FileIO_ReadHeader',
     'Read file header: open file, parse header structure, close'),
    ('LABEL_F891DD', 'FileIO_ReadHeader_ParseLoop',
     'Header parse loop: read fields sequentially'),
    ('LABEL_F89218', 'FileIO_ReadHeader_Done',
     'Header parsing complete, validate checksums'),
    ('LABEL_F8923C', 'FileIO_ReadHeader_Field1',
     'Parse header field 1 (type byte)'),
    ('LABEL_F89248', 'FileIO_ReadHeader_Field2',
     'Parse header field 2 (size word)'),
    ('LABEL_F89254', 'FileIO_ReadHeader_Field3',
     'Parse header field 3 (offset/address)'),
    ('LABEL_F89260', 'FileIO_ReadHeader_Field4',
     'Parse header field 4 (checksum)'),
    ('LABEL_F89262', 'FileIO_ReadHeader_FieldDone',
     'Current field parsed, advance to next'),
    ('LABEL_F89266', 'FileIO_ReadHeader_Return',
     'Exit from header reader'),

    # --- FileIO record-type helpers (228091-228136) ---
    ('LABEL_F8927D', 'FileIO_GetRecordType_CheckRange',
     'Check record type byte against valid range'),
    ('LABEL_F89281', 'FileIO_GetRecordType_Dispatch',
     'Dispatch based on record type value'),
    ('LABEL_F89290', 'FileIO_GetRecordType_Standard',
     'Standard record type (0x00-0x09)'),
    ('LABEL_F8929D', 'FileIO_GetRecordType_Extended',
     'Extended record type (0x0A+)'),
    ('LABEL_F892A2', 'FileIO_GetRecordType_Error',
     'Invalid record type: return error'),
    ('LABEL_F892AB', 'FileIO_GetRecordType_Return',
     'Exit from get-record-type'),
    ('LABEL_F892B2', 'FileIO_GetRecordType_ReturnOk',
     'Return with valid record type in hl'),
    ('LABEL_F892B4', 'FileIO_GetRecordType_Alt',
     'Alternate record type lookup'),

    # --- FileIO record pointer helpers (228136-228293) ---
    ('LABEL_F892BC', 'FileIO_GetRecordByType',
     'Get record pointer by file type (different from index-based)'),
    ('LABEL_F892C2', 'FileIO_GetRecordByType_Lookup',
     'Look up record in type-based table'),
    ('LABEL_F892D5', 'FileIO_GetRecordPtrAlt',
     'Get record pointer (alternate entry using F895EF)'),
    ('LABEL_F892DB', 'FileIO_WriteRecordName',
     'Write record name string to output buffer'),
    ('LABEL_F892EF', 'FileIO_WriteRecordName_Loop',
     'Name write loop: copy bytes with formatting'),
    ('LABEL_F892F5', 'FileIO_WriteRecordName_Done',
     'Name write complete'),
    ('LABEL_F89309', 'FileIO_WriteRecordName_Pad',
     'Pad name with spaces to fixed width'),
    ('LABEL_F8930C', 'FileIO_WriteRecordName_Return',
     'Exit from write record name'),
    ('LABEL_F89315', 'FileIO_FormatRecordName',
     'Format record name with prefix decoration'),
    ('LABEL_F89321', 'FileIO_FormatName_Loop',
     'Formatting loop: add prefix bytes'),
    ('LABEL_F8932F', 'FileIO_FormatName_NoPrefix',
     'Skip prefix for certain record types'),
    ('LABEL_F89335', 'FileIO_FormatName_Copy',
     'Copy formatted name to output'),
    ('LABEL_F89343', 'FileIO_FormatName_CopyLoop',
     'Copy loop for formatted name bytes'),
    ('LABEL_F8934D', 'FileIO_FormatName_Done',
     'Formatted name copy complete'),
    ('LABEL_F89353', 'FileIO_FormatName_Return',
     'Exit from format record name'),

    # --- FileIO additional record helpers (228228-228293) ---
    ('LABEL_F89367', 'FileIO_BuildRecordPath',
     'Build full path for a file record'),
    ('LABEL_F8936A', 'FileIO_BuildRecordPath_Loop',
     'Path building loop'),
    ('LABEL_F89373', 'FileIO_BuildRecordPath_AddExt',
     'Add file extension to path'),
    ('LABEL_F8937F', 'FileIO_BuildRecordPath_Done',
     'Record path building complete'),
    ('LABEL_F8938D', 'FileIO_BuildRecordPath_Error',
     'Error building record path'),
    ('LABEL_F89393', 'FileIO_BuildRecordPath_Return',
     'Exit from build record path'),
    ('LABEL_F893A1', 'FileIO_GetRecordAttr',
     'Get record attribute byte for given index'),
    ('LABEL_F893AB', 'FileIO_GetRecordAttr_Check',
     'Validate attribute byte against expected'),
    ('LABEL_F893BA', 'FileIO_GetRecordAttr_Return',
     'Exit from get record attribute'),
    ('LABEL_F893BD', 'FileIO_GetRecordAttr_Default',
     'Return default attribute when not found'),

    # --- FileIO_CheckRecordValid (228293 LABEL_F893D1) ---
    ('LABEL_F893D1', 'FileIO_CheckRecordValid',
     'Check if record at index is valid (within page bounds)'),
    ('LABEL_F89408', 'FileIO_CheckRecordByFile',
     'Check record validity by file number (with type validation)'),

    # --- FileIO_GetDiskFreeSpace (228467 LABEL_F89556) ---
    ('LABEL_F89556', 'FileIO_GetDiskFreeSpace',
     'Get free space on floppy disk via GetDiskFreeSpace'),

    # ======================================================================
    # GetFileCountEncoded region (F89C8C - F8A7CB)
    # Encoded file count, variable-length parsing, page management
    # ======================================================================

    # --- GetFileCountEncoded (229295) ---
    ('LABEL_F89C93', 'GetFileCount_StoreAndClamp',
     'Store file count, clamp to max page entries (wa = count - 1 if count > 0)'),

    # --- ReadVariableLengthInt (229312 LABEL_F89CA5) ---
    ('LABEL_F89CA5', 'ReadVariableLengthInt',
     'Parse MIDI-style variable-length integer: accumulate 7-bit groups'),
    ('LABEL_F89CAA', 'ReadVarLen_AccumulateLoop',
     'Loop: extract 7 bits, shift-left 7, continue if MSB set'),
    ('LABEL_F89CB5', 'ReadVarLen_ReadNext',
     'Read next byte via FileIO_ReadByte, check if continuation (> 0x7F)'),
    ('LABEL_F89CC8', 'ReadVarLen_Negative',
     'Read byte was negative (error): return 0xFFFF'),
    ('LABEL_F89CDB', 'ReadVarLen_Return',
     'Exit: clamp result to 0x7FFF max, pop xiz, ret'),

    # --- ReadFieldToBuffer (229344 LABEL_F89CDD) ---
    ('LABEL_F89CDD', 'ReadFieldToBuffer',
     'Read N bytes from file into buffer, with name-length trimming'),
    ('LABEL_F89CFF', 'ReadField_ShortLoop',
     'Short field (len <= 64): read bytes into buffer via FileIO_ReadByte'),
    ('LABEL_F89D09', 'ReadField_StoreByte',
     'Store read byte to buffer (negative bytes become 0)'),
    ('LABEL_F89D1F', 'ReadField_LongInit',
     'Long field (len > 64): init leading-space-skip flag'),
    ('LABEL_F89D24', 'ReadField_LongLoop',
     'Long field loop: read byte, check leading space, store to buffer'),
    ('LABEL_F89D48', 'ReadField_Long_CheckSpace',
     'Not still in leading spaces: store the byte unconditionally'),
    ('LABEL_F89D4A', 'ReadField_Long_StoreIfNotLeading',
     'Only store if not a leading space (0x20)'),
    ('LABEL_F89D55', 'ReadField_DiscardExtra',
     'Buffer full: discard remaining bytes'),
    ('LABEL_F89D5C', 'ReadField_DiscardLoop',
     'Discard loop: read and throw away excess bytes'),
    ('LABEL_F89D6A', 'ReadField_Terminate',
     'Write null terminator, begin trailing-space trim'),
    ('LABEL_F89D75', 'ReadField_TrimSpace',
     'Trim trailing spaces: replace space with null'),
    ('LABEL_F89D78', 'ReadField_TrimLoop',
     'Trailing space trim loop: decrement iz, check for space'),
    ('LABEL_F89D8B', 'ReadField_Return',
     'Exit: popw iz, adjust stack, ret'),

    # --- ParseSMFTrackName (229430 LABEL_F89D8F) ---
    ('LABEL_F89D8F', 'ParseSMFTrackName',
     'Parse SMF track name from file: find FF 03 meta-event, read name'),
    ('LABEL_F89DA3', 'ParseSMF_ReadEvent',
     'Main parse loop: read event byte, dispatch by type'),
    ('LABEL_F89DCC', 'ParseSMF_CheckSysex',
     'Not meta-event (0xFF): check for SysEx (0xF0/0xF7)'),
    ('LABEL_F89DD8', 'ParseSMF_SysexReadLen',
     'SysEx event: read variable-length data size'),
    ('LABEL_F89DDD', 'ParseSMF_ResetRunning',
     'Reset running status counter after meta/sysex'),
    ('LABEL_F89DE0', 'ParseSMF_SkipDataBytes',
     'Skip remaining data bytes (iz = count to skip)'),
    ('LABEL_F89DE4', 'ParseSMF_SkipLoop',
     'Skip loop: seek forward by iz bytes via FileIO_SeekAndReadBlock'),
    ('LABEL_F89DEE', 'ParseSMF_CheckEOF',
     'Check for end-of-track or file error after skip'),
    ('LABEL_F89DFA', 'ParseSMF_CheckMIDI',
     'Check MIDI status byte ranges (channel messages)'),
    ('LABEL_F89E0A', 'ParseSMF_Check3ByteMsg',
     'Check if 3-byte MIDI message (0x80-0xEF, excluding 0xC0-0xDF)'),
    ('LABEL_F89E18', 'ParseSMF_SetRunningStatus',
     'Save running status, continue skip loop'),
    ('LABEL_F89E1D', 'ParseSMF_CheckDataByte',
     'Data byte (< 0x80): check running status for message length'),
    ('LABEL_F89E35', 'ParseSMF_RunningStatus3Byte',
     'Running status is 3-byte message: set iz=2'),
    ('LABEL_F89E39', 'ParseSMF_ReadDeltaAndLoop',
     'Read next delta-time, loop back to read next event'),
    ('LABEL_F89E41', 'ParseSMF_ReturnNamePtr',
     'Track name found: return pointer to name buffer (0x025B90)'),
    ('LABEL_F89E46', 'ParseSMF_Return',
     'Exit: pop xiz, ret'),

    # --- ProcessFileRecord (229530 LABEL_F89E48) ---
    ('LABEL_F89E48', 'ProcessFileRecord',
     'Process single file record: seek, read header, parse 4 match-bytes'),
    ('LABEL_F89E7B', 'ProcessRecord_MatchLoop1',
     'First match loop: compare record bytes against 0xEA04AC table'),
    ('LABEL_F89EB7', 'ProcessRecord_Match1Next',
     'Match1 loop: increment index, loop while < 4'),
    ('LABEL_F89EBD', 'ProcessRecord_CheckBit5',
     'Check bit 5 of record flags (0x025F02 + offset)'),
    ('LABEL_F89EE3', 'ProcessRecord_MatchLoop2',
     'Second match loop: compare against 0xEA04AC with 5 entries'),
    ('LABEL_F89F1D', 'ProcessRecord_Match2Next',
     'Match2 loop: increment, loop while < 5; if all match, clear bit 5 set bit 6'),
    ('LABEL_F89F3C', 'ProcessRecord_ReadTimeSig',
     'Read 4-byte time signature block, then 2-byte tempo value'),
    ('LABEL_F89F6C', 'ProcessRecord_ReadAfterTimeSig',
     'After time-sig: seek past 4 bytes, begin third match loop'),
    ('LABEL_F89F76', 'ProcessRecord_MatchLoop3',
     'Third match loop: compare against 0xEA04B2 table'),
    ('LABEL_F89FAF', 'ProcessRecord_CheckTempo',
     'Tempo value check: if iz==1, set bit 7 of flags'),
    ('LABEL_F89FCC', 'ProcessRecord_DefaultSetBit',
     'Default: set bit 5 of record flags, copy path from record'),
    ('LABEL_F89FEC', 'ProcessRecord_CopyPath',
     'Copy file path via FileIO_CopyString, close handle'),
    ('LABEL_F89FF3', 'ProcessRecord_ErrorReturn',
     'Error return: hl=0xFFFF, jump to common exit'),
    ('LABEL_F89FF9', 'ProcessRecord_Match3Next',
     'Match3 loop: increment, loop while < 4; then parse track name'),
    ('LABEL_F8A01D', 'ProcessRecord_NoTrackName',
     'No track name (null ptr or parse error): use default path'),
    ('LABEL_F8A039', 'ProcessRecord_SearchTrackName',
     'Search for track name in directory via 0xEA03F6'),
    ('LABEL_F8A06F', 'ProcessRecord_UseTrackName',
     'Track name found: use it as source path'),
    ('LABEL_F8A072', 'ProcessRecord_CopyAndClose',
     'Copy path via FileIO_CopyString, close handle, return hl=0'),
    ('LABEL_F8A07B', 'ProcessRecord_Return',
     'Exit: pop xiz, adjust stack, ret'),

    # --- GetFileEntryByIndex (229756 LABEL_F8A07F) ---
    ('LABEL_F8A07F', 'GetFileEntryByIndex',
     'Get file entry pointer by page-relative index'),
    ('LABEL_F8A092', 'GetEntry_ComputeOffset',
     'Index valid: compute record offset (index * 0x52) from base 0x025EC0'),
    ('LABEL_F8A0DF', 'GetEntry_Return',
     'Exit: popw iz, ret'),

    # --- LABEL_F8A0E1 - .byte data block ---
    ('LABEL_F8A0E1', 'FileIO_ByteBlock_F8A0E1',
     'Undecoded .byte block: file record processing (needs LLVM backend additions)'),

    # --- ValidateFileRange (229627 LABEL_F8A485) ---
    ('LABEL_F8A485', 'ValidateFileRange',
     'Validate file index in range: check type==5, check 0 <= wa < max'),
    ('LABEL_F8A498', 'ValidateRange_OutOfRange',
     'Index out of range or wrong type: return 0xFFFF'),
    ('LABEL_F8A49C', 'ValidateRange_CheckPage',
     'In range: check if within current page boundaries'),
    ('LABEL_F8A4AC', 'ValidateRange_NeedPageChange',
     'Not on current page: return 1 (need page change)'),
    ('LABEL_F8A4AF', 'ValidateRange_CheckEmpty',
     'On current page: check if record slot is empty'),
    ('LABEL_F8A4C5', 'ValidateRange_IsValid',
     'Record exists: return 0 (valid)'),

    # --- GetCurrentFileIndex (229663 LABEL_F8A4C8) ---
    ('LABEL_F8A4C8', 'GetCurrentFileIndex',
     'Get current file index: validate via F8A485, return from 0x0271EA'),
    ('LABEL_F8A4D8', 'GetCurrentIndex_Return',
     'Index valid: load and return current index from 0x0271EA'),

    # --- BuildPageRecords (229675 LABEL_F8A4DE) ---
    ('LABEL_F8A4DE', 'BuildPageRecords',
     'Build page records: copy 82-byte entries from 0x025EB2 into 0xEA03E8'),
    ('LABEL_F8A4F0', 'BuildRecords_CopyLoop',
     'Copy loop: transfer 41 words (82 bytes) per entry until past xde'),
    ('LABEL_F8A54C', 'BuildRecords_SearchDone',
     'Search phase complete: begin updating page records from index 1'),
    ('LABEL_F8A55C', 'BuildRecords_UpdateLoop',
     'Update loop: compute offset, copy file path via FileIO_CopyString'),
    ('LABEL_F8A585', 'BuildRecords_UpdateNext',
     'Increment index, call F52AE8 for next entry'),
    ('LABEL_F8A595', 'BuildRecords_Cleanup',
     'Enumeration done: call F52AAA to clean up'),
    ('LABEL_F8A59C', 'BuildRecords_Return',
     'Exit: return count in hl, popw iz, ret'),

    # --- SetCurrentFileIndex (229755 LABEL_F8A5A5) ---
    ('LABEL_F8A5A5', 'SetCurrentFileIndex',
     'Set current file index: validate, adjust page if needed'),
    ('LABEL_F8A5BA', 'SetIndex_InvalidWrap',
     'Invalid index: wrap to current stored index from 0x0271EA'),
    ('LABEL_F8A5E0', 'SetIndex_UpdatePageEnd',
     'Update page end pointer at 0x0271F0'),
    ('LABEL_F8A5E8', 'SetIndex_StoreIndex',
     'Store new index to 0x0271EA'),
    ('LABEL_F8A5EF', 'SetIndex_Return',
     'Exit: popw iz, ret'),

    # --- GetFileRecordPtr (229792 LABEL_F8A5F1) ---
    ('LABEL_F8A5F1', 'GetFileRecordPtr',
     'Get file record pointer: validate index, compute offset from 0x025EC0'),
    ('LABEL_F8A604', 'GetRecordPtr_ComputeOffset',
     'Index valid: offset = (wa - pageStart) * 0x52 + 0x025EC0'),
    ('LABEL_F8A623', 'GetRecordPtr_Return',
     'Exit: popw iz, ret'),

    # --- BuildPageRecordsAlt (229818 LABEL_F8A625) ---
    ('LABEL_F8A625', 'BuildPageRecordsAlt',
     'Build second page records (alt): init page range, call F8A4DE'),
    ('LABEL_F8A640', 'BuildRecordsAlt_StoreCount',
     'Store file count, clamp page end to count'),

    # --- TrimAndFormatFilename (229835 LABEL_F8A652) ---
    ('LABEL_F8A652', 'TrimAndFormatFilename',
     'Trim control chars, replace separator, pad/trim spaces'),
    ('LABEL_F8A664', 'TrimFormat_ScanLoop',
     'Forward scan: replace control chars (< 0x20) with space'),
    ('LABEL_F8A673', 'TrimFormat_ScanNext',
     'Increment index, continue scan if < length'),
    ('LABEL_F8A679', 'TrimFormat_TrimTrailing',
     'Begin reverse trim: remove trailing spaces'),
    ('LABEL_F8A67F', 'TrimFormat_TrimLoop',
     'Trim loop: replace trailing space with null, decrement'),
    ('LABEL_F8A692', 'TrimFormat_CheckLeading',
     'Check for leading space: if so, copy trimmed name over'),
    ('LABEL_F8A6A6', 'TrimFormat_CheckSeparator',
     'Check for separator char (e): replace with null to split'),
    ('LABEL_F8A6AF', 'TrimFormat_SkipSpaces',
     'Skip leading spaces in output buffer'),
    ('LABEL_F8A6B1', 'TrimFormat_SkipLoop',
     'Space-skip loop: advance past spaces in buffer'),
    ('LABEL_F8A6C0', 'TrimFormat_Done',
     'Trim complete: return hl=0'),

    # --- DetectFileType (229900 LABEL_F8A6C9) ---
    ('LABEL_F8A6C9', 'DetectFileType',
     'Detect file type from 0x025DB6: 6=standard, 7=extended'),
    ('LABEL_F8A6D6', 'DetectType_KnownType',
     'Type 6 or 7: zero-extend and return'),
    ('LABEL_F8A6D9', 'DetectType_TryOpen',
     'Type 2: try opening standard first, then extended'),
    ('LABEL_F8A736', 'DetectType_TrimAndReturn',
     'Trim filename, reload type byte, return'),
    ('LABEL_F8A741', 'DetectType_TryExtended',
     'Standard failed: try extended format (type 7, 0xEA04EE)'),
    ('LABEL_F8A782', 'DetectType_NotFound',
     'Neither format found: return 0xFFFF'),

    # --- ValidateFileRangeAlt (229966 LABEL_F8A786) ---
    ('LABEL_F8A786', 'ValidateFileRangeAlt',
     'Validate file range (alt): check type 6/7, check bounds'),
    ('LABEL_F8A793', 'ValidateRangeAlt_CheckType',
     'Type is 6 or 7: check if wa >= 0 and <= max'),
    ('LABEL_F8A79E', 'ValidateRangeAlt_OutOfRange',
     'Out of range: return 0xFFFF'),
    ('LABEL_F8A7A2', 'ValidateRangeAlt_CheckPage',
     'In range: check current page boundaries'),
    ('LABEL_F8A7B2', 'ValidateRangeAlt_NeedPageChange',
     'Not on current page: return 1'),
    ('LABEL_F8A7B5', 'ValidateRangeAlt_CheckEmpty',
     'On current page: check if record slot is empty'),
    ('LABEL_F8A7CB', 'ValidateRangeAlt_IsValid',
     'Record exists: return 0'),

    # ======================================================================
    # RVariScreenProc region (FBF537 - FC1A22)
    # Variable-parameter screen procedure event handler
    # ======================================================================

    # --- RVariScreenProc Init (event 0x1C00001) ---
    ('LABEL_FBF5F3', 'RVari_Init_TypeNotE',
     'Init: variable type != 0xE (14): divide value by 0xA instead of 0x28'),
    ('LABEL_FBF605', 'RVari_Init_ForwardEvent',
     'Init done: forward event to FA4409, return xhl=0'),
    ('LABEL_FBF61D', 'RVari_Show',
     'Event 0x1C0000B (Show): forward to FA4409, return 0'),
    ('LABEL_FBF635', 'RVari_Paint',
     'Event 0x1C0000D (Paint): forward to FA4409, setup display areas'),

    # --- RVari_Select (event 0x1C0000E) ---
    ('LABEL_FBF789', 'RVari_Select',
     'Event 0x1C0000E (Select): forward to FA4409, check variable type'),
    ('LABEL_FBF85D', 'RVari_Select_CheckSameBank',
     'Type=0xF: check if old and new bank indices match (same color)'),

    # --- RVari_Select type=0xF (4-per-bank, FBF789-FBFE74) ---
    ('LABEL_FBFC00', 'RVari_Select_CalcVisibleCount',
     'Calculate visible item count (max 9, clamp to total - page*10)'),
    ('LABEL_FBFC30', 'RVari_Select_CheckTypeE',
     'Check if type == 0xE (10-per-bank) vs other'),
    ('LABEL_FBFCC3', 'RVari_SelectE_FirstItem_NotFirst',
     'First item is not index 0: use full-size rect (0xA3 x 0x137)'),
    ('LABEL_FBFCD1', 'RVari_SelectE_FirstItem_Draw',
     'Draw first item: set color, call FBF5C077 for text, render to screen'),
    ('LABEL_FBFD66', 'RVari_SelectE_SecondItem_Setup',
     'Setup second item rect and check same-bank condition'),
    ('LABEL_FBFD9B', 'RVari_SelectE_SecondItem_NotFirst',
     'Second item not at index 0: use full rect (0xA3 x 0xBE)'),
    ('LABEL_FBFDA9', 'RVari_SelectE_SecondItem_Draw',
     'Draw second item: compute audio index, send Sprintf_Locked'),
    ('LABEL_FBFE42', 'RVari_SelectE_SecondItem_BtnNotFirst',
     'Second item button not first: use full rect (0xB7 x 0x14B)'),
    ('LABEL_FBFE50', 'RVari_SelectE_SecondItem_BtnDraw',
     'Draw second item button: create visual feedback'),

    # --- RVari_Select remaining for type E (4-per-bank) ---
    ('LABEL_FBFE74', 'RVari_Select_OtherItem',
     'Select other item (not type-E first): check second display column'),
    ('LABEL_FBFEFD', 'RVari_SelectO_Item_NotFirst',
     'Other select: item not at first position, use full rect'),
    ('LABEL_FBFF0B', 'RVari_SelectO_Item_Draw',
     'Draw other select item: color, text, Sprintf_Locked'),
    ('LABEL_FBFF9D', 'RVari_SelectO_SecondItem_Setup',
     'Setup second item for other type'),
    ('LABEL_FBFFD2', 'RVari_SelectO_SecondItem_NotFirst',
     'Other second item not first: full rect'),
    ('LABEL_FBFFE0', 'RVari_SelectO_SecondItem_Draw',
     'Draw other second item with audio feedback'),
    ('LABEL_FC0079', 'RVari_SelectO_SecondBtn_NotFirst',
     'Other second button not first: full rect'),
    ('LABEL_FC0087', 'RVari_SelectO_SecondBtn_Draw',
     'Draw other second button with feedback'),

    # --- RVari_Select type != 0xE (10-per-bank) ---
    ('LABEL_FC00AE', 'RVari_Select_TypeNotE',
     'Type != 0xE: use 10-per-bank layout for selection'),
    ('LABEL_FC012B', 'RVari_SelNE_FirstItem_NotFirst',
     'Non-E first item not at index 0: full rect'),
    ('LABEL_FC0139', 'RVari_SelNE_FirstItem_Draw',
     'Draw non-E first item'),
    ('LABEL_FC01CF', 'RVari_SelNE_FirstItem_Deselect',
     'Deselect previous first item, update column display'),
    ('LABEL_FC0265', 'RVari_SelNE_FirstBtn_NotFirst',
     'Non-E first button not first: full rect'),
    ('LABEL_FC0273', 'RVari_SelNE_FirstBtn_Draw',
     'Draw non-E first item button with feedback'),
    ('LABEL_FC0297', 'RVari_SelNE_SecondItem',
     'Non-E second item: check page boundaries'),
    ('LABEL_FC0314', 'RVari_SelNE_SecondItem_NotFirst',
     'Non-E second item not first: full rect'),
    ('LABEL_FC0322', 'RVari_SelNE_SecondItem_Draw',
     'Draw non-E second item with text'),
    ('LABEL_FC03B5', 'RVari_SelNE_SecondItem_Deselect',
     'Deselect previous second item'),
    ('LABEL_FC044B', 'RVari_SelNE_SecondBtn_NotFirst',
     'Non-E second button not first: full rect'),
    ('LABEL_FC0459', 'RVari_SelNE_SecondBtn_Draw',
     'Draw non-E second button with feedback'),

    # --- RVari_Select common return ---
    ('LABEL_FC047D', 'RVari_Select_ReturnZero',
     'Select common return: xhl=0, jump to epilogue'),

    # --- RVari_Confirm (event 0x1C0000F) ---
    ('LABEL_FC0482', 'RVari_Confirm',
     'Event 0x1C0000F (Confirm): forward to FA4409, check type'),
    ('LABEL_FC04AE', 'RVari_Confirm_TypeF_Loop',
     'Type=0xF (4-per-bank): iterate 4 items drawing each'),
    ('LABEL_FC0509', 'RVari_ConfirmF_CheckSelected',
     'Check if current item is the selected one (same color)'),
    ('LABEL_FC056D', 'RVari_ConfirmF_Item_NotFirst',
     'Item not at first position: use full rect (0xA3 x 0xBE)'),
    ('LABEL_FC057B', 'RVari_ConfirmF_Item_Draw',
     'Draw confirm item: audio command, visual feedback, button'),
    ('LABEL_FC0601', 'RVari_ConfirmF_Btn_NotFirst',
     'Confirm button not first: full rect (0xB7 x 0x14B)'),
    ('LABEL_FC060F', 'RVari_ConfirmF_Btn_Draw',
     'Draw confirm button with audio feedback'),
    ('LABEL_FC0641', 'RVari_Confirm_TypeF_SubItems',
     'Type=0xF sub-items: iterate 3 sub-items per item'),
    ('LABEL_FC06C8', 'RVari_Confirm_TypeNotF',
     'Type != 0xF: draw title bar with bank name and page count'),
    ('LABEL_FC078C', 'RVari_Confirm_CalcVisible',
     'Calculate visible count (max 9 or total items on page)'),
    ('LABEL_FC07A1', 'RVari_ConfirmE_Loop',
     'Type=0xE (10-per-bank): draw each item with 4-column layout'),
    ('LABEL_FC083A', 'RVari_ConfirmE_CheckSelected',
     'Check if current E-type item is selected'),
    ('LABEL_FC08BE', 'RVari_ConfirmE_Item_NotFirst',
     'E-type item not first: full rect (0xA3 x 0xBE)'),
    ('LABEL_FC08CC', 'RVari_ConfirmE_Item_Draw',
     'Draw E-type item: audio command, button feedback'),
    ('LABEL_FC0956', 'RVari_ConfirmE_Btn_NotFirst',
     'E-type button not first: full rect (0xB7 x 0x14B)'),
    ('LABEL_FC0964', 'RVari_ConfirmE_Btn_Draw',
     'Draw E-type button with audio feedback'),
    ('LABEL_FC0997', 'RVari_ConfirmNE_Setup',
     'Type != 0xE: setup for 10-per-bank confirm layout'),
    ('LABEL_FC09A2', 'RVari_ConfirmNE_Loop',
     'Non-E confirm loop: draw each item'),
    ('LABEL_FC0A14', 'RVari_ConfirmNE_CheckSelected',
     'Check if non-E item is selected'),
    ('LABEL_FC0A98', 'RVari_ConfirmNE_Item_NotFirst',
     'Non-E item not first: full rect'),
    ('LABEL_FC0AA6', 'RVari_ConfirmNE_Item_Draw',
     'Draw non-E item with audio feedback'),

    # --- RVari_Confirm return ---
    ('LABEL_FC0AD6', 'RVari_Confirm_ReturnZero',
     'Confirm common return: xhl=0, jump to epilogue'),

    # --- RVari_EnumNotify (event 0x1E2000B) ---
    ('LABEL_FC0ADB', 'RVari_EnumNotify',
     'Event 0x1E2000B (EnumNotify): update display for changed enum item'),
    ('LABEL_FC0B21', 'RVari_EnumNotifyF_CheckSelected',
     'Type=0xF: check if changed item is selected (same color)'),
    ('LABEL_FC0B89', 'RVari_EnumNotifyF_Item_NotFirst',
     'Enum item not first: full rect (0xA3 x 0xBE)'),
    ('LABEL_FC0B97', 'RVari_EnumNotifyF_Item_Draw',
     'Draw enum notify item: audio command, button'),
    ('LABEL_FC0C23', 'RVari_EnumNotifyF_Btn_NotFirst',
     'Enum button not first: full rect (0xB7 x 0x14B)'),
    ('LABEL_FC0C31', 'RVari_EnumNotifyF_Btn_Draw',
     'Draw enum notify button with feedback'),

    # --- RVari_EnumNotify type != 0xF ---
    ('LABEL_FC0C59', 'RVari_EnumNotify_CalcVisible',
     'Calculate visible count for non-F type enum'),
    ('LABEL_FC0C89', 'RVari_EnumNotify_SetupDisplay',
     'Setup display lookup for non-F enum item'),
    ('LABEL_FC0D35', 'RVari_EnumNotifyE_CheckSelected',
     'E-type enum: check if item is selected'),
    ('LABEL_FC0D6A', 'RVari_EnumNotifyE_Item_NotFirst',
     'E-type enum item not first: full rect'),
    ('LABEL_FC0D78', 'RVari_EnumNotifyE_Item_Draw',
     'Draw E-type enum item: audio, button'),
    ('LABEL_FC0E08', 'RVari_EnumNotifyE_Btn_NotFirst',
     'E-type enum button not first: full rect'),
    ('LABEL_FC0E16', 'RVari_EnumNotifyE_Btn_Draw',
     'Draw E-type enum button with feedback'),
    ('LABEL_FC0E3E', 'RVari_EnumNotifyNE_CheckSelected',
     'Non-E enum: check if item is selected'),
    ('LABEL_FC0E7F', 'RVari_EnumNotifyNE_Setup',
     'Setup non-E enum item display rect'),
    ('LABEL_FC0EB4', 'RVari_EnumNotifyNE_Item_NotFirst',
     'Non-E enum item not first: full rect'),
    ('LABEL_FC0EC2', 'RVari_EnumNotifyNE_Item_Draw',
     'Draw non-E enum item with feedback'),

    # --- RVari_EnumNotify return ---
    ('LABEL_FC0EE7', 'RVari_EnumNotify_ReturnZero',
     'Enum notify return: xhl=0, jump to epilogue'),

    # --- RVari_OK (event 0x1C00007) ---
    ('LABEL_FC0EEC', 'RVari_OK',
     'Event 0x1C00007 (OK): forward to FA4409, check type, dispatch input'),

    # --- RVari_OK type=0xF input handlers ---
    ('LABEL_FC0FA1', 'RVari_OK_TypeF_Input8A',
     'Type=0xF input 0x8A: save value, advance 4 within bank, refresh'),
    ('LABEL_FC0FEB', 'RVari_OK_TypeF_Input8B',
     'Type=0xF input 0x8B: save value, advance 8 within bank, refresh'),
    ('LABEL_FC1035', 'RVari_OK_TypeF_Input9',
     'Type=0xF input 0x9: save value, set position = divs/4 * 4, refresh'),
    ('LABEL_FC106D', 'RVari_OK_TypeF_InputA',
     'Type=0xF input 0xA: save value, set position = divs/4 * 4 + 1, refresh'),
    ('LABEL_FC10A7', 'RVari_OK_TypeF_InputB',
     'Type=0xF input 0xB: save value, set position = divs/4 * 4 + 2, refresh'),
    ('LABEL_FC10E1', 'RVari_OK_TypeF_InputC',
     'Type=0xF input 0xC: save value, set position = divs/4 * 4 + 3, refresh'),

    # --- RVari_OK type=0xE input handlers ---
    ('LABEL_FC111B', 'RVari_OK_TypeE_CalcVisible',
     'Type=0xE: calculate visible count, dispatch input code'),
    ('LABEL_FC114B', 'RVari_OK_TypeE_DispatchInput',
     'Type=0xE: compare input code against 0x88-0x8C, 0x9-0xC'),
    ('LABEL_FC1208', 'RVari_OK_TypeE_Input88_Done',
     'Input 0x88 done: return 0'),
    ('LABEL_FC120D', 'RVari_OK_TypeE_Input89',
     'Input 0x89: boundary check, save, advance by -(pages*10-0x24), refresh'),
    ('LABEL_FC1260', 'RVari_OK_TypeE_Input89_Done',
     'Input 0x89 done: return 0'),
    ('LABEL_FC1265', 'RVari_OK_TypeE_Input8A',
     'Input 0x8A: boundary check, save, advance by -(pages*10-0x20), refresh'),
    ('LABEL_FC12B8', 'RVari_OK_TypeE_Input8A_Done',
     'Input 0x8A done: return 0'),
    ('LABEL_FC12BD', 'RVari_OK_TypeE_Input8B',
     'Input 0x8B: boundary check, save, advance by -(pages*10-0x1C), refresh'),
    ('LABEL_FC1310', 'RVari_OK_TypeE_Input8B_Done',
     'Input 0x8B done: return 0'),
    ('LABEL_FC1315', 'RVari_OK_TypeE_Input8C',
     'Input 0x8C: boundary check, save, advance by -(pages*10-0x18), refresh'),
    ('LABEL_FC1368', 'RVari_OK_TypeE_Input8C_Done',
     'Input 0x8C done: return 0'),
    ('LABEL_FC136D', 'RVari_OK_TypeE_Input8',
     'Input 0x8: use FBF4F9 to compute row, set absolute position, refresh'),
    ('LABEL_FC13D2', 'RVari_OK_TypeE_Input8_Done',
     'Input 0x8 done: return 0'),
    ('LABEL_FC13D7', 'RVari_OK_TypeE_Input9',
     'Input 0x9: boundary check via FBF510, compute row+1 position'),
    ('LABEL_FC143C', 'RVari_OK_TypeE_Input9_Done',
     'Input 0x9 done: return 0'),
    ('LABEL_FC1441', 'RVari_OK_TypeE_InputA',
     'Input 0xA: boundary check, compute row+2 position'),
    ('LABEL_FC14A6', 'RVari_OK_TypeE_InputA_Done',
     'Input 0xA done: return 0'),
    ('LABEL_FC14AB', 'RVari_OK_TypeE_InputB',
     'Input 0xB: boundary check, compute row+3 position'),
    ('LABEL_FC1510', 'RVari_OK_TypeE_InputB_Done',
     'Input 0xB done: return 0'),
    ('LABEL_FC1515', 'RVari_OK_TypeE_InputC',
     'Input 0xC: boundary check, compute row+4 position'),
    ('LABEL_FC157A', 'RVari_OK_TypeE_InputC_Done',
     'Input 0xC done: return 0'),

    # --- RVari_OK type != 0xE input handlers ---
    ('LABEL_FC157F', 'RVari_OK_TypeNE_DispatchInput',
     'Type != 0xE: dispatch input code for 10-per-bank layout'),
    ('LABEL_FC1622', 'RVari_OK_TypeNE_Input88_Done',
     'Non-E input 0x88 done: return 0'),
    ('LABEL_FC1627', 'RVari_OK_TypeNE_Input89',
     'Non-E input 0x89: save, set position = pages*10-9, refresh'),
    ('LABEL_FC166A', 'RVari_OK_TypeNE_Input89_Done',
     'Non-E input 0x89 done: return 0'),
    ('LABEL_FC166F', 'RVari_OK_TypeNE_Input8A',
     'Non-E input 0x8A: save, set position = pages*10-8, refresh'),
    ('LABEL_FC16B0', 'RVari_OK_TypeNE_Input8A_Done',
     'Non-E input 0x8A done: return 0'),
    ('LABEL_FC16B5', 'RVari_OK_TypeNE_Input8B',
     'Non-E input 0x8B: save, set position = pages*10-7, refresh'),
    ('LABEL_FC16F6', 'RVari_OK_TypeNE_Input8B_Done',
     'Non-E input 0x8B done: return 0'),
    ('LABEL_FC16FB', 'RVari_OK_TypeNE_Input8C',
     'Non-E input 0x8C: save, set position = pages*10-6, refresh'),
    ('LABEL_FC173C', 'RVari_OK_TypeNE_Input8C_Done',
     'Non-E input 0x8C done: return 0'),
    ('LABEL_FC1741', 'RVari_OK_TypeNE_Input8',
     'Non-E input 0x8: use FBF4F9, set absolute position, refresh'),
    ('LABEL_FC1791', 'RVari_OK_TypeNE_Input8_Done',
     'Non-E input 0x8 done: return 0'),
    ('LABEL_FC1796', 'RVari_OK_TypeNE_Input9',
     'Non-E input 0x9: use FBF4F9, compute row position, refresh'),
    ('LABEL_FC17E6', 'RVari_OK_TypeNE_Input9_Done',
     'Non-E input 0x9 done: return 0'),
    ('LABEL_FC17EB', 'RVari_OK_TypeNE_InputA',
     'Non-E input 0xA: use FBF4F9, compute row+2 position, refresh'),
    ('LABEL_FC183B', 'RVari_OK_TypeNE_InputA_Done',
     'Non-E input 0xA done: return 0'),
    ('LABEL_FC1840', 'RVari_OK_TypeNE_InputB',
     'Non-E input 0xB: use FBF4F9, compute row+3 position, refresh'),
    ('LABEL_FC1890', 'RVari_OK_TypeNE_InputB_Done',
     'Non-E input 0xB done: return 0'),
    ('LABEL_FC1895', 'RVari_OK_TypeNE_InputC',
     'Non-E input 0xC: use FBF4F9, compute row+4 position, refresh'),
    ('LABEL_FC18E5', 'RVari_OK_TypeNE_InputC_Done',
     'Non-E input 0xC done: return 0'),

    # --- RVari_OK page scroll handler ---
    ('LABEL_FC18EA', 'RVari_OK_PageScroll',
     'Page scroll handler: compute bank count, check scroll direction'),
    ('LABEL_FC192C', 'RVari_OK_PageUp_AtMax',
     'Page up at maximum: wrap to page 1, send Show event'),
    ('LABEL_FC194C', 'RVari_OK_CheckPageDown',
     'Check if input is page-down (0x90)'),
    ('LABEL_FC1979', 'RVari_OK_PageDown_AtMin',
     'Page down at page 1: wrap to max page, send Show event'),
    ('LABEL_FC199C', 'RVari_OK_ForwardDefault',
     'Not page scroll: forward event to FA4409'),

    # --- RVari_Default (unhandled events) ---
    ('LABEL_FC19B1', 'RVari_Default',
     'Default handler: forward unrecognized event to FA4409'),

    # --- RVari common epilogue ---
    ('LABEL_FC19C4', 'RVari_Epilogue',
     'Common epilogue: pop xiz, store result, ret'),

    # --- RVari_UpdateDisplayNotify helper ---
    ('LABEL_FC19CB', 'RVari_UpdateDisplayNotify',
     'Helper: allocate temp, read display params, send 0x1420000 + 0x1400003 events'),
    ('LABEL_FC1A22', 'RVari_UpdateNotify_End',
     'End marker for RVariScreenProc region'),
]


def main():
    base = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    src = os.path.join(base, 'maincpu', 'kn5000_v10_program.s')

    with open(src, 'rb') as f:
        content = f.read().decode('latin-1')

    renamed = 0
    for old_label, new_label, comment in RENAMES:
        refs = len(re.findall(r'\b' + re.escape(old_label) + r'\b', content))
        if refs == 0:
            print(f'  WARNING: {old_label} not found, skipping')
            continue

        content = re.sub(r'\b' + re.escape(old_label) + r'\b', new_label, content)
        renamed += 1
        print(f'  {old_label:25s} -> {new_label:45s} ({refs} refs)')

    with open(src, 'wb') as f:
        f.write(content.encode('latin-1'))

    print(f'\nRenamed {renamed} labels in maincpu')


if __name__ == '__main__':
    main()
