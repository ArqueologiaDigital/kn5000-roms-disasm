# What is `rewrite declined silently` declining, and what does the refusal cost?

**Question.** `convert_reachable_ranges.py --apply` ends with a refusal tally whose
largest BYTE bucket carries no reason at all:

```
refused   64  rewrite declined silently (usually a label it will not drop)
... 6,005 bytes behind: rewrite declined silently (usually a label it will not drop)
```

"Usually" is not a measurement. Split that bucket into **(a) refusals that protect
something real** and **(b) refusals that are a limitation of the rewriting code**,
and price the two SEPARATELY — never as one "recoverable" total. That flattening is
exactly what spec anti-patterns 3 and 9 warn about, and the label half of the question
is where 981 label "repairs" were committed and reverted once already
(`docs/IS-IT-DONE.md`, RETRACTED).

**Tool.** `tools/spelling-probes/label_guard_split.py`

| script | question it answers | run |
|---|---|---|
| `label_guard_split.py` | Which ranges land in the silent bucket, which labels block each one, is any of those labels' ADDRESSES corroborated by the ROM, and how many bytes would a cut at the first blocking label actually convert? | `python3 tools/spelling-probes/label_guard_split.py` |
| `label_guard_split.py --fast` | Same, skipping the `.incbin` site index (an llvm-mc + ld.lld pass over the whole tree). Verified to give an identical bucket. | `python3 tools/spelling-probes/label_guard_split.py --fast` |
| `label_guard_split.py --json OUT` | The per-range rows as JSON, for a follow-up. | `python3 tools/spelling-probes/label_guard_split.py --json /tmp/lgs.json` |

Needs `rebuilt_ROMs/kn5000_{v7,v9,v10}_program.llvm.elf` (a completed `make all`),
`~/compartilhado/tools/unidasm` and the LLVM build. About four minutes. It runs the
**real converter through the real `--apply` path** with every repo write intercepted
and discarded (self-tested at startup, including the negative control that a write
OUTSIDE the repo still goes through), so every bucket assignment is the converter's
own and nothing is re-implemented.

⚠ Do not run it while `tools/closure-loop.sh` is converting: the sources are a moving
target and the bucket changes under the probe. Section 0 prints the tree state.

**Signal read.** `original_ROMs/kn5000_v7_program.rom` at `addr - 0xE00000`; the block
index the converter builds from the v7 ELF; every `.s` file under `v7/maincpu`,
`v9/maincpu` and `v10/maincpu` (155 each), read as BYTES and decoded latin-1 because
65 of this project's sources hold bytes above 127 and a text-mode recursive grep skips
them silently (anti-pattern 9). PASS for the reconciliation control = the probe's
observed range count and byte count are EQUAL to the converter's own printed counter;
the script exits non-zero if they are not.

## Which of `rewrite()`'s eight refusals is this one?

Six of `rewrite()`'s eight `return None` paths record a `REFUSED` reason. Two do not,
and `main()` counts exactly those two in this bucket:

* **S1** the NEVER-DROP-A-LABEL guard — a labelled `.byte` block starts strictly inside
  `[entry, entry+span)` at an address the decode does not treat as an instruction start;
* **S2** the fall-through `return None` at the end of the function.

**Measured: S1 55/55 ranges, S2 0.** The bucket is the label guard and nothing else.
S2 is printed anyway, because "should be unreachable" is how 103 ranges / 8,828 bytes
once vanished from this very report.

## Results, 2026-08-23, converter md5 `c4e217ae117b`, tree at `2151f67` + working tree

The bucket had moved before it could be measured: six `closure-loop.sh` rounds ran in
this tree between the question being asked and the probe existing, so the **64 ranges /
6,005 bytes in the question are now 55 ranges / 4,747 bytes.** Same guard, same shape.

```
converter printed  : 55 range(s), 4,747 bytes
probe observed     : 55 range(s), 4,747 bytes      <- MATCH (control)
S1 NEVER-DROP-A-LABEL guard : 55 range(s), 4,747 bytes
S2 fall-through             :  0 range(s),     0 bytes
```

### The cut, and why it is the right thing to measure

The guard refuses a whole range because of one label inside it. The minimal alternative
is to **cut the range at the first blocking label**, keeping only the instructions that
END AT OR BEFORE that label. That cut is valid under BOTH readings of the conflict — if
the label is a real instruction start the kept instructions all lie before it; if the
label is spurious the kept instructions are unaffected — and it **adds, moves and
deletes no label**, so no `.long <symbol>` value in any pointer table changes. Each
truncated range is handed to the converter's own `rewrite()`, whose length-preserving
invariant still runs, and the verdict below is that function's.

Three variants, in increasing order of how much converter behaviour they change. **They
are alternatives, not addends** — variant 3 already contains what 1 and 2 recover.

| variant | (b) ranges | prefix B | (a) ranges | (a) prefix B |
|---|---:|---:|---:|---:|
| 1. cut only | 11 | **1,093** | 30 no-prefix + 14 orphan-branch | 108 / 572 |
| 2. cut, then re-run `resolve_branches()` | 12 | **1,103** | 30 no-prefix + 13 unnameable-branch | 108 / 562 |
| 3. …and pull the cut back before an unnameable branch | 20 | **1,228** | 35 no-prefix | 134 |

