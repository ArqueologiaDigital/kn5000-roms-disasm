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

✅ **THE SCRIPTS ARE NOW TRACKED** (checked 2026-08-25, round 7). This section
used to open "⚠⚠ EVERY SCRIPT LISTED HERE IS UNTRACKED ... a tree that a single
`git clean -fd` would destroy", and listed some forty files by name. That was
true when it was written and is no longer: `git ls-files notes/` returns 208
files and every script the old list named — `prom_b_dl_length_audit.py`,
`gen_prom_b_display_lists_v2.py`, `prom_b_audit_callsites.py`,
`prom_b_round5_frontier_delta.py` and the rest — comes back TRACKED. The lane
still may not commit, so anything added in the CURRENT round is untracked until
the tree's owner commits it; as of round 9 that is round 8's
`notes/gen_prom_b_fonts.py`, `notes/gen_prom_b_dsp_value_lists.py`,
`notes/prom_b_screen_arrays.py`, `notes/prom_b_dl_stack_sites.py`,
`notes/gen_prom_b_f58000_module.py`, `notes/prom_b_diskmenu_entrypoint.py`
**plus round 9's `notes/prom_b_message_module.py`,
`notes/gen_prom_b_message_module.py`, `notes/prom_b_dl_call_shapes.py`,
`notes/prom_b_anchored_tiler.py`, `notes/gen_prom_b_anchored_module.py` and
`notes/prom_b_filefield_checks.py`**. Re-check with
`git status --porcelain notes/`.

## WAVE 8 (2026-08-31) — the naming round's six scripts

### `prom_b_msgline.py` — ★ what RAM 0x0FE4 is
**"What is the 30-character text line at RAM 0x00000FE4, and who writes it?"**
Derives, from the ROM alone, that it is one line of on-screen text: the record
at 0xF3D38A, `swi 7` function 6 = `LCD_Svc_06_DrawText8x14`, AP = 40 bytes per
display line, four such lines at x = 8 and y = 52 / 97 / 142 / 180. Then lists
every routine in the committed source that copies into it, with the literal it
copies and the sub-screen code it claims.

    python3 notes/prom_b_msgline.py
    python3 notes/prom_b_msgline.py --writers
    python3 notes/prom_b_msgline.py --selftest    # 45 checks, 2 of them negative

⚠ **A routine that "references an ASCII string" is often NOT a caption
writer** — see `prom_b_string_refs.py` below, which measures the split. The
filter that separates them is the DESTINATION: does the routine copy the bytes
into 0x0FE4-0x1001? That is what this script tests.

### What wave 8's verification actually said

Recorded here rather than left in a report, because the next round will want the
numbers and the reasons.

**Byte gate** PASS after every commit. **Coverage** unchanged throughout:
`notes/reachability.py --targets` prints `STRONG 17 bytes, ANY 1,702, in 17
spans` before and after. **Preservation**
(`prom_b_naming_preservation.py --base 0f08601`): 0 lines unaccounted for, 0
labels lost.

**`prom_b_evidence_audit.py --all`, this tree against the round's base:**

    BACKED    2027 -> 2077   (+50, every new semantic label)
    GROUP       28 ->   28
    SECTION    315 ->  315
    UNBACKED   366 ->  366   (unchanged: the round added none)

Every one of the round's new semantic labels grades BACKED — an `Evidence` line
in its own immediately preceding header.

**`prom_b_probe_answer_diff.py --base 0f08601`,** run with the working tree at
`5acf220` (the six comment lines `7a90144` added to the `.s` afterwards move no
verdict below): 93 probes, **75 unchanged, 18 changed**, and all 18 are the round's own effects rather than damage:

* `gen_prom_b_cover_round2.py` — `.incbin` total 40,932 → 40,812, the 0x78 that
  `DL_EffectParamPage` now occupies. Its verdict is identical, STRONG 0 / weak
  80 / **CLOSED**;
* `prom_b_call_graph.py`, `prom_b_span_frontier.py`, `prom_b_real_coverage.py`,
  `prom_b_thunks_round6.py`, `prom_b_dl_call_shapes.py` — all read the
  `.incbin` set, which the same 0x78 changed;
* `prom_b_evidence_audit.py`, `prom_b_audit_callsites.py`, the three header
  audits and the three `wave7_round*_review_wb_prom_b.py` — they print label
  names and count headers, and the round renamed 51 labels and rewrote 51
  headers. `prom_b_audit_callsites.py`'s totals are unmoved at 3,964 citations
  over 6,333 labels, and **not one of the round's labels appears in its
  unresolved list**;
* `prom_b_msgline.py`, `prom_b_string_refs.py`,
  `prom_b_ram_and_device_census.py`, `prom_b_naming_preservation.py` — the
  round's own tools, whose whole job is to answer differently once the names and
  the `--orphans` count have moved.

### `prom_b_naming_evidence.py` — ★ THE WORK LIST FOR THE NEXT NAMING ROUND
**"What evidence exists for the routines that are still `sub_XXXXXX`?"** Sorts
them by the KIND of evidence the tree already holds, so a round can start at the
top instead of reading addresses in order. Classes overlap.

    python3 notes/prom_b_naming_evidence.py                # the summary
    python3 notes/prom_b_naming_evidence.py --class TABLE  # one class, listed
    python3 notes/prom_b_naming_evidence.py --named        # over ALL routines
    python3 notes/prom_b_naming_evidence.py --selftest     # invariants + controls

As of wave 8, over the 1,864 still bare: STRING 34, TABLE 60, CALLER 196,
CALLEE 475, DEVICE 373, ORPHAN 492, and **616 with no class at all**. ⚠ Those
are counts of a moving tree, not invariants — the `--selftest` asserts
invariants (every label is seen, only declared classes are produced,
`semantic()` rejects every generic spelling, and two routines this round named
land in the class they were named from), never a pinned total.

### `prom_b_string_refs.py` — ★ READ BEFORE NAMING ANYTHING FROM A STRING
**"Which prom_b routines name an ASCII string, and which of those are
CAPTIONS?"** Splits them three ways, because naming from the wrong column
produces a confident wrong name the byte gate cannot see:

    python3 notes/prom_b_string_refs.py             # 43 CAPTION, 19 DL-RUN, 24 OTHER
    python3 notes/prom_b_string_refs.py --unnamed   #  5 CAPTION, 17 DL-RUN, 14 OTHER

