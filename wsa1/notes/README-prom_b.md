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
`prom_b_blink_rate.py`, `prom_b_param_edit_pair.py`,
`prom_b_module_trace.py`, `gen_prom_b_blockstore_module.py`,
`prom_b_var_screens.py`, `prom_b_bank_index_census.py`.

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

## `prom_b_module_trace.py`
**"Which bytes of a module are CODE, and which are DATA?"** Recursive descent
inside one address range, seeded from the thunk table's own `jp` targets.

    python3 notes/prom_b_module_trace.py 0xF62C00 0xF64C10
    python3 notes/prom_b_module_trace.py 0xF62C00 0xF64C10 --entries
    python3 notes/prom_b_module_trace.py --selftest

Written 2026-08-25 because a linear sweep cannot find a data island: it
resynchronises afterwards and the only symptom is that a KNOWN entry point stops
being on an instruction boundary. prom_b `0xF63441` does exactly that — the
linear decode steps over `0xF63489`, which is thunk `T_F42790`'s target. ⚠ It
also showed that `scripts/analysis/trace_code.py`'s 32-phase decode table is
**not** complete: neither `0xF63489` nor `0xF63CE0` has an entry in it, because
the phase sweeps resynchronise long before they reach that module. This script
therefore decodes on demand from the address itself, and `--selftest` asserts
the `0xF63441` result.

## `gen_prom_b_blockstore_module.py`
**"…and what is the assembly for the block-store module at 0xF62C00?"** This is
the emitter whose output is in the .s.

    python3 notes/gen_prom_b_blockstore_module.py
    python3 notes/gen_prom_b_blockstore_module.py --layout

Code runs go through `llvm_roundtrip_autoforce.py`; the three data islands are
`.byte` with their patterns re-asserted at emit time
(`assert_data_islands()` — a wrong description stops the emit); the 1,008-byte
`0x0E` tail is `.fill`. **Every count in every header it writes is computed by
the script**: the per-routine caller lists, the stub-table census, the
`(0x0D4A)` error-code census and the tag-comparison census. The first draft
under-counted `BStore_CursorAdvance` at 11 sites instead of 15 because the
caller map was built one segment at a time and `dict.update` replaced instead of
merging; it is now a separate pass over all segments.

## `prom_b_bank_index_census.py`
**"How many sites compute the `0x610000 + n*0xC00` bank index?"** 48 — 8 in
prom_a, 40 in prom_b — reported as an upper bound because it is a byte window,
not a decode.

    python3 notes/prom_b_bank_index_census.py

Written because the memory-map row for `0x610000-0x6177FF` first carried a
hand-typed list of four sites.

## `prom_b_var_screens.py`
**"Which SCREEN shows a given RAM variable, and what words sit next to it?"**
A reverse index from a 16-bit RAM address to the interpreter-B display-list
records that draw it, plus the interpreter-A text drawn by the same routine.

    python3 notes/prom_b_var_screens.py --census
    python3 notes/prom_b_var_screens.py --var 0x12F6
    python3 notes/prom_b_var_screens.py --table 0xF03241
    python3 notes/prom_b_var_screens.py --site 0xF62C00-0xF65000

Interpreter B reads a RAM address out of every record it runs (`IX=(XIY+2)`
inside `DisplayListB_ExtractField`), so the display lists ARE that index. The
"near:" lines are proximity in the CODE (a window, default 0x200 bytes, around
the B call site) and the script says so — evidence for a name, not a proof of
one. Self-checks: its B-record count must equal the 494 that
`prom_b_dl_length_audit.py` reports, every field is re-read from the ROM, and
the worked example from `FINDINGS-ui-display-list-interpreter-b.md` (record
`0xF0302A` → table `0xF03241`, width 8, mask 0x3F) must come back out.

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

## `prom_b_sc1_states.py`
**"How does the SC1 module's state machine dispatch, which of its labels does
anything reach, and what is in its three jump tables?"**

    python3 notes/prom_b_sc1_states.py             # SC1_StateTable, mapped
    python3 notes/prom_b_sc1_states.py --tables    # all three dispatch tables
    python3 notes/prom_b_sc1_states.py --exits     # the six exit stubs
    python3 notes/prom_b_sc1_states.py --dispatch  # is there a bounds check?
    python3 notes/prom_b_sc1_states.py --writes    # who writes (0x2A80)
    python3 notes/prom_b_sc1_states.py --branches 0xF5B05D 0xF5B242
    python3 notes/prom_b_sc1_states.py --selftest

