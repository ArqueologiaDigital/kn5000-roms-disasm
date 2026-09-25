# Sub-CPU v1.42, 2026-09-25 (lane subcpu).
#  - CALL_TABLE_12159 (address name): the 6 x u32 setup-handler table Voice_Poly_NoteOn_SlotFound
#    calls through (`lda xix,(table:24) / add / ld xhl,(xhl) / call (xhl)`).
#  - Voice_SetParam_04134B (address name): stores A to the byte at 0x04134B, which is read only
#    by the Voice_Env_ApplyVelocity_* velocity-switch dispatchers (bits 0, 1, 3, 4).
s/\bCALL_TABLE_12159\b/Voice_PolyNoteOn_Setup_PtrTable/g
s/\bVoice_SetParam_04134B\b/Voice_SetVelSwitchConfig/g
