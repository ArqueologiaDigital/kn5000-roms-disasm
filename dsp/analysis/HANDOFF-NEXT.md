# HANDOFF — read this first

**Rewritten 2026-07-30 after §§127–146.** Read this, then
`SPECULATIVE-APPLIED-REGISTER.md` **§143 first** (it corrects §127, §131 and §135), then
§§144–146. Several earlier sections are retracted *in place*; trust the register tail over
any older summary, including older parts of this file.

---

## 1. YOUR NEXT TASK

**Decode the LFO → DELAY-TAP link. It does not exist in the model (§149).**

§148 asked for an observable downstream of the LFO; §149 found there is no downstream.

* **The LFO half already works** — §109's phase cell advances by exactly **114 per frame**,
  CHORUS's ROM increment (0.599 Hz). MEASURED, and identical across arms.
* ⛔ **`upd6383.cpp:1813`: `addr = (cellv + m_frames_run) & 0xffff`** — descriptor cell plus the
  free-running frame counter and **nothing else**. No accumulator, no temp, no phase term.
  `m_frames_run` is the circular-buffer rotation `G` (`r3-delaydram.md` §5.1), which is correct
  and is **not** modulation.
* ⇒ **A swept delay cannot exist.** Every chorus / flanger / vibrato in the machine depends on a
  mechanism the emulator does not have, and this is the whole reason `SRC 0x00 = coef` measured
  inert downstream.

★ **The candidate, SPECULATIVE (strong).** CHORUS's two modulated delay READs are each preceded by
a byte-identical idiom, with the LFO twin and its phase-read a few words earlier:

```
   C40.3.20.44C     C-format immediate
   A00.0.00.041     SRC 0x01, ACT 0x01     <- immediately before the read, both times
   880.1.20.2C7     THE DELAY READ (addr8 = 0x20)
```

`A00.0.00.041` occurs **38 times in 14 programs** = exactly the swept-delay family, and is
**ABSENT from PHASER**, the one modulation effect that sweeps all-pass coefficients rather than a
delay tap. `ACT 0x01` carries a "PLAIN GUESS ×5" tempA reading with no evidence behind it.
*Kill it:* find it in a program with no delay line, or a swept-delay effect that lacks it.

⚠ **Do NOT spend more mask arms on `SRC 0x00` first.** It is decoded where it is observable
(MEASURED bit-exact at the 29 twins, two vehicles, passing control; INFERRED strong at the twelve
`182` smoothers via the ROM's own upload script) and **unobservable everywhere else until this
link exists**. §§145–148 refined a reading that was already right against a consumer that is
missing — the fired-count and the bit-exact bus check both kept saying "the gate works".

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
  are `0..0` in quiet *and* loud, and **both units present 0 non-zero** with 314 063 loud frames.
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
  Default is now **`0x46A39B440F`**, `m_specmask` is u64. Bits 0–34 are used-in-code or
  set-in-default, **bits 35–37 are §121's `ACT 0x0D` selector** (extracted by shift, so a grep for
  the hex misses them) and **bit 38 is §130's rebase** — the lowest genuinely free bit is **39**.
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
