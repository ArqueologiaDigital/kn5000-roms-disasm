# BLOCK A's defect is in a FORCED parameter — and the tempB path has now failed twice, on the same boundary

NEC **uPD6383GF-3BA** (Technics SX-KN5000, IC311). Date: **2026-07-27**.
No hardware. Static analysis and differential dataflow only — **no impulse, no
injection point, no reference response, no adopted reading.**

**Why this note exists.** Three passes established that the reverb's BLOCK A
carries the delayed sample from the DRAM port into the accumulator **entirely
through anchored semantics**, then discards it before the multiply — so the
defect cannot be explained by any undecoded code
([`speculative-carryback.md`](speculative-carryback.md) §6.4). This note asks
which *decoded* parameter is wrong.

Labels: **MEASURED** / **PROVEN BY CONSTRUCTION** / **FORCED** / **FALSIFIED** /
**OPEN**.

---

## 0. Result

| # | statement | label |
|---|---|---|
| **A** | ★★★ **NOT ONE of the 54 machines over BLOCK A's decoded-but-not-forced parameters delivers the delayed sample to its multiply.** `order` (3) × `act00` (6) × `act19` (3), each currently CONSISTENT or shipping on a withdrawn forcing. **0 of 54.** | **MEASURED** |
| **B** | ★★ **And the software pipeline does not rescue it.** The loop is pipelined (`wtrail = 2`), so the sample could legitimately be multiplied a block or two later. Re-run over 1, 2, 3 and 4 consecutive BLOCK A instances: **0 of 54 at every window.** | **MEASURED** |
| **C** | ★★★ **Therefore the defect is in something currently FORCED.** Every step of the delivery chain is anchored, every non-forced parameter has been enumerated, and the sample still never arrives. | **FORCED** (by elimination over the printed space) |
| **D** | ★★★ **AND THE STRUCTURE NAMES THE SUSPECT.** The sample is captured into **tempB** by `ACT 0x14` at `.0`; the multiply at `.5` sources **`SRC 0x19` = tempA**. Swap which register the two temp source codes read and **36 of 54** machines deliver the sample — the block becomes a filter stage. | **MEASURED** |
| **E** | ⛔ **But the biquad forbids the swap: 59.339 dB against 0.198.** It uses both codes, so it can test this — and it says no. The swap as a *global* rule is **FALSIFIED**. | **MEASURED** |
| **F** | ★★★ **THE TEMPB PATH HAS NOW FAILED TWICE, INDEPENDENTLY, ON THE SAME BOUNDARY.** [`blocking-read.md`](blocking-read.md) item H: the reverb comb FORCES `tbsh = 0` (no shift on tempB) while **the biquad FORCES a `>>1` on the tempB path** — 77 dB without it. That was published, MEASURED and left OPEN. This note adds a second, independent disagreement about the *same register*: which code reads it. **Both are reverb-versus-biquad, i.e. unit 1 versus unit 0.** | **MEASURED** |

---

## 1. The solve, and why its window is honest

The differential test: run BLOCK A twice with two different values in the
delay-read register, everything else identical, and ask whether the value
reaching the multiply differs. No impulse, no injection point, no reference —
so none of the three failure modes that killed the previous attempts applies.

```
  machines tried                                  : 54
  in which the delayed sample reaches the multiply:  0
```

My first version of this test used a one-block window, which **assumes the
sample must be consumed in the block that reads it** — false for a
software-pipelined loop, and exactly the "wrong window" error this project has
hit before. Widened:

```
  1 block   w019..w026    0 of 54
  2 blocks  w019..w034    0 of 54
  3 blocks  w019..w042    0 of 54
  4 blocks  w019..w050    0 of 54
```

The pipeline does not rescue it. The conclusion survives the correction.

## 2. The swap: what BLOCK A needs, and what the biquad forbids

| | delivers the sample | biquad |
|---|---|---|
| `SRC 0x19`/`0x1A` as published | **0 of 54** | 0.198 dB ✓ |
| `SRC 0x19`/`0x1A` swapped | **36 of 54** | **59.339 dB** ✗ |

The swap is precisely what the reverb requires and precisely what the biquad
rejects. As a global rule it is dead.

## 3. ★ The convergence, which is the real result

This is the **second** independent way the reverb and the biquad disagree about
the **tempB path**:

| disagreement | reverb says | biquad says | status |
|---|---|---|---|
| the tempB `>>1` (`blocking-read.md` H) | `tbsh = 0`, no shift | a `>>1` is required, 77 dB without | published, OPEN |
| which register the temp codes read (this note) | swapped, or the block cannot filter | unswapped, 59 dB | new |

