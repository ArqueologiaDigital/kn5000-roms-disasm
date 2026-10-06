# Panel TLV lookups and per-part companion records (docs/kn-disk-file-formats.md, "The record container" and
# "The C0..D4 run is one companion block PER PART").  0xEDAE64 is the tag -> payload address table, 0xEDB264
# the part -> companion-record table; the routines that index them and the one that refreshes every companion
# from its part's sound were named Audio_/Voice_/ToneGen_ by guess.  See rename_panel_tlv_schema.sed.
s/\bAudio_InitAllDefaults_Data_2\b/PanelTlv_CompanionByPart/g
s/\bAudio_InitAllDefaults_Data\b/PanelTlv_PayloadByTag/g
s/\bVoiceData_LookupPtrByIndex\b/PanelTlv_PayloadOfTag/g
s/\bVoiceData_LookupPtrByChannel\b/PanelTlv_CompanionOfPart/g
s/\bVoiceLookup_CheckRhythm\b/PanelTlv_CompanionOfPart_Style/g
s/\bVoiceLookup_ReturnInvalid\b/PanelTlv_CompanionOfPart_None/g
s/\bVoice_InitAllChannelEntries\b/PanelTlv_ResolvePartCompanions/g
s/\bVoice_InitChannelLoop_Data\b/PanelTlv_CompanionPartTags/g
s/\bVoice_InitChannelLoop\b/PanelTlv_ResolvePartCompanions_Loop/g
s/\bVoice_InitChannelNext\b/PanelTlv_ResolvePartCompanions_Next/g
s/\bToneGen_InitAllChannelEntries_Skip\b/PanelTlv_ResolvePartCompanions_Entry/g
s/\bToneGen_ApplyMaskTable_Data\b/PanelTlv_ResetMasks/g
s/\bToneGen_ApplyMaskTable\b/PanelTlv_ApplyResetMasks/g
s/\bToneGen_ApplyMaskLoop\b/PanelTlv_ApplyResetMasks_Loop/g
