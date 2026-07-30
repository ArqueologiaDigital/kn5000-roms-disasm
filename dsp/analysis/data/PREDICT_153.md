# §153 the delay-tap modulation path — PRE-REGISTERED, written before the run

ARM  = 0x1110E446A39B440F   (default 0x110E446A39B440F | bit 60)
BASE = 0x110E446A39B440F
Bit 60 verified free by programmatic enumeration of every mask literal; one site.
Vehicle: CLEAN cold-boot CHORUS, notes at 21..27.5 s (§148's harness) -- CHORUS is the
default effect, so the swept taps run without any panel navigation.

WHAT IS BEING TESTED (§152): `lo12 == 0x44C` applies a modulation offset to the delay-tap
address.  The offset is taken as the accumulator in DATUM units -- a signed sample count,
because the depth the idiom loads IS a sample count (ENHANCER: UI "DELAY L (ms)" = 350 ->
C-RAM 15435 = 350 x 44100/1000 exactly).
⚠ The transport is deliberately NOT scaled to make any particular excursion come out.  The
per-cell tap-address census MEASURES the range, so a wrong quantity shows as a wrong range
rather than being fitted away.

CHORUS's designed geometry (MEASURED, §152): nominal tap 400 samples, depth 240,
line allocation 1040 = 800 + 240.  DEPTH defaults to a 0.5 gain, so the expected
excursion is +/-120 samples => a RANGE of about 240.

PREDICTIONS
 P1  fired-count > 0.  (0 = the gate never ran; any "no change" would be an artefact.)
 P2  ★ At least one descriptor cell's tap address MOVES.  In BASE the range must be 0 for
     every cell -- the address is (cellv + G) and G is common to all of them, so no cell's
     address can move RELATIVE to the others.  This is the null and it is structural.
 P3  ★ THE ONE THAT DECIDES IT.  The swept cells' range should be of ORDER the depth --
     roughly 240 (full depth) or 120-240 (at the 0.5 DEPTH gain).  A range of order 10^5
     means the accumulator is not the offset; a range of 1-2 means it is the wrong term
     entirely.
 P4  The swept addresses must stay inside the line: CHORUS's allocation is 1040 samples,
     so an excursion that leaves that window is wrong even if its size looks right.

FALSIFIERS
 F1  fired-count 0                          -> gate inert, void
 F2  BASE shows a non-zero range             -> the census is measuring G, not modulation;
                                               the null is broken and the run is void
 F3  range >> 10^3 or range <= 2             -> the accumulator is not the offset (P3)
 F4  frames stop closing (traps > 0)         -> structurally broken
 F5  the swept address leaves [0, allocation] -> wrong sign or wrong base

⚠ NOT the criterion: audio.  DO1/DO2 are 0 in this vehicle for reasons upstream of this
   change (§141/§148).  Read §70 ACCA min vs max before describing any output.

---
# §154 RE-RUN — the census fixed, predictions restated

⛔ §153's run was VOID by its own F2: the BASE arm showed range 65535 for every cell,
because the census took the ABSOLUTE address and `m_frames_run` (the rotation G) sweeps
the whole 16-bit space by itself.  It was a criterion that could not fail in the other
direction.  The census now measures the MODULATION TERM (`m_tapmod`) per descriptor cell.

RESTATED PREDICTIONS
 P1  fired-count > 0.  (§153 already measured 4 513 920 = 4 words/frame -- CHORUS has
     exactly four 0x44C words, and §148 measured the same count for its four f98=1 twins.
     The gate fires correctly; only the census was wrong.)
 P2  ★ THE NULL, now real: with bit 60 OFF, `m_tapmod` is 0 at every cell, so EVERY range
     must be 0 and the report must read "NONE".  If BASE shows any excursion the census is
     still measuring something else and the run is void again.
 P3  ★ THE ONE THAT DECIDES IT: with bit 60 ON, the excursion should be of ORDER THE DEPTH.
     CHORUS's designed geometry is nominal tap 400, depth 240, allocation 1040 = 800 + 240,
     with DEPTH defaulting to a 0.5 gain => expect a range of roughly 120..240 samples.
 P4  |excursion| must stay under the line allocation (1040 for CHORUS), or the sweep leaves
     its own delay line.

FALSIFIERS
 F1  fired-count 0                      -> void
 F2' BASE shows a non-zero excursion     -> census still wrong, void
 F3  range >> 10^3, or range <= 2        -> the accumulator is NOT the offset
 F4  traps > 0                           -> structurally broken
