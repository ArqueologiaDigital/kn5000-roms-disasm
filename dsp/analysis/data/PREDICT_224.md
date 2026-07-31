# PREDICT_224 — `iw34` IS ANSWERED FROM DISK; the live question is `iw91`'s **WRAP CONSTANT**

**Committed BEFORE `build.sh` was run.** Every number in §0–§2 is read out of a log already in
`dsp/analysis/data/` (decompressed to scratch, never in place) or out of
`kn7000_mame/src/devices/cpu/upd6383/upd6383.{cpp,h}`. **Nothing in §0–§2 was measured by a new
run.** §3 is what the build must reproduce or fail.

---

## 0. ★★★ WHAT `iw34`'s `14 428 403` IS — FORCED, NO RUN

### 0.1 It is NOT a store datum. It is the `SRC 0x10` accumulator→bus read.

`iw34` = `000.A.FF.407` (`§104`, arm F). By the disassembler's own accessors
(`hi12 = (w>>24)&0xFFF`, `class4`, `addr8`, `lo12`; `SRC = lo12[10:6]`, `ACT = lo12[4:0]`):

```
   hi12 0x000  ->  f31 = 0  = HI_ACC_LOAD  (acc <- P)      ST bit4 CLEAR, B7 CLEAR
   class4 0xA  ->  coefficient consumer: P := coef[cursor++] * L
   addr8 0xFF  ->  p += -1        (dp 06 -> 05, matches §104)
   lo12 0x407  ->  SRC 0x10 = THE ACCUMULATOR,  ACT 0x07 = mem[p] <- L
```

⇒ `acc_to_datum()` is called at `iw34` to build **`L`**, the bus operand — the accumulator being
placed on the bus and clamped — and that clamped `L` is then both stored and multiplied.
**`§223` §1 quoted it as a store's datum; the conversion it censuses is the SOURCE read.**

### 0.2 Its value is `§104` row **33**'s `acc`, and the same identity holds for ALL EIGHT `§S1` rows

`§S1`'s pre-clamp value is, for every site it names, the **previous** `§104` row's `acc >> 16` —
an independent instrument, arithmetic-exact, computed here entirely from `F_satcen_223.log.gz`:

```
   iw16 <- row15  788 981 014 570 >>16 = 12 038 894      §S1  12 038 894      OK
   iw17 <- row16 1 183 702 722 651 >>16 = 18 061 870     §S1  18 061 870      OK
   iw18 <- row17  686 638 043 089 >>16 = 10 477 265      §S1  10 477 265      OK
   iw19 <- row18 1 236 393 791 441 >>16 = 18 865 872     §S1  18 865 872      OK
   iw34 <- row33  945 579 874 058 >>16 = 14 428 403      §S1  14 428 403      OK
   iw39 <- row38  703 174 786 484 >>16 = 10 729 595      §S1  10 729 595      OK
   iw91 <- row90 [7 733 451 .. 549 762 367 691] = [118 .. 8 388 708]   §S1 [118..8 388 708]   OK
   iw92 <- row91 [549 763 481 803 .. 1 099 518 116 043] = [8 388 725 .. 16 777 315]  §S1 same  OK
```

★ **8 of 8, both endpoints, both ranges.** `§S1` is now validated by a **second** route (the first
was `§220`'s `iw39` loud minimum `1 991 044`), and the validation cost **no run**.

### 0.3 The three terms that build it, reproduced to the unit

From the frame trace's own `cur` / `coef` / `p` columns (⚠ the trace header lists 13 names over 12
values — the real columns after `dp` are `acc accb p cur coef MUL L`, `INSTRUMENT-AUDIT` item 1)
and from the ALU's own adder (`acc <- SRC_TERM + P_TERM`, `P = (coef*L) >> P_SHIFT`, `P_SHIFT = 6`,
`ACC_SHIFT = 16`):

```
   C-RAM[0x9B] = 0x4CCCCC = 5 033 164     C-RAM[0x9C] = C-RAM[0x9D] = 0x400000 = 4 194 304

   acc after iw29                                                  0          0.000 FS
   iw30  09A.A.00.200  f31=5(->ADD)  ACT 00  SRC 08  class A
         acc = 0 + (C-RAM[9B] << 16) + P(0)          329 853 435 904   5 033 164   0.600 FS
   iw31  C0A.4.B1.820  C-format, no accumulator write
   iw32  000.A.FF.207  f31=0(LOAD)   ACT 07  SRC 08  class A
         acc = P(iw30) = (C-RAM[9B]^2)>>6            395 824 060 170   6 039 795   0.720 FS
   iw33  412.A.00.200  f31=1(ADD)    ACT 00  SRC 08  class A
         acc = acc + (C-RAM[9D] << 16) + P(iw32)=(C-RAM[9C]^2)>>6
             = 395 824 060 170 + 274 877 906 944 + 274 877 906 944
             =                                       945 579 874 058  14 428 403   1.720 FS
   iw34  SRC 0x10 -> L = clamp(14 428 403) = 8 388 607        <== THE CENSUSED CONVERSION
```

