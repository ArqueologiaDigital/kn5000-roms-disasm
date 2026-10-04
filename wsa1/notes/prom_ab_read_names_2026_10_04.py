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
  python3 notes/prom_ab_read_names_2026_10_04.py --place  # 'ADDR=Name|header' for the label placer (PLACED rows)
  python3 notes/prom_ab_read_names_2026_10_04.py --relabel  # 'old=new|header' for labels that had a name (RELABEL rows)
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
     "(0x2160) = 0xFFFF, (0x215E) = 0, (0x0C00) = 0, T_Transport_StopAllRunning; then (0x34BB) |= 4.  Called by Paint_StepRecordPartSelect."),
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
     "when Medley_Playing is 1: clears it and (0x22D0); for an INT source, or FD with a NORM file: T_Medley_Stop and, unless\n"
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
     "clears (0x60505E) bit 0 and (0x60504C), MidiInQueue_InjectAllNotesOff_AllChannels, T_PartNotes_ReleaseAllReceivedMidiIn, then clears the\n"
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
    ("FEA183", "EditField_EventVelocityUp",
     "(0x601F45), the NOTE field, + 1 up to 0x7F; redraws (0xFF0B46, 0xFE9A07).  NOTE EDIT draws the fields MEAS POS NOTE VEL LEN INC (DisplayList_NoteEditTrackSong)."),
    ("FEA199", "EditField_EventVelocityDown",
     "(0x601F45) - 1 down to 1; redraws."),
    ("FEAC67", "EditField_EventVelocityUp5",
     "(0x601F45) + 5, clamped to 0x7F; redraws."),
    ("FEAC8B", "EditField_EventVelocityDown5",
     "(0x601F45) - 5, clamped to 1; redraws."),
    ("FEA1AF", "EditField_NewNoteVelocityUp",
     "(0x601F46), the VEL field (1..127, 100 by default from 0xFE833F), + 1 up to 0x7F; redraws (0xFF0B3A)."),
    ("FEA1C2", "EditField_NewNoteVelocityDown",
     "(0x601F46) - 1 down to 1; redraws."),
    ("FEAC1E", "EditField_NewNoteVelocityUp5",
     "(0x601F46) + 5, clamped to 0x7F; redraws."),
    ("FEAC3F", "EditField_NewNoteVelocityDown5",
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
     "push XDE / XHL / XIX / XIZ, call T_Transport_StopAllRunning (Transport_StopAllRunning), pop, ret.  The bytes after it to the next\n"
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
    ("FE2368", "DiskLoad_Sequencer", "content type 1: T_SeqFile_Load (saving registers); result (0x23CB), 0x1D read as 1."),
    ("FE2CBF", "DiskSave_Sequencer", "content type 1: SeqFile_Save_SaveRegs; result (0x23CB)."),
    ("FE202F", "DiskLoad_Sound",
     "content type 3: extension 'TM ', DiskLoad_ReadFileIntoWindow, DiskLoad_CheckSoundRamTag ('WSA SOUND RAM S0'),\n"
     "then DiskLoad_StreamFileToLinkRam moves 0x40000 bytes to 0xE80000 in 0x100-byte blocks and Link_SendAfterSoundRamLoadMsg."),
    ("FE2092", "DiskLoad_Combination",
     "content type 2: extension 'CMB', DiskLoad_CheckCombiTag ('WSA1'), DiskLoad_StreamFileToLinkRam moves 0x16300 bytes to 0xEC0000\n"
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
     "content type 4, first file: extension 'LSW', read through DiskLoad_ReadFileIntoWindow, checked by DiskLoad_CheckLswHeader\n"
     "(0x10 when it refuses), read again and applied by DiskLoad_RestoreRam7FC0 + DiskLoad_ApplyPanelImage."),
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
     "byte-identical stale copy at 0xFAA342); then SysExTx_Tempo through T_SysExTx_Tempo unless MidiCfg_ModeBits bit 4 or\n"
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
     "layer 0, then DrumEdit_DrawRowNote0 .. DrumEdit_DrawRowNote11.  Called by DrumEdit_RedrawRowList only when EditScreen_Mode\n"
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
     "SmfEvent_DispatchChannelMessage for a format-0 or one-track file, SmfEvent_DispatchChannelMessage_MultiTrack otherwise."),
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
    # prom_b: the part-record setters behind the SMF controller handlers (SmfPart_GetRecordPtr: XIY = the event channel's
    # 64-byte record at 0x6036A0 + SmfPart_RecordOffsets[channel]).
    ("F7067F", "SmfPart_SetVolume", "SmfPart_GetRecordPtr, then record +5 = data byte 2.  Called by SmfCC_Volume (and SmfCC_Volume_MultiTrack)."),
    ("F709A3", "SmfPart_SetEffect3Depth",
     "SmfPart_GetRecordPtr, then record +7 = data byte 2, keeping its bit 7.  Called by SmfCC_Effect3Depth."),
    ("F709DA", "SmfPart_SetEffect4Depth", "record +8 the same way.  Called by SmfCC_Effect4Depth."),
    ("F70A30", "SmfPart_SetEffect1Depth", "record +9 the same way.  Called by SmfCC_Effect1Depth."),
    ("F45975", "SeqBufRing_Discard",
     "at interrupt level 6: the control block 0x600A0A of SeqBuf_Ring (0x600A14) gets its +2 index = its +6 index and its\n"
     "+8 count = 0x1FF -- the 0x200-byte sequencer ring emptied, the same three stores as TimedEventRing_Discard."),
    # prom_a: the part-record field setters.  List2030_Part*_Apply's headers fix the record bytes: 3 volume, 5 / 6 / 7 effect
    # 3 / 4 / 1 depth, 8 pan, 9 coarse tune, 0x0A fine tune (8-bit), 0x0B bend range (MidiOut_ParamClassTable's classes).
    ("FAB8E9", "List2030_PartVolume_Apply_Call", "JumpTable_FAB8B4[3]: `calr List2030_PartVolume_Apply / jr` to the table's shared `ret` -- the shape of class 11's\n"
     "List2030_PartBendRange_Apply_Call."),
    ("FAB8F3", "List2030_PartEffect3Depth_Apply_Call", "JumpTable_FAB8B4[5]: `calr List2030_PartEffect3Depth_Apply / jr` to the table's shared `ret` -- the shape of class 11's\n"
     "List2030_PartBendRange_Apply_Call."),
    ("FAB8F8", "List2030_PartEffect4Depth_Apply_Call", "JumpTable_FAB8B4[6]: `calr List2030_PartEffect4Depth_Apply / jr` to the table's shared `ret` -- the shape of class 11's\n"
     "List2030_PartBendRange_Apply_Call."),
    ("FAB8FD", "List2030_PartEffect1Depth_Apply_Call", "JumpTable_FAB8B4[7]: `calr List2030_PartEffect1Depth_Apply / jr` to the table's shared `ret` -- the shape of class 11's\n"
     "List2030_PartBendRange_Apply_Call."),
    ("FAB902", "List2030_PartPan_Apply_Call", "JumpTable_FAB8B4[8]: `calr List2030_PartPan_Apply / jr` to the table's shared `ret` -- the shape of class 11's\n"
     "List2030_PartBendRange_Apply_Call."),
    ("FAB907", "List2030_PartCoarseTune_Apply_Call", "JumpTable_FAB8B4[9]: `calr List2030_PartCoarseTune_Apply / jr` to the table's shared `ret` -- the shape of class 11's\n"
     "List2030_PartBendRange_Apply_Call."),
    ("FAB90C", "List2030_PartFineTune_Apply_Call", "JumpTable_FAB8B4[10]: `calr List2030_PartFineTune_Apply / jr` to the table's shared `ret` -- the shape of class 11's\n"
     "List2030_PartBendRange_Apply_Call."),
    ("FB5B6A", "GmReset_PartVolume",
     "for records 0..31: IndexedTable_MergeMaskedByte of {record, byte 3, 100 (0x64), mask 0x7F} -- every part's Volume set to the\n"
     "GM default.  One step of GmMode_ResetToDefaults."),
    ("FB5B97", "GmReset_PartEffect3Depth",
     "for records 0..31: IndexedTable_MergeMaskedByte of {record, byte 5, 0, mask 0x7F} -- every part's Effect3Depth set to the\n"
     "GM default.  One step of GmMode_ResetToDefaults."),
    ("FB5BEF", "GmReset_PartEffect4Depth",
     "for records 0..31: IndexedTable_MergeMaskedByte of {record, byte 6, 0, mask 0x7F} -- every part's Effect4Depth set to the\n"
     "GM default.  One step of GmMode_ResetToDefaults."),
    ("FB5C1B", "GmReset_PartEffect1Depth",
     "for records 0..31: IndexedTable_MergeMaskedByte of {record, byte 7, 90 (0x5A), mask 0x7F} -- every part's Effect1Depth set to the\n"
     "GM default.  One step of GmMode_ResetToDefaults."),
    ("FB5C47", "GmReset_PartPan",
     "for records 0..31: IndexedTable_MergeMaskedByte of {record, byte 8, 64 (0x40), centre, mask 0x7F} -- every part's Pan set to the\n"
     "GM default.  One step of GmMode_ResetToDefaults."),
    ("FB5C73", "GmReset_PartCoarseTune",
     "for records 0..31: IndexedTable_MergeMaskedByte of {record, byte 9, 64 (0x40), centre} -- every part's CoarseTune set to the\n"
     "GM default.  One step of GmMode_ResetToDefaults."),
    ("FB5C9F", "GmReset_PartFineTune",
     "for records 0..31: IndexedTable_MergeMaskedByte of {record, byte 10, 128 (0x80), centre, mask 0xFF} -- every part's FineTune set to the\n"
     "GM default.  One step of GmMode_ResetToDefaults."),
    ("FB5CCB", "GmReset_PartBendRange",
     "for records 0..31: IndexedTable_MergeMaskedByte of {record, byte 11, 2, mask 0x7F} -- every part's BendRange set to the\n"
     "GM default.  One step of GmMode_ResetToDefaults."),
    ("FB58CC", "GmMode_ResetToDefaults",
     "the GM reset sequence: sub_FB556D (SOUND mode when (0x7F02) & 0xF0 is 0x10), sub_FB5A17, sub_FB56D3, the\n"
     "GmReset_Part* steps (volume 100, effect depths 0 / 0 / 90, pan and tuning centred, bend range 2) and further\n"
     "resets.  Called by GmMode_ApplyChange (GmMode_HandleChange's) and sub_FB585E."),
    # prom_a 0xFB5D64-0xFB5E2C: per-controller resets.  Each stores a parameter number to (0x60F080), loops (0x60F081) over the
    # parts 0..31 with (0x60F082) / (0x60F083) fixed, and publishes each through T_Queue2C00_PublishStagedDrainPassB.  The
    # numbers are Dispatch_By_60F080's ParamMsg_Bx controllers.
    ("FB5D64", "GmReset_AllPartsPitchBend",
     "parameter 0xB1 (ParamMsg_B1...) for parts 0..31 with (0x60F082) / (0x60F083) = 0x00 / 0x40 -- the bend centre.  Called by GmMode_ApplyChange\n"
     "(GmMode_HandleChange's) after GmMode_ResetToDefaults."),
    ("FB5DC8", "GmReset_AllPartsModulation",
     "parameter 0xB2 (ParamMsg_B2...) for parts 0..31 with (0x60F082) / (0x60F083) = 0 / 0x7F.  Called by GmMode_ApplyChange\n"
     "(GmMode_HandleChange's) after GmMode_ResetToDefaults."),
    ("FB5DFA", "GmReset_AllPartsExpression",
     "parameter 0xB3 (ParamMsg_B3...) for parts 0..31 with (0x60F082) / (0x60F083) = 0x7F / 0x7F.  Called by GmMode_ApplyChange\n"
     "(GmMode_HandleChange's) after GmMode_ResetToDefaults."),
    ("FB5D96", "GmReset_AllPartsChannelPressure",
     "parameter 0xB4 (ParamMsg_B4...) for parts 0..31 with (0x60F082) / (0x60F083) = 0 / 0x7F.  Called by GmMode_ApplyChange\n"
     "(GmMode_HandleChange's) after GmMode_ResetToDefaults."),
    ("FB5E2C", "GmReset_AllPartsHold",
     "parameter 0xB5 (ParamMsg_B5...) for parts 0..31 with (0x60F082) / (0x60F083) = 0 / 0x7F.  Called by GmMode_ApplyChange\n"
     "(GmMode_HandleChange's) after GmMode_ResetToDefaults."),
    # prom_b 0xF1156B-0xF11C2F: sanitizing a DSP effect block (records 0x61..0x63)
    ("F1156B", "DspEffect_SanitizeBlock",
     "(block entry 0x61..0x63, block): H = block byte 0 (the algorithm, bit 7 cleared), looked up in that block's\n"
     "EffectAlgoToPos_Block97/98/99; byte 21 above 99 becomes 35, byte 23 above 1 becomes 0; an algorithm the block does\n"
     "not offer (0xFF) is replaced by 1 / 35 / 20 through DspEffect_CopyAlgorithmDefaults, otherwise DspEffect_RepairParams.\n"
     "Thunk T_DspEffect_SanitizeBlock; prom_a's ParamImage_SanitizeAll calls it on records 0x61 and 0x63."),
    ("F1162E", "DspEffect_CopyAlgorithmDefaults",
     "(algorithm word, block): byte 0 = the algorithm, then EffectDefaultParams[algorithm]'s record copied the way\n"
     "DspEffect_SetAlgorithm copies it -- +0 -> byte 22, +1..+4 -> bytes 17..20, values -> bytes 1..16 up to the first\n"
     "0xFF and zero after it -- but nothing is queued."),
    ("F11556", "DspEffect_CopyAlgorithmDefaults_Fwd",
     "pushes (block, algorithm byte zero-extended) and calls DspEffect_CopyAlgorithmDefaults.  Thunk slot T_DspEffect_CopyAlgorithmDefaults_Fwd; no caller found."),
    ("F114DA", "DspEffect_ApplyAlgorithmDefaults",
     "(block entry 0x61..0x63, algorithm): when the block's EffectAlgoToPos_BlockNN offers the algorithm,\n"
     "DspEffect_CopyAlgorithmDefaults into T_IndexedTable_GetPtr(block) and returns 0; otherwise returns 0xFFFF.  The\n"
     "unqueued twin of DspEffect_SetAlgorithm.  prom_a calls it (thunk T_DspEffect_ApplyAlgorithmDefaults) for blocks\n"
     "0x61 / 0x62 / 0x63 with the stored algorithm bytes (0x7642 / 0x7662 / 0x7682) at 0xFAAB8E, and with 1 / 0x23 / 0x14 --\n"
     "the fallbacks DspEffect_SanitizeBlock uses -- at 0xFB565D."),
    ("F116C4", "DspEffect_RepairParams",
     "(algorithm, block): DspEffect_CopyAlgorithmDefaults into a local copy, then for each EffectParamDescriptors_F12F24[algorithm]\n"
     "entry (type, offset) up to type 0xFF calls DspEffect_RepairValueTable[type](type, offset, block, defaults);\n"
     "then DspEffect_RepairEqBandFc (0, 17) / (1, 19) and DspEffect_RepairEqBandGain (0, 17) / (1, 19); finally byte 22\n"
     "must equal byte +3 of one of the algorithm's descriptors, or it gets the default's byte 22."),
    ("F11831", "DspEffect_RepairEqBandFc",
     "(which, offset 17 or 19, block, defaults): the Fc field (bits 6..10) of the word at block+offset must lie in\n"
     "0..min(Fc of +19, 22) for which = 0, max(Fc of +17, 8)..26 for which = 1 -- the band at +17 may not pass the band\n"
     "at +19; out of range, bytes 17..20 are copied from the defaults."),
    ("F118E2", "DspEffect_RepairEqBandGain",
     "(which, offset, block, defaults): the gain field (bits 0..5) of block+offset above 48 copies bytes 17..20 from\n"
     "the defaults.  The 0..48 range is EffectValueRanges type 5 (BAND EMPHASIS G)."),
    ("F1195A", "DspEffect_RepairU8",
     "DspEffect_RepairValueTable's entry for the byte types (1, 6..10, ...): the byte at block+offset outside\n"
     "EffectValueRanges[type] min..max (unsigned) is replaced by the defaults' byte."),
    ("F119A9", "DspEffect_RepairS8",
     "DspEffect_RepairU8 with a SIGNED compare (jr GT / GE): types 0x0C and 0x11, the slots DspEffect_StepS8 takes."),
    ("F119F8", "DspEffect_RepairU16",
     "the 16-bit types (0x14..0x16, 0x18, 0x1A..0x1C): the word at block+offset outside min..max is replaced by\n"
     "the defaults' two bytes."),
    ("F11A61", "DspEffect_RepairEqFc",
     "types 2 and 3 (EMPHASIS Fc): the field (word & 0x07C0) >> 6 outside min..max is replaced by the defaults' field."),
    ("F11AF3", "DspEffect_RepairEqQ",
     "type 4 (Q): the field (word & 0xF800) >> 11 outside min..max is replaced by the defaults' field."),
    ("F11B85", "DspEffect_RepairEqGain",
     "type 5 (G): the field word & 0x003F outside min..max is replaced by the defaults' field."),
    ("F11C10", "DspEffect_RepairSlowFast",
     "type 0x0B (SLOW/FAST): re-pushes its arguments and calls DspEffect_RepairU8."),
    # prom_b 0xF0F018-0xF0F060 and 0xF10252: the DSP EFFECT screen's section (FINDINGS-prom_b-dsp-effect-parameters.md 7.1)
    ("F0F018", "DspEffect_SetSection",
     "DspEffect_Section = the argument byte, DspEffect_SelectSectionBlock, then (0x2791) |= 0x80.  Thunk T_DspEffect_SetSection;\n"
     "called in-module by ScreenEnterBody_DspEffect."),
    ("F0F02B", "DspEffect_SetSectionAndRepaint",
     "the same as DspEffect_SetSection, plus UI_Request_Hi bit 4 (repaint the current screen in place,\n"
     "FINDINGS-prom_ab-screen-stage-and-flags.md).  Called by the ExitKey / LcdKeyRow2..4 _DspEffect arms."),
    ("F0F042", "DspEffect_GetSection",
     "`ld A,(DspEffect_Section) / ret`.  Thunk T_DspEffect_GetSection."),
    ("F0F047", "DspEffect_SelectSectionBlock",
     "when DspEffect_Section is not 0: Effect_BlockIndex = EffectPage_BlockIndex[DspEffect_Section] -- the block\n"
     "(0..2, IndexedTable entry 97 + it) the section edits."),
    ("F10252", "DspEffect_StepEqBandFc",
     "(which, offset 17 / 19): steps the Fc field (bits 6..10) of the EQ word at block+offset by 1, or 2 with\n"
     "PanelEvent_Flags bit 2, down with bit 0; limits max(Fc(+17), 8)..26 for the band at +19 (which = 1) or\n"
     "0..min(Fc(+19), 22) for the band at +17 (which = 0) -- the limits DspEffect_RepairEqBandFc checks.  Offsets 1 / 3 when UI_ScreenId is 0x6B.\n"
     "Called by SoftKeyCol2/5_DspEffect_EqSections."),
    # prom_b 0xF5BBE7-0xF5BEFA: the small-icon drawers (FINDINGS-image-files.md section 9)
    ("F5BCE8", "OctaveIcon_Draw",
     "at (IX, IY): one 28-pixel octave -- a service-0x09 box 28 x 12, six VLines (service 0x02) and the five\n"
     "OctaveIcon_BlackKeyX boxes.  Called seven times by KeyboardIcon_Draw."),
    ("F5BBE7", "KeyboardIcon_Draw",
     "seven OctaveIcon_Draw from (IconOrigin_X, IconOrigin_Y), IX + 28 each, then the closing key at +196..+200\n"
     "and two marks.  Called after IconOrigin_X/Y = (47, 51) by SoundEditToneLayerKeyLayer_Paint, (56, 139) by the KEY FOLLOW painters."),
    ("F5BE5A", "TouchCurve_DrawThumbnail",
     "curve = (XIZ) >> 5: 3 erases the box at IconOrigin + 1 (service 0x1B) and draws the diagonal (service 0x00,\n"
     "DrawLine); otherwise blits CurveBitmapSelector[curve], 40 x 40, at IconOrigin (service 0x03).  Also the filler\n"
     "entry of DispatchTable_F5B8F8 / F5B9F8 at the selectors with no page."),
    ("F5BDBB", "TouchCurve_DrawCurrentSlot",
     "IconOrigin = TouchCurve_BoxOrigins[(0x27A3)] (BoxOrigins3 when (0x27F5) is 1), TouchCurve_DrawThumbnail on\n"
     "ModelingPage_Fields+5 / +8 + (0x27A3), then the slot's TouchCurve_ListPtrs list.  Called by\n"
     "Draw_Page12LevelTouchCurveLevel and SoundEditAmpLevel1_RepaintField."),
    # prom_a 0xFF6906-0xFF74C3: the LOAD SINGLE SOUND / COMBINATION pages' shared key handlers.  Dispatch_FF4049 holds
    # L0adSingleS0und's two 32-slot pages, Dispatch_FF4151 L0adSingleC0mbination's (their ExitKey_ entries name them);
    # a routine in both, or in two key slots, was refused by notes/prom_ab_button_table_siblings.py and is read here.
    ("FF6906", "SoftKeyCol1_L0adSingle_AllPages",
     "slot 0 (and its held form 0x11) of all four pages of both screens: PanelDial_SetButtonPair(0, 0x80),\n"
     "UI_ScreenItem_StepByDial, Disk_FormatSelectedEntry_SaveRegs, then the string-table list DL_F5910F -- steps the\n"
     "selected disk file entry."),
    ("FF6BD2", "SoftKeyCols3_4_L0adSingleS0und_Page0",
     "slots 2 and 3 of L0adSingleS0und page 0: steps (0x2735) down (argument bit 7 set) or up within 0..0x7F, 0..1 when\n"
     "Var2728_Is2or3 (a drum bank), then L0adSingle_DrawBankAndNumber((0x2735))."),
    ("FF6F86", "SoftKeyCols3_4_L0adSingleC0mbination_Page0",
     "slots 2 and 3 of L0adSingleC0mbination page 0: the same step of (0x2735) within 0..0x7F, then\n"
     "L0adSingle_DrawBankAndNumber((0x2735))."),
    ("FF6C9E", "SoftKeyCol6_L0adSingle_Page0",
     "slot 5 of page 0 of both screens: steps (0x2737) within 0..15 (forced 0 for a drum bank), then the group's name and\n"
     "members -- L0adSingleS0und_DrawGroupName / _DrawGroupSounds when UI_ScreenLatch is 0x54, else the C0mbination pair."),
    ("FF6CF0", "SoftKeyCols7_8_L0adSingleS0und_Page0",
     "slots 6 and 7 of L0adSingleS0und page 0: steps (0x2738) within 0..T_SoundGroup_MaxMemberIndex_ByStack(bank\n"
     "Table_FF4039[(0x2736)], group (0x2737)) and redraws the member highlight (DL_F591A6 / DL_F591B1, source 0x2738)."),
    ("FF6FC0", "SoftKeyCols7_8_L0adSingleC0mbination_Page0",
     "the same as SoftKeyCols7_8_L0adSingleS0und_Page0 with T_CombiGroup_MaxMemberIndex_ByStack."),
    ("FF69B9", "SoftKeyCols3_4_L0adSingle_Page1",
     "slots 2 and 3 of page 1 of both screens: steps (0x2727) within 0..15 (0..0 for a drum bank) and shows it 1-based\n"
     "through (0x2730), the decimal readout of DL_F5910F's second record."),
    ("FF6A17", "SoftKeyCols5_6_L0adSingleS0und_Page1",
     "slots 4 and 5 of L0adSingleS0und page 1: (0x2736) = 0 / 1 (2 / 3 for a drum bank) by the argument's bit 7\n"
     "(the direction) -- USER 1 / USER 2 (/ USER1 DRUM / USER2 DRUM) in DLText_F59128 -- then redraws the (0x2736) string-table record at 0xF59100."),
    ("FF6A6C", "SoftKeyCols7_8_L0adSingle_Page1",
     "slots 6 and 7 of page 1 of both screens: moves the cursor row (0x2739, 0..7) and scrolls the list top (0x273A, up to 8)\n"
     "when the cursor is at an end; refused for a drum bank.  DL_F5915B is the row highlight (source 0x2739)."),
    ("FF7436", "L0adSingle_DrawBankAndNumber",
     "(n): Text_UserBankAbbrevs[(0x2728)]'s 4 characters, then n + 1 in 1..3 digits, drawn at 0x19A5.  Called by the\n"
     "SoftKeyCols3_4 page-0 handlers with (0x2735)."),
    ("FF7224", "L0adSingleS0und_DrawGroupName",
     "T_SoundGroupName_CopyToBuffer(bank Table_FF4039[(0x2736)], group (0x2737)) into 0x2940, drawn at 0x0C1E."),
    ("FF725D", "L0adSingleC0mbination_DrawGroupName",
     "the same with T_CombiGroupName_CopyToBuffer."),
    ("FF7296", "L0adSingleS0und_DrawGroupSounds",
     "eight lines from 0x0EEE, 0x208 apart: member k's name (T_SoundName_CopyToBuffer, bank Table_FF4039[(0x2736)],\n"
     "group (0x2737)) up to T_SoundGroup_MaxMemberIndex_ByStack, Text_FF4291 after it."),
    ("FF7399", "L0adSingleC0mbination_DrawGroupCombinations",
     "the same over a combination group (T_CombiGroup_MaxMemberIndex_ByStack)."),
    # prom_a 0xFC0BDA-0xFC1918: Msg0716_HandlerTables entries and the pending-part pass.  A part's object record (XIZ) holds
    # at +0 the address of its 8-byte RAM slot 0x0600 + 8n and at +4 its bit 1 << (n mod 16) (FINDINGS-prom_a-msg0716-module.md).
    ("FC0BDA", "Msg0716_PartSetProgramLow",
     "table 0 entry 0: the part's RAM slot +0 = UiEvent_Byte2; its bit ORed into (0x0700) (parts 0..15) or (0x0702)\n"
     "(16..31), and (0x070F) bit 0 set -- nothing is posted here.  The pending pass (Msg0716_FlushPending) later sends\n"
     "Msg0716_PartPostProgramChange, whose message carries the slot's +0..+1 word as the program number."),
    ("FC0BFD", "Msg0716_PartSetProgramHigh",
     "table 0 entry 1: the same as Msg0716_PartSetProgramLow for slot +1, the program number's high byte."),
    ("FC0C20", "Msg0716_PartSetVolume",
     "table 0 entry 3: the bits UiEvent_Byte3 selects of the slot's +6 are replaced by UiEvent_Byte2's, then +6 is\n"
     "posted as CC 7 (Msg0716_PostCC07_VolumeWithOffset for part 0, Msg0716_PostCC07_VolumeFromA otherwise)."),
    ("FC0C50", "Msg0716_PartPostCC40_Sustain",
     "table 0 entry 4: when UiEvent_Byte3 bit 3 is set and bit 0 of byte +0x2C of the part's 64-byte record\n"
     "(Msg0716_GetRecordPtrByIndex) is set, Msg0716_PostCC40_Sustain for the part."),
    ("FC0C8E", "Msg0716_PartPostCC0A_Pan",
     "table 0 entry 8: CC 10 for the part -- Msg0716_PostCC0A_PanWithOffset(UiEvent_Byte2 & 0x7F) for part 0, else Msg0716_PostCC0A_Pan."),
    ("FC0CC6", "Msg0716_PartPostCtrlInt9C",
     "table 0 entry 12: when UiEvent_Byte3 bit 3 is set, Msg0716_PostCtrlInt9C for the part."),
    ("FC0CE3", "Msg0716_PartPostCtrlInt9A",
     "table 1 entry 25: stores the part and calls Msg0716_PostCtrlInt9A, then falls into the `ret` at 0xFC0CEC."),
    ("FC0D12", "Msg0716_ScaleTuningPostTypeAndSemitones",
     "table 3 entry 0: Msg0716_PostSysEx50_86, then ScaleTuning_PostAllTwelveSemitones.  Table 3 is the scale-tuning\n"
     "page: its entries 2..13 are the twelve semitones (Msg0716_ScaleTuningPostSemitone)."),
    ("FC0D19", "Msg0716_ScaleTuningPostChangedFields",
     "table 3 entry 1: UiEvent_Byte3 (the changed bits) low nibble -> ScaleTuning_PostAllTwelveSemitones; bit 7 ->\n"
     "Msg0716_PostSysEx50_B1."),
    ("FC0D2F", "Msg0716_ScaleTuningPostSemitone",
     "table 3 entries 2..13: when the temperament (0x78A2) is 0x80, the user copy (ScaleTuning_PostAllTwelveSemitones' RAM arm),\n"
     "ScaleTuning_PostSemitoneFromUserRam(UiEvent_Byte1 - 2) -- semitone 0..11."),
    ("FC0E12", "Msg0716_PostCC07_VolumePart20",
     "table 7 entry 3: Msg0716_PostCC07_Volume with part byte 0x20, one past the 32 parts."),
    ("FC0E21", "Msg0716_RepostPart0Volume",
     "table 8 entry 18: Msg0716_PostCC07_VolumeWithOffset for part 0 with (0x0606), part 0's slot +6 -- the value\n"
     "Msg0716_PartSetVolume keeps there."),
    ("FC0E36", "Msg0716_RepostPart0Pan",
     "table 8 entry 19: Msg0716_PostCC0A_PanWithOffset for part 0 with (0x76AA) & 0x7F, byte +8 of part 0's 64-byte\n"
     "record 0x76A2."),
    ("FC1918", "Msg0716_PartPostProgramChange",
     "XIY = the part's RAM slot (object record +0), part byte = record +6, then Msg0716_PostProgramChange\n"
     "(C0 <part> <slot +0..+1> 00).  Called by the pending-part loops."),
    ("FC101E", "Msg0716_PartPostCC78_AllSoundOff",
     "unless (0x7F0B) bit 0, and -- when (0x070E) bit 5 or 6 is set -- only for parts above 7: Msg0716_PostCC78_AllSoundOff\n"
     "for the part.  Called by the pending-part loops before the program change."),
    ("FC0F4E", "Msg0716_FlushPendingParts0to15",
     "for each part 0..15 whose bit is set in (0x0700): Msg0716_PartPostCC78_AllSoundOff then Msg0716_PartPostProgramChange."),
    ("FC0F85", "Msg0716_FlushPendingParts16to31",
     "the same over (0x0702) and parts 16..31 (Msg0716_ObjectRecords + 0x80)."),
    ("FC0E6B", "Msg0716_FlushPending",
     "the (0x070E) group posts when it is non-zero, then Msg0716_FlushPendingParts0to15 / 16to31 for a non-zero (0x0700) /\n"
     "(0x0702) (after clearing those parts from (0x0706) / (0x0708)), two conditional extras, and finally clears\n"
     "0x0700..0x070E."),
    ("FC0E56", "Msg0716_FlushIfPending",
     "when (0x070F) bit 0 is set -- the bit every Msg0716_PartSetProgram* sets -- Msg0716_FlushPending and clear it; then\n"
     "(0x60F021) bit 5 is cleared."),
    # prom_a 0xFC0FC5-0xFC1B66: the (0x070E) block posts and link stream 3
    ("FC0FC5", "Msg0716_FlushPendingBlocks",
     "(0x070E) bit 4 -> Msg0716_PostOp87_Bytes78B3, bit 0 -> Msg0716_PostOp80_Byte7634, bits 1..3 ->\n"
     "Msg0716_PostOp81_EffectBlock97 / Op82_EffectBlock98 / Op83_EffectBlock99 -- the bits Msg0716_SetPendingBit0..4 set.\n"
     "Called first by Msg0716_FlushPending."),
    ("FC1A35", "Msg0716_PostOp80_Byte7634",
     "Msg0716_DefaultMessages record 0 (80 00 01), Msg0716_BiasOpcodeByMode, then the byte at 0x7634: 4 bytes on stream 1."),
    ("FC1A5D", "Msg0716_PostOp81_EffectBlock97",
     "record 1 (81 00 18), the opcode bias, then the 24 bytes at 0x7642 -- effect block 97's payload, the one\n"
     "ParamImage_SanitizeAll hands DspEffect_SanitizeBlock: 27 bytes on stream 1."),
    ("FC1A85", "Msg0716_PostOp82_EffectBlock98",
     "record 2 (82 00 18), then the 24 bytes at 0x7662, effect block 98: 27 bytes on stream 1."),
    ("FC1AAD", "Msg0716_PostOp83_EffectBlock99",
     "record 3 (83 00 18), then the 24 bytes at 0x7682, effect block 99: 27 bytes on stream 1."),
    ("FC1AD5", "Msg0716_PostOp87_Bytes78B3",
     "record 4 (87 00 04), no bias, then the 4 bytes at 0x78B3: 7 bytes on stream 1."),
    ("FC1B66", "Msg0716_PostFromXIX_Stream3",
     "Msg0716_PostFromXIX_Stream1 with stream word 3: push XIX / push BC / push 3 / T_Link_SendBlockIn32ByteChunks."),
    ("FC1B34", "Msg0716_PostStream3Op80",
     "80 <UiEvent_Byte2 & 0x0F>, 2 bytes, on stream 3."),
    ("FC1B4D", "Msg0716_PostStream3Op90",
     "90 <UiEvent_Byte2 & 0x7F>, 2 bytes, on stream 3."),
    ("FC0DC5", "Msg0716_PostStream3Op80IfChanged",
     "handler table 4 entry 0: Msg0716_PostStream3Op80 when UiEvent_Byte3 (the changed bits) & 0x0F."),
    ("FC0DD3", "Msg0716_PostStream3Op90IfChanged",
     "handler table 4 entry 2: Msg0716_PostStream3Op90 when UiEvent_Byte3 & 0x7F."),
    ("FC0FF3", "Msg0716_AllSoundOffParts0to7",
     "unless (0x7F0B) bit 0, and only when (0x070E) bit 5 or 6 is set: Msg0716_PostCC78_AllSoundOff for parts 0..7 --\n"
     "the parts Msg0716_PartPostCC78_AllSoundOff skips in that case.  Called last by Msg0716_FlushPending's group posts."),
    # prom_b 0xF4C4DD / 0xF4C6BF: the CREATOR SELECT CONTROLLER screen's six soft keys
    ("F4C4DD", "SoftKeyCols2to7_CreatorSelectController",
     "ScreenButtonHandlers_CreatorSelectController slots 1..6 (soft keys 2..7, button codes 1..6): v =\n"
     "CreatorSelect_ButtonCodeToBit(PanelEvent_ButtonCode); when (0x2870) is 0 / 1 and the part's IndexedTable entry\n"
     "0x20 + UI_PartIndex byte 26 / 25 & 0x3F differs from v, T_List2030_Append4(entry, 26 / 25, v, 0x3F) -- one key, one bit\n"
     "of the six."),
    ("F4C6BF", "CreatorSelect_ButtonCodeToBit",
     "(code): BitMask_F4C3E9[code], 0 for code above 8 -- 0, 1, 2, 4 ... 0x80."),
    # prom_b 0xF7B4BF-0xF7CB90: the remaining sequencer EDIT jobs' field machinery (MEASURE INSERT / COPY, QUANTIZE, ADVANCE/DELAY)
    ("F7B4BF", "MeasureInsert_InitFields",
     "Paint_MeasureInsert's stage-0 init (thunk T_MeasureInsert_InitFields): MeasureInsert_LoadSavedFields, MeasureInsert_Field = 1.  MEASURE INSERT: FROM TRACK / FIRST MEASURE / LAST MEASURE | TO TRACK / START MEASURE / REPEAT"),
    ("F7B852", "MeasureInsert_LoadSavedFields",
     "copies the job's saved fields from battery RAM 0x6034xx into the working cells and the display stage."),
    ("F7B53D", "MeasureInsert_StepFieldUp",
     "(0x0C4E) = W, (0x0C4F) = 0 (up), then field MeasureInsert_Field 1..6 -> MeasureInsert_StepFromTrack / MeasureInsert_StepFirstMeasure / MeasureInsert_StepLastMeasure / MeasureInsert_StepToTrack / MeasureInsert_StepStartMeasure / MeasureInsert_StepRepeat.  (field order: the page text, checked against each stepper's helper; notes/prom_b_seqjob_field_names.py for the pattern)"),
    ("F7B58C", "MeasureInsert_StepFieldDown",
     "the same with (0x0C4F) = 0x80 (down)."),
    ("F7B5F5", "MeasureInsert_StepFromTrack",
     "field 1 of the page; steps with SeqJob_StepTrack."),
    ("F7B65E", "MeasureInsert_StepFirstMeasure",
     "field 2 of the page; steps with SeqJob_StepMeasure."),
    ("F7B694", "MeasureInsert_StepLastMeasure",
     "field 3 of the page; steps with SeqJob_StepMeasure."),
    ("F7B6CE", "MeasureInsert_StepToTrack",
     "field 4 of the page; steps with SeqJob_StepTrack."),
    ("F7B737", "MeasureInsert_StepStartMeasure",
     "field 5 of the page; steps with SeqJob_StepMeasure."),
    ("F7B74C", "MeasureInsert_StepRepeat",
     "field 6 of the page; steps with sub_F7CCDB, 0..127."),
    ("F7B8DC", "MeasureC0py_InitFields",
     "Paint_MeasureC0py's stage-0 init (thunk T_MeasureC0py_InitFields): MeasureC0py_LoadSavedFields, MeasureC0py_Field = 1.  MEASURE C0PY: the same six fields"),
    ("F7BC73", "MeasureC0py_LoadSavedFields",
     "copies the job's saved fields from battery RAM 0x6034xx into the working cells and the display stage."),
    ("F7B95A", "MeasureC0py_StepFieldUp",
     "(0x0C4E) = W, (0x0C4F) = 0 (up), then field MeasureC0py_Field 1..6 -> MeasureC0py_StepFromTrack / MeasureC0py_StepFirstMeasure / MeasureC0py_StepLastMeasure / MeasureC0py_StepToTrack / MeasureC0py_StepStartMeasure / MeasureC0py_StepRepeat.  (field order: the page text, checked against each stepper's helper; notes/prom_b_seqjob_field_names.py for the pattern)"),
    ("F7B9AB", "MeasureC0py_StepFieldDown",
     "the same with (0x0C4F) = 0x80 (down)."),
    ("F7BA16", "MeasureC0py_StepFromTrack",
     "field 1 of the page; steps with SeqJob_StepTrack."),
    ("F7BA7F", "MeasureC0py_StepFirstMeasure",
     "field 2 of the page; steps with SeqJob_StepMeasure."),
    ("F7BAB5", "MeasureC0py_StepLastMeasure",
     "field 3 of the page; steps with SeqJob_StepMeasure."),
    ("F7BAEF", "MeasureC0py_StepToTrack",
     "field 4 of the page; steps with SeqJob_StepTrack."),
    ("F7BB58", "MeasureC0py_StepStartMeasure",
     "field 5 of the page; steps with SeqJob_StepMeasure."),
    ("F7BB6D", "MeasureC0py_StepRepeat",
     "field 6 of the page; steps with sub_F7CCDB, 0..127."),
    ("F7BFEA", "Quantize_InitFields",
     "Paint_Quantize's stage-0 init (thunk T_Quantize_InitFields): copies the saved fields from battery RAM 0x603477.. into the working cells."),
    ("F7C0F1", "Quantize_StepFieldUp",
     "at stage 1 leaves through Quantize_ReturnToStageZero; else (0x0C4F) = 0 (up) and field (0x0DB9) 1..6 -> Quantize_StepTrack / _StepFirstMeasure / _StepLastMeasure / _StepValue / _StepStrength / _StepWindow.  (field order: the page text, checked against each stepper's helper; notes/prom_b_seqjob_field_names.py for the pattern)"),
    ("F7C17D", "Quantize_StepFieldDown",
     "the same with (0x0C4F) = 0x80 (down)."),
    ("F7C13E", "Quantize_ReturnToStageZero",
     "writes the track / measure cells back to battery RAM 0x603477.., then UI_ScreenStage = 0 and UI_Request_Hi |= 0x10 -- the stage-1 exit of Quantize_StepFieldUp."),
    ("F7C1C1", "Quantize_StepTrack",
     "field 1: SeqJob_StepTrack17."),
    ("F7C20B", "Quantize_StepFirstMeasure",
     "field 2: SeqJob_StepMeasure, stage +1."),
    ("F7C242", "Quantize_StepLastMeasure",
     "field 3: SeqJob_StepMeasure, stage +3."),
    ("F7C27C", "Quantize_StepValue",
     "field 4: (0x0C37) 0..6, stage +5 -- the VALUE caption's string-table readout in DL_TrackValueFirstMeasureLastMeasureStrengthWindow."),
    ("F7C2AB", "Quantize_StepStrength",
     "field 5: (0x0E04) 0..100, stage +6 -- the STRENGTH caption's unsigned readout."),
    ("F7C2D3", "Quantize_StepWindow",
     "field 6: (0x0E05) -100..100 -- the WINDOW caption's SIGNED readout (stage +7)."),
    ("F7CAD2", "AdvanceDelay_InitFields",
     "Paint_AdvanceDelay's init (thunk T_AdvanceDelay_InitFields): unless the previous screen was 0x2C, copies the working cells to the display stage and sets AdvanceDelay_Field = 1."),
    ("F7CB4A", "AdvanceDelay_StepFieldUp",
     "(0x0C4E) = W, (0x0C4F) = 0 (up), then field AdvanceDelay_Field 1..4 through the SongStore_DispatchC_1 table."),
    ("F7CB90", "AdvanceDelay_StepFieldDown",
     "the same with (0x0C4F) = 0x80 (down)."),
    # prom_b 0xF71B82-0xF72F20: the SMF reader's MULTI-TRACK path.  Smf_ReadFile reads format 0, or a one-track file, itself
    # with the SmfEvent_* handlers at 0xF6FExx; for format 1 with Smf_TrackCount != 1 it calls Smf_ReadMultiTrack (0xF6F637).
    ("F71B82", "Smf_ReadMultiTrack",
     "Smf_ReadFile's branch for format 1 with more than one track (cp (Smf_Format),1 / cp (Smf_TrackCount),1 at 0xF6F626):\n"
     "  for track (0x11B2) = 0 .. Smf_TrackCount-1, Smf_ReadTrackChunk and sub_F729D9; then sub_F72F5C."),
    ("F71BEA", "Smf_ReadTrackChunk",
     "one MTrk chunk of the multi-track path: compares the 4 tag bytes at SmfTrackTag (UI_StatusCode 49 on a mismatch), reads the\n"
     "  length into SmfOut_TrackLength, then loops delta (Smf_ReadVlqBytes_Copy / Smf_DecodeVlq) and event: 0xFF SmfEvent_Meta,\n"
     "  0xF0 / 0xF7 SmfEvent_SysEx, running status SmfEvent_ReadWithRunningStatus, new status SmfEvent_ReadWithNewStatus_MultiTrack."),
    ("F71D71", "SmfEvent_ReadWithNewStatus_MultiTrack",
     "the multi-track copy of SmfEvent_ReadWithNewStatus: Smf_RunningStatus = A, one data byte for 0xC0 / 0xD0 and two\n"
     "  otherwise, then SmfEvent_DispatchChannelMessage_MultiTrack."),
    ("F71DB7", "SmfEvent_DispatchChannelMessage_MultiTrack",
     "the multi-track copy of SmfEvent_DispatchChannelMessage: by status 0x90 (velocity 0 -> note off), 0x80, 0xB0,\n"
     "  0xE0, 0xC0, 0xD0 to the *_MultiTrack handlers."),
    ("F7208D", "SmfEvent_NoteOn_MultiTrack",
     "SmfEvent_DispatchChannelMessage_MultiTrack's arm for status 0x90 with a non-zero velocity."),
    ("F721A3", "SmfEvent_NoteOff_MultiTrack",
     "SmfEvent_DispatchChannelMessage_MultiTrack's arm for status 0x80, and 0x90 with velocity 0."),
    ("F7222D", "SmfEvent_ControlChange_MultiTrack",
     "SmfEvent_DispatchChannelMessage_MultiTrack's arm for status 0xB0."),
    ("F72754", "SmfEvent_PitchBend_MultiTrack",
     "SmfEvent_DispatchChannelMessage_MultiTrack's arm for status 0xE0."),
    ("F71E89", "SmfEvent_ProgramChange_MultiTrack",
     "SmfEvent_DispatchChannelMessage_MultiTrack's arm for status 0xC0."),
    ("F71E21", "SmfEvent_ChannelPressure_MultiTrack",
     "SmfEvent_DispatchChannelMessage_MultiTrack's arm for status 0xD0; writes 0xA0 | channel, the time and the value into the block store."),
    ("F727C8", "BStore_LoadTrackCursor",
     "BStore_CursorBlock / BStore_CursorOffset = the saved cursor of slot Smf_TrackToSlot((0x11B2)): word 0x3460[slot], byte\n"
     "  0x3482[slot].  Called before each multi-track event write; BStore_SaveTrackCursor after it."),
    ("F727F6", "BStore_SaveTrackCursor",
     "stores BStore_CursorBlock / BStore_CursorOffset back into 0x3460[slot] / 0x3482[slot]."),
    ("F728FE", "Smf_TrackToSlot",
     "IY = min(IY, 1), zero-extended: every source track above 1 shares slot 1.  Followed by four unreferenced one-call stubs."),
    ("F72F20", "Smf_BusyDelay",
     "3072 x 960 empty djnz16 iterations.  Called by Smf_ReadFile and Smf_WriteFile."),
    # prom_b 0xF72364-0xF726A2: the multi-track path's control-change handlers.  SmfEvent_ControlChange_MultiTrack indexes
    # SmfCC_HandlersByNumber_MultiTrack by the CC number for CC < 16 -- its entries 2 and 4 are the shared SmfCC_Breath / SmfCC_Foot, CC 2 and 4 --
    # and compares CC >= 16 one by one; each copy is named after its format-0 twin (MIDI 1.0 numbers).
    ("F72364", "SmfCC_BankSelectMsb_MultiTrack",
     "SmfEvent_ControlChange_MultiTrack's SmfCC_HandlersByNumber_MultiTrack[0], CC 0 -- the multi-track copy of SmfCC_BankSelectMsb."),
    ("F7237D", "SmfCC_Modulation_MultiTrack",
     "SmfEvent_ControlChange_MultiTrack's SmfCC_HandlersByNumber_MultiTrack[1], CC 1 -- the multi-track copy of SmfCC_Modulation."),
    ("F723E1", "SmfCC_DataEntryMsb_MultiTrack",
     "SmfEvent_ControlChange_MultiTrack's SmfCC_HandlersByNumber_MultiTrack[6], CC 6 -- the multi-track copy of SmfCC_DataEntryMsb."),
    ("F724A7", "SmfCC_Volume_MultiTrack",
     "SmfEvent_ControlChange_MultiTrack's SmfCC_HandlersByNumber_MultiTrack[7], CC 7 -- the multi-track copy of SmfCC_Volume."),
    ("F724CB", "SmfCC_Pan_MultiTrack",
     "SmfEvent_ControlChange_MultiTrack's SmfCC_HandlersByNumber_MultiTrack[10], CC 10 -- the multi-track copy of SmfCC_Pan."),
    ("F725D9", "SmfCC_BankSelectLsb_MultiTrack",
     "SmfEvent_ControlChange_MultiTrack's `cp A,32` arm, CC 32 -- the multi-track copy of SmfCC_BankSelectLsb."),
    ("F7243B", "SmfCC_DataEntryLsb_MultiTrack",
     "SmfEvent_ControlChange_MultiTrack's `cp A,38` arm, CC 38 -- the multi-track copy of SmfCC_DataEntryLsb."),
    ("F7263A", "SmfCC_Effect1Depth_MultiTrack",
     "SmfEvent_ControlChange_MultiTrack's `cp A,91` arm, CC 91 -- the multi-track copy of SmfCC_Effect1Depth."),
    ("F7267E", "SmfCC_Effect3Depth_MultiTrack",
     "SmfEvent_ControlChange_MultiTrack's `cp A,93` arm, CC 93 -- the multi-track copy of SmfCC_Effect3Depth."),
    ("F726A2", "SmfCC_Effect4Depth_MultiTrack",
     "SmfEvent_ControlChange_MultiTrack's `cp A,94` arm, CC 94 -- the multi-track copy of SmfCC_Effect4Depth."),
    # the part SOUND stepper and the MAIN OUT / SUB OUT steppers (PartParamStep_Ids00to1F[0], PartParamStep_Ids20to3F[0] / [1])
    ("F4F02E", "PartSound_StepBankGroupMember",
     "loads part E's sound from its record -- +0x3D bank, +0x3B group, +0x3C member, SoundGroup_LoadSelectionFromPart's\n"
     "offsets -- into 0x2761 / 0x2762 / 0x2763 and steps it like an odometer, one step in the direction of\n"
     "PanelEvent_Flags bit 0 (set = down).  The member steps first (PartSound_StepIndexClamped, bounded by\n"
     "SoundGroup_MaxMemberIndex_Get); when it cannot move, the group; when that cannot move, the bank, through\n"
     "PartSound_BankOrder.  The levels below the one that moved restart at 0 when stepping up and at their\n"
     "maximum when stepping down (`bit 7,W` arms, 0xF4F155 / 0xF4F1DF).\n"
     "The result is posted for part E as two List2030_AppendRegs records, (bank, bank) and (group, member).\n"
     "Called by PartParam_StepSound."),
    ("F4F27E", "PartSound_StepIndexClamped",
     "DE += PartSound_SignedStepTable[W'], where W' = W bits 0-2 (the size) plus W bit 7 moved to bit 3 (the sign;\n"
     "entries 8-15 are 0, -1 .. -7).  A result that goes negative becomes 0.  It is then clamped to IY..IX.\n"
     "Called three times by PartSound_StepBankGroupMember, which compares DE before and after to see whether the\n"
     "level could move."),
    ("FBBCBC", "PartParam_StepMainOut",
     "PartParamStep_Ids20to3F[0].  Steps byte 3 of part record E+0x20 (MAIN OUT: SysEx rec 32, offset 3) through T_EditValue_StepBitField\n"
     "(EditValue_StepBitField) with PartParamField_MainOut.  If it moved, the new value is kept only when EFFECT2 is\n"
     "off (byte 6 of record E, bit 7 masked, is 0), SUB OUT (byte 4 of E+0x20) is 0, or the new value is 0.\n"
     "Otherwise it sets UI_Request_Hi bit 6 and UI_Request = 0xB6 instead.  So with EFFECT2 on, a part cannot\n"
     "go to MAIN and SUB OUT at once.  A kept value is written back and posted to Queue2C00 (E+0x20, offset 3)."),
    # the part-parameter field dispatchers (notes/prom_ab_part_param_fields.py, _switches.py)
    ("FBB800", "PartParam_StepFieldById",
     "(field id H = (XIZ+8), part L = (XIZ+10)): the high nibble of H, in pairs, picks the step table -- ids\n"
     "0x00-0x1F PartParamStep_Ids00to1F, 0x20-0x3F PartParamStep_Ids20to3F at H-0x20, ... 0xA0-0xBF PartParamStep_IdsA0toBF; 0xC0 and up\n"
     "do nothing -- and calls the entry with the part.  Called by the COMBINATION EDIT INTERNAL SOUND / CONFIGURE\n"
     "soft keys and T_PartParam_StepFieldById."),
    ("FBB93C", "PartParam_EnterFieldById",
     "PartParam_StepFieldById's number-pad twin over PartParamEnter_Ids00to1F .. PartParamEnter_IdsA0toBF, the same id ranges.\n"
     "Called by NumberPadKey_CombiEditInternalSound and T_PartParam_EnterFieldById."),
    # the sequencer's file module, prom_a 0xFBAC00-0xFBB42E (FINDINGS-prom_b-disk-and-file-menus.md, SQF / SEQ)
    ("FBAC00", "SeqFile_Load",
     "DiskLoad_Sequencer's body (T_SeqFile_Load, through SeqFile_Load_SaveRegs).  SeqFile_ProbeSqfHeader: 1 -> SeqFile_LoadAllBanks;\n"
     "0 -> one song into bank Disk_SeqBank.  The workspace 0x603400 goes to its bank copy, the free chain is stashed,\n"
     "bank Disk_SeqBank's copy becomes the workspace and BStore_CurrentBank, and the SQF is read over it\n"
     "(Disk_LoadSqfToWorkspace_Entry).  If its blocks ((0x603452) >> 4) fit in the stashed free count (else result\n"
     "0x1E), they are read after the free head and relocated (SeqFile_LoadSongBlocks).  Result -> (0x23CB)."),
    ("FBB199", "SeqFile_ProbeSqfHeader",
     "reads the SQF's first 0x600 bytes to 0x609400.  A = 1 when word +5 is 4 and byte +4 is 1 (all banks:\n"
     "SeqFile_SaveAllBanks writes +4 = 1), 0 when word +5 is 4 otherwise, 2 when the read fails (result = the\n"
     "error, or 1 for content type ALL), 3 when word +5 is not 4 (result 0x10)."),
    ("FBB20B", "SeqFile_LoadAllBanks",
     "reads the SQF as 0x7800 bytes into the ten bank copies at 0x610000 (10 x 0xC00), clears the all-banks flag\n"
     "(0x610004), copies the current bank's copy into the workspace, and reads the SEQ into the heap from 0x617800,\n"
     "(0x603452) x 16 bytes -- or, for an empty store ((0x603452) = 0), sets the free head to 1 and\n"
     "BStore_RebuildFreeChain.  Result -> (0x23CB)."),
    ("FBAD07", "SeqFile_LoadSongBlocks",
     "reads the SEQ with BStore_HeapBase moved to the free head's block (BStore_FreeHeadBlockAddr), restores the\n"
     "base, then adds FreeHead-1 (BStore_FreeHeadIndex) to every block number the song holds: the 17 directory\n"
     "start blocks (0x603501, stride 3), the 17 words at 0x60347E, and each loaded block's previous / next links\n"
     "(BStore_RelocateBlockNumber); then BStore_RebuildFreeChain."),
    ("FBAD82", "BStore_RebuildFreeChain",
     "BStore_FreeHead += the loaded block count ((0x603452) >> 4), or 0xFFFF past BStore_BlockCount;\n"
     "BStore_FreeCount = BlockCount - FreeHead + 1; when any are free, blocks FreeHead .. BlockCount are linked as a\n"
     "free chain (BStore_InitFreeBlock) and the last one's next is 0xFFFF."),
    ("FBAE10", "BStore_InitFreeBlock",
     "block XIX, number WA: flags +0 = 0 (free), payload tag +5 = 0x82, previous = WA-1 (0 for 0), next = WA+1."),
    ("FBAE2A", "BStore_FreeHeadBlockAddr",
     "XIX = 0x617800 + (BStore_FreeHead - 1) x 0x100 (BStore_FreeHeadIndex), the free head's block."),
    ("FBAE3B", "BStore_FreeHeadIndex",
     "WA = BStore_FreeHead - 1, or 0 when it is 0: the number of blocks before the free head."),
    ("FBAE49", "BStore_RelocateBlockNumber",
     "adds WA to the word at (XIX) unless it is 0 or 0xFFFF (no block / end of chain)."),
    ("FBADEA", "BStore_StashFreeChain",
     "BStore_FreeHead / BStore_FreeCount -- workspace words, so per bank -- to (0x23B8) / (0x23BA), before\n"
     "SeqFile_Load swaps the workspace."),
    ("FBADFD", "BStore_UnstashFreeChain",
     "(0x23B8) / (0x23BA) back to BStore_FreeHead / BStore_FreeCount: the shared heap's free chain carried into\n"
     "the new bank's workspace."),
    ("FBB135", "BStore_BlockAddr",
     "XIX = 0x617800 + (WA - 1) x 0x100 for the 1-based block number WA -- BStore_SeekBlock's arithmetic with the\n"
     "heap base as a literal."),
    ("FBB0C3", "BStore_CurrentBankCopyAddr",
     "XIX = 0x610000 + BStore_CurrentBank x 0xC00, the current bank's copy of the workspace."),
    ("FBB0D6", "BStore_DiskBankCopyAddr",
     "XIY = 0x610000 + Disk_SeqBank x 0xC00, the copy of the bank the disk screen selected."),
    ("FBAE5A", "SeqFile_Save",
     "DiskSave_Sequencer's body (T_SeqFile_Save, through SeqFile_Save_SaveRegs).  Content type ALL -> SeqFile_SaveAllBanks.\n"
     "Otherwise: workspace -> its bank copy; bank Disk_SeqBank's copy -> staging 0x609400, all-banks flag +4 = 0;\n"
     "each in-use directory entry's chain (+0x100, stride 3, bit 7) is counted and renumbered from 1 in order, the\n"
     "running total stored at +0x7E + 2k and x 16 at +0x52; the SQF is written (Disk_SaveSqfFromStaging_Entry);\n"
     "then, if (total, or 4) x 16 paragraphs fit on the disk (result 7 if not), SeqFile_WriteSeqCompacted."),
    ("FBB2D5", "SeqFile_SaveAllBanks",
     "needs 0x780 + (0x603452) paragraphs of disk (result 7 if short); workspace -> its bank copy; all-banks flag\n"
     "(0x610004) = 1; writes the ten bank copies as the SQF (0x610000-0x617800), then the SEQ from 0x617800,\n"
     "(0x603452) x 16 bytes, or SeqFile_WriteEmptySeq when that is 0; clears the flag."),
    ("FBAF42", "SeqFile_WriteSeqCompacted",
     "walks bank Disk_SeqBank's 17 directory chains block by block, copying each into a 4-block staging buffer at\n"
     "0x609400 (SeqFile_StageBlock) with its links renumbered (SeqFile_RelinkStagedBlock); every 4 blocks and at\n"
     "the end SeqFile_FlushStagingBlocks, then T_DiskApi_CloseFile_Call.  An empty store: SeqFile_WriteEmptySeq."),
    ("FBB04F", "SeqFile_FlushStagingBlocks",
     "writes the staging buffer: the first time ((0x23CC) = 0) after SeqFile_SetSeqStagingWindow with Disk_Flags\n"
     "bit 5 set, later times with bit 1 set; (0x23CC) += 1."),
    ("FBB07E", "SeqFile_WriteEmptySeq",
     "four staging blocks cleared (SeqFile_ClearStagingBlockFlags) and linked (SeqFile_LinkStagingBlocks), written\n"
     "as a 0x400-byte SEQ file."),
    ("FBB0A1", "SeqFile_SetSeqStagingWindow",
     "Disk_WindowStart / End = 0x609400 / 0x6097FF (four blocks), extension SEQ."),
    ("FBB0E9", "SeqFile_ClearStagingBlockFlags",
     "flags byte +0 = 0 in the four staging blocks at 0x609400."),
    ("FBB0FF", "SeqFile_LinkStagingBlocks",
     "staging block k (0..3): previous = k, next = k+2 -- the links of block k+1 of a 1-based chain."),
    ("FBB11F", "SeqFile_StageBlock",
     "copies block (0x23C6) (BStore_BlockAddr) into staging slot (0x23C8) (SeqFile_StagingSlotAddr), 0x100 bytes."),
    ("FBB146", "SeqFile_StagingSlotAddr",
     "XIX = 0x609400 + (0x23C8) x 0x100."),
    ("FBB159", "SeqFile_RelinkStagedBlock",
     "the staged block becomes number (0x23C4): previous = 0 when it opens a chain ((0x23CA) bit 0), else\n"
     "number-1; next = 0xFFFF when it closes one (bit 1), else number+1; (0x23C4) += 1."),
    # the disk module's side of it
    ("FE237B", "Disk_LoadSqfToWorkspace",
     "extension SQF, window 0x603400-0x604000 (Disk_SetWindowStartToWorkspace / _EndToWorkspaceEnd),\n"
     "DiskApi_ReadFileToWindow; on success ParamImageAlt_SanitizeCombination_Entry_SaveRegs and Disk_LastError = 1."),
    ("FE233A", "Disk_LoadSeqToHeap",
     "extension SEQ, window BStore_HeapBase .. + (0x603452) x 16 (Disk_SetWindowStartToHeap,\n"
     "Disk_SetSeqLengthFromWorkspace, Disk_SetWindowEndToHeapPlusSeqLength), DiskApi_ReadFileToWindow."),
    ("FE2CC7", "Disk_SaveSqfFromStaging",
     "extension SQF, window 0x609400-0x60A000 (one bank copy, staged by SeqFile_Save), Disk_Flags bits 5 and 1\n"
     "cleared, DiskApi_WriteFileFromWindow."),
    ("FE2C64", "Disk_SaveSeqFile",
     "(0x761A) = (0x603452); DiskApi_CheckFreeSpace for that many paragraphs; with room: extension SEQ, window\n"
     "0x609000 .. BStore_HeapBase + (0x603452) x 16, DiskApi_WriteFileFromWindow.  No call of its entry T_Disk_SaveSeqFile_Entry\n"
     "is decoded in prom_a or prom_b; SeqFile_Save writes the SEQ through SeqFile_WriteSeqCompacted."),
    ("FE1BEB", "Disk_LoadSqfToWorkspace_Entry",
     "the directory entry behind T_Disk_LoadSqfToWorkspace_Entry: Disk_LoadSqfToWorkspace, A -> Disk_LastError.  Called by SeqFile_Load."),
    ("FE1BF3", "Disk_LoadSeqToHeap_Entry",
     "behind T_Disk_LoadSeqToHeap_Entry: Disk_LoadSeqToHeap, A -> Disk_LastError.  Called by SeqFile_LoadSongBlocks."),
    ("FE1BFB", "Disk_SaveSqfFromStaging_Entry",
     "behind T_Disk_SaveSqfFromStaging_Entry: Disk_SaveSqfFromStaging, A -> Disk_LastError.  Called by SeqFile_Save."),
    ("FE1C03", "Disk_SaveSeqFile_Entry",
     "behind T_Disk_SaveSeqFile_Entry: Disk_SaveSeqFile, A -> Disk_LastError."),
    ("FE2D30", "Disk_SetWindowStartToWorkspace", "Disk_WindowStart = 0x603400, the sequencer workspace."),
    ("FE2D9D", "Disk_SetWindowEndToWorkspaceEnd", "Disk_WindowEnd = 0x604000."),
    ("FE2D1D", "Disk_SetWindowStartToHeap", "Disk_WindowStart = BStore_HeapBase."),
    ("FE2DC6", "Disk_SetSeqLengthFromWorkspace",
     "(0x761A) = (0x603452), the song store's length in 16-byte units."),
    ("FE2DA7", "Disk_SetWindowEndToHeapPlusSeqLength", "Disk_WindowEnd = BStore_HeapBase + (0x761A) x 16."),
    ("FE2D26", "Disk_SetWindowStartToSqfStaging", "Disk_WindowStart = 0x609400, SeqFile_Save's one-bank staging copy."),
    ("FE2D93", "Disk_SetWindowEndToSqfStagingEnd", "Disk_WindowEnd = 0x60A000."),
    # the DISK SAVE FILE flow and the save password (FINDINGS-prom_b-disk-and-file-menus.md, DISK SAVE PASSWORD)
    ("FE1C80", "DiskSaveFile_Execute_Entry",
     "the directory entry behind T_DiskSaveFile_Execute_Entry (LcdKeyRow1_DiskSaveFile_Page1, LcdKeyRow3_DiskSaveFile_Page2,\n"
     "Smf_WriteFile): status 5; on page 2 (the overwrite question) DiskSaveFile_SaveNow, else\n"
     "DiskSaveFile_CheckDriveThenPassword; Ring_InitTenOfFourteen."),
    ("FE05EC", "DiskSaveFile_CheckDriveThenPassword",
     "Disk_RequestSenseDriveStatus: 0x2F -> status 0x0C, other non-zero -> 8, each shown with a delay and back to\n"
     "page 1.  Ready: DiskSave_IsBankPasswordSet -> (0x1735); set -> DiskSaveFile_AskForPassword, else\n"
     "DiskSaveFile_SaveOrConfirmOverwrite."),
    ("FE0648", "DiskSaveFile_SaveOrConfirmOverwrite",
     "during an SMF write ((0x21E8) bit 7) DiskSaveFile_SaveNow; otherwise DiskSave_IsSelectedFileNew: new ->\n"
     "DiskSaveFile_SaveNow, existing -> page 2 (the overwrite question).  Repaint bit 4."),
    ("FE066C", "DiskSaveFile_SaveNow",
     "Disk_RequestSenseDriveStatus (failure: status 8 / 0 / 0x0C and a delay); ready: status 0x0B,\n"
     "Var2216_SetW145C, DiskSave_StorePasswordInWorkspace, DiskSave_ByContentType, DiskSave_ShowResult(result);\n"
     "then screen request 1 when UI_StatusCode is 0x23, else page 0."),
    ("FE06EA", "DiskSave_StorePasswordInWorkspace",
     "when (0x220C) -- the page-1 SoftKeyCol4 count that opened the password page -- is at least 6:\n"
     "(0x60341C) = (0x2210) << 8 | (0x220F), the two characters page 3 took from the entry buffer 0x22F0."),
    ("FE070C", "DiskSave_ShowResult",
     "(result): 3 -> status 3, Delay_500Ticks, (0x220F) = (0x220C) = 0 (the entered password is spent); else\n"
     "status 7 for 7 and 6 for anything else, sub_FE1907 and, outside an SMF write, a delay.  Returns the result."),
    ("FE0811", "DiskSave_IsBankPasswordSet",
     "unless (0x21FA) is 3: on screen 0x4E or for content type SEQUENCER, the password of bank Disk_SeqBank\n"
     "(BStore_GetDiskBankPassword via BStore_GetDiskBankPassword_SaveRegs); for ALL, the first set one of any bank\n"
     "(BStore_GetAnyBankPassword via BStore_GetAnyBankPassword_SaveRegs).  0xFE when the word in (0x23CE) is non-zero, else 0."),
    ("FE085B", "DiskSaveFile_AskForPassword",
     "(0x222A) = 0xFA, NameEdit_CursorPos = 0, page 4 -- ScreenEnter_DiskSaveFile_Page4 draws\n"
     "DL_DiskSavePasswordSave and DL_PasswordIsAlreadySetPleaseSetThe."),
    ("FE0870", "DiskSave_IsSelectedFileNew",
     "the 8 bytes at 0x60A488 + 16 x (0x2724) -- the selected listing slot -- all 0x80: Disk_LastError = 0,\n"
     "A = 0; any other byte: 0xFE (a file is there)."),
    ("FE07E0", "DiskSaveFile_CheckPasswordThenSave",
     "the directory entry T_DiskSaveFile_CheckPasswordThenSave_Call's body, page 4's LcdKeyRow1: DiskSave_ComparePassword; mismatch -> status 0x11,\n"
     "delay, page 1; match -> status 0x12, Delay_500Ticks, DiskSaveFile_SaveOrConfirmOverwrite."),
    ("FE0785", "DiskSave_ComparePassword",
     "the entered (0x2210) << 8 | (0x220F) against (0x23CE) -- bank Disk_SeqBank's password for SEQUENCER\n"
     "(BStore_GetDiskBankPassword_SaveRegs), any bank's for ALL (BStore_GetAnyBankPassword_SaveRegs); other content types pass.  0 = match, 0xFE = mismatch."),
    ("FBB392", "BStore_GetDiskBankPassword",
     "gathers word +0x1C of the ten bank copies (0x61001C + n x 0xC00) into 0x60A000[n], the live workspace's\n"
     "(0x60341C) for the current bank, and returns bank Disk_SeqBank's in (0x23CE).  Thunk T_BStore_GetDiskBankPassword."),
    ("FBB3DC", "BStore_GetAnyBankPassword",
     "the same gathering, then (0x23CE) = the first non-zero of the ten, or 0.  Thunk T_BStore_GetAnyBankPassword."),
    ("F441AB", "BStore_ClearPasswordProtectedBanks",
     "BStore_BootPhase3's: saves the workspace to its bank, then for banks 0..9 (BStore_MoveWorkspaceToNextBank)\n"
     "runs SongClear_ClearCurrentBank wherever the password word (0x60341C) is non-zero, and zeroes it; then\n"
     "restores the current bank."),
    ("F64BB6", "BStore_MoveWorkspaceToNextBank",
     "(0x0E2B) / (0x0E2D) = BStore_FreeHead / FreeCount; unless BStore_CurrentBank is 0 the workspace goes back\n"
     "to bank CurrentBank-1 (BStore_Workspace_SaveToBank); then bank CurrentBank is loaded\n"
     "(BStore_Workspace_LoadFromBank).  Thunk T_BStore_MoveWorkspaceToNextBank, called by BStore_ClearPasswordProtectedBanks."),
    ("F608D0", "SongClear_ClearBank",
     "the SONG CLEAR job's action (SongClear_LcdKeyRow4, through T_SongClear_ClearBank) on bank (0x0E02), 10 = all of them\n"
     "(sub_F610E3): sub_F60F4F, then in the bank copy the password word +0x1C = 0 and every directory entry's bit\n"
     "7 cleared and start block 0xFFFF."),
    ("F60B0C", "SongClear_ClearCurrentBank",
     "SongClear_ClearBank with (0x0E02) = BStore_CurrentBank, the old value restored.  Thunk T_SongClear_ClearCurrentBank, called by\n"
     "BStore_ClearPasswordProtectedBanks and by SeqFile_Load on its target bank."),
    # the disk module's chunked transfers and window setters (FINDINGS-prom_b-disk-and-file-menus.md table)
    ("FE2AA9", "DiskSave_StreamLinkRamToFile",
     "(0 = SOUND: link RAM 0xE80000, 0x17 x 0x2C00 + 0xC00 = 0x40000 bytes; 1 = COMBINATION: 0xEC0000, 8 x 0x2C00 +\n"
     "0x300 = 0x16300): after the first chunk its caller wrote, each further 0x2C00 bytes come over the link into the\n"
     "staging window\n"
     "(T_Link_SendCommandE2) and go to the open file 0x400 at a time -- DiskCmd 0x1A (set transfer address) at\n"
     "window + n x 0x400, then DiskApi_WriteFileFromWindow with Disk_Flags bit 1; a failed write deletes the file\n"
     "(DiskFile_Delete).  Called by DiskSave_Sound / DiskSave_Combination."),
    ("FE20E1", "DiskLoad_StreamFileToLinkRam",
     "(count, link address): the load twin -- reads the open file 0x400 bytes at a time\n"
     "(DiskLoad_ReadKilobyteToWindowSlot) and sends every 0x2C00 to link RAM at the address\n"
     "(T_Link_SendCommandE4).  Called by DiskLoad_Sound / DiskLoad_Combination."),
    ("FE22EF", "DiskLoad_ReadKilobyteToWindowSlot",
     "(n): DiskCmd 0x1A (set transfer address) to Disk_WindowStart + n x 0x400, then DiskApi_ReadFileToWindow;\n"
     "returns its result, with 0xFD (end of file) read as 1."),
    ("FE2CFF", "Disk_SetWindowStartToStaging",
     "Disk_WindowStart = 0x609400 (DiskSave_Sound / _Combination, DiskLoad_Sound)."),
    ("FE2D4F", "Disk_SetWindowLengthToLinkChunk",
     "Disk_WindowEnd = Disk_WindowStart + 0x2C00, one link transfer (11 x 0x400)."),
    ("FE2D5E", "Disk_SetWindowLengthToKilobyte",
     "Disk_WindowEnd = Disk_WindowStart + 0x400."),
    ("FE2D09", "Disk_SetWindowStartToFileBuffer",
     "Disk_WindowStart = 0x60A080, where DiskLoad_MidiSetting / _Combination / _PanelLswFile read a file and\n"
     "DiskSave_MidiSetting builds one."),
    ("FE2CF5", "Disk_SetWindowStartToPanelImage", "Disk_WindowStart = 0x7600, the panel image the LSW file holds."),
    ("FE2D7C", "Disk_SetWindowEndToPanelImageEnd", "Disk_WindowEnd = 0x7600 + (0x760A) x 16."),
    ("FE2DBC", "Disk_SetPanelImageLength", "(0x760A) = 0xA0: the panel image is 0xA00 bytes, 0x7600-0x7FFF."),
    ("FE1FAB", "DiskLoad_CopyFromFileBuffer",
     "(dst, n): copies n bytes from the file buffer 0x60A080 at its read cursor (0x1733) to dst and advances the\n"
     "cursor.  DiskLoad_MidiSetting pulls the MDS fields out with it."),
    ("FE1E93", "DiskLoad_SaveRam7FC0",
     "copies the 32 bytes at RAM 0x7FC0 to 0x1713, before DiskLoad_PanelLswFile reads the 0xA00-byte image\n"
     "0x7600-0x7FFF over them."),
    ("FE1EC3", "DiskLoad_RestoreRam7FC0",
     "copies them back from 0x1713 after the image is read, so the LSW file never sets 0x7FC0-0x7FDF."),
    ("FE2DDD", "DiskLoad_CheckLswHeader",
     "A = 1 when the file buffer's bytes +4 / +5 (0x60A084 / 0x60A085) are 'W' 'A', else 0 -- DiskLoad_PanelLswFile\n"
     "refuses the file with 0x10 on 0."),
    # MIDI FILE DIRECT PLAY's stream (FINDINGS-prom_b-disk-and-file-menus.md) and the file-name editor
    ("FE04BE", "MidiFileStream_Open",
     "T_MidiFileStream_Open's body (MidiFileDirectPlay_LcdKeyRow1): (0x178E) = 1, (0x1704) = 0, (0x170E) = 1, extension MID,\n"
     "DiskFile_SetFcbName, DiskCmd 0x0F (open) on the FCB at 0x178E; failure -> (0x170E) = 2, WA = 0xFFFF; success\n"
     "-> kernel task 4 (MidiFileStream_ReaderTask) started, WA = 0."),
    ("FE02AB", "MidiFileStream_ReaderTask",
     "kernel task 4 (task-table entry 0xF85EAE, thunk T_MidiFileStream_ReaderTask, stack 0x60EB00): (0x17B7) = 1; file size = the\n"
     "FCB's +0x10 words (0x179E, 0x17A0) -> (0x1700); buffers 0x604B00 and 0x605300 seeded onto queue 2; then\n"
     "each buffer received from queue 2 is filled with the next 0x400 bytes (MidiFileStream_ReadBlock) and sent to\n"
     "queue 3 -- a non-zero flag word (+2) is a stop request, sent back with 0xFFFE; at the end (0x17B7) = 0 and\n"
     "T_Kernel_ExitTask_2."),
    ("FE0280", "MidiFileStream_ReadBlock",
     "(dst): DiskCmd 0x1A (set transfer address) = dst, then DiskCmd 0x83 (read file block) on the FCB at 0x178E;\n"
     "returns its status."),
    ("FE0391", "MidiFileStream_GetByte",
     "T_MidiFileStream_GetByte's body (MidiFileDirectPlay_Tick, SequencerMedley_MidiFileTick): while (0x170E) = 1, the next byte\n"
     "of the current buffer (0x1706 / read pointer 0x170A / count 0x1704), a fresh one taken from queue 3 when it\n"
     "runs out; an emptied full (0x400) buffer goes back on queue 2; a short one or a set flag -> (0x170E) = 2.\n"
     "WA = the byte, or 0xFFFF."),
    ("FE0435", "MidiFileStream_Close",
     "T_MidiFileStream_Close's body (MidiFilePlay_Stop): drains queue 2, posts the current buffer with flag 0xFFFF (stop),\n"
     "waits for (0x17B7) = 0, (0x170E) = 2, drains queues 3 and 2, blanks the 11 bytes of Disk_FileName."),
    ("FE1337", "NameEdit_MoveCursor",
     "SoftKeyCol1/2 on DISK SAVE FILE page 0 (through NameEdit_MoveCursor_Call): NameEdit_CursorPos -1 when (0x272C) bit 7 is set\n"
     "(not below 3), else +1 (not above 8); with (0x208C) bit 0 the 9-character name is first blanked to '_' and\n"
     "the cursor set to 3; then NameEdit_SyncCharIndex."),
    ("FE139D", "NameEdit_SyncCharIndex",
     "NameEdit_CharIndex = the position of Disk_FileName[NameEdit_CursorPos - 1] in the 37-character set at 0x1753\n"
     "(Disk_InitFileNameCharset), 0 when absent."),
    ("FE1863", "NameEdit_StepChar",
     "SoftKeyCol4/5 on page 0 (through NameEdit_StepChar_Call): NameEdit_CharIndex -1 when (0x272C) bit 7 is set (not below 0),\n"
     "else +1 (not above 0x24); the character set[index] goes into Disk_FileName at the cursor."),
    # the medley's floppy source (FINDINGS-prom_a-medley-and-name-edit-state.md names its RAM)
    ("FE15F4", "Medley_LoadNextSongFromDisk",
     "up to 20 tries ((0x2215)): Disk_ScanDirectory; when listing entry Disk_SelectedEntry (0x60A480 + 16 x n) is\n"
     "not empty (+8 is not 0x80), its 8-character name goes to Disk_FileName, status 0x0A, DiskLoad_ByContentType;\n"
     "Medley_AdvanceSong; a load that did not return 4 and left a song (0x60341E non-zero) ends it with 0.  Empty\n"
     "entries are skipped (Medley_AdvanceSong).  After 20: Disk_PortA3_Release, (0x34D0) bit 2 cleared, A = 4."),
    ("FE16D6", "Medley_AdvanceSong",
     "Medley_PlayingSong = Disk_SelectedEntry; Disk_SelectedEntry + 1, back to Medley_FirstSong past\n"
     "Medley_LastSong."),
    ("FE169D", "Medley_CopySongNameForDisplay",
     "Disk_FileName[2..7] -> 0x0E38 (6 characters), then spaces to 11."),
    # ranked by named context (the session's rank_context.py), read one by one
    ("FE99BF", "EditField_StoreLengthInNoteEvent",
     "when the event at the block-store cursor is a note-on (0x9n), steps 4 bytes in and writes EditField_Length as\n"
     "two 7-bit bytes, length mod 0x60 then length / 0x60 (`div A,0x60`); the cursor is saved and restored around it.\n"
     "Called by EditField_LengthUp / _LengthDown / _LengthUp12 / _LengthDown12."),
    ("F77F9A", "SmfOut_WriteFirstWindow",
     "Disk_Flags |= 0x20, T_DiskApi_WriteFileFromWindow_Entry, A = Disk_LastError, the flag cleared again -- the\n"
     "SMF writer's first window (the code after it writes a continuation with bit 1, and the final flush closes)."),
    ("FBC64F", "CombiEdit_RunPendingRepaint",
     "T_CombiEdit_RunPendingRepaint's body: when (0x277D) is 1 and the screen is one of COMBINATION EDIT's (0x33-0x3A, 0xB0-0xB7), posts\n"
     "that page's repaint routine to the callback queue and signals semaphore 1; (0x277D) = 0."),
    ("FE984B", "EditCursor_SeekPastTick",
     "opens the edited measure (EditScreen_SeekCursorMeasure, moving on through sub_FE93CA while BStore_ErrorCode is set), counts 0x81\n"
     "markers up to EditCursor_Beat, then steps over every event whose tick is <= EditCursor_Tick (`jr ule`) and\n"
     "backs onto the tag; 0x601F05 += the beat, 0x601F07 = the tick.  Called by EditCursor_NextBeat."),
    ("FE98E7", "EditCursor_SeekToTick",
     "EditCursor_SeekPastTick's twin that stops at the first event whose tick is >= EditCursor_Tick (`jr c`)."),
    ("F7C869", "N0teChange_StageDisplayFields",
     "N0TE CHANGE's fields into DisplayListB_Stage for its page: the track (0x0DEE), N0teChange_FromMeasure /\n"
     "_ToMeasure, the two notes split into octave and note name by `divs WA,12`; (0x129E) = the measure count,\n"
     "To - From + 1."),
    ("FA14E3", "Initial_SelectPreviousItem",
     "LcdKeyRow4_Initial: with Descriptor9_FA1B82 (+7 = 1: PanelEvent_Flags bit 0 set, the down step;\n"
     "maximum 6, one less on Variant_Flag 2), EditValue_StepBitField on Initial_SelectedItem; when it moved, posts\n"
     "the repaint sub_FA15CC and signals semaphore 1.  Only when PanelEvent_Flags bit 0 is clear on entry."),
    ("FA1546", "Initial_SelectNextItem",
     "LcdKeyRow5_Initial: the same with Descriptor9_FA1B8B (+7 = 0: the up step)."),
    ("FF0850", "EditMeasure_DrawBeatLines",
     "layer 2: for beats 1 .. EditMeasure_Beats-1, at x = 0x10 + 24 x beat from y 0x29 to 0xA8, SWI 7 0x1B\n"
     "(EraseRect) then 0x12 (LCD_Svc_12_DrawVLineDashed)."),
    ("F63489", "BStore_OpenChainAtSavedCursor",
     "T_BStore_OpenChainAtSavedCursor's body: BStore_OpenChain for entry A (error 1 is cleared and returned as 0); then entry A's saved\n"
     "cursor -- offset byte 0x6034A0[A-1], 5..255, else error 11; block word 0x60347E[A-1], <= BStore_BlockLimit,\n"
     "else error 10 -- becomes BStore_CursorBlock (BStore_SeekBlock); the block must be allocated (bit 7, else 11)\n"
     "and the byte at the offset not tag 0x84 (else error 6)."),
    # NOTE / DRUM EDIT: the edited part and the cursor's note row (FINDINGS-prom_a-screen-module.md section 8)
    ("FEA0CF", "EditCursor_NoteUp",
     "EditScreen_SoftKeyCol3's up arm: (0x601F44) + 1 below 0x7F; in DRUM EDIT DrumEdit_RowFollowNoteUp; then EditCursor_ApplyNoteToEvent,\n"
     "EditScreen_DrawCursorNote, EditScreen_RedrawEditArea and (0x601F58) = 0x83, (0x601F59) = 2."),
    ("FEA0FE", "EditCursor_NoteDown", "the down arm: (0x601F44) - 1 above 1; in DRUM EDIT DrumEdit_RowFollowNoteDown; the same refresh."),
    ("FEAB68", "EditCursor_NoteUp6", "(0x601F44) + 6, clamped to 0x7F, with EditCursor_NoteUp's tail.  Called by EditCursor_NoteStepHeld."),
    ("FEABA5", "EditCursor_NoteDown6", "(0x601F44) - 6, floored at 1, with EditCursor_NoteDown's tail.  Called by EditCursor_NoteStepHeld."),
    ("FE8AB3", "DrumEdit_IsOtherNote",
     "in DRUM EDIT (EditScreen_Mode bit 0) reads the note two bytes into the event at the cursor (cursor restored)\n"
     "and returns 0xFF when it differs from (0x601F44); 0 when it matches, and always 0 in NOTE EDIT."),
    ("FE8BA8", "EditScreen_SaveTrackCursor",
     "BStore_CursorBlock -> word 0x3460[(0x601F00)], BStore_CursorOffset -> byte 0x3482[(0x601F00)]: the edited\n"
     "part's saved block-store cursor."),
    ("FE8B89", "EditScreen_AppendBeatMarker",
     "EditScreen_SaveTrackCursor, then one 0x81 byte (from 0x601F37) appended to chain (0x601F00) + 1 with\n"
     "BStore_AppendBytes."),
    ("FE9997", "EditCursor_ApplyNoteToEvent",
     "when the event at the block-store cursor is a note-on (0x9n), its note byte (+2) = EditCursor_Note (cursor\n"
     "restored); then EditScreen_AuditionEvent.  Called by all four EditCursor_Note steppers."),
    ("FEAB30", "EditCursor_NoteStepHeld",
     "NoteEdit_Button19 / DrumEdit_Button19 -- slot 0x13, the held variant of SoftKeyCol3: with (0x601F5B) bit 0\n"
     "and the edit area not busy ((0x601F58) bit 7 with (0x601F59) not 2), EditCursor_NoteUp6 or _NoteDown6 by W\n"
     "bit 7, the sense reversed in DRUM EDIT; UI_RequestBits |= 8."),
    ("FF0A7B", "EditScreen_DrawCursorNote",
     "layer 0: DrumEdit_DrawCursorNoteNumber in DRUM EDIT, NoteEdit_DrawCursorNoteName in NOTE EDIT."),
    ("FF0A8F", "DrumEdit_DrawCursorNoteNumber",
     "(0x26B0) = EditCursor_Note and DisplayList_FF0AA9 run through T_DisplayListB_Run: the note as a number."),
    ("FF0AB3", "NoteEdit_DrawCursorNoteName",
     "EditCursor_Note split by `div A,0x0C`: the octave through DisplayList_FF0AEA, the note through NoteNames."),
    ("FEA12D", "EditScreen_RedrawEditArea",
     "with (0x601F58) bit 7: erase layer 1, EditScreen_FillSelectedEventBar, LCD_DrawVRuleLeft_OrNothing; otherwise erase layer 0 and\n"
     "redraw the events (EditScreen_DrawVisibleNotesExceptSelected) first."),
    ("FEAEBC", "DrumEdit_RowFollowNoteUp",
     "after EditCursor_Note + 1 in DRUM EDIT (unless (0x601F1C) bit 7): EditScreen_CursorRow + 1 below 11, with\n"
     "the left column and highlight redrawn; at row 11 the list scrolls instead, DrumEdit_TopRowNote + 1 below 0x74."),
    ("FEAF4A", "DrumEdit_RowFollowNoteDown",
     "the mirror: EditScreen_CursorRow - 1 above 0, or DrumEdit_TopRowNote - 1 above 1."),
    # NOTE / DRUM EDIT: the selected event, its velocity, keyboard input (FINDINGS-prom_a-screen-module.md section 8)
    ("FE9A07", "EditField_ApplyVelocityToEvent",
     "when the event at the cursor is a note-on, byte +3 = (0x601F45) (cursor restored); then EditScreen_AuditionEvent.  Called by\n"
     "the four steppers of 0x601F45 -- which is therefore the selected event's VELOCITY."),
    ("FF0B46", "EditScreen_DrawEventVelocity",
     "(0x601F19) = (0x601F45), then the shared tail .LFF0B50: layer 0, the cell erased (sub_FEF81D), the value drawn\n"
     "(below 100 with a leading blank, otherwise with Str_v)."),
    ("FF0B3A", "EditScreen_DrawNewNoteVelocity", "(0x601F19) = (0x601F46), then the same tail -- the same cell."),
    ("FE8F11", "EditScreen_SelectEventAtCursor",
     "(0x601F5B) bit 0 = 0; when the event at the cursor sits on EditCursor_TickInMeasure (EditScreen_PositionAndMeasureStartTicks) and is a\n"
     "note-on that DrumEdit_IsOtherNote passes: bit 0 = 1, EditCursor_Note = +2, (0x601F45) = +3, EditField_Length =\n"
     "(+5 & 0x7F) x 0x60 + (+4 & 0x7F), (0x601F6F) = the note, NoteEdit_ScrollRulerToNote."),
    ("FE8F97", "NoteEdit_ScrollRulerToNote",
     "NOTE EDIT only: moves (0x601F53), 0..9, one step at a time until (0x601F6F) is inside the range EditScreen_VisibleNoteRange\n"
     "returns (A low, W high); when it moved, NoteEdit_DrawKeyboardRuler and the edit area redrawn."),
    ("FE8FFD", "NoteEdit_TakeKeyboardInput",
     "on screens 0x25 / 0x28, with the edit area idle and free blocks: drains the sequencer input ring\n"
     "(T_SeqBufRing_Get); a note-on (0x9n) with velocity -> NoteEdit_HoldKey, velocity 0 -> NoteEdit_ReleaseKey; when\n"
     "no key is held any more (NoteEdit_AnyKeyHeld): selection cleared, NoteEdit_ScrollRulerToNote,\n"
     "NoteEdit_EnterHeldNotes, EditScreen_AppendMissingBeatMarkers, redraw."),
    ("FE90B8", "NoteEdit_HoldKey",
     "the first free slot of 0x601F1C (8 x {flag 0x80, note, velocity}; 1 slot in DRUM EDIT) takes (0x601F34) /\n"
     "(0x601F35)."),
    ("FE90F8", "NoteEdit_ReleaseKey",
     "clears the flag of the slot holding note (0x601F34); A = 0xFF when none does."),
    ("FE912B", "NoteEdit_AnyKeyHeld", "A = 0xFF when any of the 8 slots at 0x601F1C is flagged, else 0."),
    ("FE915D", "NoteEdit_EnterHeldNotes",
     "DRUM EDIT: one note, EditCursor_Note with slot 0's velocity (NoteEdit_InsertNoteAndSync); NOTE EDIT: every slot with a note\n"
     "through NoteEdit_InsertNoteEvent then EditCursor_SyncBeatAndTick, stopping on a BStore error (sub_FE8BD4)."),
    ("FE97DF", "EditScreen_AppendMissingBeatMarkers",
     "appends 0x81 beat markers (EditScreen_AppendBeatMarker) while the target (0x601F6C) exceeds the count\n"
     "sub_FE9830 returns; BStore_ErrorCode = 0xFF when an append fails; the cursor is restored."),
    # NOTE / DRUM EDIT: note insertion, the periodic tick and its deferred actions
    ("FE91D2", "NoteEdit_InsertNoteEvent",
     "NoteEdit_SeekInsertPoint, then the 6-byte event at 0x601F16 -- 0x90, EditCursor_TickInMeasure mod 0x60,\n"
     "NoteEdit_InputNote, NoteEdit_InputVelocity, (0x601F49) mod 0x60, (0x601F49) / 0x60 -- inserted into chain\n"
     "EditScreen_Part + 1 (EditScreen_SaveTrackCursor, BStore_AppendBytes, 6 bytes).  So (0x601F49) is the\n"
     "length a new note gets."),
    ("FE9223", "NoteEdit_SeekInsertPoint",
     "from the measure's mark, steps over events and beat markers until the position passes\n"
     "EditCursor_TickInMeasure, or to the end tag 0x82."),
    ("FE9276", "EditCursor_SyncBeatAndTick",
     "(0x601F07) = EditCursor_TickInMeasure mod 0x60, (0x601F05) = its beat + (0x601F0F), the measure's first beat."),
    ("FE91C0", "NoteEdit_InsertNoteAndSync",
     "NoteEdit_InsertNoteEvent then EditCursor_SyncBeatAndTick, or sub_FE8BD4 on a BStore error.  Called by\n"
     "DrumEdit_SoftKeyCol8 and NoteEdit_EnterHeldNotes."),
    ("FE9290", "EditScreen_StepCursorAfterEntry",
     "EditCursor_AdvanceToNextIncStep and EditScreen_ExtendChainToCursorBeat; inside the measure the fields are\n"
     "redrawn, past its end EditScreen_WrapAndShowCursorMeasure; EditScreen_CursorFlags bit 2 (extension failed) -> sub_FE8BD4."),
    ("FEA64D", "EditScreen_ExtendChainToCursorBeat",
     "appends beat markers (EditScreen_AppendBeatMarker) until the chain holds the cursor's beat; CursorFlags bit 2\n"
     "is set when an append fails; the block-store cursor is restored."),
    ("FE82D7", "EditScreen_Tick",
     "T_EditScreen_Tick: NoteEdit_TakeKeyboardInput, then the two countdown timers (EditScreen_CountDownAction,\n"
     "_RunDueAction, _CountDownAction2, _RunDueAction2), then T_F40A3C."),
    ("FE92C1", "EditScreen_CountDownAction",
     "(0x601F58) - 1 while bit 7 is set and it is above 0x80."),
    ("FE92ED", "EditScreen_RunDueAction",
     "when (0x601F58) has reached 0x80: it is cleared and EditScreen_DeferredActions[(0x601F59)] runs.  The note\n"
     "steppers queue action 2 three ticks ahead (0x83 / 2), the DRUM EDIT scroll 5, the ruler scroll 4."),
    ("FE92D7", "EditScreen_CountDownAction2", "the same countdown on (0x601F5A)."),
    ("FE932D", "EditScreen_RunDueAction2", "when (0x601F5A) has reached 0x80: cleared, EditScreen_EndAudition_Call (EditScreen_EndAudition)."),
    ("FE933F", "EditScreen_ReloadMeasureView",
     "EditScreen_DeferredActions[0] and [6]: EditScreen_EndAudition, the measure reopened (EditScreen_OpenCursorMeasure, moving on through\n"
     "sub_FE93CA), its beat table rebuilt (EditScreen_BuildBeatTable), sub_FE938E, the event at the cursor selected\n"
     "(EditScreen_SelectEventAtCursor), and every part of the screen redrawn."),
    # NOTE / DRUM EDIT: audition, note-grid drawing, the deferred redraws
    ("FEA566", "EditScreen_AuditionEventNote",
     "when (0x600808) >= 0x14: (0x34D4) |= 0x40 and the timed event 0x90, 0x7E, EditCursor_Note,\n"
     "EditField_EventVelocity, EditScreen_Part on TimedEvents_Ring (T_TimedEventRing_Put, five bytes)."),
    ("FEA5B0", "DrumEdit_AuditionRowNote", "the same with velocity 0x50 -- a DRUM EDIT row change."),
    ("FEA5F7", "EditScreen_PutAuditionEnd",
     "the timed event 0x90, 0x7F, 0x28, 0, EditScreen_Part: what EditScreen_EndAudition sends before each new\n"
     "audition and two ticks after one."),
    ("FEA54F", "EditScreen_EndAudition",
     "when (0x600808) >= 10: (0x34D4) |= 0x40, EditScreen_PutAuditionEnd.  EditScreen_ActionTimer2's action\n"
     "(through EditScreen_EndAudition_Call)."),
    ("FEA535", "EditScreen_AuditionEvent",
     "EditScreen_EndAudition, EditScreen_AuditionEventNote, EditScreen_ActionTimer2 = 0x82 (end it two ticks\n"
     "later).  Called after the note or velocity of the selected event changes."),
    ("FEA542", "DrumEdit_AuditionRow",
     "EditScreen_EndAudition, DrumEdit_AuditionRowNote, EditScreen_ActionTimer2 = 0x82."),
    ("FEFFB4", "EditScreen_VisibleNoteRange",
     "A = the lowest, W = the highest note shown: DRUM EDIT DrumEdit_TopRowNote .. + 11; NOTE EDIT the word pair\n"
     "WordTable_FEFFDD[NoteEdit_RulerPosition]."),
    ("FEFFF3", "EditScreen_DrawEventBar",
     "geometry from EditBar_LoadEventGeometry, layer 0, the mode's shape (DrumEdit_EventMarkRect DRUM / NoteEdit_EventBarRect NOTE), SWI 7 service 9."),
    ("FF00ED", "EditScreen_DrawSelectedEventBar",
     "with an event selected and its note in EditScreen_VisibleNoteRange: its bar on layer 1 (DrumEdit_DrawSelectedMarkBrackets /\n"
     "NoteEdit_DrawSelectedBarInset)."),
    ("FEFDAC", "EditScreen_DrawCursorTickMarker",
     "layer 1: Glyph_FEFDE4 at x = EditCursor_TickInMeasure / 4 + 0x0D (NOTE) or 0x56 (DRUM), y = 0x22."),
    ("FEFEBF", "EditScreen_DrawVisibleNotes",
     "walks the measure from its mark, counting 0x81 beat markers up to EditMeasure_Beats, and draws every note-on\n"
     "whose note is inside EditScreen_VisibleNoteRange (EditScreen_DrawEventBar)."),
    ("FEFF2D", "EditScreen_DrawVisibleNotesExceptSelected",
     "the same walk, skipping the note-on at the selected position (0x601F0B / 0x601F0D)."),
    ("FEFD8A", "EditScreen_RedrawCursorLayer",
     "while the cursor is inside the measure: layer 1 erased, EditScreen_DrawSelectedEventBar,\n"
     "EditScreen_DrawCursorTickMarker, the left rule, EditScreen_DrawDataEndMarker."),
    ("FE972B", "EditScreen_DeferredReselectAndRedraw",
     "EditScreen_DeferredActions[2] (queued by the note steppers): EditScreen_SelectEventAtCursor, layer 0 erased,\n"
     "EditScreen_DrawVisibleNotes, EditScreen_RedrawCursorLayer."),
    ("FEAFF1", "EditScreen_DeferredReselectAndRedraw5",
     "EditScreen_DeferredActions[5] (queued by the DRUM EDIT scroll): the same four calls."),
    ("FE975B", "EditScreen_DeferredRedraw",
     "EditScreen_DeferredActions[4] (queued by the ruler scroll): EditScreen_DrawVisibleNotes,\n"
     "EditScreen_RedrawCursorLayer."),
    ("FE973C", "EditScreen_DeferredRedrawAndExtend",
     "EditScreen_DeferredActions[3]: redraw; with an event selected, EditScreen_AppendMissingBeatMarkers first\n"
     "(sub_FE8BD4 on a BStore error)."),
    # NOTE / DRUM EDIT: walking the part's chain (positions in beats and ticks)
    ("FE96E3", "EditScreen_SeekPartSavedCursor",
     "BStore_CursorBlock = word 0x60347E[EditScreen_Part], BStore_CursorOffset = byte 0x6034A0[EditScreen_Part]: the\n"
     "part's saved cursor (the workspace pair BStore_OpenChainAtSavedCursor checks)."),
    ("FEA6B4", "EditScreen_CountBeatMarkersToEnd",
     "(0x601F6C) = the number of 0x81 beat markers from the cursor to the chain's end tag 0x82."),
    ("FEA6D7", "EditScreen_CountBeatsInMeasure",
     "from the measure's mark, (0x601F6C) = the 0x81 markers counted until it passes EditMeasure_Beats or the\n"
     "end tag."),
    ("FE960B", "EditScreen_SeekCursorBeat",
     "steps over EditCursor_Beat beat markers from the cursor; BStore_ErrorCode = 0xFF when the end tag comes first."),
    ("FEA628", "EditScreen_PositionAndMeasureStartTicks",
     "XWA = (0x601F05) x 0x60 + (0x601F07), the walk position in ticks; XBC = (0x601F0F) x 0x60 + (0x601F11), the\n"
     "measure's start -- the callers subtract them to get the tick within the measure."),
    # NOTE / DRUM EDIT: opening the cursor's measure
    ("FE8EF3", "EditScreen_SeekCursorMeasure",
     "(0x0C90) = EditCursor_Measure, sub_FE8F0C (T_F40A70), then T_F40C5C on chain EditScreen_Part + 1: prom_b's\n"
     "seek to that measure, which returns IX = its first beat and IY = the offset."),
    ("FE8EA9", "EditScreen_OpenCursorMeasure",
     "EditScreen_SeekCursorMeasure; when it found the measure: EditMeasure_StartBeat = IX, EditMeasure_StartTick = 0,\n"
     "and the mark (0x601F12) = BStore_CursorBlock, (0x601F14) = IY -- what BStore_CursorSlot_RestoreMark returns to."),
    ("FE8ED3", "EditScreen_SeekCursorMeasureStart",
     "EditScreen_SeekCursorMeasure; when found: EditPos_Beat = IX, EditPos_Tick = 0, BStore_CursorOffset = IY."),
    ("FE8AE9", "EditScreen_BuildBeatTable",
     "for the (0x601F76) measures from EditCursor_Measure, seeks each one (T_F40C5C) and fills the byte table at\n"
     "0x601F5F that EditCursor_BeatsInMeasure reads; the cursor is saved and restored around it."),
    ("FE95C8", "EditCursor_WrapPastMeasureEnd",
     "with EditCursor_TickInMeasure past the measure: the next measure at beat 0 when the beat table's last entry\n"
     "is set, else one beat more; EditCursor_Tick = TickInMeasure - EditMeasure_Beats x 0x60."),
    ("FE9492", "EditCursor_WrapAndRecompute",
     "EditCursor_WrapPastMeasureEnd, then EditCursor_TickInMeasure = EditCursor_Beat x 0x60 + EditCursor_Tick."),
    ("FE9EDA", "EditCursor_ComputeTickInView",
     "EditCursor_TickInMeasure = (EditCursor_Beat + the first column of the cursor's measure) x 0x60 +\n"
     "EditCursor_Tick, the column found as the first EditScreen_BeatTable entry equal to EditCursor_Measure -\n"
     "(0x601F5D) + 1.  So the table holds, per beat column shown, the 1-based measure the column belongs to."),
    ("FE9EBB", "EditCursor_RecomputeAndRedraw",
     "EditCursor_ComputeTickInView; inside the view: the cursor layer erased (EditScreen_EraseMarkerStrip),\n"
     "EditScreen_DrawCursorTickMarker, the left rule, EditScreen_DrawDataEndMarker.  Called by every EditCursor_Tick* / *Beat move."),
    ("FEA082", "EditScreen_QueueRelocateAfterMove",
     "with an event selected: EditScreen_ActionTimer = 0x85, EditScreen_ActionIndex = 1 -- deferred action 1 five\n"
     "ticks later."),
    ("FEA84F", "EditPos_LoadEventTick",
     "EditPos_Tick = byte +1 of the event at the block-store cursor (the cursor is restored)."),
    # NOTE / DRUM EDIT: the cursor moves (EditScreen_CursorRight / _CursorLeft)
    ("FEA7E7", "EditPos_SeekNextShownNote",
     "CursorFlags bits 1 and 4 cleared; steps to the next note-on that DrumEdit_IsOtherNote passes and loads its tick\n"
     "(EditPos_LoadEventTick); EditPos_Beat + 1 at each 0x81; bit 1 set at the end tag (tick 0), bit 4 once the walk\n"
     "has left the view (EditPos_Beat - EditMeasure_StartBeat >= EditMeasure_Beats)."),
    ("FEA79B", "EditCursor_SetMeasureFromView",
     "EditCursor_Measure = EditScreen_FirstMeasure + the measure starts (non-zero EditScreen_BeatTable entries)\n"
     "among the columns up to the cursor's."),
    ("FEA743", "EditCursor_SplitViewTick",
     "from EditCursor_TickInMeasure: EditCursor_Beat = the columns since the last measure start, EditCursor_Tick =\n"
     "the tick mod 0x60, then EditCursor_SetMeasureFromView."),
    ("FEA71F", "EditCursor_StepBackToIncGrid",
     "EditCursor_TickInMeasure = the largest multiple of EditField_Inc below it (unchanged at 0)."),
    ("FEA449", "EditPos_SeekFirstNoteAfterOldCursor",
     "from the measure's mark, EditPos_SeekNextShownNote until the position passes (0x601F56) -- the cursor before\n"
     "the move -- or the chain ends (bit 1)."),
    ("FEA47F", "EditPos_SeekLastNoteBeforeOldCursor",
     "the last shown note before (0x601F56): walks from the mark saving the cursor at each note; CursorFlags bit 3\n"
     "is set when there is none."),
    ("FEA4DC", "EditCursor_LandOnNote",
     "EditCursor_TickInMeasure = the note's position; past the view -> EditScreen_WrapAndShowCursorMeasure; otherwise\n"
     "EditCursor_SplitViewTick, EditScreen_SelectEventAtCursor, the fields and cursor redrawn,\n"
     "EditScreen_AuditionEvent."),
    ("FEA50C", "EditCursor_LandOnGrid",
     "past the view -> EditScreen_WrapAndShowCursorMeasure; otherwise the selection cleared (CursorFlags bit 0), the block-store cursor\n"
     "restored, the cursor layer redrawn, EditCursor_SplitViewTick, the fields redrawn."),
    ("FEA923", "EditPos_SeekPrevShownNote",
     "steps back (BStoreCursor_SeekPrevTag) to the previous note-on DrumEdit_IsOtherNote passes, loading its tick;\n"
     "EditPos_Beat - 1 at each 0x81; CursorFlags bit 3 when the measure's start is passed or a BStore error comes."),
    ("FEADFB", "EditCursor_NextBeatStart",
     "NoteEdit_Button24 / DrumEdit_Button23: selection cleared, EditCursor_AdvanceToNextIncStep with EditField_Inc\n"
     "forced to 0x60 (restored after), then EditCursor_SplitViewTick and EditCursor_SeekPastTick and a redraw;\n"
     "past the view, EditScreen_WrapAndShowCursorMeasure."),
    ("FEAE58", "EditCursor_PrevBeatStart",
     "NoteEdit_Button23 / DrumEdit_Button22: the mirror with EditCursor_StepBackToIncGrid at a 0x60 grid; at view\n"
     "tick 0, EditScreen_ShowPreviousMeasure."),
    ("FEAFB7", "DrumEdit_CursorNoteFromRow",
     "DRUM EDIT: EditCursor_Note = DrumEdit_TopRowNote + EditScreen_CursorRow."),
    ("FEB033", "DrumEdit_AuditionEnteredNote",
     "EditScreen_AuditionEvent, EditScreen_ActionTimer2 = 0x82.  Called by DrumEdit_SoftKeyCol8 after it enters a\n"
     "note."),
    ("FEB069", "DrumEdit_RedrawRowList",
     "DRUM EDIT: the left column erased (EditScreen_EraseRowLabelArea), DrumEdit_DrawRowNotes, DrumEdit_DrawRowNames."),
    ("FE9648", "EditScreen_ShowPreviousMeasure",
     "with EditCursor_Measure > 1: the view is rebuilt from the measure before (EditScreen_OpenCursorMeasure and\n"
     "EditScreen_BuildBeatTable with the measure lowered by one, then raised back), the cursor at beat 0 tick 0 of\n"
     "its measure (EditScreen_SeekCursorMeasureStart, EditCursor_ComputeTickInView), selection and screen redrawn."),
    ("FE9694", "EditScreen_ShowPreviousMeasureAtTick",
     "EditScreen_ShowPreviousMeasure with EditCursor_SeekToTick before the re-selection.  Called by\n"
     "EditCursor_PrevBeat."),
    ("FE94FB", "EditScreen_ShowCursorMeasure",
     "the view rebuilt to start at the cursor's measure: EditScreen_OpenCursorMeasure (moving on through sub_FE93CA\n"
     "when it is missing), EditScreen_SeekCursorBeat, EditScreen_BuildBeatTable, EditCursor_SeekToTick,\n"
     "EditScreen_SelectEventAtCursor, everything redrawn; with a selection, EditScreen_AuditionEvent."),
    ("FE955D", "EditScreen_WrapAndShowCursorMeasure",
     "EditCursor_WrapAndRecompute, then EditScreen_ShowCursorMeasure's sequence.  Called when a move runs past\n"
     "the view."),
    # NOTE / DRUM EDIT: the event bars
    ("FF0294", "EditBar_LoadEventGeometry",
     "for the note-on at the cursor: (0x601F38) = its tick in the view, (0x601F3A) = its row (EditBar_SetRowFromNote),\n"
     "(0x601F3B) = its length (+5 & 0x7F) x 0x60 + (+4 & 0x7F), clipped (EditBar_ClipLengthToView)."),
    ("FF02F5", "EditBar_SetRowFromNote",
     "(note L, low A): DRUM EDIT row = 11 - (L - A), the list running top-down; NOTE EDIT row = L - A, + 4 at\n"
     "NoteEdit_RulerPosition 0."),
    ("FF02D5", "EditBar_ClipLengthToView",
     "when (0x601F38) + the length passes EditMeasure_Beats x 0x60 - 1, (0x601F3B) = what is left to the view's end."),
    ("FF000E", "NoteEdit_EventBarRect",
     "LCD_X0 = (0x601F38) / 4 + 0x10, LCD_X1 = LCD_X0 + (0x601F3B) / 4, LCD_Y0 = CoordTable_FF0058[(0x601F3A)],\n"
     "LCD_Y1 = LCD_Y0 + 3: a piano-roll bar as long as the note."),
    ("FF0092", "DrumEdit_EventMarkRect",
     "LCD_X0 = (0x601F38) / 4 + 0x59, two pixels wide, LCD_Y0 = CoordTable_FF00D1[(0x601F3A)], three high: a drum\n"
     "hit mark."),
    ("FF013F", "NoteEdit_DrawSelectedBarInset",
     "NoteEdit_EventBarRect shrunk by a pixel on each side (bars under 2 pixels: their left edge only), SWI 7 5\n"
     "(FillRect)."),
    ("FF0178", "DrumEdit_DrawSelectedMarkBrackets",
     "two fills, just above and just below DrumEdit_EventMarkRect."),
    ("FF019D", "EditScreen_FillSelectedEventBar",
     "with an event selected and its note in view: layer 1, its bar or mark filled (LCD_FillRect_Grown2Rows in\n"
     "DRUM EDIT, NoteEdit_EventBarRect + FillRect in NOTE EDIT)."),
    ("FF0243", "EditScreen_DrawSelectionAtCursor",
     "with an event selected: its bar drawn at the CURSOR -- EditCursor_Note's row, EditCursor_TickInMeasure,\n"
     "EditField_Length long (2 in DRUM EDIT) -- on layer 1: the selection following the cursor."),
    ("FF0205", "EditScreen_RedrawAfterTickMove",
     "EditCursor_Tick* moves: with a selection, the other notes redrawn and the selection drawn at the cursor\n"
     "(EditScreen_DrawSelectionAtCursor while a deferred action is pending, else EditScreen_FillSelectedEventBar);\n"
     "without, all notes and EditScreen_DrawSelectedEventBar."),
    # NOTE / DRUM EDIT: the static layer (2) -- titles, numbers, grid
    ("FF031F", "EditScreen_PaintStaticLayer",
     "layer 2: Paint_DrumEdit or Paint_NoteEdit, then EditScreen_DrawTrackNumber, _DrawSongNumber,\n"
     "_DrawRowGuides and _DrawGridLines."),
    ("FF035E", "EditScreen_DrawTrackNumber",
     "(0x26B0) = EditScreen_Part + 1 through DisplayList_FF037F -- the TRACK value of 'NOTE EDIT  TRACK  SONG'."),
    ("FF0389", "EditScreen_DrawSongNumber",
     "(0x26B0) = BStore_CurrentBank + 1 through DisplayList_FF03A9 -- the SONG value."),
    ("FF03B3", "EditScreen_DrawRulersAndLegend",
     "layer 2: EditScreen_DrawMeasureStartLines, NoteEdit_DrawKeyboardRuler, Screen_DrawKitCategoryLegend."),
    ("FF07C5", "EditScreen_DrawMeasureStartLines",
     "layer 2: at each beat column whose EditScreen_BeatTable entry (from the second) is non-zero -- a measure\n"
     "start -- a solid vertical line (SWI 7 2, LCD_Svc_02_DrawVLine): x = 0x10 + 24 n, y 0x29..0xA8 (NOTE EDIT) or\n"
     "x = 0x59 + 24 n, y 0x2A..0xA1 (DRUM EDIT)."),
    ("FF0841", "EditScreen_DrawGridLines", "DrumEdit_DrawBeatLines in DRUM EDIT, EditMeasure_DrawBeatLines in NOTE EDIT."),
    ("FF08AA", "DrumEdit_DrawBeatLines",
     "layer 2: for beats 1 .. EditMeasure_Beats-1 at x = 0x59 + 24 x beat: SWI 7 0x1B (EraseRect) over y 0x2A..0xA1,\n"
     "then DrumEdit_DrawDottedVLine."),
    ("FF08E5", "DrumEdit_DrawDottedVLine", "a point (SWI 7 0x0B, LCD_Svc_0B_PlotPoint) every second row from y 0x2B to 0xA0."),
    ("FF090B", "EditScreen_DrawRowGuides", "layer 2: DrumEdit_DrawRowGuides or NoteEdit_DrawRowGuides."),
    ("FF091F", "NoteEdit_DrawRowGuides", "16 dotted rows (NoteEdit_DrawDottedHLine), 8 pixels apart from y 0x29."),
    ("FF0937", "NoteEdit_DrawDottedHLine", "a point (SWI 7 0x0B) every third pixel from x 0x10 to 0xFF on row HL."),
    ("FF0954", "DrumEdit_DrawRowGuides", "12 dotted rows (DrumEdit_DrawDottedHLine), 10 pixels apart from y 0x29."),
    ("FF096C", "DrumEdit_DrawDottedHLine", "a point every third pixel from x 0x59 to 0x100 on row HL."),
    ("FF0407", "KitCategoryLegend_SelectByKitCode",
     "XIY = the legend table for the kit code (XIX+1): 0x20 KitCategoryLegends_ByProgram, 0x28 _User1, 0x29 _User2,\n"
     "0x30 _Ext, otherwise KitCategoryLegends.  No call to it is decoded."),
    # NOTE / DRUM EDIT: the value fields and the header row
    ("FEF8D6", "EditScreen_DrawFields", "DrumEdit_DrawFields in DRUM EDIT, NoteEdit_DrawFields in NOTE EDIT."),
    ("FEF8E5", "NoteEdit_DrawFields",
     "with an event selected: EditScreen_DrawCursorNote, _DrawEventVelocity, _DrawEventLength; otherwise\n"
     "_DrawNewNoteLength; then EditScreen_DrawMeasure, _DrawBeat, _DrawTick, _DrawInc."),
    ("FEF907", "DrumEdit_DrawFields",
     "with an event selected: EditScreen_DrawCursorNote, _DrawEventVelocity; otherwise _DrawNewNoteVelocity; then\n"
     "MEAS / beat / tick and INC."),
    ("FF0BF1", "EditScreen_DrawEventLength",
     "layer 0: the cell erased (EditScreen_EraseLengthCell); EditField_Length drawn, 4-digit layout below 10000, 5-digit above."),
    ("FF0C12", "EditScreen_DrawNewNoteLength", "the same for EditField_NewNoteLength."),
    ("FF0C33", "EditScreen_DrawLengthBelow10000",
     "(0x26B0) as 1 + 3 digits (thousands at text cell 0x1C0C, the rest at 0x1C0D), or 3 digits below 1000."),
    ("FF0C9B", "EditScreen_DrawLengthFrom10000", "(0x26B0) as 2 + 3 digits (cells 0x1C0C / 0x1C0E)."),
    ("FF0D03", "EditScreen_DrawInc", "layer 0: DrumEdit_DrawIncLabel in DRUM EDIT, NoteEdit_DrawIncNumber in NOTE EDIT."),
    ("FF0D17", "NoteEdit_DrawIncNumber", "EditField_Inc through DisplayList_FF0D2F (a number)."),
    ("FF0D3E", "DrumEdit_DrawIncLabel", "EditField_Inc through DisplayList_FF0D56 and TickLabels (a label)."),
    ("FEF938", "EditScreen_DrawBeatNumbers",
     "layer 0, row y 0x18: at each beat column that is not a measure start (EditScreen_BeatTable entry 0) the\n"
     "beat's number within its measure (Digits_FEF999, restarting at 1 after each start), x = 24 x column + 0x0D\n"
     "(NOTE) or 0x55 (DRUM)."),
    ("FEFDE5", "EditScreen_DrawDataEndMarker",
     "EditScreen_CountBeatsInMeasure (cursor and position kept); when the part's chain ends inside the view, layer\n"
     "1: Glyph_FEFE58 at x = 24 x the beats it holds + 0x0D / 0x56, y 0x21."),
    ("FEF926", "EditScreen_DrawHeaderAndGrid",
     "layer 0: EditScreen_DrawBeatNumbers, EditScreen_DrawMeasureNumbers, EditScreen_DrawGridLines,\n"
     "EditScreen_DrawMeasureStartLines."),
    # NOTE / DRUM EDIT: the per-layer paints and the strip erasers (EraseRect records, SWI 7 0x1B)
    ("FEF8AC", "EditScreen_PaintLayer0",
     "layer 0: EditScreen_DrawFields, EditScreen_DrawVisibleNotes, EditScreen_DrawHeaderAndGrid.  Called by\n"
     "EditScreen_EnterNoteEdit."),
    ("FEF8BE", "EditScreen_PaintLayer1", "layer 1: EditScreen_RedrawCursorLayer."),
    ("FEF8CA", "EditScreen_PaintLayer2", "layer 2: EditScreen_PaintStaticLayer, EditScreen_DrawRulersAndLegend."),
    ("FEF778", "EditScreen_EraseFieldRow",
     "layer 0, DisplayList_FEF78C: EraseRect (8, 0xB2)-(0xE8, 0xC0), the value row at the bottom."),
    ("FEF796", "EditScreen_EraseMarkerStrip",
     "layer 1, DisplayList_FEF7AA: EraseRect (0, 0x21)-(0x108, 0x27), the strip the cursor tick marker (y 0x22) and\n"
     "the data-end marker (y 0x21) are drawn in."),
    ("FEF7B4", "EditScreen_EraseHeaderRow",
     "layer 0, DisplayList_FEF7C8: EraseRect (0, 0x14)-(0x108, 0x1F), the beat-number row (y 0x18)."),
    ("FEF83B", "EditScreen_EraseLengthCell",
     "layer 0, DisplayList_FEF84F: EraseRect (0xA0, 0xB2)-(0xC8, 0xC0).  Called by EditScreen_DrawEventLength /\n"
     "_DrawNewNoteLength."),
    ("FEF88B", "EditScreen_EraseRowLabelArea",
     "layer 0, DisplayList_FEF89F: EraseRect (0, 0x29)-(0x58, 0xA3), the left area DrumEdit_RedrawRowList redraws."),
    ("FE9762", "EditScreen_InsertSelectedEventAtCursor",
     "copies the selected event's bytes +2..+5 (note, velocity, length) to 0x601F18..0x601F1B, backs onto its tag,\n"
     "runs sub_FE9983 (EditScreen_SaveTrackCursor, BStore_DirEntry = part + 1, T_F42F04 -- whose effect is not read\n"
     "here), seeks the cursor's tick (EditCursor_SeekPastTick) and inserts 0x90, EditCursor_Tick and the four bytes\n"
     "into the part's chain (BStore_AppendBytes, 6), then EditScreen_AppendMissingBeatMarkers.  Called by\n"
     "EditCursor_NextBeat / _PrevBeat and deferred action 1 -- the selected note following the cursor."),
    ("FE9711", "EditScreen_DeferredInsertSelectedAtCursor",
     "EditScreen_DeferredActions[1], queued by EditScreen_QueueRelocateAfterMove: EditScreen_InsertSelectedEventAtCursor,\n"
     "the selection redone, the notes redrawn, EditCursor_TickInMeasure from the position, the cursor layer redrawn."),
    ("FE9148", "NoteEdit_ClearHeldKeyNotes", "the note byte of each of the 8 NoteEdit_HeldKeys slots = 0."),
    ("FEAA94", "EditCursor_MeasureStepHeld",
     "NoteEdit_Button17 / DrumEdit_Button17 -- slot 0x11, the held variant of SoftKeyCol1 (code 0x00 + 0x11, as slot\n"
     "0x13 is of 0x02): EditCursor_MeasurePlus10 / _MeasureMinus10 by W bit 7, unless deferred action 0 is pending."),
    ("FEAB0E", "EditCursor_TickStepHeld",
     "Button18 -- the held SoftKeyCol2: EditCursor_TickPlus5 / _TickMinus5, unless deferred action 1 is pending."),
    ("FEABE9", "EditField_VelocityStepHeld",
     "Button20 -- the held SoftKeyCol4: with an event selected EditField_EventVelocityUp5 / _Down5; otherwise, in\n"
     "DRUM EDIT, EditField_NewNoteVelocityUp5 / _Down5."),
    ("FE8830", "EditScreen_PartKitIsUserOrExt",
     "the edited part's entry in 0x603422 selects a record (RecordPtrs_RAM76A2); A = 0 when its kit code (+1) is\n"
     "0x28, 0x29 or 0x30 -- the User 1 / User 2 / Ext codes of KitCategoryLegend_SelectByKitCode -- else 0xFF.\n"
     "Called by EditScreen_EnterDrumEdit."),
    ("FE83DC", "EditPartSelect_DrawPartLabels",
     "the 16 bytes at 0x603422 copied to DisplayListB_Stage, then DisplayList_FE8405 with PartLabels_FE84F5.  Called\n"
     "by ShowScreen_NoteEditPartSelect / _DrumEditPartSelect."),
    ("FE87DD", "EditPartSelect_SelectUiPart",
     "(0x0DB5) bit 0 cleared; the first part set in the mask (0x1336) (up to 17) maps through 0x603422 and\n"
     "IndexMap_FE87B8 to UI_PartIndex; (0x0DB5) bit 0 set; a Queue2E00 record (W 0xFF, DE 0x1090).  Called by\n"
     "EditPartSelect_OpenEditor."),
    ("FEB280", "DrumEdit_DrawRowNames", "DrumEdit_DrawRowName for rows 0..11."),
    ("FEB290", "DrumEdit_DrawRowName",
     "(row DE) layer 0: note = DrumEdit_TopRowNote + row; T_F41040 with the part's kit (0x603422[EditScreen_Part])\n"
     "and the note; RecordNameSource_Select; 10 characters (SWI 7 0x17) at x 0x1A, y = row x 10 + 0x2B."),
    ("FE8CB4", "EditPos_SeekShownNoteAtTickZero",
     "within the beat (to the next 0x81 / 0x82), stops on the first note-on DrumEdit_IsOtherNote passes whose tick\n"
     "byte (+1) is 0, backed onto its tag; otherwise the cursor is restored."),
    ("FE8A9B", "EditPos_LoadTickIfShownNote",
     "EditPos_LoadEventTick when the event at the cursor is a note-on DrumEdit_IsOtherNote passes."),
    # the SMF player behind MIDI FILE DIRECT PLAY / the medley (FINDINGS-prom_b-disk-and-file-menus.md)
    ("FB93D0", "SmfPlay_ReadVlqBytes",
     "reads bytes (MidiFileStream_GetByte) into Smf_VlqBytes until one has bit 7 clear; A = the count; a negative\n"
     "read (end of stream) sets (0x605147) bit 0."),
    ("FB9532", "SmfPlay_ReadVlqBytes_Copy", "a byte-for-byte copy of SmfPlay_ReadVlqBytes, used by SmfPlay_ReadVlqValue."),
    ("FB9437", "SmfPlay_DecodeVlq1", "(0x60505F) = Smf_VlqBytes[0] & 0x7F."),
    ("FB9448", "SmfPlay_DecodeVlq2", "(0x60505F) = the 14-bit value of two VLQ bytes."),
    ("FB9490", "SmfPlay_DecodeVlq3", "(0x60505F) = the 21-bit value of three VLQ bytes."),
    ("FB9413", "SmfPlay_ReadDeltaTime",
     "(0x60505F) = 0, SmfPlay_ReadVlqBytes, then the decoder for 1 / 2 / 3 bytes."),
    ("FB9575", "SmfPlay_ReadVlqValue", "the same through SmfPlay_ReadVlqBytes_Copy -- event lengths."),
    ("FB951B", "SmfPlay_ClearVlqBytes", "Smf_VlqBytes[0..5] = 0."),
    ("FB9510", "SmfPlay_AdvanceEventTime", "(0x605044) += (0x60505F): the next event's time."),
    ("FB9599", "SmfPlay_SkipBytes",
     "reads and drops (0x60505F) bytes (the last kept in (0x605056)); (0x60505F) = 0."),
    ("FB9098", "SmfPlay_ScaleDeltaTo96Ppq",
     "when the file's division (0x605066) is not 0x60: (0x60505F) = delta x 0x60 / division, + 1 when the\n"
     "remainder checks against (0x60506A) / (0x60506E) say so."),
    ("FB92DC", "SmfPlay_ReadChannelEvent",
     "SmfPlay_ReadEventWithStatus when the byte just read (0x605056) has bit 7, else SmfPlay_ReadEventRunningStatus."),
    ("FB9345", "SmfPlay_ReadEventWithStatus",
     "Smf_RunningStatus = Smf_EventStatus = the status; one data byte for 0xCn / 0xDn, two otherwise;\n"
     "SmfPlay_SendChannelEvent."),
    ("FB92EF", "SmfPlay_ReadEventRunningStatus",
     "status = Smf_RunningStatus, the byte just read is data 1, data 2 read unless 0xCn / 0xDn;\n"
     "SmfPlay_SendChannelEvent."),
    ("FB95D9", "SmfPlay_SendChannelEvent",
     "data bytes clamped to 0x7F; the 2-byte (0xCn / 0xDn) or 3-byte message at Smf_EventStatus put on the MIDI\n"
     "input ring (T_MidiInARing_PutBlock) with interrupts held."),
    ("FB9923", "SmfPlay_HandleMetaEvent",
     "meta type: 0x2F -> its length byte, (0x10CB) = 0xFF, SmfPlay_StopAtEndOfTrack; 0x51 -> its length byte,\n"
     "SmfPlay_ReadTempoEvent; anything else skipped by its VLQ length."),
    ("FB9635", "SmfPlay_ReadTempoEvent",
     "the three tempo bytes to 0x605063..0x605065, then SmfPlay_ApplyTempo_SaveAll."),
    ("FB90EB", "SmfPlay_ApplyTempo_SaveAll", "SmfPlay_ApplyTempoAsBpm with every register pair saved."),
    ("FB90FE", "SmfPlay_ApplyTempoAsBpm",
     "BPM = 0x39387 (60,000,000 / 256) / ((0x605063) << 8 | (0x605064)), clamped 40..300; to (0x7EE2); queued as\n"
     "parameter 0x7A (Queue2C00); T_Tempo_ApplyBpm."),
    ("FB9176", "SmfPlay_StopAtEndOfTrack",
     "(0x60505E) bit 0 cleared; all notes off and hold off injected on every channel, positions cleared, bend /\n"
     "modulation reset, transports stopped (waits for TransportB), clock reset, T_MidiFileStream_Close,\n"
     "(0x60505E) bit 1 and (0x605148) cleared."),
    ("FB9697", "SmfPlay_ReadHeader",
     "reads four bytes and compares them with 'MThd' (MidiFile_Tables_FBA169); when they differ, 0x7C more bytes\n"
     "are skipped before it reads on -- a 0x80-byte prefix is tolerated."),
    ("FB99F5", "SmfPlay_HandleSysExEvent",
     "length (0x60505F) = 5 and the body starting 7E 7F 09 (GM System On) -> SmfPlay_ForwardGmSystemOn; length 16\n"
     "with first byte 0x50 -> F0 + the 16 bytes to Ring601646; other lengths skipped."),
    ("FB99AB", "SmfPlay_ForwardGmSystemOn",
     "unless (0x605053) already matches the mode (0x7F4D) bit 2 implies: waits for the MIDI SysEx receiver to be idle\n"
     "and puts the 6-byte F0 7E 7F 09 .. F7 on Ring601646."),
    ("FB9B30", "SmfPlay_ReadSysExEvent",
     "(0x605149) = 0, SmfPlay_ClearVlqBytes, SmfPlay_ReadVlqValue (the length), SmfPlay_HandleSysExEvent."),
    ("FB9E3F", "SmfPlay_StartPlayback",
     "clock reset, flags in (0x34D9) / (0x34BB) cleared, (0x605148) = 1, Transport_StartCAndB, repaint."),
    ("FB9E69", "SmfPlay_ClearEventTimes", "(0x605044) = 0, (0x605048) = 0."),
    # GM mode (prom_a 0xFB5000)
    ("FB5972", "GmMode_ApplyChange",
     "GmMode_HandleChange's body: the parameter image snapshot; entering GM (UiEvent_Byte2 bit 2): sub_FB567E,\n"
     "GmMode_ResetToDefaults and, unless (0x124C) bit 0, T_F42574; leaving: sub_FB5903, sub_FB568D; then the image\n"
     "re-sanitised and published, the tempo re-applied, and every part's pitch bend, channel pressure,\n"
     "modulation, expression and hold reset (GmReset_AllParts*), with GmReset_AllPartsParamB7 / _ParamB6."),
    ("FB5E5E", "GmReset_AllPartsParamB7",
     "parameter 0xB7 with (0x60F082) = 0, (0x60F083) = 0x7F, for parts 0..31 (Queue2C00_PublishStagedDrainPassB) --\n"
     "GmReset_AllPartsExpression's shape.  The parameter dispatch table maps 0xB7 to Dispatch_By_60F080_Nop64."),
    ("FB5E90", "GmReset_AllPartsParamB6", "the same with parameter 0xB6 (also Dispatch_By_60F080_Nop64 in the table)."),
    # the medley player (FINDINGS-prom_a-medley-and-name-edit-state.md section 4)
    ("FE7800", "Medley_Start",
     "T_Medley_Start: INT -> Medley_PlayingSong = Medley_FirstSong, Medley_LoadInternalSong; FD + MIDI FILE -> the same\n"
     "start, Medley_StartMidiFile."),
    ("FE782C", "Medley_Stop", "T_Medley_Stop: INT -> Medley_StopInternal; FD + MIDI FILE -> Medley_StopMidiFile."),
    ("FE7848", "Medley_Next", "T_Medley_Next: INT -> Medley_SkipToNextInternalSong; FD + MIDI FILE -> Medley_SkipToNextMidiFile."),
    ("FE7864", "Medley_LoadInternalSong",
     "from Medley_PlayingSong to Medley_LastSong (then from Medley_FirstSong once more), the first bank whose copy\n"
     "(0x610100 + bank x 0xC00) has an in-use directory entry: Medley_PlayingSong = BStore_CurrentBank = it,\n"
     "T_F4282C, (0x34D0) |= 4, its 6-character name (0x6034CA) to 0x0E38 + 5 blanks, (0x22D0) = 10.  None in range:\n"
     "UI_StatusCode 0x2F, request 0x40AB, Medley_Playing = 0."),
    ("FE78FB", "Medley_StopInternal",
     "T_Transport_StopAllRunning, (0x34D0) bit 2 cleared, Name11At0E38_Blank."),
    ("FE7908", "Medley_SkipToNextInternalSong",
     "Medley_StopInternal, Medley_PlayingSong + 1 (past Medley_LastSong: from Medley_FirstSong), Medley_LoadInternalSong."),
    ("FE7927", "Medley_AdvanceInternalSong",
     "T_Medley_AdvanceInternalSong, called by the sequencer at a song's end: when an INT medley plays ((0x34D0) bit 2), the next song as\n"
     "in Medley_SkipToNextInternalSong, without stopping first."),
    ("FE7950", "Medley_Tick",
     "T_Medley_Tick: counts (0x22D0) down; at 5 for INT: playback flags cleared and T_F409CC; at 0: INT -> T_F40304 (the\n"
     "transports from zero), FD + MIDI FILE -> the next song (wrapping) and Medley_StartMidiFile."),
    ("FE79B7", "Medley_StartMidiFile",
     "(0x34D0) |= 4, T_F42614 (mount and list the MIDI files); from Medley_PlayingSong, the first listing entry\n"
     "(0x60A480 + 8 n) that is not blank: its name to Disk_FileName and to 0x0E38, T_F42E90.  None: Medley_StopMidiFile,\n"
     "status 3."),
    ("FE7A30", "Medley_StopMidiFile",
     "(0x34D0) bit 2 cleared, Disk_BlankFileNameBase, T_F42E90, Name11At0E38_Blank."),
    ("FE7A40", "Medley_SkipToNextMidiFile", "Medley_StopMidiFile, then (0x22D0) = 10 so Medley_Tick starts the next file."),
    ("FE7A49", "Medley_ScheduleNextMidiFile",
     "T_Medley_ScheduleNextMidiFile: with an FD MIDI-file medley playing, (0x22D0) = 10."),
    ("FE7A73", "Disk_BlankFileNameBase", "Disk_FileName[0..7] = eight spaces."),
    # the note-frame processors (FINDINGS-prom_a-note-frames.md)
    ("FC80E2", "MidiInA_ProcessRing",
     "T_MidiInA_ProcessRing: T_MidiInARing_ScanRewind, then MidiInA_GatherFrame in a loop; a 0x90 frame through the note stages\n"
     "(MidiFrame_ToNoteFrame, NoteList_ApplyFrame, NoteFrame_SelectForPart ...), a 0xB0 frame through the control-change path."),
    ("FC8448", "MidiInB_ProcessRing", "the same for MIDI IN B (T_MidiInBRing_ScanRewind, MidiInB_GatherFrame)."),
    ("FC8960", "TimedEvents_ProcessRing",
     "T_TimedEvents_ProcessRing: T_TimedEventRing_ScanRewind, TimedEvents_GatherFrame in a loop; a 0x90 frame's channel mapped to a\n"
     "part through 0x603422 (0xFF = skip), then NoteRouting_ForTrack, PartNotes_ApplyFrame, PartFrame_SendToToneGen; 0xB0 frames to the CC path."),
    ("FC87AE", "Ring601850_ProcessNoteEvents",
     "T_F413B8: Ring601850_GatherFrame in a loop, each frame through NoteList_ApplyFrame, NoteFrame_SelectForPart, NoteRouting_ForPart,\n"
     "PartNotes_ApplyFrame, PartFrame_SendToToneGen."),
    ("FC915C", "MidiInA_GatherFrame",
     "(pending, frame): frame = {count, kind 0x90 / 0xB0, 1, channel, entries of 9 bytes from +7: note, velocity};\n"
     "consecutive note on / off messages on one channel, up to 0x20, or one control change; a message on another\n"
     "channel stays in the 5-byte pending record (0 = none, 0xFF = the ring is empty).  A = the entry count."),
    ("FC9343", "MidiInB_GatherFrame", "MidiInA_GatherFrame for MIDI IN B (T_MidiInBRing_Scan)."),
    ("FC9528", "TimedEvents_GatherFrame", "MidiInA_GatherFrame's shape over T_TimedEventRing_Scan."),
    ("FC9099", "Ring601850_GatherFrame",
     "up to 16 (note, velocity) pairs from T_Ring601850_Get into the frame's entries; the pending record as above."),
    ("FCB269", "MidiFrame_ToNoteFrame",
     "(MIDI frame, note frame): count, the source byte (MIDI frame +2: 1 for MIDI IN, 2 for timed events), and for\n"
     "each 9-byte entry a 7-byte one: +0 = its +7, +2 = its +8."),
    ("FCAD9B", "Note_TransposeFoldOctaves",
     "(note L, shift H): L + (H - 0x40), then 12 off or on until it lies in 0..0x7F."),
    ("FC9D6E", "NoteList_MoveNode",
     "(node, head): unlinks the 13-byte node (previous +9, next +0x0B) and links it in after the head."),
    ("FC9C1D", "NoteList_ApplyFrame",
     "(note frame, part block): for each entry -- velocity non-zero: a node from the free list (head 0x384A) when the\n"
     "source's count (0x3820 + source) is above 0, the voice mask from the part block (0x602054 table), byte +1 from\n"
     "Note_TransposeFoldOctaves, the node moved to the source's list (0x3823 + source x 13) and the entry copied into\n"
     "it; velocity 0: the source's node with the same note moved back to the free list, its count + 1, its voice mask\n"
     "ORed into the result; otherwise the entry = 0xFF, 0xFF.  XIY = the released voices."),
    ("FC9EA3", "NoteFrame_SelectForPart",
     "(out frame, note frame, part block, part): the entries whose voice mask overlaps 0x602054[part] and -- unless\n"
     "the block's +1 is not 0xFF -- whose note and velocity lie within the part's range record (6 bytes at\n"
     "+0x62 + part x 6: note low / high, velocity low / high) go to the out frame's +7 / +8; A = their count."),
    ("FC9F8B", "PartNotes_ApplyFrame",
     "(frame, part block, part): per entry -- note-on: a 15-byte node from the pool (head 0x39F7 + 0x1E0) while\n"
     "the part's budget (0x3800 + part) is above 0; up to three outputs from the part block: +0 with\n"
     "PartNote_MapForToneGen / _ApplyVelocityOffset (result bit 0), +1 with PartNote_TransposeForMidiOut (bit 1),\n"
     "+2 with the raw note (bit 2); the entry copied into the node, PartNoteList_MoveNode, budget - 1.  Note-off: the\n"
     "part's node with the same note, source and channel copied back with velocity 0, the same bits, the node\n"
     "freed, budget + 1.  A = the bits."),
    ("FCA194", "PartNoteList_MoveNode", "NoteList_MoveNode for the 15-byte nodes (previous +0x0B, next +0x0D)."),
    ("FCADD5", "PartNote_MapForToneGen",
     "on screen 0x28 the note is EditCursor_Note; then T_F41044 with the part block's +0x0E -- the note the tone\n"
     "generator gets."),
    ("FCADFA", "PartNote_ApplyVelocityOffset",
     "velocity + the part block's signed offset (+1), clamped to 0 / 0x7F; unchanged when the offset is 0."),
    ("FCAE2D", "PartNote_TransposeForMidiOut",
     "on screen 0x28 EditCursor_Note; otherwise the note + the block's transpose (+1), folded into 0..0x7F by\n"
     "octaves."),
    ("FCA6BB", "PartFrame_SendToToneGen",
     "result bit 0 of PartNotes_ApplyFrame: the frame to the tone generator (over the link)."),
    ("FCAA98", "PartFrame_SendToMidiOut",
     "result bit 1, unless (0x602493) bit 5: the frame to the MIDI OUT rings (T_Ring601432 / T_Ring60153C,\n"
     "T_MIDI_PostSendWork)."),
    ("FCACAA", "PartFrame_RecordToSeqBuf",
     "result bit 2: each entry as a 5-byte 0x90 event with Seq_BeatTick, staged at 0x602000 and put on SeqBufRing\n"
     "(SeqBuf_Flags bit 0 set)."),
    ("FCAE76", "NoteRouting_ForPart",
     "(out, routing block, part D): out+0 = the tone-generator part (block +2 + D) when it is not 0xFF, block +0x298\n"
     "bit 9 is clear and the part's record (+0x92 + 6 D) has bit 5 (or 0x602498 bit 6), with out+3 = that record;\n"
     "out+1 = the MIDI OUT channel (+0x22 + D) when its port is allowed (+0x293 bit 4 for 0..15, bit 3 for 16..31)\n"
     "and the part's MIDI record (+0x152 + 10 D) has bit 5, with out+7 = that record; out+2 = the track whose +0x42\n"
     "entry is D | 0x80, only while 0x602498 bit 7; each missing output 0xFF with the default record 0x602ACA."),
    ("FCB1BB", "NoteRouting_ForTrack",
     "(out, routing block, track): out+0 = the part the track feeds (+0x42 + track, low 5 bits), out+1 = its MIDI OUT\n"
     "channel (+0x52 + track) when the port is allowed, out+2 = 0xFF (no recording) -- the timed-event path."),
    ("FC9E46", "NoteList_BuildReleaseAllFrame",
     "(frame with the source at +1): every node of that source's list copied into the frame with velocity 0 -- a\n"
     "note-off for each sounding note; A = the low byte of their ORed voice masks."),
    ("FC54C6", "NoteRouting_RebuildForSong",
     "T_NoteRouting_RebuildForSong (BStore_BootPhase3, S0ngSelectName_Leave, ScreenEnter_CyclePlayEditScreen): sub_FC61A6 first, then\n"
     "block +0 = (0x4C22) | (0x4C21), NoteRouting_BuildByPanelMode[PanelMode] with 0, NoteRouting_UpdateActivePartMask,\n"
     "NoteRouting_CommitChanges."),
    ("FC5518", "NoteRouting_Rebuild",
     "T_NoteRouting_Rebuild (C0mbinati0nM0de_StepSelectedPart, ModeLeave_SeqPlay, MainTask_PhaseVector): the same without\n"
     "sub_FC61A6, the per-mode builder called with 1."),
    ("FC5566", "NoteRouting_SetSoloAndRebuild",
     "T_NoteRouting_SetSoloAndRebuild: (0x602498) bit 5 = the argument (LcdKeyRow1_C0mbinati0nM0de_Page2 -- the SOLO key --,\n"
     "ScreenLeaveBody_C0mbinati0nM0de, CombiEdit_CompareOn), then the rebuild with 0."),
    ("FC5C7C", "NoteRouting_CommitChanges",
     "by (0x4C04): bits 0xA0 NoteRouting_QueueMidiInChanges, 0xC0 NoteRouting_QueueTrackChanges, 0x20 NoteRouting_QueueMidiOutSchemeChange and NoteRouting_QueuePartTransmitChanges, 0x40 NoteRouting_QueueTrackPartChanges; then\n"
     "T_NoteRouting_ApplyQueuedChanges, the 0x29A-byte block copied to 0x602600, (0x4C04) = 0."),
    ("FC6153", "NoteRouting_UpdateActivePartMask",
     "(0x4C06) = BitMask32_Table_FC64C6[block +1], or block +0 when +1 is 0xFF; when it changed,\n"
     "T_ParamMsg_RefreshPartMasks."),
    # the per-mode routing builders, NoteRouting_BuildByPanelMode[PanelMode] (mode names from PanelScreen_VtableTable view A)
    ("FC5B26", "NoteRouting_KeyboardToSelectedPart",
     "the default builder (modes 0-2, 4, 8, 10-12, 14-16, 18, 19, 22: SOUND, COMBINATION, SEQ PLAY, SYSTEM, MIDI ...):\n"
     "block +1 = the part UI_PartIndex selects (Bytes_00_to_1F_x3_FC65C6 + 0x40); with block +0x298 bit 4 and a part\n"
     "below 8, block +0 = its bit (bit 5) and +1 = 0xFF instead; NoteRouting_ChangeFlags |= 3."),
    ("FC5B8A", "NoteRouting_BuildForSequencerModes",
     "modes 3, 5, 6, 7 (Sequencer, Realtime Record, Step Record, Edit): with NoteRouting_Mode bit 6, block +1 =\n"
     "(0x4C20) and flag bit 1; otherwise NoteRouting_KeyboardToSelectedPart."),
    ("FC5BCC", "NoteRouting_BuildForCombiEditPart",
     "mode 9 (CombiEditPart): on screens 0x61 / 0x63, block +1 = the part UI_PartIndex selects, flag bit 1; otherwise\n"
     "NoteRouting_KeyboardToSelectedPart."),
    ("FC5BB5", "NoteRouting_BuildForMode13",
     "mode 13: NoteRouting_Mode |= 4, then NoteRouting_KeyboardToSelectedPart."),
    ("FC5C4C", "NoteRouting_BuildForSoundCopy", "modes 20 / 21 (SoundCopy): NoteRouting_KeyboardToSelectedPart."),
    ("FC5C5C", "NoteRouting_BuildForModes23To27", "modes 23-27: NoteRouting_KeyboardToSelectedPart."),
    # the note-routing change queue (FINDINGS-prom_a-note-frames.md section 7)
    ("FC5CDA", "NoteRouting_QueueChange",
     "(kind, a, b, c): appends the 4-byte record kind / a / b / c to NoteRouting_ChangeQueue (0x602A02) and counts it in\n"
     "NoteRouting_ChangeCount (0x602A00); when the count is already above 0x7F the queue is applied first (T_NoteRouting_ApplyQueuedChanges).\n"
     "Its callers compare NoteRouting with NoteRouting_Previous."),
    ("FC8D49", "NoteRouting_ApplyQueuedChanges",
     "T_NoteRouting_ApplyQueuedChanges: for each record of NoteRouting_ChangeQueue (NoteRouting_ChangeCount of them), the kind 0..8 through\n"
     "NoteChange_HandlerTable with (record +1, +2, +3) -- a kind above 8 is skipped; then the count = 0."),
    ("FC8DD6", "NoteChange_CasePartReceive",
     "NoteChange_HandlerTable[0]: NoteChange_ReleasePartReceivedNotes(record +1, +2, +3)."),
    ("FC8DE6", "NoteChange_Case1Unused",
     "NoteChange_HandlerTable[1]: calls a bare ret (NoteChange_Kind1_Nop).  None of the queuers read queues kind 1."),
    ("FC8DF5", "NoteChange_CaseTrackMidiOut",
     "NoteChange_HandlerTable[2]: NoteChange_ReleaseTrackMidiOutNotes(record +1, +2, +3)."),
    ("FC8E04", "NoteChange_CaseTrackPart",
     "NoteChange_HandlerTable[3]: NoteChange_ReleaseTrackNotesOfOldPart(record +1, +2, +3)."),
    ("FC8E13", "NoteChange_CasePartToneGen",
     "NoteChange_HandlerTable[4]: calls a bare ret (NoteChange_PartToneGen_Nop).  Kind 4 is queued only by\n"
     "NoteRouting_QueueToneGenPartChanges, which nothing calls."),
    ("FC8E22", "NoteChange_CasePartTransmit",
     "NoteChange_HandlerTable[5]: NoteChange_ReleasePartTransmittedNotes(record +1, +2, +3)."),
    ("FC8E31", "NoteChange_CaseTrackPartRecord",
     "NoteChange_HandlerTable[6]: NoteChange_ReleaseRecordedNotesOfOldPart(record +1, +2, +3)."),
    ("FC8E40", "NoteChange_CaseMidiInMode",
     "NoteChange_HandlerTable[7]: NoteChange_ReleaseMidiInChannelNotes(record +1, +2, +3)."),
    ("FC8E4F", "NoteChange_CaseMidiOutScheme",
     "NoteChange_HandlerTable[8]: NoteChange_ReleaseOldMidiOutScheme(record +1, +2, +3)."),
    ("FC9727", "NoteChange_ReleasePartReceivedNotes",
     "kind 0 (part, new channel, old channel), queued when a part's MIDI channel (block +0x22) or its receive bit (bit 6\n"
     "of its MIDI record, +0x152) changed: unless the old channel or the part is 0xFF, the part's notes from MIDI IN\n"
     "(source 1) on the old channel become note-offs (PartNotes_BuildReleaseFrame, all three outputs) and go to the tone\n"
     "generator / MIDI OUT / record buffer as its result selects."),
    ("FC97F1", "NoteChange_ReleaseTrackMidiOutNotes",
     "kind 2 (track, new channel, old channel), queued when a track's MIDI OUT channel (block +0x52) changed: unless\n"
     "the old one is 0xFF, the track's notes (source 2, channel key = the track) on its part (BStore_TrackToPart) get\n"
     "MIDI OUT note-offs (PartNotes_BuildReleaseFrame with mask 2, PartFrame_SendToMidiOut)."),
    ("FC9796", "NoteChange_ReleaseTrackNotesOfOldPart",
     "kind 3 (track, new part, old part), queued when the part a track feeds (block +0x42, low 5 bits) changed: the\n"
     "track's notes (source 2, channel key = the track) on the OLD part are released (mask 7) and the note-offs go to\n"
     "the tone generator and MIDI OUT."),
    ("FC9854", "NoteChange_ReleasePartTransmittedNotes",
     "kind 5 (part, new channel, old channel), queued when a part's MIDI channel (+0x22) or its transmit bit (bit 5 of\n"
     "its MIDI record) changed: unless the old channel or the part is 0xFF, the part's note-list notes -- sources 0 and 1,\n"
     "whose channel key is the part itself (NoteFrame_SelectForPart writes it) -- get MIDI OUT note-offs (mask 2)."),
    ("FC98E7", "NoteChange_ReleaseRecordedNotesOfOldPart",
     "kind 6 (track, new part, old part), queued when the part a track feeds changed: the old part's notes from any\n"
     "source (frame source 0xFF) whose channel key is the old part get note-offs in the record buffer only (mask 4,\n"
     "PartFrame_RecordToSeqBuf)."),
    ("FC9933", "NoteChange_ReleaseMidiInChannelNotes",
     "kind 7 (path, 0xFF, channel), queued when the MIDI IN mode (NoteRouting_MidiFlags bits 6-7) or\n"
     "NoteRouting_ListChannel changed.  Path 1: every note MIDI IN put on the note list (NoteList_BuildReleaseAllFrame,\n"
     "source 1) is released through each part as NoteRouting_Previous routed it (NoteFrame_SelectForPart,\n"
     "NoteRouting_ForPartFromMidiIn, PartNotes_ApplyFrame; the three outputs, MIDI OUT unless +0x293 bit 5).  Path 0:\n"
     "each part that received on the channel (previous block: +0x22 = channel, record bit 6) releases its MIDI IN notes\n"
     "on it (PartNotes_BuildReleaseFrame; tone generator and record buffer)."),
    ("FC9AA1", "NoteChange_ReleaseOldMidiOutScheme",
     "kind 8 (old bit 5, 0xFF, old channel), queued when NoteRouting_MidiFlags bit 5 changed or NoteRouting_ListChannel\n"
     "changed while it stays set.  When source 0's note list holds notes: with 0 (MIDI OUT was per part) each part's\n"
     "source-0 notes get MIDI OUT note-offs; with 1 (MIDI OUT carried source 0 on the one channel) the note list's\n"
     "note-offs go out on the old channel (PartFrame_SendToMidiOut).  With 0, each part's source-1 notes then get MIDI\n"
     "OUT note-offs too, when source 1's list holds notes."),
    ("FC5D30", "NoteRouting_QueueMidiInChanges",
     "(NoteRouting_ChangeFlags bit 5): when the MIDI IN mode (NoteRouting_MidiFlags bits 6-7) or NoteRouting_ListChannel\n"
     "changed, a kind-7 record per channel whose MIDI IN path changes (1 = it took the note-list path before, 0 = the\n"
     "per-channel path); then for each of the 32 parts kind 0 (part, new, old) when its channel (+0x22) changed, or\n"
     "kind 0 (part, 0xFF, channel) when its receive bit (record +0x152 bit 6) changed."),
    ("FC5F19", "NoteRouting_QueueTrackChanges",
     "(NoteRouting_ChangeFlags bit 6 or 7): for each of the 16 tracks, kind 2 (track, new, old) when its MIDI OUT\n"
     "channel (+0x52, low 5 bits) changed and kind 3 (track, new, old) when its part (+0x42, low 5 bits) changed."),
    ("FC5FAC", "NoteRouting_QueueMidiOutSchemeChange",
     "(bit 5): kind 8 (previous bit 5, 0xFF, previous NoteRouting_ListChannel) when NoteRouting_MidiFlags bit 5\n"
     "changed, or when the channel changed while bit 5 is set."),
    ("FC6065", "NoteRouting_QueuePartTransmitChanges",
     "(bit 5): for each of the 32 parts, kind 5 (part, new, old) when its channel (+0x22) changed, or kind 5\n"
     "(part, 0xFF, channel) when its transmit bit (record +0x152 bit 5) changed."),
    ("FC610F", "NoteRouting_QueueTrackPartChanges",
     "(bit 6): for each of the 16 tracks, kind 6 (track, new, old) when its part (+0x42, low 5 bits) changed."),
    ("FCA475", "PartNotes_BuildReleaseFrame",
     "(frame with a source at +2 -- 0xFF any -- and a channel key at +3, outputs mask, part): each of the part's notes\n"
     "(PartNoteList_Heads) from that source with that key goes into the frame as a note-off (velocity 0) and is marked\n"
     "released (0xFF) on each output of the mask it still sounds on -- node +5 tone generator, +8 MIDI OUT, +0x0A\n"
     "record; a node released on all three returns to the pool and to the part's PartNote_Budget.  A = the outputs the\n"
     "frame must go to (bit 0 / 1 / 2)."),
    ("FCAFC9", "NoteRouting_ForPartFromMidiIn",
     "(out, routing block, part): NoteRouting_ForPart's tone-generator and recording-track outputs, but MIDI OUT (the\n"
     "+0x22 channel with the port and record-bit-5 tests) only when Variant_Flag is 2, NoteRouting_MidiFlags bit 5 is\n"
     "clear and the MIDI IN mode is 1.  The MIDI IN processors use it for notes on the note-list path."),
    ("FCB126", "NoteRouting_ForReceivingPart",
     "(out, routing block, part): the tone-generator output (+0x02 and its +0x92 record, without the bit-5 test) and the\n"
     "recording track; MIDI OUT always 0xFF.  The MIDI IN processors' per-channel path: each part whose +0x22 is the\n"
     "frame's channel and whose record has bit 6 receives the frame."),
    # the note core: all-notes-off per source, the tone-generator senders, test-mode notes (FINDINGS-prom_a-note-frames.md section 8)
    ("FC8A8D", "PartNotes_ReleaseAllReceivedMidiIn",
     "T_PartNotes_ReleaseAllReceivedMidiIn: for each channel 0..31, each part that receives on it (block +0x22 = the channel, record +0x152 bit 6)\n"
     "releases its MIDI IN notes on it (PartNotes_BuildReleaseFrame, source 1, mask 7); the note-offs go to the tone\n"
     "generator and the record buffer.  Six call sites, in MidiFilePlay_Stop, MainTask_PhaseVector,\n"
     "Transport_StopAllRunning_SaveRegs2, LcdKeyRow1_SoundEditMemoryWrite, PartNotes_ReleaseReceivedOnScreenChange and Notes_ReleaseAllSources."),
    ("FC8B36", "NoteList_ReleaseAllSource0",
     "T_NoteList_ReleaseAllSource0: every note on source 0's note list becomes a note-off (NoteList_BuildReleaseAllFrame, source 0) and\n"
     "leaves the list (NoteList_ApplyFrame); each part of the voice mask then takes it as a note frame does\n"
     "(NoteFrame_SelectForPart, NoteRouting_ForPart, PartNotes_ApplyFrame, the three outputs).  In MIDI IN mode 1 the\n"
     "note-offs also go out as one MIDI OUT frame.  Its entry +5 byte, which Ring601850_ProcessNoteEvents fills with\n"
     "NoteRouting_ListChannel, is here the part loop's counter (XIZ-5) (0xFC8C61)."),
    ("FC8CE0", "PartNotes_ReleaseAllTrackNotes",
     "T_PartNotes_ReleaseAllTrackNotes: for each of the 16 tracks that has a part (BStore_TrackToPart), the track's notes on it (source 2,\n"
     "channel key = the track) become note-offs (PartNotes_BuildReleaseFrame, mask 7) sent to the tone generator and\n"
     "MIDI OUT.  Eleven callers through the slot, among them MainTask_PanelTimersTick and MainTask_PhaseVector."),
    ("FCA738", "PartFrame_SendPolyToToneGen",
     "(part, state, frame): each entry's tone-generator note (entry +3) goes over the link as [0x90 (| 8), part, note,\n"
     "velocity (+4)] and makes the state 0xFF; a note of 0xA0 sends [0xB0, part, 0x78, 0] instead (state 0x80) and 0xFF\n"
     "is skipped.  When the part's note list is empty after a note went out, [0xB0, part, 0x7B, 0] follows and the\n"
     "state is 0x80.  A = the new state.  On screen 0xDA the part byte is SoundSel_Group | 0xF0.  Status bit 3 is set\n"
     "when (0x7F02) & 0xF0 is 0x10 and the frame came by the note-list path (source 0, or source 1 in mode 2 or on\n"
     "NoteRouting_ListChannel in mode 1); what it means on the link is not established."),
    ("FCA8D4", "PartFrame_SendMonoToToneGen",
     "(part, state, frame), for a part whose tone-generator record has bit 6: one note at a time, the one at the tail of\n"
     "the part's note list (head +0x0D).  State 0x80 (silent): a note-on for it.  A different note sounding: its note-off\n"
     "and the new note-on in one 8-byte block.  List empty: the sounding note's note-off and [0xB0, part, 0x7B, 0].\n"
     "A = the note now sounding, or 0x80.  The status byte is built as in PartFrame_SendPolyToToneGen."),
    ("FCA276", "PartNotes_CollectFrame",
     "(frame with a source at +2 -- 0xFF any -- and a channel key at +3, outputs mask, part): PartNotes_BuildReleaseFrame\n"
     "without the release: each of the part's notes from that source with that key is copied into the frame as it is,\n"
     "and A has bit 0 / 1 / 2 when one still sounds on that output.  A node already released on all three returns to\n"
     "the pool and to PartNote_Budget."),
    ("FCB2F0", "PartNotes_ResoundOnToneGen",
     "T_PartNotes_ResoundOnToneGen (source, part): the part's notes from the source keyed by the part (PartNotes_CollectFrame, mask 1).\n"
     "When one sounds on the tone generator and the part plays tone-generator part = itself (block +0x02):\n"
     "[0xB0, part, 0x7B, 0], bits 6-7 set in each entry's tone-generator velocity, the part's state (0x6020D4) = 0x80,\n"
     "and the frame sent again (PartFrame_SendToToneGen).  What velocity bits 6-7 mean on the link is not established.\n"
     "Its one caller is Drawbar_SendPartParams, with source 0xFF."),
    ("F540F3", "Drawbar_SendPartParams",
     "(part), from the DRAWBAR screen's page and soft keys: [0xB0, part, 0x78, 0] over the link, then the seven bytes at\n"
     "0x2890.. as 6-byte messages [0x88, part, p, 0, value, 0] for p = 11, 12, 4, 5, 6, 7, 8, then T_PartNotes_ResoundOnToneGen\n"
     "(PartNotes_ResoundOnToneGen) with source 0xFF so that held notes sound again."),
    ("FC8FD7", "ToneGen_SendSoundSelNote",
     "T_ToneGen_SendSoundSelNote (-, note, velocity): [0x90, SoundSel_Group | 0xF0, note, velocity] over the link\n"
     "(T_Link_SendBlockIn32ByteChunks).  SineWaveCheck_ServiceSwitches plays notes 0x3C..0x3F with it, velocity 0x7F\n"
     "while a switch is held and 0 on release."),
    ("FC9016", "MidiOut_SendNote",
     "T_MidiOut_SendNote (channel 0..31, note, velocity): the 3-byte message [0x90 | channel & 0x0F, note, velocity] on MIDI OUT A\n"
     "(channels 0-15: Ring601432_PutBlock, MIDI_PostSendWork) or B (16-31: Ring60153C_PutBlock, _PortB), with\n"
     "interrupts held at level 6.  SineWaveCheck_ServiceSwitches sends channel 0 with it."),
    ("FE022E", "Notes_ReleaseAllSources",
     "saves XDE / XHL / XIX / XIZ and releases every sounding note of the three sources: T_NoteList_ReleaseAllSource0,\n"
     "T_PartNotes_ReleaseAllReceivedMidiIn, T_PartNotes_ReleaseAllTrackNotes.  Its caller is Notes_ReleaseAllSources_Call."),
    ("F9565A", "PartNotes_ReleaseReceivedOnScreenChange",
     "when UI_ScreenLatch differs from UI_ScreenLatch_Previous (the screen just changed): T_PartNotes_ReleaseAllReceivedMidiIn.\n"
     "Called by Paint_SineWaveCheckMode and through its directory slot 0xF40160."),
]

