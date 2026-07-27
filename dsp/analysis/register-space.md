# THE REGISTER SPACE, THE IMMEDIATE, AND THE LAST GATE ON THE AUDIO PATH

The other 44 dark words of the uPD6383GF frame — everything in `dark-words.md`'s
partition except the 42 external delay-DRAM slots a sibling pass owns.

KN5000 IC311, NEC uPD6383GF-3BA. Date: 2026-07-27.
Tool: `dsp/tools/register_space.py` (stdlib + the repo's ROM parsers) — every
number below comes out of it.

```
python3 dsp/tools/register_space.py             # everything
python3 dsp/tools/register_space.py transport   # the host write port, and the auto-increment
python3 dsp/tools/register_space.py cells       # the canned per-algorithm cell images
python3 dsp/tools/register_space.py outlevel    # ★ PRIORITY A -- w72 / w77
python3 dsp/tools/register_space.py regmap      # ★ the UI parameter -> DSP cell map
python3 dsp/tools/register_space.py cformat     # ★ PRIORITY B -- how wide is the immediate?
python3 dsp/tools/register_space.py actions     # PRIORITY C -- ACTION 0x0B / 0x0E
python3 dsp/tools/register_space.py families    # PRIORITY D -- the three remaining groups
python3 dsp/tools/register_space.py control     # the controls, each shown saying NO
```

**Nothing was applied.** No MAME source was touched, neither disassembler mirror
was edited, `dsp/verify.py` reports **BYTE-MATCH OK**, and **zero dark slots are
recovered by this pass** — everything below that is not FORCED keeps trapping, per
the standing rule. The one thing here that *is* FORCED (the C-format immediate
width) does not on its own make any word executable.

---

## Result table

| # | Claim | Status |
|---|---|---|
| **A1** | ★★★ **Cells `0x06` / `0x86` hold the user-facing parameter named `VOLUME`.** Not inferred from position: the effect's own parameter bytecode ends with a record whose opcode is `0x63`, whose T1 address is `0x06` (37 unit-0 algorithms) or `0x86` (12 unit-1 reverbs), and whose evaluator is `LABEL_038EB9` — a **dB curve-table lookup**. Aligning the 49 T2 record lists against the captured UI parameter lists binds opcode `0x63` to the name **VOLUME in 49 of 49** algorithms. | **MEASURED / PROVEN BY CONSTRUCTION** |
| **A2** | ★★★ **What is written, in what format, with what scaling.** A **24-bit unsigned Q0.23 LINEAR GAIN**, fetched as `TABLE[sel][user_value]` with `user_value ∈ 0..99` and `sel` a one-byte constant canned in the algorithm's own stream: `sel=0 → 0x012483`, `1 → 0x012613`, `2 → 0x0127A3` (read straight off `0x038EB9..0x038EF5`). `TABLE[*][0] = 0` in all three — **user value 0 is exact mute**. Ranges: A −49.8…−3.0 dBFS (0.48 dB/step), B −27.9…−4.5 (0.24), C −32.5…−7.2 (**0.258 dB/step exactly, min == max**). | **FORCED** |
| **A3** | ★★ **The two MEASURED cold-boot values are curve entries, and the check REJECTS the wrong twin.** `reg 0x06 ← 0x400000` is `CURVE_A[84]` and algo 1 CHORUS cans selector **0**; `reg 0x86 ← 0x178D0B` is `CURVE_C[70]` — **and is in no other table** — and algo 16 ROOM REVERB cans selector **2**. So the cold-boot state is *CHORUS VOLUME = 84, ROOM REVERB VOLUME = 70*, read out of the firmware. | **MEASURED**, control demonstrated rejecting |
| **A4** | ★★ **The R2/K5 "per-unit OUTPUT LEVEL" reading is CONFIRMED, by a chain that shares no premise with it.** R2/K5 argued from frame position plus the cold-boot capture; this argues from the parameter translator, the UI name table and the curve tables. Same answer, and now with a name and a law. | **CONFIRMED** |
| **B1** | ★★★ **`dark-words.md` §4.2 reading (II) is FALSIFIED.** "`C40.3.20.44C` carries imm13 = 800, and 800 samples is the ROOM REVERB pre-delay" — the word occurs **29 times across 11 unit-0 algorithms** (CHORUS, MODULATED CHORUS, ENHANCER, ROCK ROTARY, VIBRATO, ROTARY SPEAKER, MIX UP, four combos) and **0 times in any of the twelve reverb bodies**. Its immediate is **25**, not 800: the low five bits of `imm13` are structurally zero in this family. | **FALSIFIED** |
| **B2** | ★★ **The `is_c40()` immediate is EIGHT bits** — `B = imm13 & 0x1F = 0` in **7 of 7** distinct ROM forms / **57 of 57** words, plus **2 of 2** host-written `setvec` words. Control: **9 of 11** non-`is_c40` C-format forms carry `B ≠ 0`, so the zero is opcode-local, not format-wide. ⚠ **This re-derives `output-stage-decode.md` §"the payload rule", which already published 57/57. Credit is theirs; what is new is B1.** | **FORCED** (re-derivation) |
| **B3** | ★★ **The five `lo12 = 0x820` header words are the REGISTER-LOAD family with a wide immediate.** `0x820` = selector `0x20` + `lo12` bit 11 (`addr8 carries a payload`) — the same shape as `0x821` `ldptr`, `0x822`, `0x825` `ldptr.d`, `0x827`. So `dark-words`' unknown `C-DEST-820` **is the same unknown as "what is register `0x20`"**, and its 5 slots merge into group D rather than group B. `B ≠ 0` on 4 of the 5, so their immediate really is wide. | **CONSISTENT** |
| **C1** | ★★★ **`dark-words.md` §4.3 hypothesis (β) is FALSIFIED.** (β): *"the transfer is indirect through cell `0x0E`/`0x0F` of the tag-0x15 space, which the host primes"*. MEASURED: the host writes cell `0x0E` in **79 of 79** unit-0 algorithms **with the value 0**, and writes cell `0x0F` in **0 of 100** — nor `0x8E`, nor `0x8F`. The live cold-boot capture agrees independently (`0x0E` yes, `0x0F` no). Nothing primes those cells with I-RAM 84/200. | **FALSIFIED** |
| **C2** | ★★ **The mode-1 index space SPLITS IN TWO, and the split is measurable.** Of the 12 mode-1 dark words, **5 address a cell the host writes** (`0x0E` ×2, `0x8A`, `0x85`, `0x06`) and **7 address cells the host NEVER writes in any of the 100 algorithms or in the live capture** (`0x0F` ×2, `0x8C` ×2, `0x8D` ×2, `0x8F`). The never-primed set is exactly R2's *"three unexplained registers `0x8C`/`0x8D`/`0x8F`"* plus the unit-1 tag. Host-primed = RAM state; never-primed = what a hardware register/port looks like. | **MEASURED** |
| **D1** | ★★★ **The host write port auto-increments by +1** — enumeration `{0, +1, +2, +4, −1}` printed next to the claim. ⚠ **DEGENERACY CAUGHT:** the tiling argument (9 selects, stride 4, 4 packets each, `0x1D..0x40`) is satisfied by **both +1 and −1**; a descending burst tiles just as well. The tie is broken by a second, self-contained datum: algo 39 issues `select 0x50 ×29` then `select 0x6D ×11`, and `0x6D = 0x50 + 29`. ⚠ **My first discriminator was CIRCULAR** and was discarded — see §7. ⚠ The tiling itself is already published in `instruction-set.md`; what is new here is the enumeration and the degeneracy. | **FORCED** (+1), degeneracy reported |
| **D2** | ★★★ **`kn5000_dsp_params.py:writer_038539` / `writer_0387E6` — and `notes/kn5000-dsp-parameters.md` §2, which quotes them — encode the datum's byte 1 as `(v>>1)&0x7F`. It is `(v>>17)&0x7F`.** The writer is `sra 1,XWA ; sra 0,XWA ; and 0x7F`, and **on the TLCS-900 a shift count of 0 means 16**. Round-trip over the 1751 canned packets: `v>>17` **1751 exact / 0 wrong**; `v>>1` **938 / 813**. The MEASURED live value `0A 20 00 00 15` is `+0.500000` under `v>>17` and `+0.000000` under `v>>1`. | **FALSIFIED** |
| **E1** | ★★★ **The whole tag-0x15 (D-RAM) and tag-0x4C (delay-descriptor) images are now recoverable statically for every algorithm.** 100 PARAM streams walked: 881 D-RAM writes over **65 distinct cells**, 870 descriptor writes over **52 distinct cells**. This is the data source `dark-words.md` said had barely been used. | **MEASURED** |
| **E2** | ★★★ **The descriptor space is PARTITIONED BY UNIT, measured rather than enumerated: unit-1 owns `0x00..0x1F` (12 of 12 reverbs, identical extent), unit-0 owns `0x26..0x39` (79 of 79).** R3 §6.3 could only offer this as candidate (iii); it is now read directly off the host's own streams. | **MEASURED** — for the sibling pass |
| **F1** | ★★ **`0x90` is `REV SEND`, not the wet/output level.** `notes/kn5000-dsp-parameters.md` §5 predicted, marked SPECULATIVE, that "address `0x90` is the effect wet/output level". The alignment binds parameter opcode `0x21` → cell `0x90` → the name **REV SEND, 37 of 37**. The prediction is wrong; the level is `0x06`/`0x86`. | **FALSIFIED** |
| **G1** | ★ **ACTION `0x0E` is decidable today and ACTION `0x0B` is not.** The PARAMETRIC EQ body — solved to the bit — contains **2** ACT-`0x0E` words and **0** ACT-`0x0B` words. Also: **50 of the 82** corpus ACT-`0x0B` words are delay-DRAM words, so `0x0B` and the delay-DRAM family are entangled. | **MEASURED** |
| **H1** | ★★ **Zero of the 44 dark slots are recovered.** Every result above is either about a *value* (not an instruction), or FORCED but insufficient (B2), or a falsification. Stated first rather than buried. | **MEASURED** |

---

## 0. The ranking I stated before starting, and whether it held

`dark-words.md` proved leverage is not frequency, so the brief asks for a ranking by
**slots recovered per unknown resolved**, stated up front. Mine was:

| rank | group | slots | unknowns | slots/unknown |
|---:|---|---:|---:|---:|
| 1 | **B** — C-format immediate | 17 | 4 destination codes | **4.25** |
| 2 | **E** — unknown classes 0/4/5/6 | 12 | ~4 | 3.0 |
| 3 | **C** — mode-1 space | 12 | 12 distinct words | ~1.0 |
| 4 | **D** — class-0 register load | 3 | 2 selectors | 1.5 |
| 5 | **A** — `w72` / `w77` | **2** | 2 | 1.0 — *last* |

> ### ★ THE RANKING DID NOT HOLD, AND THE REASON IS USEFUL
>
> The metric put group B first. Group B produced a FORCED result (B2) that **recovers
> zero slots**, a mostly-already-published one, and a falsification (B1). The metric
> put PRIORITY A **last**, at two slots — and PRIORITY A produced the round's only
> complete positive result, including a scaling law.
>
> What actually predicted payoff was not slots-per-unknown but **"does the host
> firmware name this thing?"**. `0x06`/`0x86` are named by the parameter translator,
> the T1 map, the UI name table and two curve tables; the C-format destinations are
> named by nothing. A reachability term is missing from the metric, and `dark-words.md`'s
> own three metrics do not contain it either. Anyone reusing that ranking should add
> a column for *"is there a firmware structure that already knows the answer?"* —
> on this chip that column dominates.

---

## 1. The host write port — the data source

The Sub CPU reaches this chip through one uC-IF byte stream. Three writer routines
build (address, value) pairs; the address goes in an instruction word, the value in a
five-byte datum whose **low seven bits are a TAG naming the space**:

```
  LABEL_03846C / LABEL_038539   000.1.AA.000   then  0A .. .. .. |0x15   D-RAM
  LABEL_0387E6                  801.0.AA.821   then  0A .. .. .. |0x26   C-RAM
  LABEL_038922                  801.0.PP.825   then  0A .. .. .. |0x4C   delay descriptor
```

Those pairs are **canned in the ROM**, one stream per algorithm, behind
`PARAM_TABLE = 0x0001EF0C`. `kn5000_dsp_extract.parse_stream()` drops the op-0/1/5
records that carry them, which is why nobody had read them: this tool keeps them.
Over the 100 streams: **881 tag-0x15 writes and 870 tag-0x4C writes, and 0 tag-0x26**
— the canned C-RAM path is instead `801.0.NN.821` followed by a raw 3-byte op-2
block, so tag `0x26` is purely the *runtime* single-value writer.

### 1.1 The datum's field split — and a published formula falsified (D2)

`LABEL_038539`, Sub CPU `0x03859A`:

```
   3859a  ld XWA,(XSP+02)          ; v
   3859d  sra 1,XWA                ;  >> 1
   385a0  sra 0,XWA                ;  >> 16   <-- count 0 == 16 on the TLCS-900
   385a3  and XWA,0x7F             ; byte 1 = (v >> 17) & 0x7F
   385b4  sra 9,XWA ; and 0xFF     ; byte 2 = (v >>  9) & 0xFF
   385c8  sra 1,XWA ; and 0xFF     ; byte 3 = (v >>  1) & 0xFF
   385dc  sla 7,XWA ; and 0x80 ; add 0x15   ; byte 4 = ((v << 7) & 0x80) | tag
```

`kn5000_dsp_params.py` transcribes the first pair as one `>>1`. Round-trip over all
1751 canned packets: **`v>>17` 1751/1751, `v>>1` 938/1751** — the two agree on 938 and
disagree on 813, so the test is not vacuous. The live cold-boot value settles it
independently. `dsp_disasm.host_packet()` already uses the correct split, so **no
disassembly is affected**; the affected artefacts are the writer reproduction in
`kn5000_dsp_params.py` and §2 of `notes/kn5000-dsp-parameters.md`.

**OPEN, stated rather than smoothed over:** the writer emits byte 0 as a literal
`0x0A`, but 44 of the 1751 canned packets carry `0x0B`. All 44 target *even* cells of
the `0x50…` state block (the cells that hold delay lengths). Byte 1 bit 7 is 0 in
1751 of 1751. So one bit above the 24-bit field is in use and this pass does not know
what it means.

### 1.2 The auto-increment (D1) — with the degeneracy, and a circular test discarded

**ENUMERATION: step ∈ {0, +1, +2, +4, −1}.**

*D2 — the live capture.* `notes/data/kn5000_dsp1_upload_coldboot.txt` transfers 40..48
are nine selects at `0x1D, 0x21, 0x25, 0x29, 0x2D, 0x31, 0x35, 0x39, 0x3D`, **stride 4,
four packets each**:

```
   step +0 -> 36 writes ->  9 cells 0x1D..0x3D, gappy,      27 collisions   REJECTED
   step +1 -> 36 writes -> 36 cells 0x1D..0x40, CONTIGUOUS,  0 collisions   survives
   step +2 -> 36 writes -> 20 cells 0x1D..0x43, gappy,      16 collisions   REJECTED
   step +4 -> 36 writes -> 12 cells 0x1D..0x49, gappy,      24 collisions   REJECTED
   step -1 -> 36 writes -> 36 cells 0x1A..0x3D, CONTIGUOUS,  0 collisions   survives
```

★ **DEGENERACY (method rule 4):** +1 and −1 are *both* perfect tilings. Reporting
"+1 FORCED" from the tiling alone — which is what `instruction-set.md` currently
does — is a two-element survivor set presented as one.

*D1 — the tie-break, self-contained.* Algo 39 issues `select 0x50 ×29` then
`select 0x6D ×11`. Only under +1 does the first run end at `0x6C` so that the next
select is `0x6D`; under −1 it descends to `0x34` and `0x6D` relates to nothing.

> ### ⚠ A CIRCULAR DISCRIMINATOR, CAUGHT AND DISCARDED
> My first test was *"+1 is the only step reproducing `output-stage-decode.md` §3's
> contiguous 40-cell block at `0x50..0x77`"*. That block is computed by
> `output_stage.py:fill_cells()`, whose loop body contains `dest += 1`. **It assumes
> the answer.** Discarded before it was quoted. The replacement (D1) uses only the
> *addresses of two selects in one stream* and no derived quantity.

---

## 2. ★ PRIORITY A — `w72` and `w77`

```
   I-RAM 72  000.1.06.087   ★ DARK      class 1, cell 0x06, route lo12 0x087
   I-RAM 73  E30.C.00.404     PARTIAL   PRESENT unit 0 -> DO1 -> IC303.SDIA
   I-RAM 77  859.0.86.822   ★ DARK      register-load, selector 0x22, payload 0x86
   I-RAM 78  A3C.D.9F.287     PARTIAL   PRESENT unit 1 -> DO2 -> IC303.SDIB
```

### 2.1 The chain, end to end

```
   USER PARAMETER  "VOLUME", 0..99
     -> T2 record  [op 0x63][operand 0][one selector byte]        per algorithm, canned
     -> eval       LABEL_038EB9:  XHL = *(CURVE[sel] + 4*value)   dB table, PROVEN
     -> address    T1[0x63][0] = 0x06  (37 algos)  /  0x86  (12 reverbs)
     -> writer     LABEL_038539:  000.1.AA.000  +  0A.. |0x15     tag-0x15 D-RAM
     -> cell       D-RAM[0x06]  /  D-RAM[0x86],  Q0.23 linear gain
     -> the frame  w72 addresses 0x06 one word before the DO1 presentation
                   w77 aims pointer register 0x822 at 0x86 one word before DO2
```

### 2.2 The numeric test, and the control that says NO

The two cold-boot values are MEASURED at the host port. If the cells are written by
opcode `0x63`, each must be a member of *the table that algorithm's own stream
selects*. A random 24-bit value hits a given 100-entry table with p = 6.0e-6.

```
   algo  1 CHORUS         cell 0x06  0x400000  selector 0 -> CURVE_A[84]   HIT
                                     also in CURVE_B[84] and CURVE_D[96]
   algo 16 ROOM REVERB 1  cell 0x86  0x178D0B  selector 2 -> CURVE_C[70]   HIT
                                     in NO other table
```

★ **The unit-1 row is the discriminating one and it rejects**: had algo 16 canned
selector 0 or 1, the check would have failed. The unit-0 row is *not* discriminating
(three tables contain `0x400000`) and is not counted as evidence it cannot supply.

### 2.3 Which parameter is opcode `0x63`? — the alignment and its control

One T2 record = one user parameter. The record *boundary* is exact (big-endian length
prefix, `0x7A` terminator), so the record **list** needs no guessing. Aligning that
list, in order, against the captured per-effect UI parameter-name lists:

```
   algorithms with both a T2 stream and a captured UI list : 49
   record count == UI parameter count                      : 49 of 49
```

**THE CONTROL.** If the ordering were wrong, the *unit* attached to each name would
scatter across parameter opcodes. It cannot fail vacuously only if every opcode
already sees every unit, so the numbers are printed rather than asserted:

```
   op 63  n=49  units {'-':49}      VOLUME x49                       <- 100% pure
   op 21  n=37  units {'-':37}      REV SEND x37                     <- 100% pure
   op 61  n=10  units {'-':10}      DRIVE x10
   op 67  n=38  units {'ms':38}     PRE DELAY x12, DELAY L x11, DELAY R x11
   op 65  n=19  units {'Hz':19}     LFO SPEED x13, SLOW LFO SPEED x2, ...
   op 75  n=12  units {'s':12}      REVERB TIME x12
   op 69  n=8   units {'s':8}       WIND UP x4, WIND DOWN x4
   op 6A  n=8   units {'Hz':8}      TREBLE FAST/SLOW, BASS FAST/SLOW
   op 6D  n=8   units {'s':8}       ATTACK SENS. x4, RELEASE SENS. x4
   op 6F  n=2   units {'ms':2}      GATE TIME, MASK TIME
   op 70  n=43  units {'Hz':15,'-':28}  BAND EMPHASIS FC/Q/G, 14 each  <- the one mix
   => 22 of 23 opcodes carry EXACTLY ONE unit
```

The single "mixed" opcode is the PARAMETRIC EQ band triple, whose three UI parameters
*legitimately* have different units (FC in Hz, Q and G unitless) and which appears
exactly 14/14/14 — itself a confirmation, not a failure.

**A SECOND CONTROL, AND IT REJECTS THE SWAP.** Suppose `0x63` were REV SEND and
`0x21` VOLUME. The twelve reverbs have no REV SEND parameter — a reverb cannot send
to itself, and their UI list is `[REVERB TIME, PRE DELAY, HIGH DAMP GAIN, ER.LEVEL,
VOLUME]` with no send. Then they would carry `op 0x21` and not `op 0x63`. **MEASURED:
op 0x63 records over algos 16..27 = 12, op 0x21 = 0.** Rejected 12/12.

### 2.4 What is written, in what format, with what scaling

* **format** — 24-bit unsigned **Q0.23 linear gain** in one D-RAM cell.
* **scaling** — `gain = CURVE[sel][v]`, `v` the 0..99 user value, `sel` canned per
  algorithm. `CURVE[*][0] = 0`, so **v = 0 is exact mute**.
* **laws** — A: −49.82…−3.02 dBFS, 0.20–0.60 dB/step; B: −27.92…−4.52, 0.10–0.30;
  **C: −32.51…−7.22, min = max = 0.258 dB/step** (a perfect geometric ladder).
* **lifetime** — the algorithm's own init stream clears it to 0 (it is in the
  zero-fill of 79/79 unit-0 and 12/12 unit-1 streams); the parameter path rewrites it
  on every edit and once at link time.

