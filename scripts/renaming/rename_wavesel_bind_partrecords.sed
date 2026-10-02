# WaveSel_Bind_PartRecords was never a symbol: the tonedb lane's name for the sub-CPU routine
# the subcpu lane labelled VoiceParam_Update (0x032112), whose header says it binds a part's
# tone record and partial blocks (partial p -> patchrec + 0x66 + 0x51*rank) and which holds
# both callers 0x032253 / 0x032345 of VoiceBuf_TypeSelector_MatchEpilogue.
s/\(^\|[^A-Za-z0-9_]\)WaveSel_Bind_PartRecords\($\|[^A-Za-z0-9_]\)/\1VoiceParam_Update\2/g
