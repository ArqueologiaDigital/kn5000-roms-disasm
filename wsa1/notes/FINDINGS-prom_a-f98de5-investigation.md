# prom_a 0xF98DE5-0xF99000 (539 B): CONVERTED 2026-09-02

**Status: converted** -- 134 LE32 pointers plus a 135th entry truncated by the
module boundary. This file previously recorded a REFUSAL (2026-09-02, earlier
the same day). That refusal and its reasoning are preserved verbatim at the
bottom, because one of its two technical reasons was simply wrong and the
correction is the useful part of this file.

Converter: `notes/gen_prom_a_f98de5_table.py`; `--audit` re-derives every number
below and the emitter refuses if any check fails. Gate after the splice: all
four WSA1R images byte-identical.

## The correction

The refusal's load-bearing claim was:

> indices 118+ : the alignment breaks. Continuing the fixed 4-byte grid
> produces values like `0x00F30180`, `0x00F3006A` ... the true record grid is
> very likely NOT a uniform 4-byte stride starting exactly at 0xF98DE5

**The alignment never breaks.** All 134 four-byte windows from 0xF98DE5 have a
0x00 top byte and a value in `0x00F00000-0x00FFFFFF`. Zero exceptions. What
changes at index 118 is the VALUE FAMILY -- `0x00F30xxx` after `0x00F2xxxx` --
which is a different region of prom_b, not a different stride. A change of
family was read as a change of grid, and the span was refused on it.

## The evidence for the conversion

1. **Grid.** 134/134 windows pointer-shaped, no exceptions.

2. **An independent detector with a published null.**
   `notes/prom_a_ptr_tables.py`, which shares no code with the emitter, reports
   exactly one run in 0xF98D00-0xF99010: 0xF98DE5, 134 entries. Its `--null`
   over 0xFB2000-0xFB8000 -- 24 KiB of prom_a that is already converted CODE --
   finds runs of at most 16 entries and **zero** runs of 17 or more.

3. **The targets are real objects.** 32 of the 57 distinct
   `0x00F2xxxx`/`0x00F3xxxx` values are RECORD STARTS of prom_b's display
   lists, obtained by walking the interpreter's own self-checking
   (opcode, length) framing -- not by "looks like an address". The local values
   are `0x00F98D20` (31x), `0x00F98D21` (3x) and `0x00F98C85` (1x).

4. **A converted sibling with the same shape.** `PtrTable_F99121` is already in
   `prom_a/wsa1_prom_a.s`: 169 LE32 pointers of exactly this kind, converted on
   exactly this class of evidence -- its own header says the entry count came
   from `prom_a_ptr_tables.py`, "NOT from a reader's bound, because no reader
   bound was found". Align this table's entry 0 with `PtrTable_F99121`'s entry
   49 (0xF991E5) and 28 of 120 entries are byte-identical, including unbroken
   runs of 10 (indices 0-9) and 12 (indices 23-34). Both tails have the same
   shape -- many copies of a local default, one outlier, then three copies of a
   second local -- and the two defaults differ by exactly 0x400:
   0xF99120-0xF98D20 = 0xF99121-0xF98D21 = 0xF99085-0xF98C85 = 0x400. These are
   two parallel versions of one UI screen table.

5. **Not code.** `notes/prom_a_linear_decode_check.py` reports 37 undecodable
   bytes starting at 0xF98DE5 itself, and no branch, call or `jp` operand
   anywhere in prom_a's source lands inside the span.

## The 3 leftover bytes, explained rather than explained away

539 = 4*134 + 3. The trailing `49 f9 f2` are the low three bytes of
`0x00F2F949` -- and 0xF2F949 **is** a display-list record start, checked by the
same length walk as the other 32. So it is a 135th entry whose top byte would
sit at 0xF99000. 0xF99000 holds 0x3E, the `push XIZ` opening `sub_F99000`, so
the entry is cut in half by the module boundary.

That is the same mechanism identified this session at 0xFDFFDF-0xFE0000
(`FINDINGS-prom_a-fdffdf-stale-fragment.md`). In BOTH spans the earlier refusal
read a truncation at a module boundary as evidence that the framing itself was
wrong. It is worth stating as a rule: **an object that does not end where the
next module begins loses its tail, and the leftover is not a reason to doubt the
record shape** -- it is a prediction the record shape makes, which can then be
tested (here: is the truncated value a valid object address? yes).

The 3 bytes are emitted as `.byte`, not as a `.long`: a fourth byte does not
exist and inventing one would change the image.

## What is still not established

