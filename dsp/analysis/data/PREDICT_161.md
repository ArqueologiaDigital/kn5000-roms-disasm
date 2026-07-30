# PRE-REGISTRATION §161 — the delay word's `addr8` is a DIRECTION field, not a store address

Written BEFORE the run.  Binary built, mask bit 61 = `0x2000000000000000`;
ARM = `0x3910E446A39B440F`, control = the shipped default `0x1910E446A39B440F`.

## Claim

`upd6383.cpp:2979` computes ACTION 0x07's mode-1 store destination as `addr8(word)`.
For a class-1 ESCAPE word that field is the delay direction code, not a register
address.  CHORUS's four delay READs `880.1.20.2C7` therefore store to register cell
`0x20` — which is LFO wavetable index 3.

## Arithmetic done in advance, from the 23 surviving cells only

A least-squares sine fit over the 22 good entries (index 3 excluded from the fit)
returns `A = 7 969 178 = 0.9500000 x 2^23` and `phi = 0.100000 rad`, with a maximum
residual of **2 LSB over 22 cells**.  Neither constant was assumed; both fell out.

## Falsifiers

* **F1 — aim.** `§161 FIRED` must be **4 513 920**, byte-identical to §153's tapmod
  count, because they are the same four words.  A count of 0 means the gate never
  matches; 26/frame means it caught the ACT-0x15 and ACT-0x0B delay words too and
  the diagnosis is wrong.
* **F2 — the value.** Cell `0x20` must read **`+6 169 475` (`0x5E2383`)**, and the
  window must go 36/36 non-zero.  A different non-zero value refutes "the microcode
  writes the sine here"; still zero refutes the whole causal chain.
* **F3 — collateral.** The store is re-aimed to `m_dp`, not deleted.  If `m_dp`
  also points inside `0x1D..0x40`, the hole simply moves and F2 passes for the
  wrong reason.  The full non-zero-cell census must be diffed against §160's 38
  cells: the ONLY admissible change is `0x20` appearing.  Any other cell changing
  value fails F3 even if F2 passes.
* **F4 — the null.** The control run (bit 61 clear) must still show `0x20 = 000000`
  and 35/36.  If the control has changed, something other than this gate moved.

## What a pass does NOT establish

It does not make the chip audible, and it does not implement the class-6 lookup.
It removes the reason the lookup could not be built: the table is the lookup's data.

## Cross-check available afterwards

`|predicted index 3| / |measured index 15|` is already **1.000000** — the antipode
reads `-6 169 476`.  If the run returns `+6 169 475` that is a third independent
agreement (fit, antipode, microcode) on a number never fed into any of them.
