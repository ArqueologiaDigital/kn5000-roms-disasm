# Conditional-call targets named on 2026-10-06 (v10/v9/v7; the bodies were compared across the three trees first)
s/\bLED_Toggle_Bit2_Loop\b/LED_BlinkBit2Forever/g
s/\bLED_Toggle_Bit3_Loop\b/LED_BlinkBit3Forever/g
s/\bSeqVoice_DispatchProcess_Data\b/MidiPkt_UnpackNibblesToXfer/g
s/\bSeqVoice_DispatchProcess_Data_Loop\b/MidiPkt_UnpackNibblesToXfer_Loop/g
s/\bSeqVoice_DispatchProcess_Data_Skip\b/MidiPkt_UnpackNibblesToXfer_Skip/g
s/\bSeqVoice_DispatchProcess_Data_Skip2\b/MidiPkt_UnpackNibblesToXfer_Skip2/g
s/\bSeqVoice_DispatchProcess_Data_Epilogue\b/MidiPkt_UnpackNibblesToXfer_Epilogue/g
