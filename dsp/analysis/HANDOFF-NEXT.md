# ▶ UNPARKED 2026-09-12 — THE AUDIO GATE IS OPEN; READ THIS BANNER FIRST

The park below stands for everything it describes, but the central obstacle it was parked on —
*"the audio never reaches the effect body"* — has been **located to one instruction word and
opened** behind a default-off diagnostic. Start here, then read the park.

**The instrument that did it:** `dsp/tools/frame_pair_diff.py` — capture frame F and F+1 with an
otherwise identical command line, diff every cell and every executed row. A body fed live audio
cannot produce two identical frames; exit status is non-zero on a static body so it can gate a
harness. ⚠ **Diff in EXECUTION order**, not by `iw`: the frame runs `iw0..49` → body `iw84..188`
→ `iw50..81`.

**What it found (all MEASURED, notes `N-INPUT-GATE-OPENED-2026-09-12.md`,
`N-EQ-TOPOLOGY-FROM-BYTECODE-2026-09-12.md`, `N-SINGLE-DELAY-RECURRENCE-2026-09-12.md`):**
1. Audio arrives (cells `0x01`/`0x04` move), the kernel is live through `iw38`, and **`iw39`
   onward — the whole body — was bit-identical**. Cause: `iw38 = 809.0.00.839` carries `lo12`
   bit 11, so `upd6383.cpp:2754`'s "addressing only" branch returns before its **ACT 0x19 tempA
   capture**; `tA` stayed frozen at `0xF65100`. `UPD6383_LO12CAP=1` performs the capture (taking
   the accumulator — the open half of ACT 0x19): body cells 0→3, rows 0→15 of 105.
2. **Class 8 is a POST-SUM ACCUMULATOR SCALE, not a no-op** (`UPD6383_C8SHIFT=n`). `0804816415`
   sits at 35 corpus sites with identical neighbours at every one, biquad programs only; `acc >>= 1`
   is the unique small integer that un-rails the EQ (0 → 33 rows at full scale; 1 → none, all five
   bands propagating, 59 of 105 rows differing; 2 and 3 over-attenuate). ⚠ The AMOUNT is not
   pinned and `addr8 = 0x16` is deliberately not used as the shift.
3. The **multiply scale and the class-8 shift are degenerate** — `(total 23, shift 1)` ≡
   `(total 22, shift 2)` for the band gain. The **input level** breaks the tie: at total-22 the
   pickup arrives pinned at full scale, at total-23 it is finite. Second independent vote for
   §227's total-23.
4. Still dead, and **NOT for the bit-11 reason** (withdrawn in §9) and **not for the `w43`/`w51`
   reason either** (withdrawn in §10): the second pickup `0x0F` and the body→epilogue handoff.
   ⚠ `w43`/`w51` are **§116's per-unit mode register** — 2 of 3057 corpus words, payloads `0x6C`
   (unit 0, wrap) and `0x64` (unit 1, saturate), differing in bit 3 — nothing to do with the data
   path; `w51`'s `0x64` matching the EQ's second state-block base is a coincidence I built on.
   **The next target is therefore open**: find what writes `0x0F`, with the same frame-pair
   instrument and a writer census, before proposing any arm.

⚠ **Method note that cost two builds:** read a word's LISTING before inferring its role from its
fields — `w42/w44/w50/w52` render as `ldptr`/`ldptr.d` (decoded pointer setup) and can never reach
the speculative branch, which is why arms aimed at them fired zero.
⚠ **Build note:** `build.sh`'s wholesale `rsync` was OOM-killed twice; for a source-only change
build directly in `kn7000_mame_build` (the overlay files are symlinked in) with `-j3`.

---

# ⏸ PARKED — 2026-08-01

**The uPD6383GF (IC311) decoding effort is parked, not abandoned.** The autonomous tick has been
stopped. Everything below remains valid; nothing here is superseded by the park.

**Where everything is**
- Running record: `SPECULATIVE-APPLIED-REGISTER.md`, §§1–234. **Later sections retract earlier ones
  in place — trust the tail.**
- Index, dead ends and standing rules 1–23: `LEDGER.md` (**dead-ends tier first**).
- Ready work with grades and sources: `BUILD-LANE-QUEUE.md` — ⚠ **item 0 is CONSUMED (§232, §233, then §234); its replacement is named below.**
- Findings files: `dsp/analysis/*_findings.md`. Archived arm logs: `dsp/analysis/data/`.
- The 22-page reverb+kernel dossier, regenerable from `dsp/analysis/dossier/`; rendered PDF and the
  1989/1992 NEC DSP data books are in `~/compartilhado/KN7000/`.
- The scratchpad (`/tmp`, a **tmpfs — lost on reboot**) is mirrored to
  `~/compartilhado/KN7000/tmp-dir/`. **Refresh that mirror before any reboot.**

**⇒ ITEM 0 IS CONSUMED BY §232 (2026-09-04), AND IT REFUTED THE SENTENCE THAT USED TO STAND HERE.**
The unanchored `SRC`/`ACTION` census ran. Of **33** unanchored codes: **16 CLOSED** by a
measured-constant index (dead end 4), **8 OPEN**, **9 NOT RESIDENT** (⚠ *unmeasured*, not
measured-constant). ⛔⛔ **The claim that the routing guard's population is *"the same set of codes"*
as §229's fabricated-zero census is HALF WRONG**: §229's six are a **SUBSET**, **173 corpus words**,
worth **ZERO** of the guard's 754 — and all six are now closed. **The silence population and the
coverage population overlap in NAME and are DISJOINT IN VALUE.**

**⇒⇒ AND `SRC 0x00` IS NOW DECIDED TOO — §233, the same day. `1 of 7`, AND THE READING THE DEVICE
SHIPS SURVIVES.** SINGLE DELAY's lag-**1001** ROM product accepts `mem[ptr]` with sample **45074**
and refutes `P`, `acc`, `zero`, `DR`, `tA` and the **global** `coef`: under all six, **no injection
cell in the entire 256-cell pointer space** puts a non-zero datum into the delay line (a09 carries
9 `SRC 0x00` words and one is the **HEAD WRITE `w46`**). ⛔ **The null-routing rival is REFUTED BY
EVIDENCE** — `upd6383.cpp` had been citing `action00-discriminator.md` item I, which
`adjudication-round6.md` §14 voided; the comment is corrected.
⛔⛔ **AND PARAMETRIC EQ's `0.198 dB` IS *NOT* A FALSIFIER FOR THIS CODE.** Its harness executes a
**9-word EXCERPT** of a39 (`w5..w13`, ×10) and **none of those words carries `SRC 0x00`** —
unconditional fired count **0**, all seven readings 0.198 dB. ⇒ ★★★★ **a program's word count is
not a harness's reach: print a criterion's FIRED COUNT before quoting it.**
⚠ LIMIT: only the **global** `coef` (mask bit 57) is refuted; bits **58/59**'s gated form is
invisible at a09 and stays open. ⚠ Corpus: **580 of 622**, not 605 of 648 and not 572 of 599.
Reproduce: `python3 dsp/tools/sd_rerun.py src00` · `python3 dsp/tools/gate_settle.py src00`.

**⇒⇒⇒ AND `ACT 0x0D` + `ACT 0x0E` ARE DECIDED — §234, the same day. THE SHIPPED PAIR (§133's
selector `(1, 7)`) IS CONFIRMED FROM DISK, `1 of 49`, BY PARAMETRIC EQ's ENTRY WINDOW** — the sample
injected in the cell the entry reads (`0x05` / `0x0F`) instead of `peq_ir()`'s pre-load into acc and
P, which is what made three-codes.md item A's 144 machines identical (**retracted**). ⛔⛔ **AND THE
SINGLE DELAY FALSIFIER §233 PRE-REGISTERED REACHES THE PAIR (fired 9208/9208) BUT ITS LAG IS WHAT THE
PAIR DECIDES**: under the shipped pair a09 returns the same ROM product **45074 at lag 500** — `0x0E`
at `w45` overwrites P one word before the head write `w46` reloads `acc <- P`. Every SINGLE DELAY
number since §230 was taken with the pair inert (`tA<-bus`, a no-op at all eight sites), on a menu
that could not execute the shipped reading; `sd_rerun.py scan` had crashed since §230. §230's VALUE
control survives at either lag; the lag is **hardware question Q4**. ⛔ **Neither code is anchored.**
⚠ **The fourth arm, a10 MULTI TAP DELAY (`sd_rerun.py multitap`), ran to completion and GRADES NOTHING**:
no pair reproduces its three descriptor taps (best **1 of 4** for 42 pairs, **0 of 4** for 7 — the shipped
pair among them), so rule 20's known-good case fails and the harness is evidence for or against nothing;
its declared gaps are two ALT words run as no-ops and three coefficient fetches beyond the upload. The
seven at 0 of 4 are set-identical to the seven the PEQ pre-load control lists. OPEN residue, filed with Q4.
Reproduce: `python3 dsp/tools/gate_settle.py act0d0e` · `python3 dsp/tools/sd_rerun.py act0d0e` ·
`python3 dsp/tools/sd_rerun.py multitap` · `python3 dsp/tools/act0d0e_corpus.py`.

**The single next action when this resumes** — **`SRC 0x11` (+49), AT `iw11/16/17/19/92`** (§234
§4.2): corpus census with its null first; both known-mathematics harnesses are BLIND to it by
construction (a09 carries no `SRC 0x11`, the PEQ excerpt executes none), so the evidence is in the
KERNEL and needs a **device arm** on the §228 vehicle, two-sided, `default OFF`, graded by provenance
(rule 17) and `§104`'s `D-I` split (rule 21). If the census finds every site's operand constant,
rule 4 closes it in one command.

<details><summary>the action §234 consumed, as it stood</summary>

**`ACT 0x0D` + `ACT 0x0E`, TOGETHER, AT
`iw19`/`iw21`, IN SINGLE DELAY** (§233 §4.2). They are the largest remaining OPEN codes (**+124**
and **+110**), the census found a **varying** index at both, and §232 §4 measured why they are one
question and not two: their resident sites are **ADJACENT in the kernel**. `sd_rerun.py scan`
already enumerates `act0d × act0e` and a09 carries 4 of each; `three-codes.md` item E's
*"unconstrained by anything in the corpus"* was reached by checking PARAMETRIC EQ and the LFO and
**never checking the third context**. **Corpus discrimination FIRST** (rule 13 — §218, §226 and
§233 each decided a rival with zero MAME runs). ⚠ **Reach-test every criterion before quoting it.**

</details>

<details><summary>the action §233 consumed, as it stood</summary>

**`SRC 0x00`, ALONE** (§232 §7.2). It is **+348
corpus words = 46 % of the entire routing ceiling** (`1178 → 1932`, `38.53 % → 63.20 %`), more than
3× the whole operation field; its reading `mem[ptr]` is graded *"1 of 6 enumerated, no independent
support"* by `upd6383.cpp` itself; and the census names **three sites where its index varies**
(`iw13`/`iw14`/`iw36`), so rule 4 does not block it. **Corpus discrimination FIRST** (rule 13).
⚠ It is **605 of 648 paired with `ACTION 0x00`**, the adder's bus term, so **PARAMETRIC EQ's
0.198 dB and SINGLE DELAY's `+0.02149296` are LIVE falsifiers there** and must both be run.
⛔ §233: the denominators are C-format-contaminated (**580 of 622**) and **only SINGLE DELAY is
live** — PARAMETRIC EQ's harness never executes a `SRC 0x00` word.

</details>
⚠⚠ **`KN5000_ENABLE_DSP1` NOW DEFAULTS TO 0**: `build.sh` alone produces a binary with **no uPD6383
device at all** and an empty `upd6383:` log section — indistinguishable from "the instrument was
never reached". The DSP build is `make ... CPPFLAGS=-DKN5000_ENABLE_DSP1=1`, which `build.sh` does
not pass.

**State of the machine:** the emulated chip is **silent**; the one silence criterion plus
`m_rf[0x8D] = 0x009B26` are the checks to quote (§230: the other five are the same measurement).
**8 gates across 11 sections** have shipped — always state the unit.

⚠ **The device source carries instrumentation, `getenv` gates and speculative readings. It is NOT in
a state to propose upstream.** See the PR-readiness inventory prepared 2026-08-01.

---

# HANDOFF — read this first

**§1 rewritten 2026-07-31 by §231.** Read `LEDGER.md` (tier 0 = the blocker + the dead ends),
then this file's §1, then `SPECULATIVE-APPLIED-REGISTER.md` **§231**, **§230**, **§229** and
**§227**, then §§215–228 backwards as needed. Several earlier sections are retracted *in place*; **trust the
register tail over any older summary, including older parts of this file** — §219 found this
file's own §1 four sections stale (standing rule 3, fifth occurrence), §223 found §222's
pre-registered next experiment refutable from a log already on disk, and §224 found §223's own
next candidate refutable the same way, and **§227 refuted BOTH halves of §226's own
pre-registered bisection AND §226's positive half, with one capture and four arms**.

---

## 0. ★ READ `LEDGER.md` FIRST

`analysis/LEDGER.md` is a four-tier progressive-disclosure index: the current blocker, **the dead
ends**, the mask-bit register (generated from the C++, so it cannot drift), and a one-line index of
every register section. It is regenerated by `tools/gen_ledger.py`. It exists because ten passes were lost to re-asking answered questions.
Tiers 1-2 regenerate with `tools/gen_ledger.py`.

## 1. YOUR NEXT TASK

**★★★★★ §231 CLOSED `f31 ∈ {3,6,7}` — THE DECODE LEAD §229 FOUND — AND IT CLOSED THE STRATEGIC
PREMISE WITH IT. THE REVIEW CALLED IT *"the cheapest open route to moving decode coverage"*. IT IS
WORTH **EIGHT WORDS**: `1178 → 1186`, `38.53 % → 38.80 %`. 41 OF THE 53 ARE REFUSED **EARLIER**, BY
THE ROUTING GUARD.
⇒ ⛔ **DEAD END 44.** DO NOT RE-OPEN IT, AND DO NOT RE-DERIVE THE BIT-5 CORRELATION.**

**★★★★ AND THE NEXT LEVER IS NAMED, MEASURED, BY TWO INSTRUMENTS THAT DO NOT KNOW EACH OTHER:
`alu_decoded()`'s ROUTING GUARD (`lo_src_anchored`/`lo_act_anchored`) REFUSES **1139 CORPUS WORDS —
60.6 % OF EVERYTHING UNDECODED** — AGAINST THE OPERATION SWITCH'S **106**. AND THAT IS THE SAME
POPULATION §229's FABRICATED-ZERO CENSUS COUNTS.**

### ★★★★★ 1.-0.NEW231.A THE FOUR NUMBERS TO CARRY FORWARD

```
   THE WHOLE CORPUS BY FIRST REFUSING GUARD  (alu_decoded() is a CONJUNCTION)
     1178 DECODED | 1139 ROUTING (SRC/ACT not anchored) | 546 CLASS
      106 OPERATION (the whole f31 switch) | 68 FORMAT | 20 GUARD 7
     self-test: 1178 / 3057 = 38.53 %, reproducing the review's own figure from a
                mirror of the C++ conjunction   (dsp/tools/f31_367.py)

   §231 COLLAPSED-OP CENSUS -- what `op = f31 & 3' DISCARDS at iw63/70/75/78
     ALL FOUR, BOTH BUCKETS, 614 548 quiet + 288 451 loud EACH (3 611 996 total):
       DISCARDED PRODUCT  min 0  max 0  non-zero 0
       OPERAND L          min 0  max 0  non-zero 0
       acc-in: iw63 = 2 603 010 048 CONSTANT; iw70/75/78 = 0
     CONTROL, two-sided, PASS 3 of 3 and IT COULD HAVE FAILED:
       f31=2 (the UNDISPUTED hold) discards a NON-ZERO product 2 669 493 times,
       peak 592 032 946 752  -- so the census SEES non-zero discards where they exist
