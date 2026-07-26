# NEC uPD6383GF — instruction set, as decoded

The effects DSP of the Technics SX-KN5000 (IC311). This is the **living ISA
reference**: it states exactly what is PROVEN, what is INFERRED, and what is OPEN,
and it is honest that most of the instruction set is still unknown. It is kept in
step with the Python disassembler [`tools/dsp_disasm.py`](tools/dsp_disasm.py)
(itself a mirror of MAME's `src/devices/cpu/upd6383/upd6383d.cpp`). When either
learns a new form, update both and re-run the generator.

> See also [`flowcharts/`](flowcharts/README.md) for the per-program **signal-flow
> flowcharts** (the shared kernel + all 38 effect bodies) that visualise the
> control flow and structural landmarks described below.

There is **no datasheet with an instruction set** — the chip is documented (block
diagram and pin table only) as IC302 of the Pioneer CDJ-500 service manual. Every
statement below is either MEASURED from the ROM corpus, PROVEN BY CONSTRUCTION
from the Sub CPU code that assembles the words, DETERMINED by an exhaustive
constraint search, INFERRED, or explicitly OPEN. Nothing is a guess dressed as a
fact.

## ⚠ Corrections — the claims that did NOT survive (2026-07-26)

The K5 (output stage), R1 (all-pass motif), R2 (result routing), K3 (pointer
register file), K4 (cursor rebase) and R3 (delay-DRAM addressing) passes killed
more than they added, and the **adjudication pass** that integrated them killed two
more. These are listed first because a wrong decode costs more than a missing one,
and because the disassembler emitted several of them for months.

The four newest rows are the adjudication's own
(`analysis/isa-adjudication.md`) — two of them against claims committed hours
earlier, which is exactly what an integration pass is for.

> ★ **And the SYNC pass (`kn7000_mame/notes/dsp-mirror-sync.md`) found one of these
> was not merely printed but EXECUTED.** `C00.A.47.407` — the frame terminator, the
> last word of every frame — passed MAME's ALU predicate, which had a class guard, a
> routing guard and an operation guard and **no format guard**, and was run as a
> class-A multiply-and-store: a C-RAM read, a multiply, a **cursor advance** and a
> D-RAM write, all invented. Three of the falsified labels below were also firing on
> **live I-RAM**, not just on the ROM corpus: the four host-written call-vector words
> were labelled *"envelope / level detector"* and two of them printed `cur+`. This is
> why "a wrong decode costs more than a missing one" is the first sentence of this
> section.

| withdrawn claim | why | replaced by |
|---|---|---|
| **`C40.1.80.000` and `C40.1.E0.451` are class-1 delay-DRAM words, and they corroborate R2's withdrawal of the `addr8` bit-7 split** (R3 §6.1, §9.5) | They are **C-FORMAT IMMEDIATE LOADS** — `hi12[11:8] == 0xC`, so `class4`/`addr8` are immediate data, not fields. R3's family predicate carries no C-format guard. Decisive: `C40.1.80.000` (A=12) and `C40.2.C0.000` (A=22) are **the same instruction** — same family, same destination `lo12 = 0x000` — differing only in the immediate; one reads `class4 == 1` and the other `class4 == 2` *because bit 8 of the immediate differs*. No machine can make one touch the DRAM and not the other. **FORCED.** | the guarded family (`is_dram()`); R2's bit-7 withdrawal stands on its own evidence (324/324 vs 3 misclassified) and never needed this |
| **the descriptor-cursor counting model is "consistent with zero residual, 8 solutions in {0,1}"** (R3 §6.1) | That holds only *with* the contamination above. Guarded, the {0,1} solution set collapses to **none** and the naive identity falls **88/96 → 80/96**: the whole residual was being absorbed by two immediates. The twelve reverbs balance only if the four `C40.1.80.000` consume; the COMPRESSOR family only if its two `C40.1.E0.451` do not. | "a good fit with 16 rows over", plus the enumerated resolutions in `analysis/isa-adjudication.md` §2.2. **Every VALIDATED R3 number survives** — the first DRAM word of every body is unchanged, so the ms→address chain, the residue test and the doubled delay lengths are untouched |
| **the C-format family predicate is `(hi12 & 0xFFE) == 0xC40`** (the Word-format section, below) | That is the predicate of the **payload rule**, not of the format. The FORMAT is `hi12[11:8] == 0xC` (68 words) — which `dsp_disasm.c_format()` has always implemented. Wide is forced three ways: R2's census reproduces row for row **only** under it; classes 3/7/B/E/F are empty **only** under it (narrow, the corpus's one "class 3" is `C04.3.12.820`, a header *pointer-load* word); and both `C00` words carry a **non-zero `B`** while encoding their own I-RAM address. | two predicates: `c_format()` = the format, `is_c40()` = the payload rule (`A = imm13>>5`, `B == 0`, 57/57 in, 2/11 out) |
| **`lo12 = 0x827` (payloads `0x6C`/`0x64`) inherits the D-RAM-origin slot** (K3, "INFERRED by elimination") | Elimination gave it no positive test. There is one — *the host's zero-fill must clear the state the body reads* — and under it the filled block lies inside the body's pointer reach in **0 of 85** streams, against **47 of 85** for the fill's own base `0x50`/`0xD0`. | the slot is **OPEN** again; `0x50`/`0xD0` is the better-supported candidate but is **not** a pin (see the Addressing section) |
| **`hi12 == 0xC40` = "envelope / level detector"** (INFERRED) | Wrong on **all 61 sites**. It fired on the reverb tank, on CHORUS, and on the frame terminator's neighbours. The family is a 13-bit **immediate load**. | the C-format rule below (`analysis/k5-output-stage.md` §2.3) |
| **`880.1.60.*` / `880.1.20.*` = "external-DRAM bracket OPEN / CLOSE"** (INFERRED) | Already falsified by the per-frame counts; R1's constraint solve then **FORCED** the real reading — one is a **READ** and the other a **WRITE**, and the opposite assignment has **zero survivors in all three machine models**. | `dramrd` / `dramwr` semantics below (`analysis/r1-allpass-motif.md` §5) |
| **`012.2.00.680` = "`d_in ← x + t` (the WRITE)"** and **`000.2.00.419` = "`y ← d_out − t`"** | These are **one of two** role assignments that survive the constraint search, and the corpus **ranks the other one first** (44/44 vs 0/56). They were printed as if settled. | "all-pass core slot 2/6 and 3/6, role NOT settled" |
| **`hi12[11:8] == 0xA` = "host-poke data form"** | `0A aa bb cc dd` is a **host-stream packet, not an instruction**. The rule fired on genuine in-program words (`A00.0.00.041` in CHORUS, `A3C.D.9F.287` at I-RAM 78). | `host_packet()`, callable only on a host stream |
| **`nop` is PROVEN BY CONSTRUCTION, writer `LABEL_038922`** | That routine emits `801.0.NN.825` plus a tag-`0x4C` coefficient packet and never emits `000.2.00.000`. | INFERRED (strengthened — see the forms table) |
| **the output stage's two host-written words carry a linear LEVEL (×2 / ×4)** (roadmap §1.4) | 84 = 2·42 and 200 = 4·50 are accidents of the I-RAM layout. The words are **call vectors**; "disconnect" is not attenuation, and the real mute is uC-IF `cmd 0x04` byte 3. | `setvec` below. **The hardware prediction is inverted**: a disconnected unit goes *silent*, it is not attenuated by 6/12 dB |
| **the reverb is "two ladders of five all-pass diffusers", "byte-identical at every repetition", "strictly descending gains"** | Re-measured: ladder 1 has **four** repetitions; slot 5's `addr8` varies (`0xBA`, `0xC4`); the gains descend in **10 of 12** presets; GATED REVERB has **6** cores, not 4. | `algorithms/reverb.md` |
| **"there is no encoded space-selector field; the memory space is pointer-identity"** (Addressing, below) | R2: `hi12` bit 11 is set on **0 of 2399** mode-2 words and on 370 words of modes 0/1/4/5 — it *is* a space selector, and `class4 & 7` is an addressing mode. Pointer-identity describes **mode 2 only**. | the `class4 & 7` section below (`analysis/r2-output.md` §1) |
| **"`hi12` bit 4 writes `mem[ptr]` in every class"** | R2: `w64`/`w71` are mode-1 bit-4 words whose destination K5 **DETERMINED** to be the call-vector *register*, and `w60`/`w61` are adjacent mode-1 stores with nothing between them, so under `mem[ptr]` the first is provably dead. The rule produces **four dead stores in the 23-word output stage**. | bit 4's target is **mode-dependent**; `mem[ptr]` is the mode-2 target (`analysis/r2-output.md` §1, §4.4) |
| **"class-1 `addr8` splits on bit 7"** (K6 lead) and **"`w53` stores the unit-1 send at the pointer"** (K6 §6) | R2: `0x06`/`0x0E`/`0x0F` are `< 0x80` and are not DRAM sub-ops, so bit 7 misclassifies 3 of 324; and `w53` is class **9** = mode 1 = a *register* access, so it never wrote `mem[ptr]`. K6's "2-cell discrepancy" had a false premise and dissolves. | `hi12` bit 11 (324/324); K6 resolution 2 confirmed (`analysis/r2-output.md` §1.1, §4.5) |
| **the coefficient bank holds "two 5-gain ladders"** (`notes/kn5000-dsp-reverb.md` §3) | The cursor map says otherwise: the code consumes **0x98–0x9C (5)** and **0xA1–0xA4 (4)**, and cells **0x96 / 0x9D / 0xA5** — one of which the old reading counted as a 5th ladder gain — are consumed by the three ladder **separators**, not by an all-pass core. | 5 + 4 diffuser gains + 3 separator tap gains; **the coefficient side now agrees with the code at nine stages** |
| **"the two resident effect units are given the two halves of the 256-word coefficient RAM, unit 0 low and unit 1 from `0x80`"** (INFERRED, `notes/kn5000-dsp-cursor-general.md` §1.2 headline 8) | C-RAM is **not** halved at `0x80`. Cells **`0x50..0x8B` hold a 60-word RESIDENT table** written once by a literal uC-IF blob at Sub CPU ROM `0x01E6BE`, and it **straddles `0x80`**. The unit-1 bank starts at `0x90` — the first 16-aligned cell after that table — and it is a **software** allocation (a literal in each parameter script; the poke writer builds its address with an 8-bit add). The `+0x80` the note actually saw is real but lives in the **class-1 register file**, a different space. | the C-RAM map in "Addressing" below, and `analysis/k4-cursor.md` §1, §4 |
| **"the host-window and in-I-RAM meanings of `801.0.NN.821` CANNOT be the same space"** (K6 headline 11) | K3: they *are* the same space — C-RAM. The argument silently equated *the C-RAM pointer* with *the C-RAM cursor*; they are different registers. The in-program payloads `0x70` / `0x50` / `0x90` are 3 of the 4 structural bases of the host's own C-RAM map (a mechanically-derived 4-cell target in 256), and `0x70` is a boundary in the **data** only — the host wrote `0x6E..0x8B` in one transfer. K6's measurements stand; the inference does not. | `ldptr` row above (`analysis/k3-pointers.md` §4) |
| **"the body's operand pointer is the `0x821` register; unit 0 origin `0x70`, unit 1 origin `0x50`"** (`notes/kn5000-dsp-pointer.md` headline 2) | K3: `0x821` addresses the **coefficient** space, which is exactly why it cannot be the D-RAM operand pointer. The host-map argument that selected it was right about the space and wrong about the job. | `0x827` (payloads `0x6C` / `0x64`) inherits the slot, INFERRED by elimination |
| **the C-format payload rule applied to all of `hi12[11:8] == 0xC`** | K3: "imm13 is a multiple of 32" is **57/57 inside `(hi12 & 0xFFE) == 0xC40`** — 61/61 once the four host-written `setvec` values are counted, which reconciles K5's number exactly — and **2/11 outside it**. Four of the nine misses are the header's `lo12 = 0x820` words, which the listing annotates with an `A`/`B` split they have not earned. | keep `A = imm13 >> 5` for the `0xC40` family only; `C00` uses the same split with a non-zero `B` |
| **"the only DSP words the firmware ever constructs are `LABEL_0387E6` / `LABEL_038922` / `LABEL_0388B3`"** (K5 §1.2) | K3: there are **seven** writers. The missing family is `000.1.PP.000` + tag `0x15` (`LABEL_03846C` / `LABEL_038539` / `LABEL_038CF9`, plus the packet-only `LABEL_038606`) — i.e. R2's mode-1 register space. `LABEL_038CF9` also proves the host word window `0x0160 = 352` by construction. | the forms table above |

