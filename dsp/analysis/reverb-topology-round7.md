# THE REVERB TOPOLOGY — the ladder is not the loop, and the program says so in its own opcodes

NEC **uPD6383GF-3BA** (Technics SX-KN5000, IC311). Round 7, 2026-07-27.
No hardware. Static analysis of the Sub CPU ROM, the canned parameter streams,
the 38 body images, the descriptor bank and the published tools only.

Labels: **MEASURED** / **PROVEN BY CONSTRUCTION** / **FORCED** / **CONSISTENT** /
**INFERRED** / **FALSIFIED** / **OPEN**.

Tool: [`../tools/topology.py`](../tools/topology.py). **Every number below comes
out of it.**

```
python3 dsp/tools/topology.py enum      #  1 the enumeration + what is held fixed
python3 dsp/tools/topology.py blocks    #  2 ★★★ THE PROGRAM IS  B A^5 B A^4 B C C
python3 dsp/tools/topology.py memory    #  3 ★★★ RULE 4 BEFORE ANY SCORE
python3 dsp/tools/topology.py refs      #  4 the candidate set + rule-7 matrix
python3 dsp/tools/topology.py pipeline  #  5 ★★★ TARGET B, decided in three parts
python3 dsp/tools/topology.py controls  #  6 ★★★ IT MUST SAY YES, AND NO
python3 dsp/tools/topology.py search    #  7 ★★★ TARGET A, the topology search
python3 dsp/tools/topology.py wdata     #  8 ★★  TARGET D, the write-data source
python3 dsp/tools/topology.py predict   #  9 PREDICT-THEN-CHECK, hits AND misses
python3 dsp/tools/topology.py all       #    everything  (~25 min)

python3 dsp/verify.py                   #    BYTE-MATCH OK
```

The exhaustive pools are cached under `$TOPOLOGY_CACHE`
(default `/tmp/kn5000-topology-pools`); the first `search` run rebuilds them in
about **10 minutes** and every later run is instant. Deleting the cache
directory reproduces them from scratch.

**Nothing is applied.** No device source, no disassembler, no `.dsm` listing,
no MAME build. **0 of the 42 delay-DRAM frame slots become executable** — §10
says exactly which constraint stops each of them.

---

## 0. Result in one page

