# Per-range data census of all twelve gated images — 2026-09-02

**The question this answers, in the project owner's words:** *"for each data range
you must have an understanding of its purpose — what does the data represent. If
you find ranges of the ROMs for which you can't explain the purpose of the data,
you must build a list of such targets for future research, and that would mean
we're not really at 100% yet."*

**The one-line verdict — do not round it in our favour:**

> Of the 12,386,304 bytes, **we can actually explain about 93.8 %** (≈11.61 MB).
> The raw census says 99.78 %; that figure is **wrong by construction** and the
> corrections are itemised below. A 95 % confidence interval from the audit
> sample is **86.7 % – 96.6 %**, and under the strictest reading — that a section
> header does not explain a 30 KB blob it happens to sit above — it falls to
> **≈82 %**.

Tool: `scripts/analysis/data_range_census.py` (`--selftest` passes, 47 checks).
Measured at worktree `w13/census-inventory`, base commit `531f681f`.
Toolchain: `tlcs900_backend @ 6f456a19f05b`
(`6f456a19f05bf94696728e89e74a53ed62dc9adf`) — stated because the map is built by
assembling and linking, and this tree has already been burnt by two lanes
measuring with two different builds.

    python3 scripts/analysis/data_range_census.py --selftest
    python3 scripts/analysis/data_range_census.py --json out.json --targets 60
    python3 scripts/analysis/data_range_census.py --load out.json --sample 40 --grade KNOWN-B

Committed outputs: `notes/data-census-2026-09-02/` (run, target list, audit
sample, and a README saying how to regenerate each).

**This lane changed no source.** `make gate-all` re-run afterwards in this
worktree: 8/8 KN5000 images assemble, **13 of 13 rebuilt ROMs byte-identical**.

---

## 1. The instrument, and the proof that it is not lying

The map is `address_line_map.py`'s marker-label technique generalised from one
image to twelve. Each image's source tree is mirrored, a synthetic label
`__drc_<n>:` is inserted in front of every byte-emitting line, the mirror is
assembled and **linked with the real linker script**, and the marker addresses
come out of the ELF symbol table. Byte `[addr(n), addr(n+1))` is emitted by the
line marker *n* was written in front of.

Two things make this a measurement rather than a tally:

* **Inertness.** A label emits no bytes, so the marked mirror must still *be* the
  dump. Every image is objcopy'd to a raw binary and compared against
  `original_ROMs/`. **12 of 12 byte-identical.** A mirror that is not inert is
  refused rather than reported.
* **Reconciliation.** Every byte lands in exactly one bucket and the per-image
  total must equal the dump size. **The run aborts on a non-zero delta.** This
  caught three real defects while the tool was being written (see §7).

Independent corroboration of the CODE/DATA split: the pre-existing, unrelated
`scripts/analysis/l1_territory_map.py` flattens the same three maincpu images
through `llvm-mc -show-encoding` and counts instruction bytes from the encoding
field. It never sees a marker or a symbol table.

| image | l1_territory_map CODE | this census CODE | delta |
|---|---:|---:|---:|
| v7 | 719,101 | 719,106 | +5 |
| v9 | 1,013,308 | 1,013,313 | +5 |
| v10 | 987,002 | 987,011 | +9 |

Two instruments that share no code agree to within 9 bytes in 2 MB. Both
reconcile to the ROM size exactly, so that residue is an attribution boundary
(most likely instruction-emitting macros, which the two size at different
granularity) and not a lost byte — but it has not been chased to the line. The `PADDING`/`FILLER` columns differ by more (v7 66,779 vs
63,467) and that difference is *intended*: this census only calls a fill
**FILLER** when its ROM bytes are **verified uniform** and the run is ≥ 16 bytes.
Short and mixed-value fills are graded as data like anything else.

---

