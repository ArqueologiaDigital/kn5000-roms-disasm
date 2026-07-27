# The consumer-lag signature, CALIBRATED — it cannot name a destination

NEC **uPD6383GF-3BA** (Technics SX-KN5000, IC311). Date: **2026-07-27**.
No hardware. Static analysis and the ROM corpus only.

**Why this note exists.** The move for this pass was to decode **`ACTION 0x0B`**,
which — measured here for the first time — gates the whole reverb ladder
together with only five other codes. The natural instrument was the one
[`adjudication-round8.md`](adjudication-round8.md) item G built and used: an
ACTION site is followed, at a characteristic lag, by a word that **sources** the
register the ACTION wrote. That statistic is the entire published basis for the
device's `LO_ACT_CAP_TA2` comment, *"DESTINATION measured (74/89, lag 1)"*.

Before using it, I asked the rule-7 question nobody had asked of it: **given a
code whose destination we already know, does it point at the right register?**

It does not. **0 of 2.**

Tool: [`../tools/capture_sig.py`](../tools/capture_sig.py).

```
python3 dsp/tools/capture_sig.py census    # the ACTION code census + a failed hypothesis
python3 dsp/tools/capture_sig.py calib     # ★ the calibration, and the verdict
python3 dsp/tools/capture_sig.py targets   # ACTION 0x0B and 0x1A
```

**POPULATION (rule 9):** the **40 distinct body images, 3154 words**. Counting
per *algorithm* replicates the twelve byte-identical reverbs and inflates every
figure by ≈4.79× — the defect round 8 item E caught in the very pass this note
re-examines.

Labels: **MEASURED** / **PROVEN BY CONSTRUCTION** / **FORCED** / **CONSISTENT** /
**FALSIFIED** / **OPEN**.

---

## 0. Result

| # | statement | label |
|---|---|---|
| **A** | ★★★ **THE INSTRUMENT FAILS ITS OWN CALIBRATION, 0 OF 2.** For `LO_ACT_CAP_TA` (`0x13` → **tempA**) the tempA and tempB profiles **tie exactly** (35 = 35 of 45) and *both are beaten by `mem`* (39) — the top signal names the wrong place. For `LO_ACT_CAP_TB` (`0x14` → **tempB**) its own register scores 39 of 59 while **the other temporary scores 51** — it prefers the **wrong register** by 20.3 points. These are the only two ACTION codes whose destinations are established independently of this statistic. | **MEASURED** |
| **B** | ★★★ **IT HAS POWER AGAINST NOISE AND NO POWER TO DISCRIMINATE.** Every profile above beats a 200-fold permutation null (ACTION labels shuffled *within* each image, preserving every other field and the whole SRC sequence). So the statistic is detecting something real — it is just not the destination. What it measures is **structural adjacency in a motif that interleaves two temporaries**. This is the **H-DIR failure mode** exactly ([`dram-cursor-closure.md`](dram-cursor-closure.md) item F, [`dram-direction.md`](dram-direction.md)): a rule that scores well and cannot choose. | **MEASURED** |
| **C** | ⚠ **CONSEQUENCE FOR THE SHIPPED DEVICE.** `LO_ACT_CAP_TA2` (`ACTION 0x19`) ships on the owner's explicit decision of 2026-07-27 with its forcing withdrawn, justified by **this measurement and nothing else**. `0x19` *is* the cleanest of the three profiles — its own register is far above null (58 of 91) while **both** other candidates sit at or below it, which neither known code manages. But **"cleanest" is not a calibrated criterion**, because neither code with a known answer produces a clean profile to calibrate it against. **The succession is real; the inference from succession to DESTINATION is what fails.** The semantic is **not refuted**; the comment is corrected and the behaviour is not touched. | **MEASURED** + a **FALSIFICATION** of the comment's strength |
| **D** | ★★ **`ACTION 0x0B` IS NOT A TEMPORARY-REGISTER CAPTURE.** Its tempA profile sits **at the null to the count** (15 vs 15 of 82) and tempB is 6 points over it; `mem` and `acc` lead, by margins *smaller* than `0x13`'s or `0x14`'s. **The negative survives the calibration**, and that is the point: a statistic that over-reports adjacency can only make a capture look **more** present, never less — so "no capture signature" is safe in a way that "capture into R" is not. | **MEASURED** (a negative) |
| **E** | ★ **`ACTION 0x1A` leans tempA (11 of 21) with tempB at null** — which is *the exact shape* `0x14` shows while writing tempB. Per item A this is **not** evidence that `0x1A` writes tempA. 21 sites, the smallest population here. | **OPEN** |
| **F** | ★★ **THE WHOLE REVERB LADDER IS GATED ON SIX CODES.** Matched mechanically over ROOM REVERB 1: **BLOCK A** ×9 (72 words) needs `ACT 0x0B`, `SRC 0x00`, `SRC 0x0B`; **BLOCK B** ×2 (20 words) needs `ACT 0x0B`, `ACT 0x1A`, `SRC 0x0B`; **BLOCK C** ×2 (18 words) needs `ACT 0x0D`, `SRC 0x00`, `SRC 0x0B`, `SRC 0x11`. **`ACTION 0x0E` does not occur in the reverb at all**, and `0x0D` only in the two tail blocks — so the reverb is *not* blocked on the 746-word `0x0D`/`0x0E` problem. | **MEASURED** |
| **G** | ★ **BLOCK B's four multiplies now resolve their coefficients** (`400000`, `382061`, `2E7551`, `CAD8AC`) — they read `NO COEF` before [`cram-unit-base.md`](cram-unit-base.md). BLOCK B, which no search has ever executed, is **three codes** from running. | **MEASURED** |
| **H** | **A structural hypothesis of mine, FALSIFIED and printed anyway.** Every ACTION code the device decodes except `0x00`/`0x12`/`0x14` has exactly **three of five bits set**, and all ten 3-of-5 codes occur — which would have bounded the field at ten values plus a no-op. Wrong: **29 of 32 codes occur**, with popcounts running 0,1,2,3,4,5 including `0x1F`. A constant-weight code cannot have members of two weights. | **FALSIFIED** |

