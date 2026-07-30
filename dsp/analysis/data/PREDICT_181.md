# PRE-REGISTRATION §181 — bit 18 AND bit 62 together: the fifth jointly-unobservable pair

Written BEFORE the run. Arms verified programmatically: bit 18 and bit 62 are each clear in the
shipped default and each used at exactly one site.

```
  A  control  0x3910E446A39B440F     C  bit 18 only   0x3910E446A39F440F   (§168, measured inert)
  B  bit 62   0x7910E446A39B440F     D  BOTH          0x7910E446A39F440F   ★ never run
```

## Why the pair, and why §168's result does not forbid it

§168 armed bit 18 (`SRC 0x11 = mem[ptr]`) alone: it **fired 9 279 912 times and `m_tb` did not
move**, and I filed that as a refutation. ★ LEDGER rule 6 says that was the wrong grade —
*"a reading that measures INERT is a hypothesis about a MISSING CONSUMER, not a refutation"* — and
this is its **fifth** occurrence on this chip.

§180 supplied the missing half. With PTRD-A the cell the pointer sits on is **live**
(`05: −599858..8388607, chg 2772`) where it was identically zero before. **Bit 18 was reading
`mem[ptr]` out of an empty cell.** Neither reading is observable without the other.

The mechanism this is aimed at, and it is specific: `C63` is `SRC 0x11 / ACT 0x03` = `m_tb = L`.
Under the default `SRC 0x11` is **ACCB**, and CHORUS runs in **unit 0**, which writes `m_acc` and
never `m_accb` — so `m_tb` is loaded once from a register the body never touches. That is exactly
the `chg = 1` §167 measured.

## Falsifiers

* **F1 — both gates fire.** Two non-zero fired-counts. If either is zero the run says nothing about
  the pair.
* **F2 — ★ THE POINT, two-sided.** `m_tb` at the class-6 lookup, currently `0..5872025` with
  **chg = 1**:
  * chg rises to of order **1 129 389** (once per lookup execution) ⇒ the index reaches its
    consumer, and K2 becomes implementable for the first time.
  * chg stays ≈1 ⇒ `SRC 0x11` is not the route into `m_tb`, and the gap is elsewhere. That is a
    real result: it would exhaust the last modelled path into the index register.
* **F3 — known-answer control.** Arm **B** must reproduce §180 bit-exactly:
  `0202A071D5` with `L −599858..8388607 nz 1128428`, `m_dp 5..5`, `m_tb` chg 1. If B differs, the
  build changed something other than the arm and **the whole run is void**.
* **F4 — ★ standing rule 1.** No output claim without `§70 ACCA` min ≠ max. Expected `min 0 max 0`.

## ⚠ Deliberately NOT pre-registered: which side moves

§180's F2 said *"`m_dp` becomes 7 or PTRD-A is refuted"*, and the run satisfied the constraint by
moving the **data** to the pointer instead. A pass read as a refutation because I had guessed the
mechanism. **Here the criterion is stated purely as "does `m_tb` vary", with no claim about the
route it takes to get there.**

## The NULL

`m_tb` has been frozen at `chg = 1` in every run since §167, across five different mask
combinations. A change in its change-count is therefore not something this vehicle produces easily,
and "chg stays 1" remains the outcome I expect more.

## What a pass does NOT license

It does not implement the lookup, and it does not make the chip audible. It would establish that a
varying index reaches the class-6 word — the precondition §162 imposed and that has blocked K2 for
nineteen sections.
