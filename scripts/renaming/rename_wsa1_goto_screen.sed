# WSA1: UI_Request = 0x80NN means "go to screen NN" (wsa1_ram.inc); a routine that only stores that is UI_GotoScreenNN.
# And one more veneer: a call of MsgLine_PartVolume_Veneer.
s/\bsub_FEAA86\b/UI_GotoScreen24/g
s/\bsub_FEAA8D\b/UI_GotoScreen27/g
s/\bsub_F6BFF2\b/MsgLine_PartVolume_Call/g
