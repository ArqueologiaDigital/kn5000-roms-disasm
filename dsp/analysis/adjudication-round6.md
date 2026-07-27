# ADJUDICATION, ROUND 6 — the polarity was reversed two rounds ago and nobody re-ran the searches that had already shipped

NEC **uPD6383GF-3BA** (Technics SX-KN5000, IC311). Date: **2026-07-27**.
No hardware. Static analysis of the Sub CPU ROM, the 100 canned parameter
streams, the 38 body images and the live emulator only.

Labels: **MEASURED** / **PROVEN BY CONSTRUCTION** / **FORCED** / **CONSISTENT** /
**INFERRED** / **FALSIFIED** / **OPEN**.

Adjudicates the four concurrent round-6 passes —
[`dram-bounds.md`](dram-bounds.md) (T1),
[`dram-datapath.md`](dram-datapath.md) (T2),
[`dram-unit-cursor.md`](dram-unit-cursor.md) (T3),
[`second-dsp-and-ready.md`](second-dsp-and-ready.md) (T4) — and, through them,
[`adjudication-round5.md`](adjudication-round5.md),
[`blocking-read.md`](blocking-read.md),
[`action-field.md`](action-field.md),
[`acc-adder.md`](acc-adder.md),
[`action00-discriminator.md`](action00-discriminator.md) and
[`schroeder-topology.md`](schroeder-topology.md).

Tool: [`../tools/adjudicate6.py`](../tools/adjudicate6.py) — stdlib plus the
repo's own ROM parsers. **Every number below comes out of it.**

```
python3 dsp/tools/adjudicate6.py census    #  1     populations, reproduced independently
python3 dsp/tools/adjudicate6.py degen     #  2 ★★  rule 4 / rule 7 on T2's two dummies
python3 dsp/tools/adjudicate6.py polarity  #  3 ★★★ THE ROUND: the harness audit
python3 dsp/tools/adjudicate6.py enum      #  4 ★★  the widened enumeration, E2' and E7
python3 dsp/tools/adjudicate6.py wtrail    #  5     the write trail, FORCED subset vs all
python3 dsp/tools/adjudicate6.py latency   #  6 ★   `land' -- the two ends, two units
python3 dsp/tools/adjudicate6.py ladder    #  7     ROOM REVERB 1 re-derived (rule 8)
python3 dsp/tools/adjudicate6.py cursor    #  8     T3's pointer census, reproduced
python3 dsp/tools/adjudicate6.py control   #  9 ★★  every control, shown saying NO
python3 dsp/tools/adjudicate6.py predict   # 10     PREDICT-THEN-CHECK, hits AND misses
python3 dsp/tools/adjudicate6.py all       # ~3 min

python3 dsp/verify.py                                    # BYTE-MATCH OK
~/compartilhado/kn7000_mame/tools/upd6383d_diff.sh       # MIRRORS AGREE 3057/3057
```

**What was applied:** three **labels**, to the device and to both disassembler
mirrors. **No executable predicate changed, and the rebuilt binary is
BYTE-IDENTICAL** (`md5 965976f50bbfa11299d1449caca7d336`) to the published one
after a full recompile and relink. **Zero dark slots recovered; the 42
delay-DRAM slots still trap; 0 of 1 536 349 frames complete.**

---

## 0. Result in one page

**POPULATIONS (method rule 9), printed once and used everywhere below:**
**91** algorithms are IC311 programs (T4 — nine of the 100 slots are IC310
streams); **91** ship descriptor cells, **83** of them aligned
(`#cells == #consumers`) carrying **829** cells; **324** delay lines; **38**
distinct body images / **2974** words; **3057** corpus words; **285** live frame
slots; **94** corpus ACTION-0x19 sites.

