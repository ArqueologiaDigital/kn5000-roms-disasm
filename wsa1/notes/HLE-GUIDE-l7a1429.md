# The L7A1429 at `0x00104000`: the engine, and what an HLE must compute

Lane `w19/lsi-topology`, 2026-09-03.  Fourth companion in the wave-19 set, and the one that
puts the other three together into something a device author can build from:

| note | answers |
|---|---|
| `FINDINGS-prom_c-dev104-register-map.md` (wave 17) | **what** each of the nineteen per-channel registers is built from |
| `FINDINGS-l7a1429-write-sequencing.md` (`w19/lsi-timing`) | **when** each one is written, and how often |
| `FINDINGS-l7a1429-curve-tables.md` (`w19/lsi-curves`) | **what quantity** each ROM curve produces |
| `FINDINGS-l7a1429-parameter-names.md` (`w19/lsi-uinames`) | **what the machine calls** each register, in the tone editor's own words |
| **this note** | **what kind of engine that adds up to**, and what an emulation must compute |

Everything this note asserts on its own account is re-derived from
`original_ROMs/wsa1_prom_{b.ic13,c.ic28,d.bin}` by

```
python3 notes/dev104_topology_probe.py             # 13 sections, printed
python3 notes/dev104_topology_probe.py --selftest  # FAILURES: 0
```

which reads bytes and never a `.s` file.  Where a claim comes from another lane it is cited at
the claim, and the probe reproduces it from the ROM rather than quoting it.

---

## 0. THE ANSWER, IN ONE PARAGRAPH

The L7A1429 is a **per-channel pair of coupled linear RESONATORS** — the tone editor calls them
`MAIN RESONATOR` and `SUB RESONATOR` — each programmed with a **tuning** (`KEY SHIFT` + `TUNE`),
a **damping filter** (`MUTING`, a one-pole lowpass whose cutoff index is literally a MIDI note),
an **excitation shaping** pair (`FITTING`), and a shared **`P0SITI0N`** along the resonator that
is a log-domain *period* and can be modulated at 40.69 Hz.  A third, independently-indexed copy
of the damping filter exists in the register set and the editor has three unassigned captions
(`DEPTH`, `FORMANT`, `INTERACTION GAIN`) for it.  **It is not a sample player**: no register in
the nineteen carries an address, a length or a loop point, and the chip's own output is a 13-bit
waveform stream into the tone generator, not audio.  The physical-modelling reading is no longer
an inference about shapes — the firmware names its own vocabulary, and the vocabulary is
`STRING`, `CYLINDER`, `CONE`, `FLARE`, `PLATE`, `MEMB`.

---

## 1. THE TWO LIMITS, STATED FIRST AND LOUDLY

**1.1  What is settled about the part, and what is not.**

* **SETTLED, from the service manual**
  (`notes/DRIVER-INSIGHT-wsa1-2026-09-02.md`, TARGET 3): the decoder puts `WFICS` = `0x104000`
  on **IC3, labelled `L7A1429 MODELING LSI`**, with `NAD <- SA1` — which *is* the
  `+0 = select, +2 = data` port pair the disassembly derived.  The chip identity and the address
  decode are documented, not inferred.
* **SETTLED, from the firmware's own screens** (`FINDINGS-l7a1429-parameter-names.md`): the
  parameters this device consumes are drawn on the tone editor's MODELING pages under the names
  in §5, and one of them — wave-select byte `+0x0B`, **`RESONATOR TYPE`** — is closed end to end
  at grade PROVEN over a 64-name list containing `ORIGINAL STRING CYLINDER CONE FLARE PLATE L
  PLATE H MEMB L MEMB H THROUGH …`.
* ⚠ **STILL INFERENCE**: the internal signal path.  A vocabulary and a coefficient set are not a
  block diagram.  §3 says exactly which parts of the topology are named and which are guessed.
* ⚠ The wave-17 header still calls the whole identification a DECLARED INFERENCE.  That text
  predates both the schematic pass and the UI pass; **reported here, not edited** — it is
  another lane's file.

**1.2  "No executable payload crosses this device" is a claim about the BUS.**

The whole image holds nine `0x00104000` literals, none of them a read, and a live bus trace saw
2,642 writes and zero reads.  ⚠ **A chip with fixed on-die microcode exposing only coefficients
produces exactly this traffic**, and everything below is consistent with such a chip.  What has
changed is that the coefficients are no longer opaque — six of them have an exact closed form
(§2.2) and twelve have a name (§5) — which constrains the algorithm from outside without opening
it.

**1.3  ⚠ Felipe has no access to the hardware.**  Nothing below proposes measuring the
instrument.  Where an answer needs it, §8 says so and stops.

---

## 2. THE ARGUMENT

### 2.1  The interface constraint, which shapes everything

From the schematic (`DRIVER-INSIGHT-wsa1-2026-09-02.md` §TARGET 3):

* **IC3's output is not audio.**  It leaves on `RQWFI` and `IOWFI(0..12)` — nets `RQWFI`,
  `DWFI0..DWFI12` — into **IC4 pins 25-40**.  IC4 is `TC183C230002 TONE GENELATOR LSI`, the
  device at `0x0010C000`.  IC3 hands the tone generator **a 13-bit word on request**.  A
  faithful `l7a1429_device` is not a sound device; it is a waveform *source* that IC4 plays.
* **IC3 has four private 16-bit DRAM ports** `M1`, `M2`, `S1`, `S2` — the "SOUND RAM" of prom_a's
  `"=WSA SOUND RAM S0"` string.  The CPU never addresses that memory.
* **IC4's crystal is 33.8688 MHz = 768 × 44100**, so the pair's audio rate is 44.1 kHz.

Two consequences to hold on to:

1. **The absence of a wave-address surface is a positive result, not a gap.**  Nineteen
   per-channel registers with no address, no start, no end, no loop is not a sample player.  The
   sample player is the *other* chip.
