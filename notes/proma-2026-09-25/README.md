# Lane `proma`, 2026-09-25 semantic push -- instruments

Lane `proma` owns `wsa1/prom_a/*` (the SX-WSA1R CPU-1 program image, TMP95C061,
base 0xF80000).  Every figure the lane quotes comes from a script in this
directory.

| script | question it answers | run |
|---|---|---|
| `measure_proma.py` | census bytes (CODE / KNOWN-A / KNOWN-B / UNKNOWN / FILLER / research targets) for `wsa1_prom_a.s` alone, data-as-code markers, numeric branches (split by destination image) and numeric ROM-range immediates | `python3 notes/proma-2026-09-25/measure_proma.py [--rev REV]` |
| `comment_loss.py` | which comments an edit dropped, split into regenerated address-only comments and OTHER lines that need a justification | `python3 notes/proma-2026-09-25/comment_loss.py [--base REV] [--rename-map F]` |

Definitions are the lane worklist generator's (`scripts/analysis/lane_worklists.py`)
and the branch symboliser's (`scripts/converters/symbolize_numeric_branches.py`);
`measure_proma.py`'s docstring states them.  The certification is never these
numbers: it is `make gate-wsa1` (byte identity of all four WSA1R images) plus
`make -C wsa1 images-check` for the PNG-backed bitmap rows.
