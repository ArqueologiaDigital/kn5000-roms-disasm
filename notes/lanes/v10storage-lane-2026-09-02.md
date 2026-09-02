# Lane v10storage — 2026-09-02

Six v10 directories: `storage`, `ui`, `factory_test`, `file_io`, `boot`, `demo`.

Everything below is reproducible from scripts committed on this branch. Every
number names the script and the exact command that produced it.

## 1. The headline: 2,088 bytes were not code at all

`storage/flash_floppy_handlers.s` opened with 1,000 lines of TLCS-900
instructions covering **0xF15907–0xF1612F**. They are not instructions. The span
is a `[flags:u8][len:u8][payload]` record stream, interleaved with u32 pointer
tables and a 168-byte ASCII effect-name table.

    python3 scripts/analysis/lane_v10storage_record_stream_evidence.py

| check | result |
|---|---|
| reference kind of the span's 18 labels, tree-wide | 63 address-taken, **0 call/jump** |
| record-length chains closing exactly on a pointer table | **6/6** (plus one running 140 records / 1,376 B) |
| in-span pointers landing on a predicted record start | **44/44** (14 out-of-span excluded as untestable) |
| `.set` addresses written by an earlier analyst from the CONSUMING code | **12/12** |
| ASCII inside the span | 168/168 printable — `CELESTE 1`, `ORGAN TREMOLO`, `SOLO EFFECT 1` |

Null, measured not assumed: the same chain-closure test from 20,000 random
starts inside proven code closes exactly **1.0%** of the time. Record-start
density is 7.95%, so 12/12 external hits is p ≈ 6.4e-14.

Converted by `scripts/converters/convert_flash_record_stream.py`, which reads
every byte out of `original_ROMs/` and refuses to write unless its own emission
equals the ROM. All 18 labels and all 7 pre-existing `data-as-code` comments are
preserved. The 38-byte tail at 0xF16109 does **not** obey the `[flags][len]`
rule and says so in the source instead of being guessed at.

## 2. The three-way split, with both error rates

    python3 scripts/analysis/lane_v10storage_byte_split.py --control
    python3 scripts/analysis/lane_v10storage_byte_split.py

| dir | (a) code-debt | (b) suspect | (c) typed data | (d) blind-start |
|---|---:|---:|---:|---:|
| storage | 793 | 65 | 2,095 | 1,125 |
| ui | 1,266 | 1,517 | 363 | 198 |
| factory_test | 8 | 412 | 940 | 104 |
| file_io | 229 | 0 | 3 | 1 |
| boot | 71 | 162 | 114 | 17 |
| demo | 290 | 130 | 60 | 17 |
| **total** | **2,657** | **2,286** | **3,575** | **1,462** |

(d) is an overlay on (a)/(b)/(c), not a fourth column — **and it is retracted as
evidence**; see §3.

**The control is the point.** The obvious criterion — a `.byte` run flanked by
instructions on both sides — has a **94.5% false-positive rate** measured
against 0xF15907–0xF1612F, ground truth this lane established independently.
Requiring the enclosing block to also call something that has a name takes that
to **0.0%**, at **66.2% sensitivity** on blocks another routine branches to by
name. Because sensitivity is 66%, bucket (b) is a ceiling: roughly a third of it
is expected to be real code the rule failed to corroborate.

That second term had to be added: `ADDR_ONLY` alone condemned
`BitMapOut_ByteData_RenderB`, which is address-taken 9× from a handler table in
`ui_widgets/widget_dispatch.s` and is ordinary code reached by indirect
dispatch. **A function-pointer table is the standing exception to "only its
address is taken ⇒ it is data".**

## 3. ⚠ The blind-start statistic: retracted, and this lane's own null

`scripts/analysis/byte_run_start_enrichment.py` (15115eae) flagged
`storage/flash_floppy_handlers.s` at 80/757 = 10.6% blind-starting `.byte` runs.

Measured here: **63 of those 80 (79%) sat inside 0xF15907–0xF1612F**, the span
proven above to be a record stream. Zero control-byte runs sat there. After the
span was typed as data — with no instruction converted anywhere — the file reads
**29/577 = 5.0%**.

This does not contradict the probe; it anticipates its **full retraction**
(`a4e94fcb`). With the decoder taught the five opcodes, 82.8% of v10's
blind-starting runs decode clean against **82.1% for a shuffle of the same
bytes** — no instruction structure at all — and the ratio was structurally
confounded: after a linear force-disassembly pass a `.byte` run begins at
*exactly* the refused byte, so a *decodable* control byte can almost never start
one, pinning the control near zero by construction.

A blind first byte says only *the framing here is wrong*. The decoder refuses in
real code it cannot spell **and** in a data region an earlier pass framed as
code, and the rate cannot tell them apart. This lane's file is a worked instance
of the second case.

⚠ Consequently bucket (d) is kept as a mis-framing smell and as a **refusal**
reason, never as a count of code. `ui_mode_handlers.s` at 29.6% remains worth
looking at, as *suspect framing*, in either direction.

## 4. The 0xF98697 marker — adjudicated

    python3 scripts/analysis/adjudicate_groupbox_ssf_marker.py

The tree's only self-tagged "still undecoded" markers were three copies of one
line. In **v10 and v9** the region is `UIState_KeyScan_Dispatch`, already spelled
as 29 instruction directives with **zero `.byte`**, and an independent unidasm
decode of `original_ROMs/` names **exactly the same 12 absolute addresses**,
12/12. The marker was **stale**; v10's is replaced with what was found.

