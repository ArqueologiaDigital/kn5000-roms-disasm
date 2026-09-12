# The audio gate: located at ONE word, opened behind a diagnostic (2026-09-12)

The project's #1 open item is the "4.2 audio gate" — external audio reaches the DSP but never the
effect body, so every program computes on stale state. This note localizes the break to a **single
instruction word** with a two-sided instrument, opens it behind a default-off arm, and reports what
the next blocker is. Companion to `N-SINGLE-DELAY-RECURRENCE-2026-09-12.md` (the scale thread,
which this turns out to meet).

## 1. The instrument: a frame-pair diff (`dsp/tools/frame_pair_diff.py`)
Capture frame F and frame F+1 with an otherwise identical command line and diff every D-RAM cell
and every `(iw, acc, P, L)` row. **A body fed live audio cannot produce two identical frames.**
This replaces judgement calls ("the operands look starved") with a two-sided test, and its exit
status is non-zero on a static body so it can gate a harness.

Capture (PARAMETRIC EQ, real note, unseeded):
```
DISPLAY=:0 DHLE=0 DSPCFG=3 TYPEIDX=15 NOTEMODE=0 TGM=0 UPD6383_PSHIFT=2 \
  UPD6383_TRACE_FRAME=1764000 ./kn7000 kn5000 -rompath ./roms -skip_gameinfo -log -window \
  -autoboot_script dsp/tools/fx_ab.lua ; cp error.log F.log        # then 1764001 -> F1.log
python3 dsp/tools/frame_pair_diff.py F.log F1.log --lo 0 --hi 400
```

## 2. What it measured (BASELINE, shipped device)
* **The audio arrives.** Cells `0x01` and `0x04` — the documented deposit cells — MOVE between
  consecutive frames (`60672 → 51456`, `122880 → 136448`).
* **The kernel is live.** 30 rows differ, all of them in `iw 3..38`, and cell `0x06` moves.
* **Everything from `iw39` on is bit-identical**, including the entire body: over `iw 84..400`,
  44 cells seen, **0 moved**, 0 of 105 rows differ.
* The body's pickup cell `0x05` is **static** at −456930 — and −456930 is exactly the operand the
  EQ's band-0 words were multiplying. The body reads its input; the input never changes.

⇒ The break is **between iw38 and iw39**, in the shared kernel that every effect runs.

## 3. The word, and why it does nothing (READ FROM THE DEVICE, then MEASURED)
`iw38 = 809.0.00.839`. Its `lo12` is `0x839`, and `upd6383.cpp:2754` reads **lo12 bit 11 as
"addressing only, no ALU effect"**: the branch advances the cursor and the pointer and `return`s
before any action runs. So `iw38`'s **`ACT 0x19` (tempA capture) never fires**. The trace shows the
consequence directly: the `tA` column reads `F65100` on every row of every frame, and `iw39`
(`SRC 0x19` = tempA) consumes that frozen `−634624` — which `iw44` then stores into `0x05`, the
body's pickup. One stale register, and the whole signal path downstream of it is a constant.

The corpus population of that branch is tiny: **95 of 3057 words carry lo12 bit 11, and only TWO
carry a capture action** — one of which is this shared-kernel word. So the reading's blast radius
is two words, and one of them sits on every effect's audio path.

## 4. The arm, with its criterion registered before the run
`UPD6383_LO12CAP` (default OFF): a bit-11 word whose ACT is `0x19` still performs its tempA
capture. **What it captures is the open half of the code** — `upd6383d.h` grades ACT 0x19 as
"tempA ← ??? : ships on the OWNER'S DECISION". The accumulator is the only input-dependent
quantity at `iw38` (its `acc` differs between frames; its `mem` and stale `L` do not), and the
HLE's input stage wants precisely "scale the kernel's accumulated audio and deposit it", which is
what `iw39` (multiply) and `iw44` (store to `0x05`) then do. So the arm captures `acc`.

**Pre-registered, two-sided:** with the arm the body must STOP being frame-identical; if it stays
identical the reading is wrong.

**RESULT — the criterion passed.** With `UPD6383_LO12CAP=1` (FIRED 1 759 822 times, i.e. once per
frame per unit, as a single kernel word should):

| | cells moved (body `iw 84..400`) | rows differing |
|---|---|---|
| shipped | **0 of 44** | 0 of 105 |
| arm on | **3** (`0x05`, `0x50`, `0x51`) | **15 of 105** |

and over the whole frame 6 cells move instead of 3. **For the first time the body is running on
live audio.** The three moving cells are the pickup and band 0's x-history, and they behave as a
shift register should: `0x51 → 0x50 → 0x05` carry `4894193 → 4899512 → 4904730` across the pair —
each frame the sample moves one position along, with the slow increment of a held note.

## 5. The next blocker, already visible in the same trace
Band 0's **y-history rails**: `0x52 = 0x7FFFFF`, `0x53 = 0x3FFFFF`, and the accumulator crosses
the ±2³⁹ clamp inside the band's MAC chain (`iw93` computes 868 693 062 138 against a clamp of
549 755 813 888). With the y feedback at the rail the band's output is a constant, so nothing
propagates past band 0 — which is why bands 1–4 are still frame-identical.

That is the **scale** question, and it is the one `N-SINGLE-DELAY-RECURRENCE §10` already answered
arithmetically from the ROM cells: the EQ's coefficients only realise a flat band when `b0`, `b2`
are scaled ×4 and `b1` ×2 relative to the a-path, and no single shift (and neither candidate
selector) produces that. The two threads have met: **the gate is open, and the first thing the
live signal hits is the unresolved scale.**

## 6. The scale fix was tried on the live body — and the prediction FAILED (MEASURED)
`UPD6383_EQSCALE` (default off, and marked in the source as never-to-ship) applies §10's solved
scales — `b0`, `b2` ×4 and `b1` ×2 — **by the coefficient's position in the band** (`cursor % 6`,
using the EQ's known cell order). That is deliberately fitted: the chip cannot know a
coefficient's role, so the probe is not a decode. Its only job was to answer what arithmetic
cannot — *fed those numbers, does the device produce a working filter?* Pre-registered: the
y-history stops railing, the per-band gain falls from 2.0 to ~1, movement reaches all five bands.

**All three failed.** With the probe on (FIRED 21 220 974) the capture is indistinguishable from
the probe off: band 0's `−a1` operand is still `8388607`, the same three cells move (`0x05`,
`0x50`, `0x51`), the same 15 of 105 rows differ, and bands 1–4 stay at the rail.

