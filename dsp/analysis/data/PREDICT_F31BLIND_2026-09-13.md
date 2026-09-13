# PRE-REGISTRATION — EMPIRICAL blindness for `f31 == 5`, and what it would license

Written **before** the multi-program run. 2026-09-13.

## What the first sweep found
Sweeping `f31 = 5` over the device's three expressible readings (`LOAD` / `ADD` / `HOLD`, SPEC bits
50-51) on the CHORUS, with `UPD6383_CENSUS_PERPROG=1`:

* **fired 1 601 712 times** — once per frame, the kernel's `w30`;
* **every census bit-identical** across the three (`§176` D-RAM, `§228` rise, `§162`, `§175`,
  the D-RAM write counts) — one md5 for all three;
* **and the FRAME TRACE DIFFERS**, so the arm demonstrably changed the machine's internal state.

⇒ at that site the accumulator output is **produced and never observed**. That is §96's blindness
lemma **measured** instead of argued — and note §96's STATIC walk refuses this site ("the site
itself stores acc"), so the static test is CONSERVATIVE and the empirical one can clear sites it
cannot.

⚠ `f31 = 4` fired **0** times in the chorus: no site executes, so that code is untested here and
the two arms aimed at it said nothing. Recorded rather than glossed.

## The test, over programs that carry their own `f31 == 5` sites
TYPES 2 (enhancer, 2 sites), 4 (phaser, 2), 15 (parametric EQ, 2), 18 (auto wah, 4) — each at
`LOAD` / `ADD` / `HOLD`, `UPD6383_CENSUS_PERPROG=1`, true default otherwise.

| | prediction |
|---|---|
| **G1** | the arm fires in every program (> 0) — otherwise that program says nothing and is dropped |
| **G2** ★ | in each program, **all three readings give bit-identical censuses** |
| **G3** | CONTROL THAT CAN FAIL: the **frame trace** must DIFFER between readings in every program. If the trace is identical too, the arm did nothing and G2 is vacuous |
| **G4** | ⚠ and a NEGATIVE control the first sweep already supplies: the same instruments DO move when a reading is wrong — `clr:after` killed the LFO, `LD@before` broke its rate, `clr:never` railed the VOLUME cell. These censuses are not insensitive |

## What a pass licenses, exactly
★ For a program where G1–G3 hold, that program's `f31 == 5` words are **EXECUTABLE**: their
accumulator output is not observed, so every reading of the code — including `f31-high.md`'s `negP`,
which no device arm can express — is equally unobservable, because all of them differ **only** in
that output.

⛔ It does not decode `f31 == 5`. ⛔ It licenses only the programs actually run: a program not in
the sample is not cleared by one that is. ⛔ And it says nothing about `f31` 3, 4 or 7.
