# DRAM-DIR — a direction test with DEMONSTRATED power, and the audit of the claims that were settled by a score

NEC **uPD6383GF-3BA** (Technics SX-KN5000, IC311). Date: **2026-07-27**.
No hardware. Static analysis, the ROM corpus and constraint solving only.

Targets: **(A)** build a direction test *proven* able to separate instruction-based
rules from instruction-blind ones — the thing
[`dram-cursor-closure.md`](dram-cursor-closure.md) item F showed did not exist;
**(B)** use it if it has power; **(C)** sweep the published notes for other claims
established by SCORING and ask them the same question.

Tool: [`../tools/dram_dir.py`](../tools/dram_dir.py) — stdlib only.
**Every number below comes out of it.**

```
python3 dsp/tools/dram_dir.py oracle     # 1  the instrument, and what it CANNOT do
python3 dsp/tools/dram_dir.py rivals     # 2  ★★ the rival family + THE EXHAUSTIVE FIELD ENUMERATION
python3 dsp/tools/dram_dir.py separate   # 3  ★★★ RULE 7 — scored ONLY where the rivals disagree
python3 dsp/tools/dram_dir.py power      # 4  ★★★ PLANTED GROUND TRUTH — recovery AND rejection
python3 dsp/tools/dram_dir.py null       # 5  permutation / collision / replication nulls
python3 dsp/tools/dram_dir.py phase      # 6  the alignment delta, re-enumerated (two MISSES)
python3 dsp/tools/dram_dir.py polarity   # 7  ★★ the ONE remaining bit, and who disagrees
python3 dsp/tools/dram_dir.py audit      # 8  ★★ SECOND TASK — the rule-7 audit
python3 dsp/tools/dram_dir.py control    # 9  every control, each shown saying NO
python3 dsp/tools/dram_dir.py all --trials 60      # ~7 min

python3 dsp/verify.py                    # BYTE-MATCH OK
```

**Nothing was applied.** No MAME source touched, neither disassembler mirror
edited, no `.dsm` regenerated, `dsp/verify.py` reports **BYTE-MATCH OK**, and no
word gains or loses an executable semantic. Method rule 6: the one FORCED result
here is forced *inside a printed model class* and its polarity is open, so it
does not ship.

---

## 0. Result in one page

