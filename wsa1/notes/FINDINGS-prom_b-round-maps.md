# prom_b 0xF5BBE7-0xF62BFF — the 96-step rounding maps

Status: **converted whole**, 28,697 bytes, one `.incbin` span closed. The byte
gate (`python3 scripts/analysis/assert_byte_identical.py`) passes.

Reproduce everything below:

    python3 notes/gen_prom_b_f5bbe7_module.py --checks   # 56 rows, all byte re-reads
    python3 notes/gen_prom_b_f5bbe7_module.py --maps     # the seven maps, run-length encoded
    python3 notes/gen_prom_b_f5bbe7_module.py            # the assembly in the .s
    python3 notes/prom_b_module_trace.py 0xF5BBE7 0xF62C00

---

## Why this span, and how its edges were fixed

`notes/prom_b_module_frontier.py` ranks thunk runs by contiguous unconverted
target extent. **T_F426E0-T_F42720** — 17 slots, 16,244 bytes, one span, summed
reference upper bound 62, the highest of any run — owns `0xF5EBD0`, which
`notes/prom_b_call_graph.py` ranks the second most-referenced unconverted target
in prom_b (x25, through `T_F4270C`). Those 17 slots are the **only** thunk slots
pointing anywhere into `0xF5BBE7-0xF62BFF`, so the run and the span are one
boundary seen twice.

⚠ **A linear decode does not pin a start.** `notes/prom_a_linear_decode_check.py`
makes the point and it applies here: a TLCS-900 decode resynchronises within a
couple of instructions, so "it decodes cleanly from 0xF5BBE7" would be true one
byte late as well. What pins this start is the **converted code above it** — the
file already transcribes through `0xF5BBE6`, and that byte is a `ret`. The end is
the `.incbin`'s own end, where the block store begins.

Four data islands sit inside the span, and **each one's end is a real transfer
target decoded in this transcription**, never a place where the decode happened
to resynchronise:

| island | ends at | what fixes the end |
|---|---|---|
| `0xF5D802` seven round-maps | `0xF5DAA2` | thunk target `T_F42700` |
| `0xF5DBB4` `RoundMap_Table` | `0xF5DBD0` | `jr T,0xF5DBD0` at `0xF5DBB2` — the jump OVER the table |
| `0xF5EE75` `IdentityMap_0_31` | `0xF5EE95` | `calr 0xF5EE95` at `0xF5ED63` **and** `0xF5F373` |
| `0xF621B9` `RoundMap_Bounds_A`/`_B` | `0xF62201` | `calr 0xF62201` at `0xF621AE` |

The check that would catch a mistake in any of them is asserted on every emit:
**all 17 thunk targets land on an instruction boundary of the transcription.** A
data island read as code resynchronises silently; a thunk target off a boundary
is the symptom.

---

## The seven rounding maps

`0xF5D802`, seven tables of 96 bytes, tiling `0xF5D802-0xF5DAA1` exactly.
`RoundMap_Table` at `0xF5DBB4` names them, and its **7 entries are fixed by the
`jr T,0xF5DBD0` that jumps over it** — 28 bytes / 4 — not by dividing a byte
extent by a guess.

Each map's entry *k* is

```
    entry[k] = g * round(k / g)        k = 0 .. 95
```

with one substitution: the value **96, which is off the end of the index range,
is written as 0x7F**. The grid *g* is not typed anywhere — it is read off each
map's own distinct values and the whole 96-entry table is then compared with the
formula byte for byte on every emit.

| map | g | steps |
|---|---:|---|
| `RoundMap_96` | 96 | 0, 0x7F |
| `RoundMap_48` | 48 | 0, 48, 0x7F |
| `RoundMap_24` | 24 | 0, 24, 48, 72, 0x7F |
| `RoundMap_12` | 12 | 0, 12, 24, 36, 48, 60, **73**, 84, 0x7F |
| `RoundMap_32` | 32 | 0, 32, 64, 0x7F |
| `RoundMap_16` | 16 | 0, 16, 32, 48, 64, 80, 0x7F |
| `RoundMap_8` | 8 | 0, 8, 16, 24, 32, 40, 48, 56, 64, 72, 80, 88, 0x7F |

