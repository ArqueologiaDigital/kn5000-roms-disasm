# The LFO ramp as a numeric anchor — two codes DETERMINED, and the model that cannot run them

NEC **uPD6383GF-3BA** (Technics SX-KN5000, IC311). Date: **2026-07-26**.
No hardware. Static analysis, the ROM corpus and constraint solving only.

Reproduce every number below with
[`dsp/tools/lfo_ramp.py`](../tools/lfo_ramp.py) (standard library only, no
emulator, no undumped ROM):

```
python3 dsp/tools/lfo_ramp.py                       # all seven sections
python3 dsp/tools/lfo_ramp.py fields rate solve     # the three that matter
```

Labels: **MEASURED** / **PROVEN BY CONSTRUCTION** / **FORCED** / **DETERMINED** /
**CONSISTENT** / **INFERRED** / **OPEN**.

---

## 0. Result in one page

| # | what | label |
|---|---|---|
| **A** | ★ **THE BRIEF'S TARGET DOES NOT EXIST.** The LFO cannot anchor `SRC = 0x00`, because **no word of the LFO block carries `SRC = 0x00`.** `092.A.00.200` was read as "SRC 00"; the `00` is **`addr8`**, the signed pointer post-increment. `SRC` is `lo12[10:6]` = **`0x08`**. This is a field misreading, and it is in the brief, in `notes/dsp-frame-advance.md` §4 blocker #2, and in this note's own predecessor. | **MEASURED** |
| **B** | What the block *can* anchor is bigger than what it was asked to anchor: **`ACTION = 0x00`** — the single largest blocker in the ranking (820 corpus words, 51 of the 205 undecoded frame slots) — which it carries **three times out of three**. | **MEASURED** |
| **C** | ★ **THE NUMERIC ANCHOR IS NINE-FOLD, NOT ONE-FOLD.** Not one 0.5993 Hz coincidence but **29 LFO blocks in 16 programs**, whose increments take **9 distinct values**, every one of them exactly `floor(f × 2²³ / 44100)` for a round decimal *f* ∈ {0.2, 0.4, 0.6, 1.2, 3.0, 4.0, 5.2, 7.4, **1000.0**} Hz. Round-to-nearest fails at 4 of 9, so the designer **truncated**. Joint null **3.1 × 10⁻¹²**. The wrap coefficient is `0x7FFFFF` at **29/29**. | **MEASURED** |
| **D** | ★ **TWO CODES DETERMINED, from 1920 candidate machines.** Over the five blocks the current model *can* run, exactly **20 of 1920** produce the ramp and all 20 agree: **`SRC 0x08` = a unity multiplicand** (the class-A product is the coefficient itself) and **`ACTION 0x00` = `acc ← bus`**, taken **BEFORE** the `hi12[3:1]` operation. Nothing else in the space works. | **DETERMINED** |
| **E** | ★ **AND THE MODEL THEY WERE DETERMINED FROM CANNOT RUN THEM.** At the other **24 of 29** blocks, **0 of 1920** machines produce the ramp — no assignment of any of the five free parameters. The accumulate word `092.A.dd.200` carries `hi12` bit 4 and sits on the **same D-RAM cell** the next word reads, so under "bit 4 stores the accumulator to `mem[ptr]`" it destroys the phase before the block reads it. **The LFO is not undecoded. It is unrunnable.** | **MEASURED** |
| **F** | The same defect, measured independently and corpus-wide: **216 provably dead stores** in the 38-image body corpus — pairs, triples and six quadruples of consecutive writes to one cell with no read between. Only 27 of 180 chains contain an LFO word, so this is a **general** defect of the memory model, not an LFO peculiarity. | **MEASURED** |
| **G** | The wrap is **not** in the accumulator. `hi12[3:1] == 2` runs *after* the bit-4 store has already written the phase and cleared the accumulator, so it can never reach the value that persists. Of five store-path candidates only two survive, and one of them is falsified by the biquad. The survivor: **the accumulator STORE PATH takes the value modulo the fetched coefficient when `hi12[3:1] == 2`** — which is also exactly why the biquad's class-8 word looks like a no-op (it has no store). | **FORCED** (against the accumulator) / **CONSISTENT** (the store path) |
| **H** | Price, for the ledger: adopting `ACTION 0x00` + `SRC 0x08` + `hi12[3:1] == 2` off class 8 takes the decodable corpus **1029 → 1288** words (**+259**). **It is not adopted.** A pass that has just measured that the datapath cannot run the block it solved must not put 259 more words on that datapath. | **MEASURED** |

