# probe_health over the twelve scripts wave 8 added to prom_b's lane

*2026-08-31. The question the lane rule asks is "keep non-green at or below where
you found it". This is the half of that which the round could actually move.*

## Why per-script FIRST, and the whole image after

`python3 notes/probe_health.py --image prom_b` is **102 scripts / 189
invocations / 756 runs**. While the prom_a lane was running its own copy on the
same eight cores it could not finish (killed at 50/748 after ~40 minutes;
`gen_prom_b_f0ea9f_module.py --checks` and `gen_prom_b_f067a6_module.py
--checks` are minutes each, in three trees), so the round measured the part it
could move — the twelve scripts it adds — and said so. The full run finished
later at `--jobs 8` in about 40 minutes and is reported at the bottom; it agrees.

What the round can move splits in two, and only one half needs the full matrix:

* **The 88 rows that already existed.** probe_health grades a probe by whether
  its answer depends on the image's FILE LAYOUT — `asis` vs an expanded `full`
  vs a split `stub`. This round split no file and added no `.include`; it
  changed comment text and label spellings, identically in all three trees. The
  one way a pre-existing row could still move is a probe that now crashes or
  goes nondeterministic, and that is exactly what
  `notes/prom_b_probe_answer_diff.py --base 0f08601` measured over **all 93**
  prom_b probes: 75 unchanged, 18 changed, every one of the 18 traced to the
  round's own conversion, renames or tools (see `notes/README-prom_b.md`).
* **The twelve rows the round ADDED.** A new script that grades VACUOUS or
  SPLIT-FRAGILE raises the non-green count on its own, and no argument about
  layout covers that. So each was measured, with the JSONs kept here.

## The result: 16 invocations, all UNAFFECTED, 0 non-green

    python3 notes/probe_health.py --image prom_b --only prom_b_msgline
    python3 notes/probe_health.py --image prom_b --only prom_b_string_refs
    python3 notes/probe_health.py --image prom_b --only prom_b_ram_and_device_census
    python3 notes/probe_health.py --image prom_b --only prom_b_naming_preservation
    python3 notes/probe_health.py --image prom_b --only prom_b_naming_evidence
    python3 notes/probe_health.py --image prom_b --only prom_b_probe_answer_diff
    python3 notes/probe_health.py --image prom_b --only prom_b_apply
    python3 notes/probe_health.py --image prom_b --only prom_b_effect_param_map

| script | invocations | grade |
|---|---:|---|
| `prom_b_msgline.py` | 2 | UNAFFECTED |
| `prom_b_string_refs.py` | 2 | UNAFFECTED |
| `prom_b_ram_and_device_census.py` | 2 | UNAFFECTED |
| `prom_b_naming_preservation.py` | 2 | UNAFFECTED |
| `prom_b_naming_evidence.py` | 2 | UNAFFECTED |
| `prom_b_probe_answer_diff.py` | 1 | UNAFFECTED |
| the six `prom_b_apply_*.py` | 7 | UNAFFECTED |
| `prom_b_effect_param_map.py` | 0 | **not a candidate** — it never names the listing; it reads the ROM |

★ **Two of them only grade this way because they were fixed first.** As first
written, `prom_b_naming_preservation.py` opened `prom_b/wsa1_prom_b.s` by path,
and `prom_b_probe_answer_diff.py` was bare-runnable — which would have made
probe_health re-enter the entire probe corpus inside each of three trees. Both
were rewritten before this measurement (commit "make this round's two new probes
split-proof and harness-safe"); the preservation check now reads the IMAGE
through `asm_source` on both sides, and the answer-diff refuses to run without an
explicit `--base <rev>`.

## ✅ THE FULL RUN LANDED — 0 REGRESSED

The whole matrix did finish, once the machine was free: **102 scripts, 189
invocations, 756 runs**, `prom_b-full.json` here.

    python3 notes/probe_health.py --image prom_b --jobs 8 --json prom_b-full.json
    python3 notes/probe_health_regression.py \
        notes/probe-health-baseline-2026-08-30/prom_b.json \
        notes/probe-health-prom_b-wave8-2026-08-31/prom_b-full.json --image prom_b

Two totals cannot settle the lane rule, because a round also ADDS scripts, so
the comparison is joined on `argv` — the exact command probe_health ran:

```
base:  88 invocations, 45 green, 43 non-green
new : 189 invocations, 183 green,  6 non-green

in both runs: 88
  ★ REGRESSED (green -> non-green): 0
  IMPROVED (non-green -> green):   39
  changed within non-green:         1   (LOUD -> VACUOUS)
ADDED since base: 101  (2 of them non-green)
GONE since base:    0
```

★ **REGRESSED is 0.** That is the number the rule is about, and it is the only
one this round can claim.

⚠ **The 43 → 6 improvement is NOT this round's.** The baseline is 2026-08-30 and
the 39 improvements are the tree's: the perf work that made
`reachability.py --targets` stop timing out, and both lanes' probe fixes since.
Attributing them here would be theft.

⚠ **Neither of the two ADDED non-green rows is this lane's**, and neither is a
regression:

| row | why |
|---|---|
| `prom_b_entrypoints_round7.py --selftest` NONDET | the same script was **already NONDET** in the baseline, under a different cited spelling (`--runs --selftest`). Same known nondeterminism, not a new one. |
| `prom_b_screens_round8.py --calibrate` NONDET | a **different invocation** of a script the baseline graded UNAFFECTED as `--layer2`. A newly exercised command, which is why the comparator reports it as ADDED rather than REGRESSED. |

Neither file was touched by any lane this pass (`git log 0f08601..HEAD --` on
both is empty). Both are worth a look by whoever owns them; they are recorded
here rather than left in a log.

**All sixteen invocations this round added are UNAFFECTED**, which the per-script
table above measured first and the full run confirms.
