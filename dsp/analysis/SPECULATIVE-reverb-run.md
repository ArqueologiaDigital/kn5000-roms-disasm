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

## What to carry back, and what to burn

**Carry back (re-derive under the normal discipline first):**

1. **Result 6** — the executed flush-read / prime-write behaviour. Independent
   confirmation of a published FORCED result, from execution rather than
   structure.
2. **Result 2's method** — scoring a candidate reading by *whether the program
   can pass signal at all*. This project has scored readings by numeric match
   and by statistical signature; "does the machine function" is a third
   criterion, it is cheap, and here it eliminated 30 of 36 combinations.
3. **Result 3** — `0x0D`'s blindness in the reverb, which is a decidability
   fact and holds regardless of the speculation around it.

**Burn:**

- Every specific reading adopted. `0x1A = tempB ← bus`, `f31hi = base`,
  `SRC 0x00 = mem[ptr]` are guesses that happened to be in the harness while the
  interesting things were measured. **None of them is supported by this run**,
  because the run did not vary them.
- The claim that `0x0E = mem[ptr] ← bus`, until it is re-derived without
  assuming the injection point.

## The honest verdict

The speculative machine is **not a working reverb**. It has functioning early
reflections and a diffuser ladder that dies after two of eleven stages. But it
is the first version of this program that runs end to end, and running it
produced one independent confirmation, one new elimination criterion, and one
precisely located failure — none of which were reachable from the gated side.
