# Probes the verification judges wrote (2026-09-25)

The eight judges of panel 1 (see `../README.md`, verdicts in `../panel1_verdicts.json`)
wrote these while checking the symboliser's accepted sites.  Several numbers in their
pattern notes -- which are committed verbatim in `panel1_verdicts.json` -- came from them,
so they are kept here, unedited, beside that evidence.  They ran from the repo root.

⚠ Most of them read `symbr/<image>.json`, a `--report` written by
`scripts/converters/symbolize_numeric_branches.py` into a scratch dir, and they measured
the tool at INTERMEDIATE, never-committed revisions (before guards R5/R6 existed), on the
tree at `2d5183f1`..`ed19eeef` (before the numeric operands were rewritten).  To re-run one
as it was run: `git worktree add --detach <dir> ed19eeef`, build (`make
rebuilt_ROMs/kn5000_v10_program.llvm.rom` for the v10 probes), write the reports with
`--report symbr/<image>.json`, then run the probe.  Against the COMMITTED tool the
populations they flagged are refused, so the figures do not reproduce -- which is the point.

| probe | judge | question it answers | run |
|---|---|---|---|
| `audit_v10.py` | v10 | of the sites the tool accepts in v10, how many have a source that is NOT an instruction start of the stated branch in the ROM's own linear disassembly (`original_ROMs/kn5000_v10_program.rom.unidasm`), and how many targets are not instruction starts? | `python3 audit_v10.py <outdir>` -> `<outdir>/v10_audit.json` (one row per accepted site, `ok_src`/`ok_tgt`) |
| `scan.py` | v9 / v7 | per file, how many numeric branches sit in a window (±6 lines) holding >= 3 suspicious instructions (mode/system ops, `:io` forms, carry-flag ops ...)? | `python3 scan.py v7/maincpu` |
| `acc_scan.py` | v7 | the same shape of window test (±5 lines, >= 2 hits) restricted to sites the tool had NOT refused | `python3 acc_scan.py <scratch> v7` |
| `lblscan.py` | prom_a | which NEW labels land where the ROM around the target is ASCII or a run of >= 4 in-range LE32 pointers? | `python3 lblscan.py prom_a wsa1/original_ROMs/wsa1_prom_a.ic12 f80000` |
| `romsrc.py` | prom_a | the same ASCII / pointer-table test applied at each accepted SOURCE address | `python3 romsrc.py prom_a <rom> <base>` |
| `xref.py` | v10 | which raw ROM bytes, decoded as jr/jrl/calr/call, would branch to the given addresses (independent of the source) | `python3 xref.py 0xF183EF ...` |
| `check_v142.py` | v142 | does every sampled v142 source address hold the stated branch opcode, and does the displacement recompute to the stated target? | `python3 check_v142.py` (reads `../samples/v142.txt`; edit its hard-coded scratch path to that) |
| `dis_v7.sh`, `dis_v9.sh` | v7, v9 | print MAME `unidasm` for a window of the v7 / v9 ROM (helpers; they compute nothing) | `./dis_v7.sh F092B0 32` |

## The one figure from here that the repo quotes, re-derived on committed code

`../README.md` quotes the v10 judge's audit: 86 of 8,028 accepted v10 sites (1.07%) were
phantoms, measured with `audit_v10.py` against the pre-R5 tool.  The same probe, run
2026-09-25 against the COMMITTED tool (`b0bfd371`) on the tree it was applied to
(`ed19eeef`, worktree built with `make rebuilt_ROMs/kn5000_v10_program.llvm.rom`):

    accepted sites 7,884 | source not an instruction start of the stated branch: 0 |
    target not an instruction start: 0

So R5 removes that whole population, not just the sampled one.
