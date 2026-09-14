# DECODE QUEUE — HANDOVER, 2026-09-14

**Read this before touching the decode queue.** Standing project rule: *check the handover first*.
Ten attacks were run on this queue in one session; two decoded, eight are nulls. The nulls are the
valuable part of this file — each closes a line and says why, so nobody walks it again.

## Where coverage stands

| region | start of session | now |
|---|---:|---:|
| KN5000 resident kernel (I-RAM 0…82) | 47.0 % | **61.4 %** |
| …header 0…59 | 56.7 % | **71.7 %** |
| …output stage 60…82 | 21.7 % | **34.8 %** |
| FRAME FLOOR (kernel + reverb) | 74.5 % | **80.1 %** |
| all 38 KN5000 body images | 80.4 % | 80.4 % |
| SX-WSA1R corpus (undecoded words 3091 → 851) | 37.5 % | **79.9 %** |
| **POOLED, as published** | — | 81.2 % (1501 undecoded of 8003) |
| **POOLED, RULE 9 de-duplicated** | — | **80.6 %** (1413 undecoded of **7273**) ← use this one |

⚠ **RULE 9 (§176):** the SX-WSA1R tree carries byte-identical duplicate images — 60 records resolve
to **52** distinct programs, so 730 pooled words are replicas. The duplicates are reverbs and are
better decoded than average, so de-duplicating **lowers** the headline. `decoded_selfcheck.py` prints
both figures side by side.

Mirrors **8003/8003** (pooled, `tools/upd6383d_diff.sh -p`, text AND the three execution
predicates); `dsp/verify.py` BYTE-MATCH OK; both trees regenerated with word columns **8003/8003**
identical (`regen_words_unchanged.sh`).

## What decoded, and why it worked

* **§122** — the C-format payload is an I-RAM address. Two routes: the region test (11 of 11 inside
  their own image, p = 6.6e-9) and the **relocation test** against the WSA1R's byte-homologous copy
  of the kernel header (§121). +11 words, kernel 47.0 → 60.2 %.
* ⛔⛔ **§161 → §162 → §164 → §165, RETRACTED TWICE AND THEN PARTLY EXPLAINED.** First the +99
  (the words carry two open axes and the run closed one); then the pointer result, on a replication
  that turned out to be unreachable by construction (§165) — so the seven nulls were predicted, and
  the measurement stands as the single-program observation it always was. Coverage is 81.2 %.
  What survives unconditionally is static and pooled: §156–§159.
* **§128** — **mode 1 is the register file.** `class4 & 7` is the addressing mode, so class 1 and
  class 9 were one question. Four measurements anchored the read half. +143 words.

**The method that paid, both times: a second copy of the same code at a different offset.** A field
that is an address shifts with a relocation; one that is data does not. No semantics, no null.

★ **A third payer, same shape: pool the two products and look at a field the earlier pass did not.**
§156–§160 did that to the alternate `lo12` encoding and to the table-lookup idiom:
* **`hi12` bit 6 is a third bit of the alternate-encoding flag** — `(hi12 bit6 AND NOT bit5) <=>
  lo12 bit11`, **0 exceptions in 6441** pooled ESC-clear words. `bit11-family.md` §9 had two bits,
  both in `lo12`; this one is in the other half of the microword. ⚠ The **mask is not identified**
  (bits 2/3/5 are all set on the two exception shapes) — say "bit 6, with the two `16E` shapes
  excluded", not "bit 6 and not bit 5".
* **The C63 idiom is 99 sites and exceptionless three ways**, and the class-6 `addr8` takes five
  values both products agree on: 24 (the proven LFO sine), **40 (the waveshaper — so the clip curve
  has 40 entries)**, 26/30/32. C-RAM cells `0x18` and `0x28` are written by **neither** the preset
  streams nor the boot blob, so `addr8` is a **count, not an address**.
* ⛔ **`cfmt_opcode.py` had been comparing product labels that never existed** — "KN5000"/"WSA1R"
  against `class_twins`'s "KN"/"WSA". Every per-product column printed 0 and the kernel-slot table
  selected nothing. Totals were unaffected. A column of zeros looks exactly like a real absence.

## The three blocks — 619 of the ~1358 remaining pooled words

### `ACT 0x0B` — 191 sole (62 KN + 129 WSA). THREE criteria measured blind.
* Anchored **only** on class A (fourth multiplicand route, FORCED under a 2-input ALU). §133
  checked whether that restriction is really the **cursor-fetch bit** rather than class A: it is
  not separable — every fetch-bit ACT-0x0B word *is* class A.
* §129 **withdrew the reason it was closed**: *"every ACT-0x0B delay word carries `addr8`
  0x20/0x30"* drops the population of a scoped measurement (`dram-matching.md` item J: "203 slots
  over the 83 algorithms where `#cells == #consumers`"). Six carry `0x60`, the FORCED write — two
  inside the KN5000's own algorithm images.
