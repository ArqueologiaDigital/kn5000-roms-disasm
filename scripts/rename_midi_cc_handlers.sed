# rename_midi_cc_handlers.sed
# Rename MIDI CC handler labels to semantic names.
#
# These handlers are dispatched from two tables:
#   MidiCC_LowRange_Table     (CC 0-7)
#   MidiCC_ExtendedRange_Table (higher CCs)
#
# Usage (dry-run preview):
#   sed -f scripts/rename_midi_cc_handlers.sed maincpu/kn5000_v10_program.s | diff maincpu/kn5000_v10_program.s -
#
# Usage (apply in-place):
#   sed -i -f scripts/rename_midi_cc_handlers.sed maincpu/kn5000_v10_program.s
#
# WARNING: Do NOT run this without first verifying the build is clean.
#          After running, rebuild and verify byte-match with compare_roms.py.

# ============================================================================
# Low-range table handlers (CC 0-7)
# ============================================================================

# CC 0,1,2,7 shared handler — simple parameter store (6 bytes, ends with ret)
s/\bLABEL_FCFB5D\b/MidiCC_Handler_SimpleParamStore/g

# CC 3 handler — complex handler with table lookups and multi-path logic
s/\bLABEL_FCFB63\b/MidiCC_Handler_CC3_TableLookup/g

# CC 4 handler — voice param with CC comparison
s/\bLABEL_FD039C\b/MidiCC_Handler_CC4_VoiceParam/g

# CC 5 handler — voice param with CC comparison
s/\bLABEL_FD0416\b/MidiCC_Handler_CC5_VoiceParam/g

# CC 6 handler — voice param with CC comparison (dual offset store)
s/\bLABEL_FD03D8\b/MidiCC_Handler_CC6_VoiceParam/g

# ============================================================================
# Extended-range table handlers — Voice parameter family
# ============================================================================
# These 8 handlers (FCFE0B..FCFFD1) share nearly identical structure:
# channel iteration, parameter offset, bounds check, then voice param update.
# They differ only in the target parameter offset byte.

# Voice param handler 0 (table index 0, offset 0x36)
s/\bLABEL_FCFE0B\b/MidiCC_VoiceParam_0/g

# Voice param handler 1 (table index 8, offset 0x37)
s/\bLABEL_FCFE4B\b/MidiCC_VoiceParam_1/g

# Voice param handler 2 (table index 9, offset 0x37)
s/\bLABEL_FCFE8C\b/MidiCC_VoiceParam_2/g

# Voice param handler 3 (table index 1, offset 0x37)
s/\bLABEL_FCFECD\b/MidiCC_VoiceParam_3/g

# Voice param handler 4 (table index 2, offset 0x37)
s/\bLABEL_FCFF0E\b/MidiCC_VoiceParam_4/g

# Voice param handler 5 (table index 3, offset 0x37)
s/\bLABEL_FCFF4F\b/MidiCC_VoiceParam_5/g

# Voice param handler 6 (table index 4, offset 0x37)
s/\bLABEL_FCFF90\b/MidiCC_VoiceParam_6/g

# Voice param handler 7 (table index 5, offset 0x37)
s/\bLABEL_FCFFD1\b/MidiCC_VoiceParam_7/g

# Voice param handler 8 (table index 6, offset 0x36 — like param 0)
s/\bLABEL_FD0012\b/MidiCC_VoiceParam_8/g

# Voice param handler 9 (table index 7, offset 0x41 — extended variant)
s/\bLABEL_FD0052\b/MidiCC_VoiceParam_9/g

# Voice param handler 10 (table index 12)
s/\bLABEL_FD009F\b/MidiCC_VoiceParam_10/g

# Voice param handler 11 (table index 13, has mid-handler label FD00EB)
s/\bLABEL_FD00E0\b/MidiCC_VoiceParam_11/g

# Voice param handler 12 (table index 14)
s/\bLABEL_FD0121\b/MidiCC_VoiceParam_12/g

