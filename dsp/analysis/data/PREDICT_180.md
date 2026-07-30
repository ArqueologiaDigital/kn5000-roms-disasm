# PRE-REGISTRATION §180 — PTRD-A: exclude `lo12 == 0x1C0` from the pointer walk

Written BEFORE the run. Mask bit **62** (`0x4000000000000000`), verified programmatically as clear
in the default and used at exactly one predicate. ARM = `0x7910E446A39B440F`, control = the shipped
default `0x3910E446A39B440F`.

## Provenance, and why it is worth a build

An exhaustive search over 21 364 736 candidate delta rules (sign × class-subset × one field gate)
returns `class4 ∈ {2,0xA}` **AND** `lo12 ≠ 0x1C0` as the **unique best non-degenerate rule** in the
whole space: it satisfies **C4 + P1 + P2 + P3** and nothing else does.

Independently re-verified here before building:
* the search's **known-answer control passes** — the current rule reproduces C1 `+5`, C2 `+1`,
  C3 `−3`, C4 `−2`, P1 30/38, P2 8/8, P3 8/9 exactly, and the absolute cells `0x76`/`0x7B`/`0x7E,0x7F`;
* its four 7/7 rules are **degenerate** — they freeze the pointer so every constraint reads `0 == 0`
  (`N cells [1,1,1]`). ★ A criterion that cannot fail, caught by the search's own author;
* **the gate is not vacuous**: 103 sites carry `lo12 0x1C0` on a pointer-moving class, and **36 of
  them have a non-zero `addr8`**, so they lose a real delta (`+66`, `−11`, `+69…+78`, `±1`…);
* the null: among non-degenerate rules that keep P1&P2&P3, **0.769 %** also satisfy C4 — PTRD-A is
  ~130× enrichment, not a coincidence, but also not a proof.

## Falsifiers

* **F1 — the gate fires.** A fired-count > 0. Zero means the predicate is unreached and the run
  says nothing.
* **F2 — ★ THE POINT, two-sided and bit-exact.** §176 measured CHORUS's index multiply
  `0202A071D5` at `m_dp 5..5`, `L 0..0`, `P 0..0`, with the phase in cell `7`.
  * `m_dp` becomes **`7..7`**, `L` stops being identically zero, `P` becomes of order `24 × phase`
    ⇒ PTRD-A is right and the modulation path is unblocked.
  * `m_dp` stays `5` (or lands anywhere but 7) ⇒ PTRD-A is refuted *in the emulator* even though it
    satisfies C4 in the static walk — which would itself be informative, because the static walk
    and the running machine would then disagree about the same quantity.
* **F3 — downstream.** §167 measured `m_tb` at the class-6 lookup as `0..5872025` with **chg = 1**.
  If F2 passes, `m_tb`'s change-count must rise to order 1.1 M (once per body execution). If `m_dp`
  reaches 7 but `m_tb` stays frozen, the defect is between them and PTRD-A is only half the fix.
* **F4 — known-answer control.** §179's D-RAM census must still show the phase ramping in cell `07`
  (`0..8388598`, chg ≈ 1.13 M) and 7 moving cells of 256. If the phase itself stops ramping, the
  gate broke the producer and the run is void.
* **F5 — ★ standing rule 1.** No output claim without `§70 ACCA` min ≠ max. **Expected `min 0
  max 0`** — this is not predicted to make the chip audible.

## ⚠ What a pass does NOT establish

C1, C2 and C3 remain unsatisfied by **every** non-degenerate rule in 21 million, and C3 is
**provably** unreachable: its second bank spans five words with two non-zero `addr8`s, so it demands
`77x − 80y = 0` with `x,y ∈ {0,1}`, and `gcd(77,80) = 1` forces `x = y = 0` — the inert case.
*(Verified independently: `x=y=1` gives exactly the `−3` C3 currently misses by.)*

⇒ Even a clean F2 pass leaves the phaser constraints unexplained. The search's own conclusion is
that the thing to drop is the **C1–C3 producer/consumer premise** (`-axes.md` §2.4, graded
INFERRED), not the arithmetic and not the origin. **Do not report a PTRD-A pass as "the pointer-delta
rule is solved".**