* **Criteria that failed, with their reasons:**
  1. SINGLE DELAY's lag-1001 ROM product — all six readings accepted (LEDGER §291, re-run).
  2. §130, the tempA hazard — beat its permutation null (0 of 48, null min 4) and **died to the
     per-action control**: 5 of 14 actions equally excluded.
  3. §133, the symmetric code (`ACT 0x0B` deposits what `SRC 0x0B` collects) — **0 of 488 at lag 1**,
     median lag 14, rank 8 of 16.
* ★ **§136: 86 % OF THE OPEN WORDS ARE DELAY ESCAPES** — 165 of the 191 sole-blocked. The 18
  class-A words are already decoded, and every "plain" ACT-0x0B word in the reverbs is one of them
  (`102.A.00.64B`), so `capture-signature.md` item F's *"BLOCK A needs ACT 0x0B"* is already
  satisfied and **the reverb is not where the open words are**. That also reframes §107's null:
  a09's three ACT-0x0B words are all escapes, so SINGLE DELAY was **the right population, measured**.
* **What would break it — now a searchable static condition, not a modelling job.** `mem<-bus` is
  one of the three survivors and §107 measured `mem[ptr]` live at every site, so a criterion with
  power must be sensitive to a `mem[ptr]` write **at an escape word** — which a09's echo is not.
  ⛔ **§137 RAN THAT SEARCH AND IT IS CLOSED.** Of the 165 escape sites, **134 (81 %)** do have
  their pointer cell read later in the same program — confirming §107 — but **0** have that reader
  inside a DF-I section interior, so the bit-exact oracle cannot be aimed at the code from the
  memory side either (§135 closed the section side). ⚠ A proximity cut ("reader within 3 of a latch
  word") returned seven candidates including the WSA1R's parametric EQ; all seven were program
  **ambles** (`w0` → `w1`). **When a span exists, test membership in the span, never distance to its
  landmark** — the same trap as §135, twice in one session.
  ⇒ what is left for this code is **hardware**, or an oracle anchored on a program whose ACT-0x0B
  words are escapes AND whose arithmetic the ROM pins. No such program exists in either corpus.

### `SRC 0x11` — 171 sole (54 KN + 117 WSA). A DEPENDENCY CYCLE, not a capture problem.
`DSP-DATAPATH-DECODE-HANDOFF-2026-09-11.md` states it: splitting `accb←acc` from `accb←P` needs a
program whose accb input **varies**, and every reachable program feeds it the frame-invariant
kernel-B constant — which is the very input route that is blocked. *"Capture campaigns cannot
settle accb… the break is the store/source-code decode from the bit-encoding (or hardware), NOT
another capture."* Confirmed there from three independent angles including the speculative ISA.
**Do not run another capture campaign at this.**

### `f31` 3…7 — 257 undecoded occurrences.
Downstream of the LFO rate defect §120 localised to **one word, `iw40`**. §132 measured the
documented-sibling route at exactly this field and it does **not** transfer: uPD6383 `ADD = 1`,
`HOLD = 2` against NEC uPD7725 `ADD = 5`, `NOP = 0`. The source-code match that made the rosetta
analogy credible is real and is **not** evidence about the ALU field.

## Lines closed this session — do not re-walk

| line | result |
|---|---|
| more class minimal pairs from the homolog pairs (§132) | **zero** aligned class substitutions; classes-4/6 stays at n = 2 |
| the class guard's missing 2×2 corner, class 0 (§132) | real asymmetry, **inert** — 221 words, 0 would decode |
| SRC/ACT codes exclusive to the WSA1R (§132) | **none**; one shared vocabulary, so its 851 words are blocked by the same codes |
| the documented sibling at the ALU field (§132) | codes **do not transfer** |
| `ACT 0x0B` = the write side of `SRC 0x0B` (§133) | **refuted**, 0 of 488 at lag 1 |
| `ACT 0x01` as the delay-data producer (§133) | **one word** in 27 images, not a field property (rule 9) |
| mode 3 / `class 3` (§131) | **exists** — the published class space is KN5000-local — but its addressing is undocumented and there is **no class twin** |
| the `0x820` targets as a strict NEXT-BLOCK pointer | **refuted**: 3 of 5 (KN) and 4 of 5 (WSA), weaker than §122's ζ (4/5, 5/5). `w31`/`w36` point **two** blocks ahead, consistently in both products. ζ is the right generality and `w40` stays the sole exception |

## Two method rules this session earned the hard way

1. **A null that moves is not a null that discriminates.** §128's first test was invariant under
   its own shuffle (mean 95.0, sd 0.0); §130's beat its permutation null and died to the
   per-category control. **Run the per-category control with the test, not after it.**
2. **De-duplicate before quoting a rate** (rule 9, `adjudication-round8` item E). §133's 70-of-91
   was one distinct word in 27 images.

## ⛔ §138 WAS RETRACTED — read this before chasing "the oracle has a target"

An earlier cut of this handover led with *"17 undecoded words sit inside a DF-I section, 8 of them
one instruction in the wah programs."* **That was wrong.** It scored section membership with a
**tempA live range** instead of `lle_oracle.py`'s own definition (five consecutive
coefficient-consuming **class-A** MACs plus the class-8 makeup). The claimed target,
`804.8.16.1DA`, is **class 8** — a shape the oracle does not model at all.

