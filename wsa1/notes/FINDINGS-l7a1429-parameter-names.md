# The 0x00104000 device's registers, named from the tone editor's own vocabulary

Wave 19, 2026-09-03, lane `w19/lsi-uinames`. Everything below is re-derived from
`original_ROMs/wsa1_prom_{a.ic12,b.ic13,c.ic28,d.bin}` by two committed scripts:

```
python3 notes/wsa1_toneedit_vocabulary.py --selftest    # FAILURES: 0
python3 notes/wsa1_toneedit_vocabulary.py               # the SOUND EDIT screens
python3 notes/wsa1_toneedit_vocabulary.py --nulls       # nulls 1 and 2
python3 notes/wsa1_tone_record_probe.py   --selftest    # FAILURES: 0
python3 notes/wsa1_tone_record_probe.py   --wave        # null 3
python3 notes/wsa1_tone_record_probe.py   --wavesel     # the 43 columns
python3 notes/wsa1_tone_record_probe.py   --twins       # null 4
```

This lane edited no `.s` file, and no `.s` file is an input to either script.

---

## ★ CORRECTIONS CARRIED IN, 2026-09-04

⚠ This note is wave 19.  Waves 20 and 21 closed everything it left open and overturned one
of its names.  Nothing below this heading is edited; the corrections are ADDED, here and
beside the claims they touch.  **§4's table is historical** — the current register-name table
is `FINDINGS-l7a1429-editor-pages.md` §4, and the guide's §5.3 mirrors it.

| this note says | where | what is true now | authority |
|---|---|---|---|
| `+0x0B` bits 7:6 = **`RESO MODE`**, STRONG | §2d, §4 footer | they are the MODELING top page's **`GROUP`**.  Its editor at `0xFD422B` is a five-state control that can emit only `0x00`, `0x40` and `0x80`; the factory data contains exactly those three and never `0xC0`; prom_b switches a bracket graphic on it; and the page's own legend reads `ON/OFF  GROUP  DRIVER  RESONATOR  INTERACTION`.  ★ The real `RESO MODE` is **p21/p31 bit 7** — `PAGE3/3`'s first column — which sets register `0x0000` bits 15/14 and adds one octave to that resonator's tuning | editor-pages §1a, §4e |
| `0x0240`, `0x0300`, `0x03C0`, `0x0480` are a `3!` six-way choice between `DEPTH`, `FORMANT` and `INTERACTION GAIN` | §4, §5e, §6 | **a false dilemma, and all four are resolved.**  `DEPTH` = p14 bits 0-6 → `0x0240` (STRONG).  `INTERACTION GAIN` = p19 → `0x0300` (STRONG).  `FORMANT` = p14 **bit 7**, drawn `FIX`/`MOVE`, which the packer tests at `0xFC4A09` to switch `0x00C0`'s key-follow term on or off — it is a gate, not a register.  `0x03C0`/`0x0480` are RESOLVED **NEGATIVELY**: their only input p15 is never an editor parameter (1 of 258 sender call sites passes `0x0F`, and that one is arm 1) | editor-pages §3a, §4, §4a, §4d |
| `SCALE`, the fifth column, is **not** located | §5d, §7.1 | **found.**  The column stacks as `RESO`/`SCALE`, not `TUNE`/`SCALE`: `PAGE1/3`'s five headers are `FIT`/`TING`, `MUT`/`ING`, `KEY`/`SHIFT`, `DE`/`TUNE`, `RESO`/`SCALE`.  `RESO SCALE` is drawn `OFF`/`ON` and is **bit 7 of p22 (MAIN) / p32 (SUB)**; so column 4 is `DETUNE`, not `TUNE`.  ⚠ What the packer does with that bit is still open — it reaches `R[+0x1A]`, whose writer was not found | editor-pages §5.3 |
| the bits 6:4 that gate `0x0300` are written by `0xFC4D27` and `0xFC7DE9` — retracted in §7.1, leaving the producer **UNLOCATED** | §6, §7.1, §7.2 | **located.**  Fifteen sites in seven routines write `P[+0x07]` bits 6..4, all with the idiom `and (Xrr+0x07),0xFF8F` and all downstream of one test on `Q[+0x0B] & 0xC0`.  The census that says nothing else writes the field enumerates the forms it searched, so the negative can be attacked.  §7.1's retraction of the two routines is right; §7.2 is answered | `FINDINGS-l7a1429-gate-and-keyscaling.md` §1.3, §1.6 |
| §4's count: **12 STRONG · 2 constants · 4 WEAK · 1 UNIDENTIFIED** | §0, §4 | **14 named** (12 of them PROVEN), 2 constants, 2 refused a name with a reason, 1 (`0x0000`) named only in its fields | editor-pages §4 |
| §7.1: "one hop on the CPU 1 side ... this single hop is the whole remaining job" | §7.1 | ★ **it was, and it was made.**  It did not need `(0x207C)` or `DispatchTable_FCF000`: each MODELING page's read-back order *is* the map, pinned by eight (index, parameter) pairs the per-field editors name directly.  §7.3 and §7.4 are also done — the curve lane printed the tables, and the MAME driver decodes `0x0040`/`0x0080` in its `LOG_DECODE` view | editor-pages, whole |

