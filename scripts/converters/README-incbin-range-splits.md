# Converting code that lives inside an `.incbin` ROM slice

`scripts/converters/convert_reachable_ranges.py` — the `.incbin` path

## The question it answers

`scripts/analysis/README-rewrite-refusals.md` measured the converter's stall and found that
**90% of it was invisible**: 132 of the 159 ranges it accepted never reached `rewrite()` or were
declined without a counter. The largest single group was

```
103 range(s)   8,828 bytes   entry is in no indexed .byte block
 82 of them    7,101 bytes   because the entry is inside an .incbin ROM SLICE
```

and the README's verdict for that group was: *"the `.incbin` bucket needs its own converter;
nothing here fixes it."* This is that converter. It splits the directive:

```
FDC_CmdRecalibrate:
-	.incbin "includes/romslices/v7_transplant_FDC_CmdRecalibrate.bin"
+	.incbin "includes/romslices/v7_transplant_FDC_CmdRecalibrate_head.bin"
+	ldb_d8 a, (0x899a)
+	cpda8 a, (0x8a68)
+	ret Z
+	.incbin "includes/romslices/v7_transplant_FDC_CmdRecalibrate_tail.bin"
```

`convert_v7_ptr_tables.py` already did this for pointer tables and is the working model for the
mechanics — residue slices, and the `own_label` rule.

## Result (measured 2026-08-22, at the fixpoint reached by `314a46f`)

```
converted 64 range(s), 6,695 bytes  (.byte runs 0/0, .incbin slices 64/6,695)
29 .incbin slices split; 44 new residue .bin files
CODE 600,755 -> 607,450   (+6,695)      scripts/analysis/v7_code_delta_vs_head.py
gate  make clean-all && make all -> Similarity: 100.00% on all NINE targets
```

The converter's own total and the L1 territory gain are **the same number**, which is the check
that makes either worth quoting: an earlier run printed 6,711 because it counted a range it had
dropped as overlapping, and the 16-byte disagreement is what exposed it.

What is left in the bucket, all of it counted:

| refused | bytes | why |
|---:|---:|---|
| 20 ranges | 1,722 | entry in no indexed `.byte` block **and** in no located `.incbin` |
| 5 ranges | 70 | decode reads as table data (below) |
| 1 slice | 48 | the `.incbin` is `generated/`, not a committed romslice |
| 1 range | 115 | starts in a slice but runs past its end |
| 1 range | 16 | overlaps an earlier range in the same slice |

## How a slice is located: ask the assembler

An `.incbin`'s address cannot be read off the source line. `probe_rewrite_refusals.py` searched
the ROM for each blob's content, which places only **279 of 322** — a blob that repeats, or that
is included twice, is ambiguous, and guessing is exactly what must not happen here.

`incbin_index()` instead copies `v7/maincpu`, writes a unique `__incloc_N:` label immediately
above **every** directive, assembles and links the copy with the real `maincpu.ld`, and reads the
addresses out with `llvm-nm`. That is the address the real build gives, by construction:
**311 of 312 sites located, 311/311 ROM-verified** (`blob == ROM[addr:addr+len]`); the one site the
linker does not report is dropped. The repo is never written — the labels go into the copy.

## Why byte-identity is structural here, not a hope

The residues are cut from **the blob itself** (`blob[:lead]`, `blob[lead+span:]`) and the converted
span is checked against the blob at the same offset before anything is emitted, so

    head + span + … + tail == blob

is asserted in `rewrite_incbin()` on every site. A wrong location cannot corrupt the ROM; it could
only put the instructions in a place where they mean nothing, and the offset check refuses that
too. What the `make clean-all && make all` gate still settles is what it settles for every other
converted range: the link-time bytes of symbolic operands.

## The two label rules, and why they differ

* a label **on the directive's own line** (`CharMap_ValueData_B:\t.incbin "…"`) names the first
  byte of the blob and is destroyed by replacing the line — it must be re-emitted, or the link
  fails with `undefined symbol`;
* a label on an **earlier** line is still defined after the replacement and must **not** be
  re-emitted, or it is defined twice.

Same rule and same reason as `convert_v7_ptr_tables.py`. `scripts/analysis/v7_unreferenced_labels_are_live.py`
is why no label is ever dropped to make a rewrite fit: 8,203 of 9,975 v7 labels that look
unreferenced are referenced in v9/v10, and the byte-match gate cannot see a deleted label.

