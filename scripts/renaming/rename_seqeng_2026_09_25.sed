# lane seqeng 2026-09-25: names that described the wrong thing
# FloppyIO_SwitchboardChannelPtrs is the 16-entry channel-record pointer table
# read by SeqPlay_InitChannelParams (see its header in smf_tonegen_core.s).
# comment-only lines keep the old names (they record history): skip them
/^[[:space:]]*;/b
s/\bFloppyIO_SwitchboardChannelPtrs\b/ChannelRecord_PtrTable/g
# the routine at VoiceChannel_ParamTable1 +0x80 now has a label of its own
s/\bVoiceChannel_ParamTable1_0x80\b/VoiceChannel_SetRecordField3/g
# SeqPos_DataBlock is a routine: SeqVoice_InitEntry run for the bank index at
# 0xFFE3 (see its header in sequencer_engine.s)
s/\bSeqPos_DataBlock\b/SeqVoice_InitEntryForCurrentBank/g
# AccPlay_NoteSetType91 is where BOTH status values (0x90 and 0x91) are written;
# the jump to it is taken when the status stays 0x90
s/\bAccPlay_NoteSetType91\b/AccPlay_NoteWriteStatusByte/g