Corrected: **7** undecoded words sit inside a real DF-I section (97 sections, 498 words pooled) —
six multi-axis (`kernel w30`, `prog15_rock_rotary w65`/`w79`) and one `SRC 0x11`
(`prog15_rock_rotary w18`). **Zero** `ACT 0x1A`. Six of seven need several axes closed at once, so
it is a thin lead, not a sized next step. `prog39_parametric_eq` has none, which is still why the
oracle has never had to say anything.

★ **Method rule, earned three times in one session:** use the model's own definition of a region —
not a proxy for it, and not a landmark near it.

★ **The one lead that survives bounding (§139).** Of those 7, exactly one has `SRC 0x11` as its
**sole** open axis: `prog15_rock_rotary w18 = 0212A01452`, a class-A MAC inside the `w16…w21` run.
If the oracle could name its operand role it would anchor `SRC 0x11` **from the biquad rather than
from accb captures**, sidestepping the dependency cycle. ⛔ Three preconditions first, none met:
the run is SIX class-A words so the section boundary is inferred; `lle_oracle.py` **assumes** the
cell order `[b1, b0, b2, −a1, −a2, makeup]` rather than deriving it, and that order is established
only for `prog39_parametric_eq`; and instantiating a model validated on the EQ at an unvalidated
site is §135's problem again. **Establish the section, derive the order, then read the operand.**
★ **§140 did the first step: PRECONDITION 1 IS MET.** `prog15_rock_rotary` (algo 15) `w17…w21`
carries the full §7 signature — `mac.ta` (ACT 0x13) at `w17`, `mac.tb` (ACT 0x14) at `w20`, class-8
`post` at `w23` — and excluding `w16` (its annotation calls it an output-level gain) leaves exactly
the oracle's six cells, C-RAM `0x05…0x09` + makeup. `w18` is **index 1**, canonical operand `x0`.
⛔ **Precondition 2 is now named precisely**: deriving the order by stability needs the
**per-coefficient SCALES**, solved in `N-SINGLE-DELAY-RECURRENCE-2026-09-12.md` §10 for the **EQ only**. Two of the rotary's five
raw coefficients exceed `2^23` (15 353 414 and 8 958 128), so no uniform divisor applies and the
poles are not computable. ⛔ **§141 DID THAT AND IT FAILS.** The EQ's method is a **flatness test** whose winner is an
*identity* (`b0,b2 ×4, b1 ×2` makes the b-vector exactly `[1, a1, a2]`, so `H ≡ 1` — the bands are
unity inverters). A rotary has no reason to be flat, so the acceptance test evaporates; only
stability is left, and **186 distinct assignments survive it**. The chain is closed: precondition 1
met, precondition 2 refuted.
⛔ **§142 RETRACTS "the one wall".** I wrote that the ROM pins an answer in exactly two places. It
does not. **`dsp/tools/host_side.py laws` already extracts a VALUE LAW per parameter opcode** from
the firmware's own evaluators — `op 0x62 = CURVE_D[user]` at **1.000 dB/step**, `op 0x67 =
base + user·44100/1000`, `op 0x21/0x66 = lo + (hi−lo)·user/99`, `op 0x68 = const·user/180`, and
more. Each pins a coefficient's law and therefore its **scale**. The EQ and SINGLE DELAY anchors are
two *instances* of this mechanism, not the only two things the ROM pins.
★ **THE REAL GAP, and it is narrow.** The cell ← opcode map exists too, annotated and graded across
the disassembly — but it is **partial**. `prog15_rock_rotary` has only 6 cells mapped
(`0x00/0x01 = op0x61`, `0x04 = op0x62`, `0x10/0x14 = op0x66`, `0x1D = op0x74`) and **`0x05…0x09` —
the biquad section, §139's whole chain — is unmapped.**
⇒ **PRECONDITION 2, RESTATED: map algo 15's C-RAM `0x05…0x09` to their parameter opcodes.** Then the
laws pin the scales, then stability or a response picks the order. `host_side.py` already has
`cmd_descbase`, `cmd_regmap`, `cmd_spaces` — **host-side work with the tools present.**

## What would actually move this

* **Hardware.** Parked — `kn7000_mame/notes/HARDWARE-QUESTIONS-PENDING-FELIPE.md`.
* **A new anchored oracle** for one of the three codes. ⛔ **NOT the existing HLE — §135 measured
  it.** `dsp/hle/effects.py` line 9 says its own models are *"models of the decoded ALGORITHM
  (graded), not bit-exact to the chip"*, and the two oracles that ARE anchored cannot see
  `ACT 0x0B`: the biquad oracle is validated on `prog39_parametric_eq`, which contains **zero**
  ACT-0x0B words, and SINGLE DELAY's lag-1001 product is measured blind to it. In the EQ-bearing
  programs the code sits in program **ambles** and **delay escapes**, never in a filter section.
  A new oracle has to be anchored on a program that actually carries the code — the reverbs, where
  the HLE is graded rather than bit-exact. **That is the gap to close, and it is a modelling job,
  not a search.**
* **`iw40`'s driver** (§120). It is now decoded as `ldreg r20,#iw14` — a register load whose I-RAM
  address points **at** a block terminator where all nine siblings point **past** one. What supplies
  `P` there is the best-posed question left, and it has a known answer at each end: the hand-off
  live at ±2.9 M and the ramp at the ROM's 114.


