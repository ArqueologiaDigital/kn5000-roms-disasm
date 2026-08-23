# Is the KN5000 disassembly done?

**No.** This is the measured answer to that question, scored against
`DISASSEMBLY-COMPLETENESS-SPEC.md`, with the command that re-derives each row. Written 2026-08-21
after a day spent testing the claim rather than repeating it.

Read this before believing any single number elsewhere in the repository: several figures that
stood for months were wrong, and are corrected in the history rather than quietly replaced.

## What would unblock each remaining item (2026-08-23)

Written because "not done" is not actionable on its own. Every open item is in exactly one of
three classes, and only the first is work anyone can do by reading these ROMs harder.

**A. STILL ANALYSABLE from the dumped ROMs — real work, available now**

| item | size | what it needs |
|---|---|---|
| 305 blocking labels — **PARTLY RESOLVED 2026-08-23** | 1,357 B left (was 4,747) | The bucket was measured to be ONE guard (55/55): a labelled `.byte` block starting strictly inside the range off any instruction boundary. **Cutting the range to end at or before that label** converts nothing at or past it, so no label moves and no `.long <symbol>` changes — the exact property the 981-repair retraction turned on. Shipped: **+1,609 B**, gated by `assert_byte_identical.py`, `no_label_was_dropped.py` (0 lost / 0 added) and the plausibility screen. ⚠ **Residual risk that no gate here can see:** 56% of blocked ranges carry MORE than one off-boundary label, some 7–11, which reads as a mis-framed decode rather than misplaced labels — and then the kept prefix is suspect too. `CUT_SINGLE_LABEL_ONLY` restricts to the single-label subset. `tools/spelling-probes/label_guard_split.py`, `cut_range_label_multiplicity.py` |
| entry in neither a `.byte` run nor a located `.incbin` | 26 ranges | extend the placement logic; the `.incbin` case was solved this way once already |
| truncated at unspelled forms | 869 B | per-form spelling probes; the method is established (`tools/spelling-probes/`), the yield per form is now small |
| **NAKA record format — LARGELY DETERMINED 2026-08-23** | ~903 KB / 248 spans | Was: names but no format. Now: header `XX 00 60 01` (2,857 found vs **13** in shuffled spans), **length pinned for 10 types**, **field layout for 12**, records shown to be **u16 fields**, and **6 pointer fields** located at named offsets resolving 92–100% against a 1.79% null. Controls discriminate at 0 CONST vs 10–29. **FIELD MEANINGS DONE for the dispatch path:** the record is a **state-query descriptor**; `+0x0C` is the query mode (0..6, bound enforced by `cps a,7`) and all seven handlers at `0x00EE10D0` are documented — masked/shifted byte extract, a 14-bit assembly clamped at `0x3FFF`, a u16 membership test against 6-entry lists, a bit-2 guard, and a 9-bit field. Seven fields carry meanings (`+0x04` block selector, `+0x05` offset, `+0x06` AND mask, `+0x09` shift low-nibble, `+0x0A` XOR, `+0x0B` secondary selector, `+0x0C` mode) plus the three tables they index. **Census repaired 2026-08-23:** the `XX 00 60 01` signature was too narrow — valid headers also carry third bytes `0x61/0x63/0x64/0x65/0x67/0x68`, derived from the 168 headers confirmed BY POSITION (26× above a 0.85% control). ⚠ Broadening the scan by VALUE is measurably worse (+481 headers, at/below a 601-hit noise control, consistency 53%→41%); **positional recovery** at the modal boundary adds **+127 headers (2,857→2,971) and improves consistency to 58%, with off-boundary controls recovering ZERO in both directions**. Still a lower bound. REMAINING: what the state blocks at `0x00EE1160` are; how a record's TYPE relates to its MODE; and 12 types whose length is carried inside the record. `l3_naka_record_format.py`, `l3_naka_field_layout.py`, `notes/FINDINGS-naka-record-format.md` |
| **L2 aptness — a SECOND decidable class shipped 2026-08-23** | 222 claims tested | Names asserting a SUBJECT are undecidable (`ToneGen_ParamTable` is a jump table). Names asserting a **STRUCTURE** are decidable: `*PtrTable*` claims pointers, `*Strings*` claims text, `*Bitmap*`/`*Glyphs*` claims not-a-pointer-table. **222 testable, 45 contradicted, control 4.6%.** Hand-checked: `SOUND_DATA_STRINGS_VOCAL` is `00 01 02 … 07` then zeros; `DiskWarning_ConfirmStrings_0xC36` is u32 counters descending 7→4. ⚠ **34 of 45 are `_0xNNN` sub-labels inheriting a parent's structural word — only 7 are standalone naming decisions.** `l2_name_vs_structure.py` |
| L2 name aptness, decidable classes | — | more classes like `l2_name_vs_return_value.py`: names that DECLARE something checkable |

**B. BLOCKED ON A PHYSICAL INSTRUMENT — cannot be closed by analysis**

* what the control panel puts on the wire (needs a logic analyser on a real KN5000)
* the four L5 items named in `kn5000-control-panel-panel-side.md`
* whether the `0x30`/`0xC0` `.LSW` gaps carry anything — PROVEN unreadable by this firmware
  (the importer never seeks), so only a capture on the machine that WROTE the disks can say

**C. BLOCKED ON A MISSING ARTEFACT — needs a disk or dump nobody here has**

* what `"M4"`/`"M6"`/`"NN"` are as products: no string in any of the seven images ties them to a model
* ⚠ **UPDATED 2026-08-23 — `0x9A` now has a measured SHAPE, though still no identity.** The `.LSW`
  record container is `<tag u8><len u8><payload>`, verified on the factory default image: 74 of 77
  header tags match their table index and the 3 exceptions are aliases whose headers carry one of
  their own aliases, so the rule holds 100%. Tag `0x9A` declares **`len = 26`**, distinct from the
  23 per-part records at `len = 24`, and that agrees with the independently-derived 4..19 /
  0..3+20..25 split. Its factory default is **26 zero bytes** in a populated neighbourhood. Also
  settled: **tags `0x00`–`0x16` ARE the NAKA widget state blocks**, so widget queries read `.LSW`
  records by tag. What is still missing is what `0x9A` MEANS, not its size or its container.
* `.LSW` tag `0x9A`: searched over the WHOLE parameter-id space (not a narrow window) and no
  descriptor exists in any revision. Absence is established, meaning is not.
