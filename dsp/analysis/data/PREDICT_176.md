# PRE-REGISTRATION §176 — is the D-RAM read empty because the POINTER is wrong, or because D-RAM IS EMPTY?

Written BEFORE the run. **Read-only probes, no mask bit, no behaviour change.**

## The fork

§174 MEASURED that at 5 of 6 class-A `ACT 0x15` sites whose source is `SRC 0x07 = mem[ptr]`, the
operand `L` is **identically zero** across 1.1–3.4 M firings while the coefficient beside it is
live. §168 read that as an **addressing** defect. There is a cheaper rival that has never been
stated, let alone tested:

* **H1 — the memory is empty.** D-RAM is mostly zero, so *any* pointer value returns 0 and the
  defect is upstream: nothing is writing the cells these reads consume.
* **H2 — the pointer is wrong.** D-RAM holds live data and the pointer lands on a dead cell.

⚠ §164 reported only the cells that **moved** (`01 02 04 06 07 0E` of 32). It never reported the
**static value** of the other 26, so it cannot distinguish "static and non-zero" from "static and
zero" — and the whole H1/H2 fork turns on exactly that. This is the same defect as §169 measuring
`m_p` at the consumer instead of at the producer: the instrument was pointed one step off.

## Falsifiers

* **F1 — the fork, two-sided and exhaustive.** Report every cell `0x00..0x1F` with its settled
  value, range and change-count.
  * ≥ 24 of 32 read **zero** ⇒ **H1**: the memory is empty, and §168's addressing story is
    unnecessary — the target moves upstream to whatever should be filling D-RAM.
  * A substantial set of non-zero static cells ⇒ **H2**: the pointer is the defect and §168 stands.
* **F2 — the pointer, per site.** Report `m_dp` at each class-A `ACT 0x15` word. Under **H2** the
  dead sites' `m_dp` must land **outside** §164's moved set `{01,02,04,06,07,0E}` and the live ones
  inside it. If dead sites point *into* that set, H2 is refuted even if F1 favours it — the read
  path itself is broken, not the address.
* **F3 — coverage.** The per-site table currently caps at **12** distinct words, first-come.
  Raise it to 24. If the count still saturates, the sample is still a sample and must be reported
  as one. CHORUS's own `0202A071D5` must appear; if it does not, coverage is still inadequate.
* **F4 — known-answer control.** §164's moved-cell list must reproduce exactly
  (`07: 0..8388598 chg 1128429`). If it does not, the build changed something other than the
  probes and the run is void.
* **F5 — ★ standing rule 1.** No output claim without `§70 ACCA` min ≠ max. Expected `min 0 max 0`.

## The NULL

If D-RAM were being written normally by the audio path, the *majority* of the low 32 cells would
carry non-zero values under a held chord — the reverbs alone allocate ladders through this space.
"Mostly zero" is therefore a real, surprising outcome and not the default expectation.

## ⚠ What neither answer licenses

Neither arm makes the chip audible, and neither decodes `ACT 0x15`. This picks the next target; it
does not move the output.
