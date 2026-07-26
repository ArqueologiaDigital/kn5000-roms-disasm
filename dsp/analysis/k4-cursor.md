# K4 — the coefficient-cursor REBASE, and the bank-register question

NEC **uPD6383GF-3BA** (Technics SX-KN5000, IC311). Roadmap item **K4**
(`kn7000_mame/notes/dsp-next-steps-roadmap.md`). Date: 2026-07-26.

The question: the implicit coefficient cursor starts at C-RAM `0x00` for the
unit-0 body and at `0x90` for the unit-1 (reverb) body, so **something rebases it
between the two units**. Find it, and settle whether the CDJ-500 block diagram's
bank register `BNK-R` is that something.

No hardware was used and none is needed for anything claimed below. Every claim is
labelled **PROVEN BY CONSTRUCTION** (the firmware builds the bytes and we read the
builder), **MEASURED** (counted over the ROM corpus or a previously-recorded
capture), **FORCED** (no other assignment survives the constraints), **CONSISTENT**,
**INFERRED**, **EDUCATED GUESS**, or **OPEN**. Where the constraints admit several
assignments they are **all enumerated**; none is silently picked.

**Overlap notice.** The concurrent **K3** pass (`analysis/k3-pointers.md`) reached
the C-RAM memory map and "`lo12 = 0x821` is a C-RAM pointer but is *not* the
cursor" independently and first; §1 and §3.2 here are cross-checks of K3's result,
not a claim of priority. K4's own contribution is everything from §2 onward: what
the rebase must satisfy, where it provably is not, and the forced conclusion that
the base value cannot be an instruction immediate.

---

## 0. Result in one page

