# ADJUDICATE AND APPLY — one mechanism dissolves the delay-DRAM contradiction, and the store gate loses an escape clause

NEC **uPD6383GF-3BA** (Technics SX-KN5000, IC311). Date: **2026-07-27**.
No hardware. Static analysis, the ROM corpus, constraint solving and the live
emulator only.

Labels: **MEASURED** / **PROVEN BY CONSTRUCTION** / **FORCED** / **CONSISTENT** /
**INFERRED** / **FALSIFIED** / **OPEN**.

Inputs adjudicated (all published this round):
[`dram-cursor-closure.md`](dram-cursor-closure.md) (TARGET 1 — the 42 delay-DRAM words),
[`store-gate.md`](store-gate.md) (TARGET 2 — the bit-7 store gate),
[`register-space.md`](register-space.md) (TARGET 3 — the register space).

Tool: [`../tools/adjudicate4.py`](../tools/adjudicate4.py) — stdlib only.
**Every number below comes out of it.**

```
python3 dsp/tools/adjudicate4.py partition   # SS1  the DRAM is split at 0x8000
python3 dsp/tools/adjudicate4.py segments    # SS2  ★ the descriptor is a PARTITION
python3 dsp/tools/adjudicate4.py itemI       # SS3  ★ TARGET 1 item I, resolved
python3 dsp/tools/adjudicate4.py schroeder   # SS4  ★ a retraction that never propagated
python3 dsp/tools/adjudicate4.py escape16    # SS5  TARGET 1's resurrection words
python3 dsp/tools/adjudicate4.py clrlate     # SS6  ★★ THE SHIPPED GUARD-7 ESCAPE
python3 dsp/tools/adjudicate4.py mirror      # SS7  ★★ the corpus-scope collision
python3 dsp/tools/adjudicate4.py control     # SS8  every control, shown saying NO
python3 dsp/tools/adjudicate4.py all         # ~2 min

python3 dsp/verify.py                        # BYTE-MATCH OK
python3 dsp/tools/dsp_coverage.py            # the coverage table
python3 dsp/tools/retraction_sweep.py        # now carries premise P16
~/compartilhado/kn7000_mame/tools/upd6383d_diff.sh   # MIRRORS AGREE 3057/3057
```

---

## 0. Result in one page