Two numbers inside the new analyses were also wrong and are corrected here:
`k5-output-stage.md` §8 says "88 × I-RAM 84" where §2.4 and the ROM say **79**
(79 + 12 = the 91 valid streams; 5 more are malformed and 4 parse to no image at
all); `r1-allpass-motif.md` §7.1's "42 distinct images … 724/3195 = 22.7 %"
counted the 5 malformed streams as images and used an adjacent-**pair** count as
if it were a word count — over the canonical 40 blobs it is **703/3017 = 23.3 %**.
**Re-measured, the 44/44 vs 0/56 split is bit-for-bit identical**, so R1's
conclusion is unaffected; only its denominator was.

## Word format — MEASURED

A 36-bit instruction word travels in a **5-byte** container, right-aligned
big-endian; **bits 36..39 are always zero** (measured across the whole corpus —
exactly the four padding bits). The working field map is INFERRED
(`notes/kn5000-dsp-encoding.md` §8):

```
 35             24 23  20 19        12 11                     0
+-----------------+------+------------+------------------------+
|      hi12       |class4|   addr8    |          lo12          |
+-----------------+------+------------+------------------------+
```

- **`class4`** is NOT universal: inside the `hi12[11:8]==0xC` family (the
  **C-FORMAT**) it is **immediate DATA** (MEASURED, `notes/kn5000-dsp-header.md`
  §6). K5 sharpened the span: the immediate is **13 bits at [24:12]**, one bit
  *further left* than previously written, i.e. it reaches into `hi12` **bit 0** —
  which is exactly why unit 1's link word carries `0xC41` and not `0xC40`.
  ⚠ **Two predicates, and conflating them cost a committed error**
  (`analysis/isa-adjudication.md` §1, §3):

  | | predicate | n / 3057 | decides |
  |---|---|---|---|
  | **the FORMAT** | `hi12[11:8] == 0xC` | **68** | whether `class4`/`addr8` exist at all |
  | **the PAYLOAD RULE** | `(hi12 & 0xFFE) == 0xC40` | **57** | whether imm13 is a multiple of 32 (`B == 0`) |

  The 11 words between them are **all kernel words** (8 header, 3 output stage,
  **0 of 2974 body words**) and exactly **2 of 11** are multiples of 32. Use the
  wide one to decide whether to parse `class4`; use the narrow one before
  reading `A = imm13 >> 5`. Two consequences the disassembler now honours: a C-format word
  does **not** advance the coefficient cursor (its `class4` bit 3 is immediate
  data, not the cursor-fetch enable), and it has **no `addr8`**, so it cannot
  post-increment the data pointer. MEASURED: exactly **one** word in the
  3057-word corpus is affected by the cursor guard — the frame terminator
  `C00.A.47.407` — and **zero** body words are, so no committed listing changes.
  *(Predicted a live mis-count in the named-coefficient join; checked; there is
  none. Reported as a miss of the prediction, not of the code.)*
- **`addr8`** is a **signed pointer post-increment** on an 8-bit (wrapping) data
  pointer, active only for `class4 & 7 == 2` (classes 2 and A). MEASURED from the
  algo-32/34 minimal pair (`notes/kn5000-dsp-addressing.md`).
- Coefficients are signed **Q0.23** (e.g. `0x517CC1 = 2/π`); the biquad's first
  four are read as Q1.22. Sample rate **44,100 Hz**.

## `hi12` is a horizontal microword — MEASURED, not an opcode

`hi12` is **not** an enumerated opcode. It is a **horizontal microword of
independent enable bits** (`notes/kn5000-dsp-hi12.md`): the 54 observed values
contain 77 Hamming-distance-1 pairs against a popcount-matched null of 43.4 ± 4.3
(z = +7.9), spread over all twelve bit positions. So every word renders `hi12` as
**flags + an explicit residue**, never as an opaque number.

