# THE READY LINE, THE SECOND DSP, AND THE HOST-SIDE LOOSE ENDS

NEC **uPD6383GF-3BA** (Technics SX-KN5000, IC311) — and, for the first time,
Matsushita **MN19413** (IC310). Date: **2026-07-27**.
No hardware. The two dumped ROMs, the committed v1.42 sub-CPU disassembly, the
committed v10 main-CPU disassembly, and the service-manual schematic pages.

Labels: **MEASURED** / **PROVEN BY CONSTRUCTION** / **FORCED** / **CONSISTENT** /
**INFERRED** / **FALSIFIED** / **OPEN**.

Tool: [`../tools/second_dsp.py`](../tools/second_dsp.py) — **every number below
comes out of it.**

```
python3 dsp/tools/second_dsp.py ready     # TASK A  the PH.0 READY/ACK line
python3 dsp/tools/second_dsp.py dsp2      # TASK B  IC310 (MN19413), scoped
python3 dsp/tools/second_dsp.py denom     # TASK B  the contaminated denominators
python3 dsp/tools/second_dsp.py base24    # TASK C1 the two BASE24 disagreements
python3 dsp/tools/second_dsp.py darkf     # TASK C3 retire dark-words item F
python3 dsp/tools/second_dsp.py control   # every control, each shown saying NO
python3 dsp/tools/second_dsp.py all       # ~90 s

python3 dsp/verify.py                     # BYTE-MATCH OK
```

**No emulator BEHAVIOUR is changed and no disassembler is touched.** One MAME
file is edited **and every edited line is a `//` comment** — the rebuilt binary is
**byte-identical** to the one published before it (§6.1), which is a control that
could have failed and did not. Zero dark slots are recovered: every word that
trapped before still traps; the frame tally is unchanged (107 FULLY /
92 addressing-only / 86 dark, 0 of 1 536 349 frames complete). Three published
claims are **retired**, five notes are **corrected**, and the emulator comment
that was measurably wrong is fixed without its behaviour moving.

---

## 0. Result in one page

