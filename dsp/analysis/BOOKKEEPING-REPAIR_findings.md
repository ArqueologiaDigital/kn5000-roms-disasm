# BOOKKEEPING REPAIR — the five findings verified, four dead ends drafted, RULE 20 defined

**Pass:** action 5 of the independent 12-agent strategic review (`STRATEGIC-REVIEW-2026-07-31.md`).
**Mode:** READ-ONLY on every owned file. No build, no MAME run, no commit, no edit to
`upd6383.cpp`, `SPECULATIVE-APPLIED-REGISTER.md`, `HANDOFF-NEXT.md`, `LEDGER.md`,
`LEDGER-HEAD.md`, `BUILD-LANE-QUEUE.md` or `gen_ledger.py`. Everything that would change an owned
file is delivered as §5's patch plan.

**★★★ THIS PASS PRODUCES NO AUDIO AND MAKES NO AUDIO CLAIM.** Where an output figure appears
below it is quoted with its arm: *"`w73`/`w78` are exactly zero"* holds for **the shipped default
and the `NOZ05` rig**, and **not** for the `XB85` arms, which carry a constant (span 0).

**New artefacts, all NEW files, none owned by §227:**

| file | what it does | self-test |
|---|---|---|
| `dsp/tools/gen_fixlist.py` | derives the enumerated shipped-fix list from the source's own gate declarations + the register | **17 of 17 PASS** |
| `dsp/tools/lint_handoff.py` | fails when a handover doc quotes a stale mask / clip rate / gate default / rule number / count | **8 of 8 PASS** |
| `dsp/tools/gen_ledger_ext.py` | sweeps `kn7000_mame/notes/` for graded verdicts absent from `dsp/analysis/` | **7 of 7 PASS** |

Evidence labels: **MEASURED** (read from a file or a log now), **FORCED** (follows from an
artefact that cannot drift), **INFERRED**, **SPECULATIVE**.

⚠ **Cite the predicate, not the line.** Line numbers below are convenience only — three of the
brief's own citations were already stale when it was written (see §1.6).

---

## 1. THE FIVE FINDINGS — VERIFIED STATE

### 1.1 Finding 1 — the shipped-fix count reads five different values — ✅ **CONFIRMED**, and the diagnosis is deeper than the brief's

**MEASURED.** All five values exist, each in the place the brief names except one:

| value | where | exact text |
|---|---|---|
| **five** | `HANDOFF-NEXT.md` heading | `### ★ SHIPPED this session — five, all from the PROVEN-BY-CONSTRUCTION audit, each with a control` |
| **seven** | the table *directly beneath that heading* | rows §188, §197, §201, §202, §204, §208, §209 — **7 rows** |
| **7 of 7** | `BUILD-LANE-QUEUE.md` item 1 | `the proven-by-construction class (7 of 7 successful fixes)` |
| **eight** | `memory/MEMORY.md` index entry | `Eight shipped; read LEDGER.md + HANDOFF-NEXT.md + 📋 BUILD-LANE-QUEUE.md first.` |
| **nine** | `memory/kn5000-dsp-handoff-next.md` §5 | `**NINE fixes shipped**, all from the proven-by-construction class (7 of 7 → 9 of 9)` |

⚠ **One correction to the brief:** the *nine* is in the **memory topic file**, not "a dispatch
brief". No dispatch brief in either repo carries the figure. (**MEASURED** — the only `NINE …
fixes` hit in `kn5000-roms-disasm/dsp`, `kn7000_mame/notes` and the memory directory is that one.)

✅ **And "there is no enumerated list anywhere" is CONFIRMED** — before this pass, no file in either
repo enumerated the shipped fixes. `gen_fixlist.py` is the first.

★★ **THE DEEPER DIAGNOSIS, and it is why five figures could coexist for weeks: NO PUBLISHED
FIGURE STATES ITS UNIT.** "How many fixes shipped" has no answer until you say whether you are
counting **gates** or **sections**. §209 ships **two** gates; §200 and §202 ship **one** gate
between them; §223's nop guard is a gate with no section heading that says SHIPPED. Derived
programmatically (`gen_fixlist.py`, denominators printed):

```
   forced GATES     8   = 7 env gates whose .h initialiser is `true'  +  1 ungated narrowing
   forced SECTIONS 11   = §112 §156 §188 §200 §201 §203 §209 §213 §223 §224 §225
   incl. prose     15   = + channel D: §144 §197 §202 §204
```

⇒ **Every one of the five published figures is wrong for every unit.** The right answer is
**8 gates across 11 sections**, denominators: 19 `getenv("UPD6383_*")` sites, of which 13 are bool
gates (7 default `true`, 6 default `false`) and 6 are non-bool knobs at baseline; 258 `logerror`
calls scanned; 119 register sections.