```

### ⚠⚠ 1.-0.NEW231.B THREE CORRECTIONS TO §229 — CHECK YOUR OWN CORPUS STATISTICS FOR C-FORMAT

1. **`f31 ∈ {3,6,7}` is 54 words, not 53.** The 54th is `EPILOGUE w74 = C16.9.AB.000`, **C-format,
   bit 5 CLEAR**. In C-format `hi12[11:8]` is a FORMAT TAG and `hi12[3:1]` is not an operation
   field. **Correct form: `53 of 53` among the 2989 NON-C-format words.** (⚠ off-by-one, **sixth**
   occurrence.)
2. **The KERNEL carries ZERO genuine bit-5 words.** §229's *"KERNEL 2, EPILOGUE 5"* counts
   `C64.5.A2.000` and `C64.6.A2.007` — **both C-format**.
3. **§229's *"hold, no product"* describes the ADDER only.** The MULTIPLIER's gate at
   `upd6383.cpp:4947` reads the **RAW `f31`**, not `op`, so `iw63`/`iw75`/`iw78` (all `class4 & 8`)
   **do issue a multiply and do write `m_p`**. And since the accumulate at `:4310` precedes the
   multiply at `:4963` in the same `exec_alu()`, **the quantity the collapse discards is `m_p` ON
   ENTRY** — which is what §231 measured.

⇒ ✔ §229's claims **2, 3 and 4** reproduce **exactly**. Only 1 and 5 are wrong, and both by the
same C-format conflation.

### ★★★★★ 1.-0.NEW231.C THE `w78` BISECTION IS ANSWERED — AND IT IS THE OPPOSITE SHAPE

§229 §7.1 pre-registered *"do the `f31` reading FIRST, `SRC 0x0A` SECOND, never jointly, because
`w78` carries both defects."* **Both are dead, and they were separable from disk:**

* **`w78`'s ACTION is `0x07`, not `0x00`** ⇒ the fabricated `SRC 0x0A` operand **never reaches the
  accumulator's bus term at all**. It reaches only ACTION 0x07's store and `w78`'s own *outgoing*
  product. **§229's *"`w78`'s central null is partly our own fabricated zero"* is true of the
  STORE, not of the presented accumulator.**
* The op code governs only `p_term`, whose source `m_p` is **measured exactly 0** at `w78`.

⇒ **Neither arm is gradable at `w78`: both candidate quantities are measured zero.** ★ And the
fabricated-zero census does **not** explain `iw63`/`iw70`/`iw75` either — their operands are
**anchored, real reads** (`SRC 0x07` = `mem[ptr]`; `SRC 0x03`/`0x00` = `D-RAM[dp]`) and they
measure **exactly zero anyway**. ⇒ **The silence at the four words is an OPERAND-SUPPLY fact, not
a decode fact.**

### ★★★★ 1.-0.NEW231.D PRE-REGISTERED: THE ROUTING GUARD, AND WHAT WOULD FALSIFY IT

**The claim to test:** the unanchored `SRC`/`ACTION` codes are where **both** the silence and the
coverage are. **Required shape: CENSUS FIRST** — per unanchored code, its sites, its **index
range** and its consumer — **before any reading**. ⛔ **Dead end 4 / standing rule 4 forbid
implementing a consumer whose index is measured constant**, so the census must print the index
range, and **a constant index CLOSES that code rather than opening it** (`SRC 0x13`:
`acc 0..0 | m_dp 12..12 | cursor 9..9`, already closed this way).
**Falsifiers:** `m_rf[0x8D] = 0x009B26` must survive; `§S1`'s `4.924 %` must not **fall** (§227's
guard: a clip rate that falls because a term stopped being added is a **REGRESSION**); `§54`
graded first; `§70`/`§211` as **mean AND AC span, both buckets, ONE ROW** (§230).

### ⚠⚠ 1.-0.NEW231.F THE `826 040` / `706 040` PAIR IN EVERY BRIEF IS **PRE-§228**

Those are the **48 000 Hz** window sizes. On the §228 44 100 clock the same two arming windows
measure **`734 548`** (`§54`, arms at 300 000) and **`614 548`** (`§S1`/`§104`/`§70`/`§211`/`§231`,
arms at `S1_ARM_FRAME = 420 000`) — `1 323 000` frames less the arm, less the boundary. The
**120 000**-frame offset between them is unchanged. **Convert before comparing; never subtract one
window from the other.** (⚠ Same class as §229's `§38` correction — the third stale-clock figure.)

### ⛔ 1.-0.NEW231.E WHAT §231 DID NOT DO

**It did not build the pre-registered applied arm**, and deliberately: §229 §7.1's own kill
condition (*"if a reading leaves `§104`'s columns input-INDEPENDENT, the operation field is not the
defect"*) is **satisfied without applying it** — every operand at the four sites is already
measured input-independent, degenerate in both buckets. Building it would have been a
CANNOT-FAIL arm.
⛔ **THE BLOCKER IS STILL *WHAT THE BASE `0x90` MEANS*** (§227, queue item 12).

---

### ⛔ 1.-0-prev-229/230 — the previous head, STILL BINDING


**★★★★★ §229 RESOLVED THE STRATEGIC REVIEW'S THREE "CHEAP DECODE EXPERIMENTS". TWO WERE REFUTED
FROM DISK BEFORE ANY BUILD (`f98` NOT VIABLE; `hi12` BIT 5 VOID BY CONFOUND). THE THIRD RAN AND IS
LOAD-BEARING: 28.492 % OF THE EPILOGUE'S OPERANDS ARE ZEROS *WE* INVENT — INCLUDING THE ONLY
OPERAND OF `w78`, WHERE `§211`'s CENTRAL NULL IS MEASURED. AND THE REFUTED ONE PAID FOR ITSELF:
`f31 IN {3,6,7}` IS `hi12`-BIT-5-ONLY, 0 COUNTEREXAMPLES IN 246 952 062 EXECUTIONS, AT EXACTLY FOUR
SITES — `w63 w70 w75 w78`, THE OUTPUT STAGE'S FOUR UNDECODED WORDS.
⛔ THE BLOCKER IS STILL *WHAT THE BASE `0x90` MEANS* (§227, queue item 12).**

**★★★★ AND §230 RAN IN PARALLEL, ON THE CONTROLS. IT REPAIRED THE PROJECT'S WORST ONE — SINGLE
DELAY's `+0.02149296` NOW **ACCEPTS** THE CORRECTED MACHINE (lag **1001**, sample **45074**,
PREDICTED BIT-EXACTLY FROM THE ROM's OWN COEFFICIENTS) AND **REJECTS SEVEN**, INCLUDING THE ONE IT
USED TO ACCEPT — AND IT PROVED, AS A SET IDENTITY OVER 33 ARMS, THAT `§54`/`§70`/`§211`/rule-19/
`§61`/THE EPILOGUE `D-I` TALLY ARE **ONE CRITERION COUNTED SIX TIMES**.
⇒ ★★★★★ **THE TWO PASSES MEET, AND NEITHER COULD HAVE SAID IT ALONE: the ONE measurement every
"still silent" rests on is, at `w78`, PARTLY OUR OWN FABRICATED ZERO.** §229 found the fabrication;
§230 found that there is only one measurement. ✔ **And §229's census CLEARS `m_rf[0x8D]`** — the
control §230 nominates as the only genuine independent check on the output stage.
**Read `1.-0.NEW9.*` (§229) and `1.-0.NEW230.*` (§230) together; they do not contradict.**

### ★★★★★ 1.-0.NEW9.A QUOTE THIS BESIDE ANY NULL YOU PUBLISH

```
   FABRICATED ZEROS -- src_term()'s `default:' returns a literal 0 for six SRC codes
     kernel A 0.000 %   kernel B 0.000 %   body 1 0.000 %
     body 0   8.772 %   EPILOGUE 28.492 %  TOTAL 9 832 536 / 246 952 062 = 3.982 %
     0x05@iw60  0x01@iw61  0x06@iw68  0x0A@iw78 | 0x13@iw99/108/140/149  0x1C@iw111

   f31 x hi12 BIT 5 -- the corpus rule (53 of 53 static), confirmed DYNAMICALLY
     f31 in {3,6,7}, bit5 = 0 :  0  in 246 952 062 executions
     f31 in {3,6,7}, bit5 = 1 :  4 424 994 at iw63(3) iw70(3) iw75(7) iw78(6) -- ALL EPILOGUE
     ⚠ our model runs all four as `op = f31 & 3' => HOLD, NO PRODUCT
```

⇒ ★★★★★ **`§70` AND `§211` ARE NOT THE SAME KIND OF NULL.** `w73` resolves `SRC 0x10` = the
accumulator and its `f31` is outside the bit-5 family; `w78`'s **only** operand is a fabricated
zero **and** its operation code is collapsed. Both print `mean 0.0 span 0`; **only one is a
statement about the chip.**
⇒ **`m_rf[0x8C]`'s permanent zero (1 108 254 stores, 0 non-zero) is 100 % OURS.**
✔ **`m_rf[0x8D] = 0x009B26 SURVIVES** — its non-zero stores come from a third site.

### ⛔ 1.-0.NEW9.B TWO EXPERIMENTS ARE **STRUCK, NOT DEFERRED**

* **`f98` cross-unit A/B** — its `f98 = 2` half is a **structural zero at `iw207` in nine archived
  arms**, and a minimal pair is **already co-resident, adjacent, in the always-resident KERNEL**
  (`w16`/`w17`). Restate the closure as **"no discriminator"**, never "no co-resident pair".
* **ROCK ROTARY `hi12` bit-5 A/B** — `hi12` bit 5 is read in **exactly one place in the device**,
  the nop guard's `hi12 == 0x000` equality. Remove the guard ⇒ the pair is bit-identical; keep it
  ⇒ the difference **is** the guard. **The review's own kill-condition cannot fire.**
  ⚠ Its recipe is `verified: false`, and the pair is co-resident in **two** images, not one.

### ★★★★ 1.-0.NEW9.C THE NEXT ARM IS PRE-REGISTERED — AND IT MUST BE BISECTED

`w78` carries **both** candidate defects (a collapsed operation code **and** a fabricated operand),
so **a joint arm cannot attribute anything** — §226 and §227 both died of that. Do the **`f31` 3/6/7
reading FIRST**, env-gated **DEFAULT OFF**, two-sided, unconditional fired count; **`SRC 0x0A`
SECOND, never together.** Falsifiers, pre-registered in §229 §7.1 before any build:
`m_rf[0x8D]` must stay `0x009B26`; PARAMETRIC EQ within **0.198 dB**; SINGLE DELAY's
`+0.02149296` untouched; and **§227's guard** — a clip rate that falls because a term stopped being
added is a **REGRESSION**. ⛔ **Do NOT implement the six SRC codes** (dead end 4, rule 4).

### ★★★ 1.-0.NEW9.D TWO STRUCTURAL FACTS THAT CHANGE DENOMINATORS

* **`I-RAM[154..199]` IS NEVER UPLOADED.** Body 0's region is **116 slots**; its resident image is
  **70 words at `[84..153]`** (= `programs.tsv` row 1, CHORUS). **Every body-0 census this project
  has published has a 46-slot tail nobody declared.**
* **§38's "frame 264 002" is a 48 000 Hz figure** (5.500 s). The last upload measures frame
  **246 078 = 5.581 s** on the 44 100 clock. **Convert before comparing.**
* ★ The upload ledger matches the offline corpus **4 of 4** (KERNEL 60, EPILOGUE 23, CHORUS 84/70,
  ROOM REVERB 1 200/133) and agrees with §228's LFO rise census **to the frame** (242 550).

---

### ⛔ 1.-0-prev-228 — §228's headline, STILL BINDING


**★★★★ §229 REPAIRED THE PROJECT'S WORST CONTROL AND PROVED ITS BIGGEST STRUCTURAL DEFECT.
SINGLE DELAY's `+0.02149296` NOW ACCEPTS THE CORRECTED MACHINE (lag 1001, sample 45074, PREDICTED
BIT-EXACTLY FROM THE ROM's OWN COEFFICIENTS) AND REJECTS SEVEN DEFECTIVE ONES — INCLUDING THE ONE
IT USED TO ACCEPT AND THE THREE COEFFICIENT SCRAMBLES A PRESENCE TEST CANNOT SEE.
AND `§54`/`§70`/`§211`/rule-19/`§61`/the epilogue `D-I` TALLY ARE **ONE CRITERION COUNTED SIX
TIMES**, MEASURED AS A SET IDENTITY OVER 33 ARMS.
⛔ NOTHING WAS BUILT OR RUN: ANOTHER LANE HOLDS `upd6383.cpp` WITH 211 UNCOMMITTED LINES.
⛔ THE BLOCKER IS UNMOVED: IT IS STILL *WHAT THE BASE `0x90` MEANS* (§227, queue item 12).**

### ⛔⛔ 1.-0.NEW230.A READ THIS BEFORE YOU TOUCH THE SOURCE — THE LANE IS CONTESTED

At **17:25:47** on 2026-07-31 `src/devices/cpu/upd6383/upd6383.{cpp,h}` gained **211 uncommitted
lines** carrying a **`§230 UPLOAD LEDGER`** and a **`§230 FABRICATED-ZERO CENSUS`**, and at
**17:29** an **untracked** `dsp/analysis/data/D_229.log.gz` appeared. §230 was dispatched with
*"you hold the build/run lane, no other agent is editing source"* — **that was false.**

* ⛔ **Check `git -C kn7000_mame status` BEFORE any build, and NEVER `git checkout` a shared
  working tree** — it would have wiped those 211 lines.
* ⚠ **`D_229.log.gz` is EXCLUDED from every §230 census, by name**, because it was produced by a
  device nobody can rebuild from the committed repo. `outstage_collapse.py` prints the exclusion.
  **If that lane lands, re-run the tool: its arms re-enter the population.**
* ✅ **THE `§229` LABEL WAS DOUBLE-BOOKED AND THIS PASS RENUMBERED ITSELF TO `§230`.** Two
  `## §229` headings existed at once; the ledger's tier-2 index is **generated from those
  headings**, so a duplicate produces a corrupt index. The prose-only pass moved.
  ⚠ **BOTH LANES' TEXT IS PRESENT AND INTERLEAVED IN THIS FILE AND IN THE REGISTER.** Nothing was
  deleted — `1.-0.NEW9.*` is the FABRICATED-ZEROS lane's §229, `1.-0.NEW230.*` is the control-repair
  lane's §230. **They do not contradict each other; read both.** ★ In fact they meet: §229 measures
  that **28.492 % of the epilogue's operands are zeros we invent, landing on `w78`**, and §230
  measures that **`w78` is one of five prints of the single output-stage measurement**. ⇒ **the one
  measurement everything rests on is partly OUR OWN FABRICATION.** That is the joint headline and
  neither pass could have stated it alone.
* ★★ **AND THE GENERAL LESSON:** `gen_ledger.py` and `gen_fixlist.py` call themselves **DERIVED**
  and both read `upd6383.cpp` **from the working tree**. A routine regeneration would have baked
  another lane's unreviewed work into two documents whose whole authority is that they are derived.
  **Both now take `UPD6383_SRC_DIR`**, and `SHIPPED-FIX-LIST.md` was regenerated against a pristine
  checkout of `HEAD` (`8884d88`). ⇒ **A DOCUMENT THAT CALLS ITSELF DERIVED MUST NAME THE SOURCE IT
  WAS DERIVED FROM.**

### ★★★★ 1.-0.NEW230.B THE REPAIRED SINGLE DELAY CONTROL — USE THIS, THE OLD CITATION IS VOID

```
   python3 dsp/tools/sd_rerun.py control      # self-test 13/13 printed FIRST, then:

   configuration                  measured                                  verdict   expected?
   CORRECTED (dram_dir, +1)       lag 1001  sample 45074  gain +0.02149296  ★ ACCEPT  ✔
   corrected, cursor -1           NO ECHO at lag 1001                       REJECT    ✔
   round-6 defect: reversed       NO ECHO at lag 1001                       REJECT    ✔
   reversed + cursor -1           NO ECHO at lag 1001                       REJECT    ✔  <- WAS ACCEPTED
   coefficients SCRAMBLED #1      lag 1001  sample  60691                   REJECT    ✔
   coefficients SCRAMBLED #2      lag 1001  sample -32511                   REJECT    ✔
   coefficients SCRAMBLED #3      lag 1001  sample -46019                   REJECT    ✔
   p0 = 0 (the D1 defect)         NO ECHO at lag 1001                       REJECT    ✔
   ⇒ 1 ACCEPTED, 7 REJECTED, 8 of 8 as expected
```