| # | statement | label |
|---|---|---|
| **A1** | ★★★ **IC311 REALLY DOES DRIVE A READY PIN AND IT REALLY DOES REACH THE SUB CPU.** Service manual p.35: IC311 **pin 8 `RDY`** → **R334 4.7 kΩ → +5D** (open drain, pulled up) **and onward as the off-sheet net `DSPRDY`**. p.33, CPU SECTION (B), IC27 **TMP94C241F**: **pin 146 = PH0**, pin 147 = PH1, pin 148 = PH2, and the DSP nets arriving on that sheet are exactly `DSPRST2 / DSPRST / DSPRDY`. The firmware names two of the three (`RES 1,(PH)` = DSP1 reset, `RES 2,(PH)` = DSP2 reset), so **PH.0 = DSPRDY by elimination**, and the drawn wire order agrees. | **MEASURED**; the pin↔bit map **FORCED** by the printed elimination |
| **A2** | ★★★ **AND THIS FIRMWARE CANNOT SEE IT. THE 8000-POLL HANDSHAKE IS VACUOUS.** The sub CPU's RESET writes **`PHCR = 0x07`**, i.e. PH.0/1/2 = **outputs**. Under the standard TLCS-900 convention (1 = output; a read of an output bit returns the **output latch**) `DSP_Read_Status` — `SET 0,(PH)` / `LDCF 0,(PH)` / `SCC C,L` — reads back the bit it just set. **READY is 1, always, whatever IC311 does.** The convention is not assumed: the **MAIN** CPU writes `PHCR = 0x09` and the only port-H bits it ever reads are 1 and 2 (`Detect_Region_Code`) — exactly the bits it left at 0. | **FORCED-IN-MODEL**, model = MAME's/TLCS-900's port semantics, corroborated by a second firmware |
| **A3** | ★★★ **THE MAME CONSTANT'S ONLY LIVE BIT IS PH.3, NOT PH.0.** `port_r<PORT_H>()` returns `(latch & PHCR) | (ext & ~PHCR)`; with `PHCR = 0x07` the `porth_read()` callback supplies **bits 3..7 only**. Evaluating the model at `ext = 0x00 / 0x01 / 0x09`: PH.0 is `1` in all three; PH.3 changes. The one consumer is `DSP_SYSTEM_INIT`'s `bit 3,(PH)` at `0x034C87`, whose **complement** becomes bit 3 of the DSP config word at RAM `0x041343`. **`set_constant(0x01)`'s bit 0 is dead code and its bit 3 is load-bearing.** | **MEASURED** |
| **A4** | ★★★ **VERDICT: NO BEHAVIOURAL CHANGE IS JUSTIFIED, AND THE COMMENT IS WRONG.** MAME's always-ready is *faithful* — but not because "the DSP asserts this line after accepting a command" and not because "the DSP1 stub accepts all register writes immediately". It is faithful because the firmware reads its own latch. Modelling IC311's RDY pin would change **nothing** unless MAME's port model changed too, and there is no measurement of the pin's protocol to model (the host stream is a pure write log — the /RD-assert primitive `0x0383B7` still has **0 call sites in 192 KB**). Method rule 6: the comment is corrected, the behaviour is not. | **FORCED** given A2/A3 |
| **B1** | ★★★ **THE CHIP PARTITION IS NINE WIDE, NOT FIVE, AND IT IS CLEAN.** An algorithm is IC310's iff any of its records carries command `0x30`. Over 100 slots × (program stream + parameter stream): **IC311 91, IC310 9, both 0, neither 0.** The nine are **57 STANDARD, 58 PERCUSSIVE, 59 SYMPHONIC, 60 DEEP SPACE, 79 GEQ, 88 ROOM, 89 KARAOKE, 90 BATH ROOM, 91 STAGE**. | **PROVEN BY CONSTRUCTION** |
| **B2** | ★★★ **`host-side.md` C5's *"algorithms 57–60 configure BOTH chips"* IS FALSE.** Algo 57's program stream is **one** op-E cmd-0x30 record and its parameter stream is **four** op-E cmd-0x30 records. There is no IC311 traffic in it. **The IC311 algorithm population is 91.** | **FALSIFIED** (`host-side.md` C5, §6.4, §10 item 5) |
| **B3** | ★★ **AND THAT EXPLAINS WHY EXACTLY FIVE "PARSE TO JUNK".** `kn5000_dsp_extract.parse_stream` handles record opcodes 3 and 2 only. The five whose cmd-0x30 rides on **op-3** (79, 88–91) parse into a phantom I-RAM block; the four whose cmd-0x30 rides on **op-E** (57–60) parse into **nothing** and are dropped silently by `if ir:`. `MALFORMED` is not a defect list — it is *the subset of DSP2 streams that survives an IC311-shaped parser*. | **PROVEN BY CONSTRUCTION** |
| **B4** | ★★★ **THE TRANSPORT IS A DIFFERENT TRANSPORT.** IC311: parallel byte port (PZ0–7 = pins 137–144 = `DSP1D0-7`), `/WR /RD /CS C/D` on P7, **READY on PH.0**, 8000-poll wait, two error returns. IC310: **3-wire bit-banged serial** — `PF.0 = DSP2DA`, `PF.2 = DSP2SCK`, `PE.6 = DSP2CS` — 8 bits MSB-first, NOP-padded, **no ready poll, no timeout, no error return, and no data-in line on the board at all**. Two independent sources agree: the firmware routines `DSP2_Send_Command`/`DSP2_Send_Data`, and the schematic's own net names. | **MEASURED** |
| **B5** | ★★★ **BUT THE RECORD FRAMING IS ONE FRAMING, AND `op-D` IS A PERFECT CHIP DISCRIMINATOR.** `op-D` occurs **34** times over the 200 canned streams; **34 of 34** immediately follow a cmd-0x30 record and **0** occur anywhere else. Its handler calls `DSP2_SPI_BusIdle` and yields — a settle marker, which is what a link with no READY bit needs instead of a handshake. op-3 and op-E emit the *same bytes* for a cmd-0x30 record (`cmd, addr_hi, addr_lo, payload`); only the host-side relocation differs. | **MEASURED** |
| **B6** | ★★★ **THE IC310 INSTRUCTION WORD IS 32 BITS.** Enumeration `w ∈ {1,2,3,4,5,6,8,12}`, three filters printed: **integrality** over 708/240/660 bytes leaves `{1,2,3,4,6,12}`; **disjointness** of the three load blocks (1336, 1520, 3376) leaves `{4,6,12}`; **period**, scored against a byte-shuffle null at the same `w` with the same multiset, puts `w = 4` at `+1.43 / +1.31 / +1.37` and `w = 3, 5` **at the null**, argmax `w = 4` in **3 of 3** images. 8 and 12 are its own multiples. | **FORCED** within the printed enumeration |
| **B7** | ★★★ **THE IC310 COEFFICIENT WORD IS 16 BITS AND THE 16-BIT FIELD IS A WORD ADDRESS.** The 8 algorithms whose parameter stream has ≥ 2 records must have consecutive records **abut**: `w = 2` in **8 of 8**, every other width in **0 of 8**. Windows: `0..114` (57–60), `128..153` (79), `160..206` (88–91) — disjoint, which is what makes the disjointness filter in B6 a constraint and not a wish. | **FORCED** within `w ∈ {1..6, 8}` |
| **B8** | ★★ **THE IC310 CORPUS, SIZED.** **3** distinct programs — 177 words @1336 (57–60), 60 @1520 (79), 165 @3376 (88–91) = **402 32-bit words / 1608 bytes**. **9** distinct parameter images = **674 16-bit words**. One program serves four presets that differ only in coefficients — exactly IC311's idiom. | **MEASURED** |
| **B9** | ★★★ **AND IC310 IS THE ONE ON THE MAIN OUTPUT PATH.** `IC303 SDO0` (the **main mix**) → IC310 `SDI` (pin 6); IC310 `SDO1`/`SDO2` → IC313 PCM69AU DAC. The **microphone** reaches IC310's own stereo ADC (`AINL` 93 / `AINR` 85) and no other digital device. IC311 is a send/return insert on IC303. So *everything you hear passes through the chip nobody has modelled*, and the KN5000's master reverb, its GEQ and its karaoke are all IC310 functions. **MAME has no device for it**; its traffic leaves on PF.0/PF.2 and is dropped. | **MEASURED** |
| **C1** | ★★★ **THE TWO `BASE24` DISAGREEMENTS ARE A FIRMWARE BUG — a stale copy-pasted constant.** The offending T2 record is **byte-identical** — `67 01 00 3f e0` — in algos 9, 67, 68, 72 (and the rest), and **8 of the 10** records carrying `BASE24 = 16352` sit on a canned base of **exactly 16350 = BASE24 − 2**. Algos 9 and 67 kept the record and moved the buffer. | **PROVEN BY CONSTRUCTION** (the byte identity) |
| **C2** | ★★★ **AND "WE MISREAD IT" IS REFUTED BY A STATISTIC NOTHING WAS FITTED TO.** Under the `+3` pairing, **7 of 11** multi-tap algorithms have **all** delay lines *exactly equal in length* and all positive; every rival offset `s ∈ {1,2,4,5,6,7}` scores **0 of 11**; shuffle null (values permuted within each algorithm, identical predicate both sides, 2000 trials) mean **0.06**, max **2**, ≥ 7 in **0 of 2000**. **Algos 9 and 67 are among the seven** — 15435/15435 and 8000/8000 — and both equalities are independent of the INFERRED `−2`. | **MEASURED**; `s = 3` re-confirmed by a route the anchor test does not use |
| **C3** | ★★★ **THE MIRROR HYPOTHESIS IS BUILT AND IT LOSES.** *"The T2 constant is right and the canned image is stale"* is evaluated by substituting `16350` into each canned block and re-running the **same** statistic: the lines then come out **15435 / 15020** and **8000 / 7800** — unequal, in both. The canned allocation is the authored one; the T2 constant is the stale artefact. | **MEASURED**, rival demonstrated losing |
| **C4** | ★★ **THE RUNTIME CONSEQUENCE, AND A UNITS BUG IN THE BRIEF.** With `delay = read − write − 2`, touching **DELAY R** adds **+415 samples (+9.41 ms)** in SINGLE DELAY and **+200 samples (+4.54 ms)** in S.DELAY+VIBRATO, permanently. The raw `BASE24 − cell` gaps are **417** and **202**. The brief quotes *"417"* and *"200"* — one with the `−2` and one without. Quote one convention. **A faithful emulator must reproduce the jump; it is not ours to fix.** | **MEASURED** |
| **C5** | ★★★ **`dark-words.md` ITEM F IS DEAD AND ITS CONSEQUENCE IS RETRACTED.** Re-scored against the round-5 FORCED rule over the full 276-word delay-DRAM corpus, `H-DIR` (`SRC 0x0B` ⟺ READ) agrees **111 of 276 = 40.2 %** — *below chance*; the inverted rule scores 59.8 %. `SRC 0x0B` sits on **both** sides (49 READ words / 50 WRITE words). The published *"99 of 276 (35.9 %) are reads"* is **reproduced exactly** (99 = the `SRC 0x0B` count) and **retracted**; the replacement is **READ 164 / WRITE 112 / trapping 0 of 276 = 59.4 %**. §10 item 1's `SRC 0x00` constraint goes with it: under the forced rule those 52 words split **29 WRITE / 23 READ**, not "all 52". | **FALSIFIED** |
| **C6** | ★ **`instruction-set.md`'s terminator sentence, corrected.** The class-1 terminator's `addr8` unit stride is **`+1`** (`0x0E`/`0x0F`, last word of 37 + 1 of the 38 distinct body images), **not** the `+0x80` the parameter cells obey 428 of 428. `host-side.md` B1/B2 asked for this and nobody had made the edit. | **MEASURED**, applied to the note |
| **D** | ★ **NOTHING IS APPLIED TO THE DEVICE OR THE DISASSEMBLERS. Zero dark slots recovered, stated first rather than buried.** | **MEASURED** |

---

## 1. TASK A — the READY line

### 1.1 The board (new data, read this pass)

Service manual p.35, IC311's right-hand pin column:

```
   pin 11 BR-RQ  -> +5D
   pin 10 RST2
   pin  9 RST
   pin  8 RDY    --+--- R334 4.7k --> +5D          (open drain, pulled up)
                   `------------------------------> DSPRDY   (off-sheet net)
   pin  7 EOFLAG   pin 6 EIFLAG   pin 5 SO   pin 4 SI   pin 3 SCK
   pin  2 /DC      pin 1 CS
```

`dsp-audiopath-wiring.md` §1.1 already recorded *"pin 8 RDY → R334 4.7k → +5D
(open-drain, pulled up)"* but stopped there. **The line does not stop there**: it
continues right and leaves the sheet as `DSPRDY`, alongside `DSPRST2`, `DSPRST`,
`DSPCD`, `DSPCS`, `DSP1 D0–D7`, `DSPRD`, `DSPWR`.

Service manual p.33, CPU SECTION (B), **IC27 TMP94C241F SUB MICROCOMPUTER**, top
edge (pin numbers read off the boxes, labels read off the rotated text):

```
   150 DVSS   149 PH3   148 PH2   147 PH1   146 PH0   145 INT0
   144..137 = PZ7..PZ0 = DSP1D7..DSP1D0     136 DVCC   135.. P40/A0 = SA0 ..
```

and the same sheet's off-sheet net list contains, in the DSP group,
`DSPRST2 / DSPRST / DSPRDY` and `DSPWR / DSPRD / DSPCS / DSPCD / SGCS / KSCS`
and `DSP2CS / DSP2SCK / DSP2DA`.

**THE ENUMERATION, printed beside the claim.** There are exactly **three** DSP
control nets on this sheet that are not the byte port, and the firmware names two
of them from its own instruction encodings:

| bit | firmware evidence | net |
|---|---|---|
| PH.1 | `DSP1_Assert_Reset` @0x038396 = `RES 1,(PH)` | `DSPRST` |
| PH.2 | `DSP2_Assert_Reset` @0x03839E = `RES 2,(PH)` | `DSPRST2` |
| PH.0 | the only bit left, and the only one that is *read* | **`DSPRDY`** |

The drawn wire order agrees independently (PH2's stub is outermost and `DSPRST2`
is the topmost horizontal; PH0's is innermost and `DSPRDY` the lowest).

> ★ **This settles the first half of the brief's question and it settles it in
> favour of the pin being real.** `host-side.md` C1 could only say "the firmware
> polls something". It polls a physical open-drain output of the uPD6383GF.

### 1.2 ★★★ And the poll is vacuous — the port direction does it

```
   SUB  CPU RESET (v142, 0x01F924)  :  PH = 0xFF   PHCR = 0x07   PHFC = 0x18
   MAIN CPU boot_hw_init            :  PH = 0x00   PHCR = 0x09   PHFC = 0x1E
```

`DSP_Read_Status` (`0x0383F7`), instruction for instruction:

```
   SET  0,(PH)      ; read-modify-write on the SFR: latch bit 0 <- 1
   LDCF 0,(PH)      ; CF <- PH bit 0
   SCC  C,L         ; L  <- CF
```

TLCS-900 port semantics, which is what MAME implements
(`tmp94c241_device::port_r<P>` = `(latch & PxCR) | (external & ~PxCR)`, `1 =
output`): a read of a bit programmed as an **output** returns the **output
latch**. `PHCR = 0x07` makes PH.0 an output. The routine sets that latch to 1 and
then samples it.

**THE CONVENTION IS NOT ASSUMED — the other CPU establishes it.** The main CPU
writes `PHCR = 0x09` (bits 0 and 3 = outputs) and the *only* port-H bits it ever
reads are **1 and 2**, in `Detect_Region_Code` (`bit 2,(PH)` / `bit 1,(PH)`, the
AREA jumpers) — exactly the two bits it left at 0. A firmware that reads inputs
and drives outputs, using the same register, on the same part.

**THE DELIBERATELY-WRONG TWIN, and it separates:**

```
   PHCR = 0x07  (as shipped)            ext=0x00 -> READY=1   ext=0x01 -> 1   ext=0xFF -> 1
   PHCR = 0x06  (PH.0 as an INPUT)      ext=0x00 -> READY=0   ext=0x01 -> 1   ext=0xFF -> 1
```

At the shipped `PHCR` the external pin is **irrelevant** — three different pin
values, one answer. At the twin it is not. So the instrument can say NO, and it
does not.

⚠ **WHAT THIS DOES NOT SETTLE, stated rather than buried.** The `SET`-then-read
idiom *is* the classic open-drain read, and a 4.7 kΩ pull-up is pointless against
a push-pull driver. Either (i) `PHCR = 0x07` is a firmware bug that the pull-up
harmlessly masks, or (ii) port H bit 0 has no output driver on this part and
`PHCR` bit 0 is a don't-care, or (iii) port H reads the pin regardless of
direction. **(i) is what MAME implements; (ii) and (iii) are not excluded, and
excluding them needs the TMP94C241 port-H specification or a board.** Under (i)
the poll is vacuous; under (ii)/(iii) it is live and the chip could stall the
host. This is the one place in Task A where a datasheet would decide something.

### 1.3 What the constant actually does

```
   constant 0x00 ->  READY (PH.0) = 1   strap (PH.3) = 0
   constant 0x01 ->  READY (PH.0) = 1   strap (PH.3) = 0     <-- as shipped
   constant 0x09 ->  READY (PH.0) = 1   strap (PH.3) = 1
```

**Bit 0 of `porth_read().set_constant(0x01)` never reaches the firmware.** The
one bit that does is **bit 3**, read exactly once, by `DSP_SYSTEM_INIT`'s
`bit 3,(PH)` at `0x034C87`, whose **complement** is stored into bit 3 of the DSP
config word at RAM `0x041343` (`0x041343 |= 8` on the zero branch). So the
constant is not inert — it is a **strap setting**, and anyone tempted to "fix the
READY line" by changing it would silently change a boot-time configuration bit.

### 1.4 What the firmware would do if READY ever deasserted

Unchanged from `host-side.md` C1/C2, re-derived here: timeout `0x1F40` = 8000
polls → return 1; a second sample at the write instant → return 1;
`DSP_ParameterWriteEngine` tests the return and calls `0x03CFED`, **a bare
`ret`** — the record is abandoned, no retry, no user-visible error. Both paths
are unreachable in this firmware for the reason in §1.2. And the DSP2 path never
reads PH.0 at all: the call-site census reproduces exactly

```
   0383B7  /RD ASSERT               0        <-- still zero call sites in 192 KB
   0383F7  read PH.0 (READY)        6        <-- all six in DSP_Send_Command / _Data
   0383BF  DSP_Select_Chip          8        <-- 6 + the two DSP2 serial routines
