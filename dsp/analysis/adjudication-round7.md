# THE THREE WITHDRAWN FORCINGS, RE-DECIDED — and the reason two of them can never be re-scored where they were made

NEC **uPD6383GF-3BA** (Technics SX-KN5000, IC311). Date: **2026-07-27**.
No hardware. Static analysis of the Sub CPU ROM, the 100 canned parameter
streams, the 38 body images, the descriptor bank, the published tools and
`delayline.py` (round 7 target 1) only.

`adjudication-round6.md` withdrew three forcings because the harness that
produced them could not hold a delay line and, in two cases, ran at a DRAM
polarity that had been reversed a round earlier. Target 1 built the instrument.
This pass asks the three questions on it, **with the polarity ENUMERATED rather
than fixed at either value**.

Tool: [`../tools/readjudicate7.py`](../tools/readjudicate7.py) — stdlib only,
re-runnable, prints every number quoted below.

```
python3 dsp/tools/readjudicate7.py census     # 1 the DRAM-word census, both polarities
python3 dsp/tools/readjudicate7.py windows    # 2 *** WHICH LOOPS CAN THE ALU MODEL CLOSE?
python3 dsp/tools/readjudicate7.py controls   # 3 *** IT MUST SAY YES, AND IT MUST SAY NO
python3 dsp/tools/readjudicate7.py act19      # 4 *** QUESTION A
python3 dsp/tools/readjudicate7.py blockread  # 5 *** QUESTION B
python3 dsp/tools/readjudicate7.py adder      # 6 *** QUESTION C
python3 dsp/tools/readjudicate7.py all        #   everything (~7 min)
```

Cross-checks re-run verbatim, not quoted:

```
python3 dsp/tools/acc_adjudicate.py biquad          # 480 of 2160, act00 and order INVISIBLE
python3 dsp/tools/acc_adjudicate.py lfo             # 1224 ; order act_first 576 / adder 576 / act_last 72
python3 dsp/tools/acc_adjudicate.py single          # 72 of 3240 ; act19 FORCED -- and VOID, see B
python3 ~/compartilhado/kn7000_mame/tools/kn5000_dsp_alu.py \
        original_ROMs/kn5000_subprogram_v142.rom verify     # the five biquad dB numbers
python3 dsp/verify.py                               # BYTE-MATCH OK
```

Labels: **MEASURED** / **PROVEN BY CONSTRUCTION** / **FORCED** (every survivor of
an exhaustive search agrees) / **FORCED-IN-MODEL** / **CONSISTENT** /
**FALSIFIED** / **OPEN**.

---

## 0. Result in one page