| bit(s) | name | status |
|---|---|---|
| 11 | **FORMAT ESCAPE** — bits[10:0] mean something else | MEASURED (removing it leaves a legal `hi12` in only 1/9 cases, vs 9/9 for bits 10 and 4) |
| 10 | **END OF BLOCK** (only when bit 11 clear) | MEASURED — one per image, always the final word; but 14× in the 60-word header ⇒ it is **not** end-of-*program* and the word still does its datapath work |
| 9:8 | a proven FIELD, meaning **UNKNOWN** (`f98`) | MEASURED as a field; the accumulator-op-selector reading was tested and **FAILED** |
| 7 | speculative "index/address domain" | rendered as residue |
| 6,5 | no reading | rendered as residue |
| 4 | **WRITE ACCUMULATOR → mem[ptr]**, taken **BEFORE** the word's own ALU step | MEASURED (`0x212 = 0x202 + bit4`, `0x092 = 0x082 + bit4`; absence control 0/410 clean). The **timing** is new: `store = after` has **zero survivors** in all three models of R1's search (**FORCED**, `analysis/r1-allpass-motif.md` F2) |
| 3:1 | a proven FIELD, meaning **UNKNOWN** (`f31`) | MEASURED as a field (8/8 values) |
| 0 | "`addr8` is an absolute immediate" | PROVEN BY CONSTRUCTION for `0x801` only; **in the C-format family it is instead the MSB of the immediate** (MEASURED); else residue. A third incompatible meaning on one bit — more evidence that `hi12` is a microword, not an opcode |