| # | statement | label |
|---|---|---|
| **A** | ★★★ **TARGET 1 ITEM I'S CONTRADICTION IS DISSOLVED BY ONE UNENUMERATED OPTION, AND IT IS THE SAME SHAPE AS THE BLOCKING READ.** Item I sets *"MULTI TAP's taps sit ABOVE its line base **0**"* against *"ROOM REVERB's read sits on the region **floor** with its writes above"* and concludes one of {alignment, H-DIR, R1's read slot, rotation sign} is wrong. **The two halves are stated in different units.** `0` is unit-0's region floor and the reverb's `0x8000` is unit-1's; they are the same object. MEASURED over **486 + 384** descriptor cells: **every unit-0 value ≤ 0x8000 and every unit-1 value ≥ 0x7FFF**, 11 exceptions and all of them the same cell index. Restated in one unit both algorithms say the identical thing — one cell holds the floor and every other cell is above it. **There is no rotation-sign disagreement in the corpus and R3 §5.1's sign is not contradicted.** | **MEASURED**; the dissolution is **FORCED** given the two images |
| **B** | ★★★ **AND THE FOUR-WAY DISJUNCTION RESOLVES TO `THE ALIGNMENT'.** Every reverb block carries **at least two INTERIOR cells that cannot be an address inside its own region** — `0x1E` = 32767, one below unit-1's floor, at index 30 of 32 in **12 of 12**; and `0x01`, which is **0** in eleven reverbs and `max+1` in ROOM REVERB 1, at index 1. TARGET 1's alignment is a **rigid 1:1** cell→word map with a single phase δ scored over −3…+3, and it requires `#cells == #consumers`. No rigid shift can skip an interior slot, so at δ = 0 two consuming words are handed a non-address. **`δ = 0, 20 off the shipped set' is a statement about the best RIGID map and says nothing about whether a rigid map is the right shape.** Method rule 3. | **FORCED** (the rigid map is refuted; which map is right is **OPEN**) |
| **C** | ★★ **THE DESCRIPTOR BLOCK IS A CONTIGUOUS ADDRESS PARTITION, AND IT IS A RE-DERIVATION OF `r3-delaydram.md`, NOT A DISCOVERY.** In **12 of 12** reverbs the block contains exactly **9 exact value duplicates at index offset +5 plus 1 at +11** (offset ENUMERATED 1…12, not fixed), and the twelve resulting addresses are **strictly ascending in 12 of 12**. The 11 differences are the segment lengths — ROOM REVERB 1: `83 172 356 513 739 240 119 247 428 616 360`. Its **even** two-segment sums are `255 869 979 366 1044`, which is `r3-delaydram.md` §5's chain 0 **to the digit**; its odd sums are `528 1252 359 675 976` against `r1-allpass-motif.md`'s chain 1 doubled `528 1252 360 674 976` — the ±1 is r1's dropped payload LSB. | **MEASURED**; **CONFIRMS** r3 by an independent route |
| **D** | ★★★ **THE BRIEF'S OWN STEP-5 PREDICTION USES NUMBERS `r3-delaydram.md` RETRACTED A ROUND AGO.** *"lines at [127, 435, 489, 183, 522]"* are the **halved** payloads; r3 §5(c) showed bit 7 of the tag byte is the payload's LSB and printed the corrected ladder. **0 of the 5 appear anywhere in ROOM REVERB 1's descriptor image** — not as a segment, a two-segment sum, a short-cluster pair or the pre-delay. The retraction never reached `schroeder-topology.md` §3, `r1_allpass_solve.py:2491`, `instruction-set.md`, `action-field.md`, `allpass-adder-rerun.md` or the brief. **Filed as `retraction_sweep.py` premise P16, which finds 7 LIVE sites.** | **FALSIFIED** (a propagation failure, credit to r3) |
| **E** | ★★★ **THE SHIPPED DEVICE HAD A GUARD WITH AN UNDER-ENUMERATED JUSTIFICATION, AND IT IS NOW REMOVED. THIS IS THE ONLY CODE CHANGE.** `upd6383d.h` guard 7 let a `(bit7, hi12[3:1]) == (1,1)` bit-4 word EXECUTE when its ACTION is `0x00`, because *"the CLEAR is unobservable — ACTION 0x00 substitutes the bus for the accumulator's feedback and the old accumulator cannot reach the result."* That covers `b7_f31_1_off` and `b7_f31_1_keepclear`. It does **not** cover `b7_f31_1_clrlate`, which defers the clear to **after** the word's own ALU step, where it zeroes the result whatever the ACTION was. `store-gate.md` §4 makes it worse: the class-(1,1) survivor set is **21 effects** and its first family is literally `-/clr:{never,before,after}`. **The escape is withdrawn; the word traps.** | **FALSIFIED**, and **APPLIED** |
| **F** | ★★★ **AND ITS PRICE IS ONE WORD, NOT 107.** `upd6383d.h` said *"138 at (1,1) of which **107 carry ACTION 0x00 and execute**"*. They do not execute: **106 of the 107 are refused by the SRC/ACTION anchoring guard** (`store-gate.md` item G's SRC `0x1C`/`0x00`/`0x08`, ACTION `0x1A`/`0x0E`). Exactly **one** corpus word ever reached the escape — `092.A.01.1C0`, the LFO ramp step at header I-RAM 37, slot 37 of the cold-boot frame. Frame tally **108 → 107 DECODED, 91 → 92 PARTIAL, 86 TRAP unchanged**. | **MEASURED**, a **FALSIFICATION** of a shipped comment |
| **G** | ★★★ **`store-gate.md` ITEM F'S FALSIFICATION OF THE PUBLISHED `13' IS WITHDRAWN — BOTH NUMBERS ARE RIGHT, THEY COUNT DIFFERENT SETS.** `gate_settle.py:images()` walks the **38 distinct BODY images** (2974 words); `upd6383d.h` says *"the 3057-word corpus"*, which is those images **plus the 83-word resident kernel**. Body-only: `(0,0) 12 / (0,1) 486 / (1,0) 2 / (1,1) 130 / (1,2) 29`, disagreement **11**. Full corpus: `19 / 494 / 3 / 138 / 29`, disagreement **13**. Kernel alone: disagreement **2**. Item F's *substantive* half survives and is sharpened: of the 13, **ten** trap on `hi12[3:1] > 2` and the other three are refused by guard 7, so settling the CONDITION changes the emulated machine by **ZERO** words, not one. | **MEASURED**; a published **FALSIFICATION IS WITHDRAWN** |
| **H** | ★★ **TARGET 1'S SINGLE-RELOAD RESURRECTION IS NOT DEAD — IT IS PINNED TO EXACTLY TWO NAMED WORDS.** Its 16 candidates are **14 distinct** (two appear in both of its lists). Against `register-space.md` E2's MEASURED descriptor cell set (52 cells, `0x00..0x1F` + `0x26..0x39`), **12 of the 14 are refused** — nine are C-format, where `addr8` is not an address at all, and three address cells the descriptor space does not have (including `859.0.86.822`, whose `addr8 = 0x86` TARGET 3 measured to be the unit-1 VOLUME cell). **The two survivors are `E30.C.00.404` and `82E.8.0F.000`.** TARGET 1 needs exactly two. | **CONSISTENT** (it assumes the C-format decode, itself only re-derived) |
| **I** | ★ **THE CLOSURE RESIDUE IS UNMOVED AT +0** — last frame `+0`, `1 080 959` of `1 106 880` complete frames close, min −1 / max +116, X = `0xFF` on 97.58 %. Input-stage audit `1 117 440` both-reads, **0 MISMATCHED**. Terminations `1 106 880 / 210 241 / 26 880`, identical. **No frame completes: 0 of 1 344 001, unchanged.** The comb impulse test still cannot run. | **MEASURED** |
| **J** | ★ **SAFETY.** Build clean (0 `error:`, binary 74 405 928 bytes, mtime advanced), `tools/publish-binary.sh` run, `-validate kn5000` **exit 0 and silent**, `dsp/verify.py` **BYTE-MATCH OK**, mirrors **AGREE 3057/3057** on text *and* the three execution predicates. **DSPCFG Off and On are byte-identical to the pre-change build** over a capture carrying real audio and therefore able to fail: `1 276 567` non-zero samples, peak `22 268`, all four WAVs one MD5. | **MEASURED** |
| **K** | ★ **NOTHING FROM TARGET 1 IS APPLIED AND NOTHING FROM TARGET 3 IS APPLIED.** TARGET 1 shipped nothing by its own decision and this pass agrees. TARGET 3's one FORCED result (the `is_c40` immediate is 8 bits) is a re-derivation of `output-stage-decode.md` and makes no word executable; re-run here at **7/7 forms, 57/57 words**, control **9 of 11**. Its `v>>17` writer fix re-runs at **1751/0** against `v>>1`'s **938/813**. | **MEASURED** |

---

## 1. The adjudication — what collided, and the single mechanism behind each

### 1.1 TARGET 1 vs TARGET 3 — and the answer is a change of units

| | TARGET 1 (`dram-cursor-closure.md`) | TARGET 3 (`register-space.md`) | settled |
|---|---|---|---|
| the per-unit descriptor bases | R3 candidate (iii) is *"the only survivor"*, carrier **OPEN** (0 of 14 setup fields admits an affine map to `{0x26, 0x00}`) | E2: **MEASURED** from the host's own streams — unit-1 owns cells `0x00..0x1F`, unit-0 `0x26..0x39` | ★ **they agree**, and TARGET 3's is the stronger statement. TARGET 1's closure (`entry = 0x00 + 32 + 0 = 0x20`) is independently corroborated: the 32 is E2's measured extent |
| the rotation **sign** (item I) | a **live contradiction** inside the corpus | — (did not look) | ★★★ **NEITHER, AND NO CONTRADICTION.** The two halves use different units. See §2 |
| `859.0.86.822` | a candidate **descriptor-cursor reload** | **the unit-1 VOLUME pointer** (`addr8 = 0x86`, cell measured) | ★ **TARGET 3.** The word is removed from TARGET 1's resurrection list |

**The single mechanism, in one sentence:** *a descriptor cell is always an
ABSOLUTE ADDRESS, and the two units' regions start at 0 and 0x8000, so "above
the line base 0" and "on the region floor" are the same sentence about
different halves of one 64 K DRAM.*

That is the same shape as the two previous rounds' wins — the accumulator-as-adder
(both sides right about the answer, wrong about the mechanism) and the blocking
read (two blocks solved under different read models). Here two *units* were being
read under different address models, inside one sentence.

### 1.2 TARGET 2 vs the shipped device — and the answer is the corpus

`store-gate.md` item F falsifies `upd6383d.h`'s *"13 corpus words"* and reports
**11**. `adjudicate4.py mirror` prints both, with the sets:

```
   full 3057-word corpus  {(0,0):19, (0,1):494, (0,3):1, (0,4):13, (0,6):1,
                           (1,0):3,  (1,1):138, (1,2):29, (1,5):10}   disagree 13
   38 body images only    {(0,0):12, (0,1):486, (0,4):12,
                           (1,0):2,  (1,1):130, (1,2):29, (1,5):9}    disagree 11
   the 83-word kernel     {(0,0):7,  (0,1):8,   (0,3):1, (0,4):1, (0,6):1,
                           (1,0):1,  (1,1):8,   (1,5):1}              disagree  2
```

`gate_settle.py:images()` returns the 38 distinct **body** images. The device
comment names *"the 3057-word corpus"*, which `dark_words.load_corpus()` builds
as those images **plus the header and epilogue**. 11 + 2 = 13.

**So the falsification is withdrawn, and the lesson is the one this project keeps
paying for in a new place: a corpus is a parameter too.** Neither pass stated the
denominator next to the numerator.

What survives from item F is the *price*, and it is smaller than item F said:
the three non-`f31>2` disagreement words are `090.A.00.1D5`, `090.2.FB.40E`,
`090.A.01.1C8`, and **none of them is decoded today** — they are exactly the
words guard 7 refuses. Settling `b7 & f31 == 1` vs `b7 & f31 != 2` therefore
changes the emulated machine by **zero** words.

### 1.3 TARGET 2 vs itself — the escape clause

`store-gate.md` item D is the round's most useful single measurement and it
**invalidates a guard the device already shipped**. Item D widens the class-(1,1)
effect set from three hand-named gates to **21 of 33 canonical effects**, and §4
prints the families:

```
   -/clr:{never,before,after}                     no memory access
   ST(acc->else) / ST(bus->else) @{before,after}, clr:{never,before,after}
   LD@{before,after}/clr:{never,before,after}     ★ the access is a READ into acc
```

`upd6383d.h` guard 7's escape rested on *"the clear is unobservable when the
ACTION is `LO_ACT_ACC_BUS`"*. Under `clr:before` and `clr:never` that is true.
Under **`clr:after`** — which is inside the surviving set, and which the
already-published `b7_f31_1_clrlate` gate also carries — the accumulator ends at
**0** instead of `bus + P`, at every one of those words. The argument was never
about all three gates; it was about two of them.

**Applied: the escape is removed.** §4.

---

## 2. ★ ONE 64 K DRAM, SPLIT AT 0x8000 — `adjudicate4.py partition`

```
   unit-0 algorithms: 486 descriptor cells, value range [0, 32768]
   unit-1 algorithms: 384 descriptor cells, value range [0, 64899]

   every unit-0 value <= 0x8000 and every unit-1 value >= 0x7FFF,
   with 11 exceptions -- and the violating CELL INDEX is {0x01: 11}
```

Eleven exceptions, one cell index. Cell `0x01` holds **0** in the eleven reverbs
that are not ROOM REVERB 1, and **45464** — its own highest address + 1 — in
ROOM REVERB 1. **It is not an address in any of the twelve**, which is item B's
second interior non-tap cell. What it *is* stays **OPEN**.

Restated in one unit (`adjudicate4.py itemI`):

```
   MULTI TAP DELAY (unit 0, floor 0):
      floor cell 0x2C = 0   taps 0x26/0x28/0x29/0x2A = 6000/12000/18000/24000
      taps MINUS floor                              = 6000/12000/18000/24000  ALL ABOVE
   ROOM REVERB 1 (unit 1, floor 0x8000 = 32768):
      floor cell 0x03 = 32768   pre-delay cell 0x00 = 33568  -> +800
      cells BELOW the floor: only 0x1E = 32767, the sentinel
```

### 2.1 The sentinel, located positionally

**MEASURED:** 90 of 91 algorithms ship a cell whose value is exactly `0x8000`
(unit-0) or `0x7FFF` (unit-1); ENSEMBLE is the one that does not. It sits at
index **n−2** in **79** of the 90 and at n−1 in **11** — and those 11 are
*exactly* the 2-cell blocks, where n−2 is index 0 and there is no interior slot.

The reading *"a wrap sentinel"* is **INFERRED**, and the enumeration is printed
beside it because only one member of it is a direction claim:

* **(a)** *the address one step beyond my region in the direction the pointer
  travels* → the two units run in **opposite** directions;
* **(b)** *the address of the partition line, named from my own side* → `0x8000`
  for the unit below it, `0x7FFF` for the unit above it, **no direction implied**;
* **(c)** a limit register compared with `!=` rather than a wrap constant.

(b) and (c) need no direction and nothing here separates them from (a).
**The sentinel is NOT evidence about direction, and `DRAM-DIR` stays exactly
where `dark-words.md` §6 and TARGET 1 item G left it.**

---

## 3. ★ THE DESCRIPTOR BLOCK IS A PARTITION — `adjudicate4.py segments`

The offset is **enumerated 1…12**, not fixed:

```
   duplicate pairs over the whole corpus, by index offset:
     d=1:2  d=2:1  d=3:1  d=4:8  d=5:117  d=11:12

   algo 16..27 (the twelve reverbs)  n=32  d=5:9  d=11:1     <- identical
   algo  8 GATED REVERB              n=20  d=5:7
   algo  3 ENHANCER                  n= 8  d=5:2
   algorithms with NO duplicate at any offset: 71 of 91
```

**The test can say NO and does: 71 of 91 algorithms show nothing.**

### 3.1 Controls, each demonstrated rejecting

```
   CONTROL -- permutation null.  Shuffle ROOM REVERB 1's own 32 values 4000
   times (the multiset is PRESERVED, so the duplicates are still there and only
   their alignment is destroyed) and take the best offset each time:
       mean 1.96, max 5, >= 9 in 0 of 4000

   CONTROL A -- the ascending property.  Assign the twelve chain values to the
   twelve chain positions at random, 200 000 times:
       strictly ascending in 0 of 200000        (the ROM: 12 of 12 reverbs)

   CONTROL B -- roundness.  If the DIFFERENCES are the designed delays and the
   VALUES are addresses, the differences carry the round numbers:
       pre-delay (cell 0x00 - cell 0x03) : 11 of 12 are multiples of 100
                                           [800, 20, 2000, 2000, 500, 1000,
                                            2000, 2000, 1000, 1000, 2000, 2000]
       the RAW cell values               :  2 of 384
       ALL pairwise differences (null)   :  107 of 5952  (1.8 %)
```

Control B is the one that decides between *"the value is the delay"* and *"the
value is an address and the difference is the delay"*, and it says the second at
11 of 12 against a 1.8 % background. It is also an independent re-derivation of
`r3-delaydram.md` §5(b).

### 3.2 The ladder, for all twelve

```
   algo 16 ROOM REVERB 1     83 172 356 513 739 240 119 247 428 616 360
   algo 17 ROOM REVERB 2    166 344 713 1027 1478 400 239 495 856 1232 600
   algo 18 PLATE REVERB 1   335 569 1107 1074 2495 600 512 870 1078 1669 800
   algo 19 PLATE REVERB 2   335 1274 1007 569 2095 800 2469 870 1678 512 1800
   algo 20 CONCERT REVERB 1 335 569 707 1250 1674 480 512 870 678 900 840
   algo 21 CONCERT REVERB 2 335 569 707 1264 2095 1000 512 870 1878 2869 1800
   algo 22 DARK REVERB 1    335 569 707 1274 1895 1200 512 870 1878 2869 1800
   algo 23 DARK REVERB 2    335 569 707 1274 1895 800 512 870 1878 2869 1200
   algo 24 BRIGHT REVERB 1  2095 569 1469 1274 335 600 512 870 1278 707 1000
   algo 25 BRIGHT REVERB 2  335 569 707 1274 1895 1000 512 870 1878 2869 1400
   algo 26 WAVE REVERB 1    335 569 1107 1874 2295 6000 512 870 1678 2669 5400
   algo 27 WAVE REVERB 2    335 569 1107 1674 2295 4000 512 870 1478 2669 3400

   the SHORT cluster (0x1B,0x18) (0x1C,0x19) (0x1D,0x1A), and the pre-delay:
   algo 16  [110, 109, 543]   pre-delay 800      algo 22  [206, 209, 1044]  2000
   algo 17  [154, 157, 782]   pre-delay  20      algo 23  [308, 513, 1065]  2000
   algo 18  [308, 213, 465]   pre-delay 2000     algo 24  [206, 209, 1044]  1000
   algo 19  [308, 313, 965]   pre-delay 2000     algo 25  [308, 313, 1565]  1000
   algo 20  [308, 313, 965]   pre-delay  500     algo 26  [410, 411, 2078]  2000
   algo 21  [410, 410, 679]   pre-delay 1000     algo 27  [513, 513, 2598]  2000
```

**Attribution.** `r3-delaydram.md` §5 already publishes ROOM REVERB 1's chain 0
as `255/869/979/366/1044` and `r1-allpass-motif.md` §3 its chain 1 as the raw
`264/626/180/337/488`. This pass adds only that the two chains are one object —
an **11-segment contiguous partition** whose even and odd two-segment sums are
exactly those two chains — and the structural evidence (§3.1) that the object is
a partition rather than a list.

---

## 4. ★★ WHAT WAS APPLIED, AND WHY IT COSTS A WORD

Two files, one behavioural change, kept identical in both mirrors.

```
   src/devices/cpu/upd6383/upd6383d.h    guard 7  + two comment blocks
   dsp/tools/dsp_disasm.py               alu_decoded() guard 7 + comment
   src/devices/cpu/upd6383/upd6383.cpp   comment only (st_suppressed is now
                                         unreachable from alu_step)
```

Before:

```cpp
    const u16 f = hi_f31(hi12(w));
    if (f == 1 && lo_act(w) != LO_ACT_ACC_BUS)  return false;
    if (f != 1 && f != 2)                       return false;
```

After:

```cpp
    if (hi_f31(hi12(w)) != 2)                   return false;
```

### 4.1 The measurement that decided it — `adjudicate4.py clrlate`

```
   corpus: 708 words carry bit 4; (b7,f31)=(1,1): 138; of those ACTION 0x00: 107
   of the 107, the shipped decoder actually EXECUTES 1

   IN THE COLD-BOOT FRAME the escape fires at 1 of the 285 slots:
     slot  37  I-RAM  37  092.A.01.1C0   header 0..49  (pre unit-0 call)

   FORWARD WALK (the perturbation `acc <- 0' taken AFTER the ALU, followed until
   a word EXPOSES the accumulator -- SRC 0x10, or a live bit-4 store -- or KILLS
   the dependence -- ACTION 0x00 with a non-acc source, or f31 == 0):
     slot  37 -> UNDECIDABLE at slot 38
   over every body image: 1 escape site, {'UNDECIDABLE': 1}, 0 OBSERVABLE

   CONTROL -- can the walk say OBSERVABLE?  Plant the perturbation at every one
   of the 285 slots: 66 of 285 are OBSERVABLE.  The walk is not vacuous, and it
   does NOT simply agree with the shipped device -- at the escape word it says
   UNDECIDABLE, not DIES.
