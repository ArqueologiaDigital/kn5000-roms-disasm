# The LFO ramp as a numeric anchor — two codes DETERMINED, and the model that cannot run them

NEC **uPD6383GF-3BA** (Technics SX-KN5000, IC311). Date: **2026-07-26**.
No hardware. Static analysis, the ROM corpus and constraint solving only.

> ★ **RETRACTION BANNER, 2026-07-27.** Where this note treats **the +121 residue**
> as an open pointer defect, that reading is **WITHDRAWN**: the D-RAM origin is
> pinned (`base = 0x05 | (unit << 7)`, FORCED) and the walk closes. §12's
> conclusion — that the LFO is *not* its source — was right, and is now moot.

> **This note is in two parts.** **Part I (§0–§6)** determines two ALU codes from
> the ramp and then falsifies the model they were determined in: at 24 of the 29
> LFO blocks *no* machine in its space can run the block, and it names four
> candidate resolutions (L-1 … L-4) without choosing. **Part II (§7–§14)**, added
> in the same pass series, **chooses** — by widening the search in the two
> directions the falsification pointed at, and by measuring that the biquad which
> validated `hi12` bit 4 never constrains it on the words the LFO uses. Part II's
> ledger is in **§11** and it supersedes Part I's **§6** where the two touch.

Reproduce every number below with
[`dsp/tools/lfo_ramp.py`](../tools/lfo_ramp.py) (standard library only, no
emulator, no undumped ROM):