---

# ADDENDUM — the state after §138…§149 (this is the current picture)

## Corrections to this file's earlier text, all measured
* **§138 RETRACTED** (see above). The "17 words inside a DF-I section / 8 in the wah programs"
  lead used a **tempA live range** instead of `lle_oracle.py`'s own definition. Corrected: **7**
  words, none `ACT 0x1A`.
* **§142 RETRACTS "exactly two anchors."** `host_side.py laws` already extracts a **value law per
  parameter opcode** from the firmware's evaluators. The EQ and SINGLE DELAY anchors are two
  *instances* of that mechanism, not the only two things the ROM pins. ⇒ the family can reach
  **837 of 1546** coefficient fetches (~54 %); the rest are fixed uploads with no evaluator.

## `f31` — the axis that moved this session
* **§146** — rule 4's gate is **passed**: `f31` 3/6/7 fire 4.9–5.8 M / 1.9 M / 2.0–3.0 M per
  program. ⚠ The bit-5 *exclusivity* is **static** (0 words with bit 5 clear), so a counter cannot
  test the 4-bit-field hypothesis. Population pooled is **120 words**, not the 53 the device says.
* **§147** — §231's COLLAPSED-OP census is a **machine** blindness instrument the static one misses:
  the four *resident* sites discard identically zero (product **and** acc-in) over 1.7 M executions.
* **§148** — `UPD6383_BX_F3 / _F6 / _F7` built and run. **HOLD ≡ the shipped collapse exactly**
  (406 report lines identical — the positive control). LOAD and ADD are observable, with **the same
  deltas (−49, −74) in two programs**. The pre-registered null is refuted.
* **§149** — ⛔ and the **ranking** criterion does not exist: `prog09`, `prog39` and `prog16` carry
  **zero** `f31 = 3` words, so every anchored criterion is blind to the axis by construction. Its
  carriers are the dynamics/distortion families, whose HLE models are graded.

## What the next pass should actually do, in order

