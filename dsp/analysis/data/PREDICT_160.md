# §160 WHERE DOES THE LFO WAVETABLE LAND? — PRE-REGISTERED

Vehicle: CLEAN cold-boot CHORUS (§148 harness), shipped default 0x1910E446A39B440F.
Instrument: dump m_rf[0x1D..0x40] by VALUE, plus every non-zero register-file cell.

WHY: §159 MEASURED D-RAM 0x1D..0x40 (the 36-entry wavetable range) as ~800 writes per cell with
NOT ONE non-zero -- the table never lands there.  Tag 0x15 routes host pokes to m_rf instead
(upd6383.cpp:919, mask bit 23, VERIFIED SET in the default).  §159 §2 left the decisive half
open: does the table ARRIVE in m_rf, or never arrive at all?  Two different fixes.
⚠ The existing "§99 MODE-1 STORES -> register file" line counts MICROCODE stores, not host
writes, so it cannot answer this -- checked before building the instrument.

THE ROM TABLE (the answer this is compared against), sub-CPU ROM 0x01EAFA, 36 entries:
  an exact sine, 0.95*sin(2*pi*k/24 + 0.1) to 0.94 LSB, one-bin DFT, peak table[6] = 0x78FE14.

PREDICTIONS -- mutually exclusive
 H-RF     the window shows ~36 non-zero cells matching the ROM sine table.
          ⇒ the upload arrives; the READER is on the wrong side of the §97 split, and K2 is a
            small change (point the class-6 lookup at m_rf) plus the lookup itself.
 H-NONE   the window is all zeros.
          ⇒ the op-0x74 upload never reaches the chip; the target moves UPSTREAM to the host
            route (ROADMAP:229's "881 writes / 65 cells dropped"), and K2 is much further off.

CONTROL WHOSE ANSWER IS KNOWN
 The "ALL non-zero cells" line must show the cells §97 validated for tag 0x15 -- the host's
 parameter registers.  If that list is EMPTY, the dump is reading the wrong array and the run is
 void, whichever way the window reads.

FALSIFIERS / VOID
 F1  the all-cells list is empty            -> instrument wrong, void
 F2  the window is non-zero but does NOT match the ROM table
                                            -> something else occupies the range; report the
                                               values, do NOT assume it is a corrupted table
 F3  values present but shifted/scaled      -> report the ratio; do NOT introduce a factor

⚠ NOT the criterion: audio, or the tap excursion.  Nothing here changes either -- the class-6
   lookup is still a no-op, so the modulation stays constant regardless of what this finds.
