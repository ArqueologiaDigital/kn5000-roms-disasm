# §157 IS §155's ±240 A SWEEP, OR POOLED CONSTANTS? — PRE-REGISTERED

This tests MY OWN headline claim from §155 and §156, which is currently load-bearing for the
whole modulation path and for a shipped default.

THE CHALLENGE (raised by a read-only agent, re-verified by me before writing this):
 * `upd6383.cpp:2030` -- class 6, the TABLE-LOOKUP idiom, is an explicit NO-OP:
   "no table is modelled, so execute the addressing and leave the ALU alone."
   So the emulator performs no waveform lookup at all.
 * §155's census buckets on `cellv & 0x3f` and takes min/max over the run.
 * CHORUS's four ROM depth constants are +240 +240 -240 -240 (§145 live, §152 static).
 ⇒ A bucket holding one positive and one negative voice reports "-240..+240" WITH NO SWEEP.
   §155's P2 therefore CANNOT distinguish a sweep from pooled signed constants.  Same failure
   family as §153's void run: a criterion that cannot fail.
 ⚠ And §155's cross-check against 160..640 is weaker than I presented it: 160..640 IS 400 +/- 240,
   and +/-240 is what the constants alone give.

THE TEST: census `m_tapmod` PER I-RAM SLOT instead of per descriptor cell.  Each voice is then
alone in its bucket and sign-pooling is impossible.  Cold-boot CHORUS, no panel navigation.
ARM = 0x1910E446A39B440F (the shipped default).

PREDICTIONS -- these are mutually exclusive, which is the point
 H-SWEEP   every firing slot shows a NON-ZERO range.  An LFO is zero-mean, so a slot carrying
           depth d should read about -|d|..+|d|.
 H-CONST   every firing slot shows range EXACTLY 0, and the four slots read
           +240, +240, -240, -240 -- the ROM constants, one per voice.
           ⇒ §155/§156's "the tap sweeps" is WRONG and must be retracted.

FALSIFIERS / VOID
 F1  no slot fires                     -> instrument broken, void
 F2  ranges are non-zero but NOT ~2|d| -> neither hypothesis; report the numbers, do not fit
 F3  slot count != 4 for CHORUS         -> the idiom is not where §152 says it is

⚠ I expect H-CONST.  The agent's argument is sound and I could not find a flaw in it.  If it
  holds, §155's headline and §156's ship justification both need correcting, and the ship itself
  needs re-examining -- the mechanism (a modulation term reaching the address) is still real, but
  "it sweeps" would not be.