2. **The engine's memory is on-die-addressed.**  Whatever the four DRAM banks hold — and a
   resonator's delay memory is the obvious candidate — nothing in the ROMs can seed it.

★ And the `M`/`S` naming of the DRAM ports lines up with the editor's **MAIN** and **SUB**
resonators.  ⚠ That is a *coincidence of initials* between a schematic and a screen; it is
recorded as suggestive and graded **WEAK**.

### 2.2  The coefficients have exact closed forms — PROVEN

`fold(x) = (x & 0x8000) ? 0x8000 − (x & 0x7FFF) : x + 0x8000`, the packer's own step at
`0xFC5361`, is a **sign-magnitude → offset-binary converter**, and applying it is what makes the
two coefficient tables admit any fit at all: under `fold` both are monotone over all 128 entries,
including across `FE04C9[89] = 0x8459 → [90] = 0x015E`, which the two's-complement reading sees
as a jump and which under `fold` is a step of 1554, bracketed by its neighbours' 1387 and 1655.
**The null is the two's-complement reading, which is not monotone.**  (Probe §2.)

Then, over the live band `k = 9..100`, with `g = tan(π·f_k/44100)` and `f_k = 440·2^((k−33)/12)`:

```
    fold(Curve_FE04C9)[k] = round(65536 · g/(1+g))        max |residual| = 1 count
    fold(Curve_FE05C9)[k] = round( 8192 · (1 − 1/(128g))) max |residual| = 5 counts
```

`g/(1+g)` with `g = tan(π f/fs)` is the **one-pole lowpass coefficient under the bilinear
transform**.  Independently fitted in this lane by inverting each entry for its implied cutoff
and regressing: **12.0016 index steps per octave, max residual 0.8 cents over `i = 14..90`**,
against four rival value-to-frequency maps of which the best is **50× worse** (probe §3):

| map | steps/octave | max residual |
|---|---:|---:|
| **bilinear, `f = atan((1+a)/(1−a))/π`** | **12.0016** | **0.8 cents** |
| `b0` read as `f` directly | 13.3058 | 188.5 cents |
| one-pole alpha, `−ln(1−b0)/2π` | 12.4414 | 41.6 cents |
| the word read as a POLE, `−ln|a|/2π` | 10.9995 | 1333.2 cents |
| `K` read as `f` | 11.6180 | 317.0 cents |

**The index is a MIDI note.**  Requiring `f(i) = 440·2^((i+36−69)/12)` gives an implied sample
rate of **44,091 ± 11 Hz** — 44,100 to within **0.33 cent** — and no other standard rate family
is reachable, because 32 k and 48 k would need a non-integer note offset.  ★ IC4's crystal is
768 × 44100.  A curve table's closed form and a crystal on a schematic agree to a third of a
cent by wholly independent routes.

★ **And the two tables are ONE parameter, not two.**  They imply the same prewarped cutoff `θ`
to **17.4 cents worst case** over `k = 9..100` and **3.4 cents** over `k = 9..60`; entry for
entry, `(1 − G/8192)·g = 1/128`.  So registers `0x0340`/`0x0380`/`0x03C0` are **computable** from
`0x0400`/`0x0440`/`0x0480`.  **An emulator has one degree of freedom per section there.**

> ⚠ **A RETRACTION FROM THIS LANE, kept visible.**  An earlier revision of this note and of the
> probe read `Curve_FE05C9` with the `g/(1+g)` formula too and reported "a second cutoff
> saturating at 0.045142·fs = 1990.8 Hz".  That number is an artefact of forcing the wrong
> formula on the right bytes.  The correct reading is the curve lane's, reproduced above.

### 2.3  ★★ THREE sections, by an exhaustive census — PROVEN, and this lane's own result

`Curve_FE04C9`, `Curve_FE05C9` and `Curve_Exp2Rise_128` are each cited **exactly three times in
the whole 512 KB image** (probe §9; the census is over every byte):

| index | built by | `FE04C9` → | `FE05C9` → | the Rise multiply → |
|---|---|---|---|---|
| `i3` (key-scaled) | `Dev104_PackStagingStruct` 0xFC52E3 / 0xFC52F0 | reg **0x0400** | reg **0x0340** | reg **0x01C0** (0xFC5361) |
| `i4` (key-scaled) | the same, 0xFC5459 / 0xFC5466 | reg **0x0440** | reg **0x0380** | reg **0x0200** (0xFC54D7) |
| `i5` = `clamp(Q[+0x0F], 44..96)` | `sub_FC47EE` 0xFC4989 / 0xFC4997 | `P[+0x26]` → reg **0x0480** | `P[+0x24]` → reg **0x03C0** | reg **0x0240** (0xFC4ACC) |

★ **This closes two of the four registers the curve lane had no lever on.**  Registers `0x03C0`
and `0x0480` are not "P[+0x24]/P[+0x26] copied straight through" — they are **the same two curve
tables at a third index**, computed earlier by `sub_FC47EE` (`ld (XBC+0x24),HL` at 0xFC49A4 and
`ld (XBC+0x26),HL` at 0xFC4993) and cached in the sub-record.  So they carry the curve lane's
unit: a one-pole cutoff, clamped 44..96 = **831 Hz .. 16.7 kHz**.  And `0x0240` is that section's
Rise-scaled copy, exactly as `0x01C0` is section A's.

**Two further ROM images agree, from paths that never run the packer** (probe §10, §11):

* `Dev104_LoadStageBImage`'s image at 0xFE1315 writes `Curve_FE05C9[64]` to `0x0340`, `0x0380`
  **and** `0x03C0`, and `Curve_FE04C9[64]` to `0x0400`, `0x0440` **and** `0x0480`.
* the power-on reset image at 0xFE133B uses index **74** for A and B and **84** for C — a
  different index for the third slot, exactly as `i5` is independent of `i3`/`i4`.
* ★ and 84 is the value of `p15` in **123 of 133** factory records (probe §13).  A fifth object
  agreeing with the fourth.

