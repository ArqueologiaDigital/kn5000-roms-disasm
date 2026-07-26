# R3 — the external delay-DRAM ADDRESSING

NEC **uPD6383GF-3BA** (Technics SX-KN5000, IC311). Roadmap item **R3**, the item
[`../instruction-set.md`](../instruction-set.md) ranks **#1** on its worklist
("the single largest hole … it blocks every delay, chorus, flanger and reverb").
Date: 2026-07-26.
Tool: [`../tools/r3_delaydram.py`](../tools/r3_delaydram.py) — stdlib only,
re-runnable, prints every number quoted here.

Labels: **MEASURED** (read out of the ROM), **PROVEN BY CONSTRUCTION** (the
firmware builds the value and we read the builder), **FORCED** (every survivor of
an exhaustive search agrees), **CONSISTENT**, **INFERRED**, **OPEN**. Where a
constraint system admits several assignments they are enumerated, not picked.

No hardware. Nothing here is a recording.

---

## 0. Result in one page

R1 forced *which* words touch the delay DRAM. It could not say where the address
came from, and it looked for it in the instruction fields. It is not there. The
address comes from a **host-written register bank** — the delay-address
counterpart of the coefficient bank — and the whole chain is in the Sub CPU ROM,
in plain sight, one call site wide.

```
   delay-DRAM address  =  ( DESCRIPTOR_CELL[cursor] + G )  mod 2^N
```

| # | statement | status |
|---|---|---|
| **P1** | The delay addresses live in a **descriptor register bank** written by host packets tagged **0x4C**, addressed by the pointer register `…825` — exactly as the coefficient bank is written by tag **0x26** through `…821`. The writer is `LABEL_038922`, whose four payload steps are **byte-for-byte** those of the coefficient writer `LABEL_0387E6` that K5 proved. | **PROVEN BY CONSTRUCTION** |
| **P2** | Therefore the payload is the **24-bit poke value** `(b1&0x7F)<<17 \| b2<<9 \| b3<<1 \| b4>>7`, i.e. **2 × the raw three bytes + tag bit 7** — *not* the raw three bytes. **This falsifies `r1-allpass-motif.md` §3; every delay length R1 prints is exactly half the real one.** | **PROVEN BY CONSTRUCTION**, confirmed three independent ways (§2) |
| **P3** | A descriptor cell holds `LINE_BASE + DELAY_IN_SAMPLES`. A **delay is an address**, and the delay of a line is the **difference of two cells**. | **PROVEN BY CONSTRUCTION** (`ADD (XSP+002h), XWA` in the writer) + **MEASURED** (§4) |
| **P4** | The ms→address chain is `cell = K24 + (ms × 0xAC44) / 0x3E8`, i.e. `K + ms × 44100/1000`, with `K24` a **literal base address** in the level-2 parameter bytecode. Scaler `LABEL_03925E`, opcode **0x67** — the **only** opcode in the machine that can write a delay descriptor. | **PROVEN BY CONSTRUCTION** |
| **P5** | Delay memory map: **unit 0 = `[0x00000, 0x08000)`, unit 1 (the twelve reverbs) = `[0x08000, 0x10000)`** — 32,768 words each = **743.0 ms** at 44.1 kHz. No address the firmware ever writes reaches 2¹⁶ (max **64,899**). | **MEASURED**, 870 cells over 100 algorithms |
| **P6** | Each DRAM-access word consumes **one** cell from an **auto-incrementing descriptor cursor**, in program order. The count identity `cells == DRAM words` holds for **88 of 96** algorithm slots outright and the full 96-equation system is **consistent with zero residual**. | **MEASURED** + **FORCED** within the counting model (§6) |
| **P7** | `addr8 = 0x30` marks the **first** DRAM access of a body — **37 of 38** distinct images. | **MEASURED** |

**Validated end to end on a named parameter** (§7): `SINGLE DELAY` UI slot 0 is
`DELAY L (ms)`; it drives descriptor cell `0x26` through op 0x67 with base
`K = 0x000002`; the ROM ships that cell as **15,435**, and
`350 ms × 44100/1000 = 15,435` exactly. Its right channel is
`cell 0x28 − cell 0x2B = 31,370 − 15,935 = 15,435` — **the same 350 ms out of a
different base**. `ENHANCER` carries the literal **350** in its own parameter
bytecode against descriptor cells reading `2 + 350×44.1 = 15,437` exactly.

**What is still OPEN:** the *phase* of the cursor (what reloads it per unit), the
per-word READ/WRITE assignment once the cursor is taken into account (§6.3 —
this **contradicts** the `addr8`-selects-direction annotation), and `N`, the width
of the global rotation, which the KN5000 firmware cannot settle because it never
uses more than 16 bits of it (§8).