| # | statement | label |
|---|---|---|
| **A** | ★★★ **THE INSTRUMENT DOES EXIST, AND THE LAST ROUND'S FAILURE WAS ITS SCORING FUNCTION, NOT ITS DATA.** `dram-cursor-closure.md` scored direction rules by *"does SOME write cell of this algorithm sit on the correct side of this read"* — a predicate so weak that any alternating labelling passes it, which is exactly why `C-CELLPAR` matched `H-DIR`. The same descriptor values carry a **far sharper** structure that was never used: **two consumers of one algorithm handed the SAME cell value**. MEASURED over **83** algorithms where the map is total (of **91** that ship cells; **890** class-1 FORMAT-ESCAPE consumer words corpus-wide; **829** cells in the aligned set): **557 singleton values, 136 doubles, ZERO triples**. Collision null: re-drawing every value uniformly in its unit's 32 K region gives **0–3** collisions over 2 000 trials against the corpus's **136**. | **MEASURED**; the read/write reading of a pair is **INFERRED** (§1.2) |
| **B** | ★★★ **FORCED — IF ONE BIT OF THE 36-BIT WORD CARRIES THE DELAY-DRAM DIRECTION, IT IS `addr8` BIT 6, AND NOTHING ELSE.** Not a scored preference: an **exhaustive** enumeration. On the **133** non-C-format pairs, over *every* boolean function of each field — `addr8` **2 of 8** functions reach zero violations (a rule and its own global flip), `SRC` **0 of 64**, `hi12` **0 of 4**, `ACTION` **0 of 128**, `lo12` **0 of 2048**, `class4` **0 of 2**, the `lo12` MODE bit **0 of 2**, `hi12[3:1]` **0 of 2**. Bit by bit over all **36** bits, exactly **one** reaches zero — bit 18, `addr8` bit 6; the runner-up is `lo12` bit 0 at **5** violations. ★ And it is **robust to the alignment phase**: over δ ∈ −4…+4, every δ at which *any* bit reaches zero (δ = 0, +2, +3) selects `addr8` bit 6. | **FORCED** within the enumeration printed in §2 |
| **C** | ★★★ **`H-DIR` IS FALSIFIED, AND SO IS ITS WHOLE FIELD.** `dark-words.md` item F's *"SRC `0x0B` ⟺ the delay-line READ"* fails **21 of 136** pairs (**18 of 133** non-C-format). At the **21** pairs where `H-DIR` and the instruction-blind cell-parity control disagree, **the control wins 19–5**. And the falsification is not of one predicate but of the field: **no function of `SRC` whatever** satisfies the oracle. The SRC pairs on which it fails: `(19,10)×13, (00,00)×4, (19,00)×2, (00,07)×1, (19,11)×1`. | **FALSIFIED** |
| **D** | ★★★ **THE TEST IS DEMONSTRATED TO SEPARATE AN INSTRUCTION RULE FROM AN INSTRUCTION-BLIND ONE — AND THE SEPARATION IS FOUR SITES WIDE. I SAY SO RATHER THAN QUOTING 97 %.** `H-ADB6` vs `C-CELLPAR` disagree at **7 of 136** pairs. Three of those are sites *no* instruction rule can explain (item E) and both rules fail them. At the remaining **four** — S.DELAY+CHORUS, S.DELAY+VIBRATO, S.DELAY+PHASER, AUTO WAH+S.DELAY, all at cell-index offset **+4** where the ladder's offset is **+5** — `H-ADB6` is right **4 of 4** and `C-CELLPAR` wrong **4 of 4**. Priced in the other unit too: those 4 pairs are **2 distinct word-pair shapes**. | **MEASURED**; the separation is real and **THIN** |
| **E** | ★★★ **THE THREE SITES NO INSTRUCTION RULE CAN EVER EXPLAIN — AND THEY ARE PROVED ACCIDENTAL BY REPLICATION, NOT EXCLUDED BY FIAT.** The remaining 3 pairs carry the **same 36-bit word on both sides** (`C40.1.80.000 | C40.1.80.000`), so no function of the instruction can separate them — which is why even a full lookup table on the whole word scores **0 of 8192** when they are included. Replication decides them without fitting anything: the twelve reverbs are twelve instances of one program, and cell-index pair `(0x19,0x1D)` holds equal values in **3 of 12** while all ten ladder pairs hold in **12 of 12**. On the **120 structural** reverb pairs `H-ADB6` fails **ZERO**. | **PROVEN BY CONSTRUCTION** + **MEASURED** |
| **F** | ★★★ **THE POWER TEST, AND ITS ASYMMETRY IS THE MOST IMPORTANT LINE IN THE PASS.** Plant a ground truth, run the instrument unchanged. Under a **random** matching the planted rule is the unique minimum in **6 of 7** plants and rivals land 21–108 violations away. Under the **geometry-preserving** plant — which keeps the real corpus's own cell-index offsets, because a pair's offset is a property of the microprogram and not of the direction rule — it is **5 of 7**, and the decisive cell is this: *plant `H-ADB6` → `C-CELLPAR` scores 7 (rejected); plant `C-CELLPAR` → `H-ADB6` scores **0** (NOT rejected).* **The instrument can refute the blind rule in favour of the instruction rule and cannot do the converse.** `H-ADB6` therefore **survives**; it is not crowned. | **MEASURED**, and a **limitation**, not a result |
| **G** | ★★ **`DRAM-DIR` HAS COLLAPSED FROM `13 DISTINCT WORDS, WHOLLY OPEN' TO ONE BIT — THE POLARITY — AND THAT BIT *IS* THE ROTATION SIGN.** Three witnesses, two ways. **(1)** `r1-allpass-motif.md` F1, algebraic, `read_slot` 0 ×36 with the swap at zero ⇒ `addr8 0x60` = **READ**. **(2)** NEW, out of the oracle itself: in **133 of 133** decidable pairs the `bit6 = 0` access is **earlier in program order**; a same-address pair is write-then-read (a zero-delay forward) unless it means a **full 32768-sample recirculation** ⇒ `0x60` = **READ**. **(3)** `r3-delaydram.md` §6.3's MULTI TAP tap count — four evenly spaced `DELAY n (ms)` cells, all on `bit6 = 0` words, and a multi-tap has one write and many reads ⇒ `0x60` = **WRITE**. Vote **2–1**. | **OPEN** — a vote is not a forcing |
| **H** | ★★ **THE STORE GATE'S BIT-7 DIRECTION READING DOES NOT REACH THE DELAY DRAM.** The brief names `hi12` bit 7 as the live candidate. MEASURED: it is **EQUAL on both members of 133 of 136 pairs**; a direction field must differ there. `store-gate.md` item D is a statement about class-`(1,1)` **store** words and is untouched; what is **excluded** is extending it to this family. | **FALSIFIED** (the extension only) |
| **I** | ★★ **SECOND TASK — SEVEN PUBLISHED CLAIMS AUDITED, TWO FALL.** `dark-words.md` item F's `H-DIR` (item C above) and `dram-cursor-closure.md` item I's *"62 clean algorithms to 10"* (produced by the instrument the same note falsified, and never withdrawn when the contradiction was dissolved). `adjudication-round4` item B's **FORCED** refutation of the rigid map is **downgraded to CONSISTENT** — its option set omits *"a consumer may take a NON-ADDRESS operand"*. `store-gate.md` C/D/E, `register-space.md` D1 and `adjudication-round4` item C **survive**, for reasons given per row in §8. | **MEASURED** |
| **J** | ★ **NOTHING IS APPLIED, AND THE PRICE OF THAT IS ZERO.** No word becomes executable: `DRAM-ADDR` (the per-unit base carrier) is still open, so a settled direction alone does not unblock the 42 delay-DRAM slots. Frame tally unmoved. `dsp/verify.py` **BYTE-MATCH OK**; no device or disassembler file touched; the rendered audio is untouched **by construction**. | **MEASURED** |

---

## 1. The instrument, stated before it was used

### 1.1 What it is

A descriptor cell is an **absolute delay-DRAM address**
(`r3-delaydram.md` §5.1; re-derived independently by `adjudication-round4`
item C from the contiguous-partition structure). Therefore:

> **PAIR-OPPOSITION.** If two consumers of one algorithm are handed the **same**
> descriptor value, one of them **writes** that address and the other **reads**
> it.

The justification is an economy argument, and it is labelled INFERRED, not
proven: two writes to one address in one frame make the first dead, and two
reads of one address in one frame return the same sample twice. A machine with
**83** words of resident kernel and 133-word reverb bodies does not spend
**136** slots on either.

The pairing is computed from the **host's canned values alone** — no instruction
field enters it. A direction rule reads **only** the instruction. The two data
sources are disjoint, which is what `dram-cursor-closure.md` §5.3 was reaching
for and did not get.

### 1.2 What it cannot do — said before the scores, not after

* **It is invariant under the global flip.** Swapping R and W everywhere changes
  no score. It decides the **partition** and never the **polarity**. §7 is where
  the polarity goes and it stays **OPEN** there.
* **It cannot crown a rule, only refute one.** `C-DUPLO` ("inside an equal-value
  pair the lower cell index is the write") scores a perfect **0 by
  construction** because it *knows the oracle*. It is included for exactly that
  reason. What separates `H-ADB6` from it is **coverage**, and coverage is a
  count, not a score: `C-DUPLO` is undefined on the **557** singleton cells;
  `H-ADB6` labels all **829**.
* **The premise could be false.** §7.1 enumerates that branch (M4) and the
  collision null refutes it.

### 1.3 The pairing geometry, because it is what limits the power

```
   cell-INDEX offset between the two members: {4: 7, 5: 117, 11: 12}
   distinct (word, word) SHAPES among the 136 pairs: 12
      880.1.20.655 | 880.1.60.2D4   x64        C40.1.80.000 | C40.1.80.000   x3
      880.1.20.64B | 880.1.60.2D4   x25        880.1.20.2C7 | 900.1.60.1D5   x2
      880.1.20.655 | 880.1.60.2DA   x24        880.1.30.00B | 900.1.60.1D5   x1
      880.1.20.655 | 880.1.60.40E   x12        880.1.30.000 | 880.1.60.000   x1
      880.1.20.655 | 880.1.60.41A   x1         880.1.20.655 | 880.1.60.000   x1
      880.1.20.64B | 880.1.60.447   x1         880.1.20.64B | 880.1.60.000   x1