Two measurements, taken years apart in project time by different methods, both
saying *the reverb's tempB path is not the biquad's*. And the boundary is the
same in both: **the reverb is a unit-1 program and the biquad is unit-0.**

### 3.1 What that does and does not license

[`k4-cursor.md`](k4-cursor.md) establishes per-unit banking **of the C-RAM
coefficient space** — unit-0 at `0x00..0x4F`, unit-1 at `0x90..0xB5`, forced,
12/12 and 79/79. It says **nothing** about the temporary registers, and this note
does not claim it does.

What the convergence licenses is a **hypothesis with two independent supporting
observations instead of one**: *the tempB path is per-unit*. That is a claim
about a **decoded, forced** parameter, which is exactly where item C says the
defect must be — and unlike the readings the speculative passes produced, it is
not invented to fit a single block.

### 3.2 And the trap to avoid

A per-unit reading is **invisible to the biquad by construction**, because the
biquad is unit-0. That is the same structure as the class-dependent `ACT 0x15`
reading this project dropped two passes ago, and it must not be waved through on
the strength of making the reverb work.

**The difference that matters:** the `>>1` tension is *already measured on both
sides* — the reverb forces one value, the biquad forces the other, both
published. That is a genuine cross-block contradiction, not a hypothesis fitted
to one block. Any per-unit reading must be tested against **both** halves, and
the discriminator has to be a unit-1 program with independently known
arithmetic, of which this project currently has **none**.

## 4. Predict-then-check

- **P1 HIT, and it was the branch I said was more interesting.** I predicted
  before running that the failure branch — no machine works — would be the
  bigger result. 0 of 54.
- **P2 MISS, caught by myself.** My first window was one block, which assumes
  away the pipeline. Widening changed nothing, but the test was invalid as first
  written and is reported that way.
- **P3 HIT.** I predicted the structure would name a specific forced parameter
  rather than leaving "something is wrong". It named the temp source codes.
- **P4 unforeseen.** I did not expect the swap to collide with an *already
  published* tension about the same register. That convergence is worth more
  than either measurement alone.

## 5. What the next pass needs

1. ★ **Treat the two tempB disagreements as one problem.** They are the same
   register and the same unit boundary. Solving them separately has failed
   twice.
2. **Find a unit-1 program with independently known arithmetic** — the project
   has none, and without one no per-unit hypothesis can ever be refuted. The
   host's parameter names are the most promising route, as they have been for
   five rounds.
3. **Do not apply anything here.** Every result is a measurement about the model,
   not about the chip, and the one reading that makes the reverb work is
   refuted by the biquad at 59 dB.

---

## 6. The joint tempB solve — exhaustively empty, and that kills a premise

§5 said to stop treating the two tempB disagreements as separate open items.
Done: enumerate the whole temp-register file as one space — **which register each
of the four capture codes (`ACT 0x13/0x14/0x19/0x1A`) writes, which register each
of the two source codes (`SRC 0x19/0x1A`) reads, over THREE temporaries**, with
and without the `>>1`. Three, not two, because
[`adjudication-round8.md`](adjudication-round8.md) withdrew *"`0x13` and `0x19`
are one operation in two encodings"* as shipped-without-evidence, so a second
register pair is admissible.

```
  machines enumerated                      : 1458
  make BLOCK A deliver its delayed sample  :  324
  ...of those, ALSO satisfy the biquad     :    0
```

**No assignment satisfies both.** 324 machines make the block a filter; the
biquad rejects every one.

### 6.1 So one of the two premises is wrong, and it is not the biquad

| premise | standing |
|---|---|
| the biquad's semantics (0.198 dB against the firmware's own designer, able to reject wrong models by 51–999 dB) | the best-established fact on this chip |
| **BLOCK A's multiply consumes the delayed sample** | an assumption I introduced, never tested |

The second is mine. It came from *"a filter stage cannot load its delay-line
sample and discard it"* — which is true of a filter stage, and simply assumes
BLOCK A is one.

★ **The exhaustive zero says it is not.** Whatever BLOCK A computes, the sample
it reads is not what its multiply scales.

### 6.2 What that opens