```

### 1.5 ★ Verdict, and the experiment

* **A behavioural change is NOT justified.** Under the port model MAME
  implements, deasserting a modelled RDY pin would change nothing (§1.2), and
  there is no measurement of the pin's protocol to model — the host stream is a
  pure write log and always has been. Method rule 6.
* **A comment correction IS justified**, because the shipped comment states a
  mechanism (*"the DSP asserts this line after accepting a command… Always ready
  since the DSP1 stub accepts all register writes immediately"*) that is
  measurably not the mechanism, and it hides that the constant's live bit is
  PH.3. See §6.
* **THE EXPERIMENT, for whoever has a board.** Pull `DSPRDY` low and select an
  effect. If effects still load, PH.0 is driven by the CPU and reading (i) is
  right — the poll is vacuous on hardware too. If the machine drops parameter
  writes or hangs at the 8000-poll timeout, the port reads the pin and
  `PHCR = 0x07` is a real firmware defect that the pull-up masks. Either outcome
  is decisive and neither needs the DSP decoded.

---

## 2. TASK B — the second DSP, scoped

### 2.1 ★★★ The partition is nine wide

Population: **100 algorithm slots × (1 program stream + 1 parameter stream)**.
Predicate: *does any record of this algorithm carry command `0x30`?*

```
   IC311 : 91        IC310 : 9        both : 0        neither : 0

   57 STANDARD   58 PERCUSSIVE   59 SYMPHONIC   60 DEEP SPACE
   79 GEQ        88 ROOM         89 KARAOKE     90 BATH ROOM    91 STAGE
```

★ **`host-side.md` C5 and §6.4 are FALSIFIED at the point that matters most for
everyone else's denominators.** They read algos 57–60 as *"IC311 unit 0 + DSP2"*.
Algo 57's program stream is one record and its parameter stream is four, and all
five carry cmd `0x30`. **There is no IC311 traffic in any of the nine.** The
IC311 algorithm population is **91**, and it always was: `PROG op-3 cmd-0x01`
occurs exactly **91** times over the 100 streams — a number `host-side.md` §6.3
printed correctly (79 + 12) and then contradicted in prose two sections later.

### 2.2 Why exactly five "parse to junk"

`kn5000_dsp_extract.parse_stream` handles record opcodes **3** and **2** only.

```
   cmd-0x30 on op-3 : 79, 88, 89, 90, 91  ->  phantom I-RAM block at word
                                              1520 / 3376, 5-byte `words'
   cmd-0x30 on op-E : 57, 58, 59, 60      ->  NOTHING; `if ir:' drops them
```

So `MALFORMED = {79, 88, 89, 90, 91}` is not a list of defects. It is *the subset
of DSP2 streams that survives an IC311-shaped parser*. **Renamed** in
`second_dsp.py` to `DSP2_MISPARSED`, with `IC310_ALGOS` for the real set of nine.
The constant is carried by 10 files in `dsp/tools` plus `dsp/verify.py`; renaming
it in all of them is a mechanical follow-up that must not change any behaviour,
and is deliberately **not** bundled into this pass.

### 2.3 The transport is a different transport

| | IC311 (uPD6383GF) | IC310 (MN19413) |
|---|---|---|
| data | **PZ0–7** (pins 137–144) = `DSP1D0-7`, parallel byte | **PF.0** = `DSP2DA`, serial |
| clock | strobed: P7.3 `/WR`, P7.4 `/RD` | **PF.2** = `DSP2SCK` |
| select | P7.5 `/CS`, P7.6 `C/D` | **PE.6** = `DSP2CS` |
| flow control | **PH.0 READY**, 8000-poll wait, 2 error returns | **none** |
| direction | bidirectional in hardware, write-only in firmware | **write-only, no data-in line exists** |
| routine | `DSP_Send_Command` 0x036331 / `DSP_Send_Data` 0x0367EE | `DSP2_Send_Command` / `DSP2_Send_Data`, 8 bits MSB-first (`bit 7,(RFP)` → set/clear PF.0 → `sll` → pulse PF.2), NOP-padded |

Two independent sources agree: the firmware routines, and the schematic's own net
names (`DSP2CS / DSP2SCK / DSP2DA`, three nets, against ten for IC311).

★ **Consequence for Task A:** the READY line is **IC311-only**. `host-side.md`
§6.1's table lists PE.6 `/CS2` in the same block as the byte-port pins, which
reads as though one parallel transport served both chips. It does not.

### 2.4 But the record framing is one framing, and `op-D` is a perfect discriminator

```
   cmd-0x30 records over the 200 canned streams : 34
   op-D records                                 : 34
      immediately after a cmd-0x30 record       : 34
      anywhere else                             : 0
```

`op-D`'s handler calls `DSP2_SPI_BusIdle` and yields — a **settle marker**, which
is exactly what a link with no READY bit needs instead of a handshake. `op-E`'s
handler sends *"the command byte, then every remaining byte verbatim"*; `op-3`'s
sends *"the command byte, a 16-bit address, then the tail"*. For a cmd-0x30
record the two emit **the same bytes**; only the host-side relocation differs.
So `cmd 0x30, addr_hi, addr_lo, payload…` is the IC310 upload framing, carried
inside the same bytecode as IC311's.

### 2.5 ★★★ The word widths

**PROGRAM.** Enumeration `w ∈ {1,2,3,4,5,6,8,12}`, three filters:

```
   (i)   INTEGRALITY over 708 / 240 / 660 bytes      survivors {1,2,3,4,6,12}
   (ii)  DISJOINTNESS of the three load blocks
         w=1   [1336,2043] [1520,1759] [3376,4035]   OVERLAP
         w=2   [1336,1689] [1520,1639] [3376,3705]   OVERLAP
         w=3   [1336,1571] [1520,1599] [3376,3595]   OVERLAP
         w=4   [1336,1512] [1520,1579] [3376,3540]   disjoint
         w=6   [1336,1453] [1520,1559] [3376,3485]   disjoint
         w=12  [1336,1394] [1520,1539] [3376,3430]   disjoint
   (iii) PERIOD, mean per-position byte entropy MINUS a byte-shuffle null at the
         same w with the same multiset (200 trials; the subtraction removes the
         sample-count bias that makes a naive entropy favour large w):
         @1336  w=2 +0.767  w=3 -0.032  w=4 +1.430  w=6 +0.671  w=12 +1.223
         @1520  w=2 +0.690  w=3 +0.181  w=4 +1.314  w=5 -0.116  w=6 +0.754
                                                     w=8 +1.012  w=12 +1.229
         @3376  w=2 +0.578  w=3 -0.043  w=4 +1.370  w=5 -0.082  w=6 +0.450
                                                                 w=12 +1.113
         argmax: w = 4 in 3 of 3
```

⇒ **32 bits**, and 8/12 are its own multiples. The KN5000 driver's standing note
*"bodies autocorrelate at lag 4, suggesting a 32-bit instruction word"* is
CONFIRMED, and the confirmation is now a measurement with a null.

**PHASE, with its miss.** 3 of 3 images end on a 4-byte word whose first byte is
`0x90`, and 2 of 3 have `e0 07 09 4x` as the penultimate word, both at offset
0 mod 4 from the payload start — so the grid is anchored at the payload start. A
*second* phase statistic (distinct values in the byte-0 column) does **not**
separate the phases for the 240-byte image (phase 2 scores *better*), and is
printed as a **MISS** rather than dropped.

**COEFFICIENTS.** The 8 algorithms whose parameter stream has ≥ 2 records must
have consecutive records **abut exactly**:

```
   w=1: 0/8    w=2: 8/8    w=3: 0/8    w=4: 0/8    w=5: 0/8    w=6: 0/8    w=8: 0/8
