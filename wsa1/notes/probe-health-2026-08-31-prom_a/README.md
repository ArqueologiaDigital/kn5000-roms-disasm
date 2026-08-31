# probe health across the prom_a naming pass of 2026-08-31

The instrument is `notes/probe_health.py --image prom_a`. It grades a probe by
whether its ANSWER CHANGES between three trees that differ only in the image's
FILE LAYOUT — so a probe that reads one file where an image is a primary plus
its includes shows up, and a probe that passes vacuously over a header shows up.

## The numbers

| run | when | VACUOUS+LOUD | rows |
|---|---|---:|---:|
| `before.json` | at the start of the pass, tree at `fab0949` + this pass's census script | **3** | 188 |
| `after.json` | after the first naming batch | **5** | 195 |
| `regrade-applier.json`, `regrade-preservation.json` | after the fix below | **0** for every script this pass added | 15 |

**The +2 was entirely this pass's own two new probes**, and both were correctly
graded:

* `prom_a_naming_wave8_apply.py --plan` → **SPLIT-FRAGILE**. It scanned
  `prom_a/wsa1_prom_a.s` directly, so the day prom_a is split it would plan
  nothing and say so quietly — the vacuous pass this instrument exists to
  catch. Reads now go through `asm_source.image_lines`; the WRITE stays on the
  primary and refuses outright if any job address is not in it.
* `prom_a_preservation_check.py` (both invocations) → **LOUD**. It compared
  `git show <rev>:<primary>` with an `open()` of the working file — two FILES,
  not two images — so it necessarily differed between trees that differ in
  layout. Both sides now go through `asm_source`.

After the fix, all four invocations of the applier and all eleven of the
`prom_a_p*` group grade **UNAFFECTED**, which puts the count back at the
baseline 3.

## The one row that moved and is not this pass's

`notes/prom_b_screens_round8.py --calibrate`: SPLIT-FRAGILE → NONDET. It belongs
to the prom_b lane, which was committing to the same branch throughout; NONDET
is not counted in VACUOUS+LOUD.

## Two probe failures that predate this pass, re-checked against `fab0949`

Both fail identically on the pre-pass listing, so neither is this pass's:

* `notes/prom_a_boot_checks.py` — `FAIL 9 source defines ExtBoardMagic_F828C7`
* `notes/prom_a_byte_checks.py` — `FAIL every .fill in prom_a is one of those`
  (41 `.fill`, 26 claimed)
* `notes/prom_a_panel_names_round11.py` — `FAIL K4 the yield really is 14 of
  130 wrappers`

## Reproduce

```
python3 notes/probe_health.py --image prom_a --json out.json
python3 notes/probe_health.py --image prom_a --only prom_a_naming_wave8   # this pass's applier
python3 notes/probe_health.py --image prom_a --only prom_a_p              # and its neighbours
```
