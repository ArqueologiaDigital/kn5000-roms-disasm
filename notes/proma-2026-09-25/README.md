# Lane `proma`, 2026-09-25 semantic push -- instruments

Lane `proma` owns `wsa1/prom_a/*` (the SX-WSA1R CPU-1 program image, TMP95C061,
base 0xF80000).  Every figure the lane quotes comes from a script in this
directory.

| script | question it answers | run |
|---|---|---|
| `measure_proma.py` | census bytes (CODE / KNOWN-A / KNOWN-B / UNKNOWN / FILLER / research targets) for `wsa1_prom_a.s` alone, data-as-code markers, numeric branches (split by destination image) and numeric ROM-range immediates | `python3 notes/proma-2026-09-25/measure_proma.py [--rev REV]` |
| `srcmap.py` | (library) which label is defined at a prom_a address (from the linked ELF via llvm-nm) and which source line starts there (address comments trusted only where their byte text equals the ROM) | imported by the generators |
| `gen_fcf044_tables.py` | what reads each byte of 0xFCF044-0xFCFDA6 (the old `ModuleTables_FCF044`): lists the 56 reader instructions (45 prom_a, 11 prom_b), checks each reader's instruction shape and that PanelEvent_ToFieldIndex is its index producer, checks the tables tile the span, checks NameChar_AsciiToIndex inverts NameChar_IndexToAscii (96/96); `--apply` writes the typed tables | `python3 notes/proma-2026-09-25/gen_fcf044_tables.py` (dry run is the check) |
| `gen_fc4000_pages.py` | what reads each byte of 0xFC4000-0xFC52F7: the prom_b routines that run its display lists (decimal immediates, hence invisible to a hex search), the arrays they index, and the interpreter-B records whose +7 long points at its name/rectangle tables; asserts every list walks exactly, every array entry lands on a boundary, every op-02 width matches its table, and the objects tile the span; `--apply` writes it | `python3 notes/proma-2026-09-25/gen_fc4000_pages.py` |
| `xref_targets.py` | per census research target, every instruction operand or `.long` in prom_a AND prom_b source (hex or decimal) naming an address inside it -- the form a hex-only grep misses | `python3 notes/proma-2026-09-25/xref_targets.py --census X.json` |
| `gen_ram3800_images.py` | what the RAM-0x3800 module's two initialised-data images hold: derives the layout from the module's literal strides (13, 15, 4) and checks it against the bytes -- self-linked queue/list heads, each node pool one ring, the budget/mask/state constants, exact tiling; `--apply` writes it | `python3 notes/proma-2026-09-25/gen_ram3800_images.py` |
| `retire_zero_runs.py` | are the two big `nop`-run regions (0xFE7A86-0xFE7FB0, 0xFF79EA-0xFF7C64) code?  Checks: preceded by `ret`, no ELF label inside, no branch (symbolic or numeric) into them, no immediate/`.long` in prom_a or prom_b names them, zeros exact; `--apply` rewrites them as `.fill`/`.byte` | `python3 notes/proma-2026-09-25/retire_zero_runs.py` |
| `gen_panel_test_tables.py` | are 0xF8C8AC-0xF8C8C1 and 0xF94ED8-0xF95117 (framed as code) the panel LED wire maps and the test mode's switch-to-LED tables?  Checks the readers' bytes, the tiling (11 + 9 rows), the map values, and that the only labels inside are three orphans no source line or ROM address names; `--apply` retypes them | `python3 notes/proma-2026-09-25/gen_panel_test_tables.py` |
| `dead_runs.py` | unlabelled instruction runs after an unconditional transfer that contain data-as-code markers and that no branch in the source targets -- the candidate list for data-as-code retirement (each still needs its reader looked for; a `push <ret> / jp (xreg)` continuation shows up here too and is NOT dead) | `python3 notes/proma-2026-09-25/dead_runs.py` |
| `comment_loss.py` | which comments an edit dropped, split into regenerated address-only comments and OTHER lines that need a justification | `python3 notes/proma-2026-09-25/comment_loss.py [--base REV] [--rename-map F]` |

Definitions are the lane worklist generator's (`scripts/analysis/lane_worklists.py`)
and the branch symboliser's (`scripts/converters/symbolize_numeric_branches.py`);
`measure_proma.py`'s docstring states them.  The certification is never these
numbers: it is `make gate-wsa1` (byte identity of all four WSA1R images) plus
`make -C wsa1 images-check` for the PNG-backed bitmap rows.