| # | statement | label |
|---|---|---|
| **A** | ★★★ **SINGLE DELAY CANNOT DECIDE ACTION 0x19, AND NOT BECAUSE THE SEARCH RETURNS ZERO — BECAUSE THERE IS NO SEARCH TO RUN.** At the FORCED polarity algo 9's two delay loops are `w0→w28` and `w9→w46`, and **both cross `w21..w24`**, whose ACTIONs `0x0D`/`0x0E` `action00_discriminate.step` refuses. Neither maximal executable run (`w3..w20`, `w25..w43`) contains a line. Enumerated: 2 polarities × 4 windows × 4 port models × 7776 ALU machines — **every forced-polarity cell has no loop**. | **MEASURED** (§2, §4) |
| **B** | ★★★ **THE PUBLISHED `108` WAS NEVER A MEMORY ARTEFACT. IT IS A POLARITY ARTEFACT, AND ROUND 6's DIAGNOSIS IS CORRECTED.** On a genuine two-address line — read cell ≠ write cell, a rotation, the delay taken from the descriptor difference, a prime write, a flush read and three orphaned reads — the published-polarity window still yields **108 of 7776**, and **the same 108 machines**, set-identical to `adjudicate6.sd_search('published')`. Inside them `act19` is **FORCED `tA←bus` 108/108** and `src00` **FORCED `mem` 108/108**. | **MEASURED** (§3) |
| **C** | ★★★ **UNDER THE FORCED POLARITY, ACTION 0x19 OCCURS ON 0 OF 416 DRAM READ WORDS AND 103 OF 365 WRITE WORDS.** Every published argument for `ACTION 0x19 = tempA ← bus` is *"the read word's own ACTION captures the fetched sample"* (`blocking-read.md` §3.3, `action-field.md` §8). That argument is not weakened by the reversal — it is **UNAVAILABLE**, exhaustively. The same holds for 0x14 (115 WRITE / 0 READ) and 0x1A (39 / 0). | **MEASURED**, exhaustive (§1) |
| **D** | ★★★ **THE BLOCKING READ IS REFUTED — BY ITS OWN STRUCTURAL ARGUMENT, RELOCATED.** **13 of 83** CEILING (flush) read words carry `SRC 0x0B` **and** `ACTION 0x07` (`mem[ptr] ← bus`). Executed: under `port = blocking` `w78` of GATED REVERB stores **the CEILING's own datum** — an out-of-region address no write of the algorithm reaches, 83/83 — into internal RAM. Under `latency` and `push_any` it stores cell 16, a READ_END; under `push_read` cell 14, also a READ_END. **The flush read has a consumer, and only a pipeline gives it a meaningful one.** | **FORCED-IN-MODEL**, conditional on `SRC 0x0B` = the read register (§5) |
| **E** | ★★ **THE ADDER'S SECOND LEG IS NOT RE-DERIVABLE, AND `order = adder` REVERTS FORCED → CONSISTENT.** `acc-adder.md` §3.4's intersection was biquad 480 ∧ LFO 153 ∧ SINGLE DELAY 72 → 18, all `adder`. The SINGLE DELAY leg is the void one. Without it the intersection is biquad ∧ LFO, and there `order` takes **three** values (`act_first` 576 / `adder` 576 / `act_last` 72 of 1224). Both surviving contexts re-run and reproduce exactly. | **MEASURED** (§6) |
| **F** | ★★ **AND THE BIQUAD ANCHOR THE BRIEF NAMES IS AN ANCHOR THAT CANNOT FAIL.** PARAMETRIC EQ's ACTION codes are `07 12 13 14 15` — **no ACTION 0x00 word at all**, so `order` and `act00` are invisible to it: of the 480 bit-identical models, `order` takes all 3 values (160 each) and `act00` all 5 (96 each). The five per-band figures **0.00205 / 0.00463 / 0.00123 / 0.00119 / 0.00116 dB** re-run and reproduce to the digit — and they would have reproduced under *any* verdict this pass could reach. Method rule 1's other half. | **MEASURED** (§6) |
| **G** | ★★★ **A NEW POSITIVE RESULT, AND IT NEEDS NO DELAY LINE AT ALL: ACTION 0x19 IS A CAPTURE INTO tempA.** **401 of 402** sites in the 83 aligned body images are followed within four words by a word naming `SRC 0x19` (tempA) — base rate **29.9 %**, best-of-2000 permutation null **45.8 %**, observed **99.8 %**. `0x14`'s anchored signature calibrates the test (tempB at **149 of 149**). **It does NOT separate `tempA ← bus` from `tempA ← acc`** — both are captures into tempA. | **MEASURED**, with a stated null (§4) |
| **H** | ★★★ **THE CONTEXT THAT COULD DECIDE THE REST IS THE REVERB LADDER — AND IT IS TWO BLOCKERS AWAY, BOTH NAMED AND PRICED.** **90 of 324** lines in **13 of 83** algorithms have a read→write span that is wholly executable, and **all 90** contain an ACTION 0x19 word. But (i) only GATED REVERB's coefficient stream resolves — the twelve 133-word reverbs resolve **0 of 33** coefficient words each, a cursor-to-C-RAM map failure; and (ii) SINGLE DELAY's own loops need ACTION `0x0D` (370 words) and `0x0E` (376 words) decoded — **746 of 5894 body words, 12.7 %**. | **MEASURED** (§4) |
| **I** | ★★★ **THE NEW HARNESS'S OWN DEFAULT MAKES AN ALU SEARCH ON THE LADDER A TAUTOLOGY.** At `wdata = bus` a DRAM write commits its operand bus, and at the forced polarity **256 of 318** in-region write words name `SRC 0x0B`. Executed on GATED REVERB's six closed loops: **1** distinct write stream over 360 (machine, loop) pairs, **0 of 360** see ACTION 0x19, and **6 of 6** loops cannot hear the input. At `wdata = acc`: **80** streams, **360 of 360**, **0 of 6** deaf. `wdata` is `dram-datapath.md` item **J**, still OPEN — and it must now be enumerated in every ALU search. | **MEASURED** (§4) |
| **J** | ★★ **THE DESCRIPTOR BANK AND THE `lo12` FIELD POINT IN OPPOSITE DIRECTIONS, AND THAT IS BIGGER THAN ANY OF THE THREE RE-DECISIONS.** With the shipped SRC/ACTION reading, the operand bus has **no consumer at all** in **356 of 781** directed DRAM words at the forced polarity and **120 of 781** at the published one; 256 of the 356 name **tempA and throw it away**. The direction is not in doubt (round 5's three oracles, plus §1's orphan census below). What is in doubt is that a DRAM word's `lo12` means what an ALU word's `lo12` means. | **OPEN**, reported against this pass's own premise (§1) |
| **K** | ★ **AN INDEPENDENT CONFIRMATION OF ROUND 5's POLARITY, BY A ROUTE IT DID NOT USE.** Reads with no write below them ("orphans"): **9** at the forced polarity (in 9 of 83 algorithms), **217** at the published one (in 83 of 83). Not the multi-tap oracle, not the boundary-aging oracle, not the exhaustive field search — and it agrees with all three. | **CONSISTENT** (§1) |
| **L** | **NOTHING IS APPLIED.** No device source, no disassembler, no MAME build, no `.dsm`. `dsp/verify.py` reports **BYTE-MATCH OK**. 0 frame slots gain or lose an executable semantic. | — |

**THE THREE ANSWERS, IN ONE LINE EACH.**

* **A — `ACTION 0x19 / LO_ACT_CAP_TA2`: STILL-UNDECIDABLE in SINGLE DELAY,
  PERMANENTLY.** Its *destination* is **re-established by an independent route**
  (item G, 401/402 against a 45.8 % null): it is a capture into tempA. Its
  *source* — `bus` vs `acc` — is undecided, and the context that could decide it
  is the reverb ladder (item H). **It keeps shipping, and for a better reason
  than before.**
* **B — the BLOCKING READ: REFUTED**, not merely unproven (item D). Its premise
  is false at the forced polarity by exhaustive count (item C), and 13 flush
  words argue the other way. The count `5145`/`5635` cannot be re-scored at all.