# labels placed where there was none -- python3 notes/prom_ab_read_names_2026_10_04.py --place
PLACED = [
    ("FBBA8E", "PartParam_StepSound",
     "PartParamStep_Ids00to1F[0], the field before VOLUME on the INTERNAL SOUND page: sets UI_RequestBits bit 3 and calls\n"
     "PartSound_StepBankGroupMember(part)."),
    ("FBBD4F", "PartParam_StepSubOut",
     "PartParamStep_Ids20to3F[1]: PartParam_StepMainOut's twin on byte 4 (SUB OUT) with PartParamField_SubOut, testing MAIN\n"
     "OUT (byte 3) instead of SUB OUT.  One difference: a step that lands on 1 is stepped again\n"
     "(`cp (XIZ-1),1 / jr nz` at 0xFBBD87), so the panel never selects SUB OUT 1."),
    ("F4F273", "PartSound_BankOrder",
     "the 11 bank codes in the order PartSound_StepBankGroupMember steps them: R1 0x00, R2 0x01, U1 0x08, U2 0x09,\n"
     "E1 0x10, RD 0x20, UD1 0x28, UD2 0x29, then the RE-MAP banks 0x18-0x1A (SoundSel_Bank's codes).  The stepper\n"
     "finds the current bank's index by a linear search of this table (0xF4F11A)."),
    ("F4F2B2", "PartSound_SignedStepTable",
     "16 signed steps 0..7, then 0, -1 .. -7, indexed by PartSound_StepIndexClamped's W'."),
    ("FC6027", "NoteRouting_QueueToneGenPartChanges",
     "for each of the 32 parts, kind 4 (part, new, old) when its tone-generator part (block +0x02) changed.  Nothing\n"
     "calls it: neither ROM holds 27 60 FC (a 24-bit pointer, call or jp to it) and no prom_a calr reaches it.  Kind 4's\n"
     "handler is a bare ret (NoteChange_PartToneGen_Nop)."),
]


