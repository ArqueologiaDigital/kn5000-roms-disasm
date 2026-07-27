# THE DELAY-DRAM DESCRIPTOR, SOLVED AS A MATCHING PROBLEM — and the published ladder is wrong

NEC **uPD6383GF-3BA** (Technics SX-KN5000, IC311). Date: **2026-07-27**.
No hardware. Static analysis of the Sub CPU ROM, the 100 canned parameter
streams, the 38 body images and the constraint solvers only.

Labels: **MEASURED** / **PROVEN BY CONSTRUCTION** / **FORCED** / **CONSISTENT** /
**INFERRED** / **FALSIFIED** / **OPEN**.

Target: `DRAM-ADDR` — the 42 delay-DRAM slots, rank 1 on all three of
`dark-words.md`'s metrics, still 0 PARTIAL / 42 TRAP. Adjudicates
[`adjudication-round4.md`](adjudication-round4.md) §10 (its own recommended next
experiment), [`dram-cursor-closure.md`](dram-cursor-closure.md),
[`r3-delaydram.md`](r3-delaydram.md) §5, [`r1-allpass-motif.md`](r1-allpass-motif.md)
§3 and [`register-space.md`](register-space.md) G1.

Tool: [`../tools/dram_match.py`](../tools/dram_match.py) — stdlib + the repo's
own ROM parsers. **Every number below comes out of it.**

```
python3 dsp/tools/dram_match.py evaluator   # SS1  the host chain, PROVEN BY CONSTRUCTION
python3 dsp/tools/dram_match.py anchor      # SS2  ★★★ the +3 cell rule and its shuffle null
python3 dsp/tools/dram_match.py lines       # SS3  ★★★ the real ladders, corpus wide
python3 dsp/tools/dram_match.py map         # SS4  ★★★ delta = -1, and the rule tournament
python3 dsp/tools/dram_match.py act0b       # SS5  ACTION 0x0B, and a conjecture withdrawn
python3 dsp/tools/dram_match.py cursor      # SS6  what this says about the reloads
python3 dsp/tools/dram_match.py control     # SS7  every control, shown saying NO
python3 dsp/tools/dram_match.py all         # ~40 s

python3 dsp/verify.py                       # BYTE-MATCH OK
```

**Nothing was applied.** No MAME source touched, neither disassembler mirror
edited, `dsp/verify.py` reports **BYTE-MATCH OK**, and **zero dark slots are
recovered** — the 42 words still trap. Method rule 6: the map is FORCED only
inside a model class, and the direction rule is 55-of-56, not 56-of-56.

---

## 0. Result in one page

