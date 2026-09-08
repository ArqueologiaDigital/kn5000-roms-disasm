# Decoding OPEN fields by cross-program correlation

**Date 2026-09-08.** A creative pass looking for discriminators the raw corpus does not
supply. The idea: the effect NAMES and the program STRUCTURE (delay-tap count, coefficient
count) are independent variables; if an OPEN field's value *tracks* one of them across the
whole catalog, that correlation is a discriminator — it says what the field is *for*, even
where a single occurrence could not. Eleven results (§1–§11), all from the committed `.dsm` of
both products, no emulator, no hardware.

> **Counts corrected 2026-09-08:** the correlation tools first keyed programs by effect
> *name*, but KN5000 and WSA1R share 31 effect names across byte-different programs, so a
> name-keyed dict silently kept only one product's version (86 programs collapsed to 55).
> The tools now retain every program; all counts below are the re-run values on the full
> corpus. **No qualitative conclusion changed** — every correlation, adjacency and family
> association held; only the absolute counts grew (e.g. 0x0D→0x0E stayed 82→80 %). The
> composition results (§7) and the 0x1C refutation (§8) used filename-keyed tools and were
> never affected.

## 1. The C-format immediate DESTINATIONS are decodable, and they are not coefficients

The C-format word loads a MEASURED 13-bit immediate into a register named by `lo12`; the
destination was always "UNKNOWN". Correlating each destination's loaded value against
program structure (`dsp/tools/dsp_cformat_analysis.py`) separates three distinct roles:

| dest `lo12` | words | r vs delay-taps | r vs cMACs | values | proposed role (GRADED, correlational) |
|---|---:|---:|---:|---|---|
| **0x000** | 207 | **−0.82** | +0.03 | 384/480/704/896 | a **DELAY / MEMORY** structural parameter — it tracks the delay-tap count and is *independent of the coefficient count*. Reverbs (40 taps) → 384; simple effects (2 taps) → 896; values are 3/5/7 × 128. |
| **0x44C** | 64 | −0.03 | +0.27 | 800/992 | a **near-unity GAIN / makeup-scale** (0.78 / 0.97 of 1024) — no structural correlation, sits just under 1.0. This is the chorus's "A = 25" (800 = 25 × 32). |
| **0x451** | 14 | **−0.88** | **+0.64** | 480/672 | a **FILTER-structure** parameter — tracks the coefficient-MAC count, not the tap count. |

⇒ **The C-format instruction is not one thing.** Its `lo12` selects *what the immediate
parameterises*: memory/delay sizing (0x000, the common case), a gain (0x44C), or a filter
count (0x451). That is a real advance over "destination UNKNOWN": the destination is now a
graded, discriminated hypothesis. It also tells the decode that **the 207 words at 0x000
are structural, not signal** — so their immediate should be modelled as a size/limit, and a
wrong "it's a coefficient" reading is ruled out by the zero correlation with cMACs.

The method's own control: if these values were arbitrary or were signal coefficients, they
would not correlate with the tap/MAC counts at all — 0x44C, which *is* a gain, correctly
shows ~0 correlation with both.

## 2. The WSA1R has FOUR reverb algorithms, not eleven

Clustering the reverb programs by byte-identity (`gen_wsa1_dsp_disasm.build`):

- **cluster 0** (91 words): CONCERT REVERB 1, DARK REVERB 1 & 2, WAVE REVERB 1 & 2
- **cluster 1** (92 words): CONCERT REVERB 2, ROOM REVERB 1 & 2
- **cluster 2** (91 words): PLATE REVERB 1 & 2
- **cluster 3** (71 words): GATED REVERB

So the thirteen named reverbs are **four distinct programs plus coefficient presets** — the
"1 vs 2" variants are *byte-identical programs* (the difference is entirely C-RAM), and
DARK/WAVE/CONCERT-1 share one program. PLATE differs from the general reverb in 47 of 91
words but with an **identical idiom histogram and identical DRAM tap counts** (28 w / 12 r) —
the same reverb-tank *shape* with different tap offsets and immediates. This is the same
lesson as the runtime finding at a different level: reverb *character* is data, not code.

## 3. Program-order context confirms the ACT 0x0D/0x0E biquad pair

A second discriminator the isolated word cannot give: what feeds each OPEN code and what it
feeds, aggregated across the catalog (`dsp/tools/dsp_context_analysis.py`).