# labels that already had a name, renamed -- python3 notes/prom_ab_read_names_2026_10_04.py --relabel
# (address, new name, header or "").  The old name is found at the address, so this file never quotes it.
RELABEL = [
    ("FC5C7C", "NoteRouting_CommitChanges",
     "CORRECTED 2026-10-04 (was NoteRouting_RebuildOutputs): it rebuilds no outputs.  The NoteRouting_Queue* routines compare the block with\n"
     "NoteRouting_Previous and queue one note-release record per difference (NoteChange_HandlerTable's kinds), the\n"
     "queue is applied (T_NoteRouting_ApplyQueuedChanges = NoteRouting_ApplyQueuedChanges), then the block becomes the previous one and\n"
     "NoteRouting_ChangeFlags (0x4C04) is cleared."),
    ("FC8DB2", "NoteChange_HandlerTable",
     "NoteChange_HandlerTable: the nine note-change kinds of NoteRouting_ChangeQueue, read by\n"
     "NoteRouting_ApplyQueuedChanges -- notes/FINDINGS-prom_a-note-frames.md section 7."),
    ("FC8D64", "NoteRouting_ApplyQueuedChanges_Loop", ""),
    ("FC8E5E", "NoteRouting_ApplyQueuedChanges_Skip", ""),
    ("FC8E6E", "NoteRouting_ApplyQueuedChanges_Return", ""),
    ("FC9726", "NoteChange_Kind1_Nop", ""),
    ("FC9853", "NoteChange_PartToneGen_Nop", ""),
]


