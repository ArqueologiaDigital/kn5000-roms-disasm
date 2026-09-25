# lane seqeng 2026-09-25: the 8.3 path-component parser (v10/v9 label set)
# comment-only lines keep the old names (they record history): skip them
/^[[:space:]]*;/b
/^SeqByteBlock_EffectsSeqData:$/d
/^SeqByteBlock_EffectsSeqDotExt:$/d
s/\bSeqByteBlock_PathNormalize_Helper3\b/FatPath_Next83Component/g
s/\bSeqByteBlock_PathNormalize_Helper3_Loop\b/FatPath_Next83Component_Restart/g
s/\bSeqStep_FileSectorPopReturn_Entry3\b/FatPath_Next83Component_SkipLeadSep/g
s/\bSeqByteBlock_PathNormalize_Helper3_Skip\b/FatPath_Next83Component_Start/g
s/\bSeqByteBlock_PathNormalize_Helper3_Loop2\b/FatPath_Next83Component_CharLoop/g
s/\bSeqStep_FileSectorPopReturn_Skip9\b/FatPath_Next83Component_AtSeparator/g
s/\bSeqStep_FileSectorPopReturn_Skip10\b/FatPath_Next83Component_CheckDot/g
s/\bSeqStep_FileSectorPopReturn_Skip11\b/FatPath_Next83Component_ToExtension/g
s/\bSeqByteBlock_TechnichordCfgA\b/FatPath_Next83Component_StoreChar/g
s/\bSeqByteBlock_PathNormalize_Helper3_Join\b/FatPath_Next83Component_NextChar/g
s/\bSeqByteBlock_PathNormalize_Join\b/FatPath_Next83Component_Terminator/g
s/\bSeqByteBlock_PathNormalize_Helper3_Skip2\b/FatPath_Next83Component_MoreFollows/g
s/\bSeqByteBlock_PathNormalize_Helper3_Skip3\b/FatPath_Next83Component_CheckEnd/g
s/\bSeqByteBlock_PathNormalize_Skip\b/FatPath_Next83Component_CheckDotEntry/g
s/\bSeqByteBlock_PathNormalize_Epilogue13\b/FatPath_Next83Component_Return/g
# FAT primitives (see their headers in smf_event_processor.s)
s/\bSeqStep_FileSectorError\b/Fat_ReadEntry/g
s/\bSeqByteBlock_PathNormalize_Helper\b/Fat_CountContiguousClusters/g
s/\bSeqByteBlock_PathNormalize_Helper_Skip\b/Fat_CountContiguousClusters_NonEmpty/g
s/\bSeqStep_FileSectorPopReturn_Loop\b/Fat_CountContiguousClusters_Next/g
s/\bSeqByteBlock_PathNormalize_Helper_Entry\b/Fat_CountContiguousClusters_ReadFat/g
s/\bSeqByteBlock_PathNormalize_Helper_Skip2\b/Fat_CountContiguousClusters_Done/g
s/\bSeqByteBlock_PathNormalize_Helper_Epilogue\b/Fat_CountContiguousClusters_Return/g
