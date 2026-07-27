# THE HARNESS THAT CAN HOLD A DELAY LINE — a two-address line, a one-deep port, and the structural filter that could only be asked twice

NEC uPD6383GF-3BA (Technics SX-KN5000, IC311). No hardware; static analysis of the
Sub CPU ROM, the 100 canned parameter streams, the 38 body images, the descriptor
bank and the published tools only.

**This pass is MACHINERY.** Three agents execute against it next and an
adjudicator audits it, so everything below is written to be re-run, not believed:

```
python3 dsp/tools/delayline.py enum      #  1 the parameter enumeration + defaults
python3 dsp/tools/delayline.py delay     #  2 *** IT MUST DELAY
python3 dsp/tools/delayline.py refs      #  3 *** IT MUST SAY YES  (+ rule 7)
python3 dsp/tools/delayline.py twins     #  4 *** IT MUST SAY NO
python3 dsp/tools/delayline.py degen     #  5 rule 4, run BEFORE any score
python3 dsp/tools/delayline.py loopok    #  6 *** loop_ok for a general wtrail
python3 dsp/tools/delayline.py loopok --full   #   ... and the whole wtrail=2 pool
python3 dsp/tools/delayline.py ledger    #  7 the ROM programs, executed
python3 dsp/tools/delayline.py migrate   #  8 *** the published search, re-expressed
python3 dsp/tools/delayline.py migrate --slow  #   ... including the two-address arm
python3 dsp/tools/delayline.py repro     #  9 the OLD path, unmodified
python3 dsp/tools/delayline.py cannot    # 10 what this harness CANNOT express
python3 dsp/tools/delayline.py all       #    everything except `repro'   (~3 min)
```

---

## 0. Result in one page

| # | statement | label |
|---|---|---|
| **A** | ★★★ **THE HARNESS EXISTS, IT DELAYS, AND THE DELAY IS THE DIFFERENCE OF TWO DESCRIPTOR ADDRESSES.** A value written at frame *n* to offset `wa` is read at frame `n + (ra − wa)` from offset `ra`, **for any placement of the two accesses inside the frame** — read-first and write-first give **bit-identical** output. Printed frame by frame in §4. | **PROVEN BY CONSTRUCTION** |
| **B** | ★★★ **THE PUBLISHED `Line` IS A POINT OF THE NEW SPACE, AND THE NEW HARNESS REPRODUCES ITS PUBLISHED NUMBER EXACTLY.** Identify the read cell with the write cell and shrink the region to *D* and the two-address memory **is** `Line(D)`. In that configuration the new harness scores the published SINGLE DELAY space at **108 of 5832**, the same 108 `adjudicate6.py polarity` prints from the old code path. | **MEASURED** (§10) |
| **C** | ★★★ **THE `wtrail = 2` STRUCTURAL FILTER NOW EXISTS, AND ITS POOL IS NOT EMPTY.** `dram-datapath.md` item **H2** named this as experiment #1: r1's `advance` returns `None` the second time it is asked, so `loop_ok` — the only structural filter this machine has — could only be stated for `wtrail = 1`. Generalised to unbounded generations it (i) **reproduces r1's filter machine-for-machine at `wtrail = 1`, 3000 of 3000**, (ii) is **demonstrated saying YES at `wtrail = 2`** on a motif built to have trail 2, and (iii) admits a **non-empty** pool on the real motif. **H2's blocker is removed.** | **MEASURED** (§8) |
| **D** | ★★★ **AND THAT POOL EXISTS ONLY UNDER THE FORCED POLARITY.** Of the sampled machines admitted at `wtrail = 2`, **6 of 6 are `swap = 1`** (round 5 D's polarity) and **0 are `swap = 0`** (r1's, falsified); at `wtrail = 1` the split is 4 / 20 the other way. The descriptors' trail and round 5's direction select each other. | **MEASURED**, sample-based (§8) |
| **D2** | ★★★ **AND `C1` WAS ITSELF A `wtrail = 1` ASSUMPTION — WHICH DISSOLVES THE `land` CONTRADICTION INSIDE `dram-datapath.md`.** r1's filter demands the multiplicand carry the **fresh** read; §6.1 of that note measures that under the forced polarity this can happen **only at `land = −1`**, while its own §§2–4 say the port hands the multiplier a sample fetched in an **earlier** repetition. Both are `rlag = 0` and `rlag > 0` of one filter. Enumerated: at `rlag = 0` every `wtrail = 2` survivor is at `land = −1` (§6.1 reproduced by an independent route); **at `rlag = 1` the `wtrail = 2` pool contains `land ∈ {0,1,2,7,8}` as well** — a pipelined machine wants `land ≥ 1`, exactly as the flush-read argument does. | **MEASURED** (§8) |
| **E** | ★★★ **THE PUBLISHED SEARCH WINDOW `w5..w9` CONTAINS NO DELAY LOOP AT ALL UNDER THE FORCED POLARITY — AND THAT IS A SECOND DEFECT, NOT THE SAME ONE.** Its only WRITE is descriptor cell 1, the **LIMIT** — the *prime write*, at an address no read of the algorithm can reach — and its READ belongs to a line whose base is written at `w46`, **37 words outside the window**. Round 6 attributed the `108 → 0` entirely to the one-cursor `Line`; the window itself was chosen when `0x60` was believed to be the READ. | **PROVEN BY CONSTRUCTION** from the descriptor bank + round 5 D (§9) |
| **F** | ★★ **`land ∈ [1,4]` IS NOT MERELY OPEN — IT IS DEGENERATE.** Tagging every read and recording which tag stands at every `SRC 0x0B` word: `land = 1, 2, 3, 4` give **identical data to every consumer in 91 of 91** algorithms that ship descriptor cells. Under `port = latency` **no word in the ROM can see the difference**. Rule 4 on an OPEN parameter. | **MEASURED** (§7) |
| **G** | ★★ **THE FLUSH READ AND THE PRIME WRITE ARE THE TWO ENDS OF ONE DATUM PATH, AND IT HAS NOW BEEN EXECUTED.** Under `port = push_read` the CEILING read leaves its datum in flight across the frame boundary; the next frame's first read commits it; and the only word that stores it is the **PRIME WRITE**, whose address nothing can read. `dram-datapath.md` A inferred the pair from positions; here the datum walks from one to the other. | **CONSISTENT** — it depends on the port model, which is OPEN (§9) |
| **H** | ★★ **THE PORT MODEL IS A REAL FORK AND THE ROM SEPARATES IT.** `push_read` (only a READ pushes the previous datum — the reading that *explains* why the flush is a read) and `push_any` disagree on SINGLE DELAY: under `push_read` `w28` stores line L0's **own** read (a self-feedback delay line, which is what the effect is); under `push_any` it stores the **other** line's datum and the register standing at `w46` is the discarded ceiling word. **Conditional**: if `SRC 0x00` is the read register, `push_any` writes flush garbage into a real line and is refuted. | **OPEN**, with a named discriminator (§7, §9) |
| **I** | ★★ **A PUBLISHED NUMBER THAT DOES NOT REPRODUCE.** `r1_allpass_solve.py singledelay` prints **5635**, not the **5145** quoted in `action-field.md` §8, `blocking-read.md` and `acc-adder.md` (whose prediction A-2 records *"the old search reproduces its published 5145 — HIT, exactly"*). Cause, found by diffing the tool against the commit that made the claim: `exec_rep` used to select the `s1op` relaxation **by position**, so the reverb motif's slot-1 relaxation leaked into SINGLE DELAY, whose slot 1 has `accop = 1` and was executed with `accop = 2`. The fix is in the source **with a comment**; the three notes were never re-run. The count is stale; the forcing it supported (`land = −1`, now 5635/5635) survives the fix. | **FALSIFIED as published**; re-measured (§10) |
| **J** | ★★ **THE WHOLE-PROGRAM ARM CANNOT PASS YET, AND ITS ZEROS ARE THEREFORE NOT REPORTED AS RESULTS.** Lifting the search from the 5-word window to all 48 words of SINGLE DELAY: **0 of 200 machines even reach the end of the program.** `w1 = 00002021CD` carries `ACTION 0x0D`, outside the ALU model's decoded set, so it refuses — as method rule 6 says it must. The control is printed **in front of** the six zeros. **The blocker has moved from the memory model to the ALU decode.** | **MEASURED** (§10) |
| **K** | ★ **NOTHING IS APPLIED.** 0 of the 42 delay-DRAM frame slots become executable. No device source, no disassembler, no MAME build is touched; `dsp/verify.py` reports BYTE-MATCH OK. | — |

**FALSIFIED / WITHDRAWN elsewhere, restated here so nobody re-quotes them:** the
`5145/5145` blocking-read forcing (round 6 F, and §10 adds that the *number*
does not reproduce either); `ACTION 0x19 = tempA ← bus` at `72/72` and `108/108`
(forcing withdrawn, semantic not refuted); `SRC 0x00 = mem[ptr]` at `72/72`;
`3873` as MEASURED; `land ∈ [1,4]` as FORCED.

---

## 1. What was wrong, quoted from the shipped tools

`r1_allpass_solve.py` lines 332–347, `action00_discriminate.py` 773–787 and
`acc_adjudicate.py` 394–408 all carry the same object:

```python
class Line(object):
    def read(self):      return self.buf[self.i]     # <- the SAME cell
    def write(self, v):  self.buf[self.i] = v        # <- the SAME cell
    def advance(self):   self.i = (self.i + 1) % self.n
