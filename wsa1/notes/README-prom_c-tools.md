# prom_c helper scripts in `notes/`

Five scripts added by the prom_c conversion lane.  They live here rather than in
`scripts/analysis/` only because that directory belongs to another lane; each answers one
question and prints its own limits.  `scripts/analysis/README.md` is the index for the
committed tools.

## `prom_c_sibling_map.py`
**"Where does this WSA1 byte range occur in the KN5000 sub-CPU image, what is it called
there, and where exactly does the identity STOP?"**

```
python3 notes/prom_c_sibling_map.py --selftest
python3 notes/prom_c_sibling_map.py --addr 0xF9806D --len 44
python3 notes/prom_c_sibling_map.py --addr 0xF98099 --len 81 --diff 0x1FD27
python3 notes/prom_c_sibling_map.py --sym DSP_WriteAllChannelRegs
python3 notes/prom_c_sibling_map.py --runs --minrun 48 --code-only
```

`notes/kn5000-label-transplant-generated.md` says a name applies; this says how far it
applies.  That mattered immediately: `DSP_WriteChannelRegs_Inner` is 80 of 81 bytes identical
to the sibling's, and the byte that differs is the peripheral base address — 0x00E00000 here,
0x00130000 there.  A header that copied the sibling's comment across would have put a
non-existent address into this tree, and the byte gate would not have noticed.

Always against the ELF's own unspliced image, never
`original_ROMs/kn5000_subprogram_v142.rom` — see `notes/FINDINGS-kn5000-transplant-offset.md`
for why that distinction is a retraction and not a detail.  `--selftest` re-proves it.

## `prom_c_xrefs.py`
**"Who references this address, and do they read it or write it?"**

```
python3 notes/prom_c_xrefs.py 0xF9806D --no-window
python3 notes/prom_c_xrefs.py 0x00F2F3 --no-window --classify
```

Finds `calr` displacements, raw 24/32-bit literals, and — **since round 2** — all twelve
direct-address spellings of the target: `prefix = 0xC0 | (size << 4) | width` with *width*
0/1/2 selecting a 1-, 2- or 3-byte address field.  `--classify` decodes one instruction at
each hit, turning a hit list into a read/write census; the run ends with a
`TOTAL literal-addressed sites:` line so a quoted count comes from the tool, not from
counting rows by eye.

> **Why the twelve-spelling sweep exists.**  The round-1 census of `0x00F2F3` searched the
> 24-bit form only, reported **nineteen** references, and missed the two `0xD1` (16-bit
> address) sites at `0xF99FC2` and `0xF99FCD`.  The real figure is **twenty-one**.  Both
> missed sites are reads, so the conclusion ("exactly one writer") held — but the number
> shipped wrong and passed the byte gate, which is exactly the failure mode this tree has
> already had to retract for.  Re-run with the fix, `0x007ED1` (14), `0x00F32A` (3) and
> `0x00F32B` (2) are unchanged.

⚠ It never proves a hit is an instruction, and it does not search short PC-relative forms or
**pointer-register** references, so an empty result means "not found", never "nothing calls
this", and a total is always a total of *literal-addressed* sites.  Every hit prints a
disassembly window so a false positive is visible.

## `prom_c_ram_image.py`
**"What does CPU 2's variable block hold at power-on?"**

```
python3 notes/prom_c_ram_image.py
python3 notes/prom_c_ram_image.py 0x00F32A 0x00F2F3:4
```

`RESET` copies 4,312 bytes of ROM into `0x00E2DF`, so most CPU-2 variables have a readable
default.  The script re-derives the copy's source, destination and count **from the
instruction bytes** and refuses to print anything if they are not exactly what it expects, so
`notes/FINDINGS-prom_c-ram-image.md` cannot drift away from the ROM.

## `prom_c_prom_a_shared_runs.py`  *(round 2)*
**"Where do prom_c and prom_a contain the same bytes, and where does the identity stop?"**

```
python3 notes/prom_c_prom_a_shared_runs.py --selftest
python3 notes/prom_c_prom_a_shared_runs.py --at 0xF9A01F 0xF8E6C9
python3 notes/prom_c_prom_a_shared_runs.py --runs --minrun 48
```