| # | statement | label |
|---|---|---|
| **A** | ★★★ **THE PUBLISHED DELAY LADDER IS THE WRONG PAIRING, AND THE HOST FIRMWARE SAYS SO.** `r3-delaydram.md` §5's chain 0 `[255, 869, 979, 366, 1044]`, `r1-allpass-motif.md` §3's chain 1 `[8905, 528, 1252, 359, 675, 976]` and `adjudication-round4.md` §3's *"11-segment partition, even and odd two-segment sums"* all pair descriptor cell `i` with cell `i+1`. The op-0x67 anchor pairs cell `i` with cell **`i+3`**, and the pre-delay is the case where the two differ and the host decides: cell `0x00` = 33568 is a tap with `BASE24 = 32770`; `i+1` → cell `0x01` = 45464 → delay **−11896, impossible**; `i+3` → cell `0x03` = 32768 → **+800 = the pre-delay**. **ROOM REVERB 1's delay lines are the ELEVEN SEGMENTS `83 172 356 513 739 240 119 247 428 616 (360)` themselves plus the 800 pre-delay and the tail taps 110 / 109 / 543 — not their pairwise sums.** | **FALSIFIED** (three notes), the replacement **FORCED** by the anchor |
| **B** | ★★★ **AND THE PHYSICAL REASON, which needs no firmware at all: under the old pairing THE DELAY LINES OVERLAP IN DRAM.** Line *k* would span `[A(k−1), A(k+1)]` and line *k+1* `[A(k), A(k+2)]` — two lines writing the same words. Corpus-wide, `s = 1` leaves **77 of 91** algorithms with overlapping line intervals and **53** abutting joins; `s = 3` leaves **24** overlapping and **171** abutting joins. A memory allocator produces abutting buffers. | **MEASURED** |
| **B2** | ★★★ **AND A ROUND NUMBER NOBODY AIMED AT.** The twelve reverbs share one 133-word body image and differ only in the descriptor table, so a cell that is identical in all twelve is *structure*. There are exactly **three**: idx 3 = `32768` (the region floor), idx 30 = `32767` (the sentinel) and idx 5 = **`41590`**, which under this reading is the ladder's own floor. `41590 − BASE24 = 41590 − 32770 = 8820 samples = ` **`200.00 ms exactly`** — the headroom a PRE DELAY parameter's full-scale range needs, and the reason the reverbs leave a hole between the pre-delay and the ladder. Nothing in the derivation aimed at a round number; the residue is `0.00 ms`. | **MEASURED** (12 of 12); the reading **INFERRED** |
| **C** | ★★★ **THE ANCHOR: opcode 0x67's record carries a 24-bit LINE BASE, and it sits exactly THREE CELLS after the tap.** `LABEL_03925E` computes `cell = round(user_ms × 44100/1000) + BASE24`, with `BASE24` three bytes of the record. So every op-0x67 tap hands us its line's base address for free. **`BASE24 − 2` is a cell of the same algorithm in 35 of 38 records, and sits at cell offset exactly `+3` in 30 of 38** (31 counting the one whose partner is at `+3` among several). Rivals `s = 1,2,4,5,6,7,8` score `0, 1, 4, 0, 3, 0, 0`. Shuffle null (multiset preserved, index relation destroyed, identical predicate both sides): **mean 3.75, max 12, ≥ 30 in 0 of 2000.** | **MEASURED**; `s = 3` **FORCED** within the enumerated offsets |
| **D** | ★★★ **THE CELL → WORD MAP: `cell = (consumer index − 1) mod n`.** A +1-per-access cursor, wrapping inside the body's own allocation, one cell behind the consumer index. Scored **only** on the 28 host-labelled (tap, line-base) pairs — no DSP-side inference in the scoring set — `δ = −1` scores **53 of 56** against 43, 42, 34, 33 for the next best phases and 10–16 for the even ones. | **FORCED** within the model class printed in §3 |
| **E** | ★★★ **AND IT CONFIRMS `r1-allpass-motif.md`'s F3, WHICH R1 COULD ONLY ASSUME.** F3 — *"the delay-line write trails the read by exactly one stage"* — was labelled *"the minimal choice and is **assumed**"*. In the reverb the two DRAM words of a repetition are consecutive consumers, so "trails by one repetition" **is** `s = 3`. The assumption is now measured, from the host side, in an algorithm R1 never looked at. | **CONFIRMED** by an independent route |
| **F** | ★★ **A NEW DIRECTION RULE, AND IT BEATS BOTH THE INCUMBENT AND THE WORD-BLIND RIVAL ON THE SITES WHERE THEY DISAGREE.** `H-ADDR60`: `addr8 == 0x60` ⇒ READ, `addr8 ∈ {0x20, 0x30}` ⇒ WRITE. On the 56 host-labelled sites: `H-ADDR60` **55**, `H-SRC0B` (`dark-words.md`'s H-DIR) 53, `C-PARITY` (word-blind, index parity) 51, `C-INV` 3, `C-LO0` 18. **Head to head on disagreeing sites only (method rule 7): H-ADDR60 beats H-SRC0B 3–1 on their 4 disagreements and beats the word-blind rival 4–0 on their 4.** Small, but it is the first direction evidence on this chip that a word-blind rival does not match. | **CONSISTENT**, and it is the first rule to survive rule 7 |
| **G** | ★★★ **MULTI TAP DELAY REFUTES EVERY STREAM-DRIVEN STRIDE MODEL — and it is also this pass's biggest MISS.** Its four user taps are cells `0x26 / 0x28 / 0x29 / 0x2A` (host-proven), which is **not contiguous**, while the four reads are **four byte-identical words** `880.1.20.2C7` separated by **byte-identical** three-word gaps that would have to advance the cursor `+2` then `+1`. No function of the executed stream can do that. Under `δ = −1` the map places **3 of the 4** taps correctly and puts the fourth on `880.1.60.000`. **Reported as a miss, not smoothed.** | **FORCED** (M3 refuted); the 3-of-4 is a **MISS** |
| **H** | ★★ **`\|R\| ≥ 2` IS CONFIRMED BY A SECOND, INDEPENDENT ROUTE, AND TASK 3 IS THEREBY MOOT.** `δ = −1` is measured **per body, relative to that body's own base**. A free-running cursor would enter the unit-1 body with a phase depending on the unit-0 consumer count, which takes **12 distinct values** over the 79 unit-0 algorithms. Constant phase + varying offset is impossible ⇒ **the cursor is reloaded per body**. That is `dram-cursor-closure.md` item A, re-derived from the observed phase instead of from closure over 948 frames. **Deciding `E30.C.00.404` and `82E.8.0F.000` therefore cannot resurrect `\|R\| = 1`; the question is dissolved rather than answered.** | **FORCED** given D |
| **I** | ★★ **AND THE UNIT-0 RELOAD VALUE IS NAMED.** `δ = −1` puts the unit-0 body's first consumer on cell `0x26 − 1 = 0x25`. I-RAM 44 is `801.0.25.825` — payload **`0x25`** into pointer register `0x825`. `0x20..0x25` is exactly the slack `dram-cursor-closure.md` §3.6 derived and that no algorithm ever writes. **R3 candidate (i) is resurrected for unit 0.** It is *not* resurrected for unit 1: I-RAM 52 loads the same `0x25` and unit 1 needs `0x1F`. | **CONSISTENT** for unit 0, **OPEN** for unit 1 |
| **J** | ★ **ACTION 0x0B IS NOT THE DELAY-LINE ACCESS AND IS NOT A DIRECTION.** Under the map, ACT-0x0B delay-DRAM slots land on READ cells **33** times and WRITE cells **168** times (population: 203 slots over the 83 algorithms where `#cells == #consumers`). And `880.1.60.2D4` — `r1`'s FORCED READ — carries ACTION `0x14`, not `0x0B`. `register-space.md` G1's entanglement is real; it does not make `0x0B` decodable. The 32 non-DRAM ACT-0x0B words share no field with the family but ACTION itself. | **MEASURED**; `0x0B` stays **OPEN** |
| **K** | ★ **A CONJECTURE OF MY OWN, WITHDRAWN BEFORE PUBLICATION.** "Cell index 1 is never an end of a line" holds in **60 of 78** algorithms at a 4000-sample delay cap and in **0 of 78** at the cap the region size justifies. **Threshold-dependent ⇒ not a claim.** What survives is the bare measurement: cell index 1 is `max used address + 1` in GATED REVERB (14553) and ROOM REVERB 1 (45464) and **0** in the other eleven reverbs. | **FALSIFIED** (mine) |
| **L** | ★ **NOTHING IS APPLIED AND THE FRAME TALLY DOES NOT MOVE.** 107 FULLY / 92 addressing-only / 86 dark, unchanged; 0 of 1 344 001 frames complete. The map is FORCED only inside a model class and the direction rule is 55/56, so under method rule 6 the 42 words keep trapping. The last two rounds each predicted 108 → 133 and delivered nothing; this one predicts nothing and delivers nothing to the device. | **MEASURED** |

---

## 1. What was actually new, and whose it is

`adjudication-round4.md` §10 asked for a matching formulation. The lever that
made it solvable is **not in the DSP**: it is parameter opcode `0x67`.

**CREDIT, stated first.** A sibling pass in this same round
([`host-side.md`](host-side.md), A1/A2/E1) independently decoded the same
dispatcher, found the same *"opcode 0x67 is the only one routed to the
descriptor writer"* and the same `44100/1000` in `LABEL_03925E`, and — crucially
for everything below — **PROVED that the relocation base is zero, so
`cell = T1[opcode][operand]` exactly**. This pass does not re-claim any of that.

What is new here is the **third argument of the record**:

```
   LABEL_03CF07  reads THREE bytes b0,b1,b2 from the T2 record
   LABEL_03925E  BASE24 = (b0<<16)|(b1<<8)|b2
                 XBC = 0x0000AC44 = 44100 ; CALL multiply
                 XBC = 0x000003E8 = 1000  ; CALL divide (rounds)
                 ADD XHL, BASE24
   =>  descriptor_cell = round(user_ms * 44100/1000) + BASE24
```

`BASE24` is a **per-parameter line base address, canned in the ROM**. It turns
38 descriptor cells across 23 algorithms into *labelled read taps whose write
address is known*, and that is the anchor set the matching needed.

The 38 records, with the bases actually used:

```
   BASE24 =      2   16 records   (unit-0 line at address 0)
   BASE24 =   8161    1
   BASE24 =  16352   10
   BASE24 =  24513    1
   BASE24 =  32770   12           (the twelve reverbs' pre-delay; unit-1 floor + 2)
```

**Unit 0's first base is `0 + 2` and unit 1's is `32768 + 2`.** The `+2` is a
constant: `BASE24 − cell_value` is `+2` in **39 of 54** matches, `+3` in 12 (the
reverbs' sentinel, coincidental), `+4` once and `+202` twice. The reading that
makes the user's millisecond exact is *hardware delay = read_cell − write_cell −
2*, i.e. a two-sample offset in the address generator. **INFERRED**; the
alternative (the firmware is two samples out) is not separable statically.

⚠ **BOUNDING THE CLAIM.** The canned defaults are authored in **address** space,
not in milliseconds — MULTI TAP's four cells are exactly `6000/12000/18000/24000`
and the implied ms are `136.01/272.06/408.12/544.17`. The evaluator proves the
**form** of the cell; it does not claim the canned numbers came through it.

---

## 2. ★★★ The +3 rule — `dram_match.py anchor`

```
   population: 38 op-0x67 tap records over 23 algorithms
               (of the 91 algorithms that ship descriptor cells at all)

   delta CELL INDEX (mod n) : +2:1  +3:31  +4:4  +6:3  +10:2  +14:1  +30:12
   delta VALUE (BASE24-cell): +2:39 +3:12  +4:1  +202:2

   RIVAL OFFSETS   s=+1: 0   s=+2: 1   s=+3: 31   s=+4: 4
                   s=+5: 0   s=+6: 3   s=+7: 0    s=+8: 0     (of 38)

   SHUFFLE NULL, identical predicate both sides ("BASE24-2 sits at EXACTLY +3"):
      shuffled mean 3.75, max 12, >= 30 in 0 of 2000
      the ROM  30 of 38
```

**The seven exceptions, named** (method: report the misses beside the hits):

| algorithm | tap | why |
|---|---|---|
| SINGLE DELAY | cell idx 2 | `BASE24 = 16352` but the algorithm's real write cell is `15935`; the firmware's base constant and the canned image disagree by 417 |
| MULTI TAP ×3 | idx 0, 2, 4 | **one write serves four taps** — the offsets are +6/+4/+3/+2 to the *same* cell |
| S.DELAY+S.DELAY | idx 6 | its 4th line's base is `24509`, i.e. `BASE24 − 4`, at `+4` |
| S.DELAY+PHASER, AUTO WAH+S.DELAY | idx 0 | at `+4` |

and `S.DELAY+VIBRATO` matches at `+3` but with `BASE24 − cell = 202`: its second
line's real base is `16150`, not `16350`, so the two lines are exactly 8000
samples each and the firmware's base constant is 200 samples stale. **Two
firmware inconsistencies found as a by-product, both reported rather than
filtered out.**

---

## 3. ★★★ The map — `dram_match.py map`

**THE MODEL CLASS, ENUMERATED BEFORE ANYTHING WAS SCORED** (method rule 3):

```
   M1  rigid 1:1, phase delta, NO wrap            <- the round-3 model
   M2  rigid 1:1, phase delta, wrap mod n         <- this pass
   M3  per-word stride s(word) in {0,1,2}
   M4  the cell index is a field of the word
   M5  two cursors, one per direction
```

* **M4 dies on sight** — MULTI TAP's four taps are four *identical* words.
* **M3 is refuted by MULTI TAP** — §5, control K1.
* **M1 vs M2** — M2 is chosen because the last line of three different images
  (ROOM REVERB's 11th segment, GATED REVERB's 9th, S.DELAY+S.DELAY's 4th) closes
  only through the wrap. That is exactly what a software-pipelined loop does
  across a sample boundary. **CONSISTENT, not forced.**

`s = 3` is FORCED by §2 and is **independent of δ**: under any +1 cursor,
`cell(k) = k + δ`, so `cell(k+s) − cell(k) = s` whatever δ is. Printed as
control K6, so the invariance is not mistaken for a result.

**THE SCORING SET is the 28 host-labelled (tap cell, line-base cell) pairs and
nothing else** — no DSP-side inference enters it. A phase scores +1 if the
consumer landing on the TAP is a read under the rule being tested and +1 if the
consumer landing on the LINE BASE is not.

```
   delta   -6   -5   -4   -3   -2   -1    0   +1   +2   +3   +4   +5   +6
   score   13   42   10   43   10  *53*  10   34   16   33   23   33   28
   of 56
```

At `δ = −1` the 28 pairs read:

```
   algo  9 SINGLE DELAY        idx0 -> idx3    880.1.60.2D9  /  880.1.20.64B
   algo 10 MULTI TAP DELAY     idx3 -> idx6    880.1.20.2C7  /  880.1.30.00B
   algo 16..27 the 12 reverbs  idx0 -> idx3    880.1.60.2DA  /  880.1.20.655
   algo 64 S.DELAY+CHORUS      idx0 -> idx3    880.1.60.2DA  /  880.1.20.2C7
   algo 64                     idx7 -> idx10   880.1.60.2DA  /  880.1.20.2C7
   algo 65 S.DELAY+S.DELAY     idx0/2/4        880.1.60.2D9  /  880.1.20.64B
   algo 67 S.DELAY+VIBRATO     idx0 -> idx3    880.1.60.2D9  /  880.1.20.2C7
   algo 68/70                  idx3 -> idx6    880.1.60.2D9  /  880.1.30.8BC
   algo 72/98/99               idx0/2          880.1.60.2D9  /  880.1.20.64B, .00B, .8BC
```

**Twenty-seven of the twenty-eight readers are `880.1.60.2Dx`** and every writer
is `880.1.20.*` or `880.1.30.*`. The reverbs' pair is literally
`r1-allpass-motif.md`'s F1 pair one word apart in the ladder.

### 3.1 ★ Rule 7 — the tournament, scored only where the rules disagree

```
   rule                                                 score
   H-ADDR60  addr8 == 0x60 is the READ                  55 of 56
   H-SRC0B   SRC 0x0B is the READ (dark-words H-DIR)    53 of 56
   C-PARITY  consumer index is ODD   (** word-blind **) 51 of 56
   C-INV     SRC 0x0B is the WRITE   (** inverted **)    3 of 56
   C-LO0     lo12 bit 0 set          (** nonsense **)   18 of 56

   HEAD TO HEAD, only on disagreeing sites:
      H-ADDR60  4  vs  C-PARITY  0     (4 disagreeing sites)
      H-ADDR60  3  vs  H-SRC0B   1     (4)
      H-SRC0B   4  vs  C-PARITY  2     (6)
      H-ADDR60 52  vs  C-INV     0     (52)
      H-ADDR60 38  vs  C-LO0     1     (39)
```

> **This is the first direction test on this chip whose word-blind rival LOSES.**
> `dram-cursor-closure.md` item F is the cautionary case: there a word-blind
> control scored **94.5 %** against the rule's 93.0 % and the instrument was
> withdrawn. Here the word-blind rival scores 51 to `H-ADDR60`'s 55 and loses
> **4–0** on the sites where they actually differ. It is still only **four
> sites**, so `H-ADDR60` is filed **CONSISTENT**, not FORCED, and nothing is
> applied. But `DRAM-DIR` now has a candidate that survives the test that killed
> the last one.

⚠ Also stated: the phase scan and the direction rule are **not** independent —
δ is chosen by asking which words land on taps, so a direction rule and a phase
are chosen together. What breaks the circle is that `r1-allpass-motif.md`'s F1
(`880.1.60.2D4` = READ, `880.1.20.655` = WRITE, forced 36/36 in three model
families) was derived from the *arithmetic* of an all-pass and knows nothing
about descriptor cells. Under `δ = −1` the reverbs' anchored pair is exactly
`(880.1.60.2DA, 880.1.20.655)` — F1's own write word on the line base.

---

## 4. ★★★ The real ladders — `dram_match.py lines`

ROOM REVERB 1, `delay = cell[i] − cell[i+3]`:

```
   00-03  +800   02-05   +83   04-07  +172   06-09  +356   08-0B  +513
   0A-0D  +739   0C-0F  +240   0E-11  +119   10-13  +247   12-15  +428
   14-17  +616   18-1B  +110   19-1C  +109   1A-1D  +543
```

Fourteen lines. The intervals `[write, read]` are

```
   [32768, 33568]                            the pre-delay
   [41590,41673][41673,41845][41845,42201]   ... ten ABUTTING segments ...
   [44487,45103]      and, through the wrap, [45103,45463]  = the 11th, 360
   [33308,33418]  [33743,33852]  [33850,34393]              the three tail taps
```

They **abut**; they do not overlap. Under the published `s = 1` pairing the same
cells give `[41590,41845]` and `[41673,42201]` — **two delay lines writing the
same DRAM words**, which no working reverb does.

Corpus-wide (population **91** algorithms that ship descriptor cells, **514**
lines at `s = 3` with delays in `[1, 32767]`):

```
   s      lines  ALL-EQUAL  repeated  algos OVERLAP  abutting joins
   +1      479       0          8          77             53
   +2      207       0          1          78              2
   +3      514       0         67          24            171
   +4      358       0         57          78             12
   +5      211       0          5          22             18
   +6      199       0          9          26              9
   +7      386       0          1          74             54
   +8      287       0          5          74             11
```

`s = 3` has the most abutting joins by a factor of three and is one of only two
offsets that keeps most algorithms overlap-free. ⚠ It is **not** a clean sweep:
24 algorithms still show an overlap under `s = 3`, because the `[1, 32767]` cap
admits differences that are not lines at all. The cap is stated rather than
tuned; a tighter one would flatter the hypothesis. Named examples the map now
reads out correctly, none of which were readable before:

```
   CHORUS            four lines of exactly 400 samples, bases 0/1040/2080/3120
   VIBRATO, MIX UP   two lines of exactly 400
   FLANGER           two lines of exactly 100
   SINGLE DELAY      two lines of exactly 15435  (350.0 ms, L and R equal)
   S.DELAY+S.DELAY   four lines of exactly 7000
   GATED REVERB      100, 458, 1258, 1846, 680, 800, 1440, 1760, 1800
   PLATE REVERB 1    2000 (pre-delay) + 335 569 1107 1074 2495 600 512 870
                     1078 1669 + 308 213 465
```

`adjudication-round4.md` §3.2 published exactly those eleven numbers for PLATE
REVERB 1 as a *partition whose two-segment sums are the delays*. **The partition
is right; the delays are the segments themselves.**

---

## 5. Controls, each shown saying NO — `dram_match.py control`

| # | control | shown rejecting |
|---|---|---|
| **K1** | MULTI TAP against every stream-driven stride model | the two inter-tap gaps are **byte-identical** instruction sequences yet must advance the cursor `+2` then `+1`. M3 refuted, and the map's own MULTI TAP score is reported as **3 of 4**, not rounded up |
| **K2** | the `+3` rule against `s = 1..8` | `0, 1, 31, 4, 0, 3, 0, 0` of 38 |
| **K3** | shuffle null for `+3`, identical predicate both sides | mean **3.75**, max **12**, `≥ 30` in **0 of 2000**; the ROM 30 |
| **K4** | `BASE24 − 2` against a *random other algorithm's* cells | 87.5 % vs 53.1 % on the non-trivial bases — ⚠ **labelled WEAK**, because 16 of 38 records carry `BASE24 = 2` whose partner `0` is a cell nearly everywhere. K3 is the decisive one |
| **K5** | the word-blind phase/direction rival | `C-PARITY` **51 of 56**, and **0 of 4** on the sites where it disagrees with `H-ADDR60` |
| **K6** | degeneracy check (method rule 4) | the **line set is phase-invariant by construction** — δ only relabels which word takes which cell — so a test scored on the line set alone *cannot* choose δ. Printed (351 lines at every δ) so the invariance is not mistaken for evidence |
| **K7** | `C-INV` and `C-LO0` | 3 of 56 and 18 of 56 — the tournament is not a walkover by construction |
| **K8** | my own "cell index 1 is reserved" conjecture | **60 of 78 at a 4000-sample cap, 0 of 78 at the region-size cap.** Threshold-dependent, withdrawn before publication |
| **K9** | the invariant-cell test (B2) | asked of all 32 reverb cells it answers **3**, not 32 — the twelve presets really do differ nearly everywhere, so "idx 5 is invariant" is a finding and not a tautology |

---

## 6. PREDICT-THEN-CHECK — 3 hits, 8 misses, 1 half

Written down before each experiment.

| # | prediction | result |
|---|---|---|
| **P1** | the host's parameter tables would give the matching a labelled anchor set | ★ **HIT, and it is the whole pass.** 38 labelled taps with their line bases |
| **P2** | the anchor would confirm `adjudication-round4.md`'s 11-segment reading | ★ **MISS, and the most valuable one.** It confirms the **partition** and **falsifies the delays**: the lines are the segments, not the two-segment sums. Three published notes carry the wrong pairing |
| **P3** | the four MULTI TAP taps would fall out of the map and validate it | ★ **MISS.** They fall out of it *negatively*: the four taps sit on non-contiguous cells and refute every stride model, and the map still only places 3 of 4 |
| **P4** | the phase would be `δ = 0`, as `dram-cursor-closure.md` §2 favoured | ★ **MISS.** `δ = 0` scores **10 of 56**; `δ = −1` scores 53. §2's off-the-shipped-set statistic was measuring cell-count bookkeeping, not the map |
| **P5** | `r1-allpass-motif.md`'s F3 (assumed) would have to be relaxed | ★ **MISS, in R1's favour.** `s = 3` **is** F3, and it is now measured rather than assumed |
| **P6** | a direction rule would again fail rule 7 | ★ **HIT and MISS.** `H-SRC0B` beats the word-blind rival only 4–2; `H-ADDR60`, which I had not enumerated before starting, beats it 4–0. The rule I set out to test is not the one that survived |
| **P7** | deciding `E30.C.00.404` / `82E.8.0F.000` would settle the reload count | ★ **MISS.** The phase settles it first, and makes those two words irrelevant to `DRAM-ADDR` |
| **P8** | ACTION `0x0B` would resolve with the DRAM family, as `register-space.md` G1 expected | ★ **MISS.** It lands on read cells 33 times and write cells 168 times: not a direction, not the access. It stays OPEN |
| **P9** | the cell-1 anomaly would turn out to be a ring limit | ★ **MISS, twice** — my own scored version of it was threshold-dependent and is withdrawn; the bare value is `max+1` in 2 of 13 and `0` in 11 |
| **P10** | at least one delay-DRAM word would become executable | ★ **MISS. Zero.** The direction is 55/56 and the model class is not closed, so method rule 6 keeps all 42 trapping |
| **P11** | the map would be consistent across images that share nothing but the descriptor convention | ★ **HIT.** `δ = −1` and `s = 3` hold on five structurally different images — the 133-word reverb, GATED REVERB, SINGLE DELAY, S.DELAY+S.DELAY and the combos |
| **P12** | the reverbs would waste no DRAM, so the hole between the pre-delay and the ladder would be a defect of the reading | ★ **HIT, and the sharpest single number in the pass.** The hole is `8820` samples = **200.00 ms**, the pre-delay's range, and the cell that bounds it is one of only three invariant across all twelve presets |

---

## 7. What this hands the other agents

* **To the direction agent.** `H-ADDR60` (`addr8 == 0x60` ⇒ READ,
  `{0x20, 0x30}` ⇒ WRITE) scores **55 of 56** on host-labelled sites and beats
  the word-blind rival **4–0** where they differ. It is *not* `H-DIR`:
  `H-SRC0B` and `H-ADDR60` disagree at four sites and `H-ADDR60` wins three.
  Its single miss is MULTI TAP's `880.1.20.2C7`, the same algorithm that breaks
  everything else. **Test it against the arithmetic, not against the cells.**
* **To the host-firmware agent.** Your A2 (relocation base = 0) is the premise
  the whole anchor rests on — thank you. Two firmware inconsistencies fall out
  as by-products and are worth a look: **SINGLE DELAY**'s op-0x67 `BASE24` for
  DELAY R is `16352` while its canned image uses `15935` (417 samples), and
  **S.DELAY+VIBRATO**'s is `16352` against a canned `16150` (200 samples). In
  both, touching the knob would move the delay discontinuously.
* **To whoever next touches `r3-delaydram.md`, `r1-allpass-motif.md`,
  `schroeder-topology.md` and `adjudication-round4.md`.** The delay ladders in
  all four need the `i+3` pairing. This is the **second** retraction of these
  numbers in three rounds (the first was the halved payloads, `retraction_sweep`
  premise P16); the corrected set for ROOM REVERB 1 is
  `800 | 83 172 356 513 739 240 119 247 428 616 360 | 110 109 543`.
* **To the comb-impulse test, when a frame finally completes.**
  `adjudication-round4.md` §6 sizes the excitation at `4 × 8905 = 35 620`
  samples, and **`8905` is exactly the artefact this pass retracts** — it is
  `cell 0x02 − cell 0x03`, an `i+1` difference. Under the anchored pairing ROOM
  REVERB 1's longest line is the **800**-sample pre-delay and the longest line
  anywhere in the twelve is **4000** (WAVE REVERB 2). The rule to carry forward
  is unchanged in form — *at least four times the longest line of the algorithm
  under test* — but the number for the reverbs is ≈ **16 000**, not 35 620.
  ⚠ That is a *smaller* figure than the published one, so it is the direction
  in which the amputated-feedback defect can recur; size on the measured
  maximum, and re-derive it from `dram_match.py lines` rather than quoting this
  sentence.
* **To the Apply agent.** **Nothing.** `s = 3` is FORCED, `δ = −1` is FORCED
  within a model class, `H-ADDR60` is CONSISTENT — and a word cannot execute
  without all three. The 42 slots keep trapping.

---

## 8. Housekeeping

* `dsp/verify.py` — **BYTE-MATCH OK**.
* `src/devices/cpu/upd6383/*` and `dsp/tools/dsp_disasm.py` **not touched**, so
  the 3057-word mirror agreement is unaffected and no `.dsm` was regenerated.
* No MAME was launched; no process outlived the pass.
* `dsp/README.md` is shared and carries a sibling's in-flight edit; this pass
  commits only `dsp/tools/dram_match.py` and `dsp/analysis/dram-matching.md`
  with `git commit --only`.
