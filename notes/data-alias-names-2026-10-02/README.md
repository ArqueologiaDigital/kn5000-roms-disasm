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