* **C — the ADDER's SECOND LEG: NOT RE-DERIVABLE.** `order = adder` goes
  **FORCED → CONSISTENT** (item E). The biquad anchor holds and always would
  have (item F). **The device does not change**, because the adder and the
  shipped sequential form are the same machine on every word whose ACTION is not
  `0x00` (`acc-adder.md` §2, PROVEN BY CONSTRUCTION), and `ACTION 0x00 = load`
  was already CONSISTENT.

---

## 1. The census — where every ACTION and every SRC sits

`python3 dsp/tools/readjudicate7.py census`

**POPULATION: the 83 aligned algorithms, 5894 body words, 829 delay-DRAM words**
(48 of them C-format, no direction under either polarity; 781 directed).

```
   polarity = forced : direction x ACTION
          0x00  0x07  0x0B  0x0E  0x14  0x15  0x19  0x1A  0x1C
   READ     10    50   203     0     0   139     0     0    14
   WRITE    63     1     0    12   115    32   103    39     0
          0x00  0x02  0x07  0x0B  0x10  0x11  0x19   <- SRC
   READ     72    14     0    61    11     1   257
   WRITE    63     0    32   256    13     1     0
```

★★ **Every capture ACTION that appears on a DRAM word (`0x14`, `0x19`, `0x1A`)
appears on WRITE words only — 257 of 257 — and `SRC 0x19` (tempA) appears on
READ words only, 257 of 257.** Under the published polarity the table is the
mirror image. This is item **C**, and it is what kills the published
*argument* for `ACTION 0x19` and for the blocking read in one stroke: at the
forced polarity **no read word captures anything**.