★ **THE CRITERION IS BIT-EXACT AND COMES OUT OF THE ROM**: `c = 0xE5762C = −0.207331`,
`h = 0x400000 = +0.500000`, `((c·c) >> 23)·h >> 23 = 180 297`, `180 297 · 2²¹ >> 23 = ` **45 074**,
and the harness measures **45 074**. `+0.02149296` is **SINGLE DELAY's** three-factor product —
⛔ **NOT PARAMETRIC EQ's**, whose validation is the separate **0.198 dB** biquad.

★★★ **THE THREE SCRAMBLES ARE THE POINT.** They carry the ROM's own coefficients shuffled among the
same slots, so they **do** put an echo at exactly 1001. **A presence test passes all three.** Only
the *value* separates them.

**The three defects were all in the HARNESS, none in any machine:** (D1) the control leg never
initialised the pointer, so the head-write word `w46` sat at `p0 − 5 = 0xFB`, a cell nobody drives,
and wrote **zero** into the line every frame; (D2) `reversed + cursor −1` is a **double negation**
that restores correct addressing — the old control was **mislabelling a differently-correct
machine** while starving the one it called correct; (D3) `echo_energies` hard-coded `D = 500` but
the taps are in **CASCADE**, `500 + 501 = 1001`, so the window was empty for all eight
configurations; (D4) there is no feedback, so its `E2/E1` had no second echo.
⚠ **`dest07` is INERT for this observable** (all four readings give 45074) and is now printed as
INERT, not counted as a calibration.

### ★★★ 1.-0.NEW230.C THE OUTPUT-STAGE NULL IS **ONE** CRITERION, NOT FOUR — AND NOT SIX EITHER

`python3 dsp/tools/outstage_collapse.py --quote` (19/19 self-tests, 4 synthetic, 12 external):

```
   MOVE-SETS over the 33 modern arms, baseline B_44100_228:
     §54  §70  §211  rule19  §61  epilogue-D-I   ALL move in EXACTLY {C_xb85_full_222, D_xb85_route_222}
     m_rf[0x8D]                                  moves in {C_xb85, D_xb85, O_227, Q_227}   <- STRICT SUPERSET
```

★ **The source forces five of the six.** In `present()`, `§70` and `§211` read the **same local
`pacc`** (differing only in `unit`), rule-19 sums that `pacc`, `§61` reads `v` (derived from
`pacc`), and `§54`'s `m_frame_out_nz` is set from that same `v`. `§41` measures `lvl` non-zero in
every arm, so `v == 0 ⟺ pacc == 0`. **One number, five prints.**

⛔ **STOP QUOTING THEM AS A BATTERY.** *"§54 clean | §70/§211 mean 0.0 span 0 — PASS"* is **one row**.
✔ **Keep them** as the output-stage watch they are. They are not wrong; they are not four.

⚠ **AND THEY ARE NOT THE SAME POPULATION.** `§54` arms at frame **300 000**, `§70`/`§211`/`§S1`/
`§104` at **420 000**. On arm `N_227`, `§54` counts **826 040** quiet frames where `§70` counts
**706 040** — all 120 000 of the difference is quiet (the loud count 313 960 is identical).
**Never compare their counts directly.**

### ★★★★ 1.-0.NEW230.D IS THERE AN INDEPENDENT SECOND CHECK ON THE OUTPUT STAGE? **YES, ONE**

**`m_rf[0x8D]`.** It reads the `w61` **self-loop accumulator** (`§104` rows 60/61, inside the
epilogue), its move-set **strictly contains** the null's, and **it has actually failed**:
`0x009B26 → 0x7FFFFF` (§222 §3), **halved** to `0x004D93` in arm Q, **absent** in arm O. Two-sided,
demonstrated three ways — **and never once quoted in the regression role while four copies of the
null were.**

⚠⚠ **BUT SAY IT PRECISELY.** `m_rf[0x8D]` checks the output stage's **ARITHMETIC**. On the
**presented value** there is **exactly ONE measurement point in the device**. ⇒ **every "the output
stage is still a null" this project has published rests on a SINGLE measurement**, and the batteries
quoted beside it have never been corroboration. `§216` makes that null believable by feeding it; it
does not make it independently measured.

### ★★ 1.-0.NEW230.E `W4′` RESTATED — A SEND-STATE DETECTOR, `20 of 20`, AND THE GATE SURVIVES

Body-0 `D-I` is **`(0,0,0)` on 20 of 20** modern arms whose delay port returned no non-zero datum —
spanning **four mask defaults**, the store-probe fix, `EPIBUS`, `PICKUP`, `PSHIFT`, `NOCARRY` and
**both LFOWRAP polarities**. It moves only where body 0 receives input: `26/28/27` (NOZ05, 7),
`26/23/23` (XB85, 2), `17/16/15` (SRC0B2, 2).
⇒ **Within the class `LFOWRAP` belongs to — an arithmetic change with the send shut — `W4′` has no
reachable failure.**
✔ **THE GATE IS NOT AT RISK**: `W0` (fired 1 176 960, one slot), `W1` (`§S1` moves by **exactly**
−706 040 / −313 960) and `W2` (`§119 iw94` becomes a +114/frame ramp) are two-sided and **did move**.
What changes is the published strength: it reads **11 of 11** and is really **6 of 11 plus
`m_rf[0x8D]`**. `SHIPPED-FIX-LIST.md` is unaffected — it derives from gate declarations, and `W4′`
appears nowhere in the source.
⚠ **NEW:** `O_227`'s delay port returns non-zero **1 175 999** times and it *still* scores `0/0/0`
(NOCARRY takes body 0 100 % input-INDEPENDENT). ⇒ **`§46`'s non-zero count is a
DELAY-LINE-CONTENT detector, not a clean send-state discriminator. Quote the rig, not the port.**

### ★★ 1.-0.NEW230.F §220's *"SLOT FOR SLOT IDENTICAL"* — CORRECTED, WITH ITS MECHANISM

`python3 dsp/tools/rule21_all.py data/C_noz05_220.log.gz data/src0b2_B_on_215.log.gz`:

```
   C_noz05_220     (RIG) body0  acc 28 = 26 + 0 +  2 | mem 32 = 28 + 4 +  0 | L 28 = 27 + 1 +  0
   src0b2_B_on_215       body0  acc 28 = 17 + 0 + 11 | mem 32 = 16 + 4 + 12 | L 28 = 15 + 1 + 12
   C_noz05_220           body1  acc  2 =  2 + 0 +  0 | mem  1 =  1 + 0 +  0 | L  2 =  2 + 0 +  0
   src0b2_B_on_215       body1  acc  2 =  0 + 0 +  2 | mem  1 =  0 + 0 +  1 | L  2 =  1 + 0 +  1
```

✔ The raw markers **are** identical element for element. ⚠ The RULE-21 content is **not**:
**`26/28/27` vs `17/16/15`**, body 1 **`2/1/2` vs `0/0/1`**. ★ **The mechanism**: the difference is
entirely **UNDECIDABLE** slots — `11/12/12` vs `2/0/0`. **The two arms mark the same slots; the rig
DECIDES them and the calibration arm does not.** Re-word to *"the same slots, with different
proof-grade content"*, never *"the rig delivers the same signal"*.
✔ **The send model survives** on §225's independent re-grade; **the corroboration does not.**
⛔ **AND THE SAME TRAP APPLIES TO BODY 1's `2/1/2`** — `0/0/1` on `src0b2_B_on_215` and
`drpub_C_on_src0b2_217`, from the identical raw tally. **NEVER QUOTE A `§104` TALLY WITHOUT ITS ARM
AND ITS `D-I` SPLIT.**

### ⚠ 1.-0.NEW230.G FIVE CONTROL REPAIRS ARE SPECIFIED AND **QUEUED**, NOT SHIPPED

All five are SOURCE print-text changes and §230 would not make one while the lane was contested.
See `BUILD-LANE-QUEUE.md` items 14–18: **A11** (`§S1 CONTROL`'s refuted *"clips = 0"*),
**A15** (`§S3`'s *"EXTERNAL"* control — the source's own comment admits the predicate is identical),
**A19** (`§44`'s 0-in-40-of-40), **A2** (mask bit 5's level guard, never observed to fire),
**A17** (`§S3-C4`, never exercised in the direction that would make it fire). Ship as **one** arm,
certified by `D1`.

### ⚠ 1.-0.NEW230.H ONE CORRECTION TO THE CONTROL AUDIT ITSELF

`§41`'s level is **not** bit-identical in 31 of 31 modern arms. **`clean_vehicle_default` is a
MODERN-layout arm (285 rows) carrying the pre-§188 `0x178D0A`**, which the audit attributed wholly
to the pre-§188 *legacy* family. It is **32 of 33**. ✔ The audit's conclusion is untouched — that is
a host-decode difference, exactly the class `§41` **does** detect. It stays MIS-AIMED as an
arithmetic guard, and **`m_rf[0x8D] = 0x009B26 = 39 718` is still the guard that fires.**

---

### ⛔ 1.-0-prev-228 — §228's headline, TRUE IN EVERY PART

**★★★★ §228 SHIPPED THE 44 100 Hz DSP FRAME CLOCK. THE OLD ONE WAS 48 000, MEASURED FROM DISK
(1 440 001 FRAMES / 30 s ON EVERY ARCHIVED ARM), SO EVERY EMULATED DELAY, REVERB TIME AND LFO WAS
+8.844 % FAST. THE CHORUS LFO NOW LANDS ON 0.599313 Hz AND THE TONE GENERATOR IS BYTE-IDENTICAL.
⚠ BUT THE "CONFIRMING MEASUREMENT ALREADY IN THE REPO" DID NOT EXIST — §196 PRINTED 0.5000 Hz AND
THE 0.652 EVERYONE QUOTED HAD NEVER BEEN MEASURED BY ANYTHING.
⛔ THE BLOCKER IS UNMOVED: IT IS STILL *WHAT THE BASE `0x90` MEANS* (§227, queue item 12).**

### ★★★★ 1.-0-prev-228.A THE CLOCK, AND THE TWO NUMBERS THAT GRADE IT

```
   arm A  UPD6383_FRAMEHZ=48000  (the two-sided control)   data/A_48000_228.log.gz
   arm B  (none) -- THE NEW DEFAULT, 44 100 Hz            data/B_44100_228.log.gz

                                          arm A            arm B
   §228 T2 frames run                     1440001          1323000  = 30 x 44100 exactly
   §228 T4 MEASURED frames / emul. second 47985.602        44086.742
   §228 T5 relative error                 0.000300 PASS    0.000301 PASS
   §228 LFO RISE cell 07  step            114..114 CONSTANT   114..114 CONSTANT   <- INVARIANT
                          period          73584.3 frames      73584.3 frames      <- INVARIANT
                          rate            0.652313 Hz         0.599313 Hz
```

⚠⚠ **DO NOT GRADE A CLOCK CHANGE ON THE LFO's Hz — THAT CRITERION CANNOT FAIL.** The census's Hz
is `wraps/frames × DECLARED rate` and `wraps/frames` is rate-invariant, so **changing the
declaration alone moves it with nothing measured** (rule 8). Grade on **T4**, frames per *emulated*
second against the machine's own clock, and on the **step/period staying invariant**.

### ⛔ 1.-0-prev-228.B `§196`'s WRAP CENSUS IS SUPERSEDED. DO NOT QUOTE IT.

It printed **`0.5000 Hz`** on every arm ever run, biased low **two ways**: its denominator includes
the **264 001** frames before the program upload, during which the ramp is **frozen**
(`1 440 001 − 1 176 000 = 264 001` exactly = the §38 boot-transient end at frame 264 002), and its
numerator **truncates the last partial wrap**. At 44 100 it gets *worse* (`0.4667`). Use the
**§228 RISE CENSUS**, which measures the per-frame step and has neither defect.
★★ **AND THE LESSON IS NOW RULE 20's NEWEST CLAUSE:** `LEDGER.md` carried `0.652 Hz` for weeks in
the register of a measurement and **no log line ever printed it**. *Before quoting a figure as
MEASURED, find the log line it came from.*

### ★ 1.-0-prev-228.C WHAT IT MEANS FOR EVERY OLDER LOG, AND FOR EVERY FUTURE ARM

* **Every frame count in a pre-§228 log is on the 48 000 clock.** `-seconds_to_run 30` gave
  **1 440 001** and now gives **1 323 000**. ⇒ **COMPARE RATIOS ACROSS THE CHANGE, NEVER COUNTS.**
  `§S1` is `4.924 % / 4.920 %` in **both** arms to three decimals while its conversion count falls
  `186 394 560 → 162 240 672` — that invariance is this pass's inertness proof.
* **The arming gates are FRAME counts and did not move**, so their wall-clock times did:
  `S1_ARM_FRAME` 420 000 = 8.75 s → **9.52 s**; `§54` arms at 300 000; `§38` at 264 002.
* **`§200`'s DELAY AGE ms figures in every older log are 8.84 % HIGH** — it divided frames by a
  hard-coded 44 100 while the clock ran at 48 000. Never load-bearing; do not compare across.
* **`UPD6383_FRAMEHZ=48000` restores the old clock** as a two-sided control. ⛔ It is **not** a knob
  for tuning audio.

### ★ 1.-0-prev-228.D THE TONE GENERATOR DID NOT REGRESS, AND THE TEST COULD HAVE FAILED

`W1` (insert **OFF** — the shipping configuration), `W2` (ON at 44 100) and `W3` (ON at 48 000) are
**BYTE-IDENTICAL**, md5 `baffbeee660a7ea68deac866b46b3c6e`, over 1 440 001 frames — with the
**mandatory positive control passing**: peak **21 796**, **626 738 non-zero samples (14.5 %)**, so
it is a comparison of real audio and not of two silences. The stream still renders at 48 000 (its
rate is load-bearing for the EG law, the voice LP coefficient and the pitch step); `run_frame()` is
gated by a **147/160 phase accumulator**, exact and drift-free.

### ⚠ 1.-0-prev-228.E FS = 44 100 HAS **FOUR** PROOFS, NOT FIVE — DROP THE CRYSTAL

All four are **inside the ROM**: `ms × 0xAC44/0x3E8`; the double **`π/44100`** at `0x012F57` that
the **SOLVED PARAMETRIC EQ validates against at 0.198 dB**; `NO OPERATION`'s `D = 4410 = 100.000 ms`;
and 29 LFO blocks × 9 increments `= floor(f·2²³/44100)`, joint null `3.1e-12`.
⛔ *"33.8688 MHz = 768×44100"* is **INFERRED** — the 1996 scan prints **`36.8688 MHz`**, which
divides to **neither** rate. Felipe reading X301 settles it; nothing waits on it.

### ★★ 1.-0-prev-228.F THE BOOKKEEPING REPAIR LANDED (P1–P9), AND IT BROKE TWO TOOLS' SELF-TESTS

TIER 0c now **defines rules 19, 20 and 21** (20 had **17 invocations and zero definitions**);
TIER 0b grew **30 → 41 rows**, covering §221–§227 and the two repo-external verdicts;
`gen_ledger.py`'s unguarded module-scope `main()` — which made **any `import` rewrite `LEDGER.md`** —
is fixed, and it now sees SHIFT-extracted mask bits 35–37 / 42–51. `lint_handoff.py`: **0 FAIL**.
Derived, never counted: `SHIPPED-FIX-LIST.md` (**8 GATES across 11 SECTIONS**) and
`EXTERNAL-VERDICTS-UNFILED.md` (**111** still unfiled).
★★ **AND THE INSTRUMENT LESSON, WHICH COST TWO TOOLS:** `lint_handoff.py` fell **8/8 → 3/8** and
`gen_ledger_ext.py`'s T1 failed — **because this pass repaired the defects they used as controls.**
⇒ **a control that IS the open defect is validated exactly once and is invalidated by its own
success.** Both now use synthetic, two-sided controls (`10/10`, `8/8`). Copy that shape.

---

### ⛔ 1.-0-prev-227 — §227's headline, STILL THE BLOCKER, TRUE IN EVERY PART

**★★★★ §227 REFUTED BOTH HALVES OF §226's PRE-REGISTERED BISECTION — ONE FROM DISK, ONE AS A
MEASURED NO-OP — AND THE REVERB CAPTURE §226 ASKED FOR REFUTED §226's OWN POSITIVE HALF.
`C-RAM[0x90..0xB4]` IS NOT A BOOT-FIXED BANK: IT IS UNIT 1's (THE REVERB's) PARAMETER BANK.
NOTHING SHIPPED AS A DEFAULT. THE BLOCKER MOVES TO *WHAT THE BASE `0x90` MEANS*.**