## 2. Reconciliation — print it and fail loudly

    image              dump     census      delta  inert
    v10             2097152    2097152          0  yes
    v9              2097152    2097152          0  yes
    v7              2097152    2097152          0  yes
    v142             196608     196608          0  yes
    subboot          131072     131072          0  yes
    tabledata       2097152    2097152          0  yes
    customdata      1048576    1048576          0  yes
    hdae5000         524288     524288          0  yes
    prom_a           524288     524288          0  yes
    prom_b           524288     524288          0  yes
    prom_c           524288     524288          0  yes
    prom_d           524288     524288          0  yes
    TOTAL          12386304   12386304          0

The thirteenth gated image, `kn5000_subprogram_v142_compressed.rom`, is *not* in
the census: it is the v1.42 payload re-compressed, so its bytes are the same
bytes already counted under `v142`. Counting it would inflate the denominator
with a duplicate.

⚠ `v142`'s ROM is two slices of the linked image spliced by `dd`
(`full[0:256] + full[60416:]`). The census maps addresses through that splice and
drops the 60,160-byte hole, which is why its 196,608 reconciles.

---

## 3. The census

Bytes. Every byte of every image is in exactly one column.

| image | CODE | KNOWN-A | KNOWN-B | UNKNOWN | FILLER |
|---|---:|---:|---:|---:|---:|
| v10 | 987,011 | 177,349 | 868,436 | 1,291 | 63,065 |
| v9 | 1,013,313 | 157,943 | 860,586 | 1,277 | 64,033 |
| v7 | 719,106 | 156,484 | 1,157,905 | 3,510 | 60,147 |
| v142 subcpu | 127,464 | 47,291 | 21,797 | 8 | 48 |
| subcpu boot | 3,604 | 868 | 37 | 0 | 126,563 |
| table data | 18,676 | 716,439 | 1,164,976 | 0 | 197,061 |
| custom data | 0 | 660,657 | 0 | 0 | 387,919 |
| HD-AE5000 | 112,335 | 330,533 | 50,845 | 0 | 30,575 |
| prom_a | 327,427 | 60,890 | 70,580 | 2,295 | 63,096 |
| prom_b | 198,037 | 130,391 | 115,821 | 9,034 | 71,005 |
| prom_c | 207,511 | 84,547 | 102,394 | 620 | 129,216 |
| prom_d | 0 | 225,863 | 95,886 | 8,772 | 193,767 |
| **TOTAL** | **3,714,484** | **2,749,255** | **4,509,263** | **26,807** | **1,386,495** |

* **CODE** — instruction statements, 30.0 % of the tree.
* **KNOWN-A** — the header states what the data represents **and** cites evidence
  (a reader, a call site, a record layout, a field meaning, a findings file).
* **KNOWN-B** — a **descriptive, non-address-derived label**, with or without a
  header. `Font_Svc07_8x16`, `DrumKitNames`, `Wallpaper_0`. This *is* real
  understanding — it is not a `Data_F12345` address label — but it rests on
  somebody's naming judgement and nothing else, so it is counted separately and
  **it is the bucket the false-positive audit is drawn from.**
* **UNKNOWN** — address-derived or absent label with no explanatory header, or a
  header that admits the purpose is not established.
* **FILLER** — a fill directive whose ROM bytes are verified uniform, ≥ 16 B.

**KNOWN-B is 36.4 % of the whole tree and 4,151,831 B of it — 33.5 % of all
12.4 MB — is graded on a name with NO header at all.** That single line is the
honest weak point of any "we understand the ROMs" claim, and it is why the
headline below is corrected rather than quoted.

    KNOWN-B by reason (bytes)
      descriptive name only ................................ 4,151,831
      descriptive name + header ............................   282,412
      section header only (address-derived label) ..........    34,715
      short/non-uniform fill: descriptive name only ........    29,205
      file header + local header ...........................    10,035
      (three smaller categories) ...........................     1,065

Per-image share the raw census calls explained, and the strict A-only floor:

| image | raw explained | A-only |
|---|---:|---:|
| v10 | 99.94 % | 58.53 % |
| v9 | 99.94 % | 58.90 % |
| v7 | 99.83 % | 44.62 % |
| v142 | 100.00 % | 88.91 % |
| subcpu boot | 100.00 % | 99.97 % |
| table data | 100.00 % | 44.45 % |
| custom data | 100.00 % | 100.00 % |
| HD-AE5000 | 100.00 % | 90.30 % |
| prom_a | 99.56 % | 86.10 % |
| prom_b | 98.28 % | 76.19 % |
| prom_c | 99.88 % | 80.35 % |
| prom_d | 98.33 % | 80.04 % |

