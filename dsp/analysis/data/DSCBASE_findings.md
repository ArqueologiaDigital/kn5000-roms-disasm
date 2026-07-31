# DSCBASE — where does the PER-UNIT DELAY-DESCRIPTOR BASE come from?

NEC **uPD6383GF-3BA** (Technics SX-KN5000, IC311). Date **2026-07-31**.
Offline, read-only: the ROM, the two host-upload captures, and the emulator's
**source** (read, never built, never run). No hardware. Nothing here is a recording.

Answers the task set by `SPECULATIVE-APPLIED-REGISTER.md` **§206**, which nominated
`lo12 = 0x827` (per-unit payloads `0x6C` / `0x64`) as the last pointer-family
register with a per-unit split, and flagged its own falsifier: `0x6C − 0x64 = 8`,
but the two units' descriptor blocks are **`0x26` = 38** apart.

Tool: [`../../tools/dscbase_arith.py`](../../tools/dscbase_arith.py) — stdlib plus the
repo's own ROM parsers. Every number below comes out of it.

```
python3 dsp/tools/dscbase_arith.py anchors    # 1  the requirement, re-derived
python3 dsp/tools/dscbase_arith.py carriers   # 2  THE ARITHMETIC + THE NULL
python3 dsp/tools/dscbase_arith.py cells      # 3  the two cold-boot bodies
python3 dsp/tools/dscbase_arith.py predict    # 4  the pre-registered numbers
```

Labels: **MEASURED** / **PROVEN BY CONSTRUCTION** / **FORCED** / **CONSISTENT** /
**INFERRED** / **SPECULATIVE** / **OPEN**.

---

## 0. Result in one page