⚠ **THIS CORRECTS THE WAVE-17 STRUCTURAL CLAIM.**  Its header says "sixteen of the nineteen
registers fall into eight A/B pairs" and lists five pairs (ten registers).  The measured grouping
is **two A/B pairs and three A/B/C triples**:

```
   pair    0x0040  0x0080                       MAIN / SUB tuning
   pair    0x0140  0x0180                       MAIN / SUB FITTING, decay form
   triple  0x01C0  0x0200  0x0240               three Rise-scaled coefficients
   triple  0x0340  0x0380  0x03C0               three FE05C9 coefficients
   triple  0x0400  0x0440  0x0480               three FE04C9 coefficients
   alone   0x0000  0x00C0  0x0100  0x0280  0x02C0  0x0300
```

4 + 9 + 6 = 19.  ⚠ Reported, not edited.

### 2.4  The pairing is real in the CODE — PROVEN, with a null

For each claimed pair the two code runs are compared byte for byte, the run length being the
distance between the two anchors.  The null slides the second run over 122 nearby offsets
(probe §5):

| pair | run length | aligned agreement | null mean | null max |
|---|---:|---:|---:|---:|
| reg 0x0040 / 0x0080 | 175 | **0.9771** | 0.0351 | 0.2000 |
| reg 0x0140 / 0x0180 | 189 | **0.9101** | 0.0274 | 0.0741 |
| reg 0x0340+0x0400+0x01C0 / 0x0380+0x0440+0x0200 | 374 | **0.9652** | 0.0264 | 0.0588 |

### 2.5  ★★ The pairing is real in the DATA too — this lane's own result, with a null

Over **133 melodic wave-select records** whose framing self-checks (probe §13 — a deliberately
conservative subset on which five of the parameter-names lane's published invariants hold
exactly), the ten twinned parameters are **equal per record**:

```
   p21==p31 133/133   p22==p32 133/133   p23==p34 131/133   p24==p35 133/133
   p25==p37 131/133   p26==p38 131/133   p27==p39 131/133   p28==p40 133/133
   p29==p41 130/133   p30==p42 133/133
```

⚠ **THE NULL.**  Over all 43 × 42 ordered column pairs of the record, with the six constant
columns excluded, **28** reach ≥130/133 — and **16 of those 28 are the claimed map's own ordered
forms** (the other four involve constant columns and are excluded by construction).  Every one of
the remaining 12 lies inside `{p3, p5, p7, p9}`, the four envelope-descriptor parameters, which
the firmware's own case table treats as a separate group (`0xFBC9BF`).  **There is no other
cross-half twinning in the record.**

★ And the fact itself matters for an HLE: **the factory tones drive MAIN and SUB identically.**
The two resonators differ only through `SUB GAIN` (`p33` = 100 in 131 of 133) and, in three
records, a −12 semitone `SUB KEY SHIFT`.  They are a matched pair, not two independent voices.

### 2.6  The pairs are NOT "two elements per voice" — PROVEN

`Pack104_SetInputs_SubRecordPair(n, m)` selects one of the part record's four 42-byte
sub-records.  `MidiNote_OnTail` passes the **literal 0** (`0b 00 00` at 0xFB36F2).  The three
`MidiNote_OnByPartMode` sites push the **register HL** (`0x2b`), whose low byte is a loop counter
bounded by `cp L,4` (`cf dc`, 0xFB3A8A) and `cp L,2` (`cf da`, 0xFB3BA3), and each iteration
re-reads a **different channel byte** from a local array (0xFB3A28).  A four-element tone
occupies **four channels**, each with its own full 19-register set.  Element multiplicity is
already spent on channels; MAIN/SUB lives *inside one channel*.  (Probe §6.)

### 2.7  ★★ Two lanes, two methods, no contact, one answer

This is the strongest single thing in the wave-19 set and it deserves to be stated plainly.

| register | the CURVE lane found, from ROM numbers alone | the UI lane found, from drawn captions alone |
|---|---|---|
| `0x00C0` | a **log-domain time** at 1/256 semitone per count, with the played pitch entering **negated** — slope exactly −1 against key, i.e. a **PERIOD** | the resonator **`P0SITI0N`**, with its **`P0SITI0N M0VEMENT`** page |
| `0x0400` / `0x0440` | a **one-pole lowpass cutoff**, index = MIDI note − 36 | **`MUTING`**, the column with a `KEY FOLLOW` / `SLOPE` / `RANGE` sub-page |

In a resonator, an excitation or pickup **position along the medium is a delay-tap time**, and it
scales with the pitch period — which is exactly a slope of −1 against key.  And **muting a string
or a bore is damping**, which is modelled by a one-pole lowpass in the loop.  Neither lane could
see the other's evidence.  ★ **A slope of exactly −1 against key is the single strongest
discriminator available**: a filter envelope's time may track the key partially, a delay-tap
position *must* track it exactly.

---

## 3. THE TOPOLOGY, AND WHAT IS STILL GUESSED

> **PRIMARY, graded STRONG.  Per channel: two resonators, `MAIN` and `SUB`, each with its own
> tuning offset, damping filter and excitation shaping; one shared modulable position along the
> resonator; and a mix level for the sub side.  A third instance of the damping-filter
> coefficient pair exists in the registers with a fixed, tone-specified index.**

What is named and what is not:

| element of the model | register(s) | status |
|---|---|---|
| resonator **tuning** | `0x0040` / `0x0080` | **named** `KEY SHIFT` + `TUNE`, STRONG |
| resonator **damping** | `0x0340`+`0x0400` / `0x0380`+`0x0440` | **named** `MUTING`, STRONG; and *fitted* as a one-pole cutoff, PROVEN |
| **excitation shaping** | `0x0140`+`0x01C0` / `0x0180`+`0x0200` | **named** `FITTING`, STRONG |
| **position** along the resonator | `0x00C0` (+ its companion `0x0100`) | **named** `P0SITI0N`, STRONG; a log period, STRONG; **absolute scale UNIDENTIFIED** |
| **sub mix** | `0x0280` | **named** `SUB GAIN`, STRONG |
| the **third** coefficient instance | `0x03C0` + `0x0480` + `0x0240` | structure PROVEN (§2.3); the editor's three unassigned captions are `DEPTH`, `FORMANT`, `INTERACTION GAIN` — **WEAK**, a 3! choice with no measurement |
| a **mode / enable** word | `0x0000` | **UNIDENTIFIED** |
| the **coupling** between MAIN and SUB | — | **not located.**  `INTERACTION GAIN` is a caption looking for a register |
| the **excitation source** | — | **not on this device.**  The editor's `DRIVER` pages select a waveform out of prom_d's wave catalogue (`DRIVER WAVEFORM`, element bytes +0x02/+0x03, PROVEN by the UI lane) — so the driver is a *sample*, and this chip is the resonator it is fed into |
| **series or parallel**; whether `MUTING`'s two coefficients are two cascaded poles or one biquad | — | **not decided** |

### 3.1  ★ A correction this lane owes to its own earlier draft

An earlier revision of this note argued that the physical-modelling reading should stay WEAK
*because there is no nonlinearity anywhere in the nineteen registers*.  **That argument was
wrong and is withdrawn.**  A struck or plucked resonator — a string, a plate, a membrane, a bore
excited by a stored waveform — is **entirely linear**: an excitation, a delay whose length is the
period, a loss filter, a gain.  Only bowed and blown models need a nonlinearity in the loop.  The
editor's own `DRIVER` / `RESONATOR` split says the excitation is a *sample*, so the absence of a
nonlinearity is exactly what this architecture predicts, not evidence against it.

### 3.2  The alternative, and what discriminates

The surviving alternative is **a conventional subtractive voice**: three one-pole lowpass filters
with key-follow and filter envelopes is also what a VCF chain looks like, and `0x00C0` would then
be an envelope *time* rather than a position.

What discriminates, in order of strength:

1. `0x00C0`'s slope against key is **exactly −1** (§2.7).  A filter-envelope time has no reason
   to be exactly inverse in frequency; a delay-tap position must be.
2. The editor's own 64-name family list is `STRING / CYLINDER / CONE / FLARE / PLATE / MEMB` —
   physical media, not filter shapes.
3. `0x0140`/`0x0180` and `0x01C0`/`0x0200` are captioned **`FITTING`**, a word about how an
   exciter meets a body, not about a filter.
4. IC3 has four private DRAM banks and produces a waveform stream, not audio (§2.1).

⚠ None of the four is a measurement of the internal path.  **The topology stays an inference;
what changed is that it is now an inference in the manufacturer's own vocabulary.**

### 3.3  ⚠⚠ TWO POINTS OF FAILURE, carried over and not smoothed away

The parameter-names lane states both, and they must travel with every name in §5.

* **The MAIN/SUB direction rests solely on `SUB GAIN` being the sub side's level.**  If it is the
  main side's, **every MAIN and SUB label in §5 swaps**.  Nothing else changes — the pairing, the
  families and the arithmetic are direction-blind.
* **The FITTING/MUTING assignment rests solely on one drawn caption** — that the key-follow block
  at `0xF02DFB` is headed `MUTING`.  If that is wrong, **a whole column of names swaps**.

Each is one fact from a drawn caption rather than from adjacency.  One fact is one fact.

### 3.4  ★ RESONATOR TYPE is a UI preset selector, and the chip never sees it

Writing wave-select byte `+0x0B` calls `ToneStage_ApplyWaveSelTailPreset`, which **overwrites
bytes 13..42** — every coefficient in §5 — from a preset.  And in the factory set the byte reads
`ORIGINAL` in **133 of 133** clean melodic records (probe §13; 455 of 459 under a looser framing
that admits some mis-framed records).  `ORIGINAL` is "no family — these are the record's own
coefficients".

> **An emulator must implement the COEFFICIENTS, not the FAMILIES.**  There is no
> `if (type == CYLINDER)` anywhere to write: the family list exists only to bulk-load thirty
> bytes, and the factory tones have all been edited past it.

---

## 4. THE `srl 0x00,XIY` ADJUDICATION — SETTLED, and not by plausibility

Three registers (`0x01C0`, `0x0200`, `0x0240`) come from `call Multiply32 / srl 0x00,XIY /
ld (struct+d),IY`.  If the TLCS-900 rule that a shift count of 0 means 16 holds, the register is
the product's **HIGH** half; otherwise its **LOW** half.

### 4.1  The settling argument: the ROM already contains the answer

`Dev104_StagingStruct_ResetImage` at **0xFE133B** is the 19-word constant the power-on sweep
copies into the same staging struct the packer otherwise computes.  Its words 7, 8 and 9 are the
three `srl` products.  Solving each for the `Curve_Exp2Rise_128` index that reproduces it, under
both readings (probe §11):

| word | register | value | HIGH half | LOW half |
|---|---|---|---|---|
| 7 | 0x01C0 | 0x1C54 | `Rise[45]`, from `FE04C9[74]` | **no solution, from any of 128** |
| 8 | 0x0200 | 0x1C54 | `Rise[45]`, from `FE04C9[74]` | **no solution** |
| 9 | 0x0240 | 0x26D7 | `Rise[32]`, from `FE04C9[84]`, then `&0xFFF8 \| 7` | **no solution** |

And the `FE04C9` indices are **the image's own**: words 16/17 are `FE04C9[74]` (registers
0x0400/0x0440) and word 18 is `FE04C9[84]` (register 0x0480).  The image is internally consistent
with "register 0x01C0 is register 0x0400's word, folded and scaled" — the whole claim.