What settles it is the REFERENCES, not any byte statistic:
`ui_widgets/widget_dispatch.s` takes the routine's address as a handler-table
entry and the block calls named routines, so it is code — and it is already
spelled as code.

**v7 is a different case and the marker hid it.** v7's copy names 0xf98697, but
v7's `UIState_KeyScan_Dispatch` is at **0xF9828A** — the address was never
re-derived for that image. There, 88 bytes genuinely are still 11 `.byte` lines,
and the references say which reading applies: `widget_dispatch.s` takes the
address as a handler-table entry and v9/v10 carry the same routine decoded, so
it is **code**, blocked on nothing but effort. All three markers now say what
was found; `kn5000_source_coverage.py` reports **none found**. v7's bytes are
NOT converted — v7 is deprioritised, and the work is a mechanical transcription
of v9/v10's block with v7's operand addresses.

## 5. `fd_test_data.s` — the answer was already committed

`scripts/analysis/extract_fd_test.py` documents this file's content as NAKA
widget descriptors (type-0x16 diaglist and friends) with the headers already
converted to the `naka_header` macro, and `notes/FINDINGS-naka-record-format.md`
establishes that NAKA record bodies are **u16 little-endian fields**. 940 of its
998 `.byte` operands classify as (c) typed data. They are structured, and could
be spelled `.short`, but they are not un-decoded anything.

## 6. Two ScreenData spans handed back to their own C source

`se_setup_editor_full.c` (266 B at 0xF1616F) and `se_setup_sel4.c` (10 B at
0xF1659F) were already committed, typed and named, and compile byte-exact — they
were simply never listed in the Makefile's `SE_NAMES`, so the bytes sat in
`flash_floppy_handlers.s` as anonymous `.byte` rows and, in part, as fake
instructions (`ld xix, 0x4d414e59` is the ASCII `"MANY"`). Now built and
`.incbin`'d; the same C already serves v7 and v9.

    python3 scripts/converters/convert_flash_se_setup_descriptors.py /tmp/amap.json

## 7. Islands: what converts, and why so little

    python3 scripts/analysis/address_line_map.py --dump /tmp/amap.json
    python3 scripts/analysis/lane_v10storage_island_feasibility.py /tmp/amap.json

Of the code-flanked runs in bucket (a):

| framing | runs | bytes |
|---|---:|---:|
| FIT — the run is exactly one instruction | 409 | 677 |
| **OVERRUN** — the real instruction runs PAST the run | **1,516** | **1,776** |
| UNDERRUN — more than one instruction in the run | 72 | 189 |

**76% are OVERRUN**, i.e. the source's *next* line is mis-framed, so fixing them
means re-framing neighbours, not rewriting one line. That reproduces the 67%
figure `v9_v10_undisassembled_census.py` already recorded for this shape.

llvm-mc reproduces the exact bytes for 330 of the 409 FIT runs. The blockers,
ranked by bytes: `db` 52 B, `div reg,(mem)` 46 B, `cp reg,(mem)` 10 B,
`call reg,imm` 10 B, `set reg,(mem)` 8 B — 162 B in 12 distinct forms.

After the anchor walk and the blind-start refusal, **10 runs / 26 bytes** were
actually written.

### ⚠ A batch of 13 was written first and reverted

Three of them came from an **address map one revision behind the source**. It
pointed at other bytes while every downstream check still passed — unidasm
decoded happily, llvm-mc round-tripped happily — and only the rebuilt ROM
objected, at 0xF16FCC. The whole batch was reverted.

The fix is a guard that demands the ROM byte equal **the byte the source line
itself states**. Shown to work rather than assumed: on the stale map it refuses
501 runs, on the fresh map 0, and the accepted set is identical either way.
Anything reading an address map in this tree should carry that assertion.

## Refusals, each with its reason

* **1,776 B, 1,516 runs — OVERRUN.** Needs the neighbouring instruction
  re-framed too; a one-line rewrite would leave the source inconsistent.
* **162 B, 12 forms — the assembler cannot spell it.** Backend coverage, fixed
  in `~/compartilhado/llvm-project`, not here.
* **1,462 B, 216 runs — blind-start**, `{0x01, 0x04, 0x17, 0x1a, 0x1c}`.
  ⚠ Refused for the CORRECTED reason (§3): not "blocked in the toolchain" — all
  five already assembled — but because such a run carries no instruction
  structure and is most likely data a linear pass broke at the byte it could not
  consume. Forcing one could *succeed* with some other reading that still passes
  the byte gate.
* **344 B, 238 runs — failed the anchor walk.** A linear unidasm decode from the
  enclosing entry point does not put an instruction boundary at the run's start
  or end, so the run's neighbours cannot both be right. Not guessed at.
* **269 B, 150 runs — no usable anchor** (the nearest entry point is more than
  1 KB away, so the walk would not be evidence).
* **2,286 B, 218 runs — bucket (b).** Code-flanked but the enclosing block is
  address-taken only and calls nothing named: the same signature the flash
  record stream had. These are data-as-code LEADS, and converting the `.byte`
  in them to instructions would deepen the error while passing the gate.
* **38 B — the 0xF16109 tail.** Its length byte is 0; the `[flags][len]` rule
  does not reach it.
* **v9 and v7 marker copies** — lower priority by standing order.
