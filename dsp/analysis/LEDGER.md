# LEDGER — every hypothesis, its mask bit, and its verdict

**Read this file before starting any DSP work. It exists because ten passes on this project were
lost to re-asking a question the notes had already answered, or re-trying an approach a previous
section had already refuted.** A 6000-line register does not prevent that; an index read *first*
does.

Tiers, cheapest first — stop as soon as you have what you need:

| tier | what | where |
|---|---|---|
| **0** | the current blocker + **the dead ends** | this page, below |
| **1** | the mask-bit register — every bit, its state, its § | generated, below |
| **2** | the section index — 59 sections, one line each | generated, below |
| **3** | the sections themselves | `SPECULATIVE-APPLIED-REGISTER.md` |

⚠ Tiers 1 and 2 are **generated** by `tools/gen_ledger.py` from the C++ source and the register's
own headings, so they cannot drift. Tier 0 is hand-written. **Re-run the generator after any
section or mask-bit change**; do not hand-edit `LEDGER.md`.

---

## TIER 0a — THE CURRENT BLOCKER  (§165, 2026-07-30)

> **The LFO phase RAMPS in D-RAM cell `0x07` and does not REACH the class-6 word.
> The defect is ROUTING over a handful of words, not generation.**

Established by run `runs164/A_control`, mask `0x3910E446A39B440F`, cold-boot CHORUS,
1 392 430 frames — **cite the run, not the section** (see rule 10):

```
  §164  07: 0..8388598  chg 1128429 / 1392430 frames     full Q0.23 sweep
  §162  at the class-6 word:  acc 0..0 | m_dp 12..12 | cursor 9..9
```

