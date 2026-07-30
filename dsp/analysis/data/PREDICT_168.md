# PRE-REGISTRATION §168 — re-arm bit 18 (`SRC 0x11 = mem[ptr]`), which §113 never validly tested

Written BEFORE the run. ARM `0x3910E446A39F440F`, control the shipped default
`0x3910E446A39B440F`. Bit 18 verified **clear in the default** and used at **exactly one site**
(`upd6383.cpp:2369`), enumerated programmatically — §129's double-booking was moved to bit 38 by
§130, so the confound that voided §113 is gone.

## Why this is a legitimate re-arm, not a retry of a dead end

§112 §2 records *"⚠⚠ §113 WAS NOT VALIDLY TESTED — a mask collision"* and §113 is off **because it
was never tested**, not because it was refuted. ⚠ `LEDGER.md` Tier 1 cannot currently tell those
two states apart; that is a real gap in the index and is being fixed.

## The chain this is aimed at

* §165: the LFO phase RAMPS in D-RAM cell `0x07` (`0..8388598`, chg 1 128 429 / 1 392 430).
* §166: `C63` + class-6 is ONE idiom, 53/53 both ways, and `C63` = `SRC 0x11 / ACT 0x03` = `m_tb = L`.
* §167: at the class-6 site `m_tb` = `0..5872025` but **chg = 1** — one step, then constant.
  `5872025 / 2^23 = 0.700000`, a coefficient, not a phase. `m_ta` and `m_l` are 0; `m_k` = **24**,
  the index scale `lfo-ramp.md` measured, confirmed live.

If `SRC 0x11` is `mem[ptr]` and the pointer is on the phase cell, `C63` loads the ramping phase
into `m_tb` and the routing gap closes in one word.

## Falsifiers

* **F1 — the gate fires.** A fired-count > 0. Zero means the site is unreached and the run says
  nothing either way.
* **F2 — TWO-SIDED, the point of the run.**
  * `m_tb` chg goes from **1** to of order **1 129 389** (once per class-6 execution) ⇒ the phase
    reaches `m_tb`, and `table[m_tb]` becomes implementable.
  * `m_tb` chg stays ≈1 ⇒ the pointer is **not** on the phase cell at `C63`, and the gap is
    upstream. That is a real result and it redirects to *which* cell the pointer is on.
* **F3 — known-answer control.** Bit 18 changes a **SRC decode**, not addressing. §162's
  `m_dp 12..12 | cursor 9..9` must be **unchanged**. If `m_dp` moves, bit 18 is doing something
  other than what it says and the run is void.
* **F4 — upstream null.** §164's cell `0x07` census must be unchanged (`0..8388598`, chg
  1 128 429). Bit 18 must not perturb phase *generation*; if it does, F2 is confounded.
* **F5 — ★ standing rule 1.** Any claim about output requires `§70 ACCA` min ≠ max. Expected
  unchanged at `min 0 max 0`; this run is not expected to make the chip audible.

## ⚠ What a pass does NOT license

`m_tb` varying does **not** authorise writing the lookup. It authorises the *next* pre-registration,
which must also fix the table base and the `(coef × phase) >> 23` scaling, and whose discriminator
is already set: **226, not 240**.
