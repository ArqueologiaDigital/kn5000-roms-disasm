# HANDOFF — read this first

**YOUR NEXT TASK: "Select PARAMETRIC EQ on the panel and run the test."**

Written 2026-07-30 at the end of a long session (register §§97–126). If you are reading this
after a context compaction, this file plus `SPECULATIVE-APPLIED-REGISTER.md` §§118–126 is
everything you need. Read §126 first — it is why this task exists.

---

## 1. What the task actually is, in order

1. **Select PARAMETRIC EQ (algo 39) on the emulated KN5000 panel.** It is *not* loaded by
   default and never has been in any measurement of this investigation — see §126. The cold-boot
   default is CHORUS (unit 0) + ROOM REVERB (unit 1), and every number in §98–§125 describes
   those two because nobody ever changed the selection.
2. **Verify it actually loaded**, from the live C-RAM dump in `error.log`
   (`grep "C-RAM 00:"`). If cell `0x00` is `000072` (=114) you are still on CHORUS — that is the
   LFO increment, and it is the fastest tell. PEQ should show ten sections' worth of biquad
   coefficients instead.
3. **Note the panel setting you used**, because PEQ's coefficients are host-programmed at
   runtime — they are NOT in the ROM (algo 39's stream has 0 C-RAM records). The analytic
   transfer function is only computable if you know what the EQ was set to.
4. **Then run the decode test** (§4 below).

## 2. Why PARAMETRIC EQ (do not lose this reasoning)

* **It is 8 words from being the first fully executable effect on this chip** — 97 of its 105
  words are decoded. Nothing else is close; see §122's table (`dsp/tools/coverage_report.py`
  regenerates it).
* **Its 8 blockers are exactly 4 unknowns, each appearing twice**, at the entry of each of its
  two banks: `ACT 0x0D`, `ACT 0x0E`, `f31=4`, `f31=5`. Those same four are also the top of the
  corpus-wide blocker ranking, so the target is not parochial.
* **It contains the reconstructed biquad verbatim.** `kn7000_mame/notes/dsp-alu-biquad.md`'s
  section words appear character-for-character at idx 5..8, repeating at stride 9, **ten times**.
* **Structure (§125):** two PARALLEL five-section banks, both reading the unit-0 input cell
  `0x05`, private state at `0x50..0x63` and `0x64..0x77` (20 cells each = 5 sections × 4), both
  writing shared scratch `0x0E`/`0x10`.

## 3. ⚠ THE CRITERION IS VALID BUT FRAGILE — do not skip this

A biquad's response comes from `b0,b1,b2,a1,a2` **inside the core, which is already decoded**. If
`ACT 0x0D`/`0x0E` only assembled a bank's input they would change **gain, not shape**, and the
transfer function would be blind to them.

**It survives only because the two banks are PARALLEL and their mixes differ:**

```
  bank 1 entry:  ACT 0D addr8 = +11   ACT 0E addr8 =  0
  bank 2 entry:  ACT 0D addr8 = +10   ACT 0E addr8 = -1
```

Parallel banks sum, so their relative weights change the **shape**. A wrong reading mis-weights
one bank against the other — visible as a shape error, not a level error. **If you change
anything that makes the banks series, or equalises the mixes, the criterion dies.**

★ Big advantage over everything tried this session: **this criterion does not need the chip to be
audible.** Every other criterion did, and the chip is still silent.

## 4. The test

1. Read the live C-RAM and take the ten sections' `b0,b1,b2,a1,a2`. The core consumes them
   through `class4 == 0xA` cursor advances at `ACT 13/12/15/14`, five per section, consecutive.
2. Compute the analytic response of **two parallel five-section banks** summed.
3. Drive the chip with a known input; compare the output spectrum against the prediction.
4. Enumerate readings for the four unknowns.
   ⚠ **All four sit in the same five-word bank entry** (idx 0,1,3 and 50/53,54,56,104). Resolve
   them together, or hold three fixed while one varies. **§121 failed precisely by varying one
   unknown while three others in the same block were still guesses.**
5. A ready-made enumeration harness exists: `ACT 0x0D` destination selector on **mask bits
   35..37** with a fired-count (values: 1 acc=L, 2 tempA, 3 tempB, 4 mem[ptr], 5 P, 6 acc+=L).
   `mem[ptr]` (sel 4) is already REFUTED — it produces a DC leak.

## 5. Current state you are inheriting

**Default mask `0x6A39B440F`** (`m_specmask` is now **u64**; new experiments take **bit 34+**,
and bits 0..33 are all either used in code or set in the default).