0★★. ★★★★★ **EXTRACT THE KN1500. IT IS A THIRD µPD6383 PRODUCT AND ITS CHIP IS CONFIRMED.**
   (§204–§205, 2026-09-14. This outranks every item below, including the bit-11 item.)

   `dsp/tools/dsp_corpus_scan.py` scanned 56 files across six products. **Exactly one other
   product carries µPD6383 host streams: the KN1500**, in
   `roms/kn1500/technics_qsigt3c16079_5y68-j079_japan_9649eai.ic15.rest`, 9 strong streams at
   `0x1A414D .. 0x1AC18B`. kn2400, kn6000, kn6500, kn7000 and the 20 non-subprogram kn5000 ROMs
   (the negative control) have **zero**.

   ★★★★★ **Felipe confirmed the chip AFTER the scan found it**: *"KN1500 does use a D6383GF-3BA
   DSP (IC3)."* Service manual `KN7000/service_manual/technics_sx-kn1500_sm.pdf` — **image-only,
   render it, never grep it.**

   **Why this outranks everything else.** Every large block in this file is shut on what the two
   known corpora *contain* — mode 4 "no replication AVAILABLE as the question is posed" (§165),
   `f31` 3…7 "blind BY CONSTRUCTION" (§149), `SRC 0x11` a dependency cycle. Those are statements
   about the evidence. A third product is the only thing that changes them, and the method that
   paid twice (§122, §128) is exactly *a second copy of the same code somewhere else*.

   ★ **THE SCAN IS NOW GOOD ENOUGH TO EXTRACT WITH** (§206): restricting the opcode alphabet to
   the **measured** `{3, D, E, F}` — `{0,1,2,5}` belong to the coefficient streams, not these —
   and putting the kernel header/epilogue into the ground truth (they are real microcode no
   algorithm pointer points at) moves it to **block recall 39 of 42 (93 %), word recall 3034 of
   3237 (94 %), precision 39 of 41 (95 %)**. The KN1500 extraction goes from 9 streams / 7 blocks
   / 737 words to **37 / 31 / 2389**, with 175 distinct new words, and every shut axis present:
   `SRC 0x11` 98 occ, `ACT 0x0B` 146, `f31` 3…7 28, bit-11 24, mode 4 17, class 6 15.

   ⛔ **But still DO NOT quote a decode rate from it**: it selects streams by vocabulary match, so
   any rate computed from it is manufactured: 0.90 → 92.4 %, 0.70 → 85.3 %,
   0.50 → 52.3 %, 0.00 → 2.7 % (`--bias` prints the curve). I computed "+1.09 pooled points" from
   the top row before running that sweep; it is retracted. Note too that the strict count would go
   **1413 → 1469** — RULE 9 in reverse.

   **The job:** extract the pool through the KN1500's own directory structures, the way
   `gen_wsa1_dsp_disasm.py` does for the WSA1R, then RULE-9 de-duplicate, then quote a rate.
   ⚠ Already tried and refuted: a 68-entry `u32le` array at `0x1A318D` immediately before the
   region resolves **3 of 68** entries against every base in `0x1A3000..0x1A5000`, and its entries
   step 10…40 bytes where streams are 400…20 000. It is not the table. Do not repeat that search.
   The KN1500 is a TLCS-900 machine, so the loader is in its own firmware — find the interpreter
   loop the way `kn5000_dsp_extract.py`'s header documents finding the KN5000's.

   ★★★ **THE NEXT JOB, precisely.** The KN1500's kernel header and the KN5000's **open with eight
   byte-identical words** and align 83 % (34 of 41). The relocation test runs on it and reproduces:
   two minimal pairs differing only in `addr8`, both by exactly **+0x40** (`C42417820`/`C42457820`,
   `C0A471820`/`C0A4B1820`). ⛔ Both are C-format words `decoded()` already admits, so it is an
   independent third-product confirmation of §122 and **worth zero words**.
   ⇒ **Align the KN1500's BODIES against the KN5000's and the WSA1R's.** That is where a minimal
   pair can land on an axis that is actually open. `topology_fingerprint.py` and
   `idiom_sequence.py` already do cross-product program matching.


