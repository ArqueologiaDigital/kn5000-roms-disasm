# K3 — the pointer-register file

NEC **uPD6383GF-3BA** (Technics SX-KN5000, IC311). Roadmap item **K3**
(`kn7000_mame/notes/dsp-next-steps-roadmap.md`). Date: 2026-07-26.
Tool: [`../tools/k3_pointers.py`](../tools/k3_pointers.py) — stdlib only apart from
the ROM parser it borrows, re-runnable, prints every number quoted here:

```
python3 dsp/tools/k3_pointers.py                       # all six sections
python3 dsp/tools/k3_pointers.py census host spaces boundary
```

Every claim carries a label: **MEASURED** (read out of the ROM or a capture),
**PROVEN BY CONSTRUCTION** (the firmware builds the bytes and we read the
builder), **FORCED** (no other assignment survives the constraints),
**CONSISTENT**, **INFERRED**, **EDUCATED GUESS**, **OPEN**. Where the constraints
admit several assignments they are all enumerated; none is silently picked.

No hardware was available. Nothing here is a recording or a measurement on a
live chip; the two uC-IF captures were recorded earlier and are re-analysed.

> **Relation to R2 (`r2-output.md`, same day).** K3 and R2 were written in
> parallel and reached the host stream from opposite ends. **They converge**, and
> where they do, say so loudly: R2's finding 4 ("the mode-1 register index space is
> the same space the host addresses with `000.1.NN.000`") and K3 §2.2 are the same
> measurement made independently. Two things here are **new relative to R2** and
> bear on its findings 2 and 4: the `0B .. .. .. 15` packet form, which is why R2's
> census reads `0x50(0)` where there are in fact eight values there (§7 item 6);
> and the **PARAMETRIC EQ** capture, which fills `0x50..0x77` with **40** cells
> (§2.2). Where R2 is more recent and better evidenced than a K3 draft claim, R2
> wins and this note says so inline.

---

## 0. Result in one page

**The pointer registers are not a mystery register file any more — three of them
have a NAME, a WIDTH and a MEMORY SPACE, and the space assignment comes out of the
host's own memory map rather than out of an analogy.**

| # | statement | label |
|---|---|---|
| **A** | The register-load word is `hi12 = 0x801, class4 = 0, addr8 = payload, lo12 = 0x8**`. The payload is **exactly 8 bits at [19:12]**; `class4` is left 0 by the writer. **`lo12` bit 11 is built as a SEPARATE FLAG** on top of a low byte — the firmware literally does `INC 8, WA` into byte 3's low nibble. | **PROVEN BY CONSTRUCTION** |
| **B** | The **coefficient-cursor reset `801.0.00.021` is the same word with that flag CLEAR** — same `hi12`, same `class4`, same low byte `0x21`, payload 0. It is the only `hi12 == 0x801` word in the entire 2974-word body corpus. | **MEASURED** (1/1 pair) |
| **C** | The host only ever uses **three** register-set forms — `801.0.PP.821`, `801.0.PP.825`, `000.1.PP.000` — with coefficient tags `0x26`, `0x4C`, `0x15`. Confirmed over 1012 packets in two captures; there is no fourth. | **PROVEN BY CONSTRUCTION** (five writers) + **MEASURED** |
| **D** | Those three tags are **three DISTINCT memory spaces**. In the PARAMETRIC EQ capture they share 62 / 37 / 31 cells pairwise and **61 / 37 / 31 of those shared cells end the capture holding different values**. One cell cannot hold two values. | **FORCED** |
| **E** | ★ **`lo12 = 0x821` is a C-RAM pointer, and the in-program word means the SAME thing as the host word.** Its three in-program payloads are `0x70` (unit 0), `0x50` (unit 1), `0x90` (output stage) and **all three are exact structural bases of the host's C-RAM map** — `0x50` and `0x70` are the two tap tables (32 and 28 entries), `0x90` is the reverb coefficient bank. The mechanically-derived boundary set has **4 members out of 256**. | **MEASURED**, P ≈ 4e-6 under a uniform null |
| **F** | ★ **`0x821` is NOT the implicit coefficient cursor.** If it were, the unit-0 body's cursor would start at `0x70` and CHORUS's second class-A word `094.A.00.200` — the LFO-wrap consumer, 29/29 corpus-wide — would read `C-RAM[0x71] = 0x0004BE` instead of the wrap constant `0x7FFFFF`, which the host puts at `C-RAM[0x01]`. **The C-RAM therefore has at least two independent pointers**: the implicit cursor and `0x821`. | **FORCED** |
| **G** | ★ **K6's headline 11 is FALSIFIED as stated.** "The host-window and in-I-RAM meanings of `801.0.NN.821` cannot be the same space" is not a consequence of the measurements; it followed from an unstated premise (that the I-RAM form sets the *cursor*). Both meanings are C-RAM. See §6. | **FALSIFICATION** |
| **H** | `lo12 = 0x825`'s space is the tag-`0x4C` space: its in-program payloads are `0x25`/`0x25`/`0x26` and the tag-`0x4C` map has exactly **two** boundaries, `0x00` and `0x26`. | **INFERRED (strong)** |
| **I** | The tag-`0x15` space — R2's **mode-1 register file**, same space, independently confirmed — also holds a **per-algorithm block at `0x50..`, sized to the algorithm**: PARAMETRIC EQ fills **40 cells, `0x50..0x77`, all zero** = 5 bands × 2 channels × 4 Direct-Form-I state words; CHORUS fills **8**, `0x50..0x57`, as four `(value, 0)` pairs. Whether that block is *state* or *parameters* is enumerated in §2.2. | **MEASURED** (n = 2 algorithms, one of them SOLVED) |
| **J** | **At least three** pointer registers exist and at least two of them carry **per-unit** values: the header sets `0x821`/`0x827`/`0x825` back to back with no word between them, and repeats the identical triple for unit 1 with *different* payloads for `0x821` and `0x827`. A dead load is not parameterised per unit. | **FORCED** (given the kernel is live) |
| **K** | "No effect body loads a pointer" **re-verified and refined**: `lo12 ∈ {820,821,822,825,827}` is **0 / 2974**; the *only* two body words in the whole `0x_2x` selector block are `algo39 w58 = 801.0.00.021` (the cursor reset) and `algo00 w18 = 80B.0.00.839`. | **MEASURED** |
| **L** | The disassembler's C-format predicate `(hi12 & 0xF00) == 0xC00` is **wider than the evidence for it**. The "imm13 is always a multiple of 32" rule is **57/57 inside `(hi12 & 0xFFE) == 0xC40`** (61/61 counting the four host-written `setvec` values, which reconciles K5's number exactly) and **2/11 outside it**. The five `lo12 = 0x820` words are in the "outside" set. | **MEASURED** |

