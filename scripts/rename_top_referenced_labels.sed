# Rename top-referenced LABEL_ routines to semantic names
# These are the 23 most-referenced unnamed labels (14-24 refs each)
#
# Most are shared epilogues and stubs — a common TLCS-900 code size optimization
# where multiple functions jump to the same cleanup/return code.

# === RET STUBS (single `ret` instruction, used as jump targets) ===

# Post-MIDI-send hook point (null stub, could be patched)
s/\bLABEL_FEBF79\b/MIDI_PostSendStub/g

# Accompaniment patch null return
s/\bLABEL_F54C21\b/AccPatch_NullReturn/g

# Sound generator null return
s/\bLABEL_F2535E\b/SoundGen_NullReturn/g

# Voice parameter null return
s/\bLABEL_F25AA3\b/VoiceParam_NullReturn/g

# === RETURN-ZERO STUBS (lds32 xhl, 0; ret or similar) ===

# Application event handler return-zero + epilogue (pop xiz, inc 4 xsp)
s/\bLABEL_F4637B\b/AppEvent_ReturnZero/g

# Display/paint function return-zero
s/\bLABEL_F685F6\b/DisplayFunc_ReturnZero/g

# File browser return-zero
s/\bLABEL_FBF42D\b/FileBrowser_ReturnZero/g

# Document event handler return-zero (DpDocTtl)
s/\bLABEL_F21E3B\b/DpDocTtl_ReturnZero/g

# Palette event handler return-zero (DpPdTtl)
s/\bLABEL_F21F6A\b/DpPdTtl_ReturnZero/g

# SMF event handler return-zero (DpSmfTtl)
s/\bLABEL_F220C0\b/DpSmfTtl_ReturnZero/g

# Audio control return-zero
s/\bLABEL_F80723\b/AudioCtrl_ReturnZero/g

# Sequencer data return-zero
s/\bLABEL_FBA3AB\b/SeqData_ReturnZero/g

# Audio control return-zero + 38-byte epilogue
s/\bLABEL_F7C7F8\b/AudioCtrl_ReturnZeroEpilogue/g

# Voice init return-zero
s/\bLABEL_F3FF1A\b/SeqVoice_InitReturnZero/g

# === SHARED EPILOGUES (stack cleanup + return) ===

# Voice reallocation cleanup (pop_werp + I/O store + ret)
s/\bLABEL_FE7456\b/NoteMap_ReallocVoices_Exit/g

# DSP config epilogue (68-byte frame cleanup)
s/\bLABEL_FDDB11\b/DSPCfg_Epilogue/g

# File I/O error return epilogue (14-byte frame cleanup)
s/\bLABEL_FED32F\b/FileIO_Epilogue/g

# MIDI send epilogue (calls post-send stub, pop iz, ret)
s/\bLABEL_FEB2BB\b/MIDI_SendEpilogue/g

# Application event handler epilogue (pop xiz + 4 bytes)
s/\bLABEL_F4487E\b/AppEvent_Epilogue/g

# UI event dispatch epilogue (pop xiz + ret)
s/\bLABEL_F98695\b/UIEvent_Epilogue/g

# Sequencer edit function epilogue jump
s/\bLABEL_F35519\b/SqedtFunc_EpilogueJump/g

# Sequencer file epilogue (popw iz + I/O store + ret)
s/\bLABEL_FEC833\b/SeqFile_Epilogue/g

# Sequencer playback epilogue (popw iz + I/O store + ret)
s/\bLABEL_FED0A1\b/SeqPlay_Epilogue/g
