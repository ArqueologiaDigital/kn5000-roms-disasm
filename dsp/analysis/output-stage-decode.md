# The OUTPUT STAGE, I-RAM 60..82 — and the D-RAM ORIGIN it hands over

NEC **uPD6383GF-3BA** (Technics SX-KN5000, IC311). Date: **2026-07-26**.
No hardware. Static analysis, the ROM corpus and constraint solving only.

Tool: [`../tools/output_stage.py`](../tools/output_stage.py) — stdlib only apart
from the ROM parser it borrows, re-runnable, and it prints **every number quoted
below**:

```
python3 dsp/tools/output_stage.py words     # the 23 words, every field
python3 dsp/tools/output_stage.py cformat   # the C-FORMAT OPCODE census
python3 dsp/tools/output_stage.py dram      # ★ SOLVE the D-RAM origin
python3 dsp/tools/output_stage.py control   # ★ RUN THIS FIRST -- the same solve
                                            #   with the answer destroyed
python3 dsp/tools/output_stage.py closure   # ★ frame closure -- residue ZERO
python3 dsp/tools/output_stage.py regs      # the 256-cell map that falls out
python3 dsp/tools/output_stage.py do        # the w73 / w78 evidence
python3 dsp/tools/output_stage.py checks    # the predict-then-check numbers
```

Labels: **MEASURED** / **PROVEN BY CONSTRUCTION** / **FORCED** (the only assignment
a stated rule admits) / **CONSISTENT** / **INFERRED** / **EDUCATED GUESS** /
**FALSIFIED** / **OPEN**. Where the constraints admit several readings they are
**enumerated, not chosen**.

**Nothing here is applied to the MAME device and neither disassembler was
touched.** No word gains an executable semantic, every currently-trapping word
still traps, and the rendered audio cannot have moved. §12.

---

## 0. Result in one page

| # | statement | label |
|---|---|---|
| **A** | ★ **THE D-RAM ORIGIN IS PINNED, and it was in the host's own zero-fill all along.** *(Controlled: §3.6. The shuffled control kills the aggregate scan's peak-location claim and leaves its excess; the two derivations that carry the result are unaffected by it.)* The per-unit body **entry pointer** is `0x05` (unit 0) and `0x85` (unit 1). Three independent derivations: PARAMETRIC EQ's 40-cell contiguous run must align with the host's 40-cell fill block (**no free parameter**, E is unique); the exhaustive scan over all 256 origins scores **626/729** there against a shuffled-pairing null of **384 ± 16** (unit 1 **96/108**) — an *excess*, not a peak location, because the control shows the peak location is a baseline (§3.6); and the **lowest cell the host ever zero-fills** is `0x05` in **79 of 79** unit-0 streams and `0x85` in **12 of 12** unit-1 streams. | **MEASURED** (given **B**) |
| **B** | ★ **The mode-1 REGISTER FILE and the mode-2 D-RAM are ONE 256-cell RAM.** `isa-adjudication.md` §6 offered this as the simpler of two enumerated readings and had no positive test. This is the test: under it the host's fill lands on the body's own footprint three ways at once, the **per-unit state block sits at ENTRY+75 in 85 of 85 streams** (`0x05+75 = 0x50`, `0x85+75 = 0xD0`, both exact), and `E1 − E0 = 0x80` reproduces R2's "bit 7 of a register index is the effect unit" to the bit. Under the alternative (two spaces laid out alike) all of that is coincidence. | **FORCED** by A's over-determination, up to the alternative being enumerated |
| **C** | ★ **THE FRAME CLOSES. Residue ZERO, and `X = 0xFF` by two independent routes.** Route 1: `X + Δ(0..44) = E0`, i.e. `X + 6 = 0x05`. Route 2: `E1 + net(reverb) + Δ(60..82) = 0x85 + 123 − 1 = 0xFF`. The **+121** residue that has stood since the ADVANCE pass is the artefact of walking one pointer straight through a machine that **rebases it per unit**. | **FORCED** given A |
| **D** | ★ **A rebase between the two CALLs is FORCED, and its value is NOT an instruction immediate.** `net(body0)` varies over **8 values** across the unit-0 pool, so `E1 = 0x85` cannot be reached by walking. And `0x85` (or `0x83`/`0x84`, the pre-`w55`/`w57` variants) appears in **0** nibble-aligned 8-bit fields of I-RAM 50..58; over *every* contiguous 8-bit field there are 4 hits against **≈3.1 expected** — at chance. This **CONFIRMS** K4 item D and `closure-pointer.md` D′ — a per-unit **BASE REGISTER** — and supplies the value they could not: `base = 0x05 | (unit << 7)`. | **FORCED** |
| **E** | ★ **The answer to the brief's question (b) is NO — and it is measured, not argued.** The D-RAM base is **not** re-primed anywhere in I-RAM 60..82: the rebase must *precede* the unit-1 body, and `E0` needs no rebase at all because the header walk from `X = 0xFF` already lands on it. `closure-pointer.md` §6.1's favoured resolution ("the D-RAM operand pointer is re-established [in 60..78] by the same mechanism") is **FALSIFIED in its D-RAM half**; its admissible-site analysis assumed **one** reload per frame and the machine has **two regimes**. | **FALSIFICATION** |
| **F** | ★ …**but the two words that carry the two base VALUES are `w63` and `w70`**, and they are the only words in the 3057-word corpus that do. `w63` has `addr8 = 0x05`, `w70` has `addr8 = 0x85`; they are K5's measured symmetric pair; and each sits **immediately before its unit's call-vector word**. So the per-unit group in the output stage is `[base value] [entry vector]`. Two readings are enumerated (§7.2) and neither is chosen. | **MEASURED** + **enumerated** |
| **G** | ★ **R2's three unexplained registers are identified.** `0x8C`, `0x8D`, `0x8F` — "the three the host never touches", R2 §7 item 3, **OPEN** — are unit-1 body cells at **ENTRY+7 / +8 / +10**, and `0x8C` and `0x8F` are two of the **three cells the reverb reads and never writes**. `P` ≈ 1.6e-4 that three named indices land in a 14-of-256 footprint by chance. The output stage is the only other place in the machine that names them. | **MEASURED** |
| **H** | **`w73`'s SRC is `0x10` = the ACCUMULATOR — an ANCHORED code.** So the unit-0 result *is* in the accumulator at the moment of presentation. R2's item 9 forbids it *surviving 156 words*, which is a different statement; what it really forces is that something in **I-RAM 60..72** puts it there, and the only word in that range naming a unit-0 cell is `w63`. R2 item 9 is **narrowed, not kept as stated**. | **MEASURED** + **FORCED** |
| **I** | **`w73` and `w78` are not one instruction seen twice.** `w73` = (SRC `0x10` acc, ACT `0x04`); `w78` = (SRC `0x0A`, ACT `0x07`). The two fields are disjoint, `SRC 0x0A` occurs **1 time in 3057 words** and `ACT 0x04` **2 times**. Any model that treats "the two output presentations" as one form is wrong. Independently, **`addr8` bit 7 assigns them** — `0x00` → unit 0, `0x9F` → unit 1 — which R2 explicitly could not do. | **MEASURED** |
| **J** | **ACTION `0x07` on a mode-1 word does NOT write `reg[addr8]`.** `w72` is `000.1.06.087`: mode 1, `addr8 = 0x06`, ACTION `0x07`. Register `0x06` is the unit-0 **OUTPUT LEVEL** (PROVEN BY CONSTRUCTION, host-written once after linking) and it must persist. If ACTION `0x07` wrote the addressed register, the user's effect depth would survive exactly one frame. This gives `alu_decoded()` guard 6 — which refuses ACTION `0x07` outside mode 2 — a **positive** reason where it had only a precautionary one. | **FORCED** (one caveat, §6.3) |
| **K** | **The C-FORMAT word has an OPCODE, and the tree has never rendered it.** `bits[35:25]`; **eight** distinct values over the 68 C-format words. `is_c40()` — the payload rule `(hi12 & 0xFFE) == 0xC40` — **is exactly `opcode == 0x620`**, which is *why* "imm13 is a multiple of 32" is family-local: it is opcode-local. And the "five `lo12 = 0x820` words" are **not a family**: they carry **four different opcodes** and share only a destination. | **MEASURED** |
| **L** | **The bit-7 store gate makes one of R2's arguments MOOT.** R2's cleanest evidence for the mode-dependent bit-4 target was "`w60`/`w61` are adjacent mode-1 stores with nothing between them, so under `mem[ptr]` the first is provably dead". Under the **adopted** gate (`acc-adder.md` §6) `w60` is `(bit7, f31) = (1, 1)` and **does not store at all**. Same for `w68`. R2's conclusion survives on K5's call-vector result; *that* argument does not. | **MEASURED** |
| **M** | Housekeeping: `dsp/verify.py` **BYTE-MATCH OK**, `tools/upd6383d_diff.sh` **MIRRORS AGREE — 3057/3057**, `-validate kn5000` clean. No `.dsm` regenerated, no device file edited. | **MEASURED** |

