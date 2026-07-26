# THE RETRACTION SWEEP — claims that outlived the model they were proved in

NEC **uPD6383GF-3BA** (Technics SX-KN5000, IC311). Date: **2026-07-26**.
No hardware. Static analysis, the ROM corpus and the document set only; nothing
here is a recording or a measurement on a live chip.

Tool: [`../tools/retraction_sweep.py`](../tools/retraction_sweep.py) — stdlib
only, re-runnable, and it prints every number quoted below:

```
python3 dsp/tools/retraction_sweep.py selftest   # ★ THE CONTROL -- run it first
python3 dsp/tools/retraction_sweep.py sweep      # the documents
python3 dsp/tools/retraction_sweep.py sweep -v   # ... plus every COVERED hit
python3 dsp/tools/retraction_sweep.py code       # ★ the SHIPPED artefacts
```

Labels: **MEASURED** / **PROVEN BY CONSTRUCTION** / **FORCED** / **CONSISTENT** /
**INFERRED** / **EDUCATED GUESS** / **OPEN**. Where the evidence admits several
readings they are enumerated, not chosen.

---

## 0. Result in one page

| # | statement | label |
|---|---|---|
| **A** | ★ **THE WORST CONCENTRATION IS IN `notes/kn5000-dsp-INDEX.md`, THE FILE A FUTURE PASS READS FIRST.** Its "Established" block — the project's own list of settled facts — carried **six** claims whose premises are withdrawn: the data-pointer origin `0x70`/`0x50`, "the pointer is reloaded every frame", "bit 23 = multiplier", "`880.1.60/20` = external-DRAM bracket", "`hi12=0xC40` = envelope detector", and "unit 1's bank base is `+0x80`". None carried a banner. **All six are now bannered in place.** | **MEASURED** |
| **B** | ★ **A DEAD CLAIM WAS HIDING AN OPEN DEFECT, AND NOBODY HAD CONNECTED THEM.** `kn5000-dsp-pointer.md` headline 3 explained away `-hi12.md` §5.1's negative result (the pointer never returns; net deltas `−87…+1149`, zero in 0 of 38) by saying the pointer *is reloaded every frame*. K3 withdrew the reload. **So the non-returning-pointer problem is re-opened — and it is numerically the same defect the live core now reports as the frame-closure residue `+121` on 1 130 880 of 1 130 880 complete frames.** A 2026-07-22 note declared solved exactly what the 2026-07-26 core measures as broken. | **FORCED** (the inheritance), **MEASURED** (both numbers) |
| **C** | ★ **NO CURRENTLY-SHIPPED CODE DEPENDS ON A RETRACTED PREMISE — checked, not assumed.** `m_dp` is written in exactly two places, both post-increment (`upd6383.cpp:734`, `:944`); `is_dram()` carries the C-format guard in **both** mirrors; the cursor advances on class A only; the bit-4 store is gated; and no `assert`/`fatalerror` rests on the input window. The 62-delay-RAM-words-as-arithmetic failure mode has **no live analogue**. | **MEASURED** |
| **D** | ★ **BUT THE SHIPPED CODE WAS STILL *ASSERTING* TWO RETRACTED LABELS, ONE OF THEM TO THE USER.** `dump_frame_report()` printed `FRAME CLOSURE (FORCED criterion: …)` on every run, and `upd6383.h` labelled the input-latch identification **FORCED**. Both rest on K6 finding 5, which `closure-pointer.md` item F falsified. **Downgraded to CONSISTENT / INFERRED (STRONG); the measurements are untouched.** | **MEASURED** → fixed |
| **E** | ★ **THE ONE-LINE SUMMARY OF THE WHOLE PASS: `closure-pointer.md` FALSIFIED K6 FINDING 5 AND NEVER WENT BACK TO K6.** The disasm tree's `README.md` advertised the falsification; `dsp-closure-applied.md` propagated it; `dsp-k6-input-stage.md` findings 4 and 5, and `dsp-frame-advance.md` §3.1 which inherits them, were **left standing unmarked** for the whole interval. All are now bannered. | **MEASURED** |
| **F** | **The sweep is a PROPAGATION checker with a validated control, not a truth oracle.** `selftest` plants 7 assertions that must come out LIVE and 5 retractions that must come out COVERED, and **passes both directions**. An empty result would otherwise mean nothing. | **MEASURED** |
| **G** | ★ **THE HARNESS REPRODUCED THE PROJECT'S OWN BUG ON ITS FIRST RUN, AND THAT IS REPORTED AS A MISS.** Its first classifier accepted *any* retraction word within ±3 lines. In `kn5000-dsp-INDEX.md` the phrase `an earlier "4 bands" was retracted` sits two lines below the "Roles" bullet and silently marked **three** live assertions COVERED — a banner about one claim read as covering another. Fixed: a nearby banner now counts only if that line **names the claim**. The fix moved 135 → 182 LIVE. | **MEASURED** — a **MISS**, self-inflicted |
| **H** | **Two of the brief's nine suspects are FALSIFIED as concerns: they were already fully propagated.** The **6 + 6 input-block split** has **zero** live assertions anywhere — the only hit in the corpus is K6 finding 2 falsifying it. **R3's unguarded DRAM family** likewise: `is_dram()` carries `!c_format(w)` in `upd6383d.h` *and* `dsp_disasm.py`, and the only textual hit is `instruction-set.md`'s own withdrawal row. | **MEASURED** — a falsification of the brief |
| **I** | **Effect of this pass, measured the same way before and after: 182 → 108 LIVE** (233 signature hits). Of the 108 remaining, **8 are in archival traces** (now covered by one file-level banner each) and the rest are historical prose in superseded notes, listed as the standing checklist in §5. | **MEASURED** |
| **J** | **Housekeeping, all re-run after every edit**: `dsp/verify.py` **BYTE-MATCH OK**; `tools/upd6383d_diff.sh` **MIRRORS AGREE — 3057/3057**; the rebuild is clean (0 `error:`, binary mtime 23:04 → 23:27, 74 401 488 bytes); `-validate kn5000` **exit 0, silent**. | **MEASURED** |