**The ACTION histogram, and what the ALU model refuses** (item **H**'s price):

```
   0x00 1908  0x01   34  0x03   40  0x04    1  0x07  705  0x08   82
   0x0B  331  0x0C   32  0x0D  370  0x0E  376  0x11    2  0x12  100
   0x13   74  0x14  149  0x15 1174  0x16    2  0x19  402  0x1A   89
   0x1C   19  0x1D    4
   REFUSED TOTAL: 1051 of 5894 body words (17.8 %), of which 0x0D + 0x0E = 746
```

### 1.1 ★ The polarity, re-checked by a route round 5 did not use

`bounds.py` serves a read from the largest write below it. A read with **no**
write below it is an *orphan*: the algorithm reads an address nothing in it
writes. This is neither of round 5's oracles and it is not "fake buffer
overlap" either.

```
   polarity=forced    lines 324  ORPHANED READS   9 (in  9 of 83)  out-of-region 83  dead writes 63
   polarity=published lines 226  ORPHANED READS 217 (in 83 of 83)  out-of-region 21  dead writes 11
```

**CONSISTENT** with round 5 D, by an independent route. (Not a new forcing:
"served by the largest write below" is `bounds.py`'s allocation *model*, which
is exactly what its CONSISTENT labels mean.)

### 1.2 ★★ AND THE TENSION THIS PASS CREATES FOR ITSELF

A word's operand bus is *consumed*, under the shipped ALU model, if the word is
a coefficient consumer, or its ACTION is `0x00`/`0x07`/a capture, or it carries
a bit-4 store — and, on a WRITE, by the write itself whenever `wdata = bus`.

```
   polarity=forced     bus DEAD in 356 of 781 directed DRAM words
                       (dead buses name SRC 0x19 x256  SRC 0x00 x62  SRC 0x0B x24  SRC 0x02 x14)
   polarity=published  bus DEAD in 120 of 781 directed DRAM words
                       (dead buses name SRC 0x00 x62  SRC 0x07 x32  SRC 0x02 x14  SRC 0x10 x12)
```

**Reported against this pass's own premise.** The descriptor bank forces the
direction (round 5's three oracles; §1.1 agrees, 9 against 217). The `lo12`
field reads *better* at the other one. Both cannot be coincidence, and the
resolution is **not** to re-open the direction — the descriptor evidence is far
stronger than a plausibility argument about a field. It is that ★ **the `lo12`
of a DRAM word has never been decoded AS a DRAM word.** The SRC/ACTION reading
was built on ALU words, carried over, and carried over while `0x60 = READ` was
believed. A DRAM word's `lo12` is far more likely to be a **port-register spec**
— which register the fetched datum is delivered to, which register supplies the
stored one — and under that reading the same 36 bits mean the same thing at
either polarity and the 356 disappear. **OPEN**, and a bigger prize than any of
the three re-decisions.

---

## 2. Which delay loops can the ALU model close?

`python3 dsp/tools/readjudicate7.py windows`

A delay loop is *scoreable* only if every word between its READ and its WRITE
executes; `action00_discriminate.step` returns `False` on any word whose ACTION
is outside `{00,07,12,13,14,15,19,0B}` or whose `hi12[3:1] > 2`, and the run
stops. **ENUMERATION: 2 polarities × every line of every one of the 83 aligned
algorithms.** Nothing else is varied — this is a property of the words and the
descriptor bank, not of any ALU parameter.

```
   polarity = forced     lines 324  CLOSED-AND-EXECUTABLE 90  in 13 of 83  (90 contain an ACTION 0x19 word)
       algo 8  GATED REVERB   6 of  9 lines closed
       algo 16..27 (twelve reverbs) 7 of 14 lines closed each
   polarity = published  lines 226  CLOSED-AND-EXECUTABLE 90  in 62 of 83  (89 contain an ACTION 0x19 word)
```

### 2.1 ★★★ SINGLE DELAY

```
   48 words.  REFUSED: w1(0x0D) w2(0x0E) w21(0x0D) w22(0x0E) w23(0x0D) w24(0x0E) w44(0x0D) w45(0x0E)
   maximal executable runs: w0..w0, w3..w20, w25..w43, w46..w47

   polarity = forced
     cell0 w0  88013000B READ  15435    cell3 w28 8801602D9 WRITE     0
     cell1 w5  8801602D9 WRITE 31871    cell4 w32 88012064B READ  32768
     cell2 w9  88012064B READ  31370    cell5 w46 880160000 WRITE 15935
     LINE cell0@w0  -> cell3@w28  D=15435  span w0..w28  ** CROSSES A REFUSED WORD **
     LINE cell2@w9  -> cell5@w46  D=15435  span w9..w46  ** CROSSES A REFUSED WORD **
     orphaned reads [] ; out-of-region [4] ; dead writes [1]

   polarity = published
     LINE cell1@w5 -> cell2@w9  D=501  span w5..w9 : INSIDE the executable run w3..w20
     orphaned reads [0, 3, 5] ; out-of-region [] ; dead writes []
```

★★★ **The published search window `w5..w9` is a closed delay loop under the
published polarity and under no other.** The `108`, the `72`, the `5145` and the
`5635` were all scored on a loop that exists only at the polarity round 5
falsified, and **there is no window of SINGLE DELAY at which they can be
re-scored.**

*Note the shape of the forced-polarity block, because it is what a SINGLE DELAY
should look like:* two lines of **15435 samples = 350.0 ms**, one per channel,
each with the ×0.5 feedback coefficient (`w6`, `w29`) and the three-tap damping
filter (`w10..w12`, `w33..w35`, coefficients +0.273441 / +0.387057 / −0.207331)
**inside** the read→write span; plus exactly one prime write and one flush read.
Under the published polarity there is one line of 501 samples and three orphaned
reads.

---

## 3. The controls

`python3 dsp/tools/readjudicate7.py controls`

**YES — three of them, and the third is the one this round actually uses.**

```
   YES-1  adjudicate6.sd_search('published'), untouched     : 108 of 5832   (published 108)
   YES-2  delayline.py driven into the ONE-address config   : 108 of 5832
   YES-3  a REAL two-address line, published polarity       : 108 of 7776   (7776 completed)
             scaled cells [3, 19, 12, 0, 32, 4] region 32
             lines ['cell1<-cell2 D=7'] ; orphaned reads [0, 3, 5] ; out-of-region [] ; dead writes []
   ... and the two 108s are the SAME 108 machines, set-identical: True
```

The scaled cell values are chosen to preserve the six real cells' **rank order**
and to make `D = 7`, the published value, so the comparison is like-for-like.
What is *not* by construction is that a memory with two addresses, a rotation, a
prime write, a flush read and three orphaned reads returns the identical
survivor set.

**NO — six deliberately-wrong twins on that same arm, each one keyword away.**

```
   write cell moved +1                :    0 of 7776 <- SAYS NO
   read cell moved +1                 :    0 of 7776 <- SAYS NO
   rotation FROZEN   (grot=static)    :    0 of 7776 <- SAYS NO
   rotation REVERSED (grot=asc)       :    0 of 7776 <- SAYS NO
   descriptor cursor shifted (delta=1):    0 of 7776 <- SAYS NO
   polarity FLIPPED to forced         :    0 of 7776 <- SAYS NO
   REJECTED 6 of 6
```

**DEGENERACY FIRST (rule 4).** The 402 corpus ACTION 0x19 sites split by SRC;
at `SRC 0x10` the readings `tA←bus` and `tA←acc` differ only through the word's
own accumulator step, elsewhere they differ outright. The three readings are
**not** degenerate on this corpus.

**SEPARATION (rule 7).** The rival that ignores the instruction entirely
(`act19 = none`, a fourth value added to the published three) scores **0 of
108**. The test separates.

---

## 4. QUESTION A — ACTION 0x19 / `LO_ACT_CAP_TA2`

`python3 dsp/tools/readjudicate7.py act19`

**ENUMERATION, printed beside the claim.** polarity {forced, published} × port
{push_read, push_any, latency, blocking} × window {`w5..w9`, `w3..w20`,
`w25..w43`, whole 48} × act19 {tA←bus, tA←acc, tB←bus, **NONE**} × order (3) ×
act00 (6) × sttime (3) × stgate (6) × src00 (6) = **7776 ALU machines per
(polarity, port, window) cell, 32 cells**.

```
   polarity   port        window     loop               hits   ran/tot
   published  blocking    w5..w9     cell1<-cell2 D=7    108   7776/7776
   published  blocking    w3..w20    cell1<-cell2 D=7    108   7776/7776
   published  blocking    w25..w43   -- NONE --          n/a   -
   published  blocking    whole 48   cell1<-cell2 D=7      0   0/7776
   published  latency/push_read/push_any, all windows      0   (7776 ran where a loop exists)
   forced     every port, w5..w9 / w3..w20 / w25..w43  -- NONE --   n/a
   forced     every port, whole 48                        0   0/7776
```

★ **Read the `-- NONE --` rows as *no search*, not *no survivors*.** And read the
`whole 48` rows the same way: **0 of 7776 machines complete the program**, for
the reason `delay-harness.md` item J gives — `w1` carries ACTION `0x0D`.

**What the one scoreable arm says:**

```
   polarity=published port=blocking window=w5..w9 TWO ADDRESSES : 108 of 7776
     act19   FORCED    tA<-bus x108
     order   2 values  adder x72   act_last x36
     act00   4 values  add x36  sub x36  load x18  rload x18
     src00   FORCED    mem x108
```

So the only configuration in which SINGLE DELAY constrains ACTION 0x19 is the
one whose DRAM polarity is falsified. The determination is not reproduced at the
forced polarity and it is not refuted there either — **it is unreachable.**

### 4.1 ★★ Can any other block decide it? (the context the brief asks to be named)

```
   lines with a closed, EXECUTABLE read->write span, forced polarity : 90 of 324
   of those, lines whose span contains an ACTION 0x19 word          : 90
     algo 8  GATED REVERB       6 closed lines
     algo 16..27 twelve reverbs 7 closed lines each
```

**And two blockers stand in front of it, both new, both priced:**

```
   algorithms whose C-RAM stream resolves for EVERY coefficient-consuming word : 70 of 83
   ... of the 13 with a closed executable loop, that leaves: [8]
```

★ The twelve 133-word reverbs resolve **0 of 33** coefficient words each — the
cursor-to-C-RAM map that works for the 48-word blocks does not work for them.
**Of the 13 algorithms that can close a loop, exactly one can be executed
today.** Fixing that map is the cheapest single thing anyone can do for this
question. The other blocker is ACTION `0x0D`/`0x0E`, 746 words.

### 4.2 ★★★ AND THE HARNESS'S OWN DEFAULT MAKES THE TEST A TAUTOLOGY

On GATED REVERB's six closed loops, 60 base machines × 4 act19 readings:

```
   algo 8  wdata=bus :   0 of 360 (machine, loop) pairs SEE act19 ;  1 distinct write
                         stream over all 1440 runs ; 6 of 6 loops CANNOT hear the input
   algo 8  wdata=acc : 360 of 360 pairs SEE act19 ; 80 distinct streams ; 0 of 6 deaf
```

At `wdata = bus` a DRAM write commits its operand bus, and at the forced
polarity **256 of 318** in-region write words name `SRC 0x0B`, the read
register: the delay line receives what the delay line produced. ★★ **A search
that scores a delay-line write stream at `wdata = bus` is a control that cannot
fail.** `wdata` is `dram-datapath.md` item **J**, OPEN; it must be enumerated in
every future ALU search and its default should not be `bus`.

**What this is NOT:** it is not a forcing of `wdata = acc`. The window excludes
algo 8's two non-`0x0B` write words (`w74` `SRC 0x10`, `w100` `SRC 0x00`), so a
cascade in which the input is injected there and propagates line-to-line through
the read register over several frames is **not** excluded by this measurement.
Stated because the measurement cannot see it.

### 4.3 ★★★ The new positive result — and it needs no delay line at all

The owner's structural support for keeping `LO_ACT_CAP_TA2` is *"`0x19 = 0x13+6`
and `0x1A = 0x14+6`, a second capture pair mirroring an established one"*. That
is a claim about **semantics**, and semantics have a consequence: a word that
loads tempA should be **followed** by a word that names tempA. `0x13` and `0x14`
are anchored and calibrate the test; `0x12` and `0x15` are the no-effect nulls.

*Prediction, written before the count: `0x19` tracks `0x13`; if instead its
successors name tempB, the shipped assignment is backwards.*

```
   base rate over all 5894 positions: tempA source within 4 words 29.9 % ; tempB 15.8 %

   ACTION   n     -> tempA used   -> tempB used   role
   0x13     74      56.8 %          56.8 %      ANCHORED tA<-bus
   0x14    149      79.9 %         100.0 %      ANCHORED tB<-bus
   0x19    402      99.8 %          39.1 %      ** THE QUESTION **
   0x1A     89      94.4 %          94.4 %      the pair's twin
   0x12    100       0.0 %          28.0 %      null: no effect
   0x15   1174      30.6 %           7.7 %      null: no effect
   0x07    705      32.5 %          11.3 %      null: mem<-bus

   PERMUTATION NULL, 2000 shuffles of the ACTION field inside each program
   (successor structure untouched): best null rate 45.8 % ; observed 99.8 %
```

★★ **401 of 402 ACTION 0x19 sites are followed within four words by a word that
names tempA.** `ACTION 0x19 IS A CAPTURE INTO tempA` — **MEASURED**, by a route
that touches neither the delay memory nor the polarity. **It does not separate
`tempA ← bus` from `tempA ← acc`**; both are captures into tempA, and that is
precisely the pair the old model left at 2940 / 2205 before forcing one of them
on the falsified polarity. Reported against myself: `0x13`'s own signature does
**not** separate (56.8 % / 56.8 %), and `0x1A`'s does not either (94.4 % /
94.4 %) — the calibration works for `0x14` and fails for `0x13`.

### 4.4 VERDICT ON A

**STILL-UNDECIDABLE in SINGLE DELAY — permanently, and the shipping decision
does not change, but its justification does.** `LO_ACT_CAP_TA2` keeps shipping
because (i) it is unrefuted, (ii) its **destination** is now independently
measured (§4.3), and (iii) the residual ambiguity is `bus` vs `acc`, which no
executable context can currently see. It does **not** ship because SINGLE DELAY
forces it: SINGLE DELAY cannot force anything about it at the polarity that is
forced. **Both disassembler mirrors' comments must say exactly that.**

---

## 5. QUESTION B — the blocking read

`python3 dsp/tools/readjudicate7.py blockread`

**5.1 The structural half.** `blocking-read.md` §3.3: *"both blocks put the
fetched sample into a temp register **with the read word's own ACTION**"*.

```
   READ  words whose own ACTION is a capture (0x13/0x14/0x19/0x1A) :   0 of 416
   WRITE words whose own ACTION is a capture                       : 257 of 365
```

**The premise is false at the forced polarity, exhaustively.** Not weakened —
false.

**5.2 And the same words now argue the other way.** CEILING (flush) read words,
one per algorithm, 83 of 83:

```
   SRC 0x19  ACT 0x0B  x48      SRC 0x0B  ACT 0x07  x13   <-- these
   SRC 0x0B  ACT 0x15  x12      SRC 0x10  ACT 0x07  x4
   SRC 0x00  ACT 0x00  x5       SRC 0x19  ACT 0x07  x1
   CEILING words that CONSUME SRC 0x0B into a register or memory : 13 of 83
     algo 1 CHORUS w64 · algo 2 MODULATED CHORUS w79 · algo 3 ENHANCER w92
     algo 8 GATED REVERB w78 · algo 10 MULTI TAP DELAY w24 · algo 15 ROCK ROTARY w78 ...
```

Executed. The delay-DRAM access sequence is fixed by the DRAM words and the
cursor alone — no ALU parameter can change it — so the provenance of the read
register can be simulated on a program the ALU model cannot run. Each read is
tagged with the cell that issued it; the table says **which read's datum is
standing in DR when `w78`'s own bus is latched** (algo 8, 20 DRAM words, 4
frames, steady state):

