# ADJUDICATION, ROUND 5 — the phase and the polarity were ONE parameter, and the delay-DRAM direction is settled backwards

NEC **uPD6383GF-3BA** (Technics SX-KN5000, IC311). Date: **2026-07-27**.
No hardware. Static analysis of the Sub CPU ROM, the 100 canned parameter
streams, the 38 body images and the live emulator only.

Labels: **MEASURED** / **PROVEN BY CONSTRUCTION** / **FORCED** / **CONSISTENT** /
**INFERRED** / **FALSIFIED** / **OPEN**.

Adjudicates the three concurrent round-5 passes —
[`dram-matching.md`](dram-matching.md) (Target 1),
[`dram-direction.md`](dram-direction.md) (Target 2),
[`host-side.md`](host-side.md) (Target 3) — and, through them,
[`r1-allpass-motif.md`](r1-allpass-motif.md),
[`r3-delaydram.md`](r3-delaydram.md),
[`dark-words.md`](dark-words.md),
[`dram-cursor-closure.md`](dram-cursor-closure.md) and
[`adjudication-round4.md`](adjudication-round4.md).

Tool: [`../tools/adjudicate5.py`](../tools/adjudicate5.py) — stdlib plus the
repo's own ROM parsers. **Every number below comes out of it.**

```
python3 dsp/tools/adjudicate5.py phase      #  1 ★★★ three POLARITY-FREE phase oracles
python3 dsp/tools/adjudicate5.py degen      #  2 ★★  the degeneracy that disqualifies 3 arguments
python3 dsp/tools/adjudicate5.py polarity   #  3 ★★★ the polarity, two independent routes
python3 dsp/tools/adjudicate5.py rivals     #  4 ★★★ RULE 7 — scored only where the rivals disagree
python3 dsp/tools/adjudicate5.py null       #  5 the permutation null, and its hole
python3 dsp/tools/adjudicate5.py ladder     #  6 the ladders re-derived, with roles attached
python3 dsp/tools/adjudicate5.py census     #  7 the corpus-wide read/write census
python3 dsp/tools/adjudicate5.py act0b      #  8 ACTION 0x0B under the corrected map
python3 dsp/tools/adjudicate5.py r1         #  9 ★★★ the confrontation with r1 F1
python3 dsp/tools/adjudicate5.py control    # 10 every control, shown saying NO
python3 dsp/tools/adjudicate5.py comb       # 11 the comb prediction, re-derived, NOT tested
python3 dsp/tools/adjudicate5.py all        # ~4 min

python3 dsp/verify.py                                    # BYTE-MATCH OK
~/compartilhado/kn7000_mame/tools/upd6383d_diff.sh       # MIRRORS AGREE 3057/3057
```

**What was applied:** the delay-DRAM **direction**, to both disassembler mirrors
— *and it is the reverse of what they shipped*. Nothing reached the device; the
42 delay-DRAM slots still trap; **0 of 1 344 001 frames complete**.

---

## 0. Result in one page

