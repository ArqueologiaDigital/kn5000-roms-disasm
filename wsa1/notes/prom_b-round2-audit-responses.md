# Round-2 audit: what the prom_b lane fixed

prom_b lane, 2026-08-25 (round 6). Three of the audit's fifteen findings name this
image — **F2**, **F10** and **F11** — and **F14** is a model-behaviour entry that
the tree had already disclosed itself. This file records what was done about each,
with the command that re-checks it. The byte gate
(`python3 scripts/analysis/assert_byte_identical.py`) passes after every edit.

---

## F2 — "13,357 decoded instructions" was 13,357 **bytes**. FIXED.

The audit is right and the error was in two places: the banner in
`prom_b/wsa1_prom_b.s` and §head of `notes/FINDINGS-prom_b-f0ea9f-module.md`.
13,357 is the byte total of the 0xF0EA9F block's 21 code segments — it is printed
six lines below the banner claim, in a column headed `bytes`, in a table that sums
to 21,141.

**Nothing in the tree had computed an instruction count at all**, so the fix is not
a corrected sentence but a script:

    python3 notes/prom_b_instr_census.py --module f0ea9f --last
    python3 notes/prom_b_instr_census.py --module f65000 --last

It takes the block's FROZEN LAYOUT from its generator, walks every `code` segment
with the same decoder the layout used, and then **cross-checks the decoded
instruction starts against the `.s`'s own `; ADDR` comments** — the sets must be
equal, which catches a splice that dropped a line as well as a decoder that
drifted. Both blocks come back 0 missing / 0 extra:

| block | code bytes | INSTRUCTIONS | bytes/instr |
|---|---:|---:|---:|
| 0xF0EA9F-0xF13D33 | 13,357 | **5,067** | 2.64 |
| 0xF65000-0xF6D001 | 25,900 | **9,112** | 2.84 |

⚠ **The audit's own hand count, 4,675, is a floor rather than the number**, and the
reason is worth recording because it will recur: it split lines into "mnemonic" and
"`.byte`/`.long`", and an instruction llvm-mc cannot encode is emitted as

    .byte 0xEE, 0x0C, 0xF8, 0xFF	; F0EA9F  link XIZ,0xfff8

which is one instruction, not four data bytes. **392 of this block's 5,067
instructions are of that kind** (instruction lines inside the LAYOUT's code
segments whose directive is `.byte`). The audit's intermediate figures reproduce
exactly against the current `.s` — 6,042 lines carrying an address comment in
0xF0EA9F-0xF13D33, 1,367 of them `.byte`/`.long`/`.ascii`, difference 4,675 — and
**4,675 + 392 = 5,067**, so the two counts differ by precisely the
`.byte`-encoded instructions and by nothing else.

The `--last` flag prints the final code segment in full (0xF1173E+3432, 1,344
instructions, last one 0xF124A5) so "the check passed" cannot mean "the check
stopped early".

## F10 — "16 → 14 runs" came from a different tool than the one cited. FIXED.

At the tree the audit read, `notes/prom_b_round5_frontier_delta.py` printed
**before 15, after 13** while `notes/prom_b_module_frontier.py` printed **14**.
The script's docstring already warned that its grouping differs from the tool's —
and that was not enough, because a warning does not stop a number being copied.

So the script now **runs `prom_b_module_frontier.py` itself**, prints both totals
side by side, and asserts the relationship as a sixth check. On the tree as it
stands after round 6 — which retired one more run, so both columns have moved
down by one — it prints:

    runs with unconverted prom_b targets:
      THIS script's grouping (maximal `jp` spans): before 14, after 12
      notes/prom_b_module_frontier.py, LIVE, on the same tree: 13

    prom_b_module_frontier.py's live total is this script's AFTER + 1   PASS

and its seven original assertions still PASS unchanged. ⚠ That drift is the point:
the pair (15, 13) was correct only against one tree, which is why the check is a
RELATION between the two tools rather than a remembered pair of numbers.

⚠ **And writing the check corrected the docstring too.** "The two differ by a run
at each end" reads as +2 and the true relation is **+1** — one run present in both
columns. Round 4's figures say the same thing (19→15 against the tool's 20→16), so
the wording, not the measurement, was the defect. A first draft of the check
asserted +2 and FAILED, which is how it was caught.

## F11 — the effect-table script was cited by a flag it does not have. FIXED.

The flag is `--checks`, not `--verify`, and `--verify` used to fall through to the
EMIT path: 4,000 lines of assembly, no error, nothing that looks like a check
result. `notes/gen_prom_b_effect_tables.py` now rejects any unrecognised flag:

    $ python3 notes/gen_prom_b_effect_tables.py --verify
    unknown flag(s) --verify -- this script takes --checks --names --bands
    --stride (the checks flag is --checks, NOT --verify)      [exit 1]