The seven grids are 96, 48, 24, 12 and 32, 16, 8 — the divisions of 96 into
halves and into thirds.

⚠ **One anomaly, recorded and not corrected.** `RoundMap_12`'s entries 66..77
read **73** where the formula gives 72. Twelve bytes, one whole step, every one
off by the same +1. The other six maps match the formula at all 96 entries. This
is what the ROM says; `--checks` asserts the anomaly's exact shape (12 entries,
all `(73, 72)`) so that it cannot quietly change.

**How they are used.** `(0x0C7F)` selects a map: `ld L,(0x0C7F)` /
`sla 0x01,XHL` / `ld XDE,0x00F5DBB4` / `ld XIY,(XDE+HL)` at `0xF5DB9B-0xF5DBA8`,
result stored to `(0x0E12)` at `0xF5DBAE`. The doubling is why an entry stride of
4 works with a selector that this module only ever tests against **even** values
(`cp A,0` / `2` / `4` / `6` / `0x08` / `0x0a` at `0xF5DAD5-0xF5DAF3`). The map is
then indexed at `0xF5DC65-0xF5DC69`: `ld XHL,(0x0E12)` / `ld A,(XHL+IX)`, where
IX is the zero-extended byte just read from the buffer at `(0x126E)` and stored
to `(0x0E25)`; the mapped value goes to `(0x0E26)`.

⚠ **What the 96 steps COUNT is not established.** Nothing decoded here says it.
Neither is what selects `(0x0C7F)`, nor whether its highest legal value is 0x0C.
The names describe the measured arithmetic and claim nothing more.

⚠ The reader zero-extends a whole byte and does no upper-bound test, so an input
above 95 reads past the selected map. The 96 is the extent of the OBJECT, proven
by tiling; it is not a bound the code enforces.

---

## The boundary lists — a structure that checked itself

`0xF621B9`, 72 bytes, and the emitter **derives** them rather than reading them:

* for each map, the list of its step boundaries is `g/2 + k*g` for every value
  below 96 — sizes 1, 2, 4, 8, 3, 6, 12, summing to 36;
* `RoundMap_Bounds_A` (`0xF621B9`, 36 bytes) is exactly that concatenation, in
  `RoundMap_Table` order, byte for byte;
* `RoundMap_Bounds_B` (`0xF621DD`, 36 bytes) is the same with **every group
  rotated right by one** — the last boundary moved to the front.

Then the cross-check, and it is a check rather than a fit because the group sizes
were derived from the maps *before* any address was looked at: **twelve sites in
prom_b spell an address inside the island as a 32-bit word, and all twelve are
group starts** — six in `_A` and six in `_B`, groups 1..6 of each. Group 0 has a
single entry and is not addressed.

⚠ Which list is used for what is **not** established. `_B` being `_A` rotated is
the shape of a "previous boundary" table beside a "next boundary" one, but
nothing decoded here says which way round.

---

## `IdentityMap_0_31`

`0xF5EE75`, 32 bytes, entry *k* = *k*. Read by three sites, each
`ld XIX,0x00F5EE75` / `ld L,(XIX+HL)` — the instructions at `0xF5ED50`,
`0xF5F360` and `0xF600DD` — all storing the result to `(0x0D44)`. Its length is
fixed by the two `calr 0xF5EE95` that step past it.

⚠ Why an identity map exists at all is not established. A table that returns its
own index changes nothing at run time, so it is either a hook a later build was
meant to fill or a documented-but-unaltered index. The name describes the content
for exactly that reason.

---

## The routines