| # | statement | label |
|---|---|---|
| **A** | ★★★ **THE PHASE AND THE POLARITY ARE ONE PARAMETER, AND THAT IS THE WHOLE COLLISION.** Target 1 FORCES the cell↔word map at `δ = −1` and reads `addr8 0x60` as READ. Target 2 FORCES `addr8` bit 6 as the direction field, finds its own oracle perfect only at `δ = 0`, and leaves the polarity OPEN. Under a cyclic map a shift of `δ` by ONE swaps which member of an alternating read/write pair takes which word — so the two passes were scanning **the same degree of freedom** and reporting it as two. Target 1's phase scan fixed a polarity (`H-ADDR60`) and scanned δ; Target 2's δ sweep fixed nothing and could not see a polarity at all. Neither could close it alone. | **FORCED** (§1) |
| **B** | ★★★ **δ = 0. THE MAP IS THE IDENTITY: the k-th class-1 FORMAT-ESCAPE consumer takes the k-th descriptor cell of its body's block.** Settled by **three oracles that cannot see a polarity**, all three simultaneously perfect at exactly one of thirteen phases: **O1** op-0x67 taps of one algorithm share a direction (10 of 10 algorithms, δ = 0 the only perfect phase); **O2** a tap and its own line base oppose (**28 of 28**, δ = 0 the only perfect phase); **O3** equal-value pairs oppose (**133 of 133** non-C-format, δ = 0 and δ = +2/+3 over smaller populations). Conjunction: **δ = 0 alone**. Permutation null 2000 trials, **0 zero-violation shuffles** (shuffled total violations min 51 / median 71 / max 95). | **FORCED** within the printed model class (§1) |
| **C** | ★★★ **`dram-matching.md`'s `δ = −1` IS FALSIFIED, AND SO IS ITS SUPPORTING DATUM.** At δ = −1: O1 rejects MULTI TAP DELAY, O2 is 27/28, O3 has 5 non-C violations (algos 3, 64, 67, 68, 70). And item I — *"I-RAM 44 is `801.0.25.825`, payload `0x25`, and δ = −1 puts the first unit-0 consumer on cell `0x25`"* — is **DEGENERATE**: a PRE-increment cursor loaded with `0x25` delivers `0x26` to the first consumer, which is δ = 0. The payload cannot choose between (δ = 0, pre-increment) and (δ = −1, post-increment). Method rule 4. | **FALSIFIED** (Target 1's item D and item I-as-evidence) |
| **D** | ★★★ **`addr8` BIT 6 IS THE DELAY-DRAM DIRECTION AND `0x60` IS THE **WRITE**.** Two independent routes, neither touched by the §2 degeneracy. **ROUTE A, counting:** MULTI TAP DELAY has FOUR op-0x67 taps sharing ONE line base (`BASE24 = 2` ×4 ⇒ base address 0); a multi-tap is one write and N reads; the four taps carry `addr8 0x20/0x30` and the shared base carries `0x60`. **ROUTE B, program order, host-free:** at a boundary shared by two ladder segments the READ must take the aged word before the write overwrites it, and the earlier access of **133 of 133** opposite-bit pairs carries bit 6 = 0. | **FORCED** (§3) |
| **E** | ★★★ **`r1-allpass-motif.md` F1 IS FALSIFIED AS STATED — NOT OUTVOTED.** F1 (`880.1.60.2D4` = READ, `36/36`, *"the opposite assignment has zero survivors in every model"*) is forced only inside a model class that **fixed the DRAM read latency**: acceptance test 2 is *"DR at exit == N — the fresh read has landed"* and F6 bounds the landing slot to `[2,5]`, both inside one 8-word repetition. With the descriptors supplied the read issued at slot 4 of a block is consumed at slot 0 of the block **three repetitions — twenty words — later**. `read_slot = 4` was **outside the searched option set**. Method rule 2. | **FALSIFIED** (r1's F1 and F6; r1's algebra F2/F4 and the two families are untouched) |
| **F** | ★★★ **AND `r3-delaydram.md` §6.3, WHICH BOTH DISASSEMBLERS QUOTED AS *REFUTING* THE `addr8` RULE, REFUTES ONLY ITS OLD POLARITY.** Its MULTI TAP observation *"the tap READS land on `880.1.20.2C7` and the line WRITE on `880.1.60.000`"* is **exactly route A** and is now the rule. The disassembler was carrying the right measurement as a falsification of the right hypothesis for two rounds. | **MEASURED**; r3 §6.3 **VINDICATED** |
| **G** | ★★ **RULE 7: the word-blind rival loses 8–0, over 4 algorithms and 5 distinct 36-bit words.** On the **59** host-labelled cells (28 anchored tap/base pairs + MULTI TAP's 4-taps-1-base), `H-ADB6` scores **59 of 59**; `C-PAIRHI` (**knows the oracle**) 56; `C-CELLPAR` (cell-index parity, instruction-blind) 51; `H-ACT0B` 49; `H-SRC0B` (`dark-words`' H-DIR) **12**; the global flip `H-ADB6i` **0**. Scored **only on disagreement sites**: vs `C-CELLPAR` **8–0**, vs `C-CELLPARi` **51–0**, vs `C-PAIRHI` **3–0**, vs `H-SRC0B` **47–0**. Wider than either incoming pass's "four sites, two shapes", and still not a hundred facts. ⚠ **The population is 59 and not 61 because an audit of my OWN scoring set caught a false premise** — see K11. | **MEASURED** (§4) |
| **H** | ★★ **THE LADDER IS RE-DERIVED FROM THE ROLES AND IT CONFIRMS `dram-matching.md` item A WHILE CORRECTING ITS GEOMETRY.** ROOM REVERB 1: pre-delay 800 and eleven segments `83 172 356 513 739 240 119 247 428 616 360`. Ten sit at cell-index offset **+3**; the **eleventh sits at +9**, closing through the `(0x14, 0x1F)` **+11** equal-value pair that `dram-direction.md` §1.3 measured **12 times** and could not explain. **The two passes were holding the two ends of one closure.** | **MEASURED** (§6) |
| **I** | ★★ **THE BRIEF'S OWN `long head 8905` IS STALE (method rule 8).** Every anchored line in ROOM REVERB 1 is ≤ 800 samples and the whole ladder is **3873 samples = 87.8 ms**. `8905` is an `i+1` artefact of the pairing Target 1 already retracted. An impulse test needs a few times **4673** samples, not `4 × 8905 = 35620`. **And the comb topology is NOT decided by the addresses**: a tightly-packed parallel comb bank has the same shared-boundary structure as a series all-pass chain. Neither confirmed nor refuted here. | **FALSIFIED** (the constant); the topology **OPEN** (§11) |
| **J** | ★ **ACTION 0x0B INVERTS, AND CLEANLY.** `dram-matching.md` item J measured **33 READ / 168 WRITE** under (δ = −1, `0x60` = READ) and concluded 0x0B is not the delay-line access. Under (δ = 0, `0x60` = WRITE) the same measurement is **203 READ / 0 WRITE** over the in-scope aligned cells. It is an **implication, not a biconditional** (416 reads, 203 of them 0x0B) and it is **degenerate with `H-ADB6` on this data** — every ACT-0x0B delay word carries `addr8 0x20/0x30`. Item J's numbers must not be quoted as published; 0x0B stays **OPEN**. | **MEASURED**; 0x0B **OPEN** (§8) |
| **K** | ★ **APPLIED: the direction, to BOTH mirrors, REVERSED.** `dsp_disasm.py`'s `DRAM_FORCED = {(0x60,0x2D4):"READ", (0x20,0x655):"WRITE"}` and `upd6383d.cpp`'s matching pair are replaced by `dram_dir()`: `addr8 0x20/0x30 → READ`, `0x60 → WRITE`, anything else → **still trapping**. Frame-floor tier-2 status moves `DETERMINED 18 → 32`, `MEASURED 20 → 6`; **tier-1 and tier-1+2 percentages do not move at all** (38.0 % / 60.6 %) because both are tier 2. **No executable semantic changed. 42 slots still trap.** | **APPLIED** (§12) |
| **L** | ★ **AND WHAT IS STILL MISSING TO MAKE ONE WORD EXECUTE.** The map and the direction are settled; the **rotation register `G`**, the **per-body cursor reload for unit 1**, **which cells are bounds rather than addresses**, and — newly re-opened by item E — the **read latency and the datapath** are not. A delay-DRAM word needs all five. Nothing is applied to the device. | **OPEN** |

---

## 1. ★★★ The phase, settled by three oracles that cannot see a polarity

### 1.1 Why the incoming passes could not close it

