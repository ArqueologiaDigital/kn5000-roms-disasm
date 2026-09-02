# Lane `rq-embedded` — the census's `embedded-in-code` column, 2026-09-02

**Target:** `notes/DATA-CENSUS-2026-09-02.md` §8, *"embedded-in-code, 222,810 B —
undocumented data between two instruction regions"*, which the census says
plainly is *"a disassembly job, not a data job"*.

Toolchain for every number here: `tlcs900_backend @ 6f456a19f05b`
(`6f456a19f05bf94696728e89e74a53ed62dc9adf`). It did not move during the lane.

## Where the column actually is

Regenerated per image rather than taken as a lump sum
(`data_range_census.py --images v10,v9,v7`):

| image | before | after | delta |
|---|---:|---:|---:|
| v10 | 32,098 | 30,679 | −1,419 |
| v9 | 48,119 | 41,688 | −6,431 |
| v7 | 139,927 | 113,637 | −26,290 |
| **total (3 maincpu images)** | **220,144** | **186,004** | **−34,140** |

The other ~2,666 B of the 222,810 lies outside these three images.

## Two numbers, and why they differ — read before quoting either

* **60,524 B of data directives became instructions.**
  `scripts/analysis/data_directive_bytes.py --diff 08d0c4e8` — counts bytes
  emitted by `.byte`/`.hword`/`.word`/`.dword`/`.ascii`/`.asciz`/`.incbin` in
  `v{7,9,10}/maincpu/**.s` at two revisions, from the source text. `.incbin`
  total unchanged (+0), so the whole movement is directive bytes.
* **The census's `embedded-in-code` column fell by 34,140 B.**

They are not the same measurement and neither is wrong. The census flag is a
property of a region's NEIGHBOURHOOD — data with an instruction region on each
side and no header of its own — so it moves for reasons other than conversion:
removing an island MERGES two code regions, and every new code/data boundary can
create a new, smaller flagged region. It answers "what is still unexplained".
The directive count answers "how many bytes did this lane convert". The lane's
own tools reported 60,668 B, which agrees with the independent source-text count
to 0.24 %.

## What was converted, and what fixed each boundary

| pass | image | spans | `.byte` → instructions | what fixed the boundary |
|---|---|---:|---:|---|
| island re-frame | v10 | 1,885 | 5,057 | a pair of addresses that is **both** a source-line address and a linear-sweep boundary, on both sides of the island — the sweep must re-converge on the tree's own framing |
| island re-frame | v9 | 4,292 | 9,863 | same |
| island re-frame | v7 | 2,788 | 8,840 | same |
| twin-framed spans (5 gates) | v7 | 216 | 14,668 | the **same label** exists in v10/v9 with the **same span length to the next label**, and the twin's source spells those bytes as instructions |
| twin framing **ported** | v7 | 43 | 22,240 | the twin's own STATEMENTS, walked over v7's bytes, gated on ≥60 % byte agreement and ≥60 % slots byte-identical |
| **total** | | **9,224** | **60,668** | |

Both twin passes take **both** boundaries from outside the span, which is the
point: on a variable-length encoding a wrong start resynchronises, so agreement
downstream of the start proves nothing about the start.

★ **The island re-frame was not a data-vs-code judgement at all.** It removes the
old toolchain's resync artefact: where the encoder could not spell a form it
emitted `.byte <first opcode byte>` and resumed ONE BYTE LATER, so the two or
three instructions printed after the byte are the tail of the real instruction
read at the wrong offset. `.byte 178` / `push sr` / `pushw iy` / `nop` is one
`ldw (xde), 45`, and the CPU never executed those three.

★ **The largest single entry in §8 is done.** `v7 AudioCtrl_DataBlock`,
7,134 B — 2,536 slots, 2,194 of them byte-identical to v10's — is instructions,
with 165 B left as `.byte`.

## Refusals, each with the specific missing fact

**1. The decoder cannot read the ALU-with-memory-operand family, and the encoder
can. This is the single biggest blocker left.**
`scripts/analysis/decoder_gap_ranking.py`. Three re-framing passes refused a span
14,239 times on a byte the sweep could not read; ranking those byte values and
sampling v10 statements the assembler itself provides, **171 of 655 sampled forms
are refused or mis-sized by `llvm-objdump`, and `llvm-mc` encodes every one of
them back to the ROM's bytes**: `cp (xwa), 0`, `cpw (xwa), 65535`,
`add b, (xbc)`, `adc iy, (xiy)`, `cp l, (xsp)`, `cpdi8 (1026), 4`,
`resm 0, (xwa)`, `setm 6, (xde)`.

⚠ The leading byte is not the unit of failure: `9f 06 81` (`add bc, (xsp+6)`) is
refused while `9f 08 23` (`ld hl, (xsp+8)`) reads fine. 0x9f selects the
addressing mode and the next byte the operation.

**Consequence, and it is not a small one:** the five decode-based gates score the
tree's CORRECT source against a decoder that cannot read it. `AudioCtrl_DataBlock`
is refused at gate C because v10's framing and an independent decode disagree at
4.2 % of instruction starts — all of it this gap. Closing it would make the
decode gates usable on the largest spans and would unblock a share of the
238,587 B the v7 re-frame pass refused for want of an anchor pair.