| # | statement | label |
|---|---|---|
| **A** | ★★★ **THE REVERB PROGRAM IS NOT A LADDER OF ONE MOTIF. IT IS `B A A A A A B A A A A B C C`.** Three word-signatures, matched with `addr8` wildcarded exactly as r1's `core_at` matches its motif: **BLOCK A** (8 words, ONE class-A multiply) ×9, **BLOCK B** (10 words, **FOUR** class-A multiplies) ×2, **BLOCK C** (9 words, two C-format traps each) ×2 — 110 of the 133 words. Every block owns exactly one delay-DRAM write and one read, and **a BLOCK B sits BETWEEN the two BLOCK A runs**. The nine BLOCK A repetitions are **5 + 4**, not nine. | **MEASURED** (§2) |
| **B** | ★★★ **AND THE PROLOGUE IS BLOCK B ROTATED BY SIX WITH ITS TWO CARRY-COPIES DISABLED — the literal signature of a software-pipelined loop.** `w007..w017` matches `B[6..9]+B[0..6]` in **9 of 11** positions; both mismatches replace a `***.2.**.407` word — ACTION `0x07`, the **anchored** `M ← bus` — with an ACTION `0x00` word. A pipeline's prologue is exactly the iteration whose carry-copies have nothing to carry. `dram-datapath.md` item I called the motif *"a software-pipelined loop"* from the descriptor positions; the **opcodes** say it. | **PROVEN BY CONSTRUCTION** (§2) |
| **C** | ★★★ **AND `dram-datapath.md` §4 D IS WRONG IN ITS DETAIL.** It says *"the NINE motif repetitions read lines 2..10 and write lines 0..8"*. The ledger says they read `{L2..L6, L8..L11}` and write `{L0..L4, L6..L9}`: **L7's read and L5's write belong to the interlude BLOCK B**, and L10's write and L12's read to the tail one. A search that runs nine contiguous BLOCK A repetitions is searching a program the chip does not execute. | **MEASURED** (§2) |
| **D** | ★★★ **RULE 4, AND IT DEFLATES THIS ROUND'S OWN PREMISE: ON THE REVERB LADDER THE TWO-ADDRESS MEMORY IS DEGENERATE WITH r1's ONE-CELL `Line`.** 200 machines per cell, 8 cells: **0 disagreements everywhere except `(swap = 1, wtrail = 0)`, where 48 of 200 disagree.** Mechanism: under the FORCED polarity slot 0 is the WRITE and slot 4 the READ, so only a trail of ZERO puts the write before the read of the *same* line. **⇒ round 6's `the line could not delay' voids `SINGLE DELAY', not the ladder**, and `dram-datapath.md` §6.2's zero was never a memory artefact. | **MEASURED** (§3) |
| **E** | ★★★ **THE `wtrail = 2` ZERO IS GONE. `swap = 1, wtrail = 2, rlag = 0`: 102 of 400 sampled machines match, out of an EXHAUSTIVE pool of 82 632.** `dram-datapath.md` §6.2 printed **0** there and said in its own words that the zero was *an absence of a search*. It was. The families that match are the **pipe-comb** family (335 hits) and the **series comb cascade** (208); the first-order all-pass, the parallel comb bank, Moorer, the nested all-pass and the lattice are at **0** — **and they stay at 0 in the topology-NEUTRAL pool too** (§7.3), which is what makes those zeros rejections rather than an absence of a search. | **MEASURED** (§7.2, §7.3) |
| **F** | ★★★ **BUT EVERY SURVIVOR SITS AT `land = −1`, THE BLOCKING READ — AND AT `rlag = 1` THE COUNT IS ZERO, ALL THREE DRAIN CONVENTIONS.** The exhaustive `wtrail = 2, rlag = 0` pool is **82 632 of 82 632 at `land = −1`**; the `rlag = 1` pool spreads over every land and matches **0 of 400**. So the topology survivors and `dram-datapath.md` §3's flush-read bound (`land ≥ 1`) are still pointing in opposite directions, now with the trail and the read-lag both enumerated. **The contradiction is not dissolved; it is sharpened.** | **MEASURED** (§7.2) |
| **G** | ★★★ **AND THE STRADDLE IS DECISIVE: WITH THE HONEST BOUNDARY CONVENTION THE COUNT IS ZERO.** `drain = open` — the lines whose write falls outside the 5-repetition window are simply never written, which is what §2's ledger says happens — gives **0 of 400** where r1's drain gives 102. Only **3 of the 5** lines a BLOCK A run touches have both ends inside it. **Every non-zero in this round depends on closing the window with repetitions the ROM does not contain in that form.** | **MEASURED** (§5, §7.2) |
| **H** | ★★ **TARGET B, DECIDED. `no cascade reference can ever match a software-pipelined loop' IS FALSE AS STATED, AND TRUE IN A DIFFERENT FORM.** (i) A pipelined ladder that carries each stage value in a *private* register for `w` repetitions is **bit-identical to the cascade, `max|diff| = 0`, for `w = 0,1,2,3` and both topologies** — the trail is invisible to the transfer function, because a two-address line is order-independent inside a frame. (ii) What is *not* covered is a **shared** carry: **0 of the 40 members of the `wtrail = 2` pipe family are in the published (`w = 1`) reference set.** (iii) The real obstruction is (G): the window is not the loop. | **PROVEN BY CONSTRUCTION** + **MEASURED** (§5) |
| **I** | ★★ **A PUBLISHED ASSERTION THAT DOES NOT HOLD: THE LATTICE IS NOT THE ALL-PASS.** `r1_allpass_solve.topology_refs`'s docstring excludes a Gray-Markel lattice from the reference set because it *"realises the same all-pass transfer function ... so it is the same test as `allpass_ref`"*. With **unit** delays that is a theorem; with the ladder's five distinct delays the two references project onto each other with residue **9.70e-01**. The lattice was excluded from every published search on a false premise. It is in the set here, and it matches **0**. | **FALSIFIED** (§4) |
| **J** | ★★★ **TARGET D MOVES: `wdata = bus' IS EXCLUDED BY THE LOOP FILTER, 0 OF 1 543 857 ROWS OVER ALL TWELVE `(wtrail, rlag)` POOLS**, exhaustively over 12 348 000 machines — **and the filter demonstrably CAN say `bus`** (delay-harness's synthetic trail-2 motif returns `['bus']`, re-run here). Mechanism: the motif's write word `880.1.**.2D4` carries `SRC 0x0B`, so under `wdata = bus` it would store the read-data register — an unmultiplied copy of another line's output, which is condition C3. **This collides head-on with `dram-datapath.md` §2.3**, whose `SRC 0x0B` argument is about the **PRIME WRITE**, a different word class. Item J's *"no route separates them"* is no longer true. | **MEASURED**, **CONDITIONAL** on the single-loop hypothesis (§8) |
| **K** | ★★ **THE POSITIVE CONTROLS BOTH REPRODUCE.** `swap = 0, wtrail = 1` (the published cell) → **78 of 400 machines match, 433 hits, pipe-comb family dominant**, as `dram-datapath.md` §6.2 reports; `swap = 1, wtrail = 1` → **46 of 400, 357 hits, series comb cascade EXCLUSIVELY**, the same exclusivity that note reports at 445. And the `(swap = 1, wtrail = 1, rlag = 0)` pool is **68 400** — **the exact number `dram-datapath.md` §6.2 prints**, reached from a differently-shaped enumeration. | **MEASURED** (§7.1) |
| **L** | ★ **NOTHING IS APPLIED.** 0 of the 42 delay-DRAM frame slots become executable; §10 names the blocking constraint for each class. `dsp/verify.py`: **BYTE-MATCH OK**. | — |

### FORCED / CONSISTENT / OPEN / FALSIFIED — the one-page table

| verdict | statement |
|---|---|
| **FORCED** (within the printed enumeration) | the block decomposition `B A^5 B A^4 B C C` and the 12 write/read pairs (§2); `wtrail = 2` in port slots (re-derived, §2); the *invisibility of the write trail* to the transfer function (§5 B-1) |
| **PROVEN BY CONSTRUCTION** | the prologue is BLOCK B rotated with its two anchored `M ← bus` carry-copies disabled (§2); a pure-carry pipelined ladder ≡ its cascade (§5) |
| **MEASURED** | memory-model degeneracy on the ladder except `(swap=1, wtrail=0)` (§3); the `wtrail = 2` survivor count 102/400 out of 82 632 (§7.2); `land = −1` on 82 632 of 82 632 at `rlag = 0` (§7.0/§8.1); `wdata = bus` at 0 of 1 543 857 (§8.1); `drain = open` at 0 (§7.2) |
| **CONSISTENT** | that the reverb is a **comb-family** structure rather than an all-pass one — pipe-comb and series comb cascade match, and first-order all-pass / nested all-pass / lattice / parallel comb bank / Moorer are at **0 in BOTH the loop-filtered and the topology-neutral pool**. Not FORCED, because every non-zero depends on the `drain` convention (§7.2 row 3) and on `land = −1` |
| **OPEN** | which topology (comb cascade vs pipe-comb vs something outside the set); the read latency `land`; the write-data source (narrowed, not closed); the drain/straddle convention; BLOCK B's ten words; the head and the tail; whether the pre-delay closes an outer 800-sample loop |
| **FALSIFIED** | *"a lattice is the same test as the all-pass"* (§4); *"the nine motif repetitions read lines 2..10 and write lines 0..8"* (§2); *"the reverb searches were voided by the one-cell `Line`"* — for the **ladder** (§3); *"no cascade reference can ever match the motif regardless of topology"* as stated (§5) |

---

## 1. The enumeration, and everything held fixed

`python3 dsp/tools/topology.py enum`

| parameter | options | what sets it |
|---|---|---|
| `swap` (polarity) | 2 | 1 = round 5 D **FORCED**; 0 = r1's, falsified, kept as the positive control |
| `wtrail` | 4 | 0..3; the descriptors FORCE 2 |
| `rlag` | 3 | 0..2; delay-harness D2 — `C1` was itself a `wtrail = 1` assumption |
| `land` | 6 | `−1` and 0..4, with **4 standing for every `land ≥ 4`** (§7.0 proves the degeneracy 3000/3000) |
| `drain` | 3 | `r1` / `cyclic` / `open` — the STRADDLE convention, §2 refutes r1's |
| `memory` | 2 | delayline's two-address DRAM / r1's one-cell `Line` |
| ACTION `0x00` / `0x19` / `0x0B` | 35 each | r1's declared EFFECTS space |
| `SRC 0x00` | 6 | zero P M acc DR tA |
| `escact`, `tbsh`, `order` | 2 each | |
| write source | 4 | bus, acc_before, acc_after, M |
| injection / extraction register | 6 each | |
| `K` | 2 | 5 (one BLOCK A run) and 9 (both runs, interlude ignored) |

**Structural sweep: 12 348 000 machines per polarity, EXHAUSTIVE** (the same
denominator `delay-harness.md` §8 STEP 4 uses). Numeric arms: 400 machines
sampled uniformly from each pool, printed beside every count.

**HELD FIXED — and therefore bounding every zero (rule 11):** the ALU is r1's
`exec_rep` unchanged; **BLOCK B's ten words are not executed**, nor BLOCK C's
nine, nor the head, nor the tail; the ladder's input is an injected register
and its output an extracted one; the frame is the sample; one unit; no
saturation; the coefficients are the canned C-RAM; `delta = 0` and
`cursor = single` are not re-enumerated.

---

## 2. ★★★ The program is `B A^5 B A^4 B C C`

`python3 dsp/tools/topology.py blocks`

**POPULATION:** ROOM REVERB 1 (algo 16), 133 words, 32 descriptor cells; the
same image serves algos 16..27 byte for byte.

```
   BLOCK A  ( 8 words)  880.1.**.2D4 104.2.**.000 000.2.**.419 012.2.**.680
                        880.1.**.655 102.A.**.64B 000.2.**.000 000.2.**.000
   BLOCK B  (10 words)  880.1.**.2DA 000.A.**.695 ***.2.**.407 212.2.**.419
                        880.1.**.64B ***.2.**.407 ***.A.**.1D5 212.A.**.415
                        202.A.**.1D5 202.2.**.407
   BLOCK C  ( 9 words)  C40.1.**.000 C40.1.**.000 ***.2.**.407 880.1.**.2D5
                        282.A.**.000 000.A.**.452 ***.A.**.1D5 202.A.**.1D5
                        202.2.**.1CD

   OCCURRENCES:  A x9  B x2  C x2       words covered: 110 of 133 (83%)
   layout: A@w019 A@w027 A@w035 A@w043 A@w051 B@w059 A@w069 A@w077 A@w085
           A@w093 B@w101 C@w111 C@w122