Written to close round-1 audit finding **F16**: 25 `SC1_*` labels rested only on
the module's section banner, and the group header above the state handlers
described entries "[0]".."[10]" in prose without ever saying which LABEL was
which entry. This resolves every table pointer to the label the `.s` puts at
that address, so those headers are read rather than typed.

It reads each branch's **resolved** target out of the transcription's own
comment rather than redoing displacement arithmetic, and scans both of CPU 1's
ROMs at every byte offset for pointer references — a scan that can only
over-count, so a zero is a real zero. That is what makes "three exit stubs are
unreachable" (see `FINDINGS-prom_b-sc1-link.md`) a measurement.

⚠ Its `reachable()` figure is a **deliberately weak** criterion and both the
docstring and the printout say so: the module has `inc 4` *and* `dec 4` on the
state byte, so the closure is the whole table range no matter what the code
does. It shows only that no table slot is stranded outside the range.

`--selftest` asserts the entry count, the abutment bound, the last entry
(state 0x28 at 0xF5AC8F), that entries [0]/[7]/[10] are one target, that every
target resolves to a label, that the three `_Delayed` stubs stay at zero
references while the three live ones stay non-zero, that `SC1_Irq_Exit_3` has
its nine branches, and the two twin byte-diff counts (0 of 4, and 1 of 15).

## `prom_b_evidence_audit.py`
**"Which prom_b semantic labels are not backed by an Evidence line, and is the
raw grep count honest?"**

    python3 notes/prom_b_evidence_audit.py --since HEAD
    python3 notes/prom_b_evidence_audit.py --all
    python3 notes/prom_b_evidence_audit.py --selftest

Round-1 finding F16 reported "prom_b 50/89" by grepping for the word
"Evidence" in the comment block directly above each label, and flagged in the
same breath that the number over-states the problem. It does. This grades into
four buckets instead of two — BACKED (own Evidence line), GROUP (no header of
its own, but the nearest preceding header names this label *and* carries an
Evidence line), SECTION (only the `; ===` banner does — weak, because the
banner is not about this label), UNBACKED (none) — so the honest figure can be
quoted. Of the 89 labels new since `HEAD` the split was **39 / 21 / 25 / 4**,
i.e. 29 owed evidence, not 50. After round 2: **62 / 27 / 0 / 0**.

⚠ It grades COMMENTS, not truth. A label can be BACKED by an Evidence line that
is wrong; that is what the gate cannot see and what reading the code catches.
Its `--selftest` checks that the grader discriminates at all (a grader that
returned one bucket for everything would pass a keyword grep and is rejected
here).

## `prom_b_f5b800_checks.py`
**"Is every number in the 0xF5B800-0xF5B8B5 and 0xF5BAB8-0xF5BBE6 headers
actually true of the ROM?"**

    python3 notes/prom_b_f5b800_checks.py

The byte gate proves the LISTING rebuilds the ROM and is blind to every claim in
a comment, so this is those two blocks' substitute: 69 PASS/FAIL rows covering
the seven thunk slots and their reference splits (41 references across the first
four, 39 prom_a / 2 prom_b; 1 / 0 / 7 across the next three), the 0xF33022 label
table (mask, stride, size and the LAST entry, index 63), the ONE-byte difference
between each pair of SWI7 veneers (53 bytes, offset 43 only, three times over),
the four SWI7 slot lookups, the shape of prom_a 0xF86AC7, both values written to
the layer byte (0x2540), the draw/erase pair at 0xF02FD9 / 0xF02FE3, and the two
self-terminating 6-entry display-list pointer tables including their LAST
entries. Exits non-zero if any row fails.

⚠ It catches real errors — the banner first said "32 of the 41 references are in
prom_a" when the sum is 39, and this script is what found it. Verified
falsifiable: perturbing the last-entry string, the differing-byte offset and the
prom_a count each produce a FAIL and a non-zero exit.

Every bound it checks is derived from the ROM's own bytes, never from two typed
constants — earlier drafts compared `0x3F` with `63`, recomputed `2C-1`, and
compared a table's last entry with its own base twice over. All three are
round-1 audit finding **F13**'s cannot-fail defect and all three were replaced
with checks that read the image: the mask byte, the four mnemonics as the
verified transcription spells them, and the last record's own length byte. Do
not reintroduce them.

Verified falsifiable a second time after the 0xF5BAB8 section was added:
perturbing the T_F417F0 reference count, the `sla` operand and the last-record
length each produce a FAIL and a non-zero exit.