```

So the escape's *consequence* is invisible today only because the word's
successor is itself undecoded and the frame traps anyway. That is not a reason
to keep executing it. **The standing rule is that a word whose semantics remain
ambiguous must keep trapping; losing a decode is acceptable, shipping a guess is
not.** It traps.

### 4.2 What was NOT applied, and why

* **TARGET 1** — nothing. Its own conclusion, and this pass agrees: `DRAM-ADDR`
  and `DRAM-DIR` are both still open, and item B above *weakens* the alignment
  rather than strengthening it.
* **TARGET 2's `SRC 0x00 = FEEDBACK L`** — a statement about a *user parameter's
  default value*, not about an instruction. It cannot decode a word, and
  `SRC 0x00` stays CONSISTENT. The 30 PARTIAL + 10 TRAP slots keep trapping.
* **TARGET 2's item D `LOAD` reading** — FORCED only negatively (`0 of 17 928`
  write `mem[ptr]`). The positive side has 21 survivors in three families;
  applying any of them would be a guess. Guard 7 now refuses the whole class.
* **TARGET 3's B2** — FORCED, and already implemented (`output-stage-decode.md`'s
  payload rule). Re-run here at 7/7 forms, 57/57 words. No word becomes
  executable.
* **TARGET 3's D1 (`+1` auto-increment)** — FORCED, but it describes the HOST's
  write port, which is `kn5000_dsp_params.py` and `register_space.py`, not the
  device. Nothing in `src/` reads it.

---

## 5. THE BEFORE / AFTER TABLE

Live, `DSPCFG On`, cold boot + the same 28 s keybed programme, same pre-init
nvram, same cfg as the previous two passes.

| | before | after |
|---|---|---|
| words executing **something** | 199 of 285 | **199** of 285 |
| words executing **FULLY** | 108 | ★ **107** |
| words executing **addressing only** | 91 | ★ **92** |
| words executing **nothing** | 86 | **86** |
| ended on wait word / CAP / OVERRUN | 1 106 880 / 210 241 / 26 880 | **identical** |
| **frames completed** | 0 of 1 344 001 | **0 of 1 344 001** |
| ★ **operand-pointer closure residue, last frame** | **+0** | ★ **+0** |
| ★ complete frames that CLOSED | 1 080 959 of 1 106 880 | **identical** |
| residue min / max | −1 / +116 | **identical** |
| frame-entry pointer X | `0xFF` on 97.58 % | **identical** |
| input-stage audit | 1 117 440 both-reads, **0 MISMATCHED** | **identical** |
| partial words executed, all frames | 99 868 800 | 100 982 400 |
| ★ **descriptor-cursor closure residue** | *not testable* | ★ **still not testable** — §6 |

Coverage (`dsp_coverage.py`), the only rows that move:

```
   region                      words  tier1  tier1%   tier2   t1+t2%
   resident kernel I-RAM 0..82    83   14->13  16.9 -> 15.7%    17   37.3 -> 36.1%
      ...header  I-RAM  0..59     60   12->11  20.0 -> 18.3%    14   43.3 -> 41.7%
   FRAME FLOOR kernel + reverb   216   83->82  38.4 -> 38.0%    49   61.1 -> 60.6%
   FRAME FLOOR as linked         216   85->84  39.4 -> 38.9%    47   61.1 -> 60.6%
   all 38 distinct body images  2974     1234  41.5% (unchanged) 329  52.6%
   reverb image (algo 16)        133       69  51.9% (unchanged)  32  75.9%