```
   port=blocking   : w78's bus carries the datum of cell18 (CEILING,  addr 32768)
   port=latency    : ...                             cell16 (READ_END, addr 14552)
   port=push_read  : ...                             cell14 (READ_END, addr 12752)
   port=push_any   : ...                             cell16 (READ_END, addr 14552)
```

★★ Under `blocking`, the flush read's `ACTION 0x07` stores **the CEILING datum**
— an out-of-region address no write of the algorithm ever reaches
(`dram-bounds.md` item C, 83/83), the one value in the machine guaranteed to be
meaningless — into `mem[ptr]`. Under **every** pipelined model it stores a real
tap.

**CONDITIONAL, and the condition is named:** `SRC 0x0B` = the delay-RAM read
register. That code is **not** in `_ANCHORED_SRC`; `dram-datapath.md` calls it
anchored and round 5's `H-SRC0B` oracle scored it at 20.3 %. If `SRC 0x0B` is
something else this argument evaporates — **and so does every `land` bound in
`dram-datapath.md` §3, which is built on the same code.**

**5.3 The numeric half cannot be re-scored.** `sec_singledelay` scores `w5..w9`
with `land ∈ (−1,0,1,2)`. At the forced polarity `w5` is the prime write and
`w9` reads a line whose base is at `w46`, outside every executable run. Not
"zero survivors" — **no search**.