```
python3 dsp/tools/lfo_ramp.py                       # all nine sections
python3 dsp/tools/lfo_ramp.py fields rate solve     # Part I
python3 dsp/tools/lfo_ramp.py publish gate          # Part II  (~6 min)
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

### Part II — added in the second pass (§7–§12)

| # | what | label |
|---|---|---|
| **I** | ★ **THE BIQUAD NEVER CONSTRAINED BIT 4 HERE, AND NOBODY HAD CHECKED.** PARAMETRIC EQ — the block that validates "`hi12` bit 4 = store accumulator to `mem[ptr]`" to 0.094 dB — contains **0 of 105** words carrying bit 4 *and* bit 7. All **22** of its store words are `(bit7 = 0, hi12[3:1] = 1)`. All three LFO words are `(bit7 = 1)`. The 57 dB evidence for bit 4 therefore says **nothing** about the words Part I could not run. Part I held bit 4 fixed for a reason that does not apply. | **MEASURED** |
| **J** | ★ **ALL 29 BLOCKS NOW RAMP AND WRAP.** Widening the window to include the words *after* the block and letting the bit-4 store be gated gives a **276 480**-machine space; **432** survive the ramp *and* the 2²³ wrap at **all 29 blocks**, against **0** in Part I's space at 24 of them. Part I's three determinations survive the 144×-larger space **unchanged and still as singletons** — `src08 = unity`, `act00 = acc ← bus`, `order = act before the operation` — and are now carried by 29 blocks in 16 programs over **0.2 – 1000 Hz** instead of 5. | **DETERMINED** |
| **K** | ★ **THE STORE GATE READS TWO BITS, AND NEITHER ONE ALONE.** `hi12` bit 7 alone (`not_b7`) has **0** survivors — the numeric constraint kills it. `hi12[3:1] == 2` alone (`f31_2_only`) survives the ramp and is **falsified by the biquad** (it would suppress all 22 PEQ stores). What survives is a gate reading **both**: the store is suppressed-or-redirected exactly on `(bit7 = 1, hi12[3:1] = 1)`. Three such gates survive and the ramp cannot separate them; they differ on **13** corpus words. | **FORCED** (that both bits are read) / **OPEN** (which of the three) |
| **L** | ★ **THE PUBLISHER IS THE WRAP WORD, NOT THE `447`.** Traced: `094.A.dd.200`'s bit-4 store is what deposits `phase + inc` in the cell; the `xxx.2.dd.447` word that follows 26 of 29 blocks is **inert on that cell**. My prediction was the opposite and it is a **MISS**. What is forced about the `447` is only negative: it must not deposit a *foreign* value — either its source is the cell itself or ACTION `0x07`'s destination is elsewhere (R2 already FORCED that destination to be mode-dependent). | **FORCED** (negative) / **OPEN** (which reading) |
| **M** | ★ **AN INDEPENDENT TEST, PARTLY PASSED — AND IT LOCATES A SECOND DEFECT.** The gate comes from a *numeric* constraint; the 216 provably-dead stores are a *structural* measurement that knows nothing about rates. The gate removes **55** of them (216 → **161**); with the `447` constraint as well, 216 → **135** (−37.5 %) or **123** (−43.1 %). Real, and **partial**. The residue is dominated by `212.2.00.000 → 000.2.F9.407` **×44**, which carries `bit7 = 0` and which this pass cannot touch. **The memory model has a second, independent defect.** | **MEASURED** |
| **N** | Nothing is adopted, again, and for a stated reason: **three** gates survive, and the datapath still carries 135 provably dead stores. The ALU predicate, both disassemblers and every `.dsm` are **unchanged**; `verify.py` **BYTE-MATCH OK**. §11 says what would settle it. | **MEASURED** |

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

## 6. What is FORCED, what is CONSISTENT, what is OPEN — *Part I's ledger*

> ⚠ **Read §11 before using this list.** Part II resolves this section's first
> OPEN item (which of L-1 … L-4 resolves §4.2 — it is **L-1**, with the
> discriminator narrowed), promotes two of its DETERMINED rows from 5 blocks to
> 29, and adds constraints this list does not carry. Where the two ledgers touch,
> **§11 wins**; nothing in this section is withdrawn.

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

---
---

# PART II — the gate, and who actually writes the phase

Part I ended on a located falsification: *nothing in a 1920-machine space runs 24
of the 29 LFO blocks, because the accumulate word `092.A.dd.200` carries `hi12`
bit 4 and sits on the very cell the next word reads.* It named four candidate
resolutions and adopted none. This part tests them.

Two things Part I held fixed turn out to be the two things worth moving, and both
were fixed for reasons that do not survive being checked.

---

## 7. ★ The biquad never constrained bit 4 on these words

Part I's search declared, in its own preamble: *"Fixed, and **not**
re-litigated: bit 4 stores to `mem[ptr]` and clears the accumulator (biquad,
57 dB)."* That is a reasonable thing to hold fixed — the PARAMETRIC EQ
reconstruction is the strongest numeric result this project has, and removing the
bit-4 store costs it 57 dB.

It is also, as an argument about the LFO, **empty**. MEASURED:

```
   PARAMETRIC EQ (algo 39), 105 words:
      words carrying hi12 bit 4 AND hi12 bit 7 :   0
      its bit-4 store words, by (bit7, hi12[3:1]) : {b7=0, f31=1} x22

   the three LFO words:
      092.A.dd.200  bit4=1  bit7=1  hi12[3:1]=1
      082.2.00.1C0  bit4=0  bit7=1  hi12[3:1]=1
      094.A.dd.200  bit4=1  bit7=1  hi12[3:1]=2
