# §155 the COMBINED arm: SRC 0x00 = coef + the tap-modulation path — PRE-REGISTERED

ARM  = 0x1910E446A39B440F   (default | bit 59 `coef' on f98=1 class-A | bit 60 tapmod)
REF  = 0x1110E446A39B440F   (§154's arm: tapmod alone -- the one that railed)
BASE = 0x110E446A39B440F
Vehicle: CLEAN cold-boot CHORUS, notes 21..27.5 s.

WHY COMBINE (this is the loop closing, not a rescue):
  §152 established that word [1] of the seven-word transaction is `192.A.40.000` -- a
  SRC 0x00 CLASS-A word -- and that it consumes C-RAM[0x02] = 240, THE DEPTH IN SAMPLES.
  §145 decoded `SRC 0x00 = C-RAM[cursor]`, bit-exact +/-240 at exactly those four slots.
  Under the DEFAULT that word reads mem[ptr] instead, which §148 measured as the RAIL
  (8388607) at iw94/iw103.  So in §154 the depth was never loaded and the accumulator
  inherited the rail -- which is precisely the 8 388 607 excursion measured.
  ⇒ §145's reading is not an optional extra here; it is the thing that puts the depth on
  the bus.  §148 called it "inert downstream"; its consumer is this path.

PREDICTIONS
 P1  fired-count unchanged at 4 513 920 (4 words/frame).  It is the same word set.
 P2  ★ THE ONE THAT DECIDES IT: the excursion COLLAPSES from 8 388 607 to ORDER THE DEPTH.
     CHORUS: nominal tap 400, depth 240, allocation 1040 = 800 + 240, DEPTH gain 0.5
     => expect roughly 120..240 per cell, and in no case more than 240.
 P3  the three cells that railed ([00] [10] [30]) should all fall together -- they are the
     same idiom at three voices.  One falling and two railing would mean the depth reaches
     one voice only, i.e. a cursor/alignment problem rather than a transport one.
 P4  cell [20]'s 670 should CHANGE.  It did not rail, so it was reading something else;
     if it is untouched by enabling coef, it is not part of this mechanism.

FALSIFIERS
 F1  excursion still ~8 388 607        -> the accumulator is not the transport, and §145's
                                          reading is not what feeds it.  The seven-word
                                          reading (§152) would then need re-examination.
 F2  excursion collapses to 0           -> coef delivers 0 here; the depth is not C-RAM[cursor]
                                          at these slots after all
 F3  excursion lands far from 240 but non-zero (say 10..50 or 2000..20000)
                                       -> right register, wrong scaling -- report the ratio,
                                          do NOT introduce a fudge factor to close it
 F4  BASE/REF arms move                 -> the gates are not independent, run void
 F5  traps > 0                          -> structurally broken

⚠ NOT the criterion: audio.  DO1/DO2 are 0 in this vehicle for reasons upstream (§141).
⚠ And a PASS here is NOT a decode of the modulation arithmetic -- it would show the depth
   reaches the address with the right magnitude.  The waveform shaping (sine table vs
   triangle vs raw ramp) is a separate question this test does not touch.
