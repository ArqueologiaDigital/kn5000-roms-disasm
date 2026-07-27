# THE DELAY-DRAM DATAPATH — the port is a one-deep pipeline, and its two dummy accesses were already in the descriptor bank

NEC **uPD6383GF-3BA** (Technics SX-KN5000, IC311). Date: **2026-07-27**.
No hardware. Static analysis of the Sub CPU ROM, the 100 canned parameter
streams, the 38 distinct body images and `bounds.py`'s descriptor
classification only.

Labels: **MEASURED** / **PROVEN BY CONSTRUCTION** / **FORCED** / **CONSISTENT** /
**INFERRED** / **FALSIFIED** / **OPEN**.

Tool: [`../tools/datapath.py`](../tools/datapath.py). **Every number below comes
out of it.**

```
python3 dsp/tools/datapath.py chains     # 1  addr8 bit 4 = the chain head
python3 dsp/tools/datapath.py dummies    # 2 ★★★ LIMIT = first write, CEILING = last read
python3 dsp/tools/datapath.py latency    # 3 ★★  the read latency, bounded from the ROM
python3 dsp/tools/datapath.py ledger     # 4 ★★★ ROOM REVERB 1: all 32 cells accounted
python3 dsp/tools/datapath.py wtrail     # 5 ★★  the write trail, corpus-wide
python3 dsp/tools/datapath.py solve      # 6  the r1 re-run  (~8 min)
python3 dsp/tools/datapath.py rivals     # 7  RULE 7, scored on disagreement
python3 dsp/tools/datapath.py control    # 8  every control, shown saying NO
python3 dsp/tools/datapath.py predict    # 9  PREDICT-THEN-CHECK, hits AND misses
python3 dsp/tools/datapath.py all        # ~10 min
python3 dsp/tools/datapath.py solve --full   # the un-subsampled land sweep (~35 min)

python3 dsp/verify.py                    # BYTE-MATCH OK
```

**Nothing is applied.** The 42 delay-DRAM frame slots still trap; no
disassembler, no device and no `.dsm` listing is touched by this pass.

---

## 0. Result in one page

