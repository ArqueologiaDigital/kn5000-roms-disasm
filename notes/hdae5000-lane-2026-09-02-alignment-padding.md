# HD-AE5000 lane, 2026-09-02: word-alignment padding in the data-table pool

Lane HDAEBYTE of wave 2 (`notes/lanes/BRIEF-2026-09-01.md`). Target: the HD-AE5000 image's
13,288 B of undocumented `.byte` and 3,791 B documented-but-untyped, per
`hdae5000/tools/measure_debt.py`.

## What this is claiming, precisely

`hdae5000_data_tables.s` contained thousands of isolated `.byte 0x00` lines with no comment --
counted as bare, undocumented debt. A subset of 1,503 of them are converted here to
`.balign 2, 0x00`. **This is claimed as a genuine debt reduction, not a directive respelling**,
for a specific reason: before this change, nothing in the tree asserted what these bytes WERE --
they were undocumented. After, they carry an explicit, checkable structural claim ("this position
must be word-aligned; whatever padding that requires goes here") backed by evidence gathered
across the whole file, not a per-instance guess. A prior wave-1 lane reclassified 153,600 bytes of
already-annotated "wallpaper" this way and had to withdraw the claim because nothing changed
except the spelling; that is NOT the situation here, because these specific bytes carried no prior
annotation to merely re-spell.

The `.balign` form also has a real, checkable property a hardcoded `.byte 0x00` does not: if the
preceding string ever changes length, `.balign 2, 0x00` emits exactly the right pad (0 or 1 byte)
to keep the following content aligned, while a hardcoded `.byte 0x00` would silently keep emitting
one byte regardless of whether that is still correct. The rule is now explicit in the source, not
implicit in a byte count nobody wrote down.

## The evidence

Reproducible via `hdae5000/tools/alignment_evidence.py` (run it; do not take these numbers on
faith):

1. **File-wide alignment statistics** (ground-truth addresses from
   `hdae5000/tools/get_lprobe_addrs.py`, which asks the pinned assembler for the real linked
   address of every source line -- not a hand-rolled parse of `.asciz`/`.ascii` escape sequences):
   - `.long`: 1,580 of 1,580 operands (100%) start on a 4-byte-aligned address. Zero exceptions.
   - `.asciz`: 3,953 of 4,167 (94.9%) start on an even address.
   - `.ascii`: 1,582 of 1,608 (98.4%) start on an even address.
   - `.zero`: only 1,373 of 2,170 (63.3%) start on an even address -- **not** reliably aligned,
     which is why a bare `.byte 0x00` immediately before a `.zero` run is deliberately left
     unconverted (341 bytes, still counted as debt).
   - The `.asciz`/`.ascii` odd-start exceptions cluster inside one different, already-known
     sub-table (a `"*"`-suffixed glyph-name pool around 0x2A2065) that has no leading pad byte at
     all -- they are places that never had a pad, not counter-evidence against the rule.

2. **Two pre-existing offset anchors, independently added by an earlier pass for an unrelated
   reason** (naming specific strings, not studying alignment), resolve exactly against this
   script's byte-accounting, tens of thousands of bytes apart:
   - The ~45 `HDAE5000_Str_*` = `HDAE5000_RECORD_COUNT + 0xNN` anchors in `hdae5000_init_data.s`
     (naming every `EV_*`/`MT_*`/`*Proc` string in that 13-entry pool) all land exactly on the
     string they claim to.
   - `HDAE5000_Panel_Save_UI + 0x2ca4` = `0x2A2656` = `"ABC"` (`HDAE5000_Str_CharSet_Upper_1`).
   - `HDAE5000_UI_Page_Titles + 0x11ea` = `0x29F174` = `"! HD FORMAT !"`
     (`HDAE5000_Str_Alert_HDFormat`).
   
   If this file's byte-accounting were wrong anywhere between these anchors (which are
   20,000+ bytes apart), at least one would land on the wrong content. None do.

