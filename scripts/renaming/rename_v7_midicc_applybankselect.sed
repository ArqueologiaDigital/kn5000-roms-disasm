# v7 carries v10's name: the same routine (RAM block at 0x95A8 / 0x9336 / 0x9376 instead of 0x9644 / 0x93D2 / 0x9412)
s/\bMidiCC_Handler_PairedParamA_Helper\b/MidiCC_ApplyBankSelect/g