`DL-RUN` is the trap: the routine's shape is `ld XIY,<start> / ld XIX,<end> /
call <a display-list runner>`, and the "string" is where the LIST ENDS, not
anything the routine says. `sub_F5C4B8`, `sub_F5D5C8`, `sub_F7E2ED` and
`sub_F7E430` are all in that column and were all deliberately left unnamed.

### `prom_b_effect_param_map.py` — ★ EffectNames entry k IS algorithm k
**"Is entry k of EffectNames_F147AC the name of DSP effect algorithm k?"** Yes.
Closes the ⚠ Unknown that table has carried since it was converted, with an
identity of two 56/72 PARTITIONS rather than a coincidence of counts, plus a
range control (456 of 456 descriptor indices inside a 100-row table). Prints
every effect with its parameter list.

    python3 notes/prom_b_effect_param_map.py
    python3 notes/prom_b_effect_param_map.py --raw
    python3 notes/prom_b_effect_param_map.py --selftest   # 20 checks, 3 controls

Write-up: `FINDINGS-prom_b-dsp-effect-parameters.md`.

### `prom_b_ram_and_device_census.py` — what the driver's map is missing
**Three questions about `src/mame/matsushita/wsa1.cpp`'s memory map, measured
from the committed source.** Every number in sections 1, 2 and 9 of
`FINDINGS-prom_b-for-the-mame-driver.md` comes from here.

    python3 notes/prom_b_ram_and_device_census.py --lowram    # 10 addresses above 0x51FF, 74 refs
    python3 notes/prom_b_ram_and_device_census.py --devices   # 130 addresses, ALL work DRAM
    python3 notes/prom_b_ram_and_device_census.py --orphans   # code that lost its label

★ `--lowram` is the actionable one: the driver maps CS1 as `0x000080-0x0051FF`
and prom_b read-modify-writes `(0x7FC2)`. ★ `--orphans` is the standing check
that no converted routine is attributed to a data object — it found two this
round (`Smf_ReadFile`, `MsgLine_AccompVolume`) and now returns none.

### `prom_b_naming_preservation.py` — ★ RUN THIS AFTER ANY RENAME
**"Did this round DELETE anything, or only substitute a token?"** Every comment
line and label of a base revision must still be present, verbatim or as the same
line with one of the round's renamed tokens substituted, or with its text quoted
inside the correction that replaced it. Prints how many lines fall in each
category; `UNACCOUNTED FOR` must be 0.

    python3 notes/prom_b_naming_preservation.py --base <rev>
    python3 notes/prom_b_naming_preservation.py --base <rev> --show-deleted

It reads the round's rename tables from the appliers themselves, so it cannot
drift from what was applied.

### `prom_b_probe_answer_diff.py` — the cheap complement to probe_health.py
**"Did a NAME change move any prom_b probe's ANSWER?"** Runs every committed
prom_b probe against the current `prom_b/wsa1_prom_b.s` and against a base
revision of that ONE file, everything else identical, and diffs.

    python3 notes/prom_b_probe_answer_diff.py --base <rev> --jobs 6

`probe_health.py` asks "would a per-subject SPLIT break this probe" and builds
three trees; this asks "did THIS edit break it" and swaps the image.

⚠ It runs **93 probes, twice each** — budget hours at `--jobs 1`. And it
**refuses to run without an explicit `--base <rev>`**, on purpose: probe_health
discovers its candidates by grepping every committed .py for the image's
filename, so a bare-runnable version of this script would re-enter the whole
probe corpus inside each of three trees.

### The six appliers
Each carries the round's rename table AS DATA, re-derives every literal it names
from the ROM when run with no argument, and edits the source with `--apply`. The
table IS the change; running one bare is the check that nothing it rests on has
moved. `notes/prom_b_naming_preservation.py` imports all six, so it can never
drift from what was applied.

    python3 notes/prom_b_apply_msgline_names.py        # 36 captions re-derived
    python3 notes/prom_b_apply_smf_names.py            # the SMF brackets and tags
    python3 notes/prom_b_apply_effect_names.py         # the 8-record page
    python3 notes/prom_b_apply_effect_editor_name.py   # the editor's four constants
    python3 notes/prom_b_apply_diskfile_name.py        # the two disk signatures
    python3 notes/prom_b_apply_chordnote_names.py      # note names and chord types

## `prom_b_dl_call_shapes.py` (round 9) — ★ READ THIS BEFORE PICKING A SPAN
**"How many display lists does the committed scanner NOT see?"** It knows one
call shape out of four. This enumerates all four and prints how many bytes that
are still `.incbin` each one names — 6,879 as of round 9, plus 48 lists in
prom_a for that lane.

    python3 notes/prom_b_dl_call_shapes.py            # the census
    python3 notes/prom_b_dl_call_shapes.py --new      # only what is still .incbin
    python3 notes/prom_b_dl_call_shapes.py --sites    # every site, with its verdict
    python3 notes/prom_b_dl_call_shapes.py --selftest # 13 checks, incl. the LAST
                                                      # site of each shape

Its shape-1 scan is asserted to reproduce `scripts/analysis/prom_b_display_lists.py`'s
`call_sites()` exactly, so any difference in the totals is the new shapes and
nothing else. ⚠ It is a byte-level scan: the framing walk is the filter, and
shape 3 (one record, no end pointer) has no framing check at all.

## `prom_b_anchored_tiler.py` + `gen_prom_b_anchored_module.py` (round 9)
**"Tile a display-list MODULE into records and operand tables."** The method
that closed round 9's two spans, written down once so the next module is not
hand-work: anchors from every call shape, record runs where the framing walk
lands exactly, and tables where a record's own pointer and width field say so.

    python3 notes/prom_b_anchored_tiler.py 0xF0C800 0xF0D061
    python3 notes/prom_b_anchored_tiler.py 0xF0C800 0xF0D79C --count
    python3 notes/prom_b_anchored_tiler.py --selftest   # 10 checks
    python3 notes/gen_prom_b_anchored_module.py 0xF0C800 0xF0D061

⚠⚠ Two things it refuses to do, both of which caught a draft: it never takes an
entry count from a record's AND mask (a mask bounds the INDEX — trusting one
produced a 1,536-byte "table" where the anchors say 304), and it emits nothing
for an interval no anchor bounds (`--count` shows the unanchored 4,004-byte
module at 0xF0C800 admits 25,692,504 tilings). Its self-test re-derives both
modules round 9 converted by hand and compares them object by object.

## `prom_b_message_module.py` + `gen_prom_b_message_module.py` (round 9)
**The 0xF2BE35-0xF317FF span, 18,694 substantive bytes — CLOSED.** The layout
script derives every object's extent and kind from the ROM (the pair tables in
prom_a, the interpreter-attribution length rule, and prom_a's four `ldir`
setups) and asserts that they tile the range with no hole; the generator renders
what it derives, using each interpreter's own field layout.

    python3 notes/prom_b_message_module.py              # the layout, object by object
    python3 notes/prom_b_message_module.py --selftest   # 76 checks, 0 failures
    python3 notes/gen_prom_b_message_module.py          # the assembly in the .s

Write-up: `FINDINGS-prom_b-message-and-service-module.md`.

## `prom_b_filefield_checks.py` (round 9)
**"Is prom_a 0xFF76B5 a FILENAME FORMAT or a SCREEN FIELD?"** A screen field —
this re-derives the round-2 audit's finding F1 and the correction that replaced
the claim in `FINDINGS-prom_b-disk-and-file-menus.md`. 22 checks.

    python3 notes/prom_b_filefield_checks.py

## `gen_prom_b_fonts.py`
**"What is in 0xF1B400-0xF27BFF, and how many cells has the last font table?"**
Emits the twelve character generators as assembly — one `.byte` line per glyph
cell, addressed, code-numbered, blank cells marked — and refuses to emit until
it has re-derived every structural claim it rests on.

    python3 notes/gen_prom_b_fonts.py --selftest     # 46 checks
    python3 notes/gen_prom_b_fonts.py --asm

Its one new number is the twelfth table's cell count, **128**, which
`FINDINGS-fonts.md` §8 listed as open: the last non-zero byte of the whole font
region (0xF26D7C) falls inside cell 127, and the defined codes are exactly the
contiguous printable range 0x21-0x7F. ⚠ It states, and rejects, the rival
180-cell reading — base and pad start are both multiples of 48, so the "exact
division" that reading rests on is exact for arithmetic reasons and carries no
information.

## `gen_prom_b_dsp_value_lists.py`
**"What are the 7,601 bytes at 0xF157A8, and how is a record reached?"** 18
arrays of interpreter-B display-list records, each followed immediately by the
string table its records index; the 35 objects tile the range with no gap and no
overlap.

    python3 notes/gen_prom_b_dsp_value_lists.py --selftest    # 87 checks
    python3 notes/gen_prom_b_dsp_value_lists.py --asm

The structural point is the **15-byte stride**: `DisplayListB_RunOne_Stack`
(0xF3183D) sets XIX = XIY+1, so interpreter B draws exactly ONE record, records
are addressed individually as `base + 15*line`, and every record shorter than 15
bytes is padded with 0xFF — which the walk asserts byte for byte.
⚠ Entry counts come from each table's EXTENT, never from its record's mask:
0xF15A7C's mask allows 32 and the table is 27.

## `prom_b_screen_arrays.py`
**"Is 0xF131E4 one 128-entry dispatch table, or four parallel 32-entry arrays?"**
Four arrays. Each base has exactly one reference in the whole three-image set;
each array's rows 0 and 31 hold its own default; and the only indexer of
0xF131E4 cannot produce an index above 0x1E.

    python3 notes/prom_b_screen_arrays.py            # 22 checks

Written because `prom_b/wsa1_prom_b.s` carried the range as one table headed
"the entries are ENTRY POINTS", and entries 64..95 point at display-list DATA.

## `prom_b_span_frontier.py` (round 6)
**"Which `.incbin` SPAN should be converted next?"** `prom_b_module_frontier.py`
ranks THUNK RUNS and is blind to a module entered by DIRECT CALL. This ranks the
spans by how many DISTINCT addresses inside them an ALREADY-TRANSCRIBED
instruction calls or jumps to.

    python3 notes/prom_b_span_frontier.py            # ranked by bytes
    python3 notes/prom_b_span_frontier.py --by proven
    python3 notes/prom_b_span_frontier.py --selftest

It is what chose round 6's span: 76 proven targets against the thunk frontier's
thirteenth place.

## `prom_b_instr_census.py` (round 6)
**"How many INSTRUCTIONS are in a converted block — as against BYTES?"** The
round-2 audit's finding F2 was a byte total worn as an instruction count. This
walks every `code` segment of a block's frozen LAYOUT and cross-checks the decoded
starts against the `.s`'s own `; ADDR` comments; the two sets must be EQUAL.

    python3 notes/prom_b_instr_census.py --last      # every known block
    python3 notes/prom_b_instr_census.py --module f0ea9f --last

⚠ It counts a `.byte`-emitted instruction as an instruction, which a line-shape
split does not: 392 of the 0xF0EA9F block's 5,067 are of that kind.

## `prom_b_f6d002_layout.py` + `gen_prom_b_f6d002_module.py` (round 6)
**The 0xF6D002-0xF77FFF span, 44,189 substantive bytes.** The layout module is
`prom_b_f0ea9f_layout.py` with LO/HI changed and NOTHING else — round 5's rule set
transferring to a new module unchanged is round 6's methodological result. It also
re-implements `--provenance` to walk instruction BOUNDARIES rather than every code
byte, which is the difference between a report that finishes and one that does not.

    python3 notes/prom_b_f6d002_layout.py --all
    python3 notes/prom_b_f6d002_layout.py --provenance
    python3 notes/gen_prom_b_f6d002_module.py --checks   # REFUSES to emit on fail

⚠ The emitter's BYTEMAP block had to be rewritten: `build()` paints adjacent byte
maps one colour, so six of this block's fourteen byte-map segments hold 2 or 4
maps, and round 5's "the N non-0xFF bytes ascend strictly, 0xAA to 0xBB" would be
false for them. The check caught it before a line was emitted.

## `prom_b_f6d002_touches.py` (round 6)
**"What does the round-6 block touch, and what does it demonstrably NOT
touch?"** Two negative claims, both checked over the transcription rather than
the raw bytes: zero operands name the panel change-mask shadow 0x2B20-0x2B3F
(which is why round 6 does not close emulation gap O), and every absolute operand
that is neither RAM nor an address in the images lies in CPU 1 work DRAM.

    python3 notes/prom_b_f6d002_touches.py
    python3 notes/prom_b_f6d002_touches.py --list
    python3 notes/prom_b_f6d002_touches.py --top

It refuses to report a vacuous zero: if the block is not converted it says so and
exits non-zero.

## `prom_b_smf_reader.py` (round 6)
**"Is 0xF6F530 a Standard MIDI File reader?"** Yes, and this is the evidence: 40
checks, every instruction re-decoded from the ROM — the `MThd`/`MTrk` tags at
0xF6F528, the 1,024-byte window at 0x60A700-0x60AAFF with its cursor in (0x1088),
the six header bytes as big-endian pairs in (0x1078)-(0x107D), and all three of the
specification's own rejections (SMPTE division, division 0, format > 1).

    python3 notes/prom_b_smf_reader.py --list

It also states what is NOT established: where the bytes come from, and whose
buffer 0x60A700 is.

## `prom_b_f0ea9f_layout.py` (round 5)
**"Which bytes of 0xF0EA9F-0xF13D33 are code — and WHY is each one code?"**
It is `prom_b_f65000_layout.py` plus four corrections, each with its own null.

    python3 notes/prom_b_f0ea9f_layout.py --all           # layout + tables + provenance
    python3 notes/prom_b_f0ea9f_layout.py --null-accept   # the 13.9% one
    python3 notes/prom_b_f0ea9f_layout.py --null-stride   # 0 of 33 proven tables
    python3 notes/prom_b_f0ea9f_layout.py --null-ptr      # content rules on proven code
    python3 notes/prom_b_f0ea9f_layout.py --provenance    # grade every code segment

⚠⚠ **`--null-accept` is the one to read.** Round 4's rule for promoting an
unreached run to code accepts **13.9%** of record-aligned chunks of PROVEN
display-list data (39,329 bytes) as code. Requiring the decode to end in a flow
end takes that to 1 of 1,884. That correction is retro-active: it moved four
runs (76 bytes) of the already-emitted 0xF65000 module from instructions to
`.byte`, `0xF6A475` (40 bytes, a lookup table) among them. See
`FINDINGS-prom_b-f0ea9f-module.md` §2.4.

## `gen_prom_b_f0ea9f_module.py` (round 5)
**"…and what is the assembly for it?"** Reuses `gen_prom_b_f65000_module.py`'s
emitter helpers by swapping that module's globals, so there is one copy of the
transcription/label/reference machinery, not two.

    python3 notes/gen_prom_b_f0ea9f_module.py --checks
    python3 notes/gen_prom_b_f0ea9f_module.py --tables    # every table, with its KIND

## `gen_prom_b_effect_tables.py` (round 5)
**"What does the WSA1's DSP effect section offer?"** 0xF147AC is 128 entries of
16 characters; **56 are real effect names and 72 are the `----------`
placeholder.** 0xF15024 is the parameter labels.

    python3 notes/gen_prom_b_effect_tables.py --checks   # 13 checks
    python3 notes/gen_prom_b_effect_tables.py --names    # the 56, with slot numbers
    python3 notes/gen_prom_b_effect_tables.py --stride   # why the stride is 16

"Nothing reads it" is a CHECK here, not a shrug: it decodes backwards from every
4-byte window in prom_a+prom_b that spells the address and asserts that none is
an instruction operand.

## `prom_b_dlb_record_arrays.py` (round 5)
**"How can the region above 0xF13D34 be framed at all?"** Not by
`prom_b_display_lists.py` — those lists have no `ld XIY,start / ld XIX,end` call
site. They are arrays of interpreter-B records, pushed ONE AT A TIME
(`push XBC / call 0xf42e0c` = `DisplayListB_RunOne_Stack`).

    python3 notes/prom_b_dlb_record_arrays.py

0xF157A8 walks as 16 records and 0xF15820 as 8, both ending at 0xF15898, and the
bases differ by 8 × 15 — two entry points into one array. That is the round-6
framing rule.

## `prom_b_f0ea9f_header_audit.py` (round 5)
**"Do the emitted headers agree with the rows under them?"** Same job as
`prom_b_f65000_header_audit.py`, but it reads `prom_b/wsa1_prom_b.s` itself, so
it also catches a splice that dropped or duplicated an object.

    python3 notes/prom_b_f0ea9f_header_audit.py
    python3 notes/prom_b_f0ea9f_header_audit.py --last

`--last` names the block's final data object, so "the audit passed" cannot mean
"the audit stopped early".

## `prom_b_round5_citations.py` (round 5)
**"Does every instruction QUOTED in round 5's findings note actually decode
there?"** The tree's standing defect list includes "~20 call sites cited one byte
past the instruction", and the first draft of that note did exactly that
(`0xF105F0` for an instruction at `0xF1060F`).

    python3 notes/prom_b_round5_citations.py --list

It PARSES the note's own fenced code blocks, so the note and the checker cannot
drift apart, and it fails loudly if it finds no citations at all rather than
passing vacuously.

## `prom_b_round5_frontier_delta.py` (round 5)
**"Did round 5 retire exactly the two runs it claims?"** Same shape as
`prom_b_f65000_frontier_delta.py`: BEFORE is reconstructed from the file's own
current `.incbin` set plus the converted range.

    python3 notes/prom_b_round5_frontier_delta.py

Round 3 makes it worse again in the same way: **21,962 substantive bytes** of
`prom_b/wsa1_prom_b.s` (0xF47800-0xF4EFFF) were emitted by
`gen_prom_b_f47800_module.py`, which lives only in the working tree, and the
emitted text carries a `REGENERATE:` line naming it.

Round 2 makes this worse rather than better, and says so: 34,777 substantive
bytes of `prom_b/wsa1_prom_b.s` were emitted by two generators that live only in
the working tree, and the emitted text carries `REGENERATE:` lines naming them.
A `git clean -fd` would leave the .s standing and the sentence "regenerate with
this script" pointing at nothing.

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
    python3 notes/prom_b_evidence_audit.py --scopes
    python3 notes/prom_b_evidence_audit.py --selftest

Round-1 finding F16 reported "prom_b 50/89" by grepping for the word
"Evidence" in the comment block directly above each label, and flagged in the
same breath that the number over-states the problem. It does. This grades into
four buckets instead of two — BACKED (own Evidence line), GROUP (no header of
its own, but the nearest preceding header names this label *and* carries an
Evidence line), SECTION (only the `; ===` banner does — weak, because the
banner is not about this label), UNBACKED (none) — so the honest figure can be
quoted. Of the labels new since `HEAD` in round 1 the split was
**39 / 21 / 25 / 4**, i.e. 29 owed evidence, not 50.

⚠ **CORRECTED 2026-08-25 (round-3 lane), round-2 audit finding F10.** The
sentence that stood here said "After round 2: **62 / 27 / 0 / 0**", with no
scope on it. Two things were wrong with it. First the scope: a `0` in the
UNBACKED column of `--since HEAD` says nothing about the image, and the audit
was right to flag that the headline reads image-wide when it is not. Second the
figures themselves do not reproduce — nothing in this tree prints 62 / 27.
What `python3 notes/prom_b_evidence_audit.py --scopes` prints today is:

| scope | labels | BACKED | GROUP | SECTION (weak) | UNBACKED |
|---|---|---|---|---|---|
| image-wide (`--all`) | **628** | 169 | 27 | 317 | **115** |
| new since `HEAD` | **40** | 40 | 0 | 0 | 0 |

`HEAD` itself has 588 semantic labels, the worktree 628, and no name was
removed — so 40, not 89, is the round-2+3 delta (the table read 618 / 30 before
round 3's ten data labels were added; UNBACKED did not move, because all ten
carry their own Evidence line). The reason a round that
converted 34,777 bytes adds only 30 *semantic* names is that the module
generators emit `sub_XXXXXX` for anything whose purpose is not established, and
`sub_XXXXXX` is deliberately not a semantic label. **Quote the image-wide row
unless the sentence says otherwise; 115 prom_b labels still owe an Evidence
line: 72 `DL_*` display-list labels, 32 `Table_*`, 2 `DispatchTable_*` and 9
others, i.e. 104 of the 115 are bulk names emitted before this rule existed.**
The breakdown is one pipeline, and it sums to 115:

    python3 notes/prom_b_evidence_audit.py --all | grep '^  UNBACKED ' \
      | grep -v 'none of the above' | awk '{print $2}' \
      | sed -E 's/_?[0-9A-F]{6}.*//' | sort | uniq -c | sort -rn

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

## `prom_b_module_frontier.py`
**"Which whole thunk MODULE should be converted next?"** `prom_b_call_graph.py`
ranks individual SLOTS and `prom_b_thunk_modules.py` groups slots into RUNS;
neither says which run is the best next unit of work, because a run's value
depends on how much of its target range is still `.incbin`. This joins them.

    python3 notes/prom_b_module_frontier.py            # ranked runs
    python3 notes/prom_b_module_frontier.py --n 25
    python3 notes/prom_b_module_frontier.py --at 0xF428B0
    python3 notes/prom_b_module_frontier.py --selftest

Ranks by **contiguous** unconverted target extent — a run whose targets straddle
several `.incbin` spans is fragmented work — and reports slots/unconverted/extent/
one-span-extent/span-count/summed reference bound per run.

`--selftest` asserts on the LAST slot of the top run (raw `jp` opcode, target and
`.incbin` membership, all re-derived from the ROM), two ordering invariants, that
the three runs this tree has already converted (`T_F42770` block store,
`T_F42880`/`T_F428B0` allocator and song-store commands) are ABSENT, and that a
known-unconverted run (`T_F40C50`) is PRESENT.
⚠ Its first draft hard-coded the then-top run and would have begun FAILING the
moment that run was converted — a self-test that breaks on success is the
opposite of one. **It then did it again, and round 3 caught it:** the
"unconverted run T_F40C50 is present" row named a run round 3 converted, and the
selftest failed on its own success. Fixed 2026-08-25 — the presence check now
takes the LAST `jp` slot in table order whose target is still inside an
`.incbin` and asserts survey() reports the run owning it, so nothing in it names
a run that conversion can remove except the absent-list, which is meant to grow
(and did: round 3's eight runs are in it).

⚠ The reference counts are `prom_b_call_graph.py`'s byte-window upper bound and
rank only. The "extent" of a run is max-min over its own targets: it is what the
run's slots NAME, not a measurement of where a module's code ends.

## `gen_prom_b_songstore_module.py`
**"…and what is the assembly for the block-store ALLOCATOR and the 132-slot
command module at 0xF7A400-0xF7CFFF?"** This is the emitter whose output is in
the .s.

    python3 notes/gen_prom_b_songstore_module.py
    python3 notes/gen_prom_b_songstore_module.py --layout
    python3 notes/gen_prom_b_songstore_module.py --checks

Code runs go through `llvm_roundtrip_autoforce.py`; the nine data objects are
`.byte`/`.long` with their structure re-asserted at emit time; the two `0x0E`
runs are `.fill`. It REFUSES TO EMIT if a check fails. Every list in every one of
its 214 headers is computed — thunk slots and their reference bounds, in-module
call sites, dispatch-table membership, the RAM addresses each routine spells, and
the routines it calls. The veneer headers are computed too: `veneer_of()` reads
the `jr` and the `calr`/`ret` it lands on out of the transcription rather than
being told what they are.

Three things it caught that a reading would not have:
* the first layout gave all six pointer tables **5** entries. The assertion "the
  word one entry past the table must not be an address in this module" failed on
  `0xF7C94C` and `0xF7C998`, which have **6**. Their four extra pointer bytes
  would otherwise have been decoded as an instruction.
* the entry count now comes from each reader's own `cp L,<max>`, read back out of
  the proven transcription by `text_at()` — never from dividing a byte extent.
* the `FORCE` label set (three addresses that start a routine but are neither a
  thunk target nor a call target) was built, validated by `checks()`, and then
  never merged into `labels()` — so `BStore_LatchHeapBase`'s curated header was
  silently dropped from the output while every check still passed. `checks()`
  now follows each `FORCE` and `CURATED` address through to the label set, not
  just to the boundary test. **A check that stops short of the output cannot
  fail on the mistake that actually happens.**

## `prom_b_songstore_checks.py`
**"Are the numbers in the 0xF7A400-0xF7CFFF headers, and the two CORRECTIONS
this round makes to older documents, actually true of the ROM?"**

    python3 notes/prom_b_songstore_checks.py
    python3 notes/prom_b_songstore_checks.py --arrays

**23** PASS/FAIL rows (the round report said 21; corrected 2026-08-25 by counting
the script's own output): the five `ld BC,0x0011` init loops (base, count, stride and
extent all re-read, never typed twice), the 17-entry abutment that corrects
`FINDINGS-memory-map.md`'s "16 saved cursors", the directory's 17×3 that closes
`FINDINGS-prom_b-block-store.md`'s open question, the byte diff behind the
borrowed name `BStore_SeekBlock_Alloc` (18 differing of the first 20), and both
padding runs.

⚠ It records one thing rather than hiding it: `0xF7CE67` **is** `0x0E`, because
`ret` **is** `0x0E`. Where the last routine stops and the padding starts is a
READING, not a measurement — the bytes cannot tell them apart. The transcription
takes that byte as the `ret` closing the routine that ends `djnz C,0xf7ce3b`,
because a routine reached by `call` must return.

Verified falsifiable: perturbing the array stride, the differing-byte total and
the initialised value each produce exactly one FAIL row and a non-zero exit.

    python3 notes/prom_b_songstore_checks.py --banks

⚠ **Added 2026-08-25, and read this before citing the file for anything else.**
The audit of 2026-08-24 (F9) found the round report naming this script for the
`SongStore_BitMask32`, dispatch-table and ten-banks claims. It contained none of
them. Two live in the module's EMITTER (`gen_prom_b_songstore_module.py --checks`,
**88** rows, which refuses to emit if one fails); the third — *"the ten banks are
the ten songs"* — was checked by **nothing**, and is now the 13 rows of `--banks`:
the four-instruction assignment chain at `0xF7AA35`, this module's two bounds on
`(0x0E02)`, prom_a's `ld A,(0x360a)`+`cp` pairs at `0xF8143B`/`0xF8143F` and
`0xF814CE`/`0xF814D2`, and the range 0..9 that "ten" is derived from. The
display-list step is deliberately NOT checked: nearness in the code is not a byte
fact, and asserting it would dress the argument's weak link as its strong one.

## `gen_prom_b_f5bbe7_module.py`
**"What is the assembly for 0xF5BBE7-0xF62BFF — the 96-step rounding maps and the
code that uses them?"** New 2026-08-25. This is the emitter whose output is in
the .s, covering the whole span (28,697 bytes) in one piece and closing it.

    python3 notes/gen_prom_b_f5bbe7_module.py            # the assembly
    python3 notes/gen_prom_b_f5bbe7_module.py --layout   # the 11-segment table
    python3 notes/gen_prom_b_f5bbe7_module.py --checks   # 56 rows; it REFUSES to emit if one fails
    python3 notes/gen_prom_b_f5bbe7_module.py --maps     # the seven maps, run-length encoded

The seven 96-entry maps are decoded as `entry[k] = g * round(k / g)` with 96
written as 0x7F; **g is read off each map's own distinct values, not typed**, and
all 96 entries are then compared with the formula byte for byte. The 36-byte
boundary lists are *derived* from those grids and then compared with the ROM, and
the twelve sites that address the island all land on group starts — a check
rather than a fit, because the sizes were derived before the addresses were read.
⚠ One anomaly is asserted rather than smoothed: `RoundMap_12` entries 66..77 read
73 where the formula gives 72.

⚠ Read the sufficiency caveat in `FINDINGS-prom_b-round-maps.md` before reusing
the recipe: "every thunk target is an instruction boundary" does **not** catch a
code segment that starts one byte late, because the decode resynchronises. The
label-emittability checks are what catch it.

## `gen_prom_b_f44018_module.py`
**"What is the assembly for 0xF44018-0xF477FF — the module that opens right after
the thunk table?"** New 2026-08-25. 14,312 bytes: 128 routines, `Dispatch_3629`
(5 pointers, two of them dead) and the 161-byte `WorkspaceDefaults` that seeds the
`0x00603400` workspace.

    python3 notes/gen_prom_b_f44018_module.py            # the assembly
    python3 notes/gen_prom_b_f44018_module.py --checks   # 30 rows; it REFUSES to emit if one fails
    python3 notes/gen_prom_b_f44018_module.py --copies   # every `ld XIX,0x00F460xx` site

⚠ `WorkspaceDefaults` is emitted as ONE labelled run with its partition stated as
unknown. Only two of its blocks are established (8 bytes each, one a byte loop and
one a **word** loop); an automated read of the loops gave nine for the second, and
shipping a partition a mechanical reader already got wrong is exactly what this
tree's error history is made of.

## `prom_b_round2_frontier_delta.py`
**"Did the frontier fall by exactly what round 2 converted — in BOTH units?"**
Yes: 364 → 283 **slots** and 356 → 277 **distinct targets**, i.e. 81 slots / 79
targets retired, which is 17 + 64 slots and 17 + 62 targets.

    python3 notes/prom_b_round2_frontier_delta.py

It reconstructs the before-state by adding each converted span back to the `.s`'s
own `.incbin` set, so nothing is quoted from an earlier printout.

⚠ It exists because `prom_b_call_graph.py`'s header said *"targets"* until
2026-08-25 while it counted one row per **slot**. The label is fixed; the units
differ by 2 for `0xF44018-0xF477FF` and by 0 for `0xF5BBE7-0xF62BFF`, so the
distinction is invisible on one span and off-by-two on the other.

## `prom_b_audit_callsites.py`
**"Does every address a prom_b header CITES really start an instruction that
reaches the object?"** New 2026-08-25. This is the tool prom_b did not have, and
whose absence is why finding F2 shipped: twelve header lines named the OPERAND of
`ld XDE,0x00F7C6E6` instead of the instruction at `0xF7C6D9`, and the emitter's
own check hard-coded the same wrong offset so it could never disagree.

    make all                                     # it reads the ELF the gate builds
    python3 notes/prom_b_audit_callsites.py
    python3 notes/prom_b_audit_callsites.py --quiet      # only rows that did not check out
    python3 notes/prom_b_audit_callsites.py --evidence   # also audit `Evidence:` lines
    python3 notes/prom_b_audit_callsites.py --selftest

Three things make it stricter than prom_c's equivalent: the object's address
comes from `llvm-nm` on the linked ELF (so DATA labels work — the labels F2 was
about), a miss triggers a backwards decode that PRINTS the address the header
should have used, and it follows the 0xF40000 thunk table. Current state: **693
citations, 669 resolved, 24 residual**, and **0 off-by rows in either mode**. The
24 residuals are enumerated in the script's docstring and were each read by hand;
20 of them are one shape — a header citing the instruction that CONSUMES a table
rather than the one that names its address, which reaches the object through a
register and so cannot be bound by any test here. A twenty-fifth row is a new
claim, not noise.

⚠ Its `--selftest` includes a structural check that the off-by-N scan precedes
every permissive verdict. That is not decoration: two revisions of the file put a
data check first, and since the operand of `ld XDE,0x00F7C6E6` IS the word
`0x00F7C6E6`, the tool called the defect a legitimate pointer and went blind to
its own reason for existing.

## `gen_prom_b_f47800_module.py`
**"What is the assembly for 0xF47800-0xF4EFFF — the eight modules at the head of
the 0x047800 `.incbin` span?"** New 2026-08-25, round 3. 30,720 bytes in one
contiguous block: 21,962 substantive (20,777 code + 1,185 data) and 8,758 of
`ret` padding as `.fill`.

    python3 notes/gen_prom_b_f47800_module.py            # the assembly
    python3 notes/gen_prom_b_f47800_module.py --layout   # the 26-segment table
    python3 notes/gen_prom_b_f47800_module.py --checks   # 90 rows; it REFUSES to emit if one fails
    python3 notes/gen_prom_b_f47800_module.py --records  # the 81 DL_F4C000 records

Chosen with the frontier tools: of the eleven unconverted thunk slots at a
reference bound of x13 or more, **eight** pointed into this one span. It retires
**92 slots / 92 targets**. Ten data islands are decoded, each with its extent
pinned by something outside itself — a reader instruction, a thunk target, or the
display list's own record framing. Everything else is `sub_XXXXXX` with a
computed header; the block claims no purpose for any of the eight modules.

⚠ **Read this before reusing the recipe.** The first draft computed each data
island's reader as *(32-bit reference) − 1*. That is right for the one-byte
opcode `ld XIX,imm32` and wrong for the two-byte `add XWA,imm32`, and
`prom_b_audit_callsites.py` returned two OFF-BY-2 rows for it — the same family
as round-2 finding F2. `reader()` now walks the proven transcription and returns
whichever instruction actually contains the reference; `checks()` asserts, per
island, that the instruction's mnemonic ends in that island's own address and
that the header cites the instruction, not *ref−1*. A third flagged row
(`BitWeight_F4E5FC`) was a correct address phrased so the auditor's deliberately
narrow operand rule could not see the disclosure; the phrasing was fixed rather
than the rule widened.

⚠ It also typed one thunk-slot number, `T_F40B54`, for the slot that targets
0xF48C1A. The real slot is **T_F43430**; T_F40B54 targets 0xF483B2. The header
now reads the slot out of `thunks()`, and a `checks()` row asserts the slot set
of 0xF48C1A is exactly {T_F43430}. The lesson is the same one this tree keeps
relearning: **a name typed next to an address is not evidence, even when the
address is right.**

Findings: `notes/FINDINGS-prom_b-f47800-modules.md`.

## `prom_b_round3_frontier_delta.py`
**"Did the frontier fall by exactly what round 3 converted — in BOTH units?"**
Yes: 283 → 191 **slots** and 277 → 185 **distinct targets**, i.e. 92 and 92.

    python3 notes/prom_b_round3_frontier_delta.py

Reconstructs the before-state by adding the converted span back to the `.s`'s own
`.incbin` set, so nothing is quoted from an earlier printout. It also re-derives
the block header's "most referenced" claim at a **threshold** (eleven slots at
x13 or more, eight of them in the span) rather than as "N of the top ten", and
asserts the threshold is tie-free — two slots tie at x13, two at x14 and two at
x15, so a top-N phrasing would depend on how the sort broke the ties.

⚠ Its round-2 sibling `prom_b_round2_frontier_delta.py` had hard-coded its "NOW"
rows to 283 / 277 and would have started FAILING the moment round 3 converted
anything — a check that breaks on success. It now carries a `LATER` list holding
round 3's span, adds it back before doing round 2's arithmetic, and goes on
asserting the state round 2 actually left behind. **A round 4 adds its own span
to both files' `LATER` lists.**

## `prom_b_f65000_trace.py`
**"Which bytes of prom_b 0xF65000-0xF6F000 are CODE?"** `prom_b_module_trace.py`
reaches only **44.7%** of it, because the block dispatches through POINTER
TABLES and a recursive descent cannot follow one. This alternates descent with a
scan of the unreached runs for two table shapes, to a fixpoint.

    python3 notes/prom_b_f65000_trace.py                 # the residue
    python3 notes/prom_b_f65000_trace.py --tables        # the tables it followed
    python3 notes/prom_b_f65000_trace.py --anchor        # per-run criteria
    python3 notes/prom_b_f65000_trace.py --discriminate  # do the criteria WORK?
    python3 notes/prom_b_f65000_trace.py --accept        # the fixpoint

⚠ **`--discriminate` is the important one, and it is a REFUTATION.** It grades
the 98 unreached runs by two candidate code tests. "A linear decode from the run
start lands exactly on the next proven instruction boundary" passes **89 of 98**
— including 12 of 12 pointer tables and 3 of 3 strings. It cannot fail and it is
not used. `selfconsistent()` (decode consumes the run exactly · no undefined
opcode · every relative branch hits an instruction boundary) passes 57, rejects
every pointer table and every string, and accepts all 19 padding runs. The dead
criterion is kept in the file, named and labelled, so nobody re-invents it.

## `prom_b_f65000_layout.py`
**"Which bytes of 0xF65000-0xF6D001 are code, which are tables, which are
padding?"** Five CONTENT rules run first and become BARRIERS the code walk may
not enter, then the descent fills in the rest.

    python3 notes/prom_b_f65000_layout.py             # the LAYOUT
    python3 notes/prom_b_f65000_layout.py --null      # the calibration
    python3 notes/prom_b_f65000_layout.py --barrier   # what the barrier buys
    python3 notes/prom_b_f65000_layout.py --conflicts # must be zero
    python3 notes/prom_b_f65000_layout.py --residue   # what no rule matched
    python3 notes/prom_b_f65000_layout.py --python    # the LAYOUT literal

The NULL is the point. Every rule is run over **every maximal run of proven
instruction text in `prom_b/wsa1_prom_b.s`** — 2,948 runs, 54,814 bytes, all of
it byte-gate-proven code — and a rule that fires there is a false positive. All
five fire zero times. `--null` also prints the two ASCII thresholds that were
REJECTED (7 false positives at 8 bytes, 3 at 10), so the choice of 20 reads as a
measurement. ⚠ Its cost is real: the 9-byte `VOLUME = ` at 0xF67DC6 is not
promoted and stays inside a `.byte` run.

`--barrier` answers "is the barrier cosmetic?" — no: without it the same descent
claims 676 bytes that a content rule frames, including whole 32-entry pointer
tables at 0xF6828B and 0xF685C1.

## `gen_prom_b_f65000_module.py`
**"…and what is the assembly for 0xF65000-0xF6D001?"** The emitter whose output
is in the `.s`.

    python3 notes/gen_prom_b_f65000_module.py
    python3 notes/gen_prom_b_f65000_module.py --layout
    python3 notes/gen_prom_b_f65000_module.py --checks   # refuses to emit on fail
    python3 notes/gen_prom_b_f65000_module.py --tables
    python3 notes/gen_prom_b_f65000_module.py --stats    # the 603 table entries

Its strongest check is that the LAYOUT literal **equals what
`prom_b_f65000_layout.py` derives, segment for segment**, so the table in the
file is a record of a measurement rather than a typed guess. Every number in the
banner is computed at emit time, including the segment counts, the heaviest
operands and the barrier figures.

## `prom_b_f65000_header_audit.py`
**"Do the numbers in the emitted headers agree with the rows under them?"**

    python3 notes/prom_b_f65000_header_audit.py
    python3 notes/prom_b_f65000_header_audit.py --last

⚠ It exists because of a real defect. The first draft of the emitter subtracted
the IMAGE-WIDE default thunk slot `0x00F42C70` when it meant the MODULE's own
`ret` stub `0x00F675CB`, and printed the wrong "distinct other targets" count in
**every one** of the 31 dispatch-table headers. Gate-clean. This re-reads the
`.long` / `.byte` / `.ascii` rows and the ROM and re-checks each header's own
arithmetic, plus every `T_xxxxxx` a routine header names (the slot must really
hold `jp <that address>`) and every in-module caller it lists. 356 objects, 0
failures. Tested on the last element with `--last`.

⚠ Its own first draft was wrong too, in the same family: the body collector ran
past the blank line after a data object and swallowed the `.byte` demotion rows
of the code below, reporting a 32-byte index map as 35. Both the fix and the
reason are in the file.

## `prom_b_f65000_frontier_delta.py`
**"Did round 4 retire exactly the four thunk runs it claims?"** Yes — and the
BEFORE figure is reconstructed from the file's own current `.incbin` set plus the
converted range, so it stays checkable instead of being a number copied out of a
session log.

    python3 notes/prom_b_f65000_frontier_delta.py
    python3 notes/prom_b_f65000_frontier_delta.py --runs

⚠ Its run TOTALS are not `prom_b_module_frontier.py`'s (19→15 against 20→16):
the tool groups a run across a leading non-`jp` slot and this does not. The four
run NAMES are identical in both, and the docstring says so.

## `prom_b_sc1_serial_regs.py`
**"What is CPU 1's SC1 actually programmed with?"** The twelve BR1CR immediates
are `0x22` ×4, `0x24` ×5, `0x28` ×3 — one prescaler tap, three divisors — and
SC1MOD is written whole exactly once, with **0x00**, which is I/O-interface
(clocked synchronous) mode, not a UART.

    python3 notes/prom_b_sc1_serial_regs.py
    python3 notes/prom_b_sc1_serial_regs.py --sites

Closes entries **E.1** and **E.2** of
`kn7000_mame/notes/WSA1-EMULATION-DISASM-GAPS.md`. It reads the PROVEN
transcription, not the raw bytes, because `08 57 nn` occurs inside data as
readily as inside code; and it prints how many instruction lines of each image
are transcribed, so the bound ("a write inside an `.incbin` is invisible here")
is visible rather than implied. Four assertions, non-zero exit on failure.
⚠ It does **not** give an absolute bit rate: that needs the divide ratio of
prescaler tap 0b10, which nothing in this tree has established, and MAME's
`tmp95c061` prescaler is documented as 16x slow so it cannot supply it.

## `prom_b_dl_stack_sites.py` (round 8)
**"Which display lists are entered with their arguments ON THE STACK?"**
`scripts/analysis/prom_b_display_lists.py` knows one shape,
`ld XIY / ld XIX / call 0xF417F0`, and **zero** sites of that shape point into
0xF58000-0xF59C5A. Every list there is entered through a stack veneer — prom_a
0xFF75D3 / 0xFF75EF, or prom_b's `DisplayList_Run_Stack` / `DisplayListB_Run_Stack`
through `lda XIX,T_F42E00` + `jp (XIX)`.

    python3 notes/prom_b_dl_stack_sites.py             # sites and spans
    python3 notes/prom_b_dl_stack_sites.py --global    # ... and what it finds elsewhere
    python3 notes/prom_b_dl_stack_sites.py --selftest  # 23 checks

109 confirmed sites, 61 spans, **0 unresolved push pairs**, all 61 frame. The
census is anchored on the CALL, not on the operand pattern: the pattern finds 33
sites and the call finds 35, because two have a `cps / jr Z` between the last
push and the call. The A/B split is cross-checked against the two interpreters'
opcode bounds rather than asserted, and **every site address is checked to START
an instruction in `prom_a/wsa1_prom_a.s`** — the defect the round-1 audit's F2
was about, which this round's own first draft committed eleven more times.

## `gen_prom_b_f58000_module.py` (round 8)
**"What is the 10,929-byte `.incbin` at 0xF57D4F?"** The DISK and FILE menus:
12 display lists (431 records), 16 runs entered one record at a time (45
records), 18 operand and string tables, 3 objects of unclaimed bytes, and two
pads.

    python3 notes/gen_prom_b_f58000_module.py --map        # the segment map
    python3 notes/gen_prom_b_f58000_module.py --asm        # the assembly
    python3 notes/gen_prom_b_f58000_module.py --selftest   # 73 checks

The check that cannot lie is that the emitted directives are **reassembled with
this tree's own llvm-mc and compared to the ROM's 10,929 bytes**. ⚠ Table entry
counts come from the EXTENT, never from the naming record's AND mask: measured
over all eighteen the mask disagrees ten times.

## `prom_b_diskmenu_entrypoint.py` (round 8)
**"What draws the DISK menu, and can it be followed back to a button?"**
Backwards from the display list to prom_a 0xFF42CD (which nothing calls), to the
single thunk that names it, to entry **96** of a 256-entry table at prom_a
0xF86EC1 — and it stops there, because what indexes that table is inside prom_a's
`.incbin`.

    python3 notes/prom_b_diskmenu_entrypoint.py        # 13 checks

Narrows gap V of `kn7000_mame/notes/WSA1-EMULATION-DISASM-GAPS.md` from a
subsystem to one table lookup. It does **not** close it.
