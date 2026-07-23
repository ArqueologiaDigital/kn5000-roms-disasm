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
table lookup and a swept delay tap. The flanger/phaser add all-pass chains (the
`104.2.00.000` markers bracket the chain rather than counting it, so the **stage
count is not decoded**). `VIBRATO` is wet-only (no dry path).

## Delay

`SINGLE DELAY` (9, high), `MULTI TAP DELAY` (10, high), `S.DELAY+S.DELAY`
(65, high). External-DRAM taps via the `880` bracket, mix + feedback coefficients
(0.5 mix, 0.15/0.3 feedback). `MULTI TAP DELAY` needs a **−3 cursor rewind**
between two words that only two candidates sit between — the best-posed small open
question in the corpus (effect-map §5.1).

## AM (tremolo / pan / ring)

`AUTO PAN` (48, high), `RING MODULATOR` (54, high). A quadrature LFO (audio-rate
for the ring modulator) multiplies the signal; the pan version is out-of-phase L/R.

## Filter / dynamics

`ENHANCER` (3, medium), `AUTO WAH` (52, medium), `COMPRESSOR` (36, medium),
`NO OPERATION` (0, medium). These carry the envelope detector (`hi12=0xC40`, the
2/π scale and one-pole smoothers) and, for the wah, a swept resonator. **`NO
OPERATION` is not empty**: it is a dry pass-through that still runs a level
detector (most plausibly effect-level metering or a de-click ramp) — which is why
it trips the `env`/`dram` structural controls. The compressor computes gain
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

## Excluded — malformed

Algos **79, 88, 89, 90, 91** load outside the 384-word I-RAM, carry no terminator
and no class-2 word. They are the same defect and are **excluded** from the tree
(flagged in the generator's `MALFORMED` set), not disassembled.

## The second DSP (MN19413) — untouched

Effect units 2–4 route to **IC310, an MN19413** — a different chip (own 20 MHz
crystal, 8-bit delay DRAM), bit-banged over PF.0/PF.2/PE.6. Its bodies
autocorrelate at lag 4, suggesting a **32-bit** word rather than 36. It is a whole
second effects processor and is **not covered here**.