```

⇒ **16 bits, word-addressed.** `w = 1` — "the address is a byte address", the
reading an IC311-shaped parser would impose — is in the rival set and scores zero.

### 2.6 The IC310 corpus, sized

```
   PROGRAMS (3 distinct)
      load 1336 (0x0538)   708 B = 177 words   algos 57 58 59 60
      load 1520 (0x05F0)   240 B =  60 words   algo  79
      load 3376 (0x0D30)   660 B = 165 words   algos 88 89 90 91
      TOTAL 402 32-bit words / 1608 bytes

   COEFFICIENTS (9 distinct images, 674 16-bit words)
      57 / 58 / 59 / 60   @0+30w @30+30w @60+30w @90+25w   = 115 w each, ALL FOUR DIFFER
      79                  @128+26w                         =  26 w
      88 / 89 / 90 / 91   @160+30w @190+17w                =  47 w each, ALL FOUR DIFFER
```

One program serving four presets that differ only in coefficients is exactly
IC311's idiom (the twelve reverbs share one 133-word body).

### 2.7 ★★★ What IC310 is and does — and why it matters more than IC311

```
   MN19413, IC310, X302 = 20 MHz (IC311 has its own 25 MHz X303)
   delay DRAM IC308 = M5M418128AJ-6, 1 Mbit organised x8 (9 row + 8 col = 17 bits)
                    = a QUARTER of IC311's IC309 (M5M44260AJ-7S, 256K x 16)

   IC303 SDO0  (THE MAIN MIX) ------------------> IC310 SDI  (pin 6)
   IC310 SDO1 (pin 8, R326 470R) / SDO2 (pin 7) -> IC313 PCM69AU 18-bit DAC
   MIC -> IC312 -> IC310 AINL (93) / AINR (85)     its own stereo ADC
```

**IC311 is a send/return insert on IC303. IC310 is the master bus.** Everything
you hear passes through it; the microphone reaches no other digital device; and
the nine algorithms it owns are the master-section effects — the four REVERB
types, the GEQ, and ROOM / KARAOKE / BATH ROOM / STAGE.

**In MAME it is not emulated at all.** There is no device, and `kn5000.cpp`'s
`portz_write` forwards to `m_dsp1` only while P7.5 is low — IC310 does not touch
PZ, so its traffic is dropped on the floor. The driver's own comment
(*"DSP2 @ IC310 (MN19413) uses GPIO serial: PF.0=SDA, PF.2=SCLK, PE.6=CS2"*) is
**CONFIRMED** by this pass from two independent sources.

### 2.8 Deliberately NOT attempted

The IC310 instruction set. Scoped, not solved, per the brief. What a next pass
inherits: 402 words of 32-bit microcode in 3 images, 674 16-bit coefficient words
in 9, a load-address space reaching 3540, a byte-wide 128 Kword delay DRAM whose
8-bit width is itself unexplained, and a **write-only** host link — so there is
no read-back oracle at all, not even a READY bit. It is a *harder* target than
IC311, and it is the one carrying the audio.

---

## 3. TASK B (cont.) — which denominators are contaminated

**THE TRUE POPULATIONS.**

```
   algorithm slots                                100
   slots whose traffic is IC311's                  91
   slots whose traffic is IC310's                   9
   distinct IC311 body images                      38
   IC311 body-image words                        2974
   + kernel 60 + epilogue 23  =  corpus          3057
   without the exclusion set: 40 images, 3154 body words
      (the 180-word difference IS the two phantom images)
```

**CONTAMINATED — named so their owners can restate them:**

1. `dsp/README.md`: *"The **96** valid programs load at I-RAM 84 or I-RAM 200"* →
   **91**. `96` is the extractor's count of pointers that yielded an I-RAM block,
   which includes the five phantoms.
2. `dsp/verify.py` docstring: *"all 100, minus the 5 malformed … so all **96**
   valid programs and all ~100 effect slots are covered"* → **91** streams, 38
   distinct images, **91 of 100** slots. *The check itself is correct; only the
   prose is wrong.*
3. `isa-adjudication.md`: *"88 of **96**"*, *"80 of **96**"*, *"14 of **96**
   algorithm slots"* → the denominator is **91**.
4. `r3-delaydram.md` P5/P6 and §6: *"870 cells over **100** algorithms"*,
   *"88 of **96**"*, *"the full **96**-equation system"* → 870 cells over **91**
   algorithms; **91** equations.
5. `k3-pointers.md` §5: *"cells across **100** algorithms"* → **91**.
6. `k4-cursor.md` item G: *"across all **100** parameter streams"* — literally
   true (it scans 100) but nine carry no IC311 traffic; say *"91 IC311 parameter
   streams"*.
7. `host-side.md` C5 / §6.4 / §10 item 5: *"algorithms 57–60 configure **both**
   chips"* → **FALSIFIED**.
8. `dsp/algorithms/families.md`: *"flagged in the generator's `MALFORMED` set"* →
   rename; they are IC310 programs.

★ **NOT CONTAMINATED, and this is a MISS against my own prediction (§7 P5).**
The delay-DRAM word census is **276 either way** — the two phantom images
contribute **zero** `is_dram` words — so `dark-words.md`'s 276 and everything
derived from it stand. `programs.tsv`'s `slots` column already sums to **91**.
Every tool that filters `if ir and a not in MALFORMED` is clean; every tool that
filters on the name alone is clean **by accident**, because 57–60 parse to an
empty image. **Nothing has to be recomputed.** The damage is entirely in prose
and in one wrong claim.

---

## 4. TASK C — the loose ends

### 4.1 ★★★ The two `BASE24` disagreements: a stale copy-pasted constant

**THE CONSTANT IS THE HOUSE CONSTANT.** Every record carrying `BASE24 = 16352`,
and the cell that sits at `+3`:

```
   algo   9 SINGLE DELAY      tap 40 -> +3 cell 43 = 15935   BASE24-cell = 417   <-- DISAGREES
   algo  64 S.DELAY+CHORUS    tap 45 -> +3 cell 48 = 16350   BASE24-cell =   2
   algo  65 S.DELAY+S.DELAY   tap 42 -> +3 cell 45 = 16350   BASE24-cell =   2
   algo  66 S.DELAY+FLANGER   tap 43 -> +3 cell 46 = 16350   BASE24-cell =   2
   algo  67 S.DELAY+VIBRATO   tap 43 -> +3 cell 46 = 16150   BASE24-cell = 202   <-- DISAGREES
   algo  68 S.DELAY+PHASER    tap 41 -> +3 cell 44 = 16350   BASE24-cell =   2
   algo  70 AUTO WAH+S.DELAY  tap 41 -> +3 cell 44 = 16350   BASE24-cell =   2
   algo  72 PEQ+S.DELAY       tap 40 -> +3 cell 43 = 16350   BASE24-cell =   2
   algo  98 PEQ+DIST+DELAY    tap 40 -> +3 cell 43 = 16350   BASE24-cell =   2
   algo  99 PEQ+OVERDR+DELAY  tap 40 -> +3 cell 43 = 16350   BASE24-cell =   2
