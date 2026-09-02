# Committed outputs of the 2026-09-02 data-range census

Every number in `notes/DATA-CENSUS-2026-09-02.md` comes from these files, and
these files come from one script. They are committed because a figure whose
evidence lives only in a session scratchpad is a figure nobody can check.

| file | what question it answers | how it was produced |
|---|---|---|
| `census-run.txt` | For all twelve gated images: how many bytes are CODE, data whose purpose is stated with evidence (KNOWN-A), data under a descriptive name only (KNOWN-B), data nobody has explained (UNKNOWN), and verified uniform FILLER — reconciled to the dump sizes; then the flag columns, and the 60 largest merged research targets. | `--json` run below, then rendered with `--load … --targets 60` |
| `fp-sample-seed90902.txt` | Of the bytes the census calls "known", how many are really not? 40 size-weighted regions, read by hand. **3 of 40 fail.** | `--load … --sample 40 --seed 90902` |
| `fp-sample-seed11-prefix.txt` | The same audit run against the **pre-fix** instrument. Kept because it is what found the three defects listed in §7 of the note — the `.include` byte theft, the same-line-label misattribution, and the inherited banner. Its grades do **not** match the current tool and must not be quoted. | `--sample 30 --seed 11`, earlier revision |

## Regenerate

    cd <this repo>
    make all                       # the generated .bin inputs must exist first
    python3 scripts/analysis/data_range_census.py --selftest
    python3 scripts/analysis/data_range_census.py --json /tmp/census.json --targets 60
    python3 scripts/analysis/data_range_census.py --load /tmp/census.json --targets 60
    python3 scripts/analysis/data_range_census.py --load /tmp/census.json \
            --sample 40 --grade KNOWN-A,KNOWN-B --seed 90902

The whole-tree run takes ~15 minutes (it assembles and links twelve marked
mirrors). The `--json` file is ~114 MB and is deliberately **not** committed:
it is regenerable from the two lines above, and this project's rule is that a
large regenerable corpus needs its recipe committed, not its bytes.

⚠ The census depends on the assembler, so a number taken with a different
`llvm-project` build is a different number. The run above was taken with
`tlcs900_backend @ 6f456a19f05b`
(`6f456a19f05bf94696728e89e74a53ed62dc9adf`); `census-run.txt` is only
comparable with another run at the same toolchain commit and the same tree
state.

⚠ The figures drift as other lanes convert code and add headers. Re-run rather
than quoting these files months from now.
