# THE HOST SIDE — what the firmware already knows, asked systematically

NEC **uPD6383GF-3BA** (Technics SX-KN5000, IC311). Date: **2026-07-27**.
No hardware. The two dumped ROMs, the one live cold-boot host capture, and the
firmware's own tables.

Companion to `register-space.md`, which opened this data source and closed with a
ranking lesson: *what predicted payoff was not slots-per-unknown but* **does the
host firmware already name this thing?** This pass is that question asked
exhaustively.

Reproduce every number with

```
python3 dsp/tools/host_side.py                # everything
python3 dsp/tools/host_side.py dispatch       # ★ opcode -> evaluator -> writer -> SPACE
python3 dsp/tools/host_side.py laws           # the value laws + a predict/check
python3 dsp/tools/host_side.py descbase       # is `cell == T1 address'?
python3 dsp/tools/host_side.py regmap         # ★ the per-SPACE named-cell map
python3 dsp/tools/host_side.py motifs         # ★ SINGLE DELAY and PARAMETRIC EQ
python3 dsp/tools/host_side.py spaces         # ★ rule 7: H vs the instruction-blind rival
python3 dsp/tools/host_side.py lfo            # ★ opcode 0x74 = a 36-cell wavetable
python3 dsp/tools/host_side.py mode1          # the mode-1 split, re-tested
python3 dsp/tools/host_side.py hostif         # ★ the transport, the READY line, the commands
python3 dsp/tools/host_side.py control        # every control, each shown saying NO
```

**Nothing was applied.** No MAME source touched, neither disassembler mirror
edited, `dsp/verify.py` reports **BYTE-MATCH OK**. Zero dark slots are recovered:
every word that trapped before still traps.

---

## Result table

| # | Claim | Status |
|---|---|---|
| **A1** | ★★★ **THE OPCODE → ADDRESS-SPACE MAP, decoded from the dispatcher.** `register-space.md` §6.1's named-cell table carries one load-bearing caveat — *"a T1 address is added to one of three per-writer base fields, so the same number is a different cell in the C-RAM, D-RAM and descriptor spaces; this table conflates them"*. It is now un-conflated by reading the code: the 25-entry jump table at ROM `0x014745` + base `0x03CB8E` gives 25 stubs (plus three explicit ones for `0x21`/`0x24`/`0x40`), and **every stub calls exactly one evaluator and one of exactly four writers**. Result: **17 opcodes write C-RAM, 6 write D-RAM, 1 (`0x67`) writes the delay descriptor, 4 are composites** (which resolve to 3 C-RAM + 1 D-RAM). ENUMERATION printed next to the claim; there is no fifth writer. | **PROVEN BY CONSTRUCTION** |
| **A2** | ★★★ **The relocation base is ZERO, so `cell = T1[opcode][operand]` exactly.** `DSP_WriteParameter` passes descriptor array `0x014777`; **10 consecutive 12-byte descriptors are entirely zero** and the 11th 12 bytes are not a descriptor. Independent confirmation from the live capture (which knows nothing of that array): algo 1's `T1[0x63][0] = 0x06` and algo 16's `= 0x86`, and the capture wrote `000.1.06.000` / `000.1.86.000`. 2 of 2, each of which would have been offset by a non-zero base. | **FORCED** |
| **A3** | ★★★ **Opcode `0x74` = `LFO WAVEFORM` is not a cell, it is a 36- or 32-entry D-RAM TABLE**, uploaded from one of **six** ROM tables (`0x01EAFA`/`0x01EB67`/`0x01EBD4`, 36 entries; `0x01EC41`/`0x01ECA5`/`0x01ED09`, 32) selected by *(one stream flag byte, the 0..2 user value)*. Read off the numbers: the first three are three cycles of a 12-point **SINE**, **TRIANGLE** and clipped **SQUARE** of period 24. Destination base cell `0x1D` is the table's own first ROM byte. **The live cold-boot capture's 36-value burst at `0x1D..0x40` is the SINE table, 36 of 36 values identical, in emission order.** | **PROVEN BY CONSTRUCTION** + **MEASURED** |
| **A4** | ★★★ **THE WRITE PORT'S AUTO-INCREMENT IS NOW PROVEN BY CONSTRUCTION, not by tiling.** Writer `0x038606` emits **five bytes and they are all one tag-0x15 packet — no address word** — and opcode `0x74`'s loop calls it **three times after** `0x038539` in every group of four. Four values reach four distinct cells from one address word. `register-space.md` D1 correctly reported that the *tiling* argument leaves `{+1, −1}` degenerate; that argument is now superseded for the magnitude. | **PROVEN BY CONSTRUCTION** (\|step\| = 1) |
| **A5** | ★★ **Two new direction discriminators, neither of them the tiling nor `register-space.md`'s algo-39 abutment.** (i) THE CLOBBER TEST: under −1 the wavetable occupies `0x1A..0x3D`, under +1 `0x1D..0x40`; **2 of the 26 algorithms carrying an op-`0x74` record have a canned D-RAM write to `0x1B`** (ROCK ROTARY, ROTARY SPEAKER) which −1 destroys, and **0** have one to `0x3E`–`0x40`. (ii) SMOOTHNESS: −1 reverses every group of four, making the D-RAM image **1.86–2.42× rougher** for all three 36-entry waveforms. (ii) assumes ascending-order reads; stated. | **CONSISTENT**, two independent legs |
| **B1** | ★★★ **`register-space.md` C2's dichotomy is FALSE AT ITS FIRST ELEMENT.** C2 split the 12 mode-1 words into "host-primed = RAM state" and "never primed = a hardware register or port". MEASURED: the class-1 index word is **the last word of every body image** — the terminator — and it carries `addr8 = 0x0E` in **37 of 37** unit-0 images and `0x0F` in the one unit-1 image. So cell `0x0E` is *both* host-primed (79/79 unit-0 canned streams write `000.1.0E.000` with value 0) *and* the terminator's unit index. **One register, both roles**: "host-primed" and "hardware register" are not alternatives. | **MEASURED** / the inference **FALSIFIED** |
| **B2** | ★★★ **In this family the two units differ by +1, not by +0x80** — and +0x80 is the rule the host's D-RAM cells obey **428 of 428** (`k4-cursor.md` item G). The +0x80 rule *predicts* `0x8E` for the unit-1 terminator and is rejected: the cell is `0x0F`. The `0x0E`/`0x0F` pair is therefore **not** a bit-7 unit pair of the parameter cell space. | **MEASURED**, control demonstrated rejecting |
| **B3** | ★★ **The "never primed" statistic is AT CHANCE once the denominator is right.** `register-space.md` C2 quoted p = 0.254 from the **65** canned cells. Adding every runtime parameter path the firmware has (the T1 targets of all six D-space opcodes, and opcode `0x74`'s 36-cell block) the reachable set is **101 of 256 = 0.395**, against **5 of 12 = 0.417** observed. Membership carries **no signal at all**. The four cells `0x0F 0x8C 0x8D 0x8F` do survive the stronger unreachability test — but so do 39 others in the same two windows. | **MEASURED** — my own result, weakened |
| **C1** | ★★★ **THE CHIP HAS AN OUTPUT REGISTER AND THE FIRMWARE READS IT ON EVERY BYTE.** `DSP_SEND_COMMAND` (`0x036331`) and `DSP_SEND_DATA` (`0x0367EE`) poll **PH.0** — set by the host at `0x0383FA`, sampled by `LDCF 0,(0x44)` at `0x0383FD` — with a bounded **8000-iteration** wait, and they sample it a **second** time at the instant of the write. **Two distinct error returns**: timeout, and ready-lost. A model that answers "always ready" is a model of a chip that never stalls. | **MEASURED** |
| **C2** | ★★ **And the firmware's response to a stalled DSP is to give up silently.** `DSP_ParameterWriteEngine` tests the return at `0x03CA21`/`0x03CA80`; on non-zero it calls `0x03CFED`, **which is a bare `ret`**, and abandons the record. No retry, no user-visible error. | **MEASURED** |
| **C3a** | ★★★ **The read strobe exists and is NEVER ASSERTED.** Call-site census of the nine pin primitives over the whole 192 KB Sub CPU ROM: `/WR assert` 2, `/RD release` 6, READY read 6 — and **`0x0383B7`, the routine that asserts /RD, has ZERO call sites**. The chip's byte port is bidirectional (the primitive exists) and this firmware only ever writes. There is no host read-back against which any data-direction hypothesis could be validated. | **MEASURED** |
| **C3** | ★★ **A SECOND chip-side input exists and is read exactly once.** `DSP_SYSTEM_INIT` samples **PH.3** at `0x034C87` and stores its **complement** into bit 3 of the config word at RAM `0x041343`, before `DSP_RESET` runs. It is the only DSP-side input outside the byte handshake. | **MEASURED** |
| **C4** | ★★★ **THE CHIP'S COMMAND-BYTE SPACE, censused.** `0x01` + a 16-bit N = *aim the write pointer at N, then stream 36-bit words*; N ∈ {`0x0000 0x003C 0x0040 0x0047 0x0054 0x00C8`} are I-RAM word addresses **0/60/64/71/84/200** — the kernel, the two link words and the two body entry points — while **`0x0160` is a poke PORT, not an I-RAM address**. `0x02` + `0x0161` = the 24-bit coefficient port. `0x03` = end of transaction. `0x04`/`0x09`/`0x0C` = boot-time singletons. **`0x30` is not IC311 at all.** | **MEASURED** |
| **C5** | ★★★ **THE "MALFORMED" ALGORITHM SET IS NOT MALFORMED.** Every tool in `dsp/tools` excludes `{79, 88, 89, 90, 91}` as `MALFORMED`. They are **exactly the five algorithms with no IC311 program**: their op-3 program record carries command `0x30` and a "load address" of `0x05F0`/`0x0D30` which is not an I-RAM word address. **They are DSP2 (MN19413, IC310) programs** — GEQ, ROOM, KARAOKE, BATH ROOM, STAGE. ~~Algorithms 57–60 (STANDARD/PERCUSSIVE/SYMPHONIC/DEEP SPACE) configure **both** chips.~~ ⛔ **CORRECTED 2026-07-27, and the correction is FALSIFYING, not additive** (`second-dsp-and-ready.md` §2): algorithms **57–60 are IC310-ONLY too**. Algo 57's program stream is **one** op-E cmd-0x30 record and its parameter stream is **four**; there is **no IC311 traffic in any of the nine**. The partition is **IC311 91 / IC310 9 / both 0 / neither 0**, so **the IC311 algorithm population is 91**, not 95 or 96. Only five were ever flagged because their cmd-0x30 rides on record opcode **3** (which an IC311-shaped parser turns into a phantom I-RAM block); 57–60's rides on opcode **`0x0E`** and parses to nothing. | **PROVEN BY CONSTRUCTION** for the five; the “both chips” clause **FALSIFIED** |
| **D1** | ★★★ **`action00-discriminator.md` §0-H's three SINGLE DELAY labels are all wrong, and `store-gate.md` item J′ closes.** Algo 9's canned C-RAM image is **two mirrored 9-cell channel blocks**: `0x00..0x08` and `0x09..0x11` are value-for-value identical. The host names `0x00` **FEEDBACK L** and `0x09` **FEEDBACK R** (opcode `0x73`, operands 0 and 2). `0x01`/`0x0A` are T1-allocated and never referenced. `0x02`/`0x0B` are `+0.5000` in both channels and **carry no user name at all**. So `w3` (cell `0x00`) is not an input mix, `w4` (cell `0x01`) is not the other half of one, and `w6` (cell `0x02`) is **not "the feedback"**. | **MEASURED** |
| **D2** | ★★ **PARAMETRIC EQ's cell layout, from the host: five bands on a SIX-cell stride.** `T1[0x70] = 00 06 0C 12 18 | 64 68 6C 70 74`; the three UI knobs `BAND EMPHASIS FC/Q/G` of band *b* are three T2 records with the **same operand** *b*, and the handler writes **three C-RAM cells** per record. Every band's canned image has `cell+3 = −(cell+0)` and `cell+5 = −1.0000` exactly. | **MEASURED** — for the matching pass |
| **E1** | ★★ **A three-way agreement that no single artefact could give.** Opcode `0x67` is the **only** opcode routed to the delay-descriptor writer; its evaluator `0x03925E` is the **only** one that multiplies by `44100/1000`; and its UI unit is **`ms` in 38 of 38** named sites, against **2 of 100** in the D space and **2 of 265** in the C space. Three independent firmware structures, one answer. | **MEASURED** |
| **F1** | ★ **Zero dark slots recovered, stated first rather than buried.** Everything above is about a *name*, a *space*, a *value* or a *transport*. Under method rule 6 nothing here reaches the device or either disassembler. | **MEASURED** |

---

## 1. ★ The dispatcher — and what it settles

`DSP_PerParameterTranslator` (`0x03CAAE`) resolves `(opcode, operand)` to an
address through T1, fetches the user's signed 16-bit value, and jumps:

```
   opcode 0x21 -> 0x03CEE2   0x24 -> 0x03CEBC   0x40 -> 0x03CE9F   (explicit)
   opcode 0x61..0x79        -> 0x03CB8E + OFFSETS_14745[op - 0x61]
   opcode 0x7A               -> end of record
   anything else             -> error code 5    (0x03CEFF)
