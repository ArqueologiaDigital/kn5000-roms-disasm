# v10 DATA-AS-CODE census (lane V10DATACODE, 2026-09-02)

★ **CONVERSION STATUS (lane V10DAC, 2026-09-02):** 120 of the STRICT list's spans (3,390 B) have
been converted to typed `.byte` data, with the whole-ROM gate green and every converted span
independently re-verified against the original ROM bytes. See
`notes/v10-data-as-code/lane-v10dac-conversions-2026-09-02.md` for the method, the false positives
it found and excluded (55 spans/1,257 B — real code the reachability signal couldn't trace), and
`notes/v10-data-as-code/v10dac_conversion_manifest.json` for the full per-span list. Re-run the
census (below) for the current remaining total; it drifts as other lanes touch v10 source.

**Question this answers:** how much of v10 is the THIRD kind of debt identified
this week in HD-AE5000 — data disassembled into plausible instruction
mnemonics, invisible to `.byte`/`.incbin` scanners and to the byte-identity
gate (re-assembling a wrong interpretation reproduces the same bytes)?
Nobody had run this census on v10 before this lane.

**Tool:** `scripts/analysis/v10_data_as_code_census.py` (this directory holds
its regenerable cache only; the script is the committed artefact).

```
python3 scripts/analysis/v10_data_as_code_census.py --selftest     # mandatory red/green check
python3 scripts/analysis/v10_data_as_code_census.py --census       # headline numbers
python3 scripts/analysis/v10_data_as_code_census.py --calibrate    # the null / false-positive rates
python3 scripts/analysis/v10_data_as_code_census.py --report --strict --top 40 --minsize 16
```

`--fresh` forces a rebuild of `notes/v10-data-as-code/cache.pkl` (16 MB,
gitignored, regenerated in ~30s from `original_ROMs/kn5000_v10_program.rom`
and the v10 source tree — nothing here is disposable evidence, it is all
one command away from the committed script).

## Method

1. **TERRITORY**: byte-level CODE/DATA/PADDING classification by replaying
   `llvm-mc -show-encoding` over the real v10 source (same method as
   `v9_v10_undisassembled_census.py`'s `territory()`). Only bytes already
   written as instructions are candidates here — data written as `.byte` is
   the sibling script's debt, not this one's.
2. **INSTRUCTION STREAM**: address, length and exact SOURCE mnemonic text
   (not a re-decode) for every CODE byte, from the same llvm-mc pass.
3. **SEEDS**: a byte is a trusted root only if it is offset 0, or a label
   referenced BY NAME in a non-branch context ANYWHERE in `v10/maincpu`
   (`.long`/`.word`/`addr24`/immediate `#NAME` loads in `.s` files, or any
   textual mention in the ~736,000 lines of `.c`/`.h` that compile into the
   UI's widget-descriptor/paramblock/screendata tables). Branch/call operands
   are tracked separately (`branch_named`) and are **never** seeds — this is
   the load-bearing design decision, because HDAE5000_RECORD_TABLE's fake
   decode produced fake `jr`/`call` chains whose operands are OTHER labels
   inside the same bogus span; allowing branches to self-seed would make
   that trick invisible.
4. **REACHABILITY**: BFS/fallthrough closure from the seeds over the real
   source's own branch targets (resolved by name, not by a raw re-decode, so
   MAME/llvm-mc TLCS900 model disagreements can't introduce noise here).
5. **CANDIDATES**: maximal CODE spans with zero reached bytes, scored by
   byte-level statistics on the RAW ROM BYTES (periodicity, distinct-value
   count, ASCII fraction) independent of any disassembler.

## Selftest (mandatory "can this go red" check)

```
$ python3 scripts/analysis/v10_data_as_code_census.py --selftest
SELFTEST PASS: planted self-referential data-as-code span correctly UNREACHED (flagged)
SELFTEST PASS: genuinely address-referenced routine correctly marked REACHED (not flagged)
SELFTEST PASS: periodic 64 B run correctly flagged data-like
SELFTEST PASS: high-entropy 64 B run correctly NOT flagged
SELFTEST ALL PASS
```
The first case is the one that matters: two fake instructions that branch to
each other ONLY, with no external reference, must NOT be able to seed
themselves — exactly the HDAE5000_RECORD_TABLE trap.

## The null — measured, not assumed

`--calibrate` draws its control population from CODE that is reached AND
whose entry label is named by >=2 distinct external call/jump sites
elsewhere in the tree (the strongest available evidence of genuine,
executing code): 165 runs, 234,131 B.

```
reachability PROPAGATION check (bugs, not seed coverage): 0/8206 = 0.00%
reachability SEED-COVERAGE gap: 4,175/24,149 (17.3%) named call targets never end up REACHED
decode-quality false-positive rate, LOOSE rule: 57/300 = 19.0%
decode-quality false-positive rate, STRICT rule (dist<=15, per>=60%): 1/300 = 0.3% (a second run: 7/300 = 2.3%)
```

Two separate, important nulls fall out of this:

* **The BFS mechanics are sound** (0.00% propagation gap within runs already
  proven reached) but **seed coverage is not complete**: 17.3% of labels
  that are provably called by name from somewhere in the tree still never
  get marked reached, because the CALLING code's own chain dead-ends before
  reaching a seed. Concrete, spot-checked example: the `SeqPart_*` cluster
  (sequencer "part editor" — splice/exchange/dual-load/navigate), 467
  labels, only 33 provably reached. The other 434 form a coherent,
  plausibly-named, byte-diverse (not periodic, not low-entropy) call graph
  that is almost certainly real code, most likely entered through a
  RAM-resident or register-indirect dispatch this static, name-based scan
  cannot see. **Consequence: the raw "unreached CODE" figure (375,743 B,
  37.4% of CODE territory) is NOT a debt figure — it is dominated by real
  code the instrument cannot prove reached, and must never be quoted as
  found debt.**
* **The byte-statistics leg needs a tight threshold to be useful.** The
  LOOSE rule (reused verbatim from the sibling census, tuned for the
  opposite question) has a 19% false-positive rate on verified real code —
  confirmed concretely: `DataBuf_CopyBulkBitfields_Large`/`_Stub` in
  `midi_dispatch_handlers.s` are real, human-written bitfield-copy routines
  whose unrolled per-field `ldcfm`/`stcfm`/`andmi8`/`or` template creates
  artificial periodicity; both were manually confirmed as false positives
  and are NOT claimed as debt. A tighter rule (`dist<=15` distinct byte
  values AND `per>=60%` periodicity — no real TLCS900 instruction stream
  sustains that combination over dozens of bytes) drops the false-positive
  rate to 0.3-2.3%, an order of magnitude tighter, and is the only tier this
  report names individual candidates from.

## v10's data-as-code debt, ranked by confidence

**Upper bound (do not quote as debt):** 375,743 B of CODE-territory bytes are
unreached by the reachability signal alone (37.4% of v10's 1,003,642 B of
CODE territory). As shown above this is dominated by real code (the
`SeqPart_*`-style false positives), not by the defect being hunted.

**Candidate pool (needs individual confirmation, ~19% noise):** intersecting
"unreached" with the LOOSE byte-stats rule narrows this to 127,208 B across
4,738 spans. Still not safe to quote as a single number — manual review of
the top-10-by-size hits at least two confirmed false positives
(`DataBuf_CopyBulkBitfields_Large`/`_Stub`, 2,972 B combined, real code).

**High-confidence finding (STRICT rule, ~0.3-2.3% noise): 7,128 B across 264
spans**, `python3 scripts/analysis/v10_data_as_code_census.py --report
--strict --minsize 16`. This tier is corroborated by more than the byte
statistics: a large share of the hits sit inside labels a PRIOR
naming/conversion pass already called `_Table`, `_TableAndData`,
`_BaseOffsets`, `_JumpTable`, `_Str_Off`, or `_ByteData` — i.e. someone
already recognized the region's *purpose* as data without ever converting it
away from instruction mnemonics. Top named evidence:

* **`PanelEvt_Handler_4_DualValueCheck_0x77`+77 and +449** (0xFD17AB and
  0xFD191F, 371 B + 259 B = 630 B in the STRICT report; a wider direct byte
  scan shows the true extent is at least 712 B across seven runs from
  0xFD175F to 0xFD1A5F, with the pattern immediately followed by a run of
  literal `0xFF` erased-flash bytes). Raw bytes are a 4-byte-periodic
  `05 FD 00 XX` run repeated ~90+ times. Disassembled, that is `halt` (0x05)
  / `swi 5` (0xFD) / `nop` (0x00) / one varying byte, over and over — a
  90-repetition `halt` chain inside a UI panel-event handler is exactly
  signal #3 from the brief ("halt in the middle of a data region"); no real
  handler executes `halt` ninety times. Almost certainly a padding/unused
  run at the tail of `PanelEvt_Handler_4_DualValueCheck`, mechanically
  disassembled because the assembler accepts any byte as *some* instruction.
* **`Voice_NoteChannelTable1_0x2` / `Voice_NoteChannelTable2_0x2`** — six
  STRICT hits (32-56 B each) inside labels already named "Table" by a prior
  pass; `dist` as low as 3-10 distinct byte values.
* **`AccVoice_IndexedTableLookup_BaseOffsets_0x2`** — three STRICT hits
  (49-51 B, `dist` 2-3, `per` 98-100%) — a name that says "base offsets"
  landing on near-constant, highly periodic bytes.
* **`TuningSystem_Handler_Table_0x117D` / `_0x23BD`**, `DrumParam_
  PointerTableAndData_0x2`, `AccStyle_JumpTable2`, `CtrlAssignStr_Off`,
  `FadeTimeStr_Off` — same pattern: a name that already says table/pointer/
  string-offset, content that is 2-15 distinct bytes at 60-100% periodicity.

Full ranked list: `--report --strict --top 264 --minsize 16` (264 rows,
7,128 B). Every row needs the same kind of hand confirmation done above
before being folded into a permanent debt total — this script is a finder,
not a verdict, exactly like the sibling census's own `judge()`.

## What could not be decided either way

* **`NAKA_InitDataBlock`+1** (0xF167AF, `flash_floppy_handlers.s:1318`,
  18 repeats of a 17-byte `cp`/`jr`/`lda_24`/`ret`/`lds32`/`ret` template,
  ~306 B). `v10/maincpu/audio/tonegen_param_table.c` (a compiled, `.incbin`'d
  C struct) hardcodes an 18-entry `uint32_t naka_init_ptrs[]` array whose own
  header comment reads *"NAKA init data block pointers (18 x uint32_t) --
  Evenly spaced at 0x11 (17) byte intervals starting at NAKA_InitDataBlock
  (0xF167AE) + 1"*, with the 18 literal addresses matching exactly. That is
  independent, strong structural evidence of an 18 x 17-byte record table —
  but it is genuinely ambiguous whether each 17-byte "record" is inert data
  or a legitimately tiny init-check routine invoked through a
  **register-indirect call sourced from this exact pointer array**, which is
  a class of reference no static, name-based scan can ever resolve (the
  addresses are raw hex literals in a data table, not symbol references).
  Settling this needs either a MAME execution trace or a by-hand read of
  whatever code loads `naka_init_ptrs`, both out of scope for a census tool.
* **`VGA_CRTCTiming_ByteData`+32** (0xFB3264, `graphics_text_vga.s:3044`) —
  named "ByteData" by a prior pass, but its neighbourhood also contains
  stray `.byte` escapes interleaved with instructions (`.byte 0xd7`, `swi 2`,
  `.byte 0x04`, ...) and `calr`/`jr` operands written as bare numeric
  literals rather than labels, both signatures of the SEPARATE
  "misframed islands" debt category already tracked in
  `DEBT-INVENTORY-2026-09-02.md` (~14,727 B/image, deliberately not
  attempted by the v9/v10 lane because fixing one re-frames an instruction
  already present). Not claimed here to avoid double-counting across lanes;
  flagged for whichever lane owns that category.
* **The 66% of "unreached" CODE that IS code-shaped** (248,535 B) — per the
  seed-coverage null above, this is most likely real code reached through a
  mechanism invisible to static source-text scanning (computed jump tables,
  RAM-resident dispatch built at init time). It would take dynamic tracing
  (a MAME coverage run) to separate any remaining real data-as-code
  instances from this bucket, which is out of scope here.


## Querying the manifest (do not re-parse a text dump)

`v10dac_conversion_manifest.json` is the structured record of every span this
lane touched or declined. It has two keys, `converted` and `excluded`, and each
entry carries `addr_lo`, `addr_hi`, `size`, `loc` (enclosing label + offset),
the census stats `per`/`dist`/`ascii`, and a `reason`.

The 146 excluded spans split by reason, and both subsets are one line away:

    import json
    ex = json.load(open('notes/v10-data-as-code/v10dac_conversion_manifest.json'))['excluded']
    no_unique = [e for e in ex if 'no unique context' in e['reason']]   # 91 spans, 2,536 B
    real_code = [e for e in ex if e not in no_unique]                   # 55 spans, 1,257 B

⚠ The 91 are spans whose instruction-text sequence was not uniquely locatable in
the source tree — a MATCHING problem, not evidence about the bytes. The 55 are
different in kind: they were corroborated as REAL CODE that the census's static
reachability could not trace, and must not be converted.
