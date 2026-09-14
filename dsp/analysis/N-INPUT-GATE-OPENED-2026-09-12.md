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

## 61. ⛔ THE DISTORTION IS GENUINELY STATIC AT THE CORRECT SELECTOR — and that is a TENSION, not a tidy-up
§60 left `prog32_distortion` as *"a measurement to redo, not a fault to explain"*, on the reasoning
that a static body is more often the instrument. **Redone at three trace offsets, it is static at
all three** (`data/t9_offsets_2026-09-13.txt`):

| offset | audio | cells / rows |
|---|---|---|
| +1.0 s | yes | 0 / 0 ⛔ |
| +2.5 s | yes | 0 / 0 ⛔ |
| +3.2 s | yes | 0 / 0 ⛔ |

⇒ **not an instrument artefact.** Audio reaches the chip at every offset and the body never moves.
⚠ My §60 hypothesis is refuted, and I am recording that rather than quietly widening the search.

### ★★ THE TENSION, STATED PLAINLY
At **selector 4** — the reading §234 and §58 both refute — `prog32_distortion` was **LIVE**
(§42: 3 cells / 42 rows). At **selector 7** — the reading two independent routes confirm — it is
**STATIC**. So:

> **The selector that is right for the PARAMETRIC EQ leaves the DISTORTION's body dead.**

That is a genuine conflict between two well-evidenced results, and it admits three readings, none
of which this session can choose between:
1. `ACT 0x0E` is **context-dependent** — selector 7 for the EQ's population, something else for the
   dynamics family. The project has precedent: `addr8` is a pointer delta in one class and a
   direction field in another, and `SRC 0x00` was just shown to partition (§7 of the work list).
2. the distortion is **blocked by something unrelated** that selector 4 happened to mask.
3. §234's 1-of-49 and §58's cascade argument are both about **the EQ**, and neither claims to be
   corpus-wide — they close `ACT 0x0E` *for that program*, which is exactly how §59 stated it.

⚠ **Reading 3 is the honest default**: both confirmations are EQ-specific by construction. ⇒ **the
claim "`ACT 0x0E` = selector 7" must be carried as *for the EQ*, not as a global decode**, and the
distortion is the first counter-population to work.

⇒ Next, and bounded: find where `prog32_distortion`'s body stops — the §55 instrument (scan for the
row where its accumulator last differs between frames) applied at selector 7 — and compare against
the same scan at selector 4, which is where it was alive.

⚠ Grade: MEASURED, 6 captures, three offsets. The §60 hypothesis it refutes was mine, made one
section earlier.

## 62. ★★ §61's TENSION DISSOLVES: the distortion's PICKUP CELL IS RAILED at the correct selector
§61 left three readings and called the EQ-specific one the honest default. The bounded scan it
named settles it instead, and the answer is neither of the exotic options
(`data/t9_scan_2026-09-13.txt`):

| configuration | acc varies in the body? | **pickup cell `0x05`** |
|---|---|---|
| **selector 7 (correct)** | **never** | **8 388 607 = `0x7FFFFF` — RAILED** |
| selector 4 (refuted) | 39 rows, live to the body's end | 0 |

★★ **The distortion's body is static because its INPUT is pinned at full scale**, not because the
selector broke the body. A railed cell is *constant frame to frame* by definition, so a body fed
from one cannot move — the frame-pair test reports STATIC and is right to.

⇒ **`ACT 0x0E` = selector 7 is NOT contradicted by the distortion.** The two results were never in
conflict: §58/§59 are about where the EQ's input is *routed*, and this is about the distortion's
input being *saturated*. ⇒ §61's readings 1 and 2 (context-dependence; an unrelated blocker) are
**not needed**, and reading 3's caution — *carry the decode as "for the EQ"* — remains correct but
for the ordinary reason that one program confirmed it, not because of a counter-example.

### ⚠⚠ AND MY AUDIO CHECK IS TOO LENIENT — it passed a saturated input as "audio present"
The check used throughout this session is *"any of `0x01`/`0x04`/`0x05` above 1 000"*. At selector 7
the distortion has `0x01 = −103 680`, so it **passed** — while the cell the body actually reads,
`0x05`, sat at the rail. ⇒ **a railed pickup must FAIL the audio test, not pass it**: it is exactly
RULE 13's shape one level up — *a constant is not a signal*, even a large one.
⇒ **Fix carried forward:** the audio precondition is *"an input cell is non-zero **and not
railed**"*. Every "audio present" verdict in §42, §50, §60 and §61 was computed with the lenient
rule; the only row it changed is this one, because the rail is rare — but the rule was wrong on
every one of them.

⇒ **This is a SCALE problem, not a body-side decode gap.**
⚠ **BUT MY PLACEMENT OF IT WAS TOO BROAD, and the next measurement says so.** I filed it under
§227's `P_SHIFT`/`ACC_SHIFT` territory as *"the dynamics family's gain staging"*. Checking the
pickup cells of all 14 sampled programs at the correct selector
(`data/railed_pickups_2026-09-13.txt`): **exactly ONE rails — `prog32_distortion` — and 13 do not**,
with healthy pickups from 517 549 to 5 211 235. ★ Decisively, **`prog96_peq_compr_dist` — which
contains the same distortion block — does NOT rail** (`0x05 = 5 211 235`).
⇒ **It is not the dynamics family and it is not distortion-as-a-block. It is `prog32_distortion`
specifically**, which makes it a question about that program's own code or coefficients rather than
a systemic scale defect. A one-program rail is a much smaller and better-posed target than a family
gain-staging review, and it should not be filed against §227 until something ties it there.

⚠ Grade: MEASURED. Both of §61's exotic readings are retired by a scan it asked for.

## 63. ★★★ `f31` IS AN ACTIVELY CHOSEN FIELD — and the corpus is TWO populations split by `hi12` bit 5
§55 ended with an instruction: *"decide `f31 = 0`'s semantics **from the corpus and the HLE**, not
from another arm."*  This is the corpus half, and it is a question the **bytecode can answer on its
own** — no emulator, no arm, no circularity.  Tools: `dsp/tools/f31_activity.py`,
`dsp/tools/bit5_words.py`; artefacts `data/f31_activity_2026-09-13.txt`,
`data/bit5_words_2026-09-13.txt`.

### The test, registered before it was run
The reading §55 leaves open is that `f31` is simply **not a field** on words that fetch no
coefficient — that hi12[3:1] is a don't-care there, the assembler emits whatever, and the device's
`acc ← P_stale + bus` is our invention rather than the chip's.  That reading makes a **falsifiable
prediction**: a field nobody chooses is a field that is always the same, so the same instruction
shape should never appear with two different `f31` codes.

> **MINIMAL PAIR** = two corpus words identical in **every other bit** (all 36, with hi12[3:1]
> masked out) that carry different `f31`.

The **coefficient-fetching population is the built-in positive control**: a multiply chain must
start (LOAD) and continue (ADD), so pairs *must* exist there or the instrument is broken.

### ⛔ The prediction FAILS — `f31` is chosen on both sides
| population | words | minimal-pair shapes |
|---|---|---|
| coefficient-fetching (**control**) | 893 | **6** ✅ the control fires |
| **no coefficient fetch** | 2 164 | **12** |

Among the non-fetching shapes the choice is not marginal: `0100200000` appears **35×** as `ADD` and
**23×** as `HOLD`; `0200200000` **18×** / **13×**; `042010E000` — *the family every body ends with*
— carries codes 0, 2, 4 **and** 6.

⇒ ★★★ **`f31 = 0` on a non-coefficient word is a DELIBERATE code, not a don't-care.**  One of the
two readings §55 left open is closed, and it is closed against the convenient one: §55's
output-killing LOADs are instructions the programmer wrote on purpose, so "the chip ignores the
field there" cannot be the explanation for the dead output accumulator.

### ★★★★ And the same census splits the ISA in two
Cross-tabulating `f31` against **`hi12` bit 5** — a bit `dsp_disasm.py` prints as `?5`, undecoded —
over all 3 057 corpus words:

| | f31 ∈ {0,1,2} | f31 ∈ {3..7} |
|---|---|---|
| **bit 5 CLEAR** (2 885 words) | **2 852 — 98.9 %** | 33 — 1.1 % |
| **bit 5 SET** (172 words) | 43 — 25 % | **129 — 75 %** |

★ With bit 5 clear the corpus uses a **two-bit** operation field.  With bit 5 set it uses **all
eight codes, high ones dominant**.  That is §229's device-side census reproduced **statically from
the source of truth**, and sharper than it: the point is not that bit 5 *admits* the high codes, it
is that bit-5 words are **mostly** high codes.
> ⛔ **CORRECTION (§88).** I wrote here that the device *"collapses every code above 2 into one
> behaviour (`acc ← acc + bus`)"*. **That is wrong at the shipped default.** `SPEC` bit 0 is SET, so
> the device computes `op = f31 & 3`: **4 → LOAD, 5 → ADD, 6 → HOLD**, and only **3 and 7** land on
> "no product". So the five high codes execute as **two** behaviours, three of them **aliased onto
> the decoded ops**. ⚠ That aliasing is the device's own silent mapping, which §133 calls *"a
> standing breach of this project's own rule"* — it is not evidence, and it does not make those
> codes decoded. The measured facts of this section (the minimal pairs, the bit-5 split) are
> unaffected.

### What the bit-5 population IS
172 words, 5.6 % of the corpus, in 32 of 40 programs (2 of them C-format, where hi12 is an
immediate and this encoding does not apply — named, not silently dropped).  It is **not** a
scattering: 92 of the 172 are a **single shape**, `0020200000` — class 2, `ACT 0x00`, `SRC 0x00`,
`addr8 0x00`, **no store** — a word with no source, no action, no store and no pointer walk, whose
*entire* content is `hi12` bit 5 and the three `f31` bits.

⛔ **And it is not padding**, the obvious trap: the 92 are scattered through the bodies (tail
offsets 1 … 105), present in 30 programs, and three of them are in **`prog00_no_operation`** — a
program that by name does nothing and still runs the full skeleton.

⛔ **A tempting headline, falsified on the spot:** *"bit 5 marks the terminator"*.  It looked
compelling — `prog00` and `prog39` both end on one.  Corpus-wide it is **17 of 40 programs**, and
**8 programs contain no bit-5 word at all** (chorus, modulated chorus, flanger, single delay, multi
tap delay, room reverb 1, vibrato, mix up).  Refuted.

⚠ Grade: MEASURED, 3 057 words, 40 listings, static, with a positive control that fired and a
headline of my own that did not survive its own corpus check.

## 64. ★★★ WHERE THE COLLAPSE CAN BE SEEN AT ALL: 96 of the 172 bit-5 sites are BLIND
§63 says five codes execute as one.  Before calling that load-bearing it has to be shown to be
**observable** — and the parametric EQ shows exactly why it might not be.

### The EQ's bit-5 word, measured at the SHIPPED default
The EQ is the one program whose structure the oracle fixes: a 9-word DF-I biquad block repeated
**ten** times (five bands × two units).  Its **four** bit-5 words sit at the four **seams** and
never inside a block — `w3` (unit-0 entry), `w50` (after unit 0's last band), `w56` (unit-1 entry,
positionally homologous to `w3`: `w0↔w53, w1↔w54, w2↔w55, w3↔w56, w4↔w57`), and `w104` (the last
word).  `w3` is `iw87`, and the frame trace at the **true default, no environment set**
(`dsp/tools/trace_window.py`, capture per `catalogue_regression.sh TYPES=15`) reads:

```
    n  iw u1 word        dp mem     acc                 delta(acc)            P
   52  86  0 0212200000 10 17DDEC         933634777639        831127289856        319337988096
   53  87  0 002A200000 10 17DDEC        1355480244775  ★    421845467136        319337988096
   54  88  0 0000240407 50 4A5700         319337988096      -1036142256679        319337988096
```

★★ `iw87` — the bit-5 word, `f31 = 5` — adds **421 845 467 136** to the accumulator, and `iw88`'s
`f31 = 0` LOAD **discards the whole accumulator one slot later**: it comes out *exactly equal to
`P`*.  ⇒ **This site is BLIND.**  No reading of the bit-5 word — collapse, clear, no-op, anything —
could be graded here, because the next instruction overwrites the only register it touched.

### The corpus-wide blindness census
Applying that criterion to all 172 (`bit5_words.py`, SUCCESSOR test):

| the next word is … | sites |
|---|---|
| an `f31 = 0` LOAD — the term is **DISCARDED**, the site is **BLIND** | **96** |
| **not** a LOAD — the term **survives**, the site is **LIVE** | **59** |
| no next word in the image | 17 |

and of the 59 live sites, **41 carry a high code** (`f31` 3:20, 4:6, 5:10, 6:1, 7:4) — the ones the
device collapses.

⇒ ★★★ **The observable size of the collapse is 41 sites**, not 129 and not 172, and they are
*named*: `prog36_compressor` (many), `prog05_phaser` `w9`/`w68`, `prog06_ensemble` `w14/24/34/72/82/92`,
`prog15_rock_rotary` `w5`, and — worth its own line — **the `epilogue`**, the stage §47/§51/§54
have been unable to make present anything.

### ★★ The epilogue, and one fact that needs stating carefully
The epilogue is **the densest program in the corpus after the compressor**: `5` bit-5 words in
`23`, **21.7 %** against a corpus rate of 5.6 %. Two of the five are live (`w70` and `w75` are
blind), and its indices are **absolute I-RAM**, so `epilogue w73` *is* `iw73` —

★★★ **`iw73`, the presentation word, is a bit-5 word.** `0E30C00404`: `SRC 0x10` = the accumulator,
store set, `hi12 = 0xE30` — **bit 5 SET**, `f31 = 0`. That is the single word that hands unit 0's
result to `DO1`, the one §43/§48/§61/§63 measured presenting `0` in every configuration ever tried.

⚠ **And here is the discipline this deserves, because the temptation is obvious.** `iw73`'s `f31`
is `0` — in the **low** set, which the device decodes normally — so the *collapse* of §63 does not
touch it, and the device's existing reading (`ACCA ← level × ACCA`, a coefficient-fetching class-C
word) is a sensible one for a presentation word. **`iw73` being a bit-5 word does not make it
suspect**; §54 already placed the output failure **upstream** of the epilogue, and nothing here
moves it back. What it does say is narrower and still worth recording: *the word that gates the
DSP's audio output carries a bit whose meaning we have just shown to be unsettled*, so `iw73` is
not fully decoded even though its accumulator op is.

### Why this is the right shape for the next unit of work
It converts *"five undecoded codes"* into **"41 sites where a reading can be graded, and 96 where
any experiment would return a false null"** — and that second number is the important one, because
this session has already produced three false nulls by aiming an arm at a site that could not
respond (§46's three aiming errors).  **Any future test of `hi12` bit 5 must be aimed at the live
41**; a gate run that happens to sample the blind 96 would report "no change" and mean nothing.

⚠ **What this does NOT establish:** nothing about what bit 5 or the high codes *mean*.  It
establishes that the corpus chooses them deliberately (§63), that the device collapses them, and
exactly where that collapse is and is not visible.  ⚠ The successor test is **static**, so it reads
the listing in address order — execution order only inside a straight run.  A site it calls blind
**is** blind; a site it calls live could still be discarded further downstream, so 41 is an **upper
bound** on the gradeable set and 96 a **lower bound** on the blind one.

⚠ Grade: MEASURED — static census over 3 057 words, plus one frame-trace window read at the true
default with no environment set (the §56 rule, applied this time *before* drawing the conclusion).

## 65. bit 5 IS A MODIFIER, NOT A CLASS — and the prettiest reading of it dies to its own control
§63/§64 bounded the bit-5 population without saying what it is. Two more static tests
(`bit5_words.py`, same artefact) narrow it, and kill the reading I would otherwise have written up.

### ★ It is a modifier on an otherwise identical instruction
| test | result |
|---|---|
| shapes written **both** ways (bit 5 and `f31` masked) | **17** of 715 |
| **EXACT** pairs — identical in all 40 bits **but bit 5** | **2** |

The two exact pairs are the corpus's own A/B: `0000200000` (**62×**) vs `0020200000` (**2×**), and
`040010E000` (**8×**) vs `042010E000` (**2×**) — the class-2 do-nothing word and the body-terminal
word, each written both ways with **`f31 = 0` on both sides**. ⇒ bit 5 is **not** a class or a
format selector: the same instruction exists with and without it.

### ⛔ And the reading that the density table suggests does NOT survive
The per-program density is strikingly non-uniform against the 5.6 % corpus rate:

| program | bit-5 words | density |
|---|---|---|
| `prog36_compressor` | 12/40 | **30.0 %** |
| `epilogue` | 5/23 | 21.7 % |
| `prog75_peq_compressor` | 12/59 | 20.3 % |
| `prog48_auto_pan` | 8/50 | 16.0 % |
| `prog96_peq_compr_dist` | 14/90 | 15.6 % |
| `prog52_auto_wah` | 9/72 | 12.5 % |
| `prog35_exciter` | 8/69 | 11.6 % |

and the **eight programs with ZERO** are *every* pure delay/modulation network in the catalogue —
chorus, modulated chorus, flanger, single delay, multi tap delay, room reverb 1, vibrato, mix up.
Compressor, auto-wah, exciter at the top; linear delay networks at the bottom. The reading writes
itself: **bit 5 selects a second operation group — the non-MAC arithmetic (rectify / peak / compare
/ limit) an envelope follower needs**, which would also explain why the corpus spends all five high
`f31` codes there.

⛔ **I wrote here that it fails its own control. THAT REFUTATION IS RETRACTED — see §66.** The
control was `prog00_no_operation` ("a pass-through program cannot be dense in detection", 10.2 %,
above the corpus rate). **The premise was false, and this project had already written down why.**

⚠ Grade: the density table is MEASURED; my refutation of the reading it suggests was WRONG and is
withdrawn in the next section, which also supplies the null it should have had from the start.

## 66. ⛔⛔ §65's REFUTATION IS RETRACTED — my control was invalid, and `families.md` said so already
§65 killed the *"bit 5 selects the envelope / non-MAC operation group"* reading with one control:
`prog00_no_operation` is bit-5-dense at **10.2 %**, and a pass-through program detects nothing.

⛔⛔ **`dsp/algorithms/families.md` had already classified that exact program**, under
**"Filter / dynamics"**, on **independent coefficient evidence** (the 2/π scale constant and the
one-pole smoother coefficients), together with ENHANCER, AUTO WAH and COMPRESSOR — and says it in
as many words:

> *"**`NO OPERATION` is not empty**: it is a dry pass-through that still runs that level detector
> (most plausibly effect-level metering or a de-click ramp)."*

⇒ **My control's premise was false.** `prog00`'s above-rate density is not a refutation of the
reading; it is a **fourth confirming member of it**. ★ And this is the **§59 failure mode again** —
a settled, written-down result not consulted before building on its contradiction — reached this
time not by ignoring the ledger but by **inventing a control instead of looking up whether the
project had already characterised the program I was using as one.** The rule generalises:
**before a program is used as a control, read what the decode already says it does.**

### With the null it should have had from the start
| group (classification is **`families.md`'s**, not mine) | words | bit-5 observed | expected at the 5.63 % corpus rate |
|---|---:|---:|---:|
| **decoded LEVEL-DETECTOR family** — enhancer, auto wah, compressor, no operation | 260 | **34** | 14.6 |
| **pure delay/modulation networks** — chorus, mod. chorus, flanger, single delay, multi tap delay, room reverb 1, vibrato, mix up | 586 | **0** | 33.0 |

★★★★ **All four detector-family programs are above the corpus rate** (compressor 30.0 %, auto wah
12.5 %, no operation 10.2 %, enhancer 8.1 %), a **2.3× enrichment** — and the eight linear networks
carry **zero** where uniformity predicts **33**: `P(0 | uniform) ≈ 1.8 × 10⁻¹⁵`. ⚠ And the longest
program in the corpus, `prog16_room_reverb_1` (133 words), is one of the zeroes, which kills the
obvious confound that long or complex programs simply accumulate more of everything.

⇒ **The association between `hi12` bit 5 and the decoded dynamics families is real and very
strong.** It is a **correlation over 40 programs**, and `families.md`'s own grading of the detector
claim ("survives on the coefficient evidence alone") is inherited by it.

### ⛔ But the obvious MECHANISM is refuted, and by the right control this time
If bit 5 were the **control-bus operation** — `DECODE-by-correlation` §8 decodes `SRC 0x1C` as
*"the effect's control/modulation bus, a source register always multiplied into the signal path,
carrying the LFO in modulation effects and an envelope / AGC level in the dynamics ones"* — then
bit-5 words should sit **near** `SRC 0x1C` words. Null = the same statistic over every non-bit-5 word:

| window | bit-5 words near a `SRC 0x1C` | **NULL** (all other words) |
|---|---:|---:|
| ±1 slot | 2.3 % | 4.6 % |
| ±2 | 2.9 % | 7.8 % |
| ±3 | **4.1 %** | **10.9 %** |

⛔ **Refuted, and in the wrong direction**: bit-5 words are **two to three times LESS** likely to be
near the control bus than an average word. And **5 of the 8 zero-density programs contain `SRC 0x1C`
anyway**, so "has a control bus" does not predict bit 5 either.

⇒ ★★★ **The association is at PROGRAM level and NOT at SITE level.** Whatever bit 5 marks, it is
something the dynamics and distortion families need *somewhere in the program* and the linear delay
networks never need at all — but it is **not** the control-bus multiply, and it is not adjacent to
it. That is a much sharper statement of the open question than §65 left, and it was bought by
running the site-level test the program-level table could not justify on its own.

⚠ Grade: MEASURED (static, 3 057 words, 40 listings, two nulls). **Nothing anchored**; one
refutation of mine retracted, one mechanism refuted with a calibrated null.

### Where this leaves the queue
1. ⇒ **The HLE cannot yet arbitrate**: `dsp/hle/effects.py` models 8 effects and **none of the four
   detector-family ones**. The oracle is silent exactly where the signal is strongest, so
   **extending the HLE to the dynamics family is now the top item** — it is what §55's "and the
   HLE" half needs, and what would let bit 5 be taken to an oracle at all.
2. Any in-emulator test of bit 5 must be aimed at §64's **live 41**, never the blind 96.
3. The two EXACT bit-5 pairs (§65) remain the cheapest experiment in the corpus.

## 67. ★★★★★ THE SITE-LEVEL MECHANISM §66 SAID WAS MISSING — and it was already written down
§66 left a sharp gap: bit 5 tracks the dynamics families at **program** level
(`P ≈ 1.8 × 10⁻¹⁵`) but is **anti-correlated** with the control bus at **site** level, so *what*
those programs use it for was open. `SPECULATIVE-APPLIED-REGISTER.md` §3 already had it, and I found
it by looking up the constant rather than by running anything new.

`0x517CC1` = **`floor(2/π × 2²³)` exactly**, and **2/π is the mean of a RECTIFIED sine** — it is
`programs.tsv`'s *"2/pi env"* level detector, **named in the ROM's own role table**. It sits in a
byte-identical idiom, and measuring the corpus for it (`dsp/tools/detector_idiom.py`,
`data/detector_idiom_2026-09-13.txt`):

```
   <HEAD>                 hi12 = 026 or 02E — class 2, BIT 5 SET, f31 = 3 or 7
   018.A.00.1D5           C-RAM 0x517CC1 = 2/π
   104.A.00.1D5           C-RAM 0x400000 = 0.5, pointer FROZEN
   C40.2.C0.000           C-format immediate
   182.A.00.000           one-pole smoothers, 4.712 ms and 11.764 ms
```

| | |
|---|---|
| idiom sites | **12**, in 8 of 40 images |
| ★ head word carries **`hi12` bit 5** | **11 of 12** |
| its `f31` | **3** (×8) and **7** (×3) — *never* a low code |

and the images are exactly the detector set: `prog00_no_operation`, `prog36_compressor` ×2,
`prog52_auto_wah`, `prog70_auto_wah_s_delay`, `prog75_peq_compressor` ×2, `prog96_peq_compr_dist` ×2,
`prog97_peq_compr_overdr` ×2, `prog08_gated_reverb`.

⇒ ★★★★ **§66's program-level association HAS a site-level mechanism: the bit-5 word is part of the
level detector itself.** And it explains §66's refutation rather than contradicting it — the idiom
**produces** the envelope; `SRC 0x1C` **carries** it to the consumers elsewhere in the program, so
the two must *not* be adjacent. The anti-correlation was evidence for this reading, read backwards.

⛔ **The one exception, stated because it is the falsifier:** `prog08_gated_reverb` `w80` is headed
by `000020868B` — **bit 5 clear, `f31 = 0`**. So the head is not *required* to be a bit-5 word, and
any "bit 5 ⇒ detector head" rule is already 11/12, not 12/12.

### ★ The inference this invites, and its exact strength
The detector must **rectify** — 2/π is the mean of `|sin|`, and it is the wrong constant for an RMS
detector (that would be `1/√2`). Of the idiom's five slots, four are accounted for by named
quantities (2/π, 0.5, an immediate, the smoother). The unaccounted one is **the head**.
⇒ **`hi12` bit 5 with `f31 ∈ {3, 7}` is plausibly the RECTIFIER — an absolute value, which is
exactly the "non-MAC operation" §65 proposed and §66 restored.**

⚠ **Grade: this is an INFERENCE, not a measurement, and it is not promoted.** Rivals that survive
it: the rectification could live in the **source encoding**, or happen **upstream** of the idiom
entirely; and `f31 = 3` vs `f31 = 7` differ by `f31[2]`, which §227/§27 tried to read as an
accumulator select and had **refuted** (the accumulator is selected by the UNIT). What *is*
measured is the co-occurrence, 11 of 12.

⚠ And the foothold is small: **11 of 172** bit-5 words are idiom heads — **6 %**. The other 94 %
remain unexplained, and `prog48_auto_pan` (16 %) and `prog35_exciter` (11.6 %) are bit-5-dense with
**no 2/π idiom at all**.

### ⇒ What this unblocks, concretely
This is the first **decoded semantic** attached to a bit-5 word, and it arrives with its own
arithmetic: `env[n] = onepole((2/π)·|x[n]|, τ)`, `τ ∈ {4.712 ms, 11.764 ms}`, plus a `0.5`
coefficient — enough to write the **level detector the HLE does not have**, from the bytecode
rather than from a textbook. That is §66's top queue item, now with its constants supplied by the
ROM.

⚠ Grade: MEASURED (12 sites, 40 listings) for the co-occurrence; the rectifier reading is INFERRED
and explicitly not anchored.

## 68. ★★★★★ THE BYTECODE CORRECTS THE HLE: the compressor's detector is a RECTIFIER, not square-law
The standing goal says the bytecode is the source of truth, *"there may even be mistakes on the HLE
version"*, and that a better HLE must be updated in the documentation. §67 produced one, and it is
not a subtlety — it is the detector's **operating principle**, wrong in the shipped reference.

`kn5000_tonegen.cpp`'s DSPHLE compressor (selector `0x16`), and the documentation page that
archives it, both said:

> *"COMPRESSOR: **square-law detector** → attack/release smoother → gain computer"*

with `rl = xl * xl`, a `sqrt()` in the gain computer, an attack mapped from C-RAM[0x02] through
`0.002 + 0.02·tc`, and a **release fixed at 150 ms**.

### Three corrections, each from the ROM
| # | the HLE said | the bytecode says |
|---|---|---|
| 1 | **square-law** (RMS) detector | **mean-absolute** (rectifier). `C-RAM[0x00] = 0x517CC1 = floor(2/π·2²³)` exactly, and **2/π is the mean of `\|sin\|`**. An RMS detector's sine calibration is **`1/√2 = 0.7071`**, which appears **nowhere** in the ROM. `programs.tsv` names the cell *"2/pi env"* from the instrument's own role table. |
| 2 | attack ≈ **2.1 ms** (`0.002 + 0.02·tc`, an invented map) | **4.712 ms** — `C-RAM[0x02] = 0x009DAD = 0.004812`, a one-pole coefficient with `τ = 1/(a·fs)` |
| 3 | release **fixed at 150 ms**, C-RAM[0x03] **ignored** | **11.764 ms** from `C-RAM[0x03] = 0x003F29 = 0.001927`. The release is **uploaded**, not a constant — which is why the panel exposes `RELEASE SENS.(s)` at all. The shipped value was **13× too slow**. |

★ And correction 1 has a **second, independent leg**: `SQUARING-MULTIPLY_findings.md` adjudicated
every squaring in the corpus and found it is **coefficient × coefficient** — a word routing
`C-RAM[cursor]` onto the multiplier's single operand bus — graded FAITHFUL and *"numerically
negligible … (envelope time constants: measured products 203 and 900)"*. **There is no `x·x` of the
SIGNAL anywhere in 3 057 words.** So the square-law reading was not merely uncalibrated; it has no
mechanism in the ISA.

### What was changed, and what deliberately was not
✅ `kn5000_tonegen.cpp`: detector rectifies and scales by the ROM's 2/π (falling back to `0x517CC1`
if the cell is unloaded, so it can never be silently scaled by zero); the gain computer's `sqrt()`
is gone (the envelope is already an amplitude); both time constants are read from **their own
cells** as `τ = 1/(a·44100)` and converted to the stream's rate so the **time** is preserved rather
than the coefficient. Compiles clean (`errors: 0`), binary back at its full size.
⛔ **The GAIN LAW is deliberately UNCHANGED.** What the corpus establishes there is only the
*negative* constraint — no comparator opcode, branchless bodies, so THRESHOLD/RATIO enter as
coefficients — and **nothing measured chooses** between the shipped knee and the linear
`g = clip(1 − k·env, 1/ratio, 1)`. Fixing what the evidence covers and leaving what it does not is
the whole discipline; changing the knee too would have been taste dressed as a decode.

### And the HLE now has the family at all
`dsp/hle/` gained `LevelDetector` (a fifth kernel, every constant from ROM `0x84CD`),
`level_envelope`, `compressor` and `auto_wah`, validated by defining property — the 2/π constant to
the LSB, both time constants to 0.002 ms, linearity in amplitude, attack faster than release, and
the wah's resonance landing within 1.5 % of the frequency its own envelope predicts at two input
levels a factor of 12 apart. ⚠ **Two of those checks earned their keep**: one caught a real bug
(the wah assigned coefficients to attribute names `BiquadDF1` does not use, so the filter never
moved), and one **was replaced rather than loosened** — a spectral centroid barely tracks a
two-pole corner (1 183 → 1 229 Hz for a corner that doubles), so it now measures the resonant peak
against a prediction, which is *stronger* than the check that was failing.

✅ **Documentation updated and permanence re-verified**: `effect-impl/compressor.md` carries the new
reference and its headline no longer says "square-law"; `test_hle_permanence.py` still passes
**24 pages / 46 `cpp` blocks byte-identical**, so the archive obligation is intact.

### ★ How big is the correction? Measured, not asserted
`dsp/hle/compare_detector_laws.py` (artefact `data/detector_laws_2026-09-13.txt`) runs **both**
detectors on the same signal — 220 Hz, amplitude 0.08 → 0.9 → 0.08 — through the **same** gain law,
so none of the difference comes from a change nobody has evidence for:

| detector | release back to the quiet passage |
|---|---|
| **the ROM's** (rectify, 4.712 / 11.764 ms) | **15.9 ms** |
| the one that shipped (square-law, ~2.1 / 150 ms) | **350.7 ms** |

⇒ ★ **the shipped detector took 22× longer to let go.** That is the audible part: it kept ducking a
passage the instrument's own ROM says had already recovered — with the release constant sitting
unread in `C-RAM[0x03]` the whole time.

### And it was run, not just compiled
A/B in the emulator, timeout-wrapped, visible window, notes playing (RULE 12), `TYPEIDX=13`
(`prog36_compressor`), control `DHLE=0` vs `DHLE=0x16`, identical in every other respect:

| | control | compressor HLE |
|---|---|---|
| 30–35 s (note on, effect not yet engaged) | rms 1 251.8 | rms 1 251.8 — **bit-identical**, the null |
| 40–45 s | rms 5 526.7 | **rms 6 438.9**, difference rms 1 638.8 |
| peak | 27 067 | **27 067 of 32 767 — NOT railed** |

★ The 30–35 s window is the **calibration**: the two arms are byte-identical there, so the
difference later is the effect engaging and not a run-to-run wobble (RULE 13 — and this instrument
can see a null, because it produced one).

⚠ **What this does NOT show:** that the change *improved* the audio against hardware. Nobody has
heard the real instrument's compressor (`kn5000-hardware-inaccessible`), so this is *"the
reconstruction now follows the ROM's constants and still runs, engages and does not rail"* — not a
fidelity claim. The fidelity claim rests entirely on the ROM's own coefficients.

⚠ Grade: corrections 1–3 are **FORCED** from the ROM's own upload script plus the adjudicated
squaring census. The size of the correction and the A/B are **MEASURED**. The gain law remains
**SPECULATIVE** and is marked so in both references.

## 69. ★★★★ THE BIT-5 PAGE SPLITS ON A BIT THE PROJECT HAD ALREADY DECODED — and END words are all EVEN
§63 tested *"bit 5 marks the terminator"* and refuted it (17 of 40). **The terminator marker is a
different bit, and it was decoded long ago**: `dsp_disasm.py:426` — *"bit 10 with bit 11 clear =
END OF BLOCK (the word still does its work)"* — and the kernel's own annotations call `w6`/`w11`
*"END OF BLOCK A/B"*.

⚠ **I re-derived this from scratch before checking**, and was one step from writing it up as a
find. The rule §66 extracted the hard way — *read what the decode already says* — applies to bits
as well as to programs. What is genuinely added here is the **null it never had**:

| | |
|---|---|
| non-C-format words carrying bit 10 | **53** of 2 989 (1.8 %) |
| of those, sitting at the image's **last** word | **39** — i.e. **39 of 40 images end on one** |
| the 40th | the `epilogue`, which ends on a **C-format** word where bit 10 is part of the `0xC00` format code and means nothing |
| base rate: a random non-C-format word is terminal | **1.34 %** |
| a **bit-10** word is terminal | **74 %** — a **55× enrichment** |

The 14 non-terminal ones are **13 in `kernel` and 1 in `epilogue`** — the two shared images that
are entered and left several times a frame, which is what "end of *block*" rather than "end of
program" predicts.

### ★★ Crossing it with bit 5 partitions the population — and yields a hard constraint
| | `bit5 = 0` | `bit5 = 1` |
|---|---:|---:|
| not END | 2 850 | 155 |
| **END** | 35 | **17** |

17 observed against **2.9 expected** under independence — **5.8×**. All 17 are the program's
terminal word, all of the `042X10E000` family. And inside the bit-5 page:

| page | `f31` histogram (0…7) |
|---|---|
| `bit5 = 1`, **END** | `0:2  1:0  2:2  3:0  4:12  5:0  6:1  7:0` — ★★ **EVERY ONE EVEN, 17 of 17** |
| `bit5 = 1`, not END | `0:11 1:24 2:4 3:34 4:22 5:42 6:2 7:16` — **75 % ODD** |
| `bit5 = 0`, END | `0:17 1:12 2:6` — **mixed**, so the rule is *not* a property of END words generally |

★★★★ **Inside the bit-5 page, an END-OF-BLOCK word takes only an EVEN code — 17 of 17 — where the
non-END bit-5 words are only 25 % even. `P ≈ 6.5 × 10⁻¹¹`.**

⇒ The bit-5 population now has **three identified parts**, and the parity separates two of them
cleanly:

| part | count | `f31` |
|---|---:|---|
| **block terminators** (§69) | 17 | **even** — 0, 2, 4, 6 |
| **level-detector heads** (§67) | 11 | **odd** — 3, 7 |
| unexplained | 144 | mixed |

⚠ **What this is:** a constraint a reading must satisfy, not a reading. It says `hi12` bit 1 (the
low bit of `f31`) is **anti-correlated with bit 10 inside the bit-5 page** — never that we know
what either means there. ⚠ And 144 of 172 remain unexplained, so this is a partition, not a decode.

### ★ The EQ, dynamically: it has NO gradeable bit-5 site at all
Running §64's successor test in **execution order** on a live capture (`dsp/tools/bit5_trace.py`,
the EQ at the true default) rather than address order:

| the EQ's 11 bit-5 executions | |
|---|---|
| `iw87`, `iw134`, `iw140` — large deltas (`4.2e11`, `1.3e9`, `5.5e11`) | **all BLIND**, discarded by the next `f31 = 0` LOAD |
| `iw73`, `iw78` — the only **LIVE** ones | delta **0**, because the epilogue's accumulator is already dead (§47/§54) |

⇒ ★ **The parametric EQ cannot grade a bit-5 experiment**: where the words do something it is
discarded, and where it would survive there is nothing left to do it to. The reference program this
session has leaned on hardest is **exactly the wrong place** to test this, and the static census
predicted it.

⚠ Grade: MEASURED (static over 3 057 words with two nulls; one live capture at the true default).
Nothing anchored.

## 70. ★★★★★ THE PICKUP RAIL IS NOT ONE PROGRAM — 4 of 4 DETECTOR PROGRAMS RAIL, AND `NO OPERATION` IS ONE
> ⛔⛔ **THE "DETECTOR FAMILY" FRAMING OF THIS SECTION IS SUPERSEDED BY §72.** The rail is **not**
> a property of the detector family: non-detector programs rail too, and the one non-railing
> program in this section's sample simply had the smallest input. §71 found the confound, §72
> decontaminated it. **The measurements below stand; the attribution to the family does not.**
This session opened by **narrowing** §62's railed pickup to *"`prog32_distortion` specifically,
not the dynamics family"*. **That narrowing was made on a sample that contained no standalone
dynamics program except the distortion** — no compressor, no enhancer, no auto wah, no
NO OPERATION. Measuring those four (`dsp/tools/pickup_cells.py`, captures
`reg/det7`, **true default, `PSHIFT=0 C8SHIFT=0`, no arms**, `NOTEOFS=2.5`, every identity
fingerprinted):

| TYPE | program | `0x01` | `0x04` | `0x05` | |
|---|---|---:|---:|---:|---|
| 2 | `prog03_enhancer` | 306 688 | 100 864 | **8 388 607** | ⛔ RAILED |
| 13 | `prog36_compressor` | −65 024 | −241 664 | **−8 388 608** | ⛔ RAILED |
| 14 | `prog00_no_operation` | −286 976 | −166 400 | **−8 388 608** | ⛔ RAILED |
| 18 | `prog52_auto_wah` | −118 528 | −211 456 | **8 388 607** | ⛔ RAILED |

★★★★ **4 of 4.** And **`prog00_no_operation` railing is decisive that this is OUR defect, not the
chip's**: a program whose entire job is to pass audio through cannot legitimately saturate its own
input cell. No fidelity argument survives that.

### It blocks everything downstream, measured
| | |
|---|---|
| body reads of cell `0x05` across the four programs | **9** |
| of those, **railed** | **9** |
| the rail across a frame pair | **CONSTANT** (verified on TYPE 2 and 13) |

⇒ a body fed from a constant cannot move. §61's *"the distortion is genuinely STATIC at the correct
selector"* is the same phenomenon, and it is **general to this family**, not peculiar to one
program.

