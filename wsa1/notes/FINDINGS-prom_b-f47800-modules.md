# prom_b 0xF47800-0xF4EFFF — eight modules at the head of the 0x047800 span

Status: **converted**, 30,720 bytes of the `.incbin` closed, of which **21,962
are substantive** (20,777 code + 1,185 data) and 8,758 are `ret` padding emitted
as `.fill`. Round 3, 2026-08-25. The byte gate
(`python3 scripts/analysis/assert_byte_identical.py`) passes.

Everything below is produced by two scripts, both in `notes/`:

    python3 notes/gen_prom_b_f47800_module.py --layout    # the 26-segment table
    python3 notes/gen_prom_b_f47800_module.py --checks    # 90 rows; it REFUSES to emit if one fails
    python3 notes/gen_prom_b_f47800_module.py --records   # the 81 DL_F4C000 records
    python3 notes/prom_b_round3_frontier_delta.py         # the frontier arithmetic

## Why this span, and not another

`notes/prom_b_module_frontier.py` ranks whole thunk RUNS by contiguous
unconverted extent; `notes/prom_b_call_graph.py` ranks individual SLOTS by an
opcode-anchored reference upper bound. This span wins on the second measure by a
wide margin:

> Of the **eleven** unconverted thunk slots whose reference bound was **13 or
> more**, **eight** pointed into 0xF47800-0xF4EFFF — 0xF4E56F (x24), 0xF4D01D
> (x21), 0xF4D0DB (x18), 0xF4D02C (x15), 0xF4E524 (x14), 0xF4D0FB (x14),
> 0xF48580 (x13), 0xF48464 (x13). The other three are 0xF000B9 (x29), 0xF5553F
> (x15) and 0xF556D2 (x13).

⚠ **Stated at a threshold, never as "N of the top ten".** Two slots tie at x13,
two at x14 and two at x15, so any top-N phrasing depends on how the sort broke
the ties and cannot be reproduced. `prom_b_round3_frontier_delta.py` re-derives
both 11 and 8 from the ROM, *and* asserts that nothing else sits at exactly 13,
so the threshold itself is tie-free.

⚠ The reference bound ranks slots. It is a byte-window upper bound, not a call
count, and must never be quoted as one.

## Layout — eight code modules, each closed by `ret` padding

| range | kind | bytes |
|---|---|---:|
| 0xF47800-0xF487E9 | code | 4,074 |
| 0xF487EA-0xF48BFF | `.fill` 0x0E | 1,046 |
| 0xF48C00-0xF48C19 | `Table_F48C00` | 26 |
| 0xF48C1A-0xF494B7 | code | 2,206 |
| 0xF494B8-0xF497FF | `.fill` 0x0E | 840 |
| 0xF49800-0xF4B7AC | code | 8,109 |
| 0xF4B7AD-0xF4B7CC | `IdentityMap_F4B7AD` | 32 |
| 0xF4B7CD-0xF4BFFF | `.fill` 0x0E | 2,099 |
| 0xF4C000-0xF4C38C | `DL_F4C000` | 909 |
| 0xF4C38D-0xF4C3E8 | `DispatchTable_F4C38D` | 92 |
| 0xF4C3E9-0xF4C3F1 | `BitMask_F4C3E9` | 9 |
| 0xF4C3F2-0xF4C735 | code | 836 |
| 0xF4C736-0xF4C7FF | `.fill` 0x0E | 202 |
| 0xF4C800-0xF4CB5A | code | 859 |
| 0xF4CB5B-0xF4CFFF | `.fill` 0x0E | 1,189 |
| 0xF4D000-0xF4D949 | code | 2,378 |
| 0xF4D94A-0xF4DFFF | `.fill` 0x0E | 1,718 |
| 0xF4E000-0xF4E5DB | code | 1,500 |
| 0xF4E5DC-0xF4E5FB | `IdentityMap_F4E5DC` | 32 |
| 0xF4E5FC-0xF4E61B | `BitWeight_F4E5FC` | 32 |
| 0xF4E61C-0xF4EBFF | `.fill` 0x0E | 1,508 |
| 0xF4EC00-0xF4EF2E | code | 815 |
| 0xF4EF2F-0xF4EF37 | `Table_F4EF2F` | 9 |
| 0xF4EF38-0xF4EF3F | `Table_F4EF38` | 8 |
| 0xF4EF40-0xF4EF63 | `Table_F4EF40` | 36 |
| 0xF4EF64-0xF4EFFF | `.fill` 0x0E | 156 |

