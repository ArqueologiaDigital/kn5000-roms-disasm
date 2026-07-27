# Re-deriving the speculative carry-backs — one confirmed and strengthened, one killed

NEC **uPD6383GF-3BA** (Technics SX-KN5000, IC311). Date: **2026-07-27**.
No hardware. Static analysis only — **no execution, no ALU model, no adopted
readings.**

**Why this note exists.** [`SPECULATIVE-reverb-run.md`](SPECULATIVE-reverb-run.md)
was produced with unverified readings deliberately adopted, and is not
evidence-gated. It named three things worth carrying back. This note tries to
establish them **under the normal discipline**, and the point of the exercise is
that they do not all survive.

Labels: **MEASURED** / **PROVEN BY CONSTRUCTION** / **FORCED** / **FALSIFIED**.

---

## 0. Result

| # | carry-back | verdict |
|---|---|---|
| **1** | The flush read and prime write, observed in execution | ★ **CONFIRMED, and STRENGTHENED to a stronger claim** |
| **2** | "Can the program pass signal" as an elimination criterion | **NOT re-derivable as used** — it depends on an unestablished input-injection point |
| **3** | `ACT 0x0D` is blind in the reverb | ⛔ **FALSIFIED.** It is observable; the speculative blindness was an artefact |

---

## 1. Carry-back 1 — CONFIRMED, and it says more than the published claim

The DRAM access *sequence* needs no ALU at all: which address each word touches,
and in which direction, is fixed by the **FORCED** cell↔word identity map
([`adjudication-round5.md`](adjudication-round5.md)) and the **FORCED**
`addr8` bit-6 direction rule. The adopted readings affect *values*, never
*addresses*. So the speculative observation can be re-derived with no
speculation whatsoever:

```
population: 83 ALIGNED algorithms (the 8 unaligned excluded, as bounds.py does)

  CEILING address is READ and NEVER WRITTEN   : 83 of 83
  first WRITE address (LIMIT) is NEVER READ   : 75 of 83
```

The CEILING result is **exceptionless**. (The LIMIT's 75 is the expected
shortfall: [`dram-bounds.md`](dram-bounds.md) item A gives 9 algorithms a FLOOR
instead of a LIMIT, and a FLOOR is a read.)

★ **And this is a stronger statement than the published one.**
[`dram-datapath.md`](dram-datapath.md) item A establishes the CEILING and LIMIT
by **position** — "the last READ of its program, 83 of 83", "the first WRITE,
74 of 74". This establishes them by **address reachability**: the CEILING
address is *never a write target anywhere in the program*, and the LIMIT address
is *never a read target*. Position implies nothing about reachability on its
own; a program could perfectly well read an address it also writes elsewhere,
and 136 addresses in the corpus do exactly that.

So `dram-datapath.md` item A can be upgraded from CONSISTENT-by-position to a
reachability property that holds for every aligned algorithm, with no execution.

## 2. Carry-back 2 — not re-derivable as it was used

The criterion — *score a candidate reading by whether the program can pass
signal at all* — eliminated 30 of 36 combinations in the speculative run, and it
is a genuinely different kind of test from numeric match or statistical
signature.

But as applied it rests on the **input-injection point**: the speculative run
put the impulse in the cell that the first `mem[ptr]`-sourcing class-A word
reads, and that choice is not established. A different injection point could
make a different reading look like the one that "passes signal".

**Not carried back.** The idea is sound and worth keeping; the application needs
the injection point derived first, which is its own piece of work.

## 3. Carry-back 3 — FALSIFIED, and the reason matters

The speculative sweep found six readings of `ACT 0x0D` giving **bit-identical**
output, and I filed that as a decidability fact. Dataflow says otherwise.

`ACT 0x0D` occurs in ROOM REVERB 1 at `w005`, `w119`, `w130`. For each possible
destination, is the value read before being overwritten?

