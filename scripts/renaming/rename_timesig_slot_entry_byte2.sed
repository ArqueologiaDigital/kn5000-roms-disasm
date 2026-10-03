# accompaniment_engine.s v10/v9 0xF661A9: 34, 42, 50, 58 = byte +2 of the four 8-byte entries of the
# AccPatch slot record, indexed by (0x39AA); was decoded as `ld b, 42 / ldw de, 15930`.
s/\bTimeSig_DisplayStrings_Code5\b/TimeSig_SlotEntryByte2Offsets/g