```

and every stub has one shape:

```
   lda XWA,XSP+0x2a          ; &stream_pointer
   ld  XBC,XDE               ; the user's value
   call <EVALUATOR>          ; -> XHL = the 24-bit datum; the stream advances
   pushw (XSP+0x0N)          ; ** N NAMES THE SPACE **
   ld  WA,IZ / ld XBC,XHL / ld DE,(XSP+0x16)
   call <WRITER>
```

`(XSP+0x04)`, `(XSP+0x06)`, `(XSP+0x08)` are the descriptor's `+0`, `+2`, `+4`
fields, loaded at `0x03CAD0`, `0x03CAE6`, `0x03CAFC`; each writer adds its own
field to the T1 address.

**ENUMERATION, printed beside the claim.** The translator contains exactly four
writer entry points and every stub calls one of them or none:
`{0x0387E6 → 801.0.AA.821 + tag 0x26, 0x03846C → 000.1.AA.000 + tag 0x15,
0x038539 → the same routine duplicated, 0x038922 → 801.0.PP.825 + tag 0x4C,
composite}`.

| space | opcodes |
|---|---|
| **C-RAM** `801.0.AA.821` + tag `0x26`, descriptor field `+0` | `21 24 40 61 62 65 66 69 6D 6E 6F 71 73 75 77 78 79` and composites `70 72 76` |
| **D-RAM / register file** `000.1.AA.000` + tag `0x15`, field `+2` | `63 64 68 6A 6B 6C` and composite `74` |
| **DELAY DESCRIPTOR** `801.0.PP.825` + tag `0x4C`, field `+4` (+ the `+8` u32) | `67` — *and nothing else* |

The four composite handlers were bounded by the next handler entry and their
writer calls counted, so the count is a measurement rather than a reading:
`op 70` 3 × C-RAM, `op 72` 1 × C-RAM, `op 74` 1 × D-RAM (+ the auto-increment
continuation writer), `op 76` 3 × C-RAM.

> **What this corrects.** `notes/kn5000-dsp-parameters.md` §6 says *"the mapping
> opcode → eval helper was derived from the jump table's address order and does
> not survive the immediate-size check for every opcode… treat only 0x21, 0x24,
> 0x40, 0x62 and 0x63 as settled"*. The jump table is **not** in address order —
> opcode `0x79`'s offset is `0x88`, between `0x63`'s `0x6C` and `0x64`'s `0xA5` —
> which is exactly why the order-derived table was wrong. Read properly it is
> settled for **all 28**.
> §10 of the same note lists *"C-RAM vs D-RAM: which is which is not
> established"*. Still not established as a **physical** identity — what is now
> established is which *opcode* goes to which *writer*, which is what the cell
> map needed.

---

## 2. ★ Rule 7 — is the space map separable from a rule that never reads the instruction?

The map is PROVEN BY CONSTRUCTION, so this section is a consistency check on my
*reading* of the code, built so that it can fail.

Population: **403 (algorithm, record) parameter sites over 49 algorithms**, of
which **60 are unit-1** — restricted to the 91 algorithms whose program loads at
I-RAM 84 or 200, i.e. the ones that are on IC311 at all (see C5).

The three spaces are unit-partitioned, MEASURED, **with opposite polarity** —
which is the structural asymmetry a wrong assignment must violate:

```
   D-RAM        unit 0 : addr <  0x80        unit 1 : addr >= 0x80
   C-RAM        unit 0 : addr <  0x80        unit 1 : addr >= 0x90
   DESCRIPTOR   unit 1 : 0x00..0x1F          unit 0 : 0x26..0x39     <-- INVERTED
