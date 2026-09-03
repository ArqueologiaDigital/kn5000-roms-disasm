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
descriptor argument, or the routine that *contains* the call rather than the call itself.

★ **Since round 3 every non-decoding row is CLASSIFIED**, because "N did not decode" was a
number with no meaning: it put a mis-cited call site and a RAM variable in the same bucket.
The classes are `OFF-BY-N` (a transfer to the routine begins within 8 bytes of the cited
address but not at it — **the defect this tool exists for, and it must be zero**), `RAM`
(outside the ROM image), `PTR32` (the word at the cited address *is* the routine's address —
a pointer-table entry), `IN-ROUTINE` (the header cited the calling routine, and the real site
is printed), and `PROSE`. `--strict` exits 1 on any `OFF-BY-N`; `--selftest` runs six negative
controls including a last-element one.

At the end of round 3: **2,699 cited sites, 18 not decoding — OFF-BY-N 0, RAM 0, PTR32 10,
IN-ROUTINE 1, PROSE 7.** (When the classifier was first run it found **three OFF-BY-N rows**
hidden inside the old "29 did not decode": two in `KeyScan_ReadEvent`, whose header named the
literal addresses beside the correct instruction starts, and one in
`KeyScan_InitKeyStateBitmap`, whose `Called from:` gave the calling routine's entry where the
call site belongs. All three are fixed.)

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


---

# Added by round 5 (2026-08-25)

## `prom_c_kernel_map.py`
**"Is `0xF9816B-0xF989EE` really prom_a's kernel, is the RAM map right, and does
anything call it?"**

```
python3 notes/prom_c_kernel_map.py --map        # the nine arrays, and the tiling check
python3 notes/prom_c_kernel_map.py --pairs      # 36 routine pairs against prom_a
python3 notes/prom_c_kernel_map.py --callers    # which entry points are used
python3 notes/prom_c_kernel_map.py --selftest   # all three, plus the boundary checks
```

Every quantified claim in the `0xF9816B-0xF989EE` block comment, in the 30 routine
headers under it, in the corrected `EntryPoint_Records` header and in
`notes/FINDINGS-prom_c-kernel.md` comes from here.

* `--map` reads the nine array bases and the nine `ldb b,N` counts out of
  **Kernel_InitRam's instruction bytes** — never out of a disassembly and never
  out of the `.s` file, so the header cannot drift away from the ROM — and then
  asserts the arrays **tile 0x0100-0x0183 with no gap and no overlap**. That
  tiling is what turns "three tasks / two levels / four semaphores / two message
  queues / four free nodes / two timers" from readings into a chain in which any
  single wrong count would leave a hole.
* `--pairs` drives `prom_c_prom_a_routine_diff.py` over all 36 pairs, but first
  **checks that every routine ends exactly where the next one begins, in BOTH
  images**, and fails if it does not — the boundary this tree has got wrong
  before. It expects 0 structural differences everywhere except `Kernel_InitRam`,
  whose 2 are the eight-byte inline `SoftTimer_Request_Boot` block that an
  instruction decoder renders as nonsense in both images; any other structural
  difference is a non-zero exit.
* `--callers` censuses every published entry with `prom_c_xrefs.py` and pairs each
  stack face with its register face. ⚠ It **excludes** the five entries reached by
  RESET's `jp`, by fall-through, or by a `jrl` — `prom_c_xrefs.py` searches
  literals and `calr` only, so those five read as zero and would be miscounted as
  unused. This is where the figure "11 of 26 published entry points have no call
  site in prom_c" comes from, and it is a searched negative.
* `--selftest` additionally checks the semaphore-count image, the eight-byte boot
  timer request and the `jr` that steps over it, that all three
  `EntryPoint_Records` levels index inside the ready-queue array, and — because
  the first element is not the one that hides an error — re-runs the **LAST** pair
  of the table on its own.

⚠ `--pairs` compares unidasm's TEXT, exactly as `prom_c_prom_a_routine_diff.py`
does. "0 structural differences" means the two disassemblies use the same
mnemonics in the same order: strong evidence that two routines are the same
routine, not a proof.


## `prom_c_apply_headers.py`  *(round 5)*
**"Turn a byte-verified prep listing into house style: real label names and a full
header block above every routine."**

```
python3 notes/llvm_roundtrip_autoforce.py c 0xF9816B 0x884 --quiet > /tmp/b.s
python3 notes/prom_c_listing_prep.py /tmp/b.s --prefix KX > /tmp/b.pretty.s
python3 notes/prom_c_apply_headers.py /tmp/b.pretty.s labels.txt headers.txt > /tmp/b.final.s
python3 notes/prom_c_verify_fragment.py c 0xF9816B /tmp/b.final.s
```

The mechanical step between `prom_c_listing_prep.py` and the `.s` file: it renames
the auto-generated `KX_xxxxxx` labels from a map, inserts a header block above each
named address, and rewrites `di` as `ei 0` (the same bytes `06 00`; llvm-mc's `di`
is EI 0, which ENABLES interrupts). Round 5 used it for all four blocks it
inserted. **Spelling and comments only** -- `prom_c_verify_fragment.py` and the
byte gate remain the proof.

