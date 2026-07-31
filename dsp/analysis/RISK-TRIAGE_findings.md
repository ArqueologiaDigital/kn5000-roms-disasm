# RISK TRIAGE — what the frame-trace SHIFT and the census POOLING actually touch

**Written 2026-07-31. READ-ONLY pass.** No source was edited, no build was run, no emulator was
launched, nothing was committed. Every number below is computed from a log already in
`dsp/analysis/data/`, from `git blame`/`git log` on the two repositories, or from
`kn7000_mame/src/devices/cpu/upd6383/upd6383.{cpp,h}` at `b03e9d6`.

Downstream of `INSTRUMENT-AUDIT_findings.md` (`6ce3b07`), which confirmed two defects and left
their blast radius unassessed. **This note is that assessment. It is risk triage, not
adjudication: no question is re-decided, only marked.**

⚠ **NO AUDIO CLAIM IS MADE OR IMPLIED.** Every finding is about the *apparatus*. Where an
instrument turned out to be defective that changes what a measurement can support; it never makes
the chip audible. RULE 19 remains the gate. See §7 for one live observation that belongs to
§222's lane and is explicitly **not** adjudicated here.

---

## 0. HEADLINE — read this first

1. **The shift and the pooling touch 14 of 2 163 live measurement-citing conclusions, and
   ZERO of them is an open load-bearing claim.** Full sweep in §3; the denominators are §2.
2. **⚠ TWO CORRECTIONS TO THE BRIEF, both RULE 3 (check the owning note first).** The brief's
   two headline downstream consequences were **already recorded before the audit was written**:
   * `OUTPUT-STAGE-NULL_findings.md` has carried a **`⛔ PARTIALLY RETRACTED`** banner at line 1
     since `e49da4b`, **2026-07-31 11:34 — 58 minutes before the audit commit** (`6ce3b07`,
     12:32). It corrects `0xD0` → `0x85`, names the post-increment `dp` column as the cause, and
     retracts the affected row. The audit's headline #2 and its risk-list item #1 report this as
     open. **They are stale.** MEASURED, `git log -S` on that file.
   * The `§104`-pools-a-type-walk defect is **pre-registered verbatim** in
     `PREDICT_S1_hi12_bench.md` §4 ("★ The §193-shaped trap, pre-registered"), including the
     420 000 arm, the ~1.76 M/~0.4 M split, `m_sp_word[]` last-write-wins and the conclusion
     *"Any `§104` reading taken from a `type_select` run is confounded"*. The brief restates it
     as a new confirmation. It is the note's own pre-registration, graded MEASURED.
3. **★★ The 13-over-12 header was CORRECT when written and broke on a datable commit.** It
   shipped 7 names / 7 values at `d7354cf` and 13 / 13 at `cbe9b31`; it went 13 / 12 at
   **`db42362`, 2026-07-29 12:09:19** (the commit that added ACCB + unit context). Register
   section **"65-66"** carries that *same* author timestamp. ⇒ **57 of the register's 201
   numbered sections predate the defect entirely** and cannot be exposed to it. §3.1.
4. **★★ The pooling defect FIRED, and I can show it firing.** 9 of the 28 archived logs are
   provably multi-program: 321 `§104` rows instead of 285, **16–17 distinct `nq/nl` values**, and
   the 36 extra slots (`iw154..189`) are *exactly* the 36 whose quiet count is ~⅓ of the rest.
   All 9 predate the clean vehicle (§148). **All 19 logs after it show ZERO spread.** §3.2.
5. **★★ `PREDICT_S1`'s F1 is VOID — and I can upgrade the grade from FORCED to MEASURED.**
   `UPD6383_NOZ05` suppressed **3 528 080** stores between two archived arms and **0 of 256**
   `D-RAM WRITES` **totals** moved, while **9 of 256** `nonzero` counts did. §4.
6. **★★★ NEW — the pre-increment trap has a FOURTH occurrence, on the CURSOR, and finding it
   CLOSES an open item on §221's own next-task list.** The trace's `cur`/`coef` pair is sampled
   after `exec_decoded()` exactly like `dp`. **17 of 18** `§175` per-site coefficients equal the
   **preceding** trace row's `coef`. `OUTPUT-STAGE-NULL_findings.md` §7's declared-unreconciled
   `iw112` `coef 0..24` vs `0x1364D9` is **resolved, with zero runs**: they are one cursor step
   apart and the `×24` attenuation **stands**. §5.
7. **`§70`/`§211` SURVIVE, and §221's `F1`/`F1b`/`§E1` diff SURVIVE — verified from the logs,
   not inherited.** §6.

---

## 1. METHOD, AND THE DETECTOR SELF-TESTS (including the one that failed)