**What K3 does NOT settle**, and says so: which architectural name (CP / DP / BP1 /
BP2 / PR1 / PR2) each selector is; whether `lo12` bit 11 is a mode bit on a shared
register field or simply part of a flat 12-bit destination code (§4); the space of
`0x827`, `0x822`, `0x820` and `0x839`, none of which the host ever writes through
(§5); and whether the *host* stream distinguishes three registers from one register
plus a three-way space selector — 1012 of 1012 packets carry the tag of the most
recently set pointer, so the captures cannot tell those apart (§3.4). The
*in-program* evidence can, and does (item **J**).

---

## 1. The word, byte by byte — PROVEN BY CONSTRUCTION

`k3_pointers.py builders` prints this; the source is
`archive/asl/subcpu/kn5000_subprogram_v142.asm`.

K5 found three DSP-word writers. There are **seven**, and the two new families are
the ones that matter:

| Sub CPU routine | 5 bytes pushed | = word | then a packet with tag |
|---|---|---|---|
| `LABEL_0387E6` | `08 01 (P>>4)&0F  ((P&0F)<<4)\|8  21` | `801.0.PP.821` | `0x26` |
| `LABEL_038922` | `08 01 (P>>4)&0F  ((P&0F)<<4)\|8  25` | `801.0.PP.825` | `0x4C` |
| **`LABEL_03846C`** | `00 00 10\|(P>>4)  (P&0F)<<4  00` | **`000.1.PP.000`** | **`0x15`** |
| **`LABEL_038539`** | idem | **`000.1.PP.000`** | **`0x15`** |
| **`LABEL_038CF9`** | idem, wrapped in its own uC-IF record | **`000.1.PP.000`** | **`0x15`** |
| `LABEL_0388B3` | — (packet only) | — | `0x26` |
| **`LABEL_038606`** | — (packet only) | — | **`0x15`** |

There is **no continuation writer for tag `0x4C`**: every `0x4C` value is preceded
by its own `801.0.PP.825`, which is why that space's host traffic is one-shot
parameter pokes rather than block uploads.

`LABEL_038CF9` is the one that shows the *transport*, and it settles a premise this
note's capture replay depends on. It emits, in order:
`DSP_DispatchCommand 1` · `01` · `60` · the five word bytes · the five packet
bytes · `DSP_DispatchCommand 3`. The `01 60` is the **16-bit I-RAM word address
`0x0160` = 352** — so "write a 36-bit word into I-RAM slot 352 and the chip
executes it" is not an inference from the capture, it is what the firmware
literally does. **PROVEN BY CONSTRUCTION.**

Every one of these routines has a second arm, `LABEL_038439`, taken when the
routine's chip argument `IZ == 1`. That arm emits `DSP_DispatchCommand 0x30` and a
**16-bit** value instead — i.e. it is the **DSP2 (MN19413, IC310)** protocol.
Cross-checked against the unit→chip table `0x01ED6D = {0,0,1,1,1}`: units 0 and 1
are on the uPD6383, units 2..4 on the MN19413. So **all five word forms above are
uPD6383-only**, and none of this transfers to DSP2. (**PROVEN BY CONSTRUCTION**.)

### 1.1 Three field facts fall straight out of the byte assembly

1. **`addr8` is exactly bits [19:12] and the payload is 8 bits.** The writer puts
   `(P>>4)&0x0F` into byte 2's *low* nibble — leaving byte 2's high nibble, i.e.
   `class4`, at **0** — and `(P&0x0F)<<4` into byte 3's *high* nibble. K5 already
   used this to pin the `class4|addr8` boundary; the new statement is that the
   payload **cannot be wider than 8 bits in this form**, because the writer
   hard-zeroes the nibble above it. C-RAM and D-RAM are 256 deep, so 8 bits is
   exactly enough and nothing is missing.
2. **`lo12` bit 11 is assembled as a separate flag.** `INC 8, WA` adds a literal 8
   to byte 3 *after* the address nibble is in place; byte 3's low nibble is
   `lo12[11:8]`. So the firmware builds `lo12 = 0x800 | 0x021` and
   `lo12 = 0x800 | 0x025`, not opaque constants `0x821` / `0x825`.
3. **The packet is `V = ((aa&0x7F)<<17)|(bb<<9)|(cc<<1)|(dd>>7)`, `tag = dd & 0x7F`** —
   K5's decode, re-read off all seven writers and confirmed.

