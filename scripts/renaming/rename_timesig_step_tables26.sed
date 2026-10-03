# The two 33-entry remap tables of (0x34D6) used when the position in (0x34EF) crosses 26
# (accompaniment_engine.s; v10/v9 0xF65CAF / 0xF65CD0).  Were positional names on bytes
# decoded as `calr ...` / `max ...` code.  Same shape as TimeSig_StepUpTable15/StepDownTable15.
s/\bTimeSig_DisplayStrings_Code3\b/TimeSig_StepUpTable26/g
s/\bTimeSig_DisplayStrings_Code2\b/TimeSig_StepDownTable26/g