---

## 1. ★ The field misreading — reported first, because it is in the brief

`092.A.00.200` renders as `hi12 . class4 . addr8 . lo12`. Spelled out:

```
   word          hi12          class  addr8  lo12   SRC    M   ACTION
   0092A00200    092 (f31=1,ST)  A      +0    200   0x08   0   0x00     phase accumulate
   00822001C0    082 (f31=1   )  2      +0    1C0   0x07   0   0x00     the middle word
   0094A00200    094 (f31=2,ST)  A      +0    200   0x08   0   0x00     the wrap
```

`SRC = lo12[10:6]`, so `0x200 >> 6 = 0x08` and `0x1C0 >> 6 = 0x07`. The three
words carry `SRC` **0x08, 0x07, 0x08** and `ACTION` **0x00, 0x00, 0x00**.
`SRC = 0x00` is not present. It is `addr8` that is zero, and `addr8` is the
pointer post-increment.

**MISS, and it is the brief's own premise.** `notes/dsp-frame-advance.md` §4
blocker #2 proposes "solve for `SRC=0x00`'s value by requiring the LFO words
`092.A.00.200` / `094.A.00.200` to produce that ramp" — that experiment cannot
run. What *can* run is the same experiment for `ACTION 0x00` and `SRC 0x08`, and
that is what this note does. `ACTION 0x00` is the **larger** prize anyway: 820
corpus words and 51 frame slots against `SRC 0x00`'s 622 and 28.

Corpus census (C-format excluded — it has no `lo12` fields of this kind):
`SRC 0x00` **622**, `SRC 0x08` **83**, `ACTION 0x00` **820**.

---

## 2. The anchor, and it is nine-fold

29 LFO blocks, in 16 of the 38 distinct body images. Each is a pair of class-A
words with `lo12 = 0x200` — `hi12 = 0x092` (`f31 = 1`) then `hi12 = 0x094`
(`f31 = 2`) — with `082.2.00.1C0` between them, consuming **two consecutive
C-RAM cells**. The first cell is the per-frame phase increment; the second is
`0x7FFFFF` in **29 of 29**.

| increment | dec | rate at 2²³ | `floor(f·2²³/Fs)`? | `round(...)`? | programs |
|---|---|---|---|---|---|
| `000026` | 38 | 0.1998 Hz | ✔ (f = 0.2) | ✔ | FLANGER ×2 |
| `00004C` | 76 | 0.3995 | ✔ (0.4) | ✔ | PHASER ×2 |
| `000072` | 114 | 0.5993 | ✔ (0.6) | ✔ | 11 sites: CHORUS, ENSEMBLE, MOD CHORUS, 4× S-DELAY, 2× PEQ |
| `0000E4` | 228 | 1.1986 | ✔ (1.2) | ✔ | AUTO PAN ×2 |
| `00023A` | 570 | 2.9966 | ✔ (3.0) | ✘ | MIX UP |
| `0002F8` | 760 | 3.9954 | ✔ (4.0) | ✘ | 6 sites: VIBRATO, S-DELAY VIBRATO, PEQ VIBRATO (×2 each) |
| `0003DD` | 989 | 5.1993 | ✔ (5.2) | ✔ | MODULATED CHORUS, MIX UP |
| `00057F` | 1407 | 7.3968 | ✔ (7.4) | ✘ | MIX UP |
| `02E709` | 190217 | **999.9954** | ✔ (1000.0) | ✘ | RING MODULATOR ×2 |

**MEASURED.** Nine for nine under `floor`, five for nine under `round` — so the
designer's converter truncated, which is itself a fact about the firmware.

**The null.** A 0.1 Hz grid over 0.1 … 1000 Hz reaches 10 000 distinct 24-bit
codes out of 2²⁴ (0.06 %); around each of our nine values exactly **1 of the 19
nearest codes** qualifies, so the per-value null is 1/19 and the joint null is
**3.1 × 10⁻¹²**. The rival explanation "they are all multiples of 38" fits the
four small values and **fails at 989, 1407 and 190217** — 3 of 9.

