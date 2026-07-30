# §138 output-stage stale-LOAD guard — PRE-REGISTERED, written before the run

ARM  = 0x80046A39B440F  (default 0x46A39B440F | bit 55).  Bit 55 verified free by
       PROGRAMMATIC enumeration of every mask literal, not by grep.
GATE = an `f31 = 0` LOAD on a word that fetches NO coefficient is an ERASURE, not an
       operation, so treat it as HOLD.  This is §83's reading with its `m_in_dram`
       restriction dropped.  §83 was REFUTED for delay words; this is a DIFFERENT claim
       about a DIFFERENT population, and it must be scored on its own.

MEASURED BASIS (per-slot accumulator profile, baseline AND §40 arms agree):
  iw60..64  acc = 1 102 114 506 752   the body's result DOES reach the epilogue
  iw65..72  acc = 0                   erased, eight consecutive slots
  iw73      w73 presents -> DO1       so DO1 presents ZERO
  the epilogue holds exactly ONE class-A word of 23 (iw82), so no multiply issues in it.

PREDICTIONS
 P1  the guard FIRES a large number of times (fired-count >> 0).  A count of 0 would
     mean the gate never ran and any "no change" reading would be an artefact.
 P2  acc at iw65..72 STOPS being 0 -- the body's 1.1e12 survives to w73.
 P3  unit0/DO1 becomes non-zero.
 P4  ★★ THE ONLY PREDICTION THAT MATTERS: §70 ACCA at w73 must have **min != max**
     across loud frames, i.e. the presented value must VARY.  A constant is not audio.

FALSIFIERS / VOID CONDITIONS
 F1  fired-count 0                          -> gate inert, result meaningless
 F2  §70 ACCA min == max                    -> another DC.  The reading gives an output
                                               that is not a signal, exactly as §40 did,
                                               and must be reported as a DC, NOT as audio.
 F3  DC leak (§54) rises toward 100%         -> same failure mode as §40 (34.69% baseline)
 F4  frames stop closing (traps > 0)         -> structurally broken

★ RULE APPLIED IN ADVANCE (method rule 13, and the reason §137 needed a retraction):
  a difference from SILENCE is not a signal.  Do not report DO1 as "output" on the
  strength of a non-zero count or a peak.  Read §70 ACCA min vs max FIRST.