| # | statement | label |
|---|---|---|
| **A** | **A rebase must exist.** The unit-1 base is the constant `0x90` in **12 of 12** reverb parameter streams, while the number of class-A words executed before the unit-1 body varies with the unit-0 program over **6 … 60 (24 distinct values)**. A cursor that is not reset cannot be constant. | **FORCED** |
| **B** | **The rebase is not in any effect body.** Over the 37 unit-0 images the intersection of the words preceding each image's first class-A word is **empty**, and one image's first word *is* its first class-A word (prefix length 0). No body word can precede every unit-0 body's first coefficient read. | **FORCED** |
| **C** | ★ **The rebase cannot carry its value as an instruction immediate.** Under the established frame order the only words between the unit-0 body's return and the unit-1 body's entry are I-RAM **50…59**, and an exhaustive search of **every contiguous 8-to-16-bit field of all ten words** finds the value `0x90` **nowhere** (the single hit, `w51` bits [14:7], straddles the `addr8`/`lo12` boundary that the firmware writer PROVES BY CONSTRUCTION, so it is not a field). Corpus-wide, `0x90` appears as an aligned field in **1 word of 3057** — I-RAM **69**, which runs *after* the unit-1 body. | **FORCED** |
| **D** | ★ **Therefore the chip holds a per-unit COEFFICIENT-BASE register and the rebase copies it into the cursor.** This is the affirmative answer to "is there a bank register": there must be one, and something outside the body/setup instruction stream loads it. | **FORCED** (given A–C) |
| **E** | ★ **It is not a power-of-two hardware bank.** C-RAM is one flat 256-cell space whose **resident constant table occupies `0x50..0x8B` and straddles `0x80`**; the unit-1 bank starts at `0x90`, the first 16-aligned cell after it. A 1-bit `BNK-R` on address bit 7 is impossible. The base register must hold an arbitrary 8-bit value. | **FORCED** |
| **F** | ★ **`cursor-general.md` §1.2 headline 8 is FALSIFIED as a C-RAM statement.** "The two resident effect units are given the two halves of the 256-word coefficient RAM, unit 0 low and unit 1 from `0x80`" cannot hold: `0x70..0x8B` is one resident table written by a single literal ROM blob. | **FALSIFICATION** |
| **G** | ★ **…but the `+0x80` displacement is REAL — in the class-1 REGISTER file, not in C-RAM.** Across the 91 well-formed parameter streams the `000.1.NN.000` register selects split perfectly: **368 packets / 23 distinct `NN`, all `< 0x80`, in unit-0 streams; 60 packets / 5 distinct `NN`, all `≥ 0x80`, in unit-1 streams**, and **5 of 5** unit-1 numbers are a unit-0 number `+ 0x80`. The boot blob writes the matched pair `000.1.06.000` / `000.1.86.000` back to back. **This resolves K6's class-1 `addr8` lead.** The earlier claim conflated two different 256-cell spaces. | **MEASURED** (428 packets, 100 %) + **PROVEN BY CONSTRUCTION** |
| **H** | The C-RAM base is a **software allocation**: it is a literal in each algorithm's parameter script, and the firmware's individually-addressed poke writer computes the destination as an **8-bit sum `P = arg2 + arg1`**. `GATED REVERB`, a reverb *algorithm* running as unit 0, uses base `0x00` — the base follows the **unit**, not the program. | **PROVEN BY CONSTRUCTION** |
| **I** | ★ **Only `class4 == 0xA` advances the cursor; `class4 == 8` sets bit 23 but must NOT advance it.** The PARAMETRIC EQ body has **10 class-8 words** (`804.8.16.415`, one per biquad section) interleaved with a cursor map that is PROVEN to the bit (60/60 named, transfer function reproduced at max|err| = 0, 6 cells per band). If class 8 advanced, band *k* would start at cell `7k` instead of `6k` and every role would shift. **Direct constraint on the ALU/core work.** | **FORCED** |
| **J** | The **leading candidate instruction** is `800.1.60.00B`: it occurs **exactly twice in the whole 3057-word machine**, once in each per-unit setup block, at the **same relative offset (+4)**, and nowhere else. It carries no per-unit payload — exactly what item D requires. **Enumerated, not asserted**; the unit-tagged transfer word itself is the co-equal alternative. | **CONSISTENT / OPEN** |
| **K** | **MISS reported.** `050.0.00.921` — unique (1/3057), sitting in `MULTI TAP DELAY`, the one program with an unexplained **−3 cursor rewind**, and in the same `lo12` low-byte-`0x21` selector group as `rstcur` — was predicted to be that rewind. **Checked and FALSIFIED**: a −3 rewind at its position moves both damping triples off the cells the host writes them to and breaks a PROVEN role assignment at six cells. It is also 17 words upstream of the group that actually overruns. | **PREDICTION MISSED** |

**What K4 does NOT settle**: *which* instruction performs the copy (J), and *who*
loads the per-unit base register — three resolutions are enumerated in §5 and none
is chosen.

Reproduce every number: `python3 dsp/tools/k4_cursor.py` (all sections) or
`… map forced fields regs class8 multitap`.

---

## 1. The C-RAM map — MEASURED, and it is the reason `0x90` is `0x90`

Cross-check of K3 §2.1, from two independent paths that agree cell for cell: the
literal uC-IF blob in the Sub CPU ROM, and the cold-boot capture.

### 1.1 The resident table is a literal ROM blob — PROVEN BY CONSTRUCTION

Sub CPU ROM **`0x01E6BE`**, decoded with K5's bytecode rule, is:

```
  op0 cmd=01 port 0x0160 : 000.1.06.000  0A 00 00 00 15   ; unit-0 effect level <- 0
                           000.1.86.000  0A 00 00 00 15   ; unit-1 effect level <- 0
  op4 cmd=03
  op1 cmd=01 port 0x0160 : 801.0.50.821                   ; C-RAM pointer <- 0x50
  op2 cmd=02 port 0x0161 : 30 x 24-bit                    ; -> C-RAM 0x50..0x6D
  op4 cmd=03
  op1 cmd=01 port 0x0160 : 801.0.6E.821                   ; C-RAM pointer <- 0x6E
  op2 cmd=02 port 0x0161 : 30 x 24-bit                    ; -> C-RAM 0x6E..0x8B
  op4 cmd=03
  op1 cmd=01 port 0x0160 : 801.0.8C.821                   ; park the pointer at 0x8C
  op2 cmd=02 port 0x0161 : 0 values
  op4 cmd=03
  F
```

