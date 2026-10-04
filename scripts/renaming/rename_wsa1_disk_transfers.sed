# WSA1 naming step (session 53b889a2, wsa1_rename.py)
s/\bsub_FE2AA9\b/DiskSave_StreamLinkRamToFile/g
s/\bsub_FE20E1\b/DiskLoad_StreamFileToLinkRam/g
s/\bsub_FE22EF\b/DiskLoad_ReadKilobyteToWindowSlot/g
s/\bsub_FE2CFF\b/Disk_SetWindowStartToStaging/g
s/\bsub_FE2D4F\b/Disk_SetWindowLengthToLinkChunk/g
s/\bsub_FE2D5E\b/Disk_SetWindowLengthToKilobyte/g
s/\bsub_FE2D09\b/Disk_SetWindowStartToFileBuffer/g
s/\bsub_FE2CF5\b/Disk_SetWindowStartToPanelImage/g
s/\bsub_FE2D7C\b/Disk_SetWindowEndToPanelImageEnd/g
s/\bsub_FE2DBC\b/Disk_SetPanelImageLength/g
s/\bsub_FE1FAB\b/DiskLoad_CopyFromFileBuffer/g
s/\bsub_FE1E93\b/DiskLoad_SaveRam7FC0/g
s/\bsub_FE1EC3\b/DiskLoad_RestoreRam7FC0/g
s/\bsub_FE2DDD\b/DiskLoad_CheckLswHeader/g
