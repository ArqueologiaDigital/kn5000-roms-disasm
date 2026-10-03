# prom_a panel routines that were named after the RAM address they work on; those addresses are
# named since 4167723f / 1ed49447 (UI_ScreenFlags 0x2095, UI_ScreenLatch 0x207A,
# UI_ScreenHoldState 0x2092, UI_ScreenHoldTimer 0x2073, PanelModeGroup 0x2076).
s/\bPanelState_Sync2095\b/PanelState_SyncScreenFlags/g
s/\bPanelState_Update207A\b/PanelState_UpdateScreenLatch/g
s/\bPanelState_UpdateFlags2092\b/PanelState_UpdateScreenHoldState/g
s/\bPanelTimer_Screen2073\b/PanelTimer_ScreenHold/g
s/\bPanelMode_To2076Map\b/PanelMode_GroupMap/g
s/\bPanelMode_To2076\b/PanelMode_ToGroup/g
