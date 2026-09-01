# The coverage instrument was double-counting HD-AE5000 -- fixed, and a trustworthy
# 13-image debt inventory (lane INSTR, 2026-09-01)

LLVM: tlcs900_backend@dbb72df07371 (dbb72df073711ef98be1e41f003e04a7022bf120)

## Question this answers

`notes/lanes/BRIEF-2026-09-01.md` assigned lane INSTR to fix the measuring instrument
itself (`scripts/analysis/kn5000_source_coverage.py`), because it was reporting an
impossible number for HD-AE5000:

    HD-AE5000   ROM 524,288   incbin 626,152   source -101,864   -19.4%

An incbin total larger than the ROM, and a negative source figure, are both
impossible. This file records the root cause, the fix, and a corrected per-image
debt inventory for all 13 gated images (9 KN5000 + 4 WSA1R).

Reproduce everything below with:

    python3 scripts/analysis/kn5000_source_coverage.py        # the table
    python3 scripts/analysis/kn5000_source_coverage.py --selftest   # the invariants

(run `make all` first so every `includes/generated/*.bin` exists on disk -- an
unbuilt generated file cannot be sized, and the tool says so on stderr rather than
guessing.)

## Root cause

`hdae5000/hdae5000_data_tables.s` carries, for each of its 10 image assets, a
historical comment recording the pre-conversion directive directly above the live
one:

```
	; Was: .incbin "includes/code_29af2d_2fffff.bin", 54881, 1024
	.incbin "includes/generated/HDAE5000_Palette_Logo.bin"
```

The old script's `.incbin`-matching regex was applied to raw file text without
stripping `;` comments first. Both lines match `\.incbin\s+"..."`, so the script
summed **both**: once for the dead "Was:" directive against the legacy monolithic
blob (`code_29af2d_2fffff.bin`), and again for the live directive against the
per-image file that replaced it -- the SAME 313,076 bytes of graphics, counted
twice, for a total of 626,152 (verified: exactly `2 * 313,076`). Once incbin exceeds
the 524,288-byte ROM, `source = ROM - incbin` goes negative.

No other root in the tree has this "; Was:" fossil-comment pattern (checked
exhaustively; the `--selftest` asserts this stays true), so the double-count itself
was confined to hdae5000 -- but the regex was comment-blind everywhere, so any future
dead `.incbin` comment anywhere else would trigger the same failure silently. The fix
strips `;` comments (outside quoted strings) from every line before matching,
tree-wide, not just for hdae5000.

A second bug, found while fixing the first: the old formula's only classification of
`.incbin` bytes was a crude `"generated/" in path` substring test used to compute "of
which C". hdae5000's *round-trip image* files also live under a `generated/`
directory (produced by `hdae5000_images.py`, not clang), so that test would have
misreported them as C source. The fix classifies every `.incbin` target by the
**actual build machinery** that produces it (see `classify_incbin()` in the script):
clang (a `.c` prerequisite exists), round-trip (a checked-in PNG/txt/mid/yaml/styles
source and a build script regenerate it, `verify`-checked), or verbatim (nothing
does -- a committed blob with no decode path, i.e. real territorial debt).

## What "debt" means here (unchanged from the brief, made precise)