---

## 1. The writer — PROVEN BY CONSTRUCTION

`r3_delaydram.py writer`. Sub CPU v1.42, `LABEL_038922`:

```
   LABEL_038922(XBC = value, WA = sub-index, arg+0Ch = BASE32, arg+10h = cell base)

     emit  08 01 <NN>>4 & 0F> <(NN & 0F)<<4 | 8> 25      NN = arg(+10h) + WA
                                    == the instruction word  801.0.NN.825
     v = XBC + arg(+0Ch)                                 <- ADD (XSP+002h), XWA
     emit  0A  (v>>17)&7F  (v>>9)&FF  (v>>1)&FF  ((v&1)<<7)|4C
```

Two things fall straight out.

*(K3, running concurrently, reaches "`0x825`'s space is the tag-`0x4C` space" by
elimination and labels it INFERRED. R3 upgrades that to **PROVEN BY
CONSTRUCTION** and names the space: it is the delay-DRAM descriptor bank.)*

**(a) The destination.** `801.0.NN.825` is the same encoding
`analysis/k5-output-stage.md` §1.2 proved for `ldptr` (`(P>>4)` into byte 2's low
nibble, `(P&0xF)<<4` into byte 3's high nibble). So the packet run that follows is
addressed by the register whose in-word `lo12` is `0x825`, and its packets carry
tag `0x4C` — precisely the pairing `instruction-set.md` already records for the
host stream (`0x26 ↔ …821`, `0x4C ↔ …825`). **`…825` is the delay-descriptor
pointer.** The C-RAM coefficient bank and the delay-address bank are the *same
mechanism* on two different pointers.

**(b) The value.** The four payload steps are, instruction for instruction,
`LABEL_0387E6`'s; only `ADD XWA, 0000004Ch` differs from `ADD XWA, 00000026h`.
Since the coefficient writer's payload is a 24-bit Q0.23 word, this one's payload
is a 24-bit word in the same packing.

**MEASURED, and it closes the search space:** `CALL LABEL_038922` occurs **exactly
once** in the 192 KB image. It sits in one handler of the level-2 parameter
translator's jump table, the handler for **opcode 0x67**. The two other writers
that dispatcher can reach, `LABEL_038539` and `LABEL_03846C`, both tag their
packets `0x15`. **Op 0x67 is the only path in the firmware that can write a delay
descriptor.** Nothing else has to be searched.

The scaler op 0x67 feeds is `LABEL_03925E`:

```
   K   = LABEL_03CF07(stream) >> 8         ; a 24-bit big-endian literal, 3 bytes
   ret = (ms * 0xAC44) / 0x3E8  +  K       ; 0xAC44/0x3E8 = 44100/1000
```

`LABEL_03CF07` reads three stream bytes into bits [31:8]; the `>>8` in the scaler
turns them back into a plain 24-bit big-endian integer. So the operand is a
24-bit constant and it is added to a **sample count**.

---

## 2. The payload is the POKE value — a FALSIFICATION

> `r1-allpass-motif.md` §3: *"Taken raw the payloads are 17-bit word addresses.
> The host-poke decode of the same 5-byte packet would give `(payload<<1)|(sel>>7)`,
> one bit wider, and the `sel` byte does alternate 0x4C/0xCC exactly as an LSB
> would. **17 vs 18 delay address bits remains OPEN**."*

It is not open, and the raw reading is wrong. §1(b) proves the packing by
construction; three independent measurements confirm it.

**(a) The firmware's own base constant.** ROOM REVERB's op-0x67 literal is
`K = 0x008002 = 32,770`. Its descriptor cell `0x03` — the cell every reverb sets
to the region floor — reads **32,768 = 0x8000** under the poke decode, i.e.
exactly `K − 2`, and **16,384 = 0x4000** under the raw decode, which is nothing in
particular. A firmware constant `0x8002` against a cell of `0x8000` is not a
coincidence; against a cell of `0x4000` it is unexplained.

**(b) The pre-delay comes out right.** `cell 0x00 − cell 0x03 = 33,568 − 32,768 =
800 samples = 18.1 ms` for ROOM REVERB 1 — a textbook room pre-delay, and the
twelve presets spread over 20 / 500 / 800 / 1000 / 2000 samples (0.45 → 45.4 ms),
every one a round number of samples above the region floor.

**(c) The multi-line residue test** (§4) is the decisive one: four delay lines,
four *different* base constants, one shared default delay. It only works under the
poke decode; under the raw decode three of the four residues are **negative**.

```
   payload = (b1 & 0x7F)<<17 | b2<<9 | b3<<1 | b4>>7
           = 2 * (b1<<16 | b2<<8 | b3)  +  (tagbyte >> 7)
```

which is *why* the tag byte alternates `0x4C` / `0xCC`: **bit 7 of the tag byte is
the payload's LSB**, exactly as R1 suspected but did not adopt.

**Consequence, and it is not small: every delay length in the tree is half of what
it should be.** R1 §2/§3, `algorithms/reverb.md`, `notes/kn5000-dsp-reverb.md` and
`notes/kn5000-dsp-coefficients.md` all quote the raw numbers. ROOM REVERB 1's
ladder is **255 / 869 / 979 / 366 / 1044**, not 127 / 435 / 489 / 183 / 522; its
pre-delay is **8,905** samples, not 4,452. The corrected table for all twelve
presets is printed by `r3_delaydram.py validate` and reproduced in §7.3.

*(R1's all-pass solve is unaffected: it constrains only the read/write line
**offset**, never a delay value. Its §6 numeric verification uses the delays as
opaque line lengths, and an all-pass ladder is exact for any positive integer
delay.)*

---

## 3. The level-2 parameter chain — MEASURED

Three 100-entry pointer tables drive it, two of them not previously used in this
tree:

| table | contents |
|---|---|
| `0x0001ED7C` | microprogram streams (already known: `ALGO_TABLE`) |
| `0x0001EF0C` | coefficient / descriptor streams (already known: `PARAM_TABLE`) |
| **`0x0001F09C`** | **T1** — one length-prefixed record per **UI parameter slot**: `op idx <operand bytes> 0x7A` |
| **`0x0001F22C`** | **T2** — `op → ordered list of destination indices` |

`DSP_PerParameterTranslator` (`0x03CB18`) walks T1; for each `(op, idx)` it calls
`LABEL_03CF53` to find `T2[op][idx]`, and that byte becomes the destination the
writer adds to its per-unit base. Opcodes `0x61…0x79` index `OFFSETS_14745`;
counting the handlers in listing order puts the `LABEL_03925E → LABEL_038922`
pair at **0x67**, which is independently confirmed by what its destinations are.

For every algorithm in the ROM, `T2[0x67]` is a list of **descriptor cell
indices** and `T1`'s operand is the **line base**:

```
   algo effect               UI slot  cell   K24 (base)  ROM default cell
   9    SINGLE DELAY         0        0x26   0x000002    15435      DELAY L (ms)
   9    SINGLE DELAY         1        0x28   0x003FE0    31370      DELAY R (ms)
   10   MULTI TAP DELAY      0..3     0x26   0x000002    6000       DELAY 1..4 (ms)
                                      0x28   0x000002    12000        -- one line,
                                      0x29   0x000002    18000        -- four taps
                                      0x2A   0x000002    24000
   16   ROOM REVERB 1        1        0x00   0x008002    33568      PRE DELAY (ms)
   65   S.DELAY+S.DELAY      1        0x26   0x000002    7000
                             6        0x28   0x001FE1    15159
                             2        0x2A   0x003FE0    23350
                             7        0x2C   0x005FC1    31509
```

The UI slot numbers land on exactly the parameters `notes/kn5000-dsp-paramlist.md`
captured **live** from the LCD: slot 0/1 of SINGLE DELAY are `DELAY L (ms)` /
`DELAY R (ms)`, slots 0–3 of MULTI TAP DELAY are `DELAY 1–4 (ms)`, slot 1 of every
reverb is `PRE DELAY (ms)`. **Every ms-valued parameter in the instrument that is
a delay time uses op 0x67, and nothing else does.** That is a complete census, not
a sample: 38 sites over 16 algorithms, printed by `r3_delaydram.py level2`.

*(An earlier pass, `notes/kn5000-dsp-paramsemantics.md` §Headline 2, had already
noted "SINGLE DELAY `DELAY L/R → 0x26/0x28` (`op67`, ms→samples)". What is new
here is that the operand is the **line base address**, that the cell is an
**address** and not a length, and the whole model that follows from it.)*

---

## 4. The residue test — MEASURED, and it is the proof of P3

`r3_delaydram.py residue`.

If a cell held a *length*, the base constant `K` would be irrelevant to it. If it
holds `base + delay`, then in any effect whose several delay lines ship with one
shared default delay, `cell − K` must come out **equal** although the bases are
not. Getting one number out of four different constants is the whole argument.

```
   algo effect               cell-K per line (samples)      bases  verdict
   64   S.DELAY+CHORUS         3998   3998                  2      AGREE      90.66 ms
   65   S.DELAY+S.DELAY        6998   6998   6998   6996    4      AGREE     158.68 ms
   66   S.DELAY+FLANGER        7998   7998                  2      AGREE     181.36 ms
   67   S.DELAY+VIBRATO        7998   7798                  2      differ by 200
   68   S.DELAY+PHASER         7998   7998                  2      AGREE     181.36 ms
   70   AUTO WAH+S.DELAY       7998   7998                  2      AGREE     181.36 ms
   72   PEQ+S.DELAY            7998   7998                  2      AGREE     181.36 ms
   98   PEQ+DIST+DELAY         7998   7998                  2      AGREE     181.36 ms
   99   PEQ+OVERDR+DELAY       7998   7998                  2      AGREE     181.36 ms
    9   SINGLE DELAY          15433  15018                  2      differ by 415
```

**8 of 10.** The two that differ differ *slightly and deliberately* — S.DELAY+
VIBRATO ships its right channel 200 samples (4.5 ms) shorter, SINGLE DELAY ships
415 samples (9.4 ms) shorter — which is what a stereo delay does. Nothing is off
by a base. MULTI TAP DELAY is excluded from the count because all four of its taps
carry `K = 2`: they are **four taps on one line**, and their residues are
correspondingly four different tap times (5998 / 11998 / 17998 / 23998). That is
the model working, not failing.

The same computation on the raw decode, algo 65: `[3498, −4677, −582, −8759]`.

---

## 5. The delay-memory map — MEASURED

`r3_delaydram.py regions`. Over all 100 algorithms, 870 descriptor cells:

```
   unit 0  (bodies loaded at I-RAM 84 — 79 of the 91 valid streams)
           descriptor cells 0x26 .. 0x39      addresses [0, 32768]
   unit 1  (the twelve reverbs, bodies at I-RAM 200 — the other 12)
           descriptor cells 0x00 .. 0x1F      addresses [32768, 64899]
```

The two ranges do not overlap anywhere, in any algorithm. The op-0x67 base
constants say the same thing arithmetically, and say more — they show the
firmware **partitioning a 0x8000-word region by powers of two**:

```
   K = 0x000002 = 0x0000 + 2      unit-0 line 0        ] two lines:  /2
   K = 0x003FE0 = 0x3FDE + 2      unit-0 line 1        ]
   K = 0x001FE1 = 0x1FDF + 2      unit-0 line 1 of 4   ] four lines: /4
   K = 0x005FC1 = 0x5FBF + 2      unit-0 line 3 of 4   ]
   K = 0x008002 = 0x8000 + 2      unit-1 (reverb) base
```

`0x0002 / 0x3FE0` halve `[0, 0x8000)`; `0x0002 / 0x1FE1 / 0x3FE0 / 0x5FC1` quarter
it. The constant `+2` is a **minimum-delay guard**: at `ms = 0` a line still reads
two samples behind its write pointer.

**Each effect unit therefore owns 32,768 delay-memory words = 743.0 ms at
44.1 kHz.** That is a hard prediction about the instrument: no delay time on this
machine can exceed 743 ms, and a two-line effect is capped at half that (371 ms)
per line, a four-line effect at a quarter (185 ms).

The static blocks confirm the floors and ceilings directly: SINGLE DELAY writes
`0` and `32768` into two of its six cells, MULTI TAP DELAY writes `0` and `32768`,
every reverb writes `32768` (its floor) and `32767` (the top of unit 0's region,
one below).

### 5.1 Why there are no ring-bound registers

Nothing in the descriptor stream is a length, a mask or a wrap limit — every cell
is an address, and the delays are differences. The cheap hardware that behaves
this way is a **single global rotation**: a counter `G` advanced once per sample
over the whole memory, with every access at `(cell + G) mod 2^N`. Data written at
time *n* to `W + G(n)` is found at time *n+D* at `(W−D) + G(n+D) = W + G(n)`, so a
tap at distance *D* is simply the cell `W − D`… which is exactly the sign the
reverb ladder shows (§7.3: the read cell of a stage sits **below** its write cell
by the delay). One counter, no per-line state, and lines never collide as long as
their bases are further apart than the longest delay — which is precisely why the
`K` constants are spaced `0x2000` / `0x4000` apart and why the max delay is
bounded by that spacing. **INFERRED** (it is the simplest mechanism consistent
with every measurement; a per-line auto-incrementing pointer would fit the numbers
too, but would need bounds registers that the firmware never writes).

---

## 6. The descriptor cursor — MEASURED

`r3_delaydram.py cursor`.

### 6.1 The counting identity

There is no field in a `880.1.**` word that can name one of 58 descriptor cells:
SINGLE DELAY's six DRAM words use only four distinct encodings, yet address six
distinct cells. So the cell must come from an **implicit cursor**, exactly as the
coefficient cell comes from the implicit coefficient cursor.

If that is right, the number of cells an algorithm ships must equal the number of
words that consume one. Taking "class-4 == 1 with the `hi12` FORMAT-ESCAPE bit
set" as the candidate family, the identity holds outright for **88 of 96**
algorithm slots.

Rather than argue about the eight, the question was posed as a linear system: 96
equations (one per algorithm), one unknown per distinct class-1 word form (37),
"how many cells does this form consume". Exact rational elimination:

```
   96 equations, 37 unknowns, rank 26, INCONSISTENT ROWS: 0
   solutions with every unknown in {0,1}: 8
```

**Consistent with zero residual** — the counting model is not merely a good fit,
it is exactly satisfiable. Across all eight {0,1} solutions:

* **20 forms consume exactly one cell in every solution** — every `880.1.20.*`,
  `880.1.30.*`, `880.1.60.*` and `900.1.60.*` form, plus `C40.1.80.000`;
* **11 forms consume nothing in every solution** — and every one of them is an
  END-OF-BLOCK / transfer word (`*.1.0E.*`, `612.1.0E.000`) or `C40.1.E0.451`.
  The solve was never told which words were control transfers; it separated them
  by itself. It also **independently corroborates R2's withdrawal of K6's
  "class-1 `addr8` splits on bit 7"**: `C40.1.80.000` has `addr8 ≥ 0x80` and
  **does** consume a cell, while `C40.1.E0.451` does not — so bit 7 is not the
  discriminator, and R2's `hi12` bit 11 is the predicate used throughout here;
* **6 forms are not decided by counting**: `612.1.0F.000`, `800.1.20.1D5`,
  `880.1.20.2D9`, `880.1.20.40B`, `880.1.60.40E`, `900.1.60.2D9`. **ENUMERATED,
  not picked.**

### 6.2 The order is program order

(The DRAM family is selected by **R2's predicate** — `class4 == 1` with `hi12`
bit 11 set, 324/324 — not by K6's withdrawn `addr8 < 0x80` split. Every result in
this section is identical under either, because the three `addr8 ≥ 0x80` forms
never sit first in a body.)

Aligning the cells of a block with the DRAM words of the body **in program order**
puts the op-0x67-written cells on the right words. SINGLE DELAY, MULTI TAP DELAY,
S.DELAY+S.DELAY and all twelve reverbs place their `DELAY …(ms)` /
`PRE DELAY (ms)` cell on the body's **first** DRAM word (or on the word the tap
belongs to, for the multi-tap). Independently, **`addr8 = 0x30` is the first DRAM
word of the body in 37 of 38 distinct images** (the exception is ENSEMBLE, which
is also the one image whose extra `800.1.20.1D5` words the solve leaves
undecided) — the natural reading of a *load / reset the cursor* bit.

