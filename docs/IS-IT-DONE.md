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
| **L1** every byte classified | **PARTIAL** | no UNKNOWN bytes remain in the audited ROMs, but the classification is not itself mechanised. |
| **L2** semantic names | **PARTIAL** | sources are well-symbolised; `symbols/maincpu_symbols_reference.txt` matches the build on 1,332 of 39,449 rows and says so in its own header. |
| **L3** field meanings | **PARTIAL** | every event status in both event formats decoded. Open: NOTE2's extra bytes AS THEY APPEAR IN THE CORPUS, and the `.LSW` 24-slot payload. |
| **L5** protocols reimplementable | **PARTIAL** | SLIDE4K/8K, the style container, the sequencer/SMF subsystem and the control-panel link are specified, three with executable tests. Panel-side behaviour is not, and cannot be. |
| **L6** evidence re-derivable | **PASS** | every quoted number has a committed producer; ten claims were retracted this session rather than left standing. |

## The three things that are not done, and where they live

1. **`.LSW`'s 24 slot blocks.** NOT in these ROMs -- traced: the KN5000 names the extension, uses
   `A:\HAMA\*.LSW` as a disk-test scratch glob, and carries an `EV_LSWDATA` widget event, but never
   parses the contents. The KN7000 does: fourteen-entry type table, and SD load/save widgets
   `SD_LD2_LBLSW` / `SD_SV2_LBLSW`. A KN7000 task, with handles.
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
