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

## 28. ★★ THE COMPLETE MATRIX — and `CALLACC` is a MEASURED NO-OP
Seven configurations, one binary, one session, baseline arms `UPD6383_PSHIFT=2 UPD6383_C8SHIFT=1
UPD6383_LO12CAP=1`. Criterion (A) is the chorus's LFO increment (114 at rest) *and* its body
liveness; criterion (B) is the EQ's body liveness.

| configuration | chorus increment | chorus body (cells/rows) | EQ body (cells/rows) |
|---|---|---|---|
| baseline (`SPEC …440F`) | 3 129 519 ⛔ | 4 of 17 / 24 of 70 | **39 of 44 / 105 of 105** |
| `+ CALLACC=1` | **3 129 519** | **4 of 17 / 24 of 70** | **39 of 44 / 105 of 105** |
| `+ CALLFLUSH=1` | **114** ✅ | 3 of 17 / 21 of 70 | 2 of 44 / 9 of 105 |
| `+ PCLR=1` | **114** ✅ | — | 0 / 0 ⛔ |
| `SPEC` bit 12 (cursor seed cleared) | **114** ✅ | — | 0 / 0 ⛔ |
| `SPEC` bit 55 (§138) alone | 168 353 ⛔ | 5 of 17 / 64 of 70 | 0 / 0 ⛔ |
| `CALLFLUSH + CALLACC + §138` | 5 211 349 ⛔ | 5 of 17 / 64 of 70 | 0 / 0 ⛔ |

★★ **`UPD6383_CALLACC` is identical to the baseline on every one of the three criteria** — the
same increment to the unit, the same 4 cells and 24 rows, the same 39 and 105. Clearing the
accumulator at the block CALL **changes nothing**, because the body's first two words overwrite it
anyway (`iw84`/`iw85` load the bus or a product). ⇒ **§24's premise is vacuous: the accumulator
does not carry across a block boundary in any observable way, so there is nothing there to clear.**
That is a clean negative, and it is only visible because the gate measures all three criteria at
once — a single-criterion run would have called it "no regression".

⛔ **§138 is refuted on its own**, not only inside the triple: the EQ goes bit-identical and the
chorus increment is wrong. The mechanism is §27's — with `iw85`'s LOAD turned into a HOLD the body
entry counts the same bus datum three times and `iw88`'s store rails the pickup cell at
`0x7FFFFF`. **The long-standing "a LOAD that brought no fresh product is an erasure" candidate is
dead as a blanket rule**, and its blast radius (35.5 % of the corpus) is why.

⇒ What stands after seven configurations: **nothing passes both criteria**, the one configuration
with a live EQ still has the wrong chorus phase, and the live question has moved off product
lifetime entirely and onto the **bus term at the body entry** — at most one of §27's three
readings can be right as it stands.

⚠ Grade: MEASURED. `data/pair_gate_v3_matrix_2026-09-12.txt`, `data/pg_v3_*_2026-09-12.log.gz`,
`data/pair_gate_v2_3criteria_2026-09-12.txt`, `data/pair_gate_3configs_2026-09-12.txt`.

## 29. ★★★ THE CRITERION THE HLE SUPPLIES — *one copy of the input* — AND IT REVERSES §20
Every criterion used so far was **self-consistency**: do two frames differ, does the phase advance
by its increment. Neither asks whether the number arriving is the **right** number, and §27 showed
why that is not a detail — a body entry that counts the same input three times is extremely alive
and completely wrong. The HLE supplies the missing criterion, and it is the simplest one in the
project: **the EQ's input is ONE copy of the pickup.**

`dsp/tools/pickup_copies.py` reads the bus datum the body entry takes and the pickup cell the band
chain reads, and divides. Over the seven gate configurations
(`data/pickup_copies_2026-09-12.txt`):

| configuration | bus datum | cell `0x10` | ratio | verdict |
|---|---|---|---|---|
| **`+ CALLFLUSH=1`** | 4 904 681 | **4 899 462** | **0.999** | ✅ **ONE COPY** |
| baseline | 4 904 681 | 7 792 377 | 1.589 | ⛔ |
| `+ CALLACC=1` | 4 904 681 | 7 792 377 | 1.589 | ⛔ |
| `SPEC` bit 55 (§138) | 5 211 235 | **8 388 607** | 1.610 | ⛔ RAILED |
| the triple | 5 211 235 | **8 388 607** | 1.610 | ⛔ RAILED |
| `+ PCLR=1` | 0 | 0 | — | ⛔ no input at all |
| `SPEC` bit 12 | 0 | 524 288 | — | ⛔ no input at all |

★★★ **`CALLFLUSH` is the only configuration in which the body entry delivers a correct input**, and
it does it exactly: `iw88`'s bit-4 store takes the accumulator *before* its own ALU step — the
order this file already calls FORCED (R1 F2) — and under the flush that accumulator holds
`4 904 681 << 16`, one clean copy, which it writes to cell `0x10`.

⇒ **§20's interpretation is REVERSED, and §22's with it.** The statement *"`CALLFLUSH` starves the
EQ"* is true as a **liveness** measure and false as a diagnosis. The baseline's 39-of-44 moving
cells were **the kernel's stale product being filtered**, not the EQ's input being processed —
§23 said exactly that and I did not draw the consequence. The liveness criterion was **rewarding
contamination**, and the one configuration it marked worst is the one delivering the right number.
⚠ What survives §20 unchanged: a claim must be tested on both programs. What does not: which way
the EQ's own evidence pointed.

⚠ This does **not** promote `CALLFLUSH` to "correct". It says the flush gets **the body entry's
input** right, on the one criterion that can distinguish right from merely alive. The chorus phase
agrees with it (114). What is still wrong under it is downstream — §30.

## 30. THE GAP, NOW ONE CELL WIDE: nothing writes the band's input cell `0x50`
With the input correct at `0x10`, the EQ's bands still do not run: 2 of 44 cells and 9 of 105 rows.
The trace says why, and it is a single cell.

```
iw88  cls2 ACT07 SRC10 f31=0   ld.st acc,(p)+64   store -> cell 0x10 (pre-increment), ptr -> 0x50
iw89  clsA ACT13 SRC07 f31=0   ld.ta (p),c+,(p)+0 reads  cell 0x50   <- the band's x input
```

Scanning **every row of the frame, both units**, only **two** address cell `0x50` — `iw88` and
`iw89`, and both are reads. **No word in the traced frame writes it.** Under the baseline it
nonetheless holds `1 572 727` (audio-derived, from the contamination); under `CALLFLUSH` it holds
**0**, and the bands have nothing to filter.

⇒ **The next target is `0x50`'s writer** — and the captures ALREADY CARRY the answer, in the
device's own store census, so no new run was needed:

```
§99  MODE-1 STORES -> register file: … 50:1331600 51:1340068 52:1329064 53:1338511 …
     MODE-1 ACT-07 STORES: … [dest 50 src 0B ptr 50] [dest 51 src 0B ptr 51] [dest 52 src 0B ptr 52]
```

Cells `0x50`–`0x53` **are** written, about 1.33 M times each — by **mode-1 `ACT 0x07` stores with
`SRC 0x0B`**. ⚠ But that census is **CUMULATIVE SINCE BOOT** (the same caveat that forced the
delay-age retraction), and **neither the EQ's listing nor the kernel's contains a word of that
shape**: the EQ's 33 `ACT 0x07` words carry `addr8 ∈ {0x40, 0xFF, 0x03, 0xAD, 0x30, 0x54}` and the
kernel's two `SRC 0x0B` words are `ACT 0x15`/`ACT 0x19`. ⇒ **those stores belong to a different
program**, and the correction to the paragraph above is this: *nothing the EQ or the kernel
executes writes the band's input cell at all.* The baseline's non-zero `0x50` is **residue left by
whatever ran before it**.

## 31. ★★★ AND THE BRIDGE IS ONE EXISTING MASK BIT: `§109`, bit 28
`iw88` stores to `0x10` and `iw89` reads `0x50`; nothing joins them. The device says why in its own
report line:

```
§109 ACT-07 store target = PRE-increment (mask bit 28 = 0)
```

`iw88` is `ld.st acc,(p)+64`: its pointer moves `0x10 → 0x50`, and the `ACT 0x07` store is aimed at
the pointer **before** that move. **Aim it after the move and the store lands on `0x50` — exactly
the cell the band reads.** That bit already exists and has never been run against the EQ with a
correct input in the accumulator, because until §29 there was never a configuration that had one.

### Prediction, before the run
`UPD6383_CALLFLUSH=1 UPD6383_SPEC=B9108446B39B440F` (the shipped mask **+ bit 28**):
- (C) the pickup stays **one clean copy** — `CALLFLUSH` already delivers it;
- **the band's `x` cell `0x50` receives that copy instead of `0x10`**, so the five bands run on the
  EQ's own input for the first time;
- (B) EQ liveness rises well above the flush's 2 cells / 9 rows, and rises **for the right
  reason**;
- (A) the chorus is untouched by a store-target change on `ACT 0x07`… ⚠ **not necessarily** — the
  chorus has `ACT 0x07` stores too, so this must be run through all four criteria, not just the EQ.

⚠ If it fails, the alternative is the mirror image: the `+64` pointer move is mis-ordered rather
than the store mis-aimed. Both are single decisions about the same word.

⚠ Grade: the census reading and the listing check are MEASURED; the prediction is a prediction,
recorded before the run.

⚠ Grade: MEASURED, `data/pickup_copies_2026-09-12.txt` + the seven archived EQ captures. §29's
reversal is a correction of my own §20/§22 interpretation on the project's own evidence.

## 32. ⛔ RETRACTED BY §34 — READ §34 FIRST. (kept in full; the EQ half stands, the headline does not)
## 32. ~~★★★★★ IT PASSES. ALL FOUR CRITERIA, FOR THE FIRST TIME~~ — `CALLFLUSH` + §109 bit 28
`UPD6383_LO12CAP=1 UPD6383_CALLFLUSH=1 UPD6383_SPEC=B9108446B39B440F`, baseline arms as always:

| criterion | result |
|---|---|
| (A) chorus LFO increment | **114** ✅ |
| (A) chorus body liveness | LIVE — 2 of 17 cells, 16 of 70 rows ✅ |
| (B) EQ body liveness | LIVE — **13 of 44 cells, 94 of 105 rows** ✅ (was 2 / 9 under the flush alone) |
| (C) one copy of the input | ✅ **at `0x50`, `0x54`, `0x58`, `0x5C`, `0x60`** — ratio **1.000** at every one |

★★★ **Those five cells are the five bands' state blocks**, spaced exactly 4 apart, which is the
EQ's decoded topology (five bands × a 4-cell Direct-Form-I block). **Every band now receives
exactly one copy of the input**, and the frame pair shows the filtered results moving beside them:

```
0x05  4 900 429 -> 4 905 834     the kernel's pickup
0x50  4 900 429 -> 4 905 834     band 1 x   <- ONE COPY
0x54  4 900 429 -> 4 905 834     band 2 x
0x58  4 900 429 -> 4 905 834     band 3 x
0x5C  4 900 429 -> 4 905 834     band 4 x
0x60  4 900 429 -> 4 905 834     band 5 x
0x52 -1 584 693 -> -1 586 989    band 1 y   <- and the bands are FILTERING
0x5A  7 930 544 -> 7 928 308     band 3 y
0x62  6 290 625 -> 6 288 694     band 5 y
0x66 -2 896 796 -> -2 894 720
0x6A  7 704 710 -> 7 702 465
0x6E -5 414 305 -> -5 411 857
```

