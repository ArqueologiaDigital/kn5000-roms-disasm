# rename_mixer_channels_v7.sed -- written by scripts/converters/mixer_channel_table_retype.py
s/\bAcMixerVol_Confirm_Data_2\b/AcMixerVol_Channels_MuteKey/g
s/\bAcMixerVol_Confirm_Data\b/AcMixerVol_Channels/g
s/\bAcMixerVol_Paint_PtrTable\b/AcMixerVol_ChannelNamePtrs/g
s/\bAcMixerVol_Confirm_Str_Fmt3d\b/AcMixerVol_DrawChannel_Str_Fmt3d/g
s/\bAcMixerVol_Confirm_Str_MUTE\b/AcMixerVol_DrawChannel_Str_MUTE/g
s/\bAcMixerVol_Confirm\b/AcMixerVol_DrawChannel/g