---

## 0. The answer in one paragraph

The route worked. **Twelve of the nineteen registers now carry a name in the
machine's own vocabulary at grade STRONG**, two more were already known to be
constants, four are WEAK and one is UNIDENTIFIED. The twelve are the tone
editor's **MAIN RESONATOR** and **SUB RESONATOR**: their `KEY SHIFT` + `TUNE`,
their `FITTING`, their `MUTING`, the resonator `P0SITI0N`, and the `SUB GAIN`
that only the sub side has. One further parameter is named at grade **PROVEN**
end to end — wave-select byte `+0x0B` is the **RESONATOR TYPE**, the 64-entry
`ORIGINAL / STRING / CYLINDER / CONE / FLARE / PLATE / MEMB / THROUGH` list —
and writing it reloads all thirty of the coefficients below from a preset,
which is the single strongest thing this note says about what the device *is*.

⚠ Two corrections are owed to files this lane does not own. See §1.

---

## 1. ⚠⚠ TWO CORRECTIONS OWED

★ **1a IS NOW CARRIED, 2026-09-03, lane `w20/lsi-regsyms`; 1b is still open.** It is written into
`prom_c/devices/dev10c_dev104_drivers.s` section 7.2(c) as an ADDED correction (the
wave-17 text is left as it was, newest last), together with two more that section's
own lines needed: the channel count is PROVEN 64 from this device's own loop bounds,
and the measured grouping is two pairs and three triples, not eight A/B pairs. 1b is
not owed to a file this lane owns, so it stays open.


### 1a. `Q` is a 43-byte WAVE-SELECT RECORD, not a tone record — GRADE PROVEN

`prom_c/devices/dev10c_dev104_drivers.s`, the ★★ WAVE 17 header, says
`Q = *(P + 0x03)  the TONE record P points at` and gives a `struct Tone104`
with offsets `+0x10..+0x28`. **Q is `WaveSelRec`**, the 43-byte record prom_d's
own converted source already documents (`u8 tail[30]` at `+0x0D..+0x2A`).

* `sub_FC6803` stores its third argument into `P[+0x03]` (`0xFC6834`). All 40 of
  its call sites pass a 43-byte object: 15 from the part record's `+0x8C+41*n`
  slot, written only by `Part_GetWaveSelectRecord`'s return (`0xFB486B`; stride
  `ld A,0x2b` = 43) or the literal `0xFE14A0` (`0xFC294D`); 16 from the staging
  image's `0x0087D2 + 0x4A1 + 150*inst + 43*idx` percussion array; 9 from
  `Part_GetPercWaveSelectRecord` / `PercInst_GetWaveSelectRecord`
  (`ld C,0x2b` at `0xFB458C` / `0xFB455A`).
* The **element-block** pointer is a *different* field of the same record,
  `+0x88`, written by `Part_GetElementBlock`'s return (`0xFB484E`, `0xFB48C1`).
  **No caller of `sub_FC6803` reads `+0x88`.**
* The hard bound: on the drawbar arm Q *is* `Table_FE14A0`, and `0xFE14CB`
  begins the ASCII `"WSA SOUND RAM S0"`. Reading that object at `+0x51` would
  land six bytes inside a bank-name string.
* The complete census of Q reads on this path is `{+0x0B} ∪ [+0x0D, +0x2A]`.
  The highest is `+0x2A` (`0xFC4842`) — the record's last byte; nothing reads
  `+0x2B` or beyond. And `[+0x0D, +0x2A]` is exactly the span
  `ToneStage_ApplyWaveSelTailPreset` overwrites (loop from `0x000D` at
  `0xFBC7D9`, bound 43 at `0xFBC7E3`).

**The wave-17 arithmetic is untouched.** Only the identity of the object the
offsets are read from changes — and that change is what made this note possible,
because the 43-byte record has a byte-per-parameter editor and the tone record
does not.

### 1b. The message class byte is `0x88 | arm`, not `0x08 | arm` — GRADE PROVEN

`ToneMsg_Dispatch` at `0xFC2612` reads `ld W,(XBC) / and W,0x08 / jrl Z,0xFC2777`:
**bit 3 SET** falls through to the WRITE table at `0xFC2754`; **bit 3 CLEAR**
goes to a second 8-arm table at `0xFC27EA` whose arms first copy the six message
bytes to CPU-2 RAM `0x00D945` and then read part-record fields — the read-back
family. prom_a builds `0x88` for writes (`ld (XIX),0x80` at `0xFD618E` then
`set 3,C` at `0xFD6191-0xFD6196`) and `0x80` for queries (`sub_FD6704`). So
arm 4 on the wire is `0x8C`.

---

## 2. The chain, and what each link is worth

```
 UI CAPTION  ->  a page handler in prom_a  ->  a tone message  ->  a byte of the
 WAVE-SELECT RECORD  ->  Dev104_PackStagingStruct  ->  a 0x00104000 register
```

### 2a. The captions are DRAWN, not merely present — GRADE PROVEN