The write word at `.0` carries **`SRC 0x0B` — the delay-read register**. Under
`wdata = bus` that word is *an unmultiplied line-to-line copy*
([`dram-datapath.md`](dram-datapath.md) recorded exactly this), which needs no
multiply at all: BLOCK A would be **a tap-and-copy stage**, moving one delay line
into the next while the multiply taps it into a separate accumulator sum. That is
a perfectly ordinary reverb-diffusion structure, and it makes the "defect"
disappear because there was never a requirement to violate.

**But it does not resolve cleanly either**, and the dilemma should be stated:
under `wdata = bus` the input never reaches the delay lines at all (the write
takes the read register, not the accumulator, so nothing injects), while under
`wdata = acc` the input enters — and the ladder is then a filter that cannot
work. **Neither reading of `wdata` yields a functioning reverb.** That is the
next thing to break, and it is a sharper question than the one this pass started
with.

### 6.3 Method note

This is the fourth time in this sequence that an exhaustive zero has been more
informative than a survivor would have been, and the third time the thing it
killed was **my own framing** rather than a published claim. The framing was
never labelled — it entered as "a filter stage cannot do that", which sounds like
a fact about filters and is actually an assumption about this block.

---

## 7. The `wdata` dilemma — RESOLVED, and it removes a free parameter

§6.2 posed it as a dilemma: `wdata = bus` and the input never reaches the delay
lines, `wdata = acc` and the ladder is a filter that cannot work.

**It is a false dilemma, and `topology.py` had already said why:** *"`wdata`
should be a per-word decode, not a global switch."* Every delay-write word in the
reverb, with what its own operand bus carries:

```
  w011 w019 w027 w035 w043 w051 w059 w069 w077 w085 w093 w101
        SRC 0x0B  -> the delay-read register   = a LINE-TO-LINE COPY   (12 words)

  w131  SRC 0x10  -> THE ACCUMULATOR           = INJECTION of the ALU result
                     -> address 45103, the write end of L11 (D = 360)
```

★ **There is no global choice to make.** Take `wdata = bus` universally — a write
stores the word's own operand bus — and the **`SRC` field, which is anchored,
decides per word** what that bus is. Twelve words copy line-to-line; one word,
the **last of the program**, injects the accumulated result into the delay
network. Both behaviours coexist because the words ask for different sources.

**`wdata` should be removed from the model as a free parameter.** It was never a
parameter; it was the `SRC` field, already decoded, read as though it were a
global mode.

### 7.1 And it retires two things

- The `wdata = bus` versus `acc` enumeration in every future search — one fewer
  dimension, and one fewer place for a control to be blind. Recall that the
  harness *default* of `bus` was what made an ALU search unable to fail
  ([`act0b-reverb.md`](act0b-reverb.md) item C): under the per-word reading that
  hazard disappears, because a write word sourcing `SRC 0x10` is visible to the
  ALU by construction.
- `dram-datapath.md` item J's *"the write-data source is still OPEN"* — it is
  not open; it is per-word and already anchored.

### 7.2 What it does NOT do, stated plainly

**The reverb still does not work.** Traced at frame 0, the accumulator is **zero
through the entire tail**, so `w131` injects zero and nothing ever enters the
delay network:

```
  w126..w130  four class-A multiplies, all with P = 0
  w131        the injector, acc = 0
```

The cause is upstream and already known: the input enters at `w002` and is
destroyed at `w006` by an `f31 = 0` word (`acc ← P`, `P` zero). The ALU chain in
the **head** does not carry the input to the tail.

So the dilemma resolves into a **relocation**: the question is no longer "which
`wdata`" but "why does the head not deliver the input to the accumulator". That
is the same `f31 = 0` barrier that has now appeared in four separate
investigations — the biquad's blindness to upstream state
([`f31-high.md`](f31-high.md) item E), the destruction of the delayed sample in
BLOCK A (§1), the input dying at `w006`, and now the tail.

★ **Four independent failures, one mechanism.** `acc ← P` with a stale or zero
`P` is where this program keeps losing its signal, and the next pass should
attack that rather than any individual code.

---

## 8. `acc ← P` — the mechanism is CORRECT, and my framing of it was wrong

§7.2 ended by naming `acc ← P` as one mechanism behind four failures and saying
to attack it. Attacked, and **it is right**.

### 8.1 The biquad genuinely tests it

`f31 = 0` appears in the biquad at words `[0]` and `[8]`, so it is not assumed
there — it is exercised:

| `f31 = 0` read as | designer error |
|---|---|
| `acc ← P` — **discards the accumulator** (shipped) | **0.198 dB** accepted |
| `acc ← acc + P` — does not discard | 10.716 dB REJECTED |
| `acc ← acc` — ignores the product | 17.363 dB REJECTED |