**The null.**  For a wrong model a hit is a 16-bit coincidence: 128 candidate indices out of
65,536 values, p = 1/512 per word.  Three of three under HIGH is p ≈ 7e-9.  Zero of three under
LOW is what a wrong model predicts.

### 4.2  Four further arguments, all agreeing, none dissenting

* **A second implementation of the ISA.**  MAME's TLCS-900 core,
  `src/devices/cpu/tlcs900/900tbl.hxx`, `srl32()` opens
  `uint8_t count = ( s & 0x0f ) ? ( s & 0x0f ) : 16;`.  So `srl 0x00,XIY` shifts by sixteen —
  **and so does `srl 0x10,XIY`**, which is what llvm-mc emits for `srl xiy,16`.  The two
  encodings the wave-17 note calls "not a witness" are the *same instruction* to a core that
  implements the rule.  ⚠ This is a second reading of Toshiba's manual, not hardware.
* **Range.**  Over the full 128 × 128 table cross-product, every pair except the 128 with
  `Rise[0] = 0` gives a product wider than 16 bits (max `0x775A0A66`).
* **Commensurability.**  The eight bytes `d9 cc f8 ff d9 ce 07 00` — `and BC,0xFFF8 / or
  BC,0x0007` — appear at **0xFC50E5**, applied to a **raw `Curve_Exp2Decay_256` entry**, and again
  at **0xFC4AD9**, applied to **the product**.  The same normalisation on two quantities means
  they share a numeric range.  A raw Decay entry is 0..0x8000; the high half is 0..0x775A; the
  low half is uniform over 0..0xFFFF.
* **Smoothness.**  Sweeping the depth index 0..127 for each of the 92 unsaturated `FE04C9`
  entries, the HIGH reading rises at **every one of 11,684 adjacent steps**; the LOW reading is
  indistinguishable from a uniform-random null in monotone fraction (0.518 vs 0.500) and total
  variation (2,825,118 vs 2,765,831 — within 3%), while the HIGH reading's total variation is
  6,848, **404× smaller** than the null's.
* And a fifth, weaker one: a shift by zero is a no-op the compiler would not emit — `ld IY` after
  the call already delivers the low half.

### 4.3  Grade

**PROVEN, on one stated premise**: that the ROM image at 0xFE133B and the packer write the same
kind of value into the same staging word.  Given that premise the instruction must compute the
high half, and the only way `srl 0x00,XIY` does so is if 0 means 16.  ⚠ No hardware trace and no
emulator trace of any of the three registers was taken; the residual risk is that premise.

---

## 5. THE REGISTER TABLE

`chan` is 0..0x3F; the register number is `block + chan`; all nineteen are **16 bits**.  `Q` is
the **43-byte wave-select record** (⚠ *not* a tone record — see §7.4), and `pN` is arm-4 tone-edit
parameter `N` = wave-select byte `+0x0N` in hex.  Names come from
`FINDINGS-l7a1429-parameter-names.md` and carry §3.3's two points of failure.