The WSA1R has no string table. Every caption is a byte run inside a
**display-list record**, and the interpreter at `0xF31A09` executes every record
of the list it is handed (`notes/FINDINGS-ui-display-list.md`). A caption found
by walking a call site's list is therefore drawn *by that screen*; it is not
"near" it. `wsa1_toneedit_vocabulary.py` walks 401 lists and prints the 37 that
belong to SOUND EDIT.

⚠ **NULL 1 — why `strings` is the wrong instrument.** prom_b holds **2,325** runs
of ≥4 bytes drawn only from `[A-Z ]`; only **594 (25.5%)** start inside a walked
display-list text payload. **74.5% of UI-label-shaped ASCII in this image is not
a UI label.** Membership of a walked record is the discriminator.

⚠ **NULL 2 — the encoding question, with a positive control.** prom_b carries
three kana faces and two kanji faces (`notes/FINDINGS-fonts.md`), so a Japanese
screen would appear here as codes ≥ 0x7F. Of 8,957 bytes in walked caption
payloads, **384 (4.29%)** are ≥ 0x7F, over 102 lists. The tone editor's captions
are **ASCII**; the non-ASCII is mostly single-byte icon/arrow glyphs and the
sharp sign in the note-name table (§5c). No private encoding had to be decoded
for anything in this note.

The MODELING screens, verbatim from the walker (caption list → value list, the
pairing measured in prom_b `0xF5BF00-0xF5C340` as an `ld XIY / ld XIX / call
0xf417f0` triple for captions immediately followed by a `call 0xf417f4` triple
for values):

| screen | captions at | values at | value fields (RAM var, mask) |
|---|---|---|---|
| MODELING top | `0xF01F96` | — | `TONE` `DRIVER` `CONNEC`+`TION` `RESO`+`NATOR` |
| DRIVER / RESONATOR / GROUP | `0xF020AA` | `0xF0302A` | `0x2808..0x280B` (3F) through the 64 resonator names at `0xF03241` |
| DRIVER WAVEFORM | `0xF02469` | `0xF338EB` | `0x27A6` (0F) |
| **PAGE1/2 `P0SITI0N PARAMETER`** | `0xF02671` | `0xF03441` | `0x27AA`(3F), `0x27AB`(0F), `0x27A7`(bit 7 → `"FIX "/"MOVE"`), `0x27A7`(7F), `0x27A8`(7F) — **4 distinct bytes** |
| **PAGE2/2 `P0SITI0N M0VEMENT`** | `0xF02942` | `0xF03498` | `0x27A6`(FF signed), `0x27A7`(7F), `0x27A8`(7F), `0x27A8`(bit 7 → `OFF/ON`) — **3 distinct bytes** |
| **PAGE1/3** `FITTING MUTING KEY SHIFT TUNE SCALE` | `0xF02A46` | `0xF034DE` | `0x27A7`(7F) `0x27B0`(FF s) `0x27A8`(bit7) `0x27A9`(FF s) `0x27AA`(FF s) **‖** `0x27AB`(7F) `0x27B1`(FF s) `0x27AC`(bit7) `0x27AD`(FF s) `0x27AE`(FF s) — **two identical groups of five** |
| `MAIN DRIVER` / `MAIN RESONATOR` / `SUB RESONATOR` / `SUB GAIN` | `0xF02B47` | `0xF0359F` | geometry only |
| **PAGE2/3 `TOUCH DEPTH` / `FITTING MUTING SUB-GAIN`** | `0xF02D08` | `0xF035CA` | `0x27A7 0x27A8 0x27A9 0x27AA 0x27AB 0x27AC`, all FF signed — **six** |
| **`MUTING` `KEY FOLLOW` `SLOPE` `RANGE`** | `0xF02DFB` | `0xF03633` | `0x27AC`(FF s), then `0x27AA 0x27A9 0x27AB 0x27AE 0x27AD 0x27AF` (7F) **all drawn through the NOTE-NAME table at `0xF05B60`**, then `0x27B0`(FF s) — **six notes + two signed** |
| **PAGE3/3 `RESO MODE`** | `0xF02EF9` | `0xF036A3` | `0x27A7`(bit 7), `0x27A8`(bit 7) |

★ `0xF05B60` really is a note-name table: its bytes read `C-2`, `D`+sharp+`2`,
`D-2`, … with the sharp as a two-byte private-encoding glyph `88 BC`.

### 2b. A tone-edit parameter number IS a record byte offset — GRADE PROVEN

`ToneMsg_Dispatch`'s write table has two byte setters, and both compute the
destination as `base + parameter`:

| arm | routine | destination | guard |
|---|---|---|---|
| 4 | `ToneMsg_WriteWaveSelectParam` `0xFBC958` | `0x0087D2 + 0x21D + 43*((req[2]>>6)&3) + (req[2]&0x3F)` | `cp BC,0x002a` `0xFBCA49` → 43 arms |
| 2,3 | `sub_FBC39D` `0xFBC39D` | `0x0087D2 + 0xD9 + 81*element + (req[2]&0x7F)` | `cp BC,0x0050` `0xFBC5C8` → 81 arms |