| site | dest `tempA` | dest `tempB` | dest `mem[ptr]` |
|---|---|---|---|
| `w005` | never read | **READ at `w012`** | **READ at `w119`** |
| `w119` | never read | **READ at `w012`** | **READ at `w130`** |
| `w130` | never read | **READ at `w012`** | **READ at `w005`** |

**Two of the three destinations are observable at every site.** `ACT 0x0D` is
*not* blind in the reverb.

### 3.1 Why the speculative run saw blindness anyway

All three sites carry `SRC 0x07` — `mem[ptr]` — at pointer `0x80`, and **in the
speculative configuration nothing ever wrote cell `0x80`**. So the bus was zero
at all three sites, every reading wrote zero, and writing zero is
indistinguishable from writing nothing.

The blindness was a property of **that configuration**, not of the program. A
sweep over readings, with a control that varies the reading and nothing else,
found no difference — and the reason was that the *operand* was zero, which is
not something varying the reading could have revealed.

★ **This is the twelfth control-that-cannot-fail on this chip, and the first
that was caught by re-derivation rather than by inspection.** It is also the
clearest argument yet for why the speculative track needs the rigorous one: the
speculative run produced a confident, clean-looking negative that is simply
false, and nothing inside that run could have detected it.

### 3.2 What replaces it

`ACT 0x0D` is **decidable in the reverb**, via `tempB` at `w012` or via
`mem[ptr]` at the next `0x0D` site — as soon as the bus at `w005`/`w119`/`w130`
carries something. Since that bus is `mem[0x80]`, the question becomes: **what
writes cell `0x80`?** That is a concrete, bounded next experiment, and it is
better than the "blind, look elsewhere" conclusion it replaces.

## 4. Predict-then-check

- **P1 HIT.** I predicted carry-back 1 would re-derive statically, because
  addresses do not depend on semantics. It did, exceptionlessly.
- **P2 unforeseen.** I did not predict it would yield a *stronger* claim than the
  published one.
- **P3 MISS, and the useful one.** I predicted `0x0D`'s blindness was a property
  of the program. It is a property of a zero operand in one configuration, and
  the dataflow contradicts it at two destinations out of three.
- **P4 HIT.** I predicted carry-back 2 would not survive without the injection
  point, and flagged that in the speculative note before testing it.

---

## 5. Second iteration — a hypothesis that works and cannot be tested

**Speculation A — the delay-read datum lands in a temporary rather than a
separate DR register.** Motivated by the surviving defect: the delayed sample
arrives in `tempB` at `.0` and is never overwritten before `.5`, yet `.5`
multiplies `tempA`. **Refuted immediately** — routing the read datum to `tempA`
*reduces* the live ladder addresses from 5 to 3. Not a near miss; wrong.

**Speculation B — `ACT 0x15` is a capture, but only on a class-1 DRAM PORT
word.** Motivated by exactly what the biquad refutation did and did not say: it
killed `0x15` as a **global** capture, and the biquad's three `0x15` words are
class A and class 8, while the reverb's is **class 1 with the `hi12` escape**.
`lo12` is operand *routing* and `class4` selects the unit, so a per-class
interpretation is not ad hoc.

**It works.** Live ladder addresses 5 → **16**, and signal persists to frame
**1356** where the global reading died at frame 0 — the first configuration that
produces anything resembling a tail.

### 5.1 And then the rigorous check, which is the point

| check | result |
|---|---|
| blast radius | **53** of 698 corpus `0x15` words are class-1 port words — 7.6%, not the 1323 the global reading would have touched |
| does the biquad refute it? | **No — it has 0 class-1 port words.** The refutation genuinely does not apply |
| does the biquad *confirm* it? | **No — for exactly the same reason** |
| PARAMETRIC EQ / SINGLE DELAY / AUTO PAN | **0** such words each |
| CHORUS | 4 such words — **all outside the anchored LFO block windows** |
| LFO blocks in the whole corpus containing one | **0 of 29** |