```

### 2.1 The twelve pairs, block by block

```
     pair  block  write@   line written             read@   line read
       0   prologue w011   PRIME/LIMIT               w015   L1(D=83)
       1     A    w019    L0(800),L12(650),L13(540)  w023   L2(D=172)
       2     A    w027    L1(D=83)                   w031   L3(D=356)
       3     A    w035    L2(D=172)                  w039   L4(D=513)
       4     A    w043    L3(D=356)                  w047   L5(D=739)
       5     A    w051    L4(D=513)                  w055   L6(D=240)
       6     B    w059    L5(D=739)                  w063   L7(D=119)
       7     A    w069    L6(D=240)                  w073   L8(D=247)
       8     A    w077    L7(D=119)                  w081   L9(D=428)
       9     A    w085    L8(D=247)                  w089   L10(D=616)
      10     A    w093    L9(D=428)                  w097   L11(D=360)
      11     B    w101    L10(D=616)                 w105   L12(D=650)
```

Pair *j* writes line *j−1* and reads line *j+1* — `wtrail = 2` in port slots,
re-derived here from the block decomposition and not quoted from
`dram-datapath.md`. **The interlude BLOCK B owns L5's write and L7's read.**
That is item **C**: no BLOCK A repetition touches them.

### 2.2 ★★ The prologue is BLOCK B rotated, with its carry-copies disabled

```
       prologue w   lo12   BLOCK B pos   lo12
       w007        1D5    B[6]          1D5    ==
       w008        415    B[7]          415    ==
       w009        1D5    B[8]          1D5    ==
       w010        407    B[9]          407    ==
       w011        2DA    B[0]          2DA    ==
       w012        695    B[1]          695    ==
       w013        000    B[2]          407    **
       w014        419    B[3]          419    ==
       w015        64B    B[4]          64B    ==
       w016        000    B[5]          407    **
       w017        1D5    B[6]          1D5    ==
       w018        000    (none)                  -- prologue ends
       matches: 9 of 11