| reg | value the firmware writes | NAME | role | grade | what an HLE should DO |
|---|---|---|---|---|---|
| **0x0000** | `(R[+0x07]<<8) \| P[+0x07]`; bit 7 CLEARED when its own bits 6..4 are non-zero; bits 13..8 = the CHANNEL on the power-on path; bit 2 SET by every note event, on *and* off | — | a mode / enable word; its bits 6..4 gate `0x0300` | **UNIDENTIFIED** | store; decode bits 6..4 only as the `0x0300` gate.  ⚠ bit 2 is **not** a key gate — the note-OFF tail sets it too |
| **0x0040** | `SatAsym(P[+0x0A] + P[+0x12] + d1)`, `d1` a pitch difference; saturates to `[0x0000, 0x7FFF]` | **MAIN RESONATOR `KEY SHIFT` + `TUNE`** | a tuning offset in 1/256 semitone — `p29` whole semitones, `p30` ≈ 0.78 cent a step | **STRONG** | treat as the pitch register's own unit and range: `f = 440·2^((v/256 − 69)/12)` |
| **0x0080** | the same, from `P[+0x0C] + P[+0x14]` and `d2` | **SUB RESONATOR `KEY SHIFT` + `TUNE`** | as above, `p41`/`p42` | **STRONG** | as above |
| **0x00C0** | `Curve_Log2_251[clamp(R[+0x12]+R[+0x16]+R[+0x21], 0..250)] + (0x4280 − R[+0x0E]) − R[+0x0C]`, forced to `0x0000`/`0x7F00` on underflow | **resonator `P0SITI0N`**, with `P0SITI0N M0VEMENT` | a **log-domain PERIOD**: 3072 counts/octave = 1/256 semitone, pitch enters **negated**, pivot note 66.5, range `[0, 0x7F00]` = 10.58 octaves | **STRONG** for unit, direction and name; **absolute scale UNIDENTIFIED** | store as `T ∝ 2^(v/3072)`.  **PERIODIC**: rewritten at 40.69 Hz per sounding voice, and `R[+0x21] = p17·sine/50` is the movement |
| **0x0100** | `Const_0100_251[the SAME index as 0x00C0]` = `0x0100` in all 251 entries; `0x0000` on the Stage_B path | — | `0x00C0`'s **table-pair companion** (§6) | **STRONG** for the companion reading; value PROVEN, unit UNIDENTIFIED | store.  Expect the write at 40.69 Hz; **do not** treat it as a latch |
| **0x0140** | `Curve_Exp2Decay_256[clampU8(0xCF − g(v1) + (s8)(0x00E08C))] & 0xFFF8`, or `0x0000` when bit 0 of `(0x00E089)` is set; `g(v) = v<48 ? v/2+24 : v` | **MAIN `FITTING`**, decay form | a Q15 quantity on a 0.3763 dB/step exponential, 13 bits used, 78.6 dB span; `p21` value, `p23` touch | **STRONG** name; role **UNIDENTIFIED** — see §5.1 | store as `v/32768`.  ⚠ bits 2..0 are a separate field (masked to 000 here, to 111 on the gated arm) |
| **0x0180** | the same, with `v2`, `p31`/`p34` | **SUB `FITTING`**, decay form | as above | **STRONG / UNIDENTIFIED** | as above |
| **0x01C0** | `high16( fold(reg 0x0400's word) · Curve_Exp2Rise_128[clamp(v1, 0..PART[+0x11])] )` | **MAIN `FITTING`**, rise form | section A's cutoff coefficient scaled by `1 − 2^(−v1/16)` ∈ [0, 0.996) = **0 to −4.56 octaves** | **STRONG** that it is the same quantity as `0x0400`; the reason for the second copy is an inference | store both views: `b0·r = v/32768`, and the implied lower cutoff |
| **0x0200** | the same, with `v2` and reg 0x0440's word | **SUB `FITTING`**, rise form | as above | **STRONG** | as above |
| **0x0240** | `( high16( fold(reg 0x0480's word) · Curve_Exp2Rise_128[clamp(R[+0x14]+R[+0x18]+\|R[+0x21]\|/4, 0..0x7F)] ) & 0xFFF8 ) \| 7` | candidate `DEPTH` / `FORMANT` / `INTERACTION GAIN` | **section C's** Rise-scaled coefficient, with the `P0SITI0N M0VEMENT` term in its index | structure **PROVEN** (§2.3); name **WEAK** | as `0x01C0`.  **PERIODIC** at 40.69 Hz; low 3 bits a separate field |
| **0x0280** | `Curve_Exp2Decay_101[clamp(R[+0x10]+R[+0x23], 0..100)]` | **`SUB GAIN`** | a Q15 gain over a **0..100 percent** control with an explicit OFF, 37.3 dB taper; `p33` value, `p36` touch | **STRONG** | apply as `v/32768`.  ⚠ this is the register the whole MAIN/SUB direction rests on |
| **0x02C0** | the literal **0xFF00**, always, on every path | — | — | **UNIDENTIFIED** | write it; model nothing |
| **0x0300** | `b = ExpCurve_0_to_0x80[Q[+0x13]]`; `(b<<8) \| b`; `0x0000` when reg 0's bits 6..4 are clear | candidate `INTERACTION GAIN` | an 8-bit gain over a **0..127** control, 42.1 dB, **duplicated into both halves** | **WEAK** | store the byte.  The duplication is the shape of a device with two 8-bit fields fed the same number |
| **0x0340** | `Curve_FE05C9[i3]` | **MAIN `MUTING`** | the Q13 companion of `0x0400`'s cutoff — **computable from it** | **STRONG** | derive from `0x0400`; do not treat as a free parameter |
| **0x0380** | `Curve_FE05C9[i4]` | **SUB `MUTING`** | as above, of `0x0440` | **STRONG** | as above |
| **0x03C0** | `Curve_FE05C9[i5]`, `i5 = clamp(Q[+0x0F], 44..96)`, cached in `P[+0x24]` | candidate `FORMANT` | **section C's** companion coefficient | table identity **PROVEN** (§2.3); name **WEAK** | as above, of `0x0480` |
| **0x0400** | `Curve_FE04C9[i3]` | **MAIN `MUTING`** | ★★ a **one-pole lowpass cutoff**, index = MIDI note − 36; clamped `Table_FDFF96[zone]..PART[+0x12]` = **466 Hz .. 16.7 kHz** | fit **PROVEN**, name **STRONG** | `a1 = (fold(v)−32768)/32768`; `K = (1+a1)/(1−a1)`; `fc = fs·atan(K)/π` |
| **0x0440** | `Curve_FE04C9[i4]` | **SUB `MUTING`** | as above | **PROVEN / STRONG** | as above |
| **0x0480** | `Curve_FE04C9[i5]`, cached in `P[+0x26]` | candidate `FORMANT` | **section C's** cutoff, clamped 44..96 = **831 Hz .. 16.7 kHz** | fit **PROVEN**, name **WEAK** | as above |
| **0x0800** *(no channel)* | the literal **0x1100**, once, at power-on | — | — | **UNIDENTIFIED** | accept the write; model nothing |

### 5.1  ⚠ The one place where the two lanes' readings differ, and it is not resolved

`0x01C0` carries `b0 × r`, where `b0` is section A's own bilinear coefficient (register `0x0400`)
and `r = 1 − 2^(−v1/16)`.  That number can be read two ways and **the arithmetic is identical
under both**:

* as **a second, lower cutoff** for the same section — the curve lane's reading, and the one the
  editor's caption structure supports (`FITTING` has a "rise form" and a "decay form", which is
  what a filter envelope's two halves look like);
* as **an input gain pre-multiplied into the coefficient**, which is what a filter implementation
  does to save a multiply, and which explains why `0x01C0` lands in Q15 (`b0·r` peaks at
  `0x775A`) while `fold(0x0400)` is Q16.

⚠ Nothing in the ROM decides it.  **Store `b0·r` and expose both derived views**; do not commit
the device to either.

### 5.2  The index chains, for an implementer who wants the whole computation

```
  key   = voice[+0x0C] & 0x7F                      the 0..127 LinCoef index
  Q5(T,d) = (T[d < 0 ? 0x7F-key : key] * |d|) >> 5         32 = 1.0

  v1 = clamp( Q5(LinCoef_FE0116, Q[+0x17]) + P[+0x16], 0 .. PART[+0x11] )     FITTING, main
  v2 = the same with Q[+0x22] and P[+0x18]                                    FITTING, sub

  ks(Q,o) = bit7 of Q[+o] ? 0
          : ( Q[+o+3] * ( max(min(note, Q[+o+2]), Q[+o+1]) - Q[+o] ) ) >> 5,  note = pitch >> 8
            -- Q[+o] a BREAKPOINT (factory: 66 +/- 12k), Q[+o+1]/Q[+o+2] note bounds,
               Q[+o+3] a Q5 slope where 32 = 100% KEY FOLLOW

  i3 = clamp( ks(Q,0x19) + Q5(LinCoef_FE0196, Q[+0x18]) + P[+0x1A],
              Table_FDFF96[(0x00E08C)] .. PART[+0x12] )          MUTING cutoff, main
  i4 = the same with Q[+0x25], Q[+0x23], P[+0x1C]                MUTING cutoff, sub
  i5 = clamp( Q[+0x0F], 44 .. 96 )        in sub_FC47EE, cached in P[+0x24]/P[+0x26]

       cutoff(i) = 440 * 2^((i + 36 - 69)/12) Hz  at fs = 44100
```

