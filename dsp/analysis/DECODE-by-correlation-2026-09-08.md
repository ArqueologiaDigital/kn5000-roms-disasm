# Decoding OPEN fields by cross-program correlation

**Date 2026-09-08.** A creative pass looking for discriminators the raw corpus does not
supply. The idea: the effect NAMES and the program STRUCTURE (delay-tap count, coefficient
count) are independent variables; if an OPEN field's value *tracks* one of them across the
whole catalog, that correlation is a discriminator — it says what the field is *for*, even
where a single occurrence could not. Two results, both from the committed `.dsm` of both
products, no emulator, no hardware.

## 1. The C-format immediate DESTINATIONS are decodable, and they are not coefficients

The C-format word loads a MEASURED 13-bit immediate into a register named by `lo12`; the
destination was always "UNKNOWN". Correlating each destination's loaded value against
program structure (`dsp/tools/dsp_cformat_analysis.py`) separates three distinct roles:

| dest `lo12` | words | r vs delay-taps | r vs cMACs | values | proposed role (GRADED, correlational) |
|---|---:|---:|---:|---|---|
| **0x000** | 195 | **−0.81** | 0.00 | 384/480/704/896 | a **DELAY / MEMORY** structural parameter — it tracks the delay-tap count and is *independent of the coefficient count*. Reverbs (40 taps) → 384; simple effects (2 taps) → 896; values are 3/5/7 × 128. |
| **0x44C** | 46 | −0.01 | +0.17 | 800/992 | a **near-unity GAIN / makeup-scale** (0.78 / 0.97 of 1024) — no structural correlation, sits just under 1.0. This is the chorus's "A = 25" (800 = 25 × 32). |
| **0x451** | 8 | **−1.00** | **+0.98** | 480/672 | a **FILTER-structure** parameter — tracks the coefficient-MAC count almost perfectly. |

⇒ **The C-format instruction is not one thing.** Its `lo12` selects *what the immediate
parameterises*: memory/delay sizing (0x000, the common case), a gain (0x44C), or a filter
count (0x451). That is a real advance over "destination UNKNOWN": the destination is now a
graded, discriminated hypothesis. It also tells the decode that **the 195 words at 0x000
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
  0x0E in **226/274 (82%)**, and ACT 0x0E is *immediately* preceded by ACT 0x0D in **226/304
  (74%)**. Two back-to-back state updates are exactly a biquad's `z⁻¹`/`z⁻²` pair — this is a
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

- **`MMM` / `MMMM` (302 / 164)** — coefficient runs = biquad / filter sections.
- **`zz` (the biquad two-state pair, 155 `zza`)** — always adjacent (§3).
- **`WC` / `WCWC` (124–127)** — a delay-tap **WRITE** immediately followed by a **C-format
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

## Why this matters for decode + implementation

- The 195 C-format-0x000 words (6.4 % of the WSA1R corpus, and a chunk of the KN5000's) get
  a *structural* reading — a decode gain that costs no hardware and no speculation beyond the
  correlation, which is itself the evidence.
- It reframes the delay/reverb implementation: the per-effect delay geometry is set by these
  0x000 immediates (a memory/limit parameter) plus the descriptor block, not by the program
  words' addresses — consistent with the "address is in the descriptor, not the word" finding.
- The reverb clustering says an emulator needs only ~4 reverb programs + the coefficient
  presets, not 13 distinct algorithms.

Instruments: `dsp/tools/dsp_cformat_analysis.py`. Graded: correlational hypotheses, to be
confirmed by a device arm (does register `lo12=0x000` feed a DRAM limit/loop?) — but the
discrimination (memory vs gain vs filter) is measured across the catalog.
