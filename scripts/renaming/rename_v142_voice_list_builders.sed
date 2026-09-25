# v142 sub-CPU: labels of the two voice-list builders converted from .byte on 2026-09-25
# (scripts/converters/convert_v142_byte_block.py).  The symboliser named their internal
# targets after the nearest CALLED routine, which for these two uncalled routines is a
# neighbour; these rules give them their own names.
s/\bVoiceState_OpaqueData1_Code_Loop\b/Voice_Build_PartSlot_List_Loop/g
s/\bVoiceState_OpaqueData1_Code_Skip2\b/Voice_Build_PartSlot_List_Done/g
s/\bVoiceState_OpaqueData1_Code_Skip\b/Voice_Build_PartSlot_List_Next/g
s/\bVoiceState_OpaqueData2\b/Voice_Build_SoundingVoiceList/g
s/\bVoice_BuildOutputList_Loop2\b/Voice_Build_SoundingVoiceList_Loop/g
s/\bVoice_BuildOutputList_Loop3\b/Voice_Build_SoundingVoiceList_ChainLoop/g
s/\bVoice_BuildOutputList_Skip2\b/Voice_Build_SoundingVoiceList_Done/g
s/\bVoice_BuildOutputList_Skip\b/Voice_Build_SoundingVoiceList_Next/g
s/(0x00f4ec:24)/(Voice_CommandIndexTable:24)/g
s/(0x00f48c:24)/(Voice_PolyphonyLimits_Table:24)/g
