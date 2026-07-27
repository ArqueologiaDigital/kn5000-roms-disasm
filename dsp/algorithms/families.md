# Effect families — structural map of the rest

The two SOLVED families have their own docs
([biquad/EQ](biquad-eq.md), [reverb](reverb.md)). The remaining 36 distinct
images are **mapped structurally** — every PM word is disassembled and every
class-A coefficient that lands on a host bank word is named, but the exact
per-instruction operation of the undecoded forms is still open. Each program is
tagged *high* or *medium* confidence (copied faithfully from
`notes/kn5000-dsp-effect-map.md`; **not** upgraded). The one-line role of each is
in [`../programs.tsv`](../programs.tsv) and its listing header; this doc groups
them by construction family. Depth lives in the effect-map note, linked once here
rather than duplicated.

## Named coefficients — 500 / 822 (60.8 %)

Every class-A multiply reads one coefficient from C-RAM through the implicit
cursor, whose absolute address is known. Joining that address to the host's
parameter-translator writers names the multiply's OPERAND (which cell, and what
the host wrote there). Two writer shapes contribute:

- **individually-addressed** T1 writers (biquad `op0x70` = 6 cells, damping
  `op0x76` = 3, and the single-cell `+0` writers) — **391** names;
- **block-upload** writers that stream a run of consecutive cells from one T1
  base via the auto-incrementing writer `0387E6 + 0388B3×n` — **+109**:
  `op0x73` = a **5-cell bilinear filter section** (103 cells; the FLANGER /
  PHASER / SINGLE DELAY / vibrato all-pass & comb stages) and `op0x77` = the
  **ENSEMBLE per-voice modulation depth** (6 cells = 3 voices × 2 channels at
  C-RAM `02 04 06 | 09 0B 0D`).

Total **500 / 822 = 60.8 %** (zero overlap). Block expansion is driven by
**T2-confirmed operands only** (the T1 map over-counts), the `0x00`-padding hazard
is guarded, and where `op0x73`'s nominal 5-cell span reaches the **MEASURED LFO
words** `092.A.**.200` / `094.A.**.200` (phase increment / `0x7FFFFF` wrap, 29/29)
the block claim is **REVOKED** — 6 such over-reaches (PHASER 2, S.DELAY+PHASER 4)
are left unnamed, not scored. **Role known ≠ full word decode:** the block roles
are **INFERRED** (which of the 5 cells is `b0` vs `−a1` is not decoded, unlike the
biquad); source coverage stays ~18 %. Tool:
`kn7000_mame/tools/kn5000_dsp_namedcoeff.py` (the block layouts folded in),
note `notes/kn5000-dsp-blockcoeff.md`.

A frequent undecoded class-A family gained an operand role this way:
**`202.A.**.655`** (20 occurrences across the delay / all-pass effects) carries an
`op0x73` **filter-section coefficient in 19 / 20 (95 %)** — a clean present-and-
absence role (`INFERRED`). The exact micro-op is the usual mac family; only its
operand is now pinned as an all-pass/comb section coefficient.

## Modulation / chorus (LFO-swept delay)

`CHORUS` (1, high), `MODULATED CHORUS` (2, high), `ENSEMBLE` (6, medium),
`FLANGER` (4, medium), `PHASER` (5, medium), `VIBRATO` (50, high),
`MIX UP` (56, medium). All build on the LFO phase accumulator
(`092.A.00.200` += increment `f/44100` in Q0.23, wrap on `0x7FFFFF`) driving a
table lookup and a swept delay tap. The flanger/phaser add all-pass chains. In
the *reverb* the word `104.2.00.000` is slot 1 of the 6-word all-pass core (one
per stage, so it does count stages there); in the phaser its position differs and
the **stage count is still not decoded**. MEASURED: all 8 non-reverb occurrences
of `104.2.00.000` sit immediately after a class-A multiply-and-store
(`../analysis/r1-allpass-motif.md` §7.2). `VIBRATO` is wet-only (no dry path).

## Delay

`SINGLE DELAY` (9, high), `MULTI TAP DELAY` (10, high), `S.DELAY+S.DELAY`
(65, high). External-DRAM taps via `880.1.60` (**READ**) and `880.1.20`
(**WRITE**) — the old "bracket OPEN/CLOSE" reading is withdrawn, the direction is
FORCED (`../analysis/r1-allpass-motif.md` §5) — plus mix + feedback coefficients
(0.5 mix, 0.15/0.3 feedback). `MULTI TAP DELAY` needs a **−3 cursor rewind**
between two words that only two candidates sit between — the best-posed small open
question in the corpus (effect-map §5.1).

## AM (tremolo / pan / ring)

`AUTO PAN` (48, high), `RING MODULATOR` (54, high). A quadrature LFO (audio-rate
for the ring modulator) multiplies the signal; the pan version is out-of-phase L/R.

