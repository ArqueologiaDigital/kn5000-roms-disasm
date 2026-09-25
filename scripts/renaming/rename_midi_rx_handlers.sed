# midi lane 2026-09-25: name the MIDI-receive handlers for what they receive.
# Evidence: MidiCC_LowRange_Table slot = status nibble (Bx CC, Cx program change,
# Dx channel pressure, Ex pitch bend); MidiCC_ExtendedRange_Table slot = CC function,
# mapped from the controller number by MidiCC_ChannelMappingData (headers in
# midi_dispatch_handlers.s).  Old=new pairs: scripts/renaming/midi_rx_handlers.map.
# `.set` lines are skipped: in v7 some old names are kept as aliases other files use.
/^[[:space:]]*\.set[[:space:]]\|v7 NAME DISPLACED/!s/\bMidiCC_Handler_CC3_TableLookup_Return\b/MidiRx_ControlChange_Return/g
/^[[:space:]]*\.set[[:space:]]/s/\(,.*\)\bMidiCC_Handler_CC3_TableLookup_Return\b/\1MidiRx_ControlChange_Return/
/^[[:space:]]*\.set[[:space:]]\|v7 NAME DISPLACED/!s/\bMidiCC_Handler_CC4_VoiceParam_Return\b/MidiRx_ProgramChange_Return/g
/^[[:space:]]*\.set[[:space:]]/s/\(,.*\)\bMidiCC_Handler_CC4_VoiceParam_Return\b/\1MidiRx_ProgramChange_Return/
/^[[:space:]]*\.set[[:space:]]\|v7 NAME DISPLACED/!s/\bMidiCC_Handler_CC5_VoiceParam_Return\b/MidiRx_ChannelPressure_Return/g
/^[[:space:]]*\.set[[:space:]]/s/\(,.*\)\bMidiCC_Handler_CC5_VoiceParam_Return\b/\1MidiRx_ChannelPressure_Return/
/^[[:space:]]*\.set[[:space:]]\|v7 NAME DISPLACED/!s/\bMidiCC_Handler_CC6_VoiceParam_Return\b/MidiRx_PitchBend_Return/g
/^[[:space:]]*\.set[[:space:]]/s/\(,.*\)\bMidiCC_Handler_CC6_VoiceParam_Return\b/\1MidiRx_PitchBend_Return/
/^[[:space:]]*\.set[[:space:]]\|v7 NAME DISPLACED/!s/\bMidiCC_Handler_CC3_TableLookup_Skip\b/MidiRx_ControlChange_Skip/g
/^[[:space:]]*\.set[[:space:]]/s/\(,.*\)\bMidiCC_Handler_CC3_TableLookup_Skip\b/\1MidiRx_ControlChange_Skip/
/^[[:space:]]*\.set[[:space:]]\|v7 NAME DISPLACED/!s/\bMidiCC_Handler_CC3_TableLookup\b/MidiRx_ControlChange/g
/^[[:space:]]*\.set[[:space:]]/s/\(,.*\)\bMidiCC_Handler_CC3_TableLookup\b/\1MidiRx_ControlChange/
/^[[:space:]]*\.set[[:space:]]\|v7 NAME DISPLACED/!s/\bMidiCC_Handler_CC4_VoiceParam\b/MidiRx_ProgramChange/g
/^[[:space:]]*\.set[[:space:]]/s/\(,.*\)\bMidiCC_Handler_CC4_VoiceParam\b/\1MidiRx_ProgramChange/
/^[[:space:]]*\.set[[:space:]]\|v7 NAME DISPLACED/!s/\bMidiCC_Handler_CC5_VoiceParam\b/MidiRx_ChannelPressure/g
/^[[:space:]]*\.set[[:space:]]/s/\(,.*\)\bMidiCC_Handler_CC5_VoiceParam\b/\1MidiRx_ChannelPressure/
/^[[:space:]]*\.set[[:space:]]\|v7 NAME DISPLACED/!s/\bMidiCC_Handler_CC6_VoiceParam\b/MidiRx_PitchBend/g
/^[[:space:]]*\.set[[:space:]]/s/\(,.*\)\bMidiCC_Handler_CC6_VoiceParam\b/\1MidiRx_PitchBend/
/^[[:space:]]*\.set[[:space:]]\|v7 NAME DISPLACED/!s/\bMidiCC_VoiceParam_11_MidEntry\b/MidiCC_RxFunc13_MidEntry/g
/^[[:space:]]*\.set[[:space:]]/s/\(,.*\)\bMidiCC_VoiceParam_11_MidEntry\b/\1MidiCC_RxFunc13_MidEntry/
/^[[:space:]]*\.set[[:space:]]\|v7 NAME DISPLACED/!s/\bMidiSerial_ParseStatus_Data\b/MidiRx_SystemMsgDispatch/g
/^[[:space:]]*\.set[[:space:]]/s/\(,.*\)\bMidiSerial_ParseStatus_Data\b/\1MidiRx_SystemMsgDispatch/
/^[[:space:]]*\.set[[:space:]]\|v7 NAME DISPLACED/!s/\bMidiCC_VoiceParam_10_Return\b/MidiCC_RxFunc12_Return/g
/^[[:space:]]*\.set[[:space:]]/s/\(,.*\)\bMidiCC_VoiceParam_10_Return\b/\1MidiCC_RxFunc12_Return/
/^[[:space:]]*\.set[[:space:]]\|v7 NAME DISPLACED/!s/\bMidiCC_VoiceParam_11_Return\b/MidiCC_RxFunc13_Return/g
/^[[:space:]]*\.set[[:space:]]/s/\(,.*\)\bMidiCC_VoiceParam_11_Return\b/\1MidiCC_RxFunc13_Return/
/^[[:space:]]*\.set[[:space:]]\|v7 NAME DISPLACED/!s/\bMidiCC_VoiceParam_12_Return\b/MidiCC_RxFunc14_Return/g
/^[[:space:]]*\.set[[:space:]]/s/\(,.*\)\bMidiCC_VoiceParam_12_Return\b/\1MidiCC_RxFunc14_Return/
/^[[:space:]]*\.set[[:space:]]\|v7 NAME DISPLACED/!s/\bMidiCC_VoiceParam_13_Return\b/MidiCC_RxFunc15_Return/g
/^[[:space:]]*\.set[[:space:]]/s/\(,.*\)\bMidiCC_VoiceParam_13_Return\b/\1MidiCC_RxFunc15_Return/
/^[[:space:]]*\.set[[:space:]]\|v7 NAME DISPLACED/!s/\bMidiCC_VoiceParam_0_Return\b/MidiCC_RxCC64_Sustain_Return/g
/^[[:space:]]*\.set[[:space:]]/s/\(,.*\)\bMidiCC_VoiceParam_0_Return\b/\1MidiCC_RxCC64_Sustain_Return/
/^[[:space:]]*\.set[[:space:]]\|v7 NAME DISPLACED/!s/\bMidiCC_VoiceParam_3_Return\b/MidiCC_RxCC1_Modulation_Return/g
/^[[:space:]]*\.set[[:space:]]/s/\(,.*\)\bMidiCC_VoiceParam_3_Return\b/\1MidiCC_RxCC1_Modulation_Return/
/^[[:space:]]*\.set[[:space:]]\|v7 NAME DISPLACED/!s/\bMidiCC_VoiceParam_4_Return\b/MidiCC_RxCC7_Volume_Return/g
/^[[:space:]]*\.set[[:space:]]/s/\(,.*\)\bMidiCC_VoiceParam_4_Return\b/\1MidiCC_RxCC7_Volume_Return/
/^[[:space:]]*\.set[[:space:]]\|v7 NAME DISPLACED/!s/\bMidiCC_VoiceParam_5_Return\b/MidiCC_RxCC11_Expression_Return/g
/^[[:space:]]*\.set[[:space:]]/s/\(,.*\)\bMidiCC_VoiceParam_5_Return\b/\1MidiCC_RxCC11_Expression_Return/
/^[[:space:]]*\.set[[:space:]]\|v7 NAME DISPLACED/!s/\bMidiCC_VoiceParam_6_Return\b/MidiCC_RxCC10_Pan_Return/g
/^[[:space:]]*\.set[[:space:]]/s/\(,.*\)\bMidiCC_VoiceParam_6_Return\b/\1MidiCC_RxCC10_Pan_Return/
/^[[:space:]]*\.set[[:space:]]\|v7 NAME DISPLACED/!s/\bMidiCC_VoiceParam_7_Return\b/MidiCC_RxCC93_Chorus_Return/g
/^[[:space:]]*\.set[[:space:]]/s/\(,.*\)\bMidiCC_VoiceParam_7_Return\b/\1MidiCC_RxCC93_Chorus_Return/
/^[[:space:]]*\.set[[:space:]]\|v7 NAME DISPLACED/!s/\bMidiCC_VoiceParam_8_Return\b/MidiCC_RxCC94_Celeste_Return/g
/^[[:space:]]*\.set[[:space:]]/s/\(,.*\)\bMidiCC_VoiceParam_8_Return\b/\1MidiCC_RxCC94_Celeste_Return/
/^[[:space:]]*\.set[[:space:]]\|v7 NAME DISPLACED/!s/\bMidiCC_VoiceParam_9_Return\b/MidiCC_RxCC91_Reverb_Return/g
/^[[:space:]]*\.set[[:space:]]/s/\(,.*\)\bMidiCC_VoiceParam_9_Return\b/\1MidiCC_RxCC91_Reverb_Return/
/^[[:space:]]*\.set[[:space:]]\|v7 NAME DISPLACED/!s/\bMidiCC_VoiceParam_1_Return\b/MidiCC_RxFunc08_Return/g
/^[[:space:]]*\.set[[:space:]]/s/\(,.*\)\bMidiCC_VoiceParam_1_Return\b/\1MidiCC_RxFunc08_Return/
/^[[:space:]]*\.set[[:space:]]\|v7 NAME DISPLACED/!s/\bMidiCC_VoiceParam_2_Return\b/MidiCC_RxFunc09_Return/g
/^[[:space:]]*\.set[[:space:]]/s/\(,.*\)\bMidiCC_VoiceParam_2_Return\b/\1MidiCC_RxFunc09_Return/
/^[[:space:]]*\.set[[:space:]]\|v7 NAME DISPLACED/!s/\bMidiCC_VoiceParam_9_Skip\b/MidiCC_RxCC91_Reverb_Skip/g
/^[[:space:]]*\.set[[:space:]]/s/\(,.*\)\bMidiCC_VoiceParam_9_Skip\b/\1MidiCC_RxCC91_Reverb_Skip/
/^[[:space:]]*\.set[[:space:]]\|v7 NAME DISPLACED/!s/\bMidiCC_VoiceParam_10\b/MidiCC_RxFunc12/g
/^[[:space:]]*\.set[[:space:]]/s/\(,.*\)\bMidiCC_VoiceParam_10\b/\1MidiCC_RxFunc12/
/^[[:space:]]*\.set[[:space:]]\|v7 NAME DISPLACED/!s/\bMidiCC_VoiceParam_11\b/MidiCC_RxFunc13/g
/^[[:space:]]*\.set[[:space:]]/s/\(,.*\)\bMidiCC_VoiceParam_11\b/\1MidiCC_RxFunc13/
/^[[:space:]]*\.set[[:space:]]\|v7 NAME DISPLACED/!s/\bMidiCC_VoiceParam_12\b/MidiCC_RxFunc14/g
/^[[:space:]]*\.set[[:space:]]/s/\(,.*\)\bMidiCC_VoiceParam_12\b/\1MidiCC_RxFunc14/
/^[[:space:]]*\.set[[:space:]]\|v7 NAME DISPLACED/!s/\bMidiCC_VoiceParam_13\b/MidiCC_RxFunc15/g
/^[[:space:]]*\.set[[:space:]]/s/\(,.*\)\bMidiCC_VoiceParam_13\b/\1MidiCC_RxFunc15/
/^[[:space:]]*\.set[[:space:]]\|v7 NAME DISPLACED/!s/\bMidiCC_VoiceParam_0\b/MidiCC_RxCC64_Sustain/g
/^[[:space:]]*\.set[[:space:]]/s/\(,.*\)\bMidiCC_VoiceParam_0\b/\1MidiCC_RxCC64_Sustain/
/^[[:space:]]*\.set[[:space:]]\|v7 NAME DISPLACED/!s/\bMidiCC_VoiceParam_3\b/MidiCC_RxCC1_Modulation/g
/^[[:space:]]*\.set[[:space:]]/s/\(,.*\)\bMidiCC_VoiceParam_3\b/\1MidiCC_RxCC1_Modulation/
/^[[:space:]]*\.set[[:space:]]\|v7 NAME DISPLACED/!s/\bMidiCC_VoiceParam_4\b/MidiCC_RxCC7_Volume/g
/^[[:space:]]*\.set[[:space:]]/s/\(,.*\)\bMidiCC_VoiceParam_4\b/\1MidiCC_RxCC7_Volume/
/^[[:space:]]*\.set[[:space:]]\|v7 NAME DISPLACED/!s/\bMidiCC_VoiceParam_5\b/MidiCC_RxCC11_Expression/g
/^[[:space:]]*\.set[[:space:]]/s/\(,.*\)\bMidiCC_VoiceParam_5\b/\1MidiCC_RxCC11_Expression/
/^[[:space:]]*\.set[[:space:]]\|v7 NAME DISPLACED/!s/\bMidiCC_VoiceParam_6\b/MidiCC_RxCC10_Pan/g
/^[[:space:]]*\.set[[:space:]]/s/\(,.*\)\bMidiCC_VoiceParam_6\b/\1MidiCC_RxCC10_Pan/
/^[[:space:]]*\.set[[:space:]]\|v7 NAME DISPLACED/!s/\bMidiCC_VoiceParam_7\b/MidiCC_RxCC93_Chorus/g
/^[[:space:]]*\.set[[:space:]]/s/\(,.*\)\bMidiCC_VoiceParam_7\b/\1MidiCC_RxCC93_Chorus/
/^[[:space:]]*\.set[[:space:]]\|v7 NAME DISPLACED/!s/\bMidiCC_VoiceParam_8\b/MidiCC_RxCC94_Celeste/g
/^[[:space:]]*\.set[[:space:]]/s/\(,.*\)\bMidiCC_VoiceParam_8\b/\1MidiCC_RxCC94_Celeste/
/^[[:space:]]*\.set[[:space:]]\|v7 NAME DISPLACED/!s/\bMidiCC_VoiceParam_9\b/MidiCC_RxCC91_Reverb/g
/^[[:space:]]*\.set[[:space:]]/s/\(,.*\)\bMidiCC_VoiceParam_9\b/\1MidiCC_RxCC91_Reverb/
/^[[:space:]]*\.set[[:space:]]\|v7 NAME DISPLACED/!s/\bMidiCC_VoiceParam_1\b/MidiCC_RxFunc08/g
/^[[:space:]]*\.set[[:space:]]/s/\(,.*\)\bMidiCC_VoiceParam_1\b/\1MidiCC_RxFunc08/
/^[[:space:]]*\.set[[:space:]]\|v7 NAME DISPLACED/!s/\bMidiCC_VoiceParam_2\b/MidiCC_RxFunc09/g
/^[[:space:]]*\.set[[:space:]]/s/\(,.*\)\bMidiCC_VoiceParam_2\b/\1MidiCC_RxFunc09/