* NOTE2's extra bytes in the factory styles: authored on other equipment before the disks were written

⚠ **L2 aptness in general is in NONE of these classes and never will be.** A name that asserts
nothing checkable — `FileIO_ReadHeader`, which builds a path and reads no header — cannot be
falsified by any script, only by a human reading the routine. The decidable classes are worth
extending; the general problem is not a measurement gap, it is a category error to treat as one.

## The scorecard

| level | status | evidence |
|---|---|---|
| **L0** byte-exact AND capable of failing | **PASS** | `rom_provenance_poison.py all` -- v7, v9, v10 report 0 copied bytes. v7 was 979,096 B (46.69%) copied this morning. |
| **§3** binary includes justified | **PARTIAL** (check can fail; weak on large blobs) | `audit_incbin_legitimacy.py` no longer stops at the path-prefix categories. It runs the structure triage and exits non-zero on any blob still holding pointer-table structure, enforcing PTR_TABLE only -- the one class that survives the byte-shuffle control. **Proven able to fail:** against the pre-conversion tree (`056a9a1^`, in a worktree) it exits 1 and names `UIState_HandlerTable_*`, `Naka_*_Table` and the rest, while the old category test passes on that same tree. 8,084 B were converted to `.long <symbol>`; three blobs are exempted BY NAME, each with the reason it scores as a table without being one. **⚠ DOWNGRADED 2026-08-23 -- it can fail, but it is nearly powerless on large blobs.** The triage classifies each blob AS A WHOLE, so structure that is a small fraction of a big file cannot move the file's statistics. `naka_widget_descriptors.bin` (150,888 B) passes as OPAQUE while the comment above its own `.incbin` documents `DspEffectName_PtrTable` inside it -- 128 x u32, **128/128 landing in the ROM address range**. A windowed re-scan (`l3_embedded_structure_scan.py`) finds **45 embedded pointer-table regions / 25,344 B across 391 OPAQUE blobs**, each surviving a per-region shuffle control, and that is a LOWER bound: aligned windows miss the naka table itself. So this row is PASS on the check as written and NOT a statement that the blobs are clean. See spec anti-pattern 22. **⚠ AND IT UNDER-CREDITS IN THE OTHER DIRECTION (2026-08-23):** the audit reads bytes and nothing else, so it does not see that the sources declare **3,709 named offsets** into 24 of these blob bases (`.equ IconBitmapNamePtrTable, NakaData_WidgetNames + 0x4C28` and 673 more for that blob alone). An `.equ` naming an interior offset IS a human-readable structure description, so "OPAQUE / earns no better format" understates how well these blobs are understood. **Shipped so far: 12,288 B of embedded pointer tables converted to `.long <symbol>`** (`convert_embedded_ptr_regions.py`, two qualification paths, `--controls` regenerates both nulls). **Deliberately NOT converted: 30 regions / 13,056 B** — they hold addresses at 13–29× the null but are not established as flat tables, and the `.equ` names show at least one is heterogeneous. `notes/FINDINGS-embedded-structure-in-blobs.md` |
| **L4** assets round-trip | **PASS** | seven converters in `scripts/build/`, each `verify` asserting ROUND TRIP EXACT. |
| **L1** every byte classified | **PASS** | `l1_territory_map.py v7 v9 v10` -- flattens each source tree through llvm-mc and assigns every byte to CODE/DATA/PADDING; all three totals equal their rebuilt ROM to the byte. ASSET is folded into DATA here (llvm-mc expands `.incbin`); its separate justification is the §3 row. |
| **L2** semantic names | **PARTIAL** — revision defect FIXED; the "displaced labels" finding is RETRACTED | The v10-only reference is repaired: `l2_symbol_reference.py` now emits `maincpu_v7`/`maincpu_v9`/`maincpu_v10` references, each checked against ITS OWN ELF at 100.0%, and the un-suffixed file carries a header saying it is v10 and must not be used for v7/v9 addresses or renames. Verified against the ROM, not just the ELF: `free_X`, `Boot_ReadFDCStatus`, `EmptyRoutine_03` and `Voice_InitBankTables_SlotLoop` all have blobs matching the ROM at the v7 file's addresses and at NONE of the shared file's — and those addresses equal the ones independently found this morning by searching the ROM for the bytes. STILL OPEN: name aptness for names that declare nothing checkable, and the 153 v7 names known to sit on the wrong routine. |
session was misleading. Broken down by `l2_positional_breakdown.py`:

| | count | assessment |
|---|---|---|
| sub-labels of a semantically named parent | 3,285 | correct as they are -- `Display_BytecodeBlock_F_0x32D` names an offset inside a named function |
| padding markers (`__pad*`) | 145 | correctly labelled |
| a real name plus an address disambiguator | 197 | e.g. `NakaInst_ON_E12345` |
| **no meaning in the stem** | **0** | -- |

Nothing is unnamed. So what remains for L2 is **aptness, not coverage**: is a name RIGHT? No script
can answer that.

**RETRACTED: aptness IS mechanically checkable for one class, and it found four real defects.**
I claimed no script could judge whether a name is right. That was too strong. 512 v10 labels state
their return value as a NUMBER (`*_ReturnZero`, `*_ReturnOne`, `*_ReturnFFFF` ...), and the return
register is XHL -- established, not assumed, by 450 of them opening `lds32 xhl, <imm>` into a shared
`ret` epilogue with callers branching on it. Abstract-interpreting XHL from label to `ret`, and
declining to judge on any conditional branch or call, measures 488 of the 512 and finds **four
CONTRADICTED** (`l2_name_vs_return_value.py`, which exits non-zero while one stands):

| symbol | address | name says | code returns |
|---|---|---|---|
| `MainGetEvent_ReturnZero` | 00FA9C6A | 0x0 | **0x1** |
| `MainGetEvent_ReturnZeroAlt` | 00FA9C6F | 0x0 | **0x1** |
| `NakaWidget_ReturnZero` | 00FA4AFD | 0x0 | **0x1600006** |
| `PostEvent_ReturnZero` | 00FA9856 | 0x0 | **0x1** |

Verified by hand at 0xFA9C6A: the routine falls through `lds wa, 7` / `call TaskSched_SignalEvent`
/ **`lds hl, 1`** into its `ret`. It returns 1. The check calibrates against cases where the name is
right -- 27/27 on `ReturnOne`, 3/3 on `ReturnFFFF` -- so it can fail rather than merely agree.