---

## 4. The false-positive rate — sample size, method, and what failed

⚠ **A census with no error bar is the thing this project keeps having to
retract.** So the "known" figure was audited rather than asserted.

**Method.** 40 regions drawn from `KNOWN-A ∪ KNOWN-B`, **size-weighted** (a byte
is as likely to be drawn as any other byte in the pool), seed 90902, reproducible
with `--load ... --sample 40 --seed 90902`. Regions already flagged
`embedded-in-code` were excluded from the pool because that class is counted
*exactly* — sampling it too would measure the same error twice. Each drawn region
was read by hand against one test: **from the label and the header attached to
it, can a reader say what these bytes represent?**

**Result: 3 of 40 fail outright — 7.5 %.** Wilson 95 % interval 2.6 % – 19.9 %.

| # | region | why it fails |
|---|---|---|
| 11 | `v7 midi/midi_dispatch_handlers.s:6907` `SeqAlt_NibbleSearch_DecLoop`, 8 B | not data at all — undecoded code under a routine name |
| 20 | `prom_b 0x077836` `Data_F77836`, 415 B | its own header says *"415 bytes this block could not split. No content rule framed it … emitted as bytes rather than guessed"* — an admission my phrase list did not catch. ✅ **CLEARED 2026-09-02**: 33 B SMF template + 66 B word table + 316 B code (§9) |
| 35 | `v10 ui_widgets/widget_descriptors.s:401` `NakaInst_OFF_Str`, **37,262 B** | the label names a three-byte string; the region is 37 KB (see §5) |

**A further 8 of 40 (20 %) pass only at a coarse granularity** — the label or
section header explains the *blob* the range belongs to, not the range: e.g.
`Naka_ReverbScreen_EmptyStr` covering 23,538 B under a header that says
"Effects & Sequencer screen widgets, source `naka_effects_seq.c`", or
`CustomData_Section_0` covering 94,112 B under a header that explicitly says
"*the 16-char name at +0x40 is the only field established … no field semantics
beyond the name are claimed*". Whether those count is a judgement call, so both
readings are carried through to the verdict rather than one being chosen
silently.

An earlier 30-region sample (seed 11) with the pre-fix instrument found the same
failure classes plus two the fixes removed; it is what produced §7.

### The arithmetic behind 93.8 %

    explained by the raw census .......................... 12,359,497   99.78 %
      minus  embedded-in-code counted as KNOWN (measured) .   -217,112
      minus  7.5 % of the remaining 7,041,406 KNOWN bytes .   -528,105
    corrected ............................................ 11,614,280   93.77 %

      at the sample's 95 % upper bound (2.6 %) ........... 11,959,308   96.55 %
      at the sample's 95 % lower bound (19.9 %) .......... 10,741,145   86.72 %
      if the 8 coarse-granularity passes also fail (27.5 %) 10,205,998   82.40 %

**So: no, we are not at 100 %, and the gap is roughly 6 points — about 772 KB —
not the 0.2 % the raw census reports.**

---

## 5. What the census structurally CANNOT see — read before quoting it

1. **It classifies by the source's own framing.** A byte inside a `.byte`
   directive is DATA here even when it is a TLCS-900 instruction, and a byte
   inside an instruction is CODE here even when it is a string. Both errors exist
   in this tree and are documented in `DEBT-INVENTORY-2026-09-02.md`; §6 flags
   what it can, but the census is not an adjudicator.
2. **A region is only as explained as the ONE label and header attached to it.**
   A C-compiled struct enters the ROM as a *single* `.incbin` of 150,888 B, and
   the labels around it are offsets into it — so a region can be vastly larger
   than the object its label names. **133 regions of ≥ 8 KiB carry 3,413,250 B —
   47.0 % of the entire explained-data figure — and 23 regions of ≥ 32 KiB carry
   1,609,518 B (22.2 %).** Failure #35 above is exactly this shape.