★ **`LinCoef_FE0196` gives the cutoff key-follow an exact unit**: its slope is 1/64 of a Q5 unit
per key and its destination is in semitones of cutoff, so **a depth byte of 64 is exactly 100%
key follow** and the signed range is ±198%.

---

## 6. THE `0x0100` TENSION, ADJUDICATED

The write-sequencing lane found `{0x00C0, 0x0100, 0x0240}` rewritten every 24.576 ms per sounding
voice, while `0x0100`'s table is the constant `0x0100` in all 251 entries — "writing an unchanging
value forty times a second is not what a parameter register looks like".  Probe §12:

* **(c) another path writes other values — ANSWERED.**  The register takes exactly **two** values
  in the whole image: `0x0100` (packer and reset image) and **`0x0000`** (the Stage_B image,
  0xFE1315 word 4) — and `0x0000` exactly where `0x00C0` is also `0x0000`.
* **(b) a LATCH / COMMIT — DISFAVOURED**, on four counts.  (i) Its producer is
  `lda XBC,0xFDFCD6 / add XBC,XIX` at 0xFC49ED — an **indexed read of a 251-entry table**, sharing
  the index register `XIX` with the `Curve_Log2_251` read one instruction earlier.  A commit
  register is not sourced from a table indexed by a synthesis parameter.  (ii) The other refresh
  arm, `Dev104_SetChanRegs_00C0_0100`, ships `{0x00C0, 0x0100}` **without** `0x0240`, so `0x0100`
  travels with `0x00C0`, not with "whatever was written before it".  (iii) In
  `Dev104_WriteAllChanRegs` it is the **fourth** of nineteen writes, not the last.  (iv) The
  write-sequencing lane's own measurement kills the block-0 commit reading too, so the device has
  no known commit convention at all.
* **(a) the chip needs the refresh — UNNECESSARY.**  The refresh is fully explained by the other
  two members: `0x00C0` and `0x0240` are exactly the two registers whose index carries `R[+0x21]`,
  the **`P0SITI0N M0VEMENT`** term (`p17·sine/50`).  They are the modulation destinations;
  `0x0100` rides along because its producer is the companion table read in the same routine.

