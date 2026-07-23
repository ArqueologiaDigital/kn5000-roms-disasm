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

- **`class4`** is NOT universal: inside the `hi12[11:8]==0xC` family and the host
  poke region it is **immediate DATA** spanning bits [23:12], not a class
  (MEASURED, `notes/kn5000-dsp-header.md` §6). The disassembler annotates those
  families rather than pretending the nibble is a class.
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
| 4 | **WRITE ACCUMULATOR → mem[ptr]** | MEASURED (`0x212 = 0x202 + bit4`, `0x092 = 0x082 + bit4`; absence control 0/410 clean, one flagged exception) |
| 3:1 | a proven FIELD, meaning **UNKNOWN** (`f31`) | MEASURED as a field (8/8 values) |
| 0 | "`addr8` is an absolute immediate" | PROVEN BY CONSTRUCTION for `0x801` only; else residue |

**bit 23** (== `class4` bit 3) is the **CURSOR-FETCH enable**, corrected from an
earlier "multiply enable" reading (`notes/kn5000-dsp-axes.md`).

## Decoded forms — the only six with a real mnemonic

Each carries its evidence in `tools/dsp_disasm.py` next to the code that emits it.

| form | mnemonic | operation | status |
|---|---|---|---|
| `000.2.00.000` | `nop` | — | **PROVEN BY CONSTRUCTION** (writer `LABEL_038922`) |
| `801.0.NN.821` | `ldptr #$NN` | load pointer register | **PROVEN BY CONSTRUCTION** (writer `LABEL_0387E6`) |
| `801.0.00.021` | `rstcur` | reset coefficient cursor to base | **VERIFIED** (algo39 section starts 0,6,12,18,24 \| rstcur \| 0,6,12,18,24) |
| `202.A.dd.1D5` | `mac (p)+dd` | `acc += P ; P = coef[cursor++] * mem[p] ; p += (s8)dd` | **DETERMINED** (all 144 survivors of a 19,674,720-point constraint search agree) |
| `202.A.dd.1D4` | `mac.lb (p)+dd` | as `mac`, and latch B ← mem[p] | **DETERMINED**, same source |
| `212.A.dd.407` | `mulst (p)+dd` | `mem[p] <- acc ; P = coef[cursor++] * acc ; p += (s8)dd` | **DETERMINED UNIQUELY** |

The recovered interpreter reproduces the transfer function of nine real ROM
coefficient banks at max|err| = 0 (`notes/kn5000-dsp-semantics.md` §4) — the
biquad and reverb families are solved on top of these three multiply forms.

## Structural landmarks — annotated, NOT decoded

These are MEASURED *landmarks* whose semantics are unknown. They keep the `?word`
prefix (a landmark is not a decode; the `?` is the greppable worklist):

- **terminator / END OF BLOCK** — `class4==1 && addr8 ∈ {0E,0F}` carries a
  transfer of control (CALL/RETURN, unit-tagged); the untagged form falls
  through. `addr8` is the **unit index** (91/91), not the halt.
- **external-DRAM bracket** — `880.1.60.*` OPEN / `880.1.20.*` CLOSE (INFERRED,
  MCC +0.944 over the DRAM-using effects); `880.1.30.*` framing.
- **all-pass marker** `104.2.00.000` (MCC +0.881); the reverb diffuser
  write/partner pair `012.2.00.680` / `000.2.00.419`.
- **LFO** — `hi12=0x082` read; `092.A.00.200` phase accumulate; `094.A.00.200`
  wrap on `0x7FFFFF`.
- **envelope detector** — `hi12=0xC40`.
- **table-lookup idiom** — `040.0.00.C63 | 000.6.TT.4CD | 012.4.01.1CE` (class-6
  `addr8` = table selector); accounts for every class-4/6 word, MCC +1.000.
- **class 8** — post-sum step (rescale/round/saturate?), **operation unknown**;
  its *position* is determined, not its operation.