### 1.2 The one pair that shows bit 11 is a *field*

`801.0.00.021` (`rstcur`) and `801.0.NN.821` (`ldptr`) differ **in exactly one
bit** of the whole 36-bit word. `hi12 == 0x801` occurs **9 times** in the corpus —
6 in the header, 2 in the output stage, and **exactly one** in the 2974 body words,
which is `algo39 w58 = 801.0.00.021`. There is no `801.0.00.821` anywhere in the
corpus (a note for anyone quoting the cursor reset from memory: the reset is
`…021`, and the `8` is precisely what this section is about).

---

## 2. What the host actually writes — the three maps

`k3_pointers.py host` replays both captures
(`kn7000_mame/notes/data/kn5000_dsp1_upload_{coldboot,parametriceq}.txt`).
The host window at I-RAM word **352** takes 5-byte words; **353** takes raw 3-byte
values that land at the current pointer of the register the last packet's tag
selected.

```
COLD BOOT (CHORUS on unit 0, ROOM REVERB on unit 1)
  tag 15 :  59 cells   05-07 0E 10-11 1D-40 50-57 85-87 8A-8B 94 D0-D2
  tag 26 : 117 cells   00-13 50-8B 90-B4
  tag 4C :  42 cells   00-1F 26-2F

PARAMETRIC EQ (algo 39 on unit 0)
  tag 15 :  99 cells   05-0C 0E 10-14 1D-40 50-77 85-87 8A-8B 94 D0-D2
  tag 26 : 128 cells   00-1E 50-8B 90-B4
  tag 4C :  52 cells   00-1F 26-39
```

### 2.1 tag `0x26` = C-RAM, and the map has exactly four structural bases

The value sequence, printed by the tool, tiles C-RAM cleanly:

| C-RAM | content | law |
|---|---|---|
| `0x00..0x1E` | the **unit-0 effect coefficient bank** | arbitrary |
| `0x50..0x6F` | **TABLE A**, 32 entries | `0x008000 + 1024·k`, ending `0x00FC00` |
| `0x70..0x8B` | **TABLE B**, 28 entries | `1214·k` saturating at `0x007FFF` |
| `0x90..0xB4` | the **unit-1 (reverb) coefficient bank** | arbitrary |

That the tag-`0x26` space *is* C-RAM is **MEASURED and independently
re-verified here**: the host writes 20 values at `0x00` (transfer 37), CHORUS's
first two class-A words are `092.A.00.200` (LFO phase accumulate, cursor `0x00`)
and `094.A.00.200` (LFO **wrap**, the consumer of `0x7FFFFF` in 29/29 corpus
occurrences, cursor `0x01`), and the host's values at `0x00`/`0x01` are
`0x000072` (an LFO rate: 0.6 Hz at 44.1 kHz) and `0x7FFFFF`. The join is exact.

The mechanically-derived boundary set (a block start, or the start of a ≥6-long
constant-delta run whose arriving delta differs — no hand picking, the definition
is in the tool) is **`{0x00, 0x50, 0x70, 0x90}`**, four cells out of 256, and it
is **identical in both captures**.

**`0x70` is not an artefact of packetisation.** The host wrote `0x6E..0x8B` in one
30-value transfer; `0x70` is the third cell of it. The boundary exists only in the
*data*. Whatever knows about `0x70` knows the table layout, not the packet layout.

### 2.2 tag `0x15` — R2's mode-1 space, and what else is in it

**The space identity is settled and is not K3's to claim**: R2 §1.2 measured that
the in-program mode-1 register indices and the host's `000.1.NN.000` addresses are
the same space, and it named the two per-unit output-level registers `0x06`/`0x86`
inside it. K3 reproduces that decode independently from the same capture and adds
nothing to it.

What K3 adds is **what else the space contains**, from two directions R2 did not
have:

1. **The `0B` packet form.** R2's census reads `0x50(0)` — a select at `0x50` with
   no values after it. There *are* values: they arrive in the previously unrecorded
   `0B .. .. .. 15` packet (§7 item 6), which R2's decoder, keyed on the `0A`
   leading byte, skipped. CHORUS's block is **`0x50..0x57`, 8 cells**, and it is
   four `(value, 0)` **pairs**: `0x000190, 0 / 0x0005A0, 0 / 0x0009B0, 0 /
   0x000DC0, 0` — 400, 1440, 2480, 3520, four values 1040 apart.
2. **A second capture.** In `kn5000_dsp1_upload_parametriceq.txt` the same block is
   **`0x50..0x77`, 40 cells, all zero**. Algo 39 is the SOLVED program:
   **5 bands × 2 channels × 4 Direct-Form-I state words = 40.** Exact.

So the block at `0x50` is **sized to the running algorithm's state footprint**.
Two readings, and this is a genuine open fork inside R2's finding 2:

* **I-a — the space is (or overlays) the D-RAM state memory**, directly indexed in
  mode 1 and pointer-indexed in mode 2. Favoured by the 40-cell fit: the PEQ's
  *coefficients* are elsewhere (C-RAM `0x00..0x1E`, MEASURED), a flat EQ still
  needs non-zero coefficients, and 40 zeros is what state initialisation looks
  like and what a coefficient upload does not.
* **I-b — the space is a distinct register file** that merely *includes* a
  per-algorithm scratch block, and D-RAM proper is only reachable in mode 2.
  Favoured by R2's positional evidence that `0x06`/`0x86`, `0x8C`/`0x8D`/`0x8F`
  behave as control registers rather than as audio state.

