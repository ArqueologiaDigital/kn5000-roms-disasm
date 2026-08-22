# Can the stalled rewrite refusals ever be accepted?

**Question.** `convert_reachable_ranges.py --apply` prints a refusal tally. Three of its
buckets barely moved across six closure rounds:

```
refused  23  range extends past its blocks
refused   6  replaced span holds a non-.byte, non-label line
refused   1  touched blocks do not tile contiguously
```

For each bucket: **is anything in it ever acceptable, or is the refusal unconditional?**
The tally cannot say. That distinction already cost 18,412 bytes once — anti-pattern 12 in
`docs/DISASSEMBLY-COMPLETENESS-SPEC.md`, where the whole-block re-check gated on "no local
labels" when it meant "no branches", so ranges branching to an external symbol were compared
against a link-time placeholder and could never pass, refused with the same message a broken
range produces.

**Tool.** `scripts/analysis/probe_rewrite_refusals.py`

```
python3 scripts/analysis/probe_rewrite_refusals.py            # ~2 min, prints 6 sections
python3 scripts/analysis/probe_rewrite_refusals.py --json /tmp/refusals.json
```

Needs `rebuilt_ROMs/kn5000_v7_program.llvm.elf`, i.e. a completed `make all`. It runs the
**real converter** through the real `--apply` path — every bucket assignment below is the
converter's own — with three additions: repo writes are intercepted and discarded (self-tested
at startup), `rewrite()` is wrapped to record each range and read which `REFUSED` counter moved,
and a **second pass** with a synthetic whole-ROM block index enumerates every range the
converter accepts, which is what makes the accounting exact. Run it on a copy of the tree if a
closure round is active: it cannot corrupt anything, but it would be reading a moving target.

**Measured on** the tree at commit `306a9d3` + working tree, 2026-08-22 17:09, immediately after
`convert_to_fixpoint.sh 8` reached its fixpoint in round 4 (`CODE 598,615 → 599,336`, gate 9/9,
`rewrote 0 file(s)`). ELF built 17:01 from that same tree.

## What the three buckets actually hold

Units: **ranges** (decoded entry-to-end runs) and **bytes of ROM**. Every byte below is *proven
code*: a range only reaches `rewrite()` after it decoded from a call target, ended at a `ret` or
at a code boundary, and had every instruction re-assembled to the ROM bytes.

| bucket | ranges | bytes | verdict |
|---|---:|---:|---|
| range extends past its blocks | 23 | 971 | **(b) fixable in the converter** |
| replaced span holds a non-.byte, non-label line | 3 | 182 | **(b) fixable in the converter**, narrowly |
| touched blocks do not tile contiguously | 1 | 34 | **(b) fixable in the converter** |
| *(three buckets combined)* | **27** | **1,187** | one shared root cause |

**None of the three is genuinely unconvertible.** All 27 are blocked by the same thing, and it
is not a property of the bytes: `blocks_of()` can only give a `.byte` run an address when a
label the ELF knows sits immediately above it. In this tree most runs do not.

* **extends past its blocks** — all 23 are `tail < 0`, never `lead < 0`; the range runs past
  the end of the last *indexed* block. In all 23, the bytes past the end are held by the very
  next `.byte` run in the same file, and that run's bytes **match the ROM at that address**
  (23/23). All 23 runs are unlabelled. Holes are 3–20 bytes.
* **touched blocks do not tile** — the single case (`0xF5FEC9`, 34 B) has a 25-byte gap between
  two labelled blocks, filled by six consecutive unlabelled `.byte` lines.
* **non-.byte, non-label line** — of the 37 offending lines across every refused range, **36 are
  blank**. Blank lines separate `.byte` runs everywhere in this tree, so this check refuses
  essentially every multi-block span. The 37th is real and must stay refused:
  `.incbin "includes/romslices/v7_transplant_TmFlashWrite_Block2.bin"`.

### The fix

**A. Address the runs that have no label** (`convert_reachable_ranges.source_index()`, *not*
`convert_corroborated_blocks.blocks_of()` — that one is shared). After `blocks_of()` returns,
walk the file's `.byte` runs in line order carrying a cursor: a labelled block sets
`cursor = addr + len`; an unlabelled run whose separation from the previous run is **only blank
or comment lines** gets `addr = cursor`, because those lines emit no bytes. Then verify
`raw == ROM[addr:addr+len]` — the check `source_index()` already applies to every block — and
drop it on mismatch. The label rule stays exactly as it is: a label must still not carry across
an intervening line, and a run separated by an *instruction* line gets no address this way.

Measured yield of exactly that rule: **139 runs / 559 bytes** gain a ROM-verified address, and
that is enough to make **23/23, 3/3 and 1/1** of the three buckets fully tiled — all 1,187 bytes.

**B. Let zero-byte lines through the span check.** A blank or comment-only line emits nothing;
skipping it cannot move a byte. Keep refusing everything else — `.incbin`, `.short`, `.ascii`,
instructions — as the one real case proves is necessary. A and B must ship **together**: fixing
A makes the ranges span more runs, and the blank lines between those runs then fail B.

