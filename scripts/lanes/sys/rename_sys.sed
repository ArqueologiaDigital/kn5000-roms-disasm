# lane sys, 2026-09-25: code that sat under data-shaped or wrongly-parented names
s/\bAudioMix_BytecodeData\b/AudioMix_WriteAllGroupRegs/g
s/\bAudioMix_WriteChannelGroup_Helper\b/AudioMix_WriteGroupRegs8/g
s/\bSongBank_LookupTableEntry_Skip\b/CDlikeSwTtl_SendEvt4_Bit0Set/g
s/\bSongBank_LookupTableEntry_Join\b/CDlikeSwTtl_SendEvt4_Post/g
s/\bCDlikeSwTtl_DispatchData:/CDlikeSwTtl_ReturnZeroStub:/g