### 2.5 What is still OPEN — and it is the instruction, not the value

`w72` and `w77` **keep trapping.** This pass settles the *cell* — its name, its
contents, its format, its law and its lifetime — and settles nothing about what the
two instructions do with it. In particular the two words are not the same form
(`w72` is a class-1 absolute reference; `w77` is a register-load aiming pointer
`0x822`), and no numeric context in this pass separates "multiply the accumulator by
this cell" from any other reading. Under method rule 6 that is where it stops.

---

## 3. ★ PRIORITY B — the C-format immediate

### 3.1 The width

```
  word            imm13      A     B    n  is_c40   lo12 as a route
  C40.0.00.1DA        0      0     0    2   yes     SRC 07  ACT 1A
  C40.1.80.000      384     12     0    4   yes     SRC 00  ACT 00
  C40.1.E0.451      480     15     0    8   yes     SRC 11  ACT 11
  C40.2.C0.000      704     22     0   12   yes     SRC 00  ACT 00
  C40.3.20.44C      800     25     0   29   yes     SRC 11  ACT 0C
  C40.3.A0.359      928     29     0    1   yes     SRC 0D  ACT 19
  C40.5.00.647     1280     40     0    1   yes     SRC 19  ACT 07
  ------------------------------------------------ 7 forms, B == 0 in 7, 57 words
  C00.9.84.000     2436     76     4    1    no
  C00.A.47.407     2631     82     7    1    no
  C04.3.12.820      786     24    18    1    no
  C0A.0.E0.000      224      7     0    1    no
  C0A.2.92.820      658     20    18    1    no
  C0A.4.B1.820     1201     37    17    1    no
  C16.9.AB.000     2475     77    11    1    no
  C42.4.57.820     1111     34    23    1    no
  C4A.1.C0.820      448     14     0    1    no
  C64.5.A2.000     1442     45     2    1    no
  C64.6.A2.007     1698     53     2    1    no
  ------------------------------------------------ 11 forms, B != 0 in 9
```

