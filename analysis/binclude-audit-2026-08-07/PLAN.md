# Binclude Elimination Plan — audit of 2026-08-07

Source: a 10-agent audit (7 scanners + 3 adversarial verifiers) over every
`.incbin`/`binclude` directive and every compressed region in this repo.
Full machine-readable findings: `findings.json` (55 findings, 24 verdicts).
This supersedes the status tables in `DISASSEMBLY_PLAN.md`, which are stale
(they list `code_280020_28f575.bin`, now an orphan outside the build).

Inventory: 598 directives; 505 are honest build products (compiled from C/asm
or generated from documented data). The rest, plus inline raw `.byte` regions
that are morally bincludes, are catalogued below.

Evidence standard used throughout: "this is code" was accepted only after an
adversarial pass — clean decode at the claimed base, branch targets landing on
instruction boundaries, ≥1 call target coinciding with an independently known
label, and a shifted-decode control (the same bytes must NOT decode cleanly at
base+1).

---

## List 1 — compressed blocks NOT yet built from decompressed source

| # | block | where | codec | status |
|---|---|---|---|---|
| 1 | 5 multilingual HELP databases (En, De, Fr, Es, Malay/Indonesian) | inside `icons_to_strings.bin`, ROM 0x988690–0x9999D2 | **SLIDE8K** — a previously undocumented 8 KB-window LZSS variant; firmware-supported (`SLIDE_Parse_Header` dispatches '4'→4K and '8'→8K init) | raw-bincluded; each decompresses to exactly 0x9000 B |
| 2 | orphaned 6th SLIDE8K block — a superseded **German** help DB revision, referenced by nothing | ROM 0x983B3A–0x987A32 | SLIDE8K | raw-bincluded dead data; round-trip with the other five |
| 3 | `original_ROMs/kn5000_subprogram_v142_compressed.rom` (93,203 B) | firmware-update "File Type 007" payload (flashed at custom-data 0x3E0000) | SLIDE4K | decompresses byte-exactly to the **already source-built** v142 payload — only a Makefile compress rule + compare coverage is missing |
| 4 | `..._v141_compressed.rom` (93,181 B) | same | SLIDE4K | verified = f(v141.rom), but **v141.rom itself has no source tree** — tracked as kn5000-v41 |
| 5 | `..._v140_compressed.rom` (93,124 B) | same | SLIDE4K | **the only copy of v1.40 in existence here** — no decompressed reference anywhere. Preservation action: commit the decompressed 196,608 B payload + verify recompression |

**List 1 item 4 — tracked.** The v141 conversion is now issue **kn5000-v41**
in `.beads/issues.jsonl`: both v1.41 artifacts are verified internally
consistent (`kn5000_subprogram_v141_compressed.rom` decompresses byte-exactly
to `kn5000_subprogram_v141.rom`, and `compress_lzss.py --strict --with-header
--reference` reproduces the image byte-for-byte), so the only missing piece is
a `v141/subcpu/` source tree. The issue proposes deriving it from the v142
source by diff — the raw byte diff (124,033 B in 2,875 runs) opens as 5-byte-stride
address-constant ripple that symbolic assembly absorbs for free, the same
situation the maincpu v7/v9/v10 trees already handle — after which the v142
update-image compress rule (items 3/5, landed in wave 1) is cloned verbatim.

Already done (verified, not just claimed): all 19 demo presets (entries 0–17 +
Feature Presentation at 0x8E0000) round-trip from `.mid + .yaml` via
`compress_lzss.py --strict`. Two errata from verification: preset 17's LZSS
stream ends at 0x9F5676 and the remaining ~15.9 KB is non-stream tail carried
verbatim; and the SLIDE4K size field is 24-bit **BE**, not LE as the Makefile
comment and `kn5000-docs/lzss-compression.md` state. The docs' "14-byte
header" is also wrong (it is 11 bytes) — which is exactly the misframing that
produced the orphaned `original_ROMs/demo_preset_compressed_refs/` slices.

