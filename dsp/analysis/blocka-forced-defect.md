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

---

## 11. How to feed the reverb — the input mix, DECODED

Felipe: *"what can we do to feed input (even if fabricated) into the reverb so
that it can be tested?"* The standing rule
([[fake-with-the-real-mechanism]]) says route the fake through the **correct
datapath**, so the first job was to find where that datapath actually is.

### ★★ 11.1 The reverb's input mix is three named multiplies

Tracing the body's first six words with the entry pointer confirmed at `0x85`:

```
  w002  class-A  x 0.25  <- mem[0x0E]
  w003  class-A  x 0.50  <- mem[0x8F]
  w004  class-A  x 0.50  <- mem[0x8C]
```

Three class-A multiplies with **coefficients read from the ROM**, sourcing the
three cells the program reads and never writes. And each one is independently
identified:

| cell | what it is | evidence |
|---|---|---|
| `0x0E` | **the unit-0 send** | 69 of 79 unit-0 bodies write it; all 12 reverbs read it (§9.1's corrected cross-tab) |
| `0x8C`, `0x8F` | **the two hardware audio latches** | unreachable from the host by any path ([`host-side.md`](host-side.md)); two of R2's three unexplained registers; K6's "two audio input latches", which the unit-1 image touches at cold-boot entry |

★ **So the reverb's input is `0.25 × (unit-0 send) + 0.5 × latch + 0.5 × latch`,
and every term is decoded.** That is the faithful interface, and it is the thing
to drive.

### 11.2 The recipe

To test the reverb, write the audio into **`mem[0x0E]`, `mem[0x8C]`, `mem[0x8F]`
each frame**, with the body entry pointer at `0x85`. The mechanism is the real
one — those are the cells the program's own input-mix multiplies read, at the
gains the ROM specifies. Only the *values* are fabricated, and they are
drop-in-replaceable the moment a capture supplies the real ones.

This supersedes every injection point used in this project's history: `0x09`
(arbitrary), `0x80` (an artefact of the wrong entry pointer), and `0x85` (the
send-cell guess, which the body reads at `w005` but does **not** multiply).

### 11.3 And it is still not sufficient — stated plainly

Driving all three cells yields **2 delay addresses at frame 0 and no
recirculation**, the same as driving one. So the missing input was never the only
blocker:

- **9 of the 133 reverb words still trap** (`ACT 0x0D`, `0x0E`, `0x1A`), and the
  runs above use *speculative* readings for them — §5's verdict stands, those
  readings are unfalsifiable and must not be trusted.
- The signal path beyond the input mix still fails, for reasons §6 showed are in
  decoded semantics rather than undecoded codes.

**What changed is the quality of the question.** "How do we feed the reverb" is
answered, with a decoded three-term mix and named cells. "Why does the signal die
after the mix" is now the whole remaining problem, and it no longer has an input
gap hiding inside it.

---

## 12. Why the signal dies after the input mix — located to one word

Driving the three input cells §11 identified, the signal **enters for the first
time in this project's history**:

```
  w002  x0.25 <- mem[0x0E]   P = 262144
  w003  x0.50 <- mem[0x8F]   P = 524288   acc =  262144
  w004  x0.50 <- mem[0x8C]                acc =  786432
  w005                                    acc = 1310720
  ...
  w018                                    acc =  121324   still alive
```

### ★★ 12.1 It dies at `w020`, on `ACT 0x00 = load`

```
  w019  0B 14  f31=0   acc = 121324
  w020  00 00  f31=2   acc =       0     <<< SRC 0x00, ACT 0x00
```

`w020` is `SRC 0x00, ACT 0x00, f31 = 2`. Under `f31 = 2` the product term is
suppressed and the accumulator would simply hold — **except that `ACT 0x00 =
load` replaces the accumulator's feedback term with the bus**, and the bus there
is `mem[ptr]`, an empty cell. The mixed input is overwritten with zero.

★ **And `act00 = load` is exactly the parameter
[`action00-discriminator.md`](action00-discriminator.md) demoted**: the "18/18
FORCED" was **one** context, not three, and `load` survives only as a plurality
(15 of 33), *"the only reading compatible with all five gates — why it still
ships"*. It is CONSISTENT, never forced.

### 12.2 And a second, structural leak at `w019`

`w019` — the head's first delay-line write — carries **`SRC 0x0B`**, the
delay-read register. Under the per-word write rule established in §7 it therefore
stores *the read register*, which is empty, **not the accumulator that holds the
mixed input**. Of the reverb's thirteen delay writes only `w131` sources the
accumulator, and by then the accumulator is zero.

So the mixed input has **no route into the delay network at the head at all** —
it must survive the entire 133-word body to reach `w131`, and `w020` destroys it
at the twentieth word.

### 12.3 Testing every `act00` reading

| `act00` | delay addresses alive | recirculates |
|---|---|---|
| `load` (ships) | 2 | no |
| `add`, `sub`, `rload`, `bsel` | **4** | no |
| `none` | 0 | no |

The four alternatives all get the signal **twice as far** as `load` does — which
is consistent with `load` being the specific thing that erases it — but **none
recirculates**. So `act00` is *a* cause and not the only one.

### 12.4 Status

**Answered:** the signal dies at `w020`, on a CONSISTENT-only reading of
`ACT 0x00`, with a second structural leak at `w019` where the head's delay write
cannot carry the accumulator.

**Not answered:** what else kills it, since fixing `act00` doubles the reach and
still yields no tail. And these runs still carry speculative readings for the
nine trapping words (§5), so the residue cannot yet be attributed cleanly.

★ **The through-line of this whole sequence is now visible.** Every failure has
been the accumulator being overwritten before its value is used — at `w006`
(§8), at `.4` in BLOCK A (§1), and now at `w020`. In each case the overwriting
word is `f31 = 0` or `ACT 0x00 = load`. The first is FORCED and correct (§8.1).
**The second is not forced, and it is the one that keeps appearing at the exact
point the signal is lost.**

---

## 13. `ACT 0x00` settled against the LFO — down to three

> ## ⛔ CORRECTION (same day) — §13 AS FIRST WRITTEN WAS WRONG
>
> I reported *"the LFO refutes three of six"* and an intersection of
> `{add, rload}`. **`bsel` is not refuted.** My search fixed `src08` at its
> default `unity` instead of enumerating it — **method rule 2, violated in the
> pass whose subject was settling a parameter.** With `src08` enumerated `bsel`
> survives (3 in my reduced run; **72** in the published `sec_publish`, which
> also enumerates `src11` and `dest07`).
>
> | | as first written | corrected |
> |---|---|---|
> | LFO refutes | `none`, `sub`, **`bsel`** | `none`, `sub` — **two of six** |
> | LFO admits | `add`, `load`, `rload` | `add`, `load`, `rload`, **`bsel`** |
> | intersection with the reverb | `{add, rload}` | **`{add, rload, bsel}`** |
>
> The published tool's own `lfo` section had the right answer on file
> (`act00 4 values load x1440 add x1080 rload x720 bsel x72`) and I did not check
> against it before writing the section. Everything below is corrected; the
> conclusion is weakened, not reversed — **`load` still ships and is still the
> reading the reverb's signal path disfavours.**

The LFO ramp is the **only known-mathematics context on this chip that carries an
`ACTION 0x00` word** — PARAMETRIC EQ has none at all, so the biquad is blind to
this parameter by construction. Run over the full published space (3888 machines:
`order × act00 × sttime × stgate × op2 × wrap`), scored against all **29** LFO
blocks at 30 frames, with `is_ramp` as the criterion:

```
  stage 1 (6 blocks, 12 frames)  : 540 survive
  stage 2 (ALL 29 blocks, 30 fr) : 540 survive
```

| `act00` | LFO survivors | reverb: delay addresses reached |
|---|---|---|
| `none` | **0 — REFUTED** | 0 |
| `add` | 180 | **4** |
| `sub` | **0 — REFUTED** | 4 |
| **`load`** *(ships)* | 240 | **2** |
| `rload` | 120 | **4** |
| `bsel` | **0 — REFUTED** | 4 |

★ **The LFO refutes two of the six** — `none` and `sub` cannot produce the ramp
under any setting. `bsel` **does** survive once `src08` is enumerated (the table
above under-enumerated it; see the correction banner). The admitted set is
`{add, load, rload, bsel}`, matching
[`action00-discriminator.md`](action00-discriminator.md) and the published
`sec_publish` counts exactly.

### ★★ 13.1 The intersection is `{add, rload}`

Cross the LFO's three against §12's functional result — which readings let the
reverb carry its mixed input past `w020`:

- `sub` passes signal but the **LFO refutes it**.
- `bsel` passes signal **and** the LFO admits it — so it is in, not out. (It was
  refuted in SINGLE DELAY 0/5832, but that context's forcings were withdrawn in
  round 7 when its polarity was corrected, so that refutation needs re-running
  before it can be leaned on.)
- `load` is **LFO-admitted and is precisely the reading that erases the signal**
  at `w020`, reaching half as many delay addresses as the alternatives.
- **`add`, `rload` and `bsel` are admitted by both.**

**`load` is what the device ships.** It is the one member of the LFO's set that
fails the functional test the other two pass.

### 13.2 Stated at its real strength

**The LFO half is solid**: 3888 machines, all 29 blocks, 30 frames, a criterion
(`is_ramp`) that requires an exact arithmetic progression matching a rate the ROM
encodes as `floor(f × 2²³/44100)`. Three values are **refuted**.

**The reverb half is a functional heuristic, not a forcing.** "4 delay addresses
versus 2" is a real, measured asymmetry — and it is the same *can the program
pass signal* criterion that eliminated 30 of 36 combinations earlier — but it is
not a numeric match against known mathematics, and the runs still carry
speculative readings for the nine trapping words. **It ranks the three; it does
not force one.**

So: `ACT 0x00 ∈ {add, load, rload, bsel}` **FORCED by the LFO**, narrowed to
`{add, rload, bsel}` **CONSISTENT-favoured** by the reverb's signal path — and
nothing here distinguishes the three, which the reverb scores identically at 4
delay addresses each.

### 13.3 Not applied, and why that is the right call

`load` continues to ship. Three reasons: the LFO admits it; the reverb's
preference is a heuristic rather than a forcing; and
`action00-discriminator.md` §0-C measured that `act00` is **locked to the store
gate** in all 33 survivors — `add` and `rload` occur *only* under a late-clearing
gate, `load` under any of five. Changing `act00` without settling the gate would
ship one guess to fix another.

★ **The handover is now exact**: `ACT 0x00` and the bit-7 store-gate clear are
**one question** (that note's own headline), the LFO forces the pair to three
possibilities, the reverb's signal path disfavours the shipped one, and the gate
is the half with 130 corpus words behind it. **Settle the gate and `ACT 0x00`
falls out — and if it falls out as anything but `load`, the reverb gains its
signal path at the same moment.**

---

## 14. The joint solve — the gate is invisible, `load` is the outlier, and the signal now reaches `w123`

Testing the **twelve `(act00, gate)` pairs the LFO admits** (taken from
`sec_publish`'s own output, so no re-enumeration error) against the reverb's
signal path, with the input mix of §11 driven:

```
  act00   gate                    acc@w020   addrs
  add     b7_f31_1_clrlate          121324      4
  add     b7_f31_1_keepclear        121324      4
  add     b7_ne2_clrlate            121324      4
  bsel    b7_f31_1_keepclear        121324      4
  load    (all five gates)               0      2
  rload   (all three gates)        -121324      4
```

### ★★ 14.1 The gate is invisible to the reverb

**Every gate gives an identical result for a given `act00`.** The reverb cannot
distinguish `b7_f31_1_clrlate` from `b7_ne2_off` from any of the others — a
decidability fact, and an unwelcome one: the two halves of the "one question" are
**not equally testable here**. The reverb ranks `act00` and says nothing at all
about the gate.

### ★★ 14.2 `load` is the outlier among the four the LFO admits

| `act00` | acc at `w020` | reach |
|---|---|---|
| **`load`** *(ships)* | **0 — destroyed** | dies at word 20 of 133 |
| `add`, `bsel` | `+121324` — survives | **reaches `w123`** |
| `rload` | `−121324` — survives | **reaches `w123`** |

With any of the three alternatives the mixed input travels from `w002` to
**`w123` — 121 of the body's 133 words**, through nine BLOCK A stages with the
accumulator carrying signal the whole way (`121324 → 242648 → 212317 → 181986 →
224752 …`). With `load` it dies at the twentieth word.

★ **That is a six-fold difference in reach between the shipped reading and the
three alternatives the LFO admits equally.** It is still a functional argument,
not a numeric forcing — but it is now a large, clean separation rather than
"4 addresses against 2".

### 14.3 And the last obstruction is eight words from the finish

```
  w118  A  acc = 47758      alive
  w119     acc = 47758
  w120     acc =     0      ACT 0x0E, f31=0 -- dies
  w122     acc = 47758      recovers: ACT 0x00=add re-reads what w120 stored
  w123     acc = 47758      <<< last live word
  w124     acc =     0      SRC 0x10, ACT 0x07, f31=0 -- dies for good
  ...
  w131     acc =     0      <<< THE INJECTOR
```

The signal dies for good at **`w124`**, and the second output tail's four
multiplies (`w126`–`w129`) then read D-RAM cells that are empty. Eight words
short of `w131`, the only word that can inject into the delay network.

### 14.4 Status

- **`ACT 0x00`**: `{add, load, rload, bsel}` FORCED by the LFO; `load` is the
  unique member that destroys the reverb's signal at `w020`. **Not applied** —
  the LFO admits `load`, the reverb's argument is functional, and `act00` is
  coupled to a gate the reverb cannot see.
- **The gate**: unconstrained by the reverb. It needs a different context, and
  `store-gate.md` already priced it at 17 corpus words.
- **`w124`** is the new frontier, and unlike `w020` it is not obviously an
  `ACT 0x00` problem: `SRC 0x10, ACT 0x07, f31 = 0` — a store of the accumulator
  to `mem[ptr]`, with `f31 = 0` reloading the accumulator from a product that is
  zero because the tail's multiplies have not run yet.

---

## 15. `wdata = acc` — the reverb produces structure at last, and a metric of mine fails again

§7 concluded the `wdata` dilemma was false and the write always stores the
word's own bus. Testing it against the corrected input mix says otherwise.

### 15.1 The combination never tried

Input mix of §11, `act00` from §13's LFO-admitted set, both `wdata` readings:

| `wdata` | `act00` | delay addresses | reach |
|---|---|---|---|
| `bus` | any | 2–4 | dies frame 0 |
| `acc` | `load` *(ships)* | 6 | dies frame 0 |
| **`acc`** | **`add`, `rload`, `bsel`** | **17** | signal persists |

★ **17 delay addresses of the reverb's ~22 carry signal**, against 2–6 for every
other combination. And under `wdata = acc` the write word `880.1.60.2D4` does
*both* jobs coherently: it stores the accumulator to the line **and** its
`ACT 0x14` captures the previously-read datum into `tempB`. The `SRC 0x0B` field
serves the ALU capture; it is not the write source.

**So §7's "the dilemma is false, `wdata` is always the bus" is WITHDRAWN.** Under
`bus` the network deadlocks — the ladder writes copy an empty read register and
only `w131` injects, but `w131` needs the tail, which needs the lines.

### ⛔ 15.2 And my success metric was another control that cannot fail

I flagged this as *"★★★ RECIRCULATES — signal alive at frame 7999 of 8000"*. The
metric was **"the last frame with any non-zero delay write"**, and the value
sustaining it is **±4 LSB**. A quantisation residue satisfies it.

The actual impulse response at the output tail:

```
  t=     0     0.0 dB   the impulse
  t=   400   -99.0 dB   nothing
  t=  1355  -54.3 dB  ┐
  t=  1356  -42.1 dB  │ ONE echo cluster, five samples
  t=  1357  -46.5 dB  │
  t=  1358  -53.4 dB  │
  t=  1359  -61.8 dB  ┘
  t=  1600+ -81.5 dB   a CONSTANT floor, +/-4 LSB, forever
```

**Six events above 20 LSB in 3000 frames.** That is an impulse and a single echo,
not a decaying train. **It is not a reverb**, and the "recirculation" was a stuck
residue at the quantisation floor. Thirteenth control-that-cannot-fail on this
chip, and the third of mine in this session.

### 15.3 What is nonetheless true

The machine now produces **structure where it produced nothing**: a delayed echo
at ≈1356 samples at −42 dB, from a program that has never before returned
anything but silence in simulation. And the configuration that does it is exactly
the one **both** independent criteria favour — LFO-admitted `act00`, and the
functional signal-survival test — with `load`, the shipped reading, excluded by
the second.

`t = 1356` is **not** an obvious sum of the known delays (pre-delay 800; ladder
83 172 356 513 739 240 119 247 428 616 360; ER taps 540 650 800), and I am not
going to force an interpretation onto it.

### 15.4 Status

- **`wdata = acc`** — §7 withdrawn; `bus` deadlocks the delay network.
- **`act00 ≠ load`** — now supported by two independent criteria, still not
  applied (the LFO admits `load`; the gate is invisible to the reverb).
- **One echo is not a tank.** Whatever produces a *decaying train* is still
  missing, and the ±4 LSB floor suggests a feedback path that is present but
  attenuated to the quantisation limit rather than absent.