It matches cold-boot capture transfers 4…10 byte for byte. The 60 values are two
exact arithmetic sequences:

```
   TABLE A   C-RAM[0x50 + k] = (32 + k) * 0x400     k = 0..31   (0x008000 .. 0x00FC00)
   TABLE B   C-RAM[0x70 + k] = min(1214 * k, 0x7FFF) k = 0..27  (0x000000 .. 0x007FFF)
```

`v[0x50+k] == (k+32)·1024` holds for all 32 cells; TABLE B's first difference is
the single value 1214 for all 27 steps. Both are 15/16-bit-ranged, not Q0.23-ranged
— K3 headline 1 reads them as the per-unit **delay-DRAM allocation** (TABLE B
`0…32767`, TABLE A `32768…64512`, TABLE B's last entry clamped to exactly
`0x7FFF`). That is a lead for the delay-address hole, not for K4; what K4 needs
from them is only **where they sit**.

**They are RESIDENT.** Scanning `801.0.NN.821` across **all 100** parameter streams
gives exactly four immediates — `0x00` (79×), `0x1E` (9×), `0x90` (12×), `0xAE`
(12×). **No parameter stream ever points at `0x50..0x8B`.** Written once at boot,
never rewritten. **MEASURED.**

### 1.2 The whole map

```
   0x00 .. 0x4F   unit-0 effect coefficient bank      (79/79 unit-0 streams: ldptr #$00;
                                                       largest observed use 0x00..0x2C)
   0x50 .. 0x6F   RESIDENT TABLE A  (32 cells)   \__  written once, by the literal blob
   0x70 .. 0x8B   RESIDENT TABLE B  (28 cells)   /    at Sub CPU ROM 0x01E6BE
   0x8C .. 0x8F   never written                       (4 cells of slack)
   0x90 .. 0xB5   unit-1 effect coefficient bank      (12/12 unit-1 streams:
                                                       ldptr #$90 +30, ldptr #$AE +7)
   0xB6 .. 0xFF   never written
```

**This is the positive explanation of `0x90`**: it is the first 16-aligned cell
after the resident table region ends at `0x8B`. It is not a hardware boundary, and
**C-RAM is not split in half at `0x80` — TABLE B straddles `0x80`.** That is item
**F**: `notes/kn5000-dsp-cursor-general.md` §1.2 headline 8's "the two resident
effect units are given the two halves of the 256-word coefficient RAM, unit 0 low
and unit 1 from `0x80`" is **wrong for C-RAM**. What that note actually saw — the
`0x06` → `0x86` displacement of the effect-level opcode — is real, but it lives in
the class-1 register file (§4), a different space. Two spaces were conflated.

### 1.3 The base is chosen in software — PROVEN BY CONSTRUCTION

Two independent constructions:

* the base is a **literal** in each algorithm's parameter script (`08 01 09 08 21`
  = `801.0.90.821` sits in the ROM bytes of all 12 reverb streams; `08 01 00 08 21`
  in all 79 unit-0 streams);
* the individually-addressed poke writer `LABEL_0387E6` builds its destination as
  an **8-bit sum**: it computes `(XSP+00Ch) + (XSP+006h)`, shifts the high nibble
  into byte 2 and the low nibble into byte 3. A hardware bank would not need a
  software add.

And the base follows the **unit**, not the algorithm: `GATED REVERB` (algo 8) is a
reverb that loads at I-RAM 84 and its bank is at `0x00`.

An independent corroboration falls out for free: `cursor-general` §5.2 had to
reclassify algo 39's `op 0x70` second group (`0x64 0x68 0x6C 0x70 0x74`) as *state*
addresses rather than coefficients on structural grounds. The map gives a positive
reason: those five C-RAM cells are **inside the resident table region**, which no
parameter stream ever writes, so they cannot be coefficient-space addresses.

