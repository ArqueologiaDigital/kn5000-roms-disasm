# lane sys, 2026-09-25: code that sat under data-shaped or wrongly-parented names
s/\bAudioMix_BytecodeData\b/AudioMix_WriteAllGroupRegs/g
s/\bAudioMix_WriteChannelGroup_Helper\b/AudioMix_WriteGroupRegs8/g
s/\bSongBank_LookupTableEntry_Skip\b/CDlikeSwTtl_SendEvt4_Bit0Set/g
s/\bSongBank_LookupTableEntry_Join\b/CDlikeSwTtl_SendEvt4_Post/g
s/\bCDlikeSwTtl_DispatchData:/CDlikeSwTtl_ReturnZeroStub:/g
# v7 only: symboliser labels parented on the drifted v7 label SoundParam_NotifyChange;
# the code is v10's SndParam_ResolveWidget tail (v10 = v7 + 0x7D1), whose own names
# v7 still defines 0x41A higher in audio/sndparam_routines.s
s/\bSoundParam_NotifyChange_Code_Skip2\b/SndParam_RW_ChainContinue_v7/g
s/\bSoundParam_NotifyChange_Code_Skip\b/SndParam_RW_ChainCheckFirst_v7/g
s/\bSoundParam_NotifyChange_Code_Join2\b/SndParam_RW_ProcessResult_v7/g
s/\bSoundParam_NotifyChange_Code_Join\b/SndParam_RW_FoundCallback_v7/g
