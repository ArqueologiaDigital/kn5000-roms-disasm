# §142 unit-aware ACT 0x0D/0x0E accumulator write — PRE-REGISTERED

ARM A = 0x10E446A39B440F   ship, unit-BLIND (exactly what §135 measured)
ARM B = 0x110E446A39B440F  ship + bit 56, unit-AWARE
bit 56 verified clear in the default and used at one site (bx_acc_w).

THE BUG, verified in source before this run:
  the ACT 0x0D/0x0E destination menu wrote `m_acc' unconditionally, but mask bit 14
  is SET in the default so unit 1 accumulates into `m_accb', and the SRC 0x10 READER
  at upd6383.cpp:2143 IS unit-aware.  So in unit 1 the pair wrote ACCA and read ACCB.

MEASURED BASIS (from the committed log ship_46A39B440F.log.gz, §104 table):
  iw205/319/330 (the three reverb ACT 0x0D words) all read dp = 0x85 -- unit 1's INPUT
  latch -- and mem there is 0..0 in BOTH quiet and loud (marked '='), i.e. MEASURED ZERO.

PREDICTIONS
 P1  the fired-count "routed to ACCB" is >> 0 in B and exactly 0 in A.
 P2  ★ In B the railing STOPS.  mem[0x85] = 0, so acc <- 0 and then P <- 0: the pair
     injects ZERO instead of leaving a railed accumulator.  unit1/DO2 non-zero should
     fall from 98.9% back toward the default's 41.2%.
 P3  unit0/DO1 is UNCHANGED between A and B -- unit 0 uses m_acc either way, so the fix
     must be a no-op there.  This is the known-answer control.

FALSIFIERS
 F1  fired-count 0 in B            -> gate inert, run void
 F2  P3 fails (DO1 differs)        -> the gate is not confined to unit 1; something else moved
 F3  B still rails at -0x800000    -> the unit-blind write was NOT the cause of §135's railing

⚠ NOT PREDICTED, and must not be reported as success: audio.  Read §70 ACCA min vs max
   before describing any non-zero output (the §137 retraction).