| # | statement | label |
|---|---|---|
| **A** | ★★★ **EVERY ALU FORCING THAT TOUCHES THE DELAY PORT WAS COMPUTED WITH THE LINE WIRED BACKWARDS, AND ONE OF THEM IS IN THE DEVICE.** `action00_discriminate.sd_run()` and `acc_adjudicate.sd_run()` both contain, verbatim, `if (addr8(w) & 0xf0) == 0x20: ln.write(bus) else: s.dr = ln.read()` — `addr8 0x20 → WRITE, 0x60 → READ`, which is the polarity `adjudication-round5` item **D** FORCED **in reverse**. Round 5 reported *"no executable semantic changed"*: true of the edit it made, and it did not audit the semantics that had already shipped. **SINGLE DELAY is the only published ALU context that carries delay-DRAM words** — of the 94 corpus ACTION-0x19 sites, **92** sit in DRAM-carrying images and the only DRAM-free one is algo 88, which T4 showed is an **IC310** stream, not an IC311 program. Re-run at the corrected polarity, the same harness, same space (5832), same reference, same seeds: **108 → 0.** | **MEASURED** (§3) |
| **B** | ★★★ **AND THE ZERO IS A HARNESS ARTEFACT TOO, DEMONSTRATED NOT ARGUED.** The harness's `Line` reads and writes **one cell** and advances once per frame, so it silently *requires* READ-before-WRITE in program order — a modelling choice never enumerated (method rule 3). Corrected, SINGLE DELAY's `w5` (`addr8 0x60`) **writes** and `w9` (`0x20`) **reads**, so the read returns the value written in that very frame: **port order `WR`, read returns 1000, 1001, 1002 … — delay 0, the loop is gone.** ⇒ **BOTH the 108 and the 0 are void.** | **PROVEN BY CONSTRUCTION** (§3) |
| **C** | ★★★ **CONSEQUENCE, AND IT IS THE ROUND'S DELIVERABLE.** `ACTION 0x19 = tempA ← bus` — the device's `LO_ACT_CAP_TA2`, shipped as *"FORCED 72/72 by SINGLE DELAY (108/108 in the wider space)"* — **is UNFORCED.** `blocking-read.md` item **D**, which withdrew `schroeder-topology.md` §0-C's conditional falsification of exactly that reading *because the comb search "omitted the BLOCKING read SINGLE DELAY forces"*, **loses its premise: that challenge is RE-OPENED.** `acc-adder.md`'s adder is a **reconciliation of the LFO with SINGLE DELAY** and one of its two legs is void. | **FALSIFIED** (the forcings); the semantics **not refuted** |
| **D** | ★★ **NOTHING IS REVERTED, AND THAT IS A DECISION, NOT AN OVERSIGHT.** Withdrawing `LO_ACT_CAP_TA2` would re-trap corpus words on the authority of a harness that **provably cannot model the corrected machine** — the method-rule-1 defect pointing the other way. The semantics are relabelled **CONSISTENT** in the device and in both mirrors, with the full provenance; the behaviour is untouched and the binary is byte-identical. **This is a live method-rule-6 exposure and it is named as one.** | **APPLIED** (labels only, §11) |
| **E** | ★★★ **T2 ITEM A's CEILING HALF IS DEGENERATE WITH A POSITIONAL RIVAL — METHOD RULE 4 AND RULE 7.** *"The CEILING is the LAST READ of its program, 83 of 83 … arrived at from a completely different direction"* and T1's already-published *"position: relative index n−2 in 75, n−1 in the 8 with n = 2"* have **ZERO disagreement sites over 83**, because the last READ of the block **is** at rel n−2/n−1 in **83 of 83**. T2's permutation null (0 of 2000; my re-run maxes at **35 of 83**) rejects a null that ignores position and cannot separate the flush reading from *"the allocator emits the ceiling second-from-last"*. **T1 reported this non-separation about its own result; T2 did not.** | **MEASURED**; T2 item A's CEILING half **CONSISTENT** (§2) |
| **F** | ★★ **THE LIMIT HALF DOES SEPARATE, AND BY EXACTLY ONE SITE.** `first WRITE` **74 of 74** versus `rel 1` **73 of 74**; the single disagreement is **ENHANCER** (`n = 8`, `RRRWRWRW`, first write at rel 3) and the direction-aware rule wins it **1–0**. Real evidence, one site wide, and printed as such — the same order of thinness round 5 flagged in its own K9. It still inherits `bounds.py`'s **FORCED-WITHIN-THE-ALLOCATION-MODEL** label, because `bounds.py` assigns LIMIT as the *residue* of model A4. | **MEASURED** (§2) |
| **G** | ★★ **THE ENUMERATION FOR THE TWO DUMMIES WAS MISSING TWO MEMBERS; I REFUTED ONE OF THEM MYSELF.** **E2′** — a per-frame-persistent **limit register loaded at the tail for the NEXT frame** — is not in T2's `E1…E5`, and T2's rejection of `E2` (*"a limit must be loaded before the accesses it bounds"*) is only true **inside one frame**, while the body is a loop executed 1 536 349 times. E2′ also explains what E1 leaves arbitrary: the ceiling's value is not any harmless address, it is exactly the per-unit partition boundary. ★ **And the control I built expecting it to support E2′ REFUTES it:** the ceiling word is byte-identically a **real line read** elsewhere in **82 of 83** cases, and the limit word a **real line write** in **74 of 74** — the dummies use *ordinary access instructions*, so no register-load opcode exists. **E7** — the address **wraps** and the last read is real — is **ADMITTED and NOT separated**. | **MEASURED**; E2′ **FALSIFIED**; E7 **OPEN** (§4) |
| **H** | ★ **T2 ITEM E's `land ∈ [1, 4]` HAS ITS TWO ENDS IN DIFFERENT UNITS — the rule-10 failure mode, inside one pass.** Item A's mechanism is stated in **PORT SLOTS** (exactly one trailing flush ⇒ the port is one deep ⇒ read *k* becomes visible when read *k+1* **issues**, a position, not a word count). Item E's bound is stated in **WORDS** (`land ≤ 4` = the corpus minimum READ → next `SRC 0x0B`) and needs a premise **not in the enumeration**: that the first `SRC 0x0B` after a read consumes *that* read — the very staleness the same pass's `wtrail = 2` says the machine tolerates. Taking item A literally instead gives `land ≤ min(READ → next DRAM word) =` **2**, tighter than 4, out of T2's own table. | **MEASURED**; the latency **OPEN** (§6) |
| **I** | ★ **T2 ITEM B's `wtrail` CORRECTION GOES BOTH WAYS, AND BOTH ARE PRINTED.** Corpus-wide `+3` is **273 of 324** (reproduced) but on host-anchored lines it is **30 of 63** — the 84.3 % is carried by model-derived pairings. **However**, 46 of those 63 are **multi-tap reads sharing one base**, and a tap has no write of its own, so the statement is not even defined for them. On host-anchored lines that are **one read on one base** it is **17 of 17**, exceptionless. ⇒ **FORCED on 17 lines, CONSISTENT on 307**, and the one-page label should carry that denominator. | **MEASURED** (§5) |
| **J** | ★ **T3's VERDICT DOES NOT TOUCH T2, AND T3 SAID SO CORRECTLY.** The pointer census reproduces exactly — **three** writes to the descriptor pointer (`HDR 44`, `HDR 52`, `EPI 62`), **zero** inside any of the 38 body images — so there is nowhere to keep a per-algorithm second cursor and M5 dies by counting. M5 was the one live **rival** to the `δ = 0` identity map T2 assumes, so killing it **strengthens** T2. No adjudication needed. | **MEASURED**; T3 **UPHELD** (§8) |
| **K** | ★ **T4 SURVIVES INTACT.** `retraction_sweep.py` carries P17 (H-DIR / *99 of 276*) and P18 (the *"both chips"* claim) and both report **0 LIVE sites** — checked. The census (416/365/48), the ladder and the pointer count all reproduce. Nothing of T4 moves. | **MEASURED** |
| **L** | ★★ **AND A RULE-8/RULE-9 CATCH ON THE LADDER EVERYBODY QUOTES.** ROOM REVERB 1's `800 + 83 172 356 513 739 240 119 247 428 616 360 = 3873 samples = 87.82 ms` is re-derived here from the ROM — and **ROOM REVERB 1 carries EXACTLY ONE host `op-0x67` tap**, so the 800-sample pre-delay is its **only host-anchored line** and **all eleven ladder segments are model output**. An impulse test sized on 3873 is sized on a **CONSISTENT** number. Longest path pre-delay + ladder = **4673 samples = 105.96 ms**. `8905` stays retracted; so does r1 §3's `127 435 489 183 522`. | **MEASURED**; the ladder **CONSISTENT** (§7) |
| **M** | **NOTHING BECOMES EXECUTABLE.** 0 of the 42 delay-DRAM frame slots; 107 words FULLY, 92 addressing-only, 86 nothing, of 285 — **identical before and after**. Operand-pointer closure residue **+0** (unmoved, as it must be). Descriptor-cursor residue **still NOT TESTABLE**. **Frames COMPLETED: 0 of 1 536 349.** | **MEASURED** (§10) |