```

★ **The discount this pass applies to `H-DIR` applies to this pass.** 136 pairs
are not 136 independent facts; they are **12 word-pair shapes** replicated across
algorithms. Every claim above is priced in both units.

---

## 2. The rival family, and the one enumeration that FORCES anything

Twenty-two instruction-reading rules and eight instruction-blind ones were
scored (`rivals`). The head of the table, over **136 pairs / 18 algorithms /
829 cells**:

```
   H-ADB6    addr8 bit 6 -> R                                   3    97.8%
   H-AD60    addr8 == 0x60 -> R                                 3    97.8%   (identical, §2.1)
   H-SRC19   SRC == 0x19 -> W                                   7    94.9%
   C-CELLPAR cell-index parity        (instruction-blind)       7    94.9%
   C-SLOTPAR consumer-order parity    (instruction-blind)       7    94.9%   (identical, §2.1)
   H-SRC0B   SRC == 0x0B -> R   (H-DIR)                        21    84.6%
   H-ACT1415 ACTION in {14,15} -> R                            70    48.5%
   H-HI7     hi12 bit 7 -> W   (store-gate.md D)              133     2.2%
   C-ALLW    everything is a WRITE                             136     0.0%
   C-DUPLO   dup pair: lower cell = W (** KNOWS THE ORACLE **)   0   100.0%
```

### 2.1 Degeneracies, looked for before anything is believed (rule 4)

```
   H-ADB6 == H-AD60                          (0x30 and 0x20 are never partners)
   H-ADB7 == H-ADB5 == H-HI6 == H-HI10       (all constant across every pair)
   H-SRCB3 == H-LO9        H-SRCB0 == H-LO6        H-LO5 == H-LO11
   C-CELLPAR == C-SLOTPAR                    (under a rigid map, cell = base + slot)
   C-FIRSTW == C-DUPLO                       (both are the oracle in disguise)
```

`C-CELLPAR` and `C-SLOTPAR` being the **same machine** is worth stating: the
brief lists "cell parity" and "slot parity" as two nuisance rivals, and on this
data they are one.

### 2.2 ★★★ THE EXHAUSTIVE ENUMERATION — WHICH FIELD CAN CARRY DIRECTION AT ALL

> **MODEL CLASS, printed next to the claim (method rule 3):** *the direction is a
> function of ONE named field of the instruction word.* For each field **every
> one of the 2^k boolean functions of its k observed values** is tried — not a
> hand-picked predicate. A field CAN carry direction iff some function of it
> gives the two members of **every** pair opposite labels.

```
   --- scored on all 136 pairs ---
      hi12         3 values ->    0 of    8   *** CANNOT CARRY DIRECTION ***
      class4       1 value  ->    0 of    2   ***           "            ***
      addr8        4 values ->    0 of   16   ***           "            ***
      lo12        11 values ->    0 of 2048   ***           "            ***
      SRC          6 values ->    0 of   64   ***           "            ***
      ACTION       7 values ->    0 of  128   ***           "            ***
      whole word  13 values ->    0 of 8192   ***           "            ***

   --- scored on the 133 NON-C-FORMAT pairs ---
      hi12         2 values ->    0 of    4   *** CANNOT CARRY DIRECTION ***
      addr8        3 values ->    2 of    8   e.g. {0x20,0x30} on one side
      lo12        11 values ->    0 of 2048   *** CANNOT CARRY DIRECTION ***
      SRC          6 values ->    0 of   64   *** CANNOT CARRY DIRECTION ***
      ACTION       7 values ->    0 of  128   *** CANNOT CARRY DIRECTION ***
      whole word  12 values ->    4 of 4096

   one bit at a time, all 36 bits, 133 non-C-format pairs:
      ZERO violations: bit 18 (addr8 bit 6)     <- the only one
      next best      : lo12 bit 0 (5), lo12 bit 10 (18), lo12 bit 7 (19), lo12 bit 1 (67)