⚠ The label prefix is hard-coded to `KX_`. Round 5 lost one fragment verification
to a `KE_` prefix mismatch: the label LINES were dropped while the references were
not, so the branches assembled to the wrong bytes. The fragment verifier named the
first wrong byte immediately, which is what it is for.

## `prom_c_runtime_check.py`  *(round 5)*
**"Do the EEPROM driver at 0xFC89C5-0xFC8BB1 and the compiler runtime at
0xFCA0BA-0xFCB27D really say what their headers claim?"**

```
python3 notes/prom_c_runtime_check.py     # prints every check, exits non-zero on failure
```

Reads `original_ROMs/wsa1_prom_c.ic28` and matches **bytes**, so nothing it asserts
depends on unidasm or on llvm-mc. Every quantified claim in the two block comments,
in the routine headers under them and in
`notes/FINDINGS-prom_c-eeprom-and-runtime.md` comes from here: the four Microwire
command words and their opcode/address fields, the 9- and 16-bit frame lengths, the
port-bit census, the 31/0x1F/0x20 word layout with its `0x5AA5` magic, the fact that
the RAM shadow ends exactly where `RamImage_Copy`'s destination begins, the delay
constants, that the runtime is exactly 38 `retd`-terminated routines tiling
0xFCA0BA-0xFCB27D with no gap and ending where the double constant pool begins, the
seven IEEE-754 bias constants, the six signed/unsigned wrapper pairs, the 1,274
image-wide `1D <target>` byte sites (an UPPER BOUND on the call count -- no
instruction-boundary filter; corrected 2026-08-25, round-2 audit F12), that `Float32_Multiply`'s only two `call`s both go to
`Float32_Divide`, and that 0xFCB4E6 is float32 1.0.

⚠ **Two of its checks exist because a first draft of them was wrong**, and both are
kept in the failure mode this tree keeps repeating:

* the port-bit counts were hand-asserted as 12/11/11/3 and are really 11/13/11/2.
  They are now DERIVED and printed, and what is asserted is the invariant that
  survives -- P6 touched only as bit 5, one more `res` than `set` on each driven
  line (all three extras being `EEPROM_PortInit`'s), and DO never driven.
* "the unsigned kernel is called from nowhere else in the image" holds for five of
  the six wrapper pairs and NOT for `Multiply32`, which has 28 call sites. The
  assertion is now "exactly one call from inside the wrapper".

⚠ It cannot show that a routine COMPUTES what its name says -- only that the bytes
the argument rests on are there. The arguments are in the headers.


---

# Added by round 6 (2026-08-25)

## `prom_c_frontier_src.py`
**"Which UNCONVERTED addresses does the converted code transfer to — without the
phantoms?"**

```
python3 notes/prom_c_frontier_src.py             # the frontier, most-called first
python3 notes/prom_c_frontier_src.py --clusters  # contiguous groups = module hints
python3 notes/prom_c_frontier_src.py --phantoms  # this vs prom_c_frontier.py
python3 notes/prom_c_frontier_src.py --selftest
```

`prom_c_frontier.py` re-disassembles each converted span LINEARLY. Half of prom_c's
converted bytes are DATA — the EQ frequency table, the two 128-entry mixer-gain curves, the
390-byte descriptor-string pool — and a linear decode of a float table produces
plausible-looking `jrl` instructions at random offsets. Its LIMITS section says so; the
RANKING did not, and the ranking is what a target is chosen from.

This reads the `.s` file's own instruction LINES instead. A `.long` line cannot be mistaken
for a `call`. On the pre-round tree it reported **5** targets where the linear tool reported
**146** — and the 5 were a strict subset of the 146, i.e. **141 phantoms and nothing
missed**. `--phantoms` prints that comparison, in both directions, every time.

⚠ It reports what the SOURCE says, so a target is only visible once its caller is converted;
both frontiers grow as conversion proceeds, and a frontier that SHRINKS after a big round
means the round converted leaves. It cannot see a target held in a register or reached
through a pointer table.

⚠ It carries a **completeness check** and prints it on every run: every transfer line with a
literal operand that its patterns did not match is listed, and every number is declared
suspect while any remain. That check exists because a first draft of the patterns silently
dropped twelve real transfers — conditional `jrl nz, (...)` forms and eight-hex-digit
spellings such as `call 0x00F9A01F`.

## `prom_c_voice_module_check.py`
**"Does the 0xFB0504-0xFB405E block really say what its 32 headers claim?"**

```
python3 notes/prom_c_voice_module_check.py            # all twelve sections
python3 notes/prom_c_voice_module_check.py --refs     # just the reference census
python3 notes/prom_c_voice_module_check.py --selftest # + the LAST-element tests
```

Reads `original_ROMs/wsa1_prom_c.ic28` and matches **bytes**, so nothing it asserts depends
on unidasm or on llvm-mc, and no header can drift away from the ROM. Every quantified claim
in that block comment, in its 32 routine headers, in the 0xFE1280 data block and in
`notes/FINDINGS-prom_c-voice-module.md` comes from here: the seven MIDI status arms in order
and the ABSENCE of 0xA0, the 4096-byte ring mask and the four-byte packet stride, the four
boot messages byte for byte, the six `VoiceQuery_*` constant triples, the voice-record
geometry (0x00003BCF / 0x44 / 64) and the part-record geometry (0x00001523 / 0x012C / 33),
the "WSA1 EXTBD" signature and the seven bases the probe installs, a reference census over
all 32 routine starts, the seven small tables at 0xFE1280-0xFE12B4 with their per-byte site
counts, the four staging routines' call-set intersections, the four orphan subset relations,
the OnTail/OffTail byte diff, and PER ARM the packet length and the handler.

Section 13 is the one that reads `prom_c/wsa1_prom_c.s`, and it is there because a header
that drifts off the routine it sits above is invisible to the byte gate: it checks that the
32 headers' own `0xAAAAAA..0xBBBBBB (N bytes)` lines are self-consistent, start at exactly
the 32 addresses the script knows from the ROM, carry a matching label, and TILE
0xFB0504-0xFB405E with no gap and no overlap.

⚠ Three of its sections exist because a hand-count of the same thing was wrong first:

* "seventeen helpers … nineteen shared" was **23 targets, 20 shared** — section 10 now
  computes all six intersections instead;
* the old 0xFE1280 comment said "twenty citations" where a per-byte census finds **41** —
  section 9;
* the orphan subset claims were eyeballed from a summary; section 11 checks all four pairs
  and finds the same three extra callees every time;
* **section 1b exists because the block comment first said "every arm consumes four bytes,
  the 0xC0 arm five".** The 0x80 arm consumes **six** and does not call the note handler at
  all. Two arms were read and the rest generalised. 1b now derives the length and the
  handler for every arm from that arm's own `cp DE,n`, `decw n,(count)` and `call`.

⚠ The reference census is an UPPER BOUND for `call`/`jp` (a byte census with no
instruction-boundary filter) and a SEARCHED NEGATIVE when it reports zero. It cannot show
that a routine computes what its name says.

---

# Added by the module-conversion pass (2026-08-25, after round 4)

Five tools that turn one address range into byte-exact, headed source. They are the pipeline
that produced 174,906 substantive bytes across ten blocks; each block's own comment names them
with the exact command line.

## `gen_prom_c_block.py`
**"What is the byte-exact source text for this range, tables and all?"**

```
python3 notes/gen_prom_c_block.py --start 0xFA7E2C --end 0xFABE30 > /tmp/b.s
VP_CACHE=/tmp/cache python3 notes/gen_prom_c_block.py --start 0xF9A050 --end 0xFA5949
```

Cuts the range into alternating CODE and TABLE segments (table bounds from
`prom_c_jumptables.py`), runs each code segment through `llvm_roundtrip_autoforce.py` and
`prom_c_listing_prep.py`, emits each table as `.long`, gives cross-segment branches a label,
and then runs **the decode-alignment test**: every `call`/`calr`/`jp`/`jrl`/`jr` target that a
DECODED INSTRUCTION names and that lands inside the range must be the start of a listing line.

⚠ **That test is the point.** A round trip proves the listing *rebuilds* the bytes; it does
not prove it *read* them at the right offsets, because a misaligned decode of data can
re-encode to the same bytes. It caught the four jump tables in 0xFA7E2C-0xFABE2F and the
49-entry `XBC`-form table at 0xFAF08F that the table scanner did not yet know. Its sites come
from decoded instructions only — a byte-pattern scan for `1D`/`1E` produced six phantoms on
the first draft.

## `gen_prom_c_block_headers.py`
**"What goes in each header, with every line read off the ROM?"**

```
python3 notes/gen_prom_c_block_headers.py --start 0xFA7E2C --end 0xFABE30 --labels
python3 notes/gen_prom_c_block_headers.py --start 0xFA7E2C --end 0xFABE30 --headers
python3 notes/gen_prom_c_block_headers.py --start 0xFA7E2C --end 0xFABE30 --blockcomment
```

Called from / Inputs / Outputs / Calls / Arms / Evidence / Unknown, every field an instruction
operand or an image-wide scan. `--blockcomment` emits the block header with its census, its
boundary bytes **printed rather than asserted**, and its regenerate recipe. It names nothing
for what it does: 598 of the 600 routines are `sub_XXXXXX`.

## `prom_c_module_map.py`
**"What routines does this range contain, where does each start and end, and who calls it?"**

```
python3 notes/prom_c_module_map.py 0xFA7E2C 0xFABE30
python3 notes/prom_c_module_map.py 0xFA7E2C 0xFABE30 --dups
python3 notes/prom_c_module_map.py --selftest
```

⚠ **Its two filters exist because both of its byte-pattern sources over-report.** Candidate
entries and call sites are both checked against the source file's own decode; without that the
entry count was 761 where the file carries 600, and 5% of cited call sites were `1D`/`1E`
bytes inside longer instructions. Where the file has decoded nothing nearby no filtering
happens and the count is an upper bound — the output says which case it is.

`--dups` finds equal-length routines differing in ≤ 12.5% of their bytes and tests every
differing byte against the `calr` that owns it, so "the same routine duplicated" is a checked
claim and not an impression; when eight or fewer bytes differ it prints them with both values,
which is how "one accessor per struct field" became visible in 0xFC3407-0xFC856B.

## `prom_c_jumptables.py`
**"Where are the computed-goto tables, how many entries, and how is that established?"**

```
python3 notes/prom_c_jumptables.py                    # 38 tables image-wide
python3 notes/prom_c_jumptables.py 0xFA7E2C 0xFABE30
python3 notes/prom_c_jumptables.py --selftest
```

Every entry count comes from **two** readings required to agree: the `cp rr,n` guard before
the `jr/jrl UGT`, and a walk of the contents while each word stays a plausible code address.
⚠ It matches the `XWA` **and** `XBC` forms of the dispatch — a scanner that knew only the
first declared 0xFAD142-0xFB0503 table-free and was wrong.

## `prom_c_voiceparam_checks.py`
**"Is every number in the 0xFA7E2C-0xFABE2F block comment still true?"**

```
python3 notes/prom_c_voiceparam_checks.py --selftest
```

Eight sections, boundary bytes, table entry counts with a last-entry and a
word-after-the-table control, the routine and arm census, the duplicate pairs with a non-pair
control, the two dispatchers byte by byte, the caller span with **both** ends checked, and the
caller tally. Two of its rows are retractions kept as assertions, so the old claim cannot come
back.

---

## Wave 5 (2026-08-25)

### `gen_prom_c_preset_bank.py`
**"What is the 98,304-byte region at 0xF80000, and what proves its geometry?"**

```
python3 notes/gen_prom_c_preset_bank.py --verify   # asserts every claim, exit != 0 on failure
python3 notes/gen_prom_c_preset_bank.py --names    # 16 category names, 129 record names
python3 notes/gen_prom_c_preset_bank.py --census   # per-chunk, per-byte value census
python3 notes/gen_prom_c_preset_bank.py --refs     # the pointer search, classified
python3 notes/gen_prom_c_preset_bank.py --apply    # splice the assembly into the source
```

A PRESET BANK: magic `ZZZZ`, 16 category names, 129 fixed 704-byte records.  The geometry is
carried by four independent facts (tiling onto the pad boundary, an `0xFF/0xFF` end marker
inside every record, the header's own stride and counts, and a layout identical in all 129) —
`--verify` re-proves each.  ⚠ `--refs` is a *negative*: it classifies all 21 candidate
pointers against the disassembly and **none is a real instruction operand**, so no consumer of
this region is known.  See `notes/FINDINGS-prom_c-preset-bank.md`.

### `gen_prom_c_f64_pool.py`
**"What are the 4,801 bytes at 0xFCB27E, and who reads each constant?"**

```
python3 notes/gen_prom_c_f64_pool.py --verify   # boundaries, decode, consumer attribution
python3 notes/gen_prom_c_f64_pool.py --table    # the 77 doubles with their loading routines
python3 notes/gen_prom_c_f64_pool.py --apply
```

77 IEEE-754 doubles, one float32 1.0, and the head of the boot RAM image.  Every constant is
attributed to the routine that loads it, from the 149 24-bit operand sites that carry a pool
half; the 23 entries with no site of their own are shown to be the interiors of seven
coefficient ARRAYS, which is checked rather than asserted.  ⚠ No routine is renamed on the
strength of a constant set — the gap is stated in
`notes/FINDINGS-prom_c-f64-pool.md` §4.

### `prom_c_dev10c_field_sources.py`
**"Which routine computes the value of each 0x0010C000 register?"**  (emulation gap A)

```
python3 notes/prom_c_dev10c_field_sources.py            # the per-register table
python3 notes/prom_c_dev10c_field_sources.py --verify
python3 notes/prom_c_dev10c_field_sources.py --sites    # every write, with its address
python3 notes/prom_c_dev10c_field_sources.py --dev104   # the 0x00104000 packer's 19 writes
```

Joins `prom_c_tg_chanmap.py`'s staged-word → register-block map to every write into the
staging struct at RAM `0x00D75E`, in both the absolute and the based addressing forms: 70
sites over 21 of the 22 words.  ⚠ It names PRODUCERS, never meanings.  Its cross-check is
that the one word with no writer is the one the device writer never reads.  See
`notes/FINDINGS-prom_c-dev10c-producers.md`.

### `gen_prom_c_p7stream_pool.py`
**"What is the 65,972-byte pool at 0xFCD0F7, and how is it framed?"**  (wave 5 round 2)

```
python3 notes/gen_prom_c_p7stream_pool.py --verify    # framing, tiling, counts; exit != 0 on fail
python3 notes/gen_prom_c_p7stream_pool.py --census    # objects, opcodes, interpreter-clean split
python3 notes/gen_prom_c_p7stream_pool.py --emit PATH # the assembly fragment
```

A relocatable byte-code container: a 4-bit opcode and a 12-bit length in the same two header
bytes, which is why round 3's 16-bit reading desynchronised after four records.  Derives the
whole object list from the ROM — no address is hardcoded except the region bounds — and
proves the framing four independent ways, the strongest being that the interpreter's
opcode-4 arm consumes exactly one payload byte and all 266 opcode-4 records have length 3.
⚠ It names no stream's meaning and no destination chip.  See
`notes/FINDINGS-prom_c-p7-byte-stream-pool.md`.

### `p7_group_template_probe.py`
**"Do prom_c's COMPUTED byte emitters produce the same 5-byte groups the POOL replays?"**

```
python3 notes/p7_group_template_probe.py            # the tables
python3 notes/p7_group_template_probe.py --verify   # assertions; exit != 0 on failure
```

Answer: **yes, and exactly.**  The routines at 0xF9AEB6-0xF9B54A compute a value in
floating point and emit it as the SAME five-byte group `P7Stream_Run` replays out of the
pool, using the same six-byte relocation record -- held in globals 0x008614/16/18/1A/1C
instead of frame slots.  The agreement pins each global to an opcode: 99/99 opcode-1
address groups end 0x21 (the constant the 0x008614 emitters push), 81/81 opcode-5 ones end
0x25 (0x008618), 963/963 opcode-0 value groups end 0x15 and 1036/1036 opcode-5 ones end
0x4C.  Carries a phase control (re-cut at every wrong head offset: best wrong phase 0.4%
against 68-93% for the true one) and the pool-directory field separation (all 56 of fields
+4/+12 interpreter-clean, all 56 of +0/+8 not; null 56.2%).

Written up in `notes/FINDINGS-prom_c-p7-group-and-naming.md`.

### `p7_sub_classify.py`
**"Which of p7_module.s's 43 `sub_XXXXXX` objects are ROUTINES, and which are the
CONTINUATION of the object above them?"**

```
python3 notes/p7_sub_classify.py            # the table
python3 notes/p7_sub_classify.py --null     # base rates only
```

The splitter cuts a top-level object at every `ret`/`link` pair, so a routine with an
interior `ret` is emitted as several objects and every piece after the first gets an
address name.  Ten of the 43 are continuations, not entry points.  Prints the base rate
that makes "no `link` at entry" evidence at all: 29/32 of the already-NAMED objects open
with a frame.

### `prom_c_dsp_port.py`
**"By which port do CPU 2's microcode bytes leave, and what answers READY?"**  (gap G)

```
python3 notes/prom_c_dsp_port.py            # the census
python3 notes/prom_c_dsp_port.py --diff     # the three byte writers, byte for byte
python3 notes/prom_c_dsp_port.py --verify   # assertions; exit != 0 on failure
```

Answer: **port P7 (SFR 0x13), written whole**, with P5.4/P5.5/P2.7 as three destination
strobes, PB.5 as data-valid, P5.3 as a command/data qualifier, PB.6 as an enable and P9.3 as
the ready input — the eighteen poll sites gap G counts, 6/6/6 across the three writers.
⚠ This ADVANCES gap G, it does not close it: the question "what answers READY" is answered
only as far as "the thing that consumes a P7 byte", and **which chip that is, is not
established**.  Gap G's second half is LOCATED, not answered: `bit 0,(P9)` occurs exactly
once in prom_c and its only effect is one flag bit beside the flash/wave bank map — that is
what the firmware DOES with the pin, not what the pin IS.  Byte-window scan, so its ZEROES are exact
and every hit reported lands in converted assembly.

### `prom_c_pool_frontier_delta.py`
**"What did converting the pool do to `prom_c_frontier.py`, and can that tool still rank?"**

```
python3 notes/prom_c_pool_frontier_delta.py
```

Imports the frontier tool and runs its own code against the before and after span lists:
132 → 49 targets, 111 gone and **28 new ones invented by linearly decoding the pool's data**.
All 49 surviving from-sites are inside established DATA regions, so the answer to the second
half of the question is **no** — rank prom_c by its `.incbin` list instead.

## Round 3 of the conversion (2026-08-25) — the tail data zone

### `prom_c_tail_census.py`
**"Which addresses in the tail data zone does prom_c's code cite, and what did the old
classifier miss?"**

```
python3 notes/prom_c_tail_census.py                 # 70 targets, 133 sites
python3 notes/prom_c_tail_census.py --sites         # each citing site and its shape
python3 notes/prom_c_tail_census.py --copyb         # the "nothing reaches copy B" claim
python3 notes/prom_c_tail_census.py --corrections   # old classifier vs this one
python3 notes/prom_c_tail_census.py --selftest      # exit != 0 if a stated number moved
```

The tail zone is data, so `prom_c_frontier.py` cannot rank it and a linear decode of it is
noise; the only thing that fixes an object boundary there is prom_c's own code citing the
object's first byte. ★ It exists because `prom_c_dup_image.py --refs` did not know the
`add <X..>,#imm32` (`e9 c8 <addr24> 00`) or `lda <X..>,addr24` shapes — the shapes the
compiler uses for every indexed table read — and round 2 concluded from its silence that
`0xFE0A6D-0xFE1167` held no citation. It holds eight. `--corrections` prints them.
`prom_c_dup_image.py`'s classifier is now fixed too; its copy-A row moved from
`98 coincidences, 54 hits` to `55 coincidences, 97 hits`, and copy B's did not move.

### `gen_prom_c_tail_tables.py`
**"What is in 0xFDF7E0-0xFE21E5, and what is the assembly for it?"**

```
python3 notes/gen_prom_c_tail_tables.py --verify   # tiling, closed forms, copy B
python3 notes/gen_prom_c_tail_tables.py --census   # objects, sizes, citations
python3 notes/gen_prom_c_tail_tables.py --emit     # the 10,389-byte fragment
```

101 objects over three regions. `--verify` asserts that they tile with no gap or overlap,
that every object start is a cited address (the five exceptions are the four strings a
pointer table points at and one unreferenced repeat), that no citation lands inside an
object, and that fourteen tables match a closed form **over every entry** — including the
five 256-entry math tables (sin, cos, atan, log2, exp2), the four `LinCoef` ramps and the
512-entry 8-bit sine. It also re-derives the copy-A/copy-B relation (41 differing bytes) and
checks that every mirrored name is a real label in `prom_c/wsa1_prom_c.s`.
⚠ It names no role for a table it has only a shape for. See
`notes/FINDINGS-prom_c-tail-data-zone.md`.

### `gen_prom_c_fp_pool.py`
**"Where do the elements of the 616-byte floating-point pool at 0xFCC81A start?"**

```
python3 notes/gen_prom_c_fp_pool.py --verify
python3 notes/gen_prom_c_fp_pool.py --emit
```

This pool was a deliberate `.incbin` — an 8-byte grid over it produces denormals. It is not
on a grid: two of its 78 elements are four bytes wide and shift everything after them. No
stride is guessed. All 154 four-byte slots are cited by literal-addressed loads, and a double
is recognised by the instruction pair that pushes it high half first, six bytes apart. 76
doubles + 2 longs = 616 bytes; 48 of the 76 are exact integers; **44100, 1/44100, 1/220500 and
1/441000 are among the values**.

### `prom_c_round3_frontier_delta.py`
**"What did round 3 convert, and did the `.incbin` list fall by exactly that?"**

```
python3 notes/prom_c_round3_frontier_delta.py --selftest
```

prom_c has no reachability frontier left to rank by, so its frontier IS the `.incbin` list:
**5 spans / 11,005 bytes before, 0 / 0 after**, against 11,005 bytes emitted in four regions.
⚠ The BEFORE column is *recorded* in the script, not derived: round 2's state was never
committed, so a delta against `HEAD` would measure rounds 2 and 3 together (that figure is
printed separately, for context).

### `prom_c_phantom_callsites.py`
**"Which `Called from:` addresses in prom_c's headers are inside DATA?"**

```
python3 notes/prom_c_phantom_callsites.py --selftest
```

The headers' call-site lists come from an image-wide byte scan for `1D <addr24>` and
`1E <disp16>`, and prom_c is a quarter data by area. **Eleven citations landed in data** — ten
in the preset bank, one in the f64 coefficient pool — and the preset-bank ten settle it
between them: they fall at four repeating offsets *inside a 704-byte preset record*
(`0x021`, `0x02D`, `0x041`, `0x061`), five of them at `0x041` in records 121 and 123–126. A
call site does not repeat at a data structure's stride. All eleven headers now read
**NO LOCATED CALLER**; the live scan is empty and `--selftest` asserts it stays empty.
The largest casualty is `sub_F9BE3A`, the 8,573-byte double-precision routine, which two notes
described as *"called once from 0xF95B01"*.

### `prom_c_dev104_regmap_checks.py`
**"For the device at CPU 2's 0x00104000: what is the per-channel register map, which staging
word feeds each register, and out of which record field?"**

```
python3 notes/prom_c_dev104_regmap_checks.py            # print all 12 sections
python3 notes/prom_c_dev104_regmap_checks.py --selftest # assert; exit 1 on any failure
```

Twelve sections over `original_ROMs/wsa1_prom_c.ic28`, no `.s` file and no unidasm text.
`Dev104_WriteAllChanRegs` writes **19 registers, `block*0x40 + chan`, value = struct word
2*block**, block 0 LAST; the five small accessors touch exactly **eight blocks 0x00C0..0x0280,
all 0x40 apart**; the whole image holds **nine** `0x00104000` literals and **no read-back**.
The 19 staging words are filled by **24 stores** — 20 in `Dev104_PackStagingStruct`, 3 in
`sub_FC49AD`, 1 in `sub_FC4AED`.

★ **It also asserts a correction.** `notes/prom_c_dev10c_field_sources.py --dev104` reports
0xFC5522, 0xFC55AF, 0xFC55C5 and 0xFC5657 as struct writes. **They are not**: all four load
their base from the absolute global `0x00E086`, so they write the 37-byte record, not the
struct. Consequences: the packer writes **19 SITES over 15 DISTINCT OFFSETS** (state the unit --
four offsets are written twice on different paths),
`+0x1D` is **not a struct offset at all**, and `+0x16` **is** written by the packer
(0xFC51AD, `extpfx5 ... = ld (XBC+0x16),0xff00`) against the round-6 note that says it is
not. ★ ADJUDICATED AND FIXED 2026-09-03 in `5c0cc732`: both defects were confirmed at the
source and `--dev104-selftest` now pins them. The scanner MISSED +0x16 because the store is
spelled as a raw-byte pseudo-instruction, which matches no `ld` pattern -- a store spelled as
bytes is still a store.

### `dev104_topology_probe.py`
**"Given how the firmware programs 0x00104000, what KIND of engine is on the other end?"**

```
python3 notes/dev104_topology_probe.py             # print all 12 sections
python3 notes/dev104_topology_probe.py --selftest  # assert; exit 1 on any failure
```

Twelve sections over `original_ROMs/wsa1_prom_c.ic28` and `wsa1_prom_d.bin`; no `.s` file and no
unidasm text. It is the evidence behind **`notes/HLE-GUIDE-l7a1429.md`**, the topology hypothesis and
per-register HLE guidance it supports. The results that matter:

* **`fold()` is a sign-magnitude -> offset-binary converter.** Under it, `Curve_FE04C9` and
  `Curve_FE05C9` are MONOTONE over all 128 entries, including across the `0x8459 -> 0x015E`
  step that looks like a wrap in the two's-complement reading. The null is that reading,
  which is not monotone. ⚠ `prom_c/data_tables/tail_data_zone.s` describes both tables in
  two's complement; **reported, not edited** — that file is another lane's.
* **`Curve_FE04C9` is a bilinear one-pole coefficient.** Read as sign-magnitude Q15 it is
  `a1 = (K-1)/(K+1)` with `K = tan(pi*f/fs)`, and `f` doubles every **12.0016 index steps**
  with a max residual of **0.8 cents** over i=14..90. Four rival value-to-frequency maps are
  fitted as a null; the best is 50x worse. Index `i` is MIDI note `i+36` at **44,091 +/- 11 Hz**,
  which is 44,100 to 0.33 cent — agreeing with IC4's 33.8688 MHz crystal by a wholly
  independent route.
* **`srl 0x00,XIY` is a shift by 16** (registers 0x01C0/0x0200/0x0240 are the product's HIGH
  half).  Section 4 gives five arguments from plausibility; **section 11 settles it with data**:
  words 7, 8 and 9 of the power-on reset image at 0xFE133B are reproduced EXACTLY by the
  high-half computation, each from one Curve_Exp2Rise_128 index, and the low-half computation
  reproduces none of the three from any of the 128 entries.
* **THREE sections, not two.** `Curve_FE04C9`, `Curve_FE05C9` and `Curve_Exp2Rise_128` are each
  cited **exactly three times in the whole image** — an exhaustive census, not a sighting — and
  the third pair lands in `P[+0x24]` / `P[+0x26]`, i.e. registers 0x03C0 and 0x0480. The
  Stage_B ROM image at 0xFE1315 says the same thing from a path that never runs the packer.
* **The four tone elements are four CHANNELS**, so the A/B grouping cannot be "two elements
  per voice": `MidiNote_OnTail` passes the literal 0 as the sub-record index while the three
  `MidiNote_OnByPartMode` sites push `HL`, a loop counter bounded by `cp L,4` / `cp L,2`.
* **Register 0x0100 is 0x00C0's table-pair companion, not a latch** (section 12) — the answer
  to the write-sequencing lane's tension about a constant register refreshed at 40.69 Hz.
* **A negative result, recorded so it is not repeated:** the `Tone104` record cannot be located
  inside prom_d's 81-byte element blocks by its note-bound fields (eight candidate offsets in
  0.90-0.93 against a pooled null of 0.55).

## `tone_db_naming_w17.py`
**"Which prom_c instruction touches which byte of which prom_d record, and what does
the code do with the value?"**

```
python3 notes/tone_db_naming_w17.py             # every section
python3 notes/tone_db_naming_w17.py --selftest  # exit 1 on any failure
python3 notes/tone_db_naming_w17.py --wrong     # just the wrong-comment report
```

Every number quoted in the W17 header block of `prom_c/tone_db/tone_db_module.s` and in
the C structs added to `prom_d/wsa1_prom_d.s` is re-derived here from the ROM bytes, at
the address it is cited at, with an image-wide occurrence count beside it so a reader can
see how surprising the hit is.  102 checks.  `--wrong` prints the one existing comment
this lane believes is wrong and did **not** edit.

## `tone_db_apply_w17.py`
**"Did the W17 rename touch a comment?"**  It must not: the comment gate requires
insertions only, so this applier renames in the CODE half of a line and never inside a
comment, and it INSERTS its documentation blocks rather than replacing the generator's
`Unknown: what the routine is FOR` paragraph.

```
python3 notes/tone_db_apply_w17.py            # idempotent apply, then verify
python3 notes/tone_db_apply_w17.py --verify
```

⚠ The price is stated in the file it edits: the generated `Called from:` / `Calls:` /
`Arms:` comments in `prom_c/tone_db/tone_db_module.s` still spell the old
`sub_XXXXXX`.  Their addresses are authoritative and the file header carries the full
old -> new table.

### `prom_c_voice_names_w17.py`
**"Which address-form labels in `prom_c/voice/` were renamed in wave 17, to what, on
what evidence, and at what confidence?"**

```
python3 wsa1/notes/prom_c_voice_names_w17.py --report    # the table
python3 wsa1/notes/prom_c_voice_names_w17.py --check     # assert it landed
```

The table IS the record: 65 renames of the 119 `sub_` labels, each with a grade
(PROVEN / STRONG) and a one-line reason. `--apply` rewrites only the CODE half of a
line, so `scripts/analysis/assert_comments_preserved.py` stays green and every
`; sub_FAxxxx -- 0x...` header line survives verbatim; the `★ NAMED (wave 17)` block
inserted above each carries the new label. Internal `sub_XXXXXX__YYYYYY` branch labels
are deliberately left alone, the same choice the tree already made for
`ChanRec_Release`.

### `prom_c_voice_engine_w17_checks.py`
**"Do the numbers in the three `★★ WAVE 17` block comments come out of the ROM?"**

```
python3 wsa1/notes/prom_c_voice_engine_w17_checks.py --selftest
```

Reads `original_ROMs/wsa1_prom_c.ic28` — bytes, never the `.s` file — and asserts, in
five sections: the eight-link array chain `0x0200 → 0x041C → 0x04E8 → 0x0AA8 → 0x0E3E
→ 0x11FE → 0x14FE` and `0x1523 → 0x3BCF → 0x4CCF`, with each stride present as an
immediate at the instruction the comment cites; that **both** polyphony-limit tables
(`0xFE1144`, `0xFE1156`) sum over their sixteen used entries to **exactly 64**, the
channel count; the two 34-entry part→pool maps; the four allocation descriptors at
`0xFE1220` and the shape of the three voice-stealing search orders; and the 21+6
staging-offset → register-block pairs read off `Dev10C_WriteAllChanRegs`'s own
select/value alternation. `--selftest` adds two negative controls — a wrong stride and
a wrong table base — and requires both to go red.

### `prom_c_voice_tonedb_w18.py`
**"Which of wave 17's fifty refusals in `0xFB405F-0xFB6E09` can be named now that
prom_d's `dsp_algo` / `dsp_param` / `WaveSelRec` / `PercInst` decode exists, and
which still cannot?"**

```
python3 wsa1/notes/prom_c_voice_tonedb_w18.py --report   # the table
python3 wsa1/notes/prom_c_voice_tonedb_w18.py --claims   # re-read the ROM
python3 wsa1/notes/prom_c_voice_tonedb_w18.py --apply    # do the rename
python3 wsa1/notes/prom_c_voice_tonedb_w18.py --check    # assert it landed
```

The table IS the record: 42 renames and 8 stated refusals, covering exactly the 50
`sub_` labels in that address range and no others. Each rename carries a grade
(PROVEN / STRONG) and the instruction addresses it rests on; each refusal says what
the routine turns on and what would settle it. `--apply` rewrites only the CODE half
of a line and inserts a `★ NAMED (wave 18)` or `★ NOT NAMED (wave 18)` block above
the generated header, so the comment gate stays green.

`--sync` asserts the 412 evidence lines in the table are still the ones the `.s`
blocks carry, so the two cannot drift apart unnoticed.

`--claims` reads `original_ROMs/wsa1_prom_c.ic28` — bytes, never the `.s` file — and
runs **56 checks** in eight sections: the `1 << 2i` element-mask byte table at
`0xFDE69D`; that the three staging regions tile (`0x008A9B - 0x0087D2 = 713`,
`0x008C33 - 0x0087D2 = 713 + 408`); that `ToneRec_GetWaveSelectRecord`'s four arms
carry `0x51 / 0xA2 / 0xF3 / 0x144` = `81*N`; the three `(index map, descriptor array,
stride)` triples `ToneDB_ResolveEnvDescriptor` reads out of the prom_d directory,
including the one that **contradicts prom_d's own block** (`+0x30`/`+0x34` are scaled
by `+0xEC`, not `+0xF2`); the four selector pairs at wave-select record
`+0x03..+0x0A`; that `PartElement_SetEnvDescriptorPointer` and
`DrawbarPreset_GetDescriptor` write the same `+0x90` slot; the seven DSP table bases
the `dsp_algo` readers index, with the curve-pool row numbers derived
(`0xFDEA21 = pool + 8*0x66`, `0xFDEB53 = pool + 11*0x66`); and `0x26AC = 300 * 33`.
Every literal is cited with its image-wide occurrence count beside it as the null.

### `prom_c_voice_tonedb_w18-block.txt` and `prom_c_voice_tonedb_w18.rename-map`
The `★★ WAVE 18` subject block inserted at the head of `0xFB405F-0xFB6E09` in
`prom_c/voice/note_engine.s`, kept beside the tool so the block can be diffed
without diffing an 800 KB listing; and the `old=new` map that
`assert_comments_preserved.py --rename-map` needs to accept the re-spelled
`Calls:` / `Called from:` lines. Regenerate the map with

```
python3 scripts/converters/sync_comments_to_renamed_labels.py \
    --base <the commit before the rename> --apply \
    --write-map wsa1/notes/prom_c_voice_tonedb_w18.rename-map \
    wsa1/prom_c/voice/note_engine.s
```

The map is also the only place the 42 **address-form** labels survive: the block
comments spell the old name as an address (`the routine at 0xFB405F is now ...`)
precisely so the sync tool cannot substitute it away.