Worked example, ROOM REVERB 1's ladder 0, cells against words:

```
   w19  880.1.60.2D4  ->  cell 0x03 = 32768   the region floor
   w23  880.1.20.655  ->  cell 0x04 = 41845
   w27  880.1.60.2D4  ->  cell 0x05 = 41590      41845 - 41590 =  255
   w31  880.1.20.655  ->  cell 0x06 = 42201
   w35  880.1.60.2D4  ->  cell 0x07 = 41673      42201 - 41673 =  528
   w39  880.1.20.655  ->  cell 0x08 = 42714
   w43  880.1.60.2D4  ->  cell 0x09 = 41845      42714 - 41845 =  869
   ...
```

The alternation of R1's FORCED read/write pair lands on an alternation of cells
whose successive differences are the diffuser delays — and R1's two interleaved
chains fall out of the *same* interleaving in the cell file. That is a
non-trivial cross-check between two passes that used completely different
evidence.

### 6.3 What the cursor CONTRADICTS — and it matters

MULTI TAP DELAY is the awkward case, and it is reported rather than smoothed over.
Its four `DELAY n (ms)` cells are `0x26 / 0x28 / 0x29 / 0x2A`, and in program order
those are words `w0 (880.1.30.00B)`, `w12 / w16 / w20 (880.1.20.2C7)` — so **three
of the four tap READS sit on `addr8 = 0x20` words**, while the one word that lands
on the line base (`cell 0x2C = 0`, the write pointer) is `w66
(880.1.60.000)`, an `addr8 = 0x60` word.