Every edge is one of: the `.incbin`'s own start; the first byte of a maximal
0x0E run whose purity is re-read on every emit; a **thunk target**; or an
address a decoded instruction of the transcription names. None is "where a
linear decode resynchronised".

⚠ **`ret` IS 0x0E, so a raw 0x0E run always reaches one byte further back than
the padding does.** Where a routine stops and its padding starts is therefore a
*reading*, not a measurement. `checks()` prints how far back each raw run
reaches — 1 byte where a routine's closing `ret` precedes it, 0 where a data
island does — so the reading is visible instead of hidden. This is the same
caveat `notes/prom_b_songstore_checks.py` records for 0xF7CE67.

## The ten data islands

**`Table_F48C00`** — the sixteen ASCII bytes `WSA SOUND RAM S0`, then the four
ASCII bytes `WSA1`, then `88 00 18 00 00 00`. The routine that starts at the
very next byte copies the first sixteen into its stack frame (`lda
XIY,0xf48c00` at 0xF48C24, then `ldirw` with BC = 8) and the next four with `ld
XBC,(0xf48c10)` at 0xF48C2E — 20 of the 26 accounted for by decoded
instructions. What the last six mean is **not** established, and the name says
nothing beyond the bytes. Reads like the title and format magic of a saved-data
header; nothing decoded here follows the frame to a device, so the guess stays
out of the name.

⚠ The island's END is 0xF48C1A, which is the target of thunk slot **T_DiskFile_CheckSignature** —
an entry point the hardware uses, not a reading. *The first draft of the
generator typed `T_F40B54` here; T_F40B54's target is 0xF483B2. The header now
reads the slot out of the thunk table, and a `checks()` row asserts the slot set
of 0xF48C1A is exactly {T_DiskFile_CheckSignature}.*

**`IdentityMap_F4B7AD` and `IdentityMap_F4E5DC`** — 32 bytes each, entry k = k.
Each has exactly one reader, `ld XIX,imm32`. prom_b now has **three** identity
maps: these two and `IdentityMap_0_31` at 0xF5EE75, converted in round 2. Three
copies of a table that returns its own index is recorded here as a fact; nothing
in the ROM explains why one exists at all, let alone three.

**`BitWeight_F4E5FC`** — sixteen 16-bit words, entry k = 1 << k. One reader,
`ld XIX,0x00f4e5fc` at 0xF4E510.

**`BitMask_F4C3E9`** — nine bytes, `00 01 02 04 08 10 20 40 80`: entry 0 is
0x00, entry k is 1 << (k−1). One reader, `add XBC,0x00f4c3e9` at 0xF4C6D4. Its
end is thunk target 0xF4C3F2.

**`DL_F4C000`** — a UI display list, **81 records**, in the format
`scripts/analysis/prom_b_display_lists.py` documents (+0 opcode, +1 length of
the whole record, +2 operands and, for the text opcodes, characters). The count
is self-checking rather than measured: advancing from 0xF4C000 by each record's
own length byte lands on 0xF4C38D **exactly**, which is where the pointer table
begins. It draws `CREATOR SELECT` and `CONTROLLER`, among others.

⚠ Nothing in prom_a or prom_b spells 0xF4C000 as a 32-bit word, so the list's
caller is **not** established and the records are emitted as framed `.byte` rows
rather than rendered field by field. ⚠ One record does not fit the shape: the
one at 0xF4C2F8 frames as opcode 0x00 with length 134. It is recorded, not
smoothed — the walk still lands on the pointer table, which is the only thing
the record count rests on.

