# SINGLE DELAY restored — the third known-mathematics context runs, and the first thing it produced was a false positive I caught

NEC **uPD6383GF-3BA** (Technics SX-KN5000, IC311). Date: **2026-07-27**.
No hardware. Static analysis, the ROM corpus and simulation only.

Labels: **MEASURED** / **PROVEN BY CONSTRUCTION** / **CONSISTENT** / **VOID** / **OPEN**.

---

## 0. Result

| # | statement | label |
|---|---|---|
| **A** | ★★★ **THERE ARE THREE KNOWN-MATHEMATICS CONTEXTS, NOT TWO, AND THE THIRD WAS NEVER CHECKED.** [`three-codes.md`](three-codes.md) §1 concludes *"both instruments this chip has are blind"* to `ACT 0x0D`/`0x0E`/`0x1A`, having tested PARAMETRIC EQ and the LFO. [`action00-discriminator.md`](action00-discriminator.md) item D names **PARAMETRIC EQ, SINGLE DELAY and the LFO**. SINGLE DELAY carries **`ACT 0x0D` ×4 and `ACT 0x0E` ×4**. | **MEASURED** |
| **B** | ★★ **Its harness was voided in round 6 and never rebuilt.** [`adjudication-round6.md`](adjudication-round6.md) items A/B: the DRAM polarity was reversed against `dram_dir()`, and the `Line` read and wrote **one index**, so the delay came from port order rather than from the descriptor. [`adjudication-round7.md`](adjudication-round7.md) item E: *"the SINGLE DELAY leg is the void one."* **Both defects are still in `action00_discriminate.sd_run()` today.** | **MEASURED** |
| **C** | ★★★ **RESTORED, AND IT PRODUCES ITS KNOWN OUTPUT.** With a rotating-cursor DRAM the delay falls out of the descriptors: `write 31871 / read 31370 → 501` and `write 15935 / read 15435 → 500` — an impulse comes back at **exactly 500 at `w46` and 501 at `w5`**. First time this program has ever produced its predicted output. ⛔ **The "stereo" reading of these two taps is CORRECTED in §5: they are in SERIES.** | **MEASURED** |
| **D** | ⛔ **A POLARITY CONFLICT THAT DISSOLVED ON ENUMERATION — reported here because it was nearly published.** At the forced polarity, an exhaustive sweep over **261 entry states × 256 start pointers = 66 816** configurations delivered the input to a delay-DRAM write **zero** times, while the reversed polarity did so 1 024 times. That looked like a fourth witness against [`adjudication-round5.md`](adjudication-round5.md) item D. **It was an artefact of MY fixed ALU readings.** Enumerating `order × act00 × act0d × act0e` gives **7 680** delivering configurations at the forced polarity. **Round 5 item D stands, untouched.** | **MEASURED**; the conflict is **WITHDRAWN** |
| **E** | ⛔ **AND THE `ACT 0x0E` DISCRIMINATION IT THEN OFFERED IS VOID.** The sweep showed `act0e ∈ {tA←bus, tB←bus, tA←acc, tB←acc}` delivering 60 times each and **`mem←bus` never** — which would contradict [`three-codes.md`](three-codes.md) items B and C, whose two independent routes both give `0x0E = mem[ptr] ← bus`. **The calibration refutes the instrument, not the consensus.** | **VOID** |
| **F** | **`ACT 0x0D` is not discriminated either** — all five readings deliver **48** configurations each; only `None` fails. Consistent with item E of `three-codes.md` calling `0x0D` the hardest of the three. | **MEASURED** (a negative) |

---

## 1. The calibration that voided item E

`ACT 0x07` is **ANCHORED** as `mem[ptr] ← bus`. If the test can see the
memory-versus-register distinction at all, then re-pointing that *known* memory
writer somewhere else must change what it delivers.

```
   configuration                      configs delivering
   baseline (act0e = tA<-bus)                 32
   act0e = mem<-bus          TARGET            0

   dest07 = mem   KNOWN memory writer         32
   dest07 = tA                                32
   dest07 = tB                                32
   dest07 = acc                               32
```

★ **Moving the anchored memory writer off memory changes nothing — 32, four times
out of four.** The instrument is blind to memory-versus-register. Its rejection of
`act0e = mem←bus` therefore cannot be attributed to that distinction, and no
conclusion about `ACT 0x0E` may be drawn from it.

### 1.1 And the mechanism is visible

Tracing the frame directly, with entry cell `0x03` and `p0 = 0x08`:

```
   act0e = tA<-bus     ACT 0x0E at w045: pointer = 0x03, wrote []
                       DRAM write carrying signal: w46
   act0e = mem<-bus    ACT 0x0E at w045: pointer = 0x03, wrote [(0x03, 0)]
                       DRAM write carrying signal: NONE
```