### What the change actually is
One bit, already in the device, never previously runnable against the EQ because until §29 there
was no configuration that put a correct input in the accumulator to begin with:

> `§109 ACT-07 store target = PRE-increment (mask bit 28 = 0)` → set it, and the store on
> `iw88 = ld.st acc,(p)+64` lands on the pointer **after** its `+64`, i.e. on `0x50` — the cell
> `iw89` reads — instead of on `0x10`, which nothing reads.

⚠ **Two arms, and the honest split between them.** `CALLFLUSH` supplies the clean single copy in
the accumulator (§29); bit 28 delivers it to the cell the band reads (§31). Neither works alone:
the flush alone leaves the bands at 2 cells / 9 rows, and bit 28 without it would store the
contaminated accumulator. Both remain **speculative and default-off** — this is a joint pass of
four criteria on two programs, which is the strongest evidence this project has had for a body-side
reading, and it is still not proof.

⚠ **One instrument bug this exposed, fixed in the same breath:** `pickup_copies.py` hard-coded
cell `0x10` and therefore reported the *correct* configuration as "0.000 copies" — it was
measuring the cell the store no longer targets. It now checks the store-target candidates and
names the cells that hold the input. A criterion that moves with the thing it measures is not a
criterion; this one nearly cost the result.

⚠ Grade: MEASURED, `data/pair_gate_bit28_2026-09-12.txt`, `data/pg_bit28_*_2026-09-12.log.gz`,
`data/pickup_copies_2026-09-12.txt`. Next: a regression over the other programs before any of this
is promoted out of default-off, and the single-arm run (bit 28 without the flush) to confirm the
split above.

## 33. THE SPLIT, CONFIRMED TWO-SIDED — bit 28 delivers, `CALLFLUSH` cleans
§32 claimed the two arms do different jobs and that neither works alone. Run bit 28 **without**
the flush (`UPD6383_LO12CAP=1 UPD6383_SPEC=B9108446B39B440F`):

| criterion | bit 28 alone | bit 28 + `CALLFLUSH` |
|---|---|---|
| chorus increment | 3 129 519 ⛔ | **114** ✅ |
| chorus body | 5 of 17 cells, 24 of 70 rows | 2 of 17, 16 of 70 |
| EQ body | 12 of 44 cells, 72 of 105 rows | 13 of 44, **94 of 105** |
| one copy of the input | ⛔ **RAILED at `0x50`, `0x54`, `0x58`, `0x5C`, `0x60`** | ✅ **1.000 at all five** |

★ Exactly the predicted shape. Bit 28 alone **does** reach the bands — all five state blocks now
receive something, where before nothing did — but what it delivers is the **contaminated**
accumulator, and it rails every one of them. The flush is what makes the delivered quantity one
clean copy.

⇒ **Each arm is doing a distinct, nameable job**, and each is falsified without the other:
| arm | job | without it |
|---|---|---|
| `UPD6383_CALLFLUSH` | the product register does not cross a block boundary, so the accumulator at the store holds **one copy of the input** | the bands are fed the kernel's residue and **rail** |
| `§109` bit 28 | the `ACT 0x07` store lands on the pointer **after** its post-increment, i.e. the cell the band **reads** | the copy is written to `0x10`, which nothing reads, and the bands stay at **2 cells / 9 rows** |

That is the cleanest joint result this investigation has produced: two arms, two distinct jobs,
each demonstrably necessary, and the pair passing four criteria on two programs. ⚠ Still joint
evidence and still default-off until a regression over the remaining programs.

⚠ Grade: MEASURED, `data/pair_gate_bit28only_2026-09-12.txt` + `data/pg_bit28only_*`.

## 34. ⛔⛔ §32's HEADLINE IS RETRACTED — the chorus criterion could not fail, and the phase is DEAD
§32 claimed the first configuration to pass all four criteria. **It does not.** The chorus
criterion I was using — the phase cell's **within-frame** delta — is one of those criteria that
cannot fail in the way that matters, which is the rule this project wrote down years of passes ago
and which I applied to everyone's work but my own.

`iw89` LOADs the increment into the accumulator and `iw91` stores it, so the **delta is 114 even
when the cell is reset to zero every frame and the LFO never advances at all.** And the device has
been printing the right measurement in every single capture the whole time — §119's witness, the
phase cell resident at body-0 `iw89` **on eight consecutive frames**:

| configuration | phase, 8 consecutive frames | step | verdict |
|---|---|---|---|
| **`CALLFLUSH`** | 7 273 022 · 7 273 136 · 7 273 250 · 7 273 364 … | **+114 constant** | ✅ **free-running ramp** |
| `PCLR` | identical | +114 | ✅ |
| `SPEC` bit 12 | identical | +114 | ✅ |
| **`CALLFLUSH` + bit 28** | **0 · 0 · 0 · 0 · 0 · 0 · 0 · 0** | 0 | ⛔ **NO PHASE AT ALL** |
| bit 28 alone | 3 168 511 × 8 | 0 | ⛔ frozen |
| baseline | 6 987 734 · 1 767 751 · 4 936 376 … | varies | ⛔ |
| the triple, §138, `CALLACC` | wander | varies | ⛔ |

⇒ **§109 bit 28 destroys the chorus's LFO.** With the flush the phase is zero on every frame;
without it, frozen at a constant. Either way the modulation is dead, and §32's criterion (A) —
both halves of it, the delta *and* the body liveness — reported a pass.

### What survives §32, and what does not
- ⛔ **"The first configuration to pass all four criteria" is withdrawn.** There is none.
- ⛔ **bit 28 is back on §22's trade curve**, and its trade is now exactly characterised: it fixes
  the EQ's delivery and kills the chorus's LFO.
- ✅ **The EQ half of §32 stands and is unaffected**: with bit 28 the five band blocks
  `0x50`/`0x54`/`0x58`/`0x5C`/`0x60` each receive **exactly one copy** of the input and the body
  moves 94 of 105 rows. That measurement is about the EQ and is not touched by the chorus witness.
- ★★ **And §29's result is now much STRONGER, not weaker.** `CALLFLUSH` was already the only
  configuration delivering one clean copy of the input; the eight-frame witness now independently
  shows it is also the only family of configurations giving the chorus a **correct free-running
  ramp at exactly the increment**. Two unrelated criteria, two programs, same answer.

### The instrument, fixed
`dsp/tools/lfo_ramp_check.py` reads §119's witness and checks the only property an LFO phase must
have: a **constant, non-zero step**. It runs on **any archived chorus capture**, which is how this
was found — retrospectively, on captures taken hours earlier. The gate's criterion (A) now uses it
instead of the within-frame delta.

⚠ ⚠ **The lesson, recorded against my own headline:** I built a four-criterion gate specifically
because single criteria had been fooling this project, then let the most important of the four be
a quantity that is constant under the failure it was meant to detect. *A criterion must be able to
fail in the way the thing fails.* The evidence was already in the logs; nothing new was captured
to find it.

⚠ Grade: MEASURED, `data/lfo_ramp_check_2026-09-12.txt`, from the nine archived chorus captures.

## 35. ★★ THE CATALOGUE ANSWERS: `CALLFLUSH` + bit 28 IS DISQUALIFIED ON TEN PROGRAMS
§34 caught the chorus. The catalogue regression (`dsp/tools/catalogue_regression.sh` +
`regression_report.py`, ten programs spanning modulation, reverb, both delay shapes and the
biquad, one frame pair each, baseline vs candidate) shows it is not one program:

| TYPE | effect | baseline live/rail/prod | candidate live/rail/prod | verdict |
|---|---|---|---|---|
| 0 | CHORUS | LIVE 4/17 0 53 | LIVE 2/17 0 48 | ⛔ **LFO FROZEN** |
| 1 | MODULATED CHORUS | LIVE 6/20 0 68 | LIVE 3/20 0 63 | ⛔ **LFO FROZEN** |
| 2 | ENHANCER | LIVE 5/31 0 46 | LIVE 2/31 0 **10** | ⚠ products halved or worse |
| 3 | FLANGER | LIVE 3/13 1 56 | LIVE 1/13 0 41 | ⛔ **LFO FROZEN** |
| 4 | PHASER | LIVE 26/32 0 87 | LIVE 25/32 0 **24** | ⛔ **LFO FROZEN** + products |
| 5 | ENSEMBLE | LIVE 6/23 1 37 | LIVE 4/23 0 35 | ⛔ **LFO FROZEN** |
| 6 | GATED REVERB | LIVE 3/15 0 53 | LIVE 3/15 0 51 | ✅ |
| 7 | SINGLE DELAY | LIVE 1/10 0 44 | LIVE 1/10 0 41 | ✅ |
| 8 | MULTI TAP DELAY | LIVE 3/13 0 44 | LIVE 2/13 0 32 | ✅ |
| 15 | PARAMETRIC EQ | LIVE 39/44 **0** 100 | LIVE 13/44 **9** 71 | ⛔ **9 new RAILED cells** |

⇒ **Every modulation program loses its LFO**, and the EQ — the program the change was *for* —
gains **nine railed cells**. Two independent disqualifications on top of §34's. The three
programs that pass are exactly the three with no LFO phase word and no biquad.

★ **And the EQ result refines §32 rather than erasing it.** §32's measurement stands: with bit 28
the five band `x` cells each receive **one clean copy** of the input. What the regression adds is
that **nine other cells rail** — the filter's own outputs saturating. So the delivery is right and
the **downstream gain is too high**: the bands are now fed properly and overdriven. That is a
different, narrower, and much more tractable problem than "nothing reaches the bands", and it is
where the EQ thread resumes.

### Two instrument bugs this table exposed, both fixed before the numbers above were read
1. ⛔ **The LFO column only fired when the BASELINE had a ramp to lose** — and the baseline here is
   the unflushed configuration, whose phase already wanders. So it stayed **silent** on a candidate
   §34 had already measured to leave the phase at 0 on eight consecutive frames. *A comparison
   against a broken reference is not a test.* It now reports the candidate's ramp on its own terms.
2. ⛔ **…and then it over-fired**, flagging "LFO FROZEN" for SINGLE DELAY, GATED REVERB and the EQ,
   which have no LFO phase word at `iw89` at all — the §119 witness samples that cell regardless.
   The measurement was real and the subject was not. It now asks the trace whether the body
   actually contains the phase-accumulate word (`hi12 = 092`, class A) before judging.
   ⚠ Same shape of error as grading a starved body on liveness, twice in one afternoon.

⚠ Grade: MEASURED, `data/regression_bit28_2026-09-12.txt`; captures in the session scratch are
regenerable with the two commands in the tools' docstrings and are not committed (40 logs, ~25 MB).

## 36. ★★★★ `CALLFLUSH` ALONE PASSES THE CATALOGUE — zero regressions, and FIVE programs gain an LFO
Same ten programs, same baseline, candidate = `UPD6383_CALLFLUSH=1` on its own
(`data/regression_callflush_2026-09-13.txt`):