**What that refutes is an assumption of mine, and it is worth more than the numbers.** §10's
flatness solve is arithmetic about a **Direct-Form-I biquad**: it says those five ROM cells, used
as `y = b0·x + b1·x1 + b2·x2 − a1·y1 − a2·y2`, are flat only under that scaling. But the device's
own measured behaviour contradicts the same model *before* any scaling: with the coefficients as
stored, DF-I predicts a band gain near **¼**, and the trace measures **2.0** — a factor of eight.
A model that is off by 8 cannot have its inputs corrected by 4. ⇒ **the device is not evaluating
the EQ as the DF-I I assumed**, and §10's numbers cannot be applied to it word-by-word until the
program's actual topology is read out of the bytecode rather than assumed from the cell names.
(That is a bytecode question — exactly the kind the project's own rule says outranks the HLE.)

**And the railing itself needs no scale mystery.** `acc_to_datum()` clamps the *datum*, not the
accumulator: the 44-bit accumulator has headroom, but a band's output is converted to 24 bits and
clipped at ±2²³. With a per-band gain of 2 and five bands in cascade, any real input is amplified
~32× and clips — which is precisely the observed pattern (bands 2–4 with 3 of 5 operands at the
rail). Fix the gain and the railing goes with it; the gain is the open item, not the clamp.

## 7. A SECOND gate, at the body → output-stage boundary (MEASURED)
The same instrument, pointed at the epilogue. With the input gate open **and** the class-8 post-sum
scale on (so the body is fully live — all five EQ bands propagating, 59 of 105 body rows differing
between frames), the **output stage is still completely static**:

```
python3 dsp/tools/frame_pair_diff.py eq_c8_F.log eq_c8_F1.log --lo 60 --hi 83
   cells seen: 2   MOVED: 0        per-row tuples differing: 0 of 22
```

So the chain is now: audio → kernel → **body (live)** → ✗ → epilogue → output. The break is visible
row by row in the trace:

* the body ends with a live accumulator — `iw186` (the makeup multiply/store) leaves
  `acc = 95 987 382`, `iw187` loads `acc = −95 944 704`, `iw188` is the END-OF-BLOCK word;
* the epilogue opens at `iw60` with `acc = 1 301 505 024` — a constant, not the body's value — and
  at `iw65` a `f31 = 0` LOAD takes `P = 0`, so **`acc = 0` from `iw65` onward**;
* `iw73` (`E30.C.00.404`, `SRC 0x10` = the accumulator) is the unit-0 presentation, and it
  presents that zero. `iw72` fetches `L = 0x400000` = the documented unit-0 OUTPUT LEVEL (+0.5),
  so the level is right there and is multiplied into nothing.

The epilogue's reads are **mode-1 register-file addresses** (`0x8D`, `0x8C`, `0x8F`, `0x06`,
`0x85`, `0x90`) while its pointer sits at `dp = 0x00` — i.e. the handover is meant to go through
the REGISTER FILE, not through D-RAM. That is the same array the chorus's delay datum was found
landing in unread (`N-DLYSEED2-CHORUS-CONFRONT §7`): mode-1 stores go to `m_rf[]` under mask bit
23, and nothing on the operand side reads it back. ⇒ **the body→epilogue handoff is the next
single-point break, and it is a register-file question, not an arithmetic one.**

⚠ Grade: MEASURED (two captures, the pair differing in the body and identical in the epilogue, on
the same rig that shows both gates). The *mechanism* is a READ of the words plus the standing
`m_rf` finding — it names where to look, it is not a decode. §221's E1 "epilogue/handover operand
provenance" census is the instrument already built for exactly this.

## 8. Where the live signal actually stops: the L→R CHANNEL BOUNDARY (MEASURED)
§7 said "the body is live but the output stage is static" and pointed at the body→epilogue
handoff. Diffing the frame pair **in execution order** rather than by `iw` locates it exactly, and
it is earlier than that:

```
rows compared 187, differing 99
   n    3..3     iw 3..3
   n    7..31    iw 7..31
   n   35..44    iw 35..44
   n   46..108   iw 46..142     <- last live row
   (nothing from n=109 / iw143 onward)
```
(The frame's real execution order is `iw 0..49` → `iw 84..188` (the body) → `iw 50..81`, so a diff
ordered by `iw` mixes the kernel's two halves; ordering by `n` does not.)

`iw142/143` is the **L→R channel boundary of the EQ body**: `w57 = ld.st acc,(p)+84` steps the
pointer from the L state block to the R one (`dp 0x10 → 0x64`) and `w58 = rstcur` restarts the
coefficient cursor (`cur 0x1E → 0x00`, visible in the trace). So the **L channel is live and the R
channel never receives input** — its first operand cell `0x64` sits static at 18535 — and the
epilogue presents the R result, which is why §7 saw a dead output stage.

**The kernel's own structure says where the R deposit is.** It carries TWO matching `lo12`-bit-11
triplets, identical word forms differing only in `addr8`:

| | L | R |
|---|---|---|
| `ACT 0x01` | `w42 0801070821` addr8 `0x70` | `w50 0801050821` addr8 `0x50` |
| `ACT 0x07` | `w43 080106C827` addr8 `0x6C` | `w51 0801064827` addr8 **`0x64`** |
| `ACT 0x05` | `w44 0801025825` addr8 `0x25` | `w52 0801025825` addr8 `0x25` |

⚠ **CORRECTED by the execution order: the two triplets are not L and R, they are IN and OUT.**
The first (`w42..w44`) runs in `iw0..49`, *before* the body. The second (`w50..w52`) runs at
`n=155+`, *after* it — and the trace shows it holding `acc = −95 944 704`, **the body's own final
accumulator**. So the second triplet is the **body→epilogue handoff** §7 was looking for, and it is
suppressed by this same bit-11 branch. The symmetry of the two triplets is a symmetry of the
input and output stages, not of two channels.

**And the R channel's input is a distinct, still-dead cell.** Diffing the kernel-region cells
across the frame pair: `0x01`, `0x04`, `0x05`, `0x06`, `0x10` **move**; `0x0E` (19 859) and `0x0F`
(18 535) are **static** — and 18 535 is exactly what the R channel's first operand reads (cells
`0x64`/`0x65` carry the same value). So `0x0F` is the R pickup, the mirror of the L pickup `0x05`,
and it is still frozen: `LO12CAP=1` released one capture and brought **one** channel to life.