Under the cursor model, then, **`addr8` does not select the DRAM direction.**
That is a *constraint*, not a decode, and it points the same way
`instruction-set.md` already cautions ("that `addr8` alone selects the direction
is **INFERRED**, proven only for the two rows") and the same way R1 §7.1's caveat
points: `880.1.20.2C7` is store-preceded **0 of 40 times** against a 23.3 % base
rate, and R1 flagged that it "may not be a write at all". The cursor alignment
says it is a **READ**. Three consequences, all of them for other people's items:

1. R1's O-1 discriminator loses its negative half. If `2C7` and the other three
   0 %-forms are reads, then only the 44/44 positive half of the store→write
   pairing carries information, exactly as R1's own caveat allowed.
2. The disassembler's `880.1.60` = read / `880.1.20` = write annotation is
   **not** safe to generalise beyond `2D4` / `655` / `64B`.
3. Whatever selects direction must be in `lo12` or `hi12` — which is the same
   conclusion R1 reached from the ALU side (`lo12` selects the operand route).

**OPEN**: the cursor's *phase*. Unit-0 bodies start at cell `0x26`, unit-1 bodies
at `0x00`, but the shared kernel loads `801.0.25.825` — the same `0x25` — in
*both* per-unit setup blocks (I-RAM 44 and 52), which cannot produce two different
bases. Enumerated, none chosen:

* **(i)** `…825` in-program *is* the cursor with pre-increment, and unit 1's copy
  is dead or overridden — `0x25 → 0x26` is exactly right for unit 0;
* **(ii)** `…825` in-program is a **different register** from the host-window
  `…825`. *This option is now weak*: the precedent it rested on — K6's "the two
  meanings of `…821` cannot be the same space" — has itself been withdrawn by K3,
  which shows they *are* the same space and that the argument conflated the C-RAM
  *pointer* with the C-RAM *cursor*;
* **(iii)** the file is 64 cells split per unit — unit 1 `0x00..0x1F`, unit 0
  `0x20..0x3F` — with the cursor reset by the unit tag on the CALL word, the
  header's own two consuming words taking `0x20..0x25`'s slack, and the `0x30`
  sub-op reloading it at each body entry.

(iii) is the only one that explains both bases and the `0x20`-aligned allocation,
and it predicts the highest cell index in use is below `0x40`; the MEASURED
maximum is **`0x39`**. It is *not* proven, because the header's consuming-word
count (2, or 3 if `800.1.60.00B` also consumes) does not reach 6.

---

## 7. The ms → address chain, validated

`r3_delaydram.py validate`.

### 7.1 SINGLE DELAY, `DELAY L (ms)` — the named-parameter validation

```
   UI parameter   SINGLE DELAY slot 0 = "DELAY L (ms)"    (paramlist.md §3,
                                                           captured live off the LCD)
   level-2 op     0x67, idx 0, K24 = 0x000002
   destination    T2[0x67][0] = descriptor cell 0x26
   chain          cell = 0x000002 + ms * 0xAC44 / 0x3E8

   ROM default of cell 0x26                       = 15435
   350 ms * 44100 / 1000                          = 15435     EXACT
```

and its right channel, out of a different base:

```
   cell 0x28 = 31370      cell 0x2B = 15935 (line R's base)
   31370 - 15935 = 15435  =  the same 350 ms
```

Honest note: the static block is authored as `base + N` with `N` a round *sample*
count, so it omits op 0x67's `+2` guard; the runtime writing the same 350 ms
produces 15,437. A two-sample (45 µs) difference between the boot image and the
first parameter refresh.

### 7.2 ENHANCER — an independent hit on the same constant

ENHANCER's UI carries `DELAY L (ms)` / `DELAY R (ms)`; its level-2 stream carries
the **literal 350** (`00 01 5E`), and its descriptor cells `0x28` and `0x2D` both
read **15,437 = 2 + 350 × 44100/1000**, exactly. Stated with its limit:
ENHANCER's runtime opcode is `0x64` (tag `0x15`), not `0x67`, so this validates
the **formula the authoring tool used**, not a live write path. It is quoted
because the number 350 appears *literally in the firmware* next to a cell that is
`350 ms` under the model and nothing under any other.

### 7.3 The corrected delay tables

Reverb `PRE DELAY (ms)`, cell `0x00`, base `0x8002`, floor cell `0x03 = 0x8000`:

| preset | samples | ms |
|---|---|---|
| ROOM REVERB 2 | 20 | 0.45 |
| CONCERT REVERB 1 | 500 | 11.34 |
| ROOM REVERB 1 | 800 | 18.14 |
| CONCERT REVERB 2, BRIGHT REVERB 1/2 | 1000 | 22.68 |
| PLATE 1/2, DARK 1/2, WAVE 1/2 | 2000 | 45.35 |

Diffuser ladders, **corrected to the 24-bit payload** — R1 §2 and
`algorithms/reverb.md` quote exactly half of every one of these:

```
   preset             ladder 0                          ladder 1
   ROOM REVERB 1        255   869   979   366  1044       528  1252   359   675
   ROOM REVERB 2        510  1740  1878   734  2088      1057  2505   639  1351
   PLATE REVERB 1       904  2181  3095  1382  2747      1676  3569  1112  1948
   PLATE REVERB 2      1609  1576  2895  3339  2190      2281  2664  3269  2548
   CONCERT REVERB 1     904  1957  2154  1382  1578      1276  2924   992  1548
   CONCERT REVERB 2     904  1971  3095  1382  4747      1276  3359  1512  2748
   DARK REVERB 1        904  1981  3095  1382  4747      1276  3169  1712  2748
   DARK REVERB 2        904  1981  2695  1382  4747      1276  3169  1312  2748
   BRIGHT REVERB 1     2664  2743   935  1382  1985      2038  1609  1112  2148
   BRIGHT REVERB 2      904  1981  2895  1382  4747      1276  3169  1512  2748
   WAVE REVERB 1        904  2981  8295  1382  4347      1676  4169  6512  2548
   WAVE REVERB 2        904  2781  6295  1382  4147      1676  3969  4512  2348
```

(5.8 → 188 ms — the range a diffuser network wants. The raw reading gave 2.9 →
94 ms, which is short for the long stages.)

### 7.4 The controls — every one must fail

`r3_delaydram.py controls`. Each perturbs exactly one decision.

```
   algo 65 S.DELAY+S.DELAY
      (unperturbed)                    [6998, 6998, 6998, 6996]      spread     2
      payload read as raw 3 bytes      [3498, -4677, -582, -8759]    spread 12257
      K stripped of its region base    [6998, 15190, 6998, 23380]    spread 16382
      cell<->line assignment rotated   [23348, -1193, 23348, -17513] spread 40861
   algo 9 SINGLE DELAY
      (unperturbed)                    [15433, 15018]                spread   415
      payload read as raw 3 bytes      [7715, -667]                  spread  8382
      K stripped of its region base    [15433, 23210]                spread  7777
      cell<->line assignment rotated   [31368, -917]                 spread 32285
```

And the counting identity, over the **40 distinct body images** (the 42
NO-OPERATION clones counted once; 38 of the 40 contain at least one DRAM access),
matched against a *different* image's descriptor block:

```
   unshifted            32 of 40          <- 80 %
   shifted by 1         12 of 40
   shifted by 2          8 of 40
   shifted by 3          6 of 40
   all mismatched pairs 178 of 1560       <- 11.4 %, the chance baseline
```

---

## 8. 17 versus 18 delay address bits — the honest answer

Three separate questions were being run together.

**The firmware side — MEASURED, and it settles the only version that matters for
emulation.** Across 870 descriptor cells in 100 algorithms, the largest address
the KN5000 ever writes is **64,899**. The whole delay map is
`[0x0000, 0x10000)`, split evenly between the two units. **Bits 16 and 17 are
never set by this firmware.** Whatever the register width is, a KN5000 emulation
needs 16 bits and a `mod 2^N` that is never exercised above `N = 16`.

**The transport side — PROVEN BY CONSTRUCTION.** The packet carries a **24-bit**
payload in the coefficient writer's packing. The host path imposes no 17/18 limit
at all; it was only the *raw three-byte misread* that made 17 look like a
candidate. That framing of the question is void.

**The hardware side — INFERRED, and "nine address lines" was a red herring.**
IC309 is an `M5M44260AJ-7S`, a 4-Mbit DRAM in the ×16 organisation — 262,144 words
of 16 bits. A 256K×16 DRAM has **multiplexed** row and column addresses: nine
lines carry 9 row + 9 column bits = **18 address bits**. So "only DSP1A0..DSP1A8
reach it, A9..A16 are unconnected" is not evidence of a 9-bit or 17-bit address —
it is what a correctly wired 4-Mbit ×16 DRAM looks like, and `MD1-MD4 = 0b1111` is
the DSP's matching memory-configuration strap. *(INFERRED from the part number and
standard DRAM practice; no `M5M44260` datasheet was in hand.)*

