# Branch symbolization, catch-up run of 2026-10-02

`semantic_debt_dashboard.py` showed v7 with 2,101 numeric branch/call operands against v10's 585:
the 2026-09-25 runs had left v7 behind.  The same tool, unchanged:

    python3 scripts/converters/symbolize_numeric_branches.py --image v7 --apply --verify --report v7_report.json
    python3 scripts/converters/symbolize_numeric_branches.py --image v10 --apply --verify --report v10_report.json
    python3 scripts/converters/symbolize_numeric_branches.py --image v9 --apply --verify --report v9_report.json
    make gate-all                                   # 13/13

| image | converted | labels reused | labels new | numbr before -> after |
|---|---|---|---|---|
| v7  | 1,326 | 415 | 39 | 2,101 -> 775 |
| v10 | 5 | 0 | 5 | 585 -> 580 |
| v9  | 5 | 0 | 5 | 611 -> 606 |

`--verify` re-mirrored each modified tree and compared it with the dump (PASS).  prom_a and
prom_b had nothing convertible.  What is left is refused on purpose, mostly R3 (509 v10,
532 v9, 692 v7): the "branch" sits in a block whose decode is absurd -- bytes framed as code
that are data -- so the right fix is reframing, not a label.  The reports list every site
with its classification (`report`) and the new labels (`labels_new`: address, name, source
line, kind).
