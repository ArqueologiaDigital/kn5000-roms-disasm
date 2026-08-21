# v7 provenance audit (2026-08-21)

The scripts that produced the v7 reconstruction figures quoted in
`docs/COMPLETENESS-STATUS.md`. They are kept because those numbers are quoted; they are NOT
convenient to run, and the honest headline number has a better tool.

## Use `rom_provenance_poison.py` instead, for the headline

`scripts/analysis/rom_provenance_poison.py` answers "how much of this build is copied from the ROM"
standalone, in one command, on any target. It is what produced:

    v9  : 0 differing bytes                              CLEAN
    v10 : 0 differing bytes                              CLEAN
    v7  : 122,387 differing (all at addr % 8 == 0)  ->  979,096 B (46.69%) copied at build time

## What these three add

They break the v7 figure down by MECHANISM, which the poison test cannot: it tells you how many
bytes were copied, not which build rule copied them.

| script | question it answers |
|---|---|
| `classify.py` | Which `.incbin`s in the v7 tree resolve to clang output, and which to raw ROM slices with no C source at all? (288 pure slices, 136,775 B.) |
| `cbin_diff.py` | Of the 76 C-compiled bins, how many does `extract_v7_bins.py` overwrite with a ROM slice, and by how much do those slices actually differ from the clang output? (23 files, but only ~5,100 B byte-for-byte -- the coverage tool's whole-file count overstates this ~137x.) |
| `honest.py` | The reconstruction split: 93.00% real source, 6.77% with no source, 0.23% committed bitmaps. |

## ⚠ They need two pre-built trees and hardcoded paths

Each expects `/tmp/spec-audit3/full` (a full build, so `extract_v7_bins.py` has run) and
`/tmp/spec-audit3/repo` (a copy where only the 76 clang rules were run), plus a
`v7_c_bins.txt` listing the C bin paths. Recreate with:

    mkdir -p /tmp/spec-audit3/{full,repo}
    tar --exclude=.git -cf - . | (cd /tmp/spec-audit3/full && tar xf -)
    tar --exclude=.git -cf - . | (cd /tmp/spec-audit3/repo && tar xf -)
    (cd /tmp/spec-audit3/full && make clean-all && make all)
    (cd /tmp/spec-audit3/repo && make $(V7_C_DATA_BINS))     # 76 bins, 855,100 B, pure clang

Editing the paths at the top of each script is expected. They are a record of one investigation,
not a maintained tool.

## What should happen to the finding

Commit the 288 used slice bins and delete their build-time regeneration. That turns them from
"injected at build time" (circular) into "committed blob" (honest but incomplete) with no change to
a single byte, and `rom_provenance_poison.py v7` should then report 0.