That leaves the device four times larger than the firmware's 65,536-word map.
**ENUMERATED, not picked:**

* **(a)** the chip addresses 2¹⁸ delay words of 16 bits and the KN5000 simply uses
  a quarter of the device — plausible for a part shared with the Pioneer CDJ-500,
  whose ECHO is seconds long;
* **(b)** a delay word occupies two DRAM words (a 24- or 32-bit sample stored as
  2 × 16), so 65,536 delay slots consume 131,072 DRAM words — half the device;
* **(c)** the two effect units on the chip have separate 2¹⁷ halves and what looks
  like one 2¹⁶ map is one unit's half used twice over.

Nothing in the ROM distinguishes them; it takes a scope on the DSP1A lines, or the
datasheet.

**And a claim that is now falsified.** `notes/kn5000-dsp-coefficients.md` §3 lists
FLANGER taps of **140,800** and **153,600** "exceeding A16", with
`notes/dsp-audiopath-wiring.md` citing them as weak evidence for an 18-bit
address. They are not delay addresses. The complete set of delay addresses this
firmware can produce is the tag-`0x4C` descriptor stream, whose maximum over the
entire ROM is **64,899**; FLANGER's actual descriptor cells are
`{0, 100, 1000, 1100, 2113, 32768}`. Those two numbers come from the separate
mode-`0x0B` parse, which the note itself already flagged as "probably a sweep
range" — it is, and the 18-bit argument built on them should be withdrawn.