So L2's remaining gap is smaller AND better defined than "unverifiable": one class is now measured
and has four defects to fix. Other classes may be measurable too; nobody has looked.

The earlier candidate did NOT survive inspection. `LoadFileVariant` opens `"wb"`,
which the mode audit flagged as a name/behaviour contradiction -- but it then calls
`SMF_LoadSoundBankAndPlay`, which genuinely loads a bank and plays it, so the name is apt and the
write-mode open is an unexplained oddity recorded in a comment at the call site. **Zero confirmed
misnomers**, which is not the same as none: an unknown number of plausible-but-wrong names remain
and no mechanical check can find them; 88.9/84.9/99.9/97.7% on subcpu/boot/table_data/hdae5000. |
| **L3** field meanings | **PARTIAL** (container firmware-proven; types/ranges from ROM; five field groups attributed to the routines that write them) | every event status in both event formats decoded. Open: NOTE2's extra bytes AS THEY APPEAR IN THE CORPUS, and the `.LSW` 24-slot payload. |
| **L5** protocols reimplementable | **PARTIAL** | SLIDE4K/8K, the style container, the sequencer/SMF subsystem and the control-panel link are specified, three with executable tests. ~~Panel-side behaviour is not, and cannot be.~~ **RETRACTED** -- most of it IS derivable, see `docs/kn5000-control-panel-panel-side.md`; four things genuinely need hardware. |
| **L6** evidence re-derivable | **PASS** | every quoted number has a committed producer; ten claims were retracted this session rather than left standing. |

## v7 territory, as of 2026-08-22

    CODE      607,450  28.97%      (was 542,379 / 25.86% at the start of the day)
    DATA    1,431,785  68.27%
    PADDING    66,752   3.18%
    TOTAL   2,097,152  = the ROM, to the byte

56,236 bytes became instructions today, every batch gated at 9/9 byte-exact. 23,232 of those came
from ONE line: the range converter's whole-block re-check tested "no local labels" where it meant
"no branches", so every range branching to an external symbol was compared against a link-time
placeholder and refused. Round 1 after the fix gained 18,446 B against 18,412 B predicted by a
census written before the fix existed -- which is the kind of agreement that makes a fix credible.
Call targets still awaiting conversion: 1,118 -> 786, and the closure has now reached a true
fixpoint (a round gaining 0 bytes), so what remains is NOT waiting on more rounds.

⚠ **THE TWO LARGEST BLOCKERS ARE ONE DEFECT (2026-08-23).** The label guard and the -0x41A
displacement looked independent and are not: of the labels sitting inside a range but not on a
decoded instruction boundary, **304 are in the displaced set and 41 are not -- 88%**. So in almost
all cases the decode is RIGHT and the label is 0x41A too high, which is why it lands
mid-instruction. The guard was refusing correctly; it just could not say which side was wrong.
Two consequences: repairing the displacement should clear most of that bucket, and the 41
non-displaced cases are a separate smaller problem sitting OUTSIDE the displaced region
(`WidgetParam_Config_004` at 0x00EE646E and friends) that must not be swept into the same fix.
Prover: `scripts/analysis/v7_guard_vs_displacement.py`.

⚠ WHAT REMAINS, MEASURED (2026-08-22 end of day). "Fixpoint reached" is not "finished":

    ~2,1xx B 30 ranges  a label inside the range is NOT on a decoded instruction boundary.
                        ⚠ TWO EXPLANATIONS HAVE NOW BEEN OFFERED AND BOTH WITHDRAWN: first
                        "needs a converter that preserves labels" (wrong -- it is a framing
                        disagreement, not a mechanism gap), then "88% are displaced by 0x41A"
                        (wrong -- the ROM's pointer tables contradict the detector, 11 of 11;
                        see the retraction banner above). The current evidence, from
                        `v7_label_guard_subjects.py`: of 313 distinct blocking labels, 8 are
                        referenced by values in the ROM and are `WidgetParam_Config_*` RECORDS
                        that pointer tables index -- for those the converter is decoding DATA as
                        code and the guard is refusing CORRECTLY. The other 305 are unsettled,
                        and being unreferenced does not make them dead
                        (`v7_unreferenced_labels_are_live.py`). A second signal points the same
                        way: the off-boundary labels CLUSTER -- 201 of 313 sit in a range where
                        3+ labels are off-boundary, one range has 11. Eleven independently
                        misplaced labels in one routine is not credible; a MIS-FRAMED DECODE
                        that disagrees with all of them is. ⚠ Do NOT read this bucket as "ranges
                        waiting to be unlocked" -- on this evidence most of it is the guard
                        working, and the honest recoverable residue is much smaller than the raw
                        byte count I quoted all session.
                        ⚠ I first wrote that this "needs a converter that preserves a label
                        across a rewrite". That is wrong, and the guard's own comment says why:
                        a label off an instruction boundary means THE DECODE AND THE EXISTING
                        FRAMING DISAGREE, and one of them is incorrect. Preserving the label
                        would paper over the disagreement rather than settle it. Either the
                        range is mis-framed (do not convert) or the label is spurious (the
                        decode is right). Neither the byte gate nor a label check can tell them
                        apart -- both readings reproduce the ROM, and deleting a label changes
                        no bytes. `v7_label_vs_decode_conflicts.py` separates the cases: only
                        17 labels tree-wide fit the "auto-generated suffix on a live base name"
                        shape (`SeMenu_ReadObjParam_Data`, whose base has 26 v7 references), so
                        spurious labels do NOT explain all 29. Deletion stays off the table
                        until the surrounding bytes convert and "referenced by nothing" stops
                        being a statement about progress (`v7_unreferenced_labels_are_live.py`).
    1,722 B  20 ranges  entry in neither an indexed `.byte` run nor a located `.incbin`
    1,057 B             truncated at instructions with no verified spelling
      115 B   1 range   runs past its slice
       48 B             inside a `generated/` blob -- compiler output; splitting it would fork
                        the data from its committed C source
       16 B   1 range   overlaps another

⚠ AND A LIMIT ON THE GATE ITSELF, found the same day: byte-identity cannot distinguish code from
DATA THAT HAPPENS TO DECODE. Five tables re-assembled byte-exactly as plausible instructions and
were only kept out by a plausibility screen. See spec anti-pattern 13. Every conversion figure in
this document is byte-verified; that is necessary and it is not sufficient.

## What the territory map shows

