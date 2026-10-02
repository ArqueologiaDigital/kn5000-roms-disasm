# Positional aliases into data, named after their readers (2026-10-02)

    python3 scripts/tools/name_data_aliases.py --tree v10 --apply --report v10.json
    python3 scripts/tools/name_data_aliases.py --tree v9 --apply --names-from v10.json --report v9.json
    python3 scripts/tools/name_data_aliases.py --tree v7 --apply --names-from v10.json --report v7.json
    make gate-all                                    # 13/13

Question: which `.set Base_0xNN, Base + N` aliases name DATA that code reads, and what should
they be called?  The tool finds, with the census marker mirror, the source line that emits
each alias's address; when it is data, the alias becomes a real label there (the line
labelled, or its `.incbin`/`.byte`/`.short`/`.long` cut at the address), named
`<Reader>_Str_<Text>` for an ASCII string or `<Reader>_Data` otherwise (Reader: the routine of
the first code line using it), and every use takes that name.  `v*.json` list each alias
(`rows`) and the alias -> label map (`retired`).

| tree | new labels | into an existing label | left: inside a line | left: code target | not used by code |
|---|---:|---:|---:|---:|---:|
| v10 | 832 | 8 | 130 | 1,036 | 198 |
| v9 | 833 | 8 | 115 | 1,036 | 182 |
| v7 | 795 | 8 | 105 | 624 | 350 |

The CODE targets (a secondary entry into a routine, a jump-table case) are left for a pass
that can name what the code does.  docs/ and technics-docs quotes of retired aliases were
renamed in the same change.

## Round 2 (2026-10-03)

name_data_aliases.py now places through scripts/tools/place_labels.py, which also cuts
whole-file `.incbin "F"` lines, negative `.byte` items and one-string `.ascii` lines: new
labels v10 128, v9 113, v7 103 (reports `round2_<tree>.json`; e.g. the sound_data_drum_kits.bin
bytes scoop_display.s reads at +0x1A / +0x3A).  Before it,
scripts/tools/drop_codeless_positional_aliases.py deleted the aliases no code, data, C or link
script uses (v10 117, v9 117, v7 248; their comment mentions were turned into the label at the
address by fix_stale_positional_comments.py), and afterwards
scripts/tools/retire_colocated_labels.py retired generated names that shared an address with
another label (v10 313, v9 320, v7 385; hand-written pairs and names a C source uses left).