3. **`self-admitted` is a superset, not a verdict.** A header saying "Unknown:
   the encoding, and why the firmware keeps two disjoint ideograph sets" about a
   font whose role, metrics, cell count and loader address are all established
   trips the flag. That font's *purpose* is known; an open question about it is
   not the same thing.
4. **The FILLER rule is byte-verified but arbitrary at the edge**: uniform and
   ≥ 16 B. Shorter uniform runs are graded as data, which is why FILLER here is
   ~3 KB per maincpu image below `l1_territory_map.py`'s PADDING.

---

## 6. Code that may be misclassified as data — flagged, NOT converted

Three independent flags. **Nothing was converted; this lane changes no source.**

| flag | regions | bytes | what it means |
|---|---:|---:|---|
| **embedded-in-code** | 34,999 | **222,810** | an undocumented data region with an *instruction* region on both sides in the same file |
| **code-shaped label** | 26,853 | **542,405** | the label carries a routine token (`_Loop`, `_Prologue`, `_Dispatch`, `Initialize*`, …) |
| **code-suspect** | 1,089 | **85,536** | a label at or inside the region is the target of a `call`/`jp`/`jr`/`jrl` somewhere in the tree |

The code-shaped-label flag is reported **with its null**, because a name-based
heuristic without one is worthless:

* **positive control** — regions the source itself frames as CODE: **47.2 %** of
  145,694 carry such a name;
* **null** — data regions of the three pure-data images (`table_data`,
  `custom_data`, `prom_d`), where a hit can only be a false positive: **4.7 %**
  of 7,611.

A 10× separation, so the flag carries real signal, with an expected ~4.7 %
false-positive floor by region count. It is a **lead**, not a verdict — the
project's own record (`DEBT-INVENTORY`) is emphatic that decode-shaped statistics
on this tree read either way without a reader.

Worked examples confirmed by hand, all in v7, all plainly TLCS-900 instruction
bytes under routine names:

    v7 audio/sprintf_core.s:556        Sprintf_MainLoop_ReadNext         27 B
    v7 audio/note_voice_mapping.s      CharMap_ActivePreamb_Prologue     40 B
    v7 audio/note_voice_mapping.s      SndParam_ProcessEntry            409 B
    v7 sequencer/sequencer_ui.s:5855   InitializeKubo                 1,280 B

These are the previously measured v7 code-as-`.byte` debt (275,822 B) seen from
a different angle, and they are the reason v7's A-only figure is the tree's worst
at 44.62 %.

---

## 7. Four defects found while building this tool, and what found each

Only the first was caught by the reconciliation — which is the argument for the
reconciliation being a hard abort rather than a warning. **The other three were
caught by reading the audit sample by hand, and every one of them would have
passed every automated check in this tool**, including the byte gate: none of
them moves a byte, they only move the *attribution* of bytes.

1. **`.include` stole its target's first bytes.** *(caught by the reconciliation:
   a −36 B delta on prom_d.)* Several markers share an
   address whenever a line emits nothing there, and an `.include` marker sits at
   the same address as the first line of the file it pulls in. Marker index is
   *not* emission order — files are walked alphabetically, so an included file's
   markers can be numbered before or after the `.include`. prom_d lost exactly
   36 B to three `.include` lines. Fixed by keeping only the *emitting* entry of
   each address group.
2. **A label on the same line as its directive was credited to the previous
   label.** *(caught by the audit sample.)* `Bitmap_1bit_Illegal_Disk: .incbin "…"` is one line, and there are
   thousands of that shape; the sample reported a 616 B bitmap as
   `SLIDE_STRING_2`, which is the label of the object above it.
3. **A banner propagated down through every later object in the file.**
   *(caught by the audit sample.)* A run of
   1-bit bitmaps was being credited to a "DMA ISR event router" header belonging
   to a table far above them. A header is now credited only if it ends within 6
   lines of the object's own label. **This fix, together with defect 2, moved
   1.73 MB from grade A to grade B** (KNOWN-A 4,474,258 → 2,749,255) — an
   unanchored header rule overstates the evidence-backed figure by more than a
   megabyte.