```

**Every word that carries the biquad's evidence has `bit7 = 0`; every word of the
LFO has `bit7 = 1`.** The 0.094 dB validation therefore constrains bit 4 on
`bit7 = 0` words and on nothing else. Part I's own §4.2 note that "`hi12` bit 7
is the most interesting candidate" was right, and the reason it could not be
pursued was that Part I never measured *where the bit-4 evidence lives*.

This narrows a standing ISA claim rather than contradicting it.
`instruction-set.md` records bit 4 as **MEASURED**, citing
`0x212 = 0x202 + bit4` **and** `0x092 = 0x082 + bit4`. The first is the biquad.
The second is **the LFO's own accumulate word against the LFO's own middle
word** — an *encoding* observation (the two hi12 values do differ by bit 4), not
a semantic one, and this pass shows those two words cannot both be storing. So:

> **`hi12` bit 4 = "store the accumulator to `mem[ptr]` and clear it" is VERIFIED
> for `bit7 = 0` and UNVERIFIED for `bit7 = 1`.** 527 corpus words are in the
> verified case; **180** are not.

Corpus census, C-format excluded (2989 of the 3057 words):

| | bit7 = 0 | bit7 = 1 |
|---|---|---|
| **bit4 = 0** | 1879 | 403 |
| **bit4 = 1** | **527** (biquad's case) | **180** (unverified) |

`hi12` bit 7 is not a rarity and not an artefact: 583 words carry it, 127
distinct, and the corpus contains **12 minimal pairs** that are byte-identical
except for it — including `212.A.01.412` (×34, the biquad's input word) against
`292.A.01.412` (×4, ENHANCER) and `212.2.00.000` (×88) against `292.2.00.000`
(×2). Whatever bit 7 is, the compiler emits both polarities of the same
instruction deliberately.

---

## 8. ★ The widened search — and it runs all 29 blocks

### 8.1 What was widened, and why exactly that

**The window.** Part I simulated the three-word block alone. But the block does
not end there:

```
   A> 092.A.00.200   store? ; SRC 0x08 ; ACTION 0x00        the accumulate
   M> 082.2.00.1C0           SRC 0x07 = mem[Q] ANCHORED     the phase read
   W> 094.A.00.200   store? ; SRC 0x08 ; ACTION 0x00        the wrap
      000.2.dd.447           SRC 0x11 ; ACTION 0x07 = "write the operand to a
                             destination" (ANCHORED) -- ON THE SAME CELL Q
      092.2.00.700   store? ; SRC 0x1C ; ACTION 0x00        -- ALSO on Q
      000.A.00.1D5           SRC 0x07 = mem[Q], class A     -- READS Q again
```

**MEASURED: 26 of the 29 blocks carry a `SRC 0x11 / ACTION 0x07` word on the
phase cell**, inside the same run of ordinary D-RAM words. A store Part I's §5
was counting as *dead* is a candidate **publisher**, and it is invisible from
inside a three-word window. The window here runs from the accumulate word to the
first following word this model cannot execute at all (C-format, a mode-1 escape,
an unanchored ACTION, or the `lo12` bit-11 / bit-5 modifiers) — 0 to 18 extra
words, most often 4.

**The store gate**, for the reason in §7.

Everything else is held exactly as Part I held it, including the parts that make
the test hard: the entering accumulator, the product latch and both temporaries
are **randomised every frame**, and **any source this ISA does not decode
delivers a fresh random value** — so `SRC 0x00`, `SRC 0x13` and `SRC 0x1C` inside
the window are noise, and a machine that depends on any of them cannot pass.

### 8.2 The result

```
   candidate machines                              276480
   stage 1  (2 blocks, 10 frames)                     864 survive
   stage 2  (ALL 29 blocks, 30 frames)                864 survive
   stage 3  (the 2**23 WRAP, all 29 blocks)           432 survive

   marginals over the 432:
      src08   : ['unity']                     <- singleton, as in Part I
      act00   : ['acc_load']                  <- singleton, as in Part I
      order   : ['act_first']                 <- singleton, as in Part I
      op2     : all four                      <- the ramp still cannot see it
      store   : ['b7_and_coef', 'f31_2_and_coef', 'wrap23']
      stgate  : ['b7_f31_1_off', 'b7_f31_1_scratch', 'b7_ne2_off', 'f31_2_only']
      src11   : all eight, with dest07='elsewhere'; only 'mem' with dest07='mem'
