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

---

# The de-circularisation attempt, and what it proved (2026-08-21)

An attempt was made to remove the ROM from the v7 build, following the recommendation above.
It FAILED, and the failure is a stronger result than the recommendation was.

## What was tried

1. The 288 `.incbin`-referenced bins with no source of any kind (136,775 B) were copied out of
   `v7/maincpu/includes/generated/` into a committed `includes/romslices/`, and the 51 source files
   referencing them were repointed. Honest committed blobs instead of build-time ROM slices.
2. Of the 76 C-compiled bins, 53 already match the ROM exactly and 23 do not. Their divergence is
   only **5,118 bytes** inside 703,651 B of files, so rather than committing 703 KB of blob and
   hiding 691 KB of genuinely-reconstructed C behind it, the divergence was captured as a committed
   patch (`v7_c_divergence.json`) applied by `apply_v7_c_divergence.py` on top of the compiler's
   output.
3. `extract_v7_bins.py` and both of its invocations were removed from the Makefile.

Every referenced bin was verified byte-identical to the state a successful build leaves behind:
**353 of 353 matching.** The sources differed only in `.incbin` paths (335 lines, no other change).

## What happened

    make clean-all && make all   ->  maincpu v7: Similarity 46.33%  (1,125,642 incorrect bytes)

Rebuilding v7 alone from those same verified-correct bins is deterministic and gives the same
46.33%. The first divergence is at ROM 0xE00012, in a pointer table, where every pointer is
**0xD0 (208) bytes higher** than the original -- a layout shift, not corrupt data.

## What that means

**The v7 build is not idempotent.** Assembling with the exact bins that a *successful* build
produced does not reproduce the ROM. The build reaches 100.00% only by re-slicing the ROM on every
run, and its first pass seeds addresses from the **v9** ELF, not the v7 one -- which is why running
`extract_v7_bins.py` against an already-wrong v7 ELF makes it worse rather than converging
(measured: 1,125,409 differing after one such pass).

So the earlier statement that v7 is "partly circular" is too kind. The accurate statement is:

> **v7 cannot currently be rebuilt from committed inputs at all.** There is no set of committed
> files from which `llvm-mc` + `ld.lld` produce the v7 ROM. The 100.00% is manufactured at build
> time by a two-pass extraction that reads the ROM twice, and no fixed point of that process has
> ever been committed.

The 46.69% figure from `rom_provenance_poison.py` measures how much is copied. This measures
something worse: even the *other* 53.31% does not assemble to the right addresses without the copy
step, because the layout depends on bins whose contents the extractor decides.

## What would actually fix it

Find the fixed point and commit it. Iterate `extract -> assemble -> extract` from a clean tree with
the v9-seeded fallback until the bins stop changing AND the assembled ROM matches, then commit those
bins and delete the extraction. If no fixed point exists, the transplant approach itself needs
replacing -- the addresses inside those bins have to become symbolic rather than baked.

Until then, **v7's 100.00% should not be quoted as evidence of anything**, and the honest headline
for v7 is that it is unreconstructed.

## Artefacts kept here

| file | what it is |
|---|---|
| `v7_c_divergence.json` | The 5,118 bytes, by file and offset, where the committed C does not reproduce the v7 ROM. Useful independently of the attempt: it is the precise work list for fixing the C. |
| `apply_v7_c_divergence.py` | Applies that patch to compiler output. Not wired into the build. |

The 288 pure ROM slices were not committed, because nothing uses them and
`extract_v7_bins.py` regenerates them on demand.