---

## 9. What this constrains for the concurrent ALU work

Relayed explicitly, per the brief.

1. **Every delay length doubles.** Any model, listing or test that consumes R1's
   delay numbers (`127 435 489 183 522`, `4452`, the chorus `200/520`, …) must use
   twice them. R1's *solve* is unaffected — it never uses a delay value — but its
   §6 ladder verification and any downstream algorithm reconstruction are.
2. **`addr8` does not select DRAM direction** (§6.3). The MULTI TAP DELAY
   alignment puts tap reads on `880.1.20.2C7` and the line write on
   `880.1.60.000`. If direction lives anywhere it lives in `lo12`/`hi12` —
   consistent with R1 F8's "`lo12` selects the multiplicand route".
3. **R1 O-1 is *half* settled, in the direction R1 itself hedged.** `880.1.20.2C7`
   reading as a READ removes the 0/56 arm of the store→write discriminator, so
   family B is ranked on the 44/44 arm alone. It neither closes O-1 nor breaks it.
4. **The ALU never sees an address.** The descriptor cell is fetched by the DRAM
   sub-unit from a host-written bank via an implicit cursor; no ALU register, no
   `mem[ptr]`, no accumulator is involved. Address generation can be modelled
   completely independently of the arithmetic, which is good news for both
   workflows.
