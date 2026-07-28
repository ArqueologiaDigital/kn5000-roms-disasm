# The speculative register — everything the DEVICE now assumes without proof

NEC **uPD6383GF-3BA** (Technics SX-KN5000, IC311). Opened **2026-07-28**.

**This file is the tracking list the owner asked for.** Every reading below is
applied in `kn7000_mame/src/devices/cpu/upd6383/` **behind `DSPCFG` bit 1**, which is
a third, default-**OFF** setting. With the option Off, and with the pre-existing "On"
setting, the device is bit-identical to before.

★ **The strategy is deliberate** (owner, 2026-07-28): *"play sudoku with the
instruction set"* — fill the grid speculatively, reduce the search surface, and let
the contradictions that appear downstream point at the real proofs. A form that
**traps** produces no contradiction; a form that **executes wrongly** does.

⛔ **Nothing here is a decoding.** Grades are stated per row and never upgraded by
having been applied.

---

## 1. What it achieved

```
                                    conservative gate      speculative gate
   frames run                          1 200 001              1 200 001
   frames that TRAPPED                 1 200 001 (100.00 %)           0 (0.00 %)
   distinct undecoded forms                  123                      0
   undecoded words executed          257 817 024                      0
   returns USABLE                              0                962 880  (80.2 %)
   last frame                285 slots: 0 decoded         285 slots: 285 DECODED
                                                          0 partial, 0 traps
   frames whose pointer walk CLOSED            -            936 959 of 962 880
```

★★ **The emulated IC311 completes frames and returns usable output for the first
time.** ⛔ Whether that output is *correct* is entirely unestablished, and §3 says why
it cannot be assumed.

## 2. The register

| # | form / field | reading applied | grade |
|---|---|---|---|
| 1 | `f31 == 2` (`HI_ACC_HOLD`) | does **not** write `P` | ★ **MEASURED** — 14 of 19 ROM LFO ramp constants vs 11, strict superset, three controls held (§17) |
| 2 | mode 4 store target | `addr8`, not `mem[ptr]` | ★ **REFUTATION** of `ptr` — 3 fewer ROM constants in all 3 injection settings (§10.3, §14.3) |
| 3 | `src08` | `coef` | ★ **MEASURED** — reproduces the LFO's ROM step exactly (§8.1) |
| 4 | `lo12` bit 11 (alternate encoding) | **addressing only**, no ALU effect | ★★ **PROVEN** that it has no SRC/ACTION field (§9); that it does *nothing else* is a guess |
| 5 | c-format | 13-bit immediate → `acc` | **PART-MEASURED** — `status()` already calls it a 13-bit immediate; the destination is 1 of 6 enumerated |
| 6 | `hi12[3:1] > 2` | contributes no product | **PLAIN GUESS** — 1 of 4 enumerated (`f31hi = hold`) |
| 7 | `ACT 0x01/0x08/0x0C/0x11/0x16` | capture into tempA | **PLAIN GUESS** ×5 |
| 8 | `ACT 0x0D`, `ACT 0x0E` | capture into tempA | **PLAIN GUESS** — and §5.3/§6 show no context can discriminate them |
| 9 | `ACT 0x1A` | capture into tempB | **PLAIN GUESS** |
| 10 | `000.0.00.000` | NOP | **INFERRED** — the all-zero word is I-RAM's reset state |
| 11 | `000.6.18.4CD`, `000.6.20.407` | addressing only | **INFERRED** — the disassembler already annotates a table-lookup idiom; no table is modelled |
| 12 | `980.5.20.402`, `A00.0.00.015`, `A00.0.00.041` | no side effect | **PLAIN GUESS** ×3 |
| 13 | ★ `E30.C.00.404` (w73), `A3C.D.9F.287` (w78) | **present `acc` to the unit's output latch**, unit from `addr8` bit 7 | **PART-MEASURED / PLACEHOLDER** — see §3 |

## 3. ⛔ The load-bearing guess, named

Rows 13 are the ones the whole audio path now rests on, and they deserve their own
warning.

**What is measured**: `w73`'s `SRC 0x10` **is** the accumulator (ANCHORED), and
`addr8` bit 7 assigns the unit — `0x00` → unit 0, `0x9F` → unit 1
([`output-stage-decode.md`](output-stage-decode.md) item I).

**What is guessed**: the **arithmetic**. The identity was chosen because it is the
simplest thing that closes the frame.

★ **And before this, `m_do[][]` had NO WRITER AT ALL** — it was only ever zeroed and
read, so even a clean frame returned silence. That is itself a sudoku constraint: the
output latch must be written by something, and these two words are the only
candidates.

⛔ **[`output-stage-io.md`](output-stage-io.md) §10 and
[`bit11-family.md`](bit11-family.md) item B proved BOTH words undecidable by
comparison** — one IC311 site each, in their own form, nothing to compare against. So
this is a placeholder that lets the frame close, and **any audio the device now
produces is shaped by a guess about how the chip presents its output.**

## 4. How to use this list

1. **Every contradiction found downstream should be checked against this table first.**
   A wrong result is far more likely to come from a PLAIN GUESS row than from the
   decoded core.
2. **Promotion requires its own evidence**, never "it has been applied for a while".
3. **Deleting a row is a result too** — if a program can be made to contradict a
   guess, that is exactly the clue this strategy is fishing for.

## 5. Verification status

* The captured audio is **silent**, but that is **inconclusive**: the machine was idle,
  and an effect applied to silence is silence. **A real listening test needs a note
  played with `DSPCFG` = "On + SPECULATIVE ISA".**
* 210 241 frames (17.5 %) still end on the slot cap and 26 880 (2.2 %) on I-RAM
  overrun; only the 962 880 that end on the wait word are used.
* 25 921 complete frames do **not** close their pointer walk.