```

**THE RIVALS.** As rule 7 demands, the strongest rival that *never looks at the
instruction*: a rule that assigns a space **per address**, free to pick whichever
space maximises its score at each address. That is the optimum over the whole
instruction-blind family, by construction, not by sampling.

```
   STATISTIC 1  unit-block conformance, all 403 sites
      H   the dispatch map            366/403 = 90.8 %
      R1  all-D  (the flat reading)   354/403 = 87.8 %
      R1  all-C                       342/403 = 84.9 %
      R1  all-S                        38/403 =  9.4 %
      R2* BEST address-only rule      354/403 = 87.8 %
```

90.8 % against 87.8 % is **not** a decode, and it is printed so. The test that
does work is scored **only where the rivals disagree**:

```
   STATISTIC 2  the 56 sites whose address is used BOTH by opcode 0x67 and by
                some other opcode.  The address in question is 0x00: it is the
                reverbs' PRE DELAY (descriptor, unit-1 block 0x00..0x1F) and it
                is a unit-0 coefficient in 44 other algorithms.  An address-only
                rule must give 0x00 ONE space and therefore loses one side.
      H     56/56 = 100.0 %
      R2*   44/56 =  78.6 %       <- and it CANNOT do better
      R1 all-D / all-C  44/56     R1 all-S  12/56