```

Three consequences, each of which cost a published result:

1. **The delay is the buffer length the experimenter chose.** Nothing in it comes
   from the descriptor bank, so a search cannot be wrong about a delay — it can
   only be wrong about everything else.
2. **Read-before-write is imposed silently.** Put the write first and the read
   returns the value written in that very frame: delay 0. That is exactly what
   happens when the polarity is corrected, and it is why round 6's re-run went
   to 0.
3. **A one-address line delays by the whole region.** §4 prints it: with
   `read cell == write cell` and a 64-cell region the observed delay is 64, not
   *D*. The published `Line` only worked because its region **was** *D*.

---

## 2. The API the next phase imports

```python
from delayline import (Harness, DelayDRAM, DramPort, Line, Micro,
                       lines_of, program, run_words, match, loop_ok_w,
                       ref_comb, ref_allpass_series, ref_schroeder_nested,
                       mp_comb, mp_allpass, mp_schroeder)

h  = Harness()                       # every default is labelled -- see sect. 3
h2 = h.replace(port="push_any")      # a rival is one keyword away

P    = program(9)                    # a ROM body image + its descriptor block
lns  = lines_of(9)                   # the corrected line set, WITH ITS LABELS
port, ok = run_words(P, machine, h, x, coefs_of(9, P.words))
```

* `Line` carries the descriptor bank's own label (`FORCED`, `FORCED-IN-MODEL`,
  `CONSISTENT`, `OPEN`) and a `hard` property that is **True only for FORCED**.
  The harness *reports* the label; it does **not** enforce it. A solver that
  treats a `CONSISTENT` pairing as a hard constraint is asserting `bounds.py`'s
  allocation model, and the API makes that a deliberate act.
* `run_words` uses `action00_discriminate.step` **unchanged** as the ALU, so any
  difference between an old number and a new one is attributable to the memory
  and to nothing else.
* `Micro` is the harness's own executor: the references in §5 are expressed in it
  and run through the same `DelayDRAM` and the same `DramPort` as the ROM.

---

## 3. The parameter enumeration, with the label of every default

`python3 dsp/tools/delayline.py enum`

| parameter | options | default | what sets it |
|---|---|---|---|
| `polarity` | forced, published | **forced** | **FORCED** — round 5 D |
| `port` | push_read, push_any, latency, blocking | **push_read** | **OPEN** — the mechanism that *explains* the flush read |
| `land` | 1, 2, 3, 4 | 2 | **OPEN**, and **DEGENERATE** on this corpus (§7) |
| `grot` | desc, asc, static | **desc** | **OPEN** — the rotation register is undecoded; only `desc` makes read−write the delay |
| `gstep` | 1 | 1 | CONSISTENT — one sample per frame |
| `g0` | any | 0 | **DEGENERATE**, proven §7 |
| `gwrap` | unit, global | unit | CONSISTENT — the region test |
| `cursor` | single, split | **single** | **FORCED** — M5 refuted (`dram-unit-cursor.md`); `split` kept as a scoreable rival |
| `delta` | 0, ±1 | **0** | **FORCED** — round 5 B |
| `wdata` | bus, acc | bus | **OPEN** — `dram-datapath.md` item J |
| `carry_dr` | True, False | True | **OPEN** |

**9216 harnesses in the model space alone.** The published SINGLE DELAY search
ran 5832 machines at **one** of them, unnamed.

---

## 4. IT MUST DELAY — printed, not asserted

`python3 dsp/tools/delayline.py delay`

D = 7, region 64, 24 frames. The value written at frame *n* is 1000 + *n*:

```
     frame  wrote   read     expected wrote[n-7]
       6     1006       0           0   ok
       7     1007    1000        1000   ok
       8     1008    1001        1001   ok
     OBSERVED DELAY d such that read[n] == wrote[n-d] for all n: [7]