**Programmatic, never a spelling grep to establish a fact.** Regexes build *candidate
populations* only; every candidate was then re-read structurally, and the top items were checked
against real logs. Scratch scripts (not committed):
`/tmp/…/scratchpad/triage/{parse,tokens,align,headers,pooling,classify}.py`.

The corpus was split into **claim units** (ATX heading + body, fence-aware) across all 65
`dsp/analysis/*.md` **and** the 31 `dsp/analysis/data/*.md`: **2 675 units in 96 files.**
Section dates come from `git blame --line-porcelain` author-time, not from prose or mtime.

### 1.1 Self-tests

| # | test | result |
|---|---|---|
| **T1** | Known-answer *positive*: the confirmed `OUTPUT-STAGE-NULL` `0xD0` unit must be flagged by the trace+`dp` detector | **PASS** (`§1.2`, trace_ctx ∧ dp_val) |
| **T2** | Known-answer *positive*: `PREDICT_S1`'s `D-RAM WRITES` unit must be found | **PASS**, 4 units |
| **T3** | Alt-spelling control (the audit's own lesson): rows written `n=135 iw 205` rather than the word "trace" must still be caught | **PASS**, 0 misses |
| **T4** | ⛔ **FAILED FIRST.** "No `min == max` unit is flagged as a trace-column reader" | **FAILED** — and the failure was *mine*, not the detector's: `INSTRUMENT-AUDIT_findings.md` legitimately discusses trace columns *beside* the null. The test was mis-specified (co-occurrence ≠ mis-classification) and was replaced by T5 |
| **T5** | Re-specified: does the `§70`/`§211` null itself resolve to a trace column? | **PASS** — it resolves to two dedicated `logerror` lines with named fields, not to any table |
| **T6** | Header-arity detector must rediscover the known 13-names/12-values case unprompted | **PASS** (§3.1) |
| **T7** | Pooling detector must reproduce the audit's *independently derived* 20 000-frame `§70`-vs-`§104` gap on every log | **PASS**, 28 of 28 |
| **T8** | Pooling detector must have a **positive control** — a log it calls multi-program | **PASS**, 9 logs, corroborated three independent ways (§3.2) |

**T4 is reported because it fired.** A detector that returns "no spread" everywhere may simply be
incapable of returning spread; T8 exists for that reason and is the reason §3.2's numbers can be
trusted.

---

## 2. THE CLASSIFIED REGISTER — denominators

| population | count |
|---|---|
| claim units parsed (96 files) | **2 675** |
| units citing a measurement | **2 368** |
| — already **RETRACTED** in their own heading (skipped per the brief; do not resurrect) | **205** |
| **live measurement-citing conclusions — the denominator** | **2 163** |

| class | count | of which **open and load-bearing** |
|---|---|---|
| **SAFE** | **2 149** | — |
| **AT RISK (shift)** | **1** | **0** — already retracted in place, `e49da4b` |
| **AT RISK (phase — `cur`/`coef`, newly identified here)** | **1** | **0** — resolved by this pass, §5 |
| **AT RISK (pooling)** | **11** | **0** — all pre-§148 vehicle; none in a live TIER-0 claim |
| **VOID** | **1** | **0** — the graded run has never been performed |

⇒ **"The shift and the pooling touch N conclusions, none of them load-bearing" is the outcome,
with N = 14.** The sweep that establishes it is §3.

---

## 3. THE SWEEP

### 3.1 The SHIFT — bounded by a commit date, and it has produced no *uncorrected* error

**The header's history, from `git log -S` on the format string** (`kn7000_mame`):

| commit | date | header | format | aligned? |
|---|---|---|---|---|
| `d7354cf` | 07-28 10:59 | `n iw word dp mem[dp] acc P` — **7** | 7 values (`t.mem`, `t.p` both printed) | **YES** |
| `851cec1` | 07-28 | + `tA tB cur coef` — **11** | 11 values | **YES** |
| `cbe9b31` | 07-28 | + `MUL L` — **13** | 13 values | **YES** |
| **`db42362`** | **07-29 12:09** | **unchanged, 13** | **12** — `t.u1`/`t.accb` added, `t.mem`/`t.ta`/`t.tb` dropped | ⛔ **NO** |

`git blame` on the register puts section **"65-66. The per-slot ACCA/ACCB trace"** at author-time
**2026-07-29 12:09:19** — the *same second*. ⇒ **57 numbered sections predate the break; 144 are
in the exposed epoch.** Exposure is not risk: only a conclusion that *reads a column* can be bitten.

**⚠ A refinement the brief and the audit both miss.** The brief says the shift makes *"`ACCB` read
as `P`, and `P` read as `tempA`"*. That is the **name-order** reading. Measured against real rows,
the **positional** (monospace-alignment) reading is different, because the header's whitespace
absorbs the unnamed `u1`:

| header name | name-order gives | **positional gives** |
|---|---|---|
| `word` | `u1` | `word` ✔ |
| `dp` | `word` | **`dp` ✔** |
| `mem[dp]` | `dp` | `acc` |
| `acc` | `acc` | `accb` |
| `P` | **`accb`** | (nothing lands there) |
| `tA` | **`p`** | **`p`** — the one both readings agree on |
| `tB` | `cur` | `coef` |

⇒ **`dp` is positionally CORRECT.** The `0xD0` mis-attribution is therefore **100 % the
pre/post sampling-phase defect (audit §5.1) and 0 % the 13-over-12 header (audit §6.1)**. The
brief files it under DEFECT 1; it belongs entirely to the compounding clause.

**Generalised header-arity sweep** (self-test T6): across all 28 logs, **the frame trace is the
only genuine mismatch**. Four other apparent mismatches are whitespace-tokenisation artefacts
(`|`, `=`/`*` markers, `a..b` ranges). Notably **`§213`'s table prints `dpPre` AND `dpPost`
explicitly — `§213` is immune to the phase ambiguity by construction.**

**Every trace-reading conclusion, adjudicated** (81 units reference the trace; 17 survived the
column filter):

| unit | reads | verdict |
|---|---|---|
| `OUTPUT-STAGE-NULL_findings.md` §1.2 / §3(c) — `m_dp = 0xD0` at `iw205` | trace `dp` (**post-exec**), positionally correct name, wrong *phase* | **AT RISK (phase) — ALREADY RETRACTED IN PLACE** at line 1 since `e49da4b` 07-31 11:34. Correct cell `0x85`; `0x85 + 0x4B = 0xD0`. **Verified in 6 independent logs** (§3.1a) |
| `SPECULATIVE-APPLIED-REGISTER.md` §89 (`:4949`) — *"`iw213` does not apply its post-increment"* | trace `dp` across **consecutive** slots | **SAFE.** A *delta* is invariant to a uniform one-word phase offset, and post-exec is the **correct** instrument for "did this word increment". Confirmed by §90's fix |
| `SPECULATIVE-APPLIED-REGISTER.md` §129 §2 — *"bank 1 executes against the delay-tap table"* | trace `coef` | **SAFE (shift).** Quoted values are real 6-hex `%06X` coefficients and are **bit-identical to the independent C-RAM dump** (`C-RAM 70: 000000 0004BE 00097C 000E3A…`). Decoded positionally, corroborated by a second instrument. *(Pooling: §3.2)* |
| `SPECULATIVE-APPLIED-REGISTER.md` §150 §1 | trace, **with the real order written out inline**: *"columns `n iw u word dp acc accb P cur coef MUL L`"* | **SAFE.** Verified: `MUL = 'Y'`, `P = −666 370 572 288`, `L = −8 388 608` all map correctly |
| `PREDICT_S1_hi12_bench.md` §3.4 | trace, columns relabelled `n iw u1 word hi12 dp d(acc) acc P L` | **SAFE.** Checked against real row n=13: `acc 1 028 206 280 788`, `P 239 225 266 218`, `L 8 388 607` — all correct |
| `PREDICT_S1_hi12_bench.md` §3.1 / §6, `OUTPUT-STAGE-NULL` §7, `IW205-DRAM-D0` §0, `INSTRUMENT-AUDIT` ×6 | — | **NOT AT RISK.** These *describe* the defect or *are* the correction; detector positives by design |

⇒ **Open, uncorrected shift/phase risk: ZERO.** The audit's own conclusion — *"the one note that
uses it decoded the real order"* — is upheld and extended: **every** note that reads the trace
decoded it correctly.

#### 3.1a The `0xD0` correction, verified in six logs

```
   trace  n=135  iw205  020224B1CD  dp D0      (POST-exec)
   §104          iw205  020224B1CD  dp 85      (PRE-exec)   mem quiet 0..0 / loud 0..0
   §104          iw206  000020040E  dp D0                   0x85 + 0x4B(addr8) = 0xD0
```

Identical in `drpub_{A_off,B_on,C_on_src0b2}_217`, `A_epibus_221`, `B_epibus_noz05_221`,
`C_noz05_220` — **including the arms where body 0 runs on live audio**. **MEASURED.**

### 3.2 The POOLING — it fired, in 9 logs, all of them pre-§148

**Detector.** `§104`'s `nq/nl` counts settled frames per I-RAM slot. In a single-program run every
executing slot executes on every frame, so `nq/nl` is one constant on every row. A **spread** is a
positive indicator of a program change inside the census window.

| vehicle era | logs | `§104` rows | distinct `nq/nl` | verdict |
|---|---|---|---|---|
| pre-§148 (`peq_gain`) | `peq_flat`, `peq_trace_base`, `peq_rebase_bit38`, `peq_rebase_confounded`, `demux_sweep`, `bodyonly`, `stale138`, `ship_10E446A39B440F`, `ship_46A39B440F` | **321** | **16–17** | ⛔ **MULTI-PROGRAM** |
| §148 onward (`coldnotes2.lua`) | the other **19**, incl. every `211/213/215/217/220/221/222` arm | **285** | **1** | ✔ single-program |

**Three independent corroborations that this is a program change and not noise:**
1. The 9 pooled logs have **36 extra slots**, `iw154..189`, absent from every clean log.
2. **70 of the 285 shared slots carry a different `word`.**
3. The 36 slots whose quiet count is `< 10⁶` are **exactly** `iw154..189` — set equality, not overlap.

★ **The loud bucket is NOT pooled** (`nl` constant at 291 193 on all 321 rows): the program change
happened inside the quiet window. So in those logs a `quiet`-vs-`loud` verdict is confounded while
a loud-only reading is not — a sharper statement than "the log is pooled".

★ **RULE 3: the project already governs this.** LEDGER TIER 0c **standing rule 2** (from §148):
*"the `peq_gain` vehicle creates a unit-1 rail through ~55 mid-run effect uploads; use it for
**deltas only**."* And §193/§194 already voided the navigated runs outright. My detector
independently re-measures what that rule was written for.

**Conclusions resting on a pooled log — the complete list (11):**

| unit | verdict |
|---|---|
| `SPECULATIVE-APPLIED-REGISTER.md` §105 (×2 subsections) | **AT RISK (pooling)** — but the section's own heading is *"**REFUTED MECHANISM**"*; not in LEDGER-HEAD |
| §106, §108, §110, §120 (6 subsections) | **AT RISK (pooling)**, low. §108/§110's targets were *"measured out of existence"* by §165 (LEDGER dead-ends #1/#2); §120 is cited by **0** later sections |
| §129 §2/§3 | **SAFE in substance.** §2's evidence is a **single frame's trace** (a genuine one-shot: `m_trace_n` re-zeroes on arming, disarms at print) plus the C-RAM dump — a single frame cannot pool. §3's `§70`/`§61` zeros survive by monotonicity (§6) |
| `data/PREDICT_142.md` | pre-registration, superseded |
| `data/SRC08_findings.md` §2 | cites `peq_rebase_bit38`; its four reasons are static/corpus arguments |
| `SPECULATIVE-APPLIED-REGISTER.md` §135 §4 | **already retracted** (`⛔ §135 §4 IS RETRACTED`) — skipped |

⇒ **No live TIER-0 / TIER-0a claim rests on a pooled log.** Everything in the current blocker
chain (§211 → §213 → §215 → §216 → §217 → §218 → §219 → §220 → §221 → §222) uses the clean vehicle,
and I verified all 19 of those logs read **one** `nq/nl` value.

---

## 4. VOID — `PREDICT_S1`'s F1, upgraded from FORCED to MEASURED

F1's **PASS** condition is *"`D-RAM WRITES` **total** at the cell under `m_dp` at `iw119` rises vs
the control arm"*. `m_dwr[]++` sits in its own brace block **after** the store guard closes, at
both sites (`b03e9d6:1932`, `:3483`) — so suppressing a store cannot move the total.

**The empirical proof, from two logs already on disk.** `UPD6383_NOZ05` suppressed **3 528 080**
bit-4 stores between `A_epibus_221` and `B_epibus_noz05_221`:

```
   cells whose D-RAM WRITES  TOTAL  changed :   0  of 256
   cells whose D-RAM WRITES NONZERO changed :   9  of 256
   e.g.  05:  A 4 703 996/5 908 625   ->  B 5 879 993/5 908 625
         0E:  A 1 180 800/3 566 218   ->  B 3 531 836/3 566 218
```

⇒ **F1 is VOID. Grade upgraded FORCED → MEASURED.**

★ **And this names a cheaper fix than the audit's.** The audit proposes re-expressing F1 on
`§104`'s `mem` column or `§109`'s `store_probe`. **The `nonzero` half of the *same printed line*
already moves under exactly the intervention F1 wants to detect** — 9 of 256 cells — so F1 can be
re-expressed as *"`D-RAM WRITES` **nonzero** at the cell under `m_dp` at `iw119` rises"* with **no
new instrument, no rebuild, and no change to the log format**.

★ **Blast radius: ZERO recorded conclusions.** The `a70` bench has **never been run** (no `a70`
log exists). The void was caught at pre-registration — the best possible time — and
`BUILD-LANE-QUEUE.md` item 3 already carries *"Replace `PREDICT_S1`'s calibration — its falsifier
F1 is VOID"*.

---

## 5. ★★★ NEW — the pre-increment trap, FOURTH occurrence, on the CURSOR (and it CLOSES an open item)

`OUTPUT-STAGE-NULL_findings.md` §7 HONEST LIMITS records, unresolved:

> *"The `coef 0..24` attenuation at `iw112` is read from `§175 PER-SITE 0202A071D5`. The frame
> trace's `coef` column at the same slot prints `0x1364D9`; the two are sampled at different
> points in the word and **I have not reconciled them**."*

This sits on §221's TIER-0a handover as next-task item (2). **It reconciles, from logs on disk:**

```
   trace n=77  iw111  0092200700  dp 05  … cur 08  coef 000018   (= 24)
   trace n=78  iw112  0202A071D5  dp 0C  … cur 09  coef 1364D9
   §175  PER-SITE 0202A071D5  coef 0..24   m_dp 5..5
   §104  row 112              dp 05
```

`t.cur`/`t.coef` are assigned **after** `exec_decoded()`, in the same block as `t.dp`. So the
coefficient printed on a trace row is the one **parked for the next slot**, and `iw112`'s actual
multiplicand is the *preceding* row's `coef` — `0x000018 = 24`. **Tested across all 18 `§175`
per-site words:**

```
   §175 consumed coef == the trace row's OWN coef     :  2 of 18
   §175 consumed coef == the PRECEDING trace row's    : 17 of 18
```

⇒ **The two instruments do not disagree; they are one cursor step apart.** `§175`'s `24` is the
consumed value and is the correct one, so **the `×24` attenuation at `iw112` STANDS and is now
reconciled rather than merely unexplained.** Grade **MEASURED**, `drpub_C_on_src0b2_217`.

⚠ This extends audit §5.1 from `dp` to **`cur` and `coef`**: *three* trace columns are post-exec
while their `§104`/`§175` namesakes are pre-exec. The `OUTPUT-STAGE-NULL` banner called `w79` the
"third occurrence"; **this is the fourth, and the first on the cursor.**

⚠ **A related hazard the audit did not name, low severity:** `§104`'s `acc` column is
`m_cur_unit1 ? m_accb : m_acc` (unit-dependent) while the trace's `acc` is always ACCA. Same name,
two quantities. Every note checked reads it correctly (`OUTPUT-STAGE-NULL` §1.2 labels `iw202..205`
as ACCB, which is right), but it is a third member of the same family.

⚠ **And one more, low severity:** `§104`'s `*`/`=` marker is a **raw** quiet-vs-loud difference and
is **not** RULE-12 filtered. Verified: all 7 raw `*` markers in arm A's body 0 are free-running
(identical delta on both range endpoints — `iw89 +4`, `iw90/91 +262 144`), which is why
`s104_score.py` reports body 0 `0/0/0` where the raw marker count gives `2/4/1`. **Quote the
tool's number, never the log's marker count.** (§211's standing rule 12 named `iw90/91`;
`iw89`/`iw92` join them.)

---

## 6. THE LOAD-BEARING ITEMS THE BRIEF NAMED, EACH CHECKED

| item | instrument | verdict |
|---|---|---|
| **`§70`/`§211` `min == max == 0`** | `m_pa_*`, `m_pb_*` | ★ **SOUND. NOTHING IN THIS ANALYSIS CHANGES IT, AND I SAY SO PLAINLY.** (a) **Shift-immune** — two dedicated `logerror` lines with named fields, not a table (T5). (b) **Pooling-immune** — min/max are monotone, pooling can only *widen* a span, and the span is 0; so the untested 400 000–420 000 window can only have contained zeros too. (c) `device_reset()` (`:451-474`) re-inits `m_kq/kl_*` but **not** `m_pa_*`/`m_pb_*` — verified; a zeroed sentinel would have *manufactured* the null and does not exist. (d) **Independent corroboration the audit did not use:** `§63 PRESENT` prints `ACCA`, `ACCB` and `pacc` **separately by name**, unconditionally, and reads `ACCA=0 ACCB=0 pacc=0` in every arm — including the NOZ05 arms. That also neutralises audit defect 1.a *empirically*, not just by mask arithmetic. (e) Read across **all 28 logs**: `0..0 / 0..0` in 26, RULE-19 mean 0.0 span 0. **MEASURED** |
| **§221 `F1 = 0 of 14`** | `§E1` provenance | **SURVIVES.** Re-extracted from both logs. Arms at frames **> 900 000** — a *fourth* threshold, and the cleanest: it excludes the boot entirely (`226 040 quiet / 313 960 loud = 540 000`). Not a trace table. **MEASURED** |
| **§221 `F1b`** (`w65 ← iw332` via `m_rf[0x8F]`, 540 000/540 000, value zero) | `§E1` last-writer column | **SURVIVES.** Corroborated independently: `§104` row `iw332` `acc = 0..0` in **both** buckets in every arm — so body 1 does write `m_rf[0x8F]` with a dead accumulator, exactly as F1b says |
| **§221's empty `§E1` diff between arms** | `§E1` | **VERIFIED BYTE-FOR-BYTE.** 18 of 18 rows identical A vs B; all four F-lines identical. **MEASURED** |
| **§220 `28/32/28`, body 1 `2/1/2`** | `§104` | **VERIFIED, recomputed from the raw rows.** arm C / arm B(221): kernel A `33/40/29`, body 0 `28/32/28`, body 1 `2/1/2` (the two acc slots are `iw203`, `iw204`), epilogue `0/0/0`. The §215 `SRC0B2` arm gives body 0 `28/32/28` too — §220's convergence claim reproduces. Single-program logs (§3.2). **MEASURED** |
| **§46 `0 → 3 494 021`; §75 `1 175 999 → 2 351 009`** | ungated counters | **SURVIVE.** Both are ungated (RULE 16) — but arm A reads **exactly 0**, and a zero cannot be inflated by boot contamination; both arms share an identical boot and identical frame totals, so the **delta** is sound even though the absolute window includes the boot. **MEASURED** |
| **§219's send localisation** (`iw35`/`iw45` overwrite cell `0x05`; the constant `4 194 304`) | `§104` **`mem`** + `§96` writer census | **SAFE.** §219 §3 explicitly names its column *"`mem` under the pointer, sampled **BEFORE** each word"* — i.e. the sound instrument, with the phase stated. `4 194 304 = 0x400000` is `acc_to_datum` arithmetic, independently confirmed by `§41 LEVEL unit0 0x400000` and `§221 F3`. **No trace column anywhere in the chain** |
| **The `iw205` chain** (ACCB dies → 128 of 133 → `iw332` → `w65`) | `§104` `acc` + `§E1` | ★ **VERIFIED END TO END, and it never needed the trace.** Body 1 has exactly **133** slots (`iw200..332`); exactly **128** have `acc` identically `0..0` in both buckets; **all 128 are `iw ≥ 205`**; `iw202..204` carry `5 206 020 096`; `iw205 → 0`; `iw332 → 0` feeds `w65`. Identical in `drpub_A_off_217`, `C_noz05_220`, `B_epibus_noz05_221`. The **only** trace-derived element was the `m_dp = 0xD0` sentence, already retracted. **MEASURED** |
| **§41 presentation LEVEL** | `m_lvl_seen` last-value latch | **LOW RISK, already answered in-log.** `unit0 0x400000 (nz on 1 172 160)`, `unit1 0x178D0B (nz on 1 172 160)`; the 31 680 shortfall of 1 203 840 *is* the ungated boot. `m_lvl_nz` supplies the denominator, and `§221 F3` confirms the same value by a second route |
| **§86** | `m_kq/kl_min/max` | **SOUND.** `device_reset()` **does** re-initialise it (`:463`, verified in the HEAD source), guard-gated at 420 000, prints its denominator |
| **§109** | `store_probe`, `SPROBE_ST = 4` | **UNQUANTIFIED, unchanged.** Not touched by shift or pooling. Its two mask-bit states and the store-gate disagreement count (`6 000 960`) print unconditionally |
| **§160**, **§186** | `m_rf`, `m_hostw_*` | **SOUND.** Explicit denominators, verified across four logs (`41`/`42` non-zero cells; `63 writes over 59 cells (42 ever non-zero)`) |
| **§200** | delay-age census | **SAFE** for the shift/pooling questions — per-descriptor `hits` counters, identical across all clean arms |
| **§150** | trace, real order written inline | **SAFE** (§3.1). Cited by 7 later sections; none of them inherits a shift |

---

## 7. ⚠ ONE LIVE OBSERVATION FOR §222's LANE — NOT ADJUDICATED HERE

Reading `§70`/`§211` across all 28 logs turned up **two arms that are not zero**, and they are
§222's, produced during this pass.

⚠ **§222 re-ran all five arms while this note was being written** (`ff4d54c`, 07-31 13:02,
*"obey the instrument audit — gate raised to 420 000"* — i.e. audit **R6** applied, `§70`/`§211`
now report `quiet frames 706 040`, matching `§104`'s window). **The verdict did not move.**
Numbers below are the **post-re-run** ones:

```
   A_pickup_222 (XB85=0), B_pickup_noz05_222 (XB85=0), E_xb85_latch_222 (XB85=3):  0..0 / 0..0

   C_xb85_full_222  (XB85=1)  §70   quiet 352 943 168 421 .. same          (span 0)
                                    loud   23 036 332 216 .. 352 943 168 421
                              §211  quiet 1 212 718 186 496 .. same        (span 0)
                       RULE 19  §70  loud mean 352 935 830 162.3  span 329 906 836 205
                                §211 loud mean 1 212 708 031 370.7 span 1 207 096 377 344
   D_xb85_route_222 (XB85=2)  identical §70; §211 loud span 1 245 317 496 832
```

★ Two things the raised gate settles for free: the 20 000-frame boot window the audit flagged
(defect 1.b) is **gone** — `§70` and `§104` now share one window — and the **zero arms stayed
zero across the gate change**, which is exactly the control that window needed.

**This is §222's experiment, it is uncommitted and in flight, and I am not interpreting it.**
Three things belong in the record, all about the *apparatus*:

1. **The RULE-13 no-stimulus control is present and reads a CONSTANT** (quiet span **0** in both
   arms). A quiet-window constant of 3.5 × 10¹¹ is precisely the DC shape RULE 19 exists to catch.
   **`|mean| >> span` is not satisfied** here, so RULE 19 does not by itself dispose of it — and
   equally does not endorse it. **No audio claim is made or implied.**
2. ⇒ **Every recorded conclusion phrased as an absolute — *"`w73`/`w78` are STILL EXACTLY ZERO"* —
   is now ARM-CONDITIONAL and must be quoted with its arm** (standing rule 11, *cite the run, not
   the section*). The shipped default and the NOZ05 rig remain zero: §222 arms A and B confirm it.
3. This is a **finding about how the claim is worded**, not about the chip.

---

## 8. RANKED RISK LIST, WITH THE CHEAPEST CHECK FOR EACH

Ranked by how load-bearing the conclusion is — measured by citation count, not by impression
(`§` cross-reference graph over the register's 201 numbered sections plus 96 note files).

| # | conclusion | cited by | class | status | **cheapest check** |
|---|---|---|---|---|---|
| **1** | `PREDICT_S1_hi12_bench.md` **F1** — the pre-registered *calibration* for the whole `a70` bench | the bench is **unrun**; queued in `BUILD-LANE-QUEUE.md` #3 | **VOID** | **CONFIRMED, grade upgraded FORCED → MEASURED** | ✅ **already done, zero cost, §4.** Then: re-express F1 on the **`nonzero`** half of the same `D-RAM WRITES` line — 9 of 256 cells moved under the very intervention F1 must detect. No new instrument, no rebuild |
| **2** | `OUTPUT-STAGE-NULL_findings.md` §1.2/§3(c) — `iw205` reads `0xD0` | §221, TIER-0a | **shift/phase** | **ALREADY RETRACTED IN PLACE** (`e49da4b`, 58 min pre-audit). The *conclusion* `ACCB ← 0` stands on `§104`'s `mem` | ✅ **already done.** Residual action is editorial: the audit's headline #2 and risk-list #1 should be marked stale |
| **3** | `OUTPUT-STAGE-NULL_findings.md` §7 — `iw112` `coef 0..24` *"unreconciled with the trace column"*; on §221's next-task list | §221 TIER-0a, §222 | **phase (`cur`/`coef`)** | ★ **RESOLVED BY THIS PASS.** One cursor step, 17/18. The `×24` **stands** | ✅ **already done, §5, zero runs.** To re-confirm on any future log: `§175` consumed coef must equal the **preceding** trace row's `coef` |
| **4** | `§70`/`§211` `min == max == 0` — the "still silent" claim | **33** later register sections + **31** note files — *the most-cited conclusion in the corpus* | shift-immune, pooling-immune | ★ **SOUND. The null stands.** | ✅ **the one open action is DONE:** §222 raised the gate 400 000 → 420 000 (audit R6) at `ff4d54c` and re-ran all five arms — the zero arms stayed zero and the two windows now match. Residual: quote the arm (§7) |
| **5** | `§104` residency (`28/32/28`, `2/1/2`, the body-0 pickup) | **19** + **18** | pooling | **SAFE for every archived clean log** | ✅ **already done:** `nq/nl` spread test, §3.2. Re-run it (1 line) on any new log before quoting `§104` |
| **6** | `§86` cell census (`3 of 31`, `11 of 31`) | **17** + **8** | — | **SOUND** — reset, gated, denominator printed | none |
| **7** | `§46`/`§75`/`§77`/`§80`/`§48` delay counters | **13** + **11** / **11** + **6** | RULE 16 (ungated) | **LOW.** Arm A reads exactly 0, so the deltas are sound | divide each by `m_frames_run` and compare with `§104`'s `nq+nl` ratio |
| **8** | `§109` store-site tables | **13** + **10** | truncation, `SPROBE_ST = 4` | **UNQUANTIFIED** (audit §6.2) — untouched by shift/pooling | count `[siteN addr …]` groups per row in an archived log; **any row printing exactly 4 is a truncation suspect.** Computable now |
| **9** | `§211` output-stage findings | **11** + **14** | — | **SOUND**; `§213` already retracted its one bad lead | none |
| **10** | `§150` (`w73`'s multiply **does** issue) | **7** + **5** | shift-candidate | **SAFE** — real column order written inline and verified | none |
| **11** | `§129` §2 (bank 1 runs on the delay-tap table) | **3** + **6** | pooling-era log | **SAFE in substance** — single-frame trace + independent C-RAM dump | if ever re-quoted quantitatively, re-run on the clean vehicle; use the pooled log for **deltas only** (standing rule 2) |
| **12** | `§105`, `§106`, `§108`, `§110`, `§120` | 0–7, none in the live chain | pooling | **AT RISK, NOT LOAD-BEARING.** §105 self-labelled *"REFUTED MECHANISM"*; §108/§110's targets measured out of existence by §165; §120 cited by 0 | none unless resurrected; then re-run on the clean vehicle |
| **13** | `§41` presentation LEVEL | **4** + **5** | last-value latch, ungated | **LOW** — `m_lvl_nz` denominator + `§221 F3` second route | ✅ already answered in-log |
| **14** | `§160`, `§186`, `§200` | 4–5 + 4–8 | — | **SOUND** | none |

---

## 9. TEN-LINE SUMMARY

1. **2 675 claim units** parsed across **96** files; **2 368** cite a measurement; **205** are
   already retracted in their own heading and were skipped; **2 163 live conclusions** = the
   denominator.
2. **SAFE 2 149 · AT RISK (shift) 1 · AT RISK (phase, new) 1 · AT RISK (pooling) 11 · VOID 1.**
   **Zero of the 14 is an open load-bearing claim.**
3. **The shift is date-bounded.** The header was correct at 7/7 and 13/13 and broke at
   `db42362`, 2026-07-29 12:09:19 — the same second as register section "65-66". **57 of 201
   numbered sections predate it.** And **`dp` is positionally correct**, so the `0xD0` error is
   the *phase* defect, not the header — a correction to the brief's framing.
4. **The pooling fired, in 9 of 28 logs**, all pre-§148: 321 rows vs 285, 16–17 distinct `nq/nl`,
   and the 36 extra slots are *exactly* the 36 with ⅓ the quiet count. **All 19 post-§148 logs
   show zero spread**, and every log in the live blocker chain is one of them.
5. **⚠ Two RULE-3 corrections to the brief:** `OUTPUT-STAGE-NULL_findings.md` has carried the
   `0xD0 → 0x85` retraction at line 1 since **58 minutes before the audit**, and the `§104`
   type-walk pooling is **pre-registered verbatim** in `PREDICT_S1_hi12_bench.md` §4. Both are
   presented as newly-confirmed and are not.
6. **`§70`/`§211` SURVIVE.** Shift-immune (dedicated `logerror`, not a table), pooling-immune
   (min/max monotone, span 0), sentinels verified intact in `device_reset()`, and independently
   corroborated by `§63 PRESENT`'s separately-named `ACCA`/`ACCB`/`pacc` — which also neutralises
   audit defect 1.a empirically. `0..0` in 26 of 28 logs; RULE-19 mean 0.0, span 0.
7. **§221's `F1` (0 of 14), `F1b` (`w65 ← iw332`, 540 000/540 000, zero) and the empty `§E1`
   diff SURVIVE** — re-extracted from both archived logs, **18 of 18 rows byte-identical**, all
   four F-lines identical. `§E1` arms at frames > 900 000 and excludes the boot entirely.
8. **`PREDICT_S1`'s F1 is VOID, upgraded FORCED → MEASURED**: 3 528 080 suppressed stores moved
   **0 of 256** `D-RAM WRITES` totals and **9 of 256** `nonzero` counts. Blast radius **zero** —
   the bench was never run. The `nonzero` column is a drop-in replacement criterion.
9. **★ New, and it closes an open item rather than opening one:** the trace's `cur`/`coef` are
   post-`exec_decoded()` like `dp` (**17 of 18** `§175` sites match the *preceding* row), so
   `OUTPUT-STAGE-NULL` §7's declared-unreconciled `iw112` `coef 0..24` vs `0x1364D9` is resolved
   with zero runs, and the `×24` attenuation **stands**. Fourth occurrence of the trap, first on
   the cursor.
10. **Single most load-bearing conclusion at risk: `PREDICT_S1_hi12_bench.md`'s falsifier F1** —
    and it is at risk in the cheapest possible way, because the run it would have graded has not
    happened. **The most-cited conclusion in the corpus (`§70`/`§211`, 33 + 31 citations) is
    SOUND.** ⚠ Separately, §222's `XB85=1/2` arms are **not** zero (§7): that is §222's live
    experiment, its quiet control is a **constant**, and **no audio claim is made here.**