**Nothing here changes what the machine does.** No word gains a semantic, no frame
is made to complete, every currently-trapping word keeps trapping, and the device
diff contains **only comments plus one `logerror` string** (§4.3 shows the diff
filter that proves it). The product of this pass is propagated retractions, a
corrected label in shipped code, one newly-connected open defect, and a checklist.

---

## 1. Method, and why the control comes first

A retraction sweep is exactly the kind of pass that can produce a comfortable,
worthless "all clear". So the harness is built to be falsifiable:

* Each **retracted premise** carries `sig` patterns (text that *asserts* the claim)
  and `exempt` patterns (phrasings that only ever appear in a retraction).
* A hit is **COVERED** if the same line carries a retraction word; or a line within
  ±3 carries one **and names the claim**; or the file's head carries a banner that
  names the claim. Otherwise it is **LIVE**.
* The classifier is **deliberately biased toward LIVE**. A false LIVE costs one
  read. A false COVERED costs an un-propagated retraction — which is the entire
  failure mode this tool exists to catch.
* `selftest` runs planted assertions and planted retractions through the real
  `scan()` and **fails loudly if either direction stops working**:

```
  ok   assert   P1   -> LIVE      The data-pointer ORIGIN is unit 0 = 0x70, unit 1 = 0
  ok   assert   P10  -> LIVE      FRAME CLOSURE (FORCED criterion: the DI latches are
  ...
  ok   retract  P5   -> COVERED   the old 'envelope detector' reading is WITHDRAWN
  ok   retract  P11  -> COVERED   the external-DRAM bracket reading is FALSIFIED by th
  SELFTEST PASSED -- both directions work
```

**What it is not.** It cannot read a sentence. A LIVE verdict is a *prompt to read
the line*, never a proof the line is wrong — §4.2 is an entire section of LIVE
hits that turned out to be correct retraction prose.

### 1.1 ★ The harness's own MISS, reported rather than quietly fixed

The first version accepted **any** retraction word within the window. Run against
`notes/kn5000-dsp-INDEX.md` it produced this:

```
   line 75:  * PARAMETRIC EQ = 5 bands x 2 channels (... an earlier "4 bands" was retracted).
```