```

**ORDER INDEPENDENCE**, the freedom a one-cursor line does not have:

```
     write BEFORE read in program order : observed delay [7]
     output bit-identical to read-first : True
```

**And four controls, each run long enough to show the delay it would have to
have** (rule 1 — the first version of this table ran 24 frames against a delay of
57 and reported an empty set, which is not a rejection):

| control | frames / region | observed delay |
|---|---|---|
| `grot=static`, two addresses | 24 / 64 | **nothing ever returns** — a frozen G is not a short delay, it is no line |
| `grot=static`, one address, read first | 24 / 64 | **1** — the previous frame's write, whatever *D* is |
| `grot=static`, one address, write first | 24 / 64 | **0** — ★ **the old harness's failure mode, reproduced inside the new one** |
| `grot=asc` | 104 / 64 | **57** = region − *D*. Both directions delay; only one delays by the descriptor's difference |
| read cell == write cell | 104 / 64 | **64** = the whole region |
| read cell == write cell, region = *D* | 24 / 7 | **7** — ★ **the published `Line(D)`, exactly** |

---

## 5. IT MUST SAY YES — and it must separate

`python3 dsp/tools/delayline.py refs`

Three structures, hand-built **from the mathematics** (`ref_comb`,
`ref_allpass_series`, `ref_schroeder_nested`) and independently expressed as
micro-programs that carry the **prime write** as their first write and the
**flush read** as their last read, exactly as all 83 aligned ROM programs do:

```
   plain comb g=0.60 D=13              ACCEPTED   scale +1.0000  relerr 0.00e+00
        test signal 160 samples, longest delay 13  =>  12.3 recirculations
   all-pass chain g=(0.7,0.5,0.35) D=(11,17,23)  ACCEPTED  relerr 0.00e+00
        test signal 160 samples, longest delay 23  =>  7.0 recirculations
   Schroeder nested D=29/7             ACCEPTED   scale +1.0000  relerr 0.00e+00
        test signal 160 samples, longest delay 29  =>  5.5 recirculations
