# prom_a numeric ROM operands made symbolic (2026-10-02)

`scripts/converters/symbolize_rom_operands.py --image prom_a --apply --verify` replaced 699
numeric addresses inside prom_a (617 `.long` pointers, 82 `ld`/`lda`/`add` operands) with
labels, inserting 79 new labels; its own re-mirror check passed, and `make gate-all` stayed
13/13.  59 candidates were refused because the target falls inside an instruction (misframing
evidence -- listed in `prom_a_report.json`); prom_b's 1,281 candidates were all refused that
way and need a separate look; prom_c had 1.

| file | what it is |
|---|---|
| `prom_a_report.json` | the tool's report: every site, its classification, refusals |
| `proma-irq-sled-pack.json` | the rename of 7 labels the tool had parented wrongly (below) |

New code labels follow the WSA1 house style `<nearest label above>__<ADDR>`.  The nearest
label above is not always the right parent: the vector table's SWI1-6/INT4 slots point at a
seven-NOP sled that falls into `IRQ_UnusedVector_Hang`, and the tool named those NOPs
`INTWD_Reboot__F82D02..08` after the routine before it.  They are now
`IRQ_UnusedVector_SWI1..SWI6` / `IRQ_UnusedVector_INT4` (applied with
`scripts/tools/apply_label_edits.py`).  27 more of the new labels have an unconditional
`ret`/`jp (xrr)`/`jrl t` between their parent and themselves -- mostly case targets of a
computed jump or extra exits, i.e. plausibly the right routine -- and all `__ADDR` labels are
placeholders for a naming pass.

## KN5000 main CPU: exact-symbol operands (same day)

`scripts/converters/symbolize_kn5000_rom_operands.py --image <v> --apply` replaced numeric
main-CPU ROM addresses in non-branch operands with the symbol the image's own linked ELF
defines AT that address (exact matches only; a column-0 label preferred over a `.set` alias, a
non-structural name over a structural one): v7 1,041, v10 190, v9 184 (76 files).  With
several names at one address the choice is listed in `kn5000_<v>_report.json`
(`candidates`).  Not touched, and listed there as `no-symbol`: v7 346, v9 117, v10 108
values with no symbol at that exact address (inside an object, or code nobody labelled) --
input for a pass that adds labels; table-data addresses (0x8xxxxx) are a cross-ROM question
the tool does not answer.  `make gate-all` 13/13.