For arm 4: `and W,0xc0` / `srl 0x06,W` (`0xFBC96C`, `0xFBC972`) take the element
index out of bits 7:6; `mul C,0x2b` (`0xFBC97A`) and `add XBC,0x0000021d`
(`0xFBC97F`) select that element's wave-select record; `and A,0x3f` (`0xFBC994`)
is the offset; `ld (XBC),A` (`0xFBC9A3`) stores `req[4]`.

**So the byte `0x00104000` consumes at Q[+N] is written by tone-edit parameter N
of arm 4, with no indirection in between.** All of those bytes are asserted by
`wsa1_tone_record_probe.py --selftest`.

### 2c. The CPU 1 sender, and the element bits — GRADE PROVEN

[Named 2026-10-03: `(0x2250)` is `UI_PartIndex` in `wsa1/include/wsa1_ram.inc`, 127 operands.]

prom_a `sub_FD616A` (`0xFD616A`) builds the six bytes — byte[0] `0x88`, byte[1]
the part index from `(0x2250)`, byte[2] the **parameter**, byte[3] `0x01`,
byte[4] the **value**, byte[5] a mask — and `sub_FD6917` (`0xFD6917`) ORs the arm
into byte[0] and the element into byte[2]:

| selector | bytes | effect |
|---|---|---|
| `0x00` | `84 3e 01` @`0xFD69A5` | arm 1 (300-byte part record) |
| `0x01` / `0x02` | `84 3e 02` @`0xFD69AA` (+ `8c 02 3e 80` @`0xFD69CF`) | arm 2, element 0 / 1 |
| `0x03` / `0x04` | `84 3e 03` @`0xFD69B4` (+ same) | arm 3, element 2 / 3 |
| `0x11..0x14` | `84 3e 04` @`0xFD69BE` | **arm 4, element 0** |
| `0x21..0x24` | + `8c 02 3e 40` @`0xFD69C6` | **arm 4, element 1** |
| `0x31..0x34` | + `8c 02 3e 80` @`0xFD69CF` | **arm 4, element 2** |
| `0x41..0x44` | + `8c 02 3e c0` @`0xFD69D8` | **arm 4, element 3** |

`0x00`, `0x40`, `0x80`, `0xC0` into byte[2] is exactly the `element << 6` the
receiver decodes. Every byte above was re-read from the ROM and is asserted by
`--selftest`.

⚠ **The parameter number is a `pushw` immediate at each of the 29 call sites of
`sub_FD616A`, not a table.** There is no `(screen, field) -> parameter` array
anywhere in either image, and an exhaustive search for one failed. That is why
§4's grades are STRONG rather than PROVEN.

### 2d. ★ One parameter closed end to end — GRADE PROVEN

**Wave-select byte `+0x0B` = the RESONATOR TYPE.**

* prom_a `0xFD41C2` `pushw 0x003F` (the mask), `0xFD41CA` `pushw 0x000B` (the
  parameter), `0xFD41D4` `call 0x00FD616A`, with selector `(layer<<4)|1` built at
  `0xFD41B8` and value `((u8*)0x2808)[layer-1]`, min 0 / max `0x3F`.
* prom_b's interpreter-B records at `0xF0302A`, `0xF0303B`, `0xF0304C`,
  `0xF0305D` draw **those same four RAM bytes**, mask `0x3F`, through the 64 × 8
  name table at `0xF03241`: `ORIGINAL STRING CYLINDER CONE FLARE PLATE L PLATE H
  MEMB L MEMB H THROUGH MELLOW MUTE BRIGHT MOVE RANDOM OCTAVE HARMONIC METAL
  BOTTLE … SPECIAL1 SPECIAL2`.
* On the CPU 2 side, `+0x0B` is the byte `sub_FC7481` reads for its bits 7:6, and
  it is the ONE parameter whose arm-4 case does work: `0xFBCA17` calls
  `ToneStage_ApplyWaveSelTailPreset`, which **overwrites bytes 13..42** — every
  coefficient in §4.

★★ **Choosing a resonator type reloads all thirty modelling coefficients from a
preset.** That is what a resonator-type control does, and it is measured.

⚠ prom_a `0xFD434D` sends the same parameter `0x0B` with mask `0xC0` — the top
two bits, which is the field `sub_FC7481` reads and which PAGE3/3 draws as two
bit-7 flags. `+0x0B` bits 7:6 = **`RESO MODE`**, grade STRONG.


⚠ **CORRECTED 2026-09-04: those bits are `GROUP`, not `RESO MODE`.**  The two bit-7 flags
`PAGE3/3` draws are `(0x27A7)` and `(0x27A8)`, and on that page those bytes hold **p21 and
p31**, not p11 — so they are not this field.  `0xFD434D`'s screen is the MODELING top
(dispatch code `0xC0`, screen `0xA0`), field 6, a five-state control over 0..4 that ORs
`0x40`/`0x80` into p11 for pairs of layers, and the page's legend names that column
**`GROUP`**.  The 392 melodic wave-select records carry only `{0x00, 0x40, 0x80}` and never
`0xC0` — exactly what that encoder can emit.  `RESO MODE` is a real caption; it belongs to
p21/p31 bit 7.  (`FINDINGS-l7a1429-editor-pages.md` §1a, §4e.)