**5.4 VERDICT ON B: REFUTED, not merely unproven.** The forcing rested on a
premise that is false by exhaustive count (0 of 416), and 13 flush words argue
against the model it forced. `blocking` remains an enumerable port model; the
device already refuses to act on any of them. **WITHDRAWN AND FALSIFIED: the
published `5145/5145`, `3206/3206`, `2310/2310` and the re-measured
`5635/5635` must never be quoted again** — `retraction_sweep.py` already knows the first three; the fourth joins
them.

*The brief anticipated that this might come out "true for a different reason".
It did not. It came out **false for the reason it was true**: the argument moved
onto the write word, and there it is an argument for the pipeline.*

---

## 6. QUESTION C — the accumulator adder's second leg

`python3 dsp/tools/readjudicate7.py adder`

**6.1 Is the second leg still a witness?** `SINGLE DELAY w7 = 000024_8000`,
`SRC 0x00`, `ACT 0x00`, `hi12[3:1] = 0`. The word is unchanged and its pointer
walk is unchanged. What is gone is the reason to believe its output is
`x + fb·v[n−D]` — that came from matching the `w5..w9` **write** against a comb,
and at the forced polarity `w9` is not a write and `w5` writes an address
nothing reads. **The witness word survives; the constraint on its value does
not.**

**6.2 The anchor the brief names, and why it cannot move.**

```
   the PARAMETRIC EQ section's ACTION codes : 07 12 13 14 15
   does it contain ACTION 0x00 ?            : NO
   acc_adjudicate.py biquad : 480 of 2160 bit-identical
        order  3 values  act_last x160  act_first x160  adder x160
        act00  5 values  none x96  add x96  sub x96  load x96  rload x96
   kn5000_dsp_alu.py verify : algo39 PARAMETRIC EQ bands 0..4
        0.00205 / 0.00463 / 0.00123 / 0.00119 / 0.00116 dB   -- reproduced to the digit
```

★ The five numbers are exactly where they were, and **they would have been under
any verdict this pass could reach**. That is method rule 1's other half: an
anchor that cannot fail is not evidence for the thing it anchors.

**6.3 What is left holding `order = adder` up?** `acc-adder.md` §3.4 intersected
biquad 480 ∧ LFO 153 ∧ SINGLE DELAY 72 → 18, all `adder`. Remove the void leg:

```
   acc_adjudicate.py lfo, re-run : 181440 -> 1632 -> 1632 -> 1224
        order  3 values  act_first x576  adder x576  act_last x72
        src08  FORCED    unity x1224
   acc_adjudicate.py single, re-run : 72 of 3240   (act19 FORCED tA<-bus, src00 FORCED mem)
        -- and VOID: its Line reads and writes one cell and it hardcodes
           addr8 0x20 = WRITE, the reversed polarity.
```

★ **`order = adder` reverts FORCED (18/18, three contexts) → CONSISTENT (two
contexts, neither of which can see the order).**

**6.4 Is there a replacement witness?** The unification needs two words that must
both compute `bus + P` while carrying different `hi12[3:1]`:

```
   hi12[3:1]   ACTION 0x00 words   of which inside a CLOSED, EXECUTABLE delay loop
   0                661                191
   1                850                103
   2                166                 90
   3..7             231                  0
```

A replacement exists in principle — the ladder's closed loops carry ACTION 0x00
words at three different `hi12[3:1]`. What they lack is a **reference**: the same
missing piece as question A, blocked by the same two things.

**6.5 VERDICT ON C: NOT RE-DERIVABLE, and the device does not change.**
`acc-adder.md` §2 proves BY CONSTRUCTION that on every word whose ACTION is not
`0x00` the adder form and the shipped sequential form are the **same machine**
(`f31=0 → 0+P`, `f31=1 → acc+P`, `f31=2 → acc+0`). The three orders differ only
on ACTION 0x00 words, and `ACTION 0x00 = load` was already relabelled
FORCED → CONSISTENT by `blocking-read.md` §6. **The retraction is a label change
on a claim that was already carrying the weaker label downstream, and it costs
zero executing words.**

---

## 7. PREDICT-THEN-CHECK — hits and misses, equally prominent

Each prediction is recorded with the point at which it was formed.

| # | formed | prediction → what happened |
|---|---|---|
| **P1** | after dumping algo 9, before the corpus count | the ACTION 0x19 / SRC 0x19 segregation seen in algo 9 would hold corpus-wide → **HIT**, and total: **0 of 416 / 103 of 365**, and the mirror for `0x14` and `0x1A` |
| **P2** | before running the two-address published arm | the published `108` would **change** on a real two-address line, because round 6 blamed the one-cell `Line` → ★ **MISS.** It is **108**, and the **same 108 machines**. The `108` was a polarity artefact all along; round 6 §3.5's diagnosis is corrected |
| **P3** | before the window census | SINGLE DELAY's forced-polarity loops would be scoreable in *some* window → ★ **MISS.** Both cross `w21..w24`; there is no window |
| **P4** | before the corpus loop census | the 133-word reverbs would be no better off (9 refused words each) → ★ **MISS.** **90 of 324** lines closed, in 13 algorithms, all of them reverbs |
| **P5** | before the orphan census | the orphan count would mildly favour the forced polarity → **HIT, and far stronger**: 9 against 217 |
| **P6** | before looking at the CEILING words | the flush reads would be inert — no consumer, which is what "discarded" means → ★ **MISS.** **13 of 83** consume `SRC 0x0B` through `ACTION 0x07`, and that miss is what refutes the blocking read |
| **P7** | before re-running the biquad | the biquad anchor would constrain nothing about `order`/`act00` → **HIT**, by construction: the section has no ACTION 0x00 word |
| **P8** | before the separation control | the instruction-blind rival would survive, i.e. the test would not separate → ★ **MISS**, and the good kind: **0 of 108** |
| **P9** | before §4.3 | `0x19`'s successors would name tempA above base rate, and `0x13`'s would too → **HALF-HIT.** `0x19` at **99.8 %** against a 45.8 % null; **`0x13` does not separate at all** (56.8 % / 56.8 %) |
| **P10** | before §4.2 | the ladder would be *sensitive* to `act19`, so the reverb context could decide it once a reference exists → ★ **MISS at the harness default.** At `wdata = bus` it is blind, 1 stream over 1440 runs; only at `wdata = acc` does it see the field |
| **P11** | before §1.2 | the shipped `lo12` reading would look equally (un)natural at both polarities → ★ **MISS.** 356 dead buses against 120, and the discrepancy is a finding in its own right |

**MISSES: 6.5 of 11**, five of them about my own instruments — which is the same
ratio the last two rounds reported, and for the same reason.

---

## 8. What the other notes must change

★ **The two retractions are filed as sweep premises, so nobody can quote them
again by accident.** `dsp/tools/retraction_sweep.py` gains `P19` (the blocking
read / `5145` / `5635`) and `P20` (`order = adder` FORCED 18/18); `selftest`
still passes both directions, and the sweep already flags **13 LIVE hits for
P19** (in `action-field.md`, `blocking-read.md`, `allpass-adder-rerun.md`,
`store-gate.md`, `adjudication-round6.md`) and **1 for P20** (`acc-adder.md`
item C). Those notes are **not** edited here — three of them are being written
by concurrent passes and the shared index makes an in-place edit a collision
risk. The sweep is the propagation mechanism; the table below is the list.