`dram_match.map_score()` scores a phase by asking *"does the consumer landing on
the TAP satisfy `rule`, and does the consumer landing on the LINE BASE not?"*
with `rule = H-ADDR60` — **a polarity**. `dram_dir.build()` rotates the same map
and scores pair-opposition — **polarity-free**. Both use the identical sign
convention (`cell (k+δ) ← consumer k`; verified by reproducing both notes'
printed rows). So Target 1 scanned δ with the polarity pinned, and Target 2
scanned δ with the polarity free — and the two answers differ by exactly one,
which is exactly the shift that flips the polarity. **Method rule 2, in the
round that was told to enforce it.**

### 1.2 The three oracles, stated before they were run

* **O1 TAP-COHERENCE.** Every `op-0x67` tap of one algorithm is the same KIND of
  access — they are all `DELAY n (ms)` knobs through one evaluator (Target 3
  E1, 38/38 in `ms`). *Which* kind is not asked.
* **O2 TAP/BASE OPPOSITION.** A delay line has one read end and one write end,
  so a tap and its own `BASE24 − 2` cell are **opposite**. Which is which is not
  asked. (`s = +3` is Target 1's item C and is δ-independent by construction:
  under a rigid +1 cursor `cell(k+s) − cell(k) = s` for every δ.)
* **O3 EQUAL-VALUE PAIR OPPOSITION.** Target 2's own oracle, unchanged.

### 1.3 The sweep

**POPULATIONS (method rule 9):** 91 algorithms ship descriptor cells; **83**
have `#cells == #consumers` and carry every test. O1 population **10**
algorithms (≥ 2 taps); O2 **28** anchored pairs; O3 **136** equal-value pairs,
of which 133 are non-C-format.

```
   delta | O1 tap-coherence | O2 tap/base opp | O3 equal-value opp     | ALL 3
   ------+------------------+-----------------+------------------------+------
     -6  |    5 ok   5 BAD  |  22 ok   6 BAD  |  95/136  non-C  83/100 |
     -5  |    5 ok   5 BAD  |  24 ok   4 BAD  | 119/136  non-C  95/100 |
     -4  |    6 ok   4 BAD  |  21 ok   7 BAD  | 109/136  non-C 106/121 |
     -3  |    6 ok   4 BAD  |  26 ok   2 BAD  | 129/136  non-C 117/121 |
     -2  |    9 ok   1 BAD  |  26 ok   2 BAD  | 119/136  non-C 119/124 |
     -1  |    9 ok   1 BAD  |  27 ok   1 BAD  | 128/136  non-C 128/133 |
     +0  |   10 ok   0 BAD  |  28 ok   0 BAD  | 133/136  non-C 133/133 | *** PERFECT ***
     +1  |    5 ok   5 BAD  |  24 ok   4 BAD  | 132/136  non-C 132/133 |
     +2  |    5 ok   5 BAD  |  25 ok   3 BAD  | 124/136  non-C 124/124 |
     +3  |    4 ok   6 BAD  |  11 ok  17 BAD  | 133/136  non-C 121/121 |
     +4  |    4 ok   6 BAD  |  27 ok   1 BAD  | 119/136  non-C 116/133 |
     +5  |    6 ok   4 BAD  |  14 ok  14 BAD  | 117/136  non-C 105/112 |
     +6  |    6 ok   4 BAD  |  14 ok  14 BAD  | 116/136  non-C 104/112 |
```

**MODEL CLASS, PRINTED BESIDE THE CLAIM (method rule 3):** a rigid 1:1 cyclic
assignment `cell (k+δ) ← consumer k` inside the body's own descriptor block.
`M3` (per-word stride) and `M4` (cell index is a field of the word) were refuted
by Target 1's item G and are not re-run. **`M5` (two cursors, one per direction)
is NOT refuted and is not tested here** — under M5 the reads and the writes each
have their own phase, and the corpus's strict alternation makes the two
indistinguishable. It is the one live alternative to item B and it is named as
such.

### 1.4 ★ And round 4 already agreed

`adjudication-round4.md`'s own applied note says *"`δ = 0` is the best rigid map
and says nothing about whether a rigid map is the right shape"*. It was right
about the phase and its doubt was about the model class, not the value.

---

## 2. ★★ The degeneracy check, run BEFORE any polarity was believed

Physical address of a datum is `desc + s·n` with `s = ±1` — the **rotation
sign**. A read at descriptor `R` returns what was written at `W` with
`delay = s·(W − R)`. Therefore:

* **assignment X**: bit 6 = 1 is the WRITE, and `s = −1` (delay = `R − W`)
* **assignment Y**: bit 6 = 1 is the READ, and `s = +1` (delay = `W − R`)

**X and Y produce the identical set of lines with identical lengths and an
identical memory layout.** Three otherwise attractive arguments are therefore
worth nothing, and are printed so nobody mistakes them later for evidence:

| argument | why it is disqualified |
|---|---|
| **(a)** *"the lines must not OVERLAP in DRAM"* — Target 1's item B | the interval set is **identical** under X and Y; only the labels on the two ends swap. It settles the OFFSET `s = +3` (it did) and **cannot** settle the direction |
| **(b)** *"the fixed end of a knob-swept allocation is the write"* | engineering plausibility; under Y the fixed end is the read and the layout is the same |
| **(c)** *"the chain's unshared low end is the input"* | the chain may run either way through memory — a free binary parameter |

What survives: **exactly two arguments**, §3.

---

## 3. ★★★ The polarity — two independent routes

### ROUTE A — MULTI TAP DELAY, a counting argument

