# probe_health over the twelve scripts wave 8 added to prom_b's lane

*2026-08-31. The question the lane rule asks is "keep non-green at or below where
you found it". This is the half of that which the round could actually move.*

## Why per-script, and not the whole image

`python3 notes/probe_health.py --image prom_b` is now **101 scripts / 187
invocations / 748 runs**, and with the prom_a lane running its own copy on the
same eight cores it did not finish (it was killed at 50/748 after ~40 minutes;
`gen_prom_b_f0ea9f_module.py --checks` and `gen_prom_b_f067a6_module.py
--checks` are minutes each and it runs every invocation in three trees).

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

⚠ **What is NOT here:** a fresh full-image `probe_health --image prom_b`. The
standing baseline remains `notes/probe-health-baseline-2026-08-30/prom_b.json`
(88 rows: 44 UNAFFECTED, 44 non-green — 34 SPLIT-FRAGILE, 4 VACUOUS, 2 LOUD, 1
WRITER, 1 TIMEOUT, 1 NONDET, 1 BY-DESIGN). Re-running it whole, once the
machine is not shared, is the honest next step and the command is above.