```

```
   STATISTIC 3  same-space same-address collisions -- two user parameters of one
                algorithm writing one cell of one memory is a broken machine.
      H = 0        one-space = 8        (and EVERY address-only rule = 8, proved)
        algo  4 FLANGER          cell 08 <- opcodes 66 68
        algo  5 PHASER           cell 06 <- opcodes 63 66
        algo 10 MULTI TAP DELAY  cell 06 <- opcodes 63 66
        algo 39 PARAMETRIC EQ    cell 06 <- opcodes 63 70
        algo 66 S.DELAY+FLANGER  cell 08 <- opcodes 68 73
        algo 72 PEQ+S.DELAY      cell 06 <- opcodes 63 73
        algo 98 PEQ+DIST+DELAY   cell 06 <- opcodes 61 63
        algo 99 PEQ+OVERDR+DELAY cell 06 <- opcodes 61 63
```

Concretely: **cell `0x06` is `VOLUME` in the D-RAM space and a filter/mix
coefficient in the C-RAM space at the same time**, in six algorithms. A
one-space reading has the volume knob clobbering a coefficient.

**THE NULL.** 4000 random permutations of the space labels over the 28 opcodes —
which preserves the label multiset and destroys the binding — reach H on **all
three** statistics **2 times in 4000** (p = 5 × 10⁻⁴). Two survivors is a
degeneracy, not a tie: they permute labels among opcodes with no site in the
discriminating subset.

**AND THE SHARPEST CONTROL IS NOT A SCORE AT ALL.** The delay-descriptor space
holds `LINE_BASE + DELAY_IN_SAMPLES` (`r3-delaydram.md`, PROVEN BY
CONSTRUCTION), so everything that reaches it must be a **time** — and the UI's
own unit column decides that, knowing nothing of the dispatcher:

```
   space D : 100 named sites,   2 carry the UI unit `ms'  =   2.0 %
   space C : 265 named sites,   2 carry the UI unit `ms'  =   0.8 %
   space S :  38 named sites,  38 carry the UI unit `ms'  = 100.0 %
```

A swap of the `S` label with either of the others inverts that. Third leg: the
evaluator. Opcode `0x67`'s is `0x03925E`, the **only** helper in the ROM that
multiplies by `0xAC44 / 0x3E8` = 44100/1000.

---

## 3. ★ The named-cell map, by space (task A)

`host_side.py regmap` prints all of it. The unit-1 rows:

```
   D-RAM      unit 1  cell 86   VOLUME x12
   C-RAM      unit 1  cell 97   REVERB TIME x12
              unit 1  cell 9E   HIGH DAMP GAIN x12
              unit 1  cell AC   ER.LEVEL x12
   DESCRIPTOR unit 1  cell 00   PRE DELAY x12
```

and this is the row that makes the point: **the reverbs' PRE DELAY lives at
descriptor cell `0x00`, a LOW address, while every other unit-1 parameter lives
at `0x86`–`0xAC`, HIGH addresses.** That is the inverted polarity, and it is what
statistic 2 above is measuring. `register-space.md` §6.2 already MEASURED
`descriptor[0x00] − descriptor[0x03] = 33568 − 32768 = 800` as the ROOM REVERB
pre-delay; the name is now attached to the cell rather than to the difference.

Unit-0, D-RAM (the six D-space opcodes plus the `0x74` block):

```
   06 VOLUME x37    07 PHASE x1     08 PHASE x5      0B DELAY L x1   0C DELAY R x1
   12 PHASE x3, MANUAL x1           13 PHASE x2      1D LFO WAVEFORM x16 (a 36-CELL BLOCK)
   50 MANUAL x2     54 MANUAL x1    5A FAST/SLOW x4  5F BASS FAST/SLOW x4
```

Unit-0, delay descriptor: `26 DELAY L ×10 / DELAY 1`, `28 DELAY R ×4 / DELAY 2 /
DELAY L`, `29 DELAY R ×2 / DELAY 3`, `2A DELAY 4 / DELAY R`, `2B 2C 2D DELAY R`.

Unit-0, C-RAM: 31 named cells, `0x00..0x19`, `0x25` and `0x90` (`REV SEND ×37`).

**The weaker direction, printed because it is weak:** three of the 64 distinct
names appear in more than one space — `DELAY L` and `DELAY R` (D and S) and
`MANUAL` (C and D). Real, not a defect: an algorithm may build a delay out of
the external line or out of an internal cell and the UI calls both `DELAY L`.
It is not counted as evidence either way.

---

## 4. ★★ Opcode `0x74` — the LFO waveform is a table, and the port auto-increments

Handler `0x03869B`, PROVEN BY CONSTRUCTION from its own code:

```
   C = *stream++                        ; the single immediate byte
   if C == 1 : len = 0x20   tables 0x01EC41 / 0x01ECA5 / 0x01ED09
   else      : len = 0x24   tables 0x01EAFA / 0x01EB67 / 0x01EBD4
   table = the one the USER VALUE (0, 1, 2) selects
   base  = *table++                     ; = 0x1D in all six
   for i in 0 .. len/4 - 1:
       cell = base + 4*i                ; 0x038764: WA = i<<2 ; IZ = WA + base
       0x038539(cell, table[4i+0])      ; address word + datum
       0x038606      (table[4i+1])      ; ** DATUM ONLY, no address word **
       0x038606      (table[4i+2])
       0x038606      (table[4i+3])
```

The six tables, values read straight off the ROM as Q0.23:

```
   0x01EAFA  36  +0.095 +0.336 +0.555 +0.735 +0.866 +0.938 +0.945 +0.888 +0.771
                 +0.601 +0.390 +0.153 -0.095 ... (3 cycles of a 12-point SINE)
   0x01EB67  36  +0.000 +0.167 +0.333 +0.500 +0.667 +0.833 +1.000 +0.833 ...  TRIANGLE
   0x01EBD4  36  +0.160 +0.566 +0.934 +1.000 x7 +0.658 +0.258 ...             SQUARE (trapezoid)
   0x01EC41  32  -0.495 ... +0.491    a monotone S-curve
   0x01ECA5  32  -0.495 ... +0.490    a ramp with a kink
   0x01ED09  32  -0.495 x13 ... +0.495 x12   a step/hold
```