```
   cell 0x26 =   6000   880.1.30.00B  b6=0  <- op-0x67 tap, BASE24=2   DELAY 1 (ms)
   cell 0x27 =  32685   880.1.60.000  b6=1
   cell 0x28 =  12000   880.1.20.2C7  b6=0  <- op-0x67 tap, BASE24=2   DELAY 2
   cell 0x29 =  18000   880.1.20.2C7  b6=0  <- op-0x67 tap, BASE24=2   DELAY 3
   cell 0x2A =  24000   880.1.20.2C7  b6=0  <- op-0x67 tap, BASE24=2   DELAY 4
   cell 0x2B =  32768   880.1.20.2C7  b6=0
   cell 0x2C =      0   880.1.60.000  b6=1  <- BASE24-2 = 0, the SHARED line base
```

**ENUMERATION of what the four could be (method rule 3):**

1. **4 reads + 1 write** — a multi-tap delay. **ADMITTED.**
2. **4 writes + 1 read** — three of the four knobs would be inaudible.
   **REFUTED** by the effect's definition and by the host's four independently
   named `DELAY n (ms)` parameters (Target 3, 38/38 in `ms`).
3. **not accesses at all** — they are the op-0x67 parameter targets and move
   with the knob. **REFUTED.**

⇒ **bit 6 = 0 is the READ.** And the same fact fixes the rotation sign: with the
four taps as reads, `delay = R − W` ⇒ **`s = −1`**, which is what makes the
host's `cell = BASE24 + ms × 44100/1000` put the moving tap **above** the fixed
base in all 38 records.

### ROUTE B — read-before-write at a shared boundary (needs no host data)

Target 2's witness 3 with **the enumeration completed**. Target 2 offered only
*"a zero-delay forward"* or *"a full-period recirculation"* for two accesses at
one descriptor, and missed the option the ladder actually uses:

> ★ **the two accesses belong to two DIFFERENT delay lines that SHARE a boundary
> address:** `A[k]` is the READ end of segment `k` and the WRITE end of segment
> `k+1`.

Under that reading the write is not a recirculation at all, and each line's
delay is set by its **other** end. But the **order** is then forced: both
accesses hit the same physical word in the same frame, so the read must take the
aged content before the write overwrites it. Write-then-read would collapse one
segment's delay to zero — and the segments are 83…739 samples.

**MEASURED:** over the **133** equal-value pairs with opposite bit 6 (population
136 pairs, 83 aligned algorithms) the earlier access in program order carries
bit 6 = 0 in **133** and bit 6 = 1 in **0**.

⇒ **bit 6 = 0 is the READ. Same answer as route A, from disjoint data.**
Target 2 measured the identical **133/133** and inferred the opposite; the
disagreement is entirely in the option set, not in the data.

### The premises, stated

* both routes need `δ = 0`, which §1 forces **without** a polarity;
* route A needs nothing else;
* route B needs *"a physical DRAM word may not be overwritten before the frame's
  read of it"* — a property of any single-port memory, not of this chip.

### ⇒ The deliverable

```
   addr8 bit 6 == 0   (addr8 0x20 / 0x30)  ->  delay-DRAM READ
   addr8 bit 6 == 1   (addr8 0x60)         ->  delay-DRAM WRITE
   rotation sign s = -1:  delay = read_descriptor - write_descriptor
```

**SCOPE, and it is applied that narrowly:** `addr8 ∈ {0x20, 0x30, 0x60}` only.
`C40.1.80.000` carries `addr8 0x80` and is the word Target 2 **proved** no
instruction rule can reach (the identical 36-bit word on both sides of three
pairs). It keeps trapping. 48 of the 829 aligned cells are that word.

---

## 4. ★★★ Rule 7 — scored only where the rivals disagree

**THE SCORING SET carries a polarity and is built from the host and the effect
definitions only** — no instruction field enters it. 28 anchored (tap, base)
pairs with tap = READ and base = WRITE, plus MULTI TAP's four taps and its one
shared base. **POPULATION: 59 labelled cells over 22 algorithms.**