Two things this buys that the single 0.5993 Hz point did not:

* **The RING MODULATOR is on the same mechanism at 1000 Hz.** The block is not
  an "LFO" — it is the machine's **oscillator**, and it spans four decades on one
  encoding. Anything that explains the block has to work at 190217 as well as at 38.
* **The span is 2²³, not 2²⁴.** Both readings give round frequencies (they differ
  by exactly ×2), so *roundness alone cannot decide it*. What decides it is the
  constant: the firmware supplies `0x7FFFFF`, and `0xFFFFFF` **never appears** in
  the 1770-word coefficient corpus. Corroboration from the other side: at 2²⁴ the
  VIBRATO runs at 2.0 Hz, which is slow for vibrato, and at 2²³ it runs at 4.0 Hz.
  **INFERRED**, and the honest caveat is in §6.

`0x7FFFFF` occurs **32 times** in the whole coefficient corpus: **29** are LFO
wrap cells, 2 are consumed by `000.A.00.415` (a unity-gain multiply) and 1 is
never fetched. So it is not the generic "×1.0" gain — that role is filled by
`0x400000` (333 occurrences).

---

## 3. Where the phase lives — FORCED by MIX UP

The block reads memory **exactly once**: the middle word `082.2.00.1C0` carries
`SRC = 0x07 = mem[ptr]`, which is **ANCHORED**. That read is the block's only
input, so the value that persists across frames is the cell it names — call it
**Q**. The wrap word sits on Q and carries `hi12` bit 4, so it is the write.

MIX UP (algo 56) is the discriminator, and it is decisive:

```
   w4  092.A.00.200 |            w8  092.A.00.200 |            w12 092.A.00.200
   w5  082.2.00.1C0 |            w9  082.2.00.1C0 |            w13 082.2.00.1C0
   w6  094.A.00.200 |            w10 094.A.00.200 |            w14 094.A.00.200
   w7  000.2.01.447 -> ptr+1     w11 000.2.01.447 -> ptr+1     w15 000.2.08.447
        Q = +2, 2.9966 Hz              Q = +3, 5.1993 Hz            Q = +4, 7.3968 Hz
```

Three **byte-identical** instruction triples, three different rates, three
consecutive cells. **Nothing in the instruction words distinguishes them**, so
the per-oscillator state is selected by an **address**, not by an opcode.
**FORCED.**

The same holds inside every multi-LFO program — MODULATED CHORUS Q = +3/+4,
FLANGER +3/+4, PHASER +14/+15, AUTO PAN +13/+14, VIBRATO +12/+13, RING
MODULATOR +13/+14 — no two blocks ever share a cell.

*Alternative not excluded by MIX UP alone:* the coefficient **cursor** also
differs between co-resident blocks, so a phase-register bank indexed by the
cursor is arithmetically possible. It is rejected for a separate reason: it
requires the anchored `mem[ptr]` read at the middle word to be **dead in 29 of
29 sites**, in 16 independently written programs. **INFERRED**, strongly.

---

## 4. ★ The constraint search — and what it determines

Five free parameters, all OPEN in the ISA before this pass:

| parameter | candidates |
|---|---|
| `src08` | unity · zero · acc · mem[ptr] · P · a dedicated phase register |
| `act00` | none · `acc ← bus` · `acc += bus` · `mem ← bus` · `tA ← bus` · `tB ← bus` · `phase ← bus` · `phase += bus` |
| `order` | ACTION before the `hi12[3:1]` operation · after it |
| `op2` | hold · `acc &= coef` · `acc −= coef while ≥` · `acc &= 2²³−1` |
| `store` | saturate · wrap 2²⁴ · wrap 2²³ · `&coef` when `f31 == 2` · `−coef` when `f31 == 2` |

Held fixed, and **not** re-litigated: bit 4 stores to `mem[ptr]` and clears the
accumulator (biquad, 57 dB); the store precedes the ALU step (R1 F2); `P` is the
*previous* multiply's product; class A multiplies and advances the cursor;
`class4 & 7 == 2` post-increments the pointer.