**bit 23** (== `class4` bit 3) is the **CURSOR-FETCH enable**, corrected from an
earlier "multiply enable" reading (`notes/kn5000-dsp-axes.md`). **FETCH is not
ADVANCE — only `class4 == 0xA` advances the cursor** (K4, FORCED): the PARAMETRIC
EQ body carries **10 class-8 words** (`804.8.16.415`, one per biquad section) inside
a cursor map that is proven to the bit at 6 cells per band, 60/60 named, transfer
function reproduced at max|err| = 0; if class 8 advanced, band *k* would start at
cell `7k` instead of `6k` and every role would shift. In the **2974-word body
corpus** the bit-23 words are class 8 (42) and class A (822) and nothing else —
re-derived exactly (`analysis/isa-adjudication.md` §4).
⚠ **Do not turn that into "bit 23 ⇒ class 8 or A".** K4's claim is body-scoped;
the 83-word **kernel** also sets bit 23 on class **9** (4 words — the call-vector
writes), class **C** (1) and class **D** (1 — R2's two `DO`-write words). A core
that assumes the body distribution mis-executes six kernel words.
**Both** disassemblers now print **`cur+`** only for `class4 == 0xA` and plain
**`cur`** for every other bit-23 word, and a *decoded* class-8 word renders `,c`
instead of saying nothing about its fetch at all (35 sites of `804.8.16.415`).
The MAME sync list of `analysis/isa-adjudication.md` §9 is **drained** — all
thirteen items landed, on both sides, in `kn7000_mame/notes/dsp-mirror-sync.md`.
The executor's own cursor advance was wrong in the other direction: it read
`class4 & 8`, i.e. it advanced on classes 8, 9, A, B, C, D, E **and** F.

## Decoded forms — the ones with a real mnemonic

Each carries its evidence in `tools/dsp_disasm.py` next to the code that emits it.
A word is in this table only if a core could **execute** it.

> ⚠ **The two disassemblers are CHECKED identical, not assumed identical.**
> `kn7000_mame/tools/upd6383d_diff.sh` runs `tools/dsp_disasm.py` and MAME's
> `upd6383d.cpp` over all **3057** corpus words and diffs them line for line:
> **3057/3057**. Run it after touching either file. They had genuinely diverged —
> for most of 2026-07-26 the C++ side carried the ALU decode and this side carried
> `ldptr.d` / `setvec` / the C-format split, and nothing noticed.

| form | mnemonic | operation | status |
|---|---|---|---|
| `000.2.00.000` | `nop` | — | **INFERRED**, strengthened. *Corrected:* the earlier "PROVEN BY CONSTRUCTION, writer `LABEL_038922`" was wrong — that routine emits `801.0.NN.825` plus a tag-`0x4C` coefficient packet and never emits this word (`analysis/k5-output-stage.md` §5.7). New support: R1's inductive closure requires the two words between consecutive all-pass cores to leave **all four** modelled registers untouched (113 of 114 cores), which is what a `nop` does. Still an inference — it inherits the all-pass reading |
| `801.0.NN.821` | `ldptr #$NN` | load the **C-RAM pointer** (not the cursor) with the absolute C-RAM address `NN` | **PROVEN BY CONSTRUCTION** for the encoding (writer `LABEL_0387E6`: `addr8` is built as `(P>>4)` into byte 2's low nibble and `(P&0xF)<<4` into byte 3's high nibble, and `lo12` bit 11 is added by a literal `INC 8, WA`, so the payload is exactly 8 bits and bit 11 is a separate flag). **UPDATED by K3 (`analysis/k3-pointers.md`): the host-stream and in-program meanings are THE SAME — both name a C-RAM pointer.** The three in-program payloads `0x70` (unit 0), `0x50` (unit 1), `0x90` (output stage) are the three non-zero structural bases of the host's own C-RAM map (two tap tables + the reverb coefficient bank), 3/3 on a mechanically-derived 4-cell target. What it is **not** is the implicit coefficient cursor — that is FORCED against by the CHORUS wrap-constant join. So C-RAM has **at least two independent pointers**. Which architectural register (CP/DP/BP1/BP2/PR1/PR2): OPEN |
| `801.0.00.021` | `rstcur` | reset coefficient cursor to base | **VERIFIED** (algo39 section starts 0,6,12,18,24 \| rstcur \| 0,6,12,18,24). K3: this is the **same word as `ldptr` with `lo12` bit 11 CLEAR** — same `hi12`, same `class4`, same low byte `0x21` — and it is the **only** `hi12 == 0x801` word in the 2974-word body corpus (1/2974) |
| `801.0.NN.825` | `ldptr.d #$NN` | load the **delay-DESCRIPTOR pointer** with the absolute bank index `NN` | **PROVEN BY CONSTRUCTION**, both halves. *Encoding:* writer `LABEL_038922` emits the same four payload steps as the coefficient writer `LABEL_0387E6` — byte for byte, only `ADD XWA,#4Ch` vs `#26h` differs. *Space:* the packets it heads carry host tag **`0x4C`**, and a cell of that bank holds `LINE_BASE + DELAY_IN_SAMPLES` (`ADD (XSP+002h), XWA`). K3 reached the same space by elimination and labelled it INFERRED; **R3 proved it and named it** (`analysis/r3-delaydram.md` §1). Promoted to tier 1 in the adjudication pass — 3 sites, all in the resident kernel |
| `000.1.NN.000` | — | load the pointer for the **state RAM (D-RAM)** | **PROVEN BY CONSTRUCTION** — writers `LABEL_03846C` / `LABEL_038539` / `LABEL_038CF9` emit `00 00 10\|(P>>4) (P&0xF)<<4 00` plus a tag-`0x15` value packet. **NEW in K3**: this whole family was missing from the writer list. Space = D-RAM, MEASURED — the host zero-fills exactly the cells the freshly-loaded body uses, and PARAMETRIC EQ's fill is 40 cells at `0x50..0x77` = 5 bands × 2 channels × 4 Direct-Form-I state words |
| ★ **the ALU** — see below | `ld` / `mac` / `post` `[.ta\|.tb\|.st]` | `lo12` **ROUTES** and `hi12[3:1]` **OPERATES** | **VERIFIED to 0.094 dB** worst case over 8 ROM coefficient banks, 11 biquad sections, 4 programs (`kn7000_mame/notes/dsp-alu-applied.md`). **1029 corpus words**, against 273 for every other form put together |
| `C4x.x.xx.445` `C4x.x.xx.446` | `setvec unitN,#A` | load unit *N*'s **call-vector register** with I-RAM address `A = bits[24:17]` | **DETERMINED** — `analysis/k5-output-stage.md` §2. NEW in this pass |

### ★ THE ALU — `lo12` routes, `hi12[3:1]` operates

```
      L    := src[ lo12[10:6] ]      07 mem[p]  10 acc  19 tempA  1A tempB
      if hi12 bit 4 :  mem[p] <- acc ; acc := 0                store AND clear
      hi12[3:1]     :  0 -> acc <- P    1 -> acc += P    2 -> acc unchanged
      lo12[4:0]     :  13 -> tempA <- L   14 -> tempB <- L   07 -> mem[p] <- L
      if class4 == A :  P := coef[cursor++] * L
      if class4 & 7 == 2 :  p += (s8)addr8
```

`P` is **not consumed** by the add — an MPLY output latch holds it until the next
multiply, and `hi12[3:1]` decides whether this word takes it.

**This SUPERSEDES three rows this table used to carry** — `202.A.dd.1D5 mac`,
`202.A.dd.1D4 mac.lb` and `212.A.dd.407 mulst`. They are the same instruction seen
through a narrower window: `202.A.dd.1D4` is simply source `mem[p]`, action
"capture tempB", operation "acc += P", class A. Nothing the 19,674,720-point
constraint search determined is contradicted; what changes is that its per-word
"accumulator op" table was an artefact of a hypothesis space that never offered a
store-and-clear.

Two independent blocks force it. **(a)** The PARAMETRIC EQ's nine-word biquad is
the only block whose arithmetic is known independently — the firmware designs its
coefficients with its own `tan()`-based bilinear designer — and the model above
reproduces its transfer function to **max 0.094 dB / 4.0°** over 8 ROM banks in 11
section instances across 4 programs, with the residual falling with signal level
(i.e. 24-bit state quantisation, not a structural error). Removing either
non-obvious part — the accumulator CLEAR riding on `hi12` bit 4, or the one-bit
right shift on the tempB path — costs **57 dB** and **77 dB**. **(b)** The LFO is
what puts the operation in `hi12` and not in `lo12`: `092.A.dd.200` and
`094.A.dd.200` are identical in `class4`, `addr8` and **all twelve `lo12` bits**,
and no single operation applied twice with their two constants makes a ramp.

**Still OPEN**, and the decoder guesses none of it: 14 of the 18 observed SRC
codes, 19 of the 24 observed ACTION codes, `lo12` bit 4, the difference between
actions `0x12` and `0x15`, five of the eight `hi12[3:1]` codes, and the `lo12`
bit-11 **modifier** (PROVEN BY CONSTRUCTION to be a separate flag, so `0x021` and
`0x821` are one route plus a modifier — never two codes).

### `setvec` — the evidence

* The **only two I-RAM words the host ever rewrites** are I-RAM **64** (`lo12 = 0x445`)
  and I-RAM **71** (`lo12 = 0x446`); a scan of the whole 192 KB Sub CPU image finds
  exactly four well-formed writes to them, and they are the four `EFF_Disconnect` /
  `EFF_Link` scripts, indexed by **effect unit**. The firmware's own debug strings are
  `"EFF n disconnect."` / `"EFF n link."`, and the unit→chip table `0x01ED6D` =
  `{0,0,1,1,1}` puts exactly units 0 and 1 on this chip. **PROVEN BY CONSTRUCTION.**
* The immediate is `bits[24:12]`, and **every one of the 11 distinct values across all
  61 occurrences of the family is a multiple of 32** (P ≈ 1e-15 under a uniform null),
  so the payload is `A = bits[24:17]`. **MEASURED.**
* Decoded that way the four written values are **84 / 42** (unit 0) and **200 / 50**
  (unit 1). Walking the 100-entry algorithm table: of the **91** streams that yield a
  valid I-RAM image, **79 load at I-RAM 84 and 12 at I-RAM 200 — nothing else** (91/91).
  42 and 50 are the first words of the header's own unit-0 / unit-1 setup blocks, and
  the return-tag constraint independently confines the unit-0 vector to 0..49 and the
  unit-1 vector to 50..59. **DETERMINED.**
* Honest limit: the tag constraint narrows each vector to a *range*, it does not single
  out one address. What carries the reading is that both values land in the correct and
  *different* window, and both on a structural boundary.
* This also settles a K1 alternative: the unit entry points are **host-loaded registers**,
  not a fixed 2-entry vector table.
* Third state, MEASURED and previously unrecorded: the canned boot image holds
  `011.9.0E.445` / `011.9.0F.446` at those slots — same `lo12`, so the destination is the
  same register, but the **source field is OPEN**. `hi12 = 0x011` and
  `class4 == 9 && addr8 ∈ {0E,0F}` occur **0 times** in the 2974-word body corpus.

## Operations DETERMINED, operand encoding still OPEN — a separate tier

These words **cannot be executed** (we do not know where their address comes from),
so they are *not* in the table above and keep the greppable `?word` prefix. But
calling them unknown would now be false. `tools/dsp_disasm.py::status()` reports
them, and `tools/dsp_coverage.py` counts them **separately — never added into the
decoded figure**.

| pattern | operation | status |
|---|---|---|
| `880.1.60.2D4` | external delay-DRAM **READ**; the data becomes visible **2–5 words later** | **DETERMINED** (R1 F1, F6) — the opposite direction has zero survivors in the base, 3-input-ALU and ALU-on-the-DRAM-word models alike |
| `880.1.20.655` | external delay-DRAM **WRITE** | **DETERMINED** (R1 F1) |
| `880.1.20.64B` | external delay-DRAM **WRITE** | **INFERRED** — same `lo12`-selected write-data source; 28/28 store-preceded |
| **every mode-1 + ESCAPE word** (`class4 == 1`, `hi12` bit 11 set, C-format excluded) — 276 of the 3057-word corpus | **external delay-DRAM access**, at `address = DESCRIPTOR_CELL[cursor] + G mod 2^N`: a host-written 24-bit descriptor bank reached through pointer `…825` / tag `0x4C`, one cell per DRAM word in program order. The address is **not in the word**, which is why these stay tier 2 | family **MEASURED** (R2, 324/324 against mode-1-without-escape = the register file); address model **PROVEN BY CONSTRUCTION** (R3 §1). ⚠ the C-format guard is mandatory — omitting it is what `analysis/isa-adjudication.md` §1 falsifies |
| `880.1.30.*` | the **first** DRAM access of a body — `addr8 = 0x30` marks it in **37 of 38** distinct images | **MEASURED** (R3 §6.2). *Corrected:* the old annotation "framing word, carries no DRAM information" was wrong — it is a DRAM word |
| direction of any **other** `880.1.*` / `800.1.*` / `900.1.*` form | **UNKNOWN** | ⚠ **`addr8` does NOT select the direction** — FALSIFIED by R3 §6.3: MULTI TAP DELAY's cursor alignment puts three of its four tap **READS** on `880.1.20.2C7` and its line **WRITE** on `880.1.60.000`. Direction must live in `lo12`/`hi12`. The `60`=read / `20`=write reading is FORCED for `2D4`/`655` (and inferred for `64B`) and **must not be generalised** |
| `(hi12 & 0xFFE) == 0xC40` | **13-bit immediate load**, `A = bits[24:17]`, `B = bits[16:12]`, destination named by `lo12` | format **MEASURED** (61/61 multiple of 32; `B == 0` in 57/57 body occurrences). Destination **OPEN** except for `lo12 ∈ {0x445,0x446}` (= `setvec`) |
| `102.A.**.64B` | class-A multiply whose **multiplicand is a sum of two registers** — neither `mem[p]` nor the incoming `acc` — i.e. a **fourth multiplicand route** beside `mac` (`0x1D5`), `mac.lb` (`0x1D4`) and `mulst` (`0x407`) | **FORCED under a two-input ALU** (R1 F8), 36/36. Falls to a three-input ALU (260 of 336 survivors take `mem[ptr]` there) — labelled model-dependent, not asserted |

**New MEASURED constraint on the C-format payload, and a caution.** Across the 38
distinct body images the payload `A` is a **function of `lo12`** — 7 distinct
`lo12` values, 7 distinct `A`s, no `lo12` ever carrying two — and `B` is 0 in all
57 occurrences:

```
   lo12 000 -> A=12 (reverb)     lo12 000 -> A=22 (8 algos)   lo12 1DA -> A=0
   lo12 359 -> A=29              lo12 44C -> A=25 (8 algos)   lo12 451 -> A=15
   lo12 647 -> A=40
```

That **supports** "`lo12` names the destination, everything above it names the
source", and it **cautions against** generalising K5's "`A` is an I-RAM address"
beyond `lo12 ∈ {0x445,0x446}`: a body word is loaded at I-RAM 84 or 200 and would
have no business pointing at I-RAM 12 or 25. `A` is better read as *an address in
whatever space `lo12`'s register addresses* — I-RAM for the call vectors, unknown
elsewhere. K5's K6 spin-off ("header w1's `A = 7` is the second input block") is
therefore **n = 1 in a different `hi12` sub-family** and stays INFERRED.

**`lo12` selects the MULTIPLICAND ROUTE.** The three multiply forms differ
only in `lo12` and only in where the multiplier reads: `0x1D5 → mem[p]`,
`0x407 → acc`. R1 adds a fourth route — the reverb's `102.A.**.64B` needs a
**sum of two registers**, which neither `mem[p]` nor the incoming `acc` can
supply, so `0x64B` routes something else (the word's own ALU result under a
2-input ALU; `mem[p]` pre-built under a 3-input one). Independent support for the
"`lo12` = route, `class4` = arithmetic" hypothesis (`-core-draft.md` §6 item 2).
See `analysis/r1-allpass-motif.md` §9.

The recovered interpreter reproduces the transfer function of nine real ROM
coefficient banks at max|err| = 0 (`notes/kn5000-dsp-semantics.md` §4) — the
biquad and reverb families are solved on top of these three multiply forms.

## Structural landmarks — annotated, NOT decoded

These are MEASURED *landmarks* whose semantics are unknown. They keep the `?word`
prefix (a landmark is not a decode; the `?` is the greppable worklist):

- **terminator / END OF BLOCK** — `class4==1 && addr8 ∈ {0E,0F}` carries a
  transfer of control (CALL/RETURN, unit-tagged); the untagged form falls
  through. `addr8` is the **unit index** (91/91), not the halt.
- **the ALL-PASS CORE** — six words, `880.1.60.2D4 | 104.2.00.000 | 000.2.00.419 |
  012.2.00.680 | 880.1.20.655 | 102.A.**.64B`, normally followed by two `nop`s.
  **114 occurrences, in 13 programs, all reverbs** (12 presets × 9 + GATED REVERB × 6);
  the only field that ever varies is slot 5's `addr8` (`0x00`×101, `0xBA`×12, `0xC4`×1);
  the inner four-word run is exceptionless 115/115. It is a **software-pipelined
  one-multiplier all-pass stage**: repetition *r* carries the arithmetic and the DRAM
  **write** of stage *r−1* together with the DRAM **read** and the **multiply** of stage
  *r*, because the multiply is the last of the six words and both DRAM words precede it.
  **Two role assignments survive the constraint search**; both reproduce a textbook
  all-pass cascade at max|err| = 0.000e+00 over all 12 preset banks and both ladder
  lengths, so the numbers cannot separate them. The corpus **ranks** — does not prove —
  the one in which `mem[ptr]` stages the DRAM write. Per-word roles must **not** be
  printed until that is settled (`analysis/r1-allpass-motif.md`).
- **LFO** — `hi12=0x082` read; `092.A.00.200` phase accumulate; `094.A.00.200`
  wrap on `0x7FFFFF`.
- **`C00` wait/sync** — both of the machine's `C00` words encode **their own I-RAM address**
  in bits[24:17] (`C00.9.84.000` @76 = 76*32+4; `C00.A.47.407` @82 = 82*32+7), the second
  being the frame terminator. INFERRED: "hold here until event bits[16:12]". It is a
  *positive* explanation for a fact that had none — the output stage contains **no
  end-of-block word at all**; a block that ends by waiting does not need one.
- **host coefficient poke** — `0A aa bb cc dd` is NOT an instruction: it is a host-port
  packet carrying a 24-bit coefficient `((aa&0x7F)<<17)|(bb<<9)|(cc<<1)|(dd>>7)` with a
  destination tag `dd & 0x7F` (`0x26` ↔ register `…821`, `0x4C` ↔ `…825`, `0x15` ↔ the
  register set by `000.1.06.000`). **PROVEN BY CONSTRUCTION** from the three Sub CPU
  writers. It is decoded by `dsp_disasm.host_packet()`, which a host-stream viewer calls
  explicitly; the old `hi12[11:8]==A → host-poke` *annotation* was removed because it
  fired on in-program words.
- **table-lookup idiom** — `040.0.00.C63 | 000.6.TT.4CD | 012.4.01.1CE` (class-6
  `addr8` = table selector); accounts for every class-4/6 word, MCC +1.000.
- **class 8** — post-sum step (rescale/round/saturate?), **operation unknown**;
  its *position* is determined, not its operation. It **fetches** a coefficient
  (bit 23) but does **not** advance the cursor (K4, FORCED — see the `hi12` table).
- **the class-1 REGISTER FILE is banked per effect unit, bit 7 = the unit** (K4,
  `analysis/k4-cursor.md` §4). Over the 91 well-formed parameter streams the host's
  `000.1.NN.000` register selects split **100 %**: 368 packets / 23 distinct `NN`
  all `< 0x80` in unit-0 streams, 60 packets / 5 distinct `NN` all `≥ 0x80` in
  unit-1 streams, and **5 of 5** unit-1 numbers are a unit-0 number `+ 0x80`
  (`85 87 8A 94 D0` ↔ `05 07 0A 14 50`). The boot blob at `0x01E6BE` writes the
  matched pair `000.1.06.000` / `000.1.86.000` back to back — PROVEN BY
  CONSTRUCTION. This resolves K6's "class-1 `addr8` splits on bit 7" lead, and it
  is **the only place the `+0x80` displacement is real**: it is *not* a C-RAM
  split. Caveat: the shared output stage names `0x85/0x8C/0x8D/0x8F` (unit-1 half)
  and only `0x06` from the unit-0 half, which is unexplained. The delay-DRAM
  sub-ops `0x20/0x30/0x60` are discriminated from register addresses by **`hi12`**
  (the `0x8xx`/`0x9xx` escapes), not by `addr8` bit 7.
  **Named cells so far:** `0x06`/`0x86` = the per-unit OUTPUT LEVEL (R2, PROVEN BY
  CONSTRUCTION) and `0x50`/`0xD0` = the per-unit STATE-BLOCK BASE (MEASURED,
  87/91 — `analysis/isa-adjudication.md` §5). That §5 also **adds two pairs to
  K4's list**, `0x06`/`0x86` and `0x0B`/`0x8B`, from the shape of the host's
  zero-fill.
- **P-consumers / carry latches** — `lo12 ∈ {647,687,1D3,1D4}`.
- **`hi12=0x212`** — ⚠ the old "writes `mem[ptr]` in **every class**" is
  WITHDRAWN (R2). Bit 4's target is **mode-dependent**; `mem[ptr]` is the mode-2
  target, and the universal reading manufactures four dead stores in the 23-word
  output stage. `hi12=0x102` is the shared gain multiply of the phaser all-pass
  and reverb diffuser.
- pointer-load siblings `lo12 ∈ {820,822,825,827}` — K3 updates this. `0x825`'s
  space is INFERRED (the tag-`0x4C` space, payloads `0x25`/`0x25`/`0x26` against a
  2-cell boundary set); `0x822` occurs once, at `w77`, where R2 reads `addr8 = 0x86`
  as unit 1's output-level register; `0x827` (payloads `0x6C`/`0x64`) and `0x820`
  (five header words, a 13-bit immediate, and the only sub-family whose payload is
  *not* a multiple of 32) are **OPEN**, with the alternatives enumerated in
  `analysis/k3-pointers.md` §5. `lo12` bit 11 is a **separate flag** built by a
  literal `INC 8` in the writer, and `rstcur` = `801.0.00.021` is the same word with
  it clear — the only `hi12 == 0x801` word in the 2974-word body corpus.

## Addressing — MEASURED

> **Superseded in part by R2 (2026-07-26).** There *is* an encoded space-selector field
> after all — `hi12` bit 11 — and `class4`'s low three bits are an **addressing mode**.
> See the next section; the pointer-identity statement below survives only as a
> description of **mode 2**.

There is **no encoded space-selector field**; the memory space is
**pointer-identity** (`notes/kn5000-dsp-spaces.md`):

- **C-RAM** (coefficients) — reached ONLY through the implicit coefficient
  cursor: base **0x00** (MEASURED across all 16 swept effects), **+1 per class-A
  word**, reset by `rstcur`. Every class-A word therefore reads a coefficient at
  a **known absolute C-RAM address** — the disassembler prints `; C-RAM[0xNN]`.
  A **C-format** word does *not* advance the cursor (its `class4` is immediate
  data). The unit-1 reverb bank base is **0x90**, now **PROVEN BY CONSTRUCTION**:
  every type-2 coefficient block in the parameter stream is preceded by a literal
  `08 01 09 08 21` packet, which *is* `801.0.90.821` = `ldptr #$90` in the writer
  encoding proven in `analysis/k5-output-stage.md` §1.2. GATED REVERB, a unit-0
  program, says `ldptr #$00`.
  **The whole 256-cell map is now MEASURED** (`analysis/k4-cursor.md` §1):

  ```
     0x00..0x4F  unit-0 effect coefficient bank   (79/79 unit-0 streams: ldptr #$00;
                                                   largest cell ever used 0x2C)
     0x50..0x6F  RESIDENT TABLE A, 32 cells  = (32+k)*0x400   \_ written ONCE, by a
     0x70..0x8B  RESIDENT TABLE B, 28 cells  = min(1214k,32767)/  LITERAL uC-IF blob at
     0x8C..0x8F  never written                                    Sub CPU ROM 0x01E6BE
     0x90..0xB5  unit-1 effect coefficient bank   (12/12 unit-1 streams: ldptr #$90
                                                   +30, ldptr #$AE +7)
     0xB6..0xFF  never written
  ```

  No parameter stream ever points at `0x50..0x8B` (0 of 91), so the tables are
  resident — **a C-RAM model that starts zeroed and only replays parameter streams
  reads zeros for every table lookup.** `0x90` is simply the first 16-aligned cell
  after the tables: the split is a **software allocation**, not a hardware bank
  (the base is a literal in each parameter script, and `LABEL_0387E6` builds a poke
  address with an 8-bit *add*).
  **The REBASE between the two units is FORCED to exist but is NOT IDENTIFIED**
  (`analysis/k4-cursor.md`): a free-running cursor cannot give the constant `0x90`
  (the unit-0 class-A count varies 6…60 over 24 values); it is not in any body (the
  intersection of the 37 unit-0 images' pre-first-class-A prefixes is empty); and it
  cannot carry `0x90` as an immediate — an exhaustive search of every contiguous
  8–16-bit field of I-RAM 50…59 finds it nowhere, and `0x90` occurs as an aligned
  field in **1 word of 3057** (I-RAM 69, which runs *after* the unit-1 body).
  **⇒ the chip must hold a per-unit COEFFICIENT-BASE register holding an arbitrary
  8-bit value, and the rebase copies it.** Leading candidate instruction:
  `800.1.60.00B`, which occurs exactly twice in the machine, once at offset +4 of
  each per-unit setup block and nowhere else. ENUMERATED, not decided.
- **D-RAM** (state) — reached through the signed-`addr8` data pointer (`mem[ptr]`)
  in mode 2. Its absolute base is **still unpinned**, so **no D-RAM absolute is
  printed**. ⚠ **Corrected by K3 (`analysis/k3-pointers.md`): the header's per-unit
  `0x70` / `0x50` are NOT the D-RAM base** — they are **C-RAM** addresses, and
  specifically the bases of the two tap tables the host writes at C-RAM `0x50` and
  `0x70`. *(Beware the numerical trap: C-RAM `0x50` and register-file `0x50` are
  different spaces that happen to share a number — conflating two 256-cell spaces
  is exactly what produced K6's withdrawn headline.)*
  ⚠ **K3's replacement candidate `lo12 = 0x827` (payloads `0x6C`/`0x64`) is now
  WITHDRAWN too** (`analysis/isa-adjudication.md` §5.1). It was inferred by
  elimination and had no positive test; the one available test — *the host's
  zero-fill must clear the state the body reads* — puts the filled block inside
  the body's pointer reach in **0 of 85** streams under `0x6C`/`0x64`, against
  **47 of 85** under the fill's own base `0x50`/`0xD0`. **The slot is OPEN.**
  `0x50`/`0xD0` is the better-supported candidate and would pin the origin *if*
  the mode-1 index space and the mode-2 pointer space are one RAM reached two
  ways — but 47/85 is not a pin, the walk model behind it is naive (one
  continuous walk, no mid-body reload), and the residual failures are **not**
  explained (uncovered offsets split 94 odd / 69 even, so the tempting
  "stereo bodies walk twice" story is *not* supported). ENUMERATED, not picked.
- **C-RAM has at least TWO pointers** — the implicit cursor *and* the register
  `lo12 = 0x821`, which is FORCED not to be the cursor (K3 §4.2). The host's C-RAM
  map has exactly four structural bases, `{0x00, 0x50, 0x70, 0x90}`, and the two
  the cursor does not supply are exactly the two `0x821` is loaded with per unit.
- **external delay RAM** — reached through the **mode-1 + ESCAPE** family (R2's
  predicate, C-format excluded). ⚠ *"How the address is supplied is OPEN — the
  largest single hole in the machine"* is **no longer true**. R3 answered it, and
  the address is not in the instruction at all:

  ```
     delay-DRAM address = ( DESCRIPTOR_CELL[cursor] + G )  mod 2^N
  ```

  **PROVEN BY CONSTRUCTION** (`analysis/r3-delaydram.md`): the descriptors are a
  host-written 24-bit register bank addressed by pointer `…825` with host tag
  `0x4C` — the delay twin of the coefficient bank behind `…821` / tag `0x26`,
  written by the *same four instructions* in the Sub CPU. **A cell holds
  `LINE_BASE + DELAY_IN_SAMPLES`: a delay is an ADDRESS, and a line's delay is
  the DIFFERENCE of two cells.** No length, mask or wrap register exists
  anywhere, which is why the model needs a single global rotation `G`. The
  authoring chain is `cell = K24 + ms × 44100/1000`, opcode `0x67` — the only
  opcode in the firmware that can write a descriptor.
  **MEASURED:** unit 0 owns `[0x0000,0x8000)`, unit 1 (the twelve reverbs)
  `[0x8000,0x10000)` — 32,768 words = **743.0 ms** each; the largest address the
  firmware ever emits is 64,899, so bits 16/17 are never exercised.
  **VALIDATED end to end:** `SINGLE DELAY` slot 0 = `DELAY L (ms)` → cell `0x26`,
  and the ROM ships **15,435 = 350 × 44100/1000** exactly; its right channel gives
  the same 350 ms out of a different base.
  ⚠ **Every delay length this tree used to print was HALF the real one** — the
  payload is the 24-bit poke value `2×raw + tagbyte bit 7`, not the raw three
  bytes. `ROOM REVERB 1`'s ladder is `255 869 979 366 1044`, not
  `127 435 489 183 522`; its pre-delay is 8,905 samples, not 4,452.
  **OPEN:** the descriptor cursor's per-unit phase; the per-word READ/WRITE
  assignment; `N`. The counting model behind the cursor is **a good fit, not
  exactly satisfiable** — see the Corrections table.
- **the internal REGISTER FILE** (mode 1 **without** the escape) — indexed
  directly by `addr8`, bit 7 = the effect unit. Named cells so far:
  **`0x06` / `0x86` = the per-unit OUTPUT LEVEL** (PROVEN BY CONSTRUCTION, R2 —
  the last four host actions of cold boot) and **`0x50` / `0xD0` = the base of the
  per-unit STATE BLOCK** (MEASURED, `analysis/isa-adjudication.md` §5: in **87 of
  91** parameter streams the host's tag-`0x15` zero-fill is `{low unit-tagged
  registers} ∪ {a CONTIGUOUS block based at exactly 0x50 / 0xD0}`; PARAMETRIC
  EQ's is the 40-cell one, `0x50..0x77` = 5 bands × 2 ch × 4 Direct-Form-I state
  words). That names the pair R2 could only observe being cleared together, and
  gives `w53` (`010.9.D0.20C`) a job — its unit-0 partner `w45` (`010.A.00.20C`)
  shares `lo12 = 0x20C`.

## `class4 & 7` is an ADDRESSING MODE, and `hi12` bit 11 picks the SPACE — MEASURED

New in **R2** (`analysis/r2-output.md`). Classifying all 2989 non-C-format words by
`mode = class4 & 7`, cursor-fetch (`class4 & 8`) and the FORMAT ESCAPE bit:

```
   mode  cur  ESC     n                       mode  cur  ESC     n
    0    no   no     62                        2    no   no   1556
    0    no   yes    47                        2    yes  no    843
    0    yes  yes    44                        4    no   no     53
    1    no   no     48                        4    yes  yes     1   <- epilogue w73
    1    no   yes   276                        5    no   yes     1   <- epilogue w67
    1    yes  no      4                        5    yes  yes     1   <- epilogue w78
                                               6    no   no     53
```

* **Mode 2 — the only mode that moves the data pointer — is NEVER escape: 0 of 2399.**
  Mode 6 is never escape either. So **`hi12` bit 11 = "this word does not address D-RAM
  through the data pointer"**, which is *why* `addr8` is a sub-op on the `880`/`800`/`900`
  family. Exceptionless over the whole 3057-word corpus.
* **Mode 1 without escape is an internal REGISTER FILE indexed by `addr8`.** Its index space
  is a subset of the space the host itself addresses with `000.1.NN.000` — `0x06`, `0x85`
  and `0x8A` are poked by the host at cold boot — and the host stream proves the file
  **auto-increments** (a 9-select run `0x1D,0x21,…,0x3D`, stride 4, four values each,
  tiling `0x1D..0x40`). **Mode 1 with escape is the external delay DRAM.** 324/324.
* **Bit 7 of a register index is the EFFECT-UNIT selector** (0 = unit 0, 1 = unit 1): five
  independent positional confirmations (`w63`/`w70` sit immediately before the unit-0 /
  unit-1 vector words; header `w58` and `w53` are inside the unit-1 setup block; the
  epilogue's unit-1 run), zero counter-examples, and the host clears the indices in
  bit-7-matched pairs `0x05/0x85`, `0x06/0x86`, `0x07/0x87`, `0x50/0xD0`.
* The exception is `addr8 ∈ {0x0E, 0x0F}`, where **`hi12` bit 10 (END) is also set**: there
  `addr8` is the **unit tag**, 40/40. Bit 10 re-purposes `addr8` exactly as bit 11 does.
* **Classes 3, 7, B, E, F do not exist.** All 31 words that appear to be class 3 are
  C-format words whose `class4` field is immediate data.

**Consequence for `hi12` bit 4 (STORE).** Its target is **mode-dependent**, not universal.
`mem[ptr]` is the mode-2 target only. Two mode-1 bit-4 words have a DETERMINED destination
in the **register** space — `w64`/`w71`, the call vectors (K5) — and `w60`/`w61` are adjacent
mode-1 stores with no pointer-moving word between them, so under a `mem[ptr]` target the
first would be provably dead. The old "`hi12=0x212` writes `mem[ptr]` in every class" reading
produces **four dead stores in the 23-word output stage**; the corrected one produces none.

### Registers `0x06` / `0x86` are the per-unit OUTPUT LEVELS — PROVEN BY CONSTRUCTION

The last four host actions of the cold-boot capture, in order, are
`setvec unit1,#200` (I-RAM 71), `setvec unit0,#84` (I-RAM 64), `reg 0x06 ← +0.500000`,
`reg 0x86 ← +0.183992` — one level per unit, in bit-7 order, immediately after linking, and
both registers were cleared to 0 at reset. This also re-confirms `setvec` from the **live**
stream (K5 proved it from the ROM; the chip is seen receiving `A = 84` and `A = 200`).

### The DO write — `w73` / `w78`, the item K5 left OPEN

Only **3 of the 370** escape words in the machine carry `hi12` bit 4, and only **1 of the 68**
C-format words does; all four are `w73`, `w74`, `w77`, `w78`, in two groups either side of
the wait word `w76`. `w72` reads unit 0's level register `0x06`; `w77` aims a pointer at
unit 1's level register `0x86`; `w74`'s C-format immediate is `A = 77` (= `w77`) and `w75`
carries `addr8 = 0x0F`, the unit-1 tag. ⇒ **`w73` presents the unit-0 result on DO1 (→
IC303.SDIA) and `w78` the unit-1 result on DO2 (→ IC303.SDIB); DO3 is never written.**
The L/R split within a port is enumerated, not settled (`analysis/r2-output.md` §3.3).

### Where a unit result goes — FORCED

The output stage performs **zero D-RAM reads before either presentation** (its only three
mode-2 words are at positions 19/20/21 of 23, and K6 forced those to be the one-frame
feedback loop), and unit 0's result must survive **156 intervening words** between its return
at header `w49` and `w73`, so it is not in the accumulator either. ⇒ **the per-unit result is
held in a dedicated register, loaded at the body's terminator** — the only word every body
executes at that moment, and the only one that names a per-unit index. The terminator's
optional bit-4 store is *not* the mechanism: only 5 of 38 bodies set it
(`612.1.0E.000` ×4, `612.1.0F.000` ×1, against the minimal pair `602.1.0E.000` ×3).

## Control flow — INFERRED/PROVEN mix

- **Per-frame hardware PC restart.** The PC sweeps I-RAM once per sample frame
  (Fs-RST / PC-RST pins); 25 MHz / 44.1 kHz = 567 cycles per frame against 384
  I-RAM words — room to spare, as some words take >1 cycle.
- **The 83-word resident kernel is TWO canned blobs**: the 60-word common header
  (`kernel.dsm`, I-RAM 0..59, Sub CPU ROM `0x01E496`, shipped by `EFF_WriteHeader`)
  and the 23-word **output stage** (`epilogue.dsm`, I-RAM 60..82, ROM `0x01E63C`,
  shipped by `DSP_AlgorithmChange`). Both are literal — **no kernel word is
  computed by the firmware** (PROVEN BY CONSTRUCTION, `analysis/k5-output-stage.md`).
- The header loads pointer registers, then
  CALLs the unit-0 body (I-RAM 84) and the unit-1 body (I-RAM 200) via a shared
  call/return encoding (the unit-tagged END-OF-BLOCK word), with a **2-level
  stack**. PROVEN BY CONSTRUCTION from the header loading registers 821/827/825
  twice (I-RAM 42–44 and 50–52), so a body must run and return between them
  (`notes/kn5000-dsp-headerdecode.md`). The **entry addresses are host-loaded
  registers**, not a fixed vector table: the output stage's I-RAM 64 and 71 load
  them, and the host rewrites those two words to link (84 / 200) or disconnect
  (42 / 50) each unit. Then the frame ends in the output stage, at the wait word
  I-RAM 82.
- **Effect bodies are straight-line, HAND-UNROLLED.** No branch word carrying the
  body entry addresses 84/200 exists; an exhaustive field scan for a branch is
  negative, and there is a positive reason — algo16 repeats 32 words at period 8
  varying only `addr8`, algo39 repeats 9 words at period 9. There is no loop to
  branch back to (`notes/kn5000-dsp-necfamily.md` §6).

## Coverage — honest, and in two tiers that are never added together

Every number here comes out of one runnable tool, so this section cannot drift
away from the disassembler:

```
python3 dsp/tools/dsp_coverage.py
```

**TIER 1 = DECODED** — a real mnemonic; a core could execute the word.
**TIER 2 = OPERATION ONLY** — determined or measured operation, operand encoding
still open, so the word *cannot* be executed. The combined column is printed only
so that nobody has to add the two by hand and get it wrong.

```
region                          words   tier1  tier1%    tier2   t1+t2%
resident kernel I-RAM 0..82        83       6    7.2%        6    14.5%
   ...header  I-RAM  0..59         60       4    6.7%        4    13.3%
   ...output stage 60..82          23       2    8.7%        2    17.4%
   ...output stage AS LINKED       23       4   17.4%        0    17.4%
reverb image (algo 16)            133      26   19.5%       32    43.6%
FRAME FLOOR kernel + reverb       216      32   14.8%       38    32.4%
FRAME FLOOR as linked             216      34   15.7%       36    32.4%
all 38 distinct body images      2974     267    9.0%      329    20.0%

distinct undecoded words           655
distinct undecoded FAMILIES        185
images with ZERO tier-1 words     8 of 38
```

**Read that honestly.** On the frame floor tier 1 moved from **29/216 = 13.4 %**
to **32/216 = 14.8 %** (as linked, 31 → 34 = **15.7 %**). The whole tier-1 gain is
**three words**: the `ldptr.d #$NN` sites at I-RAM 44, 52 and 62, promoted because
R3 proved *both* halves of `801.0.NN.825` by construction — the encoding from the
writer and the space from the tag. That is the honest size of it.

Tier 2 moved much further — frame floor 35 → **38**, bodies **230 → 329**
(16.7 % → **20.0 %**) — because the delay-DRAM family widened from
`hi12 == 0x880, addr8 ∈ {0x20,0x60}` to R2's real predicate (mode 1 + ESCAPE,
C-format guarded), and because R3 supplied the address model that makes those
words describable at all. They stay tier 2 for a good reason: the address comes
from an implicit descriptor cursor, so the word still cannot be executed in
isolation.

**What did not move, and why that is the interesting number:** `distinct
undecoded words` is still **655** and `distinct undecoded FAMILIES` still **185**.
Four analysis passes and an adjudication added mnemonics, killed six wrong
readings and explained where two whole address spaces come from — without
reducing the undecoded vocabulary by one entry. The long tail is untouched.

The tier-2 words are worth their own line because of *what* they are. The
standing complaint (`notes/dsp-critical-path-coverage.md` headline 2) was that
**not one decoded word sat on the audio boundary** — all six moved data between
the cursor, the pointer, the accumulator and P, so the decoded subset could not
get a sample in, could not get one out, and could not even enter a body. That is
no longer true in either tier: `setvec` (tier 1) is how a body is entered at all,
`ldptr.d` (tier 1) is how the delay-line addresses are aimed, and the delay-DRAM
family (tier 2) is how the lines are reached — **with a proven address model**,
which is new: `DESCRIPTOR_CELL[cursor] + G`. **DI and DO are still untouched by
every *decoded* form**, so a sample still cannot get in or out — but R2 has now
*identified* the two words that present the results (`w73` → DO1, `w78` → DO2,
and DO3 never written), so the remaining boundary problem is one of decoding two
named words rather than of not knowing which words to look at.

```
class-A multiplies (coefficient consumers)     822
  operand ROLE named (host C-RAM coeff join)   500   (60.8 %)
    391 individually-addressed T1 writers  +  109 block-upload cells
    (op0x73 = 5-cell bilinear filter section 103, op0x77 = ENSEMBLE depth 6)
  operand ROLE still unnamed                   322
```

**Role known ≠ full word decode.** The 60.8 % is the fraction of class-A
*multiplies* whose coefficient OPERAND has a named role (which C-RAM cell it reads
and what the host wrote there); the multiply MICRO-OP is one of the three DETERMINED
forms, but the block-coefficient roles (op0x73/op0x77) are INFERRED, not per-cell
decodes like the biquad's. The two figures measure different things and this
tree does not launder one into the other.

**Most of the instruction set is still unknown.** The distribution has a long
tail: the top 40 words are 46 % of undecoded occurrences and the top 29 families
55 % — there is no small set of words that unblocks everything.

### The worklist, re-ranked after K5, R1, R2, K3, K4, R3 and the adjudication

The old **#1 — "the external delay-DRAM ADDRESS path, the single largest hole"** —
is **answered** (R3; see Addressing). What replaces it at the top is smaller and
sharper, because the two structural spaces (coefficients, delay descriptors) now
both have a decoded pointer and a proven writer, and what is left is *direction*
and *phase*.

1. **DIRECTION of the delay-DRAM words.** We know which family touches the DRAM
   (276 words), where its address comes from, and which cell each word gets — but
   for all but three forms we do not know **read or write**. `addr8` is FALSIFIED
   as the selector (R3 §6.3), so it lives in `lo12`/`hi12`. Deciding it also
   decides R1's O-1 (its two surviving role families) *and* R3's O-2 in one move,
   and it is what stands between the reverb model and an audible tail. Purely
   static; the cribs are the store-preceded split (`0x64B`/`0x655` 44/44 versus
   four forms at 0/56) now that `0x2C7` is known to be a READ.
2. **The descriptor cursor's per-unit PHASE.** Unit-0 bodies start at cell `0x26`,
   unit-1 bodies at `0x00`. New evidence the enumeration did not have
   (`analysis/isa-adjudication.md` §6): there are **three** `…825` loads, not two —
   the output stage's `w62` loads **`0x26`**, exactly unit 0's region base, so the
   frame *ends* by aiming the descriptor pointer at unit 0's first cell. That is
   direct support for R3's resolution (i) and changes the arithmetic of (iii).
3. **The reverb's four surplus descriptor cells** (`analysis/isa-adjudication.md`
   §2.2) — 32 written, 28 consumed. Resolving it repairs the counting model that
   the adjudication downgraded, and the leading candidate is testable: under R3's
   reading a reverb DRAM word addresses cell `0x1E = 32767`, the *only* reverb cell
   outside unit 1's own region.
4. **The C-format destination register file.** `lo12 ∈ {000,1DA,359,44C,451,647}`
   each carry one fixed payload `A`; naming even one turns a MEASURED format into a
   decode. New crib: `A` is **bounded by the block it lives in** — 11/11 kernel
   words have `A ≤ 82` (the kernel is 83 words, `P ≈ 4×10⁻⁶`) and 57/57 body words
   have `A ≤ 40`.
5. **The six `op 0..5` uC-IF handlers** at `0x03C32E + OFFSETS_14739[op]` — the
   definition of commands `0x01/0x02/0x04/0x09/0x0C/0x30`. The ASL source renders
   them as `db …`; disassembling them is pure static work and would explain the
   whole host interface. **K4 promoted this**: it is the one static test that can
   decide *who* loads the per-unit coefficient-base register the cursor rebase is
   FORCED to read from (`analysis/k4-cursor.md` §5.2, E1).
6. **Are the mode-1 register file and the mode-2 D-RAM one space?** If yes, the
   D-RAM origin is pinned at `0x50`/`0xD0` and every listing can print D-RAM
   absolutes. The evidence is 47/85 versus 0/85 for K3's withdrawn candidate; what
   it needs is a **better pointer-walk model** (mid-body reloads), which is static
   work on the 38 body images.
7. `212.2` vs `212.A` — bit 23 on a family whose class-A form is determined.
8. the `lo12 = 0x415` group across classes A/2/8 (tests "lo12 = route, class4 =
   arithmetic", brings class 8 along).
9. the table-lookup triple (`040.0.00.C63 / 000.6.TT.4CD / 012.4.01.1CE`).
10. the remaining 73 kernel words — where `COND`, `BRAKST` and the GF flags must
   live. Standing warning: **65 of the kernel's 75 families never occur in the
   2974-word body corpus**, so frequency-ranked worklists are structurally blind to
   exactly the code that carries the audio. Note also that the output stage is
   **lexically disjoint** — 20 of its 23 words, 14 of its `lo12` values and 13 of
   its `hi12` values occur nowhere else (R2).
11. **Where the C-RAM cursor's per-unit base comes from.** K3/K4 sharpened this to
   a choice between a per-unit BASE REGISTER copy (K4 FORCED that one must exist,
   and that it is *not* a power-of-two bank), the unit-tagged transfer, and the
   frame restart. Purely static.
12. the actual µPD6383 datasheet/databook — would hand over the whole ISA.

**What genuinely needs hardware, and nothing else will do:** separating R1's two
surviving role families by ear/scope (a `ROOM REVERB 1` impulse response would do
it — with the **corrected** delays `255/869/979/366/1044`, *not* the halved
`127/435/489/183/522` this document used to quote; the families differ in what is
written to the delay line, hence in the tail after the first pass), the exact DRAM
read latency inside its forced [2,5] window, R2's prediction that **DO3 is never
written** (a scope on pin 25 should show nothing), and `N` in `mod 2^N` — for which
the KN5000 firmware is simply mute, since it never sets bits 16/17. Everything else
on this list is static.

**Emulation status:** MAME instantiates the core (`upd6383` device) **disabled** —
the host interface is exercised, nothing executes, there is no audio. A
partially-correct effects DSP produces audio that *diverges*, and
plausible-but-wrong sound is worse than silence.