## Filter / dynamics

`ENHANCER` (3, medium), `AUTO WAH` (52, medium), `COMPRESSOR` (36, medium),
`NO OPERATION` (0, medium). These carry a level detector — evidenced by the
**2/π scale constant and the one-pole smoother coefficients**, and for the wah a
swept resonator. ⚠ **Correction:** this used to cite `hi12 = 0xC40` as *the*
envelope detector. That reading is **WITHDRAWN** — `C40`/`C41` is a 13-bit
immediate load and the label was wrong on all 61 sites
(`../analysis/k5-output-stage.md` §2.3). The detector claim survives on the
coefficient evidence alone, which is where it always actually rested. **`NO
OPERATION` is not empty**: it is a dry pass-through that still runs that level
detector (most plausibly effect-level metering or a de-click ramp). The compressor computes gain
**arithmetically**: there is **no comparator opcode** in the corpus (the bodies
are branchless), so THRESHOLD/RATIO enter as coefficients, not as a compare.

## Distortion / exciter

`DISTORTION` (32, high), `FUZZ` (34, high), `OVERDRIVE` (33, high),
`EXCITER` (35, high). An AGC waveshaper through the 3-word **table-lookup idiom**
(`040.0.00.C63 | 000.6.TT.4CD | 012.4.01.1CE`, the class-6 `addr8` selecting the
transfer curve), followed by tone biquads (overdrive adds a 4 kHz Butterworth).
The exciter is LUT → band-pass → added back to dry.

## Rotary

`ROCK ROTARY` (15, high; shared with `ROTARY SPEAKER`, algo 53). Leslie-style:
crossover plus modulated taps.

## Combinations

`S.DELAY+CHORUS` (64), `S.DELAY+FLANGER` (66), `S.DELAY+VIBRATO` (67),
`S.DELAY+PHASER` (68), `AUTO WAH+S.DELAY` (70), and the `PEQ+…` set
(71,72,73,74,75,96,97,98,99). All follow one construction rule: **one or two flat
biquad bands and/or a single-delay block, then a standalone effect block verbatim,
coefficient for coefficient.** These are the strongest evidence that the effects
are **compiled from a common library** — e.g. `PEQ+OVERDRIVE+DELAY` (99) contains
two copies of `OVERDRIVE`'s tone biquad byte-for-byte, and the `PEQ+COMP…` set
shows a consistent **+4 cursor/host offset** that still decodes to the identical
flat default (effect-map §5.2).

## Excluded — ~~malformed~~ **NOT IC311's** (corrected 2026-07-27)

~~Algos **79, 88, 89, 90, 91** load outside the 384-word I-RAM, carry no
terminator and no class-2 word. They are the same defect~~ — **they are not a
defect at all.** They are **IC310 (MN19413) programs**, and so are **57, 58, 59
and 60**. **Nine** of the 100 algorithm slots belong to the second DSP; the IC311
population is **91**. The reason only five were ever flagged is that their
cmd-`0x30` record rides on record opcode **3**, which an IC311-shaped parser
turns into a phantom I-RAM block, while 57–60's rides on opcode **`0x0E`** and
parses to nothing. The generator's constant is renamed `DSP2_MISPARSED`.
See [`../analysis/second-dsp-and-ready.md`](../analysis/second-dsp-and-ready.md)
§2.

## The second DSP (MN19413) — scoped, not covered

Nine algorithm slots route to **IC310, an MN19413** — a different chip (own
20 MHz crystal X302, byte-wide 1 Mbit delay DRAM IC308), bit-banged **write-only**
over PF.0 (`DSP2DA`) / PF.2 (`DSP2SCK`) / PE.6 (`DSP2CS`), with **no READY line**.

| slot | name | program |
|---|---|---|
| 57 / 58 / 59 / 60 | STANDARD / PERCUSSIVE / SYMPHONIC / DEEP SPACE | load 1336, 177 words (shared) |
| 79 | GEQ | load 1520, 60 words |
| 88 / 89 / 90 / 91 | ROOM / KARAOKE / BATH ROOM / STAGE | load 3376, 165 words (shared) |

Its instruction word is **32 bits** — the old *"bodies autocorrelate at lag 4,
suggesting 32 bits"* is now FORCED within an enumeration `{1,2,3,4,5,6,8,12}` by
integrality + block disjointness + a period test against a byte-shuffle null —
and its coefficient word is **16 bits, word-addressed** (record abutment, 8 of 8
against 0 of 8 for every rival width). 3 programs / 402 words; 9 coefficient
images / 674 words.

**And it is the chip the whole main mix passes through** (`IC303 SDO0 → IC310 SDI
→ IC313 PCM69AU`), plus the only ADC the microphone reaches. It is a whole second
effects processor, it carries the master reverb, and it is **not covered here**
and not modelled in MAME.