---

## 2. A rebase must exist — FORCED

The unit-1 bank base is `0x90` in **12 of 12** reverb parameter streams, and the
reverb body's first class-A word is PROVEN to read `C-RAM[0x90]` (the
named-coefficient join, `input scaling`, and the nine diffuser gains landing on
`0x98..0x9C | 0xA1..0xA4`).

Suppose the cursor were a free-running per-frame counter. The unit-1 body runs
after the unit-0 body in every frame, so the cursor at unit-1 entry would be
`(header count) + (unit-0 body's class-A count) + (unit-1 setup count)`. The 37
unit-0 images have class-A counts

```
   6 6 6 8 8 10 12 13 14 15 15 16 18 18 18 18 19 20 21 22 22 22 22 22 23 25 26
   26 28 28 30 31 32 33 36 40 60          -> min 6, max 60, 24 distinct values
```

so the unit-1 entry cursor would take **24 different values** depending on which
effect is loaded in unit 0, and the firmware would have to move the reverb bank
with it. It does not — `0x90`, always. **FORCED: the cursor is reset at the unit
boundary.**

The same argument, run for unit 0, is weaker but points the same way: the header
performs 20 class-A fetches before I-RAM 42, so a counter free-running from a
frame-start zero would put the unit-0 body's first read at `0x14`, not `0x00`.

---

## 3. Where the rebase is NOT

### 3.1 Not in any body — FORCED

For each of the 37 unit-0 images, take the set of words preceding its first class-A
word. The lengths of those prefixes are

```
   0 1 1 1 1 2 2 2 2 2 2 3 3 3 4 4 4 4 4 4 5 5 5 5 5 5 5 6 6 6 6 8 8 8 10 11 12
```

and their **intersection is empty**. One image reaches a coefficient on its very
first word, so no in-body word can precede every unit-0 body's first read. (The
weaker control also holds: **no word at all** occurs in all 38 distinct images.)
**FORCED: the rebase is in the resident kernel, or is a side effect of the
unit-tagged transfer.**

### 3.2 Not `801.0.NN.821` — FORCED, and with a positive explanation

The three in-program immediates of this form are `0x70` (I-RAM 42, unit-0 setup),
`0x50` (I-RAM 50, unit-1 setup) and `0x90` (I-RAM 69, output stage). The required
bases are `0x00` and `0x90`. Under the established frame order (header 0…48, CALL
at 49, unit-0 body, 50…58, CALL at 59, unit-1 body, output stage 60…82) the live
value at unit-0 entry is `0x70` and at unit-1 entry `0x50` — **neither matches**.
Under the rival order (transfers at I-RAM 64/71) it is `0x50` and `0x90` — unit 0
still fails. **The falsification is order-independent.**