4. *(caught by the audit sample.)* Less dangerous, but the same shape: merging `.zero 30` with three `.fill n,1,0xFF` runs
produced one 73,556 B "non-uniform fill" region that then fell through to the
data grader. Fill directives are no longer merged.

---

## 8. The ranked list the owner asked for

**36,265 merged ranges, 435,048 bytes, 3.51 % of the tree**, by three reasons of
very different strength (apportioned where a merged range has more than one):

    embedded-in-code   222,810 B    undocumented data between two instruction regions
    self-admitted      195,038 B    the tree's own open questions (a SUPERSET, see §5.3)
    no-explanation      17,200 B    nobody can say what this is

Regenerate with `--targets N`. Largest 40:

| image | range | bytes | label(s) | why | shape |
|---|---|---:|---|---|---|
| prom_b | 0x01EAB0-0x024DC0 | 25,360 | `Font_Svc1C_16x16` … `Font_Svc1F_*` | **NARROWED 2026-09-02** | glyph |
| prom_a | 0x06B5C4-0x06F746 | 16,770 | `DrumKitNames` | self-admitted | text |
| prom_a | 0x078000-0x07A580 | 9,600 | `SplashImage_DitherA` | self-admitted | bitmap |
| prom_b | 0x006800-0x008CD8 | 9,432 | `ScaleTuningOff` … `SoundCodeByGroupMember` | self-admitted | ptr-table, text |
| **prom_d** | **0x044B26-0x046D6A** | **8,772** | `DrawbarPreset_EnvDescTable_Pool_B000/B001` | **no-explanation** | — |
| table data | 0x057914-0x05959D | 7,305 | `ToneDB_EnvDescTable` | self-admitted | — |
| v7 | 0x1804E2-0x1820C0 | 7,134 | `AudioCtrl_DataBlock` | embedded-in-code | — |
| prom_b | 0x078029-0x0799E8 | 6,591 | ~~`Data_F78029` … `Bitmap_F799D0`~~ → `DLGlyph_*` | ~~no-explanation~~ **CLOSED**, see §8.3 | bitmap (**not** text) |
| prom_b | 0x07669D-0x0779D5 | 4,920 | ~~`Data_F7669D` … `Data_F77836`~~ | ✅ **CLEARED 2026-09-02** | SMF export template + writer code — see §9 |
| prom_b | 0x04FF61-0x0511C7 | 4,710 | `LinkTable_F4FF61` | self-admitted | — |
| v7 | 0x10D7E7-0x10E905 | 4,382 | `.Lc_f0d7e3` | embedded-in-code | — |
| prom_d | 0x01C8CF-0x01D965 | 4,246 | `PercInst_Template_Silent` … `ToneDB_ToneIndexMapA` | self-admitted | ptr-table |
| prom_d | 0x02DF5C-0x02EFF2 | 4,246 | `ToneDB_PercSourceIndexMapA` … `PercInst_000_Silent` | self-admitted | ptr-table |
| prom_b | 0x07D2D8-0x07E2D8 | 4,096 | `ButtonTable_Ed*` | self-admitted | ptr-table |
| prom_d | 0x021A3B-0x022A3B | 4,096 | `ToneDB_ToneIndexMapC/D` | self-admitted | ptr-table |
| prom_d | 0x04809A-0x04909A | 4,096 | `ToneDB_SourceIndexMapA/B` | self-admitted | ptr-table |
| prom_d | 0x04A44C-0x04B44C | 4,096 | `ToneDB_SourceIndexMapC/D` | self-admitted | ptr-table |
| v7 | 0x103E6F-0x104E34 | 4,037 | `.Lc_f03e6c` | embedded-in-code | — |
| prom_b | 0x0124A6-0x013264 | 3,518 | `Data_F124A6` … `ScreenTable_F1*` | self-admitted | ptr-table |
| prom_a | 0x04F000-0x04FDA7 | 3,495 | `DispatchTable_*` … `ModuleTables_FCF044` | self-admitted | ptr-table |
| prom_a | 0x04B3D3-0x04C06B | 3,224 | `Ram3800_DataImage` … `Gap_FCC06A` | self-admitted | bitmap |
| prom_b | 0x0511DD-0x051E20 | 3,139 | `RecordArray_F511DD` | self-admitted | — |
| v7 | 0x1C50A9-0x1C5CB4 | 3,083 | `FileIO_BytecodeData` | embedded-in-code | — |
| v7 | 0x0FFE77-0x10096F | 2,808 | `StringData_APCModeNames` | embedded-in-code | text |
| prom_b | 0x01B400-0x01BEF0 | 2,800 | `Font_Svc06_8x14` | self-admitted | glyph |
| prom_a | 0x0717E2-0x072269 | 2,695 | `Data_FF17E2` | self-admitted | — |
| prom_a | 0x0382A0-0x038CA6 | 2,566 | `RecordTables_FB82A0` | self-admitted | — |
| prom_b | 0x03F400-0x03FD60 | 2,400 | `Rec_F3F400` … `Rec_F3FD38` (77) | no-explanation + self-admitted | ptr-table, text |
| prom_b | 0x0133E4-0x013D34 | 2,384 | `ByteMap_F133E4` … `Data_F139AB` | self-admitted | ptr-table, text |
| prom_a | 0x02C8E6-0x02D20A | 2,340 | `Gap_FAC8E6` … `Bytes_00_to_1F` | self-admitted | ptr-table |
| prom_b | 0x015024-0x015898 | 2,164 | `EffectParamNames` … `DLB_Records_*` | self-admitted | text |
| v7 | 0x16A5D3-0x16AE03 | 2,096 | `AccScreen_UIDataBlock` | embedded-in-code | — |
| prom_a | 0x044000-0x04482F | 2,095 | `DisplayList_FC4000` | self-admitted | — |
| prom_b | 0x0147AC-0x014FAC | 2,048 | `EffectNames_F147AC` | self-admitted | text |
| prom_d | 0x04F0DC-0x04F8DC | 2,048 | `ToneDB_PercSourceIndexMapB` | self-admitted | ptr-table |
| prom_d | 0x0502FA-0x050AFA | 2,048 | `ToneDB_PercSourceIndexMapC` | self-admitted | ptr-table |
| v7 | 0x11757A-0x117CB1 | 1,847 | `.Lc_f1756e` | embedded-in-code | — |
| v7 | 0x185325-0x185A4C | 1,831 | `FDemoText_ByteData_LayoutEngine` | embedded-in-code | text |
| v7 | 0x17860D-0x178CFE | 1,777 | `PmemOutLGridCheck_JumpTable` | embedded-in-code | — |
| prom_b | 0x074FCF-0x075685 | 1,718 | `Data_F74FCF` … `Data_F75675` | self-admitted | ptr-table |