0★. ★★★★★ **START HERE: THE BIT-11 ALTERNATE ENCODING. 271 words, ceiling 84.3 %, nine shapes,
   two of them 87.6 % of the prize.** (§196–§201, 2026-09-14 — this item replaces the old item 0.)

   `python3 dsp/tools/bit11_prize.py` prints all of it and is the queue:

   ```
      A  bit-11 words:  187 total, 169 UNDECODED        closing them: 80.6 % → 82.9 %
      B  undecoded words gated INDIRECTLY through the class-6 idiom:  102
      A + B = 271 words  →  84.3 %

      lo12   total  undec   by product
      C63      99     99    KN:53 WSA:46      <- and it carries NO OPERAND (see below)
      8BC      49     49    KN:24 WSA:25
      822       7      7    822/839/827/864/921/C62/F22 are 21 words between them
   ```

   It is the **third**-largest open-axis block on its own (`bit-11 encoding, class 0` = 132, behind
   `ACT 0x0B` 159 and `SRC 0x11` 139) and the **largest** once what it gates is counted — and unlike
   those two, which are documented dead ends in this file, it is newly opened.

   ★★★ **The one static fact to start from.** `bit11_prize.py` part D: `C63` has exactly **two**
   full-word forms over all 99 pooled occurrences — `040000C63` ×87 and `142000C63` ×12 — with
   `class4 = 0` and `addr8 = 0x00` in every one. The only field that varies is `hi12`, i.e. `f31`:
   **0 = LOAD, 1 = ADD**. A word whose sole variable field is the accumulator function is an
   ALU-half instruction. And that `f31` correlates **99 of 99** with the following class-6 word's
   `lo12` (`040`↔`4CD`, `142`↔`407`), so the pair is one two-word instruction.

   ⛔ **What has already been ruled out — do not redo any of it.**
   * All six index sources: `acc mod n`, the ACT-destination variant, `(n × acc) >> 23`,
     `(n × cell 0x07) >> 23`, `m_k` (the constant 24) and `m_p >> ACC_SHIFT`. The first three are
     refuted on §196's *direct* histogram of `k`, the last three on direct censuses of the
     quantity. **Do not build a seventh C6LUT arm.**
   * The bit-11 ALU half as the missing phase generator (§197): `UPD6383_ALT11ALU=1` fires
     4 726 638 times and **every cell still VARIES**. Pre-registered criterion, cleanly failed.
   * A phase accumulator anywhere in the machine: not in D-RAM (§228) and not in the register file
     (§198, which had never been walked). The one constant-step riser, `rf[50]`, is a **toggle** —
     range one step wide.

   ★★★★ **AND ONLY ONE THING IS OPEN ABOUT THEM** (`bit11_prize.py` part E, §202). Of the 169:
   **169 of 169 are in a characterised addressing mode (0/1/2)** and **158 of 169 carry one of the
   three anchored accumulator functions**. `_alu_half_anchored()` scores 0 % *by construction* —
   `dsp_disasm.py:718` refuses every bit-11 word as its first test, a deliberate policy. So the
   family turns on a single question: **what does the alternate `lo12` mean?** ⚠ Admitting the 158
   on §112's two clauses would be 80.6 % → 82.8 %, and that is a GRADING change — the owner's call,
   deliberately not taken.

   ★★★ **AND THE DECOMPOSITION ALREADY EXISTS — `dsp/tools/bit11_fields.py` (§203).**
   `lo_sel = lo12 & 0xFF`, `lo_mid = (lo12 >> 8) & 7`. Pooled, the family fills **11 cells of a
   possible 1024 (1.1 %)** — four `mid` values {0, 1, 4, 7}, nine `sel` values, nearly all present
   in both products. `lo_mid`'s docstring still says "residue: 0 at all 10 corpus sites"; it was
   written before the corpus was pooled and `mid` is live.
   **Two minimal pairs** isolate it: `sel 0x21` at mid 0 (13 words, all decoded as the C-RAM
   pointer load) vs mid 1 (`050000921`, open); `sel 0x22` at mid 0 vs mid 7 (`142000F22`, open).
   And every `mid ≠ 0` cell carries `addr8 == 0` — 4 of 4 cells, **p = 0.0885**, suggestive only.

   ★ **Where to point the first test.** `8BC`'s dominant form is `8801308BC` ×37: `class4 = 1`
   (mode 1 = the register file) with `addr8 = 0x30` — and §179 put the class-6 table port at the
   mode-1 register file `0x1D..0x3C`, so `0x30` is *inside that window*. The family's second-largest
   shape is a register-file access aimed at the table its largest shape's idiom reads. Its other two
   forms carry `class4 = 0, addr8 = 0x00` exactly like `C63`. ⇒ a relocation-style test (the method
   that paid in §122 and §128) has a target.

   ⚠ **The live upstream question, if someone wants the LFO rather than the encoding:** what writes
   cell `0x07` 1 570 842 times? §199 attributes only **12 442** writes to `store_mode()`, all with
   step 0. It is **not** the input deposit — §200 has the device print its own deposit addresses and
   they are `0x01` (L) and `0x04` (R), from base `0xFF`.


0. ⛔⛔ **MODE 4: ONE WITNESS, AND NO REPLICATION IS AVAILABLE AS THE QUESTION IS POSED.**
   Do not spend another build here without reading this.

   * **The arms are built, fire, correctly placed, and every run is fingerprinted (§193).**
     `UPD6383_CLS4PTR` (class-4-only pointer advance) and `UPD6383_ST4DEST` (0 = D-RAM at the
     pointer, 1 = register file at `addr8`, 2 = suppressed, 3 = D-RAM at `addr8`). None of that is
     the problem.
   * **On EXCITER both arms produce a large, clean, two-sided effect.** On seven other programs they
     do not — and `band_reach.py` shows **that was predictable**: EXCITER's class-4 word writes
     `p = 75, 79` and its `op0x70` band reads `p = 75..82`, while PEQ+CHORUS writes `p = 7, 13` and
     reads `p = 75..84`. **EXCITER is the only one of the eight where the arm can reach the band.**
     The seven nulls are predicted negatives, not failures to reproduce.
   * ⛔⛔ **THE TRAP, and it is why this cannot simply be re-run.** The membership walk advances the
     pointer on classes 2 and A — and whether class 4 *also* advances is the open question. Run it
     both ways and the verdict flips on exactly one program, EXCITER (no-move ⇒ reaches; V7 ⇒ does
     not). So EXCITER **discriminates**, and for the same reason membership cannot be used to
     **select** programs while "reaches" depends on the answer. Nor do the read-set shapes separate
     (8 vs 4+4; the arm-ON census matches neither).
   * ⇒ **Mode 4 has exactly one witness.** §161 and §163 are single-program observations and are
     graded as such. The 99 words stay undecoded, and they carry a *second* axis anyway (the bit-4
     store target, §162).
   * ★★ **THE RULES THIS THREAD COST, in order of transferability:**
     1. Before promoting, enumerate the word's open axes (`acc_blind.open_axes()`) and close them
        **all** or promote none. §162.
     2. Select experiment programs by **membership**, not position, and report the computation, so
        a null can be told apart from an unreachable. §165.
     3. A criterion that presupposes the hypothesis is not a criterion — and that includes the
        *program-selection* criterion, not just the acceptance test. §165.

