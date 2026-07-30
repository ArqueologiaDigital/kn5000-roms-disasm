# §145 SRC 0x00 = coef — PRE-REGISTERED, written before the run

ARM = 0x310E446A39B440F  (default 0x110E446A39B440F | bit 57).  Bit 57 verified free by
      programmatic enumeration; used at exactly one site.
Vehicle: COLD BOOT, CHORUS (the default effect) -- no panel navigation, so the run is
short and the LFO twins execute from the first frame.

THE CORPUS TWIN (MEASURED, re-verified by me):
  092.A.xx.200  SRC 0x08 (ANCHORED = C-RAM[cursor])  n=29, successor 082.2.00.1C0 29/29
  192.A.xx.000  SRC 0x00                             n=29, successor 082.2.00.1C0 29/29
  base rate of that successor after any class-A word: 64/822 = 7.79%   (chance ~1e-32)
  they differ in exactly two bits: hi12 bit 8, and SRC bit 3.
CHORUS: anchored word consumes C-RAM[0x00] = 114 = its KNOWN LFO increment (0.599 Hz);
        its four twins consume C-RAM[0x02]/[0x04]/[0x0D]/[0x0F], and 0x02/0x04 hold
        0x0000F0 = 240 = 1.262 Hz.
CHORUS twin slots: body 0 loads at iw84; twins are w10/w19/w51/w60 -> iw94/103/135/144.

PREDICTIONS
 P1  fired-count >> 0.  (0 would mean the gate never ran; any "no change" would be an artefact.)
 P2  ★ THE ONE THAT DECIDES IT.  The operand bus L at iw94/103/135/144 becomes exactly
     the C-RAM value those words' cursors land on -- +240 / +240 / -240 / -240 --
     replacing the shipped reading's measured 8388607 / 8388607 / 264 / 203.
     Bit-exact; chance of a coincidental 24-bit match is 2^-24 per slot.
 P3  KNOWN-ANSWER CONTROL: the ANCHORED word at iw89 is UNCHANGED, L = 114.  SRC 0x08 is
     not touched by this gate, so it MUST not move.  If it moves, the gate is not
     confined to SRC 0x00 and the run is void.

FALSIFIERS
 F1  fired-count 0                        -> gate inert, void
 F2  P3 fails (the anchored word moves)   -> gate not confined, void
 F3  L at the twins is not the C-RAM value -> `coef' REFUTED at the twins; report it
 F4  frames stop closing (traps > 0)      -> structurally broken

⚠ NOT PREDICTED and not the criterion: audio, DO1/DO2, or any level statistic.  Read
   §70 ACCA min vs max before describing any non-zero output (the §137 retraction).