```

**THE MEASURED FACT:** both mismatches replace a `***.2.**.407` word —
`SRC 0x10` = the accumulator, `ACTION 0x07` = one of the **five anchored
codes**, `M ← bus`, i.e. a carry-copy `M ← acc` — with a word whose SRC and
ACTION are both `0x00`. **THE INTERPRETATION**, labelled as such: a software
pipeline's prologue is the iteration whose carry-copies have nothing to carry,
and `ACTION 0x00` is undecoded, so "disabled" is a reading and not a
measurement. What is *not* a reading is that **the two anchored carry-copies of
BLOCK B are absent from the prologue and present in both of its in-loop
occurrences**, and that the other nine words line up exactly under a rotation
by six.

**This is the strongest single piece of evidence anybody has that the reverb is
a software-pipelined loop, and it is in the opcodes rather than in the
descriptor positions.**

### 2.3 The pre-delay is written by a ladder repetition and read in the head

Descriptor cell 3 (address 32768) is the base of **three** lines — L0 (800),
L12 (650), L13 (540): one buffer, three taps. Its **write is `w019`**, the
first BLOCK A repetition's own slot 0; the 800-sample tap is read at **`w000`**,
the first word of the program.

⇒ a value the ladder computes at repetition 0 of frame *n* re-enters the
program at its **head** in frame *n*+800. **Two readings, both live, and the
head's words are undecoded:**

* **(i)** the head feeds the pre-delay tap back INTO the ladder — the loop is
  closed and no open-cascade reference can express it;
* **(ii)** the head only sums the three taps into the OUTPUT (early
  reflections) — the loop is open and a cascade reference is legal.

Nothing here decides between them. It is printed because **every reference
anybody has ever scored assumes (ii) without saying so.**

---

## 3. ★★★ Rule 4 before any score — the memory model is degenerate on the ladder

`python3 dsp/tools/topology.py memory`

**POPULATION:** 200 machines per cell, drawn uniformly from r1's own space;
ladder K = 5, reduced delays `[3,5,7,11,13]`, 96 samples.

```
     swap wtrail   machines  non-zero out  DISAGREE
      0     0          200         46           0
      0     1          200         41           0
      0     2          200         41           0
      0     3          200         41           0
      1     0          200         70          48   <== SEPARATES
      1     1          200         45           0
      1     2          200         41           0
      1     3          200         41           0
```

The mechanism is not a mystery: under the FORCED polarity slot 0 is the WRITE
and slot 4 the READ, so with a trail of **zero** repetitions a line is written
at tick 8*r* and read at tick 8*r*+4 — write **before** read, the one
configuration in which a one-cell line returns the value just stored. For
`wtrail ≥ 1` line *k* is written at repetition *k*+*w* and read at repetition
*k*, so read precedes write and `Line(D)` delays by exactly *D*.

⇒ **ROUND 6's DIAGNOSIS DOES NOT TRANSFER FROM `SINGLE DELAY` TO THE LADDER.**
`dram-datapath.md` §6.2's zero at `(swap=1, wtrail=2)` was **not** a memory
artefact — it was, as that note itself said, an absence of a search. The
memory correction buys the ladder nothing, and running the control is how that
is known rather than assumed.

---

## 4. The candidate set — one set, and it separates

`python3 dsp/tools/topology.py refs`

**POPULATION: 78 references before de-duplication, 70 after** (K = 5, gains
`0.75 0.63 0.52 0.50 0.40` from C-RAM `0x98..0x9C` **MEASURED**, reduced delays
`[3,5,7,11,13]`, 160 samples → **12.3 recirculations** of the longest line).

Eight references are **removed before scoring** because they are identically
zero (`drain = zero, tap = w_last` makes `w_K = 0` every sample). r1's set
carries them; counting them inflates every denominator.

```
     allpass 1 · comb 2 · combbank 1 · lattice 1 · moorer 1
     pipe1 34 · pipe2 36 · plaincomb 1 · schroeder 1
```

**★ THE LATTICE.** `r1_allpass_solve.topology_refs`'s docstring excludes a
Gray-Markel lattice from the reference set on the ground that it *"realises the
same all-pass transfer function ... so it is the same test as `allpass_ref`"*.
Built and measured:

```
     lattice vs first-order all-pass cascade: best scale 0.051260, residue 9.696e-01
     DEGENERATE (the same test twice): False
```

With **unit** delays the assertion is a theorem; with five distinct delays it
is false. **Every published search excluded a topology on a false premise.**

**★ THE GENERALISED PIPE FAMILY REPRODUCES THE PUBLISHED ONE:**
`pipe_net_w(w=1) == r1's pipe_net_ref` in **40 of 40** members.

**RULE 7 — the same matcher, every pair of families:**

```
                    allpass comb combbank lattice moorer pipe1 pipe2 plaincomb schroeder
     allpass          YES    no     no      no      no     no    no     no        no
     comb              no   YES     no      no      no     no    no     no        no
     combbank          no    no    YES      no      no     no    no     no        no
     lattice           no    no     no     YES      no     no    no     no        no
     moorer            no    no     no      no     YES     no    no     no        no
     pipe1             no    no     no      no      no    YES    no     no        no
     pipe2             no    no     no      no      no     no   YES     no        no
     plaincomb         no    no     no      no      no     no    no    YES        no
     schroeder         no    no     no      no      no     no    no     no       YES
     diagonal 9 of 9 ; OFF-diagonal 0 of 72
     RIVAL that ignores the instruction entirely (an impulse): 0 of 70
```

---

## 5. ★★★ TARGET B — decided, in three parts

`python3 dsp/tools/topology.py pipeline`

### B-1 The trail itself is invisible to the transfer function

```
     PURE-carry pipelined comb     w=0,1,2,3  vs the cascade: max|diff| = 0.000e+00
     PURE-carry pipelined allpass  w=0,1,2,3  vs the cascade: max|diff| = 0.000e+00
```

A ladder that computes exactly topology *T* but stores each stage's line input
`w` repetitions later, held in a **private** register, is bit-identical to *T*.
It has to be: `delay-harness.md` item **A** proves the two-address line is
order-independent inside a frame, so if the stored *datum* and the stored
*frame* are the same, the memory cannot tell.

⇒ **"the motif is software-pipelined, therefore a K-stage cascade reference
cannot match it" DOES NOT FOLLOW.** What a trail costs is **registers**, not a
different transfer function — and `delay-harness.md` §8 already showed the
registers can pay: 51 877 machines of 12 348 000 carry a `wtrail = 2` product.

