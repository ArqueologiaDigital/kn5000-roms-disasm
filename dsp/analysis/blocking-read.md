# THE BLOCKING READ — the shared assumption behind the `SRC 0x00` contradiction

NEC **uPD6383GF-3BA** (Technics SX-KN5000, IC311). Date: **2026-07-27**.
No hardware. Static analysis, the ROM corpus, constraint solving and the live
emulator only.

Adjudicates three concurrent passes:
[`schroeder-topology.md`](schroeder-topology.md) (the reverb core is a comb),
[`action00-discriminator.md`](action00-discriminator.md) (`ACTION 0x00` is not
forced), [`dark-words.md`](dark-words.md) (the 86 words that execute nothing).

Tool: [`../tools/r1_allpass_solve.py`](../tools/r1_allpass_solve.py), section
`blockread`, plus three new rows in `schroeder2`.

```
python3 dsp/tools/r1_allpass_solve.py blockread                    # ~40 s, the argument + controls
SCH_PARTS=search SCH_ROW=1  python3 dsp/tools/r1_allpass_solve.py schroeder2   # PUBLISHED strict -> must still be 112
SCH_PARTS=search SCH_ROW=8  python3 dsp/tools/r1_allpass_solve.py schroeder2   # strict + blocking read
SCH_PARTS=search SCH_ROW=9  python3 dsp/tools/r1_allpass_solve.py schroeder2   # joint  + blocking read
SCH_PARTS=search SCH_ROW=10 python3 dsp/tools/r1_allpass_solve.py schroeder2   # sequential strict + blocking
python3 dsp/tools/dark_words.py cursorbase                         # item J, with its two controls
```

Labels: **MEASURED** / **PROVEN BY CONSTRUCTION** / **FORCED** / **CONSISTENT** /
**FALSIFIED** / **OPEN**.

---

## 0. Result in one page

