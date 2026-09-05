# w30 — naming prom_a's disk / block-device command layer (0xFE0000-0xFE54B6)

Artefacts committed this wave, with the question each answers and how to run it.

## prom_a_disk_cmd_layer_checks.py
**Question:** do the 13 routines named this wave hold up against the ROM — does
each FDC-request builder write the operation code its name claims, is each named
routine actually reached (by how many `calr` sites), and how many labels remain
`sub_XXXXXX` (the refusal denominator)? Plus a control proving adjacency-naming
would have misnamed a routine.

```
python3 notes/prom_a_disk_cmd_layer_checks.py --selftest
```
Exit 0 = all 8 checks + the control pass; exit 1 names the drift.

## prom_a_disk_cmd_layer_rename.map
The `old=new` rename map for the 13 labels. Passed to BOTH
`scripts/converters/sync_comments_to_renamed_labels.py --map … --apply` and
`scripts/analysis/assert_comments_preserved.py --rename-map …`.

## FINDINGS-prom_a-disk-cmd-layer.md
The write-up: subsystem choice, the 13 names with evidence, the 280 refused with
the measured reason, and both gates' state.