0. ⛔⛔ **CLOSED — THE C63 IDIOM's INDEX CANNOT BE FOUND FROM ANY REGISTER. DO NOT BUILD A SEVENTH
   C6LUT ARM.** (§189–§195, 2026-09-14, after this section was written.)

   The idiom is `C63 (alt-enc) | class-6 (table read) | class-4`. **`C63` carries `lo12` bit 11, so
   it has no SRC and no ACTION field, and the device executes NOTHING for it** — §97's swallow
   census, in the same run that produced everything below: `lo12 C63 : 3 150 504 times`, twice per
   frame, every frame. **The first word of the idiom is the one that would compute the index, and it
   is unimplemented.** No choice of existing register can supply the index, because the producer is
   not modelled.

   THREE candidates are refuted by direct measurement of the quantity: `(n × cell 0x07) >> 23`,
   `m_k` (constant 24, ONE change in the run) and `m_p >> ACC_SHIFT` (zero on 90.9 % of hits).
   ⚠ **The other three are UNGRADED, not refused** — `acc mod n`, the ACT-destination variant and
   `(n × acc) >> 23` were judged on the §157 TAPMOD census (blind, §180) and §186's ranking (void,
   §187). Their verdicts died with their instruments. ⛔ **And §183's phase is RETRACTED**: cell `0x07`
   changes every frame and wraps **87 564** times, and §228's own rise census reports **VARIES for
   every cell in the machine** — there is no monotonic phase ramp to index with.

   ⇒ **The blocker on class 6 is the bit-11 alternate encoding** (`bit11-family.md`), not the
   class-6 word. That is where the +90 words live. Everything from here to the end of item 0 is the
   superseded plan, kept because its MEASURED parts (the table port, the amplitude) still stand.

0-old. ~~**the C63 idiom is 19 % of the gap and everything but ONE thing is measured**~~
   §177 ranks it top by leverage — `0124011CE` ×99, `040000C63` ×87, `0006184CD` ×53, `0006284CD`
   ×34 = **273 occurrences**. **90 of them have `{SRC 0x13, class 6}` as their only open axes**
   (`ACT 0x0D` is already anchored), so closing class 6 is **+90 words, 80.6 % → 81.8 %**.

   **What is now MEASURED** (none of this existed a day ago):
   * the **table port** — mode-1 register file at `0x1D`, 32 cells, loaded per effect, written via
     host tag `0x15` (`upd6383.cpp:1998`). Contents identified in two effects: a 32-entry
     odd-symmetric soft-clip curve (EXCITER, §178) and `0.95·sin(2πk/24+0.1)` to max error 0.0000
     with **the first eight entries repeated as a wrap-guard** (PEQ, §179).
   * ⛔ ~~the **phase** — D-RAM cell `0x07`~~ **RETRACTED (§190–§192).** The identification used
     only a range and a change count, which cannot tell a ramp from a noisy signal. Measured
     directly: `0x07` changes **every** frame and wraps **87 564** times (a ~18-frame period), with
     steps 114 … 8 383 192. The device's own legend calls `05 07 85 87` the per-unit **input** cells.
   * the **amplitude** — the DEPTH parameter, measured **2.0000×** across a 30-step edit (§185).
     ⇒ **there is NO missing scaling step**, and the `±240 sweep` three arms were judged against was
     the wrong expectation all along.
   * a **criterion that passes an off-control** — cell `0x0F`'s behaviour (§181). ⚠ Its *span* is
     order-independent and so cannot rank index forms (§185); its *change count* can (§186).

   ⛔ **THE ONE OPEN THING: the index form.** `lfo-ramp.md` §10's anchored increment gives the
   expectation — 1 570 842 phase updates × 114 = 21.3 wraps of 2^23, so a monotonic 24-entry sweep
   steps ≈ **512** times. Measured: `=1` adds **7 110** (~14×), `=4` adds **102 331** (~200×).
   **Neither is right**, and `=4` — the form whose arithmetic fits exactly,
   `(24 × 8 388 602) >> 23 = 23` — is the worse by 14×.

   ★★ ✅ **DONE, AND IT WAS NEITHER.** The arm reads the cell it means to (§187), and the cell is
   not a ramp (§190–§192). The expectation was the thing that was wrong. ⇒ see the CLOSED banner at
   the top of this item; the index question is not answerable from a register.
   ★ Second candidate if the read is correct: §179's wrap-guard implies a **windowed** read of W
   consecutive entries, which would scale the expectation to `512 × W`. `=1`'s 7 110 gives W ≈ 14,
   `=4`'s gives W ≈ 200; the guard is 8 cells wide, so neither matches cleanly and W is worth
   deriving from the microcode rather than fitted.

