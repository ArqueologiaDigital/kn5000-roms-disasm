#!/usr/bin/env python3
"""Rename LABEL_* to semantic names in 7 maincpu functions.

Target functions:
  1. HDAE5000_Status_Check    (EF3F29)  — HDAE5000 extension board status & SLIDE decompression
  2. Detect_Disk_Type         (EF42FE)  — Floppy disk type identification
  3. HDAE5000_Parport_Setup   (EF4BCC)  — Parallel port + LZ decompression for HDAE5000
  4. FileOpen                 (F4EBB0)  — File open with mode parsing and FD table allocation
  5. NotifyUIOfSelectionChange (F89610) — UI selection change notification and file entry parsing
  6. MainRamControl           (F98970)  — RAM read/write/set control dispatch
  7. MainGetSoundName         (F98C80)  — Sound name lookup for UI events

Each rename was derived by analysing the routine's instructions, call targets,
register usage, branch patterns, and nearby named symbols.

Uses binary I/O to handle Latin-1 encoding safely.  Never use the Edit tool on
kn5000_v10_program.s — it corrupts the Latin-1 encoding.
"""

import os
import re

# ---------------------------------------------------------------------------
# Rename table: (old_label, new_label, brief_comment)
#
# Groups follow the seven function boundaries listed above.
#
#   EF3F29-EF42FD  HDAE5000_Status_Check area (SLIDE decompress, flash write)
#   EF42FE-EF468D  Detect_Disk_Type area (disk header matching, sector I/O)
#   EF4BCC-EF4F60  HDAE5000_Parport_Setup area (LZ decompress, parport read)
#   F4EBB0-F4EE6B  FileOpen area (mode parsing, FD table, device mount)
#   F89610-F89878  NotifyUIOfSelectionChange area (selection validation, entry)
#   F98970-F98BCC  MainRamControl area (read/write/set by size)
#   F98C80-F98FDA  MainGetSoundName area (sound bank/name lookup)
# ---------------------------------------------------------------------------