3. **Selectivity**: `convert_align_pads.py` only converts a bare, single-operand `.byte 0x00`
   when it sits at a real ODD address (from ground truth, not computed) AND the very next content
   line is `.asciz` or `.ascii`. It does NOT touch:
   - the 341 bytes before a `.zero` run (weak evidence per point 1),
   - the ~3,005 bytes immediately before ANOTHER bare `.byte` (no alignment evidence applies --
     could easily be a genuine second one-byte field that happens to be zero), left as
     unconverted debt and reported as such.

## Two individually-verified extra bytes (not part of the bulk pass)

`HDAE5000_RECORD_COUNT`'s own header carried two more bytes the bulk pass's filter correctly
skipped, handled by hand and documented in-place:
- `.byte 0x0d` (the pool's leading byte) is NOT alignment filler: `hd-ae5000_v2_06i.s:310` reads it
  with `ldw_da xwa, (0x29d97e)` -- a 16-bit load (confirmed against
  `TLCS900InstrInfo.td`'s `LD16_da24` definition) -- as a real record count (13), matching
  `HDAE5000_RECORD_TABLE`'s already-documented 13 records. Its high byte is genuinely zero data,
  not padding; merged into one documented `.byte 0x0d, 0x00` line instead of leaving the high byte
  looking like generic filler.
- The byte right after `"SelectListProc"` pads the pool to its real boundary `0x29DC12` (the start
  of the UI object descriptor pool documented right below it), not to another string -- so the
  bulk converter's "next line is `.asciz`" filter skipped it. Verified by hand against
  `get_lprobe_addrs.py` output and converted to `.balign 2, 0x00` for the same reason as the bulk
  pass.

## Numbers

| | undocumented `.byte` (debt) |
|---|---|
| before | 13,288 B |
| after bulk `.balign` pass (1,503 B) | 11,785 B |
| after the two hand-verified RECORD_COUNT bytes | 11,783 B |

Measured by `hdae5000/tools/measure_debt.py`. Rebuild verified byte-identical to
`original_ROMs/hd-ae5000_v2_06i.ic4` after every step (`make rebuilt_ROMs/hd-ae5000_v2_06i.llvm.rom
&& cmp rebuilt_ROMs/hd-ae5000_v2_06i.llvm.rom original_ROMs/hd-ae5000_v2_06i.ic4`).

## What was found but NOT fixed (out of this lane's measured scope, reported for follow-up)

`HDAE5000_RECORD_TABLE` (0x29C0AA, labelled "Record/entry data table" and already documented
elsewhere in `hdae5000_init_data.s` as 13 x 24-byte records) is currently written as ~6,150 lines
of TLCS-900 instruction mnemonics (`neg bc`, `pushw wa`, `scf`, ...) rather than `.byte`. This is
invisible to `measure_debt.py` (it only counts `.byte`/`.word`/`.incbin`, not fake-but-valid
instruction syntax) and is the SAME illusion-of-code trap that produced the 309 B "Technics
Software section M. Kitajima" false-code finding earlier in this same image (already fixed,
`8a5c99d`-era commit; see `hd-ae5000_v2_06i.s:19` and `hdae5000_ui_display.s:22074`). Evidence this
is data, not code: the only two references to this address range anywhere in the tree are
`lda_24 xwa, (0x29c0aa)` (load ADDRESS) and `ldw_da xwa, (0x29d97e)` (load a WORD OF DATA) in
`hd-ae5000_v2_06i.s:310-312` -- both treat it purely as a data pointer/value, never as a call or
jump target. No CALL/JP anywhere targets this range. A smaller instance of the identical pattern
also exists in `HDAE5000_Lang_Codes` (bytes disassembled as `ei 16`, `reti`, `pushw bc`,
`push sr`, mid-string). Converting either was judged too large/risky to do safely inside this
lane's session (6,356 bytes needing careful record-field typing, not just data/`.byte`
relabelling) and is left for a follow-up pass with its own verification budget.

## Reproduce every number in this note

```
python3 hdae5000/tools/get_lprobe_addrs.py > /tmp/lprobe.txt
python3 hdae5000/tools/alignment_evidence.py /tmp/lprobe.txt
python3 hdae5000/tools/measure_debt.py
```