Per `notes/lanes/BRIEF-2026-09-01.md`: **`.incbin` of a committed blob**. A `.bin`
that a checked-in, `verify`-checked script deterministically regenerates from other
checked-in source (a `.c` for clang, or a `.png`/`.mid`+`.yaml`/`.styles`/decompressed
text database for the project's own round-trip generators) is source, not debt --
even when the intermediate `.bin` also happens to be cached in git (e.g.
`table_data/images/Wallpaper_0.bin`, which sits next to its own `.png`). A `.bin`
with no such generator (e.g. `table_data/images/FTBMP01.BMP`, which has no sibling
`.png`) is genuine debt regardless of format.

"Typed data" = bytes emitted directly in a `.s` file via a byte-emitting directive
(`.byte/.short/.long/.ascii/.asciz/.fill/.space/.zero`, or one of the four
byte-emitting macros in this tree: `naka_header`, `addr24`, `desc_entry`,
`aligned_string`) outside any `.incbin`, plus the round-trip-derived bytes above.
"Assembly" is the remainder of the non-`.incbin` bytes -- inferred by subtraction,
not independently verified as instructions. This is the tool's one known blind
spot: a long anonymous `.byte` run that is really un-analysed code lands silently
in "typed data" (this project has shipped that exact defect before -- 8,496 bytes of
v1.42 sub-CPU sound code were once `.byte`; see `notes/sound/sound_coverage.py`). A
targeted grep for this project's own self-tagged markers ("UNDECODED", "MISLABELLED,
THIS IS CODE") is run separately (`tagged_debt()`) and printed as a call-out. As of
this pass it found zero live instances: the v142/subcpu tags describe conversions
already completed (verified: real TLCS-900H instructions now follow each tag), and
the one surviving tag in v7/v9/v10's `ui_control_panel.s`
(`GroupBoxNotify_SendSSFEvent (0xf98697) [UNDECODED -- still in .byte form]`) is
stale documentation -- the code at that address, `UIState_KeyScan_Dispatch`, is
already real instructions (verified by reading it). No action needed beyond deleting
the stale tag, which is outside this lane's scope (semantic labeling is deferred).

## Corrected per-image inventory (all figures byte-exact except where noted)

Built and gated 2026-09-01 in this worktree: `make all` succeeded, `python3
scripts/analysis/assert_byte_identical.py --no-build` reports IDENTICAL for all
9 KN5000 images.

| image | ROM bytes | assembly | typed data | clang C | DEBT (verbatim) | % source |
|---|---:|---:|---:|---:|---:|---:|
| maincpu v10 | 2,097,152 | 982,600 | 1,104,130 | 5,494 | 4,928 | 99.8% |
| maincpu v9 | 2,097,152 | 984,332 | 1,102,398 | 5,494 | 4,928 | 99.8% |
| maincpu v7 | 2,097,152 | 659,847 | 1,307,884 | 5,494 | 123,927 | 94.1% |
| subcpu payload v142 | 196,608 | 124,124 | 72,484 | 0 | 0 | 100.0% |
| subcpu boot (IC30) | 131,072 | 31,863 | 99,209 | 0 | 0 | 100.0% |
| table data | 2,097,152 | 76,897 | 1,684,217 | 0 | 336,038 | 84.0% |
| custom data (IC19) | 1,048,576 | 0 | 1,048,576 | 0 | 0 | 100.0% |
| HD-AE5000 | 524,288 | 120,418 | 403,870 | 0 | 0 | 100.0% (was -19.4%) |
| wsa1/prom_a | 524,288 | 318,900 | 159,082† | 0 | 46,306 | 91.2% |
| wsa1/prom_b | 524,288 | 197,753 | 285,723† | 0 | 40,812 | 92.2% |
| wsa1/prom_c | 524,288 | 207,546 | 316,742† | 0 | 0 | 100.0% |
| wsa1/prom_d | 524,288 | 0 | 524,288† | 0 | 0 | 100.0% |
| ALL 13 | 12,386,304 | 3,704,280 | 8,108,603 | 16,482 | 556,939 | 95.5% |

† of which 48,437 / 62,966 / 129,216 / 193,767 bytes respectively are verified
`.fill` padding (wsa1's own `scripts/analysis/source_coverage.py` distinction,
reused here rather than re-derived).

custom_data (IC19) is legitimately 0 assembly -- it is a pure data flash region
(accompaniment styles, wallpaper/registration-memory storage), no CPU code lives
there at all; confirmed by grep, no TLCS-900H mnemonics anywhere in the tree.

## Where the remaining 556,939 bytes of genuine debt actually are

Ranked by absolute bytes:

1. table data -- 336,038 B (60% of all remaining debt). Broken down:
   `images/FTBMP01.BMP` (77,878), `FTBMP06.BMP` (77,878), `FTBMP02.BMP` (42,678),
   `FTBMP05.BMP` (41,078), `FTBMP03.BMP` (39,478), `FTBMP04.BMP` (39,478) --
   6 raw BMP images with no PNG sibling, hence no round-trip generator (compare
   `Wallpaper_0/1.bin`, which DO have one and are correctly not counted as debt) --
   plus 17,570 B of leftover `includes/icons_to_strings.bin` slices (the legacy
   blob `scripts/analysis/audit_icons_blob_coverage.py` already tracks). This is
   the single largest, most tractable target: giving the 6 BMPs the same
   PNG-export treatment `mono_images.py` already gives every other maincpu/table_data
   bitmap would clear 318,468 of these 336,038 bytes with an established, proven
   technique.
2. maincpu v7 -- 123,927 B (22%). Entirely under `includes/romslices/*.bin`,
   already individually named and documented (`v7_fix_*`, `v7_block_*`,
   `v7_transplant_*`, `v7_data_*` -- 40+ distinct, itemized slices). This is where
   v7 diverges from v9/v10 and has not yet been given real instructions/typed
   structure; the naming shows prior analysis has already scoped each slice.
3. wsa1/prom_a -- 46,306 B (8%) and wsa1/prom_b -- 40,812 B (7%), both
   plain `.incbin` (no generator infrastructure exists for WSA1R at all --
   everything there is either real assembly/typed data or raw `.incbin`).
4. maincpu v9 and v10 -- 4,928 B each (<1%), identical figure in both,
   consistent with these being the same handful of leftover slices shared between
   the two closely-related firmware versions.
5. Everything else (v142/subcpu, subcpu boot, table_data's actual code, custom_data,
   HD-AE5000, wsa1/prom_c, wsa1/prom_d) is zero verbatim debt.

Where the rest of this push should aim: table_data's 6 BMPs (a known, bounded,
mechanical conversion) and maincpu v7's already-itemized romslices are 82% of all
remaining measured debt across all 13 images combined.

## Selftest -- asserts absent defects, not today's numbers

`python3 scripts/analysis/kn5000_source_coverage.py --selftest` (38 checks, 0
failures as of this commit) asserts, per image: assembly/verbatim never negative, no
class exceeds the ROM size, and `assembly + typed + clang + verbatim == ROM size`
exactly. It also directly reproduces and guards against the actual incident: it
asserts hdae5000 has exactly 10 fossil `; Was: .incbin` comments (found and
excluded, not silently ignored), that no other root has any, and that hdae5000's
incbin total is both `<= ROM size` and `< 500,000` (i.e. nowhere near the buggy
626,152 figure this file replaces). Verified against the actual pre-fix code path:
reproducing the old comment-blind regex on this tree today still yields exactly
626,152 for hdae5000 -- confirming the selftest's tripwire is not vacuous.