The two CPUs were built from one source tree, so the C runtime and the micro-DMA helpers appear
in both EPROMs and prom_a's names can be carried over — but only for the bytes that really are
identical.  `--at` prints the maximal run through a pair of addresses together with the first
differing byte on each side, so a header can state the extent instead of waving at a
neighbourhood.  `--selftest` re-proves the one figure the tree quotes: the micro-DMA / block-move
helper block is a **98-byte** identical run, prom_c 0xF99FEE ↔ prom_a 0xF8E698, maximal in both
directions.

Same discipline as `prom_c_sibling_map.py`, and for the same reason: byte identity is evidence
for a name, never proof of one, and a run that stops mid-routine is a trap.

## `prom_c_link_state_machine.py`  *(round 2)*
**"What does each CPU-1 link command make CPU 2 do?"**

```
python3 notes/prom_c_link_state_machine.py
python3 notes/prom_c_link_state_machine.py --dma
python3 notes/prom_c_link_state_machine.py --flags
python3 notes/prom_c_link_state_machine.py --selftest
```

Decodes the 7-entry INT0 command table and the 9-entry INTTC3 state table straight out of the
ROM by matching the arms' fixed instruction shapes — it never disassembles and never reports a
field it did not match, which is why it says "arms matching the fixed shape: **6 of 7**" instead
of quietly inventing a count for the seventh (whose transfer length is computed at run time).
It also censuses every literal-addressed reference to the state variable `0x00F32D` over all
twelve direct spellings: 18 references, 17 immediate byte writes covering exactly 0..9 and one
read.  `--selftest` checks the LAST row of both tables, not only the first, and prints the word
after each table so "the table ends here" is visible rather than assumed.  `--dma` censuses
every micro-DMA control-register access in the image and prints its own false positives (the
CR-0x00 rows) instead of filtering them away.  `--flags` censuses the five link flag/counter
bytes and prints the SPAN of the sites -- which is where an off-by-one hides, and did: a first
draft of the INTTC3 header quoted a range that stopped short of the two sites inside
`Link_WaitBlockDone`.

Every number in the `INT0_HANDLER__cmd_*` and `INTTC3_HANDLER__state*` headers, and in
`notes/FINDINGS-prom_c-link-receive.md`, comes from this script.

---

# Added by round 3 (2026-08-25)

Six more, same discipline: each answers one question, prints its own limits, and is named in the
source header of anything it produced a number for.

## `prom_c_frontier.py`
**"Which UNCONVERTED addresses does the already-converted code call?"** — reachability instead
of linear address order.

```
python3 notes/prom_c_frontier.py --spans
python3 notes/prom_c_frontier.py
```

It parses the `.incbin` directives out of `prom_c/wsa1_prom_c.s`, disassembles the converted
spans, and lists every literal `call`/`calr`/`jp`/`jrl`/`jr` target that lands outside them,
most-called first, with the address of each caller.

⚠ A linear disassembly of a span that embeds data produces phantom targets — the hits inside
0xFCC7xx and 0xFDDxxx in the default output are exactly that. The caller addresses are printed
so a phantom is visible. Re-run after every edit; "unconverted" is a property of the source
file, not of the ROM.

## `prom_c_listing_prep.py`
**"Turn `llvm_roundtrip_autoforce.py` output into this file's house style."**

```
python3 notes/llvm_roundtrip_autoforce.py c 0xF9973D 0x481 --quiet > /tmp/blk.s
python3 notes/prom_c_listing_prep.py /tmp/blk.s --prefix KL > /tmp/blk.pretty.s
```

`.byte` runs become `extpfxN` (or a named spelling from
`notes/prom_c-llvm-mc-spellings.md`), raw branch displacements become labels taken from
unidasm's own rendering, `calr` becomes the constant-folded `(target - next)` idiom, internal
I/O addresses become their `.equ` names, and decimals become hex. **It changes spelling only.**

## `prom_c_verify_fragment.py`
**"Does this fragment rebuild exactly the ROM bytes it claims to?"**

```
python3 notes/prom_c_verify_fragment.py c 0xF9973D /tmp/blk.pretty.s
```

The byte gate is whole-image and tells you which ROM differs at which offset; this assembles ONE
fragment and names the first differing byte with both contexts. Run it **before** the gate, not
instead of it. Every block round 3 inserted was cleared by this first.