- **ACT 0x0D → ACT 0x0E is an ADJACENT PAIR.** ACT 0x0D is *immediately* followed by ACT
  0x0E in **355/441 (80%)**, and ACT 0x0E is *immediately* preceded by ACT 0x0D in **355/483
  (73%)**. Two back-to-back state updates are exactly a biquad's `z⁻¹`/`z⁻²` pair — this is a
  strong, cross-program, MEASURED confirmation of the reading the strict method had refused
  for want of a discriminator. ⚠ It confirms the *pairing/role*, not the *lag* (which tap is
  delayed) — that stays hardware-Q4.
- **It is a general primitive, not EQ-only.** ACT 0x0D appears in every family (reverb 11,
  delay 13, modulation 6, eq/filter 10, other 15), so the two-state filter update is used
  wherever there is a resonant filter, damping one-pole or feedback comb — which is why the
  biquad idiom shows up far beyond the parametric EQ.
- **SRC 0x00 context matches the MEASURED mem-read.** SRC 0x00's neighbour profile (cMAC /
  route before, route / cMAC after) is the same shape as SRC 0x07 (`= mem[ptr]`, MEASURED),
  supporting the shipped "delay-read". **SRC 0x11** is *preceded by a route 56%* of the time,
  consistent with a second accumulator that is set up by a route then read (the ACCB reading).

## 4. Instruction MOTIFS name the building blocks and pin register 0x000

Mining the recurring idiom n-grams (`dsp/tools/dsp_motif_analysis.py`) recovers the
algorithm primitives directly:

- **`MMM` / `MMMM` (446 / 243)** — coefficient runs = biquad / filter sections.
- **`zz` (the biquad two-state pair, 263 `zza`)** — always adjacent (§3).
- **`WC` / `WCWC` (~124 / 106)** — a delay-tap **WRITE** immediately followed by a **C-format
  load of 480 to register `lo12=0x000`**, and it occurs in **all 11 reverbs**. So a reverb
  is a *uniform comb*: write a tap, (re)load the delay parameter, write the next. This is
  independent confirmation that **`0x000` is a delay-memory parameter** (§1) — here caught
  red-handed being reloaded before every comb write, constant 480.
- **delay STAGES (`R…W` spans)** — `RMaaW` (a comb: read tap, gain, add, write), and
  crucially **`RMMzzW`** = read tap, gain, **biquad damping filter (`zz`)**, write: a comb
  with a one-pole damper in its feedback — the textbook reverb-tank stage. The `zz` inside
  the delay loop is *why* the biquad idiom appears in reverbs (§3), not just EQ.

⇒ Three independent angles (value correlation, program-order context, motif position) now
agree on the same two readings: **`ACT 0x0D/0x0E` = a biquad two-state update** and
**C-format `lo12=0x000` = a delay-line parameter**. None needed hardware; each is a
discriminator the isolated word could not provide.

## 5. The reverb PRIMITIVE differs between products, at the coefficient level

Reading each reverb's delay stages (`R…W` spans) together with the C-RAM cursor cells the
multiplies inside them consume pins the exact reverb primitive — and it is different on the
two chips:

- **KN5000 ROOM REVERB = an all-pass diffuser ladder.** Its stages are **`RMaaW`**: read the
  delayed sample, **one** multiply (a *single* coefficient — cells 7, 8, 9, 10, … one per
  stage), then two route ops. One coefficient applied with `+g`/`−g` combines is exactly a
  first-order all-pass — which matches the SOLVED "all-pass diffuser ladder" reading, and it
  **decodes the two route (`a`) ops as the all-pass ±g combine**. The motif count finds
  **exactly nine `RMaaW` stages** in ROOM REVERB 1 — independently reproducing the "nine
  first-order all-pass diffusers (five + four)" that the *exhaustive constraint search*
  proved (public `effects-dsp.md` §4). Two unrelated methods agreeing on 9 is a
  **cross-validation of the motif approach against a PROVEN anchor**; the remaining spans
  (`RsMMMzzMMMaW`, `RaMMMaW`) are the pre-delay / damping / recirculation the doc places
  *outside* the diffuser.
- **WSA1R ROOM/PLATE/CONCERT REVERB = a comb with damping.** Its stages are **`RMMzzW`**:
  **two** multiplies (feedback gain + a damping filter) followed by the biquad `zz` pair —
  a lossy feedback-delay-network / comb, not a single-coefficient all-pass. The two mults
  read *distinct* consecutive cells (0,1 / 20..24), i.e. a gain plus a multi-tap damping
  filter, never one reused coefficient.