```

**Stage 2 does not shrink stage 1.** Every machine that runs two blocks runs all
twenty-nine, in sixteen independently written programs, at nine different rates
spanning four decades. That is the property Part I's five clean blocks could not
demonstrate.

**Part I's three determinations are re-derived, not assumed.** They were
singletons in a 1920-point space over 5 blocks; they are singletons in a
276 480-point space over 29 blocks. `src08 = unity`, `act00 = acc ← bus`,
`order = ACTION before the hi12[3:1] operation`.

### 8.3 What the gate has to be

Eight gates were offered. **Five have zero survivors:**

| gate | survivors | why it fails |
|---|---|---|
| `always` (**the shipped model**) | **0** | Part I's falsification, restated in a 144× larger space with the successor words visible. It is not a window artefact |
| `not_b7` — bit 7 cancels the store | **0** | then the **wrap** word does not store either, and nothing publishes the phase |
| `not_b7_keepclear` | 0 | as above |
| `b7_scratch` — bit 7 redirects it off D-RAM | 0 | as above |
| `prev_ptr` — the store uses the previous word's pointer | 0 | a pipelined write address does not help: in 24 of 29 blocks the previous word already left the pointer at Q |
| `next_ptr` — the store uses the post-incremented pointer | 0 | and it *breaks the 5 blocks that worked*: PHASER's `092.A.0E.200` would then store at +14 = Q |

**Three survive, plus one the biquad kills:**

| gate | ramp | biquad |
|---|---|---|
| `f31_2_only` — store only when `hi12[3:1] == 2` | ✔ | ✘ **FALSIFIED** — it suppresses all 22 PARAMETRIC EQ stores, i.e. the 57 dB |
| `b7_f31_1_off` — suppressed iff `bit7 == 1 && hi12[3:1] == 1` | ✔ | ✔ |
| `b7_ne2_off` — suppressed iff `bit7 == 1 && hi12[3:1] != 2` | ✔ | ✔ |
| `b7_f31_1_scratch` — *redirected* rather than suppressed | ✔ | ✔ |

So, **FORCED**: *the gate reads `hi12` bit 7 **and** `hi12[3:1]`.* Bit 7 alone
is excluded by the ramp (a numeric constraint); `hi12[3:1]` alone is excluded by
the biquad (an independent numeric constraint). This is the single sharpest
statement this pass produces, and it is exactly the discriminator Part I §4.2
said was needed and could not find — *"the discriminator has to separate two
words that differ only in `hi12[3:1]`"* — the answer being that it separates them
**by also reading bit 7**.

The three survivors differ on **13 corpus words**:

```
   09A.A.00.200 x9   090.A.01.1C8   29A.A.B8.21A   090.A.00.1D5   090.2.FB.40E
```

Nine of the thirteen are `09A.A.00.200` (`hi12[3:1] = 5`), and it is **not** an
LFO word: it is the **COMPRESSOR's** envelope step (1 in the resident kernel,
8 across COMPRESSOR / PEQ COMPRESSOR / PEQ COMPR DIST / PEQ COMPR OVERDR), reached
by `000.A.00.219 | 09A.A.00.200 | C40.1.E0.451`, and the coefficients it eats are
`0x600000` = **0.750000** and `0x517CC1` = **0.636620** — the latter being 2/π to
six figures. Deciding between the three gates therefore means decoding
`hi12[3:1] == 5`, which is a compressor question, not an LFO one. **OPEN, and
located.**

*A note on parsimony, stated because it is the honest objection:* a two-condition
gate is an ugly thing to propose. It is proposed anyway because the alternative
is not a simpler gate but **no gate at all**, and "no gate" has zero survivors
against 29 blocks whose output is known as a number. A natural single-bit reading
that fits — e.g. bit 7 = a CONDITION flag (the part has a COND field in the
CDJ-500 block diagram, which nothing in this decode models) whose condition
happens to be false at `hi12[3:1] == 1` and true at 2 — is **EDUCATED GUESS**, and
it is written here as one.

### 8.4 The block, read out in full

Traced, `python3 dsp/tools/lfo_ramp.py publish` and the `trace=True` path of
`sim2()`, CHORUS, increment `0x000072`:

```
   092.A.00.200   ST SUPPRESSED (bit7 & f31==1) ; acc <- 1.0 ; acc += P ; P := INC
   082.2.00.1C0                                   acc <- mem[Q] = phase ; acc += P
   094.A.00.200   ST mem[Q] <- (phase + INC) mod 2**23 , acc := 0
                                                  acc <- 1.0 ; op2 ; P := 0x7FFFFF
   000.2.09.447   INERT on Q                    ; acc <- P

   mem[Q] over three frames:  000072  0000E4  000156      delta = 114 = INC