### 2e. The arm-4 jump table partitions the tail — GRADE PROVEN

The 43 entries at `0xFBCA5D` collapse into case groups; `--selftest` asserts the
three that matter are each exactly one arm and that the three arms differ:

| parameters | arm | what it does |
|---|---|---|
| 0,1,2 | `0xFBC9BC` | nothing |
| 3,4 / 5,6 / 7,8 / 9,10 | `0xFBC9BF`… | `PartElement_SetEnvDescriptorPointer(part, elem, 0/1/2/3)` |
| **11** | `0xFBCA17` | the resonator type — reload the preset over 13..42 |
| **12..20** | `0xFBCA3B` | (empty case group) |
| **21..30** | `0xFBCA3E` | (empty case group) |
| **31..42** | `0xFBCA41` | (empty case group) |

Three *distinct* empty arms is the compiler's record of three source-level case
groups: **the firmware's own partition of the coefficient block.** §5 shows the
register map obeys it exactly.

---

## 3. The control that grades the method

Before naming anything, the method was tested where the answer is already known.
`wsa1_tone_record_probe.py` finds **223 melodic tone records** in prom_d by
chaining their 17-byte names (name at record offset 0, length `0x11` —
`ToneQuery_ReplyToneName` `0xFC0322`) on a legal `217 + 124*N` stride, giving
**392 element blocks and 392 wave-select records**.

★ **NULL 3.** Element-block bytes `+0x02`/`+0x03` are the pair `sub_FBC39D`'s
own arm handles together (`0xFBC405`, `0xFBC416`). Taken as a key into prom_d's
**307-entry wave catalogue** at file offset `0x46D6A`, they hit **392 of 392**.
The key space is 65,536 pairs and the catalogue covers 307, so the expected
number of hits by chance is **1.8**. The names are right, too: `E.Piano 1` →
`E.Piano 1`, `Suitcase E.P.` → `Suitcase E.P.`, `Bell Piano` element 1 →
`Bell Piano`, `Jangle Piano` element 1 → `Harpsichord 2`, `Marimba` → `Marimba`.
Four are asserted by name in the selftest.

**Element offsets `+0x02`/`+0x03` are the UI's `DRIVER WAVEFORM`.** GRADE
PROVEN. It is not a `0x00104000` parameter — it is the control that says the
whole chain reads correctly.

---

## 4. THE TABLE

`p<N>` = arm-4 tone-edit parameter N = wave-select byte `+0x0N` in hex
(`p21` = `+0x15`, `p42` = `+0x2A`). The P/R arithmetic is `sub_FC47EE` /
`sub_FC6803`; the register arithmetic is the wave-17 map.

| reg | P/R inputs | ← wave-select parameters | proposed NAME | grade |
|---|---|---|---|---|
| `0x0000` | `P[+0x07]`, `R[+0x07]` | `p21` bit 7, `p31` bit 7, sign of `p33`; bits 6:4 from an untraced writer | a mode/enable word | **UNIDENTIFIED** |
| `0x0040` | `P[+0x0A]`←`P[+0x0E]`, `P[+0x12]` | `p29` semitones, `p30` fine, `p26`/`p27` when `p25` bit 7 set | **MAIN RESONATOR `KEY SHIFT` + `TUNE`** | **STRONG** |
| `0x0080` | `P[+0x0C]`←`P[+0x10]`, `P[+0x14]` | `p41`, `p42`, `p38`/`p39` when `p37` bit 7 set | **SUB RESONATOR `KEY SHIFT` + `TUNE`** | **STRONG** |
| `0x00C0` | `R[+0x12]` `R[+0x16]` `R[+0x21]` `R[+0x0E]` `R[+0x0C]` | `p13` value, `p16` touch, `p17` movement amount (0..50), `p18` movement form | **resonator `P0SITI0N`, with its `P0SITI0N M0VEMENT`** | **STRONG** |
| `0x0100` | — | — | a constant `0x0100` | (constant) |
| `0x0140` | `Exp2Decay[v1]` | `p21` value, `p23` touch depth | **MAIN `FITTING`** | **STRONG** |
| `0x0180` | `Exp2Decay[v2]` | `p31`, `p34` | **SUB `FITTING`** | **STRONG** |
| `0x01C0` | `word(0x0400) × Exp2Rise[v1]` | `p21`, `p23` | **MAIN `FITTING`**, rise form | **STRONG** |
| `0x0200` | `word(0x0440) × Exp2Rise[v2]` | `p31`, `p34` | **SUB `FITTING`**, rise form | **STRONG** |
| `0x0240` | `R[+0x1A]` `R[+0x14]` `R[+0x18]` `R[+0x21]` | `p15`, `p33`, `p14`, movement | `word(0x0480)` scaled by `p14`+`p33` | **WEAK** |
| `0x0280` | `R[+0x10]`, `R[+0x23]` | `p33` value (0..100), `p36` touch depth | **`SUB GAIN`** | **STRONG** |
| `0x02C0` | — | — | the literal `0xFF00` | (constant) |
| `0x0300` | `ExpCurve_0_to_0x80[Q[+0x13]]` | `p19` | candidate `INTERACTION GAIN` | **WEAK** |
| `0x0340` | `Curve_FE05C9[i3]` | `p22` value, `p24` touch, `p25`–`p28` key follow | **MAIN `MUTING`** | **STRONG** |
| `0x0380` | `Curve_FE05C9[i4]` | `p32`, `p35`, `p37`–`p40` | **SUB `MUTING`** | **STRONG** |
| `0x03C0` | `Curve_FE05C9[p15]` | `p15` | candidate `FORMANT` | **WEAK** |
| `0x0400` | `Curve_FE04C9[i3]` | as `0x0340` | **MAIN `MUTING`**, second curve | **STRONG** |
| `0x0440` | `Curve_FE04C9[i4]` | as `0x0380` | **SUB `MUTING`**, second curve | **STRONG** |
| `0x0480` | `Curve_FE04C9[p15]` | `p15` | candidate `FORMANT` | **WEAK** |