- **P-consumers / carry latches** — `lo12 ∈ {647,687,1D3,1D4}`.
- **`hi12=0x212`** writes `mem[ptr]` in every class (bit 4); `hi12=0x102` is the
  shared gain multiply of the phaser all-pass and reverb diffuser.
- pointer-load siblings `lo12 ∈ {820,822,825,827}` (INFERRED; which register each
  loads is unknown).

## Addressing — MEASURED

There is **no encoded space-selector field**; the memory space is
**pointer-identity** (`notes/kn5000-dsp-spaces.md`):

- **C-RAM** (coefficients) — reached ONLY through the implicit coefficient
  cursor: base **0x00** (MEASURED across all 16 swept effects), **+1 per class-A
  word**, reset by `rstcur`. Every class-A word therefore reads a coefficient at
  a **known absolute C-RAM address** — the disassembler prints `; C-RAM[0xNN]`.
  The unit-1 reverb bank base is **0x90**.
- **D-RAM** (state) — reached ONLY through the signed-`addr8` data pointer
  (`mem[ptr]`). Its absolute base (the header's per-unit `0x70`/`0x50`) is still
  unpinned, so **no D-RAM absolute is printed**.
- **external delay RAM** — reached ONLY through the `880` bracket.

## Control flow — INFERRED/PROVEN mix

- **Per-frame hardware PC restart.** The PC sweeps I-RAM once per sample frame
  (Fs-RST / PC-RST pins); 25 MHz / 44.1 kHz = 567 cycles per frame against 384
  I-RAM words — room to spare, as some words take >1 cycle.
- **The 60-word common header** (`kernel.dsm`) loads pointer registers, then
  CALLs the unit-0 body (I-RAM 84) and the unit-1 body (I-RAM 200) via a shared
  call/return encoding (the unit-tagged END-OF-BLOCK word), with a **2-level
  stack**. PROVEN BY CONSTRUCTION from the header loading registers 821/827/825
  twice (I-RAM 42–44 and 50–52), so a body must run and return between them
  (`notes/kn5000-dsp-headerdecode.md`).
- **Effect bodies are straight-line, HAND-UNROLLED.** No branch word carrying the
  body entry addresses 84/200 exists; an exhaustive field scan for a branch is
  negative, and there is a positive reason — algo16 repeats 32 words at period 8
  varying only `addr8`, algo39 repeats 9 words at period 9. There is no loop to
  branch back to (`notes/kn5000-dsp-necfamily.md` §6).

## Coverage — honest

Forcing the paper analysis through an executable disassembler:

```
words over the 38 distinct images            2974
decoded (six forms)                           267   (9.0 %  by vocabulary)
undecoded                                    2707   (91.0 %)
distinct undecoded words                       655
distinct undecoded (hi12,class4,lo12) FAMILIES 185
operand-ROLE known (named coefficients etc.)         ~18.3 %

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
decodes like the biquad's. Source coverage — the fraction of the *instruction set*
understood — is still **~18.3 %**. The two figures measure different things and this
tree does not launder one into the other.

**~82 % of the instruction set is still unknown.** The distribution has a long
tail: the top 40 words are 46 % of undecoded occurrences and the top 29 families
55 % — there is no small set of words that unblocks everything. The highest-value
open targets, in order (`notes/kn5000-dsp-core-draft.md` §6):

1. `212.2` vs `212.A` — bit 23 on a family whose class-A form is determined.
2. the `lo12 = 0x415` group across classes A/2/8 (tests "lo12 = route, class4 =
   arithmetic", brings class 8 along).
3. the table-lookup triple (`040.0.00.C63 / 000.6.TT.4CD / 012.4.01.1CE`).
4. `880.1.20.*` — address latch or data latch?
5. the 83 header+stub words — where `COND`, `BRAKST` and the GF flags must live.
6. the actual µPD6383 datasheet/databook — would hand over the whole ISA.

**Emulation status:** MAME instantiates the core (`upd6383` device) **disabled** —
the host interface is exercised, nothing executes, there is no audio. A
partially-correct effects DSP produces audio that *diverges*, and
plausible-but-wrong sound is worse than silence.