---

## 1. The calibration

A capture into register *R* should be followed by a word **sourcing** *R*. Two
codes have destinations established independently of this statistic:

    LO_ACT_CAP_TA = 0x13  ->  tempA   (SRC 0x19)
    LO_ACT_CAP_TB = 0x14  ->  tempB   (SRC 0x1A)

Best lag per candidate register, against best-of-200 shuffles:

```
ACTION 0x13  -> tempA, known independently          sites=45
    tempA  best lag  8 :  35/ 45 =  77.8%   null  9 = 20.0%   ** above null **
    tempB  best lag  5 :  35/ 45 =  77.8%   null  8 = 17.8%   ** above null **
    mem    best lag  2 :  39/ 45 =  86.7%   null 22 = 48.9%   ** above null **
    acc    best lag  6 :  35/ 45 =  77.8%   null 21 = 46.7%   ** above null **

ACTION 0x14  -> tempB, known independently          sites=59
    tempA  best lag  5 :  51/ 59 =  86.4%   null 13 = 22.0%   ** above null **
    tempB  best lag  2 :  39/ 59 =  66.1%   null 10 = 16.9%   ** above null **

ACTION 0x19  -> tempA, CLAIMED by round 8 item G    sites=91
    tempA  best lag  1 :  58/ 91 =  63.7%   null 18 = 19.8%   ** above null **
    tempB  best lag  1 :  16/ 91 =  17.6%   null 11 = 12.1%   ** above null **
    mem    best lag  6 :  33/ 91 =  36.3%   null 36 = 39.6%   (at/below null)
    acc    best lag  8 :  34/ 91 =  37.4%   null 34 = 37.4%   (at/below null)
```

`0x13`'s tempA hit at lag **8** reproduces round 8 item F's *"lag exactly 8, 35
of 40 sites"* — the instrument is faithfully re-implemented, and it is that same
number which now reads as a tie rather than a determination, because **nobody had
run the other register.**

### 1.1 Why it behaves this way

The motif alternates between the two temporaries. A word that captures into
tempA is therefore followed, a fixed few slots later, by a stage that reads
tempB — and by one that reads tempA — with the spacing set by the *motif*, not
by the dataflow. Any statistic keyed on "which register is sourced N words
later" will find both, and which of the two wins is decided by where the motif
boundary happens to fall relative to the code being tested.

`0x19` sits in a sparser context (`mem` and `acc` are at or below null there,
which is true for neither known code), so its adjacent register stands out. That
is a real difference and it is why the shipped semantic is not being withdrawn —
but sparseness of context is not the same as having measured a destination.

## 2. What this does and does not change

**Does not change:** the shipped behaviour. `LO_ACT_CAP_TA2` continues to
execute, per the owner's decision of 2026-07-27, which was taken with the
forcing already withdrawn and rested on three legs — the semantic was never
refuted, it has independent structural support (`0x19 = 0x13 + 6` and
`0x1A = 0x14 + 6`, a second capture pair mirroring an established one), and
re-trapping ~100 words on a broken instrument's authority is not the
conservative act. **Two of those three legs are untouched by this note.**

**Does change:** the comment. Both mirrors said the destination was *measured*.
It was inferred, by an instrument that fails calibration on both codes where the
answer is known. The comment now says so.

**Rule 6 note.** Nothing was applied and nothing re-trapped. This is a
correction to a claim's *strength*, which is the one kind of change that is
always safe to make in both directions.

## 3. Predict-then-check

- **P1 MISS, and it is the note.** I expected the consumer-lag statistic to
  settle `ACTION 0x0B`'s destination. It cannot settle *anybody's*.
- **P2 MISS.** I predicted the ACTION field was a 3-of-5 constant-weight code.
  Falsified by its own census in one query (item H).
- **P3 HIT.** I predicted `0x0B` would not look like a temp capture — it does
  not, and the calibration makes that negative *stronger* rather than weaker.
- **P4 HIT.** I predicted the reverb was gated on far fewer codes than the
  746-word `0x0D`/`0x0E` problem suggests. Six, and `0x0E` is absent entirely.
- **P5 MISS.** I expected `0x13`'s known destination to validate the instrument
  and let me use it with confidence. It did the opposite, which is worth more.

## 4. What the next pass needs

1. **`ACTION 0x0B` needs a different instrument.** It is not a temp capture, so
   the remaining candidates are `mem[ptr]`, the accumulator, a pointer/register
   write, or no side effect. The **minimal pair** `02A.2.4B.00B` versus
   `02A.2.4B.000` ([`reverb-head-tail.md`](reverb-head-tail.md), sites 98/99
   against 96/97) is still the sharpest site in the corpus, and what it needs is
   a *downstream reader* that the two versions differ in — which is exactly what
   `target4.py act0b` says it does not yet have.
2. **Do not use the consumer-lag statistic to name a register again** without
   re-running `capture_sig.py calib` first.
3. **Any pass re-examining `ACTION 0x19`** should treat round 8 item G as
   establishing *succession*, not destination.
