# Does topology-matching reveal what specific instructions are? YES (2026-09-11)

The flowcharts are now annotated with each program's classic-effect topology
(`gen_dsp_flowcharts.py` TOPOLOGY_HINTS). Cross-referencing those topology predictions with an
idiom census over all 38 `.dsm` images (raw-word ACT/SRC/class fields) gives concrete new
constraints on several ISA idioms — and one correction to a prior claim.

## The idiom × family census (all 38 images)
`bq` = ACT 0x12/0x13/0x14 · `bqp` = ACT 0x0D/0x0E · `tbl` = class-6 · `sq` = SRC 0x08.

| family (n) | bq present | bqp | tbl (class-6) | sq (SRC 0x08) |
|---|---|---|---|---|
| eq (1) | 1/1 | 1/1 | 0/1 | 0/1 |
| filter (2) | 2/2 | 2/2 | 0/2 | 0/2 |
| reverb (2) | 2/2 | 2/2 | 0/2 | 0/2 |
| delay (3) | **0/3** | 3/3 | **0/3** | **0/3** |
| distortion (3) | **1/3** | 3/3 | 3/3 | 0/3 |
| exciter (1) | 1/1 | 1/1 | 1/1 | 0/1 |
| dynamics (2) | 1/2 | 2/2 | **0/2** | 2/2 |
| am (2) | **0/2** | 2/2 | 2/2 | 2/2 |
| modulation (7) | 3/7 | 7/7 | 7/7 | 7/7 |
| rotary (1) | 1/1 | 1/1 | 1/1 | 1/1 |
| combi (14) | 11/14 | 14/14 | 11/14 | 10/14 |

## New insight #1 — ACT 0x12/0x13/0x14 = the 2nd-order-section (biquad / all-pass) STATE ops
Present **iff** the topology has a biquad or all-pass section, and the COUNT tracks the number of
sections:
- **PHASER = 20**, S.DELAY+PHASER = 10, PEQ+FLANGER = 6 (the all-pass **chain** — phaser is a
  cascade of all-pass sections, each a 2nd-order stage);
- **OVERDRIVE = 1** (its post-distortion tone biquad) vs **FUZZ/DISTORTION = 0** (bare waveshaper,
  no biquad) — the exact split the distortion topology predicts, and the exact thing my live T2/T3
  capture found (ACT 0x12/13/14 live in OVERDRIVE, absent from FUZZ);
- **delay = 0, am = 0** (no 2nd-order section).
So the EFFECT-ALGORITHMS-spec reading (0x13=ld.ta, 0x12=mac, 0x14=mac.tb, tempA/tempB = the two
z&#8315;&#185; states) is confirmed AND generalised: these are the state-latch/MAC ops of ANY
2nd-order section, biquad or all-pass, and their per-program count = the section count.

## New insight #2 — class-6 (table lookup) is ONE op serving THREE roles
Present in modulation (7/7), distortion (3/3), exciter (1/1), am (2/2); ABSENT from delay, eq,
filter, reverb, dynamics. The three roles, unified:
- **LFO WAVEFORM table** (modulation — a phase accumulator reading a shaped sine/triangle table);
- **waveshaper nonlinearity** (distortion / exciter);
- **ring-mod carrier** (am).
So class-6 = "read a shaped table", and its presence pinpoints exactly the effects that need one.
This unifies what the docs treated as two separate things (the "waveshaper LUT" and the "LFO table").

## New insight #3 — SRC 0x08 (coefficient-square) = the LFO/envelope modulation op
Present **exactly** in the families with an LFO or an envelope — modulation (7/7), am (2/2),
dynamics (2/2) — and ABSENT from pure filter/delay/eq/distortion/reverb. This identifies SRC 0x08 as
a modulation/envelope-computation op (the coefficient-squaring §224 §S2sq idiom), and matches my live
finding that FLANGER's *gated* class-A word is exactly a SRC 0x08 (f31=4) op that fires only on the
LFO's active phase.

## Correction — ACT 0x0D/0x0E is UNIVERSAL, not a biquad-specific z&#8315;&#185; pair
`TOPOLOGY-vs-ALGORITHMS.md` lists `bqp` (ACT 0x0D/0x0E) as "the two z&#8315;&#185; biquad
delay-stage updates". But the census shows it in **every family including delay (3/3) and am (2/2)**,
which have no biquad. So ACT 0x0D/0x0E is a GENERAL delay-line / state I/O mixing op (consistent with
this session's M2 finding that ACT 0x0D reads mem and 0x0E reads acc onto the bus around the delay
read/write), NOT a biquad-only idiom. The prior doc's `bqp` label is too narrow; corrected here.

## Net
Topology-matching + the corpus census turned four "idioms" into semantically-anchored ops:
ACT 0x12/13/14 = 2nd-order-section state (count = #sections), class-6 = shaped-table lookup (LFO /
waveshaper / carrier), SRC 0x08 = LFO/envelope modulation, and ACT 0x0D/0x0E = general delay/state
mixing (correcting a prior over-narrow label). Each is falsifiable by presence/absence across the 38
images and cross-checked against the live runtime findings. These are real decoding gains — the kind
of stage-to-opcode anchoring that raises confidence on the still-"opaque" words and flags where the
remaining ambiguity (the input-route ALU, the biquad realization) actually sits.