**Neither is chosen here.** The discriminator is cheap and static: take a third
capture on an algorithm whose state size is known independently (any of the biquad
family) and check whether the `0x50` block again equals 4 × sections. If it tracks
the algorithm every time, I-a; if it saturates, I-b.

The same space also holds a **sine table of period 24** at `0x1D..0x40` — 36 cells,
i.e. one full cycle plus a 12-cell repeat (`m[c] == m[c+0x18]` for all twelve of
`0x1D..0x28`), which is what a wrap-free read window looks like. MEASURED, values
`0x0C23C6, 0x2B0A8F, 0x470273, …`. (R2 saw the same block as nine stride-4 selects;
the period-24 structure is the same fact seen from the value side.)

### 2.3 tag `0x4C` = a third space

`0x00..0x1F` is **byte-identical in both captures** — a constant table written once
at boot — while `0x26..` changes with the algorithm. Its boundary set is
`{0x00, 0x26}`, two cells out of 256. Its values are all ≤ `0x00C4E5`, i.e.
16-bit-shaped, and the constant block's values all sit in `0x8000..0xC4E5` with
`0x7FFF` parked at `0x1E`.

> **Named by the concurrent R3 pass** (`r3-delaydram.md`, same day): this is the
> **external-delay-DRAM descriptor bank**, written by tag-`0x4C` packets through
> the pointer register `…825`, exactly as the coefficient bank is written by tag
> `0x26` through `…821`. K3 arrived at "a third, distinct space reached by `…825`,
> holding 16-bit-shaped values" from the collision test and the boundary test;
> R3 arrived at what those values *are* from the firmware writer. The two results
> compose and neither depends on the other.

---

## 3. The register model

### 3.1 The registers, as named by the encoding

| selector | how it is written | payload | in-program values | space |
|---|---|---|---|---|
| `lo12 = 0x021` | `801.0.00.021` | 0 | — (`rstcur`) | the **implicit coefficient cursor** (C-RAM) |
| `lo12 = 0x821` | `801.0.PP.821` | 8 bits | `0x70` u0, `0x50` u1, `0x90` out | **C-RAM** — MEASURED (§2.1, §4.1) |
| `lo12 = 0x825` | `801.0.PP.825` | 8 bits | `0x25` u0, `0x25` u1, `0x26` out | **tag-0x4C space** — INFERRED (strong) |
| `lo12 = 0x827` | `801.0.PP.827` | 8 bits | `0x6C` u0, `0x64` u1 | **OPEN** (§5.1) |
| `lo12 = 0x822` | `859.0.86.822` | 8 bits | `0x86` (output stage only) | **OPEN** (§5.2) |
| `lo12 = 0x820` | `C**.*.**.820` | 13-bit immediate | five distinct, header only | **OPEN** (§5.3) |
| `lo12 = 0x839` | `809/80B.0.00.839` | 0 | header w38, algo00 w18 | **OPEN** (§5.4) |
| `class4 = 1, lo12 = 0x000` | `000.1.PP.000` | 8 bits | host only | R2's **mode-1 register space** — MEASURED by both passes; what the space *is* has two readings (§2.2) |

### 3.2 How many registers — the lower bound is FORCED

The header's per-unit setup is three consecutive loads with **nothing between
them**:

```
   w42  801.0.70.821          w50  801.0.50.821
   w43  801.0.6C.827          w51  801.0.64.827
   w44  801.0.25.825          w52  801.0.25.825
   w45  010.A.00.20C          w53  010.9.D0.20C
   …                          …
   w49  400.1.0E.000  CALL    w59  400.1.0F.007  CALL
```

If `0x821`, `0x827`, `0x825` named one register, w42 and w43 would be dead stores.
They are not dead: **the same triple is repeated for unit 1 with different payloads
in two of the three slots** (`0x70`→`0x50`, `0x6C`→`0x64`). Nobody parameterises a
dead store per unit. **≥ 3 registers, and ≥ 2 of them are per-unit live. FORCED**
(given that the resident kernel is live, which it is — it is the only code every
effect executes, and the live I-RAM read-back matches it word for word).

Adding `0x822` (output stage) and `0x820` gives **five distinct `lo12` selectors in
the `0x82x` block** — `820, 821, 822, 825, 827` — plus `0x839`, plus the class-1
form, plus the cursor selector `0x021`. The CDJ-500 block
diagram's **six** pointers (CP, DP, BP1, BP2, PR1, PR2) plus BNK-R is comfortably
above that and remains the working ceiling. **Nothing here contradicts six; nothing
here proves six.**

### 3.3 What the payload means

For every `0x8**` form: **an 8-bit absolute address in that register's own space**,
PROVEN BY CONSTRUCTION for the width (§1.1) and MEASURED for the space in the two
cases where the host gives us a map (§4).

There is **no relative / offset / bank interpretation anywhere in the evidence**,
and one is not needed: 8 bits addresses all of a 256-cell space exactly.

### 3.4 The one thing the captures CANNOT decide, reported as a negative

Across both captures, **1012 of 1012 coefficient packets carry the tag of the most
recently *set* pointer** and there is not a single interleave (`set A … set B …
packet A`). So the host stream is equally consistent with

* **(i)** three independent pointer registers, each with its own tag, or
* **(ii)** one pointer register plus a three-way *space* selector in the tag.

The host stream cannot separate them. The **in-program** stream can, and it chose
(i) — §3.2 — but only for the `0x82x` family; whether the class-1 form's register
is a fourth register or the same file is **OPEN**.

---

## 4. Why `0x821` is C-RAM, and why it is not the cursor

