# Analysis scripts

## Added 2026-08-21 (completeness audit)

| script | question it answers |
|---|---|
| `verify_stale_band.py` | Is the "unreferenced residue" in style_records.s really a discarded predecessor? (No: it is the live help region copied 0x8000 lower, one byte different.) |
| `ic19_cell_grammar_probe.py` | Do the custom-data style banks parse under the documented demo-preset cell grammar? (Yes: 725/725 cells frame to 0x83.) |

    python3 scripts/analysis/verify_stale_band.py original_ROMs/kn5000_table_data.rom
    python3 scripts/analysis/ic19_cell_grammar_probe.py original_ROMs/kn5000_custom_data.ic19