*Proved:* the composition of each bucket, and that the A rule tiles all 27 ranges with the ROM
check passing. *Inferred:* that all 27 then convert — they still face the byte-count invariant,
the label-placement check and the `make all` gate.

## The two buckets with no counter at all — 10,881 bytes, 90% of the stall

The tally accounts for 27 of the 159 ranges the converter accepts. The other 132 disappear
without printing anything. This is the anti-pattern-12 shape again, one step worse: not a check
that cannot pass, but a rejection that is never reported.

```
159 range(s), 12,068 bytes accepted by the converter, of which:
    103 range(s)   8,828 bytes   NEVER REACHED rewrite() -- entry in no indexed block, NO COUNTER
     29 range(s)   2,053 bytes   SILENT: rewrite() returned None with no counter
     23 range(s)     971 bytes   range extends past its blocks
      3 range(s)     182 bytes   replaced span holds a non-.byte, non-label line
      1 range(s)      34 bytes   touched blocks do not tile contiguously
```

**Never reached `rewrite()`** — `main()`'s apply loop only places a range whose entry address is
inside an indexed block; anything else is dropped by the `for … break` with no counter and no
message. 82 of the 103 (7,101 bytes) have their entry **inside an `.incbin` ROM slice**, located
by unique content match (279 of 322 referenced `.incbin` files place uniquely, covering 967,340
bytes of the 2 MB ROM — data as well as code). Those need a converter that can replace an
`.incbin` line, which rule A does not give them: **0/103** become tiled by rule A. The remaining
21 ranges (1,727 bytes) sit in unaddressed `.byte` runs separated by instruction lines, which
rule A also does not reach. Category **(c), source-layout change**, and a much larger question
than these buckets.

**Silent `return None`** — the "NEVER DROP A LABEL" check in `rewrite()` returns `None` without
touching `REFUSED` when a label inside the span is not on a decoded instruction boundary. The
check is doing real work: a mis-framed decode still reproduces the ROM bytes exactly, so the
byte-match gate is blind to it and these labels are the only local evidence. But the labels are
the ones that are wrong here. Re-framing the same bytes from the enclosing block start explains
**0 of 29** ranges, and **25 of 29** are blocked by labels that **nothing in `v7/maincpu/*.s`
references**. Example (`note_voice_mapping.s:6664`): `Audio_NullRet1:` and
`Audio_NullRet1_Data:` sit on consecutive bytes `0xca 0x8b`, which is one instruction, `ld C,B`
— a label pair that cannot both be code. They come from the ROM-slice transplant pass; the only
other place they appear is `transplant_manifest.txt`.

Fixes, in order of confidence:

1. **give both silent paths a counter** — 10,881 bytes are currently invisible in a report whose
   whole purpose is to say why a round gained nothing. Cheap, and it is the lesson of
   anti-pattern 12;
2. **delete the unreferenced mid-instruction labels** (25/29 ranges, ~1,659 bytes tiled by rule
   A) — category **(c)**. They encode a framing that is demonstrably wrong. *Inferred, not
   tested*: an alternative that keeps the symbol defined is to re-emit such a label as
   `.set NAME, 0xADDR`, which emits no bytes, but `nm` then reports it absolute (`A`) rather
   than `t`, and `cc.elf_syms()` filters on `t`/`T` — check that before relying on it;
3. the `.incbin` bucket needs its own converter; nothing here fixes it.

## UPDATE 2026-08-22 — the `.incbin` bucket is converted

Point 3 has been done: `convert_reachable_ranges.py` now splits an `.incbin` ROM slice into
head residue / instructions / tail residue, and **64 ranges / 6,695 bytes** of the 82/7,101 came
out (`CODE 600,755 -> 607,450`, gate 9/9). See `scripts/converters/README-incbin-range-splits.md`.

Two things measured here needed correcting:

* **"located by unique content match (279 of 322)"** — content search is the wrong instrument.
  Assembling a copy of the tree with a unique label above every directive places **311 of 312**
  sites, all 311 ROM-verified, and is unambiguous for blobs that repeat or are included twice.
* **the entry criterion is weaker than this README assumed.** Every byte in these buckets was
  called "proven code" on the strength of being a call target. Five of the ranges that then
  converted were table data — a frequency table decoded as `nop / swi 7 / max / ldwio / normal /
  halt`, a character map as `rcf / incf / retd 0x1009`. The byte-match gate passed on all of them.
  `v7_reachable_from_code.py` says as much in its own docstring; this README repeated "proven
  code" without it. A screen on the decode now refuses that class.

## Ancillary census

`.byte` runs the block index cannot address at all: **5,597 runs / 87,170 bytes**.
5,561 have no label of their own, 22 have a label that resolves but bytes that disagree with the
ROM (`source_index()` drops these, and does print the count), 12 have a label the ELF does not
carry, 2 hold a symbolic `.byte`. Rule A reaches 139 of the 5,597; the rest are separated from
their anchor by instruction lines, so addressing them needs the assembler's own line addresses,
not arithmetic over `.byte` counts.