★ **So the signal loss is BY DESIGN.** `acc ← P` is how a multiply-accumulate
unit *starts a fresh accumulation chain*, and a chain boundary is supposed to
discard what came before. **My "four failures, one mechanism" was the wrong
diagnosis** — the mechanism is correct and the error was my expectation that
signal should cross a boundary built to reset.

### 8.2 Which relocates the state, correctly this time

If the accumulator resets by design, whatever survives between chains lives
elsewhere. It lives in **D-RAM**:

```
  reverb D-RAM cells:  15 touched,  9 written AND read   (a real round trip)
  loaded but NEVER stored by the program : 0x80, 0x87, 0x8A
```

Cross-checked against the host's canned image for algo 16
(`register_space.py cells`): the host primes `85 86 87 8A 8B 94 D0 D1 D2`, all
zero. So `0x87` and `0x8A` are host-primed — and **`0x80` is not written by the
host either.**

### ★★★ 8.3 Cell `0x80` is the inter-unit signal path, and it explains everything

```
  algorithms that WRITE D-RAM cell 0x80 : 18   -- ALL of them unit-0 bodies
  algorithms that READ  it              : 91   -- including all 12 unit-1 reverbs
```

**Unit 0 processes, stores its result to `0x80`, and unit 1 — the reverb — reads
it in the same frame.** That is the send path between the two effect units, and
it is derived from the pointer walk and the anchored store/load codes alone.

> ⚠ **AND EVERY REVERB SIMULATION THIS PROJECT HAS RUN EXECUTED THE REVERB IMAGE
> ALONE.** Cell `0x80` was therefore zero in all of them. **The reverb has been
> simulated with no input, in every pass, for the entire investigation.**

That is a systematic defect in the methodology, not in the model — and it is
established rigorously, with no adopted reading.

### 8.4 What it does not yet fix

Injecting an impulse directly into cell `0x80` does **not** bring the reverb to
life either (0 delay addresses carry signal, against 2 for the old injection
point). So the input path is more than one cell write — the unit-0 body must be
*running*, with its own pointer walk and its own chain of stores, and a single
poked value does not stand in for it.

**The next experiment is therefore concrete and different in kind from anything
tried so far: run a unit-0 body and the reverb together, as the frame does**,
rather than the reverb in isolation. Every reverb result in this project's
history was measured without the one thing that feeds it.

---

## 9. Running the units together — the premise was wrong, and §8.3 needs correcting

### ⛔ 9.1 Correction: "cell `0x80` is the inter-unit signal path" was an artefact

§8.3 computed the D-RAM census with the **same start pointer (`0x80`) for both
units**. The per-unit body entries are **`0x05` and `0x85`**
([`output-stage-decode.md`](output-stage-decode.md), 85 of 85 streams). Redone
properly:

| entry pointers | cells written by a unit-0 body AND read by a unit-1 body |
|---|---|
| both `0x80` (what §8.3 used) | 11, headed by `0x80` — **artefact** |
| `0x05` / `0x85` (derived) | **3** — `0x0E` (69 unit-0 writers), `0x89` (2), `0x8B` (1) |

**`0x80` is not the inter-unit path.** It was an artefact of walking both units
from the same origin. Withdrawn.

### ★ 9.2 But the entry pointer itself is now confirmed, from a new direction

Sweeping all 256 candidate entry pointers against the host's canned D-RAM image
for algo 16 (`85 86 87 8A 8B 94 D0 D1 D2`):

```
  best entry pointer: 0x85, covering 8 of 9 host-primed cells
```

★ **`p0 = 0x85` wins outright**, and it is exactly the unit-1 entry
`output-stage-decode.md` derived from the host's *zero-fill* — confirmed here by
the host's *parameter writes*, a different mechanism entirely. Two independent
routes to the same origin.

### 9.3 And the corrected read-never-written set names the input

At `p0 = 0x85` the reverb loads but never stores: **`0x85`, `0x8C`, `0x8F`**.
`0x85` is host-primed. The other two are not — and
[`host-side.md`](host-side.md) has them as *"unreachable from the host by any
path"*, two of R2's three unexplained registers.

[`closure-pointer.md`](closure-pointer.md) already settled what they are:

> The two audio input latches sit at **fixed chip addresses** … the unit-1 image
> touches **both latches** at the cold-boot entry.