### 4.1 The positive evidence — three payloads, three exact bases

`k3_pointers.py boundary`:

```
   tag 26 boundary set (|B| = 4): 00 50 70 90
   hdr w42  unit-0     821<-70    tag26: HIT
   hdr w50  unit-1     821<-50    tag26: HIT
   out w69  epilogue   821<-90    tag26: HIT
```

Three for three, on a 4-cell target in a 256-cell space. Under a uniform null
`(4/256)^3 ≈ 3.8e-6`. The payloads are not independent draws and the boundary set
was derived from the same capture, so treat that number as an order of magnitude,
not a p-value — but note **which** boundaries they are:

| base | who reaches it | how |
|---|---|---|
| `0x00` | unit-0 body's coefficient bank | the **implicit cursor** |
| `0x50` | TABLE A | **`0x821`, set by the unit-1 segment** |
| `0x70` | TABLE B | **`0x821`, set by the unit-0 segment** |
| `0x90` | unit-1 body's coefficient bank | the **implicit cursor** (base 0x90, R1) |
| `0x90` | again | **`0x821`, set by the output stage** |

The four bases are exhausted, each unit gets its own coefficient bank *plus* its
own table, and the assignment is symmetric. That closure is worth more than the
probability.

A smaller corroboration: R1's reverb-bank proof rests on the host packet
`08 01 09 08 21` = `801.0.90.821` preceding every type-2 coefficient block, and
the output stage's in-program `0x821 ← 0x90` is the *same address in the same
space* — and `0x90` is also one of the cells the host later pokes singly
(`V = 0x4D9364`, cold-boot transfer 49), i.e. a live parameter at a base the
kernel names.

### 4.2 The negative — it cannot be the cursor

The cursor's per-unit bases are `0x00` and `0x90` (MEASURED; the CHORUS join in
§2.1 and R1 for the reverb). `0x821` is `0x70` when the unit-0 body runs and `0x50`
when the unit-1 body runs. If `0x821` were the cursor, CHORUS's `094.A.00.200`
would read `C-RAM[0x71] = 0x0004BE`, not `0x7FFFFF`. **FORCED against.**

Consequence: **whatever sets the cursor's per-unit base is still unidentified**, and
the `0x821` loads are now excluded as candidates. R2 finding 13 reaches the same
place by elimination ("none of the eight kernel pointer-load words carries `0x00` /
`0x90`, so the per-unit bases must be chip state only the host writes"), and K3
adds the constraint that turns that into a positive requirement:

> **MEASURED: the header performs 22 cursor advances (`class4` bit 3) in `w0..w48`,
> before the unit-0 CALL at `w49`, and 1 more in `w50..w58`.** So the cursor is at
> ≈ `0x16` when the unit-0 body is entered and it MUST read `0x00`. **A reset
> therefore happens, every frame, and it is carried by a word that is not a
> pointer-load word.**

Combining the two, the surviving candidates are enumerated:

* **the unit-tagged transfer itself** (`400.1.0E.000` / `400.1.0F.007`) reloads the
  cursor from per-unit chip state — the only per-unit event left once pointer loads
  are excluded, and the natural job for the block diagram's **BNK-R**;
* a non-pointer-load word inside `w45..w48` / `w53..w58` — K6's pair
  `w45 = 010.A.00.20C` vs `w53 = 010.9.D0.20C` (differing in `class4` A/9 and
  `addr8` `0x00`/`0xD0`) is the only structurally-positioned candidate, but R2 §4.5
  re-reads `w53` as a **mode-1 register access**, which weakens it;
* something in the frame restart, i.e. not in the instruction stream at all.

**OPEN**, three ways, and this is now a sharper question than it was: not "where is
the base loaded" but "which of these three carries a reset we can prove happens".

### 4.3 `0x825` — same argument, weaker evidence

The tag-`0x4C` boundary set is `{0x00, 0x26}`. The output stage's payload is
**`0x26`** (exact) and both header payloads are **`0x25`** (one below). Nothing
else in any of the three maps fits: `0x25`/`0x26` are unwritten in the C-RAM map,
and in D-RAM they are interior sine-table cells.

Two readings, **both open**:

* **H-a** the space is 1-based-by-pre-increment: the header parks the register one
  cell below the block and the first access lands on `0x26`;
* **H-b** cell `0x25` is itself meaningful and the block simply starts at `0x26`.

`-pointer.md` §3 killed `0x825` as the per-unit **state** pointer because it holds
the *same* value `0x25` in both unit segments and the two units would alias. That
falsification **stands and is now explained**: `0x825` points at a **shared**
table, where aliasing is the design, not a bug. R3 (`r3-delaydram.md` P1/P6) names
that table — it is the **delay-DRAM descriptor bank**, consumed by an
auto-incrementing cursor, one cell per DRAM-access word in program order — which
also settles reading **H-a** over **H-b**: a cursor that is re-based per unit and
then post-increments explains `0x25` → first access at `0x26` exactly.

---

## 5. The registers the host never touches — enumerated, not guessed

The host writes through `0x821`, `0x825` and the class-1 form and **through
nothing else**, in 1012 packets over two captures. So for the rest there is no
map, and the payloads must be placed by elimination.

### 5.1 `0x827` ← `0x6C` (unit 0) / `0x64` (unit 1)

Neither value is a boundary in any of the three maps; both are interior. Candidates:

* **α — a second C-RAM pointer, into TABLE A.** `0x6C` and `0x64` are TABLE A
  entries 28 and 20 (`C-RAM[0x6C] = 0x00F000`, `C-RAM[0x64] = 0x00D000`).
  Against: unit 0 would be reading unit 1's table.
* **β — the D-RAM operand pointer.** `-pointer.md` §3's extent test scores `0x6C`
  identically to `0x70` (30/37 images in range). Against: the host's D-RAM clears
  put unit-0 state at `0x05..0x14` + `0x50..0x77` and unit-1 state at
  `0x85..0xD2`; neither `0x6C` nor `0x64` is a base of either. For: nothing forbids
  an origin inside a block if the body's first delta is negative — and the pointer
  **delta rule is known to be wrong** (`-pointer.md` §6, two independent misses),
  so this test has no power right now.
* **γ — a pointer into a fourth space** with no host traffic at all.

**OPEN.** Note that (β) is now the *leading* candidate purely because `0x821` has
been taken away from it: before this pass `0x821` and `0x827` were the two
candidates for the D-RAM operand pointer and `0x821` was preferred on host-map
grounds. `0x821` is now C-RAM, so **`-pointer.md`'s headline 2 — "unit 0 origin
0x70, unit 1 origin 0x50, via the 0x821 register" — is WITHDRAWN**, and its
runner-up `0x827` inherits the position with its payloads `0x6C` / `0x64`. That is
a change of *which numbers* the D-RAM origin work should be using, and it is the
single most actionable consequence of this note.

### 5.2 `0x822` ← `0x86`, output stage only (`859.0.86.822`) — **answered by R2**

K3 had this as OPEN with the note that `0x86` is one of the two cells the host
clears at power-on (with `0x06`). **R2 §1.3 / §3 settles it and K3 defers**:
`0x86` is the **unit-1 output-level register**, `0x06` is unit 0's, bit 7 of a
mode-1 register index is the unit selector (5 positional confirmations, no
counter-example), and `w77` is one of the four output-presentation words.

Two things K3 adds without disturbing that: `hi12 = 0x859` carries **bit 4**, and
whatever bit 4's mode-dependent target is (R2 corrected the blanket `mem[ptr]`
reading), this word both **names a register** and **carries the store**; and the
capture confirms the level values — the host's last two acts of the cold boot poke
`0x06 ← 0x400000` (+0.5) and `0x86` (§7 item 5), which is R2 finding 6 seen from
the capture side.