**The `0x0E` word at `w045` sits on pointer `0x03` — the input cell — and under
`mem←bus` it writes a zero over it.** The zero is a property of *where this
harness injects the input*, not of what the opcode does.

## 2. Why this keeps happening, stated plainly

This is the **sixth** instrument in a week that could not measure what it was built
to measure, and the third caught *before* a conclusion was stated. All six share
one shape, already named in [`three-codes.md`](three-codes.md) §5.1: **each tested a
LEVEL or a PRESENCE when the claim was about an IDENTITY or a TREND.**

"Does the input reach a delay-DRAM write" is a **presence** test. The claim it was
being asked to support — *what does `ACT 0x0E` do* — is an **identity**. A presence
test cannot separate two opcodes that both let signal through by different routes,
and it fails any opcode whose side effect happens to overwrite the probe.

## 3. What survives, and it is not nothing

★ **SINGLE DELAY executes end to end and emits the delay its descriptors specify.**
That was not true this morning, and it has not been true at any point in this
project's history. The context is *live*; only this particular observable was
useless.

## 4. What the next pass needs

1. ★ **Score the echo's VALUE, not its existence.** SINGLE DELAY's mathematics is a
   comb: `y[n] = a·x[n] + b·x[n−D]`, `D ∈ {500, 501}`, and the two gains are in the
   C-RAM stream. Comparing the emitted amplitude against that reference is an
   **identity** test and is the instrument item E needed.
2. ⛔ **Do not re-run the presence test.** §1 shows it cannot see the distinction it
   was asked about; §1.1 shows what it actually responds to.
3. **Carry the calibration into the harness itself.** Every future SINGLE DELAY run
   should print the `dest07` row alongside its result, so an instrument that has
   lost its power announces it.
4. ⛔ **`sd_run()` in `action00_discriminate.py` still carries both round-6
   defects.** Nothing in this note changes that; `sd_rerun.py` is a separate tool
   and the old one's numbers remain void.

---

## 5. The value test — it runs, it reproduces a ROM coefficient, and it still cannot decide the codes

§4 specified the instrument: score the echo's **value** against the program's own
mathematics rather than its presence. Built and run. Three results, one of them a
correction to §0 item C.

### 5.1 ⛔ CORRECTION — the two taps are in SERIES, not stereo

§0 item C read the pair as a stereo ~11.3 ms delay. **Execution says otherwise.**
Tracing the impulse:

```
   n=   4   w46 WRITE  cell 15935   <- the input enters
   n= 504   w0  READ   cell 15435   <- 500 samples later
   n= 504   w5  WRITE  cell 31871   <- and is re-written into the SECOND line
   n=1005   w9  READ   cell 31370   <- 501 samples after that
```

★ **`w0`'s read feeds `w5`'s write.** The two taps are a **cascade**, and SINGLE
DELAY's total delay is **1001 samples ≈ 22.7 ms**, not two parallel 11.3 ms
channels. The descriptors alone could not tell the two apart; only running it could.

### 5.2 ★★ It reproduces an exact product of its own ROM coefficients

```
   BASELINE      lag 1001    gain +0.02149296
                 = -0.207331 x -0.207331 x 0.500000     to 0.001%
```

All three factors are values in algo 9's own C-RAM stream. **This is the biquad
result on a second program**: PARAMETRIC EQ reproduces its designer to 0.113 dB,
and SINGLE DELAY now reproduces a three-factor coefficient product to 0.001 % at
the lag its descriptors specify. **The datapath is right**, independently of what
the undecoded ACTIONs mean.

### 5.3 ⛔ But it does not discriminate — 25 machines, 2 outcomes

```
   act0d x act0e, all 5 x 5 readings:

      lag 1001 gain +0.02149296  ....  20 machines
      NO ECHO                    ....   5 machines   (exactly act0e = mem<-bus)
```

* **`ACT 0x0D`: all five readings identical.** No discrimination whatever.
* **`ACT 0x0E`: the same binary split the presence test gave** — `mem←bus` passes
  nothing, the four register captures are indistinguishable from one another.

### 5.4 And the calibration fails the same way

```
   dest07 = mem / tA / tB / acc      ->  +0.02149296, +0.02149296, +0.02149296, +0.02149296
   act19  = tB<-bus                  ->  NO ECHO
   src00  = acc                      ->  NO ECHO
```

Moving the **anchored** memory writer changes nothing, 4 of 4 — the identical
failure §1 found. And `act19` and `src00` also produce NO ECHO, which shows the
"no echo" outcome is **generic breakage of the register chain**, not something
specific to `ACT 0x0E`.

