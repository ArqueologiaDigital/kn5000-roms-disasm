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

# De-circularisation: FAILED, then SUCCEEDED -- and the failure was my own bug

**v7 IS DE-CIRCULARISED as of 2026-08-21.** `rom_provenance_poison.py v7` reports 0 differing
bytes: the build reads nothing from the v7 ROM, and the gate is 9/9 without the extraction step.

## How it was done

1. The 288 `.incbin`-referenced bins with no source of any kind (136,775 B) are committed in
   `v7/maincpu/includes/romslices/` and the 51 source files that reference them repointed.
2. Of the 76 C-compiled bins, 53 match the ROM exactly and 23 diverge -- by only **5,118 bytes**
   inside 703,651 B of files. Rather than committing 703 KB of blob and hiding 691 KB of
   genuinely-reconstructed C behind it, the divergence is a committed patch,
   `v7/maincpu/includes/v7_c_divergence.json`, applied by `scripts/build/apply_v7_c_divergence.py`
   on top of the compiler's output.
3. `extract_v7_bins.py` and both of its invocations are gone from the Makefile, along with the ROM
   as a prerequisite of the v7 object.

Honest v7 figure now: **1,955,259 B (93.2%) real source**, and 141,893 B (6.8%) committed blobs
that are documented as having no source -- 136,775 B of pure ROM slices plus the 5,118 divergent
bytes. Those are honest under the completeness spec's §3, and they are the remaining work: fixing
the C until `v7_c_divergence.json` is empty is what would make v7 genuinely reconstructed.

## ⚠ THE EARLIER "PROOF" THAT THIS WAS IMPOSSIBLE WAS MY OWN FILE CORRUPTION

An earlier pass concluded, and committed to the status document, that "v7 cannot currently be
rebuilt from committed inputs at all" -- on the evidence that with all 353 bins verified identical
to a successful build's output, rebuilding still gave 46.33% with every pointer shifted 208 bytes.

That was not the build. It was the script that repointed the `.incbin` paths. It read each `.s`
with `Path.read_text(errors='replace')` and wrote it back, which replaces every byte that is not
valid UTF-8 with U+FFFD -- and these sources contain `.ascii` directives holding raw non-UTF-8
bytes. Rewriting them changed the assembled length of those literals, which moved everything after
them. The 208-byte shift was string data I had destroyed, not evidence about the build.

Redone reading and writing BYTES, the identical change gives 9/9 and a clean poison test.

**The lesson, which is the reason this section exists:** never round-trip a disassembly source
through text decoding. `.ascii`/`.byte` payloads are binary. And when a measurement says something
strong and surprising -- "no set of committed files can rebuild this ROM" -- suspect the
measurement apparatus before publishing the conclusion. A second check was available and cheap:
assembling directly with the same inputs gave an EXACT match, which contradicted the claim.