### ★★★ And it is NOT an input sample — it is a CLAMPED STORE, at a named word
| | |
|---|---|
| peak `\|sample\|` that ever entered and was read (device's own input-stage audit) | **0x24F100 = 2 420 992** — *identical in all three programs checked* |
| the rail | **8 388 607** — the input never came within **3.5×** of it |

Tracing every touch of cell `0x05` through a NO OPERATION frame (identical in both frames of the
pair):

```
   iw8   read  -8388608  <-- RAIL, left over from the previous frame
   iw10        -4233362      sane
   iw34        -4543261      sane
   iw35  ST=1   4194304      = 0x400000
   iw45  ST=1  -8388608  <-- RAIL WRITTEN HERE
   iw84/86/118 -8388608      the body reads the rail
```

★★★ **`iw45` = `0010A0020C`** — class A, `ACT 0x0C`, `SRC 0x08`, `f31 = 0`, **bit-4 STORE**. The
accumulator arriving there is **−791 648 272 384**, whose datum is **−12 079 997**, i.e. **1.44×
past the datum rail**, so the bit-4 store's deliberate clamp writes `0x800000`. On the flanger the
*same word* stores **2 824 201** and nothing clamps — the accumulator arriving is
**+185 086 889 467**, 4× smaller.

⇒ **The pickup is railed by the kernel's own arithmetic overflowing the datum rail, and cell `0x05`
is both the store's target and the input pickup `iw8` reads.** That is why §62 could call it a
scale problem and be right about the *kind* of defect.

### ⛔ One candidate confirmed PRESENT and refuted as the DISCRIMINATOR
`SQUARING-MULTIPLY_findings.md` item F attributes a kernel overflow to the **cursor base being
unseeded at frame start** (*"shipped, `c = 0x9B`, which is unit 1's reverb bank … nothing seeds the
cursor at frame start"*). **Confirmed present**: `cur = 0x9B` at `iw28`, walking `0x9C 0x9D 0x9E …
0xA3 0xA4`. ⛔ **But it is IDENTICAL in the railing program and the non-railing one** — same
cursor, same coefficients, at every step. So the unseeded cursor is real and is **not** what
separates them. What separates them is the **magnitude of the accumulator**, already 45× apart by
`iw28`.

### ⚠⚠ AND A POOLING TRAP I NEARLY WALKED INTO — the two censuses are DIFFERENT MACHINES
I was one keystroke from writing *"4 of 4 dynamics programs rail, against 13 of 14 others fine"*.
**Those are not comparable.** The 14-program table (`data/railed_pickups_2026-09-13.txt`) was
captured with **`UPD6383_PSHIFT=2 UPD6383_C8SHIFT=1`**; these four are at the **true default**.
`PSHIFT=2` sets `P_SHIFT=7/ACC_SHIFT=16`, total **23** instead of **22** — **it halves every
datum**, which is exactly the quantity that decides whether the clamp fires. Pooling them would
have attributed to the *program family* something that may belong to the *arm*. That is §229's
trap, one level up.

### ★★★★★ THE 2×2 REPORTS: IT IS AN INTERACTION — NEITHER THE FAMILY NOR THE ARM ALONE
Each cell holds the **program and the trace instant fixed** and changes only the machine
(`dsp/tools/pshift_2x2.sh`):

| cell `0x05` | **arms ON** (`PSHIFT=2`, total shift **23**) | **TRUE DEFAULT** (`PSHIFT=0`, total **22**) |
|---|---:|---:|
| **NO OPERATION** (TYPE 14) | **−185 — ok** | **−8 388 608 — ⛔ RAILED** |
| **FLANGER** (TYPE 3) | 517 549 — ok | **2 912 280 — ok** |

★ **The internal null holds**: for NO OPERATION, cells `0x01` and `0x04` come out
**byte-identical** across the arm (−286 976 / −166 400) — the arm moved **only** the cell that
rails, which is what the mechanism predicts and what a contaminated run would not give.

⇒ **Both one-factor stories are wrong.**
* ⛔ **Not the program family**: NO OPERATION **un-rails** when the datum scale changes.
* ⛔ **Not the arm**: the flanger **does not rail** without it.
* ⇒ ★★★ **The datum scale is NECESSARY but not SUFFICIENT.** At the shipped total shift of 22,
  programs whose kernel accumulator runs large enough overflow the datum rail at `iw45` — and the
  four detector programs do while the flanger does not. That is why the earlier 14-program census,
  taken at total 23, saw only one rail: **the arm was hiding the defect in every program it
  measured.**

### ⚠⚠ AND THE ARM IS NOT THE FIX — this is the part not to over-read
Un-railed, NO OPERATION's pickup reads **−185**. The input-stage audit says samples up to
**2 420 992** entered. **A dry pass-through whose input cell carries −185 is still broken** — it is
simply broken quietly instead of loudly. Compare the flanger at **517 549 / 2 912 280**, which are
plausible signal levels.
⇒ **`PSHIFT=2` removes a SYMPTOM.** It is also §227's *"two-sided control"*, documented as
contradicting the MEASURED Q1.22 scale, so *"just ship total 23"* is exactly the move this note's
own rules forbid. ⚠ What the 2×2 buys is **a correctly-posed question**: why does the kernel's
accumulator arrive at `iw45` 4× larger in the detector programs, and why does the pass-through's
pickup end up at −185 either way?

⚠ Grade: MEASURED — 2×2, four cells, program and instant held fixed, an internal null that held,
identities fingerprinted. The **cause** is localised to `iw45`'s clamp and the **discriminator** is
settled as an interaction. **Nothing is promoted**, and the arm that removes the symptom is
explicitly NOT proposed as a fix.

## 71. ⛔ THE `NOZ05` ARM IS REFUTED — and it corrects §70's vocabulary AND exposes a confound
§70 localised the rail to `iw45`'s clamped bit-4 store. Walking one step further back showed that
was the **perpetuation, not the origin**: at **`iw8`**, the frame's *first* touch of cell `0x05`,
NO OPERATION already reads `0x800000` while the flanger reads a real sample. The rail is present
**before the frame starts** ⇒ a **LATCH-UP**, and the device's own default-off `UPD6383_NOZ05`
suppresses exactly the kernel-A stores that could close the loop.

Predictions were **written and committed before the run** (`data/PREDICT_NOZ05_2026-09-13.md`).

| # | prediction | result |
|---|---|---|
| **P1** | `0x05` NOT railed | ⛔ **FAILS** — still railed, it only flipped sign (`−8 388 608` → `+8 388 607`) |
| P2 | `0x05` non-zero | passes, but see below |
| **P3** | `\|0x05\|` of the input's order (10⁵…10⁶) | ⛔ **FAILS** |
| **P4** | `0x01`/`0x04` unchanged — the internal null | ✅ **HELD** (−286 976 / −166 400) |
| **C1** | the flanger unharmed | ✅ **HELD** (2 912 280, identical) |

The arm **fired** (`iw9:1 722 190  iw35:1 722 183  iw45:1 722 183` stores suppressed).
⇒ **REFUTED, and trustworthily so**: the null held and the control held, so the failure is the
arm's, not the instrument's.

### ★★★ What the refutation revealed is worth more than a pass would have been
With every kernel-A store to `0x05` suppressed, the cell **never changes for the entire frame** —
one line, `iw8`, and nothing after it. ⇒ **those stores are the cell's ONLY writer.** Suppressing
them does not break a loop; it **starves the cell**, which is precisely the failure mode P2 was
written to catch.

### ⛔⛔ AND THAT CORRECTS THE WORD "PICKUP" IN §62, §70 AND EVERY SECTION THAT USED IT
The device's own input-stage audit says where DI1 actually deposits:

> *"WHERE THE WINDOW SAT … most common X = `0xFF` on 1 711 626 (99.64 %) → **latch cells `0x01` /
> `0x04`**"*

and those two cells carry **sane, sample-like values in every capture ever taken**, railed or not
(`−286 976 / −166 400` here). ⇒ ★★ **cell `0x05` is NOT the input latch. It is a DERIVED cell —
the kernel's hand-off of the assembled input to the body** — which is why the kernel's own stores
are its only writer and why `iw8` reads last frame's value. The project's two annotations
(*"latch cells 0x01/0x04"* and *"[..] marks the per-unit base/input cells 05 07 85 87"*) are
consistent once `0x05` is read as the **hand-off**, not the deposit.
⇒ So the defect is **not "the input arrives saturated"**. The input arrives fine, every time. It is
**the kernel's input stage saturating while assembling it**, between `iw2` and `iw45`.

### ⚠⚠ A CONFOUND IN §70's HEADLINE, found by checking my own sample
§70 said *"4 of 4 detector programs rail"*. On the same machine, the input latch cells read:

| program | `0x01` | `0x05` |
|---|---:|---|
| `prog03_enhancer` | 306 688 | ⛔ railed |
| `prog00_no_operation` | −286 976 | ⛔ railed |
| `prog52_auto_wah` | −118 528 | ⛔ railed |
| `prog36_compressor` | −65 024 | ⛔ railed |
| **`prog04_flanger`** | **−32 512** | **ok** |

★ **The one program that does not rail also has the SMALLEST input — by 2× on the nearest railing
program and 9× on the loudest.** The four detector programs were traced at *later* instants
(`36.0 + 0.2·TYPE + 2.5 s`), so they are further into the note and simply **louder**. ⇒ **input
level is confounded with program family in that sample**, and §70's headline cannot distinguish
*"the detector family saturates"* from *"a loud enough input saturates"*.

⚠ **A decontamination run is in flight**: three NON-detector programs (ensemble, multi tap delay,
mix up) at the true default, whose inputs sit in the same 150k–160k band as the railing ones. If
they rail, the family is not the variable and §70's headline must be restated as a level effect.

⚠ Grade: the refutation is **MEASURED** with a pre-registered criterion, a null that held and a
control that held. The vocabulary correction is **READ from the device's own audit**. The confound
is **MEASURED and currently unresolved** — §70's headline is *provisional* until the
decontamination reports.

## 72. ★★★★★ DECONTAMINATED: IT IS NOT THE FAMILY — **7 OF 8 PROGRAMS HAVE A BROKEN HAND-OFF CELL**
§71 found the confound: §70's four railing programs were all traced *later in the note* than the
one that did not, so they were simply **louder**. The decontamination is three **NON-detector**
programs at the true default, chosen because their inputs sit in the same band as the railing ones.

**All eight programs, one machine, the device default (`PSHIFT=0 C8SHIFT=0`), identities
fingerprinted** (`data/handoff_cell_2026-09-13.txt`):

| program | family | `0x01` (input latch) | `0x05` (hand-off) | |
|---|---|---:|---:|---|
| `prog04_flanger` | modulation | −32 512 | **2 912 280** | ✅ the only healthy one |
| `prog06_ensemble` | modulation | 152 576 | **0** | ⛔ **ZERO** — no signal reaches the body |
| `prog10_multi_tap_delay` | delay | −162 304 | −8 388 608 | ⛔ RAILED |
| `prog56_mix_up` | delay/mix | 157 952 | −8 388 608 | ⛔ RAILED |
| `prog03_enhancer` | **detector** | 306 688 | 8 388 607 | ⛔ RAILED |
| `prog36_compressor` | **detector** | −65 024 | −8 388 608 | ⛔ RAILED |
| `prog00_no_operation` | **detector** | −286 976 | −8 388 608 | ⛔ RAILED |
| `prog52_auto_wah` | **detector** | −118 528 | 8 388 607 | ⛔ RAILED |

⇒ ⛔⛔ **§70's "detector family" attribution is REFUTED.** `multi_tap_delay` and `mix_up` are
delay-family programs with no level detector at all, and they rail at inputs of 162k and 158k —
*below* the enhancer's 307k. Family does not separate the columns.

⇒ ★★★★★ **THE CORRECTED HEADLINE, and it is far bigger than the one it replaces: at the SHIPPED
datum scale, 7 of 8 programs hand the body a cell that is RAILED (6) or ZERO (1). Exactly ONE
program in eight delivers a plausible sample to its body.**
> ⚠ **AND EVEN THAT ONE IS NOT HEALTHY — §73.** `prog04_flanger`'s frame **also ends with `iw45`
> storing `0x7FFFFF`**, and its cell reads **2 912 280 in frame N and 8 081 098 (96 % of full
> scale) in frame N+1**. It is **latching up more slowly**, not surviving. ⇒ the true count is
> **8 of 8 at or near full scale**; "exactly one healthy" was a sampling artefact of reading the
> cell at `iw8`, before the frame's own store.

★ The ensemble's zero is **not** an absent measurement — the cell is touched 20 times in the frame
and is driven to `0` by the **same `iw45`** that rails the others. Saturating to a rail and
collapsing to zero are two outcomes of one broken stage.

### Why nobody saw this
Every previous liveness census was taken with **`UPD6383_PSHIFT=2`** (total shift 23, datum halved)
— `data/railed_pickups_2026-09-13.txt`, `reg/sel7_live`, and the whole §42/§50/§60 sweep. At that
setting the stage does not saturate and the cell looks fine. **The arm was hiding the defect in
every program ever measured**, and it was carried as a "baseline arm" in `catalogue_regression.sh`
precisely because it made things work.

⇒ This also **vindicates §62's original reading** — *"this is a SCALE problem, §227's
`P_SHIFT`/`ACC_SHIFT` territory"* — which **I narrowed away in this session's opening commit** and
then restored piecemeal. The scale was right; my two narrowings (*"one program"*, then *"the
dynamics family"*) were both wrong, and each was wrong because its sample could not see the
alternative.

### ⇒ What this means for the LLE, concretely
This is **the** blocker, and it is upstream of every decode question the session queued:
* §54/§55's *"14 of 16 bodies leave a constant accumulator"* — a body handed a rail **cannot** do
  anything else. That whole line of investigation was measuring the consequence.
* §64/§69's bit-5 probe sites, `prog52_auto_wah` included, are fed a rail ⇒ **ungradeable today**.
* §47/§51's output-stage nulls are downstream of a body that never received a signal.
⇒ **Fix the kernel's input stage first.** The defect is between `iw2` and `iw45`, it is a
saturation in the *assembly* of the input (the input itself arrives intact at `0x01`/`0x04` in
**all eight** captures), and the two-sided evidence is already in hand: halve the datum and it
stops.

⚠ **What is still NOT known**, stated so the next pass does not over-read a good result: *why* the
assembly saturates. `PSHIFT=2` is §227's documented two-sided control and **contradicts the
MEASURED Q1.22 scale**, so "set the total shift to 23" remains forbidden as a fix. The candidates
are the shift, the `iw45` word's own decode, and the unseeded cursor base (§70 confirmed present,
refuted as the *discriminator* but not as a *contributor*).

⚠ Grade: MEASURED — 8 programs, ONE machine, identities fingerprinted, the confound §71 named
explicitly tested and the previous attribution refuted by it.

## 73. ★★★★★ THE DEFECT IS NAMED, AND A PRE-REGISTERED DECODE RIVAL FIXES IT
§72 left *"the kernel's assembly saturates, somewhere between `iw2` and `iw45`"*. A **matched pair**
closes it: `prog06_ensemble` (input `0x01` = 152 576, hand-off ends at **0**) and `prog56_mix_up`
(157 952, ends **RAILED**) — same machine, inputs **3.5 % apart**, opposite failures, running the
**byte-identical shared kernel**. Tracing the `tA` column:

| | |
|---|---|
| `iw7` `0090A011C8` (ACT 0x08) | tempA ← **−23 296 / 188 160 / −14 848** — a real sample, all three |
| **`iw25` `00002002D9` (ACT 0x19, `SRC 0x0B`)** | tempA ← **0 / −8 388 608 / +8 388 352** — ★ **OVERWRITTEN with zero or a rail** |
| `iw39` (`SRC 0x19` = tempA, an **anchored** source) | reads the garbage |
| `iw40` | multiplies it |
| `iw45` | stores the result into the hand-off cell `0x05` |

⇒ ★★★ **Both failure modes are ONE defect.** Whether the hand-off ends at `0` or at the rail is
only whether `iw25`'s garbage was `0` or `±8 388 608`.

### ★ And `iw25` is exactly the case a COMMITTED decode rival already covers
`iw25` is **class 2 — not a delay word** — and its source is `SRC 0x0B`. The device ships:

> `UPD6383_SRC0B2`: *0 = SHIPPED: `SRC 0x0B` is the delay-read register everywhere;
> 1 = RIVAL: **on a word with no delay access it is `mem[ptr]`***

Predictions committed **before** the run (`data/PREDICT_SRC0B2_2026-09-13.md`). Result:

| # | prediction | result |
|---|---|---|
| **P1** | tempA at `iw25` becomes sample-like | ✅ **−23 296 / 188 160 / −14 848** |
| **P2** | `mix_up`'s hand-off stops railing | ✅ **−8 388 608 → +263 946** |
| **P3** | `ensemble`'s hand-off stops being 0 | ✅ **0 → −12 903** |
| **P4** | internal null: `0x01`/`0x04` unchanged | ✅ **identical in all three** |
| **C1** | the flanger not broken | ✅ **2 912 280, unchanged** |

★★★★★ **And P1 is a SEMANTIC confirmation, not just a better number: the values tempA receives are
`−23 296 / 188 160 / −14 848` — EXACTLY each program's own cell `0x04`, the DI1 input latch.**
Under the rival, `iw25` reads **the input sample**; under the shipped reading it reads a **stale
delay register**. An input stage that reads the input latch is the reading that makes sense of the
word; the shipped one never did.

★ **Stable across the frame pair**, so it is not a one-frame transient: `mix_up` 263 946 → 270 950,
`ensemble` −12 903 → −33 547 — both moving with the audio and staying sane.

### ⚠ NOT PROMOTED, and three reasons why
1. **My own pre-registration forbids it**: *"one kernel site passing is not the 1 610-word
   population `SRC 0x0B` spans."*
2. ⚠ ~~**It does not fix everything.** `prog04_flanger` is unchanged and still climbs~~
   ⛔ **RETRACTED — that was MY instrument, not the arm.** `pickup_cells.py` reads the cell's
   **first touch**, which is what the frame *inherits from its predecessor*, so **an arm's effect
   shows up one frame LATE**. Reading the frame's own STORES instead: with the arm the flanger's
   `iw45` stores **−21 382**; without it, **+8 388 607**. ⇒ **the arm fixes the flanger too**, and
   "a second path to full scale" is **not supported** by that evidence. ⚠ The lag is now documented
   in the tool, and the rule is: **to grade an arm, read the frame's own stores, not the cell it
   inherited.** (§72's separate point stands: the flanger was never healthy at the default — its
   own `iw45` stored the rail.)
3. Promotion needs the **catalogue regression at the true default**, which is the one measurement
   this session never had (every prior sweep carried the datum-halving arm, §72).

⇒ **What it IS:** the input stage's first real candidate, passing five pre-registered criteria
including a semantic one, at the site a confrontation identified. ⇒ **What to do next:** run the
catalogue at the **true default**, arm off vs on, and grade `0x05` across all 38 programs.

⚠ Grade: MEASURED, pre-registered, with an internal null and a control that both held, and the
limitation that it leaves one of the three test programs unfixed stated in the same breath.

## 74. THE INSTRUMENT THAT WOULD HAVE CAUGHT §70–§73 ON DAY ONE — and a process error of mine
§72 found the kernel's input stage saturating the hand-off cell in **8 of 8** programs, at the
device default, and **nobody had noticed for the life of the project**. That is an instrument
failure, and it is worth naming precisely because the device **already had a saturation census**.

`§223 §S1` counts clips **per INSTRUCTION** — `m_s1_clip[bank][iw]`. By it, `iw45` had been
clipping in every capture ever taken. The question that mattered was never *"which word clips"*; it
was ***"which CELL receives a clipped datum"*** — and no instrument answered it.

⇒ **`§74 §S1C` ships**: the same event, indexed by `m_dp`, which is already in scope at the single
point where *"this value does not fit the datum"* is knowable. Read-only, unconditional, beside the
census it complements; the four per-unit base cells (`05 / 07 / 85 / 87`) are **flagged in the
report**, because a clip landing on one of them is the clip that silences a body.
✅ Compiles clean, binary at full size.

★ **The method point, which generalises** (and echoes §10's): §10 said *"when successive plausible
discriminators all fail, suspect the instrument before inventing a fourth candidate."* This is the
other half — **when a defect survives every census you own, ask what your censuses are INDEXED BY.**
`§S1` was the right measurement with the wrong key.

### ⚠ AND A PROCESS ERROR, recorded because it cost real time
I started the catalogue regression in the background and then **ran a 20-minute `-j3` build while
it was capturing**. Two consequences, both mine:
1. **The emulator was starved.** MAME needs real-time CPU to reach its trace frame inside the
   180 s timeout; competing with three compiler jobs, the sweep managed **one capture in 45
   minutes** instead of ~27.
2. ⚠ **The binary changed mid-experiment.** `t0` was captured with the pre-`§S1C` build and the
   rest with the post one. `§S1C` is provably behaviour-neutral (it increments a counter and prints
   at exit; no ALU, store or pointer path is touched) — but *"provably"* is an argument, not a
   measurement, so **`t0` is re-captured on the final binary and compared** rather than assumed.
⇒ ★ **RULE, beside "timeout-wrap every launch": never build while a capture is in flight.** The
build tree and the capture share one machine, and the capture is the one with a deadline.
⚠ **AND THE SWEEP WAS THEN OOM-KILLED** partway (5 of 23 on the first arm). `MEMORY.md` already
carries *"two OOM kills during `build.sh` rsync"*; this is the same resource contention reaching a
different victim. ⇒ **size a sweep to what the box can finish**: it was re-run as **8 programs ×
2 arms on ONE binary** (~32 min) rather than 23 × 2 across a rebuild, which is both survivable and
free of the machine difference the first attempt had acquired.

⚠ Grade: the instrument is SHIPPED and compiles; its first catalogue-wide reading is pending the
regression. The process error is recorded as fact, with its remedy applied.

## 75. THE NEW CENSUS'S FIRST READING — the clipping is much broader than the hand-off cell
`§74 §S1C` ran for the first time on the regression's own captures (`prog03_enhancer` and
`prog04_flanger`, true default). It pays for itself immediately, and **not by confirming what I
expected**:

| cell | enhancer | flanger | |
|---|---:|---:|---|
| **`0x06`** | **61.1 %** | **65.5 %** | ⚠ **the single largest clip target, by 10×** |
| `0x8B` | 12.7 % | 13.0 % | |
| `0x94` | 8.5 % | 8.6 % | |
| **`0x05`** | 5.9 % | 4.3 % | ★ the hand-off cell §70–§73 chased |
| `0x07` | — | 0.8 % | ★ the other per-unit base cell |

and the global rate from `§S1` beside it: **6.1 % of conversions clip in the quiet bucket, 19.0 %
in the loud one.**

⇒ ★★ **Cell `0x05` is not the main event — it is 4–6 % of the clipping.** The session found it
because it is the cell a *body reads*, so its clip is the one that silences audio; but the machine
is saturating **everywhere**, and `0x06` takes ten times more of it.
> ⛔⛔ **CORRECTION (§89) — READ THIS BEFORE QUOTING THE TABLE.** *"Cell `0x06` takes 57–65 % of the
> clipping"* **overstates what this census measures.** It is indexed by `m_dp` **at the moment of
> the conversion**, so it counts every clipping conversion that happened **while the pointer rested
> on a cell** — not the clipped datums that cell actually **received**. MEASURED in one auto-wah
> frame: cell `0x94` has **45 rows and only 5 carry a store**; cell `0x06` has **20 and 10**. ⇒ a
> cell the pointer merely **passes through** during heavy arithmetic accumulates counts it never
> took. **Use the ranking as a CANDIDATE FINDER, not a verdict** — which it earned: it independently
> named cell `0x12` in `prog52_auto_wah`, a real store target that really is railed (§88).
> ⚠ And `m_dp` is the **D-RAM pointer**, not the internal register-file index (`addr8` on a class-1
> non-escape word) — so *"cell 06"* here is **D-RAM `0x06`**, NOT register `[06]`, the per-unit
> output level named PROVEN BY CONSTRUCTION in the listings. I conflated those two when I first
> read this table. ⚠ That does **not** demote
§70–§73 (a clip on `0x05` still silences a body, and the arm still fixes it) — it says the
input-stage defect is **one visible symptom of a machine-wide scale problem**, which is §62's
original reading arriving a third time, now with a number on it.

★ **This is what the instrument was built for.** `§S1` had been reporting a 6–19 % clip rate all
along and nobody could act on it, because a rate per *instruction* does not say *what gets
poisoned*. One re-indexing, and the answer is a ranked list of cells.

⚠ Grade: MEASURED, first reading, two programs. ⚠ It counts **conversions**, not stores (one store
calls `acc_to_datum()` up to five times), so the percentages are a **distribution over clipped
conversions**, not a store census — read the ranking, not the absolute counts.

## 76. ★★★★★ PROMOTED — the gate is met, 8 FIXED / 0 BROKEN, and verified with NO ENVIRONMENT SET
§73 named three blockers to promoting `UPD6383_SRC0B2`. All three are now discharged.

### The gate (`dsp/tools/src0b2_regression.py`, `data/src0b2_gate_2026-09-13.txt`)
8 programs spanning modulation / delay / detector families, **one binary, both arms, the TRUE
DEVICE DEFAULT**, every identity fingerprinted. Graded on the hand-off cell **as the frame leaves
it** (not what it inherited — §73's own lesson):

| TYPE | program | arm OFF | arm ON |
|---|---|---:|---:|
| 0 | chorus | **0** | 113 541 |
| 2 | enhancer | **8 388 607** | 145 244 |
| 3 | flanger | **8 388 607** | −21 382 |
| 5 | ensemble | **0** | −33 547 |
| 8 | multi tap delay | **−8 388 608** | −143 401 |
| 13 | compressor | **−8 388 608** | −347 997 |
| 14 | **no operation** | **−8 388 608** | −239 616 |
| 22 | mix up | **−8 388 608** | 270 950 |

**FIXED 8 · KEPT 0 · STILL 0 · BROKEN 0.** ★ Every result lands in the 10⁴–10⁵ band — the same
order as the input latches feeding them. ★ And TYPE 3 at arm OFF stores `8 388 607`, confirming
§72's correction that the flanger was never the healthy one.

### ⚠ THE BLAST RADIUS — the test §138 was refused by, applied to my own candidate
| | |
|---|---:|
| corpus | 3 057 words |
| `SRC 0x0B` words | 106 (3.5 %) |
| … class 1 (delay) — **untouched in both arms** | 99 |
| **… non-delay — the arm's ENTIRE blast radius** | **7 words = 0.23 %** |
| distinct shapes | **2** — kernel `iw25` (`000.2.00.2D9`) and 6 × `020.2.00.2C7` in `prog06_ensemble` |

★★ **Both shapes are exercised by the gate** (the kernel word by all 8 programs, the ensemble's six
by TYPE 5) — so this is not 7 words of which one was tested. ⚠ Compare §138, refused partly for
rewriting **35.5 %** of the corpus.

⛔ **AND IT CORRECTS MY OWN PRE-REGISTRATION.** I wrote *"one kernel site passing is not the
1 610-word population `SRC 0x0B` spans."* **That number was wrong** — 1 610 is the `SRC 0x00`
population; `SRC 0x0B` spans **106**, and the arm touches **7**. My stated blocker rested on a
conflation, and measuring it is what dissolved it.

### ✅ THE §56 RULE, APPLIED: re-run with NO environment set at all
Not via the harness (which passes its own arms) — the emulator invoked directly with **no
`UPD6383_*` variable except the read-only trace instrument**. The banner confirms what was actually
in force: `PSHIFT = 0` (total 22, the true default), `C8SHIFT = 0`, `SRC0B2 = 1` (the new default).

| `prog00_no_operation`, same instant | before | after |
|---|---:|---:|
| hand-off cell `0x05` | **−8 388 608** ⛔ | **−239 616** ✅ |
| input latches `0x01`/`0x04` | −286 976 / −166 400 | **unchanged** |

★ And `§74 §S1C` corroborates independently: **cell `0x05` has dropped out of the top-6 clip
targets entirely.**

### ⚠ WHAT THIS IS NOT
* **Not "the DSP works now."** The hand-off is a **precondition**, not audio. Whether the bodies
  compute the right thing is untouched by this.
* **Not the end of the scale problem.** `§S1C` still reports **cell `0x06` at 56 %** and `0x07` — the
  *other* per-unit hand-off cell — at **7.2 %**. §75's machine-wide saturation stands; this fixed
  one path through it.
* **Not a claim about the chip's audio.** Nobody has heard the real instrument
  (`kn5000-hardware-inaccessible`). The case rests on the ROM's own structure: an input stage that
  reads the input latch, versus one that reads a leftover.

⚠ Grade: **PROMOTED.** Pre-registered, 8 of 8 with zero regressions on one binary at the true
default, blast radius measured before promoting, semantic confirmation, re-verified with no
environment set. The control `UPD6383_SRC0B2=0` restores the previous reading.

## 77. ★★★★★ THE ORACLE MEETS THE LLE: all five EQ bands carry signal, and the LLE's own pointers reproduce the HLE's CASCADE
§76 fixed what the bodies are *handed*. The standing goal is to use the HLE as an **oracle against
the LLE**, and `dsp/hle/lle_trace_diff.py` exists to do exactly that — it confronts a live per-word
LLE trace with the validated HLE biquad. So: capture the parametric EQ at the **true default with
the promotion in** (hand-off cell now leaves as **56 033**, a real sample) and run it.

### ⛔ FIRST: THE ORACLE WAS SILENTLY BROKEN — BY ME, TODAY
It reported **"0 informative words … the frame carried little signal"** on a trace full of non-zero
products. Its row parser ended `…([Y.])\s+(-?\d+)\s*$` — **anchored on `L` being the last column**.
Earlier today I shipped the `LW` operand-latch flag *after* `L` (§10), and the regex stopped
matching. It parsed **zero rows** and said so in the vocabulary of *"no signal"* rather than
*"I cannot read this file."*

⇒ **The HLE→LLE oracle — the project's stated method — had been unusable for exactly as long as
nobody ran it against a fresh capture, and I broke it myself while adding an instrument.**
⇒ ★ **RULE: never anchor a trace parser on the last column.** Fixed to tolerate trailing fields, with
that reasoning in the source.

### ✅ THE CONFRONTATION (`data/eq_oracle_confront_2026-09-13.txt`)
**All five bands, coefficients read from the trace's own cursor, and — the line that matters —**

| band | cursor | `b1` | `b0` | `b2` | `−a1` | `−a2` | operand cells | **signal?** |
|---|---|---:|---:|---:|---:|---:|---|---|
| 0 | 0x00–0x05 | −0.4977 | +0.2500 | +0.2478 | +0.9954 | −0.9911 | `64 50 51 52 53` | **YES** |
| 1 | 0x06–0x0B | −0.4953 | +0.2500 | +0.2456 | +0.9905 | −0.9824 | `51 54 55 56 57` | **YES** |
| 2 | 0x0C–0x11 | −0.4900 | +0.2500 | +0.2413 | +0.9800 | −0.9650 | `55 58 59 5A 5B` | **YES** |
| 3 | 0x12–0x17 | −0.4780 | +0.2500 | +0.2329 | +0.9559 | −0.9314 | `59 5C 5D 5E 5F` | **YES** |
| 4 | 0x18–0x1D | −0.4483 | +0.2500 | +0.2172 | +0.8967 | −0.8687 | `5D 60 61 62 63` | **YES** |

★★ **`signal: YES` on all five.** Before §76 the body was fed a rail; these bands could not carry a
signal at all. This is the first time the EQ's whole cascade has been observed live in the LLE.
★ The coefficients are a coherent five-band peaking family — `b0` constant at **+0.2500**, the
recursive pair **pre-negated** exactly as `algorithms/N-SINGLE-DELAY-RECURRENCE-2026-09-12.md §10` documents, poles marching down
from 0.9954 to 0.8967 as the band centres rise.

### ★★★★★ AND THE TOPOLOGY CROSS-VALIDATES — 4 of 4
§58 established **from the HLE** that `parametric_eq` is a **SERIES CASCADE**: band *k* filters band
*k−1*'s output. That was a statement about the reference model. The LLE's own **operand pointers**,
which nothing in this session tuned, say the same thing:

| | band *k*'s FIRST operand | is it a state cell of band *k−1*? |
|---|---|---|
| band 1 | `0x51` | ✅ in `{50,51,52,53}` |
| band 2 | `0x55` | ✅ in `{54,55,56,57}` |
| band 3 | `0x59` | ✅ in `{58,59,5A,5B}` |
| band 4 | `0x5D` | ✅ in `{5C,5D,5E,5F}` |

**4 of 4.** Band *k* opens by reading band *k−1*'s state — and band 0 alone opens on `0x64`, outside
the chain, which is where the input enters. ⇒ ★★★ **The HLE's cascade and the LLE's pointer walk are
the same topology, derived independently.** §58 reached it by reading `effects.py`; this reaches it
by reading the chip's own `m_dp` sequence out of a live frame.

### ✅ And the accumulator op, confirmed on live audio
`--ops`, 36 informative words (it had **0** before the parser fix):

| `f31` | live behaviour | reading |
|---|---|---|
| **0** | **LOAD 19** / ACC 1 | `acc ← P` ✅ |
| **1** | ACC 13 / LOAD 1 | `acc += P` ✅ |
| **2** | UNCH 9 / LOAD 1 | unchanged ✅ |
| 3, 4, 5 | 2, 2, 3 occurrences | still **OPEN** — §63–§69's population |

⇒ the three decoded codes are confirmed **on live signal** rather than on the synthetic self-test,
which is what `lle_oracle.py`'s own header asked for. The high codes remain the open queue, and
§64's aiming constraint still applies to them.

⚠ **What this is NOT**: the values are not checked sample-for-sample against the HLE's output — that
needs the oracle's numeric mode with this program's cursor base (the default-mode run reports
`cur 0x60..0x64 MISSING`, a parameter mismatch, not a divergence). **Topology, coefficients, signal
presence and the accumulator op are cross-validated; the arithmetic is not yet.** That is the next
step and it is now unblocked.

⚠ Grade: MEASURED against a live trace at the true default with the promotion in, identity
fingerprinted. The cascade check is 4/4 and stated as a test, not an eyeball.

## 78. ★★★★★ COVERAGE 41.5 % → 49.2 %: `ACT 0x0D`/`0x0E` ANCHORED, because §76 refuted the caveat
The coverage worklist ranked `ACT 0x0D` (123 occurrences unblocked alone) and `ACT 0x0E` (110) as
queue items 2 and 3. Both were **already closed** as `ACT 0x0E` = **selector 7** by two independent
routes — **§234 FROM DISK** (the EQ's entry window against the designer's biquad, **1 of 49**, with
a junk-pre-load control that kills the runner-up) and **§58 FROM THE HLE ORACLE** (the cascade
topology admits one clean copy to the first band only; selector 7 alone delivers it).

They were nevertheless held in the SPECULATIVE tier, for **one stated reason**: §61 measured
`prog32_distortion` **STATIC at selector 7**, so §266 ruled the finding must be carried *"as FOR
THE EQ, not as a global decode."*

### ⇒ That reason is REFUTED, and by this session's own input-stage work
`prog32_distortion` re-captured at the **true default with §76's promotion in**:

| | |
|---|---|
| hand-off cell `0x05` | **−102 851 / −127 919** (was **railed at 8 388 607**) |
| body rows whose accumulator moves frame-to-frame | **42 of 42** |
| body rows whose memory moves | 33 of 42 |

★★ **The distortion was never dead because of the `ACT 0x0E` selector. It was dead because its
input cell was railed.** §61's tension — *"the selector that is right for the EQ leaves the
DISTORTION dead"* — had a third explanation neither side considered, and it was a defect two stages
upstream.

⇒ the pair moves from `_ANCHORED_*_SPEC` into `_ANCHORED_ACT` (`dsp/tools/dsp_disasm.py`), mirrored
into `lo_act_anchored()` (`upd6383d.h`) so the two predicates cannot drift.

### ★★★★★ THE RESULT
| | before | after |
|---|---:|---:|
| executable words, 38 body images | 1 234 / 2 974 | **1 464 / 2 974** |
| **coverage** | **41.5 %** | **★ 49.2 %** |
| distinct undecoded words | 443 | **351** (−92) |
| distinct undecoded FAMILIES | 133 | **126** (−7) |
| frame floor as linked | 38.9 % | **42.6 %** |

**+230 executable words** — against the worklist's predicted 233 for this pair, which is the
cross-check that the leverage table was counting the right thing.

★ And it is visible in the listings, which is the point: words that rendered as
`?word … [SPECULATIVE (prospective, not measured)]` now render as instructions —
`ld (p),(p)+11`, `ld acc,(p)+0`. 40 listings regenerated, MAME rebuilt clean, the 24 documentation
pages regenerated and `test_hle_permanence.py` still **24 pages / 46 `cpp` blocks byte-identical**.

⚠ **What this does NOT claim**: that `ACT 0x0D`/`0x0E`'s *arithmetic* is verified sample-for-sample
— §77's confrontation validated topology, coefficients, signal and the accumulator op, not the
values. What changed here is that the **one documented objection** to treating the pair as a global
decode was a misattribution, and removing it lets a decode the project had already closed twice
count as closed.

⚠ Grade: the anchoring rests on §234 + §58 (both pre-existing and independent) plus a MEASURED
refutation of the caveat that blocked them. The coverage delta is mechanical once the predicate
changes.

## 79. ★★★★★ COVERAGE 49.2 % → 58.6 %: `SRC 0x00` ANCHORED — the predicate was lagging the decode
`SRC 0x00` is the corpus's **largest single open axis**: 648 occurrences, and the **sole** reason
`alu_decoded()` refused **348** of them (`dsp/tools/decode_leverage.py`, now committed — the old
leverage table had no producer).

### Both populations already had SHIPPED, evidenced readings
| population | count | reading | evidence |
|---|---:|---|---|
| class A **&** `hi12[9:8] == 1` | 41 | **C-RAM[cursor]** — the coefficient | §145/§148, **shipped** behind SPEC bit 59 (**set in the default mask**), three pre-registered predictions incl. a known-answer control, **20 of 20** live |
| everything else | 607 | **`mem[ptr]`** | **§233: SEVEN readings enumerated, SIX REFUTED** — the SINGLE DELAY's lag-1001 ROM product accepts `mem` and **only** `mem`. Supersedes the old *"1 of 6 enumerated, no independent support"* |

⇒ the decode existed on both sides; only the **disassembler's predicate** had not caught up — the
same shape of lag as §78's `ACT 0x0D`/`0x0E`.

★ **Two readings for one code is legitimate here** because the split is a function of the word's
**own fields** (`class4`, `hi12[9:8]`), so a disassembler computes which applies with no context at
all. `alu_decoded()` asks *"is this word's semantics determined"* — it is.

⚠ **And it is NOT anchored on a majority.** §7's naive whole-code test was 1 005/1 413 with a
232-row residue that looked like a **third** population. §8–§10 dissolved it: those rows never
**drove** the operand latch, which was invisible until the `LW` column existed, and **57 of 57**
undriven rows hold with zero exceptions. **The partition is clean because that sub-question was
closed, not in spite of it.**

### ★★★★★ THE RESULT
| | §78 | now |
|---|---:|---:|
| executable words | 1 464 / 2 974 | **1 743 / 2 974** |
| **coverage** | 49.2 % | **★ 58.6 %** |
| distinct undecoded words | 351 | **287** (−64) |
| distinct undecoded FAMILIES | 126 | **114** (−12) |
| frame floor as linked | 42.6 % | **48.1 %** |

**+279 words.** Cumulative from this session's start: **41.5 % → 58.6 %, +509 executable words.**
Listings regenerated, MAME rebuilt clean, docs regenerated, HLE permanence intact.

### ⚠ AND A CIRCULARITY I REFUSED ON THE WAY
The next item on the leverage table is **`f31 = 2` off class 8** (161 occurrences). I checked it
against the live EQ trace, which shows `f31 = 2` on classes 2/3/5/6/8 leaving the accumulator
unchanged with **large non-zero products** — apparently decisive.
⛔ **It is not evidence.** The device *implements* `f31 = 2` as HOLD, so the trace is the device
obeying its own code — the §3 warning in the coverage worklist, exactly. **Not anchored.** The real
question there is the one `alu_decoded()`'s own comment states: on class 8 the biquad **forces** the
identity, but elsewhere `f31 = 2` could be a **wrap/limit that simply does not fire on an in-range
sum** — and §75's finding that **19 % of conversions clip in loud passages** makes that *more* live,
not less. Deciding it needs the sample-for-sample HLE confrontation (§77's outstanding half), not a
predicate edit.

⚠ Grade: both anchorings rest on pre-existing MEASURED/FORCED determinations plus a closed
sub-question; the coverage delta is mechanical once the predicate changes. Nothing new was decided
about the chip here — what changed is that the disassembler now states what the project had already
established.

## 80. ★★★★★ COVERAGE 58.6 % → 67.8 %: the predicate was asking the DELAY ESCAPE the wrong questions
The leverage table listed *"class 1 admitted — 52"*. That figure was **an artefact of the framing**,
and working the item exposed why.

A **class-1 format escape** is an external delay-DRAM access. Its semantics are **FORCED**:
* direction from `addr8` bit 6 — `0x20`/`0x30` READ, `0x60` WRITE (adjudication-round5 §3);
* address = `DESCRIPTOR_CELL[k] + G` by the **IDENTITY map**, **PROVEN BY CONSTRUCTION** — the k-th
  escape of a body takes the k-th cell of that body's own descriptor block, which is why **no
  address appears in the word**.

★★ **And it never reaches the ALU** — the device's own `is_dram` branch **returns before it**. So
`decoded()` was grading 276 fully-determined words on **anchored SRC / ACT / `f31`: fields they do
not use.** They were counted as undecoded for failing a test that does not apply to them.
> ⚠ **QUALIFIED BY §91.** *"Never reaches the ALU"* is the device's structure, and at least one of
> these words — `iw331` (`088016040E`) — **leaves ACCB at exactly the positive rail anyway**, which
> "an external delay write" does not describe. Either the device has an extra accumulator effect the
> chip does not (a bug beside this anchoring), or the delay write genuinely does more than the
> access (and then "executable" is too strong for these 276). **The anchoring rests on the
> ADDRESSING, which is forced; the accumulator effect was neither examined nor claimed.**

| | |
|---|---:|
| class-1 escapes in the corpus | **276** |
| … inside the **validated** `addr8` set (`0x20`×106, `0x30`×58, `0x60`×112) | **276** |
| … outside it (device traps; so does the predicate) | **0** |
| … that `decoded()` accepted before | **0** |

⚠ The direction rule is scoped to the addr8 values it was validated on, and `dram_dir()` answers
`None` outside them — the restriction costs nothing today and still **refuses to answer for an
addr8 nobody validated**.

### ★★★★★ THE RESULT
| | §79 | now |
|---|---:|---:|
| executable words | 1 743 / 2 974 | **2 015 / 2 974** |
| **coverage** | 58.6 % | **★ 67.8 %** |
| **frame floor as linked** | 48.1 % | **★ 63.0 %** |
| distinct undecoded words | 287 | **263** |
| distinct undecoded FAMILIES | 114 | **95** (−19) |
| tier-2 (operation known, not executable) | 329 | **57** |

**+272 words.** Cumulative: **41.5 % → 67.8 %, +781 executable words.**

### ★ AND THEY NOW RENDER AS WHAT THEY ARE
Making `decoded()` true was not enough: the listing rendered them through the **ALU** path as
`ld ?` — *"a decoded word whose operand cannot be named"* — because the operand is a delay address,
not an ALU source. That is the same confusion, one layer up. New mnemonics, placed **before** the
ALU branch:

```
   w51   0880130407   dly.r  dsc[k],p+48        (was:  ld.st  acc)
   w0    088013000B   dly.r  dsc[k],p+48        (was:  ld     ?  )
   w26   08801602D9   dly.w  dsc[k],p+96
```
164 `dly.r` + 112 `dly.w` across the listings.

### ⛔ AND A MISTAKE OF MINE, CAUGHT BY THE OUTPUT
I wrote fresh `is_dram()` and `dram_dir()` helpers — **both already existed** in `dsp_disasm.py`,
120 lines further down, and the existing `dram_dir()` returns `"READ"`/`"WRITE"`, not `'R'`/`'W'`.
Python took the later definitions, so my renderer compared against the wrong literal and printed
**`dly.w` for every READ**. The duplicates are deleted and the renderer uses the existing API.
⇒ ★ **Third time today the same rule bit: read what the project already has before adding it.**
(§66: a program already characterised; §69: a bit already decoded; here: a function already
written.) It was caught only because the *rendered output* was checkable against `addr8` — a
predicate change alone would have been silently wrong.

⚠ Grade: the decode is PRE-EXISTING and FORCED; what changed is that the coverage predicate stopped
applying ALU tests to non-ALU words. MAME rebuilt clean, 24 doc pages regenerated, HLE permanence
intact.

## 81. COVERAGE 67.8 % → 68.0 %, and TWO REFUSALS I am not making
Small gain, and two items I worked and **declined to anchor** — which matters more than the 0.2 %.

### ✅ `SRC 0x0B` anchored (+6 words) — closing the same day's loop
The 7 undecoded `SRC 0x0B` words turned out to be **exactly the blast radius of §76's promotion**:
kernel `iw25` and the six `020.2.00.2C7` in `prog06_ensemble`. I promoted that decode into the
device today on a pre-registered gate (8 programs, **8 FIXED / 0 BROKEN**, plus the semantic
confirmation that `iw25` then loads tempA with each program's own DI1 latch) — and the
disassembler's predicate was still refusing the very words the gate exercised. Same two-population
shape as `SRC 0x00`, split by the word's own class. Mirrored into `lo_src_anchored()`.

### ⛔ REFUSED #1: `f31 = 2` off class 8 (203 occurrences — the biggest item left)
`alu_decoded()` admits `f31 = 2` **only on class 8**, and its own comment says why: the two
surviving candidates — a plain no-op and `AND 2^23−1` — **are both the identity when the sum is in
range**, and on class 8 the biquad forces it in range. So the question is measurable: *off class 8,
does the accumulator ever leave datum range at those words?*

Over 10 live captures, 216 executions of `f31 = 2` on classes 2/3/5/6/A:

| | |
|---|---:|
| accumulator **in** datum range (the two candidates agree) | **207** |
| accumulator **OUT** of range (they **differ**) | **9** — all class 2, up to **1.3×** the rail |

⇒ **The ambiguity is observable.** 96 % agreement is not a decode, and the 4 % is exactly the part
that would make it one. **Not anchored.**
⚠ And note what I did *not* use: the live trace shows every `f31 = 2` word leaving the accumulator
unchanged with large non-zero products, which looks decisive and **is circular** — the device
*implements* HOLD, so that is the device obeying its own code (the coverage worklist's §3 warning).

### ⛔ REFUSED #2: C-format (13 occurrences)
Opcode `0x620` is *"IMMEDIATE LOAD … **MEASURED 57/57** for this opcode"* — the operation is
settled. But the same annotation ends *"destination register `lo12` **UNKNOWN**"*. An immediate
load whose destination is unknown is **not executable**; that is precisely the tier-2 state
(`status()` reports it, `decoded()` must not). **Not anchored.**

### Where that leaves it
| | |
|---|---:|
| executable words | **2 021 / 2 974 = 68.0 %** |
| undecoded occurrences | 1 007, of which **509 are ONE decision away** |
| undecoded FAMILIES | 94 |

⚠ **And the top of the remaining table is now dominated by genuinely open questions, not by lag:**
`f31 = 2` off class 8 (203, measured open above), the `f31` codes 3/5/4/7 (117 — §63–§69's bit-5
page, shown undecoded today), the bit-7 store gate (52 — the device's own log calls its rule *"the
CO-EQUAL survivor"*, i.e. rival gates fit equally), `SRC 0x11` (50 — recorded as needing a device
arm, and the HLE does not model the second accumulator so the oracle cannot reach it).
⇒ The easy harvest — predicate lagging an existing determination — is **finished**. What remains
needs new evidence, and the instrument for producing it is §77's numeric confrontation, which
cannot run yet (below).

### ⚠ A THIRD INSTRUMENT DEFECT, found while trying to produce that evidence
`lle_trace_diff.py`'s **numeric** mode ignores `--base` entirely: it takes its cursor base from
`sections_from_capture()`, which supplies a **different geometry** (0x60…, WSA1R-shaped). Asked for
KN5000 section 0 at base `0x00` it still reports `cur 0x60..0x64 MISSING` — and "MISSING" reads as
a divergence rather than as "I was pointed at the wrong cursor."
⇒ **The sample-for-sample confrontation has never been runnable against a KN5000 trace.** Fixing it
properly means building the oracle from the coefficients the trace itself carries (which
`--eq-trace` already extracts) rather than from a foreign capture. That is the next instrument job,
and it is what `f31 = 2` is waiting on.

⚠ Grade: the anchoring rests on today's own gated promotion; both refusals are MEASURED, and the
circular argument I could have used for the first one is recorded so nobody reaches for it later.

## 82. ★★★★ THE SAMPLE-FOR-SAMPLE CONFRONTATION RUNS AT LAST — and its failures are the RAIL, not a decode
§77 cross-validated topology, coefficients, signal and the accumulator op, and left the
**arithmetic** owed. §81 found why it could not be run: `lle_trace_diff.py`'s numeric mode ignored
`--base` and took its cursor geometry from a **foreign capture** (0x60…), so a KN5000 trace came
back `cur 0x60..0x64 MISSING` — a wrong-cursor error wearing the words of a divergence.

`--numeric` now builds the comparison from **the coefficients and operands the trace itself
carries**, which is the only way the two sides describe the same filter.

### ⛔ AND IT TAUGHT ME THE DATAPATH BY BEING WRONG
The first version paired `coef[k]` with `L[k]`. Every step disagreed — but the trace's `P` at step
*k* came out **EXACTLY** equal to my term at step *k−1*:

```
   band 2   step 2  my term +274 877 874 176   trace P +274 877 874 176
            step 3  my term +265 266 234 489   trace P +265 266 234 489
            step 4  my term +1 077 548 288 570 trace P +1 077 548 288 570
```

That is the project's decoded **one-slot pipeline** (`P[N] = coef[N−1] × L[N−1] >> P_SHIFT`,
`algorithms/N-SINGLE-DELAY-RECURRENCE-2026-09-12.md §10`) appearing as an off-by-one in my own arithmetic. ⇒ ★ the rule is
re-confirmed *by an independent implementation tripping over it*, which is worth more than the
tool having been right first time.

### ★★★ THE RESULT, with the pairing corrected
| band | pipeline `P == coef[k−1] × L[k−1]` |
|---|---|
| 0 | 0 / 4 |
| 1 | 0 / 4 |
| **2** | **3 / 4** |
| **3** | **3 / 4** |
| **4** | **3 / 4** |

★★ **In bands 2, 3 and 4 the chip's product equals the biquad's term EXACTLY on three of four
steps** — full 44-bit integers, no tolerance. The three failures are **all step 1**, and they share
one signature:

| band | want | trace `P` | |
|---|---:|---:|---|
| 2 | +538 774 208 512 | **−**538 774 144 286 | sign flipped, `Δ` 64 226 |
| 3 | −525 528 140 617 | **+**525 528 203 264 | sign flipped, `Δ` 62 647 |
| 4 | +492 943 966 208 | **−**492 943 907 445 | sign flipped, `Δ` 58 763 |

⇒ **opposite sign, magnitude equal to ~1 part in 10⁷** — and in every case the operand of that step
is sitting **AT the saturation rail** (`−8 388 608` / `+8 388 607`). A one-LSB asymmetry at the rail
plus a sign-boundary effect accounts for both the tiny delta and the flip.

⇒ ★★★ **The arithmetic divergence is the SATURATION, not a decode gap.** §75 measured the machine
clipping 19 % of conversions in loud passages; this is that clipping arriving in the biquad's own
terms, at exactly the steps whose operand has been driven to full scale.

⚠ **Bands 0 and 1 fail on all four steps and are NOT explained by this** — their operands are small
(5×10⁴ … 2×10⁶, nowhere near the rail) and the deltas are a few per cent, not a sign flip. ★ Band 0
also executes its cursor cells **out of order** (`0x01 0x02 0x03 0x04 0x00` — the wrap comes last),
so the "previous slot" is not the previous cursor cell there. Those two bands are the next
worklist item and they are a *different* phenomenon from bands 2–4.

⚠ **A LIMITATION OF THE TEST, stated:** the running-sum check reports `NO` on every band, and that
is **the check being too strict, not a finding** — an `ACT` term adds the bus on top of the product,
so `acc[k] == acc[k−1] + P[k]` cannot hold wherever the word carries one. It needs the bus term
subtracted before it means anything; until then read only the pipeline column.

⚠ Grade: MEASURED on a live KN5000 frame at the true default with §76's promotion in. **Nothing
anchored** — this moves no coverage. What it buys is the first working numeric channel between the
HLE's algebra and the LLE, plus a bounded, named next question (bands 0/1).

## 83. ★★★★★ COVERAGE 68.0 % → 74.6 %: `f31 = 2` off class 8, settled by the RIVAL having its own predicate
§81 measured this code's ambiguity as **observable** (9 of 216 live executions leave datum range,
up to 1.3× the rail) and refused to anchor it. That refusal was right on the evidence I had. The
evidence I did not have is that **the rival is not hypothetical — it is shipped, and it has its own
six-field predicate.**

### The argument
`alu_decoded()` admitted `f31 = 2` only on class 8, because the joint solve left two candidates —
a plain no-op and `AND 2^23−1` — and on class 8 the biquad forces the sum in range, where both are
the identity.

★★ **The `AND` candidate is §224/§225's LFO WRAP, shipped as the device default**, anchored on the
ROM's own ramp constant (+114/frame, reproduced across **29 LFO blocks in 16 programs with 9
distinct increments**). Its arithmetic is stated exactly:

> `acc ← (datum(acc) & L) << ACC_SHIFT` — where **`L` is the `SRC 0x08` operand**, MEASURED as
> `C-RAM[0x01] = 0x7FFFFF`, the cell the C-RAM annotation itself calls *"wrap"*.

and it is gated on **six fields together**: bit-4 store + bit 7 + `f31 == 2` + `ACT 0x00` +
`SRC 0x08` + class A — **29 words**, none of them class 8.

### ★★★ The measurement that closes it
| | |
|---|---:|
| off-class-8 `f31 = 2` words | 244 |
| … in the wrap family | 29 |
| … **outside** it | **215** |
| **… of those 215, how many carry `SRC 0x08`** | **ZERO** |

their sources are `0x07`×155, `0x00`×51, `0x1A`×5, `0x10`/`0x11`×2.

⇒ ★★★★ **Without the `SRC 0x08` operand there is no modulus, so `AND 2^23−1` is not merely
unlikely on those 215 words — it is NOT EXPRESSIBLE.** The one rival that kept this code out of the
anchored set has been claimed by a different predicate and cannot reach them.
⇒ `f31 = 2` is admitted **except on the wrap family**, which stays refused: those 29 are a
*different operation*, and they are open on `SRC 0x08` on their own account anyway.

### ★★★★★ THE RESULT
| | §81 | now |
|---|---:|---:|
| executable words | 2 021 / 2 974 | **2 219 / 2 974** |
| **coverage** | 68.0 % | **★ 74.6 %** |
| frame floor as linked | — | **69.9 %** |
| distinct undecoded words | 262 | **203** (−59) |
| distinct undecoded FAMILIES | 94 | **83** (−11) |

**+198 words.** Cumulative: **41.5 % → 74.6 %, +985 executable words.**

⚠ **What this does NOT say.** It does not say the accumulator is *observed* unchanged at those 215
words — the live trace showing that is the device obeying its own code, and §81 records why that is
not evidence. It says the **only enumerated alternative cannot apply to them**, which is an argument
from the ISA's own field usage plus a ROM-anchored shipped decode. If a *third* candidate is ever
proposed, this reasoning does not cover it.

⚠ **And a build note**: the first C++ mirror used the wrong identifier (`word` for `w`) and failed
to compile — caught only because the rule says to grep the log for `error:` rather than trust the
build script's exit code, which is 0 either way.

⚠ Grade: the anchoring rests on §224/§225 (shipped, ROM-anchored) plus a corpus measurement that is
**0 of 215** — an exclusion by construction, not a majority.

## 84. 74.6 % → 74.9 %, and THE REMAINDER AUDITED — what 100 % would actually require
### ✅ `SRC 0x08` anchored (+8 words), and its NAME was wrong
`SRC 0x08 = C-RAM[cursor]`, **the coefficient** — MEASURED with the rival **REFUTED FROM DISK**
(`SQUARING-MULTIPLY_findings.md` item B): the chorus LFO at `iw89` reads `L = 114` with
`acc = 7 471 104 = 114 << 16` **exactly**, and `114 = C-RAM[0x00] = floor(0.5993 × 2²³/44100)`, the
constant `lfo_ramp.py` derives from the ROM. The rival needs it to be a **sample** source, and a
sample there gives no ramp. Null (item D): `P(SRC 0x08 | not multiply-gated) = 0.05 %`, 1 of 2 096;
81 of 83 occurrences are class A. The LEDGER already said *"do not touch the `SRC 0x08` source read
(anchored)"*.
⛔ **And the disassembler's label contradicted the evidence**: it read *"SRC 0x08 = LFO / per-unit
modulation source"*. It is the **coefficient port** — what anchored it was the LFO's ramp
**constant**, not an LFO signal. The name had misread its own evidence; corrected in both the
constant's comment and the rendered annotation.

### THE AUDIT — every remaining item, and why it is open
I worked each one to its source rather than leaving them as a list.

| item | words | status | what it would take |
|---|---:|---|---|
| **store gate + `f31 1`** | 52 | ⛔ **OPEN, forced negative only.** `store-gate.md` item D: over **19 758 816** machines, **17 928** survive, and **not one writes `mem[ptr]`** — but **three** readings survive: `none`, `store → elsewhere`, and ★ `load` (*a READ into the accumulator*). Those differ materially. | evidence separating "no store" from "store elsewhere" from "read into acc" |
| **`SRC 0x11`** | 50 | ⛔ **OPEN by record**: needs a **device arm** (not passively capturable — dependency cycle + kernel-B constant), and **the HLE does not model the chip's second accumulator**, so the oracle cannot reach it | a device arm, or an HLE that models ACCB |
| **`f31` 5/4/3/7** | 117 | ⛔ **OPEN** — §63–§69's `hi12` bit-5 page. Actively chosen (minimal pairs), partitioned (17 terminators EVEN / 11 detector heads ODD), but **no reading anchored**; 41 gradeable sites named | an experiment at §64's live sites, now that their input is no longer a rail |
| **`ACT 0x0B`** | 28 | ⛔ **OPEN, explicitly**: `adjudication-round5.md` — *"ACT 0x0B ⇒ READ is DEGENERATE with `H-ADB6`: every ACT-0x0B delay word carries `addr8 0x20/0x30`. It adds nothing and it is not independent evidence. **0x0B stays OPEN.**"* | evidence independent of `addr8` |
| **C-format** | 13 | ⛔ operation MEASURED 57/57, **destination register UNKNOWN** (§81) | the destination |
| `class 1` (non-escape), `ACT 0x08`, `ACT 0x1A`, `SRC 0x1B`, `ACT 0x1D` | ~30 | ⛔ small, each open on its own account | — |

### ⇒ WHERE 100 % STANDS, stated plainly
| | |
|---|---:|
| coverage now | **2 227 / 2 974 = 74.9 %** |
| undecoded occurrences | 743 |
| undecoded FAMILIES | 82 |

**Every remaining item has a documented reason for being open, and for four of the five largest the
project has already written down what it would take.** None of them is a predicate lagging a
determination — that seam, which produced this session's first ~1 000 words, is **exhausted**.
⇒ Reaching 100 % from here is **not a bookkeeping exercise**: it requires new measurements —
a device arm for `SRC 0x11`, a discriminator for the store gate's three survivors, and an
experiment at the bit-5 sites. Claiming otherwise would mean anchoring codes on majorities or on
the device's own behaviour, which is the circularity this file has refused four times today.

⚠ Grade: the `SRC 0x08` anchoring is MEASURED with a refuted rival; the audit is READ from each
item's own adjudication, cited.

## 85. 74.9 % → 75.9 %: the WRAP FAMILY, admitted on a reason that had expired while I wrote it
§83 admitted `f31 = 2` off class 8 **except** on §224/§225's 29-word wrap family, and gave two
reasons. Re-reading them an hour later, **both were already void**:

| the reason I gave | why it does not hold |
|---|---|
| *"they are a DIFFERENT operation"* | True — and irrelevant. `alu_decoded()` asks whether a word's semantics is **DETERMINED**, not whether it resembles its neighbours. For these 29 it is determined: `acc ← (datum(acc) & L) << ACC_SHIFT`, **shipped as the device default**, anchored on the ROM's own ramp constant and carried through **four passing falsifiers** (W0 one slot; W1's clip-count delta predicted **to the unit** in both buckets; W2 the chorus LFO reaching its published cell as a +114/frame ramp; W3 every regression control unmoved), the fifth restated under RULE 21 and then 0/0/0 in **both** arms. |
| *"open on `SRC 0x08` anyway"* | **Expired in the same pass** — §84 anchored `SRC 0x08` a few paragraphs earlier. The sentence was stale before it was committed. |

⇒ all three sub-populations of `f31 = 2` are determined — class 8 (identity, forced by the
biquad), the wrap family (the modulus, shipped), and the remaining 215 (the `AND` rival is not
expressible: **0 of 215** carry the operand it needs) — so the rule is now unconditional.

★ **And the wrap word renders as its own operation**, the same correction the delay escapes needed:
```
   w7   0094A00200   wrap    acc,c+          ; acc <- datum(acc) & coef  (LFO modulus)
```
It is `f31 = 2` like a HOLD and does something else entirely; rendering it as an ordinary
accumulator op would hide the one instruction in the corpus that wraps.

| | §84 | now |
|---|---:|---:|
| executable words | 2 227 / 2 974 | **2 256 / 2 974** |
| **coverage** | 74.9 % | **★ 75.9 %** |
| distinct undecoded | 202 | **200** |
| families | 82 | **81** |

**+29 words — exactly the family.** Cumulative: **41.5 % → 75.9 %, +1 022 executable words.**

⚠ **The lesson, which is the reusable part:** I wrote an exclusion and a justification for it in the
same commit as the change that invalidated half the justification. Carve-outs written *while* the
surrounding facts are moving need re-reading before they harden — this one survived barely an hour,
and only because I went back through the remaining list word by word instead of trusting my own
note.

⚠ Grade: MEASURED/SHIPPED evidence (§224/§225), re-examined; the gain is exactly the 29 words the
family contains.

## 86. 75.9 % → 76.4 %: `ACT 0x0B` on CLASS A, and a SEAM I had not been mining
### The gain
All **16** class-A `ACT 0x0B` words are one shape — `lo12 = 0x64B`, `SRC 0x19` (tempA) — and the
listing's own annotation grades it **FORCED**:

> *"all-pass core slot 6/6 — class-A multiply whose multiplicand is a **SUM OF TWO REGISTERS**, so
> `lo12 0x64B` is a fourth multiplicand route beside `mac` (0x1D5) and `mulst` (0x407)
> **(FORCED under a 2-input ALU, R1 F8)**"*

★ and the premise it is forced under is itself forced: `SQUARING-MULTIPLY_findings.md` item A —
*"the multiply has exactly TWO ports: a coefficient port HARDWIRED to `C-RAM[ccur]` and ONE operand
bus `L` selected by `SRC`. There is no third, sample-only port."*

⛔ **Admitted on class A ONLY.** On class 1/2 the same code is the delay-access reading, which
`adjudication-round5.md` closes explicitly: *"`ACT 0x0B` ⇒ READ is **DEGENERATE** with `H-ADB6` …
It adds nothing and it is not independent evidence. **`0x0B` stays OPEN.**"* The 16 class-2
occurrences keep trapping. Third use of the split-by-the-word's-own-fields pattern, after
`SRC 0x00` and `SRC 0x0B`.

| | §85 | now |
|---|---:|---:|
| executable words | 2 256 / 2 974 | **2 272 / 2 974** |
| **coverage** | 75.9 % | **★ 76.4 %** |
| families | 81 | **80** |

**+16 — exactly the class-A population.** Cumulative: **41.5 % → 76.4 %, +1 038 words.**

### ★★ THE SEAM, which is the transferable part
I found this by asking a question I should have asked hours ago: **which undecoded words carry an
annotation that already claims `FORCED` / `PROVEN BY CONSTRUCTION` / `MEASURED`?** The disassembly
has been *writing determinations into its own listing text* that its own predicate never consults.

**13 shapes, 71 occurrences.** Audited, they are:

| | |
|---|---|
| C-format `0x620` immediate loads | **55** — operation MEASURED 57/57, **destination register UNKNOWN** ⇒ correctly refused |
| class-A `ACT 0x0B` | **16** — FORCED ⇒ **admitted here** |
| internal register file `[06]` = per-unit OUTPUT LEVEL (PROVEN BY CONSTRUCTION), `[D0]` = per-unit STATE BLOCK base (MEASURED) | 2 — the *role* of the register is known; the word's **access** (index, direction, ALU effect) is not ⇒ still refused |

⇒ the seam is now **mined out**: every annotation claiming a determination has been checked against
the predicate, and the only one that was genuinely being ignored is this one.

⚠ **It also says something about the remaining 698.** They are not hiding determinations in their
own text — I looked. What is left is the register-file family (52 words, the END/CALL-RETURN
terminators among them, whose annotation says the marker *"still performs the rest of the word"* so
the register access has to be decoded too), the table-lookup idiom (~145, marked **"⛔ NOT A
DECODE"** in the device with both arms run and failed), the store gate's three survivors (52),
`SRC 0x11` (50, needs a device arm), the bit-5 high codes (~117), and `SRC 0x1C` (28, a *role*
correlation, not a register identity).

⚠ Grade: FORCED, with its premise separately FORCED; the gain is exactly the 16 words the class-A
population contains.

## 87. ★★★★★ THE REMAINDER AUDITED TO ITS SOURCES — what 100 % requires, item by item
Eight anchorings took the decode from **41.5 % to 76.4 %** (+1 038 executable words, families
133 → 80). **Every one of them was the same kind of move**: a determination the project had already
made and evidenced, which the *predicate* had never been told about. That seam is now exhausted —
§86 mined the last of it by searching the listings for annotations claiming `FORCED` /
`PROVEN BY CONSTRUCTION` / `MEASURED` and checking each against `alu_decoded()`.

So the question is no longer *"what else has been decided?"* but ***"what would it take to decide
the rest?"*** — and I worked each category to its own adjudication rather than restating a list.

| category | words | its own verdict, quoted | what would settle it |
|---|---:|---|---|
| **table-lookup idiom** | 152 | device, `c6lut`: ***"⛔ NOT A DECODE: the index's scale … is NOT verified here"*** — and **both arms were run and BOTH FAILED**: *"neither produces a ±240 sweep ⇒ what is missing is the **SCALING step** between the table and the tap, not the route"* | the scaling step; candidates named (index form `(coef × phase) >> 23`, the depth multiply's position) |
| **store gate (bit 7)** | 149 | `store-gate.md` item D: over **19 758 816** machines **17 928** survive and **not one writes `mem[ptr]`** — but **three** readings do: `none`, `store → elsewhere`, and ★ `load` (*a READ into the accumulator*) | a discriminator among those three; they differ materially |
| **`f31` high codes** (bit-5 page) | 126 | §63–§69: **actively chosen** (minimal pairs), **partitioned** (17 terminators EVEN / 11 detector heads ODD, `P ≈ 6.5e-11`), **nothing anchored** | an experiment at §64's **41 gradeable sites** — now possible, since §76 un-railed their input |
| **`SRC 0x11`** (accb) | 71 | recorded as needing a **device arm** — not passively capturable (dependency cycle + kernel-B constant) — and **the HLE does not model the chip's second accumulator**, so the oracle cannot reach it | a device arm, or an HLE that implements ACCB |
| **C-format immediate** | 68 | *"IMMEDIATE LOAD … **MEASURED 57/57** for this opcode; destination register `lo12` **UNKNOWN**"* | the destination register |
| **internal register file** | 52 | §99: *"**WHERE THEY GO INSTEAD is the open part**, and the two established readings disagree"*; and the `0x0E`/`0x0F` terminators are ***"EDUCATED GUESS G-5"*** whose own comment concedes *"the MECHANISM by which the target is chosen is unknown"* | the mode-1 store destination; the call/return target mechanism |
| other | 131 | small populations, each open on its own account | — |

### ⇒ THE CONCLUSION, stated plainly
**100 % is not reachable from the bytecode and the current instruments.** Every remaining word needs
evidence that does not exist yet, and in two cases (the table-lookup arms, §138's blanket rule) the
project has **already run the experiment and had it fail**.

To reach 100 % today I would have to anchor codes on one of:
* a **majority** — refused at §81 (`f31 = 2` was 207/216 and that was not enough);
* **the device's own behaviour** — refused at §81 and §83, and it is the circularity this file has
  now turned down four separate times;
* an **educated guess** — G-5 is labelled as one by its own author;
* a reading the project has explicitly marked ***NOT A DECODE***.

Each of those would raise the number and **destroy what the number means**. The coverage figure is
only worth quoting because everything inside it is evidenced; a 100 % built the other way would be
a worse artefact than a 76.4 % that is true.

⇒ **The three reachable next steps, in order of size:**
1. **the bit-5 experiment** (126 words) — the only one whose blocker was removed *today*; §64 names
   the 41 gradeable sites and `prog52_auto_wah` as the best host;
2. **the table-lookup scaling step** (152) — two candidates already named by the failed arms;
3. **an ACCB-aware HLE** (71) — would let the oracle reach `SRC 0x11` for the first time.

⚠ Grade: the coverage figures are MEASURED (`dsp_coverage.py`); every row of the table is READ from
the cited adjudication, not inferred. **Nothing here is a new decode** — it is the map of what is
left and what each item costs.

## 88. THE BIT-5 EXPERIMENT, ATTEMPTED — it is blocked by the SCALE problem, not by the decode
§87 named the bit-5 experiment as the most reachable of the three remaining items, because §76
un-railed its host's input. I ran it. **The host is still broken, one level deeper.**

### The setup
`prog52_auto_wah` is the right host: §67 showed its `w24` **heads the 2/π level-detector idiom**, and
a rectify-and-smooth detector has an HLE-grounded criterion that needs no oracle run — **its output
is non-negative and bounded by the input's magnitude, by construction.**

### ⛔ The result: a SATURATION CASCADE
Captured at the true default **with §76's promotion in** — the pickup is fixed
(`0x05` = **−326 247**, was **railed at 8 388 607**) — and the detector is **still pinned**:

```
   iw104  0010AFC1D5  dp 0F  mem 7FFFFF     <- cell 0x0F is AT THE RAIL
   iw105  0202A031D5  coef 517CC1 (2/pi)  L 8388607   <- the one-slot lag makes the rail its OPERAND
   iw106  0202200000  acc += 1 094 039 241 359
   iw107  002A200000  acc += 1 094 039 241 359        <- 2.16e12, i.e. datum 33 000 000
   iw109  0018A001D5  ST  -> cell 0x12 = 7FFFFF       <- the store CLAMPS; the envelope is pinned
```

⇒ **a railed cell (`0x0F`) poisons the detector, whose own output cell (`0x12`) then rails too.**
★ And `§74 §S1C` — the census I shipped this morning — **independently names `cell 12` at 3.5 %** of
all clipped conversions in this very capture, alongside `cell 06` at 57.1 %. The instrument found
the same cell the trace did.

⇒ ★★★ **The bit-5 experiment cannot be graded today, and the reason is not the bit-5 decode.** A
2/π detector pinned at full scale carries no information, so no reading of its head word can be
distinguished from any other. §75's machine-wide saturation is the blocker — **at a second cell,
one level upstream of the one I fixed.** That is a real result about the *order* the remaining work
has to be done in: **scale before semantics.**

### ⛔ AND A CORRECTION TO MY OWN §63, FOUND IN THIS TRACE
§63 states the device *"collapses every code above 2 into one behaviour (`acc ← acc + bus`)"*. The
trace shows otherwise, in two adjacent words:

| | | |
|---|---|---|
| `iw107` `002A200000` | **`f31 = 5`** | acc **+1 094 039 241 359** — the **full product** |
| `iw108` `0026200000` | **`f31 = 3`** | acc **+25 427 968** — the **bus term only** |

They are not the same behaviour. `SPEC` bit 0 is **SET in the shipped default**, so the device
computes **`op = f31 & 3`**: `4 → LOAD`, `5 → ADD`, `6 → HOLD`, and only `3` and `7` reach "no
product". ⇒ the five high codes execute as **two** behaviours, **three of them aliased onto the
decoded ops** — not one behaviour as I wrote.
⚠ **This does not make them decoded.** The aliasing is the device's own silent mapping, which §133
names *"a standing breach of this project's own rule"* (they execute with **no fired-count
anywhere**). The §63/§64 measurements — minimal pairs, the bit-5 split, the blind/live census —
are untouched; only my sentence about what the device does with them was wrong.

⚠ Grade: MEASURED on a fresh capture at the true default with the promotion in; the correction is
READ from the device's own dispatch (`op = sel ? f31 & 3 : f31`, `sel = SPEC bit 0`, set by default)
and confirmed in the trace by two adjacent words behaving differently.

## 89. ⛔ MY OWN CENSUS OVER-ATTRIBUTES — corrected, and what a real one would take
Chasing §88's conclusion (*scale before semantics*) to its biggest target, I went after **cell
`0x06` at 57 %** of all clipping. It does not survive contact.

### Two errors, both mine
**1. I conflated two different address spaces.** The listings grade register **`[06]` = the per-unit
OUTPUT LEVEL, PROVEN BY CONSTRUCTION** — and that is the **internal register file**, indexed by
`addr8` on a class-1 non-escape word. `§S1C` is indexed by **`m_dp`, the D-RAM pointer**. *"Cell
06"* in my census is **D-RAM `0x06`**, a different thing entirely. Tracing it confirms the point:
it is rewritten constantly through the kernel (`−211 456`, `−393 309`, `6 039 795`, `8 388 607`),
which is not how an output-level register behaves.

**2. The census counts POINTER RESIDENCE, not RECEIPT.** It fires in `acc_to_datum()`, where the
target is not knowable — so every clipping conversion that occurs while the pointer happens to rest
on a cell is charged to that cell. Measured in one auto-wah frame:

| cell | rows with the pointer there | of which carry a STORE |
|---|---:|---:|
| `0x94` | 45 | **5** |
| `0x00` | 31 | 15 |
| `0x8B` | 30 | **4** |
| `0x06` | 20 | **10** |
| `0x12` | 9 | 2 |

⇒ **a cell the pointer merely passes through during heavy arithmetic accumulates counts it never
took.** The ranking is a **candidate finder, not a verdict**, and §75's headline is corrected in
place above.

★ **It is not worthless** — and the distinction matters. It independently named **cell `0x12`** in
`prog52_auto_wah`, which §88 then confirmed from the trace as a **real store target that really is
railed**. A finder that surfaces true candidates alongside artefacts is still the reason §88 found
its cascade; it just cannot be quoted as a measurement of harm.

### ✅ THE STORE-ACCURATE CENSUS — built, after two wrong turns worth recording
I first wrote *"there is no central D-RAM write helper — 33 `m_dram.write_dword` sites — so it is a
refactor, not a counter."* **Both halves of that were wrong.**

**Wrong turn 1.** I picked the 5 sites that looked like microcode stores and instrumented them. The
census came back **`0 of 0`** — *the microcode's stores do not reach D-RAM through those calls at
all.* A negative result from my own patch, and the useful kind: it said the write path was somewhere
else entirely.

**Wrong turn 2.** The code's own comments point at a helper called **`do_store()`** — *"do_store()
implements the rule"*, twice. **There is no such function**; it survives only in comments. Stale
documentation sent me looking for something that had been renamed or inlined.

★ The real central helper is **`store_mode()`**, under its own banner *"one rule for both store
sites"* — exactly the thing I had declared absent. Counting there, and reverting the 5 mis-placed
call sites so nothing is double-charged:

| | auto wah | no operation |
|---|---:|---:|
| **full-scale datums received / microcode stores** | **9 986 693 / 135 151 116 = 7.39 %** | 9 430 830 / 128 539 510 = **7.34 %** |
| `cell 06` | **33.7 %** | **32.7 %** |
| `cell 8B` | 13.3 % | 12.7 % |
| `cell 94` | 9.1 % | 6.1 % |
| `cell 12` (the auto-wah detector output, §88) | **5.3 %** | — |
| `cell 05` / `07` ★ per-unit hand-off | 4.7 % | 5.6 % |

⇒ ★★ **`cell 06` really is the largest recipient** — so the *direction* of §75's claim survives —
but its share is **33.7 %, not 57 %**, and it now means *"this cell was handed full scale 3.4 M
times"* rather than *"57 % of clipping happened near it"*. **One third of the excursions, and a
different statement.** ★ The detector cell §88 found from the trace appears independently at 5.3 %,
and both per-unit hand-off cells are in the top six.

⚠ **Still not an inference about clipping**: it counts a stored datum that *is* the rail, so a
legitimately full-scale sample is counted too. That is the honest reading and it is the one printed
at the point of use.

⚠ **And the honest consequence for §88's ordering.** *"Scale before semantics"* still stands — the
auto-wah's detector really is pinned by a railed operand at cell `0x0F`, and that was read from the
trace, not from this census. What does **not** stand is *"cell `0x06` is the largest remaining scale
defect"*. The largest is **unknown** until the census counts receipts.

⚠ Grade: MEASURED (the store-bearing split, one frame); the correction is to my own instrument and
to two of my own claims, and both are corrected at the point a reader meets them.

## 90. ★★★★★ THE SCALE PROBLEM AND THE DECODE GAP ARE THE SAME PROBLEM — a complete causal chain
§89 gave the saturation a properly-measured target list for the first time. A ranked list of cells
says *where* the damage lands; it does not say *who causes it*. So I extended `§S1R` to record, per
cell, the **instructions** that hand it full scale (four `(iw, count)` slots each). One run, and the
chain closes end to end.

### The chain
| step | evidence |
|---|---|
| the largest recipient | **`cell 06`, 33.7 %** of all full-scale receipts (3 083 579) |
| its writers | **`iw19` (1 706 614)** and **`iw39` (1 372 663)** — together **all** of it, and both in the **shared kernel**, so in **every program** |
| what `iw19` is | `051220044D` — class 2, store, `ACT 0x0D`, **`SRC 0x11`** … and **`decoded()` = FALSE** |
| what it does | in the auto-wah trace its accumulator becomes **exactly `accb`**: `549 755 748 352` |
| what `accb` is | `549 755 748 352` = **`8 388 607 << 16`, EXACTLY** — the positive rail, to the unit |

⇒ ★★★★ **ACCB is pinned at the rail, `iw19` copies it into `cell 06`, and that is one third of every
full-scale datum the machine stores.**

### ⇒ Why this matters more than the number
`SRC 0x11` has sat on the open list all session with the note *"needs a **device arm** — not
passively capturable (dependency cycle + kernel-B constant) — and **the HLE does not model the
chip's second accumulator**, so the oracle cannot reach it."* True, and it made the item look like a
low-priority curiosity: 71 words, no way in.

It is **the largest single scale defect in the machine**, and it now has:
1. **a reason to be worked** — 1.7 M full-scale stores per run trace to it;
2. ★ **a two-sided criterion that did not exist before** — *does `accb` stop sitting at
   `8 388 607 << 16`, and does `cell 06`'s share of full-scale receipts fall?* Both are counted
   automatically by `§S1R` now, in any capture, with no new rig;
3. **a control**: `iw39` writes the *other* 1.37 M and **is decoded** (`ld.st ta,c+,(p)-1`), so its
   railing is genuine arithmetic overflow, not a decode gap. A fix aimed at `SRC 0x11` must move
   `iw19`'s count and **leave `iw39`'s alone** — if both move, the change is too broad.

⇒ **§88's "scale before semantics" was half right.** At this site they are not two problems in an
order — they are **one problem**: the cell is railed *because* the word feeding it is undecoded.

### The rest of the culprit table, for the next pass
| cell | share | railed by |
|---|---:|---|
| `8B` | 12.7 % | `iw296`, `iw303`, `iw288` (body 1, ~400 k each) |
| `0E` | 7.9 % | **`iw121`** (493 718 — one word, nearly all of it) |
| `94` | 6.1 % | `iw261`, `iw254`, `iw246` |
| **`07`** ★ per-unit hand-off | 5.6 % | **`iw126`** (250 283) |
| `8A` / `8C` / `8F` | ~4 % each | `iw313` / `iw66` / `iw332` — **one word each**, ~400 k |

★ Several are **a single instruction responsible for essentially all of a cell's railing** — which
is the shape of a defect, not of a diffuse scale problem.

⚠ Grade: MEASURED (one run each, two programs; the `accb` identity is exact to the unit). ⚠ It does
**not** say what `SRC 0x11` should read, or why `accb` is railed — it says the two questions are the
same one, and hands it a criterion.

## 91. ★★★★★ THE CHAIN REACHES ONE INSTRUCTION — `iw331` — and it caveats my own §80
§90 traced a third of every full-scale store in the machine to `iw19` reading **ACCB**, which sits
at **`8 388 607 << 16`** exactly. One step further back: `use_b` resolves to `m_cur_unit1` under the
shipped mask, so **ACCB *is* unit 1's accumulator**, and kernel A's `iw19` reads **last frame's**
unit-1 result. So: *what leaves it at the rail?*

Tracing every change of `accb` through an auto-wah frame — 88 of them — the **last** is decisive:

```
   n=262  iw=330  u1=1  020227B1CD   accb = 0
   n=263  iw=331  u1=1  088016040E   accb = 549 755 748 352   <-- EXACTLY the positive rail
   (next frame)  n=0  iw=0           accb = 549 755 748 352   <-- what iw19 reads
```

⇒ ★★★★ **`iw331` ends body 1 by leaving unit 1's accumulator at exactly full scale, every frame**,
and kernel A copies that into `cell 06` on the next one. **The complete chain, from a 33.7 %
statistic to a single instruction:**

> `iw331` rails ACCB → `iw19` (`SRC 0x11`) copies ACCB → `cell 06` → **33.7 % of every full-scale
> datum the machine stores.**

### ⚠ AND IT CAVEATS §80, WHICH IS MINE FROM THIS MORNING
`iw331` = `088016040E` is `hi12 0x880`, class 1, `addr8 0x60` — **a class-1 delay WRITE**. That is
one of the 276 forms I anchored in §80 as executable, and it renders as `dly.w  dsc[k],p+96`.

★ But it **also leaves ACCB at the rail**, which "an external delay write" does not describe. §80's
justification was that a class-1 escape *"never reaches the ALU — the device's own `is_dram` branch
RETURNS BEFORE IT"*. **At `iw331` something touched the accumulator anyway.**

⇒ Two readings, and I am not choosing between them here:
1. the device has an **extra accumulator effect** on a delay write that the chip does not — a bug,
   and then §80's anchoring is right and this is a defect beside it;
2. the delay write **genuinely does more** than the delay access — and then §80's anchoring
   describes only part of the word, and "executable" is too strong for these 276.

⚠ **Either way §80 needs qualifying**, and the qualification is written here rather than left for
someone to trip over: **the delay escape was anchored on its ADDRESSING, which is forced; its
effect on the accumulator was neither examined nor claimed.** The coverage gain stands only under
reading (1).

### What this gives the next pass
A **single named instruction** for the largest scale defect in the machine, with the count already
instrumented: `§S1R` reports `cell 06`'s share and its writers automatically in any capture. The
test is now trivially two-sided — *change what `iw331` does to the accumulator, and `cell 06`'s
share must fall while `iw39`'s contribution (decoded, the control) stays put.*

⚠ Grade: MEASURED (one frame, 88 `accb` transitions, the rail identity exact to the unit). ⚠ It does
**not** say `iw331` is wrong — it says it is where the rail enters, and that the word doing it is
one I called executable this morning on grounds that did not cover this.

## 92. ⛔⛔ COVERAGE 76.4 % → 74.0 % — I WALK BACK PART OF §80, BECAUSE ITS PREMISE IS FALSE
§91 left two readings of `iw331` and said I was not choosing. **The code chooses.**

§80 admitted all **276** class-1 delay escapes as executable on one stated premise:

> *"It never reaches the ALU: the device's own `is_dram` branch **RETURNS BEFORE IT**. So grading
> these words on anchored SRC/ACT/`f31` — fields they do not use — counted 276 fully-determined
> words as undecoded."*

⛔ **The branch does not return.** It calls **`exec_alu(word)` with `m_in_dram = true`**, twice, under

```
   const bool run_alu = m_speculative && (m_specmask & 0x80000) && !m_in_dram;
```

and **SPEC bit 19 is SET in the default mask** (`0xb910e446a39b440f`). The delay word runs its
datapath half **deliberately** — that is how the delay datum reaches the chain — so its
`SRC` / `ACT` / `f31` **do** apply. §91's `iw331` is the visible consequence: a delay *write* that
leaves unit 1's accumulator at exactly the positive rail, which "an external delay write" does not
describe.

⇒ **My gain was partly built on a misreading of the device**, and the honest predicate is:
*a delay escape is decoded when its **addressing** is forced **and** its **ALU half** is anchored.*

| | |
|---|---:|
| delay escapes with a validated direction | 276 |
| … whose ALU half is **also** anchored | **201** |
| … refused on their ALU half | **75** — `ACT 0x0B` on class 1 ×50, `ACT 0x1C` ×17, `ACT 0x1A` ×6, `ACT 0x07` ×2 |

### THE COST, reported as a decrease
| | before | after |
|---|---:|---:|
| executable words | 2 272 / 2 974 | **2 200 / 2 974** |
| **coverage** | 76.4 % | **⛔ 74.0 %** |
| undecoded families | 80 | 87 |

**−72 words.** Session total is now **41.5 % → 74.0 %, +966** (not +1 038).

### Why I am reporting a number going DOWN
Because it is the same discipline that made the other eight gains worth anything. Every anchoring
this session was justified by *"a determination the project had already evidenced"*. §80's
justification was **my own reading of a code path, and I read it wrong** — I quoted a comment
(*"returns before the ALU"*) instead of following the branch. The words whose ALU half really is
anchored keep their place; the 75 that were riding on a false premise lose it.

★ **And the lesson is exactly the one that has bitten four times today**: I took a claim from a
*comment* rather than from the code. §89 found comments naming a `do_store()` that does not exist;
this is the same failure mode, and this time it had put 75 words on the board.

⚠ Grade: FORCED (the mask bit is set; the call is unconditional given it). The 201 that remain are
anchored on both halves and are unaffected.

## 93. ★★★★★ THE CHAIN LANDS ON §138 — arrived at independently, at the site §55 predicted
§91 named `iw331` as where the rail enters ACCB. §92 established that a delay word **runs its ALU
half**. Putting those together, the mechanism is exact:

```
   iw329  MUL=Y  L = 8 388 607 (the rail)   ->  P = 549 755 748 352   (= 8388607<<16, the rail)
   iw330  accb -> 0                             P still 549 755 748 352
   iw331  f31 = 0, class 1, MUL = '.'       ->  accb <- P            ★ STALE: no coefficient fetched
```

⇒ **`iw331` LOADs a STALE product into unit 1's accumulator.** It is `f31 = 0` (LOAD `acc ← P`),
it is class 1 so it **fetches no coefficient**, and the `P` it loads was produced two words earlier
by a multiply whose operand was already at the rail.

### ★★★★ That is §138, and I did not go looking for it
§138's predicate is stated in the device, in these words:

> *"a word with `f31 == 0` (LOAD `acc ← P`) that fetches **NO coefficient** brought no fresh
> product, so loading from `P` is an **ERASURE**, not an operation."*

`iw331` satisfies it exactly. And §138 is **REFUTED** — §27/§28 measured it breaking the parametric
EQ's *entry*, where turning `iw85`'s LOAD into a HOLD makes the entry triple-count the input and
rails the pickup. It has sat closed since.

★★★ **But §55 already anticipated this.** Its own words: the same predicate *"names the killer in
**13 of 14** bodies' **TAILS**"*, and *"those are different sites from the entry that §28 measured
breaking."* §55 then declined to act, correctly, because *"restrict it to the tail would be
**fitting the rule to the data**."*

⇒ **This arrives at the same site from a completely unrelated direction** — a saturation census
built this morning to answer *"which cell receives full scale"*, followed backwards through
`cell 06` → `iw19` → `ACCB` → `iw331`. Nothing in that path knows about §138 or about §55's tail
census. **Two independent routes, one site.** That is not fitting the rule to the data; it is the
data arriving twice.

### ⇒ What is now available that §138 never had
| | |
|---|---|
| **a criterion** | *does `cell 06`'s share of full-scale receipts fall?* — counted automatically by `§S1R` in any capture, no new rig |
| **a control** | **`iw39`** writes the other 1.37 M receipts of the same cell and **is decoded** (`ld.st ta,c+,(p)-1`). A guard aimed at stale LOADs must move `iw19`'s count and **leave `iw39`'s alone**. If both move, it is too broad — which is exactly how §28's refutation looked |
| **a blast-radius number** | already measured: §138 as a blanket rule rewrites **1 084 of 3 057 words, 35.5 %** (`load_nocoef_census.py`) |

⚠ **I am NOT arming it.** It is refuted at the entry, its blast radius is a third of the corpus, and
§55's objection to a tail-restricted variant still stands on its own terms. What has changed is that
the *tail* case now has **independent corroboration and a two-sided test**, which is precisely what
§55 said it lacked. That is the experiment to run next, and it is a session's work: arm, measure
`cell 06` vs `iw39`, and check the EQ entry has not moved.

⚠ Grade: MEASURED (the trace rows are exact; `P` at `iw331` equals `iw329`'s product to the unit,
and `accb` equals `P`). The identification with §138 is **FORCED** by its own stated predicate. No
arm was run.

## 94. ⛔ §138 REFUTED AGAIN — by a better criterion, while its ORIGINAL refutation no longer reproduces
§93 arrived at §138's predicate from an unrelated direction and said the tail case now had a
criterion and a control it never had. I pre-registered both
(`data/PREDICT_STALE138_TAIL_2026-09-13.md`) and ran it: `SPEC` bit 55 on, true default otherwise.

| # | prediction | result |
|---|---|---|
| **P1** | `cell 06`'s share of full-scale receipts **falls** | ⛔ **FAIL** — its absolute count **ROSE**, 3 368 783 → **3 540 489** |
| **P2** ★ | **`iw39`, the DECODED control, is unchanged** | ⛔ **FAIL** — 1 372 663 → **1 758 928 (+28 %)** |
| **P3** | `iw19`'s count falls | ⛔ **FAIL** — 1 706 614 → 1 762 079 |
| **C1** | the EQ, §28's refutation site, is unharmed | ✅ **PASS** |

★★★ **And the number that settles it, which §138 has never been measured against:**

| | baseline | §138 armed |
|---|---:|---:|
| full-scale datums received / microcode stores | **9 986 693 / 135 151 116 = 7.39 %** | **40 580 369 / 135 151 116 = 30.03 %** |

⇒ **the guard QUADRUPLES the machine's saturation.** Turning stale LOADs into HOLDs does not stop
the erasure — it stops the *clearing*, so accumulators carry further and rail more often. `cell 8B`
alone goes 1 326 062 → 7 063 430, its four writers landing on **1 763 1xx each**, a suspiciously
flat signature of a machine pinned rather than computing.

★ **P2 is what caught it, and it was written down in advance.** `iw39` is decoded
(`ld.st ta,c+,(p)-1`) and has nothing to do with stale products; a correct guard must not touch it.
It moved 28 %. That is the definition of too broad, and it is the same shape as §28's original
refutation — measured this time as a number rather than as a topology.

### ★★ THE OTHER HALF: §28's refutation no longer reproduces
**C1 passed, and that is a finding in itself.** §138 was closed because at the EQ's entry it made
`iw85` a HOLD, the entry triple-counted the input and `iw88`'s store railed the pickup. Armed today
the EQ is **untouched** — pickup `0x05` identical to the baseline (inherited 53 452, leaves 56 033),
`0x01`/`0x04` identical, and **all five bands still carry signal**.

⇒ §76's input-stage promotion changed the conditions under which §28 measured. **The original
refutation's mechanism is gone; the arm is still wrong, for a different and better-measured
reason.** ⚠ That is worth recording precisely because it would have been easy to re-open §138 on
*"§28 no longer reproduces"* alone — and it would have been wrong. A refutation expiring does not
make the claim true.

⇒ **§138 stays closed**, now with a quantitative reason (`7.4 % → 30.0 %`) and a named control that
moved, on top of the topological one that has lapsed. §55's *"do not restrict it to the tail — that
is fitting the rule to the data"* is vindicated: the tail case was corroborated independently and
the arm **still** fails.

⚠ Grade: MEASURED, pre-registered, with the control that decided it written before the run. The
chain §90–§93 built is unaffected — `iw331` still rails ACCB, `iw19` still copies it, `cell 06` is
still the largest recipient. What is now excluded is **this** fix for it.

## 95. THE DENOMINATOR IS HONEST — every undecoded word is EXECUTED
One avenue remained that could have raised the number legitimately rather than by fiat: **dead
code.** A word in an image that never runs does not affect LLE fidelity, and if any of the remaining
774 were unreachable they would not belong in the denominator.

Measured against live frame traces (body base I-RAM 84):

| program | image | executed | undecoded in image | **of those, EXECUTED** |
|---|---:|---:|---:|---:|
| `prog52_auto_wah` | 72 | **72 (100 %)** | 14 | **14** |
| `prog00_no_operation` | 49 | **49 (100 %)** | 17 | **17** |
| `prog39_parametric_eq` | 105 | **105 (100 %)** | 4 | **4** |

⇒ **100 % of every image runs every frame, and every undecoded word is among them.** There is no
padding, no unreachable tail, no slack. ⇒ the coverage figure is **not inflated by dead code**, and
the whole remaining gap is **load-bearing**: each of those 774 words executes on every frame of
every program that contains it.

★ That closes the last avenue that could have moved the number without new evidence. It also says
something useful about the machine: these are **straight-line microprograms with no dead
instructions**, which is consistent with a fixed-slot DSP frame and with the call/return sequencer
being the only control flow.

⚠ Grade: MEASURED on three programs spanning modulation, dynamics and the biquad. ⚠ It is three
programs, not 38 — but the result is 100 %/100 %/100 % with no partial case, and the frame
structure (a fixed slot count per unit) predicts it generally.

## 96. ★ TIER 1b: 32 WORDS WHOSE OPEN AXIS CANNOT BE OBSERVED — 74.0 % → 75.0 %
Tool: [`../tools/acc_blind.py`](../tools/acc_blind.py). Wired into
[`../tools/dsp_coverage.py`](../tools/dsp_coverage.py) as its own column, never folded into
`decoded()`.

Three of the largest entries in the leverage table are open axes that live **entirely inside the
arithmetic** — two in the accumulator, one on the operand bus:

* **`f31` 3/4/5/6/7** — `f31-high.md` item A enumerates four readings (`base`, `negP`, `hold`,
  `prod`); each differs from the others only in how `acc` is updated.
* **the store gate at `f31 == 1`** — `store-gate.md` item D is a FORCED NEGATIVE: of 17 928
  machines surviving all 29 blocks, **not one writes `mem[ptr]`**. The three survivors are `none`,
  `ST(acc->else)` and `LD`. ★ `gate_settle.py:70` declares the `else` key *"a memory key no
  pointer can ever equal"*, and `LD` assigns `st.acc` and nothing else — so all three families,
  and the three `clr` placements with them, **differ only in `acc`**.

`f31-high.md` item F had already measured that 92 of 203 such words are BLIND, and used it only to
explain why the biquad cannot DECIDE the field. ★ **Turned around, it is a coverage result:**

> if a word's only open axis is confined to the accumulator, and the accumulator it leaves is
> destroyed before anything reads it, then every surviving reading executes that word identically
> as far as the machine can tell — so the word is EXECUTABLE though the axis is unknown.

That is what tier 1 measures: not *what the code names* but *can we run it faithfully*.

**MEASURED:** 310 sites have an open axis confined to the arithmetic; **32 are blind** — 15 ×
`f31 5`, 6 × `f31 4`, 5 × `f31 3`, 2 × `f31 7`, 1 × `f31 6`, 2 × `SRC 0x11`, and **1 store-gate
site (kernel `w24`, `0692200415`)**. The body corpus goes **2200 → 2231 of 2974, 74.0 % →
75.0 %**; the frame floor 70.4 % → 70.8 %.

⚠ **The operand case taints the PRODUCT, not the accumulator, and getting that backwards would
have been a large false positive.** `P[N] = coef[N−1] × L[N−1]` — the one-slot pipeline this
project measured bit-exactly — so an unknown operand reaches `acc` only at word *i+1*, and it
reaches it there **even if that word is an `f31 == 0` reload**: `acc <- P` LOADS the tainted
product rather than killing it. The commonest shape in the corpus is exactly "open-SRC word whose
successor reloads the accumulator", so a walk that killed the taint at *i+1* would have admitted
most of the 54 `SRC 0x11` sites instead of 2.

### The walk, and the three places it is deliberately pessimistic
`SRC 0x10` observes the accumulator; so does the bit-4 store — **except** on a `b7 & f31 == 1`
word, where item D forces that it does not reach `mem[ptr]`. `f31 == 0` (`acc <- P`) destroys it,
and that kill does not depend on the open `ACTION 0x00` reading either, because
`action00-discriminator.md` item C proves `load`/`add`/`rload` are the *same expression* at
`hi12[3:1] == 0`. Pessimistic on purpose: **a C-format word, a bit-11 word, or any word whose SRC
this project has not anchored counts as an observer**, because `gate_settle.py`'s own menus list
`acc` among the candidates for `SRC 0x00`, `0x08` and `0x11`. Assuming those are harmless would
assume away the coverage gap. It also counts **the site's own store** — whether that store takes
the pre- or post-ALU accumulator is one of the solver's free dimensions, so the axis is observable
at the site and the walk never starts. That last check alone removed 25 sites from a first draft.

### ★ The control, and it goes the right way
An accumulator thrown away four slots later looks like **dead work**, and §95 has just shown these
microprograms contain no unreachable instructions. If discarding were rare, finding it
concentrated on the `f31 > 2` words would be evidence that those words are *not* accumulator
operations — and the lemma would be assuming the very thing in doubt. So measure the rate where
the operation is not in question (`acc_blind.py --null`):

| `f31` | words | accumulator discarded | rate |
|---|---:|---:|---:|
| 0 (`acc <- P`) | 1143 | 354 | **31.0 %** |
| 1 (`acc <- acc + P`) | 808 | 157 | 19.4 % |
| 2 (hold) | 251 | 26 | 10.4 % |
| **anchored 0/1/2** | **2202** | **537** | **24.4 %** |
| **open 3..7** | **131** | **32** | **24.4 %** |

**The same rate, to three digits.** Discarding an accumulator is ORDINARY in this machine — the
fully anchored `acc <- P` is discarded 31 % of the time — so it carries no information about what
the open codes mean. The objection is answered by the machine itself, and the ROM's microprograms
are shown not to be minimal: they routinely compute accumulator values nothing reads.

### Grade, split honestly
⚠ **The store-gate site is FORCED** — the survivor set is exhaustive over the 19 758 816 machines
`gate_settle.py` searched, and `else` is unreadable by construction.
⚠ **The 29 `f31` sites rest on a stated premise**: that `hi12[3:1]` selects the accumulator's
update for values 3..7 as it provably does for 0/1/2. That premise is FORCED to be an accumulator
control by the LFO minimal pair `092.A.dd.200` / `094.A.dd.200` (identical in class4, addr8 and
all twelve lo12 bits) and MEASURED to have base-op structure by `f31-high.md` item B (bases 0/1/2
track to three digits across bit 2, over a 20× sample-size difference) — but `f31-high.md` §4.3 is
explicit that the four readings are *"a starting set, not an enumeration"*, and item C shows base 3
is not a modified base 3. **So this is DETERMINED-conditional, not FORCED, and the column is kept
separate from `decoded()` so no published per-word number moves.**

⚠ Tier 1b is a property of the SITE, not the word. `dsp_disasm.decoded()` stays per-word — the
MAME disassembler mirrors it word for word and has no image to look at — and `dsp_coverage.tally()`
now takes a LIST OF IMAGES rather than a concatenation, so a site at one body's tail cannot find
its `f31 == 0` killer in the next body, which does not follow it in execution.

## 97. ⛔ §168 WAS VOID: THE ARM COULD NOT REACH THE WORD IT WAS AIMED AT
Pre-registration: [`data/PREDICT_SRC11_MEM_2026-09-13.md`](data/PREDICT_SRC11_MEM_2026-09-13.md).
Control: [`data/src11_control_2026-09-13.txt`](data/src11_control_2026-09-13.txt).
Arm: [`data/src11_bit18_2026-09-13.txt`](data/src11_bit18_2026-09-13.txt). One program
(`prog01_chorus`), one frame, `NOTEOFS=2.5`, true default plus `UPD6383_SPEC=b910e446a39f440f`.

### Why it was re-opened
The `C63` + class-6 idiom is the largest coherent undecoded block in the corpus — with the
`012.4.01.1CE` word that follows it, **159 words, 5.3 % of the body corpus**. §166 called it one
idiom (53 of 53 in both directions) and named `tempB` as its index register; §168 tested the
`SRC 0x11` reading that would fill that register and refuted it on one sentence:

> *"Cell `0x0C` is not among them. `C63` reads cell `0x0C` … It is reading the wrong cell."*

At today's default that sentence is false: `§176 0C:1(-17..19/chg19520)` — a small signed integer
changing every ~91 frames, which is the shape of a table index. So the refutation was re-run.

### Result against the pre-registration

| | pre-registered | measured | |
|---|---|---|---|
| **P1** gate fires | `§113` count > 0 | **12 760 530** | ✔ |
| **P2** ★ the decision | `tB` at the class-6 site VARIES, chg ≫ 1, range inside `-17..+19` | `tB 0..5872025 chg 1` — **bit-identical to the control** | **MISS** |
| **P3** control that can fail | `m_dp` `12..12`/`14..14`, `cursor 9..9` unchanged | unchanged | ✔ |
| **P4** upstream null | cell `0x0C` census unchanged | `-17..19/chg19520` | ✔ |
| **P5** RULE 12 | the traced frame has audio | `01` chg 175 919, `05` chg 175 660 | ✔ |

The whole 256-cell census is identical between arm and control except `06: chg1389 → chg2` — the
same single-cell difference §168 recorded (`06: chg 1100 -> 2`), reproduced, and not at the idiom.

### ★ Why it did not move, and it is not the reason §168 gave
`lo12 = 0xC63` has **bit 11 set**. `upd6383.cpp:2768` — whose own comment cites
`bit11-family.md` §9 — takes the alternate-encoding branch, performs the addressing and
**`return`s**. The SOURCE switch is at ~3830 and the ACTION switch at ~4600, both downstream of
that return, and `m_tb` is assigned **only** inside the ACTION switch.

⇒ **`SRC 0x11` is never decoded for a `C63` word, under any setting of bit 18, and `m_tb` can
never be written by one.** §168's experiment could not have produced a different answer. Its
9 279 912 firings were real and were counting *other* words.

★★ **A fired-count proves the arm ran somewhere. It does not prove it ran at the site the
conclusion is about.** §116 hit the identical trap on `lo12 = 0x827` — *"a selector-0x27 word is
swallowed here and never reaches the register-load dispatch"* — and caught it because its count
was per-site. This one was not.

### ★★ And the same bit sinks §166's identification of the index register
§166 §3 reads `C63` as *"`SRC 0x11 / ACT 0x03`, and `ACT 0x03` is `m_tb = L`"*. Those are the
ALU field accessors applied to a word that does not have those fields —
`dsp_disasm.alt_lo12()`'s own docstring says *"`lo_src()`/`lo_act()`/`lo_ptrmode()` are
MEANINGLESS on these words"*, and the device comment at the branch says the alternate encoding has
*"no SRC and no ACTION field"*. It is the same error this session corrected in
`decode_leverage.py`, where the leverage table was charging 76 bit-11 words to a
`pointer mode 1 + SRC 0x11 + ACT 0x03` that is not in their encoding.

⇒ **§166 §2 STANDS** — the 53/53 bijection is pure adjacency and needs no field decode. **§166 §3
does not.** The idiom's index does not live in `tempB` by way of `ACT 0x03`; where it lives is
open, and the next step for the 159 words is to decode the **bit-11 alternate encoding of
`lo12 = 0xC63`**, not to keep testing SOURCE readings that the word never reaches.

### The instrument, so this cannot happen a third time — and it turns the argument into a measurement
`upd6383.h` gains `note_alt11()` and `upd6383.cpp` a **§97 SWALLOW CENSUS**: every distinct `lo12`
that leaves `exec_alu()` at the bit-11 return, with its count, logged at the end of every run.
Built and run ([`data/swallow_census_2026-09-13.txt`](data/swallow_census_2026-09-13.txt), chorus,
true default):

```
   lo12 822 : 1 581 303 times
   lo12 839 : 1 601 712 times
   lo12 8BC : 1 576 134 times
   lo12 C63 : 3 150 504 times   <- the C63 idiom's first word
```

★ **3 150 504 = exactly twice per frame** against §162's 1 575 252 hits per class-6 site — the
chorus's two idiom instances, every frame, every one of them leaving before the SOURCE stage. The
claim is now MEASURED, not inferred from reading the branch. And the census names the rest of the
family: **all four bit-11 shapes in this program execute as addressing only**, which is the only
honest thing the device can do with an encoding whose fields are undecoded — but it is also the
reason no SOURCE or ACTION arm will ever move any of the 84 undecoded bit-11 words.

Any future arm on a SOURCE or ACTION field can now check in one line whether its target word even
reaches the stage it edits.

⚠ Not isolated: between §168 and today the input stage was corrected (§76) and the census quoted
here (`§176`) is not the one §168 quoted (`§164`). What is established is that the sentence the
refutation rested on is not true of the machine as it ships, and that the refutation's *verdict*
survives anyway — for a reason that makes the test void rather than negative.

## 98. `addr8` IS READ BY NOTHING ON 53 WORDS — and the first version of this said 150
Tool: [`../tools/addr8_usage.py`](../tools/addr8_usage.py). Static, no emulator.

§97 named the next target: the `C63 | class-6 | class-4` idiom. Start with the field nobody has
asked about. The device reads `addr8` for exactly three things — the pointer delta on classes 2
and A, the register-file index on 1 and 9, and the register-load payload on a bit-11 word. On
classes 0, 4, 5, 6, 8, C and D it reads nothing.

### The null, and it is exceptionless
Class 0 is the only class carrying both kinds of word:

| class 0 | words | of which have a known use for `addr8` |
|---|---:|---|
| `addr8 != 0` | 9 | **9** — every one an `is_regload()` whose `addr8` is its payload |
| `addr8 == 0` | 100 | **0** |

⇒ **in this ROM `addr8` is zero exactly when the word has no use for it.** No exceptions. Against
that null, classes 4, 6 and 8 carry a non-zero `addr8` in **150 of 150** words and the model reads
none of them. The shape agrees: a signed DELTA has zeros (classes 2/A are **46.5 %** zero — "do
not move" is a legal delta), an INDEX does not (classes 1/9 are **0 of 328**), and 4/6/8 are
**0 of 150**.

And the delta reading was tested rather than argued. `closure_pointer.py variants` gained V7–V11,
which add classes 4 / 6 / 8 to the pointer walk. **None closes the frame, and every one raises the
unit-0 pool's net heterogeneity** — 8 distinct nets at the baseline → 10, 15, 12, 21, 21. That
tool's item G killed two earlier variants for exactly this ("destroying the pool constancy"), so
the delta reading is disfavoured on four independent arms.

### ⚠⚠ And then the control, which cut the finding from 150 words to 53
**"Never zero" is not "carries information."** A field holding the SAME VALUE everywhere is never
zero either. Split by how many values each class actually takes:

| class | distinct `addr8` | varies inside one image? | |
|---|---:|---|---|
| 4 | **1** (`0x01` ×53) | no | ⇒ CONSTANT — selects nothing |
| 8 | 3 (`0x16` ×42 body, kernel `0x0C`, epilogue `0x0F`) | no | ⇒ CONSTANT — selects nothing |
| **6** | **5** (`18` ×29, `1A`, `1E` ×3, `20` ×3, `28` ×17) | **yes, in 5 images** | ★ **SELECTS SOMETHING** |

Class 8 has a positive check besides, and it is the strongest acceptance test this project owns:
PARAMETRIC EQ's ten class-8 words are the **identical word `0804816415`**, and the biquad
reproduces the firmware's own bilinear designer to **0.198 dB** with `addr8` unread at all ten.
If that field redirected the coefficient fetch, the 6-cells-per-band cursor map would not hold.

⇒ **No word is demoted. The coverage number stands at 75.0 %.** I had drafted the opposite —
"36 class-8 words are admitted as tier-1 while carrying an unread load-bearing field, so the
number is 1.2 % too high" — and the constant/varying split refutes it. ★ The lesson is the same
shape as §66 and §73: *check whether the corpus can distinguish your explanation from the
alternative before believing it*, and here the check was one `collections.Counter`.

### What survives, and it is aimed at the idiom
**53 words — every class-6 word in the corpus — carry an `addr8` that takes five values, varies
between sites inside a single program (chorus: `0x18` at `w31`, `0x20` at `w35`), and is read by
nothing.** That is the idiom's SECOND word, the one the disassembler already annotates
"class-6 `addr8` = table selector (INFERRED)". The annotation now has evidence under it: the
field is used, it is not the pointer delta, and it distinguishes sites within one program.

★ And the five values split exactly along the idiom's two variants, 53 of 53:
`040.0.00.C63 → 000.6.{18,28}.4CD` (46) and `142.0.00.C63 → 000.6.{1A,1E,20}.407` (7). The
selector's value set is a property of which variant the macro is, not of the program.

## 99. ⚠ CORRECTION TO §97's OWN FRAMING — the "index-shaped" cell is our own output
Evidence: [`data/idiom_cells_2026-09-13.txt`](data/idiom_cells_2026-09-13.txt), from the same
chorus capture.

§97 re-opened §168 because the cell the idiom sits on had come alive: `§176 0C:1(-17..19/chg19520)`
— *"a small signed integer changing every ~91 frames is the shape of a table index"*. The
conclusion §97 reached does not depend on that, but **the framing was wrong and it should not
stand.**

The frame trace shows the idiom's two chorus instances executing at `dp = 0x0C` and `dp = 0x0E`:

```
   n=80 iw114  0040000C63  dp 0C  mem 000000     the C63 word
   n=81 iw115  00006184CD  dp 0C  mem 000000     the class-6 selector word
   n=82 iw116  00124011CE  dp 0C  mem 000000     the class-4 word -- carries the bit-4 store
   n=83 iw117  01042021CE  dp 0E  mem 009B26     the class-2 `post (p),(p)+2'
   n=84 iw118  0142000C63  dp 0E                 the second instance begins
   n=85 iw119  0000620407  dp 0E
   n=86 iw120  00124011CE  dp 0E  mem 000001
```

and the same run's write census reports **`0C: 144162/3252070`** — cell `0x0C` is written
**3 252 070 times**, about twice per frame, by words inside this frame.

⇒ **the idiom writes the cell it reads.** Its `-17..+19` content is a fixed point of our own
undecoded execution — the class-4 word storing its accumulator back where the next frame's class-4
word will read it — not a quantity the chip is feeding in from a table. Reading it as
"index-shaped" was reading our own output back as evidence.

★ This makes §97's verdict stronger, not weaker: the entire §166/§168 thread was chasing a value
the emulator produces. And it is the same failure §168 committed one level up — RULE 13 in its
general form, *a value that moves is not a signal until you know who moves it.* The pre-registration
`data/PREDICT_SRC11_MEM_2026-09-13.md` carries the same over-reading in its "Why this is being
re-opened"; it is left as written, because a pre-registration that is edited after the run is not
one, and this section is the correction.

⚠ Also visible and worth the next pass's attention: in the first instance `mem[0x0C] = 0`, so the
modulated tap multiplies by **zero**, and in the second `mem[0x0E] = 39718` — 0.5 % of full scale.
Neither cell carries audio (the live audio cells in the same census run to ±2.9 million). **The
chorus's two modulated taps are not reading the delay line.** That is what an undecoded addressing
mode looks like from the outside, and it is the same shape as the input-stage defect §76 fixed:
the arithmetic runs, and it runs on the wrong cell.

## 100. ★★★ THE CLASS-4 TWIN EXISTS — IN THE OTHER PRODUCT'S CORPUS
Tool: [`../tools/class_twins.py`](../tools/class_twins.py). Pre-registration:
[`data/PREDICT_CLS46PTR_2026-09-13.md`](data/PREDICT_CLS46PTR_2026-09-13.md).

§97 left the 159-word `C63` macro needing new evidence and §98 narrowed the question to one field.
The evidence was next door the whole time.

### The asset nobody had pooled
The **SX-WSA1R runs the same uPD6383 ISA**, and its 60 effect programs are disassembled in
`wsa1/dsp/disasm/` by the same `dsp_disasm.py` model. Pooled with the KN5000's 38 images the
corpus is **7558 occurrences of 1129 distinct non-C-format words** — and it contains programs the
KN5000 never shipped, because twelve of the KN5000's named effects are byte-identical to NO
OPERATION (`bit11-family.md` item G) and PITCH SHIFTER is one of them.

`dark-words.md` §4.4 named the lever years of notes ago and nobody could pull it:

> *"`012.4.01.1CE` differs from the K6 input-stage word `012.2.FF.1CE` in **nothing but `class4`
> (4 vs 2) and `addr8`**. A minimal pair across the class field, with one side forced, is the
> cleanest possible probe of what class 4 changes."*

**It is better than that, and the KN5000 corpus does not contain it:**

```
   012.2.01.1CE   x2     WSA1R eff54_pitch_shifter          ★ DECODED
   012.4.01.1CE   x99    53 KN5000 + 46 WSA1R               ⛔ traps
```

Identical in `hi12`, in `addr8` **and** in `lo12`. The only difference in the 36-bit word is
`class4`. ★ And the instrument has a positive control built in: over the pooled corpus the
commonest multi-class triple is `2 ↔ A` on **19** triples, `xor = 8` — it recovers the known
CURSOR-FETCH bit from the data before it is asked anything.

### ★★ And the same program spells the whole macro in class 2
`eff54_pitch_shifter` is the only program in **either** product using `lo12 = 0xC62` instead of
`0xC63`, and its macro is spelled in classes where the pointer arithmetic is FORCED:

```
   99 instances   [ x.0.00.C63 ]   [ 000.6.TT.4CD|407 ] [ 012.4.01.1CE ] [ 104.2.dd.1CE ]
    2 instances   [ 142.0.00.C62 ] [ 022.2.1B.4CD ]     [ 092.2.01.1CE ] [ 184.2.FF.1CE ]
                                     class 2              class 2          class 2
```

Net pointer displacement over the three words after the head:

| model | the 99 class-4/6 instances | the 2 class-2 instances |
|---|---|---|
| shipped (only class 2/A move) | −14 … +9 | **+27** ← an outlier **3× beyond the whole range** |
| classes 4 and 6 move by `(s8)addr8` | +11 … +41 | **+27** ← inside it, and 6 of the 99 land on exactly +27 |

**A model under which the ROM's two spellings of one macro differ by 25 cells, against one under
which they agree exactly.** The `addr8` values line up too: class 4 is always `0x01` and its class-2
twin carries `0x01`; class 6 runs `0x18`–`0x28` and its class-2 counterpart `0x1B`.

⇒ this retires §98's *"index-like, not delta-like"* inference. That was drawn before the twin was
in hand, and the 0 % zero-rate it rested on is explained: the macro never wants a zero delta.

### The gate, and run 1 failed its own first check
The decode has to pass the catalogue regression at the true device default, the way `SRC0B2` did.
`UPD6383_CLS46PTR` (default OFF) is that arm; six predictions were committed before the run,
including the blast radius (**106 KN5000 words, all in the one macro, ZERO in the kernel or output
stage** — checked) and the counter-evidence (`closure_pointer.py` row **V12**: residue +179,
unit-0 pool 8 → 15 distinct nets, closes nothing; its force limited by `closure-pointer.md` item F
having falsified that criterion's own premise, and item G's rejections being at 29 and 31).

⛔ **Run 1: `§100 CLS46PTR (ON): class-4/6 pointer advances performed: 0`** — everything
bit-identical, run discarded. The pointer post-increment lives at the END of `exec_alu()`, the one
site that runs for every word; the two sites a grep for `m_dp = u8(m_dp + s8(addr8(word)))` finds
are the twelve-word K6 whitelist path and a copy inside `exec_decoded()`'s **nop branch**, and I
patched those. ★ **Second time in one session that a fired count caught an arm that could not
reach its target** — §97 was the first, on someone else's experiment. Recorded in the
pre-registration rather than quietly retried.

⛔ **Run 2: 3 150 504 = exactly 2 per frame**, against P1's "≈ 4". Only the class-4 half fired:
`exec_alu()` has a dedicated `if (cl == 6)` branch that returns before the post-increment. ★ **A
non-zero fired count is still not the count you predicted** — P1 was written with the rate in it,
which is the only reason half an arm did not read as a whole one.

✔ **Run 3: 6 301 008 = exactly 4 per frame**, and the chorus's first macro instance walks
`dp 0C → 24 → 25 → 27` — **net +27, the predicted value, to the cell.** P5 holds exactly: the
kernel's cells are bit-identical, including the hand-off `05:177684(-2869494..3486228/chg175660)`.

⛔ **P2 FAILS and the criterion could not have succeeded.** The taps' operand is still 0 and 1;
the cells they read moved (`0x0C`→`0x24`, `0x0E`→`0x47`) and carry the same tiny self-written
values. §97 — mine, from earlier the same day — established that the macro's head never reaches the
SOURCE stage, so **the index the tap is built around never arrives**: moving the pointer relocates
the tap but cannot aim it. A criterion that required the index is a control that cannot fail, seen
from the other side. My error, and it was knowable in advance.

✔ **P4: 10 KEPT, 0 BROKEN** over the ten-program catalogue at the true default — correct rather
than null, since the kernel carries no class-4 or class-6 word.

⚠ **And the harness cannot grade the body side.** `fx_ab.lua` steps UP from TYPE 0 and §176's
D-RAM census accumulates from boot ("cells present" grows 12 → 109 across the sample), so diffing
it between arms conflates every program walked through. My first pass at it read the PARAMETRIC
EQ's five band cells as losing half their movement — **but PEQ contains no class-4 or class-6
word**, so the arm cannot touch it. ⇒ §176's census in a `catalogue_regression.sh` capture is
**CUMULATIVE, not per-program**; the frame-local instruments (`pickup_cells.py`,
`src0b2_regression.py`, the traced frame) are the per-program ones.

### Verdict: NOT PROMOTED, and coverage is unchanged at 75.0 %
The static case stands on its own — the cross-corpus twin and the two spellings agreeing at +27 —
and the arm reproduces the predicted walk to the cell with no regression. But **a decode is not
promoted on a failed criterion however well the failure is explained**, the runtime case cannot be
made until the bit-11 head is decoded, and `012.4.01.1CE` would additionally owe its **store
target** on a mode the store rule never adjudicated (that rule separates mode 1 from mode 2; modes
4 and 6 were never in its sample). `UPD6383_CLS46PTR` ships default-off with its fired count.

## 101. THE STORE GATE HAS TEN MINIMAL PAIRS, AND THE LFO RAMP WORD IS ONE OF THEM
Tool: `class_twins.py --bit7`. Static, pooled corpus, no emulator.

The gate at `(bit 7, f31 == 1)` is the largest single entry in the leverage table (82 sole / 138)
and `store-gate.md` item D leaves it three-way open. The same instrument that cracked `class4` —
minimal pairs over the pooled KN5000 + WSA1R corpus — aimed at `hi12` bit 7:

**23 pairs differ in bit 7 and in nothing else** (same `class4`, `addr8`, `lo12`, and every other
`hi12` bit), and in **10 of them the bit-7 member is the open gate while its twin is DECODED** and
stores `acc` to `mem[ptr]`. Ten minimal pairs across the one bit whose meaning is open, and nobody
had asked the corpus for them.

```
   0212200000 x236  ↔  0292200000 x4      0012A00200 x1   ↔  0092A00200 x26   ★ THE LFO RAMP
   0212A01412 x100  ↔  0292A01412 x23     00122FF1D5 x8   ↔  00922FF1D5 x4
   00122011CE x2    ↔  00922011CE x2      001224F1C0 x2   ↔  009224F1C0 x2
   0212A001D3 x7    ↔  0292A001D3 x1      0212A011D5 x4   ↔  0292A011D5 x3
   0012A001D5 x2    ↔  0092A001D5 x1      001224B1C0 x1   ↔  009224B1C0 x1
```

★★ **`092.A.00.200` is the LFO ramp word** — 46 occurrences over 26 images, the one whose
increment `lfo-ramp.md` anchors **nine-fold** (`floor(f × 2²³/44100)` for round decimal rates) —
**and its bit-7-clear twin `012.A.00.200` exists.** The LFO is this project's best-anchored
arithmetic; the gate's three survivors differ only in the accumulator; and a phase accumulator is
made of exactly that. In the chorus frame the ramp word sits two slots before the WRAP word
`094.A.00.200` (`f31 == 2`, DECODED, and the one that actually stores the phase to cell `0x07`),
so the block is *ramp → … → wrap-and-store* with the ramp's own store suppressed under the shipped
reading. ⇒ **the question "where does the phase enter the accumulator" is the one the LFO can
answer, and `LD` — bit 7 as a memory-port DIRECTION bit, item D's third survivor — is the reading
that would answer it.**

⚠⚠ **AND A LEAD IS NOT A TEST — this one is post-hoc and is labelled so in the tool.** I noticed
the WSA1R pitch shifter carrying both spellings of one word four slots apart, and only then asked
how often the two share an image: **5 of 10, against a shuffled null of 2.72 ± 0.76**
(P = 0.019, 2000 shuffles preserving each word's image count). The hypothesis was formed on the
data that scores it. A real test needs a prediction made before looking — the obvious one being
the **order** of the two spellings inside an image under the direction reading, which nothing here
has examined.

⛔ **Nothing is anchored and coverage does not move.** What this section delivers is that the
largest open axis now has ten minimal pairs and one of them sits in the machine's best-anchored
arithmetic — which is the first time the gate has had a context with known mathematics that the
29-block solve did not already consume.

## 102. THE STORE GATE, GRADED AT LAST — on a criterion the FIRMWARE supplies
Arm: `UPD6383_CLS46PTR`'s sibling **`UPD6383_GATECLR`**, default OFF — on a word carrying the
bit-4 store **and** bit 7 **and** `f31 == 1`, the accumulator's feedback term is dropped, which is
`store-gate.md` item D's **`clr:before`** survivor exactly. Pre-registrations:
[`data/PREDICT_GATECLR_2026-09-13.md`](data/PREDICT_GATECLR_2026-09-13.md),
[`data/PREDICT_VOLCELL_2026-09-13.md`](data/PREDICT_VOLCELL_2026-09-13.md),
[`data/PREDICT_VOLCELL2_2026-09-13.md`](data/PREDICT_VOLCELL2_2026-09-13.md).

### Attempt 1 — the LFO rate. MISS by 136×
§101 found that `092.A.00.200`, the **LFO ramp word**, is a gate word. The LFO is anchored
nine-fold, so the rate is a known answer: `114 = floor(0.5993 × 2²³/44100)` ⇒ 0.5993 Hz. §228's
read-only rise census on the chorus phase cell:

| | step | mean | rate |
|---|---|---:|---:|
| shipped | 114 … 4 190 812 | 29 098.03 | **152.97 Hz** |
| `GATECLR` | 114 … 3 470 859 | **15 506.97** | 81.52 Hz |
| predicted | 114 … 114 | 114.000 | **0.5993 Hz** |

⛔ MISS. ⚠ **And the criterion assumed the gate word is the phase's only contaminant** — I never
checked that, and it is false. So the miss refutes *"the gate alone accounts for the 255× error"*,
not `clr:before`. ★ The minimum step being exactly the ROM's constant, in both arms, is itself the
standing evidence that the increment path is right and the accumulator path is dirty.

### Attempt 2 — the VOLUME cell. ★ 5 of 5 OUT OF SAMPLE, control 5 of 5
`register-space.md` item A1 is **PROVEN BY CONSTRUCTION** over 49 of 49 algorithms: cell `0x06` is
the user's effect **VOLUME**, written by `EFF_VolumeLoop` after linking. Registered on five TYPE
indices never captured this session:

```
   TYPE  limit | arm OFF (shipped)                        | GATECLR ON
   16    <=22  | (3075606, -8388608..8388607, chg 188032) | (2260027, -1..8388607, chg 13)
   17    <=23  | (8388607, -8388608..8388607, chg 120328) | (2260027, -1..8388607, chg 13)
   18    <=24  | (8388607, -8388608..8388607, chg  10746) | (2260027, -1..8388607, chg 13)
   19    <=25  | (6913425, -8388608..8388607, chg  49056) | (2260027, -1..8388607, chg 13)
   20    <=26  | (8388607, -8388608..8388607, chg  52201) | (2260027, -1..8388607, chg 13)
```

**W1 HIT 5/5. W2 (the control that can fail) HIT 5/5.** W3 (never railed) MISS — and its metric is
a range accumulated from boot, so it localises nothing; the ten-program run puts the remaining rail
in the PARAMETRIC EQ. Plus **10 KEPT / 0 BROKEN** on the hand-off regression at the true default.

★ **Stated correctly, because the obvious phrasing is wrong:** `chg` counts **value changes, not
writes**, and the gate word writes `0x06` in *neither* arm — the shipped reading already suppresses
its store. The arm changes the accumulator, hence the VALUE some other word deposits there. What
is tested is *"the VOLUME cell holds a constant under the arm and churns without it"*.

### What it settles, and what it does not
★★ This is **the strongest evidence the store gate has ever had, and the first time it has been
graded against a criterion the firmware supplies rather than one the emulator can fake.** It is
evidence about **the CLEAR**: taken BEFORE the ALU.

⛔ It does **not** settle the memory access. `LD` passes W1/W2 exactly as `-` does — both stop the
accumulator's junk reaching whatever writes `0x06`. The axis goes **three-way → two-way**, and
`alu_decoded()` still refuses all 138 words. **Coverage is unchanged at 75.0 %**, which is what the
pre-registration said a pass would leave.

### ⚠⚠ FIVE defective criteria in one session, and the last two were repeats
§100's P2 needed an index the arm could not supply. The class-4/6 P1 was patched at the wrong site
**twice**. §102's first P2 assumed a sole cause. The first VOLUME criterion used a per-program
threshold against a **cumulative** census — after I had documented that census as cumulative in §100
— and W3 did it again. Every one was caught by the criterion or its control rather than by the
result, which is the case *for* writing them down; but the rate is itself the finding, and the fix
is not more care at the same speed. **A per-program capture harness — one program per boot, no type
walk — would have removed three of the five by construction**, and that is the instrument the next
pass should build before it designs another criterion.

## 103. THE INSTRUMENT THAT REMOVES THE MISTAKE — and the store-gate result it produces
Device: **`UPD6383_CENSUS_PERPROG`** (default OFF, read-only). Data:
[`data/volcell3_perprog_2026-09-13.txt`](data/volcell3_perprog_2026-09-13.txt).

§102 ended with five defective criteria, three of them the same defect: the capture harness steps
UP from TYPE 0, so a capture of TYPE *n* has walked through *n+1* program loads, and §176's D-RAM
census and §228's rise census both accumulate **from boot**. I documented that in §100 and then
wrote three criteria that ignored it. ★ **The fix is not more care at the same speed — it is an
instrument that cannot be read the wrong way.**

With the arm on, both censuses are cleared when a new I-RAM program arrives, so a capture's numbers
describe the program it traced; the census header line now states which mode produced it,
**including a warning on the default path**, because every census number this project has published
was cumulative and nothing said so.

### And with it, the store-gate result comes out clean
The same five out-of-sample programs, re-measured per-program:

```
   TYPE | arm OFF (shipped)                       | GATECLR ON
   16   | (3075606, -599857..8388607, chg 177316) | (2260027, 0..2260027, chg 1)
   17   | (8388607, -599857..8388607, chg 109605) | (2260027, 0..2260027, chg 1)
   18   | (8388607,       0..8388607, chg     11) | (2260027, 0..2260027, chg 1)
   19   | (6913425,       0..8388607, chg  38311) | (2260027, 0..2260027, chg 1)
   20   | (8388607,       0..8388607, chg  41456) | (2260027, 0..2260027, chg 1)
```

★★★ **With the arm the VOLUME cell is written EXACTLY ONCE per program, holds a plausible depth,
and is never railed — 5 of 5.** Without it the cell is **railed in 5 of 5** and churned 11 … 177 316
times. That is `PREDICT_VOLCELL`'s W1 and W3 as originally intended, on the instrument that makes
them mean what they say, over programs captured for the first time today, with the control firing
on every one — and with `PREDICT_VOLCELL2`'s cumulative-form W1/W2 already passed 5/5 beforehand.

### What is now determined, stated at exactly its strength
The arm implements *"the incoming accumulator does not contribute to the gate word's result"*.
⇒ **every surviving family that carries the accumulator through the gate word is refuted** —
including the shipped `-/clr:never` — because those are the machines that rail and churn a cell the
firmware writes once and the ROM proves is the user's VOLUME (`register-space.md` item A1, 49 of 49
algorithms).

⛔ It does **not** choose between `-`, `ST(acc→else)` and `LD`: all three can discard the incoming
accumulator, and `else` is unreadable by construction. The axis narrows from *what happens to the
accumulator AND the memory* to **the memory access alone**.

⛔ **Coverage is unchanged at 75.0 %.** `alu_decoded()` refuses these 138 words for the memory
access, which this does not touch — exactly as both pre-registrations said a pass would leave it.

## 104–106. ★★★★★ THE STORE GATE IS DETERMINED — 75.0 % → 77.6 %
Pre-registration and every run: [`data/PREDICT_GATECLR_2026-09-13.md`](data/PREDICT_GATECLR_2026-09-13.md).

`store-gate.md` item D left the gate at `(bit 7, f31 == 1)` **three-way open** — `none`,
`ST(acc→else)`, `LD`, each with three clear placements — and said so because its 29 blocks could
not separate them. It is now closed, by **elimination on criteria the ROM and the FIRMWARE supply**,
each of which demonstrably CAN fail, because a different arm made each of them fail.

| reading | refuted by | the measurement |
|---|---|---|
| `-/clr:never` — **the shipped one** | the **VOLUME** cell | `0x06` is the user's effect depth, PROVEN BY CONSTRUCTION in 49 of 49 algorithms and written once by `EFF_VolumeLoop`. Shipped, it is **RAILED in 5 of 5 out-of-sample programs** and churned **11 … 177 316** times |
| `-/clr:after` | the **LFO** | the phase cell vanishes from both instruments — absent from the non-zero census, no row in the rise census |
| `LD@before` | the **LFO** | `step 36 … 4 194 103, mean 2 082 744`, a **4.0-frame period** against a ROM constant of **114 per frame** |
| `LD@after` | the **LFO** | phase cell dead |
| **`-/clr:before`** | — | VOLUME written **once**, unrailed, **5 of 5**; the LFO alive with its **minimum step exactly 114**; **10 KEPT / 0 BROKEN** on the hand-off regression at the true default |

★★★ And `ST(acc→else)/clr:before` is **the same machine** as `-/clr:before`: `gate_settle.py:70`
declares the `else` key *"a memory key no pointer can ever equal"*, so nothing can read what it
writes. ⇒ *"is there a store at all"* remains **unanswerable — and stops mattering for EXECUTION**,
which is the only question `decoded()` asks.

### Promoted, and verified the way §56 demands
`UPD6383_GATECLR` default **1** (`=0` is the control), **re-verified with NO ENVIRONMENT SET AT
ALL**: hand-off `05:177684(-2869494..3486228/chg175660)` unchanged, `06` written once at 2 260 027,
`07` alive. Guard 7 in `dsp_disasm.py` and its C++ mirror now admit `f31 == 1`; **mirrors agree
3057/3057**, `dsp/verify.py` **BYTE-MATCH OK**, the 24 documentation pages regenerate and
`test_hle_permanence.py` passes.

**COVERAGE: tier 1 74.0 % → 76.6 % (+78 body words), 77.6 % with tier 1b. Frame floor 70.4 % →
72.2 %.** The 82 words render as real instructions for the first time — `mac.b c,c+,(p)+0 ;
store SUPPRESSED (bit7)`.

⚠ Two things this does NOT claim. The LFO's **rate** is still wrong under the survivor (81 Hz
against the ROM's 0.599 Hz) — §102 measured that the gate was never its only cause, and that defect
is open. And `f31 == 0` still traps: there the two surviving GATE CONDITIONS disagree about whether
`mem[ptr]` is written at all, which is not an accumulator question and nothing here touches it.

### ★ What made it work, after five defective criteria
Not care — an **instrument**. §103's `UPD6383_CENSUS_PERPROG` made the censuses per-program, and
`register-space.md` item A1 supplied a known answer the emulator cannot fake. Every criterion that
decided something here is one the ROM or the firmware states: the VOLUME cell's write-once, and the
LFO's `floor(f × 2²³/44100)`. The three that failed earlier were all criteria I had constructed.

## 107. ⛔ THE DELAY CRITERION IS BLIND TO `ACT 0x0B` — measured, with its reach test passing
Tool: [`../tools/sd_act0b.py`](../tools/sd_act0b.py). Output:
[`data/sd_act0b_2026-09-13.txt`](data/sd_act0b_2026-09-13.txt). Static, no emulator.

`ACT 0x0B` is now the second-largest entry in the queue (62 sole, 66 occurrences), and
`act0b-reverb.md` item H stopped exactly here: *"picking between [the three surviving readings]
needs known mathematics the reverb does not supply — the diffuser gains are known but there is NO
REFERENCE RESPONSE."* §106's method says what to do about that: find a criterion the ROM states.

SINGLE DELAY has one — an impulse must return at the cascade lag **1001** carrying **45 074** =
`((c·c)>>23)·h>>23` from the program's own coefficients, and `sd_rerun.py` self-tests that harness
**13 of 13** — and `prog09_single_delay` carries **three ACT-0x0B words** (`w0`, `w9`, `w32`).

### It reaches the code and it still cannot see it
```
   REACH TEST      ACT 0x0B fired 13 812 times in one scoring pass    ✔ (expected ~6 906+)
   CONTROL         known-good baseline reproduces (1001, 45074)       ✔
   ADDRESSING      pointer map over the 6 readings: 1 distinct        ✔ INVARIANT
   THE SWEEP       none / tA<-bus / tB<-bus / tA<-acc / tB<-acc / mem<-bus
                   ALL SIX -> 1001:45074                              ⛔ 6 of 6 ACCEPTED
```

**The criterion has no power on this code**, and that is a measurement rather than a suspicion: it
demonstrably CAN fail — the *shipped* `ACT 0x0D`/`0x0E` pair fails it, putting 45 074 at lag 500
(§234's own recorded result, which is why the baseline pair here is chosen mechanically as the
first in menu order that reproduces the ROM answer, and printed).

⇒ **at a09's three sites the six readings are the same machine.** What `ACT 0x0B` writes never
reaches the delay output in this program.

### And the static generalisation does NOT carry
If the six readings were indistinguishable wherever all three of their destinations (tempA, tempB,
`mem[ptr]`) are dead downstream, those words would be executable by §96's lemma. Measured over the
62: **0 qualify.** `mem[ptr]` is live at every one of them under the honest test (any later memory
read at all), which is what you would expect of a machine that reads memory constantly. The a09
result is therefore a fact about a09's three sites, not a route to the other 59 — and the reason it
holds there must be the *cell* the write lands on, which needs the pointer walk per site rather
than a liveness flag.

⛔ **Coverage unchanged at 77.6 %.** What this earns: `ACT 0x0B` cannot be decided by the delay
line, so the next attempt should not be built on it — and the reason is now on file with a passing
reach test instead of being rediscovered.

## 108. ★★ §96's STATIC BLINDNESS WALK, VALIDATED BY THE MACHINE — 5 of 5
Pre-registration: [`data/PREDICT_F31BLIND_2026-09-13.md`](data/PREDICT_F31BLIND_2026-09-13.md).
Data: [`data/f31blind_2026-09-13.txt`](data/f31blind_2026-09-13.txt).

§96 admitted 32 words on a lemma and graded itself *"DETERMINED-conditional, not FORCED"*. The
method that closed the store gate suggested the missing half: **sweep the reading and look at the
machine.** The device can express three readings of `f31 == 5` (`m_bx_f5`, SPEC bits 50-51:
LOAD / ADD / HOLD), so run each program under all three with the per-program census and ask whether
anything moves.

| TYPE | program | `f31 == 5` fired | censuses | frame trace | machine says |
|---|---|---:|---|---|---|
| 0 | chorus | 1 601 712 | identical | **differ** | BLIND |
| 2 | enhancer | 2 154 408 | identical | **differ** | BLIND |
| 4 | phaser | 2 195 822 | **DIFFER** | differ | OBSERVED |
| 15 | parametric EQ | 2 449 160 | **DIFFER** | differ | OBSERVED |
| 18 | auto wah | 3 060 922 | **DIFFER** | differ | OBSERVED |

★★ **The instrument says BOTH answers**, so "identical" is a null with power — G3 and G4 both hold:
the frame trace differs in every row (the arm demonstrably changed the machine's internal state),
and three of five programs move a census.

★★★ **And it agrees with §96's static walk 5 of 5.** The enhancer's two sites are the ones §96
called BLIND; the phaser's and the EQ's are the ones it called live; the auto wah has three live
sites and differs. Where the walk says the accumulator is destroyed unread, the machine cannot tell
the three readings apart. Where it says the accumulator is read, the machine can.

⇒ **§96's lemma is no longer conditional on an argument** — the walk's verdicts are reproduced by
the hardware model on five programs, with an instrument shown able to say the opposite.

⛔ **No new words are admitted and coverage stays at 77.6 %.** That is the point: the statically-live
sites are empirically observed, exactly as the walk said, so there was nothing here to harvest. The
run's value is that the 32 words §96 admitted now rest on a measurement as well as a lemma.

⚠ Two limits, stated. The observable set is the censuses — broad (all 256 D-RAM cells with ranges
and change counts, the rise census, the per-site accumulator censuses, the write counts) but **not
the audio**; a difference that altered only the output samples would read as "blind" here. And
`f31 == 4` **fired 0 times** in the chorus, so the two arms aimed at it said nothing; it is untested
and is recorded as such rather than swept in with the rest.

## 109. THE C-FORMAT DESTINATION: 6 → 4, and a 255× lead on the LFO
Pre-registration and result: [`data/PREDICT_CFMTDST_2026-09-13.md`](data/PREDICT_CFMTDST_2026-09-13.md).

C-format became the queue's largest entry once the store gate closed — **68 words, every one
trapping** — and `status()` has called its operation MEASURED with the destination OPEN since it
was written, *"1 of 6 enumerated"*, with nobody ever having run the six. New arm
`UPD6383_CFMTDST` (default 0 = the shipped latch) runs them.

| dest | hand-off `0x05` | LFO mean step (ROM says 114) | |
|---|---|---:|---|
| latch (shipped) | intact | 15 543.93 | |
| acc | intact | 15 543.93 | |
| **P** | **14 — DESTROYED** | **128.30** | ⛔ refuted / ★ the lead |
| **tempA** | **53 — DESTROYED** | 167.40 | ⛔ refuted |
| tempB | intact | 15 543.93 | |
| **mem[ptr]** | **45 — DESTROYED** | LFO DEAD | ⛔ refuted |
| reg[addr8] | intact | 15 543.93 | **bit-identical to the latch** |

**Three of six are refuted** on an anchored criterion: they collapse the per-unit hand-off cell
from a live ±2.9 M audio signal to a frozen constant, and that cell is the one §76 promoted
`SRC0B2` on across 8 programs. ★ `latch` and `reg[addr8]` are **bit-identical** — the register-file
destination cannot be told apart from a latch nobody reads — but `acc` and `tempB` move other
censuses, so the four survivors are **not one machine**.

⛔ **The words stay undecoded. Coverage is unchanged at 77.6 %.** The pre-registration named this
outcome in advance (H5) so it is a result and not a disappointment.

### ★★ The lead is larger than the result
**Destination `P` takes the chorus LFO from 153 Hz to 0.674 Hz** — `step 128..464046, mean 128.30`
against the ROM's **114** — **within 12.5 %** of `floor(0.5993 × 2²³/44100)`, where the shipped
model is out by **255×**. Nothing else this session moved that number into the right order of
magnitude, and §102 left precisely this open: *"the gate is not the only cause."*

It cannot be the answer as it stands, because it destroys the hand-off. What it does is **name the
path**: the C-format immediate is implicated in the LFO rate defect, and the next pass has
something specific to pull on instead of a symptom.

## 110. `SRC 0x11`: the anchored criteria are BLIND, and the diff says exactly why
Pre-registration and result: [`data/PREDICT_SRC11_2026-09-13.md`](data/PREDICT_SRC11_2026-09-13.md).

`SRC 0x11` — 54 sole / 77 words over 29 images, 5 of them in the resident kernel — has three
readings, all already in the device behind the SPEC mask: the current unit's accumulator (shipped),
`ACCB`, and `mem[ptr]`. None had ever been swept against the criteria that closed the store gate.

**All three leave the hand-off cell `0x05`, the VOLUME cell `0x06` and the LFO phase `07`
bit-identical.** No refutation.

### ★ And the diff localises the blindness, which is the useful part
```
   §176 D-RAM CENSUS   IDENTICAL   -- 0 of 12 cells differ
   §228 LFO RISE       IDENTICAL
   §162                IDENTICAL
   §175 PER-SITE       DIFFER      -- `L' 0..8388607 vs 0..7474246, and `P' with it
   D-RAM WRITES        DIFFER
```

The readings **do** feed different operands into the multiplier — `§175` shows it — and the
**resulting D-RAM state is bit-identical, cell for cell.** The difference is absorbed before
anything is stored.

⇒ **that is why the store-gate method does not transfer here.** The hand-off, VOLUME and the LFO
phase are all D-RAM cells, and no D-RAM cell separates the readings. The gate was decidable because
it changed the accumulator wholesale; a SOURCE swap changes a multiplicand the datapath absorbs.

★ **The instrument the next pass needs is named**: one that grades **`L` and `P` at the `SRC 0x11`
sites** — `§175` already reports both — against a program where the multiplicand at such a word is
known from the ROM. The same shape as SINGLE DELAY's lag-1001 product, applied to an operand rather
than an output.

⛔ Coverage unchanged at 77.6 %.

### ⚠ Three negatives in a row, and they are not the same negative
§107 (`ACT 0x0B` vs the delay line): the criterion reaches the code and cannot see it.
§109 (C-format): the criterion refutes 3 of 6 and cannot separate the rest.
§110 (`SRC 0x11`): the criterion cannot see it, **and the diff says the whole D-RAM is insensitive
to the axis**. Each one removes a specific experiment from the queue and names what would replace
it. That is what a queue is for.

## 111. ⛔ `SRC 0x11`'s OPERAND IS CONSUMED — 5 of 5, and the chorus was the exception
Pre-registration and result:
[`data/PREDICT_SRC11BLIND_2026-09-13.md`](data/PREDICT_SRC11BLIND_2026-09-13.md).

§110 measured, on the chorus, that `SRC 0x11`'s three readings move the operand (`§175`) while the
whole D-RAM census comes out **bit-identical**. I read that as *"the operand is never consumed"*,
which would have made the **54 words refused for this axis alone** executable by §96's lemma — a
+1.8 % coverage move — and wrote it into a pre-registration.

**Five programs say no.**

```
   TYPE  program        sites   §175 (K1)     §176 (K2)
   2     enhancer         4     differ(3)     DIFFER(3)
   3     flanger          4     differ(3)     DIFFER(3)
   5     ensemble         7     differ(3)     DIFFER(3)
   14    no operation     2     differ(3)     DIFFER(3)
   16    auto pan         4     differ(3)     DIFFER(3)
   ---   chorus (§110)    -     differ(3)     IDENTICAL   <- the exception
```

⇒ **the operand IS consumed. No words are admitted and coverage stays at 77.6 %.**

### What is refuted is my extrapolation, not the measurement
§110's chorus numbers stand. The sentence built on them does not: **the chorus's D-RAM being
insensitive is a property of the chorus, not of the code.**

★ **Sixth over-read of this session, and the sixth stopped by a criterion written before the run.**
K1 and K2 exist so that "the censuses agree" cannot be quoted without "and they were able to
disagree" — here they disagreed, five times out of five.

⚠ **And it bounds §108's method: one program's null does not generalise.** §108's blindness
conclusion was drawn over five programs with three showing the opposite, which is why it holds;
§110's was drawn over one, which is why it did not. Any future use of the sweep-and-diff instrument
needs the sample, not just the instrument.

## 112. ★★★ THE BLOCK TERMINATOR IS EXECUTABLE — 77.6 % → 78.5 %
The queue's `class 1` entry turned out to be one word shape. All **19 words refused for that axis
alone** are `xxx.1.0E.000` — class 1, `addr8 = 0x0E`, `lo12 = 0x000` — differing only in `hi12`.

★ That is **the block terminator**, and its identity is MEASURED, not guessed: `host-side.md` item
B1 — *"the class-1 index word is **the last word of every body image** and it carries `addr8 =
0x0E` in **37 of 37** unit-0 images and `0x0F` in the one unit-1 image"* — and
`instruction-set.md` already publishes the form (*"terminator / END OF BLOCK — `class4 == 1 &&
addr8 ∈ {0E, 0F}`"*).

So this is exactly §90's argument for the delay escape: **the CLASS TEST is what refuses the word,
and the word's own form explains the class.**

### The §91 check, which is the reason §90's first version was wrong
§91 caught §90 admitting words on the belief that their ALU half never ran. So: does a terminator's
ALU half run? `upd6383.cpp`'s sequencer answers in its own comment —

> `// ---- the transfer, AFTER the word has done its datapath work -------`

— the datapath executes first, then the call/return. ⇒ its `SRC` / `ACT` / `f31` apply and must be
anchored, which for all 19 they are (`SRC 0x00`, `ACT 0x00`, `f31 ∈ {0,1,2}`, no store, no bit-11,
no pointer mode). Graded on `_alu_half_anchored()`, exactly as the escape is.

★ And `text()`'s own comment had already noticed the gap without closing it: *"the word still
performs its datapath work AND ends the block … class 1 cannot reach here, so the unit-tagged
CALL/RETURN form is unreachable by construction."*

### Result
```
   all 38 distinct body images   2974   2303  77.4%   +31  78.5%
   FRAME FLOOR as linked          216    159  73.6%
   resident kernel                 83     39  47.0%
```
**tier 1 76.6 % → 77.4 % (+25 words), 78.5 % with tier 1b; the frame floor 72.2 % → 73.6 %.**
They render as `endblk  unit0 ; END OF BLOCK -- the image's last word`. Mirrors agree
**3057/3057**, `dsp/verify.py` BYTE-MATCH OK, 24 doc pages regenerated, permanence test PASS.

⚠ **NOT claimed: the call/return itself.** `upd6383.cpp` calls its sequencer model *"the frame
SEQUENCER's model, not the ISA's"* and that stays true — this says **the word is executable**, not
that the jump is derived from the encoding. Disjoint from the delay escape by construction:
`is_end` needs `hi12` bit 10 set with bit 11 CLEAR; the escape needs bit 11 SET.

## 113. `f31 == 4`: outcome C — and what five rounds of this say about the instrument set
Pre-registration and data: [`data/PREDICT_F31_4_2026-09-13.md`](data/PREDICT_F31_4_2026-09-13.md),
[`data/f31_4_2026-09-13.txt`](data/f31_4_2026-09-13.txt).

§108 measured `f31 == 4` firing **0 times** in the chorus. The shape census found where it does
run: 12 of the 34 words refused for that axis alone are one shape, **`018.A.00.1D5`**, whose
`f31 == 0` twin `010.A.00.1D5` — the same word differing in `f31`'s **bit 2 alone** — is DECODED.

```
   TYPE  program        f31=4 fired   §176        anchored cells (05 / 06 / LFO)
   13    compressor     1 196 405     DIFFER(3)   ALL THREE IDENTICAL
   14    no operation     485 513     DIFFER(3)   ALL THREE IDENTICAL
   18    auto wah         536 818     DIFFER(3)   ALL THREE IDENTICAL
```

**M1 HIT** — it fires everywhere, which is the precondition §108 could not meet. **M2 MISS** — the
D-RAM census differs, so the words are not blind. **M3 MISS** — no reading is singled out: the
hand-off `0x05`, the VOLUME cell `0x06` and the LFO are **identical across LOAD / ADD / HOLD in all
three programs**. ⇒ **M4, outcome C**, named in advance. No words admitted; **coverage unchanged at
78.5 %**.

### ★★ Five rounds now say the same thing about the instruments, and it generalises
| § | axis | result |
|---|---|---|
| 107 | `ACT 0x0B` | the delay criterion reaches it and cannot see it |
| 109 | C-format destination | refutes 3 of 6, cannot separate the other 4 |
| 110 | `SRC 0x11` | the operand moves; **no D-RAM cell** distinguishes the readings |
| 111 | `SRC 0x11` blindness | but the operand IS consumed — 5 of 5 |
| 113 | `f31 == 4` | the census moves; **the anchored cells do not** |

★ **The three criteria that closed the store gate — the per-unit hand-off, the VOLUME cell and the
LFO phase — are sensitive to a change in the accumulator WHOLESALE and insensitive to a change in
one word's arithmetic.** The gate and the C-format destination were decidable because they alter
the accumulator or memory globally; `f31`, `SRC 0x11` and `ACT 0x0B` alter one word's contribution,
which the datapath absorbs before it reaches any of those three cells.

⇒ **that is what the next criterion has to be: local to the word — its operand `L` and its product
`P`, which `§175` already reports — graded against ROM-known arithmetic, not a downstream cell.**
The same shape as SINGLE DELAY's lag-1001 product, applied at the instruction instead of the
output. Stated here because it is the common cause of five separate negatives, and finding it again
from scratch would cost another session.

## 114–115. ★★★★ THE C-FORMAT IMMEDIATE LOAD DECODES — 78.5 % → 80.4 %
Pre-registration and all runs:
[`data/PREDICT_CFMTDST_2026-09-13.md`](data/PREDICT_CFMTDST_2026-09-13.md).

### §114 — the enumeration was missing its best-motivated member
§109 swept six destinations and mode 6 indexed the register file by **`addr8`**. That is the wrong
half of the word: `is_setvec(w) = is_c40(w) && is_vector_lo12(lo12(w))` — **`lo12` is what selects
the destination** on a C40 word, PROVEN (K5) for `lo12 = 0x445` / `0x446`, the per-unit CALL VECTOR
registers — while `addr8` carries the PAYLOAD under the same family's payload rule. Mode 7 is
`reg[lo12 & 0xFF]`, the member the enumeration should have had.

**MEASURED: mode 7 is BIT-IDENTICAL to the shipped latch on 8 of 8 programs** (chorus, enhancer,
flanger, phaser, ensemble, gated reverb, multi tap delay, parametric EQ), with the arm firing
~28 M times in each. ⇒ **the register that destination names is never read back in the frame.**

### §115 — and the structural half, which is a proven sub-case rather than a preference
`is_c40` is **ONE instruction**: opcode `0x620`, the payload rule holding **57 of 57** inside it
and 2 of 11 outside. Its destination is selected by `lo12`, and for two `lo12` values that
destination is **proven** to be a register. ⇒ for one opcode the destination field selects among
**registers**; `acc` or `tempB` would mean the same opcode writes a register for two `lo12` values
and the accumulator or a temporary for the others, which is not how a destination field works.

Combined: the destination is a register, and the register is never read.
⇒ **the 57 `is_c40` words are EXECUTABLE**, rendering as
`ldreg   r4C,#25          ; immediate -> the register lo12 selects`.

**PROMOTED:** `UPD6383_CFMTDST` default **7** (`=0` restores the latch as the control) — a
**zero-risk** default, bit-identical by the 8-of-8 measurement — and **re-verified with NO ENV SET
AT ALL**: hand-off `05:177684(-2869494..3486228/chg175660)`, `06` written once, `07` alive, all
three byte-for-byte what the pre-promotion no-env run reported.

```
   all 38 distinct body images    2974   2360  79.4%   +31  80.4%
   FRAME FLOOR as linked           216    163  75.5%
   reverb image (algo 16)          133    122  91.7%
```
**tier 1 77.4 % → 79.4 % (+57 words), 80.4 % with tier 1b; the frame floor 73.6 % → 75.5 %.**
Mirrors agree **3057/3057**, BYTE-MATCH OK, 24 doc pages regenerated, permanence test PASS.

⛔ **NOT extended to the 11 non-`is_c40` C-format words.** `k3-pointers.md` §8 item 3 warns
explicitly against carrying the payload rule past opcode `0x620`, and this does not: they keep
trapping.

## 116. THE AUTO-PAN DISCRIMINATOR IS BLOCKED ON THE LFO RATE DEFECT — and that is the chain
Pre-registration and data:
[`data/PREDICT_F31_5_AUTOPAN_2026-09-14.md`](data/PREDICT_F31_5_AUTOPAN_2026-09-14.md).

`f31-high.md` §4 item 1 named the instrument and nobody had run it: *"★ AUTO PAN, not PARAMETRIC
EQ … whose observable is a ramp, not a filter response, so it does not run through a biquad's
`f31 = 0` barrier. This is the discriminator this pass was looking for and did not use."* §108's
sweep had covered five programs and auto pan was not among them.

**Q1 HIT** — `f31 = 5` fires 2 480 216 times on TYPE 16. **Q2 MISS** — the rise census is identical
across ADD / LOAD / HOLD, and shows no ramp to read: the moving cells step `4..3 415 889`,
`6..4 194 283`, `152..2 313 079` — **nothing at or near 228**, which is
`AUTO PAN C-RAM 01 = 0x0000E4 = floor(1.1986 × 2²³/44100)`, the ROM's own constant for its 1.2 Hz
pan.

⇒ the reasoning was right about the KIND of instrument and its **precondition is not met**: the
ramp is not clean. The LFO-rate defect §102 measured (153 Hz against the ROM's 0.599 Hz) sits
upstream of the discriminator.

### ★ The chain, stated
```
   f31 3/4/5/7  ⟵ blocked on ⟵  a clean LFO ramp  ⟵ blocked on ⟵  the LFO RATE DEFECT
                                                        ⟵ §109 named the path: the C-format
                                                          destination `P' takes it 153 Hz → 0.674 Hz
                                                          (ROM: 0.5993) while destroying the hand-off
```
That is worth more than another inconclusive sweep: it says **which problem to solve first**, and
§109 already has a lead on it. It also explains §113's and §108's results from one cause rather
than three — a broken ramp cannot grade an accumulator field, whichever program you point it at.

## 117. ★★★ THE ROM's LFO CONSTANT REPRODUCED TO 0.6 % — and the trade that blocks it
Pre-registration and data:
[`data/PREDICT_CFMTPCLR_2026-09-14.md`](data/PREDICT_CFMTPCLR_2026-09-14.md).

§116 put the chain in the open: `f31` 3/4/5/7 is blocked on a clean LFO ramp, which is blocked on
the rate defect. §109 named the path — the C-format destination `P` took the chorus from 153 Hz to
0.674 Hz — and §115 then settled that destination as `reg[lo12]`, so the improvement had to be a
**side effect**: writing `P` overwrote the **stale product**, which §102's trace named as the
contaminant.

A C-format word issues no multiply, so the one-slot product after it is not that instruction's.
**Invalidating** it tests the side effect without the injection that wrecked the hand-off.

```
   arm ON   07: step 114..402 306    mean    114.2560   =  0.60065 Hz
   control  07: step 114..3 470 859  mean 15 543.9286   = 81.7 Hz
   ROM                                      114         =  0.5993 Hz
```

★★★ **`mean step 114.2560` against the ROM's `114`; 0.60065 Hz against 0.5993 — 0.6 %.** The
shipped model is 255× wrong. This is the first time the project has reproduced
`floor(0.5993 × 2²³/44100)` end-to-end from the running machine rather than deriving it.

⛔ **And the hand-off cell `0x05` goes to ZERO.** The audio path dies. NOT promoted: by the
pre-registration that is "the same trade §109 refused".

### ★★ The trade is the finding
The two halves together say what neither says alone: **the audio path is currently living on the
stale product, and the LFO is being poisoned by the same value.** One register, two consumers,
opposite requirements.

⇒ **the defect is not the stale product — it is that nothing drives `P` for the audio path there.**
★ Which is exactly the shape §240 found for the EQ: *"the baseline's EQ activity is the KERNEL'S
RESIDUE being filtered."* Two independent routes, one diagnosis.

### The question that replaces `f31`
**What should be driving the product register where the C-format word currently leaves a stale
one?** Answer that and the LFO is right, the audio keeps its operand, and the auto-pan
discriminator §116 wanted becomes usable — which is the whole `f31` family. That is a better next
question than any of the four open fields, and it was not visible before tonight.

## 118–119. THE LFO's CONTAMINANT, BRACKETED TO THE KERNEL's OWN C-FORMAT WORDS
Pre-registrations: [`data/PREDICT_CFMTPCLR_2026-09-14.md`](data/PREDICT_CFMTPCLR_2026-09-14.md),
[`data/PREDICT_CALLFLUSH_RETEST_2026-09-14.md`](data/PREDICT_CALLFLUSH_RETEST_2026-09-14.md).

§117 fixed the chorus LFO to **0.6 %** of the ROM's constant by invalidating the product at every
C-format word — and emptied the hand-off cell. Two further arms bracket where that came from:

| arm | LFO mean step (ROM: **114**) | hand-off `0x05` |
|---|---:|---|
| shipped | 15 543.93 | ✔ live |
| **§117** clear `P` at EVERY C-format word | **114.2560** | ⛔ **zero** |
| **§118** clear `P` at `is_c40` only | 15 543.93 | ✔ live |
| **§119** clear `P` at the block CALL (`CALLFLUSH`, fired 3 181 374) | 15 543.93 | ✔ live |

**§118's S3 HIT confirms the census argument** — the kernel and output stage carry **zero**
`is_c40` words (their eleven are opcodes `605/602/621/625/632/60B/600`; a body's four are `0x620`),
so restricting to `is_c40` cannot touch the kernel, and the hand-off lives. **S2 MISS** says the
body's C40 words are not the contaminant.

**§119 re-tested `CALLFLUSH`** — reverted by §56 at a default that no longer exists — and it does
nothing for the ramp now. ⇒ §56's revert stands **and the benefit it was kept alive for does not
reproduce either**. ★ §94's rule cuts both ways: a refutation expiring does not make a claim true,
and here the CLAIM expired too.

### ⇒ The question, now per-site
Only the **KERNEL's own** C-format words matter: clearing there fixes the ramp and starves the
input stage. They sit at **iw1, 15, 22, 29, 31, 40, 48, 56** — spanning both sides of the **iw45**
that writes the hand-off.

★★★ **WHICH of them does the input stage consume, and which does the LFO inherit?** If they are
different words, clearing at one and not the other fixes both — a per-word experiment with a known
answer at each end (the ROM's 114, and a live hand-off). That is a far better-posed question than
"the LFO rate is wrong", and it is what §116's chain reduces to.

## 120. ★★★★★ ONE WORD — `iw40` — AND IT IS ONE OF THE FIVE UNSOLVED `0x820` WORDS
Pre-registration and data: [`data/PREDICT_PCLRIW_2026-09-14.md`](data/PREDICT_PCLRIW_2026-09-14.md).

§118/§119 bracketed the LFO's contaminant to the kernel's own eight C-format words. Clearing the
product at each slot in turn:

```
   iw    LFO mean (ROM 114)   hand-off 0x05
    1,15,22,29,31,48,56       15 543.93   live      -- inert on both counts
 ★ 40                       ★   114.2560   ⛔ ABSENT  -- the ROM's number, and the audio dies
```

**U2 HIT at exactly one slot; U3 MISS at the same one.** ⇒ one word serves both consumers: the fix
is **not a clear but a DRIVER** — something must SUPPLY `P` at `iw40` rather than leave the residue.

### ★★★ And `iw40` is `0C4A1C0820`
It is one of the **five `lo12 = 0x820` words**, all in the kernel, and that family is this project's
longest-standing unsolved one. `closure-pointer.md` item H closed a whole pass on it with a null —
*"The five `0x820` words are not solved, and the field search says so cleanly. Every contiguous
bit-field of the 36-bit word was enumerated: no field makes all five …"* — and item B falsified them
as the frame-closing pointer reload.

⇒ **two long-standing open problems are one problem.** The unsolved `0x820` semantics are
load-bearing for the audio input path AND for the LFO rate, and `w40` is the single site. Neither
end showed that: `closure-pointer.md` was looking for a pointer reload, and the LFO work was looking
for an accumulator contaminant.

### The question that replaces everything above it
Not *"what clears `P`"* but **"what does `w40` drive `P` with?"** — a C-format word, opcode `0x625`,
A = 14, five slots before the `iw45` that writes the hand-off, whose product the input stage
consumes and the body's LFO inherits. **A driver that satisfies both ends has a known answer at each
end**: the hand-off live at ±2.9 M, and the ramp at the ROM's **114**. That is the best-posed
question this chain has produced, and it is where the `f31` family (117 words), the auto-pan
discriminator and the audio path all now meet.

⛔ Coverage unchanged at 80.4 %: this decodes no word. It says which one word to decode next.

## 121. ★★★★★ THE SX-WSA1R SHIPS A SECOND COPY OF THIS KERNEL HEADER
Tools: [`kernel_homolog.py`](../tools/kernel_homolog.py), [`cfmt_opcode.py`](../tools/cfmt_opcode.py).
Data: [`data/kernel_homolog_2026-09-14.txt`](data/kernel_homolog_2026-09-14.txt).
Pre-registration: [`data/PREDICT_HI6C_2026-09-14.md`](data/PREDICT_HI6C_2026-09-14.md).

§120 asked *"what does `w40` **drive** `P` with?"* and the single-product corpus cannot answer it:
`cfmt_opcode.py --control` measures that in this ROM the C-format opcode is a **function of
(destination, payload)** — no `(lo12, imm13)` pair is ever seen with two opcodes — and `--twins`
finds **no** minimal pair on the opcode field anywhere in the pooled corpus. That is a null with
power: it says the answer has to come from somewhere else.

`wsa1/dsp/disasm/struct_00_fd4093.dsm` is a WSA1R record the effect directory does not name,
catalogued as *"a shared/alternate body (candidates: a second unit's program, an alternate reverb
tank, or a variant of a named effect)"*. It is none of those.

> ★★★ **It is the kernel header. 34 of the KN5000 kernel's first 42 words are byte-identical and
> in order inside it.** Control: the same alignment against every other image in either product —
> best **2**, mean **0.4**. 75.7× the mean, and it beats the best unrelated image outright.

And every divergence between the two copies is a `lo12 = 0x820` word:

```
   KN  w15 op 0x605  <->  WSA w21 op 0x605        KN  w29 op 0x621  <->  WSA w34 op 0x621
   KN  w22 op 0x602  <->  WSA w28 op 0x602        KN  w31 op 0x605  <->  WSA w36 op 0x605
 ★ KN  w40 op 0x625  <->  WSA w45 op 0x605        ⛔ THE ONLY OPCODE THAT DIFFERS
```

**Four of the five keep their opcode across two products. The fifth does not, and the fifth is
§120's word** — reached from the machine by a completely unrelated route.

### The pair, and what it is a pair on
```
   KN  w40   0C4A1C0820   imm13 448    hi12 C4A  f31 5  bit6 1
   WSA w45   0C0A5E0820   imm13 1504   hi12 C0A  f31 5  bit6 0
   xor       0040420000   bits 17, 22, 30 — 17 and 22 are INSIDE the 13-bit immediate
                          ⇒ outside the payload: bit 30 = `hi12` BIT 6, and nothing else
```
`c_opcode` is `hi12 >> 1` and its low three bits are `f31`; both carry `f31 = 5`. So the "opcode
difference" **is** `hi12` bit 6, which the disassembler prints `?6`.

### The arm, and its positive control
`UPD6383_HI6C=<mode>`, an eleven-entry menu (`P ← 0 / acc / accb / mem[ptr] / imm / A / tempA /
tempB`, `acc ← 0`, `accb ← 0`, both), default off. **C3 passes**: mode 1 reproduces `PCLRIW=40`
*exactly* — LFO mean step **114.2560** and the hand-off cell `0x05` gone — so the arm fires where
its comment says. (§97 and §100 each spent a run on an arm that never reached its word.)

⚠ Whatever the sweep returns, the bit-6 *reading* is not decoded by any of this. What is decoded
is §122.

## 122. ★★★★★ THE C-FORMAT PAYLOAD IS AN I-RAM ADDRESS — kernel 47.0 % → 60.2 %
Tool: [`cfmt_addr.py`](../tools/cfmt_addr.py) and `kernel_homolog.py --reloc`.
Data: [`data/cfmt_addr_2026-09-14.txt`](data/cfmt_addr_2026-09-14.txt).

`k3-pointers.md` §8 item 3 is the standing objection and it was a fair one: *"`A = imm13 >> 5` is
measured on `(hi12 & 0xFFE) == 0xC40` only (57/57 in-corpus) and fails 9/11 outside … extending it
to `C00 / C04 / C0A / C16 / C42 / C4A / C64` is not [safe]."* `decoded()` obeyed it to the letter —
`is_c40` returned true and the other **11** C-format occurrences trapped, the `C-format 11` row of
the leverage table. The objection was that the extension was **unmeasured**. Two routes measure it,
and neither carries the `0xC40` rule outward.

**ROUTE 1 — the region test.** The resident microcode is kernel I-RAM 0…59 and epilogue 60…82. An
address must land inside the image that carries it; data has no reason to. **11 of 11 do.** `A` is
8 bits, so the uniform null is explicit: **p = 6.6 × 10⁻⁹**. Two of them are *self-references*
(epilogue `w76 → 76`, `w82 → 82`) and the two `0x632` words both land at **block start + 3** of
their own per-unit CALL block (42…49 → 45, 50…59 → 53).

**ROUTE 2 — the relocation test, which needs no null at all.** Two copies of one routine at
different offsets (§121). A field that is an **address** must shift by the number of words inserted
before it; one that is **data** must not.

```
   KN w   A    | WSA w  A    | offset  dA
   15     20   | 21     26   | +6      +6   ★ tracks the relocation EXACTLY
   22     24   | 28     30   | +6      +6   ★
   29     34   | 34     39   | +5      +5   ★
   31     37   | 36     42   | +5      +5   ★
   40     14   | 45     47   | +6      +33  ⛔ (§120's word, the outlier here too)

   A   [20,24,34,37,14] -> [26,30,39,42,47]   RELOCATES
   B   [18,18,23,17, 0] -> [18,18,23,17, 0]   ★ IDENTICAL across the two products
   f31 [ 5, 2, 1, 5, 5] -> [ 5, 2, 1, 5, 5]   ★ IDENTICAL
```

**4 of 4 comparable pairs, and the companion fields do not move.** That is a two-field
decomposition proved with no semantic assumption whatever: `A` is an address, `B` and `f31` are not.

### ★★★ And it resurrects K3's ζ reading, which `closure-pointer.md` item H buried
Item H: *"no field makes all five `one past an END-OF-BLOCK word' … K3's ζ reading does not become
5-of-5 under any alternative field."* It searched **one** product. Scored per copy:

| image | one past an END | null |
|---|---|---|
| KN5000 kernel | **4 of 5** (the exception is `w40 → 14`, which is itself an END) | 21.7 % |
| WSA1R `struct_00_fd4093` | ★★★ **5 of 5** | 27.1 % |

⇒ ζ was right. Item H's search was underpowered because **the five words are not five of the same
instruction** — exactly what `output-stage-decode.md` item K said from the opcodes, now with a
mechanism.

### What it buys
`decoded()` in both `dsp_disasm.py` and `upd6383d.cpp` now admits every C-format word, rendered
`ldreg r20,#iw14,0` — the destination, the I-RAM address, and `B` printed because it is real and
unexplained. Mirrors **3057/3057**; `dsp/verify.py` **BYTE-MATCH OK**.

| region | before | after |
|---|---:|---:|
| resident kernel I-RAM 0…82 | 47.0 % | ★ **60.2 %** |
| …header 0…59 | 56.7 % | **70.0 %** |
| …output stage 60…82 | 21.7 % | **34.8 %** |
| FRAME FLOOR kernel + reverb | 74.5 % | ★ **79.6 %** |
| all 38 body images | 80.4 % | 80.4 % (no such word in any body) |

⚠ **Encoding, not purpose.** `closure-pointer.md` item B has FALSIFIED this family as the
frame-closing D-RAM pointer load **on siting**, and `w40 → 14` is a backward reference to an
END-OF-BLOCK word that nothing explains. "The payload is an I-RAM address" and "we know what the
instruction does with it" are different claims and only the first is measured.

## 123. ★★★★★ THE WSA1R DISASSEMBLY WAS STALE: 40.1 % → 67.9 % FOR FREE
Regenerating `wsa1/dsp/disasm/` with `gen_wsa1_dsp_disasm.py` after §122 changed **63 files**, and
almost none of it is §122. The tree had not been regenerated since the ISA model advanced, so the
second product had been carrying a 2026-era decode while the KN5000 side closed the store gate, the
block terminator, the blindness lemma and the delay escape.

```
   48 images whose header line changed   3972 words
   strict decode BEFORE   1591   40.1 %
   strict decode AFTER    2697   67.9 %
   ⇒ +1106 words, +27.8 points, from running the generator
```

⇒ **every decode proved on the KN5000 transfers to the WSA1R corpus at zero cost**, because the
two products run the same ISA and one generator serves both trees. That is the concrete answer to
"is it worth expanding the analysis to the WSA1R programs": it already was, and the tree was
simply out of date.

⚠ The converse does **not** hold automatically. A *criterion* validated on KN5000 programs (the
hand-off cell, the VOLUME cell, the LFO increment) is not transferred to that product by this —
different kernel, possibly different per-unit geometry, and §111's boundary stands: one program's
null does not generalise.

## 124. ⛔⛔ THE BLOCK TERMINATOR'S `addr8` CLAUSE WAS OVER-FITTED TO ONE PRODUCT
Tool: [`xprod_homolog.py`](../tools/xprod_homolog.py).

§121's homolog was found by accident, so I asked the pooled corpus for the others. `xprod_homolog.py`
aligns all 100 images pairwise and scores each pair by its longest in-order byte-identical run,
with the **same-product pairs as the null** — two programs of one ISA share idioms, so "N words
match" means nothing on its own.

```
   SAME-product pairs   2550,  mean 12.2, median  7, 95th pct 54, max 110
   CROSS-product pairs  2400,  mean  8.4, median  5, 95th pct 27, max 97
   floor = 99th pct of the same-product null + 1 = 90

   97   KN prog05_phaser          <->  WSA eff09_phaser          (106 / 115 words)
   90   KN prog68_s_delay_phaser  <->  WSA eff42_s_delay_phaser  (110 / 116 words)
```

**The two instruments ship the same phaser.** And the last word of each pair is a 1↔1 replacement:

```
   KN  w109  060410E000   604.1.0E.000
   WSA w115  060414F000   604.1.4F.000      ← addr8, and nothing else
```

`is_terminator()` — §112's decode — reads `class4 == 1` + END + **`addr8 ∈ {0x0E, 0x0F}`**. Pooled:

| | terminator-shaped words | `addr8` | admitted |
|---|---:|---|---:|
| KN5000 | 40 | `0x0E` ×38, `0x0F` ×2 | **40** |
| SX-WSA1R | 53 | `0x4F` ×53 | ⛔ **0** |

The **shape** is confirmed by the second product, not weakened by it: **93 of 93** class-1 END
words are the last word of a **block** — the one non-image-final case is the kernel's `w49`, which
ends the unit-0 CALL block 42…49, i.e. exactly what a block terminator does. What the second
product refutes is the **value set**, and the `addr8 = unit index` reading with it: 53 WSA1R images
cannot all be unit 1. So the clause is gone, in Python and in `upd6383d`, and the rendering no
longer names a unit the word cannot tell us — `endblk #4F`, the operand printed, its meaning open.

⇒ **−53 undecoded words in the WSA1R tree.** Nothing changes in the KN5000: its 40 were already
admitted, which is precisely why one product could not have caught this.

### The session's two trees, in undecoded (`?word`) lines
```
   SX-WSA1R   3091  ->  1046  (§122 + regenerating a stale tree)  ->  993  (§124)
              4946 words:  37.5 %  ->  79.9 % decoded
   KN5000      653  ->   643  (§122)
              3057 words:  78.6 %  ->  79.0 % decoded
```

## 125. ★★★★★ THE BYTES RECOVER THE EFFECT CATALOGUE — and five of the twelve stubs exist
Tool: [`xprod_homolog.py --catalogue`](../tools/xprod_homolog.py).
Data: [`data/xprod_homolog_2026-09-14.txt`](data/xprod_homolog_2026-09-14.txt).

§124 used a conservative floor (99th percentile of the same-product null) and found two pairs. Drop
the floor to 35 and the ranking stops being a list of pairs and becomes **a dictionary between the
two instruments' effect catalogues**:

```
   97  prog05_phaser            eff09_phaser           88  prog39_parametric_eq   eff04_parametric_eq
   90  prog68_s_delay_phaser    eff42_s_delay_phaser   82  prog03_enhancer        eff07_enhancer
   78  prog98_peq_dist_delay    eff51_peq_dist_delay   78  prog66_s_delay_flanger eff40_s_delay_flanger
   77  prog70_auto_wah_s_delay  eff55_pedal_wah_delay  72  prog06_ensemble        eff20_ensemble
   …  exciter, mix_up, rotary, flanger, wah, multi_tap_delay, vibrato, overdrive, compressor …
```

**The scorer never sees a name.** So name agreement among the top pairs is a control the
instrument cannot fake, and it has a computable base rate:

> ★★★ **61 of 67 pairs scoring ≥ 35 share a name word, against a base rate of 11.0 % over all
> 2400 KN5000 × WSA1R pairs.**

### ★★★ And five of the twelve stubs have a real program in the other instrument
`bit11-family.md` item G: twelve **named** KN5000 effects ship a program byte-identical to NO
OPERATION — same image, coefficients, program record and parameter record. The menu entry without
the program.

| KN5000 stub | SX-WSA1R |
|---|---|
| SLOW ATTACKER | ★ `eff17_slow_attacker` |
| PITCH SHIFTER | ★ `eff54_pitch_shifter` |
| PEDAL WAH | ★ `eff12_pedal_wah` |
| HARS EFFECT | ★ `eff19_haas_effect` — the KN5000 menu's spelling of **HAAS** |
| PEDAL WAH+DELAY | ★ `eff55_pedal_wah_delay` |
| MODULATION DELAY, NOISE FLANGER, CEL, CELM, STRING, DS_D, OVER_D | — absent |

The pitch shifter is the one this project already leaned on (the class-4 minimal pair,
`class_twins.py`); four more were there and nobody had looked.

### ⚠ THE SCAFFOLD TEST, which changed one row of that table
`NO OPERATION` is **not an empty image** — the KN5000's is **49 words** of common I/O framework —
so "the other product ships a real program" has to mean words *beyond* the scaffold:

```
   WSA1R program            words   shared with KN NO-OP   own work
   eff54_pitch_shifter        108            7              101
   eff55_pedal_wah_delay      103            9               94
   eff12_pedal_wah             75            5               70
   eff19_haas_effect           35            6               29
 ⚠ eff17_slow_attacker         50           30             ★ 20
   NULL over the other 42 effects: min 18 (eff16_noise_generator), median 85, max 119
```

⇒ four are unambiguous. **SLOW ATTACKER is thin** — 20 own words, and 30 of its 50 are the
KN5000's no-op scaffold. ⚠⚠ **And an earlier pass said the opposite.**
`DECODE-by-correlation-2026-09-08.md` §10 clusters by idiom-sequence LCS ≥ 0.85 and reports
*"SLOW ATTACKER ≡ NO OPERATION (a stub, confirming the KN5000 stub-effect list on the WSA1R
too)"*. At byte level that is wrong — the two are 4 words apart, not identical — but "a real
program" overstates it in the other direction: 20 own words is at the bottom of the distribution,
above the corpus minimum for an effect nobody disputes. **State the number, not the label.**

### ⚠ And credit where it is due
§10 of that same pass had already established that *"every KN5000 ↔ WSA1R same-name pair
clusters — cross-product structural validation"*, and that **AUTO WAH ≡ PEDAL WAH**. What is new
here is the instrument, not the correspondence: idiom-sequence LCS is a similarity measure on
derived strings, this is **byte identity in program order with a computed null**, and it is what
makes the kernel homolog (§121) and the relocation test (§122) possible. The catalogue result is
a *confirmation at a stronger standard*, and it should be quoted that way.

`prog70_auto_wah_s_delay ↔ eff55_pedal_wah_delay` at **77** and `prog52_auto_wah ↔ eff12_pedal_wah`
at **51** put that identity on bytes too.

⇒ this is what the second product is worth, stated plainly: **a named, byte-anchored counterpart
for essentially every KN5000 effect**, an independent copy of the kernel header (§121), and five
programs the KN5000 lists but does not carry.

⚠ It does **not** make a KN5000-validated criterion valid there (§111), and it does not put a
WSA1R program in front of the emulator — the firmware never uploads effect bodies to IC30 in play
(bus-proven) and the wave ROMs are undumped, so RULE 12 forbids calling any such run a test.

## 126. THE POOLED QUEUE, which is not the KN5000's queue
`decode_leverage.py` ranks the KN5000's 658 undecoded occurrences. The same census on the WSA1R's
997 ranks differently, and pooled the head changes:

```
   decision       WSA sole   KN sole   pooled
   SRC 0x11            118        54      172   ★ the head, and it was second before
   class 1              87         ~       87   ★ NEW -- see below
   ACT 0x0B             14        62       76
   class 9              55         ~       55
   class 4              46         ~       46
   SRC 0x1C             43         ~       43   ★ NEW -- barely present in the KN5000
```

★ **`class 1` is the new entry and it is aimed at this project's worst region.** The KN5000 has
only **8** class-1 words that are neither a delay escape nor a terminator — and **all eight are in
the epilogue**, the output stage that sits at 34.8 %. The WSA1R has **150**, and they include
cross-product near-minimal pairs:

```
   WSA kernel    012.1.C4.05B        KN epilogue   012.1.8D.05B     ← addr8 alone
   WSA kernel    222.1.C4.1CD x10    KN epilogue   092.1.8D.15B
```

`r2-output.md` §1.1/§1.2 already **measured** what these are: class 1 **without** the escape bit is
the **register file**, `addr8` the index, 48 of 48 in the KN5000. 87 of the WSA1R's 150 have an
anchored ALU half, so the class test is the only thing refusing them.

⛔ **NOT promoted — and I checked the device before saying why, because the first reason I wrote
down was wrong.** I had it that the source side "still reads `mem[ptr]`". It does not:

```
   upd6383.cpp:4130   const bool regfile = (rdmode == 1) && !(hi & 0x800);
   upd6383.cpp:4143   L = (regfile && m_speculative && (m_specmask & 0x800000) && !xb_rd)
                              ? s32(util::sext(m_rf[rdsrc] & 0xffffff, 24)) : …
```

`regfile` is *exactly* "class 1 without the escape bit", and **SPEC bit 23 is set in the default
mask `0xb910e446a39b440f`** — the register-file read route is live today. What the device says
about it is the real obstacle, and it says it about itself:

> ⛔ **GUESSED: symmetry.** *"The store side is documented; the read side is not, and no note in
> this project states it. It is applied because the two halves of one addressing mode disagreeing
> would be the odd claim, not because anything proves it."*

So the words execute; the route they execute through is labelled a guess. Tier 1 cannot be built on
that. ⇒ the next pass's job is to **anchor the read side**, and there is one witness already:

> ★★ The corpus contains **exactly one** word addressing mode-1 index `0x06` — KN epilogue `w12`,
> i.e. **I-RAM 72**, in the output stage. `register-space.md` item A1 proves **by construction**,
> 49 of 49 algorithms, that register `0x06`/`0x86` is the **VOLUME**, written once per algorithm by
> the host's `EFF_VolumeLoop` and never by microcode. Under the register-file reading that word
> reads the volume, in the one place a volume multiply belongs. Under the rival it reads
> `D-RAM[m_dp]` and the host's volume never reaches the datapath from microcode at all.

That is one anchored instance, not a proof of the general route — but "GUESSED: symmetry"
understates it, and the comment should say *one anchored instance, generalised by symmetry*.

A symmetry check over the pooled corpus (read indices ⊆ written indices, mode-1 escape-0 words):
**KN 36 of 40 read occurrences take an index the same mode writes (90.0 %), WSA1R 95 of 124
(76.6 %)** — and the four KN exceptions are `06`, `85`, `8A`, `8F`, of which `0x06` is the one the
**host** writes. ⚠ Weak on its own: the KN figure is carried by the terminators' `0x0E` (×38), and
I have not computed a null for it. Recorded as a lead, not a result.

## 127. THE `hi12` BIT-6 MENU IS EXHAUSTED — U2, and the reading is abandoned
Pre-registration + full table: [`data/PREDICT_HI6C_2026-09-14.md`](data/PREDICT_HI6C_2026-09-14.md).

Eleven readings, `UPD6383_HI6C=1..11`, scored on §120's two consumers at the true default with the
per-program census.

```
    0  off (control)     LFO 15543.9286   hand-off LIVE 177684(-2869494..3486228/chg175660)
  ★ 1  P <- 0            LFO   114.2560   ⛔ ABSENT        ← reproduces PCLRIW=40 exactly
    2  P <- acc          the phase NEVER RISES             dead
  ★ 3  P <- accb         LFO   114.2560   ⛔ ABSENT
    4  P <- mem[ptr]     LFO   178.4357   dead
    5  P <- imm          LFO   128.2953   dead
    6  P <- payload A    LFO   128.2953   dead
    7  acc <- 0          LFO 15543.9286   LIVE, identical to the control
    8  accb <- 0         LFO 15543.9286   LIVE, identical to the control
    9  P <- tempA        LFO 10423.4350   LIVE (chg 90 448)  ← the only live-but-wrong row
 ★ 10  P <- tempB        LFO   114.2560   ⛔ ABSENT
 ★ 11  P <- 0 and acc<-0 LFO   114.2560   ⛔ ABSENT
```

**C0 reach passes** (19 005 336 firings, identical in every armed mode) and **C3 passes** — mode 1
is `PCLRIW=40` to the digit, so the arm reaches its word. And **nothing passes C1 and C2 together**:
every reading that gives the ROM's ramp starves the hand-off, and the one reading that keeps the
hand-off live misses the ramp by two orders of magnitude.

⇒ **outcome U2, as pre-registered.** `hi12` bit 6 does not act on the product register. The reading
is abandoned; the minimal pair stays a static fact and §122 is where the homolog actually paid.
⛔ Coverage unchanged.

**Two by-products.** Modes 3 and 10 are bit-identical to mode 1, so `accb` and `tempB` both hold
**zero** at every bit-6-set C-format word in the chorus. Modes 7 and 8 are bit-identical to the
control, so clearing either accumulator at those eight sites per frame moves nothing in the rise
census or in any of the 32 D-RAM cells — the blindness lemma at eight more sites, ⚠ against those
two instruments and not against the whole machine.

⇒ **§120's question stands, unchanged and still the best-posed one open**: *what does `w40` drive
`P` with?* What §121–§122 added is that `w40` is `ldreg r20,#iw14` — a register load whose payload
is an I-RAM address pointing **at** a block terminator rather than past one, the only one of ten
such words in two products that does so.

## 128. ★★★★★ MODE 1 DECODED — 143 WORDS, and the read half is no longer a guess
Tool: [`mode1_index.py`](../tools/mode1_index.py). Data:
[`data/mode1_index_2026-09-14.txt`](data/mode1_index_2026-09-14.txt).

§126 left this as the queue's second entry with an explicit next step: *"anchor the read side"*.
It also noted that `class4 & 7` is the addressing mode, so **class 1 and class 9 are one question**
— **247** undecoded words across the two products, not 25.

The store half was already documented (`r2-output.md` §1.1/§1.2: mode 1 without the escape bit is
the **register file**, `addr8` the index, 48 of 48). The read half was what `upd6383.cpp` applied
while calling it, about itself, *"⛔ GUESSED: symmetry … no note in this project states it"*.

### Four measurements, each with the control that can fail it

**1. The zero calibration.** The project's own rule (Part 231 §3, measured 9/9 vs 100/100 on a
class carrying both kinds of word): in this ROM a field is zero exactly when the instruction has no
use for it.

```
   KN5000    WITH the store bit      11 words   addr8 = 0 in  0
             WITHOUT the store bit   41 words   addr8 = 0 in  0
   SX-WSA1R  WITH the store bit      88 words   addr8 = 0 in  0
             WITHOUT the store bit  187 words   addr8 = 0 in  0
   ⇒ 327 of 327, including all 228 with NO STORE and therefore no documented use for the field.
   ⛔ CONTROL — mode 2, where addr8 IS a signed delta and 0 is legal: 2455 of 5769 ZERO (42.6 %).
```

**2. The constant control** — the one that killed the previous version of this argument (*"never
zero is not the same as carries information"*): 35 distinct values, varying inside a single image.

**3. ★★★ The run test.** An index takes consecutive values; a field nothing reads has no reason to.
One WSA1R image's 32 distinct indices contain a run of **26 consecutive values** — `p ≤ 7.6 × 10⁻²⁸`
for a uniform 8-bit field — and it is walked in a fixed order:

```
   C1 C3 C2 C4 | C5 C5 | C7 C6 C8 C9 | CA CB CC CD | CF CE D0 | D1 D1 D3 D2 D4 | D5 D5 D7 D6 D8
   `n, n+2, n+1, n+3' repeating on a STRIDE OF 4 — a Direct-Form-I biquad's four state cells
   per section (DECODE-by-correlation §7).
```

**4. ★ And the read USES it.** A read sits at **lag ≤ 1 from a write of the same index** in
**51 of 95** cases, against a shuffled null of **29.4 ± 2.1, max 37 over 2000 shuffles**. A read
that ignored `addr8` would have no reason to be placed next to the write of that index.

> ⚠⚠ **My first version of test 4 was VACUOUS and the null is what caught it.** "Does a write of
> this index exist somewhere in the image" is **invariant** under a multiset shuffle — null mean
> **95.0, sd 0.0**, observed **95**. A criterion that cannot fail is not a criterion, and I did not
> notice by being careful; I noticed because rule 15 makes me compute the null before reading the
> row.

### Promoted
`decoded()` admits `is_mode1(w) && _alu_half_anchored(w)` — the same footing as `is_dram` (§90) and
`is_terminator` (§112): the class test is what refuses these words and the word's own form explains
the class. The rendering names what the word actually reads and writes — `mac rC4`,
`mac.b rC4 ; rC4<-acc, acc=0` — because a decoded word that prints `(p)` for a register operand is
the delay escape's `ld ?` all over again. Two stale comments saying *"class 1 cannot reach here"*
are corrected in both mirrors.

```
   undecoded words   SX-WSA1R  993 -> 851   (-142)        KN5000  643 -> 642  (-1)
   resident kernel   60.2 % -> 61.4 %       frame floor   79.6 % -> 80.1 %
```

### ★ And a mirror invariant that was lying by omission
`upd6383d_diff.sh` compares the two ISA descriptions over the **KN5000's** 3057 words. Mode 1
decoded 143 words and **one** of them is a KN5000 word — so a green *"MIRRORS AGREE — 3057/3057"*
said nothing whatever about the other 142. Added `-p`: the WSA1R's listings carry their own slot
indices, so pooling costs one flag. **MIRRORS AGREE — 8003/8003.**

⇒ the remaining 104 mode-1 words are refused on their **ALU half**, not on the mode:
`SRC 00/ACT 00/f31 4` ×12, `SRC 11/ACT 12/f31 0` ×12, `ACT 0x1B` ×23 across five SRC codes.
Those are ordinary queue entries now.

## 129. ⛔⛔ THE SENTENCE HOLDING `ACT 0x0B` SHUT IS A DROPPED POPULATION QUALIFIER
Tool: [`act0b_scope.py`](../tools/act0b_scope.py). Data:
[`data/act0b_scope_2026-09-14.txt`](data/act0b_scope_2026-09-14.txt),
[`data/sd_act0b_2026-09-14.txt`](data/sd_act0b_2026-09-14.txt).

With mode 1 decoded (§128) the pooled queue re-ranks and **`ACT 0x0B` is the head — 191 words
whose only open axis it is** (62 KN5000 + 129 WSA1R), ahead of `SRC 0x11`'s 171. Unlike `SRC
0x11`, which the datapath handover shows is a genuine **dependency cycle** (*"capture campaigns
cannot settle accb while every reachable program feeds it the kernel-B constant"*), `ACT 0x0B` is
held shut by a sentence. Both mirrors quote it as the reason:

> *"ACT 0x0B ⇒ READ is DEGENERATE with H-ADB6: **every ACT-0x0B delay word carries `addr8`
> 0x20/0x30**. It adds nothing and it is not independent evidence. 0x0B stays OPEN."*

`dram-matching.md` item J states that measurement's population explicitly — **"203 slots over the
83 algorithms where `#cells == #consumers`"** — and round 5 says "over the in-scope aligned cells".
**The code comment dropped the qualifier and states a universal.** Measured over the full delay
corpus:

```
   ACT-0x0B delay-DRAM escapes, by addr8   (round 5 D, FORCED: bit 6 = direction, 0x60 = WRITE)
      KN5000     50 words   20 x35   30 x11   ★ 60 x4
      SX-WSA1R  115 words   20 x74   30 x39   ★ 60 x2

   the six the universal forbids:
      KN  kernel w46 / w54          080016000B   800.1.60.00B
      KN  prog06_ensemble w0 / w39  088016000B / 088016040B
      WSA eff20_ensemble  w0 / w51  088016000B / 088016040B      (byte-identical to the KN5000's)
```

**Two of them are in the KN5000's own algorithm images**, so the universal fails inside one
product — the second is confirmation here, not the source.

And the converse fails harder, which is the half "degenerate" actually needs: **463 WRITE-side
delay words carry EIGHT distinct ACTIONs, and `ACT 0x0B` is 1.3 % of them.** Neither field
determines the other.

**The control**, because a rule that cannot fail is not a rule: 4 of the 9 ACTIONs on this family
*are* one-sided (`0x1C` 37/0, `0x14` 0/16, `0x1A` 0/6, `0x0E` 0/1), so one-sidedness is the **norm**
here and carries little information alone. `ACT 0x0B` at 159/6 is not one of them.

⇒ **withdrawn: the universal, and the "adds nothing" inference built on it.** The scoped
measurement is untouched and is *not* re-run here. Corrected in both mirrors; `_act_anchored()`'s
behaviour is unchanged and mirrors stay 8003/8003.

### ⛔ And the code is still OPEN, on its own merits
Removing a bad reason is not a decode. `act0b-reverb.md` item D still leaves **three** survivors
(`none`, `mem<-bus`, `tA<-acc`), and re-running `sd_act0b.py` this session confirms LEDGER §291 —
reach test passes (13 812 firings), the control reproduces the ROM answer, the pointer map is
invariant over the six readings, and **all six give `1001:45074`**. SINGLE DELAY's lag-1001 product
is blind to this code, measurably.

⇒ what the queue head needs is a criterion that can *see* `ACT 0x0B`, and the corpus now says
where to look: **165 of 213 occurrences are delay escapes, 48 are plain**, and the six WRITE-side
words sit in ENSEMBLE and the resident kernel in *both* products — a small, byte-identical,
cross-product population that any candidate reading has to explain.

## 130. ⛔ A CRITERION FOR `ACT 0x0B` THAT LOOKED DECISIVE AND HAS NO POWER
Tool: [`act0b_hazard.py`](../tools/act0b_hazard.py). Data:
[`data/act0b_hazard_2026-09-14.txt`](data/act0b_hazard_2026-09-14.txt).

§129 removed the bad reason `ACT 0x0B` was closed; it did not decode it. The queue head needs a
criterion that can *see* the code, and this is the first one I built.

**The idea.** If `ACT 0x0B` writes tempA — one of `act0b-reverb.md` item D's three survivors —
then an ACT-0x0B word placed between a tempA **write** (`ACT 0x13`) and the **read** that consumes
it (`SRC 0x19`) would destroy a live value. Microcode must avoid that. So: does it ever happen?

```
   pooled                          0 of 213 inside a tempA live range   (base rate  9.0 %)
   the 26 images carrying BOTH     0 of  48                             (windows span 25.7 %)
   binomial P(0 | p=.257, n=48)  = 6.6e-7
   permutation null, 2000 reshuffles within each image: mean 11.8, sd 2.8, MIN 4  -- observed 0
```

Below the **minimum** of every one of 2000 shuffles. On that null the reading looks confirmed.

### ⛔⛔ And then the per-action control
The same test for every action, over the images that have a tempA window:

```
   ACT      n   inside  expected  ratio
   0x01    23      0       6.1     0.00   ★ EXCLUDED   -- no tempA relationship whatever
   0x03    38      0      10.1     0.00   ★ EXCLUDED   -- ditto
 ★ 0x0B    48      0      12.8     0.00   ★ EXCLUDED   -- the one under test
   0x13   101      0      27.0     0.00   ★ EXCLUDED   ⚠ BY CONSTRUCTION: it is the window's write
   0x1C    22      0       5.9     0.00   ★ EXCLUDED
   …
   0x12    96     91      25.6     3.55   ENRICHED
   0x14   102     99      27.2     3.64   ENRICHED
```

**Five of the fourteen actions with n ≥ 20 are equally excluded**, two of them with no tempA
relationship at all, and one excluded by the window definition itself. The exclusion describes what
a **filter's inner loop contains** — a narrow ACTION vocabulary, `0x12`/`0x14` enriched 3.6× — not
hazard avoidance around `0x0B`.

⇒ **the reading is neither supported nor refuted; the criterion has no power.** Coverage unchanged.

### ★ The method note, and it is the second one this session
The permutation null was **correct and insufficient**. It asked *"is 0 unusual for **these
positions**?"* and answered yes, decisively. The question that decides is *"is 0 unusual for **an
action of this kind**?"* — and it is not.

That is the same shape as §128's vacuous first test (where "a write of this index exists somewhere
in the image" could not move under a multiset shuffle). Twice in one session a row survived its
first null and died to its second. **A null that moves is not automatically a null that
discriminates — run the per-category control before believing a rate.**

## 131. ⛔ `class 3` EXISTS — the published class space is KN5000-local
Tool: [`class_space.py`](../tools/class_space.py). Data:
[`data/class_space_2026-09-14.txt`](data/class_space_2026-09-14.txt).

§128 admitted mode 1 because the word's own form explains its addressing. Asking which modes
remain shows one entry that is *only* blocked by the class test:

```
   undecoded non-C-format words by mode (class4 & 7), pooled
      mode 0   258        mode 3    14   ← class-sole 14, ALU half anchored 14
      mode 1   315        mode 4   106   ← blocked by TWO axes: the class AND its bit-4 store
      mode 2   703        mode 5     6
                          mode 6    99
```

Mode 3 should not exist. Two notes say so, and both are quoted as ISA facts:

> `r2-output.md`: *"**class 3 and class B do not exist.** All 31 words with `class4 & 7 == 3` are
> C-FORMAT words whose `class4` field is immediate data."*
> `isa-adjudication.md` item 2: *"The single apparent class-3 word in the entire 3057-word corpus
> is `C04.3.12.820`… Wide, the class space is exactly `{0,1,2,4,5,6,8,9,A,C,D}`."*

Both are **correct about the KN5000** — and both say "the corpus" meaning that one.

```
   class4 on NON-C-FORMAT words
      KN5000    0 1 2 . 4 5 6 8 9 A C D          ← class 3 absent, exactly as published
      SX-WSA1R  0 1 2 3 4 5 6 8 9 A C            ← ★ class 3, x14

      104.3.40.1CE  x6   WSA1R kernel               SRC 07  ACT 0E  f31 2
      104.3.40.1D5  x6   WSA1R kernel               SRC 07  ACT 15  f31 2
      182.3.10.419  x2   WSA1R eff54_pitch_shifter  SRC 10  ACT 19  f31 1
```

`hi12` is `0x104`/`0x182`, nowhere near the `0xC00` C-format mask, so `class4` is **not** immediate
data on them. **`class 3` exists**, and the published class space is a KN5000 fact, not an ISA one
— the third time today a claim scoped to one product was being quoted as the chip's behaviour
(§124's terminator `addr8`, §129's `ACT 0x0B` universal, and now this).

### ⛔ Not decoded, and precisely why
All 14 are blocked by the **class test alone** — SRC, ACT and f31 are anchored on every one — so
they would fall out the moment mode 3's *addressing* were documented, which is the condition §128
admitted mode 1 on. It is **not** documented. `class4 & 7 == 3` is `mode 2 | mode 1` bitwise, which
*suggests* pointer and register-file addressing together; a suggestion is not a reading. And
`class_twins.py`'s instrument finds **no class twin** at any of the three `(hi12, addr8, lo12)`
triples, so the pooled corpus offers no minimal pair either.

⇒ a precisely-bounded queue entry: **14 words, one axis, and the axis needs a reading rather than
a measurement.** Coverage unchanged.

## 132. FOUR CHEAP ATTACKS ON THE QUEUE, FOUR NULLS — written down so they are not walked again
Tool: [`queue_probes.py`](../tools/queue_probes.py). Data:
[`data/queue_probes_2026-09-14.txt`](data/queue_probes_2026-09-14.txt).

After §128 the queue is dominated by two entries a session cannot crack — `SRC 0x11` (171 sole) is
a documented **dependency cycle**, and `ACT 0x0B` (191 sole) now has **two** criteria measured
blind to it (§130 and LEDGER §291). Four cheaper lines were worth trying first. All four are empty.

**1. More class minimal pairs?** The classes-4/6 pointer reading rests on **n = 2** — one WSA1R
program spelling the C63 macro in class 2 where 99 instances spell it class 4 — and the project
declined to promote on that. §125's aligned homolog pairs could in principle raise n without
lowering the bar. **They do not: zero aligned class substitutions** across every cross-product pair
scoring ≥ 35. The reading stays at n = 2 and the non-promotion stands, now for a measured reason
rather than an unexamined one.

**2. The class guard is a list where it should be a decomposition.** `class4` bit 3 is the
cursor-fetch enable and bits 2:0 are the addressing mode, so the guard's admitted set `(2, 8, 0xA)`
is three corners of a 2×2:

```
                fetch = 0              fetch = 1
     mode 0     class 0  ⛔ REFUSED     class 8  ✔ admitted
     mode 2     class 2  ✔ admitted    class A  ✔ admitted
```

Class 0's every component is admitted elsewhere, and guards 5 and 6 of the same function already
speak the decomposition (`(cl & 7) != 2`). **But it is inert: 221 class-0 words pooled, 0 would be
decoded** — every one is refused on its SRC, ACT or `f31` anyway. A real asymmetry that costs
nothing.

**3. Does the second product bring unreviewed vocabulary?** Every pass in this project read the
KN5000, so a code occurring only in the WSA1R would never have been examined. **There are none** —
0 WSA1R-only SRC/ACT codes (and 2 KN5000-only singletons). The two products share one vocabulary,
so the WSA1R's remaining 851 words are blocked by the *same* codes, not by new ones. That is worth
knowing: it means the second product's value is in its *structure* (§121–§125), not in fresh codes.

**4. The documented sibling, at the field that matters.** `NEC-uPD77C25-rosetta-2026-09-09.md` took
the µPD7720/77C25 analogy seriously because the 6383's **source** codes match NEC's documented
register encoding (RAM `0x07`, ACCA/ACCB `0x10`/`0x11`, TA/TB `0x19`/`0x1A`). `f31` 3…7 is **257
undecoded words**, so: do the ALU-operation codes match too?

```
   uPD6383 f31   0 = acc <- P      1 = acc <- acc + P (ADD)   2 = acc unchanged (HOLD)
   uPD7725 ALU   0 = NOP           5 = ADD                    ...
```

**They do not.** The rosetta note's own caveat — *"analogy to a sibling FAMILY, not ISA identity;
numeric codes don't transfer"* — is now **measured at the field it matters for** rather than
assumed in either direction. The source-code match was real and is not evidence about the ALU
field. `f31` gets nothing from this route.

⇒ four nulls, no coverage change. Each one closes a line and says why; an empty line that is not
written down gets walked again.

## 133. ⛔ `ACT 0x0B` IS NOT THE WRITE SIDE OF `SRC 0x0B` — and the lead the control threw up is one word
Tool: [`act0b_symmetry.py`](../tools/act0b_symmetry.py). Data:
[`data/act0b_symmetry_2026-09-14.txt`](data/act0b_symmetry_2026-09-14.txt).

§132 closed four cheap lines. This is the one idea left that was worth a run on the queue head,
and it comes from a fact already anchored: `SRC 0x0B` is **the delay-read data register** (§215,
41 listings) — *"a delay READ has to land somewhere for the next word to use"*. The same numeric
code in the other field is the obvious candidate: **`ACT 0x0B` deposits what `SRC 0x0B` collects.**

```
   488 pooled SRC-0x0B reads.  Preceded at lag 1 by an ACT-0x0B word:  0
   nearest preceding ACT-0x0B: median lag 14
   ACT 0x0B ranks 8th of 16 actions on lag-1 adjacency
```

⇒ **REFUTED.** The reading predicts lag 1 and the ROM gives none.

### ★ The control, run *with* the test this time
§130's lesson was that a rate means nothing without the per-category control, so this one shipped
with it — and the control saw something the test could not: **`ACT 0x01` sits at lag 1 before a
SRC-0x0B read in 70 of 91 occurrences**, base rate 1.2 %, permutation null mean 4.5 / sd 2.0 /
max 12 over 2000 shuffles. About 33 σ.

### ⛔⛔ And it does not anchor `ACT 0x01` either — two reasons, both measured
**Rule 9, replication.** The 70 is per-occurrence. De-duplicated it is **one distinct word**,
`A00.0.00.041`, in 27 images — a 2.6× replication, the same shape `adjudication-round8` item E
caught.

**The confound the de-duplication exposes.** Of the **13** distinct ACT-0x01 words, **exactly one**
ever precedes a SRC-0x0B read — and it does so in 27 of its 27 images, while the other twelve never
do. ⇒ the adjacency is a property of **that word**, not of the ACTION field, so it anchors neither
`ACT 0x01` nor the `SRC 0x01` the same word carries.

What survives is a real, null-backed **two-word idiom** — `A00.0.00.041` followed by a delay-data
read, 27 images against a shuffled null of max 11. An adjacency is not a field reading, and it
decodes nothing.

### ⚠ A bug in my own throwaway, written down
The first de-duplication printed *"13 of 13 distinct words are followed by a SRC-0x0B read"*. False:
the count read a `defaultdict` inside the display loop and **created the twelve missing keys as it
printed them**. The table beside it already showed one word at 100 % and twelve at 0 %. A container
that materialises keys on read is a good way to turn a 1 into a 13, and the committed tool now
guards that line explicitly.

⇒ coverage unchanged.

## 134. TWO GUARDS §128 MADE ME WANT TO WIDEN — AND BOTH ARE RIGHT AS THEY STAND
Having decomposed the class field (§128: bit 3 = cursor fetch, bits 2:0 = addressing mode), two
guards in `alu_decoded()` look like leftovers from before that decomposition. Both survive the
check, and one nearly didn't.

### 1. The STORE guards, and the near-miss
```
   guard 5:  if (hi12 & HI_ST)        and (cl & 7) != 2:  refuse
   guard 6:  if lo_act == LO_ACT_ST_BUS and (cl & 7) != 2:  refuse
```
A store is admitted **only in mode 2** — yet the guard list already admits **class 8 = mode 0** for
*reading*, and modes 0 and 2 differ only in the pointer post-increment, so both address through the
pointer. The device stores that way too (`stdest = m_dp` for every mode but 1, the one §128
documented). Widening to `(cl & 7) not in (0, 2)` looked obviously right.

**Measured: it would admit 12 words — and they are all one distinct word, `800.8.0B.407`.**
`hi12 = 0x800` carries the **format escape**, and `r2-output.md` reads bit 11 as *"this word does
not address D-RAM through the data pointer"*. ⇒ the premise of my widening — "mode 0 addresses
through the pointer" — **fails for exactly the words it would admit.** Guard 6 refusing them is
right, and the corpus contains **no** non-escape mode-0 store at all, so the guard's condition is
never tested against a clean case.

> ★ The lesson is cheap and I nearly skipped it: **look at what the affected words ARE, not just
> how many.** A count of 12 said "small but real"; the words said "your premise is false here".
> This is rule 9's neighbour — de-duplicate, *and* inspect.

### 2. `is_dram()`'s exact class test — SAFE
`is_dram(w) = (hi12 & HI_ESC) and class4(w) == 1`, an **exact** class test where §128 says the mode
is `class4 & 7`. That is the same shape as §124's terminator `addr8` clause, which was over-fitted.
Here it is not:

```
   escape words by class4, pooled
      0 x102   1 x862 ✔   5 x5   8 x140   C x7   D x1
   escape words in mode 1 but not class 1 (i.e. class 9):  NONE
```

`class4 == 1` and `mode 1` coincide exactly over every escape word in both products, so the exact
test admits precisely the right set. **No change.**

⇒ two nulls, coverage unchanged — and one of them is a guard I would have widened wrongly.

## 135. ⛔ THE HLE ORACLE CANNOT SEE `ACT 0x0B` — the last named route, measured
`act0b-reverb.md` item H stopped for a stated reason: *"picking between them needs known
mathematics the reverb does not supply — the diffuser gains are known but there is NO REFERENCE
RESPONSE."* The HLE reference models are a reference response, and `lle-via-hle-oracle` is the
project's standing plan for exactly this. My own §132 handover named it as the remaining candidate.
It does not work here, and now that is measured.

**What is actually bit-exact.** `dsp/hle/effects.py` line 9 says it plainly of its own models:
*"models of the decoded ALGORITHM (graded), **not bit-exact to the chip**."* Only two oracles in
this project are anchored:

| oracle | anchored on | can it see `ACT 0x0B`? |
|---|---|---|
| the **biquad** (`lle_oracle.py`, *"proven bit-exact"*) | `prog39_parametric_eq` | ⛔ that program contains **zero** ACT-0x0B words |
| **SINGLE DELAY**'s lag-1001 ROM product (`sd_rerun.py`, self-test 13/13) | `prog09_single_delay` | ⛔ MEASURED blind — all six readings give `1001:45074` |

And in the EQ-bearing programs that *do* carry the code, it never sits in a filter section:

```
   ACT-0x0B words in peq / parametric images, by position and kind
      slot <= 3, plain          9        later, delay escape    15
      slot <= 3, delay escape   4        later, plain            3
```

— program **ambles** and **delay escapes**. The WSA1R's own parametric EQ has exactly one, at `w0`,
and it is a delay escape. An earlier cut of this test said "12 of 31 are within 4 words of a DF-I
latch word", which is proximity to a *marker*, not membership in a modelled *section*; the words
themselves say otherwise.

⇒ using the graded reverb model as the criterion would score the three readings against a **guess**
— RULE 13's cousin, a difference from an unvalidated model is not a signal — and the two anchored
oracles cannot see the code. **The HLE route is exhausted for `ACT 0x0B`**, and the handover is
corrected to say so rather than list it as a candidate.

⇒ coverage unchanged.

## 136. ★ THE QUEUE HEAD IS AN ESCAPE-WORD QUESTION — 86 % of it — and that reframes §107's null
Asking what the 191 sole-blocked `ACT 0x0B` words actually **are**, rather than how many:

```
   kind                    decoded   undecoded   sole-blocked
   delay ESCAPE                  0         165         ★ 165   (86 %)
   class A (ANCHORED)           18           0              0
   plain                         0          30             26
```

**165 of 191 are delay-DRAM escapes.** The 18 class-A words are already decoded — they are the
all-pass core's fourth multiplicand route — and every one of the reverb's "plain" ACT-0x0B words
turns out to be one of those, `102.A.00.64B`. So `capture-signature.md` item F's *"BLOCK A needs
ACT 0x0B"* is already satisfied; the reverb is **not** where the open words are.

### What that does to §107's null
`sd_act0b.py` found SINGLE DELAY's lag-1001 ROM product blind to all six readings, and LEDGER §291
recorded it as "a measured blindness". a09's three ACT-0x0B words are **all delay escapes** — so
that null was not a weak criterion applied to the wrong population. **It was the right population,
measured, with the reach test passing (13 812 firings) and the criterion demonstrably able to fail**
(the shipped `ACT 0x0D`/`0x0E` pair puts 45 074 at lag 500). The queue head is an **escape-word
question**, and the one anchored escape-word criterion this project has says the readings are
indistinguishable there.

### ⛔ And why that is still not a promotion
The obvious move is the blindness lemma (§113): if the ACTION on an escape word cannot be observed,
every surviving reading executes it identically and the word is executable. **§107 already refused
that generalisation and the refusal stands** — *"of the 62 words refused for this axis alone, 0 have
all three destinations dead; `mem[ptr]` is live at every one."* The six readings differ in machine
state; what SINGLE DELAY showed is that they do not differ in **that echo**. Site-blindness with
respect to one criterion is not word-blindness, and `decoded()` needs the latter.

### ★ The specification this leaves, which is sharper than "find a criterion"
`mem<-bus` is one of the three survivors and `mem[ptr]` is live at every ACT-0x0B site. So a
criterion with power must be **sensitive to a `mem[ptr]` write at an escape word** — which a09's
echo is not, presumably because its three sites write cells the echo path never reads. That is a
**searchable static condition**, not a modelling job:

> find an ACT-0x0B escape word whose pointer cell, at that moment in the frame, is read downstream
> by a consumer the ROM's own arithmetic pins.

`sd_rerun.py`'s descriptor machinery (`descriptors_of`, `ptr_offsets`, `mt_lags`) already computes
per-algorithm pointer/cell maps, and a second program already has a runner (`MT_ALGO`), so the
search has somewhere to stand. **That is the next concrete step on this code**, and it replaces the
handover's vaguer "a program whose arithmetic the ROM pins and that an ACT-0x0B word visibly
affects".

⇒ coverage unchanged.

## 137. ⛔ THE SEARCH §136 SPECIFIED IS CLOSED — negatively, and by measurement
§136 replaced "find a criterion for `ACT 0x0B`" with a **searchable static condition**: find an
ACT-0x0B **escape** word whose pointer cell is read downstream by a consumer the ROM's own
arithmetic pins. Both ends sit in one program, so the pointer **offset** is computable without the
absolute base — walk `off += s8(addr8)` on pointer-moving words; escapes never move it.

```
   ACT-0x0B escape sites, pooled                                165
   ...whose pointer cell IS read later in the same program      134  (81 %)
   ...where that reader sits INSIDE a DF-I section interior       0
```

The middle row is the one that makes the search look promising — §107's *"`mem[ptr]` is live at
every one"* is confirmed at 81 % — and the bottom row is the answer. **No ACT-0x0B escape's pointer
cell is consumed inside a biquad section anywhere in either product**, so the one bit-exact oracle
cannot be aimed at this code from the **memory** side either. §135 closed the **section** side.

### ★ And a proximity cut got it wrong first, in the same session that learned not to
A first pass scored "the reader is within 3 words of an `ACT 0x13`/`0x14` latch word" and returned
**seven** candidates, including the WSA1R's own parametric EQ. Every one was a program-**amble**
word — `w0` escape, `w1` reader — which is precisely the false positive §135 caught when it said
proximity to a *marker* is not membership in a modelled *section*. Replacing the heuristic with the
real span (from an `ACT 0x13` tempA write to the `SRC 0x19` read that consumes it, §130's window)
takes it to **0 of 165**.

> Twice in one session a proximity heuristic produced candidates a membership test dissolved. The
> rule to carry: **when a span exists, test membership in the span — never distance to its
> landmark.**

⇒ `ACT 0x0B` has now been attacked six ways this session — the withdrawn universal (§129), the
tempA hazard (§130), the symmetric code (§133), the HLE oracle from the section side (§135), the
population reframing (§136) and this memory-side search. It is not a criterion this project is
missing by accident; **the code's 165 open words are delay escapes whose ACTION no anchored
quantity in either product observes.** Coverage unchanged.

## 138. ⛔⛔ RETRACTED AND CORRECTED — I USED THE WRONG SPAN, THE THIRD TIME THIS SESSION
**What §138 first claimed, and it is wrong:** *"17 undecoded words sit inside a DF-I section
interior … 8 of them are the single instruction `804.8.16.1DA` … the first target the oracle has
ever had."* The handover was updated to lead with it. Both are corrected here.

**The error.** I scored "inside a DF-I section" using §130's **tempA live range** — the span from an
`ACT 0x13` write to the `SRC 0x19` read that consumes it. That is not a section. `lle_oracle.py`
defines one itself, and narrowly: **five consecutive coefficient-consuming class-A MACs plus the
class-8 makeup post** (`BIQUAD_SCHEDULE`). Looking at the words settles it in one glance —
`prog52_auto_wah` around the claimed target:

```
   w11  0102ABF1D4  mac.tb  (p),c+,(p)-65      w13  02042FE687  post.st tb,(p)-2
   w12  02042421CD  post    (p),(p)+66       ★ w14  08048161DA  ?word   (the claim)
   w15  00002FF647  ld.st   ta,(p)-1           w16  0000202687  ld.st   tb,(p)+2
```

`post` and `ld.st` words, not a five-MAC biquad. And `804.8.16.1DA` is **class 8**, while every word
the oracle models is **class A**. It was never a candidate.

**Corrected, with the oracle's own definition:**

```
   DF-I sections pooled                 97, spanning 498 words
   UNDECODED words inside one            7    (not 17)
      multi-axis                         6    kernel w30, prog15_rock_rotary w65 / w79
      SRC 0x11                           1    prog15_rock_rotary w18  (0212A01452)
   ACT 0x1A inside a section             0    (not 8)
```

Seven words, six of them multi-axis — so the oracle would have to close several things at once to
reach them. That is a much thinner lead than the one I reported, and `prog39_parametric_eq` still
has none, which remains the real reason the oracle has never had to speak.

### ★ The method rule, now in its strongest form
§135 and §137 both caught **proximity to a landmark** standing in for **membership in a span**, and
§137 wrote the rule down. §138 then broke it a third way: I used a span that was *real* but was
**not the model's span**. The rule as it should have been written:

> **Use the model's own definition of the region. Not a proxy for it, and not a landmark near it.**

Three variants of one error in a single session, each caught only by looking at the actual words.
⇒ coverage unchanged, and the handover's top section is corrected rather than left standing.

## 139. ONE WORD WHERE THE ORACLE COULD SPEAK TO `SRC 0x11` — bounded properly this time
§138's corrected census left seven undecoded words inside a real five-MAC run. Exactly one has
`SRC 0x11` as its **sole** open axis, and `SRC 0x11` is the code the handover calls
dependency-cycle-blocked. If the oracle could name that word's operand, it would anchor the code
**from the biquad instead of from accb captures** — sidestepping the cycle entirely.

```
   prog15_rock_rotary
     w16  0000A40415  ld     acc,c+,(p)+64   C-RAM[0x04] = "op0x62[0] (role output-level, INFERRED)"
     w17  0292A001D3  mac.ta (p),c+,(p)+0    C-RAM[0x05]
   ★ w18  0212A01452  ?word                  C-RAM[0x06]   SRC 0x11 · ACT 0x12 · f31 1 · class A
     w19  0202A011D5  mac    (p),c+,(p)+1    C-RAM[0x07]
     w20  0202A011D4  mac.tb (p),c+,(p)+1    C-RAM[0x08]
     w21  0202A001D5  mac    (p),c+,(p)+0    C-RAM[0x09]
```

If `w17…w21` are the canonical five and `w18` is index 1, the schedule
(`b1·x1, b0·x0, b2·x2, −a1·y1, −a2·y2`) names its operand **x0 — the current input sample**, which
would be a direct, testable statement about what `SRC 0x11` delivers.

### ⛔ And that is a LEAD, not an anchor — three things are unestablished
1. **The run is SIX class-A words, not five.** `w16` carries C-RAM `0x04`, annotated *output-level*,
   so it reads as a gain preceding the section — but the boundary is inferred, not derived, and the
   schedule's index for `w18` moves with it.
2. **The canonical cell order is assumed, not measured here.** `lle_oracle.py` says plainly that
   `section` is *"the six C-RAM cells **in the decoded order** [b1, b0, b2, −a1, −a2, makeup]"* — it
   does not derive that order. It is established for `prog39_parametric_eq`; nothing establishes it
   for the rotary.
3. **The oracle is validated on the EQ, not here.** Instantiating a validated model at an
   unvalidated site and reading off a prediction is the §135 problem again: a difference from an
   unvalidated instantiation is a difference from a **guess**, not from the chip.

⇒ what would make it an anchor, in order: establish that `w17…w21` is a DF-I biquad (the
idiom-sequence and coefficient-run instruments already grade sections — `DECODE-by-correlation` §7,
§15), then derive the cell order rather than assume it, then read off `w18`'s operand role. Only
then does the oracle say anything about `SRC 0x11`.

**Recorded as one word with its three preconditions, not as a target.** §138 was retracted for
exactly the failure of skipping that bounding step. Coverage unchanged.

## 140. §139's PRECONDITION 1 IS MET; PRECONDITION 2 IS HARDER THAN I STATED
Working §139's chain rather than handing it on.

### ★ Precondition 1 — MET. The section carries the full §7 signature.
`DECODE-by-correlation` §7 names a DF-I section by `ld.ta` (ACT `0x13`) at entry, `mac.tb`
(ACT `0x14`), and a class-8 `post` makeup. `prog15_rock_rotary` (algo 15):

```
   w16  ld     acc,c+,(p)+64   C-RAM 0x04   coef 373712     ← output-level gain, OUTSIDE
   w17  mac.ta (p),c+,(p)+0    C-RAM 0x05   coef 0                ACT 0x13  ← section entry
 ★ w18  ?word                  C-RAM 0x06   coef 1423801           SRC 0x11
   w19  mac    (p),c+,(p)+1    C-RAM 0x07   coef 15353414
   w20  mac.tb (p),c+,(p)+1    C-RAM 0x08   coef 7777061           ACT 0x14
   w21  mac    (p),c+,(p)+0    C-RAM 0x09   coef 8958128
   w23  post   acc,c                                               class 8  ← the makeup
```

All three markers present, five coefficient-fetching class-A MACs (`w17…w21`), and excluding `w16`
— which its own annotation calls an *output-level* gain — gives **exactly the oracle's six cells**
(`0x05…0x09` + the makeup). ⇒ §139's first precondition is satisfied, and `w18` is **index 1**,
whose canonical operand role is `x0`, the current input sample.

⚠ One caution kept: the coefficient-run instrument reports **7** run-5/6 sections against only **3**
`ld.ta` entries in the *modulation* family, where in the EQ family the two counts track (78 vs 80).
So the run-length signature alone does not identify a section here; it is the §7 markers that do,
and this section has them.

### ⛔ Precondition 2 — NOT met, and the reason is sharper than "the order is assumed"
I expected to derive the cell order by stability, the way `biquad_stability_probe.py` did for the
EQ (*"the captured coefficients are a STABLE, sensible peaking EQ (poles 0.710) ONLY with
SUBTRACTIVE feedback"*). **That route needs the per-coefficient SCALES, and they are solved for the
EQ only** (`N-SINGLE-DELAY-RECURRENCE-2026-09-12.md` §10 — the EQ's per-coefficient scales were solved statically, which is
precisely why that probe could run). The raw integers here forbid assuming a single divisor:

```
   w17  0          w18  1423801     w19  15353414   ← exceeds 2^23 = 8388608
   w20  7777061    w21  8958128     ← also exceeds 2^23
```

Two of the five exceed `2^23`, so a uniform `÷2^23` cannot be right for all of them, and without the
scales the poles are not computable — so **stability cannot decide the order.** `w17`'s coefficient
being exactly **0** is a further oddity worth carrying: the schedule's index 0 is the `load`
(`acc ← b1·x1`), and a zero there makes the section's opening multiply a no-op, which may mean the
word is there for its `ACT 0x13` tempA capture rather than its product.

⇒ the chain now reads: **precondition 1 met; precondition 2 requires the rotary's per-coefficient
scales, which is `N-SINGLE-DELAY-RECURRENCE-2026-09-12.md` §10's method applied to a second program** — a bounded, named piece of
work rather than an unknown. Precondition 3 (validating the oracle at this site) follows it.

⇒ coverage unchanged, and no claim is made about `SRC 0x11`.

## 141. ⛔ PRECONDITION 2 FAILS — and it fails for the SAME reason every other route did
§140 named the step: apply the EQ's scale-solving to algo 15. Done, and it does not transfer.

**First, a citation I got wrong and have corrected everywhere.** §140, the handover and the LEDGER
all cited **`biquad-eq.md`**. There is no such file. The method is
`N-SINGLE-DELAY-RECURRENCE-2026-09-12.md` §10, and all three are fixed.

**What the EQ's method actually is.** A **flatness test**: evaluate `|H(e^jω)|` over 200 log-spaced
frequencies from each band's own five cells, for each candidate scaling. The winner is not a fit but
an **identity** — under `b0, b2 ×4 and b1 ×2` the b-vector becomes exactly `[1, a1, a2]`, so
`H ≡ 1` and each band is a unity inverter, 0.00 dB spread against 46–109 dB for every rival.

**Why it cannot transfer.** That acceptance test *is* "the EQ's bands are unity inverters". A rotary
speaker has no reason to be flat, so the criterion evaporates. What generalises is the structure —
enumerate role assignments × per-coefficient power-of-two scales over the ROM's own cells, and keep
what is a legal filter. Stability is the only criterion left:

```
   role permutations × scale pairs tried      3000
   assignments giving a STABLE pole pair      1116
   distinct (a1-cell, a2-cell, scale, scale)   186     ← not 1
```

**186 survive.** Stability cannot pick the order.

### ⇒ And this is where all twenty attempts have converged
Precondition 2 needs *a response the ROM pins for this program*. That is word-for-word what
`act0b-reverb.md` item H was missing — *"picking between them needs known mathematics the reverb
does not supply … there is NO REFERENCE RESPONSE"*. The general shape, now visible after twenty
probes:

> **This project has exactly two places where the ROM pins an answer: the parametric EQ's response
> (via the firmware's own coefficient designer) and SINGLE DELAY's lag-1001 product. Every open code
> lives outside both, and every route tried this session ended by needing a third.**

`ACT 0x0B` (§130/§133/§135/§137), `SRC 0x11` via accb (the documented cycle) and now `SRC 0x11` via
the rotary's biquad all terminate there. It is one wall, not four.

⇒ the §139 chain is closed: **precondition 1 met, precondition 2 refuted.** Coverage unchanged.

## 142. ⛔ §141's "EXACTLY TWO ANCHORS" IS WRONG — there is a THIRD family, already extracted
§141 concluded: *"this project pins an answer in exactly two places — the parametric EQ's response
and SINGLE DELAY's lag-1001 product. Every open code lives outside both."* That is the tidiest thing
I wrote this session and it is **not true**, which I found by asking whether a third anchor could be
*created* rather than accepting the wall.

**There is a third family, and it was already recovered from the ROM.** `dsp/tools/host_side.py
laws` — "THE VALUE LAWS: what each evaluator computes" — walks the parameter dispatcher
(`DSP_PerParameterTranslator` at `0x03CAAE`, stubs at `0x03CB8E + OFFSETS_14745[op − 0x61]`) and
extracts, per opcode, the arithmetic the firmware applies to the user's value:

```
   op 0x61  CURVE_E[user]                       table lookup
   op 0x62  CURVE_D[user]                       table lookup  ★ 1.000 dB/step
   op 0x64  one 3-byte constant, shift+divide
   op 0x65  3-way piecewise, breakpoints 0x32 / 0x4B      (0xac44 = 44100)
   op 0x21, 0x66  lo + (hi − lo)·user/99         LINEAR INTERPOLATION
   op 0x67  base + user·44100/1000               MILLISECONDS → SAMPLES
   op 0x68  const·user/180                       DEGREES
```

**Each of those pins a coefficient's law, and therefore its scale** — which is exactly what
precondition 2 needs. The EQ anchor and the SINGLE DELAY anchor are two *instances* of this
mechanism (`op 0x67` is literally the delay anchor); they are not the only two things the ROM pins.

### ⇒ The gap is narrower and more specific than a wall
The cell ← opcode map also already exists, annotated across the disassembly and graded
(`op0x72[0] … PROVEN`, most others `INFERRED`) — but it is **partial**. For `prog15_rock_rotary`
only **6** cells carry one:

```
   C-RAM 0x00, 0x01 = op0x61     0x04 = op0x62     0x10, 0x14 = op0x66     0x1D = op0x74
   ⛔ 0x05 … 0x09 — the biquad section, and §139's whole chain — UNMAPPED
```

⇒ **precondition 2 restated, correctly and for the first time:** *map algo 15's C-RAM cells
`0x05…0x09` to their parameter opcodes.* Then the laws above pin their scales, and only then does
stability or a response pick the order. `host_side.py` already carries the machinery for that
half — `cmd_descbase`, `cmd_regmap`, `cmd_spaces` — so this is **host-side work with the tools
present**, not hardware and not a modelling job.

⚠ And the honest note on my own §141: writing "exactly two" felt like the session's conclusion, and
it was reached by generalising from four failed routes rather than by checking the ROM. The check
took one command. **A tidy summary of failures is not a measurement.**

## 143. ★★ THE ROM PINS WHAT `f31 = 4` COMPUTES — three sites, no emulator run
Tool: [`f31_oracle_pin.py`](../tools/f31_oracle_pin.py). Data:
[`data/f31_oracle_pin_2026-09-14.txt`](data/f31_oracle_pin_2026-09-14.txt).

§142 said the value-law family was the missing third anchor. Chasing it into algo 15 gave two
corrections and one result.

**Correction A — §139's precondition 2 was mis-stated.** I wrote that `lle_oracle.py` *"assumes"*
the cell order `[b1, b0, b2, −a1, −a2, makeup]`. It does not assume it:
`kn5000_dsp_namedcoeff.host_coeff_map()` records it as **the host writer's own layout** — *"op0x70
(biquad) writes 6 consecutive cells per band (b1, b0, b2, −a1, −a2, makeup)"*. Where `op0x70`
writes, **the order is derived.**

**Correction B — but not for the rotary.** Algo 15's T1 has **no `op0x70` entry at all**, and its
cells `0x05…0x0A` are written by **no parameter opcode** — they are fixed uploads with no evaluator
and therefore no law. §139's chain is closed by measurement, not by a wall.

**The bound that falls out.** The value-law family can only ever reach cells a parameter opcode
writes: **837 of 1546 coefficient fetches, ~54 %.** The rest are fixed uploads.

### ★★ And the result: where `op0x70` DOES write, both halves are available at once
Eleven algorithms carry an `op0x70` band. **Three contain an undecoded word, and it is the same
instruction in all three, at the same slot:**

```
   0018A001D5   class A · SRC 0x07 mem · ACT 0x15 ANCHORED · f31 = 4 — the ONLY open axis

   algo 75 PEQ+COMPRESSOR     w42  cell 0x11  band 1 slot 2 (b2)   acc_op = mac
   algo 96 PEQ+COMPR+DIST     w58  cell 0x15  band 1 slot 2 (b2)   acc_op = mac
   algo 97 PEQ+COMPR+OVERDR   w61  cell 0x18  band 1 slot 2 (b2)   acc_op = mac
```

The host writer says which cell is `b2`; the oracle's schedule says slot 2 is `mac`. Crossing them:

> ★★ **`f31 = 4` computes `acc += P` at these three sites — the same algebra as `f31 = 1` (ADD).**

That is the **first positive statement about any of `f31` 3…7** in this project, and it comes from
the ROM's own two halves with no emulator run.

### ⛔ Not promoted, and the limits are the interesting part
* **One distinct instruction** (rule 9). Three *programs* beats three occurrences in one, but it is
  a single word shape.
* **The oracle is a FLOAT model** — `BiquadOracle.c = [float(v) …]`. It pins the **algebra**,
  `acc += product`, and cannot separate ADD from ADD-with-a-different-shift, rounding or
  saturation — which is exactly the fixed-point detail `f31` might encode. *"Same algebra as
  `f31 = 1`"* is strictly weaker than *"`f31 4` is `f31 1`"*.
* It says nothing about `f31` 3, 5, 6 or 7.

⇒ coverage unchanged; `alu_decoded()` untouched. The next step is now sharp and is a **device**
question rather than a corpus one: run the machine with `f31 = 4` executed as ADD and check the
three sites against the oracle's predicted `acc_after` — the float model pins the algebra, the
machine supplies the fixed-point detail it cannot.

## 144. ⚠ §143 WEAKENED BY ITS OWN CONTROL — "the ROM pins" becomes "the corpus favours, 22 of 25"
§143 claimed the ROM *pins* `f31 = 4` to `acc += P`, by crossing the host writer's 6-cell layout
with `lle_oracle.py`'s `BIQUAD_SCHEDULE`. I did not run the control that decides whether the
schedule is a **law** or a **template**. It is a template.

**The control.** At every `op0x70` band slot, do the **decoded** words' `f31` agree with the
schedule (slot 0 → LOAD, slots 1–4 → ADD)?

```
   agree 113, DISAGREE 12  —  90 %, not 100 %

   slot  schedule   word carries   n
     0   load       load          19      0   load   mac    6   ← the ROM deviates
     1   mac        mac           25      1   mac    hold   3   ← and here
     2   mac        mac           22      2   mac    f31=4  3   ← ★ my three sites
     3   mac        mac           22      3   mac    hold   3   ← and here
     4   mac        mac           25
```

**The ROM varies the accumulator op inside a band** — six `mac`s where the schedule says `load`,
and six `hold`s at slots 1 and 3. So the schedule does **not force** slot 2 to be `mac`, and
§143's "pins" is too strong.

### What actually survives, and it is still worth having
> At **slot 2**, **22 of 25** words in the whole corpus carry `mac` (`f31 = 1`) — and the **only
> three exceptions anywhere are the `f31 = 4` word itself.**

That is the *corpus* speaking rather than the model, and it is a genuinely better argument than the
one §143 made: not "the schedule says mac so f31 4 is mac", but "every other word at this slot is
mac, and the three that are not are all the same unknown". It makes `f31 4 ≈ ADD` the **favoured**
reading at these sites; it does not derive it.

⇒ §143's status is corrected from **pinned** to **favoured, 22 of 25 at the slot, against a
schedule that deviates 12 times in 125**. Everything else in §143 stands — the two corrections
(the order is the host writer's, algo 15 has no `op0x70`) and the ~54 % bound.

### ★ And the tension with the shipped alias is the real prize
`data/PREDICT_F31_4_2026-09-13.md` records the device's default: `m_bx_f4 = 0` keeps the alias
`op = f31 & 3`, so **`4 → LOAD`**. The favoured reading here is **ADD**. The same file already
provides the arms and masks — `b912e446a39b440f` = ADD, `b913…` = HOLD, control `b910…` — and
names TYPES 13/14/18. That pre-registration has **no RESULT section**: the run was never made.

⇒ the next step is not new work, it is **an experiment already designed and never run**, and §143
has now supplied it with a prediction it did not have: *ADD should leave the anchored cells healthy
where the shipped LOAD alias does not.*

⇒ coverage unchanged.

## 145. ★★ THE `f31 = 4` EXPERIMENT, RUN AT LAST — and a liveness check that reweights its own result
Pre-registration + full data: [`data/PREDICT_F31_4_2026-09-13.md`](data/PREDICT_F31_4_2026-09-13.md),
[`data/f31_4_run_2026-09-14.txt`](data/f31_4_run_2026-09-14.txt).

⛔⛔ **§144 SAID THIS RUN HAD NEVER BEEN MADE. IT HAD.** `f31_4_2026-09-13.txt` records it on
TYPE 13 / 14 / 18 with **outcome C** — *"several differ and none is singled out"*. I read a missing
`## RESULT` heading as a missing run, and asserted it twice. This is a **SECOND** run, on TYPE
33/34/35 — different programs (§111's boundary), each fingerprinted (§193) — and its value is that
it **explains** outcome C: the 2026-09-13 pass scored the ANCHORED CELLS, and §145 measures those as
identical to the digit under every arm. They could not separate the readings. The §160 register file
can.

```
   TYPE 33 prog75_peq_compressor ✅   CONTROL 72  0E=7B3F32 C3=--     C8=FFFFFF D0=62FFEE
                                      ADD     73  0E=7FFFFF C3=1259EA C8=C46363 D0=7FFFFF
                                      HOLD    73  0E=7FFFFF C3=1259EA C8=FFFFFF D0=7FFFFF
   TYPE 34 prog96_peq_compr_dist ✅   CONTROL 70  … C3=--  D0=03530A  │ ADD/HOLD  C3=1259EA D0=7FFFFF
   TYPE 35 prog97_peq_compr_overdr ✅ CONTROL 68  … C3=--  D0=7FFFFF  │ ADD/HOLD  C3=1259EA D0=7FFFFF
   reach: 1 387 425 / 1 429 877 / 1 470 848 — §108 measured 0 in the chorus
```

* **N0 reach — PASS.** * **N4, the pre-registered null — REFUTED**: the arms are not bit-identical,
  so the accumulator at this word is observed and the blindness lemma does not apply.
* **N1 / N2 — REFUTED.** I predicted ADD would be the healthy arm; it is not.

### ⛔ Correcting myself twice, in the same experiment
1. After TYPE 33 alone I reported *"the shipped alias is the only arm leaving `0E` and `D0`
   unrailed"*. **On TYPE 35 the control already rails `D0`** — so railing is not the discriminator,
   and I had quoted a one-program observation as general. §111's boundary, walked into by writing
   up one program before running the other two.
2. Then I reported the 3-of-3 discriminator as *"ADD and HOLD create register `C3`, the alias never
   does"* — and did not ask whether anything **reads** `C3`.

### ★ The liveness check, which reweights the whole result
Which of these registers does the microcode of those three programs actually touch?

```
   prog75 / prog96 / prog97 — mode-1 words touching C3 / C8 / 0E / D0:   only 0x0E, and it is a READ
   pooled corpus: C3 (2 w / 2 r), C8 (2 r), D0 (1 w / 2 r) — all elsewhere, none in these programs
```

⇒ **`C3`, `C8` and `D0` are never read in the programs under test.** The 3-of-3 difference is a
census artefact — real in the register file, **functionally dead** in these programs.
⇒ **`0x0E` is read, by all three programs.** And it is the one cell where the shipped alias
(`7B3F32`) and the two rivals (`7FFFFF`, the rail) differ on a value the microcode consumes — but
only in `prog75`; in `prog96`/`prog97` it is zero under every arm and says nothing.

**So the evidence against ADD and HOLD is one program in which a register the program reads gets
railed.** That is thin, and it is what the experiment actually supports — not the 3-of-3 headline I
would have quoted an hour ago.

⇒ `f31 = 4` remains **open**: observable and separable (that is new), with the shipped alias
favoured by one live cell in one program, and §144's static argument (22 of 25 at band slot 2 carry
`mac`) still pointing the other way. Coverage unchanged.

## 146. ★ RULE 4's GATE ON `f31` 3/6/7 IS PASSED — and the census that shows it cannot fail
The nine `f31 = 4` logs carry a census I had not read. `upd6383.cpp` records a **speculative**
hypothesis about `hi12` bit 5 — *"(bit5, f31) acting as a 4-bit selector whose codes 3/6/7 are
reachable only with bit 5 set … the first FALSIFIABLE hypothesis this bit has ever had"* — and a
counter built for one stated purpose: *"⛔ THIS CHANGES NOTHING. It COUNTS, so the next pass knows
whether those 53 sites are even reachable in the resident frame — which rule 4 requires before
anyone implements a reading for them."*

```
   prog75   bit5=0  f31 3:0        6:0        7:0     │ bit5=1  3:5 687 512  6:1 927 653  7:2 020 787
   prog96   bit5=0  f31 3:0        6:0        7:0     │ bit5=1  3:5 772 416  6:1 938 492  7:2 031 626
   prog97   bit5=0  f31 3:0        6:0        7:0     │ bit5=1  3:4 892 718  6:1 948 735  7:3 003 509
```

**⇒ Rule 4's precondition is met: the sites are reachable, 5–6 M firings per program, 3 of 3.**
Implementing a reading for `f31` 3/6/7 is no longer blocked on "are they even executed".

### ⚠ And the thing I nearly reported instead
My first reading of that table was *"the machine confirms the bit-5 hypothesis — zero with bit 5
clear, millions with it set."* **It confirms nothing.** The exclusivity is a **static** fact:

```
   pooled corpus, (f31, bit5) word counts
      f31 3   bit5=0: 0     bit5=1: 73
      f31 6   bit5=0: 0     bit5=1:  3
      f31 7   bit5=0: 0     bit5=1: 44
```

If **no word** with `f31 ∈ {3,6,7}` carries bit 5 clear, then no **execution** can either. The
runtime zeros are *implied by the disassembly*, so that census **cannot disconfirm the hypothesis**
— a criterion that cannot fail, the third time this session I have caught one, and this time in a
table I was about to quote as a result.

**What the runtime genuinely adds is reachability, and only that** — which is exactly what the
device comment said it was for. The hypothesis that `(bit 5, f31)` is a 4-bit operation field
remains **speculative and untested**; testing it needs an arm that makes the two halves behave
differently, not a counter.

### ★ And the population is bigger than the comment says
`upd6383.cpp` says **53 of 53**, counted on the KN5000. Pooled with the WSA1R it is **120 words**
(73 + 3 + 44). Anyone implementing a reading should size it against 120.

⇒ coverage unchanged.

## 147. ★ §231's CENSUS IS A *MACHINE* BLINDNESS INSTRUMENT, and it sees what the static one misses
Reading §231's COLLAPSED-OP census in the same logs — *"what `op = f31 & 3` DISCARDS at the four
`f31 in {3,6,7}` sites"* — splits those sites in two:

```
   iw63  f31=3  DISCARDED PRODUCT 0..0 nz 0   L 0..0 nz 0   acc-in 0..0    n = 1 532 730 + 177 023
   iw70  f31=3  DISCARDED PRODUCT 0..0 nz 0   L 0..0 nz 0   acc-in 0..0    "
   iw75  f31=7  DISCARDED PRODUCT 0..0 nz 0   L 0..0 nz 0   acc-in 0..0    "
   iw78  f31=6  DISCARDED PRODUCT 0..0 nz 0   L 0..0 nz 0   acc-in 0..0    "
   ── against the BODY sites, which discard plenty ──
   iw102 f31=3  non-zero 3410      iw119 f31=3  max 4.46e11, non-zero 26 581
   iw150 f31=3  non-zero 2646      iw166 f31=3  non-zero 829
                                                   CONTROL: PASS 3 of 3
```

**At the four resident sites the product is identically 0 *and the accumulator on entry is
identically 0*.** With `P = 0` and `acc = 0`, `acc ← P`, `acc += P` and `acc unchanged` all leave
`acc = 0`: **every reading of `f31` executes identically there**, measured over 1.7 M executions
with a control that passes 3 of 3.

### ★ The two blindness instruments disagree, and the machine one is the stronger evidence
`acc_blind.blind_sites()` — §113's **static** census — flags **none** of these four. §231's census
is a **machine** measurement of the same lemma and it sees all four. That is worth recording as a
method fact: the static census reasons about what *could* be observed from the word stream; §231
measures what the quantity *actually is*.

### ⛔ And what it is worth, stated without inflation
Of the four, only **`iw75`** (`082E80F000`) has `f31` as its **sole** open axis. The others carry
more:

```
   iw63  class 9 · ACT 0x03 · f31 3        iw70  class 1 · SRC 0x03 · ACT 0x07 store · f31 3
   iw78  class D · SRC 0x0A · two stores · f31 6
```

so resolving `f31` leaves them undecoded anyway. ⇒ **one site** becomes blindness-clear, in the
output stage (23 words, 8 tier-1 today).

⚠ And `082E80F000` occurs **7 times** in the pooled corpus. The inertness was measured at the
resident site; the other six are elsewhere and unmeasured. So this is **per-SITE** blindness —
**tier-1b, not tier-1** — exactly the distinction §113 drew and the reason `decoded()` must not
depend on position.

⇒ coverage unchanged in `decoded()`; **+1 machine-measured tier-1b site**, and a method note worth
more than the site: **§231 is an existing, unread blindness instrument**, and it is pointed at the
axis (`f31`) that the static one cannot resolve.

## 148. ★★ `f31 = 3` IS SEPARABLE AND REPRODUCIBLE — the arm §146 asked for, built and run
Pre-registration + data: [`data/PREDICT_F31_367_2026-09-14.md`](data/PREDICT_F31_367_2026-09-14.md),
[`data/f31_367_run_2026-09-14.txt`](data/f31_367_run_2026-09-14.txt).

§146 said the bit-5 hypothesis *"needs an arm that makes the two halves behave differently, not a
counter"*. Built (`UPD6383_BX_F3` / `_F6` / `_F7`, counted unconditionally, default off) and run on
the two programs §231 pointed at.

* **R0 reach — PASS**, 5.69 M / 5.77 M firings.
* **R1 positive control — PASS, and it could have failed.** `BX_F3=3` (HOLD) differs from the
  control in **nothing but its own banner**: 406 device report lines identical. ⇒ the shipped
  `op = f31 & 3` **is** HOLD for code 3, exactly as the device claims.
* **R2 — PASS, with identical magnitude in two programs:**

```
   §167 tempB change count     TYPE 33    TYPE 34    Δ vs control
     control / HOLD             39 559    498 837     --
     LOAD                       39 510    498 788     −49   in BOTH
     ADD                        39 485    498 763     −74   in BOTH
```

Not same-signed — **the same deltas**, across programs whose totals differ by an order of magnitude.
* **R3, the pre-registered null — REFUTED.** `f31 = 3` is not blind at these sites.

### ⛔ What it does not settle, which is the decision itself
§160's register file is **identical across all four arms in both programs**; so are the D-RAM
anchored cells. The only discriminators are **activity counts**, and §20 measured that liveness
**rewards contamination** — "more transitions" is not "more correct".

⇒ `f31 = 3` moves from **no evidence of any kind** to **separable, reproducible, and with one
reading proven identical to the shipped model**. It needs a criterion that **ranks** the three
readings, not one that merely distinguishes them. Coverage unchanged.

## 149. ⛔ THE RANKING CRITERION §148 ASKED FOR DOES NOT EXIST — measured per axis
§148 left `f31 = 3` separable but unranked, and asked for a criterion that **ranks** LOAD / ADD /
HOLD rather than merely distinguishing them. Every anchored criterion this project has was checked
against it:

```
   prog09_single_delay   (the lag-1001 ROM product)      f31=3 words: 0
   prog39_parametric_eq  (the bit-exact biquad oracle)   f31=3 words: 0
   prog16_room_reverb_1                                  f31=3 words: 0
```

**Zero, in all three.** The code does not occur in a single program where the ROM pins an answer —
so the existing anchors are blind to this axis **by construction**, not by weakness.

Where it does occur is the **dynamics and distortion** families: enhancer, compressor, exciter,
auto-wah, distortion, overdrive, fuzz, and the `peq_compr_*` combos. §135 already measured that the
HLE's models for those are *graded, not bit-exact*.

### The one thing that looked like a way in, and why it is not
The cell ← opcode map carries a **PROVEN** entry in exactly this family — `op0x72[0] (role
gain-computer, PROVEN)` — and §142 established that the firmware's evaluators give a **value law**
per opcode. So: does `op 0x72` pin anything usable?

```
   op 0x72  evaluator 0x039ABD, 203 lines, 15 ROM data references — a TABLE-DRIVEN law
   writes   prog36_compressor  C-RAM 0x04, 0x0D        prog75_peq_compressor  C-RAM 0x0A, 0x19
```

It pins a **coefficient**, not a **response**. Knowing what value the gain computer's coefficient
takes does not rank three accumulator operations — for that you need a predicted output to compare
against, which is the reference-response problem again, one family further along.

⇒ `f31 = 3` stands where §148 left it: **separable, reproducible, one reading proven identical to
the shipped model, and unranked.** The ranking criterion has to be *built* on a dynamics program,
and that is the same modelling job §135 named for the reverbs. Coverage unchanged.

## 150. ⛔⛔ "THE RUN WAS NEVER MADE" — IT WAS, AND I SAID OTHERWISE TWICE
`PREDICT_F31_4_2026-09-13.md` carries no `## RESULT` heading. I read that as *"the run had never
been made"*, wrote it into §144 and §145, and reported it twice as the reason the experiment was
worth doing.

**It had been made.** `data/f31_4_2026-09-13.txt`, committed the day before, records it:

```
   TYPE  program          f31=4 n    §176      anchored cells (05 / 06 / LFO)
   13    compressor       1 196 405  DIFFER(3)  ALL THREE IDENTICAL
   14    no_operation       485 513  DIFFER(3)  ALL THREE IDENTICAL
   18    auto_wah           536 818  DIFFER(3)  ALL THREE IDENTICAL
   M1 HIT · M2 MISS · M3 MISS  ⇒  M4 outcome C
```

A missing heading is not a missing run. The result was in the data file and in the notes, and I
checked neither before asserting.

### ★ What my run actually contributed, stated correctly
Not "the first execution of a designed experiment" — a **second** run, and two things the first
did not have:

1. **Three different programs** (TYPE 33/34/35 against 13/14/18), which §111's boundary requires
   before any of this generalises.
2. ★ **An explanation of outcome C.** The 2026-09-13 pass scored the **anchored cells** and found
   them *"ALL THREE IDENTICAL"*, concluding the criteria cannot separate the readings. §145 measures
   exactly why: those cells are identical **to the digit** under every arm, in every program. They
   are blind to this code. **The §160 register file is not** — it separates all three, and §145's
   liveness check then shows which parts of that separation are functionally dead.

So outcome C was a property of the criteria, not of the code — and that is worth more than the
"first run" framing I gave it.

⇒ ten corrections this session, and this is the one I should have caught earliest: the file I was
reading had a sibling data file with the answer in it.

## 151. ★★ A PRE-REGISTRATION THAT REALLY WAS NEVER RUN — and its answer was in today's logs
§150 taught me to check the data file before saying a run never happened. Applying that
constructively: of the pre-registrations with no `## RESULT` heading, **three** have neither a data
file nor any note referencing them. Two are old self-challenges. The third, **§179**, asks a live
question and its falsifiers are answerable from logs I already had.

**The question.** Two independently-argued anchors for the same pointer disagree —
`DRAM_UNIT_BASE = 0x05` (marked **FORCED**, from closure arithmetic) against an origin of
`0x70`/`0x50` (**MEASURED three ways**). §176 censused `0x00..0x1F`, one eighth of D-RAM, and
concluded *"the pointer is 2 short"*. §179 asks: **was that measured in an empty corner?**

**The answer, from the §148 logs — the current build's §176 already covers all 256 cells:**

```
   NON-ZERO 126 of 256 (22 below 0x20)      MOVING 24, only 7 below 0x20
   the movers above 0x20:  50 51 52 53 55 56 57 58 · 87 88 89 8A 8B 8D 94 · D1 D2
```

* **F1 — the window was WRONG.** 17 % of the live data is below `0x20`, and the movers concentrate
  at `0x50..0x58` and `0x85..0x94` — exactly the branch §179 named. **Any conclusion measured inside
  `0x00..0x1F` has to be re-derived where the data actually is**, and that includes §176's
  off-by-two.
* **F2 — half.** Unit 1's `0x85` footprint is live (`87 88 89 8A 8B 8D` all move); the `0xF0..0xFF`
  frame-end is **not** (9 non-zero, none moving). One half of the FORCED closure argument has an
  observable consequence; the other half does not.
* **F3 — the known-answer control does not reproduce**, expectedly: it was written against a build
  many changes ago. ⚠ **So this is not a clean before/after.** F1 stands alone — it is a measurement
  of the current build and needs no comparison.

⇒ this is the opposite error from §150: there I called a run missing that had happened; here a
genuinely unrun experiment had its answer sitting in a log from a different experiment. **Check the
data before concluding either way.** Coverage unchanged.

## 152. ★★★ THE COMPRESSOR'S SCALES ARE WRITTEN DOWN IN THE ROM — §140's blocker dissolves
Tool: [`op72_constants.py`](../tools/op72_constants.py). Data:
[`data/op72_constants_2026-09-14.txt`](data/op72_constants_2026-09-14.txt).

§140 stopped on one sentence: *"deriving the cell order by stability needs the per-coefficient
SCALES, and they are solved for the EQ only."* The EQ's came from a **flatness identity** — under
one assignment its b-vector becomes exactly `[1, a1, a2]` — and no other family has an analogue.
§149 then measured that no anchored criterion can rank `f31 = 3` because the code lives in the
dynamics families, and the handover's top item became *"build a bit-exact reference for one
dynamics program"*, with the compressor named because `op0x72[0]` is the family's only **PROVEN**
cell←opcode entry.

**Step one is far cheaper than I assumed.** `host_side.py laws` locates op 0x72's evaluator at
`0x039ABD` with *"15 ROM data references, 0x012DB3..0x012E03"* and describes it as table-driven.
Those 80 bytes are **not a table** — they are **IEEE-754 constants**, little-endian:

```
   DOUBLES   −0.0697      10      0.9999        ← and the triple appears TWICE, byte-identical
   FLOATS     2   2   1   3
              2²¹  2²³  2²²  2²¹                ← FIVE SCALED WRITES, THREE DISTINCT SCALES (⛔ §155 corrects §152's "four distinct")
```

* The doubles repeating byte-for-byte is what the cell map already said: `op0x72` writes **exactly
  two cells** in every carrier (`prog36` `0x04`/`0x0D`, `prog75` `0x0A`/`0x19`) — one law, two
  operands.
* `10` is the dB base; `0.9999` is a near-unity pole, the shape of a release smoother; `−0.0697` is
  the per-step exponent. A gain computer, in floating point.
* ★ And **`2²¹ / 2²³ / 2²² / 2²¹`** — the DSP's fixed-point scale and its neighbours, **explicit**.

⇒ **§140's blocker does not apply to this family.** The per-coefficient scales are not something to
solve by identity or by stability; for the compressor they are **written down**. That is the first
concrete piece of the artefact the handover asks for, and it is a ROM fact rather than a model.

### ⛔ What this is not
**The constants are not the law.** How they combine is in the evaluator's 203 lines of TLCS-900,
which this pass does not read, so **no formula is claimed**. And a coefficient law still pins a
*coefficient*, not a *response* — §149's point stands. What has changed is that the piece §140
called unavailable turns out to be sitting in the ROM, which moves the dynamics-reference job from
"derive the scales somehow" to "read 203 lines and check them against these constants."

⇒ coverage unchanged.

## 153. ★★★ THE COMPRESSOR'S GAIN LAW, READ FROM THE FIRMWARE
§152 said what remained was *"read 203 lines and check how the constants combine."* Read, from the
committed linear disassembly (`kn5000_subprogram_v142.rom.unidasm`).

```
   39b08  cp HL,0x59 / clamp           the user value, clamped ≤ 89   (second operand: ≤ 88)
   39b1a  ld WA,0x63 ; sub WA,HL       x = 99 − user                  (0x63 = 99, the 0..99 range)
   39b2a  call 0x03dd36                int → double
   39b31  lda XDE,0x012db3 ; 0x03e290  × (−0.0697)
   39b47  push 0x012dbb ; 0x03d533     POW:  10 ^ (that)
   39b61  lda XDE,0x012dc3 ; 0x03e290  × 0.9999
   39b77  ld WA,0x63 ; sub WA,IZ       ── and the identical sequence for the SECOND cell,
   39b8e  lda XDE,0x012dcb                 using 0x012dcb / 0x012dd3: THE DUPLICATES.
```

> ★★ **cell = 10 ^ ( −0.0697 × (99 − user) ) × 0.9999** — one law, two operands.

The duplicated constant triple §152 found in the bytes is **used by the second operand's own copy
of the sequence**. That is the code confirming "one law, two operands", where §152 only had the byte
pattern and the cell map suggesting it.

In dB the law is linear in the knob: `20·log₁₀(gain) = −1.394 × (99 − user)`, unity at 99 and about
−138 dB at 0 — the shape of a threshold or range control, which is what a gain computer's input is.

### ⛔ Two things still not established, stated plainly
1. **The helper identities are INFERRED FROM USE.** `0x03dd36`, `0x03e290` and `0x03d533` are read
   as int→double, double-multiply and pow from their operands and call shape. Nothing here proves
   them; a float-library cross-check would.
2. **The eight FLOATS are not in the code I read.** `2, 2, 1, 3` and `2²¹, 2²³, 2²², 2²¹` do not
   appear before `0x039bbb`, so the **scale application is further on and unread**. The exponential
   law is read; the scaling is not.

⇒ the handover's top item is now two-thirds done as *evidence*: the scales are written down (§152)
and the law that produces the coefficient is read (§153). What remains is the scaling step and then
a comparison against a live trace. Coverage unchanged — this decodes no microcode word; it decodes
the **firmware** that feeds one.

## 154. THE SCALE STEP IS READ — single precision, its own helpers, and 2²¹ applied first
§153 left one gap: *"the eight FLOATS do not appear in the code read — the scale application is
past `0x039bbb` and is UNREAD."* Read.

```
   39bbe  XDE=0x012ddb · 0x03e290      × 0.9999      ← the second operand finishing the DOUBLE law
   39bd0  0x03dd6c                     double → …     ← and storing it
   ── from here the constants are the FLOATS and the helpers are a DIFFERENT SET ──
   39bd4  ld XWA,0x40400000            ★ the immediate 3.0f, the same value as 0x012def
   39bdf  XDE=0x012de3 · 0x03d92c      2.0f
   39bee  XDE=0x012de7 · 0x03d92c      2.0f
   39c00  XDE=XSP+0x0a · 0x03e2c0
   39c0a  XDE=0x012deb · 0x03d92c      1.0f
   39c26  XDE=XSP+0x06 · 0x03d3d4
   39c33  XDE=0x012def · 0x03e2c0      3.0f
   39c42  XDE=XSP+0x4a · 0x03e15a
   39c4f  XDE=0x012df3 · 0x03e2c0      ★ 2²¹
   39c5e  0x03d44c                     ← a final conversion
```

**Two arithmetics, cleanly separated.** The exponential law (§153) uses `0x03e290` / `0x03d533` /
`0x03dd36` / `0x03dd6c` on the **doubles**; the scaling uses `0x03d92c` / `0x03e2c0` / `0x03d3d4` /
`0x03e15a` / `0x03d44c` on the **floats** — which is exactly the split the byte decode showed
(first `0x30` doubles, last `0x20` singles) and is now confirmed by which helper touches which
constant.

★ **The first scale applied is `2²¹`** (`0x012df3`, at `0x039c4f`), immediately before the final
conversion at `0x03d44c`.

### ⛔ What is still open, and it is narrower than before
* The **helper semantics** remain inferred from use — now for two families rather than one. Nothing
  here proves `0x03e2c0` is a single-precision multiply; it is read that way from its operands.
* The **cell ↔ scale assignment** is not settled. Four scales exist (`2²¹, 2²³, 2²², 2²¹`) and this
  path applies one of them; which cell takes `2²³` and `2²²` is in code past `0x039c65`, unread.

⇒ the artefact the handover asks for now has: the constants (§152), the coefficient law (§153), and
the shape of the scaling (§154). What it lacks is the helper semantics and the cell↔scale map —
both readable, neither read. Coverage unchanged; this is firmware, not microcode.

## 155. THE CELL↔SCALE MAP — five writes, three scales, and a correction to §152
§154 left *"the cell↔scale assignment … past `0x039c65`, unread."* Read, and it is a clean repeat:

```
   39c4f  0x012df3 = 2²¹  →  0x03d44c convert  →  call 0x0387e6   ← the C-RAM writer (tag 0x26)
   39c78  0x012df7 = 2²³  →  0x03d44c          →  call 0x0388b3
   39ca8  0x012dfb = 2²²  →  0x03d44c          →  call 0x0388b3
   39cce  0x012dff = 2²¹  →  0x03d44c          →  call 0x0388b3
   39cf4  0x012e03 = 2²¹  →  0x03d44c          →  …
```

**⛔ And this corrects §152.** I dumped `[0x012DB3, 0x012E03)` — 80 bytes — and reported *"four
distinct power-of-two scales"*. The code references **`0x012E03` itself**, which that range
excludes, and there is another constant at `0x012E07`:

```
   012DF3 2²¹   012DF7 2²³   012DFB 2²²   012DFF 2²¹   012E03 2²¹   ← excluded by my dump
   012E07 = 32768 = 2¹⁵                                             ← also excluded, use untraced
```

⇒ **five scaled writes using three distinct scales** (2²¹ ×3, 2²² ×1, 2²³ ×1), not "four distinct".
An exclusive upper bound taken from a tool's reported span, and the code used the endpoint.

### ★ And it reconciles the write count with the cell map
Five writes against `host_coeff_map`'s "two cells" is not a contradiction: that function's own
docstring says it is *"restricted to +0 (C-RAM coefficient) writers"*. The first write goes through
`0x0387e6` — the C-RAM writer — and the other four through `0x0388b3`, which the coefficient map
does not track. **The map sees the C-RAM subset; the evaluator emits more.**

⇒ the artefact now has four of five pieces: constants (§152, corrected here), coefficient law
(§153), scaling shape (§154), cell↔scale map (§155). What remains is the **helper semantics** —
still inferred from use — and then a live-trace comparison. Coverage unchanged; firmware, not
microcode.

## 156. ★★★ `hi12` BIT 6 IS A THIRD BIT OF THE ALTERNATE-ENCODING FLAG — in the other half of the word

`bit11-family.md` §9 proved, on the KN5000 alone, that `lo12` bit 11 selects a second `lo12`
encoding with no SRC and no ACTION field, and closed at §11 item 1 with *"the alternate `lo12`
encoding is the object now… the question is now what the alternate form encodes"*. That pass had
one product, and its two co-varying bits (11 and 5) were both in `lo12`.

Pooled over the 6441 ESC-clear non-C-format words of **both** products (`dsp/tools/lut_idiom.py
--flag`):

```
   (hi12 bit 6  AND NOT  hi12 bit 5)   <=>   lo12 bit 11        0 exceptions in 6441
```

A bit in the **other half of the microword** tracks the flag exactly. The plain form `hi12 bit 6
<=> lo12 bit 11` misses by 14, and those 14 are **two word shapes**, `16E.8.00.000` ×12 and
`16E.8.00.655` ×2, present only in the SX-WSA1R and carrying bit 6 *with* bit 5.

**THE CONTROL, AND IT DISCRIMINATES.** All 144 plain `(hi12 bit, lo12 bit)` biconditionals and all
1584 masked ones are swept. Six masked combinations reach zero exceptions and they are the **same
finding six times** — bit 6, masked by any of bits 2/3/5 (all three are set on the `16E` shapes, so
the corpus cannot separate them), against `lo12` bit 5 or 11 (which §9.1 already showed are one
flag). The next-best `hi12` bit misses by **119**; the worst pair by **4343**.

⛔ **So the MASK is not identified.** The honest statement is *"`hi12` bit 6 agrees with `lo12` bit
11 on 6427 of 6441 ESC-clear pooled words, the exceptions being two shapes"* — not *"bit 6 and not
bit 5"*. Writing the masked form as the result would be fitting the mask to the 14 words it has to
exclude.

★ And a second structural fact falls out with its own null: **every ESC-clear alternate word carries
`class4 == 0` and `addr8 == 0`**, 119 of 119. The base rate of `addr8 == 0` among ESC-clear words
that are *not* alternate is **39.1 %**, so the exceptionlessness is not automatic. The form has no
addressing field at all — which is why `decoded()` never reaches the bit-11 guard on these words:
they are refused earlier, on their class.

## 157. ★★★ THE C63 TABLE-LOOKUP IDIOM, POOLED — exceptionless, and the clip curve has 40 entries

`instruction-set.md` measured the `C63` + class-6 idiom at 53 of 53 in both directions on the
KN5000. Pooled it is **99 sites**, and three things hold without exception (`lut_idiom.py --idiom`):

1. **Every `C63` is followed by a mode-6 word and then a mode-4 word** — 99 of 99.
2. **The head's `f31` and the class-6 word's `lo12` are coupled** — 99 of 99:
   `hi12 040` (f31 = 0, LOAD) ↔ class-6 `lo12 4CD`; `hi12 142` (f31 = 1, ADD) ↔ `lo12 407`.
3. The class-6 word's `addr8` takes **five values in the entire pooled corpus**, and the two
   products agree on all five:

```
   addr8 = 0x18 = 24   LFO family     KN 29 / WSA 24   <- the PROVEN 24-entry host-uploaded sine
   addr8 = 0x28 = 40   waveshaper     KN 17 / WSA 17   <- ★ so the CLIP CURVE HAS 40 ENTRIES
   addr8 = 0x1A/1E/20  the 407 variant  KN 7 / WSA 5
```

`upd6383.cpp`'s `UPD6383_C6LUT` arm already reads `addr8` as the entry count, citing §160's *"addr8
= 0x18 = 24 at every LFO site"* — **one product, one role**. New here: the **waveshaper half** (34
sites), the **cross-product replication**, and the two couplings. A completely different instrument,
built by a different team, uses the same five table lengths.

★ **40 is a constraint `N-DISTORTION-NOT-UNDUMPED-2026-09-12.md` did not have.** That note left open
*"which exact C-RAM cells hold the distortion waveshaper table"*. Two of its premises are now
measurably wrong about this field: C-RAM cell `0x28` is written by **neither** the preset streams
(DISTORTION writes cells 0x00–0x06 only) **nor** the boot blob (0x50–0x8B), and cell `0x18` is not
written either (CHORUS writes 0x00–0x13). `addr8` is therefore **not a C-RAM address**, which is what
the C6LUT arm assumes and what this makes explicit.

⚠ **24 is the one ANCHORED value** — the LFO table is proven to have 24 entries (1 LSB match). 40 is
read off the same field of the same idiom in a second product; **no 40-entry table has been
located**, and this does not claim one exists at any particular address.

## 158. ★★ THE POINTER-DELTA READING OF `addr8` IS EXCLUDED FOR CLASS 6 — three walk variants die

§98 put classes 4, 6 and 8 into `closure_pointer.py`'s walk-variant table on this inference:

> *"`addr8` is NEVER ZERO on classes 4, 6 and 8 — 53 of 53, 53 of 53, 44 of 44 … So the field is
> load-bearing there. One of the two live readings is that it is the SAME pointer delta classes 2
> and A carry."*

⛔ **"Never zero" licenses "load-bearing"; it does not license "pointer delta" — and class 6 is the
counterexample inside the same sentence.** Class 6's `addr8` is never zero (99 of 99 pooled) *and*
load-bearing *and* provably not a displacement: §157 shows it is the table entry count, anchored at
24.

And the walk measures the incoherence directly. `closure_pointer.py variants` reports V0 (baseline)
residue **+121** and V8 (class 6 post-increments) **+177** — a delta of **+56**. That is not an
arithmetic coincidence: the tool walks algo 1 by default, and **that image's two class-6 words carry
`addr8` 24 and 32**. V8 advances the D-RAM operand pointer by a sine table's entry count.

⇒ **V8, V10 and V12 are excluded on the MEANING of the field.** This matters because *no* variant
closes the frame, so the closure criterion by itself excludes nothing — it was never able to rank
these rows.

**What survives:** V7 (class 4 alone — residue +123, 8 → 10 nets, exactly the two class-4 words a
frame executes at +1 each) and V9 (class 8). ⛔ And `addr8` cannot separate V7 from "no move":
**class 4 carries the single value `0x01` in 99 of 99 words in both products**, so the field
expresses one displacement in eight bits under one reading and nothing under the other. A constant
field is uninformative either way. Mode 4's pointer behaviour stays **OPEN**.

⚠ Correction to my own first draft of `lut_idiom.py`: it cited V12 (classes 4 **and** 6) for a claim
about class 4 alone. V7 is the class-4 row.

## 159. WHAT THE CLASS TEST ALONE REFUSES — the measured size of the §90/§112/§128 opportunity

The three decodes that worked this month share one shape: *the class test is what refuses the word,
and the word's own form explains the class*. `lut_idiom.py --classgate` measures how much is left on
that exact footing — words that are undecoded while `_alu_half_anchored()` already passes:

```
   class 3    14 undecoded,  14 anchored          class 6    99 undecoded,  12 anchored
   class 4    99 undecoded,  99 anchored   <- ★   class 8    56 undecoded,  12 anchored
   class 5     5 undecoded,   2 anchored
   ⇒ 139 pooled words, 9 distinct shapes
```

**99 of the 139 are one shape — `0124011CE`, the idiom's third word** (class 4, `addr8 = 0x01`, SRC
0x07, ACT 0x0E, f31 = 1 ADD), in 47+ images across both products.

⛔ **Not promoted, and §158 is why.** §112's standard is *"decoded when the ADDRESSING is explained
AND the ALU half is anchored"*. The ALU half is anchored for all 139. The addressing is **not**
explained for mode 4: post-increment-by-one and no-move are both alive, they differ on exactly these
99 words, and the field that would separate them is constant. This is the single cheapest open axis
in the corpus — **+99 words on one decision** — and it names the instrument that would settle it:
anything that observes the D-RAM pointer two class-4 words later.

## 160. ★★ AND FOR MODE 4 THE RANKING CRITERION *DOES* EXIST — 8 of 11, against §149's zero

§149 checked `f31 = 3` against every anchored criterion and found **zero** carriers among the
programs where the ROM pins an answer. §159's mode-4 axis is the first open axis this month where
that check comes back positive, and it is worth being precise about why.

Asked with the oracle's **own** definition of a predictable program — `f31_oracle_pin.py`'s
selection, *"algorithms carrying an `op0x70` biquad band"*, which is `host_coeff_map`'s reading of
the firmware's own writer, not a proxy and not a landmark (§138's rule):

```
   11 algorithms carry an op0x70 band
    8 of them contain a class-4 word
    8 of 8 have an op0x70 band consumed DOWNSTREAM of that class-4 word
```

and the sharpest is **EXCITER**: class-4 at `w14`, the band's coefficient cells consumed at
`w18..w22` — **four words later**. §159 asked for *"anything that observes the D-RAM pointer two
class-4 words later"*; this observes it four words later with a band the firmware's own coefficient
designer pins.

★ **Why the oracle's float-model caveat does not bite here.** `f31_oracle_pin.py` marks itself NOT
PROMOTED partly because *"the oracle is a FLOAT model … it pins the ALGEBRA and cannot separate ADD
from ADD-with-a-different-shift, rounding or saturation"*. That is a **precision** limitation. The
mode-4 question is not a precision question: under V7 the band reads `mem[p+1]` where V0 reads
`mem[p]` — a **different operand cell**, which a graded model sees immediately.

⛔ **WHAT STILL BLOCKS IT, stated so nobody re-walks this.** The obvious static form of the test —
"under which variant do the band's words land in the `0x64..0x77` EQ state block the device's
`SPEC_SUBFB` treats as absolute?" — needs the **body's entry pointer**, and that is precisely what
`closure-pointer.md` leaves open (the frame does not close; a re-establishing mechanism is FORCED).
A purely static ranking therefore rests on the one quantity this corpus cannot supply. Contiguity
cannot substitute: under both variants the five MACs read five *consecutive* cells, so the shapes
are identical and only the absolute base differs.

⇒ **The instrument is an emulator arm, and the existing one is the wrong arm.** `UPD6383_CLS46PTR`
(§100) moves classes 4 **and** 6 together, so it can only ever test V10/V12 — both excluded by §158.
A **class-4-only** arm is what V7 needs, with the EXCITER band as the two-sided criterion: with the
arm the band's operands must change, and the oracle must get worse, or V7 is right and it must get
better. That is the next build, and it is worth +99 words on one decision.

## 161. ★★★★★ MODE 4 DECODED — +99 words, on a two-sided run that could have gone the other way

§159 measured that 139 pooled words in 9 shapes were undecoded with their ALU half **already
anchored**, 99 of them one shape — `0124011CE`, the C63 idiom's third word. §160 said the blocker
was mode 4's pointer behaviour and named the run. This is the run.

**The prediction was committed before the run**, in the handover (`85212a49`) and in the script's
own header (`8cc541f6`): *"with the arm ON, EXCITER's band must read different cells and the oracle
must get worse … or better. If the band does not move at all, the arm is not where I think it is."*

### The run

`dsp/tools/cls4_arm.sh 12`, evidence committed in `analysis/data/cls4/`.

* **The arm fired: 3 346 456 with `UPD6383_CLS4PTR=1`, 0 without.** §97 and §100 each spent a run on
  an arm that never reached its word; this one reached it first try.
* **Both runs fingerprint `prog35_exciter` ✅** from their own capture (§193's standing requirement).
* EXCITER because `f31_oracle_pin.py`'s own selection puts an `op0x70` biquad band **four words
  downstream** of its class-4 word (§160: 8 of 8 such algorithms have a band downstream).

### The answer, and it is not close

D-RAM change counts over 259 308 frames, cells `0x50..0x5F`:

```
   arm OFF   50:32699  51:56868  52:9836  53:9836  |  54:33065  55:57855  56:9941  57:9941
   arm ON    50:57661  51:1      52:1     53:1     |  54:1      55:9255   56:1     57:1    … 58..5E all chg1
```

**OFF is two live four-cell bands**, mirrored across the two channels (32699≈33065, 56868≈57855,
9836≈9941), and in each the **offset-2 and offset-3 cells change exactly together** (9836 = 9836,
9941 = 9941) — which is the DF-I y-state pair, and it is the layout this device's *own*
`SPEC_SUBFB` encodes (`(rdsrc − base) & 3 >= 2`). Not a shape I went looking for: it is the model's
own definition (§138's rule).

**ON, ten of those twelve cells are written ONCE in 259 308 frames** and the state sprays out to
`0x58..0x5E`. The filter stops running.

⇒ **The pointer does NOT advance on class 4. `closure_pointer.py` variant V7 is falsified**, and
with §158 having already excluded V8/V10/V12 on the meaning of the field, mode 4's addressing is
**explained**: `mem[ptr]`, no move — the same addressing mode 0 has.

★ **The criterion could fail, and it did — under the arm.** That is what makes the OFF column
evidence rather than a description of the status quo. And the oracle's float-model caveat does not
apply: this is *which cell is read*, not a rounding.

### What moved

`is_mode4()` added to `dsp_disasm.py` and mirrored in `upd6383d.h` / `upd6383d.cpp`, on exactly
§112's standard — addressing explained **and** ALU half anchored — and gated on
`_alu_half_anchored()` like `is_mode1`.

```
   pooled undecoded   1501  ->  1402        +99 words
   pooled coverage    81.2 % -> 82.5 %
   class 4            0 of 99 decoded  ->  99 of 99
```

Both disasm trees regenerated; **word columns 8003 of 8003 identical** (`regen_words_unchanged.sh`);
`dsp/verify.py` BYTE-MATCH OK.

⚠ **NOT claimed.** What `addr8 = 0x01` is *for* — it is constant across all 99 words in both
products, and this says only that it is not a pointer displacement. Class C (mode 4 with the
cursor-fetch bit, 7 words, `addr8 = 0`) stays undecoded because its ALU half is not anchored, which
is the right reason. And the other 40 class-test-refused words (classes 3, 5, 6, 8) are untouched:
their modes have not been through this.

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