### ⛔ 1.-0.A `f31 == 1` IS THE ISA's ONLY ACCUMULATE. DO NOT PROPOSE "iw33 does not carry" AGAIN.

* It is `HI_ACC_ADD`: **1309 of 2989** non-C-format corpus words, **695 of 1178** ALU-decoded.
  op 0 LOADs, op 2 HOLDs *without a product*, op 3 gets HOLD's behaviour ⇒ **no second accumulate
  exists**. The **PARAMETRIC EQ biquad** — `programs.tsv` grade **SOLVED**, validated against its
  designer at **0.198 dB** — sums five products through `f31 == 1` words `w6..w10`, which this
  repo's generator renders **`acc += P`**. Without the carry `H(z)` = `makeup · (−a2) · z⁻²`.
* **AND IT DOES NOT FIX THE CLIP.** Arm O, MEASURED: `iw34` becomes `8 388 608` = `2²³` = **FS+1**
  and clips `706040/706040` quiet and `313960/313960` loud — **exactly as on the shipped default.**
* **The 13× clip-rate "win" is the guard firing.** `§S1` `4.924 % → 0.379 %`, bought with
  **117 655 680** accumulate steps refusing to add. Collateral, all measured: `§104` body-0 goes
  100 % input-INDEPENDENT (`first DIFFERS at −1 = never`), and **`m_rf[0x8D]` disappears entirely**.

### ⛔ 1.-0.B `P_SHIFT` IS SETTLED. THE TIED MOVE IS A **MEASURED NO-OP**; THE UNTIED ONE BREAKS A CALIBRATION.

The core's own header says the total is **FORCED and MEASURED**: coefficients are **Q1.22**, data
Q0.23 ⇒ the Q-consistent total is **22**, which is what ships. *"P_SHIFT = 7 is Q-consistent"* is
**false**.

```
   arm  P_SHIFT ACC_SHIFT TOTAL | §S1 quiet  §S1 loud | iw34 datum | m_rf[0x8D]    §41
   N        6      16      22   | 4.924 %    4.920 %  | 14 428 403 | 0x009B26 ✔   0x400000/0x178D0B ✔
   P        7      15      22   | 4.924 %    4.920 %  | 14 428 403 | 0x009B26 ✔   0x400000/0x178D0B ✔
   Q        7      16      23   | 2.273 %    2.141 %  |  9 311 353 | 0x004D93 ✘   0x400000/0x178D0B ✔
```

Arm P's **entire `§S1` block is BIT-IDENTICAL to arm N** over 269 279 999 conversions — the only
differing line is the header text `>> 16` vs `>> 15`.
⚠ **CORRECT THE FALSIFIER LIST WHEREVER IT IS QUOTED: `§41` DOES NOT GUARD `P_SHIFT`** (it reads
C-RAM levels and is unmoved by a 2× product rescale). **`m_rf[0x8D] = 0x009B26 = 39 718` does**,
and arm Q halves it to `0x004D93 = 19 859`.

### ★★★★ 1.-0.C THE BANK AT `0x90` IS **UNIT 1's**, AND THE LADDER CELLS MOVE WITH THE REVERB KNOB

```
   CONCERT REVERB 1 (the COLD-BOOT DEFAULT)  vs  ROOM REVERB 1     -- both SCREEN-VERIFIED
   23 cells differ, EVERY ONE inside 0x90..0xB4, NOTHING else in 256 cells
      [00..4F]  0 of 80 differ     [50..8F]  0 of 64 differ
      [90..A3]  13 of 20 differ  <- the header's own walk
      [9B..9D]   2 of  3 differ  <- 9B and 9C, the LADDER CELLS
   ladder: CONCERT 1  C=4CCCCC/400000/400000  iw33 +1.720 CLIPS
           ROOM 1     C=400000/333333/400000  iw33 +1.320 CLIPS
   in Q1.22 they read as reverb gains:  CONCERT 1.200/1.000/1.000   ROOM 1.000/0.800/1.000
```

★ **THE CONTROL THAT MAKES IT PROOF-GRADE:** an independent 45 s panel run (boot → SOUND → REVERB
page → 40 DOWN → 4 UP) landing on CONCERT REVERB 1 reproduces the **2026-07-22 archived cold-boot
capture on all 256 C-RAM cells, 0 differ** ⇒ the replayer is faithful, the navigation perturbs
nothing, and **the cold-boot default reverb is CONCERT REVERB 1** — every *"CHORUS + RR1"* label in
§226 names the wrong preset.

⇒ ★★★★ **BOTH CANDIDATE BASES ARE NOW MEASURED TO BE SOMEBODY's PER-ALGORITHM PARAMETER BANK**:
`0x00` is unit 0's (§226) and `0x90` is unit 1's (§227). ⛔ **This does NOT re-open `0x00`** — `§S2`
measures the cursor at `0x9B` and the `0x00` arm is worse on every image. It re-opens what `0x90`
*means*.

### ★★★★ 1.-0.D THE BLOCKER, AND THE THREE READINGS THAT MUST BE SEPARATED

Why does a **canned, effect-independent** header read **unit 1's live parameters**?

1. **row 25 is wrong** — `ldptr` does not seed the coefficient cursor (**K3 has said so all
   along**), and the kernel's base comes from somewhere else;
2. **the base is right and the header legitimately reads the reverb's gains** — it does run
   immediately before the reverb's own CALL;
3. **the cursor-advance map is wrong**, so the header's 20 cells are not `base+0x00..base+0x13`.

⚠⚠ **A falsifier that DISTINGUISHES these is required before any of them is tried.** §226 and §227
both caught the same failure mode: a base that makes a number smaller is not a reading.

**CHEAP AND NEXT:** ★★★ **sweep the other twelve reverb presets** —
`REVIDX=n dsp/tools/reverb_select.lua` + `python3 dsp/tools/hdrbase.py --score <a> <b>`, one command
each. If the same 23 cells move every time, that set **is** the reverb's parameter block, measured
rather than inferred from the ROM's T1 map.

Full write-up: register **§227**; `HEADER-BANK_findings.md` carries a **CORRECTION BANNER**;
instruments `dsp/tools/f31carry.py` (18 self-tests, 7 external) and `dsp/tools/hdrbase.py --score`
(3 controls, orientation-sensitive); logs `data/{N,O,P,Q}_227.log.gz`; captures
`notes/data/kn5000_dsp1_upload_{room,concert}reverb1.txt` + their screenshots.

**SHIPPED (both OFF/inert by default):** `UPD6383_NOCARRY` (diagnostic, refuted from disk before
it ran) and `UPD6383_PSHIFT` (0 = shipped 6/16, 1 = tied 7/15, 2 = untied 7/16). `P_SHIFT` and
`ACC_SHIFT` are no longer `constexpr`; **arm N vs §225's arm M is 4 diff lines and NOT ONE is a
measured value**, which is the inertness proof. `dsp/verify.py` **BYTE-MATCH OK**.

---

### ⛔ 1.-0-prev-226 — §226's headline, **PART-RETRACTED by §227**, the rest STILL BINDING

**⛔ RETRACTED (see 1.-0.C above):** *"the header's fixed coefficient bank is `C-RAM[0x90..0xB4]`,
boot-fixed, 15 of 20 header cells invariant, ladder cells `9B/9C/9D` ALL invariant"*. It is
**unit 1's per-algorithm bank**; a reverb-preset change moves **13 of 20** walk cells and **`9B`,
`9C`**. Also **wrong preset**: the cold-boot board is **CONCERT REVERB 1**, not ROOM REVERB 1, so
§226 item G's `9F/A0/A7/A8/AC/B2` attribution names the wrong algorithm.

**★ STILL BINDING, EVERY WORD:**

* ⛔ **DO NOT SEED THE COEFFICIENT CURSOR AT FRAME START.** The base **is** seeded, by an
  instruction: row 25 is LIVE (`is_ldptr` → `m_cursor = ad` under `!(m_specmask & 0x1000)`,
  **mask bit 12 CLEAR**), the **epilogue's `iw69 ldptr #$90`** is the last of the frame, and the
  epilogue has **ZERO** cursor-advancing words ⇒ `w0` starts at **exactly `0x90`, every frame**.
  Setting it to the value it already has **cannot fail**.
* ⛔ **DO NOT AIM THE HEADER AT `0x00`.** `C-RAM[0x00..0x13]` is the **UNIT-0 EFFECT's** own
  parameter bank: PARAMETRIC EQ rewrites `0x00..0x1E` wholesale, moves **all 20**, and writes
  **nothing at or above `0x50`**. §227 re-confirms it: the reverb capture moves **0 of 80** cells
  in `[00..4F]`. The `0x0B` ladder is `+2.733 FS` with PEQ loaded — **1.6× worse than shipped.**
* ✔ **`headerdecode.md` §7.6 STAYS ANSWERED**: the boot-time `cmd 0x02` runs at `0x90` (30) and
  `0xAE` (7) are the upload; a `cmd 0x02` packet carries **no destination** — the host writes an
  `ldptr` into a scratch I-RAM slot first. `30+30+30+7+20 = 117` = the log's own count.
  ⚠ §227 changes only what those 37 cells ARE: **the cold-boot reverb's coefficients.**
* ⚠ **`kernel.dsm`'s *"base 0x00 MEASURED"* IS A GENERATOR DEFAULT.** `gen_dsp_disasm.py` passes
  the literal `0x00`; the word MEASURED belongs to `cram-unit-base.md` item A, which measured unit
  **BODIES**. **Never anchor on it again.**
* ✔ **THE SQUARING MULTIPLY IS FAITHFUL** and ⛔ **`SRC 0x08` MUST NOT BE TOUCHED** (anchored by
  the CHORUS LFO: `acc = 114 << 16` exactly).

---

### ⛔ 1.-0-prev-225 — §225's headline, SUPERSEDED as the task, TRUE IN EVERY PART

**★★★ §225 ANSWERED §224's RULE-21 QUESTION FROM DISK — `28/32/28` SURVIVES, `26/28/27` OF IT
PROOF-GRADE — SHIPPED THE `LFOWRAP` FLIP ON A RESTATED GATE, AND RETIRED THE `0x06` "LATCH-UP":
`0` IS NOT A FIXED POINT.**

```
   arm K  (NEW shipped default)   data/K_lfowrap_default_225.log.gz
   arm L  UPD6383_LFOWRAP=0       data/L_lfowrap_off_225.log.gz     the two-sided OFF control
   arm M  (default, wider census) data/M_s3_census_225.log.gz       0 diff lines vs arm K
```

### ★★★★ 1.-0.0 RULE 21's BLAST RADIUS IS **BOUNDED**, AND THE DISCRIMINATOR IS A PROOF

The discriminator is **forced by the instrument's own bucket predicate** (cite the predicate,
not the line): `const bool nz = (m_in_val[0] != 0) || (m_in_val[1] != 0);`. The quiet bucket is
**not "small input"** — it is the frames where the input latch reads **EXACTLY ZERO**, the same
value on all **706 040** of them. So:

* **quiet range DEGENERATE (`min == max`) ⇒ INPUT-DEPENDENT, PROOF-GRADE.** A ramp sampled over
  706 040 frames sweeps; its quiet range cannot be a point.
* **quiet range NON-degenerate ⇒ the slot carries state that evolves with the input constant
  ⇒ FREE-RUNNING**, and the `*` is RULE 21 exactly.

```
   body 0  NOZ05 (send OPEN)  28/32/28 = I 26/28/27  +  FREE 0/4/1  +  UND 2/0/0
   body 0  shipped (send SHUT) 2/4/1   = I  0/0/0    +  FREE 2/4/1
   body 1  NOZ05  2/1/2      = I 2/1/2   |  XB85 59/44/49 = I 59/44/49
   epilogue XB85 22/19/9     = I 22/19/9   -- ALL THREE 100 % INPUT-DEPENDENT
   kernel A NOZ05 33/40/29   = I 33/35/27 + FREE 0/5/2
```

⇒ ★★★ **`28/32/28` SURVIVES: `26/28/27` proof-grade, `0/4/1` free-running (5 of 88 markers,
5.7 %), and the free part is EXACTLY the four cell-`0x07` rows `iw89..92`.** The two `UND`
rows are `iw90`/`iw91`, ramp carriers whose **loud bucket goes NEGATIVE** where the quiet one
never does — a ramp cannot change sign, so that is evidence *for* input.
⇒ ⚠⚠ **AND THE CORRECTION RUNS THE OTHER WAY: `2/4/1` IS 100 % FREE-RUNNING.** The shipped
build's body 0 is **`0/0/0`** input-dependent. `28/32/28`'s true delta over the null is
**`26/28/27` over `0/0/0`** and the "rig delivers signal" claim comes out **STRONGER**.
⇒ ⛔ **RULE 21's damage is confined to rows reading cell `0x07` or `0x10`. Every other published
tally is proof-grade.** ★ **NEVER QUOTE A `§104`/`§86` COUNT AGAIN WITHOUT ITS `D-I` SPLIT** —
`dsp/tools/rule21_all.py <log>` does it in one line.

⚠ **THE REGION BOUNDARIES WERE WRONG IN EARLIER SLICES.** The device's own labels
(`upd6383.cpp:630`): kernel A `0..49`, kernel B `50..59`, **epilogue `60..82`**, body 0
`84..199`, body 1 `200..332`. The epilogue is INSIDE the low range; a naïve `333..` slice
reports `0/0/0` for `22/19/9` forever.

★ **THE TWO CONTROLS THAT MAKE THIS MORE THAN A CRITERION I INVENTED** (RULE 20): opening the
send is the *only* difference between arms A and C, and a ramp is present in **both** — so the
slots newly `*` in C cannot be free-running. **The differential and the classifier agree
`26 = 26 / 28 = 28 / 27 = 27`, and the `mem`/`L` sets coincide element for element.**

### ★★★ 1.-0.1 SHIPPED: `UPD6383_LFOWRAP` IS NOW THE DEFAULT

