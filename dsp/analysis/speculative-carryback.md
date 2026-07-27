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