⇒ Same effect name, genuinely different reverb *algorithm* between the products — now shown
not just by the DRAM read/write order (`TOPOLOGY-vs-ALGORITHMS.md`) but by the per-stage
coefficient count: **1 coefficient/stage (all-pass) vs 2+ (comb+damp)**. For the KN5000 this
also gives the all-pass route ops a decoded role.

## 6. The table-lookup SELECTOR decodes by family — and reveals the LFO

The class-6 word is a table lookup; its `addr8` selects *which* table. Grouping the selector
by the effect family that uses it (`dsp/tools/dsp_table_analysis.py`) names the tables,
because a distortion only ever looks up a waveshaper and a chorus only ever looks up an LFO
shape:

- **`addr8 = 0x28` → the WAVESHAPER / distortion curve.** Used by DISTORTION, FUZZ,
  OVERDRIVE, EXCITER and every PEQ+DIST / PEQ+OVERDR combination (34 words).
- **`addr8 = 0x18` → the LFO WAVEFORM table.** Used by the modulation effects — RING
  MODULATOR, VIBRATO, PHASER, CHORUS, FLANGER, AUTO PAN (53 words). So the **LFO is a
  phase-accumulate → table lookup**, i.e. a *shaped* waveform (sine/triangle), not a bare
  ramp — which is what the phase-accumulator idiom (§ the f31=1 step / f31=2 wrap words)
  feeds into.
- **`addr8 = 0x18 / 0x1A / 0x1E / 0x20` together → multiple LFO voices.** ENSEMBLE and some
  PEQ+CHORUS / S.DELAY+CHORUS read *several* LFO tables at once — one detuned phase per
  voice, exactly a multi-voice chorus/ensemble.
- **`lo12 = 0x4CD`** is the table-lookup operation register (47 of the class-6 words).

⇒ The class-6 selector `addr8` is a table id, decoded by family into waveshaper vs LFO, and
it closes the LFO datapath: *phase accumulator → LFO waveform table → modulates the delay/gain*.

## 7. End-to-end reconstruction: the decoded pieces COMPOSE, and there are TWO biquads

The strongest check on all of the above is not another correlation but a *composition* test:
trace a whole program and see whether the independently-decoded fields assemble into the
textbook algorithm the effect name promises. Two programs, traced word-by-word, plus the
mechanism split they reveal (`dsp/tools/dsp_biquad_mechanisms.py`).

### 7a. CHORUS (prog01) is a textbook LFO-swept delay — built from this session's decodes

Reading `prog01_chorus.dsm` top to bottom, every stage is one of the primitives decoded above:

- **LFO phase accumulator** (w5 `phase += increment`, w7 `phase wrap`, consuming the
  MEASURED `0x7FFFFF` = 2²³−1 mask) — the §6 phase generator, verbatim.
- **Two class-6 LFO-table reads**: w31 `addr8=0x18` (voice 0) **and** w35 `addr8=0x20`
  (voice 1), each with `lo12=0x4CD`. That is §6's *multi-voice* prediction caught in the act:
  the header's "**quadrature 2-voice** chorus" is literally **two** LFO-waveform lookups at
  the two selectors §6 named — verified with the disassembler, not asserted.
- **Modulated delay taps**: external delay-DRAM read/write pairs (w9/w14/w18/w23 …) whose
  address moves with the LFO, each scaled by a **C-format gain load to `lo12=0x44C`, A=25**
  (w12/w21/w53/w62) — the §1 near-unity makeup gain.
- The **ACT 0x0D/0x0E pair** appears only in the I/O amble (w1/w2, w46/w47), not in the LFO
  or delay core.

⇒ the parts decoded from *independent* angles (LFO tables §6, C-format gain §1, biquad pair
§3) **compose** into exactly the block diagram a chorus should have. Composition is the
cross-check a single-word reading can never give.

### 7b. PARAMETRIC EQ is a Direct-Form-I biquad — and it uses a DIFFERENT filter primitive

`prog39_parametric_eq.dsm` / `eff04_parametric_eq.dsm` are a pristine, fully-named
Direct-Form-I bilinear biquad. Each section is a fixed **9-word** template with six
coefficients (`b1, b0, b2, −a1, −a2, makeup`) and **two state latches** `ta`/`tb`:

```
  ld.ta   (p),c+  ; b1  -- P=b1*S0, latch A <- S0     (ACT 0x13 = section entry)
  mac     ...+1   ; b0  -- S0<-x, acc=P, P=b0*x        (ACT 0x12 = MAC + advance)
  mac     ...+1   ; b2  -- acc+=P, P=b2*S1
  mac.tb  ...+1   ; -a1 -- acc+=P, P=-a1*S2, latch B<-S2 (ACT 0x14 = the -a1 tap)
  mac     ...+0   ; -a2 -- acc+=P, P=-a2*S3
  mac.st  tb      ; acc+=P, S3 <- latch B
  post    acc,c   ; class-8 normalize/output step
  mac.st  acc,c+  ; makeup -- S2<-acc, P=makeup*acc
  ld.st   ta      ; acc<-P, S1 <- latch A
```

KN5000 runs **5 sections × 2 channels**, WSA1R runs **6 × 2** — otherwise byte-identical
template. So the parametric EQ is **convergent** between the products, unlike the reverb
primitive, which genuinely differs (§5). "Same name → different algorithm" is effect-specific.

### 7c. This resolves the "OPEN ACT 0x12/0x13/0x14" red herring and decodes class-8 `post`

An earlier family-concentration scan flagged ACT `0x12/0x13/0x14` as codes "worth decoding"
because each is concentrated in the eq/filter family. The 7b trace shows they are **not open**:
they are the Direct-Form-I latch ops the disassembler already renders `mac` / `ld.ta` /
`mac.tb`. They are eq-concentrated because DF-I *is* the EQ mechanism. Measured split
(`dsp_biquad_mechanisms.py`, both products):

| primitive | ops | where | count |
|---|---|---|---:|
| **Direct-Form-I latch biquad** | `ld.ta`(0x13) · `mac`(0x12) · `mac.tb`(0x14) · class-8 `post` · makeup | **EQ / PEQ-combo / wah only** | **91 % of 101 `ld.ta`** |
| **two-state pair** | ACT 0x0D / 0x0E (adjacent 80 %, §3) | **every family** (I/O amble, feedback damping) | 78–110 per family |

Two consequences:

- **The negative adjacency of §3-adjacent-test is now the *expected* signature.** ACT 0x13→
  0x14 came back **0/66** — because in a DF-I section they are the *entry* (`ld.ta`) and the
  *−a1 tap* (`mac.tb`), **three words apart**, not a z⁻¹/z⁻² neighbour pair. A biquad z-pair
  would be adjacent (that is 0x0D/0x0E); a DF-I section deliberately is not. The failed pair
  test *confirms* the mechanism rather than refuting anything.
- **The class-8 `post acc,c` op is decoded by concentration.** In the PEQ disasm it was
  literally commented `OPERATION UNKNOWN`; measured here, it occurs **only** in DF-I biquad
  programs (PARAMETRIC EQ, every PEQ+*, OVERDRIVE, EXCITER, ROCK/ROTARY, wah) and **never**
  in a pure reverb/delay/modulation program. ⇒ graded reading: it is the **biquad section's
  normalize / output-scale step** (the point where the accumulated sum is rounded/saturated
  back to the sample word before the makeup multiply), not a general instruction.

So §3's "ACT 0x0D/0x0E = the biquad" was slightly too broad: the *reference* biquad (the
parametric EQ) does **not** use it — it uses the DF-I latch. There are **two** filter
primitives, and they separate by family: DF-I for tone-shaping EQ, the 0x0D/0x0E pair for
the resonant/damping filters embedded in reverb/mod/delay feedback paths.

### 7d. The distortion family = {pre-gain → waveshaper → optional tone filter}, and the tone filter names the effect

Tracing `prog32_distortion.dsm` per channel (it is stereo — two byte-identical halves)
composes §6's waveshaper with §7's DF-I biquad into the textbook AGC-waveshaper the header
names ("distortion: AGC waveshaper, curve A"):