0a. ⛔ **`ACT 0x01..0x06` IS CLOSED TOO (§175).** §167 characterised it — an enumerated
   destination bank, 6 of 6 pair exchanges at p = 1.1e-9 — and §174 put it top of this queue. One
   command closed it: 15 KN5000 programs carry these codes, only 4 also carry an `op0x70` band, and
   in **0 of those 4** does a band read a cell such a word writes. The other eleven carry no band at
   all. ⇒ same state as `f31 = 3`: **separable, characterised, unrankable.**
   ★ **Both leads this session named are now measured shut.** `f31 = 3` (§149), `ACT 0x0B` (§135),
   `ACT 0x01..0x06` (§175) and the `op 0x72` dynamics reference (§170/§173) are all blind to every
   anchor the project owns. That is the real state of the queue, and it is not a tooling problem.
   ★★ **RULE that would have saved this session two builds and four retractions**: ask §149's
   question FIRST, and ask it by **membership** — does the model's own section read a cell this word
   writes — not by **position**. §160 asked it first and still failed, because it asked the
   positional version and admitted 8 of 8 programs that the membership version admits none of.

0b. **The other 40 class-test-refused words are the same shape of opportunity, not yet worked.**
   `lut_idiom.py --classgate` now lists classes 3 (14), 5 (2), 6 (12) and 8 (12) still undecoded
   with an anchored ALU half. Each needs its own mode settled the way §158/§161 settled mode 4 —
   and §158 already did half the work for class 6 by showing its `addr8` is a table count.
   ⚠ Class 8 is in `alu_decoded()`'s admitted set already; its 12 are refused by `dram_dir()`
   (`addr8 = 0x0B` has bit 6 clear), which is a different question.

1. ⛔ **THE BIT-EXACT DYNAMICS REFERENCE: the `op 0x72` route is CLOSED. Do not re-run the
   compressor.** It remains the item that would pay most (§149: `f31 = 3`, 56 sole-axis words, AND
   §135's `ACT 0x0B` job, 191) — but both routes to it are now measured shut, by two independent
   methods that agree:
   * ⛔ **Static (§170)**: all four `op 0x72` cells hold `0x600000` = exactly 0.75, which §153's law
     produces at **no integer knob position** at any of §154's three scales; `op 0x72` is 8-of-8
     "low 16 bits zero" against a 35 % corpus base rate (p ≈ 2e-4).
   * ⛔ **Dynamic (§173)**: with the parameter actually moved and the uC-IF stream captured, the
     cell is rewritten `600000` **75 times unchanged** through the whole edit phase.
   ⇒ §153's gain law has no output to validate against, in ROM or in a capture. **Pick a different
   dynamics program, or a different anchor.** ★ Do NOT read the eight floating-point helpers
   (`0x03dd36` &co.) — that would validate an implementation against nothing.

1a. ✅ **WHAT THE THREAD BUILT, and it is reusable for any effect (§171–§174).**
   * **The editor is mapped, measured**: TYPE = row 1 (row 2 duplicates it); **parameter cursor =
     row 3** (`RAM[0x8D9D]` steps ~6 per press and wraps after ~16 fields — a screen position, not
     an index, which is why index-hunting missed it); **VALUE = row 7 = `CPL_SEG7 0x20`**
     (`RAM[0x2978]` +1 per press, saturating at 26 on the PEQ's 27-entry list).
     ⚠ `-paramlist.md` §1.3's "TYPE / PARAMETER / VALUE" describes the **LCD legend**, not the key
     matrix. `peq_gain.lua` is corrected and its header now says so.
   * **A live capture pipeline**: `op72_live.py` replays a uC-IF capture into a cell-resolved,
     write-ORDERED coefficient map. ⚠ The KN5000 pokes coefficients as **`0A`-led host packets
     inside `cmd 0x01`**, not only as `cmd 0x02` records — a parser that reads only `cmd 0x02` sees
     nothing and it looks exactly like "the machine wrote nothing".
   * **Acceptance test passes on the PARAMETRIC EQ**: driving VALUE moves 13 coefficients off their
     defaults, and cells `0x05`–`0x08` / `0x0E`–`0x11` take 80–90 distinct values.
   ⇒ **live (knob, coefficient) data is now obtainable for any effect and any parameter.** That is
   the instrument §142's value-law family always wanted; it just does not reach `op 0x72`.

2. `UPD6383_BX_F6` / `_F7` are built and unused — 3 + 44 pooled words, same method as §148.
3. `SRC 0x11` stays a documented **dependency cycle**; do not run another capture campaign at it.
