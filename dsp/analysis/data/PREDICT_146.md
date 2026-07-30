# §146 SRC 0x00 = coef, ONLY on coefficient-consuming words — PRE-REGISTERED

ARM = 0x510E446A39B440F  (default 0x110E446A39B440F | bit 58; bit 57 NOT set).
GATE = the `coef' read applies only when coeff_consumer(word), i.e. class4 == 0xA.

MEASURED BASIS
  bit 57 (coef on ALL 1610 SRC-0x00 words):  bit-exact +240/+240/-240/-240 at the four
  CHORUS twins, AND unit 1 railed -- DO2 98.9% non-zero, peak +8388607, DC leak 99.94%,
  against the default's 41.2% / +1543433 / 34.64%.
  Class split of SRC 0x00: class1 233, class2 1262, class8 4, **classA 111** of 1610.
  A class-2 word consumes no cursor coefficient, so C-RAM[cursor] there returns whatever
  the last class-A word left.

PREDICTIONS
 P1  fired-count falls sharply from bit 57's 91 383 219 -- to roughly the class-A share.
     (If it is unchanged, the gate is not discriminating and the run is void.)
 P2  ★ THE TWINS ARE UNCHANGED: L at iw94/103/135/144 stays +240/+240/-240/-240.
     They are class A, so the narrower gate must still fire on them.  This is the
     known-answer control and it is what makes the refinement non-trivial.
 P3  ★ THE RAILING STOPS: DO2 returns toward the default's 41.2% / +1543433 / 34.64%.

FALSIFIERS
 F1  fired-count ~unchanged        -> gate not discriminating, void
 F2  P2 fails (twins lose ±240)    -> the narrower gate breaks the one thing that worked
 F3  P3 fails (still railed)       -> class is not the right discriminator; the corpus-wide
                                      failure is elsewhere and `coef' may be wrong generally
 F4  traps > 0                     -> structurally broken

⚠ NOT the criterion: audio.  Read §70 ACCA min vs max before describing any output.
