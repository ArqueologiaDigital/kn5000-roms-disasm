# Committed outputs of lane RQ-CODESHAPE, 2026-09-02

Evidence for `notes/lanes/rq-codeshape-2026-09-02.md`. Committed because a
figure whose evidence lives only in a session scratchpad is a figure nobody can
check — including me later.

Everything here was produced at `tlcs900_backend @ 6f456a19f05b`
(`6f456a19f05bf94696728e89e74a53ed62dc9adf`). Both files depend on that decoder,
so they are only comparable with a re-run at the same toolchain commit.

| file | what question it answers | how it was produced |
|---|---|---|
| `grade-484-sites.txt` | For every data region whose heading label is the target of a `call`/`calr`/`jp`/`jr`/`jrl`/`djnz` in v7, v9 and v10: its address, extent, what fraction of its bytes decode AND round-trip byte-exact, and `refrun` — how many consecutive instruction lines the referring transfer sits inside, which is the phantom discriminator. **Taken BEFORE this lane's 64 conversions**, so it is the population that was adjudicated, not what is left. | `python3 scripts/analysis/code_suspect_adjudicate.py v7 v9 v10` at `ec98912f` |
| `blockers.txt` | Of the regions that do not fully convert, how many have a branch target that is not an instruction start at all (the phantom shape, decided by **unidasm**, a decoder independent of this tree's llvm backend), and how many are held up by a spelling gap llvm-mc has — with the blocking mnemonics named, which makes it the backend lane's worklist. Taken AFTER the conversion. | `python3 scripts/analysis/code_suspect_adjudicate.py --blockers` |

## Regenerate

    make rebuilt_ROMs/kn5000_v7_program.llvm.rom       # and v9 / v10
    python3 scripts/analysis/code_suspect_adjudicate.py v7 v9 v10   # ~6 min
    python3 scripts/analysis/code_suspect_adjudicate.py --blockers  # ~6 min

Both figures drift as lanes convert: a region that becomes instructions leaves
the population. Re-run rather than quoting these files months from now.

## What is NOT here, and why

The nulls are not tabulated in a file because they are cheap and must be
re-derived against the tree as it stands: `--null` (0 of 11,179 C-compiled data
regions is control-transfer targeted; 0 of 711 numeric transfers lands in one)
and `--randomctl` (0.8 % of random byte runs decode and round-trip clean at
these lengths). Run them; do not quote them from memory.