### 5.3 `lo12 = 0x820` — five header words, and a correction to the disassembler

```
   w15 C0A.2.92.820   w22 C04.3.12.820   w29 C42.4.57.820
   w31 C0A.4.B1.820   w40 C4A.1.C0.820
```

The disassembler renders these as C-format with an `A`/`B` split. **That split is
not supported for this sub-family** (`k3_pointers.py cfmt`): K5's "every imm13 is a
multiple of 32" is **57/57 inside `(hi12 & 0xFFE) == 0xC40`**, which with the four
host-written `setvec` values reproduces K5's 61/61 exactly, and **2/11 outside it**
— and four of the nine misses are `lo12 = 0x820` words. So `A = imm13 >> 5` is a
`0xC40`-family rule that the listing is currently applying to words it was never
measured on.

Three readings of the `0x820` words, all open:

* **δ** a **wide register load**: `lo12 = 0x820` is the `0x82x` block's selector 0
  and the payload is the full 13 bits `[24:12]` (658, 786, 1111, 1201, 448).
  13 bits is too wide for C-RAM/D-RAM and too narrow for the 18-bit delay DRAM, so
  under this reading it names something else again.
* **ε** **not an immediate at all**: `class4` is a real class (2, 3, 4, 4, 1) and
  `addr8` a real pointer delta, and `hi12[11:8] == 0xC` is simply not a single
  format. This is the reading the `cfmt` measurement leans towards.
* **ζ** a **block-end / loop-count setup**. MEASURED, and it is the most
  suggestive thing in this section. Four of the five sit **immediately after an
  end-of-block word** (w14→w15, w21→w22, w28→w29, w39→w40), i.e. they are the
  *first word of a new block*; and the header is exactly where the block diagram's
  LC1–LC3 loop counters have to live. Reading the payload with K5's split gives
  `A = 20, 24, 34, 37, 14` and `B = 18, 18, 23, 17, 0`. The header's END-OF-BLOCK
  words are at `6 11 14 19 21 23 24 28 33 36 39 41 49 59`, and

  | word | A | relation |
  |---|---|---|
  | w15 | 20 | `= 19 + 1`, and 19 ends w15's own block |
  | w22 | 24 | `= 23 + 1`, and 23 ends w22's own block |
  | w29 | 34 | `= 33 + 1`, and 33 ends w29's own block |
  | w31 | 37 | `= 36 + 1`, but 36 ends the *next* block |
  | w40 | 14 | an END address itself, and backwards |

  **All five `A` values lie inside the 60-word header** (payload space is 0..255)
  and **four of five are exactly one past an END-OF-BLOCK word** (14 such addresses
  in 256 → 5.5 % each under a uniform null). Three of those four point at their own
  block's end. That is a real pattern and it reads as "at the start of a block, set
  a register to the address just past the block's end" — a loop/return bound. Two
  of five do not fit, so this is an **EDUCATED GUESS**, offered because it is
  testable, not a finding.

### 5.4 `lo12 = 0x839`

`809.0.00.839` (header w38) and `80B.0.00.839` (algo 00 w18) — payload 0 in both,
`hi12` differing only in bit 1. If `lo12[4:3]` is a sub-op and `lo12[2:0]` a
register index, this is "sub-op 3 on register 1", i.e. the same register `0x821`
names; if `lo12[7:0]` is a flat register code it is a sixth register. **OPEN.**
It is one of only two body words in the whole `0x_2x` selector block.