# Voice param handler 13 (table index 15)
s/\bLABEL_FD0162\b/MidiCC_VoiceParam_13/g

# Mid-handler entry point inside VoiceParam_11 (jumped to from elsewhere)
s/\bLABEL_FD00EB\b/MidiCC_VoiceParam_11_MidEntry/g

# ============================================================================
# Extended-range table handlers — Stub handlers (just ret)
# ============================================================================

# Stub handler A (table index 10) — single ret instruction
s/\bLABEL_FD009D\b/MidiCC_StubHandler_A/g

# Stub handler B (table index 11) — single ret instruction
s/\bLABEL_FD009E\b/MidiCC_StubHandler_B/g

# ============================================================================
# Extended-range table handlers — Specialized handlers
# ============================================================================

# Bit manipulation handler (table index 18) — complex bit mask/set logic
# with lookup table of bit patterns at the end
s/\bLABEL_FCFC74\b/MidiCC_Handler_BitManipulation/g

# Paired param handler A (table index 25) — channel iteration with
# bounds check and voice param update (offset byte 0x25/0x24 pair)
s/\bLABEL_FCFCBC\b/MidiCC_Handler_PairedParamA/g

# Paired param handler B (table index 24) — nearly identical to A,
# differs in offset byte order (0x24/0x25 pair)
s/\bLABEL_FCFCFA\b/MidiCC_Handler_PairedParamB/g

# Range-check handler (table index 16) — validates input range,
# uses small inline lookup table (3 entries)
s/\bLABEL_FCFD38\b/MidiCC_Handler_RangeCheck/g

# Channel mapping handler (table index 17) — complex handler with
# push/pop, multi-channel iteration, and bit-field mapping table
s/\bLABEL_FCFD7B\b/MidiCC_Handler_ChannelMapping/g

# Bank/mode select handler (table index 31) — complex multi-branch
# logic checking bank numbers (0x80, 0x81, 0x82) and mode values
s/\bLABEL_FD01A3\b/MidiCC_Handler_BankModeSelect/g

# Expression parameter handler (table index 32) — handles expression
# CC with special 0x81/0x80 mode check and scaled parameter update
s/\bLABEL_FD0234\b/MidiCC_Handler_ExpressionParam/g

# Direct parameter store A (table index 33) — reads channel offset,
# stores parameter with 0x7F mask, conditional secondary store
s/\bLABEL_FD029F\b/MidiCC_Handler_DirectStoreA/g

# Direct parameter store B (table index 34) — similar to A but with
# different offset and additional indirect store path
s/\bLABEL_FD02CE\b/MidiCC_Handler_DirectStoreB/g

# CC parameter dispatch handler (table index 39) — dispatches based
# on CC value with bounds check and voice param update
s/\bLABEL_FD02FF\b/MidiCC_Handler_ParamDispatch/g

# Table-indexed dispatch (table index 40) — already partially disassembled,
# uses XIX+A indexing into a sub-dispatch table
s/\bLABEL_FD0335\b/MidiCC_Handler_TableDispatch/g

# Return point for TableDispatch (early exit on out-of-range)
s/\bLABEL_FD036A\b/MidiCC_Handler_TableDispatch_Ret/g

# ============================================================================
# Helper subroutines (called by MIDI CC handlers)
# ============================================================================

# Conditional E setup helper — sets E from D if A >= 0x40, then calls
# voice param update subroutine
s/\bLABEL_FD036B\b/MidiCC_Helper_ConditionalESetup/g

# Mid-label inside ConditionalESetup (branch target after compare)
s/\bLABEL_FD037C\b/MidiCC_Helper_ConditionalESetup_Store/g

# Entry variant helper — loads E=A, sets up param registers, calls
# a different voice param update subroutine
s/\bLABEL_FD0385\b/MidiCC_Helper_EntryWithEqA/g

# Note: LABEL_FD0467 is NOT a MIDI CC handler — it's a separate routine
# after UIState_ProcessDisplayUpdate. Do not rename it here.