## `prom_c_prom_a_routine_diff.py`
**"Are these two routines the SAME routine compiled for the two CPUs, or just similar?"**

```
python3 notes/prom_c_prom_a_routine_diff.py 0xF99A40 0xF8E0FE 0x83
```

`prom_c_prom_a_shared_runs.py` measures BYTE identity and is the wrong tool when every port
address, handshake pin and work-RAM address differs: it reports **8 bytes** for a pair of
routines that are in fact the same **47 instructions**. This aligns them instruction by
instruction and separates *different mnemonic* (structural) from *same mnemonic, different
operand* (a substituted address), printing every difference in full.

⚠ It compares unidasm's TEXT.

## `prom_c_tg_chanmap.py`
**"Every port write one routine makes to a register-pair device, in order, with where its value
came from."**

```
python3 notes/prom_c_tg_chanmap.py 0xFB713A 0x1F2 --pairs
python3 notes/prom_c_tg_chanmap.py 0xFB713A 0x1F2 --groups
python3 notes/prom_c_tg_chanmap.py 0xFB77EF 0x1B0 --dev 0x00104000 --groups
python3 notes/prom_c_tg_chanmap.py --selftest
```

`prom_c_tg_regmap.py` matches the small fixed-shape accessors and printed 27 sites it could not
match; most of them are inside `Dev10C_WriteAllChanRegs`, which is not an accessor at all. This
walks one routine, follows the +0 and +2 pointers through their frame slots, tracks what each
16-bit register holds, and preserves across a `calr` **exactly the registers the callee pushes
and pops** — read off the callee, not assumed. It reports the stream in execution order and
never zips two lists, which is the mistake `FINDINGS-prom_c-tone-generator.md` §3 had to
retract. `--selftest` asserts the LAST select and the LAST data write.

It was cross-checked against an independently derived result before being trusted: run on
`Dev104_WriteAllChanRegs` it reproduces `prom_c_tg_regmap.py --dev104`'s nineteen blocks 0..0x12
and the trailing block-0 write.

## `prom_c_dup_image.py`
**"prom_c carries its initialiser image twice. Where exactly, how do the copies differ, and does
anything use the second one?"**

```
python3 notes/prom_c_dup_image.py --extent
python3 notes/prom_c_dup_image.py --diff
python3 notes/prom_c_dup_image.py --refs
python3 notes/prom_c_dup_image.py --fill
python3 notes/prom_c_dup_image.py --selftest
```

`--extent` walks the identity outward and reports **both** alignment deltas rather than
splitting the region on one of them; `--diff` decodes every differing byte and shows that 40 of
the 41 are pointers relocated by exactly the delta; `--refs` classifies each literal hit by the
bytes around it and **counts** the coincidences it discards instead of dropping them silently;
`--fill` checks the 118,298-byte tail over every byte. Every figure in
`notes/FINDINGS-prom_c-duplicate-initialiser.md` comes from it.

## `prom_c_audit_callsites.py`  *(round 3, self-audit)*
**"Does every address a `Called from:` line names actually START a call to that routine?"**

```
python3 notes/prom_c_audit_callsites.py
python3 notes/prom_c_audit_callsites.py --quiet     # only the rows that did not check out
```

This tree's history includes *"call sites cited one byte past the instruction, ~20 times,
systematically"*, and the cause is structural: `prom_c_xrefs.py` prints the address of the
LITERAL it matched, while the instruction that owns the literal begins one or two bytes
earlier. Copying the tool's address into a header is therefore wrong **by default**, and the
byte gate cannot see it.

The script parses every `; Called from:` block out of `prom_c/wsa1_prom_c.s`, takes each
routine's own address from the `; ADDR` comment on its first instruction line, disassembles ONE
instruction at every cited address, and checks it is a transfer to that routine.

⚠ **Read the output; it is not a pass/fail.** A header legitimately names a pointer-table entry
(`Link_Ch0_AppendToRing` is reached through `Handler_PtrTable_FCC53F`, not by a `call`), a
descriptor argument, or the routine that *contains* the call rather than the call itself. As of
2026-08-25 it reports **178 cited sites, 150 decoding to a real transfer and 28 flagged**, and
every one of the 28 was read and is one of those legitimate cases.