```

The body corpus does not move because the word is in the kernel.

**Does any frame complete? NO. 0 of 1 344 001, 100.00 % trapped.** The audible
output is exactly the dry tone generator, so step 5 of the brief has nothing to
listen to — and §6 changes what it should listen *for* when it does.

---

## 6. ★ THE COMB IMPULSE TEST — the brief's own numbers are retracted

`adjudicate4.py schroeder`:

```
   ROOM REVERB 1, read off the descriptor image:
     the 11-segment partition : [83, 172, 356, 513, 739, 240, 119, 247, 428, 616, 360]
     two-segment sums, EVEN   : [255, 869, 979, 366, 1044]   <- r3's chain 0, IDENTICAL
     two-segment sums, ODD    : [528, 1252, 359, 675, 976]   <- r1's chain 1 x2, +-1
     short cluster (3 pairs)  : [110, 109, 543]
     pre-delay 0x00-0x03      : 800     long head 0x02-0x03: 8905

   the brief's five numbers   : [127, 435, 489, 183, 522]
   present anywhere in the descriptor image: NONE -- 0 of 5

   CONTROL: probing with [83, 172, 356, 513, 739] -> 5 of 5 present.
```

**When a frame finally completes, the impulse must be ≥ 4 × the LONGEST line.**
That is `4 × 8905 = 35 620` samples for the head (TARGET 1's own figure) and
`4 × 12 696 = 50 784` if the whole used region is to recirculate — **not
`4 × 522`.** A test sized against the brief would be the fourth recurrence of the
amputated-feedback defect, and it is caught here *before* the experiment rather
than after.

Filed as `retraction_sweep.py` premise **P16**, which reports **7 LIVE sites**
still quoting the halved list (`instruction-set.md` ×2, `action-field.md`,
`allpass-adder-rerun.md`, `r1-allpass-motif.md` ×2, `r3-delaydram.md`). Its
`selftest` still passes in both directions.

---

## 7. FOR THE DELAY-DRAM PASS — the resurrection, narrowed to two words

`adjudicate4.py escape16`. TARGET 1 names 16 header/epilogue words carrying the
hi12 format-escape bit with no assigned role, and says *"two more descriptor
consumers would resurrect a one-reload machine with no free parameter at all"*.
The 16 are **14 distinct** (`C16.9.AB.000` and `C00.9.84.000` appear in both of
its lists). Against `register-space.md` E2's measured 52-cell descriptor space:

```
   REFUSED (12):  C0A.0.E0.000  C0A.2.92.820  C04.3.12.820  C42.4.57.820
                  C0A.4.B1.820  C64.5.A2.000  C64.6.A2.007  C16.9.AB.000
                  C00.9.84.000  980.5.20.402  859.0.86.822  A3C.D.9F.287
   STILL POSSIBLE (2):  E30.C.00.404   82E.8.0F.000