- **input load** → **pre-gain / drive** (C-RAM[0x00], the `op0x61` coefficient — decoded by
  position as the *drive* amount) → **waveshaper table lookup** (w10/w31, class-6
  `addr8=0x28` — §6's distortion curve, now confirmed *by composition*) → **output level**
  (C-RAM[0x02], `op0x62` — the makeup after the AGC-normalised curve).

Whether a **DF-I tone biquad** sits in that chain, and where, discriminates the whole family
(`dsp_biquad_mechanisms.py`, both products):

| effect | datapath (per channel) | character |
|---|---|---|
| **FUZZ, DISTORTION** | waveshaper only | hardest — raw curve, no tone filter |
| **OVERDRIVE, EXCITER** | waveshaper → **tone biquad** | smoothed — a post filter tames the clipping harmonics |
| **PEQ+DIST / PEQ+OVERDR …** | **pre-EQ biquad(s)** → waveshaper | the parametric EQ shapes the tone *into* the nonlinearity |

That ordering is exactly what the effect names imply — fuzz is the harshest (bare curve),
overdrive is softer (post-nonlinearity smoothing), and the PEQ combos put a full parametric
pre-filter ahead of the drive. So the distortion family needs one shared kernel —
`gain · waveshaper(curve) · gain` — plus an optional DF-I biquad placed before or after by a
per-effect flag; the curve itself is the C-RAM table, not code.

## 8. Correction: SRC 0x1C is a control bus, NOT "LFO output"

Correlation can also *refute*. The disassembler carried a speculative reading
`SRC 0x1C = LFO output`. If that were right, 0x1C could only occur in programs that build an
LFO. Cross-tabulating 0x1C against the presence of an LFO-waveform table
(`dsp_datapath_fingerprint.py`) shows it is **present in 19 programs that have NO LFO table
at all** — DISTORTION, FUZZ, OVERDRIVE, EXCITER, PITCH SHIFTER, and the PEQ+COMPR+DIST/OVERDR
combos — versus 29 that do. And it is **consumed by a MAC in 91 of 91 occurrences**.

⇒ 0x1C is not the LFO. It is the effect's **control/modulation bus**: a source register,
always multiplied into the signal path, that carries the **LFO** in modulation effects and an
**envelope / AGC level** in the dynamics/distortion effects (which is exactly what an
AGC-waveshaper and a compressor need, and where the LFO reading was impossible). The
annotation in `dsp_disasm.py` and all 48 regenerated `.dsm` are corrected to the control-bus
reading in this same change, per the "correct the old text with the new evidence" rule. This
is a graded refinement (the *what-it-carries-per-family* split is a correlation), but the
refutation of "LFO-only" is measured: 19 non-LFO programs cannot be explained by an LFO source.

## 9. The topology/coefficient split, measured at the VALUE level

Every earlier "coefficients are runtime data, not baked in the program" result came from bus
capture or the descriptor structure. A fresh, independent check: look at the actual C-format
immediate *values* a program embeds (`dsp/tools/dsp_immediate_census.py`). The decisive
distinction is the **C-format opcode**: `0x620` loads an immediate *value* (a size, gain or
coefficient); `0x600` (WAIT/SYNC — its field is the word's own I-RAM address) and
`0x60B/0x60C/0x60D` (pointer-loads) are *control* words whose 13-bit field is an **address**.
Separating them by opcode (an earlier draft of this section lumped them and mistook addresses
for huge "coefficients"):

| file class | value-loads (0x620) | control words (0x600/0x60B–D) |
|---|---|---|
| **effect body** (`prog*`/`eff*`) | **296**, range [0 … 1440] | **0** |
| resident **kernel** (`kernel.dsm`) | **0** | 15, range [224 … 3520] (addresses) |
| boot **struct** records | 90, range [384 … 480] | 44, range [−3931 … 3520] (addresses) |

Two clean, measured facts fall out:

- **Effect bodies carry ONLY value-loads (never a control word); the resident kernel carries
  ONLY control words (never a value-load).** The kernel is pure sync/pointer scaffolding — the
  runtime *engine* — and it takes its coefficients from streamed C-RAM, not from any C-format
  immediate. The effect programs are pure topology + structural sizing (delay length 0x000,
  gain 0x44C, filter-count 0x451). That is the topology/coefficient split drawn a third way,
  and it matches the raw-bus runtime finding exactly.
- **No value-load immediate anywhere — body, kernel or struct — exceeds `|imm| = 1440`.** There
  is **no baked biquad-range (a1/a2 ≈ ±2) signal coefficient in any program.** The large
  numbers that first looked like coefficients (up to ±3931) are every one an *address* in a
  WAIT/SYNC or pointer-load word. The tempting "resident biquad a1/a2" reading is not merely
  unproven — it is **wrong**: those fields are addresses, not fixed-point values. (This section
  corrects that misread in the same commit that found it, per the evidence rule.)

## 10. Whole-catalog template clustering — the cross-name algorithm identities

§2 collapsed the 13 reverb *names* to 4 programs. Generalising that to all 86 effect programs
(`dsp/tools/dsp_template_clusters.py`, clustering by idiom sequence): **78 exact templates**
(only the reverb 1/2 variants and DISTORTION≡FUZZ are word-identical) and **~52 near-families**
at idiom-sequence LCS ≥ 0.85. The near-families expose identities the *names* hide:

- **EXCITER ≡ OVERDRIVE** (waveshaper + post tone biquad, §7d) — the same template.
- **AUTO WAH ≡ PEDAL WAH** (a swept filter: auto = LFO-swept, pedal = manual — one DSP program).
- **MANUAL DELAY ≡ SINGLE DELAY**; **SLOW ATTACKER ≡ NO OPERATION** (a stub, confirming the
  KN5000 stub-effect list on the WSA1R too).
- **FLANGER ~ VIBRATO** inside the S.DELAY+ / PEQ+ combos (both LFO-swept delay).
- every **KN5000 ↔ WSA1R same-name pair** clusters — cross-product structural validation.

⇒ the catalogue does *not* collapse to a handful of templates (each family is its own program),
but it does contain real cross-name equivalences an emulator can share: implement one
waveshaper-plus-tone-filter for exciter+overdrive, one swept-filter for auto/pedal wah, etc.

## 11. The scratch-pointer STRIDE is a family fingerprint of the on-chip state geometry

Every class-2 word carries a signed post-increment in `addr8` — the move of the internal
scratch/state pointer `p` (the external DRAM taps are descriptor-borne, not here). Histogramming
the strides by family (`dsp/tools/dsp_pointer_stride_analysis.py`) turns this already-decoded
field into an algorithm discriminator:

| stride class | meaning | global count |
|---|---|---:|
| **0** | same-cell accumulate / store-back | 2248 |
| **±1, ±2** | the biquad two-state (z⁻¹/z⁻²) move | ~1140 |
| **\|d\| > 2** | reach-back into on-chip scratch (short delay / all-pass / comb state, multi-tap) | — |

| family | strides | state (\|d\|≤2) | reach (\|d\|>2) | distinct reach |
|---|---:|---:|---:|---:|
| **eq** | 1518 | **75 %** | 25 % | 72 |
| reverb | 754 | 53 % | **47 %** | 48 |
| delay | 1186 | 63 % | 37 % | 63 |
| **modulation** | 988 | 57 % | 43 % | **90** |
| dyn/dist | 522 | 68 % | 32 % | 57 |

⇒ EQ is **state-bound** (three-quarters of its pointer moves are the biquad z-state) while
reverb/delay/modulation spend nearly half their moves **reaching back** into scratch — the
on-chip short-delay / all-pass / comb state — and modulation has the **widest** spread of
distinct reach offsets, exactly what an LFO-swept tap that reads at a moving offset produces.
This is the on-chip state/delay geometry, complementary to the descriptor-borne DRAM topology
(§5): an emulator's per-effect scratch buffer is sized and accessed along these lines.

## Why this matters for decode + implementation

- The 207 C-format-0x000 words (~6 % of the combined two-product corpus) get
  a *structural* reading — a decode gain that costs no hardware and no speculation beyond the
  correlation, which is itself the evidence.
- It reframes the delay/reverb implementation: the per-effect delay geometry is set by these
  0x000 immediates (a memory/limit parameter) plus the descriptor block, not by the program
  words' addresses — consistent with the "address is in the descriptor, not the word" finding.
- The reverb clustering says an emulator needs only ~4 reverb programs + the coefficient
  presets, not 13 distinct algorithms.
- The emulator needs **two** filter kernels, not one: a Direct-Form-I biquad (parametric EQ,
  5–6 bands × 2 ch, coefficients `b1,b0,b2,−a1,−a2,makeup` + a normalize step) and a
  0x0D/0x0E two-state update for the reverb/mod feedback filters. The DF-I kernel is shared
  by both products; the reverb primitive is not (§5, §7b). §7a shows a chorus is fully
  specified by {LFO phase-accumulator → two LFO tables → LFO-swept delay tap → makeup gain} —
  every element already decoded, so the modulation family is implementable from the disasm.

Instruments: `dsp/tools/dsp_cformat_analysis.py`, `dsp_context_analysis.py`,
`dsp_motif_analysis.py`, `dsp_table_analysis.py`, `dsp_biquad_mechanisms.py`, `dsp_immediate_census.py`, `dsp_template_clusters.py`, `dsp_pointer_stride_analysis.py`. Graded:
correlational hypotheses, to be confirmed by a device arm (does register `lo12=0x000` feed a
DRAM limit/loop? does class-8 `post` round/saturate?) — but the discriminations (memory vs
gain vs filter; DF-I vs two-state; which LFO tables a voice reads) are measured across the
catalog, and §7's composition test is a construction, not a correlation.