| TYPE | effect | baseline live/rail/prod | candidate live/rail/prod | verdict |
|---|---|---|---|---|
| 0 | CHORUS | LIVE 4/17 0 53 | LIVE 3/17 0 46 | ✅ ★ **LFO +114/frame — was not a ramp** |
| 1 | MODULATED CHORUS | LIVE 6/20 0 68 | LIVE 5/20 0 62 | ✅ ★ **LFO +114/frame — was not a ramp** |
| 2 | ENHANCER | LIVE 5/31 0 46 | LIVE 2/31 0 **10** | ✅ ⚠ products halved or worse |
| 3 | FLANGER | LIVE 3/13 1 56 | LIVE 3/13 1 52 | ✅ ★ **LFO +114/frame — was not a ramp** |
| 4 | PHASER | LIVE 26/32 0 87 | LIVE 26/32 0 86 | ✅ ★ **LFO +114/frame — was not a ramp** |
| 5 | ENSEMBLE | LIVE 6/23 1 37 | LIVE 4/23 1 35 | ✅ ★ **LFO +114/frame — was not a ramp** |
| 6 | GATED REVERB | LIVE 3/15 0 53 | LIVE 3/15 0 51 | ✅ |
| 7 | SINGLE DELAY | LIVE 1/10 0 44 | LIVE 1/10 0 41 | ✅ |
| 8 | MULTI TAP DELAY | LIVE 3/13 0 44 | LIVE 2/13 0 28 | ✅ |
| 15 | PARAMETRIC EQ | LIVE 39/44 0 100 | LIVE 2/44 0 **9** | ✅ ⚠ products halved or worse |

**0 regressions.** No body dies, **no cell rails anywhere** (the flanger's and ensemble's single
railed cell is present in the baseline too), and **five of the five programs that have an LFO phase
word gain a correct free-running ramp at exactly the increment, where the baseline had none.**

★★ That is now **four independent lines of evidence for the same single change**:
1. §29 — it is the **only** configuration delivering **one clean copy** of the EQ's input;
2. §34 — it is the only family giving the chorus a **constant +114/frame** phase;
3. §36 — **five** programs gain that ramp, not one;
4. §36 — **zero** regressions across ten programs spanning four families.

⚠ **The two ⚠ flags, stated plainly rather than explained away:**
- **PARAMETRIC EQ, 100 → 9 products.** This is the KNOWN open problem, not a new one: §23/§29
  established that the baseline's EQ activity is **the kernel's residue being filtered**, and the
  flush removes the residue. The bands are then correctly fed at `0x10` — which nothing reads
  (§30). Expected, understood, and the EQ thread's next step.
- **ENHANCER, 46 → 10 products.** ⚠ **NOT explained.** It is not an LFO program and it does not
  rail; its arithmetic simply drops by a factor of four. This is the one thing the catalogue flags
  that no current reading accounts for, and it should be looked at before anyone treats the flush
  as settled.

⇒ On this evidence the arm is **promoted to default-ON**, with `UPD6383_CALLFLUSH=0` to restore the
old behaviour so the A/B stays available — the same treatment §225 gave `UPD6383_LFOWRAP`. It is
the first body-side reading in this investigation to be promoted on catalogue evidence rather than
on two programs.

⚠ Grade: MEASURED, ten programs, one binary, one baseline. Promotion is a judgement on that
evidence, and the enhancer flag is the standing argument against it.

## 37. ★★ THE ENHANCER FLAG IS RESOLVED — it is §30, on a second program, unmasked
§36 promoted the flush with one standing objection: the **ENHANCER's** non-zero product rows drop
**46 → 10** and nothing explained it. Reading its body entry in both configurations explains it
completely, and the answer is not a regression.

```
ENHANCER body entry, WITH the flush                      (base = the same words, residue instead of 0)
iw85  cls2 ACT0D SRC07 f31=0   acc = 320 968 982 528   <- = 4 897 598 << 16, THE INPUT
iw86  cls2 ACT0E SRC10 f31=0   acc = 0                 <- LOAD from P.  input DISCARDED
iw87  cls2 ACT00 SRC00 f31=1   acc = 320 968 982 528   <- the bus term puts it BACK
iw88  cls2 ACT00 SRC00 f31=5   acc = 320 968 982 528      and the pointer moves 0x10 -> 0x50
iw89  clsA ACT15 SRC07 f31=0   acc = 0, L = 0, mem[0x50] = 0   <- the body reads a cell NOTHING WROTE
```

From `iw89` on every operand is zero, so every multiply is zero — which is the entire 46 → 10.
**Under the baseline the same words run and the same discard happens**; the only difference is that
`iw86` loads the *kernel's residue* instead of zero, so the body has a non-zero number to multiply.
⇒ **the flush did not break the enhancer. It removed the residue that was standing in for its
input**, exactly as §23/§29 established for the EQ.

★★ **And the two programs now state the same gap in the same words.** Compare:

| | ENHANCER | PARAMETRIC EQ |
|---|---|---|
| input assembled in the accumulator | `iw85`/`iw87` | `iw84`/`iw86` |
| pointer moves to the band/state block | `iw88`, `0x10 → 0x50` | `iw88`, `0x10 → 0x50` |
| first body word reads | `iw89` `ld (p),c+,(p)+0` at **`0x50`** | `iw89` `ld.ta (p),c+,(p)+0` at **`0x50`** |
| what is in `0x50` | **0** | **0** |

Two unrelated effect families, the same entry shape, the same empty cell. ⇒ §30's question —
**what writes `0x50`** — is not an EQ quirk; it is *the* remaining body-side gap, and it is now
stated on two programs. The EQ has an explicit store at `iw88` whose target is the **pre**-increment
pointer (`0x10`, unread); the enhancer's `iw88` carries no store bit at all. Whatever the chip does
to get the entry's accumulator into `0x50`, the device is not doing it in either program.

### One candidate explanation CLOSED before anyone spends a build on it
The obvious suspicion is that the pointer move is mis-decoded — that the entry word lands the
pointer on the wrong cell. **It does not.** Both programs' `iw88` carries `addr8 = 0x40`, the
disassembler reads it as the signed post-increment `+64`, and `0x10 + 64 = 0x50` — the cell the
next word reads. ⚠ I first read that field as `0x24` by mis-slicing `addr8` out of the word and
nearly wrote up a decode error that does not exist; the field is bits [19:12]. **The pointer
arithmetic is right in both programs**, so the fault is in the STORE, not in the walk.

And the two programs constrain the store differently, which is the useful half:
- the **EQ**'s `iw88` carries `ACT 0x07` — a store — aimed at the **pre**-increment pointer
  (`0x10`), per the device's own `§109 ACT-07 store target` line;
- the **enhancer**'s `iw88` (`002A240000`) has `ACT 0x00`: **no store at all**. Its only `ACT 0x07`
  store is `w8`, four words later, by which time the body has already read `0x50`.

⇒ **A store-target change cannot fix both**, which is an independent reason §109 bit 28 was never
going to be the answer, quite apart from the LFOs it freezes. Whatever puts the entry's accumulator
into `0x50` is something the enhancer's entry does *without* a store word — so the next question is
not "which pointer does the store use" but **"is `0x50` written by the entry at all, or does the
body's first read take its operand from somewhere other than `mem[ptr]`?"**

⇒ **The §36 promotion's standing objection is withdrawn**: the enhancer flag is the known open
problem made visible, not a new fault. The flag stays in the table — it is a real difference — but
it is no longer unexplained, and it is no longer an argument against the flush.

⚠ Grade: MEASURED, from the committed regression captures' own traces
(`reg/base/t2_F.log`, `reg/flush/t2_F.log`; regenerable per `catalogue_regression.sh`).

## 38. ★★ THE REMAINING GAP HAS A NAMED DISCRIMINATOR: the SIGN of the store word's `addr8`
§37 left the question as *"is `0x50` written by the entry at all?"*. Comparing the programs that
work with the two that do not answers it, and narrows the solution to one field.

**A program whose body reads live data writes its state cells with the BIT-4 store.** The
SINGLE DELAY's body entry is the control — it reads `0x50` and finds **−201**, not zero:

```
SINGLE DELAY   w3 = 0212A011D5   mac (p),c+,(p)+1 ; mem[p]<-acc, acc=0   <- hi12 0x212 carries HI_ST
               w4 = 0202A481D5   mac (p),c+,(p)+72                       -> pointer reaches 0x50
PARAMETRIC EQ  w4 = 0000240407   ld.st acc,(p)+64                        <- hi12 0x000: NO bit-4 store
ENHANCER       w4 = 002A240000                                           <- ACT 0x00: no store at all
```

⇒ the delay's cells are filled by **bit-4 stores on class-A words**, which land at `mem[ptr]` and
work. The EQ's only store at its entry is the **`ACT 0x07` site-3 store**, and the enhancer has
none — which is why exactly those two start on an empty cell while the delay does not. (Of the ten
programs swept, the first body read finds live data in seven; `0x50` itself holds **−201** in the
single delay, so the cell is perfectly writable.)

### ★ And the discriminator is ONE FIELD
The chorus's phase store and the EQ's entry store are the **same word but for one field**:

| | word | ACT | SRC | f31 | `addr8` |
|---|---|---|---|---|---|
| CHORUS `iw88` (phase cell must keep working) | `00002F4407` | 07 | 10 | 0 | **0xF4 = −12** |
| PARAMETRIC EQ `iw88` (needs the store at `0x50`) | `0000240407` | 07 | 10 | 0 | **0x40 = +64** |

The EQ needs the `ACT 0x07` store at the **post**-increment pointer; the chorus needs it at the
**pre**-increment pointer, because §109 bit 28 moves *every* such store and that is precisely what
freezes the LFOs (§35). **The two words differ only in the SIGN of their post-increment.**

⇒ **The next hypothesis, named and falsifiable:** the `ACT 0x07` store target depends on the sign
(or the magnitude) of `addr8` rather than being uniform. Corpus census of `ACT 0x07` words carrying
no bit-4 store: **181 with `addr8 > 0`, 155 with `addr8 < 0`, 54 with `addr8 == 0`** — a real split,
not a handful of special cases, so a sign-dependent rule is testable on hundreds of sites and the
catalogue regression is already built to grade it.

⚠ **This is a HYPOTHESIS, not a reading.** "The two words that need opposite behaviour differ in
this field" is a constraint on the answer, not the answer: the difference could equally be carried
by something the trace does not print. What is MEASURED is the constraint itself — that a uniform
store target cannot satisfy both programs — and that is worth more than another arm, because it
rules out the whole family of uniform-target fixes including the one §32 got excited about.

⚠ Grade: the listings, the census and the ten-program first-read table are MEASURED; the
sign-dependence is the next experiment, stated so it can fail.

## 39. ★★★★★ §38's HYPOTHESIS PASSES ALL FOUR CRITERIA — the sign of `addr8` IS the discriminator
`UPD6383_ST07SIGN=1` (new, default off): the `ACT 0x07` mode-2 store lands on the **POST**-increment
cell when `addr8 > 0`, and on the PRE cell otherwise. Run through the gate at
`UPD6383_LO12CAP=1 UPD6383_SPEC=B9108446A39B440F` with the baseline arms:

| criterion | result |
|---|---|
| (A1) chorus LFO, **eight-frame witness** | ✅ **FREE-RUNNING RAMP at +114/frame** |
| (A2) chorus body live | ✅ 3 of 17 cells, 21 of 70 rows |
| (B) EQ body live | ✅ **30 of 44 cells, 105 of 105 rows** |
| (C) one copy of the input | ✅ **at `0x50`, `0x54`, `0x58`, `0x5C`, `0x60`** |

The arm fired **10 733 061** times, so it is not a no-op. ★★★ **This is what §32 was reaching for
and got wrong**: the EQ's five band blocks each receive one clean copy of the input **and** the
chorus keeps a correct free-running oscillator — on the very criterion (the §119 eight-frame
witness) that exposed §32's failure. The EQ's liveness is also the highest of any configuration
tried: **30 of 44 cells and 105 of 105 rows**, against bit 28's 13 and 94.

★ **The prediction was written before the run** (§38), from a constraint rather than a guess: the
chorus's phase store and the EQ's entry store are the same word but for `addr8` (`−12` against
`+64`), a uniform target cannot serve both, and the census said the split is real
(181 positive / 155 negative / 54 zero among `ACT 0x07` words carrying no bit-4 store).

