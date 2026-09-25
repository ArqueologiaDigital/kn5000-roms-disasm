# Rename the 974 SET chunks of table_data/tone_database_aux.s (2026-09-25).
# They were called ToneEnv_RecNNN_A/_B from an early "envelope" reading that the
# chunk header itself retracted on 2026-08-21 ("Nothing in these chunks is an
# envelope").  NNN is the SET (descriptor) number; A is the SET's key map, B its
# zone-record array.
#   LC_ALL=C sed -i -f scripts/renaming/rename_tonedb_set_chunks.sed table_data/tone_database_aux.s
s/\bToneEnv_Rec\([0-9][0-9][0-9]\)_A\b/ToneSet_\1_KeyMap/g
s/\bToneEnv_Rec\([0-9][0-9][0-9]\)_B\b/ToneSet_\1_Zones/g
# The zone-record row macros introduced the same day follow the chunks' name.
s/\bToneEnvZone\([46]\)\b/ToneSetZone\1/g
