# notes/ — the prom_b lane's scripts

One entry per script: the question it answers, and the exact command. Every
number quoted in `FINDINGS-ui-display-list.md`,
`FINDINGS-ui-display-list-interpreter-b.md`,
`FINDINGS-prom_b-dispatch-layers.md` and `FINDINGS-prom_b-thunk-table.md`, and
every count asserted in a routine header in `prom_b/wsa1_prom_b.s`, comes from
one of these or from a script in `scripts/analysis/`.

⚠ None of them is self-checking the way the build gate is. The gate
(`python3 scripts/analysis/assert_byte_identical.py`) proves the bytes; it says
nothing about a name or a comment. These scripts are what a name or a comment is
allowed to rest on.

⚠⚠ **EVERY SCRIPT LISTED HERE IS UNTRACKED** (added 2026-08-25). The prom_b lane
is not permitted to `git commit`, so these files exist only in the working tree.
Until someone commits them, the sentence above — "every number quoted comes from
one of these" — is true of a tree that a single `git clean -fd` would destroy,
and the numbers would then be unreproducible. **Committing `notes/*.py` is the
first thing the owner of this tree should do.** Nothing else in this lane can fix
it. Files concerned:
`prom_b_dl_length_audit.py`, `gen_prom_b_display_lists_v2.py`,
`prom_b_dl_operand_tables.py`, `gen_prom_b_dl_operand_tables.py`,
`prom_b_dispatch_tables.py`, `prom_b_f7d_tables.py`, `llvm_roundtrip_force.py`,
`prom_b_default_slot_census.py`, `prom_b_call_graph.py`,
`prom_b_blink_rate.py`, `prom_b_param_edit_pair.py`.

⚠ **One correction this lane could NOT apply.** The audit of 2026-08-24 flagged
`scripts/analysis/prom_b_display_lists.py`'s docstring for carrying "243 of 244"
(line 20) and "zero exceptions" (line 24) as if they were retracted text. They
are **not** retracted — both figures were RESTORED and both are reproduced by
`prom_b_dl_length_audit.py` above. So the docstring needs no correction; what
needed correcting was the note that called it stale, and that is done here. The
prom_b lane may not edit `scripts/`, so this is recorded rather than applied.

## `prom_b_dl_length_audit.py`
**"Are the 341 'length-rule violations' in the display lists really violations?"**
No: they are interpreter-B records measured against interpreter A's layout.

    python3 notes/prom_b_dl_length_audit.py            # the counts
    python3 notes/prom_b_dl_length_audit.py --edges    # first and last record of each class
    python3 notes/prom_b_dl_length_audit.py --records  # every record
    python3 notes/prom_b_dl_length_audit.py --bspans   # the B-only spans

Reads the implied length of every record off its handler's own instructions, one
handler per line in the docstring. Exits non-zero if any record disagrees with
its own interpreter's rule. Current result: 3,603 A records / 0, 494 B records / 0.

## `gen_prom_b_display_lists_v2.py`
**"What does the display-list section look like when each record is rendered by
the interpreter that runs it?"** This is the emitter whose output is in the .s.

    python3 notes/gen_prom_b_display_lists_v2.py --lo 0x00000 --hi 0x31800
    python3 notes/gen_prom_b_display_lists_v2.py --lo 0x32709 --hi 0x40000

A-record text is byte-identical to what `scripts/analysis/prom_b_display_lists.py
--asm` produces, so a diff between the two is exactly the B records.

## `prom_b_dl_operand_tables.py`
**"What is in the `.incbin` gaps between the display lists?"** The lists say: the
records carry pointers, and the handler that consumes each pointer fixes the size
of the thing pointed at.

    python3 notes/prom_b_dl_operand_tables.py           # every gap, graded
    python3 notes/prom_b_dl_operand_tables.py --exact   # only the proven ones
    python3 notes/prom_b_dl_operand_tables.py --dump 0xF031C9

Grades a gap EXACT when the objects tile it end to end with the size each
handler implies, and TILED when they tile by their starts with each extent a
whole number of entries and the last object's implied size exact. Anything less
stays `.incbin`, because the entry count a record implies is an upper bound on
the INDEX, not a measurement of the array. 13 gaps, 999 bytes, currently pass.