## List 2 — raw undocumented binaries

### A. Code, verified (disassemble)

| blob | size | verdict |
|---|---|---|
| `bootcode_hdae_to_lzss.bin` @0x9FC6F6 | 460 B | CONFIRMED code; **latent bug: the incbin boundary splits a 5-byte `ld A,(0x160002)` mid-instruction** (byte-matches today, fragile) |
| `bootcode_flash_handlers.bin` @0x9FD8A5 | 4,600 B | CONFIRMED code — and it is actually the **FDC command-layer driver**, not "flash update handlers"; `Boot_ClearWatchdog` is really `FDC_WaitRQM_Timeout` |
| `bootcode_utils.bin` @0x9FEB2B | 1,790 B | CONFIRMED — `FDC_ProbeDiskFormat` + the **boot-time CP-serial driver** (independent of the runtime one in the CP-serial saga) |
| `bootcode_serial_handlers.bin` + `bootcode_serial_state.bin` @0x9FF229/0x9FF2F2 | 201 + 2,148 B | three ISRs + two `.long` dispatch tables; tail 0x9FFA2C–0x9FFB2E is shared verbatim with subcpu/boot → factor into `shared/` |
| `bootcode_malloc_and_after.bin` @0x9FFB56 | 906 B | code + dead code at 0x9FFD7D (the .s claim of a "secondary-heap free()" there is wrong) + a NOP-patched debug site at 0x9FFEC1 |
| inline `.byte` block @0x9FB496 (.s:516-519) | 60 B | three FDC dispatch offset tables — prerequisite for the `jp T,XIX+WA` sites |
| `subcpu_boot_data_8000.bin` @0xFF8000 | 656 B | mixed; split ≥5 ways — code references 6+ addresses inside it |

### B. v7 tree — raw ROM slices hiding behind `generated/`

The v7-vs-v9/v10 asymmetry (288 raw ranges) is real: `extract_v7_bins.py`
dd-slices the v7 ROM at build time. Every one is an undocumented binary in
disguise:

- `v7_fix_*` — 24 files, 22 KB (three hard: tuningsystem 9.3 KB, colorblit2 4.1 KB, initializetoshi 3.4 KB)
- `v7_block_*` — **139 files** (verifier corrected the scanner's count of 23), spanning 0xED3448–0xFF242A
- `v7_transplant_*` — 67.5 KB
- `v7_data_*` — 17 KB of pointer tables (trivial: symbolic labels resolve the v7-vs-v9 pointer deltas automatically)
- 23 shared-named bins (`naka_*`, `tonegen_param_table`, …) — **703 KB of raw ROM slice silently replacing C-compile output**. Fix is to parameterize the C sources per firmware version, then delete the overwrite. Largest single item in the plan.

Strategy for all of these: diff against the v9 symbolic sibling — most differ
only in pointer constants, which symbolic assembly absorbs for free
(`v7_source_migration.py` already proved the technique).

### C. v142 subcpu + maincpu inline raw regions (critic-found)

- `subcpu_data_tables.s` ZONE A0 0x00F7E6–0x012114 (10.5 KB, garbage-decoded), ZONE A 0x012195–0x014738 (9.6 KB), ZONE B 0x0147B3–0x01E17E (39 KB — the Eff9/EffA DSP effect-parameter grammar: carve per-effect descriptor/values/bytecode labels)
- maincpu inline `.byte` content never audited: **460 KB in v7**, 108 KB in v9 — needs its own classification pass (labeled-but-undecoded tables vs code-as-bytes vs conversion residue)

### D. Big data blobs (document-as-table)

- `initial_data.bin` (524 KB): left half = 33-section floppy-save preset banks; right half @0x830000 = **the tone database** the maincpu bulk-copies to subcpu RAM 0x50000 (629-entry tone-record offset table @0x831B00 — the very table `DSP1_ResolveStreamPtr` indexes — plus drum kits, drawbar presets, percussion names). Highest documentation value in the repo; directly supports the ongoing sound work. **Refutes the CLAUDE.md claim that the subcpu executable sits at 0x830000** — that region is data; the runtime code-payload source path is still unresolved.
- `icons_to_strings.bin` (742 KB): font descriptor table + glyphs, ~970×198 B style records, model pointer tables, the help system (region's "Demo Song Index" comment is wrong), TG config records (26 B stride), demo-preset pointer table. Tail beyond file offset 0x7F2D8 is dead weight duplicating the now-source-built preset region.
- `wallpaper1_to_icons.bin` (152 KB): the name says "gap"; it actually holds two live UI draw sources.
- `icon_table.bin`, `wallpaper_gap.bin`, `section_7.bin`, `registration.bin`: trivial symbolic conversions.
- `custom_data` sections 0–6 (658 KB): factory style database in the same rhythm-cell event grammar as the rhythm ROM (cell header `80 FF FF FF FF 87`). Verdict: blob-level documentation adequate — deep-parsing is preservation of one unit's user data, not firmware RE.
- hdae5000 `code_29af2d_2fffff.bin` (414 KB): the "code_" name is a lie — it is graphics/palettes/text/pointer tables, including a **previously unidentified boot-splash image** @0x2E61CE and a string table currently mis-decoded as instructions (runs of `nop` = the tables' 0x00 padding). Init-data slice has 69 code-target + 119 string pointers to symbolize.

### E. Hygiene (cheap, zero-risk)

- subcpu boot ROM: **98,304 lines of `.byte 0xFF`** → one `.fill` (98 K-line source shrink, byte-verified).
  ⚠ **CORRECTION 2026-08-08:** the audit called this "erased flash / known padding". It is **not erased — it is
  UNDUMPED.** `kn5000.cpp` marks IC30 `BAD_DUMP` with ranges 0xFE0800-0xFF7800 and 0xFF9800-0xFFF000 "not dumped
  yet, assumed 0xFF"; measured, only **4,352 of 131,072 bytes are non-FF (3%)**. The `.fill` collapse stays
  byte-safe, but the comment must say UNDUMPED, and any "sub-CPU boot ~99% disassembled" figure is meaningless.
- orphans to delete or move to `analysis/`: 9 table_data `bootcode_*` bins (62 KB), 5 hdae5000 `code_*` bins, `demo_preset_compressed_refs/` (19 misframed slices), 2 `note_voice_mapping_v9_patch.bin`, `table_data_bootcode.bin`
- `transplant_manifest.txt`: prune to the 225 referenced entries (40× smaller audit surface)
- docs errata: lzss-compression.md (header size, endianness), hdae5000.md (font/palette labels, "multiple palettes"), CLAUDE.md (0x830000)
- `.beads` issues: reuse m1j/1ru/16s/si0; audit the five `e0xxxx` "Document binary include" issues for closure
- `kn5000_subprogram_v141.rom`: no source tree, no compare coverage — file an issue either way

---

## Execution plan — parallel taskforce with manager integration

Non-negotiable invariant: **`make all` + `compare_roms.py` at 100% byte-match
after every merge.** Workers never touch git; the manager owns the branch.

**Worker contract.** Each worker gets one package (below), read-only access to
the tree, and returns: (a) replacement `.s` text with semantic MixedCase
labels matching existing conventions, a documentation header per module, and
per-table comments; (b) the evidence for every label (xref address or
behavior); (c) a self-check: the worker assembles its fragment standalone and
byte-compares against the original ROM slice before returning.

**Manager protocol.** Applies one package at a time on a dedicated branch;
runs the full build + byte-compare; on mismatch returns the diff to the
worker (one retry, then escalate); on match commits (succinct message, one
commit per package); updates the issue tracker and CHANGELOG. After each wave:
a re-audit that greps for regressions (new LABEL_ placeholders, dropped
comments, orphaned includes).

**Waves** (each wave = one workflow run, results reviewed between waves):

- **Wave 0 — foundations + tone database** (~7 agents; tone DB moved up from
  Wave 2 at Felipe's request, 2026-08-07 — it feeds the sound emulation
  directly): re-split the mid-instruction incbin boundary at 0x9FC6F6;
  symbolize the 0x9FB496 dispatch tables; write
  `compress_slide8k.py`/`decompress_slide8k.py` with `--reference`
  decision-replay (same technique as `compress_lzss.py`); docs errata batch;
  and the tone database in three tiling packages — directory + index + the
  629-entry offset table (0x830000–0x8324D3), the tone/voice records
  (0x8324D4–0x855A47), and the aux tables + percussion names + fill
  (0x855A48–0x87FFEF) — splitting `initial_data.bin` so its left half stays
  an incbin until Wave 2.
- **Wave 1 — bootcode + SLIDE8K round-trip** (~8 agents): the six bootcode
  packages (A above, including renames the verifier mandated); split
  `icons_to_strings.bin` at block boundaries, check in decompressed help DBs,
  wire the Makefile; v142-compressed compress rule; v140 preservation commit.
- **Wave 2 — table_data conversion** (~9 agents): fonts; style records +
  model tables; help index/strings; TG config; tone-database directory +
  offset table; tone records; preset banks; wallpaper/icon tables; hkst/gap
  trivia.
- **Wave 3a — DSP-related only** — ✅ **DONE 2026-08-07** (commits `c5816ae`,
  `09a82ec`, `85ecca2`, docs `1bd4690`). Zones A0/A/B carved and annotated.
  ⚠ Two claims this plan carried were REFUTED by the work: there is no
  "exponential pitch table @0x13318" (it is `DSP_MixerGain_Curve`), and the
  0x00FF00/0x00FF80 "two 128-byte tables" banner claim is retracted.

---

# Remaining waves — resumable plan (saved 2026-08-07)

Everything below is **not started**. Waves 0, 1, 2 and 3a are complete; the
build gate has held at 100.00% × 15 sections (the "×16" in one Wave-2 ledger
row was a miscount) after every one of the 24 packages landed so far.

**How to restart.** Read `WAVE-STATUS.md` for what landed, then launch one
wave as a Workflow with the same shape every previous wave used, because it
has worked 24/24 times:

1. N read-only worker agents draft in parallel into a scratch dir, each with a
   **mandatory self-check**: assemble the fragment standalone and byte-compare
   against the original ROM slice, quoting commands and output. A fragment that
   does not match returns `blocked`/`partial` with the diff — never silently.
2. One **integration manager** — the only agent allowed to touch the repo —
   applies packages one at a time, runs `make all` + `compare_roms.py` after
   each, commits on 100% and surgically reverts (hand edits, never
   `git checkout/reset/stash`) on anything less.
3. Manager appends a ledger row to `WAVE-STATUS.md`.

**★★ THE GATE COMMAND MATTERS — a wave-3b manager caught this the hard way.**
Run `make clean-all && make all && make asl-all && python3
scripts/build/compare_roms.py`. `make clean-all` deletes the ASL ROMs and
`make all` does **not** rebuild them, so `compare_roms.py` then silently reports
**9 sections instead of 15** — and a manager reading "everything says 100.00%"
passes a gate that never tested the six legacy ASL mirror builds. Always count
the sections, not just the percentages. (`clean-all` is also what catches stale
object files: `hd-ae5000_v2_06i.llvm.o` depends only on the top-level `.s`, not
on the files it `.include`s.)

Non-negotiables for every wave: blob files that `archive/asl/` bincludes stay
byte-identical on disk (slice with `.incbin "file", offset, length` instead);
symbols reference files are UPPERCASE and address-sorted; disasm commits carry
the `LLVM: tlcs900_backend @ ...` line the hook enforces; kn5000-docs commits
need a passing jekyll build and must leave the pre-existing uncommitted
`flowcharts/` edits alone; nothing is ever pushed.

## Wave 3b — hdae5000 + subcpu boot (~7 packages)

| package | scope |
|---|---|
| `hdae-strings` | re-decode the string table ~0x2A7736–0x2A8499, currently **mis-decoded as instructions** in `hdae5000_data_tables.s` (~lines 33150–33301: runs of `nop` are the tables' 0x00 padding, plus junk like `ld xiy,0x5443454c`) |
| `hdae-slices` | re-split the four `code_29af2d_2fffff.bin` slices at the real boundaries 0x2A858E / 0x2A898E / 0x2BB58E / 0x2BB98E / 0x2CE58E / 0x2CE98E / 0x2E158E / 0x2E198E / 0x2E61CE; retire the false `HDAE5000_Font_Data` label |
| `hdae-splash` | extract the **previously unidentified 320×240 boot-splash** at 0x2E61CE + its palette; add to `convert_images.py` IMAGE_METADATA and the gallery |
| `hdae-initdata` | symbolize the init-data slice at 0x2F94B2: 69 code-target pointers + 119 name-string pointers bound to the re-decoded string labels |
| `subcpu-bootdata` | split `subcpu_boot_data_8000.bin` (656 B) ≥5 ways — code references ≥6 addresses inside it; emit the 8-entry table as symbolic `.long` |
| `subcpu-fill` | replace 98,304 lines of `.byte 0xFF` in `kn5000_subcpu_boot.s` with one `.fill 0x18000,1,0xff` (≈98 K-line source shrink, zero byte risk). ⚠ the comment must say **UNDUMPED**, not "erased" — see the correction above |
| `hdae-docs` | fold the findings into `hdae5000.md` (the "code_" blob is graphics, not code) |

## Wave 4 — the v7 tree (~10 packages, the largest wave)

`extract_v7_bins.py` dd-slices the v7 ROM at build time; every slice is an
undocumented binary behind a `generated/` path. Strategy throughout: **diff
against the v9 symbolic sibling** — most differ only in pointer constants that
symbolic assembly absorbs for free (`v7_source_migration.py` proved this).

| package | scope |
|---|---|
| `v7-data` | 16 `v7_data_*` pointer/string tables, 17 KB — trivial, symbolic labels resolve the deltas |
| `v7-fix-small` | the 21 small `v7_fix_*` files |
| `v7-fix-tuning` | `v7_fix_tuningsystem_handler_table` (9.3 KB) — hard, one agent |
| `v7-fix-colorblit` | `v7_fix_colorblit2_largecodeblock` (4.1 KB) — hard, one agent |
| `v7-fix-toshi` | `v7_fix_initializetoshi` (3.4 KB) — hard, one agent |
| `v7-block-*` | **139 files** spanning 0xED3448–0xFF242A, in size-sorted batches (the audit scanner said 23; the verifier corrected it) |
| `v7-transplant` | resume the `v7_source_migration.py`-style re-conversion of the 225 referenced transplants; prune `transplant_manifest.txt` to those 225 (40× smaller audit surface) |
| `v7-cdata` | **703 KB of raw ROM slice silently replacing C-compile output** (23 shared-named bins: `naka_*`, `tonegen_param_table`, `sepaout_config`, …). Fix: parameterize the C sources per firmware version so compilation alone reproduces the v7 bytes, then delete the overwrite. ⚠ The >50 %-similarity heuristic in the build is a **silent-corruption risk** — flag it. Largest single item in the plan; may need its own wave |

## Wave 5 — sweep and close-out (~6 packages)

- **maincpu inline-`.byte` audit** — ~676 KB never classified: 460 KB in v7,
  108 KB in v9, the rest v10. Separate (a) labelled-but-undecoded tables,
  (b) code-as-bytes under `_Data` labels (disassemble), (c) v7 conversion residue.
- **maincpu effect/name tables** — the effect-name table at maincpu 0x033568
  and the parameter-name table at 0x0324D5 are read from ROM by tooling but
  **not carved in source**; Wave 3a's docs quote them. Carve and label them.
- **orphan cleanup** — 9 `table_data/includes/bootcode_*` bins (62 KB),
  5 hdae5000 `code_*` bins, `demo_preset_compressed_refs/` (19 misframed
  slices), 2 `note_voice_mapping_v9_patch.bin`, `table_data_bootcode.bin`:
  delete or move to `analysis/`.
- **`icons_to_strings.bin` dead tail** — bytes beyond file offset 0x7F2D8
  duplicate the now-source-built preset region.
- **issue-closure audit** — the five `e0xxxx` "Document binary include" issues;
  `kn5000-1ru` UNCERTAIN entries for the now-carved subcpu zones.
- **final completeness re-audit** against `findings.json` — plus the deferred
  backlog below.

## Deferred backlog (accumulated across waves 0–3a)

Small, verified, independent items. Any wave can absorb a few; none blocks
anything.

**Renames / symbols**
- `FDC_STATUS_HANDLER` is really the seek handler (rename + docs).
- maincpu `EffectMode_*` → Stylist; `Pmem_*` / `Composer_*` per Wave 2's
  identifications.
- `maincpu_symbols_reference.txt` is stale (`FDC_InitSequence_*` et al).
- 8 zone-A0 addresses carry documentation-only aliases from the 2026-07-26
  naming pass that now duplicate real labels.

**Code**
- `BootRegLib` v2 factoring + the maincpu 0xEF17F4 copy.
- Hunt the computed consumer of effect-metadata bases 0x143AD / 0x14411 / 0x145A1.
- `TOOLCHAIN_VERSION` vs the actual llvm-mc in use.

**Assets / tooling**
- Run the new `extract_ui_bitmaps.py` / `extract_icons.py` galleries;
  `BitmapNtedt0k` orientation fix.
- `extract_fonts.py` upper-code-page rendering; font descriptor +4/+6 naming.

**Hardware questions for Felipe**
- ★ **SLOW ATTACKER on the real KN5000** (effect 37): it is one of the twelve
  stub effects — a program byte-identical to NO OPERATION — yet it is the only
  one carrying live parameter values (THRESHOLD / ATTACK RATE / RELEASE RATE /
  VOLUME / REV SEND). Prediction: indistinguishable from no effect. If it
  audibly does something, the algorithm-selection path substitutes a program
  the algorithm table does not name.
- The v1.41 subcpu source tree (issue `kn5000-v41`) is unblocked whenever it is
  wanted: both artifacts verify, only the tree is missing.

**★★ TWO CHIPS NEED RE-DUMPING — this blocks a real preservation question.**
The sub-CPU payload's source on a stock machine is **unresolved**. Boot code
(`v10/maincpu/kn5000_v10_program.s:346-360`) picks between table-data 0x800000
and custom-flash 0x3E0000 via a marker byte in the maincpu flash; the marker is
0xFF, selecting 0x3E0000 — and **our IC19 dump is 0xFF from 0xE0000 to the end**,
with no SLIDE4K magic anywhere in the chip. The other candidate holds the preset
banks, not code. The payload appears in neither dumped image. The emulator only
works because `kn5000.cpp` ROMX_LOADs the compressed payload *extracted from an
update floppy* over that blank region — a reconstruction, not a chip image.
- **Re-dump IC19, especially 0xE0000-0xFFFFF.** Either it confirms the payload
  lives there, or "the dump is stale" dies and this becomes a real mystery.
- **Dump IC30 properly** (see the correction above): 97% unread, and the leading
  alternative hiding place.

Estimated remaining: ~23 worker packages across 3 waves, plus the backlog.
