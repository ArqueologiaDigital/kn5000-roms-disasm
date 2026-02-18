# Rename audio mixer/attenuator init routines at 0x150000
s/LABEL_EF17F4/AudioMix_Init/g
s/LABEL_EF1830/AudioMix_EnableChannels_Loop/g
s/LABEL_EF183D/AudioMix_WriteChannelGroup/g
s/LABEL_EF184B/AudioMix_WriteChannelGroup_Loop/g
