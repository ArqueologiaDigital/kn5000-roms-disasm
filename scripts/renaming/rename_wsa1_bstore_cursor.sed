# WSA1 prom_a: save/restore of the song-store cursor (BStore_CursorBlock/Offset + (0x601F05..07)) in two RAM slots.
# (prom_b already has a different BStore_SaveCursor, hence the CursorSlot names.)
s/\bsub_FE8CEE\b/BStore_CursorSlot_Save/g
s/\bsub_FE8D15\b/BStore_CursorSlot_Restore/g
s/\bsub_FE8BF8\b/BStore_CursorSlot_RestoreMark/g