⚠ **Attribution is not unique for 2 of the 8 gates and the tool says so rather than picking:**
`UPD6383_STPROBE` → §112/§213, `UPD6383_LFOWRAP` → §224/§225. `UPD6383_CFMTIX` is a third case:
the source announces it as `§203` while the register heading credits **§204** (*"the
CONSUMER-TO-CELL census grades §203. It was right. SHIPPED."*).

### 1.2 Finding 2 — TIER 0c stops at rule 18; rules 19/20/21 are cited but 20 is never defined — ✅ **CONFIRMED**

**MEASURED**, enumerated programmatically over both repos (denominator: every `.md/.py/.cpp/.h/.txt`
file under `kn5000-roms-disasm/` and `kn7000_mame/notes/`):

```
   TIER 0c defines rules 1..18.  Highest defined: 18.
   rule 19 : 35 citations in 19 files       <- cited, NOT in the index
   rule 20 : 17 citations in 10 files       <- cited, NOT in the index, NEVER DEFINED ANYWHERE
   rule 21 : 30 citations in  8 files       <- cited, NOT in the index
```

✅ The brief's *"≥8 files"* is confirmed and understated (19 / 10 / 8).

★ **And the three are NOT in the same state — this matters for the repair:**

* **Rule 19 HAS a definition, outside the index.** `LEDGER-HEAD.md`/`HANDOFF-NEXT.md`:
  *"`§70`/`§211` print **MEAN and AC SPAN** (standing rule 19, mechanised)"*, and
  `BUILD-LANE-QUEUE.md`'s standing constraints spell it out (*"Report mean AND AC span, both
  buckets, both arms, before calling anything audio"*, with `79 438 ± 90` as the worked case).
  **Needs indexing, not inventing.**
* **Rule 21 HAS a definition, outside the index.** §224 states it at length (*"`§104`'s and `§86`'s
  quiet-vs-loud markers CANNOT DISTINGUISH input-dependent from free-running-and-sampled-over-two-frame-sets"*),
  §225 made it operational (`dsp/tools/rule21.py`). **Needs indexing, not inventing.**
* ✅ **RULE 20 HAS NO DEFINITION ANYWHERE. CONFIRMED.** All 17 citations are **invocations**:
  `hdrbase.py:16`, `hdrbase.py:201`, `f31carry.py:24`, `f31carry.py:126`,
  `SQUARING-MULTIPLY_findings.md:47`, `HEADER-BANK_findings.md:29/:39`,
  `UNWRITTEN-CELLS_findings.md:68/:512`, `data/PREDICT_224.md:176`, `data/PREDICT_225.md:57/:177/:198`,
  `SPECULATIVE-APPLIED-REGISTER.md:15771/:16017`, `HANDOFF-NEXT.md:155`,
  `STRATEGIC-REVIEW-2026-07-31.md:56`. **Not one of them says what the rule IS.**

See §4 for the definition and the keep/delete recommendation.

### 1.3 Finding 3 — `BUILD-LANE-QUEUE.md`'s standing constraints still assert 5.303 % — ✅ **CONFIRMED**

**MEASURED.** Standing-constraints block, first bullet:

> ⚠ **It still rails**, and so does the shipped build: `§S1` measures **5.303 %** of all
> accumulator conversions clipping on the shipped default with the input **exactly zero**, at a
> rate **higher** than the loud bucket.

The shipped default's actual rate, read from the log of a **forcibly identified** shipped-default
arm (every announced gate equals the `.h` initialiser; no `UPD6383_SPEC` override):

```
   M_s3_census_225.log.gz / K_lfowrap_default_225.log.gz
   TOTALS  quiet 9 178 556 clip / 186 394 560 conversions (4.924 %)
         |  loud 4 077 722 clip /  82 885 440 conversions (4.920 %)
   L_lfowrap_off_225.log.gz  (UPD6383_LFOWRAP=0, the PRE-§225 default)
   TOTALS  quiet 9 884 596 clip / 186 394 560 conversions (5.303 %)   <- the stale figure's arm
```

⇒ **5.303 % is now the `LFOWRAP=0` control arm's number, not the shipped build's.** Quoting it as
*"the shipped build"* in the standing constraints is the single most consequential stale value in
the three handover files, because item 4's whole rationale (*"no vehicle until the shipped build's
own 5.303 % clip rate is dealt with"*) rests on it, and because it is a **regression falsifier for
the current blocker** (queue item 10 lists *"§S1's 4.924 % quiet / 4.920 % loud"* among its
falsifiers — the same document disagrees with itself by 0.379 pp).

⚠ **Two further occurrences are CORRECT and must NOT be "fixed":** `HANDOFF-NEXT.md`'s
`§1.-0-prev-223` / `§1.-0-prev-222` blocks and `BUILD-LANE-QUEUE.md` item 4's banner are inside
⛔-marked superseded sections and are quoting §223 accurately. `lint_handoff.py` grades those
**INFO**, not FAIL, for exactly this reason.

### 1.4 Finding 4 — `HANDOFF-NEXT.md` quotes `0x46A39B440F` while saying the mask is EXHAUSTED — ✅ **CONFIRMED**

**FORCED** (source) + **MEASURED** (doc):

* `upd6383.h` has **exactly one** `m_specmask` initialiser: `u64 m_specmask = 0xb910e446a39b440f;`
  (verified by count, not by spelling — standing rule 7).
* `HANDOFF-NEXT.md` §4 "Build / run": **`Default is now **`0x46A39B440F`**, `m_specmask` is u64.`**
* The **same file** says the mask is **EXHAUSTED** twice: §1.2's *"⚠ New gates are env vars,
  default OFF, with a fired count — the u64 spec mask is EXHAUSTED"* and the shipped-fix table's
  *"⚠ **The u64 spec mask is EXHAUSTED.**"*

★ **`0x46A39B440F` is not a typo — it is a DEFAULT THAT WAS SUPERSEDED FOUR TIMES.** Traced through
the register: §130 shipped `0x46A39B440F` → §144 `0x110E446A39B440F` → §156 `0x1910E446A39B440F` →
`0x3910E446A39B440F` → §188 `0xB910E446A39B440F`. The handover has been ~96 sections behind on this
line. It is also **actively harmful advice**: the surrounding paragraph tells the next agent to
pick a free bit by checking it against that value, and the paragraph's own conclusion
(*"the lowest genuinely free bit is 39"*) is contradicted by the file's own EXHAUSTED statements
and by `BUILD-LANE-QUEUE.md`'s *"61 of 64 bits referenced, the only three unreferenced (1, 2, 3) are
SET"*.

★ **A side finding that pays for itself.** The same paragraph warns that bits 35–37 are *"extracted
by shift, so a grep for the hex misses them"* — and **`gen_ledger.py`'s own `mask_bits()` has
exactly that blindness**: it matches `1ull << N` and `m_specmask & 0xHEX` and nothing else, so
bits 35–37 and 42–51 (`(m_specmask >> 42) & 7`) are invisible to TIER 1. `gen_fixlist.py`
implements the shift form and self-test **T8** fails if the regression returns.

### 1.5 Finding 5 ★★ — the KN7000 cross-model NEGATIVE is missing because the index is repo-scoped — ✅ **CONFIRMED**

**MEASURED, and independently hand-confirmed.**

The result exists, is dated, and is graded: `kn7000_mame/notes/kn5000-dsp-coefficients.md`
(last modified 2026-07-22), `## 5. The KN7000 correlation — VERDICT: NEGATIVE`:

* *"**Zero** arbitrary coefficient is shared."* 12 shared round two-decimal values against an
  expected ~5 from an independent draw of the same pool ⇒ shared **habit**, not shared **data**;
  the only two non-round shared values are **±0.125 = 2⁻³**, a shift.
* KN5000's most distinctive constant **2/π = 0.63662 (53 occurrences)** appears nowhere in the
  KN7000 records; KN7000's signatures **0.618, 0.5614, 0.876, 0.2435, 0.111, 0.243** appear nowhere
  in the KN5000 set.
* §5.2, *"Felipe's strongest hypothesis, **FALSIFIED**"*: delay-tap intersection **`{200}`** — one
  value, and it is round — over **26 × 37 = 962 pairs**; a ±0.3 ms window scores 2/26, 7/26, 4/26
  at 32/44.1/48 kHz, *"consistent with chance"*. Root cause: **both machines design in round
  SAMPLE counts, not round milliseconds.**
* The note explicitly flags its own trap: *"Recording this because it is exactly the sort of number
  that could have been reported as a correlation."*

**Its absence from `dsp/analysis/` is MEASURED, two ways:**

1. `gen_ledger_ext.py` self-test **T1**: with a 21-token discriminating fingerprint, **fewer than 3
   tokens co-occur in any analysis file**.
2. By hand, independent of the tool: `0.5614`, `0.618`, `0.876`, `0.2435` and `{200}` return
   **zero** hits anywhere under `kn5000-roms-disasm/dsp/`. The only mention of the whole result in
   the analysis tree is inside **the review that found it missing**
   (`STRATEGIC-REVIEW-2026-07-31.md:67`).

**The mechanism is exactly as the brief states, and it is structural, not an oversight.**
`gen_ledger.py` reads two paths: `upd6383.cpp/.h` and `SPECULATIVE-APPLIED-REGISTER.md`. Both are
in this repo. `kn7000_mame/notes/` is **213 notes** the generator has never opened. ⇒ **no
repo-external verdict can reach TIER 0b by any path that exists today.**

★★ **AND TIER 0b HAS A SECOND, INDEPENDENT GAP NOBODY HAS NAMED: IT STOPS AT §220.**
**MEASURED** — TIER 0b holds exactly **30** entries and the highest section any of them cites is
**§220**. Nothing from **§221–§226** is filed, although those six sections refuted at least five
distinct candidates. Both gaps have the same effect (a refuted idea stays re-proposable) and they
compound: a re-proposal can now come from either side.

**How many repo-external verdicts are missing:** `gen_ledger_ext.py`, 6 of 6 self-tests passing —
**209 verdict-bearing sections** across **213** notes; **22** represented in `dsp/analysis/`;
**187 absent**, of which **112 are DSP-relevant**.
⚠ These counts drift by a unit or two between runs because §227 is adding analysis files
concurrently — **re-run the tool, do not quote this table.**
⚠ **Grade that number honestly: MEASURED for the KN7000 case, INFERRED in aggregate.** The
detector's threshold was calibrated on **two** known answers, so 112 is a **lower-bound work
queue**, not a statistic.

### 1.6 Three claims in the brief that did NOT reproduce — reported per rule 3/13

| brief's claim | verified state |
|---|---|
| the memory file says *eight*, **a dispatch brief** says *nine* | ⚠ **PARTLY.** Both figures exist; the *nine* is in `memory/kn5000-dsp-handoff-next.md` §5, and **no dispatch brief carries it** |
| the mask is called EXHAUSTED at `HANDOFF-NEXT.md` `:544`/`:665` | ⚠ **STALE LINES.** The two EXHAUSTED statements are at `:631` and `:752`. The claim is true; the citations are not. **Rule 3/13's own failure mode, in the brief that cites rule 3/13** |
| the **class-6 lookup** is one of the four missing dead ends | ❌ **NOT REPRODUCED. It is already filed** — TIER 0b entry **3** (*"`addr8` on the class-6 word = the table extent"*, `lfo-ramp.md` P-16) and entry **4** (*"Implement the class-6 lookup **now**"*, §162), with entry **9** carrying §158's *"the settled modulation value is CONSTANT"*. A fourth entry is still owed, but it is **not** class 6 — see §3.4 |

⚠ Also for the record: the brief's *"RULE 3/13 (five and three occurrences)"* is itself behind the
index — TIER 0c rule 3 now reads **"Ten occurrences"**, and `HANDOFF-NEXT.md` §5 trap 1 says
*"this has now cost eight passes"*. **Three live counts for one rule.** This is the same defect
class as finding 1 and the patch plan does not attempt to resolve it — it is flagged here so the
next pass reconciles it deliberately rather than picking one at random.

---

## 2. WHAT THE THREE TOOLS FOUND, AS NUMBERS

### 2.1 `gen_fixlist.py` — 17 of 17 self-tests PASS

Known-answer controls, printed before any list: LFOWRAP **in** (positive), the §223 nop guard
**in** (positive), `NOCARRY`/`SRC0B2`/`DRPUB`/`EPIBUS`/`PICKUP` **out** (five negatives), §196
(*"Measured, no gate"*), §203 (*"Not shipped"*), §217 (*"NOT SHIPPED"*) and §180 (*"Not
shipped."*) **out** (four documentation-only negatives), plus denominator and rule-7 checks.

★ **Two of the tool's own defects were caught by its self-test and fixed before the list was
believed** — which is the whole point of RULE 20:

* **T4 failed first.** `m_xb85`'s default was parsed as `"== 1 || m_xb85 == 3"`, because the
  initialiser regex matched the body of `bool xb_route() const { return m_xb85 == 1 || …; }`.
  Fixed by requiring a **type** and forbidding `==`.
* **Channel B over-matched.** `§109`'s mask-bit announcement contains the token `SHIPPED` and was
  reported as an ungated narrowing. Fixed by excluding any `logerror` that mentions `m_specmask`.
* Channel D likewise over-matched on **§120** (*"DEAD IN THE **SHIPPED BUILD**"*) and **§151**
  (*"the build **already ships** TWO incompatible readings"*) — neither shipped anything.
  **"SHIPPED" is not a verdict wherever it appears.**

### 2.2 `lint_handoff.py` — 8 of 8 self-tests PASS, **12 distinct FAIL defects across 24 citations**

```
   C1 mask         1   HANDOFF-NEXT.md:965   0x46A39B440F      vs  0xb910e446a39b440f
   C2 clip rate    1   BUILD-LANE-QUEUE.md:332   5.303 %       vs  4.924 / 4.920 %
   C4 undefined   21   rules 19/20/21 cited in all three files vs  TIER 0c = 1..18
   C5 count        1   HANDOFF-NEXT.md:740   "five"            vs  7 table rows
```

Its four known-answer controls **are the brief's four cheap findings**, so the linter cannot pass
its own self-test without reproducing them. Its fifth control is the **kill-condition**: T5 asserts
`SPECULATIVE-APPLIED-REGISTER.md` is not in scope and produced no finding.

⚠ **Scoping decisions, all deliberate, all reversible only by widening the kill-condition:**

* The register is **never** linted. Its §130 *should* still read `default 0x46A39B440F`.
* Inside a ⛔/SUPERSEDED/`prev-`/RETRACTED heading, findings are **INFO** (10 of them). This is what
  keeps the tool usable — without it, every legible closure in `HANDOFF-NEXT.md` would fire.
* `LEDGER.md` from `## TIER 1` onward is a **generated excerpt of the register** and inherits the
  register's exemption (`LEDGER.md:880` is a §223 heading quoting 5.303 % correctly).
* ⚠ `LEDGER.md`'s tier 0 is a **verbatim copy** of `LEDGER-HEAD.md`, so every tier-0 defect is
  reported twice by construction. **Edit `LEDGER-HEAD.md` and regenerate. Never edit `LEDGER.md`.**

### 2.3 `gen_ledger_ext.py` — 7 of 7 self-tests PASS, **112 DSP-relevant verdicts absent**

★ **Its self-test caught two defects that would each have produced a confidently wrong number:**

1. **T2 failed first.** Sections were sliced at the next heading of *any* level, truncating
   `## 5. The KN7000 correlation` at `### 5.1` — a two-line body with **one** discriminating token.
   The verdict would have been reported absent **for the wrong reason**. Fixed: slice at the next
   heading of the **same or higher** level.
2. **T1 then failed.** With the full body, `§5` matched `SPECULATIVE-APPLIED-REGISTER.md` on ten
   tokens — every one of them either a fragment of a digit-grouped number (`962` out of
   `962 880`) or borrowed from `§3`'s KN5000 tap list, which the analysis tree genuinely does
   carry. **The tool was about to certify the missing verdict as present.** Fixed three ways:
   normalise digit grouping before tokenising, require ≥4-digit numerics, and subtract tokens that
   occur elsewhere in the same note.
3. **T3's control was itself broken** and had to be replaced: the "known PRESENT" control selected
   `§5.2 Delay lengths … FALSIFIED`, which is one of the **known-ABSENT** verdicts — a control that
   demanded PRESENT for something that must be ABSENT. Replaced with
   `dsp-register-space-applied.md` ↔ `analysis/register-space.md`, whose answer is known
   independently of the thing under test.

⇒ ★★ **A control has to be a case whose answer is known INDEPENDENTLY of the thing being tested.**
That is a candidate sharpening of rule 20 and it was earned in this pass.

★★ **AND A FOURTH, WHICH IS THE BEST EVIDENCE THE DETECTOR WORKS.** Once **this very document**
existed, T1 flipped to FAIL — the sweep found the KN7000 verdict "represented", in
`BOOKKEEPING-REPAIR_findings.md`, because §3 quotes it in order to draft it. ⇒ **a report about
the gap must not be allowed to close the gap on paper.** The file is now excluded from the index
by design, and the exclusion is guarded by a **two-sided** control: **T1** asserts ABSENT with the
drafts excluded, **T1b** asserts the *same detector on the same fingerprint* reports **PRESENT**
once they are counted. A detector that cannot see a filing cannot be trusted to report an absence.
⚠ **The gap closes when TIER 0b carries the rows — not when a findings file describes them.**

---

## 3. THE MISSING DEAD-END ENTRIES — DRAFTED, READY TO PASTE

Format matches TIER 0b exactly: `| # | the idea | why it is dead | where |`. Paste after the
existing entry 9 (the current last row, `§155, §157 → §158`). Numbering continues from **30**.

### 3.1 ★★ The KN7000 cross-model coefficient oracle — NEGATIVE, repo-external

```
| 31 | Open the **KN7000 / SHARC effects engine as a cross-model oracle** for IC311's coefficients | ⛔ **RUN 2026-07-22, VERDICT: NEGATIVE.** **Zero** arbitrary coefficient is shared. 208 KN5000 constants vs 548 KN7000 floats: 12 shared two-decimal round values against ~5 expected from an independent draw of the same ~100-value pool (shared **habit**, not shared **data**), and the only two non-round shared values are **±0.125 = 2⁻³**, a shift. KN5000's signature **2/π = 0.63662 (53 occurrences)** appears nowhere in the KN7000 records; KN7000's **0.618 / 0.5614 / 0.876 / 0.2435 / 0.111 / 0.243** appear nowhere in the KN5000 set. ⚠ A naive float-set baseline predicts 1.8 ± 1.3 against 16 observed and **looks significant** — it is wrong, because both real sets are biased toward round decimals; split the sets and the signal vanishes. ★ **The note flagged its own trap in advance**: *"recording this because it is exactly the sort of number that could have been reported as a correlation"* | `kn7000_mame/notes/kn5000-dsp-coefficients.md` §5 / §5.1 |
```

### 3.2 ★★ The delay-length ms-domain correlation — FALSIFIED, repo-external

```
| 32 | **Delay tap lengths survive the change of chip** — "N milliseconds is the same physical quantity on either instrument", so KN7000 taps should locate KN5000's (Felipe's strongest cross-model hypothesis) | ⛔ **FALSIFIED 2026-07-22.** Raw intersection of the two tap sets is **`{200}`** — one value, and it is round. Over **26 × 37 = 962 pairs** with a ±0.3 ms window spanning 5–500 ms: **2 of 26** at 32 kHz, **7 of 26** at 44.1 kHz, **4 of 26** at 48 kHz — consistent with chance, and **the test cannot even pin the sample rate**. ★ **The reason is the transferable part: both machines design their delay lines in round SAMPLE counts, not round milliseconds** (KN5000: 160 200 520 600 640 720 840 1100 1160 1240 1550 1760 12800; KN7000: 200 250 400 512 800 1000 4000 5000 8000 32768). A tap is an **address in a delay buffer**; a designer moving to a new chip with a new buffer geometry re-picks them from scratch. The physical-quantity argument holds for a spec sheet, not for an implementation | `kn7000_mame/notes/kn5000-dsp-coefficients.md` §5.2 |
```

### 3.3 ★★★★ §226's frame-start coefficient-cursor seed — REFUTED from disk

```
| 33 | **Seed the coefficient cursor at frame start** (`UPD6383_CURSEED`, base `0x00`) — "the cursor is never seeded, so the header runs on whatever the previous frame's unit-1 body left behind" | ⛔ **REFUTED §226, FROM DISK, NO RUN — and both halves of the premise are wrong.** (a) **The base IS seeded, by an instruction**: the epilogue's own `iw69 = 801.0.90.821 ldptr #$90` reaches register row 25's `is_ldptr` branch (`m_cursor = ad` under `!(m_specmask & 0x1000)`; **bit 12 is CLEAR in the default**), and the epilogue contains **ZERO** cursor-advancing words, so the next frame's `w0` starts at **exactly `0x90`, every frame**. (b) **Base `0x00` is the UNIT-0 EFFECT's own per-effect parameter bank** — selecting PARAMETRIC EQ rewrites `0x00..0x1E` wholesale and moves **every one of `0x00..0x13`** while writing nothing at or above `0x50`; the header is a **literal canned image in Sub CPU ROM** and cannot read a per-effect bank. (c) **The numbers refute it too**: at base `0x90`, **15 of 20** header cells are INVARIANT across cold-boot / PARAMETRIC EQ / live arm K and ladder cells `9B/9C/9D` are **all** invariant; at base `0x00`, **0 of 20** are invariant and the same ladder reaches **`2.733 × FS`** — **1.6× WORSE**. ⇒ ★★★★ **A CLIP RATE THAT FALLS BECAUSE A COEFFICIENT BECAME *SOMEBODY ELSE'S* IS ALSO A REGRESSION**: seeding `0x00` drops `§S1 iw34` and `§S2 iw33` on the archived vehicle and looks like a clean win in every statistic. ⚠ And *"set it to the value it already has"* **cannot fail** — rule 8 | §226, `HEADER-BANK_findings.md` item E |
```

### 3.4 The fourth entry the review asked for — **the class-6 lookup is ALREADY FILED**; this is what is actually missing

**❌ NOT REPRODUCED as a gap.** The class-6 lookup occupies TIER 0b entries **3**, **4** and **9**
already. Re-filing it would create the fourth and fifth statements of one fact, which is the defect
this pass exists to repair.

**What is genuinely missing in its place** is the §221–§226 cohort, of which the highest-value
unfiled refutation is §224's — it is the one most likely to be re-proposed, because the mechanism
is real and only its *application* is refuted:

```
| 34 | **`ACT 0x00`'s bus term is a missing general attenuation** — the unity-gain bus addend is what overflows the kernel ladder, so attenuate it | ⛔ **REFUTED §224, FROM DISK, FOR `iw34`.** Zero the `ACT 0x00` bus term and `iw33` **still leaves 10 234 099 = 1.220 × FS. It still clips.** ⚠ **HALF RIGHT, AND THE HALF MATTERS**: the mechanism IS real — a unity-gain bus addend exists — but at `iw34` it is not the cause, and at `iw13`/`iw91` the fault is **WHAT THE BUS CARRIES** (a railed memory cell; a modulus), not that it is added. The named addend at `iw91` is `iw92 − iw91 = 8 388 607 = 0x7FFFFF = C-RAM[0x01]` **exactly, at both endpoints** — the constant `upd6383.cpp`'s **own** C-RAM annotation calls *"wrap"*, which §225 then shipped as `UPD6383_LFOWRAP`. ⇒ **do not re-propose "attenuate the bus"; ask what is ON it** | §224, superseding §223 §8.2 |
```

★ **And the class-6 row should be CONSOLIDATED rather than added to.** Suggested replacement text
for the existing entry 4, folding in §158's later verdict so the three rows stop drifting apart:

```
| 4 | Implement the class-6 lookup **now** | Every index candidate is constant (`acc 0..0 \| m_dp 12..12 \| cursor 9..9`, 1 129 389 hits). A frozen lookup returns one entry forever, and that reads as *refuting the sine* against the "226 not 240" test. ★ **CONFIRMED DOWNSTREAM (§158):** the settled tap modulation is **CONSTANT per voice** — `§104` gives `iw96 15729946 \| iw105 15729540 \| iw137 −15727740 \| iw146 −15727740`, **all `min == max`** in quiet *and* loud — *because the lookup is a no-op*. ⇒ rule 4: the consumer cannot be validated until its index varies. See also entries 3 and 9 | §162, §158 |
```

### 3.5 The rest of the §221–§226 cohort, drafted for completeness

```
| 35 | **`SRC 0x03` / `ACT 0x03` as an epilogue crossbar latch** (`§E-D85`) | ⛔ **REFUTED §222 by a two-sided bisection.** Arm E fired 1 204 800 / 1 203 840 and its `diff`s are **EMPTY**; arm D equals arm C in every column. `iw205` is a **MESSENGER** — its operand `547 518 .. 8 388 607` gives `ACCB 35 882 139 648 .. 549 755 748 352 = L × 65536` at both endpoints — and **`m_bx_sel0d` stays FROZEN at 1**, where changing it breaks body 0's only working pickup and the regression **IS** the `79 438 ± 90` rule-19 DC. ⚠ **`D-RAM[0x85]` has NO WRITER AT ALL** on settled frames, measured by an instrument that names `iw70` the instant one exists | §222 |
| 36 | **A store-suppression rig will produce a non-railing vehicle** | ⛔ **REFUTED §223.** The narrow rig (`NOZ05 = 2`, `iw35`/`iw45` only, 2 stores) reproduces `28/32/28` / `33/40/29` / `2/1/2` column for column **and still rails** — and so does the shipped build, which clips **4.924 %** of all accumulator conversions with the input **exactly zero** (5.303 % before §225's `LFOWRAP` shipped), at a rate **higher** than the loud bucket. ⇒ **the rail is upstream of the send entirely**; the rig removes the two stores that were HIDING it from body 0, it does not create it. **Treat nothing that rails as evidence**, and do not build another suppression rig looking for a clean vehicle | §223, correcting §222's attribution |
| 37 | **Kernel A's cell `0x06` is a BISTABLE / a latch-up with a stable second state** | ⛔ **RETIRED §225. `0` IS NOT A FIXED POINT.** `§S3` — read-only, always on, **no frame gate** — reports `SETTLING`: cell `0x06` is 0 before any instruction writes it, **stores #1..#1356 write exactly 0** (measured: the ladder's lowest rung is *"val ≥ 1"* and first fires at #1357), then `iw19`'s **first ever execution** at frame 264 002 puts `1 650 061 = 0.1967 × FS` **into an empty cell** — already **1.52 ×** the `0.129 703 × FS` threshold — and the rail follows **on the next frame**. **There is no second state.** The rail needs a **FORWARD GAIN** explained, not an ENTRY. ⚠ **`§106`'s writer list was 5 names of 12** and `5 881 351` was never divisible by 5 — quote `nz`, never just the count | §225, retiring §224 §2 |
| 38 | **The multiply should read `C-RAM[cursor + 1]`** (`§S2sq`, the coefficient squaring) | ⛔ **CLOSED WITHOUT A BUILD, TWICE.** (a) `SQUARING-MULTIPLY_findings.md`: the multiply has **one hardwired coefficient port** (`C-RAM[ccur]`; no instruction field selects it) and **one** operand bus, so a word routing the coefficient onto that bus has **no second port for a sample** — the squaring is **FAITHFUL**. Census `123 / 893 = 13.77 %` against a `0.05 %` null, `z = +90`: **evidence FOR the decode.** (b) The re-attribution to the cursor BASE is refuted by §226 (entry 33). ⛔ **`SRC 0x08 = C-RAM[cursor]` is ANCHORED** by the CHORUS LFO (`C-RAM[0x00] = 114` ⇒ `+114`/frame; §196 measures the wrap period at 96 000 frames = 0.5000 Hz) — **do not touch the source read** | `SQUARING-MULTIPLY_findings.md`, §226 |
```

---

## 4. RULE 20 — DEFINE IT. **Do not delete it.**

### 4.1 The recommendation

**KEEP AND DEFINE.** It is not redundant against rules 4 or 8, and the test is that they govern
different objects:

| rule | what it governs | the question it answers |
|---|---|---|
| **4** | the **experiment's inputs** | do the inputs to the thing I am about to implement actually vary? |
| **8** | the **criterion's logic** | could my test have come out the other way, and did I compute the null first? |
| **20** | the **instrument itself** | has this detector ever reproduced an answer I already know, and did I say so **before** I reported its output? |

A detector can satisfy rules 4 and 8 perfectly and still be broken — that is not hypothetical, it
happened three times **inside this pass** (§2.1, §2.3). §221's provenance census graded on one
column of three and produced a **false absence**; §221's `E1_SLOTS = 24` silently dropped two rows;
§224 recorded that *"a census whose internal consistency is TRUE BY CONSTRUCTION is not a
self-test"*. None of those is a rule-4 or rule-8 failure. All three are rule-20 failures, and the
project has been paying for the rule while it had no name.

### 4.2 The proposed TIER 0c text

```
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
    * **print the result of every check, PASS or FAIL, before the finding** — reporting only the
      passes is how `§121` ran seven arms that were all the same arm.
    ⇒ **Report your failed controls out loud.** `UNWRITTEN-CELLS_findings.md` §2 opens *"two of
    them FAILED"*, and that is what makes the other five worth reading.
    *(named across §224/§225/§226; `hdrbase.py` 10 self-tests + 3 external, `f31carry.py`,
    `SQUARING-MULTIPLY_findings.md` §1, `HEADER-BANK_findings.md` §1 — all invoked it, none
    defined it, for 17 citations across 10 files)*

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
```

---

## 5. THE PATCH PLAN — mechanical, for the lane-holder

Every item is *file · anchor · replacement*. Anchors are **exact current text**, chosen to be
unique. ⚠ Anchor on the text, never on the line number.

### P1 — `BUILD-LANE-QUEUE.md` · the 5.303 % standing constraint ★★ HIGHEST VALUE

**Anchor** (standing-constraints block, first bullet):

```
  `28/32/28` / `33/40/29` / `2/1/2` **column for column**. ⚠ **It still rails**, and so does the
  shipped build: `§S1` measures **5.303 %** of all accumulator conversions clipping on the shipped
  default with the input **exactly zero**, at a rate **higher** than the loud bucket.
```

**Replace with:**

```
  `28/32/28` / `33/40/29` / `2/1/2` **column for column**. ⚠ **It still rails**, and so does the
  shipped build: `§S1` measures **4.924 %** quiet / **4.920 %** loud of all accumulator conversions
  clipping on the shipped default with the input **exactly zero**, at a rate **higher** than the
  loud bucket in the pre-§225 arm and level with it now.
  ⚠ **`5.303 %` / `5.298 %` are the `UPD6383_LFOWRAP=0` CONTROL ARM's numbers** (§223/§224,
  `L_lfowrap_off_225.log.gz`), NOT the shipped build's — §225's `LFOWRAP` ship removed exactly
  `iw92`'s 706 040 quiet / 313 960 loud conversions. **Quote the arm with the number.**
```

⚠ **Do NOT touch** item 4's `<details>` banner (the *"…until the shipped build's own 5.303 %"*
line): it is inside a ✅-DONE historical banner filed at §223 and is correct for its arm.

### P2 — `HANDOFF-NEXT.md` §4 · the stale mask literal

**Anchor:**

```
  Default is now **`0x46A39B440F`**, `m_specmask` is u64. Bits 0–34 are used-in-code or
  set-in-default, **bits 35–37 are §121's `ACT 0x0D` selector** (extracted by shift, so a grep for
  the hex misses them) and **bit 38 is §130's rebase** — the lowest genuinely free bit is **39**.
```

**Replace with:**

```
  ⛔ **THE u64 SPEC MASK IS EXHAUSTED — DO NOT LOOK FOR A FREE BIT.** The default is
  **`0xb910e446a39b440f`** (`upd6383.h`, its ONE initialiser; ⚠ the `0x46A39B440F` this paragraph
  carried until 2026-07-31 was §130's default, superseded FOUR times: §144 → §156 → §161 → §188).
  **61 of 64 bits are referenced; the only three unreferenced (1, 2, 3) are SET.**
  New gates are **env vars, default OFF, with an unconditional fired count**.
  ★ **Bits 35–37 (§121's `ACT 0x0D` selector) and 42–51 are extracted by SHIFT**
  (`(m_specmask >> 42) & 7`), so a census that matches only hex literals — including
  `gen_ledger.py`'s TIER 1 — is blind to them. `dsp/tools/gen_fixlist.py` implements the shift
  form and self-test T8 fails if the regression returns.
```

### P3 — `HANDOFF-NEXT.md` · the shipped-fix heading

**Anchor:**

```
### ★ SHIPPED this session — five, all from the PROVEN-BY-CONSTRUCTION audit, each with a control
```

**Replace with:**

```
### ★ SHIPPED in the §188–§209 session — SEVEN, all from the PROVEN-BY-CONSTRUCTION audit, each with a control

⚠ **DO NOT QUOTE THIS AS THE PROJECT TOTAL.** It is one session. The authoritative enumerated list
is **derived, never counted**: `python3 dsp/tools/gen_fixlist.py`. As of 2026-07-31 it reports
**8 forced GATES across 11 SECTIONS** (denominators: 19 `getenv` sites — 7 bool gates default
`true`, 6 default `false`, 6 non-bool knobs at baseline; 258 `logerror` calls; 119 register
sections). ★ **A shipped-fix count is meaningless without its UNIT**: §209 ships two gates, §200
and §202 share one. That ambiguity is why this figure has been published as five, seven, "7 of 7",
eight and nine simultaneously.
```

### P4 — `LEDGER-HEAD.md` TIER 0c · append rules 19, 20, 21

**Anchor** — the final line of rule 18 (end of TIER 0c, immediately before the `---` and
`## TIER 1`):

```
    ⇒ **And when a re-derived number disagrees with the source comment beside the counter, the
    comment is evidence — reconcile before building on the new number.** *(§218)*
```

**Append after it** the three numbered blocks from §4.2 above, verbatim.
Then run `python3 dsp/tools/gen_ledger.py` to regenerate `LEDGER.md`.
**Verification:** `python3 dsp/tools/lint_handoff.py` — check C4 drops from **21** to **0**.

### P5 — `LEDGER-HEAD.md` TIER 0b · append dead ends 31–38

**Anchor** — the current final TIER 0b row:

```
| 9 | "the delay tap **sweeps** ±240" / "each voice ramps 0→depth, a **sawtooth**" | Both retracted. The first pooled voices of opposite sign; the second censused across the boot transient. The settled modulation value is **CONSTANT** | §155, §157 → §158 |
```

**Append after it** rows **31–38** from §3 above.
**Also replace** entry 4 with the consolidated text in §3.4 (anchor: the row beginning
`| 4 | Implement the class-6 lookup **now** |`).

**And amend the TIER 0b preamble** so the two new scopes are declared. Anchor:

```
Each cost at least one full pass. The refutation is worth more than the hypothesis was.
```

**Replace with:**

```
Each cost at least one full pass. The refutation is worth more than the hypothesis was.

★★ **TWO KINDS OF ENTRY LIVE HERE NOW.** Entries 1–30 come from `SPECULATIVE-APPLIED-REGISTER.md`,
which `gen_ledger.py` reads. Entries **31+** include **REPO-EXTERNAL** verdicts from
`kn7000_mame/notes/`, which **NO GENERATOR READS** — they are filed by hand and they must be,
because the index is repo-scoped while the evidence is not. `python3 dsp/tools/gen_ledger_ext.py`
sweeps the notes and reports what is still unfiled: **112 DSP-relevant graded verdicts** as of
2026-07-31 (⚠ INFERRED aggregate — a lower-bound work queue, not a statistic).
⚠ **And entries 1–30 stopped at §220.** Nothing from §221–§226 was filed for eleven days while
those six sections refuted five distinct candidates. **File the refutation in the same pass that
earns it.**
```

### P6 — `gen_ledger.py` · two defects, both blocking, neither editable by this pass

★★ **P6a is a HAZARD, not a preference.** `gen_ledger.py` calls `main()` at **module scope with no
`if __name__ == '__main__':` guard**, so *any* `import gen_ledger` — from a tool, a test, a REPL —
**silently rewrites `LEDGER.md`**. All three tools delivered here re-implement its parsing rather
than import it, purely to avoid this.

**Anchor** (final line of the file):

```
main()
```

**Replace with:**

```
if __name__ == '__main__':
    main()
```

**P6b — the shift-form mask blindness.** `mask_bits()` matches `1ull << N` and
`m_specmask & 0xHEX` only, so bits **35–37** and **42–51** never reach TIER 1 — the exact blindness
`HANDOFF-NEXT.md` §4 warns about in prose. **Anchor:**

```
            for h in re.findall(r'm_specmask\s*&\s*(0x[0-9a-fA-F]+)u?l*', ln):
                v = int(h, 16)
                for b in range(64):
                    if v >> b & 1: hit.add(b)
```

**Append after that block** (see `gen_fixlist.mask_bits()` for the tested form):

```python
            #  ★ THE SHIFT FORM: `(m_specmask >> N) & M' matches no hex literal, so a
            #  literal-only census is blind to bits 35-37 (§121's ACT 0x0D selector)
            #  and 42-51 (m_bx_sel0d / sel0e / f4 / f5).  Standing rule 7: match the
            #  BIT, not the spelling.
            for n, msk in re.findall(r'm_specmask\s*>>\s*(\d+)\s*\)?\s*&\s*(\w+)', ln):
                n = int(n)
                try:    w = int(msk, 0)
                except ValueError: w = 1
                for k in range(max(1, w.bit_length())):
                    hit.add(n + k)
```

### P7 — the memory files (not owned by §227, but part of the same defect)

* `memory/MEMORY.md` — replace `Eight shipped;` with
  `8 gates / 11 sections shipped (derive it: dsp/tools/gen_fixlist.py, never quote a count);`
* `memory/kn5000-dsp-handoff-next.md` §5 — replace
  `**NINE fixes shipped**, all from the **proven-by-construction** class (7 of 7 → 9 of 9)` with
  `**8 forced GATES across 11 SECTIONS shipped** — derived by `dsp/tools/gen_fixlist.py`, never
  hand-counted; ★ a count without its UNIT is how this figure reached five simultaneous values`

### P8 — wire the linter in so this cannot recur

Add to `BUILD-LANE-QUEUE.md`'s standing constraints (anchor: the final bullet,
`- **Do not ship a default flip on a moved number or a model argument alone.**`), **before** it:

```
- ★★★ **RUN `python3 dsp/tools/lint_handoff.py` BEFORE HANDING OFF.** It exits non-zero when
  `HANDOFF-NEXT.md`, `LEDGER.md` or this file quotes a mask literal, clip rate, gate default,
  rule number or declared count that disagrees with `upd6383.h` or with the current
  shipped-default log. ⚠ It is scoped to those three files and **NEVER** the register, whose
  older sections legitimately quote superseded values — **do not widen that scope**, it is the
  tool's kill-condition. Findings inside a ⛔/SUPERSEDED heading are INFO by design.
  ⚠ `LEDGER.md`'s tier 0 is a verbatim copy of `LEDGER-HEAD.md` — **edit the HEAD and regenerate.**
```

### P9 — application order and verification

| # | patch | verify with |
|--:|---|---|
| 1 | **P6a** (the `main()` guard — a hazard for every later step) | `python3 -c "import sys; sys.path.insert(0,'dsp/tools'); import gen_ledger"` leaves `LEDGER.md` mtime unchanged |
| 2 | **P4** + **P5** (`LEDGER-HEAD.md`), then `python3 dsp/tools/gen_ledger.py` | `lint_handoff.py` C4 goes 21 → 0; TIER 0b row count 30 → 38 |
| 3 | **P1**, **P2**, **P3** | `lint_handoff.py` C1/C2/C5 each go 1 → 0; expect **0 FAIL**, INFO unchanged |
| 4 | **P6b**, re-run `gen_ledger.py` | TIER 1 gains bits 35–37 and 42–51; `gen_fixlist.py` T8 still PASS |
| 5 | **P7**, **P8** | `gen_fixlist.py` still 17/17 |

⚠ **None of these patches touches `upd6383.cpp`, needs a build, or changes device behaviour.**
Every one is a documentation change against a value the source or a log already carries.

---

## 6. WHAT THIS PASS DID NOT DO, AND SAYS SO FIRST

* **No audio claim of any kind.** No run, no capture, no spectral comparison.
* **The aggregate "112 absent verdicts" is INFERRED**, threshold-calibrated on two known answers.
  Only the KN7000 cross-model case is MEASURED, and it is hand-confirmed independently of the tool.
* **`gen_fixlist.py`'s "what it changes" column is an EXCERPT**, taken from the nearest `★` banner
  that owns the member. For `UPD6383_ROTSIGN`, `DSCPRE` and `DSCRING` the nearest owning banner is
  a neighbouring paragraph — the same failure mode `gen_ledger.py` warns about for TIER 1
  (*"where two gates share a comment block the text can belong to the neighbour"*). **Use the
  column to find the gate, then read the source.** `BODYIX` and `CFMTIX` have no owning banner at
  all and correctly fall back to their runtime announcement.
* **The rule-3 occurrence count (five / eight / ten) is left unreconciled**, deliberately — see
  §1.6. It needs a decision, not a guess.
* **Channel D of `gen_fixlist.py` is graded INFERRED** and is never folded into the headline. It
  reads headings, and headings are prose.