```

★ **8 of 10 sit on exactly `16350 = BASE24 − 2`, and the T2 record is
byte-identical in all of them:**

```
   67 01 00 3f e0        opcode 0x67, operand 1, BASE24 = 0x003FE0 = 16352
```

The two offenders carry a **byte-for-byte copy** of a record that is correct in
eight sibling algorithms. PROVEN BY CONSTRUCTION.

**AND "WE MISREAD IT" IS REFUTED, by a statistic nothing was fitted to.** Under
the `+3` pairing, do an algorithm's delay **lines come out equal in length**?
(A delay effect allocates equal maxima to its L/R or multi-line taps; the host
never says so and neither does the DSP.) Population: **11** algorithms with ≥ 2
op-0x67 taps.

```
   algo   9 SINGLE DELAY      [15435, 15435]                  equal
   algo  10 MULTI TAP DELAY   [-12000, -20768, 18000, 18000]  (one write, four taps)
   algo  64 S.DELAY+CHORUS    [4000, 4000]                    equal
   algo  65 S.DELAY+S.DELAY   [7000, 7000, 7000, -1259]       (4th line at +4)
   algo  66 S.DELAY+FLANGER   [8000, 8000]                    equal
   algo  67 S.DELAY+VIBRATO   [8000, 8000]                    equal
   algo  68 S.DELAY+PHASER    [-16350, 8000]                  (1st tap at +4)
   algo  70 AUTO WAH+S.DELAY  [-16350, 8000]                  (1st tap at +4)
   algo  72 PEQ+S.DELAY       [8000, 8000]                    equal
   algo  98 PEQ+DIST+DELAY    [8000, 8000]                    equal
   algo  99 PEQ+OVERDR+DELAY  [8000, 8000]                    equal

   s=+3 : 7 of 11 (equal AND all positive)
   RIVALS  s=+1: 0   s=+2: 0   s=+4: 0   s=+5: 0   s=+6: 0   s=+7: 0   (of 11)
   SHUFFLE NULL, values permuted within each algorithm, identical predicate both
   sides, 2000 trials:  mean 0.06, max 2, >= 7 in 0 of 2000
```

The four non-equal algorithms are **exactly** the four `dram-matching.md` §2
already named as `+3` exceptions. And **algos 9 and 67 are among the seven that
ARE equal** — 15435/15435 and 8000/8000 — with both equalities independent of the
INFERRED `−2` (it cancels in a difference of differences).

**THE MIRROR HYPOTHESIS, built because it could have won.** *"The T2 constant is
right and the canned image is the stale one"* — both artefacts are internally
self-consistent, so consistency cannot decide. The same statistic can:

```
   algo  9  canned [15435, 15435] equal   |  with cell 43 := 16350  [15435, 15020]  NOT equal
   algo 67  canned [8000,  8000]  equal   |  with cell 46 := 16350  [8000,  7800]   NOT equal
```

⇒ **the canned allocation is the authored one; the T2 constant is stale.**

**THE RUNTIME CONSEQUENCE, and a units bug in the brief.**

```
   effective delay = read_cell - write_cell - 2        (-2 is INFERRED, dram-matching sect.1)

   algo  9 SINGLE DELAY     BASE24 16352, canned write cell 15935
        BASE24 - cell      = 417 samples = 9.46 ms
        BASE24 - cell - 2  = 415 samples = 9.41 ms      <-- the error the user hears
        canned default     = 15435 samples = 350.000 ms  (exactly)
        implied default if the T2 constant were the base = 340.54 ms  (not round)

   algo 67 S.DELAY+VIBRATO  BASE24 16352, canned write cell 16150
        BASE24 - cell      = 202 samples = 4.58 ms
        BASE24 - cell - 2  = 200 samples = 4.54 ms      <-- the error
        canned default     = 8000 samples = 181.406 ms   (exactly 8000 samples)
        implied default if the T2 constant were the base = 176.83 ms
