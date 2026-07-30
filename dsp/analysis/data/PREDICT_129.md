# §129 cursor-rebase A/B -- PRE-REGISTERED, written before the run

ARM  = UPD6383_SPEC=0x6A39F440F   (default 0x6A39B440F | bit 18)
       bit 18 is used at exactly ONE site, upd6383.cpp:3917, and is CLEAR in the
       default, so the two arms differ in this reading and nothing else.
GATE = m_cursor = unit1 ? 0x90 : 0x00 at the body CALL (cram-unit-base.md item A).

BASELINE, ALREADY MEASURED (§129 §2): body 0's cursor enters at 0x71 and bank 1
fetches C-RAM TABLE B -- 0004BE 00097C 000E3A ... step 0x4BE = 1214, clamped 0x7FFF.
Bank 2, after w58 = rstcur, fetches C0515C 20691C 1F481C 7F6996 81227A 800000.

PREDICTION IF THE REBASE READING IS RIGHT
  P1  bank 1 (iw89..) fetches the SAME stream bank 2 does:
        C0515C 20691C 1F481C 7F6996 81227A 800000  then C09AE0 200000 ... 
      i.e. C-RAM 0x00..0x1D in order, because BOTH banks read 0x00..0x1D.
  P2  bank 2 (iw143..) is UNCHANGED -- it already rstcur'd to 0x00, so the gate
      must be a no-op there.  This is the control whose answer is known.
  P3  the unit-1 reverb's cursor moves to 0x90, not 0x00.

FALSIFIERS
  F1  bank 1's stream is anything other than C-RAM 0x00..0x1D in order.
  F2  bank 2's stream CHANGES -> the gate is doing something other than a rebase.
  F3  no change at all -> the gate did not fire (check it is not a silent no-op).

NOT PREDICTED, and must not be read as success: audio.  unit0/DO1 presents 0
non-zero in 2.1M frames and PEQ's input cell is railed at 0x7FFFFF, so the output
is expected to stay zero even if P1 and P2 both hold.  The clobber is a separate
defect.  A non-zero DO1 here would be a SURPRISE, not the criterion.
