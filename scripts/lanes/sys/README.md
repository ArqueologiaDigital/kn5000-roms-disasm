# Lane `sys` (2026-09-25 semantic push) -- scripts

| script | question it answers | run |
|---|---|---|
| `sys_lane_census.py` | per owned file: census bytes CODE / KNOWN-A / KNOWN-B / UNKNOWN / FILLER and research targets (same rule as `scripts/analysis/lane_worklists.py`), plus data-as-code markers and numeric branch operands counted from the sources; with two census JSONs, the before -> after per file | `python3 scripts/analysis/data_range_census.py --images v10,v9,v7 --json A.json` then `python3 scripts/lanes/sys/sys_lane_census.py A.json [B.json]` |