| # | statement | label |
|---|---|---|
| **A** | ⛔ **`0x827` IS NOT THE DESCRIPTOR BASE, AND NO SCALING CAN RESCUE IT.** The base must satisfy `base_0 − base_1 = 0x26 = 38`. Under any affine map `f(x) = s·x + b (mod 256)` the offset `b` cancels, so a field with per-unit delta `d` can carry the base **iff `s·d ≡ 38 (mod 256)` is solvable, iff `gcd(d,256)` divides 38**. `38 = 2·19`, `gcd` is a power of two ⇒ **`d` must be odd or `≡ 2 (mod 4)`**. `0x827`'s `d = 8` ⇒ `gcd = 8 ∤ 38` ⇒ **no integer scale whatsoever**, not merely no small one. §206's *"either the base is scaled, or `0x827` is not it"* resolves to the second horn, with no free parameter left. | **FORCED** (§2) |
| **B** | ⛔ **AND NEITHER IS ANY OTHER FIELD OF THE PER-UNIT SETUP BLOCK.** All 12 differing fields of the paired words `w42..w49 / w50..w59`, printed with their deltas: **four are refuted for every integer scale** by the same gcd test — the three pointer/address payloads `0x821` (`d=32`), `0x827` (`d=8`), `w45/w53 addr8` (`d=48`), plus `w47/w55 hi12` (`d=0`). The other **eight admit only scales of 38, −38, 49, −79, 50 and −42** — an 8-bit multiply on a 4-bit class nibble or a `±1` step. **0 of 12 admit `|s| ≤ 8`** — independently reproducing `dram-unit-cursor.md` §2.4's *"0 of 12"* and strengthening it from a bound to a divisibility. | **FORCED** (§2) |
| **C** | ⛔ **THE BODY'S OWN FIRST DRAM WORD CANNOT CARRY IT EITHER.** `880.1.30.00B` is descriptor-consumer 0 of algorithms on **both** units, so the *same 36 bits* would have to yield `0x26` for one and `0x00` for the other. Re-derived here over all 91 algorithms that ship cells. | **FORCED** (§2.3) |
| **D** | ⛔ **NOR THE HOST WRITE POINTER.** Replaying the cold-boot capture: the host sets the descriptor pointer to **absolute** cells (`0x00`, `0x1E`, `0x00`, `0x26`) and leaves `m_dsc_wp` at **`0x30`** — one value, neither anchor, and dependent on the upload order (unit 1 was written first here). The blocks are separated by **addresses**, not by write ordering. | **MEASURED** (§2.4) |
| **E** | ★★★ **WHAT SURVIVES: THE BASE IS NOT A REGISTER AT ALL. It is PER-UNIT STATE ESTABLISHED AT THE CALL, and the ROM's own answer is a per-unit RING on the ONE shared cursor.** `dram-unit-cursor.md` (2026-07-27) swept 766 576 machines and got **4440 survivors, every one with `B₁ = 0x00` and `L₁ ≤ 0x26`** — reproduced today. The single immediate `0x25` means *"one below unit 0's base"* to unit 0 and *"the last cell of my ring"* to unit 1; one pre-increment delivers `0x26` to one and wraps to `0x00` for the other. **Neither §206 nor `HANDOFF-NEXT.md` cites that note.** | **FORCED within the printed model class**, and **tied** with item F (§3) |
| **F** | ⚠ **A SECOND SURVIVOR, AND IT IS OBSERVATIONALLY EQUIVALENT.** *"A 1-bit unit selector indexing a two-entry table of hardwired bases"* fits every shipped algorithm exactly as well. No experiment this ROM supports can separate them: the discriminator would be a unit-1 algorithm with **> 38** consumers, and the maximum is **32**. The ring is preferred only because it gives the immediate `0x25` a job — an explanatory advantage, **not evidence**. | **CONSISTENT**, both (§3.2) |
| **G** | ★★ **THE DEFECT, SIZED EXACTLY.** Shipped device: `cell = u8(m_dsc + m_delay_ix)`, `m_dsc = 0x25` for both units. Body 0 (CHORUS) lands on cells `0x25..0x2E` — **9 of 10** written, one short at each end. Body 1 (CONCERT REVERB 1) lands on `0x25..0x44` — **0 of 32** written: the reverb reads **unit 0's chorus descriptors and then 21 unwritten zeros**. | **MEASURED** from the source + the capture (§4) |
| **H** | ⚠ **TWO PROBE DEFECTS FOUND ON THE WAY, both affecting numbers already published.** (1) The §200 age probe and the §204 census both print a `dsc` label **one too high** for body consumers (`upd6383.cpp:1927` increments before `:1950` reads; `:5707` recomputes the label at *print* time from `m_dsc = 0x26`, the epilogue's value). §204's own printed line `iw46->ix3(dsc29,cell05A0)` proves it: `0x05A0` is cell **`0x28`** = `0x25+3`. (2) Consequently §202's two "bit-exact" lines — `4161 = cell 0x27`, `3120 = cell 0x2F` — were **body-1 consumers reading body-0's block**, i.e. an artefact of the very defect item G names. §202's *conclusion* (the rotation sweeps down) is untouched; its *numbers* must be re-baselined after the fix, not read as a regression. | **INFERRED** from the source, with §204's own MEASURED line as the check (§5) |

**What this does NOT settle:** the ring's **top** `L₀` and the exact `L₁` within
`0x20..0x26` (no shipped algorithm reaches either bound); whether the header's own
consumers run in unit 0's ring or unit 1's (`dram-unit-cursor.md` §2.5 prints both
and chooses neither); and the increment discipline **PRE vs POST**, which the
experiment in §6 is built to decide separately from the ring.

---

## 1. What §206 got right, and the one thing it did not have

§206 is right on its own terms and its premise correction stands:

```
   HDR 42  801.0.70.821      HDR 50  801.0.50.821     0x821: 0x70 / 0x50   DIFFERS
   HDR 43  801.0.6C.827      HDR 51  801.0.64.827     0x827: 0x6C / 0x64   DIFFERS
   HDR 44  801.0.25.825      HDR 52  801.0.25.825     0x825: 0x25 / 0x25   IDENTICAL
```

Re-derived today over the whole corpus (`dscbase_arith.py anchors`): those are the
only per-unit-paired pointer loads in the machine, **and 0 of the 38 body images
contains a pointer load of any kind**. So "give `0x825` a per-unit base" would
indeed be inventing a split the instruction stream does not contain — correct.

What §206 did not have is `dram-unit-cursor.md`, filed **2026-07-27**, four days
earlier, which asks exactly this question, sweeps the model class exhaustively and
answers it. Its answer is not on §206's list of candidates because §206's list is
implicitly *"which register holds the base"*, and the answer is *"no register does"*.

★ The same trap the memory's standing rule names: **a note went stale in the other
direction** — a published result existed and the task premise was written as if it
did not. `HANDOFF-NEXT.md` and §206 both name the base as "absent"; neither cites
`dram-unit-cursor.md`.

---

## 2. The arithmetic — every candidate, and the NULL first

### 2.1 The requirement, re-derived from the ROM (not quoted)

`dscbase_arith.py anchors`, over all 100 algorithms:

```
   unit 0 : 79 algorithms, cells 0x26..0x39, block BASE 0x26
   unit 1 : 12 algorithms, cells 0x00..0x1F, block BASE 0x00
   => base_0 - base_1 = 0x26 = 38
```

### 2.2 The test, and why it can fail

A "descriptor base register" means `base_u = f(F_u)` for some field `F` of the
per-unit setup block and some affine `f(x) = s·x + b (mod 256)`. Subtracting,
**`b` cancels**:

```
   base_0 - base_1 = s * (F_0 - F_1)  (mod 256)
```

So the whole test is: **does `s·d ≡ 38 (mod 256)` have an integer solution?**
It does iff `gcd(d, 256) | 38`; `38 = 2·19` and `gcd(d,256)` is a power of two, so
**`d` must be odd or `≡ 2 (mod 4)`**.

**THE NULL, computed before the verdict:** of the 256 possible per-unit deltas,
**192 (75.0 %)** admit *some* integer scale and **16 (6.2 %)** admit one with
`|s| ≤ 8`. The criterion is therefore easy to pass by accident and is a real test;
the address-shaped fields fail it anyway. Under the strictest reading — the payload
*is* the base, `s = 1, b = 0` — the null is `1/65536` and the hit count is **0 of 12**.

### 2.3 Every differing field of the paired setup words

```
   pair   unit 0         unit 1          differing fields
   42/50  801.0.70.821   801.0.50.821    addr8 70/50
   43/51  801.0.6C.827   801.0.64.827    addr8 6C/64
   44/52  801.0.25.825   801.0.25.825    IDENTICAL
   45/53  010.A.00.20C   010.9.D0.20C    class4 A/9, addr8 00/D0
   46/54  800.1.60.00B   800.1.60.00B    IDENTICAL
   47/55  800.8.0C.000   000.2.01.007    hi12, class4, addr8, lo12
   48/56  C64.5.A2.000   C64.6.A2.007    class4 5/6, lo12 000/007
   49/59  400.1.0E.000   400.1.0F.007    addr8 0E/0F, lo12 000/007   <- the CALLs
```

| field | u0/u1 | delta | gcd(d,256) | integer scales with `s·d ≡ 38` |
|---|---|---|---|---|
| `w42/w50 addr8` (**0x821**) | 70/50 | 32 | 32 | ⛔ **none, for any integer scale** |
| `w43/w51 addr8` (**0x827**) | 6C/64 | **8** | **8** | ⛔ **none, for any integer scale** |
| `w45/w53 class4` | 0A/09 | 1 | 1 | 38 (`abs(s)<=8`: none) |
| `w45/w53 addr8` | 00/D0 | 48 | 16 | ⛔ **none, for any integer scale** |
| `w47/w55 hi12` | 800/000 | 0 | 256 | ⛔ none |
| `w47/w55 class4` | 08/02 | 6 | 2 | −79, 49 (`abs(s)<=8`: none) |
| `w47/w55 addr8` | 0C/01 | 11 | 1 | 50 (`abs(s)<=8`: none) |
| `w47/w55 lo12` | 000/007 | 249 | 1 | −42 (`abs(s)<=8`: none) |
| `w48/w56 class4` | 05/06 | 255 | 1 | −38 (`abs(s)<=8`: none) |
| `w48/w56 lo12` | 000/007 | 249 | 1 | −42 (`abs(s)<=8`: none) |
| `w49/w59 addr8` (the CALL) | 0E/0F | 255 | 1 | −38 (`abs(s)<=8`: none) |
| `w49/w59 lo12` (the CALL) | 000/007 | 249 | 1 | −42 (`abs(s)<=8`: none) |

**12 fields; 8 admit some integer scale; 0 admit `|s| ≤ 8`.** And a second,
independent reason the three address-shaped payloads cannot be bases at all:
the corpus maximum descriptor cell is **`0x39`** and `0x70 / 0x50 / 0x6C / 0x64`
are all above it — read directly, each would aim the cursor at cells **no
algorithm ever writes**. `dscbase_arith.py cells` confirms it end to end: with
`0x827` as the base, CHORUS scores **0 of 10** written cells and the reverb
**0 of 32**; with `0x821`, likewise **0 of 10** and **0 of 32**.

**The body's own first DRAM word is refuted the same way** — r3 §6.2 reads
`addr8 = 0x30` as "load/reset the cursor", but

```
   880.1.30.000   units [0]
   880.1.30.00B   units [0, 1]   <== ONE WORD, BOTH UNITS
   880.1.30.407   units [0]      880.1.30.447   units [0]
   880.1.30.8BC   units [0]      880.1.60.00B   units [0]
```

`880.1.30.00B` is consumer 0 of algorithms on both units, so no field of it can
distinguish `0x26` from `0x00`. **FORCED.**

### 2.4 "There is no base — the host's write ordering separates the blocks"

Replaying the cold-boot capture (`dscbase_arith.py predict`), the descriptor
traffic is four transfers:

```
   t20  SET 0x00  + 30 cells   (0x00..0x1D)   unit 1, CONCERT REVERB 1
   t21  SET 0x1E  +  2 cells   (0x1E, 0x1F)   its separately-addressed tail
   t27  SET 0x00  +  1 cell    (0x00)         the PRE DELAY re-poke
   t35  SET 0x26  + 10 cells   (0x26..0x2F)   unit 0, CHORUS
   final host write pointer m_dsc_wp = 0x30
```

⇒ **REFUTED.** The separation is carried by explicit **absolute** pointer pokes,
not by ordering; unit 1 is uploaded *first* here, so ordering would give the wrong
sign; and `m_dsc_wp` ends at `0x30`, a single value that is neither anchor and that
moves with every parameter edit. The chip's read cursor must land correctly with no
host traffic at all. **MEASURED.**

### 2.5 The candidate list, closed

| # | candidate | verdict |
|---|---|---|
| 1 | `0x827` is the base (§206's nomination) | ⛔ **REFUTED** — `gcd(8,256) ∤ 38`; payloads above the corpus max; 0/10 and 0/32 written-cell hits |
| 2 | `0x821` is the base | ⛔ **REFUTED** — same, `gcd(32,256) ∤ 38` |
| 3 | `0x825` is the base, per unit | ⛔ **REFUTED BY CONSTRUCTION** — the firmware loads the same `0x25` twice (§206, re-confirmed) |
| 4 | some other field of the paired setup words | ⛔ **REFUTED** — 0 of 12 at `|s| ≤ 8`; 4 of 12 for any scale at all |
| 5 | a field of the body's first DRAM word (`addr8 = 0x30`) | ⛔ **REFUTED** — one word serves both units |
| 6 | the host write pointer `m_dsc_wp` / write ordering | ⛔ **REFUTED** — MEASURED at `0x30`, order-dependent, not per-unit |
| 7 | a **per-unit ring** on the one shared cursor, established at the CALL | ★ **SURVIVES** — FORCED within `dram-unit-cursor.md`'s printed class |
| 8 | a **hardwired 2-entry base table** indexed by the unit at the CALL | ★ **SURVIVES** — observationally equivalent to 7 on every shipped algorithm |

---

## 3. The survivor, and the honest shape of it

### 3.1 The ring

`dram-unit-cursor.md` §2, re-run today (`cursor_units.py reload`, ~30 s):

```
   766 576 combinations of (PRE/POST) x (RESET/MOD) x (wrap-on-load) x
           (per-unit ring [B_u, L_u)) x (do I-RAM 46/54 consume)
   SURVIVORS: 4440

   ACROSS EVERY SURVIVOR:   B_1 = 0x00        L_1 in 0x20..0x26
                            B_0 in 0x00..0x26  L_0 in 0x3A..0x41
   under the MOD flavour alone:  L_1 = 0x26, single-valued
```

Unit 1's ring **ends where unit 0's block begins**. The immediate `0x25` is
simultaneously *"the cell before unit 0's base"* and *"the last cell of unit 1's
ring"*, so one pre-increment delivers `0x26` to unit 0 and wraps to `0x00` for
unit 1. **That is why no field of the word could ever carry the difference**, and
it is why item C's clash (`880.1.30.00B` in both units) was never resolvable inside
an instruction.

⚠ The note states its own limit and this pass repeats it: `B₁ = 0x00` is the model
**recovering** the anchor it was handed, not discovering it. What the sweep's
control actually tests is *whether the wrap is necessary*, and with the wrap
switched off there are **0 survivors** on the real anchors and **8** on a fake
unit-1 anchor of `0x26` that needs none. The control can say yes, and here it says no.

### 3.2 The rival that cannot be separated

A hardwired two-entry base table indexed by the unit at the CALL fits everything
just as well. `dram-unit-cursor.md` §2.4 says so in terms and this pass agrees:
*"a 1-bit unit selector indexing a two-entry table of hardwired bases is not
refutable by any such search — but it is exactly as unfalsifiable as a hardwired
per-unit ring, and only the ring explains why the payload is `0x25`."*

**The discriminator that does not exist:** the two models differ only when a body
runs past its ring's top. Unit 1's ring holds **38** cells; the longest unit-1
block is **32** (all twelve reverbs). Unit 0's holds ≥ 26 (`L₀ ≥ 0x3A`) and its
longest block is 20 (GATED REVERB). **No shipped algorithm reaches a wrap
mid-body**, so no capture, no ROM read and no emulator run can separate them.
State it as a limit, not as a preference.

**The weak asymmetry, graded honestly.** Under the ring reading all three in-program
`ldptr.d` words are live: `w44`/`w52` re-base the cursor per unit and the epilogue's
`w62 = 801.0.26.825` sets the phase for the next frame's header consumers — the
epilogue itself contains **zero** descriptor consumers (checked over all 23 words),
so `w62` can only be for the frame boundary. Under the table reading, `w44`/`w52`
are dead for the bodies and a live `0x825` cursor is *still* needed for the kernel's
own consumers — strictly more machinery for the same behaviour. That is parsimony,
**not evidence**, and it is not offered as more.

⚠ **And the corroboration that is NOT one.** §204's live census shows `iw12` reading
cell `0x26` right after the previous frame's `w62 ← 0x26`. That is the *emulator's*
model being self-consistent — it is exactly what `m_dsc` from `ldptr.d` must
produce — and it says nothing about the chip. Recorded so it is not later quoted as
support.

---

## 4. The defect in the shipped device, sized exactly

`upd6383.cpp:1882` — `u32(m_dscbank[u8(m_dsc + m_delay_ix)])`, with `m_dsc` from
`is_ldptrd` (`:3760`) and `m_delay_ix` reset per body (§201, `:4300`). The
consumer count is `is_dram` (`:1857`) plus the C-format advance (§203, `:4310`),
which together equal the ROM's consumer set exactly: CHORUS 10 (0 C-format),
CONCERT REVERB 1 32 (28 + 4).

```
   body 0  CHORUS            cells 0x25..0x2E    9 of 10 written  (short at both ends)
   body 1  CONCERT REVERB 1  cells 0x25..0x44    0 of 32 written
```

Body 1's 32 cells are **11 of unit 0's chorus descriptors followed by 21 unwritten
zeros**. The bank is correct — the cold-boot replay reproduces §189/§190's four
quoted live cells exactly (`03:8000`, `1E:7FFF`, `26:0190`, `2B:0410`, 4 of 4) and
§189's nine exceptionless `k ↔ k+5` pairs and its ten-element chain
`569 707 1250 1674 480 512 870 678 900 840` fall straight out of algo 20's ROM
cells, **10 of 10 in order**. Only the read cursor is in the wrong place.

---

## 5. Two probe defects found on the way

**(1) The `dsc` labels are one too high for body consumers.** In the §200 age probe
`m_delay_ix++` (`:1927`) runs *before* `dsc = u8(m_dsc + m_delay_ix)` (`:1950`); in
the §204 census the label is recomputed at *print* time (`:5707`) from the current
`m_dsc`, which by then is `0x26` (the epilogue's `w62`) while the bodies ran with
`0x25`. **The device's own published line proves it:** §204 printed
`iw46->ix3(dsc29,cell05A0)`, and `0x05A0` is cell **`0x28`** = `0x25 + 3`.
The `cell%04X` column is trustworthy; the `dsc%02X` column is not. **INFERRED from
the source, checked against a MEASURED line.**

**(2) §202's two bit-exact lines were the defect, seen from inside.** Its
`dsc 28 → 0..4161` and `dsc 30 → 0..3120` are cells `0x27 = 0x1041 = 4161` and
`0x2F = 0x0C30 = 3120` — both **CHORUS's**, and cell `0x2F` is only reachable at
`ix 10`, which CHORUS (10 consumers, `ix 0..9`) never reaches. **They were body-1
consumers reading body-0's block.** §202's conclusion — the rotation sweeps down,
`age = C_read − C_write` — is untouched, because that relation is what produced the
match; but the numbers were produced by the aliasing this note is about. ⇒ **after
the fix those two lines will move, and that is expected, not a regression.** They
must be re-baselined. **INFERRED**, and stated because pre-registering against them
unchanged would guarantee a false alarm.

---

## 6. The experiment — pre-registered, four-armed, and what refutes it

### 6.1 The change

Two **independent** env gates, so the two halves of the model are scored separately
(the shipped `UPD6383_BODYIX` / `UPD6383_CFMTIX` precedent; the `u64` spec mask is
exhausted):

* `UPD6383_DSCPRE` — pre-increment: the cell is `m_dsc + m_delay_ix + 1`.
* `UPD6383_DSCRING` — the per-unit ring, wrapping the cell into
  `[0x00, 0x26)` for unit 1 and `[0x26, 0x40)` for unit 0, the unit taken from the
  index the device **already** uses for the per-unit D-RAM rebase (`m_cur_iw ≥ 200`)
  — the same CALL-time mechanism `DRAM_UNIT_BASE` uses, so no new chip-boundary
  violation: nothing reaches into another device's memory, and the unit is available
  at the chip's own CALL interface.

★ Both gates OFF must reproduce today's numbers bit for bit. That is the null arm
and it is listed first below so the run can be checked against it.

### 6.2 The observable

The device's own **§204 CONSUMER→CELL census**, bucket *"unit 1 (I-RAM ≥ 200)"*,
first 16 consumers, sampled after 900 k frames — **the `cell%04X` column only**
(see §5). Vehicle: cold boot, unit 0 = algo 1 CHORUS, unit 1 = algo 20 CONCERT
REVERB 1, notes playing (rule 12: a DSP test with no notes playing is not a test).

### 6.3 The four arms, pre-registered

**Body 1 — CONCERT REVERB 1 (32 consumers, census shows 16). This arm decides it.**

```
 PRE=0 RING=0  cells 25 26 27 28 29 2A 2B 2C 2D 2E 2F 30 31 32 33 34
   (SHIPPED)   vals  0000 0190 1041 05A0 0000 09B0 0410 0DC0 0820 8000 0C30 0000 0000 0000 0000 0000
                                                                      -> 0 of 16 on written cells

 PRE=1 RING=0  cells 26 27 28 29 2A 2B 2C 2D 2E 2F 30 31 32 33 34 35
               vals  0190 1041 05A0 0000 09B0 0410 0DC0 0820 8000 0C30 0000 0000 0000 0000 0000 0000
                                                                      -> 0 of 16

 PRE=0 RING=1  cells 25 00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E
               vals  0000 81E7 0000 A3C5 8000 A5FE A276 A8C1 A3C5 ADA3 A5FE B42D A8C1 B60D ADA3 B80D
                                                                      -> 15 of 16

 PRE=1 RING=1  cells 00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F
  (CANDIDATE)  vals  81E7 0000 A3C5 8000 A5FE A276 A8C1 A3C5 ADA3 A5FE B42D A8C1 B60D ADA3 B80D B42D
                                                                      -> 16 of 16
```

**Body 0 — CHORUS (10 consumers). This arm decides PRE alone** (unit 0 never
reaches its ring, so `RING` is inert here — which is itself a prediction):

```
 PRE=0 (either RING)  cells 25 26 27 28 29 2A 2B 2C 2D 2E
                      vals  0000 0190 1041 05A0 0000 09B0 0410 0DC0 0820 8000     ->  9 of 10
 PRE=1 (either RING)  cells 26 27 28 29 2A 2B 2C 2D 2E 2F
                      vals  0190 1041 05A0 0000 09B0 0410 0DC0 0820 8000 0C30     -> 10 of 10
```

All four body-1 signatures are distinct, and body 0 separates `PRE` from `RING`, so
the 2 × 2 identifies both halves independently rather than shipping a bundle.

⚠ `0x81E7` is the **capture's** cell `0x00` (the machine's actual boot PRE DELAY);
the ROM default is `0x81F4`. If the run shows `81F4` the bank came from the ROM
defaults rather than the capture — a *vehicle* difference, not a refutation. Every
other value is identical in both.

### 6.4 What would REFUTE it, stated before the run

1. **Body 1's cells land on `0x00..0x0F` but the values are not the sixteen above.**
   Then the ring is right and the bank contents are wrong — a host-path defect, and
   the finding transfers to `m_dscbank[]`.
2. **`PRE=1 RING=1` does not give body 1 `00..0F`.** Then the ring bounds are wrong;
   the sweep says they can only be wrong in `L₁ ∈ 0x20..0x26`, and every value in
   that range gives the same first-16 for this vehicle — so a miss here refutes the
   **class**, not a parameter, and sends the question back to §2.5's table.
3. **`PRE=0 RING=1` does *not* show the single stray `0x25` at the head.** Then the
   emulator's `m_dsc` is not `0x25` when body 1 runs, contradicting `ldptr.d` at
   `w52` — a decode error upstream of everything here.
4. **Body 0 changes when only `RING` is toggled.** Then unit 0's ring is being
   reached, which no shipped algorithm should do (`L₀ ≥ 0x3A`, longest block 20).

### 6.5 What the experiment CANNOT decide, said in advance

* **Ring vs hardwired base table** (§3.2). Both produce every number in §6.3
  identically. The run confirms the *class*, never the member.
* **`L₁` inside `0x20..0x26` and `L₀` inside `0x3A..0x41`.** No shipped algorithm
  reaches either bound.
* **Audio.** The chip is still silent (`§70 ACCA min 0 max 0`); the output stage
  (`w73`, §141/§150) is a separate, untouched defect. A correct descriptor map is
  not a working reverb, and the delay **ages** are deliberately **not**
  pre-registered — per §5(2) they will move, and predicting them would require the
  read/write pairing, which is r3 O-2 and still open.

---

## 7. Answer to §206, in one line

> **`0x827` is not the descriptor base, and no scaling can make it one: `gcd(8,256)`
> does not divide `38`. The base is not a pointer register at all — it is per-unit
> state established at the CALL. Of the two mechanisms that survive, the one the
> ROM's own numbers select is a per-unit RING on the single shared cursor that the
> immediate `0x25` addresses from both sides — FORCED within the swept model class,
> and observationally tied with a hardwired two-entry base table that no shipped
> algorithm can separate from it.**

★ And `0x827` already has a job: §115/§116 measured it as a per-unit **mode**
register (`m_ovc`, payloads `0x6C`/`0x64` and nothing else, near-equal counts, one
per unit per frame), with bit 3 — the *only* differing bit — selecting wrap vs
saturate. A field that carries **one bit** of per-unit information was never going
to carry an 8-bit base; that it can select one of two hardwired bases is true and
vacuous, because so can the unit index itself.

---

## 8. Reproduce

```
python3 dsp/tools/dscbase_arith.py all        # everything above, ~40 s
python3 dsp/tools/cursor_units.py ptr         # the three pointer writes
python3 dsp/tools/cursor_units.py reload      # the 766 576-machine sweep
python3 dsp/tools/r3_delaydram.py regions cursor
```

Inputs: `original_ROMs/kn5000_subprogram_v142.rom`,
`~/compartilhado/kn7000_mame/notes/data/kn5000_dsp1_upload_coldboot.txt`,
the ROM parsers in `~/compartilhado/kn7000_mame/tools`, and — read only —
`~/compartilhado/kn7000_mame/src/devices/cpu/upd6383/upd6383.{cpp,h}`
(lines 1857–1966, 3754–3761, 4291–4312, 5702–5730).

**Nothing was applied.** No emulator source was edited, nothing was built or run,
and `dsp/verify.py`'s tree is untouched.
