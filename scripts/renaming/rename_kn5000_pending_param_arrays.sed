# The pending per-part parameter arrays scanned by PendingParam_ScanAllTables, named by what fills them
# (MidiCC_PartTargets_CC1_Modulation {0xB2}, MidiPB_PartTargets {0xB1}, MidiCC_PartTargets_CC11_Expression {0xB3},
# MidiCC_SetPendingPartVolume) -- evidence: analysis/kn5000-naming/proposals-2026-10-06-helpers-h.json
s/\bPendingExpr_ScanEntry\b/PendingB4_ScanEntry/g
s/\bPendingExpr_NextEntry\b/PendingB4_NextEntry/g
s/\bPendingVol_ScanEntry\b/PendingModulation_ScanEntry/g
s/\bPendingVol_NextEntry\b/PendingModulation_NextEntry/g
s/\bPendingPan_ScanEntry\b/PendingPitchBend_ScanEntry/g
s/\bPendingPan_NextEntry\b/PendingPitchBend_NextEntry/g
s/\bPendingBank_ScanEntry\b/PendingExpression_ScanEntry/g
s/\bPendingBank_NextEntry\b/PendingExpression_NextEntry/g
s/\bPendingPartCC_ScanEntry\b/PendingVolume_ScanEntry/g
s/\bPendingPartCC_NextEntry\b/PendingVolume_NextEntry/g
s/\bVoiceParam_StoreExpression\b/VoiceParam_StorePendingB4/g
s/\bVoiceParam_WriteExpression\b/VoiceParam_SendPendingB4/g
s/\bVoiceParam_ExprCheckGuard\b/VoiceParam_SendPendingB4_Guard/g
s/\bVoiceParam_ExprDone\b/VoiceParam_SendPendingB4_Done/g
s/\bVoiceParam_StoreVolume\b/VoiceParam_StorePendingModulation/g
s/\bVoiceParam_WriteVolume\b/VoiceParam_SendPendingModulation/g
s/\bVoiceParam_VolCheckGuard\b/VoiceParam_SendPendingModulation_Guard/g
s/\bVoiceParam_VolDone\b/VoiceParam_SendPendingModulation_Done/g
s/\bVoiceParam_StorePan\b/VoiceParam_StorePendingPitchBend/g
s/\bVoiceParam_WritePan\b/VoiceParam_SendPendingPitchBend/g
s/\bVoiceParam_PanCheckGuard\b/VoiceParam_SendPendingPitchBend_Guard/g
s/\bVoiceParam_PanDone\b/VoiceParam_SendPendingPitchBend_Done/g