— and that single word `retracted`, about **band count**, marked as COVERED the
three live assertions two lines above it:

```
   line 72:  bit 23 = multiplier, `880.1.60/20.*` = external-DRAM bracket (MCC +0.944), ...
   line 73:  ... `hi12=0x082` = LFO read, `hi12=0xC40` = envelope detector,
   line 77:  ... unit 1's bank base is `+0x80`.
```

**This is the project's own bug, committed by the tool built to find it**: a
retraction about X taken as covering Y. It is recorded here rather than silently
corrected because the failure mode is the *point* of the pass. The rule is now
"a nearby banner counts only if it names the claim", and the correction moved the
count from **135 LIVE to 182 LIVE** — i.e. **47 assertions of retracted premises
had been invisible to the first design**.

---

## 2. The premise catalogue — and what each affected claim's fate is

Fourteen premises are tracked: the nine named in the brief, plus five the sweep
turned up. For each affected claim the verdict is **SURVIVES**, **DOWNGRADED** or
**RETRACTED**.

| id | withdrawn premise | killed by | fate of what depended on it |
|---|---|---|---|
| **P1** | `ldptr` (`lo12 = 0x821`) loads the **D-RAM operand pointer**; origin unit 0 `0x70`, unit 1 `0x50` | K3 §4, **FORCED** — `0x821` addresses C-RAM | **RETRACTED.** `kn5000-dsp-pointer.md` headline 2 bannered; INDEX bannered. Headline 1's *structural* find (the loads are in the common header, 83 words every static search excluded) **SURVIVES, MEASURED three ways** — only *which register* changed |
| **P2** | `801.0.NN.821` is the **coefficient cursor** | K3 §4, **FORCED** — pointer ≠ cursor | **RETRACTED.** Already honoured by both disassemblers and by `k4-cursor.md` §3.2's "do not model it as writing the cursor" |
| **P3** | the two units get **the two halves of C-RAM**; unit 1's base is `+0x80` | K4 §1/§4 — the resident table `0x50..0x8B` **straddles** `0x80` | **RETRACTED.** `cursor-general.md` headline 8 and the INDEX bannered. The `+0x80` **SURVIVES in a different space** — the class-1 register file (5 of 5 unit-1 selects are a unit-0 select `+0x80`) |
| **P4** | the output stage's host-written words carry a **linear level (×2/×4)** | K5 — they are **call vectors** | **RETRACTED as a semantic; SURVIVES as an unexplained numeric regularity**, which is what `kn5000-dsp-parameters.md` §8 already concluded ("not a UI parameter"). The hardware prediction is **inverted**: a disconnected unit goes silent, it is not attenuated by 6/12 dB |
| **P5** | `hi12 == 0xC40` = **envelope / level detector** | K5 §2.3 — wrong on **all 61 sites** | **RETRACTED.** Both disassemblers, the flowcharts and `programs.tsv` already carry it; the INDEX did **not** and now does. NB the *compressor's* detector **SURVIVES on other grounds** (its 2/π and 0.9629 constants), which is why `prog36`'s role line is unchanged |
| **P6** | "the chip has three ports and **this board uses one stereo pair**" | `dsp-audiopath-wiring.md` §1.1/§2, MEASURED from the service manual — **all three DI and DO are wired** | **REASON RETRACTED, CONCLUSION SURVIVES.** K6 finding 6 re-derived two-channel from independent evidence. `headerdecode.md` §4.2 bannered. The supporting step was a category error anyway: `addr8` is a pointer delta and could never carry a port index |
| **P7** | the input stage splits **6 + 6** | K6 finding 2, MEASURED — it is **0..6 / 7..11** | **NOT A CONCERN — ZERO live assertions in the entire corpus.** The brief's suspicion is **falsified** |
| **P8** | R3's **DRAM family without a C-format guard** | adjudication §1, **FORCED** | **NOT A CONCERN — fully propagated.** `is_dram()` carries `!c_format(w)` in `upd6383d.h` *and* `dsp_disasm.py`; MIRRORS AGREE 3057/3057. The brief's suspicion is **falsified** |
| **P9** | **K6 finding 5** — the I/O window is touched by **0 of 38** bodies; `X+2`/`X+5` **read and never written** | `closure-pointer.md` item F, MEASURED — **79 of 79** enter the window, 10 of 79 touch a latch | **FINDING 5 RETRACTED; FINDING 4 DOWNGRADED** from *MEASURED + FORCED* to **INFERRED (STRONG)**. The **offsets** +2/+5 **SURVIVE** — finding 3 is an origin-free pointer-rule walk |
| **P10** | the **frame-closure criterion is FORCED** | inherits P9 | **DOWNGRADED to CONSISTENT.** `dsp-frame-advance.md` §3.1 and item E bannered; **`upd6383.h` and `upd6383.cpp` corrected, including the string printed to the log**. The `+121` residue is **untouched** — what is lost is the entitlement to call it a defect (§3.2) |
| **P11** | `880.1.60/20` = external-DRAM **bracket** OPEN/CLOSE | R1 §5, **FORCED** — one is a **READ**, one a **WRITE** | **RETRACTED.** Both disassemblers already carried it; the INDEX did not and now does; `upd6383d.h`'s guard comment renamed (the guard itself never depended on it) |
| **P12** | `hi12` **bit 23 = multiply enable** | `-axes.md` §2.2 — it is the **cursor-fetch** enable | **RETRACTED.** `instruction-set.md` and `upd6383d.h` already carried it; the INDEX did not and now does |
| **P13** | the pointer **does not return because it is reloaded every frame** | inherits P1 | **RETRACTED, and it is the expensive one — see §3.1.** The explanation is gone and the phenomenon is back |
| **P14** | `lo12 = 0x827` inherits the **D-RAM-origin** slot | adjudication §5.1 — **0 of 85** streams | **RETRACTED.** Already honoured everywhere; `k3-pointers.md` §5.1's own narrative line is the only textual survivor and is historical |