---

## 1. The populations, re-derived rather than imported

```
python3 dsp/tools/adjudicate6.py census
```

```
   algorithms shipping descriptor cells         : 91
   ... of which #cells == #consumers (ALIGNED)  : 83
   descriptor cells, all algorithms             : 870
   descriptor cells, ALIGNED algorithms         : 829
   READ 416   WRITE 365   still trapping (C format) 48
   role census: CEILING 83  LIMIT 74  FLOOR 9  DISPUTED 2  LINE_BASE 291
                READ_END 322  TRAP 48
```

`adjudication-round5` §7 published `416 / 365 / 48`; `dram-bounds.md` §1
reproduced it; this is a **third** independent implementation and it agrees.
That is why nothing in this round re-opens the alignment or the direction — the
`δ = 0` map and `addr8` bit 6 are the two things three passes now agree on from
three different routes.

---

## 2. ★★ Rule 4 and rule 7 on T2's two dummies

```
python3 dsp/tools/adjudicate6.py degen
```

T2 item A, verbatim: *"the LIMIT is the FIRST WRITE of its program, 74 of 74,
and the CEILING is the LAST READ, 83 of 83 … two cell classes `dram-bounds.md`
located and explicitly left open are the two ends of one mechanism, arrived at
**from a completely different direction**."*

T1 had already published **where** those cells sit — and T1 also reported, about
itself, that the instruction-blind, value-blind positional rival
`R1 = {rel 1, rel n−2}` ties it 163/163 and that it could not separate the two.
The question T2 never asked is whether *its* statement is a different statement.

```
   POPULATION 83 aligned algorithms.  Strictly alternating 55, NOT 28.
   (T3 sect. 3 measured the same 55 / 28 -- reproduced independently.)

   RIVAL A  T2's : the CEILING is the LAST READ                 83 of 83
   RIVAL B  T1's : the CEILING sits at rel n-2 (n-1 when n = 2) 83 of 83
   ** DISAGREEMENT SITES BETWEEN A AND B: 0 of 83 **
   the last READ of the block IS at rel n-2 / n-1 in 83 of 83
```

**METHOD RULE 4.** Two rules that produce the identical map are one machine
counted twice, and an exact tie on every site is the signature. **METHOD RULE
7.** T2's permutation null — place each algorithm's dummy read uniformly among
its own reads, 0 of 2000 reach 83 (my re-run: max **35 of 83**) — rejects a null
that ignores position. It does not, and cannot, separate the pipeline-flush
reading from *"the allocator emits the ceiling second-from-last"*, which is a
rival that never looks at the instruction. **T1 printed this about its own
result. T2 did not.**

The LIMIT half is different, and better:

```
   RIVAL A  T2's : the LIMIT is the FIRST WRITE   74 of 74
   RIVAL B  T1's : the LIMIT is rel 1             73 of 74
   ** DISAGREEMENT SITES: 1 **
      algo 3  ENHANCER  n=8  seq=RRRWRWRW  first write rel 3
```