113 of them, every one `sub_XXXXXX` with a computed header claiming only the
entry point, per this tree's rule that a stated gap beats a plausible guess. Each
header's `Called from`, `Touches` and `Calls` lists are read out of the proven
transcription's own decoded comments — they are facts about the text, not
inferences — and the thunk reference counts are the opcode-anchored **upper
bound**, never call counts.

Naming what 113 routines DO needs `(0x0C7F)`, `(0x0E02)` and the buffer at
`(0x126E)` decoded, and nothing in this lane does that yet.

---

## Verified falsifiable — and one check that is weaker than it looks

Two perturbations of `notes/gen_prom_b_f5bbe7_module.py`, each run through
`--checks`:

| perturbation | result |
|---|---|
| move `IdentityMap_0_31`'s start one byte (`0xF5EE75` → `0xF5EE76`) | **3 FAIL**, exit 1 |
| grow that island by one byte so the code segment starts one byte LATE, keeping the LAYOUT tiling | **4 FAIL**, exit 1 |

⚠ **What the second probe exposes.** It was caught by the *label* checks —
`FORCE 0xF5EE95` is no longer a boundary, and `0xF5EE95`/`0xF5EE9A` are labels
that are no longer instruction boundaries — and **not** by "every thunk target is
an instruction boundary". None of the 17 thunk targets moved, because a TLCS-900
decode started one byte late resynchronises within a couple of instructions and
then agrees with everything downstream. So the thunk-boundary check is necessary
and is **not sufficient**: on its own it would have passed a wrong segment start.
What actually holds the split together is the combination of it with the
requirement that every label — data label, `FORCE` label and every `call` target
— be an emittable instruction boundary, and that no code label fall inside a data
segment. Recorded because the opposite belief is the easy one to hold.

---

## Frontier, before and after

| | before | after |
|---|---:|---:|
| unconverted prom_b thunk **slots** (`prom_b_call_graph.py`) | 364 | **347** |
| unconverted **distinct targets** | 356 | **339** |
| runs with unconverted targets (`prom_b_module_frontier.py`) | 34 | **33** |
| real `.incbin` spans in prom_b | 125 | **124** |
| substantive bytes (`source_coverage.py`) | 81,798 | **108,130** |

364 − 347 = **17 slots**, and 356 − 339 = **17 distinct targets** — for this span
the two units agree, because none of its 17 slots shares a target with another.
Reproduce both, from the ROM rather than from two printouts:

    python3 notes/prom_b_round2_frontier_delta.py

⚠ **State the unit.** `prom_b_call_graph.py`'s header said *"UNCONVERTED prom_b
thunk targets"* until 2026-08-25 while what it counted was one row per **slot**.
For this span the numbers coincide; for the other span this round converted
(`0xF44018-0xF477FF`) they do not — 64 slots, 62 distinct targets — so a
reconciliation done in the wrong unit is off by two with nothing to show why. The
header now prints both.

⚠ **`source_coverage.py`'s `.incbin spans` column is not the span count.** It is
`text.count(".incbin")` (`scripts/analysis/source_coverage.py:52`), a raw
substring count, so every *prose mention* of `.incbin` in a comment inflates it.
For prom_b it printed 136 where the real number was **124**: `grep -c '\.incbin'`
also gave 136, while `grep -cE '^\s*\.incbin'` — the directive, anchored — gave
124. The 12 extras were prose. *(Re-measured 2026-08-25 after round 3: the raw
count is now **140** and the anchored count is still **124**, because round 3
replaced one `.incbin` directive with one `.incbin` directive and its block
comment mentions the word four more times. The gap grows with every honest
comment, which is the point.)* `notes/prom_b_call_graph.py` parses the directive
properly and
self-checks its byte total against `source_coverage.py`, so its span count is the
one to quote. The bytes columns are unaffected. The fix belongs in
`scripts/analysis/source_coverage.py`, which this lane may not edit.