L1 was mechanised on 2026-08-21, and the first thing it measured was a gap nobody had quantified:

| | CODE | DATA | PADDING |
|---|---|---|---|
| **v7** | **542,379 (25.86%)** | 1,488,021 (70.95%) | 66,752 (3.18%) |
| v9 | 1,003,061 (47.83%) | 1,019,367 (48.61%) | 74,724 (3.56%) |
| v10 | 1,003,078 (47.83%) | 1,019,364 (48.61%) | 74,710 (3.56%) |

**v7 has ~460 KB less CODE and ~469 KB more DATA than its siblings**, which are nearly identical to
each other. The 288 committed ROM slices account for 136,775 B of that, so roughly 320 KB is not yet
explained -- regions that v9/v10 express as instructions and v7 still carries as data. Whether that
is genuine content difference or simply less-advanced disassembly is NOT established here; the
measurement is, and it says where to look.

That is what a mechanised L1 is for. The previous "no UNKNOWN bytes remain" was true and told nobody
where the work was thin.

**Where the thin part is, located.** `v7_undisassembled_spans.py` builds a per-byte territory map for
v7 and for v9 and reports every span of >= 256 B that v7 carries as DATA while v9 carries the same
offsets as CODE: **258 spans, 158,902 bytes**. Same offset is not the same function across
revisions, so that is a candidate list -- but four spans were checked by hand and all four are
plainly real TLCS-900 code:

| span | size | what it is |
|---|---|---|
| 0xFD3095 | 5,030 B | an unrolled bit-extraction loop, `ldcf 7,(XHL)` / `scc C,A` / `sla 0x07,A` / mask / `or`, repeating per bit |
| 0xF2D29A | 4,520 B | function prologue `lda XSP,XSP+0xf2` then a struct set-up |
| 0xF1960C | 3,317 B | the same prologue shape, a near-twin |
| 0xFDE939 | 2,816 B | a table lookup, `lda XIX,0xee8ea2` / `ld A,(XIX+WA)` |

So a substantial part of v7's DATA is undisassembled CODE, and this is a ranked worklist for it.
`--disasm N` prints the head of the N largest spans so a reviewer can judge rather than trust.

**And the reason it is still data is not neglect.** The tree must assemble byte-exactly with
llvm-mc, so a byte sequence can only be written as an instruction if the TLCS-900 LLVM backend
accepts that instruction. Several forms it does not:

| form | llvm-mc |
|---|---|
| `and (xix), 0x7f` | error: invalid operand |
| `bit 7, (xix)` — and `bit (xix), 7` | error, both orders |
| `ldcf 7, (xhl)` | error: invalid operand |
| `scc c, a` | error: invalid operand |
| `res 5, (xhl)` | error: invalid operand |
| `or (xix), a` | fine, `[0x84,0xe9]` |
| `sla a, 7` | fine — **not** a gap; unidasm just prints it as `sla 0x07,A` |

Those first forms make up the whole unrolled bit-extraction loop at 0xFD3095, so that block **cannot
be expressed as instructions today** however obviously it is code.

`llvm_missing_instruction_forms.py <file.s>` measures the blocker per file by decoding with unidasm
(complete where llvm-mc is not) and re-assembling each instruction. On
`v7/maincpu/midi/midi_dispatch_handlers.s` alone: **365 blocks, 28,105 bytes blocked**, led by
`and (mem), imm` (84), `bit imm, (mem)` (49) and `ldcf imm, (mem)` (43).

It tries both operand orders before calling a form missing, because unidasm and llvm-mc disagree on
order for shifts -- without that, every shift in the ROM reads as a backend gap. Entries beyond the
hand-confirmed ones above are LEADS: `lda xbc, imm` still reports rejected and is not yet explained.

**FIXED 2026-08-21, and the diagnosis above was wrong in its cause.** The backend never lacked these
instructions -- it lacked their NAMES. `AND8mi`, `BITm`, `RESm`, `SETm`, `LDCFm` and `STCFm` all
encoded correctly, but were reachable only as `andmi8`, `bitm`, `resm`, `setm`, `ldcfm`, `stcfm`, so
a source could not write `and (xix), 0x7f` even though the encoder produced `84 3C 7F` for it --
exactly the ROM bytes at 0xFD30A2. `CP8mi` in the same file already used the real `"cp"`.

`tlcs900_backend@970c4a75312e` renames each to its real mnemonic and keeps the old spelling as an
`InstAlias`, since this tree uses them in hundreds of files (`bitm` in 53, `incm` in 80) and a bare
rename would break every one. Both spellings emit identical encodings, and a full
`make clean-all && make all` on the new toolchain gives **9/9 at 100.00%**.

So the 158,902 bytes were never "work nobody did" nor "work the toolchain cannot accept" -- they
were work the toolchain could not be ASKED for. The unrolled bit-extraction loop at 0xFD3095 now
round-trips **26 of 26 instructions byte-exactly, against 0 of 26 this morning**.

**What that unlocked, measured rather than assumed.** On `midi_dispatch_handlers.s`, invalid
encodings went 487 -> 0. Of its 623 `.byte` blocks: 124 have no v9 corroboration, 203 contain `db`
(unidasm declines to decode them, so they are data), 283 still fail the round-trip, and **13 are
convertible**. That is a smaller number than the headline suggests, and the reason is worth stating:

| still blocking | why |
|---|---|
| ~~`QIZH`, `QIZL`, `QIXH` ... (46 uses)~~ | ~~a genuine missing-register gap~~ **RETRACTED.** They are expressible today. llvm-mc has no register OPERAND for them, but it encodes them through the `_erpb` forms with the register byte as an immediate: `cp_erpb 0xfb, 0x10` gives `[0xc7,0xfb,0xcf,0x10]`, which unidasm reads back as `cp QIZH,0x10`. The converter now translates them, using the register-byte table from MAME's `dasm900.cpp`. `ld`/`inc` still lack a located `_erpb` sub-opcode. |
| `incw 1,(XSP+0x04)` | unrecognized mnemonic in this form |
| `ld E,(XWA+)` | post-increment addressing |

⚠ That retraction is the **third** time this session I concluded the backend could not do something
it could do, and each time the real answer was a spelling I did not know: first "the backend lacks
these instruction forms" (it lacked their mnemonics), then four syntax differences counted as gaps,
now the Q registers. The lesson is the same one that runs through this whole document -- **before
reporting that a tool cannot do something, try to make it do it.** Assembling one line would have
refuted each claim in seconds.

