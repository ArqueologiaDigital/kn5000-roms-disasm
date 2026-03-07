# Rename data record targets for tables whose entries point to data, not code
# These tables were initially identified as "jump tables" but actually contain
# pointers to parameter/descriptor data records.

# === BrassSound_SamplePtr_Table targets (77 entries at 0xE06BB0) ===
# Each entry is a 3-byte record: sample_id, bank, terminator(0xFF)
# Entries at E06DB0-E06EA6, spaced 3 bytes apart
# Only renaming a representative set — too many to rename individually
# (The pattern is clear: sequential 3-byte sample parameter records)

# === Naka_EventHandler_Table targets (40 entries at 0xEE86D0) ===
# First 33 entries: 8-byte records starting with 0x16 0x40 0xfb 0x00 0xff 0xff 0xff 0xff
# Last 7 entries: 4-byte 0xFF fill records
# These are event handler registration slots (likely populated at runtime)
# Sequential labels EE89D1-EE8AED, spaced 8 or 4 bytes apart

# === TuningSystem_Handler_Table targets (15 entries at 0xF13447) ===
# Each entry is a small data record (5-15 bytes) encoding UI parameter descriptors
# for tuning system settings. Contains register IDs (0x61-0x6f), value ranges,
# and display coordinates.

# Tuning system parameter records — rename to reflect they're data, not code
# Group 1: Simple 11-byte records (type 0x05, display type 0x0b)
s/LABEL_F131E5\b/TuningSys_Param_01/g
s/LABEL_F131F0\b/TuningSys_Param_02/g
s/LABEL_F1320A\b/TuningSys_Param_04/g
s/LABEL_F13215\b/TuningSys_Param_05/g
s/LABEL_F1322F\b/TuningSys_Param_07/g
s/LABEL_F1323A\b/TuningSys_Param_08/g
s/LABEL_F13254\b/TuningSys_Param_10/g
s/LABEL_F1325F\b/TuningSys_Param_11/g

# Group 2: Extended 15-byte records (type 0x02, display type 0x0f, include sub-table ptr)
s/LABEL_F131FB\b/TuningSys_Param_03/g
s/LABEL_F13220\b/TuningSys_Param_06/g
s/LABEL_F13245\b/TuningSys_Param_09/g
s/LABEL_F1326A\b/TuningSys_Param_12/g
s/LABEL_F13279\b/TuningSys_Param_13/g

# Special entry with tuning system name strings and coordinate data
s/LABEL_F13288\b/TuningSys_Param_NamesAndCoords/g
s/LABEL_F132B4\b/TuningSys_Param_ModeSelect/g