```

**RULE 7 — the same matcher, scored on every pair:**

```
                           plain       all-pass    Schroeder
        plain comb         YES         no          no
        all-pass chain     no          YES         no
        Schroeder nested   no          no          YES
        RIVAL: pass-through no         no          no
     diagonal 3 of 3 ; OFF-diagonal 0 of 6 ; instruction-blind rival 0 of 3
```

The pass-through rival is the one that **ignores the instruction entirely**, and
it is rejected by all three targets.

---

## 6. IT MUST SAY NO

`python3 dsp/tools/delayline.py twins`

**POPULATION: 14 twins over 3 references. ACCEPTED: 0.**

wrong write cell · no flush read · sign flipped · feedback removed · rotation
frozen · rotation reversed — for the comb, the all-pass chain and the Schroeder
nest. Every one is rejected.

★ **And a rejection that also identifies is worth more than one that only says
no.** Matched against a family of combs `D−2 … D+3`:

```
     NO FLUSH READ                      -> ['comb D=14']
     WRITE MOVED IN FRONT OF THE READ   -> ['comb D=14']
     WRONG WRITE CELL (base+1)          -> ['comb D=12']
```

The first two are the **same** defect and the harness says so: both make the
stored datum one frame stale. The third moves the **address**. ★ **The old
harness could not distinguish these three at all** — with one cell the delay is
the buffer length and nothing else.

---

## 7. RULE 4 — run before anything is scored

`python3 dsp/tools/delayline.py degen`

```
     g0 = 12345 (a rigid shift of every address)      DEGENERATE (bit-identical)
     gwrap = global                                   DEGENERATE
     port = push_any                                  DEGENERATE   <- on the comb only
     port = latency, land=1                           separates
     port = latency, land=2                           DEGENERATE
     port = blocking                                  separates
     carry_dr = False                                 DEGENERATE
     grot = asc                                       separates
     grot = static                                    separates