---

## 6. The falsifications

| earlier claim | source | status |
|---|---|---|
| "the host-window and in-I-RAM meanings of `801.0.NN.821` **cannot be the same space**" | K6 headline 11, `dsp-k6-input-stage.md` §9.1 | **FALSIFIED as stated.** Both are C-RAM. The argument's first leg — "if the I-RAM form aimed at C-RAM the chorus's MEASURED base 0x00 would be impossible" — silently equates *the C-RAM pointer* with *the C-RAM cursor*. They are different registers (§4.2). Its second leg — "if the host form aimed at D-RAM the reverb bank would land on the input window" — is sound but argues against a reading nobody now holds. **The measurements in K6 §9.1 are all upheld; the inference drawn from them is not.** |
| "**ASSIGNED (INFERRED, strong): the body's operand pointer is the `0x821` register. Unit 0 origin `0x70`. Unit 1 origin `0x50`.**" | `-pointer.md` headline 2 / §4 | **WITHDRAWN.** `0x821` is a C-RAM pointer. The host-map argument that chose it ("the host writes parameters through `0x821` and a body must read them") is exactly right about the *space* and exactly wrong about the *register's job*: it proves `0x821` addresses the coefficient space, which is why it cannot be the D-RAM operand pointer. `0x827` — the runner-up that note explicitly did not exclude — is now the leading candidate, with origins `0x6C` / `0x64`. |
| `instruction-set.md`: "`801.0.NN.821` … **it sets the C-RAM destination pointer** … The same word inside I-RAM is a different animal and must not be conflated" | `instruction-set.md`, `ldptr` row | **Half withdrawn.** The first half is right. The second half should now read: the same word inside I-RAM sets **the same register in the same space**; what it is *not* is the coefficient cursor. |
| R1: "the unit-1 reverb bank base is `0x90`, PROVEN BY CONSTRUCTION: every type-2 coefficient block is preceded by `801.0.90.821` = `ldptr #$90`" | `r1-allpass-motif.md`, `instruction-set.md` | **Conclusion UPHELD, mechanism corrected.** The packet proves where the *host put the data*; the reverb body's *cursor* starting at `0x90` is then a join, not a consequence of that word. Nothing downstream of R1 changes. |
| the disassembler's C-format predicate `(hi12 & 0xF00) == 0xC00` | `tools/dsp_disasm.py::c_format` | **Too broad.** The `A = imm13 >> 5` payload rule is measured only on `(hi12 & 0xFFE) == 0xC40` (57/57 in-corpus, 61/61 with the host words) and fails 9/11 elsewhere. The five `lo12 = 0x820` words carry an `{C-fmt A=… B=…}` annotation they have not earned. |
| K5: "the only DSP words the firmware ever *constructs* are `LABEL_0387E6` / `LABEL_038922` / `LABEL_0388B3`" | `k5-output-stage.md` §1.2 | **INCOMPLETE.** There are seven writers, and the missing family `000.1.PP.000` + tag `0x15` is the **D-RAM** one — the space K5 and K6 both needed and neither had. |
| the task brief's "the cursor is reset by `801.0.00.821`" | K3 brief | **Typo, but a load-bearing one.** The reset is `801.0.00.021`; the difference is `lo12` bit 11, which is the field this whole note turns on. The repo's own `dsp_disasm.py::is_rstcur` has it right. |
| K3's own draft "`class4 == 1` = direct addressing" | this note, §7 item 4 | **SUPERSEDED by R2 §1.1 before it was published.** The split is on the **escape bit**, not on the class: escape-1 class-1 = the delay-DRAM sub-ops `{0x20,0x30,0x60}`, escape-0 class-1 = register indices, 324/324. Reported as a K3 miss. |

---

## 7. By-products — things K3 measured that belong to other quests

These are handed over labelled, not folded into K3's conclusions.

1. ★ **A DELAY-DRAM ALLOCATION falls out of C-RAM TABLE A / TABLE B.**
   TABLE B covers `0 … 32767` in 27 equal steps of 1214; TABLE A covers
   `32768 … 64512` in 31 equal steps of 1024, and TABLE B's last entry is
   **clamped to exactly `0x7FFF`**. Unit 0's `0x821` points at TABLE B, unit 1's at
   TABLE A. Read as delay-line addresses this says **unit 0 owns external DRAM
   `0x0000..0x7FFF` and unit 1 owns `0x8000..0xFFFF`** — and the clamp is the
   region limit. Corroboration from two other spaces: the constant tag-`0x4C`
   table at `0x00..0x1F` holds values in `0x8000..0xC4E5` (unit-1 territory) with
   `0x7FFF` sitting at `0x1E`; and CHORUS's D-RAM cells `0x50..0x57` hold
   `0x190 / 0x5A0 / 0x9B0 / 0xDC0` — four bases 1040 apart, all below `0x8000`
   (unit-0 territory). **INFERRED (strong)**, and directly on worklist item #1.
   **Confirmed independently and with far better evidence by the concurrent R3 pass
   the same day** (`r3-delaydram.md` P5: unit 0 = `[0x00000, 0x08000)`, unit 1 =
   `[0x08000, 0x10000)`, 32 768 words = 743.0 ms each, MEASURED over 870 descriptor
   cells across 100 algorithms, max address 64 899). K3 saw the allocation as a
   *side effect* of asking where a pointer points; R3 derived it from the firmware.
   Where they differ in precision, use R3.