⚠ **NOT PROMOTED YET, and the reason is this session's own history.** §32 also passed everything I
was measuring at the time, and it was wrong because a criterion could not fail. The standard this
investigation now holds is the **ten-program catalogue regression** — the instrument that
disqualified bit 28 on five LFOs and nine railed cells — and that is running. Nothing is promoted
on two programs again.

⚠ Grade: MEASURED on the two reference programs
(`data/pair_gate_st07sign_2026-09-13.txt`, `data/pg_st07sign_*_2026-09-13.log.gz`). The catalogue
verdict follows in §40.

## 40. ★★★★★ THE CATALOGUE AGREES — `UPD6383_ST07SIGN` IS PROMOTED, AND THE EQ'S BODY RUNS
Isolated against the **flush-only** sweep (so the comparison measures this change and nothing
else), ten programs, one frame pair each (`data/regression_st07sign_2026-09-13.txt`):

| TYPE | effect | flush only | + `ST07SIGN` | |
|---|---|---|---|---|
| 0 | CHORUS | 3/17 0 46 | 3/17 0 46 | ✅ unchanged, LFO +114 |
| 1 | MODULATED CHORUS | 5/20 0 62 | 5/20 0 62 | ✅ unchanged, LFO +114 |
| 2 | ENHANCER | 2/31 0 10 | 2/31 0 10 | ✅ unchanged |
| 3 | FLANGER | 3/13 1 52 | 3/13 1 **53** | ✅ **+1 product**, LFO +114 |
| 4 | PHASER | 26/32 0 86 | 26/32 0 86 | ✅ unchanged, LFO +114 |
| 5 | ENSEMBLE | 4/23 **1** 35 | 4/23 **0** 35 | ✅ **a railed cell REMOVED**, LFO +114 |
| 6 | GATED REVERB | 3/15 0 51 | 3/15 0 51 | ✅ unchanged |
| 7 | SINGLE DELAY | 1/10 0 41 | 1/10 0 41 | ✅ unchanged |
| 8 | MULTI TAP DELAY | 2/13 0 28 | 2/13 0 28 | ✅ unchanged |
| **15** | **PARAMETRIC EQ** | **2/44 0 9** | **30/44 0 90** | ✅ **+28 cells, +81 products** |

**0 regressions.** Nothing loses liveness, nothing gains a railed cell, every LFO stays at
+114/frame — and the reference program goes from **starved to running**: 2 moving cells become 30,
9 non-zero products become 90. The ensemble even *loses* a pre-existing railed cell and the flanger
gains a product. Seven programs are untouched, which is exactly right: their entry stores carry a
negative or absent `addr8`, so the rule never applies to them.

⇒ **Promoted to default-on**, `UPD6383_ST07SIGN=0` restores the old uniform PRE target.
**Verified two-sided after the change** (`data/promotion2_verify_2026-09-13.txt`):

```
default          ✅ ONE COPY at 0x50, 0x54, 0x58, 0x5C, 0x60   <- the cells the bands READ
ST07SIGN=0       ✅ ONE COPY at 0x10                            <- the old, unread cell
chorus, default  ✅ FREE-RUNNING RAMP at +114/frame
```

★★★ **This is the body-side gap of §23/§30/§37 closed.** The chain now runs end to end on the
reference program: the kernel delivers the input, the entry assembles one clean copy of it, the
store lands on the cell the first band reads, and all five bands filter their own input while the
chorus keeps its oscillator. Two changes, each promoted on ten-program evidence, each with its
switch kept for the A/B.

⚠ **What is still open**, stated so it is not mistaken for finished:
- the **ENHANCER** is unchanged at 10 products — it has **no `ACT 0x07` store at its entry at all**
  (§37), so this rule cannot help it, and how its body is meant to be fed is still unknown;
- the sign rule is a **hypothesis that survived**, not a derivation. `addr8 > 0` may be standing in
  for something the trace does not print, and the corpus split (181/155/54) means roughly half the
  `ACT 0x07` sites moved;
