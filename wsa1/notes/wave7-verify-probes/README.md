# The wave-7 verification probes

These were written by the **adversarial verifiers**, not by the lanes under review. That is the
whole point of keeping them: a lane's own script and a lane's own claim share an author, so they
can agree with each other and both be wrong. These are the independent re-derivations that decide
whether a dossier survives.

They ran in session scratch, which is not storage. They are here because
[the standing rule](../../../.claude/CLAUDE.md) says the thing that produced a number belongs in
the repo beside what it measures, in the same session the number is first quoted.

One entry per script: **the question it answers**, and the exact command.

⚠ None of these is the gate. `python3 scripts/analysis/assert_byte_identical.py` is the gate and
nothing else is. These check *meaning*, which is the half the gate is blind to.

---

## ★ `wave7_pa_write_census.py` — the gap-T adjudicator

**"Does the firmware ever change PA bit 3 (the floppy motor/ready line), and where?"**

```
python3 notes/wave7-verify-probes/wave7_pa_write_census.py
python3 notes/wave7-verify-probes/wave7_pa_write_census.py --selftest   # 18 checks
```

It settles a contradiction between two committed documents. Commit `a4976de` (wave 6) said
`ld (PA),A` occurs exactly twice and "the firmware never changes it ... it is now a hardware
question". `WSA1-EMULATION-DISASM-GAPS.md`'s 2026-08-26 refresh said the opposite. **The refresh is
right.** The wave-6 census searched for one *spelling*; the TLCS-900 reaches an 8-bit direct address
through twelve encodings, and the two writes it missed are bit manipulations — `res 3,(PA)` at
`0xFE18EF` and `set 3,(PA)` at `0xFE18F7` — which never contain the store opcode.

★ **The reusable lesson: a census that enumerates one spelling is not a census of the operation.**
Enumerate encodings, not idioms.

Result: **5 writes and 2 reads, all in prom_a, none in prom_b.** `res` at `0xFE18EF` followed by a
307 ms delay is the active-low evidence; RESET's `ldio PA,0xF9` sets bit 3 HIGH, so a machine at
rest has the line released.

⚠ **This script fell into a weaker version of the same trap on its first draft, and the correction
is kept rather than quietly folded in.** It enumerated the twelve `C0/D0/E0/F0` direct-operand
encodings, found four writes, and declared the census complete. It was missing the RESET write
`ldio PA,0xF9` at `0xF826D6` — which is opcode `0x08` (`ld (n8),imm8`), a standalone direct opcode
outside that family, *and* is written in the source with a symbolic operand and **no byte comment**,
so the byte-comment scan was structurally blind to it as well. The wave-7 doc-audit lane's verifier
found it independently. Hence pass 1b (symbolic operands) and the `op08` raw pattern. Enumerating
twelve encodings instead of one is better; it is not the same as enumerating all of them.

It also states its own denominator, which the earlier census did not. Scanning the `.s` sources
only sees converted code — 106,585 bytes of prom_a and 159,459 of prom_b are still `.incbin` — so
pass 2 scans the raw ROM over exactly those ranges. prom_a yields **zero** candidates. prom_b yields
**three**, and they are adjudicated in the docstring rather than waved away: `0xF3A0C1` is inside a
stride-5 LE16 table (`0x1720 0x1725 0x172A …`) and 0 of 38 trial decode starts land on it;
`0xF0B984` would be a word `cp`, a read; `0xF53DFF` would be `chg 0,(PA)` — **bit 0, not bit 3**.
The 38-start convergence numbers are reproduced by `--adjudicate`, not asserted.
So even if both remaining candidates are real instructions, gap T's answer is unchanged, and the
bit-3 census is complete over both 512 KiB images.

## `wave7_selftest_mutation.py` — is a self-test a real criterion?

**"Does this layout script's `--selftest` actually FAIL when the ROM changes?"**

```
MUT_ADDR=FADB55 MUT_VAL=00 python3 notes/wave7-verify-probes/wave7_selftest_mutation.py
LAYOUT=prom_a_fa5aeb_layout.py MUT_ADDR=FA6018 MUT_VAL=00 python3 notes/wave7-verify-probes/wave7_selftest_mutation.py
```

A self-test that passes on a mutated ROM is decoration. **A criterion that cannot fail is not a
pass.**

★ **It found something.** `prom_a_fad800_layout.py --selftest` reports 57 checks, 0 failures. Flip a
byte it explicitly cites and it does fail, correctly:

| mutation | failures |
|---|---:|
| `0xFADB55` `0xC9`→`0x00` (a cited dispatch bound) | 2 |
| `0xFADB56` `0xCF`→`0x00` | 2 |
| `0xFADB5C` `0xD8`→`0x00` (the cited index scaler) | 1 |
| `0xFAD800` `0x0E`→`0x00` (**first byte of its own span**) | **0** |
| `0xFAD801` `0x1E`→`0xFF` | **0** |
| `0xFADFFF` `0x10`→`0xFF` | **0** |

