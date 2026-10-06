# Panel-memory recall (technics-docs panel-memory-factory-data.md): ui/bitmap_out_routines.s opens with a real VGA
# palette loader and the BitMapOut_ prefix spread over the panel-memory code after it.  The slot table is the 80
# panel memories (RAM 0x1ED400 + 960*n) + index 80 = the Music Stylist mirror at RAM 0x3C2C4; recall backs the live
# panel (0xF9A0) up to RAM 0x3C8E4, copies the slot in, and puts back what RAM 0x8D52 / parameter 0x302 say to keep.
s/\bBitMapOut_CopyPreset9_Execute_Data\b/PanelMemory_SlotAddresses/g
s/\bBitMapOut_SnapshotFromROM\b/PanelMemory_Recall/g
s/\bBitMapOut_Snapshot_Clamp50\b/PanelMemory_Recall_CheckSlot/g
s/\bBitMapOut_Snapshot_Execute\b/PanelMemory_Recall_Slot/g
s/\bBitMapOut_Snapshot_RestorePartial\b/PanelMemory_Recall_KeepStyle/g
s/\bBitMapOut_Snapshot_RestoreFull\b/PanelMemory_Recall_Records/g
s/\bBitMapOut_Snapshot_PostProcess\b/PanelMemory_Recall_Finish/g
s/\bBitMapOut_Snapshot_CheckActive\b/PanelMemory_Recall_CheckActive/g
s/\bBitMapOut_Snapshot_SetFlags\b/PanelMemory_Recall_NoSlot/g
s/\bBitMapOut_SaveDisplayToROM\b/PanelMemory_BackupLivePanel/g
s/\bBitMapOut_CopyROMToWorkspace\b/PanelMemory_CopySlotToLivePanel/g
s/\bBitMapOut_PartialRestore\b/PanelMemory_RecallKeepStyle/g
s/\bBitMapOut_RestoreVoiceFields_CheckNot80\b/PanelMemory_RecallKeepAccompaniment_CheckNot80/g
s/\bBitMapOut_RestoreVoiceFields\b/PanelMemory_RecallKeepAccompaniment/g
s/\bBitMapOut_RestoreFullVoice\b/PanelMemory_RecallRecords/g
s/\bBitMapOut_RestoreFull_FieldLoop\b/PanelMemory_RecallRecords_FieldLoop/g
s/\bBitMapOut_RestoreFull_CopyField\b/PanelMemory_RecallRecords_CopyField/g
s/\bBitMapOut_RestoreFull_CheckType0D\b/PanelMemory_RecallRecords_CheckByte13/g
s/\bBitMapOut_RestoreFull_SkipField\b/PanelMemory_RecallRecords_KeepByte/g
s/\bBitMapOut_RestoreFull_DefaultCopy\b/PanelMemory_RecallRecords_CopyByte/g
s/\bBitMapOut_RestoreFull_NextField\b/PanelMemory_RecallRecords_NextByte/g
s/\bBitMapOut_RestoreFull_FieldDone\b/PanelMemory_RecallRecords_NextRecord/g
s/\bBitMapOut_RestoreFull_CheckEnd\b/PanelMemory_RecallRecords_CheckEnd/g
