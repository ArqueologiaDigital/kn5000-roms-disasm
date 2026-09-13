# PRE-REGISTERED: does §138's guard un-rail cell 0x06?  (§94)

Committed **BEFORE the run**.

## Why this is worth re-opening a REFUTED arm
§138 (`SPEC` bit 55) — *"a LOAD that fetches no coefficient brought no fresh product, so loading
from `P` is an erasure; treat it as HOLD"* — was **refuted** at the parametric EQ's **entry**
(§27/§28): it makes `iw85` a HOLD, the entry then triple-counts the input and `iw88`'s store rails
the pickup. It has been closed since.

§93 arrives at the *same predicate* from an unrelated direction. A saturation census built today,
followed backwards: `cell 06` takes **33.7 %** of every full-scale store → its writers are `iw19`
(1 706 614) and `iw39` (1 372 663) → `iw19` copies **ACCB** → ACCB is set at **`iw331`**, which is
`f31 = 0`, class 1, **fetches no coefficient**, and loads a `P` produced two words earlier from an
already-railed operand. **That is §138's predicate, exactly.** And §55 had independently observed
the same predicate names the killer in **13 of 14 body TAILS** — *different sites from the entry
that §28 measured breaking*.

⇒ two routes, one site. This run asks whether the guard fixes the tail without re-breaking the
entry.

## PREDICTIONS, registered in advance
| # | on `prog52_auto_wah`, true default + `SPEC` bit 55 | refuted if |
|---|---|---|
| **P1** | `cell 06`'s share of full-scale receipts **FALLS** | unchanged ⇒ the guard does not reach this path |
| **P2** | ★ **`iw39`'s receipt count is UNCHANGED** — it is DECODED (`ld.st ta,c+,(p)-1`) and must not move | it moves ⇒ the guard is too broad, which is what §28's refutation looked like |
| **P3** | `iw19`'s receipt count falls | unchanged ⇒ ACCB is still railed |
| **P4** | `accb` at frame start is no longer exactly `8 388 607 << 16` | still the rail |

## CONTROL — the site that refuted it
| # | on `prog39_parametric_eq`, same arm | |
|---|---|---|
| **C1** | the EQ's pickup cell `0x05` must **NOT** rail, and its five bands must still carry signal | if the EQ re-breaks, the guard is refuted again and the tail case must be scoped more narrowly (or abandoned) |

⚠ A pass does **NOT** promote §138. Its blast radius is **1 084 of 3 057 words (35.5 %)**, and a
tail-only variant is what §55 called *"fitting the rule to the data"*. A pass makes the tail case
**testable and corroborated**, not decided.
