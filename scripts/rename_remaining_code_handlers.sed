# Rename remaining code handler targets (Phase 2 final batch)
# Only tables with confirmed executable code targets

# === SoundEffect_Dispatch_Table (15 entries at 0xEEAE08) ===
# Sound effect processing handlers, all start with push xiz prologue
s/LABEL_FE8DC5\b/SoundFX_Handler_0/g
s/LABEL_FE8DD9\b/SoundFX_Handler_1/g
s/LABEL_FE8E38\b/SoundFX_Handler_2/g
s/LABEL_FE8EA1\b/SoundFX_Handler_3/g
s/LABEL_FE8F0A\b/SoundFX_Handler_4/g
s/LABEL_FE8FA5\b/SoundFX_Handler_5/g
s/LABEL_FE9075\b/SoundFX_Handler_6/g
s/LABEL_FE9171\b/SoundFX_Handler_7/g
s/LABEL_FE9241\b/SoundFX_Handler_8/g
s/LABEL_FE933D\b/SoundFX_Handler_9/g
s/LABEL_FE9360\b/SoundFX_Handler_10/g
s/LABEL_FE9383\b/SoundFX_Handler_11/g
s/LABEL_FE8DB1\b/SoundFX_Handler_12/g

# === PerfMode_ParamHandler_Table (19 entries at 0xEF63BD) ===
# Performance mode parameter processing handlers
# All start with prevbank push (0xd9, 0x8b) — save registers before param edit
s/LABEL_EF646F\b/PerfMode_ParamHandler_0/g
s/LABEL_EF6581\b/PerfMode_ParamHandler_1/g
s/LABEL_EF665D\b/PerfMode_ParamHandler_2/g
s/LABEL_EF66F8\b/PerfMode_ParamHandler_3/g
s/LABEL_EF67A6\b/PerfMode_ParamHandler_4/g
s/LABEL_EF6841\b/PerfMode_ParamHandler_5/g
s/LABEL_EF68DC\b/PerfMode_ParamHandler_7/g
s/LABEL_EF698A\b/PerfMode_ParamHandler_8/g
s/LABEL_EF6AD7\b/PerfMode_ParamHandler_9/g
s/LABEL_EF6C50\b/PerfMode_ParamHandler_10/g
s/LABEL_EFDCA6\b/PerfMode_ParamHandler_11/g

# === UIState_EventHandler_Table (5 entries at 0xEE8558) ===
# UI state machine event processing handlers
s/LABEL_FEAC83\b/UIStateEvt_ProcessHandler/g
s/LABEL_FDE981\b/UIStateEvt_StubReturn/g
s/LABEL_FC7BBA\b/UIStateEvt_NullHandler/g
s/LABEL_F202EC\b/UIStateEvt_VoiceParamHandler/g

# === CharMap_Preamble_Table (4 entries at 0xEEC288) ===
# Character mapping preamble handlers (3 ret stubs + 1 store handler)
s/LABEL_FEE3F6\b/CharMap_NullPreamble_0/g
s/LABEL_FEE3F7\b/CharMap_NullPreamble_1/g
s/LABEL_FEE3F8\b/CharMap_NullPreamble_2/g
s/LABEL_FEE3F9\b/CharMap_ActivePreamble/g