---

## 1. Method, and why it worked from outside the output stage

The brief asked for a word-by-word decode of I-RAM 60..82 and named two OPEN
questions. The **second** one — *does a per-unit base register get re-primed
here?* — turned out to be unanswerable in the terms it was posed, because
nobody knew **what number the base would have to be**. `closure-pointer.md` said
so itself: its §6 lists nine unassigned epilogue words and closes with *"Nothing
selects among them, so nothing is selected."*

What selects among them is an **absolute** D-RAM address, and the machine does
not contain one — but the **host** does. The firmware zero-fills, per algorithm,
exactly the state cells the freshly-loaded body will use, and it addresses them
by the **mode-1 index**, while the body reaches them through the **mode-2
pointer**. If those are one RAM, the alignment between the two is an equation
with one unknown, and the unknown is the body's entry pointer.

That equation had been *looked at* before (`isa-adjudication.md` §5.1: "the walk
footprint must be at least the zero-filled block", 47/85). It had never been
**solved**. Solving it is §3, and everything else in this note follows from it.

---

## 2. The 23 words, with the fields the tree was not splitting

`output_stage.py words`. Two changes from `epilogue.dsm`: the C-format words are
split as **opcode + immediate** (their `hi12` is not a microword — §5), and the
bit-7 store gate is applied.

```
 w60  092.1.8D.15B   mode1        ST(GATED OFF)  f31=1 b7=1  SRC=05 ACT=1B   reg 0x8D
 w61  012.1.8D.05B   mode1        ST            f31=1 b7=0  SRC=01 ACT=1B   reg 0x8D
 w62  801.0.26.825   mode0 ESC                              ldptr.d #$26    descriptor ptr
 w63  2A7.9.05.1C3   mode1 fetch                f31=3 b7=1  SRC=07 ACT=03   reg 0x05  <- UNIT-0 BASE
 w64  011.9.0E.445   mode1 fetch  ST                         SRC=11 ACT=05   setvec unit0
 w65  200.1.8F.1C1   mode1                      f98=2       SRC=07 ACT=01   reg 0x8F
 w66  000.1.8C.107   mode1                                  SRC=04 ACT=07   reg 0x8C
 w67  980.5.20.402   mode5 ESC                  f98=1 b7=1  SRC=10 ACT=02   the hinge
 w68  092.1.8C.19B   mode1        ST(GATED OFF) f31=1 b7=1  SRC=06 ACT=1B   reg 0x8C
 w69  801.0.90.821   mode0 ESC                              ldptr   #$90    C-RAM ptr
 w70  2A6.1.85.0C7   mode1                      f98=2 f31=3 SRC=03 ACT=07   reg 0x85  <- UNIT-1 BASE
 w71  011.9.0F.446   mode1 fetch  ST                         SRC=11 ACT=06   setvec unit1
 w72  000.1.06.087   mode1                                  SRC=02 ACT=07   reg 0x06 = UNIT-0 LEVEL
 w73  E30.C.00.404   mode4 fetch ESC ST         f98=2       SRC=10 ACT=04   PRESENT unit 0
 w74  C16.9.AB.000   C-FORMAT  opcode 60B  A=77  B=11
 w75  82E.8.0F.000   mode0 fetch ESC            f31=7       SRC=00 ACT=00
 w76  C00.9.84.000   C-FORMAT  opcode 600  A=76  B=4        WAIT
 w77  859.0.86.822   mode0 ESC   ST             f31=4       ptr2 <- 0x86 = UNIT-1 LEVEL
 w78  A3C.D.9F.287   mode5 fetch ESC ST         f98=2 f31=6 SRC=0A ACT=07   PRESENT unit 1
 w79  012.2.FF.1CE   mode2        ST            f31=1       SRC=07 ACT=0E   D-RAM store at X+1
 w80  104.2.00.1CE   mode2                      f98=1 f31=2 SRC=07 ACT=0E   D-RAM read  at X+0
 w81  102.2.00.000   mode2                      f98=1 f31=1 SRC=00 ACT=00   D-RAM       at X+0
 w82  C00.A.47.407   C-FORMAT  opcode 600  A=82  B=7        FRAME WAIT
```

Two structural facts that were not in `k5-output-stage.md` §3:

* `w63` and `w70` have their **SRC and ACTION swapped**: `SRC 07 / ACT 03` against
  `SRC 03 / ACT 07`. Under the ALU decode `SRC 0x07` is *the addressed operand*
  (ANCHORED) and `ACT 0x07` is *write the operand to a destination* (ANCHORED).
  So the pair is a **read/write pair on the two per-unit base cells**.
* `w60`/`w68` carry the store bit **and** `(bit7, f31) = (1, 1)`. All three
  surviving store gates agree that this case does **not** store
  (`acc-adder.md` §6), so the 23-word stage contains **five** live bit-4 words
  (`w61`, `w64`, `w71`, `w73`/`w77`/`w78` in their escape modes, `w79`), not
  eight. See **L** in §0.

---

## 2A. Word-by-word verdict — I-RAM 60..82, updated from K5 §4

Changes against `k5-output-stage.md` §4 are marked **NEW** or **CHANGED**. The
column "what is claimed" is the *whole* claim; where it says OPEN, nothing is
claimed and the word keeps trapping.

| I-RAM | word | verdict | what is claimed |
|---|---|---|---|
| 60 | `092.1.8D.15B` | **OPEN** | **CHANGED**: register `0x8D` = unit-1 body cell **ENTRY+8**, which the reverb also writes (body words 120, 124). Its bit-4 store is **GATED OFF** (`bit7, f31` = 1,1) — so K5's/R2's "adjacent stores" reading is moot |
| 61 | `012.1.8D.05B` | **OPEN** | same cell `0x8D`; this one **does** store (`bit7 = 0`). Target unproven off mode 2 |
| 62 | `801.0.26.825` | **PROVEN** | `ldptr.d #$26` — the delay-descriptor pointer, aimed at unit 0's region base for the next frame (R3, isa-adjudication §6). Unchanged |
| **63** | `2A7.9.05.1C3` | **CONSISTENT** | **NEW**: `addr8 = 0x05` is the **unit-0 body ENTRY/SEND cell** (§3), `SRC 0x07` = the addressed operand ⇒ it **reads** it. Read/write pair with `w70`. Two readings enumerated (§7.2); best candidate for the word that puts the unit-0 result where `w73` reads it (§6.3) |
| 64 | `011.9.0E.445` | **DETERMINED** | unit-0 CALL VECTOR; host writes 84 (link) / 42 (disconnect). Unchanged (K5) |
| 65 | `200.1.8F.1C1` | **OPEN** | **NEW**: register `0x8F` = unit-1 **ENTRY+10**, one of the reverb's three **read-and-never-written** operands. `SRC 0x07` ⇒ this word reads it too, so nothing in the frame writes it — which by K6 §4's own criterion makes it externally supplied. Stated, not claimed |
| 66 | `000.1.8C.107` | **OPEN** | **NEW**: register `0x8C` = unit-1 **ENTRY+7**, another of the reverb's read-never-written operands. `ACT 0x07`, whose mode-1 destination §6.4 forces **not** to be `reg[addr8]` |
| 67 | `980.5.20.402` | **OPEN** | the hinge. **NEW**: one of only **two** mode-5 words in the machine, and the other is `w78`. `SRC 0x10` = acc |
| 68 | `092.1.8C.19B` | **OPEN** | cell `0x8C` again; bit-4 store **GATED OFF** |
| 69 | `801.0.90.821` | **INFERRED** | C-RAM pointer ← `0x90` (K3: FORCED not the cursor, FORCED not the D-RAM pointer). Unchanged |
| **70** | `2A6.1.85.0C7` | **CONSISTENT** | **NEW**: `addr8 = 0x85` is the **unit-1 body ENTRY cell** (§3) and the reverb's principal read-never-written operand. `ACT 0x07` ⇒ it **writes**, which is the mirror of `w63`. Two readings enumerated (§7.2) |
| 71 | `011.9.0F.446` | **DETERMINED** | unit-1 CALL VECTOR; 200 / 50. Unchanged (K5) |
| 72 | `000.1.06.087` | **CONSISTENT** | **CHANGED**: register `0x06` = unit-0 OUTPUT LEVEL = **ENTRY+1** (§3.4), and §6.4 **FORCES** that this word does not overwrite it ⇒ it is a **read**, confirming R2 against the ALU table's default |
| **73** | `E30.C.00.404` | **CONSISTENT** | **NEW**: `addr8` bit 7 = 0 ⇒ **unit 0**, independently of position (§6.1). `SRC 0x10` = **the accumulator** (ANCHORED) ⇒ the presented value is the accumulator (§6.3). Still the only mode-4+escape word; `ACT 0x04` occurs twice in 3057 words. The *arithmetic* stays OPEN |
| 74 | `C16.9.AB.000` | **INFERRED** | C-format, **opcode `0x60B`** — its own opcode, shared with nothing (§5). `A = 77` = I-RAM 77 |
| 75 | `82E.8.0F.000` | **OPEN** | class 8 post-sum step, operation unknown. `addr8 = 0x0F` |
| 76 | `C00.9.84.000` | **INFERRED** | WAIT/SYNC at its own address 76, event 4. **NEW**: opcode `0x600`, shared with `w82` and nothing else — so the two waits *are* one instruction, which the earlier "two `C00` words" observation asserted and this measures |
| 77 | `859.0.86.822` | **INFERRED** | pointer register `0x822` ← `0x86`. **CHANGED**: `0x86` = unit-1 OUTPUT LEVEL = **ENTRY+1** (§3). It is the **only** `lo12 = 0x822` word in the machine, and the only pointer-register load at an admissible closure site whose destination is not already spoken for — which is why it was the pass's first hypothesis for the D-RAM reload, and why §4 **rejects** it: the reload has to precede the unit-1 body |
| **78** | `A3C.D.9F.287` | **CONSISTENT** | **NEW**: `addr8 = 0x9F`, bit 7 = 1 ⇒ **unit 1**, independently of position (§6.1). `SRC 0x0A` occurs **once in 3057 words**. Not the same form as `w73` (§6.2) |
| 79 | `012.2.FF.1CE` | **PARTIAL** | stores the accumulator at `X+1 = 0x00`; **NEW**: absolute, from `X = 0xFF` (§4) |
| 80 | `104.2.00.1CE` | **PARTIAL** | reads `X+0 = 0xFF` |
| 81 | `102.2.00.000` | **PARTIAL** | reads `X+0 = 0xFF` |
| 82 | `C00.A.47.407` | **INFERRED** | FRAME WAIT at its own address 82, event 7. Opcode `0x600`, as `w76` |

**Coverage change, stated honestly.** No word moves into **tier 1** (an
executable mnemonic): nothing here supplies an operand encoding that a core
could run, and that is deliberate. What moves is the number of words with a
*named operand*: **0 → 8** (`w60`, `w61`, `w63`, `w65`, `w66`, `w68`, `w70`,
`w72`, plus `w77`'s payload and `w79`/`w80`/`w81`'s absolute cells). The
output stage's tier-1 figure stays **2/23 = 8.7 %** and the frame floor is
unchanged. A named operand is not a decode.

---

## 3. ★ The D-RAM origin, solved — three derivations

`output_stage.py dram`.

### 3.1 The one that needs no scan (**MEASURED, no free parameter**)

```
 PARAMETRIC EQ (algo 39)
   body touches 44 cells:  offsets [0, 9, 10, 11]  +  a CONTIGUOUS RUN OF 40 at 75..114
   host zero-fills 43:     [0x05, 0x06, 0x0E]      +  a CONTIGUOUS BLOCK OF 40 at 0x50..0x77

   40 == 40   =>   E + 75 = 0x50   =>   E = 0x05        UNIQUE
```

40 consecutive body cells and 40 consecutive host-filled cells can be aligned
exactly one way. The remaining four body offsets then land on `0x05`, `0x0E`,
`0x0F`, `0x10`, and the host fills `0x05` and `0x0E` — so **42 of the 43 filled
cells are inside the body's own footprint**, and PEQ's fill is the 5 bands × 2
channels × 4 Direct-Form-I state words `isa-adjudication.md` §5 already named.

### 3.2 The exhaustive scan (**MEASURED**)

For every candidate entry pointer `E ∈ [0, 256)`, how many of the host's fill
cells the body actually reaches, summed over all streams of that unit:

```
   unit 0 (79 streams, 729 fill cells):  E=0x05:626  E=0x04:467  E=0x03:458  E=0x06:431
   unit 1 (12 streams, 108 fill cells):  E=0x85:96   E=0x84:72   E=0x83:72   E=0x86:60
```

`E` must be **one number for all 37 unit-0 images**, because the header is shared.
The peak is unique and it is not close.

### 3.3 The one-line one (**MEASURED, 91/91**)

```
   min(host zero-fill)  =  0x05  in 79 of 79 unit-0 streams
                        =  0x85  in 12 of 12 unit-1 streams
```

The host never clears a cell **below** its unit's entry pointer, because below it
is the kernel's own I/O window. Three derivations, one answer.

### 3.4 What the answer looks like

```
   E1 − E0 = 0x80              <- R2's "bit 7 of a register index is the EFFECT UNIT"
   E0 + 75 = 0x50              <- the unit-0 state-block base the host itself uses
   E1 + 75 = 0xD0              <- the unit-1 one;  85 of 85 streams, both exact
```

and the fill cell that is **systematically unreachable** is:

```
   0x06  unreached in 70 streams        0x86  unreached in 12 of 12
```

— i.e. **ENTRY+1, which is the per-unit OUTPUT LEVEL** (PROVEN BY CONSTRUCTION,
R2 §2). The host clears it in every stream (it is inside the state block it
zeroes), then `EFF_VolumeLoop` writes the real level *after* `EFF_LinkLoop` — and
the bodies leave it alone. That was a **prediction of the map, checked after it**:
HIT. *(Wrinkle, stated: 8 of 37 unit-0 images touch ENTRY+1 and **3 of them
write it** — algos 8, 67, 74. Under the map those three clobber the unit-0 level.
Not explained.)*

### 3.5 The resulting 256-cell map

```
   0x00 .. 0x04   kernel I/O window     X = 0xFF, so X+1..X+6 = 0x00..0x05
      X+2 = 0x01, X+5 = 0x04            the two DI input latches (K6 §4)
      X+3 = 0x02                        written, never read (K6 §10)
   0x05           UNIT-0 entry / send   <- header w45 stores here, mode 2
   0x06           UNIT-0 OUTPUT LEVEL   <- host, PROVEN
   0x07 .. 0x4F   unit-0 body state
   0x50 ..        unit-0 STATE BLOCK    = entry+75, the host's own fill base
   0x85           UNIT-1 entry
   0x86           UNIT-1 OUTPUT LEVEL   <- host, PROVEN
   0x87 .. 0xCF   unit-1 body state
   0xD0 ..        unit-1 STATE BLOCK    = entry+75; header w53 stores here by
                                           ABSOLUTE INDEX (class 9 = mode 1)
```

The `w45` / `w53` **mode split** that `closure-pointer.md` §5 could only call
CONSISTENT now has a mechanism: `w45` runs before any body and can use the
pointer; `w53` runs after body 0, when the pointer is wherever that body left it,
so it must address absolutely. Both land on their unit's block.

### 3.6 ★ THE CONTROL — and one derivation does not survive it

`output_stage.py control`. A solve that cannot fail proves nothing, so the same
question is asked with **the answer destroyed**: each body scored against a
*different* algorithm's zero-fill.

```
   TEST A -- the aggregate scan of §3.2, scored AT E = 0x05
      TRUE 626    SHUFFLED(200) mean 384.0  sd 16.0  max 442     z = +15.1

   TEST B -- the same solve with the shared low registers EXCLUDED: only the
             contiguous STATE BLOCK, and only the 19 streams whose block is >= 8
      TRUE       E=0x05 : 17 of 19      (E=0x03 : 4, E=0x04 : 4)
      SHUFFLED(60)  best-E count max 14, mean 11.1, sd 1.1        z = +5.5
```

**⚠ And the part that does not survive: the shuffled pairing still PEAKS at
`0x05`.** Every stream's fill contains the same low registers `0x05`/`0x06`/`0x0E`
and every body walk starts at offset 0, so the *peak location* in §3.2 is a
baseline the scan rides on, not a discovery. **What is evidence is the EXCESS at
that `E`** — 626 against 384 ± 16 — and TEST B, which removes the baseline
entirely and still separates at z = +5.5.

**⚠ Second honest limit: 2 of the 19 big-block streams admit NO `E` at all** —
algos 15 and 53, whose zero-filled block is unreachable from *any* origin under a
single continuous walk. So the strict intersection over all big-block streams is
**empty**, while 17 of 19 agree on `0x05`. That is a limit of the **walk model**,
which `isa-adjudication.md` §5.1 already flagged as naive (no mid-body reload),
and it is the same class of failure as the 6 images of P-4.

⇒ **the load-bearing derivations are §3.1 and §3.3**, neither of which uses the
aggregate scan: PARAMETRIC EQ's two 40-cell contiguous runs have exactly **one**
alignment and no free parameter, and `min(host zero-fill)` is `0x05`/`0x85` in
**91 of 91** streams. §3.2 corroborates at z = +15 but **cannot locate the peak by
itself**, and this note does not let it pretend otherwise.

---

## 4. ★ Frame closure — residue ZERO

`output_stage.py closure`. Slot-exact displacements: `Δ(0..44) = +6`,
`Δ(45..49) = 0`, `Δ(50..58) = +2`, `Δ(59) = 0`, `Δ(60..82) = −1`; reverb net
`+123`.

```
   ROUTE 1   K6 FORCED that the cell w45 stores at IS the unit-0 entry
             (addr8 = 0, and w46..w49 cannot move the pointer):
                   X + 6 = E0 = 0x05          =>   X = 0xFF

   ROUTE 2   the reverb from its own MEASURED base, then the output stage:
                   0x85 + 123 − 1 = 0xFF      =>   X = 0xFF

   ★ THEY AGREE.
```

The whole frame, CHORUS in unit 0:

```
   PC-restart                             ptr = 0xFF
   header w0..w44          +6             ptr = 0x05    <- w45 stores the unit-0 SEND
   unit-0 body (CHORUS)    −9             ptr = 0xFC
   header w50..w59         +2             ptr = 0xFE    (w53 stores by INDEX at 0xD0)
   ---- REBASE at the unit-1 CALL ----    ptr = 0x85    (E1, MEASURED)
   unit-1 body (REVERB)  +123             ptr = 0x00
   output stage            −1             ptr = 0xFF
   ------------------------------------------------------
   residue                                 +0   ★ CLOSES
```

Against the single-walk model's **+121**, which is the ADVANCE pass's live number
(`+121` on 1 130 880 of 1 130 880 frames) and the static walk's `−135`.

**Honest limits, three of them.**

1. **The unit-1 net is one sample.** All twelve reverb presets share one image
   (`closure-pointer.md` §2.4), so ROUTE 2 cannot be varied. It is an
   arithmetic coincidence of `+123` unless it is design.
2. **ROUTE 1 inherits K6 finding 7**, which assumes no absolute reload in
   I-RAM 45..49. If `w46` (`800.1.60.00B`) is itself a rebase — the leading
   candidate, §7.1 — then `w45`'s store lands *before* it and the send would be
   delivered to the wrong cell, which is the argument *against* siting it there.
3. **`E0` needs no rebase.** The header walk from `X = 0xFF` lands on `0x05`
   exactly. That is either the design (the mix block accumulates in `X+6`, which
   *is* the unit-0 send cell) or a 1-in-256 coincidence. It is *not* independent
   evidence for `X`; it is the same equation as ROUTE 1.

---

## 5. The C-FORMAT OPCODE — `bits[35:25]`

`output_stage.py cformat`. Eight opcodes over the 68 C-format words:

| opcode | n | `imm13 % 32 == 0` | `lo12` | where |
|---|---|---|---|---|
| `600` | 2 | 0/2 | `000`, `407` | **`w76`, `w82`** — the two WAIT words |
| `602` | 1 | 0/1 | `820` | I-RAM 22 |
| `605` | 3 | 1/3 | `000`, `820` | I-RAM 1, 15, 31 |
| `60B` | 1 | 0/1 | `000` | **`w74`** |
| `620` | 57 | **57/57** | 6 values | the immediate-load family |
| `621` | 1 | 0/1 | `820` | I-RAM 29 |
| `625` | 1 | 1/1 | `820` | I-RAM 40 |
| `632` | 2 | 0/2 | `000`, `007` | I-RAM 48, 56 |

Three consequences.

1. **`is_c40()` is `opcode == 0x620`.** `(hi12 & 0xFFE) == 0xC40` is exactly
   `(hi12 >> 1) == 0x620`, so K3's "57/57 in, 2/11 out" is not a mysterious
   family-locality — the multiple-of-32 payload law is a property of **one
   opcode**, and the words outside it are simply *other instructions*.
2. ★ **The "five `lo12 = 0x820` words" are not a family.** They carry **four**
   opcodes (`602`, `605` ×2, `621`, `625`). Every pass that reasoned about them
   as a group — K3 §5.3's ζ reading, `closure-pointer.md` §8's exhaustive field
   search, `dsp-frame-advance.md` blocker #4 — was grouping by **destination**,
   not by instruction. The negative results stand; the *framing* was wrong, and
   it explains why no single field rule ever fit all five.
3. **`A` is an I-RAM address in 11 of 11 kernel C-format words**, and each one
   points somewhere structural: I-RAM 1 → 7 (block start), 15 → 20, 22 → 24,
   29 → 34, 31 → 37 (all block starts), 40 → 14 (an END-OF-BLOCK word),
   **48 → 45 and 56 → 53 (each unit's own send-store word)**, 74 → 77,
   76 → 76 and 82 → 82 (their own addresses). The body words' `A ≤ 40` is then
   naturally read as *block-relative*, which removes `instruction-set.md`'s
   caution ("a body word would have no business pointing at I-RAM 12") without
   needing a second meaning for `A`. **INFERRED**, and it is a worklist item
   (#4) that this pass moves but does not close.

---

## 6. The DO write — what is new

`output_stage.py do`.

### 6.1 The unit assignment is now independent of position

R2 §3.3 said plainly: *"`addr8` on `w73` (`0x00`) and `w78` (`0x9F`) is a sub-op
or port selector… Which value means which port is **OPEN**; the unit assignment
above comes from the neighbouring level registers, not from `addr8`."*

`addr8` **bit 7** is R2's own effect-unit selector (five positional
confirmations, zero counter-examples). `w73` has `addr8 = 0x00` (bit 7 = 0 →
unit 0) and `w78` has `addr8 = 0x9F` (bit 7 = 1 → unit 1). **The assignment R2
derived from the neighbours is reproduced by the words themselves.**

### 6.2 They are different instructions

```
   w73   mode 4 + ESC + fetch + store    SRC = 0x10 (acc, 701 corpus words)   ACT = 0x04 (2)
   w78   mode 5 + ESC + fetch + store    SRC = 0x0A (1 corpus word)           ACT = 0x07 (455)
```

`SRC 0x0A` occurs **once in 3057 words** and it is `w78`. `ACT 0x04` occurs
twice — `w73` and `040.0.00.864` in MULTI TAP DELAY. Mode 5 has **exactly two
members in the whole machine** and both are in the output stage (`w67`, `w78`);
mode 4 has 54, of which 53 are the table-lookup writer `012.4.01.1CE` and the
54th is `w73`. So the two presentations do not share a form, a source, an action
or an addressing mode. **A model that implements "the DO write" once and
parameterises it by unit is wrong.**

### 6.3 `w73` reads the ACCUMULATOR — and that narrows R2 item 9

`SRC 0x10 = the accumulator` is one of the four ANCHORED source codes. So at
`w73` the value presented **is** the accumulator. R2 §4.2 FORCED that unit 0's
result *cannot be in the accumulator* — but that argument is about surviving the
**156 words** between the unit-0 return at header `w49` and `w73`, not about
`w73`'s operand. Both are true only if something between I-RAM 60 and 72 puts
the unit-0 result into the accumulator.

**The only word in I-RAM 60..72 that names a unit-0 cell is `w63`**
(`2A7.9.05.1C3`, `SRC 0x07` = the addressed operand, `addr8 = 0x05` = the
unit-0 entry cell, §3.5). That is a positive, evidence-backed reading for a word
K5 listed as **OPEN**, and it makes the unit-0 chain

```
   w63  read the unit-0 result cell 0x05   ->   ...   ->   w73  present the accumulator
```

**CONSISTENT, not FORCED** — `w63`'s ACTION `0x03` is undecoded, so what it does
with the operand is not established, and ten words separate it from `w73`.

### 6.4 ACTION `0x07`'s mode-1 destination is NOT `reg[addr8]` — FORCED

`w72 = 000.1.06.087`. Mode 1, `addr8 = 0x06`, `ACT = 0x07`. Under the ALU decode
`ACT 0x07` is `M ← bus`. Register `0x06` is the **unit-0 output level**, written
once by `EFF_VolumeLoop` after linking (PROVEN BY CONSTRUCTION, R2 §2) and it
carries the user's effect depth, so it must persist. If `ACT 0x07` wrote the
addressed register, the depth would survive **one frame**.

⇒ on a mode-1 word `addr8` supplies the **operand**, and `ACT 0x07`'s destination
is something else (a port, or a `lo12`-named register). This turns
`alu_decoded()` guard 6 from a precaution ("MEASURED: this removes ZERO words")
into a **decided** question, and it confirms R2's reading of `w72` as *"READ
reg 0x06 = UNIT-0 LEVEL"* against the ALU table's default.

*Caveat, stated:* the escape is that `SRC 0x02` (undecoded) happens to carry the
level itself, making the write an identity. Contrived, but not excluded.

### 6.5 What is still OPEN about the DO write

* the arithmetic of `w73` and `w78` — ACTION `0x04` and SRC `0x0A` are decoded
  nowhere and each occurs once or twice;
* the L/R split within a port (R2 §3.3's D-1 vs D-2) — untouched;
* `w74` (opcode `60B`, `A = 77`) and `w76` (opcode `600`, WAIT at its own address,
  event 4) — the opcode split shows they are *different instructions*, which
  R2 §3.1's "four bit-4 words in two groups" reading implicitly denied.

---

## 7. ★ Question (b): what re-primes, and what does not

### 7.1 What the frame needs, and where

| resource | who re-primes it | where | status |
|---|---|---|---|
| per-unit **call vector** (I-RAM entry) | `w64` / `w71` | **output stage** | **DETERMINED** (K5) |
| **delay-descriptor** pointer | `w62` ← `0x26` = unit 0's region base | **output stage** | PROVEN (R3) |
| **C-RAM** pointer `0x821` | `w69` ← `0x90` | **output stage** | FORCED not the cursor (K3) |
| **C-RAM cursor** per-unit base | *not an immediate anywhere* | **I-RAM 50..58 or the CALL** | FORCED to exist (K4) |
| **D-RAM operand pointer** per-unit base | *not an immediate anywhere* | **I-RAM 50..58 or the CALL** | ★ **FORCED, this pass** |

The last row is the brief's question and the answer is **no, not in 60..82**:

* the rebase must **precede** the unit-1 body, and the output stage runs after it;
* `E0` needs no rebase — the header walk from `X = 0xFF` already delivers `0x05`;
* the frame **closes exactly** with one rebase before the unit-1 body and none in
  the output stage (§4). An epilogue-sited reload is not merely unsupported, it
  is **unnecessary**, and the closure equation no longer has a hole to fill.

The mechanism is a **REGISTER**, not an immediate (item **D**): `0x85` is in no
nibble-aligned field of I-RAM 50..58, and over every contiguous 8-bit field the
count is at chance. The single best-shaped candidate remains K4's:
**`800.1.60.00B`, `w46` and `w54`, occurring exactly twice in the machine, once
at offset +4 of each per-unit setup block and nowhere else** (verified here:
`hi12 == 0x800` with `addr8 == 0x60` has exactly those two sites). One word, unit
implicit from the CALL context, rebasing **both** per-unit resources — which is
what K4 wanted for the cursor and what closure wanted for the pointer, and they
would be the same instruction. **EDUCATED GUESS**, and it collides with R2's
mode-1+escape = external-delay-DRAM family (324/324), which would make `w46`/`w54`
DRAM reads. That collision is unresolved and is stated, not smoothed over.

### 7.2 …and yet `w63` and `w70` carry exactly the two base values

The two numbers this pass measured are `0x05` and `0x85`. Searching every
aligned 8-bit field of the output stage for them (`checks`, P-7) returns
`addr8` of **`w63`** (`0x05`) and **`w70`** (`0x85`) — and nothing else at an
aligned position. They are K5's measured symmetric pair, and each sits
**immediately before its unit's call-vector word**, so the per-unit group reads

```
    w63  [unit-0 base value 0x05]     w70  [unit-1 base value 0x85]
    w64  [unit-0 entry vector]        w71  [unit-1 entry vector]
```

Two readings, **enumerated, neither chosen**:

* **(R-1) they load the per-unit BASE REGISTERS for the next frame.** For: the
  values are exactly the measured bases; the position is exactly where a
  next-frame prime belongs (K5 §2.4 already established that the vector loaded in
  frame *n* is used in frame *n+1*); K4 and `closure-pointer.md` both FORCED that
  such registers exist and neither searched the output stage for their values.
  **Against, and it is a real problem:** `hi12` bit 0 is the "`addr8` is an
  absolute immediate" flag (PROVEN BY CONSTRUCTION for `0x801`), and it is **set
  on `w63` (`0x2A7`) and clear on `w70` (`0x2A6`)**. The two words disagree about
  whether their `addr8` is an immediate at all.
* **(R-2) they are ordinary mode-1 accesses to each unit's own entry cell** —
  `w63` reading `0x05` (SRC `0x07`) and `w70` writing `0x85` (ACT `0x07`). For:
  the SRC/ACT swap is exact; mode 1 is the register file indexed by `addr8`
  (R2, MEASURED, 324/324); and `0x85` is a cell the reverb **reads and never
  writes**, so something must supply it and `w70` is the only candidate in the
  machine. Against: that supplies the reverb's input **one frame late**, and
  §6.4 has just forced that `ACT 0x07` does not write `reg[addr8]`.

*(R-2) and §6.4 are in direct tension, and that is the sharpest single question
this pass leaves open.*

---

## 8. What this FALSIFIES or CORRECTS

| claim | where | status now |
|---|---|---|
| "the D-RAM operand pointer is re-established [in I-RAM 60..78] by the same mechanism [as the call vectors]" — the favoured resolution | `closure-pointer.md` §6.1 | **FALSIFIED in its D-RAM half.** The rebase must precede the unit-1 body. The output stage re-primes the *call vectors* and the *descriptor pointer*, and nothing else that closure needs |
| "ADMISSIBLE SITES = I-RAM 50..78, unconditionally 60..78" | `closure-pointer.md` §C | **PREMISE WITHDRAWN.** It assumes **one** absolute reload per frame; the machine rebases **per unit**, so `Δ(S+1..end)` is not one quantity. The site algebra is sound and its input was not |
| "the closure residue is **+121**… something in the model is wrong" | `dsp-frame-advance.md`, `instruction-set.md` | **EXPLAINED, and it closes.** The residue is exactly the drift a per-unit rebase discards. Residue **0** with `X = 0xFF` |
| ★ "the **non-returning-pointer problem is re-opened** — and it is numerically the same defect the live core reports as `+121`" | `retraction-sweep.md` item B (committed hours before this pass) | **ANSWERED.** The 2026-07-22 note that declared it solved was right that *something* re-establishes the pointer and wrong about what: not a per-frame reload of `0x821`, but a **per-unit rebase from a base register**, `0x05` / `0x85`. `-hi12.md` §5.1's "net deltas −87…+1149, zero in 0 of 38" is a measurement of the *bodies*, which are exactly the part the rebase discards |
| "the D-RAM absolute base is still unpinned, so **no D-RAM absolute is printed**" | `instruction-set.md`, Addressing | **PINNED** at the body-entry level: `0x05` / `0x85`, hence `X = 0xFF`. Conditional on the one-RAM reading, which this pass is the first positive test of |
| "K3's replacement candidate `lo12 = 0x827` … the slot is OPEN. `0x50`/`0xD0` is the better-supported candidate **and would pin the origin** *if* the two spaces are one RAM" | `instruction-set.md`, Addressing | the *if* is now tested and passes; but the pin is **`0x05`/`0x85`**, not `0x50`/`0xD0` — those are the **state-block bases at ENTRY+75**, which is why the naive test scored only 47/85 |
| "registers `0x8C`, `0x8D`, `0x8F` — the three the host never touches… Their role is **OPEN**" | R2 §3.3, §7 item 3 | **ANSWERED**: unit-1 body cells at ENTRY+7/+8/+10; `0x8C` and `0x8F` are two of the reverb's three read-never-written operands |
| "`w60`/`w61` are adjacent mode-1 stores with nothing between them, so under a `mem[ptr]` target the first is provably dead" | R2 §1, §4.4 | **MOOT.** The adopted bit-7 gate suppresses `w60`'s store outright. R2's conclusion stands on K5's call-vector result; this argument no longer contributes |
| "there is a per-unit RESULT REGISTER… the result never passes through D-RAM… **it cannot be in the accumulator either**" | R2 §0 item 9, FORCED | **NARROWED.** `w73`'s SRC is the accumulator, so it *is* there at the presentation. What is forced is that it does not survive 156 words — so a word in I-RAM 60..72 loads it |
| "the five `lo12 = 0x820` words" treated as one family | K3 §5.3, `closure-pointer.md` §8, `dsp-frame-advance.md` #4 | **the FRAMING is falsified** — four different opcodes. The negative results survive; the reason no field rule fit all five is that they are not one instruction |
| "`A` is an I-RAM address… **cautions against** generalising beyond `lo12 ∈ {445,446}`: a body word would have no business pointing at I-RAM 12" | `instruction-set.md` | the caution is answerable: **`A` is block-relative**, and the kernel is the block that starts at 0. 11/11 kernel words point somewhere structural. **INFERRED** |
| K6 finding 4/5 ("`X+2` and `X+5` are read and never written") | `dsp-k6-input-stage.md` | **still falsified** (`closure-pointer.md` §F), and now with absolute addresses: `X+2 = 0x01`, `X+5 = 0x04`, and **6 of 37 unit-0 images WRITE one of them** (algos 15, 50, 53, 56, 67, 74). This is the leading falsifier of the whole map and it is reported as such, not buried |

---

## 9. FORCED / CONSISTENT / OPEN

**FORCED**

1. The per-unit body **entry pointers** are `0x05` and `0x85`, given that the
   mode-1 index space and the mode-2 D-RAM are one RAM (§3).
2. `X = 0xFF`, by two routes that agree, and the frame **closes with residue 0**
   (§4).
3. A **rebase between the two CALLs** exists — `net(body0)` takes 8 values, so
   `E1` is unreachable by walking (§4, §7.1).
4. That rebase's value is **not an instruction immediate** in I-RAM 50..58
   (0 nibble-aligned hits; 4 hits at chance over all contiguous fields) ⇒ a
   per-unit **BASE REGISTER**, K4 item D confirmed with a measured value (§7.1).
5. **Nothing in I-RAM 60..82 re-primes the D-RAM base** (§7.1) — the brief's
   question (b), answered in the negative.
6. On a mode-1 word, ACTION `0x07`'s destination is **not** `reg[addr8]` (§6.4).
7. `w73` and `w78` do not share an instruction form; their SRC and ACT fields are
   disjoint and each is near-unique in the corpus (§6.2).

**CONSISTENT, not forced**

* `w63` reads the unit-0 result cell `0x05` and feeds the chain that ends at
  `w73`'s accumulator read (§6.3).
* `0x8C` / `0x8F` are the reverb's two non-send inputs and the output stage is
  where they are produced (§0 **G**) — direction not settled.
* `w46` / `w54` (`800.1.60.00B`) are the rebase (§7.1) — collides with R2's
  delay-DRAM family predicate.
* the C-format `A` is block-relative (§5.3).

**OPEN**

* **(R-1) vs (R-2) for `w63` / `w70`** (§7.2) — the sharpest question left, and
  §6.4 and (R-2) contradict each other.
* Which word does the rebase, and whether the CALL does it in hardware.
* The 6 unit-0 images that write `0x01` / `0x04` (§8, last row) — the map's
  leading falsifier.
* The 3 unit-0 images that write ENTRY+1, the output level (§3.4).
* ACTION `0x04`, SRC `0x0A`, ACTION `0x03`, ACTION `0x1B`, `f31` 3/4/6/7 — the
  output stage's own undecoded vocabulary. It remains **lexically disjoint**
  (R2 §14): 20 of 23 words occur nowhere else.
* What `w67` (the hinge, the only other mode-5 word) and `w75` (class 8,
  `addr8 = 0x0F`) do.

---

## 10. PREDICT-THEN-CHECK log

Predictions were written to a scratch file before the corresponding measurement.

| | prediction | result |
|---|---|---|
| **P-1** | `800.1.60.00B` occurs exactly twice, and `hi12 == 0x800 && addr8 == 0x60` nowhere else | **HIT.** I-RAM 46 and 54 only |
| **P-2** | The reverb's fill coverage has a unique maximum at `E = 0x85` with 8 of 9, runner-up ≤ 6 | **HIT, exactly.** `0x85`:8, `0x84`:6, `0x83`:6, `0x86`:5 |
| **P-3** | No word of I-RAM 50..58 carries `0x83`/`0x84`/`0x85` in any **aligned** 8-bit field | **HIT** for the stated (aligned) form: 0 hits. Over *every* contiguous field there are 4 (lsb 2, 9, 17, 21) against **≈3.1 expected** in 261 trials — **at chance**, and reported rather than dropped |
| **P-4** | Under `X = 0xFF` no word of any frame writes the DI-latch cells `0x01` / `0x04` | **MISS, and the important one.** 6 unit-0 images do (15, 50, 53, 56, 67, 74). It is a *subset* of `closure-pointer.md` §F's already-published "10 of 79 touch an input latch", so it damages K6 finding 4 and not this map — but it is the map's leading falsifier and §8 says so |
| **P-5** | The unit-0 counterparts of `0x8C`/`0x8D`/`0x8F` (i.e. `0x0C`/`0x0D`/`0x0F`) are named by no kernel word | **HIT.** The kernel's mode-1 indices are `{05, 06, 85, 8A, 8C, 8D, 8F, D0}` plus the unit tags `0E`/`0F`. The asymmetry `instruction-set.md` calls "unexplained" is real and now has a coordinate: the output stage does five register accesses in unit 1's block and two in unit 0's |
| **P-6** | Every unit-0 stream's fill block is based at ENTRY+75 | **HIT, 85 of 85** (both units) |
| **P-7** | The output stage contains no word that can supply `0x05` or `0x85` | **MISS, and the productive one.** `w63`'s `addr8` is `0x05` and `w70`'s is `0x85` — the *only* aligned occurrences in 3057 words. This is what §7.2 is about, and I would not have looked without the prediction failing |
| **P-8** | *(before §3.2)* the exhaustive scan will agree with the PEQ alignment | **HIT**, and by a wide margin (626 vs 467) |
| **P-9** | *(before §4)* the two routes to `X` will disagree, because the rebase model is new and under-constrained | **MISS, and the best one.** They agree to the unit, `0xFF` = `0xFF`. Recorded because the agreement is the single strongest piece of evidence in this note and I expected it to fail |
| **P-10** | *(before §3.6)* the shuffled control will destroy the peak, so §3.2 stands on its own | **MISS, and it cost §3.2 its status.** The shuffled pairing **still peaks at `0x05`**, because every fill contains the same low registers and every walk starts at offset 0. §3.2 survives only as an *excess* (626 vs 384 ± 16) and TEST B (z = +5.5); the derivation that carries the result is §3.1, which has no free parameter, and §3.3, which is 91/91. Had I not run the control I would have published a scan whose headline number measures the shape of the walk |

---

## 11. What this constrains for the other two targets

**TARGET 1 (the all-pass core / the reverb).** Three things.

* The reverb's **external inputs are exactly three cells** — `0x85`, `0x8C`,
  `0x8F` (ENTRY+0, +7, +10) — read at body words 5, 4 and 3 respectively, all
  three by `mac`-family words with coefficients. So the reverb opens with a
  **three-operand input mix**, not a single send, and any model that feeds it one
  sample is under-supplying it. Its state is `0x87`, `0x88`, `0x89`, `0x8A`,
  `0x8B`, `0x8D` and the three block cells `0xD0`/`0xD1`/`0xD2`, and **`0xD0` is
  where the header deposits the unit-1 send** (`w53`, absolute index).
* The reverb's D-RAM footprint is **14 cells**, and the all-pass ladder is *not*
  in it (`closure-pointer.md` §11 already said so); `0xD0`/`0xD1`/`0xD2` are the
  three cells that carry the ladder's read-modify-write traffic — one per
  ladder/separator — which is a new handle on the separator words.
* `SRC 0x00` — the code the reverb and SINGLE DELAY disagree about
  (`action-field.md` §8) — is **not** touched here, but note that the D-RAM
  origin being pinned makes the reverb's operands *nameable* for the first time,
  so a solver can now assert what each `mem[ptr]` read is.

**TARGET 3 (the LFO / the coefficient cursor).** K4's per-unit **coefficient
base register** and this pass's per-unit **pointer base register** are almost
certainly the same mechanism, and now both have measured values:
`cursor base = {0x00, 0x90}` and `pointer base = {0x05, 0x85}`. The pointer
base's two values differ by exactly `0x80`, which the cursor's do **not** — so
if one instruction rebases both, the pointer half is unit-tagged by a bit and the
cursor half is not, and that asymmetry is itself a constraint on the instruction.
Also: `closure-pointer.md` §11's warning to the LFO work — *"do not assume the
cursor is 0 at frame start"* — is unchanged, but the D-RAM half of that warning
is now lifted: a body's `mem[ptr]` cells **are** absolute and printable.

**For the disassemblers (a sync list, nothing done here).**

1. Render a C-format word as `opcode = bits[35:25]` + `imm13`, not as `hi12`
   microword flags. Both sides; then re-run `upd6383d_diff.sh` and `verify.py`.
2. Print D-RAM absolutes for mode-2 words, given a body's load unit
   (`0x05`/`0x85` + the walk) — **only** if the one-RAM reading is adopted, and
   labelled with that dependency.
3. Annotate `0x06` / `0x86` as the per-unit OUTPUT LEVEL and `0x50` / `0xD0` as
   the STATE-BLOCK BASE = ENTRY+75.
4. Stop rendering `w60`/`w68` as stores — the adopted gate suppresses them
   (this is a *display* bug; the executor already gets it right).

**For the MAME device (nothing applied).** If `X = 0xFF` is ever adopted, the
places are `m_dp`'s reset value and a per-unit rebase at the tagged transfer.
Both are INFERRED mechanisms, and adopting them would make frames complete for a
reason the corpus has not proved, which is exactly what this project refuses.

---

## 12. Safety and housekeeping

* **Neither disassembler was touched** and **no `.dsm` was regenerated**. Both
  checks re-run anyway:
  * `dsp/verify.py` → **BYTE-MATCH OK** (kernel + epilogue + 91 valid algorithm
    streams, 38 distinct images)
  * `kn7000_mame/tools/upd6383d_diff.sh` → **MIRRORS AGREE — 3057/3057**
* **Nothing was applied to `src/devices/cpu/upd6383/`.** The published binary is
  unchanged, so the DSPCFG-off audio is bit-identical **by construction** — there
  is no code path that could differ. `-validate kn5000` re-run: **clean**.
* The `+121` closure residue in the live core is **unchanged and still correct
  for the model the core implements**; this note explains it rather than patching
  it. Trapped frames still contribute zero, the 384-slot cap and the I-RAM
  overrun guard are untouched.
* New file: `dsp/tools/output_stage.py` (7 subcommands, stdlib only).

## 13. Reproduction

```
python3 dsp/tools/output_stage.py all          # every number in this note
python3 dsp/verify.py                          # the tree still byte-matches
bash ~/compartilhado/kn7000_mame/tools/upd6383d_diff.sh
```

Inputs: `original_ROMs/kn5000_subprogram_v142.rom` (microcode at CPU `0x01E496`
= header, `0x01E63C` = output stage; algorithm table `0x0001ED7C`; parameter
table `0x0001EF0C`; file offset = CPU address − `0x00EF00`) and the ROM parsers
in `~/compartilhado/kn7000_mame/tools`.
