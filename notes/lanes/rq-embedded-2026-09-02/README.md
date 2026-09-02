# Committed outputs of lane `rq-embedded`, 2026-09-02

Every figure in `notes/lanes/rq-embedded-2026-09-02.md` comes from one of these,
and each comes from a committed script. A number whose evidence lives only in a
session scratchpad is a number nobody can check.

Toolchain for all of them: `tlcs900_backend @ 6f456a19f05b`.

| file | what question it answers | how it was produced |
|---|---|---|
| `census-after-v10-v9-v7.txt` | After the lane's conversions, how much of the census's `embedded-in-code` column is left, per image, and which ranges are the largest? | `python3 scripts/analysis/data_range_census.py --images v10,v9,v7 --json <scratch>.json --targets 40` |
| `data-directive-bytes-before-after.txt` | How many bytes did the lane actually move out of data directives, measured **without** the tools that did the converting? | `python3 scripts/analysis/data_directive_bytes.py --diff 08d0c4e8` |
| `decoder-gap-ranking.txt` | Which byte values block the most conversion work, and does the ENCODER already have the form the decoder refuses? | `python3 scripts/analysis/decoder_gap_ranking.py` |
| `decode-encode-asymmetry.txt` | Which forms does `llvm-objdump` spell as a *different* instruction — silent, because only a re-assembly notices? | `python3 scripts/analysis/decode_encode_asymmetry.py` |
| `twin-five-gate-report-min64.txt` | Of v7's `.byte` label-spans ≥64 B, how many pass all five twin-framing gates, and what refuses the rest? | `python3 scripts/analysis/twin_framed_spans.py --report --min 64` |
| `twin-port-apply.txt` | How many spans can be framed by PORTING the twin's own statements, and what do the two agreement floors refuse? | `python3 scripts/analysis/twin_framed_spans.py --port <linemap>.json --min 64` |
| `reframe-{v10,v9,v7}-apply-tail.txt` | Per image: how many `.byte` islands inside code were re-framed, how much was refused, and which byte values blocked a span? (tail only — the full run is one block per source file) | `KN5000_IMAGE=<img> python3 scripts/analysis/v10_reframe_code_runs.py --linemap <linemap>.json --apply $(find <img>/maincpu -name '*.s')` |

⚠ **The line map must be regenerated after any edit to the files it describes.**
`v10_line_address_map.py --image <img>` costs ~10 minutes and a stale one is
invisible to every check except the rebuilt ROM. `twin_framed_spans.py` refuses
to run unless its guard passes: every `.byte` line the map places must carry the
byte the ROM has at that address (36,330 lines checked, 0 disagreements, in the
run above).

⚠ **The large `--json` census file is deliberately not committed** — it is ~30 MB
per run and regenerable from the command in the table.