```

**Read the top block first.** With the three C-format pairs included, *not even a
full lookup table on the whole 36-bit word* satisfies the oracle — because those
three pairs carry the **identical word on both sides**. That is a **proof** that
they lie outside the reach of any instruction-based direction rule, so excluding
them is forced by the data rather than chosen to fit; §5.3 then shows
independently that they are accidental.

The **2 of 8** for `addr8` is the rule and its own global flip. That is the
degeneracy §1.2 warned about, appearing exactly where it should.

### 2.3 The field that separates the two members of a pair

```
   addr8 of (lower cell, upper cell)      SRC of (lower, upper)     hi12 of (lower, upper)
      (0x20 , 0x60)  x131  bit6 (0,1)        (0x19 , 0x0B)  x113       (0x880,0x880) x130  bit7 (1,1)
      (0x80 , 0x80)  x3    bit6 (0,0)        (0x19 , 0x10)  x13        (0x880,0x900) x3    bit7 (1,0)
      (0x30 , 0x60)  x2    bit6 (0,1)        (0x00 , 0x00)  x4         (0xC40,0xC40) x3    bit7 (0,0)
                                             (0x19 , 0x00)  x2
                                             (0x0B , 0x07)  x2   <- SRC 0x0B on the WRITE side
                                             (0x00 , 0x07)  x1
                                             (0x19 , 0x11)  x1
```

`SRC 0x0B` appears on **both** sides of the partition. `H-DIR` is not merely
incomplete; it is wrong in the strong sense.

---

## 3. ★★★ Rule 7 — scored ONLY where the rivals disagree

A pair is a **disagreement site** for (A, B) when A and B label at least one of
its two members differently. Sites where they agree cannot choose between them
and are **discarded**. Empty disagreement sets are printed as such.

```
   A                B                  n     A viol   B viol
   H-ADB6           H-SRC0B  (H-DIR)   20        0       18
   H-ADB6           H-ACTRD            105       0       92
   H-ADB6           C-VALRANK          136       3      136
   H-ADB6           H-HI7              133       3      133
   H-ADB6           C-CELLPAR            7       3        7
   H-ADB6           C-DUPLO              3       3        0
   H-SRC0B          C-CELLPAR           21      19        5     <- ★ the blind rule WINS
   H-SRC0B          C-DUPLO             23      21        0
   C-CELLPAR        C-SLOTPAR          -- DISAGREEMENT SET EMPTY (same machine)
   C-FIRSTW         C-DUPLO            -- DISAGREEMENT SET EMPTY (same machine)
```

### 3.1 The headline separation, printed site by site — all seven

| algo | pair | earlier word | later word | `H-ADB6` | `C-CELLPAR` |
|---|---|---|---|---|---|
| 21 CONCERT REVERB 2 | `0x19,0x1D` | `C40.1.80.000` | `C40.1.80.000` | W W **FAIL** | R R **FAIL** |
| 26 WAVE REVERB 1 | `0x19,0x1D` | `C40.1.80.000` | `C40.1.80.000` | W W **FAIL** | R R **FAIL** |
| 27 WAVE REVERB 2 | `0x19,0x1D` | `C40.1.80.000` | `C40.1.80.000` | W W **FAIL** | R R **FAIL** |
| 64 S.DELAY+CHORUS | `0x2C,0x30` | `880.1.20.2C7` | `900.1.60.1D5` | W R **OK** | W W **FAIL** |
| 67 S.DELAY+VIBRATO | `0x2A,0x2E` | `880.1.20.2C7` | `900.1.60.1D5` | W R **OK** | W W **FAIL** |
| 68 S.DELAY+PHASER | `0x28,0x2C` | `880.1.20.64B` | `880.1.60.447` | W R **OK** | W W **FAIL** |
| 70 AUTO WAH+S.DELAY | `0x28,0x2C` | `880.1.20.64B` | `880.1.60.000` | W R **OK** | W W **FAIL** |

**That is the whole of the evidence separating the instruction rule from the
blind one: four sites, two word-pair shapes, four algorithms.** It is stated at
that strength and no higher. What makes it evidence rather than noise is that
these four are the only pairs in the corpus at cell-index offset **+4** while the
reverb ladder is at **+5** — the parity rule is right on the ladder for a reason
that has nothing to do with direction, and it breaks the moment the geometry
does.

---

## 4. ★★★ Power — plant a ground truth, then see whether the test finds it

The instrument is run **unchanged** on synthetic descriptor images built from the
**real** words, the **real** cell counts and the **real** number of pairs per
algorithm, with the pairs drawn from the planted rule's own R-cells and W-cells.

```
   RANDOM matching (60 trials each; mean violations of the scored rule)
   planted \ scored  | H-ADB6  H-SRC0B  H-SRC19   H-HI7  H-ACTRD  C-CELLPAR  C-VALRANK
   H-ADB6            |    0.0     25.1     50.9    108.1     76.8      21.5      136.0   recovered
   H-SRC0B           |   26.8      0.0     46.9    107.8     69.3      30.4      136.0   recovered
   H-SRC19           |   45.7     40.8      0.0    109.2     80.5      27.9      134.0   recovered
   H-HI7             |   27.1     26.6     30.5      0.0      9.0      26.1       52.0   recovered
   H-ACTRD           |   54.7     45.8     63.9     66.8      0.0      57.1      118.0   recovered
   C-CELLPAR         |   24.9     32.9     36.9    107.0     79.0       0.0      136.0   recovered
   C-VALRANK         |   66.5     67.7     72.3    107.7     80.0      65.0      136.0   MISSED
   RECOVERY: 6 of 7.        rejection: plant H-ADB6 -> C-CELLPAR min 16 median 22 max 29
