# PRE-REGISTRATION §169 — is the table index the PRODUCT, `(scale × phase) >> 23`?

Written BEFORE the run. **Read-only probe, no mask bit, no behaviour change.**

## Why this candidate, and why it was missed

`lfo-ramp.md` §10 reads the idiom as `(coef × phase) >> 23` with `coef = 24`, giving an integer
0..23 into a 24-entry table. §167 then MEASURED `m_k = 24` at the class-6 site — **the scale is
already arriving in the multiplier input latch.** A multiply of the scale by the phase lands in
`m_p`, the product register.

⚠ §167 censused `m_ta`, `m_tb`, `m_k`, `m_l` — **and not `m_p`.** That is a gap in my own
instrument, not a measurement. The one register the arithmetic points at is the one I did not read.

## Falsifiers

* **F1 — the point of the run, two-sided.**
  * `m_p` at the class-6 site **VARIES with a change-count of order 1 129 389** (once per
    execution) ⇒ the index is the product, and `table[(m_p >> s) & 23]` becomes the candidate
    implementation.
  * `m_p` is **constant, or its change-count is ~1** ⇒ the product is not the index either, and
    every register at the site is now enumerated and dead. That is a real result: it would force
    the index to arrive through addressing (`addr8`/pointer) rather than through a register, which
    is a different and much narrower search.
* **F2 — magnitude.** If F1 arm 1 fires, `m_p`'s range must be consistent with `24 × phase` for a
  phase sweeping `0..8388598`: order `2 × 10^8` before any shift. A varying `m_p` whose range is
  wildly off that is *some other product*, not the index — the sign it would be a coincidence.
* **F3 — control that has already been answered.** `m_k` must still read `0..24` and `m_tb` must
  still read chg = 1. If either moves, the build changed something other than the probe and the
  run is void.
* **F4 — ★ standing rule 1.** No output claim without `§70 ACCA` min ≠ max. Expected `min 0 max 0`.

## ⚠ Pre-committed: what I will NOT do on a pass

F1 arm 1 does not authorise writing the lookup. `m_p` varying establishes only that a varying
quantity reaches the site. The shift `s` and the table base are separate unknowns, and the
discriminator for the whole construction is already fixed and must be pre-registered separately:
**226, not 240.**

★ And the change-count is mandatory, not optional. §167's `m_tb` reported range `0..5872025` —
which reads as "VARIES" — on a change-count of **1**. Range alone would have licensed the wrong
implementation twice now.
