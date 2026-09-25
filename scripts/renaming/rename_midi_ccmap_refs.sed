# midi lane 2026-09-25: point the readers of the MIDI receive mapping tables at
# the semantic labels now defined in midi/midi_dispatch_handlers.s instead of the
# positional `.set` aliases (shared/positional_labels.s, which still defines the
# old names -- now unreferenced -- and belongs to another lane).
# Evidence for each name: the header above each label in midi_dispatch_handlers.s.
# Comment lines are left alone (/^[[:space:]]*;/!): they are preserved text.
/^[[:space:]]*;/!s/\bMidiCC_ChannelMappingData_0x80\b/MidiCC_FunctionRxFilter/g
/^[[:space:]]*;/!s/\bMidiCC_ChannelMappingData_0xE0\b/MidiCC_PartTargets_CC64_Sustain/g
/^[[:space:]]*;/!s/\bMidiCC_ChannelMappingData_0x140\b/MidiCC_PartTargets_Func08/g
/^[[:space:]]*;/!s/\bMidiCC_ChannelMappingData_0x1A0\b/MidiCC_PartTargets_Func09/g
/^[[:space:]]*;/!s/\bMidiCC_ChannelMappingData_0x200\b/MidiCC_PartTargets_CC1_Modulation/g
/^[[:space:]]*;/!s/\bMidiCC_ChannelMappingData_0x260\b/MidiCC_PartTargets_CC7_Volume/g
/^[[:space:]]*;/!s/\bMidiCC_ChannelMappingData_0x2C0\b/MidiCC_PartTargets_CC11_Expression/g
/^[[:space:]]*;/!s/\bMidiCC_ChannelMappingData_0x320\b/MidiCC_PartTargets_CC10_Pan/g
/^[[:space:]]*;/!s/\bMidiCC_ChannelMappingData_0x380\b/MidiCC_PartTargets_CC93_Chorus/g
/^[[:space:]]*;/!s/\bMidiCC_ChannelMappingData_0x3E0\b/MidiCC_PartTargets_CC94_Celeste/g
/^[[:space:]]*;/!s/\bMidiCC_ChannelMappingData_0x440\b/MidiCC_PartTargets_CC91_Reverb/g
/^[[:space:]]*;/!s/\bMidiCC_ChannelMappingData_0x560\b/MidiCC_PartTargets_Func12/g
/^[[:space:]]*;/!s/\bMidiCC_ChannelMappingData_0x5C0\b/MidiCC_PartTargets_Func13/g
/^[[:space:]]*;/!s/\bMidiCC_ChannelMappingData_0x620\b/MidiCC_PartTargets_Func14/g
/^[[:space:]]*;/!s/\bMidiCC_ChannelMappingData_0x680\b/MidiCC_PartTargets_Func15/g
/^[[:space:]]*;/!s/\bMidiCC_ChannelMappingData_0x6E0\b/MidiCC_PartTargets_CC121_ResetAll/g
/^[[:space:]]*;/!s/^\(\s*ld\s\+xix, \)0x00fd1587$/\1MidiCC_PartTargets_CC120_AllSoundOff/
/^[[:space:]]*;/!s/\bMidiCC_ChannelMappingData_0x760\b/MidiPC_PartTargets/g
/^[[:space:]]*;/!s/\bMidiCC_ChannelMappingData_0x7A0\b/MidiPB_PartTargets/g
/^[[:space:]]*;/!s/\bMidiCC_ChannelMappingData_0x7E0\b/MidiCP_PartTargets/g
/^[[:space:]]*;/!s/\bMidiCC_ChannelMappingData_0x820\b/MidiCC_PartSelector_DataEntry/g
/^[[:space:]]*;/!s/\bMidiCC_ChannelMappingData_0x840\b/MidiCC_PartTargets_BankSelect/g
/^[[:space:]]*;/!s/\bMidiSerial_StatusTable_0x1\b/MidiSerial_StatusHandlers/g
/^[[:space:]]*;/!s/\bMidiCC_Handler_BitManipulation_0x45\b/MidiCC_CC83_ValueMap/g
/^[[:space:]]*;/!s/\bMidiCC_Handler_RangeCheck_0x3F\b/MidiCC_CC80_ValueMap/g
/^[[:space:]]*;/!s/\bMidiCC_Handler_ChannelMapping_0x60\b/MidiCC_CC82_Records/g
/^[[:space:]]*;/!s/\bPanelEvt_Dispatch6_TableAndHandlers_0x1\b/PanelEvt_Dispatch6_Handlers/g
/^[[:space:]]*;/!s/\bPanelEvt_Dispatch6_TableAndHandlers_0x49\b/PanelEvt_D6Slot3_ValueMap/g
/^[[:space:]]*;/!s/\bPanelEvt_Dispatch6_TableAndHandlers_0xAC\b/PanelEvt_D6Slot5_BitMapA/g
/^[[:space:]]*;/!s/\bPanelEvt_Dispatch6_TableAndHandlers_0xB5\b/PanelEvt_D6Slot5_BitMapB/g
/^[[:space:]]*;/!s/\bPanelEvt_Dispatch11_TableAndHandlers_0x1\b/PanelEvt_Dispatch11_Handlers/g
/^[[:space:]]*;/!s/\bPanelEvt_Dispatch11_TableAndHandlers_0x5F\b/PanelEvt_D11Slot11_ValueMap/g
/^[[:space:]]*;/!s/\bPanelEvt_Handler_4_DualValueCheck_0x77\b/MidiDispatchCC_HandlerTable/g
/^[[:space:]]*;/!s/\bPanelEvt_Handler_4_DualValueCheck_0x377\b/MidiCC_FunctionToCCNumber/g
