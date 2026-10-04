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
    # prom_a: NOTE / DRUM EDIT's value fields (0x601F45 NOTE, 0x601F46 VEL, 0x601F47 / 0x601F49 LEN, 0x601F4D INC)
    ("FEA183", "EditField_NoteUp",
     "(0x601F45), the NOTE field, + 1 up to 0x7F; redraws (0xFF0B46, 0xFE9A07).  NOTE EDIT draws the fields MEAS POS NOTE VEL LEN INC (DisplayList_NoteEditTrackSong)."),
    ("FEA199", "EditField_NoteDown",
     "(0x601F45) - 1 down to 1; redraws."),
    ("FEAC67", "EditField_NoteUp5",
     "(0x601F45) + 5, clamped to 0x7F; redraws."),
    ("FEAC8B", "EditField_NoteDown5",
     "(0x601F45) - 5, clamped to 1; redraws."),
    ("FEA1AF", "EditField_VelocityUp",
     "(0x601F46), the VEL field (1..127, 100 by default from 0xFE833F), + 1 up to 0x7F; redraws (0xFF0B3A)."),
    ("FEA1C2", "EditField_VelocityDown",
     "(0x601F46) - 1 down to 1; redraws."),
    ("FEAC1E", "EditField_VelocityUp5",
     "(0x601F46) + 5, clamped to 0x7F; redraws."),
    ("FEAC3F", "EditField_VelocityDown5",
     "(0x601F46) - 5, clamped to 1; redraws."),
    ("FEA1F7", "EditField_LengthUp",
     "the LEN field + 1 up to 0x2FFF: (0x601F47), or (0x601F49) when (0x601F5B) bit 0 is clear; redraws."),
    ("FEA23C", "EditField_LengthDown",
     "the LEN field - 1 down to 1 (0 becomes 1); redraws."),
    ("FEACD8", "EditField_LengthUp12",
     "the LEN field + 12, clamped to 0x2FFF; redraws."),
    ("FEAD49", "EditField_LengthDown12",
     "the LEN field - 12, clamped to 1; redraws."),
    ("FEA2BF", "EditField_IncUp",
     "(0x601F4D), the INC field (cursor step in ticks), + 1 up to 0x60; redraws (0xFF0D03)."),
    ("FEA2D4", "EditField_IncDown",
     "(0x601F4D) - 1 down to 1; at 0 it is reset to 0x30; redraws."),
    ("FEA2FD", "EditField_IncUp5",
     "(0x601F4D) + 5, clamped to 0x60; redraws."),
    ("FEA322", "EditField_IncDown5",
     "(0x601F4D) - 5, clamped; at 0 it is reset to 0x30; redraws."),
    ("FEA2A5", "EditField_StepInc",
     "repaint bit 3; unless (0x601F58) bit 7: W bit 7 clear -> EditField_IncUp, set -> EditField_IncDown (the key's two halves)."),
    ("FEADE1", "EditField_StepInc5",
     "as EditField_StepInc with EditField_IncUp5 / _IncDown5."),
    ("FEACB6", "EditField_StepLength12",
     "repaint bit 3; unless (0x601F58) bit 7 with (0x601F59) not 3: W bit 7 clear -> EditField_LengthUp12, set -> _LengthDown12."),
    # prom_a SysEx module: routines the committed probes already describe (notes/sysex-probes/README.md), named after them
    ("FB4CAE", "SysExTx_GmSystemOnOff",
     "transmits F0 7E 7F 09 01 F7 (GM System On) or 09 02 (Off), the literal at 0xF4FEE6 / 0xF4FEEC chosen by the record's\n"
     "byte +1 (README: 'The instrument transmits')."),
    ("FB5F2E", "SysExTx_AnnounceGmMode",
     "unless (0x60F020) bit 7: the record {B0, 0x11 if the argument's bit 2 else 0x10, 00, 7F} to SysExTx_GmSystemOnOff."),
    ("FB590A", "GmMode_HandleChange",
     "the only handler of internal event class 0x91 (UiListA_Class91): for byte index 3 -- the GM setting at 0x7F4D, record\n"
     "0x91 payload byte 3 -- applies it (0xFB5F0F) and SysExTx_AnnounceGmMode, guarded against re-entry by (0x60F01F) bit 0."),
    ("FB3355", "SysExTx_Tempo",
     "the tempo transmitter; bounds the value to 0x0028..0x012C like the receiver 0xFB33FE (README, tempo section)."),
    ("FB5197", "SysExRx_AnswerRefused2B2C",
     "for a family 2B or 2C message that is refused: SysExTx_Append of F0 50 29 7E F7 (0xF4FEC8), sent on both ports."),
    ("FB28BE", "SysExSession_AnswerByStatus",
     "with a session open, answers every message from the parse status: 0 -> F0 50 23 7E F7, 0x16 -> F0 50 2A 7E F7,\n"
     "else F0 50 24 7E F7 (README: 'What an open session answers with')."),
    ("FB374D", "SysExParam_CheckValueWhiteList",
     "walks the six-byte value records at 0xF51E58 and refuses a value not in them (README: the VALUE WHITE-LIST)."),
    ("FB4D62", "SysExTx_SendParamValue",
     "the family-2B transmitter: the descriptor's +0x18 method reads the instrument's value and calls it (README: 'Direction, three witnesses')."),
    # prom_a 0xFE3000-0xFE4BCB: under Disk_CommandDispatch.  The record DiskCmd_* take is an MS-DOS FCB:
    # +1..+11 the 8.3 name, +0x10 the file size (4 bytes); +0x18 directory index, +0x1A first cluster,
    # +0x1C last cluster sit in the FCB's DOS-reserved bytes.
    ("FE45BF", "Fat_MatchDirEntryName",
     "compares the 11-byte 8.3 name at arg 2 (a directory entry) with arg 1, byte by byte; a '?' (0x3F) on either\n"
     "side matches anything; an entry whose first byte is 0xE5 (deleted) never matches.  HL = 0 on a match, else 0xFF."),
    ("FE4671", "Fat_FindRootDirEntryByFcbName",
     "for every root-directory sector (count (0x605D52)) read by Disk_ReadRootDirSector and every 32-byte entry in it\n"
     "(count (0x605D50)), Fat_MatchDirEntryName against the FCB's name at arg + 1.  HL = the entry's index, or 0xFFFF.\n"
     "Called by DiskCmd_OpenFile."),
    ("FE46DA", "Fat_FindFreeRootDirEntry",
     "the same walk, stopping at the first entry whose first byte is 0x00 (never used) or 0xE5 (deleted).  HL = its\n"
     "index, or 0xFFFF.  Called by DiskCmd_CreateFile."),
    ("FE457E", "Disk_CopyBytes",
     "copies arg 3 (a word) bytes from the arg-2 pointer to the arg-1 pointer, one byte at a time.\n"
     "Called by DiskCmd_ReadFileBlock and DiskCmd_WriteFileBlock (blocks of 0x400)."),
    ("FE44BD", "Disk_WriteCurrentCluster",
     "writes the work buffer 0x606F9B to cluster (0x605D34): through Disk_WriteClusterFromWorkBuffer when the drive\n"
     "record ((0x605D22) + 2) is type 1, else inline the same Fat_ClusterToSector + Disk_WriteSectors of (0x605D56) sectors."),
    ("FE4B4B", "Fat_FindCrossLinkedCluster",
     "zeroes a byte per cluster at 0x60A002.., then for every cluster 2..0x3FF counts Fat_GetEntry's value (when it\n"
     "is non-zero and below the end-of-chain mark 0xFF8, 0xFFF8 on type 1); returns the first cluster counted more\n"
     "than once -- the target of two chains -- or 0."),
    ("FE423E", "DiskCmd_StoreFatIfConsistent",
     "Disk_CommandDispatch's code 0x85: on a type-1 drive returns 0; else Fat_FindCrossLinkedCluster, and only when it\n"
     "finds none, Fat_Store and (0x605D6C) = (0x605D6E) = 0.  Returns the cross-linked cluster otherwise."),
    ("FE4376", "Fcb_AddToFileSize",
     "adds the word arg 2 to the 32-bit value at arg 1, carrying into the high word when the low word passes 0xFFFF\n"
     "from 0xF000 up.  DiskCmd_WriteFileBlock passes FCB + 0x10, the file size, and 0x400 after each block."),
    ("FE3CF4", "Fat_FreeChain",
     "from the cluster arg 1 until the end-of-chain mark (0xFF8, 0xFFF8 on type 1): next = Fat_GetEntry, Fat_SetEntry\n"
     "the cluster to 0, step to next.  HL = 0xFF if 65536 clusters pass (a loop), else 0."),
    ("FE3D4D", "Fat_DiscardFcbFile",
     "marks the FCB's directory entry (index FCB + 0x18) deleted (first byte 0xE5) and writes its sector, ends the\n"
     "chain at FCB + 0x1C (Fat_SetEntry 0xFFFF), Fat_FreeChain from FCB + 0x1A, Fat_Store.  DiskCmd_WriteFileBlock\n"
     "calls it when Fat_FindFreeClusterAfter finds no cluster -- the disk is full."),
    ("FE30DD", "Disk_SetDriveGeometry",
     "(0x605D36) = arg & 0x0F; on a type-1 drive reads Dev7E_IdentifyDevice's data at 0x606F9B (Fdc_SetError 0xFC on\n"
     "failure) and takes the geometry from it; otherwise sets sectors per track (0x605D54: 9, 18 or 8), sectors per\n"
     "cluster (0x605D56), root entries (0x605D4E) and the other 0x605D3E-0x605D6A parameters per format code."),
    ("FE35F9", "Disk_DetectFloppyFormat",
     "DiskCmd_CheckMediaId; failing that, reads sector 1 (the FAT's first sector) into 0x606F9B and reads the media\n"
     "descriptor: 0xF9 -> 8, 0xF7 -> 0x0D (geometry 5); 0x00 FF FF -> probes sectors 0x12, 9 and 8 (18 per track -> 0x0B,\n"
     "9 -> 8, 8 -> 0x0A).  0xFFFE when the read reports not ready, 0xFF when nothing fits."),
    ("FE370A", "DiskCmd_MountDrive",
     "Disk_CommandDispatch's code 0: stores the drive type (0x605D98), invalidates the cached clusters (0x605D32/34/5E =\n"
     "0xFFFF), Disk_SetDriveGeometry, Fdc_Request op 10 (controller present) then op 0 (reset + identify media); on a\n"
     "floppy, Disk_DetectFloppyFormat up to three times.  HL = its format code when it recognises the disk, 0 for a\n"
     "type-1 drive or a passing DiskCmd_CheckMediaId, 1 no medium (0xFFFE, or status 0x30 / 0x31), 2 or 3 failure."),
    # prom_b 0xF000B9-0xF00320: the three transports' start / stop.  TransportA/B/C_State: bit 2 running,
    # 0x01 a start request, 0x0C a stop request (INTTR4_SequencerTick header; wsa1_ram.inc).
    ("F000B9", "Transport_StopAllRunning",
     "with interrupts at level 6, builds a mask of which transports run (A bit 2 -> 4, B -> 8, C -> 0x10) and calls\n"
     "Transport_StopByRunningMask[mask]; every handler there writes 0x0C to exactly the running transports' states."),
    ("F002C9", "TransportB_Stop", "TransportB_State = 0x0C.  Transport_StopByRunningMask's entry 2 (only B runs)."),
    ("F00280", "Transport_StopCAndA",
     "TransportC_State = 0x0C if C runs and has no stop pending (bit 3), then TransportA_State = 0x0C.  Entry 5 (A and C)."),
    ("F002F4", "TransportC_ResetCounters", "TransportC_Tick = 0, TransportC_Beat = 0, at interrupt level 6."),
    ("F00301", "TransportA_ResetCounters", "TransportA_Tick, TransportA_Beat and TransportA_Bar = 0, at interrupt level 6."),
    ("F00313", "TransportB_ResetCounters", "TransportB_Beat = 0, Seq_BeatTick (B's tick) = 0, at interrupt level 6."),
    ("F00320", "Transport_QueueMidiStartOrContinue",
     "when MIDI setting (0x7F34) bit 2 is set: MidiTx_RealtimePending bit 2 (FB CONTINUE) if (0x34BB) bit 3, else bit 1\n"
     "(FA START), then T_MIDI_PostSendWork."),
    ("F00293", "Transport_StartCAndB",
     "TransportC_State = 1, Transport_QueueMidiStartOrContinue, TransportB_State = 1."),
    ("F001B5", "Transport_ToggleCAndB",
     "if transport C runs, Transport_StopAllRunning; else Transport_StartCAndB at interrupt level 6."),
    ("F001C9", "Transport_StartAllFromZero",
     "unless C is starting or running: either a count-in (TransportA_State = 0x80, (0x34D9) |= 4, when (0x34D9) bit 1\n"
     "is set and bit 2 clear) or TransportC_State = 1 with TransportC_ResetCounters and the MIDI start; then\n"
     "TransportB_State = 1 + TransportB_ResetCounters and TransportA_State = 1 + TransportA_ResetCounters."),
    ("F00244", "Transport_StartAllContinue",
     "the same start without resetting C's or B's counters (only TransportA_ResetCounters)."),
    ("F0017D", "Transport_StartStopFromZero",
     "if C does not run, Transport_StartAllFromZero; if B runs and (0x3000) is non-zero, T_F40E18 with (0x60501B) bit 0\n"
     "set around it; otherwise Transport_StopAllRunning."),
    ("F0020B", "Transport_StartStopContinue",
     "the same with Transport_StartAllContinue for the start."),
    # prom_a 0xFE0000-0xFE2FFF: the disk module's file workers, above DiskCmd_MountDrive.
    ("FE1962", "Disk_MountFloppy",
     "Disk_CommandDispatch code 0 (DiskCmd_MountDrive) with drive code 0xAF, type 0; (0x221D) = 0xAF; the result to (0x1735)."),
    ("FE192D", "Disk_MountFloppy720K",
     "the same with drive code 0xD0.  Disk_MountFloppyWithRetry calls it when Disk_MountFloppy reports format 8 -- the\n"
     "code Disk_DetectFloppyFormat gives a 0xF9 media descriptor or 9 sectors per track, i.e. a 720K disk."),
    ("FE08BD", "Disk_MountFloppyWithRetry",
     "pulses Port B bit 2 (Delay_150Ticks), clears Disk_Flags bit 6, Disk_MountFloppy up to twice while it returns 2;\n"
     "format 0x0B (18 sectors per track) -> result 0 and Disk_Flags bit 6 set; 0x0A / 0x0C / 0x0D -> 0; format 8 ->\n"
     "Disk_MountFloppy720K.  Returns the result, also in (0x1735)."),
    ("FE0925", "Disk_SaveFileName", "copies the 9 bytes at Disk_FileName to 0x21DB."),
    ("FE0941", "Disk_RestoreFileName", "copies the 9 bytes at 0x21DB back to Disk_FileName."),
    ("FE0970", "Disk_ShowMountError",
     "for a mount result: 1 -> StatusMsg_ShowByIndex(8) (status 0x02, Error02 'There is no disk in the disk drive');\n"
     "2 or 3 -> index 16 (status 0x00, Error00); 0xFF -> index 13 (status 0x04, the bare ERROR list); each with a delay."),
    ("FE0CB9", "Disk_ScanDirectory",
     "builds its line buffers, sets Disk_FileName to eleven '?', the transfer address (code 0x1A) to 0x60A080 (also\n"
     "(0x21D3)), then DiskFile_FindFirst and, per found entry, Disk_ScanDirectory_RecordEntry + DiskFile_FindNext until it fails.\n"
     "Returns 0, or 0x1A when nothing matched."),
    ("FE0527", "Disk_MountAndScanDirectory",
     "StatusMsg_ShowByIndex(9) (PLEASE WAIT), Disk_MountFloppyWithRetry; on 0: Disk_SaveFileName, Disk_ScanDirectory,\n"
     "Disk_RestoreFileName; otherwise Disk_ShowMountError and Disk_PortA3_Release."),
    ("FE055B", "Disk_MountAndScanDirectory_LeaveOnError",
     "the same, but a failed mount also runs sub_FE1907, clears (0x2229) and sets UI_Request_Hi = 0x10."),
    ("FE179D", "Disk_InitFileNameCharset",
     "writes the 37 characters '_', 'A'..'Z', '0'..'9' to 0x1753.. -- the character set of the name editor."),
    ("FE2F39", "Disk_InitDriveAndNameEntry",
     "Disk_BootPhase3's body: pulses Port B bit 2 (2 and 5 ticks), Var220D_SetW4157, fills Disk_FileName with eleven\n"
     "'_', Disk_InitFileNameCharset."),
    ("FE2FC8", "StatusMsg_HoldForCode",
     "after StatusMsg_ShowByIndex paints: UI_StatusCode 0 -> Delay_Ticks(1500), 0x2B -> Delay_Ticks(500), else nothing."),
    ("F45B0A", "TimedEventRing_Discard",
     "at interrupt level 6: the ring control block 0x600800's put index (+6) = its get index (+2) and the count (+8) =\n"
     "0x1FF -- the 0x200-byte TimedEvents_Ring emptied (the block's layout: TimedEventRing_* in prom_a)."),
    ("FE0207", "Transport_StopAllRunning_SaveRegs2",
     "push XDE / XHL / XIX / XIZ, call T_F409AC (Transport_StopAllRunning), pop, ret.  The bytes after it to the next\n"
     "label are two more such wrappers that nothing calls."),
    # prom_a 0xFE1D52-0xFE2A21: DISK LOAD / DISK SAVE by content type.  (0x2725) is the content type: the
    # interpreter-B record at prom_b DL_F583F0 draws it from DLText_F585AD, twelve bytes per entry, which
    # reads ALL, SEQUENCER, COMBINATION, SOUND, PANEL, MIDI SETTING, SOUND RE-MAP, COMBI RE-MAP, DRUM MAP.
    # The extension each routine writes to Disk_FileName+8..10 is quoted: the files on disk use THESE, not
    # the .ALL/.SEQ/... display strings at 0xF58625.
    ("FE1D52", "DiskLoad_ByContentType",
     "dispatches on (0x2725): 0 ALL runs every loader below in turn (the sequencer only when Variant_Flag is 1),\n"
     "1 DiskLoad_Sequencer, 2 _Combination, 3 _Sound, 4 _PanelLswFile + _PanelSlsFile, 5 _MidiSetting,\n"
     "6 _SoundRemap, 7 _CombiRemap, 8 _DrumMap; anything else returns 4."),
    ("FE2531", "DiskSave_ByContentType",
     "the same dispatch on (0x2725) for saving: 1 DiskSave_Sequencer, 2 _Combination, 3 _Sound, 4 _PanelLswFile +\n"
     "_PanelSlsFile, 5 _MidiSetting, 6 _SoundRemap, 7 _CombiRemap, 8 _DrumMap; 0 ALL, all of them."),
    ("FE2368", "DiskLoad_Sequencer", "content type 1: T_F41EF8 (saving registers); result (0x23CB), 0x1D read as 1."),
    ("FE2CBF", "DiskSave_Sequencer", "content type 1: sub_FE0046; result (0x23CB)."),
    ("FE202F", "DiskLoad_Sound",
     "content type 3: extension 'TM ', DiskLoad_ReadFileIntoWindow, DiskLoad_CheckSoundRamTag ('WSA SOUND RAM S0'),\n"
     "then sub_FE20E1 moves 0x40000 bytes to 0xE80000 in 0x100-byte blocks and Link_SendAfterSoundRamLoadMsg."),
    ("FE2092", "DiskLoad_Combination",
     "content type 2: extension 'CMB', DiskLoad_CheckCombiTag ('WSA1'), sub_FE20E1 moves 0x16300 bytes to 0xEC0000\n"
     "in 0x58-byte blocks, T_Queue2E00_PostParam98Fields."),
    ("FE1EF1", "DiskLoad_MidiSetting", "content type 5: extension 'MDS', read into the window, then copied out in 9-byte pieces."),
    ("FE23BD", "DiskLoad_SoundRemap", "content type 6: extension 'S' + 'RM', DiskLoad_ReadRemapFile, 0x230 (0x650 for a '1' file) bytes to 0x5210."),
    ("FE23EA", "DiskLoad_CombiRemap", "content type 7: extension 'C' + 'RM', DiskLoad_ReadRemapFile, the same lengths to 0x5860."),
    ("FE2417", "DiskLoad_DrumMap", "content type 8: extension 'D' + 'RM', DiskLoad_ReadRemapFile, 0x1D0 bytes to 0x5EB0."),
    ("FE2484", "DiskLoad_ReadRemapFile",
     "extension bytes 9-10 = 'RM', window 0x60A700..+0x800, Disk_Flags bit 1 clear, DiskApi_ReadFileToWindow; 1 on success."),
    ("FE24BE", "DiskLoad_CopyBufferWords", "copies arg-2 bytes (as words) from the buffer 0x60A700 to the arg-1 address."),
    ("FE292D", "DiskSave_CopyWordsToBuffer", "the reverse: arg-2 bytes (as words) from the arg-1 address to the buffer 0x60A700."),
    ("FE1E3C", "DiskLoad_PanelLswFile",
     "content type 4, first file: extension 'LSW', read through DiskLoad_ReadFileIntoWindow, checked by sub_FE2DDD\n"
     "(0x10 when it refuses), read again and applied by sub_FE1EC3 + DiskLoad_ApplyPanelImage."),
    ("FE2430", "DiskLoad_PanelSlsFile",
     "content type 4, second file: extension 'SLS', into the window 0x60A700..+0x800, 0x600 bytes copied to 0x7000."),
    ("FE26E2", "DiskSave_PanelLswFile",
     "content type 4: DiskApi_CheckFreeSpace for the size in (0x760A)/(0x760B), extension 'LSW', DiskSave_WriteWindowToFile."),
    ("FE28D5", "DiskSave_PanelSlsFile",
     "content type 4: 0x600 bytes from 0x7000 to the buffer 0x60A700, extension 'SLS', DiskSave_WriteWindowToFile."),
    ("FE2993", "DiskSave_Sound", "content type 3: extension 'TM ' (the file DiskLoad_Sound reads)."),
    ("FE2A21", "DiskSave_Combination", "content type 2: extension 'CMB'."),
    ("FE2736", "DiskSave_MidiSetting", "content type 5: extension 'MDS'."),
    ("FE2863", "DiskSave_SoundRemap", "content type 6: extension 'S', then DiskSave_WriteRemapFile."),
    ("FE288B", "DiskSave_CombiRemap", "content type 7: extension 'C', then DiskSave_WriteRemapFile."),
    ("FE28B3", "DiskSave_DrumMap", "content type 8: extension 'D', then DiskSave_WriteRemapFile."),
    ("FE2916", "DiskSave_WriteRemapFile", "extension bytes 9-10 = 'RM', then the write."),
    ("FE1E29", "DiskLoad_ReadFileIntoWindow",
     "sub_FE2F86, Disk_Flags |= 0x20 and bit 1 cleared, DiskApi_ReadFileToWindow."),
    ("FE2980", "DiskSave_WriteWindowToFile",
     "sub_FE2F86, Disk_Flags bits 5 and 1 cleared, DiskApi_WriteFileFromWindow."),
    ("FE1FFF", "DiskLoad_ApplyPanelImage",
     "Disk_Flags |= 0x18 around: ParamImage_WriteRecordHeaders, ParamImage_SanitizeAllAndHook, ParamImage_QueueDiffAll,\n"
     "Queue2C00_DrainPassB, MidiIn_ServiceDeferred, UiEventList_Publish; returns 1.  Called after the LSW file is read."),
    ("FE1218", "Disk_ScanMidiFiles",
     "sets Disk_FileName to eight '?' + 'MID', the transfer address, DiskFile_FindFirst / _FindNext, and per entry\n"
     "(not deleted -- first byte 0xE5 -- and extension M I D) records it."),
    ("FE11D9", "Disk_MountAndScanMidiFiles",
     "sub_FE0514, Disk_MountFloppyWithRetry; on 0: Disk_SaveFileName, Disk_ScanMidiFiles, Disk_RestoreFileName;\n"
     "otherwise Disk_PortA3_Release, Disk_ShowMountError, a 1500-tick delay and UI_StatusCode = 2."),
    ("FE0E89", "Disk_ScanDirectory_RecordEntry",
     "for the entry DiskFile_FindFirst/_FindNext left at 0x60A080: if a record among the twenty 16-byte records at\n"
     "0x60A480 starts with the same two name characters, sub_FE0F6B merges it; otherwise, unless the entry is deleted\n"
     "(0xE5) or a .MID file or the table is full (0x840), sub_FE10AA and its 11-byte name go to a new record at (0x222B)."),
    ("FAA742", "Tempo_ApplyBpm",
     "unless MidiCfg_ModeBits bit 2: the BPM in the low 9 bits of (0x7EE2), reset to 120 when outside 40..300,\n"
     "to (0x60F800); TREG5 = 140,000,000 / (64 * BPM), rounded (FINDINGS-system-clock.md, lever B -- which quotes the\n"
     "byte-identical stale copy at 0xFAA342); then SysExTx_Tempo through T_F408EC unless MidiCfg_ModeBits bit 4 or\n"
     "(0x60F020) bit 4, which it clears.  18 call sites, among them List2030_Tempo_Apply and ParamModule_BootPhase1."),
    ("F31852", "LCD_BlankThenSetPanel3Layer_Copy",
     "byte for byte LCD_BlankThenSetPanel3Layer (prom_a 0xF99000): SWI 7 service 0x0C with C = 0, then 0x10.\n"
     "wsa1_exact_copy_names.py refuses it only because prom_a has two names for that body; 36 call sites."),
    # prom_a 0xFEF7D2-0xFEF86C: an interpreter-A record's opcode IS the SWI 7 service it calls (FINDINGS-ui-display-list.md:
    # the bound 0x24 is one past the last service), so op 0x1B with four words is LCD_Svc_1B_EraseRect (x0, y0, x1, y1).
    ("FEF7E6", "NoteEdit_EraseEditArea",
     "runs DisplayList_FEF7F5, one op-0x1B record: LCD_Svc_1B_EraseRect (0x10, 0x29)-(0x102, 0xAE)."),
    ("FEF7E1", "NoteEdit_EraseEditArea_Layer0", "LCD_CurrentLayer = 0, then falls into NoteEdit_EraseEditArea."),
    ("FEF804", "DrumEdit_EraseEditArea",
     "runs DisplayList_FEF813: LCD_Svc_1B_EraseRect (0x58, 0x29)-(0x102, 0xAE): NOTE EDIT's area from x = 0x58."),
    ("FEF7FF", "DrumEdit_EraseEditArea_Layer0", "LCD_CurrentLayer = 0, then falls into DrumEdit_EraseEditArea."),
    ("FEF7D2", "EditScreen_EraseEditArea_Layer0",
     "EditScreen_Mode bit 0 (DRUM EDIT) -> DrumEdit_EraseEditArea_Layer0, else NoteEdit_EraseEditArea_Layer0.  22 call sites."),
    ("FEF859", "EditScreen_EraseEditArea_Layer1",
     "LCD_CurrentLayer = 1, then by EditScreen_Mode bit 0 DrumEdit_ or NoteEdit_EraseEditArea."),
    # prom_a 0xFF0989-0xFF0A7A: the NOTE / DRUM EDIT position readouts.  Each stores a value to the interpreter-B
    # source variable 0x26B0 and runs a one-record list that draws it (op 06: digits; op 02: a string-table entry).
    ("FF0989", "EditScreen_DrawMeasure",
     "layer 0; EditCursor_Measure below 1000 is drawn as a number (DisplayList_FF09EB), otherwise the string '***.'\n"
     "(DisplayList_FF09D8, string table entry 0 at 0xFF09E7)."),
    ("FF0A04", "EditScreen_DrawBeat", "layer 0; EditCursor_Beat + 1 to 0x26B0, DisplayList_FF0A39 (op 06, digits)."),
    ("FF0A52", "EditScreen_DrawTick", "layer 0; EditCursor_Tick to 0x26B0, DisplayList_FF0A71 (op 06, digits)."),
    # prom_a 0xFEB03D-0xFEB280: the left column of NOTE / DRUM EDIT, x 0..0x16, twelve 10-pixel rows from y = 0x2A.
    ("FEB07A", "DrumEdit_DrawRowNotes",
     "layer 0, then DrumEdit_DrawRowNote0 .. DrumEdit_DrawRowNote11.  Called by sub_FEB069 only when EditScreen_Mode\n"
     "bit 0 (DRUM EDIT) is set."),
    ("FEB03D", "EditScreen_HighlightCursorRow",
     "LCD_Svc_05_FillRect x 0..0x16, y = (0x601F73) * 10 + 0x2A .. +8: one 10-pixel row of the left column.  Called\n"
     "between EditScreen_EraseLeftColumn_Layer1 and the DRUM EDIT row numbers by the three column redraws."),
    ("FEF86D", "EditScreen_EraseLeftColumn_Layer1",
     "layer 1, DisplayList_FEF881: LCD_Svc_1B_EraseRect (0, 0x2A)-(0x16, 0xA3) -- the twelve rows' column.  Called by\n"
     "NoteEdit_DrawKeyboardRuler and the column redraws."),
    ("FEB0A4", "DrumEdit_DrawRowNote0",
     "(0x601F71) + 0 to the interpreter-B variable 0x26B0, then a one-record list (op 0A, a decimal readout,\n"
     "handler 0xF31C14) -- row 0's note number."),
    ("FEB0C8", "DrumEdit_DrawRowNote1",
     "(0x601F71) + 1 to the interpreter-B variable 0x26B0, then a one-record list (op 0A, a decimal readout,\n"
     "handler 0xF31C14) -- row 1's note number."),
    ("FEB0F0", "DrumEdit_DrawRowNote2",
     "(0x601F71) + 2 to the interpreter-B variable 0x26B0, then a one-record list (op 0A, a decimal readout,\n"
     "handler 0xF31C14) -- row 2's note number."),
    ("FEB118", "DrumEdit_DrawRowNote3",
     "(0x601F71) + 3 to the interpreter-B variable 0x26B0, then a one-record list (op 0A, a decimal readout,\n"
     "handler 0xF31C14) -- row 3's note number."),
    ("FEB140", "DrumEdit_DrawRowNote4",
     "(0x601F71) + 4 to the interpreter-B variable 0x26B0, then a one-record list (op 0A, a decimal readout,\n"
     "handler 0xF31C14) -- row 4's note number."),
    ("FEB168", "DrumEdit_DrawRowNote5",
     "(0x601F71) + 5 to the interpreter-B variable 0x26B0, then a one-record list (op 0A, a decimal readout,\n"
     "handler 0xF31C14) -- row 5's note number."),
    ("FEB190", "DrumEdit_DrawRowNote6",
     "(0x601F71) + 6 to the interpreter-B variable 0x26B0, then a one-record list (op 0A, a decimal readout,\n"
     "handler 0xF31C14) -- row 6's note number."),
    ("FEB1B8", "DrumEdit_DrawRowNote7",
     "(0x601F71) + 7 to the interpreter-B variable 0x26B0, then a one-record list (op 0A, a decimal readout,\n"
     "handler 0xF31C14) -- row 7's note number."),
    ("FEB1E0", "DrumEdit_DrawRowNote8",
     "(0x601F71) + 8 to the interpreter-B variable 0x26B0, then a one-record list (op 0A, a decimal readout,\n"
     "handler 0xF31C14) -- row 8's note number."),
    ("FEB208", "DrumEdit_DrawRowNote9",
     "(0x601F71) + 9 to the interpreter-B variable 0x26B0, then a one-record list (op 0A, a decimal readout,\n"
     "handler 0xF31C14) -- row 9's note number."),
    ("FEB230", "DrumEdit_DrawRowNote10",
     "(0x601F71) + 10 to the interpreter-B variable 0x26B0, then a one-record list (op 0A, a decimal readout,\n"
     "handler 0xF31C14) -- row 10's note number."),
    ("FEB258", "DrumEdit_DrawRowNote11",
     "(0x601F71) + 11 to the interpreter-B variable 0x26B0, then a one-record list (op 0A, a decimal readout,\n"
     "handler 0xF31C14) -- row 11's note number."),
    # prom_a 0xFE9CFC-0xFEA86F: the NOTE / DRUM EDIT soft keys.  DisplayList_NoteEditTrackSong's text at row 199 labels the
    # columns MEAS, POS, NOTE, VEL, LEN, INC, then '- CURSOR' with '<' (col 32) and '>' (col 37) on row 220; DRUM EDIT's
    # list reads MEAS, POS, SND, VEL, INC, '- CURSOR' '<' (27) '>' (32), ENTER (35).  Up / down arrows sit above / below
    # the first five or six columns (bit 7 of the code picks which).
    ("FEA36C", "EditScreen_CursorRight",
     "the 'CURSOR >' key: SoftKeyCol8_NoteEdit and SoftKeyCol7_DrumEdit call it (DRUM EDIT has one column fewer)."),
    ("FEA86F", "EditScreen_CursorLeft",
     "the 'CURSOR <' key: SoftKeyCol7_NoteEdit and SoftKeyCol6_DrumEdit call it."),
    ("FE9CFC", "EditCursor_MeasurePlus1",
     "EditCursor_Measure + 1 unless it is above 999, then EditCursor_MeasureChanged.  EditScreen_SoftKeyCol1 (MEAS), bit 7 clear."),
    ("FE9D16", "EditCursor_MeasureMinus1",
     "EditCursor_Measure - 1 unless it is 1, then EditCursor_MeasureChanged.  EditScreen_SoftKeyCol1 (MEAS), bit 7 set."),
    ("FE9D2E", "EditCursor_MeasureChanged",
     "redraws the measure (EditScreen_DrawMeasure between the bottom-row erases), (0x601F54) = 0, erases the edit area on\n"
     "both layers, EditCursor_Beat = EditCursor_Tick = 0, (0x601F58) = 0x82, (0x601F59) = 0.  Called by the MEAS +-1 / +-10 steps."),
    ("FE9D60", "EditCursor_MeasureChangedByCursor",
     "the same with (0x601F58) = 0x81; called only by EditScreen_CursorRight."),
    ("FE9F74", "EditCursor_TickMinus1",
     "EditCursor_Tick - 1, or EditCursor_PrevBeat at tick 0; then EditScreen_DrawTick and the redraws.  EditScreen_SoftKeyCol2\n"
     "(POS) with bit 7 set -- the counterpart of EditCursor_TickPlus1."),
    ("FE9F95", "EditCursor_TickMinus5",
     "EditCursor_Tick - 5, floored at 0 (EditCursor_PrevBeat at tick 0) -- the counterpart of EditCursor_TickPlus5."),
    ("FE9FC7", "EditCursor_PrevBeat",
     "at beat > 0: EditCursor_Beat - 1 with EditCursor_Tick = 0x5F (the beat's last of 96 ticks); at beat 0, the previous\n"
     "measure's last tick (EditCursor_Measure - 1) or the boundary handling of (0x601F5D) / (0x601F5B).  The counterpart of\n"
     "EditCursor_NextBeat."),
    # prom_a 0xFC01B1-0xFC1975: Msg0716 module, the reset copies and two all-parts loops.  The three RAM blocks are the ones the
    # DISK LOAD content types 6-8 fill (DiskLoad_SoundRemap 0x5210, _CombiRemap 0x5860, _DrumMap 0x5EB0).
    ("FC01B1", "SoundRemap_ResetToDefault",
     "copies 0x650 bytes from RamDefault_SoundRemap to RAM 0x5210 -- the block DiskLoad_SoundRemap fills from a .SRM file.\n"
     "Called by Msg0716_BootPhase2_MemoryLost."),
    ("FC01C7", "CombiRemap_ResetToDefault",
     "copies 0x650 bytes from RamDefault_CombiRemap to RAM 0x5860 -- the block DiskLoad_CombiRemap fills from a .CRM file."),
    ("FC01DD", "DrumMap_ResetToDefault",
     "copies 0x1D0 bytes from RamDefault_DrumMap to RAM 0x5EB0 -- the block DiskLoad_DrumMap fills from a .DRM file."),
    ("FC1975", "Msg0716_PostCC40_SustainOff",
     "posts B0 <part (XIZ+6)> 40 00 -- MIDI controller 0x40, Sustain, value 0 -- through Msg0716_Post_Trampoline."),
    ("FC10FA", "Msg0716_AllPartsSustainOff",
     "for the 32 object records from Msg0716_ObjectRecords (8 bytes each): Msg0716_PostCC40_SustainOff."),
    ("FC10DD", "Msg0716_AllPartsResetBendAndModulation",
     "for the 32 object records: Msg0716_PostPitchBendCenter and Msg0716_PostCC01_ModulationZero.  Called by Msg0716_AllPartsResetBendAndModulation_Call\n"
     "and Msg0716_AllPartsResetBendAndModulation_SaveRegs."),
    ("FEA709", "EditCursor_AdvanceToNextIncStep",
     "EditCursor_TickInMeasure = the first multiple of EditField_Inc above it (adds EditField_Inc from 0 until it passes).\n"
     "The first step of EditScreen_CursorRight."),
    # prom_b 0xF7122F-0xF71299: the MIDI FILE loader's helpers (the SMF header fields: notes/prom_b_smf_reader.py)
    ("F7122F", "Smf_TicksToPpq96",
     "unless Smf_Division is 96: XWA = XWA * 96 / Smf_Division -- a delta time in the file's ticks per quarter note\n"
     "rescaled to the sequencer's 96 per beat (INTTR4_SequencerTick's resolution)."),
    ("F7124E", "TrackCursor_Load",
     "BStore_CursorBlock = word[IY] of the table at RAM 0x3460, BStore_CursorOffset = byte[IY] of the table at 0x3482:\n"
     "the block-store cursor of track IY."),
    ("F71275", "TrackCursor_Save", "the reverse: the BStore cursor into word[IY] at 0x3460 and byte[IY] at 0x3482."),
    # prom_b 0xF6FD7A-0xF71369: the MIDI FILE loader's event layer.  RAM: 0x10CC running status, 0x10D0-0x10D2 the event
    # (status, data 1, data 2), 0x1193 the raw variable-length bytes, 0x1198-0x119A their value (wsa1_ram.inc).
    ("F6FDF5", "Smf_ReadVlqBytes",
     "reads input bytes (InputStream_GetByte) to 0x1193 while bit 7 is set -- an SMF variable-length quantity; IX = its length."),
    ("F71369", "Smf_ReadVlqBytes_Copy", "the same twelve instructions as Smf_ReadVlqBytes."),
    ("F6FE96", "Smf_ClearVlqValue", "the decoded value words (0x1198), (0x119A) = 0."),
    ("F6FDE4", "Smf_ClearVlqBytes", "the two words at 0x1193 (the raw bytes) = 0."),
    ("F6FE1B", "Smf_DecodeVlq",
     "packs IX = 1, 2 or 3 raw bytes' low 7 bits, most significant first, into the 24-bit value at 0x1198..0x119A."),
    ("F6FD7A", "Smf_ReadVlq", "Smf_ClearVlqBytes, Smf_ReadVlqBytes, and on a good read Smf_DecodeVlq."),
    ("F6FEFE", "SmfEvent_ReadWithNewStatus",
     "A is a status byte: (0x10CC) = it (the running status), (0x10D0) = it, then one data byte for 0xCn / 0xDn and two\n"
     "otherwise to 0x10D1..; then SmfEvent_DispatchChannelMessage."),
    ("F6FEA1", "SmfEvent_ReadWithRunningStatus",
     "A is a data byte: the status is the running status (0x10CC); A and the remaining data bytes to 0x10D1..; then\n"
     "SmfEvent_DispatchChannelMessage for a format-0 or one-track file, sub_F71DB7 otherwise."),
    ("F6FF44", "SmfEvent_DispatchChannelMessage",
     "clamps both data bytes to 127 and dispatches on the status's high nibble: 0x90 with velocity > 0 SmfEvent_NoteOn,\n"
     "0x80 or velocity 0 SmfEvent_NoteOff, 0xB0 _ControlChange, 0xE0 _PitchBend, 0xC0 _ProgramChange, 0xD0 _ChannelPressure;\n"
     "0xA0 (polyphonic pressure) is dropped."),
    ("F70ED5", "SmfEvent_NoteOn", "SmfEvent_DispatchChannelMessage's arm for status 0x9n with a non-zero velocity."),
    ("F71023", "SmfEvent_NoteOff", "the arm for status 0x8n, and for 0x9n with velocity 0."),
    ("F7039A", "SmfEvent_ControlChange", "the arm for status 0xBn."),
    ("F70330", "SmfEvent_PitchBend", "the arm for status 0xEn; it writes song code 0xD2 to the channel's track."),
    ("F70008", "SmfEvent_ProgramChange", "the arm for status 0xCn."),
    ("F6FFAE", "SmfEvent_ChannelPressure",
     "the arm for status 0xDn: to the channel's track (TrackCursor_Load) song code 0xD0, the delta time\n"
     "(Smf_TicksToPpq96 of the track's word at 0x10D3) and the pressure; then TrackCursor_Save."),
    # prom_b SmfEvent_ControlChange (0xF7039A): controllers 0-15 through SmfCC_HandlersByNumber (renamed SmfCC_HandlersByNumber),
    # 16-19, 32, 38, 64, 66, 67, 91, 93, 94, 96, 97, 98/99, 101, 100 by compare; 66 and 67 and the table's empty slots are
    # bare rets.  Each handler is named for the MIDI 1.0 controller number it receives.
    ("F704CE", "SmfCC_BankSelectMsb",
     "SmfCC_HandlersByNumber[0]: SmfEvent_ControlChange's handler for MIDI controller 0."),
    ("F704E7", "SmfCC_Modulation",
     "SmfCC_HandlersByNumber[1]: SmfEvent_ControlChange's handler for MIDI controller 1."),
    ("F71A23", "SmfCC_Breath",
     "SmfCC_HandlersByNumber[2]: SmfEvent_ControlChange's handler for MIDI controller 2."),
    ("F71A5C", "SmfCC_Foot",
     "SmfCC_HandlersByNumber[4]: SmfEvent_ControlChange's handler for MIDI controller 4."),
    ("F7053F", "SmfCC_DataEntryMsb",
     "SmfCC_HandlersByNumber[6]: SmfEvent_ControlChange's handler for MIDI controller 6."),
    ("F7063C", "SmfCC_Volume",
     "SmfCC_HandlersByNumber[7]: SmfEvent_ControlChange's handler for MIDI controller 7."),
    ("F7068A", "SmfCC_Pan",
     "SmfCC_HandlersByNumber[10]: SmfEvent_ControlChange's handler for MIDI controller 10."),
    ("F70754", "SmfCC_Expression",
     "SmfCC_HandlersByNumber[11]: SmfEvent_ControlChange's handler for MIDI controller 11."),
    ("F7193F", "SmfCC_GeneralPurpose1",
     "SmfEvent_ControlChange's arm for MIDI controller 16 (`cp a,16 / jr z`)."),
    ("F71978", "SmfCC_GeneralPurpose2",
     "SmfEvent_ControlChange's arm for MIDI controller 17 (`cp a,17 / jr z`)."),
    ("F719B1", "SmfCC_GeneralPurpose3",
     "SmfEvent_ControlChange's arm for MIDI controller 18 (`cp a,18 / jr z`)."),
    ("F719EA", "SmfCC_GeneralPurpose4",
     "SmfEvent_ControlChange's arm for MIDI controller 19 (`cp a,19 / jr z`)."),
    ("F707AE", "SmfCC_BankSelectLsb",
     "SmfEvent_ControlChange's arm for MIDI controller 32 (`cp a,32 / jr z`)."),
    ("F70599", "SmfCC_DataEntryLsb",
     "SmfEvent_ControlChange's arm for MIDI controller 38 (`cp a,38 / jr z`)."),
    ("F707E6", "SmfCC_Sustain",
     "SmfEvent_ControlChange's arm for MIDI controller 64 (`cp a,64 / jr z`)."),
    ("F709ED", "SmfCC_Effect1Depth",
     "SmfEvent_ControlChange's arm for MIDI controller 91 (`cp a,91 / jr z`)."),
    ("F70960", "SmfCC_Effect3Depth",
     "SmfEvent_ControlChange's arm for MIDI controller 93 (`cp a,93 / jr z`)."),
    ("F709B6", "SmfCC_Effect4Depth",
     "SmfEvent_ControlChange's arm for MIDI controller 94 (`cp a,94 / jr z`)."),
    ("F70A43", "SmfCC_DataIncrement",
     "SmfEvent_ControlChange's arm for MIDI controller 96 (`cp a,96 / jr z`)."),
    ("F70A97", "SmfCC_DataDecrement",
     "SmfEvent_ControlChange's arm for MIDI controller 97 (`cp a,97 / jr z`)."),
    ("F70C6F", "SmfCC_Nrpn",
     "SmfEvent_ControlChange's arm for controllers 98 and 99 (NRPN LSB / MSB): it clears the channel's bit in the\n"
     "mask at 0x11B4."),
    ("F70CBA", "SmfCC_RpnMsb",
     "SmfEvent_ControlChange's arm for MIDI controller 101 (`cp a,101 / jr z`)."),
    ("F70D42", "SmfCC_RpnLsb",
     "SmfEvent_ControlChange's arm for MIDI controller 100 (`cp a,100 / jr z`)."),
    ("F6FB51", "SmfEvent_Meta",
     "after an FF byte: reads the meta type; 0x2F (End of Track) reads its length byte and sets (0x10CB) = 0xFF;\n"
     "0x51 (Set Tempo) reads two bytes and SmfMeta_SetTempo; 0x02, 0x03, 0x58 and every other type: Smf_ReadVlq for the\n"
     "length and Smf_SkipBytes."),
    ("F6FC10", "SmfMeta_SetTempo",
     "the Set Tempo meta event: the microseconds per quarter note (three bytes, the first in A) -> BPM = 234,375 /\n"
     "(tempo >> 8), i.e. 60,000,000 / tempo, clamped to 40..300 -- the range Tempo_ApplyBpm accepts."),
    ("F6FD91", "Smf_SkipBytes",
     "advances InputStream_Cursor by Smf_VlqValue, refilling the 1 KB input window (InputStream_Refill) when it passes\n"
     "0x60AAFF."),
    ("F712FB", "Smf_DeltaToPpq96",
     "the delta time in Smf_VlqValue (24 bits) rescaled to 96 per beat: * 96 / Smf_Division, unless the division is 96."),
    ("F712B6", "Smf_AddDeltaToHeldNotes",
     "for each of the 33 seven-byte records at 0x305A whose bit 7 is set (a note still sounding), adds Smf_DeltaToPpq96 to\n"
     "its word at +5, saturating at 0x2FFF -- the largest note length (EditField_Length's limit)."),
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
