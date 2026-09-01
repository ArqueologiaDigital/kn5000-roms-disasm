; ============================================================================
; dsp/dsp_channel_regs_maincpu.inc -- what the SHARED DSP driver means on the
; MAIN processor of the Technics SX-WSA1R.
; ============================================================================
;
; dsp/dsp_channel_regs.s is ONE source assembled into BOTH CPUs.  The ONLY thing
; that differs between the two copies is named here and nowhere else, so the
; shared body never has to ask which processor it is being built for.
;
; ⚠ THIS VALUE IS A MEASUREMENT, not a decision.  It is the literal the ROM
;   carries at the three sites listed by
;       python3 notes/sound/wsa1_dsp_join_probe.py --pairs
;   and if it is wrong by a single byte the image stops rebuilding:
;       python3 scripts/analysis/assert_byte_identical.py
;
; ⚠ THE ADDRESS IS NOT DERIVABLE FROM THE SIBLING.  The KN5000 sub-CPU runs the
;   same routines against 0x00130000; copying its comment across would have
;   written a peripheral address that does not exist on this machine, and the
;   byte gate would never have noticed -- it would simply have stopped matching
;   here, which is exactly why the equate is a measurement.

.equ DSP_REGS_BASE, 0x007F0000	; CPU 1's DSP register file: 8-bit index at +0, data at +2