---

## 3. The three propagation failures that mattered

### 3.1 ★ P13 — a retraction that re-opened a defect nobody re-opened

This is the most valuable single find, and it is a *connection*, not a new
measurement.

**2026-07-22**, `kn5000-dsp-pointer.md` headline 3, three stars:

> "That search was well posed and its negative result is now *explained*: the
> pointer does not return because **it is reloaded from the header every frame**.
> The premise was right and the conclusion drawn from its failure … was wrong."

The negative result being explained is `-hi12.md` §5.1: **no class subset, wrap
modulus or `hi12` bit gate makes any image's pointer return** — net deltas
`−87 … +1149`, zero in **0 of 38**.

**K3 then withdrew the reload.** `0x821` is a C-RAM pointer; `0x827` was falsified
at 0 of 85; `0x825` is the delay-descriptor pointer; `0x822` is the unit-1 level.
**Nothing in the decoded set loads the D-RAM pointer** — the shipped core says so
in `upd6383.cpp`, where `m_dp` is written in exactly two places and both are
post-increment.

So the explanation is gone, and the phenomenon it explained is **back**. And it is
not a historical curiosity:

```
   2022-era static search   pointer never returns over a program pass, 0 of 38
   2026-07-26 live core     FRAME CLOSURE residue +121, on 1 130 880 of 1 130 880
                            complete frames -- and the static walk independently
                            computes -135 = +121 (mod 256)
```

**These are the same defect.** One note declared it solved; the core measures it
unsolved; the two were never put side by side because the note that closed it was
never re-opened. **FORCED** (the inheritance is a chain of withdrawals, each
individually FORCED or MEASURED); the identification of the two as one phenomenon
is **CONSISTENT** — both are "the operand pointer does not come back", and the
mechanism that would fix both is the same missing absolute reload, localised by
`closure-pointer.md` item C to **I-RAM 50…78**.

### 3.2 ★ P9/P10 — what the closure downgrade does and does not cost

It costs **nothing measured**. `+121` is `+121`; the walk is unchanged; the
`m_frames_dp_closed` counter is unchanged.

What it costs is an **entitlement**. Before: "a non-zero residue is a
falsification of something". After: that is true under **Package B** and *moot*
under **Package A** (`closure-pointer.md` §4.1) —