### 4.1 What the live capture adds

The cold-boot capture's transfers 40–48 are **9 selects at `0x1D, 0x21, … 0x3D`,
four packets each**. Decoded with `dsp_disasm`'s packet split, **the 36 values in
emission order are byte-for-byte the ROM's SINE table, 36 of 36** — so the
cold-boot LFO waveform is *SINE, user value 0*, and the whole chain

```
   UI parameter LFO WAVEFORM -> opcode 0x74 -> ROM table 0x01EAFA
      -> 36 tag-0x15 writes -> D-RAM 0x1D..0x40
```

is MEASURED end to end. `k3-pointers.md` §217 already observed "a sine table of
period 24 at `0x1D..0x40`"; what is new is *whose* it is, that there are six of
them, that only one is resident at a time, and that the user chooses.

### 4.2 ★ The auto-increment, and the direction

`0x038606` emits five bytes: `0x0A`, three value bytes, `((v<<7)&0x80) + 0x15`.
**No address word.** Three of them follow every `0x038539`. Four values reach
four cells from one address. **|step| = 1, PROVEN BY CONSTRUCTION** — which
replaces `instruction-set.md`'s tiling argument and `register-space.md` D1's
enumeration for the *magnitude*.

Direction. `register-space.md` D1 correctly reported the tiling leaves
`{+1, −1}` and broke the tie on the algo-39 abutment. Two further legs, neither
of which reuses that:

```
   (i)  THE CLOBBER TEST     algorithms carrying an op-0x74 record : 26
        clobbered under -1 (the table would occupy 0x1A..0x3D) : 2
              algo 15 ROCK ROTARY  and  algo 53 ROTARY SPEAKER, both of which
              have a canned D-RAM write to cell 0x1B
        clobbered under +1 (0x1D..0x40)                        : 0
   (ii) SMOOTHNESS  (-1 reverses every group of four in the image)
        SINE      +1 = 5.424  -1 = 11.717   2.16x rougher
        TRIANGLE  +1 = 5.833  -1 = 10.833   1.86x
        SQUARE    +1 = 5.583  -1 = 13.495   2.42x
```

(i) is not vacuous — it has a live discriminator on one side and the sides could
have swapped. (ii) **assumes** the chip reads the wavetable in ascending address
order, and that assumption is stated rather than hidden.

---

## 5. The mode-1 split, re-tested (task B)

### 5.1 The denominator, corrected

`register-space.md` C2 measured that 5 of the 12 mode-1 frame words address a
cell the host writes and 7 do not, and computed p = 0.254 from the **65** cells
the canned streams write. But the canned streams are not every host path. Adding
the T1 targets of all six D-space opcodes **and** opcode `0x74`'s 36-cell block:

```
   canned init streams only              :  65 of 256
   + every runtime parameter path (T1)   : 101 of 256 = 0.395
   observed                              :   5 of  12 = 0.417
```

★ **The split is at chance.** Membership in the host's write set carries no
information about the mode-1 words at all. That is a **MISS against my own
prediction** and against C2's reading, and method rule 9 is why: the denominator
had to be stated and re-derived, not inherited.

The four cells `0x0F 0x8C 0x8D 0x8F` do survive the stronger test — the host
cannot reach them by any path — but so do 13 other cells in `0x00..0x1F` and 26
in `0x80..0x9F`.

### 5.2 ★ What does carry signal: position

Over the **38 distinct body images**, the class-1 **index** words (C-format
removed, and the mode-1 delay-DRAM escape removed — `dsp_disasm.is_dram`) are:

```
   428.1.0E.000 x12   400.1.0E.000 x7   612.1.0E.000 x4   604.1.0E.000 x4
   602.1.0E.000 x3    424.1.0E.000 x2   420.1.0E.000 x2   42C.1.0E.000 x1
   400.1.0E.407 x1    504.1.0E.407 x1   612.1.0F.000 x1
   position:  unit 0 cell 0E  LAST WORD OF THE IMAGE  x37
              unit 1 cell 0F  LAST WORD OF THE IMAGE  x1
```

Exactly one per image, and it is the terminator. `instruction-set.md` already
publishes *"terminator / END OF BLOCK — `class4==1 && addr8 ∈ {0E,0F}`… `addr8`
is the unit index (91/91)"*. What is new is the consequence for C2:

* the host writes `000.1.0E.000` with the value **0** in **79 of 79** unit-0
  canned streams, and writes neither `0x0E` nor `0x8E` nor `0x0F` in any of the
  12 unit-1 streams — **79 versus 0**;
* the host's own class-1 select words are all `000.1.NN.000`, i.e. the
  terminator's shape with `hi12 = 0`;
* therefore the cell the host "primes" and the register the terminator names are
  **the same register**, reached by the same instruction word through the poke
  port.

★ **So "host-primed = RAM state, never-primed = a hardware register or port" is a
false dichotomy.** `0x0E` is both. The unwritten status of `0x0F`/`0x8C`/`0x8D`/
`0x8F` says the host does not *initialise* them; it says nothing about their kind.

★ **And the +0x80 rule is rejected here.** The host's parameter cells obey
"unit 1 ⇒ bit 7" 428 of 428. That rule predicts `0x8E` for the unit-1 terminator.
**MEASURED: `0x0F`.** The unit stride in this family is **+1**. The class-1
`addr8` space is therefore not one flat cell space with a bit-7 unit bit — at
minimum it is two regions with different unit conventions.

---

## 6. ★ The host interface — what nobody had asked (task C)

### 6.1 The transport is bit-banged, and the chip talks back

