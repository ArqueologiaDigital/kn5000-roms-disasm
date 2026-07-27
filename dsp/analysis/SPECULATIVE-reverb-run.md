# ⚠ SPECULATIVE — the reverb run with unverified readings adopted

> ## ⚠⚠ THIS NOTE IS NOT EVIDENCE-GATED ⚠⚠
>
> Everything below was produced by **deliberately adopting unverified readings**
> at Felipe's request, as a creativity experiment, on the explicit understanding
> that it can be abandoned. **Nothing here is FORCED, nothing is applied, and
> nothing in it may be quoted as established.** The revert point is the tag
> `rigorous-baseline-2026-07-27` (and `kn5000-dsp-rigorous-baseline-2026-07-27`
> in `kn7000_mame`).
>
> The value of the pass is not the readings. It is **three things the
> speculative machine revealed that the gated one could not**, two of which are
> checkable under the normal discipline.

NEC **uPD6383GF-3BA** (Technics SX-KN5000, IC311). Date: **2026-07-27**.

## The configuration adopted

| parameter | value | basis |
|---|---|---|
| `ACT 0x1A` | `tempB ← bus` | guess — `0x19`'s +6 pair partner |
| `ACT 0x0D` | any | swept |
| `ACT 0x0E` | swept | — |
| `ACT 0x0B` | `none` | the shipped silent reading |
| `f31hi` | `base` | the frequency-shape lead |
| `wdata` | `acc` | the only regime in which the ALU is visible |
| `SRC 0x00` | `mem[ptr]` | the plurality reading |

## Result 1 — the whole program executes, for the first time

**All 133 words run.** Not 124, not 107 — all of them. That has never happened
before in this project, and it is what made everything below observable.

## Result 2 — `ACT 0x0E` has to be a memory write, on a functional argument

Sweeping `0x0D` × `0x0E` over six readings each, **the only configurations in
which any energy reaches the delay lines at all are those with
`0x0E = mem[ptr] ← bus`.** All 36 combinations were run; the six with that
setting reach a peak delay-line write of **100 575**, and the other thirty
reach **zero**.

The mechanism is visible in a word-by-word trace of frame 0: the input enters at
`w002` (`P = 262144`), survives `w003`–`w005` in the accumulator — and **`w006`
destroys it**, because `w006` has `f31 = 0`, i.e. `acc ← P`, with `P` zero at
that point. The only way the input survives the frame is if `w005`/`w006` put it
somewhere first, and of the readings tried only a memory write does.

This is a **functional** argument — *the program has to pass signal* — rather
than a statistical one, and that makes it a different kind of evidence from
anything in the gated notes. **It is still not a proof:** it assumes the input
injection point is right, and it only rules out the five alternatives actually
enumerated.

## Result 3 — `ACT 0x0D` is blind here

All six readings of `0x0D` give **bit-identical** output. Another blind site, in
the same family as the three already on record. Whatever settles `0x0D`, it is
not the reverb.

## Result 4 — the early-reflection section WORKS

Per-address, over 2500 frames:

```
  addr    #W  peak|W|      #R  peak|R|   read back?
  32768 2500     20114      0         0   (the pre-delay buffer, written)
  33308    0         0   2500     20114   YES   <- D = 540
  33418    0         0   2500     20114   YES   <- D = 650
  33568    0         0   2500     20114   YES   <- D = 800
```

One buffer, three taps, at exactly the delays `bounds.py` derives for L13, L12
and L0 — and the value written comes back **undamaged** at all three. The
early-reflection design is not merely consistent with the addressing; it
**runs**.

## Result 5 — the ladder propagates two stages and then dies

```
  41673 2500     12671   ...   read at 41845 -> 12671   YES   L2, D = 172
  42201 2500      6335   ...   read at 42714 ->  6335   YES   L4, D = 513
  43453 2500         0   ...                                  dead
  ... every later ladder address: written 0, read 0
```