| # | statement | label |
|---|---|---|
| **A** | ★★★ **THE DRAM PORT IS A ONE-DEEP PIPELINE, AND ITS TWO DUMMY ACCESSES WERE ALREADY CLASSIFIED — AS BOUNDS.** `bounds.py` found two cell classes it could not explain. They are the two ends of one mechanism: the **LIMIT is the FIRST WRITE of its program, 74 of 74**, and the **CEILING is the LAST READ of its program, 83 of 83**. A read word's datum is *not* on its own bus, so the last real tap needs one more port slot — hence a trailing read at an address deliberately outside the unit's own region, whose datum is discarded. A write word always stores something, so the first write needs somewhere harmless — hence a leading write to an address no read of that algorithm can reach. **Exceptionless in both directions**, permutation null 0 of 2000. | **FORCED** within the printed enumeration (§2) |
| **B** | ★★★ **THE WRITE OF A DELAY LINE TRAILS ITS OWN READ BY TWO 8-WORD REPETITIONS — `wtrail = 2`, NOT 1.** Corpus-wide the write consumer of a line sits **+3 port slots** after its read consumer in **273 of 324** lines; in an alternating program that is +2 repetitions, and in ROOM REVERB 1 it is **+2 in 11 of 11** consecutive pairs. `r1-allpass-motif.md` §4.2 says in its own words *"the search assumes the minimal offset of 1. **Stated as an assumption.**"* The descriptors refute it. | **FORCED** given round 5 B + D and `bounds.py`'s allocation model (§4, §5) |
| **C** | ★★★ **ROOM REVERB 1's THIRTY-TWO DESCRIPTOR CELLS ARE NOW ACCOUNTED FOR, ALL OF THEM.** 14 line reads + 12 line writes + 1 flush read + 1 prime write + 4 still-trapping C-format = 32. **Twelve delay lines**, each with exactly one write and one read, plus two extra early-reflection taps on the pre-delay buffer. | **PROVEN BY CONSTRUCTION** from FORCED inputs (§4) |
| **D** | ★★ **AND THE `9 STAGES vs 10 BUFFERS' OFF-BY-ONE THAT r1 §3/§8 LEFT OPEN DISSOLVES.** The program is **not** 5 + 4 independent ladder stages. The HEAD reads lines 0 and 1; the NINE motif repetitions read lines 2..10 and write lines 0..8; the TAIL writes lines 9 and 10 and both ends of line 11. Repetition 1 of the program writes **the pre-delay**, whose read is `w000`. | **MEASURED** (§4) |
| **E** | ★★ **THE READ LATENCY IS BOUNDED FROM THE ROM TO `land ∈ [1, 4]`, AND IT IS AN INTERVAL, NOT A VALUE.** Lower bound: the flush read of item A exists only if the datum is *not* on the read word's own bus ⇒ `land ≥ 1`. Upper bound: the datum must still be in the read-data register when the first word naming `SRC 0x0B` executes ⇒ `land ≤ 4`, the corpus minimum over 111 reads (and 4 is also the mode, 40 of 111). | **FORCED** within the printed model (§3) |
| **F** | ★★★ **`action-field.md` §8's "the BLOCKING read, FORCED 5145/5145" IS FALSIFIED — AND METHOD RULE 10 SAYS WHERE TO LOOK.** That forcing came from SINGLE DELAY read under the OLD polarity: `blocking-read.md` §3.3 labels `880.1.60.2D9` *"the DRAM READ"* and `880.1.20.64B` *"the DRAM WRITE"* — exactly the two labels **round 5 D reversed**. Under the corrected polarity the structural argument it rests on ("the read word's own ACTION captures the fetched sample") moves onto the **write** word, which is the pipeline, not the blocking read. | **FALSIFIED** (§3) |
| **G** | ★★ **`addr8` BIT 4 MARKS THE HEAD OF AN ACCESS CHAIN.** Set on 37 of the 38 images' first DRAM word (the exception, ENSEMBLE, is one of the 8 unaligned algorithms); never set on a WRITE; the 21 further heads sit at composite sub-effect boundaries and in the 2-cell blocks that own no delay line at all. | **CONSISTENT** — `H4 = a don't-care bit` is not refuted (§1) |
| **H** | ★★ **THE SEARCH THE BRIEF ORDERED WAS RUN, AND ITS STAGE A ARRIVES AT THE PIPELINE FROM THE ALU SIDE.** Exhaustively, over 3 057 600 settings: under the **FORCED** polarity the multiply at `slot 5` reads `SRC 0x19 = tempA` and the read is at `slot 4` with **nothing between them**, so the FRESH read reaches the multiplicand **only** under the blocking read — **4428 machines at `land = −1` and NONE at any `land ≥ 0`**. For every `land ≥ 0` the multiplicand can carry only an **earlier repetition's** read. That is the pipeline, reached from a direction §2 and §3 never used. Under r1's falsified polarity `land ∈ {0,1}` also work. | **MEASURED** (§6.1) |
| **H2** | ★ **STAGE B IS NOT A REJECTION AND IS NOT PRESENTED AS ONE.** r1's `loop_ok` is the only structural filter that exists and it is **specific to `wtrail = 1`** (`advance` returns `None` if asked twice). The `wtrail = 2` arms therefore run a pool selected by a filter that assumes the wrong trail, and random sampling has no power at all (**0 of 60** uniformly-drawn machines match even in the published space). **A zero at `wtrail = 2` is an absence of a search.** The named next experiment is a piece of machinery, not a parameter: extend `advance` past two atom generations so `loop_ok` can be stated for `wtrail = w`. | **OPEN** (§6.2) |
| **I** | ★★ **THE DATAPATH DOES NOT DECIDE COMB VERSUS ALL-PASS. Said plainly, as asked.** `schroeder-topology.md`'s survivors live in the `wtrail = 1` space the descriptors have now closed; they are survivors of a different machine. Neither confirmed nor refuted here. ★ **But an unasked-for by-product: at `wtrail = 1` the FORCED polarity matches the textbook SERIES COMB CASCADE 445 times and the ad-hoc `pipe-comb` family 0 times, while r1's falsified polarity matches only `pipe-comb`** — the direction correction moves the reverb from a bespoke reference onto a canonical one. And there is a second, independent obstruction no ALU search can dissolve: **every reference in the set — and every search r1, `schroeder-topology.md` and `blocking-read.md` ran — is a self-contained K-stage cascade**, while §4 shows the motif is a software-pipelined loop body whose lines straddle the ladder into the program head and tail. | **OPEN** (§6) |
| **J** | ★ **THE WRITE-DATA SOURCE IS STILL OPEN, AND I PREDICTED I WOULD CLOSE IT.** The corpus has writes naming `SRC 0x0B` (the read register, 50×), `mem[ptr]` (29×), the accumulator (3×) and `SRC 0x00` (27×). No route in this pass separates "the stored value is the bus" from "the stored value is the accumulator". | **OPEN**; PREDICT-THEN-CHECK **MISS** (P10) |
| **L** | ★★ **A CONTROL OF MINE THAT COULD NOT FAIL, CAUGHT IN THE PASS WHOSE BRIEF OPENS WITH THAT RULE.** The first numeric harness fed the REAL descriptor delays (172..739 samples) to a 24-sample test signal: no line recirculates, machine and reference both collapse to their direct path, and the matcher accepted **22 113 times out of 4 000 machines**. Caught, fixed (reduced delays `3 5 7 11 13`, 96 samples), and printed rather than quietly rewritten. | **PREDICT-THEN-CHECK MISS** (P14) |
| **K** | ★ **NOTHING BECOMES EXECUTABLE.** 0 of the 42 delay-DRAM frame slots. A word still needs the write-data source (J), one member of the latency interval (E), the rotation register `G` and the unit-1 cursor reload. | **OPEN** |

---

## 1. `addr8` bit 4 — the head of an access chain

`python3 dsp/tools/datapath.py chains`

**POPULATION (rule 9):** 38 distinct body images; 83 aligned algorithms.

The `addr8` sequence of every image, read straight off the ROM, shows a bit that
nothing had named:

```
   algo  9 SINGLE DELAY       30 60 20 60 20 60
   algo 10 MULTI TAP DELAY    30 60 20 20 20 20 60
   algo 16 ROOM REVERB 1      30 60 20 60 ... 20 60 20 80 80 20 80 80 20 60
   algo 64 S.DELAY+CHORUS     30 60 20 60 20 60 20 | 30 60 20 60 20 60 20 60
   algo 65 S.DELAY+S.DELAY    30 60 20 60 20 60 20 60 20 | 30 60
   algo 32 DISTORTION         30 30
```

* the **first** DRAM word of an image carries `addr8` bit 4: **37 of 38**
  (ENSEMBLE, algo 6, is the exception and is one of the eight algorithms whose
  descriptor block is unaligned);
* bit 4 is **never** set on a WRITE word;
* the 21 further heads are **not** noise: six sit at the sub-effect boundary of
  a composite (`S.DELAY+CHORUS`, `S.DELAY+S.DELAY`, `S.DELAY+FLANGER`,
  `S.DELAY+VIBRATO`, `S.DELAY+PHASER`, `AUTO WAH+S.DELAY`), and the rest belong
  to the 2-cell blocks (`30 30`) of algorithms that own **no delay line at all**
  — DISTORTION, OVERDRIVE, FUZZ, EXCITER, PHASER, PARAMETRIC EQ, AUTO PAN,
  AUTO WAH.

**ENUMERATION, PRINTED BESIDE THE CLAIM (rule 3):**

| reading | verdict |
|---|---|
| **H1** this access starts a chain | 37/37 aligned, and it accounts for every extra head |
| **H2** the previous DRAM word was a READ | **REFUTED** — MULTI TAP's `w016` follows a READ and is `0x20` |
| **H3** a wider address / a second DRAM bank | **REFUTED** — the same value range is reached by `0x20` and `0x30` words in different algorithms |
| **H4** nothing — a don't-care bit | **NOT REFUTED here** |

⇒ **CONSISTENT, not FORCED.** H4 survives §1 on its own. What prices it is §2:
a pipeline needs its validity managed at a chain boundary, and H4 offers no
reason for the bit to exist.

---

## 2. ★★★ The two dummies — the port is a one-deep pipeline

`python3 dsp/tools/datapath.py dummies`

**POPULATION (rule 9):** the 83 algorithms whose descriptor block is aligned,
829 cells. The roles CEILING and LIMIT are **`bounds.py`'s, imported
unchanged** — this section does not re-derive them, it asks *where they sit*.

```
   CEILING cells                        83
     ... the LAST READ of its own chain  83
     ... the LAST READ of the program    83
   LIMIT cells                           74
     ... FIRST WRITE of its own chain    74
     ... FIRST WRITE of the program      74
```