5. **Two corroborations of the concurrent passes, from a different direction.**
   The cell-consumption solve separates the control-transfer words from the DRAM
   words without being told which is which, and it puts `C40.1.80.000`
   (`addr8 = 0x80`) *in* the DRAM family and `C40.1.E0.451` (`addr8 = 0xE0`)
   *out* — independent support for **R2**'s withdrawal of K6's `addr8` bit-7
   split in favour of `hi12` bit 11. And **K3**'s INFERRED "`0x825` addresses the
   tag-`0x4C` space" is here PROVEN BY CONSTRUCTION, with the space identified.
6. **A concrete testable prediction for a future core:** the read tap of an
   all-pass stage sits **below** its write pointer by exactly the delay, so the
   global rotation must be *incrementing* if addresses are `cell + G`. Get the
   sign wrong and the reverb tail is silent, not merely wrong.

---

## 10. Open, and what would settle it

| # | question | what settles it |
|---|---|---|
| O-1 | the cursor's per-unit phase — which register/event resets it (§6.3 (i)/(ii)/(iii)) | decoding `lo12 = 0x825`'s in-program meaning, or a live trace of the DSP1A lines |
| O-2 | the per-word READ/WRITE assignment once the cursor is applied (§6.3) | decoding any one more `880.1.20.*` / `880.1.60.*` form; or the impulse response R1's O-1 also wants |
| O-3 | the 6 forms the counting solve leaves undecided (§6.1) | one more algorithm using them in a different mix; none exists in this ROM |
| O-4 | `N` in `mod 2^N`, and options (a)/(b)/(c) of §8 | the `M5M44260` datasheet, or a scope |
| O-5 | whether the global rotation increments or a per-line pointer does (§5.1) | the same |
| O-6 | the reverb's cells `0x18..0x1F` (its early-reflection block) — the op-0x67 list names seven cells but only one T1 record uses it | decoding the reverb body's separator words (R1 O-4) |

---

## 11. Reproducing

```
python3 dsp/tools/r3_delaydram.py                 # all sections, ~30 s
python3 dsp/tools/r3_delaydram.py writer payload  # §1 and §2
python3 dsp/tools/r3_delaydram.py level2 residue  # §3 and §4 -- the proof
python3 dsp/tools/r3_delaydram.py regions cursor  # §5 and §6
python3 dsp/tools/r3_delaydram.py validate controls   # §7
python3 dsp/verify.py                             # the tree still byte-matches
```

Inputs: `original_ROMs/kn5000_subprogram_v142.rom` (microcode, parameter streams
and both level-2 tables), `original_ROMs/kn5000_v10_program.rom` (effect names),
and the ROM parsers in `~/compartilhado/kn7000_mame/tools` (`--tools`).

No `.dsm` was regenerated by this pass and no disassembler was changed, so
`dsp/verify.py` still reports BYTE-MATCH OK. What `tools/dsp_disasm.py` and
`src/devices/cpu/upd6383/upd6383d.cpp` *could* adopt — together, and not in this
pass — is in §9.