`B = imm13 & 0x1F = addr8 & 0x1F`, a free five-bit field of the encoding. Under a
uniform 13-bit immediate the chance that all 7 `is_c40` forms are multiples of 32 is
`32⁻⁷ = 2.9e-11`. **CONTROL:** 9 of the 11 non-`is_c40` forms carry `B ≠ 0`, so
"B is always 0" is false *as a statement about the format* — the test separates two
opcode families instead of passing vacuously.

**Enumeration next to the claim:** {a 13-bit immediate; an 8-bit immediate plus 5
reserved bits; an 8-bit immediate plus a 5-bit field that happens to be 0 throughout
this ROM}. The data refutes the first and does not separate the second from the third.
Independent 2/2 confirmation from the host: `C40.A.80.445 → A = 84` and
`C41.9.00.446 → A = 200`, the two body entry I-RAM addresses.

> **CREDIT.** `output-stage-decode.md` already published this as the *payload rule*
> (`is_c40()` == opcode `0x620`, 57/57) and already observed that the five `0x820`
> words are four different opcodes sharing a destination. This section re-derives
> both. It is included because `dark-words.md`, published afterwards, re-opened the
> 13-bit reading, and because the next subsection is what that re-opening cost.

### 3.2 ★ The falsification

`dark-words.md` §4.2, reading (II), and repeated in its OPEN list and in the brief:

> *`C40.3.20.44C` carries `imm13 = 800`, and **800 samples is the ROOM REVERB
> pre-delay R3 derived independently** from the descriptor cells.*

Where the word actually lives:

```
   algo  1  CHORUS            x4      algo 53  ROTARY SPEAKER    x3
   algo  2  MODULATED CHORUS  x4      algo 56  MIX UP            x2
   algo  3  ENHANCER          x2      algo 64  S.DELAY+CHORUS    x4
   algo 15  ROCK ROTARY       x3      algo 67  S.DELAY+VIBRATO   x2
   algo 50  VIBRATO           x2      algo 71  PEQ+CHORUS        x4
                                      algo 74  PEQ+VIBRATO       x2
   occurrences in any of the twelve REVERB bodies:  0
```

The reverb's own C-format word is `C40.1.80.000`, immediate **12**. And the ROOM
REVERB pre-delay is now MEASURED directly, from the host's own descriptor stream:
`descriptor[0x00] = 33568`, `descriptor[0x03] = 32768`, difference **800** — R3's
number confirmed, and it has nothing to do with this word.

**So the "800" is `25 × 32`, an artefact of counting a structurally-zero five-bit
field as part of the number, attached to a unit-0 idiom that never appears in the
program whose pre-delay it was said to be. Reading (II) is FALSIFIED.** The brief
asked for this to be tested at every plausible scaling across all 79 algorithms; the
distribution kills it before the scaling question arises.

