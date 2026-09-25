# Lane `sys` (2026-09-25 semantic push) -- scripts

| script | question it answers | run |
|---|---|---|
| `sys_lane_census.py` | per owned file: census bytes CODE / KNOWN-A / KNOWN-B / UNKNOWN / FILLER and research targets (same rule as `scripts/analysis/lane_worklists.py`), plus data-as-code markers and numeric branch operands counted from the sources; with two census JSONs, the before -> after per file | `python3 scripts/analysis/data_range_census.py --images v10,v9,v7 --json A.json` then `python3 scripts/lanes/sys/sys_lane_census.py A.json [B.json]` |
| `reframe_markers.py` | around each data-as-code marker (and each 1-3 byte `.byte` prefix between instructions) of a file, where does the source framing leave the ROM's real instruction stream and where does it rejoin it; re-frames that range with MAME unidasm's linear decode from a start the source and unidasm agree on, every instruction verified by llvm-mc decode + isolated re-assembly; refuses ranges whose unidasm framing is itself absurd (data), labels inside instructions, no resync. Run repeatedly until it reports 0 ranges (a fixed misframe exposes the next one) | `python3 scripts/lanes/sys/reframe_markers.py --image v10 --file storage/fdc_routines.s [--show] [--apply]` |
| `port_islands.py` | which lines of a better-disassembled version (default v10), re-targeted by byte alignment, reproduce a `.byte`/`.incbin` island of another version byte for byte; ports those, leaves the rest `.byte`, keeps every destination label and comment | `python3 scripts/lanes/sys/port_islands.py --src v10 --dst v7 --file storage/flash_floppy_handlers.s [--line N] [--show] [--apply]` |

Both cache address maps under `$PORT_SCRATCH` (default `/tmp/claude-1000/lane-sys/port`),
keyed by a hash of the image's sources, and refuse a map whose mirror does not rebuild the
dump byte for byte.  After either, run `scripts/converters/symbolize_numeric_branches.py
--image <img> --only <files> --apply --verify`.