The test is deliberately hard: the entering accumulator, product latch and both
temporaries are **randomised every frame**, so a machine only passes if the block
is **self-contained** — which it must be, because the same three words appear in
16 programs with completely different neighbours and all produce their documented
rate. Then the ramp cell is preset to `2²³ − 2·inc` and required to **wrap**.

### 4.1 The five blocks the model can run — 20 of 1920, one answer

```
   marginals over the 20 machines that RAMP:
      src08 : ['unity']            <- FORCED within the space
      act00 : ['acc_load']         <- FORCED within the space
      order : ['act_first']        <- FORCED within the space
      op2   : all four survive     <- the ramp CANNOT see it
      store : all five survive     <- the ramp cannot see it either
   ... and of those 20, the 8 that also WRAP correctly:
      store : ['wrap23', 'f31_2_and_coef']
```

So, **DETERMINED**:

```
   SRC   0x08  =  a UNITY MULTIPLICAND.  The class-A product for lo12 = 0x200 is
                  the COEFFICIENT ITSELF -- exactly `the coefficient-into-the-adder
                  route' that dsp-alu-applied.md guessed, now with a number behind it.
   ACT   0x00  =  acc <- bus.   An accumulator LOAD, not a capture and not a no-op.
   ORDER       =  the ACTION runs BEFORE the hi12[3:1] operation.
```

and the block reads, in full:

```
   092.A.dd.200   ST: mem[Q0] <- acc, acc := 0 ;  acc <- 1.0 ; acc += P ; P := INC
   082.2.00.1C0                                   acc <- mem[Q] = phase ; acc += P
   094.A.dd.200   ST: mem[Q]  <- phase + INC   ;  acc <- 1.0 ; op2 ; P := 0x7FFFFF
```

**Why the ordering is forced, in one line:** with the ACTION *after* the
operation, the middle word's `acc += P` is immediately overwritten by
`acc ← mem[Q]`, and the block stores the phase back unchanged — no ramp.
And **the ordering costs nothing**: `L` is latched at the start of the word, and
none of the five anchored actions (`0x07`, `0x12`, `0x13`, `0x14`, `0x15`) reads
anything the accumulator operation writes, so moving them is a **no-op for every
currently decoded word**.

### 4.2 The other twenty-four blocks — 0 of 1920

```
   == 3 of the 24 blocks whose accumulate word IS on the phase cell ==
      1920 machines tested   0 produce the RAMP   0 also WRAP at 2**23