### 3.3 What the destinations look like

```
   lo12 000  SRC 00 ACT 00  n=16  immediates [12, 22]
   lo12 1DA  SRC 07 ACT 1A  n= 2  immediates [0]
   lo12 359  SRC 0D ACT 19  n= 1  immediates [29]
   lo12 44C  SRC 11 ACT 0C  n=29  immediates [25]
   lo12 445  SRC 11 ACT 05  host  immediate  84    <- SETTLED, unit-0 call vector
   lo12 446  SRC 11 ACT 06  host  immediate 200    <- SETTLED, unit-1 call vector
   lo12 451  SRC 11 ACT 11  n= 8  immediates [15]
   lo12 647  SRC 19 ACT 07  n= 1  immediates [40]
```

Four of the eight — including *both* settled ones — share `SRC 0x11` and differ only
in ACTION (`05`, `06`, `0C`, `11`). **CONSISTENT** with "`SRC 0x11` = the immediate,
ACTION = the destination"; **not forced**, because the other four `is_c40` `lo12`
values do not carry `SRC 0x11`.

### 3.4 The `0x820` five are not a C-format puzzle at all (B3)

`lo12 = 0x820` is register **selector `0x20`** with `lo12` bit 11 set — the "`addr8`
carries a payload" flag — exactly the shape of `0x821` (`ldptr`), `0x822`, `0x825`
(`ldptr.d`) and `0x827`. These words are the register-load family carrying a **wide**
immediate instead of an 8-bit one (`B ≠ 0` on 4 of the 5 confirms the width is real
here). `dark-words`' `C-DEST-820` is therefore *the same unknown* as "what is register
`0x20`", and its five slots belong with group D, not group B. That re-partition costs
group B its rank-1 position on the slots-per-unknown metric.