```

The one miss is honest and explains itself: `C-VALRANK` is derived from the
**values**, so planting it is ill-posed — its own labelling moves when the values
are re-drawn (the geometry-preserving plant has to relocate 127 pairs per trial
to realise it). Value-derived rules are not plantable by this generator and are
reported, not hidden.

### 4.1 ★★★ And now the plant that does not cheat

A random matching hands the test power the real data does not have: in the real
corpus a pair is two cells a **fixed index offset** apart, because the read and
the write of one line sit a fixed number of slots apart in the microprogram. The
honest plant keeps that geometry.

```
   GEOMETRY-PRESERVING plant
   planted \ scored  | H-ADB6  H-SRC0B  H-SRC19   H-HI7  H-ACTRD  C-CELLPAR  C-VALRANK   moved/dropped
   H-ADB6            |    0.0     18.0     10.0    130.0     89.0       7.0      136.0    6.0 / 0.0
   H-SRC0B           |    4.0      0.0     12.0    120.0     89.0       7.0      125.0   13.0 /11.0
   H-SRC19           |    4.0     16.0      0.0    131.0     92.0       7.0      131.0   26.0 / 5.0
   H-HI7             |   21.0     25.0     30.0      0.0     15.0       5.0       51.0   48.0 /85.0
   H-ACTRD           |   27.0     30.0     40.0     54.0      0.0       7.0      105.0   89.0 /31.0
   C-CELLPAR         |    0.0     16.0      2.0    128.0     90.0       0.0      129.0    0.0 / 7.0   MISSED(H-ADB6)
   C-VALRANK         |    5.0      3.0     22.0    120.0     89.0       7.0      127.0  127.0 / 9.0   MISSED(H-SRC0B)
   RECOVERY: 5 of 7.
```

> ### ★★★ THE ASYMMETRY, WHICH IS THE REAL RESULT OF §4
>
> * plant `H-ADB6` → `C-CELLPAR` scores **7** violations. **Rejected.**
> * plant `C-CELLPAR` → `H-ADB6` scores **0**. **NOT rejected.**
>
> The instrument can refute the blind rule in favour of the instruction rule and
> **cannot do the converse**. The reason is visible in the `dropped` column: a
> `C-CELLPAR` world cannot produce **7** of the corpus's 136 pairs at their own
> offsets, so the plant has to throw them away — and it is exactly those 7 that
> carry all the discrimination. The corpus **has** them.
>
> So the correct statement is **`H-ADB6` SURVIVES**, not "`H-ADB6` is confirmed".
> The FORCED result in item B is a statement about *which field could*, not about
> *which rule is*.

### 4.2 Noise tolerance

Planting `H-ADB6` and corrupting `n` pairs per algorithm into accidental
same-label collisions: `H-ADB6` then scores **9.7 / 16.9 / 23.9** mean violations
at n = 1 / 2 / 3, against **0.0** at n = 0. The real corpus's **3** violations
therefore sit well below even a one-per-algorithm corruption rate — consistent
with §5.3's finding that all three are one accidental cell-index pair.

---

## 5. The nulls, including one with a hole

### 5.1 Permutation null

Shuffle **which word takes which cell** inside each algorithm, preserving the
multiset of words and all values. 2 000 trials:

```
   H-ADB6     real  3 | shuffled min 48 median 68 max 88 | P(shuffled <= real) = 0/2000
   H-SRC0B    real 21 | shuffled min 48 median 67 max 94 | P(shuffled <= real) = 0/2000
   C-CELLPAR  real  7 | shuffled min  7 median  7 max  7 | P(shuffled <= real) = 2000/2000
```

★ **AND ITS HOLE, STATED RATHER THAN GLOSSED.** This null shuffles *words*, so it
**cannot move an instruction-blind rule at all** — `C-CELLPAR` scores 7 in every
one of the 2 000 shuffles. A null with no power against the rival you are worried
about is method rule 7 in null form; it is reported as a null against **noise**
only, and the rival test is §3.

### 5.2 Collision null

Re-draw every cell value uniformly inside its unit's 32 K region: **min 0, median
0, max 3** collisions, against the corpus's **136**. The pairing is structural.

### 5.3 Replication — the filter that costs no free parameter

The twelve reverbs are twelve instances of one program, so a **cell-index pair**
that holds equal values in all twelve is structural and one that holds in a few
is a collision:

```
   (0x02,0x07) (0x04,0x09) (0x06,0x0B) (0x08,0x0D) (0x0A,0x0F)
   (0x0C,0x11) (0x0E,0x13) (0x10,0x15) (0x12,0x17) (0x14,0x1F)   12 of 12  STRUCTURAL
   (0x19,0x1D)                                                    3 of 12  <- accidental
   reverb pairs: 123 total, 120 structural, 3 accidental

                                              all-rev   structural
   H-ADB6                                          3            0
   H-SRC0B  (H-DIR)                               15           12
   C-CELLPAR                                       3            0
   C-VALRANK                                     123          120
