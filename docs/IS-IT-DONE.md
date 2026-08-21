# Is the KN5000 disassembly done?

**No.** This is the measured answer to that question, scored against
`DISASSEMBLY-COMPLETENESS-SPEC.md`, with the command that re-derives each row. Written 2026-08-21
after a day spent testing the claim rather than repeating it.

Read this before believing any single number elsewhere in the repository: several figures that
stood for months were wrong, and are corrected in the history rather than quietly replaced.

## The scorecard

| level | status | evidence |
|---|---|---|
| **L0** byte-exact AND capable of failing | **PASS** | `rom_provenance_poison.py all` -- v7, v9, v10 report 0 copied bytes. v7 was 979,096 B (46.69%) copied this morning. |
| **§3** binary includes justified | **PASS** | `audit_incbin_legitimacy.py` -- 873 directives, every one in a justified category, exits non-zero if not. Was 1,371,778 illegitimate bytes. |
| **L4** assets round-trip | **PASS** | seven converters in `scripts/build/`, each `verify` asserting ROUND TRIP EXACT. |
| **L1** every byte classified | **PASS** | `l1_territory_map.py v7 v9 v10` -- flattens each source tree through llvm-mc and assigns every byte to CODE/DATA/PADDING; all three totals equal their rebuilt ROM to the byte. ASSET is folded into DATA here (llvm-mc expands `.incbin`); its separate justification is the §3 row. |
| **L2** semantic names | **PARTIAL** | reference files now regenerate FROM the build and match it 100% (`l2_symbol_reference.py`, was 3.4% on maincpu and 0.02% on table_data). Naming itself is **90.8% semantic** on maincpu -- 3,627 positional names remain; 88.9/84.9/99.9/97.7% on subcpu/boot/table_data/hdae5000. |
| **L3** field meanings | **PARTIAL** | every event status in both event formats decoded. Open: NOTE2's extra bytes AS THEY APPEAR IN THE CORPUS, and the `.LSW` 24-slot payload. |
| **L5** protocols reimplementable | **PARTIAL** | SLIDE4K/8K, the style container, the sequencer/SMF subsystem and the control-panel link are specified, three with executable tests. Panel-side behaviour is not, and cannot be. |
| **L6** evidence re-derivable | **PASS** | every quoted number has a committed producer; ten claims were retracted this session rather than left standing. |

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
were work the toolchain could not be ASKED for. They are now writable as instructions.

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
90.8% is a **lower bound on naming coverage, not a judgement of aptness**, and no script can supply
the latter. This session found `FileIO_ReadHeader` actually builds a file path and never reads a
header -- it counts as semantic either way. Wrong-but-plausible names are invisible to this measure,
and there is no reason to think that one is the only one.

## The three things that are not done, and where they live

1. **`.LSW`'s 24 slot blocks.** IN these ROMs after all -- the earlier "not in these ROMs" was a
   RETRACTED string-search artefact (the code says index `0`, never `"LSW"`). Now known: `.LSW` is
   **"CURRENT PANEL"** (KN7000 widget labels, cross-confirmed twice and by four real files), it is
   **file type 0**, and type 0 has a dedicated handler in every revision -- v7 `F876E9`, v9/v10
   `F87AF6` -- which sizes DRAM `0xF980..0xFFC0`, the panel area kept across power-down.
   Provers: `scripts/analysis/lsw_saveall_table.py`, and `tools/widget-map/kn7000_widget_labels.py`
   in the KN7000 repo. **Still open:** the handler moves 0x640 + 0x800 bytes and the file is 0x5800,
   so the region-to-block mapping is unread. The next pass has a function to disassemble.
2. **NOTE2's extra bytes in the factory styles.** NOT this machine's doing -- the emitter and its
   twelve-record table are identical in v7/v9/v10 and can produce three distinct pairs; the corpus
   holds 57. The styles were authored on other equipment before being written to the initial data
   disk.
3. **Control-panel behaviour.** The KN5000 half is specified from the firmware
   (`kn5000-control-panel-serial.md`). What the PANEL puts on the wire needs a logic analyser on a
   real instrument; the project's data-wheel defect and the falsified `kn5000-30` fix live there.

None of the three is answerable by more analysis of these ROMs. Two are located elsewhere and one
needs hardware -- which is a different statement from "unknown", and is the main thing that changed
today.

## Four traps that produced most of this session's wrong answers

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
4. **An elegant explanation that fits the number is still a guess.** "The styles were written by a
   different firmware revision" fit perfectly and was falsified in ten minutes by dumping three
   ROMs. Check before committing the sentence.

## What "done" would take from here

A KN7000-side trace, a hardware capture, and the mechanised L1 census. Everything else in the
specification is either passing with a runnable check or partial with its gap named and located.