```
   P7  (SFR 0x1C, P7CR = 0x78 -> bits 3..6 outputs)
      bit 3  /WR    0x0383AF assert  / 0x0383B3 release
      bit 4  /RD    0x0383B7 assert  / 0x0383BB release
      bit 5  /CS1   0x0383D1 assert  / 0x0383ED release            IC311
      bit 6  C/D    0x0383A7 -> COMMAND / 0x0383AB -> DATA  (idles at DATA)
   PE  (SFR 0x38)
      bit 6  /CS2   0x0383D6 assert  / 0x0383F2 release            IC310 = DSP2
   PH  (SFR 0x44, PHCR = 0x07, PHFC = 0x18)
      bit 0  ** READ BACK FROM THE CHIP ** 0x0383FA SET, 0x0383FD LDCF, SCC C,L
      bit 1  /RESET DSP1   bit 2  /RESET DSP2
      bit 3  ** A SECOND INPUT ** sampled once at 0x034C87
   PZ  (SFR 0x68) the 8-bit data latch: `LD (0x68),A'
```

`DSP_SEND_COMMAND` and `DSP_SEND_DATA` are one routine differing only in C/D:

```
   timeout = 0x1F40 (8000)
   repeat:
       release /RD ; release /WR ; assert /CS ; r = PH.0 ; release /CS
       if r != 0: break
       if --timeout == 0: return 1                    <-- ERROR 1, TIMEOUT
   (COMMAND only: C/D <- 0)
   release /CS ; release /RD ; assert /WR ; assert /CS
   r = PH.0
   if r == 0: return 1                                <-- ERROR 2, READY LOST
   LD (PZ),A
   release /CS ; release /WR ; (COMMAND only: C/D <- 1)
   return 0
```

★ **This is the finding the brief asked for: "a read from the chip is especially
valuable — it tells us the chip has an output register we have not modelled."**
It is one bit, it gates *every byte*, it has a bounded wait, and it has two
distinct failure modes. The MAME driver ties it to a constant 1
(`kn5000.cpp: m_subcpu->porth_read().set_constant(0x01)`), which is correct as a
stub and is **not** a model of the pin.

The consumer: `DSP_ParameterWriteEngine` tests the return and, on error, calls
`0x03CFED` — **a bare `ret`** — and abandons the record. The firmware detects a
stalled DSP and silently drops the write.

### 6.1.1 ★ The read strobe exists and is never used

Call-site census of the nine pin primitives over the whole 192 KB Sub CPU ROM:

```
   038396  /RESET DSP1 assert            1
   03839A  /RESET DSP1 release           2
   0383A7  C/D <- COMMAND                1
   0383AB  C/D <- DATA                   2
   0383AF  /WR assert                    2
   0383B3  /WR release                   6
   0383B7  ** /RD ASSERT **              0        <-- ZERO
   0383BB  /RD release                   6
   0383F7  read PH.0 (the READY line)    6
```

**`0x0383B7` — the routine that asserts /RD — has zero call sites.** Somebody
wrote a read-strobe primitive and nothing calls it. Two consequences: the chip's
byte port is bidirectional (the primitive would not exist otherwise), and *this
firmware's traffic is a pure write log* — nothing at all is read back except the
one-bit READY line.

### 6.2 The framing of every runtime parameter write

```
   DSP_DispatchCommand(0x01)    ; 0x03CA41
   DSP_DispatchData(0x01)       ; 0x03CA4D  \  the 16-bit port number 0x0160
   DSP_DispatchData(0x60)       ; 0x03CA5A  /
   <the translator: one address word + one datum, or a 36-cell block for op 0x74>
   DSP_DispatchCommand(0x03)    ; 0x03CA9B
```

which is exactly the `cmd 0x01 / 01 60 / …` shape the live capture shows and the
shape of the canned records. The framing is emitted **only when the target chip
is DSP1** (`chip = *(0x0001ED6D + unit)`), so the same engine serves both chips.

### 6.3 The command-byte census

Population: 100 canned program streams + 100 canned parameter streams, plus the
54 transfers of the live cold-boot capture.

```
   program  rec-op 3  cmd 0x01  port 0x0054  x79      <- I-RAM 84, unit-0 body
   program  rec-op 3  cmd 0x01  port 0x00C8  x12      <- I-RAM 200, unit-1 body
   program  rec-op 3  cmd 0x30  port 0x05F0  x1       <- DSP2
   program  rec-op 3  cmd 0x30  port 0x0D30  x4       <- DSP2
   program  rec-op E  cmd 0x30  port 0x0538  x4       <- DSP2
   params   rec-op 0  cmd 0x01  port 0x0160  x97
   params   rec-op 1  cmd 0x01  port 0x0160  x112
   params   rec-op 2  cmd 0x02  port 0x0161  x112
   params   rec-op 4  cmd 0x03  (no port)    x312
   params   rec-op 5  cmd 0x01  port 0x0160  x103
   params   rec-op E  cmd 0x30  ports 0x0000/001E/003C/005A/0080/00A0/00BE
   live     cmd 0x01  ports 0x0000 x3, 0x003C x1, 0x0040 x3, 0x0047 x3,
                            0x0054 x1, 0x00C8 x1, 0x0160 x31
            cmd 0x02  port 0x0161 x6
            cmd 0x04  payload FB DA 3F A0 1A  x2      (one 36-bit word, no port)
            cmd 0x09  payload 00 3C           x2
            cmd 0x0C  payload 00 55 55        x1