The map of §1.2 says what those immediates *are*: `0x50` is TABLE A's base, `0x70`
is TABLE B's base, `0x90` is the unit-1 bank base. All three land on a boundary of
a memory map derived from a completely different instrument (the host's uploads).
The mechanically-derived boundary set is small — `{0x00, 0x50, 0x6E, 0x70, 0x8C,
0x90, 0xAE}`, 7 cells of 256 — so 3/3 hits carry P ≈ (7/256)³ ≈ 2·10⁻⁵ under a
uniform null. `801.0.NN.821` is a **C-RAM address pointer that the kernel aims at
the resident tables**; K3 item F reaches the same conclusion by a sharper route
(the CHORUS LFO-wrap constant).

This repairs, rather than confirms, K5's and K6's "the same word inside I-RAM is a
different animal": it *is* the same register and the same space — it is simply not
the cursor.

### 3.3 ★ The value `0x90` is not an immediate anywhere it could be — FORCED

Under the established order the only words that can rebase unit 1 are I-RAM
**50…59** (the unit-1 setup block and its transfer), or the reverb body's own first
two words — and those are `880.1.30.00B` and `000.2.89.415`, neither of which
carries `0x90`.

Exhaustive search over I-RAM 50…59, **every contiguous bit field of width 8…16 at
every one of the 36 bit positions**:

```
   w50  801.0.50.821   none
   w51  801.0.64.827   [14:7] [15:7] [16:7]      <- straddles the addr8/lo12 boundary
   w52  801.0.25.825   none
   w53  010.9.D0.20C   none
   w54  800.1.60.00B   none
   w55  000.2.01.007   none
   w56  C64.6.A2.007   none
   w57  000.2.01.000   none
   w58  000.1.8A.007   none
   w59  400.1.0F.007   none
```

The lone hit is not a field: the `class4 | addr8` and `addr8 | lo12` boundaries are
**PROVEN BY CONSTRUCTION** (`LABEL_0387E6` writes `(P>>4)&0x0F` into byte 2's low
nibble and `(P&0x0F)<<4` into byte 3's high nibble), and bits [14:7] cross the
lower one.

Corpus-wide the same conclusion, stated as a count. Over all 3057 words (60 header
+ 23 output stage + 2974 body):

```
   addr8      == 0x90 :  1 word   -- I-RAM 69, 801.0.90.821
   bits[24:17]== 0x90 :  0 words  (the setvec / C-format payload position)
   bits[11:4] == 0x90 :  0 words
   C-format payload A == 0x90 : 0 words
```

**FORCED: the unit-1 rebase does not carry `0x90` as an immediate.** Since it must
still produce `0x90`, it must **copy the value from a register**. That is item D:
the chip holds a per-unit coefficient-base register, and §1.2 forces it to be an
arbitrary 8-bit register rather than a 1-bit bank select on address bit 7.

---

## 4. The bank register, and K6's class-1 lead — resolved

K6 flagged that class-1 `addr8` splits on bit 7: delay-DRAM sub-ops `0x20/0x30/0x60`
versus the output stage's `0x85/0x8A/0x8C/0x8D/0x8F`, "the latter matching the
numbering of the host's own `000.1.NN.000` state-clear packets". Both halves of
that observation are now measured.

**The discriminator is `hi12`, not `addr8` bit 7.** In the 2974-word body corpus,
class-1 words with `hi12` bit 7 **set** (`0x880/0x900/0x800` escapes) use `addr8 ∈
{0x20, 0x30, 0x60}` — the delay-DRAM sub-ops. Class-1 words with `hi12` bit 7
**clear** are the unit-tagged terminators (`addr8 = 0x0E` in 37 unit-0 images,
`0x0F` in the unit-1 image) plus C-format words, whose `class4|addr8` is immediate
data and not a register address at all.

**The register space itself is split by bit 7, and the split is the effect unit.**
Over the 91 well-formed parameter streams (the 5 malformed ones excluded):

```
   unit-0 streams (I-RAM 84) : 368 packets, 23 distinct NN, ALL < 0x80
                               05 06 07 08 09 0A 0B 0C 0E 10 11 12 13 14 16 1B
                               50 52 54 5A 5B 60 6D
   unit-1 streams (I-RAM 200):  60 packets,  5 distinct NN, ALL >= 0x80
                               85 87 8A 94 D0
   every unit-1 number is a unit-0 number + 0x80 :  5 / 5
        85=05+80   87=07+80   8A=0A+80   94=14+80   D0=50+80
```

428 packets, **100 % clean**. And the boot blob (§1.1) writes the pair
`000.1.06.000` / `000.1.86.000` back to back with the same value — **PROVEN BY
CONSTRUCTION** that `0x06` and `0x86` are the same register in the two unit halves.
The kernel's own I-RAM 58, `000.1.8A.007`, sits in the **unit-1** setup block and
names register `0x8A`, whose unit-0 twin `0x0A` the unit-0 parameter streams write
— consistent.

**So there IS a per-unit banking, and it is real and MEASURED — but it is a
displacement of the class-1 register file, not of C-RAM.** Applying it to C-RAM,
as `cursor-general` §1.2 did, is what produced the wrong `0x80` coefficient split.

**Loose end, honestly flagged:** the shared output stage names registers `0x85`,
`0x8C`, `0x8D`, `0x8F` (unit-1 half) and only `0x06` from the unit-0 half. A
unit-symmetric output stage would be expected to name both halves. `0x8C`, `0x8D`
and `0x8F` occur in no host stream at all. **OPEN.**

---

## 5. The surviving candidates — ENUMERATED

### 5.1 Which instruction performs the copy

| candidate | for | against |
|---|---|---|
| **`800.1.60.00B`** (I-RAM 46 and 54) | Occurs **exactly twice in the 3057-word machine**, once in each per-unit setup block, at the **same relative offset (+4)** in each, and nowhere else. Identical in both blocks — which is exactly what §3.3 demands of an instruction that copies a register rather than an immediate. Its position is *after* each block's cursor-fetch word (I-RAM 45 / 53) and *before* the transfer, so the fetch at 45/53 consumes the outgoing bank and the body starts clean at the new base. | `class4 = 1` with `addr8 = 0x60` is also the delay-DRAM read sub-op; `hi12 = 0x800` differs from the DRAM family's `0x880` only in bit 7, so this may simply be a DRAM housekeeping word. Nothing rules that out. |
| **the unit-tagged transfer** (`400.1.0E.000` / `400.1.0F.007`) | One mechanism serves both units and both directions; `addr8` already carries the unit index (91/91); the CDJ-500 diagram gives it a 2-level stack, so it is already a state-swapping word. | No evidence beyond position; would make the cursor base part of the call/return state, which nothing else suggests. |
| **I-RAM 45 / 53** (`010.A.00.20C` / `010.9.D0.20C`) | Unit-0's `addr8` is literally `0x00`, the unit-0 base. K6 has already FORCED these to be the data-pointer stores for the unit entry pointers, so they are the block's "hand over to the body" words. | Unit-1's `addr8` is `0xD0`, **not** `0x90`; under the class-1 register reading `0xD0` is unit-1's copy of register `0x50`, which fits K6's data-pointer role and not a coefficient base. |

### 5.2 Who loads the per-unit base register

| # | resolution | cost / test |
|---|---|---|
| **E1** | **The host sets it out of band.** The only per-unit `0x00`/`0x90` the host ever transmits is the `801.0.PP.821` at the head of each unit's coefficient upload (79/79 `#$00`, 12/12 `#$90`) — so either that word has a second effect on a per-unit copy, or a command in the **six un-disassembled uC-IF `op 0..5` handlers** (`0x03C32E + OFFSETS_14739[op]`) writes it. | **Testable statically** — disassembling those six handlers is roadmap item 4 and would decide this outright. This is the cheapest next move in the whole of K4. |
| **E2** | **I-RAM 69 loads it.** `801.0.90.821` is the only aligned `0x90` in the machine and sits between the two per-unit words of the output stage; under a *next-frame* reading it would arm unit 1's base for the following frame. | Requires `lo12 = 0x821` to name different physical registers in different contexts (I-RAM 42 and 50 write the same selector with `0x70`/`0x50`), and still needs a second, separate mechanism for unit 0's `0x00`. Two mechanisms where one should do. |
| **E3** | **Hard-wired per unit** (`0x00` / `0x90` in the silicon), with the firmware's allocation chosen to fit around it. | `0x90` is not a natural hardware constant, and §1.3 shows the firmware computes the address with a software add. Not excluded. Would be settled by any second uPD6383 microcode (e.g. the Pioneer CDJ-500's) putting its unit-1 coefficients at `0x90` too. |

**None is chosen.** E1 is the one with a purely static test.

---

## 6. Constraints this places on the concurrent ALU / core work

1. ★ **Only `class4 == 0xA` may advance the cursor. `class4 == 8` sets word bit 23
   but must not advance it.** The PARAMETRIC EQ body carries 10 class-8 words
   (`804.8.16.415`, one per biquad section) inside a cursor map that is PROVEN to
   the bit — 6 cells per band, 60/60 named, transfer function reproduced at
   max|err| = 0. If class 8 advanced, band *k* would begin at cell `7k` and every
   role would shift. Corpus-wide, bit-23 words are class 8 (42) or class A (822)
   and nothing else in the bodies. **FORCED.** Consequence for the renderer: the
   present `cur+` annotation on class-8 words is misleading — bit 23 is a *fetch*
   enable, the *advance* is `class4 == 0xA`. (Not renamed here, to keep
   `tools/dsp_disasm.py` in step with MAME's `upd6383d.cpp`; flagged for whoever
   changes both.)
2. **Do not model `801.0.NN.821` as writing the coefficient cursor** (§3.2,
   FORCED; K3 item F has the sharper argument). It is a C-RAM *address pointer*,
   shared with the host.
3. **The cursor's per-unit base is an external input to a body**, not derivable
   from the body's words: `0x00` for a body at I-RAM 84, `0x90` for one at I-RAM
   200. A core must take it from outside.
4. **Practical, for any C-RAM model:** cells `0x50..0x8B` hold 60 resident
   constants that no algorithm ever rewrites. A core that starts with C-RAM zeroed
   and only replays parameter streams will read **zeros** for every table lookup.
   Preload them from the Sub CPU ROM blob at `0x01E6BE` (or replay the boot
   script).

---

## 7. Predict-then-check log

| prediction | outcome |
|---|---|
| The rebase is a `801.0.NN.821` in the per-unit setup blocks, with `NN` = the bank base. | **MISS.** The immediates are `0x70`/`0x50`; they are the two resident-table bases (§3.2). |
| `050.0.00.921` — unique in the corpus, in `MULTI TAP DELAY`, the one program with an unexplained −3 rewind, and in the same `lo12` low-byte-`0x21` group as `rstcur` — is the partial rewind. | **MISS, reported.** It sits at body word 33; a −3 rewind there would send the two damping triples to cells `0x05..0x07` and `0x08..0x0A` instead of `0x08..0x0A` and `0x0B..0x0D`, contradicting the host's own `op 0x76 → 0x08` / `→ 0x0B` writes and a PROVEN role at six cells. The group that actually overruns is 17 words later, between body words 49 and 52. What it *does* is **OPEN**. |
| Class-1 `addr8` bit 7 is the effect-unit selector (K6's lead). | **HIT**, at 428/428 packets in the host register space (§4) — but the delay-DRAM/register discrimination is carried by `hi12`, not by `addr8` bit 7. |
| Unit-1's C-RAM base is `0x80` (`cursor-general` §1.2's `+0x80`). | **MISS — that claim falsified.** The resident table straddles `0x80`; the base is `0x90` and it is a software allocation (§1.2, §1.3). |
| The rebase value is somewhere in I-RAM 50…59. | **MISS, and the miss is the result:** it is nowhere, which forces the base register (§3.3). |

**Cross-check for K3.** K3 item **K** states that the only two body words in the
`0x_2x` selector block are `algo39 w58 = 801.0.00.021` and
`algo00 w18 = 80B.0.00.839`. Filtering the 2974-word body corpus on
`(lo12 & 0xFF) ∈ [0x20, 0x27]` gives **two** words — `algo39 w58` (`801.0.00.021`)
and **`algo10 w33` (`050.0.00.921`, I-RAM 117)**. Whichever predicate K3 used,
`050.0.00.921` belongs in that group and is worth a line there.

---

## 8. What would settle it, and what needs hardware

**Static, and cheap:** disassemble the six uC-IF `op 0..5` handlers at
`0x03C32E + OFFSETS_14739[op]` (roadmap item 4). If any of them writes a per-unit
register with the value the following `801.0.PP.821` carries, **E1** is decided and
K4 closes.

**Static, and harder:** decide `800.1.60.00B` against the transfer word (§5.1).
Both occur exactly where a rebase must occur; separating them needs either a second
microcode corpus for the same chip, or the datasheet.

**Needs hardware, and nothing else will do:** nothing in K4. Every open question
here is decidable from the ROM.