The phase changes 1 128 429 times against the class-6 word's 1 129 389 executions — ratio
**0.99915**, so it advances once per body execution. That identifies it as the LFO beyond doubt.
Rate puts the increment at **114** (0.652 Hz against the panel's 0.599), not §108's measured 57.

⛔ **§163's blocker — "kernel `iw32` pins the phase at `0x400000`" — is DEAD.** It was inherited
from §108, written several shipped gates earlier, and never re-measured. §108's whole kernel-`iw32`
/ `DRAM_UNIT_BASE` analysis is aimed at a symptom this build no longer has.

Everything downstream is built and waiting:
* **§161** — the wavetable is intact: `m_rf[0x1D..0x40]`, 36 cells,
  `0.9500000 × 2^23 × sin(2πk/24 + 0.100000 rad)` to within 2 LSB, period exactly **24**.
* **§162** — the class-6 lookup is four lines *once the index varies*, and not before.

**Next:** trace `0x07` → the class-6 word. The path runs through `082.2.00.1C0` (`SRC 0x07` =
`mem[ptr]` → acc) and the class-6 word's own `SRC 0x13`, which has **no reading anywhere** and
silently returns 0 (`upd6383.cpp` SRC evaluator default). `SRC 0x13` is the table read port
(§162) — that is the most likely single missing link.

---

## TIER 0b — ⛔ DEAD ENDS. DO NOT RETRY ANY OF THESE.

Each cost at least one full pass. The refutation is worth more than the hypothesis was.

⚠ #1 and #2 were aimed at §163's *"kernel `iw32` pins the phase"* blocker, which §165 then
measured out of existence. They stay listed: the refutations are still sound, and the ideas are
the ones a reader would reach for again.

| # | the idea | why it is dead | where |
|---|---|---|---|
| 1 | Fix the phase clobber by changing **`DRAM_UNIT_BASE`** | **FORCED**: kernel A's walk begins where the previous frame *closed*, so base and window are coupled and `iw32` follows the cell wherever it moves. Bit 27 ran it — gate fires, `dp` `0x07`→`0x08`, **every value bit-identical** | §108 §5 |
| 2 | Decode `040.0.**.C63` / `012.4.01.1CE` as the missing phase producers | Both **already modelled**: `SRC 0x11/ACT 0x03` = `tempB ← ACCB`, `SRC 0x07/ACT 0x0E` = `P ← mem[ptr]`. Their presence in the roadmap's *"no reading of any kind"* list is a **corpus statistic, not a statement about the emulator** | §163 |
| 3 | `addr8` on the class-6 word = the **table extent** | The `0x28` sites are fed by scale `0x000010` = 16; `0x000028` does not occur in the coefficient corpus at all. The `24`/`0x18` agreement was coincidence | `lfo-ramp.md` P-16 |
| 4 | Implement the class-6 lookup **now** | Every index candidate is constant (`acc 0..0 \| m_dp 12..12 \| cursor 9..9`, 1 129 389 hits). A frozen lookup returns one entry forever, and that reads as *refuting the sine* against the "226 not 240" test | §162 |
| 5 | `SRC 0x08` = **unity** | The rival reading saturates the accumulator on the LFO's very first word. `SRC 0x08 = the COEFFICIENT` reproduces the ROM ramp constant exactly (`mem[0x04]` 1000→1228, step +228 = `0x0000E4`) in 11 of 19 corpus constants | `upd6383.cpp:2124` |
| 6 | The brief's anchors **`SRC 0x1C` = "LFO out"**, **`SRC 0x08` = "LFO phase"** | Neither is anchored anywhere in this repository, the MAME device, or its disassembler. A *word*-level landmark was read as a *field*-level one | `lfo-ramp.md` §11 |
| 7 | `st_gate = always` | 0 survivors of 276 480 | `lfo-ramp.md` P-9 |
| 8 | Remap the three internal writes onto **output ports 0/1** | Reverted: the resulting wet was rms 1.0 — a ±1 LSB constant present *even in silence* | `upd6383.cpp:2011` |
| 10 | **Bit 54** (latch to `m_k`) and **bit 54 + bit 4** (§40 reads it) to route the phase | §136's *"the pair has never been evaluated together"* is discharged: bit 54 alone is **bit-identical to control in every cell**; the pair produces `§70 ACCA min = max = 176 471 605 248`, the exact DC §137 retracted | §165 §4 |
| 17 | The descriptor payload is truncated 24→16 bits (`m_dscbank = u16(v & 0xffff)`) | ⛔ **REFUTED §190.** `r3-delaydram.md` P5, MEASURED over 870 cells: the delay map is `[0x0000,0x10000)` and no firmware address reaches 2¹⁶ (max 64 899). 16 bits is correct, and "every unit-1 cell has bit 15 set" is just unit 1's range `[0x8000,0x10000)` | §190 |
| 18 | The cold-boot unit-1 program is not ROOM REVERB 1 | ⛔ **REFUTED §190.** §170's 16-word fingerprint applied to load address 200: `prog16_room_reverb_1`, loaded once at transfer 18 | §190 |
| 15 | Model the bit-11 `lo12` words on an **ALU route** | ⛔ There is no ALU route to model — `bit11-family.md` §9 establishes bit 11 selects a **second encoding** with no `SRC` and no `ACTION` field (bits 11/5 co-vary 90 of 90; the ALU reading needs 4 field values attested nowhere else). `alu_decoded()` refusing them is correct | §182 |
| 16 | `ACT 0x03`, `ACT 0x04`, `ACT 0x1C`, `SRC 0x02`, `SRC 0x04` | ⛔ **These codes do not exist** — parse artefacts of applying the bit-11-clear encoding to bit-11 words (`bit11-family.md` §9.3, 2026-07-27). ⚠ One genuine exception: `epilogue w63 = 2A7.9.05.1C3` carries `ACT 0x03` with bit 11 clear, in the output stage | §182 |
| 13 | `C63` writes the index register `m_tb` via `SRC 0x11 / ACT 0x03` (**§166 §3**) | ⛔ **REFUTED §181.** `lo12 = 0xC63` has bit 11 set, and `upd6383d.h:609` routes those words to *addressing only, no ALU effect*. It never writes `m_tb`. §166's 53/53 bijection is a measurement and stands | §181 |
| 14 | `SRC 0x11`'s reading explains `m_tb` being frozen | ⛔ Three experiments (§168, §181 arm D, the whole `SRC 0x11` line) tested **the source of a write that never happens** | §181 |
| 11 | `ACT 0x15` is a no-op, so the LFO index multiply never issues (**§169 §2**) | ⛔ **RETRACTED §174.** The multiply's gate is `coeff_consumer(w) = class4==0xA && !c_format(w)` — the ACTION field is not in it. `lfo-ramp.md` §10 said so in the paragraph §169 quoted. Takes §171 §4 and §173 §3 with it | §174 |
| 12 | "one cause — the frozen cell is just the dead multiply", displacing §168 | ⛔ Premise gone with #11. §168's addressing diagnosis is **confirmed** instead: 7 of 12 multiply sites have `L` identically zero while `coef` is live | §174 |
| 9 | "the delay tap **sweeps** ±240" / "each voice ramps 0→depth, a **sawtooth**" | Both retracted. The first pooled voices of opposite sign; the second censused across the boot transient. The settled modulation value is **CONSTANT** | §155, §157 → §158 |

---

## TIER 0c — STANDING RULES, each earned by a retraction

1. **Before reporting any non-zero output, read `§70 ACCA` and compare min against max.** Two
   "IC311 outputs audio" claims have been retracted; one was a DC. *(§137)*
2. **Report absolute audio statistics from a CLEAN vehicle** — `scratchpad/coldnotes2.lua`, cold
   boot, notes after ~19 s. The `peq_gain` vehicle *creates* a unit-1 rail through ~55 mid-run
   effect uploads; use it for **deltas only**. *(§148)*
3. **Check the owning note first — for EVERY component of a claim, not just the one you doubt.**
   Ten occurrences. §163 is the sharpest: the note was checked for the *table* and skipped for the
   *phase*, and the answer had been sitting in §108 for days.
4. **Before implementing a consumer, measure that its inputs VARY.** A datapath whose every input
   is constant cannot be validated by its output. *(§162, fourth occurrence)*
5. **An absolute event count is not a falsifier across runs** — cold-boot frame totals vary
   (1 128 480 vs 1 156 269). Pre-register the *relation between two counters*, never the literal.
   *(§161)*
6. **A reading that measures INERT is a hypothesis about a MISSING CONSUMER, not a refutation.**
   *(§156, third occurrence)*
7. **Enumerate mask bits programmatically — match the bit, not the spelling.** `grep 0x40000\b`
   missed `0x40000u` and double-booked bit 18, confounding a whole run. *(§129)*
8. **A criterion that cannot fail is not a test**, and **compute the NULL before interpreting a
   table, not after**.
9. **When the fix you reach for is an ANCHOR VALUE, stop.** Every anchor here is pinned by closure
   arithmetic; the defects are per-word **decodes**. *(§108 §5, named as a standing bias)*
10. **When a measurement surprises you, the first hypothesis is that it answered a DIFFERENT
    QUESTION than the one you asked. Move the instrument one step toward what you care about
    before theorising.** Four in one day: `m_p` read at the consumer not the producer (§169);
    36 M firings **pooled across sites** instead of keyed (§174); a census printing only the cells
    that *changed*, so "static and non-zero" and "static and **zero**" were indistinguishable
    (§176); and a table capped below the case of interest (§176 F3). Each was invisible until the
    previous was fixed. *(Part 109)*
11. **A blocker is a MEASUREMENT, and measurements expire.** Before building a task on a symptom
    reported in an earlier section, re-run it on the current build — several gates ship between
    passes. **Cite the run, not the section.** *(§165: the headline blocker had been fixed by
    other work and nobody re-measured it)*

---

## TIER 1 — the mask-bit register  (generated from `upd6383.cpp/.h`; authoritative)

Default `m_specmask` = **`0xB910E446A39B440F`**.  `ON` = in the shipped default; `off` = implemented
but not armed.  ⚠ `REFUTED` means **stop**; `⚠ UNTESTED` means **this is owed a run**;
plain `off` means the classifier found neither marker — read the section.

⚠ **The `§` column routes; the text does not adjudicate.** Both are heuristic excerpts taken
from the nearest `★` banner in the source, and where two gates share a comment block the text
can belong to the neighbour. Use this table to find the section, then read the section.

| bit | state | § | what it does |
|----:|:-----:|--:|---|
| 0 | **ON** | §62 |  |
| 4 | off | §29, §40 | THE MULTIPLY IS NOT GATED BY THE FETCH |
| 5 | off | §41 | DO NOT LET AN UNSUPPORTED SOURCE OVERWRITE A HOST-PROGRAMMED REGISTER |
| 6 | REFUTED | §41 |  |
| 7 | REFUTED | §43 | w72 / w77 ARE LEVEL-SELECT WORDS, NOT ACCUMULATOR OPERATIONS |
| 8 | off | §44 | C-RAM 0x50..0x8B IS A DELAY-TAP TABLE, NOT COEFFICIENTS. Dumped, the space has three clearly distinct regions: |
| 9 | off | §47 | TAKE THE DESCRIPTOR FROM THE PER-UNIT C-RAM BANK, NOT FROM D-RAM AT m_dsc |
| 10 | **ON** | §49, §76 | THE PIPELINE IS KEYED TO THE PORT, NOT TO THE SLOT COUNTER. dram-datapath.md item A: "THE DRAM PORT IS A ONE-DEEP PIPELI |
| 11 | off | §50 | LAND IT IN tempA TOO |
| 12 | off | §52 | row 25 seeds the coefficient cursor from ldptr -- and this file already records that it is "⛔ STILL AGAINST K3, which pr |
| 13 | off | §53 | READ THE RAMP BANK AT Q0.16, NOT Q0.23 |
| 14 | **ON** | §50, §62 | SELECTOR 0x27 LOADS THE PER-UNIT OVERFLOW / MODE REGISTER (m_ovc) |
| 15 | off | §116 | SELECTOR 0x27 LOADS THE PER-UNIT OVERFLOW / MODE REGISTER (m_ovc) |
| 16 | **ON** | §69 |  |
| 17 | **ON** | §44, §72 | C-RAM 0x50..0x8B IS A DELAY-TAP TABLE, NOT COEFFICIENTS. Dumped, the space has three clearly distinct regions: |
| 18 | REFUTED | §113 | SRC 0x11 = mem[ptr], NOT ACCB |
| 19 | **ON** | §76 | A DELAY WORD ALSO RUNS ITS ALU |
| 20 | **ON** | §76 | THE PIPELINE IS KEYED TO THE PORT, NOT TO THE SLOT COUNTER. dram-datapath.md item A: "THE DRAM PORT IS A ONE-DEEP PIPELI |
| 21 | REFUTED | §82, §138 | A DELAY WORD'S ACTION PUTS ITS DATUM ON THE ACCUMULATOR |
| 22 | REFUTED | §138 | THE SAME ERASURE, AT THE OUTPUT STAGE |
| 23 | **ON** | §71, §94 | SRC 0x02 = reg[addr8], the MODE-1 ADDRESSED REGISTER. This is item J's own stated escape -- "SRC 0x02, undecoded, might  |
| 24 | **ON** | §100 | SRC 0x02 = reg[addr8], the MODE-1 ADDRESSED REGISTER. This is item J's own stated escape -- "SRC 0x02, undecoded, might  |
| 25 | **ON** | §101, §112 | DO NOT LET AN UNSUPPORTED SOURCE OVERWRITE A HOST-PROGRAMMED REGISTER |
| 26 | off | §94 |  |
| 27 | REFUTED | §108 |  |
| 28 | off | §109 | ACTION 0x07's MODE-2 store lands on the POST-increment cell |
| 29 | **ON** | §104, §109 |  |
| 30 | off | §119 |  |
| 31 | **ON** | §111 | THE HOST PAYLOAD IS 2x THE RAW THREE BYTES. r3-delaydram.md states it; §71/A3 reproduced it as a control that could have |
| 32 | off | §114 |  |
| 33 | **ON** | §114, §116 | WRAP mod 2^23 instead of saturating |
| 34 | **ON** | §119 | THE MEMORY-TO-MEMORY MOVE |
| 38 | **ON** | §73, §86 | SEED THE COEFFICIENT CURSOR WITH THE PER-UNIT BASE AT THE CALL |
| 39 | off | §121 |  |
| 40 | off | §121 |  |
| 41 | off | §121 |  |
| 52 | **ON** | §133 |  |
| 53 | REFUTED | §135 |  |
| 54 | REFUTED | §40 |  |
| 55 | REFUTED | §136, §138 | THE SAME ERASURE, AT THE OUTPUT STAGE |
| 56 | **ON** | §70, §153 | THE DELAY-TAP MODULATION REGISTER |
| 57 | off | §142, §148 | `coef' only where f98 == 1 AND the word consumes a coefficient. §146 localised the railing to four words -- kernel iw14/ |
| 58 | off | §145, §148 | `coef' only where f98 == 1 AND the word consumes a coefficient. §146 localised the railing to four words -- kernel iw14/ |
| 59 | **ON** | §145, §148 | `coef' only where f98 == 1 AND the word consumes a coefficient. §146 localised the railing to four words -- kernel iw14/ |
| 60 | **ON** | §47, §50 | TAKE THE DESCRIPTOR FROM THE PER-UNIT C-RAM BANK, NOT FROM D-RAM AT m_dsc |
| 61 | **ON** | §160, §161 | A DELAY WORD'S `addr8' IS A DIRECTION FIELD, NOT A REGISTER ADDRESS -- so ACTION 0x07 must not store to it |
| 62 | off | §174, §180 | PTRD-A -- `lo12 == 0x1C0' DOES NOT MOVE THE POINTER |
| 63 | **ON** | §188 | RESTORE THE PAYLOAD'S LSB. `k5-output-stage.md' item 9 and `k3-pointers.md' |

---

## TIER 2 — the section index  (generated from the register headings)

83 sections, §97..§190.  **Read the tail first** — later sections retract earlier ones *in place*.

| § | verdict | claim | grade |
|--:|---|---|---|
| §97 | OPEN | MODE-1 `addr8` AND MODE-2 `mem[ptr]` ARE **NOT** THE SAME MEMORY, AND THE ALIAS WAS DESTROYING THE UNIT-0 OUTPUT LEVEL | **FORCED** for the two-space reading (item J's forcing, extended); |
| §98 | OPEN | THE POINTER WINDOW, MEASURED LIVE: UNIT 0 IS FED, UNIT 1 IS NOT, AND THE ONLY WRITERS OF UNIT 1'S INPUT CELL ARE **MODE- | **MEASURED** (the window, the writers, the input-dependence census); |
| §99 | OPEN | THE STORE SIDE SPLIT, AND ITEM J's PREDICTION FIRES ON CUE | **MEASURED** (all four predictions, the guard A/B); **INFERRED** for the |
| §100 | OPEN | **SRC 0x02 = `reg[addr8]`**, ITEM J's HEDGE PAYS OFF, AND THE GUARD IS RETIRED | **MEASURED** (the A/B, with a live failure mode and the guard disabled); |
| §101 | OPEN | SRC 0x03 IS **BLOCKED, NOT OPEN**, AND §100 NEEDS RIGHT-SIZING | **MEASURED** that both accumulators are zero at the epilogue while the input |
| §102 | OPEN | THE ACCUMULATOR DOES NOT "DIE". IT IS HANDED OVER THROUGH MEMORY, AND **BODY 0 FAILS TO PICK IT UP** | **MEASURED** (probe series, cell input-dependence, probe placement verified in |
| §105 | REFUTED/RETRACTED | THE BODY-0 BISECTION: EXCELLENT MEASUREMENT, **REFUTED MECHANISM**, AND THE REAL DEFECT IS AN OFF-BY-ONE | **MEASURED** for §1's facts and for the LFO-block word identity; |
| §106 | OPEN | THERE IS NO OFF-BY-ONE. THE BASE+0 PICKUP IS BLOCKED BY **UNDECODED ACTION 0x0D** | **FORCED** that no offset reconciles the two strides; **MEASURED** that filling |
| §107 | SHIPPED | ACTION 0x0D IS **STILL UNDECODED**, AND THE TEST THAT WAS SUPPOSED TO DECODE IT FAILS ITS OWN CONTROL — WHICH WEAKENS A  | **MEASURED** (all six rows, the null computed first); **REFUTED** that this test |
| §108 | REFUTED/RETRACTED | RECONSTRUCTING CHORUS AT iw84..92, AND A REFUTATION THAT RETIRES A WHOLE FAMILY OF FIXES | **MEASURED** (the block decode, the phase increment of 57, the window shift, |
| §109 | OPEN | iw30/iw32's STORE TARGET: BOTH DISCREPANCIES RESOLVED, PRE CONFIRMED ON A DECODED CONTROL, AND ONE GENUINE PER-WORD ADDR | **MEASURED** (store targets, gfail codes with a passing control, the PRE/POST arms |
| §110 | OPEN | THE iw11 TIMING DEFECT FIXED, AND IT EXPOSES A SINGLE ROOT CAUSE: **SRC 0x08 CLOBBERS BOTH AUDIO CELLS** | **MEASURED** (the fix, its fired-count and null, cell 0x05's input-dependence and |
| §111 | OPEN | ★★★ **SRC 0x08 WAS ALREADY RIGHT. THE HOST PAYLOAD IS 2× THE RAW BYTES** — two independent known-right answers, both hit | **MEASURED**, with two independent pre-registered controls hit exactly and a |
| §112 | OPEN | THE iw32 CLOBBER IS REMOVED, AND IT REVEALS THE NEXT ONE EXACTLY AS §109 PREDICTED. ⚠ §113 WAS NOT VALIDLY TESTED | **MEASURED** for §112's A/B (fired-count, null, cell 0x07 leaving the set); |
| §114 | OPEN | ★★★ THE LFO RUNS. CLAMPING WAS THE BLOCKER — BUT THE MODULUS IS HALF, AND IT DOES NOT BELONG IN `acc_to_datum()` | **MEASURED** that clamping blocked the LFO and wrapping releases it, with a |
| §115 | OPEN | WHERE THE MODULUS LIVES: A **PER-UNIT MODE REGISTER**, LOADED BY SELECTOR `0x27`, AND BIT 3 IS WHAT SELECTS IT | **MEASURED** (the corpus positions and payloads, `m_ovc` being dead); |
| §116 | OPEN | ★★★ CONFIRMED: SELECTOR `0x27` LOADS A PER-UNIT MODE REGISTER, AND BIT 3 SELECTS THE WRAP | **MEASURED**, with a pre-registered payload prediction hit exactly and a |
| §117 | OPEN | THE MODULUS IS 2²³ **UNSIGNED**, AND THE FOURTH FACTOR OF TWO CLOSES | **MEASURED** (the range becoming non-negative, with the previous arm as a |
| §118 | REFUTED/RETRACTED | THE ENABLE AND THE MODULUS SEPARATED, ⛔ §117's RAMP WAS AN ARTEFACT, AND §113 IS FINALLY CONFIRMED | **FORCED** for the wrap-word discriminator (29/29, exceptionless, matching an |
| §119 | REFUTED/RETRACTED | A REAL MECHANISM, AN OVER-READ CONCLUSION, ⛔ **AND IT UNDERMINES §118's PROMOTION OF BIT 18** | **MEASURED** for the move and the phase-tracking of cell `0x10`; **REFUTED** for |
| §120 | SHIPPED | `0x0E`/`0x0F` ARE **DEAD IN THE SHIPPED BUILD**, AND THE BLOCKER IS **CLASS 6** — 53 WORDS, WITH A 29/29 SIGNATURE | **MEASURED** that `0x0E`/`0x0F`/`0x10` are dead in the shipped build and that the |
| §121 | REFUTED/RETRACTED | ⛔ BIT 18 REMOVED (IT WAS DESTROYING THE AUDIO DEPOSIT), AND THE ACT 0x0D ENUMERATION IS **VOID TWICE OVER** | **MEASURED** (bit-18 bisect, the criterion contamination caught by its null, the |
| §122 | OPEN | COVERAGE STATS, AND THEY REDIRECT THE WHOLE EFFORT | **MEASURED** (all counts, from the ROM); **INFERRED** that `SRC 0x00` marks the |
| §123 | REFUTED/RETRACTED | ⛔ §122's `SRC 0x00` READING WAS ALREADY FALSIFIED, THE DEVICE COMMENT IS STALE, AND PARAMETRIC EQ IS **8 WORDS** FROM BE | **REFUTED** for §122's `SRC 0x00` reading, on a pre-existing constraint solve; |
| §124 | OPEN | THE BIQUAD PLACES `ACT 0x0D`/`0x0E` BY EXCLUSION: THEY ARE **PER-BANK INPUT PLUMBING**, NOT PART OF THE DIFFERENCE EQUAT | **MEASURED** (the verbatim core match, the stride-9 repeat, the ten sections, the |
| §125 | OPEN | PEQ IS **TWO PARALLEL FIVE-SECTION BANKS**, AND THAT IS WHAT MAKES THE TRANSFER-FUNCTION CRITERION VALID FOR `ACT 0x0D`/ | **MEASURED** (the parallel structure, the private state ranges, the differing |
| §126 | OPEN | THE TEST HAS A PREREQUISITE NOBODY HAS DONE: **PARAMETRIC EQ IS NOT THE LOADED EFFECT** | **MEASURED** (0 C-RAM records in algo 39's stream; the live C-RAM identified as |
| §127 | OPEN | PARAMETRIC EQ **SELECTED AND RUNNING**; the coefficient chain verified end-to-end; §125's criterion CORRECTED | §1 **MEASURED** (three pre-registered checks); §2 **MEASURED** + **FORCED** |
| §128 | OPEN | THE PANEL DRIVES THE COEFFICIENTS: a non-flat target and two measured pass-through controls | §1 **MEASURED** (per-press snapshots) and one **RETRACTION** of the confounded |
| §129 | OPEN | THE FIRST LIVE TRACE OF PEQ: the static walk CONFIRMED, and **bank 1 runs on the TAP TABLE** | §1 **MEASURED**; §2 **MEASURED**; §3 **MEASURED**; §4.1–4.3 **FORCED** |
| §130 | SHIPPED | THE PER-UNIT COEFFICIENT-CURSOR REBASE, CONFIRMED AND SHIPPED — plus a confounded run of my own | §1 **FORCED** (two gate sites on one bit, verified by enumeration); §2 **MEASURED** |
| §131 | OPEN | ★★ THE ENTRY HANDS THE INPUT OVER IN **P**, NOT IN THE ACCUMULATOR — which is why §121 was structurally blind | §1 **FORCED** (direct decode of six words, verified independently of the proposal); |
| §132 | CORRECTION | ADVERSARIAL PASS: three corrections to §127's own confirmation, and the two structural reasons §121 could never have wor | §1 **FORCED** (arithmetic, source, `programs.tsv`); §2 **MEASURED** (source, quoted); |
| §133 | OPEN | ★★★ `ACT 0x0D` AND `ACT 0x0E` DECODED: the entry hands the sample over in **P**, at the multiply's scale | §1 **MEASURED** (twice, identical); §2 **FORCED** by the 8×8 map plus the |
| §135 | REFUTED/RETRACTED | TOWARDS SHIPPING §133: the blocker localised to six words, three hypotheses refuted | §1 **MEASURED**; §2 **MEASURED** (three arms); §3 **MEASURED**, three refutations; |
| §136 | OPEN | /§137 — "SPLIT `m_p`" HAS NO SPLIT TO MAKE; §40 RE-MEASURED AND STILL REFUSED; and a DC I called output | §1 **MEASURED** (site enumeration); §2 **MEASURED** (four arms) with the routing |
| §139 | OPEN | WHY `f31 = 4/5` WERE BLIND: a POPULATION failure, not a witness failure | §1 **MEASURED** (re-verified) and **FORCED** as to the blindness; §2 **MEASURED** |
| §140 | OPEN | SPECULATIVE PATTERNS (explicitly not gated; recorded so they accumulate) | §1 **MEASURED**; §2 **MEASURED** (the exclusion is forced by `coeff_fetch`'s own |
| §141 | OPEN | §138's GUARD WORKED, AND WALKED THE SILENCE TO ITS LAST SLOT: **`w73` erases the accumulator at the door** | §1 **MEASURED**; §2 **MEASURED** (the exclusion is forced by `coeff_fetch`'s own |
| §143 | CORRECTION | FOUR CORRECTIONS FROM THE PARALLEL PASS, three of them to my own sections | §1 **MEASURED** and a **RETRACTION**; §2 **MEASURED**; §3 **FORCED** (source) and a |
| §144 | SHIPPED | ★★★ §135's REFUSAL IS OVERTURNED: the railing was my own bug, and the §133 READINGS ARE SHIPPED | **MEASURED** (three pre-registered predictions, one of them a known-answer |
| §145 | SHIPPED | ★★★ `SRC 0x00` = **C-RAM[cursor]** — the reading that was never in the menu | §1 **MEASURED**, three pre-registered predictions including a known-answer control; |
| §146 | OPEN | THE CLASS GATE FAILS ITS OWN P3, AND THE FAILURE LOCALISES THE RAILING TO **FOUR WORDS** | §1 **MEASURED** with one **stated hygiene limitation**; §2 **MEASURED** (the |
| §147 | OPEN | ★★ THE `182` SMOOTHER TEST PASSES, FROM THE ROM'S OWN UPLOAD SCRIPT — and it names the compressor's ATTACK/RELEASE | §1/§2 **MEASURED** (ROM bytes and the disassembler's cursor addresses); |
| §148 | OPEN | THE `f98` GATE IS INERT IN A CLEAN VEHICLE — and the clean vehicle overturns §143 §2 | §1 **MEASURED**; §2 **MEASURED** and a **partial retraction of §143 §2**; |
| §149 | OPEN | ★★★ WHY `coef` IS INERT DOWNSTREAM: **THE LFO IS NOT CONNECTED TO THE DELAY TAP AT ALL** | §1 **MEASURED**; §2 **MEASURED** (source, quoted); §3 **MEASURED** (the idiom, the |
| §150 | REFUTED/RETRACTED | ⛔ §141's MECHANISM IS REFUTED: `w73`'s MULTIPLY **DOES** ISSUE, AND THE ACCUMULATOR IS ZEROED ANYWAY | §1 **MEASURED** (the trace, both arms); §2 a **RETRACTION** of §141's mechanism — |
| §151 | SHIPPED | `SRC 0x00` ON CLASS 2: the build already ships TWO incompatible readings, and `acc` is excluded | §1 **FORCED** (source, both mirrors); §2 **MEASURED** (re-verified; the |
| §152 | REFUTED/RETRACTED | ⛔ §149 NAMED THE WRONG WORD, AND THE ANSWER WAS WRITTEN DOWN EIGHT DAYS EARLIER | §1 **MEASURED** and a **retraction of §149 §3**; §2 **INFERRED (strong)**; |
| §153 | OPEN | /§154 — THE MODULATION PATH IMPLEMENTED; my census was a criterion that could not fail, in the other direction | §1 **MEASURED** and a **void run by my own falsifier**; §2 **MEASURED**, F3 fired; |
| §155 | OPEN | ★★★ THE DELAY TAP SWEEPS, AT EXACTLY THE DESIGNED DEPTH | §1 **MEASURED** (four pre-registered predictions, one of them a cross-check |
| §156 | SHIPPED | SHIPPED: `SRC 0x00 = coef` and the DELAY-TAP MODULATION PATH; default `0x1910E446A39B440F` | **MEASURED** (four pre-registered predictions, one of them the known-answer |
| §157 | REFUTED/RETRACTED | ⛔ §155's "±240 SWEEP" WAS POOLED. The tap moves — as an UNSHAPED SAWTOOTH, not a sweep | §1 **FORCED** (source); §2 **MEASURED**, both my hypotheses refuted; |
| §158 | REFUTED/RETRACTED | ⛔ §157 WAS ALSO WRONG. The tap-mod is a CONSTANT. And the DEPTH chain is now traced end to end | §1 **MEASURED**, a second retraction of my own claim; §2 **MEASURED** + |
| §159 | OPEN | K2's PREREQUISITE FAILS: the wavetable is 36 cells of ZERO, and the upload is on the wrong side of the §97 split | §1 **MEASURED**; §2 **SPECULATIVE (strong)**, with the unverified half stated; |
| §160 | OPEN | ★★★ THE WAVETABLE IS THERE, IT IS AN EXACT SINE, AND EXACTLY ONE CELL IS DESTROYED | §1 **MEASURED** (35 of 36 cells fitted, control passing); §2 **MEASURED** (both |
| §161 | SHIPPED | the delay word's `addr8` is a DIRECTION field, and it was being used as a store address | the field's meaning **FORCED** (276/276, prior adjudication); the misuse |
| §162 | SHIPPED | K2 is NOT blocked on the table any more. It is blocked on the PHASE. | §1 **MEASURED** (census over all 91 programs) with the `0x18`/`0x28` functional |
| §163 | REFUTED/RETRACTED | ⛔ CORRECTION to §162 §5. The dark words are not dark, and §108 already had the answer. | §1 **MEASURED** (§104's census, re-read not re-run); §2 **FORCED** (§108's |
| §165 | REFUTED/RETRACTED | ⛔⛔ THE PHASE IS NOT PINNED. IT RAMPS. The blocker was one build out of date. | §2 **MEASURED** (two counters, plus the 0.99915 identification); §3 **FORCED** by |
| §166 | OPEN | `C63` + class-6 is ONE IDIOM: 53 of 53, both directions. And it names the index register. | §2 **MEASURED** (exhaustive over all 91 programs, null computed first); |
| §168 | OPEN | bit 18 tested at last, and it names the defect: **`C63` reads a cell that never changes** | §1 **MEASURED** (five falsifiers, fired-count satisfied); §2 **FORCED** by the |
| §169 | OPEN | the register enumeration is COMPLETE and EMPTY, and it names the hole: **`ACT 0x15` is 23.7% of the corpus and decodes a | §1 **MEASURED**, and *"nothing varying reaches the site"* **FORCED** by exhaustion |
| §170 | OPEN | the DSP EFFECT TYPE map, measured from the machine's own uploads. Vehicle problem solved. | §1 **FORCED** (the manifest's population is the wrong one by construction); |
| §171 | OPEN | §169's one word is a **46-site family**, and it is a minimal pair. Three lines converge. | §1 **MEASURED**, independently reproduced; §2 **MEASURED**; §3 **MEASURED**; |
| §172 | REFUTED/RETRACTED | ⛔ "DISTORTION ≡ FUZZ" does not survive its own test, and the data corroborates the notes | §1 **MEASURED**; §2 **MEASURED**, the original claim's precondition **REFUTED**; |
| §173 | OPEN | the lookup is a FOUR-WORD idiom, and the `-2` slot is operand staging with three forms | §1 **MEASURED** (nulls computed first); §2 **MEASURED**; §3 **INFERRED** and |
| §174 | REFUTED/RETRACTED | ⛔⛔ §169 §2 RETRACTED. The multiply issues. The dead operand is `L`, and §168 was right. | §1 **FORCED** (read at source); §2 **MEASURED**, the pooled reading **VOIDED**; |
| §176 | OPEN | ★★★ THE INDEX MULTIPLY POINTS AT CELL 5. THE PHASE IS IN CELL 7. Off by exactly 2. | §1 **MEASURED**; §2 **MEASURED** (coefficient 24 identifies the word's role |
| §177 | OPEN | §176's "off by 2" is an instance of a KNOWN, LOCALISED defect, and it adds a fourth constraint | §1 **FORCED** (quoted from the owning note, origins cancel); §2 C4 **MEASURED** |
| §178 | OPEN | the header's vocabulary, verified and enumerated; and a gap I nearly reported that is not there | §1 **MEASURED** (the quoted figure independently reproduced); §2 **MEASURED**, and |
| §179 | SHIPPED | the census window was RIGHT, and the note's origin region is EMPTY. An open discrepancy. | §1 **MEASURED**; §2 **MEASURED** (a standing prediction confirmed); |
| §180 | SHIPPED | PTRD-A: the dead multiply comes ALIVE, by moving the DATA rather than the pointer. Not shipped. | §1 **MEASURED**; §2 the mis-specification **acknowledged**, the coincidence |
| §181 | REFUTED/RETRACTED | ⛔ `C63` NEVER WRITES `m_tb`. Three experiments were aimed at the operand of a word the device does not route to the ALU. | §1 **MEASURED**; §2 **FORCED** (read at source), §166 §3's SPECULATIVE half |
| §182 | REFUTED/RETRACTED | ⛔ my own next-task was misconceived, and `bit11-family.md` had refuted §166 §3 FOUR DAYS EARLY | §1 **FORCED** (two independent measurements in the owning note, re-read not |
| §183 | OPEN | the bit-11 family rides exactly TWO carriers, and that gives it the minimal pair §7.2 said it lacks | §1 **MEASURED** (null computed first, a pre-registered MISS); §2 **MEASURED**, |
| §184 | OPEN | the alternate `lo12` decomposes, and there is exactly ONE payload with a decoded sibling | §1 **MEASURED** (null computed first); §2 **MEASURED**, exhaustive over all 90; |
| §185 | OPEN | reading the alternate encoding as SELECTOR + VALUE: `C63` is a per-channel RESET | §1 **MEASURED**, exhaustive; §2 **INFERRED** from a FORCED construction, with the |
| §186 | CORRECTION | two corrections, both caught BEFORE a build: my own falsifier was circular, and the roadmap's headline defect is fixed | §1 **FORCED** (the circularity is structural); §2 **MEASURED** (read at source); |
| §187 | OPEN | the selector space is NOT `m_rf`, and a collision proves it | §1 **MEASURED**; §2 the artefact **acknowledged**; §3 **FORCED** by the collision |
| §188 | SHIPPED | the host payload's LSB was being dropped. SHIPPED, default → `0xB910E446A39B440F`. | §1 **FORCED** (two notes, by construction); §2 **FORCED**; §3 **MEASURED**, all four |
| §189 | SHIPPED | §188 reached the descriptors too; the read/write pairing confirms; P16's ladder does not appear | §1 **FORCED** (the arithmetic) ; §2 **MEASURED** (9 of 9 pairs; the CHORUS control); |
| §190 | REFUTED/RETRACTED | two of §189's three readings are REFUTED, both statically. The third is narrowed, not settled. | §1 **FORCED** (P5 is MEASURED and the arithmetic is decisive), with two bit-exact |