### 5.5 ★ Why no observable of this kind can work — the structural reason

**The emitted gain is a product of COEFFICIENTS.** The ALU readings decide *whether*
signal flows; the C-RAM values decide *what it is multiplied by*. So every machine
that passes signal at all emits the **same** number, and every machine that breaks
the chain emits nothing. The output amplitude is invariant across the entire
question being asked.

The null confirms it from the other side: scrambling the ROM's own coefficients
among the same slots still yields one clean echo at lag 1001, with gains
`+0.0289 / −0.0155 / −0.0219` — **the gain tracks the coefficients, not the
semantics.**

## 6. What this closes

[`three-codes.md`](three-codes.md) item A said *"NEITHER known-mathematics context
can decide any of the three"*, having counted two. §0 item A found the count was
three. **The third has now been built, run, and measured, and it cannot decide them
either — for a reason that is understood rather than assumed** (§5.5).

★ **So the census is complete: all three known-mathematics contexts on this chip are
blind to `ACT 0x0D`, `0x0E` and `0x1A`, and the corpus contains no fourth.** That is
no longer an inference from two checks; it is an exhaustive result over all three,
with the mechanism of the third's blindness identified.

**This is the evidence that justifies going outside the ROM.** It is not a failure
to find the answer — it is a proof that the answer is not in the place we have been
looking.

## 7. What the next pass needs

1. ⛔ **Do not build a fourth acceptance test on SINGLE DELAY.** §5.5 gives the
   structural reason no amplitude observable can separate the readings.
2. ★ **SINGLE DELAY is now a VALIDATION context, not a discrimination one** — use it
   the way the biquad is used: to confirm a datapath change did not break the
   arithmetic. `sd_rerun.py value` is that regression test, and it has a known
   answer: **lag 1001, gain +0.02149296**.
3. ★ **External evidence is now the justified move** (§6): a uPD6383-family
   datasheet, a documented sibling, or hardware measurement.

---

## 8. A speculative round — `NO OPERATION` as a fourth context, and what it actually gave

§7 said external evidence is the justified move. Before taking it, one creative
pass, because §5.5 names precisely what *kind* of observable fails and that narrows
what to invent.

**The idea.** §5.5 kills **amplitude** observables — the emitted gain is a product
of coefficients and is invariant across every machine that passes signal. It says
nothing about **LAG**, which is structural. And `NO OPERATION` is a candidate fourth
context that nobody counted: it carries **`ACT 0x0D` ×4, `ACT 0x0E` ×4 AND
`ACT 0x1A` ×1** — the only image to carry all three — it is the best-attested image
on the chip (42 slots), and its mathematics is the sharpest possible reference. Its
coefficients include **8388291 / 2²³ = 0.99999**, a unity gain. A pass-through must
emit at **lag 0**; a machine that routes the signal through the delay line cannot.

### 8.1 ⛔ Refuted as a context — the line is never written

```
   act0d x act0e (25 readings) x 261 entry states x 32 start pointers
      = 208 800 configurations

   configurations that get the input into NO OPERATION's delay line:  0
```

★ **And this zero counts, because the positive control passes.** The same harness,
the same enumeration, delivers signal for SINGLE DELAY in 1 024–7 680
configurations. An instrument that demonstrably writes one program's line writes
none of `NO OPERATION`'s. **This is not the "five instruments that could not
measure" pattern — the control both can and does fire.**

### 8.2 ★ But the zero is evidence for something else

[`bit11-family.md`](bit11-family.md) item G established by **byte comparison** that
twelve named effects ship a program identical to `NO OPERATION`. §8.1 establishes by
**execution** that that program never writes its delay line.

**Two independent routes, one conclusion:** those twelve effects do nothing. The
first compared bytes; the second ran the program. That materially strengthens the
hardware prediction in `bit11-family.md` §4.2 — *select `SLOW ATTACKER` on a real
KN5000 and it should be indistinguishable from no effect.*

### 8.3 ★ And a free calibration of the whole project — 100.000 ms

`NO OPERATION`'s descriptors allocate:

```
   write 4510 / read  100  ->  D = 4410  =  100.000 ms
   write 9021 / read 4610  ->  D = 4411  =  100.023 ms
```

★ **4410 samples is exactly 0.1 s at 44 100 Hz.** A round number that falls out of
raw descriptor arithmetic is a designed value, and it **confirms the 44.1 kHz sample
rate from ROM data alone** — a constant this project has assumed throughout and had
never derived.

### 8.4 What survives of the idea