* **Package A** — the pointer really is shared and nothing re-establishes it.
  Bodies legitimately write `X+0..X+6`; "externally supplied only" is false;
  **`+121` may not be a defect at all**. Against it: the machine would be
  scribbling on its own input window, and the two body entries would differ by an
  algorithm-dependent amount.
* **Package B** — something undecoded re-establishes the pointer per unit. Then
  the criterion holds and **`+121` is exactly the size of the hole**. Better bet,
  but it needs a **fourth** register: the three named ones are all spoken for and
  `0x827` is falsified.

**Neither is chosen here.** That is the honest state and it is now what the code
prints.

### 3.3 The INDEX — blast radius, not subtlety

`notes/kn5000-dsp-INDEX.md` is 188 notes' front door and its "Established" block
is the shortest path to a wrong belief in the whole project. It carried six dead
claims (item **A**). Two of them — "bit 23 = multiplier" and "`0xC40` = envelope
detector" — had been retracted **in the disassemblers themselves**, so the code
was right and the index was wrong, which is the configuration that costs the most
time: a reader trusts the summary and disbelieves the source.

---

## 4. ★ SHIPPED CODE — the dangerous case, checked directly

### 4.1 The executable check — nothing depends on a retracted premise

| what could have gone stale | state | evidence |
|---|---|---|
| `ldptr` writing the D-RAM pointer | **clean** — writes `m_cp` | `upd6383.cpp:976` |
| anything else loading `m_dp` | **clean** — nothing does | `m_dp =` occurs twice, both post-increment (`:734`, `:944`) |
| DRAM family without a C-format guard | **clean, both mirrors** | `is_dram()` = `(hi12 & HI_ESC) && class4 == 1 && !c_format(w)` in `upd6383d.h`; same in `dsp_disasm.py`; MIRRORS AGREE 3057/3057 |
| cursor advancing on any class with bit 3 | **clean** — class A only | K4 item I, honoured in `exec_addressing_only()` |
| bit-4 store generalised without its gate | **clean** — gated on `hi12` bit 7 | `exec_alu()` / `exec_addressing_only()` |
| an `assert`/`fatalerror` resting on the I/O window | **none exists** | the input-stage check is a **comparison**, `upd6383.cpp:1466` |

**MEASURED.** The `62 delay-RAM words executed as arithmetic` failure has no live
analogue.

### 4.2 The eight LIVE hits in code are all retraction prose — a false-positive census

`retraction_sweep.py code` reports **8 LIVE**, and **all 8** are lines that state a
withdrawn claim *in order to withdraw it*, with the banner word more than three
lines away (e.g. `upd6383d.cpp:240`, the withdrawn-claims block; `upd6383.cpp:993`,
the `0x827` retraction; and `upd6383.cpp:1577`, which is **this pass's own
banner**). Reported rather than suppressed: it is the measured false-positive rate
of the classifier on code, and it is **8 of 8**, i.e. on this corpus the code scan
finds no real assertions and says so loudly. That is the correct behaviour for a
tool biased toward LIVE.

### 4.3 What was changed, and the proof it is inert

Two labels, one of them user-visible:

```
-	logerror("    FRAME CLOSURE (FORCED criterion: the DI latches are at fixed chip\n");
+	logerror("    FRAME CLOSURE (CONSISTENT, no longer FORCED: the criterion rests on K6\n");
+	logerror("    finding 5, which closure-pointer.md item F FALSIFIED -- 79 of 79 bodies\n");
```