Shipped and measured: §110 iw11 store timing; §111 host payload ×2 (two pre-registered right
answers hit exactly); §112 class-A ACT-07 latches P; §116 selector 0x27 → per-unit OVC, bit 3
enables wrap; §117/§118 wrap = mod 2²³ unsigned, scoped to the 29-word wrap-word family; §121
bit 34 (memory-source ACT-07 words are MOVES).

**CONTESTED / removed:** §113 (`SRC 0x11 = mem[ptr]`, bit 18) is **out of the default** — it has
no discriminating evidence (§119) *and* it turns `iw11` into a self-copy that un-feeds the audio
cell `0x05` (§121). `lfo-ramp.md` §8.4 names two compliant readings and they are observationally
equivalent on the LFO; §27's `SRC 0x11 = ACCB` is unrefuted.

**Still silent, and the audio path's real blocker is NOT ACT 0x0D** — it is the `iw45`/`iw32`
(`SRC 0x08`) clobber that overwrites the audio at `0x05`/`0x07` before body 0 reads it (§110,
§121). I twice planned work downstream of it. Do not repeat that.

## 6. Build / run, and the traps

```
  cd ~/compartilhado/kn7000_mame && ./build.sh
      *** EXITS 0 EVEN ON COMPILE FAILURE *** -- grep for "error:" AND check
      ls -la ~/compartilhado/kn7000_mame_build/kn7000   (fresh, >70 MB)
  ./tools/publish-binary.sh
  cd ~/compartilhado/kn7000-emulator && export DISPLAY=:0 && rm -f error.log
  UPD6383_SPEC=<hex> timeout 150 ./run.sh kn5000 -window -seconds_to_run 16 -log \
    -autoboot_script <scratchpad>/fast_notes.lua
```

* **NEVER `-video none`.** Always `timeout`-wrap. Always play notes.
* **COMPUTE masks in python, never type them, AND verify your bit is CLEAR IN THE DEFAULT** —
  not merely unused in code. Three passes died on mask mistakes, one because the chosen bit was
  already set so the gate was live in both arms.
* **Every new gate must log a FIRED-COUNT.** It caught two silent no-ops this session in one run
  each; without it they read as clean negative results.

## 7. The seven traps that actually cost time (all hit this session)

1. **Check the owning note FIRST.** Six times the answer was already written down — most
   sharply §123, where I re-derived a hypothesis `action00-discriminator.md` names as attractive
   and had already falsified.
2. **A value that stops being constant is not the quantity you think is moving.** §119 and my own
   §114/§116/§117: the "phase ramp" was a *different* wrong behaviour producing motion.
3. **Compute the NULL first.** §101 and §121 were void because the operand was empty or constant
   — testing consumers of nothing.
4. **Run the control whose answer you know.** §107's test scored 0% on an anchored code and was
   thereby disqualified; §121's null arm exposed a contaminated criterion.
5. **Free-running quantities fake "input dependence."** `kwatch`'s quiet/loud split measures
   INPUT dependence; an LFO is input-independent, so a working modulation cell reads as "not
   input-dependent" while a ramping one fakes DIFFERS via unequal bucket sizes. Use §104
   residency ranges downstream of the LFO.
6. **A guard being inert is a fact about the configuration, not the guard** (§99/§100).
7. **Don't ship a reading on one non-discriminating A/B** (§118 → §121). Grade it CONTESTED.

## 8. Instruments that already exist — extend, don't reinvent

`§81` accumulator probes (**POST-execution** — probe iwN is the value AFTER slot N) · `§86/§96`
`kwatch` per-cell quiet/loud census + writer identity · `§98` `pwatch` per-region pointer window,
mode-1 counted separately · `§104` per-slot quiet/loud of acc / mem-under-pointer / operand bus L
· `§109` per-slot store witness (dpPre, dpPost, store address, path, guard verdicts) · `§119`
per-frame tracking witness · `m_trace` time-ordered frame trace · `dsp/tools/coverage_report.py`
regenerates the coverage and blocker tables.

## 9. If PEQ cannot be selected

Effect selection would let **every** future pass choose its vehicle by decode coverage rather
than inherit CHORUS — ten of the 91 programs are more decoded than CHORUS and **none has ever
been executed**. If the panel route is blocked, forcing algo 39's upload directly is acceptable
*provided you say so in the result line*, since it bypasses the firmware's own parameter
translation and the C-RAM contents may then not correspond to any real panel setting.