```

**The publisher is the wrap word.** My prediction before running was that it
would be the `447` word with `SRC 0x11 = acc`; that is a **MISS**, and `acc` is
positively excluded — after the wrap word's store-and-clear the accumulator holds
`1.0`, so a `447` that copied it would overwrite the phase with unity every
frame.

What the ramp forces about the `447` word is therefore only **negative**: *it must
not deposit a foreign value in the phase cell.* Two readings do that and the ramp
cannot separate them:

* `SRC 0x11 = mem[ptr]`, making the word a self-copy on this cell — the only
  `src11` that survives with ACTION `0x07` writing D-RAM; or
* ACTION `0x07`'s **destination** is not D-RAM here, in which case `SRC 0x11` is
  unconstrained by the LFO. **R2 already FORCED that this destination is
  mode-dependent**, so this is not an invention.

### 8.5 One thing that did *not* have to work, and did

The gate was determined from the accumulate word. It applies unchanged to
`092.2.00.700` — the `SRC 0x1C` word that sits **on the phase cell** in 8 of the
29 blocks, carries `hi12 = 0x092` (bit7 = 1, `hi12[3:1]` = 1) and bit 4, and
would under the shipped model clobber the phase a *third* time. The gate
suppresses it too, without being asked. 28 corpus occurrences.

---

## 9. ★ The independent test — structural, and only partly passed

The ramp is a numeric constraint. The **provably dead store** census (Part I §5)
is a structural one that knows nothing about rates: a store is provably dead if
the next access to the same cell is another write, with no read between and no
word of unknown addressing between. The two are independent, so they can
disagree — which is why this is a test and not a demonstration.

```
   gate                 dead     removed   corpus bit-4 stores kept
   always (shipped)     216      +0.0%     707 of 707
   not_b7               123      -43.1%    527 of 707     <- 0 ramp survivors
   f31_2_only            26      -88.0%     29 of 707     <- falsified by the biquad
   b7_f31_1_off         161      -25.5%    569 of 707
   b7_ne2_off           149      -31.0%    556 of 707

   joint with the OTHER thing the ramp forces (the SRC-0x11 / ACTION-0x07 word
   being inert on the cell):
      always (shipped)   182   (-15.7 %)
      b7_f31_1_off       135   (-37.5 %)
      b7_ne2_off         123   (-43.1 %)
```

**It passes, partially, and the partiality is the useful part.** A gate invented
to make one block work would have removed the LFO's own chains and nothing else.
This one removes 55 by itself and 81 jointly, across programs it was not fitted
to — the removed chains are led by the `092.2.00.700` family (§8.5), which the
gate was never shown:

```
   removed:  x8  094.A.00.200 -> 000.2.00.447 -> 092.2.00.700
             x8  000.2.00.447 -> 092.2.00.700
             x4  02A.2.00.407 -> 212.2.00.000 -> 212.2.00.000 -> 092.2.00.700
             x4  212.2.00.000 -> 092.2.00.700
             x2  292.A.00.1D3 -> 212.A.01.452
```

But **135 survive**, and they are led by a chain this pass cannot touch:

```
   surviving: x44  212.2.00.000 -> 000.2.F9.407      bit7 = 0 on both words
              x16  212.2.00.000 -> 212.2.00.000
              x12  212.A.00.1D5 -> 212.A.00.415
              x12  090.A.00.1D5 -> 212.A.00.415
```

`212.2.00.000` stores the accumulator and clears it; `000.2.F9.407` then latches
`L = acc = 0` and writes **zero** over what was just stored, 44 times in the
corpus. Both carry `bit7 = 0`, so the store gate leaves them exactly as they were.

> **MEASURED, and it is a result in its own right: the memory model has a second,
> independent defect, and the LFO cannot see it.** The most likely candidates are
> the ones Part I §5 already flagged as caveats — a second D-RAM pointer, or a
> host read of D-RAM — plus the possibility that `SRC 0x00` / `ACTION 0x00` on
> `212.2.00.000` is not what the model assumes. Whoever attacks the `212` chain
> should not expect the LFO to help.

---

## 10. The LFO's output path — one motif, one number, and one hypothesis I falsified

The natural next numeric anchor after the ramp is the ramp's **consumer**. 8 of
the 29 blocks (FLANGER, AUTO PAN, VIBRATO, RING MODULATOR — two blocks each)
carry a single exceptionless tail:

```
   000.2.00.447 | 092.2.00.700 | 000.A.00.1D5 | 182.2.00.000 | 040.0.00.C63 | 000.6.18.4CD
      inert       SRC 0x1C       P := coef x mem[Q]   SRC 0x00     ---- the table idiom ----