2. **Every value in the four table-like blocks fits in 16 bits.** Maxima:
   C-RAM `0x50..0x8B` → `0x00FC00`; tag-`0x4C` `0x00..0x1F` → `0x00C4E5`;
   tag-`0x4C` `0x26..` → `0x008000`; D-RAM `0x50..0x57` → `0x000DC0`. That does not
   decide the 17-vs-18-bit hardware question, but if these are delay addresses
   (item 1) the firmware never uses more than 64 K words of the 256 K-word
   M5M44260. **MEASURED**; the "these are addresses" step is INFERRED.
3. **The host tells us each body's exact D-RAM footprint.** The tag-`0x15`
   zero-fill issued right after every body upload is a per-algorithm state map.
   This is a far better handle on the D-RAM origin and on the broken pointer-delta
   rule than anything static: for algo 39 the answer is known to the cell
   (`0x50..0x77`, 40 cells, 5×2×4). Anyone attacking the delta rule should start
   here.
4. **`class4 == 1` = direct addressing — SUPERSEDED, and R2 got there first and
   better.** K3's draft reading was "class 1 = `addr8` is a direct address, not a
   pointer delta", with the known problem that the reverb's `880.1.20.655` would
   then take its DRAM address from cell `0x20`, a CHORUS sine-table cell. **R2 §1.1
   dissolves that**: the split is on the **escape bit**, not on class alone —
   escape-1 class-1 words (`880/800/900`, `addr8 ∈ {20,30,60}`) are the delay-DRAM
   sub-ops and escape-0 class-1 words are register indices, 324/324. K3's problem
   case was created by conflating the two. **Recorded as a K3 miss.**
5. **The `0x06 / 0x86` pairing — CONFIRMED from the capture side, R2 owns the
   reading.** The first two host pointer/data writes of the whole boot — cold-boot
   transfer 4, immediately after the output-stage upload and before any effect
   exists — are `000.1.06.000` and `000.1.86.000`, both writing 0; and the *last*
   host action of the boot pokes `0x06 ← 0x400000` = **+0.5**. R2 finding 6 reads
   these as the per-unit **output levels**, which the value +0.5 fits exactly and
   which K3 has no better account of.
6. **A sixth host word form exists that no note has recorded**: `0B .. .. .. 15`,
   i.e. a tag-`0x15` packet with `hi12` bit 8 set (`0xB00`, not `0xA00`). Twelve
   occurrences across the two captures. The four in the cold boot carry
   `0x190, 0x5A0, 0x9B0, 0xDC0` — the same four values that end up interleaved with
   zeros in D-RAM `0x50..0x57`. So the leading nibble `0xA` vs `0xB` is a real flag
   on the packet, not part of the 24-bit value. **MEASURED, meaning OPEN.**
7. **The host injects `000.2.00.000` — the `nop` form — three times** in the
   PARAMETRIC EQ stream, as the only word that matches none of the known forms.
   Weak but non-zero support for the `nop` reading, which `instruction-set.md`
   currently carries as INFERRED.

---

## 8. What this constrains for the concurrent ALU work

Three items, all addressing-side facts with arithmetic-side consequences:

1. **`hi12 = 0x801` is not an ALU opcode at all** — with `class4 == 0` and
   `lo12 ∈ {0x021, 0x821, 0x825, 0x827}` it is a register write and nothing else.
   Nine words of the corpus (6 header, 2 output stage, 1 body) can be removed from
   any `lo12`-as-ALU-selector fit. Likewise `859.0.86.822` — **except** that its
   `hi12` bit 4 is set, so it *does* perform the standard "store accumulator to
   `mem[ptr]`" side effect. It is a register write **with** a store, not instead of
   one.
2. **`lo12` bit 11 is a field, not part of an opaque `lo12` code**, in at least the
   `0x_2x` family (§1.2, PROVEN BY CONSTRUCTION). Any model that treats `lo12` as a
   flat 12-bit enumeration of ALU routes should expect `0x021` and `0x821` to
   behave as *the same route with a modifier*, not as two unrelated codes.
3. **The C-format payload rule is family-local.** `A = imm13 >> 5` is measured on
   `(hi12 & 0xFFE) == 0xC40` only (57/57 in-corpus) and fails 9/11 outside. If the
   ALU work is using the `lo12 → A` payload table from `instruction-set.md` as a
   crib for the C-format destination register file, that table is safe — every one
   of its seven rows is inside the `0xC40` family — but extending it to `C00 /
   C04 / C0A / C16 / C42 / C4A / C64` is not.

---

## 9. Reproduce

```
python3 dsp/tools/k3_pointers.py census     # sect. 1.2, 3.2, headline K
python3 dsp/tools/k3_pointers.py builders   # sect. 1
python3 dsp/tools/k3_pointers.py host       # sect. 2, 3.4
python3 dsp/tools/k3_pointers.py spaces     # sect. 0 item D
python3 dsp/tools/k3_pointers.py boundary   # sect. 4.1, 4.3
python3 dsp/tools/k3_pointers.py cfmt       # sect. 5.3, 6
```

Inputs: `original_ROMs/kn5000_subprogram_v142.rom`,
`~/compartilhado/kn7000_mame/notes/data/kn5000_dsp1_upload_{coldboot,parametriceq}.txt`,
and `~/compartilhado/kn7000_mame/tools` for the stream parser. The Sub CPU
statements in §1 are read from
`archive/asl/subcpu/kn5000_subprogram_v142.asm` at `LABEL_0387E6` (0x0387E6),
`LABEL_038922`, `LABEL_0388B3`, **`LABEL_03846C`**, **`LABEL_038539`**,
**`LABEL_038606`** and `LABEL_038439`.