```

⚠ **The brief quotes *"a 417-sample gap"* for SINGLE DELAY and *"200 samples"*
for S.DELAY+VIBRATO. Those are two different conventions**: 417 is
`BASE24 − cell`; the matching quantity for algo 67 is **202**, and 200 is
`BASE24 − cell − 2`. Both notes have both numbers; the brief mixed them. Quote
one convention. (`dram-matching.md` §2 itself says *"200 samples stale"* while
its table says *"disagree by 417"* — the same mix, one paragraph apart.)

**VERDICT: a firmware inconsistency, and the machine really exhibits it.** On
real hardware, touching **DELAY R** jumps the delay by **+415 samples (9.41 ms)**
in SINGLE DELAY and **+200 samples (4.54 ms)** in S.DELAY+VIBRATO, and it never
comes back to the canned value. A faithful emulator must reproduce that. **It is
not ours to fix**, and nobody should "correct" the descriptor when the delay
model is finally wired up.

### 4.2 `instruction-set.md` — the terminator sentence

**CORRECTED IN PLACE.** The class-1 terminator's `addr8` is the unit index and
its unit stride there is **`+1`** — `0x0E` for unit 0, `0x0F` for unit 1,
measured as the last word of **37 + 1 of the 38** distinct body images — and it
is **not** the `+0x80` rule the host's *parameter cells* obey 428 of 428
(`k4-cursor.md` item G). The `+0x80` rule predicts `0x8E` and is rejected. Two
regions, two unit conventions; conflating them is how `dark-words.md` §4.3's
hypothesis (β) was framed. Evidence: `host-side.md` B1/B2, re-derived here.

### 4.3 See §5 for `dark-words.md` item F.

---

## 5. ⛔ `dark-words.md` item F is dead, and so is its consequence

Population: 38 distinct IC311 body images + kernel + epilogue = **3057** words,
of which **276** are delay-DRAM words (`dsp_disasm.is_dram`).

```
   UNDER THE ROUND-5 FORCED RULE (addr8 bit 6; 0x20/0x30 = READ, 0x60 = WRITE)
      READ 164     WRITE 112     still trapping 0     of 276      = 59.4 % reads

   H-DIR  (`SRC == 0x0B  <=>  READ')  re-scored against it
      SRC 0x0B & READ   49        SRC 0x0B & WRITE   50
      other   & READ   115        other   & WRITE    62
      agreement 111 of 276 = 40.2 %          <-- BELOW CHANCE
      the INVERTED rule 165 of 276 = 59.8 %
      over the 25 distinct word FORMS: 11 agree
```

`SRC 0x0B` sits on **both** sides of the partition — 3 READ forms and 4 WRITE
forms — which is what `dram-direction.md` B's exhaustive elimination already
implied (`SRC` reaches zero violations in **0 of 64** boolean functions, against
2 of 8 for `addr8`). One of item F's own four rows, R1's F1, is itself FALSIFIED
by round 5.

★ **THE RETRACTED NUMBER, REPRODUCED SO THE RETRACTION IS CHECKABLE.**
`dark-words.md` §6 publishes *"under it, 99 of 276 corpus delay-DRAM words
(35.9 %) are reads"*. Recomputed: **99 of 276 = 35.9 %** — exactly, because 99 is
the count of `SRC 0x0B` delay-DRAM words. The population was right; the rule that
produced the split is dead. **The replacement is 164 of 276.**

★ **AND §10 ITEM 1 GOES WITH IT.** That item leans on H-DIR calling the 52
`SRC 0x00` delay-DRAM words *all one way*. Under the forced rule they split
**29 WRITE / 23 READ**. Neither *"H-DIR calls all 52 writes"* nor *"all 52
reads"* is true, so the `SRC 0x00` question gets no third constraint from here.
It is not harmed either — it simply loses a helper it never really had.

All four sites in `dark-words.md` (result table F, §3's `DRAM-DIR` bullet, §9's
CONSISTENT list, §10 item 1) and §6 itself now carry the retirement, with the
historical text kept for the audit trail.

---

## 6. What this says to MAME, and what was and was not changed

**NOT CHANGED: any behaviour.** `porth_read().set_constant(0x01)` stays. Method
rule 6.

**THE COMMENT AT `kn5000.cpp` IS WRONG AND SHOULD READ**, in substance:

* PH.0 is `DSPRDY`, IC311 pin 8 `RDY`, **open drain with a 4.7 kΩ pull-up**
  (service manual pp. 33/35) — a real chip output, not a stub;
* the sub CPU's `PHCR = 0x07` makes PH.0 an **output**, so
  `DSP_Read_Status`'s `SET 0,(PH)` / `LDCF 0,(PH)` reads **its own latch**: the
  8000-poll wait and both error returns are unreachable, in MAME **and**, under
  the port semantics MAME implements, on the machine;
* consequently **bit 0 of this constant never reaches the firmware**. The only
  bit that does is **bit 3**, the strap `DSP_SYSTEM_INIT` samples once at
  `0x034C87` and stores complemented into the DSP config word. **Do not change
  this constant to "model READY".**

### 6.1 ★ APPLIED — and PROVED inert by a control that could have failed

The comment correction is **shipped** (`kn7000_mame`, `src/mame/matsushita/kn5000.cpp`,
commit `e773a45`), together with an expansion of the `subcpu_mem` DSP2 note.

Two independent proofs that no behaviour changed:

1. **By construction.** `git diff -U0 src/mame/matsushita/kn5000.cpp | grep -vE
   '^[+-]\s*//'` is **empty** — every added and every removed line is a `//`
   comment.
2. **By the artefact.** The rebuilt binary is **byte-identical** to the one
   published before the change — `md5 965976f50bbfa11299d1449caca7d336`,
   74 405 928 bytes, both. ★ **This control could have failed**: the edit adds 48
   lines to the middle of the file and therefore shifts `__LINE__` for everything
   after it, so any macro in `kn5000.cpp` that embeds `__LINE__` would have
   changed the object. None does.

An audio capture is *strictly weaker evidence than this* and was therefore not
taken: a bit-identical executable produces bit-identical audio by definition,
whereas a capture only samples one trajectory. Build log: 0 `error:`, binary
mtime advanced, size 74.4 MB; `tools/publish-binary.sh` run afterwards and the
published hash is unchanged.

**AND `subcpu_mem`'s DSP2 comment is confirmed, not corrected** — `PF.0 = SDA,
PF.2 = SCLK, PE.6 = CS2` is exactly what the firmware does and what the nets
`DSP2DA / DSP2SCK / DSP2CS` are called. Worth adding: **write-only, and IC310 is
the chip the whole main mix passes through** (§2.7), so its absence is a bigger
hole in the audio model than IC311's.

---

## 7. Predict-then-check — hits and misses, equal prominence

| # | prediction, written before the check | result |
|---|---|---|
| **P1** | The READY line will turn out to be unmodellable and the answer will be "leave the constant". | **HIT on the conclusion, MISS on the route.** I expected to conclude *"we don't know the protocol"*; the actual reason is much stronger — the firmware provably cannot see the pin. |
| **P2** | `porth_read().set_constant(0x01)` is what makes the poll succeed. | ★ **MISS, and it is the most useful thing in Task A.** Bit 0 of the constant is masked out by `PHCR`. The poll succeeds because the firmware sets its own latch. The constant's live bit is **PH.3**. |
| **P3** | The RDY pin will turn out to be tied off / not routed, which is why the firmware gets away with it. | ★ **MISS.** It is routed, as `DSPRDY`, to PH.0. The firmware gets away with it for an entirely different reason. |
| **P4** | The five "MALFORMED" streams and the four algorithms 57–60 form a five/four split that `host-side.md` already described. | ★ **MISS.** They form a **nine/zero** split. `host-side.md`'s "57–60 configure both chips" is false, and the IC311 population is 91. |
| **P5** | Excluding the DSP2 images will move published IC311 statistics, which is the point of Task B's contamination audit. | ★★ **MISS, and I report it as one.** The delay-DRAM census is **276 either way**; the phantoms contribute zero `is_dram` words; every tool is clean, two by design and the rest by accident. The contamination is entirely in prose. |
| **P6** | The IC310 word is 32 bits (the driver's lag-4 note). | **HIT**, and now with an enumeration and a null instead of an eyeball. |
| **P7** | The IC310 coefficient word will be 24 bits, like IC311's. | ★ **MISS.** It is **16**, forced 8 of 8 by abutment against 0 of 8 for every rival — and that is consistent with its delay DRAM being **byte-wide**. |
| **P8** | A naive per-position entropy will pick the word width. | ★ **MISS, caught by building the wrong statistic first.** It is biased toward large `w` (fewer samples per column) and preferred `w = 12` on two of three images. The shuffle null at the same `w` removes the bias exactly. |
| **P9** | The `BASE24` mismatch will be a deliberate offset (the numbers 417/202 looked like they might be a guard band). | ★ **MISS.** The offending record is **byte-identical** to the sibling records where the same constant is right. Copy-paste. |
| **P10** | The `+3` pairing might be what is wrong in those two algorithms. | ★ **MISS, and the reverse.** The two offenders are among the seven algorithms whose lines come out *exactly equal* under `+3` — the pairing is confirmed **by** them. |
| **P11** | The brief's "417" and "200" would both check out. | ★ **MISS.** They are two different conventions; the matching pair is 417/202 or 415/200. |
| **P12** | Retiring H-DIR would be a formality since round 5 already forced the field. | ★ **PARTIAL MISS.** It is worse than a formality: H-DIR is **anti-correlated** (40.2 %), and its published 99/276 consequence and its §10 item 1 `SRC 0x00` constraint both had to be retracted, not merely relabelled. |
| **P13** | This pass would recover dark slots. | ★ **MISS. Zero**, again, and stated first. |

---

## 8. Controls — each one demonstrated saying NO

| # | control | what it rejects |
|---|---|---|
| **K1** | **the port-direction twin** — the same three-instruction routine at `PHCR = 0x06` | at the shipped `PHCR` three different pin values give **one** answer; at the twin they give **two**. The instrument can fail |
| **K2** | **the constant's live bit** — the port model at `ext = 0x00 / 0x01 / 0x09` | PH.0 never moves, PH.3 does. A control that could not fail would have moved both |
| **K3** | **`op-D` scored on both sides** — 34 of 34 follow a cmd-0x30 record, **0 of 34** elsewhere, over 200 streams containing 700+ non-DSP2 records | a one-sided count would have proved nothing |
| **K4** | **the byte-shuffle null for the word width** | it is what shows `w = 3` and `w = 5` sit *at* the null (−0.12 … +0.18) while `w = 4` is +1.31 … +1.43. Without it the naive statistic prefers `w = 12`. The bias was found by building the wrong statistic first |
| **K5** | **the abutment test scored over 7 rival widths** — 6 of 7 score **zero** on the same 8 algorithms | includes `w = 1`, the byte-address reading an IC311-shaped parser would impose |
| **K6** | **the offset rivals for the line-length statistic** — `s = 1,2,4,5,6,7` all **0 of 11** against 7 of 11, plus a 2000-trial within-algorithm value permutation (multiset preserved, index relation destroyed, identical predicate both sides): mean 0.06, max 2, **0 of 2000** reach 7 | rejects "any pairing would produce equal lengths" |
| **K7** | ★ **THE MIRROR HYPOTHESIS, built specifically because it could have won** — substitute `16350` into the canned block and re-run the same statistic | the lines come out **unequal in both** algorithms. This is the control that decides §4.1 |
| **K8** | **H-DIR scored on the full 276-word corpus, not on the 4 rows it chose**, with the retracted number **reproduced first** | 4 rows cannot separate a 40 %-accurate rule from a 60 %-accurate one; 276 can. And a retraction whose number cannot be reproduced is an assertion |
| **★ K9** | ★ **A CONTROL OF MINE THAT DID NOT REJECT, printed rather than deleted.** I expected the two phantom IC310 images to contaminate the delay-DRAM census — that is *why* Task B asks for a contamination list. **Measured: 276 either way.** It is a failed discriminator between a clean and a contaminated corpus and is printed as one | nothing. That is the point |
| **★ K10** | ★ **A SECOND MISS PRINTED BESIDE ITS HIT.** The byte-0-distinctness phase statistic scores phase 2 *better* than phase 0 on the 240-byte image | the phase claim therefore rests on the `0x90` terminator anchor alone, and is filed CONSISTENT rather than forced |

---

## 9. What this leaves, and for whom

**FORCED**

* PH.0 = `DSPRDY` = IC311 pin 8, by the printed elimination over the three DSP
  control nets (§1.1);
* the READY poll cannot fail under the port model MAME implements (§1.2) —
  FORCED-IN-MODEL, with the model named and its alternatives enumerated;
* the chip partition, 91 / 9 / 0 / 0 (§2.1);
* the IC310 instruction word = 32 bits and coefficient word = 16 bits, each
  within its printed enumeration (§2.5);
* `s = +3`, re-confirmed by the equal-line-length route (§4.1).

**MEASURED**

* the board facts in §1.1 and §2.7 (service manual pp. 33, 35);
* the constant's live bit is PH.3 (§1.3);
* the transport asymmetry and `op-D`'s 34/34 (§2.3, §2.4);
* the IC310 corpus sizes (§2.6);
* the two `BASE24` gaps and their runtime effect (§4.1);
* H-DIR's 111/276 and the 164/112/0 replacement (§5).

**CONSISTENT, not forced**

* the IC310 word grid is anchored at the payload start (the `0x90` terminator in
  3 of 3; the second phase statistic fails, K10);
* `cmd 0x30`'s 16-bit field is a **word** address for programs too (forced for
  coefficients by abutment; for programs only by disjointness).

**OPEN**

* whether the real TMP94C241 port H reads the pin regardless of `PHCR` — the one
  place a datasheet or a board would decide something (§1.2's caveat);
* what PH.3 selects, and which config-word consumer reads bit 3 (inherited from
  `host-side.md`);
* IC310's instruction set, its 8-bit delay memory, its coefficient format —
  **all of it**;
* whether IC310 should be modelled at all before its ISA is known (it is on the
  main bus, so a wrong model is *audible*, which is the KN7000 failure mode).

**FALSIFIED here**

* `host-side.md` C5 / §6.4 / §10 item 5 — *"algorithms 57–60 configure both
  chips"*; the IC311 population is 91;
* `dark-words.md` item F, §3's `DRAM-DIR` bullet, §9's CONSISTENT entry, §6, and
  §10 item 1 — `H-DIR` is anti-correlated at 40.2 %, its 99/276 is retracted, its
  `SRC 0x00` constraint dissolves;
* `dsp/README.md`'s *"96 valid programs"*, `dsp/verify.py`'s docstring,
  `isa-adjudication.md`'s `/96`, `r3-delaydram.md`'s `/100` and `/96`,
  `k3-pointers.md`'s `/100` — all denominators, none of them a computation;
* the project-wide name `MALFORMED` — and, newly, the *belief that the set of
  five was the set of DSP2 algorithms*;
* my own P2, P3, P4, P5, P7, P8, P9, P10, P11 (§7).

**FOR THE OTHER AGENTS**

1. **Restate your denominator as 91**, not 95, 96 or 100 — §3 lists every site.
   Nothing needs recomputing; the numbers were already over the right set.
2. **Stop quoting `dark-words.md` §6 and §10 item 1.** They are retired in place
   with the round-5 evidence and a reproduce command.
3. **The two `BASE24` gaps are a bug in the instrument, not in our model** — do
   not "fix" the descriptor when the delay line is wired up; the discontinuity is
   the real behaviour.
4. **Do not touch `porth_read().set_constant(0x01)`.** Its live bit is PH.3.
5. **IC310 is the chip on the main bus.** Whoever plans emulation coverage should
   know that the master reverb, the GEQ, karaoke and the microphone are all on a
   device MAME does not instantiate — and that its host link is write-only, so
   the usual "capture the upload stream" instrument is the *only* one available.

---

## 10. Files

* `dsp/tools/second_dsp.py` — this pass's tool, six subcommands; ten controls,
  two of them printed **because they failed**; stdlib only.
* `dsp/analysis/second-dsp-and-ready.md` — this note.
* `dsp/instruction-set.md` — the terminator sentence, corrected in place.
* `dsp/analysis/dark-words.md` — item F, §3, §6, §9 and §10 item 1 retired in
  place, historical text kept.
* `dsp/analysis/host-side.md` — C5, §6.4 and §10 item 5 corrected in place
  (the "57–60 configure both chips" clause is FALSIFIED).
* `dsp/algorithms/families.md` — the "Excluded — malformed" section rewritten.
* `dsp/README.md`, `dsp/verify.py` — the 96 → 91 denominator, and
  `MALFORMED` → `DSP2_MISPARSED` (a deprecated alias keeps every caller working).
* `dsp/tools/{dark_words,closure_pointer,dsp_coverage,isa_adjudicate,
  r1_allpass_solve,k3_pointers,gen_dsp_disasm,register_space}.py` — the same
  rename, mechanical and behaviour-preserving.
* `dsp/tools/retraction_sweep.py` — **premises P17 (H-DIR and its 99/276) and
  P18 (the "both chips" claim and the 95/96 population) filed**, so that anyone
  who quotes either number again is caught. Both report **0 LIVE sites** after
  the corrections above.
* `kn7000_mame/src/mame/matsushita/kn5000.cpp` — comment only; the rebuilt
  binary is byte-identical (§6.1).
