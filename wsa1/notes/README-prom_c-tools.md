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