### B-2 What *is* different: a shared carry

```
     pipe family w=1 : 40 members, 36 of them already IN the published set
     pipe family w=2 : 40 members,  0 of them already IN the published set
```

The `wtrail = 2` shared-carry family is **not** covered by the reference set
`schroeder-topology.md` and `dram-datapath.md` scored against. **That part of
the obstruction is real**, and §7 carries the family.

### B-3 ★★★ The part nobody named: the window is not the loop

```
     lines WRITTEN inside the 5-repetition BLOCK A run : L0 L1 L2 L3 L4 L12 L13
     lines READ    inside the same run                 : L2 L3 L4 L5 L6
     lines with BOTH ends inside                       : L2 L3 L4   (3 of 5 read)
```

In r1's executor `lines[j]` is read at repetition *j* and written at repetition
*j*+*w*, **both inside the window**: every line is a closed loop by
construction. In the ROM, the line read at repetition 3 is written by the
**interlude BLOCK B** and the one read at repetition 4 by the **first
repetition of the second run**. r1's executor closes both with drain
repetitions of BLOCK A that the ROM does not contain.

**This is a statement about the DRAIN CONVENTION**, which §7 therefore
enumerates rather than inherits — and §7.2 shows it is decisive.

---

## 6. The controls — YES, NO, and the one that cannot fail

`python3 dsp/tools/topology.py controls`

**6.1 IT MUST SAY YES.** Every reference is matched by the set it belongs to:
**70 of 70**.

**6.2 ★★★ THE CONTROL THAT CANNOT FAIL, REPRODUCED ON PURPOSE.**
`dram-datapath.md` item L records that feeding the real descriptor delays to a
short signal made its matcher accept 22 113 times out of 4 000 machines. The
failure mode is reproduced on **this** pass's code path rather than trusted —
one sample of 150 machines, scored two ways:

```
     REAL delays [172,356,513,739,240]  1 reference survives de-duplication,
                                        138 of 150 machines matched, 897 hits
     REDUCED     [3,5,7,11,13]         70 references,
                                          0 of 150 machines matched,   0 hits
     0.13 recirculations   vs   7.4 recirculations
```

With the real delays **all seventy references collapse onto one signal** and
the matcher accepts almost everything. The structural run must use reduced
delays; the real ones are reported in §2 and never scored.

**6.3 IT MUST SAY NO. POPULATION: 13 twins. ACCEPTED: 0.**

```
     comb, feedback REMOVED                        rejected
     comb, sign of every gain FLIPPED              rejected
     comb, delays all D+1                          rejected
     all-pass, feedback REMOVED                    rejected
     all-pass, delays all D-1                      rejected
     comb bank, one stage MISSING                  rejected
     lattice, reflection coefficients REVERSED     rejected
     pipe w=2, feedback removed (b = 0)            rejected
     pipe w=2, delays REVERSED                     rejected
     Moorer, averager 0.3/0.7 instead of 0.5/0.5   rejected
     nested all-pass, innermost nesting UNDONE     rejected
     instruction-blind: white noise                rejected
     instruction-blind: the input itself           rejected
```

**6.4 A REJECTION THAT ALSO IDENTIFIES.** Scored against `D−2 … D+3` families:

```
     comb, delays all D+1        -> ['comb D+1']
     all-pass, delays all D-1    -> ['all-pass D-1']
     comb, feedback REMOVED      -> nothing in the D-shifted families
```

---

## 7. ★★★ TARGET A — the topology search

`python3 dsp/tools/topology.py search`

### 7.0 Rule 4 on `land`, before the pools are quoted

```
     swap=1: machines for which land = 4,5,6,7,8 give the SAME loop_ok_w
     verdict: 3000 of 3000
```

Under the FORCED polarity the READ is slot 4, so a latency of 4 or more lands
past the end of the 8-slot repetition and every such value drains identically.
The sweep uses `land ∈ (−1,0,1,2,3,4)` with 4 standing for every `land ≥ 4`;
**r1's own 7 and 8 are covered.**

### 7.1 The positive controls — both reproduce

```
     swap=0 wtrail=1 rlag=0, r1's Line, r1's drain, r1's lands (0,1,2,7,8)
       pool 127 204 / 127 204 distinct, sampled 400, matched 78
         pipe1 433 · comb 5
     swap=1 wtrail=1 rlag=0
       pool  68 400 /  68 400 distinct, sampled 400, matched 46
         comb 357   (and nothing else)
```

Both reproduce `dram-datapath.md` §6.2 **qualitatively and in one case
numerically**: the pipe-comb family dominates at r1's polarity, the series comb
cascade is *exclusive* at the FORCED one (that note prints 445 hits, all comb
cascade), and the `(swap=1, wtrail=1, rlag=0)` pool is **68 400** — its exact
published number, reached from a differently-shaped enumeration.

### 7.2 ★★★ The arm the descriptors force

**Structural pools: EXHAUSTIVE over 12 348 000 machines.**

```
     rlag=0 drain=r1     pool  82 632 sampled 400 matched 102  pipe1:335 comb:208
     rlag=0 drain=cyclic pool  82 632 sampled 400 matched 102  pipe1:135 comb:116
     rlag=0 drain=open   pool  82 632 sampled 400 matched   0  -
     rlag=1 drain=r1     pool 426 434 sampled 400 matched   0  -
     rlag=1 drain=cyclic pool 426 434 sampled 400 matched   0  -
     rlag=1 drain=open   pool 426 434 sampled 400 matched   0  -
```

★ **AND A CAUTION THAT MUST TRAVEL WITH THE ROW.** The family that matches
most is `pipe1` — the pipe-comb references whose *own* write trail is 1 — while
the machine's `wtrail` is 2. **A reference family's `w` is not the machine's
`w`**, and reading `pipe1` as "the machine has trail 1" would be exactly the
kind of misreading this project keeps having to retract. `pipe2` matches **0**;
that is a statement about which difference equation the output satisfies, not
about the descriptors' trail, which is FORCED to 2 independently (§2.1).

