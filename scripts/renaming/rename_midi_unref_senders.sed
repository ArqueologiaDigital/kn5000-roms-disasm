# midi lane 2026-09-25: the routine at 0xFD0BF1 sends CC function 9 (W = 9 before
# `calr MidiChannel_ConfigureController`), like its siblings _Ctrl1/_Ctrl3/_Ctrl0
# send functions 1/3/0; "MultiHandler" described nothing it does.
/^[[:space:]]*;/!s/\bMidiCC_ChannelDispatch_MultiHandler\b/MidiCC_ChannelDispatch_Func09/g
