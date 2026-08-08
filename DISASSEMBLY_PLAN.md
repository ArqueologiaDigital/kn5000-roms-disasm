# KN5000 ROM Disassembly Priority Plan — SUPERSEDED

> **Do not plan from this file.** It was written on 2026-01-29 (`8c7bc70`, last
> touched `5b75bc2`) and every number in it is now wrong, several by more than an
> order of magnitude. It is kept as a redirect plus an errata record; the content
> it used to carry is in git history.

**Read instead:**

| For | Read |
|---|---|
| The current plan and remaining waves | [`analysis/binclude-audit-2026-08-07/PLAN.md`](analysis/binclude-audit-2026-08-07/PLAN.md) |
| What has actually landed, wave by wave | [`analysis/binclude-audit-2026-08-07/WAVE-STATUS.md`](analysis/binclude-audit-2026-08-07/WAVE-STATUS.md) |
| Machine-readable findings (55 findings, 24 verdicts) | [`analysis/binclude-audit-2026-08-07/findings.json`](analysis/binclude-audit-2026-08-07/findings.json) |
| Live reconstruction status | `python scripts/build/compare_roms.py` |
| Narrative status for readers | `../kn5000-docs/rom-reconstruction.md` |

---

## Why it was retired

The 2026-08-07 binclude audit flagged this document's status tables as stale.
Re-measured on 2026-08-08, every row of the "Current Status Summary" and the
Priority 4 table was false:

| This file claimed | Measured 2026-08-08 |
|---|---|
| Main CPU "~99.9% disassembled, 48 KB raw bytes, **37,624** `LABEL_*`" | **Zero** `LABEL_*` in the built ROM. `llvm-nm rebuilt_ROMs/kn5000_v10_program.llvm.elf` → 40,456 symbols, 0 matching `LABEL_`. Same for v9 (40,456) and v7 (40,275). |
| Sub CPU Payload "**3,249** `LABEL_*`" | **Zero.** 4,518 symbols in `kn5000_subprogram_v142.llvm.elf`, none a placeholder; `symbols/subcpu_symbols_reference.txt` likewise (4,340 entries, 0 `LABEL_`). |
| Table Data "**~32%** disassembled" | 100.00% byte-match since Feb 2026, and after waves 0–2 most of it is genuine source, not blobs. |
| HDAE5000 "~5%, ~486 KB raw" | Still the weakest component, but the number is 340,790 B reached through four offset/length `.incbin` slices of `includes/code_29af2d_2fffff.bin`. Wave 3b is carving it. |
| Sub CPU Boot "~99% disassembled" | **Meaningless as stated.** `kn5000.cpp` marks IC30 `BAD_DUMP`; only 4,352 of 131,072 bytes are non-0xFF. The chip is ~97% **undumped**, not disassembled. |
| Priority 1 work item `code_280020_28f575.bin` | Orphan — not referenced by any build. |
| Priority 4 table: `e02510_e0458f.bin`, `e04590_e04b2f.bin`, `e04b30_e06baf.bin`, `e09150_e0adcf.bin`, `e0bb90_e0c95a.bin` "Unknown data structure" | None of those files exist anywhere in the tree. The ranges are source-built and named (`SOUND_DATA_*`, `StyleUI_ScreenData_*`, `GUI_DisplayStructData`, `ToneGen_ParamTable`). The five tracker issues that mirrored this table are closed. |
| Metric "Binary includes documented 8 / 97" | Not comparable: the inventory is now 598 directives, 505 of them honest build products. |

The only genuinely stale-in-the-other-direction item is v7: `v7/maincpu/includes/generated/`
holds 9,625 files (1,519,970 B on disk) against v10's 76, and 990,285 B of the v7
ROM enters the build through `.incbin "includes/generated/…"`. The Makefile says
why, in its own words: *"V7 bins are extracted from the v7 ROM, not compiled from
C."* That is Wave 4's subject.

## Standing invariant (unchanged, and the one thing worth keeping from here)

`make all` + `python scripts/build/compare_roms.py` must stay at **100.00% across
all 15 sections**, the legacy ASL mirror builds included, after every change.
Verified 2026-08-08: 15/15 at 100.00%.