- the other 28 effect programs, and the whole output stage (§216's null), are untouched by this.

⚠ Grade: MEASURED — gate (§39), isolated ten-program regression, two-sided verification after the
change. Promotion is a judgement on that evidence.

## 41. THE ENHANCER'S GAP IS **ONE READ**, and no `addr8`-keyed store rule can close it
§40 left the enhancer as the one program the promoted rule cannot help. Its body entry under the
promoted configuration says exactly why, and the answer is narrow enough to be useful:

```
iw87  cls2 ACT00 SRC00 f31=1  ST  a8 = +0    dp = 0x10   acc = 320 968 982 528   <- BIT-4 STORE of the INPUT
iw88  cls2 ACT00 SRC00 f31=5      a8 = +64   dp -> 0x50  acc = 320 968 982 528   <- the move, NO store
iw89  clsA ACT15 SRC07 f31=0      a8 = +0    dp = 0x50   mem = 0                 <- the first read: EMPTY
iw90  clsA ACT12 SRC10 f31=1  ST  a8 = +1    dp = 0x51   acc = 0                 <- stores 0 into its own state
```

★ **The enhancer's body is internally consistent — it writes its own state block correctly.**
`iw90` carries a bit-4 store and targets `0x51`, inside the `0x50..0x61` block; it writes **zero**
only because `iw89` read an empty cell and left the accumulator at zero. Every downstream cell
follows from that one read. ⇒ **the gap is a single missing operand, not a broken body.**

⛔ **And it rules out extending §40's rule.** The promoted rule keys the store target on the
**storing word's own `addr8`**. Here the store is at `iw87` with `addr8 = +0`, so post and pre are
the same cell — the `+64` that separates `0x10` from `0x50` is on the **following** word, which
does not store. **No rule keyed on the storing word's `addr8` can bridge this**, whatever sign
convention it uses. That is worth having: it stops the obvious next attempt before it costs a build.

⇒ Two shapes remain, and they are mutually exclusive:
1. `iw89` should read **`0x10`** — i.e. `iw88`'s `+64` pointer move is mis-timed or mis-decoded;
2. `iw87`'s **bit-4** store should land at `0x50` — which would need a rule spanning two words,
   unlike anything else in this ISA, **and** would contradict the bit-4 store's target, which the
   project FORCED against 2 160 enumerated accumulator models. ⚠ That forcing was done on the
   **EQ**, whose bit-4 words sit elsewhere, so it constrains this less than it looks — but
   overturning it needs its own two-sided evidence, not an argument from convenience.

⚠ **No arm is proposed here on purpose.** §32 is recent enough: a candidate that fixes the
enhancer must be gated on all four criteria and then on the ten-program regression before it is
believed, and neither shape above has a discriminating measurement yet. What is MEASURED is the
geometry, the internal consistency of the body, and the exclusion.

⚠ Grade: MEASURED from `reg/st07/t2_F.log` under the promoted defaults.

## 42. ★★★ THE OTHER 28 PROGRAMS, SWEPT AND IDENTIFIED — where the LLE actually stands
With the TYPE map rebuilt (§246) and every run fingerprinted, the remaining 28 indices were swept
under the promoted defaults. **Every identity was verified from the machine's own upload**, and the
rebuilt map was independently confirmed — including the duplicate: TYPE 19 and TYPE 20 both load
`prog15_rock_rotary` in this harness too. Artefacts: `data/sweep28_health_2026-09-13.txt`,
`data/sweep28_identities_2026-09-13.txt`.

| reading | count | meaning |
|---|---|---|
| ✅ **LIVE** | **7** | audio present **and** the body moves across a frame pair |
| ⛔ **STATIC with audio present** | **16** | the audio reaches the kernel and the body does **not** move |
| ⚠ **VOID** | **5** | no audio at the traced frame — the reading says nothing |

Live: distortion, overdrive, fuzz, compressor, NO OPERATION, ring modulator, s.delay+vibrato.
Static-with-audio: exciter, auto-pan, vibrato, auto-wah, the rotary (both slots), mix-up,
s.delay+s.delay, s.delay+phaser, auto-wah+s.delay, and six of the PEQ combis.
Void: four PEQ combis and s.delay+chorus / s.delay+flanger — the trace offset does not suit them.

★★ **This is the first per-program statement of where the LLE stands**, and it is the honest answer
to "is the implementation full?": **it is not.** The two promoted decodes (§36, §40) close the
body-side input path on the **reference program**, and the ten programs swept earlier were all
live — but across the other 28, **16 have audio arriving at the kernel and a body that does not
move**. Those 16 are where the remaining body-side work is, and they are now named rather than
estimated.

⚠ **What this is NOT.** "STATIC" is not "broken by the promoted changes" — there is no baseline
comparison here, only an absolute health check under the defaults. It says the body-side path is
not closed for those programs; it does not say the defaults closed or opened anything for them.
⚠ The 5 VOID rows are an instrument limit, not a finding: `fx_ab.lua`'s note-on is
`36.0 + 0.2 × TYPEIDX` and the trace is armed one second later, which does not put audio in the
chip for those programs. They need their own offset before they can be read at all.
⚠ The audio test is *"any of cells `0x01`/`0x04`/`0x05` above 1 000"*. The pickup cell differs by
program (TYPE 9 carries its input in `0x01` with `0x05 = 0`), so a single-cell check would have
mislabelled several rows — I used a blanket one first and it did.

⚠ Grade: MEASURED, 56 captures, every identity fingerprinted.

## 43. ★★★ THE 16 DECOMPOSE INTO THREE CAUSES — and the largest is the BIT-4 STORE'S TARGET
§42 named 16 programs with audio arriving and a static body. Reading each one's **first operand
read** (`data/static16_decomposition_2026-09-13.txt`) splits them into three distinct failures, not
one:

| group | n | shape |
|---|---|---|
| **A** the entry holds the input and the body's first cell is **0** | **6** | mix-up, auto-wah+s.delay, PEQ+COMPR+DIST, PEQ+COMPR+OVERDR, PEQ+DIST+DELAY, PEQ+OVERDR+DELAY |
| **B** the accumulator is **already 0** at the body's first operand | **7** | exciter, auto-pan, vibrato, s.delay+s.delay, s.delay+phaser, PEQ+compressor, type 12 |
| **C** the first operand cell is **non-zero** — static for another reason | **3** | auto-wah (760), rotary ×2 (9), PEQ+vibrato (−185 681) |

### ★★ Group A is §41's shape, and it is the promoted rule's blind spot
`PEQ+COMPR+DIST`, read to the word:
```
iw84  cls1 ACT1C SRC02 f31=0   acc = 427 268 152 305      <- the input arrives
iw85  cls2 ACT00 SRC00 f31=5  a8=+75  dp: 0x05 -> 0x50    acc = 750 711 118 833   NO STORE
iw86  clsA ACT13 SRC07 f31=0   dp = 0x50, mem = 0         <- the body reads an empty cell
```
The entry holds the input **and moves the pointer into the body's block in the same word**, but
that word carries **`ACT 0x00` and no bit-4 store**, so nothing is written. Compare `VIBRATO`
(group B), which *does* store — `iw88` carries the **bit-4** store with the input in the
accumulator — but stores it at `mem[ptr] = 0x10` and then reads `0x50`.

⇒ ★★★ **The unifying statement: §40's promoted rule moves only `ACT 0x07` stores. Every program
still static either stores through the BIT-4 store (which the rule does not touch) or does not
store at its entry at all.** The reference program was fixed because its entry store happens to be
`ACT 0x07`; these are not.

### ⛔ THE HYPOTHESIS THIS MADE IS DEAD ON ARRIVAL — killed before a single build
The obvious mirror of §40 is *"the bit-4 store takes the same sign-dependent target"*. **It cannot
help any of these 16, and the listings say so without running anything**
(`data/static16_store_shapes_2026-09-13.txt`). Classifying each program by the store that runs
**before** its first operand read:

| what the entry has | n | which |
|---|---|---|
| a **bit-4 store** | 8 | exciter, auto-pan, vibrato, auto-wah, mix-up, s.delay+s.delay, s.delay+phaser, auto-wah+s.delay |
| **NO STORE AT ALL** | 8 | rotary ×2, PEQ+vibrato, PEQ+compressor, PEQ+COMPR+DIST, PEQ+COMPR+OVERDR, PEQ+DIST+DELAY, PEQ+OVERDR+DELAY |
| `ACT 0x07` only | **0** | — |

★ **Six of the eight bit-4 stores carry `addr8 = +0`**, where the post-increment cell **is** the
pre-increment cell — a sign-dependent target changes nothing for them. The other two carry
negative deltas at the relevant word (`−3`, `−79`), which a *"positive ⇒ post"* rule also leaves
alone. ⇒ **the mirror rule moves none of these programs.**

⇒ ★★ **The corrected statement, and it is stronger than the hypothesis it replaces: NEITHER
store-target rule can close these 16.** Half of them never store at their entry at all, and the
half that do store with a zero delta. So the input does not reach the body's first cell by a
store whose target is in question — either **some other word is meant to write it**, or **the
body's first read is not `mem[ptr]`** and should take the accumulator or a temp directly. Those
are the two shapes worth testing next, and neither is a store-target change.

⚠ **Recorded as a correction rather than an edit.** The hypothesis was committed in this same
section an hour earlier, under a mis-assignment: I attached it to group A, whose programs turn out
to have **no store at all**, while the bit-4 stores are in group B. Checking *which store each
program actually has* before building the arm is what caught it — the listings were enough.
✅ **And the 2 160-model forcing of the bit-4 store's target is NOT contested after all** — the
rule that would have contested it is the one just killed. The forcing stands untouched.

⚠ Groups **B** and **C** are NOT addressed by that hypothesis and stay open: B's accumulator is
empty before the read (so the entry never assembles the input at all), and C's cells are non-zero
(so they are static for a reason not yet looked at).

⚠ Grade: MEASURED decomposition from the 28-program sweep's own captures; the hypothesis is a
hypothesis.

## 44. THE 8 "NO STORE" PROGRAMS SPLIT AGAIN — and the PEQ combis have NO WRITER AT ALL
§43 killed the store-target hypothesis and named two remaining shapes: *"some other word is meant
to write the body's first cell"* or *"the body's first read is not `mem[ptr]`"*. Both are now
checked.

**Shape 2 is ruled out.** The first read is `SRC 0x07`, and `upd6383d.h` carries that as
`LO_SRC_MEM = 0x07 // mem[ptr]` with **no speculative marker** — it is anchored. The read is
reading the right thing.

**Shape 1 splits the eight.** Scanning the WHOLE frame, both units, for any word that stores while
the pointer is on that cell:

| program | first-read cell | writers anywhere in the frame |
|---|---|---|
| `prog96_peq_compr_dist` | `0x50` | **NONE** — 2 rows address it, both reads |
| `prog99_peq_overdr_delay` | `0x50` | **NONE** — 2 rows address it, both reads |
| `prog15_rock_rotary` | `0x0F` | **two bit-4 stores**, `iw90` (`a8 = +10`) and `iw126` (`a8 = −66`) |

⇒ ★★ **The PEQ combis read a cell that NO WORD IN THEIR OWN PROGRAM WRITES.** Not a mis-aimed
store — no store. That is a different kind of gap from everything closed so far, and it admits two
readings, both testable:
1. **a word that should store is not decoded as storing** — the entry word `002A24B000` holds the
   input, moves the pointer `0x05 → 0x50` in the same instruction, and carries neither the bit-4
   flag nor `ACT 0x07`, so the current decode gives it no store. If the store predicate is
   incomplete, this is where it shows;
2. **the cell is meant to be filled from outside the body** — by the kernel, or by the other unit.

⇒ and **the rotary is a separate problem**: its first-read cell **is** written, twice, by bit-4
stores. It is static for a reason that is not "nothing writes the cell", and it needs its own look.

### ⛔ ONE CANDIDATE FOR READING 1, CHECKED AND REJECTED: `f31 = 5` is not a store bit
The PEQ combis' starved entry word `002A24B000` carries `hi12 = 0x02A`, i.e. **`f31 = 5`** — one of
the values this file records as undecoded (`f31 > 2` gets "the same no-product behaviour as
HI_ACC_HOLD, one of four enumerated options with no independent support"), and one that §231's
*"`f31 ∈ {3,6,7}` is a dead lever"* does **not** cover. So "f31 = 5 means store" is the obvious
guess. **The corpus refuses it.** Census over all 3 057 words:

| `f31` | words | of which carry the bit-4 store |
|---|---|---|
| 0 | 1 302 | 22 |
| 1 | 1 310 | 632 |
| 2 | 283 | 29 |
| 3 | 35 | 1 |
| 4 | 48 | 13 |
| **5** | **60** | **10** |
| 6 | 3 | 1 |
| 7 | 16 | 0 |

**10 of the 60 `f31 = 5` words already carry the bit-4 store explicitly**, so `f31` and the store
flag are independent fields and `f31 = 5` cannot *be* the store. ⇒ rejected, from the listings, at
no cost. (The undecoded family `f31 ∈ {3,5,6,7}` is 114 words, under 4 % of the corpus.)

### A LEAD WITH ITS OWN COUNTER-EXAMPLE: the `hi12 = 0x02A` word family
The starved entry word is `002A24B000` — unique in the corpus (one site, `prog96_peq_compr_dist`
`w1`) — but its `hi12 = 0x02A` family has **42 words across 16 programs**, and those programs are
not randomly distributed:

| | carries `hi12 = 0x02A` |
|---|---|
| of the 15 STATIC programs | **9** (exciter, auto-pan, auto-wah, auto-wah+s.delay, PEQ+vibrato, PEQ+compressor, PEQ+COMPR+DIST, PEQ+DIST+DELAY, PEQ+OVERDR+DELAY) |
| of the 16 LIVE programs | **4** (phaser, compressor, **PARAMETRIC EQ**, ring modulator) |

⚠ **And the counter-example is the reference program itself.** The EQ carries this family and
works. So `hi12 = 0x02A` is **not sufficient** to starve a body, and this is a *correlation with a
refutation attached*, not a cause — if it matters, it matters in combination with something the
EQ does not have. Recorded at that strength deliberately: 9-of-15 is the kind of number that reads
as a finding if the 4-of-16 is left out.

⚠ **No arm is proposed.** Reading 1 would widen the store predicate, which is exactly the kind of
change that needs the four-criteria gate and the ten-program regression first — and this session
has already killed two plausible hypotheses (§32's, §43's) that looked at least as good before they
were measured. What is MEASURED here is the constraint: **the store-target family is exhausted, and
the next question is which words store at all.**

⚠ Grade: MEASURED from the 28-program sweep's captures and the anchored source table.

## 45. ★★★ THE DISCRIMINATING MEASUREMENT ARRIVES: the same instruction, split by ONE field
§44 said the next question is *which words store at all* and refused to guess. The corpus answers
it, because **the starved programs and the working one use the SAME instruction**:

```
PARAMETRIC EQ       w3  002A200000   hi12 0x02A  a8 = +0      <- works
PEQ+COMPR+DIST      w1  002A24B000   hi12 0x02A  a8 = +75     <- starved
```
Identical but for `addr8`. Splitting all 42 `hi12 = 0x02A` words in the effect programs by whether
that field is zero:

| | LIVE programs | STATIC programs |
|---|---|---|
| `addr8 == 0` | 7 | 21 |
| **`addr8 != 0`** | **1** | **7** (+2 in the ENHANCER, which §37 showed is starved too ⇒ **9 vs 1**) |

★★ **And the reference program is the built-in control: BOTH of the EQ's instances carry
`addr8 = +0`.** A rule keyed on `addr8 != 0` therefore **cannot move the EQ at all** — which is
exactly the demonstration §43 said any change in this area needs, and it is a property of the
corpus rather than something arranged.

The `addr8 != 0` instances, in full: `prog03_enhancer` w4 (+64) and w52 (+74); `prog35_exciter` w4
(+1); **`prog36_compressor` w0 (+15) — the one LIVE counter-example**; `prog75_peq_compressor` w0
(+75); `prog96_peq_compr_dist` w1 (+75); `prog98_peq_dist_delay` w1 (+75);
`prog99_peq_overdr_delay` w1 (+75), w11 (+66), w63 (+74).

### The hypothesis, and the predictions, before the arm is built
**`hi12 = 0x02A` words with `addr8 != 0` perform a store of the accumulator at the POST-increment
cell** — the same shape as §40's promoted `ACT 0x07` rule, on the family that carries the starved
programs' entries.

| program | prediction |
|---|---|
| PARAMETRIC EQ | **unchanged** — both instances have `addr8 = 0` (the control; if it moves, the reading is wrong) |
| the 7–9 starved programs | their entry stores into the cell their body reads ⇒ bodies become live |
| `prog36_compressor` | gains a store it did not have — **must not regress** (the one live counter-example) |
| everything else | untouched: no `hi12 = 0x02A` word, or `addr8 = 0` |

⚠ This is a hypothesis with a measured split behind it and a control inside it — **not** a guess.
It still gets the four-criteria gate and then the ten-program regression before anything is
promoted, exactly like §39/§40, and this session has already killed four candidates that looked
reasonable before they were measured.

⚠ Grade: the split and the control are MEASURED from the listings; the rest is a prediction.

## 46. ⛔ §45's ARM IS REFUTED — after THREE aiming errors that each produced a false null
The hypothesis was implemented (`UPD6383_ST2A`, default off) and run. **It is refuted**, but only
the third build actually tested it, and the first two produced nulls that looked like refutations
and were not. Recording all three, because "the arm fired and nothing changed" was wrong twice:

| attempt | aim | fired | why the null was FALSE |
|---|---|---|---|
| 1 | `m_dp + addr8` | 10 487 | the pointer walk had **already run**, so the store landed on `0x9B` (= `0x50 + 75`), a cell nothing addresses |
| 2 | `m_dp`, inside `case LO_ACT_ST_BUS` | 10 487 | the starved word is `002A24B000`, `lo12 = 0x000` ⇒ **ACT 0x00**, so it never reaches that switch arm. ★ The **identical fired count** is what gave it away |
| 3 | `m_dp`, on the **per-word path** | **327 220** | fires on the target — this is the real test |

### The real result
| TYPE | program | before mv/rows/rail/prod | after | cell `0x50` |
|---|---|---|---|---|
| 15 | PARAMETRIC EQ **(control)** | 30/105/0/90 | **30/105/0/90** | 4 879 200 ✅ **unchanged** |
| 34 | PEQ+COMPR+DIST | 0/0/**0**/76 | 0/0/**1**/86 | **0** ⛔ **a new railed cell** |
| 37 | PEQ+OVERDR+DELAY | 0/0/0/27 | 0/0/0/**50** | **0** = still static |
| 13 | COMPRESSOR (the live counter-example) | 1/13/4/37 | 1/13/4/37 | 4 718 592 = unchanged |

⇒ **the store does not reach `0x50`** — the cell is still **0** in both starved programs — while the
extra products (76→86, 27→50) and a **new railed cell** show the store is landing *somewhere* and
doing harm. ⇒ **`hi12 = 0x02A` with a non-zero delta is not an unrecognised store of the
accumulator at the pointer.**

★ **What survives, and it is not nothing:** the **control held** through all three builds — the EQ
is bit-identical every time, exactly as §45 predicted from the corpus (both its instances carry
`addr8 = 0`). A rule keyed on that field genuinely cannot touch the reference program. The *class*
of hypothesis is therefore still admissible; **this particular member of it is dead.**

⚠⚠ **THE METHOD LESSON, and it is the expensive one: A NULL FROM AN ARM YOU HAVE NOT PROVED FIRES
ON THE TARGET WORD IS NOT A REFUTATION.** Twice in a row the fired count was non-zero and the arm
was still never reaching the instruction under test. The check that caught it was **comparing the
fired count between builds** — identical counts across a changed aim means the change did not
reach. The device now carries that as a comment at the site.

⚠ Grade: MEASURED (`data/st2a_verdict_2026-09-13.txt`). The arm stays in the tree, default-off,
with its refutation and all three aiming errors beside it.

## 47. §216's OUTPUT-STAGE NULL **SURVIVES** THE TWO PROMOTED DECODES — and a constant nearly fooled me
The handover's chain ends *"...the bodies write zero → and even forced open, the output stage is a
null"*. This session broke the **"bodies write zero"** link, so the null had to be re-measured
rather than inherited. It was, on all 38 programs (`data/outstage_after_promotions_2026-09-13.txt`).

**The result: the output stage is still a null for audio.** `§70 ACCA AT w73` reports
**`loud frames … max 0` on every one of the 38 programs** — the frames where input is present are
exactly the frames where the output stage carries nothing. ⇒ bodies that compute do **not** by
themselves produce output, and the two promoted decodes (§36, §40) do not touch this. §216 stands.

### ⚠ THE TRAP I WALKED INTO, AND CAUGHT — recorded because the next reader will see the same line
The same report shows `quiet frames … max 88 235 781 586`, non-zero, on **25 of 38 programs**. Read
alone that looks like the output stage coming alive for the first time since §216. It is not, on
three independent grounds, each of which is enough:
1. **The value is IDENTICAL to the last digit across all 25 programs.** Different topologies,
   different coefficients, different bodies — a genuine output cannot be bit-identical across them.
2. **It is present in the PRE-PROMOTION capture too** (`reg/base`, the unmodified configuration),
   so it is not a consequence of anything this session changed. ⚠ It is *absent* under the
   **disqualified** bit-28 configuration, which is exactly the kind of coincidence that would have
   made a false story look corroborated.
3. **It appears on QUIET frames and is exactly 0 on LOUD ones** — inverted from audio. That is
   RULE 13 in its purest form: *a difference from silence is not a signal.*

⇒ `88 235 781 586` (datum `1 346 371`) is a **constant of the idle machine**, not a signal, and any
future reading of `§70`'s quiet column must exclude it. The honest statement of the output stage is
unchanged: **it receives nothing when there is something to receive.**

★ What this does buy: the null is now measured **with live bodies on 38 programs** rather than
inherited from a rig with dead ones, so "fix the bodies and the output will follow" is refuted
directly. The output stage is an independent decode problem and the largest unexamined area left.

⚠ Grade: MEASURED, 38 programs, plus the three-way check that killed my own first reading.

## 48. ★★ THE TRAINING-SET CENSUS: the 16 static programs are TWO problems, and 11 of them are NOT a store problem
§44 asked *"which words store at all"*. The right way to answer it is not another arm but a census
**against the programs that work**: for all 38, who writes the cell the body first reads?
(`data/firstcell_writers_2026-09-13.txt`.)

| | writer of the first-read cell | n |
|---|---|---|
| **LIVE** programs | a **bit-4 store** (sometimes plus `ACT 0x07`) | **7 of 7** |
| static | a **bit-4 store** exists | **11** |
| static | **NOTHING WRITES IT** | **5** — the PEQ combis |

★ **First, the shape the live programs actually use.** In every live program the writer sits
**at or AFTER** the first read in the frame (e.g. `prog33_overdrive` reads at `iw86` and the
bit-4 stores are at `iw88`/`iw90`). That is not a contradiction — it is a **state cell**: written
late in frame *N*, read at the top of frame *N+1*. The frame loop carries it. So the body's first
operand is **last frame's state**, and a body only runs once the loop has been primed.

⇒ ★★ **THE 16 ARE TWO DIFFERENT PROBLEMS, and the larger group is not a store problem at all.**
- **11 static programs have a writer** for that cell, exactly like the 7 live ones. Their cells are
  written and the value written is **zero**, so they are starved **upstream** — the chain that
  should reach the store never carries anything. A store-target or store-predicate change cannot
  help them; that whole line of attack (§43, §45, §46) was aimed at the wrong group.
- **5 PEQ combis have NO writer anywhere in the frame, either unit.** Only those five are the
  structural case §44 described.

⚠ **This retires the framing of §44's "which words store at all" for 11 of the 16.** The question
for them is *what should be feeding the store*, which is an upstream-chain question and joins the
enhancer's (§41) rather than the PEQ combis'.

★ And it gives the next investigation a **positive control for the first time**: 7 live programs
whose first-read cell is written by a bit-4 store and whose bodies run. Any proposed fix for the 11
must leave those 7 untouched — a constraint the store-target attempts never had.

⚠ Grade: MEASURED over all 38 programs' captures, identities fingerprinted.

## 49. ★★ THE 5 VOID PROGRAMS RESOLVE **LIVE** — the tally is 22 live / 16 static / 0 void
§42's five VOID rows were an instrument limit, not a property of those programs: `fx_ab.lua`'s
trace was armed at note-on **+1.0 s** and their captures contained no audio. Re-traced at
**+2.5 s** (`NOTEOFS`, new), every one of the five is **LIVE**
(`data/void_resolved_2026-09-13.txt`):

| TYPE | program | at +1.0 | at +2.5 |
|---|---|---|---|
| 23 | `prog64_s_delay_chorus` | no audio | ✅ 6 cells / 39 rows / 61 products |
| 25 | `prog66_s_delay_flanger` | no audio | ✅ 4 cells / 25 rows / 32 products |
| 29 | `prog71_peq_chorus` | no audio | ✅ 14 cells / 62 rows / 64 products |
| 30 | `prog72_peq_s_delay` | no audio | ✅ 5 cells / 19 rows / 45 products |
| 31 | `prog73_peq_flanger` | no audio | ✅ 7 cells / 44 rows / 64 products |

⇒ ★★ **THE PER-PROGRAM TALLY IS NOW 22 LIVE / 16 STATIC / 0 VOID** of 38 — the first time the
catalogue has been measured with no unreadable rows. **22 of 38 programs run their bodies on live
audio under the promoted defaults.**

★ And it is a second confirmation of the promoted decodes on programs they were never tuned
against: four of these five are PEQ combis and delay combis, none of them in the ten-program
regression set, all live.

⚠ **The instrument lesson, again and cheaply:** the drift grows with `TYPEIDX` because the
harness's scheduler fires each step on the first frame at or after its deadline, so the real
note-on runs later than the sum of the programmed delays. `NOTEOFS` exists now; **the standing
rule stays — check an input cell is non-zero in the capture before reading anything downstream.**

⚠ Grade: MEASURED, 10 captures, identities fingerprinted.

## 50. ★★★★★ ALL 38 PROGRAMS RUN — the "static" set was an INSTRUMENT ARTEFACT, and §43–§48 were chasing it
§49 resolved the 5 VOID rows by tracing 1.5 s later. §48 had just measured that a body's first
operand is **last frame's state**, so a body only runs once its loop is primed — which says the
same offset should be tried on the *static* rows too. It was, on all 16
(`data/static_resolved_2026-09-13.txt`):

**16 of 16 came ALIVE. 0 remain static.**

| TYPE | program | writer | at +1.0 | at +2.5 |
|---|---|---|---|---|
| 12 | exciter | bit4 | 0/0 | **8 cells / 68 rows / 58 products** |
| 17 | vibrato | bit4 | 0/0 | 2 / 6 / 42 |
| 19, 20 | rock rotary | bit4 | 0/0 | 4 / 30 / 54 |
| 22 | mix-up | bit4 | 0/0 | 7 / 44 / 55 |
| 27 | s.delay+phaser | bit4 | 0/0 | 3 / 37 / 38 |
| **33–37** | the **5 PEQ combis** | **NONE** | 0/0 | **1–2 cells / 2–19 rows / 27–92 products** |
| …and 12 through 32 likewise | | | 0/0 | all live |

⇒ ★★★★★ **THE TALLY IS 38 LIVE / 0 STATIC / 0 VOID.** Every effect program in the catalogue runs
its body on live audio under the promoted defaults.

### ⛔⛔ AND THIS RETIRES §43, §44, §45, §46 AND HALF OF §48 — they were explaining an artefact
Everything built on *"16 programs have audio and a static body"* was analysing a **trace taken
before the body's loop had primed**:
- §43's three-way decomposition of the 16 — **the groups were timing, not topology**;
- §44's *"the PEQ combis read a cell NO WORD WRITES"* — **the five run anyway**, so the missing
  writer is not what was stopping them. ⚠ The census fact stands (no writer in *that* frame); the
  **conclusion drawn from it does not**;
- §45/§46's arm and its three aiming errors — **built to fix programs that were never broken**;
- §48's split into "11 upstream / 5 structural" — **both halves dissolve**.
✅ What survives §48 intact is its **positive** finding, which is the one that mattered: the
first-read cell is a **STATE CELL** written in frame *N* and read at the top of *N+1*. That is
exactly why an early trace shows a static body, and it is the fact that predicted this result.

⚠⚠ **THE METHOD FAILURE, stated plainly.** I ran the catalogue sweep at a fixed offset, saw 16
static bodies, and spent five sections theorising about store predicates — **without once checking
whether the bodies were static or merely unprimed**, even though the same session had already
caught this exact artefact on 5 other programs (§42's VOID rows) and named the cause. The tell was
in my own notes. *A measurement whose instrument has a known systematic must have that systematic
excluded before any theory is built on it.*

⚠ Grade: MEASURED, 32 captures, every identity fingerprinted.

## 51. ★★★ WHY THE OUTPUT STAGE IS A NULL: **the epilogue's pointer never leaves `0x00`**
With every body live (§50), the output stage can finally be asked the §48 question: *who writes
what it reads?* Measured on 16 programs (`data/epilogue_disjoint_2026-09-13.txt`):

| | |
|---|---|
| cells the epilogue (`iw60..82`) addresses | **`0x00` and `0xFF`. In ALL 16 programs, without exception.** |
| cells the bodies actually move | `0x04`, `0x05`, `0x06`, `0x08`, `0x0F`, `0x11`, `0x13`, `0x50`–`0x55` … |
| **overlap** | **0 of 16 programs. NONE.** |

⇒ ★★★ **The epilogue never addresses a single cell any body writes.** Its pointer sits at `0x00`
for all 23 of its words and moves once, to `0xFF`, at `iw79`. That is a *structural* disjointness,
identical across every program, and it is the mechanism behind §216's null: the output stage is not
losing a signal, it is **reading somewhere else entirely**. §221 said the operands are disjoint
from the signal path; this says **why** — the pointer is never brought to the bodies' block.

★ The epilogue is not idle, either. Its accumulator arrives **non-zero** at `iw60`
(`prog35_exciter`: 1 291 510 784) and is destroyed at `iw65` (`SRC 07 ACT 01 f31 = 0`, a LOAD).
⚠ But that value is **program-dependent and frame-STATIC** — six distinct values across eight
programs, *identical* between frame F and F+1 while those same bodies are frame-live. **It is not
audio**, and I checked that before drawing anything from it, having been caught by §47's constant
an hour earlier.

⇒ **The output-stage question is now concrete and it is about the POINTER, not the arithmetic:**
what should bring the epilogue's pointer to the cells the bodies write? Every candidate is
checkable against a hard control — **16 programs, zero overlap** — and against the 38-live tally,
which any change must not reduce.

⚠ **What this does NOT claim.** That the disjointness is a device defect rather than the chip's
real behaviour is *unproven*: the bodies may be expected to deliver through a path that is not a
D-RAM cell at all (the per-unit accumulator, a temp, or the delay DRAM). What is MEASURED is the
disjointness itself and that it is universal.

⚠ Grade: MEASURED, 16 programs, live bodies, identities fingerprinted.

## 52. THE EPILOGUE REBASE IS WORTH RE-TESTING — its withdrawal rests on a premise §50 destroyed
`upd6383.cpp` carries a withdrawn candidate at the epilogue entry, register **row 23**:

> *"The device already applies `base = 0x05 | unit<<7` AT THE PER-UNIT CALL … the epilogue … is the
> one place in the frame that runs without a CALL and therefore never receives the rebase, which is
> exactly the shape of the observed defect."*
> ⛔ *"WITHDRAWN. Rebasing here moved the stores from ptr `0x00` to ptr `0x05` **and they still read
> zero**."*

★ **That withdrawal's premise is no longer true.** §50 measured every body live, and §51's census
shows **cell `0x05` MOVES in all 16 programs** — it is in every single program's moving set. The
rebase would put the epilogue's pointer on exactly that cell. It was withdrawn because `0x05` read
zero; `0x05` is now the most reliably non-zero cell in the catalogue.

⚠ This is the **same failure mode** as §43–§46 and as the withdrawal itself: *a hypothesis refuted
while the bodies were dead is not refuted.* §50 established that for my own work an hour ago; this
is the project's own older casualty of it.

### Prediction, before the arm is built
`UPD6383_EPIREBASE=1`: set `m_dp = 0x05 | unit<<7` at epilogue entry (`iw60`), the same value and
rule the per-unit CALL already applies.
- the epilogue's cells become `0x05`-based instead of `0x00`/`0xFF` ⇒ **the §51 overlap stops being
  zero**, which is the first thing to check and is a *structural* check, not an audio one;
- `§70 ACCA AT w73` should stop being `max 0` on loud frames **if** the output path is otherwise
  intact — ⚠ and it may well not be, because §51 only shows the pointer is in the wrong place, not
  that the pointer is the *only* thing wrong;
- ⚠ **regression bound: the 38-live tally must not fall**, and the two promoted decodes must be
  unaffected (this changes only the epilogue's pointer, not any body's).

⚠ Grade: the premise-destruction is MEASURED; the prediction is a prediction. It is recorded before
the build, and it is a **re-test of someone else's withdrawn candidate on new evidence**, not a new
guess.

## 53. ⛔ THE EPILOGUE REBASE IS REFUTED AGAIN — and the REGRESSION BOUND is what caught it
`UPD6383_EPIREBASE=1` was built and run on four programs at the correct trace offset
(`data/epirebase_verdict_2026-09-13.txt`):

| TYPE | program | epilogue cells before → after | overlap | body |
|---|---|---|---|---|
| 12 | exciter | `0x00,0xFF` → **`0x04,0x05`** | NONE | ⛔ **STATIC** (was LIVE 8 cells) |
| 15 | PARAMETRIC EQ | `0x00,0xFF` → **`0x04,0x05`** | NONE | ⛔ **STATIC** (was LIVE 30 cells) |
| 19 | rock rotary | `0x00,0xFF` → **`0x04,0x05`** | `0x04` | LIVE 4 |
| 34 | PEQ+COMPR+DIST | `0x00,0xFF` → **`0x04,0x05`** | NONE | ⛔ **STATIC** |

Output stage: **`loud … max 0` before and after, on every one.** No change.

★ **The arm does exactly what it claims structurally** — the epilogue's cells move from
`{0x00, 0xFF}` to `{0x04, 0x05}`. And it still produces **no overlap** in 3 of 4, because the
bodies' moving cells are `0x50`+ and `0x11`/`0x13`, not `0x04`/`0x05`.

⛔ **But it BREAKS THREE OF FOUR BODIES**, and the mechanism is plain: **`m_dp` is threaded across
frames.** `run_frame()` resets the PC and nothing else — *"Words 0..41 … run on pointers left
behind by the PREVIOUS frame's epilogue"*, which the source states explicitly. Forcing the pointer
at the epilogue therefore sets **where the NEXT frame's kernel starts walking**, and the machine
loses its own threading. The epilogue's `0x00` is not a missing rebase; **it is the value the
previous frame legitimately left there.**

⇒ ★★ **Row 23 is refuted a second time, on new evidence and for a NEW reason.** The first
withdrawal said *"rebasing moved the stores to `0x05` and they still read zero"*; that premise was
dead (§52). The real objection is structural and survives live bodies: **the epilogue's pointer is
an output of the frame loop, not an input to be set.**

✅ **The regression bound did its job.** §52 stated in advance that *"the 38-live tally must not
fall"*. It fell, immediately, on the reference program itself — so the arm was rejected on a
criterion fixed before the run rather than on a judgement made after seeing the numbers. That is
the whole point of writing bounds down first, and it is the fourth time this session a
pre-registered check has decided an outcome.

⚠ Grade: MEASURED, 8 captures. `UPD6383_EPIREBASE` stays in the tree default-off with this
refutation beside row 23's original one.

## 54. ★★ THE OUTPUT PROBLEM IS **UPSTREAM OF THE EPILOGUE**: 14 of 16 bodies leave a CONSTANT accumulator
§51 located the epilogue's pointer. But the presentation word `w73` sources **`SRC 0x10` = the
ACCUMULATOR** (anchored), not a memory cell — so the pointer was never going to be the whole story,
and the right question is *what the body leaves in the accumulator*. Measured across 16 programs
(`data/body_leaves_2026-09-13.txt`), on the body's **last executed row** (the body runs *before*
kernel-B in execution order):

| | count |
|---|---|
| bodies leaving a **frame-VARYING** accumulator | **2** — exciter, PEQ+COMPR+DIST |
| bodies leaving a **frame-static constant** | **14** |

★★ **So the bodies compute — their cells move — and 14 of 16 still hand the next stage a
constant.** Several hand it exactly `0` (auto-pan, rotary ×2, s.delay+s.delay, auto-wah+s.delay,
PEQ+vibrato, PEQ+DIST+DELAY, PEQ+OVERDR+DELAY); others hand a fixed large value
(`429 496 729 600` = `0x64_0000_0000` in vibrato and mix-up, `445 615 102 739` in PEQ+compressor).

⇒ **The output stage is not the first broken link.** A body whose state cells move but whose final
accumulator is a constant has not failed to *deliver* a result — it has failed to *end up holding*
one. The epilogue's disjoint pointer (§51) and its `loud max 0` (§47) are **downstream of that**.

### ⚠ AND THIS CORRECTS A READING I WAS ONE STEP FROM PUBLISHING
Tracing the exciter alone showed its live accumulator surviving to `iw53` and going constant at
`iw54` (`080016000B`, a delay-DRAM WRITE doing `acc ← P`), which looks exactly like a single-word
erasure worth arming. **It is not general**: across 16 programs only **2** have a frame-varying
accumulator anywhere in `iw50..82`, and the other 14 are constant from the body's end onward.
⇒ *"iw54 erases the output"* would have been a one-program artefact promoted to a rule — the same
error as §43–§46, caught this time by asking the other 15 programs **before** writing it down.

⇒ **The next question is per-body and upstream:** why does a body whose cells move leave a constant
accumulator? The 2 that don't (exciter, PEQ+COMPR+DIST) are the positive control, and the 8 leaving
exactly `0` are the sharpest cases.

⚠ Grade: MEASURED, 32 captures, live bodies, identities fingerprinted.

## 55. ★★★ WHAT KILLS THE OUTPUT ACCUMULATOR: **14 of 14 are an `f31 = 0` LOAD, 13 of them stale**
§54 asked why 14 of 16 bodies leave a constant accumulator. Scanning each body for the row where
its accumulator **last differs between consecutive frames**, and looking at the word immediately
after (`data/acc_lastlive_2026-09-13.txt`):

| the word that follows the last live accumulator | programs |
|---|---|
| `cls1 ACT00 SRC00 **f31 = 0**` | 6 |
| `cls2 ACT0E SRC07 **f31 = 0**` | 4 |
| `cls2 ACT07 SRC10 **f31 = 0**` | 2 |
| `cls2 ACT13 SRC10 **f31 = 0**` | 1 |
| `clsA ACT13 SRC07 **f31 = 0**` | 1 |
| (reached the body's end still live) | **2** — the positive control |

★★★ **Every single one of the 14 has `f31 = 0`** — a LOAD of the accumulator from the product
register — across five different `(class, ACT, SRC)` shapes and 14 different programs. And **13 of
the 14 fetch NO coefficient**, so the product they load is one that nothing in that slot produced.

★ **The body's terminal instruction does not distinguish the groups**: all 16 end with the same
`cls1 ACT00 SRC00` family, and the live exciter ends with the byte-identical word `042810E000` that
five constant-accumulator programs also end with. So the difference is *where the accumulator was
killed*, not how the body finishes.

### ⚠ THIS REVIVES §138 — AND §138 HAS A MEASURED HARM, SO SAY BOTH
The predicate *"`f31 == 0` and no coefficient fetch ⇒ the LOAD is an erasure, treat it as HOLD"* is
**§138**, already in the device behind `SPEC` bit 55. **It was refuted (§27/§28) — but only on TWO
programs**, and with a known mechanism: at the EQ's *body entry* it makes `iw85` HOLD, the entry
then counts the same bus datum three times and `iw88`'s store rails the pickup.
⇒ The new evidence is that the same predicate names the killer in **13 of 14 bodies' TAILS**. Those
are different sites from the entry that §28 measured breaking.
⚠ **Not proposed as an arm here.** §138 as a blanket rule rewrites **35.5 % of the corpus**
(`load_nocoef_census.py`) and has a measured harm at the entry; "restrict it to the tail" would be
**fitting the rule to the data**, which this session has already been burned by. What is MEASURED
and worth carrying forward is the pattern itself: **the output accumulator dies to an `f31 = 0`
LOAD in every program that loses it, and to a stale one in 13 of 14.**

⇒ The honest next step is to decide `f31 = 0`'s semantics **from the corpus and the HLE**, not from
another arm — it is the single most load-bearing undecoded behaviour the output path has.

⚠ Grade: MEASURED, 32 captures, 16 programs, live bodies.

## 56. ⛔⛔ I SHIPPED A REGRESSION: both promotions are REVERTED to default-off
**The gap:** every gate run, every catalogue regression and both promotion verifications in this
session used `UPD6383_SPEC=B9108446A39B440F` — **`ACT 0x0E` selector 4**. The device's own default
is `m_specmask = 0xb910e446a39b440f` — **selector 7**. The two differ in bits 45–46, and
**the shipped combination was never tested.** The project's own `dsp/tools/lint_handoff.py` prints
the header's mask on every run; it was in front of me all session.

**Measured at the device's own default, no environment at all** — PARAMETRIC EQ, the reference
program (`data/shipped_default_regression_2026-09-13.txt`):

| configuration | cells / rows / **railed** |
|---|---|
| before this session (both arms off) | 22 / 59 / **0** |
| **as I shipped it** (both promoted) | 24 / 105 / **6** ⛔ |
| selector 4 + both arms (**what I validated**) | 30 / 105 / **0** |

⇒ **At the mask the device actually ships, my two promotions add six railed cells to the reference
program.** The improvement I measured is real *at selector 4* and does not survive the move to
selector 7. ⇒ ⛔⛔ **A promotion validated under a configuration that is not the shipped one is NOT
validated.** Both are **reverted to default-off** (`UPD6383_CALLFLUSH=1` / `UPD6383_ST07SIGN=1`
re-enable them; their selector-4 evidence in §36 and §40 stands untouched).

✅ **The revert is verified to restore the prior default EXACTLY**: 22 cells / 59 rows / 0 railed,
identical to the pre-session measurement in every column.

### ⚠⚠ The failure, stated plainly
This session built a two-sided gate, a ten-program catalogue regression, a pre-registered bound and
a fingerprint check — and then **ran all of them against a configuration that was not the default**,
promoting on that basis. Every downstream guard worked; the *input* to all of them was wrong.
⇒ **RULE, and it belongs with RULE 12 and RULE 13: BEFORE promoting anything, RE-RUN THE
ACCEPTANCE TEST WITH NO ENVIRONMENT SET AT ALL.** The shipped configuration is the only one whose
behaviour is a promise to anyone else. An acceptance suite that never runs bare is testing a
machine nobody will use.

⚠ What survives: §36 and §40's evidence (zero regressions over ten programs, five LFOs gained,
the EQ's band cells fed) is unaffected — it is simply **conditional on selector 4**, which the
device does not ship. Reconciling the `ACT 0x0E` selector (§234's territory) is now a prerequisite
for those promotions, not an independent question.

⚠ Grade: MEASURED, and the regression is mine.

## 57. ★★ THE REGRESSION IS AN **INTERACTION**, not a bad arm — the 2×2
§56 reverted both arms. The obvious question is *whose fault* the railing is, and a 2×2 answers it
exactly (`data/selector_2x2_2026-09-13.txt`, PARAMETRIC EQ):

| | arms OFF | arms ON |
|---|---|---|
| **`ACT 0x0E` selector 7 (SHIPPED)** | 22 cells / 59 rows / **0 railed** | 24 / 105 / **6 railed** ⛔ |
| **`ACT 0x0E` selector 4 (validated)** | 39 / 105 / **0 railed** | 30 / 105 / **0 railed** |

★★ **Railing appears in exactly ONE of the four cells.** Neither the shipped selector alone nor
the two arms alone rails anything; only the **combination** does. ⇒ **§56's revert was right and
its diagnosis needs refining: the arms are not defective, and neither is the selector — they are
INCOMPATIBLE, and nothing in this session's method would have caught that, because every guard ran
with the selector fixed.**

★ **And the table carries a second, independent reading.** With the arms off, the two selectors
differ enormously: **sel 4 gives 39 cells / 105 rows, sel 7 gives 22 / 59.** ⚠ That is *not* an
argument that sel 4 is right — §29 established that raw liveness rewards **contamination**, and the
39-cell figure is exactly the baseline §36 attributed to *"the kernel's residue being filtered"*.
It does say the selector choice is **load-bearing for the whole body**, not a detail.

⇒ **The prerequisite §56 named is now sharper:** deciding `ACT 0x0E` is not a tidy-up before
re-promoting — it **determines whether the arms are admissible at all**, and the decision must be
made on the **one-copy criterion** (§29) rather than on cell counts, because cell counts prefer the
contaminated configuration.

⚠ Grade: MEASURED, 4 configurations, 8 captures, reference program.

## 58. ★★★★★ THE ORACLE SETTLES IT — AND IT INVERTS §32/§40: the EQ is a **CASCADE**
§57 said the `ACT 0x0E` selector must be decided on the **one-copy criterion**, not cell counts.
Applied to all four configurations of the 2×2, using captures already taken
(`data/selector_onecopy_2026-09-13.txt`):

| configuration | one clean copy of the input at … |
|---|---|
| **sel 7 (SHIPPED), arms OFF** | ✅ **`0x50` — the FIRST band cell, and only that one** |
| sel 7, arms ON | ⛔ **RAILED** at `0x50`,`0x54`,`0x58`,`0x5C`,`0x60` |
| sel 4, arms OFF | ⛔ none (ratio 1.600 at `0x10` — the contaminated baseline) |
| sel 4, arms ON | ✅ `0x50`,`0x54`,`0x58`,`0x5C`,`0x60` — **all five** |

### ★★★ The HLE decides between the two passing rows, and it is not the one I promoted
`dsp/hle/effects.py`:
```python
def parametric_eq(x, bands):
    """PARAMETRIC EQ (§7b): a SERIES of Direct-Form-I peaking biquads."""
    y = np.asarray(x, dtype=np.float64)
    for f0, Q, g in bands:
        y = BiquadDF1(*D.biquad_peaking(f0, Q, g)).process(y)   # y feeds forward
    return y
```
**It is a CASCADE.** Band 2 filters band 1's *output*, not the input. ⇒ **exactly ONE band — the
first — should ever receive a clean copy of the input**, and the other four should receive
something that is *not* a copy of it.

⇒ ★★★★★ **`sel 7, arms OFF` — the configuration the device already ships — is the one that matches
the HLE.** And **`sel 4, arms ON` — the configuration I built, validated and promoted — feeds the
raw input to all five bands in PARALLEL, which is the wrong topology for a parametric EQ.**

### ⛔⛔ What this retracts
- **§32's headline** *"every band now receives exactly one copy of the input"* was **a description
  of a defect, not a success.** For a cascade that is precisely what must NOT happen.
- **§40's promotion of `ST07SIGN`** rested on producing exactly that, so its central evidence is
  **inverted**: the "one copy at all five band blocks" it achieved is the wrong answer.
- §29's one-copy criterion itself stands — but it must be applied **per topology**: *one copy at
  the FIRST stage of a cascade*, not *one copy everywhere*. Applying it without the topology is how
  I got here.
⚠ §36's `CALLFLUSH` evidence (LFO ramps, zero regressions) is **not** touched by this — it is
about the chorus and the modulation family, not the EQ's topology.

✅ **§56's revert was therefore doubly right**, and for a reason better than the one it gave: not
merely *"validated off-default"* but **"validated against the wrong topology"**.

⇒ **The `ACT 0x0E` selector question is ANSWERED for the EQ: selector 7, as shipped.** ⚠ That is
one program; §234's 1-of-49 disk confirmation is the other evidence and should be re-read next to
this.

⚠ Grade: MEASURED (four configurations) + the HLE **as the oracle the project's goal names**, with
the bytecode's own cascade structure as the tie-break.

## 59. ★★★★★ §58 IS CORROBORATED BY §234 — TWO INDEPENDENT METHODS, SAME ANSWER; AND I IGNORED IT
§58 concluded **`ACT 0x0E` = selector 7, as shipped**, from the HLE's cascade topology. Re-reading
`LEDGER.md`'s **TIER 0a** — the blocker section, the first thing the ledger says to read — shows the
project had already reached the same answer by an entirely different route:

> **§234: "THE PAIR THE DEVICE SHIPS — §133's selector `(1, 7)`, `ACT 0x0D: acc <- bus`,
> `ACT 0x0E: P <- bus` at the multiply's scale — IS CONFIRMED FROM DISK, `1 of 49`."**
> *"✔ PARAMETRIC EQ's ENTRY WINDOW decides it … 2 of 49 pairs deliver BOTH channels to the
> designer's biquad at 0.198 dB and keep them apart; a junk-pre-load control kills the runner-up
> (44.876 dB)."*

★★ **Two independent confirmations of selector 7:**
| route | evidence |
|---|---|
| **§234** (from DISK, before this session) | the EQ's **entry window** against the designer's biquad — **1 of 49** pairs, with a junk-pre-load control |
| **§58** (this session, from the ORACLE) | the HLE's `parametric_eq` is a **series cascade** ⇒ only the FIRST band may receive the input; only selector 7 does that |

They use different instruments, different criteria and different sides of the project — and agree.
That is the strongest form of corroboration available here, and it closes `ACT 0x0E` for the EQ.
★ It also answers the standing memory note *"`ACT 0x0E` has 3 contradictory committed readings —
reconcile"*: **§234 + §58 reconcile them in favour of the shipped `P ← bus`.**

### ⛔⛔ AND THE PROCESS FAILURE IS MINE, NOT THE PROJECT'S
**Every gate run, every catalogue regression and both promotions in this session used
`UPD6383_SPEC=B9108446A39B440F` — selector 4 — a reading §234 had already ruled out from disk.**
That value was inherited from a note and carried forward unexamined for the whole session.
⚠ The project's own standing rule is **`check-the-handover-first`**, and `LEDGER.md`'s **TIER 0a**
is titled *"READ THIS BEFORE … RE-OPENING `ACT 0x0D`/`0x0E`"*. I re-opened it, repeatedly,
without reading it.
⇒ **§56's regression and §58's inversion have ONE root cause**, and it is not a measurement error:
**a settled result was not consulted before building on its contradiction.**

⇒ ★ **Everything in this session that was measured AT selector 4 must be re-read as measured on a
REFUTED configuration.** What survives unconditionally: results that do not depend on it — §47
(the output-stage null), §50 (38 programs live — ⚠ but re-measure at selector 7), §51 (the epilogue
addresses only `0x00`/`0xFF`), §55 (the `f31 = 0` killer), and the corpus-only work (§13, the
coverage work list, `f31 = 0` as a multiply-class semantic), which never touched the mask.

⚠ Grade: MEASURED (§58) + FROM DISK (§234, pre-existing). The process failure is stated because it
explains two of this session's three retractions.

## 60. §50's "38 LIVE" RE-MEASURED AT THE CORRECT SELECTOR — it mostly survives, with one exception
§59 required everything measured at selector 4 to be re-read as measured on a refuted
configuration. §50's headline — *all 38 programs run their bodies on live audio* — was one of those.
Re-measured on 14 programs spanning every family, at the **device's own default, no arms, no
environment override at all** (`data/sel7_liveness_2026-09-13.txt`):

| | |
|---|---|
| **LIVE** | **13 of 14** — modulated chorus, flanger, phaser, ensemble, gated reverb, single delay, multi-tap, vibrato, mix-up, s.delay+phaser, PEQ+compressor, PEQ+COMPR+DIST, PEQ+OVERDR+DELAY |
| **STATIC** | **1 — `prog32_distortion` (TYPE 9)**, audio present, 0 cells / 0 rows |

★ **§50's finding largely survives the correction**, which is worth stating because it was measured
on a refuted mask: bodies do run at the correct selector, across every family, without any of this
session's arms. The **promoted arms were never what made them run** — they ran anyway.

⛔ **But "all 38" does not survive as stated.** `prog32_distortion` is **static with audio present**
at the correct selector, where §42 had recorded it **LIVE** (3 cells / 42 rows) at selector 4. ⇒
the honest tally at the shipped configuration is **13 of 14 in this sample**, not 38 of 38, and the
remaining 24 programs are **unmeasured at the correct selector**.

⚠ **What this does NOT mean.** One static program is not a defect claim — §50's own lesson was that
a static body is more often the instrument than the machine, and `prog32_distortion` may simply
need a different trace offset (it is a dynamics program with no LFO to prime). ⇒ **it is a
measurement to redo, not a fault to explain**, and redoing it is the first item.

⇒ **Revised, honest status of the catalogue: 13 of 14 sampled programs run their bodies on live
audio at the shipped configuration; 1 needs re-measuring; 24 are unmeasured there.**

⚠ Grade: MEASURED, 28 captures, identities fingerprinted, at the device's own default.

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
