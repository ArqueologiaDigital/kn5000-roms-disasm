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

## Reconciled: C-RAM coeff = 2 × cursor operand (MEASURED, exact)
The "two representations" are one. In the SEED8 capture — the one trace that dumps BOTH the
C-RAM and the cursor walk — the C-RAM cell at each cursor index is **exactly 2.000000×** the
cursor `coef` the multiplier reads (41/41 cells, max deviation 0.0; `eq_cram_operand_reconcile.py`).
So the multiplier operand = **C-RAM[cursor] >> 1**; there is no transform beyond a 1-bit
(Q-format) scale. The biquad's real coefficients ARE the near-RBJ C-RAM 0x00+ set, read halved.
(Note SEED8 and the clean peq-default are different EQ *presets* — SEED8's band-0 2cos term is
0.995, peq-default's is 1.99 — but the C-RAM↔operand factor of 2 is preset-independent.)

## Gain calibration — the design parameters are recoverable (2026-09-11, MAME port)
`eq_spectral_ab.py` proved the raw cells cannot be read as a direct-form biquad H(z) (that
needs the walled N2 realization). But the **design parameters** are recoverable, which is all
the HLE port needs (it *synthesises* textbook RBJ peaking biquads, exactly as `dsp/hle/` does):
- **Frequency (SOLID):** `cell 0x03 = 2·cos ω₀`. Band 1's 0x03 gives 966 Hz == N1′ band-1
  centre; universal across bands.
- **Gain (STRONG, band-0-calibrated):** the pure, frequency-INDEPENDENT gain signal is
  **(c1 − 0.5)**, where c1 = cell base+1. That cell is **exactly 0.5 (0x200000) at 0 dB** —
  for band 0, band 1, *and* under a frequency-only (FC) edit — and moves only under a gain
  edit (0.50654 at +12 dB). So **A² = 1 + G·(c1 − 0.5)**, G = 455.7 fit to the +12 dB capture
  (A²=3.98). NB **(c1 − c2) is the WRONG signal**: c2 moves with frequency, so an FC edit
  misreads as +31 dB — de-entangling to (c1 − 0.5) is what fixes it.

This is validated **offline against all three captures** by `dsp/tools/eq_rbj_reconstruct_ab.py`
(flat→0.0 dB, +12 dB→+11.9 dB at 673 Hz, FC→0 dB with the design centre migrated up). It is the
formula shipped in `kn7000_mame` `kn5000_tonegen.cpp` (the `eq_hle` insert, default OFF, DSPHLE
port), pending the in-emulator spectral A/B. SPECULATIVE: that the same G holds for bands 1-4
(only band 0 was driven); the 0.5 baseline is confirmed shared. Q is assumed 2.0 (sets
bandwidth only; the A/B's peak-height check is Q-independent).

## Open (feeds N2)
- The realization question now reduces to: **which biquad structure does the cursor-ordered MAC
  sequence implement over these near-RBJ coefficients (read C-RAM>>1)?** Answerable from the
  decoded datapath + the coefficient identities — potentially without a cross-frame state match.
- The exact 2cos→frequency and gain→coefficient mappings (RBJ assumed, not yet fit).
- Per-band grouping is inferred from the 6-cell C-RAM repeat + the band-0 intervention;
  confirming it needs a rig that moves the BAND cursor (peq_gain.lua only moves the
  PARAMETER cursor within a band).