| # | statement | label |
|---|---|---|
| **A** | ★★★ **THE `SRC 0x00` CONTRADICTION IS DISSOLVED, AND IT WAS NEVER TWO FACTS.** `action-field.md` §8 tabulates two rows of reverb-vs-SINGLE-DELAY disagreement — `SRC 0x00` (`DR` 52 696/52 696 vs **0** of 5 145) and the **read latency** (`land ∈ {0,1}` vs `land = −1`, a BLOCKING read, FORCED 5 145/5 145). **The second row causes the first.** `LANDS = (0,1,2,7,8)` omits the blocking read, so inside the reverb's space the fresh delay sample could reach the ALU by exactly one route — `SRC 0x00 = DR` at slot 1. Put the blocking read back and a second route opens that reads `SRC 0x00` not at all. | **MEASURED** |
| **B** | ★★★ **THE ROUTE IS THE READ WORD'S OWN ANCHORED ACTION, AND `dark-words.md` §10.3 POINTED AT IT.** Slot 0 is `880.1.60.2D4`, an escape word whose `lo12` ACTION is **`0x14` = `tempB ← bus`, one of the five anchored codes**. Under a blocking read its bus *is* `w[r]`, so `tempB ← w[r]` before slot 1 executes; slot 3 (`012.2.00.680`) reads `SRC 0x1A = tempB` and computes `acc ← tB + P`. Symbolically, with **`SRC 0x00 = zero`**: `MULTIPLICAND = P + N`, `write = P + N` — **the identical comb stage `schroeder-topology.md` published**, with `SRC 0x00` reading nothing. | **PROVEN BY CONSTRUCTION** |
| **C** | ★★★ **THE COMB SURVIVES, AND `SRC 0x00 = DR` DOES NOT.** STRICT + blocking: **3 206** comb machines (against 112 published), `SRC 0x00` **6 values** — `DR` 581, `zero`/`P`/`mem[ptr]`/`acc`/`tA` **525 each**. Sequential + blocking: **2 310**, and `SRC 0x00` is **perfectly uniform, 385 each of six** — total indifference. The all-pass reference is carried in the same set and matched by **0** in every row. | **MEASURED** |
| **D** | ★★ **AND THE STRICT VOCABULARY IS RE-UPHELD BY THE SEARCH THAT APPEARED TO FALSIFY IT.** `schroeder-topology.md` §0-C reported that the comb forces `ACTION 0x19 = tB ← bus` (112/112, contradicting SINGLE DELAY's tempA) and, in its joint row, that `0x19` must **route the bus** — i.e. *"only `ACTION 0x00` routes the bus"*, what the device implements, is false. With the blocking read: `tB ← bus` collapses to **56 of 3 206**, `tA ← bus` is admissible again, and **`ACTION 0x19`'s accumulator half is FORCED to "no effect" — 3 206/3 206 (adder) and 2 310/2 310 (sequential).** ★ **The falsification is itself FALSIFIED. Nothing in the device changes; `LO_ACT_CAP_TA2 = tempA ← bus` stands.** | **FORCED** / a **FALSIFICATION** |
| **E** | ★★ **A DEGENERATE PARAMETER, IN BOTH PUBLISHED SPACES.** `land = 0` and `land = 1` are **the same machine**: `exec_rep` queues the read at `tick + land` and pops it when `deadline <= tick`, and the read is at slot 0, so both are first visible at slot 1. MEASURED: **4 000/4 000** random machines symbolically identical, and every published row's LAND split is exactly 50/50 (8 260/8 260, 56/56, 6 370/6 370). "read lands +n: 2 values, CONSISTENT" is **one machine counted twice**. The comparison is shown able to say *different*: `land 0` vs `2` differs on 10/300, vs `−1` on 36/300. | **PROVEN BY CONSTRUCTION** + **MEASURED** |
| **F** | ★ **`SRC 0x00 ≠ DR` NOW HAS THREE INDEPENDENT ROUTES AND NO DISSENTER.** (1) SINGLE DELAY, numerically: `DR` 0 of 5 832 in every window and mix setting (`action00-discriminator.md` §7). (2) `dark-words.md` §6/§10.1, structurally and with no search: under H-DIR, `SRC 0x00 = DR` makes `880.1.60.000` a *read*, contradicting R3 §6.3's independently derived line-write. (3) The reverb, the only block that ever demanded `DR`, is now **indifferent**. | **FORCED** (as a negative) |
| **G** | ★ **AND IT STILL DOES NOT UNLOCK `SRC 0x00`.** The remaining ambiguity is `mem[ptr]` vs `acc`, and it is *live*: `action00-discriminator.md` §0-H MEASURED that `mem[ptr]` is forced only while the two input-mix coefficients are `0.0000`, which they are in the ROM image (20 of 23 motif instances) but which **the host can overwrite at run time**. Two values ⇒ **the 30 frame slots keep trapping.** Nothing was applied. | **OPEN** |
| **H** | ★★ **A THIRD CROSS-BLOCK TENSION, PRESENT IN THE PUBLISHED WORK AND NEVER PRINTED.** The comb search enumerates the tempB `>>1` as `tbsh`, and in every **STRICT** row it **FORCES `tbsh = 0`** — 112/112 in the *published* row, 3 206/3 206 blocking, 2 310/2 310 sequential-blocking — while the biquad FORCES a `>>1` somewhere on the tempB path (77 dB without it). ★ **Stated at its real strength, not its best:** in the *joint* blocking row it is only a **92.1 % majority** (32 050 of 34 815), so this is a **tension inside a hypothesis**, not a contradiction between two determinations. The marginal existed in every run since `schroeder-topology.md` and was simply not among the fields printed. It is printed now, recorded in the device comment, and **not acted on**. | **MEASURED**, **OPEN** |
| **I** | ★ **`ACTION 0x00`'s CAPTURE HALF is FORCED to `tA ← acc`** in the strict blocking rows (3 206/3 206, 2 310/2 310) — the device gives `0x00` no capture half at all — and **SINGLE DELAY does not dissent: it is perfectly blind to that half** (7 values, exactly uniform, at both orders; §3.4). So it is a live candidate with no opposition. **NOT applied**: it is forced *inside* a topology hypothesis, in one block, and it is only a plurality in the joint row (27 510 of 34 815). Method rule 2. Ranked as an experiment instead. | **FORCED (conditionally)** |
| **J** | ★ **A TOP-RANKED LEAD OF `dark-words.md` IS FALSIFIED IN ONE PASS.** Its §4.5 calls pointer register `0x827` "the highest possible payoff per unit of work in the dark set" — 42 slots from 2 — and names the test: does an affine map take its per-unit payloads `{0x6C, 0x64}` to R3 candidate (iii)'s per-unit descriptor bases `{0x26, 0x00}`? **Zero maps in the declared family, in either orientation**, and the reason is arithmetic rather than exhaustion: the payload difference is **8**, the target difference **38**, ratio **4.75** — no scale-and-offset map exists. The family is shown able to hit reachable targets (it finds maps onto the payloads themselves and onto the FORCED D-RAM bases `0x05`/`0x85`). It does **not** kill the register's role in general — R3 has candidates (i) and (ii) too. | **FALSIFIED** |
| **K** | Housekeeping: `dsp/verify.py` **BYTE-MATCH OK**; both disassembler mirrors changed together (comments only) and agree 3057/3057; no word gains or loses an executable semantic; DSPCFG-Off audio bit-identical. §7. | **MEASURED** |

---

## 1. The adjudication, and how it was reached

### 1.1 The three passes disagree in exactly three places

| # | `schroeder-topology.md` (T1) | `action00-discriminator.md` (T2) | `dark-words.md` (T3) |
|---|---|---|---|
| **`SRC 0x00`** | **`DR`, FORCED** in every row (16 520/16 520, 10 080/10 080, 12 740/12 740) — and explicitly **reinstated** as a live two-block contradiction | **never `DR`** — 0 of 5 832, and §0-J retires the reverb's demand as *a necessary condition of a refuted premise* | structurally consistent only with **not-`DR`** (H-DIR + R3 §6.3, 4/4) |
| **`ACTION 0x19`** | capture is **`tA ← acc`** and `0x19` **routes the bus** (joint, 12 740/12 740); the strict row says **`tB ← bus`** (112/112) | **`tempA ← bus`, FORCED 108/108** | — |
| **`ACTION 0x00`** | **`load`, FORCED** given the bit-4 clear | **not forced**: 33 survivors, `load` 15 / `add` 12 / `rload` 6 | — |

T1 and T2 both noticed that they collide, and each resolved it by demoting the
other: T2 by arguing the reverb's demands are conditions of the refuted all-pass;
T1 by observing that the *comb* is not refuted and makes the same demand, so the
contradiction is "reinstated and is the highest-value experiment left".

**Both of those moves take the reverb's demand at face value.** The adder lesson
says to look for the shared assumption first, and there is one.

### 1.2 ★ The shared assumption, and where it is written down

`action-field.md` §8 already prints it, as a *separate row of the same table*:

```
                    the reverb ladder demands    SINGLE DELAY demands
   SRC 0x00         the delay-RAM read register  NOT it: 0 of 5145
   the read latency land in {0, 1}               land = -1, a BLOCKING read,
                                                 FORCED 5145/5145
```

Two blocks are being solved **under different read models**, and the block whose
read model cannot deliver the fetched word to the read word's own bus is exactly
the block that "requires" a second route for it. In the tool:

```python
LANDS = (0, 1, 2, 7, 8)                     # sect. 10 / 13 / 14 all use this
...
if sl["dram"] == "rd" and m[LAND] < 0:      # the BLOCKING read
    # "the read word's OWN bus already sees the returned word.  SINGLE DELAY
    #  needs it; R1's model excluded it by construction"
```

`sec_singledelay` enumerates `ld in (-1, 0, 1, 2)`. `action_search` — which every
reverb section uses — enumerates `LANDS`. **The blocking read has never been in
the reverb's space.** `action_search` now takes an explicit `lands=` argument so
the choice is made at the call site instead of inherited.

*Why `land = −1` is not exotic:* it is a **wait-state / stall** read, the ordinary
way a DSP fetches from external DRAM, and R1's own open item O-2 names the two
pins (`SETRDY` open, `BR-RQ` strapped) that would settle the timing. R1's `land ∈
[2,5]` (F6) is **CONSISTENT inside the refuted all-pass hypothesis** and is not a
constraint on the comb; T1's `land ∈ {0,1}` is item **E**, one machine twice.

### 1.3 The second route, from the ROM

The motif as the decoder reads it, and the anchored ACTION on each escape word:

```
   slot 0 880.1.**.2D4  ESC  src=0B dram-rd  act=14 -> tB<-bus     accop=0
   slot 1 104.2.**.000       src=00 (OPEN)   act=00 -> (OPEN)      accop=2
   slot 2 000.2.**.419       src=10 acc      act=19 -> (OPEN)      accop=0
   slot 3 012.2.**.680       src=1A tempB    act=00 -> (OPEN)      accop=1 ST
   slot 4 880.1.**.655  ESC  src=19 tempA    act=15 -> (no effect) accop=0
   slot 5 102.A.**.64B       src=19 tempA    act=0B -> (OPEN)      accop=1
   slot 6,7 000.2.**.000     src=00 (OPEN)   act=00 -> (OPEN)      accop=0
```

★ **Slot 0's ACTION is `0x14`, one of the five ANCHORED codes: `tempB ← bus`.**
`dark-words.md` §10.3 states this and asks that any nested-comb model satisfy both
halves of the read/write pair; nothing had used it, because with a pipelined read
the read word's bus carries the *previous* repetition's word and the capture is
useless. Under a blocking read it carries `w[r]`, and slot 3's `SRC 0x1A = tempB`
consumes it. Symbolically (`P` = entry product `t[r−1]`, `N` = this repetition's
read `w[r]`, `Q` = the fresh product):

```
   SRC 0x00 = ZERO, land = -1, escact = 1:
       MULTIPLICAND = P+N
       write value  = P+N
       exit  tA=Q  tB=N  acc=Q  DR=N
       delay-loop filter -> ['bus', 'acc_before', 'acc_after', 'M']
```

**The same stage `u[r] = w[r] + t[r−1]`, written to the line and multiplied by
`g[r]`, that `schroeder-topology.md` §6.3 published — with `SRC 0x00` reading
nothing at all.** The comb result is *unaffected*; only its `SRC 0x00` corollary
falls.

---

## 2. ★ THE CONTROLS — each shown able to say NO

Rule 1 of the brief, and the reason the previous pass's ladder control was
worthless. Every control here is printed with the case where it rejects.

**(a) The mirror check — the new driver must reproduce the published numbers.**
Run through the same `action_search`/`match_refs` pipeline with `LANDS` at its
published value:

```
   PUBLISHED STRICT      2268 loop survivors -> 112 comb
       pipe-comb b+1 c+1 hold u_last x192   t_last x144   w_last x144
       comb cascade, tap = stored    x48    tap = delayed x48
       SRC 0x00 FORCED DR x112 ; ACTION 0x19 FORCED tB<-bus x112
```

**112, and the same five references at the same multiplicities** as
`schroeder-topology.md` §6.2. The difference between 112 and 3 206 is the read
model and nothing else.

**(b) Kill the route and the machine must die.** The survivor of §1.3 with
`escact = 0` — the escape word's `lo12` ignored, so ACTION `0x14` does nothing:

```
   escact = 1 (the route open)                  loop filter -> ['bus','acc_before','acc_after','M']
   escact = 0 (read word's ACTION 0x14 ignored) loop filter -> REJECTED   <- SAYS NO
```

**(c) Take the blocking read away and it must die too**, because the route needs
the fetched word on the read word's own bus:

```
   land = 0 (pipelined, SRC 0x00 = zero)  loop filter -> REJECTED   <- SAYS NO
   land = 1 (pipelined, SRC 0x00 = zero)  loop filter -> REJECTED   <- SAYS NO
   land = 2 (pipelined, SRC 0x00 = zero)  loop filter -> REJECTED   <- SAYS NO
```

**(d) The degeneracy comparison must be able to report "different".**

```
   SYMBOLIC, 4000 random machines, land 0 vs 1 : identical 4000 / 4000
   CONTROL  land 0 vs  2 on the real ladder    : identical  290 / 300   <- not 300
   CONTROL  land 0 vs -1 on the real ladder    : identical  264 / 300   <- not 300
```

**(e) The all-pass negative control travels inside the reference set** and is
matched by **0** machines in every blocking row (explicitly counted: 0 of 3 206)
— the published falsification is reproduced by the run that overturns its
`SRC 0x00` corollary.

**(f) A second mirror check, on the other block.** Re-solving SINGLE DELAY with
`land` fixed at −1 returns **5 635** survivors in the sequential model — the
number `allpass-adder-rerun.md` §8 published (§3.3).

---

## 3. ★★★ THE SEARCH

### 3.1 STRICT + the blocking read (`SCH_ROW=8`)

```
   164640 enumerated, 8036 pass the delay-loop filter
   3206 machines reproduce SOME topology at BOTH delay sets
      pipe-comb b+1 c+1 hold t_last x5022   comb cascade, tap = stored  x1674
      pipe-comb b+1 c+1 hold w_last x3312   pipe-comb b-1 c+1 t_last    x1290
      pipe-comb b+1 c+1 hold u_last x1266   comb cascade, tap = delayed x1104
   SRC 0x00 reads   6        DR x581  zero x525  P x525  M x525  acc x525  tA x525
   read lands +n    FORCED   -1 x3206
   escact           2        1 x3178   0 x28
   tempB >>1        FORCED   0 x3206
   ACTION 0x00 acc op    4        bus x896  +bus x840  bus-acc x840  -bus x630
   ACTION 0x00 capture   FORCED   tA<-acc x3206
   ACTION 0x19 acc op    FORCED   -  x3206          <- "no accumulator effect"
   ACTION 0x19 capture   6        - x630  tA<-bus x630  tA<-acc x630
                                  M<-bus x630  M<-acc x630  tB<-bus x56
   ACTION 0x0B acc op    FORCED   -  x3206
```

★ **And the cross-tab explains every residual number exactly** (`xtab`, on the
same 3 206):

```
   escact x SRC 0x00                    ACTION 0x19 capture x escact
      escact=0  src00=DR    x28            -        escact=1  x630
      escact=1  src00=DR    x553           M<-acc   escact=1  x630
      escact=1  src00=M     x525           M<-bus   escact=1  x630
      escact=1  src00=P     x525           tA<-acc  escact=1  x630
      escact=1  src00=acc   x525           tA<-bus  escact=1  x630
      escact=1  src00=tA    x525           tB<-bus  escact=0  x28
      escact=1  src00=zero  x525           tB<-bus  escact=1  x28
   ALL-PASS matches: 0
```

**All 28 `escact = 0` survivors read `SRC 0x00 = DR`** — they are the *old* route,
which the blocking read also enables (`DR` is loaded before slot 1 either way).
**And the 56 `tB ← bus` survivors are exactly those 28 plus their `escact = 1`
twins.** So `ACTION 0x19 = tB ← bus` is not a second opinion at all: it is the
residue of the only route the published space could see. The 3 150 machines that
use the read word's own ACTION are *all* compatible with `tA ← bus`.

### 3.2 SEQUENTIAL + the blocking read (`SCH_ROW=10`) — the same answer in the model the adder replaced

```
   6622 loop survivors -> 2310 comb
   SRC 0x00 reads   6        zero x385  P x385  M x385  acc x385  DR x385  tA x385
   escact           FORCED   1 x2310
   tempB >>1        FORCED   0 x2310
   ACTION 0x00 acc op    3        +bus x840  bus-acc x840  -bus x630   (`load' ABSENT)
   ACTION 0x00 capture   FORCED   tA<-acc x2310
   ACTION 0x19 acc op    FORCED   -  x2310
```

★ **`SRC 0x00` is perfectly uniform across all six candidates.** In the sequential
model the reverb is not merely compatible with a non-`DR` reading — it has **no
opinion at all**, which is the cleanest possible form of item **A**.

### 3.2a JOINT (`0x19` restricted to a tempA capture) + the blocking read (`SCH_ROW=9`)

The row `schroeder-topology.md` §6.6 built to intersect the comb with SINGLE
DELAY's tempA, re-run with the read model SINGLE DELAY also forces:

```
   1176000 enumerated, 104472 pass the delay-loop filter
   34815 machines reproduce SOME topology at BOTH delay sets   (published: 12 740)
   SRC 0x00 reads   6      DR x11725  zero x4690  acc x4690  tA x4690  M x4610  P x4410
   read lands +n    FORCED -1 x34815
   escact           2      1 x31105   0 x3710
   tempB >>1        2      0 x32050   1 x2765          <- 92.1 %, NOT forced here
   ACTION 0x00 acc op   4      bus x14515  bus-acc x7280  +bus x6720  -bus x6300
   ACTION 0x00 capture  7      tA<-acc x27510  - x1630  tB<-bus x1540  ...
   ★ ACTION 0x19 acc op   5      +bus x7365  bus x7365  bus-acc x7365  -bus x6420
                                 -  x6300      <- "no accumulator effect" is BACK
   ★ ACTION 0x19 capture  2      tA<-acc x20960   tA<-bus x13855
```

★★ **The two results this row was quoted for are both gone.**
`schroeder-topology.md` §6.6 forced `tA ← acc` at 12 740/12 740 and reported
**ZERO** survivors for *"`0x19` has no accumulator effect"*, and concluded that
the strict vocabulary — what the device implements — is falsified. With the
blocking read, `tA ← bus` has **13 855** survivors and *"no accumulator effect"*
has **6 300**. Nothing needs to change in the device.

*(Reported against myself: this row is also where `tbsh = 0` stops being forced.
Item **H** is stated at 92.1 % because of it, not at "forced in every row", which
is what the three strict rows alone would have supported.)*

### 3.3 ★ SINGLE DELAY, at the read model it forces — and the same mechanism, in the other block

Its five words, printed by the tool rather than typed:

```
   880.1.60.2D9  ESC src=0B dram-rd  act=19   <- the DRAM READ carries ACTION 0x19
   202.A.B8.655      src=19 tempA    act=15   <- and the NEXT word multiplies tempA
   000.2.48.000      src=00 (OPEN)   act=00   <- x arrives HERE, not the delayed sample
   212.2.00.419      src=10 acc      act=19 ST
   880.1.20.64B  ESC src=19 tempA    act=0B   <- the DRAM WRITE
```

★★ **Both blocks put the fetched sample into a temp register with the READ WORD'S
OWN ACTION and consume it in the following word** — `0x14`/tempB in the reverb,
`0x19`/tempA in SINGLE DELAY. That is a structural argument, not a numeric one,
and it is why SINGLE DELAY forces the blocking read: it has no other route
either. It also explains its `SRC 0x00 = mem[ptr]` — `000.2.48.000` is where *x*
arrives, not the delayed sample.

Re-solved with `land` **fixed at −1** (the value it forces) and the ACTION halves
projected:

```
   == SINGLE DELAY, order=sequential, land=-1 : 5635 survivors   <- the PUBLISHED number
      SRC 0x00              4     M x3430  acc x980  P x980  zero x245   (DR: ZERO)
      ACTION 0x19 capture   2     tA<-bus x3430   tA<-acc x2205
      ACTION 0x00 capture   7     UNIFORM, 805 each     <- BLIND
   == SINGLE DELAY, order=adder, land=-1 : 8085 survivors
      SRC 0x00              3     M x4900  acc x1960  P x1225            (DR: ZERO)
      ACTION 0x19 capture   2     tA<-bus x6860   tA<-acc x1225
      ACTION 0x00 capture   7     UNIFORM, 1155 each    <- BLIND
```

**5 635 reproduces `allpass-adder-rerun.md` §8 exactly** — the second mirror check
of this pass. And `ACTION 0x00`'s capture half is **perfectly uniform** at both
orders: SINGLE DELAY has no opinion about it, so the comb's `tA ← acc` (item
**I**) has no dissenter — which is not the same as having support.

### 3.4 What moved and what did not

| claim | source | status after this pass |
|---|---|---|
| the reverb core is a **comb**, not a first-order all-pass | T1 §0-A | **STANDS, and is broadened** — 3 206 / 2 310 machines with the blocking read, all-pass still 0 |
| the multiplicand and the written value are `w[r] + t[r−1]` | T1 §0-A | **STANDS** — reproduced symbolically with `SRC 0x00 = zero` |
| **`SRC 0x00 = DR`, FORCED**, "contradiction #2 reinstated" | T1 §0-D, §7 | ★ **WITHDRAWN.** An artefact of a read model that omitted the blocking read |
| **`ACTION 0x19 = tB ← bus`, FORCED 112/112** | T1 §6.2 | ★ **WITHDRAWN** — 56 of 3 206 |
| **`ACTION 0x19` must route the bus ⇒ the strict vocabulary is FALSIFIED** | T1 §0-C, §6.6 | ★★ **FALSIFIED IN TURN.** `0x19`'s accumulator half is FORCED to "no effect" 3 206/3 206 and 2 310/2 310 |
| `ACTION 0x00 = load` FORCED given the bit-4 clear | T1 §0-B | **WEAKENED to a plurality** — 896 of 3 206 (adder); **absent** among the 2 310 sequential survivors |
| `ACTION 0x00` is **CONSISTENT**, not FORCED; act00 ↔ store-gate are one question | T2 §0-A, §0-C | **UPHELD**, and now the reverb no longer argues the other way |
| `SRC 0x00 ∈ {mem[ptr], acc}`, FORCED | T2 §7 | **UPHELD and strengthened** — the last dissenter withdrew |
| H-DIR / R3 §6.3 say `SRC 0x00` is not `DR` | T3 §6, §10.1 | **UPHELD**, and it is now the majority of a 3-0 agreement |
| `dark-words.md` §10.3: the read word's ACTION `0x14` is tempB and any comb model must satisfy it | T3 §10.3 | ★ **DELIVERED — it is the mechanism** |
| "read lands +n: 2 values" | T1 §6.1/6.2/6.6 | ★ **DEGENERATE** — one machine counted twice |

---

## 4. PREDICT-THEN-CHECK — every hit and every miss

Recorded in full before any measurement (scratch `PREDICTIONS.md`).

| # | prediction | outcome |
|---|---|---|
| **PR-1** | `land = 0` and `land = 1` are the same machine; every published LAND split is exactly 50/50 | **HIT** — 4 000/4 000 symbolic, 300/300 numeric, and 8 260/8 260, 56/56, 6 370/6 370 |
| **PR-2** | comb machines still survive with the blocking read | **HIT** — 3 206 strict, 2 310 sequential |
| **PR-3** | ★ `SRC 0x00 = DR` stops being forced; `mem[ptr]` appears | **HIT**, and stronger than predicted: `zero` also appears (525), and the sequential row is perfectly uniform |
| **PR-4** | `ACTION 0x19`'s capture stops being forced to `tA ← acc`; `tA ← bus` becomes available | **HIT** — 630 of 3 206 |
| **PR-5** | `ACTION 0x00 = load` stays the plurality, may stop being forced | ★ **PARTIAL MISS.** Plurality in the adder (896 of 3 206) but **absent entirely** from the 2 310 sequential survivors, which I did not predict |
| **PR-6** | the all-pass still matches 0 | **HIT**, every row |
| **PR-7** | the new survivors will **FORCE** `escact = 1` | ★ **MISS in the adder row** — 3 178 of 3 206, not all: 28 survivors reach the same topology through the *old* `SRC 0x00 = DR` route, which the blocking read also enables (`DR` is loaded before slot 1 either way). FORCED in the sequential row, 2 310/2 310. Reported rather than quoted from the row that agreed |
| **PR-8** | no frame completes | **HIT** — 0 of 1 344 001, §6 |
| **PR-9** | *(not predicted)* the comb would turn out to force `tbsh = 0` **and the published rows already did** | ★ **UNFORESEEN** — item **H**. A field that had been enumerated in every run since T1 and never printed |

---

## 5. What is FORCED, CONSISTENT and OPEN after this pass

### 5.0 ★ A TOP-RANKED LEAD OF `dark-words.md`, TESTED AND FALSIFIED

`dark-words.md` §4.5: *"If `0x827` turns out to be the delay-DESCRIPTOR CURSOR's
base, it settles `DRAM-ADDR` — 42 slots — from 2 dark slots. That is the highest
possible payoff per unit of work in the dark set, and it is testable: does any
affine map of `{0x6C, 0x64}` land on `{0x26, 0x00}`?"*

Run, exhaustively over a **declared** family — `a·x + b (mod m)` for
`a ∈ [−16,16]`, `b ∈ [−256,256]`, `m ∈ {0xFF, 0x7F, 0x3F, 0x1F}`, plus
`(x >> s) + b` and `(x << s) + b` for `s ∈ [0,7]`, in **both** target
orientations:

```
   HITS: 0
   CONTROL (target = the payloads themselves, must be non-empty) : 3
   CONTROL (target = the FORCED D-RAM bases 0x05 / 0x85)         : 4
   0x6C - 0x64 = 8 ;  0x26 - 0x00 = 38 ;  ratio 4.75
```

**FALSIFIED, and by arithmetic rather than by exhaustion**: a scale-and-offset map
must carry the payload difference 8 onto the target difference 38, and 38/8 is not
an integer. The controls show the family is capable of hitting targets it can
reach. This kills the *test*, not the register: R3 offers candidates (i) and (ii)
as well, and the cursor base need not be an affine image of anything.

---

**FORCED / PROVEN BY CONSTRUCTION**

* `land = 0` ≡ `land = 1` in `exec_rep` (item **E**).
* The second route exists and is anchored: slot 0's ACTION `0x14` is `tempB ← bus`
  and slot 3 reads `SRC 0x1A = tempB` (item **B**).
* `ACTION 0x19` has **no accumulator half** in the comb — 3 206/3 206 and
  2 310/2 310 — so the strict vocabulary survives (item **D**).
* `SRC 0x00 ≠ DR` — three routes, no dissenter (item **F**).
* The reverb core is a comb network and not a first-order all-pass (T1, broadened).

**CONSISTENT, not forced**

* `SRC 0x00 = mem[ptr]` — forced only while the input-mix coefficients are zero.
* `ACTION 0x00 = load` — the plurality and the only reading compatible with all
  five surviving store gates (T2); **it ships, and it is no longer FORCED**.
* `escact = 1` (an escape word honours its `lo12`) — 3 178/3 206, 2 310/2 310.

**OPEN**

* ★ `SRC 0x00`: `mem[ptr]` vs `acc`. **30 frame slots.** Decided by whether the
  host ever writes a non-zero gain into the two SINGLE-DELAY input-mix
  coefficients — a *capture*, not a search.
* ★ The tempB `>>1` (item **H**): the biquad requires it, the reverb comb
  forbids it. Three candidates enumerated in `upd6383.cpp`, none chosen.
* `ACTION 0x00`'s capture half (`tA ← acc`, forced inside the comb, item **I**),
  and whether a bit-7-suppressed store clears (T2's §0-C, still the primary half
  of the `ACTION 0x00` question).
* Which comb network, what feeds the ladder, and the 133-word program around it.
* Everything the delay-DRAM family needs (T3 group A, 42 of the 86 dark slots).

---

## 6. What was applied — and what was not

**Nothing gains or loses an executable semantic.** Every word that trapped before
this pass still traps; `alu_decoded()` is unchanged in both mirrors; the ALU is
unchanged. The frame is 285 slots = 108 DECODED + 91 PARTIAL + 86 TRAP, the
closure residue is +0, and no frame completes — all re-measured, `notes/dsp-schroeder-applied.md`.

Applied, and it is all labels and evidence:

1. `ACTION 0x00 = load` relabelled **FORCED → CONSISTENT** in `upd6383d.h` and in
   `dsp/tools/dsp_disasm.py` (`instruction-set.md` already carried T2's banner —
   the two mirrors did not).
2. `ACTION 0x19 = tempA ← bus` keeps its FORCED label, and the comment now records
   the challenge and its withdrawal.
3. The tempB `>>1` comment records the reverb's `tbsh = 0` and enumerates the
   three candidate resolutions.
4. `action_search()` takes `lands=`; `schroeder2` gains rows 8/9/10; section
   `blockread` carries the argument and its four controls.
5. `notes/dsp-closure-applied.md` §5's blocker list is corrected (T3 item E: the
   twelve buckets sum to 179 against a stated 177, and the delay-DRAM bucket is
   42, not 41).

**Not applied, deliberately:** `SRC 0x00` (two values), `ACTION 0x00`'s capture
half (one block, inside a hypothesis), `tbsh = 0` (contradicts a MEASURED
reconstruction), H-DIR (CONSISTENT 4/4, not forced), the delay-DRAM family (two
open unknowns).

---

## 7. Safety

* No behavioural change: the only edits to `src/devices/cpu/upd6383/` are
  comments; `dsp/tools/dsp_disasm.py` likewise. Mirror diff re-run.
* `dsp/verify.py` **BYTE-MATCH OK**; no `.dsm` regenerated.
* DSPCFG **Off** bit-identical to the published build over a capture that carries
  real audio (1 276 567 non-zero samples, peak 22 268); **On** bit-identical to
  Off, so trapped frames still contribute zero.
