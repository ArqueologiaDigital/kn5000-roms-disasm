# §148 SRC 0x00 = coef, gated on f98 == 1 AND coefficient-consuming — PRE-REGISTERED

ARM  = 0x910E446A39B440F  (default 0x110E446A39B440F | bit 59)
BASE = 0x110E446A39B440F  (the shipped default)
Vehicle: COLD BOOT CHORUS -- the twins live in CHORUS -- with notes at t=21..27.5 s,
AFTER the ~19 s boot, so there ARE loud frames this time (§145's cold vehicle had none).
Trace armed at frame 1 100 000 = 22.9 s, inside the held note.

WHY f98 AND NOT CLASS (the fitting objection, answered)
  §146 localised the railing to four words: kernel iw14/iw36 (400.A.00.000, f98=0) and
  ROOM REVERB iw315/iw326 (282.A.00.000, f98=2).  None is f98=1.  Gating on f98 BECAUSE
  it separates them would be fitting to the outcome; what licenses it is §147, an
  INDEPENDENT test on the other f98=1 form -- the twelve 182.A.00.000 words land on the
  2/pi envelope idiom's one-pole constants, in the ROM's own upload order, named
  ATTACK/RELEASE SENS.(s) in the UI.

PREDICTIONS
 P1  fired-count > 0 and MUCH smaller than the class-A arm's 16 063 766.
     (0 would mean the gate never fires in this vehicle and the arm is a null.)
 P2  ★ KNOWN-ANSWER CONTROL: the twins still read +240/+240/-240/-240 at
     iw94/103/135/144, and the anchored SRC 0x08 word at iw89 still reads 114.
 P3  the railing does NOT appear: DO2 stays at the BASE arm's level for this vehicle.
     ⚠ This is a CONSISTENCY CHECK, not a discovery -- the railers are excluded by
     construction, so P3 passing confirms §146's localisation and nothing more.
 P4  ★ THE ONLY PREDICTION THAT COULD SURPRISE: with the designed increment on the bus,
     CHORUS's LFO phase cell should MOVE -- §109's "LFO PHASE resident at body-0 iw89"
     probe, and the §104 per-slot mem column, should differ between BASE and ARM.
     Under the shipped mem[ptr] reading the twins were fed the RAIL at two of four sites.

FALSIFIERS
 F1  fired-count 0                    -> null arm, void
 F2  P2 fails                         -> the narrower gate broke the one thing that worked
 F3  DO2 rails anyway                 -> §146's localisation to four words is WRONG
 F4  P4 shows no difference anywhere  -> `coef' changes the bus but nothing downstream reads
                                         it, i.e. the reading is inert in this vehicle and
                                         cannot be validated by it

⚠ NOT the criterion: audio.  §70 ACCA min vs max before describing any output.