**Exceptionless, both ways.** Two cell classes that `dram-bounds.md` located and
explicitly left open (*"the instruction consuming it still traps, so where the
wrap happens stays OPEN"*) are the two ends of one mechanism:

* a WRITE word always stores something. The **first** write of a program has
  nothing meaningful to store yet — so it is aimed at an address **no read of
  that algorithm can reach**. That is exactly `bounds.py`'s LIMIT predicate,
  arrived at from a completely different direction.
* a READ word's datum is **not** on its own bus. The **last** real tap therefore
  needs one more port slot to become visible — so the program issues one more
  read, at an address **outside its own DRAM region**, whose datum is discarded.
  That is exactly `bounds.py`'s CEILING predicate.

### 2.1 The enumeration for the trailing out-of-region read (rule 3)

| # | reading | verdict |
|---|---|---|
| **E1** | a PIPELINE FLUSH | requires it to be LAST: **83/83** |
| **E2** | loading a per-unit WRAP/limit register (`dram-bounds.md`'s own suggestion) | a limit must be loaded *before* the accesses it bounds; it is last **83 of 83** |
| **E3** | a DRAM refresh cycle | refresh has no reason to be last, nor to be exactly one per algorithm, nor to be a READ |
| **E4** | padding to a fixed block size | **REFUTED** — `n` runs 2..32 |
| **E5** | coincidence | permutation null, §7 |

**E1 is the only member of the list that predicts the position it has.**

### 2.2 The counting separator — MULTI TAP DELAY

The one algorithm where host-side ground truth pins every datum. Four
host-named `op-0x67` taps at 6000 / 12000 / 18000 / 24000 samples off one base,
and five read words:

```
   w000  880.1.30.00B   cell 38   6000   READ  READ_END   ACT 0B
   w008  880.1.60.000   cell 39  32685   WRITE LIMIT      ACT 00
   w012  880.1.20.2C7   cell 40  12000   READ  READ_END   ACT 07  <- M<-bus, ANCHORED
   w016  880.1.20.2C7   cell 41  18000   READ  READ_END   ACT 07  <- M<-bus, ANCHORED
   w020  880.1.20.2C7   cell 42  24000   READ  READ_END   ACT 07  <- M<-bus, ANCHORED
   w024  880.1.20.2C7   cell 43  32768   READ  CEILING    ACT 07  <- M<-bus, ANCHORED
   w066  880.1.60.000   cell 44      0   WRITE LINE_BASE  ACT 00
```

`ACTION 0x07 = mem[ptr] ← bus` is one of the five **anchored** codes and was
fitted to nothing here.

| deposit | PIPELINED gives | BLOCKING gives |
|---|---|---|
| `w012` | 6000 (host-named) | 12000 (host-named) |
| `w016` | 12000 (host-named) | 18000 (host-named) |
| `w020` | 18000 (host-named) | 24000 (host-named) |
| `w024` | 24000 (host-named) | **32768 — OUT OF REGION** |

PIPELINED deposits a host-named tap **4 of 4** and an out-of-region word **0 of
4**; BLOCKING deposits **3 of 4** and **1 of 4**, and leaves the first
host-named tap fetched and never used. **The separation is one site wide in
this algorithm and is reported as such** — not as a corpus result.

**The pointer trace, printed so it can be checked (CONSISTENT).** Taking
`addr8` on a non-escape word as a signed post-displacement, the four deposits
land at `ptr+0, +1, +2, −9` and the first run of class-A `SRC 0x07` multiplies
after the last deposit reads `ptr+0, +1, +2, −9` — **the same four cells, in the
same order, including the odd −9**:

```
   deposit  w012 at ptr+0     multiply w027  010.A.01.1D5  reads ptr+0
   deposit  w016 at ptr+1     multiply w028  202.A.01.1D5  reads ptr+1
   deposit  w020 at ptr+2     multiply w029  202.A.F5.1D5  reads ptr+2
   deposit  w024 at ptr-9     multiply w030  202.A.0C.1D5  reads ptr-9
```

### 2.3 What the two dummy words themselves say — with both denominators

```
   the CEILING word's ACTION (pop 83): unknown 0x0B x48   ANCHORED ACTIVE x18
                                       ANCHORED INERT x12  unknown 0x00 x5
   the LIMIT   word's SRC    (pop 74): SRC 0x0B x64  SRC 0x07 x9  SRC 0x00 x1
```

`SRC 0x0B` is the anchored delay-RAM read register. The first write of a
program naming it in **64 of 74** is what the prime reading predicts — the word
exists to bring the chain-head read's datum onto the bus, and the store it
cannot avoid is aimed where no read can follow it.

★ **BUT THE SAME ASSOCIATION MEASURED OVER THE 38 DISTINCT IMAGES INSTEAD OF
THE 83 ALGORITHMS IS WEAK** — `SRC 0x0B` follows a READ in 48 % of cases and a
WRITE in 37 %, against 66 % / 12 % algorithm-weighted. The algorithm-weighted
number is carried by the twelve byte-identical reverbs. **CONSISTENT, NOT
FORCED**, and both denominators are printed so nobody quotes the flattering one.

---

## 3. ★★ The read latency, bounded from the ROM

`python3 dsp/tools/datapath.py latency`

**POPULATION (rule 9):** every READ word of the 38 distinct body images.

```
   READ -> next DRAM word           n=154  min=2   max=56
   READ -> next READ                n=124  min=4   max=56
   READ -> next word with SRC 0x0B  n=111  min=4   max=63   (4 is also the mode, 40x)
```

* **LOWER BOUND.** §2's flush read is needed only if the datum is *not* on the
  read word's own bus ⇒ **`land ≥ 1`**.
* **UPPER BOUND.** The datum must be in the read-data register when the first
  word naming `SRC 0x0B` executes ⇒ **`land ≤ 4`**, the corpus minimum.

⇒ **`land ∈ [1, 4]`. THIS IS AN INTERVAL, NOT A VALUE**, and nothing below
picks a member of it.

### 3.1 ★★★ And this is where method rule 10 pays

`action-field.md` §8 and `blocking-read.md` report the **BLOCKING** read
(`land = −1`) as **FORCED 5145/5145** by SINGLE DELAY. Read
`blocking-read.md` §3.3 again, with round 5 D in hand:

```
   880.1.60.2D9  ESC src=0B dram-rd  act=19   <- "the DRAM READ carries ACTION 0x19"
   880.1.20.64B  ESC src=19 tempA    act=0B   <- "the DRAM WRITE"
```

`addr8 0x60` is the **WRITE** and `0x20` is the **READ**. Those two labels are
**exactly the pair round 5 D reversed**, and the whole structural argument of
that section — *"both blocks put the fetched sample into a temp register with
the READ WORD'S OWN ACTION and consume it in the following word"* — is the
statement that the **write** word carries the capture. Under the corrected
polarity that is not a blocking read; **it is the pipeline**: the reverb motif's
`slot 0` write word `880.1.60.2D4` carries `SRC 0x0B` (the read register) and
the anchored `ACTION 0x14 = tempB ← bus`, four words after the `slot 4` read of
the previous repetition.

**VERDICT: `land = −1` FALSIFIED as a forced value; the measurement that
supported it is re-attributed, not discarded.** This is the fourth round in a
row in which two searches disagreed because one of them held a parameter fixed
— here, the direction itself.

---

## 4. ★★★ ROOM REVERB 1 — every one of the 32 cells accounted

`python3 dsp/tools/datapath.py ledger`

**POPULATION:** one algorithm, 32 cells, 133 words. The same body image serves
algos 16..27 byte for byte.

```
   LEDGER: 14 line reads + 12 line writes + 1 flush + 1 prime + 4 C-format = 32 = n
```

The twelve delay lines, **re-derived from the descriptor images** (rule 8 —
`8905` is not quoted, and neither is r1 §3's `chain 0  127 435 489 183 522`,
which came from the pairing `dram-matching.md` retracted):

```
   line  0  read cell  0  base cell  3    800 samples   18.141 ms   <- PRE DELAY
   line  1  read cell  2  base cell  5     83            1.882
   line  2  read cell  4  base cell  7    172            3.900
   line  3  read cell  6  base cell  9    356            8.073
   line  4  read cell  8  base cell 11    513           11.633
   line  5  read cell 10  base cell 13    739           16.757
   line  6  read cell 12  base cell 15    240            5.442
   line  7  read cell 14  base cell 17    119            2.698
   line  8  read cell 16  base cell 19    247            5.601
   line  9  read cell 18  base cell 21    428            9.705
   line 10  read cell 20  base cell 23    616           13.968
   line 11  read cell 22  base cell 31    360            8.163
   LADDER (lines 1..11)                  3873 samples = 87.82 ms
   PRE DELAY buffer, multi-tapped off cell 3:  800, 650, 540 samples
```

This reproduces round 5 item H's eleven segments and its `+9` closure exactly,
by a route that never uses a `+3` rule — the line of a read is the buffer the
read falls inside.

### 4.1 ★★ The write trail, and the off-by-one that dissolves

Every WRITE word followed four words later by a READ word — i.e. every
alternating port-slot pair of the program, the 8-word motif included:

```
   pair slot0 word cell  writes line   slot4 word cell  reads line  trail
     0   w011        1   (the PRIME)   w015        2    1            -
     1   w019        3   0             w023        4    2           +2
     2   w027        5   1             w031        6    3           +2
     3   w035        7   2             w039        8    4           +2
     4   w043        9   3             w047       10    5           +2
     5   w051       11   4             w055       12    6           +2
     6   w059       13   5             w063       14    7           +2
     7   w069       15   6             w073       16    8           +2
     8   w077       17   7             w081       18    9           +2
     9   w085       19   8             w089       20   10           +2
    10   w093       21   9             w097       22   11           +2
    11   w101       23  10             w105       24   12           +2
```

**+2 in 11 of 11.** Repetition *r* writes the base of line *r* and reads the top
of line *r+2*.

⇒ **`wtrail = 2`.** `r1-allpass-motif.md` §4.2, verbatim: *"Trailing by 2 or
more is not excluded by this argument alone, but would need a second register to
hold `d_in` across a whole repetition; **the search assumes the minimal offset of
1. Stated as an assumption.**"* The descriptors refute the assumption and
**confirm the register it names is needed**.

★ **AND THE `9 STAGES vs 10 BUFFERS' OFF-BY-ONE THAT r1 §3 FLAGGED AND §8 COULD
NOT CLOSE DISSOLVES.** There are twelve delay lines, each with exactly one write
and one read, plus two extra early-reflection taps on the pre-delay buffer — 12
writes and 14 reads. They are **not** partitioned 5 + 4 into two ladders:

* the program **HEAD** (`w000`, `w015`) reads lines 0 and 1;
* the **NINE** motif repetitions read lines 2..10 and write lines 0..8 —
  so repetition 1 of the program writes **the pre-delay**;
* the **TAIL** writes lines 9 and 10 and both ends of line 11.

---

## 5. ★★ The write trail, corpus-wide

`python3 dsp/tools/datapath.py wtrail`

**POPULATION (rule 9):** 324 lines over the 83 aligned algorithms.

```
   write consumer - read consumer, in DRAM PORT SLOTS
      -24     12      the twelve reverbs' 540-sample early-reflection tap
      -21     12      the twelve reverbs' 650-sample early-reflection tap
       +2      7
       +3    273      <== the mode
       +4      7
       +6      1
       +9     12      the twelve reverbs' line-11 closure
```

**+3 port slots in 273 of 324**, and in an alternating program +3 port slots is
+2 repetitions (§4). The 14 at +2/+4/+6 are composites, whose two sub-effects
interleave.

**WHAT THIS IS AND IS NOT:** it is a property of the layout `bounds.py` derived,
so it inherits that model's labels — **FORCED** for the 69 host-anchored
endpoints, **CONSISTENT** elsewhere. It is *not* independent evidence for the
allocation model.

---

## 6. The r1 re-run — the search the brief ordered

`python3 dsp/tools/datapath.py solve`

**THE ENUMERATION, PRINTED BESIDE THE CLAIM (rule 3):**

```
   read/write roles   2   swap=1 = round 5 D's FORCED polarity (slot 0 = WRITE,
                          slot 4 = READ); swap=0 = r1's F1, kept as the rival
                          AND as the positive control's setting
   wtrail             4   0..3;  the descriptors FORCE 2 (sect. 4).  r1 fixed
                          it at 1 and said so
   land              26   -1 (BLOCKING) and 0..24.  r1 searched [2,5];
                          schroeder/blocking-read searched {0,1,2,7,8} and {-1}
   ACTION 0x00/19/0B 35 each, over the declared EFFECTS space
   SRC 0x00           6   zero P M acc DR tA
   escact             2   is an ESCAPE word's ACTION honoured
   tbsh               2   the tempB >>1 relaxation
   order              2   sequential and THE ADDER
   write source       4   bus, acc before, acc after, mem[ptr]
   TOTAL              4 275 264 000 machines
```

The ladder inputs are **re-derived** (rule 8): gains `0.75 0.63 0.52 0.50 0.40`
from C-RAM `0x98..0x9C` (r1 §2, MEASURED) and delays **`172 356 513 739 240`**
from the descriptor images — *not* r1 §3's `127 435 489 183 522`.

### 6.1 Stage A — exhaustive, over a condition sound for every `wtrail`

The multiplicand must carry a delay-line datum — the fresh read `N`, or the read
still standing in the read-data register `D` — with coefficient ±1. It involves
neither `ACTION 0x0B` (which acts at the class-A slot, after that slot's bus is
latched), nor the write source, nor `wtrail`, so all three factor out exactly.

```
   enumerated 3 057 600 (swap, land, order, escact, tbsh, SRC 0x00, A00, A19)
   survivors, split by WHICH delay datum reaches the multiplier
     swap=1 (round-5 D, FORCED):
       via the FRESH read N: land -1: 4428   and NOTHING at any land >= 0
       via the STANDING read D (every land): 4428
     swap=0 (r1 F1, FALSIFIED):
       via the FRESH read N: land -1: 4428   land 0: 1728   land 1: 1728
       via the STANDING read D (every land): 4428
```

★ **RULE 4, AND IT BIT.** The first version of this filter asked *"N **or** D"*
and returned **the same 4428 for every land and both polarities** — one machine
counted twenty-six times, because the D route is available unconditionally. The
split above is the fix, and it is what makes the row informative.

★ **AND THE TWO POLARITIES DIFFER HERE, WHICH IS NEW.** Under the FORCED
polarity the multiply at `slot 5` reads `SRC 0x19 = tempA`, the read is at
`slot 4`, and **there is no word between them**: the fresh read reaches the
multiplicand **only** under the blocking read. For every `land ≥ 0` the reverb
multiplies a delay word fetched in an **earlier repetition** — which is exactly
what §2 and §4 say the port does, arrived at from the ALU side and from no part
of the descriptor bank. §3 bounds `land` to `[1,4]` from the ROM with no
reference to this search; the two ends agree that the reverb multiplies an older
sample. **Nothing is FORCED by that agreement** — it is the first time they have
met.

### 6.2 Stage B — the numeric ladder, with a positive control that says YES

**THE PRE-FILTER, AND ITS LIMIT, STATED BEFORE THE NUMBERS.** r1's `loop_ok` is
the only structural filter that exists for this machine and it is **specific to
`wtrail = 1`**: it advances the written value by exactly one repetition
(`advance`, which returns `None` if asked twice). So the `wtrail = 1` arms are a
real search over a filtered pool, and the `wtrail = 2` arms run the *same* pool,
selected by a filter that assumes the wrong trail. **A zero there is an absence
of a search, not a rejection.** Random sampling has no power at all here: **0 of
60** uniformly-drawn machines match even in the published space.

All four arms use the same executor, the same matcher and 40 deduplicated
references. Pools: `loop_ok`, swap 0 over `land ∈ {0,1,2,7,8}` → **23 520**;
swap 1 over `land ∈ {−1,0,1,2,3,4,5}` → **68 400**. 400 sampled from each.

```
   POSITIVE CONTROL -- the PUBLISHED space (swap=0, wtrail=1)
       400 machines,  714 matches
         pipe-comb b+1 c+1 hold u_last  x188      pipe-comb b+1 c+1 hold w_last x160
         pipe-comb b-1 c+1 hold w_last   x86      pipe-comb b+1 c+1 hold t_last  x82
   swap=1 FORCED, wtrail=1  (r1's assumed minimal offset)
       400 machines,  445 matches
         comb cascade, tap = stored     x250      comb cascade, tap = delayed   x195
   swap=1 FORCED, wtrail=2 FORCED   <== THE RE-RUN
       800 machines,    0 matches
   swap=0, wtrail=2   (isolates which change bites)
       800 machines,    0 matches

   WHICH CONSTRAINT BITES -- one change at a time
     swap 0 -> 1 alone (wtrail still 1)          445 matches
     wtrail 1 -> 2 alone (swap still 0)            0 matches
     both, i.e. the two FORCED values              0 matches
```

★ **THE CONTROL SAYS YES (rule 1).** The harness reproduces the published
pipe-comb family in the published space, on the same code path.

★★ **AND THE POLARITY CORRECTION IMPROVES THE TOPOLOGY MATCH — a result nobody
asked for.** Under r1's falsified polarity the reverb ladder matches only the
**pipe-comb** family, which is not a textbook structure at all — it is
`schroeder-topology.md` §6.3's own difference equation, written out and used as
its own reference. Under **round 5 D's FORCED polarity** the same pool matches
the **series comb cascade** `V_k = V_{k−1}/(1 − g_k z^{−D_k})`, a named
structure, 250 + 195 times, and matches the pipe-comb family **not at all**.
The direction correction moves the reverb from a bespoke reference onto a
canonical one.

★ **WHAT THIS DOES AND DOES NOT ESTABLISH.**
*Does:* the polarity is **not** what empties the reverb solve — `swap = 1` with
`wtrail = 1` still matches, 445 times. Every zero above is produced by `wtrail`.
*Does not:* it does **not refute** a `wtrail = 2` machine, because no filter for
`wtrail = 2` exists and the pool was built by the `wtrail = 1` one.

**THE NAMED NEXT EXPERIMENT, precisely:** extend r1's `advance` past two atom
generations so `loop_ok` can be stated for `wtrail = w`, then re-run. That is a
piece of *machinery*, not a parameter, and it is the whole reason this arm
cannot be closed in this pass.

**AND THE INDEPENDENT OBSTRUCTION, which no ALU search can dissolve.** With
`wtrail = 2` the motif is a software-pipelined loop body whose lines straddle
the ladder (§4): repetition 1 writes **the pre-delay**, whose read is `w000` in
the program HEAD, and the last two repetitions read lines whose writes are in
the TAIL. **Every reference in the set is a self-contained K-stage cascade**,
and so was every search r1, `schroeder-topology.md` and `blocking-read.md` ran.
The right object is the 12-line pipeline, head and tail included, and those
words are undecoded.

---

## 7. Rule 7 — the rivals, scored only where they disagree

`python3 dsp/tools/datapath.py rivals`

**GROUND TRUTH used for scoring, none of it this pass's output:** `bounds.py`'s
CEILING/LIMIT predicates (a region test and a write-above-every-read test, built
with no notion of a pipeline); the host's `op-0x67` tap labels and their
`BASE24` bases; the five anchored ACTION codes.

```
   RIVAL SET for the CEILING, scored on `is it the LAST read'
     E1 pipeline flush      predicts LAST      83 of 83
     E2 wrap-register load  predicts NOT last   0 of 83
     E5 coincidence         NULL: place each algorithm's dummy read uniformly
                            among its own reads -> expectation 24.2 of 83,
                            0 of 2000 trials reach 83
```

★ **A RIVAL MY TEST DOES *NOT* SEPARATE, REPORTED AS SUCH.** *"The CEILING is
simply the largest cell value and the allocator emits the block in ascending
order, so it lands last by construction."* On the twelve reverbs the ceiling
(32767) is **not** the largest value (45464 is), so the rival is refuted there
**12–0**. In the 71 unit-0 algorithms 32768 **is** the largest, and ordering is
exactly what my statistic measures: **UNSEPARATED**. I am not entitled to the
whole 83 by this route — item A rests on the *conjunction* of the position
statistic with the LIMIT statistic (which the ascending-order rival predicts
nothing about) and with §2.2.

---

## 8. The controls — each shown saying NO

`python3 dsp/tools/datapath.py control`

**POPULATION for every row:** the 83 aligned algorithms / 829 cells.

| control | CEILING last | LIMIT first |
|---|---|---|
| **[0] the ROM, unmodified** | **83/83** | **74/74** |
| **[1] DIRECTION REVERSED** (round 5 D flipped) | **0/83** | 19/78 |
| **[2] PHASE `δ = −1`** (round 5 B falsified it) | **8/83** | 1/36 |
| **[2] PHASE `δ = +1`** | **8/83** | 9/49 |
| **[3] NON-STRICT matching twin** | 83/83 | 74/87 |

Row [1] is the one that matters: **flipping the polarity takes the flush read
from 83/83 to 0/83.** The pipeline statistic is therefore *not* something the
cell values would produce under any labelling — it is downstream of round 5's
direction, and it independently re-confirms it from a route round 5 did not use.

Row [3] does **not** reject, and is printed as a failed discriminator: relaxing
the matching predicate adds 13 LIMIT cells without disturbing the 74.

★ **A CONTROL WHOSE EXPECTED FAILURE MODE DID NOT HAPPEN.** I built a
reversed-order twin — score *"is the CEILING the FIRST read"* and *"is the LIMIT
the LAST write"* — and **predicted it would score non-zero**, because the eight
`n = 2` algorithms have so few cells that first and last should coincide. They
do not: those blocks hold **two** reads, so the ceiling is last and not first.
The twin rejects cleanly, **0/83 and 0/83**. The prediction was wrong and the
control is stronger than I expected; recorded as a miss (P13), not silently
upgraded.

---

## 9. PREDICT-THEN-CHECK — hits AND misses

Recorded in full before the measurements they refer to (scratch
`PREDICTIONS.md`; P1 is recorded honestly as **observed-first**).

| # | verdict | prediction → what happened |
|---|---|---|
| **P1** | HIT* | `addr8` bit 4 marks a chain head — recorded as **observed-first**. 37 of 38 images; the 21 further heads split into 6 composite sub-effect boundaries and the 2-cell blocks of algorithms with no delay line. Labelled **CONSISTENT**, not FORCED |
| **P2** | **HIT** | CEILING is the last read of its chain in ≥ 75 of 83 → **83 of 83**, exceptionless |
| **P3** | **HIT** | LIMIT is the first write of its chain in ≥ 62 of 63 → **74 of 74**, exceptionless |
| **P4** | **MISS** | min gap READ → next DRAM word == 4 → it is **2**. Three read words are followed by a DRAM word only two slots later. The bound that matters (`SRC 0x0B`) is unaffected |
| **P5** | **HIT** | min gap READ → next `SRC 0x0B` word == 4 → **4**, and 4 is also the mode (40 of 111) |
| **P6** | **HIT** | `wtrail = 2` for the reverb motif → +2 in 11 of 11 pairs |
| **P7** | **MISS** | the re-run yields non-empty survivors → **zero at `wtrail = 2`**, and — worse for the prediction — the zero is *not even a rejection*, because no `wtrail = 2` filter exists |
| **P8** | HIT (weakly) | the survivors will not separate comb from all-pass → correct, but not for the reason predicted: at `wtrail = 1` the FORCED polarity matches the **comb cascade** 445 times and the all-pass 0, which is *more* separation than expected, in a space the descriptors have closed |
| **P9** | HIT, NOT BY THE PREDICTED ROUTE | `land = −1` rejected by the descriptor-anchored search → it is excluded by the **CEILING** argument, a structural result; the search itself never reached it |
| **P10** | **MISS** | the written value is forced to acc or `mem[ptr]` → **not established**. The write source is OPEN |
| **P11** | HIT, trivially | fewer than 10 of the 42 slots become executable → **zero**. Nothing is applied |
| **P12** | **HIT** | the 8 `30 30` algorithms perform exactly one useful read → their two cells are `[128, CEILING]`, 128 in region |
| **P13** | **MISS** | the reversed-order control twin would score non-zero because the `n = 2` blocks are degenerate → **0/83 and 0/83**. Those blocks hold *two* reads, so first and last do not coincide. The control is stronger than I expected and I was wrong about why |
| **P14** | **MISS** | the numeric harness would be sound as first written → **no**. It fed the real descriptor delays (172..739) to a 24-sample signal, no line recirculated, and the matcher accepted **22 113 of 4 000** — a control that could not fail, in the pass whose brief opens with that rule. Caught, fixed, printed |

**MISSES: 5 of 14**, two of them (P13, P14) about my own instruments.

---

## 10. What this changes about earlier claims

| source | claim | now |
|---|---|---|
| `dram-bounds.md` FORCED-1 | the CEILING is a per-unit ceiling register; *"where the wrap happens stays OPEN"* | ★ **RE-ATTRIBUTED** — it is the **flush read** of a one-deep pipeline. The wrap question is untouched and stays OPEN; the *cell* is spoken for |
| `dram-bounds.md` FORCED-2 | the LIMIT is *"an in-region WRITE above every READ"*, meaning OPEN | ★ **RE-ATTRIBUTED** — it is the **prime write**. Both `bounds.py` predicates survive; what changes is what they are *for* |
| `action-field.md` §8 / `blocking-read.md` | the BLOCKING read `land = −1`, **FORCED 5145/5145** | ★ **FALSIFIED** — the forcing used the pre-round-5 polarity (§3.1). `land ∈ [1,4]` |
| `r1-allpass-motif.md` §4.2 | *"the search assumes the minimal offset of 1"* | ★ **REFUTED by the descriptors** — `wtrail = 2` (§4.1) |
| `r1-allpass-motif.md` §3, §8 | *"5 buffers ↔ 5 core repetitions"*; the 9-vs-10 off-by-one is *"real and R1 does not close it"* | ★ **DISSOLVED** — 12 lines, 12 writes, 14 reads, one software-pipelined loop (§4) |
| `r1-allpass-motif.md` §3 | the ladder delays `127 435 489 183 522` | ★ **SUPERSEDED** — `172 356 513 739 240` from the descriptors (rule 8) |
| `schroeder-topology.md` | the reverb core is a comb network, 16 520 survivors vs 0 | ★ **NEITHER CONFIRMED NOR REFUTED** — those survivors live in the `wtrail = 1` space the descriptors close. The topology stays OPEN, exactly as round 5 item H left it |
| round 5 B, D | the identity map and `addr8` bit 6 | ★ **BOTH SURVIVE**, and the control in §8 re-confirms D from a new route |
| round 5 item H | the eleven segments and the `+9` closure | ★ **RE-DERIVED** independently (§4) |
| `dram-matching.md` A, C | `BASE24`, the `+3` anchor | ★ **SURVIVE** |

---

## 11. What is OPEN, and what the next pass needs

* **the write-data source** — bus / accumulator / `mem[ptr]`. §2.3 shows the
  field pattern; no route here separates them. This is the single missing piece
  for a WRITE word.
* **which member of `land ∈ [1,4]`** — an interval, not a value.
* **the 12-line pipeline's head and tail** — `w000..w018` and `w102..w132` of
  the reverb image are where lines 0, 1, 9, 10, 11 are driven, and no search has
  ever looked at them. **This is the named next experiment**: the motif is not a
  closed system and cannot be solved as one.
* **the topology** — comb vs all-pass. Not decided by the addresses (round 5 H)
  and not decided by the datapath (item I).
* **`ACTION 0x0B`** — 48 of the 83 CEILING words carry it, which is the largest
  single clue anyone has about it, and it is *not* enough.
* **the 48 trapping C-format cells**, the rotation register `G`, the unit-1
  cursor reload — unchanged.

---

## 12. Safety

`dsp/verify.py` reports **BYTE-MATCH OK**. Neither disassembler mirror is
touched; `dsp_disasm.py` and `upd6383d.cpp` are byte-for-byte as round 5 left
them. No `.dsm` listing, no device source, no MAME build. **0 of the 42
delay-DRAM frame slots become executable, and nothing is applied.**