`--checks` still passes 14/14.

⚠ The audit's second half of F11 — that "the 56 effect algorithms with slot
numbers" is a stronger claim than the tree's own header — needs **no tree change**,
and this file says so rather than quietly agreeing: `EffectNames_F147AC`'s header
already reads *"⚠ Unknown: that entry k is effect algorithm k … 128 and 128 is a
CORRESPONDENCE, not a decoded fact"*, and the audit re-derived the data itself
(56 real / 72 placeholder, entry 0 `  NO OPERATION  `, entry 127 `   ----------   `)
and found it exact. The overstatement was in a report, not in the tree.

## F14 — the "wrong 8 times out of 8" immediate-seeding figure. NO CHANGE, BY DESIGN.

`notes/FINDINGS-prom_b-f0ea9f-module.md` §"NO IMMEDIATE-SEEDING" states, unprompted,
that the figure cannot be re-derived under the current rule set, because switching
immediate-seeding back on now runs against a rule set that has since changed. The
audit lists it "only for completeness" and so does this. The conclusion it supports
— that the source is OFF in this lane and the cost is stated rather than hidden — is
re-measured every round by `--provenance`, which lists every weak-grade segment
individually.

---

## A defect of the SAME KIND, found in round 6 and fixed in both rounds' tools

**`proven_call_sites()` counted the block's OWN branches once the block was
converted, so the generator could not reproduce its own output.**

`notes/prom_b_f0ea9f_layout.py`'s `proven_call_sites(lo, hi)` scans
`prom_a/wsa1_prom_a.s` and `prom_b/wsa1_prom_b.s` for transcribed
`call`/`calr`/`jp`/`jr`/`jrl` lines and keeps the targets in `[lo, hi)`. While a
block is still `.incbin` no site can be inside it, so the answer is the same
either way — and that is why nobody noticed. **After** the block is spliced in,
its own thousands of internal branches match too:

| block | targets, sites anywhere | targets, sites OUTSIDE the block |
|---|---:|---:|
| 0xF6D002-0xF77FFF | **1,119** | **76** |
| 0xF0EA9F-0xF13D33 | 401 | 2 |

Two things broke. The seed set for the code walk changed, so
`gen_prom_b_f6d002_module.py --checks` re-derived a DIFFERENT layout from the one
frozen in it — **206 segments against 180, 38 of them absent from the frozen
layout and 12 of the frozen ones gone** — and the check caught it and printed
FAIL. And the grade text *"an already-converted call site **elsewhere in the
image**"* would have stopped being true for most of the addresses carrying it.

`proven_call_sites()` now skips a site inside `[lo, hi)`, which is what both the
name and the round-5 measurement always meant. Verified after the fix:

* `prom_b_f6d002_layout.py`'s derivation equals the frozen LAYOUT again;
* **round 5's block re-derives identically too** — `LY.build()` with
  `LO/HI = 0xF0EA9F/0xF13D34` returns exactly `gen_prom_b_f0ea9f_module.LAYOUT`,
  so the fix restored round 5's reproducibility rather than changing its answer.

This is the round-2 audit's own theme — a number that stops meaning what its
name says — reaching a tool instead of a sentence.

**And it had a twin one level up, in both generators' `header()`.** The line

    ; Called from: in-module: 0xF6D48F; an already-converted call site elsewhere
    ;              in the image

was emitted whenever `LY.proven_call_sites(a, a + 1)` was non-empty — "is there a
transcribed transfer to exactly this address". While the block was `.incbin` that
coincided with "…from OUTSIDE the block"; afterwards every in-module `calr`
answered YES, so **the clause appeared on 100+ routines directly after their
in-module call sites had just been listed**, saying "elsewhere in the image" about
a site two words to its left. Both generators now test membership of the
block-wide external set (76 addresses for round 6, 2 for round 5), which is the
question the sentence asks. The defect was caught by diffing a re-emit against
the emitted file, which is the only test that catches a generator that has
stopped agreeing with its own output.

---

## What this round adds that the audit could not have known

**The instruction/byte confusion was structural, not a typo.** Every emitter in
this lane prints a LAYOUT table in BYTES and no emitter printed an instruction
count, so the only number available to a writer reaching for "how big is this in
instructions" was the byte one. `notes/prom_b_instr_census.py` exists so that
number is now available and checked, and round 6's own banner quotes **bytes** for
segments and nothing else.