So its 57 checks verify the **cited anchors**, not the **segmentation**. A segment boundary could be
wrong, or a segment's content could contradict its declared kind, and the self-test would not
notice. That is a bounded, honest statement of what the number 57 buys — and the fix for a later
round is a per-segment content check (a `pad` segment really is all `0x0E`, an `ascii` segment
really is printable), not more anchors.

## The tiling checks — transcribed from the dossier PROSE, not from the lane's code

**"Do the segments in the DOSSIER TEXT cover the span exactly, with no gap and no overlap — and do
they agree with what the committed script computes?"**

```
python3 notes/wave7-verify-probes/wave7_tile_a3_fa1404.py    # lane A3, prom_a 0xFA1404
python3 notes/wave7-verify-probes/wave7_tile_b1_f17559.py    # lane B1, prom_b 0xF17559
python3 notes/wave7-verify-probes/wave7_tile_b3_f067a6.py    # lane B3, prom_b 0xF067A6
```

A one-byte gap silently shifts every following segment, and the byte gate **cannot see it** while
the region is still `.incbin`. Transcribing from the prose rather than importing the lane's code
means a lane that reported one thing and computed another fails here.

All three tile exactly (B1 16,039 = 16,039; B3 24,463 = 24,463; 0 gaps, 0 overlaps).

★ **B1's prose and B1's script disagree on four segment KINDS**, which is precisely what this probe
exists to surface — the arithmetic is right and the naming is not:

| range | dossier says | the script says |
|---|---|---|
| `0xF17C59-0xF17C8B` | `bitmap` | `index_map` |
| `0xF18066-0xF1814D` | `display_list` | `record_array` |
| `0xF185FD-0xF1881C` | `display_list` | `record_array` |
| `0xF1A62F-0xF1A7AE` | `ascii` | `index_map` |

Kinds are what become routine headers, and headers are exactly what the gate is blind to. These
four must be resolved before any of that span is converted.

## The null-corpus checks — is a "0 false positives" real?

**"When a lane says its content rules fire zero times on known-good code, is that because the rules
are tight or because the corpus is empty?"**

```
python3 notes/wave7-verify-probes/wave7_null_corpus_independent.py    # rebuild the corpus from scratch
python3 notes/wave7-verify-probes/wave7_null_ptrtab_independent.py    # an independent pointer-table rule
python3 notes/wave7-verify-probes/wave7_null_ptrtab_window.py         # the same rule, two address windows
python3 notes/wave7-verify-probes/wave7_null_displaylist_threshold.py # the cost of each chunk threshold
```

`wave7_null_corpus_independent.py` rebuilds the proven-instruction corpus from the `.s` comments
without copying the lane's code: **109,819 instruction lines, 0 byte-comment mismatches against the
ROM, 287,291 bytes in 10,509 runs**, and 0 runs overlap the target span (correct — it is still
`.incbin`). The corpus is real.

`wave7_null_displaylist_threshold.py` prints the **cost of the threshold instead of hiding it**, the
way `prom_b_f65000_layout.py` states the 9-byte string it declines to promote:

```
chunk>=16  whole-run rule 1/1884 (0.1%)   with <=8-byte trim  83/1884 (4.4%)
chunk>=32  whole-run rule 0/1084 (0.0%)   with <=8-byte trim  35/1084 (3.2%)
```

## The lane-specific re-derivations

| script | question it answers |
|---|---|
| `wave7_g1_write_census.py` | **"Where is each gap-A register actually written?"** — re-finds the write sites for `0x0440`/`0x0480`/`0x04C0`/`0x0500` by scanning raw ROM for the RAM operand, independent of the lane's method |
| `wave7_g1_pointer_hits.py` | **"How many sites reference the staging block, and by which mechanism?"** — separates `call`, `imm32` and 3-byte-operand forms (74 operand hits vs 3 call hits) |
| `wave7_a4_constants.py` | **"Are the constant tables at `0xF8671A` and `0xF8679A` really powers of two?"** — checks the LAST entry too (`0x80000000`, and `1<<17..1<<24`) |
| `wave7_a4_directories.py` | **"Do the claimed directory areas match the min/max of their own entries?"** — for each, whether `entry[0]` equals the area start and the furthest list end equals area end + 1 |
| `wave7_a4_dir_c.py` | **"Is directory C real, or is it pointing into `0xFF` fill?"** — dumps the raw bytes under the claimed entries |
| `wave7_a4_thunk_tails.py` | **"Do the per-id lists really start at `T_F41070 + 4*id`?"** — ★ **32 ids start there but only 31 match through the tail**, a first-vs-last discrepancy of exactly the kind this project keeps being caught by |

---

## What is deliberately NOT here

About thirty other scratch files — `try1.py`…`try5.py`, `probe1.py`…`probe8.py`, `codesegs*.py`,
`islands.py`, `refs*.py`, `expl*.py` and similar — were lane **scaffolding**: the exploration each
lane did before writing its committed `notes/*_layout.py`. They are disposable because the committed
script is the durable form of the same derivation, and each lane's verifier was required to re-run
that script and confirm it reproduces every number the dossier quotes.

The probes kept here are the ones that are **not** reproduced by any committed script, because they
were written to disagree with one.