★ **AND THE POPULATION IS 59 BECAUSE AN AUDIT OF MY OWN SET REMOVED TWO SITES.**
The many-taps-one-base branch was written as *"the algorithm has ≥ 2 taps and
exactly one findable base cell"*, and it fired on SINGLE DELAY and
S.DELAY+VIBRATO, **whose two taps are two DIFFERENT lines** (`BASE24` 2 and
16352 — the second base cell is simply missing from the image, which is Target
1's own reported firmware inconsistency). Both sites happened to be labelled
correctly, and that is precisely why the guard matters: *a site that is right by
accident is not evidence.* The branch now requires
`len(set(BASE24 values)) == 1`, which admits MULTI TAP DELAY and nothing else.
Filed as control **K11**.

```
   H-ADB6    addr8 bit6=0 -> READ            (the hypothesis)   59 of 59  100.0%
   C-PAIRHI  higher value in its +3 pair is READ (KNOWS ORACLE) 56        94.9%
   C-CELLPAR cell index EVEN -> READ         (** WORD-BLIND **) 51        86.4%
   H-ACT0B   ACTION 0x0B -> READ                                49        83.1%
   C-LO0     lo12 bit0 set -> READ           (** nonsense **)   43        72.9%
   C-VALMED  value above algo median -> READ (** WORD-BLIND **) 34        57.6%
   C-ALLR    everything is a READ            (** cannot fail **)31        52.5%
   H-HI7     hi12 bit7 -> WRITE   (store-gate D, extended)      25        42.4%
   H-SRC0B   SRC 0x0B -> READ    (dark-words H-DIR)             12        20.3%
   C-CELLPARi cell index ODD -> READ         (** WORD-BLIND **)  8        13.6%
   H-ADB6i   addr8 bit6=1 -> READ            (** global flip **) 0         0.0%

   HEAD TO HEAD, only on the sites where the two rules DISAGREE:
      vs C-CELLPAR   n= 8    H  8 : 0        <- ★ the one that matters
      vs C-CELLPARi  n=51    H 51 : 0
      vs C-PAIRHI    n= 3    H  3 : 0
      vs C-ALLR      n=28    H 28 : 0
      vs C-LO0       n=16    H 16 : 0
      vs C-VALMED    n=25    H 25 : 0
      vs H-ACT0B     n=10    H 10 : 0
      vs H-HI7       n=34    H 34 : 0
      vs H-SRC0B     n=47    H 47 : 0
      vs H-ADB6i     n=59    H 59 : 0
```

The eight sites where the **word-blind** rival differs, printed in full:

| algo | cell | idx | word | truth | `H-ADB6` | `C-CELLPAR` |
|---|---|---|---|---|---|---|
| 10 MULTI TAP DELAY | `0x29` | 3 | `880.1.20.2C7` | R | R | W |
| 10 MULTI TAP DELAY | `0x2C` | 6 | `880.1.60.000` | W | W | R |
| 64 S.DELAY+CHORUS | `0x2D` | 7 | `880.1.30.407` | R | R | W |
| 64 S.DELAY+CHORUS | `0x30` | 10 | `900.1.60.1D5` | W | W | R |
| 68 S.DELAY+PHASER | `0x29` | 3 | `880.1.30.000` | R | R | W |
| 68 S.DELAY+PHASER | `0x2C` | 6 | `880.1.60.447` | W | W | R |
| 70 AUTO WAH+S.DELAY | `0x29` | 3 | `880.1.30.000` | R | R | W |
| 70 AUTO WAH+S.DELAY | `0x2C` | 6 | `880.1.60.000` | W | W | R |

**THE DISCOUNT THIS PASS APPLIES TO ITSELF** (Target 2's discipline, turned
inward): eight sites, **4 algorithms**, **5 distinct 36-bit words**
(`880.1.20.2C7`, `880.1.30.000`, `880.1.30.407`, `880.1.60.000`,
`880.1.60.447`, `900.1.60.1D5`). That is wider than either incoming pass's
*"four sites, two shapes"*, and it is still not a hundred facts. Note also that
four of the eight are `MULTI TAP` / `S.DELAY+PHASER` / `AUTO WAH+S.DELAY` at cell
index 3 — the same **cell-index offset +4** geometry Target 2 identified as the
only place where the reverb ladder's parity breaks.

`C-PAIRHI` **knows the oracle** on the anchored subset — a tap is always above
its own base by construction — and is included for exactly that reason
(Target 2's `C-DUPLO`, same role). What separates `H-ADB6` from it is
**coverage**, a count and not a score: `C-PAIRHI` is undefined on the 773 cells
with no anchored partner; `H-ADB6` labels all 781 in-scope aligned cells.

---

## 5. Nulls, and the hole in one of them

```
   PERMUTATION (2000 trials).  Shuffle which word takes which cell inside each
   algorithm; multiset of words and all values preserved.
      real corpus at delta = 0: O1 10/10, O2 28/28, O3 non-C 133/133
      shuffled TOTAL violations: min 51, median 71, max 95
      zero-violation shuffles: 0 of 2000
```

★ **AND ITS HOLE, STATED (method rule 1).** This null shuffles *words*, so it has
**no power against an instruction-blind rival** — `C-CELLPAR` scores the same in
every shuffle. It prices the phase against **noise** only. The rival test is §4
and the polarity test is §3, and neither is this null.

**NULL 2, the sweep is its own control:** 13 phases tried, the conjunction is
satisfied at exactly one. **Twelve of thirteen FAIL**, so the test demonstrably
can say no.

---

## 6. The ladders, re-derived from the ROLES (method rule 8)

The read/write roles now come from §3, so the ladder is a **consequence** of the
decode and not an input to it. Line-pairing rule, stated before it was run: with
`s = −1` a read's own write is the WRITE cell with the **largest value strictly
below it** — the minimal positive delay; nothing else can be its write without
swallowing another line.

**ROOM REVERB 1** (unit 1, 32 cells):

```
   READ cells  (b6=0): 00 02 04 06 08 0A 0C 0E 10 12 14 16 18 1B 1E
   WRITE cells (b6=1): 01 03 05 07 09 0B 0D 0F 11 13 15 17 1F
   (0x19 0x1A 0x1C 0x1D are C40.1.80.000 -- OUT OF SCOPE, still trapping)

   write 03  32768 -> read 00  33568 =  800   the PRE-DELAY   (offset +3)
   write 05  41590 -> read 02  41673 =   83   |               (offset +3)
   write 07  41673 -> read 04  41845 =  172   |
   write 09  41845 -> read 06  42201 =  356   |
   write 0B  42201 -> read 08  42714 =  513   |
   write 0D  42714 -> read 0A  43453 =  739   |  the ELEVEN
   write 0F  43453 -> read 0C  43693 =  240   |  ABUTTING
   write 11  43693 -> read 0E  43812 =  119   |  SEGMENTS
   write 13  43812 -> read 10  44059 =  247   |
   write 15  44059 -> read 12  44487 =  428   |
   write 17  44487 -> read 14  45103 =  616   |               (offset +3)
   write 1F  45103 -> read 16  45463 =  360   |               (offset +9) ***
   write 03  32768 -> read 18  33418 =  650   ) taps off the PRE-DELAY line
   write 03  32768 -> read 1B  33308 =  540   )  (early reflections; four more
                                              )   are C40 and undecided)
```

★ **THE +9 IS THE POINT.** Ten segments sit at cell-index offset **+3** — Target
1's anchor — and the **eleventh sits at +9**, closing through the `(0x14, 0x1F)`
**+11** equal-value pair that Target 2 measured in **12 of 12** reverbs and
listed among the *"structural"* pairs it could not interpret. **The two passes
were holding the two ends of one closure.** Target 1's *"through the wrap"* was
the right instinct with the wrong mechanism.

**PLATE REVERB 1** reproduces identically: pre-delay 2000, segments
`335 569 1107 1074 2495 600 512 870 1078 1669 800`, plus six pre-delay taps.

⚠ **HONEST LIMIT.** Cells that are region BOUNDS or SENTINELS (`0`, `32767`,
`32768`, the per-unit ceiling) are handed to consumers like any other cell, and
the nearest-write rule pairs them into "lines" that are not lines — SINGLE
DELAY's `897` and PLATE REVERB's `32767` are both of those. `adjudication-round4`
item B's missing option *"a consumer may take a NON-ADDRESS operand"* (which
Target 2's audit correctly identified) is exactly this, and it is still **OPEN**:
nothing here says **which** cells are bounds. Corpus-wide with the roles applied
(population **75** algorithms, **446** lines): **20** algorithms still contain an
overlapping pair, **132** abutting joins.

---

## 7. The census — and it inverts the published one

**POPULATION: 829 aligned cells over 83 algorithms** (of the 91 that ship cells;
the 8 unaligned ones have `#cells ≠ #consumers`). **IN SCOPE: 781.**
**READ 416 (53.3 %) · WRITE 365 (46.7 %) · out of scope, still trapping: 48.**

```
   880.1.20.64B  READ  x141      880.1.60.2D4  WRITE x115
   880.1.20.655  READ  x115      880.1.60.2D9  WRITE x103
   880.1.30.00B  READ  x62       880.1.60.000  WRITE x63
   880.1.20.2C7  READ  x37       880.1.60.2DA  WRITE x38
   880.1.20.2D5  READ  x24       900.1.60.1D5  WRITE x32
   880.1.30.8BC  READ  x14       880.1.60.40E  WRITE x12
   880.1.30.407  READ  x11       880.1.60.41A  WRITE x1
   880.1.30.000  READ  x10       880.1.60.447  WRITE x1
   880.1.30.647  READ  x1        880.1.30.447  READ  x1
   C40.1.80.000  TRAP  x48   <- out of scope
```

★ **This inverts `dram-direction.md` §7.3's replacement census**, which put
`880.1.60.000` (×63) and `900.1.60.1D5` (×32) on the READ side. They are WRITES.
`dark-words.md` item F's consequence — *"99 of 276 delay-DRAM words are reads
under H-DIR"* — is retired along with `H-DIR` itself, which scores **12 of 61**
on the host-labelled set and is not merely incomplete but **anti-correlated**.

---

## 8. ACTION 0x0B

`dram-matching.md` item J: **33 READ / 168 WRITE** under (δ = −1, `0x60` = READ),
concluding *"ACTION 0x0B is NOT the delay-line access"*. Under (δ = 0,
`0x60` = WRITE): **203 READ / 0 WRITE**, over the in-scope aligned cells.

The **conclusion is unchanged** — 0x0B is not a biconditional for either role
(416 reads, 203 of them 0x0B) — but the asymmetry has swapped sides, so item J's
numbers must not be quoted as published. And on this data **ACT 0x0B ⇒ READ is
DEGENERATE with `H-ADB6`**: every ACT-0x0B delay word carries `addr8 0x20/0x30`.
It adds nothing and it is not independent evidence. **0x0B stays OPEN.**

---

## 9. ★★★ r1 F1 — where it fixed a parameter instead of enumerating it

`r1-allpass-motif.md`'s motif is the 8-word block repeating from word 19 of ROOM
REVERB 1's body image, and it matches the image byte for byte. With `δ = 0` each
DRAM word's descriptor cell is known — which r1's solve never had:

```
   block @w19   slot0 w19  880.1.60.2D4  cell 03 = 32768  WRITE
                slot4 w23  880.1.20.655  cell 04 = 41845  READ
   block @w27   slot0 w27  880.1.60.2D4  cell 05 = 41590  WRITE
                slot4 w31  880.1.20.655  cell 06 = 42201  READ
   block @w35   slot0 w35  880.1.60.2D4  cell 07 = 41673  WRITE
                slot4 w39  880.1.20.655  cell 08 = 42714  READ
   block @w43   slot0 w43  880.1.60.2D4  cell 09 = 41845  WRITE
                slot4 w47  880.1.20.655  cell 0A = 43453  READ
```

Under F1 (slot 0 = READ), block *N* reads `A[N−2]` and writes `A[N+1]`, and the
value written at descriptor `A[k]` is read back at `A[k]` **five consumers later
in the same frame at the same physical word** — one segment's delay collapses to
zero.

**WHERE THE SEARCH EXCLUDED THE ANSWER**, quoting r1's own §4.4: acceptance test
2 is *"DR at exit == N — the fresh read has landed"*, and F6 bounds the landing
slot to `[2,5]`. Both fix the DRAM read latency to **inside one 8-word
repetition**. Under the descriptor-anchored reading the read issued at slot 4 of
a block is consumed at slot 0 of the block **three repetitions — twenty words —
later**. `read_slot = 4` is therefore not *"refuted 36/36"*; it is **outside the
searched model class**. Method rule 2, and it is the third time an unenumerated
parameter has produced a false forcing on this chip.

**VERDICT: F1 → FALSIFIED AS STATED; F6 → withdrawn.** r1's *algebra* is not
touched — F2 (`store = old`), F4, and the two machine families stand; only the
read/write labelling of slots 0 and 4 and the latency bound move. **Named next
experiment:** re-run `r1_allpass_solve.py` with `land ∈ [6, 24]` and the
descriptor addresses supplied as constraints.

---

## 10. What moves in the other notes

| source | claim | was | now |
|---|---|---|---|
| `dram-matching.md` D | `cell = (consumer index − 1) mod n`, δ = −1 | **FORCED** | ★ **FALSIFIED** — the identity map, §1 |
| `dram-matching.md` I | I-RAM 44 payload `0x25` supports δ = −1 | CONSISTENT | ★ **DEGENERATE** with pre/post-increment; withdrawn as phase evidence, survives as the reload value |
| `dram-matching.md` F | `H-ADDR60`: `0x60` = READ | CONSISTENT | ★ **the FIELD is right, the POLARITY is inverted** |
| `dram-matching.md` J | ACT 0x0B: 33 R / 168 W | MEASURED | ★ **203 R / 0 W**; conclusion unchanged, numbers retracted |
| `dram-matching.md` A, B, C, B2 | the +3 anchor, `BASE24`, the retraction of the `i+1` ladder, the 8820-sample pre-delay headroom | FORCED / MEASURED | ★ **ALL SURVIVE** and are re-derived here. Item A's ladder is confirmed with the +9 correction of item H |
| `dram-direction.md` B | `addr8` bit 6 is the direction field | FORCED | ★ **SURVIVES**, and the polarity closes against it |
| `dram-direction.md` G | polarity OPEN, vote 2–1 for `0x60` = READ | OPEN | ★ **CLOSED for `0x60` = WRITE.** Witness 1 (r1 F1) falsified; witness 3's *measurement* (133/133) is kept and its *inference* reversed by the missing enumeration option; witness 2 (r3 §6.3) wins |
| `dram-direction.md` C, H, I | `H-DIR` falsified; bit-7 extension excluded; the 62/10 retraction | FALSIFIED | ★ **ALL SURVIVE**, and `H-DIR` is now measured at **12 of 61**, anti-correlated |
| `dram-direction.md` §7.3 | the replacement census, 365 reads | MEASURED | ★ **INVERTED** — those are the writes |
| `host-side.md` (all) | the opcode→space map, relocation base 0, op-0x74's 36-cell table, the auto-increment, MALFORMED = DSP2, the READY line | PROVEN / MEASURED | ★ **ALL SURVIVE UNTOUCHED.** Nothing in this adjudication contradicts Target 3, and its opcode→name binding is what makes route A a measurement rather than a guess |
| `r1-allpass-motif.md` F1, F6 | `880.1.60.2D4` = READ; land ∈ [2,5] | FORCED | ★ **FALSIFIED AS STATED**, §9 |
| `r3-delaydram.md` §6.3 | *"`addr8` does NOT select the DRAM direction"* | a constraint | ★ **VINDICATED as a polarity refutation**; the field stands and r3's MULTI TAP reading is now the rule |
| `adjudication-round4.md` B | the rigid map is FORCED-refuted | FORCED → CONSISTENT (Target 2) | ★ the rigid map is **RE-FORCED** at δ = 0; the *"interior non-address cell"* objection is re-labelled as the OPEN bounds question |
| the round-5 brief itself | ROOM REVERB 1's *"long head 8905"* | quoted | ★ **STALE** — an `i+1` artefact; ladder total 3873, longest anchored line 800 |

---

## 11. The comb prediction — re-derived, and NOT tested

The brief asks for an impulse test *"if the delay line executes"*. **It does
not**: nothing in this round reaches the device, the 42 delay-DRAM slots still
trap, and 0 of 1 344 001 frames complete. What is delivered is the prediction
with its constants re-derived:

```
   ROOM REVERB 1   pre-delay 800 samples (18.14 ms)
                   ladder    83 119 172 240 247 356 360 428 513 616 739
                   TOTAL     3873 samples = 87.82 ms
                   pre-delay taps (decodable) 540, 650, 800
   ==> an impulse test needs a few times 4673 samples, NOT 4 x 8905 = 35620
```

★ **AND THE TOPOLOGY IS NOT DECIDED BY THE ADDRESSES** (method rule 1, applied
to a conclusion I wanted). A shared boundary address `A[k]` follows from an
allocator packing buffers **tightly**, and a tightly-packed parallel comb bank
has exactly the same address structure as a series all-pass chain. So *"the
reverb core is a comb network"* is **neither confirmed nor refuted here** — the
addresses are silent and the ALU is what would speak. The §3 polarity argument
does **not** depend on the topology: it needs only that the two accesses hit one
physical word.

---

## 12. What was applied, and the before/after

**Applied to both disassembler mirrors and nowhere else.**

* `dsp/tools/dsp_disasm.py`: `DRAM_FORCED = {(0x60,0x2D4):"READ",
  (0x20,0x655):"WRITE"}` → `dram_dir(w)`: `addr8 0x20/0x30 → READ`,
  `0x60 → WRITE`, else `None` (**keeps trapping**).
* `src/devices/cpu/upd6383/upd6383d.{cpp,h}`: the same, with the full
  provenance — including the r1 conflict — in the comment.
* Both annotation strings rewritten; the "DIRECTION UNKNOWN — `addr8` does NOT
  select it" text is removed because it is false.
* **No executable predicate changed**: `decoded()`, `addressing_only()` and
  `has_addressing()` are untouched, so the device's behaviour is unchanged **by
  construction**.

| | before | after |
|---|---|---|
| frame floor tier 1 | 82 of 216, **38.0 %** | 82, **38.0 %** |
| frame floor tier 1+2 | **60.6 %** | **60.6 %** |
| 38 body images (2974 words) | 1234 tier 1, **41.5 % / 52.6 %** | identical |
| frame-floor tier-2 `DETERMINED` | 18 | ★ **32** |
| frame-floor tier-2 `MEASURED` | 20 | ★ **6** |
| frame-floor tier-2 `PARTIAL` | 11 | 11 |
| distinct undecoded words | 443 | 443 |
| `dsp/verify.py` | BYTE-MATCH OK | ★ **BYTE-MATCH OK** (39 `.dsm` regenerated) |
| `upd6383d_diff.sh` | MIRRORS AGREE 3057/3057 | ★ **MIRRORS AGREE 3057/3057** |

The live tally is in
[`kn7000_mame/notes/dsp-adjudication-round5-applied.md`](../../../kn7000_mame/notes/dsp-adjudication-round5-applied.md).

---

## 13. Controls, each shown saying NO

| # | control | shown rejecting |
|---|---|---|
| **K1** | the δ sweep | 12 of 13 phases violate at least one oracle; the conjunction is empty except at 0 |
| **K2** | O1 tap-coherence | rejects MULTI TAP at δ = −1 and six of ten at δ = +3 |
| **K3** | the **global flip** `H-ADB6i` | scored explicitly, **0 of 61** — the polarity is not assumed |
| **K4** | the word-blind `C-CELLPAR`, **in both polarities** | 52/61 and 9/61, beaten **9–0** and **52–0** on the disagreement sites |
| **K5** | `C-PAIRHI`, which **knows the oracle** | included precisely because it cannot lose on the anchored subset; reported as a limit of the instrument |
| **K6** | the **degeneracy check** | disqualifies three arguments before they are used, **including Target 1's own "the lines must not overlap"** |
| **K7** | `C-ALLR`, `C-LO0` | 33/61 and 44/61 — the tournament is not a walkover by construction |
| **K8** | the permutation null | its **hole** against word-blind rivals is printed, not left to be found |
| **K9** | MULTI TAP's thinness | it is the **single** site separating δ = 0 from δ = −1 on O1 and O2 — which is why §3 carries a second, host-free route over 133 pairs |
| **K10** | rule 8 | every constant quoted is re-derived from the ROM in the same run; the brief's own `8905` fails it |
| **K11** | ★ **an audit of MY OWN scoring set** | the many-taps-one-base branch fired on two algorithms whose taps are two different lines; both sites were labelled *correctly*, and they were removed anyway. 61 → **59**, `C-CELLPAR` disagreements 9 → **8**. A site that is right by accident is not evidence |

---

## 14. PREDICT-THEN-CHECK — 4 hits, 6 misses

| # | prediction | outcome |
|---|---|---|
| **P1** | The three passes would collide on the *polarity*, and the resolution would be a mechanism nobody enumerated. | ★★ **HIT on the shape, MISS on the location.** The collision was the **phase**, and the polarity turned out to be the same parameter. |
| **P2** | Target 1's δ = −1 would win, because it had the host anchor and Target 2 did not. | ★★★ **MISS, and it is the pass's whole content.** The host anchor is polarity-free and it selects δ = 0; Target 1's δ = −1 came from scoring the phase with a polarity **fixed**. |
| **P3** | The polarity would stay OPEN and this round would ship nothing, like two of the last three. | ★★ **MISS.** Two independent routes close it, and something shipped — a **reversal**. |
| **P4** | `r1`'s F1 would survive as the senior result and I would have to explain the descriptors around it. | ★★★ **MISS, the most consequential.** F1 fixed the read latency in its acceptance test; `read_slot = 4` was never in the option set. |
| **P5** | The "no-overlap" argument would help decide the direction. | ★★ **MISS, caught by my own §2 control before it was used.** X and Y give the identical memory layout; it is worth nothing for direction. |
| **P6** | The `H-ADB6` vs `C-CELLPAR` disagreement set would stay at Target 2's four sites. | ★ **HIT, better than predicted.** The host-labelled set widens it to **nine** sites over five algorithms. |
| **P7** | ACTION 0x0B would become decodable once the polarity was fixed. | ★ **HIT that it becomes one-sided (203/0), MISS as a decode**: it is **degenerate** with `addr8` bit 6 on this data and adds nothing. |
| **P8** | Applying the direction would recover dark slots. | ★ **HIT (negative), as expected.** Zero. The rotation register, the unit-1 cursor reload, the bounds question and — now — the datapath are all still open. |
| **P9** | The ladder would come out with all eleven segments at offset +3. | ★★ **MISS.** Ten at +3, the eleventh at **+9**, and that miss is what explains Target 2's unexplained `+11` pairs. |
| **P10** | The brief's own constants would hold, since they were re-derived last round. | ★ **MISS.** `8905` is stale — a retracted pairing's artefact that survived into the brief. |

---

## 15. For the next round

1. **RANK 1, and the host firmware DOES already name it:** the **bounds
   question**. `adjudication-round4` item H measured *"76 of 91 algorithms ship
   exactly two region-boundary cells"*; §6 shows those cells are handed to
   consumers exactly like addresses and produce fake lines. The host writes them
   through the same op-0x67/tag-0x4C path, so **`host_side.py regmap` can be
   asked which opcode writes them and what the UI calls it** — the same lever
   that solved this round. If a bound cell has no UI name while every address
   cell has one, the split falls out for free.
2. **RANK 2:** re-run `r1_allpass_solve.py` with `land ∈ [6, 24]`, `read_slot`
   free, **and the descriptor addresses supplied as constraints**. This is
   Target 2's own proposed experiment #2 and §9 makes it decisive rather than
   confirmatory. It is what would give the delay-DRAM words a **datapath**, which
   is the last thing between them and execution.
3. **RANK 3:** the **unit-1 cursor reload**. Under δ = 0 the unit-0 body's first
   consumer takes cell `0x26`, which a pre-increment cursor loaded with `0x25`
   (I-RAM 44, `801.0.25.825`) delivers exactly. Unit 1's first consumer needs
   `0x00` and I-RAM 52 loads the same `0x25`. One of the two is not the reload,
   or the reload is conditional.
4. **RANK 4:** model **M5** — two cursors, one per direction — is the one
   alternative to the identity map that this round did **not** refute, because
   the corpus's strict read/write alternation makes M5 and M2 indistinguishable.
   The place to break it is an algorithm with unequal read and write counts.
5. **Everyone:** `dark-words.md` item F and its census paragraph should be
   deleted, not amended. `r1-allpass-motif.md`'s F1/F6 rows and the `dramrd` /
   `dramwr` labels in its §6 table need the reversal.