Four other apparent gaps turned out to be **unidasm-vs-llvm-mc syntax**, and the converter now
translates them: `lda` wants its source parenthesised (`lda XWA,(0xf980)`), shifts take the register
first (which is what this tree's own sources already write, `sla xhl, 8`), `T` is the always-true
condition that llvm-mc omits, and unidasm prints doubled condition codes as `PE/OV`.

**Reachability is the approach that scales, and v9-content corroboration is not.**
`v7_reachable_from_code.py` walks the 3,678 contiguous CODE runs, reads the call targets out of the
disassembly, and reports those landing in DATA: **808 targets, 69 of them (9%) opening with a
stack-frame prologue**. Two properties make this the right criterion where content matching was not:

* **it is evidence about this ROM** -- something already disassembled calls the address -- rather
  than a resemblance to a different firmware revision;
* **a call target is an instruction boundary by construction**, which matters because a label is
  not, and a block decoded from the wrong offset produces garbage that still round-trips
  byte-exactly. The build gate cannot catch that; this criterion cannot make the mistake.

⚠ **AMENDED 2026-08-23 -- it was run ONCE, and it is a fixpoint.** The scan reads call targets out
of the CODE territory *as the sources currently stand*. But every range the converter then accepts
and byte-matches becomes CODE, and the branches inside it name further addresses that are code by
the identical argument. Nothing fed that back. Iterating to convergence takes the entry set from
687 to **1,209 in ten rounds (+522, a 76% expansion)** -- `scripts/analysis/v7_branch_closure.py`.
The paragraph above is right about *why* reachability is the correct criterion and wrong to imply
the scan's output is the answer; it is the first approximation of one.

The iteration is only sound because destinations are harvested exclusively from ranges passing every
structural gate: a mis-framed decode's "branches" can be data bytes that read as `jr`, and a wrong
entry point produces no byte difference for the gate to catch. 254 destinations seen only in refused
ranges are withheld and counted separately. This is anti-pattern 20 in the spec.

By contrast, v9-content corroboration converted 536 bytes in total and will not go much further: it
requires a block's exact bytes to appear in another revision at a code location, and most v7 code
simply differs.

**Where the v7 lane actually stands (2026-08-22).** ~20,864 bytes converted, every one byte-matched
and every batch gated 9/9. `convert_to_fixpoint.sh` runs regenerate-targets -> convert -> gate until
nothing more is gained. It now stops immediately, and the reason matters:

| blocker | ranges | note |
|---|---|---|
| range starts mid-block, **lead path disabled** | **52** | ~5,571 bytes; the binding constraint |
| range extends past its blocks | 7 | |
| replaced span holds a non-`.byte` line | 1 | |
| unspellable instruction (truncates the range) | -- | **6,754 bytes** lost, the measured ceiling for more spelling work |

The lead path -- re-emitting the bytes of a partly-covered first block around the instructions --
was tried THREE times and produced silent corruption every time (103, then 183 wrong bytes): content displaced a few bytes with the
totals intact, so the length invariant saw nothing and the gate reported 103 wrong bytes only after
a full rebuild. It stays off. **It is the single biggest lever on this lane**, worth more than every remaining
spelling combined, and `scripts/analysis/lead_path_repro.py` is the harness for whoever takes it:
it rebuilds `lead + instructions + tail` in memory and compares against the block's real bytes, so
a round trip that costs minutes as a build costs seconds. It has already found one real defect --
the touched blocks are assumed to TILE the address range and 2 of 114 multi-block cases do not,
because bytes inside the span belong to a block whose label has no ELF address. Fixing that alone
still leaves 183 wrong bytes, so at least one more defect is in there. Single-block cases
reconstruct exactly; the fault is in the multi-block case.

**Nothing further has been converted yet, deliberately.** Proving 13 blocks round-trip is not the same as
emitting them well: the decoded text carries raw numeric branch targets (`call 0xfd814f`), and
writing that beside lines reading `call FileIO_BuildFilePath` is the regression that got the older
converter marked unsafe. The missing piece is symbolisation from the ELF.

## ⚠ L2's reference file describes ONE revision and is consulted for THREE (2026-08-22)

`PAIRS` in `l2_symbol_reference.py` reads `"maincpu": "kn5000_v10_program.llvm.elf"`. The output is
`symbols/maincpu_symbols_reference.txt` -- one file, no revision in its name, no v7 or v9 sibling.
Its `--check` compares that file to the v10 ELF and reports 100%, which is a true and useful
STALENESS check; it says nothing about v7, and nothing in the file or the script warns a reader
that v7 addresses are not in it.

    reference vs v10 ELF : 39,393 / 39,393   100.00%
    reference vs v7  ELF : 10,181 / 39,212    25.96%

⚠ This corrupted work earlier in the same day. Looking up `free_X`, `Boot_ReadFDCStatus` and
`EmptyRoutine_03` for v7 gave addresses whose ROM bytes did not match the blobs at all; the
symptom was noted, worked around by searching the ROM for the bytes, and NOT diagnosed. The
addresses were v10's.

⚠ A second, worse consequence, found by the pointer-table pass: **153 v7 names sit on the wrong
routine**, 152 of them off by exactly 1050 (0x41A), across `SndParam_*`, `MidiPkt_*`, `UIState_*`,
`SoundFX_Handler_*`, `HdaeRom_*` and `CharMap_*`. Byte agreement decides it 153/153 in favour of
the pointer table's target (~1.00 vs ~0.01). Anything that renamed v7 routines from the v10 file
would have moved code silently -- which is why `convert_v7_ptr_tables.py` refuses v10 as a naming
source.

⚠ PROVENANCE OF THAT 153, recorded because it is no longer reproducible in place. It was measured
by `convert_v7_ptr_tables.py --name-conflicts` on the tree BEFORE the pointer tables were
converted. Run today it reports `0 / 0`: the cross-check reads `.incbin` blobs, and those blobs are
now `.long <symbol>` lines, so there is nothing left to cross-check. To reproduce:

    git worktree add --detach /tmp/wt 056a9a1^
    cd /tmp/wt && make clean-all && make llvm-all      # its ELF has DIFFERENT addresses;
                                                      # borrowing the current one is wrong
    cp <this repo>/scripts/converters/convert_v7_ptr_tables.py scripts/converters/
    python3 scripts/converters/convert_v7_ptr_tables.py --name-conflicts

The measurement stands; what changed is that the evidence now needs a build of an older commit to
re-derive, and a figure whose reproduction takes a 15-minute build should say so rather than look
like a one-liner.

⚠⚠ **EVERYTHING IN THIS SUBSECTION ABOUT "DISPLACED LABELS" IS RETRACTED (2026-08-23).**

The detector behind it (`v7_label_displacement.py`) compares v7 bytes against the same-named
routine in **v9** -- a heuristic across two DIFFERENT programs. The ROM's own pointer tables point
at those labels' ORIGINAL addresses, and of the labels a pointer table can check, **11 of 11
contradict the detector**: every word that broke shows `ROM - built = exactly 0x41A`. A name shared
across revisions is a hypothesis; a pointer the firmware dereferences is evidence.

981 label "repairs" built on it were committed and have been REVERTED (`8998d1b`); all six rebuilt
ROMs are byte-identical again, verified by `scripts/analysis/assert_byte_identical.py` rather than
by a percentage.

⚠ HOW IT GOT PAST THE GATE, which matters more than the finding: the check was
`grep -c "Similarity: 100.00%"`, and that string is a PREFIX of
`Similarity: 100.00%  (22 incorrect bytes)`. The percentage is rounded to two decimals -- up to 104
bytes in a 2 MB ROM. Fourteen run logs carry the pattern. The corruption was printed the whole
time. See spec anti-patterns 15 and 16.

The text below is kept as written, because the reasoning is a useful record of how a plausible
measurement went wrong -- but NONE of its conclusions should be acted on.

---

⚠ THE 153 NAMES ARE A SOURCE DEFECT, NOT A GENERATION DEFECT -- confirmed by bytes 2026-08-23.
`FileData_AllocLoadAndParse` is the clean test case. The v7 reference (correctly generated from
the v7 ELF) puts it at 0xFD2305. Comparing 16 bytes against the same routine in v9:

    v9 at its own symbol   ef6c2e0b20001d720effef62bf0263af
    v7 at 0xFD1EEB         ef6c2e0b20001da306ffef62bf0263af   14/16 match
    v7 at 0xFD2305 (file)  1e020aaf0e20f3e1cc0230af0421f3e5    0/16 match

The routine is at 0xFD1EEB; the LABEL in the v7 sources sits 0x41A above it. So the per-link
regeneration is right and the sources are wrong.

⚠ **AND IT IS 21x LARGER THAN 153.** That figure came from a pointer-table cross-check, which
only ever examined the 1,309 names reachable through those tables. Re-derived from first
principles over ALL 39,212 names defined in both the v7 and v9 links
(`scripts/analysis/v7_label_displacement.py`, which scores v9's bytes against v7's ROM at the
label and then searches nearby):

    labels sitting off their routine : 3,481
    of those, displaced by -0x41A    : 3,254

Robust to window size -- widening from 24 to 32 bytes RAISES the count, so it is not a threshold
artefact. Spot-checked independently: `AccMidi_DispatchLoop` scores 0/32 at its label and 30/32
at label-0x41A. ⚠ Entries with |delta| at 0x800 are clipped at the search bound and their true
displacement may be larger; the -0x41A cluster sits well inside it and is the credible signal.

A single constant across 3,254 labels is a systematic source defect, not scattered mistakes. It
is also CONTIGUOUS, which narrows it further:

    displaced by -0x41A                       3,474      (32-byte window, thresholds 8/28)
    span                                      0x00FCCE4A .. 0x00FFFE80   (~208 KB)
    correctly-placed labels inside that span  4          (one is the 0x800 clipping artefact)
    displaced labels outside the span         0
    gaps > 0x400 between consecutive ones     8

So it is ONE region at the top of the ROM in which essentially every label is 0x41A too high,
and everything below 0xFCCE4A is fine. That is the signature of a region whose labels were placed
against another link's addresses, not of thousands of independent errors -- and it means the
repair is plausibly ONE operation rather than 3,474.

WHAT THE REPAIR NEEDS, so the next pass does not have to rediscover it:
  * for each label in the span, the true site is `label - 0x41A`; the source line carrying that
    address must be found and the label moved onto it;
  * ⚠ the byte-match gate CANNOT review this. Moving a label changes no bytes, so `make all`
    reports 9/9 whether every label lands right or every one lands wrong. The check that CAN see
    it is `v7_label_displacement.py`, which must go to ~0 displaced afterwards;
  * the 4 correctly-placed labels inside the span must NOT be moved -- a blanket shift would
    break them, which is exactly why this is not a `sed`.
FEASIBILITY, MEASURED (`scripts/analysis/v7_label_repair_feasibility.py`) -- the repair is far
more tractable than the raw count suggests:

    displaced labels                        3,474
      target address free                   3,353
      target held by an ALSO-DISPLACED label  109   frees in the same simultaneous shift
      target held by a STATIC label            12   <- the ONLY genuine conflicts
    => targets not owned by a static label  3,462 of 3,474

⚠ **THAT LINE READ "mechanical moves" AND WAS WRONG — corrected 2026-08-23.** It measured only
whether a LABEL already owned the target address. An unowned address is not a placeable one, and
nothing had tested whether a SOURCE LINE exists there. Against the converter's own block index:

    targets landing INSIDE a `.byte` run (nothing to attach a label to)   2,834
    targets in a code region (a line boundary plausibly exists)             640

So the repair is NOT mostly mechanical today: for 2,834 of them the destination sits mid-way
through an undisassembled byte run, and putting a label there means SPLITTING the run, which is
conversion work rather than renaming. The same failure shape as the rest of this document -- I
asked a question the data could answer and reported it as the question I cared about.
    correctly placed inside the region          4   must be excluded BY NAME

⚠ The two-level question is what makes this tractable, and asking only the first level misleads:
"is the target occupied?" answers 121. "Is it occupied by a label that is ITSELF moving?" answers
12. A repair plan built on the first number would have looked ten times harder than it is.

⚠ USEFUL CONSEQUENCE: the label repair gets EASIER as conversion proceeds -- every `.byte` run
that becomes instructions moves some of those 2,834 into the 640 case. The two jobs are coupled,
and the repair should FOLLOW the conversion rather than race it.

So the outstanding work is 640 currently-placeable moves, 2,834 blocked behind conversion,
12 named decisions (`CharMap_ActivePreamb_
Prologue` vs `DirectReturn_DoDrainQue`, `MidiSeq_SendMultiByte_CompIface` vs `PreLswLoad`, and ten
more, all listed by the probe), and 4 labels to leave alone.

DELIBERATELY NOT ATTEMPTED in this session: the edit itself. Not because it is unclear -- it is now
fully specified -- but because the byte-match gate cannot review it, so it needs a pass that
verifies each move against `v7_label_displacement.py` returning to ~0, rather than one that trusts
a plan written at the end of a long day.

⚠ MOVING THEM IS NOT A GATE-SAFE EDIT. Relocating a label changes no bytes, so `make all` will
report 9/9 either way (spec anti-patterns 12 and 13). Each move needs its own byte evidence, of
the kind shown above. Deliberately NOT attempted in bulk.

FIXED 2026-08-22: `PAIRS` now maps `maincpu_v7`/`maincpu_v9`/`maincpu_v10` to their own ELFs and
`--check` measures each against the build it came from (all 100.0%). The un-suffixed `maincpu`
file is kept so the ~20 existing consumers keep working, is byte-identical to `maincpu_v10`, and
now opens with a header stating the 100.00%/25.96% split and that renaming v7 labels from it would
move code.

⚠ STILL TO DO: the consumers themselves. `scripts/renaming/*.py` and several analysis scripts read
the un-suffixed file by name; each must be pointed at the right link before it is trusted for v7
or v9. The header warns a human reader; it does not stop a script.

## L2: what the regeneration fixed, and what it did not

All five symbol reference files were stale, not just the one that admitted it. `table_data` agreed
with its build on **1 row out of 4,689**. They are now generated from the ELFs -- which are
byte-identical to the original ROMs -- and re-checked at 100%.

One class of wrongness is now measurable rather than merely feared.
`l2_name_vs_fopen_mode.py` reads the mode string each routine passes to `fopen` -- `"wb"` writes,
`"rb"` reads, and that is not a matter of opinion -- and compares it with the routine's name. Of 57
sites it flags 3; two are false positives that inspection settled (`StylCnv_*_WriteExtension` write
an extension into a NAME BUFFER, and sit among `FindDot`/`FindDot2`/`FindDot3`), leaving **one
genuine oddity: `LoadFileVariant` at 0xF8805B passes `"wb"`**, mode string verified at 0xEA0244. The
script exits non-zero while that stands.

Two lessons from building it, both now in its docstring. **A verb does not say what it acts on** --
two thirds of the flags were buffer-writes, so flagged rows get read before they get believed. And
the first version found only 11 of 57 sites because it required mode strings to be preceded by
`0x00`, when this ROM separates them with `0xFF`; a quiet under-count looked exactly like a clean
result.

What none of this does is make the names good. The metric counts a name as positional only when it
restates an address (`_0xHEX`, a bare hex tail, `LABEL_*`); everything else scores as semantic. So
90.8% is a **lower bound on naming coverage, not a judgement of aptness**. ⚠ The sentence that
stood here -- "and no script can supply the latter" -- is RETRACTED; see the L2 retraction above.
No script can judge aptness *in general*, but that is not the same claim, and the difference was
worth four real defects: names that DECLARE a checkable fact (a return value, an `fopen` mode) can
be tested against the code, and `l2_name_vs_return_value.py` found four wrong ones by doing it.
⚠ A SECOND CONCRETE INSTANCE, found 2026-08-23 while answering a tone-generator question:
**`ToneGen_ParamTable` (0x00E0E407, 1,389 B) is a JUMP TABLE for the sound editor UI**, not
tone-generator data. All nine of its references are `lda_24 xde, (…)` / `ld XHL,(XBC)` /
`call (XHL)` in `sound_editor_ui.s`; no TG register is touched by it. The name is the obvious
thing to consult when working on the tone generator, and it is wrong. No aptness script catches
it, for exactly the reason below -- it declares nothing checkable.
Prover: `scripts/analysis/v7_tonegen_paramtable_is_a_jumptable.py`.

What survives is the narrower statement, and it is still sharp: a name that declares nothing
checkable cannot be tested this way. `FileIO_ReadHeader` actually builds a file path and never
reads a header -- it counts as semantic either way, and no return-value or mode check would catch
it. Wrong-but-plausible names of THAT kind remain invisible to every measure here, and there is no
reason to think it is the only one.

## L5: "cannot be" was wrong

I scored the panel side as unspecifiable without a logic analyser. That was a claim, not a
measurement, and it did not survive being tested.

The bootloader's CP-serial driver and the runtime CPanel stack are **ONE implementation at two link
addresses**. Verified here independently of the probe: the status field sits at `base+11` and the
previous-state field at `base+32` in both, with base 0x8DAE in v7 and 0x8E4A in v9/v10 (0x1022 in
the bootloader). Same 15 command frames, same dispatch tables.

Two consequences beyond the protocol itself, both name corrections: `Boot_ClassifyDeviceID` is not
a device probe, it is `CPanel_CheckSpecialCombos`; and the boot driver's "XOR-scramble buffer" is
the button-state array.

`docs/kn5000-control-panel-panel-side.md` now specifies clock mastership, line arbitration, framing
-- including a `(first & 0x3f) >= 0x30` guard the older document omits -- the full 256-value
first-byte message space, and the acceptance test behind every command. It also names the four
things that genuinely need hardware, which is a sharper statement than the one it replaces.
`analysis/cpanel-protocol-probes/` reads only the ROMs and its gate exits non-zero.

## What is not done, and where it lives

(Was "the three things". Item 1 is now closed to a residue; the count is kept honest below.)

1. **`.LSW`'s 24 slot blocks.** IN these ROMs after all -- the earlier "not in these ROMs" was a
   RETRACTED string-search artefact (the code says index `0`, never `"LSW"`). Now known: `.LSW` is
   **"CURRENT PANEL"** (KN7000 widget labels, cross-confirmed twice and by four real files), it is
   **file type 0**, and type 0 has a dedicated handler in every revision -- v7 `F876E9`, v9/v10
   `F87AF6` -- which sizes DRAM `0xF980..0xFFC0`, the panel area kept across power-down.
   Provers: `scripts/analysis/lsw_saveall_table.py`, and `tools/widget-map/kn7000_widget_labels.py`
   in the KN7000 repo. **CLOSED 2026-08-22.** The region-to-block mapping is read. The KN5000
   WRITES 0xE40 in four parts (0x20 header from `0xF980`; block 0 0x3C0 from `0xF9A0`; block 1
   0x260 from `0xFD60`; 0x800 from `0x1E7800`), and `FileIO_CheckRegionSignature(0)` demands `"HK"`
   at file offset 4 -- which the ROM's own default panel image at `0xEDB3DC` (`5A 5A 00 00 48 4B`)
   satisfies, so the live panel area IS a `.LSW`. The 0x5800 files are `"M60"` headers, classified
   as format 2 and imported by a converter, which is why a failing `"HK"` does not stop the load.
   **The 24 slot blocks are PANEL MEMORIES** (0x300 each at 0x0680..0x4E80), read into
   `0x1ED400 + 960*j` between `PrePmLoad`/`PostPmLoad`.
   Prover: `analysis/disk-format-probes/lsw_region_to_block_map.py`, which fails when perturbed in
   three directions. **Residual open questions, smaller than the original:** why format 2 imports
   only 10 of the 24 (`0x000A` is a literal; format 1 uses `0x0018`, and header byte +7 is 0x0A but
   the firmware ignores it); the 0x30 gap at 0x4E80 and the 0xC0 at 0x53C0; and what `"M4"`/`"NN"`
   are.

   ⚠ UPDATE 2026-08-23, three of those four residual questions are now settled or closed:
   * **Why format 2 imports only 10 of 24 -- SOLVED, and no format-1 disk was needed.** Slot
     blocks 10..23 are byte-identical across all seven disks and are period-10
     (`block[i] == block[10 + (i-10) % 10]`) -- they are the DEFAULTS, and `02BOSSA_`'s untouched
     user slots 5..9 equal blocks 15..19. `0x680 + 10*0x300 = 0x2480` is exactly the first byte of
     block 10, so the firmware reads every informative byte and stops.
   * **`"M4"`/`"M6"`/`"NN"` are a DISK GENERATION, not three layouts.** The dispatcher calls the
     SAME importer pair for formats 1 and 2 (v9 `FD276E`/`FD2938`); the only format-dependent
     value in it is one immediate, `0x0018` vs `0x000A`. Format 3 has its own importer
     (`FD4366`/`FD44D5`) and is fully mapped: 23 part records of 12 bytes (not 32), then tags
     48/90/70/71/72, then a per-part array at 0x19E permuted through ROM 0xEE1584.
     `DataBuf_CheckSubFormat` gives the `.SQF` the same generation number, which is what fixes the
     reading. What they are AS PRODUCTS is still not determined -- no string in any of the seven
     images ties them to a model.
   * **The 0x30 gap at 0x4E80 and the 0xC0 at 0x53C0 -- CLOSED AS UNANSWERABLE FROM THIS ROM.**
     The importer never seeks (zero seek calls across all five routines) and
     `FileIO_CheckRegionSignature` rewinds, so the format-2 cursor stops at 0x2480. **The KN5000
     never reads those bytes.** Measured anyway: the 0xC0 is one 16-byte pattern x12, identical on
     all seven disks (zero information); the 0x30 varies. The "24 u16 per slot" reading is now
     refuted a SECOND way, in both word orders. Settling it needs a differential capture on the
     machine that WROTE the disks.
   Provers: `analysis/disk-format-probes/lsw_formats_1_and_3.py` and `lsw_param_namespace_map.py`,
   both asserting, both with a verified "can it fail?" section.

   ⚠ Three claims in `kn-disk-file-formats.md` were REFUTED by this and are corrected in place
   -- the worst of them, "no KN5000 code reads or writes `.LSW` contents", was a case-sensitive
   search missing the mixed-case `PreLswLoad`/`PostLswSave` names at `0xE1F726`.
2. **NOTE2's extra bytes in the factory styles.** NOT this machine's doing -- the emitter and its
   twelve-record table are identical in v7/v9/v10 and can produce three distinct pairs; the corpus
   holds 57. The styles were authored on other equipment before being written to the initial data
   disk.
3. **Control-panel behaviour.** The KN5000 half is specified from the firmware
   (`kn5000-control-panel-serial.md`). What the PANEL puts on the wire needs a logic analyser on a
   real instrument; the project's data-wheel defect and the falsified `kn5000-30` fix live there.

Item 1 WAS answerable by more analysis of these ROMs, and the earlier sentence here -- "none of
the three is answerable by more analysis of these ROMs" -- was wrong about it. It is now read from
the importer's own immediates. Items 2 and 3 stand: one is located on other equipment, one needs a
logic analyser. The residue of item 1 needs a format-1 `.LSW`, which is a disk we do not have
rather than an analysis nobody did.

## Traps that produced most of this session's wrong answers

Written here because they cost more than any single format did, and they will catch the next person.

1. **Recursive `grep` skips 47% of this tree.** The wrapper is ugrep with `-I`, and 65 of 506 `.s`
   files hold bytes above 127 in `.ascii` data. Named files are searched; recursive searches omit
   them silently. Use `command grep`. This had already made a committed "I searched everywhere"
   claim false.
2. **`Path.read_text()` corrupts these sources.** Same root cause. A rewrite through text decoding
   destroyed `.ascii` payloads and produced a confident, committed, false conclusion that a working
   build could not work.
3. **Curated symbol names are not evidence.** `AccPlay_FindSlotByChannel` searches by NOTE.
   `Display_FontPalette_Table_0x12EA` is a mod-12 lookup. `CharMap_ValueData_B` is a parameter
   table. Cite instructions and addresses.
4. **A tool that shares a scratch file is not safe to parallelise.** Both converters wrote the
   bytes-to-decode to a FIXED path under the temp dir, then read the disassembly back. Run two at
   once -- which is exactly what "use more agents" means -- and one overwrites the other's bytes
   between the write and the read. It produced a census line reading `0xF04E98 inc 1,WA` where the
   ROM holds `1d 09`, a call. The byte-match gate meant no bad conversion could LAND, but the
   decode is the input to every census and every priority call that is not gated. Fixed with a
   per-process `mkdtemp`. The general form: adding parallelism can invalidate a tool that was
   correct for years, and it fails by producing plausible output, not by crashing.
5. **An elegant explanation that fits the number is still a guess.** "The styles were written by a
   different firmware revision" fit perfectly and was falsified in ten minutes by dumping three
   ROMs. Check before committing the sentence.

## What "done" would take from here

A KN7000-side trace, a hardware capture, and the mechanised L1 census. Everything else in the
specification is either passing with a runnable check or partial with its gap named and located.