---

## 4. PRIORITY C — ACTION `0x0B` and `0x0E`

Frame slots: `0x0B` **17**, `0x0E` **14** — the brief's figures reproduced.
Corpus: `0x0B` 82 words / 23 forms; `0x0E` 227 words / 53 forms.

**THE DECIDABILITY CENSUS** — the question is not where an ACTION is *frequent* but
where it sits inside a block whose arithmetic is already solved:

| algo | solved reference block | ACT `0B` | ACT `0E` |
|---:|---|---:|---:|
| 9 | SINGLE DELAY — comb, solved | 3 | 4 |
| 16 | ROOM REVERB — Schroeder comb network | 13 | 3 |
| 39 | **PARAMETRIC EQ — biquad, solved to the bit** | **0** | **2** |

★ **ACTION `0x0E` is decidable today**: it occurs inside the PARAMETRIC EQ body, where
every coefficient and every state cell is known, so a solver has a numeric target.
★ **ACTION `0x0B` is not**: the EQ has none, and all 13 reverb instances are the
all-pass motif's slot 5 (`102.A.00.64B`), whose value the R1 solve never reads.

★ **AND `0x0B` IS NOT MINE ALONE: 50 of the 82 corpus ACT-`0x0B` words are delay-DRAM
words** (`880.1.20.64B` ×28, `880.1.30.00B` ×11, `880.1.20.40B` ×7, `800.1.60.00B` ×2,
`880.1.60.00B`, `880.1.60.40B`). ACTION `0x0B` and the delay-DRAM family are
**entangled** — neither is separable from the other, and no block that omits the
delay line can settle it.

`ACT 0x0E` is dominated by `lo12 = 0x1CE` (144 corpus words) and `0x40E`. And every
corpus word with `lo12 = 0x1CE` has `class4 ∈ {2, 4}` — **91 class-2, 53 class-4,
nothing else**.

---

## 5. PRIORITY D — the three remaining families

### 5.1 The mode-1 space, and the split (C2)

```
   slot  word           cell  host writes it?   region
    49   400.1.0E.000   0x0E  YES               header
   119   602.1.0E.000   0x0E  YES               unit-0 body
   128   000.1.8A.007   0x8A  YES               header 50..59
   129   400.1.0F.007   0x0F  no                header 50..59
   262   612.1.0F.000   0x0F  no                unit-1 body
   263   092.1.8D.15B   0x8D  no                epilogue
   264   012.1.8D.05B   0x8D  no                epilogue
   268   200.1.8F.1C1   0x8F  no                epilogue
   269   000.1.8C.107   0x8C  no                epilogue
   271   092.1.8C.19B   0x8C  no                epilogue
   273   2A6.1.85.0C7   0x85  YES               epilogue
   275   000.1.06.087   0x06  YES               epilogue
```

The host's D-RAM write set is 65 of 256 cells, so a random address lands in it with
p = 0.254. **5 of 12** land in it. That is **not** a confirmation of "class-1 `addr8`
is an address in the host's D-RAM space" — the test had a live failure mode and
7 of 12 words took it. What it *is* is a partition:

* **host-primed** — `0x05 0x06 0x07 0x08 0x09 0x0A 0x0B 0x0C 0x0E 0x10..0x14 0x16
  0x1B 0x50..0x77` and their `|0x80` twins `0x85 0x86 0x87 0x8A 0x8B 0x94 0xD0..0xD2`.
  Bit-7 pairs actually observed: `05/85 06/86 07/87 0A/8A 0B/8B 14/94 50/D0 51/D1
  52/D2` — nine independent confirmations of "bit 7 of a cell index is the effect
  unit", from 79 + 12 algorithms.
* **never primed, in 100 canned streams *and* in the live cold-boot capture** —
  `0x0F`, `0x8C`, `0x8D`, `0x8F`. Three of the four are exactly R2's *"three
  unexplained registers"*. A cell the host never initialises is not state the host
  owns; it behaves like a hardware register or port.

That split also kills (β) — §C1 above.

### 5.2 The class-0 register loads

```
   I-RAM 43  801.0.6C.827   selector 0x27  payload 0x6C
   I-RAM 51  801.0.64.827   selector 0x27  payload 0x64
   I-RAM 77  859.0.86.822   selector 0x22  payload 0x86
   corpus selectors: 0x21 x4 (ldptr, settled)  0x25 x3 (ldptr.d, settled)
                     0x22 x1   0x27 x2   -- plus 0x20, via the five 0x820 words (3.4)
```

Selector `0x20` now carries **5 more dark slots** than the group-D count suggests.
Selector `0x22`'s single site is `w77`, whose payload `0x86` this pass has just named
(unit-1 VOLUME) — so `0x22` is a pointer register that gets aimed at the level cell
one word before the unit-1 presentation. Which is a *coherent story* and is
deliberately not promoted above CONSISTENT.

### 5.3 The unknown classes