**`prefix B` is the only recoverable number, and only on a (b) row.** The rest of each
range stays `.byte` by design. Under variant 3 the bucket splits

* **(b) 20 ranges — a converter limitation. 1,228 bytes.** The whole range is dropped
  for a label near its end; a prefix of proven, byte-matched code goes with it.
* **(a) 35 ranges — the refusal costs nothing.** Fewer than three instructions survive
  the cut, and `main()` will not accept a range under three anyway. By how many
  instructions do end before the label: `{0: 8, 1: 13, 2: 9}`.

Note what is NOT claimed: 1,228 is **25.9% of the bucket's bytes**, not the bucket.
The `range B` column of the script's output (2,930 B for the (b) rows) is what the
refusal withholds, not what a fix returns.

### Is the guard protecting a corroborated address? Not detectably.

Two kinds of evidence, and they are **not interchangeable** — this is the distinction
the retraction turned on.

**ADDRESS evidence (v7 only)** — the label's v7 address appears as a little-endian u32
somewhere in the v7 ROM (a pointer the firmware dereferences), or the name is used as a
`.long`-family operand in a v7 source, or the address is in the reachability entry set.
A pointer the firmware follows outranks any cross-revision heuristic (anti-pattern 16).

```
labels with address evidence : 0 / 101
```

with both tests shown to fire, and both nulls printed:

```
u32 test   : 29.69% of all 38,988 v7 text symbols are pointed at by a u32   <- fires
             1.41% of ALL in-band addresses are, i.e. the uniform null
.long test : 5,283 of the 38,988 v7 text symbols (13.55%) are .long operands <- fires
```

Against the uniform-address null the expected hit count is 1.4 and a 0 proves little.
Against the base rate for v7 symbols generally the expected counts are 30 and 14, and
a 0 is a real signal. The true reference class for an *interior* label sits between the
two, so the honest reading is **"no label in this bucket is a KNOWN pointer target"**,
not "proven not to be".

**NAME evidence (v7/v9/v10 references)** — 96 of the 101 blocking labels are referenced
somewhere, 3 only in v9/v10, 5 nowhere at all. This says the labels must not be
**deleted**; it says nothing about whether their v7 **addresses** are instruction
boundaries, because v7's tree was seeded from v9's and an interior label's v7 address is
v9's offset replayed onto v7's bytes. Anti-pattern 12 is the standing warning here:
8,203 of the 9,975 v7 labels that nothing in v7 references ARE referenced in v9/v10.
**The cut proposal needs neither reading**, because it never touches a label.

### The residual risk, which is NOT the labels

The real hazard in this bucket is a **mis-framed decode**, which the byte gate cannot
see (anti-pattern 13). A range whose framing disagrees with the sources REPEATEDLY is
the suspicious one; a range with a single off-boundary label near its end is not. Of the
20 ranges variant 3 would convert:

```
blocking labels per range : {1: 11, 2: 2, 3: 2, 4: 4, 5: 1}
entry is a SEED call target (not only a branch-closure target) : 11 / 20
single-blocking-label subset : 11 range(s), 427 prefix bytes
```

## What would have to pass before acting, and what would refute it

Do NOT act on the 1,228 B figure alone. The staged proposal, safest first:

1. implement variant 1 (cut only) and run `make clean-all && make all` followed by
   `scripts/analysis/assert_byte_identical.py` — **bytes, never a rounded percentage**
   (anti-pattern 15);
2. run `scripts/analysis/no_label_was_dropped.py` against HEAD, and confirm it is
   comparing a tree that actually changed (anti-pattern 14 — on a clean tree it reports
   a pass that means nothing);
3. run `scripts/analysis/v7_converted_range_screen.py` over the newly converted prefixes;
   a CPU-control mnemonic in one means it is table data, not code;
4. only then variants 2 and 3, re-running 1–3 each time.

**What would REFUTE the proposal**, stated so it can happen:

* `assert_byte_identical.py` reporting any non-zero difference on v7 — the cut claims
  to be byte-neutral, and this is the check that can say otherwise;
* a link failure naming a blocking label, or `no_label_was_dropped.py` reporting a lost
  label — the cut claims to touch no label;
* the plausibility screen firing on a converted prefix, or `v7_label_guard_verdict.py`'s
  S1 (a sibling revision framing the same bytes differently) disagreeing with the kept
  prefix of a multi-label range — that would mean the prefix is mis-framed and the guard
  was refusing for the reason its comment gives, not for the reason measured here;
* the `{4: 4, 5: 1}` rows converting cleanly and *later* being contradicted by a sibling
  framing: five off-boundary labels in one routine is not five independently misplaced
  labels, it is one wrong decode, and the byte gate will not object.

If the 11 single-label ranges (427 B) pass 1–3 and the multi-label ones do not, that is
the answer, and it is a smaller number than the bucket. Report it as such.
