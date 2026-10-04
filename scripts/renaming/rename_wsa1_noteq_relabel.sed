# WSA1 naming step (session 53b889a2, wsa1_rename.py)
s/\bNoteRouting_RebuildOutputs\b/NoteRouting_CommitChanges/g
s/\bJumpTable_FC8DB2\b/NoteChange_HandlerTable/g
s/\bsub_FC80E1_Loop\b/NoteRouting_ApplyQueuedChanges_Loop/g
s/\bJumpTable_FC8DB2_Code_Skip\b/NoteRouting_ApplyQueuedChanges_Skip/g
s/\bJumpTable_FC8DB2_Code_Skip2\b/NoteRouting_ApplyQueuedChanges_Return/g
s/\bsub_FC8DE6_Nop\b/NoteChange_Kind1_Nop/g
s/\bsub_FC8E13_Nop\b/NoteChange_PartToneGen_Nop/g
