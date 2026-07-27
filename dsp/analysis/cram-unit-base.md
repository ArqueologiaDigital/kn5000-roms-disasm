# The cursor→C-RAM map was missing its per-unit base

NEC **uPD6383GF-3BA** (Technics SX-KN5000, IC311). Date: **2026-07-27**.
No hardware. Static analysis and the ROM corpus only.

**Why this note exists.** [`adjudication-round7.md`](adjudication-round7.md) STEP 4b:

> ** A SECOND, INDEPENDENT BLOCKER, AND IT IS NEW. ** The twelve 133-word
> reverbs resolve 0 of 33 coefficient words each — the cursor-to-C-RAM map that
> works for the 48-word blocks does not work for them. So of the 13 algorithms
> that CAN close a loop, exactly ONE can be executed today. **Fixing that map is
> the cheapest single thing anyone can do for this question.**

It is a missing addend. `dsp_disasm.cursor_addresses()` returns **k**, the count
of class-A words since the last `rstcur` — an *offset*, not an address — and its
own docstring has said so all along: *"`base` is added by the caller for the
unit-1 reverb bank (0x90)."* `lfo_ramp.py` adds it at all six of its call sites
(`base = 0x90 if la == 200 else 0x00`). `delayline.coefs_of()` — the round-7
two-address harness — did not.

Tool: [`../tools/delayline.py`](../tools/delayline.py) (`cram_base`, `unit_of`,
`coefs_of`).

```
python3 dsp/tools/delayline.py all        # seven self-tests, all PASS after the fix
```

Labels: **MEASURED** / **PROVEN BY CONSTRUCTION** / **FORCED** / **CONSISTENT** /
**OPEN**.

---

## 0. Result

| # | statement | label |
|---|---|---|
| **A** | ★★ **The C-RAM cursor is UNIT-RELATIVE: base `0x00` for unit 0, `0x90` for unit 1.** Population 91 IC311 programs, 1546 class-A words. Unit 1 (12 reverbs, 33 class-A words each): **0 of 33** resolve at base `0x00`, **33 of 33** at base `0x90`, in **12 of 12** algorithms. Their C-RAM keys run `0x90..0xB4` (`0xB5` in algo 25) and **nothing below `0x90`**. | **MEASURED** |
| **B** | ★★ **Algorithms executable end-to-end: 78 → 90 of 91.** Every coefficient-consuming word now resolves in 78 unit-0 bodies *and* all 12 unit-1 reverbs. | **MEASURED** |
| **C** | ★ **The two routes to the unit agree exactly.** The `(unit, load)` cross-tab over all 91 programs is `{(0, 84), (1, 200)}` and nothing else, so `ctx()`'s unit and `lfo_ramp.algo_to_image()`'s load address are one fact, not two conventions. | **MEASURED** |
| **D** | ★★ **The fix cannot move any published unit-0 number, by construction:** for unit 0 the base is `0x00` and `0x00 + k == k`, so `coefs_of` returns the identical list it returned before. All seven `delayline.py` self-tests still PASS, including the harness validation round 8 audited. | **PROVEN BY CONSTRUCTION** + **MEASURED** |
| **E** | ★ **RULE 7 — the rival is separated, and it is the tempting one.** "Always add `0x90`" also fixes the reverbs, and is **rejected 79 of 79** on unit 0 (0 fully resolve). The base is genuinely per-unit; no global constant can be right. | **MEASURED** |
| **F** | **The defect is confined to one function.** The three other base-free C-RAM lookups in `dsp/tools` — `adjudicate6.py:243`, `action00_discriminate.py:844/880/940` and `peq_banks()`, `gate_settle.py:1565` — read algorithms `{9, 33, 35, 39, 99}`, **all load 84** (verified), where base `0x00` is correct. Nothing else needs changing. | **MEASURED** |
| **G** | **Residue, named and not fixed:** algorithm 10 (MULTI TAP DELAY) resolves **15 of 18** class-A words at the correct base. Pre-existing, unrelated to the base — the same algorithm whose fourth tap `dram-matching.md` could not place. | **OPEN** |

---

## 1. The measurement

```
algo u load  nw  #A base0 base90 cramLo cramHi
   1 0   84   70   19    19      0   0x00   0x13
   3 0   84   99   26    26      0   0x00   0x1A
   8 0   84  102   22    22      0   0x00   0x1A
   9 0   84   48   18    18      0   0x00   0x12
  10 0   84   68   18    15      0   0x00   0x0E     <- the residue, item G
  16 1  200  133   33     0     33   0x90   0xB4
  ...                                                  (algos 16..27, identical)
  25 1  200  133   33     0     33   0x90   0xB5
  27 1  200  133   33     0     33   0x90   0xB4

UNIT 0 (n=79): fully resolved at base 0x00 -> 78 ; at base 0x90 -> 0
UNIT 1 (n=12): fully resolved at base 0x00 ->  0 ; at base 0x90 -> 12
class-A words: unit 0 = 1150, unit 1 = 396, total 1546
```

The unit-1 column is not a near miss that a better base would improve — the
reverbs' C-RAM streams contain **no key below `0x90` at all**, so at base `0x00`
every lookup misses and the program is unexecutable. That is why the count was
exactly zero rather than partial, and why it read as "the map does not work for
them" rather than as an off-by-something.

## 2. The control, which says NO

Rule 1. The same code path, forced to base `0x00` on unit 1:

```
CONTROL -- same code forced to base 0x00 on unit 1:
  12 of 12 reverbs resolve ZERO words.  The fix can fail.
```

And rule 7's rival, scored where it disagrees: "always add `0x90`" fixes all 12
reverbs and breaks all 79 unit-0 bodies. Both directions are demonstrated, so
this is not a change that could only ever look like an improvement.

## 3. What it unblocks

`adjudication-round7.md` names the reverb ladder as **the only remaining
context** for `ACTION 0x19`, for the accumulator adder's second leg, and for
[`schroeder-topology.md`](schroeder-topology.md) §0-C's re-opened challenge —
and reported that only **one** of the 13 algorithms with a closed executable loop
could actually be run. The twelve that could not were the twelve reverbs, for
this reason alone.

They can be run now. That does **not** by itself settle any of those three
questions: `adjudication-round7.md` is also explicit that the reverb references
in `schroeder-topology.md` were matched on the one-cell line and have to be
re-derived on a memory that delays before the ladder can force anything. This
note removes a blocker; it does not answer the question behind it.

## 4. Predict-then-check

- **P1 HIT** — I predicted a missing per-unit base rather than a broken map, on
  the strength of `cursor_addresses`' own docstring and `lfo_ramp`'s six call
  sites. It is exactly that.
- **P2 MISS** — I predicted the other base-free lookups would need the same fix.
  They do not: all four read load-84 algorithms, verified rather than assumed.
- **P3 MISS** — I predicted unit 0 would come out 79 of 79 and that any residue
  would be the base. It is 78, and algorithm 10's three unresolved words have
  nothing to do with it (item G).
- **P4 HIT** — the fix is provably inert on unit 0, so nothing published moves.

## 5. Not applied to the emulator

No MAME source, no disassembler, no `.dsm`. `dsp/verify.py` **BYTE-MATCH OK**.
Frame tally unchanged: 107 / 92 / 86 of 285, closure residue +0, 0 of 1 536 001
frames complete. This is analysis machinery, not a decode — nothing here makes a
trapping word execute.
