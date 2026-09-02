# prom_a 0xF98DE5-0xF99000 (539 B): investigated 2026-09-02, NOT converted

**Status: refused.** Recorded here so the analysis is not repeated from
scratch. Preceded by a function ending in the common `unlk XIZ / ret`
epilogue (already converted); the span ends exactly at 0xF99000, a
round address where `sub_F99000` (already converted) begins.

## Why a naive decode is not even attempted

`python3 notes/prom_a_linear_decode_check.py 0xF98DE5 0xF99000` reports 37
undecodable bytes STARTING AT THE FIRST BYTE (0xF98DE5 itself) and never
reaches a boundary at 0xF99000. Unlike every span this pass closed, there is
no clean code prefix to anchor on -- the whole 539 B reads as data from the
first byte.

## What the data actually looks like

Read as a flat array of 134 little-endian longs (536 of the 539 bytes;
539 = 4*134 + 3), the values fall into at least three families, in this
order:

* indices 0-82 (~332 B): clean `0x00F2xxxx` pointers, strictly increasing
  and plausible as one table.
* indices 83-117 (~140 B): overwhelmingly the SAME value, `0x00F98D20`
  (33 of 35 entries), pointing into the ALREADY-CONVERTED code immediately
  before this span, with one outlier `0x00F98C85` and 3 trailing
  `0x00F98D21` entries -- the shape of a jump/return-address table where
  most inputs share a default case.
* indices 118+ : the alignment breaks. Continuing the fixed 4-byte grid
  produces values like `0x00F30180`, `0x00F3006A`, mixed with more
  `0x00F2xxxx` values, and the run does not divide evenly (3 leftover bytes
  at the very end, `49 f9 f2`, look like the START of one more `0x00F2F949`
  entry missing its top byte -- i.e. the true record grid is very likely NOT
  a uniform 4-byte stride starting exactly at 0xF98DE5, the same
  "alignment breaks partway through, off by some number of bytes" failure
  mode already documented for the neighbouring 0xF8E77C-0xF8E7CD residue in
  `FINDINGS-prom_a-f8e6fa-boundary.md`).

## What was checked and came up empty

A raw whole-ROM pointer scan (3- and 4-byte little-endian) for the span's
own start address, `0xF98DE5`, finds **zero hits** -- no literal reference
anywhere in the ROM. If something reads this table, it does so through
computed/relocated addressing this pass could not find, not a literal
`ld XIY,0x00f98de5`-shaped load.

## Relationship to the already-documented `PtrTables_F95C95` cluster

`prom_a/wsa1_prom_a.s` already has a converted, comparable structure at
0xF95C95-0xF95E82 (`PtrTables_F95C95`, converted in an earlier pass) with
the SAME symptom: multiple mixed pointer tables, one of whose 59 entries
still has "NO reader located" even after dedicated forensic work, and one
stray byte that "belongs to neither" table. That cluster's own header
comment records it as the weakest-evidence conversion in its neighbourhood.
0xF98DE5 looks like the same class of object, at a difficulty this pass did
not have the budget to resolve to the same standard (an external reader or
an independently-derived record boundary, the bar every OTHER conversion in
this session met).

## Recommendation for whoever takes this next

* Do NOT walk from 0xF98DE5 assuming a uniform 4-byte grid -- the observed
  break after index ~117 means at least one record in this table is not
  4 bytes wide, or the true start is offset from 0xF98DE5.
* The 33x repeated `0x00F98D20` run strongly suggests a return-address /
  default-case table for some dispatcher; finding what COMPUTES the index
  into this table (rather than what is stored in it) is more likely to pin
  the boundary than continuing to stare at the values.
* Cross-reference the `0x00F300xx`/`0x00F301xx` family against whatever
  object occupies that address range -- those two addresses recur next to
  each other and may themselves be a small, separately-typed sub-table.