The **lag observable is still sound** — §5.5's invariance argument applies to
amplitude and not to it. What §8.1 shows is that `NO OPERATION` cannot host it,
because its signal never reaches an observable at all. The idea needs a program in
which the undecoded readings can *select between two paths of different length*.
Whether such a program exists in the corpus is **OPEN**, and it is a well-posed
question the census in §6 did not ask.

### 8.5 Predict-then-check

- **P7 MISS.** I predicted `NO OPERATION` would be a fourth known-mathematics
  context. It is not one: 0 of 208 800.
- **P8 unforeseen.** I did not expect the refutation to corroborate the twelve-stub
  finding by an independent route, nor to hand back the sample rate.
- ★ **The census in §6 is unchanged.** `NO OPERATION` does not become a fourth
  context, so *all three* remains *all three*.

---

## 9. The corpus-wide decidability census — and it relocates the bottleneck

§8.4 left one well-posed question: does *any* program let the undecoded readings
select between paths of different length? §6 answered "which contexts have known
mathematics"; this asks something weaker and far more useful.

★ **Decidability does not require known mathematics.** A program discriminates the
readings if different readings produce **different observable behaviour** — whether
or not we know which behaviour is correct. That is a *necessary* condition for any
future test, it is cheap, and it had never been swept.

### 9.1 The instrument, and the calibration that first refuted it

Signature = every delay-DRAM write bus value plus both send cells, over 60 frames,
hashed; run all **25** `act0d × act0e` readings per image and count distinct
signatures.

⛔ **Version 1 reported "1 signature" for all 38 images — including SINGLE DELAY,
which is KNOWN to give 2.** Instrument refuted on the spot, before any conclusion:
it fixed `p0 = 0`, and SINGLE DELAY only delivers at `p0 = 0x08`. **SINGLE DELAY's
known outcome count is the built-in calibration**, and version 2 locates delivery
per image before measuring. Version 2 reports SINGLE DELAY = **2**. Instrument
valid.

### 9.2 The result

```
   images that DELIVER an input to their delay line ...........   3 of 38
      algo  9  SINGLE DELAY     (incell 0x00, p0 0x05)   2 signatures
      algo 72  PEQ+S.DELAY      (incell 0x00, p0 0x05)   2 signatures
      algo 16  ROOM REVERB 1    (incell 0x00, p0 0xB4)   1 signature

   images with NO DELIVERY .................................... 35 of 38
   ★ images producing MORE THAN 2 distinct signatures ..........  0
```

**No discriminator exists among the images that can be fed**, and the "2" in both
delay programs is the generic *does-the-register-chain-survive* split already
identified in §5.3 — not a semantic distinction.

### 9.3 ★★★ But the headline is the other column — 35 of 38

**Thirty-five of the thirty-eight images cannot be fed at all.** The body has no
input; the audio arrives through the shared 60-word kernel — a fact on file as
**FORCED** since 2026-07-26 and the reason the reverb resisted every pass. A search
that drives one body cell is structurally unable to feed them.

★ **So the census is CONCLUSIVE for the 3 feedable images and BLOCKED for the other
35 by a single known cause.** And that cause is the same one every line of this
investigation has hit from a different direction:

* the reverb produced silence for its entire history — no input;
* `NO OPERATION` delivers 0 of 208 800 — no input;
* 35 of 38 images here — no input.

⛔ **The bottleneck is not the ACTION codes. It is that most programs cannot be fed.**
Every attempt to decide `0x0D`/`0x0E`/`0x1A` has been blocked upstream by the same
missing piece, and treating the codes as the obstacle has been a misdiagnosis.

### 9.4 What that reprioritises

1. ★★ **Solve the kernel input path and 35 programs become testable at once.** This
   is a far larger lever than any individual opcode, and it is partly solved
   already: the reverb work identified unit 1's input mix as
   `0.25 × mem[0x0E] + 0.50 × mem[0x8F] + 0.50 × mem[0x8C]`. What is missing is the
   **unit-0 equivalent** and a harness that drives the kernel rather than a body
   cell.
2. Only after that does a discriminator census mean anything — §9.2's "0 of 3" is a
   real answer over a sample of three, and three is not a corpus.
3. ⛔ Do not spend further effort attacking the codes directly while 92 % of the
   corpus cannot be given a signal.

### 9.5 Predict-then-check

- **P9 MISS.** I predicted some program would let the readings select between paths
  of different length. None of the three feedable ones does.
- **P10 HIT, and it is the one that mattered.** I built SINGLE DELAY's known outcome
  count into the instrument as a calibration *before* running it — and it caught
  version 1 immediately. **First time this session an instrument was refuted by a
  control designed in from the start rather than added after a suspicious result.**
- **P11 unforeseen.** The census's most valuable column was the one I was not
  looking at.