```

Nine of the twelve are refused because they are C-format, where `addr8` is part
of a 13-bit immediate and is not an address at all; three because their `addr8`
is not a descriptor cell — including `859.0.86.822`, whose `0x86` TARGET 3
measured to be the **unit-1 VOLUME** cell and TARGET 2 flagged as the one site
where bit 4 and the format escape collide. Three passes, three readings, one
word, and TARGET 3's is the one with a measurement behind it.

**The next experiment is now small and named:** decide `E30.C.00.404` and
`82E.8.0F.000`. If both consume a descriptor cell, TARGET 1's `|R| = 1` machine
holds with **no free parameter** and the frame-entry cursor question closes; if
either does not, `|R| ≥ 2` and R3 candidate (iii) stands alone. **CONSISTENT, not
FORCED** — the C-format refusal rests on the C-format decode, which
`register-space.md` B2 only re-derives.

---

## 8. PREDICT-THEN-CHECK — 3 hits, 8 misses, 2 halves

Written down before each experiment.

| # | prediction | result |
|---|---|---|
| **P-1** | the DRAM value partition at `0x8000` holds with **0** exceptions | ★ **MISS** — 11, and they are informative: all cell `0x01`, which is therefore a second non-address cell |
| **P-2** | the reverb descriptor block is a contiguous address partition with duplicated boundary cells | **HIT** — 9 pairs at d=5 + 1 at d=11, 12 of 12, permutation null 0 of 4000 |
| **P-3** | the sentinel sits at index n−2 uniformly | ★ **PARTIAL** — 79 of 90; the 11 exceptions are exactly the 2-cell blocks |
| **P-4** | the brief's five line lengths would be a **new** falsification | ★ **MISS, and the most useful one** — `r3-delaydram.md` §5(c) retracted them a round ago. What I found was a retraction that never propagated, not a new fact |
| **P-5** | the 11-segment ladder would be a new object | ★ **MISS** — its even two-segment sums *are* r3's chain 0, digit for digit, and its odd sums are r1's chain 1 doubled |
| **P-6** | the shipped guard-7 escape is unsound, and it is worth ~107 words | ★ **HALF** — unsound YES; worth **1** |
| **P-7** | the observability walk would find OBSERVABLE sites among the escape words | ★ **MISS** — 0. The single site is UNDECIDABLE, because its successor traps |
| **P-8** | TARGET 3's measurements would leave TARGET 1's resurrection with 0 or 1 candidate | ★ **MISS** — exactly **2**, which is exactly what the resurrection needs. The opposite of the expected outcome |
| **P-9** | TARGET 2's class census would reproduce | ★ **MISS** — it does not, and the reason (body-only vs full corpus) withdraws one of TARGET 2's published falsifications |
| **P-10** | the frame tally would move **up** if anything were applied | ★ **MISS** — it moved **down** by one |
| **P-11** | the operand-pointer closure residue stays **+0** | **HIT** |
| **P-12** | DSPCFG-Off audio bit-identical | **HIT** — and On too; all four captures one MD5 over 1 276 567 non-zero samples |
| **P-13** | at least one of the three passes has a FORCED result that decodes a word | ★ **MISS** — zero. The round's only code change **removes** a decode |

---

## 9. CONTROLS DEMONSTRATED SAYING NO

| # | control | shown rejecting |
|---|---|---|
| **K1** | the duplicate-pair test | **71 of 91** algorithms show nothing at any offset — a corpus-wide "yes" was never on offer |
| **K2** | the value partition | with the unit labels **SWAPPED**, **757** violating cells against the true labelling's 11 |
| **K3** | the sentinel position | asked at index **0** it scores **0 of 91**; at n−2, **79 of 91** |
| **K4** | the Schroeder comparison | fed the ROM's own numbers it says **5 of 5**; fed the brief's, **0 of 5** |
| **K5** | the observability walk | **66 of 285** planted perturbations are OBSERVABLE, and at the escape word the walk says **UNDECIDABLE**, not DIES — it is not agreeing with the device by construction |
| **K6** | the permutation null | preserves the multiset, so the ten real duplicate *values* survive and only their alignment is destroyed; `>= 9` in **0 of 4000** |
| **K7** | the ascending-chain null | **0 of 200 000** random assignments of the same twelve values ascend |
| **K8** | the mirror (§7) | two of its four re-run numbers are values this round contradicts (`v>>1` 938/813) or re-scopes (the 13) — it is not self-fulfilling |
| **K9** | the DSPCFG audio capture | carries **1 276 567** non-zero samples, peak **22 268**, so a behaviour change would show |

---

## 10. WHAT IS NOW THE HIGHEST-RANKED BLOCKER

Unchanged in rank, sharpened in content: **`DRAM-ADDR` / `DRAM-DIR`, 42 slots,
0 PARTIAL / 42 TRAP.** But the shape of the question has changed twice this
round and both changes point the same way:

1. the descriptor block is **not** a flat tap list, so the cell→word map is not
   a rigid shift (item B), and
2. every line length in it is a **difference of two cells**, so a word that
   consumes "the delay" must consume **two** descriptor cells or one cell and a
   register.

**The precise next experiment.** Take ROOM REVERB 1's 11-segment partition (§3.2)
and its 12 boundary addresses as *given* — they are host data, no instruction is
involved — and solve for the cell→word map that makes R1's two FORCED words
(`880.1.60.2D4` = READ, `880.1.20.655` = WRITE, forced 36/36) address the two
ends of the **same** segment, with the two non-address cells (`0x01`, `0x1E`)
assigned to whatever consumes region constants. That is a matching problem over
32 cells and ~32 consumers, not a one-parameter phase scan, and it is decidable
statically. **Enumerate the map family before scoring anything** — the
one-parameter rigid family is now known to be the wrong one, and it is the third
time in four rounds that the missing option was in the model rather than in the
parameters.

Second-ranked and cheap: **decide `E30.C.00.404` and `82E.8.0F.000`** (§7). Two
words, and they close TARGET 1's `|R| = 1` vs `|R| = 2` question outright.

---

## 11. HOUSEKEEPING

* `dsp/verify.py` — **BYTE-MATCH OK**. No `.dsm` regenerated.
* `tools/upd6383d_diff.sh` — **MIRRORS AGREE, 3057/3057**, text *and* the three
  execution predicates `D/A/K`.
* Build: 0 `error:` / `Error [0-9]` in the log; binary **74 405 928** bytes,
  mtime advanced; `tools/publish-binary.sh` run.
* `-validate kn5000` — **exit 0, zero bytes of output**.
* Audio: `before_on`, `after_on`, `before_off`, `after_off` all
  `ed4353643dd5ffbf2a526634e5831203`. 1 344 001 frames, 1 276 567 non-zero,
  peak 22 268.
* No process left running; all MAME launches `timeout`-wrapped, visible video on
  `:0`, never more than one at a time.
* `dsp/README.md` carries rows added by TARGET 1 and TARGET 2 that neither
  committed (each avoided sweeping the other's in-flight edit). **This pass
  commits that file**, carrying both, plus its own row.