```

Every `H-ADB6` failure in the whole corpus is one accidental pair.

---

## 6. The alignment phase — two predictions, two misses

δ is a **cyclic** rotation of the cell list against program order, so every δ
keeps all 83 algorithms and all 136 pairs. (A non-cyclic shift simply dropped
algorithms and made the sweep vacuous — that was this file's first draft, caught
by method rule 1.)

```
   delta  H-ADB6  H-SRC0B  C-CELLPAR | zero-violation bits (of 36, non-C sites)
     -4      27      18        7     | 0   -
     -3       7      10        7     | 0   -
     -2      17      17        7     | 0   -
     -1       8       4        7     | 0   -
      0       3      21        7     | 1   addr8 bit 6
     +1       4      18        7     | 0   -
     +2      12      18        7     | 1   addr8 bit 6
     +3       3      20        7     | 1   addr8 bit 6
     +4      17      15        7     | 0   -
```

* **MISS 1.** I predicted the raw violation count would single δ = 0 out. It does
  not: `H-ADB6` scores 3 at δ = 0 *and* at δ = +3.
* **MISS 2.** I then predicted the strong statistic would. It does not either:
  δ = 0, +2 and +3 each admit exactly one bit.

★ **But look at WHICH bit.** At every δ where any bit works at all it is `addr8`
bit 6 and nothing else. The pass's forcing is therefore **robust to the alignment
parameter** — *"if a single bit of the word carries the delay-DRAM direction then
it is `addr8` bit 6"* does not depend on δ. That is a stronger claim than the one
I set out to make and it needs less. **The alignment is not settled here and does
not need to be**, which also means this pass is **not** an independent vote on
`adjudication-round4` item B; §8 handles item B on its own terms.

---

## 7. ★★ The one remaining bit — and the two sides of it

The oracle is flip-invariant, so it delivers *"`addr8` bit 6 separates read from
write"* and never *which side is which*.

**WITNESS 1 — `r1-allpass-motif.md` F1, ALGEBRAIC.** `read_slot` enumerated over
{0, 4} and forced numerically, **36/36**, the opposite assignment with **zero
survivors in every model**. Slot 0 is `880.1.60.2D4`, slot 4 is `880.1.20.655`.
⇒ **`addr8 0x60` = READ.**

**WITNESS 2 — MULTI TAP DELAY (`r3-delaydram.md` §6.3), a COUNTING argument.**
Re-derived here:

```
   cell 0x26 =   6000   880.1.30.00B  addr8 0x30  bit6=0     <- DELAY 1 (ms)
   cell 0x27 =  32685   880.1.60.000  addr8 0x60  bit6=1
   cell 0x28 =  12000   880.1.20.2C7  addr8 0x20  bit6=0     <- DELAY 2
   cell 0x29 =  18000   880.1.20.2C7  addr8 0x20  bit6=0     <- DELAY 3
   cell 0x2A =  24000   880.1.20.2C7  addr8 0x20  bit6=0     <- DELAY 4
   cell 0x2B =  32768   880.1.20.2C7  addr8 0x20  bit6=0     <- the region CEILING
   cell 0x2C =      0   880.1.60.000  addr8 0x60  bit6=1     <- the region FLOOR
```

A multi-tap delay has **one** write and **many** reads. The four evenly spaced
tap values all sit on `bit6 = 0` words. ⇒ **`addr8 0x60` = WRITE**, or the taps
are writes.

**WITNESS 3 — NEW, AND IT FALLS OUT OF THE ORACLE.** The two members of a pair
hold the same address, so one happens first. MEASURED: **the earlier access has
`bit6 = 0` in 133 pairs and `bit6 = 1` in 0** (the 3 C-format pairs carry the same
bit and order nothing). A read and a write of one address in one frame is either
**write-then-read** — a zero-delay forward through the DRAM — or **read-then-write**,
a delay of a **full rotation period** (32 768 samples; the longest ladder segment
in the corpus is 8 905). ⇒ **`addr8 0x60` = READ**, agreeing with witness 1.
INFERRED: it rests on *"not a full-period recirculation"*.

**Vote 2–1 for `0x60` = READ, i.e. for `r3-delaydram.md` §5.1's rotation sign and
against `dram-cursor-closure.md` item I's. IT STAYS OPEN.** Method rule 6.

### 7.1 The model class, printed next to the claim

What is forced is that `addr8` bit 6 separates the two members of an equal-address
pair. What that **means** is enumerated:

* **(M1)** bit 6 **is** the read/write direction. Polarity as above.
* **(M2)** bit 6 selects one of two **DRAM address registers**, and the direction
  follows from which register the datapath drives. Same partition, identical on
  this data. If the register→direction map is **global**, (M2) *is* (M1). If it
  is **per-program**, witnesses 1 and 2 can both be right and `DRAM-DIR` is not
  one bit after all. **Nothing here separates (M1) from (M2).**
* **(M3)** the pair is a `(base, limit)` register pair of one ring rather than an
  access pair. ★ **REFUTED HERE**: the two members hold the **same value**, and a
  ring with `base == limit` has zero length.
* **(M4)** the oracle's premise is false and the equalities are coincidence.
  ★ **REFUTED** by §5.2 (chance gives 0–3; the corpus has 136) and by the fact
  that a false premise would not single out exactly one bit of thirty-six.

### 7.2 What would decide the polarity — named, not hand-waved

1. **The host's own parameter semantics.** MULTI TAP's four cells are named
   `DELAY n (ms)` by the UI table. *A tap length is meaningless for a write.*
   This is witness 2 made rigorous, and it is the cheapest next experiment:
   it needs the T2 opcode→name binding for algorithm 10, which
   `register_space.py`'s alignment machinery already produces for 49 algorithms.
2. **Re-run `r1_allpass_solve.py`'s `read_slot` forcing with the descriptor
   addresses supplied** instead of left free. If the solve still forces slot 0
   once the DRAM contents are constrained by the descriptor, witness 1 hardens.
3. **The frame completing.** Write-before-read ordering inside one frame is
   directly observable — but 0 of 1 344 001 frames complete, so it cannot be run.

### 7.3 What changes if `H-ADB6` replaces `H-DIR` — for whoever owns the disassembler

Over the **829** labelled cells in the 83 aligned algorithms: reads go from
**317 (38.2 %)** under `H-DIR` to **365 (44.0 %)** under `H-ADB6`, and the two
disagree on **170 cells (20.5 %)**:

```
   880.1.60.000   x63    H-ADB6 READ  / H-DIR WRITE     <- r3 6.3's row 4
   880.1.20.2C7   x37    H-ADB6 WRITE / H-DIR READ      <- r3 6.3's row 3
   900.1.60.1D5   x32    H-ADB6 READ  / H-DIR WRITE
   880.1.20.2D5   x24    H-ADB6 WRITE / H-DIR READ
   880.1.60.40E   x12    H-ADB6 READ  / H-DIR WRITE
   880.1.60.41A   x1     880.1.60.447   x1
