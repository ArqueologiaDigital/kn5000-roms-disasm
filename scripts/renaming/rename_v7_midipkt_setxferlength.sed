# v7 carries v10's name: the same routine with the descriptors at 0xBC40 / 0xBC50 instead of 0xBCDC / 0xBCEC
s/\bMidiPkt_ArpExtHandler_G_Helper\b/MidiPkt_SetXferLengthFromMsg/g
