# WSA1 naming step (session 53b889a2, wsa1_rename.py)
s/\bPanelWire_EntryThunks_Join\b/PanelWire_BootPhase0/g
s/\bSysExModule_EntryThunks_Join\b/SysExModule_BootPhase0/g
s/\bsub_F8A6F3_Join\b/PanelEvent_BootPhase0/g
s/\bPanelScreen_RequestRedrawIfFieldQueued_Join\b/SysexBulkDump_BootPhase0/g
s/\bPanelDial_DrawValueDigits_Join\b/DebugMonitor_BootPhase0/g
s/\bData_F82000_Nop\b/MainTask_PhaseVector_Ret/g