## ⚠ The screen the byte gate cannot be: is the decode CODE at all?

A mis-framed decode reproduces its bytes exactly, so `Similarity: 100.00%` says nothing about
whether a range is a function or a table of numbers. The entry criterion (*something already
disassembled calls this address*) is supposed to prevent that, and `v7_reachable_from_code.py`'s own
docstring says it does not always: *"those are calls into data, or calls found inside a CODE run
that was itself mis-framed. Read a target before converting it."*

Read on the first, unscreened `--apply` run — which converted 69 ranges / 6,765 bytes — 5 of them
were unmistakably data:

| where | decoded as |
|---|---|
| `ToneKit_FrequencyTable` (a frequency TABLE), two ranges | `nop / swi 7 / max / ei 0x04 / ldwio / normal / popw wa / halt / push SR …` |
| `CharMap_ValueData_B` (a character map) | `rcf / incf / retd 0x1009` |
| `WidgetParam_Entry_018` | `nop / swi 7 / reti` |
| `SeqStep_ByteBlockEA5F` | `cp A,H / ldb W,0xd7 / swi 2` |

**The cheap idea does not work.** `scripts/analysis/v7_target_reference_kind.py` tested the obvious
hypothesis — that a `call` reaches a function and a `jrl` into a table is a mis-decode. All four
junk entries are `jrl` targets, but so is `FileIO_BytecodeData` (0xFC5CB4), which decodes to 80
instructions of plainly real code, and `SeMenu_RefreshPartDisplay_Data` (0xF09AA6, a `jp` target)
to 76. Reference kind does not discriminate; the probe is kept so nobody re-derives it.

**What works is a screen on the decode.** `IMPLAUSIBLE = (swi, normal, max, halt, ldio, ldwio)`,
plus `retd` with a frame over 0xff — the forms that ROM table bytes decode to (`0xFF` → `swi 7` is
the commonest filler byte in the ROM). `--no-plausibility` turns it off.

The screen runs before placement, so its own tally (13 ranges: `normal` 8, `swi` 3, `halt` 1,
`retd` 1) covers both paths. The `.incbin` share — **5 ranges / 70 bytes** — is the difference
between the unscreened run (69 ranges / 6,765 B) and the screened one (64 / 6,695 B).

⚠ Frequency alone does **not** justify the set, and `scripts/analysis/v7_mnemonic_census.py` is why:
across the 210,320 instruction lines v7 already carries, `swi` occurs 3,804 times, `halt` 391 and
`ldio` 396 — "rare mnemonic" would be the wrong rule. What settles it is reading the six ranges the
screen fires on: five are the table decodes above, and the sixth, `AccState_ReadAccompParams`, is
real code whose second instruction is `ei 0x06` — which is exactly why `ei`/`di` are **not** in the
set. The other 64 ranges are untouched by the rule. It can only ever refuse; it never accepts
anything the byte match did not already accept.

## Reviewing what a run did

Every converted range is listed in `analysis/v7-reachability/v7_incbin_range_splits.json` — entry,
byte count, instruction count, the slice it came out of, and its first four instructions. A split
that turns table bytes into instructions is invisible to the build gate, so that manifest is the
only thing a reviewer can read.

## Running it

```
python3 scripts/converters/convert_reachable_ranges.py --dry-run   # place and check, write nothing
python3 scripts/converters/convert_reachable_ranges.py --apply
make clean-all && make all                                          # the gate; clean-all is not optional
python3 scripts/analysis/v7_code_delta_vs_head.py                   # the CODE gain, against HEAD
```

⚠ `make all` without `clean-all` relinks stale objects and can report both failures that no longer
exist and successes that are not real.

## What this leaves open

* **20 ranges / 1,722 bytes** whose entry is in neither an indexed `.byte` run nor a located
  `.incbin`. `README-rewrite-refusals.md` calls these runs separated from their anchor by
  instruction lines; addressing them needs the assembler's own line addresses — the same trick
  `incbin_index()` uses, applied to `.byte` runs.
* **29 ranges / 2,053 bytes** still declined silently by the "never drop a label" guard, 25 of them
  over labels nothing in `v7/maincpu/*.s` references.
* **48 bytes** inside an `includes/generated/` blob. Those are compiler output from
  committed C, so splitting them would fork the data away from its source — the same scope rule
  `convert_v7_ptr_tables.py` applies. Converting them means changing the C, not the blob.