What indexes the table. No literal `0x00F98DE5`, nor any base inside
0xF98D00-0xF99010, exists in any of the four images -- re-checked this pass with
a whole-image LE24 and LE32 scan. `PtrTable_F99121` has the same gap and was
converted anyway; so is this.

---

## APPENDIX: the refusal this file used to carry (2026-09-02, superseded)

> **Status: refused.** Recorded here so the analysis is not repeated from
> scratch. Preceded by a function ending in the common `unlk XIZ / ret`
> epilogue (already converted); the span ends exactly at 0xF99000, a round
> address where `sub_F99000` (already converted) begins.
>
> ### Why a naive decode is not even attempted
>
> `python3 notes/prom_a_linear_decode_check.py 0xF98DE5 0xF99000` reports 37
> undecodable bytes STARTING AT THE FIRST BYTE (0xF98DE5 itself) and never
> reaches a boundary at 0xF99000. Unlike every span this pass closed, there is
> no clean code prefix to anchor on -- the whole 539 B reads as data from the
> first byte.
>
> ### What the data actually looks like
>
> Read as a flat array of 134 little-endian longs (536 of the 539 bytes;
> 539 = 4*134 + 3), the values fall into at least three families, in this
> order:
>
> * indices 0-82 (~332 B): clean `0x00F2xxxx` pointers, strictly increasing
>   and plausible as one table.
> * indices 83-117 (~140 B): overwhelmingly the SAME value, `0x00F98D20`
>   (33 of 35 entries), pointing into the ALREADY-CONVERTED code immediately
>   before this span, with one outlier `0x00F98C85` and 3 trailing
>   `0x00F98D21` entries -- the shape of a jump/return-address table where
>   most inputs share a default case.
> * indices 118+ : the alignment breaks. Continuing the fixed 4-byte grid
>   produces values like `0x00F30180`, `0x00F3006A`, mixed with more
>   `0x00F2xxxx` values, and the run does not divide evenly (3 leftover bytes
>   at the very end, `49 f9 f2`, look like the START of one more `0x00F2F949`
>   entry missing its top byte -- i.e. the true record grid is very likely NOT
>   a uniform 4-byte stride starting exactly at 0xF98DE5, the same
>   "alignment breaks partway through, off by some number of bytes" failure
>   mode already documented for the neighbouring 0xF8E77C-0xF8E7CD residue in
>   `FINDINGS-prom_a-f8e6fa-boundary.md`).
>
> ### What was checked and came up empty
>
> A raw whole-ROM pointer scan (3- and 4-byte little-endian) for the span's
> own start address, `0xF98DE5`, finds **zero hits** -- no literal reference
> anywhere in the ROM. If something reads this table, it does so through
> computed/relocated addressing this pass could not find, not a literal
> `ld XIY,0x00f98de5`-shaped load.
>
> ### Relationship to the already-documented `PtrTables_F95C95` cluster
>
> `prom_a/wsa1_prom_a.s` already has a converted, comparable structure at
> 0xF95C95-0xF95E82 (`PtrTables_F95C95`, converted in an earlier pass) with
> the SAME symptom: multiple mixed pointer tables, one of whose 59 entries
> still has "NO reader located" even after dedicated forensic work, and one
> stray byte that "belongs to neither" table. That cluster's own header
> records it as the weakest-evidence conversion in its neighbourhood.
> 0xF98DE5 looks like the same class of object, at a difficulty this pass did
> not have the budget to resolve to the same standard (an external reader or
> an independently-derived record boundary, the bar every OTHER conversion in
> this session met).
>
> ### Recommendation for whoever takes this next
>
> * Do NOT walk from 0xF98DE5 assuming a uniform 4-byte grid -- the observed
>   break after index ~117 means at least one record in this table is not
>   4 bytes wide, or the true start is offset from 0xF98DE5.
> * The 33x repeated `0x00F98D20` run strongly suggests a return-address /
>   default-case table for some dispatcher; finding what COMPUTES the index
>   into this table (rather than what is stored in it) is more likely to pin
>   the boundary than continuing to stare at the values.
> * Cross-reference the `0x00F300xx`/`0x00F301xx` family against whatever
>   object occupies that address range -- those two addresses recur next to
>   each other and may themselves be a small, separately-typed sub-table.

**On the appendix's third recommendation:** it was right. The
`0x00F300xx`/`0x00F301xx` family is a real sub-family -- three consecutive
entries at indices 118-120 -- and cross-referencing it against prom_b is part of
what confirmed the whole run. **On the first:** it was the one that had to be
disobeyed.
