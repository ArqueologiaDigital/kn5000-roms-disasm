#!/usr/bin/env python3
"""Routines named by reading their bodies, 2026-10-04 -- the evidence for each, in one place.

QUESTION IT ANSWERS
  When no table or structural rule names a routine, it is named by reading it.  Each row is (old label,
  new label, what the body does that the name rests on).  The evidence is written to be checked against
  the routine's own instructions (python3 the session's rb.py viewer, or the listing).  Nothing here is
  inferred from a caller's name alone.  RAM names are wsa1/include/wsa1_ram.inc's.

RUN
  python3 notes/prom_ab_read_names_2026_10_04.py          # the table
  python3 notes/prom_ab_read_names_2026_10_04.py --args   # 'old=new|header' for the rename helper
"""
import os
import re
import sys

# the old label is kept as its bare address: the rename helper rewrites every old LABEL token in wsa1/notes
ROWS = [
    # prom_b 0xF65000-0xF66FFF: sequencer job screens
    ("F66619", "TrackAssignPresets_BankUp",
     "(0x0DFE) + 1, stopping at 10, and (0x0DFE) + 1 to DisplayListB_Stage+1; repaint bit 3.  (0x0DFE) is the bank\n"
     "the page shows: TrackAssignPresets_InitFromCurrentBank loads it from BStore_CurrentBank.  Called by SoftKeyCol3_TrackAssignPresets."),
    ("F66639", "TrackAssignPresets_BankDown",
     "(0x0DFE) - 1, stopping at 0, mirrored +1 to DisplayListB_Stage+1.  Called by SoftKeyCol2_TrackAssignPresets."),
    ("F665B4", "TrackAssignPresets_InitFromCurrentBank",
     "unless the previous screen latch is 0x11: (0x0DFD) = 1, (0x0DFE) = BStore_CurrentBank (+1 to the display stage),\n"
     "UI_StatusCode = 0; then, if UI_StatusCode is 0x23, requests screen 0x10.  Called by Paint_TrackAssignPresets."),
    ("F664AE", "StepRecordPartSelect_OpenStepRecord",
     "(0x0C90) = 1, (0x0DC8) = 0, and when the chosen part (0x0E5C) is 1..0x11: (0x12A0) = 0 and UI_Request = 0x800E,\n"
     "screen 0x0E = STEP RECORD.  Called by all eight SoftKeyColN_StepRecordPartSelect."),
    ("F664D5", "StepRecordPartSelect_ResetOnEntry",
     "(0x3010) = (0x60341E); on a newly entered screen (latch changed): chosen part (0x0E5C) = 0, (0x2130) |= 0x100,\n"
     "(0x2160) = 0xFFFF, (0x215E) = 0, (0x0C00) = 0, T_F409AC; then (0x34BB) |= 4.  Called by Paint_StepRecordPartSelect."),
    ("F66081", "TrackAssign_ReturnToStageZero",
     "unless (0x95) bit 2: (0x0DC0) = 0, UI_ScreenStage = 0, UI_Request_Hi |= 0x10.  Called by ExitKey_ and\n"
     "LcdKeyRow3_TrackAssign_StageNonZero."),
    ("F660ED", "SequencerMedley_InitOnEntry",
     "on a newly entered screen: (0x0E48) = (0x7F4D), Medley_Playing = 0, (0x22D0) = 0, (0x605068) |= 0x8000,\n"
     "BStore_LoadBankDirectory, T_F42410; then Blink_EnableThenStop unless the medley plays.  Called by Paint_SequencerMedley."),
    ("F66123", "BStore_LoadBankDirectory",
     "(0x60341E) = (0x360C); copies 3,072 bytes from 0x610000 + BStore_CurrentBank * 0xC00 to 0x603500, the song directory\n"
     "SmfSize_Pass and the block store walk."),
    ("F661F3", "Blink_EnableThenStop",
     "T_Blink_SetEnable(1) then T_Blink_Stop."),
    ("F66201", "SequencerMedley_StopPlayback",
     "when Medley_Playing is 1: clears it and (0x22D0); for an INT source, or FD with a NORM file: T_F43030 and, unless\n"
     "(0x0E48) bit 2, T_F42E98; otherwise (0x0E36) = 1 and T_F4257C.  Called by LcdKeyRow3_SequencerMedley and SequencerMedley_OnLeave."),
    ("F6625C", "SequencerMedley_StepFieldUp",
     "clears bit 7 of W, then SequencerMedley_StepFirstSong (Medley_Field 1) or _StepLastSong (2): the step goes UP."),
    ("F66278", "SequencerMedley_StepFieldDown",
     "sets bit 7 of W, then the same dispatch on Medley_Field: the step goes DOWN."),
    ("F66294", "SequencerMedley_StepFirstSong",
     "unless (0x95) bit 2: W bit 7 set -> Medley_FirstSong - 1 (floor 0); clear -> + 1 up to 9 (INT), 19 (disk, NORM file)\n"
     "or 99 (MIDI file); then the range fix-up 0xF662D7 and repaint bit 3."),
    ("F662F7", "SequencerMedley_StepLastSong",
     "the same as SequencerMedley_StepFirstSong on Medley_LastSong."),
    ("F6633A", "SequencerMedley_SetSourceInternal",
     "when not playing: Medley_Source = 0 (INT) and Medley_FileType = 0, each to its display stage, and both songs\n"
     "clamped to 9 (an INT medley has ten songs).  Called by SoftKeyCol2_SequencerMedley and Paint_SequencerMedley."),
    ("F660A0", "SequencerMedley_ClampSongRange",
     "clamps Medley_FirstSong to the source's last song (9 / 19 / 99) and Medley_LastSong (to 0 when beyond it), then\n"
     "keeps FIRST <= LAST, moving whichever one C (the previous FIRST) says did not change."),
    ("F65CD6", "TrackAssign_SelectTrackGroup",
     "BC = 10 (LcdKeyRow3) clears (0x0C07) bit 0 and sets (0x0C03) = 0; BC = 11 (LcdKeyRow4) sets the bit and (0x0C03) = 8;\n"
     "then (0x0C06) = the byte map 0x603422[(0x0C03)].  Called by LcdKeyRow3/4_TrackAssign_StageZero."),
    # prom_a 0xFB9000-0xFBA1FF: the MIDI-file player (screens 0x13 SequencerMedley and 0x45 MidiFileDirectPlay)
    ("FB9E79", "MidiFilePlay_Tick",
     "UI_ScreenLatch 0x13 (SequencerMedley) -> SequencerMedley_MidiFileTick; 0x45 (MidiFileDirectPlay) ->\n"
     "MidiFileDirectPlay_Tick; anything else, nothing.  Reached from the table at Data_F82000."),
    ("FB9E96", "SequencerMedley_MidiFileTick",
     "acts only on screen 0x13 with Medley_Source 1 (FD) and Medley_FileType 1 (MIDI FILE) and (0x60505E) bit 1;\n"
     "unless bit 0, runs 0xFB9697; a pending stop (0x605147 bit 0) -> MidiFilePlay_Stop; otherwise builds the song\n"
     "position (0x605040) = beat (0x91) * 96 + Seq_BeatTick."),
    ("FB9FE1", "MidiFileDirectPlay_Tick",
     "the same as SequencerMedley_MidiFileTick for screen 0x45 (no medley-source test)."),
    ("FB91C9", "MidiFilePlay_Stop",
     "clears (0x60505E) bit 0 and (0x60504C), MidiInQueue_InjectAllNotesOff_AllChannels, T_F413C0, then clears the\n"
     "position (0x605040) and (0x605044) / (0x605048).  Called by MidiFileDirectPlay_LcdKeyRow1, both ticks, and the leave."),
    ("FB991B", "MidiFilePlay_ClearPosition",
     "(0x605040) = 0: the 32-bit song position the ticks build as beat * 96 + tick."),
    ("FB9E61", "MidiFilePlay_ClearPosition_Copy",
     "byte-for-byte MidiFilePlay_ClearPosition."),
    ("FB916A", "SeqClock_ResetBeatAndTick",
     "with interrupts masked (ei 6 ... ei 0): the beat word (0x91) = 0 and Seq_BeatTick = 0."),
    ("FB9B41", "MidiFileDirectPlay_InitOnEntry",
     "(0x605069) bit 7 set; saves (0x60341E) in (0x605072) and clears it; (0x34BB) bit 2 cleared; (0x60505E) = 0;\n"
     "(0x605144) = the byte at 0x7F4D; then 0xFB9089.  Called by Paint_MidiFileDirectPlay, the screen's enter."),
    ("FB9B73", "MidiFileDirectPlay_RestoreOnLeave",
     "(0x605068) = 0; restores (0x60341E) from (0x605072); MidiFilePlay_Stop; (0x60505E) = 0; then 0xFB9C52 or, when\n"
     "(0x605144) bit 2, 0xFB9BA4 (which installs the 17-byte part map from MidiFile_Tables_FBA169 into 0x603422).\n"
     "Called by ScreenLeave_MidiFileDirectPlay."),
    # prom_a 0xFE4400-0xFE4BFF: the FAT layer under Disk_ReadSectors / Disk_WriteSectors.  Geometry, set at
    # 0xFE3356-0xFE336C and per floppy format at 0xFE33BE..: (0x605D64) = 1 = first FAT, (0x605D66) = 1 + sectors per FAT
    # = second FAT, (0x605D3E) = 1 + 2 * sectors per FAT = root directory (7 / 19 / 5 / 11 on the floppy formats),
    # (0x605D40) = data area, (0x605D56) = sectors per cluster; (0x605D22) points at the drive record, +2 = 1 on FAT16.
    ("FE4731", "Fat_GetEntry",
     "HL = the FAT entry of cluster IZ.  FAT16: the word at 0x605D99 + 2 * (IZ - page * 256), loading page IZ >> 8 into\n"
     "the one-page cache (0x606F99) after Fat_Store of the old one; FAT12: the 12 bits at offset IZ + IZ / 2, the high\n"
     "nibble pair for odd IZ, 0xFFF returned as 0xFFFF."),
    ("FE47BE", "Fat_SetEntry",
     "the FAT entry of cluster IZ = the word argument; clusters 0 and 1 refused ((0x605A05) = 0xFF, HL = 0xFF).  FAT16\n"
     "through the same page cache; FAT12 packs the 12 bits at IZ + IZ / 2, keeping the neighbour's nibble."),
    ("FE48EF", "Fat_Load",
     "FAT16: Disk_ReadSectors of one sector, FAT page (0x606F99) at (0x605D64) + page, into 0x605D99; FAT12: the whole\n"
     "FAT, its size by the media type (0x605D36) 0..5."),
    ("FE4A55", "Fat_Store",
     "writes the FAT buffer 0x605D99 back to BOTH copies: Disk_WriteSectors at (0x605D64) + page, then at (0x605D66) +\n"
     "page (FAT16: the cached page; nothing when (0x606F99) = 0xFFFF)."),
    ("FE4483", "Fat_ClusterToSector",
     "XHL = (0x605D40) + (cluster - 2) * (0x605D56), less one on FAT16 (drive record +2 = 1)."),
    ("FE4512", "Disk_ReadCluster",
     "Disk_ReadSectors(Fat_ClusterToSector(arg), (0x605D56) sectors, the buffer (0x605D2C) points at)."),
    ("FE452D", "Disk_WriteCluster",
     "Disk_WriteSectors(Fat_ClusterToSector(arg), (0x605D56) sectors, from the buffer (0x605D2C) points at)."),
    ("FE4548", "Disk_ReadClusterToWorkBuffer",
     "Disk_ReadSectors(Fat_ClusterToSector(arg), (0x605D56) sectors, into 0x606F9B)."),
    ("FE4563", "Disk_WriteClusterFromWorkBuffer",
     "Disk_WriteSectors(Fat_ClusterToSector(arg), (0x605D56) sectors, from 0x606F9B)."),
    ("FE4621", "Disk_ReadRootDirSector",
     "Disk_ReadSectors(1 sector at (0x605D3E) + arg, the root directory, into 0x605B12); HL = 0 or 0xFF."),
    ("FE4649", "Disk_WriteRootDirSector",
     "Disk_WriteSectors(1 sector at (0x605D3E) + arg from 0x605B12); HL = 0 or 0xFF."),
    # prom_a Disk_CommandDispatch's handlers.  The command codes (decoded from its word-offset table at 0xFE6DFC, base
    # 0xFE42B4) are MS-DOS INT 21h's FCB function numbers: 0x1A, whose handler stores the transfer-buffer pointer
    # (0x605D2C), is DOS "Set Disk Transfer Address"; 0x14/0x15/0x17-0x19 (sequential read / write, rename ...) fall to
    # the default case.  Each name below was checked against its body, not taken from the DOS table alone.
    ("FE389E", "DiskCmd_OpenFile",
     "command 0x0F (DOS 0Fh Open File, FCB).  DiskCmd_DeleteFile calls it to find each entry it deletes."),
    ("FE395A", "DiskCmd_CloseFile",
     "command 0x10 (DOS 10h Close File): writes the entry back (Disk_WriteRootDirSector) and the FAT (Fat_Store)."),
    ("FE3A4C", "DiskCmd_FindFirst",
     "command 0x11 (DOS 11h Search First): Disk_ReadRootDirSector and the entry matcher 0xFE45BF."),
    ("FE3AF3", "DiskCmd_FindNext",
     "command 0x12 (DOS 12h Search Next): resumes the root-directory scan at the saved index (0x605D2A) + 1, up to\n"
     "(0x605D4E) - 1 entries."),
    ("FE3CB1", "DiskCmd_DeleteFile",
     "command 0x13 (DOS 13h Delete File): DiskCmd_OpenFile then 0xFE3C23; when Fat_NameHasWildcard, repeats until no\n"
     "entry matches.  HL = 0xFF when the first one fails."),
    ("FE3DB2", "DiskCmd_CreateFile",
     "command 0x16 (DOS 16h Create File): a directory slot from 0xFE46DA (kept at the record's +0x18), Fat_Load, the first\n"
     "free cluster from 2, Fat_SetEntry(cluster, 0xFFFF) -- a one-cluster chain."),
    ("FE3E97", "DiskCmd_SetTransferAddress",
     "command 0x1A (DOS 1Ah Set Disk Transfer Address): (0x605D2C) = the 32-bit argument, the buffer\n"
     "Disk_ReadCluster / DiskCmd_ReadSectors use; HL = 0."),
    ("FE3EA2", "DiskCmd_CheckMediaId",
     "command 0x1B: reads sector 1 (the first FAT) into 0x606F9B and checks its leading media-ID bytes against the\n"
     "format (0x605D36) 0..5 (DOS 1Bh reports the same byte).  HL = 0 for a match, 1 for read results 0x30 / 9 / 1,\n"
     "else 0xFF."),
    ("FE4BCC", "DiskCmd_CountFreeSpace",
     "command 0x80: Fat_Load, then counts the clusters 0 .. (0x605D58) whose FAT entry is 0; returns the count scaled by\n"
     "8 on FAT16 or by the format's factor from Table_FE6DBF+0x75."),
    ("FE3F82", "DiskCmd_ReadSectors",
     "command 0x81: Disk_ReadSectors(sector, count from the arguments, into the transfer buffer (0x605D2C))."),
    ("FE3F99", "DiskCmd_WriteSectors",
     "command 0x82: Disk_WriteSectors(sector, count, from the transfer buffer (0x605D2C))."),
    ("FE3FB0", "DiskCmd_ReadFileBlock",
     "command 0x83: the next block of an open file into the transfer buffer -- Disk_ReadCluster of the cluster the record\n"
     "holds at +0x1C (0xFFFF: end, HL = 1), or for a record of type 1 the next 1 KB of the work buffer 0x606F9B."),
    ("FE40B9", "DiskCmd_WriteFileBlock",
     "command 0x84: the write counterpart -- Disk_WriteCluster / _WriteClusterFromWorkBuffer and Fat_SetEntry\n"
     "(its callers' census: notes/prom_ab_read_names_2026_10_04.py rows above)."),
    ("FE3C23", "Fat_DeleteFileAndFreeChain",
     "marks the opened entry deleted (0xE5) and frees its cluster chain to the end marker (>= 0xFF8), with\n"
     "Fat_GetEntry / Fat_SetEntry, Fat_Store and Disk_WriteRootDirSector."),
    ("FE489E", "Fat_FindFreeClusterFrom",
     "the first cluster IZ .. (0x605D58) - 1 whose FAT entry is 0; HL = 0 when none."),
    ("FE48C7", "Fat_FindFreeClusterAfter",
     "cluster + 1 when its entry is 0, else Fat_FindFreeClusterFrom(2); HL = 0 when none."),
    # prom_a 0xFE171D-0xFE1BBF: the UI's file calls, one Disk_CommandDispatch command each
    ("FE171D", "DiskFile_SetFcbName",
     "copies the 11-byte 8.3 name Disk_FileName (0x21C8..) into the file-control block 0x178E, +1 .. +11."),
    ("FE19FF", "DiskFile_FindFirst",
     "issues command 0x11 (DiskCmd_FindFirst; DiskFile_SetFcbName first): (0x1739) = the command, (0x173B) = 0, Disk_CommandDispatch through T_Disk_CommandDispatch_SaveRegs_Entry with the file-control block at RAM 0x178E, the result byte to (0x1735)."),
    ("FE1A2E", "DiskFile_FindNext",
     "issues command 0x12 (DiskCmd_FindNext): (0x1739) = the command, (0x173B) = 0, Disk_CommandDispatch through T_Disk_CommandDispatch_SaveRegs_Entry with the file-control block at RAM 0x178E, the result byte to (0x1735)."),
    ("FE1A5A", "DiskFile_Open",
     "issues command 0x0F (DiskCmd_OpenFile; DiskFile_SetFcbName first): (0x1739) = the command, (0x173B) = 0, Disk_CommandDispatch through T_Disk_CommandDispatch_SaveRegs_Entry with the file-control block at RAM 0x178E, the result byte to (0x1735)."),
    ("FE1A89", "DiskFile_ReadBlock",
     "issues command 0x83 (DiskCmd_ReadFileBlock): (0x1739) = the command, (0x173B) = 0, Disk_CommandDispatch through T_Disk_CommandDispatch_SaveRegs_Entry with the file-control block at RAM 0x178E, the result byte to (0x1735)."),
    ("FE1AB5", "DiskFile_CountFreeSpace",
     "issues command 0x80 (DiskCmd_CountFreeSpace; its 16-bit result goes to (0x1739)): (0x1739) = the command, (0x173B) = 0, Disk_CommandDispatch through T_Disk_CommandDispatch_SaveRegs_Entry with the file-control block at RAM 0x178E, the result byte to (0x1735)."),
    ("FE1ADE", "DiskFile_Create",
     "issues command 0x16 (DiskCmd_CreateFile): (0x1739) = the command, (0x173B) = 0, Disk_CommandDispatch through T_Disk_CommandDispatch_SaveRegs_Entry with the file-control block at RAM 0x178E, the result byte to (0x1735)."),
    ("FE1B0D", "DiskFile_WriteBlock",
     "issues command 0x84 (DiskCmd_WriteFileBlock): (0x1739) = the command, (0x173B) = 0, Disk_CommandDispatch through T_Disk_CommandDispatch_SaveRegs_Entry with the file-control block at RAM 0x178E, the result byte to (0x1735)."),
    ("FE1B39", "DiskFile_Close",
     "issues command 0x10 (DiskCmd_CloseFile): (0x1739) = the command, (0x173B) = 0, Disk_CommandDispatch through T_Disk_CommandDispatch_SaveRegs_Entry with the file-control block at RAM 0x178E, the result byte to (0x1735)."),
    ("FE1B65", "DiskFile_Delete",
     "issues command 0x13 (DiskCmd_DeleteFile; DiskFile_SetFcbName first): (0x1739) = the command, (0x173B) = 0, Disk_CommandDispatch through T_Disk_CommandDispatch_SaveRegs_Entry with the file-control block at RAM 0x178E, the result byte to (0x1735)."),
    # prom_a: the disk API prom_b calls through the thunk directory.  The memory window is (0x21D3) .. (0x21D7)
    # (SmfSize_ / InputStream_ code sets them to 0x60A700 .. 0x60AB00); Disk_Flags bit 1 = continue an earlier call,
    # bit 2 = the last, partial 1 KB block (transfer through 0x60A080), bit 5 = stop after one block.
    ("FE0B43", "DiskApi_ReadFileToWindow",
     "(T_DiskApi_ReadFileToWindow_Entry via 0xFE1C3A) unless Disk_Flags bit 1: DiskFile_Open (once more after 0xFE08BD if it fails; A = 4 when it\n"
     "fails again), the window end clamped to start + the file size at control block +0x10/+0x12, the transfer\n"
     "address set; then DiskFile_ReadBlock per 1 KB until the window is full (DiskFile_AdvanceWindow 0xFF), bit 5 asks\n"
     "for one block, or bit 1 (A = 0xFD: more to come).  A = 5 on a read error, 1 when done."),
    ("FE0A99", "DiskApi_WriteFileFromWindow",
     "(T_DiskApi_WriteFileFromWindow_Entry via 0xFE1C4D) unless Disk_Flags bit 1: DiskFile_Create and the transfer address; then DiskFile_WriteBlock\n"
     "per 1 KB; on a write error DiskFile_Delete (A = 7 or 6); at the window's end DiskApi_CloseFile; A = 3 when done."),
    ("FE0CA2", "DiskApi_DeleteFile",
     "(T_DiskApi_DeleteFile_Call via 0xFE1C55) DiskFile_Delete; (0x1735) = its result; A = 0x19 deleted, 0x18 not."),
    ("FE0C45", "DiskApi_CloseFile",
     "(T_DiskApi_CloseFile_Call via 0xFE1CAF) DiskFile_Close; A = 3, or, when the close fails, the file is deleted (command 0x13) and A = 6."),
    ("FE0C08", "DiskFile_SetTransferToWindow",
     "(0x174B) = the window start (0x21D3), or 0x60A080 when Disk_Flags bit 2; then command 0x1A with it (DOS Set DTA)."),
    ("FE0C73", "DiskFile_AdvanceWindow",
     "(0x21D3) += 0x400 unless that reaches (0x21D7) (A = 0xFF); sets Disk_Flags bit 2 when the next 1 KB would pass the\n"
     "end; A = 0."),
    ("FE1C3A", "DiskApi_ReadFileToWindow_Entry",
     "the directory's entry (T_DiskApi_ReadFileToWindow_Entry): DiskApi_ReadFileToWindow, A to Disk_LastError, and on screen latch 0x49 (0x360B) bit 0 cleared."),
    ("FE1C4D", "DiskApi_WriteFileFromWindow_Entry",
     "the directory's entry (T_DiskApi_WriteFileFromWindow_Entry): DiskApi_WriteFileFromWindow, A to Disk_LastError."),
    ("FE26B8", "DiskApi_CheckFreeSpace",
     "DiskFile_CountFreeSpace (A = 6 when it fails); A = 7 -- the code DiskApi_WriteFileFromWindow returns for a full disk\n"
     "-- when the size argument, in 16-byte units, rounded up to KB (>> 6, + 1), is not below the free space; else 0.\n"
     "SmfWrite's first-window path computes that argument from SmfOut_TrackLength + 22."),
    # prom_b's most-called still-unnamed routines (call-site census, 2026-10-04)
    ("F70FE1", "BStore_PutByteAtCursor",
     "A to the block-store cursor: SongStore_SeekBlock_Copy(BStore_CursorBlock), then (BStore_CursorBlockAddr + BStore_CursorOffset) = A."),
    ("F70FF8", "BStore_AdvanceCursorForWrite",
     "BStore_CursorOffset + 1; at offset 255: no free block (BStore_FreeCount 0) -> (0x1238) = 0xFF, else\n"
     "BStore_ExtendChainAtCursor; (0x1238) = 0 on success."),
    ("F70FDA", "BStore_PutByteAndAdvance",
     "BStore_PutByteAtCursor then BStore_AdvanceCursorForWrite (107 call sites)."),
    ("F713E1", "BStore_ExtendChainAtCursor",
     "IX = a new block from T_F42884; the cursor block's next link (+3) = it, its previous link (+1) = the cursor block,\n"
     "its next = 0xFFFF; the cursor moves to it at offset 5 (the block header's length)."),
    ("F6B8BD", "BStore_ReadByteAtSongPosition",
     "for directory entry IZ: the block word 0x3460[2 * entry] and the offset byte 0x3482[entry] (the per-song position\n"
     "0xF6AC4D initialises to 0xFFFF / 5); A = the byte there."),
    ("F550A6", "EditValue_StepBitField",
     "steps a bit-field of the byte at the first argument through the field record XIX: +1 mask, +2 shift, +3 maximum,\n"
     "+4 minimum, +5 / +6 step sizes (chosen by PanelEvent_Flags bit 2 / UI_RequestBits bit 2), +7 PanelEvent_Flags XOR;\n"
     "up when PanelEvent_Flags bit 0, else down, clamped, written back under the mask (77 call sites)."),
    ("F7F237", "Blink_EnableThenStop_Copy",
     "byte-for-byte Blink_EnableThenStop: T_Blink_SetEnable(1), T_Blink_Stop."),
    ("F7F245", "Blink_DisableThenStop",
     "T_Blink_SetEnable(0), T_Blink_Stop."),
    # prom_a Msg0716 builders of other shapes (notes/prom_a_msg0716_message_names.py has the message format and the
    # receiver, prom_c MidiCtrl_Dispatch, that reads byte 2 as the MIDI controller number)
    ("FC1545", "Msg0716_PostCC07_VolumeWithOffset",
     "B0 <part> 07 <A + (0x0710)>, clamped to 0..0x7F (0x7F when it overflows and (0x7F4D) bit 2); A bit 7 set = value 0."),
    ("FC1528", "Msg0716_PostCC07_VolumeFromA",
     "B0 <part> 07 <A AND 0x7F>, or 0 when A bit 7 is set."),
    ("FC15C5", "Msg0716_PostCC40_SustainFromValue",
     "B0 <part> 40 <0x7F if UiEvent_Byte2 >= 0x40 else 0> -- MIDI's sustain threshold."),
    ("FC161D", "Msg0716_PostCC0A_PanWithOffset",
     "B0 <part> 0A <A + (0x0711) - 0x40>, clamped to 0..0x7F (controller 10, pan, which the receiver handles)."),
    ("FC159C", "Msg0716_PostCtrlInt9C",
     "B0 <part> 9C <0x7F if UiEvent_Byte2 bit 3 else 0>: the receiver's extension controller 0x9C as a switch."),
    ("FC1726", "Msg0716_PostCtrlInt9B",
     "B0 <part> 9B <value from the part's record (Msg0716_RecordPtrTable[(XIZ+6)] and 0x76C2 + its offset)>."),
    ("FC170D", "Msg0716_PostPitchBend",
     "E0 <part> <UiEvent_Byte2> <UiEvent_Byte3>, four bytes: MIDI pitch bend, LSB then MSB."),
    ("FC1927", "Msg0716_PostProgramChange",
     "C0 <part> <word from (XIY)> 00, five bytes: a program change carrying a 16-bit program number."),
]


def main():
    here = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    src = "".join(open(os.path.join(here, p), "rb").read().decode("latin-1")
                  for p in ("prom_a/wsa1_prom_a.s", "prom_b/wsa1_prom_b.s"))
    for o, n, ev in ROWS:
        if "--args" in sys.argv:
            if not re.search(r'^sub_%s:' % o, src, re.M):
                continue                          # applied already
            print("sub_%s=%s|%s: %s" % (o, n, n, ev.replace("\n", "\\n  ")))
        else:
            print("sub_%-7s -> %s" % (o, n))
    if "--args" not in sys.argv:
        print("rows %d" % len(ROWS))


if __name__ == "__main__":
    main()