---

# Added by round 4 (2026-08-25)

## `prom_c_flash_driver_check.py`
**"Does the flash driver at 0xFC856C-0xFC89C4 really issue the command sequence, the sector
map, the buffer address and the loop counts its headers claim?"**

```
python3 notes/prom_c_flash_driver_check.py     # prints every check, exits non-zero on failure
```

It reads `original_ROMs/wsa1_prom_c.ic28` and matches **bytes**, not unidasm's text, so nothing
it asserts depends on the disassembler. Every quantified claim in
`notes/FINDINGS-prom_c-flash.md`, in the 0xFC856C block comment and in the sixteen routine
headers below it comes from here: the two JEDEC unlock addresses, all 21 immediate command
bytes, the four device/manufacturer literals, both boot-block sector maps (offsets, sizes,
their mirror relation and the 7 × 64 KiB that makes 512 KiB), the 0x00010000 staging buffer,
the `− 0x00E70000` window arithmetic, the 1 << 10 slice scale, and the three loop counts.

⚠ The one thing it cannot do byte-only is the *register width* of `djnz`, which is a property
of the prefix byte — so it checks the prefix byte itself (0xCA = the 8-bit B, 0xD9 = the 16-bit
BC) and cites where that mapping is defined in MAME. That is the check that found the one real
oddity in the block: `Flash_SectorBlankCheck` loads `BC = 0x4000` and then counts with `B`, so
it inspects 256 bytes and not 64 KiB.

## `prom_c_prom_a_shared_runs.py --window` *(new mode)*
**"How similar are these two routines as raw bytes — all of it, not just the run through one
address?"**

```
python3 notes/prom_c_prom_a_shared_runs.py --window 0xF99A40 0xF8E0FE 0x83
```

`--at` measures the ONE maximal run that passes through the address you give it, which for a
pair of routines is usually the leading prologue. Reporting that as if it were the maximum is
a mistake this tree shipped once — `Link_SendCmdE2_MemRead`'s header said *"an identical run of
only EIGHT bytes"*; 8 is the leading run, the longest is 23 and 109 of 131 bytes are equal.
`--window` prints every equal run, the longest, and the total, and `--selftest` now asserts all
three of those figures alongside the 98-byte micro-DMA run it already checked.

## `prom_c_coverage_split.py`
**"How much of prom_c's 'converted' figure is `.fill` padding?"**

```
python3 notes/prom_c_coverage_split.py
```

`scripts/analysis/source_coverage.py` counts a `.fill` directive as converted bytes and says so
nowhere. For prom_c that is 23.3 of its 28.0 percentage points — one directive covering the
0x0E padding run at 0xFE21E6-0xFFEFFF. The real figure, the bytes someone had to read, is
**4.7%**. Quote both or neither.

⚠ prom_c only, because `scripts/analysis/` belongs to another lane. The same defect inflates
prom_a and prom_b; adding a `.fill` column to the shared tool's table is left to whoever
integrates.

## `prom_c_header_audit.py`
**"Which semantic labels have no evidence in the comment block above them?"**

```
python3 notes/prom_c_header_audit.py            # summary + the tier-C list
python3 notes/prom_c_header_audit.py --tier B   # the one-word fixes
python3 notes/prom_c_header_audit.py --all
```

The round-1 audit measured "semantic labels with no line containing 'Evidence'" by hand and got
44 of 92 for one round's additions — a number nobody could re-derive, and one that over-states
the problem because many labels sit under a shared block comment that argues its case without
using the word. This makes it reproducible and splits the two cases: **tier A** the header says
"Evidence"; **tier B** it cites a tool, a `0xXXXXXX` address or another label but not by that
keyword; **tier C** it asserts a name and backs it with nothing.

As of round 4: **110 A / 112 B / 0 C** over 222 labels. Working through tier C is what found the
write-order defect corrected in `Dev104_SetChanRegs_01C0_0200_0240`,
`Dev104_SetChanRegs_0140_to_0240` and `Dev104_WriteChanReg0`.

⚠ Tier B is not a pass, and tier A is not proof — the keyword is only a keyword. This measures
whether a citation is *present*, never whether it is *true*; `prom_c_audit_callsites.py` is the
tool that checks truth, and only for `Called from:` lines.