RENAMES = [
    # ==================================================================
    # 1. HDAE5000_Status_Check (lines 49755-50150, 28 labels)
    #    Checks HDAE5000 board presence, SLIDE decompression for 4K/8K
    #    ring buffers, FDC sector write helper, and FDC retry wrapper.
    # ==================================================================

    # --- HDAE5000_Status_Check entry: bit test on port, return 0 or -1 ---
    ('LABEL_EF3F31', 'HDAE5000_Status_NotPresent',
     'Board not present: return HL=0xFFFF'),

    # --- Data block (calr targets, encoded bytes) ---
    ('LABEL_EF3F35', 'HDAE5000_Status_DataBlock',
     'Embedded data block (byte-encoded instructions) following status check'),

    # --- SLIDE 4K decompressor (ring buffer size 0x1000) ---
    ('LABEL_EF3FAB', 'SLIDE_Decompress_4K_Init',
     'SLIDE 4K: alloc 0x1000-byte ring buffer via Malloc, init write pointer'),

    ('LABEL_EF3FC6', 'SLIDE_Decompress_4K_FillRing',
     'SLIDE 4K: fill ring buffer with 0xE0 padding bytes'),

    ('LABEL_EF4002', 'SLIDE_Decompress_4K_MainLoop',
     'SLIDE 4K: main decompression loop — shift flags, check literal vs match'),

    ('LABEL_EF4020', 'SLIDE_Decompress_4K_CheckLiteral',
     'SLIDE 4K: check bit 0 flag — if set, emit literal byte'),

    ('LABEL_EF404D', 'SLIDE_Decompress_4K_CopyMatch',
     'SLIDE 4K: no literal — decode match offset+length from ring buffer'),

    ('LABEL_EF4083', 'SLIDE_Decompress_4K_CopyLoop',
     'SLIDE 4K: copy matched bytes from ring buffer to output'),

    ('LABEL_EF40B3', 'SLIDE_Decompress_4K_Continue',
     'SLIDE 4K: check if more data remains, loop back to main'),

    ('LABEL_EF40B8', 'SLIDE_Decompress_4K_Done',
     'SLIDE 4K: free ring buffer and return'),

    # --- SLIDE 8K decompressor (ring buffer size 0x2000) ---
    ('LABEL_EF40C5', 'SLIDE_Decompress_8K_Init',
     'SLIDE 8K: alloc 0x2000-byte ring buffer via Malloc, init write pointer'),

    ('LABEL_EF40E0', 'SLIDE_Decompress_8K_FillRing',
     'SLIDE 8K: fill ring buffer with 0xE0 padding bytes'),

    ('LABEL_EF4120', 'SLIDE_Decompress_8K_MainLoop',
     'SLIDE 8K: main decompression loop — shift flags, check literal vs match'),

    ('LABEL_EF413E', 'SLIDE_Decompress_8K_CheckLiteral',
     'SLIDE 8K: check bit 0 flag — if set, emit literal byte'),

    ('LABEL_EF416B', 'SLIDE_Decompress_8K_CopyMatch',
     'SLIDE 8K: no literal — decode match offset+length from ring buffer'),

    ('LABEL_EF41A1', 'SLIDE_Decompress_8K_CopyLoop',
     'SLIDE 8K: copy matched bytes from ring buffer to output'),

    ('LABEL_EF41D1', 'SLIDE_Decompress_8K_Continue',
     'SLIDE 8K: check if more data remains, loop back to main'),

    ('LABEL_EF41D6', 'SLIDE_Decompress_8K_Done',
     'SLIDE 8K: free ring buffer and return'),

    # --- SLIDE header parser: match "SLIDE" string, dispatch 4K/8K ---
    ('LABEL_EF41E3', 'SLIDE_Parse_Header',
     'Parse SLIDE header: match "SLIDE" string, read size byte, dispatch 4K or 8K'),

    ('LABEL_EF4224', 'SLIDE_Parse_ReturnOK',
     'SLIDE parse: return HL=0 (success)'),

    ('LABEL_EF4228', 'SLIDE_Parse_Check8K',
     'SLIDE parse: size byte != 0x34 (4K), check for 0x38 (8K)'),

    ('LABEL_EF4239', 'SLIDE_Parse_NotFound',
     'SLIDE parse: "SLIDE" string not found, return HL=0xFFFF'),

    ('LABEL_EF423C', 'SLIDE_Parse_Return',
     'SLIDE parse: common return (pop xiz, restore stack)'),

    # --- FDC_InitRecalibrate: build recalibrate command and call FDC ---
    ('LABEL_EF4241', 'FDC_InitRecalibrate',
     'Build FDC recalibrate command struct (cmd=0xD3) and call FDC_CommandEntry'),

    # --- FDC_SetupSectorParams: compute CHS from linear sector number ---
    ('LABEL_EF4271', 'FDC_SetupSectorParams',
     'Compute cylinder/head/sector from linear address, store to FDC param block'),

    # --- FDC_ReadSectors: read sectors with auto-recalibrate on error ---
    ('LABEL_EF42CC', 'FDC_ReadSectors',
     'Read disk sectors: set CHS, issue FDC cmd=3, recalibrate on error'),

    ('LABEL_EF42D7', 'FDC_ReadSectors_Retry',
     'FDC read retry loop: recompute CHS, issue cmd, recalibrate if failed'),

    ('LABEL_EF42FA', 'FDC_ReadSectors_Done',
     'FDC read sectors: success, pop xiz and return'),

    # ==================================================================
    # 2. Detect_Disk_Type (lines 50151-50522, 28 labels)
    #    Read sector 0x21, match against 8 known header strings to
    #    identify disk type (Program 1/2, 2/2, Table 1/2, 2/2, etc.).
    #    Also: FDC_WriteSectors and FDC_WriteSectors_Compressed.
    # ==================================================================

    # --- Disk type string matching: each label matches one header ---
    ('LABEL_EF433B', 'DetectDisk_CheckProgram2of2',
     'Check for "Technics KN5000 Program DATA FILE 2/2"'),

    ('LABEL_EF435A', 'DetectDisk_CheckTable1of2',
     'Check for "Technics KN5000 Table DATA FILE 1/2"'),

    ('LABEL_EF4379', 'DetectDisk_CheckTable2of2',
     'Check for "Technics KN5000 Table DATA FILE 2/2"'),

    ('LABEL_EF4397', 'DetectDisk_CheckCmpCustom',
     'Check for "Technics KN5000 CMPCUSTOMDATA FILE"'),

    ('LABEL_EF43B5', 'DetectDisk_CheckHDAEPRG',
     'Check for "Technics KN5000 HD-AEPRG DATA FILE"'),

    ('LABEL_EF43D3', 'DetectDisk_CheckProgramPCK',
     'Check for "Technics KN5000 Program DATA FILE PCK"'),

    ('LABEL_EF43F1', 'DetectDisk_CheckTablePCK',
     'Check for "Technics KN5000 Table DATA FILE PCK"'),

    ('LABEL_EF440D', 'DetectDisk_FreeBufAndReturn',
     'Free sector buffer, load detected type into L, return'),

    # --- FDC_WriteSectors: uncompressed sector write with CHS calc ---
    ('LABEL_EF441B', 'FDC_WriteSectors',
     'Write uncompressed sectors to flash: compute CHS, iterate tracks'),

    ('LABEL_EF445E', 'FDC_WriteSectors_TrackLoop',
     'Write partial first track: transfer sector data to flash'),

    ('LABEL_EF4479', 'FDC_WriteSectors_TrackLoopCheck',
     'Check if partial-track transfer is complete'),

    ('LABEL_EF4485', 'FDC_WriteSectors_FullTracks',
     'Compute number of full 18-sector tracks and set up loop'),

    ('LABEL_EF44A8', 'FDC_WriteSectors_FullTrackOuter',
     'Outer loop: read one full track (18 sectors) from FDC'),

    ('LABEL_EF44C8', 'FDC_WriteSectors_FullTrackInner',
     'Inner loop: write each sector of full track to flash'),

    ('LABEL_EF44F5', 'FDC_WriteSectors_Remainder',
     'Write remaining sectors in last partial track'),

    ('LABEL_EF4521', 'FDC_WriteSectors_RemainderLoop',
     'Transfer remaining sector data to flash'),

    ('LABEL_EF453C', 'FDC_WriteSectors_RemainderCheck',
     'Check if remaining sectors transfer is complete'),

    ('LABEL_EF4548', 'FDC_WriteSectors_Return',
     'Restore stack and return from FDC_WriteSectors'),

    # --- FDC_WriteSectors_Compressed: sector write with 256-byte blocks ---
    ('LABEL_EF454D', 'FDC_WriteSectors_Compressed',
     'Write compressed sectors: 256-byte block size, separate erase/write'),

    ('LABEL_EF4593', 'FDC_WriteCompressed_PartialTrackLoop',
     'Compressed write: transfer partial first track'),

    ('LABEL_EF45B3', 'FDC_WriteCompressed_PartialTrackCheck',
     'Compressed write: check partial track completion'),

    ('LABEL_EF45BF', 'FDC_WriteCompressed_FullTracks',
     'Compressed write: compute and iterate full tracks'),

    ('LABEL_EF45DE', 'FDC_WriteCompressed_FullTrackOuter',
     'Compressed write: outer loop — read full track from FDC'),

    ('LABEL_EF45FE', 'FDC_WriteCompressed_FullTrackInner',
     'Compressed write: inner loop — write sectors to flash'),

    ('LABEL_EF4630', 'FDC_WriteCompressed_Remainder',
     'Compressed write: handle remaining sectors'),

    ('LABEL_EF465B', 'FDC_WriteCompressed_RemainderLoop',
     'Compressed write: transfer remaining sector data'),

    ('LABEL_EF467B', 'FDC_WriteCompressed_RemainderCheck',
     'Compressed write: check remaining sectors completion'),

    ('LABEL_EF4687', 'FDC_WriteCompressed_Return',
     'Compressed write: restore stack and return'),

    # ==================================================================
    # 3. HDAE5000_Parport_Setup (lines 51025-51380, 27 labels)
    #    Configures parallel port (0x160000), reads data via parport,
    #    and LZ-decompresses firmware into flash (LZSS variant).
    # ==================================================================

    # --- Parallel port init and data read loop ---
    ('LABEL_EF4BF7', 'Parport_WaitDataReady',
     'Poll parallel port bit 0 until data is ready'),

    # --- Parport byte reader: read from LZ stream via FDC buffer ---
    ('LABEL_EF4C07', 'Parport_ReadNextByte',
     'Read next byte from disk buffer; refill from FDC when exhausted'),

    ('LABEL_EF4C17', 'Parport_ReadByte_FromBuffer',
     'Buffer not exhausted: check if DMA buffer needs refill'),

    ('LABEL_EF4C3C', 'Parport_RefillBuffer_Loop',
     'Refill DMA buffer: read 4 tracks of 18 sectors each'),

    ('LABEL_EF4C69', 'Parport_ReadByte_Emit',
     'Emit byte from current buffer position, advance pointer'),

    ('LABEL_EF4C78', 'Parport_ReadByte_Return',
     'Pop iz and return from Parport_ReadNextByte'),

    # --- Flash write helper: accumulate 4 bytes then write dword ---
    ('LABEL_EF4C7A', 'Flash_AccumWrite_Byte',
     'Accumulate byte into 4-byte buffer; write dword to flash when full'),

    ('LABEL_EF4CB2', 'Flash_AccumWrite_ByteDone',
     'Byte accumulated; increment total byte counter'),

    # --- Flash write helper: accumulate 2 bytes then write word ---
    ('LABEL_EF4CB9', 'Flash_AccumWrite_Word',
     'Accumulate byte into 2-byte buffer; write word to flash when full'),

    ('LABEL_EF4CF1', 'Flash_AccumWrite_WordDone',
     'Word accumulated; increment total byte counter'),

    # --- LZSS decompressor: reads from disk, writes to flash ---
    ('LABEL_EF4CF8', 'LZSS_Decompress_ToFlash',
     'LZSS decompress: init state, set flash base addr 0x3E0000'),

    ('LABEL_EF4D1A', 'LZSS_Decompress_ReadHeader',
     'LZSS: read 6 header bytes and match "SLIDE" signature'),

    ('LABEL_EF4D4D', 'LZSS_Decompress_HeaderOK',
     'LZSS: header matched, begin streaming decompressed bytes'),

    ('LABEL_EF4D4F', 'LZSS_Decompress_StreamHeaderBytes',
     'LZSS: write header bytes to flash via word accumulator'),

    ('LABEL_EF4D7B', 'LZSS_Decompress_StreamData',
     'LZSS: read remaining bytes and write to flash until done'),

    ('LABEL_EF4D8F', 'LZSS_Decompress_ReturnOK',
     'LZSS decompress: return HL=0 (success)'),

    ('LABEL_EF4D91', 'LZSS_Decompress_Return',
     'LZSS decompress: pop iz, restore stack, return'),

    # --- LZ decompressor: ring-buffer based (main PCK decompressor) ---
    ('LABEL_EF4D95', 'LZ_Decompress_Init',
     'LZ ring-buffer decompress: alloc 0x1000 buffer, init state'),

    ('LABEL_EF4DB1', 'LZ_Decompress_ClearRing',
     'LZ: clear ring buffer with zeros'),

    ('LABEL_EF4E20', 'LZ_Decompress_ReadTracks',
     'LZ: read 4 tracks of 18 sectors to fill DMA buffer'),

    ('LABEL_EF4E4A', 'LZ_Decompress_ReadSizeField',
     'LZ: read 8 header bytes then compute decompressed size (3 bytes)'),

    ('LABEL_EF4E85', 'LZ_Decompress_MainLoop',
     'LZ: main decode loop — read flags, dispatch literal or match'),

    ('LABEL_EF4EA4', 'LZ_Decompress_LiteralByte',
     'LZ: flag bit set — read literal byte and output'),

    ('LABEL_EF4ED7', 'LZ_Decompress_MatchRef',
     'LZ: flag bit clear — read match offset and length from stream'),

    ('LABEL_EF4F17', 'LZ_Decompress_CopyMatchLoop',
     'LZ: copy matched bytes from ring buffer to output'),

    ('LABEL_EF4F55', 'LZ_Decompress_LoopCheck',
     'LZ: check if total decompressed size reached, loop or exit'),

    ('LABEL_EF4F60', 'LZ_Decompress_Done',
     'LZ: free ring buffer and return'),

    # ==================================================================
    # 4. FileOpen (lines 155316-155625, 26 labels)
    #    Parse mode string ("r", "w", "a", "b", "+", "d", "~"),
    #    allocate FD table slot, invoke device driver open function.
    # ==================================================================

    # --- Mode character dispatch ---
    ('LABEL_F4EBB9', 'FileOpen_ParseModeLoop',
     'Loop over mode string characters, set flags per character'),

    ('LABEL_F4EBED', 'FileOpen_ModeW',
     'Mode "w": set write+create+truncate flags (0x92)'),

    ('LABEL_F4EBF3', 'FileOpen_ModeA',
     'Mode "a": set append+create flags (0x8A)'),

    ('LABEL_F4EBF9', 'FileOpen_ModePlus',
     'Mode "+": set read+write flags (0x03)'),

    ('LABEL_F4EBFF', 'FileOpen_ModeB',
     'Mode "b": clear text-mode flag (bit 2)'),

    ('LABEL_F4EC04', 'FileOpen_ModeTilde',
     'Mode "~": set exclusive flag (bit 5)'),

    ('LABEL_F4EC09', 'FileOpen_ModeD',
     'Mode "d": set direct+no-cache flags (0x41), clear text-mode'),

    ('LABEL_F4EC10', 'FileOpen_ParseModeNext',
     'Advance to next mode character or exit loop'),

    # --- Filename processing ---
    ('LABEL_F4EC15', 'FileOpen_AllocBuffer',
     'Mode parsing done: call Strlen on filename, alloc temp buffer'),

    ('LABEL_F4EC31', 'FileOpen_CopyFilename',
     'Copy filename into allocated buffer via Strcpy'),

    ('LABEL_F4EC45', 'FileOpen_NormalizeName',
     'Normalize filename: uppercase Shift-JIS chars, strip drive prefix'),

    ('LABEL_F4EC6A', 'FileOpen_ScanForColon',
     'Scan for ":" drive separator in filename'),

    ('LABEL_F4EC89', 'FileOpen_NormalizeNoUpper',
     'Character not uppercase-range: pass through as-is'),

    ('LABEL_F4EC90', 'FileOpen_StoreNormChar',
     'Store normalized character and check for end of string'),

    # --- Device matching ---
    ('LABEL_F4EC96', 'FileOpen_MatchDevice',
     'Compute device-relative path, iterate device table to find match'),

    ('LABEL_F4ECD4', 'FileOpen_DeviceSearchLoop',
     'Loop through device table entries comparing path strings'),

    ('LABEL_F4ED00', 'FileOpen_DeviceFound',
     'Device matched (or table exhausted): free temp buffer'),

    # --- Error: no filename or no device match ---
    ('LABEL_F4ED16', 'FileOpen_ErrorNoFile',
     'Error: null filename or no device match — set errno=7, return NULL'),

    # --- Permission check and FD slot allocation ---
    ('LABEL_F4ED22', 'FileOpen_CheckPermission',
     'Check requested mode against device permission bits'),

    ('LABEL_F4ED44', 'FileOpen_FindFreeSlot',
     'Increment open-file count, scan FD table (16 slots) for free entry'),

    ('LABEL_F4ED53', 'FileOpen_SlotSearchLoop',
     'Loop through 16 FD table entries looking for NULL (free slot)'),

    ('LABEL_F4ED72', 'FileOpen_SlotExhausted',
     'All 16 FD slots in use — set errno=4, return NULL'),

    ('LABEL_F4ED88', 'FileOpen_InitSlot',
     'Mark FD slot as in-use, alloc 0x4B-byte FILE struct'),

    ('LABEL_F4EDD4', 'FileOpen_PopulateStruct',
     'Populate FILE struct fields: slot index, device ptrs, mode flags'),

    ('LABEL_F4EE69', 'FileOpen_ReturnHandle',
     'Return FILE handle in XHL (or NULL if driver open failed)'),

    ('LABEL_F4EE6B', 'FileOpen_Return',
     'Common epilogue: pop xiz, restore stack, return'),

    # ==================================================================
    # 5. NotifyUIOfSelectionChange (lines 228553-228844, 31 labels)
    #    Validates file selection index, retrieves entry pointer,
    #    parses two-digit file number, and updates UI state.
    # ==================================================================

    # --- NotifyUIOfSelectionChange: store or retrieve selection index ---
    ('LABEL_F8961A', 'NotifyUI_StoreIndex',
     'Valid index: store to 0x025EA8 current selection'),

    ('LABEL_F89621', 'NotifyUI_Return',
     'Pop iz and return'),

    # --- GetFileEntryPtr: return pointer to file entry struct ---
    ('LABEL_F89623', 'GetFileEntryPtr',
     'Get pointer to file entry for given index (12-byte structs)'),

    ('LABEL_F89636', 'GetFileEntryPtr_Compute',
     'Index valid: compute entry address = base + index * 12'),

    ('LABEL_F8964A', 'GetFileEntryPtr_Return',
     'Pop iz and return entry pointer in XHL'),

    # --- GetCurrentFileType: return type byte of current selection ---
    ('LABEL_F8964C', 'GetCurrentFileType',
     'Get file type byte for currently selected file'),

    ('LABEL_F8965B', 'GetCurrentFileType_Lookup',
     'Valid selection: compute offset and load type byte into L'),

    # --- UpdateFileEntry: write 16-byte name + extension data ---
    ('LABEL_F8966F', 'UpdateFileEntry',
     'Update file entry: copy name/ext, call comparison and commit'),

    ('LABEL_F896DB', 'UpdateFileEntry_Error',
     'Comparison or commit failed: return -104 (0xFFFFFF98)'),

    ('LABEL_F896E2', 'UpdateFileEntry_Commit',
     'Commit succeeded: finalize and load result'),

    ('LABEL_F896E9', 'UpdateFileEntry_Return',
     'Pop xiz, restore stack frame byte, return'),

    # --- ParseFileExtension: parse filename.ext to get 0-9 extension index ---
    ('LABEL_F896F0', 'ParseFileExtension',
     'Parse file extension: find dot, match against 10 known extensions'),

    ('LABEL_F89707', 'ParseFileExt_ScanDot',
     'Advance pointer searching for "." separator'),

    ('LABEL_F8970B', 'ParseFileExt_CheckDot',
     'Check current char for "." and limit scan to 10 chars'),

    ('LABEL_F89716', 'ParseFileExt_DotFound',
     'Dot found: validate position, start matching extensions'),

    ('LABEL_F89721', 'ParseFileExt_MatchLoop',
     'Loop through 10 extension table entries comparing strings'),

    ('LABEL_F8974A', 'ParseFileExt_MatchCheck',
     'Check if extension matched (index < 10) or exhausted'),

    ('LABEL_F89750', 'ParseFileExt_NoMatch',
     'No matching extension found: return HL=0xFFFF'),

    ('LABEL_F89755', 'ParseFileExt_StoreResult',
     'Match found: compute entry index * 12, set flags in table'),

    ('LABEL_F89776', 'ParseFileExt_SetFlag',
     'Set extension flag bit (shift left if index != 0)'),

    ('LABEL_F8977D', 'ParseFileExt_Return',
     'Pop xiz, restore stack, return with extension index in L'),

    # --- ParseTwoDigitFileNum: parse "01"-"20" from filename ---
    ('LABEL_F89781', 'ParseTwoDigitFileNum',
     'Parse two ASCII digits into file number 1-20, return 0-19 or -1'),

    ('LABEL_F897AE', 'ParseTwoDigitFileNum_Invalid',
     'Invalid digit pair: return HL=0xFFFF'),

    ('LABEL_F897B2', 'ParseTwoDigitFileNum_Return',
     'Valid number: decrement to 0-based, return in HL'),

    # --- HandleFilenameChange: validate and update file entry table ---
    ('LABEL_F897B7', 'HandleFilenameChange',
     'Process filename change: validate index, parse ext, update entry'),

    ('LABEL_F89832', 'HandleFilenameChange_NoOverwrite',
     'File size <= 5000: set overwrite flag = 0'),

    ('LABEL_F89835', 'HandleFilenameChange_ReturnOK',
     'Return HL=1 (success) after setting entry'),

    ('LABEL_F89839', 'HandleFilenameChange_ExistingEntry',
     'Entry already exists: compare strings, reparse extension'),

    ('LABEL_F89873', 'HandleFilenameChange_SmallFile',
     'Existing file, size <= 5000: set overwrite flag = 0'),

    ('LABEL_F89876', 'HandleFilenameChange_ReturnFail',
     'Return HL=0 (no change or error)'),

    ('LABEL_F89878', 'HandleFilenameChange_Return',
     'Pop xiz, restore stack, return'),

    # ==================================================================
    # 6. MainRamControl (lines 234663-234933, 28 labels)
    #    Handles events 0x1E00068 (set), 0x1E0006A (adjust), 0x1E00069
    #    (read). Reads/writes RAM values of different sizes (1/2/4 byte)
    #    with clamping and offset correction, then dispatches events.
    # ==================================================================

    # --- Event 0x1E00069: RAM read by size ---
    ('LABEL_F989F0', 'RamCtrl_Read_Word',
     'Read 16-bit value from RAM, mask to 0xFFFF'),

    ('LABEL_F98A05', 'RamCtrl_Read_Dword',
     'Read 32-bit value from RAM'),

    ('LABEL_F98A11', 'RamCtrl_Read_InvalidSize',
     'Invalid size: zero out the data pointer field'),

    ('LABEL_F98A18', 'RamCtrl_Read_Dispatch',
     'Dispatch events 0x1C0001D and 0x1E00023 with cloned param block'),

    # --- Event 0x1E0006A: RAM adjust (read + clamp + write) ---
    ('LABEL_F98A39', 'RamCtrl_Adjust_Entry',
     'Adjust RAM value: load current, clamp to range, apply offset'),

    ('LABEL_F98A62', 'RamCtrl_Adjust_Byte_SignExt',
     'Byte size: sign-extend read value for clamping'),

    ('LABEL_F98A76', 'RamCtrl_Adjust_Word_CheckRange',
     'Word size: check if min > max (range inversion guard)'),

    ('LABEL_F98A7F', 'RamCtrl_Adjust_MaskAndStore',
     'Mask adjusted value and store to temp'),

    ('LABEL_F98A8B', 'RamCtrl_Adjust_Word_SignExt',
     'Word size: sign-extend 16-bit value before clamping'),

    ('LABEL_F98A9A', 'RamCtrl_Adjust_Dword',
     'Dword size: store 32-bit value directly (no masking)'),

    ('LABEL_F98AA4', 'RamCtrl_Adjust_InvalidSize',
     'Invalid size: store zero'),

    ('LABEL_F98AA9', 'RamCtrl_Adjust_ClampLow',
     'Apply lower bound: check offset field, clamp to min'),

    ('LABEL_F98AC7', 'RamCtrl_Adjust_ClampHigh',
     'Apply upper bound: check if value exceeds max after offset'),

    ('LABEL_F98AD5', 'RamCtrl_Adjust_ApplyOffset',
     'Add offset to clamped value'),

    ('LABEL_F98ADA', 'RamCtrl_Adjust_StoreMax',
     'Value exceeds max: clamp to max value'),

    ('LABEL_F98ADD', 'RamCtrl_Adjust_WriteBack',
     'Alloc param block copy, write clamped value back by size'),

    ('LABEL_F98B13', 'RamCtrl_Adjust_Write_Word',
     'Write back 16-bit clamped value'),

    ('LABEL_F98B1D', 'RamCtrl_Adjust_Write_Dword',
     'Write back 32-bit clamped value'),

    ('LABEL_F98B27', 'RamCtrl_Adjust_Write_InvalidSize',
     'Invalid size on writeback: zero out field'),

    ('LABEL_F98B2E', 'RamCtrl_Adjust_Dispatch',
     'Dispatch events 0x1C0001D and 0x1E00023 with cloned block'),

    # --- Event 0x1E00068: RAM set (write immediate value) ---
    ('LABEL_F98B4E', 'RamCtrl_Set_Entry',
     'Set RAM value: read input, write by size to data pointer'),

    ('LABEL_F98B70', 'RamCtrl_Set_Word_Mask',
     'Set 16-bit: mask to 0xFFFF'),

    ('LABEL_F98B75', 'RamCtrl_Set_MaskAndWrite',
     'Apply size mask and write value to data pointer'),

    ('LABEL_F98B80', 'RamCtrl_Set_Dword',
     'Set 32-bit: write full dword to data pointer'),

    ('LABEL_F98B8C', 'RamCtrl_Set_InvalidSize',
     'Invalid size: write zero'),

    ('LABEL_F98B90', 'RamCtrl_Set_Dispatch',
     'Alloc cloned param block, dispatch events 0x1C0001D + 0x1E00023'),

    ('LABEL_F98BC8', 'RamCtrl_DispatchAndReturn',
     'Common tail: call dispatch 0xFA9D58, fall through to return'),

    ('LABEL_F98BCC', 'RamCtrl_Return',
     'Return HL=0 from MainRamControl'),

    # ==================================================================
    # 7. MainGetSoundName (lines 235023-235363, 29 labels)
    #    Handles 4 events: 0x1E0005E (get sound name string),
    #    0x1E00061 (lookup sound by category), 0x1E000A8 (set sound),
    #    0x1E000A9 (navigate to sound). Uses sound bank/program tables.
    # ==================================================================

    # --- Event 0x1E0005E: build sound name string ---
    ('LABEL_F98D12', 'GetSoundName_BuildString',
     'Sound index <= 15 or 21-22: lookup via bank/program, build name string'),

    ('LABEL_F98D3E', 'GetSoundName_DefaultString',
     'Sound index 16-20: use default string at 0x99E6 via Strcpy'),

    ('LABEL_F98D4E', 'GetSoundName_DispatchResult',
     'Dispatch result events 0x1C00020, 0x1E00023 with name and index'),

    # --- Event 0x1E00061: lookup sound by category/bank ---
    ('LABEL_F98D7F', 'SoundLookup_ByCategory',
     'Lookup sound: get bank+program, compute offset, dispatch 0x1C00023'),

    ('LABEL_F98DCD', 'SoundLookup_DispatchAndReturn',
     'Common dispatch: call 0xFA9D58, jump to return'),

    # --- Event 0x1E000A8: set current sound selection ---
    ('LABEL_F98DD4', 'Sound_SetSelection',
     'Set sound selection: decode bank/program, call FC9CF9 and FDB255'),

    # --- Event 0x1E000A9: navigate/browse sound list ---
    ('LABEL_F98E13', 'Sound_Navigate_Entry',
     'Navigate sound list: validate index range, begin search'),

    ('LABEL_F98E2D', 'Sound_Navigate_Init',
     'Init navigation: extract page offset, lookup initial position'),

    ('LABEL_F98E85', 'Sound_Navigate_SearchLoop',
     'Main search loop: scan backward or forward for valid entry'),

    ('LABEL_F98EA2', 'Sound_Navigate_ScanBackward',
     'Scan backward: decrement bank, check for valid sound'),

    ('LABEL_F98ED0', 'Sound_Navigate_BackwardCheck',
     'Backward scan: check if valid entry found or hit bottom'),

    ('LABEL_F98EDD', 'Sound_Navigate_AtBottom',
     'Hit bottom of range: set index to 0, go to commit'),

    ('LABEL_F98EE2', 'Sound_Navigate_ScanForward',
     'Scan forward: increment bank, check for valid sound'),

    ('LABEL_F98F03', 'Sound_Navigate_ForwardLoop',
     'Forward scan loop: increment bank, update position'),

    ('LABEL_F98F32', 'Sound_Navigate_ForwardCheck',
     'Forward scan: check if valid entry found or hit top'),

    ('LABEL_F98F3F', 'Sound_Navigate_UpdateState',
     'Store updated bank/index, check if navigation is complete'),

    ('LABEL_F98F53', 'Sound_Navigate_Commit',
     'Commit navigation: check if position changed, update sound'),

    ('LABEL_F98F68', 'Sound_Navigate_ApplyChange',
     'Position changed: call FC9CF9 + FDB255 to update sound'),

    ('LABEL_F98F95', 'Sound_Navigate_Notify',
     'Call FB4296 to notify UI of sound change'),

    ('LABEL_F98F99', 'Sound_Navigate_Return',
     'Return HL=0 from MainGetSoundName'),

    ('LABEL_F98FA0', 'Sound_Navigate_AtTop',
     'Hit top of range: use current position as final'),

    ('LABEL_F98FA3', 'Sound_Navigate_SetDone',
     'Mark navigation as complete (flag=1), go to commit'),

    # --- GetSoundBankCount: return entry count for a bank/category ---
    ('LABEL_F98FAA', 'GetSoundBankCount',
     'Get sound count for given category (WA) and bank (BC)'),

    ('LABEL_F98FC8', 'GetSoundBankCount_StandardBank',
     'Category 0/1/2: fall through to table lookup'),

    ('LABEL_F98FCA', 'GetSoundBankCount_CheckDrum',
     'Category 15 (drums): check bank == 15, else return -1'),

    ('LABEL_F98FD0', 'GetSoundBankCount_Invalid',
     'Invalid category/bank combination: return HL=0xFFFF'),

    ('LABEL_F98FD3', 'GetSoundBankCount_Return',
     'Return from GetSoundBankCount'),

    ('LABEL_F98FD4', 'GetSoundBankCount_CheckSpecial',
     'Non-standard category: check for special bank 12'),

    ('LABEL_F98FDA', 'GetSoundBankCount_DoLookup',
     'Valid bank: call FEE43F to get entry count, sign-extend result'),
]


def main():
    base = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    src = os.path.join(base, 'maincpu', 'kn5000_v10_program.s')

    with open(src, 'rb') as f:
        content = f.read().decode('latin-1')

    renamed = 0
    for old_label, new_label, comment in RENAMES:
        if old_label + ':' not in content:
            print(f'  WARNING: {old_label} not found as definition, skipping')
            continue

        refs = len(re.findall(r'\b' + re.escape(old_label) + r'\b', content))
        new_content = re.sub(r'\b' + re.escape(old_label) + r'\b', new_label, content)

        if new_content != content:
            content = new_content
            renamed += 1
            print(f'  {old_label:25s} -> {new_label:50s} ({refs} refs)')

    with open(src, 'wb') as f:
        f.write(content.encode('latin-1'))

    print(f'\nRenamed {renamed} labels in maincpu/kn5000_v10_program.s')


if __name__ == '__main__':
    main()