plus retraction banners in `upd6383.h` (the input-latch FORCED label), `upd6383.cpp`
(the closure comment, the stale `ldptr #$90` steady-state sentence, and the
modelling-choices entry that still claimed "only the `0x821` form is decoded at
all") and `upd6383d.h` (the "external-DRAM bracket" naming vestige inside a guard
comment — **the guard itself never depended on it**, it only ever cared that class
1's `addr8` is not a pointer delta).

**The diff contains no executable change**, and that is checked mechanically
rather than asserted:

```
git diff -U0 -- src/devices/cpu/upd6383/ | grep -E '^[+-]' \
  | grep -vE '^(\+\+\+|---)' | grep -vE '^[+-][[:space:]]*(//|\*|/\*)' \
  | grep -vE '^[+-][[:space:]]*$'
```

leaves only the `logerror` block above and prose inside the top-of-file `/* */`
comment. No predicate, no `exec_*`, no state.

**Safety, re-verified after the rebuild:** `-validate kn5000` exit 0 and silent;
MIRRORS AGREE 3057/3057; `dsp/verify.py` BYTE-MATCH OK; build clean (0 `error:`,
binary 74 401 488 bytes, mtime advanced 23:04 → 23:27). The `DSPCFG` ioport is
untouched and still defaults **OFF**; with it off the device's execution path is
not entered at all, and since the diff changes no executable statement the
rendered audio is bit-identical **by construction** — this is stronger than an A/B
render, and the filter above is the evidence.

---

## 5. ★ THE CHECKLIST — re-runnable, for a future pass

```
python3 dsp/tools/retraction_sweep.py selftest && \
python3 dsp/tools/retraction_sweep.py sweep && \
python3 dsp/tools/retraction_sweep.py code
```

**How to read it.** `selftest` must pass first — if it does not, every other number
is meaningless. Then: **`code` LIVE hits are the emergency**; `sweep` PROSE hits
are the worklist; `sweep` ARCHIVAL-TRACE hits need one file-level banner, never a
per-row edit.

**Standing state after this pass** — the baseline a future run compares against:

| scan | signature hits | LIVE | of which prose | of which traces |
|---|---|---|---|---|
| `sweep` (documents) | 233 | **108** | 100 | 8 |
| `code` (shipped) | 21 | **8** (all false positives, §4.2) | 8 | 0 |

**A rise in `code` LIVE is the alarm.** A rise in `sweep` LIVE usually just means
somebody wrote a new note.

**When a claim is withdrawn, add a premise to `PREMISES` in the tool.** That is the
whole maintenance burden, and it is what turns a one-off audit into a ratchet.

**Known residual LIVE, triaged and deliberately left:**

* ~64 rows in `dsp-perframe-execution.md` / `dsp-audiopath-wired.md` /
  `dsp-k6-input-stage-applied.md` — **archival traces**, now carrying one banner
  each. The wrong label *is* the evidence; rewriting it would destroy the record.
* `closure-pointer.md` §4.1's "under Package B … closure is FORCED" — correctly
  **conditional** prose; a false positive.
* Historical prose in superseded notes (`kn5000-dsp-class2.md`,
  `-class2-round2.md`, `-core-draft.md`, `-effect-map.md`, `-paramsemantics.md`,
  `-biquad.md`) that predates the retraction. Lower value than the front door;
  the INDEX is what a reader hits first and it is fixed.
* `dsp-critical-path-coverage.md` §B13 still lists "envelope detector" as a
  **work item** (TIER 5). Harmless — the item is "decode these words" and they do
  need decoding — but the *name* is dead. Flagged, not rewritten.

---

## 6. PREDICT-THEN-CHECK — every prediction, including the misses

| # | prediction | outcome |
|---|---|---|
| **Pred-1** | the `ldptr → m_dp` retraction reached the shipped core | **HIT.** `m_cp = ad`, with the K3 citation next to it |
| **Pred-2** | R3's DRAM family carries the C-format guard in both mirrors | **HIT**, and MIRRORS AGREE 3057/3057 confirms they cannot silently diverge |
| **Pred-3** | K6's own document was never updated after `closure-pointer.md` falsified finding 5 | **HIT** — findings 4 and 5 stood unmarked |
| **Pred-4** | the closure criterion's FORCED label survives in `dsp-frame-advance.md` | **HIT**, §3.1 and item E both |
| **Pred-5** | ★ my first banner-proximity rule would be too generous | **HIT, and it cost three real assertions** in the INDEX before I caught it (§1.1). Recorded as a **MISS of the design**, not of the prediction |
| **Pred-6** | the `+0x80` C-RAM claim would be the least propagated of the brief's nine | **MISS.** It was already bannered in `dsp-k4-cursor-rebase.md` and in `instruction-set.md`; only the origin note and the INDEX lacked it. The least-propagated was **P13**, which the brief did not list at all |
| **Pred-7** | the 6 + 6 split would still be asserted somewhere | **MISS — zero occurrences.** The brief's concern is falsified (item **H**) |
| **Pred-8** | the archival trace files would need per-row edits | **MISS, and a useful one.** They need exactly one banner each; per-row edits would have destroyed the evidence of the very bug the traces document |
| **Pred-9** | some shipped code would have an *executable* dependency on a retracted premise | **MISS — none does** (§4.1). The damage was confined to labels, one of which was printed to the user every run |

---

## 7. What this constrains for the other two targets

**For TARGET 1 (retest the all-pass impossibility under the adder model).**

* The negative result's stated cause — *the `hi12` bit-4 store "stores and CLEARS
  right before `tempA` is last writable"* — is a claim about a mechanism the adder
  model **replaced**. That is textbook P-inherits-a-withdrawn-premise, and it is
  **not** in this sweep's catalogue because `action-field.md` states it as a
  *result*, not as a cited premise. **Add it as P15 when it is retested**, whatever
  the outcome: if it survives, the banner records that it was re-derived under the
  new model; if it dies, the banner records why.
* The bit-4 store is now **GATED** (`hi12` bit 7), and 19 corpus words TRAP on the
  gate. Any re-run of the all-pass search must use the **gated** store or it is
  searching a machine that does not exist.
* **A control is mandatory and there is a proven one**: the hand-built Gardner
  ladder accepted at 2/4/5 stages in the same executor. Reuse it — an empty result
  set from an executor that cannot say YES is worth nothing, and that is exactly
  how the original search earned its credibility.

**For TARGET 2 (the output stage, I-RAM 60…82, 8.7 % decoded).**

* ★ **Two of this sweep's retractions land directly in it.** `w64`/`w71` are
  **`setvec` call vectors, not levels** (P4) — so a decode that predicts
  attenuation is predicting the wrong thing; the hardware prediction is
  **inverted** (disconnect ⇒ **silence**). And three of the four host-written
  words were, until recently, printed as *"envelope / level detector"* (P5) with
  two of them also printing `cur+`.
* ★ **The output stage is the region the closure work points at.**
  `closure-pointer.md` item C: the admissible reload-site set is **I-RAM 50…78**,
  and **60…78 is admissible unconditionally**. Item D: the epilogue tail is
  exactly **−1**, so an epilogue-sited reload gives `X = V − 1` — the same relation
  K6 §5 derived from the one-sample feedback loop by a completely different route.
  **A decode of the output stage is the most likely place to find the missing
  absolute pointer reload**, which is the same mechanism that would close §3.1's
  re-opened defect.
* Do **not** re-import "the two host-written words carry a level" from any note
  that still says it; and note that `closure-pointer.md` §5 leaves a **FORCED
  disjunction** open — either a D-RAM pointer reload exists in I-RAM 50…58, **or**
  the mode-1 register space and the mode-2 D-RAM are not one RAM.

**For both.** `kn5000-dsp-pointer.md`, `kn5000-dsp-cursor-general.md`,
`kn5000-dsp-headerdecode.md` and `kn5000-dsp-INDEX.md` now carry banners. If a
future pass quotes one of them, quote the banner too.

---

## 8. Files touched

**Bannered in place (nothing deleted):**
`notes/kn5000-dsp-INDEX.md` (six claims), `notes/kn5000-dsp-pointer.md`
(headlines 2 and 3), `notes/kn5000-dsp-cursor-general.md` (headline 8),
`notes/kn5000-dsp-headerdecode.md` (§4.2), `notes/dsp-k6-input-stage.md`
(findings 4 and 5, and §5), `notes/dsp-frame-advance.md` (item E and §3.1),
and one file-level banner each on `notes/dsp-perframe-execution.md`,
`notes/dsp-audiopath-wired.md`, `notes/dsp-k6-input-stage-applied.md`.

**Shipped code (labels only, §4.3):** `src/devices/cpu/upd6383/upd6383.cpp`,
`upd6383.h`, `upd6383d.h`.

**New:** `dsp/tools/retraction_sweep.py`, this file.