**12 STRONG · 2 already-known constants · 4 WEAK · 1 UNIDENTIFIED.**
Before this pass: 2 named (both constants), 17 unidentified.

And one parameter, not a register, at **PROVEN**: `p11` = `RESONATOR TYPE`
(bits 5:0) + `RESO MODE` (bits 7:6).

---


⚠ **SUPERSEDED 2026-09-04.**  The table above is left exactly as wave 19 wrote it.  The
current register-name table is `FINDINGS-l7a1429-editor-pages.md` §4, mirrored in
`HLE-GUIDE-l7a1429.md` §5.3 — the table `notes/l7a1429_crosscheck.py` reads.  Four rows here
name the wrong thing and the closing count is out of date; see the corrections at the head of
this note.

## 5. The argument, step by step, each with its null

### 5a. `21..30` and `31..42` are one parameter set twice — STRONG

The firmware's own case groups already cut the tail there (§2e). The factory
data agrees, and this is **NULL 4**: under the map
`21→31, 22→32, 23→34, 24→35, 25→37, 26→38, 27→39, 28→40, 29→41, 30→42`, the
first column's value set is a subset of the second's with at most one extra
value in **8 of 10** cases. Over all 43 columns only **30 of the 1,806 ordered
pairs** do that, so p = 0.0166 for an arbitrary pair, p¹⁰ = 1.6e-18, and the
claimed map accounts for 8 of the 30 twins that exist in the record.

The halves are **not** the same size: `31..42` has twelve parameters, `21..30`
has ten. The two extras are `p33` and `p36` — the only asymmetric parameters.

★ **Independent confirmation from the UI.** PAGE1/3's value list draws exactly
**ten** fields in **two identical groups of five**
(`7F, FF-signed, bit-7, FF-signed, FF-signed` twice over). Ten fields, ten
parameters per half, and the same 5+5 shape. The page's own column headings are
`FITTING` `MUTING` `KEY SHIFT` `TUNE` `SCALE` and its row headings include
`MAIN RESONATOR` and `SUB RESONATOR`.

### 5b. Which half is MAIN and which is SUB — STRONG, one point of failure

`p33` and `p36` are the only inputs to register `0x0280`, whose value is
`Curve_Exp2Decay_101[clamp(R[+0x10]+R[+0x23], 0..100)]` — a **0..100** clamp
against a **101**-entry curve. `p33`'s factory values are
`{0: 9, 70: 1, 80: 2, 100: 380}`: a 0..100 control sitting at maximum in 380 of
392 records. `p36` is 0 in all 392, which is what an unused touch depth looks
like.

The tone editor has exactly one parameter belonging to one resonator and not the
other, and it is captioned on both MODELING pages: **`SUB GAIN`**
(`0xF02B84`+`0xF02B8D`; `0xF02D24`+`0xF02D4A`, column header
`FITTING MUTING SUB-GAIN` at `0xF02D2D`).

★ PAGE2/3 draws **six** FF-signed fields. Five of them are the five touch depths
this device consumes (`p23`, `p24` main; `p34`, `p35` sub; `p36` sub-gain) and
the sixth is the `SUB GAIN` value itself, which the page also captions. Six for
six.

⚠ **The point of failure:** if `SUB GAIN` were instead the main resonator's
level, MAIN and SUB swap throughout §4. Nothing else changes — the pairing, the
families and the arithmetic are all direction-blind.

### 5c. Which family is FITTING and which is MUTING — STRONG, one point of failure

Each half carries two continuous parameters with a touch depth, and exactly one
of the two also carries a four-byte key-scaling stage (`p25`–`p28`, `p37`–`p40`).
The editor likewise has two such columns and exactly one has a key follow: the
caption block at `0xF02DFB` is `MUTING` / `KEY FOLLOW` / `SLOPE` / `RANGE`. So
the key-scaled family is `MUTING` and the other is `FITTING`.

★★ **The UI confirms the key-follow decode field by field**, which is why this
is STRONG. The `MUTING KEY FOLLOW` page's value list at `0xF03633` draws **six
fields through the note-name table at `0xF05B60`** and two more as signed bytes
— and the wave-17 map says `ks(Q,o)` takes a breakpoint, a low note bound, a
high note bound and a Q5 slope, twice. Six notes and two slopes, for eight
parameters:

| field | code role | factory values (`--wavesel`) |
|---|---|---|
| `p25` | breakpoint, bit 7 disables | `{42, 54, 66, 78, 90}` — **note numbers at exact octave spacing, centred on 66** |
| `p26` | lower note bound | `{24, 36, 48, 60}` — octave spacing, max 60 |
| `p27` | upper note bound | `{60, 72, 74, 77, 84, 86, 88, 96, 108, 120}` — min 60 |
| `p28` | Q5 slope, 32 = 1.0 | 24 values in **0..32** — exactly the Q5 unit interval |

`lo ≤ 60 ≤ hi` in every record; the breakpoints are `66 ± 12k`; 66 is the same
note the `0x4280` pivot names on both devices (wave-17 §2). Three independent
things agree: the arithmetic, the data, and the fact that the UI draws those
three bytes *as note names*.

⚠ **The point of failure:** the FITTING/MUTING assignment rests on one caption —
that the key-follow block at `0xF02DFB` is headed `MUTING`. It is a drawn caption
in the same display list, not an adjacency, but it is one fact.

### 5d. `0x0040` / `0x0080` are the resonator's tuning — STRONG

`P[+0x0E] = ((s8)p29 << 8) + 2*(s8)p30` (`0xFC480B`, `0xFC4828`). The pitch
word's LSB is 1/256 semitone (`FINDINGS-prom_c-dev10c-register-meanings.md` §2),
so `<< 8` makes `p29` a **whole semitone** and `p30` a step of 2/256 semitone
≈ 0.78 cent. Factory values: `p29 ∈ {0, −12, −7}` — zero, an octave down, a
fifth down — and `p30 ∈ {0, −10}`. PAGE1/3's columns are `FITTING` `MUTING`
`KEY SHIFT` `TUNE` `SCALE`, and its per-half field shapes are
`7F, FF-signed, bit-7, FF-signed, FF-signed`: two signed bytes per half, which
is what `p29` and `p30` are. A field in semitones whose factory values are 0 and
−12 is `KEY SHIFT`; its 0.78-cent companion is `TUNE`.

⚠ `SCALE`, the fifth column, is **not** located. `p26`/`p27` do double duty —
the packer folds them into `0x0040` as a 16-bit value only when `p25`'s bit 7 is
SET, i.e. only when the MUTING key follow is off. That is a plausible home and
is **not** evidence.


⚠ **CORRECTED 2026-09-04: `SCALE` is found, and column 4 is `DETUNE`.**  The five headers
are two-line stacks — `FIT`/`TING`, `MUT`/`ING`, `KEY`/`SHIFT`, `DE`/`TUNE`, `RESO`/`SCALE` —
so reading them as five words was reading two of them in halves.  `RESO SCALE` is drawn
`OFF`/`ON ` from the 2x3 table `0xF034D8` at pixel x 208 under a header at x 210, and it is
**bit 7 of p22 / p32**: one byte carries the `MUTING` number in bits 0-6 and the `RESO SCALE`
flag in bit 7.  The `p26`/`p27` guess in the paragraph above was correctly graded *not
evidence*, and it was wrong.  (`FINDINGS-l7a1429-editor-pages.md` §3c, §5.3.)

### 5e. `0x00C0` is the resonator POSITION — STRONG

Group `12..20` has exactly seven live parameters: `p12` and `p20` are read by
nothing in the image (`p20` is the constant 100 in all 392 factory records), and
`p13`–`p19` are read. The two RESONATOR sub-pages carry, between them, exactly
**seven distinct RAM bytes** — four on `P0SITI0N PARAMETER` and three on
`P0SITI0N M0VEMENT` (§2a). Seven for seven.

Register `0x00C0` consumes four of the seven: `p13`, `p16` (its touch depth via
`LinCoef_FE0096`), and `p17`/`p18`, which are the whole of the movement term
`R[+0x21] = P[+0x28] * sine / 50`, where `P[+0x28] = clamp(p17 ± PART[+0x07],
0..50)` (`0xFC6AC2`) and `P[+0x29] = Table_FE0296[...p18...]`. `p17`'s factory
values are `{0,10,15,16,20,30,40,50}` — the code's own 0..50 range — and `p18`
has bit 7 set in 183 of 392 records, a form flag, which is the page's
`OFF`/`ON` field. **The page that modulates this register is titled `P0SITI0N
M0VEMENT`; the thing that moves is therefore the `P0SITI0N`.**

⚠ Within the group, *which* of `p13`, `p14`, `p15`, `p19` is `P0SITI0N`,
`DEPTH`, `FORMANT` and `INTERACTION GAIN` is **not** measured. `p13` is the one
`0x00C0` takes, and `0x00C0` is the one the movement modulates — that is the
whole of the argument, and it does not extend to the other three.

---

## 6. Why the remaining five stayed WEAK or UNIDENTIFIED