```

In 24 of the 29 blocks the accumulate word's `addr8` is 0, so it sits **on Q** —
and it carries `hi12` bit 4. Under the shipped model it writes the incoming
accumulator into Q, and the middle word then reads *that* instead of the phase.
No choice of `src08`, `act00`, `order`, `op2` or `store` repairs it, because the
phase is already gone before the block's only read happens.

The five that work are exactly the five where `addr8` moves the pointer between
the accumulate word and the middle word: PHASER w1 (`+14`, and back `−14`),
ENSEMBLE w2 (`+5`), RING MODULATOR w10 (`+4`), S DELAY CHORUS w0 (`+3`), PEQ
VIBRATO w1 (`+3`). Their traces ramp perfectly and self-containedly.

**This is a falsification, and it is precisely located.** One of these is wrong:

* **(L-1)** `hi12` bit 4 is not an unconditional `mem[ptr] ← acc` on class A.
  *Note the discriminator that is sitting there*: all three LFO words carry
  `hi12` **bit 7**, and both of the biquad's bit-4 words (`0x212`) have bit 7
  **clear**. The ISA table already carries bit 7 as a speculative
  "index/address domain" with no reading. **But bit 7 alone does not resolve it**
  — the wrap word carries bit 7 too, and *its* store must reach Q, so the
  discriminator has to separate two words that differ only in `hi12[3:1]`.
* **(L-2)** the accumulator entering the accumulate word is not arbitrary but is
  *itself* the phase, so its store into Q is idempotent. Requires a producer we
  have not found; the predecessor word is `000.2.dd.407` (`acc ← P`) at 15 of 29
  sites, which makes the entering accumulator the product latch.
* **(L-3)** the pointer model is wrong for one of the two class-A words (a second
  data pointer, a pre- rather than post-increment, or an implicit offset).
* **(L-4)** `ACTION 0x00` is not `acc ← bus` and §4.1's determination is an
  artefact of five sites. Against this: those five are in five *different*
  programs and span 0.4 – 1000 Hz.

**None is adopted.** Each is a different machine, and the LFO alone does not
choose between them.

### 4.3 The wrap is not in the accumulator — FORCED

`notes/dsp-alu-applied.md` §2.2 enumerated two survivors for the wrap
(`acc &= K`, `acc −= K if ≥ K`) and `notes/dsp-frame-advance.md` §2 rated
"`HI_ACC_HOLD` allowed off class 8" as **FORCED AGAINST**, on the grounds that
the LFO's `094.A.dd.200` carries that code and "must do something (the 2²³
wrap)". **That reasoning is now falsified in its detail, though its conclusion
survives in a different form.**

The wrap word's bit-4 store happens **before** its ALU step (R1 F2) and clears
the accumulator. So by the time `hi12[3:1] == 2` runs, the phase has already been
written to Q and the accumulator is 0. **Whatever code 2 does to the accumulator,
it cannot reach the value that persists.** The search confirms it: all four `op2`
candidates survive equally, at every one of the five solvable blocks. The ramp
**cannot see** `op2`.

Of the five store-path candidates, only two survive the wrap test:

* **`wrap23`** — every store masks with `0x7FFFFF`. **FORCED AGAINST**: that
  makes every stored value non-negative, i.e. a full-wave rectifier on every
  store, and the biquad reconstruction that validated to 0.094 dB uses a signed
  store path.
* **`f31_2_and_coef`** — the accumulator's store path takes the value **modulo
  the fetched coefficient** when `hi12[3:1] == 2`. Survives.

The second reading has a property the first does not: **it explains the class-8
puzzle instead of tolerating it.** `dsp-alu-applied.md` §2.3 left it OPEN whether
code 2 is a no-op or a wrap that happens not to fire. Under "the operation lives
on the store path", the biquad's `804.8.16.415` comes out unchanged **because it
has no store** (`hi12 = 0x804`, bit 4 clear) — not because the sum is in range.
One rule, both blocks, no coincidence. It also gives the chip's OVC block (CDJ-500
block diagram) something to be. **CONSISTENT, not FORCED** — the LFO cannot
distinguish it from any other mechanism that masks the phase on the way to memory.

**AND versus subtract-if-≥.** With `K = 0x7FFFFF`, an AND gives a period of
exactly 2²³ and a conditional subtract gives 2²³−1 — a rate difference of 1 part
in 8.4 million, which no measurement here can see. My stage-3 test required the
phase sequence to be exactly `(phase + inc) mod 2²³`, and *that assumption* is
what excluded the subtract. Stated honestly: **the two are not separated by the
ramp.** What does favour the AND is the constant itself — for a subtract the
natural constant is `0x800000` (which the corpus does contain, 27 times), while
`0x7FFFFF` is exactly the *mask* for mod 2²³. **INFERRED.**

---

## 5. ★ The same defect, corpus-wide — 216 provably dead stores

A store is provably dead if the next access to the same cell is another write,
with no read between and no word of unknown addressing between. R1 and R2 used
exactly this instrument to falsify claims. Applied to the 38-image body corpus
under the shipped model (a mode-2 word writes `mem[ptr]` if bit 4 is set or
`ACTION == 0x07`, reads it if `SRC == 0x07`):

```
   provably dead stores: 216
      runs of 2 consecutive writes : 150
      runs of 3                    :  24
      runs of 4                    :   6

   x44  212.2.00.000 -> 000.2.F9.407
   x12  212.A.00.1D5 -> 212.A.00.415
   x12  090.A.00.1D5 -> 212.A.00.415
   x8   094.A.00.200 -> 000.2.00.447 -> 092.2.00.700
   x8   000.2.00.447 -> 092.2.00.700
   x7   094.A.00.200 -> 000.2.01.447
