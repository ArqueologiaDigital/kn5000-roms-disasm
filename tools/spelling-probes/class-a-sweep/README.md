# Class-A sweep probes (2026-08-23)

The scripts a 13-agent workflow used to find and verify the remaining v7
spellings. Each answers one question and produced a number quoted in commit
`9728ff2`; they are here because a number whose producer lives in `/tmp` is a
number nobody can check.

| script | question it answers | command |
|---|---|---|
| `enum_sites.py` | For a given form, what is EVERY site in the reachable ranges, and can the tree spell each one? Does not stop at the first blocker, so it does not undercount the way the `--forms` census does. | `python3 enum_sites.py` |
| `census.py` | What does `convert_reachable_ranges.py --forms` report, using cached decodes? Reproduces the headline blocking counts cheaply. | `python3 census.py` |
| `measure.py` | What is the payoff of a proposed rule, in ranges and bytes, run through the converter's OWN `main()` rather than a reimplementation? | `python3 measure.py baseline` / `python3 measure.py patched` |
| `which.py` | WHICH ranges does a proposed rule newly accept? Names them, so "5 more ranges" can be checked for being real code rather than table data. | `python3 which.py` |

⚠ These import the live converter and cache `unidasm` decodes of all 687 call
targets in `decodes.pkl`, built on first use by `_decodes.py` -- any probe here
can be run standalone and in any order, and deleting the pickle forces a rebuild
(minutes). ⚠ The first committed `census.py` loaded that pickle without being
able to build it, so it raised `FileNotFoundError` for anyone who ran it before
`enum_sites.py`: the cache had only ever existed in a scratch directory.
Committing a probe is not the same as committing a probe that runs -- check by
running it from a clean tree. They do NOT modify the
repo — `measure.py` monkey-patches `cc.translate` in memory.

## What they established

* **`push A` is `0x14`**, a one-byte dedicated opcode, not the `0xC8+r` family.
  Six sites; v7 already carried 82 `push_a` lines.
* **`or (mem),r` is `orddm8` — DOUBLE d, and parenthesised.** `or (0x328e),A`
  = `c1 8e 32 e9`. The single-d name is not a mnemonic; it was wrong in BOTH
  branches of the existing rule, and the missing parens made the corrected name
  yield nothing. The general shape is sub-opcode `0xE8 + regcode` after prefix
  `0xC1` (w=e8, a=e9, b=ea, c=eb, d=ec, e=ed, h=ee, l=ef).
* **`ldw (imm),(imm)` is the `ldmm` family**: `ldmm8 0x3910, 0x3911` = `c1 11 39
  19 10 39`, `ldmm16 0x2796, 0x2792` = `d1 92 27 19 96 27`.
* **`djnz` is `djnz8`/`djnz16` with a LABEL operand** — `djnz16 bc, .Lc_ef8480`
  = `d9 1c f9`. ⚠ `--show-encoding` shows only the fixup placeholder for these;
  the verifier assembled to an object file and read `.text` instead. Not yet
  implemented: `djnz` must first be added to the converter's branch set.
* **`encode()` ignored llvm-mc's exit status.** `or (0x328e),A` exits 1 with
  `error: byte/word direct memory load not encodable` and STILL prints
  `; encoding: [0xe9]`, which was being returned as a valid encoding. Fixed.

## What the adversarial pass refuted, on its own side

Kept because a verification that never contradicts is not a verification:

* a missed 8th `djnz` site;
* a site count off by two (536 distinct addresses, not 534);
* **four of the six `push A` sites are data, not code** — `0xEE5BF1` decodes as
  `push A / incf / push WA / halt` and the plausibility screen correctly kills
  it. Only two sites contributed to the measured gain, so "6 sites fixed" reads
  as more than it is.