★ **So the reverb's input is a HARDWARE INPUT LATCH, not a unit-0 body writing
D-RAM.** The premise of this experiment — "run a unit-0 body and the reverb
together" — was wrong, and the project already knew where the input comes from;
it had simply never been connected to the reverb's own read set.

### 9.4 What still does not work

Injecting at `0x8C`, at `0x8F`, at both, or at `0x85`, with the confirmed entry
pointer, still yields **no recirculation** — 2 delay addresses at frame 0 and
nothing after. So the input latch is necessary and not sufficient; something
further along the chain still fails.

**What survives §8 intact:** the accumulator resets by design and the state lives
in D-RAM (§8.1, §8.2), and **every reverb simulation this project has run has had
its input at zero** (§8.3's headline, which does not depend on *which* cell the
input arrives in). That remains a systematic defect in the methodology.

**What is withdrawn:** `0x80` as the inter-unit path, and the plan to run a
unit-0 body alongside the reverb as the fix.

---

## 10. Re-reading the closure and input-stage work — the simulations were never capable of this

Two notes hold the answer, and I had not connected them to the reverb work.

### 10.1 The input enters through the KERNEL, not the body

[`closure-pointer.md`](closure-pointer.md) §2.1:

> The two audio input latches sit at **fixed chip addresses**: the serial
> receivers write them, no instruction does, and **the kernel reads them at
> `ptr+2` and `ptr+5` in its first twelve words**. The kernel is *shared* — the
> same 60 words run for every effect.

**Every reverb simulation in this project has run the 133-word body alone.** The
60-word kernel — the only thing that reads the audio input — has never been in
any of them. That is the systematic defect §8.3 was groping at, stated exactly.

### 10.2 And hand-injecting D-RAM is not a substitute

`kn7000_mame/notes/dsp-k6-input-stage.md` finding **7** (FORCED + MEASURED,
over-determined 37×):

> the input stage does **not** hand cells to the bodies. It hands the
> **accumulator** to the header's mix block, which deposits the per-unit send
> with `w45` (unit 0) / `w53` (unit 1) at exactly **the cell the body reads
> first**.

So the value the body sees is *computed by the kernel's mix block* — it is not a
raw sample poked into a cell. Injection at any single cell reproduces neither the
value nor the timing. Tested anyway, across the ±3 window around the confirmed
entry pointer `0x85`, to see whether finding **8**'s open 2-cell discrepancy
could be chosen functionally:

```
   inject 0x82..0x88 (entry ±3) : 0 delay addresses alive at every offset
                                  except +3, which gives 2 at frame 1
```

**It cannot.** The discrepancy stays OPEN, and injection is the wrong instrument
for it.

### ★★ 10.3 And the kernel cannot be run either — its coefficients are unknown

K6 finding **12** (MEASURED):

> the header's own 23-slot bank is **not written anywhere in the cold-boot
> capture**, so **the four input-stage coefficients are UNKNOWN values**.

★ **That closes the loop, and it is the real answer to "why has the reverb never
produced audio in simulation".** Not a decode gap, not a wrong reading:

> **The signal cannot be computed at all, because the numbers that scale it on
> entry have never been observed.** They are not in the ROM's canned parameter
> streams and not in the cold-boot capture.

Everything downstream — the ladder, `ACT 0x0B`, the topology, BLOCK A — has been
investigated on a machine whose input stage is missing four unknown constants.

### 10.4 What this reframes

- **The reverb was never simulable**, and no amount of ALU decoding would have
  made it so. Four rounds of topology search were run on a program with no input.
- **The blocker is a DATA gap, not a decode gap** — a different kind of problem,
  and one the host firmware may still answer: the four coefficients must be
  written by *some* path the captures did not cover (a different preset, a
  parameter change at run time, a second capture).
- **`closure-pointer.md` finding 9 is the one testable thing here**: a closed,
  origin-free loop — `iw0` writes `X+0`, the epilogue reads `X+0` the same frame,
  the epilogue writes `X+1` and `iw2` reads it the *next* frame — *"the dry path
  plus a one-sample feedback"*, FORCED by the pointer rule alone. That loop needs
  no unknown coefficient to trace, and it is the only part of the audio path that
  can be checked today.

### 10.5 Method note, and it is the lesson of the whole session

Two consecutive passes produced headline claims that were artefacts of my own
setup, and **both were resolved by reading notes this project had already
written** rather than by running anything. The input-stage answer has been on
file since 2026-07-26 with the status **FORCED**. I ran perhaps a dozen
simulations that could not have worked, when twenty minutes of reading would have
said so.
