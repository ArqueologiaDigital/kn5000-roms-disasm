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
| **2** | the section index — every section, one line each | generated, below |
| **3** | the sections themselves | `SPECULATIVE-APPLIED-REGISTER.md` |

⚠ Tiers 1 and 2 are **generated** by `tools/gen_ledger.py` from the C++ source and the register's
own headings, so they cannot drift. Tier 0 is hand-written. **Re-run the generator after any
section or mask-bit change**; do not hand-edit `LEDGER.md`.

---

## TIER 0a — THE CURRENT BLOCKER  (§227, unmoved by §228/§229/§230/§231/§232/§233/§234, 2026-09-04)

> ### ★★★★★ §234 — READ THIS BEFORE QUOTING SINGLE DELAY's LAG, AND BEFORE RE-OPENING `ACT 0x0D`/`0x0E`
>
> **THE PAIR THE DEVICE SHIPS — §133's selector `(1, 7)`, `ACT 0x0D: acc <- bus`, `ACT 0x0E: P <- bus`
> at the multiply's scale — IS CONFIRMED FROM DISK, `1 of 49`. AND THE FALSIFIER §233 PRE-REGISTERED
> AS LIVE REACHES IT AND CANNOT JUDGE IT.**
>
> * ✔ **PARAMETRIC EQ's ENTRY WINDOW decides it** (`gate_settle.py act0d0e`): a39 `w0..w13` and
>   `w53..w67` run with **acc = P = 0 at frame start and the sample in the cell the entry READS**
>   (`0x05` / `0x0F`). 2 of 49 pairs deliver BOTH channels to the designer's biquad at 0.198 dB and
>   keep them apart; a junk-pre-load control kills the runner-up (44.876 dB). ★ **three-codes.md
>   item A is RETRACTED**: its "144 machines identical" was `peq_ir()`'s pre-load of the sample into
>   acc and P every frame — the injection presupposed the answer (§233 item E's shape, other harness).
> * ⛔⛔ **SINGLE DELAY's lag 1001 is NOT independent of this pair.** The criterion fires (9208/9208)
>   and separates readings (5 outcomes over 49), but under the shipped pair a09 returns the **SAME
>   ROM product 45074 at lag 500**: `0x0E` at `w45` overwrites P with the stage-0 value one word
>   before the head write `w46` reloads `acc <- P`. Both lines are live under both readings; the
>   stage-1 product reaches `acc` at `w45` and is discarded at `w46`. **Every SINGLE DELAY number
>   since §230 was taken with the pair INERT** — `(tA<-bus, tA<-bus)`, a no-op at all eight sites —
>   on a menu that could not execute the shipped reading. §230's VALUE control survives at either
>   lag; the lag is **hardware question Q4** (`kn7000_mame/notes/HARDWARE-QUESTIONS-PENDING-FELIPE.md`).
> * ⚠ **`sd_rerun.py scan` had CRASHED on every invocation since §230** (`KeyError: 46`); §233's
>   "already enumerates `act0d × act0e`" described a command that had not run. Repaired, ungraded.
> * ★ Corpus (`act0d0e_corpus.py`, 11 of 11 vs §232): `0x0D` is followed by `0x0E` at **157 of 202**
>   (×9.87) — a fact about `0x0E`'s operand, not `0x0D`'s destination; the consumer census's null
>   has no power. **The corpus cannot separate the seven readings.**
> * ⚠ **a10 MULTI TAP DELAY (`sd_rerun.py multitap`) RAN TO COMPLETION AND GRADES NOTHING**: no pair
>    reproduces its three descriptor taps (best **1 of 4** for 42 pairs; **0 of 4** for 7, **the shipped pair
>    among them**, no non-zero output in 27085 frames) — rule 20's known-good case fails, so the harness is
>    evidence for or against nothing. Declared gaps: two ALT words run as no-ops, three coefficient fetches
>    beyond the 15-cell upload. ★ The seven at 0 of 4 are set-identical to the seven the PEQ pre-load
>    control lists at 999. OPEN residue, filed with Q4. `data/S_234_sd_multitap.log.gz`; re-run byte-identical.
> * ⛔ **Neither code is ANCHORED**: confirmed in one context (PEQ, device §133 + model §234); its
>   consequence in the other (delay programs) is a lag only the chip can confirm. Anchoring waits on
>   Q4, not on more static work.
> * Reproduce: `python3 dsp/tools/act0d0e_corpus.py` · `python3 dsp/tools/gate_settle.py act0d0e` ·
>   `python3 dsp/tools/sd_rerun.py act0d0e` · `python3 dsp/tools/sd_rerun.py multitap`.
> ⇒ **THE QUEUE'S TOP ITEM IS NOW `SRC 0x11` (+49), AT `iw11/16/17/19/92` — CORPUS FIRST, THEN A
> DEVICE ARM** (both known-mathematics harnesses are blind to it by construction; §234 §4.2).
> ⛔ **THE BLOCKER IS UNCHANGED: *what does the coefficient base `0x90` MEAN?***

> ### ★★★★★ §233 — READ THIS BEFORE QUOTING A FALSIFIER, AND BEFORE RE-OPENING `SRC 0x00`
>
> **`SRC 0x00` IS DECIDED — `1 of 7`, AND THE READING THE DEVICE SHIPS SURVIVES. AND ONE OF THE
> TWO FALSIFIERS THAT DECIDED IT WAS NEVER LOOKING AT THE CODE AT ALL.**
>
> * ✔ **`SRC 0x00 = mem[ptr]`.** SINGLE DELAY's lag-**1001** ROM product accepts it with sample
>   **45074** and refutes `P`, `acc`, `zero`, `DR`, `tA` and the **global** `coef`: under all six,
>   **no injection cell in the entire 256-cell pointer space** puts a non-zero datum into the
>   delay line. a09 carries 9 `SRC 0x00` words and one is the **HEAD WRITE `w46`**.
>   ⛔ **The null-routing rival is now REFUTED BY EVIDENCE**, not by `action00-discriminator.md`
>   item I — which `adjudication-round6.md` §14 voided and which `upd6383.cpp` was still citing.
> * ⛔⛔ **PARAMETRIC EQ's `0.198 dB` IS NOT A FALSIFIER FOR EVERY CODE a39 CONTAINS.** §232 §7.2
>   pre-registered it for `SRC 0x00` because a39 carries 8 such words. The harness executes a
>   **9-word EXCERPT** (a39 `w5..w13`, ×10) and the intersection is **EMPTY**: unconditional fired
>   count **0**, all seven readings **0.198 dB**. ⇒ ★★★★ **A PROGRAM'S WORD COUNT IS NOT A
>   HARNESS'S REACH. Reach-test a criterion — print its FIRED COUNT — before quoting it.** A
>   patched-excerpt control moves 6 of 6, so the sweep is live and the blindness is the excerpt's.
> * ⚠ **A HARNESS CAN PRESUPPOSE THE ANSWER IN ITS INPUT INJECTION.** `sd_rerun.py`'s `derive_p0`
>   places the head write's pointer on the driven cell — i.e. it injects the audio exactly where
>   `mem[ptr]` would read it, so every rival is silent by construction. Removed by sweeping the
>   injection cell over all 256 (the walk is `p0`-invariant mod 256). **Rule 22, and the reason
>   the refutation is a statement about all 256 placements rather than about one.**
> * ⚠ **LIMIT: only the GLOBAL `coef` (mask bit 57, which §146 measured railing unit 1 at 98.9 %)
>   is refuted.** None of a09's nine `SRC 0x00` words is a coefficient consumer, so bits **58/59**
>   — §145/§148's **gated** `coef` — fall back to `mem[ptr]` here and are invisible. Still open.
> * ★ Corpus: **580 of 622** non-C-format words, not `572/599` and not `605/648`. Eighth C-format
>   contamination. The **+348 price is unaffected**.
> * Reproduce: `python3 dsp/tools/sd_rerun.py src00` · `python3 dsp/tools/gate_settle.py src00`.
> ⇒ **THE QUEUE'S TOP ITEM IS NOW `ACT 0x0D` + `ACT 0x0E`, TOGETHER, IN SINGLE DELAY** (§233 §4.2).
> ⛔ **THE BLOCKER IS UNCHANGED: *what does the coefficient base `0x90` MEAN?***

> ### ⛔⛔ §231 — READ THIS BEFORE SPENDING A PASS ON DECODE COVERAGE
>
> **THE OPERATION FIELD IS NOT WHERE COVERAGE LIVES. THE ROUTING GUARD IS — BY 10×.**
>
> `alu_decoded()` is a **conjunction**, so only its FIRST failure is observable. Mirrored over
> the 3057-word corpus (`dsp/tools/f31_367.py`, self-test **1178 of 3057 = 38.53 %**, reproducing
> the strategic review's own figure):
>
> ```
>    THE WHOLE CORPUS, BY FIRST REFUSING GUARD
>      1178  DECODED
>      1139  routing / SRC-or-ACTION NOT ANCHORED   <-- 60.6 % of everything undecoded
>       546  CLASS
>       106  OPERATION (the whole f31 switch, ALL EIGHT CODES)
>        68  FORMAT (C-format)
>        20  GUARD 7
> ```
>
> ⇒ ★★★★★ **Solving `f31 ∈ {3,6,7}` COMPLETELY moves coverage `1178 → 1186` = `38.53 % → 38.80 %`
> — EIGHT WORDS.** 41 of the 53 are refused earlier by the ROUTING guard, 4 by CLASS. `f31 4/5`
> (§133's alias) is worth 23. **The entire operation field, all codes, is worth at most 106.**
> ⛔⛔ **AND THE SENTENCE THAT USED TO FOLLOW HERE IS REFUTED — §232, 2026-09-04.** It read
> *"the routing guard's population is the SAME ONE §229's fabricated-zero census counts"*, and it
> steered this queue for a month. **It is a SUBSET, and it is the half with no coverage in it.**
> §229's six codes `SRC 0x01/05/06/0A/13/1C` are **173 corpus words**, and anchoring **all six
> together** is worth **0 NEWLY DECODED WORDS** (86 are refused earlier by CLASS; of the 87 that
> reach the guard, 41 keep an unanchored `ACT 0x08` and the other 46 walk into GUARD 7).
> ⇒ **the silence population and the coverage population overlap in NAME and are DISJOINT IN
> VALUE.** Reproduce: `python3 dsp/tools/routing_census.py`.
> ★★★★★ **WHERE THE ROUTING PAYOFF ACTUALLY IS (§232):** the ceiling is `1178 → 1932` =
> `38.53 % → 63.20 %`, **+754**, and **97 % of it sits in EIGHT codes** — `SRC 0x00` **+348**,
> `ACT 0x0D` **+124**, `ACT 0x0E` **+110**, `SRC 0x11` **+49**, `ACT 0x0B` +19, `SRC 0x08` +10,
> `ACT 0x08` +9, `SRC 0x0B` +7. ⚠ The top four are exactly the codes `upd6383.cpp` **already reads
> SPECULATIVELY**, so "unanchored" there means *modelled on a guess*, not unmodelled.
> ⛔ **Rule 4 still governs, and §232 applied it: of 33 unanchored codes, 16 are CLOSED by a
> measured-constant index (worth 13 words), 8 are OPEN (worth 668), 9 are NOT RESIDENT in the
> vehicle and are UNMEASURED, not measured-constant.**
>
> ⛔ **`f31 ∈ {3,6,7}` IS DEAD END 44** — off by one, a spandrel of base `0x020`, and measured
> **not load-bearing** (discarded product `min 0 max 0 nz 0` at all four sites, 3 611 996
> executions, both buckets, against a control that discards **2 669 493** non-zero products
> elsewhere). ⚠ And the two defects at `w78` are **separable and both dead**: `w78`'s ACTION is
> `0x07`, **not `0x00`**, so the fabricated `SRC 0x0A` operand never reaches the accumulator's bus
> term at all — §229's *"`w78`'s central null is partly our own fabricated zero"* is true of the
> **store**, not of the presented accumulator.

> ### ★★★★★ §229 — READ THIS BEFORE QUOTING ANY NULL
>
> **THE OUTPUT STAGE'S OPERANDS ARE 28.492 % ZEROS *WE* INVENT**, and its four distinctive
> words are executed as *"hold, no product"*. Both facts land on **`w78`** — the word
> `§211`'s central null is measured at.
>
> ```
>    FABRICATED ZEROS (src_term()'s `default:'), per REGION -- quote beside any null:
>      kernel A  0.000 %    kernel B  0.000 %    body 1  0.000 %
>      body 0    8.772 %    EPILOGUE 28.492 %    TOTAL 9 832 536 / 246 952 062 = 3.982 %
>      sites: 0x05@iw60  0x01@iw61  0x06@iw68  0x0A@iw78 | 0x13@iw99/108/140/149  0x1C@iw111
>
>    f31 x hi12 BIT 5 -- the corpus rule, confirmed DYNAMICALLY:
>      f31 in {3,6,7} with bit5=0 :  0  in 246 952 062 executions   (corpus: 53 of 53)
>      f31 in {3,6,7} with bit5=1 :  4 424 994, at EXACTLY FOUR SITES
>      iw63(3) iw70(3) iw75(7) iw78(6)  -- ALL EPILOGUE, all words the disasm cannot name
>      ⚠ our model runs all four as `op = f31 & 3' => HOLD, NO PRODUCT
> ```
>
> ⇒ ★★★★★ **`§70` AND `§211` ARE NOT THE SAME KIND OF NULL.** `w73` resolves `SRC 0x10` = the
> accumulator and its `f31` is outside the bit-5 family. `w78`'s **only** operand is a
> fabricated zero **and** its operation code is collapsed. Both print `mean 0.0 span 0`;
> **only one is a statement about the chip.**
> ⇒ **`m_rf[0x8C]`'s permanent zero (1 108 254 stores, 0 non-zero) is 100 % OURS.**
> ✔ **`m_rf[0x8D] = 0x009B26` SURVIVES** — its non-zero stores come from a third site.
> ⛔ **NOT A LICENCE TO IMPLEMENT ANYTHING.** Dead end 4 / rule 4 still forbid the six SRC
> codes; §7.1 of §229 pre-registers the `f31` 3/6/7 arm with its falsifiers, **default OFF**,
> and requires `SRC 0x0A` be done **SECOND, never jointly** — `w78` carries both candidates.
> ★ **UPLOAD LEDGER, and it ends an inference:** 12 runs, **8 distinct images**, matching the
> offline corpus **4 of 4** (KERNEL 60, EPILOGUE 23, CHORUS load 84/70 w, ROOM REVERB 1 load
> 200/133 w). ⚠ **Body 0's region is 116 slots holding a 70-word image — `I-RAM[154..199]` is
> never uploaded.** Declare that 46-slot tail wherever a body-0 denominator is quoted.
> ⚠ **§38's "frame 264 002" is a 48 000 Hz figure (5.500 s).** The last upload measures frame
> **246 078 = 5.581 s** on the 44 100 clock. Convert before comparing.
> ⛔ **STRUCK, NOT DEFERRED:** the `f98` cross-unit A/B (**NOT VIABLE** — its `f98=2` half is a
> structural zero at `iw207` in nine arms, and a kernel pair `w16`/`w17` is already co-resident)
> and the ROCK ROTARY `hi12` bit-5 A/B (**VOID BY CONFOUND** — bit 5 is read in exactly ONE
> place in the device, the nop guard, so the A/B measures our dispatch table and nothing else,
> and the review's own kill-condition cannot fire).


> ### ★★★★ §230 — READ THIS BEFORE QUOTING ANY **CONTROL**
>
> **THE PROJECT'S WORST CONTROL IS REPAIRED, AND ITS MOST-QUOTED BATTERY IS ONE CHECK.**
>
> **1. SINGLE DELAY's `+0.02149296` IS TWO-SIDED AGAIN.** It used to **reject** the corrected
> machine and **accept** the doubly-defective one. Repaired, `python3 dsp/tools/sd_rerun.py control`
> **ACCEPTS** the corrected machine at lag **1001** with sample **45074** and **REJECTS seven**
> others — `cursor −1`, `reversed`, `reversed + cursor −1` (the one it used to accept), the `p0 = 0`
> defect, and **all three coefficient scrambles**. **1 / 7, 8 of 8 as expected**, self-test 13/13.
> ★ **The criterion is BIT-EXACT and comes out of the ROM**: `((c·c) >> 23)·h >> 23 = 180 297`
> with `c = 0xE5762C = −0.207331`, `h = 0x400000 = +0.500000`; `180 297 · 2²¹ >> 23 = ` **45 074**.
> ⛔ **`+0.02149296` is SINGLE DELAY's gain, NOT PARAMETRIC EQ's** (PEQ's control is the separate
> **0.198 dB** biquad). ★★ **The three scrambles are the point** — they carry the ROM's own
> coefficients reshuffled, so they **do** put an echo at 1001. **A presence test passes all three;
> only the VALUE separates them.**
> ⚠ Three harness defects, none a property of any machine: an **uninitialised pointer** (the head
> write sat on `mem[0xFB]`, so the line was fed zero every frame), a **double negation**
> (`reversed + cursor −1` restores correct addressing — the old control was mislabelling a
> *differently-correct* machine), and a **hard-coded `D = 500`** where the taps are in **CASCADE**
> (`500 + 501 = 1001`).
>
> **2. ⛔ `§54` / `§70` / `§211` / rule-19 / `§61` / the epilogue `D-I` tally ARE ONE CRITERION
> COUNTED SIX TIMES.** Measured as a **set identity** over the 33 modern arms
> (`dsp/tools/outstage_collapse.py`, 19/19 self-tests): all six have the **identical move-set**
> `{C_xb85_full_222, D_xb85_route_222}`. The source forces five of them — in `present()`, `§70`
> and `§211` read the **same local `pacc`**, rule-19 sums it, `§61` reads `v` derived from it, and
> `§54`'s `m_frame_out_nz` comes from that same `v`. **One number, five prints.**
> ⇒ *"§54 clean | §70/§211 mean 0.0 span 0 — PASS"* is **ONE ROW**. Keep them as the output-stage
> watch they are; **stop counting them as a battery.**
>
> **3. ★★★★ THE INDEPENDENT SECOND CHECK IS `m_rf[0x8D]` — AND §229 CLEARED IT.** Its move-set
> `{C_xb85, D_xb85, O_227, Q_227}` **strictly contains** the null's; it lives in the output stage
> (the `w61` self-loop, `§104` rows 60/61); and **it has actually failed** — `0x009B26 → 0x7FFFFF`
> (§222), **halved** to `0x004D93` (arm Q), **absent** (arm O). §229's fabricated-zero census
> independently reports **its non-zero stores come from a third site**, so it survives that audit.
> ⚠⚠ **BUT ON THE PRESENTED VALUE THERE IS EXACTLY ONE MEASUREMENT POINT.** Every *"the output
> stage is still a null"* this project has published rests on **a single measurement** — and at
> `w78` that measurement's only operand is a zero **we fabricate** (§229). ⇒ **`§70` and `§211`
> are not even the same KIND of null**: `w73` is a statement about the chip, `w78` is partly a
> statement about us.
>
> **4. `W4′` IS A SEND-STATE DETECTOR, `20 of 20`** — body-0 `D-I` is `(0,0,0)` on every modern arm
> whose delay port returned no non-zero datum, across four mask defaults, `EPIBUS`, `PICKUP`,
> `PSHIFT`, `NOCARRY` and **both LFOWRAP polarities**. ✔ **The `UPD6383_LFOWRAP` gate survives** on
> `W0`/`W1`/`W2`, which are two-sided and did move; what falls is the published **11 of 11**, which
> is really **6 of 11 plus `m_rf[0x8D]`**. ⚠ `§46`'s non-zero count is a **delay-line-content**
> detector, not a clean send-state one (`O_227` moves it 1 175 999 times and still scores `0/0/0`).
>
> **5. §220's *"slot for slot IDENTICAL to the §215 calibration arm"* — the RAW markers are equal
> element for element; the RULE-21 content is `26/28/27` vs `17/16/15`, body 1 `2/1/2` vs `0/0/1`.**
> ★ The whole difference is **UNDECIDABLE slots** — `11/12/12` vs `2/0/0`. **The two arms mark the
> same slots; the rig decides them and the calibration arm does not.** ✔ The send model survives on
> §225's independent re-grade; **the corroboration does not.**
>
> ⛔ **`dsp/verify.py` IS NOT A DEVICE CONTROL.** It reads `original_ROMs/*.rom` and `dsp/disasm/*.dsm`
> and **cannot see `upd6383.cpp` at all**. Keep it as a repo invariant; never count it as a
> falsifier row for a C++ change — the equivalent there is the **diff-line** control.
>
> ⚠ **Five control repairs are SPECIFIED AND QUEUED, not shipped** (`BUILD-LANE-QUEUE.md` 15–19):
> `§S1 CONTROL`'s refuted *"clips = 0"*, `§S3`'s *"EXTERNAL"* control (the source's own comment
> admits the predicate is identical at the same hook), `§44`'s 0-in-40-of-40, mask bit 5's level
> guard and `§S3-C4` — both never exercised in the direction that would make them fire.

> ### ★★★★ §228 SHIPPED FIRST, AND IT IS NOT THE BLOCKER — IT IS A CLOCK
>
> **THE DSP FRAME CLOCK RAN AT 48 000 Hz AGAINST AN Fs OF 44 100.** Measured from disk before
> anything was built: every archived arm reports **1 440 001 frames on a `-seconds_to_run 30`
> vehicle** = exactly `30 × 48 000`, and its settled window `1 440 000 − 420 000 = 1 020 000` is
> precisely `§S1`'s `706 040` quiet + `313 960` loud. **Every emulated delay, reverb time and LFO
> was +8.844 % fast.** It now ships at **44 100**, by decoupling `run_frame()` from the 48 kHz
> rendering stream with an exact **147/160** phase accumulator.
> `UPD6383_FRAMEHZ=48000` restores the old clock as the two-sided control.
>
> ```
>                       arm A (48000, control)   arm B (44100, DEFAULT)
>    frames run          1440001                  1323000 = 30 x 44100 exactly
>    §228 T4 meas. Hz    47985.602                44086.742   (T5 err 3.0e-4, PASS both)
>    LFO step / period   114..114 / 73584.3 fr    114..114 / 73584.3 fr   <- INVARIANT
>    LFO rate            0.652313 Hz              0.599313 Hz
>    §S1 TOTALS          4.924 % / 4.920 %        4.924 % / 4.920 %       <- INVARIANT
> ```
>
> ⚠⚠ **NEVER GRADE A CLOCK CHANGE ON THE LFO's Hz — IT CANNOT FAIL** (the census's Hz is
> `wraps/frames × DECLARED rate` and `wraps/frames` is rate-invariant; rule 8). Grade on **T4**,
> frames per emulated second against the machine's clock, and on the step/period staying invariant.
> ⛔ **`§196`'s WRAP CENSUS IS SUPERSEDED** — it printed **0.5000 Hz** on every arm ever run
> (denominator included the 264 001 pre-upload frames; numerator truncated the last partial wrap).
> ★★ **And `LEDGER`'s own `0.652 Hz` had never been measured by anything** — it was derived from
> the increment. **Before quoting a figure as MEASURED, find the log line it came from** (rule 20).
> ★ **NO TONE-GENERATOR REGRESSION**: insert-OFF / ON-at-44100 / ON-at-48000 are **byte-identical**
> over 1 440 001 frames (md5 `baffbeee…`), with the positive control passing (peak 21 796,
> 14.5 % non-zero).
> ⇒ ⚠ **EVERY FRAME COUNT IN A PRE-§228 LOG IS ON THE 48 000 CLOCK. COMPARE RATIOS, NEVER COUNTS.**
> Arming gates are FRAME counts and did not move; their wall-clock times did (420 000 = 8.75 →
> **9.52 s**). `§200`'s DELAY AGE ms figures in older logs are **8.84 % high**.
>
> ---
>
> **★★★★ THE BLOCKER, UNCHANGED BY §228, IS: *WHAT DOES THE COEFFICIENT BASE `0x90` MEAN?* BOTH
> CANDIDATE BASES ARE NOW MEASURED TO BE SOMEBODY's PER-ALGORITHM PARAMETER BANK.**
>
> **§227 took the reverb-preset capture §226 asked for, and it REFUTED §226's own positive half.**
> `C-RAM[0x90..0xB4]` is **NOT** a boot-fixed bank — it is **UNIT 1's (the reverb's) parameter
> bank**. A preset change `CONCERT REVERB 1 → ROOM REVERB 1` rewrites **23 cells, every one inside
> `0x90..0xB4` and NOTHING else in the 256-cell C-RAM**; **13 of the header's 20 walk cells move**
> and **2 of the 3 ladder cells (`0x9B`, `0x9C`) move with them**.
> ★ **The control that makes it proof-grade:** an independent 45 s panel run landing on CONCERT
> REVERB 1 reproduces the archived cold-boot capture on **all 256 cells, 0 differ** ⇒ the
> **cold-boot default reverb is CONCERT REVERB 1**, not ROOM REVERB 1.
> ★ Reproduce in one line:
> `python3 dsp/tools/hdrbase.py --score notes/data/kn5000_dsp1_upload_concertreverb1.txt notes/data/kn5000_dsp1_upload_roomreverb1.txt`
>
> **THE THREE READINGS, and a falsifier that DISTINGUISHES them is required first:**
> (a) **row 25 is wrong** — `ldptr` does not seed the coefficient cursor (**K3 has said so all
> along**); (b) the base is right and the header **legitimately reads the reverb's gains** (it runs
> immediately before the reverb's CALL); (c) the **cursor-advance map** is wrong.
> ★★★ **CHEAP AND NEXT: sweep the other twelve reverb presets** —
> `REVIDX=n dsp/tools/reverb_select.lua` + `hdrbase.py --score`, one command each. If the same 23
> cells move every time, that set **is** the reverb's parameter block, measured not inferred.
>
> ### ⛔ THE ALU DECODE OF `iw30/iw32/iw33` IS **CLOSED**. BOTH HALVES REFUTED (§227, four arms).
> * **`f31 == 1` IS the ISA's only accumulate** — `HI_ACC_ADD`, **1309 of 2989** non-C-format
>   corpus words, **695 of 1178** ALU-decoded; op 0 LOADs, op 2 HOLDs *without a product*, op 3
>   gets HOLD's behaviour. The **PARAMETRIC EQ biquad** (grade **SOLVED**, validated against its
>   designer at **0.198 dB**) sums five products through `f31 == 1` words `w6..w10`, rendered
>   **`acc += P`** by this repo's own generator. Without the carry `H(z) = makeup·(−a2)·z⁻²`.
> * **AND THE ARM DOES NOT FIX THE CLIP:** `iw34` becomes `8 388 608` = `2²³` = **FS + 1** and
>   clips `706040/706040` quiet and `313960/313960` loud — **identical to shipped.** Its 13 %→0.4 %
>   `§S1` "win" is **117 655 680 accumulate steps refusing to add**, and it takes `§104` body-0 to
>   100 % input-INDEPENDENT and makes `m_rf[0x8D]` disappear.
> * **`P_SHIFT = 7` IS NOT Q-CONSISTENT AND THE TIED MOVE IS A MEASURED NO-OP.** Coefficients are
>   **Q1.22 (MEASURED)** ⇒ the Q-consistent total is **22**, which ships. Arm P (7/15): the entire
>   `§S1` block is **BIT-IDENTICAL** to the default over 269 279 999 conversions. Arm Q (7/16,
>   untied): **`m_rf[0x8D]` halves, `0x009B26 → 0x004D93`** — and it still clips at `1.110 × FS`.
> * ⚠⚠ **CORRECT THE FALSIFIER LIST EVERYWHERE IT IS QUOTED: `§41` DOES NOT GUARD `P_SHIFT`**
>   (it reads C-RAM *levels* and is unmoved by a 2× product rescale). **`m_rf[0x8D] = 39 718` does.**
>
> ### ⛔ STILL BINDING FROM §226 — do NOT re-derive
> * **DO NOT SEED THE CURSOR AT FRAME START** — row 25 is LIVE (mask bit 12 CLEAR), the epilogue's
>   `iw69 ldptr #$90` is the frame's last pointer load and the epilogue has **ZERO** cursor-advancing
>   words ⇒ `w0` starts at exactly `0x90`. Setting it to what it already is **cannot fail**.
> * **DO NOT AIM THE HEADER AT `0x00`** — that is **unit 0's** per-effect bank (PEQ rewrites all 20
>   cells; §227's reverb capture moves **0 of 80** cells in `[00..4F]`), and the `0x0B` ladder is
>   `+2.733 FS` with PEQ loaded, **1.6× worse than shipped**.
> * **`headerdecode.md` §7.6 STAYS ANSWERED** (the `cmd 0x02` runs at `0x90` + `0xAE`; the packet
>   carries no destination — an `ldptr` in a scratch I-RAM slot does). ⚠ Only their *meaning*
>   changed: they upload the **cold-boot reverb's** coefficients.
> * ⚠ **`kernel.dsm`'s *"base 0x00 MEASURED"* IS A GENERATOR DEFAULT.** Never anchor on it.
> * **THE SQUARING MULTIPLY IS FAITHFUL**; ⛔ **do not touch the `SRC 0x08` source read** (anchored
>   by the CHORUS LFO, `acc = 114 << 16` exactly).

## TIER 0a-prev-226 — §226's BLOCKER, CLOSED by §227 (both halves refuted; see TIER 0a)

> **§226's headline was:** *"the header's fixed coefficient bank is FOUND — `C-RAM[0x90..0xB4]`,
> uploaded by the boot-time `cmd 0x02` runs at base `0x90` (30 values) + `0xAE` (7); `headerdecode.md`
> §7.6 is ANSWERED; the shipped build was already reading it; 22 of the 37 cells are written by no
> algorithm; the blocker moves to the ALU decode of `iw30/iw32/iw33`."*
>
> ⛔ **RETRACTED by §227:** *boot-fixed*, *15 of 20 invariant*, *ladder cells `9B/9C/9D` ALL
> invariant*, and the *"CHORUS + ROOM REVERB 1"* label on the cold-boot image (it is **CONCERT
> REVERB 1**). Of the "22 written by no algorithm", **15 move under a preset change**
> (`93 94 95 97 9A 9B 9C A1 A2 A3 A4 AD AE B3 B4`) ⇒ that list measured a **gap in the ROM's T1
> map**, not a property of the chip.
> ✔ **SURVIVES:** the upload half and `headerdecode.md` §7.6's answer; base `0x00` is unit 0's
> per-effect bank and is still refuted; the frame-start seed is still refuted; `kernel.dsm`'s
> *"base 0x00 MEASURED"* is still a generator default.
> ⇒ **the ALU decode it handed on is now CLOSED (§227) and the blocker is TIER 0a.**

## TIER 0a-prev-225 — §225's BLOCKER, SUPERSEDED by §226 (the squaring is FAITHFUL; the base is RIGHT)

> **★★★★ `§S2sq` — THE COEFFICIENT SQUARING — WAS THE BLOCKER, AND §225 GAVE IT A MEASURED
> CONSEQUENCE.** ⛔ **`SQUARING-MULTIPLY_findings.md` then established the squaring is FAITHFUL
> and re-attributed the overflow to the cursor base; §226 refuted THAT too. Do NOT re-open
> `cursor + 1`.**
> `SRC 0x08` resolves to `C-RAM[m_cursor]`; on a class-A word the multiply reads
> `C-RAM[m_cursor]` **again**, before the post-increment, so the product is the coefficient
> **SQUARED**. It fires **5 100 000** times a run at `iw30 iw32 iw33 iw41 iw89`.
> ★★★ **The FIRST non-zero datum ever placed in D-RAM cell `0x06`** — caught by `§S3` at store
> **#1360**, frame 264 002 — is **`iw33`'s `6 039 795` = `C-RAM[0x9B]² >> 6` = `0.720 × FS`**,
> a coefficient squared and **not a sample**; and `§224` §1 showed `iw33`'s two product terms
> **alone exceed full scale** (`1.720 × FS`; zeroing the `ACT 0x00` bus term still leaves
> `1.220 × FS`). ⇒ **the cell-`0x06` rail and `§S2sq` are the same defect.**
>
> **THE QUESTION:** should the **multiply** read `C-RAM[cursor + 1]` while `SRC 0x08` reads
> `C-RAM[cursor]`?
> ⛔ **DO NOT TOUCH THE SOURCE READ** — ANCHORED by the LFO rate (`C-RAM[0x00] = 114` ⇒
> `+114`/frame, `§109`; `§196` measures the wrap period at 96 000 frames = **0.5000 Hz**).
> **Two-sided, DEFAULT OFF, unconditional fired count.** Falsifiers: `§41`, SINGLE DELAY's
> validated `+0.02149296` three-factor product, **and now `§S3`'s ladder** — a correct reading
> must move store #1357's `1 650 061` and #1360's `6 039 795`, and `§S1`'s 4.924 % with them.
>
> ⇒ ★★★★ **AND §224's "CELL-`0x06` LATCH-UP" IS ANSWERED AND ITS FRAMING RETIRED.** `§S3` — a
> boot-window recorder with **NO FRAME GATE**, ladder unbounded in time — reports `SETTLING`:
> ```
>    §S3 EPOCH-0 (the PRE-EXECUTION state, 0 prior writes): frame 204731 iw73 pre 0 val 0
>    stores #1..#1356 write EXACTLY ZERO   (the ladder's lowest rung is "val >= 1"
>                                           and it first fires at #1357 -- MEASURED)
>    #1357  frame 264002  iw19  pre 0        val 1 650 061  (0.1967 FS)  <- THE ENTRY
>    #1360  frame 264002  iw33  pre 0        val 6 039 795  (0.720  FS)
>    #1362  frame 264003  iw19  pre 8217878  val 8 388 607   RAILED
> ```
> ⇒ ⛔ **`0` IS NOT A FIXED POINT. There is NO second state; "BISTABLE" is RETIRED.** `iw19`'s
> **first ever** store, from an **EMPTY** cell, is already **1.52 ×** the `0.129 703 × FS`
> threshold and the rail follows **on the next frame**. The rail needs a **FORWARD GAIN**
> explained, not an entry.
> ★ **HOW `§S3` BEAT RULE 16, and this is the transferable part:** it does **not** sample a time
> window. It records **STORES** and splits them by a property of the **DATUM** — the first
> store's `pre` is *by construction* the state before any instruction wrote the cell, every later
> `pre` is *by construction* an instruction's result — and prints the verdict as the **RELATION**
> between them (`RESET-STATE` / `SETTLING` / `NO CROSSING`, unconditional).
> ★ **External control passed to the unit:** mask bit 26 counts the identical predicate at the
> identical hook and `§220` measured **5 881 351**; `§S3` reports **5 881 351**.
> ★ **`S3-C4` passed:** **0** host tag-`0x15` writes reach D-RAM `0x06` (mask bit 23 SET ⇒
> `m_rf[0x06]`) — the entry is **not** the host's `+0.5` level poke.
> ⚠ **`§106`'s cell-`0x06` writer list is WRONG** — 5 names of **12**, and `5 881 351` was never
> divisible by `5`. **Quote `nz`, never just the count:**
> ```
>    RAILS IT   (nz on ~every frame INCLUDING all 706 040 SILENT ones)
>       iw19:1176011(nz 1175999)  iw33:1176007(nz 1175999)  iw39:1176003(nz 1175999)
>    INPUT-DEPENDENT (nz 313 127 ~ the 313 960 loud frames) -- NOT what rails it
>       iw21:1176011(nz 313127)   iw27:1176011(nz 313127)
>    ZEROS ONLY (1308 stores -- the traffic holding the cell at 0 for 1356 stores)
>       iw73:98  iw78:196  iw9:23  iw11:19  iw35:8  iw45:4  iw321:960     all nz 0
> ```
>
> ⇒ ★★★★ **AND RULE 21's BLAST RADIUS IS NOW BOUNDED — `28/32/28` SURVIVES.** The discriminator
> is **forced by the instrument's own bucket predicate**
> (`nz = (m_in_val[0] != 0) || (m_in_val[1] != 0)`): the quiet bucket is frames where the input
> is **EXACTLY ZERO**, the same value on all 706 040 of them, so a **DEGENERATE quiet range
> (`min == max`) PROVES input dependence** — nothing free-running can be a point over 706 040
> frames — and a non-degenerate one proves free-running state.
> ```
>    body 0  NOZ05 (send OPEN)   28/32/28 = I 26/28/27 + FREE 0/4/1 + UND 2/0/0
>    body 0  shipped (send SHUT)  2/4/1   = I  0/0/0   + FREE 2/4/1      <- 100 % ARTEFACT
>    body 1  2/1/2 = I 2/1/2  |  XB85 59/44/49 = I 59/44/49  |  epilogue 22/19/9 = I 22/19/9
>    kernel A NOZ05 33/40/29 = I 33/35/27 + FREE 0/5/2
> ```
> ⇒ **`26/28/27` is proof-grade; the free part is EXACTLY the four cell-`0x07` rows.**
> ⇒ ⚠⚠ **`2/4/1` — the shipped-build "null" — IS 100 % FREE-RUNNING. Body 0 on the shipped build
> is `0/0/0`**, so `28/32/28`'s true delta is `26/28/27` over `0/0/0` and the *"the rig delivers
> signal to the bodies"* claim comes out **STRONGER**, not weaker.
> ★ **The two controls that make this more than a criterion somebody invented:** opening the send
> is the *only* difference between arms A and C and a ramp is present in **both**, so the slots
> newly `*` in C cannot be free-running — **the differential and the classifier agree
> `26 = 26 / 28 = 28 / 27 = 27`, and the `mem`/`L` sets coincide element for element.**
> ⛔ **NEVER QUOTE A `§104`/`§86` COUNT AGAIN WITHOUT ITS `D-I` SPLIT.**
> `dsp/tools/rule21_all.py <log>` does it in one line.
> ⚠ Region boundaries, from the device's own labels (`upd6383.cpp:630`): kernel A `0..49`,
> kernel B `50..59`, **epilogue `60..82`**, body 0 `84..199`, body 1 `200..332`. The epilogue is
> INSIDE the low range; a naïve `333..` slice reports `0/0/0` for `22/19/9` forever.
>
> ★ **SHIPPED by §225:** `UPD6383_LFOWRAP` **DEFAULT ON** — `iw91` applies `C-RAM[0x01] =
> 0x7FFFFF` (the constant the source's own annotation calls *"wrap"*) as a **MODULUS**, at the
> adder only, so cell `0x10` carries the chorus LFO instead of a full-scale DC. The gate `W4`
> was **restated** to grade degenerate-quiet markers only (which **cannot** fire on a ramp, and
> which **can** still fail — the XB85 arms score body-0 `D-I` = `26/23/23`) and it is
> `0/0/0` → `0/0/0`; `K1` diffs arm K (no env) against §224's arm J in **7 lines, not one a
> measured value**; `K2` shows `=0` still reproduces arm I exactly. Also shipped: **`§S3`**, and
> `dsp/tools/{parse104,rule21,rule21_detail,rule21_all}.py`.
> Logs: `data/{K_lfowrap_default,L_lfowrap_off,M_s3_census}_225.log.gz`.
> `dsp/verify.py`: **BYTE-MATCH OK.**
>
> ★★★ **METHOD, §225's three:** (1) **RULE 21 is now OPERATIONAL, not a warning** — and its
> `1 %` `X-ramp` threshold is **not load-bearing** (worst FREE extra-reach across 33 logs is
> **0.000048 % of span**, a 20 971 × margin). (2) **A gate must be able to fail, and saying so
> means NAMING AN ARM WHERE IT DOES.** (3) **A boot-window instrument need not trade off RULE 16**
> if it splits epochs by a property of the datum rather than by a time threshold.
> ⚠ **The overflow counter earned its keep on its first run**: `§S3`'s 8-slot writer census
> overflowed **2 352 974** times and *said so* — without it the truncated 8-name list would have
> looked complete and would have "confirmed" `§106`.

## TIER 0a-prev-224 — §224's BLOCKER, SUPERSEDED by §225 (the latch-up framing is RETIRED)

> **★★★ KERNEL A's D-RAM CELL `0x06` IS A LATCH-UP, NOT A GAIN ERROR — AND `§S2` NAMES IT TERM BY
> TERM.**
> §224 built `§S2`, an accumulator TERM census at the adder: per `iw`, per `§54` bucket, the three
> physical addends register row 26 names (`CARRIED`, the `ACT 0x00` `BUS` term, `P`) with their
> full-scale ratios and the `SRC` codes that fed the bus.
>
> ```
>    iw13  carried 239 225 266 218 + bus 549 755 748 352 + P 239 225 266 218 = 1.870 x FS
>    iw14  carried             0   + bus 549 755 748 352 + P 239 225 266 218 = 1.435 x FS
>    busSRC 00 = mem[ptr] = CELL 0x06, at UNITY.  §96: iw19 STORES the clamp back into 0x06.
>    549 755 748 352 = 0x7FFFFF << 16.   §176 shipped:  06:8388607(0..8388607/chg1100)
> ```
>
> **`iw13`'s other two terms sum to `0.870 × FS` — BELOW the rail — so the loop has a STABLE
> SECOND STATE and the shipped build sits in it with zero input.** ⇒ **Find what first drives cell
> `0x06` past ≈ `0.13 × FS`.** ⚠⚠ **`§S1`, `§S2` and `§104` ALL arm at frame 420 000 and CANNOT
> SEE IT** — a boot-window instrument is required and its arming must be stated in the prediction.
>
> ⇒ ★★★ **§223's BLOCKER IS ANSWERED AND ITS CANDIDATE IS REFUTED.** `iw34` is `000.A.FF.407`:
> `lo12 0x407` ⇒ **`SRC 0x10` = the ACCUMULATOR** — the censused conversion is the accumulator
> being placed on the **bus**, not a store's datum, and its value is `§104` row **33**'s
> `acc >> 16`. The ladder is three terms, **not one of them a sample**:
> `C-RAM[9B]² >> 6` (0.720) + `C-RAM[9D] << 16` (0.500) + `C-RAM[9C]² >> 6` (0.500) = **1.720 × FS
> at `iw33`, the true overflow site.** ⇒ ⛔ **zero the `ACT 0x00` bus term and `iw33` still leaves
> `10 234 099 = 1.220 × FS`. STILL CLIPS.** Refuted from disk, no build.
>
> ⇒ ★★★ **WHERE THE BUS TERM *IS* THE CAUSE, THE ADDEND IS THE WRAP CONSTANT.**
> `iw92 − iw91 = 8 388 607` **exactly, both endpoints, both buckets**, and
> `8 388 607 = 0x7FFFFF = C-RAM[0x01]` — which `upd6383.cpp`'s **own** annotation calls *"wrap"*.
> `iw91` is `§118`'s wrap word (`ST mem[Q] <- (phase + INC) mod 2**23`); the model **ADDS the
> modulus**, so `iw92` publishes `clamp(phase + INC + 0x7FFFFF)` and cell `0x10` — `§120`'s
> modulation cell — is a full-scale DC while the phase ramps correctly at `+114`/frame in `0x07`.
>
> **`UPD6383_LFOWRAP=1` (arm J) passes EVERY falsifier but one, and the one that decides it is
> POSITIVE:**
> ```
>    W0 fired 1 176 960, ONE slot (iw91)                                          PASS
>    W1 §S1 quiet 9 884 596 -> 9 178 556 = -706 040 EXACTLY  (5.303 % -> 4.924 %)
>       §S1 loud  4 391 682 -> 4 077 722 = -313 960 EXACTLY  (5.298 % -> 4.920 %) PASS
>    W2 §119 iw94 mem[dp10]  8388607 x8 -> 1006898 1007012 ... 1007696            PASS
>       -- a +114/frame RAMP.  THE CHORUS LFO REACHES ITS PUBLISHED CELL.
>    W3 §41 0x400000/0x178D0B | m_rf[8D]=009B26 | §54 quiet-in 826 040 -> 826 040
>       SILENT / 0 LOUD (peak 0) | §70 mean 0.0 span 0, §211 mean 0.0 span 0,
>       BOTH buckets BOTH arms | §S1 iw39 loud min 1 991 044                      PASS
>    W4 §104 body 0  2/4/1 -> 2/9/4                                               FAIL
>    R1 arm I vs F_satcen_223.log.gz: NOT ONE measured value moved                PASS
> ```
> ⚠ **IT DOES NOT SHIP AS A DEFAULT** because `W4` was a gate this pass set for itself and it
> failed. ⚠ **`W4`'s failure is an INSTRUMENT ARTEFACT (RULE 21 below);** the `acc` column is
> unchanged at 2 and what moved is `mem`/`L` on the six slots that read cell `0x10`.
> ⇒ **§225: restate `W4` so it cannot fire on a ramp, then FLIP `UPD6383_LFOWRAP`.**
>
> ★ **SHIPPED by §224:** `§S2` (read-only, always on, 48-row cap **with** overflow counter, four
> pre-registered cross-instrument controls printed beside the table, and a 44-bit-overflow count);
> `§S2sq`, the coefficient-squaring counter (**5 100 000**, slots `iw30 iw32 iw33 iw41 iw89`);
> the `§S1 PROVENANCE` line; `UPD6383_LFOWRAP`, **default OFF**, gated by **predicate** not line.
> Logs: `data/{I_s2,J_lfowrap}_224.log.gz`. `dsp/verify.py`: **BYTE-MATCH OK.**
>
> ★★★ **RULE 21 (NEW): `§104`'s and `§86`'s quiet-vs-loud markers CANNOT DISTINGUISH
> "input-dependent" from "FREE-RUNNING AND SAMPLED OVER TWO FRAME SETS".** Proof from a case that
> predates the change and sits in **every** log this project has taken:
> `★ cell 07  quiet [4 .. 8388594]  loud [8 .. 8388598]` — that is the **LFO PHASE**, with no
> input in it at all, flagged `INPUT-DEPENDENT` in both arms. Both buckets cover the whole ramp;
> the endpoints differ by **less than one increment (114)** because the buckets are different
> *sets of frames*. **Never grade a cell carrying an LFO, a counter or a free-running ramp on
> them.**
> ★★ **`§S1`'s VALUE IS THE PRE-UPDATE ACCUMULATOR** = the PREVIOUS slot's `§104` `acc >> 16`,
> verified **8 of 8**, both endpoints, from disk. `iw34 = row 33`, `iw92 = row 91`, `iw39 = row 38`.
> ★★ **A CENSUS WHOSE INTERNAL CONSISTENCY IS TRUE BY CONSTRUCTION IS NOT A SELF-TEST** — `§S2`'s
> source says so, and its real controls are **external and pre-registered**.
> ⚠ **The kernel's C-RAM block is Q23** (`0x4CCCCC = 0.600000` … `0x600000 = 0.750000`, eight round
> decimals ≤ 0.75), so `P = (coef × L) >> 6` with `ACC_SHIFT = 16` is **2 ×** a Q23 product. That
> is an **OBSERVATION, NOT A PROPOSAL** — `ACC_SHIFT = 22 − P_SHIFT` ties them, `§41` and
> `m_rf[0x8D]` calibrate `ACC_SHIFT`, and halving the products alone leaves `iw33` at `1.110 × FS`.

## TIER 0a-prev-223 — §223's BLOCKER, SUPERSEDED by §224 (and its CANDIDATE refuted)

> **★★★ THE BLOCKER IS A WORD, NOT A RIG: `iw34` CONVERTS A CONSTANT `14 428 403` = 1.720 × FULL
> SCALE AND CLIPS ON 1 020 000 OF 1 020 000 CONVERSIONS — QUIET AND LOUD, SHIPPED BUILD AND BOTH
> RIGS.**
> §223 built `§S1`, a saturation census on `acc_to_datum()`'s **pre-clamp** value, per `iw`, per
> `§54` bucket, settled frames only. Run on the **shipped default** with the input **exactly zero**:
>
> ```
>    arm F  SHIPPED   quiet  9 884 596 clip / 186 394 560 conversions = 5.303 %   <- ZERO INPUT
>                     loud   4 391 682 clip /  82 885 440             = 5.298 %   <- LOWER
>    arm G  NOZ05=1   quiet 14 826 840 / 177 922 080 = 8.333 %
>    arm H  NOZ05=2   quiet 17 651 000 / 180 746 240 = 9.766 %
>       H - G = +2 824 160 clip / +2 824 160 conv (quiet), +1 255 624 / +1 255 840 (loud)
>             = EXACTLY iw9's row, and 100 % of iw9's quiet conversions CLIP
>    SEVEN sites clip on 100 % of quiet frames in arm F.  iw34: 14 428 403 in BOTH buckets, ALL
>    THREE ARMS.  iw92 (body 0): pre-clamp MINIMUM 8 388 725 -- above the rail before the range opens.
>    §54 all three arms: quiet-in 826 040 -> 826 040 SILENT / 0 LOUD (peak 0); loud-in 313 960
>                        -> 313 960 silent / 0 loud (peak 0).  §70/§211 mean 0.0 span 0, both buckets.
>    §104  arm F 27/26/20 | 2/4/1 | 0/0/0 | 0/0/0   arms G AND H  33/40/29 | 28/32/28 | 2/1/2 | 0/0/0
> ```
>
> ⇒ ★★★ **THE PEDESTAL IS IN THE SHIPPED MODEL.** `UPD6383_NOZ05` does not create it; it removes
> the two stores that were **hiding** it from body 0. §222's *"the pedestal is the rig's own rail"*
> is corrected to that.
> ⇒ ⛔ **§222's PRE-REGISTERED NEXT EXPERIMENT IS REFUTED FROM DISK, WITH NO RUN.** `iw35`'s
> POST-update accumulator `908 714 800 127 >> 16 = 13 865 887` = **1.653 × FS, CLIPS**; `iw45`'s
> `538 760 587 509 >> 16 = 8 220 834` = **98.0 % of FS, constant in both buckets**. A post-update
> store deposits **the rail** it was proposed to remove.
> ⇒ ⛔ **NO STORE-SUPPRESSION RIG AVOIDS THE RAIL.** `NOZ05 = 2` (the narrow rig: `iw35`/`iw45`
> only, 2 stores instead of mode 1's **8**) reproduces `28/32/28` / `33/40/29` / `2/1/2` **column
> for column** and **still rails** `D-RAM[05]` at `8 388 607`, with `iw9` restored and railing too.
>
> ⇒ **NEXT: (1)** name the words that build the accumulator between `iw30` and `iw34` and grade
> each one's contribution against full scale — **no rig needed**, `iw34` is input-, rig- and
> arm-independent. Grade on `§S1`'s per-`iw` clip count, **never** on `§70`/`§211`.
> **(2)** `ACT 0x00`'s **BUS TERM** is the leading structural candidate: row 26 makes ACTION `0x00`
> **ADD** `L << 16`, the kernel's bus carries coefficient-magnitude constants (`4 194 304` is
> exactly **½ FS**), so three such words pass full scale with no attenuation — **a unity-gain comb
> fed a DC ramps to the rail**. Two-sided, env-gated, DEFAULT OFF, fired count; the falsifier is
> `§S1`'s quiet clip rate FALLING while `§41` and `m_rf[0x8D]` do not move.
> **(3)** body-0's coefficient cursor at `iw112` — `RISK-TRIAGE_findings.md` §5 resolved the
> `coef 0..24` vs `0x1364D9` conflict with zero runs and the **×24 attenuation STANDS**.
> ⛔ **NOT `ACC_SHIFT`** on a moved number — `§41` (`0x400000` / `0x178D0B`) and
> `m_rf[0x8D] = 0x009B26` calibrate it and both passed in all three arms.
> ⛔ **NOT `ACT 0x0D` / `m_bx_sel0d` / `iw205`**; ⛔ **NOT `SRC 0x03`/`ACT 0x03` as a latch**;
> ⛔ **NOT the epilogue's operand set** — all closed by §222 and unchanged.
>
> ★ **SHIPPED by §223:** `§S1` (read-only, always on, 48-row cap **with** an overflow counter);
> `UPD6383_NOZ05` as a **mode** (0/1/2, default OFF, mode 1 verified bit-identical to §222 arm B);
> the **nop guard narrowed** by `addr8 == 0x00` — `§NG` = 2 371 200 words, and arm F's whole report
> `diff`s against §222's archived arm A in **29 lines of which NOT ONE is a measured value**;
> and a **latent runaway `logerror`** (`§90`, bounded by a counter another site owned) fixed.
> Logs: `data/{F_satcen,G_noz05m1,H_noz05m2}_223.log.gz`.
> ★★ **METHOD, and it cost a control:** **state which side of the slot a predicted number came
> from, in the prediction.** `PREDICT_223`'s `S2` took `iw34`'s value from `§104` row 34's `acc`,
> which is *"acc AFTER the slot"*, where the store's datum is the **PRE**-update accumulator —
> row 33's. Off-by-one, **fifth occurrence**. ★ **A pure observer's known-answer control must come
> from a different instrument:** `§S1` printed `iw39`'s loud minimum as `1 991 044`, the number §220
> established by `kwatch` two sections earlier, digit for digit, without being told.

## TIER 0a-prev-222 — §222's BLOCKER, SUPERSEDED by §223 (and its ATTRIBUTION corrected)

> **★★★ THE BLOCKER IS NOW THE RIG ITSELF: `UPD6383_NOZ05` RAILS `D-RAM[0x05]` AT `8 388 607` ON
> EVERY QUIET FRAME, AND IT IS THE ONLY ARM THAT MAKES UNIT 0 LIVE.**
> §222 forced unit 1's empty input cell open (the epilogue-crossbar arm, `UPD6383_XB85`), and the
> output stage **left zero for the first time in the project** — `§70`/`§211` went from
> `min 0 max 0` to means of `3.53e11` / `1.21e12`, body 1 from `2/1/2` to `59/44/49`, the epilogue
> from `0/0/0` to `22/19/9`. ⛔ **AND IT IS NOT AUDIO:**
>
> ```
>    §54 arm C   quiet-in 826 040 -> 0 silent / 826 040 LOUD (peak 8 388 607)   <- THE FATAL CASE
>                loud-in  313 960 -> 0 silent / 313 960 loud (peak 2 692 742)   <- LOWER than quiet
>    §70  quiet mean 352 943 168 421.0 span 0 | loud mean 352 935 830 162.3 span 329 906 836 205
>    §211 quiet mean 1 212 718 186 496.0 span 0 | loud mean 1 212 708 031 370.7 span 1 207 096 377 344
>    (gate raised 400 000 -> 420 000 per INSTRUMENT-AUDIT R6 and ALL FIVE ARMS RE-RUN; verdict unmoved)
>    m_rf[8D] 009B26 -> 7FFFFF ; body 0 28/32/28 -> 28/27/24 ; w65's operand a RAILED CONSTANT
>    arm D (route only)  == arm C in EVERY s104 column and in §70, both buckets
>    arm E (latch only)  fired 1 204 800 + 1 203 840 times; its §E-D0 block diffs EMPTY vs control
> ```
>
> ⇒ **The pedestal is the rig's own rail — `D-RAM[0x05]` reads `8 388 607` on every quiet frame in
> the CONTROL arm, before any crossbar exists.** ⇒ ⛔ **NOTHING SHIPPED BEHAVIOURALLY.**
> ⇒ **NEXT: (1) STOP THE RIG RAILING** — §220's residual: the bit-4 store writes the PRE-update
> accumulator; at `iw35` the POST-update accumulator is INPUT-DEPENDENT, so a post-update store
> would DEPOSIT audio instead of destroying it, **without deleting a store the corpus contains**.
> Grade it on `§54` first (`quiet-in → LOUD-out` must stay **0**). **(2)** `w63`'s READ is the
> narrow one-word form of the bit-23 question and §222 §4 proves it is the *entire* mechanism —
> re-ask it **only on a non-railing rig**. **(3)** body-0's coefficient cursor at `iw112`
> (`coef 0..24`, −111 dB).
> ⛔ **NOT `ACT 0x0D` / `m_bx_sel0d` / `iw205`** — §222 closed the destination **at the site**:
> `iw205`'s own `ACCB` = its own operand `× 65536`, both endpoints (`547 518 × 65536 =
> 35 882 139 648` EXACT). `m_bx_sel0d` is FROZEN at 1 and is now a regression control.
> ⛔ **NOT `SRC 0x03` / `ACT 0x03` as a crossbar latch** — REFUTED by the two-sided bisection.
> ⛔ **NOT the epilogue's operand set** — `§221 F1` is **still 0 with the link open**; the operand
> the crossbar delivers is provenance `iw11`, **kernel A's dry deposit**, not body 0.
>
> ★ **`D-RAM[0x85]` HAS NO WRITER AT ALL — now MEASURED**, not inferred, by an audit that names
> `iw70` the instant one exists. ★ **The `:2914`/`:3491` mode-1 unit-rebase divergence is DECIDED
> and UNIFIED**: corpus body images unit-relative **7 of 7**, `iw332 → m_rf[0x8F]` measured, and
> **0 disagreements in 5 976 000 resolutions**; it also closes a latent cross-unit corruption in
> `a04 FLANGER` / `a05 PHASER`.
> ⚠ `UPD6383_XB85` and `UPD6383_PICKUP` are **DEFAULT OFF**, fired counts printed unconditionally.
> Logs: `data/{A_pickup,B_pickup_noz05,C_xb85_full,D_xb85_route,E_xb85_latch}_222.log.gz`.
> ★★ **METHOD, and it cost a falsifier:** a regression control must be **UPSTREAM** of the arm.
> `m_rf[0x8D]` is `acc_to_datum(ACCA)` written by `iw60`/`iw61` — downstream — so when it railed it
> could not tell "the gate leaked" from "the arm worked". `§41` was upstream and passed everywhere.

## TIER 0a-prev — §221's BLOCKER, TRUE IN EVERY PART (and §222 could not refute it)

> **★★★ THE OUTPUT STAGE IS NOT STARVED — IT IS NOT CONNECTED, AND THAT IS MEASURED BY PROVENANCE.**
> §221 ran `§E1`, the operand-provenance census, on the `NOZ05` rig: for every operand the output
> stage fetches it names **the array, the index, and the `iw` that last wrote it** (standing
> RULE 17; rule 15 is why liveness could never have decided it).
>
> ```
>    §221 F1 : epilogue operands (iw60..81) tracing to BODY 0 (iw84..153):  0 of 14
>    §221 F1b: ...to BODY 1: 1 -- w65 <- iw332 via m_rf[0x8F], 540 000/540 000, VALUE ZERO
>    §221 F2 : ACCA at w73, PRODUCER = kernel-B iw54, 540 000 of 540 000 (100.00 %), BODY 0 = 0
>    §221 F3 : CALIBRATION PASS -- w72 -> m_rf[06] = 4 194 304, both buckets
>    diff(arm A §E1 census, arm B §E1 census) = EMPTY, all 18 rows, all 3 provenance columns
>    arm B  s104 body 0: 28/32/28 (arm A 0/0/0) | §46 3 494 021 nz reads | §75 2 351 009
>    BOTH   §70/§211  min 0 max 0, MEAN 0.0, AC SPAN 0, quiet AND loud
> ```
>
> ⇒ **body 0 runs its whole ladder on live audio and NOT ONE BYTE of the epilogue's operand picture
> moves.** §216 said the output stage is a null independent of its input; §221 says why.
> **⇒ NEXT: (1) body-1 `iw205`, `ACT 0x0D`'s destination — `iw`- or unit-SCOPED only,
> `m_bx_sel0d` is FROZEN at 1 globally; (2) body-0's coefficient cursor at `iw112` (`coef 0..24`,
> −111 dB). ⛔ NOT the epilogue and NOT its decode gap — `§E1b` measured all twelve counterfactual
> operands CONSTANT in both buckets, in both arms.**
>
> ⚠ `UPD6383_EPIBUS` is **DEFAULT OFF**, read-only, fired count **120 960 000** printed
> unconditionally. Logs: `data/{A_epibus,B_epibus_noz05}_221.log.gz`.
> ★ New instrument, always on: **`§70`/`§211` now print MEAN and AC SPAN** (standing rule 19), so
> `OUTPUT-STAGE-NULL_findings.md` §6.5(ii)'s `79 438 ± 90` DC counter-example is caught by the log.

## TIER 0a-prev — §220's BLOCKER, still true in every part

> **★★★ THE SEND IS SOLVED AS A DIAGNOSIS AND THE OUTPUT STAGE IS NOW THE WHOLE PROBLEM.**
> §219 located the unit-0 send at **D-RAM cell `0x05`** and named `iw35`/`iw45` as the two stores
> that overwrite the audio `iw9`/`iw11` deposit there. **§220 CONFIRMED IT BY INTERVENTION**:
> suppress those stores (`UPD6383_NOZ05=1`, env, **DEFAULT OFF**) and body 0's `§104` columns go
> from **`0/0/0`** input-dependent slots to **`28/32/28`, slot for slot identical to the §215
> `SRC0B2` calibration arm**; the delay line fills (`§46` non-zero reads **0 → 3 494 021**, `§75`
> writes-with-content 1 175 999 → **2 351 009**) — **and `§70 ACCA at w73` / `§211 ACCB at w78` are
> STILL `min == max == 0`, quiet and loud, in all four arms.**
> ⇒ ★★★ **EVERY UPSTREAM LINK IS DEMONSTRABLY ALIVE AND THE OUTPUT IS STILL A HARD NULL.
> Work the OUTPUT STAGE, with `UPD6383_NOZ05=1` as the rig.**

Decided from `data/{A_off,B_mirror06,C_noz05,D_noz05_drpub}_220.log.gz` — four arms, one build,
the §217 clean vehicle, 1 440 001 frames each. **Cite the run, not the section** (rule 11):

```
   arm A  shipped default -- IDENTICAL, slot for slot, to drpub_A_off_217:  body-0 idep 0/0/0
   arm B  mask bit 26 ON  -- fired 5 881 351, iw84 STILL 0 ‖ 0, kernel A STRICTLY WORSE
                            (acc 27→22, mem 21→10, L 18→12)              ⛔ DEAD-END 30
   arm C  UPD6383_NOZ05=1 -- fired 3 528 080 (iw9/iw35/iw45, +55 pointer-drift strays)
                            §104 iw84 mem 8 388 607 ‖ -8 388 608..8 388 607  *   THE PICKUP, LIVE
                            s104 acc 63 (body0 28) | mem 73 (body0 32) | L 59 (body0 28)
   arm D  NOZ05 + DRPUB=1 -- m_dr non-zero at iw25 on 1 174 369 of 1 211 520 (arm C: 0),
                            provenance iw12 age 0; new live slots ONLY at L iw25/27/39/40 and
                            acc iw41..44  <- SRC 0x0B at iw25 confirmed BEHAVIOURALLY
   ALL FOUR:  §70/§211  min 0 max 0  in the loud bucket AND the 726 040-frame quiet window
```

⚠ **NOTHING SHIPPED. `UPD6383_NOZ05` is a DIAGNOSTIC, DEFAULT OFF**, for three reasons: its cell
`0x05` **rails** (`§86` quiet `[8 388 607 .. 8 388 607]`, full scale with no notes — §176's warning,
third occurrence); there is **no decode** under which `iw35`/`iw45` do not store (both carry
`HI_ST`, both `mode 2`, and **neither carries bit 7**, so `§109`'s CO-EQUAL store-gate ambiguity —
mask bit 29 — cannot refuse them under either reading); and by §216 it produces no audio.

**⇒ NEXT: (1) THE OUTPUT STAGE, with `UPD6383_NOZ05=1` on so a fix is not masked by a zero input.
(2) the send's residual question is the store's DATUM, not its address — the bit-4 store writes the
PRE-update accumulator (`iw39` stores `acc_to_datum(130 485 107 904) = 1 991 044`, `iw38`'s
post-value); at `iw35` the POST-update accumulator is INPUT-DEPENDENT, so a post-update store would
DEPOSIT audio there. `iw45`'s post-value is still constant, so it does not finish the job alone.**
⚠ **`UPD6383_DRPUB`: DEFAULT OFF still.** It now has a measurable consequence (arm D) — but only
with NOZ05 on, and the shipping condition names the **SHIPPED** build's delay line.
⚠ **rule 8, SHARPENED by §220:** a fired count that prints only when non-zero makes "0 fires" and
"never ran" the same log line. **Print it unconditionally with the arm's flag.** Audit a bit before
arming it with `dsp/tools/bit26_audit.py`.

---

## TIER 0a-prev-219 — the §219 blocker, SUPERSEDED by §220 but TRUE IN EVERY PART

> **★★★ THE SEND IS D-RAM CELL `0x05`, AND `iw35` OVERWRITES THE AUDIO THAT `iw9`/`iw11`
> DEPOSITED THERE.** `§213 §4`'s *"one corpus-unique word whose `SRC` is a GUESS"* (`iw25`,
> `SRC 0x0B`) **stopped being a guess in §215**, and **no `SRC` on the send path can decide a
> stored value anyway** — the delay WRITE and the `HI_ST` store both take `acc_to_datum(m_acc)`,
> never the bus. ⇒ **DO NOT look for the send defect in a SOURCE-field decode** (dead-end 28).
> ⚠ **"the delay line is EMPTY" is IMPRECISE** (dead-end 29): `§75` counts **1 175 999 delay
> writes with content** on the shipped build — the kernel's `iw46` writing the DC `0x7D70`.

---

## TIER 0a-prev — the §218 blocker, SUPERSEDED by §219. Kept so the closure is legible

> **★★★ THE WHOLE `iw25` LINE OF ENQUIRY IS CLOSED — decode, delivery, schedule, line index,
> register width and latency. §218 refuted the last open rival (the CROSS-FRAME pipeline) with
> NO run and NO rebuild, and corrected the census it rested on: there are **7** class-2
> `SRC 0x0B` words in the corpus, not 9, and `ENSEMBLE w62` is not one — its `lo12 0x40B` carries
> `SRC 0x10` (the ACCUMULATOR); the `0B` §217 §5 read was the ACTION field.**
> ⛔ Its handover — *"NEXT: the SEND, `§213 §4`'s one corpus-unique word whose `SRC` is a GUESS"* —
> is **RETIRED BY §219**: the guess was decided in §215 and no `SRC` on the path is load-bearing.

```
   arm A  §217 provenance at iw25  540000 evals | age 1..1 | read by iw289 x540000   <- SINGLE BIN
   arm B  (DRPUB=1)                540000 evals | age 0..0 | read by iw12  x540000
   the cross-frame rival predicted  read by iw26, age 1..1                <- 0 % of the mass
   §218  41 delay words (21 READS) between iw26(N-1) and iw25(N) -- one-deep cannot span it
   §218  item A "+4 after the PRECEDING read" is 6/6 at ENSEMBLE; the rival is UNDEFINED at w92
```

---

## TIER 0a-prev — the §215 blocker, RETIRED by §217 and §218. Kept so the closure is legible

> ⛔ **"THE BLOCKER IS THE §78 PER-LINE PUBLISH SCHEDULE" is REFUTED (§217).** The datum is not
> lost — it is published intact to `iw98`, 540 000/540 000. The line index is a RED HERRING.

> **THE `iw25` DECODE IS CLOSED — `SRC 0x0B` = the delay-read data register IS RIGHT, on a class-2
> word as on a class-1 one, REFUTING the rival by the corpus. THE BLOCKER MOVES ONE HOP UPSTREAM:
> the datum `iw12` fetches NEVER REACHES `iw25`. In the arm where the delay line was FULL of audio,
> `m_dr` at `iw25` was non-zero on `0` of `1 211 520` evaluations while `§80` published `181 521`
> non-zero data. THE BLOCKER IS THE §78 PER-LINE PUBLISH SCHEDULE.**

Established by runs `data/src0b2_A_off_215.log.gz` (shipped) and `data/src0b2_B_on_215.log.gz`
(rival forced ON), same build, clean vehicle, `-log`, 1 440 001 frames, ~314 000 loud — cite the
run, not the section (rule 11). Scored against `data/PREDICT_215.md`, committed **before the
build**; N1/N2/N3 and the calibration all held.

```
   arm B  §46  24 922 560 reads, 181 521 returned NON-ZERO      (arm A: 0)
          §80  latched 24 922 560 (181 521 nz) | publish hits 24 922 552 (181 521 nz)
          §215 m_dr non-zero AT iw25:  0 of 1 211 520           <- the blocker, in one line
   arm A  §215 mem[ptr] at iw25 non-zero on 313 169 ~= 313 960 loud frames | m_dr non-zero on 0
```

**THE DECODE, settled by the corpus (41 listings, 3057 words):** `lo12 0x2D9` is 36 words — 29
delay WRITE, 6 delay READ (ENSEMBLE), 1 = kernel `iw25`. Its consumer `0012201655` (`mac ta`) has
a **0.43 %** base rate and **13 of 13** of its sites are immediately preceded by a class-1
`addr8 0x20` DELAY READ. ENSEMBLE fuses read+capture in one `2D9`; the kernel splits the identical
`2D9` off one word ahead of its read — **same lo12, same idiom, same successor.** The rival would
need one lo12 to mean two things on two classes and would leave the kernel's two delay READs with
no consumer. ⇒ `UPD6383_SRC0B2` **default OFF, NOT SHIPPED.**

**⛔ THE FOUR FALSIFIERS OF `HANDOFF-NEXT.md` §1.2 ARE RETIRED AS A TEST.** All four passed under
the rival — and had to: arm A measured `mem[ptr]` at `iw25` non-zero on ≈ the loud-frame count
*before the rival ever ran*. They grade **"is the operand alive"**, not "is it `mem[ptr]`".
★ RULE 15: *a criterion that every live operand satisfies is a reach test, not a decode test.*

**★★★ AND THE RESULT THAT OUTLIVES IT:** with the send FORCED open, body 0 ran its whole ladder on
live audio (28 input-dependent slots, `acc` last-dependent slot `iw38` → **`iw204`**), fed body 1 —
and `§70 ACCA at w73` / `§211 ACCB at w78` stayed **`min 0 max 0`, quiet AND loud**, `§61` both
ports 0 non-zero, `§54` 0 loud output frames. ⇒ **The output stage is a null INDEPENDENTLY of what
the send carries.** §211 asserted it; §215 proved it by feeding it.

**Next:** does `iw12`'s datum ever reach `iw25`? Instrument the publish immediately preceding
`iw25`, per frame. If it never carries, decide between the **line index**
(`line = descriptor_value & 0x3f`, and §46 shows the kernel's descriptors resolving to `0000`, so
every kernel delay word shares line 0), the **ordering**, and the **single `m_dr` register** — in
that order. Env gates, default OFF, fired counts; the u64 mask is EXHAUSTED.

⚠ **TWO VEHICLE TRAPS, one run each:** the isolated `-cfg_directory` must carry
`:DSPCFG value="3"`, **and** MAME must be given **`-log`** or the entire `upd6383:` report is
discarded and the run looks like a crash.

**⛔ RETRACTED by §213 — the previous blocker's "one gradeable lead" was a PROBE ARTEFACT.**
`upd6383.cpp`'s ACT-0x07 site had an **unbraced `else`**, so `kwatch`/`watch_store`/`store_probe`/
`m_dwr` ran on every VISIT while §112's latch arm (mask bit 25, ON) stored nothing. `iw39` performs
**one** store, not two. Fixed under `UPD6383_STPROBE` (default 1): fired count **3 630 720 = the
§112 latch count exactly**, and the §104 census is identical slot-for-slot to §211 in all three
columns. ⇒ *"suppress one of the two stores"* would have been a **no-op on the machine**.
⚠ Do not read "cell X is write-only" off §98: its READ hook sits only on the anchored `SRC 0x07`
evaluator, so `SRC 0x00` reads are invisible to it (§213 §5.2).

---

## TIER 0a-old — the previous blocker  (§165, 2026-07-30), still open but no longer the headline

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

★★ **TWO KINDS OF ENTRY LIVE HERE NOW.** Entries 1–30 come from `SPECULATIVE-APPLIED-REGISTER.md`,
which `gen_ledger.py` reads. Entries **31+** include **REPO-EXTERNAL** verdicts from
`kn7000_mame/notes/`, which **NO GENERATOR READS** — they are filed by hand and they must be,
because the index is repo-scoped while the evidence is not. `python3 dsp/tools/gen_ledger_ext.py`
sweeps the notes and reports what is still unfiled: **112 DSP-relevant graded verdicts** as of
2026-07-31 (⚠ INFERRED aggregate — a lower-bound work queue, not a statistic).
⚠ **And entries 1–30 stopped at §220.** Nothing from §221–§227 was filed for eleven days while
those seven sections refuted six distinct candidates. **File the refutation in the same pass that
earns it.**

⚠ #1 and #2 were aimed at §163's *"kernel `iw32` pins the phase"* blocker, which §165 then
measured out of existence. They stay listed: the refutations are still sound, and the ideas are
the ones a reader would reach for again.

| # | the idea | why it is dead | where |
|---|---|---|---|
| 1 | Fix the phase clobber by changing **`DRAM_UNIT_BASE`** | **FORCED**: kernel A's walk begins where the previous frame *closed*, so base and window are coupled and `iw32` follows the cell wherever it moves. Bit 27 ran it — gate fires, `dp` `0x07`→`0x08`, **every value bit-identical** | §108 §5 |
| 2 | Decode `040.0.**.C63` / `012.4.01.1CE` as the missing phase producers | Both **already modelled**: `SRC 0x11/ACT 0x03` = `tempB ← ACCB`, `SRC 0x07/ACT 0x0E` = `P ← mem[ptr]`. Their presence in the roadmap's *"no reading of any kind"* list is a **corpus statistic, not a statement about the emulator** | §163 |
| 3 | `addr8` on the class-6 word = the **table extent** | The `0x28` sites are fed by scale `0x000010` = 16; `0x000028` does not occur in the coefficient corpus at all. The `24`/`0x18` agreement was coincidence | `lfo-ramp.md` P-16 |
| 4 | Implement the class-6 lookup **now** | Every index candidate is constant (`acc 0..0 \| m_dp 12..12 \| cursor 9..9`, 1 129 389 hits). A frozen lookup returns one entry forever, and that reads as *refuting the sine* against the "226 not 240" test. ★ **CONFIRMED DOWNSTREAM (§158):** the settled tap modulation is **CONSTANT per voice** — `§104` gives `iw96 15729946 \| iw105 15729540 \| iw137 −15727740 \| iw146 −15727740`, **all `min == max`** in quiet *and* loud — *because the lookup is a no-op*. ⇒ rule 4: the consumer cannot be validated until its index varies. See also entries 3 and 9 | §162, §158 |
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
| 19 | `iw39` stores TWICE to cell `0x06` and the second store wins (**§211 §6**) | ⛔ **RETRACTED §213.** The site-3 record is a **PHANTOM**: an unbraced `else` at the ACT-0x07 site let `kwatch`/`watch_store`/`store_probe`/`m_dwr` run on every VISIT while §112's latch arm stored nothing. Fired count after the fix = **3 630 720 = the §112 latch count exactly**; §211's own log already contradicted it (`iw34` logged storing 8 388 607 to `0x06` while §104 shows `6 039 795` still there two slots later). "Suppress one store" was a **no-op on the machine** | §213 |
| 20 | `tempA` is empty at `iw39` because its producer has never been identified (the `SRC 0x13` shape) | ⛔ **ANSWERED §213, not a hole.** `tempA` is INPUT-DEPENDENT `iw7..iw24` and is **zeroed at `iw25`** by `SRC 0x0B` + `ACT 0x19` — the delay-read register, 0 on 24 922 560 of 24 922 560 reads. A correct consequence of §48, and the send inherits it | §213 |
| 21 | `SRC 0x0B` at a CLASS-2 word is a different code (`mem[ptr]`, or anything but the delay register) | ⛔ **REFUTED §215, by the corpus.** `lo12 0x2D9` is 36 words — 29 delay WRITE, 6 delay READ, 1 = kernel `iw25`. Its consumer `0012201655` (`mac ta`, **0.43 %** base rate) sits within 3 slots of a class-1 `addr8 0x20` DELAY READ at **13 of 13** sites. ENSEMBLE `w10` fuses read+capture in one `2D9`; the kernel splits the identical `2D9` off one word ahead of its read, with the SAME successor. The rival needs one lo12 to mean two things on two classes AND leaves the kernel's two delay READs with no consumer | §215 |
| 22 | `HANDOFF-NEXT.md` §1.2's FOUR FALSIFIERS as a decode test | ⛔ **RETIRED §215.** All four passed under the refuted rival, and had to: arm A measured `mem[ptr]` at `iw25` non-zero on **313 169** ≈ the **313 960** loud frames *before the rival ran*. `iw25`'s pointer sits on a LIVE cell, so ANY live operand scores 4/4. They grade **reach**, not **identity** | §215 |
| 23 | "the output-stage null is an artefact of a zero send" | ⛔ **REFUTED §215.** The send was FORCED open: body 0 ran its whole ladder on live audio (28 input-dependent slots, last dependent `acc` slot `iw38` → **`iw204`**), fed body 1 — and `§70 ACCA at w73` / `§211 ACCB at w78` stayed `min 0 max 0` in **both** buckets, `§61` 0 non-zero, `§54` 0 loud frames | §215 |
| 24 | The **LINE INDEX** (`line = descriptor_value & 0x3f`) loses `iw12`'s datum — "the kernel's delay words all share line 0" | ⛔ **REFUTED §217.** That came from `§46`'s descriptor dump, which is an **UNGUARDED BOOT-TIME SAMPLE** (`m_dly_dsc[]` has no `m_frames_run` guard, so it freezes the pre-upload state where every cell reads `0000`). `§204`'s **guarded** census, *in the same log*, gives the kernel three distinct lines (`0x01`/`0x20`/`0x00`) with `iw12 ↔ iw98` paired exactly as `§79` says. Standing rule 10, third occurrence | §217 |
| 25 | **Widen `m_dr`** / "it is a single-register problem" | ⛔ **MOOT §217.** One register is enough: `§217` measured **`publishes strictly between iw12 and iw25: 0`** — nothing overwrites it in `iw13..iw24`. The fault was *when* `m_dr` is written (only at a delay word, and `iw25` is not one), not *how many* registers there are | §217 |
| 26 | The class-2 `SRC 0x0B` pipeline is **one-deep and CROSS-FRAME** — the word captures the datum of the read that FOLLOWS it, from the previous frame, so `DRPUB`'s `age 0` is off by one frame | ⛔ **REFUTED §218, three ways, with NO run.** (a) Pre-registered discriminator: the rival predicts tag `iw26`; arm A's histogram is **SINGLE-BIN `iw289`**, age 1..1, 540 000/540 000 — `iw26` holds **0 %** (`m_prov_other` silent in all three arms). (b) FORCED: **41 delay words, 21 of them READS**, execute between `iw26`(*N−1*) and `iw25`(*N*) — *one-deep* forbids the retention *cross-frame* needs. (c) Corpus: item A's "+4 after the PRECEDING read" is exceptionless **6/6** at ENSEMBLE, while "the FOLLOWING read" is **UNDEFINED at `w92`** and −30 at `w34` | §218 |
| 27 | **`ENSEMBLE w62` / `MULTI TAP w25` are class-2 `SRC 0x0B` words** "ahead of their read" (§217 §5's residue) | ⛔ **WRONG FIELD, §218.** `lo12 0x40B` = `SRC 0x10` (**the ACCUMULATOR**, anchored) + `ACT 0x0B`; the `0B` is the ACTION. The corpus has **7** class-2 `SRC 0x0B` words, not 9 — which `upd6383.cpp`'s own `case 0x0B` comment has said since §215. ⇒ §217 §5's "a shape no latency model explains" is **EMPTY**: `w62` is not in the class, and `iw25` at **+13** is *inside* item E's `land ≤ 4` with 0 intervening publishes | §218 |
| 28 | The **SEND is decided by a guessed `SRC`** (`§213 §7`, `HANDOFF-NEXT.md` §1 item 1) | ⛔ **DOUBLY REFUTED §219, statically.** (a) The guess — `SRC 0x0B` at `iw25` — **stopped being a guess in §215** (13/13 successor identity, the ENSEMBLE/kernel `2D9` twin), was provenance-graded in §217 and its population re-verified in §218. (b) **No `SRC` on the path decides a stored value**: the delay WRITE (`upd6383.cpp:2081-2090`) and the `HI_ST` store (`:2942`) both take `acc_to_datum(m_acc)`, never the bus, so a `SRC` there changes a GAIN OPERAND, never whether anything is injected. `tools/src0b_census.py sendpath` grades all 44 non-C-format words of kernel A | §219 |
| 29 | "the delay line is **EMPTY**" as an independent fact | ⚠ **IMPRECISE §219.** `§75` in the same report as `§46`: **1 175 999 writes carry content** (one per settled frame — the kernel's `iw46` writing the DC `0x7D70`), and `§200` reports reads resolving with 0..4401-frame ages. The reads return zero because the **bodies** write zero, because their input cell `0x05` is zeroed by `iw45`. "Empty" names a symptom of dead-end 28's replacement, not a cause | §219 |
| 30 | **Mask bit 26** (`0x4000000`, `m_mirror06_n`) — mirror the kernel's `0x06` result into `0x05` to fix the DEPOSIT ADDRESS | ⛔ **REFUTED §220, by running it.** It **fired 5 881 351 times** — exactly 5 per kernel-A pass (`iw19/21/27/33/39`, mode 2; **not** `iw72`, whose mode is 1) — and body 0's `§104` pickup at `iw84` stayed `0 ‖ 0`, because **every mirror site is upstream of `iw45`**, whose zero store is the last write to `0x05` before the CALL. Worse, it made kernel A **strictly less input-dependent** (`acc 27→22, mem 21→10, L 18→12`) via a cross-frame path through cell `0x06`. ⇒ **the mirror destroys input dependence, it does not create it.** ⚠ And §219 §8's reading *"a null means the gate never fired"* is wrong: this is a null with a fired count of 5.9 M | §220 |
| 9 | "the delay tap **sweeps** ±240" / "each voice ramps 0→depth, a **sawtooth**" | Both retracted. The first pooled voices of opposite sign; the second censused across the boot transient. The settled modulation value is **CONSTANT** | §155, §157 → §158 |
| 31 | Open the **KN7000 / SHARC effects engine as a cross-model oracle** for IC311's coefficients | ⛔ **RUN 2026-07-22, VERDICT: NEGATIVE.** **Zero** arbitrary coefficient is shared. 208 KN5000 constants vs 548 KN7000 floats: 12 shared two-decimal round values against ~5 expected from an independent draw of the same ~100-value pool (shared **habit**, not shared **data**), and the only two non-round shared values are **±0.125 = 2⁻³**, a shift. KN5000's signature **2/π = 0.63662 (53 occurrences)** appears nowhere in the KN7000 records; KN7000's **0.618 / 0.5614 / 0.876 / 0.2435 / 0.111 / 0.243** appear nowhere in the KN5000 set. ⚠ A naive float-set baseline predicts 1.8 ± 1.3 against 16 observed and **looks significant** — it is wrong, because both real sets are biased toward round decimals; split the sets and the signal vanishes. ★ **The note flagged its own trap in advance**: *"recording this because it is exactly the sort of number that could have been reported as a correlation"* | `kn7000_mame/notes/kn5000-dsp-coefficients.md` §5 / §5.1 |
| 32 | **Delay tap lengths survive the change of chip** — "N milliseconds is the same physical quantity on either instrument", so KN7000 taps should locate KN5000's (Felipe's strongest cross-model hypothesis) | ⛔ **FALSIFIED 2026-07-22.** Raw intersection of the two tap sets is **`{200}`** — one value, and it is round. Over **26 × 37 = 962 pairs** with a ±0.3 ms window spanning 5–500 ms: **2 of 26** at 32 kHz, **7 of 26** at 44.1 kHz, **4 of 26** at 48 kHz — consistent with chance, and **the test cannot even pin the sample rate**. ★ **The reason is the transferable part: both machines design their delay lines in round SAMPLE counts, not round milliseconds** (KN5000: 160 200 520 600 640 720 840 1100 1160 1240 1550 1760 12800; KN7000: 200 250 400 512 800 1000 4000 5000 8000 32768). A tap is an **address in a delay buffer**; a designer moving to a new chip with a new buffer geometry re-picks them from scratch. The physical-quantity argument holds for a spec sheet, not for an implementation | `kn7000_mame/notes/kn5000-dsp-coefficients.md` §5.2 |
| 33 | **Seed the coefficient cursor at frame start** (`UPD6383_CURSEED`, base `0x00`) — "the cursor is never seeded, so the header runs on whatever the previous frame's unit-1 body left behind" | ⛔ **REFUTED §226, FROM DISK, NO RUN — and both halves of the premise are wrong.** (a) **The base IS seeded, by an instruction**: the epilogue's own `iw69 = 801.0.90.821 ldptr #$90` reaches register row 25's `is_ldptr` branch (`m_cursor = ad` under `!(m_specmask & 0x1000)`; **bit 12 is CLEAR in the default**), and the epilogue contains **ZERO** cursor-advancing words, so the next frame's `w0` starts at **exactly `0x90`, every frame**. (b) **Base `0x00` is the UNIT-0 EFFECT's own per-effect parameter bank** — selecting PARAMETRIC EQ rewrites `0x00..0x1E` wholesale and moves **every one of `0x00..0x13`** while writing nothing at or above `0x50`; the header is a **literal canned image in Sub CPU ROM** and cannot read a per-effect bank. (c) At base `0x00` the same ladder reaches **`2.733 × FS`** with PEQ loaded — **1.6× WORSE**. ⇒ ★★★★ **A CLIP RATE THAT FALLS BECAUSE A COEFFICIENT BECAME *SOMEBODY ELSE'S* IS ALSO A REGRESSION.** ⚠ And *"set it to the value it already has"* **cannot fail** — rule 8 | §226, `HEADER-BANK_findings.md` item E |
| 34 | **`ACT 0x00`'s bus term is a missing general attenuation** — the unity-gain bus addend is what overflows the kernel ladder, so attenuate it | ⛔ **REFUTED §224, FROM DISK, FOR `iw34`.** Zero the `ACT 0x00` bus term and `iw33` **still leaves 10 234 099 = 1.220 × FS. It still clips.** ⚠ **HALF RIGHT, AND THE HALF MATTERS**: the mechanism IS real — a unity-gain bus addend exists — but at `iw34` it is not the cause, and at `iw13`/`iw91` the fault is **WHAT THE BUS CARRIES** (a railed memory cell; a modulus), not that it is added. The named addend at `iw91` is `iw92 − iw91 = 8 388 607 = 0x7FFFFF = C-RAM[0x01]` **exactly, at both endpoints** — the constant `upd6383.cpp`'s **own** C-RAM annotation calls *"wrap"*, which §225 then shipped as `UPD6383_LFOWRAP`. ⇒ **do not re-propose "attenuate the bus"; ask what is ON it** | §224, superseding §223 §8.2 |
| 35 | **`SRC 0x03` / `ACT 0x03` as an epilogue crossbar latch** (`§E-D85`) | ⛔ **REFUTED §222 by a two-sided bisection.** Arm E fired 1 204 800 / 1 203 840 and its `diff`s are **EMPTY**; arm D equals arm C in every column. `iw205` is a **MESSENGER** — its operand `547 518 .. 8 388 607` gives `ACCB 35 882 139 648 .. 549 755 748 352 = L × 65536` at both endpoints — and **`m_bx_sel0d` stays FROZEN at 1**, where changing it breaks body 0's only working pickup and the regression **IS** the `79 438 ± 90` rule-19 DC. ⚠ **`D-RAM[0x85]` has NO WRITER AT ALL** on settled frames, measured by an instrument that names `iw70` the instant one exists | §222 |
| 36 | **A store-suppression rig will produce a non-railing vehicle** | ⛔ **REFUTED §223.** The narrow rig (`NOZ05 = 2`, `iw35`/`iw45` only, 2 stores) reproduces `28/32/28` / `33/40/29` / `2/1/2` column for column **and still rails** — and so does the shipped build, which clips **4.924 %** quiet / **4.920 %** loud of all accumulator conversions with the input **exactly zero** (⚠ **5.303 % is the `LFOWRAP=0` CONTROL arm's number**, not the shipped build's, since §225). ⇒ **the rail is upstream of the send entirely**; the rig removes the two stores that were HIDING it from body 0, it does not create it. **Treat nothing that rails as evidence**, and do not build another suppression rig looking for a clean vehicle | §223, correcting §222's attribution |
| 37 | **Kernel A's cell `0x06` is a BISTABLE / a latch-up with a stable second state** | ⛔ **RETIRED §225. `0` IS NOT A FIXED POINT.** `§S3` — read-only, always on, **no frame gate** — reports `SETTLING`: cell `0x06` is 0 before any instruction writes it, **stores #1..#1356 write exactly 0** (measured: the ladder's lowest rung is *"val ≥ 1"* and first fires at #1357), then `iw19`'s **first ever execution** at frame 264 002 puts `1 650 061 = 0.1967 × FS` **into an empty cell** — already **1.52 ×** the `0.129 703 × FS` threshold — and the rail follows **on the next frame**. **There is no second state.** The rail needs a **FORWARD GAIN** explained, not an ENTRY. ⚠ **`§106`'s writer list was 5 names of 12** and `5 881 351` was never divisible by 5 — quote `nz`, never just the count | §225, retiring §224 §2 |
| 38 | **The multiply should read `C-RAM[cursor + 1]`** (`§S2sq`, the coefficient squaring) | ⛔ **CLOSED WITHOUT A BUILD, TWICE.** (a) `SQUARING-MULTIPLY_findings.md`: the multiply has **one hardwired coefficient port** (`C-RAM[ccur]`; no instruction field selects it) and **one** operand bus, so a word routing the coefficient onto that bus has **no second port for a sample** — the squaring is **FAITHFUL**. Census `123 / 893 = 13.77 %` against a `0.05 %` null, `z = +90`: **evidence FOR the decode.** (b) The re-attribution to the cursor BASE is refuted by §226 (entry 33). ⛔ **`SRC 0x08 = C-RAM[cursor]` is ANCHORED** by the CHORUS LFO (`C-RAM[0x00] = 114` ⇒ `+114`/frame; ★ §228 MEASURED the resulting ramp at **step 114..114 CONSTANT** over 1 175 985 frames) — **do not touch the source read** | `SQUARING-MULTIPLY_findings.md`, §226 |
| 39 | **`iw33`'s `f31 = 1` should not carry** (`UPD6383_NOCARRY`) — "the kernel ladder overflows because a term is being added that should not be" | ⛔ **REFUTED §227, FROM DISK BEFORE IT RAN, AND THEN MEASURED INERT.** `f31 == 1` is `HI_ACC_ADD`, **1309 of 2989** non-C-format corpus words and **695 of 1178** ALU-decoded; op 0 LOADs, op 2 HOLDs *without a product*, op 3 gets HOLD's behaviour ⇒ **it is the only accumulate the ISA has**, and the **PARAMETRIC EQ** biquad (grade SOLVED, validated at **0.198 dB** against its designer) sums five products through `f31 == 1` words `w6..w10`. Without the carry `H(z)` = `makeup · (−a2) · z⁻²`. **AND IT DOES NOT FIX THE CLIP:** `iw34` becomes `8 388 608` = `2²³` = **FS + 1** and clips `706040/706040` quiet, `313960/313960` loud — **unmoved from shipped.** ⇒ ★★★★ its `§S1` `4.924 % → 0.379 %` is **117 655 680 accumulate steps refusing to add**: **a clip rate that falls because a term stopped being added is a REGRESSION wearing a good number.** Collateral: `§104` body-0 goes 100 % input-INDEPENDENT and **`m_rf[0x8D]` vanishes** | §227 |
| 40 | **`P_SHIFT = 7` is the Q-consistent shift** — "`>> 6` is one bit short" | ⛔ **REFUTED §227, and the phrase had TWO meanings which are different experiments.** The core's own header records coefficients **Q1.22 (MEASURED from the firmware's scale constants)** and data Q0.23 ⇒ the Q-consistent TOTAL is **22**, which is what ships. **TIED (7/15, total still 22) is a MEASURED NO-OP** — the entire `§S1` block is BIT-IDENTICAL to the default over **269 279 999** conversions, the only differing line being the header text `>> 16` vs `>> 15`. **UNTIED (7/16, total 23) halves `m_rf[0x8D]` `0x009B26 → 0x004D93`** and *still* clips at `1.110 × FS`. ⚠⚠ **AND `§41` DOES NOT GUARD `P_SHIFT`** — it reads C-RAM *levels* `0x06`/`0x86` and is UNMOVED by a 2× product rescale; **`m_rf[0x8D] = 39 718` is the guard that fires.** Fix the three-guard phrase wherever it is quoted | §227 |
| 41 | **`C-RAM[0x90..0xB4]` is the header's BOOT-FIXED coefficient bank** (§226 item D, in its strong form) | ⛔ **REFUTED §227 BY THE CAPTURE §226 ITSELF ASKED FOR.** A preset change **CONCERT REVERB 1 → ROOM REVERB 1** rewrites **23 cells, every one inside `0x90..0xB4` and NOTHING else in the 256-cell C-RAM**: `[00..4F]` 0 of 80, `[50..8F]` 0 of 64, the header's own walk `[90..A3]` **13 of 20**, the ladder cells `[9B..9D]` **2 of 3**. ⇒ **it is UNIT 1's per-algorithm parameter bank**; it looked fixed only because both §226 captures carried the **same** reverb. ★ The control that makes it proof-grade: an independent 45 s panel run landing on CONCERT REVERB 1 reproduces the archived cold-boot capture on **all 256 cells, 0 differ** ⇒ **the cold-boot default reverb is CONCERT REVERB 1**, so every *"CHORUS + RR1"* label in §226 names the wrong preset. ⛔ **This does NOT re-open base `0x00`** (entry 33) | §227 |
| 42 | **The `f98` CROSS-UNIT A/B** — select GATED REVERB into unit 0 with a reverb preset in unit 1, making `012.A.00.1D5` / `212.A.00.1D5` co-resident in one frame (strategic review action 3) | ⛔ **NOT VIABLE, FROM DISK, NO BUILD.** The `f98 = 2` half sits at **`iw207`, inside body 1's third-death region, measured an EXACT ZERO on every channel in BOTH buckets across NINE archived arms** (§220 A/B/C/D, §221 A, §222 A, §223 F, §224 I, §225 K: `dp = 0xD0`, `acc 0..0`, `mem 0..0`, `L 0..0`) — **you cannot A/B a live number against a structural zero.** ★ And it is **UNNECESSARY**: `KERNEL w16 = 0192A00455` (`f98=1`) and `w17 = 0292A00455` (`f98=2`) differ in `f98` **and nothing else** and run **back-to-back in every frame of every program ever emulated**, already printed by `§104`/`§S1`/`§S2`. ⚠ Even that perfect pair is not a controlled measurement — it is a CHAIN (`iw17`'s carried term IS `iw16`'s result) and the two words necessarily read different coefficients. ⇒ **restate the closure: not *"no co-resident pair"* (falsified four ways) but *"NO DISCRIMINATOR"*.** ⚠ The review's sentence also dropped `a10 MULTI TAP DELAY`, which carries the same word | `PREDICT_F98_CORESIDENT.md`, §229 |
| 43 | **`hi12` bit 5 via ROCK ROTARY** — `000.2.00.000` vs `020.2.00.000` co-resident in `a15`, "one program load decides whether a `nop` the disassembler prints 62 times is a `nop`" (strategic review action 6) | ⛔ **VOID BY CONFOUND, AND THE CONFOUND IS 100 % OURS.** `000.2.00.000` matches the §223 nop guard on **all four** terms (`hi12 == 0x000 && class4 == 2 && addr8 == 0x00 && lo12 == 0x000`) and is **swallowed**; `020.2.00.000` fails the first term, falls through, and runs a full `exec_alu()` that **clears and reloads the accumulator** (`acc <- 0 + (mem[dp]<<16) + P`). Under `DSPCFG = 1` it **TRAPS** and the frame is discarded instead. §223's `addr8` narrowing does not help — `000.2.00.000` has `addr8 = 0x00` too. ★★★★ **DECISIVE: `hi12` bit 5 is read in EXACTLY ONE PLACE in the whole device — that guard's `hi12 == 0x000` equality.** Remove the guard ⇒ the two words execute **bit-identically**; keep it ⇒ the difference **IS** the guard. ⇒ **the review's own kill-condition (*"measures identical ⇒ bit 5 inert"*) CANNOT FIRE** — rule 8. ⚠ Also: the pair is co-resident in **TWO** images (`a70 AUTO WAH+S.DELAY` too, and `a70` is the one with a written vehicle), and the *"ready recipe"* is `verified: false` (29 of 224 are verified). ★ **STRIKE IT, DO NOT DEFER IT** — but keep §229 §2.1: the corpus DOES constrain bit 5 (`f31 in {3,6,7}` is bit-5-only, **53 of 53** static, **0 counterexamples in 246 952 062** live executions) ⚠ **BUT §231 CORRECTED THAT SENTENCE AND THEN CLOSED IT — see dead end 44.** | §229, §231 |
| 44 | **`f31 ∈ {3,6,7}` as a decode lead** — three field values collapsed to one behaviour at four epilogue sites; "the cheapest open route to moving decode coverage" (strategic review action 6, §229 §7.1's pre-registered arm) | ⛔ **CLOSED BY §231, THREE INDEPENDENT WAYS, EACH SUFFICIENT.** ⑴ ⚠ **the corpus rule is OFF BY ONE**: 54 words carry `f31 ∈ {3,6,7}`, not 53 — `EPILOGUE w74 = C16.9.AB.000` is **C-format**, bit 5 CLEAR, and in C-format `hi12[3:1]` is not an operation field. Correct form: *53 of 53 among the 2989 NON-C-format words*. (Same conflation in §229's claim 5: the KERNEL's "2 bit-5 words" are both C-format ⇒ the kernel carries **zero**.) ⑵ ★★★★★ **the correlation is a SPANDREL**: base `0x020` — `hi12` with bit 5 and **nothing else** — holds **134 of 172** bit-5 words, **42 of 53** `{3,6,7}` occurrences and **7 of the 8** `f31` codes on ONE routing (`.2.00.000`); no other base carries more than 4. "3/6/7 requires bit 5" = "the only base on which `f31` sweeps its range is the base whose only bit IS bit 5". ⛔ *bit 5 extends the operation field* is **not supported by its own distribution**. ⑶ ★★★★★ **NOT LOAD-BEARING, MEASURED**: at all four sites, both buckets, **3 611 996 executions**, the discarded product is `min 0 max 0 nz 0` and the operand `L` is `min 0 max 0 nz 0`; every range degenerate and identical across buckets. The control **could have failed** — the *undisputed* HOLD (`f31 == 2`) discards a **non-zero** product **2 669 493** times, peak **592 032 946 752**. ★ AND EVEN SOLVED IT IS WORTH **8 WORDS**: `1178 → 1186`, `38.53 % → 38.80 %` — 41 of the 53 are refused **earlier**, by the ROUTING guard | §231 |

---

## TIER 0c — STANDING RULES, each earned by a retraction

1. **Before reporting any non-zero output, read `§70 ACCA` and compare min against max.** Two
   "IC311 outputs audio" claims have been retracted; one was a DC. *(§137)*
   ★ §211 adds the unit-1 half: **`§211 ACCB AT w78`**, same buckets. `§61`'s "DO2 peak 0" cannot
   tell an empty ACCB from an empty unit-1 OUTPUT LEVEL — read both.
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
   ★ **SHARPENED, §220: a fired count must be PRINTED UNCONDITIONALLY, with the arm's own flag
   beside it.** `m_mirror06_n` had an increment *and* a `logerror` and still made "0 fires" and
   "this code never ran" the same log — because the print sat inside `if (m_mirror06_n)`. That is
   exactly the ambiguity a fired count exists to remove. Fixed for `§106`; `§220 NOZ05` prints its
   count **and the per-`iw` breakdown**, which is what caught 55 pointer-drift fires in 3 528 080.
   ★ **And AUDIT A MASK BIT BEFORE ARMING IT** — `dsp/tools/bit26_audit.py` parses the C++ with
   comments and string literals stripped, enumerates every mask literal, decides whether the bit
   is set in the shipped default, counts the sites that test it (two sites = confounded, stop) and
   checks the fired count reaches a `logerror`. Never grep a spelling (rule 7's constructive form).
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
    ★ **Second occurrence, §211:** §141's *"`w73` erases the accumulator at the door"* was measured
    **with mask bit 55 ON**. That bit is 0 in the shipped default and fires **0 times**; on the
    shipped build the accumulator is zero from `w65`. A measurement taken under a gate belongs to
    that gate — **quote the arm with the number, every time.**
12. **A DIFFERENCE BETWEEN TWO BUCKETS IS NOT INPUT DEPENDENCE.** Free-running quantities (ramps,
    counters, phases) sampled over buckets of unequal length report different ranges by
    construction. The discriminator, and it is cheap: **do both range endpoints translate by the
    same constant?** If yes it is free-running. *(§211 — under the raw flag, body 0 appears to
    carry the signal at `iw90/91`; it does not, and `dsp/tools/s104_score.py` applies the rule)*
13. **AIM THE PROBE YOU ALREADY HAVE.** §150 §4 named the exact instrument and the exact slot —
    *"point the §109 store witness at slot 73 and read it"* — and 60 sections passed with the probe
    in the build and the slot missing from its list. **Before designing an experiment, check
    whether an existing instrument merely needs pointing.** *(§211)*
    ★ **Second occurrence, §218, and it paid the most:** the whole cross-frame rival was decided
    from three logs that already existed and a corpus already committed — **zero MAME runs, zero
    rebuilds**. ⇒ **A STATIC DECISION IS THE BEST OUTCOME, NOT A LESSER ONE.** Before designing
    an experiment, prove the existing logs *cannot* answer it.
14. **Instrumentation must follow the EFFECT, not the visit.** A probe placed beside a
    conditional rather than inside it reports events that did not happen — and the next pass
    builds a task on them. §211's headline lead was one unbraced `else`: three phantom stores
    per frame, polluting `§96`, `§109` and the `m_dwr` census at once. **When a gate's fired
    count and a store census disagree, suspect the census.** *(§213)*
15. **A CRITERION THAT EVERY LIVE OPERAND SATISFIES IS A REACH TEST, NOT A DECODE TEST.** §215's
    four pre-computed falsifiers all passed under a reading the corpus refutes — because `iw25`'s
    pointer sits on a **live cell**, so *any* substitution that puts a live value on the bus scores
    4/4. The counterfactual was measurable in the DEFAULT arm (`mem[ptr]` non-zero on 313 169
    ≈ the 313 960 loud frames) **before the rival was ever built**. ⇒ **Count, in the control, how
    many arms would pass your test. If the answer is "all of them", it is not a test.** And when a
    decode question has a CORPUS answer, the corpus outranks any run. *(§215)*
16. **A census that enumerates "cells touched" only sees the hooks it has.** §98 marks kernel
    cell `0x06` write-only because `pwatch()`'s READ hook sits on the anchored `SRC 0x07`
    evaluator alone; `0x06` is in fact a cross-frame carry read by `SRC 0x00`. Check the hook
    before quoting an absence. *(§213 — numbered 16 in §218; it and rule 15 were both filed as 15)*
17. **★ GRADE BY PROVENANCE, NEVER BY LIVENESS — and state the WRONG `iw` NUMBER as the failure
    mode.** The constructive fix for rule 15. §217's instrument tags every delay latch with the
    `iw` that performed the READ, carries the tag with the datum and histograms it at the consumer;
    a wrong source then reports a **wrong `iw`**, which no amount of liveness can fake. It graded a
    decode **with every value counter still at zero** (arm B: provenance flipped `iw289`→`iw12`,
    `§215 m_dr nz at iw25` still 0), and §218 refuted the cross-frame rival on the same histogram.
    ⇒ **A decode test must be able to name the specific wrong answer it would print.** *(§217, §218)*
18. **★ GRADE A FIELD CENSUS WITH THE DISASSEMBLER'S OWN ACCESSORS, NEVER BY EYE AND NEVER BY THE
    `lo12` STRING.** §217 §5 re-derived in prose a census `upd6383.cpp`'s `case 0x0B` comment had
    carried correctly since §215, read `lo12`'s **ACTION** field (`lo12[4:0]`) as its **SOURCE**
    field (`lo12[10:6]`), got **9** class-2 `SRC 0x0B` words instead of **7**, and built a
    handover question on the two impostors. **11** distinct `lo12` values occur on both class-1
    delay words and class-2 words, so the `lo12` string carries no class information at all.
    Use `dsp_disasm.lo_src` / `lo_act`, and control the result against a published corpus
    statistic (§218 reproduced `register-space.md` §4's `82`/`50` split digit-for-digit).
    ⇒ **And when a re-derived number disagrees with the source comment beside the counter, the
    comment is evidence — reconcile before building on the new number.** *(§218)*

19. **★ REPORT MEAN AND AC SPAN SEPARATELY, BOTH BUCKETS, BOTH ARMS, BEFORE CALLING ANYTHING
    AUDIO.** `min != max` is not signal: `79 438 ± 90` passes min-vs-max, the no-stimulus check
    *and* the translation rule, and is a **DC at −59 dB**. Mechanised — `§70`/`§211` print both.
    ⚠ `m_bx_sel0d` is FROZEN at 1 globally because the regression from moving it **IS** this DC.
    *(§221; and rule 1's two retracted "IC311 outputs audio" claims are the same shape)*

20. **★★ A NEW DETECTOR IS NOT EVIDENCE UNTIL IT HAS REPRODUCED AN ANSWER ALREADY ON RECORD —
    AND THE SELF-TEST IS PRINTED FIRST, NOT APPENDED.** A census printing a clean zero is
    indistinguishable from a correct negative, and a classifier agreeing with itself is
    indistinguishable from a correct one. Before interpreting ANY output of a new instrument:
    * validate it against known answers, **at least one of which would FAIL if the detector were
      broken** — a control every arm passes is rule 15's reach test, not a test;
    * prefer at least ONE **EXTERNAL** control — an answer produced by a *different* instrument.
      §225's `§S3` earned its keep this way: mask bit 26 counts the identical predicate at the
      identical hook and §220 measured **5 881 351**; `§S3` reported **5 881 351**;
    * ⚠ **internal consistency that is TRUE BY CONSTRUCTION IS NOT A SELF-TEST.** `§S2`'s
      `carried + bus + P == result` cannot fail — the terms are split out of `src_term` itself —
      and the source says so; its real controls are four pre-registered per-term values;
    * ⚠ **a control must be a case whose answer is known INDEPENDENTLY of the thing under test.**
      *(new, 2026-07-31: a sweep's "known PRESENT" control was itself one of the known-ABSENT
      cases, and demanded the opposite of the right answer);*
    * ⚠⚠ **AND AN INSTRUMENT CAN BE WRONG WHILE EVERY ARM AGREES WITH IT** *(new, §228)*: the
      `§196` LFO wrap census printed **0.5000 Hz** on every arm anyone ever ran, because its
      denominator included the **264 001** frames before the program is uploaded (during which
      the ramp is frozen) and its numerator truncated the last partial wrap. The rate it was
      hiding — **0.652313 Hz** — had been quoted in `LEDGER.md` for weeks as if measured; it had
      only ever been **derived from the increment**. ⇒ **before quoting a figure as MEASURED,
      find the log line it came from.** A number nobody can point at in a log is a derivation.
    * **print the result of every check, PASS or FAIL, before the finding** — reporting only the
      passes is how `§121` ran seven arms that were all the same arm.
    ⇒ **Report your failed controls out loud.** `UNWRITTEN-CELLS_findings.md` §2 opens *"two of
    them FAILED"*, and that is what makes the other five worth reading.
    *(named across §224/§225/§226; `hdrbase.py` 10 self-tests + 3 external, `f31carry.py`,
    `SQUARING-MULTIPLY_findings.md` §1, `HEADER-BANK_findings.md` §1 — all invoked it, none
    defined it, for 17 citations across 10 files; DEFINED HERE by §228)*

21. **★★ `§104`'s AND `§86`'s QUIET-VS-LOUD MARKERS CANNOT DISTINGUISH "INPUT-DEPENDENT" FROM
    "FREE-RUNNING AND SAMPLED OVER TWO FRAME SETS" — BUT THE SPLIT IS COMPUTABLE.**
    Proof, from a case in every log this project has ever taken: cell `07` quiet `[4 .. 8388594]`
    loud `[8 .. 8388598]` — the LFO phase, with no input in it; the endpoints differ by **less
    than one increment (114)** because the buckets are different *sets of frames*.
    ★ **The discriminator is FORCED by the instrument's own bucket predicate**
    (`nz = (m_in_val[0] != 0) || (m_in_val[1] != 0)`): the quiet bucket is the frames where the
    input latch reads **EXACTLY ZERO**, the same value on all 706 040 of them, so a **DEGENERATE
    quiet range (`min == max`) PROVES input dependence** and a non-degenerate one proves
    free-running state. `dsp/tools/rule21_all.py <log>` does it in one line.
    ⛔ **NEVER QUOTE A `§104`/`§86` COUNT AGAIN WITHOUT ITS `D-I` SPLIT.** Under it, `28/32/28`
    survives as `26/28/27` proof-grade + `0/4/1` free-running, and the shipped build's `2/4/1`
    "null" is **100 % free-running — body 0 is `0/0/0`**. Damage is confined to rows reading cell
    `0x07` or `0x10`; every other published tally is proof-grade. *(§224, operational §225)*

22. **★★ A CONTROL IS NOT A ROW, IT IS A **QUANTITY** — AND TWO CONTROLS THAT MOVE IN THE SAME
    ARMS ARE ONE CONTROL.** `§54`, `§70`, `§211`, the rule-19 line, `§61` and `§104`'s epilogue
    `D-I` tally have the **identical move-set** over 33 arms, and `present()` shows five of them
    are functions of **one local variable at one program point**. A battery of six that has never
    once disagreed with itself is one check with five extra prints. ⇒ **Before quoting N
    falsifiers, compute their MOVE-SETS: `python3 dsp/tools/outstage_collapse.py`.** Identical
    move-set ⇒ collapse them and say so. Strict containment ⇒ *that* is your independent check.
    ★ **AND TWO CONTROLS CAN COLLAPSE BY SENSITIVITY WHILE DIFFERING IN KIND**: `§70`'s `w73` reads
    the accumulator; `§211`'s `w78` reads an operand the emulator **fabricates** (§229). Both print
    `mean 0.0 span 0`; only one is a statement about the chip. **Sameness of behaviour is not
    sameness of meaning — check both.** *(§230; the control audit `f601303` found four of these and
    the measurement found six)*
    ⚠ **AND A CONTROL CAN BE INVERTED, NOT MERELY INSENSITIVE.** SINGLE DELAY's harness **rejected**
    the corrected machine and **accepted** the doubly-defective one, confidently and reproducibly,
    for three independent harness reasons (an uninitialised pointer, a double negation, a hard-coded
    window). ⇒ **"the control fired" is not evidence; run it against a machine you KNOW is good and
    one you KNOW is bad, and print both.** *(§230)*

23. **★★ A DOCUMENT THAT CALLS ITSELF *DERIVED* MUST NAME THE SOURCE IT WAS DERIVED FROM.**
    `gen_ledger.py` and `gen_fixlist.py` generate from `upd6383.cpp` *"so it cannot drift"* — from
    the **WORKING TREE**. On 2026-07-31 that tree held **211 uncommitted lines** from a concurrent
    lane, and a routine regeneration would have baked them into two documents whose entire
    authority is that they are derived. Both now take **`UPD6383_SRC_DIR`**; `SHIPPED-FIX-LIST.md`
    was regenerated against a pristine checkout of `HEAD`. ★ The same defect had a second head:
    `lint_handoff.py` picks *"the current shipped-default log"* as the **newest by mtime** in a
    shared directory, and graded four documents against an **untracked** arm dropped mid-pass by
    that lane. It now considers **git-tracked logs only**. ⇒ **An untracked artefact is not
    evidence, and a shared working tree is not a source.** *(§230)*
    ⚠ **AND A SECTION NUMBER IS A SHARED RESOURCE**: two `## §229` headings existed at once, which
    would have corrupted the generated tier-2 index. Claim it by writing the heading early, or
    check before writing. The prose-only pass renumbered.

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
| 7 | off | §43 | w72 / w77 ARE LEVEL-SELECT WORDS, NOT ACCUMULATOR OPERATIONS |
| 8 | off | §44 | C-RAM 0x50..0x8B IS A DELAY-TAP TABLE, NOT COEFFICIENTS. Dumped, the space has three clearly distinct regions: |
| 9 | off | §47 | TAKE THE DESCRIPTOR FROM THE PER-UNIT C-RAM BANK, NOT FROM D-RAM AT m_dsc |
| 10 | **ON** | §49, §217 |  |
| 11 | off | §50 | LAND IT IN tempA TOO |
| 12 | off | §52 | row 25 seeds the coefficient cursor from ldptr -- and this file already records that it is "⛔ STILL AGAINST K3, which pr |
| 13 | off | §53 | READ THE RAMP BANK AT Q0.16, NOT Q0.23 |
| 14 | **ON** | §62, §68 | SELECTOR 0x27 LOADS THE PER-UNIT OVERFLOW / MODE REGISTER (m_ovc) |
| 15 | off | §116 | SELECTOR 0x27 LOADS THE PER-UNIT OVERFLOW / MODE REGISTER (m_ovc) |
| 16 | **ON** | §69 |  |
| 17 | **ON** | §44, §72 | C-RAM 0x50..0x8B IS A DELAY-TAP TABLE, NOT COEFFICIENTS. Dumped, the space has three clearly distinct regions: |
| 18 | REFUTED | §113 | SRC 0x11 = mem[ptr], NOT ACCB |
| 19 | **ON** | §76 | A DELAY WORD ALSO RUNS ITS ALU |
| 20 | **ON** | §76 | THE PIPELINE IS KEYED TO THE PORT, NOT TO THE SLOT COUNTER. dram-datapath.md item A: "THE DRAM PORT IS A ONE-DEEP PIPELI |
| 21 | off | §82, §224 | A DELAY WORD'S ACTION PUTS ITS DATUM ON THE ACCUMULATOR |
| 22 | REFUTED | §138 | THE SAME ERASURE, AT THE OUTPUT STAGE |
| 23 | **ON** | §1, §5 | SRC 0x02 = reg[addr8], the MODE-1 ADDRESSED REGISTER. This is item J's own stated escape -- "SRC 0x02, undecoded, might  |
| 24 | **ON** | §100 | SRC 0x02 = reg[addr8], the MODE-1 ADDRESSED REGISTER. This is item J's own stated escape -- "SRC 0x02, undecoded, might  |
| 25 | **ON** | §41, §101 | DO NOT LET AN UNSUPPORTED SOURCE OVERWRITE A HOST-PROGRAMMED REGISTER |
| 26 | REFUTED | §220 |  |
| 27 | REFUTED | §108 |  |
| 28 | off | §109 | ACTION 0x07's MODE-2 store lands on the POST-increment cell |
| 29 | **ON** | §104, §109 |  |
| 30 | off | §119 |  |
| 31 | **ON** | §111 | THE HOST PAYLOAD IS 2x THE RAW THREE BYTES. r3-delaydram.md states it; §71/A3 reproduced it as a control that could have |
| 32 | off | §114 |  |
| 33 | **ON** | §114, §116 | WRAP mod 2^23 instead of saturating |
| 34 | **ON** | §119 | THE MEMORY-TO-MEMORY MOVE |
| 35 | off | §113, §234 |  |
| 36 | off | §113, §234 |  |
| 37 | off | §113, §234 |  |
| 38 | **ON** | §73, §86 | SEED THE COEFFICIENT CURSOR WITH THE PER-UNIT BASE AT THE CALL |
| 39 | off | §121 |  |
| 40 | off | §121 |  |
| 41 | off | §121 |  |
| 42 | **ON** | §121 |  |
| 43 | off | §121 |  |
| 44 | off | §121 |  |
| 45 | **ON** | §121 |  |
| 46 | **ON** | §121 |  |
| 47 | **ON** | §121 |  |
| 48 | off | §121, §209 |  |
| 49 | off | §121, §209 |  |
| 50 | off | §121, §209 |  |
| 51 | off | §121, §209 |  |
| 52 | **ON** | §133 |  |
| 53 | REFUTED | §135 |  |
| 54 | REFUTED | §40 |  |
| 55 | REFUTED | §136, §138 | THE SAME ERASURE, AT THE OUTPUT STAGE |
| 56 | **ON** | §70, §153 | THE DELAY-TAP MODULATION REGISTER |
| 57 | off | §142, §148 | `coef' only where f98 == 1 AND the word consumes a coefficient. §146 localised the railing to four words -- kernel iw14/ |
| 58 | off | §145, §148 | `coef' only where f98 == 1 AND the word consumes a coefficient. §146 localised the railing to four words -- kernel iw14/ |
| 59 | **ON** | §145, §148 | `coef' only where f98 == 1 AND the word consumes a coefficient. §146 localised the railing to four words -- kernel iw14/ |
| 60 | **ON** | §153, §200 | LAND IT IN tempA TOO |
| 61 | **ON** | §160, §222 | A DELAY WORD'S `addr8' IS A DIRECTION FIELD, NOT A REGISTER ADDRESS -- so ACTION 0x07 must not store to it |
| 62 | off | §174, §180 | PTRD-A -- `lo12 == 0x1C0' DOES NOT MOVE THE POINTER |
| 63 | **ON** | §188 | RESTORE THE PAYLOAD'S LSB. `k5-output-stage.md' item 9 and `k3-pointers.md' |

---

## TIER 2 — the section index  (generated from the register headings)

127 sections, §97..§234.  **Read the tail first** — later sections retract earlier ones *in place*.

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
| §140 | OPEN | SPECULATIVE PATTERNS (explicitly not gated; recorded so they accumulate) |  |
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
| §191 | OPEN | the probe reverses the target: `0x921` sits at a CONSTANT pointer, `C63` is the one that varies | §1 both defects **acknowledged**; §2 **MEASURED**, with the vehicle's program |
| §192 | REFUTED/RETRACTED | ⛔ §191 §3's "target reversal" needs a vehicle qualifier. The bit-11 family has NO gradeable test. | §1 **MEASURED**; §2 **FORCED** by §1 (same words, two vehicles, opposite answers); |
| §193 | OPEN | the f31 run is VOID: the navigation vehicle loaded the wrong program. The control caught it. | §1 **MEASURED** (the symptom is diagnostic); §2 **FORCED** by the word sequence |
| §194 | OPEN | the transport is FIXED and §170's map has an off-by-one. The f31 comparison then FAILS its own input control. | §1 **MEASURED** (both arms fingerprinted), the map defect **FORCED** by the +1 on |
| §195 | OPEN | the three-way f31 test also fails: bit identity is confounded with program similarity | §1 **MEASURED** (all three fingerprinted); §2 the pooling **MEASURED** and its |
| §196 | SHIPPED | §114 §3's "the modulus is exactly half" does NOT apply to the shipped build. Measured, no gate. | §1 **FORCED** (the arithmetic); §2 **MEASURED**, with the range agreement as an |
| §197 | SHIPPED | the poke packet's leading nibble is a FLAG, not a constant. Two-character fix, SHIPPED. | the packet form **PROVEN BY CONSTRUCTION** (two notes); the fix's effect |
| §198 | SHIPPED | the three-way PROVEN-BY-CONSTRUCTION audit: four gaps, two note defects, and a correction to §182 | §1 gaps **MEASURED/FORCED** per the linked audits, none implemented here; |
| §199 | REFUTED/RETRACTED | the rotation sign: I nearly refuted a correct finding by checking the wrong quantity | §1 **MEASURED** (the cancellation); §2 **FORCED** (the temporal argument, matching |
| §200 | OPEN | the delay lines have ZERO LENGTH, so the rotation sign is ungradeable. And §199's arithmetic paired the wrong cells. | §1 **MEASURED**; §2 **FORCED** by §189's nine exceptionless pairs; §3 **MEASURED**, |
| §201 | SHIPPED | ★★★ THE DELAY LINES HAVE LENGTH. Per-body descriptor index, SHIPPED ON. | the decode **FORCED** (round5 §1); the consequence **MEASURED**, with §189's |
| §202 | SHIPPED | ★★★ THE ROTATION SWEEPS DOWN, and the proof is the ROM's own numbers. SHIPPED. | **MEASURED**, bit-exact at two lines against an independently-taken dump; the |
| §203 | SHIPPED | `C40.1.80.000` consuming a descriptor cell is INERT by the only instrument that could grade it. Not shipped. | the claim **FORCED** (r3 §6.1, plus the 28 + 4 = 32 arithmetic); the run |
| §204 | SHIPPED | the CONSUMER-TO-CELL census grades §203. It was right. SHIPPED. | the decode **FORCED** (r3 §6.1 + the 28 + 4 = 32 arithmetic); the consequence |
| §205 | OPEN | both standing tasks return NOT-AS-NAMED. One is 93 sections stale; the other is undecidable. | §1 **FORCED** (the datapath) with the corpus census **MEASURED**; §2 the closures |
| §206 | OPEN | the descriptor base is not missing from the emulator; it is absent from `0x825`. Look at `0x827`. | the header values **MEASURED**; "the firmware does not split `0x825`" **FORCED**; |
| §207 | REFUTED/RETRACTED | ⛔ the `dsc` labels are OFF BY ONE, so §202's "bit-exact" numbers were the wrong block. And the answer was written four d | §1 **FORCED** (§204's own output); §2 **FORCED** (the gcd argument, null computed); |
| §208 | SHIPPED | the §204 probe stops printing a DERIVED cell label. Housekeeping, recorded so §209 has a baseline. | **MEASURED** (§204's own output was the proof). |
| §209 | OPEN | ★★★ THE PER-UNIT DESCRIPTOR RING. 16 of 16, all four arms bit-exact, and §202 re-baselined. | the implementation **FORCED within `dram-unit-cursor.md`'s printed model class** |
| §210 | SHIPPED | ⚠ §207 OVER-CORRECTED §202, and §209's measurement shows how far | §209's census **MEASURED** against a pre-registration committed before the build; |
| §211 | REFUTED/RETRACTED | ⛔⛔ THE OUTPUT STAGE IS NOT WHERE THE SILENCE LIVES. `w73` PRESENTS A ZERO IT WAS HANDED, AND `§48` IS NOT A GATE | §1 **MEASURED** against a scoring rule committed before the run, and **exhaustive** |
| §212 | REFUTED/RETRACTED | ⛔ §205's "single number that matters" was WRONG. §48 is not a gate, and §141's `w73` does not hold. | §1 and §2 **MEASURED** (exhaustive over 285 slots; the store witness aimed for the |
| §213 | REFUTED/RETRACTED | ⛔⛔ §211's GRADEABLE LEAD WAS A PROBE ARTEFACT. The input dies at `iw36`, and the SEND is decided by ONE corpus-unique wo | §1 **MEASURED** against four predictions committed before the build, with an exact |
| §214 | REFUTED/RETRACTED | the lead I handed forward was an INSTRUMENT ARTEFACT, and §212 §1 is half-retracted | §1 **FORCED** (the fired-count identity, and the contradiction inside §211's own |
| §215 | REFUTED/RETRACTED | ⛔ THE RIVAL IS REFUTED BY THE CORPUS AND THE FALSIFIERS ALL PASSED ANYWAY. `SRC 0x0B` SURVIVES AT `iw25`, AND THE SEND W | §0 **MEASURED** (corpus census over 41 listings / 3057 words, plus the 1.0064 |
| §216 | REFUTED/RETRACTED | the rival is refuted, my "suspicious loop" is retracted, and the OUTPUT STAGE NULL IS NOW PROVEN BY FEEDING IT | §1 **MEASURED** (41 listings, 13/13, two independent programs); §2 **FORCED** — the |
| §217 | REFUTED/RETRACTED | ⛔★★★ THE `§78` BLOCKER IS REFUTED: THE DATUM IS NOT LOST, IT IS DELIVERED TO `iw98`. The LINE INDEX is a RED HERRING and | §0 **MEASURED** (both censuses are in `src0b2_B_on_215.log.gz`; the boot-sample |
| §218 | REFUTED/RETRACTED | ⛔★★★ THE CROSS-FRAME RIVAL IS REFUTED WITHOUT A RUN, AND `ENSEMBLE w62` IS NOT AN `SRC 0x0B` WORD AT ALL. §217 §5's CENS | §1 **MEASURED** (three existing logs, single-bin histograms, `m_prov_other` |
| §219 | REFUTED/RETRACTED | ⛔★★★ THE SEND'S "GUESSED `SRC`" WAS DECIDED FOUR SECTIONS AGO, AND NO `SRC` ON THE PATH CAN CLOSE THE SEND ANYWAY. THE S | §1 **MEASURED** (corpus, §215/§218) and a documentation correction; §2 **FORCED** |
| §220 | NOT SHIPPED (diagnostic only) | ★★★ THE PICKUP IS DECIDED BY EXPERIMENT: SUPPRESS `iw35`/`iw45` AND BODY 0 RUNS ON LIVE AUDIO, THE DELAY LINE FILLS, AND | §1 **MEASURED** (a parse of the C++, not a grep) with the conditional-print defect |
| §221 | NOT SHIPPED (instrument only) | ★★★ THE EPILOGUE IS EXONERATED BY PROVENANCE, NOT BY LIVENESS: `§E1` RUN ON THE `NOZ05` RIG NAMES EVERY OPERAND'S ARRAY, | §1 **MEASURED**, two arms, against a pre-registration committed before the build, |
| §222 | NOT SHIPPED (instrument + one provably inert unification) | ★★★ `ACT 0x0D`'s DESTINATION IS CLOSED AT `iw205` ITSELF, AND THE FIRST NON-ZERO OUTPUT IN THE PROJECT IS A **RIG RAIL** | §1 **MEASURED EXACT**, three arms, at the site rather than the twin; §2 |
| §223 | SHIPPED (one instrument, one narrower rig, one proven-by-construction fix, one latent runaway) | ★★★ THE RAIL IS **NOT THE RIG'S**: THE SHIPPED BUILD CLIPS **5.303 %** OF EVERY ACCUMULATOR CONVERSION WITH THE INPUT ** | §0 **FORCED** from an archived log, no run; §1 **MEASURED**, three arms, with a |
| §224 | SHIPPED (two read-only instruments, one fully-measured decode arm, DEFAULT OFF on a self-imposed gate) | ★★★ `iw34` IS **ANSWERED**, AND ITS ANSWER KILLS `§223`'s OWN CANDIDATE: `ACT 0x00`'s BUS TERM CANNOT BE THE CAUSE THERE | §1 **FORCED** from an archived log, no run, then **CONFIRMED** by a new |
| §225 | SHIPPED (one default flip on a restated gate that CAN fail, one boot-window instrument, one from-disk result that needed no run) | ★★★ `28/32/28` **SURVIVES, AND THE DISCRIMINATOR IS A PROOF**: `26/28/27` of it is input-dependent by the instrument's o | §1 **FORCED** from 33 archived logs, **no run**, with two controls that use no |
| §226 | NO CHANGE SHIPPED (a from-disk refutation of the pass's own candidate, plus a positive identification that closes a nine-day-old filed open question) | ★★★★ THE HEADER'S COEFFICIENT BANK IS **FOUND**, `headerdecode.md` §7.6 IS **ANSWERED**, AND THE SHIPPED BUILD IS **ALRE | §0/§2/§3 **MEASURED and FORCED**, from two archived captures, the ROM's own |
| §227 | REFUTED/RETRACTED | ★★★★ BOTH HALVES OF §226's PRE-REGISTERED BISECTION ARE **REFUTED**, ONE FROM DISK AND ONE BY A **MEASURED NO-OP**; AND  |  |
| §228 | SHIPPED | ★★★★ THE DSP FRAME CLOCK WAS **48 000 Hz AGAINST AN Fs OF 44 100**, MEASURED FROM DISK BEFORE ANYTHING WAS BUILT (1 440  |  |
| §229 | REFUTED/RETRACTED | ★★★★★ THE REVIEW'S **THREE CHEAP DECODE EXPERIMENTS**, RESOLVED. **TWO WERE REFUTED FROM DISK BEFORE ANY BUILD** (`f98`  |  |
| §230 | CONTROLS REPAIRED | ★★★★ THE PROJECT'S WORST CONTROL IS **REPAIRED AND TWO-SIDED**: SINGLE DELAY's `+0.02149296` NOW **ACCEPTS** THE CORRECT |  |
| §231 | SHIPPED | ★★★★★ `f31 ∈ {3,6,7}` IS **DECODED AS FAR AS IT CAN BE, AND IT IS A DEAD LEVER**: the bit-5 rule is **OFF BY ONE** and a |  |
| §232 | SHIPPED | ★★★★★ THE UNANCHORED `SRC`/`ACTION` CENSUS: **16 CODES ARE CLOSED, 8 STAY OPEN, 9 ARE NOT RESIDENT** — AND §231's OWN FU |  |
| §233 | CONFIRMED 1 of 7 (+ retracts §232 §7.2's PEQ falsifier) | ★★★★★ `SRC 0x00` IS DECIDED **FROM DISK**, AND THE READING THE DEVICE SHIPS **SURVIVES**: SINGLE DELAY's lag-1001 ROM PR |  |
| §234 | CONFIRMED 1 of 49 (+ retracts three-codes.md item A and the lag-1001 criterion's independence from this pair) | ★★★★★ `ACT 0x0D`/`0x0E`: THE SHIPPED PAIR IS **CONFIRMED FROM DISK, 1 of 49** — BY PARAMETRIC EQ's *ENTRY WINDOW*, ONCE  |  |
| §235 | ⛔ REFUTED (both arms) + the family with them | ★★★★★ THE **PRODUCT-REGISTER FAMILY IS DEAD**. `UPD6383_CALLFLUSH` (flush at the block CALL) and `UPD6383_PCLR` (a DRIVEN product register, new, predicted BEFORE the run) both fix the chorus's LFO increment to 114 and both **starve the parametric EQ** — 39 of 44 cells and 105 of 105 rows moving with no flush, 2 cells / 9 rows with the flush, **0 and 0** with PCLR. Clearing §52's cursor seed (`SPEC` bit 12) does the same. FOUR structurally unrelated interventions on ONE trade curve ⇒ **not a retention policy**; do not propose a fifth. N-INPUT-GATE-OPENED §20/§22, `dsp/tools/pair_gate.sh` |  |
| §236 | ⚠ THE CRITERION ITSELF WAS THE BUG | ★★★★★ **`phase = 114` IS A STARVATION SIGNATURE.** Every configuration that empties `P` at the LFO entry word reports it, including ones that leave the EQ bit-identical. A landmark that cannot fail is not a pass (measurement discipline, applied to this project's own headline). The gate now measures **chorus phase + chorus liveness + EQ liveness** at one setting, and **nothing has passed all three**: the only configuration with a live EQ is the one with the wrong phase. N-INPUT-GATE-OPENED §22/§23 |  |
| §237 | ★★ MEASURED (device), 18 of 38 images | ★★★★★ **WHAT ERASES THE EQ IS `iw88`.** `iw86` puts the live pickup in the accumulator (`4 904 681 << 16`) and `iw88` — `f31 = 0`, **no coefficient** — loads the accumulator from a product nothing produced, two words later. Without a flush that stale product is the KERNEL's, itself audio-derived, so the bands keep moving: **the EQ was never fed its own input, it was fed the kernel's residue.** The same body-entry shape is in **18 of 38** images (`entry_erasure_census.py`). Candidate: §138's guard (bit 55), blast radius **35.5 %** of the corpus (`load_nocoef_census.py`). N-INPUT-GATE-OPENED §23/§24 |  |
| §238 | ★ MEASURED (device), from the corpus | ★★★★ **THE DEVICE'S ALGEBRA, EXTRACTED**: `class2_solve.py` states `upd6383.cpp`'s accumulator model as one table over 104 captures — `f31` = LOAD/ACCUMULATE/HOLD in every class, `ACT 0x00` adds the bus **on top of** the `f31` op (442 rows), `ACT 0x0D` replaces the accumulator with the bus even at `f31 = 1`. `--target ta` gives the temp-register writer map: every uniquely determined tempA writer writes the operand latch `L`. ⚠ It measures the EMULATOR; its **VACUOUS** rows are the experiment queue. N-DEVICE-ALGEBRA-EXTRACTED |  |
| §239 | ⛔ REFUTED (alone and in combination) + ⛔ §24 VACUOUS | ★★★★★ **`§138` IS DEAD AND `CALLACC` IS A NO-OP.** Seven configurations on one binary, three criteria each: `UPD6383_CALLACC` is **identical to the baseline** (same chorus increment, same 4/17 and 24/70, same 39/44 and 105/105) ⇒ the accumulator does **not** carry across a block boundary, so there is nothing to clear; `SPEC` bit 55 leaves the EQ **bit-identical** and the chorus increment at 168 353. ★★ MECHANISM, and it is the round's real result: with `iw85`'s LOAD removed the EQ's body entry counts the **same bus datum THREE times** (`ACT 0x0D` loads, `ACT 0x00` adds at `f31 = 1`, adds again at `f31 = 5`) and `iw88`'s store **rails the pickup at `0x7FFFFF`** — *the erasure was also what prevented the triple count*. ⇒ **at most ONE of those three bus readings is right as it stands**; the live question is the BUS TERM, not product lifetime. N-INPUT-GATE-OPENED §27/§28 |  |
| §240 | ★★★ REVERSES §20/§22's INTERPRETATION + locates the gap | ★★★★★ **THE HLE'S OWN CRITERION: the EQ's input is ONE COPY of the pickup** (`pickup_copies.py`, gate criterion **(C)**). Of seven configurations **only `UPD6383_CALLFLUSH=1` delivers it** — **0.999**, vs **1.589** baseline and a **RAILED** 1.610 under bit 55. ⇒ *"CALLFLUSH starves the EQ"* is true as LIVENESS and **false as diagnosis**: the baseline's 39 moving cells were **the kernel's stale product being filtered**, so liveness was **rewarding contamination**. ⛔ never grade an arm on liveness alone. ★★ **The remaining gap is ONE CELL: nothing writes `0x50`**, the band's `x` input — of every row in the frame, both units, exactly two address it and both are READS. NEXT: find `0x50`'s writer with the §109 store probe. N-INPUT-GATE-OPENED §29/§30 |  |
| §241 | ★★★★★ **FIRST FULL PASS** (joint, 2 speculative arms, default-off) | ★★★★★ **`CALLFLUSH` + §109 BIT 28 PASSES ALL FOUR CRITERIA ON BOTH PROGRAMS.** Chorus increment **114** with a live body; EQ **13 of 44 cells / 94 of 105 rows** (was 2/9); and **every one of the five band state blocks — `0x50`/`0x54`/`0x58`/`0x5C`/`0x60`, spaced 4 apart as the decoded topology says — holds exactly ONE COPY of the input** (ratio 1.000), with the filtered `y` histories moving beside them. THE CHANGE: `iw88 = ld.st acc,(p)+64`'s `ACT 0x07` store was aimed at the pointer BEFORE the `+64` (→ `0x10`, which nothing reads); aimed AFTER it lands on `0x50`, which `iw89` reads. Never runnable before because until §29 no configuration put a correct input in the accumulator. ⚠ NEXT: regression over the other programs before promoting out of default-off. N-INPUT-GATE-OPENED §31/§32 |  |
| §242 | ⛔⛔ **RETRACTS §241** + ★★ strengthens §29 | ★★★★★ **THE CHORUS CRITERION COULD NOT FAIL, AND BIT 28 KILLS THE LFO.** The phase cell's WITHIN-FRAME delta reads **114 even when the phase is reset to zero every frame** (`iw89` loads the increment, `iw91` stores it). The device's §119 witness — the phase on **eight consecutive frames** — has been in every capture all along: under `CALLFLUSH + bit 28` it is **`0 0 0 0 0 0 0 0`**, under bit 28 alone **frozen**. ⇒ **NO configuration passes all four criteria**; §241 withdrawn. ★★ But by the eight-frame ramp, **`CALLFLUSH`/`PCLR`/bit 12 give a constant +114 per frame — a correct free-running LFO** — while the baseline wanders, so **two unrelated criteria on two programs now point at `CALLFLUSH`** (§29 + §34). Instrument: `dsp/tools/lfo_ramp_check.py`, runs on any archived capture. ⚠⚠ LESSON, against my own headline: *a criterion must be able to fail in the way the thing fails.* N-INPUT-GATE-OPENED §34 |  |
| §243 | ⛔ DISQUALIFIED ON THE CATALOGUE (10 programs) | ★★★★★ **`CALLFLUSH` + §109 bit 28 FAILS ACROSS THE CATALOGUE**: every modulation program **freezes its LFO at phase 0** (chorus, modulated chorus, flanger, phaser, ensemble) and the **PARAMETRIC EQ gains NINE RAILED CELLS**; the only three that pass are the three with no LFO word and no biquad. ★ Refines §32 rather than erasing it — the five band `x` cells DO each receive one clean copy, and nine OTHER cells rail ⇒ **delivery right, downstream gain too high**. Instruments: `catalogue_regression.sh` + `regression_report.py` (TYPE 0–8 + 15; `TYPE_MAP.md` is off by one above 8). ⚠ The LFO column first fired only when the BASELINE had a ramp to lose — a comparison against a broken reference is not a test — and then over-fired on programs with no LFO word. N-INPUT-GATE-OPENED §35 |  |
| §244 | ★★★★ **PROMOTED TO DEFAULT-ON** (first body-side reading promoted on catalogue evidence) | ★★★★★ **`UPD6383_CALLFLUSH` — the product register does not cross a block CALL — IS NOW THE DEFAULT** (`UPD6383_CALLFLUSH=0` restores the old behaviour). FOUR independent lines: §29 the ONLY configuration delivering **one clean copy** of the EQ's input; §34 the only family giving the chorus a **constant +114/frame** phase on the §119 eight-frame witness; §36 **FIVE** programs gain that ramp (chorus, modulated chorus, flanger, phaser, ensemble), not one; §36 **ZERO regressions over ten programs / four families**, no body dying and no cell railing. Verified two-sided after the change. ⚠⚠ STANDING ARGUMENT AGAINST: the **ENHANCER's products drop 46 → 10 and nothing explains it**. ⚠ The EQ's 100 → 9 is understood (the baseline was filtering the kernel's residue). N-INPUT-GATE-OPENED §36 |  |
| §245 | ★★★★★ **PROMOTED TO DEFAULT-ON** — the body-side input path CLOSED on the reference program | ★★★★★ **`UPD6383_ST07SIGN`: the `ACT 0x07` mode-2 store lands on the POST-increment cell when `addr8 > 0`, PRE otherwise** (`=0` restores the uniform target). Predicted from a MEASURED constraint before the run (§38: the chorus's and EQ's entry stores are the same word but for `addr8`, `−12` vs `+64`, so no uniform target can serve both). §39 all four gate criteria on both references; §40 **ZERO regressions over ten programs isolated against flush-only**, every LFO still +114/frame, ENSEMBLE **loses** a railed cell, FLANGER +1 product, **PARAMETRIC EQ 2→30 cells and 9→90 products**. ⇒ kernel delivers → entry assembles ONE CLEAN COPY → store lands where the first band reads → all five bands filter their own input. ⚠ A hypothesis that SURVIVED, not a derivation. ⚠ ENHANCER unchanged: it has NO `ACT 0x07` store at its entry (§37). N-INPUT-GATE-OPENED §38–§40 |  |
| §246 | ★★★ ROOT CAUSE + a new instrument; UNBLOCKS 28 programs | ★★★★★ **THE DSP EFFECT TYPE LIST HAS 38 ENTRIES (0..37), NOT 36.** That one fact is the root of `TYPE_MAP.md`'s documented off-by-one AND of `type_select.lua`'s wrong `TYPELAST` default. MEASURED by **fingerprinting the uploaded program image** — `dsp/tools/type_fingerprint.py` replays the uC-IF capture into a 384-word I-RAM image and matches **16 words** against the 38 listings (4 words collide for 8 programs). At `TYPELAST=35`, `TYPEIDX` 0 and 15 gave `prog03_enhancer` and `prog50_vibrato`, **exactly two slots high** = `37 − (35 − N)`; at **37 BOTH known-answer controls pass** (`0 → prog01_chorus`, `15 → prog39_parametric_eq`). ⇒ index-addressed experiments across the catalogue are unblocked. ⚠ The map's TABLE is NOT regenerated — fingerprint every run. ⚠ Two practical traps recorded: these scripts print to **stdout/stderr, not `error.log`**, and the panel title read at `0x30AE5` returns garbage in this build. `data/typewalk/TYPE_MAP.md` |  |
| §247 | ★★★★ **THE TYPE MAP IS REBUILT — 38 indices, every one MEASURED** | ★★★★★ Rebuilt from the machine's own uploads (`type_map_rebuild.sh` + `type_fingerprint.py`, 16-word match; all 38 body images are unique on 16 words). **CORRECTIONS: indices 0..19 were ALREADY RIGHT; index 20 is the collapse — TYPE 19 AND 20 BOTH LOAD `prog15_rock_rotary`; 21..35 were shifted down by one; 36/37 were MISSING.** ⇒ the old *"add 1 above index 8"* rule was wrong about WHERE and wrong for 9..19. ⚠ Independently the SELECTOR was wrong — `TYPELAST` 35 for a list of 38 — so **every request through `type_select.lua` before 2026-09-13 landed TWO SLOTS HIGH**; re-check any result measured through it. `fx_ab.lua` steps UP from 0 and is unaffected. ⇒ the 28-program sweep is now a mechanical run. `data/typewalk/TYPE_MAP.md` |  |
| §248 | ★★★ **THE FIRST PER-PROGRAM STATEMENT OF WHERE THE LLE STANDS** | ★★★★★ All 28 remaining TYPE indices swept under the promoted defaults, **every identity fingerprinted from the machine's own upload** (rebuilt map independently confirmed — TYPE 19 and 20 both load `prog15_rock_rotary` here too). **7 LIVE / 16 STATIC WITH AUDIO PRESENT / 5 VOID.** ⇒ the two promoted decodes close the body-side input path on the REFERENCE program and keep the ten earlier programs live, but **16 programs have audio arriving at the kernel and a body that does not move** — that is the remaining body-side work, now NAMED. ⚠ "STATIC" is not "broken by the promoted changes": absolute health check, no baseline. ⚠ 5 VOID = the trace offset puts no audio in the chip for those programs. ⚠ The audio test must be per-program (TYPE 9 carries its input in `0x01`, not `0x05`). ⚠ §193's "fx_ab drops steps at long distances" does NOT survive the map rebuild. N-INPUT-GATE-OPENED §42 |  |
| §249 | ⛔ REFUTED (3rd aim) + ⚠⚠ a METHOD lesson | ★★★★ **`UPD6383_ST2A`** — *`hi12 = 0x02A` with `addr8 != 0` stores the accumulator at the pointer* — predicted from a MEASURED corpus split (9 starved vs 1 live on `addr8 != 0`; **both** EQ instances at `addr8 = 0`, so the control is a corpus property). **REFUTED**: the starved bodies' cell stays **0**, extra products appear and one program gains a **railed cell**. ✅ The control held in all three builds. ⚠⚠ **TWO FALSE NULLS FIRST**: `m_dp + addr8` stored past the target (the walk has already run) and the check inside `case LO_ACT_ST_BUS` never sees an ACT-0x00 word — both with NON-ZERO fired counts. **A null from an arm not proved to fire on the target word is not a refutation; compare FIRED COUNTS between builds** (10 487 → 10 487 → 327 220). N-INPUT-GATE-OPENED §45/§46 |  |
| §250 | ★★ MEASURED, 38 programs | ★★★★★ **THE OUTPUT-STAGE NULL SURVIVES BOTH PROMOTED DECODES** — re-measured with LIVE bodies on all 38: `§70 ACCA AT w73` gives `loud frames … max 0` everywhere. ⇒ *"fix the bodies and the output follows"* is **REFUTED DIRECTLY**; the output stage is an independent problem and the largest unexamined area. ⚠ `§70`'s QUIET column shows `88 235 781 586` on 25 of 38 — a **CONSTANT OF THE IDLE MACHINE** (identical to the last digit across all 25, present PRE-promotion, zero on loud frames). RULE 13; exclude it. N-INPUT-GATE-OPENED §47 |  |
| §251 | ★★ MEASURED + a POSITIVE CONTROL | ★★★★★ **THE 16 STATIC PROGRAMS ARE TWO PROBLEMS.** Census of who writes the body's first-read cell: **7 of 7 LIVE** programs have a **bit-4 store**; **11 static** ones have one too (written with **zero**); only the **5 PEQ combis** have **NO WRITER ANYWHERE**. ⇒ the 11 are starved **UPSTREAM** (they join the ENHANCER, §41) and **the store-target line §43/§45/§46 was aimed at the wrong group**. ★ In live programs the writer sits at/AFTER the read — a **STATE CELL** written in frame N, read at the top of N+1 ⇒ a body only runs once the loop is primed. ★ First **positive control**: 7 live programs any fix must leave untouched. N-INPUT-GATE-OPENED §48 |  |
| §252 | ★★★★★ **38 LIVE / 0 STATIC / 0 VOID** + ⛔⛔ retires §43–§46 | ★★★★★ **EVERY EFFECT PROGRAM RUNS ITS BODY ON LIVE AUDIO** under the promoted defaults. The entire "static" set was a **TRACE-TIMING ARTEFACT**: the first-read cell is a STATE CELL written in frame N and read at the top of N+1 (§48), so a body only runs once its loop is PRIMED, and the sweep traced at note-on +1.0 s. At **+2.5 s (`NOTEOFS`) 16 of 16 come ALIVE**, including the 5 PEQ combis with NO writer for that cell. ⛔⛔ **RETIRES §43/§44/§45/§46 and half of §48** — the `UPD6383_ST2A` arm and its three aiming errors were built to fix programs that were never broken. ✅ §48's STATE-CELL finding survives and is what predicted this. ⚠⚠ METHOD: **exclude a known instrument systematic BEFORE theorising on the measurement** — the same artefact had been caught on 5 other programs earlier in the session. N-INPUT-GATE-OPENED §49/§50 |  |
| §253 | ★★★ MEASURED, 16 programs, LIVE bodies | ★★★★★ **THE OUTPUT-STAGE NULL HAS A MECHANISM: THE EPILOGUE'S POINTER NEVER LEAVES `0x00`.** It addresses **only `0x00` and `0xFF` in ALL 16 programs**, the bodies move a dozen other cells, and the **overlap is 0 of 16**. ⇒ the output stage is **not losing a signal, it is reading somewhere else**; §221's "operands disjoint from the signal path" now has its cause. **The question is the POINTER, not the arithmetic**, with a hard control (zero overlap) and the 38-live tally as the regression bound. ⚠ The epilogue's acc arrives NON-ZERO and dies at `iw65` (LOAD) but is **program-dependent and frame-STATIC** ⇒ NOT audio. ⚠ NOT claimed: that this is a defect rather than the chip's behaviour — delivery may not be through a D-RAM cell. N-INPUT-GATE-OPENED §51 |  |
| §254 | ⛔ REFUTED (2nd time, NEW reason) + ✅ the BOUND caught it | ★★★★ **THE EPILOGUE POINTER REBASE (register row 23) IS DEAD FOR A STRUCTURAL REASON.** Re-tested because its first withdrawal rested on *"the stores still read zero at `0x05`"* — a premise §50 destroyed (`0x05` moves in all 16 programs). Structurally the arm works (`0x00,0xFF` → `0x04,0x05`) but gives **NO overlap in 3 of 4**, leaves the output stage at `loud max 0`, and **BREAKS 3 OF 4 BODIES including the PARAMETRIC EQ** (30 cells → STATIC). ★★ MECHANISM: **`m_dp` is THREADED ACROSS FRAMES** — `run_frame()` resets the PC and nothing else, so forcing the pointer at the epilogue sets where the NEXT frame's kernel walks. ⇒ **the epilogue's `0x00` is the value the previous frame legitimately left; the pointer is an OUTPUT of the frame loop, not an input.** ⛔ Do not re-propose it. ✅ Rejected by a bound fixed BEFORE the run (the 38-live tally). N-INPUT-GATE-OPENED §52/§53 |  |
| §255 | ★★ MEASURED, 16 programs, LIVE bodies | ★★★★★ **THE OUTPUT PROBLEM IS UPSTREAM OF THE EPILOGUE.** `w73` sources **`SRC 0x10` = the ACCUMULATOR** (anchored), not a cell. On the body's LAST executed row: **only 2 of 16** programs leave a frame-VARYING accumulator; **14 leave a CONSTANT**, 8 of them exactly `0`. ⇒ **bodies compute (cells move) and still hand the next stage a constant** — §51's disjoint pointer and §47's `loud max 0` are DOWNSTREAM. ⇒ next question is **per-body and upstream: why does a body whose cells move leave a constant accumulator?** (2 non-constant = positive control; the 8 zeros = sharpest cases). ⚠ A one-program artefact was caught BEFORE being written down: the exciter's acc goes constant at `iw54` (delay-WRITE, `acc ← P`) and that is NOT general across the other 15. N-INPUT-GATE-OPENED §54 |  |
| §256 | ★★★ MEASURED, 16 programs — the strongest cross-program pattern in this area | ★★★★★ **THE OUTPUT ACCUMULATOR IS KILLED BY AN `f31 = 0` LOAD IN 14 OF 14 PROGRAMS THAT LOSE IT** — five different `(class,ACT,SRC)` shapes, 14 programs, and **13 of 14 fetch NO coefficient** (a LOAD from a product nothing produced). The 2 that keep a live accumulator reach the body's END. ★ The body's TERMINAL word does NOT distinguish them (all 16 share `cls1 ACT00 SRC00`; the live exciter's last word is byte-identical to 5 constant programs'). ⚠ **REVIVES §138** (bit 55) which names the killer in 13 of 14 TAILS — but §138 is refuted on 2 programs with a measured harm at the body ENTRY and rewrites 35.5 % of the corpus. ⛔ **Do NOT restrict it to the tail** (fitting the rule to the data). ⇒ **`f31 = 0`'s semantics must be decided from the CORPUS and the HLE, not another arm.** N-INPUT-GATE-OPENED §55 |  |
| §257 | ★★★★ DECODE FROM THE BYTECODE (not fitted) | ★★★★★ **`f31 = 0` IS A MULTIPLY-CLASS SEMANTIC: 213 OF 213.** Every `f31 = 0` word in class A fetches a coefficient (the lone exception is a **C-format** word excluded by definition); in the non-multiply classes the encoding is everywhere (90 % of cls 0, 90 % of cls 1, 97 % of cls 3, 98 % of cls 6) and **never** fetches one. ⇒ *"acc ← P"* is well-defined **exactly where a product is produced in the same instruction**; the device applies it to BOTH populations and on the others loads a register nothing wrote — which is §256's 14-of-14 killer. ★ Derived from the CORPUS without looking at which programs fail, so it EXPLAINS §256 rather than being fitted to it. ⚠ Does NOT establish what `f31 = 0` means on a non-multiply word (HOLD is a candidate, not a conclusion) and is NOT an argument for flipping bit 55, whose blanket form has a measured harm at the body entry. N-DEVICE-ALGEBRA-EXTRACTED §13 |  |
| §258 | ★★★★ THE COVERAGE ROADMAP (no family promoted) | ★★★★★ **THE UNDECODED MASS IS CONCENTRATED AND HALF-ANSWERED.** By OCCURRENCE: **1 740 undecoded occurrences in 133 families; the 18 largest are 49.9 %**. Cross-referenced against the extracted algebra, **15 of 18 already carry a uniquely-determined accumulator op** (several on **48–53 programs**, fully discriminating) — **81 %** of the top-18's occurrences, **~40 %** of the whole undecoded mass. ⛔⛔ **NOT 40 % of a decode**: the extractor measures the **DEVICE** (promoting it = encoding our emulator's speculation as truth) and an accumulator op is only PART of a word (`decoded()` needs store/pointer/source/destination too). ⇒ next unit of work is **per family, top down: run its programs through the HLE and confirm or refute**. N-COVERAGE-WORKLIST-2026-09-13 |  |
| §259 | ★★★★★ **THE COVERAGE NUMBER RE-FRAMED** (no code anchored) | ★★★★★ **41.5 % COUNTS OPEN AXES, NOT UNKNOWN INSTRUCTIONS.** `alu_decoded()` needs EVERY axis, so a word with six settled and one open counts like one nobody understands. Of **1 740** undecoded occurrences, **52 % are refused for exactly ONE reason**. ★★★ LEVERAGE (sole reason): **`SRC 0x00` 310**, `ACT 0x0D` 123, `ACT 0x0E` 110, `f31=2` off cls8 72, class 1 69, then `SRC 0x11`/`0x1C`/`0x08`, `ACT 0x0B`/`0x1A`/`0x08`, `f31=4` ⇒ **twelve single decisions unblock 869 of 1 740 (50 %) BY THEMSELVES.** ⚠ "Unblock" = the predicate stops refusing, NOT that we know what the code does — each anchor needs the ORACLE, and several already carry committed SPECULATIVE readings behind mask bits, so anchoring = deciding between those and the measurements. ⇒ queue: `SRC 0x00`, `ACT 0x0D`, `ACT 0x0E`, `f31=2` off cls8, class 1. N-COVERAGE-WORKLIST §6 |  |
| §260 | ⛔ THE TOP QUEUE ITEM DOES NOT CLOSE + ⚠⚠ a self-correction | ★★★★ **`SRC 0x00` HAS AT LEAST THREE POPULATIONS AND CANNOT BE ANCHORED ON THIS EVIDENCE.** Over all 1 433 of its rows: **class A `f98 = 1`** (exactly §148's stated population) is the **COEFFICIENT 20/20**, memory operand **0/20** ⇒ the two rival readings **PARTITION rather than compete** (⚠ circular on content — the device ships §148 — but it confirms the POPULATION restriction). The rest: `mem[N−1]` explains 74 %, but **356 matches are trivially zero==zero** and the **307-row residue concentrates 232 in `hi12=000 cls2`**. ⇒ work = **separate the populations, then anchor each**; `000/cls2` is the first sub-question. ⚠⚠ CORRECTION: §5's *"51 of 51"* is true **of ONE FAMILY** and says nothing about the CODE — **never promote a per-family measurement to a per-code anchor** (same error class as §43–§46). N-COVERAGE-WORKLIST §7 |  |
| §261 | ★★ SUB-QUESTION WORKED (nothing anchored) | ★★★★ **THE `000/cls2` RESIDUE IS A HELD OPERAND LATCH.** All **232** residue rows have `L == L[N−1]` and all carry `ACT 0x00` ⇒ `SRC 0x00` sources NOTHING there; the latch keeps what the previous word left and `ACT 0x00`'s bus term re-uses it (which is why they looked like a residue — tested against `mem[N−1]`, a value they never load). Whole shape, adjacency verified, 0 skipped: **held 347 of 363 (95.6 %), loaded 16**, concentrated at `iw119` and unit-1 `iw213`. ⛔ **`addr8` does NOT discriminate** (`0x01`/`0xBA`/`0xFF` in BOTH columns; `0xBA` 3 held / 13 loaded). ⇒ next, bounded: **what makes 16 of 363 identical words LOAD when 347 HOLD?** — not the pointer field; candidates are the unit, the preceding word, or an unprinted field. ⚠ **A 95.6 % rule is not a decode.** N-COVERAGE-WORKLIST §8 |  |
| §262 | ⛔ two more discriminators refuted + ★★ a NECESSARY CONDITION | ★★★★ **THE 16 LOADS ARE CONCENTRATED.** Neither the **UNIT** (u0 40/3, u1 307/13) nor the preceding word's `(class,ACT)` **fully** discriminates hold from load — but **every one of the 16 loads follows either the class-A MULTIPLY (`ACT 0x15`, 14/16) or a `cls1 ACT 0x07` (2/16)**, and **327 of the 347 holds follow a word that NEVER precedes a load** (`cls2 ACT00` 148/0, `clsA ACT0B` 144/0, `cls1 ACT0B` 16/0, `cls6 ACT07` 16/0). ⇒ **MEASURED NECESSARY CONDITION: the latch is only reloaded when the previous word was a MULTIPLY or an `ACT 0x07`** — not sufficient, but it kills 5 of 7 contexts and **cuts the open set 363 → 36**. ⇒ live candidate = **a field the trace does not print** (the multiply's pipeline state); ⚠ **needs a NEW TRACE COLUMN, not an arm.** N-COVERAGE-WORKLIST §9 |  |
| §263 | ✅✅ **CLOSED BY AN OBSERVATION, NOT AN ARM** + ★★ a method rule | ★★★★★ **THE `LW` TRACE COLUMN CLOSES §261/§262.** New read-only column (set where `m_last_l` is finalised, reset per word, printed `W`/`.`; **no behaviour change, ships unconditionally**): **the operand latch changes IF AND ONLY IF the word drove it — 57 of 57 undriven rows HOLD, ZERO exceptions.** ⇒ the *"95.6 % held / 16 loaded"* split was **ONE behaviour seen through a MISSING COLUMN**, not two. `addr8`, the unit and the preceding word were refuted because **none was the variable**. ★★ **METHOD: when successive plausible discriminators all fail, SUSPECT THE INSTRUMENT before inventing a fourth candidate.** ⚠ Does NOT anchor `SRC 0x00`; it deletes a spurious sub-question and returns the work to §260's real partition. N-COVERAGE-WORKLIST §10 |  |
| §264 | ⛔⛔ **A SHIPPED REGRESSION, FOUND AND REVERTED** + ★★★ a new RULE | ★★★★★ **BOTH PROMOTIONS ARE BACK TO DEFAULT-OFF.** They were validated with `SPEC=B9108446A39B440F` (**`ACT 0x0E` selector 4**); the device's own default `0xb910e446a39b440f` is **selector 7**, and **the shipped combination was never tested**. At it the pair **ADDS 6 RAILED CELLS to the PARAMETRIC EQ** (pre-session 22/59/**0** → shipped 24/105/**6**). Revert verified to restore the prior default **exactly**. §36/§40's evidence stands but is **CONDITIONAL ON SELECTOR 4** ⇒ reconciling the `ACT 0x0E` selector (§234) is a **prerequisite** for re-promotion. ★★★ **RULE (beside RULE 12/13): BEFORE PROMOTING ANYTHING, RE-RUN THE ACCEPTANCE TEST WITH NO ENVIRONMENT SET AT ALL.** ⚠ A two-sided gate, a 10-program regression, a pre-registered bound and a fingerprint check all WORKED — their INPUT was wrong. N-INPUT-GATE-OPENED §56 |  |
| §265 | ★★★★★ **THE ORACLE INVERTS §241/§245** — the EQ is a CASCADE | ★★★★★ **`dsp/hle/effects.py`'s `parametric_eq` is a SERIES of biquads** (`y` feeds forward) ⇒ **exactly ONE band — the first — should receive a clean copy of the input.** One-copy criterion over the selector × arms 2×2: **sel 7 (SHIPPED) + arms OFF gives ONE COPY at `0x50` ONLY — it MATCHES THE ORACLE**; sel 4 + arms gives one copy at ALL FIVE = **PARALLEL, the WRONG topology**; sel 7 + arms RAILS; sel 4 alone is contaminated. ⛔⛔ **RETRACTS §32's headline** (*"every band receives one copy"* was a DEFECT description) and **INVERTS §40/§245's central evidence**. ✅ §29's criterion stands but must be applied **PER TOPOLOGY** (first stage of a cascade, not everywhere). ⚠ §36's CALLFLUSH chorus evidence untouched. ⇒ **`ACT 0x0E` = selector 7 as shipped, for the EQ**; re-read §234 beside it. ★★★ METHOD: **consult the ORACLE BEFORE applying a criterion, not after promoting.** N-INPUT-GATE-OPENED §58 |  |
| §266 | ★★★★★ **`ACT 0x0E` CLOSED FOR THE EQ (2 independent routes)** + ⛔⛔ a process failure | ★★★★★ **SELECTOR 7, AS SHIPPED.** §234 confirmed it **FROM DISK, 1 of 49** (EQ entry window vs the designer's biquad, junk-pre-load control kills the runner-up); §58 reached the same answer **FROM THE ORACLE** (the HLE's `parametric_eq` is a SERIES CASCADE ⇒ only the FIRST band may receive the input). Different instruments, same result ⇒ the three contradictory committed readings are **reconciled in favour of the shipped `P ← bus`**. ⛔⛔ **PROCESS FAILURE:** every gate run, catalogue regression and promotion this session used `SPEC=B9108446A39B440F` — **selector 4, which §234 had already ruled out** — and TIER 0a is titled *"READ THIS BEFORE … RE-OPENING `ACT 0x0D`/`0x0E`"*. ⇒ **§264's regression and §265's inversion have ONE root cause: a settled result was not consulted.** ⚠ Re-read everything measured at selector 4 as measured on a REFUTED configuration; §252's *38 live* needs re-measuring at selector 7. N-INPUT-GATE-OPENED §59 |  |
| §267 | ★★★ **`f31` IS AN ACTIVELY CHOSEN FIELD, and the ISA splits on `hi12` BIT 5** | ★★★ §55 asked for `f31 = 0`'s semantics *"from the corpus and the HLE"*. **Corpus half, done statically, no emulator, no circularity** (`dsp/tools/f31_activity.py`). ⛔ **"hi12[3:1] is a don't-care on non-multiply words" is REFUTED by a MINIMAL-PAIR test** — same word in every other bit, different `f31`: **12 shapes** among non-coefficient words (positive control: **6** among coefficient-fetching, so the instrument fires); `0100200000` is written **35× ADD / 23× HOLD**. ⇒ **§55's output-killing LOADs are DELIBERATE.** ★★★ And the corpus is **two populations**: `hi12` bit 5 CLEAR ⇒ **98.9 %** of 2 885 words use only `f31 ∈ {0,1,2}`; bit 5 SET ⇒ **75 %** of 172 use `f31 ∈ {3..7}`, which **the device collapses into ONE behaviour**. ⛔ Refuted on the spot: "bit 5 = terminator" (17 of 40; 8 programs have none). N-INPUT-GATE-OPENED §63 |  |
| §268 | ★★★ **WHERE THE COLLAPSE IS OBSERVABLE — read before aiming anything at bit 5** | ★★★ A bit-5 word whose **next** instruction is an `f31 = 0` LOAD has its only effect overwritten one slot later. **96 of 172 sites are BLIND, 59 LIVE, 41 of those carry a high code.** Measured at the EQ's `iw87` at the **true default, no environment set**: it adds `421 845 467 136` and `iw88` discards the whole accumulator (it comes out exactly `P`). ⇒ **aim only at the live 41** — `prog36_compressor`, `prog05_phaser` w9/w68, `prog06_ensemble` w14/24/34/72/82/92, `prog15_rock_rotary` w5, **the `epilogue`**; a run sampling the blind 96 returns a **false null** (the §46 failure mode, now predictable in advance). ★ Also: **`iw73`, the presentation word, is a bit-5 word** — ⚠ its `f31` is in the decoded low set, so this does **not** move §54's "the failure is upstream". N-INPUT-GATE-OPENED §64/§65 |  |
| §269 | ⛔⛔ **A REFUTATION OF MINE, RETRACTED — the control was already characterised** + ★ a RULE | ★★★★ bit 5 tracks the decoded dynamics families **hugely**: the **8 pure delay/modulation networks carry ZERO** bit-5 words in 586 words where uniformity predicts **33** (`P ≈ 1.8e-15`), and **all four** of `families.md`'s LEVEL-DETECTOR programs are above the corpus rate (compressor 30 %, auto wah 12.5 %, no operation 10.2 %, enhancer 8.1 %; 34 observed vs 14.6 expected). The longest program in the corpus is one of the zeroes, killing the length confound. ⛔⛔ **I refuted this with `prog00_no_operation` as the control — and `dsp/algorithms/families.md` already classifies it as one of the four detector programs** on independent coefficient evidence, saying *"NO OPERATION is not empty: it is a dry pass-through that still runs that level detector"*. ⇒ ★ **RULE: before using a program as a control, read what the decode already says it does.** ⛔ Separately, the **mechanism** is refuted with a calibrated null: bit-5 words sit **2–3× FURTHER** from the control bus (`SRC 0x1C`) than an average word (±3: 4.1 % vs 10.9 %) ⇒ the association is at **PROGRAM** level, not SITE level. N-INPUT-GATE-OPENED §66 |  |
| §270 | ★★★★★ **THE SITE-LEVEL MECHANISM: the bit-5 word HEADS the 2/π LEVEL DETECTOR** | ★★★★★ Found by looking up a constant, not by running anything. `0x517CC1` = `floor(2/π × 2²³)` **exactly**, 2/π being **the mean of a RECTIFIED sine**; `programs.tsv` calls it *"2/pi env"* in the ROM's own role table. Its byte-identical idiom occurs **12 times in 8 images**, every one a detector program, and **11 of the 12 are HEADED BY A BIT-5 WORD**, `f31 = 3` (×8) or `7` (×3), **never a low code** (`dsp/tools/detector_idiom.py`). ⇒ this **explains §269's anti-correlation** rather than contradicting it: the idiom **produces** the envelope, `SRC 0x1C` **carries** it elsewhere, so they must not be adjacent. ⛔ Falsifier kept: `prog08_gated_reverb` w80 is headed by a bit-5-CLEAR word — 11/12. ⚠ **INFERRED, not anchored**: the detector must rectify and the head is the idiom's only unaccounted slot ⇒ bit 5 + `f31 ∈ {3,7}` **plausibly the RECTIFIER**; rivals alive (rectification in the source encoding, or upstream). ⚠ A **6 % foothold** — 11 of 172. N-INPUT-GATE-OPENED §67 |  |
| §271 | ★★★★★ **THE BYTECODE CORRECTS THE HLE — the compressor's detector is a RECTIFIER, not square-law** | ★★★★★ The standing goal's *"there may even be mistakes on the HLE version"* paid out. `kn5000_tonegen.cpp`'s DSPHLE compressor **and its archived documentation page** said *"square-law detector"*, with an attack through an invented map and a **release FIXED at 150 ms** while `C-RAM[0x03]` went unread. The ROM contradicts **all three**: `C-RAM[0x00] = 0x517CC1 = 2/π` is the **mean-absolute** calibration (RMS would need `1/√2`, **absent from the ROM**); `C-RAM[0x02] = 0.004812 → 4.712 ms`; `C-RAM[0x03] = 0.001927 → 11.764 ms`, **uploaded**, hence the panel's `RELEASE SENS.(s)`. ★ Second leg: `SQUARING-MULTIPLY_findings.md` adjudicated **every** squaring in the corpus as **coefficient × coefficient** ⇒ **no `x·x` of the SIGNAL in 3 057 words**, so square-law had no mechanism in the ISA. ★ Size: the shipped detector took **22× longer to let go** (350.7 ms vs 15.9 ms). ✅ Fixed, compiles clean, **A/B'd in the emulator WITH A NULL** (arms bit-identical at 30–35 s, apart by rms 1 639 at 40–45 s, peak 27 067/32 767 — not railed). ✅ Docs regenerated, permanence still **24 pages / 46 blocks byte-identical**. ⛔ **GAIN LAW deliberately UNCHANGED** — the corpus only rules out a comparator. ✅ `dsp/hle/` now has the dynamics family at all (`LevelDetector` from ROM `0x84CD`, `compressor`, `auto_wah`). N-INPUT-GATE-OPENED §68 |  |
| §272 | ★★★★★ **THE INPUT PICKUP IS RAILED FOR A WHOLE FAMILY — and `NO OPERATION` is one** | ★★★★★ **4 of 4** decoded LEVEL-DETECTOR programs rail cell `0x05` at the **TRUE DEFAULT** (enhancer +rail, compressor −rail, **no_operation −rail**, auto_wah +rail; `dsp/tools/pickup_cells.py`, identities fingerprinted). ★★★★ **`prog00_no_operation` settles that it is OUR defect** — a dry pass-through cannot saturate its own input. **9 of 9** body reads of the cell are railed; the value is **constant across a frame pair** ⇒ those bodies CANNOT move (this is §61's "genuinely STATIC", **family-wide**). ⛔⛔ **RETRACTS this session's own opening commit** (*"prog32_distortion specifically, not the dynamics family"*), which rested on a sample containing **no standalone dynamics program but the distortion**. ★★★ **NOT an input sample**: the device's input-stage audit peaks at **2 420 992**, never within 3.5× of the rail. Localised to **`iw45` = `0010A0020C`** (class A, `ACT 0x0C`, `SRC 0x08`, `f31 = 0`, **bit-4 STORE**): the accumulator arrives at **−791 648 272 384** (datum **1.44× past the rail**) so the store's deliberate clamp writes `0x800000`; the flanger's same word stores 2 824 201 and does not clamp. ⛔ The **unseeded cursor base** (`cur = 0x9B`, SQUARING-MULTIPLY item F) is **CONFIRMED PRESENT but REFUTED as the discriminator** — identical in a railing and a non-railing program. N-INPUT-GATE-OPENED §70 |  |
| §273 | ★★★★★ **THE 2×2: the rail is an INTERACTION, and the ARM WAS HIDING IT** | ★★★★★ Program and trace instant held fixed, **only the machine changed** (`dsp/tools/pshift_2x2.sh`): **NO OPERATION** rails at the true default (`−8 388 608`) and is **ok with `PSHIFT=2`** (`−185`); the **FLANGER** is ok both ways (517 549 / 2 912 280). ⇒ ⛔ **not the program family** (NO OP un-rails), ⛔ **not the arm** (the flanger never rails) ⇒ ★★★ **the datum scale (total shift 22 vs 23) is NECESSARY but NOT SUFFICIENT**. ★ Internal null HELD: `0x01`/`0x04` byte-identical across the arm. ⇒ ★★ **the earlier 14-program census was taken at total 23 — the arm was hiding the defect in every program it measured**, and pooling the two censuses would have credited the FAMILY with what belongs to the ARM (§229's trap, caught before publication). ⚠⚠ **`PSHIFT=2` IS NOT PROPOSED AS A FIX**: un-railed, NO OPERATION's pickup is **−185** against inputs of 2 420 992 — still broken, quietly — and that arm is §227's two-sided control, contradicting the MEASURED Q1.22 scale. ⇒ the open question is **why the kernel accumulator arrives at `iw45` 4× larger in the detector programs**. N-INPUT-GATE-OPENED §70 |  |
| §274 | ⛔ **`NOZ05` REFUTED (pre-registered) — and it corrects what cell `0x05` IS** | ⛔ `UPD6383_NOZ05=1` suppresses every kernel-A store to cell `0x05` (fired: `iw9:1 722 190 iw35/45:1 722 183`). **P1 FAILS** — the cell stays RAILED, only flipping sign (`−8 388 608` → `+8 388 607`); **P3 FAILS**. ✅ **P4 internal null HELD** (`0x01`/`0x04` unchanged) and ✅ **C1 control HELD** (flanger identical) ⇒ the refutation is the ARM's, not the instrument's. ★★★ **What it revealed is worth more than a pass**: with those stores suppressed the cell **NEVER CHANGES for the whole frame** ⇒ they are its **ONLY writer**, so suppressing them **STARVES** it — the exact failure mode the pre-registration named. ⛔⛔ **CORRECTS THE WORD "PICKUP"** in §62/§70: the device's own audit says DI1 latches to **cells `0x01`/`0x04`**, which are sample-like in EVERY capture ⇒ **`0x05` is the kernel's HAND-OFF of the assembled input to the body, not the deposit** ⇒ the defect is the kernel's **ASSEMBLY** (`iw2`…`iw45`), not a saturated input arriving. `data/PREDICT_NOZ05_2026-09-13.md`. N-INPUT-GATE-OPENED §71 |  |
| §275 | ★★★★★ **DECONTAMINATED: NOT THE FAMILY — 7 OF 8 PROGRAMS GET A BROKEN HAND-OFF** | ★★★★★ §71 found the confound (§70's four railing programs were traced LATER in the note and were simply LOUDER). Decontamination = three **NON-detector** programs at the true default in the same input band. **8 programs, ONE machine, device default** (`data/handoff_cell_2026-09-13.txt`): **6 RAILED, 1 ZERO (`prog06_ensemble`, driven to 0 by the same `iw45`), 1 HEALTHY (`prog04_flanger`)**. ⛔⛔ **§70's "detector family" attribution REFUTED**: `prog10_multi_tap_delay` and `prog56_mix_up` have **no detector at all** and rail at inputs (162k/158k) **BELOW** the enhancer's 307k. ★ The input ARRIVES INTACT in all 8 (`0x01`/`0x04` sample-like everywhere). ⇒ ★★ **vindicates §62's ORIGINAL scale reading**, which this session's opening commit narrowed away and §70 mis-attributed — **two retractions of mine, each because its sample could not see the alternative**. ⛔⛔⛔ **WHY NOBODY SAW IT: every previous census carried `UPD6383_PSHIFT=2`** (total 23, datum HALVED), passed by `catalogue_regression.sh` as a *"baseline arm … NOT optional"* — **an arm adopted because it made things work was hiding the project's largest input-path defect**. The harness now warns at the top. ⇒ **§54/§55's "14 of 16 bodies leave a constant accumulator" was measuring the CONSEQUENCE**; §64/§69's bit-5 probe sites are **ungradeable until this is fixed**. ⚠ `PSHIFT=2` is NOT the fix (§227's two-sided control, contradicts the MEASURED Q1.22 scale). N-INPUT-GATE-OPENED §72 |  |
| §276 | ★★★★★ **THE INPUT-STAGE DEFECT IS NAMED — `iw25` — AND A PRE-REGISTERED DECODE RIVAL FIXES IT** | ★★★★★ **MATCHED PAIR** (`prog06_ensemble` input 152 576 → hand-off **0**; `prog56_mix_up` 157 952 → **RAILED**; same machine, **3.5 %** apart, opposite failures, byte-identical shared kernel) localises BOTH to **`iw25` = `00002002D9`** (`ACT 0x19`, `SRC 0x0B`): `iw7` puts a real sample in **tempA** (−23 296 / 188 160 / −14 848) and **`iw25` overwrites it with 0 / −8 388 608 / +8 388 352**; `iw39` (`SRC 0x19` = tempA, ANCHORED) reads the garbage, `iw40` multiplies, `iw45` stores it into the hand-off cell. ⇒ **zero and rail are ONE defect.** ★ `iw25` is **class 2 — NOT a delay word** — exactly the case the COMMITTED rival `UPD6383_SRC0B2` covers (*"on a word with no delay access `SRC 0x0B` is `mem[ptr]`"*). **PRE-REGISTERED, 5 of 5 PASS** (`data/PREDICT_SRC0B2_2026-09-13.md`): P1 tempA sample-like, P2 mix_up **−8 388 608 → +263 946**, P3 ensemble **0 → −12 903**, P4 internal null `0x01`/`0x04` unchanged, C1 flanger unharmed; **stable across the frame pair**. ★★★★★ **P1 IS SEMANTIC**: tempA's new values are **EXACTLY each program's own cell `0x04`, the DI1 input latch** ⇒ the rival makes `iw25` read **the input**, the shipped reading made it read a **stale delay register**. ⚠ **NOT PROMOTED**: one site is not the 1 610-word `SRC 0x0B` population; **`prog04_flanger` is UNCHANGED and still climbs (2 912 280 → 8 081 098)** ⇒ a **SECOND path to full scale** exists — which also **corrects §72**: the flanger was never healthy, it latches up more slowly, so the true count is **8 of 8**. Promotion needs the catalogue regression **at the true default**. N-INPUT-GATE-OPENED §73 |  |
| §277 | ★★★★★ **PROMOTED TO DEFAULT-ON: `SRC 0x0B` on a NON-DELAY word is `mem[ptr]`** | ★★★★★ **`UPD6383_SRC0B2` default 0 → 1** (control: `=0`). **GATE**: 8 programs / 3 families / ONE binary / both arms / **TRUE DEVICE DEFAULT** (the first catalogue sweep ever taken there — every earlier one carried `PSHIFT=2`, which halves the datum and **was hiding this**), graded on the hand-off cell **as the frame leaves it**: **FIXED 8 · KEPT 0 · STILL 0 · BROKEN 0** (`dsp/tools/src0b2_regression.py`, `data/src0b2_gate_2026-09-13.txt`). Chorus `0→113 541`, enhancer `8 388 607→145 244`, flanger `8 388 607→−21 382`, ensemble `0→−33 547`, multitap/compressor/no-op/mixup all `±8 388 608 →` 10⁵-order samples. ★★ **BLAST RADIUS measured BEFORE promoting** (the test §138 was refused by): **7 words of 3 057 = 0.23 %**, **2 shapes**, both exercised by the gate; the **99 class-1 delay words are untouched in both arms**. ⛔ **Corrects my own pre-registration**, which cited a 1 610-word population for `SRC 0x0B` — that is `SRC 0x00`'s; `SRC 0x0B` spans **106**. ★★★ **SEMANTIC confirmation**: `iw25` now loads tempA with **EXACTLY each program's own DI1 input-latch cell `0x04`** — the input stage reads the input, where the shipped reading read a leftover. ✅ **§56 RULE APPLIED**: re-verified with **NO `UPD6383_*` set at all** — `prog00_no_operation` `0x05` **−8 388 608 → −239 616**, latches unchanged, and `0x05` **drops out of the `§S1C` top-6**. ⚠ **NOT "the DSP works"**: a hand-off is a precondition, not audio; **§75's machine-wide saturation STANDS** (cell `0x06` at **56 %**, cell `0x07` at 7.2 %); no hardware has been heard. ⇒ **§54/§55's "14 of 16 bodies leave a constant accumulator" was measuring the CONSEQUENCE and must be re-run.** N-INPUT-GATE-OPENED §76 |  |
| §278 | ★★★★★ **THE HLE ORACLE MEETS THE LLE — 5 bands live, CASCADE cross-validated 4/4** + ⛔ I had broken the oracle | ⛔⛔ **`dsp/hle/lle_trace_diff.py` WAS SILENTLY BROKEN BY MY OWN `LW` COLUMN (§10)**: its row parser anchored on `L` being the LAST column, so it parsed **zero rows** and reported *"0 informative words / the frame carried little signal"* — a NULL's vocabulary for a READ FAILURE. The project's stated HLE→LLE method was unusable for as long as nobody ran it on a fresh capture. ⇒ ★ **RULE: never anchor a trace parser on the last column.** Fixed to tolerate trailing fields. ✅ **THE CONFRONTATION** (EQ at the TRUE DEFAULT with §76's promotion in; hand-off leaves as 56 033): **all 5 bands `signal: YES`** — before §76 the body was fed a rail and none could carry one. Coefficients: coherent 5-band peaking family, `b0` constant **+0.2500**, recursive pair **PRE-NEGATED** as `algorithms/N-SINGLE-DELAY-RECURRENCE-2026-09-12.md §10` documents, poles **0.9954 → 0.8967**. ★★★★★ **TOPOLOGY CROSS-VALIDATED**: band *k*'s FIRST operand is a state cell of band *k−1* — `0x51/0x55/0x59/0x5D`, **4 of 4** — and band 0 alone opens outside the chain (`0x64`, where the input enters). §58 derived the SERIES CASCADE from the HLE's `effects.py`; this reads it from the chip's own `m_dp` walk. **Two independent derivations, one answer.** ✅ Accumulator op confirmed **on live audio** (36 informative words, was 0): `f31 0` LOAD **19:1**, `1` ACC, `2` unchanged; `3/4/5` still OPEN. ⚠ **NOT yet checked sample-for-sample** — topology/coefficients/signal/op are cross-validated, the ARITHMETIC is not; the default-mode `cur 0x60..0x64 MISSING` is a cursor-base parameter mismatch, not a divergence. `data/eq_oracle_confront_2026-09-13.txt`. N-INPUT-GATE-OPENED §77 |  |
| §279 | ★★ **COVERAGE 74.0 % → 75.0 % WITHOUT DECODING ANYTHING** | ★★ `dsp/tools/acc_blind.py`. Two of the biggest open axes disagree ONLY about a value in the accumulator (`f31 > 2`: four enumerated readings; the store gate at `f31 1`: 17 928 survivors, **0 write `mem[ptr]`**, and `gate_settle.py:70` declares the `else` key unreadable BY CONSTRUCTION). Where the image destroys that accumulator unread, every surviving reading executes the word IDENTICALLY ⇒ **32 words become EXECUTABLE with the axis still unknown**, as TIER 1b (per-SITE, kept out of the per-word `decoded()` the MAME disassembler mirrors). ★ WITH ITS CONTROL: a discarded accumulator looks like dead work, so measure the rate where the op is NOT in question — **anchored 24.4 %, open 24.4 %**, identical to three digits. Extended to the operand bus: an open `SRC` taints the PRODUCT first (`P[N] = coef[N-1] × L[N-1]`), so an `f31 0` reload at i+1 **LOADS** the taint rather than killing it. N-INPUT-GATE-OPENED §95/§96 |  |
| §280 | ⛔⛔ **§168 WAS VOID — the arm could not reach the word it was aimed at** | ⛔⛔ Re-ran SPEC bit 18 at the corrected default, predictions committed first (`data/PREDICT_SRC11_MEM_2026-09-13.md`): gate **FIRED 12 760 530**, and `m_tb`/`m_dp`/`cursor`/`L`/`acc`/cell `0x0C` all **BIT-IDENTICAL** to the control. `C63` carries lo12 bit 11 ⇒ `exec_alu()` RETURNS at the alternate-encoding branch before the SOURCE switch — new **§97 SWALLOW CENSUS** measures it leaving there **3 150 504×/run, twice a frame**. ★★ **A FIRED-COUNT PROVES THE ARM RAN SOMEWHERE, NOT THAT IT RAN AT THE SITE THE CONCLUSION IS ABOUT** (§116 hit this on `0x827` and caught it with a per-site count). ⇒ §166 §3's index register is RETRACTED (it reads `SRC`/`ACT` out of a word that has neither field); §166 §2's 53/53 bijection STANDS. **NEXT for those 159 words: the bit-11 encoding, not another SOURCE reading.** N-INPUT-GATE-OPENED §97 |  |
| §281 | ★ **`addr8` is read by NOTHING on 53 words — and the first version of this said 150** | ★ `dsp/tools/addr8_usage.py`. NULL from class 0, the one class with both kinds: `addr8 != 0` in **9 of 9** register loads (payload), `== 0` in **100 of 100** without a use — exceptionless. Against it, classes 4/6/8 are non-zero in **150 of 150** and unread; zero-rate says INDEX (classes 1/9: 0 of 328) not DELTA (2/A: 46.5 %), and `closure_pointer.py` V7–V11 add those classes to the walk — none closes, all RAISE the u0 pool heterogeneity 8 → 10/15/12/21. ⚠⚠ **THEN THE CONTROL CUT IT TO 53**: never-zero ≠ informative. class 4 holds ONE value in 53, class 8 ONE value in 42 body words ⇒ they select nothing, and PEQ's ten class-8 words are byte-identical while the biquad matches its designer to **0.198 dB** with `addr8` unread. I had drafted a 36-word demotion; it does not stand and the number is unchanged. SURVIVES: **53 class-6 words, five values, varying INSIDE one program, read by nothing** — the idiom's second word. N-INPUT-GATE-OPENED §98 |  |
| §282 | ⚠ **RULE 13 one level up: the cell that "came alive" is the idiom writing to itself** | ⚠ §97 re-opened §168 partly because cell `0x0C` had started moving (`-17..+19`, chg 19 520) — *"the shape of a table index"*. The frame trace puts the idiom's two chorus instances at `dp 0x0C` / `0x0E` and the write census reports **`0C: 144162/3252070`** — ~2 writes a frame, one of them the idiom's OWN class-4 store. **The value is a fixed point of our own undecoded execution.** Strengthens §97 (the thread was chasing our output) and corrects §97's framing in place; the pre-registration keeps its original wording. ⚠ Also: the chorus's two modulated taps read cells holding **0** and **39 718** while live audio cells run to ±2.9 M — **they are not reading the delay line.** N-INPUT-GATE-OPENED §99 |  |
| §283 | ★ **MIRRORS AGREE AGAIN — 3057/3057**, after four silent drifts | ★ `tools/upd6383d_diff.sh` had not been run since the delay escape became executable and was failing on FOUR shapes: two rows rendering `ld.ta2 ?` against Python's `dly.w dsc[k],p+96` (the pass that made the escape executable mirrored the PREDICATE and not the RENDERING), the wrap word with the same gap, and three annotation strings corrected on one side only — including `SRC 0x08` still carrying the *"LFO/per-unit source"* name its own note retracted. Fixed in `upd6383d.cpp`, with the mirror obligation stated at the two strings, because the check compares text VERBATIM and a stale sentence hides a real disagreement in the noise. Housekeeping also re-run: `dsp/verify.py` **BYTE-MATCH OK**. |  |
| §284 | ★★★ **THE CLASS-4 TWIN EXISTS — in the OTHER PRODUCT's corpus** | ★★★ `dsp/tools/class_twins.py` pools KN5000 + **SX-WSA1R** (same uPD6383 ISA, 60 programs, 4946 words): **7558 occurrences of 1129 distinct words**, with a POSITIVE CONTROL that recovers the cursor-fetch bit unprompted (`2 ↔ A`, 19 triples, xor 8). The pair `dark-words.md` §4.4 asked for and the KN5000 lacks: **`012.2.01.1CE` (WSA1R pitch shifter, DECODED) ↔ `012.4.01.1CE` (x99)** — identical in `hi12`, `addr8` AND `lo12`. That program is the only one in either product spelling the `C63` macro in class 2 throughout, and the two spellings net **+27** ONLY if classes 4 and 6 carry the delta; shipped, they differ by **25 cells** and the class-2 one is an outlier 3x beyond the class-4/6 range. ⇒ RETIRES §281's "index-like, not delta-like". N-INPUT-GATE-OPENED §100 |  |
| §285 | ⛔ **THE GATE: three runs to make it fire, and then one criterion fails** | ⛔ `UPD6383_CLS46PTR`, default OFF, `data/PREDICT_CLS46PTR_2026-09-13.md`. Run 1 fired **0** (the post-increment is at the END of `exec_alu()`; the two sites a grep finds are the K6 whitelist and a copy in `exec_decoded()`'s nop branch). Run 2 fired **3 150 504 = 2/frame** against P1's "≈ 4" — `exec_alu()`'s `if (cl == 6)` branch returns first. ★ **A non-zero fired count is still not the count you predicted.** Run 3: **6 301 008 = 4/frame**, macro walks `0C→24→25→27` = **net +27**, P5 exact (kernel cells bit-identical), **P4 10 KEPT / 0 BROKEN**. ⛔ **P2 FAILS — and could not have succeeded**: §97 showed the macro's head never reaches the SOURCE stage, so the index never arrives and the tap is relocated, not aimed. My error, knowable in advance. ⚠ §176's census in a `catalogue_regression.sh` capture is **CUMULATIVE over the type walk**, not per-program — it nearly read as an EQ regression in a program containing **no class-4/6 word**. **NOT PROMOTED; coverage unchanged at 75.0 %.** N-INPUT-GATE-OPENED §100 |  |
| §286 | ★★ **THE STORE GATE HAS TEN MINIMAL PAIRS — and the LFO RAMP WORD is one** | ★★ `class_twins.py --bit7` over the pooled corpus: **23 pairs** differ in `hi12` bit 7 and NOTHING ELSE; in **10** the bit-7 member is the open gate (`bit-4 store` + `f31 == 1`) and its twin is DECODED and stores `acc` to `mem[ptr]`. ★★ One of the ten is **`092.A.00.200`, the LFO ramp word** (46 occurrences, 26 images), whose increment `lfo-ramp.md` anchors NINE-FOLD; its bit-7-clear twin `012.A.00.200` exists. First context with known mathematics the gate has had that the 29-block solve did not already consume. ⚠ The co-occurrence figure (5 of 10 share an image, null 2.72 ± 0.76, P = 0.019) is **POST-HOC and labelled so in the tool**. N-INPUT-GATE-OPENED §101 |  |
| §287 | ⛔ **`clr:before` HALVES A 255x LFO ERROR, MISSES ITS NUMBER, AND UN-RAILS THE VOLUME CELL** | ⛔ `UPD6383_GATECLR`, default OFF, `data/PREDICT_GATECLR_2026-09-13.md`. **P1 HIT** (22 230 564). **P2 MISS by 136x**: §228's rise census on the chorus phase goes `step 114..4190812 mean 29098 (152.97 Hz)` → `114..3470859 mean 15507 (81.52 Hz)` against a predicted `114..114 (0.5993 Hz)`. ⚠ **The criterion embedded a premise I never checked** — that the gate word is the ONLY contaminant of the phase; it is not, so the miss refutes *"the gate alone accounts for the error"*, not `clr:before`. ★ Third defective criterion of the session, all three caught by the criterion rather than the result. ★★ **POST-HOC LEAD**: the arm removes EVERY railed cell from the chorus, and cell `0x06` — the user's effect **VOLUME**, PROVEN BY CONSTRUCTION in 49 of 49 algorithms, written once by `EFF_VolumeLoop` — goes from `(8388607, railed, chg 1389)` to `(2260027, chg 1)`. ⇒ pre-registered successor `data/PREDICT_VOLCELL_2026-09-13.md`, graded on a criterion the FIRMWARE supplies. N-INPUT-GATE-OPENED §102 |  |
| §288 | ★★★ **THE STORE GATE GRADED AT LAST — `clr:before` passes OUT OF SAMPLE on a FIRMWARE-supplied criterion** | ★★★ `UPD6383_GATECLR`, default OFF. Attempt 1 (the LFO rate) MISSED by 136x and its criterion assumed a sole cause. Attempt 2: cell `0x06` is the user's effect **VOLUME**, PROVEN BY CONSTRUCTION in 49 of 49 algorithms. Registered on five TYPE indices never captured this session: **W1 5/5** (`chg 13` against limits 22..26), **W2 the control 5/5** (shipped churns it **10 746 … 188 032**), W3 MISS (cumulative range, localises nothing; the EQ still rails it), and **10 KEPT / 0 BROKEN** on the hand-off. ★ `chg` counts VALUE CHANGES not writes, and the gate word writes that cell in NEITHER arm -- what is tested is that VOLUME holds a constant under the arm and churns without it. ⇒ the axis goes **three-way → two-way** (`LD` passes it too); `alu_decoded()` still refuses all 138 words and **coverage is unchanged at 75.0 %**. ⚠⚠ FIVE defective criteria this session, the last two repeats of a caveat I had written myself; **the fix is a per-program capture harness, not more care at the same speed.** N-INPUT-GATE-OPENED §102 |  |
| §289 | ★★★ **THE INSTRUMENT THAT REMOVES THE MISTAKE — `UPD6383_CENSUS_PERPROG` — and the clean store-gate result** | ★★★ Three of §102's five defective criteria were the SAME defect: `fx_ab.lua` walks UP from TYPE 0 and §176/§228 accumulate FROM BOOT. Read-only arm, default OFF: both censuses clear on every I-RAM program upload, and the header line now states the mode **including a warning on the default path** (every census number this project has published was cumulative and nothing said so). ★★★ With it, the same five OUT-OF-SAMPLE programs: `GATECLR` ON leaves the **VOLUME** cell `0x06` **written EXACTLY ONCE, unrailed, 5 of 5** (`chg 1`, value 2 260 027); shipped, it is **RAILED 5 of 5** and churned **11 … 177 316** times. ⇒ every surviving family that carries the incoming accumulator through the gate word is REFUTED, including the shipped `-/clr:never`. ⛔ Does not choose among `-` / `ST(acc→else)` / `LD` (all discard it; `else` unreadable by construction). **Coverage unchanged at 75.0 %.** N-INPUT-GATE-OPENED §103 |  |
| §290 | ★★★★★ **THE STORE GATE IS DETERMINED — coverage 75.0 % → 77.6 %** | ★★★★★ `store-gate.md` item D's THREE-WAY open axis closed by ELIMINATION on ROM/firmware criteria, each shown able to fail because a different arm made it fail: `clr:never` ⛔ the **VOLUME** cell (PROVEN BY CONSTRUCTION, 49 of 49 algorithms) RAILED 5 of 5 out-of-sample and churned 11…177 316; `clr:after` ⛔ LFO phase cell DEAD; `LD@before` ⛔ LFO at a **4.0-frame period** against the ROM's 114/frame; `LD@after` ⛔ phase dead. **`clr:before` survives**: VOLUME once and unrailed 5/5, LFO alive with min step exactly 114, **10 KEPT / 0 BROKEN**. `ST(acc→else)` is the SAME MACHINE (`else` unreadable by construction) ⇒ *"is there a store"* stays unanswerable and **stops mattering for EXECUTION**. PROMOTED (`UPD6383_GATECLR` default 1, `=0` the control), **re-verified with NO ENV AT ALL**; guard 7 admits `f31 == 1`; mirrors **3057/3057**, BYTE-MATCH OK, 24 doc pages + permanence PASS. **tier 1 74.0 % → 76.6 % (+78), 77.6 % with tier 1b; frame floor 70.4 % → 72.2 %.** ⚠ NOT fixed: the LFO's RATE (81 Hz vs 0.599) and `f31 == 0`. N-INPUT-GATE-OPENED §104-106 |  |
| §291 | ⛔ **THE DELAY CRITERION IS BLIND TO `ACT 0x0B`** | ⛔ `dsp/tools/sd_act0b.py`. `act0b-reverb.md` item H stopped for want of known mathematics; SINGLE DELAY has it (lag **1001**, sample **45 074** = the ROM's `((c·c)>>23)·h>>23`, harness self-tested 13/13) and a09 carries THREE ACT-0x0B words. **REACH TEST PASSES** -- fired **13 812** times -- the control reproduces the ROM answer, the pointer map is INVARIANT over the six readings, and **ALL SIX give 1001:45074**. The criterion CAN fail (the shipped `ACT 0x0D/0x0E` pair puts 45 074 at lag 500, §234), so this is a measured blindness, not a suspicion. ⇒ at a09's sites the six readings are the same machine. ⛔ The static generalisation does NOT carry: of the 62 words refused for this axis alone, **0** have all three destinations dead -- `mem[ptr]` is live at every one. Coverage unchanged at 77.6 %. N-INPUT-GATE-OPENED §107 |  |
| §292 | ★★ **§96's STATIC BLINDNESS WALK VALIDATED BY THE MACHINE — 5 of 5** | ★★ `data/PREDICT_F31BLIND_2026-09-13.md`. Swept `f31 == 5` over the device's three expressible readings (`m_bx_f5`) per program with the §103 per-program census. **chorus + enhancer: every census BIT-IDENTICAL; phaser, PEQ, auto wah: censuses DIFFER** — and the FRAME TRACE differs in all five, so the arm demonstrably acted and "identical" is a null WITH POWER. ★★★ It agrees with §96's static walk **5 of 5**: where the walk says the accumulator is destroyed unread the machine cannot tell the readings apart; where it says live, it can. ⇒ **§96's 32 admitted words now rest on a measurement as well as a lemma.** ⛔ No new words: the statically-live sites ARE observed, so there was nothing to harvest; coverage stays **77.6 %**. ⚠ the observable set is the censuses, NOT the audio; and `f31 == 4` fired **0** times in the chorus, so it is untested. N-INPUT-GATE-OPENED §108 |  |
| §293 | ★★ **C-FORMAT DESTINATION: 6 → 4 refuted-by-anchor, and a 255× LEAD on the LFO** | ★★ `UPD6383_CFMTDST` (default 0 = the shipped latch), `data/PREDICT_CFMTDST_2026-09-13.md`. Fired **28 577 436**; five of six destinations move a census, so the sweep has power. **`P`, `tempA`, `mem[ptr]` REFUTED** -- each collapses the per-unit hand-off `0x05` from a live ±2.9 M signal to a frozen 14/53/45, the cell §76 promoted `SRC0B2` on across 8 programs. ★ **`latch` ≡ `reg[addr8]` BIT-IDENTICAL**; `acc` and `tempB` keep the hand-off but move other censuses ⇒ the four survivors are NOT one machine, the words stay undecoded, **coverage unchanged at 77.6 %** (outcome H5, named in advance). ★★ **THE LEAD: destination `P` takes the chorus LFO from 153 Hz to 0.674 Hz** -- mean step **128.30** against the ROM's **114**, within **12.5 %**, where the shipped model is out by **255×**. §102 left *"the gate is not the only cause"* open; this names the path. N-INPUT-GATE-OPENED §109 |  |
| §294 | **`SRC 0x11`: the anchored criteria are BLIND, and the diff says why** | `data/PREDICT_SRC11_2026-09-13.md`. All three readings (cur-unit acc / `ACCB` / `mem[ptr]`, all already in the device) leave the hand-off `0x05`, the VOLUME `0x06` and the LFO phase `07` **bit-identical**. ★ The diff localises it: `§176` D-RAM census **IDENTICAL — 0 of 12 cells differ**, `§228` and `§162` identical, while **`§175` PER-SITE DIFFERS** (`L` 0..8388607 vs 0..7474246, `P` with it) and the write counts differ. ⇒ the readings DO feed different multiplicands and **the D-RAM state is bit-identical cell for cell** -- the difference is absorbed before anything is stored, which is why the store-gate method does not transfer: those three criteria are all D-RAM cells. ★ NAMES the replacement: grade **`L` and `P` at the `SRC 0x11` sites** (`§175` already reports both) against a ROM-known multiplicand. Coverage unchanged at 77.6 %. N-INPUT-GATE-OPENED §110 |  |
| §295 | ⛔ **`SRC 0x11`'s OPERAND IS CONSUMED — 5 of 5; the chorus was the exception** | ⛔ `data/PREDICT_SRC11BLIND_2026-09-13.md`. §110's chorus null (`§175` differs, `§176` IDENTICAL) would have made the **54 words refused for this axis alone** executable by §96's lemma, +1.8 %. Tested on enhancer / flanger / ensemble / no-operation / auto-pan: **K1 holds everywhere** (the operand moves) and **K2 FAILS everywhere** (the D-RAM census differs). ⇒ the operand IS consumed; **no words admitted, coverage stays 77.6 %.** ⚠ What is refuted is my EXTRAPOLATION, not §110's measurement -- the chorus's insensitivity is a property of the chorus. ★ Sixth over-read of the session and the sixth stopped by a criterion written before the run. ⚠ **It bounds §108's method: one program's null does not generalise** (§108 held because it had five programs with three showing the opposite). N-INPUT-GATE-OPENED §111 |  |
| §296 | ★★★ **THE BLOCK TERMINATOR IS EXECUTABLE — 77.6 % → 78.5 %** | ★★★ The queue's `class 1` entry is ONE SHAPE: all 19 words refused for that axis alone are `xxx.1.0E.000`, differing only in `hi12`. That is **the block terminator**, MEASURED by `host-side.md` item B1 as **the last word of every body image**, `addr8 = 0x0E` in **37 of 37** unit-0 images and `0x0F` in the one unit-1, with the form already published in `instruction-set.md`. ⇒ §90's argument exactly: the CLASS TEST refuses it and the word's own form explains the class. ★ The §91 check passes — `upd6383.cpp`'s sequencer says *"the transfer, AFTER the word has done its datapath work"*, so the ALU half runs and is anchored on all 19. **tier 1 76.6 % → 77.4 % (+25), 78.5 % with tier 1b; frame floor 72.2 % → 73.6 %; kernel 44.6 % → 47.0 %.** Renders `endblk unit0`. Mirrors **3057/3057**, BYTE-MATCH OK, 24 doc pages + permanence PASS. ⚠ NOT claimed: the call/return itself, which stays the SEQUENCER's model. N-INPUT-GATE-OPENED §112 |  |
| §297 | **`f31 == 4`: outcome C — and the instrument set's boundary, stated** | `data/PREDICT_F31_4_2026-09-13.md`. §108 measured `f31 == 4` firing **0** in the chorus; the shape census found where it runs (12 of 34 are `018.A.00.1D5`, whose `f31 == 0` twin is DECODED). Swept LOAD/ADD/HOLD on compressor, no-operation and auto-wah: **M1 HIT** (fires 1 196 405 / 485 513 / 536 818), **M2 MISS** (census differs -- not blind), **M3 MISS** -- the hand-off `0x05`, the VOLUME `0x06` and the LFO are **IDENTICAL across all three readings in all three programs**. ⇒ outcome C, named in advance; coverage unchanged at **78.5 %**. ★★ **FIVE rounds now agree on the boundary** (§107/§109/§110/§111/§113): the three anchored criteria are sensitive to a WHOLESALE accumulator change and blind to one word's arithmetic. ⇒ the next criterion must be **local to the word — `L` and `P`, which `§175` already reports — graded against ROM-known arithmetic**, not a downstream cell. N-INPUT-GATE-OPENED §113 |  |
| §298 | ★★★★ **THE C-FORMAT IMMEDIATE LOAD DECODES — 78.5 % → 80.4 %** | ★★★★ §109's enumeration indexed the register file by `addr8`; `is_setvec()` proves **`lo12`** is what selects the destination on a C40 word (`lo12` 0x445/0x446 = the per-unit CALL VECTORS, K5 DETERMINED) while `addr8` carries the payload. Mode 7 = `reg[lo12 & 0xFF]` is **BIT-IDENTICAL to the shipped latch on 8 of 8 programs**, arm firing ~28 M times in each ⇒ the register is never read back. ★ Structural half: `is_c40` is ONE opcode (0x620, payload rule 57/57 inside, 2/11 outside) and a destination field selects among REGISTERS -- `acc`/`tempB` would have it write a register for two `lo12` values and the accumulator for the rest. ⇒ **57 words EXECUTABLE**, rendering `ldreg r4C,#25`. PROMOTED (`UPD6383_CFMTDST` default 7, `=0` the control), **zero-risk** and **re-verified with NO ENV AT ALL**. **tier 1 77.4 % → 79.4 %, 80.4 % with tier 1b; frame floor 73.6 % → 75.5 %; reverb image 88.7 % → 91.7 %.** Mirrors 3057/3057, BYTE-MATCH OK, docs + permanence PASS. ⛔ NOT extended past opcode 0x620 (k3-pointers §8 item 3). N-INPUT-GATE-OPENED §114-115 |  |
| §299 | **THE AUTO-PAN DISCRIMINATOR IS BLOCKED ON THE LFO RATE DEFECT -- the chain, stated** | `f31-high.md` §4 item 1 named AUTO PAN as the instrument its pass wanted and never used (a RAMP, so no biquad `f31 = 0` barrier); §108's sweep had covered five programs and not that one. **Q1 HIT** (`f31=5` fires **2 480 216** on TYPE 16), **Q2 MISS**: the rise census is IDENTICAL across ADD/LOAD/HOLD and shows **no ramp to read** -- moving cells step `4..3415889`, `6..4194283`, `152..2313079`, **nothing near 228** = `AUTO PAN C-RAM 01 = 0x0000E4 = floor(1.1986 × 2²³/44100)`. ⇒ right kind of instrument, **precondition not met**. ★ **THE CHAIN: `f31` 3/4/5/7 ⟵ a clean LFO ramp ⟵ the LFO RATE DEFECT, and §109 named the path to that** (C-format destination `P` takes the chorus 153 Hz → 0.674 Hz against the ROM's 0.5993, while destroying the hand-off). Explains §108's and §113's results from ONE cause rather than three. N-INPUT-GATE-OPENED §116 |  |
| §300 | ★★★ **THE ROM's LFO CONSTANT REPRODUCED TO 0.6 % — and the trade that blocks it** | ★★★ `UPD6383_CFMTPCLR` (default OFF): a C-format word INVALIDATES the one-slot product. Chorus, per-program census: **`mean step 114.2560` against the ROM's `114`, `0.60065 Hz` against `0.5993` — 0.6 %**, where the shipped model reads **15 544 / 81.7 Hz, 255× wrong**. First end-to-end reproduction of `floor(0.5993 × 2²³/44100)` from the running machine. ⛔ **R3 MISS: the hand-off cell `0x05` goes to ZERO** -- the audio path dies. NOT PROMOTED (the trade §109 refused). ★★ **The trade IS the finding: the audio path is living on the stale product and the LFO is poisoned by the same value** -- one register, two consumers, opposite requirements ⇒ **the defect is that nothing DRIVES `P` for the audio path there**, which is the shape §240 found for the EQ (*"the baseline's EQ activity is the KERNEL'S RESIDUE being filtered"*). ⇒ **the next question is not `f31' but what should drive the product register**; answering it unblocks the auto-pan discriminator and the whole `f31` family. N-INPUT-GATE-OPENED §117 |  |
| §301 | **THE LFO's CONTAMINANT BRACKETED TO THE KERNEL's OWN C-FORMAT WORDS** | Three arms bracket §117's result (`P` invalidated at every C-format word ⇒ LFO **114.2560**, ROM 114, but the hand-off goes to ZERO): **§118** restricts it to `is_c40` -- the kernel and output stage carry **ZERO** `is_c40` words (opcodes 605/602/621/625/632/60B/600 vs a body's 0x620) so it cannot touch the kernel -- **S3 HIT (hand-off lives), S2 MISS (LFO unchanged)**; **§119** re-tests `CALLFLUSH` (fired 3 181 374) at today's default and **it does nothing for the ramp**, so §56's revert stands AND the *"constant +114/frame ramp"* the ledger credits it with **does not reproduce** -- ★ §94's rule both ways: a refutation expiring does not make a claim true, and here the CLAIM expired. ⇒ **only the KERNEL's own C-format words matter** (iw1/15/22/29/31/40/48/56, spanning both sides of the iw45 that writes the hand-off). ★★★ **The question is now per-site: WHICH of them does the input stage consume and which does the LFO inherit?** Different words ⇒ clearing one and not the other fixes both. N-INPUT-GATE-OPENED §118-119 |  |
| §302 | ★★★★★ **ONE WORD -- `iw40` -- AND IT IS ONE OF THE FIVE UNSOLVED `0x820` WORDS** | ★★★★★ `UPD6383_PCLRIW=<iw>`, `data/PREDICT_PCLRIW_2026-09-14.md`. Clearing the one-slot product at each of the kernel's eight C-format slots in turn: **iw 1/15/22/29/31/48/56 are INERT on both counts**; **`iw40` alone** gives the LFO `mean step` **114.2560** (ROM **114**, `floor(0.5993 × 2²³/44100)`) **and** empties the hand-off cell. ⇒ one word serves both consumers ⇒ the fix is **not a clear but a DRIVER**. ★★★ `iw40 = 0C4A1C0820` is one of the **five `lo12 = 0x820`** words -- the family `closure-pointer.md` item H closed a whole pass on with a null (*"not solved … every contiguous bit-field enumerated"*) and item B falsified as the frame-closing pointer reload. ⇒ **TWO long-standing open problems are ONE**: the unsolved `0x820` semantics are load-bearing for the audio input path AND the LFO rate. ★ The question is now *"what does `w40` DRIVE `P` with?"*, with a known answer at each end (hand-off live at ±2.9 M; ramp at 114). Coverage unchanged at 80.4 %. N-INPUT-GATE-OPENED §120 |  |
| §303 | ★★★★★ **THE SX-WSA1R SHIPS A SECOND COPY OF THE KN5000 KERNEL HEADER** | ★★★★★ `dsp/tools/kernel_homolog.py`. `wsa1/dsp/disasm/struct_00_fd4093.dsm`, catalogued as an unnamed *"shared/alternate body"*, contains **34 of the KN5000 kernel header's first 42 words BYTE-IDENTICAL AND IN ORDER**. Null: the same alignment against all 99 other images in both products scores **best 2, mean 0.4**. ★ Every divergence is a `lo12 = 0x820` word, **four of five keep their opcode across the products and the fifth does not** -- and the fifth is §120's `w40`, reached from the machine by an unrelated route. The pair differs outside the payload in **`hi12` bit 6 alone** (both `f31 = 5`), a bit the disassembler prints `?6`. Arm `UPD6383_HI6C` + `dsp/tools/pslot_sweep.sh`; **C3 positive control PASSES** (mode 1 reproduces `PCLRIW=40` exactly: LFO 114.2560, hand-off gone). N-INPUT-GATE-OPENED §121 |  |
| §304 | ★★★★★ **THE C-FORMAT PAYLOAD IS AN I-RAM ADDRESS -- kernel 47.0 % -> 60.2 %** | ★★★★★ `dsp/tools/cfmt_addr.py`, `kernel_homolog.py --reloc`. `k3-pointers.md` §8 item 3 refused to extend `A = imm13 >> 5` past opcode 0x620 because the extension was UNMEASURED; two routes measure it. **REGION TEST**: all **11** non-`is_c40` payloads land inside the image carrying them (kernel 0..59, epilogue 60..82), **p = 6.6e-9** under a uniform 8-bit payload -- two are SELF-REFERENCES and the two `0x632` words land at `block start + 3` of their own CALL block. **RELOCATION TEST** (no null needed): against the WSA1R's homologous header, **`A` tracks the relocation EXACTLY 4 of 4** while **`B` and `f31` are IDENTICAL** across the products at all five positions. ★★★ Resurrects K3's ζ reading that `closure-pointer.md` item H buried: **5 of 5** one-past-an-END in the WSA1R copy (null 27.1 %), 4 of 5 in the KN5000 -- item H was underpowered because the five words are not five of the same instruction. `decoded()` widened in Python + `upd6383d.cpp`, rendered `ldreg r20,#iw14,0`; mirrors **3057/3057**, byte-match OK. **Kernel 47.0 -> 60.2 %, header 56.7 -> 70.0 %, output stage 21.7 -> 34.8 %, FRAME FLOOR 74.5 -> 79.6 %.** ⚠ ENCODING, NOT PURPOSE. N-INPUT-GATE-OPENED §122 |  |
| §305 | ★★★★★ **THE WSA1R DISASSEMBLY WAS STALE: 40.1 % -> 67.9 % FOR FREE** | ★★★★★ Regenerating `wsa1/dsp/disasm/` with `gen_wsa1_dsp_disasm.py` changed 63 files, and almost none of it is §122: the tree had not been regenerated since the ISA model advanced, so the second product carried a pre-store-gate, pre-terminator, pre-blindness, pre-delay-escape decode. **48 images, 3972 words: strict decode 1591 -> 2697, +1106 words, +27.8 points, from running the generator.** ⇒ every decode proved on the KN5000 transfers to the WSA1R corpus at zero cost -- one ISA, one generator, two trees. ⚠ The converse does NOT hold: a CRITERION validated on KN5000 programs is not transferred by this (§111's boundary). N-INPUT-GATE-OPENED §123 |  |
| §306 | ⛔⛔ **THE BLOCK TERMINATOR'S `addr8` CLAUSE WAS OVER-FITTED TO ONE PRODUCT** | ★★★★ `dsp/tools/xprod_homolog.py` aligns all 100 images pairwise with the SAME-PRODUCT pairs as the null (mean 12.2, 99th pct 89). Two cross-product pairs clear the floor: **KN `prog05_phaser` <-> WSA `eff09_phaser` (97 words identical in order)** and **`prog68_s_delay_phaser` <-> `eff42_s_delay_phaser` (90)** -- the two instruments ship the same phaser -- and each pair's LAST word is a 1<->1 replacement differing in `addr8` alone. ⇒ `is_terminator()` (§112: class 1 + END + `addr8 in {0x0E,0x0F}`) admits **40 of 40** in the KN5000 and **0 of 53** in the WSA1R, whose terminators all carry `addr8 = 0x4F`. The SHAPE is CONFIRMED by the second product (**93 of 93** class-1 END words end a BLOCK; the one non-image-final case is kernel `w49`, which ends the unit-0 CALL block); the VALUE SET and the `addr8 = unit index` reading are REFUTED -- 53 images cannot all be unit 1. Clause dropped in Python + `upd6383d`, rendering now `endblk #4F`. **-53 undecoded words in the WSA1R tree; zero change in the KN5000, which is why one product could not have caught it.** N-INPUT-GATE-OPENED §124 |  |
| §307 | ★★★★★ **THE BYTES RECOVER THE EFFECT CATALOGUE, AND FIVE OF THE TWELVE STUBS EXIST** | ★★★★★ `dsp/tools/xprod_homolog.py --catalogue`. Ranked by byte alignment alone -- **the scorer never sees a name** -- the top cross-product pairs are a DICTIONARY between the two instruments' catalogues: phaser<->phaser, parametric_eq<->parametric_eq, enhancer, ensemble, exciter, rotary, vibrato, overdrive, multi_tap_delay, every `peq_*` and `s_delay_*`. **61 of 67 pairs scoring >= 35 share a name word against a base rate of 11.0 % over all 2400 pairs.** ★★★ And `bit11-family.md` item G's twelve NAMED KN5000 STUBS: **5 of 12 have a program in the WSA1R** -- SLOW ATTACKER, PITCH SHIFTER, PEDAL WAH, **HARS EFFECT (= `eff19_haas_effect`, the KN5000 menu's spelling of HAAS)** and PEDAL WAH+DELAY. `prog52_auto_wah <-> eff12_pedal_wah` (51) and `prog70_auto_wah_s_delay <-> eff55_pedal_wah_delay` (77) say AUTO WAH and PEDAL WAH are one routine under two menu names. ⚠⚠ **SCAFFOLD-CORRECTED, and it corrects me AND an earlier pass**: `NO OPERATION` is 49 words of COMMON FRAMEWORK, so only words BEYOND it count -- pitch shifter 101 own, pedal_wah_delay 94, pedal_wah 70, haas 29, but **slow_attacker only 20 of 50** (30 shared with the KN5000 no-op), against a null of min 18 / median 85 over the other 42 effects. `DECODE-by-correlation-2026-09-08.md` §10 called it *"SLOW ATTACKER == NO OPERATION (a stub)"* on idiom-sequence LCS; at byte level that is wrong, and "a real program" overstates it the other way. ⚠ CREDIT: §10 had already found that *"every KN5000 <-> WSA1R same-name pair clusters"* and that AUTO WAH == PEDAL WAH -- what is new here is the INSTRUMENT (byte identity in program order with a computed null, which is what makes §121/§122 possible), not the correspondence. ⚠ Does NOT transfer a KN5000-validated CRITERION (§111), and does not put a WSA1R program in the emulator (firmware never uploads bodies to IC30; wave ROMs undumped; RULE 12). N-INPUT-GATE-OPENED §125 |  |
| §308 | **THE POOLED QUEUE IS NOT THE KN5000's QUEUE -- and `class 1` is the new head at the worst region** | ★★★ Pooled leverage: **`SRC 0x11` 172 sole** (118 WSA + 54 KN) -- was second, now the head; `class 1` **87** (NEW); `ACT 0x0B` 76; `class 9` 55; `class 4` 46; `SRC 0x1C` 43 (NEW, barely present in the KN5000). ★ The KN5000 has only **8** class-1 words that are neither a delay escape nor a terminator and **ALL EIGHT ARE IN THE EPILOGUE** -- the output stage at 34.8 %, the project's worst region -- while the WSA1R has **150**, with cross-product near-minimal pairs on `addr8` alone (`012.1.C4.05B` <-> `012.1.8D.05B`). `r2-output.md` §1.1/§1.2 MEASURED that class 1 without the escape bit is the REGISTER FILE with `addr8` the index, 48 of 48; **87 of the WSA1R's 150 have an anchored ALU half**, so the class test is all that refuses them. ⛔ **NOT promoted, and the first reason I wrote down was WRONG and I checked it**: the source route EXISTS and is live (`upd6383.cpp:4130`, `regfile = (rdmode == 1) && !(hi & 0x800)`; SPEC bit 23 is SET in the default mask). The obstacle is what the device says about itself -- *"⛔ GUESSED: symmetry … the read side is not [documented], and no note in this project states it"*. ★★ But §126 found a witness: the corpus contains **exactly one** word addressing mode-1 index `0x06` -- epilogue `w12` = **I-RAM 72, in the output stage** -- and `register-space.md` A1 proves BY CONSTRUCTION (49 of 49) that register `0x06`/`0x86` is the **VOLUME**, written once per algorithm by the host's `EFF_VolumeLoop` and never by microcode. Under the register-file reading that word reads the volume where a volume multiply belongs; under the rival the host's volume never reaches the datapath from microcode at all. ⇒ the device comment is corrected to *one anchored instance, generalised by symmetry*; anchoring the general route is the next pass's job. N-INPUT-GATE-OPENED §126 |  |
| §309 | **THE `hi12` BIT-6 MENU IS EXHAUSTED -- U2, reading ABANDONED** | ★★ `UPD6383_HI6C=1..11` + `dsp/tools/pslot_sweep.sh`, pre-registered in `data/PREDICT_HI6C_2026-09-14.md`. **C0 reach PASSES** (19 005 336 firings, identical in every armed mode) and **C3 positive control PASSES** (mode 1 reproduces `PCLRIW=40` to the digit: LFO `114.2560`, hand-off gone). **Nothing passes C1 and C2 together**: modes 1/3/10/11 give the ROM's ramp and all four starve the hand-off; mode 9 (`P <- tempA`) is the only row keeping `0x05` live (chg 90 448) and misses the ramp by two orders of magnitude. ⇒ **`hi12` bit 6 does not act on the product register; the reading is ABANDONED**, and the minimal pair stays a static fact -- §122 is where the homolog paid. ★ By-products: modes 3/10 bit-identical to mode 1 ⇒ `accb` and `tempB` are **zero** at every bit-6-set C-format word in the chorus; modes 7/8 bit-identical to the control ⇒ clearing either accumulator at those 8 sites/frame moves nothing in the rise census or any of the 32 D-RAM cells (the blindness lemma at 8 more sites, ⚠ against those two instruments only). §120's question stands unchanged. Coverage unchanged. N-INPUT-GATE-OPENED §127 |  |
| §310 | **A REGENERATION GATE FOR BOTH TREES** | ★★ `dsp/tools/regen_words_unchanged.sh <ref>`. §123/§124 regenerated 116 listing files and ~4300 lines at once, which is exactly where a generator bug would rewrite a ROM WORD unnoticed. The `wNNN  HHHHHHHHHH` column IS the ROM, so it must be bit-identical across a rendering change. **MEASURED: 8003 of 8003 word columns identical across BOTH trees.** The KN5000 has `dsp/verify.py` (true byte-match, re-run and OK); the WSA1R had no verifier at all and this is its stand-in. |  |
| §311 | ★★★★★ **MODE 1 DECODED -- 143 WORDS, and the read half is no longer a guess** | ★★★★★ `dsp/tools/mode1_index.py`. §126's named next step, done. `class4 & 7` is the addressing mode ⇒ **class 1 and class 9 are ONE question, 247 words**. STORE half already documented (`r2-output.md` §1.1/§1.2, 48/48); the READ half was `upd6383.cpp`'s *"⛔ GUESSED: symmetry"*. Four measurements, each with a control: (1) **327 of 327** mode-1 words carry a NON-ZERO `addr8` including all **228** with no store and no documented use, against a mode-2 control that is **42.6 % zero** where zero is legal; (2) 35 distinct values varying inside one image (the constant control); (3) ★★★ one WSA1R image's 32 indices contain a run of **26 CONSECUTIVE** values, **p <= 7.6e-28**, walked `n, n+2, n+1, n+3` on a **STRIDE OF 4** -- a DF-I biquad's four state cells per section; (4) ★ reads sit at **lag <= 1 from a WRITE OF THE SAME INDEX in 51 of 95**, shuffled null **29.4 +- 2.1, max 37 of 2000**. ⚠⚠ **My first version of (4) was VACUOUS and the NULL caught it** -- "a write of this index exists somewhere in the image" is invariant under a multiset shuffle (null mean **95.0, sd 0.0**, observed **95**). PROMOTED into `decoded()` on the `is_dram`/`is_terminator` footing, rendered `mac rC4` / `mac.b rC4 ; rC4<-acc, acc=0`; two stale *"class 1 cannot reach here"* comments corrected in both mirrors. **WSA1R undecoded 993 -> 851, KN5000 643 -> 642; kernel 60.2 -> 61.4 %, frame floor 79.6 -> 80.1 %.** N-INPUT-GATE-OPENED §128 |  |
| §312 | **THE MIRROR INVARIANT WAS LYING BY OMISSION** | ★★★ `tools/upd6383d_diff.sh -p`. The mirror check compared the two ISA descriptions over the **KN5000's 3057 words only**. §128 decoded 143 words of which **ONE** is a KN5000 word, so a green *"MIRRORS AGREE -- 3057/3057"* said nothing about the other 142. The WSA1R runs the same ISA and its listings carry their own slot indices, so pooling costs one flag. **MIRRORS AGREE -- 8003/8003.** ⇒ any decode whose words live mostly in the other product needs `-p`; the KN5000-only corpus is the wrong invariant for it. |  |
| §313 | ⛔⛔ **THE SENTENCE HOLDING `ACT 0x0B` SHUT IS A DROPPED POPULATION QUALIFIER** | ★★★★ `dsp/tools/act0b_scope.py`. After §128 the pooled queue head is **`ACT 0x0B` -- 191 sole** (62 KN + 129 WSA), ahead of `SRC 0x11`'s 171 (which the datapath handover shows is a real DEPENDENCY CYCLE). Both mirrors refuse `0x0B` outside class A quoting *"every ACT-0x0B delay word carries `addr8` 0x20/0x30"* -- but `dram-matching.md` item J states that measurement's population as **"203 slots over the 83 algorithms where `#cells == #consumers`"**, and the code comment DROPPED the qualifier. Over the full delay corpus **SIX** ACT-0x0B delay words carry `addr8 = 0x60`, round 5 D's FORCED **WRITE**: `kernel w46/w54`, `prog06_ensemble w0/w39`, WSA1R `eff20_ensemble w0/w51` (byte-identical). **TWO are in the KN5000's own algorithm images, so the universal fails inside ONE product.** The CONVERSE fails harder: **463 WRITE-side delay words carry EIGHT distinct ACTIONs and `0x0B` is 1.3 % of them** -- neither field determines the other. CONTROL: **4 of 9** ACTIONs here ARE one-sided, so one-sidedness is the NORM and says little; `0x0B` at 159/6 is not one. ⇒ the universal and the "adds nothing" inference are WITHDRAWN in both mirrors; the SCOPED measurement is untouched and not re-run. ⛔ The code stays OPEN on its own merits -- item D's three survivors stand and `sd_act0b.py` re-run confirms §291 (all six readings give `1001:45074`; SINGLE DELAY is measurably blind to it). Behaviour unchanged, mirrors 8003/8003. N-INPUT-GATE-OPENED §129 |  |
| §314 | ⛔ **A CRITERION FOR `ACT 0x0B` THAT LOOKED DECISIVE AND HAS NO POWER** | ⛔ `dsp/tools/act0b_hazard.py`. If `ACT 0x0B` writes tempA (item D survivor `tA<-acc`), an ACT-0x0B word between a tempA WRITE (`ACT 0x13`) and its READ (`SRC 0x19`) would clobber a live value. MEASURED: **0 of 213** pooled (base rate 9.0 %); restricted to the **26** images carrying BOTH, windows span **25.7 %** and **0 of 48** land inside -- binomial P(0) = **6.6e-7**, permutation null over 2000 reshuffles mean **11.8**, sd 2.8, **MIN 4**. Below every shuffle. ⛔⛔ **THE PER-ACTION CONTROL KILLS IT**: **5 of the 14** actions with n>=20 are equally excluded (`0x01`, `0x03`, `0x0B`, `0x13`, `0x1C`) -- two with no tempA relationship at all, and `0x13` excluded BY CONSTRUCTION as the window's own write -- while `0x12`/`0x14` are ENRICHED 3.6x. The exclusion describes a FILTER INNER LOOP's narrow ACTION vocabulary, not hazard avoidance. ⇒ the reading is NEITHER supported NOR refuted; **the criterion has no power**. Coverage unchanged. ★ METHOD, the SECOND instance this session (cf. §128): the permutation null was CORRECT and INSUFFICIENT -- it asked whether 0 was unusual for THESE POSITIONS, not whether 0 was unusual for AN ACTION OF THIS KIND. **A null that moves is not automatically a null that discriminates; run the per-category control before believing a rate.** N-INPUT-GATE-OPENED §130 |  |
| §315 | ⛔ **`class 3` EXISTS -- the published class space is KN5000-LOCAL** | ★★★ `dsp/tools/class_space.py`. `r2-output.md`: *"class 3 and class B do not exist.  All 31 words with `class4 & 7 == 3` are C-FORMAT words whose `class4` field is immediate data"*; `isa-adjudication.md` item 2: *"the class space is exactly {0,1,2,4,5,6,8,9,A,C,D}"*. Both CORRECT about the KN5000 (measured: class 3 absent from its 2989 non-C-format words) and both quoted as ISA facts. The SX-WSA1R carries **three distinct NON-C-format class-3 words, 14 occurrences**: `104.3.40.1CE` x6 and `104.3.40.1D5` x6 in its KERNEL, `182.3.10.419` x2 in the pitch shifter -- `hi12` 0x104/0x182, nowhere near the 0xC00 C-format mask, so `class4` is NOT immediate data on them. ⇒ the published class space is a KN5000 fact; **the THIRD time today a one-product claim was being quoted as the chip's behaviour** (cf. §124, §129). ⛔ NOT decoded: all 14 are blocked by the CLASS TEST ALONE (SRC/ACT/f31 anchored on every one), so they fall out the moment mode 3's ADDRESSING is documented -- §128's condition -- and it is not. `class4 & 7 == 3` is `mode 2 | mode 1` bitwise, which SUGGESTS pointer+register-file together; a suggestion is not a reading, and `class_twins.py` finds NO class twin at any of the three triples. Coverage unchanged. N-INPUT-GATE-OPENED §131 |  |
| §316 | **FOUR CHEAP ATTACKS ON THE QUEUE, FOUR NULLS** | ⛔ `dsp/tools/queue_probes.py`. (1) **Zero aligned CLASS substitutions** across every cross-product homolog pair scoring >= 35 ⇒ the classes-4/6 pointer reading stays at **n = 2** and the project's non-promotion stands for a MEASURED reason. (2) The class guard `(2, 8, 0xA)` is three corners of a 2x2 -- `class4` bit 3 = CURSOR FETCH, bits 2:0 = ADDRESSING MODE -- and refuses **class 0**, whose every component is admitted elsewhere (guards 5/6 of the same function already say `(cl & 7) != 2`). **REAL but INERT: 221 class-0 words, 0 would decode.** (3) **0 WSA1R-only SRC/ACT codes** (2 KN-only singletons) ⇒ the two products share ONE vocabulary; the WSA1R's remaining 851 words are blocked by the SAME codes, so the second product's value is STRUCTURAL (§121-§125), not fresh codes. (4) The documented-sibling route MEASURED at the ALU field: **6383 ADD = 1 / HOLD = 2 vs uPD7725 ADD = 5 / NOP = 0 -- the numeric codes DO NOT TRANSFER**, confirming the rosetta note's own caveat at the field it matters for; `f31` 3..7 (257 undecoded words) gets nothing from it. No coverage change. N-INPUT-GATE-OPENED §132 |  |
| §317 | ⛔ **`ACT 0x0B` IS NOT THE WRITE SIDE OF `SRC 0x0B`** | ⛔ `dsp/tools/act0b_symmetry.py`. `SRC 0x0B` is ANCHORED as the delay-read DATA REGISTER (§215, 41 listings), so the same numeric code in the ACTION field is the natural producer: `ACT 0x0B` deposits what `SRC 0x0B` collects. **REFUTED**: over **488** pooled SRC-0x0B reads, **0 at lag 1**, median lag **14**, and `ACT 0x0B` ranks **8th of 16** actions on lag-1 adjacency. ★ The per-category control -- shipped WITH the test after §130 -- found `ACT 0x01` at lag 1 in **70 of 91** occurrences (base rate 1.2 %, permutation null mean 4.5 sd 2.0 **max 12** over 2000; ~33 sigma). ⛔⛔ It anchors nothing: **RULE 9** -- de-duplicated the 70 is **ONE distinct word** `A00.0.00.041` in 27 images (2.6x replication) -- and of the **13** distinct ACT-0x01 words **exactly ONE** ever pairs, in 27 of 27 images, the other twelve never. ⇒ a property of that WORD, not of the ACTION field; it anchors neither `ACT 0x01` nor the `SRC 0x01` it also carries. What survives is a real two-word IDIOM (27 images vs null max 11) that decodes nothing. ⚠ A bug written down: the first de-dup printed "13 of 13" because the count read a `defaultdict` inside the display loop and CREATED the missing keys while printing them. Coverage unchanged. N-INPUT-GATE-OPENED §133 |  |
| §318 | **DECODE-QUEUE HANDOVER WRITTEN** | `dsp/analysis/DECODE-QUEUE-HANDOVER-2026-09-14.md`. Ten attacks in one session: **two decoded** (§122 +11 words, §128 +143) and **eight nulls**, each recorded with the reason it closes its line. Names the three blocks holding 619 of ~1358 remaining pooled words -- `ACT 0x0B` (191 sole, **three** criteria now measured blind), `SRC 0x11` (171, a DOCUMENTED DEPENDENCY CYCLE -- do not run another capture campaign at it), `f31` 3..7 (257, downstream of §120's `iw40` and with the sibling route measured NOT to transfer) -- and the lines closed. ★ Also records the strict NEXT-BLOCK-POINTER refinement of §122 as **REFUTED**: 3 of 5 (KN) and 4 of 5 (WSA) against ζ's 4/5 and 5/5, with `w31`/`w36` pointing TWO blocks ahead consistently in both products ⇒ ζ is the right generality and `w40` stays the sole exception. ★★ Two method rules earned: **a null that moves is not a null that discriminates** (run the per-category control WITH the test), and **de-duplicate before quoting a rate** (rule 9). |  |
| §319 | **TWO GUARDS §128 MADE ME WANT TO WIDEN -- BOTH ARE RIGHT** | ⛔ (1) The STORE guards admit a store only in mode 2, while the guard list already admits class 8 = **mode 0** for READING and both modes address through the pointer -- widening looked obvious. **MEASURED: it would admit 12 words, all ONE distinct word `800.8.0B.407`, whose `hi12 = 0x800` carries the FORMAT ESCAPE** -- and `r2-output.md` reads bit 11 as *"this word does NOT address D-RAM through the data pointer"*. ⇒ the premise fails for exactly the words it would admit; guard 6 is RIGHT, and the corpus has **no** non-escape mode-0 store, so the condition is never tested against a clean case. ★ **Look at what the affected words ARE, not just how many** -- the count said "small but real", the words said "your premise is false here". (2) `is_dram()`'s EXACT `class4 == 1` test, the same shape as §124's over-fitted terminator clause: escape words by class are 0 x102, 1 x862, 5 x5, 8 x140, C x7, D x1 and **escape words in mode 1 but not class 1: NONE** ⇒ exact test admits precisely the right set, **no change**. Coverage unchanged. N-INPUT-GATE-OPENED §134 |  |
| §320 | ⛔ **THE HLE ORACLE CANNOT SEE `ACT 0x0B` -- the last named route, MEASURED** | ⛔ `act0b-reverb.md` item H stopped for want of a REFERENCE RESPONSE and `lle-via-hle-oracle` is the standing plan for exactly that; §132's handover named it as the remaining candidate. It does not work here. `dsp/hle/effects.py` line 9 of its own models: *"models of the decoded ALGORITHM (graded), **not bit-exact to the chip**"*. The two ANCHORED oracles cannot see the code: the **biquad** oracle (*"proven bit-exact"*) is validated on `prog39_parametric_eq`, which contains **ZERO** ACT-0x0B words, and **SINGLE DELAY**'s lag-1001 product is MEASURED blind (all six readings give `1001:45074`, §291). In the peq/parametric images the code sits in program **AMBLES** (13) and **DELAY ESCAPES** (19), never in a filter section -- an earlier cut saying "12 of 31 within 4 words of a DF-I latch" was proximity to a MARKER, not membership in a modelled SECTION. ⇒ scoring the three readings against the graded reverb model would be a difference from a GUESS (RULE 13's cousin). **The HLE route is exhausted for this code**; the handover is corrected from "standing candidate" to "the gap to close is a MODELLING job on the reverbs, not a search". Coverage unchanged. N-INPUT-GATE-OPENED §135 |  |
| §321 | ★ **THE QUEUE HEAD IS AN ESCAPE-WORD QUESTION -- 86 % OF IT** | ★★★ Asking what the 191 sole-blocked `ACT 0x0B` words ARE rather than how many: **165 are DELAY ESCAPES (86 %)**, 18 are class A and **already decoded** (the all-pass core's fourth multiplicand route), 26 plain. ★ Every "plain" ACT-0x0B word in the REVERBS is one of the decoded class-A ones (`102.A.00.64B`) ⇒ `capture-signature.md` item F's *"BLOCK A needs ACT 0x0B"* is ALREADY SATISFIED and **the reverb is not where the open words are** -- which retires the plan to build a reverb oracle for this code (§135). ★★ It also REFRAMES §107/§291's null: a09's three ACT-0x0B words are ALL escapes, so SINGLE DELAY was **the RIGHT population, measured**, with the reach test passing and the criterion demonstrably able to fail. ⛔ Still not a promotion: §113's blindness lemma was already refused for this axis by §107 (*"0 of 62 have all three destinations dead; `mem[ptr]` is live at every one"*), and site-blindness w.r.t. one criterion is not word-blindness. ★★★ **The specification this leaves is SEARCHABLE, not a modelling job**: find an ACT-0x0B ESCAPE word whose pointer cell is read downstream by a consumer the ROM's arithmetic pins -- `sd_rerun.py` already has per-algorithm pointer/cell maps and a second program's runner. Handover updated. Coverage unchanged. N-INPUT-GATE-OPENED §136 |  |
| §322 | ⛔ **THE SEARCH §136 SPECIFIED IS CLOSED -- NEGATIVELY, BY MEASUREMENT** | ⛔ §136 turned "find a criterion for `ACT 0x0B`" into a searchable static condition; §137 ran it. Pointer OFFSETS are computable without the absolute base (both ends in one program; `off += s8(addr8)` on pointer-moving words, escapes never move it). **165 escape sites; 134 (81 %) DO have their pointer cell read later** -- confirming §107's *"`mem[ptr]` is live at every one"* -- but **0** have that reader **inside a DF-I section interior**. ⇒ the one BIT-EXACT oracle cannot be aimed at this code from the MEMORY side either; §135 closed the SECTION side. ⚠⚠ **A PROXIMITY CUT GOT IT WRONG FIRST**: "reader within 3 words of an `ACT 0x13`/`0x14` latch" returned **seven** candidates including the WSA1R's own parametric EQ, and every one was a program **AMBLE** (`w0` escape -> `w1` reader) -- the exact false positive §135 caught. The real span test (§130's tempA window) takes it to **0 of 165**. ★ **RULE: when a span exists, test MEMBERSHIP in the span, never DISTANCE to its landmark** -- twice in one session. ⇒ `ACT 0x0B` attacked six ways this session; its 165 open words are delay escapes whose ACTION **no anchored quantity in either product observes**. Coverage unchanged. N-INPUT-GATE-OPENED §137 |  |
| §323 | ⛔⛔ **RETRACTED: I USED THE WRONG SPAN (the third variant of one error this session)** | ⛔ §138 first claimed *"17 undecoded words inside a DF-I section interior, 8 of them the single instruction `804.8.16.1DA` -- the oracle's first target"*, and the handover was updated to lead with it. **WRONG.** It scored membership with §130's **tempA LIVE RANGE**, not `lle_oracle.py`'s own definition (**five consecutive coefficient-consuming CLASS-A MACs** + the class-8 makeup, `BIQUAD_SCHEDULE`). The claimed target is **class 8**, a shape the oracle does not model; the words around it are `post`/`ld.st`, not a five-MAC biquad. **CORRECTED: 97 sections spanning 498 words pooled contain 7 undecoded words -- six MULTI-AXIS (`kernel w30`, `prog15_rock_rotary w65`/`w79`) and one `SRC 0x11` (`prog15_rock_rotary w18`); ZERO `ACT 0x1A`.** Six of seven need several axes closed at once ⇒ a thin lead, not a sized step. `prog39_parametric_eq` still has none, which remains why the oracle has never had to speak. ★★ **METHOD, in its strongest form: USE THE MODEL'S OWN DEFINITION OF THE REGION -- not a proxy for it (§138), and not a landmark near it (§135, §137).** Three variants of one error in one session, each caught only by looking at the actual words. Notes and handover corrected. N-INPUT-GATE-OPENED §138 |  |
| §324 | **ONE WORD WHERE THE ORACLE COULD SPEAK TO `SRC 0x11` -- BOUNDED** | ★★ §138's corrected census left 7 undecoded words inside a real five-MAC run; **exactly one has `SRC 0x11` as its SOLE open axis** -- `prog15_rock_rotary w18 = 0212A01452` (class A, ACT 0x12, f31 1), between `w17` (C-RAM 0x05) and `w19..w21`. If the oracle named its operand role it would anchor `SRC 0x11` **from the BIQUAD instead of from accb captures**, sidestepping the documented dependency cycle; on the canonical schedule (`b1·x1, b0·x0, b2·x2, -a1·y1, -a2·y2`) index 1 is **x0, the current input sample**. ⛔ **A LEAD, NOT AN ANCHOR -- three preconditions, none met**: (1) the run is **SIX** class-A words (`w16` carries C-RAM 0x04, annotated *output-level*), so the section boundary is INFERRED and `w18`'s index moves with it; (2) `lle_oracle.py` **ASSUMES** the cell order *"the six C-RAM cells in the decoded order [b1, b0, b2, -a1, -a2, makeup]"* and does not derive it -- established for `prog39_parametric_eq` only; (3) instantiating a model validated on the EQ at an unvalidated site is §135's problem (a difference from an unvalidated instantiation is a difference from a GUESS). ⇒ establish the section (`DECODE-by-correlation` §7/§15 grade sections), derive the order, THEN read the operand. Recorded with its preconditions because §138 was retracted for skipping exactly that step. Coverage unchanged. N-INPUT-GATE-OPENED §139 |  |
| §325 | **§139's PRECONDITION 1 IS MET; PRECONDITION 2 IS SHARPER THAN STATED** | ★★ Worked §139's chain instead of handing it on. **PRECONDITION 1 MET**: `prog15_rock_rotary` (algo 15) `w17..w21` carries the FULL `DECODE-by-correlation` §7 signature -- `mac.ta` (ACT **0x13**) at `w17`, `mac.tb` (ACT **0x14**) at `w20`, class-8 `post` at `w23` -- five coefficient-fetching class-A MACs, and excluding `w16` (annotated *output-level* gain) leaves **exactly the oracle's six cells**, C-RAM `0x05..0x09` + makeup. ⇒ `w18` is **index 1**, canonical operand **`x0`, the current input sample**. ⚠ The run-length instrument alone cannot identify a section in this family (**7** run-5/6 vs only **3** `ld.ta` in *modulation*, where the EQ family tracks 78 vs 80); it is the §7 MARKERS that do it here. ⛔ **PRECONDITION 2 NOT MET, and the reason is sharper than "the order is assumed"**: deriving it by stability (`biquad_stability_probe.py`'s route for the EQ) needs the **per-coefficient SCALES**, solved in `N-SINGLE-DELAY-RECURRENCE-2026-09-12.md` §10 **for the EQ only**. Two of the rotary's five raw coefficients **exceed 2^23** (15 353 414 and 8 958 128), so no uniform divisor applies and the poles are not computable. ⚠ `w17`'s coefficient is exactly **0**, making the schedule's opening `load` a no-op multiply -- the word may be there for its ACT-0x13 tempA capture rather than its product. ⇒ next step NAMED AND BOUNDED: **apply `N-SINGLE-DELAY-RECURRENCE-2026-09-12.md` §10's scale-solving method to algo 15**. No claim made about `SRC 0x11`. Coverage unchanged. N-INPUT-GATE-OPENED §140 |  |
| §326 | ⛔ **PRECONDITION 2 FAILS -- AND IT IS THE SAME WALL AS EVERY OTHER ROUTE** | ⛔ §140 named the step (apply the EQ's scale-solving to algo 15); §141 did it. ⚠ **CITATION CORRECTED**: §140/handover/LEDGER cited **`biquad-eq.md`, which does not exist** -- the method is `N-SINGLE-DELAY-RECURRENCE-2026-09-12.md` §10, fixed in all three. The EQ's method is a **FLATNESS TEST** whose winner is an **IDENTITY**: under `b0,b2 x4 and b1 x2` the b-vector becomes exactly `[1, a1, a2]`, so `H == 1` and each band is a unity inverter (0.00 dB spread vs 46-109 dB for every rival). **A rotary has no reason to be flat, so the acceptance test evaporates.** Only stability transfers: 3000 role-permutation x scale pairs tried, 1116 stable, **186 distinct (a1-cell, a2-cell, scale, scale) survive -- not 1**. ⇒ the §139 chain is CLOSED: precondition 1 met, **precondition 2 REFUTED**. ★★★ **THE GENERAL SHAPE, after twenty probes: this project pins an answer in exactly TWO places -- the parametric EQ's response (the firmware's own coefficient designer) and SINGLE DELAY's lag-1001 product. Every open code lives outside both, and every route tried this session ended by needing a THIRD.** `ACT 0x0B` (§130/§133/§135/§137), `SRC 0x11` via accb (the documented cycle) and `SRC 0x11` via the rotary's biquad all terminate there -- **one wall, not four.** Coverage unchanged. N-INPUT-GATE-OPENED §141 |  |
