# v7: two audio-mode routines carried v7-only names; v10/v9 call the same code (same bytes, v7 RAM) by these
# (v7 0xFDD7C0 / 0xFDD7D6, v10 0xFDDF91 / 0xFDDFA7).
s/\bAudioMode_CheckAndUpdateStereo_Helper\b/AudioMode_SetStereoFlags/g
s/\bDkMdlyPly_CheckState_Helper2\b/AudioMode_ResetVoiceState/g