**One site, and the direction-aware rule wins it 1–0.** That is genuine
separation and it is genuinely thin, and both halves of that sentence are
printed. It does not lift the label above T1's own: `bounds.py` assigns `LIMIT`
as the **residue** of allocation model A4, so it is FORCED *within that model*.

⇒ **T2 item A: the CEILING half is CONSISTENT, the LIMIT half is
FORCED-WITHIN-THE-MODEL.** Neither is FORCED simpliciter.

---

## 3. ★★★ THE ROUND — the SINGLE DELAY harness audit

```
python3 dsp/tools/adjudicate6.py polarity
```

### 3.1 What T2 found, and where it stopped

T2 item F falsifies `action-field.md` §8 / `blocking-read.md`'s *"the BLOCKING
read, FORCED 5145/5145"* by **re-attribution**: that forcing read SINGLE DELAY
under the polarity round 5 reversed, and `blocking-read.md` §3.3 literally
labels `880.1.60.2D9` *"the DRAM READ"* and `880.1.20.64B` *"the DRAM WRITE"* —
the exact pair item D flipped. Correct, and T2 stopped there.

**Method rule 10 says to ask what else that parameter was held fixed inside.**

### 3.2 The hard-coded polarity, quoted from the shipped tools

`dsp/tools/action00_discriminate.py` `sd_run()` and
`dsp/tools/acc_adjudicate.py` `sd_run()`, both verbatim:

```python
        def dram(w, bus, s):
            if (DIS.addr8(w) & 0xf0) == 0x20:
                ln.write(bus)                       # <- addr8 0x20 = WRITE
            else:
                s.dr = int(ln.read()) & MASK24      # <- addr8 0x60 = READ
        ...
            if ... (DIS.addr8(w) & 0xf0) == 0x60:
                st.dr = int(ln.read()) & MASK24     # "the BLOCKING read"
```

`adjudication-round5` item **D** FORCES `addr8 0x20/0x30 → READ`,
`0x60 → WRITE`. **The delay line in every SINGLE DELAY search is wired
backwards.**

### 3.3 How wide the exposure is (rule 9)

```
   ACTION 0x19 sites, whole corpus (60-word header + 23-word epilogue
   + 38 distinct body images)                       : 94
   ... inside an image that carries delay-DRAM words: 92
   DRAM-FREE images carrying ACTION 0x19            : [('A88', 2)]
```

The single DRAM-free site is **algo 88**, which `second-dsp-and-ready.md` §2
showed is an **IC310 (MN19413)** stream and not an IC311 program at all. And
SINGLE DELAY is the **only** published ALU context that constrains `ACTION 0x19`
in the first place: the biquad carries no `0x19` word (MEASURED — its ACTION
codes are `07 12 13 14 15`) and the LFO section does not enumerate it.

**ENUMERATION PRINTED BESIDE THE CLAIM (rule 3): the published ALU contexts are
the biquad, the 29 LFO blocks, SINGLE DELAY, and the reverb comb search. Of
these, only SINGLE DELAY and the comb touch the delay port; only SINGLE DELAY
constrains `ACTION 0x19`; the comb's own blocking-read rows are the ones T2
already voided.**

### 3.4 The re-run

Same space (5832 machines), same reference `v[n] = x[n] + fb·v[n−D]`, same
tolerance, same seeds, same coefficient bank read off the ROM. **The only thing
enumerated is the parameter the harness fixed.**

```
   polarity = published                                   : 108 of 5832
       order  2 values  adder x72  act_last x36
       act00  4 values  add x36  sub x36  load x18  rload x18
       act19  FORCED    tA<-bus x108
       src00  FORCED    mem x108
   polarity = forced                                      :   0 of 5832
   polarity = forced, read register CARRIED across frames  :   0 of 5832
```

The first row is the **positive control**: my re-implementation reproduces the
published 108 exactly, so the instrument can say **yes**.

### 3.5 ★ And the zero is a harness artefact — DEMONSTRATED

The harness's `Line` reads and writes **one cell** and advances once per frame.
That silently requires READ-before-WRITE in program order, and it was never
enumerated as a modelling choice.

```
   SINGLE DELAY, the searched window w5..w9:
     w5  08801602D9  addr8=60   published: READ    FORCED: WRITE
     w9  088012064B  addr8=20   published: WRITE   FORCED: READ

   published (addr8 0x20 = WRITE)        port order RW  READ returns [0,0,0,0,0]
       -> a real D-frame delay: the loop exists
   round-5 FORCED (addr8 0x60 = WRITE)   port order WR  READ returns [1000,1001,1002,1003,1004]
       -> THE VALUE WRITTEN IN THAT VERY FRAME -- delay 0, no loop
```

The chip's line is **not one cell**: `dram-bounds.md`'s line set gives every line
a separate read cell and write cell, and `dram-datapath.md` §5 measures the write
consumer **+3 port slots after** the read consumer. A two-address line with a
rotation has no read-before-write requirement at all. **That harness does not
exist in `dsp/tools`, and building it is this round's rank-1 experiment.**

### 3.6 The adjudication, at its real strength and no higher

* *"The BLOCKING read, FORCED 5145/5145"* — **FALSIFIED** (T2 by
  re-attribution; this section supplies the mechanism).
* *"`ACTION 0x19 = tempA ← bus`, FORCED 72/72 and 108/108"* — **the forcing is
  WITHDRAWN.** The semantic is **not refuted**: what fell is the evidence.