> **VERDICT, graded STRONG: register `0x0100` is `0x00C0`'s table-pair companion, held at a
> constant by this firmware's table.**  The shape `(two parallel tables, one index, two staging
> words)` is the shape `(Curve_FE04C9, Curve_FE05C9)` has, and there it is now established as two
> encodings of one quantity (§2.2).
>
> ⚠ An HLE must still **expect the write at 40.69 Hz** and must not assume the value is
> invariant: the Stage_B path writes `0x0000`.

---

## 7. WHAT A FIRST IMPLEMENTATION SHOULD DO

**7.1  Build the register file and the plumbing before any DSP.**

* 64 channels × 19 registers, plus the single global `0x0800`.  Channel count is PROVEN from this
  device's own loops (`FINDINGS-l7a1429-write-sequencing.md` §1).
* Port pair: `+0x00` = 16-bit register number (`block + chan`), `+0x02` = 16-bit data.  There is
  **no read port** located; return 0 and log a read, because a read would be new information.
* Come up in the power-on state: `0x0800 = 0x1100`, then all 64 channels loaded with the 0xFE133B
  image, then block 0 rewritten with bit 2 cleared.
* **No write-recovery delay.**  The five-`nop` bus padding every `0x0010C000` write carries occurs
  **zero** times in the eight `0x00104000` routines.
* **Do not build a "commit on block 0" model** — block 0 is last in 1 routine, first in 2, alone
  in 1 and absent in the 4 with live callers.  A single `(select, data)` pair is the only atomic
  unit.

**7.2  Decode the coefficients, because that part is understood.**

```c
// PROVEN closed form (notes/dev104_topology_probe.py sections 2, 3, 11;
//  notes/FINDINGS-l7a1429-curve-tables.md section 1).
static double a1_from_word(uint16_t w) {           // sign-magnitude Q15 -> [-1, +1)
    int mag = (w & 0x8000) ? -(int)(w & 0x7FFF) : (int)w;
    return mag / 32768.0;
}
static double cutoff_hz(uint16_t w, double fs) {   // registers 0x0400 / 0x0440 / 0x0480
    double a1 = a1_from_word(w);
    if (a1 >= 1.0) return fs / 2.0;
    double K = (1.0 + a1) / (1.0 - a1);            // K = tan(pi * fc / fs), the bilinear prewarp
    return fs * atan(K) / M_PI;
}
// registers 0x0340 / 0x0380 / 0x03C0 are the SAME cutoff: (1 - G/8192) * K = 1/128.
//   -> derive them, do not treat them as a second degree of freedom.
// registers 0x01C0 / 0x0200 / 0x0240 carry b0 * r, r in [0, 0.996):
//   b0_scaled = value / 32768.0        (see section 5.1 -- gain or lower cutoff, undecided)
```

⚠ **Label this "the coefficient decode", not "the filter".**  What is proven is that the
*numbers* are bilinear one-pole coefficients; that the chip runs a one-pole with them is STRONG.

**7.3  Where you must fake, fake with the real mechanism.**

* Two resonators per channel, `MAIN` and `SUB`, mixed by `SUB GAIN` (`0x0280`).
* Each: tuning from `0x0040`/`0x0080`, a damping one-pole whose cutoff comes from
  `0x0400`/`0x0440` (with `0x0340`/`0x0380` derived, not read), and `FITTING` from
  `0x0140`+`0x01C0` / `0x0180`+`0x0200`.
* One shared `P0SITI0N` from `0x00C0`, as a delay-tap time proportional to `2^(v/3072)` with an
  **unknown constant of proportionality** — expose that constant as a single named, adjustable
  parameter of the device, because it is the one number a future trace would pin.
* Route the third coefficient set (`0x0480` + `0x03C0` + `0x0240`) into the model **inert**:
  decoded, exposed, and multiplied by nothing.
* **Do not** implement resonator families (§3.4).
* **Do not** model registers `0x0000`, `0x02C0`, `0x0300`, `0x0800`.  Store, expose in the
  debugger, leave inert.
* Put every stand-in behind one switch so it is drop-in replaceable.

**7.4  ⚠ Name the record correctly.**  `Q` is the **43-byte `WaveSelRec`**, not a tone record;
the wave-17 header's `struct Tone104` is a misnaming of the object, not of the arithmetic
(`FINDINGS-l7a1429-parameter-names.md` §1a, PROVEN).  ★ That also explains this lane's own
negative result: probe §7 could not locate `Q` inside prom_d's 81-byte **element blocks**, with
eight candidate offsets at 0.90-0.93 against a pooled null of 0.551.  It is not there.  The
failed search is kept in the probe because its null is what says the element block was the wrong
object, not that the method was.

**7.5  The hard constraint that shapes the whole device.**

There is **no key-off register**.  A note-off is the same full 19-register re-program with
release values, and after the voice leaves the active list the device sees **no further traffic
at all**.  The entire decay happens inside the chip with no input.  A device that treats the
registers as instantaneous parameters will cut every note off.  **The model must sustain and
decay a voice autonomously**, which means the register values are the *initial conditions and
time constants* of an internal process.  Registers `0x00C0` and `0x0240` are the only ones a
sounding voice ever receives again, at 40.69 Hz — and they are `P0SITI0N` and section C's scaled
coefficient, i.e. exactly the `P0SITI0N M0VEMENT` modulation.

**7.6  ⚠ CARRY THIS WARNING, do not resolve it.**  `Curve_Exp2Decay_256` **cannot** be a
per-sample pole: its two largest entries are 1.0 and 0.957520 with nothing between, so the
longest representable finite time constant is **0.522 ms** and even 1 ms is unrepresentable
(`FINDINGS-l7a1429-curve-tables.md` §5).  Stepped instead at the measured 40.69 Hz refresh the
same table gives τ = 8.9-566 ms and T60 = 24 ms - 3.9 s, which is musical.  ⚠ **But that refresh
rate is measured for the `0x00C0`/`0x0100`/`0x0240` trio, NOT for `0x0140`/`0x0180`**, and nothing
in the ROM says the LSI advances anything on the host's cadence.  It is a hypothesis with a number
attached.  An implementation should make the rate a named constant and not bury it.

**7.7  Model IC3 before its output, but do not call it a sound device.**

IC3 feeds IC4 on `RQWFI` / `DWFI0..12`.  Until IC4 (`0x0010C000`, `TC183C230002`) is modelled and
the six 16-Mbit wave mask ROMs are dumped, an `l7a1429_device` that emits audio emits it into
nothing.  The right first device is a **register file with a decoded, inspectable parameter
view** — §7.1 and §7.2.

---

## 8. WHAT AN IMPLEMENTER STILL WOULD NOT KNOW

1. **The absolute scale of `P0SITI0N`.**  Unit, direction and name are STRONG; the constant that
   turns register `0x00C0` into a time in samples is nowhere in the image.  This is the single
   most valuable missing number.
2. **The internal signal path.**  Series or parallel; where the `DRIVER` waveform enters; whether
   `MUTING`'s two coefficients are two cascaded poles or one stage; how `MAIN` and `SUB` are
   coupled.  `INTERACTION GAIN` is a caption with no register assigned to it.
3. **Which of `DEPTH` / `FORMANT` / `INTERACTION GAIN` is which**, i.e. the roles of `p14`, `p15`,
   `p19` and hence of registers `0x0240`, `0x0300`, `0x03C0`, `0x0480`.  A 3! choice with two soft
   arguments and no measurement.
4. **Whether `0x01C0` is a gain or a lower cutoff** (§5.1).  The arithmetic is the same; the chip
   decides.
5. **Register `0x0000`'s fields.**  Bits 6..4 gate `0x0300`; bit 7 is cleared when they are
   non-zero; bit 2 is set by every note event including note-off; bits 13..8 hold the channel on
   the power-on path.  Their writers, `0xFC4D27` and `0xFC7DE9`, are undecoded.
6. **`0x02C0` = 0xFF00, `0x0300`'s mirrored byte, and the global `0x0800` = 0x1100.**
7. **What the four DRAM banks hold**, and whether their `M`/`S` naming really is MAIN/SUB.
8. **`SCALE`**, the fifth column of PAGE1/3, is not located.
9. **Whether MAIN and SUB are the right way round**, and whether `FITTING`/`MUTING` are the right
   way round.  §3.3 — one drawn caption each.
10. **What selects the Stage_B path**, on which the nineteen registers are a ROM image rather than
    a computation.

★ **The cheapest thing that would close most of §8 is not the instrument.**  The parameter-names
lane names it: **one hop on the CPU 1 side** — correlate `sub_FD616A`'s 29 call sites with the
screen id in `(0x207C)` and the cursor in `(0x27A5)` through prom_a's `DispatchTable_FCF000`.
That turns every WEAK row in §5 into PROVEN, removes both points of failure in §3.3, and finds
`SCALE`.  ⚠ A hardware sweep would settle §8.1 and §8.2 and nothing here proposes one: the
instrument is in storage abroad.