## `gen_prom_b_dl_operand_tables.py`
**"…and what is the assembly for the gaps that pass?"**

    python3 notes/gen_prom_b_dl_operand_tables.py --list
    python3 notes/gen_prom_b_dl_operand_tables.py

## `prom_b_dispatch_tables.py`
**"How many entries do the selector-dispatch tables at 0xF5B8F8 and 0xF5B9F8
have?"** 48, not the 64 the code's `0xC0` bound would allow.

    python3 notes/prom_b_dispatch_tables.py

Re-reads every byte it argues from — the two `ld XIY,imm32` immediates, all 96
table words, the word past each table, and the first byte after each table — and
exits non-zero if any check fails.

## `prom_b_f7d_tables.py`
**"How many 32-entry dispatch tables sit at 0xF7D2D8?"** 32, by three independent
counts that must agree.

    python3 notes/prom_b_f7d_tables.py

Also re-checks that prom_a `0xF8BDEA` really is
`and L,0x1F / sla 2,L / ld XIX,(XIX+L) / call XIX`, which is what fixes the table
at 32 entries.

## `prom_b_call_graph.py`
**"What should be converted next?"** Answers it mechanically instead of by
taste: every `jp` slot of the thunk table, ranked by an opcode-anchored
reference upper bound, filtered to targets that are in prom_b AND still inside
an `.incbin` in `prom_b/wsa1_prom_b.s`.

    python3 notes/prom_b_call_graph.py               # top unconverted targets
    python3 notes/prom_b_call_graph.py --n 60
    python3 notes/prom_b_call_graph.py --covered     # what IS converted
    python3 notes/prom_b_call_graph.py --callees 0xF0E800

The converted/unconverted split is exact — it is parsed from the .s's own
`.incbin` directives, and a self-check asserts the total matches
`scripts/analysis/source_coverage.py`. The reference counts are NOT exact: they
rank slots and must never be quoted as call counts.

## `prom_b_blink_rate.py`
**"How fast does the field-blink engine at 0xF0E800 flash?"** 1.27 Hz, 0.39 s on
and 0.39 s off — and every link of the chain from the crystal to the toggle is
re-read from the ROM.

    python3 notes/prom_b_blink_rate.py

⚠ It prints an UPPER BOUND, and says so: the last link assumes prom_a's main
loop iterates faster than 10.17 Hz, which nothing in this tree measures.

## `prom_b_param_edit_pair.py`
**"Is 0xF5535B really 'the same routine as sub_F550A6 with the pointer arguments
swapped'?"** No, and this script is why that sentence is no longer in the .s.
It measures what the two DO share — a 100-byte adjust core, identical in 99 of
100 bytes — and self-checks the three structural differences.

    python3 notes/prom_b_param_edit_pair.py

## `prom_b_default_slot_census.py`
**"Does the default thunk slot `0x00F42C70` fill one dense run, or many?"** Many.
Written 2026-08-25 to fix a claim that joined two measurements by hand ("222 of
them in one dense run at prom_a 0x216B4" — 222 is prom_a's total; the longest
stride-4 run is 10).

    python3 notes/prom_b_default_slot_census.py          # the census + self-checks
    python3 notes/prom_b_default_slot_census.py --runs   # every run of >= 2

Counts the 4-byte spelling at EVERY byte offset (not only 4-aligned ones) and
reports the maximal stride-4 run separately from the total, so the two can never
be conflated again. Exits non-zero if a self-check fails.

## `llvm_roundtrip_force.py`
**"What does this range say, in a form the gate will accept, when
`scripts/analysis/llvm_roundtrip.py` cannot converge?"**

    python3 notes/llvm_roundtrip_force.py b 0xF5533C 0x1F
    python3 notes/llvm_roundtrip_force.py b 0xF7D000 728

The committed script finds the instruction to demote by locating the first
differing BYTE, which cannot work when an instruction assembles to a different
WIDTH — every later byte shifts and the first difference is byte 0 forever. It
gives up with "cannot converge at byte 0"; prom_b `0xF5533C`'s `push 0x00` does
this. This wrapper reuses the committed script's own unidasm, spelling cache and
assemble-and-compare, adds `--force ADDR,...`, and on a width mismatch demotes
every instruction that does not individually round-trip. A listing it prints has
still been proven byte-for-byte against the ROM before printing.
