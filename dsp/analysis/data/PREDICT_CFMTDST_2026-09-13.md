# PRE-REGISTRATION — the C-format immediate's DESTINATION, enumerated and swept

Written **before** the run. 2026-09-13.

## The target
C-format is now the largest entry in the queue: **68 words, every one trapping**, and `status()`
has called the operation MEASURED with the destination OPEN since it was written. 57 of the 68
obey the payload rule (`is_c40`, opcode `0x620`) and reduce to **five distinct shapes**, whose
`lo12` — the field `is_setvec` uses to pick the call-vector destination — takes four values the
vector predicate does not recognise: `0x44C` ×29, `0x000` ×16, `0x451` ×8, `0x1DA` ×2.

The destination was always *"1 of 6 enumerated"* and nobody ever ran the six.
`UPD6383_CFMTDST` = 0 latch (shipped) | 1 acc | 2 P | 3 tempA | 4 tempB | 5 mem[ptr] | 6 reg[addr8].

## Predictions

| | prediction | what it would mean |
|---|---|---|
| **H1** | the arm fires (`§109` count > 0) in every program that carries a C-format word | otherwise that program says nothing |
| **H2** | ⚠ **the sweep HAS POWER before it runs**: `acc` is known not to be inert — the site's own comment records a stuck presentation value of **4 988 928 = 2436 << 11**, exactly this line's shape. At least `mode 1` must move a census, or the instrument is blind | a blind instrument invalidates every row |
| **H3** ★ | **outcome A** — every destination leaves the censuses bit-identical ⇒ the immediate is never read and the 57 words are EXECUTABLE whatever it lands on (§96's lemma in the §108 empirical form) |
| **H4** ★ | **outcome B** — exactly one destination leaves the machine healthy while the others break a firmware/ROM criterion (the VOLUME cell, the LFO) ⇒ that one is the destination, by the §106 elimination |
| **H5** | outcome C — several differ and none is singled out ⇒ the criteria cannot separate them; the axis stays open and that is the result |

⛔ Whatever happens, this does not decode the 11 non-`is_c40` words: their payload rule is
explicitly family-local (`k3-pointers.md` §8 item 3 warns against extending it) and they are not
in the sweep's scope.