```

**Read as a command set:**

* `0x01` + 16-bit N — aim the write pointer at N and stream 36-bit words.
  `0x0000 0x003C 0x0040 0x0047 0x0054 0x00C8` are I-RAM word addresses
  **0 / 60 / 64 / 71 / 84 / 200** — the kernel, the epilogue, the two link words
  the host rewrites to connect a unit, and the two body entry points.
  **`0x0160` is a poke PORT, not an I-RAM address**: the same command carries
  register and D-RAM traffic there.
* `0x02` + `0x0161` — the 24-bit coefficient port (3-byte words).
* `0x03` — end of transaction, no payload.
* `0x04` / `0x09` / `0x0C` — boot-time singletons; `0x09`'s payload `00 3C` is 60,
  the epilogue's I-RAM address, which is a lead and not a decode.
* `0x30` — **not IC311.**

### 6.4 ★ The `MALFORMED` set is a second chip

> ⛔ **CORRECTED 2026-07-27** — the four `IC311 unit 0 + DSP2` rows below are
> **WRONG**. Algorithms 57–60 carry **no IC311 record at all**: their program
> stream is one op-E cmd-0x30 record and their parameter stream is four, every
> one of them command `0x30`. The chip partition is **91 / 9 / 0 / 0** and the
> IC311 population is **91**. See
> [`second-dsp-and-ready.md`](second-dsp-and-ready.md) §2; reproduce with
> `python3 dsp/tools/second_dsp.py dsp2`.

```
   algo 57 STANDARD     DSP2 ONLY (program rec-op E cmd 0x30, params rec-op E cmd 0x30)
   algo 58 PERCUSSIVE   idem      algo 59 SYMPHONIC   idem   algo 60 DEEP SPACE  idem
   algo 79 GEQ          NO IC311 PROGRAM -- program rec-op 3, cmd 0x30, port 0x05F0
   algo 88 ROOM         NO IC311 PROGRAM -- cmd 0x30, port 0x0D30
   algo 89 KARAOKE      idem      algo 90 BATH ROOM   idem   algo 91 STAGE  idem