```

**Only 27 of the 180 chains contain an LFO word.** So §4.2 is not a quirk of the
LFO: the memory model has a systematic problem, and the LFO is simply the one
block whose correct output is known as a *number*, which is why it can prove it.

The commonest chain is worth reading. `212.2.00.000` stores the accumulator and
clears it; `000.2.F9.407` then latches `L = acc = 0` and writes **zero** over what
was just stored — 44 times in the corpus. Under the shipped model this machine
zeroes a state cell 44 times per corpus. That is not a plausible program.

*Caveat, stated because the argument depends on it:* a second data pointer, or a
host read of D-RAM, would make some of these stores live. K3 already established
that C-RAM has at least two independent pointers; whether D-RAM does is **OPEN**.

---

## 6. What is FORCED, what is CONSISTENT, what is OPEN

**FORCED**

* The LFO block carries no `SRC = 0x00`; it carries `SRC` 0x08 / 0x07 / 0x08 and
  `ACTION 0x00` three times. (§1)
* The per-oscillator phase is selected by an **address**, not by the opcode —
  MIX UP runs three byte-identical triples at three different rates. (§3)
* `hi12[3:1] == 2` **cannot** be what wraps the phase: the store that publishes
  the phase precedes it and clears the accumulator. (§4.3)
* Within the shipped model, **no** assignment of the five free parameters runs
  the LFO at 24 of its 29 sites. (§4.2)
* The action's position relative to the `hi12[3:1]` operation is a **free
  parameter for every currently decoded word** — moving it costs nothing. (§4.1)

**DETERMINED** (unique survivor of an exhaustive search over 1920 machines, at the
five blocks the model can run, in five different programs, over 0.4 – 1000 Hz)

* `SRC 0x08` = a unity multiplicand: the class-A product is the coefficient itself.
* `ACTION 0x00` = `acc ← bus`, taken before the `hi12[3:1]` operation.

**CONSISTENT, not forced**

* The wrap lives on the accumulator **store path**, as a modulo by the fetched
  coefficient enabled by `hi12[3:1] == 2` — one rule that also explains why the
  biquad's class-8 word looks like a no-op.
* The mask reading (`AND 0x7FFFFF`) over the conditional subtract, on the grounds
  that the firmware wrote the mask and not the modulus.
* The phase span is 2²³ rather than 2²⁴, and the nine rates are therefore
  {0.2, 0.4, 0.6, 1.2, 3.0, 4.0, 5.2, 7.4, 1000} Hz rather than half of each.
  Roundness alone cannot decide this; the `0x7FFFFF` constant and the 4.0 Hz
  vibrato are what carry it.

**OPEN**

* Which of (L-1) … (L-4) resolves §4.2. `hi12` bit 7 is the most interesting
  candidate and is **not sufficient on its own**.
* What `hi12[3:1] == 2` does to the accumulator (all four candidates survive).
* `SRC 0x11` — carried by the `xxx.?.dd.447` word that follows **28 of 29** LFO
  blocks; **26** of those are class-2 words that write `mem[Q]` *again*. It is one
  bit away from `SRC 0x10` = the accumulator. Under the shipped model each of
  those 26 is one of §5's dead stores.
* `SRC 0x1C` — carried by `092.2.00.700`, which sits on the same cell Q in **18
  of the 29** blocks (immediately after the successor word in 8 of them). The obvious reading is "the oscillator's
  waveform output", and the table-lookup idiom
  (`040.0.00.C63 | 000.6.TT.4CD | 012.4.01.1CE`) two words later is the obvious
  sine table. **Not tested here.**
* Whether D-RAM has a second pointer (§5's caveat).

---

## 7. PREDICT-THEN-CHECK log — every miss reported

| | prediction | result |
|---|---|---|
| **P-1** | the LFO anchors `SRC = 0x00`, as the brief and blocker #2 say | **MISS.** The field is `addr8`; `SRC` is `0x08`. The brief's experiment cannot run |
| **P-2** | `092.A.dd.200` and `094.A.dd.200` are identical in `class4`, `addr8` and all twelve `lo12` bits | **HIT**, verified bit by bit |
| **P-3** | before running the search: `src08` = unity, `act00` = `acc ← bus`, action **before** the operation, would be the unique survivor | **HIT.** 20 of 1920, all agreeing on those three |
| **P-4** | the 2²³ wrap is `hi12[3:1] == 2` acting on the accumulator, as `dsp-alu-applied.md` §2.2 and `dsp-frame-advance.md` §2 both assume | **MISS.** It runs after the store that publishes the phase; the ramp cannot see `op2` at all. The wrap must be on the store path |
| **P-5** | the phase is in D-RAM at `mem[ptr]` | **HIT**, and forced by MIX UP rather than assumed |
| **P-6** | `0x7FFFFF` is exclusive to the LFO in the coefficient corpus | **MISS (small).** 29 of 32 occurrences are LFO wraps; 2 are a unity-gain multiply (`000.A.00.415`) and 1 is never fetched |
| **P-7** | once the ALU codes were settled the shipped model would run the LFO | **MISS, and the result of this pass.** 0 of 1920 machines run it at 24 of 29 sites |
| **P-8** | the numeric anchor is one point (0.5993 Hz) | **MISS (good).** Nine distinct increments over four decades, joint null 3.1 × 10⁻¹² |

---

## 8. What this hands to the other two targets

**TARGET 2 — the `lo12` ACTION field.** `ACTION 0x00` is the field's largest code
and this pass gives it a named, tested candidate: **`acc ← bus`, before the
operation**. Two of the reverb all-pass core's six words carry it —
`082.2.00.1C0` (64 corpus sites, 5 per reverb frame) and `012.2.00.680` (16
sites, and it carries `hi12` bit 4). Under the candidate they read:

```
   012.2.00.680   mem[p] <- acc ; acc := 0 ; acc <- tempB>>1 ; acc += P
   082.2.00.1C0                              acc <- mem[p]   ; acc += P