**2. Four forms the decoder spells as a DIFFERENT instruction.**
`scripts/analysis/decode_encode_asymmetry.py`. `85 11` prints as `ldir` and
re-encodes to `80 11`; `bb 01 cf` prints as `and (xhl+1), xsp` and re-encodes to
`ab 01 cf`; `9e 04 04` and `9c 20 04` print as `push xiz` / `push xix`, which are
the one-byte `3e` / `3c`. Byte LENGTHS are right in all four, so framing is
unaffected — only the text. Missing fact: the operand-size / addressing spelling
for these encodings.

**3. `v7 WndEvt_EventCodeDispatch` (1,527 B) — OPEN.** It passes all five framing
gates and fails the round trip at +0x4C5, and the bytes there round-trip
correctly when decoded standalone with context. Not explained by (1) or (2).

**4. 1,098 v7 spans whose twin is 0 % instruction bytes.** These are data in both
images and were correctly refused; they are not a research target, they are an
answer.

**5. 408 of 1,756 same-length twin spans share <60 % of their bytes with the
twin** — same label, same distance to the next label, different code. Not
convertible from the twin. `AccMidi_DispatchLoop` is 67 B in both images and
shares NOT ONE byte.

**6. The v7 re-frame pass refused 238,587 B** for want of a pair of addresses
that is both a source-line boundary and a sweep boundary. That is the honest
shape of v7: ~30 % code and far more fragmented than v9 or v10.

## ⚠ The mistake this lane made, and the gate that now catches it

Port mode's first run converted **342 spans whose MEDIAN byte agreement with the
twin was ZERO**. Gate A only says two labels are the same distance apart; two
same-length spans with nothing in common are not the same routine, and porting a
length sequence onto them frames v7 by a coincidence of label spacing. **The
whole-span round trip cannot see it** — it only proves the emission reproduces
v7's bytes, which any framing that decodes will. It was reverted; two floors now
gate it, and `AccMidi_DispatchLoop` is the selftest's null.

★ The general shape: *a check that the output is self-consistent is not a check
that the input hypothesis is true.*

## The gate

`make gate-all` in this worktree: **13/13 rebuilt ROMs byte-identical**, 8/8
KN5000 images assembling. Proven able to go RED on this lane's own bytes, twice:

* v10, `ldw (xde), 45` → `46` in `drawbar_panel_ui.s` — red at file offset
  `0x18091F`, one byte, restored green.
* v7, `ldw wa, 52` → `53` inside the ported `AudioCtrl_DataBlock` — red at
  `0x1804F2`, one byte, restored green.

## Reproduce

    make all                                            # inputs must exist
    python3 scripts/analysis/twin_framed_spans.py --selftest
    python3 scripts/analysis/decoder_gap_ranking.py --selftest
    python3 scripts/analysis/decode_encode_asymmetry.py --selftest
    python3 scripts/analysis/data_directive_bytes.py --selftest

    # where the column is, per image
    python3 scripts/analysis/data_range_census.py --images v10,v9,v7 --targets 40

    # island re-frame, per image (the line map must be REGENERATED after any
    # edit to the files it describes -- a stale map is invisible to every check
    # except the rebuilt ROM)
    python3 scripts/analysis/v10_line_address_map.py --image v9 \
        $(find v9/maincpu -name '*.s') --out /tmp/lm-v9.json
    KN5000_IMAGE=v9 python3 scripts/analysis/v10_reframe_code_runs.py \
        --linemap /tmp/lm-v9.json --report $(find v9/maincpu -name '*.s')

    # v7 spans the twin already frames
    python3 scripts/analysis/twin_framed_spans.py --report --min 64
    python3 scripts/analysis/twin_framed_spans.py --apply /tmp/lm-v7.json --min 16
    python3 scripts/analysis/twin_framed_spans.py --port  /tmp/lm-v7.json --min 64

    # before/after, independent of the converting tools
    python3 scripts/analysis/data_directive_bytes.py --diff 08d0c4e8

## Tooling changed, and why

* `v10_line_address_map.py` takes `--image`, `v10_reframe.py` and
  `v10_byte_run_classifier.py` take `KN5000_IMAGE` — all defaulting to v10, so
  existing callers are unaffected. The same defect exists in all three images and
  the tools named v10's ROM, ELF and root source literally.
* `v10_reframe.py`'s `verify()` had three FIXED `/tmp` paths shared by every
  lane; it now uses a private temporary directory. Two lanes verifying at once
  would have checked each other's image.
* `v10_reframe_code_runs.py`: a candidate text assembling to `encoding: []` now
  joins the bad set instead of crashing the run after every file was processed.

## A hazard worth passing on

The `.s` sources are latin-1 and the `.py` tools are UTF-8. Writing a tool file
back through `encoding='latin-1'` **truncates it to zero bytes** at the first
`⚠` — silently, with the traceback pointing at the encode, not at the loss. The
lane brief's latin-1 addendum is about the sources; the inverse applies to
everything else in the tree.