★ **The reading survives the refutation *by construction*, which is the same
fact as: no independently-anchored program can test it.** Every context on this
chip whose arithmetic we know — the biquad, the SINGLE DELAY motif, all 29 LFO
ramp windows — contains **zero** class-1 `ACT 0x15` port words.

### 5.2 The honest verdict

This is a hypothesis that **makes the machine work and cannot be falsified by
anything we trust**. That combination is precisely what this project has been
burned by repeatedly — a reading that explains the data because it was shaped to,
with no instrument able to say no.

It is not evidence. It is a **prediction**, and it makes a specific one: under
this reading the reverb produces a decaying tail out to ≈1356 frames with the
ROM's own gains and delays. **The only instrument that can test it is the real
KN5000.** That moves it out of static analysis entirely and into the one place
this project treats as ground truth — Felipe's hardware.

Filed accordingly: **not applied, not carried back, and not to be quoted as a
decode.** Recorded because a well-posed question for the hardware is worth more
than a badly-posed one for the solver.

---

## 6. Third pass — the speculation's *premise* validated, and refuted

§5 left Speculation B (`ACT 0x15` is a capture on class-1 DRAM port words) as
"works, untestable". That framing was incomplete. The reading itself may be
untestable, but the **premise it rests on — that the ACTION field is
re-interpreted on port words — is fully testable, on codes whose meaning we
already know.**

### 6.1 The ACTION field is not a separate space on port words

Census over the 40 distinct images, 3154 words, splitting every ACTION code by
whether its word is a class-1 DRAM port word:

```
  codes appearing on BOTH sides          : 10   00 07 0B 0E 11 14 15 19 1A 1C
  ...of which ANCHORED (meaning known)   :  5   00 07 14 15 19
```

Five codes whose semantics are fixed by the biquad — an ALU context — also occur
on port words. So the ACTION field is **not** a separate namespace: the same
codes are used on both sides of the split.

### 6.2 And an anchored code demonstrably KEEPS its ALU meaning on a port word

The decisive case is in the block under investigation, and it needs no execution:

```
w019  08801602D4   class-1 PORT word
      SRC 0x0B  = the delay-read register   [anchored]
      ACT 0x14  = tempB <- bus              [anchored, fixed by the biquad]

w022  0012200680   ordinary ALU word
      SRC 0x1A  = tempB                     [anchored]
```

`w019` is a port word, and **its anchored ALU meaning is exactly what delivers
the delayed sample into `tempB`** — from which `w022` brings it to the
accumulator. If the ACTION field were re-interpreted on port words, that capture
would not happen and the delayed sample would never reach the accumulator at
all. It demonstrably does (`tempB = 20114` at frame 800). Nine such words in this
image — every BLOCK A `.0`.

### ⛔ 6.3 Verdict

**Speculation B's motivation is refuted.** `ACT 0x14` keeps its ALU meaning on a
class-1 port word, in the very block the speculation was invented to fix, so
there is no principled reason for `ACT 0x15` to acquire a different one there.

The class-dependent reading is therefore not merely *untestable* (§5.1) — the
structural argument that made it plausible now **points the other way**. It
should be dropped, not parked.

### 6.4 What survives, and it is the real result

The defect stands and is now better isolated. BLOCK A carries the delayed sample
from the DRAM port into the accumulator **entirely through anchored semantics**
— `ACT 0x14`, `SRC 0x0B`, `SRC 0x1A`, all fixed independently — and then
discards it at `.4` before the multiply at `.5`. Every step of that chain is
anchored. So:

> **The defect cannot be explained by any undecoded ACTION or SRC code in the
> block.** The delivery is anchored; the destruction at `.4` is `f31 = 0`, which
> the biquad fixes; the multiply at `.5` sources `tempA`, which is anchored.

Whatever is wrong is in something all of those share — the **order** of capture
against the accumulator operation, the **`ACT 0x19`** capture at `.2` (shipping
on a withdrawn forcing), or the assumption that `.5`'s multiplicand register is
the one we think. That is a much smaller space than "one of the undecoded
codes", and it is where the next rigorous pass should go.