**`DispatchTable_F4C38D`** — 23 pointers. **Fifteen** are the default thunk stub
`0x00F42C70` (see `notes/prom_b_default_slot_census.py`); the remaining eight
resolve to **three** addresses inside this module — 0xF4C4DD six times, 0xF4C588
once, 0xF4C5A2 once — and all three are asserted to be instruction boundaries of
the transcription. The
count is fixed at both ends: the display list's framing walk stops exactly at
0xF4C38D, and the first word that is *not* a prom_b address is at
0xF4C3E9 — 92 bytes, 23 × 4, nothing over.

**`Table_F4EF38`** — 8 bytes, `01 01 02 03 04 05 06 07`. Its entry count comes
from the CODE, not from the extent: `and A,0x07` at 0xF4EDF0 and `ld IY,WA` at
0xF4EDF3 sit in front of `ld XIX,0x00f4ef38` / `ld A,(XIX+IY)`, so the index can
only be 0..7.

**`Table_F4EF2F`** — 9 bytes, `01 01 02 03 04 05 06 07 08`. **Nothing reads it**
that this tree can find. Its neighbour above is a `ret`; its neighbour below is
the referenced 8-byte table. Name claims nothing.

**`Table_F4EF40` — a 36-byte dead duplicate.** These 36 bytes are
**byte-identical to 0xF4EF1C-0xF4EF3F**, the tail of the routine at 0xF4EF14
together with the two tables after it. No site in either ROM spells 0xF4EF40,
0xF4EF53 or 0xF4EF5C. Decoded from its own first byte it reads `jrl
GT,0xF52E63` — a jump into the 3,571-byte 0x0E padding run at 0xF5220E — so it
cannot be entered as code either. A build that emitted a routine twice and lost
the first eight bytes of the second copy would produce exactly this; so would a
hand patch. Nothing in the ROM decides between them, and the header says so.

## Frontier, before and after

| | before | after |
|---|---:|---:|
| unconverted prom_b thunk **slots** | 283 | **191** |
| unconverted **distinct targets** | 277 | **185** |
| runs with unconverted targets (`prom_b_module_frontier.py`) | 29 | **20** |
| real `.incbin` spans in prom_b (`grep -cE '^\s*\.incbin'`) | 124 | **124** |
| substantive bytes (`source_coverage.py`) | 116,575 | **138,537** |
| `.fill` bytes | 19,532 | **28,290** |

283 − 191 = **92 slots** and 277 − 185 = **92 distinct targets**. For this span
the two units agree — no slot shares a target with another — and that agreement
is asserted rather than assumed, because the same reconciliation for round 2's
0xF44018 span was off by two (64 slots, 62 targets). Reproduce both from the ROM:

    python3 notes/prom_b_round3_frontier_delta.py

The span count is unchanged: one `.incbin` directive was replaced by one
`.incbin` directive covering the 24,576 bytes left. The `.fill` gain is 8,758
bytes and is reported separately from the 21,962 substantive ones; **a `.fill`
never headlines a round.**

## What the auditor caught, and it is the tree's own recurring defect

`notes/prom_b_audit_callsites.py` was run against the first spliced draft and
returned **three OFF-BY rows, all mine**. Two are a real defect and one is a
phrasing fault; they are separated here rather than lumped together:

| label | header claimed the instruction was at | it is actually at |
|---|---|---|
| `DispatchTable_F4C38D` | 0xF4C4C9 | **0xF4C4C8** `add XWA,0x00f4c38d` |
| `BitMask_F4C3E9` | 0xF4C6D5 | **0xF4C6D4** `add XBC,0x00f4c3e9` |

The cause was a one-line shortcut: the generator computed the reader's address
as *(32-bit reference) − 1*, which is right for the one-byte opcode `ld
XIX,imm32` and **wrong for the two-byte `add XWA,imm32`**. This is the same
family as round-2 finding F2 (twelve headers naming the operand of `ld
XDE,0x00F7C6E6` instead of the instruction) and the round-2 audit's "~20 call
sites cited one byte past the instruction".