def main():
    here = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    src = "".join(open(os.path.join(here, p), "rb").read().decode("latin-1")
                  for p in ("prom_a/wsa1_prom_a.s", "prom_b/wsa1_prom_b.s"))
    labels = set(re.findall(r'^([A-Za-z_][\w$]*):', src, re.M))   # one pass: a regex per row took a minute
    if "--relabel" in sys.argv:
        L = src.split("\n")
        at = {}
        for i, l in enumerate(L):
            m = re.match(r'^([A-Za-z_][\w$]*):', l)
            if not m:
                continue
            for x in L[i + 1:i + 6]:
                a = re.search(r';\s*(F[0-9A-F]{5})\b', x)
                if a and x.split(";")[0].strip() and not re.match(r'^[\w.$]+:', x):
                    at.setdefault(a.group(1), []).append(m.group(1))
                    break
        for o, n, hdr in RELABEL:
            if n in at.get(o, []):
                continue                          # applied already
            cur = at.get(o, [])
            assert len(cur) == 1, "%s: labels %s" % (o, cur)
            print("%s=%s%s" % (cur[0], n, ("|" + hdr.replace("\n", "\\n  ")) if hdr else ""))
        return
    if "--place" in sys.argv:
        for o, n, ev in PLACED:
            if n not in labels:
                print("%s=%s|%s: %s" % (o, n, n, ev.replace("\n", "\\n  ")))
        return
    for o, n, ev in ROWS:
        if "--args" in sys.argv:
            if "sub_" + o not in labels:
                continue                          # applied already
            print("sub_%s=%s|%s: %s" % (o, n, n, ev.replace("\n", "\\n  ")))
        else:
            print("sub_%-7s -> %s" % (o, n))
    if "--args" not in sys.argv:
        print("rows %d" % len(ROWS))


if __name__ == "__main__":
    main()