Energy enters at 20 114, is 12 671 after one ladder stage, 6 335 after two, and
**zero after three**. The chain breaks at the write into 41590 (L1's write),
which is always zero.

That is a *specific, addressed* failure — not "it doesn't work" but "it dies at
this write, at this address, after this stage". Whatever is wrong with the
adopted readings, it is wrong **there**.

## ★ Result 6 — an independent confirmation of the bounds model

This one is worth more than the rest, because it is checkable and it came from a
direction that did not assume it:

```
  32767     0 writes   2500 reads    <- the CEILING: read every frame, NEVER written
  45464  2500 writes      0 reads    <- the LIMIT:  written every frame, NEVER read
```

`dram-bounds.md` and `dram-datapath.md` derive the CEILING as a **trailing flush
read whose datum is discarded** (83 of 83) and the LIMIT as a **leading prime
write at an address no read can reach** (74 of 74), from descriptor values and
program order. This run *executes* the program and finds exactly that behaviour
— an address read 2500 times that nothing ever writes, and an address written
2500 times that nothing ever reads.

**That is a confirmation the gated work could not produce**, because the gated
model cannot run the program. It should be re-derived properly and, if it holds,
it strengthens `dram-datapath.md` item A from a static argument to an executed
one.


---

## ⛔ Result 7 — `ACT 0x15` as a capture: PROPOSED, THEN REFUTED

> **KILLED THE SAME DAY, by the biquad, at 53.474 dB.** Read the whole section
> anyway: the hypothesis died but **the problem that motivated it did not**, and
> that surviving problem (§7.1) is the real output of this pass.

Tracing the frame in which the pre-delay returns (frame 800) shows the ladder
failing for a *specific, mechanical* reason:

```
w022  SRC 1A -> acc = 10057     the delayed sample arrives from tempB
w023  f31=0  -> acc <- P = 0    ...and is destroyed one word later
w024  multiplies tempA = 0
```

The stage loads the delay-line sample and throws it away before the multiply.
**A filter cannot do that.** And the word that throws it away, `w023`, carries
**`ACT 0x15`** — which ships as *"no temp/memory side effect"* with the device's
own comment: *"ditto — how it differs from `0x12` is OPEN."*

If `0x15` captures the accumulator into tempA, the stage becomes coherent: the
delayed sample arrives at `.3`, is captured at `.4` **before** the accumulator is
overwritten, and is multiplied by the stage gain at `.5`.

**Tested, sweeping four readings of `0x15` with everything else fixed:**

| `ACT 0x15` | ladder addresses carrying signal |
|---|---|
| `none` (shipped) | 5 |
| `tB<-acc`, `tA<-bus`, `tB<-bus` | 5 (identical to shipped) |
| **`tA<-acc`** | **16** |

It is the only one of the four that changes anything, and it triples the reach.
The resulting cascade:

```
  41590   15085     41673    9503     41845    4941
  42201    2470     42714     987     43453     103
  43693      65     43812      41     44059      22
  44487       9     45103       5
```

`20114 × 0.750 = 15085`. `× 0.630 = 9503`. `× 0.520 = 4941`. `× 0.500 = 2470`.
`× 0.400 = 987`. **Every stage attenuates by exactly its own ROM coefficient, to
±1 LSB, in ladder order, through all eleven stages** — where the shipped reading
dies after two.


### ⛔ 7.0 The refutation

The solved biquad carries `ACT 0x12` once and **`ACT 0x15` three times**, and it
captures `tempA` at word 0 via `ACT 0x13`. A `0x15` that also writes a temporary
clobbers that capture two words later. Scored against the firmware's own
coefficient designer:

| `ACT 0x15` | worst-band error |
|---|---|
| `none` (shipped) | **0.198 dB** — accepted |
| `tA<-acc` | **53.474 dB** — REJECTED |
| `tB<-acc` | 31.897 dB — REJECTED |
| `tA<-bus` | 53.474 dB — REJECTED |
| `tB<-bus` | 59.311 dB — REJECTED |

**`ACT 0x15` is not a capture.** The shipped no-op stands, and the 1323-word
blast radius does not open. One query, known mathematics, no ambiguity — exactly
what the gated instrument is for, and exactly the right way for a speculative
lead to die.

### ★ 7.1 But the problem it was invented to solve is REAL, and it survives

The refutation removes the answer, not the question. Under **every** semantics
this project currently has, the reverb's BLOCK A does this:

```
.3  acc <- tempB + P      the delayed sample arrives
.4  acc <- P              it is destroyed, one word later
.5  multiply tempA        which never saw it
```

A filter stage cannot load its delay-line sample and discard it before the
multiply. So **something in the current decode of BLOCK A is wrong**, and it is
localised to three words — `.2` (`ACT 0x19`), `.3` (`SRC 0x1A`, `ACT 0x00`) and
`.4` (the DRAM read, `f31 = 0`).

That is a **constraint on the model that does not depend on any speculation**,
and it is the durable result of this pass. Note which word is the prime suspect:
`.2` carries **`ACT 0x19`** — the code shipping on a *withdrawn* forcing, whose
destination `capture-signature.md` showed is not actually measured.

### What the ladder result was, before it fell

**Is:** a mechanism argument (the stage must capture before it clobbers) that
predicts a specific reading, plus a functional test that the reading passes and
its three rivals fail, on a chain eleven stages deep.

**Is not:** proof. The gain cascade is partly circular — the coefficients *are*
the ROM's, so any model that applies them in sequence shows this. What is **not**
automatic is that they apply **once per stage, in ladder order**: under the
shipped `0x15` they do not apply at all past stage two. And the run still has
**no recirculation** — energy traverses the ladder and leaves. A reverb tank
needs feedback that this configuration does not produce.

**The check to run under the normal discipline:** `0x15` is *anchored* and
shipping as a no-op. If it is really a capture, that is not a new decode — it is
a **correction to a shipped semantic**, and it would touch every program
containing `ACT 0x15`, which is **1323 corpus words, the second most common
ACTION code on the chip**. That is a large enough blast radius that it must be
re-derived from a context with known mathematics before anyone touches the
device.

## What to carry back, and what to burn

**Carry back (re-derive under the normal discipline first):**

1. ★★ **Result 7.1** — BLOCK A discards its delayed sample under every current
   semantics. A model-level defect, localised to three words, independent of the
   speculation. `ACT 0x19` at `.2` is the prime suspect.
2. **Result 6** — the executed flush-read / prime-write behaviour. Independent
   confirmation of a published FORCED result, from execution rather than
   structure.
3. **Result 2's method** — scoring a candidate reading by *whether the program
   can pass signal at all*. This project has scored readings by numeric match
   and by statistical signature; "does the machine function" is a third
   criterion, it is cheap, and here it eliminated 30 of 36 combinations.
4. **Result 3** — `0x0D`'s blindness in the reverb, which is a decidability
   fact and holds regardless of the speculation around it.

**Burn:**

- Every specific reading adopted. `0x1A = tempB ← bus`, `f31hi = base`,
  `SRC 0x00 = mem[ptr]` are guesses that happened to be in the harness while the
  interesting things were measured. **None of them is supported by this run**,
  because the run did not vary them.
- The claim that `0x0E = mem[ptr] ← bus`, until it is re-derived without
  assuming the injection point.
- **`ACT 0x15 = tempA ← acc` — refuted outright, §7.0. Do not revive it.**

## The honest verdict

The speculative machine is **not a working reverb**. It has functioning early
reflections and a diffuser ladder that dies after two of eleven stages. But it
is the first version of this program that runs end to end, and running it
produced one independent confirmation, one new elimination criterion, and one
precisely located failure — none of which were reachable from the gated side.