| source | claim | now |
|---|---|---|
| `adjudication-round6.md` §3.4/§3.5 | the `108 → 0` is an artefact of the one-cursor `Line` | ★ **CORRECTED.** The `108` reproduces exactly, set-identical, on a genuine two-address line. It is a **polarity** artefact; the memory model was never what produced it |
| `blocking-read.md` items **A**,**B**,**D**,**F**, §3.3 | the blocking read; "both blocks put the fetched sample into a temp with the READ WORD's own ACTION" | ★★ **FALSIFIED at the forced polarity: 0 of 416 read words carry a capture ACTION.** Items C/D/I, which are counts inside that read model, are void with it |
| `action-field.md` §8 | `land = −1` FORCED 5145/5145 | ★ **UNRE-SCOREABLE.** No window of SINGLE DELAY contains a loop at the forced polarity. Add to `retraction_sweep.py` alongside `5635` |
| `acc-adder.md` item **B**/**C**, §3.4 | `order = adder` FORCED, 18/18 | ★ **FORCED → CONSISTENT.** The SINGLE DELAY leg is void; biquad ∧ LFO leaves three orders |
| `acc-adder.md` item **E** | `ACTION 0x19 = tA←bus` 72/72, `SRC 0x00 = mem` 72/72 | ★ **VOID as forcings** (one-cell line + reversed polarity), and the numbers still reproduce — the tool is unchanged, the model is wrong |
| `dram-datapath.md` item **J** (`wdata` OPEN) | "no route in this pass separates bus from acc" | ★ **A ROUTE EXISTS AND IT IS URGENT.** At `wdata = bus` the ladder's line writes are ALU-independent and input-deaf; every future ALU search must enumerate `wdata` |
| `dram-datapath.md` item **E** (`land ∈ [1,4]`) | bounded from the ROM | ★ its lower bound and its upper bound are both built on `SRC 0x0B` = the read register, which is **not** anchored; §5.2 makes that dependency explicit |
| `delay-harness.md` §3 | `wdata` default `bus` | ★ **the default is a hypothesis that silently disables ALU searches on the ladder.** Change it or enumerate it |
| `dsp_disasm.py` / `upd6383d.h` `LO_ACT_CAP_TA2` comment | "the semantic is retained deliberately and is not forced… what re-derives it is a two-address delay line" | ★ **the two-address line exists and it does NOT re-derive it.** The comment must say: destination measured (§4.3), source OPEN, SINGLE DELAY cannot decide it at the forced polarity |
| `schroeder-topology.md` §0-C, re-opened by round 6 | the conditional challenge to the strict vocabulary | ★ **still re-opened, and now unreachable from SINGLE DELAY.** Its own block (the ladder) is executable for exactly one algorithm |

---

## 9. What is FORCED, CONSISTENT, OPEN and FALSIFIED after this pass

**FORCED / PROVEN BY CONSTRUCTION / MEASURED**

* SINGLE DELAY has **no** closed executable delay loop at the forced polarity
  (§2.1); the published window is one at the published polarity and nowhere else.
* ACTION 0x19 / 0x14 / 0x1A occur on DRAM **WRITE** words only, 257 of 257 (§1).
* ACTION 0x19 is a **capture into tempA**: 401 of 402 sites, base 29.9 %,
  best-of-2000 null 45.8 % (§4.3).
* The `108` reproduces on a two-address line, set-identical (§3).
* The biquad cannot see `order` or `act00` (§6.2), and its five dB figures are
  unchanged.
* 90 of 324 lines in 13 of 83 algorithms have a wholly executable read→write
  span; 1 of those 13 has a resolvable coefficient stream (§4.1).

**FORCED-IN-MODEL** (conditional, condition named)

* The blocking read is refuted by the 13 flush words — conditional on
  `SRC 0x0B` = the read register (§5.2).

**CONSISTENT**

* `order = adder` — WITHDRAWN as FORCED, now only CONSISTENT (§6.3).
* `LO_ACT_CAP_TA2 = tempA ← bus` — destination measured, source unresolved;
  **it keeps shipping** (§4.4).
* Round 5's polarity, re-confirmed by the orphan census 9 : 217 (§1.1).

**OPEN**

* ★ `wdata` (`bus` vs `acc`) — and it is now the **rank-1** parameter, because
  it decides whether an ALU search on the ladder is a test at all (§4.2).
* ★ What a DRAM word's `lo12` means **as a DRAM word** — 356 dead buses (§1.2).
* `ACTION 0x0D` (370 words) and `0x0E` (376) — the words that close SINGLE
  DELAY's loops.
* The cursor-to-C-RAM map for the twelve 133-word reverbs (0 of 33 each).
* `tempA ← bus` vs `tempA ← acc`; `SRC 0x00`; the port model; the reverb
  reference on a memory that delays.

**FALSIFIED**

* "the read word's own ACTION consumes the fetched sample" — 0 of 416 (§5.1).
* The blocking read as a **forcing** of SINGLE DELAY; and the numbers `5145`,
  `5635`, `3206`, `2310`, `72/72`, `108/108` as **forcings** (they remain
  reproducible as *outputs of a model whose polarity is wrong*).
* `order = adder` as **FORCED** — FALSIFIED as a forcing (§6.3).

---

## 10. Safety

Nothing is applied. No `src/devices/cpu/upd6383/` file, no `dsp/tools/dsp_disasm.py`,
no `.dsm` listing, no MAME build is touched by this pass; the only new files are
`dsp/tools/readjudicate7.py` and this note. `dsp/verify.py` reports
**BYTE-MATCH OK** (kernel + epilogue + 91 valid algorithm streams, 38 distinct
images). 0 of the 285 frame slots gain or lose an executable semantic, so the
frame floor, the closure residue and the audio are bit-identical by construction.