```
   class 0: 809.0.00.839  A00.0.00.041 x4  040.0.00.C63  142.0.00.C63
   class 4: 012.4.01.1CE x2
   class 5: 980.5.20.402
   class 6: 000.6.18.4CD  000.6.20.407
```

★ **The minimal pair is far better armed than `dark-words.md` §4.4 thought.**
`012.4.01.1CE` has **53 corpus copies** against **2** for the class-2 member
`012.2.FF.1CE` whose addressing K6 forced. So a class-4 model is testable in 53
places, not 2. And with R2's mode table, class 4 and class 5 are the addressing modes
of the two **presentation** words (`w73` is class C = mode 4 + cursor fetch; `w78` is
class D = mode 5 + fetch), so the dark class-4 and class-5 words sit in the same modes
as the two words that reach the pins. Stated as a lead, not a result.

---

## 6. What the host's own tables now hand over

### 6.1 The named cell map (extract)

Alignment of §2.3, all 49 algorithms. **Caveat, stated because it is load-bearing:**
a T1 address is added to one of three per-writer base fields, so the same number is a
different cell in the C-RAM, D-RAM and descriptor spaces. This table conflates them;
only rows whose transport is separately MEASURED (VOLUME, REV SEND, the descriptor
delay cells) are unambiguous.

```
   0x06  VOLUME x37          0x86  VOLUME x12          0x90  REV SEND x37
   0x97  REVERB TIME x12     0x9E  HIGH DAMP GAIN x12  0xAC  ER.LEVEL x12
   0x1D  LFO WAVEFORM x16    0x17  GATE TIME           0x15  MASK TIME
   0x26  DELAY L x10 / DELAY 1     0x28  DELAY R / DELAY 2
   0x29  DELAY R / DELAY 3         0x2A  DELAY 4 / DELAY R
```

### 6.2 The delay descriptors, for the sibling pass (E1/E2)

Every algorithm's descriptor image is now readable. Examples:

```
   algo 10 MULTI TAP DELAY   26=6000  27=32685  28=12000  29=18000  2A=24000
                             2B=32768 2C=0
   algo  9 SINGLE DELAY      26=15435 27=31871  28=31370  29=0  2A=32768 2B=15935
   algo  1 CHORUS            26=400   27=4161   28=1440   29=0  2A=2480  2B=1040
                             2C=3520  2D=2080   2E=32768  2F=3120
   algo 16 ROOM REVERB 1     00=33568 01=45464  02=41673  03=32768 ... 1E=32767
```

* `26/28/29/2A = DELAY 1..4` for MULTI TAP is **independently confirmed by T1**
  (`op 0x67 → 26 28 29 2A`, all four named `DELAY n [ms]` by the UI alignment), and
  `6000/12000/18000/24000` at 44.1 kHz is `136/272/408/544 ms`.
* `2C = 0` for MULTI TAP is exactly the value R3 §6.3 used to identify
  `880.1.60.000` as the line write.
* ROOM REVERB `00 − 03 = 33568 − 32768 = 800` reproduces R3's pre-delay exactly.
* **The space is partitioned by unit: unit-1 `0x00..0x1F` (12/12), unit-0
  `0x26..0x39` (79/79).** R3 candidate (iii) named these two bases; they are now
  measured, not enumerated.
* CHORUS writes the same four tap lengths *twice* — into descriptor `26/28/2A/2C`
  **and** into D-RAM `50/52/54/56`, with `51/53/55/57 = 0`. The state block holds
  `(length, 0)` pairs; the descriptor holds the DRAM geometry.

---

## 7. Controls — each shown saying NO

| # | control | what it rejects |
|---|---|---|
| **C1** | writer round-trip over 1751 canned packets | `v>>1` scores 938/1751 against `v>>17`'s 1751/1751 — the published formula is rejected by 813 packets |
| **C2** | curve membership | `0x178D0B` is in CURVE_C only; selectors 0 and 1 would have failed |
| **C3** | auto-increment enumeration | steps 0, +2, +4 rejected by the tiling; −1 rejected by the abutment; **and +1/−1 shown degenerate under the tiling alone** |
| **C4** | `B == 0` | rejected for 9 of 11 non-`is_c40` C-format forms, so it is not a property of the format |
| **C5** | mode-1 host membership | rejected for 7 of 12 words, and hypothesis (β) dies on exactly that failure |
| **C6** | planted probes on the transport decoder | select words and `ldptr.d` correctly *not* decoded as packets; two tags decoded correctly |
| **C7** | UI-alignment unit purity | would scatter under a wrong ordering; 22 of 23 opcodes are unit-pure, the one exception being structurally correct |
| **⚠ discarded** | "+1 reproduces the 40-cell block" | **circular** — that block is computed with `dest += 1`. Removed before use. |

---

## 8. Predict-then-check — hits and misses with equal prominence