The third row, `BitWeight_F4E5FC` cited 0xF4E511 / OFF-BY-1, was **not** a wrong
address: the header named the instruction correctly, at 0xF4E510, and 0xF4E511
was its operand field, disclosed as such. The auditor's operand exemption is
deliberately narrow — the word *operand* has to appear within 60 characters
**after** the address — and this header put it before. Worth recording twice
over: the narrow rule is what makes the other two rows trustworthy, and a
generator that phrases a disclosure the checker cannot see is a generator whose
clean run means less than it looks.

The fix is not a corrected constant. `reader()` now walks the **proven
transcription** and returns whichever instruction actually contains the
reference, and `checks()` asserts, per island, that the instruction's mnemonic
ends in that island's own address and that the header cites the instruction
address and not *ref−1*. After the fix the auditor reports **0 OFF-BY rows in
either mode**, 1,021 citations over 3,376 labels, and the 24 residual `??` rows
are the pre-existing set documented in `notes/README-prom_b.md` — none of them
in this block.

## What is left, and why

0xF4F000-0xF54FFF (24,576 bytes) stays `.incbin`, and it is **not** because it
is hard to read. `notes/prom_b_module_trace.py 0xF47800 0xF55000` reaches none
of 0xF4EF14-0xF53019: those modules have **no thunk slot pointing at them**, so
a recursive descent has no seed and the code/data split there would rest on a
linear decode. This tree does not accept a linear decode as a boundary argument,
and the probe in `notes/FINDINGS-prom_b-round-maps.md` is why — growing an
island by one byte, so the following code segment starts one byte late, leaves
every thunk target on a boundary because the decode resynchronises.

The one thunk run left inside that range is **T_F42E40-T_F42E6C**, 12 slots at
0xF53000-0xF54210, and it *is* seeded. It is the obvious next unit of work, and
`prom_b_module_frontier.py` currently ranks it fourth in the image.

## A self-test that failed on its own success

`notes/prom_b_module_frontier.py --selftest` went **FAIL** the moment this block
landed. Its last row was

    check("unconverted run T_F40C50 is present", ...)

and T_F40C50 is one of the eight runs round 3 converted. The script's own
docstring already warned about this shape — *"an earlier draft hard-coded the
then-top run (T_BStore_AppendBytes_Join3_Veneer) and would have started FAILING the moment that run was
converted"* — and it had the defect again in a different row.

Fixed 2026-08-25: the presence check now takes the **last** `jp` slot in table
order whose target is still inside an `.incbin` and asserts that `survey()`
reports the run owning it. It is derived from the ROM, follows the tree's
last-element rule, and can only stop discriminating when the frontier is empty —
which the first row of the same selftest catches. Round 3's eight runs went into
the absent-list, which is the part that is *meant* to grow.

All eight of the lane's other self-checking scripts were re-run after the splice
and are unaffected: `prom_b_module_trace.py --selftest`,
`prom_b_sc1_states.py --selftest`, `prom_b_default_slot_census.py`,
`prom_b_dispatch_tables.py`, `prom_b_f7d_tables.py`, `prom_b_f5b800_checks.py`,
`prom_b_songstore_checks.py`, `prom_b_dl_length_audit.py` — all exit 0.

## Reproducing the whole round

    python3 scripts/analysis/assert_byte_identical.py     # the gate
    python3 scripts/analysis/source_coverage.py           # 138,537 substantive in prom_b
    python3 notes/gen_prom_b_f47800_module.py --checks    # 90 rows
    python3 notes/prom_b_round3_frontier_delta.py         # 283 -> 191 slots
    python3 notes/prom_b_audit_callsites.py --quiet       # 0 OFF-BY rows
    python3 notes/prom_b_evidence_audit.py --scopes       # 40 new labels, 40 BACKED
    python3 notes/prom_b_module_frontier.py --selftest

⚠ **Every one of those `notes/` scripts is UNTRACKED.** This lane may not
`git commit`, so 21,962 substantive bytes of `prom_b/wsa1_prom_b.s` currently
rest on a generator that exists only in one working tree, and the `REGENERATE:`
line in the emitted text points at a file a `git clean -fd` would destroy.
Committing `notes/*.py` remains the first thing the owner of this tree should do;
see the standing warning at the top of `notes/README-prom_b.md`.