```

`MALFORMED = {79, 88, 89, 90, 91}` in `dark_words.py`, `register_space.py`,
`lfo_ramp.py` and every other tool here. The reason those five "fail to parse" is
that `kn5000_dsp_extract.parse_stream` reads an op-3 record's bytes 1–2 as an
I-RAM address regardless of the command byte, and for a `cmd 0x30` record that
number is `0x05F0` / `0x0D30`, far past the 384-word I-RAM. **They are not
corrupt. They are DSP2 (MN19413, IC310) programs and IC311 never sees them.**

---

## 7. Controls — each shown saying NO

| # | control | what it rejects |
|---|---|---|
| **C1** | the space map vs the **best possible instruction-blind rule**, scored only on the 56 sites where they disagree | H 56/56, R2\* 44/56 — and R2\* cannot do better, because one address gets one space. Rejects by 12 sites |
| **C2** | same-space same-address collisions | one-space (= every address-only rule) 8, dispatch map 0. Rejects |
| **C3** | the UI **unit** column against the descriptor space | S 38/38 `ms`, D 2/100, C 2/265. A label swap inverts it. Rejects |
| **C4** | the clobber test for the auto-increment direction | −1 destroys a canned cell in 2 of 26 algorithms, +1 in 0. Live discriminator on one side |
| **C5** | curve membership (re-derived from `register-space.md`) | `0x178D0B` is in `CURVE_C` only; algo 16 cans selector 2. Selectors 0 and 1 would have failed |
| **C6** | the descriptor base | a non-zero base is rejected by the *capture*, not merely by the ROM array — which could have been a different array |
| **C7** | the **+0x80 unit rule** on the terminator | it predicts `0x8E` for unit 1 and the measured cell is `0x0F`. Rejects |
| **C8** | planted probes on the dispatch decoder | opcodes `0x21` and `0x66` must resolve to the **same** evaluator `0x039206` though they are different parameters; and opcode `0x79`'s offset `0x88` is **out of order**, so a decoder assuming monotone offsets would hand it `0x038F9B` instead of `0x038EF6` |
| **C9** | the evaluator immediate-size predict/check | 10 hits, **5 misses** over the 15 opcodes whose records all have one size. Reported as misses, not folded away |

---

## 8. Predict-then-check — hits and misses with equal prominence

| # | prediction, written before the check | result |
|---|---|---|
| **P1** | the dispatcher will name the address space for every opcode | **HIT.** 28 of 28, PROVEN BY CONSTRUCTION |
| **P2** | the relocation bases will turn out to matter and the cell map will shift | ★ **MISS.** They are all zero; the map does not move. A negative that removes an entire class of doubt |
| **P3** | opcode `0x67` (the `ms` opcode) will be the descriptor opcode | **HIT**, and it is the *only* one — plus a three-way agreement with the evaluator's 44100/1000 and the UI unit column |
| **P4** | the mode-1 "never primed" split will strengthen once every runtime path is added | ★ **MISS, and it is my own result that weakens.** The reachable set grows 65 → 101 and the split goes to chance (0.417 vs 0.395). The right denominator killed my own lead |
| **P5** | the never-primed cells will look like hardware ports | ★ **MISS.** `0x0E` is host-primed *and* the terminator's unit register — the dichotomy is false, so the question was mis-posed |
| **P6** | opcode `0x74` writes one cell (`0x1D`), as `register-space.md` §6.1 lists it | ★ **MISS.** It writes **36**. And that block is exactly the 9×4 burst `register-space.md` D1 used for the auto-increment argument, so the two are the same object seen from two sides |
| **P7** | the auto-increment direction would stay `{+1, −1}` degenerate without new data | ★ **PARTIAL MISS.** The *magnitude* is now forced by construction (`0x038606` has no address word) — which nobody needed new data for, only a reading of the writer. The *direction* still is not forced; it has three converging non-forcing arguments |
| **P8** | the main ROM will carry a value list naming the LFO waveforms | ★ **PARTIAL.** `SINTRISQRSAW` exists at main-CPU `0x11353C` — four 3-char entries — but it sits in the tone-editor string region, far from the effect tables at `0x0324D5`, and I could not bind it to the effect parameter. **Marked OPEN, not claimed.** The sine/triangle/square identification stands on the numbers alone |
| **P9** | the firmware never reads anything back from the DSP (the working assumption everywhere in this project) | ★ **MISS, and the most valuable one.** It reads PH.0 before **every single byte**, twice per byte, with a bounded wait and two error returns |
| **P10** | the five `MALFORMED` algorithms are a parser defect or corrupt data | ★ **MISS.** They are a *different chip*. The exclusion set has been carried by every tool in `dsp/tools` for the whole project |
| **P11** | this pass would recover some dark slots | ★ **MISS. Zero**, again. Names, spaces, values and transport — no instruction semantics |

---

## 9. What this leaves

**PROVEN BY CONSTRUCTION**

* opcode → evaluator → writer → address space, 28 of 28, enumeration printed;
* the relocation bases are zero, so `cell = T1[opcode][operand]`;
* opcode `0x74` uploads a 36- or 32-entry table from one of six ROM tables;
* the write port auto-increments with |step| = 1 (writer `0x038606`);
* the five `MALFORMED` algorithms are DSP2 programs.

**MEASURED**

* the per-space named-cell map (403 sites, 49 algorithms);
* the cold-boot LFO burst is the SINE table, 36/36;
* the terminator's unit index is `0x0E`/`0x0F`, +1 not +0x80, 37+1 of 38 images;
* the host reachable D-RAM set is 101 of 256, and the mode-1 split is at chance;
* the READY line, the two error paths, the PH.3 strap, the command census;
* SINGLE DELAY's two mirrored 9-cell blocks; PARAMETRIC EQ's 6-cell band stride.

**CONSISTENT, not forced**

* the auto-increment *direction* is +1 (three converging arguments, none forcing);
* SINGLE DELAY's cells `0x01`/`0x0A` are the reserved second cell of each
  channel block (T1-allocated, never referenced);
* command `0x09`'s payload `00 3C` = 60 = the epilogue's I-RAM address.

**OPEN**

* what PH.3 selects, and which of the config-word consumers reads bit 3;
* commands `0x04`, `0x09`, `0x0C` — one transfer each, no second sample;
* whether `SINTRISQRSAW` (main ROM `0x11353C`) is the effect LFO's value list;
* the physical identity of "C-RAM" vs "D-RAM" — this pass settles which *writer*,
  not which *memory*;
* cells `0x0F`, `0x8C`, `0x8D`, `0x8F`: unreachable from the host by any path,
  but that is now known to be uninformative about their kind.

**FALSIFIED here**

* `register-space.md` C2's inference *"host-primed = RAM state, never-primed =
  hardware register/port"* — `0x0E` is both;
* `register-space.md` C2's p = 0.254 — the denominator was the canned set;
* `register-space.md` §6.1's flat cell table — superseded, not wrong: it printed
  its own caveat and this pass discharges it;
* `register-space.md` §6.1's `0x1D LFO WAVEFORM` as a single cell — it is 36;
* `notes/kn5000-dsp-parameters.md` §6's *"the opcode → eval helper table is
  INFERRED and partially wrong; treat only 0x21, 0x24, 0x40, 0x62 and 0x63 as
  settled"* — the jump table is **not** in address order (`0x79`'s offset is
  `0x88`), which is why the order-derived table failed; read properly all 28 are
  settled;
* `action00-discriminator.md` §0-H's three SINGLE DELAY labels — `w3` (cell
  `0x00`) is `FEEDBACK L`, `w4` (cell `0x01`) is the unreferenced second cell of
  the same block, and `w6` (cell `0x02`, `+0.5000`) is **not** "the feedback".
  This closes `store-gate.md` item **J′**, which left exactly this OPEN;
* the project-wide reading of `MALFORMED = {79, 88, 89, 90, 91}` as bad data.

---

## 10. For the other agents in this round

1. **The DRAM-address matching pass.** Every descriptor cell it needs is now
   *named*: opcode `0x67` is the **only** opcode that reaches the descriptor
   space, its UI names are `PRE DELAY` / `DELAY L` / `DELAY R` / `DELAY 1..4`
   (38/38 in milliseconds), and its evaluator is
   `samples = base + ms × 44100/1000` with the `base` a 3-byte constant canned
   in the T2 record. Unit-1 uses descriptor `0x00..0x1F` (**PRE DELAY = cell
   `0x00`**), unit-0 `0x26..0x39`. `T1[0x67]` per algorithm is printed by
   `host_side.py motifs` and `register_space.py regmap`.
2. **The direction pass gets host-side evidence, and it is asymmetric.** The host
   has a **write-only** data path to the chip: writers `0x0387E6`, `0x03846C`,
   `0x038539`, `0x038922`, `0x038606`, and *nothing* reads a coefficient back.
   The single readable thing is **PH.0, one bit, a READY/ACK** — not a data path.
   ★ And the strongest form of that: the read-strobe primitive `0x0383B7`
   (`RES 4,(P7)` = assert /RD) exists and has **zero call sites in 192 KB**. The
   port is bidirectional in hardware and this firmware only ever writes.
   So any "direction" bit in the microprogram cannot be validated against a host
   read-back; the host stream is a pure write log. Also: `0x038606` proves the
   port auto-increments *on write*, which constrains any model in which the same
   port also reads.
3. **`store-gate.md` item J′ is closed** — see D1 above. Whoever owns SINGLE
   DELAY should re-label `w3`/`w4`/`w6`.
4. **`instruction-set.md` needs one sentence changed**: the terminator's `addr8`
   is the unit index, and the unit stride there is **+1** (`0x0E`/`0x0F`), which
   is *not* the +0x80 rule the parameter cells obey. They are different spaces or
   different regions, and conflating them is how `dark-words.md` §4.3's
   hypothesis (β) was framed.
5. **Everyone: stop calling `{79, 88, 89, 90, 91}` malformed.** Rename the
   constant. ~~Four more algorithms (57–60) *also* talk to DSP2 while running on
   IC311~~ — ⛔ **CORRECTED: 57–60 do NOT run on IC311 at all.** Nine algorithm
   slots are IC310's and none of them touches IC311; the IC311 population is
   **91**. Any per-algorithm statistic whose denominator is 95, 96 or 100 is
   wrong — `second-dsp-and-ready.md` §3 lists every site, and the good news is
   that **nothing has to be recomputed**: the numbers were already over the
   right set. The constant is now `DSP2_MISPARSED` throughout `dsp/tools`.
6. **Anyone modelling the host port in MAME**: `porth_read().set_constant(0x01)`
   makes the READY line unfailable. The firmware has an 8000-poll timeout and two
   error paths, and it drops parameter writes silently when they fire — which is
   a behaviour the emulator currently cannot exhibit.

---

## 11. Files

* `dsp/tools/host_side.py` — this pass's tool, ten subcommands; nine controls,
  each shown rejecting; the rule-7 rival constructed and demonstrated to lose.
* `dsp/analysis/host-side.md` — this note.