| # | prediction | result |
|---|---|---|
| P1 | the host write log names some of the dark set's registers | **HIT, and larger than expected.** It names `0x06`/`0x86` completely, and gives a 36-cell named map plus every algorithm's descriptor image. |
| P2 | `0x06`/`0x86` are the per-unit OUTPUT LEVEL (R2/K5's inference) | **HIT.** Confirmed by an independent chain, and refined: the parameter is called **VOLUME** and the value is a dB-table gain. |
| P3 | the C-format `800` will match a delay/pre-delay somewhere once every scaling is tried | ★ **MISS, and the useful kind.** The word never occurs in a reverb at all, and its low five bits are structurally zero, so "800" is not a number the machine ever holds. The lead dies on distribution before scaling is reached. |
| P4 | the in-program mode-1 indices are the space the host writes (k5 finding 4) | ★ **MISS, 5 of 12.** The four never-primed cells `0x0F`/`0x8C`/`0x8D`/`0x8F` are a *different* kind of thing, and saying so is stronger than the original claim. |
| P5 | the host primes cells `0x0E`/`0x0F` with the body entry addresses (hypothesis β) | ★ **MISS, decisively.** `0x0E` is primed with **zero** in 79/79 and `0x0F` is never written at all. (β) falsified. |
| P6 | my "40-cell block" test would be a clean positive control for the auto-increment | ★ **MISS — it was CIRCULAR.** Caught by reading `fill_cells()`. Replaced. |
| P7 | the tiling argument forces the increment to +1 | ★ **MISS — it forces `{+1, −1}`.** A descending burst tiles identically. This is a degeneracy in a currently-published claim (`instruction-set.md`), not just in my draft. |
| P8 | the published writer reconstruction is reliable enough to use as a control | ★ **MISS.** It is wrong by 16 bit positions; the shift count of 0 means 16 on this CPU. |
| P9 | this pass would recover some of the 44 dark slots | ★ **MISS. Zero.** Every result is about a value, a name, a partition, or a falsification. The instructions still trap. |
| P10 | the slots-per-unknown ranking would predict where the payoff was | ★ **MISS.** It ranked the winner last. §0. |

---

## 9. What this leaves

**FORCED / PROVEN BY CONSTRUCTION**

* The `is_c40()` immediate is 8 bits (re-derivation of `output-stage-decode.md`).
* The host write port's auto-increment is **+1** (enumeration `{0,+1,+2,+4,−1}`;
  D2 leaves `{+1,−1}`, D1 breaks it).
* The datum's byte-1 field is `(v>>17)&0x7F`, from the writer's own instructions.
* The `0x63` evaluator's selector→table map, read off `0x038EB9`.
* `w72`/`w77`'s cell is a Q0.23 linear gain from a dB curve table, cleared at load.

**MEASURED**

* 881 tag-0x15 and 870 tag-0x4C host writes over 100 streams; 65 and 52 distinct
  cells; the per-algorithm images; the unit partition of the descriptor space;
  49-of-49 record/UI alignment; 22-of-23 unit purity; op `0x63` → VOLUME 49/49;
  op `0x21` → REV SEND 37/37.

**CONSISTENT, not forced**

* `SRC 0x11` = "the operand is the immediate", ACTION = the destination (4 of 8
  `is_c40` `lo12` values, including both settled ones).
* The five `0x820` words are register selector `0x20` with a wide immediate.
* Selector `0x22` = a pointer register aimed at the unit-1 level cell.
* Class 4 / class 5 are the addressing modes of the two presentation words.

**OPEN**

* What `w72` and `w77` *do*. They keep trapping.
* Registers `0x20`, `0x22`, `0x27`; cells `0x0F`, `0x8C`, `0x8D`, `0x8F`.
* The `is_c40` destinations other than the two call vectors.
* The extra bit above the 24-bit datum (byte 0 = `0x0B` in 44 of 1751 packets, all
  targeting even cells of the `0x50…` state block).
* ACTION `0x0B` — and it cannot be settled without the delay-DRAM family.

**FALSIFIED here**

* `dark-words.md` §4.2 reading (II) and the 800-sample pre-delay coincidence.
* `dark-words.md` §4.3 hypothesis (β).
* `notes/kn5000-dsp-parameters.md` §2's byte-1 formula and
  `kn5000_dsp_params.py:writer_038539` / `writer_0387E6`.
* `notes/kn5000-dsp-parameters.md` §5's SPECULATIVE prediction that cell `0x90` is
  the wet/output level — it is **REV SEND**.
* The sufficiency (not the conclusion) of `instruction-set.md`'s auto-increment
  argument: the tiling alone leaves `{+1, −1}`.
* One of my own tests, discarded before use: the circular 40-cell-block
  discriminator.

---

## 10. For the other agents in this round

1. **The delay-descriptor pass gets its data.** Every algorithm's descriptor image is
   now a static read (`register_space.py cells`). Unit-1 occupies `0x00..0x1F`,
   unit-0 `0x26..0x39` — R3's candidate (iii) bases, measured. MULTI TAP's
   `26/28/29/2A` are confirmed as `DELAY 1..4` by an independent table (T1) *and* by
   the UI name list, and `2C = 0` is the value R3 used for the line write.
2. **ACTION `0x0B` is 61 % delay-DRAM words (50 of 82).** Whoever settles the DRAM
   family will settle `0x0B` with it, and vice versa; they are one problem.
3. **The store-gate pass should know** that `w77` (`859.0.86.822`, the one site where
   `hi12` bit 4 and the format escape collide) aims a pointer at a cell this pass has
   now named — the unit-1 VOLUME. Whatever bit 4 does there, its target is a level
   register, not a data-path cell.
4. **`instruction-set.md`'s auto-increment sentence needs one word changed**: the
   tiling proves *stride-1 addressing*, not *ascending* stride-1. The direction comes
   from the algo-39 abutment.
5. **Do not reuse `kn5000_dsp_params.writer_038539`** until byte 1 is fixed to
   `(v>>17)&0x7F`. Anything derived from re-synthesised writer bytes is suspect;
   anything derived from `dsp_disasm.host_packet()` is fine.

---

## 11. Files

* `dsp/tools/register_space.py` — this pass's tool; eight subcommands, seven controls
  each demonstrated rejecting, one of its own discriminators withdrawn for
  circularity.
* `dsp/analysis/register-space.md` — this note.
