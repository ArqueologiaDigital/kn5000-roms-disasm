# §133 BANK-ENTRY DEMULTIPLEXER — PRE-REGISTERED, written before the run

Masks, computed not typed (all four bits verified clear in the default 0x46A39B440F):
  A2 THE TEST (inj + distinct + sweep + suppressTA) = 0x1003C6A39B440F
  A1 CONTROL  (inj + SAME     + sweep + suppressTA) = 0x1002C6A39B440F
  A3 DC NULL  (sweep only, injector OFF)            = 0x246A39B440F

Bit map: 39 injector | 40 distinct streams | 41 sweep | 42-44 sel0D | 45-47 sel0E
         48-49 f31=4 | 50-51 f31=5 | 52 suppress the blanket tempA capture

Trial index -> (sel0D, sel0E, f4, f5) = (t>>7 &7, t>>4 &7, t>>2 &3, t &3).
1024 trials x 64 frames = 65536 frames = 1.37 s emulated.

Selector menu 0..7:
  0 none | 1 acc<-L | 2 tempA | 3 tempB | 4 mem[ptr] | 5 P raw | 6 acc+=L | 7 P<<ACC_SHIFT
f31 menu 0..3:
  0 keep the current alias | 1 LOAD | 2 ADD | 3 HOLD

INJECTED STREAMS (non-repeating, disjoint, never zero):
  s[n] = 0x010000 + n*0x101  -> D-RAM 0x05
  t[n] = 0x018000 + n*0x203  -> D-RAM 0x0F   (A2; in A1 both cells get s)

## PREDICTIONS

P0  **TRIAL 0 IS THE READING NULL** — it is the shipped default (all four selectors 0).
    It must score `nz = 0`: the entry routes nothing, so no state cell is ever written.
    Independently MEASURED (§129: `unit0/DO1` 0 non-zero in 2,099,250 frames).
    ⛔ If trial 0 shows `nz > 0` the injector is leaking and THE WHOLE RUN IS VOID.

P1  A large majority of the 1024 trials must ALSO score `nz = 0`. The offline
    enumeration says 576/1024. A pass rate near 100% would mean the criterion
    cannot fail and the run must be discarded.

P2  Any trial that feeds a bank must show its feed count NEAR 64 and bit-exact:
      feed1_s high => bank 1's entry fed from cell 0x05
      feed1_t high => bank 1's entry fed from cell 0x0F   (likewise feed2_* for bank 2)
    Chance is 2^-24 per frame, so ANY non-zero feed count is already decisive.

P3  §131 says P is the only register that can carry the sample across the entry, so
    survivors should concentrate on sel = 5 or 7 (the two P variants).
    ★ If survivors are instead concentrated on 1/2/3/4/6, §131 is WRONG — and that is
    the more interesting outcome.

P4  ★ THE SCALE IS DECIDED HERE. Value 5 writes P as a RAW datum; value 7 writes it at
    the multiply's scale (<< 16). §132 §3 flagged the two as ~2^16 apart and refused to
    guess. Exactly one of them should reproduce the feed identity.

## FALSIFIERS / VOID CONDITIONS

F1  trial 0 `nz > 0`                    -> injector leaks, run VOID
F2  >90% of trials pass C1+C2           -> criterion cannot fail, run VOID
F3  A3 (injector off) shows `chg > 0`   -> something other than my stimulus moves the
                                           cells, so the feed identity is not mine
F4  no trial scores any feed match      -> the entry's destination is not in the menu

## READING NOTE (a limitation of this scoring, stated in advance)

The shift-identity column is TRIVIALLY satisfied when cells are zero (`0 == 0`), so it
is a criterion that cannot fail on the null. It is meaningful ONLY on trials with
`chg > 0` and must be read that way. The deciding predicate is the FEED IDENTITY, which
zero cells cannot fake because the injected streams are never zero.