* `blocking-read.md` item **D** — the withdrawal of `schroeder-topology.md`
  §0-C's conditional challenge — **loses its premise. The challenge is
  RE-OPENED.** So are the `3206/3206` and `2310/2310` blocking rows behind
  `blocking-read.md` items C, D, H and I; the `112/112` PUBLISHED row survives.
* `acc-adder.md`'s adder — a **reconciliation of the LFO with SINGLE DELAY** —
  loses one of two legs. Retained: the LFO leg is untouched and the adder is the
  plurality (**27 of 33**) even in the reversed model. But it is no longer a
  two-context forcing.
* `SRC 0x00 = mem[ptr]`, `72/72` — also void, and it was **never applied**
  (`blocking-read.md` item G: two values ⇒ the 30 frame slots keep trapping), so
  nothing moves there.

---

## 4. ★★ The enumeration for the two dummies, widened

```
python3 dsp/tools/adjudicate6.py enum
```

T2 §2.1 prints `E1` flush / `E2` wrap-register load / `E3` refresh / `E4`
padding / `E5` coincidence. **Rule 3 asks what physically plausible option is
not in the list.** Two are:

| # | reading | verdict |
|---|---|---|
| **E2′** | a per-frame-persistent **limit register loaded at the TAIL, for the NEXT frame** | T2 rejects `E2` with *"a limit must be loaded before the accesses it bounds; it is last 83 of 83"* — true only **inside one frame**, and the body is a loop run 1 536 349 times, so the last word of frame *N* precedes every word of frame *N+1*. E2′ additionally explains what E1 leaves arbitrary: the ceiling's value is not *any* harmless address, it is exactly the per-unit partition boundary (`32768` unit 0 / `32767` unit 1), which is what a limit register holds. **REFUTED below.** |
| **E7** | the address **wraps** and the last read is a **real** read (32768 is unit 0's region size, so a 15-bit adder returns offset 0) | **ADMITTED. NOT SEPARATED.** |

### ★ The control that decides E2′ — and it rejects it

If the ceiling access were a *limit-register load* it would be a **different
instruction** from a delay read. It is not:

```
   distinct CEILING words: 6
      088012064B x48   the SAME 36 bits also perform a real line READ  x93
      08801202C7 x13   ... x24
      08801202D5 x12   ... x12
      0880130000 x5    ... x4
      0880130407 x4    ... x1
      0880130647 x1    ... x0
   distinct LIMIT words:   4
      08801602D9 x51   the SAME 36 bits also perform a real line WRITE x52
      08801602DA x13   ... x25
      09001601D5 x9    ... x23
      0880160000 x1    ... x62

   CEILING cells whose word is elsewhere a real line read : 82 of 83
   LIMIT   cells whose word is elsewhere a real line write: 74 of 74
```

**The two dummy accesses use ordinary access instructions.** The same 36 bits
cannot be a limit load here and a delay read there — that is the HLE
chip-boundary discipline, and it kills E2′. ★ **I built this control expecting
it to SUPPORT E2′. It says no, and it is printed rather than deleted.**

**E7 is not separable here.** E1 and E7 make the same prediction about position
*and* about the instruction; they differ only in whether the datum is used, and
the ceiling read is the **last** read, so no later word distinguishes *discarded*
from *consumed and irrelevant*. ⇒ **T2 item A is CONSISTENT, not FORCED.**

**What is untouched either way:** T1's region test. `32768` minus a unit-0 write
is not a delay length under E1 *or* E7, so the fake-line correction, the 324-line
set and the `21 → 0` overlap result stand.

---

## 5. The write trail — the correction goes both ways

```
python3 dsp/tools/adjudicate6.py wtrail
```

```
   POPULATION 324 lines over 83 aligned algorithms.
   write consumer - read consumer, in DRAM PORT SLOTS
      ALL LINES          {-24: 12, -21: 12, 2: 7, 3: 273, 4: 7, 6: 1, 9: 12}
      HOST-ANCHORED ONLY {-24: 12, -21: 12, 2: 4, 3: 30, 4: 4, 6: 1}
      ... of which MULTI-TAP reads sharing one base
                         {-24: 12, -21: 12, 2: 4, 3: 13, 4: 4, 6: 1}

   +3 among HOST-ANCHORED lines                         : 30 of 63
   +3 among host-anchored lines that are ONE read on ONE base: 17 of 17
```

T2 §5 says the trail *"inherits `bounds.py`'s labels — FORCED for the 69
host-anchored endpoints, CONSISTENT elsewhere"*, and then the one-page table
says **FORCED**. Both corrections are printed: the corpus-wide 84.3 % **is**
carried by model-derived pairings, **and** on the subset where the host supplies
both ends and the line has one read and one write, the trail is
**exceptionless**. ⇒ **FORCED on 17 lines, CONSISTENT on 307.**

`wtrail = 2` — the `+3` slots read as `+2` eight-word repetitions — is **MEASURED
on the twelve reverbs, 11 of 11**, and "repetition" is only defined there, so the
corpus-wide statement is `+3 slots`.

---

## 6. ★ `land ∈ [1, 4]` — the two ends are in different units

```
python3 dsp/tools/adjudicate6.py latency
```

```
   READ -> next DRAM word            n=154  min=2  max=56  mode 4 (x48)
   READ -> next READ                 n=124  min=4  max=56  mode 8 (x19)
   READ -> next word with SRC 0x0B   n=111  min=4  max=63  mode 4 (x40)
```

T2's §3 table, reproduced exactly. **The collision is inside one pass and it is a
change of units — the rule-10 failure mode.**

* Item **A**'s mechanism is stated in **PORT SLOTS**: exactly one trailing flush
  read per program ⇒ the port is one deep ⇒ read *k*'s datum becomes visible when
  read *k+1* **issues**, which is a *position in the program*, not a constant
  number of words. Under that mechanism `land` in words is not a hardware
  constant and the interval is not well formed.
* Item **E**'s bound is stated in **WORDS** and needs a premise not in the
  enumeration: **that the first `SRC 0x0B` word after a read consumes THAT
  read.** The same pass's `wtrail = 2` says the machine tolerates exactly this
  staleness elsewhere.
* Taking item A literally instead gives *"the datum arrives within one port
  access"* ⇒ `land ≤ min(READ → next DRAM word) = ` **2**, which is **tighter**
  than 4 and comes out of T2's own table.

⇒ `land ≥ 1` is **CONSISTENT** (it follows from the flush reading, which §4
downgraded); `land ≤ 4` is **CONSISTENT** and rests on an unenumerated premise.
**The read latency is OPEN.**

---

## 7. ROOM REVERB 1, re-derived — and how much of it is anchored

```
python3 dsp/tools/adjudicate6.py ladder
```

```
   host op-0x67 taps in this algorithm: {cell 0x00: 32770}     <- EXACTLY ONE

   PRE DELAY  800 samples (18.141 ms)  -- HOST-ANCHORED (BASE24 32770, base cell 0x03 = 32768)
   LADDER     83 172 356 513 739 240 119 247 428 616 360
   TOTAL      3873 samples = 87.82 ms
   LONGEST PATH pre-delay + ladder = 4673 samples = 105.96 ms
   early reflections off the pre-delay base: 650 and 540 samples
   the 4 still-trapping C-format cells: 33852 34393 33743 33850
        = 1084 / 1625 / 975 / 1082 samples off cell 0x03
```

Re-derived from the ROM: T2's ledger and round 5 item H are both reproduced to
the digit, including the `+9` closure through cell `0x1F` and the `−21 / −24`
early-reflection taps.

★ **The part nobody states, and rules 8 and 9 both demand it.** ROOM REVERB 1
carries **exactly one** host `op-0x67` tap, so the 800-sample pre-delay is its
**only host-anchored line** and **all eleven ladder segments are model output**
(`bounds.py` A4). Quoting `3873` as though it were measured is the same class of
error that made `8905` survive two retractions. **An impulse test sized on 3873
is sized on a CONSISTENT number** — which is fine, provided the note beside it
says so.

---

## 8. T3's measurement, reproduced; and M5's death does not touch T2

```
python3 dsp/tools/adjudicate6.py cursor
```

```
   writes to the DESCRIPTOR POINTER (lo12 selector 0x25): 3
      HDR 44  0801025825  payload 0x25
      HDR 52  0801025825  payload 0x25
      EPI 62  0801026825  payload 0x26
   pointer writes of ANY selector inside a body image: 0
```

Reproduced from the whole ROM, nothing sampled. T3's counting argument stands.

**And the brief's specific question — does M5's death invalidate any of T2's
constraints? No, and the direction is the opposite of what the question
supposes.** M5 (two cursors, one per direction) was the one live **rival** to the
`δ = 0` identity map that T2 *assumes*; refuting it strengthens T2's premise.
T3's message to the datapath agent is correct as written.

---

## 9. The controls, each demonstrated saying NO

```
python3 dsp/tools/adjudicate6.py control
```

| # | control | shown rejecting |
|---|---|---|
| **K1** | ★ the harness, run at its **published** polarity | **108 of 5832** — it reproduces its own published number, so the instrument **can say yes**; at the FORCED polarity, **0** |
| **K2** | ★ and the zero itself | shown to be a **harness artefact** (the one-cursor `Line`), so it is *not* reported as a rejection. A control that cannot pass is as worthless as one that cannot fail, and both are printed |
| **K3** | ★ **a control of mine that did not do what I built it for** | I built the *"is the dummy access an ordinary instruction?"* test expecting it to **support** E2′; it **refutes** E2′, 82/83 and 74/74 |
| **K4** | the degeneracy check, run **before** any score (rule 4) | `CEILING = last READ` vs `CEILING at rel n−2`: **0 disagreement sites of 83** — one machine counted twice |
| **K5** | the same check on the LIMIT | **separates**, 1 site, 1–0 — so the instrument is able to report *different* |
| **K6** | T2's permutation null, re-run | 2000 trials, max **35 of 83** — it rejects, **and** its hole is printed: an instruction-blind positional rival scores 83 too |
| **K7** | ★ the audio capture | verified to **carry real audio before anything is concluded**: 1 536 001 frames, **876 696 non-zero samples, peak 21 541**, `md5 f57115a26a55fcfed68fb6eab0769ea8`. Round 5's first attempt produced peak 0, which is why this is checked every time |
| **K8** | ★ the artefact control on the applied edit | the rebuilt binary is **byte-identical** to the published one (`md5 965976f50bbfa11299d1449caca7d336`) after a full recompile and relink, although the edit adds ~60 lines. Stronger than the audio control, and it **could** have failed |

---

## 10. The before/after

Live, cold boot, fresh `nvram` per run, identical `cfg`, identical 32 s keybed
programme (three chords at 20.0 / 23.5 / 27.0 s), `-str 32`, `-nothrottle`,
visible video, `DSPCFG` Off and On, before and after.

| | before | after |
|---|---|---|
| frames run | 1 536 349 | **1 536 349** |
| words executing **something** of 285 | 199 | **199** |
| words executing **FULLY** | 107 | **107** |
| words executing **addressing only** | 92 | **92** |
| words executing **nothing** | 86 | **86** |
| ★ **frames COMPLETED** | **0** of 1 536 349 | ★ **0** of 1 536 349 |
| frames that TRAPPED | 1 536 349 (100.00 %) | **identical** |
| ended on wait word / CAP / OVERRUN | 1 299 228 / 210 241 / 26 880 | **identical** |
| ★ **operand-pointer closure residue, last frame** | **+0** | ★ **+0** |
| complete frames that CLOSED | 1 273 307 of 1 299 228 | **identical** |
| residue min / max, entry pointer X | −1 / +116, `0xFF` 97.93 % | **identical** |
| input-stage audit | 1 309 788 both-reads, **0 MISMATCHED** | **identical** |
| frames carrying a NON-ZERO sample into the chip | **438 663**, peak `0x542500` | **identical** |
| **descriptor-cursor residue** | NOT TESTABLE (its 42 consumers trap) | **still NOT TESTABLE** |
| distinct undecoded words | 443 | **443** |
| frame floor tier 1 | 82 of 216, **38.0 %** | **identical** |
| frame floor tier 1 + 2 | **60.6 %** | **identical** |
| 38 body images (2974 words) | 1234 tier 1, **41.5 % / 52.6 %** | **identical** |
| frame-floor tier-2 DETERMINED / MEASURED / PARTIAL | 32 / 6 / 11 | **identical** |
| `dsp/verify.py` | BYTE-MATCH OK | **BYTE-MATCH OK** |
| `upd6383d_diff.sh` | MIRRORS AGREE 3057/3057 | **MIRRORS AGREE 3057/3057** |
| `-validate kn5000` | exit 0, silent | **exit 0, silent** |
| ★ binary `md5` | `965976f5…d336` | ★ **`965976f5…d336`, byte-identical** |
| ★ audio, all four WAVs | `f57115a2…9ea8` | ★ **identical** |

**Nothing moves, and it cannot: the binary is byte-identical.** The
descriptor-cursor residue is still not testable and neither T2 nor T3 made it
testable — their results are about *which cell* and *which direction*, and the
42 consumers still trap.

**Rule 5 — the impulse test the brief asks for was NOT run, and that is not a
choice.** The delay line does not execute. §7 re-derives what it would need
(several times 4673 samples, not `4 × 8905`), and records that the ladder it
would be sized against is CONSISTENT, not MEASURED.

---

## 11. What was applied

**Labels only. No executable predicate, no `decoded()`, no `addressing_only()`,
no `has_addressing()`, no `is_dram()`, no ALU semantic.**

* `src/devices/cpu/upd6383/upd6383d.h` — `LO_ACT_CAP_TA2` (0x19): the
  *"FORCED 72/72 / 108/108"* claim and the *"it survived a challenge and the
  challenge is withdrawn"* narrative are replaced by the full provenance of §3,
  ending in **the semantic is retained, is CONSISTENT, and must not be cited as
  FORCED**. `LO_ACT_ACC_BUS` gains the adder's one-leg caveat.
* `src/devices/cpu/upd6383/upd6383.cpp` — the same at the `LO_ACT_CAP_TA2` case
  in `exec_alu()`, and the `tbsh` comment's two **blocking-read** rows
  (`3206/3206`, `2310/2310`) are marked void while the `112/112` published row
  survives.
* `dsp/tools/dsp_disasm.py` — the mirror of both.

⚠ **THE OPEN DECISION, STATED SO IT IS NOT BURIED.** Method rule 6 says only
FORCED results reach the device. `LO_ACT_CAP_TA2` shipped as FORCED and its
forcing is gone. It was **not** withdrawn here because the only instrument that
could withdraw it is a harness that provably cannot model the corrected machine
(§3.5) — reverting on that authority is the rule-1 defect in the other
direction, and losing ~100 executing words to an artefact is not a conservative
act. **This is a live exposure and it needs either the rank-1 experiment below
or an explicit decision.**

---

## 12. For the next round, ranked twice

**Ranked by slot leverage:**

1. **Build the two-address delay-line harness** and re-derive `ACTION 0x19`,
   `SRC 0x00` and the adder's second leg against it. Read cell and write cell
   come from `bounds.py`'s line set; the rotation `G` is a free parameter; the
   trail is `+3` slots (§5). This is the same piece of machinery T2 named for its
   own stage B (*"extend `advance` past two atom generations"*), and it now
   blocks **three** published determinations as well as the reverb search.
2. The **write-data source** for a WRITE word and one member of the latency
   interval for a READ word — T2's list, unchanged.
3. The **C-format direction** for the 48 trapping cells. T1's off-by-one gives a
   CONSISTENT reading; §7 shows the four cells are `975 / 1082 / 1084 / 1625`
   samples off the pre-delay base, which is exactly early-reflection shaped.

**Ranked by the rule that has actually predicted payoff — does the host firmware
already name this?**

1. **The C-format cells: YES.** `T1[0x67]` of all twelve reverbs reserves
   `0x19 0x1A 0x1B 0x1C 0x1D 0x1E`; four of those cells are the trapping words.
   The host names them **delay taps**. That is the same lever that solved the
   bounds question and the phase.
2. **The rotation `G`: PARTIALLY.** The host writes the per-unit ceilings
   (`32768` / `32767`) through the same tag-`0x4C` path, and §4 shows they are
   consumed by ordinary read instructions — so whatever `G` is, it is *not*
   loaded by a distinct opcode.
3. **`ACTION 0x19`: NO.** Nothing host-side names it. That is why it needs the
   harness and not a firmware read.

---

## 13. PREDICT-THEN-CHECK — 12 predictions, 7 clean misses, 2 half-results

```
python3 dsp/tools/adjudicate6.py predict
```

| # | prediction | outcome |
|---|---|---|
| **P1** | The collision would be between T1's bounds and T2's datapath, since T2 imports T1's roles wholesale. | ★★★ **MISS, and it is the pass's whole content.** Those two agree. The collision is between **round 5's reversal** and the ALU semantics that had already shipped — a pass that finished two rounds ago. |
| **P2** | T3's M5 verdict would invalidate something of T2's. | ★★ **MISS.** M5 was the *rival* to T2's premise; killing it strengthens T2. |
| **P3** | T1's bounds classification would have been used as FORCED where it is only CONSISTENT. | ★ **HIT.** T2 item A's LIMIT half and item B's `+3`. Though on item B the correction goes **both** ways (17 of 17 on the clean subset) and both are printed. |
| **P4** | T2's *"the CEILING is the LAST READ"* would be independent of T1's positional statement. | ★★ **MISS — for T2.** Zero disagreement sites over 83. I expected a handful. |
| **P5** | The missing enumeration member would be a cross-frame limit-register load, and it would survive. | ★★ **HALF-MISS.** E2′ really was missing — and the control I built for it **refutes** it. |
| **P6** | Re-running SINGLE DELAY at the corrected polarity would move the forcing to some *other* value. | ★★★ **MISS, and worse than predicted: to NOTHING.** 0 of 5832. |
| **P7** | Carrying the read register across frames would restore the survivors. | ★★ **MISS.** Still 0. The defect is the one-cell line, not the register lifetime — so the fix is machinery. |
| **P8** | The exposure would be narrow — one or two contexts. | ★ **HIT on the count, MISS on the consequence.** It is one context, and that context is the **only** one constraining `ACTION 0x19`, so "narrow" means "total". |
| **P9** | Something would be applicable to the device. | ★ **MISS as a decode, HIT as a correction.** Zero dark slots; three FORCED assertions withdrawn. |
| **P10** | T4's numbers would need re-checking. | ★ **HIT (negative).** P17/P18 report 0 LIVE; census, ladder and pointer count all reproduce. |
| **P11** | `land ∈ [1,4]` would survive as the round's one clean forced result. | ★★ **MISS.** Its two ends are in different units and the word bound needs a premise the same pass denies elsewhere. |
| **P12** | The before/after would be bit-identical and the tally unmoved. | ★ **HIT**, and stronger than expected — the **binary** is byte-identical, which is a control the audio capture cannot match. |

---

## 14. What moves in the other notes

* **`blocking-read.md`** — items **C**, **D**, **H** and **I** rest on the
  blocking-read rows (`3206`, `2310`). **VOID.** Item **D**'s withdrawal of
  `schroeder-topology.md` §0-C is retracted; that challenge is **re-opened**.
  Item **E** (the `land 0` / `land 1` degeneracy) is untouched — it is about the
  searcher's queue, not the polarity. Item **F**'s three routes to
  `SRC 0x00 ≠ DR`: route (1) is SINGLE DELAY and is void; routes (2) and (3)
  stand, and route (2) quotes `dark-words.md` §6 which T4 retired, so
  **`SRC 0x00 ≠ DR` now has ONE surviving route, not three.**
* **`action00-discriminator.md`** — §7's `108/108` and the `single` section's
  `72/72`: **VOID**. Its `census`, `biquad` and `lfo` sections are untouched.
* **`acc-adder.md`** — the adder's SINGLE DELAY leg: **VOID**. The LFO leg and
  the conclusion stand, on one context.
* **`action-field.md`** §8 — already falsified by T2; this note adds the
  mechanism.
* **`dram-datapath.md`** — item A → **CONSISTENT** (§2, §4); item B →
  **FORCED on 17 host-anchored lines / CONSISTENT on 307** (§5); item E →
  **OPEN** (§6). Items C, D, F, G, H, H2, I, J, K stand.
* **`dram-bounds.md`** — stands entirely. Its own rule-7 confession (item L) is
  the honest version of the thing T2 did not confess.
* **`dram-unit-cursor.md`**, **`second-dsp-and-ready.md`** — stand.
* **`adjudication-round5.md`** — item K's *"no executable semantic changed"* is
  true of what it edited and **incomplete as a statement about the round's
  consequences**. Nothing in round 5 is retracted; §3 is the audit it did not
  run.
