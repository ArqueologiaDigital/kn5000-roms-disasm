# midi lane 2026-09-25.  MidiSerial_CmdJumpTable is indexed by the low nibble of
# a SYSTEM status byte (F0..FF, MidiSerial_ParseStatus_Data).  Slot 2 (F2 = Song
# Position Pointer, two data bytes) stores (0x9635) -> (0x42D) and (0x9636) ->
# (0x42E); slot 3 (F3 = Song Select, one data byte) stores (0x9635) -> (0x42C).
# Neither is a "system reset" (that is FF) nor generic "system common".
/^[[:space:]]*;/!s/\bMidiSerial_HandleSysReset_Data\b/MidiSerial_HandleSongPosition/g
/^[[:space:]]*;/!s/\bMidiSerial_HandleSysCommon_Data\b/MidiSerial_HandleSongSelect/g