Three things at once, and the uncomfortable two are printed first:

1. ★★★ **THE ZERO IS GONE at `rlag = 0`.** 102 of 400. The families are
   **pipe-comb** and **series comb cascade**; all-pass, comb bank, Moorer,
   nested all-pass and lattice are at **0** in the same candidate set — which is
   the condition the brief set for a zero to mean anything.
2. ★★★ **`drain = open` KILLS IT.** With the honest straddle convention — the
   lines whose write falls outside the window are never written — the count is
   **0**. Every non-zero above depends on closing the window with repetitions
   the ROM does not contain in that form (§5 B-3).
3. ★★★ **`rlag = 1` IS ZERO EVERYWHERE.** The pool is five times larger and
   spreads over every `land`; it matches nothing. Combined with §8.1's finding
   that the whole `rlag = 0` pool sits at `land = −1`, **the topology survivors
   and `dram-datapath.md` §3's flush-read bound (`land ≥ 1`) point in opposite
   directions with the trail and the read-lag both enumerated.**

### 7.3 ★★ The topology-neutral arm — the zeros survive a pool that does not assume a loop

`loop_ok_w` is the **single-feedback-path** filter: it demands the multiplicand
carry the read with ±1 and the written value carry that product with ±1 and no
direct copy of the read. A **parallel comb bank**, a **Moorer** lowpass comb, a
**nested all-pass** and a **lattice** cannot pass it — so a zero for them inside
that pool would be an absence of a search, not a rejection. The neutral filter
drops the ±1 requirements and asks only that the multiplicand carry *some*
delay datum and the written value not be disconnected from the loop. It is
sampled by **rejection from a uniform draw**, not truncated, so the pool is not
biased towards the smallest `land`.

```
     rlag=0  neutral pool 2000 accepted of 135 581 uniform draws (1.48 %)
             sampled 400, matched  41 : pipe1 127 · comb 91
     rlag=1  neutral pool 2000 accepted of  26 682 uniform draws (7.50 %)
             sampled 400, matched   0 : -
```

★★ **The bank, Moorer, the nested all-pass, the lattice and the first-order
all-pass are at ZERO in the neutral pool as well.** That is the strongest
statement this round can make about the topology: the two families that match
are the **pipe-comb** family and the **series comb cascade**, and they match in
a pool that does *not* presuppose them.

### 7.4 `wtrail` swept

```
     wtrail=0 pool      0 (EMPTY)   sampled   0  matched   0
     wtrail=1 pool  68 400          sampled 400  matched  56 : comb 467 (only)
     wtrail=2 pool  82 632          sampled 400  matched 105 : pipe1 320 · comb 238
     wtrail=3 pool   6 970          sampled 400  matched   0 : -
```

Two different kinds of zero, and they are labelled differently:
`wtrail = 0`'s pool is **structurally empty** — under the FORCED polarity a
zero trail admits no single-multiply loop at all; `wtrail = 3`'s pool has
**6 970 members and none of them matches anything**, which is a rejection.
`wtrail ∈ {1, 2}` survive, and the descriptors force 2.

### 7.5 K = 9 — both BLOCK A runs, interlude ignored

```
     K=9, 70 references, pool 82 632, sampled 200, matched 67
       pipe1 208 · comb 161
```

**33.5 % of machines match at K = 9 against 25.5 % at K = 5.** This is a
**MISS** against P7 (I predicted fewer) and it says something about the
instrument rather than the chip: **the matcher is not sensitive to the number
of stages.** A machine that reproduces a 5-stage comb cascade at K = 5 also
reproduces a 9-stage one at K = 9, because it *is* a comb cascade of whatever
length it is run for. The topology conclusion is therefore robust to K — and
the ladder LENGTH is not determined by this test and is not claimed to be.
The K = 9 run remains a model §2 refutes (the interlude BLOCK B is skipped);
it is reported so its cost is on the record, not as a result.

---

## 8. ★★ TARGET D — the write-data source

`python3 dsp/tools/topology.py wdata`

### 8.1 The structural route

**POPULATION: the exhaustive sweep, 12 348 000 machines, swap = 1.**

```
     wtrail rlag |  bus     acc_before  acc_after   M          pool
        0    0/1/2 |   0          0          0         0            0
        1    0     |   0      34 200     34 200        0       68 400
        1    1     |   0     325 165    325 165   14 928      665 258
        1    2     |   0      94 110     94 110   20 001      208 221
        2    0     |   0      17 375     17 375   47 882       82 632
        2    1     |   0      88 519     88 519  249 396      426 434
        2    2     |   0       8 697      8 697   31 511       48 905
        3    0     |   0       1 750      1 750    3 470        6 970
        3    1     |   0       8 834      8 834   17 515       35 183
        3    2     |   0         483        483      888        1 854
```

★★★ **`bus` IS ZERO IN ALL TWELVE POOLS: 0 of 1 543 857 rows.**
★★ **AND `wtrail = 0` IS EMPTY IN ALL THREE:** under the FORCED polarity a
zero trail admits no single-multiply loop at all.

**THE CONTROL, BEFORE THE ZERO IS ALLOWED TO MEAN ANYTHING (rule 1)** —
delay-harness's synthetic trail-2 motif, re-run here:

```
     synthetic wtrail-2 motif, filter at wtrail = 0 : REJECTED
     ...                                        1 : ['acc_before', 'acc_after']
     ...                                        2 : ['bus']        <== the built path
     ...                                        3 : REJECTED
```

The filter **can** say `bus`. The zero is a rejection, not a blind spot.

**WHY, MECHANICALLY.** The reverb motif's WRITE word is slot 0,
`880.1.**.2D4`: `SRC = 0x0B` (the delay-read register), `ACTION = 0x14`. Under
`wdata = bus` that word stores the read-data register — an **unmultiplied**
copy of another line's output. A line fed that is not a comb and not an
all-pass; it is condition **C3**. The zero is structural, not statistical.