```

`000.A.00.1D5` is `SRC 0x07 = mem[Q]`, ACTION `0x15` (no side effect), class A —
so it **multiplies the phase by a coefficient** and leaves the product in `P`,
two words before the class-0/6/4 table-lookup idiom. That is a phase-to-index
scaling followed by a waveform lookup, which is what an oscillator's output stage
looks like.

MEASURED: **the coefficient is `0x000018` = 24 at 8 of 8**, and the C-RAM shows
the LFO's coefficients are a **triple**, not a pair:

```
   FLANGER  C-RAM   05:000026  06:7FFFFF  07:000018  08:400000
                    09:000026  0A:7FFFFF  0B:000018  0C:400000
   AUTO PAN C-RAM   01:0000E4  02:7FFFFF  03:000018
                    04:0000E4  05:7FFFFF  06:000018
                    ^ increment ^ wrap    ^ index scale
```

`(coef × phase) >> 23` with `coef = 24` maps a Q0.23 phase onto `0 … 23` — an
integer index into a 24-entry table.

**PREDICT-THEN-CHECK, and a MISS.** The class-6 word in the same motif carries
`addr8 = 0x18` = **24**, the same number. I predicted that this was the table's
extent appearing in both fields, and that the machine's *other* class-6 selector
— `000.6.28.4CD`, `addr8 = 0x28` = 40, ×17 — would be fed by a scale coefficient
of `0x000028` = 40. **It is not.** All ten of those sites are preceded by
`000.A.00.415` consuming `0x000010` = **16** (eight sites) or `0xC00008` (two).
`0x000028` does not occur in the coefficient corpus at all. The `24/0x18`
agreement is a **coincidence**, and the general rule is **FALSIFIED**.

What survives is weaker and still worth having: *the class-A word immediately
before a table-lookup idiom consumes a small integer* — 24 before the LFO's
lookup, 16 before the waveshaper's — which is what an index scale looks like and
which puts the tables at ~24 and ~16 entries. **CONSISTENT, not forced.**
A second temptation resisted: `0x000018` occurs 29 times in the coefficient
corpus but only **10** of those are within three cells of an LFO wrap cell, and
only **11 of 29** blocks carry it near their wrap at all — so it is a general
small constant, **not** an LFO signature.

---

## 11. ★ Part II's ledger

**MEASURED**

* PARAMETRIC EQ contains **0 of 105** words with `hi12` bit 4 and bit 7 together;
  all 22 of its store words are `(bit7 = 0, hi12[3:1] = 1)`. The biquad
  constrains bit 4 only on `bit7 = 0`. (§7)
* 527 corpus words are in the verified bit-4 case; **180 are not**. 583 words
  carry bit 7, 127 distinct, in 12 bit-7 minimal pairs. (§7)
* 26 of 29 blocks carry a `SRC 0x11 / ACTION 0x07` word **on the phase cell**. (§8.1)
* The gate removes 55 of the 216 provably dead stores alone, 81 jointly; **135
  survive**, led by `212.2.00.000 → 000.2.F9.407` ×44 at `bit7 = 0`. (§9)
* The LFO's coefficients are a **triple** — increment, `0x7FFFFF`, and a third
  cell that is `0x000018` = 24 at all 8 sites carrying the waveform tail. (§10)

**FORCED**

* **The `hi12` bit-4 store is not unconditional.** 0 of 276 480 machines run the
  24 broken blocks with `stgate = always`, with the successor words visible. This
  is Part I's falsification confirmed in a 144×-larger space, so it is not an
  artefact of the three-word window. (§8.3)
* **The gate reads `hi12` bit 7 *and* `hi12[3:1]`.** Bit 7 alone: 0 survivors
  (ramp). `hi12[3:1]` alone: falsified (biquad). This resolves Part I's §4.2 in
  favour of **(L-1)**, and narrows it — bit 7 is necessary but, exactly as Part I
  warned, not sufficient. (§8.3)
* **The publisher is the wrap word `094.A.dd.200`.** The `447` word is inert on
  the phase cell, and `SRC 0x11 = acc` is positively excluded. (§8.4)
* The same gate suppresses `092.2.00.700`'s store without being fitted to it. (§8.5)
* `hi12[3:1] == 2` **still** cannot be what wraps the phase — Part I §4.3 stands,
  for the same reason (the store precedes it and clears the accumulator), and all
  four `op2` candidates still survive equally. (§8.2)

**DETERMINED** (unique survivor, now over **all 29 blocks**, 16 programs,
0.2 – 1000 Hz, in a 276 480-machine space — was 5 blocks in a 1920-machine space)

* `SRC 0x08` = a **unity multiplicand**: the class-A product for `lo12 = 0x200`
  is the coefficient itself.
* `ACTION 0x00` = **`acc ← bus`**, taken **before** the `hi12[3:1]` operation.

**CONSISTENT, not forced**

* The 2²³ wrap lives on the accumulator **store path**, keyed by something that
  separates the LFO's wrap word from the biquad's store words. Two candidates now
  survive where Part I had one — `f31_2_and_coef` (keyed on `hi12[3:1] == 2`) and
  `b7_and_coef` (keyed on bit 7). `wrap23` remains **falsified** by the biquad's
  signed store path.
* The gate **suppresses** rather than **redirects** the store
  (`b7_f31_1_off` vs `b7_f31_1_scratch`); the ramp cannot tell.
* The class-A word before a table-lookup idiom carries a small-integer index
  scale (24 for the LFO, 16 for the waveshaper). (§10)

**OPEN**

* **Which of the three surviving gates.** They differ on 13 corpus words, 9 of
  them `09A.A.00.200` — the COMPRESSOR's envelope step at `hi12[3:1] == 5`, eating
  `0.750000` and `0.636620` (= 2/π). Settling it means decoding `hi12[3:1] == 5`.
* Whether `SRC 0x11` is `mem[ptr]` or whether ACTION `0x07`'s destination is
  elsewhere on these words.
* What `hi12[3:1] == 2` does to the accumulator. Unchanged: the ramp cannot see it.
* **What causes the surviving 135 dead stores**, above all
  `212.2.00.000 → 000.2.F9.407` ×44. A different defect, at `bit7 = 0`.
* What `hi12` bit 7 *means* — the gate uses it without reading it. A COND flag
  (CDJ-500 block diagram) is an **EDUCATED GUESS**, nothing more.

**FALSIFIED in this pass**

* ★ **The brief's SRC anchors.** The task brief lists *"Anchored SRC: … `0x1C`
  LFO out, `0x08` LFO phase"*. **Neither is anchored anywhere in this
  repository** — `grep` over `dsp/`, the MAME device and its disassembler finds
  no such claim. `SRC 0x08` was **DETERMINED** by Part I, and re-determined here
  over 29 blocks, to be a **unity multiplicand**, which is not "LFO phase";
  `SRC 0x1C` has no anchor at all and is treated as *noise* by this pass's
  simulator, which is why the result does not depend on it. What exists is a
  *word-level* landmark — `092.A.dd.200` is "the LFO phase-accumulate word" — and
  it appears to have been read as a *field-level* anchor.
* My own "the index scale equals the class-6 selector byte" (§10).
* The scope of `instruction-set.md`'s bit-4 row is **narrowed**, not withdrawn:
  its `0x092 = 0x082 + bit4` half is an encoding observation on two LFO words
  that this pass shows cannot both be storing.

---

## 12. PREDICT-THEN-CHECK log — Part II

| | prediction | result |
|---|---|---|
| **P-9** | `stgate = always` has **zero** survivors even with the window widened — i.e. Part I's falsification is not a window artefact | **HIT.** 0 of 276 480 |
| **P-10** | some non-shipped gate runs all 29 blocks | **HIT.** 432 machines do, over four gates |
| **P-11** | Part I's `src08 = unity`, `act00 = acc_load`, `order = act_first` carry over to the wider space | **HIT.** Still singleton marginals, now on 29 blocks instead of 5 |
| **P-12** | the publisher is the **`447`** word, with `SRC 0x11 = acc` | **MISS.** The publisher is the **wrap word**; the `447` is inert, and `src11 = acc` is excluded — after the wrap's store-and-clear the accumulator holds 1.0 |
| **P-13** | the gate is `not_b7` — bit 7 alone suppresses the store | **MISS.** 0 survivors: with both LFO stores gone nothing publishes the phase. The gate needs `hi12[3:1]` as well |
| **P-14** | the gate removes more than 60 of the 216 provably dead stores | **MISS (marginal).** 55 by itself; 81 with the `447` constraint. Reported because I set the threshold before looking |
| **P-15** | `212.2.00.000 → 000.2.F9.407` ×44 survives every gate untouched, because both words carry `bit7 = 0` | **HIT**, and it is the largest surviving chain |
| **P-16** | if `addr8` on the class-6 selector is the table extent, `0x000028` = 40 appears in the coefficient corpus at the `0x28` sites | **MISS.** They are fed by `0x000010` = 16; `0x000028` does not occur at all. My §10 hypothesis is falsified |
| **P-17** | `prev_ptr` (a pipelined write address) is a live candidate | **MISS.** 0 survivors — in 24 of 29 blocks the previous word had already left the pointer on Q |

---

## 13. What Part II hands to the other two targets

**TARGET 2 — the `lo12` ACTION field.** Three things, one of them a warning.

* `ACTION 0x00 = acc ← bus, before the operation` is no longer a five-block
  determination: it is a **29-block** one, in 16 programs, at nine rates over four
  decades. It is the field's largest code (824 corpus words, 51 of the 205
  undecoded frame slots) and the all-pass core carries it twice —
  `082.2.00.1C0` (×64, and **the LFO's own middle word**, so this pass reads it
  directly) and `012.2.00.680` (×16).
* **The gate does not touch the all-pass core.** `012.2.00.680` has
  `hi12 = 0x012` → `bit7 = 0`, so its bit-4 store stands exactly as R1 modelled
  it; and `880.1.20.655`, the core's external-DRAM write, has bit 7 set but **no**
  bit 4, so the gate does not apply. R1's model is untouched by this pass — which
  is worth knowing before the multiplicand-restriction re-run, because it means a
  collapse or a survival there is not confounded with anything here.
* A constraint for `SRC 0x00`: under the determined `ACTION 0x00`, every
  `xxx.?.??.000` word — `104.2.00.000` ×9 in the reverb, `182.2.00.000` in the LFO
  tail — reads **`acc ← src00`**. That does not say what `SRC 0x00` *is*, and this
  pass explicitly **cannot** say: those words sit downstream of the publisher, so
  the ramp is invariant under them. The brief's §4 blocker #2 experiment
  ("solve for `SRC = 0x00` from the LFO") is unreachable for a **second**,
  sharper reason than Part I's field misreading.

**TARGET 1 — frame closure.** Unchanged, and now provably so: **this pass alters
no pointer displacement.** The gate changes only whether a store happens, never
`ptr_postinc()` or the cursor, so the static walk's −135 ≡ +121 (mod 256) and the
live +121 are exactly as they were. The LFO remains not the source of the residue
(25 of 29 blocks are net 0). What does transfer is the negative result of §9: the
pointer walk that produces 216 dead stores still produces **135** of them after
this pass, so *"a pointer model that could also be producing the +121"* remains a
live candidate — but the LFO has now been eliminated as its cause.

---

## 14. Reproducing Part II

```
python3 dsp/tools/lfo_ramp.py publish     # the 276480-machine search   (~5 min)
python3 dsp/tools/lfo_ramp.py gate        # the independent dead-store test
python3 dsp/tools/lfo_ramp.py             # everything, Part I and Part II
cd dsp && python3 verify.py               # BYTE-MATCH OK
```

**Nothing is adopted.** The ALU predicate, `upd6383d.cpp`, `dsp_disasm.py` and
every `.dsm` are untouched by this pass; `verify.py` re-run and **BYTE-MATCH OK**
(kernel + epilogue + 91 valid algorithm streams, 38 distinct images). Part I's
row H price stands, and this part adds a second reason to refuse it: three gates
survive, and the datapath they would run on still contains 135 provably dead
stores that this pass has shown it cannot explain.