### ✅ Closed and narrowed since this list was written (2026-09-02)

**Target 3, `prom_b 0x078029-0x0799E8` — CLOSED.** The two competing framings
were mutually exclusive (parsing the pointer-bounded objects as records gets
1 of 121), and the 72-byte glyph grid wins on two independent measurements that
agree: the array ends exactly on the grid — `0xF7A1A0 − 0xF78028 = 8,568 =
119 × 72`, remainder 0 — and 119 is separately the highest glyph index the UI
ever requests. 119 icons converted over 8,568 B; the `text` hint does not
survive. ⚠ `PtrTable_F003F9` is now the open question and is **sharper**: one
table of 216 slots (not the tree's "181 + 35"), shaped 18 × 12, describing a
real twelve-screen structure whose objects are not where it says — and the
**third of four** tables in `0xF0033F-0xF007FF` to fail identically. Take all
four together. `wsa1/notes/gen_prom_b_f78028_icon_sheet.py`.

**`prom_b 0x01EAB0-0x024DC0` (25,360 B) — NARROWED, not closed.** The pixels
were never the open question: all twelve faces were already exported. The
headers' actual admission is the **encoding**, and the ordering half is now
CONFIRMED — 72 adjacent pairs of set A are dictionary words against a shuffle
null of 24.8 ± 4.8, with 0 of 10,000 permutations reaching it (9.9 sd), and
distance-2..8 controls on the null. **The source-text half is REFUTED**: there
is no Japanese text in the four images, proved with a plant test that moves
prom_a from 4 to 54 hits. So the codes were assigned by walking a document that
is not in this ROM. ★ And the service manual explains why the faces are
unreferenced at all: the SX-WSA1**R** lists eighteen areas and **Japan is not
among them** — `R` is the export suffix, and the domestic SX-WSA1 shares the
source. Still open: the source text itself (try the floppy filesystem and any
compressed region), set A `0x38`, and `Font_Svc06` `0xB0`/`0xBC`.

**The three worth a lane first**, because they are the only large ranges where
nobody can say anything at all:

1. **`prom_d 0x044B26-0x046D6A`, 8,772 B — `DrawbarPreset_EnvDescTable_Pool_B000`
   and `_B001`.** Two 4,374-byte pools reached from `_Desc000..003`'s `+0x05`
   field. Their own header says *"part B of descriptor 0 — role NOT
   established"*. This is the largest range in the tree with a genuine
   no-explanation verdict.
2. **`v7 0x1804E2-0x1820C0`, 7,134 B — `AudioCtrl_DataBlock`**, and the rest of
   the `embedded-in-code` column. 222,810 B sitting between decoded routines
   under routine names: this is v7/v9/v10's known code-as-`.byte` debt located
   range by range, and converting it is a *disassembly* job, not a data job.
3. ~~**`prom_b 0x078029-0x0799E8`, 6,591 B**, the 121-object bitmap sheet whose
   index at `PtrTable_F003F9` is understood and whose *contents* are not.~~
   **CLOSED 2026-09-02 by lane RQ-SHEET, and it closed the other way round from
   how it was posed.** The *contents* are understood — the span is part of the
   UI icon sheet at `0xF78028`, **119 cells of 24x24** on the 72-byte grid
   `DLHandler_Glyph24x24` (`0xF31ACE`) computes, now 119 `DLGlyph_*` cells in
   `wsa1/prom_b/wsa1_prom_b.s` with a PNG each. It is the **index** that is not
   understood: `PtrTable_F003F9` is not this sheet's index and not
   `DisplayList_FC4000`'s either. Evidence, both directions, with a control:

   | test | observed | chance |
   |---|---:|---:|
   | the sheet ends exactly on the grid | `0xF7A1A0 - 0xF78028 = 8568 = 119*72`, rem **0** | 1 in 72 |
   | highest op-`0x23` record index, independently | **118** → 119 cells | — |
   | `PtrTable_F003F9` targets in the sheet that are on the grid | **1** of 121 | 1.7 |
   | its targets on a proven `DisplayList_FC4000` record boundary | **3** of 24 | 1.8 |
   | immediates equal to `0xF003F9` in the four images | **0** | — |
   | CONTROL: the live table at `0xF00340`, targets starting `EE 0C` | **25** of 26 | 3.8 % |

   **What goes back on the list, sharper:** `PtrTable_F003F9` is ONE table of
   **216 slots** (`0xF003F9-0xF00758`, 864 B — the tree's old "181 + 35" cut is
   not structural), shaped **18 columns × 12 rows**: column 17 zero in every
   row, columns 13/14 the `0x00FDB10E` filler in every row, columns 15/16 always
   descending, and the target-to-target delta nearly constant *down* a column
   (column 15 = 52 B in six successive rows, then 32 in three). Rows 0-9 point
   into the icon sheet, rows 10-11 into prom_a `0xFC4082-0xFC4454`. So it
   describes a real 12-screen × 18-field structure whose objects are not, in
   this build, where it says they are. Reproduce with
   `python3 wsa1/notes/gen_prom_b_f78028_icon_sheet.py --evidence --layout
   --selftest`; narrative in `wsa1/notes/FINDINGS-image-files.md` §8.

   ⚠ The `text` shape hint the census attached to this range does not survive:
   the only ASCII in the neighbourhood is `DLB_BlankField_8`'s eight spaces at
   `0xF78020-0xF78027`, which were already `.ascii` and are *below* the range.
   Nothing inside `0xF78028-0xF7A19F` is text; it is 8,568 bytes of pixels.

---

## 9. Ranges that look like a known file format — for the conversion lanes

Byte counts over data regions. ⚠ **These categories OVERLAP** (a region can carry
several hints) so they do not sum to anything; `name:` hints come from the label,
the others from the bytes.

| hint | bytes | for |
|---|---:|---|
| `name:bitmap` | 2,222,274 | PNG |
| `bitmap-like` (byte histogram) | 1,143,008 | PNG |
| `name:sequence` (song/preset) | 934,805 | MIDI |
| `ptr-table` (LE32 stride-4, common top byte) | 925,380 | C structs |
| `text` (≥ 75 % printable) | 797,153 | proper `.asciz` |
| `name:midi` | 352,155 | MIDI |
| **`bmp` (verified `BM` magic + DIB)** | **318,468** | already correct — leave alone |
| `name:text` | 247,441 | strings |
| `name:glyph` | 229,360 | PNG font sheets |
| `name:coefficients` | 177,815 | C tables |
| `name:palette` | 132,345 | palette |
| `name:pcm` | 39,316 | WAV |
| `midi` (verified `MThd` in the first 64 B) | 898 | MIDI |

Two of these are **verified from the bytes, not guessed**. The 318,468 B of
`bmp` are the six table_data Windows BMPs (already in their best form — see
`DEBT-INVENTORY`, do **not** "convert" them).

And the `MThd` hit is worth a lane on its own. `prom_b 0x077836`
`Data_F77836`, 415 B, whose own header says *"415 bytes this block could not
split. No content rule framed it … emitted as bytes rather than guessed"*, is a
**Standard MIDI File**. Read straight out of `wsa1/original_ROMs/wsa1_prom_b.ic13`
at file offset 0x77836:

    4D 54 68 64  00 00 00 06  00 00  00 01  00 60      MThd, len 6, format 0,
                                                        1 track, 96 ticks/quarter
    4D 54 72 6B  00 00 00 00                            MTrk, length field = 0
    00 FF 03 0F  57 53 41 20 20 20 20 …                 meta 0x03 track name "WSA    "

**The `MTrk` length field is zero**, which is exactly why no walker ever framed
it: a conformant reader consumes nothing and stops.

⚠ **RESOLVED 2026-09-02, and the guess above was wrong.** It is *not* "415 bytes
of real MIDI events": it is a 33-byte EXPORT TEMPLATE — the file's opening,
which the writer copies into its output buffer before emitting events at run
time — followed by an unrelated 66-byte word table and 316 bytes of code. The
zero length is a placeholder that 0xF7789A backfills from a byte count once the
track is closed. The whole 4,920-byte range is now real source: 4,186 bytes of
code in six spans, 352 of typed data, 382 of `.byte` rows standing in for
instructions llvm-mc cannot encode. Evidence and 87 checks:
`wsa1/notes/FINDINGS-prom_b-smf-writer.md` and
`wsa1/notes/gen_prom_b_smf_writer_module.py --selftest`.

---

## 10. What would move the number

* **+~220 KB**: disassemble the `embedded-in-code` column. It is the largest
  single correction and it is a known, bounded job.
* **+~500 KB (the sampled false-positive mass)**: attach a one-line "what this
  represents" header to the 4.15 MB of regions that currently rest on a label
  alone. Most are genuinely understood; the census cannot tell, and neither can
  a new reader.
* **Split the 133 regions of ≥ 8 KiB.** They carry 47 % of the explained figure
  on 133 labels. A single wrong one is a 30 KB error, and the audit found one.
* **26,807 B carry the UNKNOWN grade**, of which 17,200 B survives as a pure
  `no-explanation` share once ranges that merge with an adjacent self-admitted or
  embedded-in-code neighbour are apportioned. That is the whole of what nobody
  can say anything about at all. It is small — but it is not zero, and the 772 KB
  correction above is the real answer to the question that was asked.