`iw91` (§118's wrap word) applies its `SRC 0x08` operand — `C-RAM[0x01] = 0x7FFFFF`, the
constant this file's own C-RAM annotation calls *"wrap"* — as a **MODULUS**, at the adder only.
D-RAM cell `0x10` (`§120`'s modulation cell) stops being a full-scale DC and **carries the
chorus LFO**.

```
   W4′ (RESTATED, and it CAN still fail -- the XB85 arms score body-0 D-I = 26/23/23):
       grade body 0 on DEGENERATE-QUIET markers only.  0/0/0 -> 0/0/0            PASS
   W4′-b  every body-0 FREE marker sits at cell 0x07 or 0x10, nothing else       PASS
   W4′-c  kernel A D-I 27/21/18 -> 27/21/18, unmoved                             PASS
   W0 1 176 960 / one slot (iw91) | W1 §S1 5.303 % -> 4.924 % quiet, 5.298 % ->
   4.920 % loud | W2 §119 iw94 mem[dp10] = the +114/frame ramp | W3 all controls  PASS
   K1 arm K (NO ENV) vs §224 arm J: 7 diff lines, NOT ONE a measured value        PASS
   K2 arm L (=0)     vs §224 arm I: 6 diff lines, NOT ONE a measured value        PASS
   K3 dsp/verify.py BYTE-MATCH OK   |   R  arm M vs arm K: 0 diff lines           PASS
```

⚠ **The env var is KEPT as a two-sided control**: `UPD6383_LFOWRAP=0` reproduces §224's arm I
exactly, so the arm stays bisectable in both directions.

### ★★★★ 1.-0.2 THE `0x06` RAIL IS ANSWERED, AND "BISTABLE" IS RETIRED

`§S3`, the new **boot-window first-store recorder** — read-only, always on, **NO FRAME GATE**,
ladder unbounded in time:

```
   §S3 EPOCH-0 (the PRE-EXECUTION state, 0 prior writes): frame 204731 iw73 pre 0 val 0
   §S3 VERDICT: SETTLING.  store #1357 IS THE ENTRY:
                frame 264002  iw19  pre 0  val 1 650 061  (0.1967 x FS)
                store #1360   frame 264002  iw33  pre 0        val 6 039 795 (0.720 FS)
                store #1362   frame 264003  iw19  pre 8217878  val 8 388 607  RAILED
```

⇒ ★★★ **`0` IS NOT A FIXED POINT.** The ladder's lowest rung is *"val ≥ 1"* and it first fires
at store **#1357** — so stores **#1..#1356 wrote EXACTLY ZERO**, measured. Then `iw19` runs for
the first time and its store **from an EMPTY cell** is already **1.52 ×** the `0.129 703 × FS`
threshold; the rail follows **on the next frame**. **There is no second state.** The rail does
not need an *entry* explained — it needs the **FORWARD GAIN** explained.

★ **HOW `§S3` BEATS RULE 16, and this is the transferable part:** it does **not** sample a time
window. It records **stores** and splits them by a property of the **datum** — the first store's
`pre` is *by construction* the state before any instruction wrote the cell, every later `pre` is
*by construction* an instruction's result — and prints the verdict as the **relation** between
the two (`RESET-STATE` / `SETTLING` / `NO CROSSING`, unconditional).
★ **Its first control is EXTERNAL and passed to the unit:** mask bit 26 counts the identical
predicate at the identical hook and `§220` measured **5 881 351**; `§S3` reports **5 881 351**.

### ⛔ 1.-0.3 §225's BLOCKER — `§S2sq` — **CLOSED as a defect by `SQUARING-MULTIPLY_findings.md` (the squaring is FAITHFUL) and RE-ATTRIBUTED TWICE SINCE.** `SQUARING` moved it to the cursor base; **§226 refuted THAT and moved it to the ALU decode of `iw30/iw32/iw33`** (see §1.-0.C). ⛔ The paragraph below is kept for its measured content only — **do NOT re-open `cursor + 1`.**

**The FIRST non-zero datum ever placed in cell `0x06` is `iw33`'s `6 039 795` = `C-RAM[0x9B]²
>> 6` = `0.720 × FS` — a COEFFICIENT SQUARED, not a sample**, and `§224` §1 already showed
`iw33`'s two product terms alone exceed full scale. ⇒ **the `0x06` rail and `§S2sq` are the same
defect.** `§S2sq` fires **5 100 000** times a run at `iw30 iw32 iw33 iw41 iw89`.

1. ★★★★ **DECIDE `§S2sq`.** `SRC 0x08` resolves to `C-RAM[m_cursor]` and the class-A multiply
   then reads `C-RAM[m_cursor]` **again**, before the post-increment. Should the **multiply**
   read `cursor + 1`?
   ⛔ **DO NOT TOUCH THE SOURCE READ** — it is ANCHORED by the LFO rate (`C-RAM[0x00] = 114` ⇒
   `+114`/frame, `§109`; `§196` now measures the wrap period at 96 000 frames = **0.5000 Hz**).
   Two-sided, **default OFF**, unconditional fired count. Falsifiers: `§41`, SINGLE DELAY's
   validated `+0.02149296` three-factor product, **and now `§S3`'s ladder** — a correct reading
   must move store #1357's `1 650 061` and #1360's `6 039 795`, and `§S1`'s 4.924 % with them.
2. ★★ **POINT `§S3` AT CELLS `0x05` AND `0x07`.** One predicate away, already validated, and
   `§219`'s send question (*"why does the kernel write `0x05` four times a frame"*) is exactly a
   first-store / per-writer-datum question. ⚠ **Re-derive the external control for the new
   cell** — `§220`'s 5 881 351 is `0x06`-specific and does not transfer.
3. ⚠ **`§106`'s cell-`0x06` WRITER LIST IS WRONG AND `§S3` REPLACES IT.** It said *"5 per
   kernel-A pass at iw19/21/27/33/39"*; **5 881 351 is not divisible by 5**. The real census is
   **12 writers**, reconciling exactly, and the `nz` column splits them:
   ```
     RAILS IT (nz on ~EVERY frame incl. all 706 040 SILENT ones):
        iw19:1176011(nz 1175999)  iw33:1176007(nz 1175999)  iw39:1176003(nz 1175999)
     INPUT-DEPENDENT (nz 313 127 ~ the 313 960 loud frames) -- and NOT what rails it:
        iw21:1176011(nz 313127)   iw27:1176011(nz 313127)
     ZEROS ONLY (1308 stores, the traffic that holds the cell at 0 for 1356 stores):
        iw73:98  iw78:196  iw9:23  iw11:19  iw35:8  iw45:4  iw321:960     all nz 0
   ```
   ⇒ **quote `nz`, never just the count.**
4. ⛔ **NOT the host's level poke as the `0x06` entry** — measured **0** host tag-`0x15` writes
   reach D-RAM `0x06` (mask bit 23 SET ⇒ `m_rf[0x06]`), corroborated by
   `UNWRITTEN-CELLS_findings.md` §2.2.
5. ⛔ **NOT `ACT 0x00`'s bus term as a general attenuation** (refuted for `iw34`, §224);
   ⛔ **NOT `ACC_SHIFT`/`P_SHIFT` on a moved number** (halving the products still leaves `iw33`
   at 1.110 × FS); ⛔ **NOT another store-suppression rig** (§223 §3); ⛔ **NOT `ACT 0x0D` /
   `m_bx_sel0d` / `iw205`** (§222 §1); ⛔ **NOT `SRC 0x03`/`ACT 0x03` as a crossbar latch**
   (§222 §4); ⛔ **NOT the epilogue's operand set** (§221); ⛔ **NOT mask bit 23** (confounded)
   **or bit 26** (dead end 30).
6. **body-0's coefficient cursor at `iw112`** — still open, still untouched by all of the above;
   `RISK-TRIAGE_findings.md` §5 resolved the `coef 0..24` vs `0x1364D9` conflict with zero runs
   and the **×24 attenuation STANDS**.

### ⚠ 1.-0.4 WHAT §225 ADDED AND CORRECTED — THREE OF THEM ARE METHOD

* ★★★ **RULE 21 IS NOW OPERATIONAL, NOT JUST A WARNING.** `dsp/tools/rule21.py` decides it, the
  discriminator is forced by the bucket predicate, and the `1 %` `X-ramp` threshold is **not
  load-bearing**: the worst FREE-classified extra reach across 33 logs is **0.000048 % of span**,
  a 20 971 × margin.
* ★★★ **A GATE MUST BE ABLE TO FAIL, AND SAYING SO MEANS NAMING AN ARM WHERE IT DOES.**
  `W4′` is `0/0/0` here, but the **XB85 arms score body-0 `D-I` = `26/23/23` on the same
  instrument, column and vehicle**. That is what makes it a gate rather than a rewrite.
* ★★ **A BOOT-WINDOW INSTRUMENT NEED NOT TRADE OFF RULE 16** if it splits epochs by a property
  of the **datum** (had an instruction already written this cell?) instead of by a time
  threshold, and prints the verdict as the **relation** between them.
* ⚠ **THE OVERFLOW COUNTER EARNED ITS KEEP ON ITS FIRST RUN.** `§S3`'s 8-slot writer census
  overflowed **2 352 974** times and *said so*; without it the truncated 8-name list would have
  looked like a complete census and would have "confirmed" `§106`. **The audit's
  `store_probe()` finding is now a habit, not a note.**

### ⛔ 1.-0-prev-224 — §224's headline, SUPERSEDED as the task, TRUE IN EVERY PART


**★★★ §224 ANSWERED §223's BLOCKER AND KILLED §223's OWN CANDIDATE WITH IT. THE NEW BLOCKER IS
KERNEL A's D-RAM CELL `0x06` — AND IT IS A LATCH-UP, NOT A GAIN ERROR.**

```
   arm I  (shipped default)  data/I_s2_224.log.gz    THE NULL
   arm J  UPD6383_LFOWRAP=1  data/J_lfowrap_224.log.gz  the wrap-word reading (DEFAULT OFF)

   iw34 = 000.A.FF.407 -> lo12 0x407 -> SRC 0x10 = THE ACCUMULATOR, ACT 0x07.
     Its conversion is NOT a store's datum: it is the accumulator placed on the BUS,
     and its value is §104 row 33's acc >> 16.  §S1's value is ALWAYS the PRE-update
     accumulator = the PREVIOUS slot's §104 acc (verified 8 of 8 from disk).

   THE LADDER, reproduced to the unit and then confirmed by §S2:
     iw30  09A.A.00.200  acc = 0 + (C-RAM[9B]<<16) + P(0)             5 033 164   0.600 FS
     iw32  000.A.FF.207  acc = P(iw30) = C-RAM[9B]^2 >> 6             6 039 795   0.720 FS
     iw33  412.A.00.200  acc += (C-RAM[9D]<<16) + (C-RAM[9C]^2 >> 6) 14 428 403   1.720 FS
     iw34  SRC 0x10   -> L = clamp(14 428 403) = 8 388 607
   ⇒ iw33 is the OVERFLOW SITE.  Both its addends are exactly 1/2 FS and NOT ONE of the
     three terms is a sample -- a coefficient and two coefficients SQUARED.
   ⇒ ⛔ ZERO THE ACT-0x00 BUS TERM AND iw33 STILL LEAVES 10 234 099 = 1.220 x FS.  STILL
     CLIPS.  §223 §8.2 is REFUTED for iw34, from disk, with no build.
```

⇒ **AND WHERE THE BUS TERM *IS* THE CAUSE, THE ADDEND HAS A NAME.** `§S1`, both buckets:
`iw92 − iw91 = 8 388 607` **exactly, at both endpoints**, and `8 388 607 = 0x7FFFFF = C-RAM[0x01]`
— the constant `upd6383.cpp`'s **own** C-RAM annotation calls *"wrap"*. `iw91` is `§118`'s wrap
word (`ST mem[Q] <- (phase + INC) mod 2**23`); the shipped model **ADDS the modulus**, so `iw92`
publishes `clamp(phase + INC + 0x7FFFFF)` and D-RAM cell `0x10` — `§120`'s modulation cell — is a
full-scale DC while the phase itself ramps correctly at `+114`/frame in cell `0x07` (`§109`).

#### ⛔ prev-224.a — §224's "WHAT TO DO NEXT", **CONSUMED BY §225**

> ⚠ **ITEM 1 (flip `LFOWRAP`) IS DONE — §225 SHIPPED IT.** **ITEM 2 (the cell-`0x06`
> boot-window instrument) IS DONE — §225's `§S3`, and its answer RETIRES the "latch-up /
> stable second state" framing: `0` is not a fixed point.** **ITEM 3 (`§S2sq`) IS NOW THE
> BLOCKER.** Kept below only for its wording; read §1.-0.0..§1.-0.3 above instead.

1. ★★★ **FLIP `UPD6383_LFOWRAP` TO DEFAULT ON — after restating `W4`.** Arm J passed
   **every** falsifier except one this pass set for itself:
   ```
     W0 FIRED 1 176 960, ONE slot (iw91)                                        PASS
     W1 §S1 quiet 9 884 596 -> 9 178 556 = -706 040 EXACTLY (5.303 % -> 4.924 %)
        §S1 loud  4 391 682 -> 4 077 722 = -313 960 EXACTLY (5.298 % -> 4.920 %) PASS
     W2 §119 iw94 mem[dp10]  8388607 x8  ->  1006898 1007012 ... 1007696         PASS
        -- a +114/frame RAMP.  THE CHORUS LFO REACHES ITS PUBLISHED CELL.
     W3 §41 0x400000/0x178D0B | m_rf[8D]=009B26 | §54 clean | §70/§211 mean 0.0
        span 0 BOTH buckets BOTH arms | §S1 iw39 loud min 1 991 044              PASS
     W4 §104 body 0  2/4/1 -> 2/9/4                                              FAIL
     R1 arm I vs F_satcen_223.log.gz: NOT ONE measured value moved               PASS
   ```
   ⚠ **`W4`'s failure is an INSTRUMENT ARTEFACT** — see rule 21 below. The `acc` column is
   **unchanged at 2**; what moved is `mem`/`L` on the six slots that read cell `0x10`.
   **Restate `W4` so it cannot fire on a ramp** (grade body 0 on `acc` alone, or require the
   loud range to *contain* values the quiet range cannot reach), then flip.
2. ★★★ **THE NEW BLOCKER: KERNEL A's CELL-`0x06` LATCH-UP.** `§S2` names it term by term:
   ```
     iw13  carried 239 225 266 218 + bus 549 755 748 352 + P 239 225 266 218 = 1.870 FS
     iw14  carried             0   + bus 549 755 748 352 + P 239 225 266 218 = 1.435 FS
     busSRC 00 = mem[ptr] = CELL 0x06, at UNITY;  §96: iw19 STORES the clamp back into 0x06
     §176 shipped:  06:8388607(0..8388607/chg1100)
   ```
   `549 755 748 352 = 0x7FFFFF << 16`. **`iw13`'s other two terms sum to `0.870 FS` — BELOW the
   rail — so this is a BISTABLE, not a gain error**, and the shipped build sits in the latched
   state with zero input. ⇒ **Find what first drives cell `0x06` past ≈ `0.13 × FS`.**
   ⚠⚠ **`§S1`, `§S2` and `§104` ALL arm at frame 420 000 and CANNOT SEE IT.** A boot-window
   instrument is required and **its arming must be stated in the prediction**.
3. **`§S2sq`: the multiply squares its own coefficient, 5 100 000 times a run**, at
   `iw30 iw32 iw33 iw41 iw89` (1 020 000 each). `SRC 0x08` reads `C-RAM[cursor]` and the class-A
   multiply reads `C-RAM[cursor]` **again** before the post-increment.
   ⛔ **Do not "fix" the SOURCE:** `SRC 0x08 = C-RAM[cursor]` is **ANCHORED by the LFO rate**
   (`C-RAM[0x00] = 114` ⇒ `+114`/frame, `§109`). Whether the **multiply** should read
   `cursor + 1` is open, two-sided, default OFF; falsifiers are `§41` and SINGLE DELAY's
   validated `+0.02149296` three-factor product.
4. ⛔ **NOT `ACT 0x00`'s bus term as a general attenuation** — refuted for `iw34`; at
   `iw13`/`iw91` the fault is **what is on the bus**, not that it is added.
5. ⛔ **NOT `ACC_SHIFT` / `P_SHIFT`** on a moved number. ⚠ For the record: the kernel's C-RAM
   block is **Q23** — `0x4CCCCC = 0.600000`, `0x400000 = 0.500000`, `0x4F5C28 = 0.620000`,
   `0x50A3D7 = 0.630000`, `0x599999 = 0.700000`, `0x5C28F5 = 0.720000`, `0x5D70A3 = 0.730000`,
   `0x600000 = 0.750000` (eight round decimals, all ≤ 0.75 — reverb gains) — and
   `P = (coef × L) >> 6` with `ACC_SHIFT = 16` makes the product **2 ×** a Q23 product. That is an
   **OBSERVATION, NOT A PROPOSAL**: `ACC_SHIFT = 22 − P_SHIFT` ties them, `§41` and `m_rf[0x8D]`
   calibrate `ACC_SHIFT`, and halving the products alone still leaves `iw33` at **1.110 × FS**.
6. ⛔ **NOT ANOTHER STORE-SUPPRESSION RIG** (§223 §3), ⛔ **NOT `ACT 0x0D` / `m_bx_sel0d` /
   `iw205`** (§222 §1), ⛔ **NOT `SRC 0x03`/`ACT 0x03` as a crossbar latch** (§222 §4),
   ⛔ **NOT the epilogue's operand set** (§221).
7. **body-0's coefficient cursor at `iw112`** — still open, still untouched by all of the above;
   `RISK-TRIAGE_findings.md` §5 resolved the `coef 0..24` vs `0x1364D9` conflict with zero runs
   and the **×24 attenuation STANDS**.

#### ⚠ prev-224.b — WHAT §224 ADDED AND CORRECTED — TWO OF THEM ARE METHOD

* ★★★ **RULE 21 (NEW): `§104`'s and `§86`'s quiet-vs-loud markers CANNOT DISTINGUISH
  "input-dependent" from "FREE-RUNNING AND SAMPLED OVER TWO FRAME SETS".** Proof, from a case that
  predates the change and is in **every** log this project has taken:
  ```
     ★ cell 07  quiet [4 .. 8388594]  loud [8 .. 8388598]     <- THE LFO PHASE. No input in it.
     ★ cell 10  quiet [0 .. 8388594]  loud [0 .. 8388598]     <- arm J, the published copy
  ```
  Both buckets cover the whole ramp; the endpoints differ by **less than one increment (114)**
  because the buckets are different *sets of frames*. **Never grade a cell carrying an LFO, a
  counter or any free-running ramp on those markers.**
* ★★ **`§S1`'s VALUE IS THE PRE-UPDATE ACCUMULATOR — the PREVIOUS slot's `§104` `acc >> 16`.**
  Verified 8 of 8, both endpoints, from disk. `iw34 = row 33`, `iw92 = row 91`, `iw39 = row 38`.
  The build now prints this as a `§S1 PROVENANCE` line so the after-slot/before-slot off-by-one —
  **five occurrences** — cannot be made a sixth time from this instrument.
* ★★ **A CENSUS WHOSE INTERNAL CONSISTENCY IS TRUE BY CONSTRUCTION IS NOT A SELF-TEST.**
  `§S2`'s `carried + bus + P == result` cannot fail (the terms are split out of `src_term`
  itself) and the source **says so**. Its real controls are **external and pre-registered**:
  four per-term values derived from `§104` + the frame trace before the code existed, all four
  passing digit for digit, plus a pre-registered row **exclusion** (`iw34` must NOT appear —
  and it does not).
* ★ **STANDING RULE 3/13 PAID OFF AGAIN.** `0x7FFFFF` was already annotated as *"wrap"* in
  `upd6383.cpp`'s own C-RAM dump comment and `iw91` already called *"the wrap word"* in its own
  §-note. The reading was **read out of the file**, not invented.
* ⚠ **`§223`'s `ACT 0x00` bus-term candidate is HALF RIGHT and the half matters.** The mechanism
  is real — a unity-gain bus addend — but at `iw34` it is not the cause (refuted from disk) and at
  `iw13`/`iw91` the problem is **what the bus carries** (a railed memory cell; a modulus), not the
  absence of attenuation.
### ⛔ 1.-0-prev-223 — §223's headline, SUPERSEDED as the task, TRUE IN EVERY PART

**§223 SHOWED THE RAIL IS THE SHIPPED BUILD'S, NOT THE RIG'S:** `§S1` measures **5.303 %** of all
accumulator conversions clipping on the shipped default with the input **exactly zero**, at a rate
**HIGHER** than the loud bucket; **seven** sites clip on 100 % of quiet frames. `NOZ05 = 2` (the
narrow rig, 2 stores vs mode 1's **8**) reproduces `28/32/28` / `33/40/29` / `2/1/2` column for
column and **still rails**; the two rigs' clip counts differ by **exactly** `iw9`'s conversions,
every one of which clips. §222's post-update bit-4 store was **refuted from disk, no run**. The
nop guard was narrowed by `addr8 == 0x00` (`§NG` = 2 371 200, 29-line diff with no measured value
moved); ⚠ **82 of the 103 words remain UNMEASURED, not measured-zero**.
⚠ **AND ITS ONE MIS-AIM, corrected by §224:** *"`ACT 0x00`'s bus term is the leading candidate"*
is **refuted for `iw34`** — zero it and `iw33` still leaves `1.220 × FS`.

### ⛔ 1.-0-prev-222 — §222's headline, SUPERSEDED as the task, TRUE EXCEPT FOR ITS ATTRIBUTION

**§222 CLOSED `ACT 0x0D` AT `iw205` ITSELF** — the operand `547 518 .. 8 388 607` gives `ACCB`
`35 882 139 648 .. 549 755 748 352`, `L × 65536` to the unit, **both endpoints**. `iw205` is a
**MESSENGER**, `m_bx_sel0d` stays **FROZEN at 1** and is a regression control.
**`D-RAM[0x85]` has NO WRITER AT ALL** on settled frames, measured by an instrument that names
`iw70` the instant one exists. **`SRC 0x03`/`ACT 0x03` as a crossbar latch is REFUTED** by a
two-sided bisection (arm E fired 1 204 800 / 1 203 840 and `diff`s **empty**; arm D equals arm C
in every column). **`§221 F1` is still 0 with the link open** — provenance `iw11`, kernel A's dry
deposit. **The mode-1 store rebase is UNIFIED** (corpus 7/7, 5 976 000 resolutions, 0 disagreements).
⚠ **AND ITS ONE MIS-ATTRIBUTION, corrected by §223:** *"the pedestal is `UPD6383_NOZ05`'s own
rail"* is **too kind to the shipped build** — the shipped default clips **5.303 %** of all
accumulator conversions with the input **exactly zero**, at a rate **higher** than the loud bucket.
The rig removes the two stores that were **hiding** it from body 0; it does not create it.

### ⛔ 1.-0-prev-221 — §221's headline, SUPERSEDED as the task, TRUE IN EVERY PART

**§221 CLOSED THE EPILOGUE BY PROVENANCE: it is not starved, it is NOT CONNECTED.** `§E1`, the
operand-provenance census, run on the `NOZ05` rig, names for every output-stage operand the array,
the index and the `iw` that last wrote it: **`F1` = 0 of 14** trace to body 0; the only body link is
`w65 ← iw332` via `m_rf[0x8F]`, 540 000/540 000, **value zero**; `w73`'s producer is kernel-B `iw54`
at **100.00 %**; and the **entire 18-row census is byte-identical between the shipped build and the
rig** while body 0 runs at `28/32/28`. ★ **§222 tested it the hardest way available — by opening a
link — and `F1` is STILL 0**, because the operand the crossbar delivers has provenance `iw11`
(kernel A), not body 0. ⇒ §221 survives its own attempted refutation.
★★ **A PROVENANCE CENSUS MUST REPORT AND GRADE ALL THREE COLUMNS** (last writer / last non-zero
writer / last writer that CHANGED the value): §221's first build graded on one and produced a FALSE
ABSENCE. ★ **PRE-REGISTER THE ROW COUNT** — `E1_SLOTS = 24` silently dropped two handover rows.
★ `§70`/`§211` print **MEAN and AC SPAN** (standing rule 19, mechanised).

### ⛔ 1.-0-prev-220 — §220's headline, SUPERSEDED as the task, TRUE IN EVERY PART

**§220 DECIDED THE SEND BY EXPERIMENT. CELL `0x05` **IS** BODY 0's INPUT PICKUP:** suppress the two
kernel-A stores that overwrite it (`iw35`, `iw45`) and body 0's `§104` columns go from `0/0/0`
input-dependent slots to **`28/32/28` — slot for slot IDENTICAL to the §215 `SRC0B2` calibration
arm** — the delay line fills (`§46` non-zero reads **0 → 3 494 021**, `§75` writes-with-content
1 175 999 → **2 351 009**), and `§70`/`§211` are **STILL `min == max == 0`**.
⛔ **AND MASK BIT 26 IS DEAD-END 30.** It **fired 5 881 351 times** (5 per kernel-A pass, exactly as
predicted from the words: `iw19/21/27/33/39`, and *not* `iw72`, whose mode is 1) and moved `iw84`
**not at all** — every mirror site is upstream of `iw45` — while making kernel A **strictly worse**
(`acc 27→22, mem 21→10, L 18→12`) through a cross-frame path via cell `0x06`. **Never flip it.**
⚠ §219 §8's own reading — *"a null would mean the gate never fired"* — is **WRONG**.

★ **THE SEND'S REMAINING QUESTION IS THE STORE'S DATUM, NOT ITS ADDRESS.** Why does the kernel
write `0x05` four times a frame — `iw9` (constant `5 084 004`), `iw11` (**the real deposit**),
`iw35` (constant `4 194 304`), `iw45` (`0`)? The pointer walk that lands on `0x05` is deliberate
(`iw32`: `dp 07→06`, `iw34`: `dp 06→05`), so *"the pointer is one cell low"* is not available.
★ **The live candidate:** the bit-4 store writes the **PRE-update** accumulator (verified —
`iw39` stores `acc_to_datum(130 485 107 904) = 1 991 044`, `iw38`'s post-value). At `iw35` the
**POST-update** accumulator is `908 714 800 127 ‖ 227 691 099 135..1 125 285 262 335`, **INPUT
DEPENDENT** — so a post-update store would make `iw35` DEPOSIT audio instead of destroying it.
⚠ `iw45`'s post-value is still the constant `538 760 587 509`, so this does not finish the job
alone. **Two-sided arm, default OFF, fired count. Do not adopt it on the model.**
⛔ **CLOSED as a candidate:** `§109`'s CO-EQUAL bit-4 store gate (mask bit 29, `b7 && f31 != 2`).
**Neither `iw35` nor `iw45` carries bit 7**, so `guard7_would_refuse()` is false under *both*
readings.

**`UPD6383_NOZ05` stays DEFAULT OFF and so does `UPD6383_DRPUB` and `UPD6383_EPIBUS`.** NOZ05
deletes two stores the corpus says are there and its cell `0x05` **rails** (`§86` quiet
`[8 388 607 .. 8 388 607]`, the positive 24-bit rail with no notes playing — §176's warning, third
occurrence). DRPUB has a measurable consequence only with NOZ05 on (§220 arm D). EPIBUS is a
read-only census whose shadow tables should not be maintained on a shipped run.

### ⚠ 1.-0.2 WHAT §220 CORRECTED IN THIS FILE

* ⛔ ~~"the instrument may already exist: mask bit 26"~~ — it existed, it ran, it is **dead-end 30**.
* ⛔ ~~"is `iw35`/`iw45` storing to the wrong cell, or is cell `0x05` not the pickup?"~~ —
  **ANSWERED: cell `0x05` IS the pickup**, `base = 0x05 | unit<<7` is CORRECT.
* ⚠ **rule 8, SHARPENED.** `m_mirror06_n` had a counter *and* a `logerror` and still made "0 fires"
  indistinguishable from "never ran", because the print was inside `if (m_mirror06_n)`. **Print
  fired counts UNCONDITIONALLY, with the arm's own flag beside them.** Fixed for `§106` this pass.
* ★ **The mask-bit audit is now a tool**, `dsp/tools/bit26_audit.py`: it parses the C++ with
  comments and string literals stripped, enumerates every mask literal, counts the sites that test
  a given bit and checks the fired count is emitted. **Run it before arming any bit.**

### ⛔ 1.-0-prev-219 — §219's headline, SUPERSEDED as the task, still true in every part

**§219 located the send at D-RAM cell `0x05` and named `iw35`/`iw45` as its killers, statically,
from five existing logs. §220 confirmed every part of it by intervention.** `SRC 0x0B` at `iw25` is
DECIDED (dead-end 28: no `SRC` on the send path decides a stored value — both stores take
`acc_to_datum(m_acc)`), and "the delay line is EMPTY" is IMPRECISE (dead-end 29: `§75` counts
1 175 999 writes with content on the shipped build).

### ⛔ 1.-0-prev — §218's headline, SUPERSEDED as the task, still true in every part

**§218 refuted the CROSS-FRAME rival with NO run: `DRPUB`'s `age 0` is NOT wrong by one frame, and
`ENSEMBLE w62` was never an `SRC 0x0B` word (its `lo12 0x40B` carries `SRC 0x10` = the ACCUMULATOR;
the `0B` is the ACTION field). The corpus population is 7, not 9, exactly as `upd6383.cpp`'s own
`case 0x0B` comment has said since §215. With `w62` removed, `dram-datapath.md` item A + a hold
register explains 7 of 7 and §217 §5's "honest residue" is EMPTY.**
⇒ `iw25`, the `§78` schedule, the line index, `m_dr`'s width and the class-2 `SRC 0x0B` decode are
**all closed** (§215–§219; dead ends 21–28). **Do not open any of them again.**

**⛔ §217 (superseded as the headline, still true in every part):** the datum `iw12` fetches is NOT
LOST — it is published, intact, to `iw98`, on 540 000 of 540 000 settled frames. The `§78` per-line
schedule is CORRECT and the LINE INDEX is a RED HERRING: `§46`'s descriptor dump is an UNGUARDED
BOOT-TIME SAMPLE and `§204`'s guarded census — in the same log — gives the kernel three distinct
lines with `iw12 ↔ iw98` paired exactly as `§79` says.

★★ **THE METHOD LESSONS, and they are the expensive ones:**
* **rule 18 (§218):** grade a field census with the disassembler's own accessors
  (`dsp_disasm.lo_src` = `lo12[10:6]`, `lo_act` = `lo12[4:0]`), never by eye and never by the
  `lo12` string — **11** distinct `lo12` values occur on both class-1 delay words and class-2 words.
* **rule 13, third occurrence (§219), and the most expensive yet:** `upd6383.cpp`'s `kwatch()` note
  asked, at **§110**, *"something overwrites cell 0x05 between deposit and pickup — name the
  writers, in execution order"*. The census it asked for has printed `iw9 / iw11 / iw35 / iw45` in
  **every log since**, beside a `§104` column showing the `4 194 304 → 0` collapse. 109 sections
  passed with the answer in the report. ⇒ **read the report the build already prints — all of it —
  before designing anything.**
* **rule 3, fifth occurrence (§219):** the task in this file was **four sections stale** at the
  moment it was written down. Before building on a §-numbered claim, check the sections that came
  after it.

### ★★★ 1.-1 READ THIS BEFORE PLANNING — §216, §217 AND §221 TOGETHER BOUND WHAT IS LEFT

* ★★★ **§221 SUPPLIES THE MISSING TERM: the epilogue's operands are DISJOINT from the signal
  path.** `§E1`, run on the rig, gives every output-stage operand its array, its index and its last
  writer: `F1 = 0 of 14` trace to body 0, the only body link is `w65 <- iw332` (`m_rf[0x8F]`,
  540 000/540 000, **value zero**), `w73`'s producer is kernel-B `iw54` at **100.00 %**, and the
  **entire census is byte-identical between the shipped build and the rig** while body 0 runs at
  `28/32/28`. ⇒ the output stage is not losing a signal it receives; **it receives none.**
* **The output stage is a NULL independent of the send** (§216: send forced open, body 0 ran its
  whole ladder on live audio, `w73`/`w78` still `min 0 max 0`). §217 re-measured it in **three**
  more arms including the no-stimulus window: still `min 0 max 0`, all six readings.
* **`UPD6383_DRPUB` (new, env, DEFAULT OFF, fired count 24 922 560) makes `iw25` receive `iw12`'s
  datum** — provenance `iw12`, age 0, 540 000/540 000 — and on the shipped build it is
  **BIT-IDENTICAL to the control in every column**, because the datum it correctly delivers is
  **zero**. Not shipped: a default flip with no observable consequence is a claim, not a fix.
* ⇒ **The chain is: right datum now deliverable → it is zero because the delay line carries no
  audio → the line carries no audio because the bodies write zero → the bodies write zero because
  the unit-0 input cell `0x05` is zeroed by `iw45` after `iw9`/`iw11` deposited the audio in it
  (§219) → and even forced open, the output stage is a null (§216).**
  Every link is MEASURED. Do not re-derive any of them.
  ⚠ **§219 corrected two links of the older phrasing**: the line is *not* unwritten (`§75`:
  1 175 999 writes with content) and the send is *not* a `SRC` decode (dead-end 28).

### ⛔ 1.-0.5 ANSWERED BY §218 — kept only so the closure is legible

⛔ **The paragraph below is the question §217 handed forward. §218 answered it with NO run and NO
rebuild; see §1.-0 above for the verdict. Do not re-open it.**

~~**Decide `ENSEMBLE w62` and `kernel iw25`** — the two `000.2.00.*` class-2 `SRC 0x0B` words that
sit a couple of slots *AHEAD* of a delay READ rather than after one. §217 §5 censused all 9
class-2 `SRC 0x0B` words … If the pipeline is one-deep and **cross-frame**, then `DRPUB`'s
`age 0` is wrong by exactly one frame.~~ ⇒ **There are 7, not 9; `w62` is not one of them; the
rival is REFUTED; `age 0` is RIGHT.**

★★ **THE METHOD LESSON, and it is the expensive one (standing rule 18, new):** §217 §5 re-derived
in prose a census that `upd6383.cpp`'s `case 0x0B` comment had carried correctly since §215, and
got a different number by reading `lo12`'s **ACTION** field as its **SOURCE** field. **Grade a
field census with the disassembler's own accessors** (`dsp_disasm.lo_src` = `lo12[10:6]`,
`lo_act` = `lo12[4:0]`), never by eye and never by the `lo12` string — **11** distinct `lo12`
values occur on both class-1 delay words and class-2 words (`src0b_census.py pairs`).

### ⚠ 1.0 VEHICLE: TWO traps, both of which have now cost a run each

1. **`-cfg_directory` MUST CARRY `:DSPCFG value="3"`.** `DSPCFG` is a `PORT_CONFNAME` defaulting
   to **Off**, so a *fresh* cfg directory executes **zero DSP frames** and `device_stop()`'s
   `if (m_frames_run != 0)` prints **no report at all**. Copy `kn7000-emulator/cfg/kn5000.cfg` in.
2. **★ PASS `-log`.** The whole `upd6383:` report goes through `logerror`, which MAME discards
   unless `-log` is given. A silent stderr with `exit=0` and a normal `coldnotes2` trace is THIS,
   not a crash. (§215 lost a run to it exactly as §213 lost one to `DSPCFG`.)

Working recipe:

```
  cd kn7000-emulator && UPD6383_SRC0B2=0 timeout 900 ./kn7000 kn5000 -rompath ./roms \
      -skip_gameinfo -log -nvram_directory <iso>/nvram -cfg_directory <iso>/cfg \
      -pluginspath ./plugins -autoboot_script ../kn7000_mame/scratchpad/coldnotes2.lua \
      -seconds_to_run 30 -window -resolution 640x480
  # error.log is written into the CWD; copy it out before the next run.
```

### ★★★ 1.1 WHAT §215 ESTABLISHED, AND WHAT IS LEFT

**The decode is right (MEASURED, corpus, 41 listings / 3057 words):**

```
   lo12 0x2D9 = SRC 0x0B + ACT 0x19   36 words: 29 delay WRITE, 6 delay READ, 1 = kernel iw25
   word 0012201655 = `mac ta,(p)+1'   13 sites, base rate 0.43 %
   C1  13 of 13 sites of 0012201655 are IMMEDIATELY preceded by a class-1 addr8 0x20 DELAY READ
   C2  ENSEMBLE w10 (880.1.20.2D9) -> w11 (0012201655)      read AND capture fused
       KERNEL   w25 (000.2.00.2D9) -> w26 (READ) -> w27     capture split off, SAME successor
```

⇒ `iw25` is grouped **by its successor** with ENSEMBLE's six class-1 delay reads. The rival would
need one lo12 to mean two things on two classes **and** would leave the kernel's two delay READs
(`iw12`, `iw26`) with no consumer at all. **REFUTED. `UPD6383_SRC0B2` stays default OFF.**

**⛔ AND THE FOUR FALSIFIERS ARE RETIRED AS A TEST.** All four passed under the rival — `tempA`
at `iw25`, `P` at `iw39`, the last input-dependent `acc` slot (`iw38` → **`iw204`**), and body 0's
`iw84`/`iw85`. They had to: arm A's own counter measured `mem[ptr]` at `iw25` non-zero on
**313 169** evaluations ≈ the **313 960** loud frames, *before the rival ever ran*. **They grade
"is the operand alive", not "is the operand `mem[ptr]`".**

**★★★ AND THE ONE RESULT THAT OUTLIVES THE REFUTED READING:** with the send FORCED open, body 0
ran its whole ladder on live audio (28 input-dependent slots), fed body 1 (2 slots) — and
`§70 ACCA at w73` and `§211 ACCB at w78` were **still `min 0 max 0`, quiet and loud**.
⇒ **The output stage is a null INDEPENDENTLY of what the send carries.** §211 could not prove
that; §215 did, by feeding it.

### ⛔ 1.2 — ANSWERED AND RETRACTED BY §217. Kept only so the retraction is legible

⛔ **The paragraph below is WRONG in its diagnosis and its remedies, and §217 measured each out.**
(a) `iw12`'s datum **does** reach a consumer — `iw98`, 540 000/540 000. (b) It is **not** the line
index: `§46`'s `0000` descriptors are an **unguarded boot-time sample**, and `§204`'s guarded
census gives the kernel three distinct lines with `iw12 ↔ iw98` correctly paired. (c) Widening
`m_dr` is **MOOT** — nothing overwrites it between `iw12` and `iw25`; the fault is *when* it is
written (only at a delay word, and `iw25` is not one), not *how many* registers there are.

### ★★★ 1.2 (superseded) THE NEXT EXPERIMENT — the §78 publish, and the number that names it

```
   arm B  §46  24 922 560 reads, 181 521 returned NON-ZERO
          §80  latched 24 922 560 (181 521 nz) | publish hits 24 922 552 (181 521 nz)
          §215 m_dr non-zero AT iw25:   0 of 1 211 520        <- the whole blocker, in one line
```

Non-zero data are latched and published into `m_dr`, and `iw25` never sees one. `m_dr` is a
SINGLE register and `line = descriptor_value & 0x3f`; §46's dump shows the kernel's own
descriptors resolving to `0000`, i.e. **every kernel delay word shares line 0**. So every non-zero
publish lands at a body delay word *after* `iw25` has run, and a zero publish overwrites `m_dr`
before the next frame's `iw25`.

**Ask, in this order:** (a) does `iw12`'s datum ever reach `iw25` — instrument the publish that
immediately precedes `iw25`, per frame; (b) if not, is the fault the **line index**, the
**ordering**, or the **single register**; (c) only then consider widening `m_dr`.
⚠ New gates are **env vars, default OFF, with a fired count** — the u64 spec mask is EXHAUSTED.
⚠ And none of it is audio until `§70`/`§211` show `min != max` **and** a no-stimulus window is
measured. §215's arm B is the standing proof that a live send is not enough.

### ⛔ 1a. DO NOT RE-OPEN — closed by §213

* **"`iw39` stores TWICE to cell `0x06`, and the second store wins" (§211 §6) is RETRACTED.**
  The site-3 record was a **PHANTOM**: `upd6383.cpp`'s ACT-0x07 site had an **unbraced `else`**,
  so `kwatch`/`watch_store`/`store_probe`/`m_dwr` ran on every VISIT while §112's latch arm
  (mask bit 25, ON) stored nothing. Fixed under `UPD6383_STPROBE` (default 1); fired count
  **3 630 720 = the §112 latch count exactly**. `iw32`/`iw34` now print `(NO STORE)`.
  ⇒ *"suppress one of the two stores"* would have been a **no-op on the machine**.
* **Prerequisite (a) — "does `HI_ST` + `ACT 0x07` do two stores?" — is MOOT twice over.** The
  ACT-07 arm stores nothing on a class-A word, and its `P` write is overwritten by the class-A
  **multiply** in the same word (`pw` reads bit 6 = THE MULTIPLY at `iw39`, not bit 5).
* **Prerequisite (b) — "why is `tempA` empty?" — is ANSWERED.** It is not empty; it is **zeroed
  at `iw25`**. A correct consequence of §48, not a decode hole and not the `SRC 0x13` shape.
* **`iw35`'s store is not a defect.** Store-then-re-read is an ordinary idiom, and the input is
  not lost by it: `iw39` parks the last input-bearing accumulator in cell `0x06`, which the NEXT
  frame's `iw13`/`iw14` read back (§213 §5.2). ⚠ But §176 says it is at the **24-bit rail** on
  all but ~1100 of 1 440 001 frames.
* **§98's `06w` understates.** `pwatch()`'s read hook sits only on the anchored `SRC 0x07`
  evaluator, so `SRC 0x00` reads are invisible to it. Do not read "cell X is write-only" off §98.

### ⛔ 0a. DO NOT RE-OPEN THE OUTPUT STAGE. Every branch of it is closed by §211

* **`w73` is NOT where the accumulator dies.** On the shipped build the epilogue's accumulator is
  the **constant `2 603 010 048`** from `w54` to `w64` and **`0` from `w65`** — eight slots before
  `w73`. §141's table was measured with **mask bit 55 (the §138 guard) ON**; that bit is 0 in the
  default and **fires 0 times**. ⚠ And what `w73` would have destroyed under that arm was a
  **constant in quiet and loud alike** — standing rule 1's exact shape.
* **`w73`'s store FIRES and writes ZERO** (`[site2 addr 00 val 0..0 x1 020 000]`, the §109 probe
  finally aimed at slot 73 as §150 §4 asked 60 sections ago). ⇒ §150 §3's *store-and-clear* suspect
  is **MOOT, not refuted**: there is nothing to clear, the destination cell `0x00` is read by
  nothing, and all three of §150's rival readings produce the same observable on a zero datum.
  **No experiment at this word can separate them.**
* **`w78` / ACCB is a hard zero too** — §211's new probe, the unit-1 half measured for the first
  time: `ACCB AT w78: quiet min 0 max 0 | loud min 0 max 0`. So the `A3C.D.9F.287` decode is not
  between the chip and audio either, and `bit11-family.md` item B's undecidability is now not just
  true but **irrelevant**.
* ⚠ **`§48` — HALF-RETRACTED BY §213. It IS in the send path; it is still not enough on its own.**
  §211/§212 called it "a symptom, not a gate". §213 §4 MEASURED that `iw25` reads it straight into
  `tempA`, which is what the unit-0 send at `iw45` ends up carrying — so it is **upstream of the
  send**, not downstream of it. What survives: 95.04 % of delay writes write **0**
  (`1 175 999 of 23 693 760` with content) and the other 5 % write the **constant `0x7D70`** =
  `acc_to_datum(538 760 587 509) >> 8`, which is `acc` at `iw45`, which is that same zero one hop
  later. **The path is a CLOSED LOOP of constants**, so opening §48 alone still delivers a DC.
  The way in is the `iw25` **decode**, §1.2 — not the delay port.

### ⛔ 0b. SUPERSEDED BY §213 — this block's "one gradeable lead" was a PROBE ARTEFACT

It read: *"`iw39` stores TWICE to cell `0x06`, and the second store wins"*, and set two
prerequisites. **All of it is closed; see §1 above and §213.**

* the site-3 record was a **PHANTOM** (unbraced `else`; the §112 latch arm stores nothing).
  MEASURED both ways: the fixed probe prints `(NO STORE)` at `iw32`/`iw34`, fired count
  **3 630 720 = the §112 latch count exactly**; and §211's own log already proved it — `iw34` was
  logged storing `8 388 607` to `0x06` while §104 shows `0x06` still holding `6 039 795` two
  slots later.
* prerequisite **(1)** is MOOT twice over; prerequisite **(2)** is ANSWERED — `tempA` is **zeroed
  at `iw25`** by the delay-read register, a correct consequence of §48.
* and the "destroyed before the body runs" framing was wrong in one place: cell `0x06` is a
  **cross-frame carry** read by the next frame's `iw13`/`iw14`, not a dead deposit.

### ⛔ 0. DO NOT RE-OPEN THE DESCRIPTOR BASE — every branch of it is closed

* **A base REGISTER is dead by arithmetic** (§207 §2 / `data/DSCBASE_findings.md`):
  `base_u = s·F_u + b (mod 256)` cancels `b`, so the test is `s·d ≡ 38 (mod 256)`, solvable iff
  `gcd(d,256) | 38`. `38 = 2·19` ⇒ `d` odd or `≡ 2 (mod 4)`. `0x827` (`d=8`), `0x821` (`d=32`),
  `w45/w53 addr8` (`d=48`) — **all impossible for any integer scale**. Also dead: the body's own
  first D-RAM word and the host write pointer.
* **What shipped instead**: a per-unit **ring** on the one shared cursor, `[0x00,0x26)` for unit 1
  and `[0x26,0x40)` for unit 0, the unit taken at the CALL. `UPD6383_DSCPRE` and `UPD6383_DSCRING`,
  both default ON, both with fired counts.
* ⚠ **RING vs a HARDWIRED TWO-ENTRY BASE TABLE is TIED and NEITHER is claimed.** Separating them
  needs a unit-1 block longer than 38 cells; the corpus maximum is 32. **Do not try to break the
  tie with this ROM — it cannot be done.**
* ⚠ **FREE, and no run can move them:** `L₁ ∈ 0x20..0x26`, `B₀ ∈ 0x00..0x26`, `L₀ ∈ 0x3A..0x41`.
  No shipped algorithm reaches any bound.

### ★ 1. §202 IS RE-BASELINED — quote the NEW numbers

```
   published (mislabelled)   dsc 28 -> 0..4161      dsc 30 -> 0..3120
   same machine, labels fixed cell 27 -> 0..4161     cell 2F -> 0..3120   (0x2F was BODY 1's)
   SHIPPED, ring ON          cell 27 -> 0..4401     0x2F gone from unit 0 entirely
```

and unit 1 has **fifteen delay lines where it had none**, `7.6 .. 780 ms`. §202's *conclusion* (the
rotation sweeps down) stands and is strengthened. ⛔ `age = R − W` is an **identity**, not a test —
do not score "the age equals a ROM cell difference"; only *which* cell it resolves to is
informative (7 of 15 land inside unit 1's own block).

### ⛔ 2. SUPERSEDED BY §211 — this section's task is DONE and its framing was wrong

It read: *"the two live questions are why a resolved delay read still returns zero data and what
`w73` does, in that order."* **Both are answered and neither is live.** `§70 ACCA min 0 max 0`
still holds, and `§211 ACCB AT w78 min 0 max 0` now holds beside it — but the cause is not in the
output stage and not at the delay port. See §1 above. ⚠ The `PRE=0 RING=1` arm remains a
**degenerate** line (it reads back the same frame's own write at zero distance); that warning
stands.

### Also still open, unchanged

per-unit **CALL VECTORS** written and read by nothing (controls: four Sub CPU ROM constants;
cold-boot capture → 84/42, 200/50) · the five **MALFORMED** streams `{79,88,89,90,91}` = programs
for the **second** DSP (MN19413/IC310), which Felipe wants inspected · `f31 = 4/5` is
**UNDECIDABLE** with existing instruments and `f31 = 4` fires **zero** times in the clean vehicle.

### ★ SHIPPED in the §188–§209 session — SEVEN, all from the PROVEN-BY-CONSTRUCTION audit, each with a control

⚠ **DO NOT QUOTE THIS AS THE PROJECT TOTAL.** It is one session. The authoritative enumerated list
is **derived, never counted**: `python3 dsp/tools/gen_fixlist.py`. As of 2026-07-31 it reports
**8 forced GATES across 11 SECTIONS** (denominators: 19 `getenv` sites — 7 bool gates default
`true`, 6 default `false`, 6 non-bool knobs at baseline; 258 `logerror` calls; 119 register
sections). ★ **A shipped-fix count is meaningless without its UNIT**: §209 ships two gates, §200
and §202 share one. That ambiguity is why this figure has been published as five, seven, "7 of 7",
eight and nine simultaneously. ⚠ §228 adds one more **default-behaviour** change that is not an
env gate at all (the 44 100 Hz frame clock) — re-run the tool rather than incrementing anything.

| § | what | control |
|---|---|---|
| **188** | host payload LSB (default `0xB910E446A39B440F`) | LFO sine: max err 2→1 LSB, RMS 1.291→0.707 = 1/√2 |
| **197** | accept `0x0B` poke packets (leading nibble is a flag) | 2 recovered values bit-exact vs the descriptor space |
| **201** | per-body descriptor index | delay lines got LENGTH: `0..0` on every line → 240/480/640 |
| **202** | rotation **sweeps DOWN** | delays = the ROM's own cells — ⚠ **numbers RE-BASELINED by §209**, see §1.1 |
| **204** | `C40.1.80.000` consumes a cell | consumer-to-cell census: a duplicate-cell collision removed |
| **208** | the §204 probe stops printing a derived cell label | §207: it was `+1` for every body consumer |
| **209** | ★★★ the **per-unit descriptor RING** | body 1's census **0 of 16 → 16 of 16**; all four arms bit-exact vs a pre-registration committed before the build; the null said **no** |

⚠ **The u64 spec mask is EXHAUSTED.** New gates are env vars + fired-count:
`UPD6383_ROTSIGN` (ON), `UPD6383_BODYIX` (ON), `UPD6383_CFMTIX` (ON),
`UPD6383_DSCPRE` (ON), `UPD6383_DSCRING` (ON).

### ⛔ Two long-standing tasks CLOSED by §205 — do not reopen

* **"Fix the `SRC 0x08` clobber"** — **not real as named**, wrong four ways; §111 §3 had already
  retracted the attribution and the title outlived it by 93 sections. The store writes the
  **accumulator**; `SRC 0x08` is not in that datapath. `iw45` **is** the unit-0 send (FORCED, 37×),
  59 of 71 candidate stores are the LFO idiom, and "rails" is a `peq_gain` vehicle artefact.
* **`f31 = 4/5`** — **UNDECIDABLE** with existing instruments; for four of six readings nothing
  outside the emulator depends on the choice. ⚠ `f31 = 4` **fires ZERO times** in the clean vehicle
  (§205) — any experiment needs a vehicle that exercises it. ★ And `f31-high.md` §6's "14/14 linear"
  is **circular**; the a-priori replacement gives 69 of 97 vs 36.4, p = 8.4e-12.
  ★ SPECULATIVE, worth keeping: 46 % of the `f31=4/5` population is operand-free, and for
  `f31 = 0/1/2` those are the three **MAC writeback modes** ⇒ the shipped `{LOAD,ADD,HOLD}` space is
  categorically wrong for 45 words.

### Then

per-unit **CALL VECTORS** written and read by nothing (controls: four Sub CPU ROM constants;
cold-boot capture → 84/42, 200/50). ⛔ *"the OUTPUT STAGE — still silent, localised to `w73`"*
is **CLOSED by §211**; see §1.

### ⛔ Dead, do not retry

















 — all three cost a pass

* kernel `iw32` / any `DRAM_UNIT_BASE` value (§108 §5 FORCED; bit 27 bit-identical) — and it is
  aimed at a symptom this build no longer has.
* **bit 18** (`SRC 0x11 = mem[ptr]`, §113): TESTED at last (§168) — fired **9 279 912** times and
  `m_tb` is unchanged. Swapping the source moves *which* constant arrives, not whether it is
  constant. Not inert (`06: chg 1100 -> 2`) but not shipped.
* **bit 54** alone (latch to `m_k`): **bit-identical to the control in every cell.**
* **bit 54 + bit 4** (§136's *"never evaluated together"*, now discharged): `§70 ACCA min = max =
  176 471 605 248`, the exact DC §137 retracted. Standing rule 1 caught it.

### Then K2 is four lines. Pre-register these — already computed

```
  peak excursion  226, NOT 240     <- table peak is 0.9452541, not 1.0
                                      226 kills "no table";  240 kills "sine"
  DEPTH 30 -> +/-36 samples        DEPTH 99 -> +/-120       (30/99 = 0.30303030, seven digits)
  rate 0.599 Hz
```

### ⛔ THREE RETRACTIONS — do not build on any of them

```
  §155  "the delay tap SWEEPS +/-240"     WRONG -- the census pooled voices of opposite sign
  §157  "each voice RAMPS 0 -> depth"     WRONG -- boot transient inside an undeclared window
  §158  TRUTH: the tap-mod is CONSTANT per voice.  Nothing moves, because the lookup is a no-op.
```

`§104` over the settled window, quiet **and** loud identical:
`iw96 15729946 | iw105 15729540 | iw137 −15727740 | iw146 −15727740` — **all min == max.**

### The mechanism, MEASURED end to end (this part stands)

```
  LCD "DEPTH 30" -> op 0x66 -> C-RAM[0x09]=[0x0A] = 0x1364D8
                    = 0.30303 x the ROM base,  and 30/99 = 0.30303030 (7 digits)
  -> iw123 acc = DEPTH x LFO -> D-RAM 0x0F ; iw126 -> 0x0E ; iw132 -> 0x10
  -> the tap idiom's word [1] reads D-RAM 0x10/0x0E/0x0F as its BUS operand
  -> word [3] `C40.3.20.44C` applies it to the delay-tap address
```

With the lookup working, expect **±36 samples at DEPTH 30** and **±120 at DEPTH 99**, sweeping at
0.599 Hz (73 584-frame period) — three independent ways to fail. And under the sine table the peak
must be `0.9452541 × depth`: **226, not 240**, which is two-sided.

### ⚠ A SHIPPED READING IS IN TENSION (§158 §3)

The four taps read `dp = 0x10/0x10/0x0E/0x0F` — exactly the cells the DEPTH block writes — and
§145's *"rail and unrelated residue"* `8388607/8388607/671/203` are, for the last two, **the
outputs of the two DEPTH multiplies.** So `SRC 0x00 = coef` may be wrong **at these four slots**.
It is SHIPPED (bit 59). **Not un-shipped**: the 29/29 corpus twin is independent, and the class-A
cursor fetch supplies ±240 to `K` regardless of `SRC`. The working lookup decides it.

## 1a. Still open, and untouched by any measurement

The **1262-word class-2 `SRC 0x00` majority** — 78 % of the population. `coef` is wrong there by
construction (a class-2 word consumes no cursor coefficient, so `C-RAM[cursor]` returns whatever
the last class-A word left), and §143 §5 established that the constraint which once narrowed
`SRC 0x00` to `{mem[ptr], acc}` is **VOID**.

### Superseded scope note (§145/§146)

§145 decoded it: at CHORUS's four LFO twins the operand bus becomes **+240/+240/−240/−240**,
bit-exact, predicted before the run from the live C-RAM, with the anchored `SRC 0x08` control
unmoved and a fired-count of 15 540 204. Chance of a coincidental 24-bit match at four slots
is 2⁻⁹⁶.

⛔ **But applied to all 1610 `SRC 0x00` words it RAILS unit 1** — DO2 98.9 % non-zero at
+8 388 607, DC leak 99.94 %, against the default's 41.2 % / +1 543 433 / 34.64 %.

★ The class split explains both, and is the live hypothesis:

```
  SRC 0x00 by class:  class1 233 | class2 1262 | class8 4 | class A 111   (of 1610)
```

Only **111** are class A — the coefficient consumers. **The twins are all class A.** A class-2
word consumes no cursor coefficient, so `C-RAM[cursor]` there returns whatever the last class-A
word left: stale residue, which is exactly the shape of a corpus-wide rail.

**Mask bit 58 gates the read on `coeff_consumer(word)`; the arm `0x510E446A39B440F` was running
when this was written** — see `data/PREDICT_146.md` for its three pre-registered predictions
(fired-count falls sharply; ★ the twins are UNCHANGED, the known-answer control; ★ the railing
stops) and its falsifiers. If P3 fails, class is not the discriminator and `coef` may be wrong
generally rather than merely over-applied.

`SRC 0x00` is worth this care: **1270 words across all 91 programs, three times the next
blocker**, and it is **PARAMETRIC EQ's entire remaining blocker set** (§143 §6).

## 1b. The two standing open items, neither of which is the above

* **★ `w73` erases the accumulator at the door (§141).** The body's result now reaches the
  epilogue intact, and `w73` — `0E30C00404`, class 0xC, so `coeff_fetch()` is TRUE — fetches a
  coefficient and then loads the accumulator from a product **that is never formed**, so `P = 0`
  and the LOAD is an erasure. This is the third instance of ONE defect (kernel `iw47`, epilogue
  `iw65..72`, `w73`), and §39's *"what enables the MULTIPLY, as distinct from the fetch"* is its
  single root cause. **This is what keeps unit 0 silent.**
* **★ Unit 1's railing is VEHICLE-DEPENDENT (§148, correcting §143 §2).** In a **clean**
  vehicle — cold boot, notes after the ~19 s boot settles, no panel navigation — `iw330/331/332`
  are `0..0` in quiet *and* loud, and **both units present 0 non-zero** with 313 960 loud frames.
  The rail appears only in the `peq_gain` vehicle, which drives the panel for ~40 s and uploads a
  different effect at every TYPE step (~55 program loads mid-run).
  ★★ **STANDING RULE: report audio statistics from a CLEAN vehicle** (`data/PREDICT_148.md`'s
  setup; harness `scratchpad/coldnotes2.lua`). Use the navigation vehicle only when the experiment
  needs a *selected* effect, and then only for **deltas** — a shared contaminant cancels in a
  delta but not in a characterisation. Every DO2 / DC-leak *absolute* number in §§135–148
  describes the vehicle, not the chip.

## 1c. ⛔ RETRACTED — do not build on these

* §135 §4's *"the reverb pairs read loop state"*: `+75/+8/+123` are the signed pointer
  POST-INCREMENTS, not addresses. All three read `dp = 0x85`, unit 1's input latch, measured
  `0..0`. The "feedback ladder" framing is gone.
* §135's *"not shippable"*: the railing was **my own unit-blind accumulator write** (§143 §3).
  The §133 readings are **SHIPPED** — default `0x110E446A39B440F` (§144).
* §131's *"every word of the bank entries carries `f31 = 0`"*: the entries hold **thirteen**
  words, five with `f31 ∈ {1,4,5}`. The conclusion survives (`w4`/`w57` are `f31=0`); the
  argument did not.
* §123's `SRC 0x00` device comment cites `action00-discriminator.md` item I, which
  `adjudication-round6.md:605` had **VOIDED**. `SRC 0x00` was never narrowed to `{mem, acc}`.
* The `m_p` two-registers suspect (§136/§137): there is no split to make — `m_k`/`m_l` are the
  input latches and `m_p` the product register with one functional read. §40 stays refused
  (DC leak 34.69 % → 99.79 %).

## 2. What is already done, so you do not redo it

* **PEQ is selectable from the panel** (`dsp/tools/peq_gain.lua`, all MEASURED):
  `CPR_SEG3 0x04` DSP EFFECT on → `CPR_SEG10 0x04` SOUND → `CPL_SEG7 0x02` DSP EFFECT editor →
  40× `CPL_SEG10 0x10` (saturate to CHORUS) → 15× `CPL_SEG10 0x20` (up to PEQ).
  **PARAMETER down/up = `CPL_SEG8 0x10 / 0x20`; VALUE up = `CPL_SEG7 0x20`.**
  ⚠ `CPL_SEG8 0x80` is NOT PARAMETER and `CPL_SEG10 0x80` changes the *effect*.
  Boot settle ≈ 19 s emulated; use `-seconds_to_run 80`.
* **The frame trace can now see it.** It armed unconditionally at frame 420 000 (≈ 8.75 s) while
  PEQ lands at ≈ 50 s, so *every* trace ever taken of "PEQ" was a CHORUS frame.
  `UPD6383_TRACE_FRAME` sets the arm frame; 2 300 000 lands inside the held note.
* **The coefficient chain is verified**, most strongly by `dsp/tools/peq_roundtrip.py`: the ROM
  designer run forward in **float32** from the panel-stated (f0, Q, gain), scored per word —
  13 of 15 band-instances within **13 LSB of 2²⁴**, 75 words, zero free parameters.
* **Three live captures with known panel settings** are in `dsp/tools/peq_ab.py`: FLAT, FC16K
  (both exact pass-throughs — the measured null) and **G12**, the only discriminating one
  (+12 dB, Q 2, at 125 Hz). That is §128's target and it still stands.
* **The static pointer walk is confirmed live at 13/13 slots.** Bank state bases `0x50` and
  `0x64`, disjoint. ★ And **both banks read the same input cell, D-RAM `0x05`** — the "two
  channels must read two different inputs" expectation is FALSIFIED.

## 3. The four unknowns, and the one thing that changed about them

`ACT 0x0D`, `ACT 0x0E`, `f31=4`, `f31=5`, all inside PEQ's two five-word bank entries
(iw84–88 and iw134–141). **Move them together** — §121 failed by varying one while three others in
the same block were guesses.

⚠ **They are not trapping today.** With mask bit 0 set (it is), `op = f31 & 3`, so `f31=4` executes
as HI_ACC_LOAD and `f31=5` as HI_ACC_ADD; `ACT 0x0D`/`0x0E` both fall into the blanket tempA
capture. **There is no fired-count for any of this**, in violation of the project's own rule. So
any enumeration must A/B against the *alias*, not against a trap — and the alias means bank 1's
`w1` (ACT 0x0E) immediately clobbers what `w0` (ACT 0x0D) wrote.

## 4. Build / run

```
  cd ~/compartilhado/kn7000_mame && ./build.sh
      *** EXITS 0 EVEN ON COMPILE FAILURE *** -- grep for "error:" AND check
      ls -la ~/compartilhado/kn7000_mame_build/kn7000   (fresh, >70 MB)
  ./tools/publish-binary.sh
  cd ~/compartilhado/kn7000-emulator && export DISPLAY=:0 && rm -f error.log
  UPD6383_SPEC=<hex> UPD6383_TRACE_FRAME=2300000 timeout 1500 ./run.sh kn5000 \
      -window -seconds_to_run 80 -log -autoboot_script <scratchpad>/peq_gain.lua
```

* **NEVER `-video none`.** Always `timeout`-wrap. Always play notes.
* **COMPUTE masks in python, never type them, AND verify your bit is CLEAR IN THE DEFAULT.**
  ⛔ **THE u64 SPEC MASK IS EXHAUSTED — DO NOT LOOK FOR A FREE BIT.** The default is
  **`0xb910e446a39b440f`** (`upd6383.h`, its ONE initialiser; ⚠ the `0x46A39B440F` this paragraph
  carried until 2026-07-31 was **§130's** default, superseded FOUR times: §144 → §156 → §161 →
  §188, so this line was ~96 sections stale and its conclusion *"the lowest genuinely free bit is
  39"* was actively harmful advice).
  **61 of 64 bits are referenced; the only three unreferenced (1, 2, 3) are SET.**
  New gates are **env vars, default OFF, with an unconditional fired count**.
  ★ **Bits 35–37 (§121's `ACT 0x0D` selector) and 42–51 are extracted by SHIFT**
  (`(m_specmask >> 42) & 7`), so a census that matches only hex literals is blind to them —
  which `gen_ledger.py`'s own `mask_bits()` was until §228 taught it the shift form.
  `dsp/tools/gen_fixlist.py` implements it too and self-test **T8** fails if the regression returns.
  ★ Enumerate bits **programmatically from every mask literal**. Checking "is this bit clear in the
  default" is not enough: §130's audit grepped `0x40000\b`, which does not match `0x40000u`, and
  so missed a second site and produced a confounded run. **Match the bit, not the spelling.**
* **Every new gate must log a FIRED-COUNT.**

## 5. The traps that keep costing time

1. **★ Check the owning note FIRST — this has now cost eight passes.** §126 declared PEQ had never
   been loaded while `kn7000_mame/notes/kn5000-dsp-origin-capture.md` had selected it in MAME a
   week earlier, with the recipe. §127 "discovered" the make-up cell that
   `kn5000-dsp-biquad-map.md` had corrected 44 minutes after the note it corrects, 8 days earlier.
   `kn5000-dsp-INDEX.md` indexes ~40 notes. Read it.
2. **A criterion that cannot fail.** §127's evidence for the make-up was `abs(h)*32` with **32 a
   hardcoded literal** — the cell was never read, so the "test" would have printed the same thing
   whatever it held. Before quoting a number, check the code actually consumes the datum.
3. **Degenerate configurations hide the thing you are testing.** At `G = 0 dB` a peaking biquad has
   numerator ≡ denominator, so the pole is recoverable from *either* cell pair and an ISO-centre
   control cannot localise which is which. Change the configuration until the thing you want to
   measure is the only thing that explains the data.
4. **A control that runs between stimulus and observation is part of the stimulus.** The soft-key
   sweep pressed each pair's restore before the next pair's snapshot and misattributed a cursor
   move by one press. One snapshot per press, no restores.
5. **Compute the NULL first.** `unit0/DO1` = 0 non-zero over 2.1 M frames was already in the log
   before any audio harness was designed.
6. **★ The quiet/loud split is contaminated in any panel-selection run.** Every cumulative census
   (§81, kwatch, pwatch, §104, §109) gates on `m_frames_run > 420000` and buckets on input≠0. In a
   run that selects PEQ at 50 s, "quiet" is ≈94 % *CHORUS-era* frames, so quiet-vs-loud is very
   nearly CHORUS-vs-PEQ and any DIFFERS verdict is uninterpretable. Make the window era-aware
   before quoting any of them.
7. **Free-running quantities fake "input dependence"**; **an inert guard is a fact about the
   configuration, not the guard**; **don't ship on one non-discriminating A/B** (§118 → §121).

## 6. Two stale claims to stop repeating

* **"Capture DO3, never the speaker mix."** The *hardware* claim survives (DO3 → HD-AE5000, not in
  the main mix). The *measurement prescription* is inverted for this build: the only writer that
  could reach `m_do[2]` is behind `if (false && …)`, so **DO3 is a constant zero**, while unit 0 —
  PARAMETRIC EQ — presents to **DO1**, which *is* summed into the speaker mix. Capture DO1 at the
  device.
* **The emulated chip runs one frame per 48 000 Hz output sample** while the firmware designs its
  biquads for **44 100**. Scale every predicted frequency by **1.0884** before comparing, or the
  poles land 8.8 % off and read as a decode error.