★★ **AND THIS COLLIDES WITH `dram-datapath.md` §2.3.** That section reads *"the
LIMIT word names `SRC 0x0B` in 64 of 74"* as evidence that a write word stores
the bus. **The reverb's own line-write word carries `SRC 0x0B` too.** Method
rule 10 — the parameter one of them holds fixed is **which word class** is
being talked about: §2.3's population is the **PRIME WRITE** (74, one per
program, storing a datum nothing reads); this one's is the **LINE WRITE**. A
**per-word** answer is consistent with both; a single global `wdata` is not.

### 8.2 The corpus route, with both denominators

```
     POPULATION (per ALGORITHM): 91          0x0B   0x07   0x00  other     n
       delay-DRAM WRITE words                 264     32     69     15    380
       delay-DRAM READ  words                  73      6    123    308    510
       every other word                         6   1633   1562   2441   5642
       P(SRC=0x0B | WRITE) = 0.695     P(SRC=0x0B | other) = 0.001

     POPULATION (per DISTINCT IMAGE): 38     0x0B   0x07   0x00  other     n
       delay-DRAM WRITE words                  50     29     27      4    110
       delay-DRAM READ  words                  48      6     27     93    174
       every other word                         6    884    561   1239   2690
       P(SRC=0x0B | WRITE) = 0.455     P(SRC=0x0B | other) = 0.002
```

The image-weighted row **exactly reproduces `dram-datapath.md` item J's own
population** (`SRC 0x0B` 50, `mem[ptr]` 29, `SRC 0x00` 27). The association is
overwhelming against the null in both weightings — and it is the **same**
evidence §2.3 already labelled CONSISTENT, not a second one.

⇒ **THE WRITE-DATA SOURCE STAYS OPEN.** What changes is that item J's *"no
route in this pass separates them"* is no longer true: there is a route, it is
exhaustive, it is conditional on the single-loop hypothesis, and **it points
away from `bus` for the LINE WRITE while §2.3 points towards `bus` for the
PRIME WRITE.** The next pass should test `wdata` as a **per-word** decode of
the SRC/ACTION fields, not as one global switch.

---

## 9. What this changes about earlier claims

| source | claim | now |
|---|---|---|
| `dram-datapath.md` §4 D | *"the NINE motif repetitions read lines 2..10 and write lines 0..8"* | ★ **CORRECTED.** They read `{L2..L6, L8..L11}` and write `{L0..L4, L6..L9}`; L5's write and L7's read belong to the **interlude BLOCK B** (§2) |
| `dram-datapath.md` item I | *"every reference is a self-contained K-stage cascade while the motif is a software-pipelined loop"* | ★★ **HALF RIGHT, AND THE HALF THAT IS RIGHT IS NOT THE TRAIL.** The trail is transfer-function-invisible (§5 B-1). What bites is the **straddle**: 3 of 5 lines close in-window and `drain = open` scores 0 (§7.2) |
| `dram-datapath.md` §6.2 | 0 matches at `(swap=1, wtrail=2)`; *"an absence of a search"* | ★★★ **CONFIRMED AS AN ABSENCE OF A SEARCH.** With the `wtrail = 2` filter the same cell scores **102 of 400** out of an exhaustive 82 632 |
| `dram-datapath.md` item J | *"no route separates bus from acc"* | ★★ **SUPERSEDED.** `bus` is 0 of 1 543 857 under the loop filter, with a control demonstrating the filter can say `bus` (§8) |
| `dram-datapath.md` §3 vs §6.1 | `land ≥ 1` (flush read) vs `land = −1` (ALU) | ★★ **STILL CONTRADICTORY, NOW SHARPER.** With `rlag` enumerated the whole `rlag = 0` pool is `land = −1` and the `rlag = 1` pool matches **nothing** (§7.2) |
| `adjudication-round6.md` §3.5 / this round's brief | the reverb searches ran *against a delay line that could not delay* | ★★★ **TRUE FOR `SINGLE DELAY`, FALSE FOR THE LADDER.** 0 disagreements in 7 of 8 cells, 48 of 200 in the eighth (§3) |
| `r1_allpass_solve.topology_refs` docstring | a lattice *"is the same test as `allpass_ref`"* | ★★ **FALSIFIED** for multi-sample delays: residue 9.70e-01 (§4) |
| `schroeder-topology.md` §0-C | the conditional challenge, re-opened by round 6 | ★ **STILL OPEN.** The two matching families here are pipe-comb and comb cascade; both all-pass forms and the nested all-pass are at 0 — but the pool assumes a single feedback path, so the all-pass zeros are **not** rejections of those topologies (§7.3) |
| `delay-harness.md` §8 STEP 4 | 51 877 admitted of 12 348 000 at `wtrail = 2` | ★ **RE-DERIVED with a different denominator convention**: 82 632 **(machine, write-source) rows**, all distinct machines, at `(wtrail 2, rlag 0)`. Both numbers are printed because they count different things (rule 9) |

---

## 10. TARGET C — what would become executable, and what stops it

**0 of the 42 delay-DRAM frame slots.** Per class, the constraint that stops it:

| word class | what is settled | what still blocks it |
|---|---|---|
| **line READ** (`addr8 & 0xF0 == 0x20/0x30`) | direction (round 5 D), address (descriptor cell, `delta = 0`), that the datum is **not** on its own bus (`dram-datapath.md` A) | **which `land`** — §7.2's survivors say `−1`, §3 of that note says `≥ 1`, and this round makes the disagreement worse rather than better |
| **line WRITE** (`0x60`) | direction, address | **the write-data source.** §8 excludes `bus` *conditionally*; `acc_before` / `acc_after` / `M` remain, and they are three different machines |
| **PRIME write** (LIMIT, 74) | it stores a datum no read can reach | same as line WRITE; harmless *only if* `wdata` is settled |
| **FLUSH read** (CEILING, 83) | its datum is discarded | nothing to apply — it is a no-op by construction, but 48 of the 83 carry ACTION `0x0B`, which is undecoded |
| **C-format** (`C40.1.**.000`, 4 in ROOM REVERB 1) | nothing | undecoded entirely |