⇒ **`iw33` is the overflow site, not `iw34`.** Its two addends are each **exactly ½ FS**
(`4 194 304 = 2^22`), and **not one of the three terms is a sample** — they are `C-RAM[0x9D]`,
`C-RAM[0x9C]²` and `C-RAM[0x9B]²`. Every multiply here is a **coefficient squared**, because
`SRC 0x08` puts `C-RAM[cursor]` on the bus and the class-A multiply then reads the **same** cell:
verified exactly at `iw30` (`5 033 164² >> 6 = 395 824 060 170`), `iw32`/`iw33`
(`4 194 304² >> 6 = 274 877 906 944`) and at body-0 `iw89` (`114² >> 6 = 203`, the trace's own `p`).

★ The kernel's coefficient block is **Q23**: `0x4CCCCC = 0.600000`, `0x400000 = 0.500000`,
`0x4F5C28 = 0.620000`, `0x50A3D7 = 0.630000`, `0x599999 = 0.700000`, `0x5C28F5 = 0.720000`,
`0x5D70A3 = 0.730000`, `0x600000 = 0.750000` — eight round decimals, all ≤ 0.75. Reverb gains.

## 1. ⛔ `ACT 0x00`'s BUS TERM IS **REFUTED** AS THE CAUSE OF `iw34` — from disk, no run

`§223` §8.2 nominated it. Set the bus term to **zero** and re-run the same ladder:

```
   shipped                      14 428 403   1.720 FS   CLIPS
   ACT 00 bus term = 0          10 234 099   1.220 FS   STILL CLIPS
   products halved (>> 23)       9 311 353   1.110 FS   STILL CLIPS
   both                          5 117 049   0.610 FS   clean
```

⇒ **removing `ACT 0x00`'s bus term does not stop `iw34` clipping**, because the two *product*
terms alone already exceed full scale. The candidate is **dead for `iw34`**, and it is dead
without a build. ⛔ And `ACC_SHIFT` stays untouched (`§41` `0x400000`/`0x178D0B` and
`m_rf[0x8D] = 0x009B26` calibrate it and both pass in all three §223 arms).

## 2. ★★★ WHERE `ACT 0x00`'s BUS TERM **IS** THE CAUSE — `iw91`, AND THE ADDEND IS THE **WRAP CONSTANT**

`§S1` arm F, body 0, **both buckets**:

```
   iw91  calls 2 824 160/1 255 840   clips 36/16       pre-clamp   118 .. 8 388 708
   iw92  calls   706 040/  313 960   clips 706 040/313 960         8 388 725 .. 16 777 315

   iw92 - iw91,  MIN: 8 388 725 -   118 = 8 388 607
                 MAX: 16 777 315 - 8 388 708 = 8 388 607     <-- EXACT, both endpoints
```

`8 388 607 = 0x7FFFFF = C-RAM[0x01]`, and `upd6383.cpp`'s **own** C-RAM annotation names it:

> `0x00..0x13  real parameters (LFO rate 000072, wrap 7FFFFF, 400000 ...)`

and the file's §-note on the wrap word says *"the wrap word (f31 == 2, coefficient `0x7FFFFF`)"*.

The block, from the trace and `§109`/`§119`:

```
   iw89  092.A.00.200  ACT 00 SRC 08  L = C-RAM[0x00] = 114   acc = 114<<16    (the LFO INCREMENT)
   iw90  082.2.00.1C0  ACT 00 SRC 07  L = mem[0x07] = phase   acc = (114+phase)<<16 + 203
   iw91  094.A.00.200  ST+B7, f31 = 2 (HOLD), ACT 00, SRC 08, class A   <-- §118's WRAP WORD
         store mem[0x07] <- acc_to_datum(acc)          = phase+114     (§109: +114/frame, correct)
         ALU:  acc = acc + (C-RAM[0x01] << 16)         = +0x7FFFFF     <-- THE DEFECT
   iw92  000.2.09.447  SRC 0x11(->ACCA), ACT 07  ->  mem[0x10] <- clamp(phase+114+8 388 607)
                                                    = 8 388 607, ALWAYS
```

**Measured consequence, already on disk:** `§119 TRACK iw94 mem[dp]` = `[dp10]8388607` on **8 of 8**
consecutive settled frames while `§109` shows the phase itself ramping `1006784 → 1007582` at
`+114`/frame; `D-RAM WRITES 0F:0/4748946` (never non-zero); `§120` names `0x0E/0x0F/0x10` the
modulation cells. ⇒ **the CHORUS LFO's PUBLISHED output is a full-scale DC.** The phase is fine;
its published copy is destroyed by one addend.

⇒ §118's own decode of this word family is `ST mem[Q] <- (phase + INC) mod 2**23`. **The modulus is
sitting in C-RAM as `0x7FFFFF` and the shipped model ADDS it.** That is the hypothesis this pass
tests, two-sided, default OFF.

---

## 3. WHAT THIS PASS BUILDS

| # | change | class | default |
|---|---|---|---|
| **1** | **`§S2` ACCUMULATOR TERM CENSUS** — at the adder, per `iw` per `§54` bucket: carried term, `ACT 0x00` bus term, `P` term, result, each as a datum with its FS ratio, plus the `SRC` that supplied the bus | **READ-ONLY instrument** | always on, frames > `S1_ARM_FRAME` |
| **2** | **`§S2sq` COEFFICIENT-SQUARING COUNTER** — class-A multiplies whose bus operand came from `SRC 0x08` at the **same** C-RAM index as `coef` ⇒ `P = C-RAM[c]²` | **READ-ONLY instrument** | always on, unconditional count |
| **3** | **`UPD6383_LFOWRAP`** — on `§118`'s wrap-word family (`HI_ST ∧ HI_B7 ∧ f31 == 2 ∧ ACT 0x00 ∧ SRC 0x08 ∧ coeff_consumer`), the `SRC 0x08` operand is applied as a **MODULUS** (`acc ← (datum(acc) & L) << ACC_SHIFT`) instead of as an addend | **decode arm, env-gated** | **OFF** |

⚠ **Cite the predicate, not the line.** ⚠ Change 3 touches the **adder only**; the bit-4 store's
own datum is left clamping (it clips 36/2 824 160 quiet, so it is not the damage) — a separate
question, deliberately not merged into this bisection.

### ARMS

| arm | env | what it is |
|---|---|---|
| **I** | *(none)* | shipped default. **The NULL**, and the regression bisector against `F_satcen_223.log.gz` |
| **J** | `UPD6383_LFOWRAP=1` | the wrap-word reading |

Vehicle: `coldnotes2.lua`, cold boot, isolated NVRAM, isolated `-cfg_directory` carrying
`:DSPCFG value="3"`, `-log`, triad C4/E4/G4, `-seconds_to_run 30`, visible video, one run at a time.

---

## 4. PREDICTIONS AND FALSIFIERS

### 4.1 `§S2` — KNOWN-ANSWER CONTROLS THAT CAN FAIL (arm I, quiet bucket)

The census must print, **digit for digit**, values §0.3 derived from a *different* instrument:

* **T1** `iw30`: carried `0`, bus `329 853 435 904`, P `0`, result `329 853 435 904`, bus SRC `0x08`.
* **T2** `iw32`: carried `0`, bus `0`, P `395 824 060 170`, result `395 824 060 170`.
* **T3** `iw33`: carried `395 824 060 170`, bus `274 877 906 944`, P `274 877 906 944`,
  result `945 579 874 058`, bus SRC `0x08`.
* **T4** `iw91`: bus `549 755 748 352` (= `0x7FFFFF << 16`) **constant in both buckets**, P `0`
  (f31 = 2), carried `[7 733 451 .. 549 762 367 691]`, result `[549 763 481 803 ..
  1 099 518 116 043]`.
* **T5 — THE SELF-TEST, and it is the one that matters (RULE 20):** for every printed row,
  `carried + bus + P == result`, and `result` equals `§104`'s own `acc` column for the same slot.
  ⛔ A single row where the three terms do not sum to the result means the census is hooked in the
  wrong place and **nothing else in it may be quoted**.
* **T6 — ROW COUNT, PRE-REGISTERED:** rows are emitted only where the **result** exceeds full
  scale in either bucket. Predicted arm-I rows: **between 6 and 24**, cap 48, **with** an overflow
  counter that prints even at zero. `iw16 iw17 iw18 iw19 iw33 iw91` must be among them
  (⚠ **`iw34` must NOT be**, because `iw34`'s own result is `2^38` = ½ FS — the over-scale value it
  censuses belongs to row **33**; this is the after-slot/before-slot trap, sixth occurrence, and
  naming it here is the whole point of stating which side of the slot a number came from).

### 4.2 `§S2sq` — the coefficient-squaring counter (arm I)

* **Q1 — FIRED COUNT > 0**, and `iw30`, `iw32`, `iw33`, `iw89` are among the named slots.
  ⛔ Zero ⇒ my reading of `SRC 0x08` + the class-A multiply is wrong and §0.3 collapses with it.
* **Q2** the count is **identical in arms I and J** (LFOWRAP touches the adder, not the multiply).

### 4.3 `UPD6383_LFOWRAP` — arm J, TWO-SIDED

* **W0 — FIRED COUNT, printed unconditionally with the gate's state.** Predicted **> 0**, with
  **exactly one** distinct slot in this vehicle (`iw91`, ~1 020 000 fires). ⛔ **0 ⇒ UNTESTED**,
  not inert, and it must be reported as such (rule 8 as sharpened by §220).
* **W1 — `§S1`'s `iw92` ROW MUST VANISH** (clips `0/0`). The `§S1` quiet total must fall by
  **exactly 706 040** (`9 884 596 → 9 178 556`) and the loud total by **exactly 313 960**
  (`4 391 682 → 4 077 722`) **if nothing else moves**. A different delta is itself the result and
  must be attributed before anything is claimed.
* **W2 — THE ONE THAT DECIDES IT.** `§119 TRACK iw94 mem[dp]` must stop reading
  `[dp10]8388607` on 8 of 8 frames and show a **ramp**; `§176`'s D-RAM census must show cell `10`
  MOVING. ⛔ **If W1 passes and W2 fails, the wrap is in the wrong place and the arm is DEAD** —
  removing a clip is not the same as delivering a modulation signal.
* **W3 — WHAT MUST NOT MOVE:** `§41` `unit0 0x400000 / unit1 0x178D0B`; `m_rf[0x8D] = 0x009B26`;
  `w72`'s `L = 4 194 304`; `§S1`'s `iw39` loud minimum `1 991 044`; `§54` `quiet-in 826 040 →
  826 040 silent / 0 LOUD`; `§70`/`§211` **mean 0.0 span 0, both buckets**; the `D-RAM[05]` writer
  census. ⛔ Any of these moving ⇒ the gate is not narrow and the arm is reverted.
* **W4 — `§104` region tally.** Arm I must reproduce `27/26/20 | 2/4/1 | 0/0/0 | 0/0/0`
  (`dsp/tools/s104_tally.py`). Arm J is **predicted identical**: `iw92`'s cell is `0x10`, not an
  input pickup, so body 0's input-dependence must not change. ⛔ If it does, the change is
  load-bearing somewhere it was not supposed to reach.
* ⚠ **`§70`/`§211` are a NULL and a non-zero there would NOT be audio** — it would be §222's rail
  again, and is pre-registered as a FAILURE, not a success (§216/§221/§222, three times).

### 4.4 Regression

* **R1** arm I's whole `upd6383:` report `diff`s against `F_satcen_223.log.gz` (§223 arm F, same
  vehicle, same env) with **no measured value moved** — only the additive `§S2`/`§S2sq` blocks and
  the `LFOWRAP` announcement line. ⛔ Any other divergence ⇒ `§S2` is not read-only and it is
  reverted.
* **R2** `dsp/verify.py` **BYTE-MATCH OK**; both disassembler mirrors untouched.

## 5. WHAT WOULD MAKE THIS PASS SHIP A DEFAULT FLIP

**Nothing below `W0 ∧ W1 ∧ W2 ∧ W3 ∧ W4 ∧ R1`, all six.** A removed clip is not enough; a moved
number is not enough. §217–§223 all correctly declined. **A NULL is a fine outcome**, and so is
*"the wrap constant is real, the addition is wrong, and here is the arm that proves the modulus
belongs somewhere else."*

## 6. REPORT ORDER (fixed)

`§54` first, then `§S1` totals **and** the per-`iw` rows, then `§70`/`§211` **mean AND AC span,
both buckets, every arm**, then body 0's `§104` tally, then `§S2`. Nothing is called audio before
`§54` has spoken.
