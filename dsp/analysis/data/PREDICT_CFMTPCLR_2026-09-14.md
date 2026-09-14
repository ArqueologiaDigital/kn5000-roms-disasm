# PRE-REGISTRATION — a C-format word INVALIDATES the product register

Written **before** the run. 2026-09-14.

## Where this comes from
§109 measured that giving the C-format immediate the destination `P` takes the chorus LFO from
**153 Hz to 0.674 Hz** against a ROM constant of **0.5993** — the only thing all session to put
that number in the right order of magnitude — while **destroying** the per-unit hand-off cell.
§115 then settled the destination as `reg[lo12]` on a proven sub-case (`is_setvec`), so `P` is not
where the immediate goes.

⇒ the LFO improvement was a **side effect**: writing `P` overwrote the **stale product**, which
§102's trace already named as the contaminant — *"the gate word still LOADS the one-slot product,
and at the LFO ramp word that product is the PREVIOUS word's"*.

A C-format word issues no multiply, so the one-slot product after it is not that instruction's.
**Invalidating** it tests the side effect without the injection that wrecked the hand-off.

⚠ NOT `UPD6383_PCLR`. That is the GLOBAL policy *"clear P on any word that did not drive it"*, and
it is **refuted and default-off** — the LEDGER records it as *"a trade, not a decode"*. This is one
word FORM, and the C-format form is the one §109's measurement points at.

## The arm
`UPD6383_CFMTPCLR=1`, default OFF. `UPD6383_CENSUS_PERPROG=1`, chorus (TYPE 0), true default
otherwise.

## Predictions

| | prediction | what a miss means |
|---|---|---|
| **R1** | the arm FIRES (count > 0) | the run says nothing |
| **R2** ★★ | **THE KNOWN ANSWER**: the chorus phase cell `07` reads `mean step` at or near **114** — `floor(0.5993 × 2²³/44100)`, i.e. ~0.5993 Hz, period ~73 584 frames. Shipped it is **15 544 / 81.7 Hz** | the stale product is not the (whole) contaminant and the LFO defect is elsewhere |
| **R3** ★ | the per-unit hand-off `0x05` SURVIVES — live, ±2.9 M, ~175 660 changes — unlike §109's destination-`P` arm, which collapsed it to 14 | the arm is the same trade §109 refused, not a fix |
| **R4** | the **VOLUME** cell `0x06` stays written-once and unrailed | it breaks a firmware criterion |
| **R5** | if R2–R4 hold: the 10-program hand-off regression, **0 BROKEN**, before anything is promoted | a trade, not a decode |

## What a pass would unlock
★ §116 established the chain: **`f31` 3/4/5/7 is blocked on a clean LFO ramp, which is blocked on
this rate defect.** A pass makes the auto-pan discriminator — the instrument `f31-high.md` §4
item 1 asked for — usable for the first time.

⛔ A pass would not decode `f31` by itself, and it would not be a claim about the C-format word's
DESTINATION, which §115 settled separately.