**A FORCED list for the Apply agent: EMPTY.** Nothing in this round reaches
the threshold. The two candidates closest to it are (a) `wtrail = 2` as the
port-slot trail — already FORCED by `dram-datapath.md` §4 and re-derived here
from the block decomposition, but it is a property of the *layout*, not a word
semantic; and (b) `wdata ≠ bus` for the LINE WRITE, which is exhaustive but
**conditional on the single-loop hypothesis** and therefore must keep trapping
under method rule 6.

---

## 11. PREDICT-THEN-CHECK — hits AND misses

Recorded in a scratch `PREDICTIONS.md` before any number in `topology.py`
existed, and reproduced here verbatim:

```
P1  The two-address DelayDRAM is DEGENERATE against r1's one-cell Line(D) on the
    REVERB LADDER for every wtrail >= 1, and separates ONLY at wtrail = 0 under
    swap = 1.
P2  A Gray-Markel ONE-MULTIPLIER LATTICE is DEGENERATE with the first-order
    all-pass cascade under this matcher.
P3  The generalised pipe-comb at wtrail = 2 is NOT proportional to any member of
    the published reference set.
P4  A PURE-CARRY pipelined ladder is BIT-IDENTICAL to the corresponding cascade.
P5  The wtrail = 2 search with the new filter yields a NON-ZERO survivor count,
    dominated by PIPELINED references rather than cascades.
P6  The write-data source is NOT settled to one value; but `bus' is EXCLUDED at
    wtrail = 2 under the forced polarity.
P7  The K = 9 arm gives FEWER matches than K = 5.
P8  `land' is NOT forced by the topology search.
P9  At least one of the six named topologies survives at wtrail = 2 with a
    strictly non-zero count while at least one other is at zero.
P10 The real descriptor delays will NOT recirculate in a short test signal, so a
    run with the real delays would be a control that cannot fail.
P11 The nine repetitions being non-contiguous will turn out to matter.
```

| # | verdict | prediction → what happened |
|---|---|---|
| **P1** | **HIT** | the two-address memory would be degenerate on the ladder except at `(swap=1, wtrail=0)` → exactly that, 48 of 200 in the one cell and 0 in the other seven |
| **P2** | **MISS** | the Gray-Markel lattice would be degenerate with the all-pass cascade (r1's docstring says so) → **it separates**, residue 9.70e-01. The docstring is FALSIFIED and a topology had been excluded on it |
| **P3** | **HIT** | the `w = 2` pipe family would not be in the published set → 0 of 40 |
| **P4** | **HIT** | a pure-carry pipelined ladder would be bit-identical to its cascade → `max|diff| = 0` for `w = 0..3`, both topologies |
| **P5** | **HIT, then half-MISS** | the `wtrail = 2` search would yield a non-zero, **pipelined-dominated** count → non-zero (102 of 400) and pipe-comb *is* the largest family (335 vs 208) — but the count is **zero at `rlag = 1` and zero at `drain = open`**, which I did not predict at all |
| **P6** | **HIT** | the write-data source would not be settled, but `bus` would be excluded at `wtrail = 2` → 0 of 1 543 857 across **all twelve** pools, not just `wtrail = 2`; still OPEN because the exclusion is conditional |
| **P7** | **MISS** | K = 9 would give **fewer** matches than K = 5 → **more**: 67 of 200 (33.5 %) against 102 of 400 (25.5 %). The matcher is not sensitive to the number of stages, which is a limit of the instrument and is now on the record (§7.5) |
| **P8** | **HIT, badly** | `land` would not be forced by the topology search → it is not *forced*, but every survivor is at `land = −1`, which is a much stronger statement than I predicted and one that **contradicts a published bound** |
| **P9** | **HIT** | the search would discriminate → 2 families non-zero, 5 families zero, in one candidate set |
| **P10** | **HIT** | the real delays would not recirculate → 70 references collapse to 1, 138 of 150 machines accepted |
| **P11** | **HIT, and bigger than predicted** | the nine repetitions would be non-contiguous and it would matter → they are `5 + 4` with a **ten-word BLOCK B** between them that owns its own delay line, and the prologue is that same block rotated with its carry-copies disabled |

**MISSES: 2 outright (P2, P7) and 1 partial (P5), of 11.** P2 is about
someone else's instrument; P5 and P7 are about mine.

---

## 12. What is OPEN, and what the next pass needs

1. ★★★ **BLOCK B.** Ten words, four class-A multiplies, one delay line of its
   own, and it sits **inside** the ladder. No search has ever executed it.
   Until it is decoded the ladder cannot be solved as a whole, and every
   `drain` convention is a guess about what it does.
2. ★★★ **The `land = −1` vs `land ≥ 1` contradiction**, now sharper: the
   topology survivors are *entirely* at the blocking read and the pipelined-read
   pool matches nothing. One of the two arguments has a parameter held fixed;
   this round could not find which.
3. ★★ **The head and the pre-delay loop.** Whether `w000`'s tap feeds the
   ladder decides whether an open-cascade reference is legal at all.
4. ★★ **`wdata` as a per-word decode** rather than a global switch (§8).
5. ★ **The 4 C-format cells**, the rotation register `G`, the unit-1 cursor
   reload — unchanged.

---

## 13. Safety

`dsp/verify.py` reports **BYTE-MATCH OK**. Neither disassembler mirror is
touched; no `.dsm` listing, no device source, no MAME build, no `.cpp`.
**0 of the 42 delay-DRAM frame slots become executable, and nothing is
applied.** No processes are left running.