```

The two biggest disagreements are **exactly** the two words `r3-delaydram.md`
§6.3 used to falsify the `addr8` rule. The dispute has not moved; it has been
localised to one bit and two rows.

---

## 8. ★★ SECOND TASK — the rule-7 audit of published claims

For every published claim established by **scoring against a structured corpus**:
what is the strongest instruction-blind rival, and was it ever run?

| source | claim | published label | audit | verdict |
|---|---|---|---|---|
| `dark-words.md` F / §6 | `H-DIR`: SRC `0x0B` ⟺ READ. *"4 of 4 established assignments against 2 of 4 for the falsified `addr8` rule."* | CONSISTENT, 4 of 4 | The strongest instruction-blind rival was **never run**. And the four rows are **two SOURCES**: rows 1–2 are r1's single algebraic solve, rows 3–4 are r3 §6.3's single alignment argument — and `addr8` "fails" only on r3's two, so the 4–2 margin is one disputed source counted twice. The oracle adds 136 rows; `H-DIR` fails **21**, and loses **19–5** to cell parity at their disagreement sites. No function of `SRC` at all survives. | ★ **FALSIFIED** as a biconditional |
| `dram-cursor-closure.md` I | *"the rotation sign is in contradiction inside the corpus; `R > W` beats `R < W` by **62 clean algorithms to 10** under the identical rule."* | OPEN, a live contradiction | Those 62/10 come from `score_rule()` — **the same instrument the same note falsified in item F**. `adjudication-round4` item A dissolved the *contradiction* by a change of units but the **number** was never withdrawn, and it has no discriminating power: `C-CELLPAR` reproduces it. | ★ the **number is RETRACTED**; the sign is **OPEN** (§7) |
| `dram-cursor-closure.md` H / `adjudication-round4` B | *"76 of 91 algorithms ship exactly two region-boundary cells"* → a `(base,limit)` pair; and *"no rigid 1:1 map can skip an interior slot, so the alignment is refuted"* | MEASURED / **FORCED** | The measurement stands and this pass uses it. The **FORCED** refutation does not: its option set omits *"a consumer may take a NON-ADDRESS operand"* — method rule 3, in the file that enforces method rule 3. Under that option cells `0x1E` and `0x01` are bounds, not addresses, and the rigid map survives untouched. | ★ the refutation is **DOWNGRADED to CONSISTENT** |
| `r3-delaydram.md` §6.3 | *"under the cursor model, `addr8` does NOT select the DRAM direction"* | r3's own words: *a constraint, not a decode* | r3 labelled it correctly and it is the one witness that still bites. But it is a **semantic** assumption ("the taps are reads") plus the alignment, and it disagrees with r1's algebraic forcing. It does **not** refute *"`addr8` bit 6 is the direction FIELD"* — only the **polarity**. | **SURVIVES**, and it is now one bit |
| `store-gate.md` C / D / E | bit 7 is in the gate CONDITION; class `(1,1)` never writes `mem[ptr]`; class `(1,2)` is the ordinary store | FORCED | Different genre: **exhaustive elimination** against numeric witnesses (the biquad's dB error, the LFO's 29 blocks), with each condition killed by a *named* witness. Rule 7 does not bite. ★ **But its `bit 7 = memory-port DIRECTION` reading does not reach the delay DRAM:** `hi12` bit 7 is **equal on both members of 133 of 136 pairs**. | **SURVIVES**; the extension to the delay DRAM is **EXCLUDED** |
| `register-space.md` D1 | the write port auto-increments by +1; the {+1, −1} degeneracy broken by *"algo 39 issues select `0x50` ×29 then `0x6D` ×11, and `0x6D = 0x50 + 29`"* | FORCED (+1) | One arithmetic coincidence, not a corpus score, so rule 7 does not apply in its usual form. It is nevertheless a **single row with no rival family enumerated**: *"the two selectors are unrelated"* predicts a hit with probability ≈ 1/256 per algorithm, and the sweep over the other 99 streams that would price that null was not run. | **SURVIVES**, but the null was never priced |
| `adjudication-round4` C | the descriptor block is a contiguous address partition; 9 duplicates at offset +5 plus 1 at +11 in 12 of 12; permutation null 0/4000 | MEASURED | The null preserves the multiset and the claim is about a **structure**, not a choice between rules, so there is no instruction-blind rival to build. This pass depends on it and re-derives it — the duplicate structure **is** the oracle. | **SURVIVES**, and is this pass's foundation |

---

## 9. Predict-then-check — written down first, hits and misses with equal weight

| # | prediction | outcome |
|---|---|---|
| **P1** | The descriptor values would again fail to discriminate, and the deliverable would be *"DRAM-DIR is undecidable from the descriptor images"*. | ★★★ **MISS, and it is the pass's whole content.** They discriminate. The previous round's failure was in its **scoring function** — *"some write on the correct side"* is passed by any alternating labelling — not in its data. §1. |
| **P2** | `H-DIR` would survive as *"incomplete but not wrong"*: `SRC 0x0B` ⊂ reads, with other reads carrying other codes. | ★★ **MISS.** `SRC 0x0B` appears on **both** sides (`(0x0B,0x07)` ×2), and **no function of `SRC` at all** satisfies the oracle — 0 of 64. The field is dead, not the predicate. §2.2 |
| **P3** | The `H-ADB6` / `C-CELLPAR` disagreement set would be large enough to carry the result comfortably. | ★★ **MISS.** Seven pairs, of which **four** informative and those four are **two** word-pair shapes. Reported at that strength. §3.1 |
| **P4** | The phase sweep would single out δ = 0 and become an independent vote on the alignment. | ★★ **MISS TWICE** (raw count, then the strong statistic). The consolation is better than the prediction: the forcing is **δ-independent**. §6 |
| **P5** | `hi12` bit 7 — the brief's named candidate, from `store-gate.md`'s memory-port DIRECTION reading — would be a live contender. | ★ **HIT that it must be enumerated, MISS as a hypothesis**: 133 of 136 violations, because it is *constant* across a pair. §8 |
| **P6** | The power test would show symmetric separation between the instruction rule and the blind one. | ★★★ **MISS, and the most important one.** Asymmetric: `C-CELLPAR` is rejected when `H-ADB6` is true; `H-ADB6` is **not** rejected when `C-CELLPAR` is true. So the result is *survives*, not *confirmed*. §4.1 |
| **P7** | The `C40.1.80.000` failures would need a post-hoc exclusion I would have to defend. | ★★ **HIT, and better than predicted.** The exclusion is **forced**: both members are the *identical 36-bit word*, so no instruction rule can ever separate them, and replication independently calls the site accidental (3 of 12 reverbs). §2.2, §5.3 |
| **P8** | Resolving direction would move the frame tally. | ★ **HIT (negative), as expected.** It does not: `DRAM-ADDR`'s per-unit base carrier is still unnamed, so the 42 delay-DRAM slots keep trapping whatever direction is. Nothing is applied. |

---

## 10. Housekeeping

* `dsp/verify.py` — **BYTE-MATCH OK**, 91 valid algorithm streams / 38 distinct
  images.
* No MAME source touched; neither disassembler mirror edited, so the 3057-word
  mirror diff is unaffected; no `.dsm` regenerated.
* The rendered audio is untouched **by construction** — no executable semantic
  changed.
* New files: `dsp/tools/dram_dir.py`, this note.

## 11. For the other agents in this round

* **To the DRAM-address sibling.** ★ The equal-value pairs are a **new
  constraint on the memory model**, and they do not fit a single global rotation
  as stated in `r3-delaydram.md` §5.1: under one rotation counter a read and a
  write of the same *data* have cells differing by the delay, so two cells with
  the **same** value are a read and a write of the same *location* — a zero-delay
  forward, or a full-period recirculation. Which one is §7's open bit. There are
  **136** of these pairs with the geometry `{offset 4: 7, offset 5: 117, offset
  11: 12}`, and the ten structural reverb pairs are `(0x02,0x07) … (0x14,0x1F)`.
* **To the host-firmware sibling.** ★ The single cheapest thing anyone can do for
  this target is bind algorithm **10**'s T2 parameter opcodes to UI names, the way
  `register-space.md` bound `0x63 → VOLUME` in 49 of 49. If MULTI TAP's cells
  `0x26/0x28/0x29/0x2A` are named `DELAY n (ms)` by the host's own table, witness
  2 becomes a measurement and §7's polarity closes — against r1. If they are not,
  witness 2 collapses and it closes the other way.
* **To whoever next edits `dark-words.md`.** Item F's `H-DIR` is falsified (§8);
  its consequence paragraph (now RETIRED) — *"99 of 276 corpus delay-DRAM words (35.9 %) are
  reads under H-DIR"* — should be retired with it. The replacement census is
  §7.3.
* **To the adjudicator.** Two published labels move: `dram-cursor-closure.md`
  item I's 62/10 (retract the number, keep the question) and
  `adjudication-round4` item B (FORCED → CONSISTENT). Both are in §8 with the
  reason.