```

★ **`push_read` vs `push_any` is degenerate on the micro-program and separates
on the ROM**, which is exactly why the check is run on both:

```
     push_read  the write at w28 stores the datum of : cell0@15435   (line L0's OWN read)
     push_any   the write at w28 stores the datum of : cell2@31370   (the OTHER line)
```

★★ **AND `land ∈ [1,4]` IS DEGENERATE ON THE WHOLE CORPUS.** Not "the gap is big
enough" — every read is tagged with its own index and the tag standing at every
`SRC 0x0B` word is recorded, for each land:

```
     algorithms in which land = 1,2,3,4 give DIFFERENT data to
     at least one SRC 0x0B word : 0 of 91
     READ -> first later SRC 0x0B word, over 350 reads: min 4, mode 4
```

⇒ under `port = latency` **no word in the ROM can see which member of the
interval is right**. Round 6 §6 left `land` OPEN; this says something stronger
and cheaper — **do not spend a search dimension on it.**

---

## 8. `loop_ok` FOR A GENERAL `wtrail` — the named experiment #1

`python3 dsp/tools/delayline.py loopok`

r1's `advance` maps `N → N'` and `Q → Q'` and **returns `None` if asked twice**:
there are exactly two generations of fresh atoms in its algebra. The fix is the
algebra, not the ALU. A form here is a dict over `("R", k)` (register *k*'s entry
value), `("N", g)` and `("Q", g)` for unbounded *g*, and `gadvance` can be applied
any number of times. **The ALU model is r1's own `exec_rep`, imported and
monkey-patched only at `_sym_unit`, so the two cannot drift.**

**STEP 0 — THE POSITIVE CONTROL, BEFORE ANY NUMBER.** A synthetic 8-slot motif is
built *from the mathematics of the pipeline* to park its product in `tempA`, copy
`tA → tB` one repetition later, and write `tB` one repetition after that:

```
     synthetic wtrail-2 motif, filter at wtrail = 0 : REJECTED
     synthetic wtrail-2 motif, filter at wtrail = 1 : ['acc_before', 'acc_after']
     synthetic wtrail-2 motif, filter at wtrail = 2 : ['bus']        <== the built path
     synthetic wtrail-2 motif, filter at wtrail = 3 : REJECTED
```

**STEP 1 — EQUIVALENCE AT `wtrail = 1`:** `agree 3000 of 3000, disagree 0`, of
which **24 are non-empty** — so the agreement is not the agreement of two empty
sets.

**STEP 2 — THE ARM THAT COULD NOT BE STATED BEFORE:**

```
     machines admitted, of 3000 sampled:
       wtrail = 0 :     0   (swap=0    0 / swap=1    0)
       wtrail = 1 :    24   (swap=0   20 / swap=1    4)   <== r1's assumption
       wtrail = 2 :     6   (swap=0    0 / swap=1    6)   <== the descriptors' value
       wtrail = 3 :     1   (swap=0    0 / swap=1    1)
```

**STEP 2b — ★★ AND `C1` WAS ITSELF A `wtrail = 1` ASSUMPTION (rule 2).** The
multiply need not consume the *fresh* read: `rlag` is how many repetitions after
the read the multiply happens, and everything is then expressed in the frame of
the repetition that does the read (C1 on `advance^rlag(MULT)`, C2 on
`advance^(rlag+w)(W)` at `("Q", rlag)`, C3 at `("N", 0)`).

```
       admitted, of 3000 sampled      wtrail=0  wtrail=1  wtrail=2  wtrail=3
       rlag = 0                           0        24         6         1
       rlag = 1                           0        98        44         5
       rlag = 2                           0        21         2         0
     the wtrail = 2 survivors, by (rlag, land):
       (0,-1) 6 | (1,-1) 3 (1,0) 14 (1,1) 8 (1,2) 8 (1,7) 5 (1,8) 6 | (2,1) 1 (2,7) 1
```

★★ **At `rlag = 0` every survivor is at `land = −1`** — `dram-datapath.md` §6.1's
measurement, reached by a route that never used its Stage A. **At `rlag = 1` the
pool is five times larger and it is no longer confined to the blocking read.**
The contradiction that note leaves standing between its §3 (`land ≥ 1`, from the
flush read) and its §6.1 (`land = −1`, from the ALU) is **a parameter both of
them held fixed.** Which value is right is the next phase's question; the filter
can now ask it.

**STEP 3 — exhaustively over the 42875 ACTION triples at each of the 16
configurations that survive at `wtrail = 1`: 107354 admitted at `wtrail = 1`,
13926 at `wtrail = 2`.**

**STEP 4 (`loopok --full`) — THE WHOLE `wtrail = 2` POOL UNDER THE FORCED
POLARITY, EXHAUSTIVELY: 12 348 000 machines enumerated, 51 877 admitted.**

```
       src00=DR   land=-1  order=1  wsrc=M                       x8418
       src00=DR   land=-1  order=0  wsrc=M                       x7689
       src00=zero land=-1  order=0  wsrc=M                       x3575
       src00=M    land=-1  order=0  wsrc=acc_before,acc_after,M  x3325
       ... (top 20 rows; every one at land = -1, i.e. rlag = 0)
```

The pool the next phase needs exists, and it is enumerated rather than sampled.

★★ **AND METHOD RULE 10 BIT ME FIRST, IN THE PASS WHOSE SUBJECT IS RULE 10.** The
first version of this section held `swap` at its default 0 — r1's `MSLOTS`
hardcodes `lo12 0x2D4 = READ`, the polarity round 5 reversed — and printed **0 at
`wtrail = 2`**. That zero was an artefact of a parameter *I* had held fixed. It is
printed here rather than deleted.

---

## 9. The ROM programs, executed

`python3 dsp/tools/delayline.py ledger`

```
   algo 9  SINGLE DELAY   unit 0   48 words   6 cells   6 DRAM words
   slot word  36 bits     dir   addr    role      label            line
     0  w0   088013000B READ   15435  READ_END  FORCED           reads L0 (D=15435)
     1  w5   08801602D9 WRITE  31871  LIMIT     FORCED-IN-MODEL
     2  w9   088012064B READ   31370  READ_END  FORCED           reads L1 (D=15435)
     3  w28  08801602D9 WRITE      0  LINE_BASE FORCED           base of L0
     4  w32  088012064B READ   32768  CEILING   FORCED
     5  w46  0880160000 WRITE  15935  LINE_BASE CONSISTENT       base of L1
```

**The flush read and the prime write, executed** (steady state, not the cold
frame):

```
     port=push_read : w5 stores cell4@32768 [SRC 0B]   w28 stores cell0@15435 [SRC 0B]
                      w46 stores cell2@31370 [SRC 00]
     port=push_any  : w5 stores cell0@15435 [SRC 0B]   w28 stores cell2@31370 [SRC 0B]
                      w46 stores cell4@32768 [SRC 00]
```

Under `push_read` the **prime write stores the previous frame's flush datum**, at
the one address in the algorithm no read can reach. `dram-datapath.md` A derived
the two dummies from their *positions*; this is the first time the datum has been
walked from one to the other. **CONSISTENT** — it depends on the port model.

**And the real delay, unscaled, checked arithmetically:**

```
     L0  write@frame 0 -> phys 0     ; read@frame 15435 -> phys 0      SAME CELL
     L1  write@frame 0 -> phys 15935 ; read@frame 15435 -> phys 15935  SAME CELL
```

350.0 ms, from the descriptor's own addresses, with no buffer length anywhere.

---

## 10. The published search, re-expressed — and the reproduction

`python3 dsp/tools/delayline.py migrate` · `... repro`

### 10.1 ★★★ The window contains no loop

```
     w5   08801602D9  polarity=forced    -> WRITE cell 1 = 31871   LIMIT
     w5   08801602D9  polarity=published -> READ  cell 1 = 31871   LIMIT
     w9   088012064B  polarity=forced    -> READ  cell 2 = 31370   READ_END  reads L1
     w9   088012064B  polarity=published -> WRITE cell 2 = 31370   READ_END
```

Under the FORCED polarity the searched window's only WRITE is the **prime write**
and its READ belongs to a line whose base is `w46`. **A search over `w5..w9`
cannot find a delay loop there because there is none.** Round 6 §3.5 attributed
the `108 → 0` to the one-cursor `Line`; that is true and it is not the whole
story — **the window was chosen under the old polarity too.** Two defects, and
the second one is not fixed by a better memory model: it is fixed by searching
the whole program.

### 10.2 The migration control — the old model inside the new harness

```
     the OLD path, unmodified                       : 108 of 5832
     the NEW harness, one-address configuration     : 108 of 5832
```

★ **The new harness contains the old model exactly.** Every published number
stays reproducible, which is what makes this round's retractions honest.

### 10.3 The two-address arm, with the control that says it cannot pass

```
     machines whose run COMPLETES the 48-word program : 0 of 200
     the SAME machine, two RNG seeds -> different scored sequence: 0 of 0
     words at which action00_discriminate.step REFUSES: [1]
       w1   00002021CD  act=0D  f31=0  <- ACTION outside the decoded set
   ---- AND THE SAME 5832 MACHINES ON THE TWO-ADDRESS MEMORY, WHOLE PROGRAM
       polarity=forced    port=push_read  :    0 of 5832
       polarity=forced    port=push_any   :    0 of 5832
       polarity=forced    port=blocking   :    0 of 5832
       polarity=published port=push_read  :    0 of 5832
       polarity=published port=push_any   :    0 of 5832
       polarity=published port=blocking   :    0 of 5832
```

**These six zeros are NOT results and are not offered as any.** The control is
printed **in front of** them: **not one machine of the 5832 reaches the end of the
program.** `w1 = 00002021CD` carries `ACTION 0x0D`, which is outside the decoded
set, so the ALU model refuses it — exactly as method rule 6 says it must. The
five-word window could be scored because its five words are decoded; the whole
program cannot. **The blocker has moved from the memory model to the ALU
decode**, and that is the finding.

### 10.4 ★★ A published number that does not reproduce

`adjudicate6.sd_search` reproduces **108 / 0 / 0** exactly. But:

```
   action-field.md sect. 8, blocking-read.md : "5145"
   acc-adder.md prediction A-2               : "reproduces its published 5145 -- HIT, exactly"
   r1_allpass_solve.py singledelay, today    :  5635        (13 min)
                                                land = -1 FORCED, 5635/5635
```

**Cause**, by diffing the tool against the commit that made the claim:

```python
   then:  op = m[S1OP] if s == 1 else sl["accop"]
   now:   op = (m[S1OP] if (s == 1 and MSLOTS is MOTIF_MSLOTS) else sl["accop"])
```

The reverb motif's slot-1 relaxation was selected **by position** and leaked into
SINGLE DELAY, whose slot 1 is `202.A.B8.655` with `accop = 1` and was executed
with `accop = 2`. The fix ships **with a comment explaining it**; the three notes
that quote 5145 were never re-run. The **count** is stale; the **forcing** it
supported survives the fix. Both halves are printed because only one of them is
comfortable.

---

## 11. What this harness CANNOT express

`python3 dsp/tools/delayline.py cannot`. This list bounds every negative result
the next phase can produce.

1. **The host's parameter writes.** Descriptor cells are read as ROM constants;
   a modulated line (CHORUS, FLANGER, every LFO-swept effect) is frozen at its
   canned value.
2. **The rotation register G is a model, not a decode.** No word of the ROM has
   been decoded as writing it. If G is not a per-frame counter, every delay
   changes.
3. **The 50 UNKNOWN cells and the 4 C-format traps.** Lines built on them do not
   exist here — ROOM REVERB 1's four `C40180000` cells are exactly that case.
4. **One unit at a time.** The inter-unit wrap `dram-unit-cursor.md` locates is
   not modelled.
5. **No arbitration, no refresh, no bandwidth limit.** Every port slot succeeds.
6. **The ALU is `action00_discriminate.step`** — wide, but 22 of SINGLE DELAY's
   48 words are undecoded and are driven by `unknown()`.
7. **The frame is the sample** (`gstep = 1`).
8. **Floats in the delay RAM.** The chip's cells are ≤ 24 bits and may saturate;
   a loop stable in floats may not be stable in fixed point.
9. **Multi-tap pairings are `bounds.py`'s model.** The harness reports the label;
   it does not enforce it. 307 of 324 lines are CONSISTENT, not FORCED.

---

## 12. PREDICT-THEN-CHECK — hits and misses

| # | verdict | prediction → what happened |
|---|---|---|
| **P1** | **HIT** | the new memory would reproduce the published 108 in a one-address configuration → **108 of 5832**, exactly |
| **P2** | **HIT** | every deliberately-wrong twin would be rejected → **0 of 14 accepted** |
| **P3** | **MISS** | moving the write in front of the read would be **accepted**, because with two addresses the order does not change the delay → **rejected**. The order does not change the *address*, but it does change the *datum*: the machine becomes a comb of `D+1`, and the harness identifies it as exactly that. Order-independence is a property of the MEMORY (§4), not of a program |
| **P4** | **HIT, after my own rule-10 failure** | `loop_ok_w` would admit a non-empty pool at `wtrail = 2` → first measurement **0**, because I had held `swap` at r1's falsified default; enumerated, **6 of 3000** and 13926 exhaustively. Printed, not deleted |
| **P5** | **MISS** | `land ∈ [1,4]` would separate on at least a few algorithms → **0 of 91**. It is degenerate corpus-wide |
| **P6** | **MISS** | the published `5145` would reproduce on the old code path → **5635** |
| **P7** | **MISS** | `push_read` and `push_any` would separate on the comb micro-program → **degenerate** there; they separate on the ROM program, which is why the check was run on both |
| **P8** | **MISS** | the `108 → 0` was entirely the one-cursor `Line`, so re-running the same window on a two-address memory would revive it → **the window contains no loop at all** under the forced polarity. A second, independent defect |
| **P9** | **HIT, for the wrong reason** | the whole-program arm would not close anything → 0. I expected the noise of 8 undecoded words to swamp it; in fact **not one machine completes the program at all**, because `ACTION 0x0D` at `w1` traps. Weaker instrument than I predicted, and printed |
| **P10** | **HIT** | `g0` would be degenerate → bit-identical output |
| **P11** | **MISS** | `rlag` would change the `wtrail = 2` pool only marginally → it **quadruples** it (6 → 44 of 3000) and, more importantly, **moves it off `land = −1`**, which is the one place `dram-datapath.md` contradicts itself |
| **P12** | HIT, weakly | `gwrap` would be degenerate → yes on the comb; **not** demonstrated to be degenerate on a program whose ceiling read wraps into a live cell |

**MISSES: 6 of 12**, five of them about my own instruments.

---

## 13. What the other notes must change

| source | claim | now |
|---|---|---|
| `dram-datapath.md` **H2** | *"a zero at `wtrail = 2` is an absence of a search"*; experiment #1 = extend `advance` | ★ **DONE.** The filter exists, is validated both ways, and its `wtrail = 2` pool is non-empty **only under the forced polarity**: 51 877 of 12 348 000 enumerated exhaustively |
| `dram-datapath.md` §3 vs §6.1 | `land ≥ 1` (flush read) vs `land = −1` (ALU, forced polarity) | ★ **THE CONTRADICTION IS A HELD-FIXED PARAMETER.** Both hold `rlag = 0`. At `rlag = 1` the `wtrail = 2` pool contains `land ∈ {0,1,2,7,8}` |
| `adjudication-round6.md` §3.5 | the `108 → 0` is a harness artefact of the one-cursor `Line` | ★ **CORRECT BUT INCOMPLETE.** The searched *window* is a second artefact: under the forced polarity it contains the prime write and no loop |
| `adjudication-round6.md` §6 | `land ∈ [1,4]` is OPEN | ★ **STRENGTHENED to DEGENERATE** — 0 of 91 algorithms can see the difference |
| `action-field.md` §8, `blocking-read.md`, `acc-adder.md` A-2 | SINGLE DELAY's `5145` | ★ **DOES NOT REPRODUCE — it is 5635.** Cause attributed to the `s1op` positional leak, which was fixed without re-running the notes |
| `dram-datapath.md` **A** | the CEILING is the flush read, the LIMIT the prime write | ★ **EXECUTED, not only positioned** — under `push_read` the prime write is the flush datum's only consumer |
| `r1-allpass-motif.md` §4.2 | *"the search assumes the minimal offset of 1"* | ★ the assumption is now a **parameter**, and both values have pools |
| `dram-bounds.md` labels | FORCED / FORCED-IN-MODEL / CONSISTENT / OPEN | ★ **carried into the API**; `Line.hard` is True only for FORCED |

---

## 14. Safety

`dsp/verify.py` reports **BYTE-MATCH OK**. Neither disassembler mirror is touched.
No `.dsm` listing, no device source, no MAME build, no `.cpp`. **0 of the 42
delay-DRAM frame slots become executable, and nothing is applied.**