* **`0x0240`, `0x0300`, `0x03C0`, `0x0480`** are fed by `p14`, `p15` and `p19`,
  and the three remaining captions on the two RESONATOR sub-pages are `DEPTH`,
  `FORMANT` and `INTERACTION GAIN`. That is a 3! = six-way choice with two soft
  arguments and no measurement: `p15` is clamped to **44..96** (`0xFC4964`) and
  indexes the same `(FE05C9, FE04C9)` curve pair the two MUTING chains use — a
  note range and a **third instance** of that pair, which is what `FORMANT`
  would look like; and `p19` reaches `0x0300` as `(b << 8) | b`, one byte in
  both halves, gated off by register 0's bits 6:4 — which is what a switchable
  `GAIN` would look like. Neither is evidence. Assigning by screen order would
  be naming from position, and screen order is not record order anywhere else in
  this image.
* **`0x0000`** carries three bits this lane can source (`p21` bit 7 at
  `0xFC488B`, `p31` bit 7 at `0xFC48BD`, the sign of `p33` at `0xFC48EE`) and
  three it cannot: bits 6:4, preserved by the `& 0x0070` at `0xFC4865`, are
  written by `0xFC4D27` and `0xFC7DE9`, which nobody has decoded. Those are the
  bits that gate `0x0300`.

---


⚠ **CORRECTED 2026-09-04: none of §6 survives, and that is a result, not a loss.**  The
six-way choice was a false dilemma — `DEPTH` is p14 bits 0-6, `FORMANT` is p14 bit 7 (a gate
on `0x00C0`, not a register), `INTERACTION GAIN` is p19.  The two "soft arguments" both
pointed the right way and neither was the reason: what settled `0x0300` is that its caption
is drawn on p19's own row *and* that it is mode-gated, and what settles `0x03C0`/`0x0480` is
that **p15 has no editor field at all**, so the ROM cannot name them.  And `0x0000`'s bits
6:4 have a located producer.  See the corrections at the head of this note.

## 7. What would settle the rest

1. **One hop on the CPU 1 side.** The parameter number is a `pushw` immediate at
   each of `sub_FD616A`'s 29 call sites, and the page handler that owns a given
   call site is reached through prom_a's own dispatch — `DispatchTable_FCF000`
   (17 LE32 entries at `0xFCF000`, read by a computed call at `0xFCFE1D`) and a
   pointer run near `0xFCFD41` whose base alignment is not established
   (`FINDINGS-prom_a-fcf000-module.md` §5 says so too). **Correlate that index
   with the screen id in `(0x207C)` and the cursor in `(0x27A5)`** and every
   WEAK row in §4 becomes PROVEN, the MAIN/SUB direction stops resting on one
   asymmetry, and `SCALE` gets found. This single hop is the whole remaining job.
★★ CORRECTED 2026-09-03, and it REOPENS a question this section closed.
   `0xFC4D27` and `0xFC7DE9` write **`R[+0x07]`, not `P[+0x07]`**: both load their
   base with `lda XIX,0x00e086` (at `0xFC4C8C` / `0xFC7DB6`), which is the 37-byte
   record, not the part record. The packer then shifts that byte into bits 15:8.
   ⚠ So **the producer of the bits 6..4 that gate register `0x0300` is still
   UNLOCATED** -- naming these two routines as its writers was wrong, and any
   implementation that trusted it would look for the gate in the wrong record.

2. **`0xFC4C85-0xFC4D62` and `0xFC7DAF-0xFC7E0F`**, the writers of `P[+0x07]`
   bits 6:4. They name `0x0000` and, through its gate, `0x0300`.
3. **Print `Table_FE0296` and `LinCoef_FE0096/0116/0196/0216` as numbers.** A
   curve whose output is a time in ms, a gain in dB or a frequency ratio is a
   far narrower claim than "a curve". `Curve_Exp2Decay_101`'s 101 entries against
   `SUB GAIN`'s 0..100 is the strongest instance of that argument so far; the
   others have not been made.
4. **A MAME trace of `0x0040` and `0x0080` against a played note.** They are
   claimed to be a pitch in units of 1/256 semitone; a two-octave sweep confirms
   or kills that in one run. This lane edits no driver, so it did not.
5. **The remaining 12 arm-4 parameters, 0..10 and 12/20.** Parameters 3–10 are
   four envelope-descriptor pointer pairs; 0,1,2 and 12 and 20 do nothing that
   this image reads. Worth a line in the wave-select struct, not a register name.

---

## 8. What this note does NOT claim

* It does **not** claim `0x00104000` is the acoustic-modelling section. That
  remains the declared inference of the wave-17 header. What is added is that
  its coefficients come from the `MODELING` menu's RESONATOR pages and are
  reloaded wholesale when the user picks a resonator type — consistent with the
  reading, not proof of it, since the same records also feed `0x0010C000`.
* It does **not** name any register from arithmetic alone. Every STRONG row
  rests on a caption drawn by a walked display list *plus* a measured data path
  *plus*, in four cases, a factory-data signature.
* It does **not** name the *units* of `FITTING`, `MUTING`, `SUB GAIN`,
  `P0SITI0N` or `RESO MODE`. The names are the machine's; the physical
  quantities behind them are still unidentified.
* The `MAIN DRIVER` row of PAGE1/3 is **not** accounted for. Nothing in §4 is
  claimed to be a driver parameter.
