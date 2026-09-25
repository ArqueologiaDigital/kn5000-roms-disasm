# lane seqeng 2026-09-25: names that described the wrong thing
# FloppyIO_SwitchboardChannelPtrs is the 16-entry channel-record pointer table
# read by SeqPlay_InitChannelParams (see its header in smf_tonegen_core.s).
s/\bFloppyIO_SwitchboardChannelPtrs\b/ChannelRecord_PtrTable/g
# the routine at VoiceChannel_ParamTable1 +0x80 now has a label of its own
s/\bVoiceChannel_ParamTable1_0x80\b/VoiceChannel_SetRecordField3/g