```

That is a concrete constraint the R1 solver did not have, and it should be fed in
**before** the multiplicand restriction the brief describes, because it changes
what `104.2.00.000` (`SRC 0x00`, `ACTION 0x00`) can be. It also cuts the other
way: R1's `L = 0x19` = "capture into latch A" now has a rival reading in which
`000.2.00.419` (`SRC 0x10` = acc, `ACTION 0x19`) captures the *outgoing*
accumulator before `acc ← P` overwrites it — which is what an action-before-
operation ordering makes natural.

**And a warning for TARGET 2**: the all-pass core writes `mem[ptr]` from
`012.2.00.680`'s bit 4 and from the external DRAM word `880.1.20.655`, inside a
motif that §5 shows is in the middle of the dead-store population. Any per-word
role assignment settled on the current memory model inherits §4.2's defect.

**TARGET 1 — frame closure.** The LFO is **not** the source of the +121 residue:
25 of 29 blocks have net pointer displacement **0**, and the four that do not
(+3 ×2, +4, +5) are ordinary program moves, not a missing reload. Two things do
transfer:

* The five clean blocks show the machine deliberately **bracketing** a state cell
  with `+d … −d` (PHASER: `+14` then `−14`). If that idiom is general, a body's
  net displacement is a *design* quantity, which supports the closure criterion
  rather than the "nothing loads the pointer" candidate (P-1).
* §5's 216 dead stores are computed from the **same** pointer walk the closure
  measurement uses. A pointer model that produces 216 dead stores is a pointer
  model that could also be producing the +121.

**And the cross-cutting one.** `010.A.00.20C` and `010.9.D0.20C` — K4's two named
candidates for the missing per-unit **coefficient-base rebase**, the words K4
FORCED must exist and could not identify — both carry **`SRC = 0x08`**. Under
this pass's determination they put the *coefficient* on the bus, which is a
mechanism by which a C-RAM value could become the new base. **Not tested. A lead,
labelled as one.**

---

## 9. Reproducing

```
python3 dsp/tools/lfo_ramp.py fields      # the field misreading, sect. 1
python3 dsp/tools/lfo_ramp.py sites rate  # the 29 blocks and the 9-fold anchor
python3 dsp/tools/lfo_ramp.py walk        # where the phase lives, MIX UP
python3 dsp/tools/lfo_ramp.py solve       # the 1920-machine search  (~2 min)
python3 dsp/tools/lfo_ramp.py deadstore   # the 216 dead stores
python3 dsp/tools/lfo_ramp.py closure     # the hand-off, and the price tag
cd dsp && python3 verify.py               # BYTE-MATCH OK (no listing changed)
```

Nothing in this pass changes either disassembler, any `.dsm`, or the MAME device:
the two codes it determines are **not** adopted, for the reason in §0 row H.
`verify.py` re-run and **BYTE-MATCH OK**.