**Arm extended to the ACT-0x07 store — and it FIRED ZERO TIMES.** `UPD6383_LO12CAP=2` performs the
`ACT 0x07` store on bit-11 words; the count is 0 and the frame pair is unchanged (59 of 105 rows,
identical to `=1`). The reason is in the device and is itself informative: those two words have
`lo12 == 0x827`, which the **§116 branch catches first** (`m_ovc = addr8; return;` — "a register
aimed") under a mask bit that is set by default. ⇒ `w51` does not store; it **aims a register at `0x64`**. The live
candidates in that triplet are therefore `w50` (`ACT 0x01`) and `w52` (`ACT 0x05`), both of which
DO fall into the bit-11 "addressing only" branch and are suppressed there — the same suppression
that held the first gate shut. Since that triplet is the OUTPUT handoff (above), releasing it is
what should carry the body's result to the epilogue; the R channel's input needs the *other*
missing capture, the mirror of the one `LO12CAP=1` released.

⚠ Grade: the stop point, the triplet table, the execution-order correction and the static/moving
cell census are MEASURED. The zero-fire is a MEASURED negative whose cause was then READ from the
device (§116). ⇒ there are **two** remaining suppressed handoffs, both in the shared kernel and both
behind the same bit-11 branch: the **R-channel input** (mirror of the released capture; its cell is
`0x0F`) and the **body→epilogue output** (`w50`/`w52`). §7's framing is corrected: the output break
is real, but it is one of two, not the only one. The arm stays default-off with its zero count.

## 9. ⚠ CORRECTION: the triplets are POINTER SETUP, and only ONE kernel word was ever suppressed
Two further arms were built and both **fired zero times**: `LO12CAP=2` (bit-11 `ACT 0x07` stores)
and `LO12CAP=3` (bit-11 `ACT 0x05` stores under the pointer). Chasing *why* corrects §8's central
claim, and the correction is worth more than either arm.

**Read the disassembly of the seven words instead of inferring from their fields:**
```
  w38   0809000839   ?word                 <- UNDECODED  (the one LO12CAP=1 released)
  w42   0801070821   ldptr   #$70          <- DECODED
  w43   080106C827   ?word   (register write, selector lo12[7:0] = 0x27)
  w44   0801025825   ldptr.d #$25          <- DECODED
  w50   0801050821   ldptr   #$50          <- DECODED
  w51   0801064827   ?word   (register write, selector 0x27)
  w52   0801025825   ldptr.d #$25          <- DECODED
```
So the "triplets" are **pointer-setup sequences** — `ldptr`, a register write, `ldptr.d` — not data
deposits. `w42`/`w44`/`w50`/`w52` are DECODED words, and the device's bit-11 branch lives inside
`if (m_speculative && !alu_decoded(word))`: **a decoded word never reaches it.** That is why both
arms fired zero: those words were never suppressed in the first place.

⇒ **§8's "two suppressed handoffs remain, both behind the same bit-11 branch" is WRONG and is
withdrawn.** Of the kernel's seven bit-11 words exactly **one** — `w38` — was ever suppressed, and
`LO12CAP=1` released it. The second pickup (`0x0F`) and the body→epilogue handoff are still dead,
but **not for this reason**, and the bit-11 branch has nothing further to give.

**What is genuinely still open there** is the pair `w43`/`w51` (`?word`, "register write, selector
0x27"), which §116 consumes as `m_ovc = addr8; return;`. Their values are `0x6C` and `0x64` — and
`0x64` is exactly the second channel's state-block base. In the device `m_ovc` is consulted only
for one wrap bit, so whatever those words really write is unread. That, not the bit-11 branch, is
the next target.

⚠ Grade: the listing quotations and the `alu_decoded` gate are READ from the sources; the two
zero-fire counts are MEASURED. The correction is to my own §8. No decode changed; both arms stay
default-off with their zero counts recorded.

## 10. ⚠⚠ SECOND CORRECTION, from the project's OWN prior analysis: the triplets are PER UNIT
§8 called the two kernel triplets "IN and OUT" (correcting §8's first reading of "L and R"), on the
strength of the execution order and of `w51`'s payload `0x64` matching the EQ's second state-block
base. **Both readings are wrong, and the register already said so.** `SPECULATIVE-APPLIED-REGISTER`
§116 analysed these exact two words years of sessions ago:

> *"`0x27` is the only member whose target is unidentified, and it occurs exactly twice: once per
> unit. That is where a per-unit mode register is configured… unit 0 `0x6C = 01101100`, unit 1
> `0x64 = 01100100`, XOR `0x08` → bit 3, and nothing else."*

So the two triplets are **unit 0's and unit 1's setup**, written immediately before each unit's
body: `ldptr`, the per-unit mode register, `ldptr.d`. Bit 3 selects wrap (unit 0, the LFO-bearing
effects whose phase accumulator must wrap) versus saturate (unit 1, the reverbs) — which is exactly
what the device consults it for (`m_ovc & 0x08`). The frame is
`kernel-A → unit-0 body → unit-1 setup → unit-1 body → epilogue`, and that is why the second
triplet is seen holding unit 0's final accumulator: it runs right after that body, but its job is
unit-1 setup, not carrying the result. **`w51`'s `0x64` matching the EQ's second state-block base
is a coincidence of two unrelated 8-bit values**, and I built a reading on it.

**Corpus check that agrees:** `lo12 == 0x827` occurs at exactly **2 of 3057** words, both in the
kernel — a per-unit configuration site, not a data path. Nothing else in the corpus uses that form.

⇒ The body→epilogue handoff and the second pickup `0x0F` remain open, and the kernel's bit-11
triplets have **nothing to do with either**. Everything §8 and §9 said about them beyond the
measured cell census is withdrawn.

★ **The rule this broke is one of the project's own:** *check the handover first*. §116's analysis
of these two words was committed and indexed; reading it would have replaced two builds, two
zero-fire arms and two wrong structural readings with one grep. The measured parts of §8 (the last
live row at `n=108/iw142`, the moving/static cell census, `0x0F` as the second pickup) are
unaffected — they came from the trace, not from the triplets.

## 11. What actually starves the second channel: the OPEN 0x0D/0x0E MIXING PAIR (MEASURED)
Having removed a bad candidate (§10), the disciplined move is a writer census before any new arm.
The EQ body itself addresses the second pickup. Every body word whose pointer is `0x0E`/`0x0F`:

| n | iw | word | class | SRC | ACT | dp | mem | row differs between frames? |
|---|---|---|---|---|---|---|---|---|
| 99 | 133 | `00002AD647` | 2 | 0x19 | 0x07 | 0x0E | 004D93 | **yes** |
| 100 | 134 | `0028200000` | 2 | 0x00 | 0x00 | 0x0E | 004D93 | **yes** |
| 101 | 135 | `0880130407` | 1 | 0x10 | 0x07 | 0x0E | 004D93 | **yes** |
| 103 | 137 | `000020A1CD` | 2 | 0x07 | **0x0D** | 0x0F | 004867 | **yes** |
| 104 | 138 | `00002FF1CE` | 2 | 0x07 | **0x0E** | 0x0E | 004D93 | **yes** |

**Every one of those rows differs between consecutive frames — and the cells they address do not
move at all** (`0x0E` stays `0x4D93`, `0x0F` stays `0x4867` = 18 535, the value the second half
then reads). So the words run, they run on live data, and they leave their cells unchanged.

`iw137`/`iw138` are the **`ACT 0x0D` / `ACT 0x0E` pair** — the "delay/state MIXING" codes that the
register lists as long-open, and for which `0x0E` has **three contradictory committed readings**
(`mem[ptr] ← bus` / `acc → bus` / `P ← bus`). Under the reading the device currently ships, the
pair reads but never writes, which is exactly the observed signature.

⇒ **The dead second channel is gated by the 0x0D/0x0E mixing pair**, one of the four items the
handoff has carried as open since long before this session. That is a genuine join between the
newest measurement and the oldest open decode, and it also says what would settle it: of the three
readings for `0x0E`, only `mem[ptr] ← bus` writes a cell, and it is the one that would make
`0x0F` move. ⚠ Stated as the *discriminating prediction*, not as a decode — the right next step is
to run the three readings against this frame pair and see which makes the second channel live
without disturbing the first, not to assume the convenient one.

## 12. ★★ ACT 0x0E = `mem[ptr] ← bus` MAKES THE SECOND CHANNEL LIVE (MEASURED, no rebuild)
The discriminating test §11 called for needed **no new code**: the device already exposes the
`ACT 0x0E` reading as a selector in the speculative mask (bits 45–47), so `UPD6383_SPEC` selects it.
Reading the shipped value explains the symptom outright: **selector 7 = `P ← bus`, which writes no
memory** — which is why `iw138` runs on live data every frame and leaves its cell untouched.
Selector **4 = `mem[ptr] ← bus`** is the one committed reading that writes a cell.

`UPD6383_SPEC=B9108446A39B440F` (the default mask with `sel0e` 7 → 4), same rig, same frame pair:

| | shipped `sel0e=7` | **`sel0e=4`** |
|---|---|---|
| cells moving (whole frame) | 25 of 52 | **42 of 52** |
| rows differing | 99 of 187 | **149 of 187** |
| last live row | `n=108` (`iw142`, mid-body) | **`n=158`** (into the post-body kernel) |
| second state block `0x64..0x77` | **static** | **`0x64`–`0x74` ALL MOVING** |
| rows at the rail (body) | 2 of 105 | 2 of 105 |
| per-band gain | 0.667 ×4 | 0.667 ×4 |

⇒ **Both channels of the reference program run for the first time.** Of the three contradictory
committed readings of `ACT 0x0E`, only this one does that; the shipped `P ← bus` starves the second
channel by construction, because it never writes memory.

⚠ **My specific prediction still failed, and that matters.** §11 predicted *cell `0x0F` moves*.
It does not — `0x0E` (19 859) and `0x0F` (18 535) are as static as before, while the whole second
state block came alive. So the sub-claim "`0x0F` is the second pickup" is **refuted**: it is static
*and* irrelevant to whether the channel runs. What §11 got right was the gate (the `0x0D`/`0x0E`
pair); what it got wrong was the cell.

⚠ **What this is NOT.** Liveness is evidence, not proof: switching the reading also changes the
first channel's values (`0x50`: 4 899 512 → 1 574 402), as any different ACT reading must, so
"intact first channel" was never a fair criterion and I should not have written it as one. The
rail count (2 of 105) and the per-band gain (0.667) are unchanged, so nothing regressed. The
epilogue remains bit-identical — **a further gate stands between the body and the output**, and it
is not this code.

★ The honest summary: on the reference program, `mem[ptr] ← bus` is the only one of the three
readings under which both channels compute, and the shipped one cannot by inspection. That is the
strongest discrimination this code has had, and it is reproducible with one environment variable.

## 13. The THIRD gate, localized: `iw53`/`iw54` on the output path (MEASURED)
With `ACT 0x0E` set to `mem[ptr] ← bus` the live rows reach `n=158`. Where they stop is one word,
and the trace shows the mechanism in two columns:

```
n=157  iw52  0801025825  acc 1065091072 / 1066467328   P 1065091072 / 1066467328   (both DIFFER)
n=158  iw53  00109D020C  acc 1065091072 / 1066467328   P 1301505024 / 1301505024   L 32768 / 32768
n=159  iw54  080016000B  acc 1301505024 / 1301505024   P 1301505024 / 1301505024   (both SAME)
```

* `iw53` (`00109D020C`, class 9, **`SRC 0x08`**, `ACT 0x0C`) carries a LIVE accumulator — it differs
  between frames — but its **operand `L` is the constant `32768`** and its **product is the constant
  `1 301 505 024`**.
* `iw54` (`080016000B`, class 1 escape, delay-DRAM WRITE direction, **`f31 = 0` = LOAD**) then does
  `acc ← P`, **overwriting the body's live result (1 065 091 072) with that constant**.

⚠⚠ **THE ATTRIBUTION TO `SRC 0x08` IS WRONG, AND WITHDRAWN — same-session, from the handover.**
`SRC 0x08` is **anchored and MEASURED**: it reads `C-RAM[cursor]`, established by the LFO rate, and
`HANDOFF-NEXT` says in terms *"⛔ `SRC 0x08` MUST NOT BE TOUCHED"*. The trace agrees exactly — at
`iw53` the cursor is `0x50` and `C-RAM[0x50] = 0x008000 = 32 768`, which is the `L` in the table.
**A coefficient is constant by nature**, so "its operand never changes" is not evidence of a gap;
it is the anchored decode working. I reasoned from a symptom without checking the code's status
first — the second time this session, and the same rule both times (*check the handover first*).

What survives the withdrawal is the **measurement**: the body's result does not reach the output.
`iw184` (`ACT 0x07`, `dp = 0x76`) stores `L = 0`, `iw186` (bit-4 store, `dp = 0x75`) carries a live
accumulator — and cells **`0x75`, `0x76`, `0x77` all read 0 and stay static across the frame pair**
while `0x74` moves. So the break is at the body's **output store**, one stage after the channel
work, and its cause is **not** `SRC 0x08` and not yet identified.

### The shape of the whole problem, now visible
The "audio gate" was never one thing. It is a **chain of open codes**, one per stage, and each
starves everything downstream so only the first is ever visible:

| stage | gate | status |
|---|---|---|
| kernel → body | `iw38` `ACT 0x19` capture, suppressed by the bit-11 branch | **opened** (`UPD6383_LO12CAP=1`) |
| body, 1st → 2nd channel | `iw137`/`iw138` `ACT 0x0D`/`0x0E` mixing pair | **opened** (`sel0e = mem[ptr] ← bus`) |
| body → output stage | the body's output cells `0x75`–`0x77` stay 0 while the words storing to them run live | **open, cause unidentified** |

Every one of the three is on the handoff's own checklist of ~6 unanchored codes. That is why
progress looked blocked for so long: with the first gate shut, the second and third could not even
be *seen*, and each looks like "the body is starved" from downstream. The frame-pair diff is what
makes them separable — it locates the exact row where liveness stops, one stage at a time.

⚠ Grade: the columns and the cell census are MEASURED; the `SRC 0x08` attribution built on them is
WITHDRAWN (above). The chain table's first two rows stand on two-sided arm results; the third row
now records a measured symptom with **no candidate cause**. The next step is a writer census of
cells `0x75`–`0x77` — which word is supposed to write them, and does its store fire — and to check
each code's status in the handover *before* building anything on it.

## 14. ⚠ POSITIONING AGAINST §215/§216 — the downstream null was ALREADY MEASURED
Checking the handover for the third gate (as §13's correction says to) turns up that the project
has been here before, by a different route:

> **§216: "The output stage is a NULL independent of the send."** With the send **forced open**,
> body 0 ran its whole ladder on live audio (28 input-dependent slots) and fed body 1 — and
> `w73`/`w78` were still `min 0 max 0`, quiet and loud. §217 re-measured it in three more arms
> including a no-stimulus window: still `min 0 max 0`, all six readings.
> *"Every link is MEASURED. Do not re-derive any of them."*

So **"the body runs live and the output stage still produces nothing" is not a new finding** — it
is §216's, and my §7/§13 rediscovered its downstream half. That needs saying plainly.

**What IS new in this session, stated against that baseline:**
* §216 forced the send open with a rig (`m_noz05`, suppressing the words that zero cell `0x05`).
  This session found the **MECHANISM** instead: one word (`iw38`), one suppressed action
  (`ACT 0x19`), one branch (`lo12` bit 11, `upd6383.cpp:2754`) — a word-level cause rather than an
  artificial forcing, with a two-sided frame-pair criterion.
* `ACT 0x0E` had three contradictory readings and no discriminator. It has one now: only
  `mem[ptr] ← bus` makes the reference program's second channel compute (§12).
* Class 8 was `OPERATION UNKNOWN` in the reference listing; it is a post-sum accumulator scale (§5
  of `N-EQ-TOPOLOGY-FROM-BYTECODE`).
* `frame_pair_diff.py` is a reusable two-sided instrument for "is this stage running", which is
  what let each stage be separated from the one downstream.

**And the consequence for planning, which is the useful part:** opening further INPUT-side gates
cannot produce audio, because the output stage is null *independently* of what reaches it. The two
halves are separate problems, and §216 already closed the question of whether feeding the body more
signal helps. Anyone continuing should treat the output stage as its own investigation — starting
from §216/§217's measurements, not from a fresh frame-pair hunt that will rediscover them.

## 15. REGRESSION CHECK: the opened readings do not disturb the MEASURED primitives
A reading that makes a stage live is worthless if it breaks what was already bit-exact. The same
EQ frame, three configurations, through `dlyseed_confront.py`:

| configuration | multiplier `P[N] = coef[N−1]·L[N] >> 7` | accumulator classification |
|---|---|---|
| shipped readings | **57 exact, 0 mismatch** | 61 accumulate, 27 load, 4 bus-add, 2 saturated, 10 boundary, **0 unexplained** |
| `+LO12CAP +C8SHIFT` | **57 exact, 0 mismatch** | 60, 27, 4, **0 saturated**, 13 boundary, **0 unexplained** |
| `+LO12CAP +C8SHIFT +ACT0E=mem[ptr]` | **57 exact, 0 mismatch** | 60, 27, 4, **0 saturated**, 13 boundary, **0 unexplained** |

The multiplier is bit-exact on all 57 non-zero products in every configuration, and the accumulator
has **no unexplained multiply rows** in any of them. The only movement is that the two saturated
rows disappear once the class-8 post-sum scale is applied — which is the intended effect, not a
regression — and three rows move from "saturated" into the boundary bucket.

⇒ the three readings opened or decoded this session (`ACT 0x19` capture on the bit-11 word, class-8
post-sum scale, `ACT 0x0E = mem[ptr] ← bus`) are **compatible with the project's bit-exact
datapath measurement**. That is a necessary condition, not a sufficient one, but a reading that
failed it would have been dead on arrival.

## 16. ⚠⚠ THE GATE ARM HAS A MEASURED COST: it breaks the chorus's LFO phase
The session's headline needs this qualification attached to it, not filed beneath it. Bisecting the
arms against the one modulation quantity that matched the HLE exactly — the chorus's phase cell
advancing by **114 per frame**, the `N-DLYSEED2-CHORUS-CONFRONT §1` triangle:

| configuration | phase-cell delta |
|---|---|
| baseline (shipped readings) | **114** ✓ |
| `ACT 0x0E = mem[ptr] ← bus` alone | **114** ✓ |
| **`UPD6383_LO12CAP=1`** (capture the accumulator) | **1 360 432** ✗ |
| **`UPD6383_LO12CAP=4`** (capture the BUS instead) | **4 348 764** ✗ |

Two things follow, and the second is the one that matters:
1. **The mixing-code change is innocent.** `ACT 0x0E = mem[ptr] ← bus` — the reading that makes the
   EQ's second channel compute — leaves the phase at 114. My prior said it would be the culprit;
   the bisect says otherwise, which is why the bisect was run.
2. **Both captured SOURCES break the phase.** Accumulator and bus alike. So this is not "the wrong
   value is being captured", which was the obvious next hypothesis and is now refuted — **it is the
   capture happening at all** that disturbs the chorus's phase path.

⇒ `UPD6383_LO12CAP` is a **two-sided experiment with a measured cost**, not a fix: it opens the
body and breaks a quantity three independent sources agree on (bytecode constant, HLE increment,
panel rate). A reading that trades a confirmed-correct behaviour for liveness is not yet the chip's,
however useful it is as an instrument — and it *is* useful, because everything §12–§15 measured was
only visible with the body running.

What that implies for the next attempt: the chorus's phase path evidently depends on `tempA`
retaining its value across `iw38`, so the chip's `ACT 0x19` there cannot be a plain capture. Either
the action is conditional (on something not yet decoded), or it targets a register other than
`tempA`, or the phase path's dependence on the stale `tempA` is itself an artefact of another
speculative reading upstream. Those are three testable shapes, and the frame-pair diff plus the
phase-delta check together make a two-sided test for each.

## 17. ★ THE REGRESSION IS A MODELLING ARTEFACT OF THE LFO PHASE WORDS — exposed, not caused
§16 left three shapes for why the capture breaks the phase. The traces already in hand decide it,
and the answer converts the regression from "my arm is wrong" into something more useful.

Compare the LFO block with the gate off and on (chorus, `iw88..92`):

```
gate OFF  iw88 acc            0   | iw89 acc      7 471 104  | iw91 (wrap) acc    183 540 121 600 ; phase cell 2ABB66 -> 2ABBD8  (+114)
gate ON   iw88 acc  319 452 807 168 | iw89 acc 638 913 085 440 | iw91 (wrap) acc    228 176 166 912 ; phase cell 205E2C -> 35205C  (+1.36 M)
```

The phase words are `092.A.00.200` (phase +=) and `094.A.00.200` (the wrap), and both carry the
**store bit**: the device writes `acc >> 16` into the phase cell. With the body starved the
accumulator arriving at `iw88` is **0**, so the cell receives only the increment and advances by
exactly 114 — the behaviour that matched the HLE. With the body live the accumulator arriving is
**3.19 × 10¹¹**, i.e. audio, and the same store writes **audio + phase** into the phase cell.

⇒ **The phase does not break because the capture is wrong; it breaks because the LFO phase words'
store is modelled as "store the whole accumulator", and that model is only harmless while the
accumulator is dead.** The 114-per-frame agreement with the HLE was measured under exactly the
condition that hides the defect. A phase accumulator has to be a narrow path — the increment and
the wrap, not the effect's running sum — and the chip evidently keeps it separate.

That is a **new open decode with a sharp statement and a two-sided test already built**: any
correct model of `092.A`/`094.A` must advance the cell by the increment (114 for the chorus at
rest, and by the panel-driven rate when LFO SPEED moves) **while the body is live**. Today the
device passes that test only with the body dead, which is no test at all.

★ This is the session's method paying off in an unexpected direction: opening a gate did not just
reveal what was downstream of it, it **invalidated a measurement that everyone (including the HLE
triangle) had trusted** — because that measurement had only ever been taken in the starved state.

### One level further: the entry point is `iw88`'s LOAD, and what should isolate the block
Reading the LFO block's arithmetic word by word shows the chip's intent is exactly the HLE's, and
where the device parts company from it:

```
iw88  000.2.F4.407  f31 = 0  -> LOAD  acc <- P
iw89  092.A.00.200  f31 = 1  -> acc += P + (L << 16),  L = 114 = C-RAM[0x00] = the increment
iw90  082.2.00.1C0  f31 = 1  -> acc += mem[0x07] << 16,  the phase
iw91  094.A.00.200  f31 = 2  -> the wrap word; its STORE writes acc >> 16 back to the phase cell
```
Starved, `P` at `iw88` is **0**, so the chain computes exactly `increment + phase` and the store is
correct — `2 800 486 → 2 800 600`, `+114`. Live, `P` at `iw88` is **3.19 × 10¹¹** (the body's
product), the LOAD takes it, and everything after inherits it.

So the defect is not in the phase words' own arithmetic — which is the HLE's formula, word for word
— but in **what the accumulator carries into `iw88`**. `f31 = 0` is a LOAD from `P`, and `P` is the
one-slot pipeline's *previous* product. Either the chip isolates the LFO block (a preceding word
that clears `P`, or a `P` that is not shared across that boundary), or `iw88`'s source is not the
product at all. Both are decode questions about words the corpus already contains, and the
two-sided test is the one stated above: **the cell must advance by the increment with the body
live**. ⚠ Note what this does NOT say: it does not say the gate arm is correct — §16's cost stands
— only that the phase failure is downstream of a modelling choice that the starved state concealed.

## 18. The pipeline-flush hypothesis was tested — REFUTED (MEASURED)
§17 named the mechanism (the body inherits a live `P` into `iw88`'s LOAD) and the obvious hardware
reading that would prevent it: a product register that **flushes at a block CALL**.
`UPD6383_CALLFLUSH` clears `P` at the call, nothing else.

```
FIRED 3 181 374  (twice per frame -- the two unit calls, as expected)
chorus phase-cell delta: 1 360 432   -- IDENTICAL to LO12CAP=1 alone
```

**Refuted.** Clearing the product at the CALL changes nothing, so the contamination is **not
inherited across the block boundary** — it is produced *inside* the body, in the four words before
the LFO block (`iw84` the delay READ, `iw85`/`iw86` the `0x0D`/`0x0E` mixing pair, `iw87` a store).
None of those is class A, so none of them should form a product at all — yet `P` is live by `iw88`.

That is a sharper target than §17 left, and it points at the **ACT codes that write `P` directly**:
the device's `ACT 0x0E` default reading is `P ← bus` (selector 7), which is exactly such a writer,
and the chorus's `iw86` carries `ACT 0x0E`. ⚠ But that alone does not close it either — the
`sel0e = mem[ptr]` configuration (which does *not* write `P`) still shows a broken phase
(3 129 519), so at least one more `P` writer is in play among those four words.

⇒ the question is now narrow and mechanical: **which of `iw84..iw87` leaves a live product, under
which reading?** Every one of those words is in the corpus, the trace records `P` at each row, and
the two-sided test is unchanged. ⚠ Grade: MEASURED refutation with a fired count; the arm stays
default-off with its record.

## 19. ★★★ THE THREE READINGS ARE MUTUALLY CONSISTENT — body LIVE **and** phase EXACT
§16 concluded "the gate arm breaks the LFO phase" and §18 concluded "the pipeline-flush hypothesis
is refuted". **Both are wrong, and the experiment that shows it also closes the loop.**

Dumping `P` row by row at the body's entry under each arm separately shows two *different* paths
to the same contamination:

```
CALLFLUSH only:  iw84 P = 0                  <- the flush DOES work
                 iw86 P = 319 452 807 168     <- ACT 0x0E under the SHIPPED reading (P <- bus)
                                                 re-creates it: L << 16, exactly
                 iw88 LOAD acc <- P           -> phase destroyed
sel0e=4 only:    iw84 P = 102 544 344 703     <- inherited; nothing flushed it
                 iw86 P unchanged             <- this reading does NOT write P
                 iw88 LOAD acc <- P           -> phase destroyed
```

Each arm closes one path and leaves the other open — which is exactly why each looked like a
failure on its own. **Together** (`UPD6383_LO12CAP=1 UPD6383_CALLFLUSH=1 UPD6383_SPEC=…8446…`):

```
iw84  P = 0     iw86  P = 0     iw88  acc = 0, P = 0
iw89  acc = 7 471 104 = 114 << 16        <- identical to the STARVED baseline
iw91  phase cell 2ABB66 -> 2ABBD8        <- +114
```

and the frame pair, the other half of the two-sided test:

```
cells seen 17, MOVED 3:  0x05 4 874 463 -> 4 872 698   (the pickup: live audio)
                         0x07 2 800 486 -> 2 800 600   (+114, the phase)
                         0x10 2 800 600 -> 2 800 714   (+114, its published copy)
rows differing: 21 of 70        ✅ the body is LIVE
```

**Both criteria pass at once, for the first time:** the effect body runs on live audio **and** the
LFO phase advances by exactly 114 per frame — the bytecode's constant, the HLE's increment, the
panel's rate. The phase cell and its published copy each step by the increment while the input cell
carries changing audio.

⇒ **§16 corrected:** the gate arm does not break the phase; it breaks it *only in combination with*
the shipped `ACT 0x0E` reading and an un-flushed product.
⇒ **§18 corrected:** `CALLFLUSH` is not refuted; it is **necessary**. It was refuted only as a
*solo* fix, which is a different claim and the one I should have made.
⇒ Three readings that individually looked destructive or inert — the `ACT 0x19` capture, the block
CALL's product flush, and `ACT 0x0E = mem[ptr] ← bus` — are **mutually consistent**, and each was
needed for the other two to show their value.

⚠ What this is NOT: proof that any of the three is the chip's. It is a configuration in which two
independent criteria hold simultaneously where previously no configuration satisfied both, and in
which the numbers at the LFO block are bit-identical to the starved baseline that matched the HLE.
That is the strongest joint evidence any of these codes has, and it is still three speculative
readings standing together. All three remain default-off.

## 20. ⚠⚠ §19's CONFIGURATION IS NOT PROGRAM-NEUTRAL: `CALLFLUSH` starves the EQ
§19 called the three readings "mutually consistent". That was tested on **one program**. Running the
**parametric EQ** — the reference program — in the same configuration shows the cost:

| EQ body, frame pair | cells moved | rows differing | non-zero products |
|---|---|---|---|
| gate + `C8SHIFT` + `ACT 0x0E = mem[ptr]` | **42 of 52** | **149 of 187** | 57 |
| …**plus `CALLFLUSH`** | **2** (`0x05`, `0x10`) | **9 of 105** | **6** |

The signal still reaches the pickup, but it no longer propagates into the band state (`0x50`+) at
all. So **`CALLFLUSH` fixes the chorus's phase and starves the EQ's filter** — the two programs
want opposite things from the product register at a block CALL, which is precisely what a *correct*
decode must not do. ⇒ **§19's "mutually consistent" is withdrawn as stated**: the configuration is
consistent *for the chorus*, and the flush is not a program-neutral reading.

What survives §19 unqualified: the *diagnosis* — there are two independent paths that contaminate
the LFO block's entry LOAD, and both must be closed for the phase to survive. What does not is the
conclusion that the particular closure used is the chip's. A flush at the CALL is too blunt: the
chorus needs `P` clear at its body entry and the EQ needs `P` carried into its own, so whatever the
chip does is finer-grained than "flush on CALL" — conditional on the word, the block, or something
not yet decoded.

★ Separately and cleanly: **§148 is irrelevant to the EQ.** On and off give byte-identical results
(6 exact products, `92/7/3/0/2` accumulator classification, zero railed bands in both) — its
population is `SRC 0x00` on `f98 = 1` class-A words, which the EQ's biquad does not use. So the
chorus evidence against §148 stands unopposed by the reference program; removing it costs the EQ
nothing. That part of §9 is **confirmed on a second program**.

⚠ Grade: MEASURED (four EQ runs, frame pairs and product counts). This is a correction of this
session's headline result, found by testing it where it could do damage rather than where it was
built.

## 21. THE CANDIDATE §20 CALLS FOR: a DRIVEN product register (`UPD6383_PCLR`)
§20 says the chip's rule must be finer-grained than "flush on CALL". The obvious finer rule is
that the multiplier's output register is **driven, not held**: it carries the result of *this*
word's multiply, and a word that issues no multiply leaves it undriven, i.e. **zero**, for the
next word's `f31 = 0` LOAD. Implemented as `UPD6383_PCLR` (default off): a per-word flag
`m_ptouch` is set by every site that writes `m_p`, and at the end of each word an untouched `P` is
cleared.

### The PREDICTION, written from the listings BEFORE the run
- **Chorus.** The LFO block's entry LOAD is `iw88 = 00002F4407` (`ld.st acc,(p)-12`, `f31 = 0`).
  The three words before it — `iw85` `000020E1CD`, `iw86` `00002DE40E`, `iw87` `021222200B` — are
  all **class 2** and issue no multiply. So `PCLR` clears `P` before the LOAD, exactly as
  `CALLFLUSH` did, but by a local rule instead of a block-boundary one. ⇒ criterion (A) should
  still give **114**.
- **EQ.** A band is `ld.ta`, four back-to-back `mac`s, `mac.st tb`, `post acc,c` (class 8),
  `mac.st acc`. Between the four `mac`s nothing is cleared, because every one of them writes `P`.
  ⇒ criterion (B) should stay at the **no-flush** liveness, not the starved shape.
- ★ And it removes a **double count** the hold model has: `w11` (`post acc,c`) issues no multiply,
  so under the hold model `w12`'s accumulate adds `w10`'s product a **second time** — `w11` already
  consumed it. The clear happens *after* the word's datapath work, so `w11` still consumes it once.

If (A) or (B) fails, this reading dies like the others; it is recorded here as a prediction so the
measurement can contradict it rather than confirm a story written afterwards. Gate:
`dsp/tools/pair_gate.sh pclr UPD6383_LO12CAP=1 UPD6383_PCLR=1 UPD6383_SPEC=B9108446A39B440F`.

⚠ Grade: PREDICTED, not measured. The result follows in §22.

## 22. ⛔ §21 IS REFUTED — and so is the whole *product-register* family of fixes
The two-sided gate (`dsp/tools/pair_gate.sh`, one binary, one session, baseline arms
`UPD6383_PSHIFT=2 UPD6383_C8SHIFT=1`) on three configurations, all sharing
`UPD6383_LO12CAP=1 UPD6383_SPEC=B9108446A39B440F`:

| configuration | (A) chorus LFO increment | (B) EQ cells moved | (B) rows differing |
|---|---|---|---|
| no flush | 3 129 519 ⛔ | **39 of 44** | **105 of 105** |
| `+ CALLFLUSH=1` | **114** ✅ | 2 | 9 of 105 |
| `+ PCLR=1` | **114** ✅ | **0** | **0 of 105** ⛔ |

**§21's prediction was that `PCLR` would leave the EQ's back-to-back `mac`s untouched. It is
wrong.** `PCLR` does not merely reduce the EQ's liveness the way the flush does — it makes the
body **bit-identical across a frame pair**, i.e. completely static. The prediction was recorded
before the run precisely so this could happen, and it did.

★★ **The pattern across three configurations is the result, not the individual failures.** Every
rule that makes the chorus's phase come out right does so by **removing product from the EQ**, and
the more thoroughly it removes it, the more completely the EQ dies:

```
liveness  105 rows  ->  9 rows  ->  0 rows
phase       WRONG   ->   114    ->   114
```

That is a straight trade, not a decode. ⇒ **The contamination is not a retention policy on the
product register.** If it were, some retention rule would satisfy both programs, and three points
on the trade curve say none does. The chorus's LFO entry LOAD reads a product that should not be
*there*, which is a question about **what the preceding words did**, not about how long `P` lives.

⇒ Next, and it is a different investigation from this one: find which word leaves that product
behind and why the chip would not. §8 of `N-DEVICE-ALGEBRA-EXTRACTED-2026-09-12.md` opens one
concrete candidate on the kernel side — `iw45` fetching a **zero** coefficient off the delay
descriptor ramp because the cursor was seeded there, and `iw46` loading that zero over live audio.

⚠ Grade: MEASURED, `dsp/analysis/data/pair_gate_3configs_2026-09-12.txt` plus the five archived
captures `pg_*_2026-09-12.log.gz`. `UPD6383_PCLR` stays in the device **default-off**, with this
refutation in its comment, exactly like the other refuted arms.

## 23. ★★ WHAT ACTUALLY ERASES THE EQ: `iw88`, AND IT IS §138'S SHAPE
§22 said the next question is *what the preceding words left there*. Reading the EQ's body entry in
all three configurations answers it. Under `CALLFLUSH` (the middle column of §22):

```
iw84  cls2 ACT0D SRC07 f31=0   L = 4 904 681            <- the pickup, LIVE
iw86  cls2 ACT00 SRC00 f31=1   acc = 321 433 174 016    <- = 4 904 681 << 16, the audio IS in acc
iw87  cls2 ACT00 SRC00 f31=5   acc = 321 433 174 016       (held)
iw88  cls2 ACT07 SRC10 f31=0   acc = 0                  <- LOAD from P, and P is 0.  ERASED.
iw89+ every band cell 000000
```

**`iw86` puts the live input into the accumulator and `iw88` throws it away**, two words later,
by doing `acc ← P` on a word that issues **no multiply** — so `P` is not this word's result, it is
whatever survived from before. That is verbatim the shape `upd6383.cpp` already names:

> *"LOADing the accumulator from a stale product is not an operation; it is an erasure."* — §83,
> generalised by **§138 (`m_specmask` bit 55)** with `m_in_dram` dropped: *a LOAD that brought no
> fresh product is an erasure; treat it as HOLD.*

★ And it explains the whole trade in one sentence. Without the flush, `iw88` loads the **kernel's**
stale product (103 180 042 421) — which is itself audio-derived, so the EQ's bands keep moving and
the body looks live. **The EQ was never being fed correctly; it was being fed the kernel's leftover
product.** Clear that leftover by any means — flush at the CALL, drive the register per word, move
the cursor — and the EQ gets a clean zero instead, which is why *every* intervention kills it.

### The prediction, written before the run
`UPD6383_SPEC` bit 55 (§138) makes `iw88` HOLD instead of loading. Then:
- **EQ:** `iw88` keeps `321 433 174 016` — the actual input — and the bands are fed the right
  quantity for the first time, rather than the kernel's residue. Criterion (B) should pass, and
  pass *for the right reason*.
- **Chorus:** `iw88` would hold `acc = 205 088 689 406` from `iw87` instead of loading, so the phase
  word at `iw89` would add that in and the increment would **not** be 114. ⇒ criterion (A) is
  expected to FAIL, and if it does, that is informative rather than fatal: it would say the
  chorus's accumulator ought to be empty at `iw87` for a reason that has nothing to do with `iw88`.

Test: `dsp/tools/pair_gate.sh s138 UPD6383_LO12CAP=1 UPD6383_SPEC=B9908446A39B440F`
(`B9108446A39B440F | 1<<55`).

⚠ **Know the blast radius before reading the result** (`dsp/tools/load_nocoef_census.py`,
`data/load_nocoef_census_2026-09-12.txt`): of the corpus's **3 057** words, **1 302 (42.6 %)** are
`f31 = 0` LOADs and **1 084 of those fetch no coefficient — 35.5 % of every word in the corpus.**
This rule does not adjust one instruction; it changes **a third of the machine** from LOAD to HOLD.
A gate pass would be strong evidence, and a gate failure would not be surprising. The reverbs are
the most exposed (`prog16_room_reverb_1` 70 words, `prog08_gated_reverb` 53).

★ **And it is not the EQ's quirk.** `dsp/tools/entry_erasure_census.py` scans the first eight
words of every body image for the same shape — an `ACT 0x00 / f31 = 1` word (the bus-add that puts
the input in the accumulator) followed within three words by an `f31 = 0` word that fetches no
coefficient. **18 of the 38 distinct body images carry it**, the reference program among them
(`prog39_parametric_eq` `w2 0212200000 → w4 0000240407`), and so do NO OPERATION, the phaser, the
ensemble, the overdrive, the exciter, auto-pan, vibrato, auto-wah, the ring modulator and five
combis. ⇒ whatever this one situation decodes to reaches **about half the catalogue**, which is
both why it matters and why it must not be guessed.
⚠ The shape is in the BYTECODE; calling it an erasure is a statement about the DEVICE, which has
no fresh product there. On the chip the pipeline may have one. The census sizes the question.

⚠ Grade: the READING of the three traces is MEASURED (`data/pg_*_eq_2026-09-12.log.gz`); the
census is MEASURED (`data/entry_erasure_census_2026-09-12.txt`); the prediction is a prediction.

## 24. ★★ THE CHORUS NEEDS AN EMPTY **ACCUMULATOR**, NOT AN EMPTY PRODUCT REGISTER
Reading the chorus's phase block on the `CALLFLUSH` trace to the unit shows what the LFO actually
requires, and it is architectural rather than incidental:

```
iw89  clsA ACT00 SRC08 f31=1   acc = 0 + 0 + (114 << 16)            =       7 471 104
iw90  cls2 ACT00 SRC07 f31=1   acc = 7 471 104 + (2 800 486 << 16)  = 183 540 121 701
iw91  clsA ACT00 SRC08 f31=2   store -> cell 0x2ABB66 + 114 = 0x2ABBD8          ✔ +114
```

The sum `phase + increment` is formed across **two** words: `iw89` puts the **increment** in the
accumulator and `iw90` adds the **phase cell**. For that to work, `iw89` must start from an
**empty accumulator** — which is a statement about the accumulator at body entry, nothing to do
with how long a product lives.

⇒ `CALLFLUSH` reaches that state only **indirectly**: it empties `P`, and `iw88` (`f31 = 0`) then
loads the zero into `acc`. That is why it also takes the EQ's product path with it. **Clearing the
accumulator at the block CALL says what is actually required and leaves the product path alone** —
and the product path is the half the EQ needs (§23).

### The candidate pair, and its prediction
`UPD6383_CALLACC=1` (new, default off) **+** `UPD6383_SPEC` bit 55 (§138: a LOAD that brought no
fresh product is a HOLD):

- **Chorus:** the accumulator is 0 at body entry, so `iw89`/`iw90` form `phase + increment` and the
  increment comes out **114** — *and* the body stays live, because nothing has emptied `P`.
- **EQ:** `iw86` puts the live pickup in the accumulator, `iw88` now **holds** instead of loading
  the kernel's residue, so the bands are fed **their own input** for the first time (§23).

This is the first candidate that is not on §22's trade curve: the two arms act on **different
registers**, each addressing the program that needs it, and neither takes anything away from the
other. ⚠ It is also two speculative arms at once, and §138's blast radius is **35.5 % of the
corpus** (1 084 of 3 057 words) — so a pass is evidence, not proof, and each arm needs its own
single-arm run to say which half did the work.

Test, in this order:
```
dsp/tools/pair_gate.sh callacc      UPD6383_LO12CAP=1 UPD6383_CALLACC=1 UPD6383_SPEC=B9108446A39B440F
dsp/tools/pair_gate.sh s138         UPD6383_LO12CAP=1 UPD6383_SPEC=B9908446A39B440F
dsp/tools/pair_gate.sh callacc_s138 UPD6383_LO12CAP=1 UPD6383_CALLACC=1 UPD6383_SPEC=B9908446A39B440F
```
⚠ Grade: the trace reading is MEASURED; the pair is a PREDICTION, recorded before the build.

## 25. ★★ THE TRIPLE, DERIVED WORD BY WORD — *a block starts with an empty datapath*
§24 proposed `CALLACC` + §138 and I then traced what each word would actually do. It does not
work, and the same trace says what does. Working from the measured columns (`data/pg_*_cho`,
`pg_*_eq`), with §138's guard being `f31 == 0 && !coeff_fetch ⇒ HOLD`:

**Chorus, `CALLACC` alone.** `iw87` is `f31 = 1`, so §138 never touches it and the kernel's
product enters there: `acc ← 0 + P(kernel)`. ⇒ (A) fails.
**Chorus, §138 alone.** `iw84…iw88` all become HOLDs, so nothing clears the accumulator the kernel
left (421 997 151 871). ⇒ (A) fails.
**Chorus, `CALLACC` + §138.** Same as the first: `iw87` still admits the kernel's product.

⇒ the product register must ALSO be empty at the boundary. With **all three** on:

```
CHORUS                                     EQ
iw84 hold            acc = 0               iw84 hold            acc = 0
iw85 hold            acc = 0               iw85 hold            acc = 0
iw86 hold            acc = 0               iw86 acc+P+L<<16     acc = 4 904 681 << 16   <- the input
iw87 acc + P(0)      acc = 0               iw87 hold            acc = 4 904 681 << 16
iw88 hold            acc = 0               iw88 hold            acc = 4 904 681 << 16   <- SURVIVES
iw89 0 + P + 114<<16 -> increment 114 ✅    iw89 acc <- P (FRESH, coefficient word) -> band runs ✅
```

★ Note what each arm is doing, and that none of them is a patch:
| arm | what it says |
|---|---|
| `UPD6383_CALLFLUSH` | the **product register** does not cross a block boundary |
| `UPD6383_CALLACC` | neither does the **accumulator** |
| `SPEC` bit 55 (§138) | a word that **produced nothing** does not overwrite what is there |

Together: **a block starts with an empty datapath, and a word that computes nothing leaves it
alone.** That is one architectural statement in three switches, not three unrelated fixes — which
is exactly what §22 said was missing from every candidate so far.

### Predictions, before the runs
- `callacc` alone → (A) **fails** (the phase will not be 114); EQ unchanged from no-flush.
- `s138` alone → (A) **fails**; EQ may improve, since `iw88` stops erasing.
- **`callflush + callacc + s138` → both criteria pass**: chorus increment 114 *with a live body*,
  and the EQ live *and fed its own input* rather than the kernel's residue.
⚠ If the triple passes, that is still three speculative arms at once and §138 alone rewrites
**35.5 %** of the corpus — the single-arm runs above are what say which arm did what, and a pass
must be followed by a regression over the other programs, not shipped.

⚠ Grade: the per-word derivation is READ from measured columns; the three predictions are
predictions, recorded before the build.

## 26. THE REFERENCE TABLE, all three criteria, one binary
The gate's chorus half now carries its own liveness (§22 showed the phase landmark alone is a
starvation signature). Measured with `UPD6383_PSHIFT=2 UPD6383_C8SHIFT=1 UPD6383_LO12CAP=1
UPD6383_SPEC=B9108446A39B440F`:

| configuration | chorus increment | chorus body | EQ body |
|---|---|---|---|
| no flush | **3 129 519** ⛔ | LIVE — 4 of 17 cells, 24 of 70 rows | LIVE — **39 of 44 cells, 105 of 105 rows** |
| `+ CALLFLUSH=1` | **114** ✅ | LIVE — 3 of 17 cells, 21 of 70 rows | **2 of 44 cells, 9 of 105 rows** |

★ Both configurations leave the **chorus body live**, so the chorus's liveness half does not
discriminate between them — the discrimination is entirely in the phase and in the EQ. That is
worth stating because it means §19's original evidence ("body live **and** phase 114") was, on
this measurement, one real criterion and one that the baseline also passes.

Artefacts: `data/pair_gate_v2_3criteria_2026-09-12.txt`, `data/pg_v2_*_cho*_2026-09-12.log.gz`.
⚠ Grade: MEASURED. The run was stopped after these two configurations; `pclr` and `spec12` already
have their phase and EQ numbers in §22/§9 and only their chorus-liveness half is missing.

## 27. ⛔ THE TRIPLE IS REFUTED — and the diagnosis is that the body entry TRIPLE-COUNTS the input
Measured, same binary and baseline arms, `UPD6383_CALLFLUSH=1 UPD6383_CALLACC=1
UPD6383_SPEC=B9908446A39B440F`:

| | chorus increment | chorus body | EQ body |
|---|---|---|---|
| the triple | **5 211 349** ⛔ | LIVE, and the most of any configuration — 5 of 17 cells, **64 of 70 rows** | **0 of 44 cells, 0 of 105 rows** ⛔ |

§25's word-by-word derivation was wrong in both halves, and the traces say exactly where.

**Where the chorus derivation broke.** `CALLACC` works — `iw84` arrives at `acc = 0`. But `iw85`
(`ACT 0x0D`, `f31 = 0`, no coefficient) **still loads the bus**: `acc = 5 211 235 << 16`. I had
predicted §138's guard would make it HOLD. It does not fire there, so the accumulator is non-zero
from the body's second word onward and the phase word can never see zero.

**Where the EQ derivation broke — and this is the useful half.** Everything up to `iw88` went as
predicted: `iw85` held, the bus arrived, `iw88` held instead of erasing. But look at what the
accumulator actually contains by then:

```
iw84  ACT 0x0D  f31=0   acc  = 5 211 235 << 16        <- the bus, LOADED
iw86  ACT 0x00  f31=1   acc += 5 211 235 << 16        <- the same bus, ADDED
iw87  ACT 0x00  f31=5   acc += 5 211 235 << 16        <- the same bus, ADDED AGAIN
iw88  ld.st             STORE acc -> cell 0x10, and 3 x the input SATURATES: mem = 7FFFFF
```

★ **The body entry counts the same input three times**, and `iw88`'s store then rails the EQ's
pickup cell at `0x7FFFFF`. The bands read zero from `0x50` afterwards because the railed pickup
never propagates. Under the shipped decode this never showed, because `iw85`'s LOAD threw the
first copy away — **the erasure §23 identified was also the thing keeping the input from being
counted three times.**

⇒ **At most ONE of these three readings can be right as it stands:**
1. `ACT 0x0D` loads the accumulator from the bus (measured device behaviour, 63 + 29 rows);
2. `ACT 0x00` adds the bus on top of the `f31` op at `f31 = 1` (442 rows, §3 of the algebra note);
3. the same at `f31 = 5`.

That is a sharper, falsifiable statement than anything the retention-policy family produced, and it
is about the **bus term**, not about product lifetime. ⇒ the next round belongs there.

⚠ Grade: MEASURED (`data/pg_v3_triple_*`). The prediction it refutes was recorded in §25 before the
build, and the refutation is of my derivation, not of the instrument.

## Honest grade
§2 and §4's result are MEASURED, with a pre-registered two-sided criterion and a null (the shipped
device produces identical frames on the same rig). §3 is READ from the device plus MEASURED in the
trace (`tA` frozen, `iw39` consuming it). **The captured SOURCE is SPECULATIVE** — that ACT 0x19
takes the accumulator is a reasoned choice among {bus, acc, P}, motivated by the HLE's input stage
and by which quantity is input-dependent; the arm is default-off and changes no shipped decode.
⚠ What this does NOT establish: that the chip's ACT 0x19 reads the accumulator, that the value now
reaching the body is numerically right, or that any effect yet produces correct audio. It
establishes that one word's suppressed action is what holds the gate shut, and that releasing it
lets the body run.
§6 is a MEASURED refutation with its criterion registered in advance, and what it refutes is my own
DF-I assumption behind §10 — the flatness solve stays true of the ROM cells under DF-I and becomes
UNPROVEN as a statement about this device. The probe stays default-off and is marked never-to-ship.
