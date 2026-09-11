# N1′ result: the EQ coefficient memory, located by intervention (2026-09-11)

## What was done
Two-plus differential captures with `peq_gain.lua` (which navigates to the PARAMETRIC
EQ and drives one panel parameter), diffed by `dsp/tools/eq_gain_diff_probe.py`:
- **flat** control (NVALUE=0),
- **+12 dB band-0 gain** (NPARAM=2, NVALUE=24),
- **band-0 centre-frequency up** (NPARAM=0, NVALUE=24).

Evidence committed beside this note: `data/kn5000-dsp-eq-cram-{flat,boost,fc}-2026-09-11.txt`
(the C-RAM dumps). Regenerate via the recipe in the probe's docstring.

## Findings (MEASURED, from the intervention)
1. **The panel EQ-drive keys work.** The LCD moves from flat to the PEQ editor showing
   `Hz` and `G` fields, and C-RAM coefficients move — confirming the previously *inferred*
   PARAMETER (UP-2) / VALUE (UP-3) key mapping in `peq_gain.lua`.
2. **The parametric EQ's coefficient memory is C-RAM 0x00+**, laid out as **five 6-cell
   band groups** (band b = cells 0x00+6b … 0x05+6b), in a near-RBJ representation (each
   group has a ~+2.0 term = 2cos ω₀ and a −2.0 structural constant).
3. **Gain and frequency are separate, identifiable cells** (band 0):
   - a **+12 dB gain** edit moves **0x01** (and slightly 0x00, 0x02); it does **not** move
     0x03/0x04/0x05.
   - a **centre-frequency** edit moves **0x03** (hugely: +1.99 → −1.09) and 0x04 (and
     0x00, 0x02); it does **not** move 0x01.
   - so **0x03 is the dominant frequency coefficient** (2cos ω₀), 0x01 a gain coefficient,
     0x00/0x02 shared (the 1±α·A / 1±α/A combinations), 0x05 a fixed −2.0.
4. **The 5 bands are genuinely SPREAD, not clustered.** Their 0x03 (2cos) terms are
   1.9908, 1.9811, 1.9600, 1.9119, 1.7933 → ω₀ = 0.096…0.459 rad → centre frequencies
   **≈ 673, 966, 1405, 2091, 3219 Hz** (fs=44.1k, RBJ 2cos mapping) — a monotone,
   roughly-⅔-octave EQ progression.

## What this corrects
The **~13.5 kHz clustering red flag is RESOLVED as an artefact**: it came from interpreting
the cursor-walk *D-RAM operand* cells (entry≈0.75, c2≈0.498, c3≈0.504 — what the multiplier
reads at run time, `eq_coef_layout_probe.py`) as the biquad's b/a coefficients. The
panel-controlled *filter* coefficients live in **C-RAM 0x00+**, where band centres are low
and spread. So the b/a role work (N1) was chasing the wrong memory; the decode datapath
(P=(coef×L)>>6, etc.) is unaffected.

## Open (feeds N2)
- The **relationship between the uploaded C-RAM 0x00+ coefficients (near-RBJ, 2cos form)
  and the cursor-walk operands the multiplier actually uses** (0.75/0.5/0.49…). The DSP
  must transform one into the other; that transform IS the biquad realization question (N2).
  Reconciling them may decide the DF-II-family form more cheaply than a cross-frame state
  match.
- The exact 2cos→frequency and gain→coefficient mappings (RBJ assumed, not yet fit).
- Per-band grouping is inferred from the 6-cell C-RAM repeat + the band-0 intervention;
  confirming it needs a rig that moves the BAND cursor (peq_gain.lua only moves the
  PARAMETER cursor within a band).
